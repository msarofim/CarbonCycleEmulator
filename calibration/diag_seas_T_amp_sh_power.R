# =====================================================================
# diag_seas_T_amp_sh_power.R -- THE SH CANCELLATION ARM
#   Pre-registered in notes/prereg_2026-08-27n_seas_T_amp_SH_cancellation_arm.md,
#   committed 11a59de BEFORE this file existed. NO GATE MAY MOVE.
#
# HYPOTHESIS (27m). The model's SH land signal at SPO is 1.92x observed not
# because its productivity is too big but because too little of it is CANCELLED.
# CT2022: SH land nets only 25.1 % of its gross swing to air (NH 68.2 %). The
# cancelling channel is soil respiration, scaled by `seas_T_amp_SH`, which the
# fit drove to 1.0391 K = 28.9 % of its measured bracket's LOW end.
#
# ⚠ UNLIKE `seas_npp_amp_SH`, THIS IS A CALIBRATED PARAMETER, NOT A CONSTANT.
# Two consequences the driver must respect and both are easy to get wrong:
#   (1) it is set through the UNCONSTRAINED VECTOR (tr = "log", so u = log(x)),
#       not through base_params;
#   (2) the conditional slice must REMOVE it from the free set -- leaving it in
#       would let the optimiser walk straight back to the incumbent and report
#       "no cost", which is a structurally guaranteed null. [[no_power_null]]
#
# Usage:  Rscript calibration/diag_seas_T_amp_sh_power.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

TA_YEARS <- c(1750, 2024)
# THE MEASUREMENT, from R/constants.R -- every label below derives from these.
TA_LO   <- ccx_const("SEAS_T_AMP_SH_OBS_LO")     # 3.5915 K, all SH land
TA_HI   <- ccx_const("SEAS_T_AMP_SH_OBS_HI")     # 7.1012 K, SH land >30S
TA_INIT <- sqrt(TA_LO * TA_HI)                   # 5.0503, the prior's centre
# Grid. The first four are the MEASURED bracket; the last two are GEOMETRY
# POINTS reported for the floor and NOT proposed values -- prereg sec.2.
TA_GRID <- c(1.0391, TA_LO, TA_INIT, TA_HI, 11.08, 13.95, 20.0)
TA_INBRACKET <- c(1.0391, TA_LO, TA_INIT, TA_HI)
TA_COND  <- c(1.0391, TA_LO, TA_INIT, TA_HI)     # conditional arm: bracket only
# Slice = 27i's block MINUS seas_T_amp_SH, which is the profiled parameter.
TA_COND_BLOCK <- c("sst_seas_amp_NH", "sst_seas_amp_SH", "seas_T_amp_NH",
                   "seas_lag_p", "q10")
TA_MAXIT <- 1500; TA_RESTARTS <- 6; TA_RESTOL <- 0.02
TA_COST_ROWS <- c("co2_seasonal_MLO", "co2_seasonal_SPO", "d13c_seasonal_MLO",
                  "d13c_seasonal_SPO", "co2_level_MLO", "co2_level_SPO",
                  "d13c_level_MLO", "d13c_level_SPO", "gcb_land_sink",
                  "co2_gradient", "d13c_gradient")
TA_OBS_SPO_LAND <- 0.683         # inversion at the mode, 2026-08-27h
# PRE-REGISTERED closed-form predictions (prereg sec.1), for gate P1.
TA_PRED <- c(1.313, 1.119, 1.015, 0.879)
TA_PRED_FLOOR <- 0.633

sep <- function(s) cat(sprintf("\n\n=== %s ===\n", s))
amp    <- function(v) 2 * sqrt(sum(v^2))                    # PEAK-TO-PEAK
ang_mo <- function(v) 12 * ((atan2(v[1], v[2]) / (2 * pi)) %% 1)

