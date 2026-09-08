# =====================================================================
# diag_hilda29_predictions.R -- SCORE ROUND 2 OF THE HILDA REFIT (Torch job
# 17110417, 29 parameters, objective #10) AGAINST prereg_2026-09-07b R1-R8.
# Basin table from the start files; the best start of every basin family AND
# ent26 (structure OFF) run through the transient and scored stream by stream
# under the same objective. Adopts nothing. Usage: Rscript calibration/diag_hilda29_predictions.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
source(ccx_path("calibration", "lib_design_gates.R"))
HP_DIR <- ccx_path("calibration", "output", "multistart_20260907b_hilda29")
HP_OBS_FACTOR <- readRDS(ccx_path("data", "obs_hs_exchange_factor.rds"))$factor
HP_R1_F_MAX <- 0.3; HP_R1_BAND <- c(0.45, 0.85); HP_R1_FLOOR_MULT <- 1.5
HP_R2_Z <- 2; HP_R3_TOL <- 2; HP_R4_TOL <- 5; HP_R6_MARGIN <- 0.05; HP_R7_HML <- c(60, 180); HP_R8_N <- 10; HP_R8_WIN <- 5; HP_R8_DF <- 0.2
HP_PROFILE_ROWS <- c("d14c_profile_level", "d14c_profile_ab", "d14c_profile_bd")
HP_PUMP_ROWS <- c("ocean_grad_d13c", "ocean_grad_dic", "ocean_grad_alk")
HP_OUT <- ccx_path("outputs", "diagnostics", "hilda29_predictions_20260907.rds")
fs <- list.files(HP_DIR, pattern = "^start_[0-9]+[.]rds$", full.names = TRUE)
R <- lapply(fs, readRDS); lp <- vapply(R, `[[`, 0, "logpost")
tab <- data.frame(id = vapply(R, `[[`, 0L, "id"), logpost = lp, basin = round(lp, 2),
                  f = vapply(R, function(x) x$par_mode$kz_deep_frac, 0), asx = vapply(R, function(x) x$par_mode$hs_asx_frac, 0),
                  kz = vapply(R, function(x) x$par_mode$kz, 0), h_ml = vapply(R, function(x) x$par_mode$h_ml, 0), h_hs = vapply(R, function(x) x$par_mode$h_hs, 0))
ag <- do.call(rbind, lapply(split(tab, tab$basin), function(d) data.frame(logpost = d$basin[1], n = nrow(d), id = d$id[which.max(d$logpost)],
  f = mean(d$f), K_deep = mean(d$f * d$kz), asx = mean(d$asx), h_ml = mean(d$h_ml), h_hs = mean(d$h_hs), kz = mean(d$kz))))
ag <- ag[order(-ag$logpost), ]
cat(sprintf("\n=== HILDA REFIT ROUND 2 (job 17110417): %d starts, %d basins ===\n", nrow(tab), nrow(ag)))
print(ag, row.names = FALSE, digits = 4)
best <- R[[which.max(lp)]]; pm <- best$par_mode
cat(sprintf("\nBEST: id %d, logpost %.4f\n", best$id, best$logpost))
for (n in c("kz_deep_frac", "hs_asx_frac", "h_hs", "kz", "h_ml", "k_w", "tau_ex", "pump_grad", "q10", "beta_max", "fert_k"))
  cat(sprintf("  %-14s %10.4f  prior_z %+6.2f\n", n, pm[[n]], best$prior_z[[n]]))
z <- best$prior_z; big <- names(z)[abs(z) > 2]
cat(sprintf("  |prior_z| > 2: %s\n", if (length(big)) paste(sprintf("%s %+.2f", big, z[big]), collapse = ", ") else "none"))

mk_v <- function(p, pmv) list(p = p, pm = pmv, luc_scale = pmv$luc_scale, bomb_total = pmv$bomb_total, sigma_d14c = pmv$sigma_d14c,
                              rep_dC = pmv$rep_dC, grad_off_co2 = pmv$grad_off_co2, grad_off_d13c = pmv$grad_off_d13c)
