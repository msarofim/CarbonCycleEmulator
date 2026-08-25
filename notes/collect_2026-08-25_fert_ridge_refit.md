# Collection — the 4-arm fertilisation-ridge refit. 2026-08-25.

Against `notes/prereg_2026-08-25b_fert_ridge_refit.md`, written before launch.
**ALL FOUR ARMS FINISHED** (8 h 53; all wrote `pump_arms_comparison.rds`). Measured with
`calibration/diag_gates_at_landed_modes.R`. **This file was first written when two arms were still
running and said gate 12 was unmeasured and "only gate 4 survives". Both are now corrected below —
gate 12 survives too.**

## P1 — FALSIFIED. The likelihood pulls `fert_k` straight back to 555.

| | logpost | `fert_k` | `beta_max` | enh(420) | `rep_dC` |
|---|---|---|---|---|---|
| reference mode | −1859.32 | 554.54 | 1.0112 | 0.2074 | 5.566 |
| **`ridge_free_from90`** (seeded at K = 90) | **−1859.32** | **554.98** | **1.0118** | **0.2074** | **5.566** |

Seeded at the K = 90 cell with a warm start of −3412, it climbed **all the way back** — `fert_k`
within **0.08 %** of the adopted mode, logpost identical to two decimals, every reported coordinate
restored. **There is no second basin.** The pre-registration named this outcome and its consequence:
*"That outcome retires the programme and must be reported as such, not explained away."*

## P2 — FALSIFIED. `rep_dC` does not follow.

Predicted |`rep_dC`| ≤ 2.0 ppm at K = 90, falsifier > 3.0. **Landed values: 4.967 (K = 120,
finished), 4.733 (K = 90, still running), 4.138 (K = 60, still running)** against a reference of
5.566 — versus the frozen scan's 1-D conditional optima of **1.370 / 0.150 / −1.750**.

**The mechanism of the failure is visible and it is the ridge itself.** Each arm was seeded ON the
ridge (enh(420) = 0.2074 by construction). With `fert_k` pinned, the fit moved **off** it:

| arm | seeded `beta_max` | landed `beta_max` | seeded enh(420) | **landed enh(420)** |
|---|---|---|---|---|
| pin120 | 0.3814 | 0.4806 | 0.2074 | **0.2614** |
| pin90 | 0.3379 | 0.4679 | 0.2074 | **0.2873** |
| pin60 | 0.2944 | 0.4807 | 0.2074 | **0.3387** |

Pinning one coordinate of a ρ = +0.997 pair does **not** hold the pair. The fit raises present-day
fertilisation 26–63 % above the ridge value, which restores most of the CO₂-level fit — and `rep_dC`
with it. **The frozen scan's cells are not on the posterior's manifold.**

## P3 — HOLDS, and it no longer means what it was supposed to mean.

| arm | landed | pin-offset removed | Δ vs mode | frozen estimate | |
|---|---|---|---|---|---|
| pin120 | −1895.45 | −1906.78 | **−47.5** | −912.9 | 19.2× better |
| pin90 | −1934.31 | −1945.98 | −86.7 | −1550.4 | 17.9× better |
| pin60 | −2040.69 | −2052.90 | −193.6 | −2914.4 | 15.1× better |

The refit recovers **15–19×** more than the frozen scan predicted, exactly as P3 said. But P3 was
offered as evidence the cells were viable. It is not: the recovery is the model **routing around the
pin**, and the route is the ridge itself.

## P4 — HOLDS, AND IT IS THE ONE REAL SURVIVOR

Gate 4 at the landed modes (target: trend +0.0148, sd 0.0483):

| | AF | dec sd | trend | r(obs) | land σ | ocean σ |
|---|---|---|---|---|---|---|
| reference | 0.434 | 0.0188 | −0.0007 | −0.06 | +2.12 | −0.64 |
| free arm (landed) | 0.434 | 0.0188 | −0.0007 | −0.06 | +2.12 | −0.64 |
| **pin120 (landed)** | 0.405 | **0.0300** | **+0.0107** | **+0.48** | **+2.62** | −0.49 |

**The gate-4 fix is REAL and survives the refit** — trend −0.0007 → +0.0107, decadal sd 0.019 →
0.030, correlation −0.06 → +0.48, all with 19 other parameters free to undo it and none of them
doing so. A saturating fertilisation genuinely produces airborne-fraction time-dependence.

