# PREREG 2026-08-28b — **PRICING σ-INFLATION AT THE PROFILE'S OWN VECTORS**
# The measurement 08-28 §6 proposed, done as a TWO-SIDED BRACKET first, with the
# 26-point refit held in reserve for the case where the bracket fails to separate.
# Committed BEFORE the driver exists.

**State:** repo clean at `c76465c`, suite 1164 / 0. A Julia SLR job (`postprocess_mcmc_ext.jl`,
pid 89548, `SLR-RFF-BRICK`) is using ~1 core; load avg 3.9 on 10 cores. Stage A is seconds of
compute, so it does not contend. **Stage B is not launched by this prereg.**

**Marcus 2026-08-28: "I would profile `h_ml`, but lean towards option 5 as being more
scientifically appropriate."** The profile is done (§5 of the 08-28 handoff). This prices option 5.

---

## 1. WHY A BRACKET INSTEAD OF THE REFIT §6 PROPOSED

08-28 §6 proposed re-running the out-of-band profile points with inflation ON and reading the
argmax. That is right in substance, but the refit is not needed to answer it, because **both sides
of the answer are boundable exactly from artifacts already on disk.**

`outputs/diagnostics/hml_unbound_profile.rds` stores the **full 21-parameter vector** at each of
the 26 profiled `h_ml`. σ_rep(h) is measured for all three rows on a common 30-point grid:
`hml_band_discontinuity.rds` (DIC, δ¹³C — 16g part 4) and `alk_sigma_rep.rds` (ALK — 08-18).
So for every grid point:

    LOWER(h) = lp_shipped(h) − rows_shipped(h) + rows_inflated_at_the_STORED_vector(h)
    UPPER(h) = lp_shipped(h) − rows_shipped(h) + Σ_rows −log(√(2π) σ_eff(h))

`rows_shipped(h)` is the σ_obs value in band and **exactly 0 out of band** (the skip).
`σ_eff(h)² = σ_obs² + σ_rep(h)²`, dnorm's normalization **retained**, which is what makes
inflation charged-for rather than free (16g §2.4).

**Both bounds are rigorous, in opposite directions, for the SAME reason:** re-optimizing the five
free parameters with the rows switched on can only *raise* the objective above its value at the
stored vector (LOWER), and can never raise any row above its own density peak (UPPER). So the
value the §6 refit would report at each `h` lies in `[LOWER(h), UPPER(h)]`, and

**if `max UPPER over out-of-band h` < `max LOWER over in-band h`, the argmax is PROVABLY in-band
and Stage B is unnecessary.**

⚠ **σ_rep is interpolated by PCHIP through the 30 measured points, never fitted.** The grids
differ (profile 26 points, σ_rep 30) and 4 of the profile's points are edge-straddles.

## 2. WHY §6's ~1.6 RESIDUAL IS ALREADY SUSPECT — THE PRE-CHECK

§6 wrote: at 16g's "21 % residual", inflation on §5's 7.30 cliff leaves ≈1.53, an 80 % reduction
**not** an elimination. **That multiplies 16g's ratio by a base that is not 16g's.**

16g measured **2.14 of 10.01** — a *difference*, `in-band row cost − out-of-band inflated row
cost`, expressed as a fraction of ITS OWN in-band cost of 10.01. **The relief is that difference,
and the subtrahend is set by the σ's, not by the base.** §5's in-band cost is **7.30**, not 10.01,
and the out-of-band inflated cost is ~7.1–7.5 across the whole grid. Recomputed from the measured
σ's, the density-peak ceiling is:

    h = 32 m   ceiling −7.481      h = 75 m   ceiling −7.095      h ≈ 96.5 m  ceiling −6.824

⇒ at §5's argmax of 75 m the rows must cost **at least 7.095**, against a lead of **+7.74**. The
relief is **≤ 0.645**, i.e. **≤ 9 % of 7.30, not 21 %** — and at 32 m it is **negative**
(7.30 − 7.481), meaning inflation would score 32 m *worse* than in-band scoring does.
**[[ratio_needs_its_base]] — Marcus's own promoted convention, and the previous session walked
into it.**

