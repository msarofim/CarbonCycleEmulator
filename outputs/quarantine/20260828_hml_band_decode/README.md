# QUARANTINE 2026-08-28 — `h_ml` decoded under the wrong band

## 1. The bug

`h_ml` is logit-transformed onto `[lo, hi]`, and the pump refits **override that band in
process** (`run_modefind_pump_arms.R`, `recompute_hessian.R:112-113`) because the band is a
property of the REFIT, not of the model. `ccx_unc_to_par()` is a pure function of the
**SHIPPED** table and cannot know. So at the canonical mode `from90`:

    ccx_unc_to_par(md$u_mode)$h_ml   85.7292 m    <- what these outputs were produced with
    md$par_mode[["h_ml"]]            96.4737 m    <- what the refit actually found

**An 11.14 % shallower mixed layer, and `h_ml` is the ONLY one of the 21 parameters affected.**
Fixed 2026-08-28 by `ccx_adopt_mode_band()` / `ccx_mode_params()` in `R/paths.R`, with
`ccx_check_mode_decode()` as a hard gate and `tests/testthat/test-mode-decode.R` pinning it.
Diagnosis: `calibration/diag_hml_mode_decode.R`. **No objective changed and no refit is owed** —
the calibration was always fine; what was wrong is what the DIAGNOSTICS fed the model afterwards.

⚠ The defect was **already documented, in one file only** — `diag_landed_gap_streams.R:36-37`
("`u_mode` DOES NOT DECODE under the default [30, 200] band … `par_mode` is the authority") —
and never propagated to the other drivers or to memory. A trap documented once is not thereby
fixed everywhere.

## 2. What is in here

Produced by drivers that used the `pv <- ccx_unc_to_par(md$u_mode)` idiom, i.e. every one of
these ran the model with `h_ml = 85.73 m` while naming the mode whose `h_ml` is 96.47 m:

| file | arc |
|---|---|
| `so_entrainment_refit.rds` | 27g, the entrainment channel as counterweight |
| `seas_npp_sh_power.rds` | 27i, the `seas_npp_amp_SH` power check |
| `joint_land_ocean_refit.rds` | 27j, the 2×2 with INTERACTION +64.99 |
| `seas_T_amp_sh_power.rds` | 27n, the SH cancellation arm |
| `seas_slice_q10_pin.rds` | 27p, the q10-pin slice repair |
| `admissible_2x2_land_ocean.rds` | 27q, the 2×2 with the admissible lever |
| `design_gates_unscored.rds` | 2026-08-28, gates 6/8/10/11 |
| `tau_ex_*.rds` | 27h, the `tau_ex` power checks |
| `hml_edge_probe.rds` | 2026-08-28 scratch probe, made **at the wrong depth** |

## 3. What survives and what does not

- **MATCHED CONTRASTS SURVIVE.** Every arm within a driver shared the same wrong `h_ml`, so
  differences, interactions and per-arm orderings are unaffected in kind.
- **ABSOLUTE VALUES DO NOT** — SPO decomposition amplitudes, phases, ×obs ratios, stream totals.
- ⚠ **NOR DO CROSS-SESSION "REPRODUCES THE EARLIER CONTROL" CHECKS.** 27q's P0 reproduced all four
  of 27j's control values to three decimals; they agreed because all three sessions shared the
  defect, not because the values were right. A reproducibility check is only as good as the
  assumption that the runs differ.
- `design_gates_unscored.rds` is the mildest case: its `defaults` vector is unaffected (no mode
  decode) and its **observed** targets are untouched, so gate 6's target correction stands
  independently.

## 4. Canonical replacements

Re-run the same drivers, now band-corrected, to the same paths in
`outputs/diagnostics/`. Nothing else changed in any of them.
