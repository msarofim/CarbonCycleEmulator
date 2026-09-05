# PRE-REGISTRATION — does a HILDA-style HIGH-LATITUDE CONDUIT fix the
# intermediate-depth D14C profile?
# Written 2026-09-04k BEFORE `calibration/diag_hilda_conduit.R` existed or ran.

Marcus: *"Yes, test the Hilda approach."*

## The claim under test

2026-09-04k measured that **in HILDA, `K(z)` ventilates the UPPER ocean and the high-latitude
conduit (`u`: HS↔HD, `q`: HD↔Interior) ventilates the DEEP** — their fitted deep diffusivity is
**K₀ = 465 m²/yr**. Our model has no conduit, so `K` must do both, and every arm tested needs a deep
K of **2519–6356**, i.e. **5–14× HILDA's**. The hypothesis is that **that over-mixed interior IS our
intermediate-water defect** (mean z **+3.30** over 500–2500 m, max **+4.49** at 1160 m).

⇒ **If the hypothesis is right, giving the deep its own ventilation pathway should let `kz` FALL,
and a lower `kz` should AGE the intermediate water toward the observations.**

## Why this is NOT `w_out`, which was measured and failed

`w_out` lifts bottom water to the mixed layer in one step and returns it **DISTRIBUTED DOWNWARD
through every layer** — so it injects surface water directly into the intermediate boxes, which is
why it over-ventilates them. **HILDA's HD exchanges with the Interior as a reservoir; the Interior's
intermediate layers are never injected with surface water.** The reduced form tested here is
therefore a **two-way exchange between the mixed layer and the BOTTOM box only, with NO distributed
return** — the one conduit geometry that has never been measured.

⚠ **THIS IS A REDUCED FORM, NOT HILDA.** Representing HS and HD as real boxes changes the state
vector, which a shim cannot do. What is tested is the conduit's **GEOMETRY** — a surface-to-deep
pathway that bypasses the interior — not its temperature, not its 16 %-of-area surface, and not the
poorly-equilibrated Δ¹⁴C that HILDA's HS box carries (**−120 ‰** prescribed, against LS's −40 ‰).
**A positive result licenses building it properly; it does not license quoting these numbers as
HILDA's.**

## P0 — CONSERVATION, scored first
**PREDICT: total carbon is conserved across the conduit to ~1e-10 relative**, the repo's standing
closure tolerance. **FALSIFIER: it is not** ⇒ the shim is wrong and nothing below is read.

## P1 — THE MECHANISM: does the conduit relieve `kz`?
**PREDICT: at iso-deep, `kz` FALLS monotonically as the conduit rate `u` rises**, because the
conduit takes over the deep's ventilation.
**FALSIFIER: `kz` rises or is flat** ⇒ the conduit is not doing the job the HILDA reading assigns
it, and P2 is uninterpretable.

## P2 — THE RESULT: does the intermediate profile improve?
**PREDICT: the scored mean |z| over depths > 1500 m FALLS below the incumbent's 2.55.**
**FALSIFIER: it does not fall** ⇒ the HILDA reading is wrong about our defect, and a high-latitude
conduit is not indicated by the profile either — which would leave the equatorial box's ENSO
motivation as the only one standing.

## P3 — THE SHAPE, and the one that would make it convincing
**PREDICT: the improvement is concentrated at 1622 m and 2268 m** (currently z +3.25 / +2.57 in the
scored band) rather than spread evenly, because that is where the over-mixing sits.
⚠ Weakest of the three: with only three scored layers this is a weak shape claim and is labelled so
in advance.

## What is NOT claimed
- **Nothing implemented, fitted or adopted.** `kz` is the only parameter re-solved; the other 25 are
  held at `ent26`.
- **Preindustrial steady state only**, so the scored band is **> 1500 m** where the bomb addition is
  ≤ 4.5 ‰. The error's PEAK (1160 m) is outside it and is printed unscored.
- **No claim that this closes the Joos gap.** Transport and capacity already point opposite ways.
