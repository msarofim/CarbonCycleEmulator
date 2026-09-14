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
  set.seed(20260912)                     # seeded immediately before the draw (review A15)
  v <- stats::rnorm(length(t))
  h <- ccx_year_harmonic(t, v)
  expect_equal(h$year, 2000)
  expect_equal(nrow(h), 1L)
})

# ---- 2. fast path == general path ------------------------------------

test_that("the fast model-side reduction equals the general estimator", {
  skip_if_no_cpp()
  p <- ccx_default_params(); p <- ccx_set_enso(p, list(gamma_enso = 0.5))
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
  p <- ccx_default_params(); p <- ccx_set_enso(p, list(gamma_enso = 0.5))
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = sp$prod_c14)
  list(obs = obs, out = ccx_run_fast(sp, F)$out,
       err = list(sigma_co2 = 1.5, sigma_d13c = 0.1, sigma_d14c = 5))
}

test_that("a CO2 level bias is expensive", {
  skip_if_no_cpp()
  # RE-EXPRESSED 2026-08-15 (Marcus), NOT re-baselined. The old form asserted
  # cost(1) > 100 measured from a ZERO shift, i.e. it assumed the fixture model
  # starts unbiased. It no longer does, in the good direction: the MLO annual
  # residual mean is +0.97 ppm (obs above model), so shifting the model UP by
  # 1 ppm moves it TOWARD the observations and "cost(1)" is -68. The assertion
  # was measuring the model's level bias, not the price of a bias -- and it
  # broke twice as the level fit IMPROVED (RMS 3.04 -> 0.99 -> 1.13 across the
  # MM flip and item 5b), which is the signature of a fixture, not a guard.
  #
  # What the test is actually for: under the retired AR(1) scheme at rho =
  # 0.998 a +50 ppm bias cost 13.7 log-units IN TOTAL. The property that must
  # hold is that the objective has real CURVATURE in the level, wherever its
  # optimum happens to sit. So the cost is measured FROM THE FITTED OFFSET and
  # the guard is on the curvature, which is scale-free and cannot go stale.
  f <- lik_fixture()
  shift <- function(b) {
    o <- f$out; o$co2_NH <- o$co2_NH + b; o$co2_SH <- o$co2_SH + b
    ccx_loglik(o, f$obs, f$err)
  }
  # The uniform-shift profile is quadratic to numerical precision (the level
  # terms are Gaussian in it), so fit it rather than search: A is the total
  # level precision in log-units per ppm^2 and -B/2A is the fitted offset.
  bb  <- c(-4, -2, -1, 0, 1, 2, 4)
  ll  <- vapply(bb, shift, numeric(1))
  cf  <- stats::coef(stats::lm(I(ll - ll[bb == 0]) ~ 0 + bb + I(bb^2)))
  A   <- -cf[["I(bb^2)"]]          # curvature, log-units per ppm^2
  b0  <- cf[["bb"]] / (2 * A)      # fitted uniform offset, ppm
  # the quadratic must actually describe the profile, or A means nothing
  expect_gt(summary(stats::lm(I(ll - ll[bb == 0]) ~ 0 + bb + I(bb^2)))$r.squared, 0.999)

  # THE GUARD. Under AR(1) a 50 ppm bias cost 13.7 log-units in total, i.e. a
  # curvature of ~0.0055. Requiring A > 10 is a ~1800x margin over that
  # pathology while sitting a factor ~2.6 below the measured value (26.4), so
  # it has room for the model to keep improving without going stale.
  expect_gt(A, 10)

  # THE LEVEL BAR IS NOW DERIVED FROM AN OBSERVATION (2026-08-30, Marcus's
  # ruling), replacing a round `abs(b0) < 3` that tripped at 3.017 when
  # gamma_diff was adopted at 0.25.
  #
  # ⚠ THE OWED REFIT CANNOT MOVE THIS ONE, which is why it could not simply be
  # deferred like the other post-adoption failures: lik_fixture() runs on
  # ccx_default_params(), NOT the fitted mode, so re-fitting the 21 leaves it
  # exactly where it is. b0 is linear in gamma_diff -- 2.418 / 2.718 / 3.017 at
  # gamma = 0 / 0.125 / 0.25, +2.40 ppm per unit -- and was already at 81 % of
  # the old bar BEFORE the adoption, so the round number was going to fail on
  # the next change whatever it was.
  #
  # DERIVATION in calibration/diag_co2_level_bar.R; the short form is that a
  # uniform shift of the model is degenerate with a systematic level offset in
  # the record it is scored against, so the bar is that record's own level
  # uncertainty. LIK_ICE_REP_ERR is the repo's estimate of it (gas-age + firn
  # smoothing + model-vs-ice representation). The diagnostic also measures a
  # fully external FLOOR -- Law Dome against SPO over their 1962-1996 overlap,
  # like-for-like Antarctic, no model and no likelihood weight involved:
  # RMS 1.087 ppm -- which confirms the constant is 3.7x conservative rather
  # than fitted to fit. ⚠ The floor is BLIND to all three terms the bar
  # carries (both records there are modern, precise and Antarctic), so it
  # bounds from below and is NOT the bar.
  #
  # ⚠ AND THE COUPLING, SINCE THE RULE SAYS NAME IT: LIK_ICE_REP_ERR is inside
  # the objective that produces b0. It is not re-baselining, because the
  # dependence runs the wrong way to be self-satisfying -- inflating it
  # DOWN-weights the ice samples, pulling b0 toward the MLO/SPO-only optimum
  # rather than dragging b0 along with the bar.
  expect_lt(abs(b0), LIK_ICE_REP_ERR)
  # MUTATION TEST: a bar that passes is not a bar that works. A model whose
  # level is genuinely broken must trip it. Shifting the run by twice the bar
  # moves the fitted offset by the same amount, so the guard must fail there.
  bad <- local({
    o <- f$out; o$co2_NH <- o$co2_NH - 2 * LIK_ICE_REP_ERR
    o$co2_SH <- o$co2_SH - 2 * LIK_ICE_REP_ERR
    sh <- function(b) { q <- o; q$co2_NH <- q$co2_NH + b; q$co2_SH <- q$co2_SH + b
                        ccx_loglik(q, f$obs, f$err) }
    l <- vapply(bb, sh, numeric(1))
    c2 <- stats::coef(stats::lm(I(l - l[bb == 0]) ~ 0 + bb + I(bb^2)))
    c2[["bb"]] / (2 * -c2[["I(bb^2)"]])
  })
  expect_gt(abs(bad), LIK_ICE_REP_ERR)
  # ...and the direct AR(1) comparator, now measured from the optimum
  cost <- function(b) shift(b0) - shift(b0 + b)
  expect_gt(cost(50), 10000)
  expect_gt(cost(-50), 10000)
  # monotone in the DISTANCE from the optimum, in both directions
  expect_true(all(diff(vapply(c(0, 1, 5, 20, 50), cost, numeric(1))) > 0))
  expect_true(all(diff(vapply(c(0, -1, -5, -20, -50), cost, numeric(1))) > 0))
})

test_that("sigma_co2 cannot collapse: its profile peaks near the residual RMS", {
  skip_if_no_cpp()
  # SCOPE NOTE 2026-08-15 (item 6b): `sigma_co2` is RETIRED from
  # CCX_PARAM_TABLE. This test is unchanged and still passes -- it now gates
  # the LEGACY branch of ccx_loglik(), which every pre-retirement diagnostic
  # relies on and which must keep reproducing its old numbers. The contract for
  # the branch the OBJECTIVE now takes is gated separately, below.
  # RE-EXPRESSED 2026-08-15 (Marcus). The interior-maximum assertions below
  # still PASS and are unchanged. What failed was the last line, which compared
  # the AR(1)-collapsed 0.0744 against a hand-picked "sane" sigma of 5 -- and 5
  # is no longer sane. The likelihood uses sqrt(sigma_co2^2 + LIK_CO2_REP_ERR^2)
  # with LIK_CO2_REP_ERR fixed at 1.0 ppm, so sigma 0.0744 gives an EFFECTIVE sd
  # of 1.003 against a residual RMS of ~1.13, while sigma 5 gives 5.1. The
  # collapsed value legitimately beats 5 because the model now fits better than
  # a comparator chosen when it did not.
  #
  # AND THAT MATTERS BEYOND THIS TEST: handoff 2026-08-15 section 4.1 measured
  # that sigma_co2 -> 0 is the CORRECT inference here, not the AR(1) pathology
  # it resembles, precisely because the fixed 1.0 ppm constant already exceeds
  # the residual it explains. So the property to assert is NOT "small sigma is
  # bad" -- it is that the profile's optimum lands where the DATA put it. That
  # is derived from the residual, so it cannot go stale.
  f <- lik_fixture()
  grid <- c(0.05, 0.2, 1, 2, 5, 15, 40, 100)
  ll <- vapply(grid, function(s) {
    e <- f$err; e$sigma_co2 <- s; ccx_loglik(f$out, f$obs, e)
  }, numeric(1))
  # interior maximum -- not at either end, and in particular not railed at the
  # top, which is the flat-likelihood failure the AR(1) scheme's mirror image
  best <- which.max(ll)
  expect_gt(best, 1L)
  expect_lt(best, length(grid))

  # The pooled annual level residual, over BOTH stations, since sigma_co2 enters
  # both level terms. Measured here rather than stored.
  ms <- ccx_model_stats(f$out, f$obs)
  res <- unlist(lapply(c("MLO", "SPO"), function(st) {
    o <- f$obs$co2_ann[[st]]; m <- ms$co2[[st]]
    k <- match(o$year, m$year); g <- !is.na(k)
    o$level[g] - m$level[k[g]]
  }))
  rms <- sqrt(mean(res^2))
  # The profile's optimum, on a fine grid, expressed as the EFFECTIVE sd the
  # likelihood actually uses. It must sit within a factor of 1.5 of the residual
  # the model leaves -- which is the whole content of "peaks near the RMS".
  fine <- exp(seq(log(0.01), log(50), length.out = 400))
  llf  <- vapply(fine, function(s) {
    e <- f$err; e$sigma_co2 <- s; ccx_loglik(f$out, f$obs, e)
  }, numeric(1))
  eff <- sqrt(fine[which.max(llf)]^2 + LIK_CO2_REP_ERR^2)
  expect_gt(eff, rms / 1.5)
  expect_lt(eff, rms * 1.5)
})

