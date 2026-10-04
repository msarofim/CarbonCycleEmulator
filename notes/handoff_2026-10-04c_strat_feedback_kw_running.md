# HANDOFF 2026-10-04 (c) — the stratification feedback is BUILT and PREVIEWED; P3 ≈ P0 (the choice is P0 vs P4); MAGICC reviewed; the `k_w` price arm is still RUNNING

**Supersedes** `notes/handoff_2026-10-04b_kw_price_obj16_proposals.md`. Its open items are closed or carried here (§4).
Self-contained. **Last updated 2026-10-04 19:50** (Marcus: "write a handoff"). The `k_w` status in §3 is as of 19:46.

**Start here.**
1. Read this note.
2. Then CHANGELOG 2026-10-04 (k)–(o), newest at the top of `CHANGELOG.md`.
3. Then these memory files (routed from `INDEX_ccx_ocean_struct.md`, `INDEX_ccx_phi.md`, `INDEX_diag_bound.md`,
   `INDEX_ccx_ocean_circ.md`, `INDEX_cmp_magicc.md`):
   - `ccx_strat_feedback_built`
   - `block_power_is_per_name`
   - `ccx_greening_sign_set_by_lag` (its P3 section)
   - `magicc_ocean_no_hemispheric_carbon`
   - `ccx_kw_hemispheric_balance`
   - `ccx_substep_fix_slows_nearwall_starts` (routed from `INDEX_infra.md`)

## 1. What was done (10-04 k → o)
- **(k) The P3 preview had NO POWER on `q10`.**
  - Its block frees `q10` to 0.15 of its marginal sd. `q10` rides a seasonal ridge with `seas_T_amp`, which the
    block held.
  - The repair (`calibration/diag_p3_powered_step.R`): a Newton step from the mode, EVALUATED, at power 0.87–1.00.
    `q10` moves < 0.04 sd, and **P3 ≈ P0**: `npp_tsens` +0.0089 → +0.0063, net climate effect +0.12 → +0.07 GtC/yr
    (still the wrong sign), +3.3 ppm.
  - `q10` is weak because 96 % of heterotrophic respiration passes through the 2-yr soil pool. A first-principles
    estimate gives 0.61 per unit ln q10 against 0.69 measured: structure, not a bug.
  - The greening proposal's §5 now recommends **P0 vs P4**.
- **(l) MAGICC's ocean** (restricted v7.5.3 source, read only; cite Meinshausen 2011 ACP 11:1417) has NO
  NH-sink / SH-upwelling mechanism for carbon.
  - Its hemispheric upwelling-diffusion columns are heat-only and closed per hemisphere. Its carbon ocean is one
    global response function with no isotopes.
  - CCX's record (the conveyor 08-13, `w_gthc` 09-20) already goes further.
  - The one transferable idea was the warming-dependent mixing, which Marcus took up.
- **(m) The mixing proposal and Marcus's four rulings** (§2). The P3 preview landed and is QUARANTINED
  (`outputs/quarantine/20261004_p3_q10_no_power/`, README).
- **(n) THE STRATIFICATION FEEDBACK BUILT** (DESIGN §3.4a S; `8567ef3`).
  - The mechanism: the upper part of K(z) × g, with g = (1 + s·T_key)^(−q/2), and the solved export rescaled with g.
  - The constants: s 0.052198 /K (Cheng 2025's N² trend over the key's trend), q 1 (Gargett 1984), and T_key = GMST
    − T_deep with a 195-yr lag (the climate module; model-derived).
  - Label `hilda_csl3v0kaidgbem`; **the NAME is Marcus's call.**
  - OFF is bit-exact.
  - Tests: `test-mixing-strat.R` 78/0; six label ledgers extended, each citing the ruling; the regression set (16
    files) 1441/0/0/1; mutations M1–M6 each caught by its own gate.
  - Checked: CCX's sink elasticity to kz is 0.149, not a column's 0.5. A √K estimate overstates CCX ~3.4×.
- **(o) The preview** (`calibration/diag_mix_preview.R` → `outputs/diagnostics/mix_preview_20261004.*`):
  - every registered mode −1.5 to −1.9 likelihood, unrefitted;
  - futures SMALL: SSP5-8.5 +2.5 ppm at 2100 and +5.5 at 2300 (q ½–2: +2.7 to +11.0), vvH +2.9, low scenarios ≈ 0;
  - the record mildly disfavours it (−1.40 at the cited s after kz);
  - CCX's EXISTING ocean climate effect (−0.43 GtC/yr, 2015–24 vs a 1901–20 climate held) against GCB's
    −0.20 ± 0.05 is NOT like-for-like and is OPEN (§4).

## 2. Rulings this session (Marcus, verbatim labels)
- The mixing mechanism: "Thermocline mixing only (Recommended)", "Obs × law, fixed (Recommended)", "GMST minus lagged
  deep ocean (Recommended)", "History + futures, one #16 refit (Recommended)".
