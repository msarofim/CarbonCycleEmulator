# =====================================================================
# forcing.R — assemble every external driver onto the model's monthly axis.
#
# This is the single place where acquired data (data/*.rds, written by
# data-raw/build_calibration_data.R) becomes model input. Every choice made
# here -- hemispheric splits, interpolation, gap handling, unit conversion --
# is a modelling decision, so each is stated inline rather than buried.
#
# See DATA.md for the provenance of every input and a summary of this pipeline.
#
# THE CENTRAL NUMERICAL CARE: annual -> monthly interpolation must CONSERVE the
# annual total. Emissions drive cumulative carbon, so an interpolation that
# quietly changes annual sums changes the answer. `ccx_annual_to_monthly()`
# interpolates smoothly and then corrects each year additively so its 12 monthly
# values average exactly to the annual value. Gated by test-forcing.R.
# =====================================================================

# ---- named constants: every split and gap rule is declared here -----
FORC_FOSS_NH_SHARE <- 0.95   # fossil CO2 emitted in the NH. PROVISIONAL.
FORC_LUC_NH_SHARE  <- 0.55   # land-use change is far more tropical/SH-weighted
                             # than fossil. PROVISIONAL -- see DATA.md.
FORC_NUC_NH_SHARE  <- 0.95   # nuclear-industry 14C: the 22 reporting countries
                             # are overwhelmingly NH. PROVISIONAL.
FORC_BOMB_NH_SHARE <- 0.90   # atmospheric weapons tests were overwhelmingly NH.
FORC_GMST_PRE1850  <- 0      # IGCC starts 1850; earlier GMST anomaly set to 0
                             # (the model's own baseline is the 1750 spinup).
FORC_ENSO_PRE1948  <- 0      # Nino 3.4 starts 1948; no ENSO term before that.
                             # A DISCONTINUITY IN CONSTRAINT, not in physics:
                             # pre-1948 residuals lack an ENSO explanation.

# ---------------------------------------------------------------------
#' Interpolate an annual series to monthly, preserving annual means exactly
#'
#' Smooth (natural spline through year midpoints) then additively corrected so
#' each calendar year's 12 monthly values average to its annual value. Additive
#' rather than multiplicative correction because annual values can be zero or
#' negative (land-use change flux, ENSO index) and a multiplicative rescale
#' would blow up or flip sign.
#'
#' @param years  integer vector of years (need not be contiguous)
#' @param values numeric vector, same length
#' @param out_years integer vector of years to produce
#' @return numeric vector of length 12*length(out_years), month-major
ccx_annual_to_monthly <- function(years, values, out_years, method = c("spline", "constant")) {
  method <- match.arg(method)
  ok <- !is.na(values)
  years <- years[ok]; values <- values[ok]
  mid <- out_years + 0.5
  ann <- stats::approx(years + 0.5, values, xout = mid, rule = 2)$y

  if (method == "constant") {
    # Piecewise constant within each year. Exactly conserving, shape-preserving,
    # and CANNOT undershoot. Required for sharply peaked non-negative sources:
    # a spline through the bomb-14C series undershoots either side of the 1962
    # peak, and clipping those negatives back to zero ADDED 4.3 % to the
    # prescribed total -- i.e. quietly broke the calibrated magnitude.
    return(as.vector(matrix(rep(ann, each = 12), nrow = 12)))
  }

  t_m <- rep(out_years, each = 12) + (seq_len(12) - 0.5) / 12
  m   <- stats::spline(years + 0.5, values, xout = t_m, method = "natural")$y

  # additive per-year correction -> annual mean is exact
  m_mat <- matrix(m, nrow = 12)
  m_mat <- sweep(m_mat, 2, colMeans(m_mat) - ann, "-")
  as.vector(m_mat)
}

# ---------------------------------------------------------------------
#' Nuclear-industry 14C emissions, GBq/yr -> mol 14C/yr, annual
#'
#' Sums every annual file in data-raw/downloads/nuclear14c. Coverage is
#' incomplete by construction (e.g. USA reports only 2010-2023), so this is a
#' LOWER BOUND on the true industrial source -- stated in DATA.md, not hidden.
ccx_nuclear_c14_annual <- function(dir = ccx_path("data-raw", "downloads", "nuclear14c")) {
  fs <- list.files(dir, pattern = "csv$", full.names = TRUE)
  if (length(fs) == 0) {
    warning("No nuclear 14C files found; industrial source set to zero.")
    return(data.frame(year = integer(0), mol_per_yr = numeric(0)))
  }
  d <- do.call(rbind, lapply(fs, function(f) {
    x <- utils::read.csv2(f, stringsAsFactors = FALSE)
    data.frame(year = suppressWarnings(as.integer(x$Year)),
               GBq  = suppressWarnings(as.numeric(x$C14_tot_GBq)))
  }))
  d <- d[!is.na(d$year) & !is.na(d$GBq), ]
  agg <- aggregate(GBq ~ year, data = d, FUN = sum)
  data.frame(year = agg$year,
             mol_per_yr = agg$GBq * ccx_const("MOL_C14_PER_GBq"))
}

