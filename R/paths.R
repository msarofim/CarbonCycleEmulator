# =====================================================================
# paths.R — resolve repo-relative paths regardless of working directory.
#
# Needed because scripts, testthat (which runs from tests/testthat/), and
# the Shiny app (which runs from app/) all have different working
# directories but must reach the same data/ files.
# =====================================================================

REPO_MARKER <- "DESIGN.md"

#' Absolute path to the repository root
#' @param start directory to search upward from
ccx_root <- function(start = getwd()) {
  d <- normalizePath(start, mustWork = FALSE)
  for (i in 1:10) {
    if (file.exists(file.path(d, REPO_MARKER))) return(d)
    parent <- dirname(d)
    if (identical(parent, d)) break
    d <- parent
  }
  stop("Could not locate the CarbonCycleEmulator root (no '", REPO_MARKER,
       "' found above '", start, "').")
}

#' Build a path relative to the repository root
#' @param ... path components, e.g. ccx_path("data", "obs_co2_monthly.rds")
ccx_path <- function(...) file.path(ccx_root(), ...)

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
CCX_MODE_CANONICAL <- "from90"

CCX_MODE_FILES <- c(
  from90 = file.path("calibration", "output", "refit_20260825f_from90",
                     "mode_fit_pumpN.rds"),
  pin90  = file.path("calibration", "output", "refit_20260825f_pin90",
                     "mode_fit_pumpN.rds")
)

# WHICH ARMS ARE FREE -- AND WHY THE STORED logpost IS A TRAP ACROSS THEM.
# `pin90`'s stored logpost is -1544.50, HIGHER than the canonical mode's
# -1544.615, and reading that as "pin90 wins" is wrong: the pinned arm's
# objective carries a near-delta prior on `fert_k`, worth +11.6698 at
# fert_k = 90. On the comparable scale pin90 is -1556.17, i.e. 11.56 BELOW the
# free mode. That offset is COMPUTED from the transform by
# diag_landed_gap_streams.R (gate 1), never quoted, so it is not stored here --
# what is stored is which arms may be compared on their stored value at all.
# The project rule is "the highest FREE arm wins regardless of name".
CCX_MODE_PINNED <- c(from90 = FALSE, pin90 = TRUE)

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
              "calibration/output/quarantine/20260825_seas_isotope_rectification/")
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
ccx_mode_params <- function(md = CCX_MODE_CANONICAL) {
  if (is.character(md)) md <- readRDS(ccx_mode_file(md))
  if (!is.null(md$par_mode)) return(md$par_mode)
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
  if (!identical(.nm, CCX_PARAM_NAMES))
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
