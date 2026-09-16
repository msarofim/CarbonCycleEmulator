# Handoff — 2026-09-16. **O6 READ (the land is ¼ of the 1995 ocean bomb overshoot, the ocean's own uptake rate ¾ — and that rate is NOT k_w); O5 (the SEASONAL EXPORT) BUILT, PROBED, PASSES its rule, SOURCED (CMIP6 epc100, confirmed by satellite NPP) and MEASURED at a fixed mixed layer; the O5 × THC 2×2: independent but they do NOT add. `hilda30c` canonical; nothing adopted. Owed: the O5b ruling (separate LS/HS factors, the HS pump on the data's rectified shape), the h_ml floor for arrays, O2's statement if the martin field is parked.**

> Self-contained. HEAD = `ccaaf51` (+ this note). CHANGELOG entries 09-15 (f) (g) (h) and 09-16. Memory: [[ccx_o6_bomb_partition_0915f]],
> [[ccx_o5_seasonal_export_0915g]], [[ccx_export_seasonal_source_0916]] (pointers in `INDEX_ccx_ocean_cell` — 15.1 KB, OVER its 14 KB
> soft target, under the 18 KB hard ceiling: merge before the next add; `INDEX_ccx_ref` 5.6 KB). Root `MEMORY.md` content 11.9 KB, under soft.
> Previous: `handoff_2026-09-15e_o1_probed.md`. Torch was down Wed 09-16 07:00–19:00; nothing here needed it (every probe ran on the Mac).

## 1. What happened, in order (two sessions' worth)
1. **O6 READ** (`calibration/diag_o6_bomb_partition_hilda30c.R`, `a78f5d9`). The literature budget was already in the tree (`data/obs_excess_c14.rds`,
   Naegler & Levin 2006 Table 4). **A framing RETRACTION first:** the 08-12 inference "N&L's rows sum to the input ⇒ paired bomb-on/off" has NO POWER
   (total-minus-pre-bomb also sums to input − decay; measured 0.03 kmol apart). Naegler 2009 (Tellus B 61:372, open, READ) defines excess as total
   minus the 1940s mean; that is now the primary framing (the paired framing moves ~11 kmol between the atm and land rows, ~1 on the ocean). At N&L's
   input (102 kmol), 1995: atm −16 %, land −17 %, ocean +12 % (shares 18.4/15.3/66.3 vs 22.0/18.7/59.3). The atmosphere's short share forces
   `bomb_total` ×1.16 (118.4 vs citable 99–105) and the ocean to 60 × 1.161 × 1.117 = 78.9 kmol (z +3.6). ⇒ O6 (the land) is ¼ of the overshoot,
   the ocean's uptake rate ¾. Marcus: the land quarter NOT pursued.
2. **THE k_w TEST** (`diag_kw_naegler_pin.R`, `01ba2df`; rule stated first): NOT a lever. Raw elasticity of the inventory to k_w 0.17; pinned at
   Naegler's 16.5 cm/h the inventory drops 5.5 kmol at −99 (≈4 of it `bomb_total` 118 → 113), `d13c_level_MLO` −68 holds k_w; kz free changes
   nothing. The sub-ML delivery is the bottleneck.
3. **O5 BUILT** (prereg `notes/prereg_2026-09-15f_o5_seasonal_export.md` `6e68ff4`, before the core edit): `pump_seas_amp` / `pump_seas_lag`,
   STRUCTURAL (not in the table), `s_h = 1 + amp·σ_h·sin(2π(t − (3.5 + lag)/12))`, σ NH +1 / SH −1 (the SST convention), zero-mean, on EVERY pump
   limb (LS both surface boxes + HS), under `seas_drivers`, both cores, bit-exact off. `test-pump-seas.R` 114/114. Suite `suite_20260915f`
   (+ `_counts.log`): 3607 / 2 / 2 + 1 error = the standing reds only.
4. **O5 PROBED** (`diag_o5_seasonal_export_scan.R`): under martin 9.08 the SPO row −252 → −119 raw / −206 → −89 after arm C, the total −895 → −742 /
   −289 → −126; the SPO PHASE lands on obs (+6.05 vs +5.99 mo). PASSES its rule (a)–(c). Honest reading: the rule was in log-lik and the row is
   quadratic — in AMPLITUDE a third of the 0.32-ppm deficit closes (0.248 → 0.358 vs obs 0.585). Layer-2 inversion persists (−67/−71). Arm C put
   h_ml on its floor (32 m; z ≈ −1.8 on the 59.7-centred Holte prior — the first z of −2.8 was against the retired 83.9 centre, corrected).
5. **THE h_ml FLOOR MEASURED** (`diag_o5_hml_pinned_armc.R`): h_ml pinned at the canonical 65.2 m → O5's arm-C gain +123.8 = 76 % of the free gain
   (−287.0 → −163.2); at the prior's 16 % point 42.5 m → 93 % (−134.9). The thin ML bought 37.5 of −125.7. O5 SURVIVES at a fixed reservoir.
