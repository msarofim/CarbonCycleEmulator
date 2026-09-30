# =====================================================================
# test-ndep.R -- D2 (a), the N-deposition NPP multiplier (Marcus 2026-09-30;
# R/model.R CCX_GAMMA_NDEP_DEFAULT, src/ccx_core.cpp, R/forcing.R ccx_ndep_forcing)
#
#   NPP x (1 + gamma_ndep * ndep_h),  ndep_h = anthropogenic deposition onto
#   hemisphere h's land, Tg N/yr above 1750 (forcing columns ndep_NH / ndep_SH).
#
# What has to hold BEFORE any value is adopted:
#   OFF     gamma_ndep 0 ignores even a loud deposition column, bit for bit.
#   PARITY  both cores see the deposition identically, at explicit gammas, with the
#           COLUMN absent (= zero) and with the PARAMETER absent (= the default) --
#           the two absence contracts the gamma_diff incident taught (test-parity.R).
#   TRAJ    an 80-yr trajectory agrees between the cores with gamma ON.
#   CONSERVE carbon is conserved with the multiplier ON.
#   GUARD   a nonzero gamma on a forcing that carries no deposition series is REFUSED,
#           and the periodic spinup's quiet year is accepted (zero by definition).
# Mutation-tested 2026-09-30 (CHANGELOG 09-30 l).
# =====================================================================

NDEP_TEST_LOUD <- c(NH = 40, SH = 8)       # Tg N/yr, ~ the modern order, NH-heavy (synthetic)
NDEP_TEST_GAMMAS <- c(0, 0.002, 0.01)

.nd_forcing <- function(sp, years = c(1900, 1980)) {
  F <- ccx_build_forcing("historical", years, prod_c14 = sp$prod_c14)
  F$ndep_NH <- NDEP_TEST_LOUD[["NH"]] * (F$year - years[1]) / diff(years)   # a ramp
  F$ndep_SH <- NDEP_TEST_LOUD[["SH"]] * (F$year - years[1]) / diff(years)
  attr(F, "ndep_source") <- "synthetic ramp (test-ndep.R)"
  F
}

test_that("OFF: gamma_ndep 0 ignores even a loud deposition column, bit for bit", {
  skip_if_no_cpp()
  sp <- ccx_spinup(ccx_default_params())
  F0 <- suppressWarnings(ccx_build_forcing("historical", c(1900, 1980), prod_c14 = sp$prod_c14))
  expect_true(all(c("ndep_NH", "ndep_SH") %in% names(F0)))
  expect_identical(length(CCX_FORCING_COLS), 19L)
  a <- suppressWarnings(ccx_run_fast(sp, F0))
  b <- suppressWarnings(ccx_run_fast(sp, .nd_forcing(sp)))
  expect_identical(a$out, b$out)
  expect_identical(a$state, b$state)
})

test_that("PARITY: both cores see the deposition, at explicit gammas and at both absences", {
  skip_if_no_cpp()
  p  <- ccx_default_params(); sp <- ccx_spinup(p)
  F  <- .nd_forcing(sp); i <- nrow(F) - 6L; t <- F$t[i]
  f  <- ccx_forcing_at(F, i)
  expect_gt(f$ndep_NH, 30)                                    # the gate has something to bite on
  for (g in NDEP_TEST_GAMMAS) {
    p$gamma_ndep <- g
    expect_equal(ccx_deriv(sp$y, t, p, f, sp$grid, sp$aux),
                 ccx_deriv_fast(sp$y, t, p, f, sp$grid, sp$aux), tolerance = 1e-12, info = g)
  }
  # POWER: at gamma 0.01 the core really sees 40 Tg N/yr
  p$gamma_ndep <- 0.01
  f0 <- f; f0$ndep_NH <- 0; f0$ndep_SH <- 0
  expect_gt(max(abs(ccx_deriv_fast(sp$y, t, p, f, sp$grid, sp$aux) -
                    ccx_deriv_fast(sp$y, t, p, f0, sp$grid, sp$aux))), 1)
  # the COLUMN's absence is zero deposition, in both cores
  fn <- f; fn$ndep_NH <- NULL; fn$ndep_SH <- NULL
  expect_equal(ccx_deriv_fast(sp$y, t, p, fn, sp$grid, sp$aux),
               ccx_deriv_fast(sp$y, t, p, f0, sp$grid, sp$aux), tolerance = 1e-12)
  expect_equal(ccx_deriv(sp$y, t, p, fn, sp$grid, sp$aux),
               ccx_deriv(sp$y, t, p, f0, sp$grid, sp$aux), tolerance = 1e-12)
  # the PARAMETER's absence is the default, in both cores (and they agree with each other)
  pa <- p; pa$gamma_ndep <- NULL
  pe <- p; pe$gamma_ndep <- CCX_GAMMA_NDEP_DEFAULT
  expect_equal(ccx_deriv(sp$y, t, pa, f, sp$grid, sp$aux),
               ccx_deriv_fast(sp$y, t, pa, f, sp$grid, sp$aux), tolerance = 1e-12)
  expect_equal(ccx_deriv_fast(sp$y, t, pa, f, sp$grid, sp$aux),
               ccx_deriv_fast(sp$y, t, pe, f, sp$grid, sp$aux), tolerance = 1e-12)
  expect_equal(ccx_deriv(sp$y, t, pa, f, sp$grid, sp$aux),
               ccx_deriv(sp$y, t, pe, f, sp$grid, sp$aux), tolerance = 1e-12)
})

