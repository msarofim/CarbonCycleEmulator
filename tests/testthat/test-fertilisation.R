# =====================================================================
# Gate: the CO2-fertilisation FORM (2026-08-14, review item 7).
#
# Two forms now exist and one switch selects between them, which creates three
# distinct ways to break the model silently. This file guards all three:
#
#   1. THE INCUMBENT MUST NOT MOVE. The default is still CCX_FERT_LOG, and the
#      log path must be bit-identical to what it was -- otherwise adding an
#      unused alternative would silently invalidate every existing number.
#   2. EACH FORM MUST BE INERT TO THE OTHER'S PARAMETERS, in BOTH directions.
#      An inert parameter that quietly becomes live is the failure mode
#      `luc_scale` was kept out of ccx_default_params() to avoid.
#   3. THE FORM MUST ACTUALLY DECOUPLE what the log form cannot. That is the
#      entire reason it exists, so it is asserted as arithmetic on the
#      function, not inferred from a run.
#
# The GATES themselves (Joos IRF, the Revelle lesson, the sink partition) are
# NOT here: they cost minutes each and live in calibration/diag_fert_*.R.
# =====================================================================

skip_if_no_cpp <- function() {
  skip_if_not_installed("Rcpp")
  ok <- tryCatch({ ccx_load_cpp(); TRUE }, error = function(e) FALSE)
  if (!ok) skip("C++ core failed to compile")
}

FT_CHI_NOW  <- 388
FT_CHI_HIGH <- 1998
FT_NPP0     <- 60

test_that("the default is still the LOG form -- item 7 changed no default", {
  # Marcus deferred the beta default TO this item (decision 2, 2026-08-14) and
  # has not been shown the fitted numbers. If this ever flips, it must flip as a
  # decision with the gate table attached, not as a side effect.
  expect_equal(CCX_FERT_FORM_DEFAULT, CCX_FERT_LOG)
  expect_equal(ccx_default_params()$fert_form, CCX_FERT_LOG)
  expect_equal(ccx_default_params()$beta, 0.75)
})

test_that("the log path is exactly the expression it replaced", {
  p <- ccx_default_params()
  chi <- c(180, 276.88, 300, 388, 420, 1998)
  expect_equal(ccx_fert_factor(chi, p),
               1 + p$beta * log(chi / ccx_const("CO2_PI_PPM")), tolerance = 0)
  # factor 1 at preindustrial, for BOTH forms -- this is what makes the
  # preindustrial spinup identical under either, and it is asserted rather than
  # assumed because the whole land equilibrium hangs off it.
  q <- p; q$fert_form <- CCX_FERT_MM
  expect_equal(ccx_fert_factor(ccx_const("CO2_PI_PPM"), p), 1, tolerance = 1e-12)
  expect_equal(ccx_fert_factor(ccx_const("CO2_PI_PPM"), q), 1, tolerance = 1e-12)
})

test_that("each form is INERT to the other's parameters, both ways", {
  skip_if_no_cpp()
  co2_2024 <- function(p) {
    sp <- ccx_spinup(p)
    F  <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = sp$prod_c14)
    tail(ccx_run_fast(sp, F)$out$co2_NH, 1)
  }
  base_log <- ccx_default_params()
  base_mm  <- base_log; base_mm$fert_form <- CCX_FERT_MM
  a <- co2_2024(base_log); b <- co2_2024(base_mm)
  # log ignores (beta_max, fert_k)
  q <- base_log; q$beta_max <- 99; q$fert_k <- 7
  expect_identical(co2_2024(q), a)
  # MM ignores beta
  q <- base_mm; q$beta <- 99
  expect_identical(co2_2024(q), b)
  # MUTATION: and the switch is not decorative -- the two forms must differ.
  expect_gt(abs(a - b), 1)
})

test_that("the preindustrial spinup is identical under both forms", {
  # Both factors are exactly 1 at chi0, so the land equilibrium, the 14C
  # production solve and every spinup diagnostic must be untouched by the
  # switch. If this fails the fixed point has picked up a dependence it must
  # not have.
  a <- ccx_spinup(ccx_default_params())
  q <- ccx_default_params(); q$fert_form <- CCX_FERT_MM
  b <- ccx_spinup(q)
  expect_equal(a$y, b$y, tolerance = 1e-12)
  expect_equal(a$prod_c14, b$prod_c14, tolerance = 1e-12)
})

