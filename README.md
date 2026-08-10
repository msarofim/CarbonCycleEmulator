# CarbonCycleEmulator

A simple, observationally calibrated global carbon cycle model — two hemispheres, monthly
time steps, two-pool land biosphere, box-diffusion ocean, and three carbon isotopes
(¹²C, ¹³C, ¹⁴C) — wrapped in an interactive RShiny app for teaching how the carbon cycle
works.

The model is calibrated by Bayesian MCMC against the instrumental CO₂ record (Mauna Loa,
South Pole, Law Dome ice core), atmospheric Δ¹⁴C including the bomb spike, δ¹³C (the Suess
effect), and Global Carbon Budget sink estimates. The app lets users explore where emitted
carbon goes, switch off individual mechanisms (CO₂ fertilization, ENSO, the ocean's Revelle
buffering), read the isotopic fingerprints of fossil carbon, and run future scenarios —
SSPs, stylized pathways, and matched pulse/baseline experiments.

**Audience:** people with an introductory environmental-science background (think
undergraduate environmental studies).

**Status:** model core built and running end-to-end on uncalibrated defaults; calibration
and app pending.

| Document | Contents |
|---|---|
| [DESIGN.md](DESIGN.md) | model specification, calibration design, sanity gates |
| [DATA.md](DATA.md) | every data source, its traps, and the code that assembles it |
| [CHANGELOG.md](CHANGELOG.md) | decision log, including what was tried and abandoned |

```bash
Rscript data-raw/download_data.R && Rscript data-raw/build_carbonate_tables.R && Rscript data-raw/build_calibration_data.R && Rscript tests/run_tests.R
```

**Author:** Marcus C. Sarofim (NYU Marron Institute)
