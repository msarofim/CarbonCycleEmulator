# =====================================================================
# Gate 3: forcing assembly.
#
# The critical property is that annual -> monthly interpolation CONSERVES
# annual totals. Emissions drive cumulative carbon, so an interpolation that
# changes annual sums changes the answer while looking perfectly smooth.
# =====================================================================

test_that("annual-to-monthly interpolation preserves annual means exactly", {
  set.seed(1)
  yrs <- 1900:1950
  v   <- cumsum(rnorm(length(yrs))) + 5
  m   <- ccx_annual_to_monthly(yrs, v, yrs)
  ann <- colMeans(matrix(m, nrow = 12))
  expect_lt(max(abs(ann - v)), 1e-12)
})

test_that("interpolation handles zeros and sign changes without blowing up", {
  # Why the correction is ADDITIVE: a multiplicative rescale divides by the
  # annual mean, which is zero here and negative elsewhere (land-use flux,
  # ENSO index both do this in practice).
  yrs <- 2000:2010
  v <- c(0, 0, 1, -1, 0, 2, -3, 0, 0, 1, 0)
  m <- ccx_annual_to_monthly(yrs, v, yrs)
  expect_true(all(is.finite(m)))
  expect_lt(max(abs(colMeans(matrix(m, nrow = 12)) - v)), 1e-12)
})

test_that("a constant annual series stays exactly constant", {
  m <- ccx_annual_to_monthly(1900:1950, rep(7, 51), 1900:1950)
  expect_lt(max(abs(m - 7)), 1e-12)
})

test_that("historical forcing assembles with the expected shape and no NAs", {
  F <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = 360)
  expect_equal(nrow(F), (2024 - 1750 + 1) * 12)
  for (cl in names(F)) expect_false(anyNA(F[[cl]]), info = cl)
  expect_true(all(F$t > 1750 & F$t < 2025))
})

test_that("emission hemispheric splits sum to the global total", {
  F <- ccx_build_forcing("historical", c(1900, 2000), prod_c14 = 360)
  e <- as.data.frame(readRDS(ccx_path("data", "forcing_emissions_historical.rds")))
  tot_model <- sum(F$e_foss_NH + F$e_foss_SH) / 12          # GtC integrated
  tot_data  <- sum(e$fossil_GtC[e$year >= 1900 & e$year <= 2000])
  expect_lt(abs(tot_model / tot_data - 1), 1e-10)
})

test_that("cumulative fossil emissions match GCB to roundoff", {
  # The number the whole model hinges on: if this drifts, everything downstream
  # is wrong by the same factor while still looking smooth.
  F <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = 360)
  e <- as.data.frame(readRDS(ccx_path("data", "forcing_emissions_historical.rds")))
  cum_model <- sum(F$e_foss_NH + F$e_foss_SH) / 12
  cum_data  <- sum(e$fossil_GtC[e$year >= 1750 & e$year <= 2024], na.rm = TRUE)
  expect_lt(abs(cum_model / cum_data - 1), 1e-10)
})

test_that("gap rules are applied where the records genuinely start", {
  F <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = 360)
  expect_true(all(F$gmst[F$t < 1850] == FORC_GMST_PRE1850))
  expect_true(all(F$enso[F$t < 1948] == FORC_ENSO_PRE1948))
  # 14C sources are strictly zero outside their source records
  expect_true(all(F$c14_bomb[F$t < 1945] == 0))
  expect_true(all(F$c14_bomb[F$t > 1981] == 0))
  expect_true(all(F$c14_bomb >= 0))
})

test_that("bomb 14C total is set by the prior, not by the provisional shape", {
  # The shape is normalised to unit integral, so the placeholder cannot set the
  # magnitude -- only the (citable) total can.
  for (tot in c(50, 102, 150)) {
    F <- ccx_build_forcing("historical", c(1900, 2000), prod_c14 = 0,
                           bomb_total_kmol = tot)
    expect_lt(abs((sum(F$c14_bomb) / 12) / (tot * 1000) - 1), 1e-6)
  }
})

test_that("SSP scenarios assemble and diverge from each other", {
  # suppressWarnings: this checks the EMISSIONS columns, and ccx_build_forcing()
  # rightly warns that it is holding GMST flat past 2024 (use ccx_run_coupled()
  # for a real future climate). Warning about the column this test does not look
  # at is correct behaviour, not something to silence at source.
  a <- suppressWarnings(ccx_build_forcing("ssp126", c(2000, 2100), prod_c14 = 360))
  b <- suppressWarnings(ccx_build_forcing("ssp585", c(2000, 2100), prod_c14 = 360))
  e2100a <- sum(a$e_foss_NH[a$year == 2100] + a$e_foss_SH[a$year == 2100]) / 12
  e2100b <- sum(b$e_foss_NH[b$year == 2100] + b$e_foss_SH[b$year == 2100]) / 12
  expect_lt(e2100a, e2100b)     # ssp126 must be below ssp585 in 2100
})
