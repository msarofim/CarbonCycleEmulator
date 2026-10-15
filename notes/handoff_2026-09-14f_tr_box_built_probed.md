# Handoff — 2026-09-14 (f). **THE TROPICAL SURFACE BOX IS BUILT (`hilda_tr`, both cores, 40 boxes, `test-tr-box.R` 238/238) AND PROBED UNREFITTED: PT1 FAILS (B1 +101.6, z +6.8, for the first build's +133), and the reason is measured — the cell's source layer is diffusively slaved to the cold mixed layer at 69× the loop's replacement rate, and the tropical box itself tracks layer 1 through the ML base's kz. Two build choices stated (D2, R6-knob); rulings R5 / R6 and a DESIGN question (a tropical COLUMN vs a kz lever) are Marcus's; the array is NOT launched. Canonical `hilda30c` unchanged; `hilda_eq` / `start_011` reproduce bit-exactly; nothing adopted.**

> Self-contained. HEAD after this note's commit (build `c4a13be`, prereg amendments the commit after). CHANGELOG 09-14 (f). Memory:
> [[ccx_tr_box_built_probe]] (in `INDEX_ccx_ocean_circ`; `INDEX_ccx` live line updated). Prereg (build tier, with §8 amendments and §9
> the reading): `notes/prereg_2026-09-14f_tr_box_build.md`. Previous: `handoff_2026-09-14e_tr_box_product_built.md` (its §4 is what
> this session executed), `handoff_2026-09-14a_eq_cell_prelaunch_review.md`.

## 1. What was built (all committed; the suite's verdict is in §5)
- **Model (`R/model.R`)**: `ccx_box_names(nl, hs, eq, tr)` (`tr` after `eq`; 40 boxes with all on; no existing index moves); `ccx_tr_on()`
  (mirror boxes, a mixed pair errors "MIRROR BOXES"; `tr` does not require `eq`); defaults `tr_frac_*` 0, `h_tr`, `sst_tr`, `sst_tr_enso`,
  `alk_tr`, `q_tr` 0 (R4), `kz_tr_frac` 1 (R6). `ccx_prepare()`: `a_tr = tr_frac·a_oc`, **`a_ml = a_ls − a_eq − a_tr`**, the interior keeps
  `a_ls`; range checks by name; the D1 guard covers `tr`; aux fields `tr_on, a_tr, h_tr, tr_mass_kg, asx_tr, sst_tr, sst_tr_enso, alk_tr,
  tr_q_share, ml_pump_share, kz_tr, dic0_tr, revelle0_tr, tr_C0`. Deriv: the loop re-routed `oc[k] → eq → tr → oc[k]` (with `tr` off the
  09-13g limbs, bit for bit); `tr`'s own air–sea (cell idiom, `sst_tr + sst_anom_h + sst_tr_enso·enso`); the diffusive `tr`–layer-1
  interface at `kz_tr = kz_tr_frac × kz_int[1]` in the effective-thickness form (`dz_1·a_ls/a_tr`, center `(h_tr + dz_1)/2`); `q_tr`
  lateral limbs (channel `tr_ml`); **D2** — `tr` supplies `1 − ml_pump_share` of the LS pump export (its own DIC-limited scale). Recorder
  `.ptr`; `ccx_tr_box_eigbound()` folded into `ccx_substeps_for()` at each seasonal grid extreme (exactly 0 off).
- **Outputs / readers**: `CCX_OCEAN_BOX_COLS` 14 per hemisphere (`tr_C_, tr_C13_, tr_pco2_` added; C++ `out` 39 wide, `pco2_rec[8]`,
  offsets `11 + 14·hi`); `CCX_SURFACE_BOXES` gains `tr`; `ccx_box_mass_at("tr")`; `ccx_surface_annual_conc` sums every existing
  low-latitude surface box by mass; B1's area map has `tr`; the ocean inventories (R `forcing.R:948`, C++ `IML..NPH`) include it;
  `ccx_flux_boxclass` "ml"; `ccx_out_na_guard_cols` / the run guard drop `tr_*` when off; `test-stability` / `test-ocean-advection`
  filters gained `tr_`.
