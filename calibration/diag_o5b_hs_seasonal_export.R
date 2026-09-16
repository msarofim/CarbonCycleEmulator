# =====================================================================
# diag_o5b_hs_seasonal_export.R -- O5b of notes/prereg_2026-09-16b_o5b_hs_seasonal_export.md:
# the HS pump on the CMIP6 rectified bloom shape (pump_hs_seas_amp / _lag), the LS
# pump on O5's sine at its source (SH LS median 0.5 / -1), under the prescribed
# field at Nowicki's 9.08, unrefitted at hilda30c (raw grid + the canonical's own
# control), then arm C (the PK-2 eight) with the h_ml band set IN PROCESS to
# [42.5, 200] (Marcus 09-16 b). The rule (prereg §3) is stated in ppm / uatm and
# printed; nothing is adopted. The HS SH pCO2 first harmonic is the OUT-OF-SAMPLE
# row (SOM-FFN 40-90S, data/obs_so_pco2_seas_amp.rds).
# Usage: Rscript calibration/diag_o5b_hs_seasonal_export.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))
OB_ARM <- CCX_MODE_CANONICAL; OB_EXPORT <- ccx_pump_export_prior()$centre_gtc
src <- readRDS(ccx_path("data", "obs_export_seasonal_shape_cmip6.rds")); sm <- src$summary
OB_LS_AMP <- round(sm$amp_med[sm$series == "SH_LS"], 2); OB_LS_LAG <- round(sm$lag_med[sm$series == "SH_LS"])   # 0.5 / -1, READ
OB_HS_AMPS <- c(0, 0.25, 0.5, 0.75, 1); OB_HS_LAGS <- c(-1, 0, 1)
OB_CTRL_AMPS <- c(0.5, 1)                                                     # the canonical's own control (solved field)
OB_ARMC <- c("beta_max", "fert_k", "q10", "kz_deep_frac", "h_ml", "k_w", "bomb_total", "sigma_d14c")
OB_HML_BAND <- c(42.5, 200)                                                   # Marcus 09-16 (b): the arrays' floor, applied in process
OB_NM_MAXIT <- 1500; OB_BFGS_MAXIT <- 100; OB_GATE_TOL <- 1e-4; OB_GATE2_TOL <- 0.5
OB_HARM_WINDOW <- c(1985, 2014)                                               # the pCO2 harmonic's window (a climatology; the SOM-FFN product is one)
OB_RULE_A_PPM <- 0.46; OB_RULE_PHS_UATM <- 33; OB_RULE_PHASE_MO <- 1; OB_RULE_DLIK <- 20; OB_PARTIAL_PPM <- 0.03
so <- readRDS(ccx_path("data", "obs_so_pco2_seas_amp.rds"))
X2 <- ccx_path("outputs", "diagnostics", "o5_thc_2x2_20260916.rds")
OB_OUT <- ccx_path("outputs", "diagnostics", sprintf("o5b_hs_seasonal_export_%s", format(Sys.Date(), "%Y%m%d")))
sink_log <- file(paste0(OB_OUT, ".log"), open = "wt"); sink(sink_log, split = TRUE); on.exit({ sink(); close(sink_log) }, add = TRUE)
commit <- tryCatch(system("git rev-parse --short HEAD", intern = TRUE), error = function(e) "?")
cat(sprintf("== O5b: the HS pump on the rectified bloom, at %s (prereg 2026-09-16 b) -- commit %s ==\nLS sine at the source: amp %.2f lag %+d; HS amp grid {%s} x lag {%s}; export %.2f; arm C h_ml band [%g, %g]\nSO pCO2 obs (%s): %.1f uatm @ month %.1f\n\n",
            OB_ARM, commit, OB_LS_AMP, OB_LS_LAG, paste(OB_HS_AMPS, collapse = ", "), paste(OB_HS_LAGS, collapse = ", "), OB_EXPORT, OB_HML_BAND[1], OB_HML_BAND[2], so$band_label, so$band_amp_uatm, so$band_peak_month))
