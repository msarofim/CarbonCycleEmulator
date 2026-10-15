# =====================================================================
# carbonate.R — mixed-layer carbonate chemistry
#
# Provides pCO2 as a function of DIC and temperature at fixed alkalinity,
# and the Revelle factor as an EMERGENT diagnostic (never imposed).
#
# Method: closed-form carbonate-alkalinity solve for [H+], refined by
# Newton iterations that add the borate and water contributions to total
# alkalinity. Dissociation constants come from polynomials in T fitted to
# `seacarb` (see data-raw/build_carbonate_tables.R for provenance) so no
# coefficient in this file is hand-copied from a paper.
#
# All routines are vectorized over DIC/T and use only arithmetic, so they
# port directly to the Rcpp core if the pure-R model misses its speed target.
# =====================================================================

CARB_COEFS_FILE <- file.path("data", "carbonate_coefs.rds")
# THE TABLES, ONE PER REFERENCE SALINITY (2026-10-12). 34.7 is the uncited legacy value every
# mode registered before hilda31w ran on; 34.760 is GLODAPv2.2023's 0-100 m cos-lat-weighted
# surface salinity (citation rulings row 30, "Compute from GLODAP, adopt (Recommended)"), read by
# label hilda_csl3v0kaidgbemwtc through the structure field `carb_salinity` -- the canonical
# hilda31w runs on it. Each file is built by
# data-raw/build_carbonate_tables.R <salinity>; the loader checks the file's own salinity.
CARB_SALINITY_LEGACY    <- 34.7
CARB_COEFS_BY_SALINITY  <- c("34.7" = "carbonate_coefs.rds", "34.76" = "carbonate_coefs_s34760.rds")

#' Load the fitted carbonate constants (memoized PER FILE)
#' @return list with coefs (K0,K1,K2,Kb), poly_degree, salinity, boron_total
#' ⚠ Until 2026-10-12 the memo held the FIRST file read and ignored `file` thereafter -- harmless
#' while there was one table, wrong with two. It is now keyed by path.
.carb_env <- new.env(parent = emptyenv())
carb_coefs <- function(file = ccx_path(CARB_COEFS_FILE)) {
  key <- normalizePath(file, mustWork = FALSE)
  if (is.null(.carb_env[[key]])) {
    if (!file.exists(file)) {
      stop("Carbonate coefficients not found at '", file, "'.\n",
           "  Run: Rscript data-raw/build_carbonate_tables.R")
    }
    .carb_env[[key]] <- readRDS(file)
  }
  .carb_env[[key]]
}

#' The carbonate table for a reference salinity (NULL = the legacy 34.7, the SAME object
#' carb_coefs() returns, so every mode registered before hilda31w is bit-exact). An unbuilt
#' salinity STOPS.
ccx_carb_coefs_for <- function(salinity = NULL) {
  if (is.null(salinity)) return(carb_coefs())
  hit <- names(CARB_COEFS_BY_SALINITY)[abs(as.numeric(names(CARB_COEFS_BY_SALINITY)) - salinity) < 1e-9]
  if (length(hit) != 1L)
    stop("no carbonate table for salinity ", format(salinity), " (built: ",
         paste(names(CARB_COEFS_BY_SALINITY), collapse = " / "), "). Build one with ",
         "data-raw/build_carbonate_tables.R and register it in CARB_COEFS_BY_SALINITY.")
  if (as.numeric(hit) == CARB_SALINITY_LEGACY) return(carb_coefs())
  cc <- carb_coefs(ccx_path("data", CARB_COEFS_BY_SALINITY[[hit]]))
  if (abs(cc$salinity - salinity) > 1e-9)
    stop("carbonate table ", CARB_COEFS_BY_SALINITY[[hit]], " was built at S ", cc$salinity,
         ", not the requested ", salinity)
  cc
}

#' Evaluate a fitted ln-K polynomial
#'
#' Coefficients are fitted in the CENTERED, SCALED variable x = (T - t_centre)/t_scale
#' (see data-raw/build_carbonate_tables.R) — evaluating them against raw T would
#' silently return garbage, so the scaling is always applied here.
#' @param co numeric coefficient vector (intercept first)
#' @param T temperature, degC
.eval_lnK <- function(co, T, cc) {
  x <- (T - cc$t_centre) / cc$t_scale
  out <- rep(co[1], length(x))
  for (i in seq_len(length(co) - 1L)) out <- out + co[i + 1L] * x^i
  exp(out)
}

