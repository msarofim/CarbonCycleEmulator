# =====================================================================
# likelihood.R — compare a model run to the observations.
#
# Design notes that matter for interpreting posteriors:
#
# 1. ANNUAL RESOLUTION, INDEPENDENT ERRORS -- NOT AR(1). (Changed 2026-08-11;
#    the AR(1) scheme it replaces is described in, and kept runnable by,
#    ccx_ll_ar1_SUPERSEDED().)
#
#    The original problem was real: ~1500 monthly CO2 observations against ~17
#    parameters would swamp every other constraint if treated as independent,
#    and they plainly are not independent. The AR(1) fix was worse than the
#    problem. Model-data residuals are dominated not by noise but by slowly
#    varying MODEL DISCREPANCY -- measured lag-1 autocorrelation 0.998 at MLO
#    and 0.9998 at SPO -- so a calibrated rho ran to the bound and reclassified
#    that discrepancy as free correlated noise. Measured at the 2026-08-10 mode:
#
#      rho     n_eff (of 812 MLO monthly)   log-units lost to a +50 ppm bias
#      0.998                          0.8                              13.7
#      0.95                          20.8                           3,390.7
#      0       (independent)          812                       1,274,217.9
#      annual means, sd 2 ppm          69                          27,461.7
#
#    At the mode, 67 years of the Keeling curve carried the weight of LESS THAN
#    ONE independent observation, and a 50 ppm level error cost 13.7 log-units.
#    That is why the mode had q10 = 0.28 and kz at the solver wall: nothing was
#    holding them. See CHANGELOG 2026-08-11.
#
#    The replacement addresses the swamping directly instead of via a fitted
#    nuisance parameter. Dense series are reduced to ANNUAL values scored with
#    INDEPENDENT errors, so the effective sample size is set by the data's real
#    information content (69 years for MLO) rather than by an autocorrelation
#    parameter free to decide the data barely count. The seasonal cycle, which
#    annual means discard and which is the only thing seas_amp_*/seas_phase_*
#    exist to fit, comes back as an EXPLICIT statistic -- two harmonic
#    coefficients per station -- rather than as 812 monthly likelihood terms.
#
#    A side benefit: the AR(1) was applied on OBSERVATION INDEX, not time, so a
#    16-month SPO gap was treated as a 1-month step. Annual values make the
#    sampling regular by construction.
#
# 1b. THE SAME ESTIMATOR RUNS ON MODEL AND OBSERVATIONS. ccx_year_harmonic()
#    fits, per calendar year, `v ~ 1 + (t - midyear) + sin(2*pi*phi) +
#    cos(2*pi*phi)`. Its intercept is a deseasonalised, detrended annual level
#    that is immune to partial month coverage (SPO has 8 sparse years, and the
#    DESIGN 6 note records raw partial-year means shifting the 1950s by
#    -0.77 ppm); its sin/cos coefficients are the seasonal statistic. Applying
#    one estimator to both sides means neither NOAA's deseasonalisation method
#    nor the model's seasonal shape has to be trusted separately.
#
# 1c. D14C IS REDUCED TO ANNUAL MEANS FOR THE SAME REASON. The Hua et al. (2022)
#    zonal record is a SMOOTHED MONTHLY COMPILATION fitted to sparser discrete
#    samples (DATA.md), so its 939 monthly values per hemisphere are not 939
#    independent measurements. Leaving them monthly while thinning CO2 would
#    have relocated the swamping, not removed it. Annual means keep the bomb
#    spike's amplitude and decay -- the ventilation signal -- and only discard
#    sub-annual structure the compilation interpolated in anyway. The monthly
#    error terms are NOT reduced by sqrt(n) on averaging, because the dominant
#    term is systematic representation error (note 3), not measurement noise.
#
# 2. GCB SINKS ARE A PARTITION CONSTRAINT, NOT A GROWTH ONE. Atmospheric growth
#    is already pinned by the CO2 series, so using GCB's full budget again would
#    double-count. Only the OCEAN sink enters at its stated uncertainty; the LAND
#    sink is deliberately given inflated uncertainty (Marcus, Q1 default).
#
# 3. D14C ZONE AGGREGATION CARRIES REPRESENTATION ERROR LARGER THAN THE
#    MEASUREMENT ERROR. Hua's five zones are bounded by the polar jet and the
#    tropical low-pressure belt -- not latitude circles -- and those boundaries
#    move seasonally and with longitude. Aggregating them to two hemispheric
#    boxes therefore has no uniquely right weighting. Measured spread across
#    defensible schemes: 21-26 permil during the bomb peak, ~4 permil after
#    1970, against Hua's reported sd of 0.5-6.7 permil. That spread is added in
#    quadrature rather than ignored, otherwise the bomb peak would dominate the
#    posterior on the strength of a weighting choice.
#
# 4. STATION-VS-BOX REPRESENTATION ERROR. MLO is not the NH mean and SPO is not
#    the SH mean. A fixed representation term is added to the CO2 error model.
# =====================================================================

