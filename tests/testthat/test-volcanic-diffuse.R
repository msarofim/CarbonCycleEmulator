# =====================================================================
# test-volcanic-diffuse.R -- volcanic diffuse-light fertilisation (2026-08-29)
#
# ⚠ THE THIRD TEST IS THE ONE THAT MATTERS AND IT EXISTS BECAUSE THE BUG
# HAPPENED. `src/ccx_core.cpp` carries `N_FORCING`, a hardcoded row width, and
# its own comment says "a disagreement in the ceiling is NOT caught by anything".
# Appending aod_NH/aod_SH to CCX_FORCING_COLS without bumping it made f[15] and
# f[16] read PAST the row buffer: the core returned adjacent memory, the effect
# came out ~1e-4 ppm instead of ~4, and NOTHING failed. R<->C++ parity caught it.
# A test that only checked "gamma_diff = 0 changes nothing" would have passed
# throughout. So the guard is that a NON-ZERO gamma_diff must MOVE THE ANSWER.
# =====================================================================

test_that("gamma_diff defaults to 0 and 0 is behaviour-preserving", {
  expect_identical(ccx_default_params()$gamma_diff, 0)
  skip_if_no_cpp()
  p <- ccx_default_params()
  sp <- ccx_spinup(p)
  F  <- suppressWarnings(ccx_build_forcing("historical", c(1980, 1995),
                                           prod_c14 = 0, bomb_total_kmol = 102))
  F$c14_cosmo <- sp$prod_c14
  a <- as.data.frame(ccx_run_fast(sp, F)$out)
  p2 <- p; p2$gamma_diff <- NULL              # a pre-2026-08-29 parameter list
  sp2 <- ccx_spinup(p2)
  b <- as.data.frame(ccx_run_fast(sp2, F)$out)
  expect_equal(a$co2_NH, b$co2_NH, tolerance = 0)
})

test_that("the AOD forcing column is present, zero pre-1850, and large at Pinatubo", {
  F <- suppressWarnings(ccx_build_forcing("historical", c(1750, 2024),
                                          prod_c14 = 0, bomb_total_kmol = 102))
  expect_true(all(c("aod_NH", "aod_SH") %in% names(F)))
  # ⚠ pre-1850 is ZERO BY CONSTRUCTION, not by physics: the CMIP7 series starts
  # in 1850, so Laki 1783 and TAMBORA 1815 are absent. If this ever becomes
  # non-zero someone has added eVolv2k and this expectation should be REWRITTEN,
  # not deleted.
  expect_true(all(F$aod_NH[F$year < 1850] == 0))
  expect_gt(mean(F$aod_NH[F$year == 1992]), 0.05)
  expect_lt(mean(F$aod_NH[F$year == 2005]), 0.02)
})

test_that("a non-zero gamma_diff MOVES the C++ answer (the N_FORCING guard)", {
  skip_if_no_cpp()
  mk <- function(gd) { p <- ccx_default_params(); p$gamma_diff <- gd; p }
  eff <- function(gd) {
    sp <- ccx_spinup(mk(gd))
    F  <- suppressWarnings(ccx_build_forcing("historical", c(1980, 1995),
                                             prod_c14 = 0, bomb_total_kmol = 102))
    F$c14_cosmo <- sp$prod_c14
    tail(as.data.frame(ccx_run_fast(sp, F)$out)$co2_NH, 1)
  }
  d <- eff(2) - eff(0)
  # Pinatubo is inside the window; gamma_diff = 2 is ~18 % of NPP at its peak,
  # so the effect is ppm-scale. Under the N_FORCING bug it was 4e-4.
  expect_lt(d, -1)
})

test_that("R and C++ agree with the mechanism ON", {
  skip_if_no_cpp()
  p <- ccx_default_params(); p$gamma_diff <- 2
  sp <- ccx_spinup(p)
  F  <- suppressWarnings(ccx_build_forcing("historical", c(1985, 1995),
                                           prod_c14 = 0, bomb_total_kmol = 102))
  F$c14_cosmo <- sp$prod_c14
  a <- as.data.frame(ccx_run_fast(sp, F)$out)
  b <- as.data.frame(suppressWarnings(ccx_run(sp, F))$out)
  expect_lt(max(abs(a$co2_NH - b$co2_NH)), 1e-9)
  expect_lt(max(abs(a$co2_SH - b$co2_SH)), 1e-9)
})
