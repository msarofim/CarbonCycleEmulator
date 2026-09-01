# =====================================================================
# lib_design_gates.R -- the DESIGN sec.6 gate 4 / 5 / 7 KERNELS, in one place.
#
# WHY THIS FILE EXISTS (2026-08-31f). These estimators were written inside
# `diag_design_gates_at_mode.R` and were about to be written a SECOND time, in
# the file that re-prices the same three gates in the 08-31e basin. Two copies
# of a gate is the caption-sync bug class the project rule against free-floating
# labels exists to kill: the day one copy's window, target or estimator moves,
# the two files report the same gate name at two different measurements and
# nothing says so. One kernel, two callers, one set of named constants.
#
# ⛔ SOURCE THIS, DO NOT RUN IT. It defines constants and functions and reads
# the zonal 14C observations once; it prints and gates nothing on its own.
#
# EVERY DESIGN DECISION BELOW IS INHERITED VERBATIM from the 2026-08-27 file and
# its comments are kept with it, because each one is a ruling that was paid for:
#   * the two FORCING parameters (`bomb_total`, `luc_scale`) are carried;
#   * gate 5 is scored on the HEMISPHERIC aggregate, never Hua's Zone 1;
#   * gate 7's window ends at 2023 and its targets are RECOMPUTED on that
#     window rather than quoted against a different one;
#   * gate 7's year boundaries extrapolate LINEARLY, matching the objective.
#
# WHAT IS NEW HERE, AND ONLY THIS: `dg_vector()` accepts a mode PATH as well as
# a mode NAME, and it MIGRATES a stored 21-parameter ancestor onto this build's
# 22 through `ccx_migrate_par_set()` instead of refusing it. The refusal it
# replaces (`stopifnot(identical(md$param_names, CCX_PARAM_NAMES))`) made this
# whole harness unrunnable the moment `seas_lag_p` split on 08-31 -- and a gate
# that cannot run reports nothing, which is worse than a gate that runs and says
# out loud that its input was migrated. It says so: `$migrated` is returned and
# every caller prints it.
# =====================================================================

# ---- labels derive from named constants (project rule) --------------
DG_BOMB_REF  <- 102                  # = BOMB_REF in ccx_make_logpost()
DG_YEARS     <- c(1750, 2024)

# GATE 4 -- GCB 2025 airborne fraction (DESIGN sec.6 gate 4)
DG_AF_WIN     <- c(1959, 2024)
DG_AF_OBS     <- 0.431
DG_AF_DECADES <- c(1960, 1970, 1980, 1990, 2000, 2010, 2020)
DG_AF_OBS_DEC <- c(0.35, 0.43, 0.47, 0.38, 0.42, 0.45, 0.50)

# GATE 5 -- Hua et al. 2022, HEMISPHERIC AGGREGATE (DESIGN's own like-for-like
# benchmark, not the Zone 1 numbers it warns against)
DG_BOMB_NH_PEAK <- 853.2; DG_BOMB_NH_YR <- 1963.708
DG_BOMB_SH_PEAK <- 659.4; DG_BOMB_SH_YR <- 1965.042
DG_BOMB_LAG     <- 1.33
DG_EFOLD_FLOOR  <- 20                # permil, the > 20 permil window DESIGN names

# GATE 7 -- GCB 2025 decade means and stated 1 sigma.
#
# THE WINDOW ENDS AT 2023, NOT 2024, AND THAT IS A DECISION (Marcus, 2026-08-27).
# The historical run ends at 2024-12 (t[n] = 2024.958), so the 2025 year boundary
# this gate differences the stock against sits HALF A MONTH past the last model
# state. That half month lands entirely on 2024, and it lands there at the moment
# in the seasonal cycle when the land stock's slope is at its most NEGATIVE (NH
# December respiration) -- so how the end is extrapolated is worth 0.65 GtC/yr on
# the 2024 annual increment alone, against sub-0.001 in every other year.
DG_SINK_WIN  <- c(2015, 2023)
# THE TARGETS ARE RECOMPUTED ON DG_SINK_WIN, NOT QUOTED. GCB's published decade
# means are 2.36 (land) / 3.22 (ocean) over 2015-2024 -- verified: recomputing
# them from the obs series over that window returns 2.363 / 3.221. But they are
# means over a WINDOW, so quoting them against a different window would compare
# nine model years with ten observed ones. Over 2015-2023 the observed means are
# 2.410 / 3.202. Both sides move together; the like-for-like rule decides it.
DG_GCB_LAND_SD  <- LIK_GCB_LAND_SD
DG_GCB_OCEAN_SD <- LIK_GCB_OCEAN_SD
DG_GCB_PUB_WIN  <- c(2015, 2024)     # the window GCB's published means are over
DG_GCB_PUB_LAND <- 2.36; DG_GCB_PUB_OCEAN <- 3.22

