source("/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/fa6620c3-fcfb-49a4-a787-90d23c00188e/scratchpad/review/L2/setup.R")
rho <- ccx_const("RHO_SEAWATER")
grad <- function(pp, lab) {
  sp <- ccx_spinup_from_label(ccx_mode_spinup(md))(pp); y <- sp$y; aux <- sp$aux; grid <- aux$grid
  for (h in HEMIS) {
    i <- aux$idx[[h]]
    fo <- if (!is.null(aux$mld_coef)) ccx_mld_eval(aux$mld_coef[[h]], 1750 + 0.5/12)$f else 1
    ml <- y[i$ml, "C"] * aux$mol_per_GtC / (aux$ml_mass_kg[[h]] * fo) * 1e6
    dz1 <- grid$dz[2] + grid$h_ml * (1 - fo)
    prof <- c(ml, sapply(seq_along(i$oc), function(k) y[i$oc[k], "C"] * aux$mol_per_GtC / (aux$a_ls[[h]] * (if (k == 1) dz1 else grid$dz[k + 1]) * rho) * 1e6))
    cat(sprintf("%-28s %s bottom-ML %.1f  (pump_grad %.1f)\n", lab, h, prof[length(prof)] - prof[1], pp$pump_grad))
  }
}
grad(p, "canonical")
p3 <- p; p3$tau_q <- 0; grad(p3, "canonical, tau_q = 0")
