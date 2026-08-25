# Pre-registration — P3's decisive test: the `luc` arm with `sigma_d14c` pinned

**Written before launch, 2026-08-25.** Discharges the P3 failure recorded in
`notes/prereg_2026-08-24c_luc_arm_persistence_vs_isotopes.md`.

## Why this run and not a cheaper one

P3 named **1.5 σ** as `sigma_d14c`'s falsifier and it moved **+1.671 σ**, so by the
pre-registration's own terms P1's −5.014 σ `rep_dC` move cannot be quoted clean.

**Three cheaper tests were run first and two of them have no power.** Recorded because a null with
no power reads exactly like a null with power:

- **T1 structural.** `rep_dC` enters the CO₂ and δ¹³C station terms only (`likelihood.R:1105,
  1251`); `sigma_d14c` enters the Δ¹⁴C terms only. ρ(`rep_dC`, `sigma_d14c`) = **−0.146** in the
  reference posterior (−0.285 in the arm). `rep_dC`'s real partners are **`k_w` −0.784** and
  **`bomb_total` −0.731**, and both moved hard in the arm (+5.685, +4.522 σ).
- **T3 fixed-state re-optimisation — VACUOUS, and measured to be.** Resetting `sigma_d14c` to the
  reference moves the 1-D `rep_dC` argmax by **exactly 0.000 ppm**, in both the arm and the
  control. Per this project's own rule, all-exactly-zero is treated as a code path until disproven,
  so it was **mutation-tested**: across `sigma_d14c` ∈ {2, 6.13, 7.22, 20, 60} the argmax is
  **bit-identical to 6 decimals** while the peak moves **~200 log-units**. The zero is genuine
  additive separability, not a dead path — which means **T3 could never have detected contamination**
  and its null is worth nothing.
- **T2 covariance-predicted.** Conditioning the reference Gaussian on the other 20 coordinates'
  observed moves predicts **−9.227 σ** for `rep_dC`; the measured move is **−5.014 σ**, an
  unexplained residual of **+4.213 σ**. So the move is **not** a pure slide along the posterior —
  but T2 cannot separate "the arm did real work" from "the arm's likelihood resisted the slide".

**Contamination, if it exists, runs through the model state** — parameters that moved because a
wider ¹⁴C error bar let them — so only a refit with `sigma_d14c` held can settle it.

## What is run

Identical to `calibration/output/luc_arm_pinluc/` in every setting — arm N, `CCX_SINK_MODE=luc`,
rate 2.5, `luc_scale` pinned 0.898400, `RESTARTS=8 CYCLES=2`, h_ml [85, 120] — **plus**
`sigma_d14c` pinned at the reference **6.125078** via the generalised `CCX_PIN_PARAMS`. Output
`calibration/output/luc_arm_pin2/` — SCRATCH.

## Predictions

Δσ against the **rate-0 reference** (`rep_dC` 5.5658, sd 0.2433). Pinned arms' logposts and
evidence are **not** comparable to free ones.

- **P1′ (predicted): Δ`rep_dC` stays at ≤ −3.5 σ**, i.e. it keeps most of the −5.014.
  *Falsifier:* > −2.0 σ, which would mean **half or more of the move was bought by the widened ¹⁴C
  error bar** and the persistence reading of 08-24c must be withdrawn, not merely caveated.
- **P2′ the two ¹⁴C streams get WORSE than in the free-σ arm.** In the free arm `d14c_NH`/`d14c_SH`
  already degraded (−6.75 / −13.16) *despite* σ inflating; with σ held they must degrade further.
  Predicted a further −5 to −40 log-units combined. *Falsifier:* they improve.
- **P3′ the (`beta_max`, `fert_k`) ridge moves at least as far as the free-σ arm's +9.16 / +7.44 σ**
  — with one escape route closed the model should lean harder on the other. *Falsifier:* the ridge
  moves **less**, which would say σ and the ridge were substitutes rather than independent routes.
- **P4′ `beta_max` reaches ≥ 2.7**, i.e. ≥ 90 % of its hard implausibility bound of 3.0. This is
  recorded as a prediction because it is the finding that matters independently of P1′: **two
  probes and now a third drive the same ridge into the same corner.**

## Reading

- **P1′ predicted** ⇒ the P3 flag is a caveat, not a retraction; the persistence reading of 08-24c
  stands with `sigma_d14c` named as a minor accommodation.
- **P1′ falsified** ⇒ withdraw 08-24c's headline. The `luc` arm would then have shown that a
  probe's apparent `rep_dC` relief can be bought by a free error term — the same lesson as
  08-24b §3, one level down.
