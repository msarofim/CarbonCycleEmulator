# =====================================================================
# build_carbonate_tables.R
#
# The ocean mixed layer needs pCO2(DIC, T) at every timestep, so the
# carbonate system must be FAST and C++-portable. Rather than hand-copying
# dissociation-constant coefficients out of the literature (an error-prone
# step this project forbids), we query `seacarb` -- a maintained, cited
# implementation -- over the model's temperature range and fit smooth
# polynomials in T to ln K0, ln K1, ln K2, ln Kb.
#
# seacarb is therefore the CITED AUTHORITY; the fitted coefficients are a
# reproducible derivative of it, and tests/testthat/test-carbonate.R gates
# the whole chain against seacarb's full solver.
#
#   Gattuso J-P, Epitalon J-M, Lavigne H, Orr J (2024). seacarb: seawater
#   carbonate chemistry. R package. K1/K2 = Lueker et al. (2000),
#   K0 = Weiss (1974), Kb = Dickson (1990), total pH scale.
#
# Run from repo root:  Rscript data-raw/build_carbonate_tables.R [salinity] [out]
#
# SALINITY IS AN ARGUMENT (2026-10-12, citation rulings row 30). The model has
# TWO tables, selected by the structure label (R/carbonate.R's
# CARB_COEFS_BY_SALINITY), never by editing this file:
#   (no argument) S = 34.7, the uncited legacy value -> data/carbonate_coefs.rds,
#        which every registered mode ran on. NOT rebuilt: the shipped file is the
#        record. Rebuild it only into a scratch `out` to check reproduction.
#   `glodap`  S = the GLODAPv2.2023 0-100 m cos-lat-weighted salinity, RULED
#        34.760 ("Compute from GLODAP, adopt (Recommended)"), read from
#        data/obs_glodap_surface_alk_sal.rds -> data/carbonate_coefs_s34760.rds,
#        the table of label hilda_csl3v0kaidgbemwtc.
# The optional second argument overrides the output path (the reproduction
# check writes to a scratch file and compares against the shipped table).
# =====================================================================

suppressMessages(library(seacarb))

# ---- named constants -------------------------------------------------
SALINITY_LEGACY <- 34.7      # the uncited working value every registered mode ran on
SA_PRODUCT    <- file.path("data", "obs_glodap_surface_alk_sal.rds")
args          <- commandArgs(trailingOnly = TRUE)
SALINITY_REF  <- if (length(args) < 1 || identical(args[1], "34.7")) SALINITY_LEGACY else
  if (identical(args[1], "glodap")) readRDS(SA_PRODUCT)$salinity_ruled else
  stop("build_carbonate_tables.R: the salinity argument is `34.7` or `glodap`; got '", args[1], "'")
# Lueker et al. (2000) is validated for T = 2-35 degC, S = 19-43. The grid stays
# strictly inside that range: this model's boxes are HEMISPHERIC-MEAN mixed layers
# (~15-20 degC), so no evaluation approaches the endpoints. A future version with
# a separate polar box would need a different K1/K2 formulation.
T_GRID        <- seq(2, 35, by = 0.25)    # degC
K1K2_FORM     <- "l"         # Lueker et al. (2000)
KF_FORM       <- "pf"        # Perez & Fraga (1987)
PH_SCALE      <- "T"         # total scale
BORON_FORM    <- "u74"       # Uppstrom (1974) boron:salinity
# Fits are done in a CENTRED, SCALED temperature x = (T - T0)/Ts. Fitting in raw
# T is badly conditioned once T^5 reaches ~5e7, which showed up as a Kw fit 1000x
# worse than the other constants. Scaling fixes it; the scaling is stored with
# the coefficients so evaluation stays consistent.
POLY_DEGREE   <- 6           # in scaled T; validated below
# The output name DERIVES from the salinity (the labels-from-constants rule):
# the legacy name for 34.7, `carbonate_coefs_s<S x 1000>.rds` for anything else.
OUT_FILE      <- if (length(args) >= 2) args[2] else
  if (SALINITY_REF == SALINITY_LEGACY) "data/carbonate_coefs.rds" else
  sprintf("data/carbonate_coefs_s%05.0f.rds", SALINITY_REF * 1000)

cat("\n=== build_carbonate_tables.R ===\n")
cat(sprintf("S = %.3f, T grid %.1f..%.1f degC (n=%d), poly degree %d\n",
            SALINITY_REF, min(T_GRID), max(T_GRID), length(T_GRID), POLY_DEGREE))
cat(sprintf("seacarb %s; K1K2=%s, pH scale=%s, boron=%s\n\n",
            as.character(packageVersion("seacarb")), K1K2_FORM, PH_SCALE, BORON_FORM))

