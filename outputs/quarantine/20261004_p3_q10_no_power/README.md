# QUARANTINE 2026-10-04 — the P3 preview: no POWER on `q10`

## 1. The defect (a design defect, not a code bug)
`calibration/diag_p3_netclimate_preview.R` @`c6e3873` (Marcus 10-04: "Preview P3 with q10 freed") re-optimises the
8-name land block plus `q10`, every other name held.
- That block frees `q10` to only **0.15 of its marginal sd** (hilda34g's stored covariance; `npp_tsens`: 0.93).
- `q10`'s partners sit outside it: `seas_lag_p_NH` r +0.80, `npp_frac_NH` +0.68, `seas_T_amp_SH` −0.59, `tau_ex` +0.47.
- The seasonal respiration is q10^(A_T sin/10), so the seasonal rows fix A_T · ln(q10). With `seas_T_amp` held,
  `q10` cannot move.
- **So the "q10 freed" cell R1 is a no-power null** (`q10` 1.0603 → 1.0604).
- **And the held-`q10` cells Q1.25 / Q1.4 price the SEASONAL RIDGE, not the GCB row.** A probe at `q10` 1.25 cost
  −1708 on the #15 likelihood with `seas_T_amp` held and −22.5 with it rescaled along the ridge: 98.7 % ridge.
  Neither cell converged (−1557 / −4589); the land block thrashed (net climate effect +0.51 / +0.94).
- Found 10-04 (k), while the run was in flight ⇒ memory `block_power_is_per_name`.

## 2. The files
- `obj16_p3_preview_20261004.log`: the run's log (14:50 → 17:42, 4 workers, `nice 19`, from a frozen copy of the
  committed driver, md5-identical).
- `obj16_p3_preview_20261004.rds`: the read table, the identity cell, the cells and their provenance.
- `obj16_p3_preview_20261004_cells.rds`: the cells' checkpoint.

## 3. What IS still usable, and the canonical replacement
- **R1 and RH** (the row from the mode; `q10` free-but-powerless and held) are valid as "P3 with `q10` effectively
  held". Both converged:
  - `npp_tsens` 0.00885 → 0.00667;
  - net climate effect +0.118 → +0.078 GtC/yr;
  - SSP5-8.5 2300 1448.6 → 1451.8 ppm.
- They CROSS-CHECK the powered repair with a real optimiser: the Newton step gives 0.00663 and +0.078.
- **The canonical P3 result is `outputs/diagnostics/p3_powered_step_20261004.{log,rds}`**
  (`calibration/diag_p3_powered_step.R` @`b44e20b`; CHANGELOG 10-04 k). With power 0.87–1.00, `q10` moves < 0.04 sd,
  and P3 ≈ P0.
- ⛔ **Do NOT quote Q1.25 / Q1.4 as "the price of matching GCB through `q10`".** That price, measured along the
  ridge, is tens of log-units, not thousands. The structural reason `q10` cannot match GCB is the 2-yr soil pool
  (CHANGELOG 10-04 k).
