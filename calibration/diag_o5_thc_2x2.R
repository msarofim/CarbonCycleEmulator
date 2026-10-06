# =====================================================================
# diag_o5_thc_2x2.R -- THE O5 x THC 2x2 of notes/prereg_2026-09-16_o5_thc_2x2.md:
# the seasonal export at its SOURCE's LS amplitude (SH median 0.5, lag -1) and
# the HS-route deep exit (w_thc 10 Sv, k_thc 10), alone and together, under the
# prescribed field at Nowicki's 9.08, unrefitted at hilda30c then arm C (the
# PK-2 eight) at every cell. Bounds: O5 at the source IQR ends (raw), THC k 8
# with O5 (raw). The decision rule (prereg §3) is printed; nothing adopted.
# Usage: Rscript calibration/diag_o5_thc_2x2.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
X2_COMMIT <- ccx_git_stamp()
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))
X2_ARM <- CCX_MODE_CANONICAL; X2_EXPORT <- ccx_pump_export_prior()$centre_gtc
src <- readRDS(ccx_path("data", "obs_export_seasonal_shape_cmip6.rds")); sm <- src$summary
X2_AMP <- round(sm$amp_med[sm$series == "SH_LS"], 2); X2_LAG <- round(sm$lag_med[sm$series == "SH_LS"])       # 0.5 / -1, READ
X2_AMP_IQR <- round(c(sm$amp_q25[sm$series == "SH_LS"], sm$amp_q75[sm$series == "SH_LS"]), 2)
X2_LAG_IQR <- round(c(sm$lag_q25[sm$series == "SH_LS"], sm$lag_q75[sm$series == "SH_LS"]), 1)
X2_W <- 10; X2_K <- 10L; X2_K_ALT <- 8L
X2_ARMC <- c("beta_max", "fert_k", "q10", "kz_deep_frac", "h_ml", "k_w", "bomb_total", "sigma_d14c")
X2_NM_MAXIT <- 1500; X2_BFGS_MAXIT <- 100; X2_GATE_TOL <- 1e-4
X2_RULE_ADD <- 20; X2_RULE_DICZ <- 1; X2_RULE_SPO <- 20
X2_OUT <- ccx_path("outputs", "diagnostics", sprintf("o5_thc_2x2_%s", format(Sys.Date(), "%Y%m%d")))
sink_log <- file(paste0(X2_OUT, ".log"), open = "wt"); sink(sink_log, split = TRUE); on.exit({ sink(); close(sink_log) }, add = TRUE)
cat(sprintf("== O5 x THC 2x2 at %s (prereg 2026-09-16) -- commit %s ==\nsource: SH LS amp %.2f [%.2f, %.2f], lag %+d mo [%+.1f, %+.1f]; THC k %d W %g Sv; export %.2f\n\n", X2_ARM,
            X2_COMMIT, X2_AMP, X2_AMP_IQR[1], X2_AMP_IQR[2], X2_LAG, X2_LAG_IQR[1], X2_LAG_IQR[2], X2_K, X2_W, X2_EXPORT))
obs <- ccx_prepare_obs(); exc_obs <- obs$excess_c14; i95 <- which(exc_obs$year == 1995); tg <- ccx_ocean_gradient_target()
harm <- function(h) c(amp = sqrt(h$a_mean^2 + h$b_mean^2), phase_mo = (atan2(h$b_mean, h$a_mean) / (2 * pi)) * 12)
v0 <- dg_vector(X2_ARM); md <- v0$md; r_ref <- dg_run(v0); ref <- unlist(dg_streams(r_ref, v0))
cat(sprintf("HARNESS GATE 1: %.4f vs %.4f -> %s\n", sum(ref[names(md$streams)]), sum(md$streams), if (abs(sum(ref[names(md$streams)]) - sum(md$streams)) < X2_GATE_TOL) "PASS" else "FAIL"))
conc_layer <- function(y, aux, grid, h, k) { m <- if (k == 0) aux$a_ml[[h]] * grid$dz[1] else aux$a_ls[[h]] * grid$dz[k + 1]
  i <- if (k == 0) aux$idx[[h]]$ml else aux$idx[[h]]$oc[k]; y[i, "C"] * aux$mol_per_GtC / (m * ccx_const("RHO_SEAWATER")) * 1e6 }
point_p <- function(amp, lag, W, k) { v <- v0; p <- v$p; p$pump_field <- "martin"; p$pump_export <- X2_EXPORT
  p$gamma_enso_ocn_NH <- 0; p$gamma_enso_ocn_SH <- 0; p$gamma_vent <- 0; p$w_vent <- 0
  p$pump_seas_amp <- amp; p$pump_seas_lag <- lag; p$w_thc <- W; p$k_thc <- k; v$p <- p; v }
