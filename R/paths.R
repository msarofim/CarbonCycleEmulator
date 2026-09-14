# =====================================================================
# paths.R — resolve repo-relative paths regardless of working directory.
#
# Needed because scripts, testthat (which runs from tests/testthat/), and
# the Shiny app (which runs from app/) all have different working
# directories but must reach the same data/ files.
# =====================================================================

# ⛔ THE ROOT RESOLVER MOVED TO R/aaa_root.R (2026-09-09w). `REPO_MARKER`,
# `ccx_root()` and `ccx_path()` used to live here, but the alphabetical
# `list.files("R", ...)` bootstrap sources `calibrate.R` and `constants.R`
# BEFORE `paths.R`, so a constant that reads a data/ product at source time
# could not resolve a path. They are hoisted to a file that sorts first; see its
# header. Everything else about paths -- the canonical mode, the retired arms,
# mode decoding and the band contract -- stays here.

# =====================================================================
# THE CANONICAL MODE — ONE NAME, RESOLVED HERE (2026-08-27)
#
# WHY THIS EXISTS. Until today the adopted mode's path was a literal,
# `calibration/output/pump_arms/mode_fit_pump<arm>.rds`, written out in
# ccx_load_mode(), in app/global.R, and INDEPENDENTLY in ~35 diagnostics that
# never went through ccx_load_mode() at all. The 2026-08-25f seasonal-NEP
# isotope fix (`6bda464`) changed the OBJECTIVE, so every vector fitted before
# it — arm N included — is in
# `calibration/output/quarantine/20260825_seas_isotope_rectification/`, and the
# post-fix refit landed in a DIFFERENT directory. Repointing 35 literals is 35
# chances to point one of them at the quarantine; repointing one constant is
# one decision.
#
# THE FAILURE MODE THIS IS DEFENDING AGAINST is not a missing file — that is
# loud. It is a diagnostic that still resolves, silently, to a vector fitted on
# a different objective, and reports its numbers as current.
#
# `ref` IS DELIBERATELY NOT RESOLVABLE. `refit_20260825f_ref/mode_fit_pumpN.rds`
# is the PRE-FIX SEED the driver warm-started from, not a result (logpost -1909
# under the current objective); cycle 1's real result is in the `_progress.rds`
# beside it. That arm was abandoned as a worse local optimum. Naming it here
# would hand out the seed as if it were a mode.
# 2026-09-08f: `hilda31` -- the round-5 winner of the HILDA refit (31 parameters,
# structure "hilda": HS/HD boxes, K(z), the HS pump, u_hs and hs_asx_frac under
# their observations). ⚠ THE FIRST CANONICAL FITTED UNDER A STRUCTURE: the file
# carries `struct`, and every consumer builds its base list through
# ccx_mode_base(md) below, never ccx_default_params() (where hs_frac = 0 and the
# vector would run as a column with nothing said).
# 2026-09-10: `hilda31p` -- the SAME 31-parameter HILDA space, REFITTED under the
# PERIODIC spinup adopted 09-09x (`50f0105`) and the 09-09w priors. Torch arrays
# 17318015 + 17325832: 14/14 round-2 starts converged, 8 onto this point to four
# decimals, logpost -1480.540424, +9.0880 over `hilda31` RE-SCORED on the same
# objective (never over its stored -1478.66, which is in another objective's
# units ⇒ [[compare_gaps_not_absolute_logposts]]). ⚠ Fitted at `seas_ml = 0`,
# exactly as `hilda31` was: this is the SHIPPED model's mode under the adopted
# spinup, NOT a round-6 result ⇒ [[ccx_refit_ran_at_seas_ml_0]]. The file records
# `struct`, and ccx_mode_seas_ml() reads its absent `seas_ml` as the 0 it was.
# 2026-09-11 (8): `hilda31s` -- the SAME 31-parameter HILDA space with the SEASONAL
# MIXED LAYER ON (`seas_ml` 1), refitted under the corrected concentration
# observables (annual mean over the box's mass at the time, 09-11 (5)). Torch
# arrays 17367892 + 17379055: 8/24 converged, 18 dispersed reproduced the basin,
# logpost -1475.457904; on LIKELIHOOD equal to `hilda31p` (-0.61 / +0.23 across
# the two h_ml basins, inside the 0.5 convergence bound), priors +5.8, GATE P7
# PASS, P2 inside 2 sigma, P12 1.25x. Hessian PD, cond 3.4e5, NOTHING
# step-unstable (h_ml 64.8 +/- 2.3 m, the P8 wall 4 sigma out). Promoted on
# Marcus's ruling ("Promote 1"). `hilda31p` STAYS REGISTERED as the free
# `seas_ml` = 0 control: every seasonal-ML diagnostic scores against it, and the
# 09-10 rule that the canonical must WIN on today's objective is what keeps the
# pair honest (test-mode-file.R option 2).
# 2026-09-13: `hilda31s2` -- the SAME 31-parameter HILDA / seas_ml 1 space REFITTED
# under the 09-12 objective (annual-mean isotope pins, row-read concentrations,
# IntCal to 1941, no pre-run ice rows, observed-month D14C edge years). Round 7:
# 24 dispersed starts + a checkpoint resume, 12 CONVERGED, ids 1/3/14/20 at
# -1423.5675 to 4 dp (+8.68 over the restamped hilda31s: exactly the two d13C
# level rows the objective change had cost), h_ml UNCHANGED at 64.82 m; a
# second basin at h_ml 49.7 sits 0.35 behind. Hessian PD, cond 3.36e5,
# h_ml 64.82 +/- 2.43. Promoted on Marcus's ruling ("Promote id 1, run the
# Hessian, and repoint"). `hilda31p` STAYS the registered seas_ml = 0 control.
# 2026-09-13 (d): `hilda30c` -- THE FIRST PINNED CANONICAL. The SAME HILDA /
# seas_ml 1 space and the SAME 09-12 objective as `hilda31s2`, with the pCO2-side
# entrainment SHIM `ent_seas_amp_SH` PINNED to 0 (ccx_apply_pins; 30 free names):
# assessment 09-12 option C', asking whether the real seasonal mixed layer carries
# the SH ocean limb's DIC side on its own. It does: Torch job 17681685, 24 starts,
# 4 CONVERGED; promoted start id 3 (= id 1 to 4 dp; ids 0/6 TIME at the same
# point), pinned logpost -1426.242817, streams -1392.0158. ⚠ THAT LOGPOST IS NOT
# COMPARABLE TO A FREE ARM'S (no prior term, no Jacobian for the held name); on
# LIKELIHOOD over the 25 common rows it is -1392.02 vs `hilda31s2` -1389.48
# (-2.53, of which d13c_seasonal_SPO -1.88) and vs `hilda31p` -1396.26 (+4.24).
# The price against the parent is ACCEPTED by the ruling and RECORDED, not gated
# (test-mode-file). h_ml 65.23 +/- 2.40 m (Hessian PD, cond 3.31e5; h_ml's step
# drift 3.81 % over eps/3-3eps -- the plateau 1e-3..1e-2 is flat to 0.5 %, the
# 3 eps leg touches the same roll-off hilda31s2 has); sst_seas_amp_SH 1.288 +/-
# 0.188 -- CONFIDENTLY off its observation 1.746 (2.4 posterior sd), the thing the
# shim was standing in for. Promoted on Marcus's rulings ("Promote C' id 1";
# "Repoint"). `hilda31s2` STAYS REGISTERED as the FREE PARENT (the pinned arm's
# meaning is its likelihood price against that file); `hilda31p` stays the seas_ml
# = 0 control. Nothing is quarantined: the parent is not superseded. The shim is
# PINNED, not RETIRED from the table -- retirement would make `hilda31p` (shim
# 18.7 at seas_ml 0) unscorable; a later ruling.
CCX_MODE_CANONICAL <- "hilda30c"