# ---- named constants -------------------------------------------------
# Area weights use the Hua et al. (2013) nominal band boundaries (NH1/NH2 at
# ~40 N, NH2/NH3 at ~15 N, NH3/SH at the Equator). Hua et al. (2022) refine the
# NH1/NH2 boundary to lie between 45.1 N and 48.0 N in north-western America and
# note it varies seasonally; that alternative is what the representation error
# below is calibrated against.
LIK_ZONE_BOUNDS_NH <- c(40, 15)      # degrees N
LIK_ZONE_BOUNDS_SH <- c(15)          # degrees S, SH3/SH1-2 split
LIK_D14C_REP_BOMB  <- 25             # permil, 1955-1970 (weighting spread)
LIK_D14C_REP_OTHER <- 4              # permil, elsewhere
LIK_D14C_BOMB_WIN  <- c(1955, 1970)
LIK_CO2_REP_ERR    <- 1.0            # ppm, station-vs-hemispheric-box
LIK_D13C_REP_ERR   <- 0.05           # permil
LIK_LAND_SINK_INFLATE <- 3.0         # multiplier on GCB land-sink sigma (Q1)

# ---- annual reduction and the seasonal statistic (2026-08-11) --------
# A calendar year needs this many months for its harmonic fit (4 parameters:
# level, within-year trend, sin, cos). 9 leaves MLO 67 of 69 years and SPO 60
# of 68; the dropped years are the 1957-61 SPO start-up and partial end years.
LIK_ANNUAL_MIN_MONTHS <- 9L
# Window for the seasonal statistic. Starts at 1975 because that is when the
# SPO monthly record begins (the Scripps 1957-1975 SH record is unreachable --
# see CHANGELOG 2026-08-09), so both stations contribute over the same years.
LIK_SEAS_WINDOW <- c(1975, 2024)
# The seasonal constraint is scored PER YEAR -- each year's two first-harmonic
# coefficients are one observation pair -- with sigma set to the INTERANNUAL SD
# of those coefficients. Not the standard error of their multi-year mean: the
# model carries one fixed amplitude and phase, so year-to-year variation is
# structural discrepancy, and sigma has to cover it.
#
# Scoring the multi-year MEAN instead (4 terms in total) was tried and rejected:
# it made the seasonal cycle weaker than its own side effect. Measured at
# defaults, moving seas_amp_NH from 20 to 24 GtC/yr cost 1.2 log-units on the
# seasonal term but 6 on the CO2 LEVEL term, because a bigger seasonal cycle
# rectifies against the log CO2-fertilisation term and shifts the annual mean.
# The seasonal amplitude would then have been set by its rectification
# side-effect rather than by the seasonal cycle. Per-year scoring puts ~50 term
# pairs per station behind it and restores the intended ordering.

# BOMB-WINDOW D14C IS NOW INCLUDED (2026-08-10). It was excluded while the
# injection shape was a placeholder: a likelihood decomposition at the default
# parameters showed the two D14C streams contributing -165,214 of a -183,666
# total -- 90 % of ALL the information -- so calibrating against the peak would
# have let a placeholder drive essentially the entire posterior and laundered it
# into every parameter.
#
# That shape is now a measured stratosphere->troposphere delivery function built
# from Tans (1981) SCOPE 16 Tables 1-2 (DATA.md 9), so the window is admitted.
#
# CAVEAT that rides with it: at uncalibrated defaults the modelled NH peak is
# still +0.75 yr late against the area-weighted observed aggregate, and a 4.5x
# one-month step survives at the Part A / Part B join in 1963.04 -- inside this
# window. Both push on tau_ex and the ocean-uptake parameters. Treat any
# posterior shift in those specifically as suspect until the join is resolved.
LIK_USE_BOMB_WINDOW <- TRUE
LIK_BOMB_EXCLUDE    <- c(1950, 1975)   # window dropped when the switch is FALSE

