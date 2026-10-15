# QUARANTINE 20260910_periodic_spinup_adopted — `hilda31`, the pre-adoption canonical

Moved 2026-09-10, when `hilda31p` became `CCX_MODE_CANONICAL`.

## 1. WHY THIS IS HERE

**NOT a bug — a deliberate change of OBJECTIVE.** `hilda31` is SUPERSEDED, not defective.
Two objective moves separate it from anything fitted since, and neither changed the
parameter set (31 names throughout — which is exactly why a directory, not a `param_names`
guard, has to say so):

| date | commit | change | what it moved |
|---|---|---|---|
| 2026-09-09w | (prior re-centering) | `ent_seas_amp_SH` center 10.95 → 6.5525, `h_ml` 83.94 → 59.69 m | the PRIOR: −0.811 at `hilda31` |
| 2026-09-09x | `50f0105` | the PERIODIC spinup adopted as `CCX_OBJECTIVE_SPINUP` (Marcus's ruling) | the LIKELIHOOD: −10.158 at `hilda31` (SPO −16.73, MLO +8.28) |

⇒ `hilda31` was fitted under the ASEASONAL spinup and the pre-09-09w priors. Its stored
logpost **−1478.659503** is in the units of THAT objective. Re-scored under today's it is
**−1489.6284**, and the refit under today's objective found **−1480.5404** — a gain of
**+9.0880** that is like-for-like ONLY on the re-scored number, never on the stored one
⇒ [[compare_gaps_not_absolute_logposts]]. ⛔ **Both `hilda31` and `hilda31p` are
`seas_ml = 0`** — the seasonal mixed layer was OFF in both, so the pair is the shipped
model before and after adoption, and NOT a round-6 result ⇒ [[ccx_refit_ran_at_seas_ml_0]].

⚠ **Why it had to leave `CCX_MODE_FILES` rather than sit beside the replacement**:
`test-mode-file.R:187` picks the FREE arm with the largest STORED logpost, and −1478.66 >
−1480.54 would have named `hilda31` — a comparison across two objectives that means
nothing. The registry may hold only arms whose stored numbers are commensurable.

## 2. WHAT IS IN HERE

- `refit_20260908_hilda31/` — the round-5 winner of the HILDA refit, promoted 2026-09-08f
  from `multistart_20260908e_hilda31_asx` (which stays in place; it is a survey, not a
  mode). `CCX_MODE_CANONICAL` from 2026-09-08f to 2026-09-10. `struct = "hilda"`,
  `seas_ml` 0 (unrecorded — the field did not exist; 0 is a fact about every file of its
  age), `h_ml` 49.15 m, stored logpost −1478.659503, Hessian PD with `h_ml` unstable.
  `mode_fit_pumpN_hess.rds` is its standalone second-order block.

Facts that remain TRUE of this file and are still asserted from it by path
(`CCX_MODE_HILDA31_QUARANTINED`, `tests/testthat/test-enso-demean.R`): the ENSO-demean flag
is worth **43.8367** here under the aseasonal spinup (what Ruling A was ratified on) and
**63.7282** under the adopted one — the latter a STALE-MODE artifact, not a re-pricing;
refitted, the flag is 45.1896 ⇒ [[ruling_a_repricing_was_a_stale_mode]].

## 3. THE CANONICAL REPLACEMENT

`calibration/output/refit_20260910_hilda31_periodic/mode_fit_pumpN.rds`, resolved as
`ccx_mode_file("hilda31p")` — 31 parameters, `struct = "hilda"`, `seas_ml = 0`, logpost
**−1480.540424** under the adopted objective, promoted from start id 6 of the Torch
arrays `17318015` (round 1) + `17325832` (round 2; 14/14 converged, 8 onto this point to
four decimals, 2 distinct basins) by `calibration/promote_multistart_mode.R`. Hessian
recomputed 2026-09-10 (PD, condition 3.6e5, `h_ml` unstable — the same flag as here).

Do not point anything here except a deliberate before/after comparison.
