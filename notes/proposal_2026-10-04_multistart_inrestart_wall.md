# PROPOSAL 2026-10-04 — an IN-RESTART wall for the multistart (handoff 10-04c §4 item 6)

**Status: for Marcus's ruling. Nothing is built.** This is the design question owed before any Torch
multistart under `seas_ml` = 1 (memory `ccx_substep_fix_slows_nearwall_starts`).

## 1. The problem, measured
- The 10-04 (a) substep fix (ruled "Apply A+B+C") correctly makes evaluations within ~0.3 m of the P8 `h_ml`
  wall cost 25–75× more: 100–300 RK4 substeps instead of 4.
- `calibration/run_dispersed_multistart.R` sizes each Nelder-Mead restart BEFORE it starts
  (`maxit_for_budget()`, the projected budget at l. 880–975). It uses the slowest whole-restart rate seen so far.
  `optim()` cannot be interrupted from inside, so a restart that drifts to the wall partway through overruns its
  projection, unseen.
- **The `k_w` price arm (Mac, 300 min wall):**
  - start 7's second restart ran **250 min for 6,002 evaluations** (~2.5 s/eval against 0.33 projected; 7.6×) and
    ended at `h_ml` 75.39 m, 0.11 m from the wall;
  - start 11's first restart ran 164 min, then recovered.
  The #15 waves (old controller) never exceeded ~100 min in any restart.
- **The polish is more exposed than the restarts.** Its size (l. 1015–1019) uses `MS_SEC_PER_EVAL`, the START
  point's 5-sample rate, not any observed restart rate. Its `tryCatch(error = NULL)` (l. 1024) would discard the
  polish's progress on any error.
- On the Mac the overrun is bounded: one restart, after which the budget skips the rest. **Under a hard SLURM
  wall on Torch it kills the task mid-restart.** The cycle checkpoint survives; the restart's progress does not;
  fairshare pays for the dead time.

## 2. Options
| | what | changes results? | needs a ruling because |
|---|---|---|---|
| **A** | **an in-restart DEADLINE.** The objective wrapper tracks the best point it has evaluated. Past the deadline it signals a classed condition; a `tryCatch` around `optim()` returns the tracked best as the restart's result. | **No**, unless a deadline is reached: then the restart ends at its best evaluated point instead of being killed. | it is a driver change |
| B | past the deadline, return `MS_PENALTY` without running the model, so NM contracts onto its best vertex at no cost | no (same end point as A) | it inflates `n_eval` with sentinels and leans on NM's internals to stop; A is cleaner |
| C | a SOFT WALL: treat points needing more than N substeps as infeasible | **yes**: it removes valid points near the P8 wall from the feasible set | it moves the objective |
| D | accept it, and size `CCX_MS_WALL_MIN` with more margin | no | no fixed margin covers a 7.6× restart on a 4 h partition |

## 3. Recommendation: A, on both the restarts and the polish
- **Deadline:**
  - for an NM restart, `t0 + MS_WALL_MIN − polish_reserve_min()`;
  - for the polish, `t0 + MS_WALL_MIN`.
  Both sit inside the SLURM margin that `MS_WALL_MIN` already keeps (60 min below the wall, per the l. 893–900
  arithmetic).
- **The wrapper** (`neg_lp`, l. 538):
  - keep `best_u` / `best_val` over every evaluation of the current step;
  - check `Sys.time()` BEFORE evaluating (a single evaluation is bounded: the controller STOPs past
    `CCX_SUBSTEPS_MAX`);
  - past the deadline, `stop(structure(class = c("ms_deadline", "error", "condition"), list(message = …)))`.
- **The caller:** `tryCatch(optim(…), ms_deadline = function(e) list(par = best_u, value = best_val, deadline = TRUE))`.
  - Nelder-Mead's best vertex is always an evaluated point, so nothing better than `best_u` is lost; only the
    simplex's shape is.
  - BFGS's line-search points are evaluated points too.
- **Bookkeeping:**
  - log "STOPPED AT THE DEADLINE after k evals" on the restart line;
  - normalise `restart_min` by the evaluations actually done, not the planned `mx`;
  - set `out_of_time`;
  - write the start file as today: NOT converged, with the reason.
- **The polish's size** should use `max(restart_min)` when restarts exist, like `maxit_for_budget()` does,
  instead of the start point's rate.
- **Bit-identity when no deadline is reached:** the wrapper adds bookkeeping only. Every evaluation, `optim()`
  path and result is unchanged.

## 4. Test plan (each mutation-proven)
1. A mock objective with a scripted `Sys.sleep` slowdown after k evaluations: the restart stops within one
   evaluation of the deadline and returns the best evaluated point. Mutation: drop the check, and the test's own
   timeout fails it.
2. The same mock without the slowdown gives an `optim()` result `identical()` to the current code.
3. The polish's size reads `max(restart_min)` when restarts exist. Mutation: revert to `MS_SEC_PER_EVAL`.
4. A start that hits the deadline is recorded NOT converged with the reason. Mutation: drop the flag.

## 5. Cost and what it does not change
- About 40 lines in the driver plus one new test file. No model or objective change, and no mode file moves.
- It does NOT make near-wall starts faster. It bounds what they cost, and the start's best point is kept.
- The `k_w` arm in flight runs a frozen tree and is unaffected.
