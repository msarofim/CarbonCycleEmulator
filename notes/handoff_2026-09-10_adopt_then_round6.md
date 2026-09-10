# Handoff — 2026-09-10. **THE REFIT LANDED AND IS PROMOTED (−1480.5404, +9.0880 over `hilda31`). ⛔ IT RAN AT `seas_ml = 0`, SO IT IS A NEW BASELINE AND *NOT* THE ROUND-6 TEST. FOUR STEPS OWED, IN THIS ORDER: HESSIAN → REPOINT → `seas_ml` CAPABILITY → THE ROUND-6 REFIT.**

> ⚠ This header states what is DONE. For live state read `CHANGELOG.md` **2026-09-10 (5)** back to
> **(1)**, and `INDEX_ccx_seas_ml.md` ⇒ [[status_field_carries_the_query]].

Read first: **CHANGELOG 2026-09-10 (5)** — the promotion, the `seas_ml` finding and Ruling A, each
with its derivation. Memory: [[ccx_refit_ran_at_seas_ml_0]], [[ruling_a_repricing_was_a_stale_mode]],
[[ccx_periodic_adoption_priced]], [[torch_cpu_short_spans_gpu_nodes]].

---

## 0. THE FOUR STEPS, IN DEPENDENCY ORDER
**Do them in this order.** Each one is safe only after the one before it.

1. **HESSIAN** on the new mode file, so the file is COMPLETE before it becomes canonical.
2. **REPOINT** `CCX_MODE_CANONICAL` — ⛔ **quarantine `hilda31` FIRST or a test fails for a
   misleading reason** (§3).
3. **`seas_ml` CAPABILITY** in the driver + sbatch — it does not exist today (§4).
4. **THE ROUND-6 REFIT** at `seas_ml = 1`, which is what P2 and P12 were always waiting for (§5).

⚠ **1–3 are all cheap and local. Only 4 costs HPC time.**

## 1. STATE OF THE TREE
- **`CarbonCycleEmulator/main`, clean, no remote.** The refit arc: `50f0105` (adopt the periodic
  spinup) → `02c9f87` (port targets) → `79d9245` (four red tests + `CCX_OBJECTIVE_SPINUP`) →
  `54621ca`/`e03f6a4` (the GPU-node requeue) → `27cff96` (round 2) → the promotion commit.
- ✅ **NEW MODE PROMOTED** to `calibration/output/refit_20260910_hilda31_periodic/mode_fit_pumpN.rds`
  — **logpost −1480.540424**, 31 par, `struct = "hilda"`, `seas_ml = 0`.
  GATE 3 DERIVED the start (id 6); GATE 4 reproduced to **−8.3e−08**; **GATE 5 PASSED**
  (streams −1441.701546, recomputed prior −38.838878, gap **−1.2e−09**). ⚠ **GATE 5 only passes
  because `promote_multistart_mode.R:153` was repointed to `CCX_OBJECTIVE_SPINUP` on 09-10** — before
  that it would have failed here, *after* both rounds had run.
- ⛔ **`CCX_MODE_CANONICAL` is STILL `hilda31`.** Nothing resolves to the new mode yet.
- ⚠ **The new mode dir contains ONLY `mode_fit_pumpN.rds`** — no `_run.log`, no
  `pump_arms_comparison.rds`, because it came from the MULTISTART promoter rather than
  `run_modefind_pump_arms.R`. §3 depends on this.
- ✅ Suite was **2443 / 2 fail / 1 error / 4 skip** at the last full run (the 2+1 are the
  long-standing pre-existing set).

## 2. STEP 1 — THE HESSIAN
```
CCX_MS_STRUCT=hilda Rscript calibration/recompute_hessian.R \
  calibration/output/refit_20260910_hilda31_periodic/mode_fit_pumpN.rds --update
```
`promote_multistart_mode.R` prints this itself as the next step. **Without `--update` it computes and
does not write** (`recompute_hessian.R:302-304`), and the gates run either way — so a dry run first is
free. The new file has **`prior_z` but NO `hessian`/`cov`/`sd_unc`**; this fills that block.
⚠ **Do it BEFORE the repoint**, so the file is complete at the moment it becomes canonical rather
than briefly canonical-and-incomplete.
⚠ Its GATE 1 is the same 1e−5 "does this point reproduce" tolerance `promote_multistart_mode.R` used
(`PMM_LP_TOL`), deliberately not tighter.

## 3. STEP 2 — THE REPOINT, AND THE TRAP IN IT
⛔⛔ **`tests/testthat/test-mode-file.R:187` WILL FAIL ON A NAIVE REPOINT, FOR A MISLEADING REASON.**
```r
expect_equal(CCX_MODE_CANONICAL, free[which.max(lp[free])])
```
It picks the FREE arm with the **largest STORED logpost**. The stored values are:

