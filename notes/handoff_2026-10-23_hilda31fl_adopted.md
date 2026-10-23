# HANDOFF 2026-10-23: hilda31fl ADOPTED, ledger applied, MCMC running; the product rebuilds are next

**Supersedes** `notes/handoff_2026-10-23_flask_refit_running.md`, which now points here. Written on Marcus's request ("Yes,
write the handoff"), 2026-10-23 ~14:10.

- **Start here:** CHANGELOG **2026-10-23 (j) to (n)**; this note's §4. Memory: `ccx_hilda31fl_adopted` (linked from
  `INDEX_ccx.md`'s LIVE STATE line and the root `MEMORY.md`), and `ccx_seas8_tracer_conflict_hilda31w` for the arc.
- **main = the commit that logs this note as CHANGELOG 2026-10-23 (o), pushed.** No branches. **The canonical is `hilda31fl`.**
  The live app is unchanged (revision `01a1638d-7ac2-c682-a56b-6d52a8c539ac` from `2c5b445c`, `APP_RELEASE_MODE` "hilda31w").
- **Running now:** the hilda31fl MCMC, 4 × 200k, launched 2026-10-23 13:52 EDT, about 15-17 h (done ~05:00-07:00 10-24).
  PIDs in `~/ccx_frozen/20261023_mcmc_hilda31fl.pids` (the caffeinate wrappers). Check with `kill -0 <pid>`; progress
  `tail -2 ~/ccx_frozen/20261023_mcmc_hilda31fl_chain{1,2,3,4}.out`. Never a `pgrep -f` wait loop.

## 1. What was done this session

| | commits | outcome |
|---|---|---|
| ruling: empty file slots | `63633d99` | Marcus: "Keep the empty-slot rule". No code change. (i) |
| landing + read | `3e872cb8` | ids 1 / 6 / 7 -> -1050.120667 / -1050.120651 / -1050.134021; spread 0.0134 vs 0.5: one optimum. Promoted id 6. +17.48 over hilda31w under the flask label (T8f forecast +17.41); -21.18 on the in situ objective. Every scorecard verdict as hilda31w's. Both worktrees removed after `cmp`. (j) |
| adoption | `6171db02` | dir `calibration/output/refit_20261023_hilda31fl_flask_hilda_csl3v0kaidgbemwtcf/` (md5 80c487f5); `R/paths.R` registry; `CCX_MODE_CANONICAL_MODULE_CHECK` -> the `_vs_pins` check; the flask branch of `ccx_ms_reference_set()` removed with test (16); README / DESIGN; `make_bundle.sh`. (k) |
| ledger | `b7c167da` | suite @6171db02: 9177 passed, 81 failed, 2 errored, 4 skipped; 83 entries classified (B 11, B2 2, C 1, D 67, F 1, G 1); no test edited. `outputs/diagnostics/ledger_20261023_hilda31fl/README.md`. (l) |
| ledger applied | `2ec25511` | six test files edited as ruled, 830 / 0; the mechanisms "either" check mutation-tested. (m) |
| MCMC launch | `0a9043e7` | smoke: every chain reproduces -1050.120651 (diff 0), 0.26-0.30 s/iteration. `outputs/diagnostics/mcmc_launch_20261023_hilda31fl/`. (n) |

## 2. Decisions (Marcus, verbatim)

- "Keep the empty-slot rule; continue when it lands".
- "Adopt id 6 (Recommended)"; the name "hilda31fl (Recommended)" ("hilda31f" declined, one letter from hilda32f).
- Module-check reference: he asked "recommendation?"; I recommended the pins' file (the check guards the pins a refit
  carries, which are the 10-08 file's values); ruled "Pins' file, no 2nd pass (Recommended)". w_enso_l2 -0.156 sigma
  there (hilda31w had -0.110); a second pass would gain +0.017 module log-lik. Refresh the pins at the next refit run
  for its own reasons.
- Ledger: "Approve all (Recommended)"; mechanisms check "Either of the two (Recommended)"; MCMC "Mac, tonight
  (Recommended)" (Torch verdict said before launch: Mac, a Torch node is ~2x slower per evaluation).
- **Open, Marcus's:** the app release (precedent 10-13 h: "Hold until rebuilt"); item 8's wording and any app copy naming
  the flask series; card 8's text (still Claude's draft since 10-13).

## 3. Files

- **Committed, new:** the landed wave `calibration/output/multistart_20261023f_…/`, the refit dir (renamed), three
  `iav_module_20261023_refit_20261023_flask_…{,_vs_own,_vs_pins}.rds` (the un-suffixed one is a byte copy of `_vs_own`),
  `outputs/diagnostics/flask_landing_20261023/` (chain, armed script and log, `dryrun_id007/`),
  `flask_refit_read_20261023_id006.{log,rds}`, `obj18_basins_20261023_flask.*`, `ocean_climate_gobm_20261023_flaskid006.*`,
  `whole_model_scorecard_20261023_hilda31w_flask.rds`, `suite_20261023_6171db02{.log,_failing.log,_perfile.csv}`,
  `mechanism_sweep_20261023_hilda31fl.{log,rds}`, the ledger and MCMC-launch folders.
