# Expert panel — model structure for the pedagogical goal

**CarbonCycleEmulator, 2026-08-13, branch `luc-veg-debit` at `4c10d93`.**

Marcus asked for a **carbon-cycle expert** added to the ocean / atmosphere / ecosystem /
isotope / pedagogical / reduced-complexity lenses, to answer: *what is the best model
structure, given the goal of matching monthly CO₂ and isotope ratios in a way students and
users can understand?* — with a stated motivation:

> *"frustration with so many engineers and scientists over the years who fall for the
> '5 year CO₂ residence time' and 'CO₂ concentrations correlate with temperature' and
> other similar arguments... something that would show why those are wrong in a model that
> has the complexity necessary to match reality but not too much more."*

**That motivation is a specification, and it has not been written down as one before.**
DESIGN §1 lists four scientific goals; none of them is "refute the residence-time
conflation." This note treats the two named fallacies as *design requirements* and asks
what structure each one demands. Everything numeric below was **measured on the model**
this session (provenance in §9), not recalled.

---

## 0. The five findings that should change the plan

1. **The structure the two fallacies demand is already built, and it is not the structure
   currently under debate.** The model already refutes both, quantitatively, today. §1.

2. **The model produces the "5-year residence time" number itself — 4.69 yr — and in the
   same run shows 26 % of a mass pulse still airborne after a century.** Turnover and
   adjustment differ by **4.5× at 100 yr** in one model, one state, one parameter set.
   That is not an analogy for the fallacy; it is the fallacy, executed and dissected. §1.

3. **The conveyor / deep-Δ¹⁴C / `sigma_d13c` questions are nearly irrelevant to the
   pedagogy.** Conveyor C at 20 Sv with `kz` 2000 moves airborne-fraction-at-100-yr from
   **0.262 → 0.284** and the turnover time from **7.13 → 7.55 yr**. Choosing a 2024
   background instead of preindustrial moves the same numbers **further** (0.262 → 0.298,
   7.13 → 9.25 yr). **A feature the app already has outweighs the entire structural
   debate.** That is an argument for settling the ocean questions on scientific grounds
   alone and not letting them block the app. §2, §7.

4. **The one structural gap that does matter is the flux layer, and it is missing.**
   `ccx_run()` returns stocks and ratios only. The residence-time argument *is* an argument
   about gross fluxes — the model computes them inside `add_flux()` and discards them. The
   "Under the hood" box diagram consequently has **unlabelled arrows**. **This is the
   highest-value structural addition for the stated goal, and it is an output change, not
   a box change.** §1, §6.

5. **Two defects found while measuring.** (a) **74.1 GtC of pre-1850 land-use emissions are
   invented by an undeclared `rule = 2` back-fill** — 23 % of the LUC the model actually
   burns — where GCB supplies `NA`. GMST's identical flat-hold carries a loud warning; this
   one is silent. (b) The app's box diagram says "Vegetation / Soil" against a model that
   has had **four** land pools since 2026-08-12. §4, §6.

---

## 1. THE CARBON-CYCLE EXPERT — the new lens, and the one Marcus actually asked for

The other six lenses ask whether a component is *right*. This one asks whether the model,
as an integrated budget, **can be made to say the true thing about the two named fallacies**
— and it is the only lens that scores the model against its purpose rather than against a
dataset.

### 1a. "CO₂ has a 5-year residence time"

The fallacy is a conflation of two quantities that are both real, both correct, and differ
by an order of magnitude:

- **turnover time** τ_turn = M_atm / (gross flux *out* of the atmosphere) — how long an
  average CO₂ *molecule* stays airborne before being swapped into a leaf or the sea surface;
- **adjustment time** — how long a *perturbation to the amount* takes to relax, which is set
  by where the carbon can finally go, not by how fast it is being swapped.

**The model already separates them exactly, and needs nothing new to do it.** Because it
carries ¹⁴C as its own tracer, a pure **isotopic label** perturbation and a pure **mass**
perturbation can be launched from the identical state with identical parameters:

