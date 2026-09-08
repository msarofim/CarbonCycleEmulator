# PRE-REGISTRATION — the HS pump probe (2026-09-07d). Written BEFORE the mechanism was run; binding.

**Ruling (Marcus, 2026-09-07d):** "Scope the HS pump and move forward with it if it looks like a plausible fix."
Context: `notes/options_2026-09-07d_hs_biology.md` §1–2; the end-member probe ([[ccx_hs_endmember_probe]]) showed
the HS box's DIC is right (2169 = observed SH surface 2163) and the deep under it lacks +116–185 µmol/kg and
−0.87 ‰ of remineralised carbon.

## The mechanism (built 2026-09-07d, both cores)
`pump_hs_rel` = HS per-area export ÷ the LS pump's per-area NET export (Σ over layers of the solved divergence
field, org + carb, over `a_ls`). Export from HS is remineralised in HD (one box), two limbs at the LS pump's
`pump_carb_frac` and `PUMP_EPS13_ORG` / `PUMP_EPS13_CARB` fractionation, ¹⁴C unfractionated, DIC-limited scaling
under `pump_mode = "D"` against HS's preindustrial carbon. **0 = OFF, bit-exact** (`aux$pump_hs` NULL, nothing
emitted; guarded by `tests/testthat/test-pump-hs.R`). Pays choice C9 of `prereg_2026-09-05_hilda_boxes.md`.

## The probe (`calibration/diag_hs_pump_probe.R`)
At the round-2 winner's vector (id 44, `multistart_20260907b_hilda29`), `pump_hs_rel` ∈ {0, 0.5, 1, 2}, nothing
refitted: the box table at 2008 (the end-member probe's convention), the three gradient rows, the Δ¹⁴C profile
rows, the sink and bomb streams, the total likelihood under objective #10. Pre-check from first principles:
at rel 1 the HS export is 3.64 GtC/yr ⇒ HD enrichment ≈ E/(u_hs·a_hs·ρ) = **+135 µmol/kg**, δ¹³C ≈ ε_org·ΔDIC/DIC
≈ **−1 ‰** (options note §1).

## Predictions at `pump_hs_rel` = 1 (the run is judged on these)
| | prediction | falsified if |
|---|---|---|
| P1 | hemisphere-mean HD − HS DIC in **[+70, +185]** µmol/kg (the observed deep − high-lat-surface range) | outside |
| P2 | bottom − HS δ¹³C **≤ −0.5 ‰** (was 0.00; observed −0.87) | > −0.5 |
| P3 | `ocean_grad_d13c` improves by **≥ 20** log-units vs rel 0 (its loss vs ent26 is −27.6) | < 20 |
| P4 | `ocean_grad_dic` improves by **≥ 2** (bottom − ML grows toward 233) | < 2 or worse |
| P5 | the three Δ¹⁴C profile rows stay inside **2σ** (¹⁴C rides unfractionated; no first-order effect) | any \|z\| > 2 |
| P6 | HS δ¹³C falls by **≥ 0.2 ‰** toward the observed +1.31 (HD's light carbon sets HS at 15 %/pass equilibration) | < 0.2 |
| P7 | sink and both bomb streams within **2** log-units of rel 0 (mode N: the pump does not touch uptake) | worse by > 2 |

**Plausible fix = P1, P2, P3 and P5 pass at rel 1 (or at some rel in the scan with P1 still inside).** Then:
register `pump_hs_rel` as the 30th fitted parameter (or declare it), add the HS-surface rows, pre-register and
launch round 3 under the CORRECTED gradient rows. If P3 fails with P1 passing, the δ¹³C row is not the deep−HS
contrast and the diagnosis is wrong — stop and re-read the row.

## AMENDMENT 2026-09-07d (after the first run, before the second) — the judged point FAILED ON SIZE
First run, sizing "relative to the LS field": `rel` 1 = **14.0 GtC/yr** from HS (the winner's LS net export is
73.6 GtC/yr, ~4× the real ocean), HD − HS **+443** ⇒ P1 FAIL; P2 PASS (−2.50); P3 +19.05 (FAIL by 1); P4 −33
(FAIL); P5 level z −2.84 (FAIL); P6, P7 FAIL. At `rel` 0.5 (7.0 GtC/yr): HD − HS +233, δ¹³C row **+26.7**, total
**+2.1** — the mechanism works and was over-sized. Log kept: `outputs/diagnostics/diag_hs_pump_probe_20260907_run1_rel.log`.
**Change made:** the parameter is now ABSOLUTE, `pump_hs_gcm2` (gC m⁻² yr⁻¹), comparable to the export
literature and independent of the fitted LS field. **Judged point for the second run** (the prereg's stated
alternative): the scan value {15, 30, 45, 60, 90, 120} whose HD − HS lands nearest the CENTRE of P1's window —
chosen by P1's own statistic so P2–P7 stay out-of-sample. Predictions P2–P7 unchanged.
