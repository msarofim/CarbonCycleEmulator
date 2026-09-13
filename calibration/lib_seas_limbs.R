# =====================================================================
# lib_seas_limbs.R -- THE SPO LIMB ESTIMATOR, EXTRACTED SO TWO FILES CANNOT
#   REPORT THE SAME LIMB AT TWO DIFFERENT MEASUREMENTS.
#
# WHAT THIS IS. The three-way SPO seasonal decomposition and its peak-to-peak /
# phase estimator, as `diag_admissible_2x2_land_ocean.R` (08-27q) and its
# ancestors ran them. Same idiom as `calibration/lib_design_gates.R`: one
# estimator, sourced by every file that quotes the number.
#
# ⛔ `diag_admissible_2x2_land_ocean.R` IS NOT EDITED TO USE THIS. That file is
# a PRE-REGISTERED artefact (prereg 27q, committed `36e4051` before it existed)
# and its gates may not move under a refactor. It keeps its inline copy; what
# binds the two is a REPRODUCTION GATE -- `diag_2x2_repriced_at_enso25.R` sec.1
# re-scores 27q's six STORED arms through this library and requires the stored
# amplitudes and phases back. If this file ever drifts from that one, the gate
# fires and names the arm. A comment claiming they agree would not.
#
# ✅ THE FOUR OBSERVED CONSTANTS ARE NOW REGISTERED (2026-09-02). SPO total
# 1.168, land 0.683, ocean 0.522, ocean phase 8.52 months -- plus the land phase
# 9.29 and the ocean phase's 95 % bounds [7.82, 9.20] -- live in
# `R/constants.R` as `SPO_SEAS_*`, with the provenance and the ⚠ that three of
# them are observations INVERTED THROUGH THE MODEL's own signatures and so sit
# on the provisional ledger. This file still does not read them: it is the
# ESTIMATOR, and its callers supply the targets.
# ⛔ THE COPIES ARE NOT CONVERTED IN BULK -- several callers are pre-registered
# artefacts whose gates may not move. What binds them is CONVERT ON TOUCH plus
# `tests/testthat/test-spo-constants-tie.R`, which ties all 34 file-local copies
# to the registry exactly and can only ratchet down.
# =====================================================================

# PEAK-TO-PEAK, always -- the estimator the whole arc is quoted in.
sl_amp    <- function(v) 2 * sqrt(sum(v^2))
sl_ang_mo <- function(v) 12 * ((atan2(v[1], v[2]) / (2 * pi)) %% 1)
# The inverse, for the arithmetic in sec.3: a limb back to its (a, b) vector.
sl_vec    <- function(amp, mo) { th <- 2 * pi * mo / 12
                                 c(amp / 2 * sin(th), amp / 2 * cos(th)) }

# ⚠ THE OCEAN CASE MUST KILL **BOTH** SH LIMBS. `sst_seas_amp_SH = 0` alone
# leaves the entrainment limb running -- the bug the channel exposed on 27g.
#
# ⭐ THE FOURTH CASE IS NEW AND IS NOT 27q's. None of the three cases above
# touches the ENSO coefficients, so ENSO sits INSIDE the residual the other
# three do not explain -- and attributing to "the mode moved" what a newly
# fitted mechanism did is exactly the confound this case removes.
# ⚠ AND THE PRE-SPLIT VECTORS ARE NOT A ZERO CONTROL, which is what I first
# wrote here. `gamma_enso` was itself a CALIBRATED parameter in the 21-name set
# and 27q's arms carry it at 0.8512, split 0.5/0.5 onto the land pair by
# CCX_ENSO_SHARE_LEGACY. So this limb is NONZERO in every column; what the old
# columns control for is the SPLIT, not the mechanism.
SL_CASES <- list(
  NH_origin = list(seas_npp_amp_NH = 0, seas_T_amp_NH = 0, sst_seas_amp_NH = 0),
  SH_land   = list(seas_npp_amp_SH = 0, seas_T_amp_SH = 0),
  # ⛔ THE THIRD LIMB (2026-09-12). With the seasonal mixed layer ON (seas_ml 1,
  # canonical since hilda31s) the SH ocean has THREE seasonal drivers: the SST
  # sine, the pCO2-side entrainment shim, and the mixed layer's own entrainment
  # of real water. A knockout of the first two alone reads the residual of a
  # partial cancellation -- at hilda31s 0.410 ppm @ 4.53 mo at SPO, OUTSIDE
  # gate S's bracket -- when the whole limb is 0.465 @ 8.96, inside it. The
  # 27g bug's exact class ("a one-limb knockout gates a limb that is not the
  # one named"), one limb later. ⚠ `seas_ml` is a WHOLE-MODEL switch: this
  # knockout also removes the NH mixed layer's leak into SPO (0.107 ppm @ 6.43,
  # measured 09-12 with a per-hemisphere override; hemisphere-clean the limb is
  # 0.451 @ 9.41). A per-hemisphere handle on the MLD cycle is OWED; until it
  # exists the NH_origin case below does NOT include the NH mixed layer, so the
  # three-limb decomposition is not complete at seas_ml = 1.
  SH_ocean  = list(sst_seas_amp_SH = 0, ent_seas_amp_SH = 0, seas_ml = 0),
  ENSO      = setNames(as.list(rep(0, length(CCX_ENSO_PARAMS))), CCX_ENSO_PARAMS))

