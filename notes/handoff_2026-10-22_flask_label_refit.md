# HANDOFF 2026-10-22 (late): the pointer fix is live; the flask label is built; the local refit is next

> **Superseded** by `notes/handoff_2026-10-23_flask_refit_item2.md` (CH₄ and CFC ruled out; gate 6 done; refit item 1 done).

**Supersedes** `notes/handoff_2026-10-22_sampling_refit_live_pointer.md`. Written on Marcus's request ("Write the handoff
(Recommended)"), 2026-10-22.

- **Start here:** CHANGELOG **2026-10-22 (e)–(i)**; this note's §3. Memory: `ccx_seas8_tracer_conflict_hilda31w` (its 10-22 f, g
  section), `ccx_connect_cloud_deploy` (10-22 e, h), and their lines in `INDEX_ccx_seas.md` / `INDEX_ccx_app.md`.
- **main = the commit that adds this note, pushed.** No branches, no worktrees, no servers, no background jobs.
- **Live app = revision `01a1638d-7ac2-c682-a56b-6d52a8c539ac` from `2c5b445c`** (published 12:19 UTC by Marcus), checked live
  in (h). The canonical is still `hilda31w`; nothing about the flask label is in the app yet.

## 1. What was done

| | commits | outcome |
|---|---|---|
| pointer fix | `2c5b445c` | `SEE_CARD_JS` reads `this.hash.slice(1)`. Headless check with the host's rewrite INJECTED: fix passes, pre-fix fails as live. Pin in `test-app-scan-items.R`. (e) |
| suite + bundle | `02c5cdd1` | 9,183 / 0 / 1 at `2c5b445c`; bundle `~/ccx_frozen/bundle_20261022_2c5b445c` (only `app/ui.R` differs from the old live one). (e) |
| T8f, all-flask priced | `6f134ab0`, `1c7c4eba` | Every MLO CO₂ row on flask: forecast +17.41 over the canonical; 10 level years and 4 gradient years lost; `tau_ex` +0.36 sd; physical outputs ≤ 0.09 ppm, pulse ≤ 0.002. T8e rerun with the edited lib reproduces its stored fields. (f) |
| the flask label | `f63edcd1` | `hilda_csl3v0kaidgbemwtcf`: reproduces T8f's override objective exactly at three points; mutation-tested; 10 label ledgers extended. (g) |
| live checks + suite | `e0bbcd42` | Both pointers work live with the host's rewrite firing; every tab draws. Suite at `f63edcd1`: 9,247 / 0 / 1. (h) |

## 2. Decisions (Marcus, verbatim or his chosen option)

- "Make the fix & build the bundle." Then "I published the pointer fix; do the live checks".
- On the ¹³C update: "we'd want to make our plots & tests with observed data match whatever we are using for the fits, and
  we'd want whatever we are using for the fits to be the most consistent source of data."
- Scope: first "Price all-flask first (Recommended)"; after T8f, **"All MLO CO₂ rows (Recommended)"** (level, seasonal, gradient).
- **Gate 6 stays on in situ:** "Keep in situ, state why (Recommended)". Flask has 1–6 months a year in 1963–67, so it can't
  supply the 1960s; the gate is a growth ratio. The ledger row must name the series and the reason. Not yet edited.
