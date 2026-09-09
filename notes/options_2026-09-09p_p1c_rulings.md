# OPTIONS — P1c's two rulings: the BAND-TO-BOX mapping, and WHAT THE MODEL SHOULD EXPOSE (2026-09-09p)
# **Rulings owed. Nothing changed on the strength of this note.**
# **Observed numbers are GENERATED from `data-raw/downloads/MPI-ULB-SOM_FFN_clim.nc` (Landschutzer/Laruelle, NCEI 0209633) by `calibration/diag_so_pco2_amplitude.R`, on GATE S's own masks and estimator. Model structure is read from the canonical `hilda31`.**

## 0. The two rulings
P1c would score the model's simulated seasonal surface-ocean pCO₂ against SOM-FFN, on GATE S's
template ("OBSERVATION + LAW", no model in the loop). It is blocked on:
- **RULING A — WHICH OBSERVED BAND corresponds to the model's `ml` box?**
- **RULING B — WHAT QUANTITY, and what must the model expose to produce it?**

---

## 1. The facts the rulings turn on

**The model's SH surface is TWO boxes, and neither matches the natural observational band:**

| | area share of SH ocean | thickness |
|---|---|---|
| `ml` (low-latitude surface) | **84 %** (`1 − hs_frac`, `hs_frac` = 0.16) | 49.15 m |
| `hs` (high-latitude surface) | **16 %** | **401.1 m**, pinned |
| the 40–90 °S band GATE S uses | **36.9 %** (`.ENT_BAND_AREA_FR`) | — |

**The observation has TWO ANTIPHASE REGIMES, and that is the whole difficulty:**

| band | amp (µatm) | peak month | regime |
|---|---|---|---|
| SH subtrop 0–30 °S | 12.62 | 1.43 | **thermal** — pCO₂ peaks in summer, solubility-driven |
| SH 30–40 °S | 22.19 | 1.28 | thermal |
| SO 40–60 °S | 11.31 | 7.10 | **DIC** — pCO₂ peaks in winter, entrainment-driven |
| SO 60–90 °S | 25.19 | 7.79 | DIC |
| **SO 40–90 °S** (GATE S) | **16.26** | **7.50** | DIC |
| **SH all (0–90 °S)** | **3.69** | 1.20 | **the two CANCEL** |

⭐⭐ **THE CANCELLATION IS THE CENTRAL FACT: the hemispheric mean is 3.69 µatm against the Southern
Ocean's 16.26 — a 4.4× destructive interference between two real, opposite-signed cycles.** Picking
the band therefore moves the target by up to 4.4×, and it is the same hazard that already bit GATE S
(its SH-area-mean bracket EXCLUDED the right answer while CONTAINING the pre-fix model).

**And the model's mechanism sits in the DIC regime, not the thermal one.** The seasonal ML produces
an anomaly peaking in **August** (measured, P1b), because the MLD climatology driving it
(`obs_mld.rds$seasonal`) is an **SH-wide cos-lat-weighted mean** whose August maximum is set by
high-latitude deep winter mixing.

⇒ ⛔⛔ **A LOW-LATITUDE BOX (84 % of the SH ocean) IS BEING GIVEN A HIGH-LATITUDE SEASONAL CYCLE.**
That is a structural statement about the model, and it is more consequential than which band gets
picked. Ruling A does not create this problem; it **exposes** it.

---

## 2. RULING A — the band-to-box mapping

### A1. `ml` → **SH all, 0–90 °S** (amp 3.69, peak 1.20)
- ⭐⭐ **PRO — it is like-for-like BY CONSTRUCTION, and this is the strongest argument in the note.**
  The mechanism is driven by an **SH-wide cos-lat-weighted** MLD climatology. The honest observational
  counterpart of a model quantity is the observation aggregated **the same way the model's own driver
  was**. That is the `like_for_like_forcing` rule applied to aggregation rather than to forcing.
- ⭐ **PRO — it is the only option that does not require choosing a latitude the model does not have.**
  `ml` has an area share, not a latitude range.
- ⛔ **CON — 3.69 µatm is a cancellation artifact, and a target that small is fragile**: it is the
  small difference of two large opposite cycles, so its own uncertainty is dominated by how the two
  regimes are weighted, not by the measurement.
