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
  - **Bomb source:** prescribed test-yield time history shape, total production P_bomb
    [CAL] with prior from Naegler & Levin (2006) [VERIFY], injected into the NH (and small
    SH share [VERIFY]) troposphere through the τ_strat delay kernel.
  - **Fossil fuel:** ¹⁴C-free by definition → Suess dilution emerges.
  - Nuclear-industry ¹⁴C source: omitted in v1 (small), v2 (§10).

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

| Dataset | Role | Source (to be pinned in data-raw) |
|---|---|---|
| Mauna Loa monthly CO₂ (1958+) | dense NH target | NOAA GML co2_mm_mlo (or Scripps — pick one, document) |
| South Pole monthly CO₂ (1957+) | dense SH target | Scripps SPO record |
| Law Dome ice core + firn CO₂ | sparse 1750–1960 target | Rubino et al. 2019 dataset |
| Zonal atmospheric Δ¹⁴C, monthly 1950–2019 | bomb-era target, both hemispheres | Hua et al. 2022 compilation (NH zones averaged for N box; SH zones for S box) |
| Pre-bomb atmospheric ¹⁴C (Suess decline) | 1900–1950 target | tree-ring records / IntCal20 |
| δ¹³C flasks MLO + SPO (1977+) | Suess partition target | Scripps CO₂ program |
| δ¹³C ice/firn | sparse pre-1977 target | Rubino et al. 2019 |
| GCB annual ocean sink + uncertainty (1959+) | partition constraint | GCB latest release tables |
| GCB annual land sink | *soft* partition constraint (§5.2) | GCB latest release tables |
| Ocean bomb-¹⁴C inventory (single epoch) | optional integral constraint | GLODAP-era estimates (Key et al. 2004 / Peacock 2004) [VERIFY] |

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

Adapted from the standing climate-modeling checklist; numbers below are *expectations to
be replaced by values read from the actual datasets*, not memory:

1. **Conservation:** closed-budget carbon constant to ~1e-10 relative (¹²C, ¹³C; ¹⁴C
   closes including decay + production).
2. **Zero-emissions run** from spinup: no drift in any reservoir or isotope ratio.
3. **Pulse tests (paired):** zero-pulse bit-identical to baseline; sign-flip antisymmetric
   in the linear regime; 2× pulse ≈ 2× response at small size, with departure explained by
   Revelle curvature, not bugs.
4. **Airborne fraction** ≈ mid-0.40s, roughly flat over recent decades (vs GCB).
5. **Bomb curve:** NH tropospheric Δ¹⁴C peak location/height (~1963–64, order 1000 ‰) and
   post-peak e-folding (~16 yr [VERIFY]) vs Hua data; NH−SH gap closing timescale.
6. **Seasonal cycle:** MLO amplitude ~6–7 ppm peak-to-peak, SPO ~1 ppm and phase-shifted
   [VERIFY from data]; amplitude *growth* qualitatively present.
7. **Sinks:** recent-decade land and ocean sinks within GCB stated uncertainty.
8. **δ¹³C Suess:** ~−6.4 ‰ → ~−8.5 ‰ trajectory [VERIFY from data].
9. **Natural ocean Δ¹⁴C profile:** deep-ocean depletion in the observed range (free check).
10. **Suspicious-uniformity screen** on all residual series (all-same-sign or
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

Solar-modulated cosmogenic ¹⁴C production; nuclear-industry ¹⁴C source; explicit
stratosphere boxes (if τ_strat kernel proves inadequate); volcanic/Pinatubo diffuse-light
term; time-varying fossil δ¹³C fuel mix; ocean advective overturning loop; user-drawn
emissions in the app; N₂O/CH₄; permafrost.
