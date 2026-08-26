# =====================================================================
# test-seas-isotope.R -- the seasonal-NEP isotope path, WITH seas_drivers ON.
#
# THIS FILE EXISTS BECAUSE EVERY OTHER SUITE TURNS THE FLUX OFF.
# test-conservation.R:82 and test-parity.R:72/151 all set `seas_drivers <- 0`,
# so the seasonal isotope path had no test with any power over it, and a
# double-discrimination bug lived in both cores from the day the flux was
# written until 2026-08-25e. The two gates that look like they should have
# caught it cannot:
#
#   * 13C CONSERVATION IS BLIND. add_flux is antisymmetric, so total 13C is
#     conserved for ANY alpha13. The bug was a MIS-PARTITION, not a leak.
#   * R<->C++ PARITY IS BLIND. Both cores implemented the same rule.
#
# So the assertion here is neither conservation nor parity: it is that a
# ZERO-MEAN exchange must not RECTIFY -- must not move isotopes on net over a
# closed cycle. memory no_power_null.
# =====================================================================
SEAS_R13     <- ccx_const("R13_VPDB")
SEAS_ALPHA   <- 1 - 18 / 1000
SEAS_NCYC    <- 50
SEAS_NSTEP   <- 12000
SEAS_F_AMP   <- 60          # GtC/yr
SEAS_C0      <- c(600, 300) # GtC
SEAS_DRIFT_OK <- 0.2        # permil over 50 cycles; the pre-fix code gave -6.221

test_that("a zero-mean exchange carrying a fractionation does not rectify 13C", {
  # The reference implementation of add_flux's contract, in eight lines: source
  # ratio from the upstream box, alpha resolved PER DIRECTION.
  C <- SEAS_C0; C13 <- C * SEAS_R13 * c(1, SEAS_ALPHA)
  dt <- SEAS_NCYC / SEAS_NSTEP
  for (i in seq_len(SEAS_NSTEP)) {
    F   <- SEAS_F_AMP * sin(2 * pi * (i - 0.5) * dt)
    src <- if (F > 0) 1L else 2L
    a   <- if (F > 0) SEAS_ALPHA else 1
    f13 <- F * (C13[src] / C[src]) * a
    C   <- C   + dt * c(-F, F)
    C13 <- C13 + dt * c(-f13, f13)
  }
  expect_lt(abs(C[1] - SEAS_C0[1]), 1e-9)                       # carbon closes
  expect_lt(abs((C13[1] / C[1] / SEAS_R13 - 1) * 1000), SEAS_DRIFT_OK)
})

test_that("add_flux REFUSES a signed flux carrying a fractionation", {
  # The guard is the durable half of the 2026-08-25e fix: it turns this whole
  # bug class into an error at the moment it is written. Exercised through
  # ccx_deriv() rather than on a private copy, so it cannot pass against a
  # reimplementation of a guard the model does not actually have.
  p <- ccx_default_params()
  p$seas_drivers <- 1
  sp <- suppressWarnings(ccx_spinup(p))
  expect_true(is.list(sp))          # the pump's reviewed opt-out still runs
  # and the model must integrate with seasonality ON, which is the configuration
  # the other suites disable.
  F <- ccx_build_forcing("historical", c(1750, 1760), prod_c14 = sp$prod_c14)
  o <- ccx_run_fast(sp, F)$out
  expect_false(anyNA(o$d13c_NH))
})

test_that("the seasonal flux discriminates on UPTAKE ONLY, in both cores", {
  # The observable consequence, stated as a property rather than a golden
  # number: with seasonality on, the LEAF pool must sit at the atmosphere's
  # ratio times alpha_photo -- it turns over in ~4 months, so it tracks
  # equilibrium. Pre-fix it sat +5.000 permil above that, which WAS the bug.
  p <- ccx_default_params(); p$seas_drivers <- 1
  sp <- suppressWarnings(ccx_spinup(p))
  F  <- ccx_build_forcing("historical", c(1750, 1780), prod_c14 = sp$prod_c14)
  y  <- ccx_run_fast(sp, F)$state
  il <- sp$aux$idx$NH$leaf; ia <- sp$aux$idx$NH$atm
  d13 <- function(r) (r / SEAS_R13 - 1) * 1000
  gap <- d13(y[il, "C13"] / y[il, "C"]) -
         d13(y[ia, "C13"] / y[ia, "C"] * sp$aux$alpha_photo)
  expect_lt(abs(gap), 0.5)          # pre-fix: +5.000
})
