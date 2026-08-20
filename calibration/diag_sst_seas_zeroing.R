# =====================================================================
# diag_sst_seas_zeroing.R -- WHY DID THE REFIT DRIVE `sst_seas_amp_{NH,SH}` TO
# ZERO? Bug, or degeneracy?
#
# THE OBSERVATION. The 2026-08-20 two-arm refit put `sst_seas_amp_NH` at
# -6.03 / -6.06 sigma and `sst_seas_amp_SH` at -4.72 / -4.63 (arms N / D), while
# `seas_T_amp_NH` went the other way, +3.83 / +3.78. Both SST amplitudes are
# LOG-transformed and positive-only, so negative z means shrinking toward zero.
#
# WHY THAT PATTERN IS WORTH A DIAGNOSTIC RATHER THAN A SHRUG. It is the exact
# signature of the SH phase bug caught on 2026-08-18: a wrong-phased mechanism
# cannot be REPAIRED by a log-amplitude, only ZEROED, so "the fit turned it off"
# and "the fit could not turn it round" look identical from the outside. That
# bug was found in the land seasonal-T sine, which had no hemisphere flip; the
# SST term was written with one, but written is not verified.
#
# THE COMPETING EXPLANATION, and it is a priori just as good. Both the ocean
# seasonal term and the land respiration counter-cycle REDUCE the net seasonal
# CO2 amplitude, which at defaults overshoots (MLO 4.77 vs obs 3.02). Two   <-- WRONG, see CORRECTION below
# mechanisms with the same sign of effect on the dominant stream are DEGENERATE;
# a fit will load one and null the other, and which one it picks is not
# physics. Under that reading nothing is broken and the zeroing is a
# identifiability statement.
#
# THREE TESTS, each of which separates those two.
#   1. GEOMETRY, measured not asserted: the peak MONTH of every seasonal driver.
#      A mis-phased ocean term shows here and nowhere else.
#   2. WHAT THE OCEAN TERM BUYS at the mode: amplitudes at the fitted value, at
#      the prior centre, and at zero. If the ocean term moves the amplitude the
#      WRONG way at the mode, that is the bug; if it moves it the right way and
#      the fit still zeroed it, that is degeneracy.
#   3. ISO-OBSERVABLE PROFILE of `sst_seas_amp_NH` with everything else frozen
#      (the match_incumbents_optim discipline: a challenger evaluated on a slice
#      the incumbent is not re-optimised over).
#
#
# ---------------------------------------------------------------------
# CORRECTION, 2026-08-20 (diag_seasonal_phase_obs_vs_model.R + diag_seas_lag_profile.R)
#
# THE OBSERVED TARGETS QUOTED BELOW ARE A FACTOR OF 2 OUT, AND THE CONCLUSION
# THEY SUPPORT INVERTS. "obs 3.02 ppm / 0.55 ppm / 0.178 permil" are
# SEMI-amplitudes, mean(sqrt(a^2 + b^2)); every model number in this script is
# 2 * mean(sqrt(a^2 + b^2)), PEAK-TO-PEAK. The peak-to-peak observed values are
# MLO CO2 6.764 ppm, SPO CO2 1.196 ppm, MLO d13C 0.358 permil (1975-2024), and
# the raw NOAA monthly climatology (co2_ppm - co2_deseas, 1990-2014) gives an
# independent MLO peak-to-trough of 6.61 ppm.
#
# WHAT THAT CHANGES. The model does not OVERSHOOT the MLO seasonal cycle -- it
# UNDERSHOOTS it, 5.24 against 6.76 at the mode. So the header's premise ("at
# defaults overshoots, MLO 4.77 vs obs 3.02") and the degeneracy reading built
# on it ("two mechanisms with the same sign of effect on the dominant stream")
# both fail: the ocean seasonal term is zeroed because it DAMPS a cycle that is
# already too small, which needs no phase bug to explain.
#
# AND THE PHASE HYPOTHESIS DID NOT SURVIVE ITS OWN DECISIVE TEST. Measured
# against the observed cycle the likelihood scores, the model at the mode peaks
# 0.09 MONTHS early at MLO (SPO -0.51, d13C MLO +0.40) -- not 1-2 months late.
# Profiling CCX_SEAS_T_LAG at the mode makes the shipped 2.0 a clean interior
# optimum that beats the "climatological" mid-July peak (LAG = 0) by 18,944
# log-units on the seasonal rows. The constant multiplies SOIL respiration, not
# air temperature, and soil temperature genuinely lags air temperature -- so it
# is the COMMENT ("seasonal land T peak after Jun") that is wrong, not the 2.0.
# Three of the four seasonal rows are AMPLITUDE-dominated in cost.
# ---------------------------------------------------------------------
#
# Usage:  Rscript calibration/diag_sst_seas_zeroing.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

