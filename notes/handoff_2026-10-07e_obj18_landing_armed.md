# HANDOFF 2026-10-07e — #18's LANDING KIT BUILT, DRY-RUN TWICE, AND THE LANDING ARMED; NEXT: READ THE LANDING

> ⚠ **SUPERSEDED 2026-10-08 by `notes/handoff_2026-10-08_hilda29e_adopted.md`**: #18 landed, pass 2 passed, `hilda29e` adopted.


**Supersedes** `notes/handoff_2026-10-07d_obj18_stage2_running.md`, which now points here.
- Written on Marcus's request ("Yes" to the offered handoff note).
- 10-07d's §3 items 1–6 are DONE. Its item 7 (the landing report) is this note's §3.

**Start here.**
1. CHANGELOG 2026-10-07:
   - (k): the kit, the six rulings, both dry runs, the arming;
   - (l): this handoff.
2. Memory, shared store:
   - `ccx_iav_cut_previewed`: the arc. Its last two bullets are this session;
   - `basin_rank_by_logit_jacobian`: the criterion RULED. Rank basins of ONE objective on likelihood + PRIOR, never the likelihood alone, and read a runner-up within 0.5;
   - `pinned_name_seed_vanishes`: RECURRED under the cut; the driver fix is owed;
   - `objective_noise_floor_optimum_on_spike`: every reproduce-gate ≥ 1e-5;
   - `block_refit_futures_can_be_ridge_position`: read every futures move against the ridge.

## 1. Where things stand
- **Stage 2 is running.**
  - Launcher PID 51496; tree `~/ccx_frozen/20261007i_obj18` at `c81f285`; tag `20261007i`. 24 starts, 8 at once, 300 CPU-min each.
  - Ids 0–7 finished 18:18–19:13 EDT, all exit 0.
  - From ~19:20 to ~20:50, another Claude session's `python/ic_ladrillo_vs_brick20.py` (a multiprocessing pool) held the load at ~100–120 on 10 cores. The work processes fell from ~94 % to ~65 % CPU. The budget is on the CPU clock, so nothing is lost, but the end slips. **Expected ~03:00–09:00 EDT 10-08.**
