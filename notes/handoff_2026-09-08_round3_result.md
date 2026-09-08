# Handoff — 2026-09-08. ROUND 3 RESULT: the HS pump supplies the deep biology (δ¹³C row −27.6 → −7.0, ALK −13.8 → −0.1, LS export 73.6 → 29.9, rest −47.8 → −9.0, profile inside 1σ) at the price of a cold-box export 4× the float prior and a cold surface δ¹³C at z +3.8. 6 of 11 predictions pass. The lever is the declared `u_hs` = 38 m/yr = a 70 Sv flush.
# **⛔ NOTHING ADOPTED. Canonical `ent26`. Torch idle. ⇒ NEXT IS A RULING: free or observation-pin `u_hs`; then the HS air–sea fractionation if the surface stays heavy; `h_ml` 40 m is separately open.**

Read: CHANGELOG 2026-09-08 (the table), the scored `prereg_2026-09-07f_hs_pump_round3.md`, then `handoff_2026-09-07f_round3_launched.md`.

## 1. Result (job 17150003, 46/46, `diag_hilda30_predictions.R`)
Winner −1481.27 from 24 starts: `pump_hs_gcm2` 137.5 (7.94 GtC/yr, +3.0σ of the lognormal prior), f 0.0247, `hs_asx_frac`
0.818, `h_ml` 39.8, `h_hs` 400, `kz` 9047, `pump_grad` 276 (+0.68), LS export 29.9 GtC/yr. Profile z −0.50/+1.05/+0.68.
vs `ent26` on common rows: +225.0 = profile +234.0, rest −9.0 (δ¹³C −7.0, DIC −3.2, ALK −0.1, `d14c_NH` −1.6). HS surface
DIC 2149 (z −0.6), δ¹³C +2.46 (z +3.8). R1/R3/R6/R7/R9 FAIL; R2/R4/R5/R8/R10/R11 PASS. Every basin puts the export at 136–142.

## 2. The mechanism of the price
The export that holds the observed deep-minus-surface enrichment scales with the HD flush: `u_hs` 38 m/yr × a_hs 5.78e13 m²
= 2.19e15 m³/yr = **70 Sv** (both hemispheres) — HILDA's declared value, never fitted or observation-pinned here. Twice
the export means twice the stripping of the cold surface's light carbon, so the surface δ¹³C defect (already +0.6 at
round 2) grew with the fix. Objective #11's rows are weak by construction (σ_eff from the bottle spread) and recorded it
rather than arbitrating it — as the prereg said they would.

## 3. State / open
Torch idle. 30 parameters in the table; mode-file tests fail on purpose (no 30-name canonical). Suite: same 9 pre-existing
failures. Memory: `INDEX_diag` split 09-08 (→ `INDEX_diag_design`); `INDEX_ccx_ocean_struct` 15.8 KB (soft 14, hard 18);
root 13.9 KB (soft 12). Owed: the pump/ALK operator consistency (conduit + HS limb); HS alkalinity (C8); a sourced
overturning number before `u_hs` gets a prior.
