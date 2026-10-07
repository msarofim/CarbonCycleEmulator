# HANDOFF 2026-10-07 — OBJECTIVE #17's STAGE 2 FINISHED. LAND IT: everything is ready to run.

> ⛔ **SUPERSEDED by `notes/handoff_2026-10-07b_obj17_landed.md`.** The landing below RAN on 2026-10-07 (CHANGELOG
> 10-07 a, b). Step 6 stopped at its 1e-6 gate (the objective's noise floor; ruled to 1e-5), and the rest is done.
> Read the new note, not this one.

**Supersedes** `notes/handoff_2026-10-06d_obj17_running.md`, which now points here.
- Written on Marcus's instruction, verbatim: "write the handoff and run everything in the next session".
- So the next session RUNS the landing (§3) and reads it. Adoption stays Marcus's call.

**Start here.**
1. §3 below: one command runs the whole landing; then read its outputs in the order given.
2. CHANGELOG 2026-10-06 (o) (the build), (p) (the dry run and the second bug), (q) (the run finished, this note).
3. Memory, shared store:
   - `ccx_iav_cut_previewed`: the arc;
   - `pinned_value_reset_by_fitted_resolver`: the two bugs; check the class before trusting a new resolver;
   - `r_parser_17_digits_not_round_trip`: why the pin literals are within one ulp.

## 1. Where things stand
- **#17 is built** (CHANGELOG 10-06 o):
  - the label `hilda_csl3v0kaidgbemw`: `gcb_land_sink` on its low-pass part; `gcb_ocean_enso_slope` moved into the module;
  - the module's four names PINNED at stage 1's values (`CCX_MODE_OBJ17_PINS`);
  - stage 1 at hilda33p: lag 5.84 months, land ×1.30, `w_enso_l2` 14.73.
- **Stage 2 ran on the Mac**, 2026-10-06 19:26 → **2026-10-07 06:34 EDT, rc 0**. All 24 start files are written; no
  process is left.
- **Two pinned-value bugs were fixed** (`1ce5018`, `0a4e89f`). The whole landing chain was DRY-RUN on the first finished
  start and PASSED (CHANGELOG 10-06 p).
- **Code:** the suite at `0c585fc` is CLEAN, 6598 / 0 / 3. `main` is at this note's commit, pushed.

## 2. The run's result, as surveyed read-only (NOT the read)
- **18 of 24 converged in time, into TWO basins:**

  | basin | logpost | starts (ids) |
  |---|---|---|
  | **A** | **−1164.8154** | 8, all from COLD dispersed starts: 10 (best), 17, 15, 9, 8, 0, 14, 13 |
  | B | −1165.2246 | 8: the incumbent seed 1, the new-basin seed 2, seeds 3 / 4 / 5, cold 20 / 16 / 7 |

  - Also converged, local: id 6 −1198.68 and id 23 −1216.36.
  - Out of time: 11 (−1167.44), 12 (−1171.10), 19 (−1223.04), 18 (−1284.94), 21 (−1837.91), 22 (−1.56e9, a penalty
    region it never left).
- **A beats B by 0.409, so the landing promotes id 10 (A).** No canonical-seeded start found A.
- **What separates them** (stored parameters, in hilda33p's marginal sd):
  - mainly **`h_ml` 58.03 m in A vs 49.89 m in B (+2.67 sd)**;
  - then `sst_seas_amp_SH` 1.373 vs 1.234 (+0.76), `npp_frac_NH`, `q10`, `seas_lag_p_NH` / `_SH` (≤ 0.38 sd each).
  - It is the known `h_ml` near-degeneracy. hilda33p sits at 49.6 m, on B's side. The read must show what the deeper
    mixed layer does to the rows and the futures.
- **⚠ The dry run's numbers (CHANGELOG 10-06 p) were BASIN B's (start_001).** Every one of them must be re-read at A:
  - #17's rows −9.32 against REF; #16's rows −39.24;
  - SSP5-8.5 2300 −4.33 ppm;
  - the one-pass check's `w_enso_l2` drift of +1.55σ.
- **Id 18 exited rc 1, and it changes nothing.**
  - The driver's DEAD-TASK gate fired on a 1.58e-8 relative gap between its recorded best and a re-evaluation (the
    tolerance is 1e-8). The re-evaluation is FINITE, despite the message's "penalty plateau" wording.
  - It is an out-of-time cold start about 120 log-units below the basins, and `collect` refuses it.
  - The chain appends a statement with these numbers, all read from the file, to `RUN_PROVENANCE.txt`.

## 3. THE LANDING: run it, then read it
1. **Preconditions:**
   - the Mac awake;
   - no uncommitted changes under `R/`, `calibration/` or `tests/`, and HEAD at or after `0a4e89f` (the chain refuses
     otherwise);
   - do not edit any repo script while it runs.
2. **Run the chain in the background and wait on its PID** (never a `pgrep` loop):
   ```
   nohup bash ~/ccx_frozen/20261007_obj17_land_chain.sh > ~/ccx_frozen/20261007_obj17_land_chain.out 2>&1 &
   ```
   - About 30 min, mostly the Hessian. It stops at the first failure and names the log.
   - Its steps:
     0. `land.sh`: verify, copy into the repo, cmp every file, write `RUN_PROVENANCE.txt`. It REFUSES to overwrite an
        existing repo outdir; once it has succeeded, never re-run it;
     1. the id-18 statement;
     2. collect;
     3. promote to `calibration/output/refit_20261007_obj17_hilda_csl3v0kaidgbemw/` (expect id 10);
     4. Hessian (`--update`, `nice 10`);
     5. `diag_obj17_refit_read.R`;
     6. the one-pass check, `fit_iav_module.R --check`;
     7. the same read at BASIN B (the dry run's promoted start_001, in `~/ccx_frozen/20261006o_obj17_dryrun`).
   - Logs: `outputs/diagnostics/obj17_landing_20261007/`. On a failure, read the log, fix, and run the remaining steps
     by hand: the commands are in the script.
3. **Read, in this order:**
   - **collect:** the basins and their counts.
   - **promote:** GATES 1–5 (GATE 5 must close to ~1e-14, as in the dry run) and the promoted id.
   - **Hessian:** positive-definite? The condition number (the dry run's basin B gave 2.9e5)? Which directions are
     widest (`h_ml`, given §2)?
   - **The read** (`outputs/diagnostics/obj17_refit_read_20261007.log`):
     - #17 vs REF on #17's rows;
     - #17's vector vs hilda33p on #16's rows;
     - the module at both points;
     - the prior ledger and the moves;
     - the futures (SSP5-8.5 and vvH, 2300);
     - the land's net climate effect.
   - **A vs B:** set the basin-B read (`…_basinB.log`) beside A's: which rows, which futures. That is the `h_ml`
     degeneracy's practical consequence.
   - **The one-pass check** (`check.log`, VERDICT line): each module name's move in its stage-1 σ. RULED: stop below 0.1σ;
     anything larger goes to Marcus before any second refit.
4. **If it flags `w_enso_l2` again, run the test before framing the choice for Marcus.**
   - At the landed vector, take the slope row's derivative with respect to each ocean name that moved (one at a time,
     the others held), and see whose product with its move accounts for the slope's drop.
   - My hypothesis is UNTESTED: a weaker solved pump (`pump_grad` moved −0.88 sd at B) leaves less DIC contrast for the
     limb to move per unit exchange.
5. **The separate drivers**, from a frozen copy at HEAD, as for #16 (CHANGELOG 10-05 p):
   ```
   CCX_SC_EXTRA_MODE="obj17=<mode>" CCX_SC_TAG_SUFFIX=_obj17 Rscript calibration/diag_whole_model_scorecard.R
   CCX_OC_MODE="obj17=<mode>" Rscript calibration/diag_ocean_climate_gobm.R
   ```
   Also the gate ledger and the constraint map, as #16's landing read them.
6. **Write it up, commit, push, and bring Marcus the decisions:**
   - adopt #17 or not; the read is on LIKELIHOOD, never stored logposts;
   - the `w_enso_l2` outcome: accept the one pass, iterate (another overnight refit at the new `w`), or redesign;
   - **the cut posterior** ("Laplace + propagation", RULED; not built yet):
     - stage 1's covariance is in `calibration/output/iav_module_20261006_hilda33p.rds` (`$laplace$cov`, and
       `$laplace$cov4` on the four pinned names);
     - still needed: the main objective's cross-Hessian between the 29 free names and the four module names. Vary the
       PIN values and rebuild the logpost per step; the guard refuses them free;
     - then Cov(θ₂) = H₂₂⁻¹ + B Σ₁ Bᵀ, with B = −H₂₂⁻¹ H₂₁, drawn by `build_futures_ribbons.R`;
   - **the app copy:** card 4's timing disclosure becomes obsolete; the What-if numbers; the wobble shares.
     ⚠ `tests/testthat/test-review-card-numbers.R` will FAIL by design once the lag moves. Update the copy WITH Marcus,
     not the test;
   - still separate: `gamma_diff`'s own future (an AOD term made zero-mean).

## 4. Non-obvious state
- **Frozen trees** (each a detached worktree; removing either needs Marcus's OK, as before):
  - `~/ccx_frozen/20261006x_obj17`: the run, finished. Removable once the landing copy is verified. Its
    `calibration/torch/port_targets.csv` holds #17's targets (`main`'s still holds the canonical's).
  - `~/ccx_frozen/20261006o_obj17_dryrun` at `0a4e89f`: basin B's promoted file, which chain step 7 reads. Removable
    after the landing; its logs are already in `outputs/diagnostics/obj17_dryrun_20261006/`.
- **Scripts** in `~/ccx_frozen/`:
  - `20261006o_obj17_launch.{sh,out,pid}`: the launch and its chain status;
  - `20261006o_obj17_land.sh`: step 0;
  - `20261006o_obj17_dryrun.sh`: the dry run;
  - `20261007_obj17_land_chain.sh`: the whole landing.
- **The app preview (localhost:7788) is NOT running.** It died overnight; restart it with `preview_start` (`ccx-app`) if
  needed.
- **The pin literals are within one ulp,** not bit-identical: R's parser and the launch string agree, so the run's pins
  ARE `CCX_MODE_OBJ17_PINS`.
- **`fit_iav_module.R` names a promoted base by its directory** (since this note's commit), so the check writes
  `calibration/output/iav_module_20261007_refit_20261007_obj17_hilda_csl3v0kaidgbemw.rds`.
- **Smoke outputs** of the new drivers are in `outputs/diagnostics/smoke/` (untracked).
