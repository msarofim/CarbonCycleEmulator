# Handoff — 2026-09-16 (e), end of session. **O5b refuted and the martin arc PARKED (O2 written into DESIGN §6); the whole-model REVIEW done; its bug fixes landed (2, 3, 6, 7); OBJECTIVE CHANGE #12 (the hygiene batch) landed, priced per item, every registered mode RESTAMPED; the `h_ml` floor is 42.5 m. `hilda30c` stays canonical. A REFIT IS OWED under `hilda_c`; the array is NOT launched.**

> Self-contained for a cold start. HEAD = `fd88650`. Read with `INDEX_ccx.md` (15.0 KB — merge before adding) and, for the ocean arcs,
> `INDEX_ccx_ocean_pump.md` (new this session). CHANGELOG entries 09-16 (b) → (e). Memory written this session:
> [[ccx_o5b_hs_rectified_bloom_0916b]], [[ccx_whole_model_review_0916d]], [[ccx_objective_12_hygiene_batch_0916e]], the new sub-index
> `INDEX_ccx_ocean_pump.md` (split off `_cell`), the floor/band term and #12 lines in `INDEX_ccx.md`. Earlier session handoff (O5b detail):
> `handoff_2026-09-16b_o5b_refuted.md`. Review note: `notes/review_2026-09-16c_whole_model.md`.
> ⚠ The GUI session was relaunched mid-review (uptime says no kernel reboot); nothing was lost — check `ps` for R processes before launching
> anything, and note the load average was 80+ from apps relaunching.

## 1. Rulings taken this session (Marcus), in order
1. O5b: prereg, build, probe → REFUTED by its own ppm rule. 2. `h_ml` box floor → 42.5 m (a table change). 3. THC parked.
4. Memory clean, then park the martin arc and write O2's DESIGN §6 statement → done. 5. Whole-model review → done.
6. "Do 3, 6, and 7" (review fixes) and "(a) for #1 and the most defensible choices for the rest of the hygiene list" → done as objective #12.

## 2. What is now true (the numbers a next session must not re-derive)
- **Objective = #12** (five items, each with a reproduction switch; `R/likelihood.R` at `LIK_D14C_EVERY_BOX`, DESIGN §6 note): (i) the
  deep/slab Δ¹⁴C rows read EVERY box in their window, HD included (`ccx_d14c_window_read` / `ccx_d14c_deep_read`); (ii) land-sink σ at
  GCB's 0.5, `LIK_LAND_SINK_INFLATE` 3 → 1; (iii) Naegler 2009's net-uptake correction ×1.03 / ×1.08 on the excess-¹⁴C centers; (iv) pre-1850
  SST anomaly at the product's 1850–1900 mean (`FORC_SST_PRE1850_MEAN`); (v) `h_hs` under the Holte HS lognormal (median 175.4 m, log-sd
  0.422; `data/obs_h_hs_prior.rds`, `data-raw/build_h_hs_prior.R`). Priced per item at every registered mode
  (`outputs/diagnostics/hygiene_batch_price_20260916.log`): canonical **+2.32 / −26.95 / +1.17 / +0.59, prior −1.69 = −22.76 on the
  likelihood**. The cost is item (ii) alone — the land is +1.0 GtC/yr over GCB 2015–24 and now pays at the source's σ.
  CLOSED unchanged by receipts already in the code: `CCX_ICE_DISCREPANCY` OFF; the excess-¹⁴C target set `table4_obs_range`.
