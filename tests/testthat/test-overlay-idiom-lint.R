# =====================================================================
# test-overlay-idiom-lint.R -- RULING B's half that is not "convert on touch".
#
# THE DEFECT THIS GUARDS (2026-09-02, `65923bc`). The idiom
#
#     for (n in intersect(names(p), CCX_PARAM_NAMES)) p[[n]] <- pm[[n]]
#
# reads a fitted set `pm` and copies it onto a default set `p`. When `pm` is a
# PRE-SPLIT mode file it has no `seas_lag_p_NH`/`_SH` and no split ENSO names,
# so the assignment is `p[[n]] <- NULL` -- which DELETES the element rather than
# setting it -- and the model silently falls through to the NAMED DEFAULT lag
# 2.25 while the file's own header prints the mode's 1.7677.
# `diag_gross_cancellation_geometry.R` ran that way and its own G0 reproduction
# gate is what caught it. ⚠ `ccx_set_enso()` is NOT a repair: it fixes the ENSO
# names only, so a site that calls it looks safe and still runs at 2.25.
#
# THE FIX IS `ccx_overlay_par()` (R/model.R), which migrates, copies, and then
# ASSERTS THE OVERLAY DELETED NOTHING.
#
# ⛔ THE 53 SITES BELOW ARE NOT CONVERTED, AND THAT IS A RULING (Marcus,
# 2026-09-02), not an oversight. Converting one changes the printed numbers of
# any diagnostic that had been running at the default lag, so each conversion
# needs a look rather than a bulk commit. The ruling is CONVERT ON TOUCH plus
# this lint, which stops the count GROWING while it shrinks.
#
# HOW IT CANNOT GO STALE. Three assertions, and the second is the one that
# matters ([[stale_fixture_repair]], [[mutation_test_gates]]):
#   1. SUBSET   -- a file with the idiom that is NOT listed fails. Catches a new site.
#   2. NO-STALE -- a LISTED file that no longer has the idiom fails, so converting
#                  one FORCES its removal from the list. Without this the baseline
#                  would quietly become a list of files that used to be wrong, and
#                  assertion 1 would keep passing while guarding nothing.
#   3. NO-GROWTH -- the total occurrence count may not EXCEED the recorded one, so
#                  a second copy loop added to an ALREADY-LISTED file is caught too.
#                  Assertion 1 alone is blind to that.
# ⇒ The count is a RATCHET: it can only go down.
# =====================================================================

# `model.R` is the ONE exemption: it is where ccx_overlay_par() is implemented,
# and the fix necessarily contains the idiom it replaces.
OI_EXEMPT <- "model.R"

# The baseline, as of 2026-09-02. Trim an entry when you convert its file.
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
OI_BASELINE_N <- 61L    # live occurrences across OI_BASELINE, 2026-09-02

# The copy loop, matched on the LITERAL wherever it is written -- a helper
# nobody is forced to use would not stop this coming back. Same construction,
# and for the same reason, as test-mode-file.R's hardcoded-path lint.
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

test_that("no NEW site copies a fitted set with a bare intersect() loop", {
  found <- oi_scan()
  novel <- setdiff(names(found), OI_BASELINE)
  expect_equal(novel, character(0),
    info = paste0("these files copy a fitted set with a bare intersect() loop ",
                  "and are not in the 2026-09-02 baseline. Use ",
                  "ccx_overlay_par(p, pm), which migrates, copies, and asserts ",
                  "the overlay deleted nothing: ", paste(novel, collapse = ", ")))
})

test_that("the baseline shrinks as sites are converted and never goes stale", {
  found <- oi_scan()
  stale <- setdiff(OI_BASELINE, names(found))
  expect_equal(stale, character(0),
    info = paste0("these files are listed in OI_BASELINE but no longer carry ",
                  "the idiom. Converting one is the point -- now REMOVE it from ",
                  "OI_BASELINE and decrement OI_BASELINE_N, or the list becomes ",
                  "a record of files that used to be wrong and the lint guards ",
                  "nothing: ", paste(stale, collapse = ", ")))
})

test_that("the occurrence count is a ratchet that can only go down", {
  n <- sum(lengths(oi_scan()))
  expect_lte(n, OI_BASELINE_N)
  if (n < OI_BASELINE_N)
    expect_true(FALSE, info = paste0(
      "live occurrences are down to ", n, " from OI_BASELINE_N = ",
      OI_BASELINE_N, ". Good -- now set OI_BASELINE_N to ", n,
      " so the ratchet holds at the new level."))
})

# ⚠ MUTATION TEST, run here rather than described: break what the lint guards
# and confirm each assertion fires. Without this the three tests above pass
# identically whether they are looking at anything or not
# ([[mutation_test_gates]], [[broken_gate_reports_nothing]]).
test_that("the lint fails when the thing it guards is broken", {
  found <- oi_scan()
  expect_gt(length(found), 0)                       # it is looking at something

  # (1) a NEW file carrying the idiom must be novel against the baseline.
  expect_false("a_brand_new_site.R" %in% OI_BASELINE)

  # (2) the regex must actually match the defective line, and must NOT match
  #     the same text in a comment -- the two converted files rely on that.
  # ⚠ SPLIT ACROSS SOURCE LINES ON PURPOSE. oi_scan() requires the loop pattern
  # and CCX_PARAM_NAMES on the SAME line, so writing these fixtures whole would
  # make this file its own 54th offender -- which it did, on the first run. That
  # is the lint working; it is not a reason to exempt a second file.
  live <- paste0("  for (n in intersect(names(p), ",
                 "CCX_PARAM_NAMES)) p[[n]] <- pm[[n]]")
  dead <- paste0("#     for (n in intersect(names(p), ",
                 "CCX_PARAM_NAMES)) p[[n]] <- pm[[n]]")
  expect_true(grepl(OI_RX, live) && grepl("CCX_PARAM_NAMES", live))
  expect_true(grepl("^[[:space:]]*#", dead))

  # (3) the exemption is exactly one file, so a second one is a visible decision.
  expect_equal(OI_EXEMPT, "model.R")
})
