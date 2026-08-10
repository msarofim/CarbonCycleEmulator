# CarbonCycleEmulator — Design Document

**Status: DRAFT — awaiting Marcus sign-off. No model code until approved.**
Created 2026-08-09. This document is the authoritative spec; changes to it are logged in
`CHANGELOG.md`.

---

## 1. Purpose & audience

A simple, calibrated global carbon cycle model (two hemispheres, monthly steps, land +
box-diffusion ocean, ¹²C/¹³C/¹⁴C) wrapped in a public RShiny app. The app is a
communication tool calibrated to an **undergraduate environmental-studies major**: someone
who knows what the Keeling curve and the greenhouse effect are, but not what a Revelle
factor or Δ¹⁴C is. Every panel gets a one-sentence takeaway; isotope notation and unit
conversions (GtC ↔ ppm, ‰) get tooltips; advanced content lives in collapsibles.

Scientific goals, in order:
1. Reproduce the observed atmospheric CO₂ record (Mauna Loa + South Pole + ice core),
   including the seasonal cycle and its growing amplitude, from emissions alone.
2. Reproduce the isotopic fingerprints: δ¹³C Suess effect, pre-bomb ¹⁴C Suess dilution,
   the bomb-Δ¹⁴C spike and its decay, and the NH→SH bomb-spike propagation.
3. Match Global Carbon Budget (GCB) land/ocean sink partitioning within stated uncertainty.
4. Provide a defensible pulse-response (IRF) mode for pulse-vs-baseline pedagogy.

## 2. Locked decisions (Marcus, 2026-08-09)

| Decision | Choice |
|---|---|
| Stack | **R end-to-end** — model, MCMC, Shiny all in R; Rcpp core allowed if the sampler needs speed (see §5.5, flagged question Q4) |
| Ocean | **Box-diffusion column** per hemisphere (Oeschger-style): mixed layer + ~10 diffusive layers |
| Isotopes | **¹²C + ¹³C + ¹⁴C** |
| App scope | **Historical + scenarios**: counterfactual toggles, SSP pathways, stylized pathways, **pulse scenarios matched with baselines** |
| Deployment | **Public shinyapps.io** |
| Audience | Undergrad environmental-studies major |
| Calibration | Bayesian MCMC (adaptive Metropolis), posterior ensemble shipped with app |
| Seasonal cycle | Resolved (raw monthly obs; model carries seasonal NEP harmonics) |
| Timeline | Steady-state spinup at 1750; transient 1750→present; dense monthly likelihood 1958+ |
| Temperature forcing | Observed GMST from IGCC (standing obs convention) |
| ENSO | MEIv2 (1979+) spliced to extended MEI before; lagged land-flux term |

**Number-provenance convention for this doc:** values marked **[VERIFY]** are my working
recollections of literature values. Each must be replaced by a cited value (paper + table,
or dataset + access date) in `data-raw/constants.R` before any code uses it. Values marked
**[CAL]** are calibrated parameters. Unmarked values are definitional or arithmetic.

---

## 3. Model structure

### 3.1 Reservoirs and state vector

Per hemisphere *h* ∈ {N, S}, per isotope *i* ∈ {12, 13, 14}, carbon mass in GtC:

- **Atmosphere** `M_atm[h,i]` — one well-mixed tropospheric box per hemisphere. No explicit
  stratosphere in v1; bomb ¹⁴C enters through a first-order delay kernel (τ_strat [CAL]),
  upgradeable to explicit strat boxes if the 1963–66 peak shape demands it (§10).
- **Land** `C_veg[h,i]`, `C_soil[h,i]` — two pools per hemisphere. These are *effective
  responsive* stocks, not literal global inventories; documented as such in the app.
- **Ocean** `C_ml[h,i]` (mixed layer) + `C_z[h, z, i]`, z = 1…10 interior layers with
  thickness increasing downward to a mean full depth ≈ 3700 m [VERIFY]. Interior layers
  exchange by vertical eddy diffusion only; no advective overturning loop in v1 (§10).

