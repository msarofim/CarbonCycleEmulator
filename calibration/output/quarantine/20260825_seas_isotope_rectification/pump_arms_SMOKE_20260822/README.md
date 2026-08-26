# Smoke test — 2026-08-22, before the arm-N refit

Cheap end-to-end proof of `run_modefind_pump_arms.R` before committing hours, run via
the env overrides added the same day:

```
CCX_ARM_OUTDIR=<this dir> CCX_ARM_RESTARTS=1 CCX_ARM_CYCLES=1 CCX_ARM_MAXIT=200
```

The directory was seeded with a copy of the real `mode_fit_pumpN.rds` first, so the
**warm-start path was exercised exactly as the production run does it** — and because
`ARM_OUT()` derives from `ARM_OUTDIR`, the smoke run could not touch the real file.

**What it proved** (9.7 min, 3014 evals, 0.194 s/eval):

| check | result |
|---|---|
| arm selection | `REFIT, 1 ARM(S) [N]` |
| warm start under the NEW objective | −1861.0, against a **predicted** −1877.947 + 16.90 = −1861.05 |
| ⇒ the objective change is the ice term and nothing else | confirmed to ~0.05 log-units |
| `co2_icecore` at the new mode | −690.86 (was −706.81 on `co2_NH`) |
| `gcb_land_sink` | −95.91 — the **single**-scaled value, so the luc fix is live in the stored streams |
| provenance fields | `hml_bound` [85, 120], `kz_bracket` [3942.5, 6528] both recorded |
| Hessian | all 21 coordinates step-stable; Laplace covariance PD, condition 4.67e+05 |
| no repair fields on a fresh fit | `streams_as_fitted` absent, as it should be |

Not a converged fit — 1 restart, 1 cycle, maxit 200. Do not quote its parameters.