| yr after pulse | mass pulse (100 GtC) still airborne | ¹⁴C label anomaly remaining |
|---|---|---|
| 1 | 0.893 | 0.811 |
| 5 | 0.710 | 0.453 |
| 10 | 0.604 | 0.292 |
| 20 | 0.484 | 0.171 |
| 50 | 0.337 | 0.092 |
| 100 | **0.262** | **0.058** |
| 300 | 0.171 | 0.029 |

- **Turnover time = 4.69 yr at 1750, 5.32 by 2024** (M_atm ÷ gross outflux, read off the
  flux trace added under R1). The model *hands you the sceptic's own number*, correctly, as
  a property of gross exchange — and shows it is not even a constant.
  *(An earlier draft of this note said 4.32 yr, from a one-month label slope. That estimator
  is contaminated by the January seasonal drawdown, which is excluded from the gross outflux
  because it integrates to zero annually. With seasonality off the two routes agree to 0.2 %
  — 4.700 vs 4.692 — which is now a test, `test-fluxes.R`.)*
- **Label 1/e = 7.1 yr; mass 1/e = 40.3 yr; at 100 yr the ratio is 4.5×** and still widening.
- The label curve is not a fitted convenience — it is the same gross air–sea and gross
  GPP/respiration loops that `add_flux()` already emits *because the isotopes forced it to*
  (`model.R:278`: representing only net fluxes made the preindustrial isotope operator
  singular). **The architecture that made the isotopes work is the architecture that
  refutes the residence-time argument. That is not a coincidence to leave unstated.**

**What is required structurally, therefore: gross fluxes, a mass tracer and an isotopic
label tracer, and a reservoir the perturbation cannot escape into on the pulse timescale
(a buffered ocean).** The model has all three. **Requirement met — with one gap.** The
model cannot currently *display* the gross fluxes (§1c).

**The real-world clincher the model also already owns.** Bomb ¹⁴C is this experiment run by
history: the spike decays with an e-folding of ~15 yr while CO₂ has gone up monotonically
for 65 years. The model is *calibrated to both series simultaneously*. **An app panel that
overlays the observed bomb-¹⁴C decay and the observed Keeling curve, from one model run,
settles the argument with measurements rather than with a model claim.** This is the single
highest-value pedagogical figure available and it needs no new physics.

### 1b. "CO₂ concentrations correlate with temperature"

Two distinct claims hide inside this, and **they need opposite answers** — which is exactly
why the argument survives.

**Claim A: interannual CO₂ growth correlates with temperature.** *This is true, and the
model must reproduce it.* Measured on the historical run, 1960–2023:

| statistic | model |
|---|---|
| cor(CO₂ **growth rate**, GMST) | **+0.930** |
| cor(CO₂ **level**, GMST) | +0.962 |
| cor(detrended growth, detrended GMST) | +0.582 |
| regression slope | +1.55 ppm/yr per K |

**The model reproduces the sceptic's headline statistic at r = 0.93 while 100 % of its
trend is emissions-driven.** That is the demonstration: co-trending manufactures r = 0.93;
strip the trends and the genuine, physical, ENSO-mediated link is r = 0.58 and it explains
year-to-year *wobbles*, not the rise. The model has the ENSO term (`gamma_enso`) precisely
so the true part of the claim is present and not strawmanned.

**Claim B: the rise itself is temperature-driven.** *This is false, and the model bounds it.*
Holding +1 K with **zero emissions**:

| horizon | ΔCO₂ |
|---|---|
| 10 yr | +5.19 ppm |
| 100 yr | +8.17 ppm |
| 300 yr | +10.74 ppm |

**≈10.7 ppm per K at equilibrium.** Against the model's own 1959→2023 warming of 1.20 K,
that is **12.9 ppm of the 102.5 ppm rise — 13 %.** The temperature effect is real, is in
the model, is the right sign, and is **an order of magnitude too small**. That is a far
stronger rhetorical position than denying it.

**And the isotopes decide it, by sign.** Splitting the +1 K response into its two limbs
(300 yr, zero emissions):

