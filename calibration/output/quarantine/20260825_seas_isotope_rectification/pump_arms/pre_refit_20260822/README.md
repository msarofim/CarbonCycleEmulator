# Pre-refit snapshot — 2026-08-22

`mode_fit_pumpN.rds` as it stood immediately before the 2026-08-22 refit onto the
post-`d6adb58` objective (ice term scoring `co2_SH`).

This is the **repaired** file: its `streams` were recomputed by
`calibration/repair_arm_streams.R` after the `luc_scale`-squared bug, and it carries
`streams_as_fitted` and `streams_provenance`. Its `par_mode` / `logpost` / `hessian`
are the 2026-08-21 fit, on the **pre-`d6adb58`** objective.

Kept because it is the vector `app/global.R` shipped from 2026-08-21 (`8b94ba4`) to
this refit, and every DESIGN sec.6 gate status measured on 2026-08-22b — gate 12's
11.74 / 23.97 / 39.36, gate 4's 0.435 and sd 0.019, gate 5's 892.3 ‰ peak, gate 7's
land +2.04σ — was measured at it. Reproducing those numbers requires this file.

The pre-*repair* copies are separately in
`calibration/output/quarantine/20260822_luc_scale_squared_streams/`.