#' Carbonate equilibrium constants at temperature T
#' @param T temperature in degC (must lie in the fitted range)
#' @return list(K0, K1, K2, Kb, boron_total)
carb_constants <- function(T, cc = carb_coefs()) {
  rng <- cc$t_range
  if (any(T < rng[1] - 1e-9 | T > rng[2] + 1e-9)) {
    warning(sprintf("Temperature outside fitted range [%.1f, %.1f] degC; extrapolating.",
                    rng[1], rng[2]))
  }
  list(K0 = .eval_lnK(cc$coefs$K0, T, cc),
       K1 = .eval_lnK(cc$coefs$K1, T, cc),
       K2 = .eval_lnK(cc$coefs$K2, T, cc),
       Kb = .eval_lnK(cc$coefs$Kb, T, cc),
       Kw = .eval_lnK(cc$coefs$Kw, T, cc),
       bt = cc$boron_total)
}

#' Hydrogen ion concentration from DIC and total alkalinity
#'
#' Step 1 is the exact solution of the carbonate-alkalinity-only system,
#' a quadratic in h:
#'   A h^2 + K1 (A - DIC) h + K1 K2 (A - 2 DIC) = 0
#' Step 2 refines with Newton iterations on the residual
#'   TA(h) - TA_target,  TA(h) = HCO3 + 2 CO3 + B(OH)4 + OH - [H+]
#' which folds in borate and water self-ionization.
#'
#' The OH- term is only ~0.25 % of total alkalinity but pCO2 amplifies an
#' alkalinity error by roughly the Revelle factor, so dropping it costs
#' ~4.5 % in pCO2 (measured against seacarb before it was added) -- far
#' above any tolerance the calibration could absorb. Do not "simplify" it away.
#'
#' On the total pH scale, -[H+]_free - [HSO4-] is well approximated by
#' -[H+]_total, so no explicit sulfate term is needed here.
#'
#' @param dic  total dissolved inorganic carbon, mol/kg
#' @param alk  total alkalinity, mol/kg
#' @param T    temperature, degC
#' @param iter number of Newton refinements (default gated by tests)
#' @return [H+] in mol/kg
h_from_dic_alk <- function(dic, alk, T, iter = 6L, k = carb_constants(T)) {
  K1 <- k$K1; K2 <- k$K2; Kb <- k$Kb; Kw <- k$Kw; bt <- k$bt

  # --- exact carbonate-only seed -------------------------------------
  a <- alk
  b <- K1 * (alk - dic)
  cc_ <- K1 * K2 * (alk - 2 * dic)
  disc <- pmax(b * b - 4 * a * cc_, 0)
  h <- (-b + sqrt(disc)) / (2 * a)
  h <- pmax(h, 1e-12)

  # --- Newton refinement including borate and free protons -----------
  for (i in seq_len(iter)) {
    denom  <- h * h + K1 * h + K1 * K2
    hco3   <- dic * K1 * h / denom
    co3    <- dic * K1 * K2 / denom
    boh4   <- bt * Kb / (Kb + h)
    oh     <- Kw / h
    f      <- hco3 + 2 * co3 + boh4 + oh - h - alk

    # analytic derivative d(TA)/dh
    dden   <- 2 * h + K1
    dhco3  <- dic * K1 * (denom - h * dden) / denom^2
    dco3   <- -dic * K1 * K2 * dden / denom^2
    dboh4  <- -bt * Kb / (Kb + h)^2
    doh    <- -Kw / (h * h)
    fp     <- dhco3 + 2 * dco3 + dboh4 + doh - 1

    h <- pmax(h - f / fp, 1e-12)
  }
  h
}

#' Seawater pCO2 from DIC, alkalinity and temperature
#' @return pCO2 in microatm
pco2_from_dic <- function(dic, alk, T, k = carb_constants(T), iter = 6L) {
  h    <- h_from_dic_alk(dic, alk, T, iter = iter, k = k)
  co2  <- dic * h * h / (h * h + k$K1 * h + k$K1 * k$K2)   # [CO2*], mol/kg
  co2 / k$K0 * 1e6                                          # -> microatm
}

#' Revelle (buffer) factor, computed as an emergent centered derivative
#'
#'   R = (dpCO2 / pCO2) / (dDIC / DIC)
#'
#' Reported by the app rather than prescribed: it rises as the ocean takes
#' up carbon, which is exactly the saturation story the pulse tab tells.
#' @param rel_step relative DIC perturbation for the centered difference
revelle_factor <- function(dic, alk, T, rel_step = 1e-4, cc = carb_coefs()) {
  k  <- carb_constants(T, cc)
  d  <- dic * rel_step
  p1 <- pco2_from_dic(dic - d, alk, T, k = k)
  p2 <- pco2_from_dic(dic + d, alk, T, k = k)
  ((p2 - p1) / (p2 + p1)) / ((2 * d) / (2 * dic))
}
