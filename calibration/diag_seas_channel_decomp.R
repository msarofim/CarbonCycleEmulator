# =====================================================================
# diag_seas_channel_decomp.R -- WHICH CHANNEL OWNS THE SEASONAL MISFIT,
# IN WHICH HEMISPHERE, AND WITH WHAT ISOTOPIC SIGNATURE?
#
# THE QUESTION. Handoff 2026-08-20c section 2c test 1 asked for a per-hemisphere
# amplitude BUDGET: turn each seasonal channel off in turn and see which one
# owns the error. The 08-20d audit then sharpened the target. It is not only
# that the NH undershoots (-22 %) and the SH overshoots (+40 %) in CO2; it is
# that the seasonal cycle is TOO ISOTOPICALLY DEPLETED PER ppm at BOTH stations
# (1.53x at MLO, 2.54x at SPO). Photosynthesis moves CO2 at -18 permil, air-sea
# exchange at -2 (invasion) / -10 (evasion). So the budget worth computing is
# not amplitude alone -- it is each channel's CO2 contribution, its d13C
# contribution, and the RATIO between them, which is the channel's effective
# isotopic signature as the observable sees it.
#
# THE FOUR CHANNELS, and how each is switched off EXACTLY:
#   1. NEP / insolation   seas_npp_amp_{NH,SH} = 0   (added 2026-08-20f; the
#      other two already had exact switches and this one did not, because
#      CCX_SEAS_PHI_EFF is a compile-time constant in src/ccx_core.cpp)
#   2. Soil respiration   seas_T_amp_{NH,SH}   = 0   (q10^0 = 1, norm = 1)
#   3. Air-sea SST        sst_seas_amp_{NH,SH} = 0
#   4. Emission seasonality  FORC_USE_EMIS_SEASONALITY = FALSE -- the sourced
#      EDGAR/GFED hemispheric monthly weights. GLOBAL, not per hemisphere:
#      it is a forcing-side flag, and splitting it would mean rebuilding the
#      weights rather than flipping a switch. Included because it IS a seasonal
#      channel that the 08-20c channel list omitted, and it carries fossil
#      carbon at -27.9 permil, which is isotopically the most extreme thing in
#      the model.
# All four are zero-annual-mean or annual-budget-preserving, so none of them
# changes the model's carbon budget -- only its within-year distribution.
#
# THE DECOMPOSITION IS VECTORIAL, NOT SCALAR, AND THAT MATTERS. Each row scores
# a sin and a cos coefficient, so a channel's contribution has a PHASE as well
# as a size, and scalar amplitudes do not subtract. Contributions are therefore
# computed as the VECTOR difference (a, b)_base - (a, b)_off, whose magnitude is
# the channel's contribution and whose angle is when in the year it acts. A
# scalar reading is what made the 08-20 amplitude-only test wrong in both
# directions (handoff 2026-08-20c section 2d).
#
# AND THE SUM IS CHECKED. The model is nonlinear, so channel contributions are
# not guaranteed to add up to the total. The all-off case is run and the
# residual reported. If the channels do not sum, the budget is indicative and
# this script says so rather than presenting it as exact -- decompose_channels.
#
# Usage:  Rscript calibration/diag_seas_channel_decomp.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

CD_MODE_FILE <- ccx_path("calibration", "output", "pump_arms", "mode_fit_pumpN.rds")
CD_YEARS     <- c(1750, 2024)
CD_WINDOW    <- LIK_SEAS_WINDOW
CD_STREAMS   <- c(co2_MLO = "co2_seas.MLO", co2_SPO = "co2_seas.SPO",
                  d13_MLO = "d13_seas.MLO", d13_SPO = "d13_seas.SPO")
CD_SCORED    <- c("co2_seasonal_MLO", "co2_seasonal_SPO",
                  "d13c_seasonal_MLO", "d13c_seasonal_SPO")
