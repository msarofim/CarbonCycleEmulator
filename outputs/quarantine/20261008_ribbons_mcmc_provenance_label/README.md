# QUARANTINE 2026-10-08 — the 50k MCMC preview band: two wrong PROVENANCE strings

## 1. The defect (a provenance-label bug; the band's numbers are not affected)
`calibration/build_futures_ribbons.R` @`641732c` hard-coded two strings that were true only of `hilda33d`'s Laplace band:
- `provenance$label` = "Gaussian approximation at the best fit, conditional on the 14 held values". These draws are
  **MCMC** draws (`--draws=` the pooled chains), not a Gaussian.
- `provenance$covariance_note` = "computed under the spline emissions interpolation, before the 2026-10-01 flip". That
  was `hilda33d`'s. `hilda29e`'s Hessian was computed 2026-10-08 (`recompute_hessian.R`, no interpolation override),
  under "constant", the same as the runs. The log's line "(the covariance predates the 2026-10-01 flip)" is wrong too.
- With supplied draws the covariance enters only the delta-method pre-check, so no band number depends on either string.

Found 2026-10-08 ~21:55 EDT, while the build was in flight (the driver was not edited until it exited).

## 2. The files
- `futures_ribbons_mcmc_20261008j_hilda29e_snap50k.rds` (md5 `0ec4518727686736fd7bbec8c3a3fc0c`): bands, key draws,
  linear check, provenance. 4200 of 4200 draws ran; built 21:03–22:04 EDT, 6 cores.
- `futures_ribbons_mcmc_20261008j_hilda29e_snap50k_20261008.log`: its log.
- Draws: `outputs/mcmc_check_20261008j_hilda29e_snap50k/pooled_u.rds` (committed `641732c`; window (30000, 51000],
  4 chains x 1050).

## 3. What still uses it
Its NUMBERS are valid. It is the 50k side of the "still widening, 50k vs 100k?" comparison and the input to
`diag_mcmc_band_by_chain.R --tag=hilda29e_snap50k`, read from here.

## 4. The fix and the replacement
- Fix: `build_futures_ribbons.R` derives the label from the draws' source ("MCMC posterior draws (supplied), …" with
  `--draws`), and the covariance note from `RB_COV_EMIS`, keyed by mode (an unlisted canonical stops the run).
- Replacement: the 100k band from the final chains,
  `outputs/diagnostics/futures_ribbons_mcmc_20261008j_hilda29e_final.rds`, built by the fixed driver. The 50k
  preview is not rebuilt: the only change would be the two strings, and rebuilding costs ~1 h on 6 cores while the
  chains still run.
