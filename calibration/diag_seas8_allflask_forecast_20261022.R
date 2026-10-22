# =====================================================================
# diag_seas8_allflask_forecast_20261022.R -- T8f: what would it cost, and what would move, if EVERY Mauna Loa CO2
# row scored Scripps flask CO2 (the same flasks as the d13C rows), not only the seasonal row?
# Marcus 2026-10-22, on the scope question: "Price all-flask first (Recommended)".
#
# THE THREE OBJECTIVES (same parameters, same model; only the MLO CO2 data differ):
#   insitu   the canonical's: every MLO CO2 row on Scripps in situ
#   seas     T8e's: co2_seasonal_MLO on Scripps flask; level and gradient in situ (CCX_SEAS8_CO2SEAS)
#   all      this driver's: co2_seasonal_MLO, co2_level_MLO and co2_gradient on Scripps flask (+ CCX_SEAS8_CO2LEVEL)
#
# METHOD (no refit, no RNG), T8e's, which was validated there against T8c's measured block refit:
#   1. the data: the years each row scores under each series, and the flask minus in situ level offset by period;
#   2. every row at the canonical under the three objectives (what the switch costs before any refit);
#   3. gradients of `all` by central differences at md$hess_eps (check at 2x), at the mode and at T8c's block-refit
#      point; `seas` recomputed at the block point too, which must reproduce T8e's stored gradient (GATE T);
#   4. one Newton step on the canonical's stored Hessian over all 31 names, from the mode and from the block point,
#      EVALUATED at steps 1 and 0.5 (an evaluated point is a lower bound on what a converged refit reaches);
#   5. every row and the physical outputs at the canonical, T8e's Newton point (seas) and this Newton point (all).
#
# Usage: Rscript calibration/diag_seas8_allflask_forecast_20261022.R > <S8_OUT_DIR>/t8f_allflask_forecast_<mode>.log
# =====================================================================
Sys.setenv(CCX_SEAS8_CO2SEAS = "MLO_SIO_FLASK", CCX_SEAS8_CO2LEVEL = "MLO_SIO_FLASK")   # read by the lib at source time
for (.lf in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(.lf)
ccx_load_cpp()
source(file.path("calibration", "lib_seas8_20261021.R"))

S8F_DRIVER <- "calibration/diag_seas8_allflask_forecast_20261022.R"
S8F_COMMIT <- ccx_git_stamp()
S8F_T8C    <- file.path(S8_OUT_DIR, "co2flask", sprintf("t8c_split_%s.rds", S8_MODE))
S8F_T8E    <- file.path(S8_OUT_DIR, sprintf("t8e_refit_forecast_%s.rds", S8_MODE))
S8F_STEM   <- file.path(S8_OUT_DIR, sprintf("t8f_allflask_forecast_%s", S8_MODE))
S8F_STEP_CHECK   <- 2
S8F_NEWTON_STEPS <- c(1, 0.5)
S8F_LARGE_SD     <- 2          # a forecast move beyond this (posterior sd) is flagged as outside the quadratic's reach
S8F_GATE_T_TOL   <- 1e-8       # GATE T: the seas gradient recomputed here vs T8e's stored one (same code, same points)
S8F_OFFSET_PERIODS <- list(c(1959, 1979), c(1980, 1999), c(2000, 2024))
S8F_SEAS_YEARS <- 1980:2024    # T8e's readings, so the two Newton points are read alike
S8F_FLUX_YEARS <- 2014:2023
S8F_GRAD_YEARS <- 2010:2019
S8F_IRF_READ   <- c(20, 100, 300)
S8F_LEVEL_ROWS <- c("co2_level_MLO", "co2_gradient", "co2_seasonal_MLO")
say <- function(...) { cat(sprintf(...)); flush.console() }
say("=== %s @%s, %s ===\n", S8F_DRIVER, S8F_COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M"))

S <- s8_setup(S8F_DRIVER)                         # GATE R1 at the canonical, then both overrides (GATE G inside)
md <- S$md; P <- md$param_names; u0 <- S$u0[P]
if (!identical(names(S$u0), P)) stop("the fitted names are not the mode file's")
obs_i <- ccx_prepare_obs(); obs_s <- s8_obs(level = FALSE); obs_a <- S$obs
mk <- function(o) ccx_make_logpost(obs = o, base_params = S$bp0, by_stream = TRUE, spinup_fn = S$spf)
LP <- list(insitu = mk(obs_i), seas = mk(obs_s), all = S$lp)
d_old <- as.numeric(LP$insitu(S$u0)) - md$logpost
say("GATE R2: the in situ objective rebuilt here scores the mode %.6f vs stored %.6f (diff %.2e) -> %s\n",
    md$logpost + d_old, md$logpost, d_old, if (abs(d_old) <= CCX_REPRO_TOL) "PASS" else "FAIL")
if (abs(d_old) > CCX_REPRO_TOL) stop("the in situ objective does not reproduce the mode")
T8E <- readRDS(S8F_T8E)
if (!identical(T8E$provenance$mode_md5, S$mode_md5) || !identical(T8E$provenance$co2seas, "MLO_SIO_FLASK"))
  stop(S8F_T8E, " is not T8e at this mode")
f_seas_e <- sum(T8E$rows$canonical)
d_seas <- as.numeric(LP$seas(S$u0)) - f_seas_e
say("GATE R3: the seas objective scores the mode %.6f vs T8e's recorded %.6f (diff %.2e) -> %s\n",
    f_seas_e + d_seas, f_seas_e, d_seas, if (abs(d_seas) <= CCX_REPRO_TOL) "PASS" else "FAIL")
if (abs(d_seas) > CCX_REPRO_TOL) stop("the seas objective is not T8e's")
negH <- -md$hessian[P, P]; sdU <- md$sd_unc[P]; h0 <- md$hess_eps[P]
T8 <- readRDS(S8F_T8C)
if (!identical(T8$provenance$co2seas, "MLO_SIO_FLASK") || !identical(T8$provenance$mode_md5, S$mode_md5))
  stop(S8F_T8C, " is not the flask T8c at this mode")
B <- T8$block
uB <- u0; uB[B] <- T8$best$B_iii$x[B]
if (!isTRUE(all.equal(uB, T8E$points$uB, tolerance = 0))) stop("the block-refit point is not T8e's")
uNs <- T8E$points$uN                              # T8e's Newton point (the seas refit forecast)

say("\n=== 1. THE DATA: which years each MLO CO2 row scores ===\n")
for (nm in c("insitu", "all")) { o <- if (nm == "insitu") obs_i else obs_a
  say("  %-6s co2_level_MLO %d years %d-%d; co2_gradient %d years %d-%d; co2_seasonal_MLO %d years %d-%d\n", nm,
      nrow(o$co2_ann$MLO), min(o$co2_ann$MLO$year), max(o$co2_ann$MLO$year), nrow(o$co2_grad), min(o$co2_grad$year),
      max(o$co2_grad$year), o$co2_seas$MLO$n_years, min(o$co2_seas$MLO$year), max(o$co2_seas$MLO$year)) }
lost <- setdiff(obs_i$co2_ann$MLO$year, obs_a$co2_ann$MLO$year)
say("  level years in situ has and flask lacks (fewer than %d months): %s\n", LIK_ANNUAL_MIN_MONTHS, paste(lost, collapse = " "))
jl <- merge(obs_i$co2_ann$MLO[, c("year", "level")], obs_a$co2_ann$MLO[, c("year", "level")], by = "year",
            suffixes = c("_i", "_f"))
OFF <- do.call(rbind, lapply(S8F_OFFSET_PERIODS, function(w) { k <- jl$year >= w[1] & jl$year <= w[2]
  d <- jl$level_f[k] - jl$level_i[k]; data.frame(from = w[1], to = w[2], n = sum(k), mean = mean(d), sd = stats::sd(d)) }))
for (i in seq_len(nrow(OFF))) with(OFF[i, ], say("  flask - in situ annual level %d-%d: %+.3f ppm (sd %.3f, n %d)\n",
                                                 from, to, mean, sd, n))
tr <- stats::coef(stats::lm(I(level_f - level_i) ~ year, data = jl))[2]
say("  its trend %+.4f ppm/yr; the rows' sigmas: LIK_CO2_REP_ERR %.2f ppm, LIK_GRAD_CO2_SD %.2f ppm (unchanged)\n",
    tr, LIK_CO2_REP_ERR, LIK_GRAD_CO2_SD)

full_u <- function(u) { x <- S$u0; x[P] <- u; x }
rows_at <- function(lp, u) { v <- lp(full_u(u)); c(unlist(attr(v, "streams")), logprior = attr(v, "logprior")) }
say("\n=== 2. EVERY ROW AT THE CANONICAL under the three objectives (before any refit) ===\n")
R0 <- lapply(LP, rows_at, u = u0)
for (r in names(R0$insitu)) if (abs(R0$all[[r]] - R0$insitu[[r]]) >= 1e-9)
  say("  %-20s insitu %9.3f | seas %9.3f (%+7.3f) | all %9.3f (%+7.3f)\n", r, R0$insitu[[r]], R0$seas[[r]],
      R0$seas[[r]] - R0$insitu[[r]], R0$all[[r]], R0$all[[r]] - R0$insitu[[r]])
say("  TOTAL: insitu %.4f | seas %.4f | all %.4f\n", sum(R0$insitu), sum(R0$seas), sum(R0$all))
moved <- names(R0$all)[abs(R0$all - R0$seas) >= 1e-9]
say("  rows that differ between all and seas: %s\n", paste(moved, collapse = ", "))
if (!all(moved %in% S8F_LEVEL_ROWS)) stop("the level override moved a row it should not touch")

grad1 <- function(lp, u, h) {
  g <- stats::setNames(numeric(length(P)), P)
  for (i in seq_along(P)) {
    up <- u; up[i] <- up[i] + h[i]; dn <- u; dn[i] <- dn[i] - h[i]
    g[i] <- (as.numeric(lp(full_u(up))) - as.numeric(lp(full_u(dn)))) / (2 * h[i])
  }
  g
}
newton <- function(g, idx = P) { du <- stats::setNames(rep(0, length(P)), P)
  du[idx] <- solve(negH[idx, idx], g[idx]); list(du = du, gain = 0.5 * sum(g[idx] * du[idx])) }
rel <- function(a, b) max(abs(a - b)) / max(abs(a))

say("\n=== 3. GRADIENTS (central differences at md$hess_eps; check at %gx) ===\n", S8F_STEP_CHECK)
GsB <- grad1(LP$seas, uB, h0)
gt <- max(abs(GsB - T8E$grad$block[P, "new"]))
say("GATE T: the seas gradient at the block point vs T8e's stored one: max |diff| %.2e (tol %g) -> %s\n", gt,
    S8F_GATE_T_TOL, if (gt <= S8F_GATE_T_TOL) "PASS" else "FAIL")
if (gt > S8F_GATE_T_TOL) stop("the seas gradient does not reproduce T8e's")
Ga0 <- grad1(LP$all, u0, h0); Ga0c <- grad1(LP$all, u0, S8F_STEP_CHECK * h0)
GaB <- grad1(LP$all, uB, h0); GaBc <- grad1(LP$all, uB, S8F_STEP_CHECK * h0)
say("  step check (max |g(h) - g(%gh)| / max |g|): all@mode %.3f, all@block %.3f\n", S8F_STEP_CHECK,
    rel(Ga0, Ga0c), rel(GaB, GaBc))
say("  %-21s %10s %10s %10s %10s\n", "name", "g_all@mode", "g_seas@mode", "g_all@blk", "sd")
for (n in P) say("  %-21s %10.3f %10.3f %10.3f %10.4f%s\n", n, Ga0[[n]], T8E$grad$mode[n, "new"], GaB[[n]], sdU[[n]],
                 if (n %in% B) "  [block]" else "")

say("\n=== 4. NEWTON FORECASTS over all 31 names (the all objective) ===\n")
EVAL <- list()
for (from in c("mode", "block")) {
  ub <- if (from == "mode") u0 else uB; g <- if (from == "mode") Ga0 else GaB
  fc <- newton(g, P); fb <- as.numeric(LP$all(full_u(ub)))
  ev <- data.frame(step = S8F_NEWTON_STEPS, forecast = S8F_NEWTON_STEPS * (2 - S8F_NEWTON_STEPS) * fc$gain,
                   evaluated = vapply(S8F_NEWTON_STEPS, function(s) as.numeric(LP$all(full_u(ub + s * fc$du))) - fb, 0))
  mv <- fc$du / sdU; o <- names(sort(abs(mv), decreasing = TRUE))
  say("  from the %s (all objective there %.4f; %+.3f vs the mode): forecast gain %+.2f\n", from, fb,
      fb - as.numeric(LP$all(S$u0)), fc$gain)
  for (k in seq_len(nrow(ev))) say("    step %.1f: forecast %+.2f, EVALUATED %+.2f\n", ev$step[k], ev$forecast[k], ev$evaluated[k])
  say("    largest moves (posterior sd): %s\n", paste(sprintf("%s %+.2f", o[1:8], mv[o[1:8]]), collapse = ", "))
  big <- names(mv)[abs(mv) > S8F_LARGE_SD]
  say("    moves beyond %g sd: %s\n", S8F_LARGE_SD, if (length(big)) paste(big, collapse = ", ") else "none")
  kb <- which.max(ev$evaluated)
  EVAL[[from]] <- list(du = fc$du, gain = fc$gain, evaluated = ev, base = fb, step_used = ev$step[kb],
                       u = ub + ev$step[kb] * fc$du, total = fb - as.numeric(LP$all(S$u0)) + ev$evaluated[kb])
}
pick <- if (EVAL$block$total >= EVAL$mode$total) "block" else "mode"
uNa <- EVAL[[pick]]$u
say("  the all-flask Newton point used below: from the %s, step %.1f; total gain over the mode %+.2f (from the mode: %+.2f)\n",
    pick, EVAL[[pick]]$step_used, EVAL[[pick]]$total, EVAL$mode$total)
dA <- (uNa - uNs) / sdU; o <- names(sort(abs(dA), decreasing = TRUE))
say("  all-flask Newton point minus T8e's (seas) Newton point, posterior sd: %s\n",
    paste(sprintf("%s %+.2f", o[1:8], dA[o[1:8]]), collapse = ", "))

say("\n=== 5. EVERY ROW at the canonical, T8e's Newton point (seas) and this one (all), on each objective ===\n")
RS <- lapply(LP, rows_at, u = uNs); RA <- lapply(LP, rows_at, u = uNa)
ROWS <- data.frame(row = names(R0$all), all_canonical = R0$all, all_at_seasN = RS$all, all_at_allN = RA$all,
                   insitu_canonical = R0$insitu, insitu_at_seasN = RS$insitu, insitu_at_allN = RA$insitu,
                   seas_canonical = R0$seas, seas_at_seasN = RS$seas, seas_at_allN = RA$seas, row.names = NULL)
for (i in order(-abs(ROWS$all_at_allN - ROWS$all_canonical))) with(ROWS[i, ],
  if (max(abs(c(all_at_allN - all_canonical, all_at_seasN - all_canonical, insitu_at_allN - insitu_canonical))) >= 0.05)
    say("  %-22s all objective: seasN %+7.2f allN %+7.2f | in situ objective: seasN %+7.2f allN %+7.2f\n", row,
        all_at_seasN - all_canonical, all_at_allN - all_canonical, insitu_at_seasN - insitu_canonical,
        insitu_at_allN - insitu_canonical))
for (ob in c("all", "seas", "insitu")) say("  TOTAL on the %-6s objective: canonical %.3f | seasN %+.2f | allN %+.2f\n", ob,
                                           sum(ROWS[[paste0(ob, "_canonical")]]),
                                           sum(ROWS[[paste0(ob, "_at_seasN")]]) - sum(ROWS[[paste0(ob, "_canonical")]]),
                                           sum(ROWS[[paste0(ob, "_at_allN")]]) - sum(ROWS[[paste0(ob, "_canonical")]]))

say("\n=== 6. PHYSICAL OUTPUTS at the three points ===\n")
load_at <- function(u) {
  nat <- ccx_unc_to_par(full_u(u))
  md2 <- md; for (n in P) md2$par_mode[[n]] <- nat[[n]]
  pm <- ccx_mode_par_with_pins(md2); if (length(ccx_mode_absent(md2))) pm <- ccx_migrate_par_set(pm)
  p <- ccx_overlay_par(ccx_mode_base(md2), pm); p$pump_mode <- md2$pump_mode
  err <- list(sigma_d14c = pm$sigma_d14c, rep_dC = pm$rep_dC, grad_off_co2 = pm$grad_off_co2, grad_off_d13c = pm$grad_off_d13c)
  sh <- ccx_imb_shares(pm); if (!is.null(sh)) { err$imb_share_land <- sh[["land"]]; err$imb_share_ocean <- sh[["ocean"]] }
  list(p = p, pm = pm, luc_scale = pm$luc_scale, bomb_total = pm$bomb_total, err = ccx_err_with_struct(err, p))
}
L0 <- ccx_load_mode(S8_MODE); La <- load_at(u0)
gl <- isTRUE(all.equal(La$p, L0$p, tolerance = 1e-10)) && isTRUE(all.equal(La$luc_scale, L0$luc_scale, tolerance = 1e-10)) &&
  isTRUE(all.equal(La$bomb_total, L0$bomb_total, tolerance = 1e-10)) && isTRUE(all.equal(La$err, L0$err, tolerance = 1e-10))
say("GATE L: load_at(the mode) is ccx_load_mode() to 1e-10 -> %s\n", if (gl) "PASS" else "FAIL")
if (!gl) stop("load_at() does not reproduce the loader")
phys <- function(u) {
  L <- load_at(u); sp <- S$spf(L$p)
  sf <- ccx_scaled_forcing(sp, S8_YEARS, luc_scale = L$luc_scale, bomb_total = L$bomb_total)
  r <- ccx_run_fast(sp, sf$F); ms <- ccx_model_stats(r$out, obs_a)
  ll <- ccx_loglik(r$out, obs_a, L$err, luc = sf$eluc, deep = ccx_d14c_deep_read(sp),
                   ocean_grad = ccx_ocean_grad_scored(r$out, sp), d14c_mid = ccx_model_d14c_slabs(sp),
                   npp = if (isTRUE(L$p$npp_row == 1)) r$npp else NULL, by_stream = TRUE)
  mvec <- function(h) { k <- match(S8F_SEAS_YEARS, h$year); c(mean(h$a[k], na.rm = TRUE), mean(h$b[k], na.rm = TRUE)) }
  out <- list(ll = unlist(ll))
  for (st in S8_STATIONS) {
    vc <- mvec(ms$co2_seas[[st]]); vd <- mvec(ms$d13_seas[[st]])
    out[[paste0("co2_amp_", st)]] <- s8_amp(vc); out[[paste0("co2_peak_", st)]] <- s8_ang_mo(vc)
    out[[paste0("d13_amp_", st)]] <- s8_amp(vd); out[[paste0("d13_peak_", st)]] <- s8_ang_mo(vd)
    out[[paste0("lead_", st)]] <- s8_dmo(s8_ang_mo(vd), s8_ang_mo(-vc))
  }
  lv <- function(x, st, yrs) { h <- x[[st]]; mean(h$level[h$year %in% yrs]) }
  out$co2_MLO_2024 <- lv(ms$co2, "MLO", 2024) - L$err$rep_dC
  out$grad_co2 <- lv(ms$co2, "MLO", S8F_GRAD_YEARS) - lv(ms$co2, "SPO", S8F_GRAD_YEARS)
  out$grad_d13c <- lv(ms$d13, "MLO", S8F_GRAD_YEARS) - lv(ms$d13, "SPO", S8F_GRAD_YEARS)
  out$rep_dC <- L$err$rep_dC; out$grad_off_co2 <- L$err$grad_off_co2
  fl <- ccx_calendar_flux(r$out); kf <- fl$year %in% S8F_FLUX_YEARS
  out$ocean_flux <- mean(fl$ocean[kf]); out$land_flux <- mean(fl$land[kf])
  o <- ccx_pd100(sp, JOOS_REF_YEAR + max(S8F_IRF_READ) + 10, L$bomb_total, L$luc_scale, climate = CCX_PD_CLIMATE_DEFAULT)
  kk <- o$t >= 0
  for (y in S8F_IRF_READ) out[[sprintf("irf_%d", y)]] <- o$irf[kk][which.min(abs(o$t[kk] - y))]
  out
}
PH <- lapply(list(canonical = u0, seasN = uNs, allN = uNa), phys)
nr <- setdiff(names(R0$all), "logprior")
chk <- max(abs(PH$canonical$ll[nr] - R0$all[nr]))
say("GATE P: phys() at the mode reproduces the all objective's rows to %.1e -> %s\n", chk, if (chk <= 1e-6) "PASS" else "FAIL")
if (chk > 1e-6) stop("phys() is not the objective's run")
QN <- setdiff(names(PH$canonical), "ll")
say("  %-18s %11s %11s %11s %11s %11s\n", "quantity", "canonical", "seasN", "allN", "seasN-can", "allN-can")
for (q in QN) say("  %-18s %11.4f %11.4f %11.4f %+11.4f %+11.4f\n", q, PH$canonical[[q]], PH$seasN[[q]], PH$allN[[q]],
                  PH$seasN[[q]] - PH$canonical[[q]], PH$allN[[q]] - PH$canonical[[q]])
og <- function(o, yrs) mean(o$co2_grad$grad[o$co2_grad$year %in% yrs])
say("  observed CO2 gradient %d-%d: in situ MLO %.3f ppm, flask MLO %.3f ppm (each minus SPO; the model adds grad_off_co2)\n",
    min(S8F_GRAD_YEARS), max(S8F_GRAD_YEARS), og(obs_i, S8F_GRAD_YEARS), og(obs_a, S8F_GRAD_YEARS))

saveRDS(list(data = list(lost_level_years = lost, offset = OFF, offset_trend = unname(tr)),
             rows_canonical = R0, grad = list(all_mode = Ga0, all_mode_check = Ga0c, all_block = GaB,
                                              all_block_check = GaBc, seas_block = GsB),
             forecast = EVAL, pick = pick, points = list(u0 = u0, uB = uB, uN_seas = uNs, uN_all = uNa),
             rows = ROWS, phys = PH,
             provenance = list(driver = S8F_DRIVER, commit = S8F_COMMIT, lib = "calibration/lib_seas8_20261021.R",
                               mode = S8_MODE, mode_file = S$mode_file, mode_md5 = S$mode_md5, co2seas = S$co2seas,
                               co2level = S$co2level, t8c = S8F_T8C, t8e = S8F_T8E, t8e_commit = T8E$provenance$commit,
                               step = "md$hess_eps", step_check = S8F_STEP_CHECK, newton_steps = S8F_NEWTON_STEPS,
                               seas_years = range(S8F_SEAS_YEARS), flux_years = range(S8F_FLUX_YEARS),
                               grad_years = range(S8F_GRAD_YEARS), irf_read = S8F_IRF_READ,
                               pd_climate = CCX_PD_CLIMATE_DEFAULT, rng = "none",
                               units = "log-units; u-space and posterior sd; ppm; permil; months; GtC/yr; IRF fraction",
                               built = format(Sys.time(), "%Y-%m-%d %H:%M"))),
        paste0(S8F_STEM, ".rds"))
say("\nwrote %s.rds\n=== DONE ===\n", S8F_STEM)
