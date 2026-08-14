# QUARANTINE — pre-MM-fertilisation posterior mode, 2026-08-14

## What applies

Not a bug: a **model-structure change**. On 2026-08-14 the CO₂-fertilisation form
flipped from `NPP = NPP₀(1 + β ln(χ/χ₀))` to Michaelis–Menten,
`NPP = NPP₀(1 + β_max·Δχ/(K + Δχ))` (`CCX_FERT_MM`, review item 7). `beta` left
`CCX_PARAM_TABLE`; `beta_max` and `fert_k` entered it, 17 parameters → 18.

**MM is NOT a reparameterisation of the log form.** As `fert_k → ∞` MM goes *linear*, not
logarithmic, so **no substitution carries a `beta` posterior across**. This file is a
posterior for a different model.

## What is here

- `mode_fit.rds` — the 17-parameter MAP fit under the log form at β 0.75. It is the source
  of the `sigma_d13c = 0.440` / `sigma_co2 = 0.301` / `sigma_d14c = 4.16` values that
  `diag_recentre_beta.R` and `diag_beta_luc_profile.R` quote by hand, and of the
  `mode_fit`-labelled column in several diagnostics. Those files are pinned to
  `CCX_FERT_LOG`, so they remain reproducible against it.

## Canonical replacement

**There is none yet.** No refit has been run under the saturating form — item 8. Until it
has, `ccx_default_params()` is *uncalibrated defaults*, and `app/global.R` correctly falls
back to them: its `identical(md$param_names, CCX_PARAM_NAMES)` guard rejects this file
because the parameter vector changed. That guard is why the app never silently ran a
log-form posterior through an MM model.

`calibration/diag_excess_c14.R` reads `calibration/output/mode_fit.rds` directly and falls
back to an earlier quarantine copy when absent — it will now find neither at the canonical
path and use its own fallback. That is the intended behaviour: it is a log-form diagnostic.

## Why it was not deleted

It is the provenance for every β-era result in `CHANGELOG.md`, the fixture behind the
`mode_fit` sigma columns above, and the only thing that can measure how far the refit moves
the shared parameters. Deleting it would make the size of the form change unmeasurable.