test_that("MM DECOUPLES the integral from the derivative -- the whole point", {
  # The log form's defect stated as arithmetic: enhancement and slope are
  # locked in a fixed ratio, so no beta can move one without the other.
  chi0 <- ccx_const("CO2_PI_PPM")
  lg <- function(b) {
    p <- ccx_default_params(); p$beta <- b
    c(enh = ccx_fert_factor(FT_CHI_NOW, p) - 1, slope = b * FT_NPP0 / FT_CHI_NOW)
  }
  r1 <- lg(0.50); r2 <- lg(0.75)
  expect_equal(r1[["enh"]] / r1[["slope"]], r2[["enh"]] / r2[["slope"]], tolerance = 1e-10)

  # MM: hold the enhancement at 388 FIXED by construction, vary fert_k, and the
  # slope must still move -- by a lot, or the replacement buys nothing.
  d <- FT_CHI_NOW - chi0
  enh_target <- 0.70 * log(FT_CHI_NOW / chi0)
  mm <- function(K) {
    p <- ccx_default_params()
    p$fert_form <- CCX_FERT_MM; p$fert_k <- K
    p$beta_max <- enh_target * (K + d) / d
    c(enh = ccx_fert_factor(FT_CHI_NOW, p) - 1,
      slope = FT_NPP0 * p$beta_max * K / (K + d)^2,
      ratio_high = ccx_fert_factor(FT_CHI_HIGH, p))
  }
  lo <- mm(60); hi <- mm(300)
  expect_equal(lo[["enh"]], enh_target, tolerance = 1e-10)   # (a) by construction
  expect_equal(hi[["enh"]], enh_target, tolerance = 1e-10)
  expect_gt(hi[["slope"]] / lo[["slope"]], 1.8)              # the freedom gained
  # (b) the review's slope ceiling, 0.5 * NPP0 / 388, is reachable
  expect_lt(mm(140)[["slope"]], 0.50 * FT_NPP0 / FT_CHI_NOW)
  # (c) and the 1998 ppm ratio comes in well under the log form's 2.48x
  expect_lt(mm(300)[["ratio_high"]], 2.0)
  expect_lt(mm(120)[["ratio_high"]], 1.6)
})

test_that("MM saturates and stays non-negative under abuse", {
  p <- ccx_default_params()
  p$fert_form <- CCX_FERT_MM; p$fert_k <- 140; p$beta_max <- 0.5338
  # monotone increasing in CO2, and bounded by the asymptote
  chi <- seq(100, 1e5, length.out = 500)
  f <- ccx_fert_factor(chi, p)
  expect_true(all(diff(f) >= 0))
  expect_lt(max(f), 1 + p$beta_max)
  # the pole at chi = chi0 - fert_k is guarded, not fitted: NPP cannot be
  # negative and must not be Inf/NaN anywhere a sampler or app slider can go.
  wild <- c(0, 1e-9, ccx_const("CO2_PI_PPM") - p$fert_k, 1e6)
  expect_true(all(is.finite(ccx_fert_factor(wild, p))))
  expect_true(all(ccx_fert_factor(wild, p) >= 0))
})

test_that("R and C++ agree under the saturating form", {
  skip_if_no_cpp()
  # test-parity.R covers the default (log) path. The MM branch is a SECOND
  # hand-written copy of ccx_fert_factor() inside src/ccx_core.cpp, so it needs
  # its own parity check or the two can drift silently.
  p <- ccx_default_params(); p$fert_form <- CCX_FERT_MM
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = sp$prod_c14)
  for (yr in c(1800, 1900, 2000)) {
    fa <- ccx_forcing_at(F, yr)
    dR <- ccx_deriv(sp$y, yr, p, fa, sp$grid, sp$aux)
    dC <- ccx_deriv_fast(sp$y, yr, p, fa, sp$grid, sp$aux)
    expect_equal(dR, dC, tolerance = 1e-12)
  }
})
