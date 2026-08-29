# SPEC 2026-08-29 — **THE SIX TABS** (Marcus's requirements, recorded verbatim in substance)
# This is a REQUIREMENTS record, not a design I invented. Technical flags are marked ⚠ and are mine.

## 1. THE TABS AS SPECIFIED

**① Global historic atmospheric CO₂**
- Graph A: observed vs modelled CO₂ over time, **by month** (the Keeling curve).
- Graph B: **annual year-over-year CO₂ increase**.
- Key input graphs: **CO₂ emissions (fossil / LUC)**, **ENSO**, **volcanic AOD**, **temperature**.
- Right-hand panel: **four checkboxes — ENSO, volcanoes, warming, human emissions — on or off in
  ANY combination.**
- **The ENSO and volcano boxes adjust BOTH the temperature and the non-temperature factors.**

**② Historic isotope trends.**

**③ Future projections** — the van Vuuren scenarios, our model compared to **FaIR** and **MAGICC**.

**④ Emission pulses** — using **a tracer**, so we can see total atmospheric concentration versus
**which box of the model it ends up in**.

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
