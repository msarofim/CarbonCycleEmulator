# PRE-REGISTRATION — FIX B: re-score the BUILT ocean structures against the
# TWO observables that did not exist when the candidate list was scored

**Written 2026-09-04i, BEFORE `calibration/diag_fixB_ocean_levers.R` existed or ran.**
Marcus: *"Yes, I think we need to do work on Fix B."*

---

## Why this is a re-scoring and not a new mechanism

`DESIGN.md` §3.4a already lists the ocean structural candidates and insists they be **"scored
against the same observables, not adopted one at a time on mechanism plausibility."** Four of them
are **already built in the model and default to zero**, so the pure-diffusion column is
bit-reproduced: `w_up` (uniform upwelling + a polar sinking limb), `w_out_NH` / `w_out_SH` (a
deep→mixed-layer conduit in ONE step, distributed return), and `q_conv` (the conveyor).

⭐⭐ **THE POINT: THE LIST WAS SCORED ON FIVE OBSERVABLES IN AUGUST, AND THE TWO THAT MATTER FOR FIX B
DID NOT EXIST YET.**
- The **ENSO ocean sensitivity** was not diagnosed until **2026-09-01**
  ([[ccx_ocean_enso_sign_error]]) — two weeks after B1 was scored and rejected.
- **GATE H**, the interhemispheric gradient contrast, was built **today**.
- The **δ¹³C LEVEL bias** was never one of the five discriminating rows either.

So "B1 FAILED" and "`w_up` ≥ 2 makes the deep age unreachable" are **verdicts on the deep-Δ¹⁴C row**,
and they stand. **They are not verdicts on the rows this pre-registration adds.**
⛔ **This does NOT re-open the conveyor**, which was falsified twice and is listed in §3.4a "only so
it is not re-proposed". `q_conv` appears below **as a harness control with a known answer**.

⭐ **AND THE STANDING METHOD IS EXPLICIT** ([[ccx_conveyor_not_the_enso_fix]]): **MEASURE THE LEVER
BEFORE BUILDING THE MACHINERY.** A static scan costs a minute; plumbing an ENSO-modulated forcing
column costs a day and an `N_FORCING` bump. **Nothing is implemented in this arc.**

## The physical claim being tested

`ccx_d13c_suess` diagnoses the δ¹³C over-depletion as **the price of the pure-diffusion ocean**:
*"the real ocean maintains isotopic disequilibrium by upwelling — water last in contact with a
preindustrial atmosphere keeps the return flux isotopically old. A diffusive column has no
upwelling, so its surface water is already Suess-loaded and the return flux is too depleted."*
If that is right, **one absent mechanism should show up on three rows at once**: the δ¹³C level, the
gate-H contrast, and the ENSO ocean sign. **That is the hypothesis this arc tests.**

---

## P0 — THE HARNESS CONTROL, SCORED FIRST

**PREDICT: raising `w_up` and `w_out` moves deep Δ¹⁴C AWAY from the GLODAP target**, reproducing the
2026-08-15 measurement (B1: z +1.70 → +2.26 → +6.69) and the CHANGELOG's `w_up` finding.
**FALSIFIER: it does not** ⇒ the harness disagrees with a recorded measurement, **P1–P4 ARE NOT READ**
and the discrepancy is the finding. Same contract as the MLO control in
`diag_seas_signature_inversion.R`.

## P1 — THE SIGN, AND THE DECISIVE ROW

The conveyor died on sign: `d(ocean sink)/d(q_conv) = +0.0101` GtC/yr per Sv — **more circulation
gave MORE uptake**, because *"in a transient anthropogenic run, ventilating deep water undersaturated
in anthropogenic carbon dominates over upwelling DIC-rich water to outgas."* If `w_up` and `w_out`
share that physics, Fix B dies the same way.

**PREDICT: `d(ocean sink)/d(w_up) > 0` and `d(ocean sink)/d(w_out) > 0`** — the same sign as the
conveyor, for the same reason.
**FALSIFIER: either is NEGATIVE**, i.e. more upwelling gives LESS uptake. That would make an
ENSO-modulated upwelling term viable **and would be a genuinely new result**, because it would mean
the one-step `w_out` limb behaves differently from the distributed conveyor. **This is the outcome
worth being wrong about.**

## P2 — THE MAGNITUDE, scored only if P1 falsifies

To reach the observed **+0.1153 ± 0.0246** GtC/yr per Niño3.4 unit from the solubility path's
**−0.1274**, an ENSO-modulated lever must supply **+0.2427** GtC/yr per index unit.
**PREDICT: the required modulation exceeds 100 % of the lever's own value**, as the conveyor's did
(136–542 %). **FALSIFIER: below 100 %** ⇒ physically plausible, and Fix B becomes a live mechanism.

## P3 — THE ISOTOPE ROW, and the one where these levers should WIN

**PREDICT: raising `w_out` REDUCES the δ¹³C over-depletion** — model−obs currently **−0.196 ‰** at
MLO — because the one-step deep→surface limb returns preindustrially-aged carbon, which is exactly
the mechanism `ccx_d13c_suess` names. **PREDICT the effect is LARGER for `w_out` than for `w_up`**,
because `w_up`'s upward limb is distributed box-to-box and re-equilibrates on the way.
**FALSIFIER: no reduction, or `w_up` beats `w_out`** ⇒ the named mechanism is not what the model's
δ¹³C bias responds to, and the `ccx_d13c_suess` diagnosis needs revisiting.

## P4 — GATE H

**PREDICT: `w_out` reduces the gate-H contrast** (`R_d13c − R_co2`, currently **+1.056**, z +6.55).
**FALSIFIER: it does not move it, or moves it the wrong way.**
⚠ **WEAKEST OF THE FOUR AND LABELLED SO IN ADVANCE:** gate H is one day old, its target is a
hemispheric contrast, and `w_up`/`w_out` are configured per hemisphere here only in the crude
NH=SH form. A null on P4 is weak evidence, a hit is suggestive, and neither decides anything alone.

---

## What is NOT claimed

- **Nothing is implemented, fitted or adopted.** Every scan holds the other 25 parameters at
  `ent26` and re-optimises nothing. ⚠ That means every row is a **CONDITIONAL** price, and the
  standing rule says a conditional price has been ~100 % wrong twice
  ([[ccx_solar_aerosol_declined]]). **A promising conditional row licenses a re-optimised follow-up,
  never an adoption.**
- **No claim about `z_K`** (candidate A, depth-dependent `kz`). It is **not built** — it was
  measured in a diagnostic only — so it is out of scope here.
- **The ENSO sensitivity target is GCB's**, itself a model/data-product ensemble; the conveyor memo
  already flagged that it *"deserves an observational cross-check"*. I reproduced it independently
  at **+0.1153 ± 0.0246** from GCB + Niño3.4, which is a re-measurement, **not an independent
  product**. Treated as the best available target, not as truth.
