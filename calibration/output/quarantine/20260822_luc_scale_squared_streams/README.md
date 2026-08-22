# Quarantine — 2026-08-22 — `luc_scale` squared in the stored per-stream table

## 1. Which bug applies

`calibration/run_modefind_pump_arms.R:452` derived the annual E_LUC series from a
forcing whose four LUC columns had **already** been multiplied by `luc_scale`
three lines above, and then multiplied it by `luc_scale` again. The gross
land-sink reconstruction passed to `ccx_loglik(luc = )` was therefore scaled by
`luc_scale²`.

**The objective never had this bug.** `ccx_make_logpost()` (R/calibrate.R) derives
`ELUC_BASE` once, from a forcing built at `luc_scale = 1`, outside the closure.
So every fitted quantity is sound: `par_mode`, `u_mode`, `logpost`, `hessian`,
`cov`, `cor`, `sd_unc`, `eigen`, `logdet_negH`, and every evidence margin computed
from them. **Only the stored `streams` field was wrong**, because `luc` is read by
exactly one term in `ccx_loglik` — `gcb_land_sink`.

Measured at arm N: stored `gcb_land_sink` **−93.71**, correct value **−95.62**,
error **+1.91 log-units**. Not common-mode across arms (`luc_scale` 0.8902 vs
0.8575), so the N-vs-D per-stream comparison carried a *differential* error of the
same order as the ±5.62 evidence margin printed next to it.

Found by the provenance gate in `calibration/diag_design_gates_at_mode.R`, which
recomputes each arm file's stored per-stream logL at the same `par_mode` under
current code. Seven further sites of the same signature were found by the scan and
fixed the same day; `tests/testthat/test-luc-scale.R` now lints for it and is
mutation-tested.

## 2. Which files are here

Pre-repair copies, exactly as `run_modefind_pump_arms.R` wrote them:

- `mode_fit_pumpN.rds` — arm N, fitted 2026-08-21 (`refit_20260821_cont.log`)
- `mode_fit_pumpD.rds` — arm D, fitted 2026-08-18/20 (`refit_20260818.log`)

## 3. Canonical post-fix replacement

`calibration/output/pump_arms/mode_fit_pump{N,D}.rds` — same paths, repaired in
place by `calibration/repair_arm_streams.R`. Each now carries:

| field | vintage |
|---|---|
| `streams` | recomputed at this `par_mode` under the **current** objective |
| `streams_as_fitted` | what the refit stored — the buggy values, kept for postmortem |
| `streams_provenance` | dates, commit, and which fields belong to which vintage |
| `par_mode`, `logpost`, `hessian`, … | **unchanged** — as fitted, never affected |

**Two vintages live in each file, deliberately.** `streams` is on today's
objective (ice scores `co2_SH` since `d6adb58`); `logpost` is on the objective in
force at fit time. They reconcile when the owed refit runs.

Deltas from the repair:

- **arm N: +15.0 total** — `co2_icecore` +16.90 (the `d6adb58` objective change)
  and `gcb_land_sink` −1.91 (this bug). Nothing else moved by >0.05.
- **arm D: −8244.4 total**, dominated by `co2_seasonal_MLO` −7130.73. That is *not*
  this bug: arm D was last fitted before the 2026-08-20g `CCX_SST_SEAS_LAG`
  correction. **Arm D and arm N remain two different objectives and must not be
  tabled as an arm comparison** — repairing the LUC term does not change that.
