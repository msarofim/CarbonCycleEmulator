# =====================================================================
# test-pin-family.R -- the parameter-pin near-delta, for every transform family
# (2026-08-25)
#
# `CCX_PIN_PARAMS` collapses a parameter's prior to a near-delta so an arm can
# close an escape route. Until today the near-delta was hardcoded LOGNORMAL,
# which made it correct only for `tr = "log"`; the driver errored on anything
# else, deliberately, because a pin that binds in the wrong coordinate looks
# exactly like a parameter that chose to stay put. That guard was right. The fix
# was to supply the missing families, and these tests are what makes the fix
# safe rather than merely permissive.
#
# The pin is defined by:
#     prior(x) = dnorm(u(x), u0, PIN_SD) - log_jac(u(x))
# so that ccx_make_logpost()'s `prior(x) + log_jac(u)` (R/calibrate.R:874) sums
# to exactly dnorm(u, u0, PIN_SD) -- a normal near-delta in the coordinate the
# OPTIMIZER MOVES IN, which is the coordinate a pin has to bind in.
#
# The driver builds this inline. It is rebuilt here rather than sourced, because
# sourcing run_modefind_pump_arms.R would launch a refit; the identity in test 1
# is what ties the two together, and it would fail loudly if the driver's
# expression drifted from this one.
# =====================================================================

PIN_SD <- 1e-4
pin_prior <- function(val, s, sdv = PIN_SD) {
  u0 <- .to_unc(val, s)
  function(x) {
    u <- suppressWarnings(.to_unc(x, s))
    if (!all(is.finite(u))) return(-Inf)
    stats::dnorm(u, u0, sdv, log = TRUE) - .log_jac(u, s)
  }
}

test_that("on a log parameter the general form IS the old lognormal", {
  # THE REPRODUCIBILITY GATE. Every pinned run before 2026-08-25 used
  # dlnorm(x, log(val), sd); if this drifts, those runs stop reproducing.
  for (nm in c("luc_scale", "sigma_d14c", "q10", "k_w")) {
    s <- CCX_PARAM_TABLE[[nm]]
    expect_identical(s$tr, "log", info = nm)   # was skip_if_not() inside the loop (review A15)
    val <- s$init
    xs  <- val * c(0.9, 0.99, 0.999, 1, 1.001, 1.05, 1.5)
    expect_equal(pin_prior(val, s)(xs),
                 stats::dlnorm(xs, log(val), PIN_SD, log = TRUE),
                 tolerance = 1e-12, info = nm)
  }
})

test_that("the pin sums with the Jacobian to a plain normal in u, in every family", {
  # This is the property the pin is FOR. If it holds, the optimizer sees an
  # isotropic near-delta whatever the parameter's natural scale.
  cases <- list(list(nm = "fert_k", val = 90),        # logit
                list(nm = "beta_max", val = 0.34),    # logit
                list(nm = "q10", val = 1.5),          # log
                list(nm = "rep_dC", val = 1.25))      # id
  for (cs in cases) {
    s <- CCX_PARAM_TABLE[[cs$nm]]
    pr <- pin_prior(cs$val, s); u0 <- .to_unc(cs$val, s)
    for (du in c(-3e-4, -1e-4, 0, 1e-4, 3e-4)) {
      u <- u0 + du; x <- .from_unc(u, s)
      expect_equal(pr(x) + .log_jac(u, s),
                   stats::dnorm(u, u0, PIN_SD, log = TRUE),
                   tolerance = 1e-8, info = sprintf("%s du=%g", cs$nm, du))
    }
  }
})

test_that("the pin is SHARP -- mutation-tested in both directions", {
  # Passing is not the same as working (memory mutate_test_gates): a prior that
  # is flat would also "pass" a test that only checks the value AT the pin.
  bump_u <- log(1.05)
  for (cs in list(list(nm = "fert_k", val = 90), list(nm = "beta_max", val = 0.34),
                  list(nm = "luc_scale", val = 0.8984))) {
    s <- CCX_PARAM_TABLE[[cs$nm]]
    pr <- pin_prior(cs$val, s); u0 <- .to_unc(cs$val, s)
    want <- 0.5 * bump_u^2 / (2 * PIN_SD^2)
    for (sgn in c(-1, 1)) {
      bump <- .from_unc(u0 + sgn * bump_u, s)
      expect_gt(pr(cs$val) - pr(bump), want)
    }
    # MUTATION: a near-delta that is not near -- sd 1e4 times wider -- must FAIL
    # the same gate. Without this the gate above could be passing on the
    # parameter's scale rather than on the pin's sharpness.
    loose <- pin_prior(cs$val, s, sdv = 1)
    expect_lt(loose(cs$val) - loose(.from_unc(u0 + bump_u, s)), want)
  }
})

test_that("a logit pin refuses the bounds, where the transform is infinite", {
  s <- CCX_PARAM_TABLE$fert_k
  expect_true(is.finite(.to_unc(s$lo + 1e-9, s)))
  expect_false(is.finite(.to_unc(s$lo, s)))
  expect_false(is.finite(.to_unc(s$hi, s)))
  # and the prior itself returns -Inf rather than NaN outside the support
  pr <- pin_prior(90, s)
  expect_identical(pr(s$lo), -Inf)
  expect_identical(pr(s$hi + 1), -Inf)
  # and it does so SILENTLY -- qlogis()'s NaN warning would otherwise fire on
  # every out-of-support proposal the optimizer makes.
  expect_silent(pr(s$hi + 1))
})

test_that("the pinned parameter round-trips through the transform", {
  for (cs in list(list(nm = "fert_k", val = 90), list(nm = "beta_max", val = 0.34),
                  list(nm = "rep_dC", val = -1.75))) {
    s <- CCX_PARAM_TABLE[[cs$nm]]
    expect_equal(.from_unc(.to_unc(cs$val, s), s), cs$val, tolerance = 1e-12,
                 info = cs$nm)
  }
})