State dimension: 2 hemispheres × 3 isotopes × (1 atm + 2 land + 11 ocean) = **84 states**.

### 3.2 Atmosphere

Mixing ratio χ[h] (ppm) = M_atm[h,12+13] / (2.124/2), using 2.124 GtC per global ppm
[VERIFY — standard conversion, cite source].

d M_atm[h]/dt =
  E_foss[h] + E_LUC[h]            (prescribed emissions, §3.6)
  − F_as[h]                        (net air→sea, §3.4)
  − NEP[h]                         (net land uptake, §3.3)
  + F_ENSO[h] + F_seas[h]          (ENSO anomaly and seasonal NEP, §3.3)
  + (M_atm[h′] − M_atm[h]) / τ_ex  (interhemispheric exchange, τ_ex [CAL],
                                    prior centered on the SF₆-derived ≈1.3 yr [VERIFY])

### 3.3 Land (per hemisphere)

- **NPP with CO₂ fertilization:** NPP[h] = NPP₀[h] · (1 + β · ln(χ[h]/χ₀)), β [CAL].
  NPP₀ global ≈ 60 GtC/yr [VERIFY], split N/S by land productivity share [VERIFY].
- **Pools:** dC_veg/dt = NPP − C_veg/τ_veg;  dC_soil/dt = C_veg/τ_veg − R_het.
- **Heterotrophic respiration:** R_het = (C_soil/τ_soil) · Q10^(ΔT_GMST/10), Q10 [CAL].
  Preindustrial steady state (R_het = NPP₀) sets pool sizes: C_veg = NPP₀·τ_veg,
  C_soil = NPP₀·τ_soil. τ_veg, τ_soil fixed [VERIFY], chosen so effective stocks are
  defensible (order 500 GtC veg, order 1000–1500 GtC responsive soil [VERIFY]).
- **NEP** = NPP − R_het (annual-mean part).
- **Seasonal NEP:** F_seas[h](m) = A_h · [sin(2π(m−φ_h)/12) + a₂·sin(4π(m−φ₂ₕ)/12)] ·
  (NPP[h](t)/NPP₀[h]), zero annual integral. Amplitude scales with NPP so the growing
  Keeling-sawtooth amplitude *emerges* from fertilization rather than being prescribed.
  Harmonic coefficients [CAL] (or pre-fit to the mean seasonal cycle — flagged question Q2).
- **ENSO:** F_ENSO = γ_MEI · MEI(t − L_MEI), a land→atmosphere flux anomaly (El Niño →
  source), split between hemispheres by fixed tropical-land share [VERIFY]. γ_MEI, L_MEI
  [CAL]. Pinatubo 1992–93 is a *documented residual* in v1 (§10).
- **Land-use change:** prescribed GCB bookkeeping flux E_LUC(t) added to the atmosphere and
  decremented from C_veg (carries biospheric isotopic signature).

### 3.4 Ocean (per hemisphere column)

- **Air–sea exchange:** F_as = k_g · A_oc[h] · (pCO₂_atm[h] − pCO₂_ml[h]). Gas-transfer
  coefficient k_g [CAL], prior centered on the Wanninkhof global-mean CO₂ transfer velocity
  [VERIFY]. Ocean areas A_oc[N] < A_oc[S] [VERIFY — SH is ocean-dominated].
- **Mixed-layer carbonate chemistry:** pCO₂_ml = f(DIC_ml, T) via the Joos et al. (1996)
  polynomial perturbation fit [VERIFY exact coefficients], times the temperature factor
  exp(0.0423 · ΔSST) (≈4.23 %/°C, Takahashi [VERIFY]). ΔSST = scaled IGCC GMST anomaly.
  **The Revelle factor is therefore a state-dependent emergent quantity** — displayed in
  the app, not imposed. Mixed-layer depth h_ml [CAL], prior ~50–120 m.
