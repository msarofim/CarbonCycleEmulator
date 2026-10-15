# Handoff — 2026-09-13 (g). **SIX RULINGS TAKEN; the equatorial cell's data product is BUILT and its transport is SOURCED; the PREREG is WRITTEN. Next session BUILDS (R side first).**

> Self-contained. CHANGELOG 09-13 (g); memory [[ccx_eq_cell_rulings_targets]] (in `INDEX_ccx_ocean_circ`; `INDEX_ccx` live line updated).
> Commits `4f54b64` (rulings + product), `3a4e64a` (prereg + W0 prior). Canonical `hilda30c` unchanged; NOTHING built; no source under
> `R/`, `src/`, `tests/` touched, so the suite was not re-run. Root `MEMORY.md` untouched.

## 1. The rulings (Marcus), all recorded in CHANGELOG (g)
1. **The CELL, as MIRROR CELLS `NH_eq`/`SH_eq`, ONE fitted parameter set** (not the lite limb; not a single straddling box).
2. **`k_eq` = LAYER 2 alone** (117–190 m).
3. **Area-weighted surface reader**: `ocean_grad_*` surface = `ml` + `eq` by mass; bit-exact at `eq_frac = 0`.
4. **`w_eq` (W0) FITTED with prior N(27, 3) Sv** (Meinen, McPhaden & Johnson 2001); **B1 (+55.5 µatm) SCORES** as a row.
5. **B1 σ = 6.77 µatm** — the mask-sensitivity floor (the climatology has no uncertainty field).
6. **`h_eq` = Holte annual MEAN 44.2 m.**

## 2. What exists now
- **`data-raw/build_eq_cell_targets.R` → `data/obs_eq_cell.rds`** (mask 5 °S–5 °N, 160 °E–80 °W; halves lat > 0 / ≤ 0). Components:
  `eq_frac` **NH 0.0480 / SH 0.0356**; `b1` **+55.47** (NH half +43.4, SH half **+67.7** — the cold tongue IS SH-heavy, 1.56×;
  `sd_mask` 6.77, `sd_month` 2.83); `h_eq` **44.2** (max 64.9; NH 40.6 / SH 47.6); `sst_eq` **27.04 °C**, β **+0.97 K per index**
  (⚠ not independent of the index); `alk_eq` **2296**; `dic_eq` by bin (+28/+115/+176/+222 at 50–300 m; NH half +150/+208 vs SH
  +95/+157 at 100–200); **`w0_prior`** (27 ± 3 Sv; 1997–99 swing 50 Sv = **14–25 Sv per index** on this forcing; citations).
  Three regressions against earlier cuts all close (B1 +55.5, band 4.1 %, GLODAP bins). ⚠ A first-draft bottle selector asserted the
  band WRAPS after 0..360 normalization — it does not (160..280); caught by its own `stopifnot` before any number was read.
- **The transport source** (was "unsourced recollection" in (e)/(f) — RETRACT that label): Meinen et al. 2001 *JPO* 31:3230 — mean
  upwelling across 50 m **24–30 Sv** (= **51–64 m/yr** through the cell), interannual p2p 50 Sv ⇒ T-A2's 26 Sv per index is at the TOP
  of the observed bracket; **γ_eq ≈ 0.9–1.1** per index against W0, i.e. the floor `max(0, 1 − γN)` binds near N = +1 (1997 annual +0.84).
  Text extracted from the PMEL scan with `pdftotext` (scratchpad `meinen2001.txt`, not committed). Kessler 2006 review: 30–50 Sv.