# The three limbs 27q decomposed into, named so a caller can ask for its own
# arithmetic to close over exactly them and not silently gain a fourth.
SL_CASES_27Q <- c("NH_origin", "SH_land", "SH_ocean")

#' Overlay a stored parameter vector onto today's defaults, MIGRATING splits
#'
#' ⛔ NOT `intersect(names(p), CCX_PARAM_NAMES)`, which is what every pre-split
#' diagnostic does. On a 21-parameter ancestor that idiom assigns NULL to
#' `seas_lag_p_NH/_SH` -- which DELETES them -- and the model then falls back to
#' `CCX_SEAS_LAG_P_DEFAULT`, running an ancestor at a lag it never had and
#' reporting the number as that ancestor's. Absence must assert: anything the
#' CURRENT parameter set needs and this vector does not carry goes through
#' `ccx_migrate_par_set()`, which is the contract, or errors.
#'
#' @param pv a named list/vector of parameter values (any vintage)
#' @param pump_mode the arm the vector was fitted under -- READ from its own
#'   mode file by the caller, never assumed
sl_overlay <- function(pv, pump_mode, struct = "", seas_ml = NULL, pins = NULL) {
  # `pins` (2026-09-13): the pins the vector was fitted under (ccx_mode_pins(md));
  # a PINNED name is HELD, not absent, so it is written into `pv` here before the
  # absence test below can hand it to the migration contract (which would fill
  # the pre-09-03 meaning and call the vector migrated). A caller resolving a
  # mode file can equivalently pass ccx_mode_par_with_pins(md) as `pv`.
  for (n in names(pins)) pv[[n]] <- pins[[n]]
  # `struct` (2026-09-08f): the structure label the vector was fitted under
  # (ccx_mode_struct(md)); "" = the column, as every pre-09-08f caller meant.
  # `seas_ml` (2026-09-12, review A8): the mixed-layer switch the vector was
  # fitted under (ccx_mode_seas_ml(md)). It is a STRUCTURAL switch, not a
  # fitted name, so `pv` never carries it; NULL = ccx_apply_structure()'s own
  # default (the env's CCX_MS_SEAS_ML, "0"), which is what every earlier caller
  # got. A caller resolving a seas_ml = 1 mode file MUST pass it, or the limb
  # is measured with the mixed layer OFF and the third SH ocean limb absent.
  p <- if (is.null(seas_ml)) ccx_apply_structure(ccx_default_params(), struct)
       else ccx_apply_structure(ccx_default_params(), struct, seas_ml = seas_ml)
  for (n in intersect(names(p), names(pv))) p[[n]] <- pv[[n]]
  miss <- CCX_PARAM_NAMES[!(CCX_PARAM_NAMES %in% names(pv))]
  if (length(miss)) {
    for (n in miss) p[[n]] <- NULL                 # so migration SEES them absent
    for (n in setdiff(names(pv), names(p))) p[[n]] <- pv[[n]]   # the legacy scalars
    # ⚠ THE FALLBACK BELOW IS FOR A VECTOR THAT CARRIES NO `gamma_enso` AT ALL.
    # ⛔ It is NOT the path 27q's arms take: `gamma_enso` was one of their 21
    # CALIBRATED names, fitted at 0.8512, and it is copied across as a legacy
    # scalar by the loop above -- so the migration contract splits the FITTED
    # value, not a default. (I first wrote the opposite here, that a 21-parameter
    # ancestor ran at the pre-split default of 0; the ENSO limb in sec.3 of the
    # caller came back nonzero on those arms and said otherwise.) A vector from
    # BEFORE the coefficient was calibrated genuinely ran at that default
    # (`git show 11ff844:R/model.R`, line 870), and only that case lands here.
    if (any(CCX_ENSO_PARAMS %in% miss) && is.null(pv$gamma_enso) &&
        is.null(p$gamma_enso)) p$gamma_enso <- 0
    p <- ccx_migrate_par_set(p)
  }
  p$pump_mode <- pump_mode
  p
}

