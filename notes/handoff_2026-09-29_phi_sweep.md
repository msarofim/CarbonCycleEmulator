# Handoff 2026-09-29: φ-like sweep done, van Vuuren menu shipped; the next step is Marcus's choice of refit

> Launch from `FaIRtoFrEDI/`, then `change_directory` here (CLAUDE.md). ⛔ **Never use a bare `cd` in a Bash
> call.** On 09-29 it moved the session into FaIRtoFrEDI. Use `git -C` or absolute paths.
> **Read first:** this file; then CHANGELOG **2026-09-28 (e)–(f)** and **2026-09-29 (a)–(d)**. Memory, via
> `INDEX_ccx_ref.md` / `INDEX_ccx_app.md`: `ccx_pulse_decay_is_the_veg_loop`, `ccx_phi_like_sweep_0929`,
> `ccx_app_menu_is_van_vuuren`.

---

## 1. What we were doing
The arc started with why CCX's CO₂ pulse decays faster than Joos / FaIR. It led to φ (`npp_veg_frac`), then
to the question "is anything else like φ?". Along the way the app's scenario menu moved to van Vuuren.

## 2. Results and rulings, in order
1. **φ = 0 Torch arrays, collected and scored (09-28 e/f).**
   - Free φ = 0 (job 18723994) reproduces the Mac start. It has two basins that differ only in `h_ml`
     (57 vs 50); the land is identical (`beta_max` 2.72, `fert_k` 938).
   - Shape-prior arm (`hilda_csl3v0k`, 18729847): `fert_k` 865 and **P1–P3 pass**. The prereg's
     "`fert_k` stays > 850" clause is **triggered**: the record resists the evidence-based shape.
   - Log-likelihood, all 29 free parameters: `hilda29l` −1391.81; φ 0 −1390.46 / −1389.47;
     φ 0 + shape −1391.10 / −1390.11. **The record cannot choose between them.**
   - ⚠ P1's exact optimality bound is on the free arm's OBJECTIVE, not bare log-lik (see 09-28 e).
     **Unruled:** whether to change the prereg wording.
2. **Marcus leans φ = 0** ("more physically sensible", 09-29). **NOT yet adopted**; the canonical is still
   `hilda29l`.
   - Historical: every scorecard gate is the same.
   - Pulse IRF(20/100/300): 0.509/0.288/0.207 → 0.493/0.342/0.250.
   - Futures: φ = 0 runs +14 to +28 ppm at 2100 in every vV marker, and **+219 ppm under H by 2300**. The
     φ 0.5 loop grows the land to 2.27× preindustrial.
   - No cited ESM benchmark for land carbon at 2300 has been found yet.
3. **Scenario menu → the seven van Vuuren markers (RULED, SHIPPED, `79b5751`).** See §3.
4. **The φ-like sweep (09-29 d, `86f004d`).**
   - No unfitted scalar behaves like φ; φ was the screen's power control and was flagged.
   - The live candidates are **fitted**:
     - **ENSO land channel.** The index is demeaned, not detrended (+0.0082/yr). Through
       `gamma_enso_land` that trend is a land source of −0.26 → +0.31 GtC/yr, and it vanishes in futures.
     - **`q10`.** The seasonal ridge sets the century feedback. At q10 = 2: −72.7 logpost, vvH 2300
       −45 ppm after rebalance vs +49 alone.
   - Untested audit flags: `NPP_GLOBAL_PI` 60 uncited; `f_luc_wood` 0; `kz_deep_frac` near its floor;
     the `gamma_diff` AOD background; `rep_dC` +3.5σ.
5. Housekeeping: `promote_multistart_mode.R` one-start crash fixed (`163a457`); the 09-28 frozen worktrees
   were removed (after checking their contents were archived).

## 3. Files (CCX `main`, all pushed; last commit `86f004d` + this handoff)
- **Archives:** `calibration/output/multistart_20260928b_hilda_csl3v0_…/` and
  `…_20260928c_hilda_csl3v0k_…/`, each with a `promoted_basin1/mode_fit_pumpN.rds` (a scratch mode file,
  NOT registered).
