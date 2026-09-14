# PREREG (build tier) — OPTION D + E: the PRESCRIBED-EXPORT PUMP and the MODE-WATER VENTILATION LOOP (`hilda_e`)

**2026-09-14 (h). Written BEFORE any core edit, from HEAD `3e93222` (+ the E4 data product, this session).** Implements the
rulings Marcus gave 09-14 (h) on `notes/scoping_2026-09-14g_option_e_ventilation.md` §3 ("follow the recommendations; for E4,
Nowicki if it includes uncertainty bounds"). Every number below is read from `data/obs_pump_export_prior.rds`
(`data-raw/build_pump_export_prior.R`, this session), from the canonical `hilda30c` vector, or from the 09-14 (g) preview
(`calibration/diag_tr_box_martin_preview.R`) — nothing is recalled. Hooks are named by file:line as of `3e93222`.
`hilda30c` stays canonical; every registered mode stays bit-reproducible; nothing is adopted here.

## 0. The rulings this build implements (Marcus, 09-14 h — the recommendations of the scoping note, each as recommended)
- **E1 — prescribed export × Martin shape, gradient EMERGENT.** `pump_grad` retires under the new field; the solved field stays
  reachable (every registered file reproduces) behind a NEW switch `pump_field` = `"solved"` (default) | `"martin"`. ⚠ The
  scoping note said "the existing `pump_mode` switch" — wrong: `pump_mode` is the N/D export LAW (nutrient- vs DIC-limited,
  `R/model.R:1492`), orthogonal to the field's CONSTRUCTION. Both switches stay; `pump_mode` applies to either field.
- **E2 — subduction into layers 1–3, thickness-weighted return from the same layers.** `k_e1 = 1L`, `k_e2 = 3L` (structural,
  not fitted); weights `w_k = dz_k / Σ dz` over the ANNUAL-MEAN grid (layer 1's seasonal excursion does not move the weights —
  stated, so that the weights are constants and the loop's volume is conserved at every instant).
- **E3 — ONE limb.** `W_E(t) = w_vent [Sv] × a_ls share_h × max(0, 1 − γ_e · Niño3.4)` — the cell's floor form (`R/model.R:2834`).
  The mean loop and the ENSO modulation share physics. Under `pump_field = "martin"` with `w_vent > 0`, **`gamma_enso_ocn_NH/SH`
  are PINNED at 0** for the array (option A is subsumed; the 09-01 signed air–sea term stays in the code for the old modes).
- **E4 — Nowicki et al. 2022 WITH its bounds, computed from its data release.** Prior on `pump_export` (the LS export, GtC/yr):
  lognormal, median **9.08**, log-sd **0.148** (2.5/16/50/84/97.5 %: 6.79 / 7.83 / 9.08 / 10.52 / 12.13). The width is the IQR of
  the sum-of-per-cell-percentile maps [8.12, 9.92] — an OUTER bracket of the ensemble's IQR of the total (comonotonic
  assumption; the true IQR is narrower) — and is ENSEMBLE-INTERNAL: the cross-method literature spread (5–13 global) is wider,
  and the prior's 2σ range (6.8–12.1 LS ≈ 7.6–13.7 global-equivalent) is where the two meet. The global integral reproduced the
  abstract's 10.2 (10.25) and its pathway shares (0.72/0.10/0.19 vs 0.70/0.10/0.20) before anything was saved.
  Hemispheric split ∝ `a_ls` (Nowicki's own LS split is NH 0.431 / SH 0.569; the model's a_ls share is 0.429 / 0.571; the
  per-area export is 29.6 vs 29.1 gC m⁻² yr⁻¹ — the same number). The export HORIZON is the ML base: Nowicki's euphotic depth
  averages 67.6 m; `h_ml` is 65.2 at the canonical. HS cross-check: 24.8 gC m⁻² yr⁻¹ on Nowicki's grid vs the shipped HS prior
  median 22.9 — the two products agree.
- **E5 — E first, then re-read the cell.** T5 only if the cell's B1 stays > +70 with E in.
- **E6 — the refit may move** `kz`, `kz_deep_frac`, `pump_export`, `w_vent`, `gamma_vent`, `h_ml`, `u_hs`, `h_hs`, and every name
  the canonical fits except the pins; the deep-row set and the bomb rows are scored as today (no new row, no σ change).

## 1. What is built — parameters, field, loop
**New parameters** (`ccx_default_params()`): `pump_field = "solved"`; `pump_export = 0` (GtC/yr, LS total, both hemispheres);
`w_vent = 0` (Sv, whole-LS, split by `a_ls` share); `gamma_vent = 0` (per index); `k_e1 = 1L`, `k_e2 = 3L`. Absence ≡ the defaults ≡ the
09-14 (g) model, on both cores. New constant `MARTIN_B = 0.858` (Martin et al. 1987 DSR 34:267, p. 273, status "data";
`lib_martin_shape.R`'s literal moves to it). New reader `ccx_pump_export_prior()` (the lazy idiom, `R/calibrate.R:76`).
**The field** (`ccx_pump_export()`, `R/model.R:3169`): under `"martin"`, per hemisphere `E_h = pump_export × a_ls_h / Σ a_ls`
and `S_k = E_h [F(z_{k−1}) − F(z_k)] / F(h_ml)`, `F(z) = (z / h_ml)^−MARTIN_B`, interfaces `z_k = cumsum(dz)`, with the flux
through the seafloor (`F(3700)/F(65) = 3.1 %`) deposited in the bottom layer so the budget closes (no sediment). `pump_export = 0`
under `"martin"` returns NULL — the no-pump model, the `pump_grad = 0` contract. `pump_carb_frac` and `pump_mode` apply unchanged;
`ml_pump_share` (D2) applies unchanged. `pump_grad` is IGNORED under `"martin"` (a guard errors if it is fitted there: see §2).
**The loop** (`ccx_deriv()`, after the cell block `R/model.R:2801`): per hemisphere, `W = w_vent × SV × a_ls_h/Σa_ls × max(0, 1 −
gamma_vent × enso)`; for `k` in `k_e1..k_e2`: `ml → oc[k]` at `W w_k × y[iml]/(a_ml h_ml(t))` (subduction; the ML's TRUE per-volume
concentration under D1 — `a_ml`, and `gr$dz[1]` NOW) and `oc[k] → ml` at `W w_k × y[oc_k]/(a_ls dz_k)` (return). `alpha13 = 1`,
bulk (⛔ no ¹⁴C fractionation). Labels: the return limb `lab = NULL` (int → ml classifies as ml_int); the subduction limb likewise.
A uniform column has zero tendency (fixed point) BY CONSTRUCTION, per box — the P0 contract. With `tr` on, E's limbs still attach
to the residual ML (the subtropical gyres ARE the residual under R2); `tr`'s water comes through the cell. Stated, not tested here.
**C++ twin** (`src/ccx_core.cpp`, after the cell block at :867): `P.w_vent, P.gamma_vent`, `A.k_e1, A.k_e2, A.e_w[NL]` (the weights,
zero outside the band), `A.e_share[2]`. `R/cpp.R:325` gains the two names; `:119` the aux fields.
**Guards** (`ccx_prepare()`): `pump_field` ∉ {"solved","martin"} errors by name; `w_vent > 0` with `pump_field == "solved"` errors by
name (the scoping's D1 lesson: the solved field is no longer the fixed point's operator); `k_e1 ≤ k_e2`, both in `1..nl`;
`w_vent ≥ 0`, `gamma_vent ≥ 0`, `pump_export ≥ 0`, all finite. The D1 guard at `:3247` is NOT widened: E's limbs are written in the
cell's idiom and close under D1 (tested, P0c).
**Stability**: `ccx_e_loop_eigbound(p, grid)` = `2 × max_k( W w_k /(a_ml h_ml), W w_k /(a_ls dz_k) ) × (1 + |γ_e| × 3)`, at both
seasonal extremes (the 09-09i lesson), added to `ccx_substeps_for()`; exactly 0 at `w_vent = 0`.
**Spinup**: no change to the Newton; the periodic spinup is the objective's spinup. If the Newton fails to converge under
`"martin"` at the canonical vector, THAT is a finding, recorded, not patched.

## 2. Parameter table (`R/calibrate.R`) — 33 → 36 names
`pump_export` (log; prior = `ccx_pump_export_prior()`, lognormal 9.08 / 0.148; init 9.08), `w_vent` (logit [0, 60]; ⚠ PRIOR OWED:
no STC subduction transport is sourced in the repo — until one is, FLAT on the box, and the prereg SAYS the data rows set it;
init 20), `gamma_vent` (logit [0, 2], flat, init 0.5 — the cell's idiom). Migration contract: absent = 0 = OFF (what every ancestor
ran); `CCX_PARAM_ABSENT_OK` gains the three. `pump_grad` stays in the table; the E array PINS it (`CCX_MS_PIN`) at the canonical
314.1 because under `"martin"` it does not reach the model — and a guard in `ccx_make_logpost()` refuses a FREE `pump_grad`
under `"martin"` by name (an unidentifiable free parameter is a non-PD Hessian waiting to happen). Likewise `gamma_enso_ocn_*`
pinned at 0 (E3). Structure `hilda_e` = `hilda30c`'s structure + `pump_field = "martin"` (`ccx_struct_block()` idiom).

## 3. Likelihood changes — NONE. (No new row; no σ change; the gradient rows score the EMERGENT gradient exactly as they score
the held one today.)

## 4. Predictions — P0 first; nothing below is read if P0 fails
### P0 — the contracts (`tests/testthat/test-option-e.R`)
- **P0a** every registered mode's 25 stream likelihoods BIT-IDENTICAL with the new names absent AND with them present at their
  defaults (`pump_field = "solved"`, `w_vent = 0`) — R and C++.
- **P0b** conservation: total C, ¹³C-weighted, ¹⁴C-weighted with E on (`w_vent` 20, `gamma_vent` 0.5, `"martin"` 9.08): the residual at
  the model's existing gate tolerance.
- **P0c** the uniform-column fixed point: a column at one concentration everywhere (ML, layers, HS/HD, cell if on) has zero
  advective tendency from E's limbs, with the cell OFF and ON (D1).
- **P0d** R/C++ parity with E on at the test-parity tolerance; the substep count identical on both cores.
- **P0e** the field's budget: `Σ_k S_k = E_h` exactly (the seafloor remainder lands in the bottom layer); `pump_export = 0` →
  `aux$pump` NULL; `"martin"` ignores `pump_grad` (two values, identical trajectories).
- **P0f** mutations: `gamma_vent` sign flip changes the ENSO slope's sign; `k_e2 = 1` vs `3` changes the deep δ¹³C; a guard
  test for every guard in §1.
- **N-E1** (negative control): `w_vent = 0`, `"martin"` with `pump_export` set so that the emergent PI gradient equals the
  canonical's 314 — the two fields' 25 rows within 1 log-unit? ⚠ RE-SCOPED: the Martin shape is NOT the GLODAP shape, so
  the two fields cannot agree row-by-row at ANY export (the preview measured B1 +133 → +98 across them). N-E1 becomes: at the
  export that reproduces the canonical's BOTTOM-minus-ML gradient, the `ocean_grad_dic` row is within 1 log-unit; the deep
  δ¹³C row's shift is REPORTED, not gated.
### PE — the science (`calibration/diag_option_e_probe.R`, UNREFITTED at the canonical vector, then the array)
- **PE-1** at the refit, `kz` at the ML base falls below 4,000 (> 2.7×) with the bomb rows (d14c_NH/SH) within 2 log-units of today.
- **PE-2** the emergent surface–deep DIC gradient lands inside 233 ± 29 at an export inside the prior's 2σ (6.8–12.1 LS).
- **PE-3** the cell's B1 at Meinen's 27 Sv, unrefitted after E's refit, falls below +80 (from +133); PT1 (< +69) is the pass mark.
- **PE-4** the modern surface–deep δ¹³C gradient moves from 0.40 toward 0.89 and GATE GL's 1.97× moves for the first time in four refits.
- **PE-5** the ENSO ocean slope at `gamma_vent = 0` stays solubility-only (r ≈ −0.53); at the `gamma_vent` the observed 14–25 Sv per
  index implies, it flips positive (T-A2's 26 Sv/index at layer 2).
- **Unrefitted probe, this session** (the canonical vector + `"martin"` 9.08 + `w_vent` ∈ {0, 10, 20, 40} + `gamma_vent` ∈ {0, 0.5}):
  the 25 rows, the PI gradient, the deep δ¹³C, the bomb rows, the ENSO slope — READ, not gated. The expected reading: the
  gradient collapses (the export is 5× smaller and kz is the old 10,964) and the bomb rows hold; the array is what moves kz.
- **Not claimed**: that E fixes GATE Q or V; that the tropical band's +7.6 is reached without T5; that the refit converges in one
  array (kz, export and W_E are a new degeneracy triangle — the export prior is what breaks it).

## 5. Rulings still owed (flagged, not resolved here)
- The `w_vent` prior's SOURCE (an STC subduction transport with a citation) — flat until then.
- The constants batch rides in the same array (`sst_NH/SH` 17.18/15.35, `hs_frac` 0.126/0.130, biosphere-wide `ALPHA_PHOTO_EPS`):
  each is a separate commit with its own test, BEFORE the array's start file is cut.
- Whether `OCEAN_AREA_NH/SH` (provisional 1.55/2.06e14) should be sourced from a bathymetry — Nowicki's OCIM grid gives 1.463 /
  2.031e14 (wet cells), which is NOT a source, only a second reading.

## 6. Order and artefacts
1. Constants + prior reader + parameters + the field (R) → `test-option-e` P0a/P0e.  2. The loop (R) + guards + stability → P0b/c/f.
3. C++ twin + marshalling → P0d.  4. The unrefitted probe → `outputs/diagnostics/option_e_probe_20260914.{log,rds}`.
5. Table + migration + structure `hilda_e` + the logpost guard.  6. Full suite; CHANGELOG; handoff; memory.  7. The array (Torch;
"consider Torch first" — the verdict is Torch: 36 names × ≥ 30 starts is the laptop's day).

## 7. AMENDMENT made DURING the build, before any probe ran (stamped 2026-09-14 h)
- **`w_e` → `w_vent`, `gamma_e` → `gamma_vent`.** The prereg's names were PREFIXES of existing parameter names (`w_eq`,
  `gamma_eq`, `gamma_enso_*`), and R's `$` on a list PARTIAL-MATCHES when the exact name is absent: `is.null(p$w_e)` on a list
  without `w_e` returned `w_eq`'s value, so the "absent = 0 = OFF" contract silently read the CELL's transport as the loop's.
  Caught by the C++ marshalling (`Index out of bounds: w_e`) on the first parity run — the memory tree's encoder-trap family
  (`INDEX_conv`). Renamed rather than patched with `[[`: a name that cannot partial-match is the structural fix. Every
  occurrence of the two names above reads with the new ones.
- **The solved-field guard is INERTNESS, not an error.** §1 said `w_vent > 0` with `pump_field = "solved"` errors by name. Built
  as: under `"solved"` the loop is ABSENT and `w_vent` / `gamma_vent` are inert — the `w_eq`-under-`"hilda"` contract. Reason: the
  objective carries every table name under every structure (72 callers of `ccx_make_logpost()` run at the default `"solved"`), and
  a name that ERRORS at every draw breaks the fit instead of being unidentified by it. `pump_grad` is inert under `"martin"` the
  same way. The array pins the inert names (session 2); no logpost guard. Tested bit-exact: solved + `w_vent` 20 ≡ solved + 0.