# ---------------------------------------------------------------------
#' Bomb 14C DELIVERY to the troposphere, monthly, mol 14C/yr
#'
#' Reads the measured input function built by
#' data-raw/build_bomb_c14_source.R from Tans (1981) SCOPE 16 Tables 1 and 2.
#'
#' NOT a production rate. The model's atmosphere is a single well-mixed
#' troposphere per hemisphere with no stratospheric box (R/model.R), so what
#' belongs here is the stratosphere->troposphere flux. Tans (p.133): the input
#' of bomb 14C into the troposphere equals the stratospheric decrease. Feeding
#' a production series into this slot delivers the 1961-62 tests to the
#' troposphere about a year early -- see the superseded shape below.
#'
#' The stored series is normalised to unit integral, so `total_kmol` alone sets
#' the magnitude and the calibrated bomb_total (Naegler & Levin 2006 prior)
#' continues to carry it.
ccx_bomb_c14_monthly <- function(total_kmol = 102) {
  b <- readRDS(ccx_path("data", "forcing_bomb_c14.rds"))
  data.frame(year = b$year, month = b$month,
             mol_per_yr = b$shape_per_yr * total_kmol * 1000)
}

#' Annual aggregate of the monthly delivery -- diagnostics and back-compat
ccx_bomb_c14_annual <- function(total_kmol = 102, years = 1945:1980) {
  b <- ccx_bomb_c14_monthly(total_kmol)
  a <- tapply(b$mol_per_yr, b$year, mean)
  out <- data.frame(year = years, mol_per_yr = 0)
  i <- match(as.character(years), names(a))
  out$mol_per_yr[!is.na(i)] <- as.numeric(a)[i[!is.na(i)]]
  out
}

# ---------------------------------------------------------------------
#' SUPERSEDED 2026-08-10 -- the provisional production-shaped placeholder.
#'
#' Kept only so the size of the correction can be reproduced. It put 54.0 % of
#' all bomb 14C into 1961-62 and 2.2 % into 1963; the measured input function
#' puts 13.2 % into 1961-62 and 27.2 % into 1963. Do not wire this back in.
#'
#' *** PROVISIONAL SHAPE -- see DATA.md "Outstanding data gaps". ***
#'
#' The design (Marcus, 2026-08-09) is a prescribed time SHAPE from atmospheric
#' test yields with the TOTAL calibrated, so the model PREDICTS the Delta14C
#' spike rather than fitting it. The total has a citable prior: Naegler & Levin
#' (2006) give 99.3-104.9 kmol for 1945-1980. The SHAPE does not: UNSCEAR 2000
#' Annex C holds the annual atmospheric test yields, but only as a PDF table
#' with no machine-readable release found.
#'
#' Until that is digitised, the shape below is a documented placeholder built
#' from the qualitative test history (peak testing 1961-62, with 1954, 1958 and
#' 1961-62 the most active years; total atmospheric yield ~440 Mt). It is
#' NORMALISED to unit integral, so `total_kmol` alone sets the magnitude and the
#' placeholder cannot silently set the amplitude. Do not report bomb-era 14C
#' results on this shape.
ccx_bomb_c14_annual_SUPERSEDED <- function(total_kmol = 102, years = 1945:1980) {
  # relative annual atmospheric test activity -- PROVISIONAL
  shape <- c(
    `1945` = 0.2, `1946` = 0.3, `1947` = 0.0, `1948` = 0.4, `1949` = 0.2,
    `1950` = 0.0, `1951` = 0.9, `1952` = 1.2, `1953` = 0.9, `1954` = 4.0,
    `1955` = 2.0, `1956` = 3.5, `1957` = 3.0, `1958` = 8.0, `1959` = 0.0,
    `1960` = 0.2, `1961` = 15.0, `1962` = 22.0, `1963` = 1.5, `1964` = 0.4,
    `1965` = 0.3, `1966` = 0.6, `1967` = 0.5, `1968` = 0.6, `1969` = 0.3,
    `1970` = 0.5, `1971` = 0.3, `1972` = 0.2, `1973` = 0.3, `1974` = 0.4,
    `1975` = 0.1, `1976` = 0.3, `1977` = 0.1, `1978` = 0.1, `1979` = 0.0,
    `1980` = 0.2)
  yr <- as.integer(names(shape))
  w  <- as.numeric(shape) / sum(as.numeric(shape))
  out <- data.frame(year = years, mol_per_yr = 0)
  idx <- match(out$year, yr)
  out$mol_per_yr[!is.na(idx)] <- w[idx[!is.na(idx)]] * total_kmol * 1000
  out
}

