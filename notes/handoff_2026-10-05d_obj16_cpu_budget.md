# HANDOFF 2026-10-05d — #16 is still RUNNING and its landing is ready; THE NEXT BUILD is budgeting multistart starts by CPU TIME instead of wall-clock time

> **STATUS 2026-10-05 20:45 (CHANGELOG 10-05 o):**
> - **D1–D4 are RULED, all as recommended.** D5 was not chosen.
> - **Cron `dc08080d` is GONE;** it did not survive the context reset. A PID waiter in the same session replaces it.
> - The exact sleep windows for §4's statement are in (o).
>
> **STATUS 2026-10-05 21:10, OVERNIGHT.** Marcus: "I'm headed to bed. Take the next obvious steps whenever the running tasks complete."
> - **The landing runs ITSELF.** `~/ccx_frozen/20261005f_obj16_landchain.sh` is under `nohup` + `caffeinate`; its PID is in `…_landchain.pid` and its log in `…_landchain.out`.
>   - It waits on the launch chain (PID 27265), then runs §4 steps 1–7 with ONE date stamp.
>   - Its step 1b appends the ruled sleep statement (`…_sleep_addendum.R`, every number read).
>   - It stops at the first failing step. Mock-tested: the full path, a promote failure, and a refused landing.
>   - Step 8 (CHANGELOG, commit, push) is the session's. Adoption is Marcus's.
>   - If `…_landchain.out` ends in "landchain DONE", read the step logs and write step 8. If it does not, read where it stopped.
> - **The CPU-clock build is DONE on branch `claude/ms-cpu-clock` (`0038262`; worktree `~/ccx_frozen/20261005h_cpuclock`). It is NOT merged.**
>   - test-ms-clock passes (47 expectations), and test-ms-deadline's 36 pass unchanged.
>   - 13 of 13 mutations are caught (`~/ccx_frozen/20261005h_cpuclock_smoke_logs/mutations_0038262.log`).
>   - Still to do, in order:
>     1. the end-to-end smokes, `~/ccx_frozen/20261005h_cpuclock_smoke.sh`, ONLY after the chain's step 1 (the landing helper counts every driver process);
>     2. rebase onto the landing commit;
>     3. the full suite, frozen, under `nohup`;
>     4. merge, then the build's CHANGELOG entry.
> - **Scratch worktrees, never to be committed from:** `~/ccx_frozen/20261005h_cpuclock_old` (2ed310a) and `~/ccx_frozen/20261005h_cpuclock_smoke` (0038262). Each has #16's port targets copied in.

**Supersedes** `notes/handoff_2026-10-05c_obj16_landing_ready.md`.
- 10-05c remains the record of the landing tools and the dry run.
- Its landing commands are reproduced in §4 here, so this note stands alone.
- Written on Marcus's request, verbatim: "Can you write a handoff that includes budgeting by CPU time instead of clock time."

**As of 2026-10-05 19:28:** 16 of 24 tasks are finished, all exit 0, and 8 work processes are running (ids 16–23). The
expected end is **~23:10**: ids 20–23 reach their wall deadlines at ~23:05.