- Label name: **"hilda_csl3v0kaidgbemwtcf (Recommended)"**.
- Refit: **"Local refit from T8c's point (Recommended)"**, not a 24-start wave; **"Add it as a third (Recommended)"** (T8f's
  Newton point); the module: **"Carry module, then check (Recommended)"** (the canonical's pins, incl. the interannual
  module's four, carried; `fit_iav_module.R --check` after).
- **Not decided:** the new mode's name; adoption itself; Marcus's wording for item 8 and any copy that names the series.

## 3. Next: the local refit (code first)

**Starts** (u-space, the canonical's 31 names):
1. id 1, the canonical `hilda31w`, scored under the new label: **−1067.597927**.
2. T8c's block point: the canonical's `u` with the 8 names of `outputs/diagnostics/seas8_20261021_hilda31w/co2flask/t8c_split_hilda31w.rds`
   `$best$B_iii$x` (`$block`); also stored whole as `t8f_allflask_forecast_hilda31w.rds` `$points$uB`: **−1052.232908**.
3. T8f's Newton point: `t8f_allflask_forecast_hilda31w.rds` `$points$uN_all`: **−1050.185317**.

These three numbers are free reproduction gates (`test-flask-label.R` already holds them).

**Code the refit needs.** These come from a read-only survey at `3f8256b9`; line numbers in `R/calibrate.R` and `R/likelihood.R`
have moved since, so grep the names.
1. `ccx_ms_reference_set()` (R/calibrate.R) refuses the canonical's pins under any label but the canonical's own (the
   cut-canonical guard). Add a ruled FLASK REFIT branch: struct `hilda_csl3v0kaidgbemwtcf`, the canonical's pins, seas_ml 1
   → incumbent the canonical as a START, new basin the seas_ml 0 control. Constants `CCX_MODE_FLASK_*` in R/paths.R
   (precedent: `CCX_MODE_WTC_STRUCT/_PINS/_INCUMBENT`, still in paths.R as records). Test in `test-ms-reference-set.R`
   (precedent: its WTC case). It also unblocks `make_port_targets.R`. Remove the branch at adoption, as WTC's was.
2. `calibration/run_dispersed_multistart.R` has no start-from-vector path: ids 0/1/2 are cold / incumbent / new basin; 3–5
   are seeded and unseedable under these pins (they fall back to dispersed); ≥ 6 are dispersed. Add file starts
   (e.g. an env var naming an rds of named u vectors, on reserved fixed ids), dispatched in `ms_start()` and the fixed-u
   helper above it BEFORE the gap guard, with their own `kind`/`class`. Check what the port gate, the checkpoint
   compatibility check and `collect_dispersed_multistart.R` do with a new class. PREFLIGHT (`CCX_MS_PREFLIGHT=1`) every id.
3. `calibration/make_port_targets.R` under the new label (writes the TRACKED `calibration/torch/port_targets.csv`; the WTC run
   kept a copy `port_targets_<label>.csv`).
4. Outdir: name it explicitly (the default with 14 pins exceeds 255 bytes); it must contain `MS_PRIOR_LABEL`
   (`_prior_bomb_share_NH_seas_T_lag`) or the driver stops.
5. `calibration/diag_obj18_basins.R` `OB_OBJECTIVES`: a new entry (label + pins). A new refit read in place of
   `diag_wtc_refit_read.R` (it is WTC-specific). Frozen launch / land (`NSTART=3`) / chain scripts, copied from the WTC
   wave's (`outputs/diagnostics/wtc_landing_20261013/`, and the wave's `logs/`).

**Run:** the WTC recipe (BUDGET 300 CPU-min, 3 restarts × 6 cycles × 6000 maxit, `CCX_MS_CLOCK=cpu`), Mac, frozen worktree,
3 at once, `caffeinate`, BLAS pinned. **Torch verdict: laptop** (Mac ~2× faster per eval; Torch lacks `adaptMCMC`). The WTC
incumbent took 160.6 CPU-min. `MS_CYCLE_TOL` 0.5 is weak evidence this close to the optimum; the three starts agreeing is
the real check. T8e's quadratic underpredicted a measured refit by 18 %, so expect a little better than −1050.19.

**Landing chain** (WTC times): collect → basins → `promote_multistart_mode.R --struct` (GATE 4/5 at `CCX_REPRO_TOL`) →
`recompute_hessian.R <mode> --update` (~13 min) → the new read → `fit_iav_module.R --base=<mode> --check=<ref>` (~1.4 min;
ask Marcus which reference: hilda31w's check file is the natural one) → checkz → `diag_ocean_climate_gobm.R` (~3.4 min) →
`diag_whole_model_scorecard.R` (~0.5 min). Then Marcus rules adoption and the name.

**Adoption** (precedent 10-13 f): `git mv` the refit dir; R/paths.R `CCX_MODE_CANONICAL`, `CCX_MODE_FILES`,
`CCX_MODE_PINNED`, `CCX_MODE_CANONICAL_PINS`, `CCX_MODE_CANONICAL_MODULE_CHECK`; README / DESIGN / DATA mentions;
`calibration/torch/make_bundle.sh`; remove the FLASK branch; full suite and classify every failure without editing a test;
then the ledger.

**Post-adoption** (precedent 10-13 g ff): MCMC 4 × 200k (`run_mcmc_check.R`, ~16.6 h; reads `CCX_MODE_CANONICAL`, needs
`md$cov`), `read_mcmc_check.R`, `diag_mcmc_identifiability.R`; futures band (`build_futures_ribbons.R --draws`, 216 min on
8 cores; add the new mode to `RB_COV_EMIS`), `promote_futures_ribbons.R`. ⚠ The app stops drawing the band the moment the
canonical changes, until it is rebuilt (`ccx_ribbons_problems()`; `test-futures-ribbons.R` pins `hilda31w`). Constraint map,
`diag_pulse_vs_tcre.R` (syncs `APP_PULSE_*`), card 8, ocean card, `ALPHA_AS_FCO3`, both precomputes (re-run at every
adoption), `APP_RELEASE_MODE`.

**The app's series must follow the fit** (Marcus's rule). Under the flask canonical:
- `APP_OBS` (app/global.R ~580): `ccx_obs_co2_scored(ccx_prepare_obs(), TRUE, monthly = TRUE)` swaps the MLO monthly rows
  and targets to flask, so `plot_keeling()`, `plot_seasonal()`, `app_keeling_numbers()` and `app_seas_window()` follow.
  Check what each does with flask's gaps: 1–7 months a year in 1963–68; 2025 has 2 months.
- Known issue 1: `rv_rep_dc()` / `RV_REP_OBS_NH` 0.738 (app/R/review.R) recomputed on flask. Known issue 2: `rv_gradients()`
  (review precompute) on the flask gradient.
- Item 8's text (server.R, What pins down what?) says "the continuously measured CO₂ cycle … two sampling methods": stale
  once both rows are flask. Marcus's wording. It is pinned in `test-app-review-copy.R`.
- The Under the hood data table ("Mauna Loa CO₂ 1958–2024") and the download source strings `DLS$co2_obs` / `DLS$d13c_obs`
  (app/R/downloads.R ~127). ⚠ These are already WRONG on the live app: they credit NOAA GML / INSTAAR, but every series
  scored and plotted is Scripps.
- Gate 6 (`calibration/lib_design_gates.R` `dg_gate6_obs()`, ledger row ~633): stays in situ. Edit the ledger row's `src`
  to say why (ruled). `dg_gate6_obs()` takes `ccx_prepare_obs()` unswapped, so nothing else changes.

## 4. Non-obvious state

- **The label's plumbing:**
  - `ccx_prepare_obs()` carries ADDITIVE flask targets (`co2_flask`, `co2_ann_flask`, `co2_seas_flask`, `co2_grad_flask`).
  - `ccx_loglik()` swaps them in through `ccx_obs_co2_scored()` when `err$co2_mlo_flask == 1`.
  - `ccx_comparable_rows()` drops `LIK_CO2_FLASK_ROWS` across arms that differ in the switch.
  - ⛔ A logpost under the flask label is a different objective: never compare it with an in situ one on those three rows.
- **seas8 overrides:**
  - `CCX_SEAS8_CO2SEAS=MLO_SIO_FLASK`; `CCX_SEAS8_CO2LEVEL=MLO_SIO_FLASK`, which requires the former.
  - Both apply after GATE R1.
- **The publish is Marcus's.** Hand him
  `Rscript -e 'rsconnect::deployApp("<bundle dir>", appId = "01a14244-5cc3-1951-7b06-9e2fb07beae3", account = "saraphreport", server = "connect.posit.cloud", forceUpdate = TRUE)'`.
  Timeouts live under `$current_revision$connect_options`.
- **Live checkers (headless Chrome on port 9333):**
  - `outputs/diagnostics/scan_items_20261021/check_scan_ui.py`;
  - `outputs/diagnostics/see_card_hash_20261022/check_live_pointer.py` (`<port> <url> <W> <H> <commit7>`). ⚠ Its tab sweep
    reads Futures → Build your own's `f_plot` before "Run it" is pressed, and that plot waits for the click by design;
  - `check_see_card_rewrite.py` (the four-arm injection check, local).
  - The Browser pane cannot test scrolling.
- **Suite recipe:** copy `~/ccx_frozen/suite_20261022_f63edcd1.sh`, change the commit and label, `git worktree add --detach`,
  link the 78 untracked `data-raw/downloads` entries per file (81 total), run in the background, `git worktree remove`.
  42 app-facing files: `grep -lE 'file\.path\(\.root, "app"\)|app/R/|app/global\.R|shinyAppDir|"app"' tests/testthat/test-*.R`,
  as one `test_dir(filter=…)`.
- **Carried over:** f_plot's alt text "Futures" in all three modes; capacity before a live class; cold start ~8 s; the
  marketing list; `INDEX_ccx_app.md` is 16.3 KB, over its 14 KB soft budget (hard 18). The science follow-ups listed in the
  previous handoff §3.3 still stand. One is now sharper: flask CO₂'s MLO cycle is 4.8 % larger and 2.2 d earlier than in
  situ, unexplained.
