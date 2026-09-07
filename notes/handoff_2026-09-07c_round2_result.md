# Handoff — 2026-09-07c. ROUND 2 RESULT: the structure holds the Δ¹⁴C profile (first time after a refit) and breaks the DIC/δ¹³C gradients. The conduit's water has no biology.
# **⛔ NOTHING ADOPTED. Canonical `ent26`. Torch idle. Everything in git (`calibration/output/multistart_20260907b_hilda29/`).**
# **⇒ NEXT IS A DESIGN RULING: give the HS box a pump (or a preformed-DIC end-member), or stop here and record the structure as "ventilation yes, biology no".**

Read: CHANGELOG 2026-09-07c (the tables and the mechanism), the scored `prereg_2026-09-07b_...`, then
`handoff_2026-09-07b_...` (how it was launched) and `_2026-09-07_hilda_refit_result.md` (round 1).

## 1. THE RESULT
Winner −1508.24 from 28/46 starts: f 0.0086 (K_deep 101, near the floor), `hs_asx_frac` 0.507 (−1.5 sd
of 0.653), `h_ml` 37, `h_hs` 399, `kz` 11,706, `pump_grad` 524 (+3.2 prior-z). Profile −179/−190/−191:
z −1.32 / +1.40 / +0.42 ⇒ R1, R2, R6, R8 PASS. Rest −43 vs `ent26`: `ocean_grad_d13c` −27.6, ALK −7.1,
DIC −6.1, `d14c_NH` −4.1 ⇒ R3, R4, R5 FAIL; `h_ml` 37 ⇒ R7 FAIL.

## 2. THE MECHANISM (and the refuted hypothesis, on the record)
Gradients at the winner: DIC 118 (ent26 221), δ¹³C **+0.36** (ent26 −0.88, wrong sign), ALK 156 (95).
Hypothesis 1: `ccx_pump_export()` solves the export against diffusion only (true — `kz_int`, no q term),
so the export shrank with K_deep. **Refuted:** export is 56.7 GtC/yr at the winner vs 19.1 (`ent26`),
16.1 (09-06c arm) — it GREW 3× (K(top) 11,706 × pump_grad 524) and the gradient still halved. The
conduit (τ_q 538 into every layer) flushes the interior with HS water: air–sea-equilibrated, NO pump
(C9 deferred), low DIC, heavy δ¹³C. No export rebuilds a gradient against that. The h_ml 37 / 200 split
is the same lever (the two families differ by 4.7 on `ocean_grad_d13c`).

## 3. ⇒ THE RULING, then the tests
Options: (a) **an HS pump** — export from HS (the Southern-Ocean/N-Atlantic export that C9 deferred),
sized like the LS pump's, so HD carries remineralised DIC; (b) **a preformed-DIC/δ¹³C end-member for HS**
(HS DIC set by the observed high-latitude surface DIC, ~2150 vs ~1950 low-lat, rather than by air–sea
equilibrium alone); (c) stop: record HILDA's structure as ventilation-right / biology-wrong and return
to the column with #10. Cheap first test for (a)/(b): at the winner's vector, add an HS export equal to
the LS pump's per-area export and re-read the three gradient rows — a one-spinup probe.
⚠ Also owed regardless: the pump solve should include the conduit in its operator (a consistency fix,
not the cause); `ent26`'s 19 GtC/yr export vs ~10 observed is an unpriced pre-existing property.

## 4. STATE
Torch: nothing running. Objective #10 ON (β 4, level σ 10.26), table 29 parameters, `hs_asx_frac`
floor 0.02. Two mode-file tests fail on purpose (no 29-name canonical). `INDEX_ccx_ocean_struct` at
~17.3 KB — SPLIT next session (hard 18 KB).