**But gate 7 goes the WRONG WAY.** The frozen scan predicted the land sink improving to +1.26 σ at
K = 120; it landed at **+2.62 σ, worse than the reference's +2.12**. That improvement was a
frozen-vector artifact. The AF *level* also degrades, 0.434 → 0.405.

## P5 — NOT SUPPORTED. `q10` 1.091 → 1.099–1.101, i.e. unmoved.

---

## WHAT THIS RETRACTS

This morning's headline — **"four problems, one direction"** — does not survive its own refit.
Corrected:

| claim (frozen scan) | after the refit |
|---|---|
| gate 4's AF trend responds to saturation | **HOLDS** — the one real result |
| gate 7's land sink comes inside 1 σ | **RETRACTED** — lands at +2.62 σ, worse than baseline |
| `rep_dC` falls to its prior centre | **RETRACTED** — stays at 4.1–5.0 of 5.566 |
| gate 12 passes at all three horizons | **HOLDS** — measured at the landed modes, see below |
| four problems, one cause | **RETRACTED** — **two** gates respond, two other things break, `rep_dC` does not move |

**And the cost is now priced.** Buying +0.011/decade of AF trend costs **47 log-units** and **+0.5 σ
on the land sink**, and the free arm says the posterior declines the trade.

[[sens_scan_achievable]] in its purest form: the scan ranked the work correctly — fertilisation
shape *is* the lever gate 4 responds to — and was wrong about everything it inferred beyond that.

## THE FULL LANDED PICTURE — all four arms, all gates

**Gate 4 / gate 7** (targets: trend +0.0148, sd 0.0483, land 0 σ):

| | AF | dec sd | trend | r(obs) | land σ | ocean σ | enh(420) |
|---|---|---|---|---|---|---|---|
| reference | 0.434 | 0.0188 | −0.0007 | −0.06 | +2.12 | −0.64 | 0.207 |
| free arm | 0.434 | 0.0188 | −0.0007 | −0.06 | +2.12 | −0.64 | 0.207 |
| pin120 | 0.405 | 0.0300 | +0.0107 | +0.48 | +2.62 | −0.49 | 0.261 |
| **pin90** | 0.393 | 0.0355 | **+0.0138** | +0.52 | **+2.97** | −0.45 | 0.287 |
| pin60 | 0.372 | 0.0442 | +0.0184 | +0.55 | **+3.72** | −0.37 | 0.339 |

**Gate 12 / 12b** (floors 12.2 / 24.0 / 39.5; 12b band [0.593, 0.979]):

| | TH20 | TH50 | TH100 | 12b tail | airborne @300 |
|---|---|---|---|---|---|
| reference | 11.69 ✗ | 23.81 ✗ | 39.06 ✗ | 0.707 ✓ | 0.194 |
| pin120 | **12.28 ✓** | **25.35 ✓** | **41.79 ✓** | 0.713 ✓ | 0.210 |
| pin90 | **12.38 ✓** | **25.61 ✓** | **42.20 ✓** | 0.718 ✓ | 0.213 |
| pin60 | **12.50 ✓** | **25.89 ✓** | **42.58 ✓** | 0.730 ✓ | 0.217 |

## ⇒ THE REAL RESULT IS A TENSION, NOT A DEAD END

**Two gates are fixed by saturation and they survive the refit.** Gate 4's AF trend reaches
**+0.0138 against a +0.0148 target** at pin90, and **gate 12 passes at all three horizons for the
first time at any fitted vector** — where the reference fails all three. Neither is a frozen-vector
artifact; 19 free parameters had every chance to undo them.

**Two things break, monotonically in the same direction.** The GCB land sink goes +2.12 → +2.62 →
+2.97 → +3.72 σ, and the AF *level* degrades 0.434 → 0.372 against an observed 0.431.

**And `rep_dC` does not move** (5.566 → 4.967/4.734/4.138).

So the model is being pulled two ways by its own objective: **the pulse-response and
airborne-fraction-variability gates want strong fertilisation saturation; the CO₂ station levels and
the GCB land sink want weak saturation.** The likelihood, weighted as it currently is, chooses weak
— by **86.7 log-units** at pin90, of which the frozen decomposition showed **93 % lives in
`co2_level_MLO` + `co2_level_SPO`**, the two streams whose absolute level is absorbed by the
`rep_dC` nuisance offset.

**That is the question the next session inherits, and it is an OBJECTIVE question, not a parameter
one.** Not "where on the ridge does the model sit" — that is answered, 555 — but "should two
station-level streams, fitted through a 5.6 σ nuisance offset, outvote the pulse response and the
airborne-fraction record by two orders of magnitude?"