obs <- ccx_prepare_obs(); exc_obs <- obs$excess_c14; i95 <- which(exc_obs$year == 1995); tg <- ccx_ocean_gradient_target()
harm <- function(h) c(amp = sqrt(h$a_mean^2 + h$b_mean^2), phase_mo = (atan2(h$b_mean, h$a_mean) / (2 * pi)) * 12)
obs_spo <- harm(obs$co2_seas$SPO); cat(sprintf("GATE 0: obs SPO first harmonic %.3f ppm @ %+.2f mo\n", obs_spo[["amp"]], obs_spo[["phase_mo"]]))
circ_mo <- function(a, b) { d <- (a - b) %% 12; pmin(d, 12 - d) }
pco2_harm <- function(out, col) { w <- out$t >= OB_HARM_WINDOW[1] & out$t < OB_HARM_WINDOW[2] + 1; x <- out[[col]][w]; t <- out$t[w]
  a <- 2 * mean(x * cos(2 * pi * t)); b <- 2 * mean(x * sin(2 * pi * t)); c(amp = sqrt(a^2 + b^2), peak_month = ((atan2(b, a) / (2 * pi)) %% 1) * 12 + 0.5) }
v0 <- dg_vector(OB_ARM); md <- v0$md; r_ref <- dg_run(v0); ref <- unlist(dg_streams(r_ref, v0))
cat(sprintf("HARNESS GATE 1: %.4f vs %.4f -> %s\n", sum(ref[names(md$streams)]), sum(md$streams), if (abs(sum(ref[names(md$streams)]) - sum(md$streams)) < OB_GATE_TOL) "PASS" else "FAIL"))
ph0 <- pco2_harm(r_ref$out, "hs_pco2_SH"); cat(sprintf("the canonical's HS SH pCO2 first harmonic: %.2f uatm @ month %.1f (obs %.1f @ %.1f)\n", ph0[["amp"]], ph0[["peak_month"]], so$band_amp_uatm, so$band_peak_month))
conc_layer <- function(y, aux, grid, h, k) { m <- if (k == 0) aux$a_ml[[h]] * grid$dz[1] else aux$a_ls[[h]] * grid$dz[k + 1]
  i <- if (k == 0) aux$idx[[h]]$ml else aux$idx[[h]]$oc[k]; y[i, "C"] * aux$mol_per_GtC / (m * ccx_const("RHO_SEAWATER")) * 1e6 }
point_p <- function(hs_amp, hs_lag, field = "martin") { v <- v0; p <- v$p; p$pump_field <- field; if (field == "martin") p$pump_export <- OB_EXPORT
  p$gamma_enso_ocn_NH <- 0; p$gamma_enso_ocn_SH <- 0; p$gamma_vent <- 0; p$w_vent <- 0; p$w_thc <- 0
  if (field == "martin") { p$pump_seas_amp <- OB_LS_AMP; p$pump_seas_lag <- OB_LS_LAG }
  p$pump_hs_seas_amp <- hs_amp; p$pump_hs_seas_lag <- hs_lag; v$p <- p; v }
read_point <- function(v) { r <- dg_run(v); sp <- r$sp; aux <- sp$aux; g <- sp$grid; y <- sp$y; out <- r$out; yr <- floor(out$t + 1e-9)
  stv <- unlist(dg_streams(r, v)); cm <- intersect(names(stv), names(ref)); d <- stv[cm] - ref[cm]
  exc <- ccx_c14_kmol(mean(out$ocean_C14[yr == 1995]) - out$ocean_C14[1]); gg <- ccx_ocean_grad_scored(out, sp)
  ms <- ccx_model_stats(out[out$t < DG_SINK_LAST + 1, ], obs); hs <- harm(ms$co2_seas$SPO); pS <- pco2_harm(out, "hs_pco2_SH"); pN <- pco2_harm(out, "hs_pco2_NH"); pL <- pco2_harm(out, "ml_pco2_SH")
  pr <- rowMeans(sapply(HEMIS, function(h) c(conc_layer(y, aux, g, h, 2), conc_layer(y, aux, g, h, 6)) - conc_layer(y, aux, g, h, 0)))
  rows <- function(pat) sum(d[grep(pat, cm)])
  list(d = d, dlik = sum(d), spo = d[["co2_seasonal_SPO"]], mlo = d[["co2_seasonal_MLO"]], spo_amp = hs[["amp"]], spo_phase = hs[["phase_mo"]], dphase = circ_mo(hs[["phase_mo"]], obs_spo[["phase_mo"]]),
       phs_amp = pS[["amp"]], phs_peak = pS[["peak_month"]], phn_amp = pN[["amp"]], phn_peak = pN[["peak_month"]], pml_amp = pL[["amp"]], pml_peak = pL[["peak_month"]],
       dic = gg$dic, z_dic = (gg$dic - tg$dic$target) / gg$sd_eff[["dic"]], exc95 = exc, z_exc95 = (exc - exc_obs$centre[i95]) / exc_obs$half_width[i95], L2 = pr[1], L6 = pr[2],
       level = rows("^co2_(NH|SH|level)"), d14prof = rows("^d14c_profile"), bomb = rows("^d14c_(NH|SH)$"), d13 = rows("^d13c")) }
