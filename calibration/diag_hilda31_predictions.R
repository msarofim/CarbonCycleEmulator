# =====================================================================
# diag_hilda31_predictions.R -- SCORE ROUND 4 OF THE HILDA REFIT (u_hs FREED
# under the observed overturning, h_ml under the Holte mean/max prior; 31
# parameters, objective #10 + #11) AGAINST prereg_2026-09-08d R1-R10. Basin
# table from the start files; the best start of every basin family AND the
# round-3 winner (30 par, u_hs migrated to 38) run through the transient and
# scored stream by stream under the same objective -- so every comparison is on
# LIKELIHOOD (two priors changed between the rounds; logposts are not
# comparable). Adopts nothing.
# Usage: Rscript calibration/diag_hilda31_predictions.R
#        CCX_R4_DIR=<other outdir> to smoke-test on another round's files.
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))
R4_DIR <- Sys.getenv("CCX_R4_DIR", ccx_path("calibration", "output", "multistart_20260908d_hilda31"))
R3_DIR <- ccx_path("calibration", "output", "multistart_20260907f_hilda30")
R4_N_EXPECTED <- 46L; R4_ARM <- "N"
R4_UHS_PRIOR <- ccx_u_hs_prior(); R4_HML_PRIOR <- ccx_h_ml_prior(); R4_HS_PRIOR <- readRDS(ccx_path("data", "obs_hs_export_prior.rds"))
R4_R1_HI <- 33; R4_R1_LO <- 27                       # the pre-registered reading: >= 33 structural; <= 27 the observation holds
R4_R2_RATIO <- c(3.6, 4.3); R4_R3_HML <- c(50, 100); R4_R4_TOL <- 5; R4_R3_LIK <- -1438.64
R4_R5_UHS <- 30; R4_R5_HS13 <- 2.40; R4_R6_Z <- 2; R4_R7_N <- 10; R4_R7_WIN <- 5; R4_R7_DU <- 5; R4_R8_TOL <- 2; R4_R10_FRAC <- 0.30
R4_R3_KZF <- 0.02475; R4_R3_ASX <- 0.8175           # round 3's winner (id 24), CHANGELOG 2026-09-08
R4_PROFILE_ROWS <- c("d14c_profile_level", "d14c_profile_ab", "d14c_profile_bd"); R4_HS_ROWS <- c("hs_surf_dic", "hs_surf_d13c")
R4_OUT <- ccx_path("outputs", "diagnostics", sprintf("hilda31_predictions_%s.rds", format(Sys.Date(), "%Y%m%d")))
fs <- list.files(R4_DIR, pattern = "^start_[0-9]+[.]rds$", full.names = TRUE)
if (!length(fs)) stop("no start files in ", R4_DIR)
S <- lapply(fs, readRDS); lp <- vapply(S, `[[`, 0, "logpost")
if (length(S) < R4_N_EXPECTED) cat(sprintf("\n⚠ PARTIAL: %d of %d starts on disk -- an interim read, not the verdict.\n", length(S), R4_N_EXPECTED))
pmv <- function(st) ccx_migrate_par_set(st$par_mode)   # a round-3 file (30 names) migrates u_hs -> 38 and says so
tab <- data.frame(id = vapply(S, `[[`, 0L, "id"), logpost = lp, basin = round(lp, 2),
                  u_hs = vapply(S, function(x) pmv(x)$u_hs, 0), hs_g = vapply(S, function(x) pmv(x)$pump_hs_gcm2, 0),
                  f = vapply(S, function(x) pmv(x)$kz_deep_frac, 0), asx = vapply(S, function(x) pmv(x)$hs_asx_frac, 0),
                  kz = vapply(S, function(x) pmv(x)$kz, 0), h_ml = vapply(S, function(x) pmv(x)$h_ml, 0), h_hs = vapply(S, function(x) pmv(x)$h_hs, 0))
ag <- do.call(rbind, lapply(split(tab, tab$basin), function(d) data.frame(logpost = d$basin[1], n = nrow(d), id = d$id[which.max(d$logpost)],
  u_hs = mean(d$u_hs), hs_g = mean(d$hs_g), ratio = mean(d$hs_g / d$u_hs), f = mean(d$f), asx = mean(d$asx), h_ml = mean(d$h_ml), h_hs = mean(d$h_hs), kz = mean(d$kz))))
