# Quarantine 2026-10-02: the six mode files BEFORE the objective-#15 restamp

**What these are.** Byte-identical copies (`cmp`-checked) of `mode_fit_pumpN.rds`, taken at commit `f6049e2`
(objective #14 streams and logposts) before `calibration/restamp_mode_objective.R` re-recorded them under
objective #15:

| copy here | the live file it was taken from |
|---|---|
| `refit_20261001_hilda33d_obj14_hilda_csl3v0kaidgb/` | `hilda33d`, the canonical |
| `refit_20260920_hilda29l_obj13_hilda_csl3/` | `hilda29l` (v1.0) |
| `refit_20260922_hilda32f_obj13_hilda_csl3_free_parent/` | `hilda32f` |
| `refit_20260912_hilda31_seasml1_round7/` | `hilda31s2` |
| `refit_20260919_hilda31pe_obj13_hilda_c_seasml0/` | `hilda31pe` |
| `refit_20260908_hilda31_ratification/` | the retired `hilda31` in `../20260910_periodic_spinup_adopted/refit_20260908_hilda31/`, which `test-enso-demean`'s ratification pin cross-checks (`CCX_MODE_HILDA31_QUARANTINED`) |

**Why.** Objective #15 (Marcus 2026-10-02, D1: *"Every version, as objective #15"*; CHANGELOG 10-02 bb/cc) =
objective #14 plus three changes, each ruled:
1. **W3:** the ice-core CO₂ row scores only samples before 1958 (`LIK_ICE_CO2_END`; *"Cut to pre-1958"*).
2. **W2:** the Law Dome ice-core δ¹³C row `d13c_icecore` (`LIK_USE_ICE_D13C`). D4 rulings: σ = √(err² + 0.05²) ‰,
   samples before 1977, every in-run sample from 1750.
3. **W5:** the `k_w` and `tau_ex` priors, cited and moved: lognormal(1500, 0.4) → (1446 m/yr, 0.2), and
   (1.3, 0.25) → (0.8 yr, 0.26) on the hemispheric-mass basis (`R/constants.R`).

**The priced moves** (`calibration/diag_obj15_price.R` @`f6049e2` → `outputs/diagnostics/obj15_price_20261002.log`).
At every file, the switches-off harness reproduced the stored #14 streams `identical()`, only `co2_icecore`
and the new row moved, and logpost(#15) − stored = likelihood move + prior move.

| file | likelihood move | prior move |
|---|---|---|
| hilda33d | +198.7576 | +0.8327 |
| hilda29l | +191.9017 | +1.0548 |
| hilda32f | +193.4598 | +1.0170 |
| hilda31s2 | +212.2072 | +1.2673 |
| hilda31pe | +193.0867 | +1.0331 |
| hilda31 (ratification) | +213.1080 | +1.3208 |

The restamp log is `outputs/diagnostics/restamp_obj15_20261002.log`.

**The canonical post-restamp path** of every file is unchanged: the same `calibration/output/<dir>/mode_fit_pumpN.rds`.
The restamped files also keep the #14 streams and logpost inside `objective_history`.

**To reproduce an objective-#14 number:**
- set `LIK_USE_ICE_D13C <- FALSE` and `LIK_ICE_CO2_END <- Inf` (`R/likelihood.R`);
- put the #14 priors back on `k_w` / `tau_ex` (`R/calibrate.R` before `0ae4d99`);
- or read these copies' `streams` / `logpost`.
