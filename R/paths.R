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

# The pre-fix names, kept ONLY so that asking for one gets the reason rather
# than a file-not-found. Everything here is quarantined and not comparable.
CCX_MODE_RETIRED <- c(
  N   = "arm N of the 2026-08-18/20 pump refit",
  D   = "arm D of the 2026-08-18 pump refit",
  ref = "the ABANDONED reference arm of refit_20260825f (its mode file is the PRE-FIX SEED)"
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
    stop("mode '", mode, "' (", CCX_MODE_RETIRED[[mode]], ") was fitted BEFORE ",
         "the 2026-08-25f seasonal-NEP isotope fix (`6bda464`), which changed ",
         "the objective. It is quarantined under ",
         "calibration/output/quarantine/20260825_seas_isotope_rectification/ ",
         "and is NOT comparable with anything fitted since. The canonical mode ",
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
# an 11.1 % error, and `h_ml` is the ONLY one of the 21 that moves. Every
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
  u <- md$u_mode; names(u) <- CCX_PARAM_NAMES
  if (is.null(md$hml_bound)) return(ccx_unc_to_par(u))
  .old <- CCX_PARAM_TABLE$h_ml
  on.exit(CCX_PARAM_TABLE$h_ml <<- .old, add = TRUE)
  CCX_PARAM_TABLE$h_ml$lo <<- md$hml_bound[1]
  CCX_PARAM_TABLE$h_ml$hi <<- md$hml_bound[2]
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
  u <- md$u_mode; names(u) <- CCX_PARAM_NAMES
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
