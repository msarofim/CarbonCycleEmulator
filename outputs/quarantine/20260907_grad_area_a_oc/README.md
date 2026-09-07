# Quarantine 2026-09-07 — `grad_area_a_oc`: the ocean gradient rows divided by the wrong area

**Bug.** `ccx_model_ocean_gradient()`, `ccx_model_ocean_alk_gradient()` / `ccx_steady_profile_from_source()`
(R/likelihood.R) and `dg_gateG()` (calibration/lib_design_gates.R) converted box carbon (GtC) to
concentration (µmol/kg) over the HEMISPHERE area `a_oc`. Since the HILDA boxes (2026-09-05) the mixed
layer and interior boxes span `a_ls = a_oc·(1 − hs_frac)` (R/model.R `ml_mass_kg`, the pump's kappa,
the conduit). At `hs_frac` 0.16 every HILDA-arm `ocean_grad_dic` and `ocean_grad_alk` value was read
**16 % low**; `ocean_grad_d13c` (a ratio) and every `hs_frac = 0` arm (ent26) were exact — which is why
nothing failed. Fixed 2026-09-07d by `ccx_column_area()`; mutation-tested in
`tests/testthat/test-ocean-grad-area.R` (3/3 fail with the helper reverted to `a_oc`).

**Files here (pre-fix, produced 2026-09-07 18:39):**
- `diag_hilda29_predictions_20260907.log`, `hilda29_predictions_20260907.rds` — round-2 scoring of Torch
  job 17110417 under the deflated rows.

**Canonical replacements (regenerated 2026-09-07d with the fix, same names):**
`outputs/diagnostics/diag_hilda29_predictions_20260907.log`, `outputs/diagnostics/hilda29_predictions_20260907.rds`.

**Size of the impact at the round-2 winner (id 44), vs `ent26` under objective #10:**

| stream | pre-fix | post-fix |
|---|---|---|
| `ocean_grad_dic` | −6.05 | **−3.96** |
| `ocean_grad_alk` | −7.06 | **−13.80** (the true ALK gradient is 1/0.84 LARGER, so further from +78.6) |
| `ocean_grad_d13c` | −27.56 | −27.56 (ratio, unaffected) |
| rest-of-likelihood (`d_rest`) | −43.1 | **−47.8** |
| R1–R8 verdicts | R1,R2,R6,R8 PASS; R3,R4,R5,R7 FAIL | unchanged |

**Not quarantined, but affected:** the round-1 scoring (`multistart_20260907_hilda28`, CHANGELOG
2026-09-07) and every 09-05/09-06 conduit arm's `ocean_grad_dic`/`_alk` read; the FIT of rounds 1 and 2
was optimised against the deflated rows (the optimiser saw a 16 % smaller DIC gradient and pushed
`pump_grad` to +3.2 prior-z). The start files in `calibration/output/multistart_20260907b_hilda29/`
are kept in place — they are the record of what the objective-with-bug found — and are superseded
only by a refit under the corrected rows.
