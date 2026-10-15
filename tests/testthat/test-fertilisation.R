# =====================================================================
# Gate: the CO2-fertilization FORM (2026-08-14, review item 7).
#
# Two forms now exist and one switch selects between them, which creates three
# distinct ways to break the model silently. This file guards all three:
#
#   1. THE SUPERSEDED FORM MUST STILL WORK. The default flipped to CCX_FERT_MM
#      on 2026-08-14, but every result in this repo before that date was
#      produced under the log form, and `p$fert_form <- CCX_FERT_LOG` is what
#      reproduces them. The log path must stay bit-identical to the expression
#      it was, or the pre-flip record becomes unreproducible.
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

FT_CHI_NOW  <- 388
FT_CHI_HIGH <- 1998
FT_NPP0     <- 60

test_that("the default is MM, and the flip is recorded rather than assumed", {
  # THIS ASSERTION DID ITS JOB. It shipped as "the default is still the LOG
  # form" on 2026-08-14 so that a flip could not happen as a side effect; Marcus
  # then took decision 2 ("flip the default to MM") and the flip is recorded
  # HERE, with its criterion, rather than the expectation being quietly edited.
  #
  # THE CRITERION WAS GATE 12, NOT THE LIKELIHOOD. fert_k 120 passes Joos at all
  # three horizons with margin (12.4/25.6/41.9); the log-posterior's own optimum
  # on the design-target locus is fert_k 171, which FAILS at TH20 and TH100.
  # DESIGN sec.6 opens "all must pass before headline claims", so the gate wins.
  # See ccx_default_params()$fert_k for the full table.
  expect_equal(CCX_FERT_FORM_DEFAULT, CCX_FERT_MM)
  expect_equal(ccx_default_params()$fert_form, CCX_FERT_MM)
  expect_equal(ccx_default_params()$fert_k, 120)
  expect_equal(ccx_default_params()$beta_max, 0.4913)
  # the log form is KEPT, not deleted -- it is what reproduces every pre-flip
  # result, and `beta` stays in ccx_default_params() for exactly that purpose.
  expect_equal(ccx_default_params()$beta, 0.75)
  expect_false(is.null(ccx_default_params()$beta))
})

test_that("the log path is exactly the expression it replaced", {
  p <- ccx_default_params(); p$fert_form <- CCX_FERT_LOG
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
  base_mm  <- ccx_default_params()
  base_log <- base_mm; base_log$fert_form <- CCX_FERT_LOG
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
  q <- ccx_default_params(); q$fert_form <- CCX_FERT_LOG
  b <- ccx_spinup(q)
  expect_equal(a$y, b$y, tolerance = 1e-12)
  expect_equal(a$prod_c14, b$prod_c14, tolerance = 1e-12)
})

test_that("MM DECOUPLES the integral from the derivative -- the whole point", {
  # The log form's defect stated as arithmetic: enhancement and slope are
  # locked in a fixed ratio, so no beta can move one without the other.
  chi0 <- ccx_const("CO2_PI_PPM")
  lg <- function(b) {
    p <- ccx_default_params(); p$fert_form <- CCX_FERT_LOG; p$beta <- b
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
  # test-parity.R runs on ccx_default_params(), which is now MM, so the MM
  # branch is covered there. This keeps an explicit check anyway: the branch is
  # a SECOND hand-written copy of ccx_fert_factor() inside src/ccx_core.cpp, and
  # if the default ever moves again the coverage must not move with it.
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