md <- readRDS(ccx_mode_file())
u0 <- md$u_mode                       # ⚠ SPELL IT OUT: md$u partial-matches this
names(u0) <- CCX_PARAM_NAMES
stopifnot("seas_T_amp_SH" %in% CCX_PARAM_NAMES)      # a PARAMETER, not a constant
i_at <- match("seas_T_amp_SH", CCX_PARAM_NAMES)
stopifnot(CCX_PARAM_TABLE$seas_T_amp_SH$tr == "log") # the u-space transform
pv0  <- ccx_unc_to_par(u0)
cat(sprintf("mode %s (arm %s)\n", basename(ccx_mode_file()), md$pump_mode))
cat(sprintf("seas_T_amp_SH landed %.4f K | bracket [%.4f, %.4f] | landed/LO %.3f\n",
            pv0$seas_T_amp_SH, TA_LO, TA_HI, pv0$seas_T_amp_SH / TA_LO))
cat(sprintf("seas_T_amp_NH landed %.4f K | /HI %.3f  (the hemispheric inversion)\n",
            pv0$seas_T_amp_NH, pv0$seas_T_amp_NH / ccx_const("SEAS_T_AMP_NH_OBS_HI")))

bp <- ccx_default_params(); bp$pump_mode <- md$pump_mode
lp <- ccx_make_logpost(years = TA_YEARS, base_params = bp)
u_at <- function(u, a) { u[i_at] <- log(a); u }
one  <- lp(u0)
cat(sprintf("\nharness at u_mode %.4f vs stored %.4f -> offset %+.4f (known -3.3223)\n",
            one, md$logpost, one - md$logpost))
if (abs((one - md$logpost) - (-3.3223)) > 0.5)
  cat("  ⚠ THE OFFSET HAS MOVED. Investigate BEFORE reading this run.\n")

obs  <- ccx_prepare_obs()
pick   <- function(ms, k) { kk <- strsplit(k, ".", fixed = TRUE)[[1]]; ms[[kk[1]]][[kk[2]]] }
vec_of <- function(h) if (is.null(h)) c(NA, NA) else c(mean(h$a), mean(h$b))

# ⚠ bomb_total / luc_scale come off `pv`: seven of the 21 calibrated names are
# likelihood-side and absent from ccx_default_params(). Cost a run on 27h.
run_at <- function(pv, mods = list()) {
  p <- ccx_default_params()
  for (n in intersect(names(p), CCX_PARAM_NAMES)) p[[n]] <- pv[[n]]
  p$gamma_enso <- pv$gamma_enso; p$pump_mode <- md$pump_mode
  for (n in names(mods)) p[[n]] <- mods[[n]]
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", TA_YEARS, prod_c14 = 0, bomb_total_kmol = 102)
  F$c14_cosmo <- sp$prod_c14
  F$c14_bomb  <- F$c14_bomb * (pv$bomb_total / 102)
  for (cc in c("e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH"))
    F[[cc]] <- F[[cc]] * pv$luc_scale
  attr(F, "luc_scale") <- pv$luc_scale
  ms <- ccx_model_stats(ccx_run_fast(sp, F)$out, obs)
  list(co2_SPO = vec_of(pick(ms, "co2_seas.SPO")), d13_SPO = vec_of(pick(ms, "d13_seas.SPO")),
       co2_MLO = vec_of(pick(ms, "co2_seas.MLO")), d13_MLO = vec_of(pick(ms, "d13_seas.MLO")))
}
TA_CASES <- list(SH_land = list(seas_npp_amp_SH = 0, seas_T_amp_SH = 0),
                 SH_resp = list(seas_T_amp_SH = 0),
                 SH_nep  = list(seas_npp_amp_SH = 0))
obsv <- list(co2_SPO = vec_of(pick(obs, "co2_seas.SPO")), d13_SPO = vec_of(pick(obs, "d13_seas.SPO")))
ratio_SPO <- function(b) (amp(b$d13_SPO)/amp(b$co2_SPO)) /
                         (amp(obsv$d13_SPO)/amp(obsv$co2_SPO))
sh_land_of <- function(pv) {
  b <- run_at(pv); amp(b$co2_SPO - run_at(pv, TA_CASES$SH_land)$co2_SPO)
}

