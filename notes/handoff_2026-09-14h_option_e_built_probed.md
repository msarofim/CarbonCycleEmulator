# Handoff — 2026-09-14 (h). **Rulings E1–E6 taken (the recommendations; E4 = Nowicki WITH bounds, COMPUTED from its data release), option D + E BUILT on both cores behind a `pump_field` axis (`test-option-e.R` 60/60; every registered mode bit-exact), and PROBED UNREFITTED: D alone starves and E is invisible at the old kz — as preregistered, the array is the test. Nothing adopted; `hilda30c` canonical; no array launched.**

> Self-contained. HEAD = the commit carrying this note. CHANGELOG 09-14 (h). Memory: [[ccx_option_e_built_probe]] (in
> `INDEX_ccx_ocean_circ`, now 16.6 KB — over the 14 KB soft target, a SPLIT is due: the ENSO-response lines vs the pump /
> ventilation arc); `INDEX_ccx` live line updated (15.7 KB); the prefix rule in `INDEX_conv`. Notes:
> `prereg_2026-09-14h_option_e_ventilation.md` (§0 rulings, §7 amendments), `scoping_2026-09-14g_option_e_ventilation.md`.
> Previous: `handoff_2026-09-14g_review_preview_r5.md`.

## 1. What was done, in order
1. **E4 resolved by measurement** (`4c7be1c`). The paper text is behind Wiley's bot-check (not bypassed); the abstract gives only
   the ensemble mean. Its figshare release (`nowicki2022_bcp`, 215 MB, md5 verified; `.gitignore`d, manifest row tracked) carries
   per-cell mean + p25/p75 of the 124-member ensemble. `data-raw/build_pump_export_prior.R` → `data/obs_pump_export_prior.rds`:
   global 10.25 [9.09, 11.27] (abstract 10.2 ✓, pathway shares ✓ — both `stop()`-checked before saving); **LS 9.08 [8.12, 9.92]**;
   prior lognormal median 9.08, log-sd 0.148. ⚠ The bracket is a sum of PER-CELL percentiles (an OUTER bound of the total's IQR)
   and ensemble-internal — stated in the product's `bounds_note`. ⚠ `mask` 1 = WET (the file's attribute says the reverse).
2. **Prereg written**, rulings stamped (§0). Correction to the scoping: `pump_field` is a NEW switch; `pump_mode` is the N/D law.
3. **Built** (`714e6a2`): `MARTIN_B` (cited); the prescribed field in `ccx_pump_export()` (seafloor remainder in the bottom layer,
   sum(S) = E exactly, `pump_grad` inert); the loop in `ccx_deriv()` + the C++ twin + marshaling; guards; `ccx_e_loop_eigbound()`;
   the `pump_field` axis on `ccx_apply_structure()` / `ccx_mode_base()` / `ccx_mode_pump_field()` (env `CCX_MS_PUMP_FIELD`);
   table 33 → 36 (`pump_export`, `w_vent`, `gamma_vent`), migration 0 = OFF, `CCX_PARAM_ABSENT_OK` + three; four count
   assertions updated. Two amendments (prereg §7): the RENAME (`w_e` partial-matched `w_eq` — caught by the C++ index), and the
   loop INERT under "solved" (not an error; 72 objective callers).
4. **N-E1 measured** (in the test, reported): the Martin field matches the canonical's PI bottom−ML gradient at 6.29 GtC/yr with the
   shape moved below 900 m.
5. **The probe** (`calibration/diag_option_e_probe.R` → `outputs/diagnostics/option_e_probe_20260914.{log,rds}`): see §3.
6. Suite: `outputs/diagnostics/suite_20260914h.log` (§4).

## 2. Owed to Marcus / next session (session 2 of the build)
- **The `w_vent` prior's SOURCE** — an STC subduction transport with a citation; flat [0, 60] until then (the prereg says the data
  rows set it). My recollection is Schott, McCreary & Johnson 2004 for the Pacific STCs — RECOLLECTED, unsourced; look it up.
