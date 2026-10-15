# =====================================================================
# lib_ms_deadline.R -- the multistart's IN-RESTART DEADLINE (option A; Marcus 2026-10-05, ruling "Option A" on
# notes/proposal_2026-10-04_multistart_inrestart_wall.md). Sourced by calibration/run_dispersed_multistart.R;
# tested by tests/testthat/test-ms-deadline.R.
#
# WHY. The 10-04 (a) substep fix makes evaluations near the P8 h_ml wall 25-75x dearer, and the driver sizes
# each optimizer step BEFORE it starts: `optim()` cannot be interrupted from inside, so a step that drifts to
# the wall overruns its projection unseen (the k_w price arm's start 7: one restart 250 min for 6,002 evals,
# 7.6x; memory ccx_substep_fix_slows_nearwall_starts). On the Mac that costs one restart; under a hard SLURM
# wall it kills the task with the restart's progress unwritten.
#
# HOW. The objective wrapper checks a per-step deadline BEFORE each evaluation and tracks the best point it has
# evaluated. Past the deadline it signals a classed condition (`ms_deadline`), and ms_run_step() returns the
# tracked best as the step's result. Nelder-Mead's best vertex and BFGS's iterates and gradient probes are all
# evaluated points, so nothing better than the tracked best is lost -- only the simplex's or the quasi-Newton
# matrix's state is.
# ⭐ BEHAVIOR-PRESERVING WHEN NO DEADLINE IS REACHED: the wrapper returns the same values in the same order, so
#   `optim()` takes the identical path (test-ms-deadline D2 asserts identical()).
# ⚠ The two SIZING helpers below are deliberate behavior changes, ruled with option A (proposal §3): a restart's
#   minutes are normalized by the evaluations it actually made, and the polish is sized from the observed rate.
#
# ⭐ THE BUDGET'S CLOCK (CHANGELOG 2026-10-05 o; Marcus, D1 "CPU on Mac, wall on Torch (Recommended)", D2 "Keep
# 300 CPU-min (Recommended)"). Every budget reading and every deadline goes through ms_clock(), and nothing else
# in the budget path reads a clock (test-ms-clock C5 lints it). On 10-05 a ~3 h Mac sleep spent #16's WALL budget
# (memory mac_sleep_eats_wall_budget): four starts ran out of time while the machine was off.
#   "wall" -- seconds since the epoch. The default, and what every run before 10-05 (o) used.
#   "cpu"  -- this R process's OWN CPU seconds (user + sys; children excluded, and there are none). They do not
#             advance while the process is suspended or the machine sleeps (measured 10-05: a 5-s SIGSTOP added
#             +8.2 s wall, +0.00 s CPU).
# ⚠ CPU time cannot outrun wall time only while BLAS runs ONE thread (both runners pin it). A k-thread BLAS would
#   spend a CPU budget up to k times faster than the wall clock.
# =====================================================================

#' The clocks a budget may run on. CCX_MS_CLOCK selects one.
MS_CLOCK_KINDS <- c("wall", "cpu")

#' The budget's clock from CCX_MS_CLOCK; unset or "" is "wall". VALIDATED: an unknown value STOPS rather than
#' falling back, because a typo that silently ran the wall clock is the failure this switch exists to prevent.
ms_clock_kind <- function(v = Sys.getenv("CCX_MS_CLOCK", "")) {
  if (!nzchar(v)) return("wall")
  if (!v %in% MS_CLOCK_KINDS)
    stop("CCX_MS_CLOCK must be one of ", paste(sprintf("'%s'", MS_CLOCK_KINDS), collapse = ", "),
         "; got '", v, "'", call. = FALSE)
  v
}

#' Seconds on the named clock. Only a DIFFERENCE of two readings on one clock means anything: "wall" counts from
#' the epoch, "cpu" from this process's start.
ms_clock <- function(kind) {
  switch(kind,
         wall = as.numeric(Sys.time()),
         cpu  = { pt <- proc.time(); unname(pt[["user.self"]] + pt[["sys.self"]]) },
         stop("unknown clock '", kind, "'", call. = FALSE))
}

#' The clock's name in labels ("wall" / "CPU"), so a printed budget always says which clock it is on
ms_clock_label <- function(kind) c(wall = "wall", cpu = "CPU")[[ms_clock_kind(kind)]]

#' The clock a START FILE ran on. A file written before 10-05 (o) has no `clock` field, and every such file ran
#' the wall clock, so absent reads as "wall".
ms_start_clock <- function(r) if (is.null(r$clock)) "wall" else r$clock

#' D3 (Marcus 2026-10-05, "Record and warn (Recommended)"): the warning for a set of start files that ran on more
#' than one clock, or NULL when they agree. Their minutes and out-of-time counts are not like-for-like.
ms_clock_mix_note <- function(clocks, ids) {
  u <- sort(unique(clocks))
  if (length(u) < 2L) return(NULL)
  paste0("MIXED CLOCKS: ",
         paste(vapply(u, function(k) sprintf("%s [%s]", k, paste(ids[clocks == k], collapse = ", ")), character(1)),
               collapse = "; "),
         ". Minutes and out-of-time counts are not like-for-like across clocks (D3, CHANGELOG 2026-10-05 o).")
}