# Each case is a modifier on the parameter list (and, for emis, on the forcing).
CD_CASES <- list(
  `NEP NH off`      = list(seas_npp_amp_NH = 0),
  `NEP SH off`      = list(seas_npp_amp_SH = 0),
  `resp NH off`     = list(seas_T_amp_NH   = 0),
  `resp SH off`     = list(seas_T_amp_SH   = 0),
  `air-sea NH off`  = list(sst_seas_amp_NH = 0),
  `air-sea SH off`  = list(sst_seas_amp_SH = 0),
  `emissions off`   = list(.emis = FALSE),
  `ALL model chans off` = list(seas_npp_amp_NH = 0, seas_npp_amp_SH = 0,
                              seas_T_amp_NH = 0, seas_T_amp_SH = 0,
                              sst_seas_amp_NH = 0, sst_seas_amp_SH = 0))
sep <- function(s) cat(sprintf("\n\n=== %s ===\n", s))

md <- readRDS(CD_MODE_FILE)
p0 <- ccx_default_params(); for (n in names(md$par_mode)) p0[[n]] <- md$par_mode[[n]]
p0$pump_mode <- md$pump_mode
cat(sprintf("mode %s (arm %s) | window %d-%d | seas_drivers %g\n",
            basename(CD_MODE_FILE), md$pump_mode, CD_WINDOW[1], CD_WINDOW[2], p0$seas_drivers))

obs <- ccx_prepare_obs()
pick <- function(ms, key) { k <- strsplit(key, ".", fixed = TRUE)[[1]]; ms[[k[1]]][[k[2]]] }
# Window-mean harmonic coefficients: average a and b, THEN take magnitude and
# angle. Averaging per-year magnitudes would inflate them by Jensen and
# averaging per-year angles wraps wrongly at the Dec/Jan seam.
vec_of <- function(h) if (is.null(h)) c(NA, NA) else c(mean(h$a), mean(h$b))
amp    <- function(v) 2 * sqrt(sum(v^2))          # PEAK-TO-PEAK, always
ang_mo <- function(v) 12 * ((atan2(v[1], v[2]) / (2 * pi)) %% 1)

cd_run <- function(mods = list()) {
  p <- p0
  emis <- TRUE
  for (n in names(mods)) if (n == ".emis") emis <- mods[[n]] else p[[n]] <- mods[[n]]
  old <- FORC_USE_EMIS_SEASONALITY
  assign("FORC_USE_EMIS_SEASONALITY", emis, envir = globalenv())
  on.exit(assign("FORC_USE_EMIS_SEASONALITY", old, envir = globalenv()))
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", CD_YEARS, prod_c14 = 0, bomb_total_kmol = 102)
  F$c14_cosmo <- sp$prod_c14
  F$c14_bomb  <- F$c14_bomb * (p$bomb_total / 102)
  for (cc in c("e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH"))
    F[[cc]] <- F[[cc]] * p$luc_scale
  attr(F, "luc_scale") <- p$luc_scale
  # luc_scale applied ONCE: the forcing above already carries it, so the second
  # multiply that stood here until 2026-08-22 was luc_scale SQUARED on the
  # gross-land-sink reconstruction. `luc` is read ONLY by `gcb_land_sink`, so that one
  # stream was wrong and nothing else. Use R/calibrate.R's ccx_scaled_forcing(), which
  # returns F and its eluc together so they cannot disagree.
  el <- ccx_forcing_eluc_annual(F)
  r  <- ccx_run_fast(sp, F)
  ms <- ccx_model_stats(r$out, obs)
  ll <- ccx_loglik(r$out, obs, list(sigma_d14c = p$sigma_d14c, rep_dC = p$rep_dC,
                                    grad_off_co2 = p$grad_off_co2,
                                    grad_off_d13c = p$grad_off_d13c),
                   luc = el, deep = sp$diagnostics$d14c_bottom_box,
                   ocean_grad = ccx_ocean_grad_scored(r$out, sp), by_stream = TRUE)
  list(v = lapply(CD_STREAMS, function(k) vec_of(pick(ms, k))), ll = ll)
}

base <- cd_run()
cases <- lapply(CD_CASES, cd_run)
obsv  <- lapply(CD_STREAMS, function(k) vec_of(pick(obs, k)))

# ---------------------------------------------------------------------
sep("1. WHERE THE MODEL STARTS (peak-to-peak, window-mean harmonic)")
cat(sprintf("  %-9s %10s %10s %9s | %12s %12s %8s\n",
            "station", "CO2 obs", "CO2 model", "err", "d13/CO2 obs", "model", "ratio"))
