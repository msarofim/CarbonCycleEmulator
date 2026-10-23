# HANDOFF 2026-10-23 (2): products rebuilt, the app on flask, wording settled; the MCMC read is next

**Supersedes** `notes/handoff_2026-10-23_hilda31fl_adopted.md`, which now points here. Written on Marcus's request ("Yes,
write the handoff"), 2026-10-23 ~15:20.

- **Start here:** CHANGELOG **2026-10-23 (p) to (s)** and this note's §4. Memory: `ccx_hilda31fl_adopted` (linked from
  `INDEX_ccx.md`'s LIVE STATE line and the root `MEMORY.md`).
- **main = the commit that logs this note as CHANGELOG 2026-10-23 (t), pushed.** No branches, no extra worktrees. **The canonical
  is `hilda31fl`.** The live app is unchanged (revision `01a1638d-7ac2-c682-a56b-6d52a8c539ac` from `2c5b445c`,
  `APP_RELEASE_MODE` "hilda31w"). Nothing deployed this session.
- **Running now:** the hilda31fl MCMC, 4 × 200k, launched 2026-10-23 13:52 EDT. At 14:32 each chain was at ~7,500 iterations
  (~0.3 s/iteration), so it should finish around **06:30 on 10-24**. PIDs in `~/ccx_frozen/20261023_mcmc_hilda31fl.pids` (the
  caffeinate wrappers; check with `kill -0 <pid>`). Progress: `tail -1 ~/ccx_frozen/20261023_mcmc_hilda31fl_chain{1,2,3,4}.out`.
  Never use a `pgrep -f` wait loop.

## 1. What was done this session

| | commits | outcome |
|---|---|---|
| `pulse_vs_tcre` | `5dc67758` | 1.359 °C per 1000 GtC at the app defaults (hilda31w 1.350); horizons 1.436 / 1.372 / 1.359 / 1.411; spread 2.2 %. `APP_PULSE_*` synced. "About 1.4" holds by 0.009. (p) |
| constraint map | `8b1e8e41`, `f6fd95c1` | `CM_DATE` `20261023k`; every gate passes; every row keeps its winner (shares move ≤ 2.6 pp); pin share 8.7 %; `beta_max`/`fert_k` "about 32×" (was 51×, computed). (p) |
| card 8 chain | `4c829447`, `47222e4c`, `10b9b822` | time shape 2015–24 −0.434, ratio 1.80 ± 0.41, 27 yr earlier; G1 reference 1492.6672 ppm; stake G1–G3b pass, f_T 0.4903, SSP5-8.5 2300 −31.9 ppm; card 2.17×. (p) |
| `ALPHA_AS_FCO3` | `934a6823` | 0.0926 (2024), 0.1191 (1750); 0.082 kept. (p) |
| app series → flask | `7ea63a50`, `3d2821d6`, `2f3a6b27`, `e6f5b8d7`, `b71084ee` | `APP_OBS` swapped by `APP_CO2_FLASK`; card 2 reads the arm's switch; `RV_REP_OBS_NH` 0.738 → 0.668; card 1's signature −37.6 ‰; Mauna Loa "Covers" from the data. (q) |
| precomputes | `ca48a2a5` | start-up, default pulse and Known issues rebuilt after the switch. Card 2 on flask: CO₂ 0.885× (z −6.3), δ¹³C 2.00×. (q) |
| full suite | `ffee2577` | @`ca48a2a5`: 9343 passed, 6 failed (the expected ones, §5), 1 standing skip, 0 errored, 25.9 min. (r) |
| wording | `15ecf86f`, `27caa4f7` | Marcus's four calls applied and pinned (§2). (s) |

## 2. Decisions (Marcus, verbatim)

- Card 1: "About −38‰ (Recommended)". Card 2: "About 12% (Recommended)" (both places). Credits: "Scripps draft (Recommended)".
- Item 8: "Draft one for me", then "Apply, move the pins (Recommended)". The text reads: "A likely reason they disagree: at
  Mauna Loa, measured in the same air samples, the ¹³C cycle runs about two days ahead of the CO₂ cycle. The model's land
  plants move the two tracers nearly in step, so the fit splits the difference."
