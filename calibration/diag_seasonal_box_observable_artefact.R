# =====================================================================
# diag_seasonal_box_observable_artefact.R -- 2026-09-11 (4). Does the objective
# read a SEASONAL box's concentration correctly? It does not: the ocean-gradient
# observable (ccx_model_ocean_gradient, R/likelihood.R) divides the INSTANT
# carbon at the GLODAP epoch (DIC 1999.84, early November) by the ANNUAL-MEAN
# box mass. Exact at seas_ml = 0 (f = 1); at seas_ml = 1 the LS mixed layer
# holds 0.885 (NH) / 0.919 (SH) of its mean mass at that instant, so the
# surface DIC reads ~157 umol/kg LOW and the gradient ~157 too STEEP.
#
# Three reads of the surface, at hilda31p (seas_ml 0) and the round-6 mode
# (start_004, seas_ml 1), through the same run path as diag_round6_p7_gradient.R:
#   A  instant carbon / annual-mean mass   -- THE OBJECTIVE'S (reproduces the record)
#   B  instant carbon / instant mass       -- the box's real concentration then
#   C  annual mean over the epoch year of the instant concentration -- like-for-
#      like with a climatological product
# RESULT: A -156.9 | B +43.6 | C +0.9 umol/kg (round 6 minus hilda31p). Under C the
# round-6 DIC gradient is 226 vs target 233 (the objective read 385). The d13C
# half (+0.33 on the gradient) is the DEEP box (DIC -73, d13C +0.37): the refit
# reshuffled the deep to cancel a surface row reading 157 low. Round 6 was
# FITTED against the artefact; the P7 verdict is not a property of the mechanism.
# Same construction: dg_gateG (calibration/lib_design_gates.R, Dec-31 state /
# mean mass) and ccx_model_hs_surface (hs_mass_kg annual mean).
# Usage: Rscript calibration/diag_seasonal_box_observable_artefact.R
# =====================================================================
suppressMessages(for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)); ccx_load_cpp()
D <- "calibration/output/multistart_20260910_round6_seasml1_sd1.0452"
tg <- ccx_ocean_gradient_target()
run_at <- function(mdx) {
  pm <- mdx$par_mode; bp <- ccx_mode_base(mdx); bp$pump_mode <- mdx$pump_mode
  p <- ccx_overlay_par(bp, pm); sp <- CCX_OBJECTIVE_SPINUP(p)
  F <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = 0, bomb_total_kmol = 102)
  F$c14_cosmo <- sp$prod_c14; F$c14_bomb <- F$c14_bomb * (pm$bomb_total / 102)
  for (cc in c("e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH")) F[[cc]] <- F[[cc]] * pm$luc_scale
  attr(F, "luc_scale") <- pm$luc_scale
  list(out = ccx_run_fast(sp, F)$out, sp = sp, p = p)
}
surf <- function(r, seas) {
  out <- r$out; aux <- r$sp$aux; grid <- r$sp$grid; rho <- ccx_const("RHO_SEAWATER")
  at <- function(col, tt) stats::approx(out$t, out[[col]], xout = tt, rule = 2)$y
  # (A) the objective's read: instant carbon / annual-mean mass
  inst <- function(tt) { C <- 0; M <- 0; C13 <- 0
    for (h in HEMIS) { C <- C + at(paste0("ml_C_", h), tt); C13 <- C13 + at(paste0("ml_C13_", h), tt); M <- M + ccx_column_area(aux, h) * grid$dz[1] * rho }
    c(dic = C * aux$mol_per_GtC / M * 1e6, d13c = 1000 * (C13 / C / ccx_const("R13_VPDB") - 1)) }
  # (B) instant carbon / INSTANT mass (the box's real concentration at that instant)
  inst_m <- function(tt) { C <- 0; M <- 0; C13 <- 0
    for (h in HEMIS) { f <- if (seas) ccx_mld_eval(aux$mld_coef[[h]], tt)$f else 1
      C <- C + at(paste0("ml_C_", h), tt); C13 <- C13 + at(paste0("ml_C13_", h), tt); M <- M + ccx_column_area(aux, h) * grid$dz[1] * f * rho }
    c(dic = C * aux$mol_per_GtC / M * 1e6, d13c = 1000 * (C13 / C / ccx_const("R13_VPDB") - 1)) }
  # (C) annual mean of the instant concentration over the epoch year
  ann <- function(tt) { tts <- floor(tt) + (0:11 + 0.5) / 12; v <- sapply(tts, inst_m); rowMeans(v) }
  rbind(A_instant_meanmass = c(inst(tg$dic$epoch_surf)["dic"], inst(tg$d13c$epoch_surf)["d13c"]),
        B_instant_instmass = c(inst_m(tg$dic$epoch_surf)["dic"], inst_m(tg$d13c$epoch_surf)["d13c"]),
        C_annual_mean      = c(ann(tg$dic$epoch_surf)["dic"], ann(tg$d13c$epoch_surf)["d13c"]))
}
r0 <- run_at(readRDS(ccx_mode_file())); r1 <- run_at(readRDS(file.path(D, "start_004.rds")))
s0 <- surf(r0, FALSE); s1 <- surf(r1, TRUE)
cat("out cadence (yr):", diff(r1$out$t)[1:3], "\n")
cat("SURFACE DIC (umol/kg) and d13C (permil) at the gradient epochs:\n")
cat("hilda31p (seas_ml 0):\n"); print(round(s0, 3))
cat("round 6 (seas_ml 1):\n"); print(round(s1, 3))
cat(sprintf("\nsurface DIC shift r6 - hilda31p: A (objective) %+.1f | B (instant mass) %+.1f | C (annual mean) %+.1f\n", s1[1,1]-s0[1,1], s1[2,1]-s0[2,1], s1[3,1]-s0[3,1]))
cat(sprintf("surface d13C shift r6 - hilda31p: A %+.3f | B %+.3f | C %+.3f\n", s1[1,2]-s0[1,2], s1[2,2]-s0[2,2], s1[3,2]-s0[3,2]))
for (h in HEMIS) cat(h, "f at dic epoch", round(ccx_mld_eval(r1$sp$aux$mld_coef[[h]], tg$dic$epoch_surf)$f, 3), "\n")
deep <- function(r) { out <- r$out; aux <- r$sp$aux; grid <- r$sp$grid; rho <- ccx_const("RHO_SEAWATER")
  at <- function(col, tt) stats::approx(out$t, out[[col]], xout = tt, rule = 2)$y
  C <- 0; C13 <- 0; M <- 0
  for (h in HEMIS) { C <- C + at(paste0("deep_C_", h), tg$dic$epoch_deep); M <- M + ccx_column_area(aux, h) * grid$dz[length(grid$dz)] * rho }
  for (h in HEMIS) C13 <- C13 + at(paste0("deep_C13_", h), tg$d13c$epoch_deep)
  Cd <- 0; for (h in HEMIS) Cd <- Cd + at(paste0("deep_C_", h), tg$d13c$epoch_deep)
  c(dic = C * aux$mol_per_GtC / M * 1e6, d13c = 1000 * (C13 / Cd / ccx_const("R13_VPDB") - 1)) }
