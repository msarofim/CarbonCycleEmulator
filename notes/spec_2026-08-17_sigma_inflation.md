# SPEC — σ-inflation for the ocean-gradient rows (handoff 16g open item 4)

**Status: SPEC ONLY. Nothing implemented, nothing proposed for the objective.** This exists so the
decision is taken on a concrete design with named gates and a stated cost, rather than in the
abstract. **Marcus's call** — it is a likelihood redesign.

Written 2026-08-17, while the two-arm refit was running. Prerequisite that unblocked it: all three
rows' `σ_rep` are now measured (`calibration/diag_alk_sigma_rep.R`; the alkalinity row was the last
one missing, and 16g's reason for it being missing was wrong — see that file's README).

---

## 1. What it replaces, and which of the two defects it fixes

Today the three rows are scored only inside `LIK_OCEAN_GRAD_HML_OK = c(85, 120)` and contribute
**exactly 0** outside. 16g decomposed the resulting 10.0-log-unit cliff into two separable defects:

- **(A) a barrier** — the discontinuity itself, the MCMC hazard.
- **(B) an incentive** — a skipped Gaussian pays 0 where a live one pays a negative number, so
  leaving the band is a *free gain*.

A taper fixes (A) and provably not (B) (16g §2.2 — an identity, not a measurement: for any weight on
a negative row sum, `d/dw < 0`). **σ-inflation is the only candidate on the table that addresses both
while leaving `h_ml` free**, because the gain from leaving becomes *bounded* and *charged for*
instead of unbounded and free.

**It does NOT fix the pull.** 16g §2.3 is unconditional: the rows are not why `h_ml` leaves the band
(a 236-log-unit pull against a 10.0 cliff; deleting the rows moves the argmax 32 → 32 m). Inflation
is a fix for the *formulation*, not for `h_ml`'s preference. Anyone reading this as "the alternative
to bounding `h_ml`" should read §6 first.

## 2. The form

For each row `r ∈ {dic, d13c, alk}`, replace the hard skip with

```
σ_eff,r(h)² = σ_obs,r² + σ_rep,r(h)²
logL_r(h)   = dnorm(model_grad_r(h), target_r, σ_eff,r(h), log = TRUE)
```

**The normalisation term `−log(σ_eff √(2π))` is RETAINED.** This is the whole mechanism: without it,
inflating σ would be free and the design would collapse back into a taper. With it, widening is
*charged for*, and the best any inflation can do at a miss of `m` is `σ_eff = |m|`, giving
`−log(|m|√(2π)) − ½`. Bounded, and the bound is what makes (B) tractable.

**`σ_rep` is measured, not tuned.** It is the gap between the shipped fixed-depth target and the
like-for-like target read on the model's own box edges at that `h_ml` — both computed from
observations, by the same recipe that built the shipped target. There is no free parameter here and
none may be introduced.

## 3. THE ASSUMPTION, stated rather than buried

**`σ_rep` is a BIAS, not a random error, and adding it in quadrature is a convention, not a theorem.**
The like-for-like and fixed-depth targets are two definitions of the same quantity; their difference
is deterministic given `h_ml`, not a draw. Carrying a representation error as extra variance is the
standard move and it is defensible — it says "we do not know which definition is right, so widen to
cover both" — but it is an assumption and it should be written into `R/likelihood.R` as one.

The alternative (subtracting the bias, i.e. scoring against the like-for-like target directly) was
already **rejected** for a reason that still holds: a target anchored on the model's own boxes is a
function of `h_ml`, its penalty falls 81 → 53 log-units across `h_ml` 50 → 220, and it therefore
*rewards a large `h_ml`* — pushing against the very thing the pump exists to fix
(`R/likelihood.R`, the fixed-depth TARGET bullet). **So the choice is inflation or the status quo,
not inflation or bias-correction.**

## 4. Implementation

**`σ_rep` must be a BUILD PRODUCT, not a runtime computation.** Computing it inside the likelihood
would mean re-binning ~465k GLODAP bottles onto the model's box edges at every evaluation — the same
impossibility that made the DIC profile a build product (`build_glodap_deep_targets.R`, the
2026-08-16c note). So:

1. **Extend `data-raw/build_glodap_deep_targets.R`** to emit `sigma_rep` for all three rows on a
   grid of `h_ml`, stored in `data/obs_glodap_deep.rds` alongside the targets.
   - **Grid:** denser than the diagnostic's. Proposed 2 m over [80, 130] (the curve's floor and the
     old band) and 5 m over the rest of `h_ml`'s prior support [30, 200]. The floor is near 102 and
     under-resolving it is the one place interpolation error matters.
   - **`h_ml` = 30 is not evaluable** in the objective (`qlogis(0)` = −Inf) but the anchor grid should
     still reach it so interpolation never extrapolates.