- ⛔ **CON — the model will very likely FAIL it, on PHASE (Aug vs Jan) and by ~3× on amplitude.**
  ⭐ **But that failure would be CORRECT and informative**: it would say the single SH surface box
  cannot represent two antiphase regimes, which is a true statement about the structure. It would
  **not** falsify entrainment.

### A2. `ml` → **SO 40–90 °S** (amp 16.26, peak 7.50) — GATE S's band
- ⭐ **PRO — ONE convention with GATE S.** Amplitude and phase would come from the same product,
  band and estimator, so they cannot disagree for bookkeeping reasons. That is a real and specific
  benefit, and it was the reason I first recommended it.
- ✅ **PRO — it is the regime the mechanism actually operates in** (winter entrainment), so the test
  would be about the mechanism's SIZE rather than about the box's geography.
- ⛔ **CON — it maps the LOW-latitude box to a HIGH-latitude observation.** On area it is wrong twice
  over: `ml` is 84 % of the SH ocean, the band is 36.9 %, and the box that is *geographically*
  high-latitude (`hs`, 16 %) is not the one being scored.
- ⛔⛔ **CON — IT FLATTERS THE MODEL, and for a reason that is not physical.** The model's box gets a
  Southern-Ocean cycle only because its driver is dominated by Southern-Ocean mixing; scoring it
  against the Southern Ocean rewards that dominance rather than testing it. **A gate that is chosen
  because the model will pass it is not a gate.**

### A3. `ml` → **0–40 °S** (the low-latitude complement; amp 12.6–22.2, peak ~1.3)
- ✅ **PRO — the honest geographic match** for a low-latitude box, and it is a genuine observation
  with a healthy, non-cancelling amplitude.
- ⛔ **CON — the model would fail on phase by ~6 months**, for the reason in §1. Same informative
  failure as A1, without A1's like-for-like justification.
- ⚠ It also leaves `hs` (16 %) facing a 60 % band, which is worse than A1's split.

### A4. **Area-matched partition** — build the observed bands to match `hs_frac`
Take the 16 % highest-latitude SH ocean as the `hs` target and the remaining 84 % as the `ml` target.
- ⭐ **PRO — the only construction that is like-for-like BY AREA**, which is the one quantity the
  model's partition actually declares.
- ⭐ **PRO — derivable from the product already in hand**, no new data.
- ⛔ **CON — it assumes the model's box boundary is LATITUDINAL. It is not: `hs_frac` is an area
  fraction with no declared latitude**, and a HILDA high-latitude box is a *water-mass* concept.
  Choosing a latitude to realise it is exactly the kind of silent methodological choice that has to
  be ruled, so this option **contains a second ruling inside it**.
- ⛔ **CON — 16 % of SH ocean is roughly poleward of ~55 °S**, where the observed amplitude is
  largest (25.19 in 60–90 °S); `ml` would then inherit the residual, still mixing both regimes.

### A5. **Score `ml` and `hs` SEPARATELY against matched bands**
- ⭐ **PRO — it is the only option that does not average away the antiphase**, and it uses the model
  structure as built rather than collapsing it.
- ⛔⛔ **CON — `hs` is 401 m thick and is not a mixed layer.** Its seasonal pCO₂ is not comparable to
  a surface climatology in the first place, so the second half of the comparison is not defined.
- ⛔ **CON — it needs A4's latitude ruling anyway.**

### ⭐ Recommendation on A
**A1, and expect it to fail.** It is the only option whose aggregation matches the aggregation of the
model's own driver, and it requires no invented latitude. **The right posture is to run it as a
REPORTED comparison first, not as a gate** — because what it will most likely establish is a
structural limitation (one SH surface box cannot carry two antiphase regimes), and a gate is the
wrong instrument for reporting that.
⛔ **A2 should be declined despite its consistency benefit**, because the consistency is bought by
scoring a low-latitude box against a high-latitude observation that the model happens to match.
⚠ If a *gate* is wanted now rather than a comparison, **A2 with the mismatch stated at the gate** is
defensible — but then the gate's `src` must say plainly that the band does not correspond to the
box's area, in the way GATE S's own record states its caveats.

---

## 3. ⚠ AN UNRESOLVED 20 % DISCREPANCY THAT RULING A INHERITS
`R/constants.R` already carries **`.ENT_SO_PCO2_AMP <- 19.45`**, commented as the *"OBSERVED 40-90 S
pCO2 seasonal amplitude (Landschutzer/Laruelle NCEI 0209633), the same product CCX_ENT_SEAS_PEAK_MO's
7.50 comes from"* — **the same band and the same product as my 16.26**.

