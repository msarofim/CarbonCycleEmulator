# IntCal σ-units bug: impact measurement (2026-10-12)

This directory measures the impact of the bug in `notes/code_review_2026-10-12.md` §1. It does not fix it.
The `d14c_intcal` row is scored with the ¹⁴C-AGE σ (9–11 yr) as if it were ‰.
The measurement swaps in the published Δ¹⁴C σ (IntCal20 column 5, 1.2–1.3 ‰ over the window). The row's own d14c values stay as they are. The 4 ‰ `LIK_D14C_REP_OTHER` term stays in quadrature.

- **Driver:** `calibration/diag_intcal_sigma_impact.R`. It is untracked and not committed.
- **Where it ran:** the frozen worktree `~/ccx_frozen/intcal_impact_1b16747` (HEAD `1b16747`), with `data-raw/downloads` symlinked to the main tree.
- **IntCal20 file:** `https://intcal.org/curves/intcal20.14c`, accessed 2026-10-12, sha256 `974a66649f2ac8a53e6c99e256b019ac6982f999b12dcf7193162d4c1c09168e`. It is saved at `data-raw/downloads/intcal20/intcal20.14c` (gitignored).
  - ⚠ It is NOT entered in `MANIFEST.csv` / `download_data.R`, because the main tree was being edited by another session. Its provenance is recorded in the artifact instead. A MANIFEST entry is still owed.

## Files

| File | What |
|---|---|
| `intcal_impact_n1000.rds` | Per-draw results (`per_draw`), natural-scale parameters, weights, `is_diag`, parameter and output tables, mode-level numbers, verdict, `provenance` |
| `intcal_impact_n1000.log` | The driver's log for that run |
| `repro_n20_run{1,2}.rds/.log` | Reproducibility check: two runs at N = 20 are byte-identical (sha256 `a1cd1d30…`) |
| `timing.log` | The serial timing run: 0.77 s/draw including the vvM coupled run |

## Gates (all passed; the three driver gates were mutation-tested and each fired)

- **Mode logpost.** Recomputed −1166.949732, stored −1166.949732, diff 0.
- **Row identity.** The IntCal row recomputed from the tapped model output equals the objective's own `d14c_intcal` stream, diff 0, at the mode and at all 1000 draws.
- **vvM central line.** The decoded mode matches the app's `APP_SPIN` run to 1.8e-8 ppm.
- **Checks:**
  - All 1000 recomputed logposts equal the chains' stored `samples_lp` exactly.
  - The per-draw vvM CO₂ at 2100 and 2150 equals the shipped band's `key_draws` exactly.
  - CCX's converted d14c is within 0.106 ‰ of published column 4.

## At the canonical mode (n = 191 rows, 1750–1940)

| | as coded | corrected σ |
|---|---|---|
| mean σ used | 10.57 ‰ | 4.18 ‰ |
| row log-lik | −640.62 | −543.83 |
| χ²/n | 0.155 | 0.997 |

- **Residual (obs − model).** Mean −3.05 ‰, RMS 4.17 ‰. The linear trend is only +0.58 ‰/century.
- **Shape of the residual.** It is not a slope error. Decadal means run from +1.0 to −8.9 ‰:
  - −8.3 / −8.9 in the 1780s/90s;
  - −4.8 to −5.8 in the 1850s–70s;
  - −2 by the 1930s–40s.
- **Direction depends on the window.**
  - 1750s→1930s: the model declines 2.7 ‰ LESS than IntCal (18.6 vs 21.4 ‰).
  - 1850s→1930s: it declines about 2.5 ‰ MORE.

## Reweighting (N = 1000 MCMC draws, every 17th pooled row; weight = exp(Δℓ))

- **Δℓ across draws.** Mean 96.83, sd 0.94, range 93.9–99.8.
- **`ccx_is_diagnostics`.** ESS 437 / 1000; k-hat 0.149, below the 0.667 limit, so the reweighting is reliable by PSIS. Max weight 0.012.
- **Top shifts.** In units of the unweighted posterior sd; ± is the chain-to-chain standard error from four per-chain reweightings.

| | shift (sd) | ± chain se |
|---|---|---|
| luc_scale | +0.67 | 0.05 |
| bomb_total | −0.54 | 0.03 |
| rep_dC | +0.53 | 0.02 |
| imb_share_land | +0.43 | 0.02 |
| ndep_ret | −0.38 | 0.05 |

- **First-order check.** cov(θ, Δℓ)/sd(θ) agrees with the reweighted shifts: 0.63 / −0.57 / 0.56 for the first three rows.

**Outputs, unweighted → reweighted:**

| Output | Median, unweighted → reweighted | Shift (sd) | Largest quantile shift / 5–95 width |
|---|---|---|---|
| MLO CO₂ 2024 (scored line) | 422.78 → 422.73 ppm | −0.22 | — |
| Ocean sink, 2010–19 mean | 3.080 → 3.078 GtC/yr | −0.06 | — |
| Land sink (gross), 2010–19 mean | 2.861 → 2.907 GtC/yr | +0.60 | 0.20 |
| IntCal residual RMS | 4.170 → 4.146 ‰ | — | — |
| vvM CO₂ 2100 | 563.8 → 564.0 ppm | +0.13 | 0.040 |
| vvM CO₂ 2150 | 617.1 → 617.4 ppm | +0.14 | 0.066 |

5–95 % bands:
- **vvM CO₂ 2100:** [561.2, 566.9] → [561.4, 567.2] ppm.
- **vvM CO₂ 2150:** [612.8, 622.4] → [612.9, 623.0] ppm.

## Verdict

- **Reliability.** k-hat 0.149 is below the 0.667 limit and ESS is 437, so the reweighting is reliable.
- **Parameters.** Three move by more than 0.5 posterior sd: luc_scale, bomb_total and rep_dC. rep_dC is marginal: one of the four chains gives 0.46.
- **CO₂ futures.** The vvM 2100/2150 median and 5–95 % band each move by less than 0.1 × the band width (largest 0.066).

**Limitations:**
- The base sample is thin: min bulk ESS about 105 and R-hat about 1.05 (CHANGELOG 2026-10-09). The 1000 draws are autocorrelated.
- Reweighting estimates the corrected POSTERIOR. It does not give the refitted MODE, which the app's central line uses.
