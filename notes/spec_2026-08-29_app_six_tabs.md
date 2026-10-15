# SPEC 2026-08-29 — **THE SIX TABS** (Marcus's requirements, recorded verbatim in substance)
# This is a REQUIREMENTS record, not a design I invented. Technical flags are marked ⚠ and are mine.

## 1. THE TABS AS SPECIFIED

**① Global historic atmospheric CO₂**
- Graph A: observed vs modeled CO₂ over time, **by month** (the Keeling curve).
- Graph B: **annual year-over-year CO₂ increase**.
- Key input graphs: **CO₂ emissions (fossil / LUC)**, **ENSO**, **volcanic AOD**, **temperature**.
- Right-hand panel: **four checkboxes — ENSO, volcanoes, warming, human emissions — on or off in
  ANY combination.**
- **The ENSO and volcano boxes adjust BOTH the temperature and the non-temperature factors.**

**② Historic isotope trends.**

**③ Future projections** — the van Vuuren scenarios, our model compared to **FaIR** and **MAGICC**.

**④ Emission pulses** — using **a tracer**, so we can see total atmospheric concentration versus
**which box of the model it ends up in**. **DECIDED 2026-08-29 — THREE charts:**
1. **top: total atmospheric CO₂**;
2. **what FRACTION OF THE TRACER is in which box**;
3. **how much ADDED CO₂ is in each box** — *"if it doesn't add too much complexity"*.

⚠ **Charts 2 and 3 are exactly the LABEL and the PERTURBATION**, the two things §4 warns differ by
**2.8× in the atmosphere at 100 yr**. Specifying them as separate charts is the right resolution —
**they must carry separate captions saying which question each answers**, and chart 3 is worth the
complexity precisely because it is the one that answers "how much extra CO₂ is left".

**⑤ Hemispheric effects** (form TBD).

**⑥ CO₂ transport into the oceans.**

## 2. MAPPING ONTO THE APP THAT EXISTS

Current tabs (`app/ui.R`): "The Keeling Curve", "Where does the carbon go?", "What if…?",
"Isotope fingerprints", "Futures", "Under the hood".

| new | from | work |
|---|---|---|
| ① Global historic CO₂ | *The Keeling Curve* | **major** — add YoY graph, 4 input graphs, 4 checkboxes |
| ② Historic isotopes | *Isotope fingerprints* | light |
| ③ Future projections | *Futures* | **major** — add van Vuuren + FaIR + MAGICC comparison |
| ④ Emission pulses | *Where does the carbon go?* | moderate — the partition panel exists ([[ccx_pulse_partition_panel]]) |
| ⑤ Hemispheric | — | **new** |
| ⑥ Ocean transport | partly *Under the hood* | **new** |

⚠ **"What if…?" and "Under the hood" are displaced by this six.** Fold, drop, or keep as a seventh —
**a decision, not an implementation detail.**

## 3. ⚠ THE HARD REQUIREMENT IN ①: THE CHECKBOXES NEED AN ATTRIBUTABLE GMST DECOMPOSITION

`gmst` is currently **one observed series** (`data/forcing_gmst.rds`) feeding
`q10f = pow(q10, gmst/10)` (`ccx_core.cpp:371`) and, through `ccx_sst_anom_from_gmst()`, the ocean.
**It contains anthropogenic + volcanic + ENSO + internal variability, inseparably.** To toggle
"volcanoes" and have it move the temperature too, GMST must be split into components that sum back
to the observed series.

**Marcus: "We can use FaIR to estimate the ENSO and volcanic temperature effects."**
⚠ **Half of that works and half does not, and the halves need different methods:**

- **VOLCANIC — yes, FaIR does this.** FaIR carries volcanic forcing (with its own scale factor; see
  the `fair-quirks` skill) and returns the FORCED temperature response. Run with and without the
  volcanic forcing series; the difference is the volcanic temperature component. ✅