CCX_MODE_FILES <- c(
  hilda30c = file.path("calibration", "output", "refit_20260913_hilda30_cprime_pin_ent0",
                       "mode_fit_pumpN.rds"),
  hilda31s2 = file.path("calibration", "output", "refit_20260912_hilda31_seasml1_round7",
                        "mode_fit_pumpN.rds"),
  hilda31p = file.path("calibration", "output", "refit_20260910_hilda31_periodic",
                       "mode_fit_pumpN.rds")
)
# THE seas_ml = 0 CONTROL, by name: the diagnostics that compare the seasonal
# mixed layer ON vs OFF read the OFF arm here rather than through the default
# ccx_mode_file(), which from 09-11 (8) is the ON arm.
CCX_MODE_SEASML0_CONTROL <- "hilda31p"

# THE COLUMN CONTROL. `ent26` (26 parameters, no structure) is retired from the
# registry -- it is not a mode of this space -- but it stays the like-for-like
# COLUMN comparison every HILDA-arc diagnostic scores against. It is resolved
# by PATH (ccx_mode_file() accepts one), migrated on load, and its absent
# `struct` means "" = the column, which is exactly what it was.
CCX_MODE_COLUMN_CONTROL <- file.path("calibration", "output", "quarantine",
                                     "20260908_hilda31_adopted", "refit_20260903_ent26",
                                     "mode_fit_pumpN.rds")

# THE PRE-ADOPTION HILDA CONTROL (2026-09-10). `hilda31` is retired from the
# registry -- its stored logpost is in the ASEASONAL objective's units and may
# not sit beside `hilda31p`'s -- but it is the point Ruling A's demean flag was
# RATIFIED at (43.8367, aseasonal) and where the adoption's apparent re-pricing
# (63.7282) was measured; both stay asserted from this path by
# test-enso-demean.R, as facts about THIS file and not about the canonical.
CCX_MODE_HILDA31_QUARANTINED <- file.path("calibration", "output", "quarantine",
                                          "20260910_periodic_spinup_adopted",
                                          "refit_20260908_hilda31", "mode_fit_pumpN.rds")

