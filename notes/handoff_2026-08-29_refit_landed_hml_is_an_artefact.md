# Handoff — CarbonCycleEmulator, 2026-08-29: **THE REFIT LANDED, CONVERGED, AND MUST NOT BE ADOPTED**
# `h_ml` = 35.38 m is prior credit spent moving ocean structure the WRONG way.
# **NEXT STEP (Marcus, 08-29): the SH LAND OVERSHOOT.**

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`, clean at `b496b8a`.
**Suite 1206 pass / 0 fail.** Nothing is running. Continues `handoff_2026-08-28d_*`.

⚠ **SESSION CWD WAS `FaIRtoFrEDI/`; ALL THIS WORK IS IN `CarbonCycleEmulator/`.**
⚠ **NOTHING IS QUARANTINED AND NOTHING IS REPOINTED.** `ccx_mode_file()` still resolves `from90`.
That is a DECISION (§3), not an unfinished step.

---

## 0. STATE IN SEVEN LINES

1. **The refit LANDED 06:39:50 after 10.9 h and CONVERGED** — cycle 2 gained exactly 0.0000. §1
2. ⚠ **It reproduced the 14-minute crippled SMOKE TEST to three decimals**, which INVERTS
   08-28c §3's reading of that smoke. §1
3. ⚠ **The +4.06 is ENTIRELY PRIOR CREDIT; the fit got WORSE by 1.199.** §1
4. ⚠ **`h_ml` = 35.38 m is an ARTIFACT, not a repair** — MEASURED twice, §2.
5. ⚠ **I ASSERTED THE PHYSICS BACKWARDS and retracted it in place** — a shallower mixed layer makes
   the SH ocean limb SMALLER, not larger. §2
6. ⚠ **I ALSO WITHDREW my own "decoupling" explanation** when its test fired P2. §2
7. ⇒ **NEXT: THE SH LAND OVERSHOOT (1.92× observed).** Two independent arcs now point at it. §4

---

## 1. THE REFIT: CONVERGED, AND THE SMOKE TEST WAS RIGHT ALL ALONG

`calibration/output/refit_20260828_sigma_eff/`, 274,722 evals, **0.142 s/eval** measured six times.
Cycle 1 gained **+4.0598** over 20 restarts (10.5 h); **cycle 2 gained exactly 0.0000** in 9 minutes
and `CONVERGED: cycle gain below ARM_CYCLE_TOL` fired. NM restarts *and* BFGS polish both gain zero
from the cycle-1 mode: **the mode is located.**

⚠ The driver's `*** HIT THE RESTART CAP WHILE STILL GAINING` banner fired on cycle 1 and is a
**FALSE ALARM** here — it is THRESHOLD-triggered (`ARM_TOL` 1e-4) and restart 20 gained 0.0012,
0.03% of the cycle. On 08-20r the polish then gained **16.08**; here it gained **0.0317**, ~500×
smaller. Do not read that banner without its magnitudes.

**⚠ THE PRODUCTION REFIT REPRODUCED THE CRIPPLED SMOKE TEST TO THREE DECIMALS.**

| | smoke (14 min) | production (10.9 h) |
|---|---|---|
| Δlogpost | +4.060 | **+4.060** |
| = prior | +7.399 | +7.397 |
| jac | −2.139 | −2.139 |
| **loglik** | **−1.201** | **−1.199** |
| `h_ml` | 35.38 m | **35.38 m** |

⇒ **08-28c §3's reading is INVERTED.** It called the smoke's 35.38 m an artifact of its budget —
*"a crippled run wanders down soft directions… the real refit needs its FULL restart/cycle budget."*
It did not wander. Twenty restarts, two cycles and a polish went to the same point. **The smoke was
measuring the mode.** What §3 got RIGHT is the part that matters: the gain is prior credit.

Prior movers: `sst_seas_amp_SH` **+4.326**, `sst_seas_amp_NH` +1.769, `rep_dC` +1.087; `h_ml`
itself **COSTS −2.049**. `kz` still rails at 95.3%. `prior_z` improved for every flagged parameter
(`sst_seas_amp_SH` −6.321 → −5.595) while `h_ml`'s |z| went 0.446 → **1.857**.

## 2. WHY 35.38 m IS AN ARTIFACT — TWO MEASUREMENTS, AND TWO RETRACTIONS OF MINE

**(a) `diag_hml_seasonal_limbs.R` (`924711d`) — the REPAIR hypothesis, REFUTED.** Method copied from
`diag_admissible_2x2_land_ocean.R`, not reinvented: same knockout cases, same PEAK-TO-PEAK `amp()`,
same `ang_mo()`. Predictions written before the run.

|             | old (96.47 m)   | new (35.38 m)   | obs          |
|-------------|-----------------|-----------------|--------------|
| TOTAL       | 1.1402 @ 8.71   | 1.1307 @ 8.74   | 1.168        |
| **SH_ocean**| 0.2480 @ **4.17**| 0.2577 @ **3.90**| 0.522 @ **8.52** |
| SH_land     | 1.3080 @ 10.09  | 1.3206 @ 10.08  | 0.683        |
| NH_origin   | 0.8206 @ 6.46   | 0.8264 @ 6.47   | —            |

P1 passes only trivially (48% → **49%** of observed, on a defect needing a doubling); **P2 FAILS** —
the phase rotated AWAY from obs. This arc's own lesson, again: **limbs are VECTORS**, and a
magnitude moving the wanted way can still be a phase error that makes the sum worse. At ~4 mo
against land at ~10 the limbs are 6 months apart and still SUBTRACTING.

**(b) `diag_hml_sst_elasticity.R` (`b496b8a`) — MY explanation, REFUTED; and the physics INVERTED.**
I had inferred that a shallow layer DAMPS the transfer from `sst_seas_amp_SH` to the limb, letting
the fit buy prior credit by neutering the parameter. **P2 fired and I withdraw it:**

    elasticity d ln(SH_ocean limb) / d ln(sst_seas_amp_SH)
       h_ml 35.38 m : 1.0002        h_ml 96.47 m : 0.9999      ratio 1.0003

Identical, and both exactly 1 — the limb is precisely LINEAR in the parameter at either depth.
(Design is what made this readable: ONE base vector, only `h_ml` and `sst_seas_amp_SH` varied.
Comparing "sensitivity at the old mode" vs "at the new mode" would confound `h_ml` with the other
twenty coordinates. P3 confirms power: ±20% moves the limb 50%.)

⚠ **AND IT INVERTED THE PHYSICS I ASSERTED.** At FIXED `sst_seas_amp_SH` = 0.4312:

    h_ml 96.47 m -> limb 0.3066  (58.7% of obs) @ 4.15 mo
    h_ml 35.38 m -> limb 0.2577  (49.4% of obs) @ 3.90 mo        obs 0.522 @ 8.52

**A SHALLOWER MIXED LAYER MAKES THE SH OCEAN LIMB SMALLER, NOT LARGER.** I wrote the opposite into
`diag_hml_seasonal_limbs.R`'s header as motivating physics; **retracted in place, at the site, with
the measurement**. The phase is INDEPENDENT of `sst_seas_amp_SH` (3.90 at all three grid values) and
moves only with `h_ml`.

⇒ **The real story.** `h_ml` → 35 m **DEGRADES** the limb that is already ~2× too small (59% → 49%)
and rotates its phase further from obs. The 20% rise in `sst_seas_amp_SH` is **COMPENSATION for that
damage** and does not fully repay it. The +4.06 is prior credit bought by moving ocean structure in
the **ANTI-physical direction** relative to the arc's known defect.

⚠ **ALSO RETRACTED: my "revisit the `sst_seas_amp_*` priors" suggestion.** `ccx_prior_z()` is the
POST-fix implementation — unconstrained coordinate, Jacobian included, prior's own mode found by
scan, BOTH tails carried with the smaller used (a z of −6 is a lower cumulative of 1e-9 that
`1 − upper` would destroy). **The −6.32 is real, not a scale artifact.** And `INDEX_ccx_seas.md` is
explicit that the priors are the part ANCHORED ON OBSERVATIONS: `sst_seas_amp_SH` sits at ~21% of
observed *because* SH land is ~1.9× too big and the ocean must shrink to hold the observed total.
**The prior is not what is wrong. The partition is.** I reasoned from the z magnitude without
reading the seasonal sub-index first.

## 3. THE DECISION, AND WHY NOTHING WAS TOUCHED

**RECOMMENDATION: do not adopt `refit_20260828_sigma_eff` as canonical.** It is the legitimate
posterior mode of the adopted objective, but *posterior mode* and *better model* have come apart:
the likelihood is worse by 1.199 and the ocean structure moved the wrong way. Quarantining and
repointing would make this the vector every diagnostic **and the app** resolve to.

⇒ **Everything is HELD.** `ccx_mode_file()` still resolves `from90`; `refit_20260825f_from90/` is
still at its canonical path; `run_post_refit_adoption.R` stages `quarantine` / `repoint` / `rerun`
have **never been run**. Only `--stage=check` (5/5 pass) and `--stage=read` have.

⚠ **This looks like a problem with OPTION 5, not with the refit.** Freeing `h_ml` let the seasonal
prior conflict pay itself out through ocean structure, because the CO2 seasonal rows **have no power
to object** — they are already matched by cancellation ([[seas_right_observable_wrong_drivers]]).
The `[85, 120]` band was suppressing that, for the wrong reason and at the cost of a +7.30/+8.43
cliff, but it *was* suppressing it. A candidate that keeps option 5's σ-inflation while denying it
the anti-physical lever is **refit with `h_ml` PINNED at ~96**; not run, not decided.

## 4. ⇒ NEXT STEP (Marcus, 08-29): **THE SH LAND OVERSHOOT**

**Two independent arcs now point at the same defect.** The seasonal arc reached it from the
partition side; this refit reached it from the ocean side, by showing that the ocean limb cannot be
fixed by ocean structure — `ent` is vetoed, `tau_ex` exonerated, `(phi_eff, amp)` a degenerate
ridge, and now `h_ml` runs the WRONG WAY. **Measured here: SH land 1.3080 → 1.3206 against obs
0.683 = 1.92× → 1.93×, untouched by everything tried.**

⚠ **Read `INDEX_ccx_seas.md` before starting.** It is NOT auto-loaded and it is the active arc.
What it already establishes, so none of it is re-derived:

- **THE BIGGEST SINGLE CLUE: `0.821` of the model's `1.373` SH land is IMPORTED FROM THE NH** —
  more than the ENTIRE observed SPO land component (0.683). [[seas_spo_two_wrong_pieces]]
  ⇒ this is a **TRANSPORT / partition** question, not an amplitude one, and it is the largest
  unexplained term in the budget.
- **THE SIZE SHOULD GO *UP*; the missing piece is CANCELLATION.** `SEAS_NPP_AMP_SH` is **NOT** the
  bug — at phi = −30 MOD17 gives A = 0.50 but CMIP6 **0.94**, a 1.9× disagreement the OPPOSITE way
  from the assumed bracket. CT2022 has SH land canceling **74.9%** of its gross swing vs NH 31.8%
  (2.72× asymmetry) and **the model UNDER-CANCELS**. [[sh_land_undercancels]]
- **The SH (shape, size) pair is a DEGENERATE RIDGE — the SH latitude is NOT determined.**
  [[sh_pair_is_a_degenerate_ridge]]
- **Both single levers are VETOED by the same row, `co2_seasonal_SPO`**, and they cost the SAME at
  the margin (193.0 vs 206.8 per ppm, 7% apart). [[ccx_seas_slice_q10_leak]]
- **`q10` is SHARED and is an ESCAPE ROUTE** — a slice leaked **64%** of its lever through it.
  **Pin `q10`, leave `seas_T_amp_NH` free.** [[ccx_seas_q10_ridge]]

**Cheap and NOT RUN, in the order I would take them:**
1. **The controlled q10 test.** The 82% (27j) vs 42% (27q) channel-recovery contrast is CONFOUNDED
   by `q10` free vs pinned. The sub-index says the controlled version is **cheap and not run**.
   Do this first — it decides whether the recovery fraction is even a stable number.
2. **The NH-import channel.** Quantify and attack the 0.821-of-1.373 import directly; it is the
   biggest term and nothing has been aimed at it.
3. **The NH box's own seasonal amplitude — STILL UNCHECKED** and listed as such.
4. Only then 4b (the amplitude pair), which is where the arc's own "indicated target" sits.

## 5. NON-OBVIOUS STATE

- **`--retire-pin90` is the DEFAULT** in `run_post_refit_adoption.R` (Marcus 08-28). ⚠ My "six
  diagnostics name it" was **WRONG — it is TWO**; the rest were filename matches, not call sites
  ([[audit_live_paths]]): `diag_stream_neff.R` / `seed_fert_ridge_arms.R` mean **`ridge_pin90`, a
  DIFFERENT arm**, and `diag_design_gates_at_mode.R` names it only in comments.
- **The band mirrors were swept BY WHAT THEY DO WITH THE CONSTANT** (08-28i). `diag_hess_eps_21par`
  and `diag_stream_neff` WIDENED; `diag_ridge_reparam` widened **and its absolute logpost ladder
  shifted by the derived −1.5805 = −log(170/35)**; **`diag_landed_gap_streams` deliberately NOT
  widened** — its GATE 1 reproduces logposts STORED by band-fitted arms, so widening fails it by
  construction. ⚠ **The band CONSTANT stays**: `test-sigma-inflation.R:74` needs `c(85, 120)` to
  test that the cliff at those edges is gone.
- ⚠ **STILL OWED from 08-28d:** (a) `test-mode-file.R`'s `expect_gt(lp[["pin90"]], lp[[CANONICAL]])`
  compares two STORED logposts — across the objective change that is **meaningless, not merely
  false**; rewrite the PREMISE, do not relax it to green. (b) `diag_landed_gap_streams.R` is a
  PRE-ADOPTION driver whose every arm is retired; **re-point or quarantine is a decision**.
- **None of the four edited mirror diagnostics has been EXECUTED**; their on-disk outputs are
  pre-adoption.
- **`ccx_mode_params()`, NEVER `ccx_unc_to_par(md$u_mode)`** — the old mode decodes to 85.73 m
  instead of 96.47 under the shipped band. Both new diagnostics use the former.
- ⚠ **TWO PARAMETER LISTS THAT LOOK INTERCHANGEABLE.** `ccx_mode_params()` returns the FITTED 21;
  `ccx_spinup()` needs the full set and dies inside `ccx_dic_for_pco2()`'s `uniroot` without it —
  but merging onto `ccx_default_params()` SILENTLY DROPS `bomb_total` and `luc_scale`. Mirror
  `ccx_make_logpost()`. [[ccx_two_param_lists]]
- **`ent_seas_amp_SH` = 0 (shipped default, NOT fitted) in both new diagnostics.** It is not one of
  the 21. Any arm that means to exercise the entrainment channel must set it explicitly.
- ⚠ **`MEMORY.md` root 18.3 KB (soft 12); `INDEX_ccx.md` 16.1 KB (soft 14).** Over soft, flagged
  three sessions running, still not restructured.

## 6. HOW TO RUN WHAT THIS SESSION ADDED

    Rscript calibration/run_post_refit_adoption.R --stage=check   # 5/5, read-only
    Rscript calibration/run_post_refit_adoption.R --stage=read    # the decomposition
    Rscript calibration/diag_hml_seasonal_limbs.R                 # ~4 min, 8 runs
    Rscript calibration/diag_hml_sst_elasticity.R                 # ~6 min, 8 runs
