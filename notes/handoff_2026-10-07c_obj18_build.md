# HANDOFF 2026-10-07c — THE REDESIGN PRICED AND RULED; NEXT: BUILD OBJECTIVE #18

> ⛔ **SUPERSEDED by `notes/handoff_2026-10-07d_obj18_stage2_running.md`.** Items 1–6 below RAN on 2026-10-07 (CHANGELOG
> 10-07 h, i): #18 built (every parity target exact), stage 1 run, priced, basin B registered as `hilda29w`, and stage 2
> LAUNCHED on the Mac. Read the new note, not this one.

**Supersedes** `notes/handoff_2026-10-07b_obj17_landed.md`, which now points here.
- Written on Marcus's ruling, verbatim: "Handoff now, build fresh (Recommended)".
- The next step is ruled: build #18 `hilda_csl3v0kaidgbemwt` (§3).

**Start here.**
1. CHANGELOG 2026-10-07:
   - (d) the price;
   - (e) the ridge correction (read it: it withdraws a line of (d));
   - (f) the rulings and the build list.
2. Memory, shared store:
   - `ccx_iav_cut_previewed`: the arc; its last four bullets are this session;
   - `block_refit_futures_can_be_ridge_position` (new): why (d)'s "+23 ppm" was withdrawn;
   - `interannual_name_needs_trendless_forcing`: detrending has its own price;
   - `basin_rank_by_logit_jacobian` and `objective_noise_floor_optimum_on_spike`: both bind the landing.

## 1. Where things stand
- **#17 is landed, not adopted** (10-07 a). Basin B is its representative (RULED 10-07 b).
- **The redesign, priced at B** (10-07 d / e; `calibration/diag_iav_redesign_price.R` @`e891fa9`). The redesign is #17 + the DETRENDED ENSO index + `gcb_ocean_sink` scored on its LOW-PASS part.
  - **Resistance to `w_enso_l2` (14.73 → 16.71) on the whole main objective:** #17 −1.29; low-pass ocean row alone −0.74; detrended index alone −0.66; **both −0.10**.
  - **Stage 1 is index-blind** (≤ 0.08σ). At B: lag 5.8483, scale 1.2978, `w` 16.6051.
  - **No pump ratchet:** `pump_grad` and `kz` re-optimized at the higher `w` move ≤ 0.05 sd.
  - **The detrended index costs ≤ −7.6 in fit at this basin**, almost all in the ice cores. It is an upper bound: re-optimizing more names can only do better at this basin.
  - **The futures:** the index's own effect is +6.3 to +7.2 ppm (SSP5-8.5, 2300) at a fixed `beta_max`. (d)'s "+23" was mostly a slide along the `beta_max`/`fert_k` ridge. MEASURED, 2300 CO₂ spans about **±35 ppm at 1σ** along that ridge alone (natural space; non-Gaussian).
- **Code:** `main` at this note's commit, pushed. Since the 10-07 suite (`a6cf879`, CLEAN 6598 / 0 / 3) only `calibration/diag_*` drivers changed. No `R/`, no tests.

## 2. Rulings this session (verbatim, AskUserQuestion)
- the design: "Full redesign (Recommended)";
- the seasonal rows' interannual part: "No, keep them (Recommended)";
- stage 1's base: "Basin B (Recommended)";
- the label: "hilda_csl3v0kaidgbemwt (Recommended)" (t = trendless);
- "Handoff now, build fresh (Recommended)";
- the frozen trees: "Remove both (Recommended)". Done by MOVING them to the macOS Trash (reversible), after checking every file against the repo. Emptying the Trash is Marcus's.

## 3. NEXT: BUILD #18 (no stage-2 launch without the gates below)
1. **`R/likelihood.R`: a `gcb_ocean_lowpass_df` switch**, the twin of `gcb_land_lowpass_df`.
   - Copy it in `ccx_err_with_struct()`.
   - In `ccx_loglik()` the ocean row becomes `row_o + ccx_land_highpass_cost(tgt_o - g$ocean, g$year, df, LIK_GCB_OCEAN_SD)`.
   - Absent = `identical()` to now, on every registered mode, as #17's tests held.
2. **`R/calibrate.R`: `ccx_struct_hilda_csl3v0kaidgbemwt()`** = #17's block + `enso_index` = `CCX_ENSO_INDEX_CODES[["detrend"]]` (1) + `gcb_ocean_lowpass_df` = `LIK_LAND_LOWPASS_DF` (6).
   - Register it: `CCX_STRUCT_LABELS`, `ccx_struct_block()`, and `CCX_MODE_OBJ18_*` constants on the model of `CCX_MODE_OBJ17_*`.
   - Add a `ccx_ms_reference_set()` rule. #16's build found it STOPS on an unknown pin set: call it dry before any launch (CHANGELOG 10-05 e).
   - Every consumer that builds forcing must carry the index. `ccx_enso_index_check()` refuses a mismatch, so a missed consumer STOPS rather than runs silently. Grep for `ccx_build_forcing(` anyway.
