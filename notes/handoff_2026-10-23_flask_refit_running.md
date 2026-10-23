# HANDOFF 2026-10-23: the flask refit is RUNNING; its landing is armed

**Supersedes** `notes/handoff_2026-10-23_flask_refit_item2.md`, which now points here. Written on Marcus's request ("Yes,
write the handoff"), 2026-10-23 ~10:00.

- **Start here:** CHANGELOG **2026-10-23 (e), (f), (g)**; this note's §4. Memory: `ccx_seas8_tracer_conflict_hilda31w`
  (`INDEX_ccx_seas.md`), whose last paragraph is the arc's state.
- **main = the commit that logs this note as CHANGELOG 2026-10-23 (h), pushed.** No branches. The canonical is still `hilda31w`.
  Live app unchanged (revision `01a1638d-7ac2-c682-a56b-6d52a8c539ac` from `2c5b445c`).
- **Running now** (launched 2026-10-23 09:25:57 EDT): launcher pid **73635**, work pids 73696 / 73697 / 73698 (ids 1 / 6 / 7),
  armed-landing pid **73795**. At 09:55 (29 wall-min in): id 1 at −1050.3235 after its first restart (from −1067.5979), id 7 at
  −1050.1345 (from −1050.1853), id 6 still in its first restart. Budget 300 CPU-min per task; each restart ~27 CPU-min.

## 1. What was done this session

