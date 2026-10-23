# HANDOFF 2026-10-23: CH₄ and CFC priced and ruled out; gate 6 stays in situ; refit item 1 done; item 2 is next

**Supersedes** `notes/handoff_2026-10-22_flask_label_refit.md`, which now points here. Written on Marcus's request ("Write the
handoff"), 2026-10-23.

- **Start here:** CHANGELOG **2026-10-22 (j)** and **2026-10-23 (a)–(c)**; this note's §3. Memory: `ccx_fossil_ch4_oxidation_omitted`
  (`INDEX_ccx_inputs.md`), `ccx_cfc_inventory_no_power` (`INDEX_ccx_ocean.md`), and for the flask arc
  `ccx_seas8_tracer_conflict_hilda31w` (`INDEX_ccx_seas.md`).
- **main = the commit that logs this note as CHANGELOG 2026-10-23 (d), pushed** (the note itself landed one commit earlier, at
  `3194dfc9`). No branches, no worktrees, no servers, no background jobs.
- **Live app = revision `01a1638d-7ac2-c682-a56b-6d52a8c539ac` from `2c5b445c`**, unchanged. The canonical is still `hilda31w`.

## 1. What was done

| | commits | outcome |
|---|---|---|
| fossil CH₄ priced | `ac4129f5`, `d1d626eb` | GCB 2025 S.8.1: E_FOS omits oxidised fugitive fossil CH₄, 0.083 GtC/yr 2008–17 (0.9 % of E_FOS). As `e_foss × 1.00884`: −26.19 logpost at fixed parameters, −4.84 after one Newton step, no move beyond 0.85 sd (`imb_share_land` +0.85, `luc_scale` +0.70). (j) |
| CFC-11 power check | same | Passive CFC-11 through the canonical's transport (finite-difference Jacobian of `ccx_deriv_fast()`). Model 5.08e8 mol vs Willey 2004's 5.5 ± 1.2e8; 83 % vs 82 % above 1000 m. Posterior predicts the inventory to 4.0 % against the observation's 22 %: no sd shrinks by more than 2 %. (j) |
| rulings + DESIGN note | `94ca8696` | CH₄ left out, note under DESIGN §3.6's forcing table; no CFC tracers. (a) |
| gate 6 | `832737c3` | Ledger row names Scripps in situ and the measured reason; `dg_gate6_obs()` refuses a flask-swapped `obs`. Mutation-tested. (b) |
| refit item 1 | `e52d23d0`, `cea7a27d` | `ccx_ms_reference_set()` takes the canonical's pins under the flask label at seas_ml 1: incumbent hilda31w as a START, new basin the control. `CCX_MODE_FLASK_*` in R/paths.R; test (16), mutation-tested. 619 passed in the five related files; full suite not run. (c) |

## 2. Decisions (Marcus, verbatim or his chosen option)

- 10-23: "Yes, save them to memory. Leave the CH4 out and make a DESIGN.md note. Don't add CFC tracers."
- 10-23: "Yes, start with the gate 6 ledger edit and refit code item 1."
- Carried from 10-22: scope "All MLO CO₂ rows (Recommended)"; gate 6 "Keep in situ, state why (Recommended)" (now done); label
  `hilda_csl3v0kaidgbemwtcf`; "Local refit from T8c's point (Recommended)", not a 24-start wave; "Add it as a third
  (Recommended)" (T8f's Newton point); "Carry module, then check (Recommended)".
