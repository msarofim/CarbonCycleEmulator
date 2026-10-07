# HANDOFF 2026-10-07b — OBJECTIVE #17 LANDED AND READ; NEXT: PRICE A REDESIGNED CUT

> ⛔ **SUPERSEDED by `notes/handoff_2026-10-07c_obj18_build.md`.** The pricing below RAN on 2026-10-07 (CHANGELOG
> 10-07 d, e) and Marcus ruled the build (10-07 f): objective #18 `hilda_csl3v0kaidgbemwt`. Read the new note, not this one.

**Supersedes** `notes/handoff_2026-10-07_obj17_finished.md`, which now points here.
- Written on Marcus's ruling, verbatim: "Handoff now, continue fresh (Recommended)".
- The next step is ruled too, verbatim: "Price a redesigned cut (Recommended)". §3 below.

**Start here.**
1. CHANGELOG 2026-10-07 (a) (the landing and its read) and (b) (the rulings and the resistance split).
2. Memory, shared store:
   - `ccx_iav_cut_previewed`: the arc; its last two bullets are this session;
   - `interannual_name_needs_trendless_forcing`: why `w_enso_l2` is not interannual-only;
   - `basin_rank_by_logit_jacobian`: why basin A won the promote and lost on likelihood;
   - `objective_noise_floor_optimum_on_spike`: the ~1e-6 floor; any new reproduce-gate needs ≥ 1e-5.

## 1. Where things stand
- **#17 is landed, read and NOT adopted.** RULED 10-07: "Not yet: settle w first (Recommended)".
- **Basin B is #17's representative.** RULED: "B: better likelihood (Recommended)".
  - B leads on likelihood by 0.761.
  - A (promoted id 10, `h_ml` 58 m) leads the stored logpost by 0.409, only through `h_ml`'s logit Jacobian (+0.686) near the 42.5 m band floor.
  - B's file: `calibration/output/refit_20261006_obj17_basinB_start001_DRYRUN/mode_fit_pumpN.rds`. It is the dry run's promote of start_001, cmp-identical, with a PROVENANCE note. B's best starts (ids 2 / 4 / 5) are 3e-6 higher: the same point within the noise floor.
- **The land half of the cut holds.** The one-pass check moves the lag +0.044σ and the land scale −0.007σ at A (+0.010σ / −0.021σ at B). GATE V flips FAIL → PASS at both basins. That PASS is IN-SAMPLE (same growth record), so don't quote it as validation.
- **The ocean half does not.** The check moves `w_enso_l2` +2.31σ at A and +1.55σ at B (14.73 → 16.71).
  - Why: stage 2 lowered `pump_grad` (84 % of the slope drop at B; at A, 62 %, plus `h_ml` 28 %).
  - Restoring w costs the main objective −1.29 at B, unrefitted.
  - Split by the cut's own projector:
    - about half is INTERANNUAL: `gcb_ocean_sink` year by year −0.55, and the seasonal rows −0.24;
    - about half is the CO₂ level rows at LOW frequency, −0.78. That half is the shipped ENSO index's +0.0083 K/yr TREND, carried by the limb: on the detrended index it falls 89 %.
- **Code:** `main` at this note's commit, pushed. The full suite at `a6cf879` is CLEAN, 6598 / 0 / 3. Since then only `calibration/diag_*` drivers changed (no `R/`, no tests).
- **The gate ruling:** `fit_iav_module.R` `IAV_REPRO_TOL` = 1e-5 (`60eba2a`; "Raise to 1e-5, named (Recommended)"), mutation-tested.

## 2. Rulings this session (verbatim, all via AskUserQuestion)
- the check gate: "Raise to 1e-5, named (Recommended)";
- adoption: "Not yet: settle w first (Recommended)";
- the basin: "B: better likelihood (Recommended)";
- the w path, first round: "Test low-pass ocean row first (Recommended)" — done, CHANGELOG (b);
- the trees: "Remove all three (Recommended)" — done after cmp;
- the w path, second round: **"Price a redesigned cut (Recommended)"**;
- "Handoff now, continue fresh (Recommended)".

## 3. NEXT: PRICE THE REDESIGNED CUT (no build, no refit)
All of it is at basin B, against #17 as landed. The redesign is the arithmetic of CHANGELOG (b): #17 + the DETRENDED ENSO index + a LOW-PASS `gcb_ocean_sink` row. The five rows' resistance to w would fall from −1.31 to about −0.14; that is untested as a design. Price:
1. **The main objective's cost of the redesign at B, unrefitted**, then with a block re-optimised (as the 10-06 pricing did with `calibration/lib_block_reopt.R`, B1 / B2).
   - The detrended index changes the land ENSO term's slow part too (the 09-29 d audit: a land source rising −0.26 → +0.31 GtC/yr under the shipped index).
   - The split's detrend run is 7.2 log-units off the stored rows at stage 1's pins: that is the size to expect, before re-optimisation.
