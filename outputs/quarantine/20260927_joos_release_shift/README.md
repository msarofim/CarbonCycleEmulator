# Quarantine 2026-09-27 (d): the PD100 pulse was read five years late

## The bug
`ccx_irf()` (`R/joos_irf.R`) adds the pulse at the **first row** of its forcing, which on
the PD100 protocol is `JOOS_REF_YEAR` = 2010. Eleven call sites then ran
`o$t <- o$t - (JOOS_PULSE_YR - JOOS_REF_YEAR)` and kept `t >= 0`, believing they were moving
the clock to a 2015 release. They were not: they **discarded the first five years after
release**. Every "IRF@h" was IRF@(h+5), and every integrated IRF ran from 5 to TH+5.

Proof: the raw run's first-row IRF is 0.9995, the whole pulse, so the release was at 2010.

Fixed by `ccx_irf_pd()`, which holds the background to 2015 and then releases, plus
`joos_release_check()` (first-row IRF must be within 0.02 of 1). Mutation-tested in
`tests/testthat/test-pulse.R`.

## Size, at hilda29l
| | pre-fix | post-fix | Joos 5–95 % |
|---|---|---|---|
| TH20 | 11.41 | 13.04 | 12.2–16.3 |
| TH50 | 23.51 | 25.80 | 24.0–36.6 |
| TH100 | 39.15 | 41.80 | 39.5–65.2 |
| IRF@100 | 0.284 | 0.289 | 0.409 (T5) |

The integrated IRF moves 1.6–2.7 yr. The point IRF at ≥ 50 yr barely moves, and that gap is
real. See `outputs/diagnostics/pulse_land_attribution_20260927d.log` (moved 2026-10-12 to
`outputs/quarantine/20261012_joos_pm_label/`: its Joos ± are labelled "±1 sd" and are ±2 s.d.; numbers unchanged).

## Files here
- `joos_irf_from90.log`, `joos_irf_refit0830.log` — `diag_joos_irf.R` for superseded arms, pre-fix.

## Canonical replacement
`outputs/diagnostics/joos_irf_canonical_20260927d.log` (`Rscript calibration/diag_joos_irf.R canonical`).

## Affected IN PART, left in place deliberately
These outputs carry a gate-12 IRF column computed with the shift; **all their other columns are
unaffected**. They are mostly records of superseded arms, and moving them would break the memory
and handoff paths that cite them for those other columns. Do not quote their IRF / TH numbers.
- `outputs/diagnostics/whole_model_scorecard_*.{log,rds}` (irf20 / irf100 / irf300)
- `outputs/diagnostics/price_the_gates.{log,rds}`, `price_the_land_axis_on_support.rds`,
  `kz_bracket_on_the_sourced_target.rds`, `rep_dc_product_ladder_20260923/`
- the outputs of `diag_joos_beta_scan.R`, `diag_gates_at_landed_modes.R` and
  `diag_fert_ridge_gates.R` (IRF / TH columns)
- the app's review panel (`app/R/review.R`) computed it live, so it was fixed at the source