- Carried from the morning: "Mac, tonight (Recommended)" for the MCMC; `ALPHA_AS_FCO3` stays 0.082 (ruled at hilda31w; I reported
  and did not change it).
- **Open, Marcus's:** the app release (precedent 10-13 h: "Hold until rebuilt"); card 8's text (still Claude's draft since
  10-13); whether the Keeling chart needs a note on flask's sparse 1960s (not asked; nothing changed).

## 3. Files

- **New this session, committed:** `outputs/diagnostics/` `pulse_vs_tcre_20261023.{csv,log}`, `constraint_map_20261023k.log`,
  `h2_time_shape_20261023_hilda31fl.*`, `app_ssp585_ref_20261023_hilda31fl.log`, `h2_futures_stake_20261023_hilda31fl{.log,.rds,_runs.rds}`,
  `ocean_climate_card_20261023_hilda31fl.log`, `fco3_at_mode_20261023.{log,rds}`, `rep_dc_mbl_zonal_20261023_hilda31fl.log`,
  `rep_dc_d13c_hemispheric_20261023_hilda31fl.log`, `app_precompute_20261023_hilda31fl.log`,
  `review_precompute_20261023_hilda31fl.log`, `suite_20261023_ca48a2a5{.log,_perfile.csv}`.
- **Rebuilt in `data/`:** `constraint_map.rds`, `ocean_climate_card.rds`, `app_startup_precompute.rds`,
  `pulse_default_precompute.rds`, `review_precompute.rds`.
- **Code edited:** `app/global.R` (APP_OBS, APP_PULSE_*), `app/R/review.R` (rv_gradients, RV_REP_OBS_NH, cards 1–2),
  `app/server.R` (Covers, item 8), `app/R/downloads.R` (credits), `calibration/diag_constraint_map.R` (CM_DATE),
  `calibration/diag_h2_futures_stake.R` and `build_ocean_climate_card.R` (hilda31fl registered),
  `calibration/diag_rep_dc_mbl_zonal.R` and `diag_rep_dc_d13c_hemispheric.R` (scored series; the latter's run),
  `tests/testthat/test-app-review-copy.R` (AC_CHECKS_1023) and `test-app-downloads.R` (test 5).
- **Pending, still keyed to hilda31w:** `data/futures_ribbons.rds` and `data/constraint_map_stability.rds` (both need the
  hilda31fl chains); `APP_CMAP_TIE_SRC` names hilda31w; `APP_RELEASE_MODE` "hilda31w".

## 4. Next

1. **When the chains finish (~06:30 10-24),** follow the hilda31w precedent, CHANGELOG 2026-10-14 (a) and (b):
   - Snapshot the chains into `outputs/mcmc_check_<date>_hilda31fl_200k/` (`cmp` against the frozen worktree's
     `outputs/mcmc_check_20261023_hilda31fl/chain_{1..4}.rds`; record md5s).
   - `calibration/read_mcmc_check.R --drop=0` (R-hat, ESS, blocks against the Laplace expectation), then `--pool-thin=2`
     if the band is to be built from 17 000 draws as at hilda31w (that thinning was ruled for hilda31w, so ask again).
   - `calibration/diag_mcmc_identifiability.R`: `bomb_share_NH`, `seas_T_lag` (on its 0 floor at hilda31w), `h_ml` against the
     substep wall. `calibration/diag_mcmc_drift.R --names=<the worst R-hats>`.
   - ⚠ At hilda31w the chains did NOT converge by Vehtari's reference (the seasonal-lag ridge, chain 4's excursion). Read
     before assuming this run did; the band's shipping is Marcus's call, as on 10-14 (f).
2. **The band:** `calibration/build_futures_ribbons.R --draws=<pooled file>` (~216 min on 8 cores at hilda31w). First add
   `hilda31fl` to `RB_COV_EMIS` (`build_futures_ribbons.R` l. 123); check which emissions basis its Hessian was computed on
   before choosing the value (hilda31w's is "constant"). Then `diag_mcmc_band_by_chain.R`, `promote_futures_ribbons.R`, and
   move `test-futures-ribbons.R`'s hilda31w names (`.fr_src_file`, `.fr_ship_md`, `FR_BYCHAIN_FILE`, the identifiability
   file) to the new products. ⚠ The 2300 SSP5-8.5 CO₂ at the mode moved +5.82 ppm, but id 7 (0.013 apart) moved +1.12:
   quote the band, not the mode's move.
