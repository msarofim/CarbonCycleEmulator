# Handoff — 2026-09-13 (h). **THE EQUATORIAL CELL IS BUILT (both cores, likelihood, 142 tests) and PROBED unrefitted: PE1 PASS at γ_eq ≈ 0.59 (16 Sv per index), PE6 PASS, N1 attributed, B1 +144 vs +55.5 (z +13). One bug fixed before any read. Nothing adopted. Next: the array (the table change rides in its launch commit — ruled).**

> Self-contained. CHANGELOG 09-13 (h); memory [[ccx_eq_cell_built_probe]] (in `INDEX_ccx_ocean_circ`; `INDEX_ccx` live line updated).
> Previous: `handoff_2026-09-13g_eq_cell_ruled_prereg.md`; prereg `notes/prereg_2026-09-13g_equatorial_cell_build.md`.
> Canonical `hilda30c` UNCHANGED; its stored logpost reproduces under this build (test-eq-cell P0a); no `eq_b1` row exists at it.

## 1. What exists now (the prereg's §6, steps 1–7 except the table)
- **Model**: `ccx_eq_on()`, `ccx_box_names(nl, hs, eq)`, the `eq` box after hs/hd (38 boxes), defaults (zeros = OFF), `ccx_prepare()`
  aux with range checks by name, the three-limb loop + own air–sea in `ccx_deriv()` and `src/ccx_core.cpp` (runtime `IEQ`), D1
  (`a_ml = a_ls − a_eq`; interior + pump on `a_ls`), the ML/layer-1 interface with layer 1's effective thickness, the cell in the
  substep bound (0 when off). **Structure label `"hilda_eq"`** (`ccx_apply_structure`) reads the geometry from `data/obs_eq_cell.rds`.
- **Outputs**: `CCX_OCEAN_BOX_COLS` 11/hemisphere — `eq_C_, eq_C13_` and **`ml_pco2_, hs_pco2_, eq_pco2_`** (the DERIVATIVE's own
  values; R from `record = TRUE` at each month's opening state, handed to `ccx_step_rk4(k1 =)`; C++ from the first RK4 stage via
  `deriv(…, pco2_rec)`). Design refinement on the prereg's R1: the reader is an area-weighted average of these columns, not its own
  carbonate call — the forcing could not be threaded to ~80 call sites. P0e + test-parity hold it.
- **Likelihood**: `ccx_ml_area()`; `ccx_box_mass_at("eq")`; R2 `ccx_surface_annual_conc()` (ML alone, bit-exact, when the cell is
  absent); R1 `ccx_eq_b1_target/model/scored()` under `LIK_USE_EQ_B1`, window `LIK_EQ_B1_YEARS` 2000–2015, σ 6.77, riding in the
  `ocean_grad` bundle as `eq_b1`; `ccx_model_ocean_gradient()` now requires only the columns it reads.
- **Tests**: `tests/testthat/test-eq-cell.R` P0a–g + mutation (142). Four files extended for the `eq_*` NA-by-contract columns.
- **Probe**: `calibration/diag_eq_cell_probe.R` → `outputs/diagnostics/eq_cell_probe_20260913.rds` (5 s).
- **Manifest**: `calibration/lib_run_inputs.R` names `data/obs_eq_cell.rds` (the Torch bundle ships `data/`).

## 2. The bug the probe found (fixed in both cores; CHANGELOG (h))
First read: `co2_seasonal_SPO` −500 at EVERY γ_eq, even `w_eq = 0`, only at `seas_ml = 1`. Under D1 layer 1 (area `a_ls`) took the
whole ML (area `a_ml`) excursion off its THICKNESS → lost `a_ls·Δh` of volume against `a_ml·Δh` of carbon → +37 % concentration at
its ~7 m winter minimum → the locked ML's pCO₂ p2p 15 → 110 µatm. `ccx_grid_at_h_ml(grid, h, share = a_ml/a_ls)`; `share == 1` is the
untouched original. My prereg-time "4 % of the excursion" was wrong by (excursion / winter dz₁). Lesson filed in memory.

