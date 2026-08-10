# =====================================================================
# Gate: the annual/seasonal likelihood (2026-08-11, replacing AR(1)).
#
# Three things have to hold, and the third is the reason the file exists:
#
#   1. ccx_year_harmonic() estimates what it claims to -- level, trend and the
#      first harmonic -- and is genuinely immune to partial month coverage,
#      which is the property that let the annual reduction happen at all.
#   2. The fast model-side path is the same estimator as the slow general one.
#      They are separate code, and a silent drift between them would corrupt
#      every posterior without failing anything else.
#   3. The AR(1) pathology does not come back: a level bias must be expensive,
#      and sigma must not be able to collapse. These are regression tests for a
#      specific historical failure (CHANGELOG 2026-08-11), so they assert
#      magnitudes, not just signs.
# =====================================================================

skip_if_no_cpp <- function() {
  skip_if_not_installed("Rcpp")
  ok <- tryCatch({ ccx_load_cpp(); TRUE }, error = function(e) FALSE)
  if (!ok) skip("C++ core failed to compile")
}

# ---- 1. the estimator ------------------------------------------------

test_that("ccx_year_harmonic recovers a known level, trend and harmonic", {
  yrs <- 2000:2009
  t <- rep(yrs, each = 12) + (seq_len(12) - 0.5) / 12
  phi <- t - floor(t)
  LEVEL0 <- 380; TREND <- 2.0; A <- 3.2; B <- -1.1
  v <- LEVEL0 + TREND * (t - 2000) + A * sin(2 * pi * phi) + B * cos(2 * pi * phi)
  h <- ccx_year_harmonic(t, v)
  expect_equal(nrow(h), length(yrs))
  # intercept is the value at mid-year, seasonality and within-year trend removed
  expect_equal(h$level, LEVEL0 + TREND * (yrs + 0.5 - 2000), tolerance = 1e-10)
  expect_equal(h$trend, rep(TREND, length(yrs)), tolerance = 1e-10)
  expect_equal(h$a, rep(A, length(yrs)), tolerance = 1e-10)
  expect_equal(h$b, rep(B, length(yrs)), tolerance = 1e-10)
})

test_that("the level estimate is immune to partial month coverage", {
  # THE point of using a harmonic fit rather than a mean of available months.
  # DESIGN section 6 records raw partial-year means shifting the 1950s by
  # -0.77 ppm; SPO has 8 years with fewer than 9 months.
  yrs <- 2000:2004
  t <- rep(yrs, each = 12) + (seq_len(12) - 0.5) / 12
  phi <- t - floor(t)
  v <- 380 + 2 * (t - 2000) + 3.2 * sin(2 * pi * phi) - 1.1 * cos(2 * pi * phi)
  full <- ccx_year_harmonic(t, v)
  mo <- round(phi * 12 + 0.5)
  naive_bias <- function(k) {
    max(abs(vapply(yrs, function(y) mean(v[k & floor(t) == y]), numeric(1)) - full$level))
  }
  # Apr-Dec: 9 months, the realistic sparse case that LIK_ANNUAL_MIN_MONTHS admits
  k <- mo >= 4
  part <- ccx_year_harmonic(t[k], v[k])
  expect_equal(part$level, full$level, tolerance = 1e-9)
  expect_equal(part$a, full$a, tolerance = 1e-9)
  expect_gt(naive_bias(k), 0.1)      # measured 0.20 ppm
  # Jul-Dec: more lopsided still, and the harmonic is still exact
  k6 <- mo >= 7
  part6 <- ccx_year_harmonic(t[k6], v[k6], min_months = 6L)
  expect_equal(part6$level, full$level, tolerance = 1e-9)
  expect_gt(naive_bias(k6), 0.5)
})

test_that("years below the month threshold are dropped, not fitted", {
  t <- c(2000 + (seq_len(12) - 0.5) / 12, 2001 + (seq_len(4) - 0.5) / 12)
  v <- stats::rnorm(length(t))
  h <- ccx_year_harmonic(t, v)
  expect_equal(h$year, 2000)
  expect_equal(nrow(h), 1L)
})

# ---- 2. fast path == general path ------------------------------------

test_that("the fast model-side reduction equals the general estimator", {
  skip_if_no_cpp()
  p <- ccx_default_params(); p$gamma_enso <- 0.5
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", c(1950, 2000), prod_c14 = sp$prod_c14)
  out <- ccx_run_fast(sp, F)$out
  for (col in c("co2_NH", "d13c_SH", "d14c_NH")) {
    fast <- ccx_model_year_stats(out, col)
    slow <- ccx_year_harmonic(out$t, out[[col]], min_months = 12L)
    expect_equal(fast$year, slow$year, info = col)
    expect_equal(fast$level, slow$level, tolerance = 1e-10, info = col)
    expect_equal(fast$a, slow$a, tolerance = 1e-10, info = col)
    expect_equal(fast$b, slow$b, tolerance = 1e-10, info = col)
  }
})

