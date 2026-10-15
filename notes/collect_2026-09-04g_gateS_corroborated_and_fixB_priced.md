# COLLECT — 2026-09-04g. GATE S's TARGET IS **CORROBORATED BY AN OBSERVATION THAT
# NEVER TOUCHES THE MODEL**, AND FIX B IS **LIVE, STRUCTURAL, AND UNDER-DELIVERING**

Scores `notes/prereg_2026-09-04g_gateS_independent_and_fixB.md`, written before
`calibration/diag_gateS_indep_and_fixB.R` existed. Full console output is reproducible in
~4 s: `Rscript calibration/diag_gateS_indep_and_fixB.R`.

**Every model number at `CCX_MODE_CANONICAL` = `ent26`** (26 par, logpost −1446.7627).
**No refit, no parameter change, no new gate.**

---

## 0. THE SCORECARD

| | prediction | result |
|---|---|---|
| **A1** | 8.52 inside the Southern-Ocean bracket | ✅ **CORROBORATED** — [7.41, 10.41] |
| **A2** | that bracket EXCLUDES the pre-fix limb | ✅ **HAS POWER** — 4.16 and 3.35 both excluded |
| **A3** | the SH-mean bracket EXCLUDES 8.52 | ✅ **DISCRIMINATES** — [1.54, 4.54] |
| **A4** | (non-binding, biased late) | ⚠ lands **+1.56 mo late**, as its own bias predicts |
| **B1** | eq.Pacific > tropics > global ocean | ✅ **CONFIRMED** — +55.5 / +15.2 µatm |
| **B2** | two hemispheric boxes, no tropical one | ✅ **CONFIRMED in source** |
| **B3** | required swing < the reservoir | ✅ **CONFIRMED** — 13.2 µatm = **0.24×** |
| **B4** | (added after B3; not pre-registered) | ⛔ model NET is **0.46×** observed |

---

## 1. ⭐⭐ GATE S IS NO LONGER RESTING ON THE MODEL ALONE

Gate S's target `SPO_SEAS_OCEAN_PHASE_INV` = **8.52 mo [7.82, 9.20]** is the observed SPO CO₂ +
δ¹³C harmonics inverted through **two scalars the model supplies**. That is why all six
`SPO_SEAS_*` constants carry `status = "provisional"`.

**The independent route uses no signature scalar and no model output at all.** Surface-ocean
ΔpCO₂ from the Landschützer/Laruelle climatology gives the phase of the *flux*; the conversion to
an *atmospheric* phase is a **LAW, expressed as a bracket, not a number** — a first-order box
forced at ω lags its forcing by `arctan(ωτ) ∈ (0°, 90°]`, i.e. **0 to 3 months**.

| band | ΔpCO₂ amp µatm | peak mo | bracket | 8.52 in? | 4.16 in? |
|---|---|---|---|---|---|
| **SO 40–90 °S** | 18.65 | **7.41** | **[7.41, 10.41]** | **YES** | no |
| SO 60–90 °S | 40.98 | 7.76 | [7.76, 10.76] | YES | no |
| SO 40–60 °S | 10.99 | 6.93 | [6.93, 9.93] | YES | no |
| **SH all** | 5.32 | **1.54** | **[1.54, 4.54]** | **no** | **YES** |
| SH subtrop 0–30 °S | 17.22 | 1.52 | [1.52, 4.52] | no | YES |
| NH all | 1.95 | 7.63 | [7.63, 10.63] | YES | no |

**A1 — the target is corroborated.** 8.52 is inside the Southern-Ocean bracket, and so is the
gate's whole registered CI [7.82, 9.20]. `ent26`'s own limb, **8.871**, is inside it too.

**A2 — and the check has POWER, which was the thing worth pre-registering.** The bracket is
**25 % of the circle**, so a random phase passes with p = 0.25; a corroboration that could not
fail would be worth nothing. It **excludes both readings of the model's pre-fix SH ocean limb**
(4.16 on the channel decomposition, 3.35 on `lib_seas_limbs.R`). ⇒ **The defect gate S was built
to catch is independently confirmed to be a defect** — not an artifact of inverting through the
model's own δ¹³C signatures.