# ---- 3b. the retirement of sigma_co2 (2026-08-15, review item 6b) ----
# The CO2 level sd is now LIK_CO2_REP_ERR alone. Three things have to hold and
# they are separable, so they are separate tests: the new branch must be the
# constant EXACTLY (not approximately, and not some other constant), the legacy
# branch must still reproduce, and the retirement must have HARDENED the stream
# rather than loosened it -- the direction matters, because loosening the
# loudest stream in a 40:1 objective would be a silent re-weighting.

.lik_co2_level_ll <- function(f, sd) {
  # The CO2 level terms, recomputed from the residual with an explicit sd.
  # Derived here rather than stored, so it cannot go stale against the model.
  ms <- ccx_model_stats(f$out, f$obs)
  sum(vapply(c("MLO", "SPO"), function(st) {
    o <- f$obs$co2_ann[[st]]; m <- ms$co2[[st]]
    k <- match(o$year, m$year); g <- !is.na(k)
    sum(stats::dnorm(o$level[g], m$level[k[g]], sd, log = TRUE))
  }, numeric(1)))
}

.lik_co2_level_parts <- function(f, err) {
  ps <- ccx_loglik(f$out, f$obs, err, by_stream = TRUE)
  ps[["co2_level_MLO"]] + ps[["co2_level_SPO"]]
}

test_that("with sigma_co2 absent the CO2 level sd is exactly LIK_CO2_REP_ERR", {
  skip_if_no_cpp()
  f <- lik_fixture()
  e <- f$err; e$sigma_co2 <- NULL
  expect_equal(.lik_co2_level_parts(f, e),
               .lik_co2_level_ll(f, LIK_CO2_REP_ERR), tolerance = 1e-10)
  # and it is not silently equivalent to some OTHER plausible constant --
  # a guard that reads the intended value rather than merely a self-consistent one
  expect_false(isTRUE(all.equal(.lik_co2_level_parts(f, e),
                                .lik_co2_level_ll(f, 2 * LIK_CO2_REP_ERR))))
  # sigma_co2 = 0 is the same arithmetic, which is why R/calibrate.R omits the
  # field rather than passing a zero: the two must agree TODAY so that a future
  # change to the contract shows up as a difference instead of a silent revert.
  e0 <- f$err; e0$sigma_co2 <- 0
  expect_equal(.lik_co2_level_parts(f, e0), .lik_co2_level_parts(f, e),
               tolerance = 1e-12)
})

test_that("supplying sigma_co2 still reproduces the pre-retirement quadrature", {
  skip_if_no_cpp()
  f <- lik_fixture()
  for (s in c(0.223, 1.5, 5)) {
    e <- f$err; e$sigma_co2 <- s
    expect_equal(.lik_co2_level_parts(f, e),
                 .lik_co2_level_ll(f, sqrt(s^2 + LIK_CO2_REP_ERR^2)),
                 tolerance = 1e-10)
  }
})

test_that("retiring sigma_co2 hardened the CO2 level stream, and only slightly", {
  skip_if_no_cpp()
  f <- lik_fixture()
  e <- f$err; e$sigma_co2 <- NULL
  now <- .lik_co2_level_parts(f, e)
  # DIRECTION: any positive sigma_co2 is a LOOSER sd, so the retired form must
  # score every residual set at least as tightly. Strict, because the fixture
  # has a non-zero residual.
  for (s in c(0.223, 1.5)) {
    eo <- f$err; eo$sigma_co2 <- s
    expect_lt(now, .lik_co2_level_parts(f, eo))
  }
  # MAGNITUDE: against the value the last mode actually chose, the weight change
  # is the variance ratio of the two sds, and it must stay small -- this is the
  # assertion that the retirement was not a stream re-weighting in disguise.
  SIGMA_AT_LAST_MODE <- 0.223          # calibration/diag_sigma_co2.R part 5
  wt <- (sqrt(SIGMA_AT_LAST_MODE^2 + LIK_CO2_REP_ERR^2) / LIK_CO2_REP_ERR)^2
  expect_lt(wt, 1.10)
  # and the parameter is genuinely gone from the objective
  expect_false("sigma_co2" %in% CCX_PARAM_NAMES)
  # `sigma_d13c` JOINED IT 2026-08-18 (Marcus). This line asserted it was still
  # free, which was the 2026-08-15 decision; that decision was reversed on
  # measurement, NOT on taste, so the assertion is inverted rather than deleted.
  # The premise was that a free scale on a MINOR stream is a robustness valve
  # rather than a feedback loop. calibration/diag_fit_at_mode.R measured it: the
  # d13C residual is BIAS not scatter (de-biased scatter 0.033 / 0.036 permil,
  # BELOW the 0.05 permil representation floor) while the parameter fitted
  # 0.1931 -- so it explained no scatter and absorbed a structural bias at 4x
  # the representation error. `sigma_d14c` stays free: its de-biased scatter is
  # 14.0 / 12.1 permil against an observational sd of ~4.2, which is real.
  expect_false("sigma_d13c" %in% CCX_PARAM_NAMES)
  expect_true("sigma_d14c" %in% CCX_PARAM_NAMES)
  # and the station-vs-box offset that replaced it in the count is present
  expect_true("rep_dC" %in% CCX_PARAM_NAMES)
})

test_that("the d13C seasonal cycle is scored, and through the NEP harmonic", {
  # Added 2026-08-18 (priority rework item 3). Two claims, both cheap to pin:
  # the streams EXIST in by_stream (the obs targets built, the term is on), and
  # they are WIRED to the seasonal NEP parameters -- if a future change severs
  # d13C from the NEP harmonic, this is what says so.
  skip_if_no_cpp()
  obs <- ccx_prepare_obs()
  expect_false(is.null(obs$d13_seas$MLO))
  expect_false(is.null(obs$d13_seas$SPO))
  expect_true(LIK_USE_D13C_SEAS)
  run_ll <- function(p) {
    sp <- ccx_spinup(p)
    F <- ccx_build_forcing("historical", c(1960, 2024), prod_c14 = sp$prod_c14)
    out <- ccx_run_fast(sp, F)$out
    ccx_loglik(out, obs, list(sigma_d14c = 5, grad_off_co2 = 0, grad_off_d13c = 0),
               by_stream = TRUE)
  }
  p <- ccx_default_params(); p <- ccx_set_enso(p, list(gamma_enso = 0.5))
  l0 <- run_ll(p)
  expect_true(all(c("d13c_seasonal_MLO", "d13c_seasonal_SPO") %in% names(l0)))
  # seas_T_amp_NH, not seas_amp_NH: the default model runs the DRIVER seasonal
  # path (2026-08-18), where seas_amp_* is inert -- perturbing it here would
  # make this a test that can never fail.
  p2 <- p; p2$seas_T_amp_NH <- p$seas_T_amp_NH * 1.5
  l1 <- run_ll(p2)
  expect_gt(abs(l1[["d13c_seasonal_MLO"]] - l0[["d13c_seasonal_MLO"]]), 1)
})