# Law Dome stated errors are ANALYTICAL only (~0.02-1 ppm) and exclude gas-age
# and firn-smoothing uncertainty plus model-vs-ice representation error. Left
# uninflated, 255 ice samples at ~9 sigma each contributed -14,551 -- 8 % of the
# total from the sparsest, least direct record in the set.
LIK_ICE_REP_ERR <- 4.0               # ppm, added in quadrature
LIK_GCB_OCEAN_SD   <- 0.4            # GtC/yr, GCB stated ocean-sink uncertainty
LIK_GCB_LAND_SD    <- 0.9            # GtC/yr, GCB stated land-sink uncertainty

#' Hemisphere-area weights for the Hua zones
ccx_zone_weights <- function(nh_bounds = LIK_ZONE_BOUNDS_NH,
                             sh_bounds = LIK_ZONE_BOUNDS_SH) {
  s <- function(d) sin(d * pi / 180)
  nh <- c(NHZone1 = 1 - s(nh_bounds[1]),
          NHZone2 = s(nh_bounds[1]) - s(nh_bounds[2]),
          NHZone3 = s(nh_bounds[2]))
  sh <- c(SHZone3 = s(sh_bounds[1]), `SHZone1-2` = 1 - s(sh_bounds[1]))
  list(NH = nh / sum(nh), SH = sh / sum(sh))
}

# ---------------------------------------------------------------------
#' Per-calendar-year level, trend and first seasonal harmonic
#'
#' The single estimator applied to BOTH observations and model output (design
#' note 1b), so no deseasonalisation method has to be trusted on one side only.
#'
#' Per year, ordinary least squares of
#'     v ~ 1 + (t - midyear) + sin(2*pi*phi) + cos(2*pi*phi),   phi = t mod 1
#' The intercept is the value at mid-year with the seasonal cycle and the
#' within-year trend both removed, which is what makes it robust to partial
#' month coverage: a year observed only in Jul-Dec would otherwise report a
#' level biased upward by half a year of trend plus a lopsided seasonal mean.
#'
#' @return data.frame(year, level, trend, a, b, n) -- `a`,`b` are the sin and
#'   cos coefficients; amplitude = 2*sqrt(a^2+b^2) peak-to-peak.
ccx_year_harmonic <- function(t, v, min_months = LIK_ANNUAL_MIN_MONTHS) {
  ok <- is.finite(t) & is.finite(v)
  t <- t[ok]; v <- v[ok]
  yr <- floor(t)
  out <- lapply(sort(unique(yr)), function(y) {
    k <- yr == y
    if (sum(k) < min_months) return(NULL)
    tt <- t[k]; vv <- v[k]; phi <- tt - y
    X <- cbind(1, tt - (y + 0.5), sin(2 * pi * phi), cos(2 * pi * phi))
    cf <- tryCatch(qr.solve(X, vv), error = function(e) NULL)
    if (is.null(cf)) return(NULL)
    data.frame(year = y, level = cf[1], trend = cf[2], a = cf[3], b = cf[4], n = sum(k))
  })
  out <- do.call(rbind, out)
  if (is.null(out)) out <- data.frame(year = integer(0), level = numeric(0),
                                      trend = numeric(0), a = numeric(0),
                                      b = numeric(0), n = integer(0))
  out
}

#' Seasonal target: the per-year first-harmonic coefficients inside the window,
#' plus the interannual SD that serves as their sigma (see LIK_SEAS_WINDOW).
#' `a_mean`/`b_mean` are for reporting only; the likelihood scores year by year.
ccx_seasonal_target <- function(h, window = LIK_SEAS_WINDOW) {
  k <- h$year >= window[1] & h$year <= window[2]
  if (sum(k) < 3) return(NULL)
  list(year = h$year[k], a = h$a[k], b = h$b[k],
       a_mean = mean(h$a[k]), b_mean = mean(h$b[k]),
       sd_a = stats::sd(h$a[k]), sd_b = stats::sd(h$b[k]), n_years = sum(k))
}