# THE 09-11 SEASONAL-ML CANONICAL (2026-09-13). `hilda31s` is retired from the
# registry -- its stored streams are the 09-11 objective's, restamped twice --
# but it is the file the round-6b P7 record and the 09-12 evaluation were read
# at, and stays resolvable by path for any like-for-like read against them.
CCX_MODE_HILDA31S_QUARANTINED <- file.path("calibration", "output", "quarantine",
                                           "20260913_round7_adopted",
                                           "refit_20260911_hilda31_seasml1", "mode_fit_pumpN.rds")

# WHICH ARMS ARE PINNED -- AND WHY THE STORED logpost IS A TRAP ACROSS THEM.
# A stored logpost is a number in the units of the objective that produced it,
# and a PINNED arm's objective is not a free arm's: compare PINNED vs FREE on
# LIKELIHOOD (the stream rows), never on the stored value.
#
# WHAT A PIN IS (2026-09-13, ccx_apply_pins in R/calibrate.R): a fitted name
# REMOVED from the fitted set and HELD at a stated value in the base list. It has
# NO prior term and NO Jacobian for the held name, so the pinned objective is
# the full objective's conditional slice at the pinned value minus the held
# name's own prior -- a constant, which is exactly why the stored logposts of a
# pinned and a free arm are in different units. The file records `pins`;
# ccx_mode_base() carries the value; ccx_mode_pins() reads it.
#
# WHAT A PIN IS NOT: `pin90` (2026-08, retired). That was a near-delta PRIOR on
# `fert_k`, worth +11.6698 at fert_k = 90; its stored logpost -1544.50 read
# HIGHER than the then-canonical -1544.615 and was 11.56 BELOW on the comparable
# scale. The trap is the same in both cases -- a stored number never decides an
# arm -- but a real pin has no prior credit to subtract; it has a likelihood
# price to measure (test-mode-file measures it and prints it).
#
# 2026-09-04 -> 2026-09-11 (8) this registry held one arm, then two free arms;
# the free-vs-pinned comparison it exists to express had no power
# ([[no_power_null]]). It has power from 09-13 (d): the canonical is PINNED.
CCX_MODE_PINNED <- c(hilda30c = TRUE, hilda31s2 = FALSE, hilda31p = FALSE)
# A PINNED CANONICAL (2026-09-13). When the canonical is a pinned arm, the
# registry names WHAT it pins (the file's own `pins` must agree -- test-mode-file)
# and its free PARENT: the same space with the pinned names free, kept
# registered because the pinned arm's meaning is its LIKELIHOOD price against
# that file. Both NULL while the canonical is free. The pin is a
# RETIREMENT-IN-WAITING: `ent_seas_amp_SH` leaves the table only once the
# seas_ml 0 control can be scored without it.
CCX_MODE_CANONICAL_PINS  <- c(ent_seas_amp_SH = 0)
CCX_MODE_PINNED_PARENT   <- "hilda31s2"
#' The registered FREE mode nearest the canonical: the canonical itself when it
#' is free, its parent when it is pinned. For a consumer that needs a vector
#' ENCODABLE on the full table (an ancestor constructed by dropping names, a
#' template for a 31-name start) -- a pinned canonical's held name is 0 under
#' `tr = "log"` and cannot be encoded without its pins.
ccx_mode_free_name <- function() {
  if (isTRUE(CCX_MODE_PINNED[[CCX_MODE_CANONICAL]])) CCX_MODE_PINNED_PARENT else CCX_MODE_CANONICAL
}

