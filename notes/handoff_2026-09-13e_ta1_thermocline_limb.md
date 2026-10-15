# Handoff — 2026-09-13 (e). **T-A1 RAN: option A's limb with a layer-1 return is right-signed, linear, free — and 4× too weak. The RETURN DEPTH is the open design axis. Ruling owed before the next build step.**

> Self-contained. CHANGELOG 09-13 (e); memory [[ccx_ta1_thermocline_limb_probe]] (+ `INDEX_ccx_ocean_circ` T-A1 line,
> `INDEX_ccx` live-line NEXT). Follows handoff 09-13 (d) (`hilda30c` canonical, unchanged here). Nothing adopted; no core touched;
> suite not re-run (no source under `R/`, `src/`, `tests/` changed — the diag is a one-off).

## 1. What ran
`calibration/diag_ta1_enso_thermocline_limb.R` (prereg `notes/prereg_2026-09-13e_optionA_nino34_thermocline_limb.md`, written
first) at `hilda30c`: the Niño3.4-modulated exchange between the mixed layer and layer 1, `V_eff = V0 − γ_A·Niño3.4` on
`aux$kz_int[1]` through the T-A0 session wrapper on the pure-R `ccx_deriv()`. The limb's mean IS the fitted `kz` (a two-way box
exchange = interface diffusion, V0 = kz_int[1]/dz_mid[1] = 187 m/yr), so γ_A = 0 is the canonical bit for bit (P0: 1.8e-12 ppm;
scorecard reads reproduced to 0.0) and only the anomaly is priced. 87 s per R run; log + rds
`outputs/diagnostics/ta1_enso_thermocline_limb_20260913.*`.

## 2. What it found (P0–P5 in the CHANGELOG table)
- Layer 1 IS DIC-richer than the ML in the annual mean: **+46.8 NH / +45.5 SH µmol/kg** (each box over its mass at the time) —
  0.172 GtC/yr per (m/yr) per index of supply anomaly.
- The response is **right-signed and exactly linear**: slope = −0.1696 + **0.0250**·γ_A (R² 1.00000; −1 mirrors +1 to 0.0 %).
- **4× too weak**: the sign flips at γ_A 6.8 m/yr (65 Sv per index unit); the observed +0.1153 needs **11.4 m/yr = 109 Sv per
  index unit** — 4× T-A0's obs-implied 26 Sv. Only **14.5 %** of the supply anomaly reaches the atmosphere in the year.
- **Cheap**: the price is POSITIVE (+5.07 log-units at 8 m/yr, all `gcb_ocean_sink`); the 2015–23 sink is untouched (2.95 → 2.98).
- **Why**: the layer-1 ↔ ML coupling (0.35 yr) closes the deficit across one interface; T-A0's bottom return (gain 0.100, 4×
  this) propagated it down the column but cost −135 on `d14c_profile_bd`. ⚠ T-A0 never recorded its contrast (like-for-like
  caveat on the "58 %"). ⚠ 26 and 109 Sv are both MODEL-DERIVED scales; my recollection that equatorial upwelling is "tens of Sv"
  is UNSOURCED and labeled so in the CHANGELOG.

## 3. The ruling owed (Marcus)
Option B ruling 2 said "a dedicated equatorial box ONLY if PB1 fails on magnitude". A layer-1 limb on `ml_lo` HAS failed on
magnitude (0.25× at the physical scale). Two ways forward, both un-built:
1. **T-A2, a return-depth scan** (~90 s a run, same wrapper idiom but a NEW limb: upwell layer k → ML, sink ML → layer k, k ∈
   {2, 3, 4}, with a MEAN W0 — for k ≥ 2 the mean is NOT in `kz`, so the mean state moves and the Δ¹⁴C / gradient rows price it
   unrefitted, T-A0's trade-off at shallower depths). Finds where efficiency crosses the price. A probe, no ruling needed to RUN
   it; the ruling is whether its answer is the build.
2. **A dedicated equatorial cell** (the +55.5 µatm reservoir becomes representable; ruling 2's fallback). Weeks; option B's R side
   (`5ed31cf`) is the closest scaffold.
My recommendation: run T-A2 first (a day), because it says whether ANY limb on `ml_lo` can carry the magnitude at an
acceptable Δ¹⁴C price before an equatorial cell is designed around the answer.

## 4. Then, unchanged from 09-13 (d)
**M** (per-hemisphere MLD handle; GATE S still carries the NH mixed layer's 0.107 ppm leak); pin-vs-retire of `ent_seas_amp_SH`;
`sst_seas_amp_SH` 2.4σ under its obs (option K); the root `MEMORY.md` at 18,202 B — the next root edit must SPLIT, not trim
(nothing was added to the root this session; the T-A1 line went to `INDEX_ccx_ocean_circ`, now 8.0 KB).
