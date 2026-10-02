# =====================================================================
# test-obj15.R -- OBJECTIVE #15 (2026-10-02): the three changes that ride with the ENSO-lag
# refit (Marcus 10-02; CHANGELOG 10-02 z, bb; plan notes/plan_2026-10-02_obj15_lag_iced13c.md).
#   W3  the ice-core CO2 row scores only samples before LIK_ICE_CO2_END = 1958 ("Cut to
#       pre-1958"); Inf reproduces objective #14.
#   W2  the Law Dome ice-core d13C row `d13c_icecore` ("Add it in this refit"; D4: sigma
#       sqrt(err^2 + 0.05^2), samples before 1977, every in-run sample from 1750), read like
#       the CO2 row; LIK_USE_ICE_D13C = FALSE reproduces #14.
#   W5  the k_w and tau_ex priors CITED and moved ("1446, log-sd 0.2"; "Mass basis 0.8 /
#       0.26"), from R/constants.R.
# Each row is checked EXACTLY against a hand computation on the same run, and each switch
# against #14's row set. Mutation-tested 2026-10-02 (CHANGELOG 10-02 bb).
# =====================================================================

O15_ARM <- "hilda33d"

.o15_with <- function(d13c, co2_end, f) {
  old <- list(d = LIK_USE_ICE_D13C, c = LIK_ICE_CO2_END)
  on.exit({ assign("LIK_USE_ICE_D13C", old$d, envir = globalenv())
            assign("LIK_ICE_CO2_END", old$c, envir = globalenv()) }, add = TRUE)
  assign("LIK_USE_ICE_D13C", d13c, envir = globalenv())
  assign("LIK_ICE_CO2_END", co2_end, envir = globalenv())
  f()
}

test_that("the rulings, as constants", {
  expect_identical(LIK_ICE_CO2_END, 1958)
  expect_identical(LIK_ICE_D13C_END, 1977)
  expect_true(isTRUE(LIK_USE_ICE_D13C))
  expect_identical(LIK_ICE_D13C_REP_ERR, LIK_D13C_REP_ERR)          # the SPO row's own floor
  expect_identical(LIK_D13C_REP_ERR, 0.05)
  # the obs frame: Rubino's samples with their stated errors, from 1700, sd as ruled
  obs <- ccx_prepare_obs(); icd <- obs$ice_d13c
  raw <- as.data.frame(readRDS(ccx_path("data", "obs_icecore.rds"))$d13c_samples)
  expect_identical(nrow(icd), sum(raw$age_CO2 >= 1700))
  expect_equal(icd$sd, sqrt(icd$err^2 + 0.05^2), tolerance = 0)
  expect_identical(sum(icd$year >= 1750 & icd$year < 1977), 78L)     # the D4 count
})