# The retired names, kept ONLY so that asking for one gets the reason rather
# than a file-not-found. Everything here is quarantined and not comparable.
#
# EACH ENTRY CARRIES ITS OWN CAUSE AND ITS OWN QUARANTINE PATH, and that is not
# decoration. Until 2026-08-28 the reason lived in ccx_mode_file()'s error
# string as ONE hardcoded sentence -- the 2026-08-25f isotope fix (`6bda464`),
# quarantined under 20260825_seas_isotope_rectification/ -- which was correct
# while every retired arm had been retired by that one change. The project has
# since had a SECOND objective change (option 5, sigma-inflation, 2026-08-28),
# so the shared sentence would have told a reader the wrong cause and pointed
# at the wrong directory for anything retired by it. A registry whose entries
# cannot express why they are here has to be edited under pressure the first
# time a second reason exists; this one is a one-line addition instead.
CCX_MODE_RETIRED <- c(
  N   = paste("arm N of the 2026-08-18/20 pump refit, retired by the 2026-08-25f",
              "seasonal-NEP isotope fix (`6bda464`), which changed the objective.",
              "Quarantined under",
              "calibration/output/quarantine/20260825_seas_isotope_rectification/"),
  D   = paste("arm D of the 2026-08-18 pump refit, retired by the 2026-08-25f",
              "seasonal-NEP isotope fix (`6bda464`), which changed the objective.",
              "Quarantined under",
              "calibration/output/quarantine/20260825_seas_isotope_rectification/"),
  ref = paste("the ABANDONED reference arm of refit_20260825f (its mode file is the",
              "PRE-FIX SEED, not a result), retired by the 2026-08-25f seasonal-NEP",
              "isotope fix (`6bda464`), which changed the objective. Quarantined under",
              "calibration/output/quarantine/20260825_seas_isotope_rectification/"),
  from90 = paste("the FREE arm of refit_20260825f and the canonical mode from 2026-08-26",
              "to 2026-09-04, a TWENTY-ONE-parameter vector. Retired by the",
              "2026-09-03 freeing of `ent_seas_amp_SH` (`88ee23c`), the last of",
              "three splits that took the fitted set 21 -> 22 -> 25 -> 26. It is",
              "not a mode of this space: `ccx_migrate_par_set()` can say what it",
              "RAN, but under `tr = \"log\"` its own state has prior probability",
              "ZERO and cannot be encoded at all. Quarantined under",
              "calibration/output/quarantine/20260903_ent26_adopted/"),
  pin90  = paste("the fert_k-PINNED comparison arm of refit_20260825f, retired by the",
              "same 2026-09-03 freeing of `ent_seas_amp_SH` (`88ee23c`) and equally",
              "not a mode of this space. Its +11.6698 near-delta prior credit was",
              "never an observational or physical quantity -- it is the value of a",
              "prior this project chose, at a fert_k this project chose -- so it is",
              "NOT preserved here; a pinned comparison needs a new 26-parameter",
              "pinned refit. Quarantined under",
              "calibration/output/quarantine/20260903_ent26_adopted/"),
  ent26  = paste("the 26-parameter COLUMN canonical from 2026-09-04 to 2026-09-08,",
              "retired by the HILDA refit's parameter set (kz_deep_frac, hs_asx_frac,",
              "h_hs, pump_hs_gcm2, u_hs: 26 -> 31; `81d164c`, `d65b299`) and the",
              "adoption of the round-5 winner as `hilda31`. Not a mode of this space",
              "and fitted under NO structure. It remains the like-for-like COLUMN",
              "CONTROL, resolvable by path as CCX_MODE_COLUMN_CONTROL. Quarantined under",
              "calibration/output/quarantine/20260908_hilda31_adopted/"),
  hilda31 = paste("the 31-parameter HILDA canonical from 2026-09-08f to 2026-09-10, fitted",
              "under the ASEASONAL spinup and the pre-09-09w priors. Retired by the",
              "adoption of the PERIODIC spinup as the objective's (`50f0105`, 09-09x,",
              "Marcus's ruling) and the refit under it, promoted as `hilda31p`. SUPERSEDED,",
              "not defective: its stored logpost -1478.66 is in another objective's units",
              "and beats -1480.54 only on paper; re-scored like-for-like it is -1489.63,",
              "9.088 behind. Still the pre-adoption control, resolvable by path as",
              "CCX_MODE_HILDA31_QUARANTINED. Quarantined under",
              "calibration/output/quarantine/20260910_periodic_spinup_adopted/"),
  hilda31s = paste("the 31-parameter HILDA / seas_ml 1 canonical from 2026-09-11 (8) to",
              "2026-09-13, fitted under the 09-11 objective and RESTAMPED twice on 09-12",
              "(-1475.46 -> -1453.36 -> -1432.25; annual-mean isotope pins, row-read",
              "concentrations, IntCal to 1941, no pre-run ice rows, observed-month D14C",
              "edge years). Retired by the ROUND-7 refit under that objective, promoted as",
              "`hilda31s2` (`9bc7031`; -1423.5675, +8.68, same h_ml). SUPERSEDED, not defective. Still",
              "resolvable by path as CCX_MODE_HILDA31S_QUARANTINED. Quarantined under",
              "calibration/output/quarantine/20260913_round7_adopted/")
)

#' Absolute path to a fitted mode file, by name
#'
#' @param mode one of `names(CCX_MODE_FILES)`, or an existing path (returned
#'   unchanged, so callers can point a diagnostic at any arm on the command
#'   line without going around this function).
ccx_mode_file <- function(mode = CCX_MODE_CANONICAL) {
  if (length(mode) != 1L || !is.character(mode))
    stop("ccx_mode_file() takes ONE mode name or path; got ",
         class(mode)[1], " of length ", length(mode), ".")
  if (file.exists(mode)) return(mode)
  if (mode %in% names(CCX_MODE_FILES)) return(ccx_path(CCX_MODE_FILES[[mode]]))
  if (mode %in% names(CCX_MODE_RETIRED))
    stop("mode '", mode, "' is RETIRED: ", CCX_MODE_RETIRED[[mode]],
         ". It is NOT comparable with anything fitted since. The canonical mode ",
         "is '", CCX_MODE_CANONICAL, "'; see ccx_mode_file().")
  stop("unknown mode '", mode, "': expected a path, or one of ",
       paste(sprintf("'%s'", names(CCX_MODE_FILES)), collapse = ", "), ".")
}