**A3 — and it says WHICH regime SPO samples.** The SH **area-mean** bracket [1.54, 4.54] excludes
8.52 **and contains 4.16**. So the pre-fix model was matching the SH area mean — which 2026-08-27f
independently measured as a **76 % cancellation of two antiphase limbs**. Two routes, same reading.

⚠ **Not band-unique**: the NH bracket also contains 8.52. That is irrelevant to a South Pole
station but it is stated rather than left for a reader to notice.

**A4 — the one row with a tension, and it is the row pre-registered as biased.** With τ taken from
`tau_ex` = 0.902 yr, `arctan(ωτ)` = **2.67 mo**, putting the implied atmospheric phase at **10.08**
— **+1.56 mo later** than the gate's 8.52. The prereg said in advance that `tau_ex` alone is an
**upper bound** on the SH box's loss time (sinks drain it too), so the implied lag is biased
**LATE** — and it landed late. **It is reported, it does not fail the gate**, and the honest
follow-up is named in §5 rather than resolved by argument here.

⇒ **RECOMMENDATION (a decision for Marcus, not taken here):** `SPO_SEAS_OCEAN_PHASE_INV`'s
provisional status can be **narrowed from "circular" to "model-dependent in a way now bounded by
an independent observation"**. The constant's `status` field is not touched by this script.

---

## 2. ⭐⭐ FIX B: THE RESERVOIR IS REAL, LARGE, AND STRUCTURALLY ABSENT FROM THE MODEL

**B1 — the ordering, which is what an unsourced threshold would have had to invent.**
Annual area-weighted mean pCO₂, minus the global ocean mean (an **internal contrast**, so it needs
neither an atmospheric field — this product has none — nor a reference year — it states none):

| mask | pCO₂ µatm | − global |
|---|---|---|
| global ocean | 367.27 | — |
| tropics 20 °S–20 °N | 382.52 | **+15.24** |
| **eq. Pacific 5 °S–5 °N, 160 °E–80 °W** | 422.75 | **+55.47** |
| Southern Ocean 40–90 °S | 364.29 | −2.98 |

Both inequalities hold. Widening the longitude mask to 140 °E–70 °W moves the contrast **−12 %**,
so the declared judgment is not carrying the result.

**B2 — the model cannot represent any of it, and this is a SOURCE reading, not a run.** The ocean
is **two hemispheric mixed layers** (`ml_C_NH`, `ml_C_SH`); `R/model.R` computes one `pco2_ml` per
hemisphere from one `dic_ml`. There is no zonal or equatorial box, so the model's representable
tropical-minus-global pCO₂ contrast is **exactly zero**. Its ENSO ocean term is therefore an
**additive flux with a free coefficient** (`src/ccx_core.cpp:528`), not an upwelling response —
which is what the code's own comment already says.

**B3 — the mechanism is the right SIZE.** Regressing GCB ocean sink on annual Niño3.4 with a
linear year term (1959–2024, **n = 66**): slope **+0.1153 ± 0.0246 GtC/yr per index unit**,
t = +4.69, residual r = **+0.488** (the repo's recorded +0.535 reproduces to within the detrending
choice). Converted through the **model's own** air-sea prefactor over the equatorial mask
(4.1 % of global ocean area, `dF/dΔpCO₂` = 0.00877 GtC/(yr·µatm) at `k_w` = 1788), that sensitivity
needs a ΔpCO₂ swing of **13.15 µatm per index unit** — **0.24× the measured reservoir.**
⇒ **Equatorial upwelling is a plausible carrier of the whole observed ENSO ocean signal**: it asks
for a quarter of the pool, not more than the pool.

---

## 3. ⛔ B4 — THE FINDING THAT WAS NOT PRE-REGISTERED, AND THE COMPARISON THAT WOULD HAVE BEEN WRONG

The first draft compared the **patch coefficient** (|γ_NH| + |γ_SH| = 0.356) with the **net** GCB
slope (0.115) and read "**308 %** — the patch is 3× too strong". **That is not like-for-like**
([[like_for_like_forcing]]): the model's net ocean response is the patch **plus** the SST-solubility
path, which the code comment says carries the wrong sign. Measured the way the observation was —
the model's own annual ocean uptake, same index, same year term:

