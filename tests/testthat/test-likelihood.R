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
  # the objective locates the level rather than being flat in it
  expect_lt(abs(b0), 3)
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
  expect_length(CCX_PARAM_NAMES, 20L)
  expect_true(all(c("grad_off_co2", "grad_off_d13c") %in% CCX_PARAM_NAMES))
  # both are shrinkage priors CENTRED AT ZERO -- centring them on the measured
  # offsets would tell the model the answer and then credit it for agreeing
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

  # DECISION 2: kz is BOUNDED to the range that keeps deep-ocean D14C inside the
  # observed -150 to -200. Unbounded it ran to 10,686 (deep -129.9). The bounds are
  # bisected values, so assert the transform is actually a bounded one -- a silent
  # revert to tr = "log" would restore the runaway with no other visible symptom.
  expect_identical(CCX_PARAM_TABLE$kz$tr, "logit")
  expect_gte(CCX_PARAM_TABLE$kz$lo, 3830)
  expect_lte(CCX_PARAM_TABLE$kz$hi, 6200)
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
  p <- ccx_default_params(); p$gamma_enso <- 0.5
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
  p <- ccx_default_params(); p$gamma_enso <- 0.5
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
  # The 17-parameter unbounded mode ran kz to 10,686. If this term cannot reject
  # that on its own, deleting the kz bracket (13i sec.A3's original plan) leaves
  # the deep ocean unconstrained. Measured: 5.3 sigma at n_eff = 20.
  p <- ccx_default_params(); p$kz <- 10686
  runaway <- ccx_spinup(p)$diagnostics$d14c_bottom_box
  expect_gt(abs(runaway - tg$target) / tg$sd, 2)
  # ...and the converse, which is why the bracket was NOT deleted: expressed on
  # this same quantity the bracket is a hard box TIGHTER than the sigma allows,
  # so deleting it would loosen kz rather than tighten it.
  lo <- ccx_spinup(within(ccx_default_params(), kz <- 3830))$diagnostics$d14c_bottom_box
  hi <- ccx_spinup(within(ccx_default_params(), kz <- 6200))$diagnostics$d14c_bottom_box
  expect_lt((hi - lo) / 2, 3 * tg$sd)
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
