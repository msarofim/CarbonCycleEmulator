# =====================================================================
# diag_hilda30_predictions.R -- SCORE ROUND 3 OF THE HILDA REFIT (Torch job
# 17150003, 30 parameters, objective #10 + #11, literature prior on the HS
# pump) AGAINST prereg_2026-09-07f R1-R11. Basin table from the start files;
# the best start of every basin family AND ent26 (structure OFF) run through the
# transient and scored stream by stream under the same objective. Every
# "vs ent26" is on the COMMON rows (ent26 has no HS box, hence no hs_surf_*).
# Adopts nothing. Usage: Rscript calibration/diag_hilda30_predictions.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
source(ccx_path("calibration", "lib_design_gates.R"))
HP_DIR <- ccx_path("calibration", "output", "multistart_20260907f_hilda30")
HP_N_EXPECTED <- 46L
HP_PRIOR <- readRDS(ccx_path("data", "obs_hs_export_prior.rds"))
HP_R1_BAND <- c(10, 120); HP_R2_Z <- 2; HP_R3_TOL <- 5; HP_R4_PZ <- 2; HP_R4_EXPORT_R2 <- 73.6; HP_R5_R2_ALK <- -13.8
HP_R7_HML <- c(60, 180); HP_R8_TOL <- 2; HP_R9_HS13_MAX <- 2.08; HP_R10_Z <- 1; HP_R11_N <- 10; HP_R11_WIN <- 5; HP_R11_DG <- 20
HP_MARGIN <- 0.05
HP_PROFILE_ROWS <- c("d14c_profile_level", "d14c_profile_ab", "d14c_profile_bd")
HP_PUMP_ROWS <- c("ocean_grad_d13c", "ocean_grad_dic", "ocean_grad_alk")
HP_HS_ROWS <- c("hs_surf_dic", "hs_surf_d13c")
HP_OUT <- ccx_path("outputs", "diagnostics", "hilda30_predictions_20260908.rds")
fs <- list.files(HP_DIR, pattern = "^start_[0-9]+[.]rds$", full.names = TRUE)
R <- lapply(fs, readRDS); lp <- vapply(R, `[[`, 0, "logpost")
if (length(R) < HP_N_EXPECTED) cat(sprintf("\n⚠ PARTIAL: %d of %d starts on disk -- an interim read, not the verdict.\n", length(R), HP_N_EXPECTED))
pz_hs <- function(pm) (log(pm$pump_hs_gcm2) - log(HP_PRIOR$centre_gcm2)) / HP_PRIOR$log_sd
tab <- data.frame(id = vapply(R, `[[`, 0L, "id"), logpost = lp, basin = round(lp, 2),
                  hs_g = vapply(R, function(x) x$par_mode$pump_hs_gcm2, 0), f = vapply(R, function(x) x$par_mode$kz_deep_frac, 0),
                  asx = vapply(R, function(x) x$par_mode$hs_asx_frac, 0), kz = vapply(R, function(x) x$par_mode$kz, 0),
                  h_ml = vapply(R, function(x) x$par_mode$h_ml, 0), h_hs = vapply(R, function(x) x$par_mode$h_hs, 0),
                  pump_grad = vapply(R, function(x) x$par_mode$pump_grad, 0))
ag <- do.call(rbind, lapply(split(tab, tab$basin), function(d) data.frame(logpost = d$basin[1], n = nrow(d), id = d$id[which.max(d$logpost)],
  hs_g = mean(d$hs_g), f = mean(d$f), K_deep = mean(d$f * d$kz), asx = mean(d$asx), h_ml = mean(d$h_ml), h_hs = mean(d$h_hs), kz = mean(d$kz), pump_grad = mean(d$pump_grad))))
ag <- ag[order(-ag$logpost), ]
cat(sprintf("\n=== HILDA REFIT ROUND 3 (job 17150003): %d starts, %d basins ===\n", nrow(tab), nrow(ag)))
print(ag, row.names = FALSE, digits = 4)
best <- R[[which.max(lp)]]; pm <- best$par_mode
cat(sprintf("\nBEST: id %d, logpost %.4f\n", best$id, best$logpost))
for (n in c("pump_hs_gcm2", "kz_deep_frac", "hs_asx_frac", "h_hs", "kz", "h_ml", "k_w", "tau_ex", "pump_grad", "q10", "beta_max", "fert_k"))
  cat(sprintf("  %-14s %10.4f  prior_z %+6.2f\n", n, pm[[n]], if (n == "pump_hs_gcm2") pz_hs(pm) else best$prior_z[[n]]))
