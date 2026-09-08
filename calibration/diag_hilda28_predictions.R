# =====================================================================
# diag_hilda28_predictions.R -- SCORE THE HILDA REFIT AGAINST ITS PRE-REGISTERED
# PREDICTIONS (notes/prereg_2026-09-07_hilda_refit_run.md, R1-R7). 2026-09-07.
# Reads the multistart's start files (Torch job 17072999), tabulates the basins
# and what each did with the structure, then scores the BEST start and the
# ent26 baseline (structure OFF) under the SAME objective, stream by stream.
# ⛔ Adopts nothing. Usage: Rscript calibration/diag_hilda28_predictions.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
source(ccx_path("calibration", "lib_design_gates.R"))
HP_DIR <- ccx_path("calibration", "output", "multistart_20260907_hilda28")
HP_OBS_FACTOR <- readRDS(ccx_path("data", "obs_hs_exchange_factor.rds"))$factor
HP_ASX_SD_REF <- 0.10          # the 09-06c conditional-optimum marginal sd (no Hessian from a multistart)
HP_R1_F_MAX <- 0.3; HP_R1_BAND <- c(0.45, 0.85); HP_R3_TOL <- 2; HP_R4_TOL <- 5; HP_R6_MARGIN <- 0.05
HP_COV_BLOCK <- LIK_D14C_PROFILE_BLOCK
HP_OUT <- ccx_path("outputs", "diagnostics", "hilda28_predictions_20260907.rds")

fs <- list.files(HP_DIR, pattern = "^start_[0-9]+[.]rds$", full.names = TRUE)
R  <- lapply(fs, readRDS); lp <- vapply(R, `[[`, 0, "logpost")
tab <- data.frame(id = vapply(R, `[[`, 0L, "id"), logpost = lp,
                  f = vapply(R, function(x) x$par_mode$kz_deep_frac, 0),
                  asx = vapply(R, function(x) x$par_mode$hs_asx_frac, 0),
                  kz = vapply(R, function(x) x$par_mode$kz, 0),
                  h_ml = vapply(R, function(x) x$par_mode$h_ml, 0))
tab$basin <- round(tab$logpost, 2)
cat(sprintf("\n=== HILDA REFIT (job 17072999): %d starts, %d distinct basins (2 dp) ===\n", nrow(tab), length(unique(tab$basin))))
ag <- do.call(rbind, lapply(split(tab, tab$basin), function(d) data.frame(
  logpost = d$basin[1], n = nrow(d), f = mean(d$f), K_deep = mean(d$f * d$kz), hs_asx = mean(d$asx), kz = mean(d$kz), h_ml = mean(d$h_ml))))
ag <- ag[order(-ag$logpost), ]
cat(sprintf("  %10s %3s %7s %7s %7s %8s %6s\n", "logpost", "n", "f", "K_deep", "hs_asx", "kz", "h_ml"))
for (i in seq_len(nrow(ag))) cat(sprintf("  %10.2f %3d %7.4f %7.0f %7.3f %8.0f %6.1f\n", ag$logpost[i], ag$n[i], ag$f[i], ag$K_deep[i], ag$hs_asx[i], ag$kz[i], ag$h_ml[i]))

best <- R[[which.max(lp)]]; pm <- best$par_mode
cat(sprintf("\nBEST: id %d, logpost %.4f\n", best$id, best$logpost))
for (n in c("kz_deep_frac", "hs_asx_frac", "kz", "h_ml", "k_w", "tau_ex", "pump_grad", "q10", "beta_max", "fert_k", "npp_frac_NH"))
  if (!is.null(pm[[n]])) cat(sprintf("  %-14s %10.4f  prior_z %+6.2f\n", n, pm[[n]], best$prior_z[[n]]))
cat(sprintf("  K_deep = f * kz = %.1f m2/yr (HILDA's K0 465)\n", pm$kz_deep_frac * pm$kz))
z <- best$prior_z; big <- names(z)[abs(z) > 2]
cat(sprintf("  |prior_z| > 2: %s\n", if (length(big)) paste(sprintf("%s %+.2f", big, z[big]), collapse = ", ") else "none"))