#' Plain annual mean of an irregular series, with the year's mean stated error.
#' Errors are NOT reduced by sqrt(n): for D14C the dominant term is systematic
#' representation error, and for a smoothed compilation the monthly values are
#' not independent draws anyway (design note 1c).
ccx_annual_mean <- function(t, v, sd, min_n = 1L) {
  yr <- floor(t)
  u  <- sort(unique(yr))
  n  <- vapply(u, function(y) sum(yr == y), integer(1))
  data.frame(year = u,
             value = vapply(u, function(y) mean(v[yr == y]), numeric(1)),
             sd    = vapply(u, function(y) mean(sd[yr == y]), numeric(1)),
             n     = n)[n >= min_n, ]
}

#' Pre-assemble every observation into the form the likelihood needs.
#' Done ONCE, outside the MCMC loop.
ccx_prepare_obs <- function() {
  co2  <- as.data.frame(readRDS(ccx_path("data", "obs_co2_monthly.rds")))
  d13  <- as.data.frame(readRDS(ccx_path("data", "obs_d13c_monthly.rds")))
  d14  <- as.data.frame(readRDS(ccx_path("data", "obs_d14c_zonal.rds")))
  ice  <- readRDS(ccx_path("data", "obs_icecore.rds"))
  gcb  <- readRDS(ccx_path("data", "gcb_budget.rds"))$budget
  ic20 <- tryCatch(as.data.frame(readRDS(ccx_path("data", "obs_d14c_intcal20.rds"))),
                   error = function(e) NULL)

  # primary stations only -- the NOAA records are cross-checks, not targets
  co2 <- co2[co2$station %in% c("MLO", "SPO"), ]
  d13 <- d13[d13$station %in% c("MLO", "SPO"), ]

  # D14C: aggregate zones to hemispheres with area weights
  w <- ccx_zone_weights()
  agg <- function(zones, wts) {
    sub <- d14[d14$zone %in% names(wts), c("decimal_date", "zone", "d14c", "d14c_sd")]
    wide <- reshape(sub, idvar = "decimal_date", timevar = "zone", direction = "wide")
    vcols <- paste0("d14c.", names(wts))
    scols <- paste0("d14c_sd.", names(wts))
    keep <- stats::complete.cases(wide[, vcols])
    wide <- wide[keep, ]
    val <- as.vector(as.matrix(wide[, vcols]) %*% wts)
    # measurement error propagates as a weighted quadrature sum
    sdv <- sqrt(as.vector(as.matrix(wide[, scols])^2 %*% (wts^2)))
    data.frame(t = wide$decimal_date, d14c = val, sd_meas = sdv)
  }
  d14_nh <- agg("NH", w$NH); d14_sh <- agg("SH", w$SH)
  rep_err <- function(t) ifelse(t >= LIK_D14C_BOMB_WIN[1] & t <= LIK_D14C_BOMB_WIN[2],
                                LIK_D14C_REP_BOMB, LIK_D14C_REP_OTHER)
  d14_nh$sd <- sqrt(d14_nh$sd_meas^2 + rep_err(d14_nh$t)^2)
  d14_sh$sd <- sqrt(d14_sh$sd_meas^2 + rep_err(d14_sh$t)^2)
  if (!LIK_USE_BOMB_WINDOW) {
    drop <- function(x) x[x$t < LIK_BOMB_EXCLUDE[1] | x$t > LIK_BOMB_EXCLUDE[2], ]
    n0 <- nrow(d14_nh); d14_nh <- drop(d14_nh); d14_sh <- drop(d14_sh)
    message(sprintf("D14C bomb window %d-%d EXCLUDED (%d of %d NH points dropped): the bomb injection shape is still provisional.",
                    LIK_BOMB_EXCLUDE[1], LIK_BOMB_EXCLUDE[2], n0 - nrow(d14_nh), n0))
  }

  # ice-core CO2: use the RAW SAMPLES with their stated errors, not the spline.
  # The spline is a smoothed reconstruction; treating its annual values as
  # independent observations would massively overweight the pre-1958 record.
  ico <- as.data.frame(ice$co2_samples)
  names(ico)[names(ico) == "age_CO2"] <- "year"
  ico <- ico[!is.na(ico$year) & !is.na(ico$CO2ppm) & ico$year >= 1700, ]
  ico$sd <- sqrt(pmax(ico$CO2err, 0.5)^2 + LIK_ICE_REP_ERR^2)

  # ---- ANNUAL REDUCTION (2026-08-11; see design notes 1, 1b, 1c) -----
  # Everything below is what the likelihood actually scores. The monthly frames
  # are still returned, because diagnostics and the app plot against them.
  co2_ann <- lapply(c(MLO = "MLO", SPO = "SPO"), function(st) {
    o <- co2[co2$station == st, ]
    ccx_year_harmonic(o$decimal_date, o$co2_ppm)
  })
  d13_ann <- lapply(c(MLO = "MLO", SPO = "SPO"), function(st) {
    o <- d13[d13$station == st, ]
    if (!nrow(o)) return(NULL)
    ccx_year_harmonic(o$decimal_date, o$d13c)
  })
  co2_seas <- lapply(co2_ann, ccx_seasonal_target)

  d14_nh_ann <- ccx_annual_mean(d14_nh$t, d14_nh$d14c, d14_nh$sd)
  d14_sh_ann <- ccx_annual_mean(d14_sh$t, d14_sh$d14c, d14_sh$sd)

  list(co2 = co2, d13 = d13, d14_nh = d14_nh, d14_sh = d14_sh,
       ice = ico, gcb = gcb, intcal = ic20, weights = w,
       co2_ann = co2_ann, d13_ann = d13_ann, co2_seas = co2_seas,
       d14_nh_ann = d14_nh_ann, d14_sh_ann = d14_sh_ann)
}