2. **Stage 1 under the detrended index at B's vector.** Does the land answer (lag 5.84, ×1.30) hold, and where does w land?
   - `fit_iav_module.R` cannot do this as it stands. Its base must reproduce its stored rows (`IAV_REPRO_TOL`), and a base switched to the detrended index will not.
   - So it needs either a pricing driver that runs the module at a hand-switched base (as `diag_obj17_slope_attribution.R` switches names), or the new label first.
3. **The resistance to w that is left**, on the WHOLE main objective, not just the five rows. `diag_obj17_resistance_split.R` reports only the five rows under `CCX_RS_ENSO_INDEX=detrend`. Add the low-pass ocean row as a scored alternative and report all rows.
4. **The futures** (SSP5-8.5 / vvH 2300) at the priced point, as `diag_obj17_refit_read.R` §5 does.
- ⚠ The 09-29 (f) price of the index axis (detrending −1.3 to −2.9; futures ≤ 1.4 ppm) was at φ = 0 under an older objective. It is NOT a price for this.
- **Open design questions to put to Marcus WITH the price, not before:**
  - whether the seasonal rows' interannual part (the per-year harmonic coefficients; −0.24 at B) also leaves the main objective;
  - whether the detrended index applies to the land term as well (it does by construction: one index);
  - the label name (#18?).
- Then: build, stage 1, the stage-2 refit overnight on the Mac (say the Torch verdict out loud), the landing chain. #17's chain is the template: `outputs/diagnostics/obj17_landing_20261007/land_chain.sh`. Dry-run it on the first finished start; it caught two bugs for #17.

## 4. Non-obvious state
- **Adoption at basin B has no clean promote path.** `promote_multistart_mode.R` always promotes the best stored logpost (A), and has no `--id`. Adopting #17 (or a successor) at a chosen basin needs that option, or the decomposition-first rule of `basin_rank_by_logit_jacobian`, built into collect / promote.
- **The noise floor:** both optima sit on its upper tail (every 1e-12 nudge moves them down). Its SOURCE is unidentified; a candidate is the 12C conveyor spinup's stopping rule ("did not converge |resid| ~5e-8" in the task logs).
- **Hessians:** `h_ml` is UNSTABLE at both #17 basins (17 % / 376 %), where hilda33p's was stable. The cut posterior ("Laplace + propagation", RULED, not built) will need care along `h_ml`.
- **Frozen trees:**
  - `~/ccx_frozen/suite_20261007_a6cf879` remains; its log is in the repo, so it is removable on Marcus's OK;
  - `20261006x_obj17`, `20261006o_obj17_dryrun` and `20261007_obj17_drivers` are removed, everything checked into the repo first.
- `main`'s `calibration/torch/port_targets.csv` still holds the canonical's targets. #17's are in the outdir as `port_targets_hilda_csl3v0kaidgbemw.csv`.
- The app preview (localhost:7788) is not running. `tests/testthat/test-review-card-numbers.R` will fail BY DESIGN on any adoption that moves the lag: update the copy WITH Marcus, not the test.
- Still separate, from the earlier handoff: the cut posterior; the app copy (card 4, the What-if numbers, the wobble shares); `gamma_diff`'s own future.

## 5. Files from this session
- Code:
  - `calibration/fit_iav_module.R` (`IAV_REPRO_TOL`);
  - new drivers: `calibration/diag_obj17_{slope_attribution,basins,iterate_price,lowpass_ocean_price,resistance_split}.R` and `calibration/diag_objective_noise_floor.R`.
- Outputs:
  - `calibration/output/{multistart_20261006o_*,refit_20261007_obj17_*,refit_20261006_obj17_basinB_start001_DRYRUN,iav_module_20261007_refit_*.rds}`;
  - `outputs/diagnostics/obj17_landing_20261007/` (every step, the failed 1e-6 check, the gate's mutation harness);
  - `outputs/diagnostics/{obj17_refit_read,obj17_slope_attribution,obj17_basins,objective_noise_floor,obj17_iterate_price,obj17_lowpass_ocean_price,obj17_resistance_split,ocean_climate_gobm,whole_model_scorecard}_20261007*`;
  - `outputs/diagnostics/suite_20261007_a6cf879.log`.
