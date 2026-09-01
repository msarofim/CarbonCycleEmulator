# =====================================================================
# diag_enso_model_vs_obs.R -- DOES THE MODEL'S ENSO SINK RESPONSE HAVE THE RIGHT
# MAGNITUDE, MEASURED AS A REGRESSION OVER THE WHOLE RECORD?
#
# WHY THIS SHAPE AND NOT AN EVENT. Marcus, 2026-09-01: "every ENSO is going to
# have somewhat different impacts on land and ocean carbon, our best will only
# ever capture the average response (modulated by intensity)." A one-parameter
# ENSO response cannot be tested on one event -- my attempt to do that was
# retracted at 0.6 sigma ([[ke2026_elnino_ocean_sign]]). The testable claim is
# about the AVERAGE SENSITIVITY, so the estimator is a regression slope over
# 1959-2024 (n = 66 years), not a difference across two.
#
# THE TARGETS ARE MEASURED, NOT ASSUMED. `diag_enso_sink_power.R` established
# that the observable is not blind and fixed every free choice -- index, lag,
# detrending order -- and returned ([[enso_sink_sensitivity_target]]):
#     land  -0.665 GtC/yr per degC Nino3.4   (r -0.677, 65 -> 65 n_eff)
#     ocean +0.119 GtC/yr per degC Nino3.4   (r +0.535, 65 -> 45 n_eff)
# Those are what the model is scored against here, with the SAME estimator
# (lib_enso_regression.R) applied to both sides.
#
# ⚠ THIS IS NOT AN INDEPENDENT VALIDATION, AND MUST NOT BE READ AS ONE. The
# model is DRIVEN by this very index through `gamma_enso`, so a non-zero model
# slope is guaranteed by construction. What is NOT guaranteed -- and is what
# this measures -- is that the induced sensitivity has the right MAGNITUDE and
# SIGN in each reservoir. A model can be handed the right index and still route
# too little of it, or route it to the wrong reservoir.
#
# ⚠ AND THE SIGNS ARE NOT INDEPENDENT OF EACH OTHER. Atmospheric CO2 growth is
# the residual of emissions minus both sinks, so an error shared between land
# and ocean partly cancels in the growth rate. Both are reported, and so is the
# growth-rate slope, because the partition is the thing at issue.
#
# ⛔ ADOPTS NOTHING.
#
# Usage:  Rscript calibration/diag_enso_model_vs_obs.R    # ~20 s
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
source(ccx_path("calibration", "lib_design_gates.R"))
source(ccx_path("calibration", "lib_enso_regression.R"))

EM_MODES <- c(incumbent   = "calibration/output/refit_20260831_seas_lag_split/from90/mode_fit_pumpN.rds",
              `new basin` = "calibration/output/polish_20260831_probe_basin/from90/mode_fit_pumpN.rds")
EM_YRS   <- c(1959, 2024)          # = the GCB record the targets were measured on

cat(sprintf("\n%s\nTHE ENSO SINK SENSITIVITY: MODEL vs OBSERVED, AS A SLOPE OVER %d-%d\n  estimator shared with diag_enso_sink_power.R; index %s, detrend deg %d\n%s\n",
            strrep("=", 78), EM_YRS[1], EM_YRS[2], ER_INDEX, ER_DEG, strrep("=", 78)))

g <- as.data.frame(ccx_prepare_obs()$gcb)
g <- g[g$year >= EM_YRS[1] & g$year <= EM_YRS[2], ]

# ---- the observed targets, re-measured here rather than quoted -------
# ⚠ RE-MEASURED, NOT HARDCODED: a target typed in from another file's output
# goes stale silently the day that file's convention moves.
OBS <- list()
for (nm in c(land = "land_sink", ocean = "ocean_sink")) {
  lab <- names(which(c(land = "land_sink", ocean = "ocean_sink") == nm))[1]
  OBS[[lab]] <- er_best_lag(g$year, er_detrend(g[[nm]], g$year))
}
cat("\nOBSERVED (GCB), the targets:\n")
for (lab in names(OBS)) {
  o <- OBS[[lab]]
  cat(sprintf("  %-6s slope %+7.3f GtC/yr per degC   r %+.3f  [%+.3f, %+.3f]  lag %2d mo  n_eff %.1f\n",
              lab, o$slope, o$r, o$ci[1], o$ci[2], o$lag, o$n_eff))
}

