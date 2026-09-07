# Extracted from test-overlay-idiom-lint.R:106

# prequel ----------------------------------------------------------------------
OI_EXEMPT <- "model.R"
OI_BASELINE <- c(
  "calibrate.R", "lib_design_gates.R",
  "diag_admissible_2x2_land_ocean.R", "diag_af_trend_levers.R",
  "diag_co2_level_swing.R", "diag_d13c_midcentury.R",
  "diag_design_gates_unscored.R", "diag_enso_gpp_margin.R",
  "diag_enso_objective_leverage.R", "diag_fert_ridge_gates.R",
  "diag_fert_ridge_repdc.R", "diag_fert_ridge_residual.R",
  "diag_fert_ridge_streams.R", "diag_gamma_enso_profile.R",
  "diag_gates_at_landed_modes.R", "diag_gradient_terms.R",
  "diag_hml_band_discontinuity.R", "diag_hml_seasonal_limbs.R",
  "diag_hml_sst_elasticity.R", "diag_hml_unbound_profile.R",
  "diag_ice_hemisphere.R", "diag_joint_land_ocean_refit.R",
  "diag_joos_irf.R", "diag_kz_railed.R", "diag_land_eagerness.R",
  "diag_landed_gap_streams.R", "diag_luc_arm_ridge_confound.R",
  "diag_p3_sigma_d14c_contamination.R", "diag_price_gamma_diff.R",
  "diag_price_the_lag.R", "diag_q10_controlled_recovery.R",
  "diag_rep_dC_shape.R", "diag_seas_isotope_rectification.R",
  "diag_seas_npp_sh_power.R", "diag_seas_slice_q10_pin.R",
  "diag_seas_T_amp_sh_power.R", "diag_seasonal_fix_vs_gate7.R",
  "diag_seasonal_tau_ex.R", "diag_sigma_inflation_pricing.R",
  "diag_so_entrainment_refit.R", "diag_split_lag_prediction.R",
  "diag_station_representation.R", "diag_stream_neff.R",
  "diag_swing_estimator.R", "diag_tau_ex_conditional_power.R",
  "diag_tau_ex_seasonal_power.R", "profile_bomb_total.R",
  "profile_kz_ventilation.R", "run_modefind_pump_arms.R",
  "run_modefind.R", "run_post_refit_adoption.R",
  "test-gate-bounds.R", "test-luc-scale.R")
OI_BASELINE_N <- 61L
OI_RX <- paste0("for[[:space:]]*\\([[:space:]]*[A-Za-z._][A-Za-z0-9._]*",
                "[[:space:]]+in[[:space:]]+intersect[[:space:]]*\\(",
                "[[:space:]]*names\\(")
oi_scan <- function() {
  root  <- ccx_root()
  files <- c(list.files(file.path(root, "R"),           "[.]R$", full.names = TRUE),
             list.files(file.path(root, "calibration"), "[.]R$", full.names = TRUE),
             list.files(file.path(root, "app"),         "[.]R$", full.names = TRUE),
             list.files(file.path(root, "tests", "testthat"), "[.]R$", full.names = TRUE))
  out <- list()
  for (f in files) {
    if (basename(f) %in% OI_EXEMPT) next
    L <- readLines(f, warn = FALSE)
    h <- grep(OI_RX, L)
    # A COMMENT naming the idiom is history -- both files that were already
    # converted quote it in their headers to say what they used to do.
    h <- h[grepl("CCX_PARAM_NAMES", L[h]) & !grepl("^[[:space:]]*#", L[h])]
    if (length(h)) out[[basename(f)]] <- h
  }
  out
}

# test -------------------------------------------------------------------------
found <- oi_scan()
novel <- setdiff(names(found), OI_BASELINE)
expect_equal(novel, character(0),
    info = paste0("these files copy a fitted set with a bare intersect() loop ",
                  "and are not in the 2026-09-02 baseline. Use ",
                  "ccx_overlay_par(p, pm), which migrates, copies, and asserts ",
                  "the overlay deleted nothing: ", paste(novel, collapse = ", ")))