3. **Tests**, with `tests/testthat/test-iav-cut.R` as the template: the switch's exact split; other labels bit-identical; and **PARITY WITH THE EMULATION** (`outputs/diagnostics/iav_redesign_price_20261007.rds`).
   - At basin B's vector with its own pins (P0), under #18: logpost **−1173.052374**, likelihood **−1137.127378**.
   - The low-pass ocean row there is **−3.745088** (full −8.256639; high part 4.511551).
   - **B1 = −12.342383** against B on the redesign's rows; the reference is logpost −1160.709992, likelihood −1124.784995, i.e. B with the low-pass ocean row under the shipped index.
   - The 10-06 build reproduced its emulation to 3.7e-11; expect the same, and gate it at ≥ 1e-5 (the noise floor).
4. **Stage 1 at basin B under #18.** `fit_iav_module.R` cannot run it as it stands: its GATE 0 needs the base's stored rows, and B's file is #17's.
   - The tested pattern is `diag_iav_redesign_price.R`'s `stage1()`: gate the base AS STORED under its own label, then switch the structure. Its CONTROL reproduced both stored stage-1 runs exactly.
   - Something like `--struct=hilda_csl3v0kaidgbemwt` would do it. The module's rows do not read the ocean switch; only the index matters to it.
   - **Parity target** (same rds, `$stage1$B_detrend`): lag 5.84830781045950, γ NH 0.658977311797207, γ SH 0.631559462206096, `w_enso_l2` 16.6050643123222. The run's `ssr_ref` was 89.825775. The mirror ran the same code path, so expect EXACT.
5. **Price the built #18 at B**, as `diag_obj17_price.R` did for #17. B1 must equal the emulation's.
   - The stage-1 values at B differ from P0 by a +1.47σ `w`, so price both.
   - Show the futures against the ±35-ppm ridge ([[block_refit_futures_can_be_ridge_position]]): a future that moves less than the ridge's width is not a finding.
6. **Stage 2.** The multistart under #18 with the module pinned at stage 1's values; the incumbent seed is basin B's vector.
   - Say the Torch verdict out loud.
   - Run it on the Mac overnight, from a frozen tree.
   - Land it with #17's chain as the template (`outputs/diagnostics/obj17_landing_20261007/land_chain.sh`). Dry-run the chain on the first finished start: for #17 it caught two bugs.
7. **At the landing:** decompose the basins (likelihood / prior / Jacobian) BEFORE promoting. `promote_multistart_mode.R` has no `--id` and always takes the best stored logpost ([[basin_rank_by_logit_jacobian]]). Check whether the full refit recovers the ice-core cost.

## 4. Non-obvious state
- **The ridge:** along `beta_max`/`fert_k`, 2300 CO₂ spans ~±35 ppm at 1σ. The natural-space and u-space optima differ: #17's `beta_max` is 2.163 vs B's stored 2.099, about 7 ppm. Read any #18-vs-#17 futures difference against this.
- **Under #17 the likelihood alone still rises at `beta_max` 2.55.** The u-space upper side is closed by `beta_max`'s logit Jacobian near its band edge (3), not by data.
- **The noise floor** (~1e-6): every reproduce-gate needs ≥ 1e-5.
- **`h_ml`'s Hessian is UNSTABLE** at both #17 basins. The cut posterior ("Laplace + propagation", RULED, not built) needs care along `h_ml` and along the fertilization ridge ([[laplace_fails_on_fertilisation_ridge]]).
- `tests/testthat/test-review-card-numbers.R` fails BY DESIGN on any adoption that moves the lag. Update the copy WITH Marcus, not the test.
- `calibration/torch/port_targets.csv` still holds the canonical's targets.
- The app preview (localhost:7788) is not running.
- Two Claude-session worktrees exist under `.claude/worktrees/` (`compassionate-leavitt-a7e631`, `youthful-blackburn-fbc009`, detached). Not examined this session.
- Still separate, carried: the cut posterior; the app copy (card 4, the What-if numbers, the wobble shares); `gamma_diff`'s own future.

## 5. Files from this session
- **Code:**
  - `calibration/diag_iav_redesign_price.R` (the emulation; B1/B2/B3; the stage-1 mirror; the resistance; the ratchet; the futures);
  - `calibration/diag_iav_index_slow_flux.R`;
  - `calibration/diag_iav_redesign_futures_attr.R`;
  - `calibration/diag_iav_redesign_ridge.R` (`CCX_RF_EXTRA`, `CCX_RF_TAG`);
  - `calibration/diag_iav_redesign_ridge_read.R`.
- **Outputs**, under `outputs/diagnostics/`:
  - `iav_redesign_price_20261007{.log,.rds,_stdout.log}`;
  - `iav_redesign_price_20261007_gate_mutation/`: the harness and six mutations, all stopping at their own gate;
  - `iav_index_slow_flux_20261007.*`;
  - `iav_redesign_futures_attr_20261007.*`;
  - `iav_redesign_ridge_20261007{,_wide}.*` and `iav_redesign_ridge_read_20261007{,_wide}.*`.
