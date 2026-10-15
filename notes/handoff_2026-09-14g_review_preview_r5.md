# Handoff — 2026-09-14 (g). **The review of the three open calls and a 93-item triage of the model's non-physics; the recommendations FOLLOWED as far as they can be without rulings: R5 resolved by measurement (the excess slope; tr ≈ 0), the D+E preview run (the export field is ~45 % of the cell's B1; the kz coupling is the rest; the tropical band's +72 is insensitive to export), `ALPHA_PHOTO_EPS` registered, DESIGN §6's header rewritten as the live ledger, option E scoped with its rulings. Nothing adopted; `hilda30c` canonical; no array launched.**

> Self-contained. HEAD = the commit carrying this note. CHANGELOG 09-14 (f), (g). Memory: [[ccx_tr_box_built_probe]], [[ccx_review_20260914g_root_causes]]
> (both in `INDEX_ccx_ocean_circ`; `INDEX_ccx` live line updated; both sub-indexes ~15.3 / 15.7 KB, over the 14 KB soft target, under 18).
> Notes: `review_2026-09-14g_open_calls_and_nonphysics.md` (the review), `scoping_2026-09-14g_option_e_ventilation.md` (E's rulings),
> `prereg_2026-09-14f_tr_box_build.md` (§8–9 the build's amendments and reading). Previous: `handoff_2026-09-14f_tr_box_built_probed.md`.

## 1. What was done this session, in order
1. **The tr box built + probed** (09-14 f; the previous handoff): PT1 FAIL (+101.6, z +6.8); the 69× mechanism.
2. **The review** (`3441a76`): pros/cons of R5 / R6 / the design question; 93 flagged items → 5 root causes, 6 pedagogical liabilities,
   an accept-list, a dormant-list; the order of work (§B5).
3. **The preview** (`diag_tr_box_martin_preview.R`): B1 +133 → +98 → +74 on `hilda_eq` as the export goes 39 → 17 → 0.9 GtC/yr
   (+1.54 µatm per GtC/yr); `hilda_tr` + Martin-tail +67.5 (z +1.8); tr − global +68/+72/+75 at every export; ENSO slope 2.42× → 0.46×.
4. **R5 resolved** (`obs_tr_box.rds` gains `$sst_excess`; every prior element byte-identical; `obs_eq_cell.rds` untouched): the box's slope
   as the EXCESS over the hemispheric HadSST4 anomaly = tr +0.002/+0.015, cell +0.67/+0.83. `hilda_tr` reads both (0.006 / 0.739);
   `hilda_eq` keeps the absolute 0.97 so the first array reproduces. Probe re-run: B1 unchanged (+101.7); ENSO slope 2.57× (the
   double-counted term had hidden the loop's over-response as 1.53×). `test-tr-box.R` 241/241.
5. **`ALPHA_PHOTO_EPS` registered** in `R/constants.R` (value 18 unchanged; Lloyd & Farquhar 1994 Oecologia 99:201–215: C3 17.8, C4 3.6,
   total 14.8 at 25 % C4; Still 2003 / Suits 2005 15–18); PROVISIONAL deliberately (the C3-only value is in use; the biosphere-wide
   14.8–16.5 is a refit-batch revision — it re-scales the land's isotopic signature in every δ¹³C row). `aux$alpha_photo` reads it;
   the ledger roster updated (`test-constants` 324/324; parity 82/82).
6. **DESIGN §6's header rewritten** as the live ledger at `hilda30c` (5 / 7 / G / S / P7 PASS; V / H / GL / Q FAIL; ENSO ocean open; IRF a
   comparison; gates 4 / 8 / 10 named as retired with reasons; the `from90` / `ent26` / `hilda31` blocks marked provenance). ⚠ The 09-12
   assessment lists option J as "Marcus's text" — this is a ledger table restating measured numbers, offered as a draft to redraft.
   The dead bomb-window message no longer calls the shape provisional.
7. **Option E scoped** (`scoping_2026-09-14g_option_e_ventilation.md`): the four numbers that make kz, the 45 GtC/yr field and the T-DIC
   exposure one object; the mode-water loop; D as a prescribed export with an emergent gradient; rulings E1–E6; PE-1..PE-5 + N-E1.
8. **Withdrawn from the review**: "the app holds GMST flat past 2024" — `app/server.R:118-151` runs futures / stylized / pulse through
   `ccx_run_coupled()`; the flat hold is a warned placeholder for bare `ccx_build_forcing()` callers only.

## 2. What is owed to Marcus (nothing below happens without a ruling)
- **E1–E6** (the scoping note §3): the pump as prescribed export (recommended) vs solved field; the loop's layers (1–3 recommended); one
  limb with the ENSO modulation (recommended) or two; the export prior's source; E before T5 (recommended); what the refit may move.
- **The constants batch for the same refit**: `sst_NH/SH` 17.18/15.35 (sourced), `hs_frac` 0.126/0.130 (the product) for 0.16, the
  biosphere-wide `ALPHA_PHOTO_EPS`, and a source per remaining provisional constant (the ledger lists 15).
- **The σ-audit three** (unchanged since 09-10): `gcb_ocean_sink` uninflated while the land sink gets ×3.0; `excess_c14_ocean`'s target
  set (~130 log-units); `CCX_ICE_DISCREPANCY` off.
- **R6** only matters if a T1 array is wanted as a record (run at 1); the review says it is not worth launching.
- Whether the DESIGN §6 rewrite stands.

## 3. Non-obvious state
- `hilda_tr` and `hilda_eq` now differ in `sst_eq_enso` (0.739 vs 0.971) as well as `sst_eq` (26.33 vs 27.04) and `sst_NH/SH`; the
  "mask change alone" arm of the probe carries all three.
- `diag_tr_box_martin_preview.R` re-points `ccx_pump_shape()` through `lib_martin_shape.R` (session-local); every Martin arm is
  unrefitted (T-D0b: starved of return at this K(z)); B1 is read as a structural number there, the likelihood only as context.
- The full suite after (g)'s changes: `outputs/diagnostics/suite_20260914g.log` (see §4).
- Standing reds: the GATE Q pair (`test-alpha-as`) and `test-seas-lag-split:205`.

## 4. The full suite (`outputs/diagnostics/suite_20260914g.log`)
**3204 pass / 2 fail / 1 error / 2 skip** — exactly the standing pair (GATE Q, `test-alpha-as`) and the 08-30 arm error
(`test-seas-lag-split:205`). Everything else green, including the constants ledger with `ALPHA_PHOTO_EPS` on it.
