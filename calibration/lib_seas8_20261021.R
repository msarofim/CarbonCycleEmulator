# =====================================================================
# lib_seas8_20261021.R -- shared set-up for the seas8 diagnostics (T8a/T8b/T8c,
# 2026-10-21): the canonical's objective, gated, and a run function that returns
# the scored seasonal VECTORS and the by-stream likelihood of one run.
#
# WHY (2026-10-21). The app's "What pins down what?" tab says the CO2 and d13C
# seasonal cycles disagree because "the model's seasonal cycle is the sum of land
# plants which have a strong 13C fingerprint, and the surface ocean without a
# fingerprint ... and the fit splits the difference". Marcus challenged it: real
# observations fit both tracers, so the misfit must come from how THIS model
# sizes, times or signs a channel. These drivers MEASURE; they defend nothing.
#
# WHAT IT REUSES. The objective is run_price_profile.R's harness (gate, pins,
# bands, structure, spin-up from the mode file's own record), and the run path is
# ccx_make_logpost()'s own sequence (ccx_load_mode() -> the file's spinup ->
# ccx_scaled_forcing() -> ccx_run_fast() -> ccx_loglik() with the objective's
# arguments). GATE R0: the run path's by-stream likelihood at the mode must equal
# the mode file's stored streams row by row (CCX_REPRO_TOL), so a knockout is
# always measured against the model the canonical IS -- including the fitted
# seasonal values actually reaching the run (the ent_seas_amp_SH clobber class).
# =====================================================================

S8_MODE      <- CCX_MODE_CANONICAL
S8_YEARS     <- c(1750, 2024)          # the objective's span (ccx_make_logpost default)
S8_WINDOW    <- LIK_SEAS_WINDOW        # the seasonal rows' window
S8_STATIONS  <- c("MLO", "SPO")
S8_SEAS_ROWS <- list(co2 = c("co2_seasonal_MLO", "co2_seasonal_SPO"),
                     d13 = c("d13c_seasonal_MLO", "d13c_seasonal_SPO"))
S8_OUT_DIR   <- Sys.getenv("CCX_SEAS8_OUT",
                           file.path("outputs", "diagnostics",
                                     sprintf("seas8_20261021_%s", CCX_MODE_CANONICAL)))
# The T8c screen (block, row sets, scales, quadratic starts) is read from here; an override run reuses the
# canonical-epsilon screen rather than rebuilding it.
S8_SCREEN_DIR <- Sys.getenv("CCX_SEAS8_SCREEN_DIR", S8_OUT_DIR)
# 2026-10-21 (Marcus: "Run the ε test first"): CCX_SEAS8_EPS holds alpha_photo_eps at a stated value (permil)
# in every run AFTER GATE R1 has passed at the canonical's own value. NA = unset = the canonical's own (16.2).
# T8b's probe put the MLO station d13C-per-ppm on the observed value at 18.35.
S8_EPS <- suppressWarnings(as.numeric(Sys.getenv("CCX_SEAS8_EPS", "")))
# 2026-10-21 (T8d, CHANGELOG x; Marcus: "Measure first"): CCX_SEAS8_CO2SEAS names the monthly CO2 series that the
# MLO CO2 SEASONAL row scores, in place of the canonical's Scripps in situ. "MLO_SIO_FLASK" = Scripps flask CO2, the
# same flasks the d13C row scores (T8d: flask CO2's phase runs 2.2 d ahead of in situ). Only obs$co2_seas$MLO changes,
# coefficients and sigma both, by the row's own rule (ccx_year_harmonic -> ccx_seasonal_target); the level, gradient
# and every other row keep the in situ record. Applied, like CCX_SEAS8_EPS, only AFTER GATE R1. "" = unset.
S8_CO2SEAS <- Sys.getenv("CCX_SEAS8_CO2SEAS", "")
if (!S8_CO2SEAS %in% c("", "MLO_SIO_FLASK")) stop("CCX_SEAS8_CO2SEAS must be unset or MLO_SIO_FLASK, not ", S8_CO2SEAS)
# 2026-10-22 (T8f; Marcus: "Price all-flask first"): CCX_SEAS8_CO2LEVEL moves the MLO CO2 LEVEL row and the CO2
# GRADIENT row to the same series, so every MLO CO2 row scores it: obs$co2_ann$MLO is the series' per-year harmonics
# (the seasonal target is built from the same harmonics, as in ccx_prepare_obs()), and obs$co2_grad is that level
# minus SPO's, by ccx_prepare_obs()'s own pairing rule. The rows' sigmas are constants (LIK_CO2_REP_ERR,
# LIK_GRAD_CO2_SD) and do not change. It requires CCX_SEAS8_CO2SEAS set to the same series. "" = unset.
S8_CO2LEVEL <- Sys.getenv("CCX_SEAS8_CO2LEVEL", "")
if (!S8_CO2LEVEL %in% c("", "MLO_SIO_FLASK")) stop("CCX_SEAS8_CO2LEVEL must be unset or MLO_SIO_FLASK, not ", S8_CO2LEVEL)
if (nzchar(S8_CO2LEVEL) && !identical(S8_CO2LEVEL, S8_CO2SEAS))
  stop("CCX_SEAS8_CO2LEVEL needs CCX_SEAS8_CO2SEAS set to the same series (", S8_CO2LEVEL, ")")
