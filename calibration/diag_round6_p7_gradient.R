# =====================================================================
# diag_round6_p7_gradient.R -- PREREG P7 for round 6 ("NOT A DEEP LEVER IN
# DISGUISE": the modern surface-deep d13C gradient must not move by more than
# the ocean_grad_d13c row's sigma_eff, 0.16). Measures the scored DIC and d13C
# gradients (ccx_ocean_grad_scored, the objective's own path) at hilda31p
# (seas_ml 0) and at the round-6 modes (seas_ml 1). 2026-09-11.
# RESULT: P7 FAILS at 2x the bound -- d13C gradient -0.309 -> +0.018 (target
# -0.861), DIC gradient 302 -> 385 (target 233): the mechanism homogenises the
# isotope gradient and steepens the DIC one, both AWAY from the observation.
# =====================================================================
suppressMessages(for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)); ccx_load_cpp()
D <- "calibration/output/multistart_20260910_round6_seasml1_sd1.0452"
tg <- ccx_ocean_gradient_target()
grad_at <- function(pm, seas_ml) {
  bp <- ccx_apply_structure(ccx_default_params(), "hilda", seas_ml = seas_ml); bp$pump_mode <- "N"
  p <- ccx_overlay_par(bp, pm); sp <- CCX_OBJECTIVE_SPINUP(p)
  F <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = 0, bomb_total_kmol = 102)
  F$c14_cosmo <- sp$prod_c14; F$c14_bomb <- F$c14_bomb * (pm$bomb_total / 102)
  for (cc in c("e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH")) F[[cc]] <- F[[cc]] * pm$luc_scale
  attr(F, "luc_scale") <- pm$luc_scale
  r <- ccx_run_fast(sp, F); og <- ccx_ocean_grad_scored(r$out, sp)
  c(dic = og$dic, d13c = og$d13c, sd_dic = og$sd_eff[["dic"]], sd_d13c = og$sd_eff[["d13c"]], h_ml = sp$grid$h_ml)
}
g0 <- grad_at(readRDS(ccx_mode_file())$par_mode, 0)
g1 <- grad_at(readRDS(file.path(D, "start_004.rds"))$par_mode, 1)
g2 <- grad_at(readRDS(file.path(D, "start_001.rds"))$par_mode, 1)
cat(sprintf("target: dic %.4g  d13c %.4g\n", tg$dic$target, tg$d13c$target))
for (nm in c("hilda31p","round6 b1","round6 b2")) { g <- list(g0,g1,g2)[[match(nm, c("hilda31p","round6 b1","round6 b2"))]]
  cat(sprintf("%-10s h_ml %5.2f  DIC grad %8.4g (z %+.2f, sd_eff %.3g)   d13C grad %6.4f (z %+.2f, sd_eff %.3g)\n", nm, g["h_ml"], g["dic"], (g["dic"]-tg$dic$target)/g["sd_dic"], g["sd_dic"], g["d13c"], (g["d13c"]-tg$d13c$target)/g["sd_d13c"], g["sd_d13c"])) }
cat(sprintf("P7: modern d13C gradient moved %+.4f (bound: sd_eff %.3g)\n", g1["d13c"]-g0["d13c"], g0["sd_d13c"]))