ag <- ag[order(-ag$logpost), ]
cat(sprintf("\n=== HILDA REFIT ROUND 4 (%s): %d starts, %d basins ===\n", basename(R4_DIR), nrow(tab), nrow(ag))); print(ag, row.names = FALSE, digits = 4)
best <- S[[which.max(lp)]]; pm <- pmv(best)
zu <- (log(pm$u_hs) - log(R4_UHS_PRIOR$centre_m_yr)) / R4_UHS_PRIOR$log_sd; zh <- (log(pm$h_ml) - log(R4_HML_PRIOR$centre_m)) / R4_HML_PRIOR$log_sd
zg <- (log(pm$pump_hs_gcm2) - log(R4_HS_PRIOR$centre_gcm2)) / R4_HS_PRIOR$log_sd
cat(sprintf("\nBEST: id %d, logpost %.4f%s\n  u_hs %.2f m/yr (%.1f Sv; prior z %+.2f; 38 would be %+.2f)   pump_hs %.1f (z %+.2f, ratio %.2f x u_hs)   h_ml %.1f (z %+.2f)   f %.4f  asx %.3f  h_hs %.0f  kz %.0f\n",
            best$id, best$logpost, if (length(attr(pm, "migrated"))) paste0("  [MIGRATED: ", paste(attr(pm, "migrated"), collapse = ", "), "]") else "",
            pm$u_hs, pm$u_hs * R4_UHS_PRIOR$a_hs_m2 / 3.156e13, zu, R4_UHS_PRIOR$z_hilda, pm$pump_hs_gcm2, zg, pm$pump_hs_gcm2 / pm$u_hs, pm$h_ml, zh, pm$kz_deep_frac, pm$hs_asx_frac, pm$h_hs, pm$kz))

mk_v <- function(p, pmv) list(p = p, pm = pmv, luc_scale = pmv$luc_scale, bomb_total = pmv$bomb_total, sigma_d14c = pmv$sigma_d14c, rep_dC = pmv$rep_dC, grad_off_co2 = pmv$grad_off_co2, grad_off_d13c = pmv$grad_off_d13c)
v_of <- function(st) { p <- ccx_apply_structure(ccx_default_params(), "hilda"); p$pump_mode <- st$pump_mode; pmm <- pmv(st); mk_v(ccx_overlay_par(p, pmm), pmm) }
spec <- ccx_profile_d14c_spec(); tgh <- ccx_hs_surface_target(); tg7 <- dg_gcb_target(DG_SINK_WIN)
score <- function(v) { r <- dg_run(v); st <- dg_streams(r, v); sp <- r$sp; aux <- sp$aux; sl <- ccx_model_d14c_slabs(sp); lev <- c(sl[[1]], sl[[2]], sp$diagnostics$d14c_bottom_box)
  hs <- ccx_ocean_grad_scored(r$out, sp)$hs_surf; g7 <- dg_gate7(r)
  e_hs <- if (is.null(aux$pump_hs)) 0 else sum(vapply(HEMIS, function(h) aux$pump_hs[[h]]$org + aux$pump_hs[[h]]$carb, numeric(1)))
  list(st = st, lik = sum(st), z = c(level = (mean(lev) - spec$level) / spec$level_sd, ab = ((lev[1] - lev[2]) - spec$ab) / spec$ab_sd, bd = ((lev[2] - lev[3]) - spec$bd) / spec$bd_sd),
       hs_d13c = if (is.null(hs)) NA else hs$d13c, hs_dic = if (is.null(hs)) NA else hs$dic, sink = g7$ocean, e_hs = e_hs) }