| limb | ΔCO₂ | Δδ¹³C |
|---|---|---|
| solubility only (ocean outgassing) | +4.43 ppm | **+0.0354 ‰ — RISES** |
| respiration only (land release) | +6.24 ppm | −0.0760 ‰ |
| both | +10.74 ppm | −0.0410 ‰ |
| **observed/model, 1959–2023** | **+102.5 ppm** | **−1.773 ‰** |

**"The warm ocean is outgassing it" predicts δ¹³C going UP.** Ocean DIC sits near +1.5 ‰
against an atmosphere near −8 ‰, so ocean carbon is *enriched* — outgassing it raises
atmospheric δ¹³C, and the model confirms the sign. The observed δ¹³C **falls by 1.77 ‰**.
Even the land limb, which does have the right sign, is **43× too small**.

**And the ocean is measurably a net sink, not a source**: model cumulative 1750–2024
**ocean +172.6 GtC**, uptake **2.60 GtC/yr** over 2015–2024. A reservoir gaining carbon is
not the reservoir supplying the atmosphere. *(2.60 vs GCB's 3.22 GtC/yr — the model runs
low at `ccx_default_params()`; see §9.)*

**Structurally required: temperature-dependent solubility, temperature-dependent
respiration, an ENSO term, δ¹³C, and a closed budget that reports the ocean's sign.**
All present. **Requirement met.**

### 1c. What the carbon-cycle expert says is MISSING

**The gross fluxes are computed and thrown away.** `ccx_run()` (`forcing.R:325`) emits
stocks, ratios and two ¹⁴C inventories. It emits **no flux**. Consequences:

- **The central pedagogical quantity is uncomputable from model output.** τ_turn = M_atm /
  F_gross_out is *the* number in the residence-time argument. Above I had to recover it
  *indirectly*, from the decay slope of a label pulse. That works — it is arguably the more
  honest derivation — but no user or student can do it, and neither can the app.
- **The box diagram cannot be honest.** `app/server.R:213` draws six arrows with **no
  numbers on them**. The whole point of the diagram for this audience is that the arrows
  (~120 GtC/yr photosynthesis, ~80 GtC/yr each way air–sea) are **enormous** next to the
  ~11 GtC/yr of emissions and the ~5 GtC/yr net imbalance. **An unlabelled arrow teaches
  nothing; a labelled one teaches the entire fallacy in one glance.**
- **Diagnosis loses its cheapest instrument.** Several sessions' worth of ocean work has
  been inferred from stocks. A flux trace would have made §2c of handoff 13c visible
  immediately.

**Recommendation R1 (highest value, low cost): emit an optional flux trace.** A
`fluxes = TRUE` argument to `ccx_run()` returning the gross and net fluxes `add_flux()`
already computes. It changes no physics, breaks no result, and the recorded fluxes must sum
to the stock changes — a *free additional check on the model core.*
**BUILT 2026-08-13d** (`R/fluxes.R`, `tests/testthat/test-fluxes.R`, 20 assertions): the
recorder is a tap inside `add_flux`/`add_source`/`add_diffusion`, edges are classified by
reservoir type so future fluxes are captured automatically, and `boxnet == dy[, "C"]`
exactly. `ccx_run_fast()` (the C++ core the sampler calls) is deliberately untouched.

---

## 2. THE OCEAN EXPERT

**The pedagogical requirement on the ocean is Revelle buffering, and it is the one piece of
ocean physics that must be right.** It is *why* the adjustment time is not the turnover
time: the surface swaps carbon fast, but seawater chemistry means the mixed layer can only
*hold* ~1/10th of what its DIC-vs-pCO₂ slope would naively allow, and the interior is
reached slowly. The model has this as an **emergent, state-dependent** quantity
(`carbonate.R:134`, DESIGN §3.4) rather than an imposed constant, and there is already a
`revelle` counterfactual switch. **This is the correct and non-negotiable design and it is
in place.**

**Now the finding that should reframe the current debate.** The structural question
consuming the project — conveyor on/off, `kz`, the deep-Δ¹⁴C target — was measured against
the pedagogical outputs:

| configuration | AF@20 | AF@50 | AF@100 | AF@300 | label 1/e |
|---|---|---|---|---|---|
| preindustrial, no conveyor, `kz` 5000 | 0.484 | 0.337 | **0.262** | 0.171 | 7.13 yr |
| preindustrial, conveyor C 20 Sv, `kz` 2000 | 0.526 | 0.370 | **0.284** | 0.177 | 7.55 yr |
| **2024 background**, no conveyor | 0.568 | 0.396 | **0.298** | 0.191 | 9.25 yr |

**The entire ocean-structure question is worth 2.2 percentage points of airborne fraction
at 100 yr. Changing the background scenario — a control the app already exposes — is worth
3.6.** Both are dwarfed by the 4.5× turnover-vs-adjustment contrast that is the actual
lesson.

**The ocean expert's verdict: decide the conveyor on oceanography, not on the app.** It is
justified or not by `kz` = 5000 being ~9× Ledwell's NATRE value and by the bipolar deep
ocean (handoff 13c §4) — genuine, and unaffected by anything here. But **it is not on the
critical path to the stated goal, and the three open decisions should stop being treated as
though the app waits on them.** They don't.

**One thing the ocean lens does want, and it is pedagogical:** the background-dependence in
that table is itself a lesson — *the same pulse lasts longer in a more polluted world,
because the ocean is already fuller.* DESIGN §7 tab 5 promises exactly this ("how the answer
*depends on the background* (Revelle saturation)"). **It is measured, it is 3.6 points, and
it is the strongest single argument for keeping Revelle emergent.** Ship it.

---

## 3. THE ATMOSPHERE EXPERT

**Two hemispheric boxes are the right call and should be defended, not apologised for.**
The interhemispheric gradient is doing real pedagogical work that a global box cannot:
the NH−SH CO₂ difference **grows from ~0.5 to ~4 ppm tracking cumulative NH fossil
emissions** (DESIGN §6 gate 9), and the bomb spike arrives in the SH **1.33 yr late and
~190 ‰ smaller** (gate 5). Together these say *the extra carbon is entering in the north,
where the emissions are* — a spatial fingerprint of attribution that the isotopes then
confirm chemically. **Two boxes buy an entire independent argument for one parameter
(`tau_ex`). Nothing else in the model has that ratio.**

**The atmosphere lens' warning about Claim A (§1b).** The r = +0.93 result is a *rhetorical
hand grenade* and must be presented with care. Left unframed it reads as confirmation of
the sceptic's point. The framing that works is sequential and the app must enforce the
order: *(1) here is the correlation, it is real, r = 0.93. (2) here is the same correlation
after removing both trends: r = 0.58, and it is ENSO. (3) here is the model with
temperature's effect on the carbon cycle switched off entirely — the trend barely moves.
(4) here is the model with emissions switched off — the trend disappears.* **Steps 3 and 4
are one existing toggle (`warming_feedback`) and one trivial new one.**

**Recommendation R2: add a "no emissions" counterfactual to `CCX_MECHANISMS`.** It is the
single most-requested counterfactual in this entire argument, it is two lines, and its
absence is conspicuous — the switch list currently lets a user turn off every *sink* but
not the *source*. **BUILT 2026-08-13d**, and it lands the lesson in two numbers: over
1750–2024, emissions off gives **−134 ppm** (back to 285, essentially preindustrial) while
the warming feedback off gives **−10 ppm**. Pinned by a test.

**A caveat the atmosphere lens insists on.** The +1 K experiment (§1b) holds temperature
fixed *by fiat* with emissions at zero — it is a sensitivity, not a history. The honest
statement is "the model's equilibrium CO₂ response to warming alone is ~10.7 ppm/K, so
1.2 K of observed warming can account for ~13 % of the observed rise," **not** "temperature
caused 13 % of the rise" (attribution requires the coupled run). The app must use the first
phrasing. Note also that `ccx_run_coupled()` (`climate.R`) can close CO₂→forcing→T→carbon,
which makes a *genuinely* two-way panel possible — **and that panel is the real answer to
"which causes which": both, and the model shows the loop.**

---

## 4. THE ECOSYSTEM / LAND EXPERT

**The four-pool land structure is now carrying more pedagogical weight than its origin
suggests.** It was built to fix the ¹⁴C bomb partition (memory `project_ccx_four_pool_land`,
biosphere +51 % → +0 % @1975). But turnover-vs-adjustment on land is *the same lesson as
§1a in a second medium*: leaf carbon turns over in ~1 yr, soil_slow in ~500 yr, and the
land's ability to hold a perturbation is set by the slow pools while its gross flux is set
by the fast ones. **A student who sees the point twice, in two independent subsystems, has
learned a principle rather than an ocean fact.** Keep four pools; the two-pool DESIGN §3.3
text is stale and should be updated.

**The land is where the temperature-driven CO₂ release actually comes from** — measured, the
+1 K run's source is **land −22.8 GtC** at 300 yr, with the ocean's solubility outgassing
and buffered re-uptake **very nearly cancelling** (−0.04 GtC net). *That near-zero is a
coincidence at 300 yr, not a structural identity* — I checked: solubility-only puts the
ocean at −23.50 GtC and respiration-only at +23.50 GtC, and at 100 yr they are −15.1 vs +9.5,
i.e. not equal. **Flagged explicitly because a −0.04 net with two ±23 limbs is precisely the
suspicious-uniformity pattern the standing discipline says to distrust; it was tested and it
is a crossing, not a bug.**

### The defect

**74.1 GtC of pre-1850 land-use emissions are invented, silently.** GCB's LUC series is
`NA` for **1750–1849** (100 years). `ccx_annual_to_monthly()` strips NAs and then
`approx(..., rule = 2)` holds the 1850 value flat backwards, producing **74.1 GtC** of
emissions in a century where the data say nothing. Cumulative LUC in the forcing is
**321.6 GtC against 247.5 GtC in the source table — 23 % of what the model burns is
extrapolation.**

This is **not** a conservation error (LUC is a veg→atmosphere transfer, not an external
source — `project_ccx_luc_c14_leak`), and a nonzero pre-1850 LUC flux is defensible on the
physical merits. **The objection is that nobody chose it.** Compare the treatment of the
two neighbouring cases in the same file: GMST's flat-hold raises a **warning on every
build** (`forcing.R:232`), and `d13c_foss`'s back-fill carries an explicit justifying
comment. LUC gets neither. It sets the 1750–1850 land trajectory, the ice-core CO₂ fit over
that century, and — because LUC carries biospheric δ¹³C — part of the preindustrial isotope
budget.

**Recommendation R3: make the pre-1850 LUC choice explicit** — either cite a source for the
extrapolation, or zero it, or ramp it, but *state it and log it*, and warn like GMST does.
**Do not let a `rule = 2` be the author of 74 GtC.**

---

## 5. THE ISOTOPE EXPERT

**Carrying all three isotopes is the decision that makes this project worth doing, and both
of Marcus' fallacies die on isotopes rather than on CO₂.** Stated plainly, because it should
be the app's spine:

| the claim | the isotope that kills it | the sign |
|---|---|---|
| "CO₂ only lasts 5 years" | ¹⁴C label vs mass pulse (§1a) | 4.5× apart at 100 yr |
| "it's natural, the ocean is outgassing" | δ¹³C | outgassing → **UP** (+0.035 ‰); observed **DOWN** (−1.77 ‰) |
| "it's volcanoes / it's not fossil" | δ¹³C **and** ¹⁴C-free fossil carbon → Suess dilution | both fall; only old organic carbon does that |
| "the rise is temperature-driven" | magnitude of the δ¹³C signal | 43× too small |

**The isotope lens' structural verdict: nothing needs to be added.** Every fallacy above is
already scored by a data stream in the likelihood. **This is the strongest evidence that the
model is at the right complexity** — the pedagogical requirements and the calibration
requirements turn out to want *the same* structure, which almost never happens and should be
recorded as a design win rather than assumed.

**Where the isotope expert does push back on the app.** The Δ¹⁴C panel currently shows the
bomb spike as a *fingerprint* story. **Its most important job is the residence-time story
(§1a), and that framing is absent.** Same data, same panel, one added curve (the mass pulse
on the same axes) and a different caption. **Highest pedagogical return per line of code in
the whole app.**

**One honesty constraint.** The Suess/bomb panels rest on the model's atmospheric δ¹³C
decline being **+21–25 % too fast** (handoff 13c §3) — an open, unexplained misfit. The app
must not present the δ¹³C trace as a clean match. Either plot obs and model together and
say the model over-declines, or plot the *observations* for the argument and use the model
only for the counterfactuals. **The second is better teaching and better honesty: the
sceptic's claim is refuted by measurements, and the model's job is to explain why.**

---

## 6. THE PEDAGOGICAL EXPERT

**The app's six tabs do not currently contain the two arguments Marcus built the project
for.** Tabs 1–6 (DESIGN §7) cover the Keeling curve, partitioning, counterfactuals, isotope
fingerprints, futures, and internals. **There is no residence-time panel and no
correlation-vs-causation panel.** The material is all present; the *argument* is not
assembled anywhere. A student can leave having seen every ingredient and having met neither
fallacy.

**Recommendation R4 — one new tab, "How long does it last?", and it is the tab this whole
project is for.** Three panels, all from measurements and one model run:

1. **The two curves** (§1a table), on one axis, one sentence: *"Both are true. They answer
   different questions."* Add the ~4.3 yr readout with the label **"turnover time — the
   number people quote"**, next to **"adjustment time — the number that matters for
   climate."**
2. **The observed bomb spike next to the observed Keeling curve.** Measurements, not model:
   the ¹⁴C label went away; the CO₂ did not. **This is the argument, and it happened.**
3. **The background slider** (§2 table): the same pulse lasts longer in a fuller ocean.

**Recommendation R5 — a second tab, "Does temperature cause CO₂?"**, running §1b's sequence
in the enforced order: show r = 0.93 → detrend to r = 0.58 → attribute the wobbles to ENSO →
switch off the warming feedback and watch the trend not move → switch off emissions and
watch it vanish → and close on δ¹³C's **sign**. **Ending on the isotope sign matters:** it
converts the lesson from "the model says so" to "the carbon has a label on it, and the label
says fossil."

**What the pedagogical lens will not accept.** A "complexity necessary to match reality but
not too much more" model must be **fully inspectable**, and unlabelled arrows on the box
diagram (§1c) fail that. So does the diagram's **"Vegetation / Soil"** caption against a
four-pool land model (`model.R:80`) — a labels-vs-structure drift of exactly the class the
standing rule exists to prevent. **R6: fix the diagram's labels and put numbers on its
arrows** (blocked on R1). **DONE 2026-08-13d** — every arrow now carries its flux from
`APP_FLUX_NOW`, and the land boxes read "Vegetation (leaves + wood)" / "Soil (fast + slow)".
The diagram's closing line is now the lesson itself: *photosynthesis and the sea move
167 GtC a year in and out of the air, so an average CO₂ molecule stays only ~5.3 years — the
added carbon still takes centuries to go.*

**On complexity, the lens' actual verdict.** The audience test is not "how many boxes" but
**"how many sentences to explain a mechanism a student must believe."** By that test: gross
fluxes = 1 sentence and buy the whole residence-time argument. Revelle = 1 sentence, buys
the adjustment time. Two hemispheres = 1 sentence, buys attribution. Four land pools = 1
sentence ("some carbon is in leaves, some is in soil that takes centuries"), buys the land
half of the turnover lesson. **A conveyor = 1 sentence and buys nothing the student will
see** (§2). *That is the complexity ranking, and it is not the same as the scientific one.*

---

## 7. THE REDUCED-COMPLEXITY EXPERT

**The honest summary is that this model is already at the right complexity for its purpose,
and the risk now is drift upward.** Every structural addition of the last week has been
motivated by an ocean-interior misfit — `kz`, the conveyor, deep Δ¹⁴C, `sigma_d13c`. §2
measures what all of that is worth to the stated goal: **2.2 points of airborne fraction at
100 yr.** Meanwhile the highest-value remaining items are an **output argument** (R1), a
**two-line switch** (R2), a **provenance fix** (R3), and **two tabs of existing material**
(R4, R5). **None of them adds a box or a parameter.**

**The parameter-count argument, restated for this goal.** The conveyor's cost was priced in
`redteam_2026-08-13` §4 as *one parameter added and one constraint removed*. Against the
pedagogical spec the price is different and higher: **it also adds a mechanism the app must
either explain or hide.** Explaining it is one sentence (§4 of that red team is right that
"one Q is not HILDA"). **Hiding it is worse than not having it** — an inspectable model with
an unexplained knob is no longer inspectable.

**The reduced-complexity lens' recommendation on the three blocked decisions: unblock them
by decoupling them.** They are being treated as prerequisites to a refit that is a
prerequisite to the app. **The measurements in §2 sever that chain.** Concretely: build the
app on the current structure and the current mode, ship it with the honest caveat list it
already has (`ui.R:279` — *"No ocean circulation — the deep ocean is reached by diffusion
only, which is a real simplification"* — which is **already an admirably honest statement of
exactly the open question**), and let the conveyor refit land when the science settles. **If
the refit changes AF@100 by 2 points, no panel in the app changes its story.**

**One genuine risk this lens will flag.** *All numbers in this note are at
`ccx_default_params()`, not the posterior mode* (§9). The mode has `h_ml` = 179 m (88 % up
its bound) and `kz` = 6031, both of which push toward *more* ocean uptake and a *shorter*
adjustment time. **The pedagogical curves should be recomputed at the mode before anything
ships**, and if AF@100 at the mode drops much below 0.26 that is worth knowing — see R7.

**Recommendation R7 — add the Joos et al. (2013) CO₂ IRF as a DESIGN §6 sanity gate.** The
model's AF@100 on a 2024 background is **0.298**. My recollection of the multi-model mean
IRF at 100 yr for a 100 GtC present-day pulse is ~0.4, which would make this model's pulse
decay **too fast** — but **that is a recollection and I have not checked it against the
paper, so it is stated here as a test to run, not as a finding.** It matters because it
biases the headline pedagogical number in the direction that *understates* Marcus' own
argument, and because DESIGN §6's eleven gates score sinks, seasonality, the bomb curve and
the gradient — **but nothing scores the pulse response, which is the quantity the app's
flagship tab reports.** That is a real hole in the gate list independent of which number
turns out to be right.

---

## 8. VERDICT — the structure, item by item

| component | keep? | why, against the stated goal |
|---|---|---|
| gross fluxes at every interface | **essential** | *is* the residence-time argument; also what made isotopes work |
| ¹²C + ¹³C + ¹⁴C | **essential** | both fallacies die on isotopes, not on CO₂ |
| emergent Revelle / carbonate chemistry | **essential** | why adjustment ≫ turnover |
| two hemispheres | **keep** | 1 parameter, buys the attribution fingerprint + bomb lag |
| four land pools | **keep** | the turnover/adjustment lesson, repeated in a second medium |
| box-diffusion ocean column | **keep** | sufficient; the interior is invisible to every pedagogical output |
| ENSO term | **keep** | makes the *true half* of the temperature claim present |
| coupled climate module | **keep** | the only way to show the loop runs both ways |
| **flux output layer** | **ADD (R1)** | the one structural gap; makes the argument inspectable |
| **"no emissions" switch** | **ADD (R2)** | conspicuously absent from the switch list |
| conveyor / advective overturning | **not needed here** | 2.2 pp at 100 yr; decide on oceanography |
| second surface box (HILDA-lite) | **no** | red team §5 config E; more parameters, less story |
| two overturning cells (D) | **no** | as above, doubled |

**Blocking decisions for Marcus, in priority order for the stated goal:**

1. ~~**R1 (flux output)**~~ — **approved by Marcus 2026-08-13 and BUILT.**
2. ~~**R4 + R5 (the two missing tabs)**~~ — **approved 2026-08-13 and SPECCED**, with
   Marcus' steer: *concentrate on the positive learning, not the debunking.* So they are
   **"How long does it last?"** and **"What drives CO₂?"** (DESIGN §7 tabs 5–6), and the
   fallacious arguments are a short **signposting appendix inside "Under the hood"**
   (§7a) rather than a tab of their own — published claim → published response → which
   panel bears on it. DESIGN §1 has gained the fifth goal. **Implementation of the tabs
   themselves is not done.**
3. ~~**R3 (pre-1850 LUC)**~~ — **RESOLVED 2026-08-13d.** OSCAR v3.1 (Gasser et al. 2020,
   doi:10.5194/bg-17-4075-2020) rescaled to GCB's level over an 1850–1900 overlap:
   **41.8 GtC replaces the 74.1 the flat-hold invented.** Scored against Law Dome
   (RMSE 2.00 vs 2.48 for the flat-hold, 4.50 for zero — **zero is excluded by the data**).
   Two things fell out: a **~6.5 ppm 1900 deficit shared by every option**, untouched by
   this choice; and **`mode_fit.rds` is now stale**, since the historical forcing changed.
4. ~~**R7 — should the pulse IRF become a gate?**~~ — **YES, and it is now DESIGN §6 gate
   12.** Marcus supplied the paper. **My recollection of "~0.4 at year 100" was right about
   Joos (0.409) but the conclusion drawn from it was too strong.** Point IRF: the model is
   below the multi-model mean at every horizon (0.313 at 100 yr). But the **time-integrated**
   IRF — the quantity Joos actually puts ranges on — is **inside the 5–95 % range at 20, 50
   and 100 yr** (12.6 / 26.2 / 43.6 against 12.2–16.3 / 24.0–36.6 / 39.5–65.2). *The model
   is on the low side of the literature but within it* — the conservative direction for the
   app's argument. It also reproduces Joos's PI < PD ordering, and on coupled SSP
   backgrounds IRF@100 rises monotonically 0.342 → 0.512.
5. **The three ocean decisions (`sigma_d13c`, deep-Δ¹⁴C target, conveyor) — unchanged and
   still open.** This panel takes no position on them beyond §2's measurement that **they
   are not blocking the app**, and endorses handoff 13c §0.1: **do not block σ on the
   conveyor.**

---

## 9. Provenance of every number in this note

All measured this session against branch `luc-veg-debit` at `4c10d93`, reproduced end to end by
**`calibration/diag_pedagogy.R`** (~3 s), which carries these results in its header.

- **Parameters: `ccx_default_params()`, NOT the posterior mode.** The mode differs
  materially (`h_ml` 179 m vs 75, `kz` 6031 vs 5000) and every curve here should be
  recomputed at the mode before shipping (§7).
- **Pulse experiments** are paired perturbation-minus-control from the identical 1750
  spinup, zero emissions, zero bomb, zero ENSO, GMST held at 0, per standing paired-pulse
  discipline. Control drift over 300 yr: **−0.641 ppm CO₂, −0.001 ‰ Δ¹⁴C** — small, but
  **non-zero and subtracted, not ignored**.
- **Mass pulse** = 100 GtC added to the atmosphere *at the atmosphere's own isotopic ratios*,
  so it is a mass perturbation and not simultaneously a label perturbation.
- **Label pulse** = atmospheric ¹⁴C × 1.10, no mass change.
- **Turnover time 4.69 yr (1750) / 5.32 yr (2024)** is M_atm ÷ (photosynthesis + air-to-sea
  invasion), from the flux trace, which is the definition. The one-month label slope reads
  4.32 yr and is *not* a clean estimator of it — see §1a.
- **Historical run** 1750–2024 with full forcing; correlations on annual means 1960–2023
  against IGCC GMST; "detrended" = residuals of a cubic in year, both series.
- **Conveyor row** = Config C (`conv_sink` 8, `conv_descent` 0), `q_conv` 20 Sv, `kz` 2000 —
  the cell handoff 13c §4 calls "the interesting one".
- **Budget closure check:** atm +302.2, ocean +172.6, land +29.0 = **503.8 GtC** against
  cumulative fossil **504.7 GtC** (LUC is a veg→atm transfer, not an external source, so it
  correctly does not appear). Closes to **0.17 %**, the residual being month-centring of the
  endpoints rather than non-conservation — the suite's conservation test is the authority.
- **Ocean uptake 2.60 GtC/yr (2015–2024)** against GCB's 3.22 — the model runs ~19 % low
  **at default parameters**; this is a known consequence of not using the mode and is not a
  new finding.