- **Interior:** ∂C/∂t = ∂/∂z (K_z ∂C/∂z) discretized on the 10-layer grid (implicit
  tridiagonal solve — unconditionally stable, exactly conservative). K_z [CAL], prior
  spanning the classic box-diffusion values (order 2000–8000 m² yr⁻¹ [VERIFY against
  Oeschger 1975 / Siegenthaler & Joos 1992]).
- Total ocean DIC inventory at spinup should land near the ~38,000 GtC canonical figure
  [VERIFY]; reported in the app as a stock.

### 3.5 Isotopes

- **¹²C** is the bulk tracer (¹²C+¹³C treated as total C for mass budget; ¹³C tracked as
  ratio-relevant mass).
- **¹³C:** every flux carries a fractionation factor: photosynthesis ε_ab ≈ −18 ‰
  effective global (C3/C4-weighted) [VERIFY]; air→sea kinetic ≈ −2 ‰ and sea→air
  equilibrium ≈ −10 ‰, temperature-dependent [VERIFY, Zhang et al. 1995]. Fossil source
  δ¹³C ≈ −28 ‰ (constant in v1; time-varying fuel mix is v2, §10) [VERIFY]. LUC carries
  biospheric δ¹³C. Preindustrial δ¹³C_atm ≈ −6.4 ‰ [VERIFY].
- **¹⁴C:** transported *without* fractionation because all Δ¹⁴C observations are
  fractionation-corrected by convention (Stuiver–Polach); this is the standard trick and
  must be stated in code comments. Radioactive decay everywhere with the **true half-life
  5700 yr [VERIFY]** — *not* the Libby 5568 yr used in age-reporting conventions (classic
  gotcha; document in code).
  - **Natural production:** constant cosmogenic source balancing whole-model decay at
    spinup (solar-cycle modulation is v2). Spinup yields the natural Δ¹⁴C depth profile —
    deep-ocean Δ¹⁴C ≈ −150 to −200 ‰ [VERIFY] is a free check we get for nothing.
  - **Bomb source: SHAPE RESOLVED 2026-08-10** (see DATA.md §9). Total production P_bomb
    [CAL] keeps its sourced prior: Naegler & Levin (2006), *Closing the global radiocarbon
    budget 1945–2005*, JGR 111, doi:10.1029/2005JD006758, give total bomb ¹⁴C production
    1945–1980 as **99.3–104.9 kmol** (598–632 × 10²⁶ atoms). Injected into the NH (and a
    small SH share [VERIFY]) troposphere.
    **No test-yield series and no τ_strat parameter are needed.** This model has no
    stratospheric box, so what it wants is delivery, not production — and the delay kernel
    this line originally specified is *measured* rather than parameterised: two
    exponentials fitted to the Tans (1981) / Telegadas (1971) stratospheric ¹⁴C inventory,
    **39.97 kmol at τ = 1.00 yr** and **27.75 kmol at τ = 10.15 yr**. UNSCEAR 2000 Annex C
    is no longer required.
  - **Fossil fuel:** ¹⁴C-free by definition → Suess dilution emerges.
  - **Nuclear-industry source: IN v1** (promoted from the v2 backlog 2026-08-10 after a
    magnitude check overturned the "small" assumption). Prescribed from the Laemmel et al.
    (2025) compilation of reactor + reprocessing gaseous ¹⁴C releases, 1950–2023, in GBq.
    Cumulatively it is only ~1.1 % of bomb production, but its time profile is the
    *opposite* of the bomb's: releases **grow** from 0.20 mol ¹⁴C/yr (1950s) to
    42.5 mol/yr (2010s) while the bomb spike decays away. Against a 2010s atmospheric
    inventory of 86.1 kmol ¹⁴C, 42.5 mol/yr is **+0.49 ‰/yr**, versus an observed NH
    trend of **−4.30 ‰/yr** — i.e. **~11 % of the modern tendency**. Emissions are almost
    entirely NH, so the term also projects onto the NH−SH Δ¹⁴C difference.
    Bounding caveats point opposite ways: +0.49 ‰/yr is an upper bound (it assumes all
    released ¹⁴C stays airborne, whereas it partitions into ocean and land), while the
    emissions total is a lower bound (file coverage is incomplete — USA only 2010–2023,
    France NPP only 2005+). 11 % is the right order, not a precise figure.