test_that("rep_dC ties the CO2 and d13C level offsets to ONE knob", {
  # THE SAFETY ARGUMENT FOR THE SHARED PARAMETER, pinned. If these two could
  # move independently it would be a free d13C level offset in disguise, and it
  # would absorb the Suess overshoot instead of exposing it. Full derivation and
  # the 30x measurement: calibration/diag_rep_dC_gates.R.
  skip_if_no_cpp()
  obs <- ccx_prepare_obs()
  p <- ccx_default_params(); sp <- ccx_spinup(p)
  F <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = sp$prod_c14)
  out <- ccx_run_fast(sp, F)$out
  ms <- ccx_model_stats(out, obs)
  bias <- function(rep) {
    bc <- mean(sapply(c("MLO","SPO"), function(st) {
      o <- obs$co2_ann[[st]]; mm <- ms$co2[[st]]
      k <- match(o$year, mm$year); g <- !is.na(k)
      mean(o$level[g] - (mm$level[k[g]] - rep)) }))
    bd <- mean(sapply(c("MLO","SPO"), function(st) {
      o <- obs$d13_ann[[st]]; mm <- ms$d13[[st]]
      k <- match(o$year, mm$year); g <- !is.na(k)
      pr <- mm$level[k[g]]
      cb <- ms$co2[[st]]$level[match(o$year[g], ms$co2[[st]]$year)]
      if (rep != 0) pr <- pr - rep * (LIK_REP_SOURCE_D13C - pr) / cb
      mean(o$level[g] - pr) }))
    c(bc, bd)
  }
  b0 <- bias(0); b1 <- bias(1); bm <- bias(-1)
  # CO2 offset is exactly 1 ppm per ppm of rep_dC, by construction
  expect_equal(unname(b1[1] - b0[1]), 1, tolerance = 1e-8)
  # d13C moves in the mass-balance ratio, and NEGATIVELY: rep_dC > 0 means the
  # box holds the extra LIGHT carbon, so the station is the heavier one.
  ratio <- (b1[2] - b0[2]) / (b1[1] - b0[1])
  expect_lt(ratio, 0)
  yrs <- Reduce(intersect, lapply(c("MLO","SPO"), function(st) obs$d13_ann[[st]]$year))
  d13_bg <- mean(sapply(c("MLO","SPO"), function(st) {
    o <- obs$d13_ann[[st]]; mean(o$level[o$year %in% yrs]) }))
  co2_bg <- mean(sapply(c("MLO","SPO"), function(st) {
    o <- obs$co2_ann[[st]]; mean(o$level[o$year %in% yrs]) }))
  expect_lt(abs(ratio / ((LIK_REP_SOURCE_D13C - d13_bg) / co2_bg) - 1), 0.15)
  # and it is ONE knob: the ratio must not depend on rep_dC
  expect_equal((bm[2] - b0[2]) / (bm[1] - b0[1]), ratio, tolerance = 1e-6)
})