# =====================================================================
# DECODING A MODE FILE — `u_mode` IS MEANINGLESS WITHOUT ITS BAND (2026-08-28)
#
# THE DEFECT THIS EXISTS TO KILL. `h_ml` is transformed with a LOGIT onto
# [lo, hi], and the pump refits override that band IN PROCESS
# (`run_modefind_pump_arms.R`, `recompute_hessian.R:112-113` both set
# `CCX_PARAM_TABLE$h_ml$lo/hi <- md$hml_bound`). The band is a property of the
# REFIT, not of the model, so `R/calibrate.R` is deliberately left alone — but
# that means the SAME `u_mode` decodes to a DIFFERENT `h_ml` depending on which
# band is in force, and `ccx_unc_to_par()` is a pure function of the SHIPPED
# table and cannot know. At the canonical mode:
#
#     ccx_unc_to_par(md$u_mode)$h_ml   85.7292 m   <- shipped [30, 200]
#     md$par_mode[["h_ml"]]            96.4737 m   <- what the refit FOUND
#
# an 11.1 % error. `h_ml` was the ONLY one of the 21 that moved -- ⚠ NO LONGER
# TRUE since 2026-08-31c: `CCX_WIDEN_PARAMS` lets the refit override `kz`'s
# bracket too, and the driver records it as `kz_bracket`. The recorded-band
# fields are listed ONCE in CCX_MODE_BAND_FIELDS below so a third one cannot
# be recorded-but-never-restored the way `kz_bracket` was for a day. Every
# diagnostic using the standard `pv <- ccx_unc_to_par(md$u_mode)` idiom has
# been running an 11 % shallower mixed layer than the mode it names. It also
# accounts for most of the long-standing "the mode's logpost is not
# reproducible" offset: decoding under the recorded band takes it from
# -3.3223 to -1.5805, and -1.5805 is exactly the narrowed-prior constant the
# bounded refit adds. [[ccx_hml_band_provenance]] [[ccx_mode_logpost_offset]]
#
# ⚠ A MATCHED CONTRAST BETWEEN ARMS OF ONE DRIVER SURVIVES THIS — every arm
# shares the same wrong `h_ml`, so differences are unaffected. What does NOT
# survive is any ABSOLUTE quantity, and any cross-session "reproduces the
# earlier control values" check: those agree because the sessions share the
# defect, not because the value is right. [[mutation_test_gates]]

# WHICH FIELDS OF A MODE FILE RECORD AN OVERRIDDEN BRACKET, in one place.
# ⚠ ADD A PARAMETER HERE THE SAME DAY THE DRIVER LEARNS TO OVERRIDE IT. The
# `kz_bracket` field was WRITTEN by run_modefind_pump_arms.R from 2026-08-16 and
# CONSUMED by nothing until 2026-08-31c -- invisible for the whole of that time
# because every file's `kz_bracket` happened to equal the shipped table, so the
# missing restore could not produce a wrong number until a run finally widened
# it ([[default_off_hides_the_bug]]: a mechanism that is off by default is
# untested exactly where it matters).
CCX_MODE_BAND_FIELDS <- c(h_ml = "hml_bound", kz = "kz_bracket")

#' The parameter brackets a mode file records having been fitted under
#'
#' @param md a loaded mode file
#' @return named list of `c(lo, hi)`, one per recorded-and-present field
#' @keywords internal
ccx_mode_bands <- function(md) {
  out <- list()
  for (nm in names(CCX_MODE_BAND_FIELDS)) {
    v <- md[[CCX_MODE_BAND_FIELDS[[nm]]]]
    if (is.null(v)) next
    if (!is.numeric(v) || length(v) != 2L || any(!is.finite(v)) || v[1] >= v[2])
      stop("mode file's ", CCX_MODE_BAND_FIELDS[[nm]], " is not a finite [lo, hi] pair")
    out[[nm]] <- v
  }
  out
}