| | commits | outcome |
|---|---|---|
| item 2: file starts | `475b30e3`, `6d00fcd8` | Ids 6–9 are FILE slots filled from the rds `CCX_MS_FILE_STARTS` names (`calibration/lib_ms_file.R`). Two gates: the label (struct / seas_ml / pump field / pins, and the fitted names) and the value (the run's objective reproduces the file's logpost at port gate (a)'s bound). `MS_DISPERSED_FROM` 6 → 10. Port gate (a) uses the lib's floor and bound, byte-identical output. Collector mirrors the slots. `calibration/torch/file_starts_hilda_csl3v0kaidgbemwtcf.rds` = T8f's `uB` (−1052.232908) and `uN_all` (−1050.185317), built by `calibration/make_flask_file_starts.R`. (e) |
| item 3: port targets | `7bd37b94` | Flask label, canonical's pins: incumbent hilda31w −1067.5979272958, new basin hilda31pe −11342.8028590519, cold −58339.1009927710. (e) |
| item 5: basins + read | `3e1feaf2` | `diag_obj18_basins.R` flask entry; new `calibration/diag_flask_refit_read.R` (smoke-tested on a synthetic wave). (f) |
| tests | `475b30e3`, `30820e6c` | `test-ms-file.R` 83/0, 12 mutations caught; old vs new driver preflights in `outputs/diagnostics/ms_file_starts_20261023/`. (e) |
| lint fixes | `30820e6c`, `312edc29` | Mine: test-ms-file.R read a mode file directly. The 10-22 CFC driver's bare `intersect()` overlay → `ccx_overlay_par()`; rerun `identical()` in every result field (`outputs/diagnostics/cfc_power_20261022_hilda31w/reverify_20261023/`). (f), (g) |
| full suite | `ec3a9d5f` | **312edc29: 9351 passed, 0 failed, 1 skipped** (the standing `test-l2-enso-limb.R` skip). (g) |
| launch | `facf8851` | The run below. (f) |

## 2. Decisions

- Marcus 10-23, verbatim (AskUserQuestion): "Convert, re-verify (Recommended)" (the CFC driver's lint); "Launch now (Recommended)".
- Carried: the 10-22 rulings ("Local refit from T8c's point", "Add it as a third", "Carry module, then check"), label
  `hilda_csl3v0kaidgbemwtcf`, gate 6 stays in situ.
- **Mine, flagged, not ruled:** an EMPTY file slot runs its id's old dispersed draw (labelled EMPTY, start_class "dispersed"),
  by analogy with the unseedable-slot ruling, so a wave that names no file draws what it drew before. The alternative (stop on
  an empty slot) would break every 24-id recipe.
- **Open, Marcus's:** (1) adoption and the mode's name; (2) which module-check reference rules (the chain runs both, §3);
  (3) whether the empty-slot rule stands; (4) carried: his wording for item 8 and any app copy naming the series.

## 3. The run and its landing (all in `~/ccx_frozen/`, not the repo; the land copies the scripts into the wave's `logs/`)

- **Tree** `20261023_flask` = detached worktree at `7bd37b94`, downloads APFS-cloned (`diff -rq` identical). Its `logs/`:
  `pins_20261023f.txt` (the `%.17g` launch string), `port_targets_20261023f.log` (the repo run at 6d00fcd8),
  `preflight_20261023f.log` + `preflight_20261023f/` (3/3 LAUNCHABLE, 0.29 CPU-s/eval), `wave_20261023f.log`, per-task
  `ccx_multistart_mac_20261023f_<id>.out`, the exit file.
- **Outdir** `calibration/output/multistart_20261023f_hilda_csl3v0kaidgbemwtcf_seasml1_pin_flask_sd1.0452_prior_bomb_share_NH_seas_T_lag`.
- **Scripts:** `20261023f_flask_launch.sh` (→ `.out`, `.pid`), `_preflight.sh`, `_land.sh`, `_chain.sh dryrun|land`, `_armed.sh`
  (→ `_armed.out`, `.pid`).
- **Armed sequence:** stage 1 = the chain in **dryrun** once the first start file is 2 min old (its own worktree
  `20261023f_flask_chaindry` at the repo's HEAD; logs in its `DRYRUN_logs/`); stage 2 = the chain in **land** once launcher 73635
  exits. Land steps: land.sh (end line, no work process, **3** exit codes, copy into the repo, cmp, `RUN_PROVENANCE.txt`) →
  collect → basins (`CCX_O18_TAG=_flask`) → promote LP (+ NAT / NEAR if they differ) into
  `calibration/output/refit_<day>_flask_hilda_csl3v0kaidgbemwtcf` → per promoted mode: `recompute_hessian.R --update` (~13 min),
  `diag_flask_refit_read.R`, `fit_iav_module.R --check` **twice** (`_vs_pins` = `CCX_MODE_OBJ18P2_MODULE_FILE`, the WTC chain's
  choice; `_vs_own` = `CCX_MODE_CANONICAL_MODULE_CHECK`), each verdict at the ruled 0.1 σ, `diag_ocean_climate_gobm.R` → scorecard
  (`CCX_SC_TAG_SUFFIX=_flask`). Logs `outputs/diagnostics/flask_landing_<day>/`. It adopts and commits nothing.
- ⚠ **The land refuses a dirty repo** under `R/`, `calibration/`, `tests/` (and needs HEAD ⊇ `3e1feaf2`). Commit anything there
  before the run ends, or the landing stops at its first step (harmless; rerun `bash ~/ccx_frozen/20261023f_flask_chain.sh land`).
- **How to check:** `tail ~/ccx_frozen/20261023f_flask_armed.out`; `kill -0 73635` (launcher alive?); per-task progress
  `grep "^\[" ~/ccx_frozen/20261023_flask/logs/ccx_multistart_mac_20261023f_00{1,6,7}.out | tail`. Never a `pgrep -f` wait loop.
- **If a chain step fails:** the armed log names the step and its log. Fix, then rerun the chain from that step by hand (the
  land step refuses an existing repo outdir, so skip it once it has run).

## 4. Next

1. **Read the landing** (when `armed.out` ends with "armed landing: the chain ended rc 0"): `collect.log`, the basins log, and
   `outputs/diagnostics/flask_refit_read_<day>_id<NNN>.log`. Key lines: section 0's **three-start agreement** (finals' spread
   against `cycle_tol` 0.5; the largest coordinate range in hilda31w's Laplace sd). With no dispersed start, that agreement is the
   run's check that it found one optimum. Expect a little better than −1050.19 (T8e's quadratic underpredicted a measured refit by
   18 %). Section 1: REF gated on the port target and on T8f's rows; the three MLO CO₂ rows marked. Section 2: what the refit
   costs in situ. Both module-check verdicts.
2. **CHANGELOG entry for the landing**, citing `RUN_PROVENANCE.txt`; commit the landed outdir, refit dir, logs (the WTC landing's
   precedent: commit the landed wave, the refit dir and the landing logs).
3. **Marcus rules** adoption, the name, the module-check reference.
4. **Adoption** (precedent 10-13 f): `git mv` the refit dir to its registered name; R/paths.R `CCX_MODE_CANONICAL`,
   `CCX_MODE_FILES`, `CCX_MODE_PINNED`, `CCX_MODE_CANONICAL_PINS`, `CCX_MODE_CANONICAL_MODULE_CHECK` (the new check file);
   README / DESIGN / DATA mentions; `calibration/torch/make_bundle.sh`; **remove the FLASK branch from `ccx_ms_reference_set()`
   and test-ms-reference-set (16)**, keeping `CCX_MODE_FLASK_*` as records; the full suite, classifying every failure without
   editing a test; the ledger.
5. **Post-adoption** (precedent 10-13 g ff): MCMC 4 × 200k (`run_mcmc_check.R`, ~16.6 h), `read_mcmc_check.R`,
   `diag_mcmc_identifiability.R`; futures band (`build_futures_ribbons.R --draws`, ~216 min on 8 cores; add the mode to
   `RB_COV_EMIS`), `promote_futures_ribbons.R` (the app stops drawing the band once the canonical changes, until rebuilt;
   `test-futures-ribbons.R` pins `hilda31w`); constraint map, `diag_pulse_vs_tcre.R`, card 8, ocean card, `ALPHA_AS_FCO3`, both
   precomputes, `APP_RELEASE_MODE`.
6. **The app's series must follow the fit** (Marcus's rule): unchanged from the item-2 handoff §3. `APP_OBS` swaps MLO to flask via
   `ccx_obs_co2_scored(..., TRUE, monthly = TRUE)`; check `plot_keeling()`, `plot_seasonal()`, `app_keeling_numbers()`,
   `app_seas_window()` against flask's gaps (1–7 months a year in 1963–68; 2025 has 2); never pass `APP_OBS` to
   `dg_gate6_obs()`; `rv_rep_dc()` / `RV_REP_OBS_NH` 0.738 and `rv_gradients()` recomputed on flask; item 8's text (Marcus's
   wording); the Under the hood table and `DLS$co2_obs` / `DLS$d13c_obs` credits. The publish is Marcus's.

