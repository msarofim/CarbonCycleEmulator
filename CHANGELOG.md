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
