# Handoff — CarbonCycleEmulator, 2026-09-04g (third session of the day)
# **GATE S'S TARGET IS CORROBORATED BY AN OBSERVATION THAT NEVER TOUCHES THE MODEL.**
# **⭐ AND FIX B IS PRICED — AND THE MODEL **UNDER**-RESPONDS TO ENSO, NOT OVER.**
# **🐛 TWO BUGS IN THIS SESSION'S OWN SCRIPT, ONE OF WHICH INVERTED A VERDICT.**

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`, commit `5e9393c` (1).
No remote; nothing to push.
⚠ **Sessions launch from `FaIRtoFrEDI/`; ALL of this is in `CarbonCycleEmulator/`.** Use `git -C <abspath>`.

**Read before this one:** `handoff_2026-09-04_gate_audit.md` — this session answered its §8 item 1.

**Suite: 1757 pass / 0 fail / 0 error / 4 skip. Unchanged** — nothing under `R/` or
`calibration/lib_*` was touched. **No refit, no parameter change, no new gate.** All model numbers
at `CCX_MODE_CANONICAL` = `ent26`.

---

## 0. WHAT THIS SESSION DID

One new diagnostic, `calibration/diag_gateS_indep_and_fixB.R` (**~4 s**), answering the two
questions the audit handoff said one product could serve. Pre-registered in
`notes/prereg_2026-09-04g_gateS_independent_and_fixB.md` **before the script existed**; scored in
`notes/collect_2026-09-04g_gateS_corroborated_and_fixB_priced.md`. CHANGELOG 2026-09-04g.

| | prediction | result |
|---|---|---|
| **A1** | 8.52 inside the Southern-Ocean bracket | ✅ **CORROBORATED** |
| **A2** | that bracket excludes the pre-fix limb | ✅ **HAS POWER** |
| **A3** | the SH-mean bracket excludes 8.52 | ✅ **DISCRIMINATES** |
| **A4** | (non-binding, pre-declared biased late) | ⚠ **+1.56 mo late**, as its bias predicts |
| **B1** | eq.Pacific > tropics > global | ✅ **CONFIRMED** |
| **B2** | two boxes, no tropical one | ✅ **CONFIRMED in source** |
| **B3** | required swing < the reservoir | ✅ **0.24×** |
| **B4** | *not pre-registered — added mid-session* | ⛔ model NET is **0.46×** observed |

---

## 1. ⭐⭐ GATE S IS NO LONGER RESTING ON THE MODEL ALONE

`SPO_SEAS_OCEAN_PHASE_INV` = **8.52 mo [7.82, 9.20]** was an SPO observation inverted through
**two scalars the model supplies** (`s_L`, `s_O`) — the reason all six `SPO_SEAS_*` constants read
`status = "provisional"`. **The independent route uses no signature scalar and no model output.**
SOM-FFN surface-ocean ΔpCO₂ gives the **flux** phase; the conversion to an **atmospheric** phase is
a **LAW EXPRESSED AS A BRACKET, NOT A NUMBER** — a first-order box lags its forcing by
`arctan(ωτ) ∈ (0°, 90°]`, i.e. **0 to 3 months**.

| band | ΔpCO₂ amp µatm | peak mo | bracket | 8.52? | 4.16? |
|---|---|---|---|---|---|
| **SO 40–90 °S** | 18.65 | **7.41** | **[7.41, 10.41]** | **YES** | no |
| SO 60–90 °S | 40.98 | 7.76 | [7.76, 10.76] | YES | no |
| **SH all** | 5.32 | **1.54** | **[1.54, 4.54]** | **no** | **YES** |
| NH all | 1.95 | 7.63 | [7.63, 10.63] | YES | no |

* **A1** — the bracket contains 8.52, the whole registered CI, **and `ent26`'s own limb at 8.871**.
  ✅ The SO ΔpCO₂ peak **7.41 reproduces 2026-08-27f's 7.41 exactly** — an independent check on the
  pipeline itself, not just the conclusion.
* ⭐ **A2 — POWER, pre-registered because a corroboration that cannot fail is worth nothing.** The
  bracket is **25 % of the circle** (random pass p = 0.25) and it **EXCLUDES both readings of the
  pre-fix limb**: 4.16 (channel decomposition), 3.35 (`lib_seas_limbs.R`). ⇒ **the defect gate S was
  built to catch is confirmed independently of the inversion.**
* **A3** — the SH **area-mean** bracket excludes 8.52 **and contains 4.16**: the pre-fix model was
  matching the SH area mean, which 08-27f measured as a **76 % cancellation of two antiphase limbs**.
  Two routes, one reading. ⚠ **Not band-unique** — the NH bracket also contains 8.52; irrelevant to
  a South Pole station, but stated rather than left to be found.
* ⚠ **A4 IS THE ONE TENSION, AND IT IS THE ROW THE PREREG CALLED BIASED.** With τ = `tau_ex`
  (0.902 yr), `arctan(ωτ)` = **2.67 mo** ⇒ implied phase **10.08**, **+1.56 mo late** of 8.52. The
  prereg said in advance that `tau_ex` alone is an **UPPER BOUND** on the SH box's loss time (sinks
  drain it too) so the lag is biased LATE — **and it landed late.** Reported; it does not fail the
  gate.

⇒ ⭐ **A DECISION FOR MARCUS, DELIBERATELY NOT TAKEN:** `SPO_SEAS_OCEAN_PHASE_INV`'s provisional
status can narrow from *"circular"* to *"model-dependent in a way now bounded by an independent
observation"*. **Nothing in the registry was edited.**

---

## 2. ⭐⭐ FIX B IS LIVE, STRUCTURAL, AND THE ARGUMENT IS STRONGER THAN THE HANDOFF'S

* **B1 — an ORDERING, so no threshold had to be invented.** Annual area-weighted pCO₂ **minus the
  global ocean mean** — an **INTERNAL CONTRAST**, needing neither an atmospheric field (this product
  has none) nor a reference year (it states none): **eq. Pacific +55.47 > tropics +15.24 > global**;
  Southern Ocean **−2.98** µatm. Widening the longitude mask moves it only **−12 %**.
* **B2 — a SOURCE reading, not a run.** Two hemispheric mixed layers, one `pco2_ml` each, **no zonal
  or equatorial box** ⇒ representable tropical-minus-global contrast **EXACTLY ZERO**.
  `gamma_enso_ocn_*` is an **additive flux with a free coefficient** (`src/ccx_core.cpp:528`), not an
  upwelling response — as its own comment already says.
* **B3 — the mechanism is the right SIZE.** GCB ocean sink on **annual** Niño3.4 with a year term
  (1959–2024, **n = 66**): **+0.1153 ± 0.0246** GtC/yr per index unit, t +4.69, r **+0.488** —
  reproducing the registered target **+0.119** to within the detrending choice. Through the model's
  **own** air-sea prefactor over that mask (4.1 % of ocean area), it needs **13.15 µatm** =
  **0.24× the reservoir** ⇒ upwelling can plausibly carry the whole observed signal.

### ⛔⛔ B4 — THE VERDICT INVERTS ONCE THE COMPARISON IS LIKE-FOR-LIKE

The first draft put the **patch coefficient** (|γ_NH|+|γ_SH| = 0.356) against the **net** GCB slope
and read "**308 %** — the patch is 3× too strong". **Not like-for-like.** Measured the way the
observation was — the model's own annual ocean uptake, same index, same year term:

| arm | slope GtC/yr per index | se | r |
|---|---|---|---|
| **GCB (observed)** | **+0.1153** | 0.0246 | **+0.488** |
| model, `ent26` | **+0.0532** | 0.0303 | +0.207 |
| model, patch OFF | **−0.1274** | 0.0318 | **−0.432** |

⭐ **The model UNDER-responds, at 0.46× observed.** The patch is oversized because it must first
cancel the solubility path: **0.356 of coefficient buys +0.181 of net slope.**
⭐ And the comment's "wrong sign" is **re-measured, not recalled**: **r −0.432** at `ent26`. The
recorded **−0.51** was measured at an earlier mode and is **not** what the canonical mode reads.

⇒ **Fix B is not "shrink an oversized coefficient". It is that a wrong-sign mechanism is being paid
for TWICE** — once in the patch that cancels it, and again in a net response still at half observed.
**REPORTED, NOT GATED:** the observed sensitivity supplies **31 %** of gate V's 0.213 deficit, and
gate V's own record says a FAIL there **is not a blocker**.

---

## 3. 🐛 TWO BUGS IN THIS SESSION'S OWN SCRIPT — BOTH VERDICT-CHANGING

Both found by the **quantitative pre-check**, not by any test. Both now gated, **both gates
mutation-tested against the exact bug**.

1. ⛔⛔ **THE MASK WRAPPED THE DATE LINE AND THE CODE DID NOT.** The grid runs **−180…180**;
   `160 °E → 80 °W` written in the 0–360 idiom as `lon >= 160 & lon <= 280` selects **160–180 °E
   only** — 20° of **WARM POOL**, the *lowest*-pCO₂ part of the basin, at **one sixth** of the
   intended area — with **no error** and a plausible-looking **+23.78 µatm**. Caught because the
   printed area 2.47e12 m² was **6× below** the `2πR²·Δsinφ·Δλ/360` hand calculation. ⇒ correct
   **+55.47 µatm**. ⭐⭐ **B3 READ "1.78× the reservoir, FALSIFIED, Fix B is mis-specified" AND NOW
   READS "0.24×, CONFIRMED".** A wrong mask produced a coherent, confident, WRONG conclusion that
   would have killed a live mechanism.
2. ⛔ **`forcing_enso.rds` IS MONTHLY, GCB IS ANNUAL.** `merge(..., by = "year")` replicated each GCB
   row **twelve times**: n **66 → 792**, t inflated by ≈√12 to a meaningless **+11.30**.
   ⇒ annualised: **+0.1153**, t **+4.69**.

`lon_mask()` gates its own span; `stopifnot(nrow == n_years)` guards the merge.

---

## 4. ⚠ NON-OBVIOUS STATE

* **Torch: nothing running.** Everything here is local and takes seconds.
* ⚠⚠ **`INDEX_ccx.md` IS AT 18,225 BYTES OF CONTENT AGAINST AN 18 KB HARD CEILING** (464-byte header
  excluded). I kept it under only by **routing this session's two findings to the sub-indexes that
  own them** — gate S to `INDEX_ccx_seas.md` (13,999 B), Fix B to `INDEX_ccx_ocean.md` (11,969 B) —
  and leaving a two-line pointer in the root. **The previous handoff's warning stands and is now
  urgent: the next addition to `INDEX_ccx.md` needs a RESTRUCTURE, not another trim.**
  `MEMORY.md` is **17,087 B** against a 12 KB soft target and was **not** added to.
* **New memories:** `ccx_gateS_corroborated_by_pco2`, `ccx_fixB_reservoir_priced`,
  `mask_wraps_the_code_does_not` (the last pointed at from `INDEX_diag.md`'s silent-gate family,
  now **eleven** members).
* ⚠ **`diag_so_pco2_phase.R` (08-27f) and `diag_gateS_indep_and_fixB.R` share masks, the fill-value
  handling and the estimator by COPY, not by a common library.** They agree exactly today (both give
  the SO ΔpCO₂ peak at 7.41). **They can drift.** If a third file needs them, extract first.
* ⚠ Everything else from the audit handoff's §7 still stands.

---

## 5. ⇒ THE OPEN DECISIONS, RE-RANKED

1. ⭐⭐ **BUILD FIX B.** It is now specified and priced, and §2 says what it must do: give the ocean
   an ENSO path with the **right sign**, so the patch stops paying to cancel the solubility path.
   B1/B3 say the equatorial reservoir is the right size to carry it. ⚠ **B2 says this is STRUCTURAL**
   — the model has no tropical box — so scope the design before writing anything.
2. ⭐ **A4's +1.56 mo, honestly.** Stop assuming τ: **measure the model's own flux→atmosphere lag**
   (its SH air-sea flux phase vs the resulting SPO atmospheric limb) and apply *that* to the observed
   ΔpCO₂ phase. That is a **TRANSPORT** dependence, not the δ¹³C **SIGNATURE** one gate S's
   circularity is about — so A1 stays the scored row either way.
3. ⭐ **`sst_seas_amp_NH` at −3.91**, still the worst prior violation, still undiagnosed.
4. ⭐ **`INDEX_ccx.md`'s restructure** (§4) — this is now blocking, not cosmetic.
5. **Fix C on its own terms** (P5's lifetime). ⚠ Re-read the audit handoff §6 first: it is **no
   longer a falsified claim**.
6. **A posterior.** Both stated blockers are gone at `ent26`.
7. **The 2020–2022 growth deficit** (~1 GtC/yr, unattributed).
8. **Observations we HAVE and do not test:** `obs_d14c_station_validation` (160 held-out station
   Δ¹⁴C points, read by nothing); the Eide ocean δ¹³C Suess depth profile; the MOD17 **global** NPP
   level. **Absent entirely:** the ocean anthropogenic-C inventory; atmospheric O₂/APO.
9. **Still owed from before:** the 34 tied SPO copies on touch; the bare-overlay lint's remaining
   occurrences; a 26-par PINNED refit if the free-vs-pinned check is worth restoring.

---

## 6. ⇒ THE STANDING RULES THIS SESSION ADDED TO

* ⭐⭐ **A SELECTION CAN SILENTLY SUCCEED ON THE WRONG DATA AND STILL PRINT A PLAUSIBLE NUMBER.**
  Gate a mask on its **SPAN** and a merge on its **ROW COUNT**. The tell was arithmetic, not a test.
* ⭐ **CONVERT WITH A LAW EXPRESSED AS A BRACKET, NOT WITH A NUMBER.** Gate S's independent check
  works precisely because `arctan(ωτ) ∈ (0°, 90°]` needs no τ to be asserted.
* ⭐ **STATE THE POWER OF A CORROBORATION, NOT ONLY OF A NULL.** A 25 %-of-the-circle bracket that
  could not exclude the defect would have been worth nothing, and the prereg said so in advance.
* ⭐ **A COEFFICIENT IS NOT A RESPONSE.** Comparing a fitted patch coefficient with a NET observed
  slope read "3× too strong"; measured like-for-like the model is at **0.46×** — the opposite sign of
  error. Measure the model side the way the observation was measured.
