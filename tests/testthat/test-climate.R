# =====================================================================
# Gate: the FaIR-derived climate module and the coupled runner.
#
# The thing being protected here is a specific silent failure. Before
# 2026-08-11 ccx_build_forcing() extrapolated the IGCC record flat, so every
# future run held the climate at its 2024 temperature and reported nothing.
# A future run must now (a) actually warm, (b) reproduce FaIR when driven with
# FaIR's own forcing, and (c) leave the observational period alone.
# =====================================================================

# skip_if_no_cpp() moved to setup.R on 2026-08-16 (defined here it existed only for
# files that ran after this one); skip_if_no_climate() followed it there 2026-09-12.

# FILE-LEVEL FIXTURES (review B4, 2026-09-12): the same spinup was built in four
# blocks and the SSP5-8.5 coupled run in two (three runs). Lazy, so a machine
# without the C++ core or the climate module still SKIPS rather than errors.
cl_sp <- local({ s <- NULL; function() {
  if (is.null(s)) { p <- ccx_default_params(); p <- ccx_set_enso(p, list(gamma_enso = 0.5)); s <<- ccx_spinup(p) }
  s } })
cl_run585 <- local({ r <- NULL; function() {
  if (is.null(r)) r <<- ccx_run_coupled(cl_sp(), "ssp585", c(1750, 2100)); r } })

test_that("the impulse response reproduces FaIR's own GMST", {
  skip_if_no_climate()
  # Driven with FaIR's total ERF, the fitted response must return FaIR's
  # temperature. This is the fit's own validation, held as a gate so a rebuild
  # that silently degrades it fails here.
  mod  <- ccx_climate_module()
  fair <- as.data.frame(readRDS(ccx_path("data", CLIMATE_SSP_FILE)))
  for (s in unique(fair$scenario)) {
    k <- fair$scenario == s
    pred <- ccx_temperature_from_erf(fair$erf_total[k], fair$year[k], mod)
    e <- pred - fair$gmst_C[k]
    yy <- fair$year[k]
    expect_lt(sqrt(mean(e^2)), 0.05, label = sprintf("%s RMSE vs FaIR", s))
    # what the app actually shows: the projection period
    expect_lt(max(abs(e[yy >= 2050])), 0.12, label = sprintf("%s max|err| 2050+", s))
    # The single worst year is 1817, after Tambora: a 1-year IRF box cannot
    # track a -5 W/m2 one-year volcanic spike. Bounded, not pretended away.
    expect_lt(max(abs(e)), 0.25, label = sprintf("%s max|err| all years", s))
  }
})

test_that("CO2 -> forcing tracks FaIR, is monotone, and is zero at CO2_PI", {
  skip_if_no_climate()
  mod  <- ccx_climate_module()
  fair <- as.data.frame(readRDS(ccx_path("data", CLIMATE_SSP_FILE)))
  # Fitted, not interpolated, so this is a real residual and not a tautology --
  # see the note in data-raw/build_climate_module.R about the version that
  # interpolated every point and reported a meaningless 0.000.
  r <- fair$erf_co2 - ccx_erf_co2(fair$co2_ppm, mod)
  expect_lt(sqrt(mean(r^2)), 0.05)
  expect_lt(max(abs(r)), 0.20)
  # monotone increasing over the whole fitted range, and exactly zero at CO2_PI
  cc <- seq(mod$co2_erf_range[1], mod$co2_erf_range[2], length.out = 2000)
  expect_true(all(diff(ccx_erf_co2(cc, mod)) > 0))
  expect_equal(ccx_erf_co2(mod$co2_pi, mod), 0, tolerance = 1e-12)
  # 2xCO2 ERF must land near the value FaIR's own formulation gives (~3.9 W/m2)
  f2x <- ccx_erf_co2(2 * mod$co2_pi, mod)
  expect_gt(f2x, 3.5); expect_lt(f2x, 4.3)
})

