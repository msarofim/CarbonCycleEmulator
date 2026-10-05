# HANDOFF 2026-10-05 — the `k_w` arm LANDED (its price is a prior conflict), the ocean benchmark like-for-like, option A and the H1 switch BUILT; objective #16 waits only on P0 vs P4

**Supersedes** `notes/handoff_2026-10-04c_strat_feedback_kw_running.md`. Written on Marcus's request ("Then write a
handoff"). Self-contained.

**Start here.**
1. Read this note.
2. Then CHANGELOG 2026-10-05 (a)–(d) and 2026-10-04 (p), newest at the top of `CHANGELOG.md`.
3. Then these memory files (shared store):
   - `ccx_ocean_climate_effect_vs_gcb` (new 10-04 p; H1 added);
   - `ccx_kw_hemispheric_balance` (the price arm's verdict);
   - `ccx_substep_fix_slows_nearwall_starts` (resolved by option A);
   - `switch_test_at_defaults_has_no_power` (its second incident);
   - `mutation_test_gates` (the error-is-not-a-catch instance);
   - `ccx_greening_sign_set_by_lag` (P0 vs P4 background).

## 1. What was done
- **The ocean's climate effect, like-for-like with GCB 2025** (10-04 p; `calibration/diag_ocean_climate_gobm.R`).
  - GCB's protocol is verified from its Supplement (Table S2): there is NO single normal year. Six models use
    1957–1969, two use 1990, two use climatologies.
  - Each model's protocol was emulated with CO₂ prescribed and SST + the L2 ENSO limb.
  - **CCX −0.357 ± 0.027 vs GCB −0.20 ± 0.05 GtC/yr (1.8×); −10.0 % of the CO₂ effect vs −7.1 % (range −4.2 to
    −10.7).**
  - The thermal part alone is −0.45: 3.4× FESOM-REcoM's warming part under the same protocol (Bunsen 2024).
  - The first version missed the L2 ENSO limb. It is quarantined:
    `outputs/quarantine/20261004_ocean_climate_sst_only/`.
- **The `k_w` = 1446 price arm LANDED** (10-05 a):
  - 18/24 converged, two basins 0.224 apart;
  - promoted → `calibration/output/refit_20261005_kw1446_hilda_csl3v0kaidgbe/`;
  - read by `calibration/diag_kw1446_price_read.R`.
  - **On likelihood 1446 fits BETTER (+2.75).** The −20 posterior price is all `hs_asx_frac`'s prior (z +6.5),
    whose log-sd 0.15 is a stated JUDGEMENT. So `k_w` ≈ 1903 is a prior compromise, not a data verdict.
  - Hessian PD, but `h_hs` sits at 472.6 of its 500-m bracket, so the arm's own Laplace sds are not usable.
  - The scorecard: no gate verdict flips.
- **Option A BUILT** (10-05 b; `92b5756`): the multistart's in-restart deadline (`calibration/lib_ms_deadline.R`).
  - Tests `test-ms-deadline.R` 36/0, mutations M1–M7; a smoke run passed.
  - It also found and fixed a lazy-evaluation hazard.
- **The H1 switch BUILT and TESTED** (10-05 c; `777877b`): `hs_sst_anom_frac`, DESIGN §3.4a T. Absent = 1 is
  bit-exact; it is not fitted.
  - Tests `test-hs-sst-frac.R` 24/0, mutations M1–M5.
  - **The HS box carries only ~18 % of the thermal effect.** At frac 0, unrefitted, the thermal part goes
    −0.453 → −0.371, at −18.2 likelihood.
  - The excess lives in the low-latitude column (H2).
- **Suites:**
  - at `27d435b`: **6156 passed, 0 failed, 3 skipped**, the first since the stratification build;
  - at `777877b` (the switch): ⚠ **it did NOT finish.** It started at 07:14 in the frozen worktree
    `~/ccx_frozen/20261005_suite_777877b`. Its process died at ~07:27 inside `test-pump-seas.R` (file 88 of 112),
    with no summary line and 0 failures or errors so far, most likely with the session that launched it. The
    partial log is kept at `outputs/diagnostics/suite_20261005_777877b.log`.
    - **Re-launched** at 08:15 under `nohup` (`~/ccx_frozen/20261005_suite_777877b_rerun_launch.sh`), logging to
      `…_777877b_rerun.log`.
    - Its result goes into CHANGELOG 10-05 (d) and this line.

## 2. Rulings (Marcus, verbatim)
- 10-05: "1) Yes, test. 2) give me pros and cons. 3) Keep. 4) Option A. Then write a handoff."
  - 1 = the H1 test (done, §1).
  - 2 = P0 vs P4 (§4).
  - 3 = the label `hilda_csl3v0kaidgbem` is KEPT.
  - 4 = option A (built).
- Standing from 10-04: the mixing rulings ("Thermocline mixing only", "Obs × law, fixed", "GMST minus lagged deep
  ocean", "History + futures, one #16 refit"); "No row; draft card-4 text"; "Canonical incumbent, Mac".

## 3. Files touched this session (all committed and pushed)
- **New drivers:**
  - `calibration/diag_ocean_climate_gobm.R` (with `CCX_OC_HS_FRAC`);
  - `calibration/diag_kw1446_price_read.R`.
- **New library:** `calibration/lib_ms_deadline.R`.
- **Changed driver:** `calibration/run_dispersed_multistart.R` (option A).
- **Model:** `R/model.R` (`ccx_hs_sst_frac()` and the HS SST line), `R/cpp.R` (marshalling), `src/ccx_core.cpp`
  (`Par.hs_sst_anom_frac`).
- **Spec:** `DESIGN.md` §3.4a T (new); §3.4a S's benchmark line updated.
- **Tests (new):** `tests/testthat/test-ms-deadline.R`, `tests/testthat/test-hs-sst-frac.R`.
- **Notes:**
  - `notes/proposal_2026-10-04_multistart_inrestart_wall.md` (ruled A);
  - this handoff.
- **Outputs:**
  - `outputs/diagnostics/ocean_climate_gobm_20261004.*` and `ocean_climate_gobm_20261005_hsfrac{0.5,0}.*`;
  - `kw1446_price_read_20261005.*`;
  - `whole_model_scorecard_20261005_kw1446.log` and `whole_model_scorecard_20261005_hilda34g.rds`;
  - `suite_20261005_27d435b.log` and `suite_20261005_777877b.log`;
  - the quarantine `outputs/quarantine/20261004_ocean_climate_sst_only/`.
- **Landed arm:**
  - `calibration/output/multistart_20261004f_…_k_w=1446_…/` (starts, logs, preflight, `RUN_PROVENANCE.txt`, port
    targets, collect log);
  - `calibration/output/refit_20261005_kw1446_hilda_csl3v0kaidgbe/` (mode file with Hessian, promote and Hessian
    logs).
- **Memory:**
  - new: `ccx_ocean_climate_effect_vs_gcb`;
  - updated: `ccx_kw_hemispheric_balance`, `ccx_substep_fix_slows_nearwall_starts`, `ccx_strat_feedback_built`,
    `switch_test_at_defaults_has_no_power`, `mutation_test_gates`;
  - pointers in `INDEX_ccx_ocean`, `INDEX_ccx_ocean_circ`, `INDEX_infra`, `INDEX_diag_bound`.

## 4. P0 vs P4 — the pros and cons Marcus asked for (the decision is his)
> ⛔ **RULED 2026-10-05 (Marcus): "p4".** `npp_tsens` is pinned at 0 in #16 (CHANGELOG 10-05 d).
> ⚠ The "MASKS" bullet under "Against P0" overstates it, because in GtC the total's error (0.76) is larger than
> the ocean's (0.16). The accurate statement: the ocean's excess hides the land's SIGN.

**The choice.**
- P0 keeps `npp_tsens` (NPP × exp(σ·GMST)) free under its sign-free prior: +0.0089 /K at hilda34g, about 1 sd
  from zero.
- P4 pins it at 0.
- Background: `notes/proposal_2026-10-04_npp_tsens_prior.md` §5 and memory `ccx_greening_sign_set_by_lag`.
- P3 (a GCB row with `q10` freed) was previewed and ≈ P0.

| | **P0 — keep the fitted term** | **P4 — pin it at 0** |
|---|---|---|
| likelihood | best (by 0.26) | −0.26: negligible |
| SSP5-8.5 CO₂ at 2300 | baseline | **+13.5 ppm** |
| land net climate effect, 2015–24 (TRENDY S2−S1 definition; GCB −0.8 ± 0.7) | **+0.12, the wrong sign** | −0.04: about 0, still not GCB's |
| what sets the term | the land ENSO lag: 89–92 % of the sign flip; −0.0079 at lag 0 | nothing |
| literature | runs against 8 of 10 CMIP6 ESMs (γ_NPP < 0; Varney 2024) | neutral |
| app message | "warming slightly boosts plant growth" (weakly supported) | "the model does not claim a direct warming effect on growth" |
| bookkeeping | no change for this item | a pin: one fewer free name, compared on likelihood. It goes into #16's one refit anyway. |

**For P0:**
- It keeps what the record weakly prefers, at no cost.
- It is not an objective change for this item.
- The futures are 13.5 ppm lower.

**Against P0:**
- The sign is not identified (~1 sd).
- It rides a cross-timescale coupling (the ENSO lag) and has already flipped once with an unrelated structural
  change.
- It disagrees with most ESMs.
- It leaves a wrong-signed land climate effect for the app to explain.
- ⚠ New from 10-04 (p): it MASKS the ocean's too-strong climate effect. Land + ocean is −0.24 GtC/yr against GCB's
  ≈ −1.0, so the total looks less wrong than either part.

**For P4:**
- No fitted term whose sign the record cannot fix.
- Easy to explain.
- It removes the wrong-signed land effect and the futures' dependence on the ENSO-lag coupling.
- It costs 0.26.

**Against P4:**
- +13.5 ppm in the app's 2300 numbers.
- It still cannot reach GCB's −0.8: that needs a decadal soil pool, a structural question beyond #16.
- It discards even a weak signal that a later structure might firm up.

## 5. Open items, in order (each is Marcus's to prioritise)
1. **Objective #16.** ~~It waits ONLY on (a), P0 vs P4 (§4).~~ **(a) RULED P4 (10-05)**: the ten pins are the nine
   plus `npp_tsens=0`, leaving 33 free names (checked with the driver's own pin functions). Now it waits on where
   to run it and on the two fold-in questions below.
   - (b) The label is KEPT.
   - (c) Timing: the `k_w` arm has landed, so it can go. Ideally in a fresh session, on Torch or the Mac (say the
     verdict out loud).
   - The refit carries the stratification feedback, plus the greening choice if it is P4.
   - Option A is now in the driver. Regenerate `calibration/torch/port_targets.csv` for the arm first: the repo's
     copy is a stale 32-parameter set from 09-21.
   - Two questions Marcus may want to fold in or defer:
     - `hs_asx_frac`'s judgement width, which decides `k_w` (§1);
     - H2 (item 2).
2. **H2, the ocean thermal excess in the low-latitude column.**
   - The candidates:
     - a time-shape comparison against GCB Fig. S10 per protocol (cheap);
     - a refit at a lower kz (expensive; kz is held by the sink and bomb rows);
     - a structural surface-DIC damping in the spirit of Bunsen 2024 (a proposal).
   - Not started. Marcus's call.
3. **H1's observed-ratio arm.** It needs a gridded SST download (HadSST4 or HadISST1, ~tens–hundreds of MB),
   which needs his permission. The 0 and ½ arms already bracket it.
4. Card 4 wording (`notes/draft_2026-10-04_card4_enso_timing.md`): his text.
5. The hilda34g assessment's verdict (`notes/assessment_2026-10-04_hilda34g_DRAFT.md` §5, §7).
6. Optional, needs a ruling: extend the substep fix's held-K rule to `ccx_tr_box_eigbound()`.
7. Housekeeping, needing his OK:
   - delete the frozen `k_w` tree `~/ccx_frozen/20261004f_kw1446` (its outputs are in the repo, byte-identical);
   - delete the remote branch `claude/pensive-burnell-a9bf40`;
   - the two old `.claude/worktrees/` (`compassionate-leavitt-a7e631`, `youthful-blackburn-fbc009`).

## 6. Non-obvious state
- **The app preview** (`ccx-app`, localhost:7788) runs a tree from before the stratification build and the H1
  switch. Restart it to pick them up. Nothing visible changes: both are off in the canonical.
- **Comparing arms:** across pinned or price arms, compare on LIKELIHOOD, never on stored logposts.
- **`CCX_OC_HS_FRAC`** on the like-for-like driver tags its outputs `_hsfrac<f>`. R0's identity gate with §D applies
  only at f = 1.
- **The CO₂-prescription technique** (`match_co2()` in that driver), reusable:
  - an output row is the START-of-month state, so lead by one row;
  - the NH−SH difference needs a SUSTAINED flux kh (dG/dt + 2G/`tau_ex`).
- **A frozen tree from BEFORE `92b5756`** still has the old multistart overrun behaviour.
- **Carried:**
  - the coupled futures hold the 1850 GMST (−0.052 K) back to 1750 (pre-existing, noted);
  - MAGICC is restricted (cite M11).
- **The multi-line-shell lesson:** stage, check `git diff --cached --stat`, then commit, as separate steps.