v_of <- function(st) { p <- ccx_apply_structure(ccx_default_params(), "hilda"); p$pump_mode <- st$pump_mode; mk_v(ccx_overlay_par(p, st$par_mode), st$par_mode) }
tg7 <- dg_gcb_target(DG_SINK_WIN); ob5 <- dg_obs_gate5(); sp5 <- dg_obs_gate5_spread(); spec <- ccx_profile_d14c_spec()
score <- function(v) { r <- dg_run(v); st <- dg_streams(r, v); sp <- r$sp; sl <- ccx_model_d14c_slabs(sp); lev <- c(sl[[1]], sl[[2]], sp$diagnostics$d14c_bottom_box)
  g7 <- dg_gate7(r); v7 <- dg_gate7_verdict(g7, tg7); v5 <- dg_gate5_verdict(dg_gate5(r), ob5, sp5)
  list(st = st, lev = lev, z = c(level = (mean(lev) - spec$level) / spec$level_sd, ab = ((lev[1] - lev[2]) - spec$ab) / spec$ab_sd, bd = ((lev[2] - lev[3]) - spec$bd) / spec$bd_sd),
       hs = sp$diagnostics$d14c_hs[["NH"]], hd = sp$diagnostics$d14c_hd[["NH"]], sink = g7$ocean, z7 = v7$z_ocean, z5 = c(v5$z[["nh_t"]], v5$z[["sh_t"]])) }
v0 <- dg_vector(CCX_MODE_COLUMN_CONTROL)   # ent26, the column control (09-08f: the canonical is HILDA); S0 <- score(v0)
FAM <- lapply(seq_len(nrow(ag)), function(k) { st <- R[[which(tab$id == ag$id[k])]]; c(list(id = st$id, logpost = st$logpost, pm = st$par_mode), score(v_of(st))) })
rowsum <- function(S, rows) sum(S$st[intersect(rows, names(S$st))])
cat(sprintf("\n  %-9s %3s | %7s %7s %7s | %6s %6s %6s | %7s %7s | %8s %7s %7s %7s | %5s %5s\n", "logpost", "id", "A", "B", "deep", "z_lev", "z_AB", "z_BD", "HS", "HD", "lik", "d_lik", "d_rows", "d_rest", "sink", "z7"))
for (S in c(FAM, list(c(list(id = NA, logpost = NA), S0)))) { lab <- if (is.na(S$id)) "ent26 OFF" else sprintf("%.2f", S$logpost)
  cat(sprintf("  %-9s %3s | %7.1f %7.1f %7.1f | %+6.2f %+6.2f %+6.2f | %7.1f %7.1f | %8.1f %+7.1f %+7.1f %+7.1f | %5.2f %+5.2f\n", lab, if (is.na(S$id)) "-" else S$id,
              S$lev[1], S$lev[2], S$lev[3], S$z[1], S$z[2], S$z[3], if (is.null(S$hs)) NA else S$hs, if (is.null(S$hd)) NA else S$hd, sum(S$st), sum(S$st) - sum(S0$st),
              rowsum(S, HP_PROFILE_ROWS) - rowsum(S0, HP_PROFILE_ROWS), (sum(S$st) - rowsum(S, HP_PROFILE_ROWS)) - (sum(S0$st) - rowsum(S0, HP_PROFILE_ROWS)), S$sink, S$z7)) }