6. **THE SOURCE** (`data-raw/build_cmip6_export_seasonal_shape.py` + `build_export_seasonal_prior.R` → `data/obs_export_seasonal_shape_cmip6.rds`,
   `696299c`): CMIP6 epc100, 20 models, 1995–2014, areacello-weighted, the model's bands. **LS: SH amp_rel 0.50 [0.46, 0.58] lag −1.1 mo; NH 0.38
   [0.26, 0.45] lag −1.8. HS: amp_rel 1.4–1.5, peak/mean ≈ 3, lag ≈ 0 — a RECTIFIED bloom the sine on [0, 1] cannot carry.** Nowicki's release has
   NO time axis. **Satellite cross-check** (`build_npp_ocean_seasonal_shape.R` → `data/obs_npp_ocean_seasonal_shape.rds`, Oregon State CbPM/MODIS
   2003–2014): HS amp_rel 1.31–1.41, peak/mean 2.8, lag +0.1 — CONFIRMED; LS phase −1.6 agrees; LS NPP amplitude 0.08–0.10 = a loose lower bound.
   PROVENANCE: models, not observations (the 08-27 class); the satellite is the observational check.
7. **THE 2×2** (prereg `notes/prereg_2026-09-16_o5_thc_2x2.md`, `diag_o5_thc_2x2.R`, `ccaaf51`) at the SOURCE's amplitude (0.5, lag −1) × THC k 10
   W 10: raw interaction +3.5, arm C +1.9 — INDEPENDENT; arm C none −288.6 / **O5 −194.7** / THC −318.6 / both −222.7: THC buys the DIC gradient
   (z +2.6 → +0.3) and pays `d14c_profile_level` −30 + δ¹³C — a net cost ⇒ **they do NOT add under this build.**

## 2. The numbers that matter (all vs the canonical `hilda30c`, like-for-like on the 25 rows)
| martin 9.08 GtC/yr | raw | arm C (PK-2 eight) | SPO row (arm C) | SPO amp / obs 0.585 | DIC z | exc95 z |
|---|---|---|---|---|---|---|
| constant export (A2) | −894.8 | −288.6 | −205.9 | 0.280 | +2.6 | +4.2 |
| O5 amp 1 lag 0 (probe) | −741.8 | −125.7 (h_ml 32 m) / −163.2 (h_ml 65.2) | −88.7 / −103.7 | 0.358 / 0.334 | — | +3.8 |
| O5 amp 0.5 lag −1 (source) | −797.6 | −194.7 (h_ml 47) | −140.7 | 0.334 | +1.8 | +3.9 |
| THC k10 W10 | −1154.7 | −318.6 | −226.6 | 0.271 | +0.4 | +4.1 |
| both | −1054.0 | −222.7 | −148.4 | 0.333 | +0.3 | +4.2 |
Solved field + the factor at amp 1: SPO 1.175 ppm (2× obs, −899) — the mechanism is strong at 45 GtC/yr.

## 3. Open, and the rulings owed
- **O5b (proposed, NOT built):** separate LS and HS seasonal factors; the HS pump driven by the source's unit-mean rectified 12-month shape
  (`shape$SH_HS` / `NH_HS` in the rds) scaled by one amplitude, the LS pump by its sine at the source's 0.5 / −1. The HS box is the Southern Ocean
  next to SPO and its bloom is 3× rectified — the most plausible home of the missing two-thirds of the SPO amplitude. Prereg first; the SOM-FFN SO
  pCO₂ amplitude (`data/obs_so_pco2_seas_amp.rds`, 16.3 µatm @ month 7.5) is the out-of-sample result row to read.
- **h_ml's box floor** → 42.5 m (the prior's 16 % point) for any array (a table change; stated in the prereg convention thereafter).
- **THC:** independent of O5, a net cost after arm C at k 10; park unless the DIC gradient row is re-weighted. `w_thc` prior source still owed.
- **O2's DESIGN §6 statement** (the martin field as the pedagogical limitation) — owed only if Marcus parks the martin arc.
- **T5 / the cell, the deferred `hilda_c` arm** — still parked (Marcus 09-15 f: "4 and 5 can wait").
- Structural facts no candidate has moved: the layer-2 inversion under martin (−67 to −71), the 1995 bomb inventory (z +3.8–4.2 everywhere; the
  objective's own row is 1750-referenced, 51.4 ± 7.6; Naegler 2009's +8 % CO₂-uptake correction of the Peacock/Key obs NOT applied).

## 4. Non-obvious state
- `pump_seas_amp` / `pump_seas_lag` are STRUCTURAL: on `p`, default 0, marshalled by name, NOT in `CCX_PARAM_TABLE` / `CCX_PARAM_NAMES` /
  `CCX_PARAM_ABSENT_OK`; the arm-C probes set them on `base_params`. Registering them is the build-tier step, with the source's prior.
- `data-raw/downloads/cbpm/` holds 1.3 GB of CbPM monthly HDF4 (2003–2014, gitignored); `data-raw/downloads/cmip6_export_seasonal_shape.*` the
  epc100 climatologies. The Pangeo catalogue CSV lives in the session scratchpad (`PANGEO_CAT=` env for the builder), not in the tree.
- `calibration/torch/port_targets.csv` is STILL the E arm's — regenerate before ANY array.
- The summary reporter prints no suite totals: use `as.data.frame(test_dir(reporter = "silent"))` for counts (the `_counts.log` idiom); the first
  commit message of `01ba2df` carried an unread count and was amended before push.
- Untracked, disposable: the two `_smoke` outputs (O1, O5) and `port_gate_id1_20260914.log`.
- Two traps now gated in scripts: CMIP6 ocean fluxes are mol m⁻² s⁻¹ (a kg factor gives 83×); terra reads the Oregon State HDF4 rows SOUTH-first.
- Old scripts annotated stale: `diag_bomb_partition.R` (mode loader + the framing), `diag_excess_c14.R` [3] (the retracted inference).