2. **Interpolate with PCHIP**, not a spline and not a parametric fit — house rule, and here it is
   load-bearing: `σ_rep` is U-shaped and must stay **≥ 0**, which a cubic spline can violate by
   overshoot near the floor.
3. **`σ_obs`** is each row's shipped `sd` (the conservative blk60) — unchanged, and **not** the
   tighter blk30. Do not quietly switch blocks while changing the σ story; that is exactly the
   confusion 16g's receipt check untangled.
4. **`LIK_OCEAN_GRAD_HML_OK` stops being a switch.** Keep the constant, demote it to a **reported
   diagnostic flag** — `by_stream` should still make it visible when a fit or a chain is living
   outside the range the targets were derived for. Losing that visibility is a real cost of this
   change and should not be paid silently.

## 5. GATES — what must be asserted before it ships

Non-negotiable, and each states what a failure would mean:

- **G-PARITY.** At `h_ml` = 100 the model's surface box *is* the shipped 0–100 m layer (already
  asserted, `diag_alk_sigma_rep.R` G3), so `σ_rep` is at its floor and the inflated objective must
  reproduce the current in-band objective to within the floor's own contribution. **A failure means
  the inflation changed the in-band answer**, which it must not.
- **G-CONTINUITY.** Sweep `h_ml` at 0.02 m across both old band edges; the jump must be
  indistinguishable from the local slope. **Use 16g P1's ratio bar, not an absolute one** — an
  absolute bar collided with ~8 log-units/m of legitimate drift and had to be re-derived.
- **G-POSITIVITY.** `σ_eff ≥ σ_obs` and `σ_rep ≥ 0` at every anchor and every interpolated point.
  This is the gate PCHIP is chosen to satisfy.
- **G-INTERP.** Leave-one-out at build time: PCHIP through the remaining anchors reproduces each
  held-out measured `σ_rep` to a stated tolerance. **A failure means the grid is too coarse**, and
  the fix is more anchors, never a looser bar.
- **G-MUTATION.** Per the house rule that a passing gate is not a working gate: perturb `σ_rep` by
  ×2 and confirm G-PARITY and G-CONTINUITY actually move. A gate that passes under a doubled
  representation error is not testing anything.
- **G-BUILD-PARITY.** The extended build must leave the existing targets **bit-identical**
  (`grad` is already built before the new section, and `gd_grad_boot()` re-seeds per call — the
  2026-08-16b addition established this pattern and it must be preserved).

## 6. THE COST, and the number that must be RE-DERIVED before deciding

16g priced inflation's best case at **21 % of what the skip gives away (2.14 of 10.01 log-units)** —
and flagged that as a **FAILED prediction in the direction that strengthens inflation** (predicted
> 50 %; the reasoning was wrong, not the bar: at ~1.8σ misses `z²/2 ≈ 1.6` while `−log(σ√2π)` carries
the bulk).

**⚠️ THAT 2.14 WAS COMPUTED WITH ALKALINITY'S `σ_rep` UNAVAILABLE.** It must be re-derived across all
three rows before it is quoted as the cost of this design. Expect a **small** change — ALK's
`σ_rep/σ_obs` is 0.02–0.07 in band and 0.02–0.34 overall, the smallest of the three — but *expecting*
small is not measuring it, and this is precisely the sort of number that gets quoted for three
handoffs. **Re-deriving it needs the model's own gradient at each `h_ml` (16g part 4b), so it is
post-refit work.**

Also unresolved and worth stating: inflation still leaves a residual incentive to leave the band,
because `σ_rep` grows away from 100 and so the penalty softens. It is bounded and charged for — that
is the improvement — but it is **not zero**, and this design should not be sold as removing (B)
entirely.

## 7. What a decision needs

| input | status |
|---|---|
| `σ_rep` for all three rows | **DONE** — 16g part 4 (DIC, δ¹³C) + `diag_alk_sigma_rep.R` (ALK) |
| the form, and that normalisation is retained | **DONE** — §2 |
| the quadrature assumption, stated | **DONE** — §3 |
| build/interpolation design + gates | **DONE** — §4, §5 |
| **the cost, re-derived over all three rows** | **BLOCKED on the refit** — §6 |
| the sampler question | **OPEN** — a hard bound is defensible for a mode-find and a weaker claim for a chain (16g item 6). This design's case is strongest *for the posterior run*, not for the current refit. |

**Recommendation, offered not taken:** decide this **after** §5.3, not before. If the CO₂-level
streams recovered under the bound, the bound was cheap and inflation is a posterior-run question. If
they did not, inflation with `h_ml` free is the live alternative and §6's re-derivation becomes the
first thing to run.