DG_GtC_PER_PPM <- ccx_const("GtC_PER_PPM")

# ---- resolve one arm to (params, luc_scale, bomb_total) -------------
#' @param arm "defaults", a name ccx_mode_file() knows, or a path to a mode file
#' @return list(p = model params, pm = fitted params, luc_scale, bomb_total,
#'   ..., src, migrated, md)
dg_vector <- function(arm) {
  p <- ccx_default_params()
  if (identical(arm, "defaults"))
    return(list(p = p, luc_scale = 1, bomb_total = DG_BOMB_REF,
                src = "uncalibrated defaults", migrated = character(0), md = NULL))
  f  <- ccx_mode_file(arm)
  md <- readRDS(f)
  # ⚠ MIGRATE, THEN SAY SO. `ccx_migrate_par_set()` reads the model's own
  # absence contract (`ccx_seas_lag_p()`); it never hand-fills, and it ERRORS on
  # a name no stored field can supply. A migrated vector is a legitimate thing
  # to MEASURE a gate at -- it is not a mode of this build's space, and every
  # caller must print `$migrated` so the reader knows which it is looking at.
  pm <- ccx_migrate_par_set(md$par_mode)
  mig <- attr(pm, "migrated")
  for (n in intersect(names(p), CCX_PARAM_NAMES)) p[[n]] <- pm[[n]]
  p$gamma_enso <- pm$gamma_enso
  p$pump_mode  <- md$pump_mode
  # ⚠ TWO LISTS, NOT ONE ([[ccx_two_param_lists]]). `p` is the MODEL's list --
  # ccx_default_params() overlaid with the fitted names it has slots for -- and
  # it is what ccx_spinup()/ccx_run_fast() take. `pm` is the FITTED list, all 22
  # names including the six nuisances (`bomb_total`, `luc_scale`, `sigma_d14c`,
  # `rep_dC`, `grad_off_*`) that have no model slot at all, and it is what
  # ccx_par_to_unc()/the objective take. Handing `p` to the objective raises
  # "lacks parameters this build fits"; handing `pm` to ccx_spinup() dies
  # cryptically. Both are returned, named for what they are.
  list(p = p, pm = pm, luc_scale = pm$luc_scale, bomb_total = pm$bomb_total,
       sigma_d14c = pm$sigma_d14c, rep_dC = pm$rep_dC,
       grad_off_co2 = pm$grad_off_co2, grad_off_d13c = pm$grad_off_d13c,
       md = md, migrated = mig,
       src = sprintf("%s (logpost %.2f%s)", basename(dirname(f)), md$logpost,
                     if (length(mig)) sprintf(", MIGRATED %d->%d",
                                              length(md$param_names),
                                              length(CCX_PARAM_NAMES)) else ""))
}

dg_run <- function(v) {
  sp <- ccx_spinup(v$p)
  F  <- ccx_build_forcing("historical", DG_YEARS, prod_c14 = sp$prod_c14,
                          bomb_total_kmol = v$bomb_total, luc_scale = v$luc_scale)
  list(sp = sp, F = F, out = ccx_run_fast(sp, F)$out)
}

