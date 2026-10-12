source("/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/fa6620c3-fcfb-49a4-a787-90d23c00188e/scratchpad/review/L3/load.R")
S <- "/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/fa6620c3-fcfb-49a4-a787-90d23c00188e/scratchpad/review/L3"
rp <- readRDS(file.path(S, "rp.rds")); p <- rp$p
grid <- ccx_ocean_grid(p$h_ml); aux <- ccx_prepare(p, grid)
ss <- ccx_substeps_for(p, grid); h <- (1/12)/ss
cat("grid dz:", round(grid$dz, 2), "\n")
cat("substeps:", ss, " h:", h, "\n")
# the controller's lam
.sh <- ccx_mld_shape("ls")
fs <- c(min(sapply(HEMIS, function(hh) .sh[[hh]]$f_min)), max(sapply(HEMIS, function(hh) .sh[[hh]]$f_max)))
lam_ctrl <- max(sapply(fs, function(f) ccx_diffusion_eigmax(max(ccx_kz_profile(p, grid)), ccx_grid_at_h_ml(grid, grid$h_ml * f))))
cat("controller lam:", lam_ctrl, " z_ctrl:", h * lam_ctrl, "\n")
# the integrator's own LS-column operator for C (diffusion + entrainment/detrainment + L2 at enso), per hemisphere, over the year
nl <- grid$nl
J_at <- function(hh, t, enso = 0, g = 1) {
  ev <- ccx_mld_eval(aux$mld_coef[[hh]], t)
  dzl <- grid$dz; hm <- grid$h_ml * ev$f; dhdt <- grid$h_ml * ev$dfdt
  dzl[2] <- dzl[2] + (dzl[1] - hm); dzl[1] <- hm
  dzm <- (dzl[-length(dzl)] + dzl[-1]) / 2
  K <- aux$kz_int - (1 - g) * aux$kz_up
  J <- matrix(0, nl + 1, nl + 1)
  for (k in seq_len(nl)) { a <- k; b <- k + 1
    J[a, a] <- J[a, a] - K[k] / (dzl[a] * dzm[k]); J[a, b] <- J[a, b] + K[k] / (dzl[b] * dzm[k])
    J[b, a] <- J[b, a] + K[k] / (dzl[a] * dzm[k]); J[b, b] <- J[b, b] - K[k] / (dzl[b] * dzm[k]) }
  if (dhdt > 0) { r <- dhdt / dzl[2]; J[2, 2] <- J[2, 2] - r; J[1, 2] <- J[1, 2] + r }
  if (dhdt < 0) { r <- -dhdt / dzl[1]; J[1, 1] <- J[1, 1] - r; J[2, 1] <- J[2, 1] + r }
  ent <- if (dhdt > 0) dhdt / dzl[2] else if (dhdt < 0) -dhdt / dzl[1] else 0
  # L2 limb
  fac <- max(0, 1 - (p$w_enso_l2 / aux$w0_l2) * enso); dV <- aux$w0_l2 * CCX_SV_TO_M3YR * aux$l2_share[[hh]] * (fac - 1)
  kl <- aux$k_l2 + 1; Vk <- aux$a_ls[[hh]] * dzl[kl]; Vm <- aux$a_ml[[hh]] * dzl[1]
  J[kl, kl] <- J[kl, kl] - dV / Vk; J[kl, 1] <- J[kl, 1] + dV / Vm
  J[1, kl] <- J[1, kl] + dV / Vk; J[1, 1] <- J[1, 1] - dV / Vm
  c(rho = max(Mod(eigen(J, only.values = TRUE)$values)), ent = ent, dz1 = dzl[2], l2 = max(abs(dV / Vm), abs(dV / Vk)))
}
tt <- (seq_len(1200) - 0.5) / 1200
for (hh in HEMIS) for (en in c(0, -3, 3)) {
  m <- t(sapply(tt, function(t) J_at(hh, t, enso = en)))
  cat(sprintf("%s enso %+d: max rho %.1f /yr (z = %.3f)  max entrain/detrain rate %.2f /yr  min dz1 %.2f m  max L2 rate %.3f /yr\n",
              hh, en, max(m[, "rho"]), h * max(m[, "rho"]), max(m[, "ent"]), min(m[, "dz1"]), max(m[, "l2"])))
}
cat("RK4 stable rho limit at this h:", CCX_RK4_STAB_LIMIT / h, "\n")
cat("aux w0_l2:", aux$w0_l2, " l2_on:", aux$l2_on, " k_l2:", aux$k_l2, " mix_on:", aux$mix_on, " inert_on:", aux$inert_on, " hs_on:", aux$hs_on, " pump_hs NULL?", is.null(aux$pump_hs), "\n")