SSTZ_MODE_FILE <- ccx_path("calibration", "output", "pump_arms", "mode_fit_pumpN.rds")
SSTZ_PROFILE   <- c(1e-4, 0.01, 0.05, 0.1, 0.25, 0.5, 1.0, 2.0, 3.0, 4.0)  # K
SSTZ_MONTHS    <- c("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec")
# PEAK-TO-PEAK observed first-harmonic amplitudes, 1975-2024, on the SAME
# definition as amps() below (2 * mean(sqrt(a^2 + b^2))). Named, because the
# inline literals these replace were semi-amplitudes and nothing caught it.
SSTZ_OBS_P2P   <- c(co2_MLO = 6.764, co2_SPO = 1.196, d13c_MLO = 0.358, d13c_SPO = 0.045)
sep <- function(s) cat(sprintf("\n\n=== %s ===\n", s))

md <- readRDS(SSTZ_MODE_FILE)
p_mode <- ccx_default_params()
for (n in intersect(names(p_mode), names(md$par_mode))) p_mode[[n]] <- md$par_mode[[n]]
cat(sprintf("mode: %s (arm %s, logpost %.2f)\n", basename(SSTZ_MODE_FILE),
            md$pump_mode, md$logpost))
cat(sprintf("fitted sst_seas_amp NH %.4f K, SH %.4f K (prior centres 2.0 / 1.2)\n",
            p_mode$sst_seas_amp_NH, p_mode$sst_seas_amp_SH))
cat(sprintf("fitted seas_T_amp    NH %.4f K, SH %.4f K\n",
            p_mode$seas_T_amp_NH, p_mode$seas_T_amp_SH))

# ---- TEST 1: geometry, measured -------------------------------------
# Every driver evaluated on a monthly grid and its PEAK MONTH reported. The
# expectation each must meet is stated next to it, so a wrong answer is a
# failure rather than a number to interpret afterwards.
sep("TEST 1 -- PEAK MONTH OF EACH SEASONAL DRIVER (geometry, measured)")
tt <- (seq_len(12) - 0.5) / 12
peak <- function(v) SSTZ_MONTHS[which.max(v)]
trough <- function(v) SSTZ_MONTHS[which.min(v)]
for (h in HEMIS) {
  sgn  <- if (h == "NH") 1 else -1
  sstv <- sgn * sin(2 * pi * (tt - (3.5 + CCX_SST_SEAS_LAG) / 12))
  tlnd <- sgn * sin(2 * pi * (tt - (3.5 + CCX_SEAS_T_LAG) / 12))
  insv <- vapply(tt, function(x)
    ccx_insol(CCX_SEAS_PHI_EFF[[h]], x - p_mode$seas_lag_p / 12), numeric(1))
  cat(sprintf("[%s] seasonal SST      peaks %s (expect ocean max late summer: %s)\n",
              h, peak(sstv), if (h == "NH") "Aug-Sep" else "Feb-Mar"))
  cat(sprintf("[%s] land seasonal T   peaks %s (expect land max mid-summer: %s)\n",
              h, peak(tlnd), if (h == "NH") "Jul" else "Jan"))
  cat(sprintf("[%s] insolation/NPP    peaks %s (expect %s)\n",
              h, peak(insv), if (h == "NH") "Jun-Jul" else "Dec-Jan"))
  cat(sprintf("[%s] SST vs land-T lag: %s vs %s -- ocean must lag land\n\n",
              h, peak(sstv), peak(tlnd)))
}
# ---- shared machinery for tests 2 and 3 -----------------------------
obs <- ccx_prepare_obs()
lp  <- ccx_make_logpost(base_params = local({ b <- ccx_default_params()
                                             b$pump_mode <- md$pump_mode; b }))
u_mode <- md$u_mode; names(u_mode) <- md$param_names

# Seasonal amplitudes the model produces, via the SAME estimator the likelihood
# uses (ccx_year_harmonic), so these are comparable with the scored rows rather
# than with a different definition of "amplitude".
amps <- function(p) {
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = 0, bomb_total_kmol = 102)
  F$c14_cosmo <- sp$prod_c14
  r  <- ccx_run_fast(sp, F)$out
  g  <- function(col, lo, hi) {
    z <- ccx_year_harmonic(r$t, r[[col]])
    z <- z[z$year >= lo & z$year <= hi, ]
    2 * mean(sqrt(z$a^2 + z$b^2), na.rm = TRUE)
  }
  c(co2_NH = g("co2_NH", 1990, 2014), co2_SH = g("co2_SH", 1990, 2014),
    d13c_NH = g("d13c_NH", 1990, 2014), d13c_SH = g("d13c_SH", 1990, 2014))
}
set_amp <- function(p, nh, sh) { p$sst_seas_amp_NH <- nh; p$sst_seas_amp_SH <- sh; p }

