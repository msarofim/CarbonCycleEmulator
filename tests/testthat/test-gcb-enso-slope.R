# =====================================================================
# test-gcb-enso-slope.R -- OBJECTIVE #13 (2026-09-18 e): the GCB ENSO ocean-slope
# row `gcb_ocean_enso_slope` (LIK_USE_GCB_ENSO_SLOPE). Contracts, each a MUTATION
# test in the sense of [[mutation_test_gates]]:
#   (1) the obs target reproduces the INDEPENDENT 09-04g estimator's numbers (the
#       T-A2 / limb-probe logs: +0.1153 +/- 0.0246, r +0.488, n 66) -- a fixture
#       from a separate product, not this code
#   (2) ccx_enso_slope() recovers a KNOWN slope exactly on a synthetic series,
#       is invariant to the index's mean (the year term), and is NA below MIN_N
#   (3) ADDITIVE: with the switch ON the 25 pre-#13 rows are BIT-IDENTICAL to the
#       canonical's stored streams; the row is ABSENT (not zero) with the switch
#       OFF, with an obs lacking the target, and it is one finite number ON
#   (4) DIRECTION: at the canonical's point with the limb ON (hilda_cl3,
#       w_enso_l2 18.7, shim 0) the row is BETTER than with the limb OFF (shim
#       0) -- the row rewards the ENSO ocean response it was built to see, and
#       by more than the year-by-year gcb_ocean_sink row does
# =====================================================================
skip_if_no_cpp()
source(ccx_path("calibration", "lib_design_gates.R"))
GES_REF <- c(slope = 0.1153, se = 0.0246, r = 0.488, n = 66)     # outputs/diagnostics/l2_enso_limb_probe_hilda_cl3_20260917.log, "GCB observed"
ges_obs <- ccx_prepare_obs()

test_that("(1) the obs target reproduces the independent 09-04g estimator", {
  s <- ges_obs$enso_slope
  expect_equal(unname(s[["slope"]]), GES_REF[["slope"]], tolerance = 5e-4 / GES_REF[["slope"]])
  expect_equal(unname(s[["se"]]), GES_REF[["se"]], tolerance = 5e-4 / GES_REF[["se"]])
  expect_equal(unname(s[["r"]]), GES_REF[["r"]], tolerance = 2e-3)
  expect_identical(as.integer(s[["n"]]), 66L)
  expect_identical(LIK_ENSO_SLOPE_WIN, c(1959L, 2024L))
})

test_that("(2) the estimator recovers a known slope, ignores the index mean, and is NA below MIN_N", {
  idx <- ges_obs$enso_idx; yrs <- idx$year[idx$year >= 1959 & idx$year <= 2024]
  x <- idx$nino34[match(yrs, idx$year)]
  sink <- 2 + 0.01 * (yrs - 1959) + 0.25 * x                          # slope 0.25 exactly, no noise
  s <- ccx_enso_slope(yrs, sink, idx)
  expect_equal(unname(s[["slope"]]), 0.25, tolerance = 1e-10); expect_lt(s[["se"]], 1e-8); expect_gt(s[["r"]], 0.9)   # r is cor(resid of sink ~ year, x): < 1 by the index's own year-correlation
  idx2 <- idx; idx2$nino34 <- idx2$nino34 + 3                          # a shifted index: the year term absorbs it
  expect_equal(unname(ccx_enso_slope(yrs, sink, idx2)[["slope"]]), 0.25, tolerance = 1e-10)
  expect_true(is.na(ccx_enso_slope(yrs[1:20], sink[1:20], idx)[["slope"]]))   # 20 < LIK_ENSO_SLOPE_MIN_N
  expect_true(is.na(ccx_enso_slope(yrs, sink, idx, win = c(1990L, 2010L))[["slope"]]))
})

ges_v <- dg_vector(CCX_MODE_CANONICAL); ges_r <- dg_run(ges_v)
ges_toggle <- function(on, f) { old <- LIK_USE_GCB_ENSO_SLOPE; assign("LIK_USE_GCB_ENSO_SLOPE", on, envir = globalenv())
  on.exit(assign("LIK_USE_GCB_ENSO_SLOPE", old, envir = globalenv()), add = TRUE); f() }

test_that("(3) ADDITIVE: the 25 pre-#13 rows are bit-identical; the row is absent OFF, absent without a target, one finite number ON", {
  st_on  <- ges_toggle(TRUE,  function() unlist(dg_streams(ges_r, ges_v, obs = ges_obs)))
  st_off <- ges_toggle(FALSE, function() unlist(dg_streams(ges_r, ges_v, obs = ges_obs)))
  old <- names(ges_v$md$streams)
  expect_false("gcb_ocean_enso_slope" %in% names(st_off)); expect_true("gcb_ocean_enso_slope" %in% names(st_on))
  expect_identical(st_on[old], st_off[old])
  expect_equal(unname(st_on[old]), unname(unlist(ges_v$md$streams[old])), tolerance = 1e-9)   # the canonical's stored 25 (a #12 file)
  expect_true(is.finite(st_on[["gcb_ocean_enso_slope"]])); expect_identical(sum(!is.na(st_on)), length(old) + 1L)
  o2 <- ges_obs; o2$enso_slope <- NULL
  st_no <- ges_toggle(TRUE, function() unlist(dg_streams(ges_r, ges_v, obs = o2)))
  expect_false("gcb_ocean_enso_slope" %in% names(st_no)); expect_identical(st_no[old], st_off[old])
  # the row's value is the Gaussian at the obs se, at the model's OWN calendar-year flux slope
  expect_equal(st_on[["gcb_ocean_enso_slope"]], stats::dnorm(ges_obs$enso_slope[["slope"]], ges_obs$enso_slope[["slope"]] - sqrt(-2 * (st_on[["gcb_ocean_enso_slope"]] + log(ges_obs$enso_slope[["se"]] * sqrt(2 * pi)))) * ges_obs$enso_slope[["se"]], ges_obs$enso_slope[["se"]], log = TRUE), tolerance = 1e-8)
})

test_that("(4) DIRECTION: the limb at 18.7 (shim 0) beats the limb off (shim 0) on the new row, by more than on gcb_ocean_sink", {
  base <- ges_v; base$p$gamma_enso_ocn_NH <- 0; base$p$gamma_enso_ocn_SH <- 0
  blk <- ccx_struct_block("hilda_cl3")
  limb <- base; limb$p$k_l2 <- blk$k_l2; limb$p$w0_l2 <- blk$w0_l2; limb$p$w_enso_l2 <- 18.7
  st0 <- unlist(dg_streams(dg_run(base), base, obs = ges_obs)); st1 <- unlist(dg_streams(dg_run(limb), limb, obs = ges_obs))
  d_row <- st1[["gcb_ocean_enso_slope"]] - st0[["gcb_ocean_enso_slope"]]; d_sink <- st1[["gcb_ocean_sink"]] - st0[["gcb_ocean_sink"]]
  expect_gt(d_row, 1)                       # the solubility-only slope is -0.19 (z -12); at 18.7 it is ~+0.12 (z ~0): tens of log-units
  expect_gt(d_row, abs(d_sink))             # the year-by-year row has almost no power on the slope (the 09-18 finding)
})