- **THE LANDING IS ARMED** (20:49 EDT):
  - `~/ccx_frozen/20261007i_obj18_land_armed.sh`, PID **73011** (its parent subshell 73007 is harmless; it was reparented to launchd);
  - it waits on the launcher's PID with `kill -0` (never a `pgrep` loop), then runs `caffeinate -i -s bash ~/ccx_frozen/20261007i_obj18_chain.sh land` ONCE;
  - its stdout, and the chain's: `~/ccx_frozen/20261007i_obj18_land_armed.out`;
  - the step logs: `outputs/diagnostics/obj18_landing_<date>/` (the date is the landing's, e.g. 20261008).
  - ⛔ **It adopts nothing and commits nothing.**
- **What `chain.sh land` does, in order** (stops at its first failure and names the step's log):
  1. **land:** `~/ccx_frozen/20261007i_obj18_land.sh`. It verifies the end line, that no work process is left and the 24 exit codes; copies the outdir, the logs, the preflight folder and the port targets into `calibration/output/multistart_20261007i_hilda_csl3v0kaidgbemwt_seasml1_pin_obj18_sd1.0452/`; cmp's every file; writes `RUN_PROVENANCE.txt`. It refuses an existing outdir.
  2. **collect**, its log also copied as the outdir's `collect_<date>.log`.
  3. **basins:** `diag_obj18_basins.R` → `outputs/diagnostics/obj18_basins_<date>.{log,rds,ids}`.
     - The `.ids` file holds `LP` (the best stored logpost), `NAT` (the best likelihood + prior) and `NEAR` (the runner-up on it, when within the starts' `cycle_tol` 0.5).
  4. **promote LP** (promote's default) → `calibration/output/refit_<date>_obj18_hilda_csl3v0kaidgbemwt/`. The chain STOPS if promote's id is not the basin step's LP (a dead best).
  5. **promote NAT and/or NEAR** with `--id`, when they differ from LP → `…_id<NNN>/`. The `--why` and the gap are recorded in `promoted_from`.
  6. For EACH promoted mode (step names end `_id<NNN>`):
     - the Hessian (`--update`, `nice 10`);
     - the read (`diag_obj18_refit_read.R` → `obj18_refit_read_<date>_id<NNN>.{log,rds}`);
     - **the one-pass check** (`fit_iav_module.R --base=<mode> --check=<CCX_MODE_OBJ18_MODULE_FILE>` → `calibration/output/iav_module_<date>_refit_<date>_obj18_…[_id<NNN>].rds` + log; RULED 0.1σ);
     - the ocean-climate driver (`ocean_climate_gobm_<date>_obj18id<NNN>.*`).
  7. **ONE scorecard** with every promoted arm beside `hilda29w` (GATE V): `whole_model_scorecard_<date>_hilda33p_obj18.rds`; the full text is in the step log `scorecard.log`.
- **The PREVIEW** (two dry runs on the 8 starts finished by 19:22; ⛔ NOT the read: the landing may find other basins):

| | id 0 (cold start), `h_ml` 64.6: LP = NAT | id 6 (incumbent's basin, 4 distinct), `h_ml` 50.0: NEAR |
|---|---|---|
| stored logpost / likelihood + prior | best / best | −1.018 / **−0.087** (a tie) |
| #18's rows vs REF (the pricing: B2s −7.80) | −8.09 | −7.53 |
| the ice cores vs REF (B2s −7.71) | −7.87 | −8.08 |
| likelihood vs its seed B1s | +4.30 | +4.86 |
| #17's rows vs `hilda29w` | −8.56 | −7.36 |
| the module's slope row (stage 1's +2.786) | **+2.785 (holds)** | **+1.898 (falls)** |
| **one-pass check, `w_enso_l2`** (#17: A +2.31σ, B +1.55σ) | **+0.126σ** (16.61 → 16.79) | **−1.10σ** (16.61 → 15.01) |
| the lag / the land scale | +0.065σ / +0.028σ | +0.001σ / −0.002σ |
| Hessian | PD, cond 2.905e5, no unstable name | PD, cond 2.916e5, **`h_ml` UNSTABLE** |
| GATE V (obs 0.933 ± 0.084; `hilda29w` 0.813) | PASS, 0.792 | PASS, 0.776 |
| SSP5-8.5 2300 vs `hilda29w` (the ridge's 1σ 34.2) | +18.1 (0.53: inside) | +12.2 (0.36: inside) |

  - Every other scorecard verdict at both basins is `hilda29w`'s: 5 / D / GL / H fail; 6 / 7 / G / P7 / Q / S pass.
  - Reading it, inferred and untested: at id 6 stage 2 RAISED `pump_grad` (+0.75 sd; #17 lowered it), so the ocean's ENSO slope plausibly overshoots and the module takes w DOWN. **The basin now decides whether the cut is self-consistent.**
- **Determinism, measured:** dry run 2 reproduced dry run 1 at id 0 byte for byte (the promoted mode with its Hessian, md5 `76d1056a`; the read / check / Hessian logs line for line).
- **Code:** `main` at this note's commit, pushed.
  - Since `c81f285`: promote `--id` (`5bed8ac`), the kit (`c39797c`), the NEAR rule (`3a50d21`).
  - **Suite at `5648307`**: launched 20:54 EDT 10-07 → `outputs/diagnostics/suite_20261007_5648307.log` (tree `~/ccx_frozen/suite_20261007_5648307`). ⚠ If its result is not in CHANGELOG (l), read the log's last line. `test-promote-id.R` alone passed 67 / 0, and its seven mutations were each caught.

## 2. Rulings this session (verbatim, AskUserQuestion)
- promote: "Build --id, read both (Recommended)";
- the duplicate seeded starts: "Records now, driver later (Recommended)";
- `test-iav-cut.R` IC1 (flagged at 10-07 h): "Keep the ledger (Recommended)";
- the two suite trees `3d50312` / `c81f285`: "Remove both (Recommended)". Done;
- the second basin's criterion: "Likelihood + prior (Recommended)". Validated on #17's own wave: the likelihood alone picked basin 3 (id 6), 33.9 below, with priors −36.6;
- a near-tied runner-up: "Read both within 0.5 (Recommended)".

## 3. NEXT: READ THE LANDING (adoption is Marcus's)
1. **Did it run?**
   - `cat ~/ccx_frozen/20261007i_obj18_land_armed.out`; `kill -0 73011` (alive = still waiting or running); `kill -0 51496` (the wave).
   - Wait on PIDs, never a bare `pgrep -f` loop (memory `pgrep_wait_loop_matches_itself`).
2. **If the chain FAILED:**
   - its stdout names the step and the last 15 lines of that step's log.
   - ⛔ If it failed AFTER step `land`, do NOT re-run `chain.sh land`: `land.sh` refuses the existing outdir, and the outdir must NOT be deleted to get round that. Run the remaining steps by hand: each is one line in `~/ccx_frozen/20261007i_obj18_chain.sh` (copy: `outputs/diagnostics/obj18_dryrun_20261007/run2_3a50d21/chain_v2.sh`).
   - If it failed AT `land` (an unfinished run, a stray multistart process), nothing was copied: fix the cause and run `bash ~/ccx_frozen/20261007i_obj18_chain.sh land`.
3. **Read and report:**
   - **the basins**, decomposed, with DISTINCT counts (expect ids 3 / 4 / 5 = 1 / 2 / 2), and which ids were promoted and why;
   - **#18 vs #17-B on LIKELIHOOD only** (the read's §1 "against its SEED B1s" and §2 "on #17's rows");
   - **the ice cores** (§1 by group, against B2s −7.71);
   - **the one-pass check at EACH promoted basin**, against the ruled 0.1σ (the preview: +0.126σ / −1.10σ);
   - **GATE V**, every other verdict, and the ocean's climate effect against GCB;
   - **the futures against the ridge** (§5);
   - any non-zero exit in `logs/ccx_multistart_mac_20261007i_exit.txt`: write a statement as #17 did for its id 18.
4. **Commit** the landing (the outdir copy and the diagnostics) and write its CHANGELOG entry.
   - The steps after `land` will stamp `+dirty`: the copied outdir is untracked while they run, as at #17. The code was clean, and the chain's refusal check proves it.
   - For a clean stamp, commit, re-run the read, and require `identical()` numbers (memory `stamp_dirty_from_untracked_input`).
5. **Decisions, all Marcus's:**
   - which basin (the preview's two are tied on likelihood + prior and differ on the check);
   - adopt #18 or not;
   - the `w_enso_l2` path: accept / iterate / redesign. Its sign now depends on the basin.
6. **Owed, ruled ("driver later"):** the duplicate-start fix in `calibration/run_dispersed_multistart.R`.
   - An unseedable seeded slot (its seed hits a name the arm PINS) becomes a dispersed draw, labelled as such.
   - The preflight refuses duplicate start vectors, with a test.
   - Derive "seedable" from the arm's FREE set, not from a list of pinned special cases: the 09-17 fix keyed on the ocean pair is exactly what re-opened.

## 4. Non-obvious state
- ⛔ **Do not edit any repo script under `R/`, `calibration/` or `tests/` while the landing chain runs.** It runs them from the repo (memory `never_edit_a_running_script`). An uncommitted change there also makes it REFUSE to start.
- **The scripts outside the repo** (`~/ccx_frozen/`): `20261007i_obj18_chain.sh` (v2), `20261007i_obj18_land.sh`, `20261007i_obj18_land_armed.sh`. Copies: `outputs/diagnostics/obj18_dryrun_20261007/{land.sh,land_armed.sh,run2_3a50d21/chain_v2.sh}`.
- **The dry-run evidence:** `outputs/diagnostics/obj18_dryrun_20261007/run1_c39797c/` and `run2_3a50d21/`. The dry-run tree itself is removed.
- **The wave's tree holds its own `calibration/torch/port_targets.csv`** (#18's). The repo's copy is the canonical's, and that does not matter at the landing: collect reads each start file's RECORDED port check (`port_checked`, `port_rel`), not a CSV. `land.sh` copies the tree's targets into the outdir as `port_targets_hilda_csl3v0kaidgbemwt.csv`.
- **`hilda29w`'s file is the DRYRUN path, kept as is:** `calibration/output/refit_20261006_obj17_basinB_start001_DRYRUN/mode_fit_pumpN.rds`, md5 `081eb16f…`.
- **The Mac must stay on AC.** `caffeinate -s` holds only on AC (memory `mac_sleep_eats_wall_budget`). The armed script holds caffeinate for the chain; the launcher holds its own for the wave.
- **`test-review-card-numbers.R` fails BY DESIGN** on any adoption that moves the lag. Update the copy WITH Marcus, not the test.
- **The noise floor (~1e-6):** every reproduce-gate is ≥ 1e-5. In the dry runs: the check's dg path 3.8e-6 at id 0 and 7e-7 at id 6; promote's GATE 4 −4e-6 / −7e-7.
- **Frozen trees** (detached worktrees):
  - `~/ccx_frozen/20261007i_obj18`: the RUNNING wave; keep until landed and committed;
  - `~/ccx_frozen/suite_20261007_5648307`: removable once its log is committed (Marcus ruled the earlier two "Remove both");
  - `.claude/worktrees/{compassionate-leavitt-a7e631, youthful-blackburn-fbc009}`: unexamined, carried.
- **Carried:**
  - the cut posterior ("Laplace + propagation", RULED, not built);
  - the app copy (card 4, the What-if numbers, the wobble shares);
  - `gamma_diff`'s own future;
  - the app preview is not running.

## 5. Files from this session
- **Code** (all committed):
  - `calibration/lib_ms_promote.R` (new); `calibration/promote_multistart_mode.R` (`--id` / `--why`; `5bed8ac`);
  - `calibration/diag_obj18_basins.R` (new; `c39797c`, NEAR `3a50d21`);
  - `calibration/diag_obj18_refit_read.R` (new; `c39797c`).
- **Tests:** `tests/testthat/test-promote-id.R` (new, PI1–PI3, 67), with `outputs/diagnostics/promote_id_gate_mutation/` (`mutate.py`, its log: seven mutations, all caught).
- **Records:**
  - CHANGELOG (k), plus the in-place correction "#17's B had 5 distinct starts" at 10-06 (q) ×2 and 10-07 (a);
  - `notes/handoff_2026-10-07_obj17_finished.md` (the same correction).
- **Memory:** `pinned_name_seed_vanishes`, `basin_rank_by_logit_jacobian`, `ccx_iav_cut_previewed`; pointer clauses in `INDEX_ccx_var`, `INDEX_diag_conv`, `INDEX_conv_build`.