| mode | stored logpost | objective it was fitted under |
|---|---|---|
| `hilda31` | **−1478.659503** | pre-09-09w priors, ASEASONAL spinup |
| **new** | **−1480.540424** | 09-09w priors, PERIODIC spinup |

**−1478.66 > −1480.54**, so with both registered `which.max` returns **`hilda31`** and the assertion
fails — even though the new mode is **+9.0880 better on the objective they would both be scored
under today**. ⚠⚠ **DO NOT "FIX" THIS BY SWAPPING THE EXPECTATION.** The two numbers are from
DIFFERENT OBJECTIVES and are not comparable at all ⇒ [[compare_gaps_not_absolute_logposts]].
**The correct move is the documented one: QUARANTINE `hilda31` so it leaves `CCX_MODE_FILES`**, at
which point `which.max` has only the new arm to choose and the assertion is true again.

⭐ **AND THE TEST'S OWN COMMENT CONTRADICTS ITS ASSERTION** — worth reporting as its own finding:
lines 175-179 say *"what is asserted is that the canonical mode is FREE — never that its stored number
is the largest"*, and line 187 asserts precisely that its stored number is the largest. One of the two
is wrong. **Raise it; do not silently pick a side.**

**The mechanics** (`R/paths.R`): `CCX_MODE_CANONICAL` at **:46**, `CCX_MODE_FILES` at **:48**,
`CCX_MODE_PINNED` at **:79** (`c(hilda31 = FALSE)`), `CCX_MODE_RETIRED` at **:94** — each retired
entry carries **its own cause and its own quarantine path**, which is the format to follow.

⭐ **THERE IS A SCRIPT FOR ALL OF THIS: `calibration/run_post_refit_adoption.R`**, stages
`check → read → quarantine → repoint → rerun`, and its header explains why that order is the only
safe one (a quarantine before a replacement exists breaks `ccx_mode_file()` and the app; a repoint
without the quarantine leaves a live pre-adoption vector resolvable by name).
⚠ **BUT IT IS HARDCODED TO THE 08-28 ARC** — `PRA_NEW_NAME "sigeff"`, `PRA_OLD_NAME "from90"`,
`PRA_QUAR_TAG "20260828_sigma_inflation_adopted"`, at **lines 43-61**. All constants are at the top
(the file obeys the "labels derive from named constants" rule), so retargeting is contained —
**but it also expects `pump_arms_comparison.rds` and `_run.log` (`PRA_NEW_CMP`, `PRA_NEW_LOG`), which
the MULTISTART promoter does not produce.** Retarget AND reconcile those two, or run the stages by
hand. ⛔ It was NOT used for the 09-08f `hilda31` adoption, so assume drift and read it before trusting it.

**Suggested new name:** `hilda31p` or `hilda31_periodic`; the dir is already
`refit_20260910_hilda31_periodic`. **Quarantine tag:** `20260910_periodic_spinup_adopted`, and the
README should name the CAUSE as the spinup adoption (`50f0105`), not a bug — `hilda31` is superseded,
not defective.
⚠ **24 files name `hilda31` literally** (`grep -rln hilda31 --include=*.R R/ calibration/ tests/`).
Most resolve through `ccx_mode_file()` and follow automatically; the literals are mostly in diagnostic
FILENAMES and comments. Sweep them, but do not mass-rename diagnostics whose subject really is the old
mode (`diag_adoption_read_hilda31.R`, `diag_hilda31_predictions.R`).

## 4. STEP 3 — THE `seas_ml` CAPABILITY, WHICH DOES NOT EXIST
⛔⛔ **THIS IS WHY THE REFIT WAS NOT A ROUND-6 TEST.** `ccx_default_params()$seas_ml` is **0**,
**`seas_ml` is NOT in `CCX_PARAM_NAMES`**, and `run_dispersed_multistart.R:312` builds
`bp <- ccx_default_params(); bp$pump_mode <- MS_ARM` with **no override** — then
`:315 bp <- ccx_apply_structure(bp)`. **Neither the driver nor `multistart.sbatch` has any `seas_ml`
handling at all.** Nobody specified it and the default carried, silently.

**The pattern to mirror is `CCX_MS_STRUCT`**, which reaches the model the same way: an env var read
inside `ccx_apply_structure()` (`R/calibrate.R`), recorded into the output, and **hard-validated by
the port gate at `run_dispersed_multistart.R:546`**. Do all three for `seas_ml`:
1. **Read it** — e.g. `CCX_MS_SEAS_ML`, applied to `bp` right beside `:315`.
2. **RECORD it** in the start files and in `port_targets.csv`, exactly as `struct` is.
3. **GATE it** — the port gate must refuse a run whose targets were measured at a different
   `seas_ml`, or this same silent-default failure recurs with a better disguise
   ⇒ [[default_off_hides_the_bug]], [[two_gates_one_mechanism]].
