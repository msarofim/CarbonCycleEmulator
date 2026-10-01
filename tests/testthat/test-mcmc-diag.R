# Known-answer tests for calibration/lib_mcmc_diag.R: rank-normalised split-R-hat and bulk- and
# tail-ESS (Vehtari et al. 2021, Bayesian Analysis 16:667), written from the paper because
# `posterior` is not installed. Nothing here is compared with another implementation: each
# quantity is checked against an ANALYTIC value (AR(1) ESS, the ESS of a Gaussian AR(1) tail
# indicator, a hand-computed R-hat) or against a planted failure it must see.
#
# Every bound is derived from the estimator's own MEASURED spread (2026-10-01 p, 200 replicates
# per case; scratch logs in that CHANGELOG entry): a mean over R seeded replicates must sit within
# the measured bias + 3 x (replicate sd / sqrt(R)), and a single case within 3 replicate sd.
# Mutation-tested: each test fails when the part it names is removed.
source(file.path(.root, "calibration", "lib_mcmc_diag.R"))

# m stationary Gaussian AR(1) chains of length n
.ar1 <- function(n, m, phi) vapply(seq_len(m), function(j) {
  x0 <- stats::rnorm(1, 0, 1 / sqrt(1 - phi^2))
  as.numeric(stats::filter(stats::rnorm(n), phi, method = "recursive", init = x0))
}, numeric(n))

test_that("the FFT autocovariance equals the direct biased sum (zero-padding removes the wrap)", {
  set.seed(1); y <- stats::rnorm(257); n <- length(y); yc <- y - mean(y)
  direct <- vapply(0:(n - 1), function(k) sum(yc[1:(n - k)] * yc[(1 + k):n]) / n, numeric(1))
  expect_lt(max(abs(mcd_acov(y) - direct)), 1e-12)
})

test_that("bulk-ESS recovers the analytic AR(1) ESS, S (1 - phi) / (1 + phi)", {
  # measured, 4 x 2000: mean ratio 0.986 / 0.996 / 0.988, replicate sd 0.130 / 0.058 / 0.031
  R <- 20
  for (cs in list(c(phi = 0.9, sd = 0.130), c(phi = 0.5, sd = 0.058), c(phi = 0, sd = 0.031))) {
    truth <- 4 * 2000 * (1 - cs[["phi"]]) / (1 + cs[["phi"]])
    set.seed(20261001)
    r <- vapply(seq_len(R), function(i) mcd_ess_bulk(.ar1(2000, 4, cs[["phi"]])) / truth, numeric(1))
    expect_lt(abs(mean(r) - 1), 0.02 + 3 * cs[["sd"]] / sqrt(R),
              label = sprintf("phi %.1f: |mean ESS ratio %.3f - 1|", cs[["phi"]], mean(r)))
  }
})

test_that("tail-ESS recovers the analytic ESS of the 5 % indicator, which is NOT the mean's", {
  # A Gaussian AR(1)'s tail indicator decorrelates faster than the series: its lag-k correlation
  # is (Phi2(q, q; phi^k) - p^2) / (p (1 - p)). At phi 0.5, 4 x 2000 that gives 4744, 1.78 x the
  # mean's 2667. Measured: mean ratio 0.969 (the min over two tails biases it low), sd 0.060.
  phi <- 0.5; p <- 0.05; q <- stats::qnorm(p)
  phi2 <- function(r) stats::integrate(function(x) stats::dnorm(x) * stats::pnorm((q - r * x) / sqrt(1 - r^2)),
                                       -Inf, q, rel.tol = 1e-10)$value
  rk <- vapply(phi^(1:60), function(r) (phi2(r) - p^2) / (p * (1 - p)), numeric(1))
  truth <- 4 * 2000 / (1 + 2 * sum(rk))
  expect_equal(truth, 4744, tolerance = 1e-3)
  R <- 20; set.seed(20261001)
  r <- vapply(seq_len(R), function(i) mcd_ess_tail(.ar1(2000, 4, phi)) / truth, numeric(1))
  expect_lt(abs(mean(r) - 1), 0.04 + 3 * 0.060 / sqrt(R),
            label = sprintf("|mean tail-ESS ratio %.3f - 1|", mean(r)))
})