test_that("the seasonal statistic constrains amplitude and phase", {
  skip_if_no_cpp()
  obs <- ccx_prepare_obs()
  err <- list(sigma_co2 = 1.5, sigma_d13c = 0.1, sigma_d14c = 5)
  seas_ll <- function(amp, phase) {
    p <- ccx_default_params(); p <- ccx_set_enso(p, list(gamma_enso = 0.5))
    # seas_drivers = 0: this test instruments the seasonal STATISTIC through
    # the sine's amp/phase knobs, which are inert on the driver path. The sine
    # is the cleanest instrument for the statistic; the DRIVER path's own
    # wiring is tested separately (the d13c-seasonal test perturbs seas_T_amp).
    p$seas_drivers <- 0
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

test_that("the deep ocean is where GLODAP puts it -- the OBSERVABLE kz stands in for", {
  # ⭐ THE REPLACEMENT FOR THE RETIRED `kz$hi <= 7000` (2026-09-04). The project
  # cares that the model's deep water is as old as the ocean's actually is; `kz`
  # is only the knob that gets it there, and bounding a knob is not testing that.
  # This asserts the thing itself, at the CANONICAL mode, against the SOURCED
  # target the likelihood scores -- GLODAPv2, bottom box 2627.2-3700 m.
  #
  # ⚠ THE TOLERANCE IS THE TARGET'S OWN SIGMA, not a chosen number, and the
  # target is READ from ccx_deep_d14c_target() rather than retyped -- retyping is
  # exactly how the "-150 to -200" recollection outlived its own evidence
  # ([[derived_must_mean_computed]]).
  # Harmonised with GATE 5/7/Q/G/S's DG_*_NSD, named here rather than typed twice.
  CCX_DEEP_D14C_NSD <- 2
  skip_if_no_cpp()
  tg <- ccx_deep_d14c_target()
  skip_if(is.null(tg), "no sourced deep-D14C target on this install")
  md <- readRDS(ccx_mode_file())
  p  <- ccx_overlay_par(ccx_mode_base(md), md$par_mode)   # the file's own structure (09-08f)
  p$pump_mode <- md$pump_mode
  # under the FILE'S OWN spinup (periodic since 09-09x), not ccx_spinup(): the
  # canonical was fitted under it, and the aseasonal read is off-mode (review
  # A15; 0.25 permil = 0.024 sigma here, but the number under test is the mode's)
  deep <- ccx_spinup_from_label(ccx_mode_spinup(md))(p)$diagnostics$d14c_bottom_box
  expect_true(is.finite(deep))
  z <- (deep - tg$target) / tg$sd
  # ⚠ MEASURED +1.86 at `ent26` on 2026-09-04: INSIDE, but on the young/
  # better-ventilated side and NOT comfortably so -- the margin to the bound is
  # about 450 m2/yr of `kz`. That thinness is information, not a nuisance: the
  # model really does sit near the edge of the observation.
  #
  # ⭐ MUTATION-TESTED ACROSS `kz`, and the table is worth keeping because it says
  # something the bracket does not:
  #
  #     kz      4379.1   5000    6356.2    7000    8109.9   10686
  #     deep    -196.94 -181.05  -156.14  -147.41 -135.36  -116.49
  #     z        -2.11   -0.57    +1.86    +2.71   +3.89    +5.73
  #     verdict  FAIL    PASS   PASS(mode)  FAIL    FAIL     FAIL
  #
  # It fails at the runaway that motivated the original bound (10,686, z +5.73),
  # which is the mutation that matters. ⚠ AND IT FAILS AT BOTH ENDPOINTS OF THE
  # SHIPPED BRACKET [4379.1, 8109.9]. That is not a contradiction -- a prior
  # SUPPORT is not a 2-sigma confidence interval, and the 09-01 bisection recipe
  # never claimed to be one -- but it does mean the retired comment's promise,
  # "the range that keeps deep-ocean D14C inside the observed range", was not
  # literally true at the bracket's own edges. The observationally admissible
  # window at 2 sigma is roughly kz in (4400, 6800); the fit lands at 6356.
  # expect_true(), not expect_lt(): only the former carries `info`, and a bare
  # "2.13 is not less than 2" would send the next reader to re-derive the numbers
  # this failure is entirely about.
  expect_true(abs(z) < CCX_DEEP_D14C_NSD,
              info = sprintf("deep-ocean D14C %.2f permil vs GLODAP %.2f +/- %.2f (z %+.2f)",
                             deep, tg$target, tg$sd, z))
})

test_that("rho is gone and the parameter vector is self-consistent", {
  expect_false("rho" %in% CCX_PARAM_NAMES)
  # 17 -> 16 on 2026-08-12 (Marcus): the land layout is STRUCTURE, not calibrated.
  # 16 -> 17 on 2026-08-14: `luc_scale`, the land-use INPUT-uncertainty parameter.
  # A bare count only records the change; the assertions below GUARD the decisions,
  # because all three were made after a mode fit walked straight through them.
  #
  # This assertion did its job -- it is the tripwire that flagged the 17th
  # parameter, and the addition is recorded here rather than the count being
  # quietly bumped. `luc_scale` is the OPPOSITE of the freeing that decision 1
  # forbids: it gives a prescribed INPUT its own stated uncertainty (GCB 2025's
  # +/-0.7 GtC/yr; OSCAR's 206 +/- 57 PgC) so that uncertainty stops being
  # absorbed by `beta`, which was paying ~30 ppm of it at the cost of two of
  # DESIGN sec.6's hard gates. See CCX_PARAM_TABLE$luc_scale and
  # calibration/diag_luc_scale.R.
  #
  # 17 -> 18 on 2026-08-14 (later): the fertilisation FORM changed. `beta` LEFT
  # the table and `beta_max` + `fert_k` entered it, so the count moved by one
  # while the fertilisation block moved from one parameter to two. This is NOT a
  # reparameterisation -- as fert_k -> Inf, MM goes LINEAR, not logarithmic, so
  # no substitution carries a `beta` posterior across and any pre-flip posterior
  # in calibration/output/ belongs to a DIFFERENT MODEL. The assertions below
  # guard exactly that, because splicing one in is the plausible mistake.
  #
  # 18 -> 20 on 2026-08-15 (review item 5): `grad_off_co2` and `grad_off_d13c`,
  # the interhemispheric-gradient representation offsets. Recorded here rather
  # than bumped, and they are the SAME KIND of addition as `luc_scale` -- they
  # give a prescribed comparison its own stated uncertainty so that uncertainty
  # stops being absorbed by a physical parameter. A two-box model's
  # NH-box-minus-SH-box is not what MLO minus SPO measures; MLO sits south of
  # the northern source region, and the offset is measured at -0.45 +/- 0.10 ppm
  # with the sign that argument predicts. Fixed at zero it would have gone onto
  # `tau_ex` and the hemispheric shares and been reported as a calibrated
  # exchange time. See CCX_PARAM_TABLE$grad_off_co2 and
  # calibration/diag_gradient_terms.R part 3.
  #
  # NOTE the d13C one is NOT the same animal despite the matching name: its
  # offset is 8x larger than the station-latitude argument predicts, so it is
  # absorbing the known structural d13C misfit and its prior is deliberately
  # wide. That distinction is asserted below.
  #
  # 20 -> 19 on 2026-08-15 (review item 6b, Marcus): `sigma_co2` RETIRED. The
  # CO2 level sd is now LIK_CO2_REP_ERR alone -- the half of the old quadrature
  # that has a receipt (co-located MLO programmes disagree 0.39-0.59 ppm RMS).
  # RECORDED, NOT MERELY BUMPED, and the reason matters because it is NOT the
  # one the handoffs gave: the "boundary-pinned / unidentified / bad
  # conditioning" case was measured and failed on all three counts
  # (calibration/diag_sigma_co2.R). What it was retired for is that a free error
  # scale on the stream that already outvotes the partition terms 40:1 is
  # SELF-WEIGHTING -- the better CO2 fitted, the louder CO2 got, 2.04x across
  # the two points measured. The weight change from fixing it is 1.05x, which
  # is asserted separately so this ledger cannot absorb a re-weighting.
  # 19 -> 20 on 2026-08-16d (Marcus): `pump_grad` FITTED, the biological pump's
  # magnitude. Its prior is centred on the OBSERVED gradient (`PUMP_GRAD_OBS`),
  # not on the 274.5 the four-row objective prefers, because that optimum is
  # conditional on a `kz` the refit will move. Fitted rather than fixed because
  # the profile and the degeneracy check both cleared it: rho(pump_grad, kz) =
  # -0.17 and the marginal sd is 1.01x the conditional, so it is not `kz` in
  # disguise (calibration/diag_pump_kz_degeneracy.R).
  # 21 since 2026-08-18, reshaped three times that day: sigma_d13c -> rep_dC
  # (constant count), the seasonal sine's 4 knobs -> 3 driver knobs
  # (seas_T_amp_NH/SH, seas_lag_p; 20 -> 19), then the seasonal-SST pair
  # (sst_seas_amp_NH/SH; 19 -> 21) when Marcus moved the SST fix ahead of the
  # refit so the ocean half of the seasonal cycle is calibrated WITH the land
  # half rather than being faked by it.
  # 22 SINCE 2026-08-31: `seas_lag_p` split into `seas_lag_p_NH`/`_SH` on
  # Marcus's design call (option A of the 08-29 whole-model assessment). The
  # lag was the one seasonal TIMING parameter still global while every
  # seasonal AMPLITUDE was already a per-hemisphere pair, and that asymmetry
  # was measured at -838 conditional with the NH paying 94 %.
  # 25 SINCE 2026-09-01: `gamma_enso` split into gamma_enso_land_NH/_SH +
  # gamma_enso_ocn_NH/_SH on Marcus's design call (handoff 2026-09-01, the ENSO
  # arc). The scalar moved LAND ONLY, split 50/50 by a hardcoded share, and the
  # model's OCEAN ENSO response was measured ANTI-correlated with the observed
  # one -- r = -0.51 [-0.68, -0.28] against +0.535 [+0.29, +0.72], powered and
  # detrend-invariant. The two errors compensate 87 % in CO2 growth, which is
  # why a fit that outvotes partition 40:1 never forced them.
  # 26 SINCE 2026-09-03: `ent_seas_amp_SH` entered the table on Marcus's design
  # call. The Southern-Ocean entrainment channel had been IMPLEMENTED, DEFAULTED
  # TO 0 AND UNFITTED since 2026-08-27g while the model's WORST prior violation
  # was the SOLUBILITY amplitude it stands in for (`sst_seas_amp_SH`, prior-z
  # -5.14) and the SH ocean seasonal limb still landed 4.33 months from the
  # observed one (GATE S, first measured the same day: z -12.30, FAIL).
  # ⛔ Freeing it is a TEST, not an adoption: the acceptance criterion is
  # whether that -5.14 RELAXES, not whether the logpost rises.
  # 28 SINCE 2026-09-06d: kz_deep_frac and hs_asx_frac, the two FITTED
  # structure parameters of the HILDA refit (Marcus's ruling, prereg 09-07).
  # 29 SINCE 2026-09-07: h_hs fitted (decoupled from h_ml after the first refit).
  # 33 SINCE 2026-09-13i: w_eq and gamma_eq, the equatorial cell's two fitted names
  # (identifiable only under the "hilda_eq" structure label).
  expect_length(CCX_PARAM_NAMES, 33L)
  expect_true(all(c("kz_deep_frac", "hs_asx_frac", "h_hs", "pump_hs_gcm2", "u_hs", "w_eq", "gamma_eq") %in% CCX_PARAM_NAMES))
  expect_true("ent_seas_amp_SH" %in% CCX_PARAM_NAMES)
  expect_true(all(CCX_ENSO_PARAMS %in% CCX_PARAM_NAMES))
  expect_false("gamma_enso" %in% CCX_PARAM_NAMES)
  expect_true(all(c("seas_T_amp_NH", "seas_T_amp_SH",
                    "seas_lag_p_NH", "seas_lag_p_SH",
                    "sst_seas_amp_NH", "sst_seas_amp_SH") %in% CCX_PARAM_NAMES))
  # the retired global name must be GONE, not merely unused -- a list carrying
  # it is a pre-split list and must take ccx_seas_lag_p()'s legacy branch
  expect_false("seas_lag_p" %in% CCX_PARAM_NAMES)
  expect_false(any(c("seas_amp_NH", "seas_phase_NH") %in% CCX_PARAM_NAMES))
  expect_true("pump_grad" %in% CCX_PARAM_NAMES)
  # the prior is anchored on the OBSERVATION, not on the fit -- if this ever
  # ties to 274.5 a stale-`kz` optimum has been laundered into a constant
  expect_equal(CCX_PARAM_TABLE$pump_grad$init, ccx_const("PUMP_GRAD_OBS"),
               tolerance = 1e-12)
  expect_false("sigma_co2" %in% CCX_PARAM_NAMES)
  expect_true(all(c("grad_off_co2", "grad_off_d13c") %in% CCX_PARAM_NAMES))
  # both are shrinkage priors CENTRED AT ZERO -- centring them on the measured
  # offsets would tell the model the answer and then credit it for agreeing
  # npp_frac_NH's centre is a CONSTANT and its `init` is a literal, because
  # R/calibrate.R sources before R/constants.R. That is exactly the drift risk
  # this file exists to close: if the anchor is ever re-derived (a new NPP
  # product, a materially different luc_scale) and the literal is not, the
  # prior's mode and its starting point would disagree silently.
  expect_equal(CCX_PARAM_TABLE$npp_frac_NH$init,
               ccx_const("NPP_FRAC_NH_ANCHOR_1750"), tolerance = 1e-12)
  # ...and the prior really is centred there, not merely started there.
  a <- ccx_const("NPP_FRAC_NH_ANCHOR_1750")
  expect_gt(CCX_PARAM_TABLE$npp_frac_NH$prior(a),
            CCX_PARAM_TABLE$npp_frac_NH$prior(a + 0.01))
  expect_gt(CCX_PARAM_TABLE$npp_frac_NH$prior(a),
            CCX_PARAM_TABLE$npp_frac_NH$prior(a - 0.01))
  # The anchor is NOT the observation -- it is the observation walked back to
  # 1750 through hemispheric clearing, so it must sit ABOVE the modern share.
  # An equality here would mean someone centred the prior on the wrong quantity.
  expect_gt(a, ccx_const("NPP_FRAC_NH_OBS"))
  expect_lt(a - ccx_const("NPP_FRAC_NH_OBS"), 0.05)
  expect_equal(CCX_PARAM_TABLE$grad_off_co2$init,  0)
  expect_equal(CCX_PARAM_TABLE$grad_off_d13c$init, 0)
  for (n in c("grad_off_co2", "grad_off_d13c")) {
    pr <- CCX_PARAM_TABLE[[n]]$prior
    expect_equal(pr(0.3), pr(-0.3), tolerance = 1e-12)   # symmetric about 0
    expect_gt(pr(0), pr(0.3))                            # and peaked there
  }
  expect_true("luc_scale" %in% CCX_PARAM_NAMES)
  expect_true(all(c("beta_max", "fert_k") %in% CCX_PARAM_NAMES))
  expect_false("beta" %in% CCX_PARAM_NAMES)
  # ...but `beta` must stay in ccx_default_params(), because CCX_FERT_LOG is
  # what reproduces every pre-flip result and it needs a value to run.
  expect_true("beta" %in% names(ccx_default_params()))
  # ...and it must stay an INPUT scale, never a model parameter: nothing may
  # inject it into ccx_default_params(), where it would silently rescale every
  # diagnostic that does not know about it.
  expect_false("luc_scale" %in% names(ccx_default_params()))

  # DECISION 1: the whole land layout is fixed. A free tau_soil_fast reached
  # +3.61 sigma and put the biosphere bomb-14C back to +50 %/+64 %, undoing the
  # four-pool restructure. Nothing in the likelihood scores the partition, so the
  # freeze is the only thing holding it.
  for (n in c("tau_soil_fast", "tau_soil_slow", "tau_leaf", "tau_wood",
              "npp_leaf_frac", "litter_slow_frac"))
    expect_false(n %in% CCX_PARAM_NAMES, info = n)

  # DECISION 2: kz is BOUNDED, because unbounded it ran to 10,686 and put the
  # deep ocean at -129.9 permil. The bounds are bisected values, so assert the
  # transform is actually a bounded one -- a silent revert to tr = "log" would
  # restore the runaway with no other visible symptom.
  expect_identical(CCX_PARAM_TABLE$kz$tr, "logit")
  # =================================================================
  # ⛔ `expect_lte(CCX_PARAM_TABLE$kz$hi, 7000)` STOOD HERE AND IS REMOVED
  # (2026-09-04, Marcus's ruling). It had been failing since the 2026-09-01
  # re-bisection moved `kz$hi` to 8109.9, and the reason it failed is that it was
  # never a test of the model.
  #
  # ⭐ THE RULING, AND IT GENERALISES: "the only tests that matter are the ones
  # against observations or physics." `kz` is NOT directly observed. The
  # deep-ocean Delta14C IS. This line bounded the SUPPORT OF A LATENT PARAMETER
  # and justified itself by naming an observation -- "the range that keeps
  # deep-ocean D14C inside the observed -150 to -200" -- which R/calibrate.R's
  # own header records as AN UNCITED RECOLLECTION, and on the bottom THREE boxes
  # rather than the bottom box the likelihood actually scores. The 09-01
  # re-bisection replaced it with GLODAPv2's sourced -175.26 +/- 10.259 permil,
  # which is precisely WHY `kz$hi` moved past 7000. So the assertion was failing
  # against a number the project had already retired.
  #
  # ⚠ AND IT COULD NOT HAVE CAUGHT ANYTHING: measured at the adopted `ent26`
  # mode, `kz` is 6356 -- BELOW the 7000 it bounded -- while the observable it
  # invoked sits at z = +1.86, inside 2 sigma. A gate on the bracket's ceiling
  # cannot fail when the fit does, and cannot pass when the fit is wrong
  # [[no_power_null]]. What replaces it is the observation itself, below.
  # =================================================================
  # =================================================================
  # 2026-09-06d: THE COLUMN-ERA GUARDS ARE RETIRED WITH THE COLUMN. Marcus's
  # ruling re-bisected `kz` on the 36-box STRUCTURE (HILDA HS/HD + K(z)),
  # where the bottom box is set by K_deep = kz_deep_frac * kz and the conduit,
  # not by `kz` alone. The three assertions that stood here --
  #   lo >= 3500; hi < 10686 (the 17-parameter runaway); init = the arithmetic
  #   centre --
  # were all statements about a column in which `kz` alone set the deep. On
  # the structure at f = 0.05, kz = 10686 puts the bottom box at ~+0.9 sigma:
  # the deep row does not reject the runaway through `kz` alone any more, it
  # rejects it through f * kz, and a ceiling below 10686 would only forbid the
  # thermocline diffusivity the sink needs. So the claim that is now checkable
  # is that the SHIPPED box IS the k = 3 sigma bisection on the structure
  # (calibration/diag_kz_bracket_hilda36.R -- a product this table did not
  # write, [[gate_reads_its_own_output]]), and that init is its GEOMETRIC
  # centre (the arithmetic centre of a 24x box is 2.3x the working arm).
  # =================================================================
  bis <- tryCatch(readRDS(ccx_path("outputs", "diagnostics", "kz_bracket_hilda36_20260906.rds")),
                  error = function(e) NULL)
  skip_if(is.null(bis), "36-box bisection product absent")
  b3 <- bis$res[bis$res$k == 3, ]
  expect_equal(c(CCX_PARAM_TABLE$kz$lo, CCX_PARAM_TABLE$kz$hi),
               round(c(b3$kz_lo, b3$kz_hi), 1), tolerance = 1e-8)
  expect_equal(CCX_PARAM_TABLE$kz$init,
               sqrt(CCX_PARAM_TABLE$kz$lo * CCX_PARAM_TABLE$kz$hi),
               tolerance = 1e-5)   # the TYPED precision of the init (0.1 m2/yr on 5683.5)
  # round-trip through the unconstrained transform
  u <- ccx_init_unc()
  expect_named(u, CCX_PARAM_NAMES)
  back <- ccx_unc_to_par(u)
  for (n in CCX_PARAM_NAMES)
    expect_equal(back[[n]], CCX_PARAM_TABLE[[n]]$init, tolerance = 1e-10, info = n)
})

# ---- 4. the ocean excess-14C inventory constraint ---------------------

test_that("the ocean excess-14C term is PRESENT in the standard pipeline", {
  skip_if_no_cpp()
  # The term skips itself if the run does not start at the spinup year, which is
  # the right behaviour but also a silent way to lose a constraint. This asserts
  # that under the configuration the calibration actually uses, it is scored.
  f <- lik_fixture()
  parts <- ccx_loglik(f$out, f$obs, f$err, by_stream = TRUE)
  expect_true("excess_c14_ocean" %in% names(parts))
  expect_true(is.finite(parts[["excess_c14_ocean"]]))
  expect_equal(f$obs$excess_c14$target, LIK_EXCESS_C14_TARGET)
})

test_that("the excess-14C term refuses to score off a wrong baseline", {
  skip_if_no_cpp()
  # Started at 1900, out$ocean_C14[1] is not the natural inventory. Scoring it
  # anyway would compare a 150-year-old excess to a 1750 one and quietly reward
  # whatever parameters happened to shrink the difference.
  obs <- ccx_prepare_obs()
  p <- ccx_default_params(); p <- ccx_set_enso(p, list(gamma_enso = 0.5))
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", c(1900, 2024), prod_c14 = sp$prod_c14)
  parts <- ccx_loglik(ccx_run_fast(sp, F)$out, obs,
                      list(sigma_co2 = 1.5, sigma_d13c = 0.1, sigma_d14c = 5),
                      by_stream = TRUE)
  expect_false("excess_c14_ocean" %in% names(parts))
})

test_that("the excess-14C term bites: it is monotone in bomb_total", {
  skip_if_no_cpp()
  # The constraint exists to price the ocean sink independently of the
  # atmospheric decline. A term that did not move with the size of the bomb
  # source would be decoration.
  obs <- ccx_prepare_obs()
  err <- list(sigma_co2 = 1.5, sigma_d13c = 0.1, sigma_d14c = 5)
  p <- ccx_default_params(); p <- ccx_set_enso(p, list(gamma_enso = 0.5))
  sp <- ccx_spinup(p)
  term <- function(bt) {
    F <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = sp$prod_c14,
                           bomb_total_kmol = bt)
    ccx_loglik(ccx_run_fast(sp, F)$out, obs, err,
               by_stream = TRUE)[["excess_c14_ocean"]]
  }
  # 102 kmol is the citable Naegler & Levin total; 151 is where the 2026-08-11
  # mode sat. The observationally-constrained ocean must prefer the former.
  expect_gt(term(102), term(151))
  expect_gt(term(102), term(60))          # and it is not simply "smaller is better"
})

test_that("the shared method error is rank one, not per-year quadrature", {
  # Independent quadrature would claim more information than two estimates from
  # overlapping reconstructions carry. The off-diagonal is the whole point.
  e <- ccx_excess_c14_target(readRDS(ccx_path("data", "obs_excess_c14.rds")))
  expect_gt(e$Sigma[1, 2], 0)
  expect_equal(e$Sigma[1, 2], e$rep[1] * e$rep[2], tolerance = 1e-12)
  expect_equal(diag(e$Sigma), e$half_width^2 + e$rep^2, tolerance = 1e-12)
  # a correlated pair penalises a COMMON offset less than an opposing one
  quad <- function(r) drop(crossprod(r, e$prec %*% r))
  expect_lt(quad(c(10, 10)), quad(c(10, -10)))
})

test_that("by_stream decomposes exactly into the total", {
  skip_if_no_cpp()
  f <- lik_fixture()
  parts <- ccx_loglik(f$out, f$obs, f$err, by_stream = TRUE)
  expect_equal(sum(parts), ccx_loglik(f$out, f$obs, f$err), tolerance = 1e-9)
  expect_true(all(is.finite(parts)))
})

# ---- 5. the deep-ocean D14C term (2026-08-14) ------------------------
# Marcus' decision 1 chose sigma = spread / sqrt(n_eff = 20) and, on the same
# numbers, chose to KEEP the kz bracket. Three of the four tests below guard
# that decision rather than the arithmetic, because the arithmetic is easy and
# the decision is what a later session would undo by accident.

test_that("the deep-D14C sigma DERIVES from n_eff, with no second literal", {
  tg <- ccx_deep_d14c_target()
  skip_if(is.null(tg), "GLODAPv2 build product absent")
  # the whole point of computing it: changing LIK_D14C_DEEP_NEFF cannot leave a
  # stale sigma behind, because there is nowhere for one to hide.
  expect_equal(tg$sd, tg$sd_spread / sqrt(tg$n_eff), tolerance = 1e-12)
  expect_equal(ccx_deep_d14c_target(n_eff = 1)$sd, tg$sd_spread, tolerance = 1e-12)
  expect_equal(tg$n_eff, LIK_D14C_DEEP_NEFF)
  # THE SPREAD IS NOT THE SIGMA -- 13i sec.A3's assumption, inverted by the data.
  expect_gt(tg$sd_spread, 4 * tg$sd)
})

test_that("the term scores the BOTTOM BOX, not the 3-box 'deep' average", {
  # The target is a volume-weighted GLODAPv2 mean over 2627-3700 m. The older
  # `d14c_deep_ocean` diagnostic is 1313.6-3700 m. They are NOT interchangeable
  # and this test exists because they were interchanged once already.
  tg <- ccx_deep_d14c_target()
  skip_if(is.null(tg), "GLODAPv2 build product absent")
  expect_equal(unname(tg$layer[["bottom"]]), ccx_const("OCEAN_DEPTH"))
  d <- ccx_spinup(ccx_default_params())$diagnostics
  expect_true(is.finite(d$d14c_bottom_box))
  # the 3-box slab is materially enriched; if these ever converge the grid has
  # changed and the target's depth range has to be rebuilt with it.
  expect_gt(d$d14c_deep_ocean - d$d14c_bottom_box, 10)
  # the bottom box is the deeper, older water
  expect_lt(d$d14c_bottom_box, d$d14c_deep_ocean)
})

test_that("the term HOLDS kz at the chosen sigma -- decision 1's whole basis", {
  tg <- ccx_deep_d14c_target()
  skip_if(is.null(tg), "GLODAPv2 build product absent")
  # The 17-parameter unbounded mode ran kz to 10,686. On the COLUMN the term
  # rejects that on its own (measured 5.3 sigma at n_eff = 20) -- still true,
  # and still the reason the bracket exists as a support.
  p <- ccx_default_params(); p$kz <- 10686
  runaway <- ccx_spinup(p)$diagnostics$d14c_bottom_box
  expect_gt(abs(runaway - tg$target) / tg$sd, 2)
  # ...and the converse: expressed on this same quantity the SHIPPED bracket is
  # the observation's own 3-sigma box -- ON THE STRUCTURE IT WAS BISECTED FOR
  # (2026-09-06d: HILDA's boxes + K(z) declared, the two fitted structure
  # parameters at their table inits, pump ON at the observed gradient, mode N;
  # the recipe of calibration/diag_kz_bracket_hilda36.R). READS THE SHIPPED
  # BRACKET rather than repeating its endpoints, as before.
  pb <- ccx_apply_structure(ccx_default_params(), "hilda")
  pb$pump_grad <- ccx_const("PUMP_GRAD_OBS"); pb$pump_mode <- "N"
  pb$kz_deep_frac <- CCX_PARAM_TABLE$kz_deep_frac$init
  pb$hs_asx_frac  <- CCX_PARAM_TABLE$hs_asx_frac$init
  lo <- ccx_spinup(within(pb, kz <- CCX_PARAM_TABLE$kz$lo))$diagnostics$d14c_bottom_box
  hi <- ccx_spinup(within(pb, kz <- CCX_PARAM_TABLE$kz$hi))$diagnostics$d14c_bottom_box
  # a 3-sigma box to the bisection's own tolerance (0.5 m2/yr on kz), and not narrower than 2.9
  expect_lt((hi - lo) / 2, 3 * tg$sd * (1 + 1e-3))
  expect_gt((hi - lo) / 2, 2.9 * tg$sd)
  expect_lt(abs(0.5 * (hi + lo) - tg$target), 0.05 * tg$sd)   # centred on the target
})

test_that("the deep term is absent without `deep`, Gaussian with it", {
  skip_if_no_cpp()
  skip_if(is.null(ccx_deep_d14c_target()), "GLODAPv2 build product absent")
  f <- lik_fixture()
  bare <- ccx_loglik(f$out, f$obs, f$err, by_stream = TRUE)
  # ABSENT, not a silent zero: a missing steady-state value must be visible.
  expect_false("d14c_deep_ocean" %in% names(bare))
  tg <- ccx_deep_d14c_target()
  with_deep <- function(v) ccx_loglik(f$out, f$obs, f$err, deep = v, by_stream = TRUE)
  parts <- with_deep(tg$target)
  expect_true("d14c_deep_ocean" %in% names(parts))
  # at the target the term is the Gaussian normalisation alone
  expect_equal(unname(parts[["d14c_deep_ocean"]]),
               stats::dnorm(0, 0, tg$sd, log = TRUE), tolerance = 1e-10)
  # quadratic: a 2-sigma miss costs 4x a 1-sigma miss
  cost <- function(z) parts[["d14c_deep_ocean"]] -
    with_deep(tg$target + z * tg$sd)[["d14c_deep_ocean"]]
  expect_equal(cost(2), 4 * cost(1), tolerance = 1e-8)
  expect_equal(cost(1), 0.5, tolerance = 1e-8)
  # and by_stream still decomposes exactly into the total
  expect_equal(sum(parts),
               ccx_loglik(f$out, f$obs, f$err, deep = tg$target), tolerance = 1e-9)
})

# =====================================================================
# Where the gradient fixtures below evaluate sigma_eff. 100 m is where the model's
# surface box IS the shipped 0-100 m layer, so it is the representation error's
# own floor -- the least arbitrary point to assert Gaussian shape at.
SD_EFF_H <- 100

# The ocean DIC / d13C GRADIENT terms (task 12; Marcus 2026-08-16)
# =====================================================================

test_that("the gradient terms are absent without `ocean_grad`, Gaussian with it", {
  skip_if_no_cpp()
  tg <- ccx_ocean_gradient_target()
  skip_if(is.null(tg), "GLODAPv2 gradient block absent")
  f <- lik_fixture()
  bare <- ccx_loglik(f$out, f$obs, f$err, by_stream = TRUE)
  # ABSENT, not a silent zero -- the same visible-absence contract the deep
  # D14C term uses, and the thing the h_ml gate relies on to be legible.
  expect_false("ocean_grad_dic"  %in% names(bare))
  expect_false("ocean_grad_d13c" %in% names(bare))
  # Since option 5 was adopted (2026-08-28) the rows are scored at sigma_eff(h_ml),
  # which ccx_ocean_grad_scored() attaches; a hand-built ocean_grad must carry it
  # or ccx_loglik() STOPS. The Gaussian properties below are unchanged -- they are
  # simply asserted at sigma_eff rather than the retired sigma_obs.
  se <- vapply(c("dic", "d13c", "alk"), ccx_ocean_sigma_eff, numeric(1), h_ml = SD_EFF_H)
  at <- function(dic, d13c) ccx_loglik(f$out, f$obs, f$err, by_stream = TRUE,
                                       ocean_grad = list(dic = dic, d13c = d13c,
                                                         sd_eff = se))
  p0 <- at(tg$dic$target, tg$d13c$target)
  expect_true(all(c("ocean_grad_dic", "ocean_grad_d13c") %in% names(p0)))
  expect_equal(unname(p0[["ocean_grad_dic"]]),
               stats::dnorm(0, 0, se[["dic"]], log = TRUE), tolerance = 1e-10)
  # quadratic, and a 1-sigma_eff miss costs exactly 0.5
  cost <- function(z) p0[["ocean_grad_dic"]] -
    at(tg$dic$target + z * se[["dic"]], tg$d13c$target)[["ocean_grad_dic"]]
  expect_equal(cost(1), 0.5, tolerance = 1e-8)
  expect_equal(cost(2), 4 * cost(1), tolerance = 1e-8)
})

test_that("the retired h_ml gate is GONE: the rows are scored at every h_ml", {
  skip_if_no_cpp()
  skip_if(is.null(ccx_ocean_gradient_target()), "GLODAPv2 gradient block absent")
  # ⚠ THIS TEST WAS INVERTED 2026-08-28 WHEN MARCUS ADOPTED OPTION 5. It used to
  # assert the terms go ABSENT outside [85, 120]. That skip was measured to bear a
  # FREE LUNCH -- leaving the band bought +7.30 log-units of un-scored data -- so
  # the mismatch is now carried as sigma-inflation instead and the rows are scored
  # EVERYWHERE. The retired band survives only as LIK_OCEAN_GRAD_HML_OK_RETIRED.
  run_at <- function(h) {
    p <- ccx_default_params(); p$h_ml <- h
    sp <- ccx_spinup(p)
    ff <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = sp$prod_c14)
    list(g = ccx_ocean_grad_scored(ccx_run_fast(sp, ff)$out, sp), h = sp$grid$h_ml)
  }
  b <- LIK_OCEAN_GRAD_HML_OK_RETIRED
  for (h in c(b[1] - 10, mean(b), b[2] + 64)) {
    r <- run_at(h)
    expect_false(is.null(r$g))                       # <- the inversion
    expect_true(is.finite(r$g$dic) && is.finite(r$g$d13c) && is.finite(r$g$alk))
    expect_true(all(is.finite(r$g$sd_eff)))
    expect_equal(unname(r$g$h_ml), h, tolerance = 1e-9)
  }
  # sigma_eff is never below sigma_obs, and is LARGER outside the retired band
  # than at its centre -- that is the whole content of "representation error".
  tg <- ccx_ocean_gradient_target()
  se <- function(h) vapply(c("dic", "d13c", "alk"), ccx_ocean_sigma_eff,
                           numeric(1), h_ml = h)
  for (h in c(b[1] - 10, mean(b), b[2] + 64))
    expect_true(all(se(h) >= vapply(c("dic", "d13c", "alk"),
                                    function(n) tg[[n]]$sd, numeric(1)) - 1e-12))
  expect_true(all(se(b[1] - 10) > se(mean(b))))
  expect_true(all(se(b[2] + 64) > se(mean(b))))
})

test_that("the PREINDUSTRIAL gradient is EXACTLY pump_grad, and exactly zero without the pump", {
  skip_if_no_cpp()
  # THE TRIPWIRE FIRED, AS DESIGNED, AND THIS IS ITS RE-DERIVATION (2026-08-16e).
  # Handoff 2026-08-16 sec.4.2 measured the zero-gradient property and asked for
  # it to be GATED, because it is a property of the pump-free structure and the
  # pump is designed to destroy it: "if this test ever fails, either a pump has
  # landed (expected) or something is leaking carbon into the interior (not)."
  # The pump landed (Marcus 2026-08-16d) and it failed at exactly 233.109 --
  # `pump_grad` itself, to 1e-13 -- i.e. it CONFIRMED the pump rather than
  # catching a leak. Both readings are now separated and gated:
  #
  #   OFF arm -- the original claim, unweakened. A proof, not a coincidence: DIC
  #     and 13C are conserved with no interior source, so any steady state of any
  #     transport operator has a uniform interior; the ML value is carbonate
  #     equilibrium at fixed ALK_SURFACE and SST.
  #   ON arm -- STRICTLY STRONGER than what this test asserted before. The
  #     delivered gradient equals `pump_grad` to roundoff for EVERY parameter
  #     perturbed, including `kz` (which the export field is solved against and
  #     so scales with) and `h_ml` (which re-bins the observed shape). That the
  #     answer is parameter-INDEPENDENT is the non-trivial part, and a leak into
  #     the interior would break it while leaving a "gradient is nonzero" test
  #     perfectly happy.
  pi_grad <- function(p) {
    sp <- ccx_spinup(p); g <- sp$grid; rho <- ccx_const("RHO_SEAWATER")
    pool <- function(idx, dz) {
      C <- sum(vapply(HEMIS, function(h) sp$y[idx(h), "C"], numeric(1)))
      M <- sum(vapply(HEMIS, function(h) sp$aux$a_oc[[h]] * dz * rho, numeric(1)))
      C * sp$aux$mol_per_GtC / M * 1e6
    }
    pool(function(h) utils::tail(sp$aux$idx[[h]]$oc, 1), g$dz[length(g$dz)]) -
      pool(function(h) sp$aux$idx[[h]]$ml, g$dz[1])
  }
  base <- ccx_default_params()
  expect_gt(base$pump_grad, 0)       # the ON arm below is not vacuous
  for (nm in c("<none>", "kz", "h_ml", "k_w", "beta_max", "q10")) {
    p <- base; if (nm != "<none>") p[[nm]] <- p[[nm]] * 1.1
    # ON: the interior gradient IS the pump's, whatever else moves
    expect_lt(abs(pi_grad(p) - p$pump_grad), 1e-9)
    # OFF: and with the source removed the interior is uniform again
    p0 <- p; p0$pump_grad <- 0
    expect_lt(abs(pi_grad(p0)), 1e-9)
  }
})

test_that("the TRANSIENT gradient's parameter leverage stays far below its miss", {
  skip_if_no_cpp()
  tg <- ccx_ocean_gradient_target()
  skip_if(is.null(tg), "GLODAPv2 gradient block absent")
  # Scoring the TRANSIENT (Marcus 2026-08-16) rather than the spinup means
  # sec.4.2's "leverage exactly zero" no longer holds: anthropogenic uptake
  # depends on the ocean parameters, so the terms are no longer a pure constant.
  # MEASURED at <= 0.09 sigma per 10 % perturbation. This gate is a BOUND, not
  # an equality, and it is the honest replacement for the zero-leverage one.
  #
  # RE-DERIVED 2026-08-16e, AND THE BOUND ITSELF WAS NEVER WHAT FAILED. The old
  # `expect_gt(miss, 5)` was a guard against the bound passing for the wrong
  # reason -- against a miss so small that "leverage is far below it" is vacuous.
  # Wiring the pump ON closed the miss from 11.02 to 1.79 sigma, so the GUARD
  # fired while every leverage stayed inside LEV_MAX. Loosening 5 to 1 would have
  # kept the letter and lost the point, so the guard is now stated as what it
  # always meant: the leverage must be far below the miss, as a RATIO, whatever
  # the miss happens to be.
  #
  # AND THE PUMP DOES NOT TOUCH THE LEVERAGE AT ALL -- measured identical to
  # three digits with the pump on and off (kz 0.026, beta_max 0.088, k_w 0.013
  # sigma both ways). It moves the LEVEL of the scored gradient (-45.2 -> 187.9
  # against a 233.1 target), not the parameters' grip on it, which is exactly the
  # separation the pump was adopted for. The pump-OFF arm below gates that.
  LEV_MAX   <- 0.25        # sigma per 10 % perturbation; measured max 0.09
  LEV_SHARE <- 0.10        # ...and as a fraction of the miss; measured max 0.049
  base <- ccx_default_params(); base$h_ml <- SD_EFF_H
  gof <- function(p) {
    sp <- ccx_spinup(p)
    ff <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = sp$prod_c14)
    ccx_ocean_grad_scored(ccx_run_fast(sp, ff)$out, sp)$dic
  }
  b    <- gof(base)
  miss <- abs(b - tg$dic$target) / tg$dic$sd
  # the miss is still REAL -- if it vanished the bound below would be vacuous,
  # which is what the old `> 5` guard was protecting and what this preserves
  expect_gt(miss, 1)
  for (nm in c("kz", "beta_max", "k_w")) {
    p <- base; p[[nm]] <- p[[nm]] * 1.1
    lev <- abs(gof(p) - b) / tg$dic$sd
    expect_lt(lev, LEV_MAX)
    expect_lt(lev / miss, LEV_SHARE)
  }
  # THE PUMP CLOSES THE MISS. Held here rather than in a comment because it is
  # the reason the pump ships: without it this row sits ~11 sigma out and no
  # ocean parameter can move it (that is diag_ocean_candidates.R's structural
  # result), so a failure here means the pump has stopped reaching this row.
  p0 <- base; p0$pump_grad <- 0
  expect_gt(abs(gof(p0) - tg$dic$target) / tg$dic$sd, 3 * miss)
})

