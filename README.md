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

**Public beta `v1.0-hilda29l`, 2026-09-22.** The MODEL is frozen and tagged; what is
under review is how much its remaining flaws matter. The app's seventh tab, **"Known
issues"**, names each one, shows it measured by the running model, and asks whether it
is a **deal-breaker, fixable, or acceptable** for a pedagogical model. Comments go to
the Substack post the app links to; anyone whose comment changes the model or the
write-up is credited in the acknowledgements.

**Main branch, 2026-10-13: the canonical is `hilda31w`** (the WTC refit; 31 fitted names, fourteen held).
It is `hilda29e`'s model with the citation batch: working values replaced by cited ones (surface alkalinity and salinity
from GLODAP, the carbonate constants at that salinity, the ocean column depth, the seasonal sea-surface temperature lag
per hemisphere, the photosynthetic and pump ¹³C fractionations, IntCal20's published ¹⁴C errors, and the nuclear
industry's ¹⁴C split by hemisphere), and two former working values now fitted: the Northern Hemisphere's share of the
bomb ¹⁴C (`bomb_share_NH`, 0.84 ± 0.03) and the lag of soil respiration behind temperature (`seas_T_lag`, 0.3 ± 0.3
months). The interannual module's four values are carried from `hilda29e` without a second pass (its check moved one
of them by 0.11 of its standard deviation, just over the 0.1 stopping rule). What it buys: +10.8 log-likelihood over
`hilda29e` scored under the same cited values, mostly in the seasonal cycle, the bomb ¹⁴C record and the ice cores;
GATE V still passes. What it costs: the GCB rows (−1.1), and `seas_T_lag` is not separately identified (it sits near
its floor, correlated +0.96 with the Northern Hemisphere's phenology lag, `seas_lag_p_NH`, how far plant growth trails sunlight). CO₂ in 2300 under
SSP5-8.5 is 1487 ppm, 12 ppm above `hilda29e`'s. CHANGELOG 2026-10-12 (dd)–(ii), 2026-10-13 (b)–(f).
The app's release mode is decided separately.

**Previous canonical, 2026-10-08 to 2026-10-13: `hilda29e`** (objective #18, second pass; 29 fitted names, fourteen held).
It is `hilda33p`'s model with the interannual "cut": the ENSO terms that shape only the year-to-year variability (the
land response's lag and amplitude, and the ocean's ENSO limb `w_enso_l2`) are fitted in a separate module to the
detrended CO₂ growth rate and GCB's ocean ENSO slope, then held while everything else is refit; the ENSO forcing index
is detrended. The module was iterated to a fixed point: on the second pass every module value moved less than 0.01 of
its own standard deviation. What it buys: the interannual variability check (GATE V) passes, and the land's ENSO lag
(about 5.9 months) is the one the growth record shows. What it costs: the ice cores (about −8 log-units) and the ocean's
climate effect against GCB (2.16× its value, from 1.88×), both from the detrended index. CHANGELOG 2026-10-08 (a)–(e).
The app's release mode is decided separately (below).

**Previous canonical, 2026-10-06 to 2026-10-08: `hilda33p`** (objective #16; 33 fitted names, ten held).
It is `hilda34g` plus the stratification feedback (as the surface warms faster than the deep ocean, the
upper ocean mixes less, so added carbon is carried down more slowly; its strength fixed from observation and
mixing law, not fitted), with the greening term held at 0 (a term whose sign the record cannot fix is not
fitted), refit on objective #16. On the record it is indistinguishable from `hilda34g` (likelihood −1.77 at
one fewer fitted name); it was adopted on physics. CHANGELOG 2026-10-05 (p), 2026-10-06 (a). The app's release
name is **BETA v1.0 CarboTope** (`APP_RELEASE_NAME` in `app/global.R`), now cut on `hilda33p`
(`APP_RELEASE_MODE`; Marcus 2026-10-06: "Move v1.0 to the new mode").

**2026-10-03: `hilda34g`** (objective #15; 34 fitted names, the same
nine held). It is `hilda33d` (2026-10-01: `hilda29l`'s structure with the vegetation-capacity loop off,
the evidence-based shape prior on CO₂ fertilisation, the inert soil pool, nitrogen-deposition retention,
a sign-free greening term, and a fitted allocation of the Global Carbon Budget's imbalance) plus a fitted
delay of 2.6 months between El Niño and the land's carbon response, refit on objective #15 (the ice-core
CO₂ row cut to pre-1958, the Law Dome ice-core δ¹³C row added, the gas-exchange and interhemispheric
exchange priors cited). CHANGELOG 2026-10-03. The release was cut on `hilda34g` from 2026-10-03 to
2026-10-06 (Marcus 2026-10-03: "Move v1.0 to hilda34g"). The `v1.0-hilda29l` git tag
marks the 09-22 freeze; the paragraphs below describe that freeze.

**Product-ready as of 2026-09-21** (`notes/assessment_2026-09-21_product_ready.md`). Model core,
calibration and app run end to end. The calibrated vector is **`hilda29l`**: a **29-parameter
maximum-a-posteriori fit** (nine further names held at stated values) under the `hilda_csl3`
structure — the HILDA high-latitude ocean (a cold surface box and a cold deep box per hemisphere,
a biological pump in both columns), a seasonal mixed layer with a real entrainment channel, and a
layer-3 Niño3.4 return limb that carries the ocean's ENSO response as an upwelling anomaly
(13.7 ± 2.1 Sv per index, inside the observed bracket at one standard deviation) — located by
dispersed multistart optimisation of the posterior under objective #13. The test suite is ~4,000
checks. The seasonal-mixed-layer-off control (`hilda31pe`) and the column fit (`ent26`) are kept as
like-for-like controls.

**It is a single best fit, not a posterior.** No MCMC has been run, no posterior ensemble is
shipped, and **the app therefore shows no uncertainty bands** — it says so in-product. A
posterior is planned; the design for it is in [DESIGN.md](DESIGN.md) §5.3.

### What it is for, and what that implies

This is a **pedagogical model, not an emulator.** The point is to show that constraining a
carbon cycle with seasonal and isotopic observations makes certain behaviours — a long
perturbation lifetime, for instance — *emerge*. It is not tuned to reproduce any particular
benchmark, and it should not be used as a drop-in emulator for one.

### Known limitations, stated plainly

- **The hemispheric structure of the δ¹³C disequilibrium is not reproduced.** The model's
  MLO−SPO δ¹³C gradient is twice the observed one (a constant −0.07 ‰ offset, with the CO₂
  gradient right), and the surface-ocean disequilibrium asymmetry between the hemispheres is a
  third of what the GLODAP bottles show. Both need an interhemispheric deep-ocean exchange
  that a one-column-per-hemisphere ocean does not have; every transport tried within the
  design moves the levels and not the asymmetry. The air-sea isotopic timescale is over-
  determined by about 15 % between the surface disequilibrium and the atmospheric δ¹³C decline.
- **Interannual variability is about 60 % of observed.** The ENSO *sensitivity* of the ocean
  sink is 0.89× the Global Carbon Budget's, carried by the upwelling limb; the *variance* is
  not, and no ocean-side mechanism tried reaches it. Treat the app's ENSO switch as a
  sensitivity, not a reconstruction.
- **The perturbation lifetime is shorter than the Joos et al. (2013) multi-model mean**
  (IRF(100) 0.28 against 0.41), though the 1000-year partition between land, ocean and air is
  inside their band. Why is an open question, not a tuned-away discrepancy.
- Eleven constants are marked `provisional` in `R/constants.R` (values inverted through the
  model, held, or without a pinning source); the label is carried explicitly rather than quietly.
  Five fitted names are stand-ins for mechanisms the design names but does not carry
  (`notes/assessment_2026-09-21_product_ready.md` §4).

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