test_that("R-hat is ~1 for iid chains, and each of its parts catches its own failure", {
  set.seed(7); x <- matrix(stats::rnorm(4000), 1000, 4)
  expect_lt(mcd_rhat(x), 1.005)                          # measured mean 1.0003, max 1.0019
  # LOCATION: one chain shifted 1 sd. By hand on the 8 split halves of 500:
  # sqrt(499/500 + var(means)) with means (0 x 6, 1 x 2) = 1.1010; measured sd 0.0077
  xs <- x; xs[, 1] <- xs[, 1] + 1
  expect_lt(abs(mcd_rhat(xs) - sqrt(499 / 500 + (6 * 0.25^2 + 2 * 0.75^2) / 7)), 3 * 0.0077)
  # SCALE: one chain 3x wider, same centre. Only the FOLDED half sees it (measured 1.145, min 1.120)
  xv <- x; xv[, 1] <- xv[, 1] * 3
  expect_lt(mcd_rhat_basic(mcd_z(mcd_split(xv))), 1.005)
  expect_gt(mcd_rhat(xv), 1.05)
  # TREND shared by every chain: only the SPLIT sees it (by hand 1.1237; measured 1.1233, min 1.108)
  xt <- x + seq(-1, 1, length.out = 1000)
  expect_lt(mcd_rhat_basic(xt), 1.005)
  expect_lt(abs(mcd_rhat(xt) - sqrt(499 / 500 + 0.25 * 8 / 7 / (1 + 1 / 12))), 3 * 0.0074)
})

test_that("bulk diagnostics are INVARIANT to a monotone transform: the point of rank-normalising", {
  # Gaussian test data cannot see the ranks (they are nearly the identity there), so the
  # property itself is tested, exactly: ranks, hence z, hence everything downstream, are unchanged
  # by a strictly increasing map. The un-ranked mutant gives ESS 3097 vs 181 on this input.
  set.seed(5); x <- .ar1(1000, 4, 0.7); x[, 2] <- x[, 2] + 0.5
  f <- function(v) exp(3 * v)
  expect_identical(mcd_ess_bulk(f(x)), mcd_ess_bulk(x))
  expect_identical(mcd_rhat_basic(mcd_z(mcd_split(f(x)))), mcd_rhat_basic(mcd_z(mcd_split(x))))
})

test_that("Geyer's initial sequence is made MONOTONE, and the inputs here exercise that step", {
  # An absolute-truth test cannot see this step: across seeds the estimator's mean ratio moves by
  # more (0.99-1.10) than removing the step does (0.06-0.08). Its DEFINING property can be seen:
  # the pair sums rho(2k) + rho(2k+1) never increase. Short noisy chains (4 x 400 at phi 0.97, our
  # regime: a few autocorrelation times per chain) give raw pairs that DO increase, so the
  # property has power here.
  pairs <- function(r, mt) r[seq(1, mt, 2)] + r[seq(2, mt, 2)]
  raw_rises <- 0L
  for (s in 1:5) {
    set.seed(s); g <- mcd_rho_geyer(.ar1(400, 4, 0.97))
    expect_true(all(diff(pairs(g$rho, g$max_t)) <= 0), label = sprintf("seed %d processed pairs non-increasing", s))
    raw_rises <- raw_rises + any(diff(pairs(g$rho_raw, g$max_t)) > 0)
  }
  expect_gt(raw_rises, 0L)
})

test_that("ESS counts between-chain disagreement (eq. 10's var-plus), so disagreeing chains have little", {
  set.seed(11); x <- matrix(stats::rnorm(4000), 1000, 4)
  e0 <- mcd_ess_bulk(x)
  expect_gt(e0, 0.8 * 4000)                              # measured mean 3946, sd 160
  x[, 1] <- x[, 1] + 1
  expect_lt(mcd_ess_bulk(x), 50)                         # measured mean 26.4, max 31.8
})
