
# =====================================================================
# THE TAIL RATIO (was gate 12b, added 2026-08-25). See DESIGN sec.6 gate 12b.
#
# ⭐ STATUS 2026-09-04 (Marcus): the Joos comparison is NOT a strict test of this
# model -- see R/joos_irf.R's STATUS block. EVERYTHING ASSERTED IN THIS FILE IS
# STILL A STRICT CLAIM, because none of it is about our model: the
# single-exponential locus is parameter-free ALGEBRA, and the rest are properties
# of the REFERENCE (Joos's own published fit) and of the ESTIMATOR applied to it.
# That is exactly the part worth keeping -- it is what makes the reported
# comparison mean anything at all.
# =====================================================================

test_that("the single-exponential null is exact and parameter-free", {
  # IRF(300)/IRF(100) = IRF(100)^2 for ANY tau. This is the whole basis of the
  # gate, so it is asserted rather than trusted.
  for (tau in c(5, 20, 48.8, 60.6, 200, 1000)) {
    f <- function(t) exp(-t / tau)
    expect_equal(f(300) / f(100), joos_tail_null(f(100)), tolerance = 1e-12,
                 info = sprintf("tau = %g", tau))
  }
  # ...and for a half-life parameterization too
  for (hl in c(10, 42, 100)) {
    f <- function(t) 0.5^(t / hl)
    expect_equal(f(300) / f(100), joos_tail_null(f(100)), tolerance = 1e-12)
  }
})

test_that("the REFERENCE band rejects every single exponential and contains Joos", {
  expect_gt(JOOS_TAIL_REF, JOOS_TAIL_BAND[1])
  expect_lt(JOOS_TAIL_REF, JOOS_TAIL_BAND[2])
  # mutation: no one-box model, at any time constant, can reach the floor
  for (tau in c(5, 20, 48.8, 60.6, 200)) {
    f <- function(t) exp(-t / tau)
    expect_lt(f(300) / f(100), JOOS_TAIL_BAND[1], label = sprintf("tau=%g", tau))
  }
  # the two published ones by name
  for (nm in names(JOOS_ONEBOX)) {
    f <- JOOS_ONEBOX[[nm]]
    expect_lt(f(300) / f(100), JOOS_TAIL_BAND[1], label = nm)
  }
})

test_that("joos_tail_ratio() uses the same estimator on any series", {
  tt <- seq(0, 305, by = 0.5)
  expect_equal(joos_tail_ratio(tt, joos_irf(tt)), JOOS_TAIL_REF, tolerance = 1e-6)
  f <- function(t) exp(-t / 48.8)
  expect_equal(joos_tail_ratio(tt, f(tt)), f(300) / f(100), tolerance = 1e-6)
})

test_that("a very long single exponential still sits outside, so the statistic is not a speed test", {
  # tau = 1e4 makes IRF(100) = 0.990 and IRF(300) = 0.970 -- a ratio of 0.980,
  # which is INSIDE the band. That is correct and worth pinning: the gate tests
  # the SHAPE at a given decay level, so it cannot reject a model that barely
  # decays at all. 12a is what rejects those, which is why both are needed.
  f <- function(t) exp(-t / 1e4)
  expect_gt(f(300) / f(100), JOOS_TAIL_BAND[1])          # 12b lets it through
  expect_gt(integrate(f, 0, 100)$value, JOOS_T4$hi[JOOS_T4$th == 100])  # 12a rejects it
})