z <- best$prior_z; big <- names(z)[abs(z) > 2]
cat(sprintf("  |prior_z| > 2: %s; pump_hs_gcm2 prior-z %+.2f (lognormal, median %.1f)\n", if (length(big)) paste(sprintf("%s %+.2f", big, z[big]), collapse = ", ") else "none", pz_hs(pm), HP_PRIOR$centre_gcm2))

mk_v <- function(p, pmv) list(p = p, pm = pmv, luc_scale = pmv$luc_scale, bomb_total = pmv$bomb_total, sigma_d14c = pmv$sigma_d14c,
                              rep_dC = pmv$rep_dC, grad_off_co2 = pmv$grad_off_co2, grad_off_d13c = pmv$grad_off_d13c)
v_of <- function(st) { p <- ccx_apply_structure(ccx_default_params(), "hilda"); p$pump_mode <- st$pump_mode; mk_v(ccx_overlay_par(p, st$par_mode), st$par_mode) }
tg7 <- dg_gcb_target(DG_SINK_WIN); ob5 <- dg_obs_gate5(); sp5 <- dg_obs_gate5_spread(); spec <- ccx_profile_d14c_spec(); tgh <- ccx_hs_surface_target()
rho <- ccx_const("RHO_SEAWATER")
score <- function(v) { r <- dg_run(v); st <- dg_streams(r, v); sp <- r$sp; aux <- sp$aux; sl <- ccx_model_d14c_slabs(sp); lev <- c(sl[[1]], sl[[2]], sp$diagnostics$d14c_bottom_box)
  g7 <- dg_gate7(r); v7 <- dg_gate7_verdict(g7, tg7); v5 <- dg_gate5_verdict(dg_gate5(r), ob5, sp5)
  hs <- ccx_ocean_grad_scored(r$out, sp)$hs_surf
  e_ls <- sum(vapply(HEMIS, function(h) sum(aux$pump[[h]]$org) + sum(aux$pump[[h]]$carb), numeric(1)))
  e_hs <- if (is.null(aux$pump_hs)) 0 else sum(vapply(HEMIS, function(h) aux$pump_hs[[h]]$org + aux$pump_hs[[h]]$carb, numeric(1)))
  list(st = st, lev = lev, z = c(level = (mean(lev) - spec$level) / spec$level_sd, ab = ((lev[1] - lev[2]) - spec$ab) / spec$ab_sd, bd = ((lev[2] - lev[3]) - spec$bd) / spec$bd_sd),
       hs = sp$diagnostics$d14c_hs[["NH"]], hd = sp$diagnostics$d14c_hd[["NH"]], sink = g7$ocean, z7 = v7$z_ocean, z5 = c(v5$z[["nh_t"]], v5$z[["sh_t"]]),
       hs_dic = if (is.null(hs)) NA else hs$dic, hs_d13c = if (is.null(hs)) NA else hs$d13c, e_ls = e_ls, e_hs = e_hs) }
