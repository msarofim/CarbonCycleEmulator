# STOPPED, NOT COMPLETED. 2026-08-25, at 1 h 25 of ~6 h. **SCRATCH.**

**THERE IS NO RESULT IN THIS DIRECTORY AND ITS ABSENCE IS NOT ONE EITHER.**
`mode_fit_pumpN.rds` here is the **seeded copy of the adopted arm-N mode** (08-24b's seed-copy
trap), NOT a fitted arm. Completion would have keyed on `pump_arms_comparison.rds`, which was
never written. `refit_luc_pin2.log` stops after `cycle 1 restart 1`.

## What it was for

P3 of `notes/prereg_2026-08-24c_...md` fired (`sigma_d14c` +1.671 sd against a 1.5 falsifier), so
the `luc` arm's Δ`rep_dC` = −5.014 sd could not be quoted clean. This run pinned `sigma_d14c` at
the reference 6.125078 on top of the existing `luc_scale` pin, to decide whether the move was
bought by a widened ¹⁴C error bar. Predictions: `notes/prereg_2026-08-25_p3_sigma_pin.md`.

## Why it was stopped (Marcus, 2026-08-25)

**It could not have returned a clean number whichever way it landed.**
`calibration/diag_luc_arm_ridge_confound.R`, run the same day, measured a LARGER confound that
this run leaves wide open: the `luc` arm traveled ALONG the (`beta_max`, `fert_k`) ridge
(`beta_max` +9.16 sd, `fert_k` +7.43 sd, `enh(420 ppm)` changed only 2.4 %), and that ridge is
itself a `rep_dC` lever worth several sd. With the sink OFF and every other coordinate at the
reference mode, the arm's ridge position alone puts `rep_dC` at **7.220 (+6.80 sd)** against the
reference's 5.566.

So P1′'s threshold (Δ`rep_dC` ≤ −3.5 sd, falsifier > −2.0) was calibrated against a contaminated
baseline. This run pins `luc_scale` and `sigma_d14c` and leaves the ridge free — i.e. it closes the
two smaller routes and not the largest one.

## What replaced it, and what is still owed

The confound decomposition answered a better version of the question in minutes: the ridge was
pushing `rep_dC` **up** by +4.58 to +6.80 sd while the arm landed 5.01 sd **below** the reference,
so the mechanism is worth roughly **−9.6 to −11.8 sd, not −5.014**. 08-24c's headline is
**understated by about 2×**, not contaminated — and the "within 0.014 sd of its own threshold, so
not a decisive pass" reading was measuring a cancellation.

**STILL OWED:** the `sigma_d14c` provenance question itself is unanswered. Do not record it as
settled. The right version pins `sigma_d14c` **and holds the ridge**, which is a different run and
belongs with the `fert_k` refit design (`notes/diag_2026-08-25_g1_gcb_seam.md`'s successor work;
see `CHANGELOG.md` 2026-08-25c).

**KNOWN BLOCKER for that run:** `CCX_PIN_PARAMS` cannot pin `fert_k`. The near-delta is LOGNORMAL
and `fert_k` has `tr = "logit"` (`R/calibrate.R:68`); the driver errors with *"pin is a LOGNORMAL
near-delta and fert_k has tr = \"logit\"; add the matching family before pinning it"*. Either add a
logit-family near-delta, or narrow the bound the way `h_ml` is narrowed in
`run_modefind_pump_arms.R:217-229` (with the prior renormalized over the new support).
