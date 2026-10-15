# Handoff — CarbonCycleEmulator, 2026-08-10

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, branch `main`, 11 commits,
HEAD `a0a7d40`. Test suite: **177 passing** (`Rscript tests/run_tests.R`).

Read this plus `DESIGN.md` (spec), `DATA.md` (sources + traps), `CHANGELOG.md` (decision
log) and `CLAUDE.md` (project rules) to pick up cold.

---

## 1. Where we are

Built, gated and committed: data layer → carbonate chemistry → 84-state model core →
preindustrial spinup → forcing assembly → Rcpp production core → calibration machinery.
A pilot MCMC has run and **told us the sampler is not ready for production** (§4).

Nothing in this project has produced a reportable scientific result yet. The model runs
end to end on uncalibrated defaults and reproduces the *shape* of the record with all
errors pointing one direction (sinks too weak).

## 2. The three things to know before touching anything

1. **`R/model.R` and `src/ccx_core.cpp` are the same model twice.** R is the readable
   reference; C++ is the 479×-faster production core. **Any physics change must be made in
   both**, or `tests/testthat/test-parity.R` fails. That test is mutation-tested and does
   catch real porting errors (wrong index, dropped term, truncated solver).

2. **The bomb ¹⁴C injection SHAPE is a placeholder** (`ccx_bomb_c14_annual()`). UNSCEAR
   2000 Annex C has the annual atmospheric test yields but only as a PDF table; no
   machine-readable release was found. Consequences, already handled but easy to undo by
   accident:
   - bomb-window Δ¹⁴C (1950–1975) is **excluded from the likelihood** by default
     (`LIK_USE_BOMB_WINDOW = FALSE`), because a decomposition showed Δ¹⁴C carrying **90 %
     of all likelihood information** while resting on that placeholder;
   - `bomb_total` is a **calibrated** parameter with the Naegler & Levin (2006) prior
     (99.3–104.9 kmol), so shape error partly absorbs into magnitude;
   - **no bomb-era ¹⁴C result may be reported** until the real shape exists.

3. **7 constants are still provisional** and ledgered in `tests/testthat/test-constants.R`:
   `OCEAN_AREA_NH`, `OCEAN_AREA_SH`, `OCEAN_DEPTH`, `ALK_SURFACE`, `RHO_SEAWATER`,
   `NPP_GLOBAL_PI`, `SST_PCO2_SENSITIVITY`. `ccx_check_constants()` lists them. The last
   one additionally **risks double-counting** the carbonate module's own temperature
   dependence — check before ever applying it.

## 3. Decisions made (do not silently revisit)

| Decision | Choice | When |
|---|---|---|
| Stack | R end-to-end; Rcpp core with parity test | 08-09 |
| Ocean | box-diffusion column per hemisphere, 10 interior layers | 08-09 |
| Isotopes | ¹²C + ¹³C + ¹⁴C | 08-09 |
| App scope | historical + counterfactuals + SSPs + stylized + matched pulse/baseline | 08-09 |
| Audience | undergraduate environmental studies | 08-09 |
| ENSO index | **Niño 3.4 (1948+)**, 1991–2020 climatology (MEI.ext was retired upstream) | 08-09 |
| Δ¹⁴C zone aggregation | **area-weighted** to hemispheres | 08-09 |
| Bomb ¹⁴C | prescribed shape × **calibrated** total | 08-09 |
| GCB land sink | soft constraint, 3× inflated σ | 08-09 |
| Seasonal harmonics | joint-calibrated | 08-09 |
| SSP source | reuse RCMIP v5.1.0 CSVs | 08-09 |
| Nuclear-industry ¹⁴C | **promoted from v2 backlog into v1** | 08-10 |
| Natural ¹⁴C production | **solved by the spinup**, not prescribed | 08-10 |

## 4. Pilot MCMC result: NOT converged — this is the immediate next task

`calibration/run_pilot.R`, 1500 iters × 4 chains, seed 2026, 4.4 min,
→ `calibration/output/pilot_fit.rds`.

| Diagnostic | Value | Target |
|---|---|---|
| worst R̂ | **4.53** | < 1.05 |
| min ESS (bulk) | **4** of 3000 draws | ≥ 400 |
| acceptance | 0.045–0.063 | ~0.234 |
| log-posterior | −93,775 → −6,727 (best −6,469) | — |

**Diagnosis:** the chains gained ~87,000 log-units and were *still climbing at the last
iteration*. They are in transient burn-in, not sampling. This is a too-short-chain and
bad-starting-point problem, not evidence of a broken posterior. **No posterior numbers
from this run are usable.**

