# Pre-registration — the fertilisation-ridge refit, 4 arms

**Written before launch, 2026-08-25.** Successor to `handoff_2026-08-25_gcb_imbalance_programme.md`
§6–§7, whose G2/G3/G4 were retired by `notes/diag_2026-08-25_g1_gcb_seam.md`.

## Why

`calibration/diag_fert_ridge_{gates,streams,repdc,residual}.R` found that travelling ALONG the
ρ = +0.997 (`beta_max`, `fert_k`) ridge at fixed present-day NPP enhancement moves four open
problems together, all in the right direction:

| `fert_k` | FACE | AF trend | dec sd | land σ | IRF 20/50/100 | Δ logL frozen → after `rep_dC` | `rep_dC` |
|---|---|---|---|---|---|---|---|
| 554.5 mode | 13.6 % | −0.0007 | 0.019 | +2.12 | 11.69/23.81/39.06 | 0 | **5.566** |
| 120 | 6.4 % | +0.0097 | 0.028 | +1.26 | 12.64/26.53/44.39 | −2779 → −913 | 1.370 |
| 90 | ~5 % | ~+0.010 | ~0.031 | ~+1.0 | all inside | −4674 → −1550 | **0.150** |
| 60 | 3.8 % | +0.0163 | 0.040 | +0.74 | 13.15/28.08/47.64 | −8657 → −2914 | −1.750 |
| target | 0–23 % | +0.0148 | 0.048 | 0 | 12.2/24.0/39.5 | — | 0 |

**Every one of those costs is a FROZEN-VECTOR upper bound** with 19 coordinates held. The refit is
what converts a ranking into a result.

## The four arms

All warm-started from a seed placed AT their own ridge cell (`seed_fert_ridge_arms.R`), because the
adopted mode is a cold start from these cells — the driver's own guard rejects a warm start worse
than the cold init, and the cold init is −23610.

| arm | pin | seeded at | the question it answers |
|---|---|---|---|
| `ridge_free_from90` | **none** | K = 90 cell | **Does the likelihood drag `fert_k` back to 554?** The control, and the one that can kill the programme. |
| `ridge_pin60` | `fert_k` = 60 | K = 60 cell | the cell that meets gate 4's TREND |
| `ridge_pin90` | `fert_k` = 90 | K = 90 cell | the cell where `rep_dC` = 0 |
| `ridge_pin120` | `fert_k` = 120 | K = 120 cell | the conservative end; gate 12 already passes |

**`luc_scale` IS LEFT FREE, and the first launch had it pinned.** I pinned it at 0.898400 out of
habit from the probe arms and stopped the runs 20 s in to correct it. The probe convention exists
because a *prescribed local perturbation* is absorbed by a *free global rescale* (08-23: `luc_scale`
moved +5.52 sd and put 54 GtC back against a 20 GtC sink). **This is not that experiment.** Nothing
is prescribed here; the question is what the POSTERIOR does when the ridge is held, so every other
coordinate must be free to find its best value or the Δ logL is inflated by a constraint of my
choosing and P3 is unfair. And `luc_scale` is a constant multiplier on E_LUC — it can shift the
airborne fraction's LEVEL but cannot create a TREND in it, so it is not an escape route for gate 4
in the first place. If it moves far, that is a **finding to report**, not a contamination.

`beta_max` is **left free in every arm.** Pin the UNIDENTIFIED coordinate, free the identified one —
pinning both would prescribe the answer rather than test it.

`RESTARTS=8 CYCLES=2`, matching the stopped `luc_arm_pin2` so costs are comparable. 4 arms in
parallel on 4 P-cores with BLAS pinned to one thread each ([[pin_blas_threads]], 4.8× measured).

## Predictions

Against the adopted arm-N mode (`rep_dC` 5.5658, posterior sd 0.2433; prior N(0, 1)).

- **P1 — the control. `ridge_free_from90` does NOT return to `fert_k` > 400.**
  *Falsifier:* it lands above 400, which would say 554 is the unique optimum, the ridge has no
  second basin, and the gates simply lose to the CO₂ level record. **That outcome retires the
  programme and must be reported as such, not explained away.**
- **P2 — `rep_dC` comes inside 2 prior sd in `ridge_pin90`**, i.e. |`rep_dC`| ≤ 2.0 ppm, from 5.566.
  *Falsifier:* > 3.0 ppm, which would mean the 1-D conditional optimum did not survive letting the
  other 19 coordinates respond.
- **P3 — the refit recovers MORE than the frozen scan's ~67 %.** Predicted final `Δ logL` for
  `ridge_pin90` better than −1550 (the rep_dC-only figure).
  *Falsifier:* worse than −1550, i.e. freeing 19 parameters HURT — which would mean the frozen
  scan's cells are not on the posterior's own manifold.
- **P4 — gate 4's decadal AF trend at the landed `ridge_pin90` mode stays ≥ +0.006.** The frozen
  cell gives ~+0.010; the refit may trade some of it back for likelihood.
  *Falsifier:* ≤ +0.002, i.e. the refit undoes the gate-4 fix while keeping `fert_k` pinned, which
  would locate the trend in a coordinate other than the ridge.
- **P5 — `q10` RISES from 1.091.** It is currently near 1 (no temperature sensitivity), and the
  land-warming attribution was worth only +0.0008/decade because of it. With saturation supplying
  trend, `q10` has less reason to sit at the bound of implausibility.
  *Falsifier:* it falls. Recorded because it is diagnostic either way and costs nothing.

## Reading

- **P1 falsified** ⇒ stop. The ridge is likelihood-determined and the gate programme is over.
- **P1 + P2 hold** ⇒ the `rep_dC` blocker is a fertilisation-shape artefact and the 08-21 → 08-25
  arc is closed by an input to the model, not a mid-century mechanism.
- **P1 holds, P2 fails** ⇒ the direction is right and the cell is wrong; profile `fert_k` further.

## What this run does NOT settle

`sigma_d14c`'s provenance (the stopped `luc_arm_pin2`'s question) is untouched here and stays
**open** — see `calibration/output/luc_arm_pin2/README.md`. Laplace evidence of the pinned arms is
NOT comparable to the free arm's; read parameters and per-stream logL only.