v0 <- dg_vector(CCX_MODE_COLUMN_CONTROL)   # ent26, the column control (09-08f: the canonical is HILDA); S0 <- score(v0)
FAM <- lapply(seq_len(nrow(ag)), function(k) { st <- R[[which(tab$id == ag$id[k])]]; c(list(id = st$id, logpost = st$logpost, pm = st$par_mode), score(v_of(st))) })
common <- function(S) sum(S$st[setdiff(names(S$st), HP_HS_ROWS)])
rowsum <- function(S, rows) sum(S$st[intersect(rows, names(S$st))])
cat(sprintf("\n  %-9s %3s | %7s %7s %7s | %6s %6s %6s | %7s %7s | %8s %7s %7s %7s | %5s | %6s %6s %6s %6s\n", "logpost", "id", "A", "B", "deep", "z_lev", "z_AB", "z_BD", "HS14", "HD14", "lik_com", "d_com", "d_rows", "d_rest", "sink", "hsDIC", "hs13", "E_ls", "E_hs"))
for (S in c(FAM, list(c(list(id = NA, logpost = NA), S0)))) { lab <- if (is.na(S$id)) "ent26 OFF" else sprintf("%.2f", S$logpost)
  cat(sprintf("  %-9s %3s | %7.1f %7.1f %7.1f | %+6.2f %+6.2f %+6.2f | %7.1f %7.1f | %8.1f %+7.1f %+7.1f %+7.1f | %5.2f | %6.0f %+6.2f %6.1f %6.2f\n", lab, if (is.na(S$id)) "-" else S$id,
              S$lev[1], S$lev[2], S$lev[3], S$z[1], S$z[2], S$z[3], if (is.null(S$hs)) NA else S$hs, if (is.null(S$hd)) NA else S$hd, common(S), common(S) - common(S0),
              rowsum(S, HP_PROFILE_ROWS) - rowsum(S0, HP_PROFILE_ROWS), (common(S) - rowsum(S, HP_PROFILE_ROWS)) - (common(S0) - rowsum(S0, HP_PROFILE_ROWS)), S$sink, S$hs_dic, S$hs_d13c, S$e_ls, S$e_hs)) }
