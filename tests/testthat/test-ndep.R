# =====================================================================
# test-ndep.R -- D2 (a), the N-deposition RETENTION FLUX (Marcus 2026-09-30:
# "definitely add non-CO2 contributors"; form ruled the same day: "Retention flux").
# R/model.R CCX_NDEP_RET_DEFAULT, src/ccx_core.cpp, R/forcing.R ccx_ndep_forcing().
#
#   F_h = ndep_ret * 1e-3 * max(ndep_h, 0)  GtC/yr, atmosphere -> soil_slow, at alpha_photo
#   ndep_h = anthropogenic deposition onto hemisphere h's land, Tg N/yr above 1750.
#
# It REPLACED an NPP multiplier (1 + gamma_ndep * ndep_h) the same day: that form
# made the sink track d(ndep)/dt and could not reach the literature's steady kg C
# per kg N (calibration/diag_ndep_form_efficiency.R, CHANGELOG 09-30 l/m).
#
#   OFF      ndep_ret 0 ignores even a loud deposition column, bit for bit.
#   EXACT    the flux IS ndep_ret * 1e-3 * ndep_h, it lands in soil_slow, and it is
#            clamped at zero deposition (a one-way photosynthetic flux).
#   PARITY   both cores agree at explicit values, with the COLUMN absent (= zero) and
#            the PARAMETER absent (= the default).
#   TRAJ     an 80-yr trajectory agrees between the cores with it ON.
#   CONSERVE carbon is conserved with it ON.
#   GUARD    a nonzero retention on a forcing with no deposition series is REFUSED;
#            the periodic spinup's quiet year is accepted (zero by definition).
#   ACCESSOR no scenario / partial coverage = zeros stamped 'none...'.
# Mutation-tested 2026-09-30 (CHANGELOG 09-30 m).
# =====================================================================

NDEP_TEST_LOUD <- c(NH = 40, SH = 8)       # Tg N/yr, ~ the modern order, NH-heavy (synthetic)
NDEP_TEST_RET  <- c(0, 3.9, 8.7)           # kg C/kg N: off, the prior centre, the literature ceiling

.nd_forcing <- function(sp, years = c(1900, 1980)) {
  F <- suppressWarnings(ccx_build_forcing("historical", years, prod_c14 = sp$prod_c14))
  F$ndep_NH <- NDEP_TEST_LOUD[["NH"]] * (F$year - years[1]) / diff(years)   # a ramp
  F$ndep_SH <- NDEP_TEST_LOUD[["SH"]] * (F$year - years[1]) / diff(years)
  attr(F, "ndep_source") <- "synthetic ramp (test-ndep.R)"
  F
}

