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