- **Pending, all keyed to hilda31w (their tests are D's 67 reds until rebuilt):** `data/app_startup_precompute.rds`,
  `data/pulse_default_precompute.rds`, `data/constraint_map.rds`, `data/ocean_climate_card.rds`,
  `data/review_precompute.rds`, `data/futures_ribbons.rds`, `outputs/diagnostics/pulse_vs_tcre_20261013.csv`.

## 4. Next

1. **Model-only products now, beside the MCMC** (precedent CHANGELOG 2026-10-13 (k), which lists every driver and gate):
   `calibration/diag_pulse_vs_tcre.R` (then sync `APP_PULSE_LIN_*` / `APP_PULSE_PER1000_BY_HORIZON` in `app/global.R`;
   ⚠ 10-13's "about 1.4" rounded by 0.0003); `calibration/diag_constraint_map.R` (new `CM_DATE`; the tie cut stays
   deferred to the MCMC read); card 8's chain (time shape, the G1 reference, the futures stake, then
   `calibration/build_ocean_climate_card.R`); `calibration/diag_fco3_at_mode.R` for `ALPHA_AS_FCO3` (Marcus kept 0.082 at
   hilda31w; report, don't change). Each single-core; 6 cores are free beside the 4 chains.
2. **When the chains finish:** `calibration/read_mcmc_check.R`, `diag_mcmc_identifiability.R`, the by-chain and drift
   diagnostics; the futures band `build_futures_ribbons.R --draws` (~216 min on 8 cores; add hilda31fl to `RB_COV_EMIS`),
   `promote_futures_ribbons.R`; `test-futures-ribbons.R` pins the mode by name. Then the cmap tie cut.
   ⚠ **2300 ssp585 CO2 at the mode: +5.82 ppm over hilda31w at id 6, +1.12 at id 7 (0.013 apart in logpost).** Quote the
   band, not the mode's move.
3. **The app's series follow the fit** (Marcus's rule; handoff 10-23 item-2 §3): `APP_OBS` swaps MLO to flask via
   `ccx_obs_co2_scored(..., TRUE, monthly = TRUE)`; check `plot_keeling()`, `plot_seasonal()`, `app_keeling_numbers()`,
   `app_seas_window()` against flask's gaps (1-7 months a year in 1963-68; 2025 has 2); never pass `APP_OBS` to
   `dg_gate6_obs()`; `rv_rep_dc()` / `RV_REP_OBS_NH` 0.738 and `rv_gradients()` recomputed on flask; item 8's text
   (Marcus's wording); the Under the hood table and `DLS$co2_obs` / `DLS$d13c_obs` credits.
4. **Then the two app precomputes** (`calibration/build_app_precompute.R`, `calibration/build_review_precompute.R`).
   ⚠ ORDER: both compare against `APP_OBS`, so build them AFTER step 3, not before.
5. The full suite (expect only `app-version` red), then Marcus's release decision and the publish.

## 5. Non-obvious state

- **The canonical runs the flask label, so its logposts are on the flask objective.** Compare with hilda31w only through
  the read's §1 (both under the flask label) or §2 (both in situ). The scorecard's row totals mix the two series.
- **`CCX_MODE_FLASK_*` are records** (four readers). `CCX_MODE_FLASK_INCUMBENT` = "hilda31w" = T8f's mode;
  `test-flask-label.R` reads it from T8f's provenance.
- **`ccx_comparable_rows()` drops the three MLO CO2 rows** between labels that differ in `co2_mlo_flask`; any test that
  compares the canonical with the seas_ml-0 control (hilda31pe) must expect five dropped rows, not two.
- **The mechanisms power check's crash flips** between `warming_feedback + ocean_sink` and the triple with `revelle` across
  adoptions; the test now takes either.
- **MCMC worktree** `~/ccx_frozen/20261023_mcmc_hilda31fl` at `2ec25511` (79 download links + 3 tracked files); chain files
  `outputs/mcmc_check_20261023_hilda31fl/chain_{1..4}.rds` there; the smoke's chain files in `outputs/mcmc_smoke_…` there.
  Resumable: re-running `~/ccx_frozen/20261023_mcmc_hilda31fl_launch.sh` continues each chain. Don't edit
  `calibration/run_mcmc_check.R` or `R/` in that tree while it runs.
- **Memory budgets:** `INDEX_ccx.md` 14.8 KB (over its 14 KB soft budget before this session, +28 B here); root
  `MEMORY.md` 12,131 content bytes (soft 12,288); `INDEX_ccx_seas.md` 11.0 KB; `INDEX_ccx_app.md` over soft (from 10-22).
- **Carried over:** f_plot's alt text "Futures" in all three modes; capacity before a live class; cold start ~8 s; the
  marketing list; handoff 10-21 §3.3's science follow-ups; flask CO2's MLO cycle is 4.8 % larger and 2.2 d earlier than
  in situ, unexplained.