### 3.6 Forcings (all prescribed, monthly-interpolated)

| Forcing | Source | Notes |
|---|---|---|
| Fossil emissions | GCB (latest) global fossil CO₂ | N/S split ≈ 95/5 fixed [VERIFY]; smooth annual→monthly, no fossil seasonality in v1 |
| LUC emissions | GCB bookkeeping mean | to atmosphere, from C_veg |
| GMST anomaly | IGCC (standing convention) | drives Q10 respiration + SST factor |
| MEI | MEIv2 1979+ spliced to extended MEI (1871–2005) | splice documented; overlap regression |
| Bomb ¹⁴C | Yield-history shape × P_bomb [CAL] | via τ_strat kernel |
| Cosmogenic ¹⁴C | Constant (spinup balance) | v2: solar modulation |
| Future scenarios | SSP CO₂ emissions (fossil+LUC) from RCMIP-format CSVs (reuse FaIR-project inputs — flagged question Q3) + stylized generators | §7 |

### 3.7 Numerics

- Monthly master step. Air–sea exchange and mixed-layer↔interior diffusion are the stiff
  terms (gas-exchange e-fold ~ h_ml/k_w ≈ weeks): handle by sub-stepping (RK4 with ~4
  substeps/month) or semi-implicit air–sea + implicit diffusion. Decide at implementation;
  either way the **conservation test is a hard gate**: with zero emissions and zero decay,
  total model carbon constant to ~1e-10 relative per century; with decay, ¹⁴C budget closes
  to the same tolerance.
- Spinup: analytic/iterative steady state at 1750 (χ₀ ≈ 277–278 ppm from Law Dome
  [VERIFY]), Δ¹⁴C_atm ≡ 0 ‰ by construction, δ¹³C_atm at its preindustrial value.
- Performance target: one 1750–2100 monthly run in **≤50 ms** so MCMC (10⁵–10⁶ evals) and
  live app sliders are comfortable. Pure-R vectorized first; Rcpp core with R
  reference-implementation bit-parity test if needed (flagged question Q4).

---

## 4. Calibration data

All downloads scripted in `data-raw/` with URL + access date + checksum; processed inputs
saved as versioned `.rds` in `data/`.

**ACQUIRED 2026-08-09** — 14 datasets, provenance (URL, access date, SHA-256, citation) in
`data-raw/downloads/MANIFEST.csv`; parsers in `data-raw/build_calibration_data.R`;
processed `.rds` in `data/`.

