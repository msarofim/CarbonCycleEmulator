# Pre-registration — the post-isotope-fix refit, 3 arms

**Written before launch, 2026-08-25f.** Successor to
`notes/prereg_2026-08-25b_fert_ridge_refit.md`, whose four arms are quarantined: they were fitted
under an objective that no longer exists.

## Why

Commit `6bda464` fixed a double discrimination on the seasonal NEP flux (`R/model.R`,
`src/ccx_core.cpp`; `notes/collect_2026-08-25d_seasonal_isotope_rectification.md`). **The objective
changed.** Nothing fitted before it is comparable, there is no canonical mode, and every
`DESIGN.md` §6 gate verdict is owed a re-measurement. Two things must be recovered:

1. **a canonical mode**, because the repo has none and every diagnostic and the app resolve one;
2. **the ridge verdict**, because the fix removed most of what was rejecting a saturating
   fertilisation. Re-scored under the patch AT PRE-FIX PARAMETERS, the pin90-vs-reference likelihood
   gap fell **−90.07 → −25.28**, and its composition inverted: `d13c_seasonal_SPO` −38.16 → −8.98,
   `d13c_seasonal_MLO` out of the top six, and what remained was **`gcb_land_sink` −24.00**, a
   CARBON objection. That is not a result — both arms move under a refit — but it is why the ridge
   question is worth re-asking rather than re-litigating.

## The three arms

All free of `luc_scale` pins, for the reason recorded in the 08-25b prereg: nothing is prescribed
here, so a global rescale is not an escape route being closed.

| arm | pin | seeded at | the question it answers |
|---|---|---|---|
| `refit_20260825f_ref` | none | the quarantined arm-N mode | **restores a canonical mode.** Warm start; the driver rejects a warm start that is worse than or not finite under the new objective, so a bug-fitted seed cannot survive by inertia. |
| `refit_20260825f_from90` | **none** | the K = 90 ridge cell | **Does a second basin exist NOW?** The control, and the one that can settle the programme. Falsified under the old objective — the free arm climbed back to `fert_k` 554.98. |
| `refit_20260825f_pin90` | `fert_k` = 90 | the K = 90 ridge cell | **prices forced saturation under the corrected objective.** Its logpost is NOT comparable to a free arm's without removing the near-delta prior offset. |

`pin60` and `pin120` are NOT re-run. They bracketed a cost curve whose middle point is the one that
matters, and the free arm is what decides whether the curve is interesting at all. If `from90`
returns to ~555 again, the bracket is not worth 6 more hours.

## PRE-REGISTERED PREDICTIONS

**P1 — the reference arm moves, and moves in the direction the frozen decomposition says.**
Frozen at the old mode the fix was worth `d13c_seasonal` **+210.7** and `d13c_level` **−259.5**, net
−49.7. **PREDICT: the refitted reference recovers most of that −259.5**, i.e. lands with a total
logL ABOVE the frozen post-fix value of −1839.65. **FALSIFIER: it lands below −1839.65**, which
would mean the old vector was already optimal under the new objective and the level penalty is
structural rather than absorbable.

**P2 — `q10` and the seasonal amplitudes move.** The seasonal isotope streams were the tightest
constraint on the land seasonal cycle and they were being scored against a corrupted model.
**PREDICT: |Δ| > 1 prior sd in at least one of `q10`, `seas_T_amp_NH`, `seas_T_amp_SH`.**
**FALSIFIER: all three move < 0.5 prior sd**, which would say the seasonal streams never had the
leverage the stream table implies.

**P3 — the free-from-90 arm returns to `fert_k` > 400.** The likelihood preferred shallow saturation
by 86.7 log-units before, of which the isotopic part is now largely gone but `gcb_land_sink` −24.00
is not. **PREDICT: it climbs back above 400.** **FALSIFIER: it lands below 200**, which would be a
second basin and would REOPEN the fertilisation-shape programme in full.

**P4 — `rep_dC` stays high.** It sat at 5.566 prior sd and did NOT move in any of the four 08-25b
arms. Nothing in this fix touches the CO₂ level streams. **PREDICT: |rep_dC| > 4.0 at the reference
mode.** **FALSIFIER: < 3.0**, which would mean the d13C level streams had been propping it up
through the shared representation parameter.

**P5 — the seasonal partition improves but does NOT close.** Frozen post-fix the δ¹³C-per-ppm ratio
is 0.93× (MLO) and 1.58× (SPO). **PREDICT: after the refit SPO remains > 1.25×.** **FALSIFIER: SPO
lands inside [0.8, 1.25]**, which would close the partition problem and retire the
latitude-band / stratosphere / high-latitude-mixing candidates.

**AND THE HONEST NULL:** if P1 fails, the fix has made the fit worse in a way a refit cannot
recover, and that must be reported as such rather than explained away — the same terms the 08-25b
prereg set for itself, and which its P1 was held to.

## What is NOT being claimed

- **No posterior.** The sampler has never converged; these are mode-finds.
- **No evidence comparison.** A pinned arm's Laplace evidence is not comparable to a free arm's.
- **No gate verdicts until they are re-measured** at the landed modes, not inferred from the frozen
  values in the collect note.

## Operational

- 3 arms, 3 processes, in parallel, **BLAS pinned to one thread each**
  (`OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1`) — memory
  `pin_blas_threads`, measured 4.8× on a 4-P-core Mac; 3 naked processes would spawn 12 BLAS threads
  onto 4 P-cores.
- Production settings otherwise (`ARM_RESTARTS` 20, `ARM_CYCLES` 6, `ARM_MAXIT` 20000).
- A smoke run at reduced settings proves the pipeline end-to-end first, to a scratch directory,
  because the objective and the seeds both changed today.
- `h_ml` is bounded to `[85, 120]` by the driver, as in every arm since 2026-08-16g, and that band
  must be restored before any recomputation from these files (memory `ccx_hml_band_provenance`).
