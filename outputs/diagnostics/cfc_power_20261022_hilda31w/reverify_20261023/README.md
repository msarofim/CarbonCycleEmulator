# Re-verification of the CFC-11 power driver after its overlay conversion (2026-10-23)

`test-overlay-idiom-lint.R` flagged `calibration/diag_cfc_power_20261022.R:95`, a bare `intersect()` loop that copied the
fitted values onto the base. Marcus ruled "Convert, re-verify (Recommended)". The line became
`p <- ccx_overlay_par(bp0, pv)` (`conversion.diff`), and the driver was rerun at `facf8851` plus that diff.

Result: every result field of `cfc_power_hilda31w.rds` (`gates`, `surface`, `base`, `inv0`, `readouts0`, `t_box`,
`k_check`, `G`, `sd_pred`, `s_obs`, `cov_update`, `ceiling`, `perfect_all`) is `identical()` to the 10-22 (j) record in the
parent directory; only `provenance$commit` and `provenance$run` differ. The log matches line for line after its header.

The parent directory's files are the original record (`ac4129f5`) and are unchanged. This directory holds the rerun.
