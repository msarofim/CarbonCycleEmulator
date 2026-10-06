# HANDOFF 2026-10-06 — `hilda33p` (objective #16) IS THE CANONICAL. The suite is clean, the app is verified, and nothing is running.

> ⛔ **SUPERSEDED** by `notes/handoff_2026-10-06b_rulings_applied_h2_priced.md` (CHANGELOG 10-06 k). Its open items
> were ruled and applied the same day (10-06 c–j).

**Supersedes** `notes/handoff_2026-10-05e_obj16_landed_cpuclock_merged.md`.
- Written on Marcus's request, verbatim: "Adopt 16, and then write a handoff."
- `main` is at `8b3adc5` plus this note's commit, pushed.

**Start here.**
1. Read CHANGELOG 2026-10-06 (a), then 2026-10-05 (q) and (p), newest at the top of `CHANGELOG.md`.
2. Then these memory files (shared store):
   - `ccx_hilda33p_adopted` (new: the adoption, its ledger and its lessons);
   - `ccx_obj16_landed` (the read);
   - `mac_sleep_eats_wall_budget` (marked FIXED by 10-05 q);
   - `mutation_test_gates` (the hung-mutant blind spot).

## 1. State
- **The canonical is `hilda33p`.**
  - Objective #16, label `hilda_csl3v0kaidgbem`: hilda34g's structure plus the stratification feedback (DESIGN §3.4a S; s 0.0522 /K, q 1, τ_d 195 yr, all FIXED).
  - The greening term `npp_tsens` is PINNED at 0.
  - 33 fitted names, TEN pins.
  - The release "BETA v1.0 CarboTope" is cut on it (`APP_RELEASE_MODE`).