# ---------------------------------------------------------------------
sep("P0 -- IDENTITY CONTROL (zero perturbation)")
pv_id <- ccx_unc_to_par(u_at(u0, pv0$seas_T_amp_SH))
sl_id <- sh_land_of(pv_id); lp_id <- lp(u_at(u0, pv0$seas_T_amp_SH))
cat(sprintf("  logpost delta %+0.6f (gate < 0.05) | SH-land %.4f vs %.4f (gate < 0.5%%)\n",
            lp_id - one, sl_id, TA_PRED[1]))
cat(sprintf("  P0 %s\n", if (abs(lp_id - one) < 0.05 &&
                             abs(sl_id - TA_PRED[1])/TA_PRED[1] < 0.005) "PASS" else "FAIL"))

sep("1. FROZEN PROFILE -- only seas_T_amp_SH moves (gates P1, P2, P3)")
cat(sprintf("  %8s %9s %9s %9s %9s %11s %10s\n", "a_t", "SH-land", "phase", "resp ch",
            "SPO tot", "dlogpost", "dlogprior"))
pri <- CCX_PARAM_TABLE$seas_T_amp_SH$prior
fro <- list()
for (a in TA_GRID) {
  u <- u_at(u0, a); pv <- ccx_unc_to_par(u)
  b  <- run_at(pv)
  sl <- b$co2_SPO - run_at(pv, TA_CASES$SH_land)$co2_SPO
  rc <- b$co2_SPO - run_at(pv, TA_CASES$SH_resp)$co2_SPO
  fro[[sprintf("%.4f", a)]] <- list(a = a, sl = amp(sl), ph = ang_mo(sl),
                                    rc = amp(rc), tot = amp(b$co2_SPO),
                                    lp = lp(u), r = ratio_SPO(b))
  cat(sprintf("  %8.4f %9.4f %9.2f %9.4f %9.4f %+11.2f %+10.2f%s\n",
              a, amp(sl), ang_mo(sl), amp(rc), amp(b$co2_SPO), lp(u) - one,
              pri(a) - pri(pv0$seas_T_amp_SH),
              if (a > TA_HI) "   [GEOMETRY ONLY -- outside the bracket]" else ""))
}
cat("\n  P1 -- closed-form prediction vs measured, in-bracket points (gate 3 %):\n")
p1 <- TRUE
for (i in seq_along(TA_INBRACKET)) {
  k <- sprintf("%.4f", TA_INBRACKET[i]); m <- fro[[k]]$sl
  d <- abs(m - TA_PRED[i]) / TA_PRED[i]; if (d > 0.03) p1 <- FALSE
  cat(sprintf("    a_t %7.4f  predicted %.3f  measured %.3f  diff %5.1f%% %s\n",
              TA_INBRACKET[i], TA_PRED[i], m, 100*d, if (d > 0.03) "FAIL" else "ok"))
}
cat(sprintf("  P1 %s\n", if (p1) "PASS" else "FAIL"))
sls <- vapply(fro, function(x) x$sl, 0); as_ <- vapply(fro, function(x) x$a, 0)
imin <- which.min(sls)
cat(sprintf("\n  P2 -- FLOOR. minimum SH-land %.4f at a_t = %.2f (predicted %.3f near 13.95);\n",
            sls[imin], as_[imin], TA_PRED_FLOOR))
cat(sprintf("       non-monotone? SH-land at 20.0 (%.4f) > at 13.95 (%.4f): %s\n",
            fro[["20.0000"]]$sl, fro[["13.9500"]]$sl,
            if (fro[["20.0000"]]$sl > fro[["13.9500"]]$sl) "YES" else "NO"))
cat(sprintf("  P2 %s\n", if (fro[["20.0000"]]$sl > fro[["13.9500"]]$sl &&
                             abs(sls[imin] - TA_PRED_FLOOR) < 0.02) "PASS" else "FAIL"))