## 3. The probe's numbers (reference = hilda30c vector with `gamma_enso_ocn_* = 0`: slope −0.1696, r −0.527; obs +0.1153, r +0.488)
| γ_eq | slope | r | B1 (NH/SH) | z | common-row Δlik | CO₂-level | `gcb_ocean_sink` | max ¹⁴C |
|---|---|---|---|---|---|---|---|---|
| 0 | −0.213 | −0.593 | +154 (+149/+160) | +14.6 | −10.2 | −2.9 | −1.1 | 4.9 |
| 0.5 | +0.069 | +0.195 | +150 | +14.0 | −7.5 | −5.7 | +5.0 | 4.1 |
| 1.0 | +0.302 | +0.549 | +144 (+139/+149) | +13.1 | −18.2 | −9.6 | −0.8 | 3.8 |
- **PE1 PASS**: flip at γ_eq 0.39; observed slope at **≈ 0.59 = 16 Sv per index** at W0 27 — inside the 1997–99 bracket (14–25); the
  cell's gain is 0.021 GtC/yr per (Sv per index), 1.9× the T-A2 limb's 0.011 (the reservoir's ~0.77 yr residence time).
- **N1 FAIL as bounded (Δr −0.065 vs 0.05), ATTRIBUTED**: N1b (γ 0 AND `sst_eq_enso` 0) returns r to −0.527 ± 0.001. The whole
  shift is the cell's own solubility term (+0.97 K/index on a 420–525 µatm box); physical, and the observed net contains it.
- **PE6 PASS**: cell δ¹³C 1995 NH 1.04 / SH 1.28 ‰ (ML 1.48 / 1.70) vs GLODAP Pacific band 1.42 ± 0.30 (n 263).
- **B1 unrefitted +144 vs +55.5 (z +13)**: budget closes exactly (W·ΔDIC = degassing 0.58/0.63 GtC/yr per hemisphere at PI). The
  cell's DIC is the ML's (+8/−3 µmol/kg) but it sits at 27 °C: its Henry DIC is ~200 below layer 2's, retained fraction
  W/(W + A·k_w·K0·∂pCO₂/∂DIC) = 0.386 (model 0.386). Reaching +55 by W0 alone needs ~8 Sv (z −6 on N(27, 3)) and γ_eq ≈ 2. PE8's
  named lacks: the upwelled water arrives at 27 °C at once (real EUC water surfaces cold), no pump in the cell, `k_eq` fixed.
  **The array reads this, not the probe.**

## 4. Next session — the array
1. **RULED (Marcus, 09-13 h): the table change goes in the ARRAY-LAUNCH COMMIT, not before.** Until then `w_eq`/`gamma_eq` stay base parameters and the suite stays green. At launch: put `w_eq` (logit [5, 60], prior N(27, 3) via `obs_eq_cell$w0_prior`, init 27) and `gamma_eq` (id [0, 2],
   flat, init 1) into `CCX_PARAM_TABLE` with the migration contract (absent = 0 = what ancestors RAN; 0 is unencodable under the
   logit box ⇒ `ccx_seed_unencodable()` starts at init), `test-ent-seas-fitted` 31 → 33, the `CCX_PARAM_NAMES` consumers. Expect
   `test-mode-file`'s "carries THIS BUILD's parameter set" (31 vs 33 names) red from that commit until the array's mode is promoted
   (the 09-08d precedent) — accepted by the ruling, not a defect.
2. The array: 32 free names, `CCX_MS_STRUCT=hilda_eq`, `CCX_MS_SEAS_ML=1`, pins `ent_seas_amp_SH = 0`; `make_port_targets.R` /
   `run_dispersed_multistart.R` must accept the new label (grep `"hilda"` literals); `test-mode-file` allows `struct %in% c("", "hilda")`
   and asserts `hs_frac` — extend to `hilda_eq` at promotion. ⚠ Consider Torch first (standing rule); the C++ periodic spinup
   carries the cell at ~1 s per evaluation here.
3. Then PE2–PE5, PE7–PE8 on the array's mode; PE9 (the SH-heavy split) once, read on `co2_gradient`.
4. Still owed after the cell: M (per-hemisphere MLD handle), pin-vs-retire of `ent_seas_amp_SH`, option K, the `OCEAN_AREA_*`
   provenance one-liner (separate commit), the ~35 `diag_*.R` that stop on the pinned canonical.

## 5. Non-obvious state
- `w_eq`/`gamma_eq` are BASE parameters today (defaults 0). `ccx_cpp_par()` defaults them to 0 for older lists.
- `ccx_box_annual_conc()`'s return is unchanged (a bare named pair); the sums live in `.ccx_box_annual_sums()`.
- The eq-cell tests run the aseasonal `ccx_spinup()` under `seas_ml = 1` only where the assertion is parity/conservation; the
  instant-read contracts use `seas_ml = 0` (the aseasonal spinup is not a point on the seasonal orbit — a KNOWN artefact).
- Scratch diagnostics for the bug hunt (not committed) reproduced the isolation: `w_eq = 0` alone raised the ML p2p to 110.