B <- FAM[[1]]
cat("\n  best vs ent26, per stream, |delta| > 1.5:\n")
for (n in names(S0$st)) { d <- B$st[[n]] - S0$st[[n]]; if (abs(d) > 1.5) cat(sprintf("    %-24s %+8.2f   (ent26 %9.2f)\n", n, d, S0$st[[n]])) }
kzb <- CCX_PARAM_TABLE$kz; asxb <- CCX_PARAM_TABLE$hs_asx_frac; hhb <- CCX_PARAM_TABLE$h_hs
r1 <- pm$kz_deep_frac < HP_R1_F_MAX && pm$hs_asx_frac >= HP_R1_BAND[1] && pm$hs_asx_frac <= HP_R1_BAND[2] && pm$hs_asx_frac > HP_R1_FLOOR_MULT * asxb$lo
r2 <- all(abs(B$z) < HP_R2_Z)
bomb <- c("d14c_NH", "d14c_SH"); r3 <- (B$st[["gcb_ocean_sink"]] - S0$st[["gcb_ocean_sink"]] > -HP_R3_TOL) && all(B$st[bomb] - S0$st[bomb] > -HP_R3_TOL)
r4 <- all(B$st[HP_PUMP_ROWS] - S0$st[HP_PUMP_ROWS] > -HP_R4_TOL)
r5 <- (sum(B$st) - sum(S0$st)) > (rowsum(B, HP_PROFILE_ROWS) - rowsum(S0, HP_PROFILE_ROWS))
r6 <- (pm$kz - kzb$lo) / (kzb$hi - kzb$lo) > HP_R6_MARGIN && (kzb$hi - pm$kz) / (kzb$hi - kzb$lo) > HP_R6_MARGIN
r7 <- pm$h_ml >= HP_R7_HML[1] && pm$h_ml <= HP_R7_HML[2] && (pm$h_hs - hhb$lo) / (hhb$hi - hhb$lo) > HP_R6_MARGIN && (hhb$hi - pm$h_hs) / (hhb$hi - hhb$lo) > HP_R6_MARGIN
near <- ag[ag$logpost > ag$logpost[1] - HP_R8_WIN, ]; r8 <- ag$n[1] >= HP_R8_N && all(abs(near$f - ag$f[1]) <= HP_R8_DF)
V <- function(ok) if (isTRUE(ok)) "PASS" else "FAIL"
cat("\n  PREDICTIONS (prereg_2026-09-07b_hilda_refit_round2.md):\n")
cat(sprintf("  R1 f < %.1f, hs_asx in [%.2f, %.2f] and > %.1fx floor: f %.3f, factor %.3f (%+.2f sd of %.3f at sd 0.10)  -> %s\n", HP_R1_F_MAX, HP_R1_BAND[1], HP_R1_BAND[2], HP_R1_FLOOR_MULT, pm$kz_deep_frac, pm$hs_asx_frac, (pm$hs_asx_frac - HP_OBS_FACTOR) / 0.10, HP_OBS_FACTOR, V(r1)))
cat(sprintf("  R2 level, A-B, B-deep inside %g sigma: %+.2f / %+.2f / %+.2f  -> %s\n", HP_R2_Z, B$z[1], B$z[2], B$z[3], V(r2)))
cat(sprintf("  R3 sink and bomb within %g of ent26: sink %+.2f, d14c_NH %+.2f, d14c_SH %+.2f  -> %s\n", HP_R3_TOL, B$st[["gcb_ocean_sink"]] - S0$st[["gcb_ocean_sink"]], B$st[["d14c_NH"]] - S0$st[["d14c_NH"]], B$st[["d14c_SH"]] - S0$st[["d14c_SH"]], V(r3)))
cat(sprintf("  R4 pump gradient rows within %g each: d13c %+.2f, dic %+.2f, alk %+.2f  -> %s\n", HP_R4_TOL, B$st[["ocean_grad_d13c"]] - S0$st[["ocean_grad_d13c"]], B$st[["ocean_grad_dic"]] - S0$st[["ocean_grad_dic"]], B$st[["ocean_grad_alk"]] - S0$st[["ocean_grad_alk"]], V(r4)))
cat(sprintf("  R5 likelihood gain %+.2f exceeds the profile rows' own %+.2f  -> %s\n", sum(B$st) - sum(S0$st), rowsum(B, HP_PROFILE_ROWS) - rowsum(S0, HP_PROFILE_ROWS), V(r5)))
cat(sprintf("  R6 kz interior: %.0f at %.1f%% of [%g, %g]  -> %s\n", pm$kz, 100 * (pm$kz - kzb$lo) / (kzb$hi - kzb$lo), kzb$lo, kzb$hi, V(r6)))
cat(sprintf("  R7 h_ml in [%g, %g] and h_hs interior: h_ml %.1f, h_hs %.1f (%.0f%% of [%g, %g])  -> %s\n", HP_R7_HML[1], HP_R7_HML[2], pm$h_ml, pm$h_hs, 100 * (pm$h_hs - hhb$lo) / (hhb$hi - hhb$lo), hhb$lo, hhb$hi, V(r7)))
cat(sprintf("  R8 unimodal top: best from %d starts (>= %d), basins within %g: %d, max |df| %.3f  -> %s\n", ag$n[1], HP_R8_N, HP_R8_WIN, nrow(near), max(abs(near$f - ag$f[1])), V(r8)))
cat("\n  ⛔ Nothing adopted. Promotion is Marcus's call.\n")
saveRDS(list(tab = tab, basins = ag, best = best, fam = lapply(FAM, function(S) S[setdiff(names(S), "st")]), fam_st = lapply(FAM, `[[`, "st"), ent26_st = S0$st, ent26 = S0[setdiff(names(S0), "st")],
             preds = c(R1 = r1, R2 = r2, R3 = r3, R4 = r4, R5 = r5, R6 = r6, R7 = r7, R8 = r8)), HP_OUT); cat(sprintf("  saved %s\n", HP_OUT))