#' Parameters at a fitted mode, decoded under the band that FOUND it
#'
#' Use this instead of `ccx_unc_to_par(md$u_mode)` whenever the parameters are
#' meant to BE the mode. Returns the refit's own `par_mode` when present, which
#' is already correct by construction, and otherwise falls back to decoding
#' `u_mode` under `md$hml_bound` if that is recorded.
#'
#' @param md a loaded mode file, or a mode name/path for `ccx_mode_file()`
#' The STRUCTURE a mode file was fitted under, and the base list it needs
#'
#' `struct` is recorded by run_dispersed_multistart.R (from 2026-09-08f) and
#' carried by promote_multistart_mode.R; a file without it was fitted under no
#' structure ("" = the 32-box column), which is what every pre-09-08f file was.
#' `ccx_mode_base()` is the ONE place a consumer turns a mode file into the
#' base parameter list -- the precedent is `pump_mode`, which every consumer
#' already carries out of the file by hand; `struct` is the same kind of thing.
ccx_mode_struct <- function(md) {
  if (is.character(md)) md <- readRDS(ccx_mode_file(md))
  if (is.null(md$struct)) "" else md$struct
}
#' `seas_ml` is recorded by run_dispersed_multistart.R from 2026-09-10 on and
#' carried by promote_multistart_mode.R. A file without it was fitted with the
#' seasonal mixed layer OFF -- which is a FACT about every earlier file (the
#' driver had no way to switch it on until 09-10, [[ccx_refit_ran_at_seas_ml_0]]),
#' not a default being trusted. `hilda31` and the 09-10 `hilda31p` are both 0.
ccx_mode_seas_ml <- function(md) {
  if (is.character(md)) md <- readRDS(ccx_mode_file(md))
  if (is.null(md$seas_ml)) 0L else ccx_parse_seas_ml(md$seas_ml)
}
#' The SPINUP a mode file's `streams` and `logpost` were computed under. Recorded
#' by promote_multistart_mode.R from 2026-09-10 on; an absent field means the
#' aseasonal `ccx_spinup` -- a FACT about every file promoted before 09-09x's
#' adoption, not a default (the one post-adoption file promoted without the
#' field, `hilda31p`, had it stamped in by calibration/stamp_mode_spinup.R after
#' GATE 5 had already proved its streams periodic).
ccx_mode_spinup <- function(md) {
  if (is.character(md)) md <- readRDS(ccx_mode_file(md))
  if (is.null(md$spinup)) "aseasonal" else md$spinup
}
#' The pump field's construction a mode file was fitted under (option D + E,
#' 2026-09-14 h). A file without the field was fitted with the SOLVED field --
#' a FACT about every file promoted before 09-14 h (no other field existed),
#' not a default being trusted.
ccx_mode_pump_field <- function(md) {
  if (is.character(md)) md <- readRDS(ccx_mode_file(md))
  if (is.null(md$pump_field)) "solved" else ccx_parse_pump_field(md$pump_field)
}
ccx_mode_base <- function(md) {
  if (is.character(md)) md <- readRDS(ccx_mode_file(md))
  p <- ccx_apply_structure(ccx_default_params(), ccx_mode_struct(md),
                           seas_ml = ccx_mode_seas_ml(md),
                           pump_field = ccx_mode_pump_field(md))
  # PINNED arms (2026-09-13): the held values live in the BASE, by the file's own
  # record; a consumer that wants to SCORE such a file must also ccx_apply_pins()
  # first, or ccx_par_to_unc() will look for a name the fit never carried.
  for (n in names(md$pins)) p[[n]] <- md$pins[[n]]
  # ... and the base CARRIES the pins as an attribute, so the canonical idiom
  # `ccx_overlay_par(ccx_mode_base(md), md$par_mode)` (lint-enforced) can tell a
  # HELD name from an ABSENT one without every caller repeating it.
  if (length(md$pins)) attr(p, "pins") <- md$pins
  p
}
#' The pins a mode file was fitted under (NULL = a free arm). Read, never inferred.
ccx_mode_pins <- function(md) {
  if (is.character(md)) md <- readRDS(ccx_mode_file(md))
  md$pins
}
#' The file's `par_mode` with its PINNED names filled in from `pins` (2026-09-13).
#'
#' A pinned name is HELD, not ABSENT. `ccx_migrate_par_set()` tests absence
#' against the build's full table, so a 30-name pinned `par_mode` handed to it
#' under the 31-name table would be MIGRATED: the absence contract for
#' `ent_seas_amp_SH` fills 0 (the pre-09-03 meaning) and flags the file
#' "MIGRATED 30->31" -- which for C' happens to be the pinned value, and for any
#' other pin would be WRONG. Every consumer that overlays a mode file's vector on
#' a model list (dg_vector, sl_overlay, the scorecard's extra arm) goes through
#' this, so the held value comes from the file's own record and the migration
#' sees nothing absent. ⚠ The result is NOT encodable on the reduced space (it
#' carries the held name); to ENCODE, ccx_apply_pins(ccx_mode_pins(md)) first and
#' hand ccx_par_to_unc() the bare `md$par_mode`.
ccx_mode_par_with_pins <- function(md) {
  if (is.character(md)) md <- readRDS(ccx_mode_file(md))
  pm <- md$par_mode
  for (n in names(md$pins)) {
    if (!is.null(pm[[n]]) && !isTRUE(all.equal(pm[[n]], md$pins[[n]])))
      stop("ccx_mode_par_with_pins(): `par_mode` carries ", n, " = ", pm[[n]],
           " but the file pins it at ", md$pins[[n]], " -- the file is internally inconsistent.")
    pm[[n]] <- md$pins[[n]]
  }
  pm
}