for (st in c("MLO", "SPO")) {
  ao <- amp(obsv[[paste0("co2_", st)]]); am <- amp(base$v[[paste0("co2_", st)]])
  do_ <- amp(obsv[[paste0("d13_", st)]]); dm <- amp(base$v[[paste0("d13_", st)]])
  cat(sprintf("  %-9s %10.3f %10.3f %+8.1f%% | %12.4f %12.4f %7.2fx\n",
              st, ao, am, 100 * (am / ao - 1), do_ / ao, dm / am, (dm / am) / (do_ / ao)))
}

# ---------------------------------------------------------------------
sep("2. THE AMPLITUDE BUDGET -- each channel's VECTOR contribution")
cat("  Contribution = |(a,b)_base - (a,b)_off|, peak-to-peak, with the month it\n")
cat("  peaks. 'sig' = the channel's own d13C-per-ppm signature at that station.\n\n")
for (st in c("MLO", "SPO")) {
  cat(sprintf("  --- %s (observed CO2 %.3f ppm, d13C %.4f permil, sig %.4f permil/ppm)\n",
              st, amp(obsv[[paste0("co2_", st)]]), amp(obsv[[paste0("d13_", st)]]),
              amp(obsv[[paste0("d13_", st)]]) / amp(obsv[[paste0("co2_", st)]])))
  cat(sprintf("  %-21s %9s %6s | %10s %6s | %9s\n",
              "channel", "dCO2 ppm", "peak", "dd13C", "peak", "sig"))
  for (nm in names(cases)) {
    dc <- base$v[[paste0("co2_", st)]] - cases[[nm]]$v[[paste0("co2_", st)]]
    dd <- base$v[[paste0("d13_", st)]] - cases[[nm]]$v[[paste0("d13_", st)]]
    cat(sprintf("  %-21s %9.3f %6.2f | %10.4f %6.2f | %9.4f\n",
                nm, amp(dc), ang_mo(dc), amp(dd), ang_mo(dd),
                if (amp(dc) > 1e-6) amp(dd) / amp(dc) else NA))
  }
  # LINEARITY CHECK: do the six model channels sum to the all-off case?
  sm <- Reduce(`+`, lapply(names(CD_CASES)[1:6], function(nm)
    base$v[[paste0("co2_", st)]] - cases[[nm]]$v[[paste0("co2_", st)]]))
  tot <- base$v[[paste0("co2_", st)]] - cases[["ALL model chans off"]]$v[[paste0("co2_", st)]]
  cat(sprintf("  %-21s %9.3f  vs all-off %.3f -> residual %+.3f ppm (%.1f %%)\n\n",
              "SUM of 6 channels", amp(sm), amp(tot), amp(sm) - amp(tot),
              100 * (amp(sm) - amp(tot)) / amp(tot)))
}

# ---------------------------------------------------------------------
sep("3. WHAT EACH CHANNEL COSTS THE SCORED ROWS (log-units, off minus base)")
cat(sprintf("  %-21s %11s %11s %11s %11s %11s\n", "channel",
            "co2_MLO", "co2_SPO", "d13c_MLO", "d13c_SPO", "seas TOTAL"))
cat(sprintf("  %-21s %11.1f %11.1f %11.1f %11.1f %11.1f\n", "(base level)",
            base$ll[["co2_seasonal_MLO"]], base$ll[["co2_seasonal_SPO"]],
            base$ll[["d13c_seasonal_MLO"]], base$ll[["d13c_seasonal_SPO"]],
            sum(base$ll[CD_SCORED])))
for (nm in names(cases)) {
  d <- vapply(CD_SCORED, function(s) cases[[nm]]$ll[[s]] - base$ll[[s]], 0)
  cat(sprintf("  %-21s %+11.1f %+11.1f %+11.1f %+11.1f %+11.1f\n", nm,
              d[1], d[2], d[3], d[4], sum(d)))
}
cat("\n  NEGATIVE = removing the channel makes the fit WORSE, i.e. the channel is\n")
cat("  earning its place. POSITIVE = the channel is COSTING the objective.\n")

sep("DONE")
