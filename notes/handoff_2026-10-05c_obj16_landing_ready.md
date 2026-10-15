# HANDOFF 2026-10-05c — #16's LANDING CHAIN is BUILT and DRY-RUN TESTED; the refit is still RUNNING; this session will land it tonight if it stays open

> ⛔ **SUPERSEDED by `notes/handoff_2026-10-05d_obj16_cpu_budget.md`.** It reproduces §5 here as its §4 and adds the CPU-time budget
> build (its §5). This note stays the record of the landing tools and the dry run.

**Supersedes** `notes/handoff_2026-10-05b_obj16_running.md`.
- That note's §1–§4 and §7 remain the record of the launch.
- §5 here REPLACES its §5 (the landing), and §7 here replaces its §6 (the open items).
- Written on Marcus's ruling "Handoff now, then land tonight (Recommended)". Self-contained.

**As of 2026-10-05 12:56:**
- 5 of 24 starts have finished, every one CONVERGED in time at logpost **−1187.4518**, agreeing to 5e-6. They are:
  - the incumbent (id 1);
  - the NEW BASIN (id 2, from −11908.92);
  - the three seeded starts (ids 3–5).
- 8 work processes are running (ids 0, 6, 7 and 8–12), and 11 are queued.
- The expected end is ~23:00–01:00. The rate is ~0.40 s/eval, ~15 % slower than the preflight, under desktop load (Firefox's GPU helper at ~1.1 cores).

**Start here.**
1. Read this note.
2. Then CHANGELOG 2026-10-05 (j), (i), (h) and (g), newest at the top.
3. Then these memory files (shared store):
   - `handoff_stale_label_is_a_claim` (new);
   - `ccx_ocean_climate_effect_vs_gcb` (its new #16 section);
   - `background_job_dies_with_its_session`;
   - `ccx_greening_sign_set_by_lag`.

## 1. What was done this session (CHANGELOG 10-05 g–j)
- **Pickup.** The run was confirmed: 8 WORK processes at ~84 % CPU, and the launcher re-parented to launchd.
- **Housekeeping: all four of 10-05b's §6.8 items, on Marcus's OK.** Each target was verified before it was touched.
  - Removed the `k_w` frozen tree, after matching every file in it against the repo.
  - Removed the two suite worktrees, after unlinking their download symlinks first. The repo's downloads were unchanged.
  - Deleted the merged remote `pensive-burnell`.
  - ⚠ **`youthful-blackburn` was NOT stale.** It is the UNMERGED `ccx_git_stamp()` refactor. Both `.claude/worktrees` sessions were ARCHIVED, and both branches were kept.
- **The ocean diagnostic can read #16** (`f35ca59`; ruled "Held + spun-up lag, both shown").
  - Under #16 the ocean reads GMST. The headline holds GMST in C, with T_deep spun up at each spec's mean GMST. The GMST-historical twin is printed beside it.
  - The default path is BIT-IDENTICAL to the committed 10-04 output.
  - CHECK 0 gained a GMST mutation.
  - My prediction that CHECK 0 would be blind was WRONG: it fails 11× without GMST held.
- **The read script `calibration/diag_obj16_refit_read.R`** (`af7cb36`). It covers reproduction, the likelihood row by row, a ledger that must close, the moves, the futures at five vectors, and the land's net climate effect. Its futures and land sections reproduce the previews exactly.
- **The landing helper `~/ccx_frozen/20261005f_obj16_land.sh`.** It verifies, copies, `cmp`s and writes the provenance. It passed 6 mock tests, including 2 corruptions.
- **The DRY RUN** (`886bcfd`). Collect → promote → Hessian → read → ocean → scorecard, all rc 0 on id 1, in the frozen tree `~/ccx_frozen/20261005g_ocgobm`. The "new label with a READ name pinned" registry check is DISCHARGED.

## 2. Rulings (Marcus, verbatim, this session)
- "Landing prep only (Recommended)": the scope of the wait.
- "Delete k_w frozen tree, Remove 2 suite worktrees, Delete remote pensive-burnell, Remove compassionate-leavitt".
- "Remove worktree, keep branch (Recommended)" (`youthful-blackburn`), then "Archive both sessions (Recommended)".
- "Held + spun-up lag, both shown (Recommended)": #16's like-for-like ocean GMST rule.
- "Handoff now, then land tonight (Recommended)": this note.

## 3. Files touched
- **Code:**
  - `calibration/diag_ocean_climate_gobm.R` (`f35ca59`);
  - `calibration/diag_obj16_refit_read.R` (new, `af7cb36`).
- **Notes:**
  - `notes/handoff_2026-10-05b_obj16_running.md` (a status block; §6.8 marked DONE);
  - this note.
- **CHANGELOG:** 10-05 (g), (h), (i) and (j).
- **Outside the repo** (not committed):
  - `~/ccx_frozen/20261005f_obj16_land.sh`, the landing helper.
  - `~/ccx_frozen/20261005g_ocgobm`, my TEST worktree (a git worktree, now at `f35ca59`). Its scratch: `calibration/output/SCRATCH_obj16like_NOT_A_FIT/` (hilda34g relabeled, NOT a fit), `DRYRUN_wave/`, `DRYRUN_refit_obj16/`, `DRYRUN_logs/`, and `outputs/diagnostics/*_DRYRUN*`, `*_obj16dry*`, `*_obj16like*`.
- **Memory:**
  - `handoff_stale_label_is_a_claim` (new, with an `INDEX_conv` pointer);
  - `ccx_ocean_climate_effect_vs_gcb` (the #16 section and its description).
- **Removed:**
  - `~/ccx_frozen/{20261004f_kw1446, 20261005_suite_777877b, 20261005_suite_aa76fb5}`;
  - `origin/claude/pensive-burnell-a9bf40`.
  - The two `.claude/worktrees` sessions were archived; the app pooled their folders.

## 4. The run in flight
- As 10-05b §4: the tree `~/ccx_frozen/20261005f_obj16` at `aa76fb5`, launched 09:01:19, under `nohup`.
- **Chain status:** `cat ~/ccx_frozen/20261005f_obj16_launch.out`. It gets an "objective #16 end … rc N" line at the end.
- **Exit codes:** `logs/ccx_multistart_mac_20261005f_exit.txt` in the tree, one "id rc" line per finished task.
- ⛔ **Confirm the WORK processes, not the launcher:** `pgrep -f 'R.*--file=calibration/run_dispersed_multistart.R' | wc -l`.
- ⛔ **Never** delete `~/ccx_frozen/20261005f_obj16` before its outdir is in the repo, byte-identical (step 1 below proves it).

## 5. THE LANDING, every step dry-run tested (replaces 10-05b §5)
Run from the repo root. The refit will have ended, so the Mac is free. ⚠ Do not edit any of these scripts while one of
them runs.

1. **Confirm, copy, verify, record:**
   ```
   bash ~/ccx_frozen/20261005f_obj16_land.sh
   ```
   - It REFUSES unless the end line exists, NO work process is left, and there are 24 exit codes.
   - It copies the outdir, the logs, the preflight folder, `launch.{sh,out}` and the port targets, then `cmp`s every
     file.
   - Only after that does it write `RUN_PROVENANCE.txt`.
   - It never overwrites, and it prints the outdir path ⇒ call it `<OUT>` below.
2. **Collect:**
   ```
   CCX_MS_OUTDIR="<OUT>" Rscript calibration/collect_dispersed_multistart.R | tee "<OUT>/collect_$(date +%Y%m%d).log"
   ```
   Note the basins and the out-of-time count (the `k_w` arm had 6).
3. **Promote.** Let `<DEST>` = `calibration/output/refit_$(date +%Y%m%d)_obj16_hilda_csl3v0kaidgbem`. The read script globs `refit_*_obj16_hilda_csl3v0kaidgbem`, so the name matters.
   ```
   mkdir -p <DEST>
   Rscript calibration/promote_multistart_mode.R --name=obj16_hilda_csl3v0kaidgbem --outdir="<OUT>" --dest=<DEST> 2>&1 | tee <DEST>/promote_$(date +%Y%m%d).log
   ```
   GATES 1–5 must pass. At id 1 they did: GATE 4 diff 0, GATE 5 gap 8.5e-14.
4. **Hessian:**
   ```
   Rscript calibration/recompute_hessian.R <DEST>/mode_fit_pumpN.rds --update 2>&1 | tee <DEST>/hessian_$(date +%Y%m%d).log
   ```
   ~12 min on an idle Mac. At id 1: positive-definite, condition 2.7e5.
5. **Read:** `Rscript calibration/diag_obj16_refit_read.R`
   - It writes `outputs/diagnostics/obj16_refit_read_<date>.{log,rds}`.
   - It reads on LIKELIHOOD against hilda34g's −1143.2508, and splits the futures move into the feedback's part and the rest.
6. **Ocean:**
   ```
   CCX_OC_MODE="obj16=<DEST>/mode_fit_pumpN.rds" Rscript calibration/diag_ocean_climate_gobm.R
   ```
   - It writes `outputs/diagnostics/ocean_climate_gobm_<date>_obj16.{log,rds}` in ~4 min.
   - R0's gate is skipped BY CONSTRUCTION here. CHECK 0 must pass, and both mutations must fail.
7. **Scorecard:**
   ```
   CCX_SC_EXTRA_MODE="obj16=<DEST>/mode_fit_pumpN.rds" CCX_SC_TAG_SUFFIX=_obj16 Rscript calibration/diag_whole_model_scorecard.R | tee outputs/diagnostics/whole_model_scorecard_$(date +%Y%m%d)_hilda34g_obj16.log
   ```
8. **Record:** a CHANGELOG entry, then stage and commit `<OUT>`, `<DEST>` and the new outputs as SEPARATE steps (stage, check `git diff --cached --stat`, commit), then push.
9. **Adoption is Marcus's call**, read on likelihood. If adopted, follow 10-05b §5 step 7:
   - `CCX_MODE_CANONICAL` and its pins;
   - the reference-set branch: keep or remove it, by ruling;
   - restart the app preview;
   - the `npp_tsens` row and the greening wording are his.

## 6. What to expect: the ONE-START PREVIEW (id 1, CHANGELOG 10-05 j), not the read
- **Likelihood −1.7667 vs hilda34g:** CO₂ −1.44 (`co2_icecore` −1.10), GCB −0.32, δ¹³C +0.14.
  - It splits into the pin and the refit −0.84, and the feedback at #16 −0.93.
  - Its match with the feedback's unrefitted −1.7668 was TESTED: a coincidence of totals.
- **Futures, 2300:** SSP5-8.5 +12.80 ppm (the feedback's direct part +5.52), vvH +7.77.
- **The land's net climate effect:** −0.038 (hilda34g +0.118; GCB −0.8 ± 0.7).
- **The moves:** `beta_max` 2.078; `k_w` 1894.7.
- **The ocean, like-for-like:** −0.375 (1.87× GCB); the twin −0.355.
- **The scorecard:** no gate verdict flips.
- If all 24 land in this one basin, the read will look like this. A better basin among the dispersed starts would change it.

## 7. Open items (each is Marcus's to prioritize)
1. **#16's landing** (§5). This session lands it tonight if it stays open. Adoption is his.
2. **H2,** the ocean thermal excess in the low-latitude column (DEFERRED by ruling). ⚠ Under #16 the like-for-like headline grows by the feedback's ≈ −0.02.
3. **`hs_asx_frac`'s judgment width** (KEPT): `k_w` ≈ 1900 is a disclosed prior compromise. #16 moves it 1902.7 → 1894.7.
4. **H1's observed-ratio arm.** It needs a gridded SST download, which needs his permission.
5. **Card 4 wording** (`notes/draft_2026-10-04_card4_enso_timing.md`): his text.
6. **The hilda34g assessment's verdict.** If #16 is adopted, ask whether it becomes a #16 assessment.
7. **Optional, needs a ruling:** extend the substep fix's held-K rule to `ccx_tr_box_eigbound()`.
8. **NEW: the unmerged git-stamp branch** `claude/youthful-blackburn-fbc009` (`6c87138`, local + origin). Merging it needs a conversion pass, since its lint would flag ~94 drivers on `main` with inline stamps. Merge it, or retire it, by ruling.
9. **NEW housekeeping after the landing,** each needing his OK:
   - remove my test worktree `~/ccx_frozen/20261005g_ocgobm` (scratch only);
   - remove `~/ccx_frozen/20261005f_obj16`, ONLY after step 1's verification;
   - the three `20261004f_kw1446_launch.{sh,out,pid}` files left beside the removed `k_w` tree (copies are in the repo).

## 8. Non-obvious state
- **The read script's two globs** are matched in the repo's `calibration/output/`:
  - `multistart_20261005f_hilda_csl3v0kaidgbem_seasml1_pin_*npp_tsens=0_sd1.0452`;
  - `refit_*_obj16_hilda_csl3v0kaidgbem`.
  - A second match STOPS the script. `CCX_O16_MODE` / `CCX_O16_WAVE` override them, and `CCX_O16_TAG` tags a test run.
- **The outdir's name** writes pins as `=0`, from the launch string. `ccx_pin_label()` prints `=0.00`. Never rebuild the name from `ccx_pin_label()`.
- **Scratch in the test tree:**
  - `SCRATCH_obj16like_NOT_A_FIT` is hilda34g relabeled with #16's structure and pins. Its logpost and streams are hilda34g's.
  - The `DRYRUN_*` dirs come from a COPY of start 001.
  - Never copy either into the repo.
- **The end-of-run watch.** The background waiter hit the 2-h limit for background commands at 15:00 and was NOT restarted.
  - It was replaced by a session-only scheduled check. Since 19:15 this is cron job `dc08080d`, at `22 19-23,0-2 * * *` (it replaced `3843b92c`). On its first fire after the end line it lands the run with §5, then deletes itself.
  - ⚠ **THE MAC SLEPT 13:50–14:34 and 16:48–19:10** (lid closed on battery; CHANGELOG 10-05 m). The wall budget counted it: ids 012–015 ran OUT OF TIME, and 016–019 keep ~155 of their 300 min.
    - RULED "Land as is, state it": the landing states the sleep, the out-of-time ids, and the reduced survey power.
    - Keep the Mac on AC with the lid OPEN until the end (~23:10).
  - At 15:00 round 1 was done: 8/24, all converged. Six sit at −1187.452; ids 0 and 6 sit at −1187.636 / −1187.643, a possible second basin 0.19 below.
  - If the session dies, the run continues under `nohup`, and a fresh session lands it with §5.
- **Waiter globs:** match `start_[0-9][0-9][0-9].rds`, never `start_*.rds`, which also matches the checkpoints.
- **`pgrep` for the work processes:** use the BRACKET form, `pgrep -f 'R.*--file=calibration/run_dispersed_multistar[t].R'`.
  - The plain pattern matches its own text inside any `bash -c` that quotes it, including the Claude Bash tool's wrapper. It counted 9 = 8 workers + itself on 10-05 (CHANGELOG 10-05 l; memory `pgrep_wait_loop_matches_itself`, corrected).
  - The landing helper uses the bracket form.
- **Untracked in the repo, and not this session's:** `carbotopecomment.9.26.26.docx`, `carbotopecomments.10.2.26.docx`, `outputs/diagnostics/smoke/`, `outputs/mcmc_smoke/`.
- **Carried from 10-05b §7:**
  - the pin bookkeeping;
  - the two records that say "no code change";
  - compare arms on LIKELIHOOD;
  - `CCX_OC_HS_FRAC`;
  - the CO₂-prescription technique;
  - the coupled futures' 1850 GMST hold;
  - MAGICC is restricted;
  - the multi-line-shell lesson.