⚠ **The 21 % itself is not wrong**; it is a correct measurement of a different configuration
(16g's frozen-19 vectors, and DIC + δ¹³C only — ALK's σ_rep did not exist until 08-18).

## 3. PRE-REGISTERED PREDICTIONS

- **G1 — THE HEADLINE. The bracket SEPARATES and the argmax is provably INSIDE [85, 120].**
  *Bar:* `max UPPER(out-of-band) < max LOWER(in-band)`.
  *Falsifier:* overlap ⇒ the bracket is not decisive and **Stage B is owed** — the 26-point refit
  with inflation ON, which is then the only way to read the argmax.
- **G2 — §6's ~1.6 RESIDUAL PULL DOES NOT REPRODUCE.** *Bar:* the residual pull, `max UPPER
  (out-of-band) − max LOWER(in-band)`, is **≤ 0.7 log-units** (the refit's own restart noise
  floor, 08-28 §6). *Falsifier:* > 0.7 ⇒ §6's inference stands in magnitude even if its arithmetic
  was reached the wrong way, and inflation demonstrably does not close the free lunch alone.
  ⚠ **This is a prediction AGAINST the previous session's own stated conclusion.**
- **G3 — THE CLIFF IS GONE.** *Bar:* `|LOWER(84.99) − LOWER(85.01)| < 1.0` and the same at 120,
  against the shipped **−7.300**. *Rationale:* inflation makes the rows a continuous function of
  `h_ml`; the only residual jump is σ_rep's own interpolation error across the straddle.
  *Falsifier:* ≥ 1.0 ⇒ something other than the skip is discontinuous at the edge and neither
  option addresses it.
- **G4 — INFLATION IS CHEAP IN BAND.** *Bar:* `|LOWER(96.4737) − lp_shipped(96.4737)| ≤ 0.3`.
  *Rationale:* σ_rep/σ_obs at the mode is 0.22 (DIC) / 0.40 (δ¹³C) / 0.05 (ALK), so the peak cost
  is ~0.10 and the misfit relief partly offsets it. *Falsifier:* > 0.3 ⇒ adopting option 5 moves
  the mode's own score materially and a refit is owed by the adoption, not just by this test.

## 4. WHAT THIS RUN DOES AND DOES NOT DECIDE

- **It does NOT implement option 5.** No objective, constant, prior, `R/` or `src/` file is
  touched. `LIK_OCEAN_GRAD_HML_OK` and the skip stay exactly as shipped. σ-inflation is computed
  **in the driver only**, and no refit is owed by anything it prints.
- **It does NOT decide the band on belief grounds.** As the 08-28 prereg §4 said, an argmax inside
  the band says the bound is *harmless at the mode*, not that truncating the posterior's softest
  direction is *right*. That remains Marcus's call and this cannot speak to it.
- ⚠ **It prices ONE variant.** σ-inflation carries the representation error as *variance*. The
  alternative — **correcting the TARGET to its like-for-like value at `h_ml`** — is a different
  remedy, is strictly more aggressive, and is measurable from the very same stored curves
  (`like_for_like` is a column in both rds). It is **not** priced here and is **not** proposed;
  it is recorded so the choice is visible rather than defaulted. [[threshold_from_obs_or_law]]
- **It cannot see anything the five free parameters could not reach.** The 08-28 prereg's one-way
  argument (5 free is conservative) applies to LOWER unchanged; UPPER is free of it entirely.

---

# AMENDMENT — **STAGE B, OWED BY G1's FAILURE.** Written after Stage A, before the Stage B driver.

Stage A ran at `1ea4922`. **G1 FAILED**: `max UPPER(out) = −1543.817` at 82 m against
`max LOWER(in) = −1544.358` at 85.01 m — an overlap of **0.541** against bracket widths of
0.50–0.65. The bracket is not decisive on the SHALLOW side. (On the deep side it is: every
`h > 120` has `LOWER` at least 6.7 BELOW the in-band maximum and `UPPER` no higher, because the
model's gradient misfits badly there — `rows_infl` runs −15.2 at 120.01 to −46.5 at 198.)

**So Stage B is the prereg's own stated remedy: re-run the 26 points with inflation ON.**

## B.1 HOW INFLATION IS APPLIED WITHOUT TOUCHING THE OBJECTIVE

`ccx_loglik()` reads its σ from `ccx_ocean_gradient_target()`, which is a cached closure and does
not see `h_ml`. Rather than duplicate `ccx_make_logpost()` — the project has already paid **309
logL of artifact** for a challenger that did not match its incumbent's path
[[match_incumbents_optim]] — Stage B uses the shipped path and an EXACT algebraic identity:

    dnorm(t, v, σ_eff, log) = dnorm(t, v', σ_obs, log) − log(σ_eff / σ_obs),
    with v' = t − (t − v) · σ_obs / σ_eff.

So `ccx_ocean_grad_scored()` is overridden **in the driver's environment only** to (a) drop the
band gate and (b) return the shrunk `v'`; the per-row constant `Σ −log(σ_eff(h)/σ_obs)` is added
to the reported logpost afterwards. **`h_ml` is FIXED at every profile point, so that constant is
constant within a point and cannot influence the optimization** — it only makes the reported
number the inflated one.

