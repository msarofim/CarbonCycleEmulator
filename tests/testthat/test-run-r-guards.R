# =====================================================================
# test-run-r-guards.R -- the pure-R core runs the four forcing guards (2026-10-14 o, Marcus)
#
# ccx_run_prepared() has refused a params/forcing mismatch on the ENSO index and the AOD mode
# (09-29), N deposition (09-30) and the nuclear 14C share (10-12). ccx_run() checked none, so a
# diagnostic that fed the canonical's params a default-built forcing ran on the DEFAULT variants
# with no error (CHANGELOG 2026-10-14 n: five such scripts under calibration/). For that to stay
# fixed:
#   R1-R4. ccx_run() refuses each mismatch with that guard's own message (mutation tests: delete
#          one guard call from ccx_run() and its row fails);
#   R5.    the failure the scripts had -- a DEFAULT-built ccx_build_forcing() under params naming
#          another ENSO index -- is refused;
#   R6.    a forcing stamped from the params passes all four (it then fails on the fake spin,
#          past the guards).
# The guards sit before any use of the state, so a fake spin is enough and nothing spins up.
# =====================================================================

RG_F <- data.frame(t = 2000 + (0:11) / 12)   # UNSTAMPED: read as demean / legacy / constant, no deposition
rg_run <- function(params, F = RG_F) ccx_run(list(params = params, y = NULL, aux = NULL, grid = NULL), F)
RG_GUARD_MSG <- "ENSO index mismatch|AOD mode mismatch|nuclear 14C share mismatch|NO N-deposition series"

test_that("R1 ccx_run() refuses an ENSO-index mismatch", {
  expect_error(rg_run(list(enso_index = CCX_ENSO_INDEX_CODES[["detrend"]])), "ENSO index mismatch")
})

test_that("R2 ccx_run() refuses an AOD-mode mismatch", {
  expect_error(rg_run(list(aod_mode = CCX_AOD_MODE_CODES[["anomaly"]])), "AOD mode mismatch")
})

test_that("R3 ccx_run() refuses a nuclear 14C share mismatch", {
  expect_error(rg_run(list(nuc_share_ts = CCX_NUC_SHARE_CODES[["per_year"]])), "nuclear 14C share mismatch")
})

test_that("R4 ccx_run() refuses a nonzero ndep_ret on a forcing with no deposition series", {
  expect_error(rg_run(list(ndep_ret = 0.5)), "NO N-deposition series")
})

test_that("R5 a DEFAULT-built forcing under params naming another ENSO index is refused (the scripts' failure)", {
  Fd <- suppressWarnings(ccx_build_forcing("historical", c(2000, 2001), prod_c14 = 0))
  expect_identical(attr(Fd, "enso_index"), "demean")                 # the default the scripts got
  expect_error(rg_run(list(enso_index = CCX_ENSO_INDEX_CODES[["detrend"]]), Fd), "ENSO index mismatch")
})

test_that("R6 a forcing stamped from the params passes all four guards", {
  p <- list(enso_index = CCX_ENSO_INDEX_CODES[["detrend"]], aod_mode = CCX_AOD_MODE_CODES[["anomaly"]],
            nuc_share_ts = CCX_NUC_SHARE_CODES[["per_year"]], ndep_ret = 0.5)
  Fs <- RG_F
  attr(Fs, "enso_index") <- ccx_enso_index_of(p); attr(Fs, "aod_mode") <- ccx_aod_mode_of(p)
  attr(Fs, "nuc_share") <- ccx_nuc_share_of(p); attr(Fs, "ndep_source") <- "a test deposition series"
  msg <- tryCatch({ rg_run(p, Fs); "" }, error = conditionMessage)
  expect_true(nzchar(msg))                       # the fake spin is reached, so the call did not succeed silently
  expect_false(grepl(RG_GUARD_MSG, msg))         # ...and what stopped it was NOT a guard
})
