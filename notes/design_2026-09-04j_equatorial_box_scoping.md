# SCOPING — an equatorial surface box: does it need a hemispheric split?
# 2026-09-04j. Answers Marcus's three points. **Every number measured today.**
# ⚠ NOTHING IMPLEMENTED. This is a scoping note, not a design amendment.

Marcus: *"If the equatorial surface box would help with the intermediate water problem, then that
should be sufficient. The isotopic behavior should be similar across all the oceans as a function of
exchange rates. The equatorial surface box would still need a hemispheric split, right?"*

---

## 1. THE JUSTIFICATION BAR IS MET — the intermediate-water problem is real and localized

Measured 2026-09-04j against GLODAP at the bottle epoch (2002, n = 37,394):

| band | mean z | |
|---|---|---|
| upper ≤ 500 m | **+0.61** | bomb-dominated, and it matches |
| **mid 500–2500 m** | **+3.30** | **max +4.49 at 1160 m** (−86.9 vs −144.1 ‰) |
| bottom > 2500 m | **+1.85** | **the only layer the likelihood scores** |

⇒ The defect is **real, large, localized at intermediate depth, and unscored.** Taking that as
sufficient justification is well-founded on the evidence.

## 2. ✅ THE ISOTOPE POINT IS CORRECT, AND IT IS ALREADY HOW THE MODEL WORKS

Verified in source, not assumed. `ccx_alpha_as(sst, aux)` is a **pure function of SST** — kinetic
`eps_k` plus the equilibrium DIC-gas offset `eps_dicg`, both Zhang et al. (1995) polynomials in T —
and `add_flux()` carries a **per-direction alpha** on every limb. So a new box at its own SST gets
its fractionation **automatically, from the same function**, and the ¹⁴C limb inherits it as α₁₃²
by the Stuiver–Polach convention already implemented.
⇒ **No new fractionation decisions are needed.** That is the single biggest cost the previous ocean
additions carried, and this one does not carry it.
⚠ One check at build time: an equatorial box sits near **27 °C** against the hemispheric boxes' 18 /
16 °C. `carb_constants()` is fitted over **[2, 35] °C**, so 27 is inside — but it is near enough to
the edge to be worth asserting rather than assuming.

## 3. ⇒ THE ANSWER: IT MUST BE **CONNECTED** TO BOTH HEMISPHERES, NOT **DUPLICATED**

Three separate questions hide inside "does it need a hemispheric split":

**(a) Two boxes, NH-equatorial and SH-equatorial? — NO.**
The equatorial upwelling system is one physical feature. Duplicating it doubles the parameter count
for a symmetry the physics does not have, and DESIGN §2's pedagogy constraint argues against it.

**(b) Must it exchange with BOTH atmospheric boxes? — YES, and this is the real content of the
question. But the partition can be a CONSTANT, not a fitted parameter.**
A box straddling the equator must split its air-sea flux between the two atmospheric hemispheres.
**Measured, that new cross-equatorial conduit is negligible against atmospheric mixing:**

| band | ocean area | gross air-sea | cross-eq conduit | vs atmospheric mixing |
|---|---|---|---|---|
| 5 °S–5 °N | 9.5 % | 7.2 GtC/yr | 3.6 | **1.04 %** |
| 10 °S–10 °N | 18.8 % | 14.2 | 7.1 | **2.07 %** |
| 15 °S–15 °N | 28.2 % | 21.3 | 10.6 | **3.10 %** |
| 20 °S–20 °N | 36.8 % | 27.8 | 13.9 | **4.05 %** |

against `(atm C / 2) / tau_ex` = **343 GtC/yr** one way. ⇒ **The atmosphere mixes 25–100× faster
than the ocean route.** So the partition barely moves anything: **set it from AREA as a fixed
constant and do not fit it.** Two consequences worth stating in advance:
- ✅ It **will not wreck the CO₂ gradient**, which currently passes gate H's control at −1.06 se.
- ⛔ It **will not fix the δ¹³C gradient** either. Gate H's 2× contrast is not this box's job, and
  claiming it would be is unsupported.

**(c) Must it draw from BOTH hemispheric interiors? — YES.**
Equatorial upwelling is fed by thermocline water subducted in **both** subtropics. So the box needs
two interior couplings, and its area must be carved out of **both** `OCEAN_AREA_NH` and
`OCEAN_AREA_SH`. ⚠ Both are `status = "provisional"` constants with **no cited source**, so the
carve-out changes provisional numbers — flag it, do not quietly re-partition them.

⇒ **Minimal structure: ONE box, TWO atmospheric couplings fixed by area, TWO interior couplings.**

---

## 4. ⚠⚠ TWO CAUTIONS, BOTH MEASURED, BOTH TO BE SETTLED BEFORE CODE

**(i) THE MODEL IS ALREADY OVER-VENTILATED WHERE THE BOX WOULD ADD VENTILATION.**
§1's profile says the interior is **too YOUNG** below ~600 m — over-ventilated — and an upwelling
box **adds** ventilation. The case for it improving the profile is that it replaces *diffusive*
(smearing) transport with *advective* (structured) transport and so sharpens the gradient. **That is
a hypothesis, not a measurement**, and it is the one the whole design rests on.
⇒ **It should be pre-registered and checked on the profile SHAPE before adoption**, not after.
⚠ And it should **not** be expected to close the Joos gap: transport and capacity already point
opposite ways (an over-ventilated interior should take up MORE anthropogenic carbon, yet IRF(100) is
too LOW), which argues that shortfall is buffer chemistry.

**(ii) §3.4a's EVIDENCE GATE IS NOT YET SATISFIED ON THIS ROW, AND I COULD NOT SATISFY IT TODAY.**
DESIGN §3.4a licenses new structure "exactly when the cheaper candidates are measured and shown
insufficient". **Candidate A — depth-dependent `K_z`, one parameter, no new box — was scored in
August on the DEEP row only. It has never been scored on the intermediate rows**, and it is the
literature's own answer to precisely this tension (Siegenthaler & Joos 1992).
⛔ **I tried to measure it and could not.** `diag_ocean_candidates.R`'s shim overrides R's
`ccx_deriv`, and **mutation-testing it shows it is INERT on `ccx_spinup()`** (deep Δ¹⁴C −156.145
with the shim on and off, identical): the preindustrial ocean is built **analytically**, with the
isotope state from a **linear operator solve**, not by integrating the derivative. So candidate A's
steady-state profile needs `iso_operator()` changed as well — **a larger change than "the diffusion
loop already accepts a coefficient vector" suggests.**
⇒ **This is the one thing I would settle before writing the box**: if a depth-dependent `K` fixes
the 500–2500 m band, it does so with one parameter and no new box, and §3.4a says it wins.
