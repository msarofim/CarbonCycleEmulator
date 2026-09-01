# =====================================================================
# CAN A SEASONALLY-VARYING INTERHEMISPHERIC EXCHANGE SEPARATE THE STEADY
# GRADIENT FROM THE BOMB-SPIKE LAG?
#
# Marcus's hypothesis, 2026-08-31, offered as a cheaper alternative to adding
# tropical boxes: "is the idea that transport rates might be different in
# different seasons?" -- the ITCZ migrates, so cross-equatorial exchange really
# is seasonally modulated.
#
# WHY IT COULD WORK. DESIGN gate 5 fails STRUCTURALLY: the steady
# interhemispheric gradient wants tau_ex ~ 1.159 yr and the bomb-spike lag wants
# ~2.3, and ONE scalar cannot be both. A single well-mixed two-box exchange has
# an exponential transit-time distribution FULLY DETERMINED by its one rate --
# mean and shape are the same number. A seasonal modulation is a SHAPE knob at
# FIXED MEAN: it is applied to the RATE with a zero-mean sinusoid, so the annual
# mean exchange rate is preserved exactly (and with it the steady gradient) while
# the transient response to a spike injected at a particular time of year is not.
#
# ⚠ WHAT WOULD REFUTE IT. If the lag barely moves, or moves only by dragging the
# gradient with it, then a seasonal rate is not the missing degree of freedom and
# the tropical-box route is the one left. THAT IS THE POINT OF MEASURING IT --
# the mechanism is cheap to add and expensive to assume.
#
# ⚠ NOTHING HERE IS ADOPTED. `tau_ex_seas_amp` defaults to 0 and is NOT one of
# the 22 fitted parameters. Amplitude 0 is the shipped model bit for bit.
#
# Run:  Rscript calibration/diag_seasonal_tau_ex.R      (~8 min)
# =====================================================================

for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
ccx_load_cpp()

TX_MODE  <- file.path("calibration", "output", "refit_20260830_gamma_diff_remap",
                      "from90", "mode_fit_pumpN.rds")
TX_YEARS <- c(1750, 2024)
TX_AMP   <- c(0, 0.3, 0.6, 0.9)
TX_PHASE <- c(0, 3, 6, 9)          # months
TX_OUT   <- "outputs/diagnostics/seasonal_tau_ex.rds"
# DESIGN gate 5's own benchmark (Hua et al. 2022 hemispheric aggregate), copied
# from diag_design_gates_at_mode.R so the two are commensurable.
TX_OBS_LAG <- 1.33
TX_EFOLD_FLOOR <- 20

md <- readRDS(TX_MODE); ccx_adopt_mode_band(md)
pv <- ccx_mode_params(TX_MODE)

tx_peak <- function(t, v) {            # parabolic refinement, gate 5's estimator
  i <- which.max(v)
  if (i <= 1 || i >= length(v)) return(t[i])
  y1 <- v[i - 1]; y2 <- v[i]; y3 <- v[i + 1]
  d <- 0.5 * (y1 - y3) / (y1 - 2 * y2 + y3)
  t[i] + d * (t[i + 1] - t[i])
}
run_at <- function(amp, phase) {
  p <- ccx_default_params()
  for (n in intersect(names(p), CCX_PARAM_NAMES)) p[[n]] <- pv[[n]]
  p <- ccx_set_enso(p, pv); p$pump_mode <- md$pump_mode
  # the mode is a 21-parameter file: give both lag halves its legacy scalar
  p$seas_lag_p_NH <- pv$seas_lag_p; p$seas_lag_p_SH <- pv$seas_lag_p
  p$tau_ex_seas_amp <- amp; p$tau_ex_seas_phase <- phase
  sp <- ccx_spinup(p)
  F <- ccx_build_forcing("historical", TX_YEARS, prod_c14 = 0, bomb_total_kmol = 102)
  F$c14_cosmo <- sp$prod_c14; F$c14_bomb <- F$c14_bomb * (pv$bomb_total / 102)
  for (cc in c("e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH"))
    F[[cc]] <- F[[cc]] * pv$luc_scale
  attr(F, "luc_scale") <- pv$luc_scale
  o <- ccx_run_fast(sp, F)$out
  # THE TWO QUANTITIES THAT MUST MOVE INDEPENDENTLY
  lag <- tx_peak(o$t, o$d14c_SH) - tx_peak(o$t, o$d14c_NH)
  k   <- o$t >= 1980 & o$t <= 2024          # modern, post-bomb, steady-ish
  grad_co2  <- mean(o$co2_NH[k] - o$co2_SH[k])
  grad_d13c <- mean(o$d13c_NH[k] - o$d13c_SH[k])
  list(lag = lag, grad_co2 = grad_co2, grad_d13c = grad_d13c)
}

cat(sprintf("mode %s | observed bomb lag %.2f yr (Hua 2022 hemispheric aggregate)\n\n",
            basename(dirname(TX_MODE)), TX_OBS_LAG))
base <- run_at(0, 0)
cat(sprintf("BASELINE (amp 0): lag %.3f yr | CO2 gradient %.4f ppm | d13C gradient %.4f permil\n",
            base$lag, base$grad_co2, base$grad_d13c))
cat(sprintf("                  lag GAP to observed: %+.3f yr\n\n", base$lag - TX_OBS_LAG))

cat(sprintf("%6s %7s | %9s %10s | %11s %11s\n",
            "amp", "phase", "lag (yr)", "d lag", "d grad CO2", "d grad d13C"))
rows <- list()
for (a in TX_AMP) for (ph in (if (a == 0) 0 else TX_PHASE)) {
  r <- run_at(a, ph)
  rows[[length(rows) + 1]] <- data.frame(amp = a, phase = ph, lag = r$lag,
    grad_co2 = r$grad_co2, grad_d13c = r$grad_d13c,
    dlag = r$lag - base$lag, dgco2 = r$grad_co2 - base$grad_co2,
    dgd13 = r$grad_d13c - base$grad_d13c)
  x <- rows[[length(rows)]]
  cat(sprintf("%6.1f %7.0f | %9.3f %+10.3f | %+11.5f %+11.5f\n",
              x$amp, x$phase, x$lag, x$dlag, x$dgco2, x$dgd13))
}
res <- do.call(rbind, rows)
dir.create(dirname(TX_OUT), recursive = TRUE, showWarnings = FALSE)
saveRDS(list(res = res, base = base, obs_lag = TX_OBS_LAG, mode = TX_MODE), TX_OUT)

need <- TX_OBS_LAG - base$lag
best <- res[which.max(res$dlag), ]
cat("\n=====================================================================\n")
cat("SCORING MARCUS'S HYPOTHESIS\n")
cat("=====================================================================\n")
cat(sprintf("  the lag has to move %+.3f yr to reach the observation\n", need))
cat(sprintf("  the BEST cell moves it %+.3f yr (amp %.1f, phase %.0f) = %.0f %% of the way\n",
            best$dlag, best$amp, best$phase, 100 * best$dlag / need))
cat(sprintf("  and it moves the CO2 gradient by %+.5f ppm (%.2f %% of the gradient itself)\n",
            best$dgco2, 100 * abs(best$dgco2 / base$grad_co2)))
cat("\n  ⚠ READ THE RATIO, NOT THE SIGN. A seasonal rate is worth having only if\n")
cat("    it moves the LAG substantially while leaving the GRADIENT alone. Moving\n")
cat("    both is what the single scalar already does.\n")
