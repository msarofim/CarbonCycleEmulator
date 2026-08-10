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
