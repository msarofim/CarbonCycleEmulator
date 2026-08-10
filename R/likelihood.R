# =====================================================================
# likelihood.R — compare a model run to the observations.
#
# Design notes that matter for interpreting posteriors:
#
# 1. AR(1) RESIDUALS ON THE DENSE CO2 SERIES. ~1500 monthly CO2 observations
#    against ~16 parameters would swamp every other constraint if treated as
#    independent, and they plainly are not: model-data residuals are dominated
#    by slowly varying structure. rho is calibrated.
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

# BOMB-WINDOW D14C IS EXCLUDED BY DEFAULT. A likelihood decomposition at the
# default parameters showed the two D14C streams contributing -165,214 of a
# -183,666 total -- 90 % of ALL the information -- while the bomb 14C injection
# SHAPE is still the documented placeholder in ccx_bomb_c14_annual(). Calibrating
# against it would let a placeholder drive essentially the entire posterior, and
# would launder that placeholder into every parameter. Pre-bomb (IntCal20) and
# post-recovery D14C are retained, so 14C still constrains ventilation through
# the Suess decline and the post-peak decay; only the peak itself is dropped.
# SET TO FALSE once UNSCEAR annual test yields are digitised (see DATA.md 8).
LIK_USE_BOMB_WINDOW <- FALSE
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

  list(co2 = co2, d13 = d13, d14_nh = d14_nh, d14_sh = d14_sh,
       ice = ico, gcb = gcb, intcal = ic20, weights = w)
}

#' AR(1) Gaussian log-likelihood for a residual series on a regular grid
#' @param r residuals, @param sd standard deviations, @param rho AR(1) coefficient
ccx_ll_ar1 <- function(r, sd, rho) {
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

#' Log-likelihood of one model run
#' @param out  data.frame from ccx_run_fast()$out
#' @param obs  from ccx_prepare_obs()
#' @param err  list(rho, sigma_co2, sigma_d13c, sigma_d14c)
ccx_loglik <- function(out, obs, err) {
  ll <- 0
  interp <- function(col, tt) stats::approx(out$t, out[[col]], xout = tt, rule = 2)$y

  # ---- dense monthly CO2, AR(1) ------------------------------------
  for (st in c("MLO", "SPO")) {
    o <- obs$co2[obs$co2$station == st, ]
    if (!nrow(o)) next
    mod <- interp(if (st == "MLO") "co2_NH" else "co2_SH", o$decimal_date)
    sd  <- sqrt(err$sigma_co2^2 + LIK_CO2_REP_ERR^2)
    ll  <- ll + ccx_ll_ar1(o$co2_ppm - mod, rep(sd, nrow(o)), err$rho)
  }

  # ---- ice-core CO2, independent ------------------------------------
  mod <- interp("co2_NH", obs$ice$year)   # SH-cored but globally well mixed pre-1900
  ll <- ll + sum(stats::dnorm(obs$ice$CO2ppm, mod, obs$ice$sd, log = TRUE))

  # ---- d13C ---------------------------------------------------------
  for (st in c("MLO", "SPO")) {
    o <- obs$d13[obs$d13$station == st, ]
    if (!nrow(o)) next
    mod <- interp(if (st == "MLO") "d13c_NH" else "d13c_SH", o$decimal_date)
    sd  <- sqrt(err$sigma_d13c^2 + LIK_D13C_REP_ERR^2)
    ll  <- ll + ccx_ll_ar1(o$d13c - mod, rep(sd, nrow(o)), err$rho)
  }

  # ---- D14C, hemispheric, with representation error -----------------
  for (hh in c("NH", "SH")) {
    o <- if (hh == "NH") obs$d14_nh else obs$d14_sh
    mod <- interp(if (hh == "NH") "d14c_NH" else "d14c_SH", o$t)
    sd  <- sqrt(o$sd^2 + err$sigma_d14c^2)
    ll  <- ll + sum(stats::dnorm(o$d14c, mod, sd, log = TRUE))
  }

  # ---- IntCal20 pre-bomb Suess decline -------------------------------
  if (!is.null(obs$intcal)) {
    ic <- obs$intcal[obs$intcal$year >= 1750 & obs$intcal$year < 1950, ]
    mod <- interp("d14c_NH", ic$year + 0.5)
    ll <- ll + sum(stats::dnorm(ic$d14c, mod,
                                sqrt(ic$err^2 + LIK_D14C_REP_OTHER^2), log = TRUE))
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
    ll <- ll + sum(stats::dnorm(g$ocean_sink[k], mod_oc[k], LIK_GCB_OCEAN_SD, log = TRUE))
    ll <- ll + sum(stats::dnorm(g$land_sink[k],  mod_ld[k],
                                LIK_GCB_LAND_SD * LIK_LAND_SINK_INFLATE, log = TRUE))
  }
  if (!is.finite(ll)) return(-Inf)
  ll
}
