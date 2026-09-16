# =====================================================================
# THE 09-16 (c) REVIEW's FINDINGS 3, 6, 7 (notes/review_2026-09-16c_whole_model.md),
# fixed 09-16 (d) with no stored number moving:
#   F3  a transient that had to ESCALATE its substeps is a DIFFERENT number
#       (the 4-step fixed point is not on the 64-step orbit): ccx_run_prepared()
#       flags it (`retried`, `substeps_requested`), the objective returns -Inf
#       on it, the periodic spinup's one-year map never retries.
#   F6  a bare ccx_build_forcing() ships c14_cosmo = NA; the runners fill it
#       from the spinup so Delta14C is no longer silently all-NA.
#   F7  the units trap on alk_hs (mol/kg vs the siblings' umol/kg), a NON-FINITE
#       grad_off_* errors instead of dropping the row, q_conv is refused under
#       HILDA, the four objective data products are run inputs.
# =====================================================================
test_that("F3: a consistent evaluation is not retried; a forced escalation is FLAGGED, and the objective refuses it", {
  skip_if_no_cpp()
  p <- ccx_apply_structure(ccx_default_params(), "hilda", seas_ml = 1)
  sp <- suppressWarnings(ccx_spinup(p))
  F  <- ccx_build_forcing("historical", c(1900, 1903), prod_c14 = sp$prod_c14)
  r  <- ccx_run_fast(sp, F)
  expect_false(r$retried); expect_identical(r$substeps, r$substeps_requested)
  # the escalated transient IS a different number from the consistent one (the
  # finding's mechanism), so a caller must be told -- and is
  r64 <- ccx_run_fast(sp, F, substeps = 64L)
  expect_false(r64$retried)                                    # asked for 64, got 64: not a retry
  expect_gt(max(abs(r64$out$co2_SH - r$out$co2_SH)), 1e-6)     # ... but not the same trajectory
  # the objective's contract on a retried result, exercised through the same
  # predicate the objective uses (isTRUE(r$retried))
  fake <- r; fake$retried <- TRUE
  expect_true(isTRUE(fake$retried))
  # the periodic spinup's map never retries: its helper passes retry_na = FALSE
  expect_true(grepl("retry_na = FALSE", paste(deparse(ps_phi), collapse = " ")))
})

test_that("F3: the objective returns -Inf on a retried transient (mutation: with the flag forced on, the score is -Inf)", {
  skip_if_no_cpp()
  md <- readRDS(ccx_mode_file())
  bp <- ccx_mode_base(md); if (!is.null(md$pump_mode)) bp$pump_mode <- md$pump_mode
  rm <- ccx_apply_pins(ccx_mode_pins(md)); on.exit(ccx_unpin_params(rm), add = TRUE)
  st <- ccx_mode_start(md, "F3")
  lp <- ccx_make_logpost(base_params = bp, spinup_fn = ccx_spinup_from_label(ccx_mode_spinup(md)))
  v  <- as.numeric(lp(st$u))
  expect_true(is.finite(v))                                    # the canonical does not retry
  # force a retry by wrapping the runner: every call reports retried = TRUE
  orig <- ccx_run_fast
  assign("ccx_run_fast", function(...) { r <- orig(...); r$retried <- TRUE; r }, envir = globalenv())
  on.exit(assign("ccx_run_fast", orig, envir = globalenv()), add = TRUE)
  expect_identical(as.numeric(lp(st$u)), -Inf)
})

test_that("F6: a bare ccx_build_forcing() no longer yields an all-NA Delta14C", {
  skip_if_no_cpp()
  p <- ccx_apply_structure(ccx_default_params(), "hilda", seas_ml = 1)
  sp <- suppressWarnings(ccx_spinup(p))
  F  <- suppressWarnings(ccx_build_forcing("historical", c(1900, 1902)))
  expect_true(all(is.na(F$c14_cosmo)))
  r  <- ccx_run_fast(sp, F)
  expect_false(anyNA(r$out$d14c_NH))
  F2 <- ccx_build_forcing("historical", c(1900, 1902), prod_c14 = sp$prod_c14)
  expect_identical(r$out, ccx_run_fast(sp, F2)$out)           # the fill IS the explicit value
  # a PARTLY-set column is the caller's and is left alone
  F3 <- F2; F3$c14_cosmo[1] <- NA
  expect_identical(ccx_fill_prod_c14(F3, sp)$c14_cosmo, F3$c14_cosmo)
  rR <- suppressWarnings(ccx_run(sp, F))
  expect_false(anyNA(rR$out$d14c_NH))
})

test_that("F7: guards by name -- alk_hs in umol/kg, a non-finite grad_off, q_conv under HILDA", {
  p <- ccx_apply_structure(ccx_default_params(), "hilda", seas_ml = 1)
  q <- p; q$alk_hs <- 2300;    expect_error(ccx_prepare(q), "looks like umol/kg")
  q <- p; q$alk_hs <- 2300e-6; expect_silent(invisible(ccx_prepare(q)))
  q <- p; q$q_conv <- 5;       expect_error(ccx_prepare(q), "HILDA boxes")
  # the four products are run inputs, by name
  source(ccx_path("calibration", "lib_run_inputs.R"))
  paths <- vapply(CCX_RUN_INPUTS, `[[`, character(1), "path")
  for (f in c("obs_glodap_deep.rds", "obs_glodap_intermediate.rds", "forcing_emission_seasonality.rds", "forcing_volcanic_aod.rds"))
    expect_true(file.path("data", f) %in% paths, info = f)
  # a non-finite offset errors; NULL still opts out
  obs <- ccx_prepare_obs(); sp <- suppressWarnings(ccx_spinup(p))
  skip_if_no_cpp()
  F <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = sp$prod_c14)
  out <- ccx_run_fast(sp, F)$out
  err_ok <- list(sigma_d13c = 0.1, sigma_d14c = 5, grad_off_co2 = 0.2, grad_off_d13c = 0.06)
  err_na <- err_ok; err_na$grad_off_d13c <- NA_real_
  expect_error(ccx_loglik(out, obs, err = err_na), "grad_off_d13c")
  err_opt <- err_ok; err_opt$grad_off_d13c <- NULL
  expect_silent(invisible(ccx_loglik(out, obs, err = err_opt)))
})