test_that("TRAJ: an 80-yr trajectory agrees between the cores with gamma ON", {
  skip_if_no_cpp()
  p <- ccx_default_params(); p$gamma_ndep <- 0.004
  sp <- ccx_spinup(p); F <- .nd_forcing(sp)
  rR <- suppressWarnings(ccx_run(sp, F)); rC <- suppressWarnings(ccx_run_fast(sp, F))
  for (cc in c("co2_NH", "co2_SH", "land_C", "ocean_C", "land_C14"))
    expect_lt(max(abs(rR$out[[cc]] - rC$out[[cc]])) / max(abs(rR$out[[cc]])), 1e-13, label = cc)
  expect_lt(max(abs(rR$state - rC$state)) / max(abs(rR$state)), 1e-13)
  # MUTATION: the OFF trajectory must be far outside the parity tolerance
  rOff <- suppressWarnings(ccx_run_fast(ccx_spinup(ccx_default_params()), F))
  expect_gt(max(abs(rOff$out$land_C - rC$out$land_C)) / max(abs(rC$out$land_C)), 1e-4)
})

test_that("CONSERVE: closed-system carbon is conserved with the multiplier ON", {
  p <- ccx_set_enso(ccx_default_params(), list(gamma_enso = 0)); p$gamma_ndep <- 0.01
  sp <- ccx_spinup(p)
  closed <- list(e_foss = list(NH = 0, SH = 0), e_luc = list(NH = 0, SH = 0),
                 gmst = 0, enso = 0, c14_bomb = 0, c14_nuclear = 0, c14_cosmo = 0,
                 ndep_NH = NDEP_TEST_LOUD[["NH"]], ndep_SH = NDEP_TEST_LOUD[["SH"]])
  y <- sp$y
  d <- ccx_deriv(y, 1900, p, closed, sp$grid, sp$aux)
  expect_gt(max(abs(d[, "C"])), 1)                            # it IS out of balance: NPP x 1.4
  expect_lt(abs(sum(d[, "C"])) / max(abs(d[, "C"])), 1e-12)
  tot0 <- ccx_total(y); t <- 1900
  for (m in seq_len(12 * 30)) { y <- ccx_step_rk4(y, t, 1 / 12, p, closed, sp$grid, sp$aux); t <- t + 1 / 12 }
  expect_lt(abs(ccx_total(y) / tot0 - 1), 1e-10)
})

test_that("GUARD: a nonzero gamma on a forcing with NO deposition series is refused", {
  skip_if_no_cpp()
  p <- ccx_default_params(); p$gamma_ndep <- 0.004
  sp <- ccx_spinup(p)
  F <- suppressWarnings(ccx_build_forcing("historical", c(1900, 1910), prod_c14 = sp$prod_c14))
  attr(F, "ndep_source") <- "none"
  expect_error(ccx_run_fast(sp, F), "NO N-deposition series")
  attr(F, "ndep_source") <- NULL
  expect_error(ccx_run_fast(sp, F), "NO N-deposition series")
  # gamma 0 on the same forcing runs
  sp0 <- ccx_spinup(ccx_default_params())
  expect_silent(invisible(ccx_ndep_check(0, F)))
  # the quiet year is stamped: zero by definition, accepted under any gamma
  q <- ps_year_forcing(sp$prod_c14)
  expect_true(all(q$ndep_NH == 0) && all(q$ndep_SH == 0))
  expect_silent(invisible(ccx_ndep_check(0.01, q)))
})

test_that("ACCESSOR: no data file or no scenario = zeros stamped 'none'", {
  nd <- ccx_ndep_forcing(1750:1760, "no_such_scenario_xyz")
  expect_identical(nd$source, "none")
  expect_identical(nd$NH, rep(0, 12L * 11L)); expect_identical(nd$SH, rep(0, 12L * 11L))
})