- **ENSO — no, FaIR cannot.** ENSO is INTERNAL VARIABILITY, not a forced response; FaIR does not
  simulate it and never will. The standard method is instead a **multiple regression of observed
  GMST on (ENSO index at a lag, volcanic AOD, solar, trend)** — Foster & Rahmstorf 2011 — which
  yields an empirical ENSO temperature coefficient (~0.1 K per unit Niño3.4 at a ~3–5 month lag).
  ⚠ **Regression, not FaIR.**
- ⇒ **the decomposition is a HYBRID**: FaIR for the forced volcanic component, regression for ENSO,
  residual/trend for "warming". **It must be built so the components SUM to the observed series**,
  or the all-boxes-on state will not reproduce the calibrated run.

**⚠ A counterfactual can be physically incoherent and that is FINE — but label it.** "Human emissions
off, warming on" is a world that warms with no CO₂ rise. It is pedagogically useful as a
counterfactual and nonsense as a physical state; the tab should say so rather than pretend otherwise.

**⚠ No recalibration is needed.** The model is calibrated with everything on; the checkboxes are
counterfactual RUNS of the calibrated model, not re-fits. Say this in the tab so nobody reads a
checkbox state as "the model refitted without volcanoes".

## 3a. ⚠ THE AOD ARCHITECTURE — WHAT THE VOLCANO CHECKBOX ACTUALLY HAS TO DO

**Marcus, 2026-08-29:** *"The AOD should be a diffuse light → NPP mechanism, with the AOD → climate
mechanism implicit in the existing temperature record (and then backed out with FaIR or
Foster-Rahmstorf for removing volcanic influence through the checkbox)."*

**⇒ THE MODEL HAS EXACTLY ONE AOD PATHWAY: diffuse light → NPP.** The volcanic TEMPERATURE effect is
NOT a second model term — it is already carried by the observed `gmst` series
(`ccx_core.cpp:371`, `q10f = pow(q10, gmst/10)`). ⚠ **Adding an AOD → temperature term would
DOUBLE-COUNT it.**

**So "volcanoes OFF" is TWO edits on the FORCING side, and neither alone is correct:**