test_that("W2 + W3: each row IS its hand computation on the same run; the switches give #14", {
  skip_if_no_cpp()
  source(ccx_path("calibration", "lib_design_gates.R"), local = TRUE)
  v <- dg_vector(O15_ARM); r <- dg_run(v); obs <- ccx_prepare_obs()
  rm <- ccx_apply_pins(ccx_mode_pins(v$md)); on.exit(ccx_unpin_params(rm), add = TRUE)
  s15 <- unlist(dg_streams(r, v, obs = obs))
  s14 <- .o15_with(FALSE, Inf, function() unlist(dg_streams(r, v, obs = obs)))
  o <- r$out[r$out$t < DG_SINK_LAST + 1, ]
  t0 <- floor(min(o$t) + 1e-9)
  # W3: the cut row is the in-run samples before 1958, and nothing else moved
  ic <- obs$ice; k <- ic$year >= t0 & ic$year < 1958
  expect_identical(sum(k), 194L)
  want <- sum(stats::dnorm(ic$CO2ppm[k], stats::approx(o$t, o$co2_SH, xout = ic$year[k], rule = 2)$y,
                           ic$sd[k], log = TRUE))
  expect_equal(s15[["co2_icecore"]], want, tolerance = 1e-12)
  k14 <- ic$year >= t0
  want14 <- sum(stats::dnorm(ic$CO2ppm[k14], stats::approx(o$t, o$co2_SH, xout = ic$year[k14], rule = 2)$y,
                             ic$sd[k14], log = TRUE))
  expect_equal(s14[["co2_icecore"]], want14, tolerance = 1e-12)
  # W2: the new row, by hand, read off the SH box exactly as the CO2 row reads it
  icd <- obs$ice_d13c; kd <- icd$year >= t0 & icd$year < 1977
  wantd <- sum(stats::dnorm(icd$d13c[kd], stats::approx(o$t, o$d13c_SH, xout = icd$year[kd], rule = 2)$y,
                            icd$sd[kd], log = TRUE))
  expect_equal(s15[["d13c_icecore"]], wantd, tolerance = 1e-12)
  # ... and it is the SH box, not the NH one (power: the two differ)
  wrong <- sum(stats::dnorm(icd$d13c[kd], stats::approx(o$t, o$d13c_NH, xout = icd$year[kd], rule = 2)$y,
                            icd$sd[kd], log = TRUE))
  expect_gt(abs(wrong - wantd), 0.1)
  # #14 = the switches off: the row ABSENT (not zero), and every other row identical
  expect_false("d13c_icecore" %in% names(s14))
  expect_identical(setdiff(names(s15), names(s14)), "d13c_icecore")
  same <- setdiff(names(s14), "co2_icecore")
  expect_identical(s15[same], s14[same])
  # the stored #14 streams are what the switches-off harness gives. NOT to the bit: dg_run() runs
  # par_mode directly where the objective encodes and decodes it (~1 ulp), and the periodic
  # spinup's tolerance-terminated iteration amplifies that to ~1e-8 relative on a row (CHANGELOG
  # 09-19 m, test-gcb-enso-slope's tolerance and reason); the BIT identity of the objective's own
  # path is calibration/diag_obj15_price.R's check
  st <- unlist(v$md$streams)
  expect_identical(names(s14), names(st))
  expect_equal(unname(s14), unname(st), tolerance = 1e-6)
})

test_that("W2: an obs bundle without the frame skips the row VISIBLY (absent, never zero)", {
  skip_if_no_cpp()
  source(ccx_path("calibration", "lib_design_gates.R"), local = TRUE)
  v <- dg_vector(O15_ARM); r <- dg_run(v); obs <- ccx_prepare_obs()
  rm <- ccx_apply_pins(ccx_mode_pins(v$md)); on.exit(ccx_unpin_params(rm), add = TRUE)
  obs$ice_d13c <- NULL
  s <- unlist(dg_streams(r, v, obs = obs))
  expect_false("d13c_icecore" %in% names(s))
})

test_that("W5: the k_w and tau_ex priors read their cited constants; the inits are the centres", {
  expect_identical(ccx_const("KW_PRIOR_CENTRE"), 1446)
  expect_identical(ccx_const("KW_PRIOR_LOGSD"), 0.2)
  expect_identical(ccx_const("TAU_EX_PRIOR_CENTRE"), 0.8)
  expect_identical(ccx_const("TAU_EX_PRIOR_LOGSD"), 0.26)
  # the literature arithmetic the constants rest on (R/constants.R sources)
  expect_equal(16.5 * 0.01 * 24 * 365.25, 1446.39, tolerance = 1e-6)
  for (n in c("KW_PRIOR_CENTRE", "KW_PRIOR_LOGSD", "TAU_EX_PRIOR_CENTRE", "TAU_EX_PRIOR_LOGSD"))
    expect_true(CCX_CONSTANTS[[n]]$status %in% c("cited", "derived"), info = n)
  expect_match(CCX_CONSTANTS$TAU_EX_PRIOR_CENTRE$source, "MODEL-DERIVED")
  sk <- CCX_PARAM_TABLE$k_w; st <- CCX_PARAM_TABLE$tau_ex
  expect_identical(sk$init, ccx_const("KW_PRIOR_CENTRE"))
  expect_identical(st$init, ccx_const("TAU_EX_PRIOR_CENTRE"))
  for (x in c(900, 1446, 1921, 2500))
    expect_identical(sk$prior(x), stats::dlnorm(x, log(1446), 0.2, log = TRUE))
  for (x in c(0.5, 0.8, 0.898, 1.3))
    expect_identical(st$prior(x), stats::dlnorm(x, log(0.8), 0.26, log = TRUE))
  # the #14 priors are GONE (power: the hilda33d values score differently under them)
  expect_false(isTRUE(all.equal(sk$prior(1921), stats::dlnorm(1921, log(1500), 0.4, log = TRUE))))
  expect_false(isTRUE(all.equal(st$prior(0.898), stats::dlnorm(0.898, log(1.3), 0.25, log = TRUE))))
})
