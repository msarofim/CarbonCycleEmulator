# Handoff — CarbonCycleEmulator, 2026-09-03
# **THE MODEL IS PEDAGOGICAL, NOT AN EMULATOR — AND THAT REORDERS EVERY PRIORITY.**
# **MISSING JOOS IS NOT A DEALBREAKER. MATCHING OBSERVABLES BY CANCELLATION IS.**
# **NEXT ARC: THREE MECHANISM FIXES THAT MAY BE ONE EXPERIMENT.**

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`.
⚠ **Sessions launch from `FaIRtoFrEDI/`; ALL of this is in `CarbonCycleEmulator/`.** Use `git -C <abspath>`.

**Read before this one:** `handoff_2026-09-02l_ruling_a_shipped_and_a_finding_that_died.md` (Ruling A
shipped, the v6 grid, the refit launch) and its §9 addendum.

---

## 0. THE REFRAME, IN MARCUS'S WORDS (2026-09-03)

> "This is a pedagogical model, not an emulator. Missing Joos is not a dealbreaker (though it would
> be good to have a hypothesis about why we are underestimating the perturbation lifetime). On the
> other hand, for a pedagogical model, having non-physical ENSO and seasonal behavior is
> problematic. We are trying to show how in order to match observed seasonal and isotopic variables
> certain behaviors (like long perturbation lifetimes) are emergent."

⛔ **I HAD RANKED THE PRIORITIES BACKWARDS.** I called the Joos miss the headline dealbreaker and
the seasonal/ENSO defects documentable scope limits. For the model's actual purpose that is exactly
inverted, and the rest of this handoff is written on the corrected framing.

---

## 1. ⭐ THE UNIFYING DIAGNOSIS: THE MODEL MATCHES ITS OBSERVABLES BY CANCELLATION

In **all three** places the model reproduces an observable by cancelling two wrong things rather
than by getting the mechanism right:

| observable | matched? | by what |
|---|---|---|
| SPO seasonal CO₂ amplitude | to ~1 % | land **2.55×** obs against ocean **0.45×** obs, ~5 months apart |
| ENSO carbon-cycle response | yes, fitted | a **wrong-signed** solubility response + a fitted `gamma_enso_ocn_*` that cancels it (errors compensate **87 %**) |
| contemporary sinks (gate 7) | z +0.61 / −0.34 | fine — but on drivers the two rows above show are wrong |

⭐ **AND THE EMERGENT-LIFETIME CLAIM RESTS ON THOSE SAME DRIVERS.** The pedagogical argument is
"constrain the model with seasonal and isotopic data ⇒ a long perturbation lifetime emerges". If the
seasonal and isotopic rows are matched by cancellation, **the emergence being demonstrated is a fit
artifact, not a result.** That, not the Joos gap, is what blocks going public.

⚠ This is already half-recorded as [[seas_right_observable_wrong_drivers]] ("the CO₂ seasonal rows
have NO POWER — they are already matched"). What is new here is that it applies to **ENSO too**, and
that it is the *pedagogical* failure rather than a fitting inconvenience.

---

## 2. ⭐⭐ FIX A — THE SEASONAL OCEAN LIMB IS IN THE WRONG SEASON, AND THE RIGHT MECHANISM IS
##    IMPLEMENTED AND SWITCHED OFF

**THE EVIDENCE LINES UP IN ONE TABLE** (all measured 2026-09-03 at the refit winner):

| | peak month | miss vs observed 8.52 [7.82, 9.20] |
|---|---|---|
| **observed** SPO ocean limb | **8.52** | — |
| model's **ACTIVE** SH ocean limb (`sst_seas_amp_SH`, solubility) | **3.35** | **5.17 months** |
| model's **DISABLED** entrainment limb (`CCX_ENT_SEAS_PEAK_MO`) | **7.50** | **1.02 months** |

⭐ **AND THE MODEL'S WORST PRIOR VIOLATION IS THE SOLUBILITY AMPLITUDE**: `sst_seas_amp_SH` = 0.4832
at **prior-z −5.14**, with `sst_seas_amp_NH` −3.56 behind it. ⇒ **THE HYPOTHESIS: the fit is
straining solubility 5σ against its prior to do ENTRAINMENT's job, and still lands in the wrong
season — so it cannot, and the land has to be 2.55× to make up the amplitude.**
**One missing mechanism explains the worst prior violation, the seasonal partition error, and the
land limb's excess at once.**

⛔ `ent_seas_amp_SH` is **implemented, defaulted to 0, and NOT in the 25-parameter fitted set**
(verified in `R/cpp.R:167` + `CCX_PARAM_NAMES`, not recalled). Classic
[[default_off_hides_the_bug]]. `tau_ex_seas_amp` is in the same state.

**THE TEST (pre-register these before running):**
1. Free `ent_seas_amp_SH` (25 → 26 params) and refit. ⚠ **Ship the structural change BEFORE the
   refit** — that ordering has cost 14 h once already.
2. **P1** the SH ocean limb amplitude goes 0.45× → toward 1×, and its phase 3.35 → toward 8.5.
3. ⭐ **P2, THE LOAD-BEARING ONE:** `sst_seas_amp_SH`'s prior-z **relaxes from −5.14**. If the
   mechanism is genuinely missing, adding it should release the strain. If the z does NOT move, the
   hypothesis is wrong and solubility was never doing entrainment's job.
4. **P3** `npp_frac_NH` relaxes back inside its bounds (the seasonal fix currently needs ≈0.81,
   which is OUTSIDE them ⇒ [[sh_land_undercancels]]) and the SPO land limb falls from 2.55×.
5. **P4** the cancellation fraction FALLS. ⚠ Bound it against
   [[gross_phase_not_amplitude]]'s geometry floor (0.454 × gross ⇒ max 54.5 % vs CT2022's 74.9 %),
   not against a number chosen after seeing the result.
⚠ **A gate is owed on the OCEAN LIMB PHASE.** Nothing currently scores it — which is how a 5.17-month
error survived. The target and its CI are already registered as `SPO_SEAS_OCEAN_PHASE_INV` and its
`_LO`/`_HI` bounds (2026-09-02), so the gate has a target it did not produce itself.

---

## 3. ⭐ FIX B — THE ENSO OCEAN SIGN ERROR IS A MISSING *SOURCE*, NOT A MISSING RATE

**THE PHYSICS, stated plainly because the pedagogy depends on it.** The model's ONLY ENSO→ocean
pathway is **SST → solubility**: El Niño warms the surface, solubility falls, the ocean **outgasses**,
uptake DECREASES. Observed: El Niño ⇒ ocean uptake **INCREASES** (+0.119 GtC/yr per °C Niño3.4,
[[enso_sink_sensitivity_target]]). Hence model r ≈ **−0.50** against the product's **+0.535** —
**amplitude right, phase wrong** ([[ccx_ocean_enso_sign_error]]).

⭐ **WHY, AND WHY THE CONVEYOR ROUTE FAILED FOR THE SAME REASON.** The real mechanism is the
suppression of **equatorial upwelling**: the equatorial Pacific is a **natural CO₂ SOURCE** because
upwelled water is supersaturated, and El Niño shuts that source down, so the ocean outgasses less.
**The model has no tropical box and no natural-carbon disequilibrium in upwelled water — it has no
source to suppress.** Its ocean is essentially an anthropogenic-perturbation absorber, so *more*
overturning gives *more* uptake (+0.0101 GtC/yr per Sv) and the conveyor lever comes out
wrong-signed ([[ccx_conveyor_not_the_enso_fix]]). ⇒ **That refutation is not a dead end; it is
evidence for this diagnosis.**

⛔ **WHAT THE MODEL CURRENTLY DOES INSTEAD IS THE PEDAGOGICAL PROBLEM.** The four fitted
`gamma_enso_*` (ocean pair **+0.2551 / +0.1031** at the refit winner) add a positive response on top
of a wrong-signed physical one. **A student reading this model would conclude that ENSO reaches the
ocean through solubility, which is backwards.**

**THE DECISIVE PRE-TEST, AND IT IS CHEAP.** Distinguish "wrong RATE" from "missing DISEQUILIBRIUM"
before building anything: **measure the model's surface-ocean pCO₂ disequilibrium against the
observed climatology.** If the model's surface sits near equilibrium where the real tropics run
~+60 μatm supersaturated, **no modulation of an exchange RATE can produce the observed sign** and a
source term is forced. ⭐ The climatology is **already on disk** —
`data-raw/download_data.R` §6c, pulled 2026-08-27e for the seasonal phase question.
⚠ It is a **pCO₂** product, not a flux product: it omits the seasonality of gas transfer and K0.
Say so when using it.

**THEN, in increasing cost:**
- **B1** a prescribed natural-CO₂ outgassing flux with an ENSO-modulated magnitude, anchored on the
  observed equatorial Pacific source (~0.5 GtC/yr). One parameter, pedagogically legible, and it
  gives the model a source to suppress.
- **B2** an explicit tropical surface box. Structural, and the honest fix if B1 cannot carry the
  isotopes as well as the CO₂.
⚠ **Whatever lands, the four `gamma_enso` coefficients must be RE-PRICED afterwards.** If the
mechanism is right they should SHRINK; if they do not, the term is still papering over something.
**That is the acceptance test, and it should be pre-registered.**

---

## 4. FIX C — A HYPOTHESIS FOR THE SHORT PERTURBATION LIFETIME (Marcus asked for one)

**MEASURED 2026-09-03 at the refit winner, through the project's own Joos protocol driver**
(`diag_joos_irf.R` accepts a path to a result file):

| | model | Joos T5 |
|---|---|---|
| IRF(20) | 0.483 | 0.596 |
| IRF(100) | **0.276** | 0.409 |
| IRF(300) | **0.196** | 0.322 |
| ∫IRF to 100 yr | **39.23 yr** | 52.4 (5–95 %: **39.5**–65.2) |
| tail ratio IRF(300)/IRF(100) | **0.710** | 0.787 — **inside** the band |

⇒ The **SHAPE** of the decay is right; the **LEVEL** is not, at every horizon, and the model sits
**below Joos's asymptote a₀ = 0.2173** at 300 yr — an EQUILIBRIUM statement.
⚠ **The refit made it marginally WORSE** (IRF(100) 0.284 → 0.276), so more fitting will not fix it.

⭐ **THE HYPOTHESIS: A PERMANENT LAND SINK.** Michaelis–Menten fertilisation at `fert_k` = 328.09 /
`beta_max` = 0.726 keeps NPP elevated indefinitely under raised CO₂ with no nutrient limit and no
turnover ceiling, so the land goes on absorbing forever. Joos's a₀ is set by ocean equilibration
against a **finite** buffer; a permanent land sink pushes airborne below it. Consistent with
[[ccx_pulse_partition_panel]]'s "**40 % of a pulse is in the LAND at 3000 and no gate scores it**".
**Rival hypothesis:** the ocean buffer is too weak or the ocean too large — `ALK_SURFACE`,
`OCEAN_DEPTH`, `OCEAN_AREA_NH/SH` are all still `provisional`.

**ONE MEASUREMENT DISTINGUISHES THEM: the pulse partition at 1000+ yr. Whichever reservoir holds the
carbon is the culprit.**
⛔ **I ATTEMPTED THIS AND THE RESULT IS VOID — DO NOT USE IT.** I pulsed at the **1750** spinup state
on a held forcing; Joos's protocol pulses at **2015** on a PD100 background. My atmospheric fractions
(0.205 at 100 yr) do not even reconcile with the diagnostic's own IRF (0.276), which is how I caught
it. Redo it on the protocol background ⇒ [[like_for_like_forcing]].
⚠ Also ruled out already, with power: **`kz` is NOT the lever** (re-optimising frontier), and the
land axis reaches only IRF(100) = 0.342 before gate 7 overshoots. **Do not write another rate study**
([[ccx_gates_priced]]).

### ⭐⭐ AND THE REASON FIX C MAY NOT BE A SEPARATE EXPERIMENT AT ALL
If the ocean is given back its missing seasonal (A) and interannual (B) mechanisms, **the fit no
longer needs the land to be 2.55× and permanently absorbing** — so **the perturbation lifetime may
lengthen as a CONSEQUENCE of fixing the seasonal and ENSO physics.** That is precisely the emergence
the model exists to demonstrate: constrain the seasonal and isotopic observables *with the right
mechanisms* and the long lifetime falls out.
⚠ **PRE-REGISTER IT AS A PREDICTION BEFORE RUNNING A, or it becomes a story told afterwards.**
Prediction: after Fix A alone, IRF(100) **rises** from 0.276. If it does not move, the three problems
are independent and C needs its own fix.

---

## 5. ⚠ NON-OBVIOUS STATE

* **Refit landed**: 46/46 tasks, ONE basin at **−1482.6144**, +61.07 on the incumbent, reached from
  the cold init ⇒ [[ccx_refit_20260902_landed]]. **NOT ADOPTED** — prior-z got worse, which §2 now
  reads as evidence for a missing mechanism rather than as a defect in the vector.
* **Gates at the refit winner, measured 09-03** (every recorded number predated it):
  **PASS** gate 7 (land +0.61 / ocean −0.34), gate Q (1.37σ), gate G (z −0.228), gate 12b (0.710).
  **FAIL** gate 4 (AF sd 0.0241 vs obs 0.0515, ratio **0.468** — *worse* than the recorded
  0.032–0.041), gate 5 NH peak (**+2.19σ**, ~1 yr late, *worse* than +2.11), gate 12 level (§4).
* ⚠ **Gate 4's failure is now the SAME STORY as §1** — the model has under half the observed decadal
  AF variability and 33 % of the interannual variability ([[ccx_variability_gap]]). A model whose
  ENSO ocean response is anti-phase **should** be short of variability. **Do not treat gate 4 as a
  separate defect until B lands.**
* **No posterior.** Hessian conditioned 1.11e6. ⭐ The refit measured the softest direction
  precisely: `h_ml` 148.33 vs 154.00 m is worth **0.094 log-units** — enough to reparameterise
  `h_ml` or profile it out and sample the other 24, which is cheaper than fixing the conditioning.
* **`CCX_MODE_CANONICAL` is STILL `from90`**, a 21-parameter ancestor. The refit adopted nothing.
* **Torch**: the refit ran under QoS **`cpu48`** (2-day wall, cpu=3000), **not `cpu_short`** — the
  "6 h / cpu=32" figure in [[torch_qos_is_the_real_cap]] is not the cap that applied.
  ⚠ 26 array elements were lost to a **cluster-wide purge of 1,751 pending jobs**, not to us.
* Analysis scripts for all of the above are committed as `calibration/diag_survey_20260902_*.R`.

---

## 6. ⇒ THE ARC, IN ORDER

1. ⭐⭐ **FIX A** — free `ent_seas_amp_SH`, with P1–P4 and the IRF prediction pre-registered, and a
   gate on the ocean limb PHASE against the already-registered `SPO_SEAS_OCEAN_PHASE_INV`.
   **Cheapest, best-evidenced, and it tests §1's whole thesis in one run.**
2. ⭐ **FIX B pre-test** — the model's tropical surface pCO₂ disequilibrium against the climatology
   already on disk. Cheap, and it decides between a rate fix and a source term before anything is built.
3. **FIX C measurement** — the pulse partition at 1000+ yr **on the Joos PD100 background**. Redo;
   my 09-03 attempt is void.
4. **THEN** re-price the four `gamma_enso` coefficients and re-run the refit. ⚠ Structural changes
   BEFORE the refit.
5. **Still owed:** convert the 34 tied SPO copies on touch; the bare-overlay lint's 61 occurrences;
   `test-likelihood.R:587`'s `kz$hi <= 7000` guard rail, failing for Marcus since 09-01.

⛔ **AND THE STANDING RULE THIS ARC MUST NOT BREAK:** every one of these fixes ADDS a mechanism that
makes an observable easier to match. **A mechanism that improves a fit is not thereby right.** Each
must be judged on whether it relaxes a STRAINED PRIOR or shrinks a FITTED COMPENSATOR — P2 and B's
acceptance test are written that way on purpose.