ccx_mode_params <- function(md = CCX_MODE_CANONICAL) {
  if (is.character(md)) md <- readRDS(ccx_mode_file(md))
  # WITH the file's pins (2026-09-13): the vector the mode RAN at, held names
  # included, so a consumer that overlays or migrates it sees nothing absent. To
  # ENCODE a pinned file, ccx_apply_pins(ccx_mode_pins(md)) first -- under the
  # reduced table ccx_par_to_unc() ignores the held name it carries.
  if (!is.null(md$par_mode)) return(ccx_mode_par_with_pins(md))
  # same rule as ccx_adopt_mode_band(): the file's own names, not the build's
  u <- md$u_mode
  .nm <- if (!is.null(md$param_names)) md$param_names else CCX_PARAM_NAMES
  if (length(u) != length(.nm))
    stop("mode file's u_mode has ", length(u), " values but its param_names has ",
         length(.nm), " -- the file is internally inconsistent.")
  names(u) <- .nm
  bands <- ccx_mode_bands(md)
  bands <- bands[names(bands) %in% .nm]   # a band for a parameter this file lacks
  if (!length(bands)) return(ccx_unc_to_par(u))
  # ⚠ SNAPSHOT BEFORE THE LOOP, RESTORE IN ONE on.exit. An on.exit() registered
  # INSIDE the loop would capture the loop variable, which R evaluates at EXIT --
  # so it would restore the last band twice and leak every other one.
  .orig <- CCX_PARAM_TABLE[names(bands)]
  on.exit(for (.b in names(.orig)) CCX_PARAM_TABLE[[.b]] <<- .orig[[.b]], add = TRUE)
  for (bn in names(bands)) {
    CCX_PARAM_TABLE[[bn]]$lo <<- bands[[bn]][1]
    CCX_PARAM_TABLE[[bn]]$hi <<- bands[[bn]][2]
  }
  ccx_unc_to_par(u)
}

#' Gate a mode file's `u_mode` decoding against its own stored `par_mode`
#'
#' Call this in any diagnostic that decodes `u_mode` itself. It ERRORS rather
#' than warns: a silently-wrong `h_ml` is exactly the failure this file
#' documents, and it survived weeks because nothing checked.
#'
#' @param md a loaded mode file, or a mode name/path
#' @param tol relative tolerance per parameter
ccx_check_mode_decode <- function(md = CCX_MODE_CANONICAL, tol = 1e-8) {
  if (is.character(md)) md <- readRDS(ccx_mode_file(md))
  if (is.null(md$par_mode)) return(invisible(TRUE))   # nothing to check against
  # THIRD SITE of the same defect (2026-08-31): a STORED u_mode named with the
  # LIVE CCX_PARAM_NAMES. ccx_adopt_mode_band() and ccx_unc_to_par() were fixed
  # the same day; this one was found by its own test, which caught the raw
  # "'names' attribute [22] must be the same length as the vector [21]" instead
  # of the decode message it asserts. A file from ANOTHER parameter set is a
  # different question from a file that mis-decodes, and this function answers
  # only the second -- so say the first plainly and decline.
  u <- md$u_mode
  .nm <- if (!is.null(md$param_names)) md$param_names else CCX_PARAM_NAMES
  # a PINNED file (2026-09-13) carries the build's set MINUS its pins, and every
  # name it does carry is in the table, so it decodes on its own names
  # ... and a file lacking only CCX_PARAM_ABSENT_OK names (2026-09-13i) decodes
  # on the names it carries; ccx_unc_to_par() honours a partial named u.
  if (!ccx_mode_carries_build(md))
    stop("this mode file was fitted on a DIFFERENT parameter set (",
         length(.nm), " names vs this build's ", length(CCX_PARAM_NAMES),
         "), so 'does it decode to its own par_mode' is not a question this ",
         "build can answer. Refit, or read it with ccx_mode_params().")
  names(u) <- .nm
  pv <- ccx_unc_to_par(u)
  bad <- character(0)
  for (n in intersect(names(pv), names(md$par_mode))) {
    a <- pv[[n]]; b <- md$par_mode[[n]]
    if (!is.numeric(a) || !is.numeric(b) || length(a) != 1L || length(b) != 1L) next
    if (abs(a - b) > tol * max(abs(b), 1e-12)) bad <- c(bad, sprintf(
      "%s: ccx_unc_to_par gives %.6g but par_mode stores %.6g (%.2f %%)",
      n, a, b, 100 * abs(a - b) / max(abs(b), 1e-12)))
  }
  if (length(bad))
    stop("this mode file does NOT decode to its own stored par_mode under the ",
         "SHIPPED CCX_PARAM_TABLE:\n  ", paste(bad, collapse = "\n  "),
         "\nUse ccx_mode_params() -- see the note above it in R/paths.R. ",
         "For h_ml this is the in-process refit band (md$hml_bound = ",
         paste(md$hml_bound, collapse = ", "), ").")
  invisible(TRUE)
}

