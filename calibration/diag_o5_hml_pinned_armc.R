# =====================================================================
# diag_o5_hml_pinned_armc.R -- how much of O5's arm-C gain does the THIN
# MIXED LAYER buy? (Marcus 09-16: "follow the recommendations", item 3)
#
# WHY. O5's arm C (diag_o5_seasonal_export_scan.R, 09-15 g) put h_ml on its
# box floor (32.0 m; the Holte prior's ~3rd percentile) at martin amp 1 lag 0
# and read -125.7 like-for-like vs the canonical. The seasonal export's DIC
# anomaly on a thinner reservoir is a larger pCO2 signal, so the optimiser used
# h_ml as the amplitude knob the capped pump_seas_amp could not be. This
# re-runs the same arm C with h_ml PINNED -- at the canonical's 65.2 m (the
# like-for-like number) and at the prior's 16 % point 42.5 m (the bound the
# array would carry) -- for BOTH amp 0 and amp 1, so the O5 gain is read at a
# fixed reservoir. Same machinery, same names minus h_ml; nothing adopted.
# Rule stated first: the O5 gain SURVIVES if (amp 1 - amp 0) at pinned h_ml
# keeps >= 50 % of the free-h_ml gain (162.9 = -288.6 -> -125.7).
# Run from the repo root:  Rscript calibration/diag_o5_hml_pinned_armc.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
HP_COMMIT <- ccx_git_stamp()
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))
HP_ARM    <- CCX_MODE_CANONICAL
HP_EXPORT <- ccx_pump_export_prior()$centre_gtc
HP_PINS   <- c(canonical = NA_real_, prior16 = ccx_h_ml_prior()$q[2])     # 65.2 (read from the mode below), 42.5
HP_AMP    <- c(0, 1); HP_LAG <- 0
HP_FREE   <- c("beta_max", "fert_k", "q10", "kz_deep_frac", "k_w", "bomb_total", "sigma_d14c")   # the PK-2 eight minus h_ml
HP_NM_MAXIT <- 1500; HP_BFGS_MAXIT <- 100; HP_GATE_TOL <- 1e-4
HP_FREE_GAIN <- 162.9; HP_RULE_SHARE <- 0.5
HP_OUT <- ccx_path("outputs", "diagnostics", sprintf("o5_hml_pinned_armc_%s", format(Sys.Date(), "%Y%m%d")))
sink_log <- file(paste0(HP_OUT, ".log"), open = "wt"); sink(sink_log, split = TRUE); on.exit({ sink(); close(sink_log) }, add = TRUE)
cat(sprintf("== O5 arm C with h_ml PINNED at %s -- commit %s ==\n", HP_ARM, HP_COMMIT))
v0 <- dg_vector(HP_ARM); md <- v0$md; HP_PINS[["canonical"]] <- v0$p$h_ml
obs <- ccx_prepare_obs(); o_spo <- obs$co2_seas$SPO
harm <- function(h) c(amp = sqrt(h$a_mean^2 + h$b_mean^2), phase_mo = (atan2(h$b_mean, h$a_mean) / (2 * pi)) * 12)
r_ref <- dg_run(v0); ref <- unlist(dg_streams(r_ref, v0))
rm_pins <- ccx_apply_pins(ccx_mode_pins(md)); on.exit(ccx_unpin_params(rm_pins), add = TRUE)
bp0 <- ccx_mode_base(md); bp0$pump_mode <- md$pump_mode
st <- ccx_mode_start(md, "o5_hml"); pm0 <- st$p
lp0 <- ccx_make_logpost(base_params = bp0, by_stream = TRUE, spinup_fn = ccx_spinup_from_label(ccx_mode_spinup(md)))
v_s <- lp0(st$u); ref_st <- attr(v_s, "streams")
cat(sprintf("HARNESS GATE 4: rebuilt logpost %.4f (shift %+.4f) vs stored %.4f -> %s\n", as.numeric(v_s) - st$logpost_shift, st$logpost_shift, md$logpost,
            if (abs(as.numeric(v_s) - st$logpost_shift - md$logpost) < HP_GATE_TOL) "PASS" else "FAIL"))
ccx_unpin_params(rm_pins); rm_pins <- list()
point_p <- function(amp, lag, hml) { v <- v0; p <- v$p; p$pump_field <- "martin"; p$pump_export <- HP_EXPORT
  p$gamma_enso_ocn_NH <- 0; p$gamma_enso_ocn_SH <- 0; p$gamma_vent <- 0; p$w_vent <- 0; p$w_thc <- 0
  p$pump_seas_amp <- amp; p$pump_seas_lag <- lag; p$h_ml <- hml; v$p <- p; v }
read_point <- function(v) { r <- dg_run(v); out <- r$out; sp <- r$sp
  ms <- ccx_model_stats(out[out$t < DG_SINK_LAST + 1, ], obs); hs <- harm(ms$co2_seas$SPO)
  aux <- sp$aux; g <- sp$grid; y <- sp$y
  cl <- function(h, k) { m <- if (k == 0) aux$a_ml[[h]] * g$dz[1] else aux$a_ls[[h]] * g$dz[k + 1]; i <- if (k == 0) aux$idx[[h]]$ml else aux$idx[[h]]$oc[k]
    y[i, "C"] * aux$mol_per_GtC / (m * ccx_const("RHO_SEAWATER")) * 1e6 }
  list(spo_amp = hs[["amp"]], spo_phase = hs[["phase_mo"]], L2 = mean(sapply(HEMIS, function(h) cl(h, 2) - cl(h, 0)))) }