d0 <- deep(r0); d1 <- deep(r1)
cat(sprintf("\nDEEP: hilda31p dic %.1f d13c %.3f | round6 dic %.1f d13c %.3f  (shift %+.1f / %+.3f)\n", d0["dic"], d0["d13c"], d1["dic"], d1["d13c"], d1["dic"]-d0["dic"], d1["d13c"]-d0["d13c"]))
cat("GRADIENT deep - surf under each observable (target dic", round(tg$dic$target), "d13c", round(tg$d13c$target,3), "):\n")
for (k in 1:3) cat(sprintf("  %-20s hilda31p dic %.1f d13c %+.3f | round6 dic %.1f d13c %+.3f | P7 d13c move %+.3f (bound 0.163) dic move %+.1f\n", rownames(s0)[k], d0["dic"]-s0[k,1], d0["d13c"]-s0[k,2], d1["dic"]-s1[k,1], d1["d13c"]-s1[k,2], (d1["d13c"]-s1[k,2])-(d0["d13c"]-s0[k,2]), (d1["dic"]-s1[k,1])-(d0["dic"]-s0[k,1])))
cat(sprintf("pump_grad hilda31p %.4f round6 %.4f | k_w %.0f %.0f | h_ml %.2f %.2f\n", r0$p$pump_grad, r1$p$pump_grad, r0$p$k_w, r1$p$k_w, r0$p$h_ml, r1$p$h_ml))