dpri <- pri(TA_HI) - pri(pv0$seas_T_amp_SH)
cat(sprintf("\n  P3 -- PRIOR pays %+.2f from landed to bracket HI (predicted +8.34 +/- 0.05): %s\n",
            dpri, if (abs(dpri - 8.34) < 0.05) "PASS" else "FAIL"))

sep("2. WHICH ROWS PAY -- frozen, vs the incumbent")
# ⚠ THE PER-STREAM BREAKDOWN COMES FROM ccx_loglik(by_stream = TRUE), NOT from an
# attribute on the logpost. The first version of this script probed
# attr(lp(u), "streams"), got NULL, and skipped P5 -- the arm's DIAGNOSTIC gate --
# while printing a tidy "unavailable" line. A gate that silently declines to run
# is worse than one that fails. [[mutation_test_gates]]
streams_at <- function(u) {
  pv <- ccx_unc_to_par(u)
  p  <- ccx_default_params()
  for (n in intersect(names(p), CCX_PARAM_NAMES)) p[[n]] <- pv[[n]]
  p$gamma_enso <- pv$gamma_enso; p$pump_mode <- md$pump_mode
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", TA_YEARS, prod_c14 = 0, bomb_total_kmol = 102)
  F$c14_cosmo <- sp$prod_c14; F$c14_bomb <- F$c14_bomb * (pv$bomb_total / 102)
  for (cc in c("e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH"))
    F[[cc]] <- F[[cc]] * pv$luc_scale
  attr(F, "luc_scale") <- pv$luc_scale
  o <- ccx_run_fast(sp, F)$out
  unlist(ccx_loglik(o, obs, list(sigma_d14c = pv$sigma_d14c, rep_dC = pv$rep_dC,
                                 grad_off_co2 = pv$grad_off_co2,
                                 grad_off_d13c = pv$grad_off_d13c),
                    luc = ccx_forcing_eluc_annual(F),
                    deep = sp$diagnostics$d14c_bottom_box,
                    ocean_grad = ccx_ocean_grad_scored(o, sp), by_stream = TRUE))
}
s_ref <- try(streams_at(u0), silent = TRUE)
if (inherits(s_ref, "try-error")) {
  cat("  ⚠ per-stream breakdown unavailable from this harness; skipped.\n")
} else {
  cat(sprintf("  %8s", "a_t")); for (n in TA_COST_ROWS) cat(sprintf(" %>10s", substr(n,1,10)))
  cat("\n")
  for (a in TA_INBRACKET) {
    s <- streams_at(u_at(u0, a)); cat(sprintf("  %8.4f", a))
    for (n in TA_COST_ROWS) cat(sprintf(" %+10.2f", s[[n]] - s_ref[[n]])); cat("\n")
  }
}

sep("3. CONDITIONAL -- seas_T_amp_SH FIXED, the rest of the slice re-optimised")
cat(sprintf("  slice (%d free, seas_T_amp_SH REMOVED): %s\n\n", length(TA_COND_BLOCK),
            paste(TA_COND_BLOCK, collapse = ", ")))
idx <- match(TA_COND_BLOCK, CCX_PARAM_NAMES); stopifnot(!anyNA(idx), !(i_at %in% idx))
fit_block <- function(objf, v0) {
  ft <- optim(v0, objf, method = "Nelder-Mead", control = list(maxit = TA_MAXIT, reltol = 1e-12))
  v <- ft$par; best <- ft$value; n_re <- 0; gain <- Inf
  repeat {
    bf <- try(optim(v, objf, method = "BFGS", control = list(maxit = 200, reltol = 1e-12)), silent = TRUE)
    if (!inherits(bf, "try-error") && bf$value < best) { v <- bf$par; best <- bf$value }
    ft <- optim(v, objf, method = "Nelder-Mead", control = list(maxit = TA_MAXIT, reltol = 1e-12))
    gain <- best - ft$value
    if (ft$value < best) { v <- ft$par; best <- ft$value }
    n_re <- n_re + 1
    if (gain < TA_RESTOL || n_re >= TA_RESTARTS) break
  }
  list(par = v, value = best, restarts = n_re, last_gain = gain, converged = gain < TA_RESTOL)
}
cat(sprintf("  %8s | %11s %11s | %9s %8s %11s | %2s %8s\n", "a_t",
            "cond dlp", "frozen dlp", "SH-land", "xobs", "SPO d13/ppm", "re", "lastgain"))
