# Collection — P3 FALSIFIED: there is a second basin. 2026-08-25g.

Against `notes/prereg_2026-08-25f_post_isotope_fix_refit.md`, written before launch.
**`from90` and `pin90` have LANDED; `ref` is still running** (cycle 2, gains 0.01–0.20 — it cannot
close a 15-log-unit gap, but it is not final and every `ref` row below is marked RUNNING).

---

## 1. P3 — FALSIFIED, and not marginally

| arm | logpost | `fert_k` | `beta_max` | `enh(420)` | `rep_dC` | `q10` |
|---|---|---|---|---|---|---|
| `ref` (cycle 2, RUNNING) | −1560.05 | 483.1 | 0.9271 | 0.2119 | +3.834 | 1.116 |
| **`from90` FINAL (free)** | **−1544.61** | **154.85** | 0.5109 | 0.2454 | +3.378 | 1.136 |
| `pin90` FINAL, pin removed | −1556.17 | 90 (pinned) | 0.4698 | 0.2884 | +3.093 | 1.147 |

Seeded at `fert_k` = 90, the FREE arm landed at **154.85**. P3 predicted > 400; its falsifier was
< 200. **And `from90` beats `ref` by +15.43 log-units**, both free, same objective, like for like.

**The identical experiment on 2026-08-25 returned `fert_k` = 554.98** and killed the
fertilisation-shape programme ([[fert_shape_is_the_common_cause]]). The only thing that changed
since is the seasonal-NEP isotope fix (commit `6bda464`). **The sign of the ridge verdict has
flipped: pre-fix the posterior rejected `fert_k` = 90 by −86.66; post-fix it prefers saturation.**

The pin offset is **+11.6698**, computed from the transform at `fert_k` = 90, not quoted from the
old +11.33–12.21 range.

## 2. THE GATES, at the landed modes

Targets: AF trend **+0.0148**, decadal sd 0.0483, land 0 σ; Joos floors 12.2 / 24.0 / 39.5.

| arm | AF | dec sd | **trend** | r(obs) | land σ | TH20 | TH50 | TH100 | 12b |
|---|---|---|---|---|---|---|---|---|---|
| pre-fix ref (BEFORE) | 0.434 | 0.0188 | −0.0007 | −0.06 | +2.12 | 11.69 ✗ | 23.81 ✗ | 39.06 ✗ | 0.707 ✓ |
| `ref` (RUNNING) | 0.433 | 0.0192 | −0.0006 | −0.06 | +2.22 | 11.71 ✗ | 23.84 ✗ | 39.08 ✗ | 0.707 ✓ |
| **`from90` FINAL** | 0.413 | 0.0259 | **+0.0080** | +0.41 | +2.46 | 12.14 ✗ | **24.98 ✓** | **41.11 ✓** | 0.709 ✓ |
| `pin90` FINAL | 0.391 | 0.0355 | **+0.0137** | +0.51 | +3.03 | **12.32 ✓** | **25.43 ✓** | **41.83 ✓** | 0.716 ✓ |

**This is the first time the posterior's OWN preferred free mode moves gate 4 in the right
direction** — trend −0.0007 → **+0.0080**, r −0.06 → **+0.41** — and passes gate 12 at two of three
horizons, where every free mode before it failed all three. It is not all the way: the trend is 54 %
of target and TH20 still misses by 0.06.

`pin90` gets closer on every gate and is 11.6 log-units worse. **The gates and the likelihood now
point the same way instead of opposite ways** — that is the change.

## 3. WHERE `from90`'s +15.43 COMES FROM — and the objection that survives

| stream | Δ vs `ref` |
|---|---|
| `co2_icecore` | **+7.82** |
| `co2_seasonal_SPO` | +5.13 |
| `co2_level_MLO` | +3.94 |
| `co2_seasonal_MLO` | +2.02 |
| `co2_level_SPO` | +1.93 |
| `d13c_seasonal_MLO` | +1.80 |
| prior `rep_dC` | +1.65 |
| … | |
| `d13c_level_MLO` | −1.68 |
| **`gcb_land_sink`** | **−7.94** |

**Saturation now pays across the CO₂ streams and costs in the land sink.** That is the exact
inverse of the pre-fix decomposition, where the d13C SEASONAL streams carried 72 % of the objection
([[ridge_veto_is_a_bias]]) — those streams now *support* it (+1.80, +0.85). The land sink is the one
objection that survives the fix, at −7.94, and it is now outvoted rather than decisive. Consistent
with what the patched pre-fix re-scoring predicted: what remains is a CARBON-budget objection.

## 4. The other predictions

**P4 — FALSIFIED.** Predicted |`rep_dC`| > 4.0 at the reference; it is **3.834** and falling
(`from90` 3.378, `pin90` 3.093) from a pre-fix 5.566. `rep_dC` is by far the largest mover in the
vector — **1.73 prior sd**, where nothing else exceeds 0.58. The prereg named the mechanism: the
d13C level streams were propping it up through the shared representation parameter. That reading now
looks right, and it is a real result — `rep_dC` at 5.6 σ was a standing anomaly
([[ccx_rep_dc_co2_bias]]).

**P2 — NOT SUPPORTED AS STATED.** Predicted > 1 prior sd in `q10`, `seas_T_amp_NH` or
`seas_T_amp_SH`; the largest is `seas_T_amp_SH` at **0.58 sd** (`q10` 0.09, `seas_T_amp_NH` 0.19).
The prediction was aimed at the wrong parameters: the vector DID move by more than 1 sd, but in
`rep_dC`, which P2 did not name.