1. **zero `aod_NH` / `aod_SH`** → removes the diffuse-light NPP path (a model input);
2. **subtract the volcanic component from `gmst`** → removes the implicit thermal path
   (FaIR's volcanic-free run, or the Foster–Rahmstorf regression term).

⚠ **A consequence worth knowing:** `ccx_hold_climate()` deliberately does NOT freeze AOD, because
AOD is a radiative driver rather than a climate variable. So once `gamma_diff` ≠ 0, **"climate held"
no longer implies "volcanically quiet"** and a diagnostic that needs a quiet run must zero AOD
itself. (This corrects my first answer to the inventory gate, which classified AOD as climate.)

## 3a-bis. ⚠ THE SAME IS TRUE OF ENSO — IT IS A GENERAL RULE, NOT TWO SPECIAL CASES

**Marcus, 2026-08-29:** *"ENSO off also has two effects: the ENSO-temperature effect and the direct
effect of ENSO on the carbon cycle."*

**⇒ EVERY DRIVER WITH BOTH A DIRECT CARBON PATH AND A TEMPERATURE PATH NEEDS TWO EDITS TO TURN OFF.**
There are exactly two such drivers today, and they are structurally identical:

| driver | DIRECT carbon path (a model term) | TEMPERATURE path (implicit in the observations) |
|---|---|---|
| **ENSO** | `gamma_enso * enso * enso_share[hi]` out of the responsive soil pool (`ccx_core.cpp:396`) | ENSO's contribution to `gmst` **and** to `sst_anom_*` |
| **Volcanoes** | `gamma_diff * aod_h` on NPP (`ccx_core.cpp:~350`) | volcanic cooling in `gmst` **and** in `sst_anom_*` |

**Zeroing the driver column alone leaves the temperature half running. Backing the component out of
the temperature record alone leaves the direct half running. Both, or the checkbox lies.**

### ⚠ AND A THIRD EDIT NOBODY WOULD GUESS: `sst_anom_*` IS NOT DERIVED FROM `gmst`

Checked in `ccx_sst_anom_from_gmst()` (`R/forcing.R`): over the **observed record** the hemispheric
SST anomalies are **PRESCRIBED FROM HadSST4** (`data/forcing_sst.rds`); they only follow `gmst`
incrementally **beyond** the last observed year (`beyond <- F$year > last`).

⇒ **Over the whole historical period `gmst` and `sst_anom_NH`/`sst_anom_SH` are INDEPENDENT
observational series.** Subtracting the ENSO or volcanic component from `gmst` therefore does
**NOT** remove it from `sst_anom_*`, and the **ocean would keep seeing the signal the checkbox
claims to have switched off.** The decomposition must be applied to **BOTH**, consistently.

### ⚠ AN ASYMMETRY IN `ccx_hold_climate()` THAT IS NOW REAL
It freezes `gmst`, `enso`, `sst_anom_*` — so it removes **ENSO's variability on BOTH paths**
(the `enso` column is one of the frozen four), but only the **THERMAL** half of the volcanic signal,
because `aod_*` is deliberately not frozen (§3a). ⇒ once `gamma_diff` ≠ 0, **"climate held" is a
volcanically NOISY, ENSO-quiet world.** Not a bug; a thing to know before reading any diagnostic
that uses it.

## 3b. DECIDED (Marcus, 2026-08-29)

**The GMST decomposition uses a Foster–Rahmstorf-style REGRESSION as the primary method**, with FaIR
available as a cross-check: *"FaIR doesn't have ENSO, so it could serve as the 'ENSO-free' control.
But a Foster–Rahmstorf-style regression might be better."* ⇒ **regression is primary; FaIR's
ENSO-free run is a validation of the volcanic and trend components, not the source of the ENSO one.**

**More tabs are acceptable** — the six are not a ceiling, so "What if…?" and "Under the hood" may
survive as ⑦/⑧ rather than being folded.

**⚠ TAB ⑤ (hemispheric) IS DEFERRED UNTIL THE COMPONENT IS FIXED.** Marcus: *"don't build the
hemispheric tab until we've fixed it."* ⇒ it is gated behind plan items ③/④.

## 4. ⚠ THE TRAP IN ④, ALREADY MEASURED

Marcus asks for **a tracer** showing "which box of the model it ends up in". [[pulse_label_vs_perturb]]:
**a LABEL and a PERTURBATION are not the same experiment and they differ by 2.8× in the atmosphere at
100 yr.** ¹⁴C is already an inert tracer because the partition is decay-invariant (checked to
1.1e-16). **Both charts belong in the app and they MUST NOT share a caption.** The tracer answers
"where did THESE molecules go"; the perturbation answers "how much extra CO₂ is left". Conflating
them is the single most likely way this tab teaches something false.
Also: [[ccx_pulse_partition_panel]] — the five bars sum to 1.000 (closes to 0.000 %), and **40 % of a
pulse is in the LAND at year 3000**, which no gate currently scores.

## 5. WHAT EACH TAB NEEDS THAT DOES NOT YET EXIST

| tab | missing |
|---|---|
| ① | the GMST decomposition (§3); the volcanic mechanism itself (plan ①) — **AOD data now exists** |
| ③ | van Vuuren scenario inputs; FaIR and MAGICC comparison runs (both live in sibling repos) |
| ④ | nothing structural — the tracer and partition machinery exist |
| ⑤ | the hemispheric story is currently a KNOWN DEFECT (gate 5's τ tension) — ⚠ **this tab will display our worst-fitting component**, which is either a problem or the most honest thing in the app |
| ⑥ | the pump is shipped and wired; needs presentation, not physics |

⚠ **⑤ deserves a decision.** Interhemispheric transport is the model's weakest component
(contrasts ~0.085 ‰ / ~5.6 ‰ too strong, bomb lag 0.97 vs 1.34 yr). A hemispheric tab built now
would show that. Options: build it after plan ③/④; or build it now and make the discrepancy the
teaching point.
