# CarbonCycleEmulator

The model behind **CarboTope**, an interactive R Shiny app for teaching how the carbon cycle
works. App: https://01a14244-5cc3-1951-7b06-9e2fb07beae3.share.connect.posit.cloud/

A simple, observationally calibrated global carbon cycle model: two hemispheres, monthly
time steps, a four-pool land biosphere (leaves, wood, fast and slow soil) plus an inert soil
store, an ocean of a mixed layer over ten diffusive layers plus a cold high-latitude surface
box and a cold deep box per hemisphere, and three carbon isotopes (¹²C, ¹³C, ¹⁴C). The
hemispheres exchange carbon only through the atmosphere. Historical runs are driven by
observed global mean surface temperature (IGCC); future runs by a temperature response fitted
to FaIR 2.2.4 (calib 1.6.0).

The model is calibrated against the instrumental CO₂ record (Mauna Loa, South Pole, Law Dome
ice core), atmospheric Δ¹⁴C including the bomb spike, δ¹³C (the Suess effect), Global Carbon
Budget sink estimates, the seasonal harmonics and interhemispheric gradients of CO₂ and δ¹³C,
and GLODAP ocean gradients. The app lets users explore where emitted carbon goes, switch off
individual mechanisms (CO₂ fertilization, ENSO, the ocean's Revelle buffering), read the
isotopic fingerprints of fossil carbon, and run future scenarios: the seven CMIP7 ScenarioMIP
marker pathways (van Vuuren et al. 2026; Zenodo 10.5281/zenodo.20713982, v1.1.1), user-built
pathways, and matched pulse/baseline experiments.

**Audience:** people with an introductory environmental-science background (think
undergraduate environmental studies).

Teaching software, not peer-reviewed.

## Status (2026-10-24)

- **App:** CarboTope, release BETA v1.1 (cut on `hilda31fl`, 2026-10-24). BETA v1.0, the first public
  version (cut on `hilda31w`), is the live app until v1.1 is published.
- **Canonical parameter set:** `hilda31fl` (adopted 2026-10-23): 31 parameters fitted, 14 held
  at stated values. It refits `hilda31w` (2026-10-13) with every Mauna Loa CO₂ observation taken
  from Scripps flask samples, the same flasks that supply the Mauna Loa δ¹³C record. The app
  live-runs a single parameter set (the posterior mode).
- **Posterior sampling** (at `hilda31fl`): adaptive Metropolis, 4 chains × 200,000 iterations, 17,000 draws.
  Max R-hat 1.11, on the seasonal-lag parameters: not converged by the strict criterion.
- **Uncertainty bands:** the Futures tab's CO₂ view shows the 5–95 % range of those draws
  (`data/futures_ribbons.rds`). It varies only the fitted carbon-cycle parameters, so temperature
  has no band. The app also shows FaIR 5–95 % ranges on Known issue 5 and in the pulse lab.
- **Tests:** full suite 9,395 passed, 0 failed, 1 skipped (commit `9c7ec7de`, 2026-10-24).
- **Git tag `v1.0-hilda29l`** (2026-09-22) is an earlier internal freeze, not the app's
  BETA v1.0.

### What it is for

This is a **pedagogical model, not an emulator.** The point is to show that constraining a
carbon cycle with seasonal and isotopic observations makes certain behaviors — a long
perturbation lifetime, for instance — *emerge*. It is not tuned to reproduce any particular
benchmark, and it should not be used as a drop-in emulator for one.

### Known issues

The app's **Known issues** tab measures each of these with the running model:

1. The model's CO₂ sits above Mauna Loa (a station offset).
2. The north-south δ¹³C gradient is twice the observed one.
3. The ocean's north-south isotopic disequilibrium is too symmetric.
4. Year-to-year variability is somewhat smaller than observed (about 70–90 %).
5. CO₂ pulse decay compared with other sources: IRF(100) 0.37 here, 0.41 in Joos et al.
   (2013), 0.36 in FaIR 2.2.4 (calib 1.6.0).
6. The uncertainty band covers only the carbon-cycle parameters.
7. Stand-ins and provisional constants: 4 fitted stand-ins and 3 held at 0; 11 constants
   marked `provisional` in `R/constants.R`.
8. Ocean CO₂ uptake declines with warming about twice as fast as in ocean models.

Feedback: the Substack post linked from the app's Known issues tab; quote the issue number.

## Run / test

From the repository root, in R (developed on R 4.5, arm64 Mac):

```bash
Rscript -e 'shiny::runApp("app", launch.browser = TRUE)'
```

Start-up takes ~6–8 s on the author's laptop. It compiles `src/ccx_core.cpp` with Rcpp, so a
C++ toolchain is needed. Packages: `shiny`, `bslib`, `ggplot2`, `Rcpp`.

```bash
Rscript tests/run_tests.R
```

The full suite takes ~20 min. It also needs `testthat` and `withr`; `seacarb`, `readxl` and
`digest` are used by a few cross-checks.

Both read only tracked files: the processed inputs in `data/` and the canonical parameter
file under `calibration/output/`. Neither needs the raw downloads. On a fresh clone, the few
tests that re-check a processed file against its raw download skip, with the reason printed.

Rebuilding `data/` is not a one-command step. The raw downloads (`data-raw/downloads/`,
several GB, not tracked) are fetched by `data-raw/download_data.R`, but some inputs come from
the author's other repositories (the FaIR runs, the van Vuuren scenario file, and local copies
of the IGCC temperature and RCMIP emission files), so those steps cannot be reproduced from a
fresh clone.

## Data

The MIT license covers this repository's code and the author's own text. It does not cover
third-party data: the observations, emissions and model outputs in `data/` (processed) and
`data-raw/manual/` (raw files that cannot be fetched by script: Scripps CO₂ Program records,
redistributed because the program's website returned HTTP 404 for every data file when they
were gathered on 2026-08-09, and tables transcribed from published papers) remain under their
providers' terms. Sources, access dates, checksums and citations are in
`data-raw/downloads/MANIFEST.csv` and [DATA.md](DATA.md). Cite the original providers when you
use these data.

## Layout

`R/` the model; `src/` the C++ core; `app/` the app; `calibration/` fitting and diagnostic
drivers and their outputs; `data/` processed inputs (`.rds`); `data-raw/` download and build
scripts; `tests/` the testthat suite. `notes/`, `outputs/` and `logs/` are dated working
records, often superseded; `CHANGELOG.md` is a raw working log.

Comments of the form `[[name]]` in the code point to the author's private research notes,
which are not in this repository.

| Document | Contents |
|---|---|
| [DESIGN.md](DESIGN.md) | model specification, calibration design, sanity gates (2026-08-09 spec with dated amendments) |
| [DATA.md](DATA.md) | every data source, its traps, and the code that assembles it |
| [CHANGELOG.md](CHANGELOG.md) | raw working log, including what was tried and abandoned |
| [app/DEPLOY.md](app/DEPLOY.md) | how the app is bundled and deployed |

**Author:** Marcus C. Sarofim