# ---- the model, same estimator, same lag as the observation ----------
cat("\nMODEL, at each mode (same index, same detrending, each scored at the\nOBSERVED series' own best lag so the two are like-for-like):\n")
res <- list()
for (mn in names(EM_MODES)) {
  v <- dg_vector(EM_MODES[[mn]]); a <- dg_annual_sinks(dg_run(v))
  k <- a$year >= EM_YRS[1] & a$year <= EM_YRS[2]
  yrs <- a$year[k]
  for (lab in c("land", "ocean")) {
    y  <- er_detrend(a[[lab]][k], yrs)
    cc <- er_cor(er_index_annual(yrs, ER_INDEX, OBS[[lab]]$lag), y)
    res[[paste(mn, lab)]] <- cc
  }
  gr <- er_cor(er_index_annual(yrs, ER_INDEX, OBS$land$lag), er_detrend(a$growth_ppm[k], yrs))
  res[[paste(mn, "growth")]] <- gr
  cat(sprintf("\n  %s (%s)\n", toupper(mn), v$src))
  for (lab in c("land", "ocean")) {
    cc <- res[[paste(mn, lab)]]; o <- OBS[[lab]]
    frac <- cc$slope / o$slope
    cat(sprintf("    %-6s slope %+7.3f vs obs %+7.3f  =>  %5.0f %% of observed\n           r %+.3f  95%% CI [%+.3f, %+.3f]  p %.4f  n_eff %.1f  resid sd %.3f (obs %.3f)\n",
                lab, cc$slope, o$slope, 100 * frac,
                cc$r, cc$ci[1], cc$ci[2], cc$p, cc$n_eff, cc$sd_y, o$sd_y))
    cat(sprintf("    %-6s %s\n", "",
                if (sign(cc$slope) != sign(o$slope)) "*** WRONG SIGN ***"
                else if (frac < 0.5) "RIGHT SIGN, LESS THAN HALF the observed sensitivity"
                else if (frac > 1.5) "RIGHT SIGN, MORE THAN 1.5x the observed sensitivity"
                else "RIGHT SIGN, within a factor 1.5 of observed"))
  }
  cat(sprintf("    %-6s slope %+7.3f ppm/yr per degC (obs GCB growth is a DERIVED row; not scored)\n",
              "growth", res[[paste(mn, "growth")]]$slope))
}

# ---- the verdict, as a RATIO with the sign called separately ---------
cat(sprintf("\n%s\nSUMMARY -- fraction of the observed sensitivity captured\n%s\n",
            strrep("-", 78), strrep("-", 78)))
cat(sprintf("  %-12s %14s %14s\n", "", "land", "ocean"))
cat(sprintf("  %-12s %+14.3f %+14.3f   <- the targets\n", "observed",
            OBS$land$slope, OBS$ocean$slope))
for (mn in names(EM_MODES))
  cat(sprintf("  %-12s %13.0f%% %13.0f%%\n", mn,
              100 * res[[paste(mn,"land")]]$slope  / OBS$land$slope,
              100 * res[[paste(mn,"ocean")]]$slope / OBS$ocean$slope))
# ---- is the ocean result an artefact of the detrending order? ---------
cat(sprintf("\n%s\nDETRENDING SENSITIVITY of the OCEAN slope (the result that matters)\n%s\n",
            strrep("-", 78), strrep("-", 78)))
cat(sprintf("  %-12s %10s %10s %10s\n", "", "deg 1", "deg 2", "deg 3"))
cat(sprintf("  %-12s %10.3f %10.3f %10.3f\n", "observed",
    er_cor(er_index_annual(g$year, ER_INDEX, OBS$ocean$lag), er_detrend(g$ocean_sink, g$year, 1))$slope,
    er_cor(er_index_annual(g$year, ER_INDEX, OBS$ocean$lag), er_detrend(g$ocean_sink, g$year, 2))$slope,
    er_cor(er_index_annual(g$year, ER_INDEX, OBS$ocean$lag), er_detrend(g$ocean_sink, g$year, 3))$slope))
for (mn in names(EM_MODES)) {
  v <- dg_vector(EM_MODES[[mn]]); a <- dg_annual_sinks(dg_run(v))
  k <- a$year >= EM_YRS[1] & a$year <= EM_YRS[2]; yrs <- a$year[k]
  sl <- vapply(ER_DEGS, function(d)
    er_cor(er_index_annual(yrs, ER_INDEX, OBS$ocean$lag),
           er_detrend(a$ocean[k], yrs, d))$slope, numeric(1))
  cat(sprintf("  %-12s %10.3f %10.3f %10.3f\n", mn, sl[1], sl[2], sl[3]))
}

cat("\n  ⚠ NOT an independent validation: the model is DRIVEN by this index through\n")
cat("    `gamma_enso`, so a non-zero slope is guaranteed. The MAGNITUDE is not.\n")
cat("  ⚠ The ocean target itself clears its own detection floor by only 1.3x\n")
cat("    (diag_enso_sink_power.R), so read the ocean ratio as an order, not a value.\n")
cat(sprintf("\n⛔ NOTHING ADOPTED.\n%s\n", strrep("=", 78)))