read_point <- function(v) { r <- dg_run(v); sp <- r$sp; aux <- sp$aux; g <- sp$grid; y <- sp$y; out <- r$out; yr <- floor(out$t + 1e-9)
  stv <- unlist(dg_streams(r, v)); cm <- intersect(names(stv), names(ref)); d <- stv[cm] - ref[cm]
  exc <- ccx_c14_kmol(mean(out$ocean_C14[yr == 1995]) - out$ocean_C14[1]); gg <- ccx_ocean_grad_scored(out, sp)
  ms <- ccx_model_stats(out[out$t < DG_SINK_LAST + 1, ], obs); hs <- harm(ms$co2_seas$SPO)
  pr <- rowMeans(sapply(HEMIS, function(h) c(conc_layer(y, aux, g, h, 2), conc_layer(y, aux, g, h, 6)) - conc_layer(y, aux, g, h, 0)))
  rows <- function(pat) sum(d[grep(pat, cm)])
  list(d = d, dlik = sum(d), spo = d[["co2_seasonal_SPO"]], spo_amp = hs[["amp"]], spo_phase = hs[["phase_mo"]], dic = gg$dic, z_dic = (gg$dic - tg$dic$target) / gg$sd_eff[["dic"]],
       exc95 = exc, z_exc95 = (exc - exc_obs$centre[i95]) / exc_obs$half_width[i95], L2 = pr[1], L6 = pr[2], d14prof = rows("^d14c_profile"), bomb = rows("^d14c_(NH|SH)$"), d13 = rows("^d13c")) }
fmt <- function(lab, rp) sprintf("%-22s | dlik %+8.1f | SPO %+7.1f (%.3f ppm @ %+5.2f) | DIC %5.1f (z %+4.1f) | exc95 %5.1f (z %+4.1f) | L2/L6-ML %+4.0f/%+4.0f | d14prof %+6.1f bomb %+6.1f d13 %+6.1f",
                                lab, rp$dlik, rp$spo, rp$spo_amp, rp$spo_phase, rp$dic, rp$z_dic, rp$exc95, rp$z_exc95, rp$L2, rp$L6, rp$d14prof, rp$bomb, rp$d13)
cells <- list(none = c(0, 0, 0, X2_K), O5 = c(X2_AMP, X2_LAG, 0, X2_K), THC = c(0, 0, X2_W, X2_K), both = c(X2_AMP, X2_LAG, X2_W, X2_K))
cat("== STAGE 1: raw ==\n"); S1 <- list()
for (n in names(cells)) { c1 <- cells[[n]]; S1[[n]] <- read_point(point_p(c1[1], c1[2], c1[3], as.integer(c1[4]))); cat(fmt(n, S1[[n]]), "\n") }
for (lab in list(c("O5 amp q25 lag q25", X2_AMP_IQR[1], X2_LAG_IQR[1], 0), c("O5 amp q75 lag q75", X2_AMP_IQR[2], X2_LAG_IQR[2], 0), c("both, THC k8", X2_AMP, X2_LAG, X2_W))) {
  k <- if (grepl("k8", lab[1])) X2_K_ALT else X2_K; rp <- read_point(point_p(as.numeric(lab[2]), as.numeric(lab[3]), as.numeric(lab[4]), k)); S1[[lab[1]]] <- rp; cat(fmt(lab[1], rp), "\n") }
inter_raw <- S1$both$dlik - S1$O5$dlik - S1$THC$dlik + S1$none$dlik
cat(sprintf("\nP1 O5 SPO raw %+.1f (predicted ~ -178); P2 |SPO(both) - SPO(O5)| = %.1f (pred <= 10), DIC z(both) %+.2f (pred <= +0.6); P3 interaction raw %+.1f (pred within +-30)\n\n",
            S1$O5$spo, abs(S1$both$spo - S1$O5$spo), S1$both$z_dic, inter_raw))
