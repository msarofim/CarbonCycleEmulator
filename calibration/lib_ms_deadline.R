# =====================================================================
# lib_ms_deadline.R -- the multistart's IN-RESTART DEADLINE (option A; Marcus 2026-10-05, ruling "Option A" on
# notes/proposal_2026-10-04_multistart_inrestart_wall.md). Sourced by calibration/run_dispersed_multistart.R;
# tested by tests/testthat/test-ms-deadline.R.
#
# WHY. The 10-04 (a) substep fix makes evaluations near the P8 h_ml wall 25-75x dearer, and the driver sizes
# each optimiser step BEFORE it starts: `optim()` cannot be interrupted from inside, so a step that drifts to
# the wall overruns its projection unseen (the k_w price arm's start 7: one restart 250 min for 6,002 evals,
# 7.6x; memory ccx_substep_fix_slows_nearwall_starts). On the Mac that costs one restart; under a hard SLURM
# wall it kills the task with the restart's progress unwritten.
#
# HOW. The objective wrapper checks a per-step deadline BEFORE each evaluation and tracks the best point it has
# evaluated. Past the deadline it signals a classed condition (`ms_deadline`), and ms_run_step() returns the
# tracked best as the step's result. Nelder-Mead's best vertex and BFGS's iterates and gradient probes are all
# evaluated points, so nothing better than the tracked best is lost -- only the simplex's or the quasi-Newton
# matrix's state is.
# ⭐ BEHAVIOUR-PRESERVING WHEN NO DEADLINE IS REACHED: the wrapper returns the same values in the same order, so
#   `optim()` takes the identical path (test-ms-deadline D2 asserts identical()).
# ⚠ The two SIZING helpers below are deliberate behaviour changes, ruled with option A (proposal §3): a restart's
#   minutes are normalised by the evaluations it actually made, and the polish is sized from the observed rate.
# =====================================================================

#' The condition a passed deadline signals (classed, so a caller can catch it and nothing else)
ms_deadline_condition <- function(msg = "the optimiser step's deadline has passed")
  structure(class = c("ms_deadline", "error", "condition"), list(message = msg, call = NULL))

#' The mutable state of the CURRENT optimiser step: its deadline (seconds since the epoch; Inf = none) and the
#' best point evaluated in it. One environment, shared by the wrapper and ms_run_step().
ms_step_state <- function() {
  s <- new.env(parent = emptyenv())
  s$deadline <- Inf; s$best_val <- Inf; s$best_u <- NULL
  s
}

#' Called by the objective wrapper BEFORE it evaluates: signals `ms_deadline` once the step's time is spent.
#' Checking first means the step never starts an evaluation it has no time for; a single evaluation is itself
#' bounded (the substep controller STOPs past CCX_SUBSTEPS_MAX).
ms_check_deadline <- function(state) {
  if (as.numeric(Sys.time()) > state$deadline) stop(ms_deadline_condition())
  invisible(NULL)
}

#' Called by the objective wrapper AFTER it evaluates (val = the minimised value)
ms_track_best <- function(state, u, val) {
  if (val < state$best_val) { state$best_val <- val; state$best_u <- u }
  invisible(NULL)
}

#' One optimiser step under a deadline. `val0` is the minimised value at u0, returned only when the deadline
#' passed before the step evaluated anything. Any OTHER error propagates unchanged.
#' Returns optim()'s list plus `deadline` (TRUE = stopped at it; then only par, value and deadline are set).
ms_run_step <- function(state, u0, val0, fn, method, control, deadline) {
  # ⚠ FORCED BEFORE THE DEADLINE IS SET. R evaluates arguments lazily: a `val0` passed as an expression that
  # calls the guarded objective (test-ms-deadline D1 passes fn(u0)) would otherwise be evaluated inside the
  # handler, past the deadline, and signal a second, uncaught `ms_deadline` (found by mutation M2).
  force(val0); force(u0)
  state$deadline <- as.numeric(deadline); state$best_val <- Inf; state$best_u <- NULL
  on.exit(state$deadline <- Inf, add = TRUE)
  tryCatch({
    f <- stats::optim(u0, fn, method = method, control = control)
    f$deadline <- FALSE
    f
  }, ms_deadline = function(e) {
    if (is.null(state$best_u)) list(par = u0, value = val0, deadline = TRUE)
    else list(par = state$best_u, value = state$best_val, deadline = TRUE)
  })
}

#' A restart's minutes NORMALISED to a full `maxit_full` restart, by the evaluations it actually made (not the
#' planned maxit: a Nelder-Mead step that stops early on reltol, or at the deadline, made fewer). NULL when it
#' made none, so the caller appends nothing.
ms_restart_minutes <- function(minutes, maxit_full, evals) {
  if (!is.finite(evals) || evals <= 0) return(NULL)
  minutes * maxit_full / evals
}

#' The polish's iteration budget: what fits `left_min` at `safety` x (2 n_par + 1) evaluations per BFGS
#' iteration, at the OBSERVED per-evaluation rate when restarts have run (the slowest, as maxit_for_budget()
#' uses), else the start point's measured rate. 0 when not even `floor_` iterations fit.
ms_polish_maxit <- function(left_min, n_par, sec_per_eval, restart_min, maxit_full, safety, floor_, cap) {
  spe <- if (length(restart_min)) 60 * max(restart_min) / maxit_full else sec_per_eval
  per <- safety * (2 * n_par + 1) * spe / 60
  n <- floor(left_min / per)
  if (n < floor_) 0L else as.integer(min(n, cap))
}