fmt <- function(lab, rp) sprintf("%-26s | dlik %+8.1f | SPO %+7.1f (%.3f ppm @ %+5.2f, d %.2f mo) MLO %+6.1f | HS pCO2 SH %5.1f uatm @ %4.1f (NH %4.1f @ %4.1f) LS ML SH %4.1f @ %4.1f | exc95 z %+4.1f | L2 %+4.0f | d14prof %+6.1f bomb %+5.1f d13 %+6.1f",
                                lab, rp$dlik, rp$spo, rp$spo_amp, rp$spo_phase, rp$dphase, rp$mlo, rp$phs_amp, rp$phs_peak, rp$phn_amp, rp$phn_peak, rp$pml_amp, rp$pml_peak, rp$z_exc95, rp$L2, rp$d14prof, rp$bomb, rp$d13)
# ---- gate 2: the O5 cell reproduces the 2x2's raw number (the precedence contract, measured) ----
S1 <- list(); o5 <- read_point(point_p(0, 0)); S1[["O5 source, HS amp 0"]] <- o5
if (file.exists(X2)) { x2 <- readRDS(X2); cat(sprintf("HARNESS GATE 2: O5 cell raw %.1f vs the 2x2's %.1f -> %s\n", o5$dlik, x2$S1$O5$dlik, if (abs(o5$dlik - x2$S1$O5$dlik) < OB_GATE2_TOL) "PASS" else "FAIL")) } else cat("HARNESS GATE 2: the 2x2 rds is absent -- not checked\n")
cat("\n== STAGE 1: raw grid (martin 9.08, LS sine at the source) ==\n"); cat(fmt("O5 source, HS amp 0", o5), "\n")
for (lag in OB_HS_LAGS) for (amp in OB_HS_AMPS[-1]) { lab <- sprintf("HS amp %.2f lag %+d", amp, lag); S1[[lab]] <- read_point(point_p(amp, lag)); cat(fmt(lab, S1[[lab]]), "\n") }
cat("\n== CONTROL: the canonical (solved field, its own HS pump; fitted at amp 0 -- a cost is expected, not a criterion) ==\n")
CTRL <- list(); for (amp in OB_CTRL_AMPS) { lab <- sprintf("canonical, HS amp %.1f", amp); CTRL[[lab]] <- read_point(point_p(amp, 0, field = "solved")); cat(fmt(lab, CTRL[[lab]]), "\n") }
grid_pts <- S1[setdiff(names(S1), "O5 source, HS amp 0")]; best_lab <- names(grid_pts)[which.max(sapply(grid_pts, `[[`, "dlik"))]
a1 <- S1[["HS amp 1.00 lag +0"]]
cat(sprintf("\nP1 (amp 1 lag 0, raw): SPO amplitude %.3f -> %.3f ppm (gain %+.3f; predicted <= +0.05) | P2: SPO row %+.1f -> %+.1f (%+.1f; predicted +30..+60), total %+.1f (predicted +20..+60) | P3: HS SH pCO2 %.2f -> %.2f uatm @ month %.1f (predicted 6-12 @ 8-11)\nbest raw grid point: %s (dlik %+.1f)\n\n",
            o5$spo_amp, a1$spo_amp, a1$spo_amp - o5$spo_amp, o5$spo, a1$spo, a1$spo - o5$spo, a1$dlik - o5$dlik, ph0[["amp"]], a1$phs_amp, a1$phs_peak, best_lab, grid_pts[[best_lab]]$dlik))