- **Restamped** (`calibration/restamp_mode_objective.R`, now pin/migration-aware, logpost in the FILE'S OWN coordinates):
  `hilda30c` likelihood **−1414.7720**, logpost **−1450.6873** (was −1392.0158 / −1426.2428); `hilda31s2` −1412.0130 / −1447.7634;
  `hilda31p` −1415.1376 / −1455.9984; the quarantined `hilda31` pin −1409.4217. Pre-restamp copies:
  `calibration/output/quarantine/20260916_hygiene_batch_restamp/`. The canonical's price over its free parent −2.76; over the control +0.37.
  ⛔ EVERY number quoted before 09-16 (e) is on objective #11 (the scorecard, gate 7's z — now +2.0 for the land — the O5/O5b like-for-likes).
- **`h_ml`'s box floor 42.5 m** (`CCX_HML_FLOOR_M`); `ccx_mode_start()` carries a band term so gate 4 closes; the band-blind
  `ccx_unc_to_par(md$u_mode)` is WRONG for every pre-09-16 file (adopt the band, then `ccx_check_mode_decode()`).
- **`u_hs`'s prior converts its Sv bracket at the LIVE `hs_frac`** (`prior(x, p)` via `.ccx_prior_eval()`): 21.8 m/yr under `hilda`,
  27.3 under `hilda_c`.
- **Fixes landed**: F2 `f_luc_perm` absence (R ran 90 % cleared); F3 retried-transient flag + −Inf in the objective + no retry in the
  spinup's year map; F6 `ccx_fill_prod_c14()`; F7 guards (`alk_hs` units, non-finite `grad_off_*`, `q_conv` under HILDA, four products +
  `obs_h_hs_prior` in `CCX_RUN_INPUTS` = 13, `d1_on` spinup guess, HS guard on continuous extremes). Open by design: F4 (gradient rows'
  σ-inflation, your 08-28 ruling) and F5 is now item (iv).
- **The martin arc is PARKED; O2 is in DESIGN §6** (the diffusive column with no advective return: diffusion carries the bomb ¹⁴C ⇒ kz
  10,964 ⇒ the solved export must be 45 GtC/yr ⇒ prescribing the observed 9 inverts the sub-ML gradient; every candidate measured, none
  closed it; the 1995 inventory z +4 everywhere). The martin machinery (`pump_field`, `w_thc`, `pump_seas_*`, `pump_hs_seas_*`) stays
  in both cores at 0 as the instrument.
- **Suites**: fixes 3/6/7 tree 3698/2/6+1; the batch tree **3703 / 3 / 6 + 1** = the standing reds (GATE Q pair `test-alpha-as:110,111`,
  `test-seas-lag-split:205`) + `test-gate-bounds:235`, re-derived and green (`fd88650`). ⚠ A frozen copy MUST carry
  `data-raw/downloads/nuclear14c/` or twenty ¹⁴C bit-identity tests fail like a build regression (`setup.R` now gates on it).
- Port targets: `CCX_MS_STRUCT=hilda_c CCX_MS_SEAS_ML=1`, NO pins (incumbent `hilda31s2`, offset −314 = the constants' + the batch's
  unrefitted price, not a port defect). **Regenerate WITH the array's pins before launch.**

## 3. The review's conclusions that decide what comes next (`notes/review_2026-09-16c_whole_model.md`)
- Structure: 22/30 names justified; five shims (`rep_dC`, `grad_off_d13c`, `gamma_enso_ocn_*` with an inverted split, `sst_seas_amp_*`
  30 % under obs, the pinned shim); `q10` a candidate shim (test: refit without the δ¹³C level rows). Seven contradictions — the three
  that bind the refit (`hs_frac` 0.128, whole-LS SSTs 22.3/18.7, `alpha_photo_eps` 15.6) are `hilda_c`'s block; `h_hs`'s prior is now
  built; `pump_mode` N/D still never ruled; `ccx_default_params()` is the INVERSE of the canonical on `seas_ml` and the shim (mode-based
  consumers are safe; never run a bare-defaults column).
- Mismatches in seven groups; the release blocker is M2 (ENSO → ocean: solubility-only r −0.527 vs GCB +0.115 ± 0.025).
- Avenues, ranked: (1) the Niño3.4 LAYER-2 RETURN LIMB as a REFIT (T-A2: the whole observed slope at 26 Sv/index, +3.09 unrefitted);
  (2) the hygiene batch first — DONE except the refit; (3) an advective-return ocean = the next model class; then option K, option B, G′.

