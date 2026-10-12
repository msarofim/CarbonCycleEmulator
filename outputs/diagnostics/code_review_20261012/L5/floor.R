setwd("/Users/MarcusMarcus/Documents/2026/CodeProjects/CarbonCycleEmulator")
for (f in list.files("R", pattern="\\.R$", full.names=TRUE)) source(f)
lm <- ccx_load_mode(); p <- lm$p
sp <- ccx_periodic_spinup(p)
cat("converged: resid_carbon", sp$periodic$resid_carbon, " hist", format(sp$periodic$resid_history, digits=3), "\n")
PS_TOL <- 1e-15; PS_MAXIT <- 4L     # scratch override: measure the Newton's floating-point FLOOR
sp2 <- suppressWarnings(ccx_periodic_spinup(p, seed = sp))
cat("floor probe from the converged state:", format(sp2$periodic$resid_history, digits=3), " final", sp2$periodic$resid_carbon, "\n")
# perturbed parameters: a few draws along sd_unc to see resid_carbon spread
md <- lm$md; set.seed(20261012)
PS_TOL <- 1e-9; PS_MAXIT <- 40L
fs <- ccx_mode_fit_stats(md)
for (k in 1:4) {
  pm <- ccx_mode_par_with_pins(md)
  for (n in c("kz","h_ml","beta_max","q10","k_w")) pm[[n]] <- pm[[n]] * exp(rnorm(1, 0, 0.1))
  rp <- ccx_mode_run_params(md, pm)
  s <- withCallingHandlers(ccx_periodic_spinup(rp$p), warning=function(w) {cat("  WARN", conditionMessage(w), "\n"); invokeRestart("muffleWarning")})
  cat(sprintf("  draw %d: iters %d resid_carbon %.3e resid_state %.3e\n", k, s$periodic$iterations, s$periodic$resid_carbon, s$periodic$resid_state))
}