cond <- list(); v_warm <- u0[idx]
for (a in TA_COND) {
  ua <- u_at(u0, a)
  objf <- function(v) { u <- ua; u[idx] <- v; -lp(u) }
  ft <- fit_block(objf, v_warm); v_warm <- ft$par
  u_h <- ua; u_h[idx] <- ft$par; pv <- ccx_unc_to_par(u_h)
  b <- run_at(pv); sl <- amp(b$co2_SPO - run_at(pv, TA_CASES$SH_land)$co2_SPO)
  cond[[sprintf("%.4f", a)]] <- list(a = a, lp = -ft$value, pv = pv, sl = sl,
                                     r = ratio_SPO(b), tot = amp(b$co2_SPO),
                                     converged = ft$converged)
  cat(sprintf("  %8.4f | %+11.2f %+11.2f | %9.4f %8.2f %11.3f | %2d %8.4f%s\n",
              a, -ft$value - one, fro[[sprintf("%.4f", a)]]$lp - one, sl,
              sl / TA_OBS_SPO_LAND, ratio_SPO(b), ft$restarts, ft$last_gain,
              if (!ft$converged) "  ⚠ STILL MOVING" else ""))
}

sep("4. THE PRE-REGISTERED VERDICT")
ref <- cond[[sprintf("%.4f", 1.0391)]]
hi  <- cond[[sprintf("%.4f", TA_HI)]]
cat(sprintf("  P4 -- conditional dlogpost at bracket HI = %+.2f (gate > -20, PREDICTED POSITIVE): %s\n",
            hi$lp - ref$lp, if (hi$lp - ref$lp > -20) "PASS" else "FAIL"))
if (!inherits(s_ref, "try-error")) {
  d_spo <- streams_at(u_at(u0, TA_HI))[["co2_seasonal_SPO"]] - s_ref[["co2_seasonal_SPO"]]
  cat(sprintf("  P5 -- co2_seasonal_SPO frozen delta at bracket HI = %+.2f (gate > 0): %s\n",
              d_spo, if (d_spo > 0) "PASS" else "FAIL"))
}
z_sst <- (log(hi$pv$sst_seas_amp_SH) - log(pv0$sst_seas_amp_SH)) /
         md$sd_unc[[match("sst_seas_amp_SH", CCX_PARAM_NAMES)]]
cat(sprintf("  P6 -- sst_seas_amp_SH %.4f -> %.4f, z %+.2f (gate |z| < 2): %s\n",
            pv0$sst_seas_amp_SH, hi$pv$sst_seas_amp_SH, z_sst,
            if (abs(z_sst) < 2) "PASS" else "FAIL"))
cat(sprintf("  P7 -- SPO d13C/ppm %.3f -> %.3f (gate < 1.85): %s\n",
            ref$r, hi$r, if (hi$r < 1.85) "PASS" else "FAIL"))
cat(sprintf("  P8 -- RESIDUAL AT THE BEST IN-BRACKET POINT: %.4f = %.2fx observed %.3f\n",
            hi$sl, hi$sl / TA_OBS_SPO_LAND, TA_OBS_SPO_LAND))
cat(sprintf("        excess closed: %.1f %% (predicted 68.8 %%)\n",
            100 * (ref$sl - hi$sl) / (ref$sl - TA_OBS_SPO_LAND)))
cat("\n  ⚠ A 'confirmed' verdict that omits P8's residual multiple MISREPORTS this arm.\n")

saveRDS(list(frozen = fro, cond = cond, grid = TA_GRID, pred = TA_PRED,
             bracket = c(TA_LO, TA_HI), landed = pv0$seas_T_amp_SH),
        ccx_path("outputs/diagnostics", "seas_T_amp_sh_power.rds"))
