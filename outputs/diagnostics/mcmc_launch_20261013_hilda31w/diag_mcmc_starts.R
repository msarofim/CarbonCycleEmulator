# Read-only: reproduce run_mcmc_check.R's overdispersed starts for chains 1-4 and report WHY each is non-finite
for (f in list.files("R", pattern = "\\.R$", full.names = TRUE)) source(f)
md <- readRDS(ccx_mode_file(CCX_MODE_CANONICAL))
invisible(ccx_apply_gate(ccx_mode_struct(md))); PINS <- ccx_mode_pins(md); invisible(ccx_apply_pins(PINS))
invisible(ccx_adopt_mode_band(md))
u0 <- ccx_par_to_unc(md$par_mode); Sig <- ccx_mode_fit_stats(md)$cov; d <- length(u0)
bp <- ccx_mode_base(md); if (!is.null(md$pump_mode)) bp$pump_mode <- md$pump_mode
lpf <- ccx_make_logpost(base_params = bp, spinup_fn = ccx_spinup_from_label(ccx_mode_spinup(md)))
sdn <- sqrt(diag(Sig))
for (ch in 1:4) {
  RNGkind("Mersenne-Twister", "Inversion", "Rejection"); set.seed(20261001L + ch)
  us <- u0 + 2 * as.vector(stats::rnorm(d) %*% chol(Sig)); names(us) <- names(u0)
  ps <- ccx_unc_to_par(us)
  z  <- (us - u0) / sdn
  v  <- tryCatch(as.numeric(lpf(us)), error = function(e) paste("ERROR:", conditionMessage(e)))
  cat(sprintf("chain %d: logpost %s\n  h_ml %.2f (mode %.2f)  kz %.0f  seas_T_lag %.3f  bomb_share_NH %.3f\n  largest |z|: %s\n",
              ch, substr(as.character(v), 1, 240), ps$h_ml, md$par_mode$h_ml, ps$kz, ps$seas_T_lag, ps$bomb_share_NH,
              paste(sprintf("%s %+.1f", names(sort(abs(z), decreasing = TRUE))[1:5], z[names(sort(abs(z), decreasing = TRUE))[1:5]]), collapse = ", ")))
}
