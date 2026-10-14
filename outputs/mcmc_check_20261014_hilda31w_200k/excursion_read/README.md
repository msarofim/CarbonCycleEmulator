# Chain 4's excursion: where it went, and whether the futures care (2026-10-14)

The hilda31w 200k read (`../read_20261014_drop0.log`) is NOT converged by Vehtari et al. (2021)'s reference.
R-hat max is 1.241 on `seas_T_lag`, with `seas_lag_p_NH` at 1.199 and `seas_lag_p_SH` at 1.150; their bulk ESS is 13–19.
These files locate the failure and measure what it does to the deliverable. They REPORT; Marcus rules.

All scripts run from the repo root at `54b3ef9`. None uses RNG, and none writes to `data/`.

| file | what it is |
|---|---|
| `by_chain_quarters.R` → `.log` | Per chain, the kept-sample median by quarter of the window, in parameter units, for the worst-mixing names. Also the pooled correlations of the lag triplet. |
| `by_chain_blocks.R` → `.log` | Per chain, by 10k-iteration block: the share of draws with `seas_T_lag` > 1 month, and the medians of `seas_T_lag`, `h_ml` and logpost. |
| `make_subset.R` → `subset_ex_vs_main.rds` | 400 u-draws, evenly spaced, no RNG. Rows 1–200 come from chain 4's excursion window (iterations 50 001–115 000; 3 250 kept samples). Rows 201–400 come from chains 1–3 (25 500 kept samples). Re-running it reproduces the file byte-identical. |
| `build_ribbons_ex_vs_main_20261014.log`, `ribbons_ex_vs_main.rds` | `calibration/build_futures_ribbons.R --draws=<that subset> --cores=8`, run on the Mac. 400 of 400 draws ran in 6.6 min. The stamp reads `54b3ef9+dirty?` only because `--out` pointed outside the repo, so git's `:(exclude)` refused it. No tracked file was modified. |
| `compare_ex_main.R` → `.log` | At every key cell (7 scenarios × CO₂ / GMST × 2050 / 2100 / 2150): the excursion group's median minus the main group's, divided by the main group's 5–95 % width. |

## What it shows

- **Where the excursion went.** Chain 4 left the region chains 1–3 occupy (`seas_T_lag` ≈ 0.1–0.4 months) at ~50k and walked a joint ridge.
  - `seas_T_lag` reached 1.7 → 2.65 months; `seas_lag_p_NH` 1.25 → 1.68; `seas_lag_p_SH` 2.33 → 2.76.
  - `h_ml` fell to ~45 m at 80–110k.
  - It returned by ~115k. It spent 39.5 % of its kept samples at `seas_T_lag` > 1. Chains 1–3 spent 5.3 / 2.5 / 1.6 %.
  - The region's logpost sits ~2–7 below typical: block medians −1073 to −1078, against ~−1070.
  - So it is a TAIL along a curved ridge, not a better mode. A random-walk proposal with a covariance frozen at 30k crosses it slowly.
- **What it does to the band.** Excursion draws against main draws:
  - the median shifts by **0.10 (CO₂) / 0.13 (GMST) of the 5–95 % width** at the median cell, and **≤ 0.28** at the worst;
  - the worst cells are vvLN CO₂ 2150 (−2.76 ppm on a 10.07 ppm width) and vvLN GMST 2100 (−0.007 °C on 0.027 °C);
  - the widths agree within ×0.77–1.17.
- ⚠ **These are not effective-sample-size-adjusted.** The 200 excursion draws come from one autocorrelated stretch of one chain.
- ⚠ **The test bounds the effect, but does not fix the weight.** The region's true posterior weight is unknown: chains 1–3 put 1.6–5 % there and chain 4 puts 40 %.