# =====================================================================
# The ocean ALKALINITY gradient term (fourth row; Marcus 2026-08-16b)
# =====================================================================

test_that("the alkalinity row is a Gaussian on the shipped target, absent without it", {
  skip_if_no_cpp()
  tg <- ccx_ocean_gradient_target()
  skip_if(is.null(tg) || is.null(tg$alk), "GLODAPv2 alkalinity gradient absent")
  f <- lik_fixture()
  bare <- ccx_loglik(f$out, f$obs, f$err, by_stream = TRUE)
  expect_false("ocean_grad_alk" %in% names(bare))
  se <- vapply(c("dic", "d13c", "alk"), ccx_ocean_sigma_eff, numeric(1), h_ml = SD_EFF_H)
  at <- function(alk) ccx_loglik(f$out, f$obs, f$err, by_stream = TRUE,
                                 ocean_grad = list(dic = tg$dic$target,
                                                   d13c = tg$d13c$target, alk = alk,
                                                   sd_eff = se))
  p0 <- at(tg$alk$target)
  expect_true("ocean_grad_alk" %in% names(p0))
  expect_equal(unname(p0[["ocean_grad_alk"]]),
               stats::dnorm(0, 0, se[["alk"]], log = TRUE), tolerance = 1e-10)
  cost <- function(z) p0[["ocean_grad_alk"]] - at(tg$alk$target + z * se[["alk"]])[["ocean_grad_alk"]]
  expect_equal(cost(1), 0.5, tolerance = 1e-8)
  expect_equal(cost(2), 4 * cost(1), tolerance = 1e-8)
})