r3f <- list.files(R3_DIR, pattern = "^start_[0-9]+[.]rds$", full.names = TRUE); R3 <- lapply(r3f, readRDS); b3 <- R3[[which.max(vapply(R3, `[[`, 0, "logpost"))]]
S3 <- score(v_of(b3)); cat(sprintf("\nround-3 winner (id %d) re-scored under this build: lik %.2f (recorded %.2f)\n", b3$id, S3$lik, R4_R3_LIK))
FAM <- lapply(seq_len(nrow(ag)), function(k) { st <- S[[which(tab$id == ag$id[k])]]; c(list(id = st$id, logpost = st$logpost, pm = pmv(st)), score(v_of(st))) })
cat(sprintf("\n  %-9s %3s | %6s %6s %6s | %8s %+7s | %+6s %+6s %+6s | %+6s %6s | %5s %6s\n", "logpost", "id", "u_hs", "hs_g", "h_ml", "lik", "d_vs_r3", "z_lev", "z_AB", "z_BD", "HS13", "hsDIC", "sink", "E_hs"))
for (F in FAM) cat(sprintf("  %-9.2f %3d | %6.1f %6.1f %6.1f | %8.2f %+7.2f | %+6.2f %+6.2f %+6.2f | %+6.2f %6.0f | %5.2f %6.2f\n", F$logpost, F$id, F$pm$u_hs, F$pm$pump_hs_gcm2, F$pm$h_ml, F$lik, F$lik - S3$lik, F$z[1], F$z[2], F$z[3], F$hs_d13c, F$hs_dic, F$sink, F$e_hs))
B <- FAM[[1]]; d <- B$st - S3$st; cat("\n  best vs round-3 winner, per stream, |d| > 1.5:\n"); for (n in names(d)[order(-abs(d))]) if (abs(d[[n]]) > 1.5) cat(sprintf("    %-24s %+8.2f\n", n, d[[n]]))
V <- function(ok) if (isTRUE(ok)) "PASS" else "FAIL"
reading <- if (pm$u_hs >= R4_R1_HI) "STRUCTURAL: the flush is a SINK requirement -- declare u_hs at the observation and add the mode-water limb" else if (pm$u_hs <= R4_R1_LO) "THE OBSERVATION HOLDS -- adopt-worthy on likelihood" else "CONTEST -- report the profile, do not adopt"
r1 <- pm$u_hs >= R4_R1_HI; ratio <- pm$pump_hs_gcm2 / pm$u_hs; r2 <- ratio >= R4_R2_RATIO[1] && ratio <= R4_R2_RATIO[2]
r3 <- pm$h_ml >= R4_R3_HML[1] && pm$h_ml <= R4_R3_HML[2]; r4 <- (B$lik - S3$lik) > -R4_R4_TOL
r5 <- !(pm$u_hs < R4_R5_UHS && B$hs_d13c >= R4_R5_HS13); r6 <- all(abs(B$z) < R4_R6_Z)
near <- ag[ag$logpost > ag$logpost[1] - R4_R7_WIN, ]; r7 <- ag$n[1] >= R4_R7_N && all(abs(near$u_hs - ag$u_hs[1]) <= R4_R7_DU)
bomb <- c("gcb_ocean_sink", "d14c_NH", "d14c_SH"); r8 <- all(abs(B$st[bomb] - S3$st[bomb]) < R4_R8_TOL)
r10 <- abs(pm$kz_deep_frac / R4_R3_KZF - 1) <= R4_R10_FRAC && abs(pm$hs_asx_frac / R4_R3_ASX - 1) <= R4_R10_FRAC
cat("\n  PREDICTIONS (prereg_2026-09-08d_round4_u_hs_freed.md):\n")
cat(sprintf("  R1  u_hs >= %g (the CO2 rows win): %.2f m/yr, prior z %+.2f  -> %s   READING: %s\n", R4_R1_HI, pm$u_hs, zu, V(r1), reading))
cat(sprintf("  R2  pump_hs / u_hs in [%g, %g]: %.2f  -> %s\n", R4_R2_RATIO[1], R4_R2_RATIO[2], ratio, V(r2)))
cat(sprintf("  R3  h_ml in [%g, %g]: %.1f (z %+.2f)  -> %s\n", R4_R3_HML[1], R4_R3_HML[2], pm$h_ml, zh, V(r3)))
cat(sprintf("  R4  likelihood within %g of round 3: %.2f vs %.2f (%+.2f)  -> %s\n", R4_R4_TOL, B$lik, S3$lik, B$lik - S3$lik, V(r4)))
cat(sprintf("  R5  conditional (u_hs < %g => HS d13C < %+.2f): u_hs %.1f, HS d13C %+.2f  -> %s\n", R4_R5_UHS, R4_R5_HS13, pm$u_hs, B$hs_d13c, V(r5)))
cat(sprintf("  R6  profile rows inside %g sigma: %+.2f / %+.2f / %+.2f  -> %s\n", R4_R6_Z, B$z[1], B$z[2], B$z[3], V(r6)))
cat(sprintf("  R7  unimodal: best from %d starts (>= %d), basins within %g agree on u_hs to %g: %d basins, max |du| %.1f  -> %s\n", ag$n[1], R4_R7_N, R4_R7_WIN, R4_R7_DU, nrow(near), max(abs(near$u_hs - ag$u_hs[1])), V(r7)))
cat(sprintf("  R8  sink and bomb rows within %g of round 3: %s  -> %s\n", R4_R8_TOL, paste(sprintf("%s %+.2f", bomb, B$st[bomb] - S3$st[bomb]), collapse = ", "), V(r8)))
cat(sprintf("  R9  RECORDED: HS d13C %+.2f (obs %+.2f), HS DIC %.0f (obs %.0f); gate Q -> diag_whole_model_scorecard.R\n", B$hs_d13c, tgh$d13c$target, B$hs_dic, tgh$dic$target))
cat(sprintf("  R10 kz_deep_frac / hs_asx_frac within %.0f %% of round 3: %.4f vs %.4f, %.3f vs %.3f  -> %s\n", 100 * R4_R10_FRAC, pm$kz_deep_frac, R4_R3_KZF, pm$hs_asx_frac, R4_R3_ASX, V(r10)))
cat("\n  ⛔ Nothing adopted. Promotion is Marcus's call.\n")
saveRDS(list(tab = tab, basins = ag, best = best, pm = pm, fam = lapply(FAM, function(F) F[setdiff(names(F), "st")]), fam_st = lapply(FAM, `[[`, "st"), r3 = S3[setdiff(names(S3), "st")], r3_st = S3$st,
             preds = c(R1 = r1, R2 = r2, R3 = r3, R4 = r4, R5 = r5, R6 = r6, R7 = r7, R8 = r8, R10 = r10), reading = reading, consts = mget(ls(pattern = "^R4_"))), R4_OUT); cat(sprintf("  saved %s\n", R4_OUT))