#' SUPERSEDED 2026-08-11 -- the AR(1) residual model. Do not wire this back in.
#'
#' Kept so the size of the correction is reproducible and so the diagnosis can
#' be re-run, exactly as ccx_bomb_c14_annual_SUPERSEDED() is kept in forcing.R.
#'
#' The exact AR(1) likelihood is correct arithmetic for a wrong premise. As
#' rho -> 1 the innovation becomes (r_t - r_{t-1})/sd, so the fitted sd collapses
#' to the RMS of the residual INCREMENTS rather than of the residual LEVEL. For a
#' smooth model against a smooth observation series that is tiny -- sigma_co2 fell
#' to 0.074 ppm -- and the level goes unpenalised. See the table in design note 1.
#'
#' Two further defects, both fatal on their own:
#'   * it is applied on OBSERVATION INDEX, so a 16-month SPO gap counts as one
#'     step (the docstring's "regular grid" premise is simply not met);
#'   * one shared rho was imposed across four series -- MLO/SPO CO2 and
#'     MLO/SPO d13C -- with quite different sampling densities.
#'
#' @param r residuals, @param sd standard deviations, @param rho AR(1) coefficient
ccx_ll_ar1_SUPERSEDED <- function(r, sd, rho) {
  n <- length(r)
  if (n == 0) return(0)
  z <- r / sd
  if (n == 1) return(-0.5 * z^2 - sum(log(sd)))
  # exact AR(1) likelihood for standardised residuals
  ll <- -0.5 * (1 - rho^2) * z[1]^2 + 0.5 * log(1 - rho^2)
  e  <- z[-1] - rho * z[-n]
  ll <- ll - 0.5 * sum(e^2)
  ll - sum(log(sd)) - 0.5 * n * log(2 * pi)
}

# ---------------------------------------------------------------------
# Model-side reduction: the SAME estimator, but computed as one matrix product.
#
# ccx_year_harmonic() is general enough for observations, which have ragged
# month coverage, but it costs a qr.solve and a data.frame per year. Called on
# four model series inside an MCMC loop that is otherwise 46 ms, it took the
# posterior evaluation to 718 ms -- 40 hours for a production run. The model,
# unlike the observations, is on an EXACT monthly grid, so every full year
# shares one design matrix and the whole reduction is a 4x12 by 12xN product.
# test-likelihood.R gates the fast path against ccx_year_harmonic() so the two
# cannot drift apart.
.ccx_month_design <- local({
  phi <- (seq_len(12) - 0.5) / 12                 # month centres within a year
  X   <- cbind(1, phi - 0.5, sin(2 * pi * phi), cos(2 * pi * phi))
  list(X = X, P = solve(crossprod(X), t(X)))      # 4 x 12 pseudo-inverse
})