⛔ **Two numbers for one quantity, 20 % apart, and the difference is not explained anywhere.** The
most likely cause is the estimator: an **area-weighted mean of PER-CELL amplitudes** is phase-blind
and always ≥ the **magnitude of the harmonic of the area-mean series**, which is what GATE S's phase
uses and what `diag_so_pco2_amplitude.R` computes. That is precisely [[amp_definition_mismatch]],
whose record notes it has already bitten twice.
⚠ **It is not cosmetic: `.ENT_SO_PCO2_AMP` feeds `ENT_SEAS_AMP_SH_INBAND` and
`ENT_SEAS_AMP_SH_DERIV`, i.e. the PRIOR CENTRE 10.95 for `ent_seas_amp_SH`** — the parameter P12 is
about. ⇒ **Resolve which estimator produced 19.45 BEFORE ruling A**, because whichever is chosen
becomes the convention for both.

---

## 4. RULING B — what quantity, and what the model must expose

### B1. **Ocean pCO₂** — model `pco2_ml` vs SOM-FFN pCO₂
- ✅ **PRO — no conversion on either side.** `pCO₂ IS NOT FLUX`: `F = k·K0·ΔpCO₂`, and the product
  contains neither the wind seasonality in `k` nor the temperature seasonality in `K0`. Comparing
  pCO₂ to pCO₂ never forms a flux, so that caveat does not bite.
- ⛔ **CON — it is NOT what GATE S scores.** GATE S uses the air-sea **DIFFERENCE**, so B1 would put
  amplitude and phase on two different quantities — the exact split this whole exercise is trying to
  avoid.

### B2. **Air-sea ΔpCO₂ (ocean − atmosphere)** — GATE S's own quantity
- ⭐⭐ **PRO — ONE quantity for phase and amplitude**, which is the entire argument for using GATE S's
  template at all.
- ✅ **PRO — it is the quantity that actually drives the flux**, so it is the physically meaningful
  seasonal signal.
- ✅ **PRO — the atmospheric side is already in the objective** (the observed SPO CO₂ harmonic).
- ⚠ **CON — the atmospheric cycle is small** (~1 ppm against the ocean's 16 µatm), so B2 and B1 nearly
  coincide; the benefit is consistency rather than a different measurement. ⭐ My 40–90 °S phase came
  out **7.50** against GATE S's **7.41** for exactly this reason — close, and **rightly not
  identical**.
- ⇒ **RECOMMEND B2.**

### B3. **DIC amplitude**
- ⛔ **CON — it needs alkalinity to convert the observation**, adding a conversion the model is being
  tested on, and the model carries ALK as a single constant. Rejected.

### What the model must expose
⛔ **`ccx_run()$out` carries `ml_C` and `ml_C13` but NO mixed-layer pCO₂, and the flux trace carries
none either.** So B1/B2 need a new output column, `pco2_ml_NH/SH`, per month.
- ⚠ **It must be added to BOTH cores** and covered by `test-parity.R`, like every other output
  column — the R and C++ `out` blocks are separate emissions, and a column present in one and
  absent or transposed in the other is invisible to every other gate (the `CCX_OCEAN_BOX_COLS`
  precedent, which exists for exactly this).
- ⭐ **Cheap and low-risk**: the value is already computed inside the deriv (`pco2_ml`); exposing it
  is a diagnostic emission, not a physics change, so no stored logpost moves.
- ⚠ **One real choice inside it:** the deriv computes `pco2_ml` at the SEASONAL SST and, under
  `seas_ml`, at the seasonal ML mass. Recording it at the month's OPENING state (the existing flux
  trace convention) rather than as a substep mean is the consistent choice, and the difference is
  within-month curvature only.

---

## 5. What I would do, in order
1. **Resolve §3's 19.45-vs-16.26 estimator question.** It is cheap, it is a prerequisite for A, and
   it touches the prior centre of the parameter P12 is about.
2. **Expose `pco2_ml` in both cores** with a parity assertion (B2's prerequisite; no physics moves).
3. **Run A1 as a REPORTED comparison**, alongside A2 for reference, and let the pair speak: if A1
   fails on phase while A2 passes, that is the structural finding, stated as such.
4. **Only then** decide whether anything here becomes a gate.
