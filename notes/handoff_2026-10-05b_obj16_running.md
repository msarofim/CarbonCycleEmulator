# HANDOFF 2026-10-05b — P4 RULED; objective #16's refit is RUNNING on the Mac (launched 09:01); its LANDING is the next session's job

> ⛔ **SUPERSEDED by `notes/handoff_2026-10-05c_obj16_landing_ready.md`.** Its §5 (the landing, dry-run tested) replaces §5
> here, and its §7 replaces §6. §1–§4 and §7 here stay the record of the launch.

**Supersedes** `notes/handoff_2026-10-05_kw_landed_optA_h1.md`. That note remains the record for everything before
the P4 ruling, and its open items 2–7 carry over in §6 below. Written on Marcus's request ("yes, write the handoff").
Self-contained.

**As of 2026-10-05 09:07:** round 1 of 3 is running, with 8 work processes (ids 0–7). No start files yet: a start
file lands when its task finishes.

> ⭐ **STATUS 2026-10-05 11:35 (the next session, CHANGELOG 10-05 g/h/i).** The run is healthy at round 1. After cycle
> 1's polish, ids 1 and 3 both sit at −1187.4518. The landing tools are BUILT; use them in place of §5's hand steps 1–2
> and the step-6 drivers:
> - **Steps 1–2:** `bash ~/ccx_frozen/20261005f_obj16_land.sh`.
>   - It checks the end line, that NO work process is left, and the 24 exit codes.
>   - It copies, `cmp`s every file, and only then writes `RUN_PROVENANCE.txt`.
>   - It refuses to overwrite. It passed 6 mock tests, including 2 corruptions.
> - **Step 5 and part of 6:** `Rscript calibration/diag_obj16_refit_read.R`. It reads on LIKELIHOOD, then the ledger,
>   the moves, the futures at five vectors and the land's net climate effect. Its futures and land sections reproduce
>   the previews exactly.
> - **Step 6, the ocean:** `CCX_OC_MODE="obj16=<mode file>" Rscript calibration/diag_ocean_climate_gobm.R`. Under
>   #16 the ocean reads GMST. The RULED headline holds GMST with a spun-up lag, and the GMST-historical twin is printed
>   beside it (CHANGELOG 10-05 h).
> - **Step 6, the scorecard:** `CCX_SC_EXTRA_MODE="obj16=<mode file>" CCX_SC_TAG_SUFFIX=_obj16 Rscript calibration/diag_whole_model_scorecard.R`.
> - The §6.8 housekeeping is DONE (10-05 g). `youthful-blackburn` was NOT stale: its branch is unmerged and KEPT.