#' Per-year level / trend / harmonic of one model column, on the monthly grid
ccx_model_year_stats <- function(out, col) {
  yr <- floor(out$t + 1e-9)
  u  <- unique(yr)
  n  <- tabulate(match(yr, u), nbins = length(u))
  full <- which(n == 12L)
  if (!length(full)) return(NULL)
  keep <- yr %in% u[full]
  # Guard the reshape: the matrix() below assumes 12 consecutive month-ordered
  # rows per year, which ccx_build_forcing() produces. Assert rather than trust.
  mo <- round((out$t[keep] - yr[keep]) * 12 + 0.5)
  if (!identical(as.integer(mo), rep(seq_len(12), length(full))))
    return(ccx_year_harmonic(out$t[keep], out[[col]][keep], min_months = 12L))
  M  <- matrix(out[[col]][keep], nrow = 12)
  cf <- .ccx_month_design$P %*% M
  list(year = u[full], level = cf[1, ], trend = cf[2, ],
       a = cf[3, ], b = cf[4, ], mean = colMeans(M))
}

#' Reduce a model run to the same annual/seasonal statistics as the observations
ccx_model_stats <- function(out, obs) {
  cols <- c(co2_NH = "co2_NH", co2_SH = "co2_SH",
            d13c_NH = "d13c_NH", d13c_SH = "d13c_SH",
            d14c_NH = "d14c_NH", d14c_SH = "d14c_SH")
  s <- lapply(cols, function(cc) ccx_model_year_stats(out, cc))
  co2 <- list(MLO = s$co2_NH, SPO = s$co2_SH)
  list(co2 = co2, d13 = list(MLO = s$d13c_NH, SPO = s$d13c_SH),
       d14 = list(NH = s$d14c_NH, SH = s$d14c_SH),
       co2_seas = lapply(co2, ccx_seasonal_target))
}