# ---- streams: the best start WITH the structure vs ent26 WITHOUT, same objective ----
mk_v <- function(p, pmv, src) { v <- list(p = p, pm = pmv, luc_scale = pmv$luc_scale, bomb_total = pmv$bomb_total,
  sigma_d14c = pmv$sigma_d14c, rep_dC = pmv$rep_dC, grad_off_co2 = pmv$grad_off_co2, grad_off_d13c = pmv$grad_off_d13c, src = src); v }
pb <- ccx_apply_structure(ccx_default_params(), "hilda"); pb$pump_mode <- best$pump_mode
pb <- ccx_overlay_par(pb, pm)   # migrates, copies, asserts nothing deleted (the lint's idiom)
vB <- mk_v(pb, pm, "hilda28 best")
v0 <- dg_vector(CCX_MODE_COLUMN_CONTROL)   # ent26, the column control (09-08f: the canonical is HILDA)
tg7 <- dg_gcb_target(DG_SINK_WIN); ob5 <- dg_obs_gate5(); sp5 <- dg_obs_gate5_spread()
pc <- ccx_profile_d14c_cov(HP_COV_BLOCK); tgm <- ccx_mid_d14c_target(); tgd <- ccx_deep_d14c_target()
se_bd <- pc$se[["BD"]]; obs_bd <- pc$contrast_obs[["BD"]]
score <- function(v, lbl) { r <- dg_run(v); st <- dg_streams(r, v); sp <- r$sp; sl <- ccx_model_d14c_slabs(sp); deep <- sp$diagnostics$d14c_bottom_box
  g7 <- dg_gate7(r); v7 <- dg_gate7_verdict(g7, tg7); v5 <- dg_gate5_verdict(dg_gate5(r), ob5, sp5)
  lev <- c(sl[[1]], sl[[2]], deep); zl <- (lev - c(tgm$slabs$target, tgd$target)) / sqrt(diag(pc$cov))
  list(lbl = lbl, st = st, A = lev[1], B = lev[2], deep = lev[3], z_lev = zl, z_bd = ((lev[2] - lev[3]) - obs_bd) / se_bd,
       sink = g7$ocean, z7 = v7$z_ocean, z5 = c(v5$z[["nh_t"]], v5$z[["sh_t"]]), hs = sp$diagnostics$d14c_hs, hd = sp$diagnostics$d14c_hd) }
SB <- score(vB, "hilda28 best"); S0 <- score(v0, "ent26, structure OFF, same objective")
nm <- intersect(names(SB$st), names(S0$st))
cat(sprintf("\n  likelihood: best %.2f vs ent26 %.2f  => %+.2f;  profile row alone: %+.2f\n", sum(SB$st), sum(S0$st), sum(SB$st) - sum(S0$st),
            SB$st[["d14c_profile_mvn"]] - S0$st[["d14c_profile_mvn"]]))
cat("  per-stream delta (best - ent26), |delta| > 1:\n")
for (n in nm) { d <- SB$st[[n]] - S0$st[[n]]; if (abs(d) > 1) cat(sprintf("    %-24s %+8.2f   (ent26 %9.2f)\n", n, d, S0$st[[n]])) }
cat(sprintf("\n  profile: best A %.1f B %.1f deep %.1f  z %+.2f/%+.2f/%+.2f  contrast z %+.2f   (ent26: %.1f/%.1f/%.1f, contrast z %+.2f)\n",
            SB$A, SB$B, SB$deep, SB$z_lev[1], SB$z_lev[2], SB$z_lev[3], SB$z_bd, S0$A, S0$B, S0$deep, S0$z_bd))
cat(sprintf("  HS %.1f / HD %.1f permil;  sink %.2f (z7 %+.2f) vs ent26 %.2f (z7 %+.2f);  bomb z NH/SH %+.2f/%+.2f vs %+.2f/%+.2f\n",
            SB$hs[["NH"]], SB$hd[["NH"]], SB$sink, SB$z7, S0$sink, S0$z7, SB$z5[1], SB$z5[2], S0$z5[1], S0$z5[2]))