# ---- 3. the AR(1) pathology must not return --------------------------

lik_fixture <- function() {
  obs <- ccx_prepare_obs()
  p <- ccx_default_params(); p$gamma_enso <- 0.5
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = sp$prod_c14)
  list(obs = obs, out = ccx_run_fast(sp, F)$out,
       err = list(sigma_co2 = 1.5, sigma_d13c = 0.1, sigma_d14c = 5))
}

test_that("a CO2 level bias is expensive", {
  skip_if_no_cpp()
  f <- lik_fixture()
  base <- ccx_loglik(f$out, f$obs, f$err)
  cost <- function(b) {
    o <- f$out; o$co2_NH <- o$co2_NH + b; o$co2_SH <- o$co2_SH + b
    base - ccx_loglik(o, f$obs, f$err)
  }
  # Under AR(1) at rho = 0.998 a +50 ppm bias cost 13.7 log-units IN TOTAL.
  # Anything of that order here means the loophole is back.
  expect_gt(cost(1), 100)
  expect_gt(cost(50), 10000)
  # and monotone in the size of the bias
  expect_true(all(diff(vapply(c(0, 1, 5, 20, 50), cost, numeric(1))) > 0))
})

test_that("sigma_co2 cannot collapse: its profile peaks near the residual RMS", {
  skip_if_no_cpp()
  f <- lik_fixture()
  grid <- c(0.05, 0.2, 1, 2, 5, 15, 40, 100)
  ll <- vapply(grid, function(s) {
    e <- f$err; e$sigma_co2 <- s; ccx_loglik(f$out, f$obs, e)
  }, numeric(1))
  # interior maximum -- not at either end, and in particular not at ~0, which is
  # where the AR(1) scheme drove it (0.0744 ppm at the 2026-08-10 mode)
  best <- which.max(ll)
  expect_gt(best, 1L)
  expect_lt(best, length(grid))
  # and the collapsed value must be strictly worse than a sane one
  e0 <- f$err; e0$sigma_co2 <- 0.0744
  e1 <- f$err; e1$sigma_co2 <- 5
  expect_lt(ccx_loglik(f$out, f$obs, e0), ccx_loglik(f$out, f$obs, e1))
})

test_that("the seasonal statistic constrains amplitude and phase", {
  skip_if_no_cpp()
  obs <- ccx_prepare_obs()
  err <- list(sigma_co2 = 1.5, sigma_d13c = 0.1, sigma_d14c = 5)
  seas_ll <- function(amp, phase) {
    p <- ccx_default_params(); p$gamma_enso <- 0.5
    p$seas_amp_NH <- amp; p$seas_phase_NH <- phase
    sp <- ccx_spinup(p)
    F  <- ccx_build_forcing("historical", c(1950, 2024), prod_c14 = sp$prod_c14)
    ccx_loglik(ccx_run_fast(sp, F)$out, obs, err,
               by_stream = TRUE)[["co2_seasonal_MLO"]]
  }
  amps <- c(8, 20, 32)
  la <- vapply(amps, seas_ll, numeric(1), phase = 3.5)
  expect_gt(la[2], la[1])   # interior optimum in amplitude
  expect_gt(la[2], la[3])
  phs <- c(1.5, 3.5, 5.5)
  lp <- vapply(phs, function(ph) seas_ll(20, ph), numeric(1))
  expect_gt(lp[2], lp[1])   # interior optimum in phase
  expect_gt(lp[2], lp[3])
})

test_that("rho is gone and the parameter vector is self-consistent", {
  expect_false("rho" %in% CCX_PARAM_NAMES)
  expect_length(CCX_PARAM_NAMES, 17L)
  # round-trip through the unconstrained transform
  u <- ccx_init_unc()
  expect_named(u, CCX_PARAM_NAMES)
  back <- ccx_unc_to_par(u)
  for (n in CCX_PARAM_NAMES)
    expect_equal(back[[n]], CCX_PARAM_TABLE[[n]]$init, tolerance = 1e-10, info = n)
})

test_that("by_stream decomposes exactly into the total", {
  skip_if_no_cpp()
  f <- lik_fixture()
  parts <- ccx_loglik(f$out, f$obs, f$err, by_stream = TRUE)
  expect_equal(sum(parts), ccx_loglik(f$out, f$obs, f$err), tolerance = 1e-9)
  expect_true(all(is.finite(parts)))
})
