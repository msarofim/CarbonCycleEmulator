# CarbonCycleEmulator

A simple, observationally calibrated global carbon cycle model — two hemispheres, monthly
time steps, two-pool land biosphere, box-diffusion ocean, and three carbon isotopes
(¹²C, ¹³C, ¹⁴C) — wrapped in an interactive RShiny app for teaching how the carbon cycle
works.

The model is calibrated against the instrumental CO₂ record (Mauna Loa, South Pole, Law Dome
ice core), atmospheric Δ¹⁴C including the bomb spike, δ¹³C (the Suess effect), Global Carbon
Budget sink estimates, the seasonal harmonics and interhemispheric gradients of CO₂ and δ¹³C,
and GLODAP ocean gradients. The app lets users explore where emitted carbon goes, switch off
individual mechanisms (CO₂ fertilization, ENSO, the ocean's Revelle buffering), read the
isotopic fingerprints of fossil carbon, and run future scenarios — SSPs, stylized pathways,
and matched pulse/baseline experiments.

**Audience:** people with an introductory environmental-science background (think
undergraduate environmental studies).

## Status

Model core, calibration and app are **built and running end to end**. The current calibrated
vector (`hilda31`, adopted 2026-09-08) is a **31-parameter maximum-a-posteriori fit** under the
HILDA high-latitude ocean structure (a cold surface box and a cold deep box per hemisphere, a
biological pump in both columns, the flush and the cold-box gas exchange under observation priors),
located by multistart optimisation of the posterior; the test suite is ~2,150 checks (2026-09-08).
The previous column fit (`ent26`, 26 parameters, 2026-09-04) is kept as the like-for-like column control.

**It is a single best fit, not a posterior.** No MCMC has been run, no posterior ensemble is
shipped, and **the app therefore shows no uncertainty bands** — it says so in-product. A
posterior is planned; the design for it is in [DESIGN.md](DESIGN.md) §5.3.

### What it is for, and what that implies

This is a **pedagogical model, not an emulator.** The point is to show that constraining a
carbon cycle with seasonal and isotopic observations makes certain behaviours — a long
perturbation lifetime, for instance — *emerge*. It is not tuned to reproduce any particular
benchmark, and it should not be used as a drop-in emulator for one.

### Known limitations, stated plainly

- **The ocean's ENSO response is carried by a fitted coefficient, not by a mechanism.** The
  model's only physical ENSO→ocean pathway is sea-surface-temperature solubility, which has
  the *wrong sign*; fitted terms compensate for it, and the net response is about half the
  observed sensitivity. The model has no tropical box, so the upwelling that actually drives
  the observed signal is not representable. **Treat the app's ENSO switch as illustrative.**
- **Interannual variability is about three-quarters of observed**, which is mostly downstream
  of the point above.
- **The perturbation lifetime is shorter than the Joos et al. (2013) multi-model mean**
  (IRF(100) 0.276 against 0.409), though the shape of the decay is within their band. Why is
  an open question, not a tuned-away discrepancy.
- Several calibration targets and constants are marked `provisional` in `R/constants.R`; the
  label is carried explicitly rather than quietly.

| Document | Contents |
|---|---|
| [DESIGN.md](DESIGN.md) | model specification, calibration design, sanity gates |
| [DATA.md](DATA.md) | every data source, its traps, and the code that assembles it |
| [CHANGELOG.md](CHANGELOG.md) | decision log, including what was tried and abandoned |

Raw inputs are not in the repo — they are ~3.5 GB and are reproducible from the download
script, whose `MANIFEST.csv` records every URL, access date, SHA-256 and citation. To build
from a fresh clone:

```bash
Rscript data-raw/download_data.R && Rscript data-raw/build_carbonate_tables.R && Rscript data-raw/build_calibration_data.R && Rscript tests/run_tests.R
```

**Author:** Marcus C. Sarofim (NYU Marron Institute)