- **Spinup**: guess at `tr`'s own Henry point; Newton gate `|| aux$tr_on`; ocean_idx includes `tr`. Periodic spinup untouched.
- **Structure (`R/calibrate.R`)**: `ccx_tr_box_obs()`; `ccx_struct_hilda_tr()` = `hilda_eq` block + `tr_frac` 0.3966/0.2149, `h_tr` 42.6,
  `sst_tr` 27.21, `sst_tr_enso` 0.203, `alk_tr` 2299 + **overrides `sst_NH/SH` 17.18/15.35, `sst_eq` 26.33** (assigned by name — `c()` of
  two lists with a duplicated `sst_eq` returns the FIRST on `[[`). **`CCX_STRUCT_LABELS` / `ccx_struct_block()` is the ONE label
  dispatch** (`ccx_apply_structure`, `run_dispersed_multistart.R`'s banner, `test-mode-file`). sbatch: label named; a `hilda_tr` launch
  line exists but is ⚠ NOT to be run before R5/R6.
- **C++ (`src/ccx_core.cpp`)**: `ITR` runtime (after `IEQ`; `NPH` = after_eq + tr_on); Aux/Par fields by name; the block beside the cell's.
  `R/cpp.R`: marshaling by name, `q_tr` default 0, `tr_on` in `ccx_run_prepare`.
- **Tests (`tests/testthat/test-tr-box.R`, 238/238)**: P0a (bit-exact with `hilda_eq` at `tr_frac` 0, both cores, substeps unchanged;
  hilda30c's 25 streams reproduce), P0b, P0c (R/C++ < 1e-12, pump N and D), P0d, P0e, P0f, P0g (loop + interface + `q_tr` 3 Sv on a
  uniform column: 0 to 1e-12; power), N-T1 (bit-exact form), 7 mutations (loop, interface, `q_tr`, `sst_tr_enso`, D2, bound, channels).
- **Probe (`calibration/diag_tr_box_probe.R` → `outputs/diagnostics/tr_box_probe_20260914.{log,rds}`)**: the table in CHANGELOG 09-14 (f).

## 2. What the probe says (unrefitted at `start_011`, `w_eq` 27, γ 0.60)
| arm | B1 | z | PI tr − global | ENSO/obs | Δlik |
|---|---|---|---|---|---|
| REF `hilda_eq` | +133.2 | +11.5 | — | 2.42× | 0 |
| mask change alone | +132.1 | +11.3 | — | 2.42× | −4.9 |
| **T1 as built** | **+101.6** | **+6.8** | **+67.6** | 1.53× | −75.6 |
| `kz_tr_frac` 0.3 / 0.1 / 0 | +132 / +161 / +194 | | +0.5 / −73 / −170 | 3.6× / 5.5× / 6.4× | −119 / −270 / −788 |
| `sst_tr_enso` 0 | +101.7 | +6.8 | +67.6 | 2.50× | −78.7 |
| `q_tr` 1000 (tr ≡ ml) | +100.2 | +6.6 | +80.0 | 1.35× | −65.8 |
**PT1 FAIL; PT6 PASS (2009 vs 1963 ± 50 — the σ hides the 46 µmol/kg that IS the +68); PT7 measured.**
**Mechanism (NH at `start_011`; kz 11,319, `kz_deep_frac` 0.0105):** layer 2 diffusive exchange **3.14 /yr** vs the loop's replacement
**0.045 /yr** — **69×**: the cell exposes the pump + diffusion field's DIC (layer 2 ≈ 2060 µmol/kg) at 26 °C whatever the loop returns.
`tr`'s interface **5.62 /yr** > its air–sea **4.72 /yr**: the box tracks layer 1 (cold-equilibrated) and sits +68 over global. The pump's
divergence field is **50 GtC/yr gross** (vs 70 gross air–sea). The 09-14 (c) counterfactual's +61 (cell air–sea at the ML's SST) removed
the T-exposure itself; no return-path design reproduces it.

## 3. Rulings and the design question for Marcus (nothing launched until taken)
1. **R5** `sst_tr_enso`: the product's +0.20 K/index (cell idiom; slope 1.53× obs) or 0 (ML idiom; 2.50×).
2. **R6** `kz_tr_frac`: 1 as ruled, 0.3 (tr lands at obs but B1 unchanged and −119), or a fitted stratification parameter (not registered).
3. **The design**: T1 as ruled cannot reach +55.5. **T5 — a tropical COLUMN** (tr over its own layers 1–2 that the cell upwells from, so the
   cell's source is warm-equilibrated + the pump's contrast ≈ the DIC-term +56/+43 of 09-14 c) vs a kz lever on the cell's source layer vs
   re-examining the near-surface kz itself (11,300 m²/yr at the ML base outpaces air–sea equilibration on every warm box). My reading:
   the column is the physics; the kz lever is a knob. Also still owed behind it: the residual-ML `h_ml` prior re-cut (58/77 m), `hs_frac`
   0.16 vs 0.126/0.130, `seas_ml` on `tr`, `q_tr` from an observation.

## 4. Non-obvious state
- `aux$pump` is ABSENT when the pump is off, and R's `$` partial-matched it to a field named `pump_ml_share` — renamed `ml_pump_share`;
  a guard-class trap for any future `pump_*` aux field. `switch()` cannot take `""` as a case name (`ccx_struct_block` handles it first).
- `dg_run` at `start_011` takes ~1 s per arm (periodic spinup, C++); the probe's 8 arms run in ~10 s.
- `hilda_eq` keeps `sst_eq` 27.04 (un-re-based) so the first array reproduces; `hilda_tr` reads 26.33 — the "mask change alone" arm is
  exactly that difference plus the ML's 17.18/15.35.
- Standing reds: the GATE Q pair (`test-alpha-as`) and `test-seas-lag-split:205`; the full-suite result of this build is in §5.
- Memory sub-indexes `INDEX_ccx.md` (14.7 KB) and `INDEX_ccx_ocean_circ.md` (14.5 KB) are over the 14 KB soft target, under the ceiling.

## 5. The full suite (`outputs/diagnostics/suite_20260914f_tr_box.log`)
**3194 pass / 9 fail / 1 error / 2 skip** at `c4a13be`: the standing GATE Q pair (`test-alpha-as`, 2) and the 08-30 arm error
(`test-seas-lag-split:205`) — unchanged — plus 7 in `test-eq-cell.R` P0c, which asserted "every `out` column live" under `hilda_eq` and
now met the `tr_*` columns (NA by contract there). Scoped to `ccx_out_na_guard_cols()` in the commit after `c4a13be`; `test-eq-cell.R`
182/182. So the suite is the known pair + the known error, everything else green.