| arm | slope GtC/yr per index | se | r | n |
|---|---|---|---|---|
| **GCB (observed)** | **+0.1153** | 0.0246 | **+0.488** | 66 |
| model, `ent26` | **+0.0532** | 0.0303 | +0.207 | 66 |
| model, patch OFF | **−0.1274** | 0.0318 | **−0.432** | 66 |

⭐ **The verdict INVERTS.** The model is not over-responding: its **net** ENSO ocean sensitivity is
**0.46× observed**, and it is *under*. The oversized patch exists because it must first cancel a
wrong-sign solubility path (−0.127) before it can deliver anything — **0.356 of coefficient buys
+0.181 of net slope.**

⭐ **And the code comment's "wrong sign" is re-measured rather than recalled**: solubility-only
gives **r = −0.432** at the current mode (the recorded value, −0.51, was measured at an earlier
one and is *not* what `ent26` reads).

⇒ **THIS IS THE ARGUMENT FOR FIX B, AND IT IS STRONGER THAN THE ONE THE HANDOFF CARRIED.** Fix B
is not "tune a coefficient that is too big". It is: **a mechanism with the wrong sign is being
paid for twice** — once in the fitted patch that must cancel it, and again in a net response that
still comes out at half the observed value.

**REPORTED, NOT GATED:** the observed sensitivity supplies **sd 0.065 GtC/yr = 31 %** of gate V's
0.213 deficit. ⚠ Gate V's own record says a FAIL there **is not a blocker** (Marcus 2026-09-04f),
so no number here is a requirement.

---

## 4. 🐛 TWO BUGS IN THIS SESSION'S OWN SCRIPT, BOTH CAUGHT BY IMPLAUSIBLE MAGNITUDES

Both were found by the "quantitative pre-check" discipline, not by a test, and **both changed a
verdict**. Both now have a gate, and **both gates were mutation-tested against the exact bug**.

1. ⛔ **THE MASK WRAPPED THE DATE LINE AND THE CODE DID NOT.** This grid runs **−180…180**;
   `160 °E → 80 °W` written as `lon >= 160 & lon <= 280` selects **160–180 °E only** — 20° of
   **warm pool**, the *lowest*-pCO₂ part of the basin, at **one sixth** of the intended area — and
   it still printed a plausible positive contrast (+23.78 µatm) with no error. Caught because the
   printed area, 2.47e12 m², was **6× below** the 1.48e13 m² that `2πR²·Δsinφ·Δλ/360` gives by
   hand. ⇒ Correct mask: **+55.47 µatm**, area 1.477e13 m².
   **`lon_mask()` now gates its own span**; mutation test: the buggy `(160, 280)` form **errors**
   with "asked for 120.0 deg, selected 20.0", and a non-wrapping control still passes.
2. ⛔ **`forcing_enso.rds` IS MONTHLY AND GCB IS ANNUAL.** Merging on `year` alone silently
   replicated each GCB row **twelve times**: n **66 → 792**, and the slope's t inflated by ≈√12 to
   a meaningless **+11.30**. ⇒ Annualized: slope **+0.1153**, t **+4.69**.
   `stopifnot(nrow == n_years)` now guards it; mutation test: the fanned-out merge **errors**, the
   annualized control passes.

⭐ **B3's VERDICT INVERTED on bug 1** — "1.78× the reservoir, **FALSIFIED**, Fix B is
mis-specified" became "**0.24×**, CONFIRMED". A wrong mask produced a *coherent, publishable,
wrong* conclusion that would have killed a live mechanism.

---

## 5. ⇒ WHAT IS NOW OWED

1. **A4's +1.56 mo, honestly.** The fix is to stop assuming τ and **measure the model's own
   flux→atmosphere lag** (the phase difference between its SH air-sea flux and the resulting SPO
   atmospheric limb), then apply *that* to the observed ΔpCO₂ phase. ⚠ That reintroduces a model
   dependence — but a **transport** one, not the δ¹³C **signature** one gate S's circularity is
   about, so A1 stays the scored row either way.
2. **Fix B is now specified**, and §3 says what it must do: give the ocean an ENSO path with the
   **right sign** so the patch is not paying to cancel the solubility path. B1/B3 say the
   equatorial reservoir is the right size to carry it (0.24× of the pool).
3. **`SPO_SEAS_OCEAN_PHASE_INV`'s status** — a decision for Marcus (§1), not taken here.