⚠ **`make_port_targets.R` must then be re-run at `seas_ml = 1`** — it reads the same env vars, and its
existing footgun is that an unset variable silently yields the WRONG arm
⇒ [[port_targets_need_the_struct_var]].
⚠ **And the OUTDIR must name it** (`..._periodic_seasml1`): the 09-02 rule is that the directory names
the OBJECTIVE, and `seas_ml` changes the objective at a CONSTANT 31 names — the `param_names`
checkpoint guard cannot tell them apart; only `ref_logpost` can.

## 5. STEP 4 — THE ROUND-6 REFIT
Only after §4. **31 par, `ent_seas_amp_SH` KEPT, MAP as usual** (ruled 09-09x — "likelihood-only"
meant COMPARE on likelihood), under the ADOPTED periodic spinup, **at `seas_ml = 1`**.
**What it is for, and neither is answered today:**
- **P2** — does the NH strain relax? `sst_seas_amp_NH` is at **z −2.89** with the mechanism OFF.
- **P12** — does `ent_seas_amp_SH` retire? It fell only **21.038 → 18.695** (z +2.10, still **2.85×**
  its corrected centre 6.5525) with its intended substitute switched off.

**Torch, and it is all measured** ⇒ [[torch_cpu_short_spans_gpu_nodes]]:
`--partition=cs` (NOT `cpu_short`, which spans 74 GPU nodes where this job gets 13–18 % of a core;
`--exclude` is REFUSED by the cluster). `--time=06:00:00`, `CCX_MS_WALL_MIN=300`, `%24`.
⚠ **`cs` has `QoS=N/A`** so those are CHOICES, not ceilings — re-derive if you change them.
**Round 1** `--array=0-23%24`, then **round 2 = the fixed ids + round 1's best dispersed**, resumed
from checkpoints — that is what took convergence from **2 of 24 to 14 of 14**.
**Sizing, measured:** ~0.70 s/eval on `cs`, ~70 min per 6000-eval pass, ~3.6 passes in budget.

## 6. NON-OBVIOUS STATE
- ✅ **RULING A IS RESOLVED — no option is live.** The demean flag: **43.8367** at `hilda31`/aseasonal
  (what it was ratified on), **63.7282** at `hilda31`/adopted, **45.1896** at the mode REFITTED under
  the adopted objective. **The 63.73 was a STALE-MODE artifact**; ratification is not threatened
  ⇒ [[ruling_a_repricing_was_a_stale_mode]]. The open question in `test-enso-demean.R` was closed in
  the same edit.
- ⭐ **94 % OF THE REFIT'S GAIN IS ONE AXIS**: `d13c_level_SPO` **+15.548** against `d13c_level_MLO`
  **−8.127**, no other stream past **0.74** — the mirror image of what adoption cost at `hilda31`
  (SPO −16.73, MLO +8.28). ⇒ **the periodic spinup and the interhemispheric δ¹³C split are the SAME
  axis.** That deserves its own test, not a footnote.
- ⚠ **SIX PRIORS BEYOND 2σ at the new mode**: `rep_dC` **+3.15** (the worst in the model, and it barely
  moved), `sst_seas_amp_NH` −2.89, `kz_deep_frac` −2.46, `pump_hs_gcm2` **+2.39 (WORSE)**, `q10`
  **−2.24 (WORSE)**, `ent_seas_amp_SH` +2.10.
- ⚠ **Every stored `logpost`/`prior_z` from before 09-09x is non-comparable** — the prior shift
  (−0.811) and then the spinup adoption both moved the objective. **Compare on the likelihood, or
  re-score the vector.**
- ⚠ **`ccx_make_logpost()` now takes `spinup_fn` and `by_stream`.** `CCX_OBJECTIVE_SPINUP` is the ONE
  name for "the spinup the objective uses" — every hand-built reconstruction must read it, which is
  what broke four tests on 09-09x.
- ⚠ **The login node's `/tmp` is a 2 GB tmpfs and was 100 % full.** Use `/scratch`.
- ⚠ **Root `MEMORY.md` is at 18,197 B of an 18,432 hard ceiling** — a restructure is owed and is
  Marcus's call about what stays. `INDEX_ccx_seas_ml.md` was SPLIT on 09-09x and is healthy (9.0 KB).

## 7. ⛔ WHAT I WOULD NOT DO
- **Do not repoint before quarantining `hilda31`**, and **do not repair `test-mode-file.R:187` by
  swapping the expected value** — the two stored logposts are from different objectives.
- **Do not run the round-6 refit before §4.** Without the capability it silently repeats this run.
- **Do not read this refit as a round-6 result.** P2 and P12 are untouched.
- **Do not trust `run_post_refit_adoption.R` unread** — it is hardcoded to the 08-28 arc and expects
  two files the multistart promoter never writes.
- **Do not submit to `cpu_short`.** Use `cs`.
- **Do not re-run the suite for counts without `stop_on_failure = FALSE`**, and do not read `failed`
  without `error` — they are separate columns.