- **hilda34g stays registered** (the #15 canonical). Every test that needs a feedback-OFF mode names it.
- **The full suite at `fb8036a`: 6294 passed, 0 failed, 3 skipped (the standing three), 0 errors.** Log: `outputs/diagnostics/suite_20261006_fb8036a.log`.
- **The app is verified on hilda33p.**
  - The banner reads "33 parameters … 10 further values held".
  - The What-if, Futures, pulse lab, Known issues and constraint-map tabs all render, with no console errors.
  - The `ccx-app` preview is LEFT RUNNING on localhost:7788, from `main`.
- **Multistart budgets** are CPU time on the Mac and wall time on Torch (10-05 q). Nothing else is running.

## 2. Rulings (Marcus, verbatim)
- **10-05 evening:**
  - the CPU-clock decisions: "CPU on Mac, wall on Torch", "Keep 300 CPU-min", "Record and warn", "Warn only, at 2×";
  - then "I'm headed to bed. Take the next obvious steps whenever the running tasks complete."
- **10-06:**
  - "Adopt 16, and then write a handoff.";
  - "hilda33p (Recommended)";
  - "Remove, re-express its test (Recommended)";
  - "Move v1.0 to the new mode (Recommended)";
  - "Approve all (Recommended)": the ledger;
  - "Keep \"about 40 %\" (Recommended)": the What-if ENSO blurb.

## 3. What the adoption changed, in numbers (hilda33p − hilda34g, the same 27 rows)
| quantity | value |
|---|---|
| likelihood | −1.7678 = the feedback −0.9262 + the pin and the refit −0.8417 (`obj16_row_split_20261006.log`) |
| ΔAIC | +1.5 at one fewer fitted name: the record does not discriminate. Adopted on physics |
| CO₂ in 2300, SSP5-8.5 / vvH | +12.9 / +7.8 ppm |
| the land's net climate effect, 2015–24 | +0.118 → −0.038 GtC/yr (GCB −0.8 ± 0.7) |
| the ocean's climate effect, like-for-like | −0.357 → −0.375 GtC/yr (1.80× → 1.87× GCB) |
| gate verdicts | none flip; GATE V −4.60 → −4.39 |
| What-if, ENSO off | 36 % of the wobble removed (the blurb keeps "about 40 %", ruled) |
| pulse box, per 1000 GtC | 1.448 / 1.379 / 1.358 / 1.402 at +20 / 50 / 100 / 200 yr |

## 4. Open items (each is Marcus's to prioritise)
1. **App wording, his text:**
   - (a) **The warming switch's blurb** ("A warmer world respires soil carbon faster and holds less CO₂ in seawater…") does not mention that the switch now also removes the MIXING SLOWDOWN. DESIGN §3.4a S's ready sentence: "warming is strongest at the surface, so the upper ocean becomes more layered and mixes less, and the carbon we add is carried down into the deep ocean more slowly."
   - (b) **The `npp_tsens` row** ("Plant growth's response to warming") shows a bare 0. A note such as "held at 0: the record cannot fix its sign" would be his wording.
2. **The assessment:** does `notes/assessment_2026-10-04_hilda34g_DRAFT.md` become a hilda33p assessment? His verdict sections are placeholders.
3. **Three flags from 10-05 (q), none acted on:**
   - (a) the budget's env name `CCX_MS_BUDGET_MIN` (veto?);
   - (b) the driver's direct-invocation default of 180 against both runners' 300;
   - (c) the end-of-run "eval rate … SIZE THE ARRAY ON THIS" line under-reports ~10×.
4. **Optional:** resume #16's 8 sleep-affected starts (12, 13, 14, 15, 16, 18, 20, 21) from their checkpoints.
   - Today's driver runs them on the CPU clock, and the collector WARNS about the mixed wave, by design.
   - The survey found one basin; the expected value is low.
5. **Carried, unchanged:**
   - H2 (deferred). The ocean's thermal excess is now 1.87× GCB like-for-like.
   - `hs_asx_frac`'s judgement width (kept; `k_w` ≈ 1895 at hilda33p).
   - H1's observed-ratio arm (needs his permission for a gridded SST download).
   - Card 4 wording.
   - The substep held-K rule for `ccx_tr_box_eigbound()` (optional).
   - The unmerged git-stamp branch `claude/youthful-blackburn-fbc009`: merge or retire.
   - `~/.claude/CLAUDE.md`'s pgrep remedy. It is his file; the bracket form is right.
6. **Housekeeping, each needing his OK.** Nothing has been deleted.
   - `~/ccx_frozen/20261005f_obj16`, #16's run tree (landed byte-identical), and its companions `…_launch.{sh,out}`, `…_land.sh`, `…_landchain.{sh,out,pid}` and `…_sleep_addendum.R`. Copies of the chain files are in the landed outdir's `logs/`.
   - `~/ccx_frozen/20261005g_ocgobm`, the 10-05 test tree.
   - Worktrees from 10-05/06:
     - `20261005h_cpuclock` (the merged branch's);
     - `20261005h_cpuclock_old` and `20261005h_cpuclock_smoke` (scratch, port targets copied in);
     - `20261005h_suite_05796b9`, `20261006_suite_0b46208` and `20261006_suite_fb8036a` (suite trees);
     - their launch files, and `20261005h_cpuclock_smoke_logs/` (already copied into the repo).
   - The local branch `claude/ms-cpu-clock`: merged, never pushed, so `git branch -d` is safe.
   - The three `20261004f_kw1446_launch.*` files (carried).

## 5. Non-obvious state
- **A #15 (nine-pin) multistart array is now REFUSED** by `ccx_ms_reference_set()` until its reference set is ruled.
  - The ten pins take the first branch, with the canonical as a MODE.
  - `CCX_MODE_L2_ARM_PINS` is deliberately the canonical's alias.
- **Pin sets are built from their own parts** (`CCX_MODE_OBJ15_PINS`, then `CCX_MODE_OBJ16_PINS`), so a later adoption cannot change an older name's meaning.
- **A test that needs a model WITHOUT the feedback must NAME hilda34g** (`MS_OFF_MODE`, `HF_MODE`, N-E1's fixture). "The canonical" has the feedback now.
- **A suite with expected failures needs `testthat::set_max_fails(Inf)`.** Otherwise `ProgressReporter` quits and reports a fraction as if complete.
- **The Mac runner budgets CPU time.** A sleep no longer spends a start's budget, but nothing runs while the Mac sleeps. Keep it on AC, lid open or in closed-display mode.
- **The landing helper refuses while ANY `run_dispersed_multistart.R` process is alive.**
- **Waiters:** wait on PIDs (`kill -0`), or use `pgrep`'s bracket form.
- **Untracked in the repo, not this session's:** `carbotopecomment*.docx`, `outputs/diagnostics/smoke/`, `outputs/mcmc_smoke/`.