- **The prereg — `notes/prereg_2026-09-13g_equatorial_cell_build.md`**, hooks by file:line at `4f54b64`. Key design content:
  state order `atm | land×4 | ml | oc1..10 | [hs, hd] | [eq]` (19/hemisphere, 38 total); resolver `ccx_eq_on(p)` requiring BOTH
  `eq_frac_*` > 0 (a mixed pair errors by name); **D1**: the cell takes area from the MIXED LAYER only (`a_ml = a_oc(1 − f_hs) − a_eq`),
  the interior keeps `a_ls`; **`w_eq` in WHOLE-BAND Sv, split by area ⇒ equal velocity** (63 m/yr at 27 Sv); the three-limb loop
  (`oc[2] → eq → ml → oc[2]`, each `W × source conc`, true per-volume concentrations); own air–sea at `sst_eq(t) = 27.04 + sst_anom_h +
  0.97·enso`, `alk_eq` 2296; no pump / no seasonal / no diffusion; Newton gate `|| eq_on`; outputs `eq_C_h`, `eq_C13_h`;
  R1 = B1 row (2000–2015 mean; cells minus ALL surface boxes by area), R2 = the reader, R3 = the `w_eq` prior via a loader
  (`obs_eq_cell$w0_prior`, never typed). **P0a–g** (no-op, conservation, parity, reader no-op, reader–deriv pCO₂ parity, mirror
  lint, uniform-column fixed point), **PE1–PE9** (PE7 γ_eq ∈ [0.4, 1.1]; PE8 `w_eq` ∈ [21, 33] with B1 z within ±1.5; PE9 the SH-heavy
  split as a ONE-OFF sensitivity on `co2_gradient`), **N1** (γ_eq = 0 ⇒ r unmoved; |Δr| < 0.05 from `sst_eq_enso` alone).
  Proposed mode **`hilda30e`** (struct = `hilda30c` + the pinned geometry; pins unchanged); first array 32 free names
  (`gamma_enso_ocn_*` kept for PE2).

## 3. Next session — the build, in the prereg's §6 order
1. `R/model.R`: `ccx_box_names` (+`eq`), `ccx_eq_on`, defaults (`eq_frac_NH/SH = 0`, `h_eq`, `sst_eq`, `sst_eq_enso`, `alk_eq`,
   `k_eq = 2`, `w_eq = 0`, `gamma_eq = 0`), `ccx_prepare` aux (`a_eq`, `a_ml`, `eq_mass_kg`, `asx_eq`, `dic0_eq/revelle0_eq`, `idx$eq`),
   the deriv block (five items, §2 of the prereg) placed after the HS block, `CCX_OCEAN_BOX_COLS` + the R output twin
   (`R/forcing.R:968-1000`). ⚠ `ml_mass_kg`/`asx`/the ML–oc1 interface must follow `a_ml`, NOT `a_ls` (D1) — grep every `a_ls` use in
   the ML's own limbs before editing.
2. `R/spinup.R`: cell starting guess at its Henry point (the HS idiom `:337-344`); Newton gate `:374-375` gains `|| aux$eq_on == 1L`.
3. `R/likelihood.R`: `ccx_box_mass_at` `"eq"`; R2 in `ccx_model_ocean_gradient`; R1 as `ccx_eq_b1_target()` / `ccx_model_eq_b1()` /
   `ccx_eq_b1_scored()` (the `hs_surface` triple, `:1251-1294`) under a `LIK_USE_EQ_B1` switch.
4. `R/calibrate.R`: `w_eq`, `gamma_eq` in `CCX_PARAM_TABLE` (R3 via `ccx_w_eq_prior()`); `ccx_migrate_par_set` fills absent names.
5. `R/paths.R`: register `hilda30e`. Then `src/ccx_core.cpp` twin (`IEQ`, `Aux`/`Par` fields, `unpack_*`, the block, the output
   columns) + `R/cpp.R` by-name marshaling (send unconditionally, zero-fill when off).
6. `tests/testthat/test-eq-cell.R` = P0a–g; run the FULL suite (the mode-struct lint ratchet and `test-mode-file` will see the new mode).
7. `calibration/diag_eq_cell_probe.R` (PE1, N1, PE6 unrefitted at `w_eq` 27, `gamma_eq` 1) → ONE Torch array → PE2–PE8 → PE9.
Unchanged and still owed after the cell: **M** (per-hemisphere MLD handle), pin-vs-retire of `ent_seas_amp_SH`, option K, the ~35
`diag_*.R` that stop on the pinned canonical (fix each when run). ⚠ The model's `OCEAN_AREA_NH/SH` constants (1.55/2.06e14, marked
*provisional*) now have a source in the SOM-FFN mask (1.543/2.064e14) — a one-line `constants.R` provenance fix, separate commit.