s8_override <- function() is.finite(S8_EPS) || nzchar(S8_CO2SEAS) || nzchar(S8_CO2LEVEL)

#' ccx_prepare_obs()'s gradient pairing (its local ccx_pair_grad()), restated so an override can rebuild the row.
#' GATE G (s8_setup) holds it to ccx_prepare_obs()'s own co2_grad, exactly.
s8_pair_grad <- function(a, b) {
  m <- merge(a[, c("year", "level")], b[, c("year", "level")], by = "year", suffixes = c("_n", "_s"))
  data.frame(year = m$year, grad = m$level_n - m$level_s)
}

#' The observations every seas8 run scores: ccx_prepare_obs(), with the CO2SEAS override applied when set and,
#' when `level` is TRUE, the CO2LEVEL override too.
s8_obs <- function(level = TRUE) {
  obs <- ccx_prepare_obs()
  if (nzchar(S8_CO2SEAS)) {
    co2 <- as.data.frame(readRDS(ccx_path("data", "obs_co2_monthly.rds")))
    o <- co2[co2$station == S8_CO2SEAS, ]
    if (!nrow(o)) stop("no monthly CO2 rows for station ", S8_CO2SEAS)
    h <- ccx_year_harmonic(o$decimal_date, o$co2_ppm)
    obs$co2_seas$MLO <- ccx_seasonal_target(h)
    if (level && nzchar(S8_CO2LEVEL)) {
      obs$co2_ann$MLO <- h
      obs$co2_grad <- s8_pair_grad(h, obs$co2_ann$SPO)
    }
  }
  obs
}

s8_amp    <- function(v) 2 * sqrt(sum(v^2))                        # PEAK-TO-PEAK, always
s8_ang_mo <- function(v) 12 * ((atan2(v[1], v[2]) / (2 * pi)) %% 1)
s8_dmo    <- function(a, b) ((a - b + 6) %% 12) - 6                 # signed, wrapped, months
s8_vec    <- function(amp, mo) { th <- 2 * pi * mo / 12; c(amp / 2 * sin(th), amp / 2 * cos(th)) }

