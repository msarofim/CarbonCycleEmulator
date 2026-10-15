# =====================================================================
# THE HS AIR-SEA EXCHANGE AREA FACTOR -- `hs_asx_frac` (2026-09-06)
#
# Every residual of the 09-06 ocean arc pointed at the cold box's gas exchange
# (collect_2026-09-06b sec.2-3). This factor scales the HS exchange AREA only:
# 1 = HILDA's assumption (ice cover cancels the stronger winds) and the model
# bit for bit. It is the degree of freedom the 36-box structure re-opens; an
# observational pin is owed before it is freed.
#
# WHAT THESE TESTS GUARD:
#   * 1 -- and ABSENCE -- reproduce the model bit for bit, with the HS boxes ON
#     (with them OFF the factor has nothing to scale and must also be inert).
#   * MUTATION: 0.5 moves HS's D14C, HD's, the deep, and the atmosphere's bomb
#     curve -- a factor that only touched a diagnostic would be a silent knob.
#   * it scales the exchange, not the mass: the HS<->HD limb is untouched.
#   * both cores see it (they read aux$asx_hs, so parity holds by construction;
#     asserted anyway, because "by construction" is how ports break).
#   * invalid values error by name.
# =====================================================================

hx_par <- function(fx = NULL, hs = TRUE) {
  p <- ccx_default_params()
  if (hs) p <- ccx_apply_structure(p, "hilda")   # the declared HILDA block, through the ONE resolver (2026-09-12) }
  if (!is.null(fx)) p$hs_asx_frac <- fx
  p
}

test_that("the default is 1, and 1 / absence reproduce the model bit for bit", {
  expect_identical(ccx_default_params()$hs_asx_frac, 1)
  a <- ccx_spinup(hx_par(1)); pab <- hx_par(); pab$hs_asx_frac <- NULL; b <- ccx_spinup(pab)
  expect_identical(a$y, b$y)
  expect_identical(a$aux$asx_hs, b$aux$asx_hs)
  # HS off: the factor has nothing to scale
  expect_identical(ccx_spinup(hx_par(0.5, hs = FALSE))$y, ccx_spinup(hx_par(1, hs = FALSE))$y)
})

test_that("MUTATION: halving the exchange area ages HS, HD and the deep", {
  a <- ccx_spinup(hx_par(1))$diagnostics; b <- ccx_spinup(hx_par(0.5))$diagnostics
  expect_lt(b$d14c_hs[["NH"]], a$d14c_hs[["NH"]] - 1)
  expect_lt(b$d14c_hd[["NH"]], a$d14c_hd[["NH"]] - 1)
  expect_lt(b$d14c_bottom_box, a$d14c_bottom_box - 0.1)
  # and it scales the exchange, not the mass
  x1 <- ccx_spinup(hx_par(1))$aux; x5 <- ccx_spinup(hx_par(0.5))$aux
  expect_identical(x5$hs_mass_kg, x1$hs_mass_kg)
  expect_equal(x5$asx_hs$NH, 0.5 * x1$asx_hs$NH)
})

test_that("the atmosphere's bomb curve sees it, through the C++ transient", {
  skip_if_no_cpp()
  run <- function(fx) { sp <- ccx_spinup(hx_par(fx))
    F <- ccx_build_forcing("historical", c(1955, 1975), prod_c14 = sp$prod_c14)
    ccx_run_fast(sp, F)$out }
  a <- run(1); b <- run(0.5)
  expect_false(anyNA(b$d14c_NH))
  # less HS uptake => MORE bomb 14C left in the atmosphere at the end of 1975
  expect_gt(tail(b$d14c_SH, 1), tail(a$d14c_SH, 1) + 1)
})

test_that("R and C++ agree at 0.5", {
  skip_if_no_cpp()
  p <- hx_par(0.5); sp <- ccx_spinup(p)
  F <- ccx_build_forcing("historical", c(1850, 1851), prod_c14 = sp$prod_c14)
  fr <- ccx_forcing_at(F, 1L)
  expect_equal(ccx_deriv(sp$y, 1850, p, fr, sp$grid, sp$aux),
               ccx_deriv_fast(sp$y, 1850, p, fr, sp$grid, sp$aux), tolerance = 1e-10)
})

test_that("the prior is the measured exchange factor, tied to the product (09-08e)", {
  obs <- readRDS(ccx_path("data", "obs_hs_exchange_factor.rds")); pr <- readRDS(ccx_path("data", "obs_hs_asx_prior.rds")); s <- CCX_PARAM_TABLE$hs_asx_frac
  expect_equal(pr$centre, obs$factor)                                        # COMPUTED from the product, never re-typed
  for (x in c(0.5, 0.653, 1.835)) expect_equal(s$prior(x), dlnorm(x, log(pr$centre), pr$log_sd, log = TRUE))
  expect_gt(s$prior(pr$centre), s$prior(1.835))                             # round 4's compensator value is penalized
  expect_equal(s$lo, 0.02); expect_equal(s$hi, 2.0)                          # the box is unchanged
})

test_that("invalid values error by name", {
  expect_error(ccx_spinup(hx_par(0)), "hs_asx_frac")
  expect_error(ccx_spinup(hx_par(-1)), "hs_asx_frac")
  expect_error(ccx_spinup(hx_par(NA_real_)), "hs_asx_frac")
})