test_that("the model's alkalinity gradient is EXACTLY zero without a pump, at every parameter", {
  skip_if_no_cpp()
  # NOT an approximation and NOT a placeholder: the model has no alkalinity
  # state at all, so no parameter can separate the two layers. This is the
  # property a carbonate pump breaks ON PURPOSE -- the day it stops holding
  # must be a test failure, not something inferred from a logL that moved.
  for (h in c(85, 100, 120)) {
    p <- ccx_default_params(); p$h_ml <- h
    for (kz in c(3000, 5000, 6200)) {
      p$kz <- kz
      sp <- ccx_spinup(p)
      expect_identical(ccx_model_ocean_alk_gradient(sp), 0)
    }
  }
  tg <- ccx_ocean_gradient_target()
  skip_if(is.null(tg) || is.null(tg$alk), "GLODAPv2 alkalinity gradient absent")
  # ...and the miss that zero implies is the one the pump has to close.
  expect_equal(tg$alk$target / tg$alk$sd, 4.09, tolerance = 0.01)
})

test_that("the steady-state solver is the exact inverse of the export solve", {
  skip_if_no_cpp()
  # THIS IS WHAT MAKES THE ALKALINITY ROW TESTABLE BEFORE A PUMP EXISTS.
  # dg_export_field() maps a target profile -> the source field that holds it;
  # ccx_steady_profile_from_source() maps a source field -> the profile it
  # holds. Composing them must return the profile it started from, and if it
  # ever stops doing so the alkalinity row is silently scoring the wrong
  # quantity the moment a pump is attached to it.
  source(ccx_path("calibration", "pump_shim.R"))
  p <- ccx_default_params(); p$h_ml <- 100
  sp <- ccx_spinup(p); aux <- sp$aux; grid <- sp$grid
  for (h in HEMIS) {
    # an arbitrary NON-uniform profile, not one the model would produce
    want <- 2000 + c(0, cumsum(seq_len(grid$nl)) * 7.5)
    S    <- dg_export_field(p, aux, grid, h, want)$S
    got  <- ccx_steady_profile_from_source(S, p, aux, grid, h)
    expect_equal(got, want[-1] - want[1], tolerance = 1e-8)
  }
})