**Start here.**
1. Read this note.
2. Then CHANGELOG 2026-10-05 (m), (l), (j) and (h), newest at the top of `CHANGELOG.md`.
3. Then these memory files (shared store):
   - `mac_sleep_eats_wall_budget` (new: the incident behind §5);
   - `pgrep_wait_loop_matches_itself` (CORRECTED 10-05: use the bracket form);
   - `handoff_stale_label_is_a_claim`;
   - `ccx_ocean_climate_effect_vs_gcb` (its #16 section).

## 1. Since 10-05c
- **The Mac SLEPT ~3 h**, 13:50:45–14:34:01 and 16:48:20–19:10:43 (CHANGELOG 10-05 m).
  - The lid was closed on battery: `pmset` logged "Clamshell Sleep". `caffeinate -s` holds only on AC.
  - The multistart's 300-min budget is WALL-CLOCK, so the sleep spent it:
    - **ids 12–15 ran OUT OF TIME** at the 18:05 DarkWake: 012 −1187.643, 014 −1187.646, 015 −1187.559, and 013 −2354.9, a slow start;
    - **ids 16–19 keep only ~155 of their 300 min**, and 20–23 ~236.
  - Marcus RULED: "Land as is, state it (Recommended)".
- **12 starts CONVERGED in time, in two basins.** The `k_w` arm also had two, 0.224 apart.
  - **A at −1187.452 × 7:** the incumbent 1, the NEW-BASIN start 2 (from −11908.92), and 3, 4, 5, 7, 10.
  - **B at −1187.636 / −1187.643 × 5:** 0, 6, 8, 9, 11.
  - No out-of-time point is above A.
- **My end-of-run waiter matched ITSELF** (CHANGELOG 10-05 l). The memory's "interpreter+script" remedy was wrong; the bracket form `…multistar[t].R` is right. The watch is now session cron `dc08080d` (§3).

## 2. Rulings (Marcus, verbatim, this session)
- "Landing prep only (Recommended)".
- The housekeeping: "Delete k_w frozen tree, Remove 2 suite worktrees, Delete remote pensive-burnell, Remove compassionate-leavitt"; "Remove worktree, keep branch (Recommended)"; "Archive both sessions (Recommended)".
- "Held + spun-up lag, both shown (Recommended)": #16's like-for-like ocean GMST rule.
- "Handoff now, then land tonight (Recommended)".
- **"Land as is, state it (Recommended)"**: the sleep's out-of-time starts.
- **"Can you write a handoff that includes budgeting by CPU time instead of clock time."**: this note; the build is §5.

## 3. The run in flight, and the watch
- **Where:** the tree `~/ccx_frozen/20261005f_obj16`, at `aa76fb5`, launched 09:01:19 under `nohup`.
  - Chain status: `cat ~/ccx_frozen/20261005f_obj16_launch.out`.
  - Exit codes: the tree's `logs/ccx_multistart_mac_20261005f_exit.txt`.
  - ⛔ **Count the WORK processes with the BRACKET form:** `pgrep -f 'R.*--file=calibration/run_dispersed_multistar[t].R' | wc -l`.
- **The watch** is session-only cron **`dc08080d`**, firing at `22 19-23,0-2 * * *`. Its first fire after the end line lands the run with §4, states the sleep, then deletes itself.
  - ⚠ It DIES with this session. If the session is closed, the run still finishes under `nohup`, and the next session lands it with §4.
- **Keep the Mac on AC with the lid OPEN until ~23:15.** Measured: on battery the lid-closed Mac slept despite `caffeinate -i -s`.
  - My understanding, NOT tested here: a lid-closed MacBook sleeps even on AC unless it is in closed-display mode, which needs an external display.

## 4. THE LANDING (10-05c §5; every step dry-run tested in CHANGELOG 10-05 j)
Run from the repo root once the end line exists. ⚠ Do not edit these scripts while one of them runs.
1. **Confirm, copy, verify, record:** `bash ~/ccx_frozen/20261005f_obj16_land.sh`
   - It refuses unless the end line exists, NO work process is left, and there are 24 exit codes.
   - It `cmp`s every copied file before it writes `RUN_PROVENANCE.txt`, and it never overwrites. ⇒ `<OUT>` is the outdir it prints.
   - Then ADD the sleep to `RUN_PROVENANCE.txt` and to the CHANGELOG entry, by ruling: the two windows, the out-of-time ids, and the reduced survey power.
2. **Collect:**
   ```
   CCX_MS_OUTDIR="<OUT>" Rscript calibration/collect_dispersed_multistart.R | tee "<OUT>/collect_$(date +%Y%m%d).log"
   ```
3. **Promote.** Let `<DEST>` = `calibration/output/refit_$(date +%Y%m%d)_obj16_hilda_csl3v0kaidgbem`.
   ```
   mkdir -p <DEST>
   Rscript calibration/promote_multistart_mode.R --name=obj16_hilda_csl3v0kaidgbem --outdir="<OUT>" --dest=<DEST> 2>&1 | tee <DEST>/promote_$(date +%Y%m%d).log
   ```
   GATES 1–5 must pass.
4. **Hessian:** `Rscript calibration/recompute_hessian.R <DEST>/mode_fit_pumpN.rds --update 2>&1 | tee <DEST>/hessian_$(date +%Y%m%d).log`
5. **Read:** `Rscript calibration/diag_obj16_refit_read.R`. It reads on LIKELIHOOD against hilda34g's −1143.2508, splits the futures move, and reports the land's net climate effect.
6. **Ocean:** `CCX_OC_MODE="obj16=<DEST>/mode_fit_pumpN.rds" Rscript calibration/diag_ocean_climate_gobm.R`. The RULED GMST rule applies: the headline plus the GMST-historical twin.
7. **Scorecard:**
   ```
   CCX_SC_EXTRA_MODE="obj16=<DEST>/mode_fit_pumpN.rds" CCX_SC_TAG_SUFFIX=_obj16 Rscript calibration/diag_whole_model_scorecard.R | tee outputs/diagnostics/whole_model_scorecard_$(date +%Y%m%d)_hilda34g_obj16.log
   ```
8. **Record:** a CHANGELOG entry, then stage, check `git diff --cached --stat`, commit and push, as separate steps.
9. **Adoption is Marcus's call.** If adopted, the steps are in 10-05b §5 step 7.

**The one-start preview** (id 1, basin A; CHANGELOG 10-05 j):
- likelihood −1.7667 vs hilda34g (the pin and the refit −0.84, the feedback −0.93);
- SSP5-8.5 2300 +12.80 ppm;
- the land's net climate effect −0.038;
- the ocean −0.375 (twin −0.355);
- the scorecard: no gate verdict flips.

## 5. THE NEXT BUILD: budget each start by CPU TIME, not wall-clock time
### 5.1 Why
- The budget answers "how much COMPUTE does a start get". It is measured on the wall clock, so anything that stops the process without stopping the clock spends it.
- On 10-05 a ~3 h sleep cost #16 four out-of-time starts (012, 014 and 015 were near-converged) and halved 016–019's budget.
- An out-of-time count normally means "this start is SLOW". After a sleep it means "the machine was OFF" ⇒ `mac_sleep_eats_wall_budget`.

### 5.2 The measurement that makes CPU time the right clock (10-05, this machine, under the run's load)
- A probe R process ran ~4 s of busy work, then was `kill -STOP`ped for 5 s, within an 8-s `Sys.sleep`. Wall time advanced **8.2 s**; CPU time (`proc.time()` user + sys) advanced **0.00 s**.
- So a suspended or sleeping process accrues no CPU time.
- During the busy part, CPU/wall was **0.91**, with the 8 workers and the desktop competing for the cores.

### 5.3 What the budget is today (file:line at HEAD `ec10f5c`; the driver is unchanged since the launch commit `aa76fb5`)
`calibration/run_dispersed_multistart.R` — every one of these reads the WALL clock:

| line(s) | what |
|---|---|
| 308 | `MS_WALL_MIN <- .env_num("CCX_MS_WALL_MIN", 180)`. The Mac runner exports 300, and `multistart.sbatch` 300 of a 360-min `--time=06:00:00`. |
| 911 | `t0 <- Sys.time()`, the budget's origin. It is set AFTER the checkpoint loads, so a resume gets a FRESH budget. |
| 918–919 | the rate probe: `MS_SEC_PER_EVAL`, the median of 5 timed evaluations, in wall seconds |
| 960 | `elapsed_min()` |
| 973–981 | `polish_reserve_min()` and `maxit_for_budget()`, which size each restart from `MS_WALL_MIN - elapsed_min()` and the observed rate |
| 996, 1003 | each restart's timing → `restart_min`, normalised by `ms_restart_minutes()` |
| 999 | the restart's deadline, `as.numeric(t0) + 60 * (MS_WALL_MIN - polish_reserve_min())`, in epoch seconds |
| 1034 | the polish's sizing, `ms_polish_maxit(MS_WALL_MIN - elapsed_min(), …)` |
| 1043 | the polish's deadline, `as.numeric(t0) + 60 * MS_WALL_MIN` |
| 1136–1137 | the start file records `minutes = elapsed_min()`, `sec_per_eval` and `restart_min` |

`calibration/lib_ms_deadline.R:39`: `ms_check_deadline()` compares `as.numeric(Sys.time())` with the step's deadline.
It runs BEFORE every objective evaluation (driver line 545).

### 5.4 The design (the recommendation; the decisions in §5.5 come first)
1. **ONE clock function, `ms_clock()`, in `lib_ms_deadline.R`.** It returns seconds on the chosen clock:
   - `"wall"`: `as.numeric(Sys.time())`, today's behaviour, bit for bit;
   - `"cpu"`: `sum(proc.time()[c("user.self", "sys.self")])`, this R process's own CPU seconds. Children are excluded, and there are none. BLAS is pinned to one thread by both runners (`run_multistart_mac.sh:72`, `multistart.sbatch:370`), so CPU time cannot outrun wall time.
   - It is selected by a named constant read from `CCX_MS_CLOCK`, VALIDATED: an unknown value stops, never falls back.
2. **Every site in §5.3 reads `ms_clock()`, and nothing else does.**
   - `t0`, the rate probe, `elapsed_min()`, the restart timing and both deadlines move to it. The deadlines become `t0 + 60 * (…)` in that clock's seconds.
   - `ms_check_deadline()` compares `ms_clock()`.
   - A lint test fails on any other `Sys.time()` in the budget path: the `test-git-stamp-lint` idea, applied here.
3. **The start file records the clock:**
   - `clock` = "cpu" or "wall";
   - `minutes` on that clock, plus `minutes_wall` beside it;
   - `sec_per_eval` and `restart_min` on that clock.
   - An absent `clock` reads as "wall", which is what every existing file ran.
   - The collector and promote copy the field through.
4. **Labels name the clock.** "wall budget 300 min" becomes "CPU budget 300 min", derived from the constant, in the driver's log lines, the preflight line, and the Mac runner's banner.
5. **The Mac runner's comment is wrong; correct it.** `run_multistart_mac.sh:39` says "the Mac must not idle-sleep or lid-sleep". `caffeinate -i -s` cannot prevent a lid-closed sleep on battery.
   - Optionally, a launch-time WARNING when `pmset -g batt` says battery. It warns; it does not refuse.

### 5.5 Decisions for Marcus BEFORE building (flagged, not resolved)
- **D1. Which clock where?**
  - Recommended: **CPU on the Mac** (sleep, lid, desktop contention), **wall on Torch**. SLURM's `--time` is a hard WALL limit. A CPU budget there is safe only while the task holds its core (CPU ≈ wall), and the 60-min margin was sized for projection overruns, not for oversubscription.
  - The alternative is CPU everywhere, with an explicit wall ceiling (D4).
- **D2. A CPU budget STRETCHES the wall time under contention.**
  - At the measured 0.91, 300 CPU-min ≈ 330 wall-min. At the ~0.84 of the morning's heavier load, ≈ 357.
  - A 3-round Mac wave of ~13.7 h becomes ~15–16 h.
  - Keep 300 CPU-min (each start gets the compute the design intended), or lower it to hold the old wall ETA?
- **D3. Comparability.** Every existing run was budgeted on WALL time: the #14/#15 arms, `k_w` = 1446 and #16. Their out-of-time counts are wall-clock facts.
  - A convergence or out-of-time count compared across runs must name the clock, like-for-like ([[like_for_like_forcing]]'s discipline).
  - #16's sleep-affected starts stay labelled as such.
- **D4. A wall ceiling under the CPU clock?** Optional: stop a start at, say, 2× its budget in WALL time, so a badly oversubscribed machine cannot run a task for days ([[eta_in_days_is_not_a_slow_run]]).
- **D5. The alternative design, an "AWAKE wall clock",** would exclude any gap between consecutive objective calls longer than G (≫ the slowest evaluation, ~30 s near the h_ml wall).
  - It keeps wall semantics while awake, and it is identical to wall-clock on Torch.
  - It is more machinery for the same sleep-proofing, and Marcus asked for CPU time. Recorded so it is not re-invented.

### 5.6 Tests (each new gate MUTATION-TESTED: break what it guards, confirm it fails)
- **T1 Behaviour-preserving.**
  - With `CCX_MS_CLOCK=wall` (or unset, if D1 keeps wall the default), `test-ms-deadline.R`'s 8 tests (D1–D8) pass unchanged.
  - A preflight smoke run's log is identical below its stamp lines.
- **T2 The clock switch.**
  - An injected mock clock: a WALL jump with no CPU advance does NOT trip a CPU deadline; a CPU advance does.
  - Mutation: wire `ms_check_deadline()` back to `Sys.time()` ⇒ T2 must fail.
- **T3 A real suspend.** A smoke start under the CPU clock with a 2-min budget is `kill -STOP`ped for 3 min, then CONTinued.
  - It must NOT end out of time on the stop. The same run under the wall clock MUST.
  - The 10-05 probe already showed the clock behaves: +8.2 s wall, +0.00 s CPU.
- **T4 The record.** The start file carries `clock` and both minute fields. The collector and promote keep them. An old file reads as "wall".
- **T5 The lint.** No `Sys.time()` or `difftime` in the budget path outside `ms_clock()`. Mutation: add one back ⇒ the lint fails.
- **Then the full suite** at the change's commit, frozen and under `nohup` (`background_job_dies_with_its_session`).

### 5.7 Scope
- About 15 lines in the driver, 10 in `lib_ms_deadline.R`, and ~60 lines of tests.
- Nothing in `R/` changes: the objective, the likelihood and the optimiser's path are untouched while no deadline is reached.
- ⛔ **Not before #16 has landed.** The running tree is frozen at `aa76fb5`, so the repo may be edited, but the landing reads the run as launched, on its wall clock.

## 6. Open items (each is Marcus's to prioritise)
1. **#16's landing** (§4), then adoption by ruling.
2. **The CPU-time budget** (§5): rule D1–D5, then build and test.
3. **Optional:** resume the sleep-affected out-of-time starts (12, 14, 15, and 16–19 if they also run out of time) from their checkpoints, as a survey add-on. A resume gets a fresh budget. Ruled "stays an option".
4. **H2,** the ocean thermal excess (DEFERRED). Under #16 the like-for-like headline grows by the feedback's ≈ −0.02.
5. **`hs_asx_frac`'s judgement width** (KEPT): `k_w` ≈ 1900 is a disclosed prior compromise; #16 puts it at ~1895.
6. **H1's observed-ratio arm.** It needs a gridded SST download, with his permission.
7. **Card 4 wording**: his text.
8. **The hilda34g assessment's verdict.** If #16 is adopted, ask whether it becomes a #16 assessment.
9. **Optional:** the substep fix's held-K rule for `ccx_tr_box_eigbound()`.
10. **The unmerged git-stamp branch** `claude/youthful-blackburn-fbc009` (`6c87138`): merge it (a ~94-driver conversion pass) or retire it.
11. **`~/.claude/CLAUDE.md`'s pgrep remedy** ("interpreter+script") is wrong. The replacement text was given to Marcus 10-05; it is his file to edit.
12. **Housekeeping after the landing,** each needing his OK:
    - my test worktree `~/ccx_frozen/20261005g_ocgobm` (scratch only);
    - `~/ccx_frozen/20261005f_obj16`, only after §4 step 1's verification;
    - the three `20261004f_kw1446_launch.*` files.

## 7. Non-obvious state
- **`pgrep`:** use the BRACKET form. The plain pattern matches its own text in any `bash -c` that quotes it, the Claude Bash tool's wrapper included: 9 = 8 + itself, measured 10-05.
- **Waiter globs:** `start_[0-9][0-9][0-9].rds`, never `start_*.rds`, which also matches the `_ckpt` files.
- **The read script's globs** (`multistart_20261005f_hilda_csl3v0kaidgbem_seasml1_pin_*npp_tsens=0_sd1.0452` and `refit_*_obj16_hilda_csl3v0kaidgbem`) must match exactly once. `CCX_O16_MODE` / `CCX_O16_WAVE` override them.
- **The outdir's name** writes pins as `=0`, from the launch string. Never rebuild it from `ccx_pin_label()`, which prints `=0.00`.
- **The test tree** `~/ccx_frozen/20261005g_ocgobm` holds scratch only: `SCRATCH_obj16like_NOT_A_FIT` (hilda34g relabelled, NOT a fit) and the `DRYRUN_*` dirs. Never copy them into the repo.
- **Session cron jobs** are in-memory, die with the session, and auto-expire after 7 days.
- **Untracked in the repo, and not this session's:** `carbotopecomment*.docx`, `outputs/diagnostics/smoke/`, `outputs/mcmc_smoke/`.
- **Carried from 10-05b §7:**
  - the pin bookkeeping;
  - compare arms on LIKELIHOOD;
  - `CCX_OC_HS_FRAC`;
  - the CO₂-prescription technique;
  - the coupled futures' 1850 GMST hold;
  - MAGICC is restricted;
  - stage, check, then commit, as separate steps.