# ---- STAGE 2: arm C, h_ml band [42.5, 200] in process ------------------------
cat("== STAGE 2: arm C (the PK-2 eight), h_ml band set in process to [42.5, 200] AFTER gate 4 ==\n")
rm_pins <- ccx_apply_pins(ccx_mode_pins(md)); on.exit(ccx_unpin_params(rm_pins), add = TRUE)
bp0 <- ccx_mode_base(md); bp0$pump_mode <- md$pump_mode; st <- ccx_mode_start(md, "o5b"); pm0 <- st$p
lp0 <- ccx_make_logpost(base_params = bp0, by_stream = TRUE, spinup_fn = ccx_spinup_from_label(ccx_mode_spinup(md))); v_s <- lp0(st$u); ref_st <- attr(v_s, "streams")
cat(sprintf("HARNESS GATE 4: %.4f vs %.4f -> %s\n", as.numeric(v_s) - st$logpost_shift, md$logpost, if (abs(as.numeric(v_s) - st$logpost_shift - md$logpost) < OB_GATE_TOL) "PASS" else "FAIL"))
ccx_unpin_params(rm_pins); rm_pins <- list()
.ship_hml <- c(CCX_PARAM_TABLE$h_ml$lo, CCX_PARAM_TABLE$h_ml$hi)
CCX_PARAM_TABLE$h_ml$lo <- OB_HML_BAND[1]; CCX_PARAM_TABLE$h_ml$hi <- OB_HML_BAND[2]
on.exit({ CCX_PARAM_TABLE$h_ml$lo <- .ship_hml[1]; CCX_PARAM_TABLE$h_ml$hi <- .ship_hml[2] }, add = TRUE)
cat(sprintf("h_ml band now [%g, %g] (shipped [%g, %g]); the like-for-like dlik below is on the LIKELIHOOD streams, so the band's Jacobian does not enter\n", CCX_PARAM_TABLE$h_ml$lo, CCX_PARAM_TABLE$h_ml$hi, .ship_hml[1], .ship_hml[2]))
reopt <- function(hs_amp, hs_lag) {
  pins <- c(ccx_mode_pins(md), c(w_vent = 0, gamma_vent = 0, gamma_enso_ocn_NH = 0, gamma_enso_ocn_SH = 0, w_thc = 0))
  rm <- ccx_apply_pins(pins); on.exit(ccx_unpin_params(rm), add = TRUE)
  bp <- bp0; for (n in names(pins)) bp[[n]] <- pins[[n]]; bp$pump_field <- "martin"; bp$pump_seas_amp <- OB_LS_AMP; bp$pump_seas_lag <- OB_LS_LAG
  bp$pump_hs_seas_amp <- hs_amp; bp$pump_hs_seas_lag <- hs_lag
  lp <- ccx_make_logpost(base_params = bp, by_stream = TRUE, spinup_fn = ccx_spinup_from_label(ccx_mode_spinup(md)))
  pm <- pm0[setdiff(names(pm0), names(pins))]; pm$pump_export <- OB_EXPORT
  u <- ccx_par_to_unc(pm); stopifnot(all(is.finite(u))); idx <- match(OB_ARMC, CCX_PARAM_NAMES); stopifnot(!any(is.na(idx)))
  fobj <- function(z) { uu <- u; uu[idx] <- z; x <- -as.numeric(lp(uu)); if (!is.finite(x)) 1e10 else x }
  v_raw <- lp(u); o1 <- stats::optim(u[idx], fobj, method = "Nelder-Mead", control = list(maxit = OB_NM_MAXIT, reltol = 1e-10))
  o2 <- stats::optim(o1$par, fobj, method = "BFGS", control = list(maxit = OB_BFGS_MAXIT, reltol = 1e-12))
  bst <- if (o2$value < o1$value) o2 else o1; uu <- u; uu[idx] <- bst$par; v <- lp(uu); pmb <- ccx_unc_to_par(uu)
  st_raw <- attr(v_raw, "streams"); st_c <- attr(v, "streams"); cm <- intersect(names(st_c), names(ref_st))
  vv <- point_p(hs_amp, hs_lag); for (n in names(pmb)) if (n %in% names(vv$p)) vv$p[[n]] <- pmb[[n]]
  for (n in c("luc_scale", "bomb_total", "sigma_d14c", "rep_dC", "grad_off_co2", "grad_off_d13c")) if (!is.null(pmb[[n]])) vv[[n]] <- pmb[[n]]
  list(pm = pmb, dlik_raw = sum(st_raw[cm] - ref_st[cm]), dlik = sum(st_c[cm] - ref_st[cm]), d = st_c[cm] - ref_st[cm], n_eval = o1$counts[1] + o2$counts[1], read = read_point(vv)) }
