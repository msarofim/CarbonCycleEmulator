# GATE 4 HAS NO POWER, AND "CALIBRATION MADE THE AF SMOOTHER" IS A TREND ARTIFACT
**2026-09-04 · CarbonCycleEmulator · `calibration/diag_gate4_af_spread.R`**

Open decision 1 of `handoff_2026-09-04_ent26_adopted.md` was: *"GATE 4: why did the AF
decadal spread get SMOOTHER? 0.48x observed against defaults' 0.76x — the clearest new
lead the adoption produced."* Measured, it is not a lead. **The 0.48-vs-0.76 comparison is
a TREND artifact of the gate's own estimator**, the target it is scored against was **6.6 %
too wide and built with a DIFFERENT estimator than the model side**, and once an arm is
judged against its own trend and its own interannual amplitude **nothing decadal is left
over**. Both prior numbers reproduce exactly (0.763 / 0.478 against the retired target), so
this is a re-reading of the same measurement, not a different one.

---

## 1. The target was not what it said it was

`DG_AF_OBS_DEC` was seven typed two-decimal literals with no provenance line. Recomputed
from the same GCB budget the likelihood reads, **only one of the two natural estimators
reproduces all seven**:

| | 1960 | 1970 | 1980 | 1990 | 2000 | 2010 | 2020 | sd |
|---|---|---|---|---|---|---|---|---|
| typed (retired) | 0.35 | 0.43 | 0.47 | 0.38 | 0.42 | 0.45 | 0.50 | **0.0515** |
| mean of annual AF | 0.3534 | 0.4265 | 0.4661 | 0.3807 | 0.4245 | 0.4482 | 0.4970 | 0.0491 |
| ratio of sums | 0.3568 | 0.4303 | 0.4684 | 0.3840 | 0.4228 | 0.4483 | 0.4984 | **0.0483** |

The literals round from the **mean of annual AF**. `dg_gate4()` has always computed the
model's decadal AF as a **ratio of decade sums**. ⛔ So the gate compared a model
ratio-of-sums against an observed mean-of-annual-ratios — a like-for-like violation that 2 dp
of rounding hid in six of the seven decades; only the 1960s (0.3568 → 0.36, not 0.35)
exposes it. Both sides now go through one `dg_af_dec()`. **The gate's bound IS the sd of
this vector**, so the model was being asked to beat a spread 6.6 % larger than the
observations have. No verdict flips. Provenance pinned in `test-gate-bounds.R`.

## 2. 70 % of the target's variance is interannual noise

The interannual anomaly about a smooth AF(t) is **0.911 GtC/yr, lag-1 rho +0.014** (white).
A decade's AF therefore carries a sampling sd of 0.026–0.060 (the 2020s "decade" is 5 years):

| | 1960 | 1970 | 1980 | 1990 | 2000 | 2010 | 2020 | rms |
|---|---|---|---|---|---|---|---|---|
| analytic floor | 0.0596 | 0.0454 | 0.0406 | 0.0357 | 0.0305 | 0.0259 | 0.0360 | **0.0404** |
| matched Monte Carlo | 0.0594 | 0.0444 | 0.0401 | 0.0355 | 0.0301 | 0.0255 | 0.0347 | |

⇒ observed spread 0.0483, floor 0.0404, **resolved decadal signal 0.0265** — 70 % of the
target's variance is noise. Robust across ns df 2–5 (floor 0.0402–0.0426). The analytic se
was validated against a matched MC before anything was concluded from it (4000 draws,
`G4D_MC_SEED`).

## 3. The defaults' advantage was a DRIFT, not a wiggle

`sd()` over seven decades cannot tell a model whose AF *varies* from one whose AF *drifts*.

| arm | sd(dec) | sd(trend) | sd(detrended) | R² of trend | raw ratio | **detrended ratio** |
|---|---|---|---|---|---|---|
| GCB 2025 | 0.0483 | 0.0320 | 0.0397 | 0.439 | 1.000 | 1.000 |
| defaults | 0.0393 | 0.0323 | 0.0245 | 0.677 | 0.813 | **0.617** |
| ent26 | 0.0246 | 0.0107 | 0.0243 | 0.188 | 0.509 | **0.613** |

⭐ **Detrended, the two arms are identical to three decimals (0.0245 vs 0.0243).** The
adoption did not smooth the airborne fraction; it changed the AF **trend** (defaults
+0.0157/decade → ent26 +0.0057/decade), and the gate's statistic charged that to
variability. "Calibration made it smoother" is the wrong reading of the same number.

