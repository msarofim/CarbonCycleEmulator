source("/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/fa6620c3-fcfb-49a4-a787-90d23c00188e/scratchpad/review/L2/setup.R")
z <- readRDS(file.path(SCR, "spin_F.rds")); sp <- z$sp; y <- sp$y; aux <- sp$aux; grid <- aux$grid
rho <- ccx_const("RHO_SEAWATER")
for (h in HEMIS) {
  i <- aux$idx[[h]]
  fo <- ccx_mld_eval(aux$mld_coef[[h]], 1750 + 0.5/12)$f; ml <- y[i$ml, "C"] * aux$mol_per_GtC / (aux$ml_mass_kg[[h]] * fo) * 1e6; cat("f=", fo, " ")
  bot <- y[tail(i$oc, 1), "C"] * aux$mol_per_GtC / (aux$a_ls[[h]] * tail(grid$dz, 1) * rho) * 1e6
  cat(h, "ML DIC", round(ml, 1), " bottom DIC", round(bot, 1), " gradient", round(bot - ml, 1), " pump_grad", round(p$pump_grad, 1), "\n")
}
