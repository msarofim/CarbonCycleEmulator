# Extracted from test-mode-struct-lint.R:77

# prequel ----------------------------------------------------------------------
MS_EXEMPT <- "paths.R"
MS_DIRS   <- c("R", "calibration", "app", file.path("tests", "testthat"))
MS_READ   <- "readRDS(ccx_mode_file"
MS_BASE   <- "ccx_mode_base("
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
MS_BASELINE_N <- 31L
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

# test -------------------------------------------------------------------------
hits <- ms_scan()
new <- setdiff(names(hits), MS_BASELINE)
expect_length(new, 0L)
if (length(new)) cat("\nNEW direct mode-file reads without ccx_mode_base():", paste(new, collapse = ", "), "\n")
stale <- setdiff(MS_BASELINE, names(hits))
expect_length(stale, 0L)
if (length(stale)) cat("\nSTALE lint entries (converted -- remove them):", paste(stale, collapse = ", "), "\n")
expect_lte(sum(hits), MS_BASELINE_N)