- Asked, not yet answered: stop the (now landed and quarantined) P3 preview. Moot.
- Carried from 10-04b, still standing: "No row; draft card-4 text"; "Preview P3 with q10 freed" (done: P3 ≈ P0);
  "Canonical incumbent, Mac" (the `k_w` arm).

## 3. THE RUNNING JOB: the `k_w` = 1446 price arm (unchanged since 10-04b §3)
- Frozen tree `~/ccx_frozen/20261004f_kw1446` @`773f8f2`. Launch script `~/ccx_frozen/20261004f_kw1446_launch.sh`
  (PID in `…_launch.pid`, chain status in `…_launch.out`). 24 starts, 8 at a time, started 12:39 10-04.
- **At 19:46: 13 of 24 done (ids 0–11 and 13; 21 launched); expected to end ~00:00–01:00 10-05.** Two basins:

| basin (logpost) | ids | h_ml (m) | `u_hs` (m/yr) | `kz` (m²/yr) |
|---|---|---|---|---|
| **−1206.613** | 0, 5, 8, 9, 10, 13, and 11 | 57.7 | 15.2 | ~16,810 |
| −1206.837 | 1–4, 6 | 49.9 | 15.3 | ~17,087 |
| (id 7, stranded at the wall) | 7 | 75.39 | 16.6 | 11,236 |

  - Id 11 is flagged NOT converged (its wall budget ran out after the slow first restart) but sits in the best basin.
  - Id 7 is NOT converged at −1297.04.
  - The two basins are 0.22 apart and differ in h_ml. Read the price on the best, and report both.
  - What absorbs `k_w`: `u_hs` 23.3 → 15.2 and `kz` 14,224 → ~16,800 at hilda34g. These are the ridge partners
    memory `ccx_kw_hemispheric_balance` names.
- ⚠ **CHECK IT IS ALIVE** with `kill -0 $(cat ~/ccx_frozen/20261004f_kw1446_launch.pid)` (chain PID 64558) or
  `ps -axo pid,etime,command | grep run_dispersed_multistart`.
  - Never use a `pgrep -f` loop on the script name.
  - The exit codes collect in the tree's `logs/ccx_multistart_mac_20261004f_exit.txt` (24 lines when done).
  - "k_w price arm end" appears in `~/ccx_frozen/20261004f_kw1446_launch.out`.
  - The in-session watcher that would have landed it dies with this session.
- ⚠ **SLOW STARTS: a finding about the 10-04 (a) substep fix.**
  - Start 7's second restart took 250 min for 6,002 evaluations, 7.6× the normal rate. It ended at `h_ml` 75.39 m,
    ~0.1 m from the P8 wall (75.50 m), where the fixed controller needs 150–300 substeps instead of 4. Start 11 was
    slow too, then recovered.
  - The multistart's wall budget is checked only BETWEEN restarts, so one restart can overrun it. That is bounded on
    the Mac.
  - On Torch, under hard SLURM walls, it would KILL a task. **A design question before any Torch run:** an
    in-restart wall check, or a soft wall.
- **Landing steps** (10-04b §3, unchanged):
  1. Copy the outdir back byte-identical, with logs, preflight logs and `port_targets.csv`, plus a
     `RUN_PROVENANCE.txt`.
  2. `CCX_MS_OUTDIR=<dir> Rscript calibration/collect_dispersed_multistart.R`.
  3. `promote_multistart_mode.R --outdir=<dir> --name=kw1446_hilda_csl3v0kaidgbe`, then
     `recompute_hessian.R <mode> --update`.
  4. Read the PRICE on LIKELIHOOD against hilda34g's −1143.2508 on the 27 rows, with the `k_w` prior's term
     (lognormal(1446, 0.2)) at 1446 vs 1903 beside it. Compare with the conditional price (1783) and the Laplace one
     (~47). Run the scorecard with `CCX_SC_EXTRA_MODE=kw1446=<mode path>`, and name what absorbs `k_w`.
  5. Nothing is adopted.

## 3b. Files touched this session (all committed and pushed; last commit at writing `6795502`)
- **Model code (the stratification feedback, `8567ef3`):**
  - `R/model.R`: helpers `ccx_mix_on()`, `ccx_kz_upper()`, `ccx_mix_g_series()`, `ccx_mix_tdeep_after()`,
    `ccx_point_mix_g()`; `ccx_pump_export(…, kz_override)`; `ccx_prepare()` builds aux `mix_on` / `kz_up` /
    `pump_up`; `ccx_deriv()` applies both substitutions.
  - `R/forcing.R` (`ccx_forcing_at()`, the runner) and `R/cpp.R` (marshalling, `ccx_run_prepared(…, tdeep0)`,
    `ccx_deriv_fast`).
  - `src/ccx_core.cpp` (`Aux`, `deriv()`, `ccx_deriv_cpp()`, `ccx_run_cpp()`).
  - `R/constants.R` (`MIX_STRAT_S`, `_Q`, `_Q_LO`, `_Q_HI`, `MIX_TDEEP_TAU`).
  - `R/calibrate.R` (the label `hilda_csl3v0kaidgbem`).
  - `R/mechanisms.R` (`warming_feedback` zeroes `mix_strat_s`).
