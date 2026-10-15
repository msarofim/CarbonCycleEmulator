# COLLECT 2026-08-28b — **σ-INFLATION ERASES THE FREE LUNCH: THE PULL IS 0.033, NOT 1.6**
# Stage A bracketed (`1ea4922`); Stage B refit all 26 points. **B1 ✗ (predicted) B2 ✓ B3 ✓ B4 ✓.**

Prereg `notes/prereg_2026-08-28b_sigma_inflation_pricing.md` (`15d1906`), amended (`672dd8b`)
before the Stage B driver. Drivers `calibration/diag_sigma_inflation_pricing.R` and
`diag_sigma_inflation_profile.R`. **`R/` and `src/` untouched; `LIK_OCEAN_GRAD_HML_OK` and the
skip are exactly as shipped, and no refit is owed by anything here.**

---

## 1. THE HEADLINE

**The shipped skip's pull was +7.39 log-units. With σ-inflation it is +0.033 — a 99.55 %
reduction.** 08-28 §6 inferred ~1.6, "an 80 % reduction, NOT elimination." **That is refuted by
measurement.**

    best in-band  -1544.357 at 85.01 m
    best out      -1544.324 at 82.00 m        residual pull  +0.0334

**B1 ✗ as I pre-registered I expected**: the argmax is at **82 m**, 3 m outside the lower edge.
**B2 ✓ is what decides the question**: 0.033 is **21× below** the refit's own restart noise floor
(0.70) and below the optimizer's own restart tolerance. **An argmax 3 m outside a band by 0.033
log-units is not a preference the fit can act on.**

## 2. BOTH CLIFFS ARE GONE, AND THE 120 EDGE IS THE SURPRISE

    straddle        shipped      inflated
    85 m            +7.3005      -0.0064
    120 m           +8.4257      -0.0047

**B4 ✓.** Leaving the band is now very slightly *downhill* at both edges instead of a jump onto a
free lunch. ⚠ **Stage A predicted the 120 edge would stay large at −6.74; it did not** — at
120.01 m the five free parameters recover nearly the whole 8.4 of Stage A's bracket width, which
is exactly why that bracket was wide there. **The bound was rigorous; the inference I drew from
its LOWER was not.** Stage A's own G3 gate was mis-specified on top of that (see §5).

## 3. THE OBJECTIVE IS NOW WELL-POSED IN `h_ml` WITH NO BOUND AT ALL

    32 m  -5.56   |   65-120 m  a 1.64-log-unit PLATEAU over 55 m   |   198 m  -13.03
                                             (relative to the argmax)

It has an **interior maximum** and falls away on **both** sides. **That is the substantive case
for option 5**: with the rows scored everywhere, `h_ml` no longer needs a hard bound to stay put —
the data holds it. Under the shipped skip the same profile ran to the edge of the support and had
to be stopped by a wall.

## 4. TWO THINGS THAT DID *NOT* CHANGE, AND ONE THAT DID

- ⚠ **`kz` STILL RAILS, and still inverts.** 97.9 % of its bracket at 32 m → 92.4 % at 96.47 m →
  66.1 % at 198 m. **Identical in character to §5.** Inflation does not touch it. **The `kz` rail
  is an independent open item and this arc has now twice failed to be its cause.**
- **The argmax moved 75 → 82 m** between the shipped and inflated profiles. Both are on the
  plateau; neither is resolvable against the noise floor.
- ⚠ **`pump_grad` is now IDENTIFIED EVERYWHERE: 253.5–301.7, against the shipped profile's
  226–446.** §5's **H4 ✗** could only say "rows-off ⇒ `pump_grad` unconstrained needs more freedom
  than the uptake set to appear." **This is the positive half of that test**: with the rows on at
  every `h_ml`, the quantity they exist to constrain stops wandering. It is the first direct
  evidence that those three rows do the identifying.

## 5. WHAT I GOT WRONG, CARRIED AS EVIDENCE RATHER THAN AS A LABEL

- ⚠ **08-28 §6's ~1.6 was `ratio_needs_its_base`, from inside the project.** 16g measured
  **2.14 of 10.01** — a *difference* over *its own* base. §6 multiplied the 21 % by §5's base of
  7.30. The relief's subtrahend is set by the σ's, not by the base. **16g's 21 % is not wrong**;
  it correctly describes 16g's frozen-19 configuration, DIC + δ¹³C only.
- ⚠ **Stage A's G3 gated on `|jump|` when the incentive is SIGNED.** A step *down* on leaving the
  band is the remedy working. B4 replaced it. [[explained_away_test]]
- ⚠ **I read Stage A's LOWER at 120 as a prediction.** It is a bound. §2.

**What went right and is worth reusing:** the two-sided bracket cost seconds and **B3 ✓ 26/26** —
every refit landed inside it. It correctly identified that only the shallow side was undecided,
and the guard (the override reproducing Stage A's LOWER by a completely different route) agreed at
**0.000e+00**, cross-checking both. [[mutation_test_gates]]

## 6. WHAT THIS DOES AND DOES NOT DECIDE — **MARCUS'S CALL**

- **It does NOT adopt option 5.** Nothing in `R/`/`src/` moved; inflation is computed in the
  drivers only. Adoption is a likelihood redesign and needs a full 21-param refit, because the
  conditional argmax moves 96.47 → 82 m even though the move is inside the noise.
- **It answers what §6 asked**: inflation's residual pull, measured with the model's own gradient
  rather than scaled from 16g's observation-side number, is **0.033**.
- ⚠ **It prices ONE variant.** Correcting the **target** to its like-for-like value at `h_ml` is a
  different and strictly more aggressive remedy, measurable from the same stored `like_for_like`
  columns. **Not priced here, not proposed.** [[threshold_from_obs_or_law]]
- ⚠ **It cannot speak to the belief question.** As the 08-28 prereg said: an argmax that stays put
  says the bound is *harmless*, not that truncating the posterior's softest direction is *right*.