- **Not decided:** the new mode's name; adoption; Marcus's wording for item 8 and any app copy that names the series; which
  module-check reference to use after landing (hilda31w's check file is the natural one: ask).

## 3. Next: refit item 2, then 3–5, then the run

**The three starts** (u-space, the canonical's 31 names; reproduction gates already in `test-flask-label.R`):
1. the canonical, scored under the flask label: **−1067.597927**. Since item 1 this is **id 1**, the driver's incumbent reference,
   with no new code.
2. T8c's block point: `outputs/diagnostics/seas8_20261021_hilda31w/t8f_allflask_forecast_hilda31w.rds` `$points$uB` (31 named,
   whole): **−1052.232908**.
3. T8f's Newton point: the same file, `$points$uN_all`: **−1050.185317**.

So the ruled three-start run is id 1 plus two FILE starts. Ids 0 (cold) and 2 (the control) are not in the ruled plan.

**Item 2: file starts in `calibration/run_dispersed_multistart.R`** (1364 lines at `cea7a27d`):
- Today's fixed ids: `MS_REF_IDS` (l. 215) cold 0 / incumbent 1 / new basin 2; `MS_SEED_IDS` (l. 221) 3–5, which under these pins
  fall back to dispersed draws; `MS_DISPERSED_FROM` 6 (l. 222).
- Dispatch: `ms_fixed_u()` (l. 662, used by the duplicate check) and `ms_start()` (l. 670). The gap guard is at l. 704: an id below
  `MS_DISPERSED_FROM` that matches nothing stops. File starts must dispatch in BOTH functions, before the gap guard, with their own
  `kind` and `class` (a new class, e.g. "file"). `.ms_ref` (l. 185) is where the reference set is read.
- Suggested shape (handoff 10-22): an env var naming an rds of named u vectors, on reserved fixed ids. Reserving ids means moving
  `MS_DISPERSED_FROM`, which `collect_dispersed_multistart.R` mirrors (`CO_REF_IDS` l. 42, `CO_SEED_IDS` l. 51; `start_class`
  read at l. 216 and l. 243-244). Check what the collector, the checkpoint compatibility check and the port gate do with a new class.
- PREFLIGHT every id (`CCX_MS_PREFLIGHT=1`, l. 713): it runs up to the port gate and the start, then exits 0.

**Items 3–5** (unchanged from the 10-22 handoff):
3. `calibration/make_port_targets.R` under the new label. It writes the TRACKED `calibration/torch/port_targets.csv`; keep a copy
   `port_targets_<label>.csv`, as the WTC run did. Item 1 unblocks it.
4. Name the outdir explicitly (the default with 14 pins exceeds 255 bytes); it must contain `MS_PRIOR_LABEL`
   (`_prior_bomb_share_NH_seas_T_lag`) or the driver stops.
5. `calibration/diag_obj18_basins.R` `OB_OBJECTIVES`: a new entry (label + pins). A new refit read in place of
   `diag_wtc_refit_read.R` (WTC-specific). Frozen launch / land (`NSTART=3`) / chain scripts, copied from the WTC wave's
   (`outputs/diagnostics/wtc_landing_20261013/` and the wave's `logs/`).

**Before launch:** the full suite once (recipe in §4); `uptime` and other jobs; the Torch verdict said aloud (laptop: the Mac is about
2× faster per evaluation and Torch lacks `adaptMCMC`).

**Run:** the WTC recipe (BUDGET 300 CPU-min, 3 restarts × 6 cycles × 6000 maxit, `CCX_MS_CLOCK=cpu`), Mac, frozen worktree, 3 at once,
`caffeinate`, BLAS pinned. The WTC incumbent took 160.6 CPU-min. `MS_CYCLE_TOL` 0.5 is weak evidence this close to the optimum; the
three starts agreeing is the real check. T8e's quadratic underpredicted a measured refit by 18 %, so expect a little better than −1050.19.

**Landing chain** (WTC times): collect → basins → `promote_multistart_mode.R --struct` (GATE 4/5 at `CCX_REPRO_TOL`) →
`recompute_hessian.R <mode> --update` (~13 min) → the new read → `fit_iav_module.R --base=<mode> --check=<ref>` (~1.4 min) → checkz →
`diag_ocean_climate_gobm.R` (~3.4 min) → `diag_whole_model_scorecard.R` (~0.5 min). Then Marcus rules adoption and the name.

**Adoption** (precedent 10-13 f): `git mv` the refit dir; R/paths.R `CCX_MODE_CANONICAL`, `CCX_MODE_FILES`, `CCX_MODE_PINNED`,
`CCX_MODE_CANONICAL_PINS`, `CCX_MODE_CANONICAL_MODULE_CHECK`; README / DESIGN / DATA mentions; `calibration/torch/make_bundle.sh`;
**remove the FLASK branch from `ccx_ms_reference_set()` and test (16)**, leaving `CCX_MODE_FLASK_*` as records (the WTC precedent);
full suite, classifying every failure without editing a test; then the ledger.

**Post-adoption** (precedent 10-13 g ff): MCMC 4 × 200k (`run_mcmc_check.R`, ~16.6 h), `read_mcmc_check.R`,
`diag_mcmc_identifiability.R`; futures band (`build_futures_ribbons.R --draws`, 216 min on 8 cores; add the mode to `RB_COV_EMIS`),
`promote_futures_ribbons.R`. The app stops drawing the band the moment the canonical changes, until it is rebuilt
(`ccx_ribbons_problems()`; `test-futures-ribbons.R` pins `hilda31w`). Constraint map, `diag_pulse_vs_tcre.R` (syncs `APP_PULSE_*`),
card 8, ocean card, `ALPHA_AS_FCO3`, both precomputes, `APP_RELEASE_MODE`.

**The app's series must follow the fit** (Marcus's rule). Under a flask canonical:
- `APP_OBS` (app/global.R ~580): `ccx_obs_co2_scored(ccx_prepare_obs(), TRUE, monthly = TRUE)` swaps the MLO monthly rows and targets
  to flask, so `plot_keeling()`, `plot_seasonal()`, `app_keeling_numbers()` and `app_seas_window()` follow. Check each against flask's
  gaps (1–7 months a year in 1963–68; 2025 has 2). **Never pass `APP_OBS` to `dg_gate6_obs()`: it now stops by name.**
- Known issue 1: `rv_rep_dc()` / `RV_REP_OBS_NH` 0.738 (app/R/review.R) recomputed on flask. Known issue 2: `rv_gradients()` on the
  flask gradient.
- Item 8's text (server.R, What pins down what?) says "the continuously measured CO₂ cycle … two sampling methods": stale once both
  rows are flask. Marcus's wording; pinned in `test-app-review-copy.R`.
- The Under the hood table ("Mauna Loa CO₂ 1958–2024") and `DLS$co2_obs` / `DLS$d13c_obs` (app/R/downloads.R ~127) already credit
  NOAA GML / INSTAAR on the live app, while every series scored and plotted is Scripps.

## 4. Non-obvious state

- **Label plumbing:** `ccx_prepare_obs()` carries additive flask targets (`co2_flask`, `co2_ann_flask`, `co2_seas_flask`,
  `co2_grad_flask`); `ccx_loglik()` swaps them in via `ccx_obs_co2_scored()` when `err$co2_mlo_flask == 1` (a local copy; the
  caller's `obs` is untouched); `ccx_comparable_rows()` drops `LIK_CO2_FLASK_ROWS` across arms that differ in the switch.
  A logpost under the flask label is a different objective: never compare it with an in situ one on those three rows.
- **`ccx_obs_co2_scored(monthly = TRUE)` relabels the flask rows "MLO".** Anything reading `obs$co2` by station name then reads flask.
  Gate 6 refuses it (10-23 b); other consumers do not check.
- **The reference set's flask branch** is live only while the canonical is not a file of the flask label; it is checked before the
  cut-canonical guard. Under the canonical's own label the same pins still give the canonical as a MODE.
- **seas8 overrides** (`calibration/lib_seas8_20261021.R`): `CCX_SEAS8_CO2SEAS=MLO_SIO_FLASK`; `CCX_SEAS8_CO2LEVEL=MLO_SIO_FLASK`,
  which requires the former; both apply after GATE R1.
- **The publish is Marcus's.** Hand him
  `Rscript -e 'rsconnect::deployApp("<bundle dir>", appId = "01a14244-5cc3-1951-7b06-9e2fb07beae3", account = "saraphreport", server = "connect.posit.cloud", forceUpdate = TRUE)'`.
- **Suite recipe:** copy `~/ccx_frozen/suite_20261022_f63edcd1.sh`, change the commit and label, `git worktree add --detach`, link the
  79 untracked `data-raw/downloads` entries per file (82 total; 78 / 81 on 10-22, the new one is
  `cfc_atm_history_bullister_2023.csv`, which no test reads; the script's own check is >= 70 links), run in the background,
  `git worktree remove`. Last full run: 9,247 / 0 / 1 at `f63edcd1`.
- **The 10-22 (j) drivers** are records, not live code: `calibration/diag_ch4ox_forecast_20261022.R` (wraps `ccx_run_fast()` in the
  global env) and `calibration/diag_cfc_power_20261022.R` (CFC constants from Orr et al. 2017 live in the driver, not
  `R/constants.R`). `data-raw/download_cfc_atm_history.R` added manifest key `cfc_atm_hist`.
- **Memory budgets:** `INDEX_ccx_ocean.md` is at 14,025 B, 311 B under its 14,336 soft budget; the next ocean line probably means a
  split. `INDEX_ccx_app.md` is still over its soft budget (16.3 KB, from 10-22).
- **Carried over:** f_plot's alt text "Futures" in all three modes; capacity before a live class; cold start ~8 s; the marketing list;
  the science follow-ups in handoff 10-21's §3.3. One is sharper since 10-22: flask CO₂'s MLO cycle is 4.8 % larger and 2.2 d earlier
  than in situ, unexplained.