# ---- GATE 4: airborne fraction --------------------------------------
# AF = atmospheric growth / total emissions, both from THIS run: the model's own
# E_LUC carries luc_scale, so a fit that shrinks land use by 11 % shrinks the
# DENOMINATOR too. Scoring the model's growth against GCB's unscaled emissions
# would credit it with an AF it never produced. The scaled denominator is the
# self-consistent quantity; the unscaled one is printed beside it because
# luc_scale is a fitted nuisance and the reader is owed both.
dg_gate4 <- function(r, v) {
  o <- r$out
  yrs <- sort(unique(floor(o$t + 1e-9))); bnd <- c(yrs, max(yrs) + 1L)
  atm <- stats::approx(o$t, (o$co2_NH + o$co2_SH) / 2 * DG_GtC_PER_PPM,
                       xout = bnd, rule = 2)$y
  grow <- diff(atm)
  el <- ccx_forcing_eluc_annual(r$F)
  # No ccx_forcing_efoss_annual() exists; this is the eluc helper's own recipe
  # (FUN = mean over the calendar year, because the columns are GtC/yr RATES,
  # not monthly masses -- summing them would give twelve times the emission).
  ef <- stats::aggregate(list(efoss = r$F$e_foss_NH + r$F$e_foss_SH),
                         by = list(year = r$F$year), FUN = mean)
  luc  <- el$eluc[match(yrs, el$year)]
  foss <- ef$efoss[match(yrs, ef$year)]
  af <- function(k) sum(grow[k]) / sum((foss + luc)[k])
  k <- yrs >= DG_AF_WIN[1] & yrs <= DG_AF_WIN[2]
  dec <- vapply(DG_AF_DECADES, function(d) {
    kk <- yrs >= d & yrs <= min(d + 9, DG_AF_WIN[2]) & k; af(kk)
  }, numeric(1))
  list(all = af(k), dec = dec,
       all_unscaled = sum(grow[k]) / sum((foss + luc / v$luc_scale)[k]))
}

# ---- GATE 5: bomb curve, hemispheric aggregate ----------------------
# One estimator, applied to model and observations alike: parabolic refinement
# of the peak on the monthly series (the raw argmax is quantised to the sampling
# interval, which for the observations is 1/12 yr -- big enough to move the
# NH->SH lag by a tenth of its value), then a log-linear fit of the post-peak
# decline over Delta14C > DG_EFOLD_FLOOR.
dg_peak <- function(t, v) {
  i <- which.max(v)
  if (i <= 1 || i >= length(v)) return(c(t = t[i], v = v[i]))
  y1 <- v[i - 1]; y2 <- v[i]; y3 <- v[i + 1]
  d  <- 0.5 * (y1 - y3) / (y1 - 2 * y2 + y3)          # in samples
  c(t = t[i] + d * (t[i + 1] - t[i]), v = y2 - 0.25 * (y1 - y3) * d)
}
dg_efold <- function(t, v, tpk) {
  k <- t > tpk & v > DG_EFOLD_FLOOR
  if (sum(k) < 5) return(NA_real_)
  -1 / stats::coef(stats::lm(log(v[k]) ~ t[k]))[[2]]
}
dg_obs_bomb <- local({
  z <- as.data.frame(readRDS(ccx_path("data", "obs_d14c_zonal.rds")))
  w <- ccx_zone_weights()
  hemi <- function(h) {
    ww <- w[[h]]
    zz <- z[z$zone %in% names(ww), ]
    tt <- sort(unique(zz$decimal_date))
    m <- vapply(names(ww), function(nm) {
      s <- zz[zz$zone == nm, ]
      stats::approx(s$decimal_date, s$d14c, xout = tt, rule = 2)$y
    }, numeric(length(tt)))
    list(t = tt, v = as.vector(m %*% ww[colnames(m)]))
  }
  lapply(c(NH = "NH", SH = "SH"), hemi)
})
dg_gate5 <- function(r) {
  o <- r$out
  pk <- lapply(c(NH = "NH", SH = "SH"), function(h) {
    v <- o[[paste0("d14c_", h)]]
    p <- dg_peak(o$t, v)
    c(p, efold = dg_efold(o$t, v, p[["t"]]))
  })
  list(pk = pk, lag = pk$SH[["t"]] - pk$NH[["t"]])
}
#' The observed hemispheric bomb peaks, under the SAME estimator as the model
dg_obs_gate5 <- function() {
  lapply(dg_obs_bomb, function(x) {
    p <- dg_peak(x$t, x$v); c(p, efold = dg_efold(x$t, x$v, p[["t"]]))
  })
}