**Start here.**
1. Read this note.
2. Then CHANGELOG 2026-10-05 (f), (e) and (d), newest at the top of `CHANGELOG.md`.
3. Then these memory files (shared store):
   - `ccx_greening_sign_set_by_lag` (the P4 ruling and its cost split);
   - `background_job_dies_with_its_session` (new; read it before trusting any "running" line, including this note's);
   - `ccx_kw_hemispheric_balance` (`k_w` ≈ 1900 is a prior compromise, KEPT by ruling);
   - `ccx_ocean_climate_effect_vs_gcb` (H2, deferred by ruling).

## 1. What was done this session
- **P0 vs P4 explained, then RULED "p4"** (CHANGELOG 10-05 d). `npp_tsens` is pinned at 0 in #16. The explanation's
  new numbers:
  - Cost split: likelihood −0.26; logpost −0.58 = −0.26 − 0.36 (the compensating names' priors; `beta_max` goes
    1.83 → 2.05) + 0.05 (its own prior).
  - Futures: SSP5-8.5 2300 +13.5 ppm, against the stratification feedback's own +5.5.
  - Size: ν's factor is ×1.011 in 2015–24 but ×1.070 at 2300.
  - The MM fertilisation slope falls to 0.21 of today's by 2300.
  - The nine existing pins are all ocean-side; this is the first land pin.
- **A correction to the old handoff's §4.** "P0 masks the ocean; the total looks less wrong than either part" was
  OVERSTATED. In GtC the total's error (0.76) is larger than the ocean's (0.16). The right direction: **the ocean's
  excess hides the land's SIGN.**
- **The 777877b suite had died with the previous session** (file 88 of 112, no summary line). It was re-run under
  `nohup`: **6216 passed / 0 failed / 3 skipped**, which is the old baseline of 6156 plus exactly the 60 new tests.
- **P4 needed ONE code change** (`aa76fb5`; CHANGELOG 10-05 e). (d)'s "no code change" was wrong:
  `ccx_ms_reference_set()` stopped on the ten pins.
  - **Added:** `CCX_MODE_OBJ16_PINS` / `CCX_MODE_OBJ16_STRUCT` (`R/paths.R`) and a branch in `R/calibrate.R`.
    - Incumbent: the canonical, seeded at the pin. New basin: the control.
    - Ruled ONLY under `hilda_csl3v0kaidgbem` at seas_ml 1.
    - Its `why` names OBJECTIVE #16, not a price arm.
  - **Tested:** test (11) in `test-ms-reference-set.R` adds 18 expectations; the file is 93 / 0. Mutations M1–M5 are
    each caught.
  - **Abandoned:** a by-value match, built on my false premise that `ccx_pin_label()` prints 2 decimals. It is
    `format()`-adaptive. Its own mutation passed all 93, which exposed the premise.
- **The suite at `aa76fb5`:** **6234 / 0 / 0 / 3 skipped**, rc 0 (6216 + test 11's 18).
- **#16 LAUNCHED** (CHANGELOG 10-05 f), after the checks below.
  - **Port targets** were regenerated in the launch tree.
  - **The incumbent's offset (−66.46) was decomposed independently:**
    - the greening pin alone −53.93, against the Hessian's −54.14;
    - the feedback −1.77;
    - their interaction −8.19;
    - the removed prior density −2.57.
    - A seeding that ignored the pin would read −1187.3.
  - **Preflight:** 24/24 LAUNCHABLE, every port verified (rel ≤ 3.9e-14).

## 2. Rulings (Marcus, verbatim, this session)
- **"p4"**: P0 vs P4 → P4, `npp_tsens` pinned at 0 in objective #16.
- **"Mac, today (Recommended)"**: the #16 refit on the Mac today, 8 at once, the 10-04 (g) recipe.
  - The Torch verdict, said out loud: **Mac**. The 08-20 probe measured the Mac ~2× faster per evaluation, and it is
    like-for-like with the hilda34g and `k_w` refits. Torch would need a fresh bundle, a port gate, his login, and
    about double the wall.
- **"Neither: launch as ruled (Recommended)"**:
  - `hs_asx_frac`'s width is KEPT, so `k_w` ≈ 1900 stays a disclosed prior compromise;
  - H2 is DEFERRED.
- **"yes, write the handoff"**: this note.
- Standing, from earlier:
  - 10-05: "1) Yes, test. 2) give me pros and cons. 3) Keep. 4) Option A." The label `hilda_csl3v0kaidgbem` is KEPT.
  - 10-04: the mixing rulings ("Thermocline mixing only", "Obs × law, fixed", "GMST minus lagged deep ocean",
    "History + futures, one #16 refit"); "No row; draft card-4 text"; "Canonical incumbent, Mac".

## 3. Files touched (all committed and pushed: `d388cbd`, `aa76fb5`, `eba06c7`, and this note's commit)
- **Code:**
  - `R/paths.R` (`CCX_MODE_OBJ16_PINS`, `CCX_MODE_OBJ16_STRUCT`);
  - `R/calibrate.R` (`ccx_ms_reference_set()`'s #16 branch, its docstring, the stop message).
- **Tests:** `tests/testthat/test-ms-reference-set.R` (test 11).
- **Spec:** `DESIGN.md`'s greening bullet ("PINNED AT 0 from objective #16").
- **Notes:**
  - `notes/proposal_2026-10-04_npp_tsens_prior.md` (a RULED header);
  - `notes/handoff_2026-10-05_kw_landed_optA_h1.md` (status lines in §1, §4 and §5);
  - this handoff.
- **Outputs:**
  - `outputs/diagnostics/suite_20261005_777877b.log` (the dead partial, KEPT as evidence);
  - `…_777877b_rerun.log`;
  - `…_aa76fb5.log`.
- **Outside the repo** (not committed):
  - the launch tree `~/ccx_frozen/20261005f_obj16`: a git worktree at `aa76fb5` + a `nuclear14c` copy;
    `calibration/torch/port_targets.csv` regenerated there; `logs/port_targets_20261005f.log`;
    `logs/preflight_20261005f/`;
  - `~/ccx_frozen/20261005f_obj16_launch.{sh,out,pid}`;
  - the two suite trees `~/ccx_frozen/20261005_suite_777877b` and `~/ccx_frozen/20261005_suite_aa76fb5` (both git
    worktrees, downloads symlinked), each with its `_launch.{sh,out,pid}`.
- **Scratch, gone with this session:** the four-way incumbent decomposition script. Its numbers are in CHANGELOG
  10-05 (f).
- **Memory:**
  - `ccx_greening_sign_set_by_lag` (a RULED P4 section + its description);
  - `INDEX_ccx_phi.md` (the pointer);
  - new: `background_job_dies_with_its_session`, pointed to from `INDEX_infra.md` under a new "Local jobs (the Mac)"
    section;
  - `mutation_test_gates` (the surviving-mutation-exposes-a-false-premise instance).

## 4. The run in flight
- **What it is:**
  - Objective #16: the label `hilda_csl3v0kaidgbem`. The stratification feedback is ON and FIXED (s 0.052198 /K,
    q 1, τ_d 194.94 yr).
  - seas_ml 1; pump field solved.
  - Pins: the canonical's 9 + `npp_tsens=0`, leaving **33 free** (`k_w` among them).
  - The H1 switch `hs_sst_anom_frac` is absent, which is 1, bit-exact.
- **The design:**
  - 24 dispersed starts, seeds `2026 + id`, spread 1.0452, 8 at once.
  - WALL 300 min, 3 restarts × 6 cycles × 6000 maxit, and option A's in-restart deadline.
  - Id 0 is the cold start. Id 1 is the incumbent: hilda34g seeded at `npp_tsens` 0, a START. Id 2 is the new
    basin, `hilda31pe`. Ids 3+ are dispersed or seeded.
- **Port targets** (in the tree):

| point | logpost |
|---|---|
| cold | −60581.58 |
| incumbent | −1249.45 |
| new basin | −11908.92 |

- **Where it is:**
  - Tree: `~/ccx_frozen/20261005f_obj16` at `aa76fb5`.
  - Outdir (in the tree): `calibration/output/multistart_20261005f_hilda_csl3v0kaidgbem_seasml1_pin_ent_seas_amp_SH=0_w_eq=27_gamma_eq=1_pump_export=9.08_w_vent=0_gamma_vent=0_w_thc=0_gamma_enso_ocn_NH=0_gamma_enso_ocn_SH=0_npp_tsens=0_sd1.0452`.
- **When it ends:** it launched 2026-10-05 09:01:19. Three rounds of ≤ 5 h put the expected end at ~23:00–00:30
  (the `k_w` arm took 13.7 h at the same rate, 0.34 s/eval).
- **How to check it:**
  - `cat ~/ccx_frozen/20261005f_obj16_launch.out` shows the start line, then an "end … rc N" line when the chain
    finishes.
  - The tree's `logs/wave_20261005f.log` ends with every task's exit code. `logs/ccx_multistart_mac_20261005f_exit.txt`
    holds them; `logs/ccx_multistart_mac_20261005f_<id>.out` is each task's log.
  - ⛔ **Confirm the WORK processes, not the launcher:** `pgrep -f run_dispersed_multistart | wc -l` gives 8 while a
    round runs. A log that has stopped growing with no end line is a dead job ⇒ `background_job_dies_with_its_session`.
- **It is under `nohup`,** so it survives the session ending.
  - Keep the Mac on AC power: `caffeinate -s` holds off sleep only while it is plugged in.
  - To STOP it, kill the work processes (and the runner's `xargs`), not only the launcher PID. Killing the launcher's
    bash alone would most likely orphan the R tasks rather than stop them. That is an inference, not tested.

## 5. The landing, in order (the next session's job)
1. **Confirm it finished.**
   - `…_launch.out` has "end … rc 0".
   - `exit.txt` has 24 lines.
   - Count the non-zero exits.
   - Note how many starts ran out of time (the `k_w` arm had 6).
2. **Copy the outdir into the repo's `calibration/output/`.**
   - `cmp` every start file, the task logs, the exit file, the preflight folder, the launch script and the port-target
     CSV, as for the `k_w` arm.
   - Write a `RUN_PROVENANCE.txt`. The template is `calibration/output/multistart_20261004f_…/RUN_PROVENANCE.txt`:
     FROZEN_FROM_COMMIT `aa76fb5`, the tree, inputs 14/14, port targets, Mac 8-parallel, WALL / restarts / cycles /
     maxit, label, seas_ml, spread, PINS, the launched and finished times, rc, how the copy was verified, and the
     CHANGELOG pointers 10-05 (e)/(f).
3. **Collect:** `CCX_MS_OUTDIR=<the repo outdir> Rscript calibration/collect_dispersed_multistart.R`, saving
   `collect_<date>.log` in the outdir. Read the basins and the convergence counts.
4. **Promote:**
   ```
   Rscript calibration/promote_multistart_mode.R --name=obj16_hilda_csl3v0kaidgbem --outdir=<repo outdir> --dest=calibration/output/refit_<date>_obj16_hilda_csl3v0kaidgbem
   ```
   - The promote script derives the best id itself (GATE 3), and GATES 1–5 must pass.
   - Then run `Rscript calibration/recompute_hessian.R <mode file> --update`.
   - ⚠ **A NEW label is being promoted with a READ name pinned.** Check every registry step rather than assume it:
     the promote's gates, `ccx_mode_pins()`, the mode-struct lint, and `CCX_MODE_FILES` if it is registered.
   - Registering a mode is a separate act from ADOPTING it.
5. **Read it on LIKELIHOOD,** against hilda34g's −1143.2508 on the 27 rows. The pin removes `npp_tsens`'s prior
   density (2.57 at hilda34g), so the logposts are NOT comparable.
   - The previews to set it against: P4 −0.26 (a conditional slice); the feedback −1.77 (unrefitted).
   - A refit can only recover from those, so I expect #16 within a few units of hilda34g. That is my expectation from
     the previews, not a measurement.
6. **Read the consequences:**
   - SSP5-8.5 and vvH 2300. The previews were P4 +13.5 and the feedback +5.5, each conditional or unrefitted.
   - The land's net climate effect (TRENDY definition; the P4 preview gave −0.04, against GCB's −0.8 ± 0.7).
   - The ocean's climate effect, like-for-like (`calibration/diag_ocean_climate_gobm.R`; the canonical's −0.357).
   - Where `beta_max` lands (the P4 slice gave 2.05) and where `k_w` lands (the canonical's ~1903).
   - The whole-model scorecard.
7. **Adoption is Marcus's call.** If adopted:
   - `CCX_MODE_CANONICAL` becomes the new mode, and `CCX_MODE_CANONICAL_PINS` becomes the ten. #16's reference-set
     branch then duplicates branch 1; keep or remove it by ruling.
   - Restart the app preview (`ccx-app`, localhost:7788; it still runs a pre-stratification tree).
   - The app's `npp_tsens` row (`app/R/params_meta.R:122`) will show a pinned 0. The greening wording on the cards
     is Marcus's to write.

## 6. Open items carried over (each is Marcus's to prioritise)
1. **#16's landing** (§5).
2. **H2, the ocean thermal excess in the low-latitude column.** DEFERRED by ruling. The candidates:
   - a time-shape comparison against GCB Fig. S10 per protocol (cheap; no model change);
   - a refit at a lower kz (expensive);
   - a structural surface-DIC damping in Bunsen 2024's spirit (a proposal).
3. **`hs_asx_frac`'s judgement width** (KEPT): `k_w` ≈ 1900 is a prior compromise, to be disclosed. Widening it needs
   a proposal with a cited width and a plan for the `h_hs` bracket, since `h_hs` reached 472.6 of its 500 m in the
   `k_w` arm.
4. **H1's observed-ratio arm.** It needs a gridded SST download (HadSST4 or HadISST1), which needs his permission.
5. **Card 4 wording** (`notes/draft_2026-10-04_card4_enso_timing.md`): his text.
6. **The hilda34g assessment's verdict** (`notes/assessment_2026-10-04_hilda34g_DRAFT.md` §5, §7). If #16 is
   adopted, ask whether it becomes a #16 assessment.
7. **Optional, needs a ruling:** extend the substep fix's held-K rule to `ccx_tr_box_eigbound()`.
8. **Housekeeping, each needing his OK:**
   - delete `~/ccx_frozen/20261004f_kw1446` (its outputs are in the repo, byte-identical);
   - remove the two suite worktrees from this session, `~/ccx_frozen/20261005_suite_777877b` and `…_aa76fb5`
     (`git worktree remove`; their logs are committed);
   - delete the remote branch `claude/pensive-burnell-a9bf40`;
   - remove the two old `.claude/worktrees/` (`compassionate-leavitt-a7e631`, `youthful-blackburn-fbc009`).
   - ⛔ **Never** delete `~/ccx_frozen/20261005f_obj16` before its outdir is in the repo, byte-identical.
   - ✅ **DONE 2026-10-05 (g)**, all four on Marcus's OK, each target verified first (CHANGELOG 10-05 g).
     ⚠ **`youthful-blackburn` was NOT stale.** Its branch holds the UNMERGED `ccx_git_stamp()` refactor
     (CHANGELOG 10-01 h). Its session was ARCHIVED and the branch KEPT, local and origin at `6c87138`.

## 7. Non-obvious state
- **The pin bookkeeping:**
  - The #16 branch is ruled ONLY under `hilda_csl3v0kaidgbem` at seas_ml 1.
  - The canonical's own nine pins under #16's label still take branch 1. That is P0's set, and nothing about it
    changed.
  - `ccx_pin_label()` is `format()`-adaptive: it chooses decimals for the whole vector, so 0.004 prints "0.004". Do not
    repeat my "2 decimals" premise.
- **Two records say "no code change":** CHANGELOG 10-05 (d) and commit `d388cbd`. (e) corrects it; the pushed commit
  message cannot be changed.
- **Comparing arms:** across pinned or price arms, compare on LIKELIHOOD, never on stored logposts.
- **`CCX_OC_HS_FRAC`** on the like-for-like ocean driver tags its outputs `_hsfrac<f>`. R0's identity gate applies
  only at f = 1; unset is the shipped model.
- **The CO₂-prescription technique** (`match_co2()` in `diag_ocean_climate_gobm.R`), reusable:
  - an output row is the START-of-month state, so lead by one row;
  - the NH−SH difference needs a SUSTAINED flux kh (dG/dt + 2G/`tau_ex`).
- **Carried:**
  - the coupled futures hold the 1850 GMST (−0.052 K) back to 1750 (pre-existing, noted);
  - MAGICC is restricted (cite M11);
  - a frozen tree from before `92b5756` has the old multistart overrun behaviour (not #16's: `aa76fb5` includes
    option A);
  - the multi-line-shell lesson: stage, check `git diff --cached --stat`, then commit, as separate steps.
- **Untracked in the repo, and not this session's:** `carbotopecomment.9.26.26.docx`, `carbotopecomments.10.2.26.docx`,
  `outputs/diagnostics/smoke/`, `outputs/mcmc_smoke/`. Left alone.