#' The canonical objective, gated. Returns the pieces every seas8 driver needs.
s8_setup <- function(who) {
  md <- readRDS(ccx_mode_file(S8_MODE))
  invisible(ccx_apply_gate(ccx_mode_struct(md)))
  pins <- ccx_mode_pins(md)
  invisible(ccx_apply_pins(pins))
  ccx_require_param_set(md, who)
  invisible(ccx_adopt_mode_band(md))
  ccx_check_mode_decode(md)
  spf <- ccx_spinup_from_label(ccx_mode_spinup(md))
  bp0 <- ccx_mode_base(md); if (!is.null(md$pump_mode)) bp0$pump_mode <- md$pump_mode
  lp  <- ccx_make_logpost(base_params = bp0, by_stream = TRUE, spinup_fn = spf)
  u0  <- unlist(ccx_par_to_unc(md$par_mode[CCX_PARAM_NAMES]))[CCX_PARAM_NAMES]
  v0  <- lp(u0)
  d   <- as.numeric(v0) - md$logpost
  cat(sprintf("GATE R1 (%s): canonical logpost %.6f vs stored %.6f (diff %.2e, tol %g) -> %s\n",
              S8_MODE, as.numeric(v0), md$logpost, d, CCX_REPRO_TOL,
              if (abs(d) <= CCX_REPRO_TOL) "PASS" else "FAIL"))
  if (!(abs(d) <= CCX_REPRO_TOL)) stop("the canonical objective does not reproduce its mode")
  eps <- bp0$alpha_photo_eps
  if (is.finite(S8_EPS)) {
    bp0$alpha_photo_eps <- S8_EPS
    lp <- ccx_make_logpost(base_params = bp0, by_stream = TRUE, spinup_fn = spf)
    v0 <- lp(u0)
    cat(sprintf("EPS OVERRIDE (CCX_SEAS8_EPS): alpha_photo_eps %.2f -> %.2f permil; the mode's values now score logpost %.6f (%+.3f vs the canonical)\n",
                eps, S8_EPS, as.numeric(v0), as.numeric(v0) - md$logpost))
    if (abs(as.numeric(v0) - md$logpost) <= CCX_REPRO_TOL) stop("the epsilon override did not reach the objective")
    eps <- S8_EPS
  }
  obs <- s8_obs(level = FALSE)
  if (nzchar(S8_CO2SEAS)) {
    o0 <- ccx_prepare_obs()$co2_seas$MLO; o1 <- obs$co2_seas$MLO
    lp <- ccx_make_logpost(obs = obs, base_params = bp0, by_stream = TRUE, spinup_fn = spf)
    v1 <- lp(u0)
    cat(sprintf(paste0("CO2SEAS OVERRIDE (CCX_SEAS8_CO2SEAS): co2_seasonal_MLO scores %s, %d years %d-%d, sd_a %.4f sd_b %.4f ppm",
                       " (in situ: %d years, sd_a %.4f sd_b %.4f); the mode's values now score logpost %.6f (%+.3f vs the previous step)\n"),
                S8_CO2SEAS, o1$n_years, min(o1$year), max(o1$year), o1$sd_a, o1$sd_b, o0$n_years, o0$sd_a, o0$sd_b,
                as.numeric(v1), as.numeric(v1) - as.numeric(v0)))
    if (abs(as.numeric(v1) - as.numeric(v0)) <= CCX_REPRO_TOL) stop("the CO2SEAS override did not reach the objective")
    v0 <- v1
  }
  if (nzchar(S8_CO2LEVEL)) {
    o0 <- ccx_prepare_obs()
    g0 <- s8_pair_grad(o0$co2_ann$MLO, o0$co2_ann$SPO)
    gG <- identical(g0$year, o0$co2_grad$year) && identical(g0$grad, o0$co2_grad$grad)
    cat(sprintf("GATE G: s8_pair_grad() on the in situ levels is ccx_prepare_obs()'s co2_grad, exactly -> %s\n",
                if (gG) "PASS" else "FAIL"))
    if (!gG) stop("s8_pair_grad() does not reproduce ccx_prepare_obs()'s gradient")
    obs <- s8_obs()
    lp <- ccx_make_logpost(obs = obs, base_params = bp0, by_stream = TRUE, spinup_fn = spf)
    v1 <- lp(u0)
    cat(sprintf(paste0("CO2LEVEL OVERRIDE (CCX_SEAS8_CO2LEVEL): co2_level_MLO scores %s, %d years %d-%d (in situ: %d, %d-%d);",
                       " co2_gradient %d years %d-%d (in situ: %d); the mode's values now score logpost %.6f (%+.3f vs the previous step)\n"),
                S8_CO2LEVEL, nrow(obs$co2_ann$MLO), min(obs$co2_ann$MLO$year), max(obs$co2_ann$MLO$year),
                nrow(o0$co2_ann$MLO), min(o0$co2_ann$MLO$year), max(o0$co2_ann$MLO$year),
                nrow(obs$co2_grad), min(obs$co2_grad$year), max(obs$co2_grad$year), nrow(o0$co2_grad),
                as.numeric(v1), as.numeric(v1) - as.numeric(v0)))
    if (abs(as.numeric(v1) - as.numeric(v0)) <= CCX_REPRO_TOL) stop("the CO2LEVEL override did not reach the objective")
    v0 <- v1
  }
  list(md = md, pins = pins, spf = spf, bp0 = bp0, lp = lp, u0 = u0, v0 = v0, eps = eps, obs = obs, co2seas = S8_CO2SEAS,
       co2level = S8_CO2LEVEL,
       mode_file = ccx_mode_file(S8_MODE),
       mode_md5 = unname(tools::md5sum(ccx_mode_file(S8_MODE))))
}