**P5 — HOLDS.** Predicted SPO stays > 1.25×; it is **1.47–1.50×** at every post-fix arm (pre-fix
1.58×). MLO sits at 0.96×. So the seasonal partition improved and did NOT close — Marcus's
latitude-band / stratosphere / high-latitude-mixing candidates remain live, on a target that is now
~1.5× rather than 2.45×. Note the CO₂ amplitudes also improved on their own (MLO 0.92× → 0.98×,
SPO 1.06× → 0.95×).

**P1 — cannot be settled until `ref` lands**, and `ref` is the arm it is stated about.

## 5. Consequences

- **The canonical mode is `from90`, not `ref`** — highest free arm wins regardless of name, the rule
  set when the two diverged. `ref` is a worse local optimum.
- **`kz` still rails**: 6140 / 6332 / 6431 against a bracket top of 6528 (94–98 % up). Unchanged as
  an open problem by any of this.
- **`pump_grad` lands 267–272** against a 233.1 prior centre, at every arm.
- The `enh(420)` invariant is **no longer shared**: 0.212 / 0.245 / 0.288 across the three arms. The
  ridge has genuinely moved rather than slid along itself, which is why the arms separate at all.

## 6. What is still owed

1. **`ref` to finish**, then P1, and a re-run of §1–§4 with `ref` FINAL rather than RUNNING.
2. **A DESIGN §6 sweep** — these are four gates of many, and the objective changed under all of them.
3. **The ridge reparametrisation race**, redesigned: the 2026-08-25g smoke used starts at lp
   −26,000 to −150,000, i.e. 1.4–8× WORSE than the driver's cold init (−18,634), so it measured
   gross descent rather than the near-optimum ridge-crawling that actually costs 332k evals. The
   right start scale is sd ≈ 0.02–0.03 (median lp −1,672), the right statistic is evals-to-threshold,
   and the race parallelises — ~50 min on four free cores.
4. **No posterior.** All of this is mode-finding; the sampler has still never converged, so "the
   posterior prefers" means "the mode is higher", not a probability.

---

# ADDENDUM 2026-08-27 — the ridge reparametrisation is a NULL

`calibration/diag_ridge_reparam.R`. **Two campaigns, 8 paired races, no effect.**

## The hypothesis

`beta_max` and `fert_k` are correlated at ρ = +0.997, which is what collapses a simplex, and the
ridge-invariant coordinate `enh(420) = beta_max·d/(fert_k + d)` is what the CO₂ integral actually
constrains. Fitting in `(enh, fert_k)` should therefore need fewer evaluations. The refit spends
~332,000 per arm, so a real speedup would matter more than any hardware change.

## The result

| campaign | starts | paired (v − u) final log-post |
|---|---|---|
| A, sd 0.025 (starts −1803 to −2495) | 4 | +1.31, −0.51, −0.08, +0.20 |
| B, sd 0.006 (starts −1560 to −1601, the CRAWL) | 4 | −0.91, +0.56, −0.17, +0.07 |

**COMBINED n = 8: mean +0.059, sd 0.673, t(7) = 0.25, p = 0.812, sign split exactly 4:4.**
**95 % CI on the paired difference: [−0.50, +0.62] log-units.** Threshold ladder in campaign B
(evals to reach a given log-post) gives 0.98× / 0.68× / 1.71× — no consistent direction.

## AND THIS TIME THE TEST HAD POWER

Campaign A alone was a null from a test that could not see the effect: every run stopped **1.0–2.3
log-units short** of the mode, so it measured progress-from-a-distance, not the final crawl where
the refit actually spends its evaluations (`ref` went −1909 → −1602 in **402** evals and needed
~330,000 more for the last ~40). [[no_power_null]] — so campaign B was run in the crawl regime, and
there **7 of 8 runs finished within 0.35 log-units of the canonical mode** (u: 0.22/0.81/0.05/0.35;
v: 1.13/0.24/0.22/0.28). The arms converge, and they converge equally.

**The step-scale confound was removed**, not just noted: `optim`'s Nelder-Mead perturbs each
coordinate by 10 % OF ITS VALUE, so `logit(beta_max)` and `logit(enh)` would seed different-sized
simplexes. `RR_OFFSET` translates the enh coordinate so both arms start at NUMERICALLY IDENTICAL
vectors (asserted to 1e-12 in the worker); a translation cannot change geometry, so what is left is
decorrelation alone.

**The "speedup" statistic was RETIRED.** The first report printed "median 1.28×", which reads as a
win; when the ridge arm loses, that ratio is below 1 by construction and its magnitude depends on an
arbitrary crossing point. It is not symmetric and must not be medianed. The paired difference in
final log-post is the statistic.

## What it means

**Decorrelating this one pair does not reduce the evaluation count.** A plausible reason — NOT
tested here — is that ρ = +0.997 is a 2-parameter feature of a 20-parameter problem, and the
conditioning is dominated by other directions. **The measurement that would settle it is the Hessian
condition number in both parametrisations**, and memory `ccx_hess_step_sd` warns that the Hessian in
exactly this plane is numerically delicate, so it needs per-direction step sizing.

**⇒ IT ALSO CORRECTS THE TORCH ADVICE.** On 2026-08-26 I recommended trying this reparametrisation
BEFORE investigating Torch, on the grounds that it might make the throughput question moot. **It
does not.** The per-arm evaluation count is not reducible by this route, Nelder-Mead remains
strictly serial, and so Torch's arm-parallelism (and the MCMC, `cs` partition or checkpointed) is
back to being the main lever for throughput.