test_that("a carbonate pump moves the alkalinity row, and by the stoichiometry", {
  skip_if_no_cpp()
  # The forward direction, exercised with a HAND-BUILT pump rather than a real
  # one: alkalinity rides the carbonate limb at +2 per mole and the organic limb
  # at -(N:C). A pure organic pump must therefore move the row NEGATIVE, and a
  # pure carbonate pump must move it to +2x what the same field does for DIC.
  source(ccx_path("calibration", "pump_shim.R"))
  p <- ccx_default_params(); p$h_ml <- 100
  sp <- ccx_spinup(p); aux <- sp$aux; grid <- sp$grid
  fields <- lapply(HEMIS, function(h)
    dg_export_field(p, aux, grid, h, 2000 + c(0, cumsum(rep(10, grid$nl))))$S)
  names(fields) <- HEMIS
  zero <- lapply(fields, function(x) x * 0)
  dic_grad <- {
    v <- vapply(HEMIS, function(h) {
      g <- ccx_steady_profile_from_source(fields[[h]], p, aux, grid, h)[grid$nl]
      m <- aux$a_oc[[h]] * grid$dz[grid$nl + 1L] * ccx_const("RHO_SEAWATER")
      c(g * m, m)
    }, numeric(2))
    sum(v[1, ]) / sum(v[2, ])
  }
  carb_only <- ccx_model_ocean_alk_gradient(sp, list(S_carb = fields, S_org = zero))
  org_only  <- ccx_model_ocean_alk_gradient(sp, list(S_carb = zero, S_org = fields))
  expect_equal(carb_only, LIK_ALK_PER_CARB * dic_grad, tolerance = 1e-8)
  expect_equal(org_only, -LIK_ALK_NC_RATIO * dic_grad, tolerance = 1e-8)
  expect_lt(org_only, 0)
  expect_gt(carb_only, 0)
})

