# Quarantine — 2026-08-11: AR(1) pathology and the RK4 solver wall

Everything in this directory was produced **before** the two 2026-08-11 fixes and
must not be read as a result. Kept, not deleted, because the size of the
correction is itself evidence: these files are what the postmortem, the
regression tests, and any reviewer question about impact are answered from.

## The two bugs

**1. The `-Inf` wall was the RK4 explicit-diffusion stability limit, not zero
posterior probability.** Interior diffusion is integrated explicitly, so a
hard-coded 4 RK4 substeps per month capped `kz` at ~155,000 m²/yr (h_ml = 75 m).
Above that the integration diverged, `ccx_run_fast()` filled with NAs, and
`ccx_make_logpost()`'s `anyNA` guard turned that into `-Inf`. **The posterior was
being truncated by the integrator wearing a prior's clothes.** The mode below sits
at `kz` = 175,790 — within ~1 % of the wall for its `h_ml` = 152 m — which is why
the re-pilot's chains all started at `lp = -Inf` and two of the four never moved.

Fixed by `ccx_substeps_for()`, which derives the substep count from the diffusion
operator's largest eigenvalue. Gated by `tests/testthat/test-stability.R`.

**2. The AR(1) error model laundered model discrepancy into free noise.** With
`rho` railed at 0.998, the effective independent sample size of MLO's 812 monthly
CO₂ observations was **0.8** — 67 years of the Keeling curve carrying the weight
of less than one observation — and a **+50 ppm level bias cost 13.7 log-units**.
Nothing was holding the physics parameters, which is why the mode has `q10` = 0.280
(Q10 < 1 means respiration *falls* with warming) and `kz` at the solver wall.

Fixed by retiring AR(1) and `rho` entirely in favor of annual values with
independent errors plus an explicit per-year seasonal-harmonic statistic. Gated by
`tests/testthat/test-likelihood.R`.

## Files

| File | What it is | Which bug applies |
|---|---|---|
| `pilot_fit.rds` | Original pilot MCMC (2026-08-10 session A) | both; also never left burn-in |
| `mode_fit_bombwin.rds` | Mode + Hessian on the bomb-window likelihood; logpost −8,736.6 | both |
| `modefind_bombwin.log` | Its mode-finding log | both |
| `modefind.log` | Mode-finding on the *pre*-bomb-window likelihood | both |
| `repilot_fit.rds` | Re-pilot from that mode; acceptance 0.000/0.000/0.205/0.187, worst R̂ 9.672 | both — this is the run that exposed bug 1 |

**Structural incompatibility:** these fits carry **18** parameters. The current
`CCX_PARAM_TABLE` has **17** — `rho` is gone. Loading one of these and feeding
`u_mode` to a current `ccx_make_logpost()` will not error informatively; it will
silently misalign every parameter. Do not do it.

## Canonical replacements

Post-fix outputs go to `calibration/output/` at the usual names. The
`mode_fit_bombwin.rds` here is superseded by the re-run described in
CHANGELOG 2026-08-11.

## What these files are still good for

- Reproducing the pathology diagnosis (the profiles in
  `notes/handoff_2026-08-10b_bomb14c_and_sampler.md` §4).
- Regression-testing the fixes: `test-stability.R`'s mutation test asserts that
  `kz` = 175,790 — this mode's value — still fails under the old fixed 4 substeps.
- Answering "how big was the bug?" — the honest answer is that it changed the
  answer qualitatively, not marginally.