⚠ **GUARD, and the run ABORTS if it fails:** at the mode's stored vector the overridden path must
reproduce Stage A's `LOWER(96.4737) = −1544.6247` to < 1e-6. Stage A computed the same quantity by
a completely different route (direct `dnorm` at σ_eff on a separately-run gradient), so agreement
is a real cross-check of both. [[mutation_test_gates]]

## B.2 PRE-REGISTERED PREDICTIONS — AND I EXPECT B1 TO FAIL

- **B1 — the inflated argmax lands INSIDE [85, 120].** ⚠ **I PREDICT THIS FAILS.** Stage A's
  overlap is 0.541 and the 82 m vector was optimized with the rows OFF, so switching them on gives
  it real re-optimization freedom (up to its 0.55 width), while the in-band points were already
  optimized against these rows at nearly this σ and can gain ~0.13 at most. **Expected argmax
  75–85 m, just outside the lower edge.** *Falsifier of my expectation:* an in-band argmax.
- **B2 — THE HEADLINE. The residual pull is ≤ 0.70**, the refit's own restart noise floor.
  *Bar:* `best(out-of-band) − best(in-band) ≤ 0.70`. *Falsifier:* > 0.70 ⇒ inflation leaves a pull
  that is resolvable above the fit's own noise, and 08-28 §6's caution stands in magnitude.
  **This, not B1, is what decides whether option 5 closes the free lunch in practice**: an argmax
  0.2 outside a band, below the noise floor, is not a preference the fit can act on.
- **B3 — STAGE A's BRACKET HELD.** *Bar:* every point's inflated logpost lies in
  `[LOWER − 1e-6, UPPER + 1e-6]`. *Falsifier:* any violation ⇒ one of the two bounds is not
  rigorous and Stage A's reasoning is wrong, not merely imprecise.
- **B4 — THE INCENTIVE AT THE EDGES IS NOW INWARD.** *Bar:* the SIGNED jump on leaving the band is
  ≤ 0 at BOTH 85 and 120. ⚠ **Stage A's G3 was mis-specified and this replaces it**: I gated on
  `|jump|`, but a step DOWN on leaving the band is the remedy working, not a defect. Measured in
  Stage A: 85 collapses **+7.300 → −0.131**, while 120 stays large and **REVERSES SIGN**,
  **+8.426 → −6.743**. Carrying the evidence rather than the label: G3's numbers are in the
  artifact and the bar was mine. [[explained_away_test]]
