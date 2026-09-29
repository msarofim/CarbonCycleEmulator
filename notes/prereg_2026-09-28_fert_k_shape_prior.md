# Pre-registration — the fert_k SHAPE-prior arm (`hilda_csl3v0k`)

**Written before launch, 2026-09-28.** Rulings (Marcus, 2026-09-28): implement the saturation
mechanisms with good support; take the SHAPE from Varney 2024, Walker 2021 and physiology, with
CMIP6 as a comparison; leave the SIZE to the record; prior width "moderate" (log-sd 0.35);
φ = 0 only. Joos is **not** a target and is reported only.

## The arm
- Label **`hilda_csl3v0k`** = `hilda_csl3v0` (φ = 0) + `fert_k_prior = 1`. Canonical pins, seas_ml 1,
  solved pump field. Every other label and the frozen objective #13 are bit-exact (tested).
- Prior: lognormal on `fert_k`, **median 545.7 ppm, log-sd 0.35** (1-sd [385, 774]), inside the
  existing [20, 2000] box. `data-raw/build_fert_k_prior.R` → `data/prior_fert_k.rds`:
  - Walker 2021 §II.1 canopy β 0.60 (280–400) and 0.46 (400–550) → K 510.8 (R 1.76).
  - Varney 2024 §3.3 β_NPP 2.37 (2×) and 1.44 (4×) → K 582.9 (R 1.82).
  - CMIP6 GPP comparison (not used): median R 1.81 → K ≈ 568–580.
  - The leaf-level Farquhar bracket is PENDING (Bernacchi 2001 constants unread, paywalled).
- `beta_max` keeps its flat [0, 3] prior. Nothing constrains the size of the response.
- **Reference arm:** the unconstrained φ = 0 24-start multistart, Torch job 18723994 (running).
  Single-start φ = 0 mode for now: logpost −1424.63, `fert_k` 938, `beta_max` 2.717.

## The one fact that frames every prediction
Measured before launch: the prior's whole pull, from 938 to 546, is **+1.74 log units** (938 → 800:
+0.76; → 700: +1.24; → 600: +1.61). The 09-28 frozen profile priced `fert_k` 500 at −54 under φ = 0
with 27 parameters held. A refit cuts that by an unknown amount. **So this arm is a MEASUREMENT of
how strongly the record resists the evidence-based shape**, not a guarantee of that shape.

## Predictions
- **P1 (exact, by optimality — a gate, not a guess).** Compare on LIKELIHOOD: the v0k mode's log-lik
  is no more than **1.74** below the free φ = 0 mode's (the prior gain bounds the log-lik loss). A
  larger loss means the v0k search failed to converge, or the free mode is not the true free optimum.
- **P2 (the pull).** `fert_k` lands in [546, 938]. **My lean: 700–900** — the record wins most of the
  way, because a refit is unlikely to cut the frozen −54 below ~2. If it lands below 650, the record
  was nearly indifferent to shape once everything else could move, and the evidence decides it.
- **P3 (directional, from the 09-28 profile's monotone relations).** Relative to the free φ = 0 mode:
  `beta_max` ≤ 2.72, FACE-equivalent (400→564) ≤ 24.5 %, PD100 IRF@100 ≥ 0.344.
- **P4 (comparisons, reported, not scored).** CMIP6 shape (R ≈ 1.8) and size (+16.9 ± 6.2 % at
  400→564); FACE (+10–23 %); Joos IRF@100 0.409.

## What would change the plan
- `fert_k` stays > 850: the record rejects the evidence at this width. Options for Marcus: accept it
  (report the tension), tighten the prior (a ruling), or look for the missing process that makes a
  saturating shape fit the record (the frozen `fert_k`/`rep_dC` tie of 08-25 is the first suspect).
- P1 violated: stop and debug before reading anything else.

---

## RESULTS (appended 2026-09-28 evening; predictions above are unedited)
Torch job 18729847, 24 starts, collected → `calibration/output/multistart_20260928c_hilda_csl3v0k_…/`.
7 of 24 CONVERGED by the collector's rule; 10 more ran out of wall time AT a basin value to 4 dp.
Two basins, 0.088 apart, the same `h_ml` split (57.4 / 49.8 m) as the free φ = 0 array
(18723994: basins −1424.6273 / −1424.7110). Likelihoods from `promote_multistart_mode.R` into
scratch (sum of streams; prior + Jacobian gap < 1e-13).

| | `hilda29l` (φ 0.5) | φ 0 free, basin 1 / 2 | φ 0 + shape, basin 1 / 2 |
|---|---|---|---|
| log-lik | −1391.81 | −1390.46 / −1389.47 | −1391.10 / −1390.11 |
| `fert_k` (ppm) | 825 | 938.1 / 938.4 | **864.6 / 865.7** |
| `beta_max` | 1.31 | 2.716 / 2.717 | 2.546 / 2.549 |
| FACE-eq 400→564 | 14.4 % | 24.53 / 24.54 % | 24.19 / 24.20 % |
| PD100 atm @ 100 yr (GtC) | 28.9 | 34.4 / 34.3 | 34.5 / 34.4 |
| shape R = gain(4×)/gain(2×) | — | 2.06 | 2.02 |

(R from MM: 3(K+278)/(K+834); log ≡ 2.0; evidence ~1.8.)

- **P1 PASS, every form.** Exact optimality bound (the free arm's objective = logpost − lnN(`fert_k`)
  + the flat density): margin **+0.20** (basin 1), +0.11 (basin 2). Same-basin log-lik loss
  **0.64** / 0.64. Prereg wording (bare log-lik vs the free arm's best log-lik, which is basin 2):
  basin 1 loses 1.64, basin 2 loses 0.64, both ≤ 1.74. ⚠ The cross-basin reading passes by 0.10
  only because of an `h_ml` prior difference unrelated to `fert_k`; the exact form is the gate.
- **P2 PASS, inside the lean (700–900): `fert_k` 865.** The record wins. The prior moved it 15 % of
  the way to 546 in log space (log 938/865 = 0.081 of log 938/546 = 0.541). **The plan-change clause
  "`fert_k` stays > 850" is TRIGGERED.**
- **P3 PASS on all three, but P3's IRF clause passes on rounding:** `beta_max` 2.546 ≤ 2.72; FACE
  24.19 ≤ 24.5 %; IRF@100 0.345 / 0.344 ≥ 0.344. The pulse did not move (+0.1 GtC).
- **P4:** FACE-equivalent 24.2 % sits above FACE (+10–23 %) and above CMIP6 (+16.9 ± 6.2 %,
  i.e. +1.2 sd). Shape R 2.02 vs CMIP6 median 1.81 / Varney 1.82. Joos IRF@100 0.409 vs 0.345.
- **Price of the shape.** The record charged 0.64 log-lik for a 0.081 log-shift in `fert_k`. A
  QUADRATIC extrapolation (my estimate, not measured) puts the full move to 546 at ~28 log-lik,
  roughly half the frozen −54.
- **Reading.** At log-sd 0.35 the prior barely changes anything: `beta_max` drops as `fert_k` falls, so
  the present-day slope, the FACE-equivalent and the pulse stay put. The record pins the land's
  sensitivity AND, weakly, its shape. The three options in "What would change the plan" are Marcus's.