reopt <- function(amp, lag, hml) {
  pins <- c(ccx_mode_pins(md), c(w_thc = 0, w_vent = 0, gamma_vent = 0, gamma_enso_ocn_NH = 0, gamma_enso_ocn_SH = 0, h_ml = hml))
  rm <- ccx_apply_pins(pins); on.exit(ccx_unpin_params(rm), add = TRUE)
  bp <- bp0; for (n in names(pins)) bp[[n]] <- pins[[n]]
  bp$pump_field <- "martin"; bp$pump_seas_amp <- amp; bp$pump_seas_lag <- lag
  lp <- ccx_make_logpost(base_params = bp, by_stream = TRUE, spinup_fn = ccx_spinup_from_label(ccx_mode_spinup(md)))
  pm <- pm0[setdiff(names(pm0), names(pins))]; pm$pump_export <- HP_EXPORT
  u <- ccx_par_to_unc(pm); stopifnot(all(is.finite(u)))
  idx <- match(HP_FREE, CCX_PARAM_NAMES); stopifnot(!any(is.na(idx)))
  fobj <- function(z) { uu <- u; uu[idx] <- z; x <- -as.numeric(lp(uu)); if (!is.finite(x)) 1e10 else x }
  v_raw <- lp(u)
  o1 <- stats::optim(u[idx], fobj, method = "Nelder-Mead", control = list(maxit = HP_NM_MAXIT, reltol = 1e-10))
  o2 <- stats::optim(o1$par, fobj, method = "BFGS", control = list(maxit = HP_BFGS_MAXIT, reltol = 1e-12))
  bst <- if (o2$value < o1$value) o2 else o1; uu <- u; uu[idx] <- bst$par
  v <- lp(uu); pmb <- ccx_unc_to_par(uu)
  st_raw <- attr(v_raw, "streams"); st_c <- attr(v, "streams"); cm <- intersect(names(st_c), names(ref_st))
  vv <- point_p(amp, lag, hml); for (n in names(pmb)) if (n %in% names(vv$p)) vv$p[[n]] <- pmb[[n]]
  for (n in c("luc_scale", "bomb_total", "sigma_d14c", "rep_dC", "grad_off_co2", "grad_off_d13c")) if (!is.null(pmb[[n]])) vv[[n]] <- pmb[[n]]
  list(amp = amp, hml = hml, pm = pmb, dlik_raw = sum(st_raw[cm] - ref_st[cm]), dlik = sum(st_c[cm] - ref_st[cm]), d = st_c[cm] - ref_st[cm],
       spo = st_c[["co2_seasonal_SPO"]] - ref_st[["co2_seasonal_SPO"]], n_eval = o1$counts[1] + o2$counts[1], read = read_point(vv))
}
S <- list()
for (pn in names(HP_PINS)) for (amp in HP_AMP) {
  t0 <- proc.time()[["elapsed"]]; r <- reopt(amp, HP_LAG, HP_PINS[[pn]]); S[[paste(pn, amp)]] <- r
  cat(sprintf("h_ml %s = %.1f m, amp %.0f: raw %+8.1f -> armC %+8.1f | SPO %+7.1f | SPO harm %.3f ppm @ %+5.2f mo | L2-ML %+4.0f | kz_deep_frac %.4f k_w %.0f bomb_total %.1f sigma_d14c %.2f beta_max %.3f | %d evals [%.0f s]\n",
              pn, HP_PINS[[pn]], amp, r$dlik_raw, r$dlik, r$spo, r$read$spo_amp, r$read$spo_phase, r$read$L2, r$pm$kz_deep_frac, r$pm$k_w, r$pm$bomb_total, r$pm$sigma_d14c, r$pm$beta_max, r$n_eval, proc.time()[["elapsed"]] - t0))
  cat(sprintf("        largest rows: %s\n", paste(sprintf("%s %+.1f", names(sort(r$d))[1:5], sort(r$d)[1:5]), collapse = ", ")))
}
cat(sprintf("\n== THE RULE: the O5 gain survives if (amp 1 - amp 0) at pinned h_ml keeps >= %.0f %% of the free-h_ml gain (%.1f) ==\n", 100 * HP_RULE_SHARE, HP_FREE_GAIN))
for (pn in names(HP_PINS)) { g <- S[[paste(pn, 1)]]$dlik - S[[paste(pn, 0)]]$dlik
  cat(sprintf("h_ml %s (%.1f m): amp 0 %+.1f -> amp 1 %+.1f, gain %+.1f = %.0f %% of the free gain -> %s; the thin ML bought %+.1f of O5's %+.1f at amp 1\n",
              pn, HP_PINS[[pn]], S[[paste(pn, 0)]]$dlik, S[[paste(pn, 1)]]$dlik, g, 100 * g / HP_FREE_GAIN, if (g >= HP_RULE_SHARE * HP_FREE_GAIN) "SURVIVES" else "DOES NOT SURVIVE",
              -125.7 - S[[paste(pn, 1)]]$dlik, -125.7)) }
saveRDS(list(S = S, pins = HP_PINS, free = HP_FREE, free_gain = HP_FREE_GAIN, ref_st = ref_st, commit = HP_COMMIT, built = format(Sys.time())), paste0(HP_OUT, ".rds"))
cat(sprintf("\nsaved %s.{log,rds}\n", HP_OUT))
