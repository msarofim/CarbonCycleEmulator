# Handoff — 2026-09-16 (e). **The whole-model review's fixes 3/6/7 landed; OBJECTIVE CHANGE #12 (the hygiene batch) landed, priced per item, every registered mode restamped; a REFIT IS OWED under `hilda_c`. `hilda30c` stays canonical (restamped); nothing adopted.**

> Self-contained. HEAD = `f88b6ac` (+ this note / the counts line). CHANGELOG 09-16 (d) (review + fix 2) and 09-16 (e) (fixes 3/6/7 +
> #12). Memory: [[ccx_whole_model_review_0916d]], [[ccx_objective_12_hygiene_batch_0916e]]; `INDEX_ccx.md` 15.0 KB (over 14 soft — merge
> before the next add). Previous: `handoff_2026-09-16b_o5b_refuted.md` (O5b, the floor, the parking, the memory clean).
> ⚠ The GUI session was relaunched mid-review (not a kernel reboot: uptime 20 d); nothing was lost, the three review agents were resumed.

## 1. Rulings taken (Marcus, 09-16 c/d)
Park the martin arc and write O2 (done 09-16 c). Whole-model review (done, `notes/review_2026-09-16c_whole_model.md`). "Do 3, 6, and 7. Do
(a) for #1 and the most defensible choices for the rest of the hygiene list" (done, this note).

## 2. What is now true
- **Objective #12** (`R/likelihood.R` header at `LIK_D14C_EVERY_BOX`; DESIGN §6 note): five items with reproduction switches —
  `LIK_D14C_EVERY_BOX` (deep/slab Δ¹⁴C rows read HD too), `LIK_LAND_SINK_INFLATE` 3 → 1, `LIK_EXCESS_C14_UPTAKE_CORR` (×1.03 / ×1.08),
  `FORC_SST_PRE1850_MEAN`, and `h_hs`'s Holte HS lognormal (`data/obs_h_hs_prior.rds`). Priced per item at every registered mode
  (`outputs/diagnostics/hygiene_batch_price_20260916.log`): canonical +2.32 / −26.95 / +1.17 / +0.59 (prior −1.69) = **−22.76**.
  **The cost is item (ii) alone** — the land sits +1.0 GtC/yr over GCB 2015–24 and now pays for it at the source's σ.
- **Restamped**: `hilda30c` likelihood −1414.7720 / logpost −1450.6873; `hilda31s2` −1412.0130 / −1447.7634; `hilda31p` −1415.1376 /
  −1455.9984; the quarantined `hilda31` pin −1409.4217. Pre-restamp copies: `calibration/output/quarantine/20260916_hygiene_batch_restamp/`.
  ⛔ Every number quoted before 09-16 (e) is on objective #11 — the scorecard, gate 7's z (now +2.0 for the land at its σ), the
  O5/O5b like-for-likes. Flip the five switches to reproduce, or re-measure.
- **Closed by receipts already in the code (no change)**: `CCX_ICE_DISCREPANCY` stays OFF (08-23 measurement: the plateau is the ice
  record's second-best era); the excess-¹⁴C target set stays `table4_obs_range` (the "~130 log-units" was retracted 08-14; 0.7–1.4 measured).
- **Fixes**: F2 `f_luc_perm` absence (09-16 d); F3 retried-transient flag + −Inf in the objective + no retry in the spinup's year map;
  F6 `ccx_fill_prod_c14()`; F7 guards (`alk_hs` units, non-finite `grad_off_*`, `q_conv` under HILDA, four products in `CCX_RUN_INPUTS`,
  `d1_on` spinup guess, HS guard on continuous extremes). Open from the review, by design: F4 (the gradient rows' σ-inflation — your 08-28
  ruling; a two-line alternate scorer would say whether the THC/O5 verdicts flip).
- **Structure-aware `u_hs` prior**: `prior = function(x, p = NULL)` converts the 34–47 Sv bracket at the live `hs_frac` through
  `.ccx_prior_eval()` (all three prior call sites). Under `hilda` bit-exact; under `hilda_c` the centre is 27.3 m/yr.
- **Port targets** regenerated for the refit: `CCX_MS_STRUCT=hilda_c CCX_MS_SEAS_ML=1` (incumbent `hilda31s2` −1762.2 at its point; the
  −314 offset is the constants' + the batch's UNREFITTED price, not a port defect).

## 3. Next step — THE REFIT (owed; Torch; Marcus launches or rules)
- Structure `hilda_c` (09-14 h constants: `hs_frac` 0.128, whole-LS SSTs 22.3/18.7 re-based, `alpha_photo_eps` 15.6), `seas_ml` 1, the
  canonical's pins (`ent_seas_amp_SH = 0`), objective #12. Incumbent start `hilda30c` under its pins (`CCX_MS_PIN` as the 09-13 d array) —
  the port-targets file was generated WITHOUT pins (incumbent `hilda31s2`); regenerate with the array's pins before launch
  (`make_port_targets.R` follows `CCX_MS_PIN`). Consider Torch first — say the verdict out loud.
- Read first from the array: `gcb_land_sink` (does the land come down 1 GtC/yr, and what pays — β_max / q10 / the CO₂ level rows?),
  kz under the every-box Δ¹⁴C rows (the review's finding 1 was a directional pull on exactly this), `h_hs` under its prior, `u_hs` at
  the converted centre, gates 7 / H / GL / Q on the scorecard, `sst_seas_amp_SH`'s z.
- After that: the layer-2 ENSO limb as a REFIT (review avenue 1; prereg first, rule in the physical unit).

## 4. Non-obvious state
- `restamp_mode_objective.R` now applies pins, migrates through `ccx_mode_start()`, and writes `lp_new − logpost_shift` (the file's own
  coordinates). The first attempt wrote the seeded-and-banded logpost; caught before commit, restored from quarantine, re-run.
- `test-enso-demean`'s priced numbers moved +6.4–6.6 everywhere (item ii); re-priced with the receipt. `test-prior-z`'s uniform-under-logit
  claim now reads `fert_k`.
- ~60 archived diagnostics copy `deep = sp$diagnostics$d14c_bottom_box` by hand — provenance; the five LIVE producers use
  `ccx_d14c_deep_read()`.
- The suite gate `ccx_require_run_inputs()` in `setup.R` now checks 13 inputs; a frozen copy MUST carry `data-raw/downloads/nuclear14c/`.
- Untracked, disposable: the two `_smoke` outputs (O1, O5) and `port_gate_id1_20260914.log`.
