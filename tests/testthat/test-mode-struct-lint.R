# =====================================================================
# test-mode-struct-lint.R -- the `struct` class of bug, as a RATCHET.
#
# THE DEFECT THIS GUARDS (2026-09-08f). A mode file now CARRIES its structure
# (`md$struct`), and the ONE resolver is ccx_mode_base(md) (R/paths.R). A
# diagnostic that does
#
#     md <- readRDS(ccx_mode_file()); p <- ccx_default_params(); <overlay par_mode>
#
# runs a HILDA mode as a COLUMN with nothing said: the same vector scores
# -23,306,061 that way and -1439.42 with its structure (CHANGELOG 09-08f,
# diag_adoption_read_hilda31.R measured it). The files listed below still
# read the mode file directly and never call ccx_mode_base() -- some of them
# hard-code ccx_apply_structure(..., "hilda") by hand, some are column-era
# diagnostics that were correct when written. CONVERT ON TOUCH (the 09-02
# ruling for the overlay idiom, applied here): converting one changes what it
# prints, so each conversion needs a look, and this lint stops the count
# GROWING while it shrinks. Same three assertions as test-overlay-idiom-lint.R:
#   1. SUBSET    -- a file with the pattern that is NOT listed fails.
#   2. NO-STALE  -- a LISTED file that no longer has the pattern fails.
#   3. NO-GROWTH -- the occurrence count may not EXCEED the recorded one.
# THE RULE, literal and file-level: contains `readRDS(ccx_mode_file` and does
# NOT contain `ccx_mode_base(`. A file that resolves through ccx_load_mode(),
# dg_vector() or ccx_mode_base() never matches.
# =====================================================================

MS_EXEMPT <- "paths.R"          # defines the resolver; reads the file inside it
MS_DIRS   <- c("R", "calibration", "app", file.path("tests", "testthat"))
MS_READ   <- "readRDS(ccx_mode_file"
MS_BASE   <- "ccx_mode_base("

# The baseline, as of 2026-09-08g: 29 files, 32 OCCURRENCES (not lines --
# test-mode-decode.R carries two on one line). Trim an entry when you convert
# its file.
MS_BASELINE <- c(
  "diag_2x2_repriced_at_enso25.R", "diag_admissible_2x2_land_ocean.R",
  "diag_adoption_read_hilda31.R", "diag_attribute_the_seven.R",
  "diag_gamma_enso_profile.R", "diag_gross_cancellation_geometry.R",
  "diag_hml_mode_decode.R", "diag_hml_unbound_profile.R",
  "diag_joint_land_ocean_refit.R", "diag_phi_eff_profile.R",
  "diag_price_gamma_diff.R", "diag_price_the_lag.R",
  "diag_q10_controlled_recovery.R", "diag_rep_dC_gates.R",
  "diag_seas_T_amp_sh_power.R", "diag_seas_lag_profile.R",
  "diag_seas_npp_sh_power.R", "diag_seas_obs_drivers.R",
  "diag_seas_reanchor_arithmetic.R", "diag_seas_signature_inversion.R",
  "diag_seas_slice_q10_pin.R", "diag_seasonal_fix_vs_gate7.R",
  "diag_sigma_inflation_pricing.R", "diag_sigma_inflation_profile.R",
  "diag_station_representation.R", "diag_surface_d14c_power.R",
  "diag_tau_ex_conditional_power.R", "diag_tau_ex_leak_profile.R",
  "test-mode-decode.R")
MS_BASELINE_N <- 32L

ms_scan <- function() {
  root <- ccx_path()
  fs <- unlist(lapply(MS_DIRS, function(d)
    list.files(file.path(root, d), pattern = "\\.R$", full.names = TRUE)))
  fs <- fs[!basename(fs) %in% MS_EXEMPT]
  hits <- vapply(fs, function(f) {
    txt <- readLines(f, warn = FALSE)
    n <- sum(lengths(regmatches(txt, gregexpr(MS_READ, txt, fixed = TRUE))))
    if (n == 0L || any(grepl(MS_BASE, txt, fixed = TRUE))) 0L else n
  }, integer(1))
  hits <- hits[hits > 0L]
  stats::setNames(as.integer(hits), basename(names(hits)))
}

test_that("the direct-read-without-ccx_mode_base() set is a RATCHET: no new file, no stale entry, no growth", {
  hits <- ms_scan()
  # 1. SUBSET: every file with the pattern is listed
  new <- setdiff(names(hits), MS_BASELINE)
  expect_length(new, 0L)
  if (length(new)) cat("\nNEW direct mode-file reads without ccx_mode_base():", paste(new, collapse = ", "), "\n")
  # 2. NO-STALE: every listed file still has the pattern (convert -> trim the list)
  stale <- setdiff(MS_BASELINE, names(hits))
  expect_length(stale, 0L)
  if (length(stale)) cat("\nSTALE lint entries (converted -- remove them):", paste(stale, collapse = ", "), "\n")
  # 3. NO-GROWTH
  expect_lte(sum(hits), MS_BASELINE_N)
})

test_that("the lint rule fires on the pattern and is silenced by the resolver (mutation test on a temp file)", {
  d <- tempfile("mslint"); dir.create(d)
  writeLines(c("md <- readRDS(ccx_mode_file())", "p <- ccx_default_params()"), file.path(d, "bad.R"))
  writeLines(c("md <- readRDS(ccx_mode_file())", "p <- ccx_mode_base(md)"), file.path(d, "good.R"))
  scan_dir <- function(dd) {
    fs <- list.files(dd, pattern = "\\.R$", full.names = TRUE)
    vapply(fs, function(f) { txt <- readLines(f, warn = FALSE)
      n <- sum(lengths(regmatches(txt, gregexpr(MS_READ, txt, fixed = TRUE))))
      if (n == 0L || any(grepl(MS_BASE, txt, fixed = TRUE))) 0L else n }, integer(1)) }
  h <- scan_dir(d)
  expect_equal(unname(h[basename(names(h)) == "bad.R"]), 1L)
  expect_equal(unname(h[basename(names(h)) == "good.R"]), 0L)
  unlink(d, recursive = TRUE)
})