| Dataset | Coverage obtained | Role | Source |
|---|---|---|---|
| **Mauna Loa monthly CO₂** | **1958–2026, n=812** | **dense NH target** | **Scripps in-situ** (`data-raw/manual/`) |
| **South Pole monthly CO₂** | **1957–2024, n=711** | **dense SH target** | **Scripps merge** (`data-raw/manual/`) |
| Mauna Loa / South Pole CO₂ | 1958–2026 / 1975–2025 | independent cross-checks | NOAA GML |
| Mauna Loa flask CO₂ | 1960–2025, n=702 | cross-check on in-situ | Scripps (`data-raw/manual/`) |
| Law Dome CO₂ spline + samples | 154–1996 CE | pre-1958 target, spinup anchor | Rubino et al. 2019 (NOAA/WDS 25830) |
| Law Dome δ¹³C spline + samples | 1020–1993 CE | pre-1990 Suess target | Rubino et al. 2019 |
| Zonal Δ¹⁴C, monthly, 5 zones | 1941.2–2019.4, n=4689 | bomb-era target, both hemispheres | Hua et al. 2022 via `SoilR::Hua2021` |
| **MLO + SPO monthly δ¹³C** | **1980–2024 (n=532), 1977–2024 (n=528)** | **Suess partition target, one isotope scale** | **Scripps** (`data-raw/manual/`) |
| δ¹³C flasks MLO + SPO | 1990–2014, 1993–2014 | cross-checks | NOAA GML / INSTAAR SIL |
| MLO + SPO Δ¹⁴C | 2001–2007 (n=79), 1999–2007 (n=81) | **validation only** (feed Hua's zones) | Scripps (`data-raw/manual/`) |
| GCB global budget | 1959–2024 | sink partition constraint | GCB 2025 (Friedlingstein et al. 2026) |
| GCB historical budget | 1750–2024 | prescribed fossil + LUC forcing | GCB 2025 |
| GMST | 1850–2024 | Q10 + SST solubility forcing | IGCC (local, standing convention) |
| Niño 3.4 / MEIv2 | 1948–2026 / 1979–2026 | ENSO term | NOAA PSL |
| RCMIP SSP emissions | 1750–2500, 5 markers | app future scenarios | RCMIP v5.1.0 (local) |
| Ocean bomb-¹⁴C inventory | *not yet acquired* | optional integral constraint | GLODAP-era estimates |

**Coverage notes (see CHANGELOG 2026-08-09):**
- **The Scripps gaps are CLOSED, both hemispheres.** `scrippsco2.ucsd.edu` is still 404
  site-wide, but Marcus supplied the MLO and SPO files directly; they live in
  `data-raw/manual/` and are **tracked in git** precisely because `download_data.R` cannot
  regenerate them. Both stations are now on the **2012 SIO manometric scale** for CO₂ and
  the **Scripps isotope scale** for δ¹³C: CO₂ from 1957–58 (covering the whole bomb era)
  and δ¹³C from 1977/1980 to 2024. NOAA's records are retained as cross-checks. MLO has a
  true in-situ continuous record; SPO is flask-dominated, hence its "merge" product.
- **Only column 5 of the Scripps monthly files is a real observation.** Columns 7–10 are
  fit / seasonally-adjusted / gap-filled reconstructions. Reading a filled column would
  invent ~100 monthly "observations" — including every sparse 1950s month — and understate
  uncertainty. The parser takes column 5 and keeps the NaNs.
- **Inter-network offset: RESOLVED by moving both stations to Scripps, and it is not a
  constant.** Measured where both networks report: Scripps − NOAA = **−0.201 ± 0.217 ppm**
  at MLO (n=812) and **−0.134 ± 0.262 ppm** at SPO (n=543). But by decade the MLO offset
  runs 0.000, 0.000, +0.04, −0.36, −0.31, −0.38, −0.17, −0.29 — i.e. it *wanders by
  ~0.3 ppm*, so no single constant corrects it. (The exact 0.000 ± 0.002 for 1958–1969 is
  informative: NOAA's early MLO product simply *is* the Scripps record, so those years are
  not an independent check at all.) Using Scripps for **both** stations removes the mixed-
  network bias; what remains is a ~0.07 ppm genuine inter-network disagreement about the
  gradient, which the error model absorbs as uncertainty rather than correcting.
- **Pre-bomb tree-ring ¹⁴C not separately acquired** — Hua's compilation already starts
  1941 and includes the pre-bomb Suess decline, which covers the intended role.

**Representation error:** MLO ≈ NH free troposphere, SPO ≈ SH — comparing station records
to hemispheric-mean boxes incurs representation error, absorbed by the calibrated error
model (§5.2), not ignored.

## 5. Calibration design

### 5.1 Free parameters (draft — ~16)

| Param | Meaning | Draft prior |
|---|---|---|
| β | CO₂ fertilization | U(0.1, 1.0) |
| Q10 | het. respiration T sensitivity | logN, median 2, 90 % CI ~(1.4, 2.9) |
| K_z | ocean interior diffusivity | logN spanning classic box-diffusion values [VERIFY] |
| h_ml | mixed-layer depth | U(50, 120) m |
| k_g | gas-transfer coefficient | logN centered on Wanninkhof global mean [VERIFY] |
| τ_ex | interhemispheric exchange | N(1.3, 0.3) yr [VERIFY] |
| τ_strat | bomb-injection delay | U(0.5, 4) yr |
| P_bomb | total bomb ¹⁴C production | N centered on Naegler & Levin [VERIFY] |
| γ_MEI | ENSO land-flux coefficient | N(0, wide), sign-free |
| L_MEI | ENSO lag | U(0, 12) months |
| A_N, A_S, φ_N, φ_S (+ a₂ terms) | seasonal NEP harmonics | weak / possibly pre-fit (Q2) |
| σ_add, ρ | error model (per data stream) | weak |

Fixed [VERIFY-class]: NPP₀ + hemispheric split, τ_veg, τ_soil, fossil N/S split, all ¹³C
fractionation constants, ocean areas/depth/layering, SST-anomaly scaling of GMST, 4.23 %/°C.

### 5.2 Likelihood

- Monthly CO₂ (MLO, SPO): Gaussian with σ² = σ_instr² + σ_add², **AR(1) residual model**
  (ρ calibrated) so months don't masquerade as independent — otherwise the dense CO₂ series
  would swamp everything and overtighten posteriors.
- Ice core, Δ¹⁴C, δ¹³C: Gaussian at native (sparser) resolution.
- **GCB sinks — double-counting caution:** atmospheric growth is already constrained by the
  CO₂ series, so GCB sink series add *partition* information, not growth information. Use
  GCB S_ocean at stated uncertainty; give S_land inflated uncertainty (soft constraint)
  (flagged question Q1).
- Optional single-number ocean bomb-¹⁴C inventory constraint at its epoch.

### 5.3 Sampler

Adaptive Metropolis (adaptMCMC or custom), 4 chains, convergence gates R̂ < 1.05 and
adequate ESS (computed with the `posterior` package; mind the ESS-maxlag trap from the
Julia world — verify the R estimator's defaults rather than assuming).

### 5.4 Products

- Posterior draws → thinned **ensemble of ~100 parameter sets** shipped with the app.
- Central (posterior median) parameter set for live slider interaction.
- Full calibration report: posterior tables, parameter correlations, residual diagnostics
  per data stream, prior-vs-posterior plots.

### 5.5 Compute

Local Mac, single machine. If pure-R forward model exceeds ~50 ms/run, write the core in
Rcpp with a bit-parity test against the R reference implementation (both stay in-repo).

## 6. Sanity gates (all must pass before headline claims)

Adapted from the standing climate-modeling checklist. **Targets 4–8 below were computed
from the acquired datasets** by `data-raw/build_calibration_data.R` (access date
2026-08-09) — they are data-derived, not recalled. Re-running that script regenerates them.

1. **Conservation:** closed-budget carbon constant to ~1e-10 relative (¹²C, ¹³C; ¹⁴C
   closes including decay + production).
2. **Zero-emissions run** from spinup: no drift in any reservoir or isotope ratio.
3. **Pulse tests (paired):** zero-pulse bit-identical to baseline; sign-flip antisymmetric
   in the linear regime; 2× pulse ≈ 2× response at small size, with departure explained by
   Revelle curvature, not bugs.
4. **Airborne fraction** (GCB 2025): **0.431 over 1959–2024**; by decade 0.35 (1960s),
   0.43 (1970s), 0.47 (1980s), 0.38 (1990s), 0.42 (2000s), 0.45 (2010s), 0.50 (2020s
   partial). Roughly flat with substantial decadal variability — the model must not be
   *smoother* than this.
5. **Bomb curve** (Hua et al. 2022): NH Zone 1 peak **944.6 ‰ at 1963.625**; Zone 2
   905.3 ‰ (1963.625); Zone 3 731.4 ‰ (1964.708); SH Zone 1-2 **660.1 ‰ at 1965.542**;
   SH Zone 3 667.0 ‰ (1964.958). NH Zone 1 post-peak e-folding **15.4 yr**
   (log-linear fit over Δ¹⁴C > 20 ‰). The ~1.9 yr NH→SH peak lag and the ~285 ‰
   peak-height difference are the interhemispheric-exchange constraint.

   **Do not gate the model on the Zone 1 numbers.** The model carries one
   *area-weighted hemispheric* box, so its `d14c_NH` is not comparable to a single
   high-latitude zone — Zone 1 peaks earlier and ~110 ‰ higher than the hemispheric
   aggregate. The comparable benchmark, computed from the same `obs_d14c_zonal.rds` with
   `ccx_zone_weights()`, is **NH 853.2 ‰ at 1963.708, SH 659.4 ‰ at 1965.042, NH→SH lag
   1.33 yr**. Using the Zone 1 gate instead flattered the superseded bomb shape, whose
   996.9 ‰ peak in fact exceeded *every* observed zone.
6. **Seasonal cycle** (MLO, peak-to-trough of the mean seasonal cycle by decade):
   **5.95 (1960s) → 6.17 → 6.40 → 6.42 → 6.38 → 6.86 (2010s) → 6.66 ppm (2020s partial)**.
   Amplitude growth of ~15 % across the record is a *fertilization* signature the model
   must produce, not prescribe.
7. **Sinks** (GCB 2025, 2015–2024 mean): **ocean 3.22 GtC/yr, land 2.36 GtC/yr** — model
   must land within GCB stated uncertainty.
8. **δ¹³C Suess:** preindustrial **−6.469 ‰** (Law Dome spline, 1745–1755 mean) →
   **−8.700 ‰** (Scripps MLO, 2024) / **−8.580 ‰** (Scripps SPO, 2024); MLO starts
   −7.600 ‰ (1980), SPO −7.490 ‰ (1977). Preindustrial CO₂ from the same Law Dome source
   is **276.88 ppm** (1745–1755 mean) — this is the spinup target.
9. **MLO − SPO gradient**, both stations on the Scripps 2012 SIO scale, **SEASONALLY
   ADJUSTED**, by decade (paired months in brackets): **0.47 [8] (1950s) → 0.85 [75] →
   1.66 [113] → 1.96 [117] → 2.32 [118] → 2.72 [115] → 3.66 [117] → 3.97 ppm [45]
   (2020s partial)**. Growth from ~0.5 to ~4 ppm tracks cumulative NH fossil emissions;
   with the bomb-spike NH→SH lag this is the main constraint on τ_ex, and a headline app
   figure. Two traps, both live:
   - **Seasonal adjustment is mandatory, not cosmetic.** MLO's ~6 ppm seasonal cycle
     against SPO's ~1 ppm means uneven month coverage aliases seasonality into the
     "gradient". Raw monthly means shift the 1950s by −0.77 ppm (to a spurious *negative*
     gradient), the 1960s by +0.20 and the 2020s by +0.13, while well-covered decades move
     ≤0.03 ppm. Always compute this from the seasonally adjusted series.
   - The 1950s entry rests on 8 paired months: indicative only.
10. **Natural ocean Δ¹⁴C profile:** deep-ocean depletion in the observed range (free check).
11. **Suspicious-uniformity screen** on all residual series (all-same-sign or
    exactly-linear residuals = bug signal, per standing discipline).

## 7. Shiny app design

Public, shinyapps.io. Precompute posterior-ensemble ribbons for historical + preset
scenarios; run central-parameter model live for sliders/toggles/pulses (fast by §3.7).

Tabs (working names, undergrad-facing):

1. **The Keeling Curve** *(default)* — model vs MLO/SPO obs, zoomable; seasonal-cycle
   explainer; hemisphere toggle. Takeaway line: the model reproduces 65+ years of
   measurements from emissions alone.
2. **Where does the carbon go?** — stacked partition of cumulative and annual emissions
   into atmosphere/land/ocean; airborne fraction; live stock readouts (atm GtC, ocean DIC,
   land pools); GCB comparison bars.
3. **What if…?** — counterfactual toggles, each a one-click model rerun: no CO₂
   fertilization / no ENSO / frozen Revelle factor / no ocean sink / no land sink / no
   warming feedback. Each toggle gets a one-sentence "what this switch means".
4. **Isotope fingerprints** — δ¹³C Suess panel and Δ¹⁴C bomb panel ("how we know it's
   fossil carbon"); bomb-spike NH→SH propagation animation; Suess dilution vs nuclear-test
   history overlay.
5. **Futures** — scenario picker: **SSPs** (SSP1-1.9, SSP1-2.6, SSP2-4.5, SSP3-7.0,
   SSP5-8.5) and **stylized** (constant-today, linear-to-zero-by-year-X slider, ±r %/yr),
   plus **pulse lab**: choose background scenario, pulse size (default 100 GtC? — sized so
   effects are visible; final size TBD) and year → paired baseline/pulse runs, showing the
   pulse-decay curve, "how much is left after N years", and how the answer *depends on the
   background* (Revelle saturation). This is the pulse-matched-with-baseline requirement.
6. **Under the hood** — box diagram with live fluxes, parameter table with posterior
   ranges, data sources, model caveats, link to repo.

Uncertainty display: posterior ribbons on historical + preset scenarios (precomputed);
central line only for live interactions, with a note.

## 8. Repo layout

```
CarbonCycleEmulator/
├── README.md            public-facing description
├── DESIGN.md            this file (authoritative spec)
├── CHANGELOG.md         project log incl. abandoned approaches
├── CLAUDE.md            session context for Claude Code
├── data-raw/            download scripts (URL + access date + checksum) & raw files
│   └── constants.R      every [VERIFY] number, with citation, single source of truth
├── data/                processed calibration inputs (.rds, versioned)
├── R/                   model core, forcings, likelihood, utilities
├── calibration/         MCMC drivers, posterior outputs, calibration report
├── app/                 Shiny application
└── tests/               testthat: conservation, sanity gates, (bit-parity if Rcpp)
```

Conventions inherited from global CLAUDE.md: labels derive from named constants; output
provenance stamps; commit per unit of work; quarantine-don't-delete for bugged outputs.

## 9. Open questions for Marcus (blocking only where noted)

- **Q1.** GCB land sink as *soft* constraint (inflated σ) with ocean sink at stated
  uncertainty — agreed? (Non-blocking; default = yes.)
- **Q2.** Seasonal NEP harmonics: joint-calibrate with everything else, or pre-fit to the
  mean seasonal cycle and freeze? (Non-blocking; default = joint, freeze if it slows mixing.)
- **Q3.** SSP emissions: reuse the RCMIP-format CSVs already in your FaIR world for
  consistency across projects? (Non-blocking; default = yes.)
- **Q4.** Rcpp core acceptable within "R end-to-end" if pure R misses the 50 ms target?
  (Non-blocking; default = yes, with bit-parity test.)

## 10. v2 backlog (explicitly out of v1)

Solar-modulated cosmogenic ¹⁴C production; explicit
stratosphere boxes (if τ_strat kernel proves inadequate); volcanic/Pinatubo diffuse-light
term; time-varying fossil δ¹³C fuel mix; ocean advective overturning loop; user-drawn
emissions in the app; N₂O/CH₄; permafrost.
