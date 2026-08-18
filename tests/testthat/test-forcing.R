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

# ---- fossil-source d13C, time-varying (2026-08-12) -------------------
# ADDED with the fix to the 13C Suess overshoot. The three assertions guard
# three different silent-failure modes, all of which produce plausible output:
#   (1) a revert to a single constant, which is the defect itself;
#   (2) a reordered/short forcing matrix, since the C++ core indexes f[] BY
#       POSITION and would then read c14_cosmo as a per mil value;
#   (3) a hand-built forcing quietly defaulting rather than refusing.
test_that("fossil-source d13C is time-varying and tracks the fuel mix", {
  F <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = 0)
  expect_true("d13c_foss" %in% names(F))
  early <- F$d13c_foss[F$year == 1850][1]
  late  <- F$d13c_foss[F$year == 2024][1]
  # It must MOVE -- a constant here is the bug this replaced.
  expect_gt(early - late, 3)
  # ... and stay inside the published envelope for the global fossil-plus-cement
  # signature: Graven, Keeling & Rogelj (2020) give -28 to -24 per mil, moving
  # more negative as gas displaces coal. Half a per mil of slack either side.
  expect_true(all(F$d13c_foss > -28.5 & F$d13c_foss < -23.5))
  expect_lt(abs(early - (-24.0)), 0.5)   # 1850 is essentially pure coal
})

test_that("the C++ forcing column contract is positional and complete", {
  expect_identical(CCX_FORCING_COLS[10], "d13c_foss")
  # cum_luc APPENDED 2026-08-13 (the converted-land term). Appended rather than
  # inserted so every existing position is untouched; src/ccx_core.cpp's
  # N_FORCING must match this length.
  expect_identical(CCX_FORCING_COLS[11:12], c("cum_luc_NH", "cum_luc_SH"))
  # sst_anom APPENDED 2026-08-18 (observed HadSST4), same discipline: appended,
  # never inserted, and NaN in these two positions means "column absent -> the
  # core falls back to sst_scale * gmst".
  expect_identical(CCX_FORCING_COLS[13:14], c("sst_anom_NH", "sst_anom_SH"))
  expect_length(CCX_FORCING_COLS, 14L)
  F <- ccx_build_forcing("historical", c(1900, 1910), prod_c14 = 0)
  expect_identical(colnames(ccx_cpp_forcing(F)), CCX_FORCING_COLS)
  expect_error(ccx_cpp_forcing(F[, setdiff(names(F), "d13c_foss")]),
               "missing column")
})

test_that("a hand-built forcing with emissions must state its d13c_foss", {
  zero <- list(e_foss = list(NH = 0, SH = 0))
  expect_identical(ccx_forcing_d13c_foss(zero), 0)   # nothing to label
  emit <- list(e_foss = list(NH = 8, SH = 0.4))
  expect_error(ccx_forcing_d13c_foss(emit), "d13c_foss")
  expect_identical(ccx_forcing_d13c_foss(c(emit, list(d13c_foss = -27))), -27)
})
