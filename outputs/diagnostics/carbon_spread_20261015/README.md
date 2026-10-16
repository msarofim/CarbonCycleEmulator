# CarboTope vs FaIR: carbon-cycle uncertainty (2026-10-15)

Marcus 2026-10-15: "How does CarboTope's carbon uncertainty compare to FaIR's?", then "Run both,
200 draws for the pulse band". Before this, CarboTope had a CO₂ band on the scenarios but none on
the pulse, and FaIR had a pulse band but only the mean CO₂ on the scenarios
(`FaIRtoFrEDI/scripts/run_fair_vv_for_ccx.py:162` writes `co2.mean` only). This directory
supplies both missing pieces. Nothing here is read by the app.

- CarboTope: mode `hilda31w` (`hilda_csl3v0kaidgbemwtc`), BETA v1.0.
- FaIR: FaIR 2.2.4 (calib 1.6.0), 841 configurations.
- Drivers at `56ec846`.

## Files

| file | what |
|---|---|
| `pulse_band.R` | CarboTope pulse band: 100 GtC in 2050 on Low / Medium / High (`vvL`, `vvM`, `vvH`), 200 MCMC draws |
| `pulse_band.rds` | annual bands 2050–2300 (CarboTope 5/50/95 %, central; FaIR mean/5/50/95 %; ΔT), key-year table, provenance |
| `pulse_band_key_years.csv` | key years, both models, widths and the FaIR/CarboTope width ratio |
| `pulse_band_draws.csv` | every draw's share and ΔT at the key years, with its pooled-file row and chain |
| `pulse_band.log` | the run log (gates, timing) |
| `fair_vv_co2_spread.py` | FaIR's CO₂ spread on the seven van Vuuren markers |
| `fair_vv_co2_spread.csv` | per scenario and year (1750–2301): CO₂ mean, 5/50/95 %, sd (ppm) |
| `fair_vv_co2_spread_key_years.csv` | 2050/2100/2150/2200/2300, with the 5–95 % width |
| `fair_vv_co2_spread_provenance.txt` | inputs, versions, checksums, gate values |

## Method

**CarboTope pulse band.**
- Draws: 200 rows of `outputs/mcmc_check_20261014_hilda31w_200k/pooled_u_thin2.rds` (17 000 rows,
  chain by chain), at `round(seq(1, 17000, length.out = 200))`, which gives 50 per chain. No RNG;
  the chains' seeds (20261002–05) are in the artifact.
- Each draw is decoded as `calibration/build_futures_ribbons.R` decodes the shipped band's draws.
  Each background is run as `server.R`'s `pulse_runs()` runs it.
- Varied: the 31 fitted carbon-cycle parameters.
- Fixed: the 14 held values, the climate response (fitted to FaIR), non-CO₂ forcing and the model
  structure.
- Share = (CO₂ with pulse − without) / (100 GtC / GtC-per-ppm), as an annual mean. FaIR's
  `af_*` columns use the same annual-mean convention.

**FaIR CO₂ spread.** The FaIRtoFrEDI exporter is imported read-only and its `run_one()` body is
repeated up to `f.run()`. Statistics are taken across the 841 configurations. Neither repository's
existing files change.

## Gates

| gate | result |
|---|---|
| GC: decoded best fit = the app's central pulse (tol 1e-6 ppm, the band builder's) | 1.4e-9 ppm |
| GCm: best fit with `beta_max` × 1.01 must fail GC | 0.090 ppm, rejected |
| G99: ≥ 99 % of draws run | 200 / 200, no warnings |
| G1: FaIR config-mean CO₂ / GMST = the exporter's stored CSVs (tol 1e-9) | ≤ 2.3e-13 ppm, ≤ 8.9e-16 K |
| G1m: the same against the next marker's file must fail | 51–765 ppm, rejected |
| G2: FaIR p05 ≤ p50 ≤ p95, p05 ≤ mean ≤ p95 | pass |
| byte-identity, FaIR (two runs) | all three files identical |
| byte-identity, CarboTope band (two runs) | `.rds` identical; both CSVs identical apart from the provenance column, which names the output file |

## Results

### Pulse: share of 100 GtC (released 2050) still in the air, 5–95 %

| background | year | CarboTope | FaIR | width ratio FaIR / CarboTope |
|---|---|---|---|---|
| Low | 2100 | 42.7–46.1 % | 37.1–51.2 % | 4.2 |
| Low | 2300 | 24.0–26.7 % | 23.0–36.2 % | 4.8 |
| Medium | 2100 | 50.9–54.6 % | 40.4–64.0 % | 6.3 |
| Medium | 2300 | 39.0–43.1 % | 23.9–66.6 % | 10.4 |
| High | 2100 | 54.4–58.5 % | 42.7–69.2 % | 6.4 |
| High | 2300 | 54.1–61.1 % | 28.8–94.3 % | 9.4 |

- CarboTope's band is 3–7 percentage points wide. FaIR's is 12–66.
- CarboTope's band lies inside FaIR's at every key year and background.
- CarboTope's 95th percentile falls below FaIR's mean from 2200 on the Medium background and from
  2150 on High (at 2150 on Medium it is 52.3 % vs 51.4 %).

### Scenarios: CO₂ concentration, 5–95 % width (ppm)

CarboTope's band is `data/futures_ribbons.rds` (the shipped Futures band, 17 000 draws, to 2150).

| scenario | 2050 CarboTope / FaIR | 2100 CarboTope / FaIR | 2150 CarboTope / FaIR |
|---|---|---|---|
| Very low | 2.4 / 12.0 | 3.8 / 14.4 | 4.0 / 15.3 |
| Low-to-negative | 2.0 / 15.4 | 4.9 / 13.6 | 10.2 / 7.1 |
| Low | 2.2 / 14.5 | 3.8 / 19.9 | 4.8 / 16.9 |
| Medium-to-low | 2.3 / 16.5 | 3.5 / 35.4 | 4.3 / 30.5 |
| Medium | 2.4 / 18.1 | 6.0 / 69.3 | 10.4 / 127.8 |
| High-to-low | 2.8 / 19.6 | 9.3 / 67.3 | 7.9 / 49.0 |
| High | 2.7 / 20.3 | 10.0 / 98.5 | 23.0 / 228.5 |

- Both models start narrow: the 5–95 % width in 2024 is 1.1 ppm (CarboTope) and 1.7 ppm (FaIR).
  So the comparison is not driven by a difference in historical spread.
- The one row where CarboTope is wider is Low-to-negative in 2150 (10.2 vs 7.1 ppm). This
  scenario has net CO₂ removal.

## What the two bands include

- **CarboTope:** carbon-cycle parameter uncertainty within one model structure, conditioned on the
  CO₂, isotope and sink records, with the climate response fixed.
- **FaIR:** each configuration also differs in climate and forcing parameters, so its CO₂ spread
  includes the climate–carbon feedback through temperature.

A like-for-like split (FaIR with its climate parameters held at one setting, or CarboTope with a
varied climate response) was not run.
