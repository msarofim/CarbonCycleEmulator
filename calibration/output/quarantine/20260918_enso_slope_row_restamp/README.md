# Quarantine 2026-09-18 (e): the three registered mode files BEFORE the objective-#13 restamp

Copies of `mode_fit_pumpN.rds` for `hilda30h` (refit_20260917_hilda30h_obj12_hilda_c), `hilda31s2`
(refit_20260912_hilda31_seasml1_round7) and `hilda31p` (refit_20260910_hilda31_periodic) as they stood at
commit `bfea030` (objective #12 streams), before `calibration/restamp_mode_objective.R` re-recorded their
`streams` / `logpost` under objective #13 -- the GCB ENSO ocean-slope row `gcb_ocean_enso_slope`
(`LIK_USE_GCB_ENSO_SLOPE`, R/likelihood.R; Marcus 2026-09-18: "if the GCB regression slope is an important
observational constraint, add it to the objective"). Measured likelihood moves
(outputs/diagnostics/enso_slope_row_price_20260918.log): hilda30h -1.9466 (model slope +0.040 vs GCB's
+0.1153 +/- 0.0246, z -3.08), hilda31s2 +0.7692, hilda31p +0.3912. The restamped files carry the history inside
`objective_history`. Canonical post-restamp path: the same `calibration/output/<dir>/mode_fit_pumpN.rds`.
To reproduce a #12 number: set `LIK_USE_GCB_ENSO_SLOPE <- FALSE` (or read these copies' streams).
- Also the ratification pin's quarantined `hilda31` (quarantine/20260910_periodic_spinup_adopted/refit_20260908_hilda31): +0.3630 (its pre-#13 copy in refit_20260908_hilda31_prerestamp/).