- **The constants batch BEFORE the start file**, each its own commit + test: `sst_NH/SH` 17.18/15.35 (sourced), `hs_frac`
  0.126/0.130 for 0.16, biosphere-wide `ALPHA_PHOTO_EPS`, a source per remaining provisional constant (15). Nowicki's OCIM grid reads
  `OCEAN_AREA_NH/SH` as 1.463/2.031e14 vs the provisional 1.55/2.06 — a second reading, NOT a source.
- **The array** (Torch — say the verdict aloud: 36 names × ≥ 30 starts is the laptop's day): `run_dispersed_multistart.R` must
  RECORD `pump_field` in every start file (mirror `seas_ml`), `make_port_targets.R` under `CCX_MS_PUMP_FIELD=martin`, pins
  `CCX_MS_PIN=pump_grad=314.1031,gamma_enso_ocn_NH=0,gamma_enso_ocn_SH=0,ent_seas_amp_SH=0`, structure `hilda` + `seas_ml` 1.
  `promote_multistart_mode.R` must carry `pump_field` into the mode file. Then PE-1..PE-4 at the mode; then the cell re-read (E5).
- **The σ-audit three** and **whether DESIGN §6 stands** — unchanged from (g).
- `INDEX_ccx_ocean_circ` split (16.6 KB).

## 3. The probe's reading (unrefitted; the canonical vector; martin 9.08; `gamma_enso_ocn_*` pinned 0 in every martin arm)
| arm | PI oc2−ML | oc6−ML | bot−ML | Δ lik | ENSO/obs | r |
|---|---|---|---|---|---|---|
| solved (the canonical) | +5 | +181 | +254 | 0 | +0.58× | +0.254 |
| solved, option A off | +5 | +181 | +254 | −5.8 | −1.47× | −0.527 |
| martin w0 | −67 | +72 | +298 | −894.8 | −1.47× | −0.527 |
| martin w40 γ0.5 | −68 | +70 | +297 | −896.9 | −1.02× | −0.393 |
- **D alone starves**: at 9 GtC/yr and kz 10,964 the mixed layer keeps the carbon the 45-GtC/yr field used to export; the
  thermocline INVERTS and the tail piles the gradient below 900 m (K 129). −274 to −282 of the loss is on the CO₂ rows.
- **E is invisible at the old kz**: 40 Sv replaces layers 1–3 at 0.065 /yr against diffusion's 3 /yr (50×) — < 5 log-units.
  **PE-1 (kz falls > 2.7×) is the array's question; nothing here answers it.** Bomb rows −4.4 → −2.3 at 40 Sv (the loop does carry ¹⁴C).
- **PE-5 first half CONFIRMED** (r −0.527 solubility-only); γ 0.5 moves the slope the right way (−1.47 → −1.02× at 40 Sv), no flip
  unrefitted — the return water is not DIC-richer than the ML at this gradient.
- ⭐ **Option A does ALL the canonical's ENSO-ocean work**: `gamma_enso_ocn_NH` 0.34 off costs 5.8 log-units and flips +0.58× → −1.47×.

## 4. The full suite (`outputs/diagnostics/suite_20260914h.log`)
**3311 pass / 4 fail / 2 skip** at the build commit, then ONE more 33-count assertion found and updated
(`test-ent-seas-fitted.R:20`, 66/66 on re-run) ⇒ effectively **3312 / 3 / 2 = exactly the standing pair (GATE Q,
`test-alpha-as`) + the 08-30 arm error (`test-seas-lag-split:205`)**. Everything else green, `test-option-e.R` 60/60 included.

## 5. Non-obvious state
- `data-raw/downloads/biopump_model_output.nc` is local only (ignored); re-fetch with `Rscript data-raw/download_nowicki_bcp.R`.
- `lib_martin_shape.R` now reads `MARTIN_B` from the ledger (value unchanged); every T-D0 arm reproduces.
- `ccx_mode_pump_field(md)` reads an absent field as "solved" — every registered file. The array driver does NOT yet record it.
- Standing reds: the GATE Q pair (`test-alpha-as`) and `test-seas-lag-split:205`.
