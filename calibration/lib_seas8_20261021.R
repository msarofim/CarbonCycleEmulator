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
  list(md = md, pins = pins, spf = spf, bp0 = bp0, lp = lp, u0 = u0, v0 = v0,
       mode_file = ccx_mode_file(S8_MODE),
       mode_md5 = unname(tools::md5sum(ccx_mode_file(S8_MODE))))
}

#' One run of the canonical with `mods` applied to the model list.
#' `forc` may carry a replacement for ccx_emission_seasonality() (a function).
#' Returns the mean (a, b) harmonic vectors over `yrs` (per station, per tracer),
#' the per-year tables, and the by-stream likelihood.
s8_run <- function(L, spf, obs, mods = list(), yrs, emis_fn = NULL) {
  p <- L$p
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