- **Spec:** `DESIGN.md` §3.4a S (`8f6e001`).
- **Tests:** NEW `tests/testthat/test-mixing-strat.R`. Label ledgers extended in `test-constants-batch`, `test-tr-box`,
  `test-gated-params`, `test-enso-lag`, `test-soil-inert` and `test-struct-v0`.
- **Drivers:** NEW `calibration/diag_p3_powered_step.R` (`b44e20b`) and `calibration/diag_mix_preview.R` (`1be5504`).
- **Outputs:**
  - `outputs/diagnostics/p3_powered_step_20261004.{log,rds}`;
  - `outputs/diagnostics/mix_preview_20261004.{log,rds}`;
  - QUARANTINED `outputs/quarantine/20261004_p3_q10_no_power/` (README + the P3 preview's three files).
- **Notes:**
  - NEW `notes/proposal_2026-10-04_warming_weakens_mixing.md` (rulings recorded at its top);
  - `notes/proposal_2026-10-04_npp_tsens_prior.md` (§5 revised: P0 vs P4);
  - this handoff.
- **CHANGELOG:** 10-04 (k) through (o).
- **Memory** (the shared store), NEW:
  - `block_power_is_per_name`
  - `magicc_ocean_no_hemispheric_carbon`
  - `ccx_strat_feedback_built`
  - `ccx_substep_fix_slows_nearwall_starts`
- **Memory**, updated: `ccx_greening_sign_set_by_lag`.
- **Memory**, pointers added in: `INDEX_ccx_phi`, `INDEX_diag_bound`, `INDEX_ccx_ocean_circ`, `INDEX_cmp_magicc`,
  `INDEX_ccx_ocean_struct` (14,255 B, just under its 14 KB soft budget) and `INDEX_infra`.
- **Pending:** nothing uncommitted. The full suite has not been re-run (§4 item 8).

## 4. Open items, in order (each is Marcus's to prioritise)
1. **Land the `k_w` price arm** (§3).
2. **Objective #16:** the greening decision plus the stratification feedback, then ONE refit (the D1 precedent). It
   waits on THREE rulings from Marcus:
   - (a) greening **P0 or P4** (`notes/proposal_2026-10-04_npp_tsens_prior.md` §5; P3 ≈ P0);
   - (b) the label name **`hilda_csl3v0kaidgbem`**;
   - (c) the refit's TIMING: after the `k_w` arm lands, ideally in a fresh session.
   - The feedback is already priced on every registered mode (CHANGELOG 10-04 o). The P0 / P4 choice would be priced
     the same way if it touches the objective (P4 is a pin).
3. **The ocean climate-effect benchmark:** verify GCB 2025's GOBM protocol (which "normal year"; when run A starts),
   then build a like-for-like comparison. CCX's existing −0.43 GtC/yr may or may not be too strong; per K it is
   −0.32.
   - Checked 10-04: the MAIN TEXT (ESSD 18:3211, the sim A–D paragraph and p. 3242) defines the effect as sim A
     minus sim C, "normal year climate forcing". It is "the combined effect of change and variability in all
     atmospheric forcing fields", winds included.
   - The main text does NOT say which year: read the supplement's GOBM table.
4. **Card 4 wording** (`notes/draft_2026-10-04_card4_enso_timing.md`).
5. **The hilda34g assessment's verdict** (`notes/assessment_2026-10-04_hilda34g_DRAFT.md` §5, §7).
6. **The multistart wall budget vs the new substep controller** (§3, the slow starts) before any Torch run.
7. Optional, needs a ruling: extend the substep fix's held-K rule to `ccx_tr_box_eigbound()`.
8. Housekeeping:
   - the remote branch `claude/pensive-burnell-a9bf40` could be deleted;
   - two old worktrees remain;
   - **the FULL suite has not been run since the build.** The 16-file regression set and the new file have. Run it
     when the machine is free (≥ 21 min).

## 5. Non-obvious state
- **The app preview** (`ccx-app`, localhost:7788) runs the PRE-build tree (R sources load at start). Restart it to pick
  up the build. Nothing visible changes: the feedback is off in the canonical.
- **The coupled futures hold GMST(1850) = −0.052 K back to 1750** (`approx(rule = 2)` in `ccx_run_coupled()`); the
  objective uses 0. Pre-existing, noted, not fixed.
- **MAGICC is restricted** (`~/Documents/2026/CodeProjects/MAGICC/DO_NOT_MAKE_PUBLIC.md`). Nothing from its tree is in
  this repo; cite M11. Its source-level specifics live in local memory only.
- **The mutation harness** (`mutate.py`) and the probes live in the session scratchpad, not the repo. CHANGELOG 10-04
  (n) records each mutation and its result.
- Compare on LIKELIHOOD, never on stored logposts, across pinned or price arms (unchanged).
- **The multi-line-shell lesson:** stage, check `git diff --cached --stat`, then commit, as separate steps.
