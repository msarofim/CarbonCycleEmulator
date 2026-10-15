# =====================================================================
# Gate: the SPO seasonal-partition constants are TIED to the registry.
#
# WHY THIS EXISTS. Until 2026-09-02 the four numbers the whole seasonal arc is
# scored against -- observed SPO total 1.168 ppm, its land limb 0.683, its ocean
# limb 0.522, and that limb's peak month 8.52 -- were file-local literals in 14
# diagnostics and in `R/constants.R` nowhere. `calibration/lib_seas_limbs.R`
# extracted the ESTIMATOR for this arc and left the constants alone on purpose,
# saying registering them was "a constants-registry decision". They are now
# registered, and this is the gate that keeps the copies honest.
#
# ⛔ THE COPIES ARE NOT CONVERTED IN BULK, AND DELIBERATELY SO. Several of these
# files are PRE-REGISTERED artifacts whose scored gates may not move under a
# refactor (`diag_admissible_2x2_land_ocean.R` is the explicit case; its stored
# arms are re-scored by `diag_2x2_repriced_at_enso25.R` sec.1). So this follows
# Marcus's Ruling B idiom for the bare-overlay lint: CONVERT ON TOUCH, and let a
# ratchet make the count go one way.
#
# THREE ASSERTIONS, and the middle one is the load-bearing one:
#   TIE      -- every listed copy still equals the registry, EXACTLY. It is an
#               identity, so the bound is exact [[gate_bound_matches_its_claim]].
#   NO-STALE -- every listed (file, variable) must still BE there. Convert a
#               file to `ccx_const()` and this fails until the entry is removed,
#               so the list can only shrink [[baseline_list_must_shrink]].
#   SUBSET   -- no UNLISTED top-level constant in calibration/ carries one of
#               these values. Catches a new copy on a new file.
#
# Mutation-tested in both directions on 2026-09-02: changing a registry value
# fails TIE across every file that copies it; deleting a listed declaration
# fails NO-STALE; adding a new file-local copy fails SUBSET.
# =====================================================================

# file -> variable -> the registry name(s) it copies, positionally.
SPO_TIE <- list(
  "diag_seas_slice_q10_pin.R" = list(
    QP_OBS_SPO_LAND   = "SPO_SEAS_AMP_LAND_INV"),
  "diag_so_entrainment_power.R" = list(
    EP_OBS_OCEAN      = c("SPO_SEAS_AMP_OCEAN_INV", "SPO_SEAS_OCEAN_PHASE_INV")),
  "diag_price_the_lag.R" = list(
    PL_OBS_TOTAL      = "SPO_SEAS_AMP_OBS",
    PL_OBS_LAND       = "SPO_SEAS_AMP_LAND_INV",
    PL_OBS_OCEAN      = "SPO_SEAS_AMP_OCEAN_INV"),
  "diag_tau_ex_seasonal_power.R" = list(
    TP_OBS_SPO_OCEAN  = c("SPO_SEAS_AMP_OCEAN_INV", "SPO_SEAS_OCEAN_PHASE_INV")),
  "diag_hml_sst_elasticity.R" = list(
    EL_OBS_OCEAN      = "SPO_SEAS_AMP_OCEAN_INV",
    EL_OBS_OCEAN_MO   = "SPO_SEAS_OCEAN_PHASE_INV"),
  "diag_admissible_2x2_land_ocean.R" = list(
    AQ_OBS_TOTAL      = "SPO_SEAS_AMP_OBS",
    AQ_OBS_LAND       = "SPO_SEAS_AMP_LAND_INV",
    AQ_OBS_OCEAN      = "SPO_SEAS_AMP_OCEAN_INV"),
  "diag_joint_land_ocean_refit.R" = list(
    JR_OBS_TOTAL      = "SPO_SEAS_AMP_OBS",
    JR_OBS_LAND       = "SPO_SEAS_AMP_LAND_INV",
    JR_OBS_OCEAN      = "SPO_SEAS_AMP_OCEAN_INV"),
  "diag_so_pco2_phase.R" = list(
    SP_INV_OCEAN_MO   = "SPO_SEAS_OCEAN_PHASE_INV",
    SP_INV_CI         = c("SPO_SEAS_OCEAN_PHASE_INV_LO", "SPO_SEAS_OCEAN_PHASE_INV_HI")),
  "diag_seas_T_amp_sh_power.R" = list(
    TA_OBS_SPO_LAND   = "SPO_SEAS_AMP_LAND_INV"),
  "diag_q10_controlled_recovery.R" = list(
    QC_OBS_TOTAL      = "SPO_SEAS_AMP_OBS",
    QC_OBS_LAND       = "SPO_SEAS_AMP_LAND_INV",
    QC_OBS_OCEAN      = "SPO_SEAS_AMP_OCEAN_INV"),
  "diag_hml_seasonal_limbs.R" = list(
    HL_OBS_TOTAL      = "SPO_SEAS_AMP_OBS",
    HL_OBS_LAND       = "SPO_SEAS_AMP_LAND_INV",
    HL_OBS_OCEAN      = "SPO_SEAS_AMP_OCEAN_INV",
    HL_OBS_OCEAN_MO   = "SPO_SEAS_OCEAN_PHASE_INV"),
  "diag_seas_npp_sh_power.R" = list(
    NP_OBS_SPO_LAND   = "SPO_SEAS_AMP_LAND_INV",
    NP_OBS_SPO_OCEAN  = "SPO_SEAS_AMP_OCEAN_INV"),
  "diag_gross_cancellation_geometry.R" = list(
    GC_G3_OBS         = "SPO_SEAS_AMP_LAND_INV"),
  "diag_2x2_repriced_at_enso25.R" = list(
    RP_OBS_TOTAL      = "SPO_SEAS_AMP_OBS",
    RP_OBS_LAND       = "SPO_SEAS_AMP_LAND_INV",
    RP_OBS_OCEAN      = "SPO_SEAS_AMP_OCEAN_INV",
    RP_OBS_OCN_MO     = "SPO_SEAS_OCEAN_PHASE_INV")
)
SPO_TIE_N <- sum(vapply(SPO_TIE, function(f) sum(lengths(f)), integer(1)))   # = 34 on 2026-09-02

