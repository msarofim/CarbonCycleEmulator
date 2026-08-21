# Pre-refit snapshot, 2026-08-20r

The 2026-08-18 two-arm modes, preserved before the 2026-08-20r refit overwrote
`mode_fit_pumpN.rds`.

**These were fitted under a DIFFERENT objective AND a different model.** Since they were written:

- **2026-08-20g** — `CCX_SST_SEAS_LAG` 2.50 → 1.32, and the four seasonal amplitude priors
  re-anchored on CRU/ERSSTv5.
- **2026-08-20k** — `npp_frac_NH`'s prior `UNIFORM[0.4, 0.8]` → `dnorm(0.5986119, 0.04)`.
- **2026-08-20r** — `seas_npp_amp_{NH,SH}` 1 → 0.4969 / 0.5027, which changes the MODEL, not
  only the objective.

So: **`par_mode` is still a valid parameter vector**, and diagnostics that only run the model at it
are fine (though they now run it under different constants and will not reproduce pre-08-20r
numbers). **`logpost`, `prior_z`, `hessian`, `cov`, `sd_unc`, `eigen`, `logdet_negH` and the Laplace
evidence describe a posterior that no longer exists — do not quote them.**

**`u_mode` is BAND-DEPENDENT and these files do not record the band.** The refit overrode `h_ml` to
[85, 120] in-process; decoding under the default [30, 200] gives 81.75 / 46.46 m and flips the arm
margin to −34.63. The 2026-08-20r output records `hml_bound` so this cannot recur.

Kept for postmortem, for regression-testing the changes, and for answering "how big was the move".
The canonical post-refit mode is the parent directory's `mode_fit_pumpN.rds`.