#' Adopt a mode file's own `h_ml` band for the rest of this session
#'
#' The uniform fix for the defect documented above. `ccx_mode_params()` repairs
#' ONE decode; this repairs ALL of them, including the ones inside
#' `ccx_make_logpost()`, by putting the shipped `CCX_PARAM_TABLE` into the state
#' the refit was run in. Call it ONCE, immediately after reading the mode, in
#' any driver that decodes `u_mode` or perturbations of it.
#'
#' This is what `run_modefind_pump_arms.R`, `recompute_hessian.R`,
#' `diag_hess_eps_21par.R` and `diag_seas_T_amp_q10_ridge.R` already do by hand;
#' those files are correct and need no change.
#'
#' ⚠ IT ALSO NARROWS THE PRIOR, by construction — that is the same +1.5805
#' additive constant the bounded refit carries. It cancels from every DIFFERENCE
#' and must never be read as a change in fit. ⚠ It confines `h_ml` to the band,
#' so do not call it in a driver that profiles `h_ml` across the edge.
#'
#' @param md a loaded mode file, or a mode name/path
#' @return invisibly, the previous `h_ml` table entry, for restoring
ccx_adopt_mode_band <- function(md = CCX_MODE_CANONICAL) {
  if (is.character(md)) md <- readRDS(ccx_mode_file(md))
  # EVERY recorded band, not just h_ml. `kz_bracket` was written from
  # 2026-08-16 and adopted by nothing until 2026-08-31c; see
  # CCX_MODE_BAND_FIELDS for why that stayed invisible.
  bands <- ccx_mode_bands(md)
  old <- CCX_PARAM_TABLE[names(bands)]
  if (!length(bands)) return(invisible(CCX_PARAM_TABLE[character(0)]))
  for (bn in names(bands)) {
    CCX_PARAM_TABLE[[bn]]$lo <<- bands[[bn]][1]
    CCX_PARAM_TABLE[[bn]]$hi <<- bands[[bn]][2]
  }
  if (!is.null(md$par_mode)) {
    # ⚠ NAME A STORED VECTOR WITH THE NAMES IT WAS STORED WITH, not the live
    # ones. This read `names(u) <- CCX_PARAM_NAMES`, which is the live build's
    # list -- correct only while the parameter SET never changes, and it broke
    # the moment `seas_lag_p` was split on 2026-08-31 (22 names onto a 21-vector,
    # a bare 'names attribute must be the same length' from inside a band
    # adopter, which says nothing about the real cause). Same defect class as
    # the CCX_FORCING_COLS length trap: a stored artifact indexed by a constant
    # that is free to move underneath it.
    u <- md$u_mode
    .nm <- if (!is.null(md$param_names)) md$param_names else CCX_PARAM_NAMES
    if (length(u) != length(.nm))
      stop("mode file's u_mode has ", length(u), " values but its param_names has ",
           length(.nm), " -- the file is internally inconsistent.")
    names(u) <- .nm
    # DECODE ONLY THE BANDED PARAMETERS, which is all this check verifies.
    # Decoding the WHOLE vector made the check fail on any mode file whose
    # parameter set differs from the build's -- even though the band question it
    # exists to answer is perfectly well posed for such a file. A gate should
    # need no more of its input than the property it gates.
    for (bn in names(bands)) {
      if (!bn %in% .nm)
        stop("mode file records a band for ", bn, " but has no ", bn,
             " in its param_names.")
      got <- .from_unc(u[[bn]], CCX_PARAM_TABLE[[bn]])
      if (abs(got - md$par_mode[[bn]]) > 1e-8 * max(abs(md$par_mode[[bn]]), 1e-12))
        stop("adopting ", bn, "'s recorded band [", paste(bands[[bn]], collapse = ", "),
             "] still does not reproduce par_mode's ", bn, " (", md$par_mode[[bn]],
             "); got ", got, ". This mode file was fitted under some OTHER band.")
    }
  }
  cat(sprintf("[ccx_adopt_mode_band] %s\n", paste(vapply(names(bands), function(bn)
    sprintf("%s -> [%g, %g] (mode %.4f)", bn, bands[[bn]][1], bands[[bn]][2],
            if (is.null(md$par_mode)) NA_real_ else md$par_mode[[bn]]),
    character(1)), collapse = "; ")))
  invisible(old)
}
