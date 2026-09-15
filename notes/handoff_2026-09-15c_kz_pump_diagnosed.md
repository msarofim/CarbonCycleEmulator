# Handoff — 2026-09-15 (c). **The kz/PUMP STRUCTURE DIAGNOSED unrefitted at `hilda30c`: diffusion IS the bomb-¹⁴C carrier (70 % at 1975; the pump 19 % growing to 41 % by 2010); kz's hold is SOFT (−86 at × 0.5, −19 at × 0.7 with eight names freed; the δ¹³C rows are NOT its constraint — that prediction REFUTED); the 45-GtC/yr export is a CONSEQUENCE of the solved field demanded by NO row; the model has no advective deep return. Option E CLOSED (ruled). Scoping note written; RULINGS OWED (O1 vs O2; T5; the `hilda_c` arm). `hilda30c` canonical; nothing adopted.**

> Self-contained. HEAD = the commit carrying this note. CHANGELOG 09-15 (b) + (c). Memory: [[ccx_kz_pump_diagnosis_0915]] (new; pointers
> in `INDEX_ccx_ocean` (kz pricing, 12.4 KB), `INDEX_ccx_ocean_cell` (state line, 13.4 KB), `INDEX_diag` (gate craft, 16.3 KB — over soft)).
> ⚠ Root `MEMORY.md` is 18,400 B of its 18,432 B hard ceiling: RESTRUCTURE THE ROOT before adding any line there (nothing was added
> this session). Previous: `handoff_2026-09-15_e_array_read.md`.

## 1. This session, in order
1. **Rulings (Marcus, 09-15 b):** option E CLOSED as refuted (the `pump_field` axis stays built, bit-exact when off); the −1480.47
   mode NOT promoted; the `hilda_c`/solved arm QUEUED; NEXT = diagnose the kz/pump structure unrefitted, then scope. `2e1b76c`.
2. **Prereg** `notes/prereg_2026-09-15b_kz_pump_diagnosis.md` (P1–P4 before any edit; amendments A1 slab-read correction, A2 gate
   tolerance re-derived, A3 arm C post-hoc with P2C — all stamped, none silent).
3. **The ¹⁴C EDGE RECORDER** on the R derivative (`R/model.R` `.rec14`; `R/forcing.R` `ccx_run(edge_fn =)`): recording only; tap
   proven complete (`test-fluxes.R` +2 tests). C++ untouched. Suite `outputs/diagnostics/suite_20260915c.log`: the standing reds only.
4. **PK-1** `calibration/diag_kz_pump_pathways.R` → `outputs/diagnostics/kz_pump_pathways_20260915.{log,rds}` (194 s, R path).
5. **PK-2/3/4 + arm C** `calibration/diag_kz_pump_scan.R` → `kz_pump_scan_20260915.{log,rds}` (~25 min; arm C 6 min/point).
6. **Scoping** `notes/scoping_2026-09-15c_kz_pump_structure.md` — §3 options O1–O4, §4 rulings.

## 2. The numbers that matter (all in the logs / memory file)
| | kz × 0.5 | kz × 0.7 |
|---|---|---|
| arm A raw | −1105 (CO₂ rows −754, bomb −192) | −296 |
| arm B land three | −295 (bomb −202, sink −28, profile_level −28, δ¹³C −4.4) | −74 |
| arm C + kz_deep_frac, h_ml, k_w, bomb_total, sigma_d14c | **−86** (sigma_d14c 5.5 → 7.5; survivors sink −21, d14c_SH −22, seas SPO −13) | **−19** |
Export ∝ kz (15.9 … 63.6 GtC/yr at × 0.35 … 1.4), DIC-gradient row unmoved. PK-3: f 0.089 → −124 (`d14c_profile_ab` −49).
PK-1 entry shares 1975: diff 51 / entrain 19 / pump 19 / HS 12 %; 2010: 28 / 10 / 41 / 22. WOCE 1995 overshoot z +2.9, 22.7 of 31.4 kmol via the pump.

## 3. Rulings owed (Marcus) — scoping §4
1. **O1** (prescribed export + a MEAN deep return limb; return depth the axis; a build + a Torch array) vs **O2** (document as the
   pedagogical model's limitation; price 0) — or O2 now, O1 next.
2. Whether **T5 / the cell** resumes under O2's stated limitation or waits for O1.
3. The queued **`hilda_c` / solved arm** — still wanted (~5 h Torch)?

## 4. Non-obvious state
- `port_targets.csv` is still the E arm's (hilda_c / martin / 4 pins); regenerate before ANY array.
- Torch: queue empty, no stray `ccx_setup_*`/`ccx_diag_*` dirs (checked 09-15); login load ~52.
- Arm C's Nelder–Mead visited two non-converging spinup points (warnings in the log); the final points reproduce the mode to 9e-7.
- The carbon-edge monthly closure miss (~50 %) is a quadrature property of a gross-dominated budget, NOT a missing term (boxnet ≡ dy
  checked directly at the `hilda30c` state); do not chase it.
- Untracked stray: `outputs/diagnostics/port_gate_id1_20260914.log` (a pre-split duplicate of the `_mac`/`_torch` pair) — left alone.
- Standing reds unchanged: GATE Q pair (`test-alpha-as`), `test-seas-lag-split:205`.
