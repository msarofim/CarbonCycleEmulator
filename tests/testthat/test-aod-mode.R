# =====================================================================
# test-aod-mode.R -- the AOD background axis (2026-09-29, Marcus)
#
# `aod_mode = "anomaly"` removes the quiet-stratosphere background that the
# diffuse-light term used to see as a step at 1850 and 2025. For that to be true:
#   1. "legacy" (default) is the shipped column, stamped;
#   2. "anomaly" has no step at the series' start, a CONTINUOUS taper past its
#      end on a decay time measured from the series, and changes nothing else;
#   3. a params/forcing mismatch refuses to run (mutation tests).
# =====================================================================

FA <- lapply(setNames(nm = names(CCX_AOD_MODE_CODES)), function(m)
  suppressWarnings(ccx_build_forcing("historical", c(1840, 2040), prod_c14 = 0, aod_mode = m)))

test_that("legacy is the default, stamped, and carries the background steps", {
  d <- suppressWarnings(ccx_build_forcing("historical", c(1840, 2040), prod_c14 = 0))
  expect_identical(attr(d, "aod_mode"), "legacy")
  expect_identical(d$aod_NH, FA$legacy$aod_NH)
  expect_identical(ccx_aod_mode_of(ccx_default_params()), "legacy")
  # the defect the axis exists to remove: a step up at 1850, down after 2024
  expect_gt(mean(d$aod_NH[d$year == 1850]) - mean(d$aod_NH[d$year == 1849]), 0.0015)
  expect_true(all(d$aod_NH[d$year >= 2025] == 0))
})

test_that("anomaly: no start step, continuous measured taper, nothing else moves", {
  a <- FA$anomaly
  for (cc in c("aod_NH", "aod_SH")) {
    expect_lt(abs(mean(a[[cc]][a$year == 1850])), 2e-4, label = paste(cc, "1850"))
    expect_true(all(a[[cc]][a$year < 1850] == 0))
    i <- max(which(a$year == 2024))
    # continuity across the record's end: one month of taper, not a drop to 0
    expect_lt(abs(a[[cc]][i + 1] - a[[cc]][i]) / abs(a[[cc]][i]), 0.1, label = paste(cc, "seam"))
    expect_lt(abs(a[[cc]][a$year == 2040][1]), 1e-5)
  }
  tau <- ccx_aod_efold_yr()
  expect_gt(tau, 0.25); expect_lt(tau, 5)   # a stratospheric decay, measured -- not a typed value
  for (cc in setdiff(names(a), c("aod_NH", "aod_SH")))
    expect_identical(a[[cc]], FA$legacy[[cc]], label = cc)
})

test_that("a params/forcing AOD-mode mismatch refuses to run (mutation tests)", {
  p0 <- ccx_default_params(); p1 <- p0; p1$aod_mode <- CCX_AOD_MODE_CODES[["anomaly"]]
  expect_error(ccx_aod_mode_check(p1, FA$legacy), "AOD mode mismatch")
  expect_error(ccx_aod_mode_check(p0, FA$anomaly), "AOD mode mismatch")
  un <- FA$anomaly; attr(un, "aod_mode") <- NULL
  expect_error(ccx_aod_mode_check(p1, un), "unstamped")
  expect_true(ccx_aod_mode_check(p1, FA$anomaly))
  expect_error(ccx_run_prepared(NULL, list(aod_mode = "anomaly"), FA$legacy), "AOD mode mismatch")
  p9 <- p0; p9$aod_mode <- 7L
  expect_error(ccx_aod_mode_of(p9), "not one of")
})