# ---------------------------------------------------------------------
#' Assemble the full monthly forcing table
#'
#' @param scenario "historical", or one of the SSP names in data/ssp_emissions.rds
#' @param years    integer range c(first, last)
#' @param prod_c14 cosmogenic 14C production (mol/yr) -- from ccx_spinup()
#' @param bomb_total_kmol total bomb 14C production, 1945-1980
#' @param emissions optional data.frame(year, fossil_GtC, luc_GtC) REPLACING the
#'   scenario's emissions entirely. This is how the app's stylised pathways
#'   ("linear to zero by 2060", "+2 %/yr") and its pulse experiments are built:
#'   the caller assembles the annual series and everything downstream --
#'   hemispheric split, monthly interpolation, annual-total conservation -- is
#'   applied identically to a custom path and to an SSP. `scenario` still names
#'   the run for labelling and still selects the non-CO2 climate background.
#' @return data.frame, one row per month, with everything ccx_deriv() needs
ccx_build_forcing <- function(scenario = "historical",
                              years = c(1750, 2024),
                              prod_c14 = NA_real_,
                              bomb_total_kmol = 102,
                              emissions = NULL) {

  yrs <- seq(years[1], years[2])
  n   <- length(yrs) * 12
  t   <- rep(yrs, each = 12) + (seq_len(12) - 0.5) / 12

  # ---- emissions ----------------------------------------------------
  if (!is.null(emissions)) {
    e <- as.data.frame(emissions)
    need <- c("year", "fossil_GtC", "luc_GtC")
    if (!all(need %in% names(e)))
      stop("`emissions` needs columns: ", paste(need, collapse = ", "))
    src <- paste("caller-supplied emissions,", scenario)
  } else if (identical(scenario, "historical")) {
    e <- readRDS(ccx_path("data", "forcing_emissions_historical.rds"))
    e <- as.data.frame(e)
    src <- "GCB 2025 historical budget"
  } else {
    ssp <- as.data.frame(readRDS(ccx_path("data", "ssp_emissions.rds")))
    ssp <- ssp[ssp$scenario == scenario, ]
    if (nrow(ssp) == 0) stop("Unknown scenario '", scenario, "'")
    e <- data.frame(year = ssp$year, fossil_GtC = ssp$fossil_GtC, luc_GtC = ssp$luc_GtC)
    src <- paste("RCMIP v5.1.0", scenario)
  }
  foss <- ccx_annual_to_monthly(e$year, e$fossil_GtC, yrs)
  luc  <- ccx_annual_to_monthly(e$year, e$luc_GtC,    yrs)

  # ---- d13C of the fossil source, TIME-VARYING (2026-08-12) ----------
  # Built in data-raw/build_calibration_data.R [5b] from GCB's own by-fuel
  # split: -24.0 permil in 1850 (essentially pure coal) to -28.3 by 2024 as gas
  # displaced coal and cement (limestone, ~0 permil) entered the total. It
  # replaces a single -28 applied to the whole industrial period, which made the
  # modelled Suess decline ~30 % too steep -- see calibration/diag_d13c_suess.R.
  #
  # Only the historical table carries the column. SSPs and caller-supplied
  # pathways do not: the future fuel mix is a scenario property nobody has
  # supplied, so the last historical value is HELD FLAT, the same placeholder
  # convention the GMST column uses below. d13C is not scored past 2024, so this
  # affects reported d13C only, never the carbon budget.
  if (!is.null(e$d13c_foss)) {
    d13c_foss <- ccx_annual_to_monthly(e$year, e$d13c_foss, yrs, method = "constant")
  } else {
    h <- as.data.frame(readRDS(ccx_path("data", "forcing_emissions_historical.rds")))
    d13c_foss <- ccx_annual_to_monthly(h$year, h$d13c_foss, yrs, method = "constant")
  }

  # ---- temperature: IGCC, zero before its record starts --------------
  # AFTER the record ends this HOLDS THE LAST OBSERVED VALUE FLAT. That is a
  # placeholder, not a projection: an SSP5-8.5 run to 2100 built here sits at
  # the 2024 temperature throughout, silently, which suppresses the q10
  # respiration and ocean-solubility feedbacks entirely. Anything running past
  # the observational record must go through ccx_run_coupled() (R/climate.R),
  # which computes temperature from the model's own CO2 and overwrites this
  # column. The warning fires once per build so the placeholder cannot be used
  # by accident.
  g <- as.data.frame(readRDS(ccx_path("data", "forcing_gmst.rds")))
  gm <- ccx_annual_to_monthly(g$year, g$gmst_anom, yrs)
  yv <- rep(yrs, each = 12)          # integer year of each month
  gm[yv < min(g$year)] <- FORC_GMST_PRE1850
  if (max(yrs) > max(g$year))
    warning(sprintf(paste0("GMST observations end %d; years %d-%d are held FLAT ",
                           "at the last observed value. Use ccx_run_coupled() ",
                           "for an interactive climate."),
                    max(g$year), max(g$year) + 1L, max(yrs)), call. = FALSE)

  # ---- ENSO: Nino 3.4 anomaly, zero before 1948 ----------------------
  en <- as.data.frame(readRDS(ccx_path("data", "forcing_enso.rds")))
  en <- en[!is.na(en$nino34_anom), ]
  en_t <- en$year + (en$month - 0.5) / 12
  enso <- stats::approx(en_t, en$nino34_anom, xout = t, rule = 2)$y
  enso[yv < min(en$year)] <- FORC_ENSO_PRE1948

  # ---- 14C sources ---------------------------------------------------
  nuc <- ccx_nuclear_c14_annual()
  c14_nuc <- if (nrow(nuc)) ccx_annual_to_monthly(nuc$year, nuc$mol_per_yr, yrs,
                                                 method = "constant") else rep(0, n)
  # Compare INTEGER years. Using decimal t here silently dropped the FINAL year
  # of every source record: month-centred t for year Y runs Y.04..Y.96, all of
  # which satisfy t > Y. That cost 0.28 % of the prescribed bomb total.
  if (nrow(nuc)) c14_nuc[yv < min(nuc$year) | yv > max(nuc$year)] <- 0

  # method="constant": the bomb series is sharply peaked and must stay
  # non-negative, and its underlying data are annual anyway. See the note in
  # ccx_annual_to_monthly() -- splining then clipping inflated the total 4.3 %.
  # The bomb source is now NATIVELY MONTHLY (data/forcing_bomb_c14.rds, built by
  # data-raw/build_bomb_c14_source.R from Tans 1981 Tables 1-2), so it is placed
  # on the axis by month rather than round-tripped through an annual series.
  # ccx_annual_to_monthly() is still the right tool for genuinely annual inputs.
  bomb <- ccx_bomb_c14_monthly(bomb_total_kmol)
  key  <- yv * 12L + rep(seq_len(12), length(yrs))
  c14_bomb <- rep(0, n)
  m <- match(key, bomb$year * 12L + bomb$month)
  c14_bomb[!is.na(m)] <- bomb$mol_per_yr[m[!is.na(m)]]

  data.frame(
    t = t, year = rep(yrs, each = 12), month = rep(seq_len(12), length(yrs)),
    e_foss_NH = foss * FORC_FOSS_NH_SHARE,
    e_foss_SH = foss * (1 - FORC_FOSS_NH_SHARE),
    e_luc_NH  = luc  * FORC_LUC_NH_SHARE,
    e_luc_SH  = luc  * (1 - FORC_LUC_NH_SHARE),
    gmst = gm, enso = enso, d13c_foss = d13c_foss,
    c14_bomb = c14_bomb, c14_nuclear = c14_nuc,
    c14_cosmo = rep(prod_c14, n),
    stringsAsFactors = FALSE
  )
}

