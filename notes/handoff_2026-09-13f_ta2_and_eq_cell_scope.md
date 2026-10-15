# Handoff — 2026-09-13 (f). **T-A2 RAN: the return depth decides it — layer 2 carries the whole ENSO ocean response at 26 Sv per index unit with a positive price; deep returns leak decadal ENSO into the CO₂ level. The equatorial cell is SCOPED. Ruling owed: lite limb vs cell.**

> Self-contained. CHANGELOG 09-13 (e) T-A1, (f) T-A2 + scope; memory [[ccx_ta1_thermocline_limb_probe]], [[ccx_ta2_return_depth]]
> (both in `INDEX_ccx_ocean_circ`; `INDEX_ccx` live-line NEXT updated). Canonical `hilda30c` unchanged; nothing adopted; no core
> touched; suite not re-run (no source under `R/`, `src/`, `tests/` changed). Root `MEMORY.md` untouched at 18,202 B.

## 1. What ran today (all unrefitted, all at `hilda30c`, all through the T-A0 session wrapper on the pure-R `ccx_deriv()`)
- **T-A1** (`diag_ta1_enso_thermocline_limb.R`): the Niño3.4-modulated exchange with a LAYER-1 return — right-signed, exactly
  linear, free (+5.1 at 8 m/yr), **4× too weak** (gain 0.025; obs needs 109 Sv per index).
- **T-A2 stage 1** (`diag_ta2_enso_return_depth.R`, γ_A 3): return layer k = 1…10. Efficiency 0.146 / 0.287 / ~0.35 flat below;
  contrast +46 / +97 / +135 / … / +302 µmol/kg; gain 0.025 / 0.104 / 0.182 / … / 0.378. k = 1 reproduced T-A1 exactly.
- **T-A2 stage 2** (`TA2_STAGE=matched`): each k at ITS obs-matching γ_A. **k = 2 (117–190 m): 2.73 m/yr = 26.2 Sv per index,
  Δlik +3.09** (CO₂-level rows −1.45); k = 3: 15 Sv, −0.93; k = 4: 12 Sv, −10.7; k = 6: −49.8; bottom: −59.4 — all of it on the
  CO₂ LEVEL rows, with r falling 0.35 → 0.25. Water not upwelled from a deep box stays there, so the index's decadal structure
  (mean +0.042 over 1959–2024; forcing demeaned exactly, first non-zero 1948) integrates into the level. **The return must be
  shallow for a reason the interannual regression cannot see.**
- **GLODAP cut** (`glodap_dic_talk_subset.csv`, 5 °S–5 °N 160 °E–80 °W, flag 2, 10,568 bottles 1973–2021, raw — labeled):
  DIC over the 0–50 m median 1982.9: +29 (50–100 m), **+115 (100–150), +176 (150–200)**, +223 (200–300). The EUC source water
  IS the model's layer 2–3. Inline in the CHANGELOG (f); not yet a `data/` product.

## 2. The reading
The mechanism (upwelling suppression) is right; T-A1 probed the wrong DEPTH, not the wrong idea; the deep return is wrong for a
decadal reason. **Magnitude does not need an equatorial cell** — a limb on `ml_lo` at layer 2 carries it. What a limb cannot do:
represent the +55.5 µatm reservoir, or give the mean upwelling W0 an observable (on `ml_lo` a mean limb is `kz` by another name).
⚠ Whether 15–26 Sv per Niño3.4 unit is a PHYSICAL modulation needs an EUC/STC transport source — not established; my recollection
("tens of Sv") is unsourced and kept out of every claim.

## 3. The scope — `notes/scoping_2026-09-13_equatorial_cell.md`
- **Lite vs cell** (§1 table): lite = `w_eq`/`gamma_eq`/`k_eq` limb on `ml_lo`, days, W0 un-gateable (pin it to B3's 2.7 m/yr);
  cell = 2 mirror boxes, weeks, B1's +55.5 µatm becomes a row with power on W0. **Recommendation: the cell**, lite as the stopgap.
- **Mirror cells: YES, one parameter set** (§2). A single straddling cell breaks the `for (h in HEMIS)` idiom in both cores, the
  spinup Newton and every hemispheric reader for no physical gain; mirror cells are the HS idiom. The SH-heavy cold tongue is the
  pre-registered SENSITIVITY (asymmetric `eq_frac`), read on `co2_gradient`, not the default.
- **Plumbing** (§3): a shallow overturning loop layer k → cell → `ml_lo` → layer k, `W = w_eq·max(0, 1 − γ·Niño3.4)`, volume-
  conserving, `eq_frac = 0` bit-exact, no cell pump / no seasonal cycle in the first build, own SST + alkalinity, own air–sea.
- **Rows** (§4): B1 reservoir (SOM-FFN, σ owed), the tropical Δ¹⁴C held-out stations, and a RULING on whether the surface DIC/δ¹³C
  reader becomes area-weighted `ml_lo` + `eq`.
- **Data tasks** (§5): `eq_frac` per hemisphere from the SOM-FFN mask, `h_eq` (Holte, new mask), `sst_eq` (+ its Niño3.4
  coefficient), `alk_eq` (GLODAP talk), and the transport SOURCE. **Predictions PE1–PE6** (§6) for the first build's prereg.

## 4. Rulings owed (Marcus), in order
1. Lite limb vs equatorial cell (and, if cell, mirror cells with one parameter set — recommended).
2. `k_eq` = layer 2 (the +97 / 26 Sv choice) or a layer-2/3 split to match GLODAP's +115–176.
3. The surface-reader question (§4 of the scope).
Then, unchanged: **M** (per-hemisphere MLD handle), pin-vs-retire of `ent_seas_amp_SH`, option K, and the ~35 `diag_*.R` that
stop on the pinned canonical (fix each when run).
