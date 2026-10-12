source("/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/fa6620c3-fcfb-49a4-a787-90d23c00188e/scratchpad/review/L2/setup.R")
z <- readRDS(file.path(SCR, "spin_F.rds")); sp <- z$sp
y <- sp$y; R13 <- ccx_const("R13_VPDB")
d13 <- 1000 * (y[, "C13"] / y[, "C"] / R13 - 1); D14 <- 1000 * (y[, "C14"] / y[, "C"] - 1)
print(data.frame(box = rownames(y), C = round(y[, "C"], 2), d13C = round(d13, 3), D14C = round(D14, 1)))
# ---- uniform-concentration fixed point of the ocean transport (no air-sea, no pump) ----
p2 <- p; p2$k_w <- 0; p2$pump_grad <- 0; p2$pump_hs_gcm2 <- 0
aux2 <- ccx_prepare(p2); grid <- aux2$grid
for (tt in c(1990.13, 1990.37, 1990.71)) {
  y2 <- y
  cc <- c(C = 2.2e-12, C13 = 2.2e-12 * R13 * 1.0005, C14 = 2.2e-12 * 0.93)
  vol <- list(); dV <- list()
  for (h in HEMIS) {
    i <- aux2$idx[[h]]
    ev <- ccx_mld_eval(aux2$mld_coef[[h]], tt)
    hml <- grid$h_ml * ev$f; dh <- grid$h_ml * ev$dfdt
    gr <- ccx_grid_at_h_ml(grid, hml)
    V <- c(aux2$a_ml[[h]] * hml, aux2$a_ls[[h]] * gr$dz[-1], aux2$a_hs[[h]] * aux2$thick_hs[[h]], aux2$a_hs[[h]] * aux2$thick_hd[[h]])
    ii <- c(i$ml, i$oc, i$hs, i$hd)
    for (tr in CCX_TRACERS) y2[ii, tr] <- cc[[tr]] * V
    vol[[h]] <- setNames(V, ii)
    dvdt <- numeric(length(ii)); dvdt[1] <- aux2$a_ml[[h]] * dh; dvdt[2] <- -aux2$a_ls[[h]] * dh
    dV[[h]] <- dvdt
  }
  fi <- list(e_foss = list(NH = 0, SH = 0), e_luc = list(NH = 0, SH = 0), cum_luc = list(NH = 0, SH = 0),
             gmst = 0.8, enso = 1.7, land_enso = 1.0, mix_g = 0.9, c14_bomb = 0, c14_nuclear = 0, c14_cosmo = 0,
             d13c_foss = -28, aod_NH = 0, aod_SH = 0, ndep_NH = 0, ndep_SH = 0, sst_anom_NH = 0.5, sst_anom_SH = 0.4)
  d <- ccx_deriv(y2, tt, p2, fi, grid, aux2)
  for (h in HEMIS) {
    i <- aux2$idx[[h]]; ii <- c(i$ml, i$oc, i$hs, i$hd)
    for (tr in CCX_TRACERS) {
      dconc <- (d[ii, tr] - cc[[tr]] * dV[[h]]) / vol[[h]]
      cat(sprintf("t=%.2f %s %-3s max|dconc|/conc = %.3e  (scale: max|d|/C = %.3e)\n", tt, h, tr,
                  max(abs(dconc)) / cc[[tr]], max(abs(d[ii, tr])) / max(y2[ii, tr])))
    }
  }
}