#' Resolve the fossil-source d13C of a forcing, including hand-built ones
#'
#' ccx_build_forcing() always supplies `d13c_foss`, but several callers assemble
#' a forcing list literally -- ccx_spinup()'s zero forcing and the conservation
#' tests' closed system -- and those carry no emissions at all, so the value
#' would multiply a zero flux.
#'
#' Rather than default silently (which would let a REAL run missing the column
#' pick a number nobody chose), this returns 0 only when there is genuinely no
#' fossil flux to label, and errors otherwise.
ccx_forcing_d13c_foss <- function(forc) {
  if (!is.null(forc$d13c_foss)) return(forc$d13c_foss)
  if (any(unlist(forc$e_foss) != 0))
    stop("forcing carries fossil emissions but no `d13c_foss`; ",
         "build it with ccx_build_forcing()")
  0
}

#' Extract one month's forcing in the shape ccx_deriv() expects
ccx_forcing_at <- function(F, i) {
  list(e_foss = list(NH = F$e_foss_NH[i], SH = F$e_foss_SH[i]),
       e_luc  = list(NH = F$e_luc_NH[i],  SH = F$e_luc_SH[i]),
       gmst = F$gmst[i], enso = F$enso[i], d13c_foss = F$d13c_foss[i],
       c14_bomb = F$c14_bomb[i], c14_nuclear = F$c14_nuclear[i],
       c14_cosmo = F$c14_cosmo[i])
}