# ---- arm C at every cell ------------------------------------------------
cat("== STAGE 2: arm C ==\n")
rm_pins <- ccx_apply_pins(ccx_mode_pins(md)); on.exit(ccx_unpin_params(rm_pins), add = TRUE)
bp0 <- ccx_mode_base(md); bp0$pump_mode <- md$pump_mode; st <- ccx_mode_start(md, "o5_thc"); pm0 <- st$p
lp0 <- ccx_make_logpost(base_params = bp0, by_stream = TRUE, spinup_fn = ccx_spinup_from_label(ccx_mode_spinup(md))); v_s <- lp0(st$u); ref_st <- attr(v_s, "streams")
cat(sprintf("HARNESS GATE 4: %.4f vs %.4f -> %s\n", as.numeric(v_s) - st$logpost_shift, md$logpost, if (abs(as.numeric(v_s) - st$logpost_shift - md$logpost) < X2_GATE_TOL) "PASS" else "FAIL"))
ccx_unpin_params(rm_pins); rm_pins <- list()
reopt <- function(amp, lag, W, k) {
  pins <- c(ccx_mode_pins(md), c(w_vent = 0, gamma_vent = 0, gamma_enso_ocn_NH = 0, gamma_enso_ocn_SH = 0), if (W == 0) c(w_thc = 0) else NULL)
  rm <- ccx_apply_pins(pins); on.exit(ccx_unpin_params(rm), add = TRUE)
  bp <- bp0; for (n in names(pins)) bp[[n]] <- pins[[n]]; bp$pump_field <- "martin"; bp$pump_seas_amp <- amp; bp$pump_seas_lag <- lag; bp$k_thc <- k
  lp <- ccx_make_logpost(base_params = bp, by_stream = TRUE, spinup_fn = ccx_spinup_from_label(ccx_mode_spinup(md)))
  pm <- pm0[setdiff(names(pm0), names(pins))]; pm$pump_export <- X2_EXPORT; if (W > 0) pm$w_thc <- W
  u <- ccx_par_to_unc(pm); stopifnot(all(is.finite(u))); idx <- match(X2_ARMC, CCX_PARAM_NAMES); stopifnot(!any(is.na(idx)))
  fobj <- function(z) { uu <- u; uu[idx] <- z; x <- -as.numeric(lp(uu)); if (!is.finite(x)) 1e10 else x }
  v_raw <- lp(u); o1 <- stats::optim(u[idx], fobj, method = "Nelder-Mead", control = list(maxit = X2_NM_MAXIT, reltol = 1e-10))
  o2 <- stats::optim(o1$par, fobj, method = "BFGS", control = list(maxit = X2_BFGS_MAXIT, reltol = 1e-12))
  bst <- if (o2$value < o1$value) o2 else o1; uu <- u; uu[idx] <- bst$par; v <- lp(uu); pmb <- ccx_unc_to_par(uu)
  st_raw <- attr(v_raw, "streams"); st_c <- attr(v, "streams"); cm <- intersect(names(st_c), names(ref_st))
  vv <- point_p(amp, lag, W, k); for (n in names(pmb)) if (n %in% names(vv$p)) vv$p[[n]] <- pmb[[n]]
  for (n in c("luc_scale", "bomb_total", "sigma_d14c", "rep_dC", "grad_off_co2", "grad_off_d13c")) if (!is.null(pmb[[n]])) vv[[n]] <- pmb[[n]]
  list(pm = pmb, dlik_raw = sum(st_raw[cm] - ref_st[cm]), dlik = sum(st_c[cm] - ref_st[cm]), d = st_c[cm] - ref_st[cm], n_eval = o1$counts[1] + o2$counts[1], read = read_point(vv)) }
S2 <- list()
for (n in names(cells)) { c1 <- cells[[n]]; t0 <- proc.time()[["elapsed"]]
  r <- tryCatch(reopt(c1[1], c1[2], c1[3], as.integer(c1[4])), error = function(e) { cat(sprintf("armC %s FAILED: %s\n", n, conditionMessage(e))); NULL }); if (is.null(r)) next; S2[[n]] <- r
  cat(sprintf("armC %s\n", fmt(sprintf("%s (raw %+.1f)", n, r$dlik_raw), r$read)))
  cat(sprintf("        armC dlik %+.1f | h_ml %.1f kz_deep_frac %.4f k_w %.0f bomb_total %.1f sigma_d14c %.2f beta_max %.3f | %d evals [%.0f s] | largest: %s\n", r$dlik, r$pm$h_ml, r$pm$kz_deep_frac, r$pm$k_w, r$pm$bomb_total, r$pm$sigma_d14c, r$pm$beta_max, r$n_eval, proc.time()[["elapsed"]] - t0,
              paste(sprintf("%s %+.1f", names(sort(r$d))[1:4], sort(r$d)[1:4]), collapse = ", "))) }
cat(sprintf("\n== THE RULE: ADDITIVE iff armC dlik(both) >= max(O5, THC) + %d, DIC z(both) <= +%d, SPO(both) >= SPO(O5) - %d ==\n", X2_RULE_ADD, X2_RULE_DICZ, X2_RULE_SPO))
ok <- all(c("none", "O5", "THC", "both") %in% names(S2))
if (ok) { a <- S2$both$dlik >= max(S2$O5$dlik, S2$THC$dlik) + X2_RULE_ADD; b <- S2$both$read$z_dic <= X2_RULE_DICZ; cc <- S2$both$read$spo >= S2$O5$read$spo - X2_RULE_SPO
  inter_c <- S2$both$dlik - S2$O5$dlik - S2$THC$dlik + S2$none$dlik
  cat(sprintf("armC: none %+.1f | O5 %+.1f | THC %+.1f | both %+.1f | interaction %+.1f | (a) %s (b) z %+.2f %s (c) SPO %+.1f vs %+.1f %s\nVERDICT: %s\n",
              S2$none$dlik, S2$O5$dlik, S2$THC$dlik, S2$both$dlik, inter_c, if (a) "PASS" else "FAIL", S2$both$read$z_dic, if (b) "PASS" else "FAIL", S2$both$read$spo, S2$O5$read$spo, if (cc) "PASS" else "FAIL",
              if (a && b && cc) "O5 and THC ADD under the prescribed field" else "O5 and THC do NOT add under this build -- reported")) }
saveRDS(list(cells = cells, S1 = S1, S2 = S2, amp = X2_AMP, lag = X2_LAG, W = X2_W, k = X2_K, ref = ref, commit = X2_COMMIT, built = format(Sys.time())), paste0(X2_OUT, ".rds"))
cat(sprintf("\nsaved %s.{log,rds}\n", X2_OUT))
