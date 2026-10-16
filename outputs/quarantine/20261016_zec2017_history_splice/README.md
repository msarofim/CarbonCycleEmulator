# Quarantined 2026-10-16: stop-vs-pulse run with a 2017 stop, history splice overwrote the arms

**Files:** `ccx_hilda31w_zec2017_vs_pulse100_h100.{csv,log}`, from `calibration/diag_zec_vs_pulse.R` with
`CCX_ZP_ZERO_YEAR=2017` at `bfc7ccc9` plus an uncommitted edit (the env override).

**Bug:** the driver built each arm's emissions table, then passed it to `app_run_coupled()`, which replaces every
year up to `APP_SPLICE_YEAR` (2024) with the observed GCB record (`app_splice_history()`). For a stop year after
2024 (the shipped 2030 run) that changes nothing. For 2017 it overwrote the zeroing for 2017-2024 and the 2017
pulse. The gates passed because G4 checked the tables before the splice and G3 compared the arms only before 2017.

**Symptoms:** pulse remaining 0.0 % in every scenario (the pulse was erased); excess remaining 75-77 % at +100 yr,
inflated because the "zero" arm kept emitting to 2024 while the excess was measured at 2017.

**Replacement:** the fixed driver applies the zeroing and the pulse after the splice and runs without re-splicing.
Its output is `outputs/diagnostics/zec_vs_pulse_20261016/ccx_hilda31w_zec2017_vs_pulse100_h100.{csv,log}`
(CHANGELOG 2026-10-16 k).
