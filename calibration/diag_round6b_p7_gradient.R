# =====================================================================
# diag_round6b_p7_gradient.R -- PREREG P7 for round 6b (the refit under the corrected observables; 09-11 (7)) ("NOT A DEEP LEVER IN
# DISGUISE": the modern surface-deep d13C gradient must not move by more than
# the ocean_grad_d13c row's sigma_eff, 0.16). Measures the scored DIC and d13C
# gradients (ccx_ocean_grad_scored, the objective's own path) at hilda31p
# (seas_ml 0) and at the round-6 modes (seas_ml 1). 2026-09-11.
# RESULT (09-11, instant-over-mean-mass read, RETRACTED): d13C gradient -0.309
# -> +0.018, DIC 302 -> 385 -- the DIC half was an OBSERVABLE ARTIFACT (157
# umol/kg of surface mass) ⇒ diag_seasonal_box_observable_artefact.R.
# RESULT (09-11 (5), ANNUAL-MEAN read, round6_p7_annualmean.log): DIC 300 -> 227
# (target 233, z -0.2: AT the observation); d13C -0.300 -> +0.031, still 2.0x
# the bound -- but at an UNREFIT mode whose deep box the fit moved to cancel
# the artifact. The mechanism's own P7 verdict waits on the refit.
# =====================================================================
suppressMessages(for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)); ccx_load_cpp()
D <- "calibration/output/multistart_20260911_round6b_seasml1_sd1.0452"
tg <- ccx_ocean_gradient_target()
# each file's OWN structure and seas_ml through the one resolver (converted 2026-09-11 on touch --
# test-mode-struct-lint.R; the numbers above reproduced under the conversion)
grad_at <- function(mdx) {
  pm <- mdx$par_mode
  bp <- ccx_mode_base(mdx); bp$pump_mode <- mdx$pump_mode
  p <- ccx_overlay_par(bp, pm); sp <- CCX_OBJECTIVE_SPINUP(p)
  F <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = 0, bomb_total_kmol = 102)
  F$c14_cosmo <- sp$prod_c14; F$c14_bomb <- F$c14_bomb * (pm$bomb_total / 102)
  for (cc in c("e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH")) F[[cc]] <- F[[cc]] * pm$luc_scale
  attr(F, "luc_scale") <- pm$luc_scale
  r <- ccx_run_fast(sp, F); og <- ccx_ocean_grad_scored(r$out, sp)
  c(dic = og$dic, d13c = og$d13c, sd_dic = og$sd_eff[["dic"]], sd_d13c = og$sd_eff[["d13c"]], h_ml = sp$grid$h_ml)
}
g0 <- grad_at(readRDS(ccx_mode_file(CCX_MODE_SEASML0_CONTROL)))
g1 <- grad_at(readRDS(file.path(D, "start_005.rds")))
g2 <- grad_at(readRDS(file.path(D, "start_001.rds")))
stopifnot(ccx_mode_seas_ml(readRDS(ccx_mode_file(CCX_MODE_SEASML0_CONTROL))) == 0L, readRDS(file.path(D, "start_005.rds"))$seas_ml == 1L)
cat(sprintf("target: dic %.4g  d13c %.4g\n", tg$dic$target, tg$d13c$target))
for (nm in c("hilda31p","round6 b1","round6 b2")) { g <- list(g0,g1,g2)[[match(nm, c("hilda31p","round6 b1","round6 b2"))]]
  cat(sprintf("%-10s h_ml %5.2f  DIC grad %8.4g (z %+.2f, sd_eff %.3g)   d13C grad %6.4f (z %+.2f, sd_eff %.3g)\n", nm, g["h_ml"], g["dic"], (g["dic"]-tg$dic$target)/g["sd_dic"], g["sd_dic"], g["d13c"], (g["d13c"]-tg$d13c$target)/g["sd_d13c"], g["sd_d13c"])) }
cat(sprintf("P7: modern d13C gradient moved %+.4f (bound: sd_eff %.3g)\n", g1["d13c"]-g0["d13c"], g0["sd_d13c"]))