test_that("the NEP amplitude factors are the measured scale of the SHIPPED phi", {
  # seas_npp_amp_{NH,SH} and CCX_SEAS_PHI_EFF are ONE (shape, size) unit: the
  # factors are the least-squares scale of THAT latitude's insolation curve onto
  # the observed productivity cycle. Move phi and they are wrong -- silently,
  # and in the direction that re-opens the 48 K cancellation they were shipped
  # to close. So they are RE-DERIVED here from the observation product at the
  # CURRENT phi rather than compared with a stored number.
  f <- ccx_path("data", "obs_npp_seasonal_shape.rds")
  skip_if(!file.exists(f), "obs_npp_seasonal_shape.rds absent")
  ss <- readRDS(f)
  NG <- 720; tt <- (seq_len(NG) - 0.5) / NG
  um <- function(v) v / mean(v)
  refit <- function(nm, phi) {
    x <- ss$fits[[nm]]
    mid <- x$mid; days <- round(diff(c(mid, mid[1] + 1)) * 365); nd <- sum(days)
    half <- (days / nd) / 2
    W <- matrix(0, length(mid), NG)
    for (i in seq_along(mid)) {
      inw <- ((tt - (mid[i] - half[i])) %% 1) <= ((2 * half[i]) %% 1)
      W[i, inw] <- 1 / sum(inw)
    }
    v <- um(ccx_insol(phi, tt)) - 1
    mean(vapply(seq_along(x$years), function(i) {
      tg <- x$shape_by_year[, i]; bb <- Inf; ba <- NA_real_
      for (s in seq(0, 11.75, by = 0.05)) {
        k <- round(s / 12 * NG) %% NG
        B <- as.vector((if (k == 0) W else W[, c((k + 1):NG, seq_len(k))]) %*% v)
        a <- max(0, sum(B * (tg - 1)) / sum(B^2))
        e <- sum((1 + a * B - tg)^2)
        if (e < bb) { bb <- e; ba <- a }
      }
      ba
    }, numeric(1)))
  }
  expect_equal(refit("NH_psnnet", CCX_SEAS_PHI_EFF[["NH"]]),
               ccx_const("SEAS_NPP_AMP_NH"), tolerance = 1e-3)
  expect_equal(refit("SH_psnnet", CCX_SEAS_PHI_EFF[["SH"]]),
               ccx_const("SEAS_NPP_AMP_SH"), tolerance = 1e-3)
  # and the defaults carry them, so the shipped model IS the measured pair
  p <- ccx_default_params()
  expect_equal(p$seas_npp_amp_NH, ccx_const("SEAS_NPP_AMP_NH"), tolerance = 1e-12)
  expect_equal(p$seas_npp_amp_SH, ccx_const("SEAS_NPP_AMP_SH"), tolerance = 1e-12)
  # MUTATION: the gate must FAIL if phi moves without the factors being redone.
  expect_false(isTRUE(all.equal(refit("NH_psnnet", 50), ccx_const("SEAS_NPP_AMP_NH"),
                                tolerance = 1e-3)))
})