# ---- query seacarb ---------------------------------------------------
# NOTE ON K0 AND FUGACITY. [CO2*]/K0 is the FUGACITY fCO2, not the partial
# pressure pCO2; they differ by the fugacity coefficient phi = fCO2/pCO2
# ~ 0.9961 (10 degC) to 0.9970 (30 degC). Ignoring it puts a systematic
# -0.3 to -0.4 % bias on ocean pCO2, which biases the air-sea gradient and
# hence the ocean sink. We therefore store an EFFECTIVE K0,
#     K0_eff = K0 * phi(T),   so that  pCO2 = [CO2*] / K0_eff
# with phi taken from seacarb itself at each grid temperature.
k0_raw <- K0(S = SALINITY_REF, T = T_GRID, P = 0)
phi <- vapply(T_GRID, function(tt) {
  r <- carb(flag = 15, var1 = 2300e-6, var2 = 2000e-6, S = SALINITY_REF, T = tt, P = 0,
            k1k2 = K1K2_FORM, kf = KF_FORM, pHscale = PH_SCALE, b = BORON_FORM)
  r$fCO2 / r$pCO2
}, numeric(1))
k0 <- k0_raw * phi
k1 <- K1(S = SALINITY_REF, T = T_GRID, P = 0, k1k2 = K1K2_FORM, pHscale = PH_SCALE)
k2 <- K2(S = SALINITY_REF, T = T_GRID, P = 0, k1k2 = K1K2_FORM, pHscale = PH_SCALE)
kb <- Kb(S = SALINITY_REF, T = T_GRID, P = 0, pHscale = PH_SCALE)
kw <- Kw(S = SALINITY_REF, T = T_GRID, P = 0, pHscale = PH_SCALE)

# total boron (mol/kg) from salinity, Uppstrom (1974) as used by seacarb
bt <- bor(S = SALINITY_REF, b = BORON_FORM)

# ---- fit ln K = poly(T) ---------------------------------------------
T_CENTRE <- mean(range(T_GRID))
T_SCALE  <- diff(range(T_GRID)) / 2
x_grid   <- (T_GRID - T_CENTRE) / T_SCALE

# Per-constant fit tolerance. K0/K1/K2/Kb fit to ~1e-9. Kw does NOT: seacarb's
# Kw output carries a ~1.7e-3 oscillatory wiggle (largest at 2-12 degC) that is
# unchanged by raising the polynomial degree to 10 OR by using the physical
# (1/T, lnT, T) basis of the underlying formulation -- i.e. it is numerical noise
# in the upstream implementation, not a failure to fit. Kw enters only through
# [OH-], ~0.25 % of total alkalinity, so the impact on pCO2 is negligible; that
# claim is not taken on faith but GATED by test-carbonate.R ("Kw fit error is
# immaterial to pCO2"), which perturbs Kw by the fit error and measures pCO2.
FIT_TOL <- c(K0 = 1e-6, K1 = 1e-6, K2 = 1e-6, Kb = 1e-6, Kw = 5e-3)

fit_lnK <- function(K, label) {
  f  <- lm(log(K) ~ poly(x_grid, POLY_DEGREE, raw = TRUE))
  co <- unname(coef(f))
  pred <- exp(as.vector(cbind(1, outer(x_grid, 1:POLY_DEGREE, `^`)) %*% co))
  err <- max(abs(pred / K - 1))
  tol <- FIT_TOL[[label]]
  cat(sprintf("  %-4s max relative error over grid: %.3e  (tol %.0e)\n", label, err, tol))
  if (err > tol) {
    stop(sprintf("%s poly fit error %.2e exceeds its tolerance %.0e -- do not ship this table",
                 label, err, tol))
  }
  co
}

cat(sprintf("fugacity coefficient phi: %.6f (%.1f degC) .. %.6f (%.1f degC)\n",
            phi[1], T_GRID[1], phi[length(phi)], T_GRID[length(T_GRID)]))
cat("Polynomial fits (ln K vs T); K0 is the EFFECTIVE K0 = K0*phi:\n")
coefs <- list(
  K0 = fit_lnK(k0, "K0"),
  K1 = fit_lnK(k1, "K1"),
  K2 = fit_lnK(k2, "K2"),
  Kb = fit_lnK(kb, "Kb"),
  Kw = fit_lnK(kw, "Kw")   # water dissociation: [OH-] is ~0.25 % of TA, which
)                          # propagates to several % in pCO2 -- not negligible

out <- list(
  coefs        = coefs,
  poly_degree  = POLY_DEGREE,
  t_centre     = T_CENTRE,
  t_scale      = T_SCALE,
  salinity     = SALINITY_REF,
  boron_total  = bt,
  t_range      = range(T_GRID),
  provenance   = sprintf(
    "seacarb %s; K1K2=%s (Lueker 2000), K0=Weiss 1974 x fugacity coeff, Kb=Dickson 1990, Kw=Millero 1995, pH scale=%s, boron=%s (Uppstrom 1974); S=%s; built %s",
    as.character(packageVersion("seacarb")), K1K2_FORM, PH_SCALE, BORON_FORM,
    # %.1f for the legacy table (its stored string, byte for byte), full ruled
    # precision otherwise -- "S=34.8" would mislabel the 34.760 table.
    if (SALINITY_REF == SALINITY_LEGACY) sprintf("%.1f", SALINITY_REF) else sprintf("%.3f", SALINITY_REF),
    Sys.Date())
)
dir.create("data", showWarnings = FALSE)
saveRDS(out, OUT_FILE)

cat(sprintf("\ntotal boron = %.4e mol/kg\n", bt))
cat(sprintf("written -> %s\n", OUT_FILE))
cat("Gate: tests/testthat/test-carbonate.R checks the closed-form solver against\n")
cat("      seacarb's full system for pCO2 AND the Revelle factor.\n")