# ---- the predictions ----
kzb <- CCX_PARAM_TABLE$kz; asxb <- CCX_PARAM_TABLE$hs_asx_frac
r1 <- pm$kz_deep_frac < HP_R1_F_MAX && abs(pm$hs_asx_frac - HP_OBS_FACTOR) <= 2 * HP_ASX_SD_REF && pm$hs_asx_frac >= HP_R1_BAND[1] && pm$hs_asx_frac <= HP_R1_BAND[2]
r2 <- all(abs(SB$z_lev) < 1) && abs(SB$z_bd) < 1
bomb <- c("d14c_NH", "d14c_SH"); r3 <- (SB$st[["gcb_ocean_sink"]] - S0$st[["gcb_ocean_sink"]] > -HP_R3_TOL) && all(SB$st[bomb] - S0$st[bomb] > -HP_R3_TOL)
r4 <- SB$st[["ocean_grad_d13c"]] - S0$st[["ocean_grad_d13c"]] > -HP_R4_TOL
r5 <- (sum(SB$st) - sum(S0$st)) > (SB$st[["d14c_profile_mvn"]] - S0$st[["d14c_profile_mvn"]])
r6 <- (pm$kz - kzb$lo) / (kzb$hi - kzb$lo) > HP_R6_MARGIN && (kzb$hi - pm$kz) / (kzb$hi - kzb$lo) > HP_R6_MARGIN
r7 <- pm$hs_asx_frac > asxb$lo * 1.02 && pm$hs_asx_frac < asxb$hi * 0.98
V <- function(ok) if (isTRUE(ok)) "PASS" else "FAIL"
cat("\n  PREDICTIONS (prereg_2026-09-07_hilda_refit_run.md):\n")
cat(sprintf("  R1 f < %.1f and hs_asx within 2 sd (%.2f) of %.3f, in [%.2f, %.2f]: f %.3f, factor %.3f (%+.2f sd)  -> %s\n", HP_R1_F_MAX, HP_ASX_SD_REF, HP_OBS_FACTOR, HP_R1_BAND[1], HP_R1_BAND[2], pm$kz_deep_frac, pm$hs_asx_frac, (pm$hs_asx_frac - HP_OBS_FACTOR) / HP_ASX_SD_REF, V(r1)))
cat(sprintf("  R2 profile levels and contrast inside 1 sigma: %+.2f/%+.2f/%+.2f, contrast %+.2f  -> %s\n", SB$z_lev[1], SB$z_lev[2], SB$z_lev[3], SB$z_bd, V(r2)))
cat(sprintf("  R3 sink and bomb streams within %g of ent26: sink %+.2f, d14c_NH %+.2f, d14c_SH %+.2f  -> %s\n", HP_R3_TOL, SB$st[["gcb_ocean_sink"]] - S0$st[["gcb_ocean_sink"]], SB$st[["d14c_NH"]] - S0$st[["d14c_NH"]], SB$st[["d14c_SH"]] - S0$st[["d14c_SH"]], V(r3)))
cat(sprintf("  R4 pump-d13C gradient row within %g: %+.2f  -> %s\n", HP_R4_TOL, SB$st[["ocean_grad_d13c"]] - S0$st[["ocean_grad_d13c"]], V(r4)))
cat(sprintf("  R5 likelihood gain %+.2f exceeds the profile row's own %+.2f  -> %s\n", sum(SB$st) - sum(S0$st), SB$st[["d14c_profile_mvn"]] - S0$st[["d14c_profile_mvn"]], V(r5)))
cat(sprintf("  R6 kz interior (> %.0f%% from each bound): kz %.0f at %.1f%% of [%g, %g]  -> %s\n", 100 * HP_R6_MARGIN, pm$kz, 100 * (pm$kz - kzb$lo) / (kzb$hi - kzb$lo), kzb$lo, kzb$hi, V(r6)))
cat(sprintf("  R7 hs_asx_frac not at a bound [%g, %g]: %.3f  -> %s\n", asxb$lo, asxb$hi, pm$hs_asx_frac, V(r7)))
cat("\n  ⛔ Nothing adopted. Promotion is Marcus's call.\n")
saveRDS(list(tab = tab, basins = ag, best = best, SB = SB[setdiff(names(SB), "st")], SB_st = SB$st, S0_st = S0$st,
             preds = c(R1 = r1, R2 = r2, R3 = r3, R4 = r4, R5 = r5, R6 = r6, R7 = r7)), HP_OUT)
cat(sprintf("  saved %s\n", HP_OUT))