#' One run of the canonical with `mods` applied to the model list.
#' `forc` may carry a replacement for ccx_emission_seasonality() (a function).
#' Returns the mean (a, b) harmonic vectors over `yrs` (per station, per tracer),
#' the per-year tables, and the by-stream likelihood.
s8_run <- function(L, spf, obs, mods = list(), yrs, emis_fn = NULL) {
  p <- L$p
  if (is.finite(S8_EPS)) p$alpha_photo_eps <- S8_EPS      # an explicit mods$alpha_photo_eps (T8b's probe) still wins
  for (n in names(mods)) p[[n]] <- mods[[n]]
  if (!is.null(emis_fn)) {
    old <- get("ccx_emission_seasonality", envir = globalenv())
    assign("ccx_emission_seasonality", emis_fn, envir = globalenv())
    on.exit(assign("ccx_emission_seasonality", old, envir = globalenv()), add = TRUE)
  }
  sp <- spf(p)
  conv <- if (is.null(sp$periodic)) NA_real_ else sp$periodic$resid_carbon
  sf <- ccx_scaled_forcing(sp, S8_YEARS, luc_scale = L$luc_scale, bomb_total = L$bomb_total)
  r  <- ccx_run_fast(sp, sf$F)
  ms <- ccx_model_stats(r$out, obs)
  ll <- ccx_loglik(r$out, obs, L$err, luc = sf$eluc,
                   deep = ccx_d14c_deep_read(sp),
                   ocean_grad = ccx_ocean_grad_scored(r$out, sp),
                   d14c_mid = ccx_model_d14c_slabs(sp),
                   npp = if (isTRUE(p$npp_row == 1)) r$npp else NULL,
                   by_stream = TRUE)
  vec <- function(h, y) { k <- match(y, h$year); c(mean(h$a[k]), mean(h$b[k])) }
  v <- list()
  for (st in S8_STATIONS) {
    v[[paste0("co2_", st)]] <- vec(ms$co2_seas[[st]], yrs[[st]])
    v[[paste0("d13_", st)]] <- vec(ms$d13_seas[[st]], yrs[[st]])
  }
  co2m <- vapply(S8_STATIONS, function(st) {
    h <- ms$co2[[st]]; k <- h$year %in% yrs[[st]]; mean(h$level[k]) }, numeric(1))
  list(v = v, ms = ms, ll = ll, retried = isTRUE(r$retried), resid_carbon = conv,
       co2_mean = co2m)
}