spo_calib_dir <- function() {
  for (d in c("calibration", "../../calibration", "../../../calibration"))
    if (dir.exists(d)) return(d)
  NULL
}

# Top-level assignments whose right-hand side is a numeric literal or a c() of
# numeric literals. PARSED, never sourced: these diagnostics run the model.
spo_literals <- function(path) {
  ex <- tryCatch(parse(path), error = function(e) NULL)
  if (is.null(ex)) return(list())
  lit <- function(x) is.numeric(x) && length(x) == 1L && is.finite(x)
  out <- list()
  for (e in as.list(ex)) {
    if (!(is.call(e) && length(e) == 3L &&
          as.character(e[[1]])[1] %in% c("<-", "=") && is.symbol(e[[2]]))) next
    rhs <- e[[3]]
    ok <- lit(rhs) ||
      (is.call(rhs) && identical(as.character(rhs[[1]])[1], "c") &&
         length(rhs) > 1L && all(vapply(as.list(rhs)[-1], lit, logical(1))))
    if (!ok) next
    out[[as.character(e[[2]])]] <- unname(eval(rhs, envir = baseenv()))
  }
  out
}

test_that("TIE: every file-local SPO copy equals the registry, exactly", {
  cal <- spo_calib_dir(); skip_if(is.null(cal), "calibration/ not reachable")
  for (f in names(SPO_TIE)) {
    p <- file.path(cal, f)
    expect_true(file.exists(p), info = f)
    got <- spo_literals(p)
    for (v in names(SPO_TIE[[f]])) {
      want <- vapply(SPO_TIE[[f]][[v]], ccx_const, numeric(1), USE.NAMES = FALSE)
      expect_equal(got[[v]], want, tolerance = 0,
                   info = paste(f, v, "-- a COPY of", paste(SPO_TIE[[f]][[v]], collapse = "+")))
    }
  }
})

test_that("NO-STALE: a converted file must be REMOVED from the list", {
  # Without this the list decays into files that USED to copy the constant,
  # while TIE keeps passing vacuously and guards nothing.
  cal <- spo_calib_dir(); skip_if(is.null(cal), "calibration/ not reachable")
  for (f in names(SPO_TIE)) {
    got <- names(spo_literals(file.path(cal, f)))
    missing <- setdiff(names(SPO_TIE[[f]]), got)
    expect_equal(missing, character(0),
                 info = paste(f, "no longer declares", paste(missing, collapse = ", "),
                              "-- if it was converted to ccx_const(), drop it from SPO_TIE"))
  }
})

test_that("SUBSET/NO-GROWTH: no unlisted copy, and the count only falls", {
  cal <- spo_calib_dir(); skip_if(is.null(cal), "calibration/ not reachable")
  vals <- vapply(c("SPO_SEAS_AMP_OBS", "SPO_SEAS_AMP_LAND_INV", "SPO_SEAS_AMP_OCEAN_INV",
                   "SPO_SEAS_OCEAN_PHASE_INV", "SPO_SEAS_LAND_PHASE_INV",
                   "SPO_SEAS_OCEAN_PHASE_INV_LO", "SPO_SEAS_OCEAN_PHASE_INV_HI"),
                 ccx_const, numeric(1), USE.NAMES = FALSE)
  offenders <- character(0)
  for (p in list.files(cal, pattern = "[.]R$", full.names = TRUE)) {
    f <- basename(p)
    lits <- spo_literals(p)
    for (v in names(lits)) {
      hit <- lits[[v]]
      if (!any(vapply(hit, function(x) any(abs(x - vals) < 1e-12), logical(1)))) next
      if (!is.null(SPO_TIE[[f]]) && v %in% names(SPO_TIE[[f]])) next
      offenders <- c(offenders, paste0(f, ":", v))
    }
  }
  expect_equal(offenders, character(0),
               info = "new file-local SPO copy -- use ccx_const(), or add it to SPO_TIE")
  expect_lte(sum(vapply(SPO_TIE, function(f) sum(lengths(f)), integer(1))), SPO_TIE_N)
})