## 5. Non-obvious state

- **File starts**: `CCX_MS_FILE_STARTS` resolves a relative path against the project root (a frozen tree reads its own copy).
  Every start file records `file_starts_path/md5/n`, `file_start_name`, `file_gate`. The collector benchmarks only FILLED slots
  (`file_starts_n`) and requires one file md5 per survey. A missing reference start no longer says "port NOT verified" when the
  starts that ran checked it.
- **The read's `FR_START_IDS`** = c(canonical 1, t8c_block 6, t8f_newton 7); `FR_WAVE_GLOB` / `FR_MODE_GLOB` find the landed
  wave and refit by pattern (exactly one match required) or take `CCX_FLASK_WAVE` / `CCX_FLASK_MODE`.
- **Both module-check runs write the same rds name** (`iav_module_<date>_<base>.rds`); the chain copies each to `…_vs_<ref>.rds`
  (+ log) before the next, so the un-suffixed file is the `own` run.
- **Clean up after landing:** `git worktree remove` the dry-run tree `~/ccx_frozen/20261023f_flask_chaindry`; the run tree
  `20261023_flask` once the land's copy is verified (it holds untracked logs, so `--force` after checking `RUN_PROVENANCE.txt`).
- **Label plumbing** (unchanged): a logpost under the flask label is a different objective on the three MLO CO₂ rows;
  `ccx_obs_co2_scored(monthly = TRUE)` relabels flask rows "MLO"; gate 6 refuses a flask-swapped obs.
- **Memory budgets:** `INDEX_ccx_seas.md` 10.9 KB; `INDEX_ccx_ocean.md` 311 B under its soft budget; `INDEX_ccx_app.md` over its
  soft budget (from 10-22).
- **Carried over:** f_plot's alt text "Futures" in all three modes; capacity before a live class; cold start ~8 s; the marketing
  list; handoff 10-21 §3.3's science follow-ups; flask CO₂'s MLO cycle is 4.8 % larger and 2.2 d earlier than in situ, unexplained.