sep("TEST 2 -- WHAT THE OCEAN TERM BUYS AT THE MODE")
cat("Peak-to-peak seasonal amplitude, 1990-2014, via ccx_year_harmonic().\n")
cat(sprintf("Observed (the scored targets), PEAK-TO-PEAK: %s\n\n",
            paste(sprintf("%s %.3f", names(SSTZ_OBS_P2P), SSTZ_OBS_P2P), collapse = ", ")))
CASES <- list(
  `fitted (the refit's answer)` = c(p_mode$sst_seas_amp_NH, p_mode$sst_seas_amp_SH),
  `prior centre 2.0 / 1.2`      = c(2.0, 1.2),
  `ocean term OFF (1e-6)`       = c(1e-6, 1e-6),
  `double the prior centre`     = c(4.0, 2.4))
A <- t(vapply(names(CASES), function(k)
  amps(set_amp(p_mode, CASES[[k]][1], CASES[[k]][2])), numeric(4)))
print(round(A, 4))
cat(sprintf("\nDIRECTION TEST -- does MORE ocean amplitude move MLO CO2 toward obs (%.3f)?\n",
            SSTZ_OBS_P2P[["co2_MLO"]]))
d_off <- A["ocean term OFF (1e-6)", "co2_NH"]; d_hi <- A["double the prior centre", "co2_NH"]
cat(sprintf("  OFF -> 2x prior: %.3f -> %.3f ppm. Obs %.3f. Amplitude moves %s.\n",
            d_off, d_hi, SSTZ_OBS_P2P[["co2_MLO"]],
            if (abs(d_hi - SSTZ_OBS_P2P[["co2_MLO"]]) < abs(d_off - SSTZ_OBS_P2P[["co2_MLO"]]))
              "TOWARD obs" else "AWAY from obs"))
# DO NOT CONCLUDE FROM THIS ALONE. An earlier version of this script printed
# "the mechanism works and the fit zeroed it anyway -> DEGENERACY, not a phase
# bug" here, and that was WRONG. AMPLITUDE IS NOT WHAT THE LIKELIHOOD SCORES:
# ccx_year_harmonic() returns sin and cos coefficients, so the rows carry
# AMPLITUDE AND PHASE. Measured 2026-08-20, moving sst_seas_amp_NH from the
# fitted 0.089 K to the physical 2.0 K costs co2_seasonal_MLO -673.4 while the
# amplitude improves 5.30 -> 3.89 ppm: the amplitude gets better and the PHASE
# rotates away. A direction test on amplitude alone cannot see that.
cat("  AMPLITUDE ONLY -- not a verdict. The scored rows carry phase too; see the\n")
cat("  per-stream test below, and TEST 1's peak months, before concluding.\n")

sep("TEST 3 -- ISO-OBSERVABLE PROFILE of sst_seas_amp_NH (all else FROZEN)")
cat("Everything but sst_seas_amp_NH held at the mode -- so this is the slice the\n")
cat("fit actually saw, not a re-optimised comparison (match_incumbents_optim).\n\n")
k <- which(md$param_names == "sst_seas_amp_NH")
lp0 <- lp(u_mode)
cat(sprintf("%-12s %14s %12s\n", "amp (K)", "logpost", "delta"))
for (a in SSTZ_PROFILE) {
  u <- u_mode; u[k] <- .to_unc(a, CCX_PARAM_TABLE$sst_seas_amp_NH)
  v <- lp(u)
  cat(sprintf("%-12.4g %14.3f %+12.3f%s\n", a, v, v - lp0,
              if (abs(a - p_mode$sst_seas_amp_NH) < 1e-9) "   <- fitted" else ""))
}
cat(sprintf("\nfitted value %.5g K, logpost %.3f\n", p_mode$sst_seas_amp_NH, lp0))
# MEASURED 2026-08-20: the profile is a clean INTERIOR optimum at ~0.09 K --
# -165 at 1e-4 and -513 at the physical 2.0 K. So the parameter is NOT railing
# and the mode-find is NOT at fault: the LIKELIHOOD genuinely wants ~0.09 K.
# The -6 sigma is against the PRIOR. What that means is the open question --
# a phase-sensitive stream telling us the physical value is 513 log-units
# wrong is a statement about the GEOMETRY (TEST 1), not about the ocean.
cat("Read the SHAPE, not a slogan: interior optimum => the likelihood wants this\n")
cat("value; rail-to-zero => the prior is all that is holding it. As of 2026-08-20\n")
cat("it is INTERIOR at ~0.09 K, so the question is why the physical value is so\n")
cat("expensive -- see TEST 1's peak months.\n")