## 4. And the trend cannot reject either arm

Estimated on the annual series (`grow = (a + b·(y−ȳ))·emis`), the observed AF trend is
**+0.0147 ± 0.0080 per decade, t = +1.83** — not significant at 95 %. Both arms lie inside
its 95 % CI (defaults z +0.12, ent26 z −1.12). ⚠ A trend needs an error bar before it needs
an explanation; this one is 1.8σ from zero on 66 years.

## 5. The decisive test: judge each arm against ITSELF

If the shortfall is only (a) a weaker trend and (b) less interannual variance, an arm's
decadal spread should be a typical draw from a null built on **its own** fitted trend and
**its own** anomaly amplitude:

| arm | sd(dec) | own eps | null [5 % .. 50 % .. 95 %] | |
|---|---|---|---|---|
| GCB 2025 | 0.0483 | 0.911 | 0.0261 .. 0.0472 .. 0.0734 | INSIDE |
| defaults | 0.0393 | 0.638 | 0.0239 .. 0.0410 .. 0.0602 | INSIDE |
| ent26 | 0.0246 | 0.698 | 0.0165 .. 0.0303 .. 0.0489 | INSIDE |

⚠ The null draws WHITE noise while both arms' residuals are autocorrelated (rho +0.255 / +0.193
against the observations' +0.014), which inflates a decade sum's variance — so the arms' intervals
here are if anything too narrow, and they are inside anyway. The error runs in the direction that
would have caught a defect.

⇒ **Nothing decadal is left over.** Gate 4's failure decomposes entirely into a trend that
is inside the observations' own confidence interval and the already-recorded interannual
gap (`ccx_variability_gap`: the arms carry 0.70 / 0.77 of the observed anomaly sd here).

## 6. What DOES survive: the 2020s, and half of it is one year

Scored per decade against the observations' own sampling noise (§2), the only miss with
any size is the 2020s:

| z = (model − obs) / obs noise | 1960 | 1970 | 1980 | 1990 | 2000 | 2010 | 2020 |
|---|---|---|---|---|---|---|---|
| defaults | −0.15 | −0.02 | −1.80 | +0.60 | +0.38 | +0.66 | −1.33 |
| ent26 | +0.43 | +0.01 | −1.56 | +1.08 | +0.25 | +0.38 | **−2.68** |

2020–2024 atmospheric growth: model 22.92 GtC vs GCB 28.50 — a **5.58 GtC deficit**, i.e.
~1.1 GtC/yr of excess sink, and it is visible in the cumulative CO₂ rise (model−GCB goes
+0.37 ppm at 2019 → **−2.26 ppm at 2024**). `luc_scale` = 0.975 accounts for 0.16 GtC of it,
so this is not an emissions-input artifact. But **2024 alone is −2.89 GtC (52 %)** — the
record observed 7.92 GtC/yr growth the model reads as 5.03 — with 2020–2022 supplying a
steadier ~1 GtC/yr. The 2024 half is the ENSO/variability arc (Fix B, the anti-correlated
ocean ENSO response), not a new decadal finding; the 2020–2022 half is not yet attributed.

---

## ⇒ Rulings owed (DESIGN decisions — proposed, NOT adopted)

1. **Gate 4's ordering should be split, or retired.** As written it is one `sd()` that
   conflates a trend with a wiggle, scored against a target that is 70 % noise. The natural
   replacement is the §6 table: each decade against the observations' own sampling sd — a
   tolerance derived from the quantity it tests, and it is the only form here with power.
   Whether the AF **trend** gets its own claim is a separate call; at 1.8σ it can reject
   almost nothing today.
2. **Open decision 1 should be re-ranked.** It is not the clearest lead the adoption
   produced; it is the interannual gap under a decadal name. `sst_seas_amp_NH` (−3.91) and
   Fix C (P5) keep their places.

## Files

* `calibration/diag_gate4_af_spread.R` — the whole measurement (2 model runs, ~1 s).
* `calibration/output/gate4_af_spread/gate4_af_spread.rds`
* `calibration/lib_design_gates.R` — `dg_af_annual_model()` / `dg_af_annual_obs()` /
  `dg_af_dec()`; `DG_AF_OBS` and `DG_AF_OBS_DEC` are now COMPUTED, literals kept as `*_TYPED`.
* `tests/testthat/test-gate-bounds.R` — provenance of the retired literals pinned.