# ---- GATE 7: sinks (same construction as diag_app_params.R) ---------
# END HANDLING MATCHES THE OBJECTIVE, 2026-08-27. This used approx(rule = 2),
# which holds the stock FLAT across the half month the year boundaries fall
# outside the run at each end. R/likelihood.R rejected exactly that for the
# objective's own gcb_* streams and extrapolates LINEARLY instead: flat "would
# silently under-count the first and last year's flux ... which is the shape of
# a bug". Aligning it is what makes the two reconstructions agree at ANY window
# boundary -- dropping 2024 only hides today's instance.
#' Annual land / ocean sinks and CO2 growth from one run
#'
#' ⭐ EXTRACTED 2026-09-01 because `dg_gate7()` was not the only caller any more:
#' `diag_elnino_2023_sink_response.R` had copied this construction to get the
#' same quantity YEAR BY YEAR, and a second copy of an estimator is the
#' caption-sync bug class -- the day the end handling changes in one, the two
#' report the same sink at two values and nothing says so. Gate 7 is now the
#' WINDOW MEAN of this series, which is exactly what it always was.
#'
#' @return list(year, land, ocean, growth_ppm)
dg_annual_sinks <- function(r) {
  o <- r$out
  yrs <- sort(unique(floor(o$t + 1e-9))); bnd <- c(yrs, max(yrs) + 1L)
  tt <- o$t; n <- length(tt)
  stock <- function(v) {
    y  <- stats::approx(tt, v, xout = bnd)$y
    lo <- bnd < tt[1]; hi <- bnd > tt[n]
    if (any(lo)) y[lo] <- v[1] + (bnd[lo] - tt[1]) * (v[2] - v[1]) / (tt[2] - tt[1])
    if (any(hi)) y[hi] <- v[n] + (bnd[hi] - tt[n]) * (v[n] - v[n - 1]) / (tt[n] - tt[n - 1])
    diff(y)
  }
  el  <- ccx_forcing_eluc_annual(r$F)
  atm <- stats::approx(o$t, (o$co2_NH + o$co2_SH) / 2, xout = bnd, rule = 2)$y
  list(year = yrs, ocean = stock(o$ocean_C),
       land = stock(o$land_C) + el$eluc[match(yrs, el$year)],
       growth_ppm = diff(atm))
}

dg_gate7 <- function(r) {
  a <- dg_annual_sinks(r)
  k <- a$year >= DG_SINK_WIN[1] & a$year <= DG_SINK_WIN[2]
  list(ocean = mean(a$ocean[k]), land = mean(a$land[k]))
}

# ---- the gate-7 TARGETS, recomputed on DG_SINK_WIN from the obs series -------
dg_gcb_target <- function(win) {
  g <- as.data.frame(ccx_prepare_obs()$gcb)
  k <- g$year >= win[1] & g$year <= win[2]
  list(land = mean(g$land_sink[k]), ocean = mean(g$ocean_sink[k]), n = sum(k))
}

# ---- per-stream logL at a vector, for provenance and for pricing ----
# The LIKELIHOOD is recomputed, not the posterior: a refit's h_ml band
# renormalises the PRIOR and is not reconstructible from ccx_default_params()
# (memory ccx_hml_band_provenance), so a logpost comparison would indict the
# product for a property of the producer. par_mode is band-safe.
dg_streams <- function(r, v) {
  o <- r$out
  eluc <- ccx_forcing_eluc_annual(r$F)
  err <- list(sigma_d14c = v$sigma_d14c, rep_dC = v$rep_dC,
              grad_off_co2 = v$grad_off_co2, grad_off_d13c = v$grad_off_d13c)
  ccx_loglik(o, ccx_prepare_obs(), err, luc = eluc,
             deep = r$sp$diagnostics$d14c_bottom_box,
             ocean_grad = ccx_ocean_grad_scored(o, r$sp), by_stream = TRUE)
}
