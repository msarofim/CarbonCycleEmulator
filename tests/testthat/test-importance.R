# =====================================================================
# Gate: R/importance.R's importance-weight diagnostics (2026-10-08 i).
#
# The Pareto tail fit is RE-IMPLEMENTED ({loo} is not installed), so it is validated here against tails of
# KNOWN shape rather than trusted: generalised-Pareto draws with k = 0.2 / 0.5 / 0.9 must come back near
# their k, and an importance problem with a known answer (a Gaussian proposal narrower or wider than a
# Gaussian target) must land on the right side of the 0.7 rule.
# =====================================================================

rgpd <- function(n, k, sigma = 1) sigma / k * ((1 - stats::runif(n))^(-k) - 1)

test_that("the GPD fit recovers a known shape", {
  set.seed(20261008L)   # set immediately before the draws it governs
  for (k in c(0.2, 0.5, 0.9)) {
    est <- ccx_gpdfit(rgpd(4000, k))$k
    expect_lt(abs(est - k), 0.08)
  }
})

test_that("ESS is exact on equal and on one-hot weights; a failed draw has zero weight", {
  expect_equal(ccx_is_diagnostics(rep(0, 500))$ess, 500)
  expect_true(ccx_is_diagnostics(rep(0, 500))$k_ok)                 # equal weights: no tail at all, a PASS
  d <- ccx_is_diagnostics(c(0, rep(-1e4, 499)))
  expect_equal(d$ess, 1, tolerance = 1e-9)
  expect_false(d$k_ok); expect_identical(d$k_hat, Inf)            # one draw carries it all: a FAIL, not an error
  d2 <- ccx_is_diagnostics(c(0, 0, -Inf, NA))
  expect_equal(d2$n_failed, 2L); expect_equal(d2$ess, 2)
})

test_that("ONE surviving draw, a few equal survivors, or none at all is a FAIL, never a pass", {
  # THE DEFECT (code review 2026-10-12 sec.5): with one surviving draw the tail window had no cutoff
  # draw, the exceedances were EMPTY, all() of an empty vector is TRUE, and k-hat came back -Inf with
  # k_ok TRUE. Each case below PASSED before the fix (measured), so each line has power.
  d1 <- ccx_is_diagnostics(c(0, rep(-Inf, 999)))
  expect_identical(d1$k_hat, Inf); expect_false(d1$k_ok); expect_equal(d1$ess, 1)
  d4 <- ccx_is_diagnostics(c(rep(0, 4), rep(NA, 996)))      # four equal survivors: M = 1, "no tail"
  expect_identical(d4$k_hat, Inf); expect_false(d4$k_ok)
  d0 <- expect_silent(ccx_is_diagnostics(rep(-Inf, 50)))   # every draw failed: no warning, no NaN
  expect_identical(d0$k_hat, Inf); expect_false(d0$k_ok)
  expect_equal(d0$ess, 0); expect_equal(d0$n_failed, 50L); expect_identical(d0$w, numeric(50))
  # and the legitimate "no tail" pass still holds where the window is a real tail (M >= 5)
  expect_true(ccx_is_diagnostics(rep(0, 25))$k_ok)          # M = ceiling(min(5, 15)) = 5
})

test_that("a proposal WIDER than the target passes the k rule; a NARROWER one fails it", {
  # target N(0, 1) in 1-D; proposal N(0, s^2). Wider (s = 1.5): bounded weights. Narrower: the weights
  # exp(x^2 (1/s^2 - 1) / 2) have a Pareto tail with k = 1 - s^2 EXACTLY -- the textbook failure, with a known
  # answer. s = 0.4 -> k = 0.84 (fails 0.7); s = 0.6 -> k = 0.64 (passes it: narrower is not always fatal).
  set.seed(20261008L)   # set immediately before the draws it governs
  S <- 4000L
  for (case in list(list(s = 1.5, ok = TRUE), list(s = 0.6, ok = TRUE), list(s = 0.4, ok = FALSE))) {
    x <- stats::rnorm(S, 0, case$s)
    lw <- stats::dnorm(x, 0, 1, log = TRUE) - stats::dnorm(x, 0, case$s, log = TRUE)
    d <- ccx_is_diagnostics(lw)
    expect_identical(d$k_ok, case$ok, info = sprintf("s = %.1f", case$s))
    if (case$s < 1) expect_lt(abs(d$k_hat - (1 - case$s^2)), 0.1)     # the known shape, recovered
  }
})

test_that("weighted quantiles reduce to the ordinary ones on equal weights, and follow the weights", {
  x <- 1:101
  expect_equal(ccx_wquantile(x, rep(1, 101), c(0.05, 0.5, 0.95)), c(5.55, 51, 96.45), tolerance = 0.6)
  expect_equal(ccx_wquantile(c(1, 2, 3), c(0, 0, 1), 0.5), 3)
})
