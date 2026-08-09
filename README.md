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

**Status:** design phase. See [DESIGN.md](DESIGN.md) for the full specification and
[CHANGELOG.md](CHANGELOG.md) for the project log.

**Author:** Marcus C. Sarofim (NYU Marron Institute)