# ---------------------------------------------------------------------
#' Run the model forward over an assembled forcing table
#'
#' @param substeps RK4 substeps per month, or "auto" to pick the smallest count
#'   that keeps the explicit diffusion term stable (see ccx_substeps_for()).
#'   "auto" resolves to CCX_SUBSTEPS_MIN = 4 at every ordinary parameter value.
#' @return list(state = final state, out = data.frame of monthly diagnostics)
ccx_run <- function(spin, F, substeps = "auto", fluxes = FALSE) {
  y <- spin$y; aux <- spin$aux; grid <- spin$grid; p <- spin$params
  substeps <- ccx_resolve_substeps(substeps, p, grid)
  n <- nrow(F)
  atmN <- aux$idx$NH$atm; atmS <- aux$idx$SH$atm
  ocean <- unlist(lapply(HEMIS, function(h) c(aux$idx[[h]]$ml, aux$idx[[h]]$oc)))
  land  <- unlist(lapply(HEMIS, function(h) aux$idx[[h]]$land))

  atm   <- c(atmN, atmS)
  # 14C reservoir inventories, in STATE units ("GtC carrying standard 14C
  # content"). Carried alongside the carbon stocks because the ocean excess-14C
  # constraint (likelihood.R) is an INVENTORY at two reference years, which
  # cannot be reconstructed from the atmospheric D14C series. Converted to kmol
  # by the likelihood, not here -- the model core does not own that convention.
  out <- data.frame(t = F$t, co2_NH = NA_real_, co2_SH = NA_real_,
                    d13c_NH = NA_real_, d13c_SH = NA_real_,
                    d14c_NH = NA_real_, d14c_SH = NA_real_,
                    ocean_C = NA_real_, land_C = NA_real_,
                    ocean_C14 = NA_real_, land_C14 = NA_real_,
                    atm_C14 = NA_real_)
  gpp <- ccx_const("GtC_PER_PPM") / 2
  # Flux trace (R/fluxes.R): OPT-IN, and evaluated at each month's OPENING state
  # rather than inside the RK4 substeps. It is a diagnostic; the substep-mean
  # would differ only by within-month curvature, and paying for it on every
  # likelihood evaluation would be the wrong trade entirely.
  ystore <- if (fluxes) vector("list", n) else NULL
  for (i in seq_len(n)) {
    if (fluxes) ystore[[i]] <- y
    out$co2_NH[i]  <- y[atmN, "C"] / gpp
    out$co2_SH[i]  <- y[atmS, "C"] / gpp
    out$d13c_NH[i] <- 1000 * (y[atmN, "C13"] / (y[atmN, "C"] * ccx_const("R13_VPDB")) - 1)
    out$d13c_SH[i] <- 1000 * (y[atmS, "C13"] / (y[atmS, "C"] * ccx_const("R13_VPDB")) - 1)
    out$d14c_NH[i] <- 1000 * (y[atmN, "C14"] / y[atmN, "C"] - 1)
    out$d14c_SH[i] <- 1000 * (y[atmS, "C14"] / y[atmS, "C"] - 1)
    out$ocean_C[i] <- sum(y[ocean, "C"])
    out$land_C[i]  <- sum(y[land, "C"])
    out$ocean_C14[i] <- sum(y[ocean, "C14"])
    out$land_C14[i]  <- sum(y[land,  "C14"])
    out$atm_C14[i]   <- sum(y[atm,   "C14"])
    y <- ccx_step_rk4(y, F$t[i], 1 / 12, p, ccx_forcing_at(F, i), grid, aux, substeps)
  }
  res <- list(state = y, out = out)
  if (fluxes) res$fluxes <- ccx_flux_trace(ystore, F, p, grid, aux)
  res
}
