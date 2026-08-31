# polish_20260831_probe_basin — CONVERGE THE PROBE'S BASIN, UNDER THE SHIPPED BRACKET

**Launched 2026-08-31e from `fd24b86`.** Arm N only. **Adopts nothing on its own** — it produces a
mode file; whether that mode is adopted is a separate call.

## Why this run exists

`diag_probe_basin_vs_incumbent.R` (`fd6d696`) measured that the 08-31 probe's mode is **+51.73
log-units better than the incumbent under the SHIPPED table**, and that the two are **separated by a
21.53-log-unit barrier**. But the probe **hit its restart cap** (`CCX_ARM_RESTARTS=4`,
`CCX_ARM_CYCLES=1`) and its own driver printed *"this mode is NOT converged"*; the BFGS polish then
gained 9.07. ⇒ **−1496.28 is a LOWER BOUND on this basin's depth.** This run converges it with the
DEFAULT budget (20 restarts × 6 cycles) so the basin has a real number attached before anyone commits
to a large dispersed survey.

## The bracket choice, stated

⛔ **NO `CCX_WIDEN_PARAMS`. This runs on the SHIPPED `kz` bracket [3942.5, 6528].**

Rationale: the probe's mode is **strictly interior to the shipped table on all 22 parameters**
(`kz` = 6302.37), and the matched evaluation showed the widening contributes **nothing** to the
+51.73. Running on the shipped bracket therefore costs no fit **and** keeps this run **independent of
open ruling #1** (keep / re-bisect / delete the bracket) — it changes no parameter table, so it does
not have to be re-frozen when #1 is settled.

⚠ Consequence to watch: if `kz` **rails at 6528** here, that is the bracket binding on the NEW basin
and is a fact worth having — it would be the first railing observed in this basin, and it feeds
ruling #1 rather than being blocked by it.

## Provenance

| item | value |
|---|---|
| warm start | byte copy of `probe_20260831_kz_wide_support/from90/mode_fit_pumpN.rds` |
| warm-start md5 | `9c5db687b446318b2078a55f862ec91a` |
| frozen driver | `run_modefind_pump_arms_FROZEN.R`, md5 `2074288a17d2fb54501a2e209acc5192` |
| driver source | identical to tracked `calibration/run_modefind_pump_arms.R` at `fd24b86` |
| budget | driver defaults: `ARM_RESTARTS=20`, `ARM_CYCLES=6`, `ARM_MAXIT=20000` |
| arm | N only (`ARM_MODES = c("N")`, the shipped default) |
| BLAS | pinned to 1 thread ([[pin_blas_threads]]) |

⚠ **`ARM_WARM` READS AND WRITES THE SAME PATH.** This directory's `mode_fit_pumpN.rds` **will be
overwritten** by the run — that is by design. **The original probe file is untouched in its own
directory**; that is the copy to go back to.

⚠ Run from the **FROZEN** copy, never the tracked driver ([[never_edit_a_running_script]]).

## Reproduce

    PD=calibration/output/polish_20260831_probe_basin
    export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1
    CCX_ARM_OUTDIR=$PD/from90 \
      Rscript $PD/run_modefind_pump_arms_FROZEN.R > $PD/from90/_run.log 2>&1

---

## ⚠ FIRST ATTEMPT ABANDONED AT 3 h — REQUEUED WITH A SMALLER RESTART BUDGET

**Log preserved as `from90/_run_ABANDONED_20restarts.log`.** Nothing was written to
`mode_fit_pumpN.rds` (cycle 1 never completed), so the warm start is still the untouched probe copy,
md5 `9c5db687b446318b2078a55f862ec91a` — the requeue starts from exactly the same point.

### What it measured before being stopped

    restart 1: gain 0.2269   10,545 evals   <- converged on reltol, early
    restart 2: gain 0.0059   17,503 evals
    restart 3: gain 0.0023   20,001 evals   <- ran to maxit

⭐ **The gain collapsed geometrically to 0.0023 by restart 3**, so the basin's depth is already
determined to ~0.05 log-units: **−1496.0**, against the probe's **−1496.28**. ⇒ **the +51.73 gap does
not move.** 17 further restarts at ~20,000 evals each were priced at **≈23 h** to buy perhaps another
0.05 — indefensible.

### Two errors in the original ETA, both now corrected

1. ⛔ **I generalised restart length from restart 1 alone.** Its 10,545 evals was the EXCEPTION (it
   started from an already-polished point and converged on `reltol`); restarts 2–3 used 17,503 and
   **20,001** — i.e. maxit. The "halves cycle 1" claim was wrong.
2. ⛔ **CONTENTION, not a slow run** ([[eta_in_days_is_not_a_slow_run]]). Eval rate degraded
   **0.150 → 0.241 s/eval (1.61×)**, tracking the start of **four Julia processes at ~100 % CPU**
   (load 7.03) ~71 min in — another session's work, **left alone**.

### The requeue

`CCX_ARM_RESTARTS=4` (default 20), cycles left at the default 6. Rationale: restarts 1–3 are now
MEASURED to give 0.2269 / 0.0059 / 0.0023, so a 4th is a courtesy margin; what actually remains
unknown is the **cycle-end BFGS polish**, which gained **9.07** in the probe run from an NM-stalled
point and has never run from a polished one. A 4-restart cycle reaches it in ~1/5 the time.

⚠ **`ARM_RESTARTS=4` will print "HIT THE RESTART CAP WHILE STILL GAINING"** — the same string that
disqualified the probe. **Read the CYCLE line, not the restart line:** `ARM_CYCLE_TOL = 0.5` clears
`hit_cap` and prints `CONVERGED` when a whole cycle (restarts + polish) gains less than 0.5. Cycle 1
stood at **0.2351** when stopped, so the verdict turns on what the polish adds.