#' The condition a passed deadline signals (classed, so a caller can catch it and nothing else)
ms_deadline_condition <- function(msg = "the optimiser step's deadline has passed")
  structure(class = c("ms_deadline", "error", "condition"), list(message = msg, call = NULL))

#' The mutable state of the CURRENT optimizer step: the clock its deadlines are read on, its deadline (seconds
#' on that clock; Inf = none) and the best point evaluated in it. One environment, shared by the wrapper and
#' ms_run_step(). The driver derives its budget origin and every deadline from `$clock`, so they cannot disagree.
ms_step_state <- function(clock = "wall") {
  s <- new.env(parent = emptyenv())
  s$clock <- ms_clock_kind(clock)
  s$deadline <- Inf; s$best_val <- Inf; s$best_u <- NULL
  s
}

#' Called by the objective wrapper BEFORE it evaluates: signals `ms_deadline` once the step's time is spent.
#' Checking first means the step never starts an evaluation it has no time for; a single evaluation is itself
#' bounded (the substep controller STOPs past CCX_SUBSTEPS_MAX).
ms_check_deadline <- function(state) {
  if (ms_clock(state$clock) > state$deadline) stop(ms_deadline_condition())
  invisible(NULL)
}

#' Called by the objective wrapper AFTER it evaluates (val = the minimized value)
ms_track_best <- function(state, u, val) {
  if (val < state$best_val) { state$best_val <- val; state$best_u <- u }
  invisible(NULL)
}

#' One optimizer step under a deadline. `val0` is the minimized value at u0, returned only when the deadline
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

#' THE KEPT PAIR (2026-10-08 c; Marcus: "Build the bookkeeping fix"): a step's returned point and ITS OWN value,
#' by evaluating it. ⛔ optim()'s `value` is NOT f(`par`) in general: at NORMAL convergence R's BFGS (vmmin) exits its
#' line search on "no change" (`10 + X[i] == 10 + b[i]` for all i) and returns that `b`, NEVER EVALUATED, beside
#' Fmin = f(X), ~1e-16 away (20 / 20 seeded synthetic runs, outputs/diagnostics/obj18_vmmin_synthetic.log). On an
#' objective with a ~1e-6..1e-5 numerical floor that is a floor-sized lie: #18's id 13 was stopped DEAD on it
#' (CHANGELOG 2026-10-08 a). Re-evaluating keeps the optimizer's PATH untouched (it already returned `par`) and makes
#' (par, value) a pair by construction, so the end-of-run identity check can be EXACT. One evaluation per step.
#' @param step ms_run_step()'s result (par, value)
#' @param fn the objective the step minimized (the driver's neg_lp: counted, penalty-mapped, deadline-free outside a step)
#' @return list(par, value = fn(par), claimed = step$value, gap = value - claimed)
ms_kept_pair <- function(step, fn) {
  v <- fn(step$par)
  list(par = step$par, value = v, claimed = step$value, gap = v - step$value)
}

#' A restart's minutes NORMALIZED to a full `maxit_full` restart, by the evaluations it actually made (not the
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
  spe <- if (length(restart_min)) ms_eval_rate_sec(restart_min, maxit_full)[["slowest"]] else sec_per_eval
  per <- safety * (2 * n_par + 1) * spe / 60
  n <- floor(left_min / per)
  if (n < floor_) 0L else as.integer(min(n, cap))
}

#' The restarts' OBSERVED seconds per evaluation, on the budget's clock: the slowest restart (what the polish and
#' maxit_for_budget() size on, so the printed rate IS the sizing rate) and the fastest. `restart_min` holds
#' ms_restart_minutes() values, i.e. minutes NORMALIZED to a full `maxit_full` restart, so one restart's rate is
#' 60 x restart_min / maxit_full and the normalization cancels. NULL when no restart ran.
#' ⚠ REPLACES (2026-10-06, Marcus: "Fix eval-rate line (Recommended)") the driver's end-of-run
#'   60 x sum(restart_min) / n_eval, which divided NORMALIZED minutes by an eval count that includes the polish's
#'   and the start's. It was wrong in BOTH directions: 0.0333 s/eval printed against a true 0.2935 (10-05 q smoke
#'   T1: one 202-eval restart at maxit 200 in a 1763-eval task; the driver had measured 0.2945 before it), and
#'   32.8 against 1.149 (T3's wall arm: one 210-eval restart normalized to maxit 6000). test-ms-deadline D9.
ms_eval_rate_sec <- function(restart_min, maxit_full) {
  if (!length(restart_min) || !(max(restart_min) > 0)) return(NULL)
  c(slowest = 60 * max(restart_min) / maxit_full, fastest = 60 * min(restart_min) / maxit_full)
}