3. **The map's tie stability:** `calibration/diag_cmap_posterior_spread.R` (100 draws, ~40 min, 1 core) then
   `calibration/promote_cmap_stability.R`; update `APP_CMAP_TIE_SRC`. `test-cmap-tie` then goes green. At hilda31fl the map's
   tightest row is δ¹³C level & gradient (22.3 vs 21.0 %).
4. **Then** the full suite (expect only `app-version` red), the bundle, and Marcus's release decision (`APP_RELEASE_MODE`).
   The publish is Marcus's: hand him the `rsconnect::deployApp(...)` line from `notes/handoff_2026-10-23_flask_refit_item2.md` §4.

## 5. Non-obvious state

- **Suite reds by design (6):** `app-version` (release), `cmap-tie` ×4 (it refuses hilda31w's stability file against the
  rebuilt map, as its header says; until §4.3 the app hides the map's takeaway and logs why), `futures-ribbons` (§4.2; the app
  logs "futures ribbons NOT drawn").
- ⛔ **`ccx_prepare_obs()$co2` is IN SITU MLO under every label.** The scored series is
  `ccx_obs_co2_scored(obs, ccx_co2_flask_on(err), monthly = TRUE)`; two card-1 drivers read the raw frame and were fixed.
  Any new driver comparing against "what the fit scores" must swap the same way. Gate 6 stays in situ (ruled 10-22) and
  stops on a swapped frame.
- **The app's switch** is `APP_CO2_FLASK <- ccx_co2_flask_on(ccx_err_with_struct(list(), APP_PARAMS))`. The review precompute
  loads `review.R` WITHOUT `global.R`, so `rv_gradients()` reads the switch off its arm (`v$p`), not `APP_CO2_FLASK`.
- **The Mauna Loa credit says "flask" unconditionally;** `test-app-downloads.R` test 5 fails if that disagrees with
  `APP_CO2_FLASK`, so a canonical without the switch will flag it.
- **Card 2's typed "about 12%"** rests on the flask gradient at hilda31fl (11.5 %); the caption prints the ratio live. Card 1's
  "about −38‰" rests on `rep_dc_d13c_hemispheric_20261023_hilda31fl.log`. Neither is recomputed by a test.
- **`diag_rep_dc_d13c_hemispheric.R` had been dead since hilda33p** (its own forcing lacked the ENSO index); it now uses
  `dg_vector()` + `dg_run()`. Memory: `ccx_diag_must_use_mode_base` point 4.
- **Suite recipe:** copy `~/ccx_frozen/suite_20261023_ca48a2a5.sh`, change the commit (three places) and the label,
  `git worktree add --detach ~/ccx_frozen/suite_<date>_<commit> <commit>`, link every untracked `data-raw/downloads` entry per
  file (79 links + 3 tracked = 82), run it in the background, remove the worktree with `--force` after (the links are
  untracked; the targets survive).
- **MCMC worktree** `~/ccx_frozen/20261023_mcmc_hilda31fl` @`2ec25511` (79 links). Resumable by re-running
  `~/ccx_frozen/20261023_mcmc_hilda31fl_launch.sh`. Don't edit `calibration/run_mcmc_check.R` or `R/` in that tree while it runs.
- **Memory budgets** (unchanged this session except the two files named above): `INDEX_ccx.md` 14.8 KB (over its 14 KB soft
  budget); root `MEMORY.md` near its soft budget; `INDEX_ccx_app.md` over soft (from 10-22).
- **Carried over:** f_plot's alt text "Futures" in all three modes; capacity before a live class; cold start ~8 s; the
  marketing list; handoff 10-21 §3.3's science follow-ups; flask CO₂'s MLO cycle is 4.8 % larger and 2.2 d earlier than in
  situ, unexplained (the app's measured average cycle is now 7.12 ppm peak to trough, in situ 6.82).