test_that("OFF: ndep_ret 0 ignores even a loud deposition column, bit for bit", {
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

test_that("EXACT: the flux is ndep_ret * 1e-3 * ndep_h into soil_slow, clamped at zero", {
  p <- ccx_default_params(); sp <- ccx_spinup(p)
  f <- list(e_foss = list(NH = 0, SH = 0), e_luc = list(NH = 0, SH = 0),
            gmst = 0, enso = 0, c14_bomb = 0, c14_nuclear = 0, c14_cosmo = sp$prod_c14,
            ndep_NH = NDEP_TEST_LOUD[["NH"]], ndep_SH = NDEP_TEST_LOUD[["SH"]])
  p0 <- p; p1 <- p; p1$ndep_ret <- 3.9
  d0 <- ccx_deriv(sp$y, 1900, p0, f, sp$grid, sp$aux)
  d1 <- ccx_deriv(sp$y, 1900, p1, f, sp$grid, sp$aux)
  dd <- d1[, "C"] - d0[, "C"]
  for (h in HEMIS) {
    i <- sp$aux$idx[[h]]
    flux <- 3.9 * 1e-3 * NDEP_TEST_LOUD[[h]]
    expect_equal(unname(dd[i$soil_slow]), flux, tolerance = 1e-12, info = h)
    expect_equal(unname(dd[i$atm]), -flux, tolerance = 1e-12, info = h)
  }
  expect_lt(max(abs(dd[-unlist(lapply(HEMIS, function(h) sp$aux$idx[[h]][c("atm", "soil_slow")]))])), 1e-15)
  # 13C: photosynthetic, i.e. the atmosphere's ratio times alpha_photo
  d13 <- d1[, "C13"] - d0[, "C13"]; i <- sp$aux$idx$NH
  expect_equal(unname(d13[i$soil_slow]) / unname(dd[i$soil_slow]),
               unname(sp$y[i$atm, "C13"] / sp$y[i$atm, "C"]) * sp$aux$alpha_photo, tolerance = 1e-12)
  # CLAMPED: negative deposition gives no flux at all (one-way)
  fn <- f; fn$ndep_NH <- -5; fn$ndep_SH <- -1
  expect_identical(ccx_deriv(sp$y, 1900, p1, fn, sp$grid, sp$aux), d0)
})

test_that("PARITY: both cores agree at explicit values and at both absences", {
  skip_if_no_cpp()
  p  <- ccx_default_params(); sp <- ccx_spinup(p)
  F  <- .nd_forcing(sp); i <- nrow(F) - 6L; t <- F$t[i]
  f  <- ccx_forcing_at(F, i)
  expect_gt(f$ndep_NH, 30)
  for (r in NDEP_TEST_RET) {
    p$ndep_ret <- r
    expect_equal(ccx_deriv(sp$y, t, p, f, sp$grid, sp$aux),
                 ccx_deriv_fast(sp$y, t, p, f, sp$grid, sp$aux), tolerance = 1e-12, info = r)
  }
  p$ndep_ret <- 8.7
  f0 <- f; f0$ndep_NH <- 0; f0$ndep_SH <- 0
  expect_gt(max(abs(ccx_deriv_fast(sp$y, t, p, f, sp$grid, sp$aux) -
                    ccx_deriv_fast(sp$y, t, p, f0, sp$grid, sp$aux))), 0.1)        # POWER
  fn <- f; fn$ndep_NH <- NULL; fn$ndep_SH <- NULL                                  # COLUMN absent = 0
  expect_equal(ccx_deriv_fast(sp$y, t, p, fn, sp$grid, sp$aux), ccx_deriv_fast(sp$y, t, p, f0, sp$grid, sp$aux), tolerance = 1e-12)
  expect_equal(ccx_deriv(sp$y, t, p, fn, sp$grid, sp$aux), ccx_deriv(sp$y, t, p, f0, sp$grid, sp$aux), tolerance = 1e-12)
  pa <- p; pa$ndep_ret <- NULL; pe <- p; pe$ndep_ret <- CCX_NDEP_RET_DEFAULT        # PARAMETER absent = default
  expect_equal(ccx_deriv(sp$y, t, pa, f, sp$grid, sp$aux), ccx_deriv_fast(sp$y, t, pa, f, sp$grid, sp$aux), tolerance = 1e-12)
  expect_equal(ccx_deriv_fast(sp$y, t, pa, f, sp$grid, sp$aux), ccx_deriv_fast(sp$y, t, pe, f, sp$grid, sp$aux), tolerance = 1e-12)
  expect_equal(ccx_deriv(sp$y, t, pa, f, sp$grid, sp$aux), ccx_deriv(sp$y, t, pe, f, sp$grid, sp$aux), tolerance = 1e-12)
  # the C++ clamp too
  fneg <- f; fneg$ndep_NH <- -5; fneg$ndep_SH <- -1
  expect_equal(ccx_deriv_fast(sp$y, t, p, fneg, sp$grid, sp$aux), ccx_deriv_fast(sp$y, t, p, f0, sp$grid, sp$aux), tolerance = 1e-12)
})

test_that("TRAJ: an 80-yr trajectory agrees between the cores with it ON", {
  skip_if_no_cpp()
  p <- ccx_default_params(); p$ndep_ret <- 3.9
  sp <- ccx_spinup(p); F <- .nd_forcing(sp)
  rR <- suppressWarnings(ccx_run(sp, F)); rC <- suppressWarnings(ccx_run_fast(sp, F))
  for (cc in c("co2_NH", "co2_SH", "land_C", "ocean_C", "land_C14"))
    expect_lt(max(abs(rR$out[[cc]] - rC$out[[cc]])) / max(abs(rR$out[[cc]])), 1e-13, label = cc)
  expect_lt(max(abs(rR$state - rC$state)) / max(abs(rR$state)), 1e-13)
  rOff <- suppressWarnings(ccx_run_fast(ccx_spinup(ccx_default_params()), F))
  expect_gt(max(abs(rOff$out$land_C - rC$out$land_C)) / max(abs(rC$out$land_C)), 1e-5)
})

test_that("CONSERVE: closed-system carbon is conserved with it ON", {
  p <- ccx_set_enso(ccx_default_params(), list(gamma_enso = 0)); p$ndep_ret <- 8.7
  sp <- ccx_spinup(p)
  closed <- list(e_foss = list(NH = 0, SH = 0), e_luc = list(NH = 0, SH = 0),
                 gmst = 0, enso = 0, c14_bomb = 0, c14_nuclear = 0, c14_cosmo = 0,
                 ndep_NH = NDEP_TEST_LOUD[["NH"]], ndep_SH = NDEP_TEST_LOUD[["SH"]])
  y <- sp$y
  d <- ccx_deriv(y, 1900, p, closed, sp$grid, sp$aux)
  expect_lt(abs(sum(d[, "C"])) / max(abs(d[, "C"])), 1e-12)
  tot0 <- ccx_total(y); t <- 1900
  for (m in seq_len(12 * 30)) { y <- ccx_step_rk4(y, t, 1 / 12, p, closed, sp$grid, sp$aux); t <- t + 1 / 12 }
  expect_lt(abs(ccx_total(y) / tot0 - 1), 1e-10)
})

test_that("GUARD: a nonzero retention on a forcing with NO deposition series is refused", {
  skip_if_no_cpp()
  p <- ccx_default_params(); p$ndep_ret <- 3.9
  sp <- ccx_spinup(p)
  F <- suppressWarnings(ccx_build_forcing("historical", c(1900, 1910), prod_c14 = sp$prod_c14))
  attr(F, "ndep_source") <- "none"
  expect_error(ccx_run_fast(sp, F), "NO N-deposition series")
  attr(F, "ndep_source") <- NULL
  expect_error(ccx_run_fast(sp, F), "NO N-deposition series")
  expect_silent(invisible(ccx_ndep_check(0, F)))
  q <- ps_year_forcing(sp$prod_c14)                          # zero by definition, accepted
  expect_true(all(q$ndep_NH == 0) && all(q$ndep_SH == 0))
  expect_silent(invisible(ccx_ndep_check(3.9, q)))
})

test_that("ACCESSOR: no scenario, or partial coverage = zeros stamped 'none...'", {
  nd <- ccx_ndep_forcing(1750:1760, "no_such_scenario_xyz")
  expect_identical(nd$source, "none")
  expect_identical(nd$NH, rep(0, 12L * 11L)); expect_identical(nd$SH, rep(0, 12L * 11L))
  skip_if(!file.exists(ccx_path("data", CCX_NDEP_FILE)), "data/forcing_ndep.rds not built")
  np <- ccx_ndep_forcing(2020:2030, "historical")
  expect_match(np$source, "^none \\(historical covers")
  expect_true(all(np$NH == 0))
  F <- list(); attr(F, "ndep_source") <- np$source
  expect_error(ccx_ndep_check(0.1, F), "NO N-deposition series")
  expect_silent(invisible(ccx_ndep_check(0, F)))
  nh <- ccx_ndep_forcing(1750:2000, "historical")
  expect_match(nh$source, "\\[historical\\]$")
  expect_identical(nh$NH[1:12], rep(0, 12))
  expect_gt(tail(nh$NH, 1), 30); expect_gt(tail(nh$NH, 1) / tail(nh$SH, 1), 4)
})