#' Log-likelihood of one model run
#'
#' Every stream is scored with INDEPENDENT Gaussian errors on ANNUAL values.
#' There is no autocorrelation parameter -- see design note 1 for why the AR(1)
#' predecessor was retired rather than bounded.
#'
#' @param out  data.frame from ccx_run_fast()$out
#' @param obs  from ccx_prepare_obs()
#' @param err  list(sigma_co2, sigma_d13c, sigma_d14c)
#' @param by_stream if TRUE return the per-stream contributions instead of the
#'   total. Used by the calibration report and by the app's diagnostics panel;
#'   a single number cannot show which constraint a fit is actually paying for.
ccx_loglik <- function(out, obs, err, by_stream = FALSE) {
  parts <- c()
  add <- function(name, v) parts[[name]] <<- (if (is.null(parts[[name]])) 0 else parts[[name]]) + v
  interp <- function(col, tt) stats::approx(out$t, out[[col]], xout = tt, rule = 2)$y
  ms <- ccx_model_stats(out, obs)

  # ---- CO2 annual level, independent ---------------------------------
  # sigma_co2 is model-structural error at ANNUAL scale; LIK_CO2_REP_ERR is the
  # fixed station-vs-box term. Neither is divided by sqrt(months): both are
  # systematic within a year (design note 1c).
  for (st in c("MLO", "SPO")) {
    o <- obs$co2_ann[[st]]; m <- ms$co2[[st]]
    if (is.null(o) || !nrow(o)) next
    k <- match(o$year, m$year)
    good <- !is.na(k)
    sd <- sqrt(err$sigma_co2^2 + LIK_CO2_REP_ERR^2)
    add(paste0("co2_level_", st),
        sum(stats::dnorm(o$level[good], m$level[k[good]], sd, log = TRUE)))
  }

  # ---- CO2 seasonal cycle: per-year harmonic coefficients ------------
  # What the annual reduction discards, restored as an explicit statistic and
  # scored year by year (see the note on LIK_SEAS_WINDOW). This is the ONLY
  # thing constraining seas_amp_* and seas_phase_*.
  for (st in c("MLO", "SPO")) {
    o <- obs$co2_seas[[st]]; m <- ms$co2_seas[[st]]
    if (is.null(o) || is.null(m)) next
    k <- match(o$year, m$year); good <- !is.na(k)
    add(paste0("co2_seasonal_", st),
        sum(stats::dnorm(o$a[good], m$a[k[good]], o$sd_a, log = TRUE)) +
        sum(stats::dnorm(o$b[good], m$b[k[good]], o$sd_b, log = TRUE)))
  }

  # ---- ice-core CO2, independent ------------------------------------
  mod <- interp("co2_NH", obs$ice$year)   # SH-cored but globally well mixed pre-1900
  add("co2_icecore", sum(stats::dnorm(obs$ice$CO2ppm, mod, obs$ice$sd, log = TRUE)))

  # ---- d13C annual level ---------------------------------------------
  # Level only. The model's d13C seasonality is a derived consequence of the
  # same NEP harmonic the CO2 seasonal statistic already constrains, so scoring
  # it again would double-count one mechanism.
  for (st in c("MLO", "SPO")) {
    o <- obs$d13_ann[[st]]; m <- ms$d13[[st]]
    if (is.null(o) || !nrow(o) || is.null(m)) next
    k <- match(o$year, m$year)
    good <- !is.na(k)
    sd <- sqrt(err$sigma_d13c^2 + LIK_D13C_REP_ERR^2)
    add(paste0("d13c_level_", st),
        sum(stats::dnorm(o$level[good], m$level[k[good]], sd, log = TRUE)))
  }

  # ---- D14C annual means, with representation error -------------------
  # Model side is its own annual MEAN, not a mid-year sample: the observation is
  # a mean, and during the bomb rise the two differ by several permil.
  for (hh in c("NH", "SH")) {
    o <- if (hh == "NH") obs$d14_nh_ann else obs$d14_sh_ann
    m <- ms$d14[[hh]]
    if (is.null(m)) next
    k <- match(o$year, m$year); good <- !is.na(k)
    sd <- sqrt(o$sd[good]^2 + err$sigma_d14c^2)
    add(paste0("d14c_", hh),
        sum(stats::dnorm(o$value[good], m$mean[k[good]], sd, log = TRUE)))
  }

  # ---- IntCal20 pre-bomb Suess decline -------------------------------
  if (!is.null(obs$intcal)) {
    ic <- obs$intcal[obs$intcal$year >= 1750 & obs$intcal$year < 1950, ]
    mod <- interp("d14c_NH", ic$year + 0.5)
    add("d14c_intcal", sum(stats::dnorm(ic$d14c, mod,
                           sqrt(ic$err^2 + LIK_D14C_REP_OTHER^2), log = TRUE)))
  }

  # ---- GCB sinks: PARTITION only -------------------------------------
  # Annual sink = -d(stock)/dt from the model, compared to GCB.
  yr <- floor(out$t)
  ann <- stats::aggregate(cbind(ocean_C, land_C) ~ yr, data = out, FUN = mean)
  g <- merge(obs$gcb[, c("year", "ocean_sink", "land_sink")], ann,
             by.x = "year", by.y = "yr")
  if (nrow(g) > 2) {
    g <- g[order(g$year), ]
    mod_oc <- c(NA, diff(g$ocean_C))
    mod_ld <- c(NA, diff(g$land_C))
    k <- !is.na(mod_oc)
    add("gcb_ocean_sink",
        sum(stats::dnorm(g$ocean_sink[k], mod_oc[k], LIK_GCB_OCEAN_SD, log = TRUE)))
    add("gcb_land_sink",
        sum(stats::dnorm(g$land_sink[k], mod_ld[k],
                         LIK_GCB_LAND_SD * LIK_LAND_SINK_INFLATE, log = TRUE)))
  }
  if (by_stream) return(unlist(parts))
  ll <- sum(unlist(parts))
  if (!is.finite(ll)) return(-Inf)
  ll
}
