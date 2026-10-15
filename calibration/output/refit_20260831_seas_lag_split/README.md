# refit_20260831_seas_lag_split — the 22-parameter refit, ONTO THE SPLIT NPP LAG

**Launched 2026-08-31** by the session continuing
`notes/handoff_2026-08-31_priced_and_option_A.md` §8.1. This is the refit that handoff declared
**OWED TWICE OVER**. Nothing here is a result until both `*/mode_fit_pumpN.rds` carry a completion
timestamp and both `_run.log`s end with the comparison write.

## WHY THIS DIRECTORY EXISTS

The parameter SET changed on **2026-08-31 (`11ff844`, Option A)**: `seas_lag_p` became
`seas_lag_p_NH` / `seas_lag_p_SH`, both keeping the ORIGINAL prior. That makes
`refit_20260830_gamma_diff_remap` — which converged only the day before — a **21-parameter file in
a 22-parameter build**: a good warm start, not a mode of the current space.

It is owed twice:
1. **For the split itself** — there is no fitted mode of the 22-parameter space.
2. **To collect what the split already shows is on the table.** Holding NH at its fitted 1.7502 and
   rotating the SH alone, **SH lag 2.00 scores +11.33**. The fit wants a LATER SH lag than the NH's
   and the old scalar had no way to give it one.

It also resolves the **6 deliberately-left failures** at `11ff844`, all of which say the one true
thing that the stored modes are 21-parameter files (`test-mode-decode.R:15,:29`;
`test-mode-file.R:109` ×2, `:203`; `test-prior-z.R:38`).

## ⚠ A BLOCKER IN THE HANDOFF'S OWN RECIPE, FOUND AND FIXED BEFORE LAUNCH

Handoff §8.1 says to warm-start from the 08-30 arms because *"`par_mode` overlays via the legacy
branch"*. That is true of the MODEL — `ccx_seas_lag_p()`'s absence contract — but **not of the
FITTER**. The warm start re-encodes through `ccx_par_to_unc()`, which iterates the BUILD's names, so
a 21-parameter `par_mode` reached `.to_unc(NULL, ...)` and died inside `vapply` as

    values must be length 1, but FUN(X[[12]]) result is length 0

— an **index**, three frames below the cause, naming nothing. **Verified by direct probe before
launch: both arm files failed.** It would have killed a 14 h run in its first seconds.

The 08-31 session hardened the DECODE side (`ccx_unc_to_par()` now says a file "was encoded under a
different parameter set") and left the ENCODE side unhardened. Both halves now exist:

- **`ccx_par_to_unc()`** names the absent parameters and says a parameter SET is what changed.
- **`ccx_migrate_par_set()`** brings a stored list onto the build's fitted set, reading what an
  absent split means **from `ccx_seas_lag_p()` itself** — the one resolver both cores go through —
  rather than restating the contract. It **refuses** to fill from `CCX_SEAS_LAG_P_DEFAULT`: a warm
  start from an invented coordinate is not a warm start.
- The driver's warm-start site migrates and **prints what it filled**.

Both guards are **mutation-tested** (disable the encode guard → 3 failures; fill from the named
default instead of the legacy scalar → 5), and `test-seas-lag-split.R` now exercises the two real
08-30 arm files end to end.

## SETUP — following the 08-30 recipe

- **BOTH ARMS.** `from90` (free) and `pin90` (`fert_k` pinned at 90 via `CCX_PIN_PARAMS`). The pinned
  arm re-measures `PIN_PRIOR_CREDIT`.
  ⚠ **The 08-30 refit WIDENED the arm gap** (−21.19 vs the incumbent arms' −19.86) and showed the
  excess **−9.52 is a likelihood differential re-optimization cannot recover**, so
  `test-mode-file.R`'s premise is **permanently** false. This run re-measures the gap on comparable
  arms; it is not expected to close it.
- **`h_ml` UNBOUNDED over its shipped support [30, 200]**, prior NOT renormalized — unchanged from
  08-30; both original reasons for the bound are discharged.
- **The seasonal `tau_ex` diagnostic is NOT fitted here.** `tau_ex_seas_amp` / `tau_ex_seas_phase`
  are `base_param`s at default 0, so this run scores the shipped model bit for bit. Fitting them is
  a separate decision, and §5 of the handoff says the phase must be PINNED FROM OBSERVATION first.

## PROVENANCE OF THE INPUTS

- **Warm start:** each arm's `mode_fit_pumpN.rds` was SEEDED as a byte copy of the corresponding
  08-30 arm, so `ARM_WARM` picks it up and the driver overwrites in place:

  | arm | source | md5 |
  |---|---|---|
  | `from90` | `refit_20260830_gamma_diff_remap/from90` | `f4f28060a9ea35064ddf2bf70d118ace` |
  | `pin90`  | `refit_20260830_gamma_diff_remap/pin90`  | `23bfb7457f331d213fdddc406f72f274` |

  ⚠ These are **21-parameter files**; the migration above is what makes them usable, and each
  `_run.log` records the `WARM START MIGRATED` line naming the two filled coordinates.
- **Driver:** `run_modefind_pump_arms_FROZEN.R` is a byte copy of
  `calibration/run_modefind_pump_arms.R` taken BEFORE launch. The run executes the FROZEN copy
  because Rscript parses incrementally and editing a live script shifts byte offsets under the
  running process (memory `never_edit_a_running_script`).
  **The tracked driver may be edited during this run; this copy may not.**

## ⚠ GATES IN THIS DRIVER THAT ARE KNOWN-NOISY, CARRIED FORWARD UNCHANGED

The kink scan prints `0 kink(s) in [30, 200]` — correct, the C1 remap removed all 26 — and then
fires its `!= 3` warning on **every** run. **The substantive half is still OWED**:
`diag_hess_eps_21par.R` chose its Hessian step against a KINKED objective, so the step study must be
re-run against the C1 objective before any covariance off this refit is trusted. Left unmodified
pending a ruling, same as 08-30.