cat(sprintf("  OBS: HS surface DIC %.0f (SH), d13C %+.2f; ent26 has no hs rows -- lik_com / d_com are on the COMMON rows.\n", tgh$dic$target, tgh$d13c$target))
B <- FAM[[1]]
cat("\n  best vs ent26, per common stream, |delta| > 1.5:\n")
for (n in setdiff(names(S0$st), HP_HS_ROWS)) { d <- B$st[[n]] - S0$st[[n]]; if (abs(d) > 1.5) cat(sprintf("    %-24s %+8.2f   (ent26 %9.2f)\n", n, d, S0$st[[n]])) }
cat(sprintf("  best's own hs rows: hs_surf_dic %.2f (model %.0f), hs_surf_d13c %.2f (model %+.2f, z %+.2f)\n", B$st[["hs_surf_dic"]], B$hs_dic, B$st[["hs_surf_d13c"]], B$hs_d13c, (B$hs_d13c - tgh$d13c$target) / sqrt(tgh$d13c$sd^2 + tgh$d13c$sd_cluster^2)))
hb <- CCX_PARAM_TABLE$pump_hs_gcm2; hhb <- CCX_PARAM_TABLE$h_hs; interior <- function(x, b) (x - b$lo) / (b$hi - b$lo) > HP_MARGIN && (b$hi - x) / (b$hi - b$lo) > HP_MARGIN
r1 <- interior(pm$pump_hs_gcm2, hb) && pm$pump_hs_gcm2 >= HP_R1_BAND[1] && pm$pump_hs_gcm2 <= HP_R1_BAND[2]
r2 <- all(abs(B$z) < HP_R2_Z)
r3 <- (B$st[["ocean_grad_d13c"]] - S0$st[["ocean_grad_d13c"]]) > -HP_R3_TOL
r4 <- abs(best$prior_z[["pump_grad"]]) <= HP_R4_PZ && B$e_ls < HP_R4_EXPORT_R2
r5 <- (B$st[["ocean_grad_alk"]] - S0$st[["ocean_grad_alk"]]) > HP_R5_R2_ALK
r6 <- (common(B) - common(S0)) > (rowsum(B, HP_PROFILE_ROWS) - rowsum(S0, HP_PROFILE_ROWS))
r7 <- pm$h_ml >= HP_R7_HML[1] && pm$h_ml <= HP_R7_HML[2] && interior(pm$h_hs, hhb)
bomb <- c("d14c_NH", "d14c_SH"); r8 <- (B$st[["gcb_ocean_sink"]] - S0$st[["gcb_ocean_sink"]] > -HP_R8_TOL) && all(B$st[bomb] - S0$st[bomb] > -HP_R8_TOL)
r9 <- B$hs_d13c <= HP_R9_HS13_MAX && abs(B$hs_dic - tgh$dic$target) <= sqrt(tgh$dic$sd^2 + tgh$dic$sd_cluster^2)
r10 <- pz_hs(pm) > HP_R10_Z
near <- ag[ag$logpost > ag$logpost[1] - HP_R11_WIN, ]; r11 <- ag$n[1] >= HP_R11_N && all(abs(near$hs_g - ag$hs_g[1]) <= HP_R11_DG)
V <- function(ok) if (isTRUE(ok)) "PASS" else "FAIL"
cat("\n  PREDICTIONS (prereg_2026-09-07f_hs_pump_round3.md):\n")
cat(sprintf("  R1  pump_hs_gcm2 interior and in [%g, %g]: %.1f gC m-2 yr-1 = %.2f GtC/yr  -> %s\n", HP_R1_BAND[1], HP_R1_BAND[2], pm$pump_hs_gcm2, B$e_hs, V(r1)))
cat(sprintf("  R2  profile rows inside %g sigma: %+.2f / %+.2f / %+.2f  -> %s\n", HP_R2_Z, B$z[1], B$z[2], B$z[3], V(r2)))
cat(sprintf("  R3  ocean_grad_d13c within %g of ent26: %+.2f  -> %s\n", HP_R3_TOL, B$st[["ocean_grad_d13c"]] - S0$st[["ocean_grad_d13c"]], V(r3)))
cat(sprintf("  R4  pump_grad prior-z within +/-%g and LS export < %.1f: %+.2f, %.1f GtC/yr  -> %s\n", HP_R4_PZ, HP_R4_EXPORT_R2, best$prior_z[["pump_grad"]], B$e_ls, V(r4)))
cat(sprintf("  R5  ocean_grad_alk better than round 2's %+.1f: %+.2f  -> %s\n", HP_R5_R2_ALK, B$st[["ocean_grad_alk"]] - S0$st[["ocean_grad_alk"]], V(r5)))
cat(sprintf("  R6  common-row gain %+.2f exceeds the profile rows' own %+.2f (rest %+.2f)  -> %s\n", common(B) - common(S0), rowsum(B, HP_PROFILE_ROWS) - rowsum(S0, HP_PROFILE_ROWS), (common(B) - common(S0)) - (rowsum(B, HP_PROFILE_ROWS) - rowsum(S0, HP_PROFILE_ROWS)), V(r6)))
cat(sprintf("  R7  h_ml in [%g, %g] and h_hs interior: %.1f, %.1f  -> %s\n", HP_R7_HML[1], HP_R7_HML[2], pm$h_ml, pm$h_hs, V(r7)))
cat(sprintf("  R8  sink and bomb within %g of ent26: sink %+.2f, d14c_NH %+.2f, d14c_SH %+.2f  -> %s\n", HP_R8_TOL, B$st[["gcb_ocean_sink"]] - S0$st[["gcb_ocean_sink"]], B$st[["d14c_NH"]] - S0$st[["d14c_NH"]], B$st[["d14c_SH"]] - S0$st[["d14c_SH"]], V(r8)))
cat(sprintf("  R9  HS d13C <= %+.2f and HS DIC inside 1 sigma of %.0f: %+.2f, %.0f  -> %s  (RECORDED rows)\n", HP_R9_HS13_MAX, tgh$dic$target, B$hs_d13c, B$hs_dic, V(r9)))
cat(sprintf("  R10 pump_hs_gcm2 prior-z > %+g (the data want more export than the floats): %+.2f  -> %s\n", HP_R10_Z, pz_hs(pm), V(r10)))
cat(sprintf("  R11 unimodal: best from %d starts (>= %d), basins within %g: %d, max |d hs_g| %.1f  -> %s\n", ag$n[1], HP_R11_N, HP_R11_WIN, nrow(near), max(abs(near$hs_g - ag$hs_g[1])), V(r11)))
cat("\n  ⛔ Nothing adopted. Promotion is Marcus's call.\n")
saveRDS(list(tab = tab, basins = ag, best = best, fam = lapply(FAM, function(S) S[setdiff(names(S), "st")]), fam_st = lapply(FAM, `[[`, "st"), ent26_st = S0$st, ent26 = S0[setdiff(names(S0), "st")],
             n_starts = nrow(tab), preds = c(R1 = r1, R2 = r2, R3 = r3, R4 = r4, R5 = r5, R6 = r6, R7 = r7, R8 = r8, R9 = r9, R10 = r10, R11 = r11)), HP_OUT); cat(sprintf("  saved %s\n", HP_OUT))