**Recommended fixes, in order:**
1. **Find the mode first.** Run `optim()` (or DEoptim) on the log-posterior from the
   current init, then start chains dispersed *around the mode*. Starting 18 correlated
   parameters at hand-set defaults ~87,000 log-units from the mode is the main problem.
2. **Longer chains and longer adaptation.** At 0.058 s/eval, 50k × 4 chains ≈ 3.2 h —
   an overnight run. Keep `adapt_frac` at 0.5 or raise it.
3. **Check for a narrow ridge.** 5 % acceptance after adaptation suggests strong parameter
   correlation (likely `k_w`/`h_ml`/`kz`, all controlling ocean uptake). If acceptance
   stays low after (1) and (2), reparameterize or use a scaled proposal from the mode's
   Hessian.
4. Only then run production, and gate on R̂ < 1.05 **and** ESS ≥ 400 before reporting.

## 5. Files that matter

| Path | Role |
|---|---|
| `R/model.R` | reference model (authoritative for meaning) |
| `src/ccx_core.cpp` | production core — must mirror the above |
| `R/spinup.R` | 1750 steady state; solves natural ¹⁴C production |
| `R/carbonate.R` | pCO₂ / Revelle, gated against seacarb |
| `R/forcing.R` | assembles all drivers onto the monthly axis |
| `R/likelihood.R` | observation model; **all weighting decisions live here** |
| `R/calibrate.R` | priors, transforms + Jacobians, MCMC driver |
| `data-raw/build_calibration_data.R` | parses raw → `data/*.rds`, prints the DESIGN §6 benchmarks |
| `data-raw/manual/` | **irreplaceable** Scripps files (site is 404); tracked in git |

## 6. Non-obvious state and traps

- **Scripps CO₂ Program is unreachable** (404 on every asset path). The files in
  `data-raw/manual/` cannot be re-downloaded. Do not clean that directory.
- **Only column 5 of the Scripps monthly files is an observation**; 7–10 are fit and
  gap-filled and are populated where nothing was measured.
- **Missing-value markers differ between Scripps files**: `NaN` in most,
  **−99.99** in `monthly_in_situ_co2_mlo.csv`.
- **Three ¹⁴C time constants coexist**: 8033 (Libby, age convention), 8267 (5730-yr, Δ¹⁴C
  convention), **5700 (true half-life, the model's decay constant)**. Never substitute one
  for another.
- **The MLO−SPO gradient must be computed from seasonally adjusted series** — raw monthly
  means alias MLO's ~6 ppm seasonal cycle and produced a spurious *negative* 1950s gradient.
- **Isotopes ride GROSS fluxes, not net.** Net fluxes vanish at equilibrium; representing
  only the net made the preindustrial isotope operator exactly singular.
- **Annual→monthly interpolation must conserve annual totals.** Use `method = "constant"`
  for sharply peaked non-negative sources; splining then clipping negatives inflated the
  bomb total by 4.3 %.
- Compiled artifacts (`src/*.o`, `src/*.so`) are gitignored; `Rcpp::sourceCpp` recompiles
  on first `ccx_load_cpp()` (~20 s).

## 7. Open items, roughly in priority order

1. **Get the MCMC converging** (§4) — blocks everything downstream.
2. **Digitize UNSCEAR 2000 Annex C** annual atmospheric test yields → unlocks bomb-era
   ¹⁴C, lets `LIK_USE_BOMB_WINDOW` be set TRUE, and removes the largest caveat.
3. **Source the 7 provisional constants**; check `SST_PCO2_SENSITIVITY` for double counting.
4. Optional ocean bomb-¹⁴C inventory constraint (GLODAP-era) as an integral check.
5. **Build the Shiny app** (`app/`) once a posterior exists: 6 tabs per DESIGN §7,
   precomputed posterior ribbons, live central-parameter runs, pulse lab.
6. Revisit Scripps if the site returns (their δ¹³C predates NOAA's by 13 years).

## 8. Sanity gates that must pass before any headline number

From DESIGN §6, all data-derived: airborne fraction **0.431** (1959–2024); MLO−SPO gradient
**0.47 → 3.97 ppm** (1950s → 2020s, seasonally adjusted); MLO seasonal amplitude
**5.95 → 6.86 ppm**; GCB 2015–24 sinks **ocean 3.22 / land 2.36 GtC/yr**; preindustrial CO₂
**276.88 ppm**, δ¹³C **−6.469 ‰**, Δ¹⁴C **+2.16 ‰**; deep-ocean Δ¹⁴C −150 to −200 ‰;
derived cosmogenic production within 2× of 545 mol/yr. Bomb-curve gates (peak **944.6 ‰ at
1963.625**, e-folding **15.4 yr**) are **blocked on item 7.2**.