#' Run the model at one parameter vector and return the scored seasonal vectors
#' @param base_mods overrides applied to EVERY run, before the per-case ones --
#'   for holding a mechanism at a stated value across a whole comparison
#' @param seas_ml the mixed-layer switch the vector was fitted under (see
#'   sl_overlay); NULL = the pre-09-12 behaviour
#' @param spinup the spinup FUNCTION the vector was fitted under. ⛔ 2026-09-12
#'   (review A8): this used to call ccx_spinup() unconditionally, so a caller
#'   resolving a PERIODIC-fitted mode file (every mode promoted since 09-09x,
#'   the canonical hilda31s included) measured its limbs off-mode -- the 2447
#'   log-unit mechanism, a seasonal mixed layer started from an aseasonal
#'   equilibrium. Callers that resolve a mode file pass
#'   ccx_spinup_from_label(ccx_mode_spinup(md)); the default keeps every
#'   pre-existing caller (27q's arms and the other stored aseasonal vectors)
#'   exactly where it was.
sl_run <- function(pv, ent, pump_mode, obs, years, mods = list(), base_mods = list(), struct = "",
                   seas_ml = NULL, spinup = ccx_spinup) {
  p <- sl_overlay(pv, pump_mode, struct, seas_ml = seas_ml)
  p <- ccx_set_enso(p, pv)
  p$ent_seas_amp_SH <- ent
  for (n in names(base_mods)) p[[n]] <- base_mods[[n]]
  for (n in names(mods)) p[[n]] <- mods[[n]]
  sp <- spinup(p)
  # ⚠ bomb_total / luc_scale come off `pv`: seven of the calibrated names are
  # likelihood-side and absent from ccx_default_params(). Cost a run on 27h.
  # The reference bomb total is the registry's CCX_BOMB_REF (= DG_BOMB_REF in
  # lib_design_gates.R, which this file does not depend on), never a literal.
  F <- ccx_build_forcing("historical", years, prod_c14 = 0, bomb_total_kmol = CCX_BOMB_REF)
  F$c14_cosmo <- sp$prod_c14; F$c14_bomb <- F$c14_bomb * (pv$bomb_total / CCX_BOMB_REF)
  for (cc in c("e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH"))
    F[[cc]] <- F[[cc]] * pv$luc_scale
  attr(F, "luc_scale") <- pv$luc_scale
  ms <- ccx_model_stats(ccx_run_fast(sp, F)$out, obs)
  pick <- function(k) { kk <- strsplit(k, ".", fixed = TRUE)[[1]]; ms[[kk[1]]][[kk[2]]] }
  vec  <- function(h) if (is.null(h)) c(NA, NA) else c(mean(h$a), mean(h$b))
  list(co2_SPO = vec(pick("co2_seas.SPO")), d13_SPO = vec(pick("d13_seas.SPO")),
       co2_MLO = vec(pick("co2_seas.MLO")), d13_MLO = vec(pick("d13_seas.MLO")))
}

#' The observed seasonal vectors, in the same shape as `sl_run()` returns
sl_obs_vectors <- function(obs) {
  pick <- function(k) { kk <- strsplit(k, ".", fixed = TRUE)[[1]]; obs[[kk[1]]][[kk[2]]] }
  vec  <- function(h) if (is.null(h)) c(NA, NA) else c(mean(h$a), mean(h$b))
  list(co2_SPO = vec(pick("co2_seas.SPO")), d13_SPO = vec(pick("d13_seas.SPO")),
       co2_MLO = vec(pick("co2_seas.MLO")), d13_MLO = vec(pick("d13_seas.MLO")))
}

#' d13C-per-ppm, model over observed, at one station
sl_ratio_at <- function(b, obsv, st) {
  ao <- sl_amp(obsv[[paste0("co2_", st)]]); do_ <- sl_amp(obsv[[paste0("d13_", st)]])
  (sl_amp(b[[paste0("d13_", st)]]) / sl_amp(b[[paste0("co2_", st)]])) / (do_ / ao)
}

#' The full SPO scorecard at one parameter vector: total, the three limbs, ratios
#'
#' Each limb is BASE MINUS the run with that driver set zeroed -- so it is the
#' contribution that driver makes to SPO, as a VECTOR, not a local amplitude.
sl_score <- function(pv, ent, pump_mode, obs, obsv, years, base_mods = list(), struct = "",
                     seas_ml = NULL, spinup = ccx_spinup) {
  b <- sl_run(pv, ent, pump_mode, obs, years, base_mods = base_mods, struct = struct,
              seas_ml = seas_ml, spinup = spinup)
  d <- lapply(SL_CASES, function(m)
              b$co2_SPO - sl_run(pv, ent, pump_mode, obs, years, m, base_mods, struct = struct,
                                 seas_ml = seas_ml, spinup = spinup)$co2_SPO)
  list(total_v = b$co2_SPO, dec_v = d,
       total = c(amp = sl_amp(b$co2_SPO), mo = sl_ang_mo(b$co2_SPO)),
       dec = lapply(d, function(v) c(amp = sl_amp(v), mo = sl_ang_mo(v))),
       r_SPO = sl_ratio_at(b, obsv, "SPO"), r_MLO = sl_ratio_at(b, obsv, "MLO"))
}
