# PRE-REFIT SNAPSHOT — the 20-parameter modes, preserved before the 21-parameter run overwrites them

Copied 2026-08-18, immediately after the 21-parameter two-arm refit was launched and
BEFORE it reached its first write. `run_modefind_pump_arms.R` writes
`mode_fit_pump{N,D}.rds` and `pump_arms_comparison.rds` to fixed paths, so the running
job WILL replace these in place.

## What these are

The **20-parameter** modes from the refit that landed earlier on 2026-08-18 — including
**`mode_fit_pumpN.rds`, the mode Marcus PROVISIONALLY ADOPTED** (evidence +5.62 over D,
indicative only). Objective: pre-priority-rework — `sigma_d13c` free, no `rep_dC`, no
d13C-seasonality streams, seasonal cycle on the fitted sine, no SST.

## Why they are kept rather than left to be overwritten

They are the provenance for every number quoted before 2026-08-18's rework, and they are
the source of the `lifted` probe point in `calibration/diag_hess_eps_21par.R`. Nothing
about them is wrong — they are simply modes of a DIFFERENT objective, and the standing
rule is that superseded outputs move aside rather than sit at canonical paths where they
can be retrieved silently.

## What supersedes them

`calibration/output/pump_arms/mode_fit_pump{N,D}.rds` once the 21-parameter run finishes
(log: `refit_20260818.log`). **Do not compare logL, evidence, or any per-stream number
across the two** — the likelihood is a different function and the parameter vector is a
different space (20 vs 21, with `sigma_d13c` out and six coordinates in).