- **New drivers:**
  - `calibration/diag_phi0_futures.R` (arg `ssp` reproduces the unspliced 09-29 b run; the default is vV,
    GCB-spliced);
  - `calibration/diag_unfitted_screen.R`;
  - `calibration/diag_q10_ridge_futures.R`.
- **Van Vuuren:**
  - `data-raw/build_vv_scenarios.R` → `data/vv_emissions.rds`, `data/forcing_climate_vv.rds`;
  - core `ccx_scenario_emissions()` (R/forcing.R) and `ccx_climate_table()` (R/climate.R);
  - app `APP_SCENARIOS` / `APP_SCEN_EMIS` / input `f_scen`;
  - the pulse-lab constants re-measured on vvM (1.03 per 1000 GtC).
- **FaIRtoFrEDI:** `scripts/run_fair_vv_for_ccx.py`, committed `5e956d4` on **`heat-ed-morbidity`**, NOT
  pushed. That branch has Marcus's WIP; do not push or touch his files.
- **Outputs:** `outputs/diagnostics/{unfitted_screen,q10_ridge_futures,phi0_futures_vv,phi0_futures_ssp,
  pulse_vs_tcre,whole_model_scorecard_*_vs_phi0,suite_*}_20260929.*`

## 4. Open questions / next step (all Marcus's to rule)
1. **Which refit next?** Both are Torch arrays like the φ arms:
   - (a) ENSO: needs a new detrended-index switch in `R/forcing.R`, which does not exist; then refit and
     read `q10`, `beta_max` and 2300 CO₂.
   - (b) `q10`: split into `q10_seas` / `q10_long`, refit, and see where `q10_long` goes.
   - Probably do (a) first, since it may be why `q10` is low. Run both on φ = 0 if it is adopted.
2. **Adopt φ = 0?** Which basin and which arm (free or shape prior)? It would need `recompute_hessian`,
   registration and an app repoint.
3. The menu's parenthetical descriptors are **drafts** awaiting Marcus's wording (`app/global.R`,
   `APP_SCENARIOS`).
4. The prereg P1 wording (§2.1).
5. A cited ESM benchmark for land-carbon change by 2300 under high emissions, to judge φ's 2.27× vs 1.65×.

## 5. Non-obvious state and traps
- **Nothing is running:** no Torch jobs, no local jobs. The Torch login expires often; Marcus re-auths
  with `ssh torch true`.
- **Suite at `79b5751`: only the named red** (`test-mode-file.R:323`, AIC; do not "fix" it).
- Two tests were changed with the menu spec (renames, assertions kept): `test-fair-overlay.R` and
  `test-stylised-takeaway.R`.
- **Any driver that runs a scenario OUTSIDE the app must splice GCB itself** (see `fut_emissions()`
  in `diag_phi0_futures.R`). Otherwise it inherits the scenario's own land-use history, which for the SSPs is
  90 GtC short.
- `diag_pulse_spline_ringing.R` and `diag_app_cross_tab_step.R` still name `APP_SSP_EMIS` / SSP keys
  (deliberately left; if rerun they fail by name).
- The `diag_pulse_vs_tcre.R` ANCHOR is a reading off the running app (1.03). Re-read it by hand if the
  background changes.
- Frozen-vector costs mislead for this question (φ frozen −11,615, refit +1.3). Always rebalance or
  refit.
- The app server logs two "figure margins too large" warnings in the 800×600 preview; thought to be the
  viewport, unconfirmed.
- The memory indexes `INDEX_ccx_app.md` (16.2 KB) and `INDEX_ccx.md` (15.7 KB) are over the 14 KB soft
  budget and under the 18 KB hard one.
- `carbotopecomment.9.26.26.docx` is untracked and belongs to Marcus; leave it alone.