parse_lab <- function(lab) { m <- regmatches(lab, regexec("amp ([0-9.]+) lag ([+-][0-9]+)", lab))[[1]]; c(as.numeric(m[2]), as.numeric(m[3])) }
cells <- list("O5 source, HS amp 0" = c(0, 0)); cells[[best_lab]] <- parse_lab(best_lab); if (!"HS amp 1.00 lag +0" %in% names(cells)) cells[["HS amp 1.00 lag +0"]] <- c(1, 0)
S2 <- list()
for (n in names(cells)) { c1 <- cells[[n]]; t0 <- proc.time()[["elapsed"]]
  r <- tryCatch(reopt(c1[1], c1[2]), error = function(e) { cat(sprintf("armC %s FAILED: %s\n", n, conditionMessage(e))); NULL }); if (is.null(r)) next; S2[[n]] <- r
  cat(sprintf("armC %s\n", fmt(sprintf("%s (raw %+.1f)", n, r$dlik_raw), r$read)))
  cat(sprintf("        armC dlik %+.1f | h_ml %.1f kz_deep_frac %.4f k_w %.0f bomb_total %.1f sigma_d14c %.2f beta_max %.3f | %d evals [%.0f s] | largest: %s\n", r$dlik, r$pm$h_ml, r$pm$kz_deep_frac, r$pm$k_w, r$pm$bomb_total, r$pm$sigma_d14c, r$pm$beta_max, r$n_eval, proc.time()[["elapsed"]] - t0,
              paste(sprintf("%s %+.1f", names(sort(r$d))[1:4], sort(r$d)[1:4]), collapse = ", "))) }
# ---- THE RULE (prereg §3), in the physical unit -----------------------------
cat(sprintf("\n== THE RULE: PASS iff after arm C (a) SPO amp >= %.2f ppm, (b) HS SH pCO2 amp <= %g uatm, (c) SPO phase within %g mo of obs, (d) dlik >= O5 cell + %d; PARTIAL iff (b), (d) and the SPO amp gains >= %.2f ppm ==\n",
            OB_RULE_A_PPM, OB_RULE_PHS_UATM, OB_RULE_PHASE_MO, OB_RULE_DLIK, OB_PARTIAL_PPM))
verdict <- NA_character_
if ("O5 source, HS amp 0" %in% names(S2) && length(S2) > 1) {
  o5c <- S2[["O5 source, HS amp 0"]]; cand <- S2[setdiff(names(S2), "O5 source, HS amp 0")]
  for (n in names(cand)) { r <- cand[[n]]$read; a <- r$spo_amp >= OB_RULE_A_PPM; b <- r$phs_amp <= OB_RULE_PHS_UATM; cc <- r$dphase <= OB_RULE_PHASE_MO; dd <- cand[[n]]$dlik >= o5c$dlik + OB_RULE_DLIK
    gain <- r$spo_amp - o5c$read$spo_amp
    vd <- if (a && b && cc && dd) "PASS" else if (a && !b) "SPO BOUGHT WITH AN UNOBSERVED HS pCO2 AMPLITUDE (the joint-power case) -- not a pass" else if (b && dd && gain >= OB_PARTIAL_PPM) "PARTIAL (real, insufficient)" else "REFUTED"
    cat(sprintf("%-26s armC dlik %+.1f vs O5 cell %+.1f | SPO amp %.3f (gain %+.3f) %s | HS pCO2 %.1f %s | phase d %.2f %s | (d) %s => %s\n", n, cand[[n]]$dlik, o5c$dlik, r$spo_amp, gain,
                if (a) "PASS" else "fail", r$phs_amp, if (b) "PASS" else "fail", r$dphase, if (cc) "PASS" else "fail", if (dd) "PASS" else "fail", vd))
    if (is.na(verdict) || vd == "PASS") verdict <- vd }
  cat(sprintf("VERDICT: O5b %s\n", verdict)) }
saveRDS(list(S1 = S1, CTRL = CTRL, S2 = S2, cells = cells, best_raw = best_lab, verdict = verdict, ref = ref, obs_spo = obs_spo, canonical_phs = ph0, so_obs = so[c("band_amp_uatm", "band_peak_month", "band_label")],
             ls_amp = OB_LS_AMP, ls_lag = OB_LS_LAG, export = OB_EXPORT, hml_band_armc = OB_HML_BAND, harm_window = OB_HARM_WINDOW, rule = c(A_ppm = OB_RULE_A_PPM, PHS_uatm = OB_RULE_PHS_UATM, phase_mo = OB_RULE_PHASE_MO, dlik = OB_RULE_DLIK, partial_ppm = OB_PARTIAL_PPM),
             commit = commit, built = format(Sys.time())), paste0(OB_OUT, ".rds"))
cat(sprintf("\nsaved %s.{log,rds}\n", OB_OUT))
