# HANDOFF 2026-10-07d — OBJECTIVE #18 BUILT AND PRICED; STAGE 2 RUNNING; NEXT: BUILD THE LANDING KIT AND LAND IT

**Supersedes** `notes/handoff_2026-10-07c_obj18_build.md`, which now points here.
- Written on Marcus's request, verbatim: "write the handoff note."
- Items 1–6 of 10-07c §3 are DONE; its item 7 (the landing) is this note's §3.

**Start here.**
1. CHANGELOG 2026-10-07:
   - (h) the build, stage 1 and the price;
   - (i) basin B registered as `hilda29w`, and the launch;
   - (j) this handoff.
2. Memory, shared store:
   - `ccx_iav_cut_previewed`: the arc; its last bullet is this session;
   - `basin_rank_by_logit_jacobian`: BINDS the landing (promote ranks by the stored, Jacobian-carrying logpost);
   - `objective_noise_floor_optimum_on_spike`: every reproduce-gate ≥ 1e-5;
   - `block_refit_futures_can_be_ridge_position`: read every futures move against the ridge;
   - `stamp_dirty_from_untracked_input` (new): commit a chain's products before launching the step that reads them.

## 1. Where things stand
- **#18 = `hilda_csl3v0kaidgbemwt`** = #17 + `enso_index` 1 (detrend) + `gcb_ocean_lowpass_df` 6. Built at `3d50312`. Every parity target reproduced EXACTLY (0.0):
  - at #17's basin B with its own pins: logpost −1173.052374, likelihood −1137.127378, B1 −12.342383 (the emulation, `diag_iav_redesign_price.R` @`e891fa9`);
  - stage 1 under #18 at B (`fit_iav_module.R --struct`, `5d34d41`): `identical()` to the mirror. Lag **5.8483** (1σ 4.46–7.29), ×**1.29779**, `w_enso_l2` **16.6051**, ssr_ref 89.825775;
  - B2 (the land five re-fitted) and B2f (`beta_max` held) bit-identical to the emulation and the ridge, futures included.
- **The price** (`calibration/diag_obj18_price.R` @`570d194` → `outputs/diagnostics/obj18_price_20261007.{log,rds}`). Likelihood against REF = B on #18's rows with the shipped index:

| | module at P0 (#17's stage 1) | module at S18 (#18's stage 1) | SSP5-8.5 2300 vs B | vvH 2300 vs B |
|---|---|---|---|---|
| B1, unrefitted | −12.342 | −12.389 | +0.02 | +0.02 |
| B2, land five re-fitted | −7.664 (prior +0.52) | −7.799 (+0.51) | +23.32 / +22.73 | +10.74 / +10.45 |
| B2f, `beta_max` held at B's | −7.586 (+0.32) | −7.719 (+0.32) | +6.68 / +6.63 | +2.50 / +2.49 |

  - B: SSP5-8.5 1457.19, vvH 1006.99 (hilda33p 1461.53 / 1010.03).
  - The module's move to S18 costs −0.047 unrefitted, −0.13 re-fitted: the seasonal rows' interannual part (kept, as ruled).
  - Every futures move is INSIDE the ridge's 1σ (the redesign, natural space: SSP5-8.5 +34.2 / −37.9, vvH +17.7 / −18.3 ppm). B2's +23.3 is 0.68 of it. **Not a finding.**
- **Stage 2 is RUNNING** (launched 2026-10-07 14:55:44 EDT; at 15:22 the launcher was alive with 8 work processes and no exits).
  - Tree: `~/ccx_frozen/20261007i_obj18` at `c81f285`. Launcher PID 51496; `~/ccx_frozen/20261007i_obj18_launch.{sh,out,pid}`.
  - Tag `20261007i`. Outdir `calibration/output/multistart_20261007i_hilda_csl3v0kaidgbemwt_seasml1_pin_obj18_sd1.0452`, in THAT tree.
  - The recipe: 24 starts, 8 at once, 300 CPU-min each, 3 × 6 × 6000, spread 1.0452.
  - Incumbent `hilda29w` seeded at #18's pins (−1173.0992111 = the pricing's B1s); new basin the control `hilda31pe`.
  - Preflight 24/24, ports VERIFIED. 0.351 CPU-s/eval at preflight, 0.373 in the wave (load ~11).
  - **Expected end ~02:00–07:00 EDT 10-08** (#17's identical recipe: 11.1 h).
- **Suites:** `3d50312` 6694 / 0 / 3; `c81f285` (the launch commit) **6747 / 0 / 3**, rc 0 (`outputs/diagnostics/suite_20261007_*.log`).
- **Code:** `main` at this note's commit, pushed. No `R/`, `calibration/` or `tests/` change since `c81f285`.

## 2. Rulings this session (verbatim, AskUserQuestion)
- the incumbent: "Register B, seed from it (Recommended)", with the name proposed with it, `hilda29w`. #17's basin B is a PINNED, non-canonical, NOT-adopted registry entry, and `CCX_MODE_OBJ18_INCUMBENT`;
- `test-mode-file.R:179` (registering B turned it red: the lag gate's `lag_enso_land` was outside `names(CCX_PARAM_GATED)`): "Widen to all gates (Recommended)". It is now `names(CCX_PARAM_GATED_ALL)`, with a mutation check;
- "write the handoff note."
- ⚠ **Not ruled explicitly; flagged to Marcus, no answer yet:** `test-iav-cut.R` IC1's "no other label carries the cut's three fields" became an explicit ledger {#17, #18} under the build ruling ("Full redesign"). #18 inherits the three by design; every other label is still refused.

## 3. NEXT: THE LANDING KIT, A DRY RUN, THEN THE LANDING (adoption is Marcus's)
None of the #18 kit exists yet. #17's is the template: `outputs/diagnostics/obj17_landing_20261007/land_chain.sh`, `~/ccx_frozen/20261006o_obj17_land.sh`.
1. **Watch the run, never edit its tree.**
   - Its end line goes to `~/ccx_frozen/20261007i_obj18_launch.out`. Exit codes: `logs/ccx_multistart_mac_20261007i_exit.txt` in the tree. Per-task logs: `logs/ccx_multistart_mac_20261007i_<id>.out`.
   - Confirm the WORK processes, not only the launcher. Wait on the PID (`kill -0 51496`), never a bare `pgrep -f` loop: it matches itself (memory `pgrep_wait_loop_matches_itself`).
2. **`land.sh` for #18**, a copy of #17's with the tag, label, outdir and tree changed. It verifies the end, copies into the repo, cmps, then writes RUN_PROVENANCE.
3. **`calibration/diag_obj18_refit_read.R`**, on `diag_obj17_refit_read.R` (217 lines). It must score each comparison on ONE objective, because the rows and the free sets differ:
   - (0) each vector reproduces its stored logpost in its own space; the wave's survey;
   - (1) on #18's rows: #18's mode against REF and against the pricing's B1s / B2s;
   - (2) on #17's rows: #18's vector against `hilda29w` (the redesign's cost in #17's own terms);
   - (3) the module (`ccx_iav_module_loglik`) at #18's mode against stage 1;
   - (4) the prior ledger, and the moves in B's marginal sd;
   - (5) the futures, READ AGAINST THE RIDGE (±35 ppm);
   - (6) the land's net climate effect.
4. **The basins BEFORE promoting.** `promote_multistart_mode.R` has no `--id`; it takes the best STORED logpost.
   - Decompose likelihood / prior / Jacobian per basin first (`calibration/diag_obj17_basins.R`'s `own()`, adapted).
   - If the best-logpost basin is not the best on likelihood, bring the choice to Marcus. Adding `--id` to promote (with a test) would let the chain promote a chosen basin. It has been open since 10-07 (c); ask before building it.
5. **The chain:** land → collect → (decompose) → promote → Hessian (`recompute_hessian.R --update`, `nice 10`) → read → the one-pass check → anything else read at `hilda29w`.
   - The one-pass check: `fit_iav_module.R --base=<#18 mode> --check=calibration/output/iav_module_20261007_refit_20261006_obj17_basinB_start001_DRYRUN_hilda_csl3v0kaidgbemwt.rds`. No `--struct`: the base is a #18 file. Ruled tolerance 0.1 of stage 1's own Laplace σ.
6. **DRY-RUN the whole chain on the FIRST finished start, in a separate tree.** #17's dry run caught two bugs (CHANGELOG 10-06 p). #17's first start finished after ~3.3 h, so expect #18's around ~18:15 EDT 10-07.
7. **At the landing, report:**
   - the basins (decomposed);
   - #18 vs #17-B on LIKELIHOOD only;
   - whether the full refit recovers the ice-core cost (B2 paid −7.71 there);
   - the one-pass check (does `w_enso_l2` hold now that the main objective no longer resists it?);
   - GATE V;
   - the futures against the ridge.
   - Adoption is Marcus's.

## 4. Non-obvious state
- **The wave's tree holds its own `calibration/torch/port_targets.csv`** (regenerated under #18's pins). The repo's copy still holds the canonical's.
- **The Mac must stay on AC**, lid open or in closed-display mode: `caffeinate -s` holds only on AC (memory `mac_sleep_eats_wall_budget`). The CPU clock means a sleep spends no budget, but nothing runs while the Mac sleeps.
- **`hilda29w`'s file is the DRYRUN path, kept as is:** `calibration/output/refit_20261006_obj17_basinB_start001_DRYRUN/mode_fit_pumpN.rds`, md5 `081eb16f4fe718692004fb1cf9645891`. The pricing, the tests and stage 1 name that path and md5.
- **The new-basin port target is −11724.57.** That is an objective offset (the seas_ml-0 `hilda_c` control scored at seas_ml 1 under #18), not a port defect.
- **The noise floor (~1e-6):** every reproduce-gate needs ≥ 1e-5. `h_ml`'s Hessian was UNSTABLE at both #17 basins; expect the fallback step again.
- **`test-review-card-numbers.R` fails BY DESIGN** on any adoption that moves the lag. Update the copy WITH Marcus, not the test.
- **Frozen trees** (all detached worktrees):
  - `~/ccx_frozen/suite_20261007_3d50312` and `~/ccx_frozen/suite_20261007_c81f285`: their logs are in the repo, so removable on Marcus's OK (`git worktree remove`; he has not said yet);
  - `~/ccx_frozen/20261007i_obj18`: the RUNNING wave; keep until landed.
- **Carried:**
  - the two Claude-session worktrees under `.claude/worktrees/` (unexamined);
  - the app preview is not running;
  - the cut posterior ("Laplace + propagation", RULED, not built);
  - the app copy (card 4, the What-if numbers, the wobble shares);
  - `gamma_diff`'s own future.

## 5. Files from this session
- **Code:**
  - `R/likelihood.R` (the ocean switch);
  - `R/calibrate.R` (the label; #18's reference-set branch);
  - `R/paths.R` (`CCX_MODE_OBJ18_*`, `hilda29w`);
  - `calibration/fit_iav_module.R` (`--struct`);
  - `calibration/diag_obj18_price.R` (new).
- **Tests:**
  - `test-iav-redesign.R` (new, IR1–IR7);
  - `test-ms-reference-set.R` (13);
  - `test-mode-file.R` (179 widened + mutation);
  - `test-iav-cut.R` IC1;
  - the label ledgers in `test-enso-lag`, `-mixing-strat`, `-gated-params`, `-struct-v0`, `-constants-batch`, `-soil-inert`, `-tr-box`.
- **Outputs:**
  - `calibration/output/iav_module_20261007_refit_20261006_obj17_basinB_start001_DRYRUN_hilda_csl3v0kaidgbemwt.rds` (= `CCX_MODE_OBJ18_MODULE_FILE`);
  - under `outputs/diagnostics/`:
    - `iav_module_20261007_…_hilda_csl3v0kaidgbemwt.log` and `iav_module_20261007_basinB_obj18_stdout.log`;
    - `obj18_price_20261007{.log,.rds,_stdout.log}`;
    - `obj18_build_gate_mutation/` (`mutate.py` and its log: six mutations, all caught);
    - `suite_20261007_{3d50312,c81f285}.log`.
- **Launch (outside the repo):**
  - `~/ccx_frozen/20261007i_obj18_launch.{sh,out,pid}`;
  - in that tree, `logs/pins_20261007i.txt`, `logs/port_targets_20261007i.log`, `logs/preflight_20261007i{.log,/}` and `logs/wave_20261007i.log`.