## 4. NEXT STEP — the refit: STAGED AND LAUNCHABLE (09-16 f), blocked only on Torch authentication
- DONE 09-16 (f): port targets under the full pin set (30 free), Mac preflight ids 1/2 PASSED, bundle at `/tmp/ccx_torch_bundle.tar.gz`
  (rebuild with `bash calibration/torch/make_bundle.sh` if the tree moves), both commands in `multistart.sbatch`'s header. BatchMode ssh to
  `torch` exits 255 — no live ControlMaster; Marcus opens the channel (VPN + gateway + Duo + device code), then either runs the three
  commands or tells Claude to ("submitted by Claude over the live ControlMaster on Marcus's instruction" is the 09-14 precedent).
- Sequence: `scp /tmp/ccx_torch_bundle.tar.gz torch:/scratch/ms17839/` → untar into `/scratch/ms17839/CarbonCycleEmulator` → PREFLIGHT
  array (15 min, 24 tasks) → read 24/24 `PORT GATE (a) PASSED` + `LAUNCHABLE` → the wave `--array=0-23%24`, 6 h wall, `cs`.
- Pins: `ent_seas_amp_SH=0,w_eq=27,gamma_eq=1,pump_export=9.08,w_vent=0,gamma_vent=0,w_thc=0`; struct `hilda_c`; seas_ml 1; field solved.
### (the original §4 text, still the read plan)
- Structure `hilda_c`, `seas_ml` 1, the canonical's pins (`ent_seas_amp_SH = 0`; `CCX_MS_PIN` as the 09-13 d array), objective #12,
  incumbent start `hilda30c`, new-basin `hilda31p`. Steps: regenerate port targets with the pins → bundle (`calibration/torch/make_bundle.sh`,
  ships `nuclear14c`) → submit `multistart.sbatch` → the port gate must PASS on Torch before anything is read. Say the Torch verdict out
  loud (`consider_torch_first`).
- Read first: `gcb_land_sink` (does the land come down 1 GtC/yr, and what pays — β_max / q10 / CO₂ levels?), kz under the every-box Δ¹⁴C
  rows, `h_hs` under its prior, `u_hs` at 27.3, the scorecard's 7 / H / GL / Q, `sst_seas_amp_SH`'s z, whether the `seas_ml`-0 control
  still loses. Promotion = a new label (never an in-place edit of `CCX_STRUCT_HILDA`), then restamp nothing — a fitted mode is stamped.
- After it: prereg the layer-2 limb refit (rule in the physical unit; W0 pinned to Meinen 2001's 51–64 m/yr; γ prior 14–25 Sv/index).

## 5. Non-obvious state
- The restamp tool's first run wrote the seeded-and-banded logpost (would have failed every gate 4); caught, files restored from
  quarantine, re-run — the committed files are correct (`objective_history` inside each records both).
- `test-enso-demean` re-priced (+6.4–6.6 everywhere, item ii): canonical 49.7606, control 41.6102, pin 50.3934 / 60.0855.
  `test-prior-z`'s uniform-under-logit claim now reads `fert_k`.
- ~60 archived diagnostics copy `deep = sp$diagnostics$d14c_bottom_box`; the five live producers use `ccx_d14c_deep_read()`. Provenance.
- `INDEX_ccx.md` 15.0 KB and `INDEX_cmp_pulse` 17.1 / `INDEX_diag` 16.3 / `INDEX_slr` 16.3 / `INDEX_ais` 15.0 / `INDEX_ccx_arch` 14.6 are over
  their soft targets (all under 18 hard): split, don't trim, when next touched.
- Untracked, disposable: the two `_smoke` outputs (O1, O5) and `port_gate_id1_20260914.log`. FaIRtoFrEDI repo: one pre-session commit
  unpushed on `heat-ed-morbidity` (not mine); the CLAUDE.md sub-index registration IS pushed.
