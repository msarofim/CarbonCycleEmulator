# Handoff — 2026-09-07b. ROUND 2 OF THE HILDA REFIT IS RUNNING ON TORCH: job 17110417, 29 parameters, objective #10 (level + contrasts, shape 4).
# **⛔ NOTHING ADOPTED. Canonical mode still `ent26`; the two mode-file tests fail on purpose until a 29-name mode is promoted.**
# **⇒ NEXT: collect when the array drains (~1–2 h/task in round 1; 46 at %10 ⇒ ~8–10 h), score R1–R8 of `prereg_2026-09-07b_hilda_refit_round2.md`, then Marcus's adoption call.**

**Repo:** `CarbonCycleEmulator/`, `main`, commits `aa545af` (#10 + h_hs + floor), `441b4a4` (targets), + this
handoff. Read first: `notes/prereg_2026-09-07b_hilda_refit_round2.md` (R1–R8), CHANGELOG 2026-09-07b, then
`handoff_2026-09-07_hilda_refit_result.md` for why round 1 was rejected.

## 1. WHAT CHANGED FROM ROUND 1 (Marcus's rulings, 2026-09-07)
1. **Objective #10** replaces the MVN row: three rows on (mean level, A−B, B−deep) with declared sigmas
   (level 10.26 = the deep row's convention; contrasts 2.29 / 4.04 from the bootstrap), each a
   generalised normal with **shape 4** (cost |z|⁴/2: 2σ 8, 3σ 40, 5σ 312). Under it round 1's winner
   scores −321 on the rows, the column −242, the structural basin −24 (leads by 178).
2. **`h_hs` fitted** (29th; box [20, 500]; migrated ancestors start at their own `h_ml`).
3. **Exchange floor 0.02** (round 1 sat at the old floor 0.220).

## 2. HOW TO COLLECT AND JUDGE
```
ssh torch 'sacct -j 17110417 -X --format=JobID,State,ExitCode,Elapsed | tail -50'
rsync -a torch:/scratch/ms17839/CarbonCycleEmulator/calibration/output/multistart_20260907b_hilda29/ calibration/output/multistart_20260907b_hilda29/
CCX_MS_STRUCT=hilda CCX_MS_OUTDIR=calibration/output/multistart_20260907b_hilda29 Rscript calibration/collect_dispersed_multistart.R
```
Then adapt `calibration/diag_hilda28_predictions.R` / `diag_hilda28_basins.R` (they read the round-1 dir
and score R1–R7 of the OLD prereg; round 2 needs R1–R8 of the new one, the pump gradient rows for R4, and
`h_ml`/`h_hs` for R7). Baseline = `ent26` re-scored under #10, stream by stream.

## 3. ⚠ ON THE RECORD
* `kz` bracket NOT re-bisected for the free `h_hs` (bisected at `h_hs` = `h_ml`); R6 is the test.
* The level sigma (10.26) is a DECISION; with shape 4 it binds hard. If the survey finds NO basin inside
  2σ on all three rows, that is a structural statement, not a reason to loosen the sigma post hoc.
* Torch preflight `17110371`-era logs: setup gate rel 3.8e-13; preflight `17110372` 8/8, 0.19–0.24 s/eval.

## 4. NON-OBVIOUS STATE
* Local: nothing running. Torch: job 17110417. Bundle = `aa545af` + targets `441b4a4`.
* `LIK_USE_D14C_PROFILE_MVN` FALSE (kept for diagnostics); `LIK_USE_D14C_PROFILE_GNORM` TRUE, β 4.
