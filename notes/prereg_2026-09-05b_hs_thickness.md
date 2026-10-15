# PRE-REGISTRATION — does HS at **HILDA's own 75 m** close the gap that
# `notes/collect_2026-09-05_hilda_boxes.md` left open?
# Written 2026-09-05b, BEFORE `h_hs` existed as a parameter.

Follows the first build. **This tests choice C2's DECLARED ALTERNATIVE and nothing else** — one
number moves, and it moves to the value the source uses.

## Why this test, and why it is not fishing

§2 of the collect note explains P1's shortfall QUANTITATIVELY and the explanation makes a prediction
that has not been tested:

| | ours | HILDA | ratio |
|---|---|---|---|
| gross air-sea invasion at 280 ppm | 29.80 mol m⁻² yr⁻¹ | 15.1 ± 1.2 | **1.97×** |
| HS thickness | **134.1 m** (= `h_ml`, choice C2) | **75 m** | 1.79× |
| HS residence at `u` = 38 | 3.53 yr | 1.97 yr | 1.79× |

Isotopic equilibration scales as thickness / gas exchange = 1.79 / 1.97 = **0.91**, while residence
scales as **1.79**. So the residence-to-equilibration ratio is ≈ **1.97×** HILDA's, and HS gets
about twice as far toward atmospheric equilibrium — which is why it emerges at **−80.3 ‰** against
HILDA's −111 (model) / −120 ± 30 (GEOSECS).

⇒ **Cutting HS to 75 m removes the 1.79 and leaves only the 0.91**, so the ratio should fall to
about **1.10×** HILDA's. **`k_w` is NOT touched** — it is a fitted parameter of the low-latitude
column and moving it here would be tuning, not testing.

## P1b — THE ENDMEMBER
**PREDICT: HS falls from −80.3 to below −95 ‰**, i.e. it moves at least halfway from where it is to
HILDA's own −111, and lands INSIDE HILDA's −120 ± 30 rather than 0.3 ‰ inside a broadened window.
**FALSIFIER: HS ends above −90** ⇒ §2's arithmetic is wrong about which term dominates, and the
shortfall is not the thickness.

## P2b — THE CROSSOVER, which is the one that decides P4
§3 of the collect note located the failure: **HD (−109.2) is YOUNGER than the interior everywhere
below ~1000 m**, so `q` ventilates exactly the layers that are already over-ventilated. A colder,
less equilibrated HS feeds an OLDER HD.
**PREDICT: HD falls below −125 ‰, and the HD-minus-interior crossover moves DEEPER than 1160 m.**
**FALSIFIER: the crossover stays at or above 1160 m** ⇒ the sign problem is structural in the
attachment of `q`, not in HS's equilibration, and only the second follow-up (the attachment depth)
can address it.

## P4b — THE RESULT
**PREDICT: scored mean |z| over > 1500 m falls below the 2.05 this structure gives at 134 m.**
⚠ **Beating the reduced form's 1.81 is NOT predicted.** The honest expectation is that thickness
buys part of it and the attachment sign buys the rest; a value between 1.81 and 2.05 confirms this
note without settling P4.
**FALSIFIER: mean |z| ≥ 2.05** ⇒ thickness is not a lever on the scored band at all.

## N1b — THE CONTROL, rebuilt because the first one was compromised
The collect note's §4 retracts N1's LEVEL: at a preindustrial steady state the ≤ 500 m band is
dominated by the ABSENT bomb spike, so its mean |z| of 4.5 is an artifact, not a ventilation error.
**The valid control is the DELTA between arms, which shares that artifact.**
**PREDICT: the ≤ 500 m band does not degrade relative to the 134 m arm's 3.98 by more than 0.5 z.**
**FALSIFIER: it does** ⇒ a thinner HS is buying the deep at the surface's expense.

## O1 — THE OUT-OF-SAMPLE OBSERVATION, carried forward from the collect note's §5
GEOSECS puts the low-latitude surface at **−40 ± 20 ‰** (HILDA Table 2) and nothing in our
likelihood scores it.
**PREDICT: the LS mixed layer stays inside [−60, −20].** Reported for every arm, and an arm that
leaves the interval is EXCLUDED regardless of what it does to the scored band — the same call that
excluded τ_q = 28 in the first round.

## What is NOT claimed
- **One parameter moves.** `hs_frac`, `u_hs`, `tau_q`, `sst_hs`, `k_w` and all 26 fitted parameters
  stay where they are; `kz` is re-solved iso-deep, as in every arm of this arc.
- **`h_hs` = 0 must remain BIT-EXACT** with the 2026-09-05 build, i.e. absence still means "follow
  `h_ml`". That is P0b and it is scored first.
- **Nothing about the attachment depth of `q`**, which is the OTHER follow-up §6 names and which
  DEPARTS from HILDA's Fig. 1. It is deliberately not bundled in here: if both moved at once,
  neither would be attributable.
