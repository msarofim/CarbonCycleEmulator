# Quarantine — 2026-08-15, pre-gradient-terms MAP mode

## What is here

`mode_fit.rds` — the **18-parameter** MAP mode from `calibration/run_modefind.R`,
commit `58b4a03`, 293.6 min / 291,832 evaluations, log-posterior **−2221.3**,
Hessian positive-definite (condition 6.8e5), no parameter beyond 3 prior sds.

This is the mode that made DESIGN §6 gates 7 and 12 pass for the first time. It is
**not wrong** and nothing about it has been retracted. It is quarantined because
the model and the objective it belongs to no longer exist.

## Why it is not at the canonical path

Two changes on 2026-08-15, either of which alone would invalidate it:

1. **Review item 5b** (`98f0457`) replaced the constant land-use hemispheric share
   with the OSCAR-sourced time-varying series. That is an **input** change: the
   mode's parameters were fitted against a forcing that put ~31 GtC of cumulative
   land-use carbon in the other hemisphere.
2. **Review item 5** added the two interhemispheric-gradient likelihood streams
   and, with them, the parameters `grad_off_co2` and `grad_off_d13c`. The
   parameter vector is **18 → 20**, so a stored mode cannot even be read into the
   current `CCX_PARAM_NAMES`. `app/global.R`'s
   `identical(md$param_names, CCX_PARAM_NAMES)` guard rejects it, which is the
   guard working, not a bug.

Item 5 also moved `FORC_FOSS_NH_SHARE` 0.95 → 0.9201 (measured, EDGAR v4.3.2),
a third reason the fitted point is no longer the fitted point.

## What replaces it

**Nothing yet.** The canonical path `calibration/output/mode_fit.rds` is empty
until review item 8 — the refit at 20 parameters — is run. Until then the app
falls back to whatever its no-mode path does, and any number quoted as "the MAP
mode" must come from here **with its 18-parameter provenance stated**, or from a
new run.

## What may still be quoted from this file, and what may not

- **May:** the fact that gates 7 and 12 both passed at an 18-parameter mode under
  the Michaelis–Menten fertilisation form; the finding that `h_ml` has an interior
  optimum near 184 m; the `r(luc_scale, fert_k) = −0.907` sampling hazard.
- **May not:** any parameter value as "the calibrated value"; the log-posterior
  −2221.3 as comparable with anything computed after 2026-08-15 (the objective has
  two more streams, so the numbers are not on the same scale); the gradient
  behaviour reported in `diag_gradient_terms.R` part 3 for "the MAP mode", which
  is this file's parameters run through a forcing it was never fitted to and is
  labelled as such in that file.
