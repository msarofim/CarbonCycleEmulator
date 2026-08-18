# CHANGELOG — CarbonCycleEmulator

Project log: what was done, what was tried and abandoned, and why.

## 2026-08-09 — Project created; design locked (no code yet)

- Repo created as a sibling of FaIRtoFrEDI (design conversation ran from a FaIRtoFrEDI
  session; this project is independent of that pipeline).
- Core design decisions made by Marcus:
  - **R end-to-end** (model + MCMC + Shiny), Rcpp core only if speed demands it.
  - **Box-diffusion ocean** (Oeschger-style column per hemisphere) over discrete-box and
    HILDA alternatives — bomb-¹⁴C penetration is the key ventilation constraint.
  - **¹²C + ¹³C + ¹⁴C** — δ¹³C added for the Suess land/ocean partition constraint;
    Δ¹⁴C fractionation-corrected data lets ¹⁴C run without fractionation bookkeeping.
  - **App = historical + scenarios**: counterfactual toggles, SSPs, stylized pathways, and
    matched pulse/baseline experiments. Public deployment on shinyapps.io.
  - **Audience: undergrad environmental-studies major.**
- Alternatives considered and set aside (with reasons) are recorded in DESIGN.md §2 and
  the v2 backlog (§10): discrete-box ocean (weaker use of bomb spike), HILDA (too many
  parameters to communicate), Python-calibrate/R-port (port-parity risk), Julia+Shiny
  bridge (deployment fragility on shinyapps.io), user-drawn emissions (deferred).
- DESIGN.md written; awaiting Marcus sign-off before any model code.

## 2026-08-09 (later) — Design approved; data layer built

Marcus took the defaults on all four open questions (§9): GCB land sink as a soft
constraint, joint-calibrated seasonal harmonics, reuse of RCMIP SSP CSVs, Rcpp core
permitted with a bit-parity test.

**Acquired 14 datasets** (`data-raw/download_data.R` → `MANIFEST.csv` with URL, access
date, SHA-256, citation; parsed by `data-raw/build_calibration_data.R` → `data/*.rds`).

**Source substitutions forced by upstream availability — all flagged, none silent:**

- **Scripps CO₂ Program is unreachable.** Every `scrippsco2.ucsd.edu/assets/...` path
  returns 404 (tested with and without a browser user-agent; search engines still index
  the old URLs). Consequences: South Pole CO₂ comes from the NOAA CCGG flask record and
  therefore **starts 1975 instead of 1957**, and Scripps δ¹³C (1977+) is unavailable.
  *Not treated as fixed* — revisit; the 1957–1975 SH gap is a real loss for the bomb era.
- **δ¹³C is thinner than planned.** NOAA/INSTAAR monthly flask δ¹³C runs **1990–2014
  only** (MLO; SPO 1993–2014). With Law Dome ending 1993 there is no δ¹³C constraint
  after 2014. The Suess sink-partition constraint is correspondingly weaker; the post-2014
  gap must not be read as agreement.
- **MEI.ext has been retired by NOAA PSL** (404), so the planned MEIv2 + MEI.ext splice is
  impossible. Both MEIv2 (1979+) and Niño 3.4 (1948+, anomalized against a 1991–2020
  climatology) were acquired. **Choice of which drives the ENSO term is deferred to
  Marcus** — Niño 3.4 is the only option covering the full dense-CO₂ era in one product.
- **Law Dome δ¹³C lives in a separate NCEI file** (`law2018d13c-co2.txt`), and the spline
  composite (`law2018splines.txt`) provides smooth annual CO₂ (154–1996 CE) and δ¹³C
  (1020–1993 CE) series — better pre-instrumental targets than the raw sample list.
  Parser gotcha: that file has **two different columns both named `age_CO2`** (CO₂ and
  δ¹³C splines are on different time axes), so it must be parsed positionally.
- **Hua et al. (2022) Δ¹⁴C obtained via `SoilR::Hua2021`** — the package ships the paper's
  Supplementary Material 2 (5 zones, monthly mean + sd, 1941–2019), which avoids a
  publisher-supplementary download and fits the R-end-to-end constraint.

**Sanity-gate targets are now data-derived, replacing recalled values in DESIGN.md §6.**
Where they differ from the working values written at design time, the data wins:
NH Zone 1 bomb peak is **944.6 ‰ at 1963.625** (design said "order 1000 ‰"); post-peak
e-folding **15.4 yr** (design said ~16); airborne fraction **0.431** over 1959–2024
(design said "mid-0.40s"); preindustrial CO₂ **276.88 ppm** and δ¹³C **−6.469 ‰**.
MLO seasonal amplitude grows 5.95 → 6.86 ppm (1960s → 2010s), and the MLO−SPO gradient
grows 1.70 → 4.36 ppm (1970s → 2020s).

**Still outstanding:** bomb ¹⁴C production history (atmospheric test-yield series) and the
optional ocean bomb-¹⁴C inventory constraint.

## 2026-08-09 (later still) — Carbonate chemistry module

`R/carbonate.R` + `data-raw/build_carbonate_tables.R` + `tests/testthat/test-carbonate.R`.

**Approach:** dissociation constants are NOT hand-copied from papers. `seacarb` (a
maintained, cited implementation) is queried over the model's temperature range and
polynomials in T are fitted to ln K0/K1/K2/Kb/Kw. seacarb is the cited authority; the
fitted coefficients are a reproducible derivative; the test suite gates the fast solver
against seacarb's full system. The solver itself is a closed-form carbonate-alkalinity
quadratic seed plus Newton refinement — pure arithmetic, so it ports to Rcpp unchanged.

**Final accuracy vs seacarb:** pCO₂ to **2.2e-5** relative, Revelle factor to **1.3e-6**,
over DIC 1900–2400 µmol/kg × T 10–30 °C. Test tolerances set at 1e-4 (≈5× and ≈75×
headroom) so a real regression trips them.

**Three bugs found and fixed by the seacarb gate — each would have survived a plausibility
check.** Recorded because all three are the "looks fine, is wrong" class:

1. **Missing OH⁻ in the alkalinity balance → −4.5 % in pCO₂.** The water term is only
   ~0.25 % of total alkalinity, but pCO₂ amplifies an alkalinity error by roughly the
   Revelle factor (~10×). Do not "simplify" it away.
2. **[CO2*]/K0 is fugacity fCO₂, not partial pressure pCO₂** — a systematic −0.30 to
   −0.38 % bias, temperature-dependent. Fixed by storing an effective
   K0_eff = K0 × φ(T), with φ = 0.99572 (2 °C) … 0.99717 (35 °C) taken from seacarb.
   This one matters because it biases the air–sea gradient and hence the ocean sink in
   one direction at all times.
3. **Polynomial fits in raw T are badly conditioned** once T⁵ ~ 5e7; fitting in centred,
   scaled x = (T−T₀)/Ts improved K0/K1/K2/Kb from ~1e-7 to ~1e-9. The scaling is stored
   with the coefficients, and evaluation always applies it.

**Not a bug — a wrong test.** The Revelle factor is *not* monotonic in DIC all the way up:
it peaks near DIC ≈ 2250 µmol/kg (at ALK 2300) and falls beyond, because carbonate ion is
nearly exhausted at pH ~7.1. seacarb reproduces the turnover identically, so the assertion
was corrected to the DIC < ALK range the model actually visits, rather than the code.

**Kw carries a documented tolerance waiver.** seacarb's own Kw output has a ~1.7e-3
oscillatory wiggle (largest at 2–12 °C) that is unchanged by raising the polynomial degree
to 10 or by using the physical (1/T, lnT, T) basis — i.e. upstream numerical noise, not a
fitting failure. Kw is therefore allowed 5e-3 while the others are held to 1e-6, and the
waiver is gated by a test that perturbs Kw by a full tolerance width and requires the pCO₂
response to stay under 1e-4.

**Also added:** `R/paths.R` (`ccx_root`/`ccx_path`) so scripts, testthat (which runs from
`tests/testthat/`) and the Shiny app (which will run from `app/`) all resolve `data/`
identically; `tests/run_tests.R` as the suite entry point.

## 2026-08-09 (cont.) — Three flagged choices resolved by Marcus

- **ENSO index = Niño 3.4 (1948+)**, anomalized against a 1991–2020 climatology. One
  homogeneous product covering the whole dense-CO₂ era, no splice. MEIv2 stays in `data/`
  as a sensitivity option. (MEI.ext retirement made the original plan impossible.)
- **Δ¹⁴C zone → hemisphere aggregation = AREA-WEIGHTED**, with the zone latitude
  boundaries to be read out of Hua et al. (2022) rather than assumed. Note the tropical
  zone boundaries follow the ITCZ and migrate seasonally — the weighting scheme must state
  how it handles that (fixed annual-mean boundaries is the intended simplification).
- **Bomb ¹⁴C = prescribed yield-history SHAPE with calibrated total P_bomb.** The model
  therefore *predicts* the Δ¹⁴C spike rather than fitting it, keeping ¹⁴C as an
  independent check and preserving the app's isotope narrative. Outstanding dependency:
  a citable annual atmospheric-test-yield series.

## 2026-08-09 (cont.) — Scripps South Pole records supplied; both gaps closed

Marcus supplied the four Scripps South Pole files by hand (the website is still 404
site-wide). They live in **`data-raw/manual/`** and are **committed to git** — unlike
`data-raw/downloads/`, they cannot be regenerated, so losing them loses the data.
`data-raw/manual/README.md` records contents, citation, and the column trap.

**Both previously-flagged gaps are closed:**
- **SH CO₂ now 1957-06 → 2024** (n=711 real monthly values) instead of NOAA's 1975+
  (n=583). This recovers the entire bomb era on the SH side.
- **SH δ¹³C now 1977-03 → 2024** (n=528) instead of NOAA's 1993–2014 (n=258). The
  post-2014 hole is gone and the record extends 16 years further back.
- NOAA's SPO CO₂ and δ¹³C are retained as **independent cross-checks**, not extra
  likelihood terms.

**Column trap, documented in code and README.** The Scripps monthly files have 10 columns;
**only column 5 is a real observation** — columns 7–10 are fit, seasonally-adjusted and
gap-filled reconstructions that are fully populated even where nothing was measured (the
1957 row has CO₂ = NaN but fit = filled = 312.74). Parsing a filled column would have
invented ~100 monthly "observations", including all but 11 of the 36 months in the 1950s,
and would have understated calibration uncertainty. The parser takes column 5 and keeps
the NaNs.

**Scripps SPO Δ¹⁴C (1999–2007, n=81) is VALIDATION ONLY, not a likelihood term.** Its
range (51.9–97.9 ‰) sits on top of Hua et al.'s SHZone1-2 over the same window
(53–95.9 ‰) because this station is one of the records feeding that compilation. Using
both would double-count the same measurements. Saved to
`data/obs_d14c_spo_validation.rds` for checking the zonal aggregation independently.

**New finding — inter-network scale offset.** Over 543 months where both networks report
at South Pole, **Scripps − NOAA = −0.134 ± 0.262 ppm** (2012 SIO manometric vs WMO scale).
Because MLO is NOAA and SPO is Scripps, this offset lands directly inside the MLO−SPO
gradient — 3–8 % of a gradient that is a primary constraint on τ_ex. **Open item:** obtain
Scripps *Mauna Loa* records so both stations share one scale, or carry a calibrated
network-offset nuisance parameter. Not silently absorbed.

**Updated data-derived benchmark — the interhemispheric gradient now spans the full
record:** 0.04 ppm [9 paired months] (1950s) → 1.05 [75] → 1.65 [113] → 2.31 [117] →
2.61 [118] → 3.09 [115] → 3.83 [117] → 4.38 [45] (2020s partial). It grows from
essentially zero at the start of the record to 4.4 ppm today, tracking cumulative NH
fossil emissions. Earlier decades shifted modestly versus the NOAA-based numbers (1970s
1.70 → 1.65, 2000s 2.74 → 3.09) — mostly different month sampling rather than the scale
offset, so the paired-month estimate above is the reliable one. δ¹³C Suess trajectory
is now −6.469 ‰ (preindustrial) → −8.580 ‰ (2024).

The `daily_flask_co2_isotopes_spo.csv` file (daily CO₂, CH₄, CO, ¹³C, ¹⁸O, ¹⁴C) is
retained as provenance but unused in v1, which is a monthly model.

## 2026-08-10 — Scripps Mauna Loa records added; both stations on one scale

Marcus supplied the MLO counterparts. There is no MLO "merge" file — MLO has a genuine
**in-situ continuous** record (`monthly_in_situ_co2_mlo.csv`, 1958–2026, n=812 real), which
is better than a merge; SPO is flask-dominated, hence its merge product. Also added:
`monthly_flask_c13_mlo.csv` (1980–2024, n=532), `monthly_flask_co2_mlo.csv` (cross-check),
`intermittent_flask_c14_mlo.csv` (2001–2007, validation only — feeds Hua's NH zones).

**Both stations now sit on the 2012 SIO manometric scale (CO₂) and the Scripps isotope
scale (δ¹³C).** NOAA records are retained as cross-checks, not extra likelihood terms.

**Parser trap:** missing-value markers differ *between Scripps files*. The merge and flask
files use `NaN`; `monthly_in_situ_co2_mlo.csv` uses **−99.99**. Left unhandled, −99.99
sails through as a real observation and poisons every mean it touches. Both are handled.

### Finding 1 — the inter-network offset is NOT a constant

Measured where both networks report: Scripps − NOAA = **−0.201 ± 0.217 ppm** at MLO
(n=812) and **−0.134 ± 0.262 ppm** at SPO (n=543). By decade, though, the MLO offset runs
0.000, 0.000, +0.04, −0.36, −0.31, −0.38, −0.17, −0.29 ppm — it **wanders by ~0.3 ppm**,
so no single constant corrects it. SPO behaves similarly (+0.25, −0.22, −0.24, −0.28,
−0.06, +0.06).

The exact **0.000 ± 0.002 ppm for 1958–1969** is itself informative: NOAA's early MLO
product *is* the Scripps record, so those years were never an independent cross-check.
Worth remembering before treating NOAA-vs-Scripps agreement as corroboration anywhere.

Using Scripps for both stations removes the mixed-network bias (which would have been
+0.134 ppm on the gradient). What remains is a ~0.07 ppm genuine disagreement between
networks about the gradient — absorbed by the error model as uncertainty, not corrected.

### Finding 2 — my own gradient benchmark was aliasing the seasonal cycle (BUG, FIXED)

The MLO−SPO gradient was being computed from **raw** monthly means over whatever months
happened to be paired. MLO has a ~6 ppm seasonal cycle against SPO's ~1 ppm, so uneven
month coverage injects seasonality straight into the "gradient". The 1950s were the
extreme case: 8 paired months, 5 of them Aug/Sep (MLO's seasonal minimum), producing a
spurious **negative** gradient of −0.30 ppm — physically backwards, and it had already
been written into DESIGN.md §6 as a data-derived target.

Fixed by computing the gradient from the **seasonally adjusted** column both Scripps
products ship. Effect by decade (raw − adjusted): 1950s **−0.77**, 1960s +0.20,
2020s +0.13, and ≤0.03 ppm for every well-covered decade — i.e. concentrated exactly where
coverage is sparse, as the diagnosis predicted.

**Corrected benchmark, seasonally adjusted, both stations on the Scripps scale:**
0.47 [8 paired months] (1950s) → 0.85 [75] → 1.66 [113] → 1.96 [117] → 2.32 [118] →
2.72 [115] → 3.66 [117] → 3.97 ppm [45] (2020s partial). The 1950s entry remains
indicative only.

δ¹³C Suess trajectory is now two-hemisphere on one isotope scale: −6.469 ‰ (preindustrial,
Law Dome) → −8.700 ‰ (MLO 2024) / −8.580 ‰ (SPO 2024).

## 2026-08-10 — Nuclear-industry ¹⁴C source PROMOTED to v1 (assumption overturned)

Marcus proposed the Bristol/Zenodo compilation of nuclear-industry gaseous ¹⁴C emissions.
It is **not** the bomb source — it covers routine reactor and reprocessing releases — but
checking it against the v1 spec overturned an assumption I had written there.

DESIGN.md §3.5 previously said "Nuclear-industry ¹⁴C source: omitted in v1 (small), v2".
That "small" was never verified. It is wrong in the way that matters.

**Magnitude check.** Summing the annual files (GBq → mol via λ = ln2/5700 yr;
1 GBq = 4.309e-4 mol ¹⁴C): total industry release is **1.165 kmol**, i.e. **1.14 % of the
~102 kmol bomb production** — which is what makes "small" superficially plausible. But the
*time profiles are opposite*. Industry releases grow monotonically —
0.20 → 1.10 → 4.12 → 8.08 → 17.51 → 25.62 → **42.47 mol/yr** by the 2010s — while the bomb
spike decays and is absorbed.

Against a 2010s atmospheric inventory of **86.1 kmol ¹⁴C** (880 GtC at R_std = 1.176e-12 —
note this is comparable to total bomb production, consistent with the bomb roughly doubling
atmospheric ¹⁴C at its ~+900 ‰ peak), 42.5 mol/yr is **+0.49 ‰/yr**. The observed NHZone1
trend over 2005–2019 is **−4.30 ‰/yr**. So the industry source is **~11 % of the modern
observed tendency** — far too large to drop from a model whose whole point is to reproduce
the Δ¹⁴C record.

Two bounding caveats push opposite ways: +0.49 ‰/yr is an **upper** bound (assumes all
released ¹⁴C stays airborne; it actually partitions into ocean and land), while the
emissions sum is a **lower** bound (coverage gaps — USA only 2010–2023, France NPP 2005+).
11 % is the right order of magnitude, not a precise number.

Emissions are almost entirely Northern Hemisphere, so this term also projects onto the
NH−SH Δ¹⁴C difference — the same signal that constrains τ_ex. Added to
`download_data.R` (9 annual files, CC-BY-4.0, doi:10.5281/zenodo.15034663).

**Bomb-source prior now sourced.** Naegler & Levin (2006), *Closing the global radiocarbon
budget 1945–2005*, JGR 111, doi:10.1029/2005JD006758: total bomb ¹⁴C production 1945–1980
= **99.3–104.9 kmol** (598–632 × 10²⁶ atoms). That fixes the prior on the calibrated
P_bomb. **Still outstanding: the time SHAPE** — an annual atmospheric test-yield series
(UNSCEAR 2000 Annex C is the standard compilation).

## 2026-08-10 — Model core: 84-state box model, conservation gates, mutation testing

`R/model.R` (two-hemisphere, monthly, ¹²C/¹³C/¹⁴C), `R/constants.R` (provenance-tagged
constants), `tests/testthat/test-conservation.R`, `tests/testthat/test-constants.R`.
Suite: **120 passing**.

**Conservation by construction, not by accuracy.** Every internal transfer is emitted once
by `add_flux()` and applied with opposite sign to its two boxes, so total carbon has zero
derivative at every RK stage and is conserved to roundoff at *any* step size. Measured:
**2.2e-16** relative drift over a 100-year integration, and identical at 1, 4 and 16
substeps per month — a step-size-*dependent* conservation error would prove the flux form
was broken.

**Tracer scaling.** ¹⁴C is carried as C × (R14/R14_STD), i.e. "GtC carrying standard ¹⁴C
content", so Δ¹⁴C = 1000·(C14/C − 1) falls out directly and state values stay O(1–1000)
rather than O(1e-12). ¹³C carries fractionation on every flux; **¹⁴C deliberately does
not**, because Δ¹⁴C is fractionation-corrected by convention and C14/C *is* that corrected
ratio. Both facts are stated in the file header — the ¹⁴C one is easy to "fix" into a bug.

### Mutation testing found an inert gate (and a real bug)

The suite passed on first run, so the gates were deliberately attacked by mutating the
source and checking the tests fail. Against a 1e-10 threshold and a 2.2e-16 baseline:

| Mutant | Drift | Result |
|---|---|---|
| One-sided diffusive flux | 3.9e-01 | caught |
| Receiver flux +1 % | 3.6e-02 | caught |
| Receiver flux +0.001 % | 3.5e-05 | caught |
| ¹⁴C decay with Libby 5568 yr | **identical to baseline** | **MISSED** |

The flux gates are extremely sensitive — a 0.001 % asymmetry lands eleven orders above
threshold. But the ¹⁴C decay gate was **inert**, and the reason was a genuine bug:
`LAMBDA_C14` was written as the literal `log(2)/5700` while being *labelled* "derived" from
`T_HALF_C14`. It was an independent copy, so changing the half-life left the decay rate
untouched. `MOL_C14_PER_GBq` had the same flaw.

Fixed by defining `.T_HALF_C14`, `.M_C`, `.SEC_PER_YR`, `.AVOGADRO` once at the top and
referencing them — the constants-file analogue of the standing "labels derive from named
constants" rule. The Libby mutant now produces 1.4e-04 against a 4.7e-10 baseline, and
`test-constants.R` asserts each derivation directly so the decoupling cannot return.

**Lesson recorded:** a passing suite says nothing about whether the gates can fail. Mutate
before trusting.

### Performance: pure R is 527× off target, as expected

A 350-year monthly run (4,200 months, 67,200 derivative evaluations) takes **26.4 s**
against the 50 ms target. Pure R stays as the readable *reference implementation*; the
production core goes to Rcpp under the approved Q4 default, with a bit-parity test against
this reference. Known R-side overheads to remove in the port: `ccx_const()` does a string
lookup per flux per stage, `carb_constants()` re-evaluates five polynomials per hemisphere
per stage, and `add_flux()` is a closure using `<<-`.

**Still provisional (8 constants, ledgered in `test-constants.R`):** ocean areas and depth,
surface alkalinity, seawater density, preindustrial NPP, the SST–pCO₂ sensitivity (which
must be checked for double-counting against the carbonate module's own T dependence), and
the 1750 Δ¹⁴C, which is currently **set to 0 by construction** rather than measured.

## 2026-08-10 — Natural ¹⁴C production, IntCal20 background, and a gross-flux physics fix

Marcus asked whether a natural ¹⁴C source and background rate were needed. Both yes, and
answering it exposed a structural bug in the derivative. Suite: **138 passing**.

### Natural production is not optional

Unbalanced decay (λ = 1.216e-4/yr) drifts atmospheric Δ¹⁴C by **−24.0 ‰ over 200 yr** and
**−41.7 ‰ over 350 yr**. The pre-bomb Suess decline the model must reproduce is
**−26.6 ‰** (IntCal20, 1750→1950). Without a cosmogenic source the artefact is *larger
than the signal*.

**It is solved for, not prescribed.** `ccx_spinup()` finds the production rate that holds
atmospheric Δ¹⁴C at its 1750 value in steady state, given the model's own inventory and
ventilation. The canonical cosmogenic estimate (~2.04 atoms/cm²/s ≈ 545 mol ¹⁴C/yr) is
therefore an **independent validation**, not an input. Derived value: **360 mol/yr,
ratio 0.66**. Consistent with the model's ocean inventory (32,827 GtC) sitting ~14 % below
the canonical ~38,000 GtC, plus the published spread in production (1.6–2.5 atoms/cm²/s).
A factor-2 miss would have meant a units bug; 0.66 does not. Gated at 0.5–2.0.

### Background level: IntCal20 replaces a placeholder

`D14C_PI` was **0 by construction**. IntCal20 (via `rintcal`) gives **+2.16 ‰ at 1750** —
the placeholder was wrong by ~8 % of the whole pre-bomb decline it has to reproduce.
IntCal20 also supplies a **1700–1950 pre-bomb Δ¹⁴C target**, covering the 1750–1941 window
Hua et al. leaves empty. Conversion uses both reporting constants — F14C = exp(−age/8033)
(Libby mean life, age convention) and Δ¹⁴C = 1000(F14C·exp(calBP/8267) − 1) (5730-yr mean
life, Stuiver–Polach convention) — **neither of which is the model's decay constant**,
which uses the true 5700-yr half-life. All three coexist correctly; conflating them is a
classic ¹⁴C error, so it is spelled out in the parser.

**Independent cross-check:** IntCal20 vs Hua NHZone1 over their 1941–1950 overlap agree to
**0.90 ‰ mean absolute difference** — tree rings vs atmospheric compilation.

### Physics bug: isotopes need GROSS fluxes, not net

The spinup's isotope operator came out **exactly singular**. Cause: isotopes were carried
at the source box's ratio on the **net** carbon flux, and at equilibrium the net fluxes are
zero — so no isotope crossed any interface. Physically wrong: air–sea gross exchange is
~80 GtC/yr each way against a ~2 GtC/yr net, and it is the *gross* exchange that
equilibrates ¹³C and ¹⁴C. Fixed by:

- **air–sea** emitted as two one-way gross fluxes (invasion and evasion), which also
  required splitting the ¹³C fractionation into a kinetic factor on invasion and an
  equilibrium factor on evasion — a single "net" α cannot represent two-way exchange;
- **interhemispheric exchange** likewise gross both ways (this is what carries the
  bomb-spike NH→SH propagation signal);
- **ocean diffusion** applied to each tracer on **its own gradient**, not to the net carbon
  flux times a ratio — this is what builds deep-ocean ¹⁴C depletion where net flux vanishes.

Conservation was unaffected (all gates still exact); the rewrite is antisymmetric per tracer.

### Free check that passed

Deep-ocean Δ¹⁴C emerges at **−194.7 ‰** against observations of roughly −150 to −200 ‰.
Nothing in the spinup targets it — it falls out of Kz, ocean geometry and decay. Now gated.

Spinup residuals: |dC/dt| 6.3e-09 GtC/yr, |dC13/dt| 8.9e-16, |dC14/dt| 6.6e-14; CO₂, δ¹³C
and Δ¹⁴C reproduce their targets to 1e-6. Integrating the spinup state forward 50 yr moves
CO₂ by <1e-4 relative and Δ¹⁴C by <0.05 ‰.

## 2026-08-10 — Forcing assembly, first end-to-end run, and DATA.md

`R/forcing.R`, `tests/testthat/test-forcing.R`, and **[DATA.md](DATA.md)** — a single
document covering every source, its traps, and the code that assembles it.
Suite: **167 passing**.

### Two conservation bugs in the forcing assembly, both silent

Annual→monthly interpolation must preserve annual totals: emissions drive cumulative
carbon, so an interpolation that changes annual sums changes the answer while looking
perfectly smooth.

1. **Splining the bomb-¹⁴C series inflated its prescribed total by 4.3 %.** A natural
   spline undershoots either side of the sharp 1962 peak; clipping those negatives back to
   zero *adds* mass. Fixed with a `method = "constant"` (piecewise-constant, exactly
   conserving, cannot undershoot) branch, now used for all sharply peaked non-negative
   sources. The underlying data are annual anyway, so smoothing was never justified.
2. **Masking source records with decimal time dropped the entire final year of each.**
   Month-centred `t` for year Y runs Y.04…Y.96, all of which satisfy `t > Y`. Cost another
   0.28 % of the bomb total, and silently truncated the last year of nuclear ¹⁴C. Masks now
   compare integer years.

Both are gated: cumulative fossil emissions must match GCB to 1e-10, and the bomb total
must be set by its citable prior rather than by the provisional shape (tested at three
different totals, since a shape that set the amplitude would pass a single-value test).

### First full historical run, 1750–2024

Runs end to end in 20 s. With **uncalibrated** default parameters:

| Quantity | Model | Observed |
|---|---|---|
| CO₂ 2024 | 464 ppm | 421 |
| Airborne fraction 1959–2024 | 0.519 | 0.431 |
| Ocean / land sink 2015–24 | 2.82 / 1.97 GtC/yr | 3.22 / 2.36 |
| δ¹³C 2024 NH | −9.30 ‰ | −8.70 |
| Δ¹⁴C peak | +998 ‰ at 1963.0 | +945 ‰ at 1963.6 |
| Δ¹⁴C 2019 NH | +14 ‰ | ~+5 |

Every discrepancy points the **same direction** and reduces to one cause: sinks too weak →
airborne fraction too high → CO₂ too high → δ¹³C too depleted (extra fossil carbon left
airborne). That internal consistency is the reassuring part — CO₂ high *with* δ¹³C
enriched would indicate a bug rather than a parameter miss. β, k_w and Kz are guesses.

The Δ¹⁴C bomb peak landing within 5 % of observed in both height and timing is encouraging
given the provisional shape, but **must not be read as validation** — the shape is a
placeholder and the amplitude comes from the Naegler & Levin prior.

### DATA.md

Documents the three-stage pipeline (acquire → parse → assemble), all calibration targets,
all forcings, the cross-checks that compare independent datasets, every assembly decision
as a named constant, the outstanding gaps, and licences. Records the traps found so far:
the Scripps column-5 rule, per-file missing-value markers, duplicate `age_CO2` columns,
non-constant inter-network offsets, the seasonal-aliasing rule for the gradient, the three
distinct ¹⁴C time constants, and why MLO flask data cannot replace the in-situ record.

## 2026-08-10 — Rcpp production core: 479× speedup, parity gated and mutation-tested

`src/ccx_core.cpp` + `R/cpp.R` + `tests/testthat/test-parity.R`. Suite: **177 passing**.

**Performance.** A full 1750–2024 monthly run drops from **26.4 s to 0.019 s** — 479×,
and comfortably inside the 50 ms budget that keeps a 1e5-evaluation MCMC under ~1.5 h.
R/model.R remains the reference implementation; the C++ is a port, and any physics change
must be made in both.

**"Bit-parity" was optimistic — the honest number is roundoff.** The two implementations
are NOT bit-identical. Measured over an 81-year integration (15,552 derivative
evaluations): CO₂ agrees to **8.3e-16 relative**, δ¹³C to 7.8e-13 ‰, Δ¹⁴C to 1.1e-12 ‰,
final state to 2.8e-13 absolute against state values of ~5.5e3.

The irreducible source is **catastrophic cancellation in deep-ocean ¹⁴C tendencies**, where
the diffusive flux and decay very nearly cancel: an ulp there is unbounded in *relative*
terms while staying ~1e-16 absolute. Tried and rejected: switching the carbonate polynomial
from an incremental `xp *= x` to `std::pow(x, i)` to match R's `x^i` exactly — this changed
the disagreement **not at all** (2.842e-13 either way), so the ulp difference is elsewhere,
and the incremental form was kept for being ~15 % faster. The gate therefore uses
scale-relative tolerances rather than per-cell relative ones, since a cell whose value is
1e-16 has meaningless relative error.

**The parity gate is mutation-tested,** because a tolerance chosen for roundoff must be
shown to still catch real porting errors:

| Mutant | CO₂ rel | δ¹³C abs | Δ¹⁴C abs | |
|---|---|---|---|---|
| (unmutated) | 8.3e-16 | 7.8e-13 | 1.1e-12 | passes, correctly |
| P1 wrong hemisphere on nuclear ¹⁴C share | 8.3e-16 | 7.8e-13 | **3.3e-01** | caught |
| P2 dropped ¹³C equilibrium fractionation on evasion | 8.3e-16 | **5.9e+00** | 1.1e-12 | caught |
| P3 off-by-one in ocean diffusion index | **5.0e+00** | 6.4e+00 | 9.0e+02 | caught |
| P4 one Newton iteration instead of six | **3.1e-02** | 1.2e-01 | 3.0e+01 | caught |

Real porting errors land 10–15 orders of magnitude above the roundoff floor.

**A flaw in my own mutation harness, worth recording.** The first pass scored mutants on
CO₂ and Δ¹⁴C only, and reported P2 as MISSED. P2 perturbs the ocean→atmosphere ¹³C
fractionation and therefore shows up *only* in δ¹³C — which the real test file does check,
but my harness did not. The lesson is the same one as the earlier inert-gate finding: a
mutation test is only as good as the observables it scores. Each of P1/P2/P3 is caught by a
*different* tracer, so all three must be scored.

**Also gated independently of R:** the C++ core conserves carbon to 1e-12 over a century on
its own terms (not merely by inheritance from the reference), and the runtime budget itself
is asserted, so a future slowdown fails the suite rather than being discovered during
calibration.

## 2026-08-10 — Calibration machinery; two findings that changed the design

`R/likelihood.R`, `R/calibrate.R`, `calibration/run_pilot.R`. 18 parameters,
0.058 s per posterior evaluation (spinup + 275-yr run + likelihood).

### Finding 1 — Δ¹⁴C zone→hemisphere weighting is NOT immaterial

Marcus chose area-weighted aggregation (2026-08-09) with the boundaries to be read from
Hua et al. (2022) rather than assumed. Reading them: the zones are **not latitude bands**.
Boundaries follow the polar jet and the tropical low-pressure belt, move seasonally, and
differ by longitude — in some regions the Equator is used, in others the mean DJF TLPB
position. The paper explicitly calls for more sites to pin them down.

Measured spread of the NH aggregate across defensible schemes:

| Scheme | bomb peak | max diff vs Hua-2013 bands | post-1970 |
|---|---|---|---|
| area, 40/15 bands | 853.2 ‰ | — | — |
| area, 47/20 bands | 829.9 ‰ | 25.7 ‰ | 3.9 ‰ |
| equal weights | 834.4 ‰ | 20.8 ‰ | 4.2 ‰ |
| NHZone1 alone | 944.6 ‰ | 94.3 ‰ | 20.9 ‰ |

Hua's own reported sd is 0.5–6.7 ‰, so the weighting spread during the bomb peak is
**4–50× the measurement uncertainty** — precisely where the bomb constraint operates. It
is therefore added in quadrature as representation error (25 ‰ in 1955–1970, 4 ‰
elsewhere) rather than ignored.

### Finding 2 — a likelihood decomposition stopped a placeholder from driving the posterior

Decomposing the log-likelihood at the default parameters:

| stream | n | logLik | share |
|---|---|---|---|
| Δ¹⁴C NH + SH | 1875 | −165,214 | **90 %** |
| CO₂ ice core | 255 | −14,551 | 8 % |
| CO₂ MLO + SPO | 1523 | −4,234 | 2 % |
| everything else | ~400 | ~−800 | <1 % |

Δ¹⁴C carried **90 % of all the information while the bomb injection shape is still a
placeholder**. Calibrating in that state would have laundered a provisional input into
every parameter, and nothing in the output would have looked wrong. Three changes:

- **Bomb-window Δ¹⁴C (1950–1975) excluded by default** (`LIK_USE_BOMB_WINDOW = FALSE`),
  with a message printed whenever it is dropped. Pre-bomb IntCal20 and post-recovery Δ¹⁴C
  are kept, so ¹⁴C still constrains ventilation through the Suess decline and post-peak
  decay.
- **Total bomb production `bomb_total` is now a calibrated parameter** with the citable
  Naegler & Levin (2006) prior (99.3–104.9 kmol, entered as lognormal σ=0.10). This was
  always the design's intent, and it lets shape error be partly absorbed into magnitude
  so post-peak Δ¹⁴C remains usable rather than being discarded. **Residual shape
  dependence remains** — see DATA.md §8.
- **Ice-core error inflated** by 4 ppm in quadrature. Law Dome's stated errors are
  analytical only (~0.02–1 ppm) and exclude gas-age, firn-smoothing and
  model-vs-ice representation error; uninflated, 255 samples at ~9σ contributed 8 % of the
  total from the sparsest, least direct record in the set. Its contribution fell
  −14,551 → −1,589.

### Data-layer bug found while wiring the likelihood

`fread(skip = "SampleID")` on the Law Dome sample files matched the NOAA
**variable-description block** (`## SampleID<tab>Sample ID, ...`) tens of lines above the
real header, parsing comment text as data: 334 rows of junk in `V1..V14`. It had been
latent since the first build because the benchmarks use the splines and nothing read the
samples until now. Fixed by anchoring on `^SampleID`; now yields 321 CO₂ and 105 δ¹³C
samples with their proper columns.

### Design notes carried in the likelihood

AR(1) residuals on the dense CO₂ and δ¹³C series with calibrated ρ (1500 monthly points
against 18 parameters are not independent); GCB sinks as a **partition** constraint only,
since atmospheric growth is already pinned by the CO₂ series; land sink at 3× inflated
σ per Marcus's Q1 default; station-vs-box representation error on CO₂ and δ¹³C.
Parameters are sampled on transformed scales with the **Jacobian applied explicitly** —
omitting it silently reshapes every prior.

## 2026-08-10 — Pilot MCMC: NOT converged (the pilot doing its job)

1500 iters × 4 chains, seed 2026, 4.4 min → `calibration/output/pilot_fit.rds`.

| Diagnostic | Value | Target |
|---|---|---|
| worst R̂ | **4.53** | < 1.05 |
| min ESS (bulk) | **4** of 3000 draws | ≥ 400 |
| acceptance | 0.045–0.063 | ~0.234 |
| log-posterior | −93,775 → −6,727 (best −6,469) | — |

The chains gained ~87,000 log-units and were **still climbing at the last iteration** —
they are in transient burn-in, not sampling the posterior. **No posterior numbers from
this run are usable**, and none are recorded anywhere. This is a too-short-chain and
bad-start problem, not evidence of a broken posterior: the likelihood decomposition and
single-parameter scans both show sensible, well-scaled responses.

Fix order for the next session (detail in `notes/handoff_2026-08-10_calibration.md` §4):
mode-find with `optim()` and start chains dispersed around the mode; then 50k × 4 chains
(~3.2 h at 0.058 s/eval); if acceptance stays ~5 % after that, the ocean-uptake parameters
(`k_w`, `h_ml`, `kz`) are probably on a narrow ridge and want reparameterisation or a
Hessian-scaled proposal. Gate production on R̂ < 1.05 **and** ESS ≥ 400.

Handoff note written at `notes/handoff_2026-08-10_calibration.md`.

## 2026-08-10 (later) — Bomb ¹⁴C source replaced: it was a physics error, not just a gap

Marcus supplied two references (Graven et al. 2017 GMD 10:4405; Tans 1981 SCOPE 16
pp. 131–157). Neither is the UNSCEAR 2000 Annex C yield table that §8 of DATA.md said was
needed — and it turned out not to be needed at all.

**What the placeholder actually got wrong.** `R/model.R` gives each hemisphere one
well-mixed troposphere and **no stratospheric box**, so `forc$c14_bomb` is a *delivery*
rate. The placeholder was shaped like *production*: 54.0 % of all bomb ¹⁴C in 1961–62 and
2.2 % in 1963, delivered with no stratospheric residence. Telegadas' measurements (Tans
Table 2) say 56–60 % of the Naegler & Levin total was still **in the stratosphere** in
Dec 62 – Feb 63 and that 1963 was the largest delivery year. So this was a mistimed
forcing, not merely an uncited one.

**What was built.** `data-raw/build_bomb_c14_source.R` → `data/forcing_bomb_c14.rds`,
monthly, unit integral. Part A (≥1963.04): two exponentials fitted to Table 2, separating
into **39.97 kmol at τ = 1.00 yr** and **27.75 kmol at τ = 10.15 yr** (RMSE 1.2 kmol / 15
points); the analytic derivative is the delivery flux and is positive by construction.
Part B (<1963.04): the fit leaves 34.28 kmol already delivered, which pins the pre-1963
integral with no yield inventory; its shape comes from Table 1's tropospheric inventory
plus first-order removal `λ·N14`, with λ solved in closed form to close that budget.

**The check that makes Part B credible.** Uptake is 39 % of pre-1963 delivery, far too
large to drop. Budget closure gives λ = 0.1687 /yr (5.93 yr); gross air-sea exchange
alone, from Tans' own 19 mol/m²/yr, gives 0.1495 /yr (6.69 yr) — 89 % of it, biosphere as
the remainder. Two independent routes to 13 %.

**Effect.** Benchmarked against the *area-weighted hemispheric* observations
(`ccx_zone_weights()`), not the DESIGN §6 Zone-1 gate, which is not comparable to the
model's `d14c_NH`. Observed NH 853.2 ‰ @ 1963.708, SH 659.4 ‰ @ 1965.042, lag 1.33 yr.
New shape: NH +0.75 yr, SH +0.58 yr, lag 1.17. Old: NH −0.67 yr, SH **−1.42 yr**, lag
0.58. NH timing error is a wash in magnitude; **SH timing and the interhemispheric lag
are decisively better**, and DESIGN §6 names that lag as the `tau_ex` constraint. The old
peak (996.9 ‰) also exceeded every observed zone including Zone 1.

**Tried and rejected along the way.**
- *Graven 2017 as the bomb source* — it is an observation product, not a source term, and
  at 3 zones / annual it is coarser than the Hua et al. 2022 record already in
  `obs_d14c_zonal.rds`. Kept only as a δ¹³C cross-check back to 1850.
- *Raw quarterly differencing of Table 2* — gives 16.8 kmol for 1963 against the fit's
  27.7, because it inherits the Dec 62 – Feb 63 point that Tans explicitly calls "much too
  low". Superseded by the two-exponential fit, which extrapolates that burden upward
  (59.12 → 67.72 kmol). Keeping the low point instead worsens NH peak timing (+1.00 vs
  +0.75 yr), so Tans' advice and the data agree.
- *`hyman` spline for the pre-1963 buildup* — rejects the 1959–1960 tie in Table 1.
  Replaced with `monoH.FC`, which is also the non-overshooting choice that DATA.md §6
  demands for this series.
- *Pre-bomb Suess baseline* — varying it −30 → −20 ‰ moves NH peak timing not at all and
  amplitude 0.5 %. Immaterial; left at the Table 1 SH Dec-54 value.

**Left open.** A 4.5× one-month step survives at the Part A / Part B join. A steep rise
there is real (autumn-1962 tests descending in spring 1963) but a *step* is an artifact of
Part B resting on December-only anchors. Monthly pre-1963 Δ¹⁴C exists in
`obs_d14c_zonal.rds` and would remove it — at the cost of deriving the forcing from the
record the likelihood scores against. Awaiting direction.

`ccx_bomb_c14_annual()` is now the annual aggregate of the monthly series; the placeholder
survives as `ccx_bomb_c14_annual_SUPERSEDED()` purely so the size of the correction stays
reproducible. Test suite unchanged at 174 pass / 0 fail / 2 skip (seacarb absent) —
verified equal on HEAD before and after.

### Bomb window admitted to the likelihood

`LIK_USE_BOMB_WINDOW` FALSE → **TRUE**. It was excluded only because the shape was a
placeholder carrying 90 % of the likelihood information; that reason is gone. DESIGN.md
§6 gained an explicit warning not to gate on the Hua **Zone 1** numbers — the model has
one area-weighted hemispheric box, so the comparable benchmark is the weighted aggregate
(NH 853.2 ‰ @ 1963.708), and using Zone 1 flattered the old shape, whose 996.9 ‰ peak
exceeded every observed zone.

DESIGN.md's bomb-source spec called for injection "through the τ_strat delay kernel",
which was never implemented. The Table 2 fit **is** that kernel, measured rather than
parameterised — so this closes the spec rather than departing from it, and adds no
parameter.

Carried caveat, recorded at the switch: at uncalibrated defaults the modelled NH peak is
still +0.75 yr late, and the Part A/B join step sits inside the admitted window. Both bear
on `tau_ex` and the ocean-uptake parameters; treat posterior shifts in those as suspect
until the join is resolved.

## 2026-08-10 (later still) — Sub-annual bomb shape from observed Δ¹⁴C; two metric traps caught

Marcus: *"If we don't have the raw sub-annual emission data, then I'm okay using the
observed concentration data to get the sub-annual pattern to supplement the annual emission
data."* Implemented, and applied more broadly than first scoped once the data were checked.

**Table 2's quarterly resolution is illusory.** Its quarter-on-quarter releases are
`7, 48, 29, 17, 30, 42, 13, 0, 14, 5, 7, −2, 15, 3` units. Telegadas reports inventories
to ~3 figures, so everything below ~15 is rounding — including a **`0`, because "170" is
printed twice in succession**, which produced three months of exactly zero delivery. Annual
sums (101 / 85 / 24) are far above that floor. So the interval totals are now annual
throughout and the concentration record supplies sub-annual shape everywhere, rather than
only before 1963.

**Trap 1 — suspicious uniformity was real, but not where I first looked.** The modelled NH
peak sat at exactly 1964.625 in all nine runs of a `k_w`/`kz`/`h_ml`/`tau_ex` sweep spanning
2–4×, while amplitude and interhemispheric lag both responded strongly. That pointed at the
zero-delivery notch — but removing the notch did not move the peak, so the hypothesis was
wrong.

**Trap 2 — the metric, not the model.** The observed NH aggregate is **double-peaked**:
850.3 ‰ @ 1963.625, dipping to 741.9, then 832.6 @ 1964.625. The two maxima differ by 2 %,
so `which.max()` flips between lobes and manufactured a "+0.92 yr timing error" that no
parameter could move *because it was not a timing error*. The model reproduces the
double-peak structure and picks the other lobe. Peak timing is now explicitly disowned as a
score in DATA.md §9; the metrics are debiased scatter and correlation over 1962–1972,
because a constant level offset is exactly what `bomb_total` and the uptake parameters
absorb.

**Result on those metrics** (uncalibrated defaults, area-weighted hemispheric obs):

| Bomb source | debiased sd NH | debiased sd SH | corr NH |
|---|---|---|---|
| Measured input function, concentration sub-annual shape | **34.5 ‰** | **36.1 ‰** | **0.970** |
| Two-exponential fit, no concentration input | 48.0 ‰ | 39.5 ‰ | 0.951 |
| Superseded placeholder | 233.4 ‰ | 186.1 ‰ | **0.121** |

The placeholder correlated with the observed bomb transient at **0.12**. The earlier
two-exponential version is superseded: fitting a smooth decay to Table 2 destroyed the
Apr–Jul release maximum that appears in *both* 1963 and 1964 (48 and 42 units, the two
largest quarterly releases) — the spring stratosphere-troposphere intrusion.

**Also rejected:** using the observed record for the annual totals as well. Keeping the
totals from Tans confines the circularity to within-year timescales, so annual and longer
behaviour remains an independent test. Recorded as a caveat rather than papered over.

Smoothing window (`CCX_BOMB_SMOOTH`) is immaterial: 3, 5, 9 months agree to <1 %.
λ moved 0.1687 → 0.1996 /yr; the independent gross-air-sea check is 0.1495 /yr, now 75 % of
it (was 89 %), a more plausible ocean/biosphere split. Tests unchanged: 174 / 0 / 2.

## 2026-08-10 (session B close) — Mode found; posterior is pathological; production run BLOCKED

Mode-finding works: +81,718 log-units on the pre-bomb-window likelihood, beating the
original pilot's best on restart 1 — that pilot never left burn-in, as suspected. On the
final likelihood, init −84,837.5 → mode −8,736.6 (103 min, 135,585 evals @ 0.046 s).

**But the previous handoff's diagnosis was wrong.** It said the failed pilot was "a
too-short-chain and bad-starting-point problem, not evidence of a broken posterior." It is
evidence of a broken posterior.

- **My bug first:** `MODE_HESS_EPS = 1e-3` produced a non-PD Hessian with entries like
  −5.4e61. Stepping `log(kz)` by 1e-3 costs 49,000 log-units; the true second derivative at
  1e-4 is −41.3. Now 3e-4, with `calibration/recompute_hessian.R` sweeping the step and
  checking curvature stability before any covariance is trusted. Also fixed a
  condition-number print taking max/min of negative eigenvalues.
- **Suspected ridge REFUTED.** With a valid Hessian the strongest correlations are
  `beta`↔`q10` (+0.817) and `k_w`↔`bomb_total` (+0.813), not the guessed
  `k_w`/`h_ml`/`kz`. Condition number ~2.4e6; `h_ml` is the least-constrained parameter.
- **Re-pilot from the mode:** acceptance `0.000, 0.000, 0.205, 0.187`, worst R̂ 9.672.
  All four chains start at `lp = -Inf` even at 0.5 posterior-sd dispersion. Chains 3–4
  reached ~0.2 only because from `-Inf` the first finite proposal is always accepted.
- **Root cause:** the mode's `kz = 175,790` is within ~1 % of a hard feasibility boundary
  whose posterior sd is ~20 %. The `-Inf` is **solver failure, not zero probability** —
  the spinup is fine (`prod_c14` ≈ 333 throughout); `ccx_run_fast()` returns NAs in
  `co2_NH` above kz ≈ 177,000 and the `anyNA` guard converts that to `-Inf`. The optimiser
  maximised into a numerical wall. **The posterior is silently truncated by numerics.**
- **The mode is not physically credible:** `q10` = 0.280 (−7.9σ, and Q10 < 1 means
  respiration falls with warming), `kz` +6.3σ, `sigma_co2` = 0.074 ppm (−4.3σ),
  `k_w` −4.3σ, `rho` railed at 0.998.
- **Probable cause — the AR(1) error model.** As `rho`→1 the innovation becomes
  `(r_t − r_{t−1})/sd`, so optimal `sd` collapses to the RMS of residual *increments*, not
  the level. Profiles confirm genuine interior maxima, not runaway: `rho` prefers 0.998
  over 0.90 by **3,916 log-units**; `sigma_co2` peaks at 0.074 ppm. The AR(1) term absorbs
  systematic mismatch as correlated noise, removing the penalty on bias — which also
  explains why the −118 ‰ bomb-window bias survives untouched.

**PRODUCTION MCMC IS BLOCKED** pending (1) a real fix for the solver limit — an `-Inf`
meaning "the integrator broke" must not serve as a prior bound — and (2) a decision on the
AR(1)/σ error model, which is a methodological choice for Marcus, not one to pick silently.

Handoff: `notes/handoff_2026-08-10b_bomb14c_and_sampler.md`.

## 2026-08-11 — Blocker 1 CLEARED: the solver wall is diagnosed, controlled, and gated

Marcus's call on the app: **fix the §5 blockers before building the Shiny app**, so the app
runs on a physically credible parameter set rather than on uncalibrated defaults (which read
**467.8 ppm NH at 2024 against ~424 observed**) or on the discredited 2026-08-10 mode.

**The `-Inf` wall was the textbook RK4 explicit-diffusion stability limit — nothing else.**
Interior diffusion is integrated explicitly, so a fixed substep count caps `kz`. Predicting
the cap from the largest eigenvalue of the discrete diffusion operator and comparing against
bisection on the actual NA threshold:

| h_ml (m) | substeps | empirical NA threshold | analytic | ratio |
|---|---|---|---|---|
| 75 | 4 | 155,319 | 155,366 | 1.000 |
| 75 | 8 | 310,694 | 310,732 | 1.000 |
| 75 | 16 | 621,433 | 621,464 | 1.000 |
| 30 | 4 | 92,896 | 93,754 | 0.991 |
| 200 | 4 | 178,231 | 177,409 | 1.005 |

Agreement to 0.1–1 % across both `h_ml` and `substeps`, and the eigenvalue is exactly linear
in `kz` and independent of the state — so this is a closed form for the whole trajectory, not
an estimate at one point.

**Fix:** `ccx_substeps_for()` chooses the substep count from that criterion
(`CCX_RK4_STAB_LIMIT` 2.7853, `CCX_STAB_SAFETY` 0.85, floored at `CCX_SUBSTEPS_MIN` = 4L).
`ccx_run()` and `ccx_run_fast()` now default to `substeps = "auto"`.

**This changes no existing result.** `kz` must clear ~155,000 m²/yr — **+6.2σ on its
lnorm(log 4000, 0.6) prior** — before the count moves off 4. Gated: `ccx_substeps_for()`
returns 4 across the prior's central 99.99 % at `h_ml` ∈ {30, 75, 200}.

**Air-sea gas exchange is deliberately NOT in the criterion.** It can dominate the Jacobian
at low `kz` (measured up to 15× the diffusion eigenvalue at `k_w` = 6000, `h_ml` = 30) but in
absolute terms stays ~13× below the RK4 budget there, and would need `k_w` ≈ 80,000 (+11σ) to
bind. Adding a second closed form would have meant carrying a fudge factor for its
Revelle-driven growth along the trajectory (measured up to 3.9× from 1750 to 2100 on
SSP5-8.5). Instead `ccx_run_fast()` escalates: on NA it doubles the substeps and retries up to
`CCX_SUBSTEPS_MAX` = 256L. An `-Inf` from the posterior now means the model failed, not that
the integrator broke.

**Also considered and set aside:** (a) simply raising the fixed count to 8 or 16 — moves the
wall instead of removing it, and doubles or quadruples MCMC cost at every draw for a case that
almost never arises; (b) an implicit/operator-split diffusion step — numerically the right
answer, but it breaks the "emit each flux once, apply antisymmetrically" structure that makes
conservation exact at any step size, and would need the C++ parity gate rebuilt; (c) bounding
the `kz` prior below the limit — that is the disease, not the cure: a numerics-derived bound
masquerading as a prior is exactly what went wrong.

New gate `tests/testthat/test-stability.R` (34 assertions), including a **mutation test**: with
the controller forced back to the old fixed 4 and the retry disabled, `kz` ∈ {175,790, 4e5,
1e6} must all still produce NA. Without it the "no NAs" test could pass for the trivial reason
that the cases were never unstable. Also asserts accuracy, not just stability: doubling the
substeps beyond the controller's choice moves CO₂ by < 1e-6 relative.

Suite **208 / 0 / 2** (was 174 / 0 / 2; the 2 skips are still seacarb).

**Still blocked:** the AR(1) error-model pathology (§4 of the handoff) — a methodological
choice for Marcus. Nothing is re-run until that is settled, since re-running mode-find on the
current likelihood would just find the same `q10` = 0.28 with a slightly higher `kz`.

## 2026-08-11 (later) — Blocker 2 CLEARED: AR(1) retired for annual + explicit seasonal

Marcus's call among four options: **annual means with independent errors, plus the seasonal
cycle restored as an explicit statistic**. Rejected alternatives: capping `rho` at 0.90 (the
cap becomes the answer — an analyst-chosen effective sample size wearing a fitted parameter's
clothes); adding explicit per-stream bias parameters (4+ more parameters on an 18-parameter
problem whose Hessian condition number is already 2.4e6, and `rho` would still rail);
continuous-time AR(1) `rho^dt` (fixes the irregular-sampling defect but leaves the level-bias
loophole unchanged in kind).

**What the AR(1) was actually costing**, measured at the 2026-08-10 mode on MLO CO₂:

| ρ | n_eff (of 812 monthly) | log-units lost to a +50 ppm bias |
|---|---|---|
| 0.998 (the mode) | **0.8** | **13.7** |
| 0.95 | 20.8 | 3,390.7 |
| 0 (independent) | 812 | 1,274,217.9 |
| annual means, σ = 2 ppm | 69 | 27,461.7 |

67 years of the Keeling curve carried the weight of **less than one independent observation**.
The residuals really are that autocorrelated — measured lag-1 **0.998** at MLO, **0.9998** at
SPO — so AR(1) was describing them faithfully. That is the point: they are model *discrepancy*,
not noise, and AR(1) reclassified discrepancy as free noise. δ¹³C had it worse — `sigma_d13c`
collapsed to 0.007 ‰, giving those streams *positive* log-likelihood (+766, +1025).

**Two further defects found while measuring it**, either fatal alone: the AR(1) was applied on
**observation index, not time**, so SPO's 16-month gap counted as a 1-month step; and a single
`rho` was shared across four series of quite different sampling density.

**What replaced it.** `ccx_year_harmonic()` fits, per calendar year,
`v ~ 1 + (t − midyear) + sin(2πφ) + cos(2πφ)`. Its intercept is a deseasonalised, detrended
annual level; its sin/cos coefficients are the seasonal statistic. **The same estimator runs on
model and observations**, so neither NOAA's deseasonalisation nor the model's seasonal shape has
to be trusted separately. The level is immune to partial month coverage — gated on synthetic
data where a naive mean of Apr–Dec is biased 0.20 ppm and of Jul–Dec 0.5+ ppm, while the
harmonic recovers the truth to 1e-9.

Scored terms fell **4,713 → 632**. `rho` is retired; 18 parameters → **17**.

**Δ¹⁴C went annual too, as a consequence, not an afterthought.** The Hua et al. (2022) zonal
record is a *smoothed monthly compilation* fitted to sparser discrete samples, so its 939
monthly values per hemisphere were never 939 independent measurements. Leaving them monthly
while thinning CO₂ would have relocated the swamping rather than removed it. Monthly errors are
**not** reduced by √n on averaging — the dominant term is systematic representation error. The
model side now uses its own annual **mean** rather than a mid-year sample; during the bomb rise
the two differ by several ‰.

**Tried and rejected mid-implementation:** scoring the seasonal cycle as the multi-year *mean*
harmonic (4 terms total). It made the seasonal cycle weaker than its own side effect — moving
`seas_amp_NH` from 20 to 24 GtC/yr cost 1.2 log-units on the seasonal term but 6 on the CO₂
*level* term, because a larger seasonal cycle rectifies against the log CO₂-fertilisation term
and shifts the annual mean. The amplitude would have been set by its rectification side-effect.
Per-year scoring (~50 term pairs per station) restores the intended ordering: the seasonal term
now moves 62 log-units over that same amplitude change against the level term's 6.

**Performance regression caught and fixed.** The first implementation called `ccx_year_harmonic()`
(a `qr.solve` and a data.frame per year) on four model series inside the MCMC loop, taking the
posterior evaluation **0.046 s → 0.718 s** — 40 hours for a production run. The model, unlike the
observations, is on an exact monthly grid, so every full year shares one design matrix and the
reduction is a single 4×12 by 12×N product. Back to **0.046 s**. `test-likelihood.R` gates the
fast path against the general estimator so the two cannot drift.

`ccx_loglik(..., by_stream = TRUE)` now returns the 12-stream decomposition — a single number
cannot show which constraint a fit is paying for. At uncalibrated defaults:

```
co2_level_MLO -8138.2  co2_level_SPO -6909.8  co2_seasonal_MLO -1024.6  co2_seasonal_SPO -107.9
co2_icecore   -1589.2  d13c_level_MLO -511.8  d13c_level_SPO    -294.2  d14c_NH        -3079.5
d14c_SH       -3515.4  d14c_intcal    -674.1  gcb_ocean_sink     -17.4  gcb_land_sink   -126.2
```

New gate `tests/testthat/test-likelihood.R`: estimator correctness, partial-coverage immunity,
fast-path equality, and **regression tests for the specific historical failure** — a +50 ppm bias
must cost > 10,000 log-units (it cost 13.7), `sigma_co2`'s profile must have an interior maximum
(it collapsed to 0.0744 ppm), and the seasonal term must have interior optima in both amplitude
and phase. Suite **264 / 0 / 2**.

Pre-fix calibration outputs quarantined to
`calibration/output/quarantine/20260811_ar1_pathology_and_solver_wall/` with a README. They carry
18 parameters against the current 17, so loading one and feeding `u_mode` to a current
`ccx_make_logpost()` would silently misalign every parameter.

## 2026-08-11 (later still) — Future temperature comes from FaIR

Marcus's call for the app's Futures tab: **use FaIR to estimate future temperatures.**

**The bug this fixes.** `ccx_build_forcing()` interpolated GMST with `rule = 2`, so past
IGCC's 2024 end it held the last observed value **flat**. An SSP5-8.5 run to 2100 sat at
+1.53 °C throughout, with the q10 respiration and ocean-solubility feedbacks silently
switched off. It now warns, and `ccx_run_coupled()` supersedes it for any future run.

**Structure.** CarbonCycleEmulator stays R-only with no FaIR dependency (its CLAUDE.md makes
that a hard rule), so FaIR runs offline in FaIRtoFrEDI and crosses the repo boundary as a
provenance-stamped CSV set: `FaIRtoFrEDI/run_fair_ssps_for_ccx.py` →
`data-raw/downloads/fair_v145_ssp/` (FaIR 2.2.4 calib1.4.5, 841 configs, ensemble mean,
1750–2500, 5 SSPs, 73 s total).

**Why more than a prescribed GMST path.** The tab has to answer "what does a 100 GtC pulse
do", on scenarios FaIR was never run on. A prescribed temperature path cannot respond to a
pulse — it would show a pulse changing CO₂ while leaving the climate untouched, the exact
misconception the tab exists to dispel. So temperature is rebuilt from **our own** CO₂:

```
erf_total = erf_co2(CO2 from this model) + erf_nonco2(scenario, prescribed from FaIR)
T         = impulse_response(erf_total)
```

The non-CO₂ half — aerosols, CH₄, N₂O, ozone, volcanic, solar — stays prescribed, because
this model has none of it. That is ~1.1 of SSP2-4.5's 4.7 W/m² at 2100 and the app must say
plainly that the user is changing CO₂ only.

| fit | result |
|---|---|
| CO₂ → ERF, quadratic in ln(CO₂/CO₂_PI), no intercept | rmse **0.029**, max 0.132 W/m²; **F₂ₓ = 3.85 W/m²** |
| ERF → T, 3-timescale impulse response | q = 0.160 / 0.328 / 0.354 K/(W/m²), d = **1.56 / 14.2 / 261 yr**; ECS-equivalent **3.24 K** |
| vs FaIR GMST, per scenario | rmse 0.028–0.036 °C; **rmse ≥2050 only 0.010–0.030 °C** |

**Tried and rejected — twice, both my errors, both caught by the gate:**

1. **Interpolating the pooled (CO₂, erf_co2) pairs** instead of fitting. Wrong twice over.
   The pairs are ensemble means over 841 configs with differing CO₂ forcing scale factors, so
   mean(erf_co2) ≠ f(mean(CO₂)) and the cloud has real width (0.025 W/m² at 900 ppm). And
   CO₂ is **not monotone in time** — SSP1-1.9 and SSP1-2.6 peak and decline — so sorting by
   CO₂ interleaves the rising and falling limbs, giving **334 descending steps, worst −0.147
   W/m²**, which `monoH.FC` cannot repair because it is monotone only for monotone *input*.
   The residual printed at the time was **0.000, and that diagnostic was vacuous**: a spline
   through every point interpolates by construction and can never show scatter. The real test
   is cross-scenario spread at matched CO₂ (0.025 W/m²), now a separate gate.
2. **A pure log law** (degree 1): rmse 0.078 vs 0.024 W/m², F₂ₓ 4.003 vs 3.889. The quadratic
   term is Meinshausen et al. (2020)'s band correction and is not optional. Degrees 3–4 buy
   nothing (0.0233, 0.0231).

**Outer-loop coupling, not an in-loop climate module.** CO₂ → T → carbon cycle is closed
inside `ccx_run_coupled()` by iterating whole runs — converges in **6 passes, ~0.17 s** —
rather than porting a climate module into `ccx_core.cpp` and rebuilding the parity gate for
it. **The feedback is not negligible:** SSP5-8.5 at 2100 is **+111 ppm and +0.32 °C** coupled
versus a single uncoupled pass.

Uncalibrated CO₂ at 2100 runs above FaIR's own (SSP2-4.5: 620 vs 530 ppm; SSP5-8.5: 1126 vs
960), consistent with the model reading ~27 ppm high over the historical record at defaults.
Recheck after calibration. Note separately that FaIR's *emissions-driven* SSP CO₂ is itself
well below the SSP database's concentration projections (~530 vs ~600 ppm for SSP2-4.5 at
2100) — flagged, not explained, and not something this project needs to resolve.

`ccx_build_forcing()` gains an `emissions=` override (the route stylised pathways and pulses
take; annual totals still conserved exactly through the monthly interpolation). New gate
`tests/testthat/test-climate.R`: IRF-vs-FaIR skill, CO₂→ERF residual **and** the
concentration-alone check, a future run must actually warm (the regression test for the flat
extrapolation), the historical splice must reproduce IGCC to 1e-10, and the carbon-climate
feedback must be measurably engaged. Suite **298 / 0 / 2**.

The IRF's single worst year is **1817**, after Tambora, where a 1-year box cannot track a
−5 W/m² one-year volcanic spike (max |err| 0.192 °C, identical across scenarios because 1817
is shared history). Bounded by the gate rather than pretended away.

## 2026-08-11 (evening) — Recalibrated on the fixed posterior; CO₂ now fits, ¹⁴C does not

Mode-find re-run on the 17-parameter annual/seasonal posterior with the stability controller
in place: **126 min, 164,635 evaluations at 0.046 s/eval, init −25,999 → mode −2,359.3.**
`calibration/output/mode_fit.rds`.

**Both blockers are demonstrably gone.**

| | 2026-08-10 mode | 2026-08-11 mode |
|---|---|---|
| `q10` | **0.280** (Q10 < 1: respiration *falls* with warming) | **4.14** |
| `kz` | 175,790 — ~1 % from the solver wall | **8,354**, substeps needed = 4 (the floor) |
| `sigma_co2` | 0.0744 ppm (collapsed) | 0.301 ppm |
| Hessian condition number | 2.4e6 | **8.29e4** |
| MLO CO₂ annual residual | mean +6.6, rms 13.6 ppm | **mean −0.15, rms 0.99 ppm** |

**The CO₂ side now fits well.** CO₂ at 2024 is **422.2 ppm against ~424 observed** (uncalibrated
defaults gave 467.8). Ocean sink 2014–23 **3.26 vs GCB 3.19** GtC/yr; land sink 2.98 vs 2.47
(high, but inside the deliberately inflated land-sink uncertainty).

**The ¹⁴C side does not, and the new plausibility screen caught it.** `run_modefind.R` now
reports each parameter's position in its own prior's tail and flags |z| > 3. Three fired:

| flagged | mode | z | reading |
|---|---|---|---|
| `bomb_total` | **151.2 kmol** | **+4.60σ** | prior is lnorm(log 102, 0.10) from Naegler & Levin's citable 99.3–104.9 kmol. The fit wants **48 % more bomb ¹⁴C than was produced.** |
| `sigma_d14c` | 45.8 ‰ | +3.01σ | the Δ¹⁴C error term inflating to absorb a poor fit |
| `q10` | 4.14 | +3.46σ | right sign at last, but well above the ~1.5–2.5 usually quoted for soil respiration |

Δ¹⁴C residuals: NH rms **47 ‰** overall, **69 ‰ inside the 1960–70 bomb window**, against a
bomb-window mean bias of only −5.3 ‰. So inflating `bomb_total` has fixed the LEVEL and left the
SHAPE wrong — which is the failure mode the 2026-08-10 handoff §2 predicted ("treat any
posterior shift in those specifically as suspect until the join is resolved").

Two independent diagnostics point the same way and are almost certainly the same defect:

- **Natural ¹⁴C production solves to 382 mol/yr against the canonical ~545** (ratio 0.70) — and
  this is the free validation the spinup was built to provide (see spinup.R's header).
- **Deep-ocean Δ¹⁴C is −104 ‰ against an observed −150 to −200 ‰** — the deep ocean is too well
  ventilated, consistent with `kz` sitting at +1.45σ and `h_ml` at a thin 37.7 m.

**PRODUCTION MCMC NOT LAUNCHED.** Sampling for 2.6 h around a mode whose bomb source is 48 %
above a tightly-constrained citable prior would produce a posterior whose ¹⁴C-derived quantities
— which is to say the ocean ventilation timescale, the thing ¹⁴C is in the model *for* — are not
believable. Flagged for Marcus rather than resolved: the candidates are the residual bomb-shape
problem at the Part A/B join, the ¹⁴C bookkeeping between production and inventory, and the ocean
grid, and choosing among them is a modelling decision.

## 2026-08-11 (night) — The ocean excess-¹⁴C constraint, and a ¹⁴C source nobody declared

Handoff §7 step 1: put the Naegler & Levin (2006) ocean inventory into the likelihood, because
every other ¹⁴C term is atmospheric and an atmospheric decline can be bought with a bigger bomb
source instead of a faster sink. Done — and validating the definition first turned up a
separate defect that changes one of 2026-08-11's conclusions.

### The constraint

`data-raw/build_calibration_data.R` now parses `data-raw/manual/naegler_levin_2006_budget.csv`
into `data/obs_excess_c14.rds`; `ccx_loglik()` gains `excess_c14_ocean`. Both cores emit
`ocean_C14` / `land_C14` / `atm_C14` (state units — kmol is the likelihood's business), gated by
`test-parity.R`. Tests **371 → 384 pass**, 0 fail, 2 skip.

**The natural baseline is free.** The run's first row *is* the 1750 steady state by
construction, so no counterfactual run is needed and the posterior evaluation stays at
**0.046 s**. Measured against the expensive alternative — a full no-fossil/no-LUC/no-bomb/
no-nuclear counterfactual carrying the observed GMST and ENSO — the two differ by **0.27 kmol
(1975) and 0.58 (1995)**, under 1 % of the excess against a ~16 kmol observational spread.
Removing the climate forcing as well reproduces the spinup state to 0.003 kmol, which is the
fixed point behaving as it must.

**The units were checked before the term was trusted**, on the one row where N&L have real
observations. Rebuilding the *atmospheric* excess from the CO₂ and Δ¹⁴C observations alone under
our convention gives **37.3 kmol (1975) and 25.6 (1995)** against their troposphere-plus-
stratosphere **35.6 and 21.7**: **+4.8 % and +18.0 %**. That measured spread — not a chosen
number — sets `LIK_EXCESS_C14_REP_FRAC = 0.15`, carried as a **rank-one shared method bias**
across the two years rather than per-year quadrature, because two estimates from overlapping
reconstructions do not carry twice the information. (An earlier working note put the 1995 figure
at 15.3 %; that was arithmetic on the wrong denominator. 18.0 % is correct, and the fraction was
raised from 0.10 to 0.15 to cover it.)

### The finding: land-use-change emissions inject ¹⁴C ex nihilo

Excess ¹⁴C can only come from the prescribed sources minus decay, so the reservoir excesses must
sum to the cumulative bomb input. **Ours do not.** From `dE/dt = sources − λE`, with no
assumption about where the extra comes from:

| | excess | declared sources | decay | **undeclared** |
|---|---|---|---|---|
| 1975 | 167.85 | 144.38 | −0.45 | **+23.93 kmol (14.3 %)** |
| 1995 | 178.84 | 151.45 | −0.88 | **+28.27 kmol (15.8 %)** |

**Cause:** `R/model.R` emits LUC with `add_source()` at the **vegetation box's own ¹⁴C ratio**
while the vegetation box is not debited — 273 GtC of LUC carbon at a land Δ¹⁴C of +221 ‰ is a
real ¹⁴C source. Fossil carbon is emitted at Δ¹⁴C = −1000 and correctly carries none. Two
independent estimates agree: the closure residual above, and integrating the LUC flux against the
run's own vegetation ratio (24.0 / 27.9 kmol).

Whether this is a bug or a defensible consequence of LUC being exogenous to two *responsive*
land pools is **a modelling decision for Marcus, not resolved here.** The physical objection is
that the real ¹⁴C leaving a cleared forest was taken up from the atmosphere earlier and is
already in the bomb budget, so injecting it again double-counts.

**What it does and does not contaminate**, from `calibration/diag_excess_c14.R` §3:

- **The ocean is barely affected.** Paired bomb-only 72.6 / 94.3 kmol against total-minus-natural
  75.9 / 95.4 — a 1–4 % gap, far inside the observational spread. The ocean constraint stands.
- **The land is affected a great deal, and this CORRECTS 2026-08-11 §6.4(e).** At the citable
  102 kmol our land excess is 43.8 kmol under total-minus-natural but **29.6 kmol** paired
  against N&L's 18.9 — so "our land holds 2–3× their biosphere" becomes **~1.6×**. Still high,
  and still consistent with the `tau_veg` tension, but not the dramatic gap it looked like.

### Size of the effect — real, not decisive

At the quarantined mode's `bomb_total` = 151.2 the term scores **−15.10**; at the citable 102 it
scores **−7.26**. That is **~7.8 log-units** in favour of the citable total, against the **116
log-units** it costs to pin `bomb_total` at 102 (§6.4(c)). **The constraint sharpens the
diagnosis; it does not resolve it.** The bomb delivery *shape* remains the thing to fix, exactly
as the handoff ordered it — step 1 has not made step 2 unnecessary.

### FLAGGED FOR MARCUS — the target set is worth ~130 log-units

Two published observational reconstructions, and choosing between them dwarfs everything above:

| set | 1975 | 1995 | term at `bomb_total` 151.2 |
|---|---|---|---|
| **`table4_obs_range`** (default) | 48.6 ± 7.9 | 51.4 ± 7.6 | −15.1 |
| `table2_peacock` | 43.9 ± 4.3 | 56.5 ± 2.5 | ≈ −149 |

Both are stored in `data/obs_excess_c14.rds`; `LIK_EXCESS_C14_TARGET` picks by name. **The wide
one is the default** on the grounds that the span between two published reconstructions is method
spread, not measurement noise, and adopting one of them as if the other did not exist would put
that much leverage on a choice of paper. If Marcus prefers the tight set, the mode-find must be
re-run — and `bomb_total` would then be driven hard toward the citable value by this term alone,
which is a *result* only if the target is believed.

### State

`calibration/output/mode_fit.rds` and its log are **quarantined** to
`calibration/output/quarantine/20260811b_pre_excess_c14/` with a README: the parameter vector is
still a fine starting point, but its **logpost −2359.3 must not be quoted** (the same vector
scores −2378.6 under the current posterior) and its Hessian is of the old posterior. A mode-find
against the new posterior is running.

### Recalibrated with the constraint in — and it does not move `bomb_total`

Mode-find against the new posterior: **118.8 min, 151,536 evaluations at 0.047 s/eval,
−26,005.8 → −2,374.1.** `calibration/output/mode_fit.rds`.

| | pre-constraint mode | post-constraint mode |
|---|---|---|
| `bomb_total` | 151.25 (+4.60σ) | **149.81 (+4.54σ)** |
| `k_w` | 2950 | 2921 |
| `kz` | 8354 | 8267 |
| `q10` | 4.143 (+3.41σ) | 4.093 |
| `sigma_d14c` | 45.84 (+3.01σ) | 45.86 |
| ocean excess ¹⁴C @1975 / @1995 | 76.9 / 95.7 | **75.8 / 94.3** kmol |
| MLO CO₂ annual rms | 0.986 ppm | 0.983 |
| bomb-window Δ¹⁴C rms | 69.1 ‰ | 67.9 |
| Hessian condition number | 8.29e4 | 7.69e4 |

**Every parameter moved by about 1 %.** The same three flags fire (`q10`, `bomb_total`,
`sigma_d14c`). The fit simply **pays** the ocean-inventory penalty — `excess_c14_ocean` sits at
−14.55 at the mode, against observed targets of 48.6 ± 7.9 and 51.4 ± 7.6 that it misses by
+27 and +43 kmol — rather than give up any of the atmospheric fit.

That is a **clean negative result, and it is worth more than a positive one would have been.**
The constraint was added on the hypothesis that ¹⁴C's ocean sink was underdetermined because
every term was atmospheric. It is not underdetermined; it is *contradicted*. The model cannot
simultaneously match the atmospheric Δ¹⁴C decline and the observed ocean inventory, at any
`bomb_total` — which is the ocean-side twin of §6.4(c)'s atmospheric-side finding that it cannot
match the observed Δ¹⁴C curve at any `bomb_total` either. **Two independent constraints now say
the same thing about the same defect**, and neither is a parameter problem.

`calibration/profile_bomb_total.R` was written to close the remaining loophole — whether the
failure to bite is the *width* of the wide target set or something structural — by profiling
`bomb_total` under both target sets with everything else re-optimised at each point.

### The `bomb_total` profile: the target-set choice dissolves, and the constraint cannot win

`calibration/profile_bomb_total.R`, 91.7 min, `bomb_total` ∈ {102, 120, 135, 150, 165} kmol with
every other parameter re-optimised at each point, under **both** target sets.

| `bomb_total` | logpost | ocean term | ocean excess 1975/1995 | bomb-window Δ¹⁴C rms | MLO CO₂ rms |
|---|---|---|---|---|---|
| 102 | −2483.1 | −7.21 | 52.7 / 64.4 | **190.6 ‰** | 0.98 |
| 120 | −2433.7 | −8.93 | 60.8 / 75.4 | 119.9 | 0.99 |
| 135 | −2393.0 | −11.24 | 67.8 / 84.7 | 74.7 | 0.99 |
| **150** | **−2374.1** | −14.60 | 75.9 / 94.4 | **68.1** | 0.98 |
| 165 | −2393.4 | −19.07 | 85.0 / 104.3 | 90.6 | 0.96 |

(`table4_obs_range`; the `table2_peacock` column is within 1.3 log-units at every point.)

**Both target sets choose `bomb_total` = 150.** The flagged choice was flagged on the wrong
grounds: the earlier "~130 log-units" estimate for it assumed **per-year quadrature**, and the
term does not use per-year quadrature. Once the shared method error is modelled as the rank-one
common term it is — which is the correct structure, since the model overshoots **both** years in
the same direction — the two sets differ by **0.7 log-units at the mode**, not 130.

`calibration/diag_excess_c14_leverage.R` locates the real lever. The bar to clear is **116.4
log-units** (what the rest of the likelihood pays to move 150 → 102, almost all of it the bomb
window: **68.1 → 190.6 ‰**):

| `LIK_EXCESS_C14_REP_FRAC` | `table4_obs_range` | `table2_peacock` |
|---|---|---|
| 0.00 | 20.4 | **135.4** ← clears |
| 0.02 | 19.7 | 108.7 |
| 0.05 | 16.9 | 53.3 |
| 0.10 | 11.3 | 18.9 |
| **0.15 (in use)** | **7.4** | 9.1 |
| 0.20 | 5.1 | 5.3 |

**One corner of this table flips the answer: the tight target with essentially zero method
error.** Even 2 % of shared bias closes it. And what that corner buys is not a model that fits
both — it is the ocean inventory purchased at 190 ‰ of atmospheric bomb-window misfit. Choosing
it would be choosing which observation to disbelieve, not resolving anything.

**Conclusion: no admissible setting of this constraint resolves the ¹⁴C problem.** It either does
nothing (any plausible shared method error) or it trades one 14C misfit for another. Handoff §7
steps 2 and 4 — the bomb delivery shape at the 1963.04 Part A/B join, and the single ventilation
timescale — are where the resolution has to come from. Step 1 is complete and its answer is
that step 1 was never going to be enough.

## 2026-08-12 (later) — The ¹⁴C defect is a PARTITION error, not a delivery-shape error

Handoff §7 sent this session to the bomb delivery shape, "starting at the Part A / Part B join
at 1963.04, where a 4.5× one-month step survives."

**That entry point is stale.** The join step was already reduced **4.5× → 1.59×** on 2026-08-10
by the sub-annual rebuild, and both `DATA.md` §9 and `notes/handoff_2026-08-10b` record what
remains as *defensible real acceleration* (the autumn-1962 tests descending in spring 1963), not
a method artefact. `Rscript data-raw/build_bomb_c14_source.R` prints `join step: 16.38 → 26.05
kmol/yr = 1.59x in one month`. The 4.5× was carried forward through two handoffs after the thing
it described had been fixed.

So the shape question was re-opened on its merits instead, with a new diagnostic.

### `calibration/diag_bomb_partition.R` — the same budget, split three ways

N&L Table 4 partitions their cumulative bomb input across stratosphere / troposphere /
biosphere / ocean at 1975 and 1995. Run at **their own citable total (102 kmol)** our model
receives the same input, so the partition is a like-for-like test that is **independent of
`bomb_total`**: not how much ¹⁴C there is, but where it went.

**Compared like with like.** `R/model.R` has no stratospheric box and the bomb source is a
*delivery rate to the troposphere* — the stratospheric residence is already inside the source.
So the model's atmosphere box is a **troposphere**, and N&L's stratosphere is removed from their
atmosphere *and from their total*. Scoring against troposphere+stratosphere instead would credit
the model for ¹⁴C it has by construction already delivered, and would inflate the deficit from
−40 % to −54 %.

Paired bomb-only, kmol:

| | model 1975 | N&L 1975 | | model 1995 | N&L 1995 | |
|---|---|---|---|---|---|---|
| troposphere | 16.13 | 26.80 | **−40 %** | 9.82 | 17.50 | **−44 %** |
| biosphere | 32.80 | 21.70 | **+51 %** | 29.88 | 18.90 | **+58 %** |
| ocean | 48.73 | 42.10 | +16 % | 63.34 | 60.00 | +6 % |
| SUM delivered | 97.67 | 90.60 | +8 % | 103.04 | 96.40 | +7 % |

Observational brackets bound the two rows that have them: troposphere 26.0–28.0 and 16.0–18.0;
ocean 39.6–48.2 and 54.0–59.0 (Peacock, N&L-corrected). The model's troposphere is outside its
bracket at both years; its ocean is inside at both.

**Two errors, an order of magnitude apart.** The **sum** is +7–8 % — a real delivery-timing
error, and the *most* a re-shaped source could ever repair. Inside that budget the troposphere
is 40–44 % short and the biosphere 51–58 % long, **in the same direction at both reference
years, twenty years apart**. Re-timing the delivery moves ¹⁴C between years; it cannot move it
between reservoirs. This is why `bomb_total` sits at +4.5σ: the fit is buying atmospheric Δ¹⁴C
it cannot otherwise have, and paying for it in the ocean-inventory term (2026-08-11).

### The land is the wrong shape, not the wrong size

Model land carbon is **1678 GtC (1975) / 1721 (1995) against N&L's 2200 PgC biosphere, −22 to
−24 %** — a *smaller* pool holding *51–58 % more* bomb ¹⁴C. Capacity is not the defect; residence
structure is. `R/model.R:177-185` is a strictly serial cascade atm → veg (`tau_veg` 10 yr) → soil
(`tau_soil` 15 yr) → atm with **no fast autotrophic-respiration return**: every atom taken up by
NPP is locked for the full 25 yr before it can come back. The real biosphere returns roughly half
of GPP within the year. N&L's has four pools.

This is the same defect the `tau_veg` sweep already saw from the other side and did not name:
3 yr gives bomb rms 59.5 but CO₂ rms 11.98; 10 yr gives 69.1 and 0.99. A single serial chain has
to serve the decadal ¹⁴C transient and the centennial CO₂ uptake with one timescale — structurally
the same bind as one `kz` serving the bomb transient and the deep age (2026-08-11 §6.4(b)).

### The LUC ¹⁴C leak does not contaminate this

Measured, not assumed, in `[C]`: the leak's **paired** part is **0.52 kmol (1975) / 1.22 (1995)**
against a total injection of 23.84 / 27.70. It enters the atmosphere, so removing it would widen
the tropospheric deficit to −11.19 / −8.91 — the conclusion survives either resolution of the
open decision, and the partition test did not need to wait on it. (The *unpaired* total still
matters for §5's inventory comparison; nothing there changes.)

### Consequence for the plan

Handoff §7 steps 2 and 3 swap places, and step 6 is no longer optional. The land structure — a
third fast pool, or an explicit GPP/autotrophic-respiration loop — is now the highest-value work,
and it is what freeing `tau_veg` was always standing in for. Test suite unchanged at
**384 pass / 0 fail / 2 skip**; this session added a diagnostic and no model or likelihood code.

## 2026-08-12 (night) — LUC debits the vegetation box; the model becomes carbon-conservative

Marcus' decision on the open item from §5 of the 2026-08-12 handoff: **debit the vegetation
box** — "physically cleanest, but changes the land carbon trajectory and so the CO₂ fit."
Branch `luc-veg-debit`, **not merged**: two guard tests fail (below).

`R/model.R:226` and `src/ccx_core.cpp` — land-use change stops being an `add_source()` and
becomes `add_flux(iveg, iatm, e_luc)`. Fossil carbon stays a source: geology *is* outside the
modelled system. LUC never was.

`d13c_bio` (−25 ‰, "provisional") is **removed from both cores and from `ccx_cpp_par()`**:
`add_flux` carries the vegetation box's own emergent ¹³C ratio, so the prescribed value has no
remaining use. Clearing a forest does not fractionate, so `alpha13 = 1`. Historical `e_luc` is
strictly positive (min 0.68, max 2.41 GtC/yr over 3300 months), so the transfer never reverses;
a comment records that a negative scenario value would transfer at the atmosphere's ratio
*without* the photosynthetic fractionation it should carry.

**The model is now carbon-conservative, and was not before.** Total carbon change 1750→2024 is
**503.79 GtC against 504.67 GtC of cumulative fossil input — residual −0.88 GtC** (0.2 %, a
one-step `cumsum` alignment). Previously the same run created **321.6 GtC** of land-use carbon
out of nothing, alongside the ~28 kmol of ¹⁴C.

### It costs the old mode everything, and that is recoverable

The pre-change mode scores **−2374.1 → −56,349.7**, almost all of it `co2_level_MLO` (−26,748)
and `co2_level_SPO` (−24,664). CO₂ at 2020 falls from a good fit to **372.8 ppm against ~414
observed**. The mechanism is second-order and expected: the atmosphere receives the same LUC
carbon either way, but the vegetation box now *pays* for it, so litterfall and heterotrophic
respiration both fall while `npp0` does not — the land becomes a far stronger net sink.

A 1-D scan over `beta` with everything else held at the stale mode:

| `beta` | CO₂ @2020 | logpost | land C 2024 |
|---|---|---|---|
| 0.00 | 449.9 | −27,048.8 | 1363 |
| 0.10 | 436.1 | −11,981.8 | 1414 |
| 0.20 | 424.1 | **−6,216.3** | 1459 |
| 0.30 | **413.7** | −6,617.8 | 1499 |
| 0.40 | 404.6 | −11,095.4 | 1533 |
| 0.883 (mode) | 372.8 | −56,349.7 | 1656 |

**This is the fix removing an implausible parameter, not breaking a good one.** The old mode
needed `beta = 0.883` — far above the literature range for the log formulation — precisely
because 321.6 GtC of phantom carbon had to be absorbed by *something*. With the leak closed,
β ≈ 0.25–0.30 reproduces CO₂ @2020 to ~0.3 ppm, and everything else in the vector is still tuned
for the old bookkeeping. A full mode-find has not been run.

### Two guard tests fail, and they are right to

`test-likelihood.R:114` and `:117` ("a CO₂ level bias is expensive") assert that a +1 ppm bias
costs > 100 log-units; `cost(1)` is now **−534.6**, i.e. +1 ppm *improves* the fit. The fixture
uses `ccx_default_params()`, whose `beta = 0.40` now leaves CO₂ ~12 ppm low. **The tests are
detecting a stale default parameter set, not a likelihood loophole** — the AR(1) pathology they
were written to catch has not returned. Per the standing rule they have **not** been modified or
skipped. Resolving them means re-centring `ccx_default_params()` on the new bookkeeping, which is
a decision, not a fix. Suite: **382 pass / 2 fail / 2 skip**.

### An inconsistency this exposes

The debit removes vegetation *carbon* but not vegetation *productive capacity*: `npp` is
`npp0 * (1 + beta ln(chi/chi0))`, so clearing a forest does not reduce NPP and the land
over-recovers. Options are to tie NPP to the veg stock (`npp0 * veg/veg0 * ...`), or to accept it
and let `beta` absorb it — which is what the scan above is doing. **Not resolved**; it should be
settled as part of the land restructure, which changes the pool layout anyway.

## 2026-08-12 (night, later) — NPP capacity tie and a GPP loop; two predictions falsified

Marcus: tie NPP to the veg stock; and on GPP — *"leaf growth and decay will release the same
amount of isotopes back that it absorbs, whereas other components of GPP will be more like the
ocean where exchanging CO₂ back and forth leads to equilibrating isotopes faster than the net
CO₂ flux."* Both implemented in both cores; parity holds at 4.5e-13 on CO₂.

- **`npp_veg_frac` (φ)** — `NPP = npp0 · [(1−φ) + φ·veg/veg0] · (1 + β ln(χ/χ₀))`. Default 0.5.
- **`ra_ratio`** — `GPP = NPP·(1+ra_ratio)` down, `Ra = NPP·ra_ratio` back up at **veg's own
  ratio**. Default **0**, which reproduces the previous model exactly. Marcus' distinction is
  exactly what the parameter means: respiring carbon fixed days ago returns the *atmosphere's*
  ratio and is a null loop; respiring from the pool returns the *pool's* ratio and is the
  ocean-gross-exchange analogue. `add_flux` takes the source box's ratio, i.e. the second case,
  so `ra_ratio` is the fraction of GPP that genuinely cycles **through the pool** — his two
  regimes are its endpoints. Leaf growth-and-decay is not this flux; it is the existing
  veg → soil → atm cascade, lagged rather than equilibrating.

`calibration/diag_land_structure.R` tests three claims. **Two of my three predictions were wrong.**

### ✗ "φ cannot be 1" — falsified

The decoupled algebra says the veg coefficient is `(φ·f − 1)/tau_veg`, so `φ·f > 1` diverges.
It does not. φ up to **1.10 (φ·f = 1.25) is stable**, because **χ is not exogenous**: a growing
veg pool draws CO₂ down, which lowers `f`. CO₂ @2024 falls monotonically 413.7 → 322.2 ppm across
the scan — that column *is* the feedback. The false bound has been removed from the comments in
both cores; the diagnostic is kept live so it is not reinstated from algebra.

### ✓ `ra_ratio` is isotopes-only — confirmed

`max|ΔCO₂| ≤ 2.3e-13 ppm` and `max|Δland C| ≤ 9.1e-13 GtC` across `ra_ratio` ∈ [0, 1.5], while
Δ¹⁴C moves. The net carbon flux is NPP by construction and the implementation honours it.

### ✗ "the GPP loop shrinks the biosphere's bomb ¹⁴C" — falsified, and Marcus' caution was right

| `ra_ratio` | trop 1975 | bio 1975 | trop 1995 | bio 1995 |
|---|---|---|---|---|
| 0.00 | 21.04 | 39.74 | 11.02 | 42.55 |
| 0.50 | 20.68 | 42.47 | 11.76 | 42.43 |
| 1.50 | 21.09 | **44.12** | 12.30 | 42.26 |

The biosphere **rises** at 1975 and the troposphere barely moves. In 1975 the atmosphere is still
far above natural, so a *lagging* veg pool is still catching up and holds **less** than
equilibrium; equilibrating harder closes that gap upward. **Equilibrating faster is the wrong
lever while the source is still elevated.** `ra_ratio` is correct physics and stays, defaulted to
0 — it is simply not what closes the partition gap.

### What does set the land's bomb ¹⁴C: it is multi-pool or nothing

N&L: 21.7 / 18.9 kmol on a **2200 PgC** biosphere = **0.986 / 0.859 kmol per 100 GtC**.

| tau_veg | tau_soil | bio 1975 | bio 1995 | land C 1975 | kmol/100 GtC |
|---|---|---|---|---|---|
| 10 | 25 | 39.74 | 42.55 | 2095 | 1.897 |
| 10 | 3 | 30.49 | 23.69 | 786 | 3.880 |
| 3 | 3 | 19.69 | 11.53 | 367 | 5.363 |
| 20 | 50 | 42.52 | 52.01 | 4184 | **1.016** |

The excess is strongly **sub-linear** in pool size — a bigger, slower pool dilutes the bomb signal
faster than it accumulates it. N&L's ratio is reached only at a pool **twice theirs**. Matching
their absolute inventory (tau 3/3) needs a pool **six times too small**. **One responsive soil
pool cannot match their carbon stock and their ¹⁴C inventory simultaneously** — which is the
signature of a multi-pool biosphere: fast pools cycle the bomb ¹⁴C, a large slow pool holds carbon
while barely seeing it. That is the structural change the partition finding actually implies.

### φ = 0.5 breaks the airborne fraction, and this is a physical benchmark

`test-pulse.R:112/113` ("the airborne fraction is in the right ballpark", against recalled
Joos et al. 2013 IRF values 0.59 / 0.41 at 20 / 100 yr) now **fails**: 0.402 and 0.243.

| φ | AF @20 yr | AF @100 yr |
|---|---|---|
| **0.00** | **0.597** | **0.423** |
| 0.25 | 0.517 | 0.344 |
| 0.50 | 0.402 | 0.243 |

**φ = 0 reproduces Joos almost exactly.** The capacity term is doing two jobs at once and only one
was wanted: it makes clearing reduce productivity (wanted), but it *also* amplifies CO₂
fertilisation on the way up (more veg → more NPP → more veg), and that positive feedback is what
over-drains the pulse. Suite: **380 pass / 4 fail / 2 skip** — the two likelihood fixtures from
the LUC commit, plus these two. Not modified, not skipped, per the standing rule.

**Unresolved, for Marcus.** Separating the two jobs is the obvious move — e.g. clamping the
capacity factor at `min(veg/veg0, 1)` so clearing costs capacity while growth does not add it.
Not implemented: at defaults the land pool stays *above* veg0 all century, so the clamp would be
inert historically, and whether it bites depends on a calibrated β. It needs deciding together
with the multi-pool land, not before it.

---

## 2026-08-12 (later) — Four-pool land: the ¹⁴C partition error is closed

### The prescribed fix was wrong, and an offline tool caught it before the rebuild

The previous entry sent the next step to "split the single responsive soil pool into fast
and slow". `calibration/diag_land_topology.R` was written to choose a pool layout *before*
restructuring the state vector — it integrates a candidate topology's bomb-¹⁴C inventory
directly from an atmospheric Δ¹⁴C history, at ~1 ms per candidate, with no core rebuild.
It validates against the full model on the live land parameters first (**−0.9 % / −0.6 %**
at 1975 / 1995 on the four-pool land; −6.5 % / −3.1 % on the two-pool one it replaced).

**A soil-only split cannot work.** Its best is 30.0 / 19.5 kmol on 2214 GtC against N&L's
21.7 / 18.9 on 2200 — 1995 right, **1975 38 % high**. The reason is arithmetic: a single
600 GtC vegetation pool at `tau_veg` 10 already holds ~20 kmol at 1975, essentially N&L's
entire biosphere, so *no soil layout beneath it can help*. **The vegetation had to be split
too.** Driven by the OBSERVED atmosphere, not the model's own — the model's troposphere was
40–44 % short *because* its land took too much, so designing against it would have
understated how inert the land must be.

### The structure

`leaf` (60 % of NPP, τ 1 yr) → `wood` (τ 20 yr) → litter split 95/5 → `soil_fast` (τ 2 yr)
and `soil_slow` (τ 500 yr). NB 28 → 32. Vegetation 516 GtC, responsive soil 114, passive
soil 1500, total 2130 — every pool independently defensible, on a **flat** misfit surface
(0.60/30/0.04 and 0.70/40/0.04 both ~6 %), so these are a defensible centre, not a fit.

Routing, all stated in the derivative: capacity keys on leaf+wood; the Ra loop runs per
vegetation pool at each pool's own ratio; litter is split **per source pool** so the two
¹⁴C ratios are not averaged before the split; seasonal NEP through leaf; ENSO out of
`soil_fast`; **LUC debits wood** (Marcus 2026-08-12). Calibration keeps exactly one land
degree of freedom — `tau_soil_fast` replaces `tau_soil`; the other five are held fixed so
a CO₂ fit cannot undo the partition fix. *That is a choice, and it will need revisiting.*

### Result

Paired bomb-only at `bomb_total` 102, vs Naegler & Levin Table 4:

| | before (2-pool, at the mode fit) | after (4-pool, at defaults) | N&L |
|---|---|---|---|
| biosphere 1975 | 32.80 (+51 %) | **21.73 (+0 %)** | 21.70 |
| biosphere 1995 | 29.88 (+58 %) | **20.83 (+10 %)** | 18.90 |
| troposphere 1975 | 16.13 (−40 %) | 31.34 (+17 %) | 26.80 |
| troposphere 1995 | 9.82 (−44 %) | 15.91 (−9 %) | 17.50 |
| SUM delivered | +8 % / +7 % | +7 % / +6 % | — |

**The 40–58 % partition error is gone.** What remains is the delivery error alone, which
was always the ceiling on what a re-shaped source could repair. The four-pool land is
**not calibrated** — read the partition, not the level.

### φ resolved itself

`test-pulse.R:112/113` — the Joos airborne-fraction benchmark that φ = 0.5 broke — **now
pass unmodified.** The capacity term's runaway (more veg → more NPP → more veg) was an
artefact of a single 600 GtC vegetation pool with a 10-yr turnover; with the fast leaf pool
carrying most of NPP, the positive loop no longer over-drains the pulse. No clamp needed,
and φ stays at 0.5. The open decision from the previous entry is **closed by the
restructure**, not by a decision.

### What it cost, measured rather than argued

γ_L, the land carbon-climate feedback, **fell from −57.6 to −19.6 GtC/K** (land carbon at
2100, q10 = 2 vs q10 = 1, on coupled SSP5-8.5, over GMST at 2100; measured in both models,
like for like). Two tests record it, neither modified: `test-climate.R:122` (feedback
0.091 °C, bound 0.1) and `test-mechanisms.R:32` (ENSO switch moves CO₂ 0.28 ppm, bound 0.5).

Both trace to one number. Only soil respires with q10, and a q10 anomaly can only move
carbon a pool can release on the horizon in question — *responding carbon*,
Σ C_j (1 − e^(−100/τ_j)). The two-pool land had ~1470 GtC of it, the four-pool land ~390.
Factor 3.8, against factor 2.9 in γ_L: the metric explains the loss.

**An intermediate soil pool (τ 30–100 yr) was tried offline and does not rescue it**
(`diag_land_topology.R` [4], soil stock held fixed). The trade is ~+0.7 kmol at 1975 — 3 %
of the target — per +100 GtC of responding carbon. Doubling responding carbon to ~730 still
leaves it at half the two-pool value while pushing 1975 from exact to +13 %.
**The bomb ¹⁴C bounds the soil-respiration carbon-climate feedback from above.**

**The escape this model does not have.** Its only carbon-climate feedback is q10 on
heterotrophic respiration. Real land models draw much of γ_L from productivity decline and
disturbance — a temperature dependence of NPP, which this model lacks entirely. If γ_L
needs to be larger, that is where it should come from; the soil route is the one the ¹⁴C
has closed. (γ_L ≈ −20 is at the low edge of what I recall of CMIP6 C4MIP values, roughly
−34 ± 20 GtC/K from Arora et al. 2020 — **recollection, not verified against the paper**;
`gamma_enso`, by contrast, is a *calibrated* parameter with room to absorb its own test.)

### Quarantine

`calibration/output/quarantine/20260812_luc_debit_and_2pool_land/` — `mode_fit.rds`,
`profile_bomb_total.rds` and the run logs, with a README. They were fitted to a model that
created 321.6 GtC and ~28 kmol of ¹⁴C from nothing, **and** to a land whose parameters no
longer exist. `R/cpp.R` now errors on a pre-four-pool parameter list rather than silently
substituting a land the caller did not ask for.

Suite: **380 pass / 4 fail / 2 skip** — same count as the parent, different set.

### Would a stratospheric layer help? — and a framing question it exposed

`calibration/diag_stratosphere.R`, written to answer that, turned up something larger.

**As a DELAY, no.** A one-way stratospheric reservoir of residence τ convolves the source with
an exponential. No single τ reconciles the delivered sum at both reference years: the 1995
column barely moves at any τ (+5.6 % from τ 0.5 to 3), because the source is over by 1980 and a
one-way reservoir has emptied fifteen years later. τ ≈ 3 fixes 1975 exactly and does nothing for
1995. **N&L's own stratosphere is not a delay line either** — holding 4.7 kmol in 1995 from
8.6 kmol in 1975 needs τ ≈ **33 yr** against ~1–2 yr observed exchange, and their
stratosphere/troposphere ratio *falls* 0.321 → 0.269, relaxing toward a **mass** ratio. It is a
co-equilibrating reservoir carrying its share of the excess.

**The framing question.** `diag_bomb_partition.R` compares the model's atmosphere box to N&L's
troposphere alone, and removes their stratosphere from their total, because the bomb source is a
delivery *rate to the troposphere*. **That argument is about timing; it says nothing about
mass.** The box carries `GtC_PER_PPM = 2.124` — the whole atmosphere — while `likelihood.R` fits
its Δ¹⁴C to surface stations. Its *inventory* is whole-atmosphere mass × tropospheric Δ¹⁴C, so
the like-for-like target is troposphere **plus** stratosphere:

| | A (current) | B (proposed) |
|---|---|---|
| atmosphere 1975 | +16.9 % | −11.5 % |
| atmosphere 1995 | −9.1 % | −28.3 % |
| SUM 1975 | +7.2 % | **−2.1 %** |
| SUM 1995 | +5.6 % | **+0.7 %** |

**Under B the budget closes** — the SUM error collapses to the model's own input excess over N&L
(+2.8 % / +0.9 %; the model runs at 102 kmol against their decay-corrected 99.2 / 101.1). That is
what a model which conserves ¹⁴C and is given a prescribed input *must* do, and a "+6–7 %
delivery error" was never physically sensible for one — its apparent existence is what has been
sending sessions after the bomb source shape. **Not changed; flagged for decision**, because B
over-corrects at 1975 (N&L's stratosphere really was more enriched than their troposphere then).
Reporting both framings and scoring on neither is probably right.

**If B holds, the residual is a different defect**: atmosphere short (−11 / −28 %), ocean long
(+4.7 / +8.6 %), biosphere fine. Too much bomb ¹⁴C into the ocean — a ventilation problem.

**Which is also the real case FOR a stratospheric box**, from the other side: the model must
satisfy *tropospheric* Δ¹⁴C observations with a box holding *whole-atmosphere* carbon, so during
the spike it cannot hold the atmosphere's true inventory and the surplus is pushed into the
ocean. Splitting the box lets the troposphere match observations while the stratosphere holds the
enriched remainder — which predicts exactly that signature. It would **not** touch γ_L, the ocean
carbon inventory, or the ¹⁴C production shortfall (a stratosphere adds <1 % of system inventory
against a ~34 % gap). **Cost:** NB 32 → 34, *and* the bomb source rebuilt as an injection rate
rather than a delivery rate, or the delay is double-counted. A package, not a box.

## 2026-08-12 (later still) — The framing question is settled: it is neither A nor B, and the ¹⁴C budget closes

The previous entry left the atmospheric comparison as an A-vs-B decision and recommended
"reporting both framings and scoring on neither." That was the right instinct and the wrong
resolution: **there is a third framing that is actually like-for-like, and it is computable
rather than a matter of taste.**

**The argument.** `R/model.R`'s atmosphere is one box carrying `GtC_PER_PPM` = *whole*-atmosphere
carbon, while `likelihood.R` fits its Δ¹⁴C to `obs_d14c_zonal` = *surface* stations, i.e.
tropospheric air. Its excess-¹⁴C inventory is therefore whole-atmosphere **mass** at a
tropospheric **ratio**. So:

- **A** (vs N&L troposphere alone) is wrong by the entire stratospheric mass.
- **B** (vs troposphere + stratosphere) credits the box with an enrichment a single well-mixed
  box cannot carry.
- **C** (vs N&L troposphere scaled to whole-atmosphere mass) is the like-for-like target, and
  removes from their total only the stratosphere's *enrichment excess over its mass share*.

**The mass ratio is read from N&L's own model, not assumed.** Their Figure 2 (p. 4) puts the
GRACE tropopause at **9 km poleward of 30°, 15 km equatorward** — which is what "22 boxes, six in
the troposphere, 16 in the stratosphere" over six latitude bands means. With the US Standard
Atmosphere at those altitudes, the troposphere is **78.8 %** of atmospheric mass and the
strat/trop mass ratio is **0.2686**. Computed in `diag_bomb_partition.R` from named constants,
not hardcoded.

**An independent check that it is right.** N&L's own stratosphere/troposphere ¹⁴C ratio falls
0.321 (1975) → **0.269** (1995) — landing on the derived mass ratio 0.2686 to three decimals. By
1995 their stratosphere carries exactly its mass share of the excess, so **B and C coincide at
1995** and diverge only at the spike. This confirms both the Figure-2 reading and the physical
claim (from `diag_stratosphere.R`) that the stratosphere is a co-equilibrating reservoir, not a
delay line.

**Result, four-pool land at defaults, `bomb_total` = 102:**

| | 1975 | 1995 |
|---|---|---|
| atmosphere | −7.7 % | −28.2 % |
| biosphere | −0.3 % | +9.6 % |
| ocean | +4.8 % | +8.6 % |
| **SUM** | **−0.7 %** | **+0.7 %** |

**The budget closes to within ±1 % at both years.** The "+6–7 % delivery error" that sent two
handoffs after the bomb source shape **does not exist** — it was the artefact of scoring a
whole-atmosphere box against a tropospheric target. There is nothing for a re-shaped source to
repair, and `data-raw/build_bomb_c14_source.R` does not need reopening on these grounds.

**What the residual actually is:** atmosphere **short** (−8 % / −28 %), ocean **long**
(+5 % / +9 %), biosphere fine. Too much bomb ¹⁴C in the ocean — a **ventilation** problem. The
1995 atmospheric shortfall is the robust number; the 1975 one is sensitive to the tropopause
assumption (−0.6 % to −8.8 % across strat mass fractions 0.15–0.22) and should not be quoted
alone. This is exactly the signature the stratospheric-box mechanism predicts, so that item is
real — but it sits behind the ocean work, not in front of it.

Also noted: the script's own header had claimed the atmosphere "is compared to
troposphere+stratosphere" while the code compared to troposphere **alone**. The prose was closer
to right than the code and neither was exact — a comment that had drifted from its own function.

### γ_L against C4MIP — the recollection was wrong, and it changes the conclusion

The previous entry flagged that "γ_L ≈ −20 is at the low edge of CMIP6" rested on an
**unverified recollection** of "~−34 ± 20 GtC/K, Arora et al. 2020" and was worth ten minutes.
Checked, against two independent sources ([Biogeosciences 17:4173](https://bg.copernicus.org/articles/17/4173/2020/)
and [OSTI 1695755](https://www.osti.gov/pages/biblio/1695755), both quoting the abstract verbatim):

> γ_L = **−45.1 ± 50.6 PgC °C⁻¹**, γ_O = −17.2 ± 5.0 PgC °C⁻¹ (11 CMIP6 models, 1pctCO2 to
> 4×CO₂, BGC−COU approach)

The recollection was wrong on the central value (−45.1, not −34) and wrong on the spread by
**2.5×** (±50.6, not ±20). The spread is the consequential error:

| | γ_L | distance from CMIP6 mean |
|---|---|---|
| two-pool land | −57.6 GtC/K | −0.25 σ |
| **four-pool land** | **−19.6 GtC/K** | **+0.50 σ** |

**Both sit inside ±1 σ.** So the four-pool land's weaker γ_L is *not* an outlier against C4MIP,
and §7's "at the low edge" framing was an artefact of the misremembered spread. The honest
statement is that CMIP6 does not constrain γ_L tightly enough to call this a regression **or** a
correction — the bomb-¹⁴C constraint is the more informative one.

**Consequence for the queue:** temperature-dependent NPP is no longer motivated by a C4MIP
comparison. It remains a genuine structural gap (this model's only carbon-climate pathway is q10
on heterotrophic respiration), but it is a modelling choice, not a defect to be fixed under
deadline.

**Caveat on comparability, stated because it is not innocuous:** Arora's γ_L is 1pctCO2-to-4×CO₂
over 140 years via BGC−COU; ours is land carbon at 2100, q10 = 2 vs q10 = 1, coupled SSP5-8.5,
over GMST at 2100. Different protocol and different warming path. The comparison is fair as
"this model's *total* carbon-climate feedback vs C4MIP's", because q10 is the only such pathway
the model has — but it is not a protocol-matched number and should not be presented as one.

## 2026-08-12 (later still, ii) — Ocean scoping: the ¹⁴C "production shortfall" is arithmetic, not a defect

Mode-independent findings from scoping the ocean-ventilation item while the mode-find runs.
Recorded now, separately from the ventilation scoping itself, because these do **not** depend on
the new mode and one of them **corrects a claim already standing in this file**.

### `prod_c14` is DERIVED, not fitted — the "34 % shortfall" mis-frames a diagnostic

The queue carries "¹⁴C production **359** vs ~545 mol/yr — note it got *worse* with the new land,
382 → 359, and is unexplained" as a large open defect. Measured at the 1750 steady state:

```
total 14C inventory   2955 kmol
implied decay         359.3 mol/yr
model prod_c14        359.3 mol/yr
balance (decay/prod)  1.0000
```

**The model conserves ¹⁴C exactly.** `prod_c14` is whatever balances decay of the model's own
carbon inventory at its own Δ¹⁴C distribution — it is a *readout of the inventory*, not an
independent quantity that can be short. Scoring it against a cosmogenic production estimate
compares two different things.

**And 382 → 359 is the fix working, not a regression.** The four-pool land holds less ¹⁴C, so the
inventory it must sustain is smaller. Reporting that as "it got worse" inverted the sign of the
result.

**Where the gap actually goes.** At 32,827 GtC ocean + 2,130 land + 589 atm = 35,546 GtC total.
Raising the ocean to a realistic ~38,000 GtC gives ~40,700 GtC and **~410 mol/yr**, closing about
a third of the gap (approximate: it assumes the added carbon enters at the current mean Δ¹⁴C,
whereas a biological pump would add it *more* depleted, so the true figure is a little lower).
Reaching 535 mol/yr would require a total inventory of **52,930 GtC, ~1.3× the real world** — so
the residual is not something this model can absorb by fixing its ocean.

**NOT CLOSED, and deliberately not.** The residual is a discrepancy between the carbon-inventory
route and the cosmogenic-production route, and published production estimates span roughly
1.6–2.5 atoms cm⁻² s⁻¹ (≈430–670 mol/yr). **Where the ~545 target came from has NOT been
verified** — that provenance check is what would settle whether there is anything left to explain.
Until then: item (h)'s production line is *mostly arithmetic*, not "large and unexplained", but it
is not resolved.

(Checked in passing and found correct: `T_HALF_C14` = 5700 ± 30 yr, the Cambridge-revised value
used by IntCal and Hua et al. 2022, with `LAMBDA_C14` properly derived from it.)

### Uniform DIC is EXPECTED, and is a different gap from the ventilation one

"DIC exactly uniform with depth" is listed alongside the ocean carbon deficit as an anomaly. A
pure-diffusion ocean with no biological pump and surface-only sources **must** homogenise at
steady state — the uniformity is the *signature of the missing soft-tissue/carbonate pump*, which
is also what makes the inventory ~16 % low. That is a **different missing structure** from the
missing advection behind the ventilation item, and the two should not be merged into one "the
ocean is too simple" task: they have different fixes and only one of them is gated on the mode.

### State of the ventilation machinery (facts, not conclusions)

- `R/model.R`'s interior transport is `add_diffusion` and **nothing else** — there is no advective
  or overturning term. A single `kz` carries the whole column. (`tau_ex` is interhemispheric
  *atmospheric* exchange, not ocean.) Grid: mixed layer `h_ml` over `N_INTERIOR` geometrically
  graded layers, `growth = 1.4`.
- `calibration/profile_kz_ventilation.R` already asks the right question and states its own
  falsification criterion. It is **2 of 7 grid points complete**, those two on the superseded
  two-pool land, and the results are in the quarantine at
  `20260812_luc_debit_and_2pool_land/profile_kz.log`:

  | kz | deep Δ¹⁴C | ocean bomb | bomb_total | bombwin rms |
  |---|---|---|---|---|
  | 500 | −635.7 ‰ | 32.0 kmol | 111.9 | 42.1 |
  | 1000 | −471.1 ‰ | 39.2 kmol | 115.6 | 46.3 |
  | 8354 (old mode) | −115 ‰ | — | 151 | — |
  | *observed* | *−150 to −200* | | *99.3–104.9* | |

- **It is hard-gated on the mode**: line 51 does `readRDS(.../mode_fit.rds)` unconditionally and
  errors without it, and `PROF_KZ_GRID` is centred on the *old* mode's kz = 8354. Re-running it
  before the new mode lands answers a superseded question at ~2.5 h of cost.
- Two cautions for whoever runs it: the bomb-window RMS is **non-monotonic** in kz (42.1 at 500,
  46.3 at 1000), so the grid is not a smooth single-optimum curve; and the profile is a
  **conditional maximum, not a marginal** — the script says so, and it must not be quoted as a
  likelihood.

The mode-dependent half of the ocean scoping — whether one `kz` can serve both the decadal bomb
penetration and the millennial deep age, and therefore whether the fix is a retune or a second
ventilation pathway — is deliberately **not** written down yet. It turns on the new mode's `kz`,
and at defaults the deep ocean is already −194.7 ‰, inside the observed range.

## 2026-08-13 — δ¹³C: the fossil source is fixed, the Suess overshoot is structural, and step 1's premise was backwards

Handoff 12d §0 laid out three steps and said to do them in order. Step 1 — fix the
three σ's — rested on a stated mechanism: the fit loosens `sigma_d13c` to escape "the
one term that would discipline the land sink", so tightening it would discipline `q10`.
That mechanism was argued, not measured. Pricing it before spending a 4 h refit turned
up a different model.

### The measurement that inverted it

`calibration/diag_q10_stream_direction.R` scans `q10` with everything else held, at
fixed σ's, and reports `ccx_loglik(by_stream = TRUE)`. Relative to `q10 = 2.0`, moving
to `q10 = 0.2`:

| stream | at defaults | at the 16-par mode's other parameters |
|---|---|---|
| `d13c_level_MLO` | **+254.4** | **+345.8** |
| `d13c_level_SPO` | **+157.6** | **+293.5** |
| `co2_level_MLO` | −1533.6 | +1169.8 |

**δ¹³C pushes `q10` DOWN at both parameter vectors.** Tightening `sigma_d13c` from the
mode's 0.44 to the prior median 0.1 does not discipline the land sink — it *strengthens*
the force driving the inversion. Step 1 is still worth running; its prediction is
inverted.

### Why δ¹³C wants a bigger land sink

`calibration/diag_d13c_suess.R`. The δ¹³C residual is neither scatter nor a constant
offset: obs − model grows monotonically from ~0 ‰ in 1850 to **+0.58 ‰ by 2020** at MLO
(+0.43 at SPO), with 0.07 ‰ of year-to-year scatter around it. The model reproduces the
*shape* of the Suess decline and overshoots its *magnitude* by ~30 %. Photosynthesis
discriminates against ¹³C, so a bigger land sink is what relieves a too-depleted
atmosphere — hence the pull on `q10`.

### The fossil source: fixed, and worth 3 % of the bias

Sensitivity of the 2015–2024 MLO bias to every provisional ¹³C constant put the fossil
source far ahead of the rest: −28 → −24 ‰ takes it +0.577 → +0.048 with the CO₂ bias
unmoved at +2.33 ppm, where `alpha_photo`, `alpha_as_up` and `alpha_as_down` move it
0.014–0.035 ‰ per ‰. Two concrete defects in the shipped −28, both pushing the same way:

- GCB's `fossil` column is fossil-fuel-**and-industry**, so ~4–5 % of it is **cement** —
  calcined limestone at ~0 ‰, not fuel at −28.
- the value was **constant** across 1750–2024, but the fuel mix ran from all-coal (~−24)
  to gas-inclusive (gas ~−44).

Now built per year from GCB 2025's own by-fuel split (`data-raw/build_calibration_data.R`
[5b]) with citable endmembers — coal −24, oil −26.5, gas −44, cement 0 (Graven, Keeling
& Rogelj 2020; Tans 1981 / Andres et al. 2000 via Bush, Pataki & Ehleringer 2007) — and
carried on the **forcing table**, since it is no longer an invariant. The series runs
**−24.0 (1850) → −28.3 (2024)**, landing on both ends of the −28 to −24 ‰ envelope
Graven et al. state for the global fossil-plus-cement signature.

**It moved the bias 0.577 → 0.561 ‰. Three per cent.** Emission weighting is why: the
early years where the old constant was most wrong carry almost no emissions. The
correction is right and it stays — it was wrong twice over — but the prediction that it
would explain the overshoot was **falsified**, and the sensitivity scan that motivated it
was measuring a counterfactual (the whole history at −24) that the real fuel mix cannot
deliver.

### What else was tried and closed

- **Sink partition** (diag [3]). Closing the δ¹³C bias needs a **~72 % land share**
  (β ≈ 0.9) against GCB's 42 %; that costs **+40 ppm** of CO₂ and a 4.7 GtC/yr land sink
  against GCB's 2.4. δ¹³C and CO₂ cannot both be satisfied by any partition this model
  can reach.
- **Weak isotopic disequilibrium damping** (diag [4]). `ra_ratio`, the gross land loop,
  is the ideal lever — it changes gross exchange while leaving net carbon untouched. It
  moves the bias **0.10 ‰ across its whole plausible range**, and Δ¹⁴C, which is the right
  constraint on gross exchange, goes **+2.7 → −14.6 ‰** over the same range and forbids
  the large values.

### Where that leaves it

The model over-depletes atmospheric δ¹³C by ~0.55 ‰ and none of the source signature, the
fractionation constants, the reachable sink partition, or the gross land exchange
accounts for it. **This is the structural misfit 12d §7 inferred from the whack-a-mole
pattern, now located**: the calibration's only remaining way to relieve δ¹³C is to
manufacture land sink, which is what `q10` → 0.169 is doing. Untested candidate: the
ocean-side disequilibrium, in a pure-diffusion ocean with no biological pump whose DIC
inventory is ~16 % low (§ 12d.4).

**Consequence for step 1, flagged rather than resolved:** Marcus chose the prior medians
(1.5 / 0.1 / 5), partly on my statement that 0.1 ‰ would become the *honest* σ_d13c once
the fossil source was fixed — the residual's year-to-year scatter is only 0.07 ‰. That
premise is now false: the 0.55 ‰ bias survives, so σ_d13c = 0.1 fixes ~450 log-units of
weight onto a residual the model structurally cannot remove.

### Mechanics

The forcing table gains a 10th column. `R/cpp.R` states `CCX_FORCING_COLS` as the
positional contract with `src/ccx_core.cpp` (which reads `f[9]`), since a reorder there is
silent garbage rather than an error. `ccx_forcing_d13c_foss()` returns 0 for a hand-built
zero-emission forcing (the spinup's, the conservation tests') and **errors** for one that
carries emissions without a signature, rather than defaulting to a number nobody chose.

Suite **400 pass / 4 fail / 2 skip** — the same four failures as 12d, plus 12 new guard
assertions. One of those guards exists because the fossil sensitivity scan in diag [2]
went **inert** the moment `d13c_foss` left `aux`: it reported six identical rows while
looking live, until it was rewritten to override the forcing column.

## 2026-08-13 (later) — The δ¹³C overshoot is the price of the pure-diffusion ocean

`calibration/diag_d13c_levers.R` scans the two families the previous entry left untested
— the ocean (`k_w`, `h_ml`, `kz`) and the land **lag** (`tau_wood`, `tau_soil_slow`,
`litter_slow_frac`, `npp_veg_frac`, i.e. the *age* of returning carbon rather than the
gross magnitude `ra_ratio` already covered). Every row carries the CO₂ bias, the Δ¹⁴C bias
and the land-sink share, because a lever that closes δ¹³C by breaking those has closed
nothing.

**`k_w` is the only lever not paid for elsewhere:**

| k_w | δ¹³C bias | CO₂ bias | Δ¹⁴C bias | land share |
|---|---|---|---|---|
| 1500 (default) | +0.548 | +2.33 | +2.65 | 46 % |
| 2500 | +0.259 | +3.63 | +4.59 | 46 % |
| **4000** | **+0.075** | +4.38 | +1.52 | 45 % |
| 6000 | −0.034 | +4.81 | −1.62 | 45 % |

`h_ml` moves the bias 0.085 ‰ across 30–200 m. Every land-lag knob that helps costs
15–50 ‰ of Δ¹⁴C (`tau_wood` 150 → +43.8 ‰; `litter_slow_frac` 0.5 → +51.5 ‰).

**And 4000 is not available.** 1500 m/yr *is* the Wanninkhof global-mean CO₂ transfer
velocity the prior is centred on (DESIGN.md line 102; ~16.5 cm/hr = 1450 m/yr), so 4000
is 2.7× it, **+2.45 σ**.

**The reading.** The model needs more gross exchange than a real piston velocity delivers
because its ocean cannot *maintain* the isotopic disequilibrium. The real ocean does that
by circulation: upwelling continually presents water last in contact with a preindustrial
atmosphere, so the return flux stays isotopically old. A diffusive column has no
upwelling — it smears the Suess signal downward, the water at the surface is already
partly loaded, and the return flux is too depleted. Raising `k_w` fakes it by talking
faster to a reservoir that is too equilibrated; raising `kz` fakes it by burying the
signal, at +13 ppm and +22 ‰ Δ¹⁴C by `kz` = 10,000.

**This is the same missing term ¹⁴C already found.** 12d §2 closed the ¹⁴C budget with the
residual "atmosphere short / ocean long ⇒ **ventilation**". Two isotopes, one gap.
DESIGN §2 rejected HILDA as "too many parameters to communicate" and 12d §10 lists ocean
advection among the deliberate omissions — so this is a **known, chosen limitation now
priced in per mil**, not a new defect. That is the right thing for a communications model
to be able to say about itself.

## 2026-08-13 (later still) — The ventilation term, built and measured: it does not help

The previous entry ended with a suggestion: "the cheapest structural candidate is not full
HILDA but a single prescribed upwelling velocity through the column (one parameter, one
number a reader can be told). Nothing here has costed that." **It is now costed.** The
mechanism was built, gated, and scanned — and the answer is that it is a second knob on
the trade `kz` already makes, not the missing process.

**Built** (`w_up`, m/yr, `R/model.R` + `src/ccx_core.cpp`): the classical
upwelling–diffusion column — water rises through every interface at `w_up` and returns
from the mixed layer to the bottom box in one step (Hoffert et al. 1980; Harvey &
Schneider 1985). One parameter. It cost ~30 lines each side and **nothing else**: the
advective limbs go through `add_flux`, so conservation is structural; a uniform column is
still an exact fixed point, so `ccx_spinup()`'s analytic ¹²C equilibrium and both isotope
solves stand unchanged; and at physical values the substep controller does not move
(the added Gershgorin bound `ccx_advection_eigbound()` is exactly 0 at `w_up` = 0).

**`w_up` is 0 in `ccx_default_params()` and absent from `CCX_PARAM_TABLE`.** The
pure-diffusion model is reproduced *exactly*, and `test-ocean-advection.R` holds that —
with a mutation test, because an inert mechanism would pass the inertness gate trivially.

**Measured** (`calibration/diag_ocean_upwelling.R`). Both knobs buy δ¹³C damping by making
the deep ocean younger; per ‰ of deep-ocean Δ¹⁴C spent, upwelling is **worse**:

| axis | ‰ of δ¹³C bias per ‰ of deep Δ¹⁴C |
|---|---|
| `kz` (w_up 0, kz 3830 → 6200) | **−0.00220** |
| `w_up` (kz 5000, 0 → 2) | −0.00107 (0.5×) |
| `w_up` (kz 500, 0 → 2) | −0.00052 (0.2×) |

Over the whole (`w_up`, `kz`) surface, the best δ¹³C bias among cells whose deep ocean is
still inside the observed −150/−200 ‰ bracket is **+0.501 ‰, at `w_up` = 0**. Holding the
deep age fixed by bisecting `kz`, adding upwelling makes δ¹³C **worse**: +0.548 → +0.628
at `w_up` = 1 (the compensating `kz` falls 5000 → 3062 and stops burying the depleted
carbon faster than the upwelling limb removes it). At `w_up` ≥ 2 the deep age is
unreachable at *any* `kz` — the sinking limb alone over-ventilates the bottom box.

**Why, in one number.** For upwelling to hold the mixed layer out of isotopic equilibrium
it has to flush it faster than the atmosphere re-equilibrates it. Measured at defaults:
gross air-sea exchange **27.1 GtC/yr** against a **284 GtC** NH mixed layer = **10.5 yr**
(the textbook ~10 yr). Flushing at 4 m/yr through 75 m takes **18.8 yr — 1.8× too slow**;
the crossover is `w_up` ≈ 7 m/yr, ~80 Sv, about **4× the real overturning** (20 Sv over
this model's ocean area is 1.75 m/yr). A global-mean overturning cannot outrun air-sea
exchange, and it is not close.

**The mechanism works and still loses, which is the actual finding.** At `w_up` 4 /
`kz` 1000 the upwelled water genuinely arrives old — the ml→oc1 δ¹³C gap widens 0.167 →
0.584 ‰ — and the mixed layer still ends up *more* depleted (−1.910 vs −1.619 ‰) than with
no upwelling at all, because the `kz` that lets the advective signal survive is the same
`kz` that was burying the depletion. **No purely vertical rearrangement can decouple "the
surface stays undepleted" from "the deep stays old" in a single column. They are the same
transport.** That retires "just add advection" with a measurement rather than a judgment,
and it means the ventilation caveat in the previous entry stands as written.

**Where it points instead, untested and needing a citation first.** The model's mixed
layer declines **1.619 ‰** over 1750–2024 against an atmospheric **2.834 ‰**, a ratio of
**0.57**. My *recollection* of the observed oceanic Suess effect is a surface-DIC decline
of ~0.6–0.9 ‰ against the atmosphere's ~1.9, a ratio near 0.35–0.45 — i.e. the model's
surface ocean would be tracking the atmosphere about twice as closely as the real one
does. **That number is unverified** (nothing in DATA.md, nothing in the local Papers
folder; Quay et al. and Eide et al. 2017 are where to look). If it survives checking, the
gap is not a transport term at all but the single well-mixed surface box: the real ocean
keeps its disequilibrium with *horizontal* structure, and a global mean of a product is
not the product of the global means. That is a second surface box — the outcrop/HILDA
structure DESIGN §2 rejected — and a bigger decision than a diagnostic can take.

Suite **418 pass / 4 fail / 2 skip** — the same four failures, plus 18 new guards.

## 2026-08-13 (later still, cont.) — The other configuration: deep water straight to the surface

Marcus asked for the mechanism the previous entry did **not** test: deep water reaching the
surface *without passing through the intermediate layers*, as a Southern Ocean outcrop. The
entry above built the mirror image — its non-local limb runs **downward** (ml → bottom),
with a layer-by-layer ascent. So the ask was a different operator, and in the way that
matters: under `w_up` the water arriving at the mixed layer comes from `oc1`, which is
diffusively slaved to it (an ml→oc1 δ¹³C gap of only 0.167 ‰), while an outcrop delivers
bottom water at the full preindustrial contrast.

**Built** as `w_out_NH` / `w_out_SH` (m/yr, per hemisphere — the real outcrop is a Southern
Ocean feature and the two ocean columns exchange only through the atmosphere). Both default
0, both absent from `CCX_PARAM_TABLE`.

**It ties the first configuration exactly, and that is the finding.** At equal `w` the two
give identical CO₂, δ¹³C, Δ¹⁴C, ocean and land carbon — to **~1e-10**, at every `kz` from
10 to 5000. Not similar: *tied*. They are the same closed loop traversed in opposite
directions, so their transport operators satisfy

> **A_out = D · A_upᵀ · D⁻¹**,  D = diag(dz)  — verified to **1.7e-18**

and interior diffusion is self-adjoint in the same weighting (**2.2e-16**), so it does not
break the relation. A transpose preserves the *diagonal* elements of the propagator, and
**the mixed layer is the only box through which the ocean touches the rest of the model** —
air-sea exchange acts at `iml` and nowhere else. So the atmosphere sees the column
exclusively through an ml→ml response that is invariant under reversing the circulation:
`|ml→ml difference|` = **4e-17** over 100 yr, against a largest difference anywhere in the
propagator of **0.27**.

**This is what makes the negative result general.** It is no longer "one advection scheme
failed" but "no reversal or rerouting of a closed vertical loop can change what the
atmosphere sees". Only something that changes the **mixed layer's own budget** can: a second
surface box, or the air-sea flux itself. The direct check agrees — with `kz` bisected to
hold the deep age, the outcrop makes δ¹³C **worse** (+0.548 → +0.608 at 4 m/yr SH-only),
exactly as the classic UD did (+0.628 at 1 m/yr).

**A correction to the previous entry's "one number".** The 10.5 yr equilibration vs 18.8 yr
flush ratio bounds how *fast* the mixed layer is renewed, not how much good the renewal
does; those come apart when the arriving water is very different from the ml. Renewing with
fully preindustrial water would leave the ml at τ_flush/(τ_flush + τ_eq) = **0.64** of full
equilibrium at 4 m/yr — a 36 % cut. So that argument alone did **not** rule out a non-local
deep-to-surface path; the operator symmetry is what rules it out.

**The off-diagonals are not tied, and there the outcrop is the better-behaved one.** At
4 m/yr the deep ocean sits at **−108 ‰** (both hemispheres) or **−135 ‰** (SH only) against
**−100 ‰** for classic UD, because the descending limb has to traverse the whole column
(~depth/w years) instead of injecting modern surface water into the bottom box directly —
and in the preindustrial steady state the water then ages monotonically downward, the
observed sense of the profile rather than its inverse. None of that reaches the atmosphere.
An SH-only outcrop also leaves the MLO−SPO δ¹³C gradient essentially untouched
(−0.226 ‰ vs −0.218 ‰ at `w_out_SH` = 4, against an observed −0.074 ‰ over 1993–2014).

Suite **426 pass / 4 fail / 2 skip** — the same four failures, plus 8 more guards.

## 2026-08-13 (later still, cont.) — The oceanic Suess effect, measured at last: the mixed layer is right and the atmosphere is not

Handoff 13b §6 left one lead open: *"the oceanic-Suess lead is still unverified. Model ml
declines 1.619 ‰ over 1750–2024 vs the atmosphere's 2.834 (ratio 0.57); my recollection of
the observed ratio is 0.35–0.45. No source in DATA.md, none in ClaudeDocs/Papers. If it
holds it is independent evidence for §4 [the conveyor]."* Marcus (2026-08-13) chose to
verify this **before** deciding whether to build the conveyor. **The lead does not hold,
and it fails in the direction that matters.**

**Two observational anchors acquired** (`DATA.md` §2b, `data-raw/download_data.R` [6b],
`build_calibration_data.R` [8b] → `data/obs_oceanic_suess.rds`):

- **Quay et al. 2003** (GBC 17(1):1004): global mean surface DIC δ¹³C fell
  **0.16 ± 0.02 ‰/decade** between the 1970s and 1990s. Has an error bar, and is
  independent of the atmospheric δ¹³C target the model already fits.
- **Eide et al. 2017** (GBC 31:492–514; data PANGAEA 871993, CC-BY): the gridded full
  ¹³C Suess effect. Reduced here to an area-weighted depth profile — **0.916 ‰ at 0 m,
  0.782 ‰ over 0–75 m**, preindustrial → GLODAPv1.1 era.

**The recollected ratio was wrong in both value and sign.** Measured, the observed ocean/
atmosphere ratio is **0.56** (cumulative, Eide) to **0.71** (rate, Quay); the model's is
**0.53–0.55**. The real ocean tracks the atmosphere *at least as closely* as the model's
does, not less closely. **Retracted as evidence for the conveyor.**

**And the ratio was the wrong statistic — it hid which limb is broken.** Split:

| | mixed layer | atmosphere |
|---|---|---|
| default params (`h_ml` 75 m) | **0.156 ‰/dec vs Quay's 0.160 ± 0.020 (−0.2 σ)** | **+25 % too fast** |
| posterior mode (`h_ml` 179 m) | 0.145 (−0.8 σ) | +21 % too fast |

The ml result is **window-insensitive** (0.153–0.160 across six plausible Quay windows) and
the atmospheric result **reproduces against Scripps flask** as well as Law Dome (model
0.291 ‰/dec over 1980–2014 against MLO 0.256 / SPO 0.233), so it is not an ice-core
smoothing artefact. Cumulatively the ml is +17 % too depleted at 75 m; the mode's +54 % at
179 m is **not a fair test** — a well-mixed 179 m box against a depth-average crossing the
real thermocline is not apples to apples, and is one more sign the fitted `h_ml` is not a
mixed-layer depth.

**The model's ocean takes up ¹³C at the observed rate. The δ¹³C misfit is not the ocean
failing to absorb the depleted signal.**

**Consequence for the conveyor, computed before building it** (`diag_oceanic_suess.R`
part 4). §4.3's mechanism *is* a reduction in ml depletion — the ml sits at
τ_flush/(τ_flush + τ_eq) of full equilibrium. Applying that factor to a ml Suess rate that
is already correct:

| Sv | equilibrium fraction | ml rate after | vs Quay |
|---|---|---|---|
| 15 | NH 0.70, SH 0.77 | 0.115 ‰/dec | **−2.2 σ** |
| 27 | NH 0.57, SH 0.65 | 0.095 ‰/dec | **−3.2 σ** |

**The conveyor pays for the atmosphere with the one ocean quantity that is currently
correct.** Both figures are conservative: the neglected feedback (a less depleted
atmosphere gives the ml less signal to follow) pushes the same way. The deep-age benefit is
not in question — the diagnostic reproduces §4.3's 1536 yr transit at 27 Sv exactly, an
independent check that the two scripts share constants.

**The caveat that keeps this honest, stated because it cuts both ways.** An atmosphere
declining 25 % too fast, driving a mixed layer that lands *exactly* on the observed rate,
implies the model's air–sea ¹³C transfer is ~20 % too **weak**: the ml looks right partly
through compensating errors, not because ocean ¹³C physics is verified. So "the ocean is
right" describes the model as it stands, not a proof. What survives regardless is the
**scoring** consequence — from here, any change that lowers the ml Suess rate makes the
model worse against a real measurement with a real error bar, and **until now nothing in
the likelihood would have noticed**.

**Verified, not assumed, about the Eide product:** above 200 m its field is the 200 m
back-calculation **plus a spatially constant depth offset** (level-to-level differences
have sd exactly 0; their method builds the shallow field from the 200 m estimate plus
coral/sclerosponge surface records). The global mean is usable; **the NH/SH contrast above
200 m is inherited and must not be used to score a hemispheric gradient.** The build
re-asserts this on every rebuild rather than trusting the comment.

**Open, and Marcus' call:** promote Quay's rate to a likelihood term. It is the only new
constraint here with a stated uncertainty, it is independent of the atmospheric δ¹³C
target, and it pins the air–sea partition that `q10` has been free to trade against.
**`sigma_d13c` remains unset and still blocking; this does not change the 0.45 ‰ argument**
(it removes a hoped-for route to shrinking the gap rather than shrinking it).

**Where the conveyor pre-check is weak, said plainly.** It applies §4.3's own equilibrium
fraction to the *current* ml rate, which treats the pre-conveyor mixed layer as if it were
at full isotopic equilibrium — §4.3 derives its "37 % cut" the same way, so the two are
consistent, but both ignore that the model **already** ventilates the ml diffusively. The
offsetting term is real and points the other way: §4.5 step 3 expects `kz` to fall a long
way once a conveyor carries the ventilation, and a smaller `kz` exports less depleted
carbon out of the ml, pushing its depletion back **up**. **So −3.2 σ is an upper bound on
the damage, not a prediction.** What the pre-check establishes is the **sign**, and the
fact that the trade is now scoreable at all — not the size of the miss. Only the run
settles that, which is why this is **a gate to run the conveyor against, not a veto**.

## 2026-08-13 (later still, cont.) — Conveyor APPROVED; configuration red team finds §4.3 divided by the wrong volume

Marcus approved building the conveyor and asked for a red-team review of the available
configurations through four lenses (ocean / atmosphere / isotope / reduced-complexity),
explicitly including the refit: *"once it is in properly, the other constants might all
shuffle around into a new equilibrium and I would like to test that."* Review in
`notes/redteam_2026-08-13_conveyor_configurations.md`; arithmetic folded into
`calibration/scoping_conveyor_arithmetic.R` so every number regenerates.

**§4.3's headline arithmetic divides by a volume the §4.2 plumbing does not traverse.** It
uses `V_deep` = the whole sub-mixed-layer ocean (1.309e18 m³); under §4.2's own four limbs
the water path is NH bottom → SH bottom → up the SH column → SH ml → NH ml =
**9.13e17 m³, 70 %**. **NH `oc1`–`oc9`, 30 % of the deep ocean, receives no advective flux
at all.**

**Correcting that and §4.3's own source-water caveat, the two errors nearly cancel:**

| basis | Sv for deep Δ¹⁴C = −170 ‰ |
|---|---|
| `V_deep`, no source correction (§4.3's headline) | 27.1 |
| `V_deep`, source −51.2 ‰ (§4.3's own hedge) | 37.7 |
| `V_path`, no source correction | 18.9 |
| **`V_path`, source −51.2 ‰ — the honest number** | **26.3** |

So the headline survives but **§4.3's hedge ("moves the −170 point to ~37 Sv") is too
pessimistic by 11 Sv**. The conveyor's strongest selling point is in better shape than the
handoff thought.

**But 27 Sv is far above the AMOC that actually has an error bar** — RAPID 26°N gives
**16.9 ± 1.2 Sv** (2004–2020). At 16.9 Sv on the real path the deep goes to **−230 ‰**,
outside the model's own [−150, −200] bracket. **The "27 Sv reproduces −170 ‰ from transit
alone" headline is retired**; the claim that survives is a **joint (Q, `kz`)** result —
transit sets the floor, diffusion mixes back the other way. Weaker, true, and still a large
improvement on bounding `kz` until the deep age came out right.

**The strongest case for building is not δ¹³C — it is `kz`.** At 5000 m²/yr it is **~9× the
measured thermocline diapycnal diffusivity**: Ledwell's NATRE tracer release gives
(1.7 ± 0.2) × 10⁻⁵ m² s⁻¹ = 536 m²/yr. A conveyor is what lets `kz` become an eddy
diffusivity instead of a fiction.

**Verified and consequential: the preindustrial column is EXACTLY uniform in DIC**
(2.0379 mol/m³ at all 11 levels, spread 2e-14 %). Advection is therefore a **pure isotope
operator** preindustrially — which is the clean decoupling on offer, and equally means it
**cannot** fix the ~14 % low ocean carbon inventory and **is not a biological pump**. The
limb is not small either: **20.8 GtC/yr at 27 Sv against 27.1 GtC/yr of gross air–sea
exchange.**

**Configurations.** A (§4.2 as written) is rejected as a final answer: sinking NH ml
straight to `oc10` leaves `oc1`–`oc9` on `kz` alone, so once `kz` falls the NH gets young
bottom water under anomalously old mid-depth water — an inversion the Atlantic does not
have — and it plumbs a limb named "NADW" to AABW depth. **Recommended: build C (sink to
NADW depth, `oc8`/`oc9`), with B (distributed descent) as the cheap comparison and A as the
intermediate they are diffed against; F (build nothing) stays the scored baseline.** D
(two-cell NADW+AABW) and E (second surface box / HILDA-lite) deferred.

**The refit is the point, and it needs prerequisites.** `kz`'s [3830, 6200] bracket **must
be deleted, not carried across** (12d §6 derives it on the pure-diffusion column), so the
honest accounting is *one parameter added and one constraint removed*. Q and `kz` are a
degenerate pair — both ventilate — so the deep-Δ¹⁴C likelihood term (12d §0 step 2) is now
a **prerequisite**, with Quay's ml Suess rate as the second leg. **Four predictions stated
in advance so they cannot be retrofitted:** `kz` falls toward 500–2000; `h_ml` falls from
179 m (currently 88 % of the way up its [30, 200] bound); `tau_ex` rises as the ocean takes
over part of the interhemispheric transport; MLO−SPO δ¹³C shrinks from −0.218 ‰ toward the
observed −0.074 ‰ **and may overshoot past zero**. *If `kz` does not fall and `h_ml` does
not come down, the conveyor is not doing the job it was proposed to do, whatever happens to
the log-posterior.*

**Cost corrected: 2–3 days, not §4.2's half a day** — the plumbing is half a day, but the
per-hemisphere deep diagnostic, the reverse-conveyor gate, the new likelihood terms, the
`kz` re-derivation and **~4 h per `run_modefind.R` refit × 4 refits** are not.

**One self-correction folded in.** `diag_oceanic_suess.R` inferred that air–sea ¹³C transfer
is ~20 % too weak. That is in tension with τ_eq = C_ml/F_gross = 10.5 yr (NH) / 10.0 (SH),
which is the textbook mixed-layer ¹³C equilibration timescale — isotopes ride the gross flux
unbuffered, so this is one of the model's better-grounded numbers. If τ_eq is right the
20 % lives elsewhere, most likely `h_ml`. Left open; the refit is what separates them.

## 2026-08-13 (later still, cont.) — The conveyor built and measured: the ml-Suess objection is dead, §4.4's own prediction fails

Marcus approved the red team's recommendation (build C, B as comparison, A as intermediate).
Built, tested, and measured. `R/model.R`, `src/ccx_core.cpp`, `R/spinup.R`,
`tests/testthat/test-conveyor.R`, `calibration/diag_conveyor.R`.

**§4.2's spinup claim is wrong, and it would have been invisible.** The handoff states
`ccx_spinup()` "needed no change at all" because a uniform ocean is still an exact fixed
point. **True within a column, false between them:** the two columns sit at different DIC
(SST 18 vs 16 °C → 2.03786 vs 2.05570 mol/m³), so the interhemispheric limbs see a real
gradient and converge 0.135 GtC/yr into the NH at 20 Sv. Skipping the solve leaves a
1.35e-01 residual and **−0.915 ‰ of spurious δ¹³C drift** over a zero-emission 1750–2024
run — nearly **twice** the entire misfit the conveyor was proposed to fix. Diagnosed, not
guessed: `sst_NH = sst_SH = 17` returns both to their conveyor-off values exactly. An
ocean-only solve was tried first and was *also* wrong — pinning both atmospheres at 278 ppm
left 0.1226 GtC/yr in the two atmosphere boxes, because the conveyor makes one hemisphere
outgas and the other ingas and the preindustrial atmosphere must carry a small gradient.
`ccx_c12_steady_conveyor()` is a Newton on the **full state** using `ccx_deriv()` itself as
the residual, global CO₂ pinned and the split free. Residual 1e-13, drift 0, R/C++ parity
exact. **Physically this also means the conveyor is not the pure isotope operator between
columns that it is within one — it is a crude solubility pump.**

**The reverse-conveyor gate passes.** Reversed, the atmosphere differs (0.15 ppm CO₂,
1.8 ‰ Δ¹⁴C) and the deep ages **swap**: forward NH −113 / SH −157, reversed NH −159 /
SH −120; conveyor off they are equal (−170.8 / −169.5). Read off an **integrated** run —
the conveyor touches no atmospheric box directly, so a derivative-level assertion could
never fail, which is how the first version of the gate was written and why it "tied".

**The red team's ml-Suess objection was wrong by 4×, in the way the red team said it might
be.** It estimated −3.2 σ against Quay while flagging that as an upper bound because a
falling `kz` pushes back. Measured at fixed `kz`: 0.156 → **0.147 at 20 Sv (−0.6 σ)**. And
once `kz` falls the rate goes the **other way and overshoots from above** — 0.185 at
kz 2000, 0.212 at kz 1000, 0.237 at kz 500. **`kz` is now squeezed from both sides** (deep
age wants it small, ml Suess wants it large), which is a better position than the
degenerate ridge that was predicted.

**The structural win is real: the deep ocean goes bipolar.** Off, both hemispheres are the
same age. On (C, 20 Sv): kz 5000 → NH −113 / SH −157; **kz 2000 → NH −159 / SH −223**;
kz 1000 → NH −214 / SH −277. That is the observed sense (young ventilated end, old far
end). **But `CCX_PARAM_TABLE`'s [−150, −200] bracket is a global-average target derived on
a single-column ocean and is the wrong yardstick for a bipolar one** — the deep-Δ¹⁴C target
must be chosen *before* the refit, not after seeing this table. **Flagged for Marcus, not
resolved.**

**Two results against the proposal:**

1. **§4.4's falsifiable prediction FAILS.** It states the conveyor should shrink the NH−SH
   δ¹³C gradient and that "if the gradient does not shrink, the mechanism is not doing what
   this section says." MLO−SPO goes **−0.218 → −0.221 (20 Sv) → −0.223 (27 Sv)** — very
   slightly the *wrong* way, against an observed −0.074. Falling `kz` recovers only −0.215.
2. **`kz` cannot actually fall far**, which was the strongest argument for building at all.
   Dropping it degrades both remaining constraints: δ¹³C bias +0.500 → +0.678 (kz 2000) →
   +0.820 (kz 1000), CO₂ bias +5.4 → −5.8 → −12.5 ppm. At *fixed* kz the conveyor helps
   δ¹³C (+0.548 → +0.500 at 20 Sv, +0.483 at 27 Sv) — real, and about a **third** of §4.3's
   hoped 0.15–0.25 ‰.

**None of this is a verdict.** Every parameter except `q_conv` and `kz` is frozen at its
default; `k_w`, `h_ml`, `beta` and `q10` are all free to absorb some of it. **The refit is
the experiment** and the red team's four advance predictions are still the scorecard — on
this evidence the fourth is already in trouble.

Suite **462 pass / 4 fail / 2 skip** — the same four pre-existing failures, +36 assertions.
`CCX_PARAM_TABLE` untouched; `sigma_d13c` still open and still blocking.

**Preindustrial interhemispheric gradient — is it observable?** (Marcus asked, 2026-08-13.)
The conveyor gives the preindustrial atmosphere a gradient it did not have: **+0.149 ppm
CO₂** and **+2.40 ‰ Δ¹⁴C** at 20 Sv (both exactly 0 and +1.00 ‰ with it off).

- **CO₂, Greenland vs Antarctic ice: NO, and not marginally.** Greenland ice CO₂ runs
  **20–30 ppm above** the Antarctic composite with a standard deviation of **6–10 ppm**
  (Antarctic 2–3), from **in-situ production** by carbonate–acid reactions and oxidation of
  organics on Greenland's much higher carbonate load (~0.4 ± 0.2 µmol/L). Anklin et al.
  1995; Barnola et al. 1995; Tschumi & Stauffer 2000. **The artefact is ~150× the predicted
  signal and the scatter alone ~50×.** Antarctic cores are the reliable CO₂ record
  *precisely because* Greenland's are not, so no ice-core pair constrains this.
- **Δ¹⁴C: YES, and it is the apposite test.** **SHCal20 puts the SH 36 ± 27 ¹⁴C yr older**
  than the NH = **+4.49 ± 3.38 ‰** on the Libby mean life. The model goes from **+1.00 ‰
  (22 % of central, z −1.04)** to **+2.40 ‰ (53 %, z −0.62)**. Right direction, about half
  the gap closed — and it matters more than the arithmetic suggests, because the observed
  offset is driven substantially by **Southern Ocean upwelling of ¹⁴C-depleted water**,
  exactly the limb the conveyor adds. Honest limit: ±27 yr is too wide to discriminate
  strongly, and OFF is also inside 1 σ. **This is the independent, already-observed test
  §4.4 wanted and did not get** — a third candidate likelihood term for Marcus.
- **One unverified lead, flagged not adopted:** a search result attributed to a CanESM1
  preindustrial control states the preindustrial CO₂ gradient was **reversed** from today's
  (SH higher). If true our +0.149 ppm has the wrong **sign**. From a model paper via a
  search snippet, not observations, and not read. Check before the sign is ever quoted.

Handoff: `notes/handoff_2026-08-13c_conveyor_built.md`.

## 2026-08-13 (d) — Expert panel: model structure against the PEDAGOGICAL spec

Marcus asked for a **carbon-cycle expert** added to the ocean / atmosphere / ecosystem /
isotope / pedagogical / reduced-complexity lenses, to settle the best model structure given
the goal of matching monthly CO₂ and isotopes *understandably* — motivated by the "**5-year
CO₂ residence time**" and "**CO₂ correlates with temperature**" arguments. **That motivation
had never been written down as a specification**; DESIGN §1's four goals do not contain it.
This session treats the two fallacies as design requirements and measures the model against
them. Panel: `notes/expertpanel_2026-08-13_structure_for_pedagogy.md`; every number
reproduced by `calibration/diag_pedagogy.R` (~3 s), which carries its results in its header.

**The structure the two fallacies demand is already built.** From one spinup, one parameter
set, two paired perturbations — a **100 GtC mass pulse** and a pure **¹⁴C label pulse**:

| yr | mass airborne | label remaining |
|---|---|---|
| 1 | 0.893 | 0.811 |
| 10 | 0.604 | 0.292 |
| 100 | **0.262** | **0.058** |
| 300 | 0.171 | 0.029 |

**Instantaneous label decay time 4.32 yr** — *the model hands you the sceptic's own number,
computed correctly, as a property of gross exchange* — against a mass 1/e of **40.3 yr** and
a **4.5× gap at 100 yr**. The gross-flux architecture that does this exists **because the
isotopes forced it** (`model.R:278`, the singular preindustrial isotope operator, 2026-08-10).

**Temperature → CO₂ is real, right-signed, and an order of magnitude too small.** +1 K held
with zero emissions gives **+5.19 ppm @10 yr, +10.74 @300 yr** ≈ **10.7 ppm/K**; against the
model's own 1.20 K of 1960–2023 warming that is **12.9 of the 102.5 ppm rise — 13 %**.
**The isotopes decide it by sign:** splitting the +1 K response at 300 yr, the solubility
limb (ocean outgassing) moves δ¹³C **+0.0354 ‰ — UP**, the land limb −0.0760, both −0.0410,
against an observed/model **−1.773 ‰**. *"The warm ocean is outgassing it" predicts δ¹³C
rising; it falls, by 1.77 ‰, and even the right-signed land limb is 43× too small.* Model
ocean is a **net sink**: +172.6 GtC cumulative, +2.60 GtC/yr over 2015–2024.

**The model reproduces the sceptic's headline statistic.** cor(CO₂ **growth rate**, GMST) =
**+0.930** over 1960–2023 while 100 % of its trend is emissions-driven; detrend both and
r = **0.582** — the genuine ENSO link, which explains wobbles, not the rise.

**The ocean-structure debate is nearly irrelevant to any of this.** Conveyor C at 20 Sv with
`kz` 2000 moves AF@100 **0.262 → 0.284**; choosing a **2024 background** instead of
preindustrial moves it **further, to 0.298** (turnover 7.13 → 9.25 yr). **A control the app
already exposes outweighs the whole conveyor question.** Decide the conveyor on
oceanography — but **it is not blocking the app**, and the panel endorses handoff 13c §0.1
that `sigma_d13c` must not be blocked on it either.

**The one structural gap that does matter: `ccx_run()` emits no fluxes.** It returns stocks
and ratios only; `add_flux()` computes the gross fluxes and discards them. So the central
pedagogical quantity (τ_turn = M_atm / F_gross) is not computable from model output — above
it had to be recovered *indirectly* from a label-pulse slope — and the "Under the hood" box
diagram (`app/server.R:213`) draws **six unlabelled arrows**. **R1: an opt-in flux trace.**
No physics changes and the conservation test gains a free extra check.

**Two defects found while measuring.**
- **74.1 GtC of pre-1850 LUC emissions are invented, silently.** GCB's LUC is `NA` for
  **1750–1849**; `ccx_annual_to_monthly()`'s `approx(rule = 2)` holds the 1850 value flat
  backwards. The forcing carries **321.6 GtC of LUC against 247.5 in the source — 23 % is
  extrapolation.** Not a conservation error (LUC is a veg→atm transfer) and a nonzero
  pre-1850 flux is defensible; **the objection is that nobody chose it** — GMST's identical
  flat-hold warns on every build and `d13c_foss`'s carries a justifying comment. **R3,
  flagged as a methodological choice for Marcus, not resolved.**
- The box diagram says **"Vegetation / Soil"** against a **four-pool** land model
  (`model.R:80`, since 2026-08-12) — labels-vs-structure drift. **R6.**

**Also recommended:** **R2** a "no emissions" counterfactual (the switch list lets a user
turn off every *sink* but not the *source*); **R4/R5** the two tabs the project's stated
purpose actually lives in — *"How long does it last?"* and *"Does temperature cause CO₂?"* —
neither of which exists in DESIGN §7; **R7** adopt the Joos et al. (2013) CO₂ IRF as a §6
sanity gate, because **nothing in the eleven gates scores the pulse response**, which is the
quantity the app's flagship tab reports. *(The model's AF@100 on a 2024 background is 0.298;
my recollection of the multi-model IRF is ~0.4, which would make this pulse decay too fast —
**stated as a test to run, not a finding**, and the paper has not been checked.)*

**Everything here is at `ccx_default_params()`, not the posterior mode** (`h_ml` 179 m,
`kz` 6031, both pushing toward more uptake and a shorter adjustment time). **The
pedagogical curves must be recomputed at the mode before anything ships.** Ocean uptake at
defaults is 2.60 GtC/yr against GCB's 3.22 — 19 % low, a known consequence of not using the
mode, not a new finding.

**Verdict: the model is at the right complexity and the risk now is drift upward.** The
highest-value remaining work is an output layer, a two-line switch, a provenance fix and two
tabs of existing material — **none of them adds a box or a parameter.**

## 2026-08-13 (e) — Marcus' four directives from the expert panel

All four of the panel's blocking items answered. **Suite 490 pass / 4 fail / 2 skip** — the
same four pre-existing failures throughout.

### 1. The flux trace (R1) — approved and built

`ccx_run(fluxes = TRUE)` now returns the gross and net fluxes `add_flux()` was discarding.
The recorder is a **tap inside `ccx_deriv`'s own** `add_flux`/`add_source`/`add_diffusion`,
not a second derivation: `test-fluxes.R` asserts the recorded per-box carbon equals
`dy[, "C"]` **exactly**, which is the completeness check *and* a free extra conservation
check on the core. Edges are classified by the **reservoir type of their endpoints**, so a
flux added later is captured automatically; explicit labels exist only for the three cases
where one endpoint pair carries two processes (seasonal NEP vs GPP, land-use vs autotrophic
respiration, ENSO vs heterotrophic). `ccx_run_fast()` — the C++ core the sampler calls — is
untouched and `fluxes` defaults `FALSE`.

**The app's box diagram now carries the numbers** (R6): ~72 GtC/yr photosynthesis and
~95/93 each way air–sea against ~11 of emissions, and land boxes that admit to four pools.

**And it corrected a number in a deliverable.** τ_turn = M_atm ÷ gross outflux = **4.69 yr
at 1750, 5.32 by 2024** — not the 4.32 yr the panel note and `diag_pedagogy.R` reported
from a one-month label slope. Seasonal NEP is a real atm→leaf flux that integrates to zero
annually, so it is excluded from the gross outflux: right for the annual mean, wrong for a
January finite difference, which the January drawdown biases fast. **Tested, not argued** —
with seasonality off the two independent routes agree to **0.2 %** (4.700 vs 4.692).

**Also:** `gamma_enso = 0` added to `ccx_default_params()`. It was **absent**, so
`ccx_deriv()` died with "argument is of length zero" on default parameters while
`ccx_cpp_par()` silently substituted 0 — an **R-vs-C++ divergence about what the defaults
mean**, which is what the bit-parity rule exists to prevent. 0 is behaviour-preserving; the
table's init of 0.5 would have silently changed every existing default-parameter result.

### 2. Pre-1850 land-use emissions (R3) — sourced

GCB's LUC column is **empty before 1850**; `approx(rule = 2)` held the 1850 value flat
backwards, **inventing 74.1 GtC** — 23 % of the model's land-use carbon. Replaced with
**OSCAR v3.1** (Gasser et al. 2020, *Biogeosciences* 17:4075, doi:10.5194/bg-17-4075-2020;
data doi:10.5281/zenodo.7313542, CC-BY), which runs from 1701 and reproduces that paper's
headline **206 ± 57 PgC** exactly — the check that the right column was read.

**Rescaled, not spliced raw:** OSCAR's 1850–2018 total is 34 % below GCB's, so grafting its
absolute values on would put a **62 % step** at the join. OSCAR supplies the shape and the
pre/post share, rescaled over an 1850–1900 overlap adjacent to the splice. **41.8 GtC, 6 %
step.** Scored against Law Dome 1750–1850 (`diag_pre1850_luc.R`): adopted **2.00** ppm RMSE,
flat-hold 2.48, OSCAR absolute 2.77, **zero 4.50 — zero is excluded by the data**. The
flat-hold was not absurd, just the right integral over the wrong shape (too big too early:
+3.8 ppm at 1775 against the adopted series' +1.0).

**Two things it does NOT fix:** every option is **~6.5 ppm low at 1900** and none reproduces
the full 18th-century rise — a separate 19th-century deficit, larger than this question.
And **`mode_fit.rds` now predates the forcing and is stale.**
`ccx_build_forcing()` warns on any NA emissions year inside the window so this cannot recur.

### 3. Joos et al. 2013 (R7) — DESIGN §6 gate 12, and future pulses

Marcus supplied the paper. **Two answers, pointing different ways, both reported:** the
**point** IRF is below the multi-model mean at every horizon (0.313 vs **0.409** at 100 yr —
so the recollection recorded as an unverified test was right about Joos), but the
**time-integrated** IRF, the quantity Joos actually puts ranges on, is **inside the 5–95 %
range at 20, 50 and 100 yr** (12.6 / 26.2 / 43.6 against 12.2–16.3 / 24.0–36.6 / 39.5–65.2).
**The honest headline is the second with the first as caveat** — the panel note's flat
"decays too fast" overstated it. The model is on the **low side of the literature but within
it**, which is the *conservative* direction for the app's argument.

It also reproduces Joos's **PI < PD ordering** (39.2 vs 46.3 yr against his 34–47 / 45–62) —
a Revelle result — and on **coupled** SSP backgrounds IRF@100 rises monotonically
**0.342 (ssp126) → 0.512 (ssp585)**, with IRF@20 of 0.62–0.71 against Joos's "~70 % within
two decades in every scenario".

**Three method failures, recorded because two looked correct.** An online controller for
Joos's diagnosed compatible emissions needs `ccx_deriv` in the stepping loop (~60k pure-R
calls per run). A **Newton step on the monthly drift diverges to 2e34 ppm** — the response
operator is lower-triangular, not diagonal, so per-month correction compounds; a
least-squares solve on a relaxation-exponential basis holds the background to 0.26 % in
0.3 s (**a polynomial basis must not be added back — ill-conditioned, diverges**). And the
**SSP emissions table is decadal**, so adding the pulse to the 2050 row delivered **1000 GtC
for a nominal 100**, giving an IRF of 6.9 — impossible by inspection, since an IRF cannot
exceed 1. Densified to annual; delivered mass now asserted. Separately, `sprintf()` with a
zero-length argument returns `character(0)` and `cat()` prints nothing, so a mistyped field
name dropped an entire table **silently with exit status 0**. Guarded.

### 4. The two tabs (R4/R5) — specced, with Marcus' framing

**"Concentrate on the positive learning and not on the debunking"** (Marcus). So DESIGN §7
gains **tab 5 "How long does it last?"** (two curves from one model; the observed bomb
spike beside the observed Keeling curve; the background slider) and **tab 6 "What drives
CO₂?"** (the correlation, then detrended, then the two counterfactuals, closing on δ¹³C's
sign). The fallacious arguments are a **short signposting appendix inside "Under the hood"**
(§7a), not a tab — *published claim → published response → which panel bears on it*, naming
arguments rather than characterising people. Essenhigh (2009) `doi:10.1021/ef800581r` with
**Cawley (2011)** `doi:10.1021/ef200914u`; Harde (2017) `doi:10.1016/j.gloplacha.2017.02.009`
with **Köhler et al. (2018)** `doi:10.1016/j.gloplacha.2017.09.015`; Salby and Spencer as
non-peer-reviewed links. All four DOIs verified against Crossref, not recalled.
**Cawley (2011) is the anchor for tab 5** — its whole point is that a short residence time
and a long adjustment time are both consequences of the same model, which is exactly what
the paired ¹⁴C-label and mass pulses show here. **Spencer's is the subtle one**: not wrong
arithmetic but a **fixed-equilibrium assumption**, and the model's equilibrium point is not
a parameter — it emerges from carbonate chemistry, which the "frozen Revelle" switch already
isolates. **DESIGN §1 gains the fifth goal.** Tab implementation is NOT done; the appendix
wording is Marcus' call.

**R2 built:** a **"no emissions"** switch — every existing switch turned off a *sink*, none
the *source*. Over 1750–2024 it gives **−134 ppm** (back to 285, essentially preindustrial)
against the warming feedback's **−10 ppm**. That contrast is the whole of tab 6 and it is
now pinned by a test.

## 2026-08-13 (f) — Handoff, and the ocean's missing vertical structure

`notes/handoff_2026-08-13e_marcus_directives.md`.

**Measured while answering Marcus' question about a biological pump, and it is a finding in
its own right:** at the preindustrial spinup the ocean's **DIC is exactly uniform at
1986.3 µmol/kg and δ¹³C exactly uniform at +1.560 ‰ through all eleven layers**. Only Δ¹⁴C
has a vertical gradient (−51 → −187 ‰), because that one is built by decay plus diffusion
and needs no biology. **1986 µmol/kg is a realistic *surface* value applied to 3700 m of
ocean.**

Total ocean carbon 32,827 GtC; to reach the canonical ~38,000 the model would need a
volume-weighted mean DIC of **2299 µmol/kg**. **So the ~14 % inventory deficit and the
missing vertical DIC gradient are the same number, and that number is the soft-tissue
pump.** *(The 2299 is the model's own arithmetic. Observed deep DIC/δ¹³C values quoted in
the handoff are recollection — GLODAPv2 is the source to pull before any of it is scored.)*

**New and previously unlisted: the model's deep ocean is ~1–1.5 ‰ too enriched in DIC
δ¹³C** — in the tracer this project has spent a fortnight fighting, and nothing has ever
scored it.

**The structural consequence bounds what a pump could do here.** The interior carries **no
carbonate chemistry** (`pco2_from_dic()` is called only for the mixed layer), and in steady
state the mixed layer's DIC is **chemistry-pinned** by ALK, SST and the spinup's pCO₂
target. So a pump cannot change surface DIC, cannot change the Revelle factor, and cannot
change the IRF to first order — it changes the interior, and the interior reaches the
atmosphere only through what ventilation brings back up. **A pump alone is mostly
bookkeeping; a pump plus a return path is a mechanism.**

**Why it is nonetheless the most interesting option on the table:** the observed
surface-to-deep DIC and δ¹³C gradients are **currently exactly zero in the model and
therefore entirely unused as constraints**. A pump turns both into observables, and because
a pump's gradient is set by **export ÷ ventilation**, they constrain ventilation directly —
which is what handoff 13c §5 says the refit needs and cannot get, **without requiring the
deep-Δ¹⁴C target to be settled first.** Costs: +2 parameters on a model the panel just
called correctly sized, and a pump injects surface-¹⁴C carbon into the deep non-locally,
making it *younger* and working against the deep-age constraint — **magnitude unmeasured.**
Pedagogically it passes the test the conveyor failed: one famous sentence, and it explains
the 50× ocean:atmosphere stock ratio the app already displays.

## 2026-08-13 (g) — The 1900 deficit diagnosed: land-use carbon has an airborne fraction of ZERO

`calibration/diag_1900_deficit.R`. Discharges handoff 13e §0.4 — "a NEW, UNDIAGNOSED
MISFIT ... larger than the question that surfaced it and nobody has looked at it."

**It is not a 19th-century problem and it is not about the 19th century.** The model
undershoots Law Dome by ~6.5 ppm at 1900 because **land-use emissions have an airborne
fraction of 0.002 at 100 years**: the land takes back every tonne deforestation releases.

**THE CLUE WAS INSIDE `diag_pre1850_luc.R`'s OWN TABLE AND WAS READ PAST.** Four pre-1850
LUC options spanning **0 → 74.1 GtC** of cumulative emissions land within **0.38 ppm** of
each other at 1900, having been **6.09 ppm** apart at 1850. Fifty years erased 94 % of a
74 GtC forcing difference, against the model's own 50-yr point IRF of 0.397. Suspicious
uniformity, per the standing rule, is a code path until disproven — and it was.

**THE MECHANISM.** LUC is a transfer out of the wood pool (`98c1783`, 2026-08-12, and
right on its own terms: `add_source()` created ¹⁴C ex nihilo). But wood has a restoring
fixed point, so what deforestation removes, the model **regrows**:

```
d(δW)/dt = φ(1−f)·npp0/veg0 · δW − δW/tau_wood
         = 0.5·0.4/8.6 − 1/20 = −0.0267 /yr   →   37.4 yr
```

**MEASURED, NOT ARGUED** (§3, and it depends on no historical forcing, no observation and
no fit): 100 GtC in 1760, zero-emission background, GMST and ENSO frozen, control flat to
+0.027 ppm over 275 yr.

| airborne fraction at lag | 10 | 25 | 50 | 100 | 150 |
|---|---|---|---|---|---|
| external source | 0.605 | 0.445 | 0.337 | **0.262** | 0.226 |
| wood transfer | 0.577 | 0.260 | 0.072 | **0.002** | −0.003 |

**A fossil emission is permanent in this model; an LUC emission is a transient the land
takes back in full.** GCB reports E_LUC and S_LAND as separate terms (`gcb_budget.rds`
carries them as separate columns) and the model's β-fertilisation uptake is the analogue of
S_LAND — so regrowing what E_LUC removed adds a second, unbudgeted land sink on top of the
one already parameterised. Whatever share of regrowth E_LUC does or does not net out,
**full recovery to the preindustrial stock is not defensible: converted land is farmed.**

**IT IS A REGRESSION, dated.** `98c1783` landed 2026-08-12; the deficit was noticed
2026-08-13 and mis-attributed to the pre-1850 LUC question, which cannot touch it.

**HOW BIG, over the whole record** (default parameters, LUC routed as an external source
being mass-exact and isotopically meaningless, which is all §2/§5 read off it):

| | 1900 | 1930 | 1960 | 1990 | 2010 | 2024 |
|---|---|---|---|---|---|---|
| shipped (LUC = transfer) | −6.51 | −9.08 | −4.01 | −5.65 | −5.37 | −6.02 |
| LUC permanent | +1.62 | +3.22 | +13.44 | +19.02 | +24.29 | +27.44 |

**The regrowth path accounts for 125 % of the 1900 deficit — handled permanently the model
OVERSHOOTS — so this is not a missing source.** Cumulative land 1750–2024: model **+29.4
GtC** against GCB 2025's **−57.4**. *The model's land is a net **sink** where the budget
says net **source**.*

**AND IT IS INSIDE THE LIKELIHOOD.** Scanning β at fixed everything-else against the CO₂
record (Law Dome then MLO, 1850–2024): the transfer path prefers **β = 0.30**, a permanent
LUC prefers **β = 0.70**. **The treatment biases β down by ~2.3×.** Stated with its limit:
`mode_fit.rds` has β = 0.088, *below* even the 0.30 the transfer path prefers, so the LUC
defect is a **contributing** bias and not the whole story — the other 15 parameters and the
δ¹³C/¹⁴C streams are not in a 1-D scan. **Do not read §6 as attributing the mode.**

**NOT FIXED HERE, and deliberately.** The fix is not reversion — the ¹⁴C-ex-nihilo reason
for the transfer stands. It is to make the **debit permanent**, which means the land's
equilibrium stock must fall as land is converted: a structural change to a model the expert
panel just called correctly sized, and therefore Marcus'. Options and costs are in
`notes/handoff_2026-08-13f_luc_regrowth_double_count.md`.

**Sharpens `mode_fit.rds` is stale from "the forcing moved" to "the forcing moved AND the
model gives land-use carbon away".** A refit before this is settled would fit the defect.

## 2026-08-13 (h) — The converted-land term: the land-use debit is made permanent

Marcus chose **route A** from `notes/handoff_2026-08-13f` §4. DESIGN §3.3 gains the
converted-land term; `calibration/diag_1900_deficit.R` is rewritten around it;
`tests/testthat/test-luc-permanence.R` is the gate. **Suite 505 pass / 2 fail / 2 skip**,
up from 490 / 4 — and *which* two stopped failing is a finding in itself (below).

**THE TERM.** Cumulative land-use carbon defines a cleared fraction
`c(t) = f_luc_perm · cumLUC(t) / land0`; NPP₀ and veg₀ are both scaled by `(1 − c)`.

**`land0` IS TOTAL LAND CARBON, ALL FOUR POOLS — NOT `veg0`, AND THE DIFFERENCE IS THE
WHOLE POINT.** Scaling NPP₀ scales every pool's equilibrium, so the land's equilibrium
carbon falls by `c · land0`. Setting `c = cumLUC / land0` makes that fall equal what
deforestation removed — the debit is permanent *by construction*, with `f_luc_perm = 1` as
the mass-consistent point rather than a fitted one. Using `veg0` would shrink the
equilibrium by a quarter of what was taken and the land would re-absorb the rest.

**MEASURED, and the fix is not tuned to any of it:**

| airborne fraction at lag | 10 | 25 | 50 | 100 | 150 | 264 |
|---|---|---|---|---|---|---|
| fossil | 0.605 | 0.445 | 0.337 | **0.262** | 0.226 | 0.180 |
| LUC, `f_luc_perm = 0` (the bug) | 0.577 | 0.260 | 0.072 | **0.002** | −0.003 | −0.001 |
| LUC, shipped | 0.646 | 0.362 | 0.193 | **0.130** | 0.127 | 0.131 |

**THE INDEPENDENT CHECK NOBODY AIMED AT.** Cumulative land 1750–2024 goes **+29.4 →
−53.6 GtC** against GCB 2025's **−57.4**, and the ocean **+169.1 → +202.2** against
**+209.8**. The fix was derived from the pulse argument and the budget's own column layout;
that it lands the *partition* on GCB is a result, not a target.

**WHY ~50 % AND NOT 100 %, tested rather than argued.** The debit lands on wood (37 yr)
while the equilibrium reduction is pro rata, 70 % of it in a 500-yr passive soil. Predicted
consequence: shorten that pool and the ratio should go to 1. **At `tau_soil_slow = 20` it
is 1.02 at 100 yr and 1.01 at 150 and 264.** Confirmed. Closing the remainder means
debiting the pools **pro rata**, which trades against the 2026-08-12 call that the emitted
carbon carries wood's lagged ¹⁴C — **an open decision for Marcus, recorded, not taken.**

**TWO SUITE FAILURES WERE NEVER A STALE FIXTURE.** `test-likelihood.R:114/117` ("a CO₂
level bias is expensive") were written off as an AR(1)-era leftover in handoffs 12d, 13,
13b, 13c and 13e. They now pass, and the link is **causal, not coincidental**: at
`f_luc_perm = 0` the test's own quantity is `cost(+1 ppm) = −183.1` — adding a positive
bias *improved* the fit, because the model was systematically low — and at `f_luc_perm = 1`
it is **+534.5**. The suite had been reporting this bug since the day it landed and the
report was relabelled five times. *A failing test you have explained away is still data.*

**WHAT THIS COSTS.** At the default β = 0.38 the model now runs **+17.5 ppm high at 2024**,
because that default was centred against the bug. The CO₂ record's preferred β on a 1-D
scan moves **0.30 → 0.50**. And δ¹³C moves the **wrong** way: the 1900→2020 Suess decline
goes −2.209 → −2.366 ‰, **7.1 % faster**, against a model already ~25 % too fast. Both
arms keep LUC as a wood transfer, so unlike 13f §3's proxy this comparison is isotopically
clean. **The 13b/13c ocean conclusions must be re-measured on the fixed model.**

**Three things the change caught on its way in, all real:**

1. **`quiet_forcing()` in `test-conveyor.R` zeroed the LUC *flux* and not the LUC *stock*,**
   which asks the model to relax a pristine spinup toward a smaller land — a genuine drift
   the conveyor tests would have read as a conveyor failure. Zeroing only the flux is not
   "quiet".
2. **The `emissions` mechanism switch had the same hole**, and it is worse there because it
   is user-facing: "what if we had never emitted" would have left the land relaxing toward
   an equilibrium shrunk by ~290 GtC of clearing the counterfactual never did. Fixed in
   `R/mechanisms.R`; `test-mechanisms.R:54` was the gate that caught it.
3. **A window that starts mid-record no longer begins at a fixed point.** `ccx_spinup()`
   supplies preindustrial land; a run starting in 1900 hands it a land already shrunk by
   88 GtC of clearing. `ccx_build_forcing()` now **warns** (`FORC_LUC_PRE_WARN`). Honest
   rather than silent — but it means windowed drivers carry a start-up transient, and the
   48 warnings in a suite run are all real ones.

**Layout contracts touched, both stated on both sides:** `CCX_FORCING_COLS` gains
`cum_luc_NH`/`cum_luc_SH` **appended** (10 → 12, `N_FORCING` in `src/ccx_core.cpp`), and
`CCX_LUC_CLEARED_MAX` is duplicated as `LUC_CLEARED_MAX` in the C++ because the two
implementations are independent by design — *nothing catches a disagreement in that one,
so if one moves the other must move in the same commit.* The parity fixtures now carry a
**non-zero** `cum_luc`, because at zero the new term collapses to `(1 − 0)` and the gate
would be inert — cf. "mutation-test your gates".

**`ccx_spinup()` is untouched and every pre-2026-08-13 spinup result is bit-identical:**
the spinup's zero forcing has no LUC flux, so `ccx_forcing_cum_luc()` returns zero and the
cleared fraction is zero. A forcing that carries LUC emissions and *no* `cum_luc` is an
**error**, not a zero-default — defaulting it would restore the bug through a code path
nobody chose.

## 2026-08-13 (i) — Answering "is there a path forward?": the q10 inversion was the LUC bug

Two diagnostics, both written to answer Marcus' question, and one of them **overturns an
attribution this repo has carried since 2026-08-12**.

### `diag_d13c_partition_refit.R` — the obvious hope, tested and FAILED

`diag_d13c_suess.R` §3's verdict — "δ¹³C and CO₂ cannot both be satisfied by any partition
this model can reach" — was computed on the model whose land had the **wrong sign**
(+29.4 GtC where GCB says −57.4). It had to be re-run. **It survives.**

| | β that zeroes δ¹³C | β that zeroes CO₂ | gap |
|---|---|---|---|
| `f_luc_perm = 0` | 0.93 | 0.36 | **0.57** |
| `f_luc_perm = 1` | 1.18 | 0.59 | **0.59** |

Both crossings move up by ~0.24; **the gap does not close.** The converted-land term does
not relieve the δ¹³C misfit, and no one should expect it to. Recorded as a **measured
negative** so the hope is not re-formed later.

*A unit trap this file fixes:* §3 compared `mean(diff(land_C))` with GCB's `land_sink`.
Those were nearly the same quantity while LUC was being regrown and are **not** now —
`diff(land_C)` is the net land flux (sink *minus* LUC), GCB's `land_sink` is the residual
sink alone. The gross sink is `diff(land_C) + LUC`, and that is what the share uses here.

### `diag_which_stream_pays.R` — and this one is the finding

`diag_d13c_suess.R` states: "the calibration's only remaining way to relieve [the δ¹³C
bias] is to manufacture land sink — which is what q10 → 0.17 is doing." That is an
attribution, and it had never been measured. A (β, q10) slice at the mode, scoring each
stream separately via `ccx_loglik(by_stream = TRUE)`:

| stream | optimum, `f_luc_perm = 0` | optimum, `f_luc_perm = 1` |
|---|---|---|
| CO₂ | β 0.10, q10 0.20 | β 0.50, **q10 1.50** |
| δ¹³C | β 0.70, q10 0.50 | β 0.90, q10 0.20 |
| Δ¹⁴C | β 0.30, q10 2.50 | β 0.70, q10 2.50 |
| **total** | **β 0.10, q10 0.20** | **β 0.50, q10 1.50** |
| `mode_fit.rds` (fitted on `f_luc_perm = 0`) | β 0.088, q10 0.169 | |

**δ¹³C is not what drives q10 down.** At the mode's own `sigma_d13c` = 0.44 ‰ its surface
is flat to **~3 log-units** across the entire q10 range, while CO₂'s falls **3200**. CO₂ is
the sharp stream in q10 — and on the fixed model it wants **q10 = 1.5 and β = 0.50, both
defensible**. Cost of moving to β 0.5 / q10 2.0: CO₂ 39.9 log-units, δ¹³C 2.8, Δ¹⁴C 0.2.

**The control is what makes it an attribution.** On the buggy model the same slice puts the
total optimum at the grid **corner** (0.10, 0.20) — at or beyond the edge — reproducing
`mode_fit.rds`'s (0.088, 0.169). **The q10 inversion was the land-use regrowth bug forcing
a compensating low-β/low-q10 pair.** With the land illegitimately absorbing every tonne of
LUC carbon, the sampler had to kill the other land sink (β) and then invert the soil
temperature response (q10 < 1 makes respiration *fall* as soil warms — the wrong sign) to
recover the CO₂ trajectory.

**Bounded, not settled:** the other 14 parameters are held at values themselves fitted to
the bug. The refit decides it. Two claims deliberately *not* made: no comparison of this
model's β to C4MIP's (different quantity — `reference_arora2020_c4mip_gamma` is γ_L), and
q10's indefensibility is argued from its **sign**, which needs no citation.

### What still does not match, and where that points

At the slice optimum the model's 2015–2024 **land sink is 3.41 GtC/yr against GCB's 2.36,
and its ocean sink 2.99 against 3.22.** Land too strong, ocean too weak — and the ocean is
the reservoir with the known structural deficiency (inventory ~14 % low, **no vertical DIC
or δ¹³C gradient at all**, `kz` 9× Ledwell's NATRE value). That is where the biological
pump case now lives, and it is a stronger case than before: those two gradients are
**exactly zero** in the model and therefore entirely unused as constraints, so any pump
improves two measured mismatches — and its gradient is set by export ÷ ventilation, which
constrains ventilation **without** first settling the deep-Δ¹⁴C target.

**The pump's effect on atmospheric δ¹³C remains sign-unknown** (13e §7 said so; nothing
here changes it). Do not adopt it expecting the δ¹³C misfit to close.

## 2026-08-13 (j) — PHASE 1 of the sequenced plan: measured, and two of its own claims withdrawn

Works handoff 13h's PHASE 1 and stops where 13h says to stop. Full record in
`notes/handoff_2026-08-13i_phase1_measured.md`.

### `beta` re-centred 0.38 → 0.60, and it is not one criterion's answer

0.38 was set 2026-08-12 as the 1-D log-posterior optimum of the model that **preceded**
`404d66d` — i.e. against the bug. On the shipped model it leaves CO₂ 20.0 ppm high.
Four criteria agree to within 0.02 (`diag_recentre_beta.R`): CO₂-bias zero **0.591**,
CO₂ stream's own optimum **0.597–0.599**, full posterior at `mode_fit`'s σ **0.597**, at
the table's σ **0.617**. That last row is the useful one — the answer barely moves when
`sigma_d13c` moves 0.44 → 0.10, so the default could be set with that decision still open.

### WITHDRAWN: "the converted-land fix makes δ¹³C 7.1 % worse"

13h §2.2d measured it at a **stale β**. Like for like, at each model's own CO₂-consistent
β, the 2015-2024 MLO δ¹³C bias goes **+0.580 (pre-fix, β 0.358) → +0.529 (post, β 0.591)**.
The fix **improved** the δ¹³C misfit by 0.05 ‰. And `diag_conveyor.R`'s deep-Δ¹⁴C columns
are **bit-identical** across the fix, so the 13b/13c ocean conclusions were never at risk.
Re-measured at β 0.60 the ocean is *better* than 13c recorded: mixed-layer Suess
**0.153 (−0.4 sd vs Quay)**, atmosphere **+18 %** rather than +25–30 %.

### NEW STRUCTURAL MISFIT: the CO₂ record vs the GCB budget

`diag_luc_prorata.R` §5. Against GCB 2015-2024 (gross land 2.36, ocean 3.22 GtC/yr):

| debit | β | CO₂ bias | cum land 1750-2024 | gross land | ocean |
|---|---|---|---|---|---|
| wood only | 0.38 | −20.0 ppm | −52.2 (GCB −57.4) | 2.74 | 2.87 |
| wood only | **0.60** | **+0.8 ppm** | **+21.7** | **3.99 (+69 %)** | 2.52 (−22 %) |
| pro rata | 0.38 | −35.0 ppm | −108.8 | 2.36 | 3.00 |
| pro rata | 0.70 | −1.0 ppm | +11.1 | 4.31 | 2.45 |

**Matching GCB's cumulative land costs ~21 ppm under BOTH debits** — the debit choice moves
where β sits on the line, it does not relieve the line. Size explained, not hand-waved:
the model closes its own budget exactly (E_foss 504.7 = Δatm 303.8 + Δland 21.7 + Δocean
178.3, residual 0.9 GtC) while GCB's own table carries **+35.6 GtC of cumulative imbalance
over 1959-2024 alone**. *Provenance flag: the −57.4 / +209.8 GtC figures come from
`404d66d`'s commit message and cannot be recomputed here — `obs_gcb.rds` starts in 1959.*

### `f_luc_wood`: the pro-rata debit, built as a switch and measured

Default 1 = the shipped wood-only behaviour, bit-identical, with its own parity gate (the
default never reaches the new branch, so the existing gate could not see it).

| LUC airborne fraction ÷ fossil's | 50 yr | 100 yr | 150 yr | 200 yr |
|---|---|---|---|---|
| wood only | 0.549 | 0.496 | 0.569 | 0.647 |
| **pro rata** | **1.025** | **1.024** | **1.023** | **1.024** |

Cost: the emitted carbon stops carrying wood's ¹⁴C. At 2024 the debit's Δ¹⁴C goes
**+57.1 → −10.1 ‰** — in the bomb era it flips from enriched to depleted. Pool equilibrium
shares are leaf 1.7 / wood 22.5 / soil_fast 5.4 / **soil_slow 70.4 %**.
*Correction:* the debit does **not** land on "wood (37 yr)" as 13h §2.1b and `404d66d`'s
message say — `tau_wood` is **20 yr**, and 35.5 yr is `land0/npp0`, the whole land's bulk
turnover. The two were conflated.

### The `kz` bracket: 13h §2.1a's *reason* does not survive, and the bound is not binding

13h §2.1a deletes `[3830, 6200]` as "conditional on the pure-diffusion column" — but PHASE
2 is conveyor-OFF, i.e. that exact column, which is the same fact 13h §3.2 relies on.
What survives is 12d §8's different reason (the bound leaks), whose prescription is a
**likelihood term**, not a bare deletion. Measured (`diag_kz_bracket.R`): the bracket
**re-bisects to [3828.9, 6201.0]**, unmoved by `404d66d` or the β change; the leak is
**+7.0 to +8.1 ‰** uniformly, re-bisecting to [3601, 5703] at `mode_fit`'s vector; and the
1-D log-posterior in kz has an **interior maximum at 5000** under both candidate σ_d13c.
Bare deletion is priced: kz 10,686 gives deep Δ¹⁴C **−112.7 ‰**. There is still no
deep-Δ¹⁴C term in `R/likelihood.R`.

### A units trap that was live in a shipped diagnostic

`mean(diff(land_C))` is the **net** land flux (sink − E_LUC); GCB's `land_sink` is the
**gross** residual sink. Nearly the same quantity while land-use carbon was being regrown,
and not since `404d66d`. Fixed in `diag_d13c_suess.R` §3 (still live there), the two new
diagnostics, and the `beta` comment. **It changed a conclusion:** at β 0.60 the land sink
is +69 % against GCB, not the +11 % first written.

### Six failing tests, three new, all deliberately left failing

Re-derived rather than labelled, per "carry the evidence, not the label":
`test-likelihood.R:114/117` — the fixture's 12.65 ppm bias is gone, not the property; the
symmetric curvature `(cost(+1)+cost(−1))/2` is **+26.40 at both β** and `cost(+50)` is
64,439, so the AR(1) loophole is still shut. Station CO₂ residuals went **RMS 13.28 → 1.09
ppm**, and they are structured, not noise (+0.036 / +0.051 ppm/yr trends, p 3e-14 / 4e-20).
`test-likelihood.R:135` — at RMS 1.09 the ML σ_co2 is ≈ 0.4, so the hard-coded "sane" 5 is
no longer sane. `test-climate.R:121` joins `:122` as one phenomenon: higher β damps the
carbon-climate loop gain, and the header's ~111 ppm / ~0.3 °C was never met.
`test-mechanisms.R:32` — the ENSO switch is weak on the level *and* on the right statistic:
growth-rate sd 0.584 vs observed 0.712 at `gamma_enso` 0.5, matching at γ ≈ 1.5–2
(`mode_fit` chose 0.927), with the posterior nearly flat 0.5 → 1.0.

## 2026-08-14 — Marcus' decisions; pro rata adopted; and the Pulse Lab reversal

Decisions: `kz` → delete the bracket **and** add a deep-Δ¹⁴C likelihood term (**blocked**,
below); `sigma_d13c` → **left free**; the failing-test re-derivations → **none written**;
the LUC debit → **delegated on physical realism**.

**LUC debit: PRO RATA.** `f_luc_wood` default 1 → 0. Reasoning in full at
`CCX_F_LUC_WOOD_DEFAULT`: it is the mass-consistent partner to the converted-land term
(which already lowers all four pools' equilibria); GCB's E_LUC is **already timing-resolved**
and carries legacy soil loss, so the model must not re-impose a vegetation-only timing on
it; and wood-only leaves half of each land-use tonne coming back (AF ratio 0.50 vs 1.02).
It gives up the wood-¹⁴C call. Caveat logged not built: a **single** clearing event should
be fast out of vegetation and slow out of soil, and pro rata takes 70 % out of a 500-yr
pool instantly — right for the historical E_LUC record, wrong for the app's "what if we
cleared X". That forced a second β re-centring, **0.60 → 0.75**.

### CORRECTION: the β re-centring left TEN failing tests, not six

The 2026-08-13 (j) entry says six. Bad grep — `test-pulse.R:83/100/101/113` were in the
same output. **`:100/:101` is the consequential one: the Pulse Lab's Revelle-saturation
claim REVERSES.** 100 GtC at 2050, airborne fraction at 2150, ssp585 − ssp119:

| β | 0.38 | 0.50 | 0.60 | 0.75 |
|---|---|---|---|---|
| hi − lo | **+0.204** | **+0.085** | **−0.011** | **−0.109** |

The LUC debit is irrelevant to it — both debits agree to three decimals at every β.
**Mechanism, and it is a model limitation not a threshold problem:**
`NPP = NPP0(1 + β ln(χ/χ0))` has **no saturation**, so on SSP5-8.5 at 1998 ppm the land
runs at **2.48× preindustrial NPP** at β 0.75 (1.75× at 0.38). That sink overwhelms the
ocean's buffer and flips the sign. **Above β ≈ 0.53 the Pulse Lab teaches the opposite of
its own lesson**, and none of the four calibration criteria sees this. Either the default
stays below ~0.53 and accepts a CO₂ bias, or the fertilisation gets a saturating form —
which is model structure, i.e. PHASE-3-class work.

*Nearly missed twice:* scanning β by monkey-patching `ccx_default_params()` and calling
`test_file()` returned **byte-identical numbers at β 0.38/0.50/0.55/0.60** — the override
never reached the tests. Suspicious uniformity as a bug signal, working.

### The `kz` decision is BLOCKED on provenance, deliberately not implemented

The `[−150, −200] ‰` target appears **once** in the repo, in `DATA.md` §5, as *"roughly
−150 to −200"* — no paper, no dataset, no access date. Hard rule 2 forbids an uncited
value in code, and a term in the **objective** is a stronger use than the bound it
replaces. **The bracket is therefore NOT deleted**, since bare deletion is the
measured-and-rejected option (kz → 10,686, deep Δ¹⁴C −112.7 ‰). **GLODAPv2 unblocks it**,
and 13h §4.3 already needs the same pull for PHASE 3's deep DIC and δ¹³C targets.

## 2026-08-14 (b) — Stop before PHASE 2: a step-back architecture review is queued

Marcus called a halt before the conveyor-OFF refit. `notes/handoff_2026-08-14_step_back_architecture_review.md`
sets the terms of reference: **targets** (what are we asking the model to reproduce, and are
the stream weights defensible), **inputs** (fossil, LUC, bomb/nuclear/cosmogenic ¹⁴C, ENSO,
GMST — and the four provisional hemispheric shares), **components** (how many land pools;
how land and LUC interact; pump vs conveyor vs neither; how fertilisation is handled; how
temperature and ENSO interact; gross vs net exchange for each), and **whether the assembled
thing works** — pulse lifetime, expected to be the weakest test, and pedagogy. The
inventories in it are verified against the code; the questions are deliberately unanswered.
13h §§3–4 stay on the shelf, unchanged, until the review says whether they are still right.

### FOUND WHILE TAKING INVENTORY, NOT FIXED: `gcb_land_sink` compares net to gross

`R/likelihood.R` scores `diff(land_C)` — the model's **NET** land flux, sink minus E_LUC —
against GCB's **GROSS** residual sink. This is the same trap fixed in the diagnostics at
`cc3abd5`, but **inside the objective the MCMC will optimise**: the model is asked to
over-absorb by exactly E_LUC (~1.37 GtC/yr recently).

| β | as shipped | corrected (`mod_ld + E_LUC`) | mean model−GCB, net | gross |
|---|---|---|---|---|
| 0.38 | −139.6 | **−125.7** | −1.75 | **−0.07** |
| 0.75 | −127.6 | −134.9 | −0.31 | +1.37 |
| 0.85 | **−127.8** | −139.6 | −0.00 | +1.68 |

**The bug inverts the term's pull.** As shipped it wants β to *rise*, bottoming near 0.85;
corrected, its own optimum is β ≈ 0.39 and it *resists* rising β. It went unnoticed because
it was pushing the same way as the CO₂ streams. It is a bug, not a choice — the only choice
attached is the σ (`0.9 × 3.0 = 2.7` GtC/yr, traceable to `DESIGN.md` §9 Q1). **Left
unfixed deliberately**: the fix changes what the model is fitted to, the refit is blocked
anyway, and it belongs in front of the review rather than quietly applied. **Fix before any
refit.** Second-order and also review material: even corrected the term moves ~9 log-units
across β 0.38→0.75 against the CO₂ streams' ~12,000, so the partition constraint is nearly
decorative. `gcb_ocean_sink` has no E_LUC analogue and is unaffected.

## 2026-08-14 (later) — THE ARCHITECTURE REVIEW: two DESIGN hard gates are failing, and the objective's weighting is why

`notes/review_2026-08-14_architecture.md`. Discharges §2 of
`handoff_2026-08-14_step_back_architecture_review.md` — a written review of targets,
inputs, components and whether the assembled model works. **No model code, no fixtures
and no defaults were changed.** Three diagnostics added; everything below is measured.

**HEADLINE — the shipped default fails two of DESIGN §6's own hard gates.**

| gate | target | at `ccx_default_params()` (β 0.75) | |
|---|---|---|---|
| **7 — sinks 2015–2024** | land 2.36 ± 0.9, ocean 3.22 ± 0.4 GtC/yr | **4.57 / 2.38** | **+2.5σ / −2.1σ** |
| **12 — Joos IRF, TH 20/50/100** | 12.2–16.3 / 24.0–36.6 / 39.5–65.2 yr | **10.4 / 19.9 / 31.2** | **FAIL ×3** |

Gate 12's recorded status in DESIGN ("inside at all three, 12.6/26.2/43.6") was measured
at β 0.38 and is **stale**. `diag_joos_beta_scan.R` puts the gate's ceiling at **β ≈ 0.50**
— which independently agrees with the Pulse Lab's Revelle ceiling of ≈0.53 (13i §A1).
Neither criterion was used to set the default, which tracks the CO₂ record alone.

**WHY — measured, `diag_stream_leverage.R`.** A stream's weight is its LEVERAGE (log-units
per one-prior-sd parameter step), not its logL LEVEL. Across a step in β: CO₂ streams
1,565, ice core 118, `gcb_ocean_sink` 36, `gcb_land_sink` **2.0** (7.3 corrected). The
partition constraint loses **40 : 1**, so the sampler always buys CO₂ level with land sink.
Both β re-centrings did exactly that, correctly following the objective as written.

Four further findings from the same matrix:
- **`excess_c14_ocean` failed at its stated job.** Design note 5 added it so `bomb_total`
  could not absorb ventilation error. It has **0.8** log-units of leverage on `bomb_total`
  against the atmospheric Δ¹⁴C streams' **1,247**. Outvoted 1,500 : 1; the loophole is open.
- **A large level with no leverage is a constant offset.** `d14c_intcal` carries −670 of
  logL and **2.8** of leverage. Never quote a stream's level as evidence of its weight.
- **`q10` is decided by δ¹³C** — the one stream with a known unclosed 0.53 ‰ misfit. The two
  CO₂ station terms oppose and cancel (+7.2 / −6.9); δ¹³C supplies 31 of ~70 available
  log-units, pulling `q10` down. This is the `q10` → 0.169 pathology seen directly, and it
  confirms `diag_which_stream_pays.R`'s hypothesis with a cleaner instrument.
- **Free σ let a misfitting stream de-weight itself.** Three σ are calibrated, every other
  stream's is fixed. A +0.7 log-sd move in `sigma_d13c` GAINS the δ¹³C streams 510 log-units.
- **τ_ex is set by the seasonal cycle, not by the gradient.** DESIGN §6 gate 9 says the
  MLO−SPO gradient is "the main constraint on τ_ex". There is **no gradient term in
  `ccx_loglik()`**; 66 % of τ_ex's leverage comes from `co2_seasonal_*`.

**§1's `gcb_land_sink` net-vs-gross defect — CONFIRMED and PRICED.** Real, and it must be
fixed because the objective is wrong — but at 7.3 log-units corrected against CO₂'s 1,565
it **will change essentially nothing about the fit**. Do not mistake its landing for having
addressed the weighting. A second, smaller defect found alongside it: both sink terms
compare `diff()` of ANNUAL-MEAN stocks to GCB's CALENDAR-YEAR flux — a half-year offset,
negligible in bias, but it aliases exactly the interannual variability a partition
constraint is supposed to use. Same three lines.

**THE CHEAPEST FIX IS AN INPUT, NOT A PARAMETER — `diag_luc_scale.R`.** `E_LUC` is
prescribed exact while `DATA.md` §3a already records GCB 2025 at 239.8 GtC (1850–2018)
against OSCAR v3.1's 178.9 for the same period — a **34 % product spread** — and OSCAR's
own headline is **206 ± 57 PgC** = ±27 ppm. The model's largest structural misfit (13i §2's
"CO₂ level vs GCB budget", ~30 ppm) is **smaller than one input's stated uncertainty.**
At matched CO₂ bias:

| | β 0.75, LUC × 1.00 (shipped) | β 0.50, LUC × 0.65 (= 188 GtC) |
|---|---|---|
| CO₂ level | +3.3 ppm | −2.6 ppm |
| gate 7 land / ocean | **4.57 (+2.5σ)** / **2.38 (−2.1σ)** | 3.06 (+0.8σ) / 2.63 (−1.5σ) |
| gate 12 Joos | **FAIL ×3** | inside ×3 |
| Pulse Lab Revelle | **reversed** | holds |
| δ¹³C bias | +0.382 | +0.542 |

The LUC route wins on four criteria and **loses on δ¹³C by 0.16 ‰** — stated because it is
the one place the shipped default is better. 188 GtC sits inside OSCAR's published 206 ± 57.
**Not adopted as a fixture:** a uniform scale is crude, GCB's own E_LUC uncertainty has not
been pulled from source (rule 2), and this is a measurement of what is available.

**FERTILISATION IS THE BINDING STRUCTURAL DEFECT, with the arithmetic stated.**
`NPP = NPP₀(1 + β ln(χ/χ₀))` has one parameter controlling both the INTEGRAL (historical
uptake) and the DERIVATIVE at today's CO₂ (`β·NPP₀/χ` = 0.116 GtC/yr/ppm at β 0.75, against
the 0.062–0.077 the Joos gate needs). The data want a large integral and a small derivative;
the log form fixes their ratio. **A two-parameter saturating form is required**, to an
explicit design target: β ≈ 0.7's integral with β ≈ 0.5's marginal slope at 388 ppm.
Corroboration that this is a model defect and not a threshold problem: on the SSP protocol
the model leaves **9.6 %** of an ssp585 pulse airborne at 100 yr where Joos's Bern3D-LPJ has
RCP8.5 above 80 % at year 1000. Same cause as the Pulse Lab reversal.

**THE OCEAN IS RE-MOTIVATED AND NOW FALSIFIABLE.** At the β 0.50 / LUC 0.65 settlement the
ocean sink is the ONLY remaining gate miss (2.63 vs 3.22, −1.5σ) — a better case for the
pump than 13h §4.3 had. **Pre-registered before it is adopted on sink grounds:** build it,
measure the 2015–2024 ocean sink and surface DIC. > 0.1 GtC/yr toward 3.22 = mechanism;
otherwise 13h §4.3's "mostly bookkeeping" stands and it ships on pedagogy alone (where it
passes the one-sentence test and the conveyor fails).

**Components left alone, with reasons:** 4 land pools (free none — 13i priced one free
timescale at +3.6σ and nothing scores the ¹⁴C partition it would break); `ra_ratio` = 0
(no stream could identify it); temperature × ENSO interaction (`gamma_enso`'s max leverage
anywhere is 16.3); conveyor off (fails its own falsification test and the one-sentence test).

**ORDERING.** 1 fix §1 + the half-year alignment → 2 re-take β against DESIGN's gates
(Marcus') → 3 `luc_scale` as a 17th parameter → 4 GLODAPv2 (unblocks the `kz` decision AND
the pump's targets, one pull) → 5 gradient terms → 6 re-take the free-σ and
`LIK_EXCESS_C14_TARGET` decisions on the leverage evidence → 7 saturating fertilisation →
8 THEN the refit (~18 params) → 9 pump. **Do NOT** hand-tune stream weights, delete the
decorative terms, free land turnover, delete the `kz` bracket bare, or adopt LUC × 0.65.

**Failing tests:** `test-pulse.R:83/:100/:101/:112` now have EXTERNAL corroboration (the
Joos scan reproduces the defect at the same β). They are the model reporting a real failure
— leave them failing until the fertilisation form changes. **Add gate 12 to the suite**: it
is a hard gate whose only implementation is a diagnostic nobody runs, which is how its
status went stale across two β moves.

**Proposed DESIGN amendments written out but deliberately NOT applied** (review §8) — each
encodes a choice that is Marcus'. Includes a proposed **gate 13, stream-leverage screen**:
no calibrated parameter may be decided by a stream carrying a known unclosed structural
misfit. That is the general form of the `q10`/δ¹³C finding and would have caught it.

**Not re-measured, flagged as stale:** `diag_pedagogy.R`'s turnover-vs-adjustment numbers
(4.69 yr against a 40.3 yr mass 1/e) predate both β moves exactly as the Joos gate did, and
the mass 1/e time is precisely what §4.1 shows moving with β. The app's headline pedagogical
claim is currently uncorroborated at the shipped default.

**Non-obvious state:** `calibration/output/recentre_beta_scan.rds` was OVERWRITTEN by
re-running `diag_recentre_beta.R` at the current defaults (it was last written at β 0.60 /
wood-only). Every number in the review is at `gamma_enso` = 0, which is
`ccx_default_params()` and is **not** what `app/global.R:71` runs.

## 2026-08-14 (later still) — PRIORITY 1 + 3: the objective is fixed, and land-use uncertainty is a parameter instead of a burden on beta

Works items 1 and 3 of the architecture review's ordering. **Suite: 11 fail, the same 11
as before** (see the correction below) plus 34 new passing assertions.

### The objective (review item 1)

Three fixes in `R/likelihood.R`, all in the GCB-sink block:

1. **NET vs GROSS — the bug.** The model's `d(land_C)/dt` is net of E_LUC; GCB's
   `land_sink` column is the gross residual sink. The term is now reconstructed as
   `net + E_LUC`, using the **model's own** land-use flux (a new `luc` argument), not
   GCB's — otherwise a `luc_scale`-scaled run would be scored against an unscaled flux.
   NULL keeps GCB's column, which is **bit-identical to the forcing at scale 1**
   (verified 1959–2024, max |diff| = 0), so every existing caller stays correct.
2. **YEAR ALIGNMENT.** The old code diffed annual MEANS of the stock — the flux over
   [mid-year *y*−1, mid-year *y*], half a year off from GCB's calendar-year flux. Stocks
   are now interpolated to calendar-year **boundaries**, with linear extrapolation at the
   two ends (the monthly grid puts the first and last boundary half a month outside the
   run; `rule = 2` would hold flat and under-count the end years).
3. **`LIK_GCB_LAND_SD` 0.9 → 0.5.** It was labelled "GCB stated land-sink uncertainty"
   with **no provenance anywhere in the repo**, while GCB 2025's own header states ±0.5.
   Corrected to the cited value, with the whole uncertainty block now quoted verbatim
   from `data-raw/downloads/gcb2025_global_budget.csv` (ocean ±0.4, land ±0.5, E_LUC
   ±0.7 GtC/yr, fossil ±5 %, all 1σ). This is a **change to the objective** and is
   recorded as one — a constant tracking its source, not a reweighting. DESIGN §9 Q1's
   inflation multiplier is untouched and still rides on top.

**Effect, measured.** `gcb_land_sink` leverage on β: **2.0 → 24.3** log-units per
one-prior-sd step (12×, from the sign fix plus the σ correction) — now comparable to
`gcb_ocean_sink`'s 35.6, which is the right relationship. Still 1,565 : 24 against CO₂,
so the review's headline stands: **fixing this was necessary and did not fix the model.**

**And gate 7 is worse than the review said.** Against GCB's *stated* 0.5 rather than the
uncited 0.9, the shipped default's land sink is **+4.4σ**, not +2.5σ. Ocean unchanged at
−2.1σ.

**A counter-intuitive fact, pinned in `test-luc-scale.R` so nobody "fixes" it back:** at
β 0.75 the **buggy NET comparison scores BETTER** than the correct gross one (−97.3 vs
−122.0), because the model over-absorbs (gross sink 4.57 against GCB's 2.36). **The bug
was flattering the high-β model**, which is exactly why nothing objected as β rose.

### Land-use input uncertainty (review item 3)

**`luc_scale` is now the 17th calibrated parameter** — `ccx_build_forcing(luc_scale=)`
applied to the **annual** series (so the monthly flux, the in-window cumulative and the
pre-window `luc_pre` all scale together; scaling monthly columns alone would leave the
converted-land term's cleared fraction inconsistent with the flux). Inside
`ccx_make_logpost()` it is an equivalent column multiply for speed, gated against the
rebuild path by `test-luc-scale.R`.

**The prior has two independent receipts that agree — lognormal, median 1, sdlog 0.28:**
- OSCAR v3.1's own cumulative uncertainty, **206 ± 57 PgC (1750–2018)** → 27.7 %;
- the **GCB-vs-OSCAR product spread over the identical 1850–2018 window**, 239.8 vs
  178.9 GtC → ratio 0.746, |ln| = 0.293.

One is a stated uncertainty, one an observed disagreement between products; both land on
~0.28, which puts OSCAR's central estimate at ~1σ below GCB's. Centred at 1 (= GCB, the
standing convention) so the prior is not a silent re-basing. GCB's **annual** ±0.7 GtC/yr
(51 % of a 1.372 mean) is deliberately *not* the width — that is a single year's flux,
only partly correlated across years, so an upper bound on the cumulative fraction.

### The pre-registered prediction: MET, but conditionally, and the condition matters

Review §3.3 predicted, before the code existed: *with `luc_scale` free, β falls to
0.40–0.55 and `luc_scale` settles at 0.6–0.8.* `calibration/diag_beta_luc_profile.R`,
a 2-D slice of the **full** log-posterior (priors and Jacobians included):

| σ_d13c | argmax β | argmax `luc_scale` | cum LUC | CO₂ bias | land | ocean |
|---|---|---|---|---|---|---|
| 0.10 (table init) | 0.70 | 0.90 | 260 GtC | +3.53 ppm | +3.8σ | −2.0σ |
| **0.44 (mode_fit)** | **0.55** | **0.70** | **203 GtC** | **−0.40 ppm** | +2.0σ | −1.6σ |
| 5.00 (muted) | 0.55 | 0.70 | 203 GtC | −0.40 ppm | +2.0σ | −1.6σ |
| *any, `luc_scale` pinned at 1* | **0.75** | — | 289 GtC | +3.34 | +4.4σ | −2.1σ |

**The first run REFUTED the prediction** (β 0.70) and is left in the file's header rather
than deleted. The refutation was conditional on σ_d13c = 0.10: at that width δ¹³C
contributes ~740 log-units in favour of high β, far more than the `luc_scale` prior can
resist — and δ¹³C is the one stream carrying a known unclosed ~0.53 ‰ **structural**
misfit, so σ = 0.10 asserts that misfit is measurement noise. At 0.44 (what `mode_fit`
chose) and at 5.00 the answer is **identical**, so 0.10 is the outlier, not 0.44.

**Three things this establishes.** (i) The (β, `luc_scale`) ridge is real and steep — the
objective does use the input uncertainty rather than ignoring it. (ii) With LUC pinned,
β = 0.75 at **every** σ_d13c: pinning the input is what made the high β look robust.
(iii) The settlement's cumulative LUC of **203 GtC lands on OSCAR's central 206** without
being told to — the prior only supplied a width.

**Not oversold.** β 0.55 is still above gate 12's ≈0.50 ceiling and the Pulse Lab's ≈0.53,
and the land sink is still +2.0σ high. `luc_scale` gets most of the way and **does not
remove the need for review item 7, the saturating fertilisation form.** And a 2-D slice at
the other 15 parameters' inits bounds the answer; it does not decide it.

**It also means Marcus' 2026-08-14 "leave `sigma_d13c` free" decision is now load-bearing
on β**, which it was not when taken — free, the sampler picks ~0.44 and the prediction
holds; pinned at the table's 0.10 it does not. That is review item 6, now with a number.

### Corrections to the record

- **The pre-change suite was 11 failures, not 10.** `test-pulse.R:113` was already
  failing; handoff 13i §A1's text listed it and §A5's summary list did not, and the "10"
  propagated from there. Verified by running the suite on the stashed pre-change tree.
- `test-likelihood.R:165` (the parameter count) is the **only** newly-failing test and it
  is the tripwire doing its job. Updated to 17 **with the reason written in**, plus two
  new guards: `luc_scale` must be in `CCX_PARAM_NAMES` and must **never** appear in
  `ccx_default_params()`, where it would silently rescale every diagnostic that does not
  know about it.
- `calibration/diag_stream_leverage.R` no longer carries its hand-rolled "CORRECTED" land
  term — `ccx_loglik()` is now correct. Review numbers quoted as "corrected" (7.3 on β)
  are at the old σ = 0.9; the file now reports 24.3.

### Still open, and deliberately not done here

Fossil emissions carry GCB's stated **±5 %** (≈±25 GtC ≈ ±12 ppm cumulative) and are still
prescribed exact. A `foss_scale` is the obvious sibling of `luc_scale`, but the two are
strongly degenerate against a CO₂ record that mostly constrains their **sum**, and adding
a second emission scalar without measuring that degeneracy first is precisely what this
project's discipline forbids. Flagged, with the arithmetic, not taken.

## 2026-08-14 (cont.) — emission inputs: degeneracy measured, the LUC hemispheric share is TIME-VARYING, and the omitted input seasonality is NOT negligible

Three diagnostics, no model changes. `diag_emission_scale_degeneracy.R`,
`diag_emission_split_and_season.R`.

### `foss_scale` — identifiable, but low value. NOT added.

The two emission scales are **not degenerate**, and the discriminator is the one predicted
before the run: **Δ¹⁴C**. Walking along the iso-carbon line (fossil × 504.7 + LUC × 289.3 =
const) at β 0.75, foss +0.08 / LUC −0.14 costs **82 log-units**, of which Δ¹⁴C supplies
−104 (NH −61, SH −43) and the ice core −51, partly offset by CO₂ level +45. Fossil carbon
is ¹⁴C-free by definition; land-use carbon carries the vegetation pool's own ¹⁴C. δ¹³C
contributes almost nothing (−4), as expected — the two source signatures are similar.

**But the identification is ~10–20× weaker ALONG the iso-carbon direction than across it**
(hundreds vs thousands of log-units), so a `foss_scale` would be strongly anti-correlated
with `luc_scale`. And GCB's fossil prior is ±5 % = **25 GtC** against LUC's ±28 % = **81
GtC**, so the fossil prior admits **3.2× less** carbon movement and would dominate its own
posterior. **Verdict: add `foss_scale` only if the refit drives `luc_scale` to a prior
edge** — that is the signal that total-emission error is being forced entirely onto LUC.
Noted: at β 0.55 the grid argmax sits at foss_scale 0.95, exactly −1σ of GCB's ±5 %; at
β 0.75 it sits at 1.00. Confounded with β, so not evidence on its own.

### The land-use hemispheric share is TIME-VARYING, and the constant 0.55 is wrong at BOTH ENDS

From OSCAR v3.1's **Regional** sheet — the same sourced file `DATA.md` §3a already uses,
11 regions, 1701–2018, whose 1750–2018 total reproduces the paper's 206 PgC headline.
Within-region NH fractions are geographic judgements, not sourced, so everything is carried
as a bracket:

| period | E_luc GtC | NH lo | **NH central** | NH hi | model uses |
|---|---|---|---|---|---|
| 1750–1849 | 27.5 | 0.797 | **0.838** | 0.880 | 0.55 |
| 1850–1899 | 30.4 | 0.719 | **0.766** | 0.812 | 0.55 |
| 1900–1949 | 57.2 | 0.600 | **0.668** | 0.735 | 0.55 |
| 1950–1989 | 54.6 | 0.428 | **0.527** | 0.627 | 0.55 |
| 1990–2018 | 36.8 | 0.267 | **0.398** | 0.528 | 0.55 |
| **1750–2018** | **206.4** | 0.539 | **0.620** | 0.700 | 0.55 |

**The share falls monotonically ~0.84 → ~0.40** as clearing moves from temperate NH
(North America, Europe, FSU, China) to the tropics (Latin America, Sub-Saharan Africa,
Indonesia). **The conclusion survives the whole bracket:** before 1950 even the LOW bracket
is ≥ 0.60, and after 1990 even the HIGH bracket is ≤ 0.53. So the model puts **too much
early land-use carbon in the SH (~23 GtC over 1750–1949) and too much modern land-use
carbon in the NH (~5 GtC since 1990)**. A constant cannot represent this, whatever value
it takes.

### ...and the objective cannot see it, which is review §2.3 made concrete

| | MLO−SPO CO₂ grad | δ¹³C grad | Δ logL |
|---|---|---|---|
| **observed** (gate 9, 2020s / 13i) | **3.97 ppm** | **−0.074 ‰** | — |
| as shipped (0.95 / 0.55) | 5.06 | −0.240 | — |
| LUC NH share 0.40 | 4.66 | −0.223 | **+33.4** |
| LUC NH share 0.70 | 5.46 | −0.258 | −40.1 |
| fossil NH share 0.90 | 4.46 | −0.213 | **+3.1** |
| fossil NH share 0.97 | 5.30 | −0.251 | −2.0 |

**The fossil share moves the CO₂ gradient by 0.84 ppm across 0.90→0.97 — most of the
model's 1.09 ppm gradient error — for 5.1 log-units of objective.** The share is
effectively unconstrained by the likelihood while strongly controlling an observable that
is badly wrong. That is the missing gradient term (review item 5), priced.

**And it answers review §3.4's question negatively:** the provisional shares are **NOT** the
cause of the δ¹³C gradient miss. Across the whole plausible range the modelled δ¹³C
gradient moves only −0.213 to −0.258 against an observed −0.074. The 3× error is
structural, and this line of enquiry is now closed rather than left open.

### The omitted emission seasonality is NOT negligible — it biases the fitted NEP amplitude by ~8 %

Neither input carries any seasonal cycle (DESIGN §3.6, "smooth annual→monthly"). Bounding
test — amplitudes deliberately **not** sourced, phases from tropical burning (NH dry season
Dec–Feb, SH Aug–Oct) and NH winter heating:

| imposed | MLO p-p | Δ p-p | Δ seasonal logL |
|---|---|---|---|
| LUC A = 0.3 | 4.553 | +0.084 | **+67.0** |
| LUC A = 0.6 | 4.637 | +0.169 | **+130.1** |
| *LUC A = 0.6, NH phase Jul (control)* | 4.329 | −0.140 | **−39.9** |
| fossil A = 0.06 | 4.588 | +0.120 | +61.3 |
| fossil A = 0.10 | 4.668 | +0.200 | +100.3 |
| **both (LUC 0.6, fossil 0.10)** | 4.838 | **+0.369** | **+225.8** |

**The headline: +0.369 ppm of omitted input seasonality is almost exactly what moving
`seas_amp_NH` from 12 to 13 GtC/yr does (+0.373 ppm).** So an omitted input seasonality of
plausible size is absorbed one-for-one by the single free NEP amplitude, **biasing it high
by ~8 %** — a physical signal reassigned to the wrong mechanism, which is overfitting in
its precise sense, in the highest-leverage stream in the whole objective.

**The phase control is what makes this more than "any extra variance helps":** flipping the
NH land-use peak from January to July turns +130 into **−40**. The gain is phase-specific,
not amplitude-generic.

**Honest confound, stated:** at default parameters the model's MLO peak-to-peak is 4.47 ppm
against gate 6's observed 6.86 (2010s), so the seasonal term rewards almost any correctly
phased amplitude. `seas_amp_NH` is calibrated and would rise to close that gap — which is
exactly the mechanism of the bias: it rises to cover an amplitude deficit that partly
belongs to the inputs.

**What this needs: a sourced monthly product for each input** — GFED for biomass burning
(the seasonal part of E_LUC), and a monthly fossil product for the NH winter cycle. Until
then the amplitudes above are a bound, not an estimate. **This is a new item for the
review's ordering**, and on the numbers it belongs alongside item 5 (the gradient terms):
both are about the model being scored on the wrong statistic.

## 2026-08-14 (cont.) — GLODAPv2 pulled (review item 4): the deep targets are sourced, and the σ turns out to BE the kz decision

`data-raw/build_glodap_deep_targets.R`, MANIFEST key `glodap_v2_2023`. GLODAPv2.2023
Merged Master File (110 MB zipped / 853 MB), glodap.info, doi:10.25921/z7hc-v261;
Lauvset et al. 2024, ESSD 16:2047, doi:10.5194/essd-16-2047-2024. 50,634 bottles carry
δ¹³C or Δ¹⁴C; 42,331 / 37,511 / 37,394 usable (flag 2) for Δ¹⁴C / δ¹³C / TCO₂.

**The model's "deep" is a specific layer, not a mood.** `ccx_ocean_grid(75)` puts the
bottom box at **2627.2–3700 m**, and `diagnostics$d14c_deep_by_hemi` — the quantity the kz
bracket was bisected on — *is* that layer. Observations are binned 5°×10°×250 m and the
cells weighted by cos(lat), because GLODAP over-samples the Atlantic relative to its volume.

| quantity, 2627–3700 m, volume-weighted | model | observed | spread |
|---|---|---|---|
| **Δ¹⁴C** | (kz-dependent) | **−175.3 ‰** (N-Atl cut −178.2) | ±45.9 |
| **δ¹³C** | **+1.560 ‰ UNIFORM** | **+0.424 ‰** | ±0.3 |
| **DIC** | **1986.3 µmol/kg UNIFORM** | **2273.1 µmol/kg** | ±53.9 |

**[a] The uncited bracket was RIGHT, and now has a source.** DATA.md §5's "roughly −150 to
−200 ‰" has a midpoint of −175, which is **within 0.3 ‰ of the measurement**. The recalled
number was good; it simply had no receipt. It has one now.

**[b] But the pull does NOT unblock the kz decision — it relocates it into σ.** 13i §A3
assumed GLODAP would supply "a real spatial spread for the sigma". It supplies the spread;
**the spread is not the sigma.** A one-box model is scored against the volume-weighted
*mean*, whose uncertainty is the spread ÷ an effective sample size — and deep water masses
are basin-coherent, so n_eff is of order tens, not the 3,592 cells. Measured against the
runaway that bare deletion produces (kz → 10,686, deep Δ¹⁴C −112.7 ‰):

| candidate σ | ‰ | runaway sits at | verdict |
|---|---|---|---|
| measurement error alone | 3.0 | 20.9σ | HOLDS kz |
| SE of the weighted mean, n_eff = 20 | 10.3 | 6.1σ | HOLDS kz |
| SE of the weighted mean, n_eff = 5 | 20.5 | 3.0σ | HOLDS kz |
| **full spatial spread (n_eff = 1)** | **45.9** | **1.4σ** | **DOES NOT HOLD kz** |

**And note what that means for the incumbent bracket:** [3830, 6200] is effectively a HARD
±25 ‰ box, **tighter than every candidate except the most aggressive n_eff**. Deleting it
in favour of an "honest" term would *loosen* the constraint, not tighten it. That inverts
the framing 13i §A3 was working under. **The σ is a methodological choice about
representation error and it is Marcus'** — it is now the whole of decision 1.

**[c] The pump's targets are quantified, and they are large.** The model's interior is
uniform in both tracers: the observed surface→deep DIC gradient is **+233 µmol/kg**
(2040 → 2273) against the model's **exactly 0**, and the observed δ¹³C gradient is
**−0.861 ‰** (surface +1.285 → deep +0.424) against the model's **0, at a uniform +1.560**.
The model's deep DIC is **12.6 % below** observed, which independently reproduces 13e §6's
"~14 % ocean inventory deficit" from a completely different measurement. Both observed
gradients are the signature a biological pump produces, so 13h §4.3's pump case now has
quantified targets rather than a direction — and the pre-registered ocean-sink test from
review §4.2 still gates whether it is a mechanism or bookkeeping.

**Correction to the repo's recollection:** the interior δ¹³C gradient was recorded as
"observed ~1–1.5 ‰". Volume-weighted over the model's own layers it is **0.861 ‰** — right
order, high by ~30 %. The model is +1.14 ‰ too enriched at depth and +0.28 ‰ at the surface,
so it is wrong in offset *and* in having no structure at all.

## 2026-08-14 (cont.) — DECISION 1 TAKEN: the deep-Δ¹⁴C term lands at σ = 10.3 ‰, the kz bracket STAYS, and the layer was mismatched

**Marcus took all three of the queued decisions on the recommended options:**

| | decision | taken |
|---|---|---|
| 1 | deep-Δ¹⁴C σ | **10.3 ‰** = spread ÷ √(n_eff = 20); **KEEP the kz bracket** |
| 2 | β default | **defer until item 7 lands** — no change, 0.75 still ships and still fails gates 7 and 12 |
| 3 | `sigma_d13c` | **stays free** — no change |

Only decision 1 is code. Decisions 2 and 3 are recorded no-ops, deliberately: the review's
headline is unmoved and nothing about the failing gates has been quietly improved.

### The term

`d14c_deep_ocean`, one scalar and one Gaussian, in `ccx_loglik()` behind a new `deep`
argument (`NULL` → the term is **ABSENT** under `by_stream`, not a silent zero). It is the
first term in the objective that prices ocean **ventilation**; until now nothing but δ¹³C
touched `kz`, which is why `kz` carries a hard bracket at all.

σ is **derived** from `LIK_D14C_DEEP_NEFF`, not typed twice — `ccx_deep_d14c_target()`
reads the GLODAPv2 build product and divides. A test asserts n_eff = 1 reproduces the raw
spread, so the constant cannot drift away from the number the likelihood uses.

### The bug this found: the target and the diagnostic were DIFFERENT LAYERS

`data-raw/build_glodap_deep_targets.R` measured GLODAPv2 over **2627–3700 m** and asserted
in its header that `diagnostics$d14c_deep_by_hemi` *is* that layer. **It is not.** That
diagnostic takes `tail(aux$idx[[h]]$oc, 3)` — the bottom **three** interior boxes,
**1313.6–3700 m** — which is better ventilated and runs 13.5–20.4 ‰ enriched across the kz
bracket (kz 5000: −170.1 against the bottom box's −186.4).

Scoring the 2627–3700 m target against the 3-box average would have been a ~1.6 σ layer
mismatch baked permanently into the objective. `diagnostics$d14c_bottom_box` (and
`d14c_bottom_by_hemi`) added to `R/spinup.R` for the term; the 3-box diagnostics are
**unchanged**, because the kz bracket and every pre-2026-08-14 result were derived from
them. The build script's header claim is corrected in place, not deleted.

**Consequence to carry:** handoff 2026-08-14b §4.1's "runaway at 6.1 σ" is the mismatched
pairing. Like for like it is **5.3 σ**. *The decision survives the correction* — 5.3 still
holds kz, and the verdict column of the σ table is identical either way — which is the only
reason this is a footnote rather than a re-take.

### Two things measured rather than assumed

- **Scoring the spinup steady state against 1972–2021 bottle data is legitimate.** The
  bottom box moves **+0.012 to +0.100 ‰** between 1750 and 2024 across the bracket, i.e.
  under 0.01 σ — the layer is effectively pre-bomb. So the term costs no transient
  integration. (The 3-box slab drifts up to **+2.49 ‰**, 25× more: a second reason the two
  layers are not swappable.)
- **The term is univariate in kz**, to the same standard `calibrate.R`'s bracket note
  claimed for the 3-box quantity. Across the *whole* `h_ml` prior [30, 200] the bottom box
  moves 5.3 ‰ (0.52 σ) and the layer's own top moves 50 m on a ~1070 m box, against the
  57 ‰ the kz bracket spans.

### Why the bracket stays — and where the term and the bracket disagree

Expressed on the bottom box, the incumbent bracket [3830, 6200] maps to [−220.4, −163.5] ‰:
a hard box of half-width **28.4 ‰**, tighter than every σ candidate but the most aggressive.
**Deleting it in favour of an "honest" likelihood term would LOOSEN kz, not tighten it** —
the inversion of 13i §A3's plan, and the reason decision 1 had to be re-taken.

But the bracket is centred at −191.9 ‰, **16.7 ‰ below** the sourced target. So:

| | kz | bottom box | z |
|---|---|---|---|
| bracket lower end | 3830 | −220.4 | **−4.40** |
| shipped default | 5000 | −186.4 | −1.08 |
| **term's own optimum** | **5525** | −175.3 | 0.00 |
| bracket upper end | 6200 | −163.5 | +1.15 |
| unbounded 17-par mode | 10686 | −120.9 | **+5.30** |

The term pushes kz **up inside** the bracket. That is one stream's preference at 9.0
log-units end-to-end — against the CO₂ streams' 1,565 per prior-sd step — so it is *not* a
counterweight to the CO₂ level; it acts on a parameter the CO₂ streams barely touch.
**kz is not re-centred by hand. The refit weighs it.**

### Methodological choice flagged, not buried

`LIK_D14C_DEEP_MASK_NATL = FALSE`. Masking the North Atlantic (the one place below 2000 m
with appreciable bomb ¹⁴C) moves the target −175.3 → −178.2 ‰ = 0.28 σ. The unmasked global
mean is used because the model's bottom box is a global quantity; the switch exists so the
alternative is one edit away rather than a re-derivation.

σ is also **not** inflated for model representation error, which the build script had
anticipated doing. 10.3 is the bare SE Marcus chose; inflating it silently would move his
number. If representation error is wanted it belongs in that constant, visibly.

### Files

`R/likelihood.R` (constants, `ccx_deep_d14c_target()`, the term, the `deep` argument),
`R/spinup.R` (`d14c_bottom_box`, report line with live z), `R/calibrate.R` (passes
`sp$diagnostics$d14c_bottom_box`; the kz bracket note now records why it was retained),
`data-raw/build_glodap_deep_targets.R` (header correction),
`calibration/diag_deep_d14c_term.R` (**new** — reproduces every number above),
`tests/testthat/test-likelihood.R` (4 new tests; 3 guard the decision, 1 the arithmetic).

**Suite still 11 failing, the same 11.** No new failures.

**Second positional-argument hazard.** `ccx_loglik()` now reads
`(out, obs, err, luc, deep, by_stream)`. Every caller in the repo passes `by_stream =` by
name so nothing broke, but a positional 5th argument now means `by_stream` and a positional
4th means `luc`. Name them.

## 2026-08-14 (cont.) — REVIEW ITEM 7: the saturating fertilisation form is BUILT, and it does what the log form provably cannot

**Status: mechanism built, gates measured, DEFAULT NOT MOVED.** `fert_form` still
selects `CCX_FERT_LOG` and `beta` is still 0.75, so nothing in the repo has changed value.
Marcus deferred the β default *to* this item (decision 2), and flipping it here would resolve
his decision for him — the numbers are below and the decision is his.

### The defect, restated as arithmetic

`NPP = NPP₀(1 + β ln(χ/χ₀))` locks the **enhancement** at today's CO₂ and the **slope** at
today's CO₂ into a fixed ratio (χ/χ₀), so β slides along it and cannot move one without the
other. The CO₂ record wants β 0.75; Joos gate 12 and the Revelle lesson both want ≤ 0.50.

### The replacement

Michaelis–Menten, `CCX_FERT_MM`: `NPP = NPP₀(1 + β_max·Δχ/(K + Δχ))`, Δχ = χ − χ₀, with
`beta_max` = fractional enhancement at infinite CO₂ and `fert_k` = the CO₂ increment above
preindustrial delivering half of it. Chosen over a bounded exponential because carboxylation
*is* an enzyme reaction, so the saturation has a one-sentence undergraduate explanation.

**Not a limit of the log form.** As `fert_k → ∞` MM goes *linear*, not logarithmic, so `beta`
does not map onto (`beta_max`, `fert_k`) by any substitution and a fit under one form is not
a fit under the other.

### The decoupling, measured on the design-target locus

Fixing `beta_max` by criterion (a) — match log β 0.70's enhancement at 388 ppm — and sweeping
`fert_k`:

| | enh@388 | slope@388 | ratio@1998 |
|---|---|---|---|
| log β 0.50 | 0.169 | 0.0773 | 1.99 |
| log β 0.75 (shipped) | 0.253 | **0.1160** | **2.48** |
| MM K=60 | 0.236 | 0.0447 | 1.35 |
| MM K=120 | 0.236 | 0.0662 | 1.46 |
| MM K=300 | 0.236 | 0.0931 | 1.74 |

The log rows move enhancement and slope **together**; the MM rows hold enhancement fixed
while the slope varies **2.1×**. Criterion (b) — slope ≤ β 0.50's 0.0773 — caps `fert_k` at
**171**; criterion (c) is met with room at every K.

### The gates, all four, at the shortlist

| case | loglik | CO₂ bias | z_land | z_ocean | gate 12 (Joos IRF 20/50/100) | Revelle lesson |
|---|---|---|---|---|---|---|
| **log β 0.75 (shipped)** | −3793 | **+3.34** | **+4.57** | −2.13 | **10.4/19.9/31.2 FAIL ×3** | **−0.113 REVERSED** |
| log β 0.50 | −9790 | −20.9 | +1.71 | −1.11 | 12.2/25.0/41.1 on the floor | +0.078 holds |
| MM K=100 | −3847 | +0.52 | +2.03 | −1.46 | — | +0.590 HOLDS |
| **MM K=120** | **−3760** | **+0.14** | **+2.28** | −1.52 | **12.4/25.6/41.9 INSIDE ×3** | **+0.566 HOLDS** |
| MM K=140 | −3725 | −0.12 | +2.50 | −1.57 | 12.2/25.0/40.8 inside, on the floor | +0.540 HOLDS |
| MM K=171 | **−3720** | −0.40 | +2.76 | −1.64 | 12.0/24.3/**39.4 FAIL** @20 & @100 | +0.498 HOLDS |

(Joos Table 4 5–95 %: 12.2–16.3 / 24.0–36.6 / 39.5–65.2. z on GCB's stated σ: land 0.5,
ocean 0.4.)

**MM K=120 beats the shipped default on the log-likelihood (−3760 vs −3793) while cutting the
CO₂ bias from +3.34 to +0.14 ppm, halving the land-sink miss (4.57σ → 2.28σ), passing gate 12
at all three horizons with margin, and restoring the Revelle lesson from −0.113 to +0.566.**
No value of β can do any two of those at once — that is the structural claim, discharged.

Gate 12 caps `fert_k` at ≈150 on the criterion-(a) locus, so the likelihood's own preference
(K 171) is just outside it. **That residual tension is real and is what the refit must settle.**

### Two things that came out NEGATIVE, recorded as such

- **`luc_scale` does NOT stack with this.** The obvious move — MM to fix the pulse, `luc_scale`
  to close gate 7 — makes things worse: at `luc_scale` 0.70 the CO₂ bias goes +0.14 → **+15.5
  ppm** and z_land gets *worse* (2.28 → 2.46). With the fertilisation parameters held there is
  no β left to relax, so the CO₂ bias absorbs the whole change. The two levers are partially
  **redundant** — MM at `luc_scale` = 1 already delivers the near-zero CO₂ bias `luc_scale` was
  introduced to buy. **The handoff's β 0.55 / `luc_scale` 0.70 settlement does not carry over
  to this form**; item 8's joint refit is what decides between them.
- **Matching the enhancement at 388 ppm does NOT match the historical integral.** The two forms
  cross at 388 by construction and disagree on both sides (MM is more responsive below, less
  above), and `cum_land` is not independent of `co2_bias` anyway. The integral is bought
  *through* the CO₂ record, so `co2_bias`/loglik are the columns that price it. The shortlist
  is built on those, not on `cum_land`.

### Flagged, not resolved

The high-background airborne fraction MM produces is **large and unbenchmarked** — 0.78 at
+100 yr on SSP5-8.5 (~1998 ppm) against the log form's 0.10. Gate 12 and Joos et al. (2013)
are both at a ~389 ppm background, so nothing in the literature set scores this. What the form
asserts is that at ~7× preindustrial CO₂ the land sink is close to saturated. That is a **model
claim at the far end of the app's own slider**, not a fitted result — but the log form's answer
there is not a safe fallback: it says the same pulse nearly vanishes in 100 years, which is
worse and in the direction that flatters the scenario.

### Files

`R/model.R` (`CCX_FERT_LOG`/`CCX_FERT_MM`, `CCX_FERT_FORM_DEFAULT`, `ccx_fert_factor()`,
three new params, the `ccx_deriv()` call site), `src/ccx_core.cpp` (the only other copy of the
factor), `R/cpp.R` (packing + defaults for pre-today parameter lists),
`calibration/diag_fert_saturating.R` (**new** — the locus, historical runs, gate 7, the
`luc_scale` negative result), `calibration/diag_fert_pulse_gates.R` (**new** — the Revelle
lesson), `calibration/diag_joos_beta_scan.R` (`CCX_FERT_*` env vars),
`tests/testthat/test-fertilisation.R` (**new**, 25 assertions).

**Suite still 11 failing, the same 11** — the default did not move, so nothing could. The five
`test-pulse.R` failures are exactly what the MM form fixes, and they will keep failing until
the default flips. **Leave them failing until then.**

## 2026-08-14 (cont.) — DECISION 2 TAKEN: the default IS the saturating form, `fert_k` 120 — and the flip caught three silent-inertness bugs

Marcus: *"Flip the default to MM."* `CCX_FERT_FORM_DEFAULT = CCX_FERT_MM`,
`beta_max` 0.4913, `fert_k` 120. This resolves the deferred β default: **`beta` is no longer
a live parameter and has left `CCX_PARAM_TABLE`** (17 → 18 parameters; `beta_max` + `fert_k`
in, `beta` out). The log form is **kept, not deleted** — `p$fert_form <- CCX_FERT_LOG`
reproduces every pre-flip result, and that is what makes the β-era record reproducible.

**The criterion was gate 12, not the likelihood.** `fert_k` 120 passes Joos at all three
horizons with margin (12.4/25.6/41.9); the log-posterior's own optimum on the design-target
locus is `fert_k` 171, which *fails* at TH20 and TH100. DESIGN §6 opens "all must pass before
headline claims", so the gate wins. **That is a choice and it is stated as one** — the gate
and the likelihood still pull apart, and the refit is what settles it.

### What the suite says: 11 failing → 8

**Six resolved by the flip**, and they are the ones that mattered:

- `test-climate.R:121, :122` — carbon-climate feedback, weakened by β 0.75. Now pass.
- `test-pulse.R:83, :100, :101, :112` — **the Pulse Lab**. `:100`/`:101` are the Revelle
  lesson, which was teaching the *opposite* of what the tab says (−0.113); it is now +0.566.

**Three genuinely new**, all one cause: the model now fits the CO₂ record so much better that
fixtures asserting "a bias is expensive" no longer start from an unbiased model. Measured on
the MLO annual record, model vs obs: **residual RMS 3.04 → 0.99 ppm**, mean residual
−1.49 → +0.80.

- `test-likelihood.R:114, :117` — `cost(1)` is now **−69.4**: shifting the model up 1 ppm
  moves it *toward* the observations. The AR(1)-pathology content these guard is intact and
  emphatic — `cost(50)` = **61,206** against the 10,000 threshold.
- `test-luc-scale.R:125` — wants the gross-vs-net gap > 10, gets 8.6. **That test's own
  comment predicted this**: the gap is large *because the model over-absorbs* (gross land
  4.57 vs GCB 2.36), and under MM it is 3.50, so the gap shrinks. "Do not fix this test by
  asserting gross beats net; that holds only for a model whose sink is right."
- `test-likelihood.R:135` — the `sigma_co2` profile peaks near the residual RMS, which moved
  3.04 → 0.99, so the bracketing sigmas are stale.

**NONE OF THE FOUR WAS EDITED TO PASS.** They are stale fixtures on an improved model, but
that is a judgement, and re-baselining a failing assertion is exactly how a real regression
gets absorbed. **Flagged for Marcus; left failing.**

### THREE SILENT-INERTNESS BUGS, all the same shape

Flipping the default made `beta` inert, and **every caller that set `beta` without setting
`fert_form` silently became a no-op.** All three were caught by *suspicious uniformity* —
identical rows where there should have been a spread — not by anything failing loudly.

1. **`R/mechanisms.R` — the app's "CO₂ fertilisation (the land sink)" switch.** `p$beta <- 0`
   moved CO₂ at 2100 by **exactly 0.00 ppm** while still rendering as a live control.
   `test-mechanisms.R`'s "every switch is wired up and CHANGES the answer" caught it. Now
   zeroes **both** `beta` and `beta_max`, which is correct under either form and cannot go
   stale at the next flip.
2. **`calibration/diag_fert_pulse_gates.R`** — its own log-form reference rows printed the MM
   answer to three decimals for every β. Caught by three identical rows.
3. **`calibration/diag_joos_beta_scan.R`** — `CCX_JOOS_BETA=0.50` would have returned the MM
   answer. It now implies `CCX_FERT_LOG`.

**Nine legacy diagnostics are pinned to `CCX_FERT_LOG`** (`diag_recentre_beta`,
`diag_beta_luc_profile`, `diag_luc_scale`, `diag_luc_prorata`, `diag_d13c_suess`,
`diag_d13c_partition_refit`, `diag_emission_scale_degeneracy`, `diag_1900_deficit`,
`diag_which_stream_pays`) with a comment saying why. They reproduce their recorded numbers
exactly — verified: `diag_fert_saturating.R`'s log-reference rows are bit-identical pre- and
post-flip. **The pin does not make them current**: anything there that fed a live decision
must be re-run under the saturating form.

### Quarantined

`calibration/output/mode_fit.rds` → `calibration/output/quarantine/20260814_pre_mm_fertilisation/`
with a README. Not a bug — a **model-structure change**. It is a 17-parameter posterior for a
model that no longer exists, and **no substitution carries it across** (MM → linear, not
logarithmic, as `fert_k → ∞`). `app/global.R`'s `identical(md$param_names, CCX_PARAM_NAMES)`
guard already rejected it; the quarantine stops anything else splicing it. The app now
correctly reports "uncalibrated defaults". **There is no canonical replacement until item 8
runs.**

### Also updated

- **`DESIGN.md` §6 gate 12 status** — was `12.6 / 26.2 / 43.6`, measured at **β 0.38, two
  re-centrings stale**, which is *why the failure at β 0.75 stayed invisible*. Now the
  measured pass, with the history written in and an instruction to re-measure on any
  fertilisation default change. **§6 gate 10** is no longer a "free check": it is the sourced
  GLODAPv2 term from earlier today.
- **`app/server.R`** — parameter labels for `beta_max` ("CO₂ fertilisation, maximum boost")
  and `fert_k` ("CO₂ needed for half that boost").
- **`app/global.R`** — the uncalibrated-defaults blurb said "β is set to the 1-D posterior
  optimum", false twice over now. Same failure mode as the deleted "about 27 ppm high" string.

### Priors, and why they are wide

Both new entries are uniform: `beta_max` on [0, 3.0], `fert_k` on [20, 2000]. **Nothing in
the literature set pins either at the ECOSYSTEM scale** — leaf-level Rubisco kinetics do not
transfer, and FACE experiments and CMIP6 models disagree by more than any prior width would
encode. The bounds are implausibility limits, not beliefs. If a sourced ecosystem-scale
constraint is ever found it belongs there with its citation.

## 2026-08-14 (cont.) — REFIT READINESS: item 8 is NOT unblocked, and two of the blockers got priced

Marcus asked to move to the refit "if that is the logical next step". **It is not**, and the
reasoning is measured rather than asserted. Handoff §6 blocks item 8 on items 2, 5, 5b, 5c, 6
and 7. **2 and 7 are now cleared.** The rest:

| blocker | priced | verdict |
|---|---|---|
| **5c** — omitted monthly seasonality in the emission inputs | **101 log-units** | **REAL. Blocks.** |
| **5 + 5b** — interhemispheric-gradient terms + time-varying LUC share | 5.1 log-units *today* | **Blocks, but only as a pair** |
| **6** — `LIK_EXCESS_C14_TARGET` | **0.7–1.4 log-units** | **NOT a blocker** — see below |

### 5c has teeth, and they are sharp

Measured directly: moving `seas_amp_NH` from 12 → 13 GtC/yr — an **8.3 %** change, which is
exactly the bias the handoff measured omitted LUC + fossil seasonality to induce — moves the
objective by **+101.1 log-units**, of which `co2_seasonal_MLO` supplies **+131.5**. So the
one free NEP amplitude absorbs the missing input seasonality one-for-one, in the objective's
most sharply-curved stream. **A refit today would bake an ~8 % input error into a fitted
parameter**, which is the same error class `luc_scale` was created to fix. The objective also
already *prefers* 13 to 12 by 101 log-units, so the fit will move `seas_amp_NH` up while the
input correction would move it back down — the two are directly confounded.

### 5 and 5b block only as a pair, and 5 is what makes 5b matter

The objective still barely sees the interhemispheric gradient — 5.1 log-units for 0.84 ppm.
So fixing the LUC hemispheric share alone (5b) changes essentially nothing in a fit, and the
review was right that it must land *with* 5. But **5 adds a stream**, and adding a stream
after a fit invalidates the fit. Either both before the refit, or both after — not split.

### 6 is CHEAPER than the ordering assumed, and a repo claim did not survive checking

`R/likelihood.R` asserted that choosing between the two published excess-¹⁴C reconstructions
"would put **~130 log-units** of leverage on a choice of paper". **That number has no receipt
anywhere in the repo and does not reproduce.** Measured at the current default and swept
across `bomb_total` 80–130 kmol, `table4_obs_range` and `table2_peacock` differ by
**0.7–1.4 log-units** — the model's own excess inventory sits between them and both terms are
weak there (−6 to −10). The *direction* survives (`table2_peacock` is ~3× tighter and would
constrain harder as a fit moved away from it); the *magnitude* was pattern-matched. The
comment now says so and asks for a receipt or a correction. **Practical consequence: item 6's
remaining half is not a blocker on the refit.** `sigma_d13c` was already decided (stays free).

### What IS worth running now, and is running

A **MAP mode-find** — `calibration/run_modefind.R`, regenerating the canonical
`calibration/output/mode_fit.rds` the flip quarantined. Cheap relative to MCMC (~0.060 s per
posterior evaluation), and it answers the one question the flip left open: **where do
(`beta_max`, `fert_k`) sit under the FULL objective**, given that gate 12 caps `fert_k` near
150 while the 1-D likelihood on the design-target locus preferred 171. It is explicitly a
point, not a posterior, and does **not** discharge item 8.

### Recommended ordering

1. the mode-find (running) — gives the app a calibrated point and settles the `fert_k` tension
2. **5c** — sourced monthly seasonality for both emission inputs (GFED + a monthly fossil
   product). The only blocker measured to bias a fitted parameter today.
3. **5 + 5b together** — the gradient terms and the time-varying LUC hemispheric share
4. **8** — the refit, ~2 h wall-clock on 4 parallel chains at 0.060 s/eval

### Also

`DESIGN.md` §6 **gate 7** now carries a measured status line (**still failing**: land +2.28σ,
ocean −1.52σ, down from +4.57σ / −2.13σ) with the gross-vs-net trap named and a note that
`luc_scale` does *not* close the remainder under the saturating form.

## 2026-08-14 (cont.) — THE MAP MODE UNDER THE SATURATING FORM: gates 7 AND 12 both pass, for the first time

`calibration/run_modefind.R`, 18 parameters, 293.6 min / 291,832 posterior evaluations at
0.060 s each. **Log-post −3774.0 → −2221.3, a gain of 1552.8** — of which 1532 came in the
first restart, since the hand-set start carried two brand-new parameters against an objective
that had also gained the deep-Δ¹⁴C term and the corrected GCB land term. Hessian
positive-definite, condition number 6.8e5. **No parameter beyond 3 prior sds.** Written to
the canonical `calibration/output/mode_fit.rds`; the app now reports "posterior mode / single
best fit" instead of uncalibrated defaults.

### The headline: the review's two failing hard gates both pass

| | review §0 (β 0.75) | MM default (`fert_k` 120) | **MAP mode** |
|---|---|---|---|
| **gate 7** land | **+4.57σ** | +2.28σ | **+1.54σ** (3.13 GtC/yr) |
| **gate 7** ocean | −2.13σ | −1.52σ | **−0.35σ** (3.08) |
| **gate 12** Joos IRF | **10.4/19.9/31.2 FAIL×3** | 12.4/25.6/41.9 | **12.6/26.0/43.0 INSIDE×3** |
| Revelle lesson | **−0.113 REVERSED** | +0.566 | **+0.515 HOLDS** |

**Gate 7 has never passed before.** DESIGN §6 opens "all must pass before headline claims";
on this evidence the two that were blocking do.

Paired sanity suite at the mode (per the `climate-modeling` discipline): **zero-pulse
max|ΔCO₂| = exactly 0**; sign-flip +19.78 / −18.71 ppm at +100 yr (correctly asymmetric);
halving ratio **0.4931** against 0.5 (correctly sublinear — larger pulses see a stiffer
Revelle factor).

### The fertilisation pair barely moved where it counts

`beta_max` 0.4913 → **0.5087**, `fert_k` 120 → **153.1**. `fert_k` moved 28 % — past the ~150
gate-12 cap measured on the *design-target locus* — **but the gate did not break, and the
reason is the point of the whole form change.** `beta_max` moved with it, so the marginal
slope at 388 ppm went 0.0662 → **0.0669**, essentially unchanged and still well under the
0.077 ceiling. The fit slid *along* the decoupled direction the log form does not have. The
apparent likelihood-vs-gate tension recorded at the flip was an artefact of scanning a
one-parameter locus.

### THREE THINGS THAT MUST NOT BE BURIED

**1. `sigma_co2` collapses to its prior tail (0.223, z −2.56) — and the cause is not the AR(1)
pathology.** The MLO residual RMS at the mode is **0.642 ppm**, so RMS/`sigma_co2` = 2.88,
which reads like the collapse this repo has history with. It is not: the likelihood uses
`sqrt(sigma_co2² + LIK_CO2_REP_ERR²)` and **`LIK_CO2_REP_ERR` is fixed at 1.0 ppm**, so the
effective sd is 1.025 — *larger* than the residual it is explaining. **The model now fits the
CO₂ record better than the assumed station-vs-hemispheric-box representation error**, leaving
`sigma_co2` nothing to do. That 1.0 ppm constant is now the binding term in the objective's
highest-leverage stream and needs re-deriving, not the free parameter. (δ¹³C is healthy by
comparison: RMS 0.383 against `sigma_d13c` 0.336, ratio 1.14.)

**2. Both ocean-uptake parameters are pressed against their bounds, and that points at the
pump.** `kz` = **6119**, which is **96.6 %** of the way to its bracket's upper bound; `h_ml` =
**184.0 m**, **90.6 %** of the way up a uniform [30, 200] prior and far deeper than any
plausible global-mean mixed layer. The deep-Δ¹⁴C term is being overridden to get there — the
bottom box lands at −157.8 ‰, **z +1.70** against its own target. So the ocean is being forced
to absorb more carbon by whatever means the parameters allow, which is exactly the signature
review §4.2's pre-registered pump test predicts. **The `kz` bracket Marcus retained this
morning is now demonstrably load-bearing**: without it this mode would have run `kz` away
again.

**3. `luc_scale` = 1.0049 — it does not move.** The parameter added this morning to give
E_LUC its own uncertainty sits *on* its prior median. Under the saturating form the fit does
not want it, which confirms from the fit side what §5 of `diag_fert_saturating.R` measured
by hand: **MM and `luc_scale` are redundant, and MM won.** The handoff's β 0.55 / `luc_scale`
0.70 settlement is now doubly superseded. `luc_scale` should be kept (it costs nothing and it
prices a real input uncertainty) but it should stop being described as the lever that closes
the sink partition.

### Still outstanding, and the mode sharpens one of them

`seas_amp_NH` fits to **19.66** GtC/yr against a default of 12 — a 64 % move, in the stream
where an 8 % shift is worth 101 log-units. Item **5c** (sourced monthly seasonality for both
emission inputs) is confounded with this parameter and remains the blocker with teeth.
**This is a MAP point, not a posterior**, and items 5, 5b and 5c would each invalidate one —
so it does not discharge item 8. `bomb_total` fits to 113.97 (z +2.50), the highest-tail
parameter in the vector, and is worth watching when a posterior does exist.

## 2026-08-15 — ITEM 5c: the emission inputs now carry sourced monthly seasonality

Both emission inputs reached the model with **no within-year cycle at all** —
`ccx_annual_to_monthly()` interpolates the annual *trend* smoothly and leaves every month
within a whisker of its annual mean. Real fossil emissions peak in NH January and real
land-use fire peaks in the burning hemisphere's dry season, and the model's single free NEP
amplitude was absorbing the difference.

### Sources

| | dataset | citation |
|---|---|---|
| **fire** | GFED4.1s, monthly 0.25°, **2001–2016** | van der Werf et al. 2017, ESSD 9:697–720, doi:10.5194/essd-9-697-2017 |
| **fossil** | EDGAR v4.3.2 monthly, by country × IPCC sector, 1970–2012 | Crippa et al. 2020, Sci Data 7:121, doi:10.1038/s41597-020-0462-2 |

Both in `MANIFEST.csv`. The bulk inputs (1.2 GB of GFED HDF5, a 26 MB EDGAR xlsx) are
gitignored; `data-raw/extract_emission_seasonality.py` reduces them to two ~30 KB CSVs which
**are** committed, so a fresh clone can rebuild without re-downloading.

GFED beta years (2017+) are excluded — the product's own header says they are extrapolated
and "not suitable for trend analyses". 2001 is the start of the MODIS record it is built on.

### The weights, and the phase checks that make them falsifiable

| | J | F | M | A | M | J | J | A | S | O | N | D |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| fossil NH | **1.29** | 1.12 | 1.06 | 0.93 | 0.87 | 0.86 | 0.88 | 0.87 | 0.89 | 0.97 | 1.05 | 1.21 |
| fossil SH | 0.94 | 0.95 | 0.93 | 0.95 | 0.98 | 1.07 | **1.21** | 1.05 | 1.04 | 0.99 | 0.95 | 0.94 |
| LUC fire NH | 1.84 | 1.90 | **3.15** | 1.29 | 0.74 | 0.66 | 0.75 | 0.63 | 0.13 | 0.10 | 0.16 | 0.64 |
| LUC fire SH | 0.02 | 0.02 | 0.03 | 0.02 | 0.21 | 0.57 | 0.87 | 3.26 | **5.03** | 1.64 | 0.25 | 0.07 |

Fossil NH peaks in January and fossil SH in July — **opposed, because the driver is winter
heating**. LUC fire SH peaks in September — the southern-Africa / Amazon / Indonesia dry
season. Both are asserted in `test-emission-seasonality.R`, because a sign or index error
sails straight past a conservation test.

### THE LOAD-BEARING DECISION: E_LUC is not fire

GFED's deforestation-and-peat carbon is **0.367 PgC/yr** (2001–2016) against GCB's E_LUC of
**1.699 GtC/yr** — so **only 21.6 % of E_LUC burns**. The rest is wood harvest, product decay
and soil-carbon loss, with no comparable cycle. The land-use weight is therefore **damped**:

> `w_eff(m) = 1 + f_fire · (w_fire(m) − 1)`, with `f_fire = 0.216` **measured, not assumed**

Applying the raw fire shape to all of E_LUC would have overstated the correction by ~4.6× —
**in the direction that looks like success**, since a bigger input seasonality pulls
`seas_amp_NH` further and would read as a bigger fix. Fossil is *not* damped: all of it is
combustion. `f_fire = 0` reduces exactly to the incumbent model, which is what makes the
change auditable. Savanna and agricultural-waste burning are excluded on purpose — they are
recurring cycles whose regrowth returns the carbon, not land-use *change*.

### What it bought

At the MAP mode's other parameters, profiling `seas_amp_NH`:

| | `seas_amp_NH` | log-post |
|---|---|---|
| seasonality OFF | **19.66** GtC/yr | −2194.0 |
| seasonality ON | **18.65** | −2195.3 |

**−1.01 GtC/yr, −5.1 %**, in the predicted direction. (The OFF value reproduces the
mode-find's fitted 19.66 exactly — an independent check that the profile machinery and the
MCMC agree.) The handoff's bounding test predicted ≤8 %; the sourced version comes in at
5.1 %, which is right, because that bound used an undamped "plausible size" and the measured
`f_fire` is 0.216.

**BE CLEAR ABOUT WHAT THIS IS: a bias correction, not a fit improvement.** The log-posterior
is **1.3 units WORSE** at the new optimum. The model fitted the seasonal cycle slightly better
when it could pour all the seasonality into one free parameter. The value of the change is
that `seas_amp_NH` now means what its name says — biosphere NEP amplitude — instead of
"biosphere NEP plus whatever the inputs should have contributed". Anyone hoping 5c would raise
the log-posterior should stop expecting that.

### Conservation

Seasonality redistributes within a year and must create nothing. `ccx_seasonalise()`
multiplies by the weight and then rescales each calendar year back to its own pre-weighting
mean. Measured: **max |Δ annual total| = 1.8e-15 GtC/yr** (fossil), 4.4e-16 (LUC), and the
final cumulative land-use carbon matches to 6.8e-13 GtC. `cum_luc` is now integrated **per
hemisphere from the seasonalised flux** rather than split from a global series — the two agree
at every year boundary but not within a year, and the converted-land term reads it monthly.

### Bonus finding, for item 5

The EDGAR country aggregation measures the **NH share of fossil CO₂ at 0.9201**, against
`FORC_FOSS_NH_SHARE = 0.95`, which has carried a "PROVISIONAL" comment since it was written.
**Not changed here** — it feeds the interhemispheric gradient (item 5), where the handoff
prices 0.90 → 0.97 at 0.84 ppm of MLO−SPO for 5.1 log-units. That is item 5's decision, and
the measurement is now waiting for it.

### Files

`R/forcing.R` (`FORC_USE_EMIS_SEASONALITY`, `ccx_emission_seasonality()`,
`ccx_seasonalise()`, per-hemisphere `cum_luc`), `data-raw/extract_emission_seasonality.py`
(**new**), `data-raw/build_emission_seasonality.R` (**new**),
`data/forcing_emission_seasonality.rds` (**new**), `tests/testthat/test-emission-seasonality.R`
(**new**, 41 assertions), `MANIFEST.csv`, `.gitignore`.

**Suite still 8 failing, the same 8.** No new failures.

---

## 2026-08-15 (later) — ITEMS 5b AND 5: the hemispheric shares are sourced, and the gradient is finally in the objective

Review items **5b** and **5** landed together, in that order, because 5 is the only thing
that can score 5b. With 5c already done on the same day, the review ordering now has
**items 1–5c and 7 discharged** and item 8 (the refit) unblocked on everything except the
four test failures still waiting on Marcus.

### 5b — the land-use hemispheric share (`98f0457`)

`FORC_LUC_NH_SHARE = 0.55` had carried a "provisional" comment since it was written and is
wrong at **both** ends. OSCAR v3.1's *Regional* sheet — the same workbook DATA.md §3a already
uses for the pre-1850 E_LUC segment, whose 1750–2018 total reproduces the paper's 206 PgC
headline — gives a flux-weighted NH share of **0.838 (1750–1849) → 0.398 (1990–2018)** as
clearing moved from temperate NH forests to the tropics. Against the constant that is
**+31 GtC** of cumulative land-use carbon misplaced by 1959.

The within-region NH fractions are geographic judgements, not data, so the product ships a
lo/central/hi bracket — and **the direction survives all of it**: pre-1950 even the low end is
≥ 0.60, post-1990 even the high end is ≤ 0.53. The two ends do not overlap under any
admissible judgement, which is what makes *"no constant works"* a measurement. 0.55 is not
even the flux-weighted mean (0.620).

Three properties that could each have been silently wrong, all gated by
`test-luc-nh-share.R` (22 assertions), two of them mutation-tested:

- **One share per calendar year, held, not interpolated to months** — keeps
  `mean_year(luc_NH) = share(y)·mean_year(luc)` exact and puts the only discontinuity on the
  year boundary, where the per-year harmonic estimator cannot alias it into the seasonal
  statistic.
- **The pre-window cumulative takes its own flux-weighted share.** A run from 1900 splits
  ~58 GtC of prior clearing on the pre-1900 share (~0.79), not the window's (~0.49). Getting
  this wrong misplaces ~14 GtC of converted land and **nothing else in the suite would see
  it** — the flux still conserves.
- **Outside 1750–2018 the end value is held**, stated as extrapolation: every SSP run splits
  on a frozen 2018 share. Extrapolating the decline forward runs it negative before 2260.

`FORC_USE_LUC_NH_SHARE_TS = FALSE` reproduces every earlier result, max |diff| **exactly 0**
across every numeric column of both a full-record and a windowed forcing.

**What it bought, and what it did not.** Gradient 5.26 → 5.03 ppm (obs 3.97). δ¹³C gradient
barely moved (−0.245 → −0.238 vs −0.074), **confirming the shares are not the cause of that
3× miss** — that lead is dead. **Log-posterior DOWN 17.2**, almost all in `co2_seasonal_MLO`.
A bias correction, not a fit improvement, exactly as 5c was.

### 5 — the measurement first (`abf8e3b`), then the terms

`calibration/diag_gradient_terms.R` measured the five things the σ depends on before anything
was written, because **the σ is the decision**:

1. **The likelihood's own estimator reproduces gate 9** to ≤ 0.02 ppm on every decade it
   covers, and drops the 1950s entry (8 paired months, "indicative only" by gate 9's own
   note). No new estimator; design note 1b's same-machinery-both-sides property preserved.
2. **Observational floor ~0.23 ppm, measured** — Scripps vs NOAA disagree by 0.225 ppm RMS on
   the annual gradient. And it is a *lower* bound: handoff 15 §4.1's flag is **confirmed**,
   `MLO` and `MLO_NOAA` agree to **0.002 ppm RMS over 189 months** — one series under two
   names. So 0.225 is the two SPO records alone. For δ¹³C the floor is 0.0152 ‰ and *that* one
   is a genuine two-station two-network comparison (the records share no month timestamps).
3. **The miss is not one thing, and the two species differ.** CO₂: intercept **and** slope
   rejected — a stable −0.45 ± 0.10 ppm offset (the sign and size a station-below-the-source-
   region argument predicts) *plus* a real shape error whose sign changes across the record
   (b = 0.845 at defaults, 1.14–1.23 at the mode). δ¹³C: **b = 1 admissible in all four fits**,
   only the +0.10 ‰ intercept rejected — a pure offset, and **8× larger** than scaling CO₂'s
   19 % predicts, so it is absorbing the known structural δ¹³C misfit rather than a
   representation constant.
4. **The double count is second-order.** The two station levels imply a gradient sd of 1.45 ppm
   (2.55 at σ_co2 = 1.5); a term at 0.35 outweighs that ~17× in variance. **Adding** a term is
   correct; rotating the (MLO, SPO) pair would rewrite the two highest-leverage streams to fix
   something that is not binding.
5. **The leverage is large and points the other way** — +193/−643 log-units per prior sd of
   τ_ex at σ = 0.35, against τ_ex's whole prior leverage of ~350, and **opposite in sign** to
   what the rest of the objective wants (−207/+105).

**Marcus's three decisions, all taken on those numbers:** level + offset parameter for CO₂;
same treatment for δ¹³C; and move `FORC_FOSS_NH_SHARE` 0.95 → **0.9201** (measured, EDGAR
v4.3.2) — the gradient term prefers it by +95 log-units and the rest of the objective is
indifferent (−1.5).

**Shipped.** Streams `co2_gradient` and `d13c_gradient`; parameters **18 → 20**
(`grad_off_co2` N(0, 0.5) ppm, `grad_off_d13c` N(0, 0.15 ‰), both **shrinkage priors centred
at zero** — centring them on the measured offsets would tell the model the answer and then
credit it for agreeing). σ = the measured model-vs-obs scatter about a constant offset,
floored by the observations' own precision: **0.35 ppm / 0.025 ‰**. Both terms start near
χ²/dof ≈ 0.6.

**The offsets ride in `err`, and their ABSENCE skips the terms** rather than defaulting to
zero — the same contract `deep` uses. A zero offset is not a neutral default: it asserts the
box gradient *is* the station gradient, which the measurement rejects at 95 %. Every
diagnostic written before today therefore shows the streams as ABSENT under `by_stream`,
which is visible, instead of scoring them wrong.

**Effect.** τ_ex's constraint is now dominated by the gradient (+366/−950 log-units per prior
sd) and it pulls **opposite** to everything else (−208/+107). DESIGN's decade-old claim that
gate 9 constrains τ_ex is true for the first time.

### Tried and NOT done

- **Rotating (MLO, SPO) → (mean, gradient).** Statistically the cleanest answer to double
  counting, and rejected on measurement: the overlap is second-order (§4 above), so the
  rotation would rewrite the objective's two highest-leverage streams to fix something that is
  not binding.
- **Interpolating the land-use share smoothly to months.** Would cost the exact annual
  identity and buy nothing — the share moves ~0.0016/yr, so the calendar-year step is
  ~0.003 GtC/yr and, being *on* the year boundary, cannot alias into the seasonal statistic.
- **Making `FORC_FOSS_NH_SHARE` a calibrated parameter.** Offered and declined: it would
  correlate hard with the land-use share and τ_ex, and the sampler already has an r = −0.907
  pair to manage.
- **Centring the offset priors on the measured intercepts.** That is a measurement wearing a
  prior's clothes. Both are centred at zero and the prior *widths* were chosen so the measured
  values sit near 1 sd.

### Quarantined

`calibration/output/mode_fit.rds` → `calibration/output/quarantine/20260815_pre_gradient_terms/`
with a README. Not a bug — the 18-parameter mode belongs to a model with a different input
(5b) and an objective with two fewer streams, and its log-posterior is **not on the same scale**
as anything computed after today. The canonical path is **empty** until item 8 runs.

**Files:** `R/likelihood.R`, `R/calibrate.R`, `R/forcing.R`, `DATA.md` (§6, new §6a),
`DESIGN.md` (gate 9), `data-raw/build_luc_nh_share.R` (**new**),
`data/forcing_luc_nh_share.rds` (**new**), `calibration/diag_gradient_terms.R` (**new**),
`calibration/output/gradient/` (**new**), `tests/testthat/test-luc-nh-share.R` (**new**, 22),
`tests/testthat/test-gradient.R` (**new**, 28), `tests/testthat/test-likelihood.R`
(the 18 → 20 tripwire, recorded not bumped, per that test's own convention).

**Suite still 8 failing, the same 8.** The parameter-count tripwire fired as designed and was
recorded; no new failures.

### Later the same day — three of the four flagged tests, RE-EXPRESSED not re-baselined

Marcus took all three. Each repair replaced a hard-coded fixture with a **derived** quantity,
and each was mutation-tested. **Suite 8 → 4 failing, 695 passing.**

| test | was | now |
|---|---|---|
| `test-likelihood.R` CO₂-bias | `cost(1) > 100` measured **from zero** | cost measured **from the fitted offset**; the guard is the **curvature**, A > 10 log-units/ppm² (AR(1) pathology was ~0.0055, so a ~1800× margin) |
| `test-likelihood.R` σ_co2 profile | collapsed value must lose to a hand-picked σ = 5 | the profile optimum, as an **effective sd**, within 1.5× the **measured residual RMS** |
| `test-luc-scale.R` gross-vs-net | `abs(gross − net) > 10` | the **closed-form E_LUC displacement**, asserted to 1e-8, plus a materiality check |

**Every one had gone stale for the same reason: the model improved.** The CO₂-bias test was
measuring the model's own level bias rather than the price of a bias (MLO residual mean is now
+0.97 ppm, so a +1 ppm shift is an *improvement* and "cost(1)" is −68), and it broke twice as
the level fit got better. σ = 5 stopped being a sane comparator once the residual RMS fell to
~1.13 against a *fixed* `LIK_CO2_REP_ERR` of 1.0 — and handoff §4.1 had already established
that σ_co2 → 0 is the **correct** inference here, not the AR(1) pathology it resembles. The
gross-vs-net gap is large *because the model over-absorbs*, so it shrinks as the sink improves
(4.57 → 3.50 → 3.48 GtC/yr): that test used a symptom of the old bug as a proxy for the fix and
would have failed **harder** the more the refit succeeded.

**Mutation tests.** Reverting `gcb_land_sink` to the NET comparison → 2 failures in
`test-luc-scale.R`. Inflating the CO₂-level sd 30× (the AR(1) loophole in effect) → 3 failures
in `test-likelihood.R`. Both gates have teeth.

**The 4 that remain were never flagged for Marcus and are untouched:** `test-luc-permanence.R`
(the fossil reference arm; and a case needing `f_luc_wood = 1` that sets only `f_luc_perm`),
`test-mechanisms.R` (ENSO switch weak, 0.30 vs > 0.5), `test-pulse.R` (ssp119 airborne
fraction, an *unbenchmarked* ballpark check on a declining background while the
protocol-matched gate 12 passes).

### The refit is HELD

Item 8 is structurally unblocked by 5 + 5b. **Marcus held it** pending the `sigma_co2` decision
(unidentified, pinned at a boundary, "fix it or drop it, do not sample it"). ~6–7 h at 20
parameters and 0.083 s/eval. `calibration/output/mode_fit.rds` stays **empty** until it runs.

## 2026-08-15 (later still) — ITEM 6b MEASURED: the case against `sigma_co2` largely does not hold

`calibration/diag_sigma_co2.R` (new, ~1 min, output `calibration/output/sigma_co2/`). **No code
changed.** This is the measurement the `sigma_co2` decision was waiting on, and it was run
before touching the parameter because the previous two handoffs asserted a pathology from a
single number (σ_co2 = 0.223 at the MAP mode, z ≈ −2.6) without testing the claims that number
was taken to imply.

**The analytic frame, first, because it reorganises everything.** The CO₂ level terms use
sd = √(σ_co2² + `LIK_CO2_REP_ERR`²) with the constant fixed at 1.0 ppm. Writing v = σ² + c²,
the ML solution is v = R² for pooled residual mean-square R², so **σ*² = R² − c² — which has no
real solution whenever the pooled residual RMS falls below 1.0.** "Pinned at a boundary" is
therefore not a property of `sigma_co2`; it is a statement about R.

**And R is not one number.** The repo straddles the threshold:

| parameter point | R_MLO | R_SPO | R_pool | interior optimum? |
|---|---|---|---|---|
| `ccx_default_params()` | 1.127 | 1.750 | **1.454** | **YES**, σ* = 1.056 |
| pre-gradient MAP mode | 0.650 | 0.571 | **0.614** | NO — likelihood monotone decreasing |

The same model at two points in its own parameter space sits on opposite sides. That is also
why `test-likelihood.R`'s interior-maximum assertions still pass: its fixture is on the other
side. The margin at the mode is **0.789 ppm** of additional sustained bias — well inside an
MCMC chain's early excursions.

**Three of the four stated grounds are refuted:**

- **"Pinned at a boundary."** Not in the coordinates the sampler uses. `sigma_co2` is
  log-transformed; σ → 0 is u → −∞ and the lognormal prior closes it off smoothly. The
  posterior mode is **interior and unimodal on the log scale at both points** (0.226 at the
  mode, 1.072 at defaults). There is no edge to be pinned against.
- **"Will hurt covariance conditioning."** Measured from the stored Laplace correlation:
  **max |r| = 0.043** (with `luc_scale`), against a worst pair of **0.907** (`luc_scale`–`fert_k`)
  in the same matrix. `sigma_co2` is very nearly orthogonal to every other parameter.
- **"Unidentified."** The data tighten it **2.08×** relative to prior at the mode and **5.79×**
  at defaults. It ranks 4th of 18 by posterior width (0.324 unconstrained) — behind
  `npp_frac_NH` (1.318), `h_ml` (0.984) and `kz` (0.978), none of which is proposed for removal.

**One objection survives, and it is a different one — none of the handoffs made it.**
`sigma_co2` is a free error scale on the stream that already outvotes the partition terms 40:1,
which makes it **self-weighting**: the better CO₂ is fitted, the smaller σ goes, and the louder
the CO₂ stream becomes. Measured across the two points, as R fell 1.454 → 0.614 the effective
sd fell 1.4659 → 1.0251, i.e. the CO₂ level stream got **2.04× louder in variance terms**.
Positive feedback on the dominant constraint, in the direction that worsens the imbalance the
whole review is about. Nothing in the objective asked for it.

**What each option costs**, in the only currency that matters (the effective sd *is* the stream
weight):

| option | σ_co2 | effective sd | weight vs free | implied gradient sd | vs `LIK_GRAD_CO2_SD` |
|---|---|---|---|---|---|
| DROP (fix at 0) | 0.000 | 1.0000 | 1.05× | 1.414 | 16.3× |
| FIX at the MAP value | 0.223 | 1.0246 | 1.00× | 1.449 | 17.1× |
| FIX at the prior median | 1.500 | 1.8028 | 0.32× | 2.550 | 53.1× |

The first two are within 5 % of each other and of the status quo, so the `LIK_GRAD_*` "re-measure
if σ_co2 moves" condition is satisfied either way — the ~17× that justified *adding* a gradient
term rather than *rotating* the (MLO, SPO) pair survives at 16.3×. The prior-median option is a
real 3× re-weighting and is not a null choice.

**Stated cost of fixing it, since it is not zero:** the free σ is also the only adaptive valve on
the CO₂ level stream, and part 2 shows chains will cross back into R > 1.0 where a fixed σ prices
a bad CO₂ fit at full volume with no give.

**Decision goes to Marcus** (stream weighting, per the standing rule that weighting choices are
never resolved silently). The refit stays HELD.

## 2026-08-15 (later still, part 2) — ITEM 6b TAKEN: `sigma_co2` retired, 20 → 19 parameters

**Marcus's call on the measurement above: fix at 0.** The CO₂ level sd is now
`LIK_CO2_REP_ERR` = 1.0 ppm alone — the half of the old √(σ_co2² + c²) that has a receipt
(co-located independent programmes at MLO disagree by 0.39–0.59 ppm RMS, n = 702 months). **The
refit remains HELD**; item 6b is discharged, so item 8 is now unblocked on the objective side.

**The reason is recorded in three places (`R/calibrate.R`, `R/likelihood.R`,
`test-likelihood.R`'s parameter ledger) because it is NOT the reason the two prior handoffs
gave.** Those grounds — boundary-pinned, unidentified, bad for covariance conditioning — were
measured and failed on all three counts. What retired it is that a free error scale on the
stream that already outvotes the partition terms 40:1 is **self-weighting**: as the pooled
residual fell 1.454 → 0.614 ppm the effective sd fell 1.4659 → 1.0251, making the CO₂ level
stream **2.04× louder**. Positive feedback on the dominant constraint.

**Changes.**

- `CCX_PARAM_TABLE$sigma_co2` removed; `ccx_make_logpost()` omits the field **explicitly**
  rather than passing a zero — the two are identical arithmetic today, so passing 0 would let a
  future contract change silently revert to the old branch.
- `ccx_loglik()` gains a two-branch contract on the CO₂ level sd: **absent → `LIK_CO2_REP_ERR`**
  (the objective), **present → the old quadrature** (legacy parity). The absence being the *new*
  behaviour inverts this repo's usual absence-skips-a-stream idiom, deliberately: an updated
  caller says so by dropping the field, and a stale one keeps its old weight instead of being
  silently re-weighted. **Verified: `diag_sigma_co2.R` reproduces bit-for-bit across the change.**
- `LIK_CO2_REP_ERR`'s comment now carries its receipt and states that it is **conservative, not
  tight** — χ²/dof ≈ 0.38 against the last mode's residual. Lowering it would give the loudest
  stream *more* leverage and is flagged as a stream-weight change, not taken.
- Objective re-checked end to end: 19 parameters, finite log-posterior at init (−4057.94).

**What was given up, stated because it is not nothing:** the free σ was the only adaptive valve
on the CO₂ level stream, and the margin at the mode is 0.789 ppm of extra bias, so chains *will*
cross into R > 1.0 where a fixed sd prices a bad CO₂ fit at full volume. If the refit shows that
biting — CO₂ level dominating the trace, or a chain unable to leave a bad-CO₂ region — this is
the first thing to look at. Recorded in `R/calibrate.R` next to the retirement.

**Tests: +5 assertions blocks, all three mutation-tested, suite still 4 failing (unchanged).**

| new gate | asserts |
|---|---|
| `test-likelihood.R` absent-σ contract | the sd is **exactly** `LIK_CO2_REP_ERR`, is *not* some other constant, and σ_co2 = 0 agrees to 1e-12 |
| `test-likelihood.R` legacy parity | σ_co2 ∈ {0.223, 1.5, 5} still reproduces √(s² + c²) |
| `test-likelihood.R` direction + magnitude | retirement **hardened** the stream (strict, both σ), weight change < 1.10×, and `sigma_co2` is gone from `CCX_PARAM_NAMES` |
| `test-gradient.R` case 6 | the double-count ratio, **re-measured** at 16.3× — a pure constants check now that `LIK_CO2_REP_ERR` is its only input |

**Mutations, all caught:** loosening the absence branch to 1.5× → 4 failures; dropping the
quadrature from the legacy branch → 5; lowering `LIK_CO2_REP_ERR` to 0.4 → 2 in `test-gradient.R`.
The parameter-ledger test fired on the count as designed and was **recorded, not merely bumped**.

**DESIGN.md §5.2 corrected.** It still described the AR(1) model retired on 2026-08-11 *and* a
free σ_add for CO₂. Both corrections are dated in place, with §5.1's draft table marked
unmaintained and `R/likelihood.R` / `CCX_PARAM_TABLE` named as authoritative. Gate 9's standing
"re-measure on any change to … σ_co2" instruction now names `LIK_CO2_REP_ERR` and records the
re-measurement it asked for.

## 2026-08-15 (later still, part 3) — ITEM 9's PREREQUISITE: h_ml is a capacity-side workaround for an export deficit, and the pump case gets STRONGER

`calibration/diag_h_ml_roles.R` (new, ~3 min, output `calibration/output/h_ml_roles/`). **No
model code changed.** Run before the refit at Marcus's direction: handoff §4.2 listed a cheap
h_ml test as item 9's prerequisite, and if it motivated a pump that would be a *structural*
change, throwing away any mode found first.

### The first design was invalid, and is quarantined rather than deleted

Handoff §4.2 proposed "hold the mixed-layer carbon inventory fixed while varying its depth". The
first implementation did that by driving `aux$ml_mass_kg` (capacity) and `grid$dz[0]` (geometry)
at **different** depths. **That is not a decomposition.** The two are encodings of one
quantity — the core reads the chemistry's concentration as `y_ml/ml_mass_kg` and the diffusion's
as `y_ml/dz[0]` — so making them disagree makes "mixed-layer concentration" mean two different
things inside one timestep.

It announced itself: at h = 184 m the arms gave BOTH **+425.9**, CAPACITY **−26,203.8**, EXPORT
**−29,035.3** — an **interaction of +55,665 against an effect of +426**. Diagnosed rather than
interpreted, and the sign pattern confirms the artefact exactly (CAPACITY arm over-ventilates:
deep Δ¹⁴C −216, sink 4.84; EXPORT arm under-ventilates: deep −133, sink 1.53). Post-mortem in
`calibration/output/quarantine/20260815_h_ml_inconsistent_grid_arms/README.md`. A second, smaller
defect in the same file: the deep-Δ¹⁴C confound control filtered on `d14c_deep` when the stream
is **`d14c_deep_ocean`**, so it was a silent no-op — caught only because the diagnostic printed
both columns and they were identical everywhere. **A `ccx_spinup(grid=)` argument added to
support the invalid design was reverted**; leaving API surface whose only known use is refuted
invites its reuse.

### The replacement uses only consistent grids, and the two pre-registered tests DISAGREED

| step | result |
|---|---|
| **1. signs, off the grid alone** | 75 → 184 m: ML capacity **×2.45**, ML→interior conductance **×0.54**. The two channels have *opposite* signs, which is what makes them separable without surgery. |
| **2–3. where the carbon goes** | +32 GtC extra in the **mixed layer**, **−19 GtC** in the interior. Ocean sink 2.87 → 3.06. → **CAPACITY signature** |
| **4. kz, the pure export knob** | preferred depth across a 6× kz range: 220, 220, **184**, 50, 50, 50 m. At kz ×1.4 the model wants a **50 m** mixed layer. → **EXPORT signature** |

**Both are true at different levels, and the reconciliation is the finding:** what the objective
is short of is ocean **uptake**; h_ml = 184 m is a **capacity-side workaround for an export
deficit**, reached for because `kz` is bracket-limited (96.6 % of the way up). So h_ml is not
evidence against the pump — it is a symptom of the same shortage. The Laplace r(h_ml, kz) =
**−0.211** is consistent: they substitute, weakly, in exactly this way.

### Why kz cannot simply be freed — and why that is the pump's case

Diffusion ventilates ¹⁴C in proportion to the carbon it moves. Buying uptake with kz drives the
deep-Δ¹⁴C term from **z +1.70 → +4.47**, away from a target (−175.3 ± 10.3 ‰) the model already
misses on the under-depleted side; at kz ×1.4 the CO₂ level streams lose 712 log-units between
them (over-absorption, sink 3.37). **A biological pump exports carbon as sinking particles and
remineralises it at depth — adding uptake without mixing surface water down.** No knob currently
in the model can do that. **The pump case comes out of this stronger than handoff §4.2 had it,
not weaker.**

### Item 9's pre-registered test is AMENDED

It was: *does h_ml relax below ~163 m and kz off the top of its bracket, while the ocean sink
holds near 3.1?* Part 4 makes the h_ml clause **measured-plausible** rather than speculative —
but it is not sufficient. **Third clause added: does deep Δ¹⁴C move TOWARD −175.3 rather than
away?** That is the clause the kz route fails, and therefore the one the pump must beat to be an
improvement rather than a re-arrangement. Recorded in the diagnostic's own output, not only here.

**Still standing:** the conveyor is still NO (falsified twice in-repo). The `kz` bracket is still
load-bearing — this run is further evidence, since without it the fit would buy uptake by
wrecking deep Δ¹⁴C.

---

## 2026-08-15 (later still, part 4) — THE DIC-GRADIENT DIAGNOSTIC: all three of item 9's clauses PASS, and the uptake argument for the pump is dead

`calibration/diag_dic_gradient.R` (new, ~15 min, output `calibration/output/dic_gradient/`).
**No model file was touched** — the pump is a shim over `ccx_deriv()` in the diagnostic's own
environment, with **zero fitted parameters**: the export field is *solved* as the source that
makes GLODAPv2's own observed DIC profile an exact steady state of the model's own diffusion
operator. No Martin curve is chosen; no export magnitude is fitted.

Also: **`kz(z)` depth-dependence and the high-latitude outcrop were added to the candidate list**
(Marcus 2026-08-15). They now live in **DESIGN.md §3.4a** together with the pump and the
conveyor, and with the five observables that discriminate them. §10's v2 backlog points there.

### Two of my own predictions were measured and FAILED. Both are recorded, not dropped.

1. **The Revelle/capacity channel does not exist.** I proposed this diagnostic on the argument
   that the missing gradient means preindustrial *surface* DIC is too high, hence the buffer
   factor is too high, hence the mixed layer absorbs too little. **Measured:** the model's ML is
   1986.3 µmol/kg; GLODAPv2's 0–75 m volume-weighted mean is 2028.9 µmol/kg **modern**, i.e.
   ≈1979 preindustrial once ~50 µmol/kg of anthropogenic carbon is allowed for. The model's
   surface is right to ~7 µmol/kg. **The entire 244.7 µmol/kg deficit is interior.**
2. **The pump makes deep Δ¹⁴C MORE depleted, not less.** I argued the opposite — that sinking
   particles carry the mixed layer's young (−51 ‰) ratio down and dilute the deep. Wrong: the
   pumped carbon is delivered young but leaves only by the same slow diffusive return, so deep
   inventory rises ~12 % while the ventilation flux rises much less, mean age goes up, and decay
   beats the injection value. **The residence-time channel dominates the injection-value channel.**
   This flips the sign of clause 3 between operating points and is why part 6 scores at the mode.

### The pre-registered prediction, and it came out EXACT

Stated before part 3 ran: the interior is a passive tracer with no chemistry and diffusion is
linear in concentration, so a static background DIC profile superposes on the anthropogenic
perturbation and cannot change how it propagates. **Therefore a nutrient-limited (constant-mass)
pump must change the ocean sink by exactly zero.**

**Measured: +0.000000 GtC/yr.** Only a DIC-limited export moves it, and only by **+0.130 GtC/yr**
at 22.0 GtC/yr of export. **The "pump supplies the export deficit" argument of handoff 15c §3.3
is therefore wrong as stated** — in this model the pump is not an uptake mechanism at all. What
it moves is the isotopes and the background state, and — via the *background state* changing
which `h_ml` the objective wants — it moves `h_ml`.

### All three of item 9's amended clauses PASS, at the mode, at zero fitted parameters

At the pre-gradient MAP mode's other parameters, each arm at its own best depth:

| | pump OFF | pump ON |
|---|---|---|
| `h_ml` | 184 m | **100 m** |
| logL | −2269.7 | −2283.4 |
| ocean sink | 3.063 | 3.052 GtC/yr |
| deep Δ¹⁴C | −157.8 (z **+1.70**) | −164.2 (z **+1.08**) |

- **CLAUSE 1 PASS** — `h_ml` relaxes 184 → 100 m. The pump *does* supply what `h_ml` was faking.
- **CLAUSE 2 PASS** — the sink holds at 3.05 against 3.06, i.e. the same sink at a physical
  mixed-layer depth instead of an unphysical one.
- **CLAUSE 3 PASS** — deep Δ¹⁴C moves **toward** −175.3, z +1.70 → +1.08.
- **Cost: −13.7 log-units with nothing refitted.** The largest single loss channel is atmospheric
  Δ¹⁴C (−30/−31 NH/SH), and `bomb_total` — the free parameter that absorbs exactly that — is held
  fixed here. −13.7 across a 19-parameter objective is plausibly refit-recoverable; it is **not**
  a measurement that the pump is worse.

**At `ccx_default_params()` clause 3 FAILS instead (z −1.08 → −1.52), and this is not a
contradiction.** At defaults `kz` is low and the model is already *over*-depleted, so more
depletion is a loss; at the mode `kz` sits 96.6 % up its bracket and the model is *under*-depleted,
which is the miss 15c §3.3 is about. Scoring clause 3 at defaults would have returned the opposite
verdict for a reason with nothing to do with the pump. **Both are printed; they are not averaged.**

### Two scoping facts that any pump design must now answer

1. **The implied export is 22.0 GtC/yr — 2.6× the literature global POC export (5–12 GtC/yr).**
   The export needed is set by how fast the model's diffusion *destroys* the gradient, i.e. by
   `kz`, and `kz` = 5000 is **9× Ledwell's NATRE 536 m²/yr**. An effective diffusivity tuned to
   emulate 3-D advective *transport* also spuriously destroys *gradients*, so a pump inside this
   column must work several times harder than the real one does. **This is the same observation
   as the NATRE ratio, seen twice — and it is why depth-dependent `K_z` (§3.4a A) and the pump
   are complements, not alternatives.**
2. **A soft-tissue-only pump cannot fit the DIC and δ¹³C gradients at once, and this is
   arithmetic.** Mixing 244.7 µmol/kg of organic carbon at ε = −20 ‰ predicts a −2.153 ‰
   depletion against an observed −0.938 ‰: an overshoot of **2.3×**, and arm N measured **2.3×**.
   No single ε removes it. The implied two-component split (CaCO₃ at +2 ‰) is **≈45 % soft-tissue
   / 55 % carbonate** — order-of-magnitude only, since it also absorbs preformed-δ¹³C and air-sea
   disequilibrium structure a two-box contrast cannot separate. **A carbonate limb also moves
   alkalinity, which this model holds fixed at `ALK_SURFACE`** — a second structural commitment
   hiding behind the first.

### Controls and gates, because the shim is new code

- **PARITY GATE**: `dg_spinup()` (a near-verbatim copy of `ccx_spinup()` with the full-state
  Newton solve made unconditional) reproduces `ccx_spinup()` to **6.5e-07 GtC** over 96 states
  and **4.1e-08 mol/yr** on `prod_c14` with the pump off. It `stop()`s above 1e-6.
- **FRACTIONATION CONTROL (arm N0)**: with ε = 0 the deep δ¹³C does not move from +1.560 at all —
  unfractionated particles deliver surface-*enriched* carbon. Printed beside arm N so the one
  structural choice in the file is visible rather than assumed.
- The observed profile's slight mid-depth maximum (1314–1861 m is ~3 µmol/kg above the bottom)
  makes two boxes per hemisphere need a **negative** source, which is not remineralisation.
  **Reported with magnitudes (min S ≈ −0.14 GtC/yr), not smoothed away.**
- **Free validations, neither in the objective and both flagged as such:** ocean inventory
  32,827 → 36,467 GtC (canonical ~38,000) and natural ¹⁴C production 0.672 → 0.736 of canonical.

### What this does NOT settle

The C++ core does not know about the pump — every run here goes through the R reference
integrator, which is why it costs ~15 min. Porting is a *shipping* decision and this file exists
to inform it, not to pre-empt it. Nothing was refitted; the −13.7 is a fixed-parameter number.
And §3.4a's candidates A and B1 (`w_out_NH`/`w_out_SH`, already built and defaulting to 0) have
**not** been run against the same five rows — that comparison is the obvious next step and would
cost far less than the pump.

---

## 2026-08-15 (later still, part 5) — CANDIDATES A AND B1 SCORED: K(z) fixes the deep age, the outcrop fixes nothing, and the B2 gate does not fire

`calibration/diag_ocean_candidates.R` (new, ~40 min, output
`calibration/output/ocean_candidates/`). Scores DESIGN.md §3.4a's candidates **A**
(depth-dependent `K_z`) and **B1** (outcrop `w_out_*`) on the **same five rows** as the pump.
B1 needs **no new code** — it runs through the C++ core. A is a shim over `ccx_deriv()` with a
bit-exact no-op mutation gate. **No model file touched.**

### The prediction that was worth more than the scan

Derived before running: **DIC and ¹³C are conserved and have no interior source, so any steady
state of any transport operator has a uniform interior ratio.** ¹⁴C differs only because decay
*is* an interior sink. **Measured: A and B1 move the DIC gradient by 0.00e+00 µmol/kg and the
δ¹³C gradient by 2.2e-13 ‰.** Rows 4 and 5 are structurally reserved to biology. **The pump was
never in competition with A, B1 or B2** — the question is which *combination*, and the
objective cannot see two of the five rows at all.

### B1 — the outcrop FAILS, and it closes a general statement

Nine `w_out` values × three hemisphere allocations. **Every configuration moves deep Δ¹⁴C AWAY
from target, monotonically:** z +1.70 → +2.26 at the best-logL point (SH-only 0.5 m/yr,
Δ logL +0.1, i.e. noise) → +6.69 at 20 m/yr. `h_ml` does not relax.

**`kz`, `w_up` and `w_out` all buy ocean sink by moving surface water down, and all three pay
the same deep-Δ¹⁴C bill.** `w_up` was already measured this way (CHANGELOG 2026-08-13: "at
`w_up` ≥ 2 the deep age is unreachable at *any* `kz`"). The escape is not more ventilation —
it is changing its **depth distribution** (A) or adding an **interior source** (C).

### A — PASSES clause 3 decisively, FAILS clause 1

Form: `K(z) = kz·exp(−(z − h_ml)/z_K)`, anchored `f` = 1 at the ML base so `kz` keeps a
NATRE-comparable meaning; `z_K` → ∞ is the shipped model exactly.

**Compared ISO-SINK**, `kz` solved per `z_K` to carry the incumbent's ocean sink:

| `z_K` | `kz` | deep Δ¹⁴C z | Δ logL |
|---|---|---|---|
| ∞ (incumbent) | 6119 | **+1.70** | — |
| 5000 | 6404 | **−0.17** | **+0.9** |
| 3000 | 6601 | −1.76 | −1.6 |
| 2000 | 6857 | −4.21 | −10.5 |
| 1200 | 7400 | −11.15 | −68.5 |

A very gentle decay (K → 0.61·`kz` at the bottom) lands the deep **on target at an identical
sink, at slightly better logL**, with one parameter and only `kz` re-optimised. But **`h_ml`
stays at 184 m** — A does not supply what the deep mixed layer is faking. Only the pump has.

**`z_K` would be WEAKLY IDENTIFIED.** The iso-sink logL spread from `z_K` ∞ to 3000 is ~2 units
while deep Δ¹⁴C moves ~3.5σ. That is the term behaving correctly (a 1.9σ gain *is* ~1.4
log-units) — but adopting A puts real weight on the deep-Δ¹⁴C **n_eff choice
`build_glodap_deep_targets.R` left UNRESOLVED** (five sigmas spanning 15×). Resolve first.

### Marcus narrowed the pedagogy constraint, and the gate it created did NOT fire

**Marcus 2026-08-15:** added complexity is a real drawback, but *complexity forced by the
observations is its own pedagogical result*. B2 is therefore gated on **evidence**, not
parameter count. **The gate ran: candidate A reaches |z| = 0.17, so B2 is NOT indicated on the
deep-Δ¹⁴C row.** Not excluded — clause 1 is unmet by everything but the pump, and B2 is the only
untested candidate that does A and B together — but the argument that a single column *cannot*
reach the target is now measured false.

### THREE CORRECTIONS TO THIS REPO'S OWN CLAIMS, all mine, all from today

1. **"A lets C be built at a defensible export" (DESIGN §3.4a) — RETRACTED, measured false.**
   The export is set by the flux across the **top** interface, where A's shape is anchored at
   `f` = 1, so `K(z)` does not reduce it at fixed `kz`; and A's iso-sink solution wants
   `kz` = 6404 vs 6119, making the requirement *worse* (14.6 → 15.3 GtC/yr at `h_ml` = 184).
   A and C are complements for a **measured division of labour** instead: A owns clause 3,
   C owns clause 1 and rows 4–5.
2. **The "2.6× literature export" headline needed its conditioning stated.** It is a strong
   function of BOTH `kz` and `h_ml`, running **4.8–35 GtC/yr** across the plausible box, and
   inside the literature range only for `kz` ≲ 2500–3000. It is ~2.6× (22.5 GtC/yr) at the
   pump's own preferred point (`kz` 6119, `h_ml` 100), so the headline survives — but the 22.0
   first quoted was at `(5000, 75)` and agreed only by offsetting differences.
3. **A first-pass finding that "the objective prefers deep Δ¹⁴C at −9.75σ" — RETRACTED.** It
   came from a coarse `(kz, z_K)` grid in which the **incumbent sat at its own fitted
   `kz` = 6119.2 and no challenger did**. The size of that artifact is in the file's own control
   column: the *same constant-K model* at `kz` = 5000 scores **309 log-units worse**. An
   unmatched comparison measures the grid, not the candidate. Hence the iso-sink design.

### The decision block was wrong TWICE and both failures are recorded in it

- **v1** read the `z_K` = ∞ **control** as if it were candidate A, so it "passed" on the
  incumbent, and never checked clause 2.
- **v2** indexed the iso-sink winner out of the **wrong list** with an iso-sink key. R returns
  `NULL` for a missing name, `abs(NULL$z14)` is `numeric(0)`, and **`min()` silently dropped
  it** — so the rule scored B1 alone and fired the OPPOSITE way. A zero-length vector vanishing
  inside `min()` does not error; it quietly removes a candidate from the comparison. Explicit
  length assertions added.

### Gates

- **SHIM GATE**: `f` ≡ 1 is bit-exact (max|Δ| = 0.000e+00); `f` = exp(−z/1500) moves the
  derivative by 4.4e-01. Both directions asserted.
- **ENGINE GATE**: cpp and R agree to **7.5e-11** in logL and **0.00e+00** in sink, so the
  C++-scored B1 table and the R-scored A table are commensurable.
- Suite unchanged: FAIL 4 | PASS 708.

---

## 2026-08-16 — `LIK_D14C_DEEP_NEFF` MEASURED: the asserted 20 survives, the range narrows 15× → ~4×, and it lands ACROSS the decision threshold

`calibration/diag_deep_d14c_neff.R` (new, ~1 min, output
`calibration/output/deep_d14c_neff/`). Marcus 2026-08-16: measure `n_eff`, don't pick from the
five asserted candidates. **This file changes nothing** — `LIK_D14C_DEEP_NEFF` is still 20.

**The estimand, written down because the estimators answer different questions.**
`Var(x̄_w) = σ²·[ΣΣ w_i w_j ρ(d_ij)]/(Σw)²`, so `n_eff = (Σw)²/[ΣΣ w_i w_j ρ(d_ij)]`, which
collapses to Kish when ρ = δ. Measured on the **build script's own cells** (5°×10°×250 m,
cos-lat weights), gated to reproduce the shipped target exactly (Δ = 0.00e+00 on both the mean
and `sd_w`) so σ = `sd_w`/√`n_eff` is the shipped formula with a measured denominator.

### The gate caught a target-definition surprise

The shipped deep target is **everything below 2627.2 m**, not the model's 2627–3700 m box —
`build_glodap_deep_targets.R` calls `gd_binned(..., zmax = 1e5)`, so bottles *deeper than the
model's floor* are in it. Restricting to the model's actual box gives **−177.81 ‰ over 1,805
cells against the shipped −175.26 ‰, i.e. 0.25σ**. Flagged, not changed — it is a target
definition and it is Marcus'. The gate is what surfaced it; assuming the layer would have
measured `n_eff` for a different quantity.

### Results

Correlogram (no detrending — the basin gradient is *why* more Atlantic bottles don't pin the
global mean): **ρ < 0.5 by ~5,500 km, ρ < 0 by ~9,000 km**, reaching −0.37 at 15,000+ km.

| estimator | n_eff | σ (‰) |
|---|---|---|
| Kish, weights only (ρ = δ) | 3408 | 0.79 |
| correlogram ESS, empirical ρ | 110.1 | 4.37 |
| **correlogram ESS, ρ floored at 0** | **6.4** | **18.15** |
| block bootstrap, 10° | 148.5 | 3.76 |
| block bootstrap, 20° | 45.5 | 6.80 |
| block bootstrap, 30° | 26.0 | 9.00 |
| block bootstrap, 60° | 11.9 | 13.28 |
| *asserted incumbent* | *20* | *10.26* |

**The block bootstrap must be read against the decorrelation scale.** A block bootstrap is
valid only when the block exceeds it; 10° ≈ 1,100 km breaks correlation *inside* its own blocks
and is biased high, 60° ≈ 6,700 km does not. The monotone decline with block size is the
expected signature. **The 30–60° rows (12–26) are the methodologically valid ones and also the
noisiest** (33 and 16 blocks).

**The correlogram estimate is a BRACKET, not a point.** Flooring ρ at 0 moves n_eff **110 → 6.4,
a factor of 17** — the negative tail does all the work. Which end is right is a question about
the ocean, not the arithmetic: if the young-Atlantic/old-Pacific contrast is *deterministic
structure we have sampled*, the global mean is well determined and ~110 is right; if the basins
are better treated as a handful of exchangeable water masses, ~6 is. **The correlated-mean
formula is a random-field formula, and this field has large deterministic structure — which is
exactly where it stops being well posed.** Stated, not resolved.

### What it does to candidate A

A's net is +0.86 log-units at the sigma in use, of which the deep term supplies **+1.43** and
everything else **−0.57** (σ-independent). Closed form: **A is adopted for any σ < 16.30 ‰,
i.e. n_eff > 7.9.**

**The measurement brackets that threshold rather than clearing it** — defensible range ~6.4 to
~26 against a crossover at 7.9. What it *does* settle:

- **Ruled out: the full spread, σ = 45.88 (n_eff = 1)** — the only one of the five original
  candidates that rejected A. And **Kish's 3408**, which assumes an independence the correlogram
  refutes outright.
- **The asserted 20 survives**: inside the measured range, on the adopting side, and
  conservative relative to the correlogram's unfloored 110.
- Range narrows from **15× asserted to ~4× measured**.
- **Every candidate σ still HOLDS `kz`** against the −112.7 ‰ runaway (z 4.7–79.6), so the job
  the sigma was originally chosen for remains insensitive to all of this.

Leave-one-basin-out: the mean is hostage to the Pacific (44 % of weight, −211.5 ‰; dropping it
moves the global mean to −146.4). Full leave-one-out span **46.2 ‰**. That is the physical
reason n_eff is tens rather than thousands.

### Two estimators failed and are recorded rather than dropped

- **The detrended-residual variant returned n_eff = −4630.** A negative effective sample size
  is not a small n_eff, it is a broken estimator: the interpolated binned empirical ρ is not
  guaranteed positive semi-definite on a nonstationary field, and the double sum went negative.
  Now guarded and reported as UNUSABLE.
- A first version of the correlogram block printed "margin is 0.9 %, so the estimate is not a
  near-cancellation" — **wrong reasoning**: `S/(Σw)²` *is* `1/n_eff` by construction, so a small
  ratio is what a large n_eff means, not evidence about robustness. The real robustness check is
  the floored-vs-unfloored comparison, which is what replaced it.

### Still not measured, and both push σ UP

Model **representation error** (a one-box deep ocean against a field spanning −234 to −87 ‰;
`R/likelihood.R` records it as deliberately zero) and **unsampled volume** (part 5 has no
bathymetry denominator). **A measured n_eff sets a CEILING on the term's weight, not the weight
itself.** Both open questions are Marcus'.

---

## 2026-08-16 (later) — The n_eff measurement turned into a sigma: 20 is MEASUREMENT-CONSISTENT, and marginalising costs margin rather than correctness

`calibration/diag_deep_d14c_sigma_choice.R` (new, <5 s). Marcus 2026-08-16: "an n_eff median
and sigma to be used in the MCMC". That can mean two different things and they were both
built, because they are not the same answer:

- **Option 1 — a POINT sigma.** Summarise the admissible estimators, keep the Gaussian term.
- **Option 2 — MARGINALISE the sigma uncertainty.** For a scaled-inv-χ² prior on σ² the
  single-observation marginal is a **Student-t** in closed form — one line in the likelihood.

**`LIK_D14C_DEEP_NEFF` is unchanged at 20.** Its comment block in `R/likelihood.R` is rewritten
from *asserted* to *measured-consistent*, carrying the admissible set and both open questions.
That is the only edit to model code, and it changes no behaviour. Suite: FAIL 4 | PASS 708.

### The admissible set is the judgement call, so it is written down

A median over all seven estimators would be arithmetic dressed as a decision — two are
known-invalid and would drag it. Excluded with reasons: **Kish 3408** (assumes an independence
the correlogram refutes) and the **10°/20° block bootstraps** (block ≪ the ~5,500 km
decorrelation scale, biased high). Admissible: **6.4, 11.9, 26.0, 110.1**.

| summary | n_eff | σ (‰) |
|---|---|---|
| median | 18.9 | 10.54 |
| geometric mean | 21.6 | 9.87 |
| **incumbent (in use)** | **20** | **10.26** |
| conservative end | 6.4 | 18.15 |

**Every reasonable summary lands within 8 % of the asserted 20.** The value does not move:
changing 20 → 19 buys a 2.7 % σ change and costs comparability with every logL in the repo.
**The defect was provenance, and provenance is fixed by the receipt, not by moving the number.**

n_eff is known to a factor of **3.4** (1 sd on log n_eff); σ to a factor of **1.85**.

### Option 2 measured — and I expected it to fail and it does not

ν calibrated from the measured spread via Var(log σ) = trigamma(ν/2)/4 → **ν = 2.12**, scale
9.87 ‰. Near-Cauchy, which is what a 17× bracket on σ actually implies.

| deviation | Gaussian | Student-t |
|---|---|---|
| **kz runaway, 62.6 ‰** | **20.08** | **4.67** |
| 30 ‰ | 4.62 | 2.62 |
| 50 ‰ | 12.83 | 4.02 |

Against the build script's own "HOLDS `kz`" threshold (z > 3 = 4.50 log-units), **the Student-t
still HOLDS, at 4.67.** I had expected it to break the term's founding purpose; it does not.
What it does is cut the runaway penalty **4.3×**, leaving a **4 % margin where there was a 4×
one**. So the objection to option 2 is not that it fails — it is that **under option 2 this term
could never replace the `kz` bracket**, which would then stay load-bearing indefinitely.
*(Caveat: scoring a t against a Gaussian-derived threshold is like-for-like only in the
operational sense of log-units paid, not as a tail probability.)*

Option 2 also changes nothing about candidate A (net **+0.82**, still adopted). It shrinks A's
gain and the runaway penalty together — **a term that says less about everything**, not a thumb
on the scale.

| option | σ | A net logL | adopted? |
|---|---|---|---|
| option 1, median | 10.54 | +0.79 | yes |
| option 1, geometric mean | 9.87 | +0.98 | yes |
| option 1, incumbent | 10.26 | +0.86 | yes |
| **option 1, conservative end** | **18.15** | **−0.11** | **no** |
| option 2, Student-t | 9.87 | +0.82 | yes |

### Recommendation and what stays open

**Option 1 at the incumbent 20, re-documented as measured** — which is what was applied. Option
2 is the better-posed error model and is a real alternative; the trade is *honest error model*
vs *ability to retire the `kz` bracket*, and it is not mine to make.

Still Marcus': **(1) representation error, still zero** — it adds in quadrature and at the
conservative end (σ 18.15) candidate A stops being adopted, so this constant is now load-bearing
on a structural decision in a way it was not when it was chosen; **(2)** whether candidate A's
`kz` = 6404 outside the [3830, 6200] bracket is a blocker or a re-derivation — and note the
coupling, since option 2 makes that question *harder* by removing the term's ability to stand in
for the bracket.

---

## 2026-08-16 (later still) — MARCUS: the DIC and δ¹³C gradient terms go into the next round

Decision taken. Design, traps and ordering consequence in
`notes/handoff_2026-08-16_candidates_neff_and_gradient_terms.md` §4. Nothing implemented yet —
two sub-decisions block it (below).

**Why it is the right call.** Two of the five discriminating rows were not in the objective, and
they are the two only a pump can move. The refit could therefore never arbitrate the pump *no
matter how long it ran*, and `diag_dic_gradient.R`'s pump had zero fitted parameters precisely
because there was nothing to fit them against. **These terms are what make a fittable pump
possible.** Sanctioned direction: the architecture review's rule is add missing constraints,
not reweight existing ones.

**Their leverage on the current 19 parameters is EXACTLY ZERO — measured, not assumed.**
Perturbing each of `beta_max, fert_k, q10, k_w, h_ml, kz, tau_ex, npp_frac_NH, seas_amp_*,
gamma_enso, sst_scale` by 10 % moves the deep-box DIC and δ¹³C by ≤ **5.3e-12**. Baseline deep
DIC **1996.2555 µmol/kg**, deep δ¹³C **1.55953 ‰**, both parameter-independent (ML value set by
carbonate equilibrium at fixed `ALK_SURFACE` and SST; interior uniform by conservation).
Consequences: **no posterior distortion and no parameter hijacking**; logL shifts by a constant
**~384 log-units** (deep DIC z −23.0, penalty 264; deep δ¹³C z +15.5, penalty 120) and becomes
incomparable with every prior run; and **the zero-leverage property must be GATED**, because the
pump breaks it on purpose.

**The ordering conclusion that follows:** the terms are unfittable until a pump exists, so
**add the terms AND build the pump in the same round, then refit once against the complete
objective.** Terms-first is harmless but useless; pump-first fits the pump against an objective
blind to its two signature rows — the exact failure the terms are being added to prevent.

**GRADIENTS, not levels, and δ¹³C is the reason.** The model's surface DIC is *right*
(1986.3 vs a GLODAP 0–75 m mean of 2028.9 modern ≈ 1979 preindustrial), so level and gradient
are ~7 µmol/kg apart there. But the model's uniform ocean δ¹³C is **+1.560 ‰** against a
preindustrial surface nearer **+2.0 ‰** — a ~0.4 ‰ *level* offset owed to air–sea fractionation
constants and the preindustrial atmospheric value, nothing to do with the pump. A level term
would conflate that with the pump signal; a gradient term is immune.

**THE TRAP, unresolved:** the observed surface is anthropogenically contaminated in both fields
(~+50 µmol/kg Cant; Suess-depleted δ¹³C), so the raw modern gradients — **+244.7 µmol/kg** and
**−0.938 ‰** — are LOWER BOUNDS and bias *against* the pump. Three options: raw-and-documented;
corrected (**`data-raw/downloads/eide2017_c13_suess_effect.nc` is already in the repo** and is
exactly the δ¹³C correction; DIC needs a Cant estimate we do not carry); or score the transient
2010s gradient against the modern observation. **Target definition, Marcus'.**

**Two sub-decisions block implementation:** the target definition above, and per-field `n_eff`
(measured for Δ¹⁴C, not for DIC/δ¹³C; `sd_w` is 53.9 µmol/kg and 0.327 ‰;
`diag_deep_d14c_neff.R` generalises with a field argument, ~1 min).

**Also noted:** the existing deep-Δ¹⁴C target is *everything below 2627.2 m*, not the model's
2627–3700 m box (`zmax = 1e5` in the build script). Restricting to the model's actual box moves
it −175.26 → −177.81 ‰, i.e. 0.25σ. The new terms should not inherit that inconsistency without
a decision.

Handoff written; ordering table amended (item 12 = the terms, item 11 = outcrop, DEAD).

## 2026-08-16 (evening) — §6's two blockers MEASURED: the gradient target is not one number, and the contrast's σ is not the levels' σ

`calibration/diag_gradient_target_and_neff.R` (~25 s). Answers handoff §6 decisions 1 and 2.
**Nothing shipped; both decisions remain Marcus'.** Full tables in DESIGN.md §5.2a.

**Two gates first, both PASS.** (A) the cells reproduce all six shipped targets
(3 fields × 2 layers) to 0.00e+00; (B) Δ¹⁴C run through the *generalised* code path
reproduces `diag_deep_d14c_neff.R` exactly (Kish 3408.2032, correlogram 110.0893,
ρ-floored 6.3904, all |d| = 0). So the generalisation is a regression test on itself, and
the Δ¹⁴C rows below are a control, not a new result.

**DECISION 1 — the repo already carries TWO gradient targets and they differ by ~1σ.**
Handoff §4.4's +244.7 µmol/kg / −0.938 ‰ come from the model's own boxes **at `h_ml` = 75**
(the *default*); the shipped `obs_glodap_deep.rds` gives **+233.11 / −0.8610** on fixed
depths (0–100 m / >2627.2 m). Tracked down and reproduced exactly, so this is a layer
choice, not a discrepancy.

**And a hazard that was not visible before: a model-anchored target is a FUNCTION OF `h_ml`.**
`ccx_ocean_grid()` puts the ML box at 0–`h_ml`, so the observed gradient reads
+244.7 (h_ml 75) → +235.0 (100) → **+212.8 (184, the FITTED value)**. It moves
**+22.2 µmol/kg** as `h_ml` falls 184 → 100 — *exactly* the move the pump makes (15d).
See the correction appended below: my first statement of this hazard's DIRECTION was wrong.

**DECISION 2 — the estimand is a CONTRAST, and I predicted its covariance sign WRONG.**
Var(Δ) = Var(D) + Var(S) − 2 Cov(D,S). I argued in the file header, *before measuring*, that
the two layers share cruises so a sampling excursion biases both the same way and **cancels**,
i.e. that ignoring the covariance would make the terms weaker than the data warrant.
**Measured, by two estimators sharing no machinery — block bootstrap on the contrast, and
a paired-column correlation on the raw field — and they AGREE on the sign for all three
fields:**

| field | corr(surf, deep) | effect on σ_Δ | σ_Δ (blocks ≥30°) | deep-LEVEL n_eff |
|---|---|---|---|---|
| DIC | **−0.38 to −0.60** | **INFLATES ~25 %** | **19.8 – 25.3 µmol/kg** | 10.2 – 23.3 |
| δ¹³C | +0.09 to +0.12 | cancels ~4–8 % | 0.075 – 0.115 ‰ | 10.2 – 23.5 |
| Δ¹⁴C (control) | ≈ 0 | none | 11.9 – 15.0 ‰ | 11.7 – 25.8 |

For DIC — the field that matters most — the naive independent-layer calculation would have
made the term **~25 % STRONGER** than the data warrant, the opposite of what I claimed.
**Mechanism (and it is the same physics as the deep-Δ¹⁴C correlogram's negative tail, read on
a different pair of layers):** surface DIC is highest where the water is cold and dense — the
high latitudes — and that is precisely where the deep water is *youngest* and lowest in
respired carbon. Basins trade the two ends of the gradient against each other, so a
basin-skewed sample misses the **gradient** by more than it misses either **level**.

**§4.6's worry does NOT bite for the LEVEL terms.** It asked whether `n_eff` = 20, measured
for Δ¹⁴C, transfers to DIC and δ¹³C. It does: deep-level `n_eff` is 10.2–23.3 (DIC),
10.2–23.5 (δ¹³C), 11.7–25.8 (Δ¹⁴C) — **20 sits inside the bracket for all three.** The fields
do have their own spatial structure and it does not move `n_eff` enough to matter. The worry
bites only for the **contrast**.

**§4.2's ~384-log-unit constant does not reproduce, twice over.** (a) It is a *level*
formulation; **gradient** terms on the shipped layers cost **71–136 log-units**, because the
contrast's σ is larger than a level's. (b) Its model baseline (deep DIC 1996.2555 µmol/kg)
does not reproduce — the default spinup gives a column uniform at **1986.3340** (NH) /
**2003.7207** (SH). Recomputed live here rather than copied. The zero-leverage result itself
is confirmed and sharpened: the interior is uniform to **machine precision** in both
hemispheres, so **the gradient IS the miss, in full.**

**Caveat carried, not buried:** the bootstrap SE has **not plateaued** in block size
(30° → 60° still rising), so σ_Δ is a range, not a point. The 60° row is the most defensible
and the noisiest (16 blocks); that tension is unresolved.

**Written:** `calibration/output/gradient_target_neff/diag_gradient_target_and_neff.{rds,log}`,
DESIGN.md §5.2a. No model file and no likelihood constant changed.

## 2026-08-16 (evening, correction) — the h_ml-anchoring hazard runs the OTHER WAY, and freezing is not free either

Marcus asked whether freezing the target at the `h_ml` = 75 grid has drawbacks. Pricing it
did — and it caught a **directional claim of mine that was wrong**, made earlier the same
evening in this CHANGELOG, DESIGN.md §5.2a and `diag_gradient_target_and_neff.R`.

**RETRACTED:** "a model-anchored target would reward shrinking `h_ml` through the target's
motion". **MEASURED (part 2b, new):** the opposite. Pre-pump the model's gradient is **0 at
every `h_ml`** — the interior is uniform by conservation and the ML value is carbonate
equilibrium at fixed `ALK_SURFACE` and SST, which does not involve `h_ml` — so the penalty is
target²/2σ², and the target *falls* with `h_ml`. Penalty therefore falls **81 → 53 log-units**
across `h_ml` 50 → 220: **model-anchoring rewards a LARGE `h_ml` and pushes AGAINST clause 1**,
the thing the pump exists to fix. A worse hazard than the one I claimed, in the opposite
direction. I reasoned about the target's motion and never checked the sign of its effect on
the penalty.

**And freezing is not free either — its bias points the other way.** Freezing at `h_ml` = 75
overstates the miss by **1.61 σ_Δ** at the fitted `h_ml` = 184, because the model's ML box then
spans 0–184 m while the target is built on 0–75 m water. That bias is **in favour of adopting a
pump, and a stronger one** — i.e. it points at the conclusion the term exists to test.

| `h_ml` | like-for-like | frozen @75 | freezing costs (σ_Δ) | anchoring gives (log-u) |
|---|---|---|---|---|
| 75 | 244.71 | 244.71 | 0.00 | 76.2 |
| 100 *(pump)* | 234.98 | 244.71 | 0.49 | 70.3 |
| 184 *(fitted)* | 212.79 | 244.71 | **1.61** | **57.6** |
| 220 | 203.66 | 244.71 | 2.07 | 52.8 |

**Neutral on both counts:** freeze the layers at the `h_ml` the refit actually lands on —
frozen kills the feedback, matched kills the representation bias — for one iteration and a
gate on |`h_ml`_posterior − `h_ml`_target|. **Coincidence worth using:** at `h_ml` = 100, the
value the pump delivers (15d), the like-for-like target is +234.98 against the shipped rds's
**+233.11 — a mismatch of 0.09 σ_Δ**. If the pump lands `h_ml` near 100 the shipped
fixed-depth layers *are* the like-for-like choice and freeze-vs-anchor dissolves.

**MARCUS DECIDED (contamination axis):** option 3 — **score the model's transient gradient at
the observations' epoch** against the modern observation, rather than correcting the surface
for anthropogenic carbon and Suess. No C_ant product needed, which matters because the
GLODAPv2.2023 bottle master carries **no C_ant column** (checked) — option 2 would have meant a
new download or a ΔC* build for DIC, while only δ¹³C had its correction in-repo
(`eide2017_c13_suess_effect.nc`). GLODAP's cell-weighted mean sampling year is **1999.8**
(surface) / **2002.4** (deep). Implementation cost, stated honestly: `ccx_run_fast()` returns
only the **final** state, so this needs one recorded interior state at the obs epoch — a small
output-contract addition, not free, but far cheaper than a C_ant build. **Layer axis still open.**

## 2026-08-16 (night) — THE GRADIENT TERMS ARE IN THE OBJECTIVE (task 12). Both §6 decisions taken; suite back to its pre-existing 4 failures

Marcus took the layer axis on the amended recommendation: **fixed depths + an `h_ml` gate**,
rather than freezing at the `h_ml` = 75 grid, because at `h_ml` = 100 (the value the pump
delivers) fixed depths are already like-for-like to **0.09 σ_Δ** — so the gate defers the
choice to the refit instead of pre-judging it. Contamination axis: **transient at the
observations' epoch**. Details in DESIGN.md §5.2b.

**Shipped.** Streams `ocean_grad_dic` / `ocean_grad_d13c`. Targets +233.109 µmol/kg and
−0.8610 ‰ on fixed depths (0–100 m / >2627.2 m); σ_Δ 25.25 and 0.1115 from the block
bootstrap **on the contrast**; epochs 1999.8 / 2002.4 (surf / deep), measured per field *and*
per layer because the observed gradient is itself a difference of two differently-timed means.
`LIK_OCEAN_GRAD_HML_OK` = [85, 120] m; outside it both terms go **absent**, not zero.

**MARCUS' EPOCH DECISION IS MEASURABLY EQUIVALENT TO THE CORRECTION HE DECLINED**, which was
worth testing rather than assuming (part 5b). Because the model takes up anthropogenic carbon
too, the contamination cancels on *both* sides:

| route | miss (µmol/kg) | σ_Δ |
|---|---|---|
| **option 3 — transient at obs epoch (SHIPPED)** | **278.29** | **11.02** |
| option 2 — preindustrial + ~50 µmol/kg C_ant | 283.11 | 11.21 |
| option 1 — raw modern vs preindustrial model | 233.11 | 9.23 |

**0.19 σ_Δ apart.** The cheap route is not a compromise. Option 1 would have understated the
miss by **1.98 σ**, all of it in the direction that hides the pump — §4.4's trap, quantified.

**A CONSEQUENCE §4.2 DID NOT ANTICIPATE: THE TERMS ARE NO LONGER A PURE CONSTANT.** §4.2's
"leverage exactly zero ⇒ no posterior distortion and no parameter hijacking" is a property of
the **preindustrial** gradient — still 0 to machine precision for every parameter, and now
gated. But the **transient** gradient depends on anthropogenic uptake and therefore on the
ocean parameters. **Measured: ≤ 0.09 σ_Δ per 10 % perturbation** across `kz`, `h_ml`, `k_w`,
`beta_max`, `q10`, `tau_ex`, against an 11 σ miss — ~120× too weak to hijack anything, but not
zero. So §4.2's requested zero-leverage gate was re-aimed: the **exact-zero** assertion sits on
the preindustrial gradient (the property the pump breaks), and the transient gets a **bound**
(`LEV_MAX` = 0.25 σ). Asserting exact zero on the shipped quantity would have failed.

**Model cores changed, both of them.** `CCX_OCEAN_BOX_COLS` — mixed-layer and bottom-box C and
¹³C per hemisphere, raw GtC, emitted as a **time series** (the terms score the obs epoch, not
the run's end). Order is load-bearing: `ccx_run_fast()` names the C++ matrix positionally.
Parity gated to ~1e-13 with an added anti-degeneracy check, so a transposed pair cannot pass.

**logL moves by ~199 log-units** (DIC 64.9, δ¹³C 134.5 at `h_ml` = 100) and is now incomparable
with every prior run. Expected. **δ¹³C is the STRONGER term** (z +16.5 vs −11.0) and will
dominate the pump's fit — worth knowing before the refit, since the pump was designed against
the DIC row.

**A TEST FAILED AND IT WAS NOT A REGRESSION — reported rather than quietly fixed.**
`test-ocean-advection.R:152` asserted `expect_equal(as.matrix(out$out), ...)` over the WHOLE
frame, under a comment saying "the atmosphere, the land and the ocean TOTALS are tied ... the
INTERIOR is not". Those were the same set only because `out` carried no interior quantity; the
new columns broke the coincidence and the assertion began contradicting its own next line
(which asserts the deep DOES move). Measured at the split: **every pre-existing column ties to
≤ 1.5e-10, the MIXED-LAYER columns tie to ≤ 2.9e-13, and only the BOTTOM-BOX ones differ**
(deep_C_NH by 3.68 GtC). Physics untouched; the assertion's scope was wrong. Re-scoped, and
**strengthened** — the mixed-layer tie is now asserted explicitly, which is the test's own
mechanism claim ("air-sea acts at `iml` and nowhere else") measured directly rather than
inferred from totals that could tie by cancellation, and the bottom-box columns are now
asserted to DIFFER.

**Suite: 4 failing, 746 passing** (was 4 failing, 737 passing). The four are the pre-existing
ones, unchanged and unflagged.

**Gate C added** to `diag_gradient_target_and_neff.R`: the diagnostic now checks itself against
the shipped build product — targets exact, σ within a 3 % Monte Carlo tolerance (gating a
bootstrap SE on equality would test RNG call order, not the estimator).

**NOT DONE, and it is the other half of the round:** the pump. Handoff §4.5's ordering
conclusion is terms + pump in the SAME round, then one refit. The terms are the harmless half;
**the refit still waits for the pump.**

---

## 2026-08-16 (later, night) — §6 item 2 ANSWERED: the DIC pump does NOT close δ¹³C, but it misses by a hair — and the *preindustrial* arithmetic that says otherwise is a trap

`calibration/diag_pump_vs_gradient_terms.R` (new, ~3.5 min), `calibration/pump_shim.R` (new,
extraction), output in `calibration/output/pump_vs_gradient/`. Handoff `2026-08-16b` §6 item 2:
the pump was designed against the DIC row, δ¹³C is now the **stronger** term, and nobody had
checked whether the pump that closes one closes the other. **Scored through the SHIPPED
streams** — `ccx_ocean_grad_scored()` + `ccx_loglik(ocean_grad = )`, i.e. the transient
gradient at the observations' epoch on fixed depths at the block-bootstrap σ. These numbers are
**not** comparable with `diag_dic_gradient.R` part 3's, which scored the spinup's bottom box
against a preindustrial target under the old `n_eff` = 20 convention.

At the pre-gradient MAP mode's parameters with `h_ml` forced to 100 m (inside the gate; asserted
before anything runs), nothing refitted:

| arm | export GtC/yr | z_DIC | z_δ¹³C | z_deep¹⁴C | Δ logL |
|---|---|---|---|---|---|
| pump OFF | 0 | **−11.10** | **+16.84** | +1.48 | 0 |
| soft-tissue, ε = −20, sized to the observed gradient | 25.2 | **−1.87** | **−2.42** | +1.08 | **+245.9** |
| ε = −8.40 (the preindustrial arithmetic's answer) | 25.2 | −1.87 | **+8.47** | +1.08 | +213.0 |
| ε = 0 (control) | 25.2 | −1.87 | +16.36 | +1.08 | +115.2 |
| **ε\* = −14.55, g\* = 1.2021 (solved to close both)** | 30.3 | **+0.00** | **+0.19** | +1.00 | **+252.3** |

**VERDICT: NO — and the failure is a FRACTIONATION failure, not a size failure.** The DIC row
demands the export field × **1.202**; the δ¹³C row demands × **0.874**. They are **1.37× apart**,
so no single export scale closes both, and 1.37 = 20 / 14.55 is exactly the fractionation gap.

**But the gap is far smaller than the observed pair implies, and that is the finding.** The
effective fractionation the *observed* pair (+233.109 µmol/kg, −0.8610 ‰, deep DIC 2273.1)
implies is **−8.40 ‰** — a 2.38× overshoot against soft-tissue's −20, i.e. 56 % carbonate limb.
Under the shipped **transient** scoring the demand is **−14.55 ‰**, a **74 % soft-tissue share**.
The reason is that the pump-OFF model does not start at zero gradient at the obs epoch: the
mixed layer carries anthropogenic carbon and the Suess depletion the bottom box has not seen, so
the pump must supply **+280.2 µmol/kg and −1.8777 ‰** rather than the observed +233.1 / −0.861 —
and that ratio is not the observed ratio. **An arm built on the preindustrial arithmetic
(ε = −8.40) is 105.9 log-units WORSE on `ocean_grad_d13c` than plain soft-tissue.** Designing
the pump's fractionation from the observed pair alone would have got it badly wrong; this is the
same trap as §4.4's, one field over.

**Pre-registration scored.** Prediction 1 (naive, preindustrial: δ¹³C overshoots to z ≈ −10.7)
**WRONG**, as the header expected — and its wrongness is the trap above. Prediction 2 (transient:
both rows near −2 σ, g\* ≈ 1.19, ε\* ≈ −15) **RIGHT** — measured −1.87 / −2.42, 1.202, −14.55.
Pump-OFF rows reproduce handoff §2's quoted −11.0 / +16.5 to −11.10 / +16.84.

**A verdict-logic error I wrote, caught by the run itself, kept visible in the file.** I first
classified the failure by comparing the **signs of the two z**. Both came out negative, which the
sign test read as "same-sign miss, one export scale fixes both" — the **opposite** of the truth.
Equal signs of z are opposite corrections here: the DIC target is positive (z < 0 = pump too
**small**) while the δ¹³C target is negative (z < 0 = **too much** depletion). Replaced with the
test that actually answers the question — what scale does each row demand of the same field —
and the trap is documented in the file rather than edited away.

**An unasked-for result, flagged and NOT banked: nutrient-limited vs DIC-limited is not a free
choice.** Same ε, same export field, mode **D** gains **+441.3** against mode **N**'s +245.9, and
the whole **+195.4** difference is the CO₂ record (`co2_level_SPO` +107.3, `co2_level_MLO` +93.6,
`co2_icecore` −9.1); sink 2.913 → 3.051 GtC/yr. **The two gradient rows cannot tell N from D —
they move identically.** A refit has `beta_max` and `kz` free and could reallocate all of it, so
this is not evidence for D; it does mean the N/D choice must be made deliberately in the port
(task 9) rather than inherited from the shim.

**Clause 3 reproduces, including its sign flip.** At the mode the pump moves deep Δ¹⁴C **toward**
the target (z +1.48 → +1.08, and +1.00 at ε\*/g\*); at defaults it moves **away** (−1.01 → −1.42).
Same operating-point dependence `diag_dic_gradient.R` part 6 documented.

**The export required is a statement about `kz`, and a large one.** 20.6 GtC/yr at defaults
(`kz` 5000) vs 25.2 at the mode (`kz` 6119), and **30.3** for the arm that closes both — **3.6×**
the 5–12 GtC/yr literature POC midpoint. A 1-D effective `kz` standing in for 3-D ventilation
also destroys gradients, so the pump must work that much harder than the real one. **Do not quote
the required export as an estimate of real POC export.**

**Refactor, with a bit-identical regression check.** The shim, `dg_export_field()`, `dg_spinup()`,
`dg_parity_gate()` and the GLODAP profile helpers moved from `diag_dic_gradient.R` into
`calibration/pump_shim.R` so the two diagnostics cannot drift apart; the only added code is a
double-source guard (sourcing twice would otherwise capture the already-wrapped `ccx_deriv()` and
recurse). `diag_dic_gradient.R` re-run end-to-end afterwards: `all.equal()` against the saved
pre-refactor `.rds` is **TRUE** across all five arms and the `h_ml` profile.

**Still NOT done: the pump itself (task 9).** This measures a shim through the R reference core;
the C++ core still knows nothing about it, and the refit (task 8) still waits.

---

## 2026-08-16 (later still) — "Should we stop holding alkalinity fixed?" — NO, and the reason is that GLODAP's alkalinity gradient does the job without freeing anything

`calibration/diag_alk_gradient.R` (new, ~2 min first run, seconds after the subset caches),
output in `calibration/output/alk_gradient/`. Marcus' reply to the pump-form question.

**Two questions, different answers, plus the thing that turned out to matter.**

**Q1 — is a carbonate limb blocked by fixed alkalinity? NO, and my own DESIGN §5.2c line saying
otherwise is CORRECTED there.** Checked by grep rather than recalled: `ALK_SURFACE` enters the
**mixed-layer carbonate solve and nowhere else**; the interior has no alkalinity and no carbonate
chemistry. A carbonate limb is a second export field with its own δ¹³C signature, received by
the interior as passive tracer exactly like the soft-tissue limb. Nothing needs freeing.

**Q2 — would an alkalinity tracer change uptake? Barely, and because the model is already
right.** `ALK_SURFACE` = 2300 µmol/kg against GLODAP's **2303.4** on the shipped 0–100 m layer.
A tracer cannot improve the present-day level; it can only let the modelled surface value
*drift*, and alkalinity is near-conserved on this timescale. Priced: **d(Revelle)/d(ALK) =
−0.0005 per µmol/kg**, so 10 µmol/kg of drift moves the buffer factor **0.05 %**. Not competitive
with `h_ml`, which handoff 15c argues is faking uptake at the ~150 m level.

**THE PRIZE, which nobody had looked at: `G2talk` is in the 894 MB GLODAP master this repo
already downloaded.** Extracted on the shipped fixed depths with the same cos(lat) cell
weighting: **2303.4 µmol/kg (0–100 m, 829 cells) and 2382.3 (>2627.2 m, 5886 cells), gradient
+79.0**. With ΔALK = 2·C_carb − (N:C)·C_org at N:C = 16/117, that is a **20–22 % carbonate
share** — against 26 % from the transient δ¹³C demand and **56 %** from the preindustrial
arithmetic.

**It adjudicates transient-vs-preindustrial from an observation that was not used to decide it.**
Alkalinity carries no Suess signal and essentially no C_ant, so the contamination that trapped
the δ¹³C arithmetic does not bite. Fix the split by ALK, the fractionation by ε_org = −20, and
the δ¹³C gradient is a **prediction with nothing left to tune**:

| scoring | predicted δ¹³C | required | ratio |
|---|---|---|---|
| preindustrial (D = observed +233.1) | −1.578 ‰ | −0.861 | **1.83** |
| **transient (D = the model's +280.2)** | **−1.965 ‰** | **−1.878** | **1.05** |

**Three independent GLODAP gradients are mutually consistent only under the transient scoring.**
Independent corroboration of Marcus' 2026-08-16 epoch decision.

**CONSEQUENCE FOR TASK 9, and it inverts what I recommended an hour earlier: the TWO-LIMB pump
is now the CHEAP option.** The split is pinned by an observation, ε_org stays at the canonical
−20, and the effective-ε stand-in (−14.55, which sits outside the −20 to −22 range and hides the
carbonate limb) is no longer needed. Zero fitted parameters either way.

**NOT done, and required before this could ever be a likelihood term:** the ALK gradient's σ has
not been block-bootstrapped **on the contrast**. The cell spread is reported instead and labelled
as such. DIC's cross-layer covariance inflated its σ_Δ 25 %, so composing σ any other way is a
known error of that size.

---

## 2026-08-16 (night) — The ALKALINITY gradient is the FOURTH likelihood term (`ocean_grad_alk`), and its model side is a steady-state solve rather than a fourth tracer

Marcus: make it a term unless there is a good reason not to. There was not one, but there was
a design fork and a population hazard, both measured rather than assumed.

**THE TARGET, built the same way the other two were** (`data-raw/build_glodap_deep_targets.R`,
new block; `G2talk` extracted from the master into `glodap_dic_talk_subset.csv`, 464,590 usable
bottles):

| | value |
|---|---|
| target | **+78.5927 µmol/kg** (0–100 m vs >2627.2 m, fixed depths) |
| σ | **19.199** — block bootstrap **on the contrast**, 4000 draws, seed 20260816, conservative of the two valid block sizes (30° gives 13.879) |
| epochs | 2002.4 surf / 2002.5 deep (recorded for provenance; alkalinity has no transient) |
| **miss with no pump** | **4.09 σ, −12.25 log-units** |

**Every pre-existing field of `obs_glodap_deep.rds` is bit-identical** (`all.equal(tolerance = 0)`
against the pre-build copy). `gd_grad_boot()` re-seeds per call, so the new bootstrap cannot
perturb the shipped ones.

**THE POPULATION HAZARD, measured because the first report mixed two samples.** The shipped DIC
target comes from the isotope subset ("bottles carrying δ¹³C or Δ¹⁴C", 2897/533 cells);
alkalinity is measured on far more bottles (5886/829). Forming the carbonate share as
ALK-gradient ÷ DIC-gradient across the two compares different samples of the ocean. Recomputed
the DIC gradient **on the alkalinity population**: **+225.81 vs the shipped +233.11**, a
**−0.29 σ** move, and the carbonate share goes **22 % → 23 %**. Immaterial — but it is now
measured, and `gradient$tco2_alkpop` is stored for it. **The shipped DIC target is unchanged.**

**THE MODEL SIDE IS THE INTERESTING DECISION, and it is NOT a fourth tracer.** Alkalinity in
this model has **no air-sea flux, no decay, no anthropogenic source** — so unlike DIC it has **no
transient**, and its profile is fully determined at every date by the export field. A state
column would carry the same information at the cost of the state, the C++ core, the Newton
spinup and the parity tests. Shipped instead:

- `ccx_steady_profile_from_source()` — source field → the profile it holds, **the exact inverse
  of `dg_export_field()`**. That inverse relationship is what makes the row testable *before a
  pump exists*: a round-trip test composes the two and must return the profile it started from.
- `ccx_model_ocean_alk_gradient(spin, pump = NULL)` — **returns exactly 0 today, for every
  parameter, and that is a model PREDICTION, not a placeholder**: `ALK_SURFACE` enters the
  mixed-layer carbonate solve and nowhere else, so with no carbonate pump nothing can separate
  the two layers. Pass the pump's per-limb export fields when task 9 ships one and the row goes
  live with no other change.
- Stoichiometry as named constants: `LIK_ALK_PER_CARB` = 2 (CaCO₃ dissolution),
  `LIK_ALK_NC_RATIO` = 16/117 (nitrate release). Working values, not fitted, not cited.

**HOW THIS ROW DIFFERS FROM THE OTHER TWO, stated in the code so it cannot be misread.** DIC and
δ¹³C are state variables whose gradients already move (transient leverage ≤ 0.09 σ). The
alkalinity row is a **literal constant with zero leverage** until a carbonate pump exists. It is
shipped anyway for the reason the DIC row was shipped before the pump — the constraint has to be
in the objective for the pump to be scored against it — and the code says **do not quote it as
evidence about anything** until it is given a pump.

**+4 test blocks** (`test-likelihood.R`): the Gaussian and absence contract; **the exact-zero
assertion across h_ml × kz**, which is the property a carbonate pump breaks on purpose; the
round-trip solver test; and a **hand-built pump** that must move the row by the stoichiometry —
a pure organic limb NEGATIVE at −(N:C)×, a pure carbonate limb at exactly +2×.

**A latent bug the new row exposed in the row I shipped this morning.** The term loop used
`is.finite(ocean_grad[[field]])`, and every caller written before today passes an `ocean_grad`
with no `alk` element — `is.finite(NULL)` is `logical(0)`, which is an **error** in `if`, not
FALSE. Guarded with `length(v) == 1L`, which also keeps the absence contract: a row the caller
does not supply is **absent**, not zero.

**logL moves by another −12.25 log-units** and is again incomparable with runs before tonight.

---

## 2026-08-16 (night, later) — TASK 9: the pump is PORTED into both cores, OFF by default — and the port caught a 15 % sampling bias in the shim's export

Marcus: start the port. It is in `R/model.R` + `src/ccx_core.cpp`, not a shim over `ccx_deriv()`.

**OFF BY DEFAULT, AND OFF MEANS BIT-REPRODUCED.** `pump_grad = 0` → `aux$pump` is NULL → not one
line of pump code runs. Same contract `w_up = 0` has carried since 2026-08-13, and the whole
suite is the gate: **4 failing / 858 passing**, the same pre-existing four (was 4 / 767).

| parameter | default | what it is |
|---|---|---|
| `pump_grad` | **0** | preindustrial bottom-minus-ML DIC gradient held, µmol/kg |
| `pump_carb_frac` | **0.23** | carbonate share, **pinned by the alkalinity gradient**, not fitted |
| `pump_mode` | `"N"` | nutrient- vs DIC-limited; **both ported, choice deferred to the refit** |

**Still zero fitted parameters in the export field.** It is solved as the source that makes
GLODAP's observed DIC shape an exact steady state of the model's own diffusion operator. The
shape moved into a build product (`dic_profile`, fixed bins, 25 m near the surface) and is
integrated onto whatever layers a draw asks for — re-binning 50,634 bottles per likelihood
evaluation was never an option. `pump_grad` is **re-normalised on each grid's own layers**, so it
delivers exactly the gradient it names (without that step 233.109 landed at 235.7).

**Emitted through `add_flux()` rather than by touching `dy`** — conservative by the same
construction as every other flux, isotopes at the source ratio, and it appears in the flux trace
as its own `pump` channel. The shim could do none of this and errored under `record = TRUE`.

**Verified**: R↔C++ parity **~1e-15** in both modes; spinup still an exact fixed point (the Newton
branch now fires on the pump as well as the conveyor); `pump_grad` delivered exactly across
`h_ml` ∈ {85, 100, 120} × three magnitudes; and the pre-registered **zero-uptake property** of a
constant-mass pump is now a standing test rather than a diagnostic's one-off finding.

**THE PORT CAUGHT A REAL BIAS IN THE SHIM, and my first diagnosis of it was WRONG.** Port parity
(`calibration/diag_pump_port_parity.R`) agrees to **0.66 % on every row the likelihood scores**
(DIC 0.00 %, δ¹³C 0.66 %, deep Δ¹⁴C 0.23 %) but the **export** disagreed by 28 %. I assumed the
fixed-bin profile was too coarse near the surface and refined it — 250 m → 50 m → 25 m moved the
disagreement **28 % → 8.8 % → 15.2 %**, *not* monotonically toward the shim, which is what said
the diagnosis was wrong rather than under-resolved.

**Measured cause.** Total export is the diffusive flux across the topmost interface alone (the sum
telescopes), so it is set by the **mixed layer's mean DIC**. The shim's `dg_bin()` assigns cells by
`floor(depth/250)`, so all of 0–100 m is **one cell** and its mean is weighted by **bottle
density** — and GLODAP over-samples the shallowest water, where DIC rises fastest (25 m sub-bin
means run 2017.7 → 2083.9 across 0–100 m). The shim's ML is therefore **10.04 µmol/kg too low**
(2038.29 vs a thickness-weighted **2048.33**), its ML-to-box-1 gradient too steep, and its
required export **~15 % too high**. A model mixed layer is a well-mixed slab, so the
thickness-weighted value is correct and the **port is the better estimator, not the deviant one**.

**CONSEQUENCE — numbers reported earlier today are corrected.** The shim's export figures (20.6
GtC/yr at defaults, 25.2 at the pre-gradient mode, 30.3 at g\*) are high by ~15 %; at defaults the
port gives **17.4**, and the literature-POC ratio is nearer **3.1×** than the 3.6× quoted in
DESIGN §5.2c. The mode and g\* figures have not been re-measured. **No row the likelihood scores
is affected** — those agree to 0.66 %.

**As shipped** (`pump_grad` 233.109, h_ml 100, 23 % carbonate): z_DIC −1.79, z_δ¹³C **+2.02**,
z_ALK **+0.21**. The carbonate limb is doing its job — the same DIC gradient costs δ¹³C −0.636
against the single limb's −1.132. **The alkalinity row is no longer a constant**: it is read off
`spin$aux$pump`, the same field the derivative integrated, so it cannot be scored against a pump
the run did not use.

**Two test-infrastructure fixes made along the way.** `skip_if_no_cpp()` was defined in
`test-climate.R`, so it existed only for files testthat happened to run *after* that one and
`test_file()` on any other file failed outright — moved to `setup.R`. And the provisional-constants
**ledger** in `test-constants.R` failed on the two new fractionations, which is the ledger doing
its job; updated deliberately.

**One test of mine was wrong twice, both kept visible.** I asserted mode N and mode D differ at
the preindustrial state — they are **identical** there, because the mixed layer holds exactly
`ml_C0` and the DIC-limited scaling is 1; they diverge only once it is loaded, which is the
mechanism. And the corrected version asserted equality to 1e-14 when the Newton spinup lands the
ML on `ml_C0` to ~1e-7 GtC, making the scaling 1 + O(1e-11). Both now assert what is actually true.

**NOT DONE:** the refit (task 8). And `pump_grad`'s value is still a DESIGN decision, not a
default's to make — the observed gradient is 233.1, the transient rows want ~1.20× that.

---

## 2026-08-16d — the `pump_grad` profile: the four-row objective wants ~1.18× the observed gradient, and all three ocean rows close at once

`calibration/diag_pump_grad_profile.R` (NEW, ~9 min), `DESIGN.md` §5.2g. Handoff 16c §7 item 1 is
the decision "what should `pump_grad` be, and is it fitted?" — **this file measures the profile the
decision needs and does not take the decision. `pump_grad` is still 0 in `R/model.R`.**

**THE HEADLINE.** At the quarantined pre-gradient mode with `h_ml` forced to 100 (the same
operating point as `diag_pump_vs_gradient_terms.R`, which is what makes them comparable), the full
objective puts `pump_grad` at **274.5 ± 13.1 µmol/kg** — **1.178 ± 0.056 × the observed 233.109** —
and the three ocean rows on their own put it at **271.3 ± 14.3**. At the best grid arm (280) **all
three rows close simultaneously**: z_DIC −0.01, z_δ¹³C −0.42, z_ALK +1.08, deep Δ¹⁴C +1.04, with
**zero fitted parameters in the export field**.

**THE FRACTIONATION GAP IS CLOSED BY THE CARBONATE LIMB, AS DESIGNED.** The shim's DIC and δ¹³C
rows wanted export scales **1.37× apart** (= 20/14.55, the fractionation gap — that is why 16b §2
called the failure structural rather than a size error). With two limbs at the pinned 23 % share
the effective ε is −15.2 ‰ and the gap is **1.03×**: DIC demands 1.202×, δ¹³C 1.168×. **ALK is now
the dissenting row at 0.951×**, and it dissents inside its own σ — it is the loosest of the three
(σ = 54.1 in `pump_grad`, against δ¹³C's 18.4).

**+259.4 log-units from OFF, of which +48.2 is rows the pump was never built against**:
`d14c_NH` +25.0, `d14c_SH` +13.9, `d13c_level_MLO` +4.4, `d13c_level_SPO` +3.5 (the gradient rows
are +211.2 of the total). **The margin is an UPPER BOUND, not a verdict** — every arm including OFF
sits at the same unrefitted mode, so the no-pump incumbent never gets the refit that `beta_max`,
`kz` and `h_ml` would give it. This is the iso-observable-slice discipline the ocean-candidate
round cost 309 log-units to learn: read the *shape* and the per-row scales, not the margin.

**THE PINNED CARBONATE SHARE CHECKS OUT INDEPENDENTLY.** Scanning `pump_carb_frac` at fixed
`pump_grad` = 280 gives a quadratic vertex of **0.214 ± 0.026** against the **0.23** that GLODAP's
alkalinity gradient pinned — **0.61 σ**. The transient likelihood and the observed ALK/DIC
stoichiometry agree about the split, arriving from opposite directions. Not a licence to fit it.

**A GATE OF MINE WAS WRONG AND IS FIXED THE RIGHT WAY, NOT THE CONVENIENT WAY.** The zero-uptake
gate was written on logL at 1e−6 log-units — **tighter than the spinup's own convergence** — and
duly reported FAIL at 2.16e−6. Loosening the threshold until it passed would have been the
explaining-away move. Instead the gate now reads the **physical** quantity: max |ΔCO₂(2024)| across
the whole scan is **2.24e−08 ppm**, six orders inside any meaningful leak, and the logL footprint
is printed as context rather than as the test. **PASS.** Second estimator bug caught the same way:
the δ¹³C row is a *ratio* and departs 4.6 % from linear, so a line through the endpoint arms put
its demand at 287.8 against the bracketing pair's **272.3** — a 6 % error, larger than the
row-to-row disagreement the part exists to measure. Both DIC and ALK are exactly linear
(3.2e−11, 2.0e−16), which is what a fixed source under linear transport must be.

**PREDICTIONS.** All four pre-registered predictions held: P1 zero uptake, P2 linearity, P3 the
per-row scales (predicted DIC ~1.19, δ¹³C ~1.15, ALK the dissenter at ~0.95; measured 1.202,
1.168, 0.951), P4 identifiability (predicted σ 15–25, measured 13.1).

**NOT DONE / DELIBERATELY NOT TAKEN:** whether `pump_grad` is fixed or fitted; whether the pump
ships ON; N vs D (not scanned here — the gradient rows cannot tell them apart, so a D column would
duplicate these rows while re-opening a question already deferred to the refit); the refit itself.

---

## 2026-08-16e — `pump_grad` × `kz` is NOT degenerate; the pump-ON decision is taken, its wiring is staged, and 7 tests block it

`calibration/diag_pump_kz_degeneracy.R` (NEW, ~15 min), `DESIGN.md` §5.2h.

**THE PREREQUISITE, PASSED.** §5.2g profiled `pump_grad` with all 19 parameters held — the
condition under which a new parameter always looks best. Over the whole `kz` bracket [3830, 6200]:
**ρ = −0.167**, and `pump_grad`'s marginal σ is **1.01×** its conditional σ (13.0 vs 12.8). Fitting
it buys a direction `kz` cannot supply, exactly as the structural result (transport cannot move the
DIC/δ¹³C gradients) predicts. At `kz` = 6200 — where the posterior actually sits — the optimum is
**270.7**, within **1.4 %** of the 1-D profile's 274.5.

**TWO INTERNAL CHECKS FELL OUT FREE.** `ocean_grad_alk` is *exactly* `kz`-independent across every
column (it reads the export field alone), and the ocean sink is identical down every pump column at
fixed `kz` — the zero-uptake property holding across the whole bracket, not just at one mode. Also
verified directly at DEFAULT parameters: pump ON vs OFF gives CO₂(2024) identical to **2.0e−08 ppm**
and 1750–2024 uptake identical to **1.2e−07 GtC**, while adding **+3,457 GtC** of preindustrial
interior inventory.

**A PREDICTION OF MINE CAME BACK UNRESOLVED, NOT FALSE, AND THE FILE NOW SAYS SO.** P3 predicted the
optimum would move < 15 % across the bracket. Three of four `kz` columns peaked at the **top of my
pump grid**, so their optima are lower bounds and the first run's "20.2 % — FAIL" was a property of
the grid, not the model. Rather than widen the grid, part 5 measures the mechanism: at `kz` = 3830,
`pump_grad` 290 → 335 gains **+34.1 on atmospheric radiocarbon** while the three gradient rows
**lose** 5.2 — an under-ventilated column uses the constant-mass pump as a **bomb-¹⁴C sink**. Real,
and off the posterior's support: at `kz` = 6200 the same channel changes sign.

**P2 HELD.** `kz` prefers the bracket's top with the pump both OFF and ON; the pump makes deep water
older at every `kz`, which at 6200 moves that row toward its target (+1.60 → +1.15). The bracket was
bisected at default parameters on a model with **no pump**, on the very row the pump moves — it is a
refit question, not something to inherit.

**MARCUS'S DECISION (2026-08-16d): the pump ships ON, and `pump_grad` is FITTED** with its prior
anchored on the observed 233.109. Wiring written: `PUMP_GRAD_OBS` in `constants.R` (with the
observed value, not §5.2g's fitted 274.5 — that is a fit at a `kz` the refit will move), the
default in `model.R`, and the 20th `CCX_PARAM_TABLE` entry, `tr = "log"`,
`dlnorm(log(PUMP_GRAD_OBS), 0.25)`. The prior mildly double-counts GLODAP and says so in place:
its ±25 % width is ~4.5× the likelihood's own 13.1 µmol/kg.

**THE WIRING IS NOT COMMITTED, AND THAT IS THE POINT.** Pump-ON takes the suite **4 → 19 failing
expectations across 11 tests**. Attributed by running the full suite at HEAD and with the change:
the **4 are pre-existing and unchanged**; **7 tests are new**. One of the seven pre-declares this
event in its own comment and fails at exactly 233.109 — the pump installing precisely the gradient
it names. **No test was edited.** Two of the seven — "single derivative agrees to roundoff" and
"the pro-rata land-use debit agrees to roundoff" — could be a genuine parity break rather than a
stale expectation, and are the first thing to diagnose.

**ONE MIS-ATTRIBUTION OF MINE, CORRECTED BY MEASUREMENT.** I first read the `test-luc-permanence.R`
failures as caused by the pump, since a constant-mass pump should not move a fossil pulse's airborne
fraction. Measured at `pump_grad = 0`: af = **0.1513** at lag 100, **identical to the pump-ON arm at
every lag** (1, 10, 50, 100, 150, 250 yr). They were already failing at HEAD. The property was never
in question; my attribution was.

## 2026-08-16e — The seven tests re-derived; the pump wiring COMMITTED; the advection hypothesis on record was WRONG

**The blocker from 16d is cleared.** All seven new failures re-derived, suite back to the
pre-existing 4 — **855 passing against 802 at HEAD**. `git checkout -- R/` is no longer the escape
hatch; the pump ships. **No test was re-expressed to make a model change pass**: five of the seven
now assert *more* than before, and two ended up catching real defects (below). DESIGN §5.2i.

**MY OWN HYPOTHESIS WAS WRONG, AND KILLING IT COST NOTHING BECAUSE IT WAS FLAGGED AS A GUESS.**
Handoff 16d §5 offered "the export field is solved per hemisphere, so reversing which hemisphere
sinks is no longer a symmetry" for `test-ocean-advection.R`. **Inapplicable, on inspection before
any run**: `w_up` is a single *global* parameter and the test sets `w_out_NH = w_out_SH`, so **no
hemisphere is ever swapped** — each column is reversed separately and identically. Both hemispheres
break in the *same* direction, at the ratio of their ocean areas (1.24 measured vs 1.33), which a
swap cannot produce.

**WHAT IS ACTUALLY HAPPENING** (`calibration/diag_pump_advection_symmetry.R`, ~1 min, five
pre-registered predictions, all confirmed). `e^{A_out t} = D (e^{A_up t})^T D^-1`, so propagator
element (i,j) maps to (j,i): the mixed layer's **(1,1) is preserved BIT-EXACTLY** (|gap| =
**0.000e+00** at 10 and 60 yr) and **interior→ML elements differ by O(1)** (0.402, 0.220).
**The atmosphere's invariance was always conditional on the ocean having no interior source — the
test said so in its own words — and the pump is the model's first interior source.** Premise
falsified, theorem intact. **NOT A BUG:**

- **CO₂, the mixed layer and the land still tie EXACTLY** (≤ 1.8e-12) at every `pump_grad` from 0 to
  466.2. The break does not scale with the pump at all.
- `ocean_C`'s **1351.8 GtC** gap is a *preindustrial-inventory offset*, flat to **7.3e-11** across
  the run — a different steady state, not a different response.
- What breaks is the **isotopes**: δ¹³C **1.7e-3 ‰** against a 0.44 ‰ σ — **0.4 % of one sigma**.

**AND THE MECHANISM HAS ITS OWN MUTATION TEST.** In `pump_mode` "N" the export *mass* is fixed, so
12C's interior source is a **constant field** and cancels from the linear anomaly equation. Mode N
does not fix the export's *isotopic ratio*, which rides the Suess effect. **Mode "D" makes 12C's
export state-dependent too and CO₂ moves 5.3e-2 ppm — 6e10× mode N.** State-*dependence*, not mere
presence, is what reaches the atmosphere.

**TWO TESTS CAUGHT REAL DEFECTS, WHICH IS THE ARGUMENT FOR RE-DERIVING RATHER THAN RE-BASELINING:**

- The **`PUMP_GRAD_OBS` ↔ `ocean_grad_dic` consistency test** promised in 16d §4 was written and
  **failed on its first run**: the constant was hand-typed **233.109** against a shipped target of
  **233.109378176267**. 1.6e-6 relative — physically nothing, and *exactly* the drift the test
  exists to prevent. Both the constant and `CCX_PARAM_TABLE$pump_grad$init` now carry the target's
  own digits.
- **`test-parity.R` was NEVER a parity break** (16d already retracted that priority call on
  measurement) and the tolerance is now **derived, not re-baselined**: the pump emits into `nl` = 10
  boxes on both limbs = **20 extra terms** carrying **18.83 GtC/yr**, so reassociation is bounded by
  20 × ε × 18.83 = **8.36e-14** against a **measured 8.53e-14 — 1.02×**. The disagreement is the
  pump's own fluxes summed in a different order and nothing else. Tolerance = 4× the derived bound,
  with a **pump-OFF arm retained at the original 1e-15** so a real break cannot hide in the budget.

**THE REST.** The `test-likelihood.R` tripwire fired as designed and split into two arms — OFF keeps
the zero-uniformity claim unweakened, ON asserts the interior gradient **equals `pump_grad` to 1e-13
for every parameter perturbed**, including `kz` and `h_ml`, which is a strictly stronger statement
than "nonzero". The leverage test's **guard**, not its bound, is what failed: the pump closed the
miss **11.02 σ → 1.79 σ**, so `expect_gt(miss, 5)` fired while every leverage stayed inside
`LEV_MAX`; restated as the ratio it always meant (≤ 0.049 measured against a 0.10 gate). **The pump
does not touch the leverage at all** — identical to three digits on and off — which is the
level-vs-sensitivity separation the pump was adopted for, and is now gated. `test-pump.R` was
testing the *default* under a title about *bit-reproduction*; split, and the reproduction claim
strengthened to run against a parameter list carrying no `pump_grad` at all.

**NOT DONE.** `test-parity.R`'s frozen-Revelle arm still carries a bare `1e-15` and **passes** with
the pump on, so it was left alone rather than swept into `PARITY_REL_TOL` — a passing gate is not
something to loosen on tidiness grounds. It is the one place the derivation above is not yet
applied, and it will fire if a future mechanism raises the flux count through that branch.

## 2026-08-16f — kz re-bisected for the pump; the two-arm refit is BUILT and SMOKE-TESTED but NOT LAUNCHED

**Marcus 2026-08-16e: fit `pump_mode` "N" and "D" and compare** — DESIGN §5.2f deferred that to the
refit and this is it. `ccx_make_logpost()` gained `base_params` so a STRUCTURAL choice that is not a
fitted parameter can be varied between two otherwise identical objectives; the default path is
bit-identical (`identical()` on the log-posterior at init). N and D differ by **314 log-units at the
hand-set init**, which is precisely why they must be *refitted* rather than compared there.

**THE `kz` BRACKET WAS RE-BISECTED FIRST, and Marcus took the decision on the numbers.** It would
otherwise have decided the answer: §5.2h P2 measured `kz` **pinning to the bracket's top**, so the
top is the refit's `kz`, and [3830, 6200] was bisected on a model with **no pump** against the very
row the pump moves. **The pump-OFF control reproduces the shipped bracket to 1.3 / 0.8 m²/yr**, so
the recipe is faithful; pump-ON gives **[3942.5, 6528]**, the top **+328 m²/yr (+5.3 %)** — the pump
makes deep water older, so it *buys* `kz` headroom. **N and D give the identical bracket** (at the
preindustrial steady state D's scale factor is 1 by construction, so the arms differ only in the
transient) — it cannot bias the comparison. On the **bottom box**, the layer actually scored, the new
bracket is −219.8 / −162.8 against −220.4 / −163.5: nearly a no-op on the scored quantity.

**THE RUN IS NOT LAUNCHED, AND THE SMOKE TEST IS WHY.** A truncated two-arm run (1 restart, 60
iterations) was cheap and it surfaced a blocker that would have wasted ~11 h:

- **`h_ml`'s init is 75 and `LIK_OCEAN_GRAD_HML_OK` is [85, 120] — the objective STARTS with all
  three ocean-gradient rows ABSENT.** This is handoff 16d §7 item 7 ("where does the refit's `h_ml`
  land?") arriving with teeth.
- **The switch is a real discontinuity and it pays to be outside.** Measured at otherwise-init
  parameters: crossing 84.99 → 85.00 (absent → live) **costs 10.07 log-units**; crossing
  119.99 → 120.01 (live → absent) **gains 9.6**. A mode-finder is rewarded for leaving the band.
- **And `h_ml`'s own likelihood pulls it well below the band anyway** — the log-posterior falls
  monotonically from −4105 at `h_ml` = 70 to −4703 at 150. The previous mode's `h_ml` was **183.95**;
  the truncated arm landed at **exactly 85.00**, sitting on the edge from the outside.
- **The rows are what constrain `pump_grad`, so this is not cosmetic.** With them LIVE (`h_ml` = 100)
  the best `pump_grad` is **250.0 — 0.28 prior sd**, close to both the observation (233.1) and the
  1-D optimum (274.5). With them ABSENT the parameter is held by its prior plus weak leverage: the
  truncated 20-parameter arm ran it to **963.6, |z| = 6.27**.

So a refit launched as-is would very likely compare N against D **in the regime where the pump's
main constraint is switched off**, for both arms — apples-to-apples, but the wrong apples. Put to
Marcus rather than resolved here; `calibration/run_modefind_pump_arms.R` is written, gated
(it refuses to run if the two arms differ in anything but `pump_mode`), and ready.

## 2026-08-16g — The `h_ml` cliff DECOMPOSED: it is not why `h_ml` leaves the band, and the taper does not fix the part that matters

`calibration/diag_hml_band_discontinuity.R` (~4 min, 5 pre-registered predictions, 4 gates).
Handoff 16f §5 measured the cliff and offered four options; it did not decompose it. **Nothing was
proposed and `R/likelihood.R` is unchanged** — the four options stay Marcus's call. DESIGN.md §5.2k
has the full account.

**Four gates first, so the decomposition is of the real objective and not of a lookalike.** The
by-stream split needs a replica of `ccx_make_logpost()`; GATE B asserts the replica's total equals
the real objective's at an in-band and an out-of-band point (**gap 0.000e+00 at both**). GATE C: the
out-of-band counterfactual row values reproduce the gated ones in-band to **0.000e+00** over 11
points. GATE D: part 4's cell recipe reproduces both shipped GLODAP targets to **0.00e+00** before
any `h_ml` moves.

- **THE CLIFF IS EXACTLY "THE ROWS APPEARED", TO 1e-12.** The identity
  `Δ total = (rows that appeared) + (continuous drift)` closes to **−6.4e-13** at the floor and
  **−2.4e-12** at the ceiling. Only the three `ocean_grad_*` streams jump; the other 16 plus the
  prior are continuous, and the jump is **85×/60×** the drift the same 0.02 m step produces. So
  `h_ml` = 85 does not *fit worse* than 84.99 — **it is scored on more data.**
- **TWO SEPARABLE DEFECTS WEAR ONE NUMBER.** **(A) a barrier** — the discontinuity, 16f §5.4's MCMC
  hazard. **(B) an incentive** — the objective is *paid* to discard rows, since a skipped Gaussian
  contributes 0 where a live one contributes a negative number.
- **A TAPER FIXES (A) AND NOT (B), and that is an identity rather than a measurement:** for any
  weight on a negative row sum, the objective is monotone the wrong way. Measured at ramp
  half-widths 15/30/60 m, the argmax over `h_ml` is **32 m in every case** — identical to the
  shipped hard skip, to the rows deleted, and to the rows always live.
- **THE HEADLINE: THE ROWS ARE NOT WHY `h_ml` LEAVES THE BAND.** The objective's argmax over `h_ml`
  is **32 m** (30 is the prior bound, where `qlogis(0)` = −Inf) against a best in-band 85.01 — a
  **236 log-unit pull against a 10.0 log-unit cliff, 24×** — and **deleting the three rows moves the
  argmax not at all (32 → 32 m)**. No formulation of the rows can pull `h_ml` back in. **Option 1 is
  therefore not a tie-breaker between formulations; it is a hard constraint costing ~236 log-units**
  at init parameters — an **UPPER BOUND** (same caveat class as §5.2g's pump margin: `beta_max`, `kz`
  and `k_w` can reallocate some of it in a refit).
- **A FIFTH OPTION, NOT ON 16f's LIST: σ-INFLATION.** The band encodes a **representation error**, and
  the honest way to carry one is in quadrature — `σ_eff² = σ_obs² + σ_rep(h)²` **with dnorm's
  normalisation retained**, so inflating is charged for rather than free and the gain is bounded. Not
  a tuning knob: `σ_rep(h)` is **measured** as the shipped-minus-like-for-like target gap.
  **DIC `σ_rep/σ_obs` 0.04–0.87 over `h_ml` 32–192, δ¹³C 0.01–1.11** (in-band DIC 0.04–0.34) — i.e.
  **the mismatch the band exists to prevent never exceeds ~1σ anywhere in the prior support.**
  Alkalinity's is **UNQUANTIFIED**: the GLODAP subset carries no `talk` column.
- **TWO PREDICTIONS FAILED, BOTH INFORMATIVELY, AND NEITHER BAR WAS LOOSENED.** P4 predicted
  inflation would recover >50 % of what the skip gives away; measured **21 %** (2.14 of 10.01) — the
  *reasoning* was wrong, not the bar: at ~1.8σ misses `z²/2 ≈ 1.6` while `−log(σ√2π)` carries the
  bulk, so inflation is a **stronger** remedy than predicted. P5 predicted `σ_rep` would exceed
  `σ_obs`; it barely does, which is what reframes the band as disproportionate.
- **P1's first bar was measuring a slope and was RE-DERIVED, not re-baselined.** An absolute
  0.05 log-unit bar on "nothing else moves discontinuously" failed at 0.0696 — on the objective's
  ordinary ~8 log-units/m gradient in `h_ml`, which over a 0.02 m straddle is ~0.16 of legitimate
  drift. Restated as the claim actually being made: the jump must dwarf the drift the same step
  produces (85×/60× against a 20× bar). P2 likewise became an **exact identity** (bar 1e-6, residual
  1e-12) rather than a 0.10 tolerance.
- **RECEIPT CHECK: `R/likelihood.R`'s own "1.61 σ at 184" is ~2× overstated.** The "0.09 σ at 100"
  half reproduces (0.07). The other half does not: against the gate's own quantity and the σ the
  gate's own term uses, `h_ml` = 184 is **0.80 σ**. 1.61 is the *frozen-at-75* contrast divided by
  the **tighter blk30** σ (20.16) — the shipped rds carries
  `sd_by_block = c(blk30 = 20.16, blk60 = 25.25)` and ships the conservative 25.25, while
  `diag_gradient_target_and_neff.R` called `part2b()` with `min(...)` over valid blocks. Reproduced
  to **1.58 vs 1.61**. **Not a code defect — the band still guards a real mismatch** — but the band's
  severity has been argued from 1.61 in three handoffs.

**Two bugs in this file's own first drafts, both caught by its gates rather than by inspection.**
`ccx_par_to_unc(ccx_default_params())` errors, because `bomb_total`, `luc_scale`, the two sigmas and
the two gradient offsets are fitted parameters with **no field in `ccx_default_params()`** — the init
vector must come from `ccx_init_unc()`. And `ccx_loglik(by_stream = TRUE)` returns a **named numeric
vector, not a list**, so `[[missing_name]]` *errors* instead of returning NULL — which for a file
about absent streams would have been fatal.

**PART 7 — who pays the 236 (added same day).** The pull is **not a consensus**: between `h_ml` = 100
and 32, `co2_level_SPO` (+144.5), `co2_level_MLO` (+98.0) and `d14c_SH` (+68.0) carry **96 %** of
+324.5, while `d13c_level_MLO` (−26.4), `d13c_level_SPO` (−18.5) and `gcb_ocean_sink` (−10.8) pull the
**other way**. A thinner mixed layer absorbs less carbon, so airborne CO₂ rises — **the CO₂-level
streams want `h_ml` small because the model at init OVER-ABSORBS**, and `co2_level_SPO` is −256
log-units at `h_ml` = 100, i.e. init is a bad fit to the CO₂ record. Since `kz`, `k_w` and `beta_max`
move ocean and land uptake directly — serving exactly those three streams — **`h_ml` is simply the
cheapest single knob available while the other 19 are frozen, so part 6's 236 is an upper bound AND
probably a large overstatement** of what bounding `h_ml` would cost a refit. **What survives
unconditionally is the negative result: the gradient rows are irrelevant to where `h_ml` goes, so no
re-formulation of them fixes the pull.**

## 2026-08-17 — The "1.61 σ at 184" prose corrected in `R/likelihood.R` (16g open item 5)

**Comment-only. Nothing in the objective changed, and the two-arm refit launched 2026-08-16g was
running throughout** (comments cannot reach a process that sourced the file at startup, and the diff
was verified to touch no executable line).

16g §2.5 receipt-checked `R/likelihood.R`'s own justification for the `h_ml` band and found the
number it argues from is ~2× overstated, but left correcting the prose as open item 5 — "small, but it
is load-bearing prose". Discharged:

- **The `h_ml` gate paragraph** now reads **"0.07 σ at `h_ml` = 100 and 0.80 σ at the fitted 184"**,
  and says explicitly that those are *this gate's own quantity* —
  `(shipped target − like-for-like target at h_ml) / shipped sd`. It also now carries what 16g §2.4
  measured and the file never stated: the mismatch the band exists to prevent is **sub-1σ everywhere
  in `h_ml`'s prior support** (DIC `σ_rep/σ_obs` 0.04–0.34 in band, 0.22–0.87 out).
- **The fixed-depth TARGET bullet** dropped the bare "1.61 σ" and now gives the frozen-at-75 contrast
  on the σ this term actually ships (blk60, 25.25) — **1.26 σ** — with a pointer to where 1.61 came
  from. The bullet's *argument* is untouched: freezing at 75 still overstates the miss and still
  biases in favour of adopting a pump, which is why fixed depths were chosen.
- Both sites cite `calibration/diag_hml_band_discontinuity.R` part 5 as the receipt.

**`HB_REF_MISMATCH_184 <- 1.61` in the diagnostic is deliberately NOT changed** — part 5 *divides* by
it to recover the σ it implies (19.83 ≈ blk30's 20.16 to 2 %), which is the step that identifies
where 1.61 came from. Only its comment moved, from "R/likelihood.R's own figure" (now stale) to "the
HISTORICAL figure this part receipt-checks".

**Not done here:** the band itself is unchanged (`LIK_OCEAN_GRAD_HML_OK` is still `c(85, 120)`), and
σ-inflation (16g §2.4, open item 4) remains unimplemented and Marcus's call. This commit corrects
what the file *claims*, not what it *does*.

## 2026-08-17 — The "1.61 σ at 184" prose corrected in `R/likelihood.R` (16g open item 5)

**Comment-only. Nothing in the objective changed, and the two-arm refit launched 2026-08-16g was
running throughout** (comments cannot reach a process that sourced the file at startup, and the diff
was verified to touch no executable line).

16g §2.5 receipt-checked `R/likelihood.R`'s own justification for the `h_ml` band and found the
number it argues from is ~2× overstated, but left correcting the prose as open item 5 — "small, but it
is load-bearing prose". Discharged:

- **The `h_ml` gate paragraph** now reads **"0.07 σ at `h_ml` = 100 and 0.80 σ at the fitted 184"**,
  and says explicitly that those are *this gate's own quantity* —
  `(shipped target − like-for-like target at h_ml) / shipped sd`. It also now carries what 16g §2.4
  measured and the file never stated: the mismatch the band exists to prevent is **sub-1σ everywhere
  in `h_ml`'s prior support** (DIC `σ_rep/σ_obs` 0.04–0.34 in band, 0.22–0.87 out).
- **The fixed-depth TARGET bullet** dropped the bare "1.61 σ" and now gives the frozen-at-75 contrast
  on the σ this term actually ships (blk60, 25.25) — **1.26 σ** — with a pointer to where 1.61 came
  from. The bullet's *argument* is untouched: freezing at 75 still overstates the miss and still
  biases in favour of adopting a pump, which is why fixed depths were chosen.
- Both sites cite `calibration/diag_hml_band_discontinuity.R` part 5 as the receipt.

**`HB_REF_MISMATCH_184 <- 1.61` in the diagnostic is deliberately NOT changed** — part 5 *divides* by
it to recover the σ it implies (19.83 ≈ blk30's 20.16 to 2 %), which is the step that identifies
where 1.61 came from. Only its comment moved, from "R/likelihood.R's own figure" (now stale) to "the
HISTORICAL figure this part receipt-checks".

**Not done here:** the band itself is unchanged (`LIK_OCEAN_GRAD_HML_OK` is still `c(85, 120)`), and
σ-inflation (16g §2.4, open item 4) remains unimplemented and Marcus's call. This commit corrects
what the file *claims*, not what it *does*.

## 2026-08-17 (later) — Alkalinity's `σ_rep` MEASURED: 16g's "would need a new download" was wrong, and the row is the best-behaved of the three

`calibration/diag_alk_sigma_rep.R`, ~30 s, **3 gates + 3 pre-registered predictions, all passing**.
Nothing proposed; `R/likelihood.R` unchanged; the two-arm refit was running throughout and this was
sized to not compete with it (one 19 MB CSV read, no model evaluation).

**THE BLOCKER WAS A FILE-POINTER MISTAKE, NOT MISSING DATA.** 16g §2.4 left σ-inflation (open item 4)
with two of three inputs, recording that "alkalinity's `σ_rep` is UNQUANTIFIED — the GLODAP subset
carries no `talk` column, so it would need a new download or a stated assumption." The first clause is
true of the file 16g's part 4 reads (`glodap_c13c14_subset.csv`); **the inference is not.** The shipped
ALK target was never built from that file — `data-raw/build_glodap_deep_targets.R:324` reads
`glodap_dic_talk_subset.csv`, **464,590 QC-passed bottles already on disk**, because (its own comment)
"alkalinity is measured on far more bottles" than the isotope cruises. Part 4 pointed at one file while
the target came from another. No download, no assumption.

**GATES.** The recipe is copied from part 4 (itself copied from `diag_gradient_target_and_neff.R`) and
not re-chosen. **G1/G2** reproduce **both** shipped targets from this file's own cells before any `h_ml`
moves — `talk` **78.5927** and `tco2_alkpop` **225.8087**, each to **0.00e+00**. Two fields are gated,
not one, because a recipe reproducing only `talk` could be right by luck about the cells and wrong about
the cosine weighting. **G3** asserts `ccx_ocean_grid(100)`'s surface box *is* the shipped 0–100 m layer
to 1e-9, which is what makes the curve's floor interpretable as the closed-vs-open edge convention
rather than a depth mismatch.

**THE RESULT — the row feared unquantified carries the SMALLEST representation error of the three:**

| row | in band | all `h_ml` | source |
|---|---|---|---|
| DIC | 0.04–0.34 | 0.04–0.87 | 16g part 4 |
| δ¹³C | 0.01–0.55 | 0.01–1.11 | 16g part 4 |
| **ALK** | **0.02–0.07** | **0.02–0.34** | **this file** |

At the quarantined mode's `h_ml` = 184 the ALK mismatch is **0.17 σ**; in band it never exceeds
**0.07 σ**. The DIC/δ¹³C comparators are **read from 16g's own saved rds**, not transcribed from its
handoff, so the table cannot inherit a prose typo — and doing so filled in a cell 16g's handoff left
blank (δ¹³C in-band, 0.01–0.55).

**This STRENGTHENS 16g §2.4 rather than qualifying it.** The band switches all three rows off together,
and every one of them is sub-1σ across `h_ml`'s entire prior support — a 10-log-unit switch enforcing,
at worst, a 1.11 σ mismatch and at best a 0.02 σ one. **Predictions: 3/3 PASS** (Q1 max ratio 0.342 vs
bar 1.20; Q2 in-band 0.067 vs 0.40; Q3 r = 0.922 vs 0.90 — ALK's `σ_rep` tracks DIC's in shape, as two
gradients of carbon-like tracers read on the same box edges should).

**NOT done, and still Marcus's call:** σ-inflation remains **unimplemented**. This supplies its missing
input; it does not price it. 16g's "inflation recovers 21 % of the skip's gain" is untouched — that
needs the model's own gradient at each `h_ml`, and the refit owns the machine.

## 2026-08-18 — THE TWO-ARM REFIT LANDED. §5.3 took the good branch; N favoured by 5.62; and the pre-refit per-stream reading REVERSED

`calibration/run_modefind_pump_arms.R`, launched 2026-08-16g, **23 h 57 m wall** (N 753.5 min /
303,661 evals; D 683.0 min / 297,804 evals). Outputs at `calibration/output/pump_arms/`:
`mode_fit_pump{N,D}.rds` + `pump_arms_comparison.rds`. **This is the first serious calibration this
model has ever had** — `calibration/output/mode_fit.rds` is still absent and every previous "at the
mode" number came from the pre-gradient-terms quarantine.

**§5.3 — THE CO₂-LEVEL STREAMS RECOVERED, so the bound was cheap and the comparison is readable.**
Verified against 16g's saved rds rather than its prose:

| stream | 16g @ `h_ml` = 100, else init | arm-N mode | recovery |
|---|---|---|---|
| `co2_level_SPO` | −255.94 | **−62.87** | **+193.1** |
| `co2_level_MLO` | −182.72 | **−73.75** | **+109.0** |

Biggest movers: `co2_seasonal_MLO` **+676.3**, `d13c_gradient` **+490.0**, `d14c_SH` +166.7,
`d13c_level_MLO` +166.1. Only three streams worsened, all trivially (≤ 3.2).

**AND `h_ml` LANDED INTERIOR IN BOTH ARMS — 94.36 (N), 91.16 (D) — with the gradient rows LIVE.**
Nobody pre-registered this and it is the cleanest confirmation available: had the 236-log-unit pull
survived a refit, `h_ml` would sit pinned at the 85 bound. It does not, in either arm. **§3's "236 is
an upper bound and probably a large overstatement" is CONFIRMED — the pull was an artefact of holding
the other 19 parameters at init**, and `kz`/`k_w`/`beta_max` absorb the CO₂-level misfit directly.

**`pump_grad` IS CONSTRAINED IN BOTH ARMS** — 289.60 (N), 282.26 (D), against **963.6 / 1431.0** in
16f's rows-off truncated arms. Both sit near the old mode's 1-D optimum (274.5) and above the observed
233.11. The gradient rows are doing the job they were added to do.

### The comparison

| | N | D | D − N |
|---|---|---|---|
| log-posterior at MAP | −2091.16 | −2096.26 | −5.10 |
| ½ log|−H| | 61.43 | 61.96 | +0.52 |
| **Laplace log-evidence** | | | **−5.62** |

**N is favoured by 5.62 log-units.** Both Hessians PD (cond 6.8e5 / 5.5e5), so `recompute_hessian.R`
was not needed for either arm. The `(d/2)log 2π` term cancels (same 20 parameters) and 16g §4's prior
renormalisation constant (+1.5805) is identical in both arms, so it cancels too.

### THE PER-STREAM TABLE REVERSED THE PRE-REFIT READING — and 16g §5.4 was right to insist on reading it fresh

16f's *truncated, unconverged* table hinted D gains on `co2_seasonal_MLO`, `d14c_NH` and
`d13c_level_SPO`. Two held. **The third reversed outright: `d13c_level_SPO` is D's single biggest
LOSS (−9.74), not a gain.** And the framing "D's gain was entirely the CO₂ record" is **wrong**:

| what D buys | Δ | what D sells | Δ |
|---|---|---|---|
| `gcb_ocean_sink` | +2.51 | `d13c_level_SPO` | **−9.74** |
| `gcb_land_sink` | +1.93 | `d13c_level_MLO` | **−7.30** |
| `d14c_NH` | +1.92 | | |
| `d14c_SH` | +1.80 | | |
| `co2_seasonal_MLO` | +0.90 | | |
| `d14c_deep_ocean` | +0.77 | | |

**The CO₂ LEVELS are essentially tied** (−0.43 MLO, −0.16 SPO) and `d13c_gradient` is tied to
**+0.00**. So the contest is **δ¹³C levels (N wins, −17.04) against sinks + ¹⁴C (D wins, +10.91)**,
net loglik −6.13. **This independently corroborates the pump × advection symmetry result**
(`project_ccx_pump_advection_symmetry`: the reversal ties CO₂ and breaks only the ISOTOPES) — at two
modes that differ in all 20 parameters, CO₂ ties and the isotopes decide.

### Caveats, none of them dismissible

- **The driver's own words: "READ THIS AS INDICATIVE, NOT AS A BAYES FACTOR."** `kz` sits 96.6 % (N)
  and 88.9 % (D) up the re-bisected bracket, so the posterior is non-Gaussian in that direction and
  the Hessian reports the transformed coordinate's curvature.
- **BOTH ARMS HIT THE 20-RESTART CAP WHILE STILL GAINING** and both are flagged NOT CONVERGED.
  `ARM_TOL` = 1e-4 is unreachable for a 20-parameter Nelder-Mead here. Practical movement is tiny
  (N moved 0.7 log-units over restarts 8→19; BFGS polish gained 0.09), so these are plateaus, not
  climbs — **but that ~0.7 plateau wander is the noise floor, and 5.62 is only ~8× it.**
- `bomb_total` sits at **z = +3.01** in N and is flagged; D flags nothing.
- One `conveyor 12C spinup did not converge` warning, |resid| = 1.79e-06.
- **`ARM_HESS_EPS` = 3e-4 is still inherited from an 18-parameter run** and un-re-derived at 20
  (16g item 3, still open even though both Hessians came back PD).

**Open: N or D is Marcus's call** (16g item 2). The evidence points to N; whether 5.62 against a
0.7 noise floor and a pinned `kz` is decisive enough is the judgement.

## 2026-08-18 (decision) — **ARM N ADOPTED, PROVISIONALLY** (16g open item 2 — Marcus 2026-08-18)

**Decision: adopt N as the mode and unblock the critical path, with the choice recorded as
PROVISIONAL and revisited once the sampler produces a real posterior.**

**The case for N:** favoured on Laplace evidence (**5.62 log-units**, ~8× the ~0.7 plateau noise
floor), favoured on MAP height (−2091.16 vs −2096.26), and it wins the **δ¹³C levels** (+17.04 over D)
— the stream class the gradient rows and the pump were added to constrain in the first place.

**WHAT "PROVISIONAL" IS CARRYING, and it is not a formality.** Every one of these stands unresolved:

- **The driver's own verdict: "INDICATIVE, NOT A BAYES FACTOR."** `kz` sits **96.6 %** (N) / **88.9 %**
  (D) up the re-bisected bracket, so the posterior is non-Gaussian in that direction and the Hessian
  reports the transformed coordinate's curvature rather than a free one's.
- **BOTH arms hit the 20-restart cap while still gaining** and are flagged NOT CONVERGED. They are
  plateaus rather than climbs (N moved 0.7 log-units over restarts 8→19; BFGS polish +0.09), **but
  that ~0.7 wander is the noise floor and 5.62 is only ~8× it.**
- **`bomb_total` sits at z = +3.01 in N and is FLAGGED; D flags nothing.** The adopted arm is the one
  in a prior tail.
- **`ARM_HESS_EPS` = 3e-4 is still inherited from an 18-parameter run**, un-re-derived at 20, and the
  evidence contrast depends on the Hessian it produces.

**Nothing downstream is expensive to redo** if a converged posterior disagrees — which is the whole
reason this is defensible as a provisional call rather than a deferral. **The mode is
`calibration/output/pump_arms/mode_fit_pumpN.rds`.** Note `calibration/output/mode_fit.rds` is
**still absent** and this does NOT create it; do not conflate the two paths.

**NOT decided by this:** whether the σ-inflation redesign ships (open item 4 — its cost still needs
re-deriving over all three rows), and whether a **posterior** run keeps the `h_ml` bound. A hard bound
is defensible for a mode-find and is a **weaker claim for a sampler**; that question is re-opened by,
not settled by, this decision.

## 2026-08-18 (later) — `luc-veg-debit` MERGED into `main` at last (16g item 9)

**Done on Marcus's instruction 2026-08-18, immediately after the refit freed the machine.** The branch
had been carried unmerged since well before the pump work and was flagged in eight consecutive
handoffs.

**It was a STRICT FAST-FORWARD, which is easier than every one of those handoffs implied.** `main` was
a direct ancestor of `luc-veg-debit` — 99 ahead, **0 behind**, no conflicts, and therefore **no
working-tree change at all**. Verified before executing (`git merge-base --is-ancestor`), then run as
`git merge --ff-only`.

| | before | after |
|---|---|---|
| `main` | `0b7371c` | **`e2c9238`** |
| `luc-veg-debit` | `e2c9238` | `e2c9238` (unchanged) |
| HEAD | `luc-veg-debit` | **`main`** |

**FAST-FORWARD WAS CHOSEN OVER A SQUASH, and the reason is recoverability rather than taste:** a
squashed history can always be produced later from preserved commits, while an un-squash is
impossible. This project also leans hard on per-commit provenance — bisecting the pump and gradient
work, and answering "when did this number change" — which a squash would destroy.

**`luc-veg-debit` is KEPT, not deleted.** `0b7371c` is the recovery ref for `main`'s pre-merge state
(`git branch -f main 0b7371c`) if this ever needs undoing.

**The 4 known test failures rode along onto `main`** (`test-pulse.R` af(100) = 0.213 vs > 0.30;
`test-luc-permanence.R` ×2; `test-mechanisms.R` ENSO 0.30 vs > 0.5). They are pre-existing, not
pump-related, and **still undiagnosed since 2026-08-15** — the merge did not create them, but `main`
now carries them. **Diagnosing them is the next queued job**, and the standing rule applies: treat
"plausibly stale gate" as the hypothesis to attack, not the answer — a stale-fixture label has
already hidden a real bug in this project for five handoffs. Repair by deriving the bar, never by
re-baselining it to wherever the code lands.

No remote is configured, so nothing was pushed.
