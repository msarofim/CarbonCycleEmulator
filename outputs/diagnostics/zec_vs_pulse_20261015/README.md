# Does the present CO₂ excess decay like a pulse? FaIR and CarboTope, 2026-10-15

**The question** (Marcus, checking Steven Schwartz): "if anthropogenic CO₂ emissions were to end in 2030, what percent
of the anthropogenic increase would remain in 2130, compared to if we add an emission pulse in 2030, what percent of
that pulse would remain in 2130." Schwartz argues the difference "is of second order because most of the excess CO₂
is fairly new".

**Answer:** it is not second order. In 2130:
- **FaIR** keeps about **71 %** of the 2030 excess, against **37 %** of a pulse released into the same world (1.9×).
- **CarboTope** keeps about **66 %**, against **36 %** (1.8×).

The gap widens with time, from about 1.6–1.7× at 20 years to about 2.0× at 270 years.

## Results (remaining fraction; FaIR = mean [p5–p95] over 841 configs, paired)

At +100 years, van Vuuren Medium (vvM):

| | excess left after CO₂ emissions stop | pulse left, same zero-emission world | ratio | pulse left, scenario continuing |
|---|---|---|---|---|
| FaIR 2.2.4 (calib 1.6.0) | 0.709 [0.660–0.757] | 0.374 [0.307–0.435] | 1.91 [1.73–2.16] | 0.497 |
| CarboTope `hilda31w` | 0.655 | 0.364 | 1.80 | 0.491 |

All seven markers at +100 years:
- **FaIR:** excess 0.706–0.711; pulse (zero background) 0.371–0.375; ratio 1.91–1.92.
- **CarboTope:** excess 0.655–0.677; pulse 0.364–0.366; ratio 1.80–1.85.
- **The excess barely depends on the marker**, because only the non-CO₂ forcing and the 2025–29 emissions differ.
- **The scenario-background pulse does depend on it:** 0.35–0.56 in FaIR and 0.34–0.55 in CarboTope, generally higher on higher-emission backgrounds.

By horizon, vvM:

| horizon | FaIR excess | FaIR pulse | ratio | CarboTope excess | CarboTope pulse | ratio |
|---|---|---|---|---|---|---|
| +20 | 0.857 | 0.510 | 1.69 | 0.841 | 0.534 | 1.58 |
| +50 | 0.780 | 0.422 | 1.86 | 0.748 | 0.430 | 1.74 |
| +100 | 0.709 | 0.374 | 1.91 | 0.655 | 0.364 | 1.80 |
| +200 | 0.633 | 0.325 | 1.98 | 0.572 | 0.296 | 1.93 |
| +270 | 0.604 | 0.303 | 2.03 | 0.541 | 0.266 | 2.03 |

The 2030 excess is 153–155 ppm in FaIR and 160–162 ppm in CarboTope.

## Why (a linear illustration, not a third model)

Superposing the Joos et al. (2013) Table 5 response (`R/joos_irf.R`, `JOOS_T5`) over the 1750–2024 emissions record
(`data/forcing_emissions_historical.rds`, with 2025–29 held at 2024) gives these shares of the 2030 airborne excess:

| emitted since | share of the 2030 excess | share of cumulative emissions |
|---|---|---|
| 2000 | 48 % | 38 % |
| 1990 | 58 % | 48 % |
| 1970 | 72 % | 64 % |

- **So about half the excess is "fairly new".** But the other half is old enough that the fast sinks have already
  taken their share of it, and from then on it decays only on the slow modes.
- **The same superposition** gives 0.70 of the excess left at +100 years, against IRF(100) = 0.41 (1.72×).
- ⚠ **This is a linear illustration only.** It overstates the 2030 excess, at 214 ppm against the models' 155–162,
  because the Joos response was fitted on a 389 ppm background. Quote the models' numbers, not these.

## Choices (each stated)

- **"Emissions end in 2030":** fossil and land-use CO₂ emissions are zero from 1 January 2030, so the last emitting
  year is 2029.
  - Non-CO₂ emissions and forcing follow the marker.
  - The pulse is released over 2030: CO2 FFI at timepoint 2030.5 in FaIR, fossil in 2030 in CarboTope.
- **Excess:** the CO₂ above preindustrial at 1 January 2030 + h, as a share of that at 1 January 2030.
  - FaIR uses its own airborne CO₂ accounting; the concentration route agrees to 4e-16 (G6).
  - CarboTope uses the 12-month mean centred on each date, against its 1750 annual mean.
- **Pulse:** 100 GtC (the pulse lab's size), measured as the annual mean of year 2030 + h, i.e. h years after the
  release-year midpoint.
- **Two pulse backgrounds:**
  - **the same zero-emission world:** like for like with the excess, and the headline;
  - **the marker continuing:** the pulse lab's own experiment.
- **No climate-free variant.** Both models run with their carbon-climate feedbacks on.

## Gates

**FaIR** (all passed, all seven markers; `*_gates.csv`):
- G1 bit-identical no-op;
- G2 baseline = the shipped exporter's CO₂ (≤ 2.3e-13 ppm);
- G3 exact causality;
- G4 exact zeroing and pulse;
- G5 the base-pulse arm reproduces the pulse lab's shipped FaIR grid (≤ 8.3e-17);
- G6 the ppm route.

**CarboTope** (passed):
- G1 bit-identical no-op;
- G4 the emissions tables;
- G3 causality to 1e-6 ppm:
  - The coupled carbon-climate loop's arms can stop after different numbers of passes. That leaves ≤ 2.1e-8 ppm
    before 2030, which goes to exactly 0 when the loop is tightened.
  - The one real acausal path this loop has had (09-24) left 3.5e-3 ppm.
  - A mutation (zeroing a year early) fails G3 at 5.55 ppm.

## Provenance

- **FaIR:**
  - driver `FaIRtoFrEDI/scripts/run_fair_zec_vs_pulse_for_ccx.py` @ `417db44` (branch `heat-ed-morbidity`, with the
    other CarboTope FaIR drivers);
  - FaIR 2.2.4, calib 1.6.0, 841 configs;
  - van Vuuren markers from `run_fair_vv_for_ccx.py`.
- **CarboTope:**
  - `calibration/diag_zec_vs_pulse.R` @ `6724e834`;
  - canonical `hilda31w`;
  - the app's own `app_run_coupled()` at `CLIM_TOL`.
- **No RNG in either.**
- **Files:**
  - FaIR summary, per-config, provenance and gates CSVs;
  - CarboTope CSV and log.
