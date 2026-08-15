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
5. **Teach the two quantities people most often merge (added 2026-08-13, Marcus).**
   The project's original motivation was never written into this list, and it is a
   specification, not a mood: the app should leave a user able to distinguish
   **(a) turnover time from adjustment time**, and **(b) what makes CO₂ *wobble* from what
   makes it *rise*.** Both are things this model is unusually well placed to teach, because
   it produces both halves of each pair from one run — ¹⁴C gives the turnover time
   (~4.7 yr) while a mass pulse gives the adjustment time, and the ENSO term reproduces the
   real interannual temperature–CO₂ correlation while the emissions drive the trend.
   **The framing is positive: the app teaches the distinction, it does not campaign against
   people who miss it** (Marcus, 2026-08-13). §7 tabs 4 and 5, with §7a as a short
   signposting appendix.

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
  decremented from C_wood (carries that pool's own isotopic signature — a transfer, not a
  source, so no ¹⁴C is created; Marcus 2026-08-12).
- **Converted land — the debit is PERMANENT (added 2026-08-13).** Cumulative land-use
  carbon defines a cleared fraction `c(t) = f_luc_perm · cumLUC(t) / land0`, where `land0`
  is *total* preindustrial land carbon (all four pools). NPP₀ and veg₀ are both scaled by
  `(1 − c)`, so every land pool's equilibrium falls and the land's equilibrium carbon drops
  by exactly the carbon land-use change removed.
  **Why the spec needs this:** without it the debited pool relaxes back to a fixed point
  that does not know a forest became a field, and **land-use emissions had an airborne
  fraction of 0.002 at 100 years** against 0.262 for a fossil emission — the model regrew
  what GCB's *net* E_LUC has already subtracted, adding a second, unbudgeted land sink on
  top of the β-fertilization one that stands for S_LAND. Measured in
  `calibration/diag_1900_deficit.R`; gated by `tests/testthat/test-luc-permanence.R`.
  `f_luc_perm = 1` (the mass-consistent point) is the default and is **not** in
  `CCX_PARAM_TABLE`; `f_luc_perm = 0` reproduces the 2026-08-12–13 behaviour and exists so
  the regression stays measurable.
  **Known residual, measured not assumed:** the debit lands on wood (37 yr) while the
  equilibrium reduction is pro rata across pools, 70 % of it in a 500-yr passive soil. So
  the LUC airborne fraction is ~0.5× the fossil one at 100 yr, rising afterwards, and is
  exactly 1× in the infinite-time limit (verified at `tau_soil_slow = 20`). Closing the
  remainder means debiting the pools *pro rata*, which trades against the 2026-08-12 call
  that the emitted carbon carries wood's lagged ¹⁴C — **an open decision, not a defect.**

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

  > **SUPERSEDED — this bullet describes neither the estimator nor the error model in use.**
  > `R/likelihood.R` and `CCX_PARAM_TABLE` are authoritative; §5.1's "draft — ~16" table is
  > likewise a design-stage sketch and is not maintained. Two corrections, both dated:
  > **(a) 2026-08-11 — ρ RETIRED, and the series are no longer scored monthly.** The AR(1)
  > model was correct arithmetic on a wrong premise: as ρ→1 the fitted σ collapses to the RMS
  > of residual *increments* and the level goes unpenalised (σ_co2 fell to 0.074 ppm while a
  > +50 ppm level bias cost 13.7 log-units). It was also applied on observation *index*, so a
  > 16-month SPO gap counted as one step. Replaced by an **annual reduction** — per-station,
  > per-year level/trend/first-harmonic via `ccx_year_harmonic()` — scored with **independent**
  > Gaussian errors, with the discarded seasonal cycle restored as its own explicit stream.
  > That, not ρ, is what stops months masquerading as independent.
  > **(b) 2026-08-15 — σ_add RETIRED for CO₂ (review item 6b).** There is no free error scale
  > on the CO₂ level stream. Its sd is the single fixed constant `LIK_CO2_REP_ERR` = 1.0 ppm.
  > A free scale on the stream that outvotes the partition terms 40:1 is self-weighting — the
  > better CO₂ fitted, the louder CO₂ got — and that feedback, not the identifiability claims
  > that were made and did not survive measurement, is why it went. `sigma_d13c` and
  > `sigma_d14c` remain free; the argument is specific to the dominant stream.
  > See `calibration/diag_sigma_co2.R` and the 2026-08-15 CHANGELOG entries.
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
   must land within GCB stated uncertainty (GCB 2025 stated 1σ: land ±0.5, ocean ±0.4).
   **Status at default parameters (2026-08-14, saturating form at `fert_k` 120): STILL
   FAILING, land +2.28σ (3.50 GtC/yr), ocean −1.52σ (2.61).** Down from +4.57σ / −2.13σ
   under the log form at β 0.75, so the flip halved the land miss without closing it.
   The land sink is compared GROSS — the model's d(land_C)/dt **plus E_LUC** — because
   GCB's `land_sink` column is the residual sink alone; conflating the two inverted this
   term's pull on fertilisation for months (see `R/likelihood.R`, the GCB block).
   `calibration/diag_fert_saturating.R` §3. **Re-measure on any fertilisation or
   `luc_scale` default change.** Note `luc_scale` does NOT close the remaining gap under
   the saturating form — it makes it slightly worse while blowing up the CO₂ bias.
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

   **No longer a free check — SCORED since 2026-08-15 (review item 5).** Likelihood streams
   `co2_gradient` and `d13c_gradient`, on the annual paired MLO−SPO differences of
   `ccx_year_harmonic()` levels. The estimator question is settled by measurement, not
   assertion: those decadal means reproduce the table above to **≤ 0.02 ppm** on every decade
   it covers, and the 9-month annual minimum drops the 1950s entry outright — which is what
   this gate's own note asks for. Both traps above are therefore handled by construction, not
   by a special case. `calibration/diag_gradient_terms.R` part 1.

   **Each term carries a calibrated offset, and that is the load-bearing decision.** A two-box
   model's NH-box − SH-box is *not* what MLO − SPO measures: MLO sits at 19.5 °N, south of the
   northern source region, so the station gradient must come out **smaller** than the box
   gradient. Measured by regressing obs ~ a + b·model, the intercept is **−0.39 ppm** at
   defaults and **−0.55** at the 18-parameter mode — stable, rejected from zero at 95 %, and
   with the sign the physics predicts. Scoring the level against a fixed zero offset would push
   that representation constant onto **τ_ex** and the hemispheric shares and report it as a
   calibrated exchange time. Parameters `grad_off_co2` (prior N(0, 0.5) ppm) and
   `grad_off_d13c` (N(0, 0.15 ‰)) estimate it instead — the same move `luc_scale` makes for
   E_LUC uncertainty.

   **σ = the measured model-vs-obs scatter about a constant offset, floored by the
   observations' own precision.** CO₂ **0.35 ppm** (scatter 0.27–0.28; floor: Scripps vs NOAA
   disagree by 0.225 ppm RMS on the annual gradient, itself a *lower* bound because `MLO` and
   `MLO_NOAA` in this repo are one series under two names at 0.002 ppm RMS). δ¹³C **0.025 ‰**
   (scatter 0.0196–0.0198; floor 0.0152, and that one *is* a genuine two-station two-network
   comparison). `test-gradient.R` recomputes both floors from the data and fails if either σ is
   tightened below them.

   **The two species are NOT the same finding.** For CO₂ both the intercept and the slope are
   rejected — a representation offset *plus* a real shape error (b = 0.845 at defaults,
   1.14–1.23 at the mode, i.e. the miss changes sign across the record). For δ¹³C **b = 1 is
   admissible in all four fits** and only the +0.10 ‰ intercept is rejected: a pure offset. And
   it is 8× larger than the station-latitude argument predicts (which gives 0.013 ‰ by scaling
   CO₂'s 19 %), so `grad_off_d13c` is absorbing the **structural** δ¹³C misfit, not a
   representation constant — the δ¹³C gradient term contributes *shape*, not level. Do not read
   a fitted `grad_off_d13c` as a representation estimate.

   **Status:** the term supplies information the rest of the objective did not have — per prior
   sd of τ_ex it is worth **+193 / −643 log-units** at σ = 0.35, against τ_ex's whole prior
   leverage of ~350, and **with the opposite sign** to what the rest of the objective wanted
   (−207 / +105). DESIGN's claim that this gate constrains τ_ex is true for the first time.
   **Re-measure the gradient on any change to the hemispheric shares, τ_ex, or `LIK_CO2_REP_ERR`.**
   *(σ_co2 was the third item until 2026-08-15, when it was retired; the re-measurement it
   called for was done at that point — the implied gradient sd goes 1.449 → 1.414 ppm and the
   double-count ratio 17.1× → 16.3×, so **adding** a term rather than **rotating** (MLO, SPO)
   remains correct. `LIK_CO2_REP_ERR` is now the only input to that ratio, and
   `test-gradient.R` case 6 gates it.)*
10. **Natural ocean Δ¹⁴C profile:** deep-ocean depletion in the observed range. **No longer
    a free check — sourced and scored since 2026-08-14.** GLODAPv2.2023 over the model's own
    bottom box (2627–3700 m), cos(lat)-and-thickness weighted: **−175.3 ‰**, σ **10.3 ‰**
    (= the 45.9 ‰ spatial spread ÷ √n_eff, n_eff = 20 — deep water masses are basin-coherent,
    so the spread is *not* the sigma). It is likelihood stream `d14c_deep_ocean`. Score
    `diagnostics$d14c_bottom_box`, **not** `d14c_deep_ocean`/`d14c_deep_by_hemi`, which are
    the bottom *three* boxes (1314–3700 m) and run 13–20 ‰ enriched. The `kz` bracket is
    retained alongside it: on this same quantity the bracket is a hard box of half-width
    28.4 ‰, tighter than the σ, so deleting it would loosen `kz` rather than tighten it.
    `calibration/diag_deep_d14c_term.R`.
11. **Suspicious-uniformity screen** on all residual series (all-same-sign or
    exactly-linear residuals = bug signal, per standing discipline).
12. **CO₂ pulse response (IRF)** — **added 2026-08-13**, and it closes a hole: gates 1–11
    score sinks, seasonality, the bomb curve and the interhemispheric gradient, but
    **nothing scored the pulse response**, which is the quantity the app's flagship
    "How long does it last?" panel reports. Benchmark: **Joos et al. (2013)**, *Carbon
    dioxide and climate impulse response functions…*, ACP 13:2793–2825,
    doi:10.5194/acp-13-2793-2013 — 15 models + 3 ensembles, PD100 protocol (100 GtC onto a
    background **held** at 389 ppm; compatible emissions diagnosed).
    **Time-integrated IRF must lie inside Joos Table 4's 5–95 % range**:
    **12.2–16.3 yr (TH 20), 24.0–36.6 (50), 39.5–65.2 (100)**; multi-model best estimates
    14.2 / 30.3 / 52.4. Point IRF from the Table 5 fit
    (a₀ 0.2173; aᵢ 0.2240/0.2824/0.2763; τᵢ 394.4/36.54/4.304 yr) is
    0.596 / 0.487 / 0.409 / 0.322 at 20 / 50 / 100 / 300 yr.
    **Secondary, and a Revelle check rather than a tuning target:** Joos §4.4.1 gives
    integrated IRF at TH 100 of **34–47 yr on a preindustrial background against 45–62 on
    present-day**; the model must reproduce the **PI < PD ordering**.
    `calibration/diag_joos_irf.R` (~40 s). **Status at default parameters (2026-08-14, the
    saturating fertilisation form at `fert_k` 120 / `beta_max` 0.4913): PASSES — 12.4 / 25.6
    / 41.9 yr, inside at all three horizons with margin.** Still below the best estimate at
    every one, so the model remains on the low side of the literature — the *conservative*
    direction for the app's argument, which must be stated rather than discovered by a reader.

    **History, because this gate's recorded status was stale twice and that is what made the
    failure invisible.** The 12.6 / 26.2 / 43.6 recorded here until 2026-08-14 was measured at
    β 0.38, two re-centrings before the default reached β 0.75 — at which the gate FAILED at
    all three horizons (10.4 / 19.9 / 31.2), undetected, because the status line was never
    re-measured. `calibration/diag_joos_beta_scan.R` established that the log form passes only
    at β ≲ 0.50 while the CO₂ record wants 0.75, which is the structural defect review §4.1
    diagnosed and item 7 fixed by replacing the functional form. **Re-measure this line
    whenever a fertilisation default moves; it is not a description, it is a measurement.**
    **The background protocol is not a detail:** held-vs-decaying is worth 2 yr of
    integrated IRF and PI-vs-PD is worth 7, both larger than any structural question
    currently open (see the expert-panel note, §2).

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
5. **How long does it last?** *(added 2026-08-13; this is the tab the project exists for)*
   Teaches turnover vs adjustment, positively and from measurements. Three panels:
   - **Two curves, one model.** A 100 GtC mass pulse and a pure ¹⁴C *label* pulse released
     from the same state with the same parameters. Takeaway: *both are true; they answer
     different questions.* Readouts: **turnover ~4.7 yr** ("how long an average molecule
     stays") beside **adjustment** ("how long the added amount stays" — ~26 % airborne at
     100 yr). Numbers from `calibration/diag_pedagogy.R`.
   - **It already happened.** The observed bomb-¹⁴C spike beside the observed Keeling
     curve — *measurements, not model*: the label went away in decades, the CO₂ did not.
   - **It depends on the world you put it in.** Background slider (preindustrial / today /
     SSP): the same pulse lasts longer in a fuller ocean. This is Revelle buffering made
     visible, and it is the largest single sensitivity in the whole model (§6 gate 12).
   Uses the flux trace (`R/fluxes.R`) for the turnover readout.

6. **What drives CO₂?** *(added 2026-08-13)* Teaches attribution by letting the user take
   the machine apart, in a fixed order so the lesson lands:
   *(i)* the interannual wobble and its correlation with temperature — **real, r ≈ 0.93 on
   growth rate, and the model reproduces it**; *(ii)* the same series with both trends
   removed — **r ≈ 0.58, and it is ENSO**; *(iii)* switch the carbon cycle's response to
   warming off — the trend barely moves; *(iv)* switch emissions off — the trend goes.
   Closes on δ¹³C: a warming-driven release would move δ¹³C by **+0.04 ‰** (ocean limb
   *up*), against an observed **−1.77 ‰**. Needs **a new "no emissions" switch in
   `CCX_MECHANISMS`** (two lines; the list currently lets a user turn off every *sink* but
   not the *source*).

7. **Futures** — scenario picker: **SSPs** (SSP1-1.9, SSP1-2.6, SSP2-4.5, SSP3-7.0,
   SSP5-8.5) and **stylized** (constant-today, linear-to-zero-by-year-X slider, ±r %/yr),
   plus **pulse lab**: choose background scenario, pulse size (default 100 GtC? — sized so
   effects are visible; final size TBD) and year → paired baseline/pulse runs, showing the
   pulse-decay curve, "how much is left after N years", and how the answer *depends on the
   background* (Revelle saturation). This is the pulse-matched-with-baseline requirement.
8. **Under the hood** — box diagram **with its arrows labelled by the model's own flux
   trace** (`R/fluxes.R`; ~70 GtC/yr photosynthesis and ~95 each way air–sea against ~11 of
   emissions — the arrows *are* the residence-time lesson), parameter table with posterior
   ranges, data sources, model caveats, link to repo.

### 7a. "Claims you may meet" — a short signposting appendix, NOT a tab of its own

**Marcus, 2026-08-13: keep the app on the positive learning; a brief summary of the
arguments, with links, can sit at the end.** So this is an appendix inside tab 8, not a
sixth headline tab, and it is written as *published claim → published response → which
panel of this app bears on it*. It names arguments and their sources; it does not
characterise the people making them. **The wording is Marcus' call before this ships.**

| claim, as published | published response | panel |
|---|---|---|
| Essenhigh RE (2009), *Potential Dependence of Global Warming on the Residence Time…*, **Energy & Fuels 23:2773–2784, doi:10.1021/ef800581r** — a 5–15 yr residence time means the rise is not anthropogenic | **Cawley GC (2011), Energy & Fuels 25:5503–5513, doi:10.1021/ef200914u** — shows the *same one-box model* yields residence ≈4 yr **and** adjustment ≈74 yr simultaneously | tab 5 |
| Harde H (2017), *Scrutinizing the carbon cycle and CO₂ residence time in the atmosphere*, **Global and Planetary Change 152:19–26, doi:10.1016/j.gloplacha.2017.02.009** — ~4 yr residence time, ~4.3 % of today's CO₂ anthropogenic | **Köhler P et al. (2018), GPC 164:67–71, doi:10.1016/j.gloplacha.2017.09.015** — a single-reservoir equation cannot represent the carbon cycle; two reservoirs solved simultaneously is the minimum | tabs 5, 6 |
| Salby M — presentations arguing the rise is temperature-driven (no peer-reviewed version; see e.g. judithcurry.com/2016/08/10/murry-salbys-latest-presentation/) | — | tab 6 |
| Spencer R — blog CO₂ budget regressions (drroyspencer.com/2023/04/co2-budget-model-update-through-2022-humans-keep-emitting-nature-keeps-removing/) | — | tab 6 |

**Cawley (2011) is the anchor for tab 5 and should be cited there**: its whole point is that
a short residence time and a long adjustment time are not in tension but are *both
consequences of the same model* — which is exactly what this model's paired ¹⁴C-label and
mass pulses show, independently and with a real ocean underneath.

**Spencer's is the subtle one and deserves its own sentence** (Marcus, 2026-08-13): the
regression is not wrong arithmetic, it is a **fixed-equilibrium assumption** — treating the
level nature relaxes toward as constant, when it *rises as carbon is added*. The app can
show this directly, because the model's equilibrium point is not a parameter: it emerges
from carbonate chemistry, and the "frozen Revelle" switch already isolates it.

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