test_that("erf_co2 really is a function of concentration alone", {
  skip_if_no_climate()
  # THE check the fitted-residual test cannot make. Interpolate each scenario
  # separately onto a common CO2 grid: if erf_co2 depended on anything besides
  # concentration, scenarios would disagree at matched CO2. They agree to
  # 0.03 W/m2, the residual width coming from these being ENSEMBLE MEANS over
  # 841 configs with differing CO2 forcing scale factors.
  fair <- as.data.frame(readRDS(ccx_path("data", CLIMATE_SSP_FILE)))
  gr <- seq(320, 900, by = 20)
  mat <- sapply(unique(fair$scenario), function(s) {
    k <- fair$scenario == s; x <- fair$co2_ppm[k]; y <- fair$erf_co2[k]
    o <- order(x); x <- x[o]; y <- y[o]; d <- !duplicated(x)
    ifelse(gr >= min(x) & gr <= max(x), stats::approx(x[d], y[d], xout = gr)$y, NA)
  })
  spread <- apply(mat, 1, function(z) diff(range(z, na.rm = TRUE)))
  expect_lt(max(spread, na.rm = TRUE), 0.05)
})

test_that("a future run warms, instead of holding 2024 flat", {
  skip_if_no_cpp(); skip_if_no_climate()
  # The regression test for the actual bug.
  sp <- cl_sp()
  r <- cl_run585()
  cl <- r$climate
  t2024 <- cl$gmst[cl$year == 2024]
  t2100 <- cl$gmst[cl$year == 2100]
  expect_gt(t2100 - t2024, 1.5)          # flat extrapolation gave exactly 0
  expect_true(r$converged)
  expect_lte(r$iterations, CLIM_MAX_ITER)
  # and the ordering across scenarios is the physical one
  temps <- vapply(c("ssp119", "ssp245", "ssp585"), function(s) {
    z <- if (s == "ssp585") cl_run585()$climate else ccx_run_coupled(sp, s, c(1750, 2100))$climate
    z$gmst[z$year == 2100]
  }, numeric(1))
  expect_true(all(diff(temps) > 0))
})

test_that("the splice leaves the observational record untouched", {
  skip_if_no_cpp(); skip_if_no_climate()
  sp <- cl_sp()
  r <- ccx_run_coupled(sp, "historical", c(1750, 2024))
  g <- as.data.frame(readRDS(ccx_path("data", "forcing_gmst.rds")))
  m <- merge(r$climate[, c("year", "gmst")], g, by = "year")
  expect_gt(nrow(m), 100)
  expect_lt(max(abs(m$gmst - m$gmst_anom)), 1e-10)
})

test_that("the carbon-climate feedback is actually engaged", {
  skip_if_no_cpp(); skip_if_no_climate()
  # If the outer loop were not feeding temperature back into the carbon cycle,
  # one pass and many passes would agree. Measured difference on SSP5-8.5 at
  # 2100 is ~111 ppm and ~0.3 C -- large enough that an accidental decoupling
  # cannot hide.
  sp <- cl_sp()
  on  <- cl_run585()$climate
  # one pass is unconverged BY DESIGN here, and since 2026-10-12 (code review sec.5) it says so
  off <- expect_warning(ccx_run_coupled(sp, "ssp585", c(1750, 2100), max_iter = 1L),
                        "did NOT converge")$climate
  k <- on$year == 2100
  expect_gt(on$co2_ppm[k] - off$co2_ppm[k], 30)
  expect_gt(on$gmst[k] - off$gmst[k], 0.1)
})

test_that("caller-supplied emissions override the scenario, conserving totals", {
  skip_if_no_cpp()
  # The path the app's stylized scenarios and pulses take.
  yrs <- 1750:2100
  em <- data.frame(year = yrs,
                   fossil_GtC = ifelse(yrs < 2000, 0, 5),
                   luc_GtC = 0)
  sp <- cl_sp()
  F <- suppressWarnings(
    ccx_build_forcing("ssp245", c(1750, 2100), prod_c14 = sp$prod_c14,
                      emissions = em))
  # annual totals must survive the monthly interpolation exactly
  ann <- tapply(F$e_foss_NH + F$e_foss_SH, F$year, mean)
  expect_equal(as.numeric(ann), em$fossil_GtC, tolerance = 1e-10)
  # and it must differ from the scenario it nominally names
  Fs <- suppressWarnings(
    ccx_build_forcing("ssp245", c(1750, 2100), prod_c14 = sp$prod_c14))
  expect_gt(max(abs(F$e_foss_NH - Fs$e_foss_NH)), 1)
})

test_that("ccx_build_forcing warns when it holds GMST flat", {
  p <- ccx_default_params()
  sp_prod <- 333
  expect_warning(ccx_build_forcing("ssp245", c(1750, 2100), prod_c14 = sp_prod),
                 "held FLAT")
  expect_silent(ccx_build_forcing("historical", c(1750, 2024), prod_c14 = sp_prod))
})
