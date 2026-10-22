# =====================================================================
# diag_seas8_refit_forecast_20261022.R -- T8e: how big an improvement would a FULL refit give with the MLO CO2
# seasonal row scored on Scripps flask CO2 (CCX_SEAS8_CO2SEAS=MLO_SIO_FLASK)? Marcus 2026-10-22: "Evaluate how
# big an improvement we are likely to get from the refit."
#
# WHAT IS KNOWN. T8c on flask CO2 (CHANGELOG 10-21 z) refitted only the 8-name seasonal block: +15.30 log-units
# under the new objective, nearly all on the seasonal rows. A full refit can also move the other 23 names.
#
# METHOD (no refit, no RNG).
#   1. Gradients by central differences at the canonical's own Hessian steps (md$hess_eps), of the OLD (in situ)
#      and NEW (flask) objectives, at the mode and at the block-refit point; the same at 2x the step as a check.
#   2. FORECAST = one Newton step on the canonical's stored Hessian: gain 0.5 g' (-H)^-1 g, move (-H)^-1 g.
#      VALIDATED before it is used: the block-only forecast from the mode must reproduce T8c's MEASURED block gain
#      and move. The full forecast is then made FROM the block-refit point (where the block gradient is ~0), so
#      what it predicts is the increment a full refit adds beyond the block.
#   3. VERIFIED by evaluation: the new objective at the Newton point (steps 1 and 0.5). An evaluated point is a
#      lower bound on what a converged refit reaches (a refit would only climb further).
#   4. WHAT MOVES: every likelihood row and a set of physical outputs (seasonal cycles, levels, gradients, sinks,
#      the PD100 pulse at 20/100/300 yr) at the canonical, the block-refit point and the Newton point.
#
# Usage: Rscript calibration/diag_seas8_refit_forecast_20261022.R > <S8_OUT_DIR>/t8e_refit_forecast_<mode>.log
# =====================================================================
Sys.setenv(CCX_SEAS8_CO2SEAS = "MLO_SIO_FLASK")       # read by the lib at source time
for (.lf in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(.lf)
ccx_load_cpp()
source(file.path("calibration", "lib_seas8_20261021.R"))

S8E_DRIVER <- "calibration/diag_seas8_refit_forecast_20261022.R"
S8E_COMMIT <- ccx_git_stamp()
S8E_T8C    <- file.path(S8_OUT_DIR, "co2flask", sprintf("t8c_split_%s.rds", S8_MODE))
S8E_STEM   <- file.path(S8_OUT_DIR, sprintf("t8e_refit_forecast_%s", S8_MODE))
S8E_STEP_CHECK <- 2          # the gradient is recomputed at this multiple of the step
S8E_NEWTON_STEPS <- c(1, 0.5)
S8E_LARGE_SD <- 2            # a forecast move larger than this (posterior sd) is flagged as outside the quadratic's reach
S8E_SEAS_YEARS <- 1980:2024  # the seasonal readings (the d13C record's span at MLO)
S8E_FLUX_YEARS <- 2014:2023
S8E_GRAD_YEARS <- 2010:2019
S8E_IRF_READ   <- c(20, 100, 300)
say <- function(...) { cat(sprintf(...)); flush.console() }
say("=== %s @%s, %s ===\n", S8E_DRIVER, S8E_COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M"))

S <- s8_setup(S8E_DRIVER)                               # GATE R1 at the canonical, then the flask override
md <- S$md; P <- md$param_names; u0 <- S$u0[P]
if (!identical(names(S$u0), P)) stop("the fitted names are not the mode file's")
lp_new <- S$lp
lp_old <- ccx_make_logpost(obs = ccx_prepare_obs(), base_params = S$bp0, by_stream = TRUE, spinup_fn = S$spf)
d_old <- as.numeric(lp_old(S$u0)) - md$logpost
say("GATE R2: the in situ objective rebuilt here scores the mode %.6f vs stored %.6f (diff %.2e) -> %s\n",
    md$logpost + d_old, md$logpost, d_old, if (abs(d_old) <= CCX_REPRO_TOL) "PASS" else "FAIL")
if (abs(d_old) > CCX_REPRO_TOL) stop("the in situ objective does not reproduce the mode")
negH <- -md$hessian[P, P]; sdU <- md$sd_unc[P]; h0 <- md$hess_eps[P]
T8 <- readRDS(S8E_T8C)
if (!identical(T8$provenance$co2seas, "MLO_SIO_FLASK") || !identical(T8$provenance$mode_md5, S$mode_md5))
  stop(S8E_T8C, " is not the flask T8c at this mode")
B <- T8$block
uB <- u0; uB[B] <- T8$best$B_iii$x[B]
fB <- as.numeric(lp_new(uB)); f0 <- as.numeric(lp_new(S$u0))
say("block-refit point (T8c flask B_iii): new objective %.4f (T8c stored %.4f, diff %.1e); the mode under it %.4f\n",
    fB, T8$best$B_iii$logpost, fB - T8$best$B_iii$logpost, f0)
if (abs(fB - T8$best$B_iii$logpost) > CCX_REPRO_TOL) stop("the block-refit point does not reproduce")

full_u <- function(u) { x <- S$u0; x[P] <- u; x }
grad2 <- function(u, h) {
  g <- matrix(NA_real_, length(P), 2, dimnames = list(P, c("old", "new")))
  for (i in seq_along(P)) {
    up <- u; up[i] <- up[i] + h[i]; dn <- u; dn[i] <- dn[i] - h[i]
    g[i, "old"] <- (as.numeric(lp_old(full_u(up))) - as.numeric(lp_old(full_u(dn)))) / (2 * h[i])
    g[i, "new"] <- (as.numeric(lp_new(full_u(up))) - as.numeric(lp_new(full_u(dn)))) / (2 * h[i])
  }
  g
}
newton <- function(g, idx = P) { du <- stats::setNames(rep(0, length(P)), P)
  du[idx] <- solve(negH[idx, idx], g[idx]); list(du = du, gain = 0.5 * sum(g[idx] * du[idx])) }

say("\n=== 1. GRADIENTS (central differences at md$hess_eps; check at %gx) ===\n", S8E_STEP_CHECK)
G0  <- grad2(u0, h0); G0c <- grad2(u0, S8E_STEP_CHECK * h0)
GB  <- grad2(uB, h0); GBc <- grad2(uB, S8E_STEP_CHECK * h0)
gD0 <- G0[, "new"] - G0[, "old"]                         # the gradient of the change in the objective, at the mode
rel <- function(a, b) max(abs(a - b)) / max(abs(a))
say("  at the mode: |g_old| max %.3f (sd-scaled %.3f) -- the canonical's own residual gradient\n",
    max(abs(G0[, "old"])), max(abs(G0[, "old"] * sdU)))
say("  step check (max |g(h) - g(%gh)| / max |g|): mode old %.3f, mode new %.3f, block point new %.3f\n",
    S8E_STEP_CHECK, rel(G0[, "old"], G0c[, "old"]), rel(G0[, "new"], G0c[, "new"]), rel(GB[, "new"], GBc[, "new"]))
say("  %-21s %10s %10s %10s %10s\n", "name", "g_new@mode", "dg@mode", "g_new@blk", "sd")
for (n in P) say("  %-21s %10.3f %10.3f %10.3f %10.4f%s\n", n, G0[n, "new"], gD0[[n]], GB[n, "new"], sdU[[n]],
                 if (n %in% B) "  [block]" else "")

say("\n=== 2. VALIDATION: the quadratic forecast of the BLOCK refit against T8c's measurement ===\n")
mB <- T8$best$B_iii$x[B] - u0[B]
for (nm in c("dg (change of objective)", "g_new (incl. the canonical's residual)")) {
  g <- if (startsWith(nm, "dg")) gD0 else G0[, "new"]
  fc <- newton(g, B)
  say("  from %s: forecast gain %.2f vs measured %.2f (ratio %.2f); move corr %.3f, max |forecast - measured| %.2f sd\n",
      nm, fc$gain, fB - f0, fc$gain / (fB - f0), stats::cor(fc$du[B], mB), max(abs((fc$du[B] - mB) / sdU[B])))
}
fcB <- newton(gD0, B)
say("  %-17s %9s %9s  (posterior sd)\n", "name", "forecast", "measured")
for (n in B) say("  %-17s %+9.2f %+9.2f\n", n, fcB$du[[n]] / sdU[[n]], mB[[n]] / sdU[[n]])

say("\n=== 3. THE FULL REFIT BEYOND THE BLOCK: one Newton step from the block-refit point ===\n")
fcF <- newton(GB[, "new"], P)
nb <- setdiff(P, B)
fcN <- newton(GB[, "new"], nb)
say("  forecast extra gain: all 31 names %.2f; the 23 non-block names alone %.2f\n", fcF$gain, fcN$gain)
mv <- fcF$du / sdU
say("  largest forecast moves (posterior sd): %s\n",
    paste(sprintf("%s %+.2f", names(sort(abs(mv), decreasing = TRUE))[1:8], mv[names(sort(abs(mv), decreasing = TRUE))[1:8]]), collapse = ", "))
big <- names(mv)[abs(mv) > S8E_LARGE_SD]
say("  moves beyond %g sd: %s\n", S8E_LARGE_SD, if (length(big)) paste(big, collapse = ", ") else "none")
EV <- data.frame(step = S8E_NEWTON_STEPS, forecast = NA_real_, evaluated = NA_real_)
for (k in seq_along(S8E_NEWTON_STEPS)) { s <- S8E_NEWTON_STEPS[k]
  EV$forecast[k]  <- s * (2 - s) * fcF$gain                # the quadratic along the Newton direction
  EV$evaluated[k] <- as.numeric(lp_new(full_u(uB + s * fcF$du))) - fB }
for (k in seq_len(nrow(EV))) say("  step %.1f: forecast %+.2f, EVALUATED %+.2f (new objective, vs the block-refit point)\n",
                                 EV$step[k], EV$forecast[k], EV$evaluated[k])
kbest <- which.max(EV$evaluated)
uN <- uB + EV$step[kbest] * fcF$du
say("  the Newton point used below: step %.1f\n", EV$step[kbest])

say("\n=== 4. EVERY ROW at the canonical, the block-refit point and the Newton point ===\n")
rows_at <- function(lp, u) { v <- lp(full_u(u)); c(unlist(attr(v, "streams")), logprior = attr(v, "logprior")) }
R0 <- rows_at(lp_new, u0); RB <- rows_at(lp_new, uB); RN <- rows_at(lp_new, uN)
R0o <- rows_at(lp_old, u0); RNo <- rows_at(lp_old, uN)
ROWS <- data.frame(row = names(R0), canonical = R0, block = RB, newton = RN, d_block = RB - R0, d_newton = RN - R0,
                   insitu_canonical = R0o[names(R0)], insitu_newton = RNo[names(R0)], row.names = NULL)
ROWS$d_newton_insitu <- ROWS$insitu_newton - ROWS$insitu_canonical
for (i in order(-abs(ROWS$d_newton))) with(ROWS[i, ], if (abs(d_newton) >= 0.05 || abs(d_block) >= 0.05)
  say("  %-24s block %+7.2f | Newton %+7.2f | (in situ objective: Newton %+7.2f)\n", row, d_block, d_newton, d_newton_insitu))
say("  TOTAL (new objective): block %+.2f, Newton %+.2f | (in situ objective at the Newton point %+.2f)\n",
    sum(ROWS$d_block), sum(ROWS$d_newton), sum(ROWS$d_newton_insitu))

say("\n=== 5. PHYSICAL OUTPUTS at the three points ===\n")
load_at <- function(u) {
  nat <- ccx_unc_to_par(full_u(u))
  md2 <- md; for (n in P) md2$par_mode[[n]] <- nat[[n]]
  pm <- ccx_mode_par_with_pins(md2); if (length(ccx_mode_absent(md2))) pm <- ccx_migrate_par_set(pm)
  p <- ccx_overlay_par(ccx_mode_base(md2), pm); p$pump_mode <- md2$pump_mode
  err <- list(sigma_d14c = pm$sigma_d14c, rep_dC = pm$rep_dC, grad_off_co2 = pm$grad_off_co2, grad_off_d13c = pm$grad_off_d13c)
  sh <- ccx_imb_shares(pm); if (!is.null(sh)) { err$imb_share_land <- sh[["land"]]; err$imb_share_ocean <- sh[["ocean"]] }
  list(p = p, luc_scale = pm$luc_scale, bomb_total = pm$bomb_total, err = ccx_err_with_struct(err, p))
}
L0 <- ccx_load_mode(S8_MODE); La <- load_at(u0)
# all.equal, not identical: load_at() DECODES u (as the objective does), and the u -> natural round trip is exact
# only to roundoff against the file's stored par_mode
gl <- isTRUE(all.equal(La$p, L0$p, tolerance = 1e-10)) && isTRUE(all.equal(La$luc_scale, L0$luc_scale, tolerance = 1e-10)) &&
  isTRUE(all.equal(La$bomb_total, L0$bomb_total, tolerance = 1e-10)) && isTRUE(all.equal(La$err, L0$err, tolerance = 1e-10))
say("GATE L: load_at(the mode) is ccx_load_mode() to 1e-10 -> %s\n", if (gl) "PASS" else "FAIL")
if (!gl) stop("load_at() does not reproduce the loader")
obs_f <- S$obs; obs_i <- ccx_prepare_obs()
phys <- function(u) {
  L <- load_at(u); sp <- S$spf(L$p)
  sf <- ccx_scaled_forcing(sp, S8_YEARS, luc_scale = L$luc_scale, bomb_total = L$bomb_total)
  r <- ccx_run_fast(sp, sf$F); ms <- ccx_model_stats(r$out, obs_f)
  ll <- ccx_loglik(r$out, obs_f, L$err, luc = sf$eluc, deep = ccx_d14c_deep_read(sp),
                   ocean_grad = ccx_ocean_grad_scored(r$out, sp), d14c_mid = ccx_model_d14c_slabs(sp),
                   npp = if (isTRUE(L$p$npp_row == 1)) r$npp else NULL, by_stream = TRUE)
  mvec <- function(h) { k <- match(S8E_SEAS_YEARS, h$year); c(mean(h$a[k], na.rm = TRUE), mean(h$b[k], na.rm = TRUE)) }
  out <- list(ll = unlist(ll))
  for (st in S8_STATIONS) {
    vc <- mvec(ms$co2_seas[[st]]); vd <- mvec(ms$d13_seas[[st]])
    out[[paste0("co2_amp_", st)]] <- s8_amp(vc); out[[paste0("co2_peak_", st)]] <- s8_ang_mo(vc)
    out[[paste0("d13_amp_", st)]] <- s8_amp(vd); out[[paste0("d13_peak_", st)]] <- s8_ang_mo(vd)
    out[[paste0("lead_", st)]] <- s8_dmo(s8_ang_mo(vd), s8_ang_mo(-vc))
  }
  hs <- ms$co2_seas$MLO; k <- hs$year %in% S8E_SEAS_YEARS
  out$co2_amp_trend_MLO <- unname(stats::coef(stats::lm(I(2 * sqrt(hs$a[k]^2 + hs$b[k]^2)) ~ hs$year[k]))[2])
  lv <- function(x, st, yrs) { h <- x[[st]]; mean(h$level[h$year %in% yrs]) }
  out$co2_MLO_2024 <- lv(ms$co2, "MLO", 2024)
  out$grad_co2 <- lv(ms$co2, "MLO", S8E_GRAD_YEARS) - lv(ms$co2, "SPO", S8E_GRAD_YEARS)
  out$grad_d13c <- lv(ms$d13, "MLO", S8E_GRAD_YEARS) - lv(ms$d13, "SPO", S8E_GRAD_YEARS)
  fl <- ccx_calendar_flux(r$out); kf <- fl$year %in% S8E_FLUX_YEARS
  out$ocean_flux <- mean(fl$ocean[kf]); out$land_flux <- mean(fl$land[kf])
  o <- ccx_pd100(sp, JOOS_REF_YEAR + max(S8E_IRF_READ) + 10, L$bomb_total, L$luc_scale, climate = CCX_PD_CLIMATE_DEFAULT)
  kk <- o$t >= 0
  for (y in S8E_IRF_READ) out[[sprintf("irf_%d", y)]] <- o$irf[kk][which.min(abs(o$t[kk] - y))]
  out
}
PH <- lapply(list(canonical = u0, block = uB, newton = uN), phys)
chk <- max(abs(PH$canonical$ll[names(R0)[names(R0) != "logprior"]] - R0[names(R0) != "logprior"]))
say("GATE P: phys() at the mode reproduces the new objective's rows to %.1e -> %s\n", chk,
    if (chk <= 1e-6) "PASS" else "FAIL")
if (chk > 1e-6) stop("phys() is not the objective's run")
ovec <- function(h) { k <- h$year %in% S8E_SEAS_YEARS; c(mean(h$a[k]), mean(h$b[k])) }
OB <- list(co2_amp_MLO_insitu = s8_amp(ovec(obs_i$co2_seas$MLO)), co2_peak_MLO_insitu = s8_ang_mo(ovec(obs_i$co2_seas$MLO)),
           co2_amp_MLO_flask = s8_amp(ovec(obs_f$co2_seas$MLO)), co2_peak_MLO_flask = s8_ang_mo(ovec(obs_f$co2_seas$MLO)),
           d13_amp_MLO = s8_amp(ovec(obs_f$d13_seas$MLO)), d13_peak_MLO = s8_ang_mo(ovec(obs_f$d13_seas$MLO)))
say("  observed MLO %d-%d: CO2 in situ %.3f ppm @ %.2f mo, flask %.3f @ %.2f; d13C %.4f permil @ %.2f\n",
    min(S8E_SEAS_YEARS), max(S8E_SEAS_YEARS), OB$co2_amp_MLO_insitu, OB$co2_peak_MLO_insitu, OB$co2_amp_MLO_flask,
    OB$co2_peak_MLO_flask, OB$d13_amp_MLO, OB$d13_peak_MLO)
QN <- setdiff(names(PH$canonical), "ll")
say("  %-18s %11s %11s %11s %11s\n", "quantity", "canonical", "block", "newton", "newton-can")
for (q in QN) say("  %-18s %11.4f %11.4f %11.4f %+11.4f\n", q, PH$canonical[[q]], PH$block[[q]], PH$newton[[q]],
                  PH$newton[[q]] - PH$canonical[[q]])

saveRDS(list(grad = list(mode = G0, mode_check = G0c, block = GB, block_check = GBc, dg_mode = gD0),
             block_forecast = list(du = fcB$du, gain = fcB$gain, measured_du = mB, measured_gain = fB - f0),
             full_forecast = list(du = fcF$du, gain = fcF$gain, gain_nonblock = fcN$gain, evaluated = EV,
                                  step_used = EV$step[kbest]),
             points = list(u0 = u0, uB = uB, uN = uN), rows = ROWS, phys = PH, obs = OB,
             provenance = list(driver = S8E_DRIVER, commit = S8E_COMMIT, lib = "calibration/lib_seas8_20261021.R",
                               mode = S8_MODE, mode_file = S$mode_file, mode_md5 = S$mode_md5, co2seas = S$co2seas,
                               t8c = S8E_T8C, t8c_commit = T8$provenance$commit, step = "md$hess_eps",
                               step_check = S8E_STEP_CHECK, newton_steps = S8E_NEWTON_STEPS,
                               seas_years = range(S8E_SEAS_YEARS), flux_years = range(S8E_FLUX_YEARS),
                               grad_years = range(S8E_GRAD_YEARS), irf_read = S8E_IRF_READ,
                               pd_climate = CCX_PD_CLIMATE_DEFAULT, rng = "none",
                               units = "log-units; u-space and posterior sd; ppm; permil; months; GtC/yr; IRF fraction",
                               built = format(Sys.time(), "%Y-%m-%d %H:%M"))),
        paste0(S8E_STEM, ".rds"))
say("\nwrote %s.rds\n=== DONE ===\n", S8E_STEM)
