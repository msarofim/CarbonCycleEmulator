# Handoff — CarbonCycleEmulator, 2026-08-28c: **OPTION 5 IS ADOPTED AND SHIPPED**
# The objective CHANGED. The 21-parameter refit is OWED and NOT RUN. Nothing is quarantined yet.

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`, clean at `04cb595`.
**Nothing is running.** **Suite 1203 pass / 0 fail** (was 1164). Opens from `c76465c`.

⚠ **SESSION CWD WAS `FaIRtoFrEDI/`; ALL THIS WORK IS IN `CarbonCycleEmulator/`.**
⚠ **A Julia SLR job (`postprocess_mcmc_ext.jl --tag=L21`, `SLR-RFF-BRICK`) ran on this Mac
throughout — not mine, not touched.** Everything here was run single-threaded from frozen copies.

---

## 0. STATE IN EIGHT LINES

1. **Marcus: "Adopt option 5."** The `[85, 120]` skip is RETIRED; the three ocean-gradient rows are
   scored at `sigma_eff` at EVERY `h_ml`. §1
2. ⚠ **THE OBJECTIVE CHANGED. EVERY PRE-ADOPTION FITTED VECTOR IS NON-COMPARABLE.** §4
3. ⚠ **THE 21-PARAM REFIT IS OWED AND NOT RUN.** It is ~18 h and Marcus had not yet said whether to
   launch it against his Julia job. §4
4. ⚠ **NOTHING IS QUARANTINED YET, DELIBERATELY** — quarantining the canonical mode before a
   replacement exists breaks `ccx_mode_file()`, the app and every diagnostic. §4
5. **The smoke test's alarming `h_ml` = 35.38 m is NOT a finding and NOT a bug** — its entire
   "gain" is prior credit on the seasonal amplitudes, bought with a worse fit. §3
6. ⚠ **`h_ml` IS NOT NOW SMOOTH: 26 kinks in [30, 200].** Option 5 removed the CLIFF, not the
   `1/eps` kinks. My earlier framing needs this qualifier. §5
7. ⚠ **I overclaimed a "kink" justification and withdrew it in-place**, with a test. §2
8. **`kz` still rails (95.3 % in the smoke). Unchanged, again.**

## 1. WHAT SHIPPED

    sigma_eff(h)^2 = sigma_obs^2 + (shipped target - like-for-like target(h))^2

normalisation RETAINED, so inflating is charged for and the gain is bounded by the density peak.

- **`data-raw/build_glodap_sigma_rep.R` -> `data/obs_glodap_sigma_rep.rds`.** The **SIGNED**
  like-for-like target on a **1 m grid over `h_ml`'s whole support**, measured off GLODAP by the
  shipped target's OWN recipe. **Gate G1 reproduces all three shipped targets to `0.00e+00`.**
  ⚠ It ships in `data/` with a builder and a test precisely so it is not a hidden dependency on two
  diagnostic outputs, which is what Stage A/B used.
- **`R/likelihood.R`**: band gate DELETED; `ccx_ocean_grad_scored()` attaches `sd_eff` + `h_ml`;
  `ccx_ocean_sigma_rep_table()` / `ccx_ocean_sigma_eff()` added (monotone-Hermite, C1, cached);
  `ccx_loglik()` scores at `sd_eff` and **ERRORS** if a hand-built `ocean_grad` omits it.
  `LIK_OCEAN_GRAD_HML_OK` -> **`_RETIRED`**, provenance only, nothing may gate on it.
- **`run_modefind_pump_arms.R`: `h_ml` UNBOUNDED.** Gates H1/H2/H3 INVERTED — the parameter table
  must be UNTOUCHED, the shipped init ACCEPTED, and the rows live with finite `sd_eff` at BOTH ends.
  ⚠ **`hml_bound` in the output rds now records the SHIPPED support**, because `ccx_mode_params()`
  re-decodes `u_mode` under it — writing `[85,120]` there would corrupt every downstream decode.
- **13 diagnostics swept BY KIND**: 9 provenance/reporting repointed; 4 that mirrored the refit's
  bound repointed **with a loud staleness banner**; 3 vacuous `stop()` guards DELETED (they asserted
  a depth was in-band so the rows would not skip — the rows cannot skip now).
- **Tests 1164 -> 1203.** The h_ml-gate test is **INVERTED**; `test-sigma-inflation.R` gates the
  property the adoption is FOR: no jump across either retired edge (the skip measured **+7.3005**
  and **+8.4257**), `sigma_eff >= sigma_obs`, the loud-error contract, and the shipped grid against
  a fresh recomputation of its own recipe.

## 2. TWO METHOD CALLS, BOTH MADE ON MEASUREMENT, ONE OF THEM A RETRACTION

- **No smoothing, and a moving average was TRIED AND REJECTED.** At every width it deviated from the
  raw curve by MORE than the jumps it removed (**0.131 vs 0.090 at w = 11 m**) because the V-bottom
  at the crossing is narrower than the smoother. Measured roughness with the model gradient held at
  the mode: **median 0.0055, max 0.0734 log-units** against a 0.70 noise floor. [[smoother_wider_than_feature]]
- ⚠ **RETRACTED IN-PLACE.** I wrote into the builder and `R/likelihood.R` that shipping
  `|sigma_rep|` would "plant a KINK in the posterior's softest direction". **Measured: the signed
  and folded constructions differ by 0.0002 sigma_obs, second differences equal to six decimals** —
  `sigma_eff` SQUARES the difference, so folding is nearly a no-op. Withdrawn in both files, gated
  by a test. The signed form still ships for FAITHFULNESS, not smoothness.

## 3. THE SMOKE TEST — AND WHY ITS RESULT IS NOT A FINDING

`CCX_ARM_OUTDIR` + `CCX_ARM_RESTARTS=1 CCX_ARM_CYCLES=1 CCX_ARM_MAXIT=60`, 14.2 min, warm-started
from the canonical mode at 96.47 m. **It reported `h_ml` = 35.38 m, "gaining" 4.1** — apparently
contradicting Stage B's interior maximum. **Diagnosed, not rationalised:**

    DELTA (smoke - old):  logpost +4.060 = prior +7.399   jac -2.139   loglik -1.201
    prior movers: sst_seas_amp_SH +4.145 | sst_seas_amp_NH +1.632 | rep_dC +1.088

⇒ **the entire gain is PRIOR credit on the seasonal amplitudes, bought by making the FIT WORSE.**
Those are the known prior-data conflict ([[seas_amps_hemispheric_inversion]], `sst_seas_amp_SH` at
z ~ -6.3). **Stage B held all 16 of those parameters FIXED**, so they could not move; the crippled
smoke let them go where their priors want and dragged `h_ml` down the softest direction with them.
**FIRST verified the rows ARE scored at 35.38 m** — sum **-7.876**, `sd_eff/sd_obs`
**1.322 / 1.483 / 1.055** — so the implementation is correct.

⇒ **The real refit needs its FULL restart/cycle budget; a crippled run wanders down soft directions
trading likelihood for prior.** And the seasonal-amplitude prior conflict is now the DOMINANT
gradient in the refit, which is how the coming run should be read.

## 4. ⇒ WHAT IS OWED, IN ORDER — **THE REFIT IS THE BLOCKER**

1. ⚠ **RUN THE 21-PARAMETER REFIT.** `calibration/run_modefind_pump_arms.R`, ~18 h, warm-started.
   Seed a dated `CCX_ARM_OUTDIR` with a copy of the canonical mode so `ARM_WARM` picks it up
   (`par_mode` is band-INDEPENDENT, so warm-starting across the objective change is safe).
   **Run from a FROZEN COPY, pin BLAS to one thread, hold the process.**
2. **THEN quarantine** `calibration/output/refit_20260825f_from90/` to
   `calibration/output/quarantine/20260828_sigma_inflation_adopted/` with a README, and repoint
   `ccx_mode_file()`. **Not before** — see §0.4.
3. **Re-run `diag_hess_eps_21par.R`** (kink count changed) and **`recompute_hessian.R`**.
4. **Re-run the design gates** (`diag_design_gates_at_mode.R`, `diag_design_gates_unscored.R`,
   `diag_joos_irf.R`) at the new mode; no gate verdict here is current.
5. The 4 banner-flagged mirror diagnostics need re-running unbounded to be comparable.

## 5. ⚠ A QUALIFIER ON MY OWN EARLIER FRAMING

I argued that option 5 unblocks the posterior by removing the discontinuity in the softest
direction. **That needs narrowing.** Widening the refit's kink scan to the full support finds
**26 kinks in [30, 200]** — 46.85, 47.68, 49.51, 50.00, 73.05, ... 199.86, many on round numbers.
Option 5 removes the **band CLIFF** (+7.30 / +8.43), by far the largest defect; the **`1/eps` pump
kinks are SEPARATE and pre-existing** ([[ccx_hml_kink]] had 3 inside the band alone) and are
untouched. **`h_ml` is not now smooth**, and the posterior argument should not be made as if it is.

## 6. NON-OBVIOUS STATE

- ⚠ **`ccx_loglik()` now STOPS on an `ocean_grad` without `sd_eff`.** Any driver that hand-builds one
  must use `ccx_ocean_grad_scored()`. ~28 of 30 already did and needed no edit.
- ⚠ **`data/obs_glodap_sigma_rep.rds` is a hard dependency of the objective.** Without it
  `ccx_ocean_sigma_eff()` errors by design rather than falling back to sigma_obs.
- **Everything in the 08-28 handoff §7 still stands** — `ccx_mode_params()` never
  `ccx_unc_to_par(md$u_mode)`; `by_stream` returns a named VECTOR so test membership not nullity;
  write the artifact before the pretty-printing; spell out `md$u_mode`.
- ⚠ **The harness offset −1.5805 is a PRE-ADOPTION number** and is not current.
- `run_modefind_pump_arms.R:379`'s `rm()` warnings are PRE-EXISTING, not from this work.
- ⚠ **`MEMORY.md` root 17.7 KB (soft 12) and `INDEX_ccx.md` 15.0 KB (soft 14).** Flagged, not
  restructured; this session added one sub-index bullet and one memory file.

## 7. HOW TO RUN WHAT THIS SESSION ADDED

    Rscript data-raw/build_glodap_sigma_rep.R           # ~3 min, regenerates the sigma_rep table
    Rscript tests/run_tests.R                           # ~5 min, 1203/0
    CCX_ARM_OUTDIR=<dir> CCX_ARM_RESTARTS=1 CCX_ARM_CYCLES=1 CCX_ARM_MAXIT=60 \
      Rscript calibration/run_modefind_pump_arms.R      # ~14 min smoke; seed <dir> with the mode
    Rscript calibration/run_modefind_pump_arms.R        # ~18 h PRODUCTION -- the owed refit
