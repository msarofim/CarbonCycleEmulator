source("/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/04e20996-bd05-4d13-9da3-fa0c74359cf1/scratchpad/early_drawdown/lib_ed.R")
OUT <- "/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/04e20996-bd05-4d13-9da3-fa0c74359cf1/scratchpad/early_drawdown/out"
dir.create(OUT, showWarnings = FALSE)
SENS_WHOLE <- c("beta_max", "fert_k", "k_w", "h_ml", "kz", "kz_deep_frac", "hs_asx_frac", "h_hs", "u_hs",
                "q10", "pump_hs_gcm2", "pump_grad", "luc_scale", "ndep_ret", "tau_ex")
SENS_COND  <- c("beta_max", "fert_k", "kz", "h_ml", "hs_asx_frac", "h_hs")   # conditional (covariance) steps
cat("commit:", ccx_git_stamp(), " mode:", CCX_MODE_CANONICAL, " climate:", ED_CLIMATE, "\n")
v <- dg_vector(CCX_MODE_CANONICAL)

beta_eff <- function(p, chi) {          # d ln f / d ln chi and the absolute dNPP/dchi at chi
  chi0 <- ccx_const("CO2_PI_PPM"); d <- chi - chi0
  f <- ccx_fert_factor(chi, p, chi0); fp <- p$beta_max * p$fert_k / (p$fert_k + d)^2
  aux <- ccx_prepare(p); npp0 <- sum(unlist(aux$npp0))
  c(beta_eff = fp * chi / f, dNPP_dchi = npp0 * fp, npp_bkg = npp0 * f)
}
sinks <- function(v2) { g <- dg_gate7(dg_run(v2)); c(ocean_1523 = g$ocean, land_1523 = g$land) }
tgt <- dg_gcb_target(DG_SINK_WIN)
cat(sprintf("GCB %d-%d target (dg_gcb_target, no shares): ocean %.3f land %.3f GtC/yr\n",
            DG_SINK_WIN[1], DG_SINK_WIN[2], tgt$ocean, tgt$land))

run_whole <- function(v2, label, value = NA) {
  spin <- dg_spinup(v2); o <- ed_pd100(v2, spin)
  cbind(ed_row(o, label), value = value, t(beta_eff(v2$p, o$target)), t(sinks(v2)))
}
rows <- list(run_whole(v, "canonical"))
for (n in SENS_WHOLE) for (k in c(-1, 1)) {
  x <- ed_step(v, n, k)
  rows[[length(rows) + 1]] <- run_whole(ed_v_with(v, stats::setNames(list(x), n)),
                                        sprintf("%s %+d sd", n, k), x)
  cat(".")
}
# conditional steps: u -> u_mode + k * cov[, n] / sd[n]  (all fitted names move, along the posterior)
for (n in SENS_COND) for (k in c(-1, 1)) {
  du <- k * v$md$cov[, n] / sqrt(v$md$cov[n, n])
  u <- v$md$u_mode + du[names(v$md$u_mode)]
  newp <- ccx_unc_to_par(u)
  rows[[length(rows) + 1]] <- run_whole(ed_v_with(v, newp), sprintf("COND %s %+d sd", n, k), newp[[n]])
  cat("c")
}
cat("\n")
W <- do.call(rbind, rows)
saveRDS(W, file.path(OUT, "s2_whole.rds"))
c0 <- W[1, ]
W$dIRF20 <- W$irf20 - c0$irf20; W$dIRF100 <- W$irf100 - c0$irf100
W$ratio_20_100 <- W$dIRF20 / W$dIRF100
cat("\n=== WHOLE-RUN +/-1 posterior sd (marginal, unconstrained space) and COND steps ===\n")
print(format(W[, c("label", "value", "irf20", "irf100", "dIRF20", "dIRF100", "ratio_20_100", "th20", "th100",
                   "oc5", "ld5", "oc20", "ld20", "oc100", "ld100", "target", "beta_eff", "dNPP_dchi",
                   "ocean_1523", "land_1523")], digits = 4), row.names = FALSE)
