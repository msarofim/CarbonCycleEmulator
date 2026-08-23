# Handoff — CarbonCycleEmulator, 2026-08-23: the sweep, the refit, and `rep_dC`

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`, clean at `277959b`.
**Follows:** `notes/handoff_2026-08-22_panel_and_three_tests.md`. That handoff's §§1–6 stand.
This one discharges its §7 work list, runs the refit it said was owed, and **re-poses two of its
items** — panel #7 (gates at defaults) and panel #12 (`rep_dC`'s prior).

---

## 0. STATE IN TWELVE LINES

1. **The objective is unchanged since `d6adb58`.** Nothing here changed it. No refit is owed.
2. **The arm-N refit RAN and CONVERGED** on the post-`d6adb58` objective. Log-post **−1859.32**.
   `mode_fit_pumpN.rds` is the shipped mode; `app/global.R` picks it up automatically. §3.
3. **NO DESIGN GATE CHANGED VERDICT. Three drifted slightly worse.** +16.9 log-units of genuine
   objective correction bought no physical improvement. §3, and it is the session's main result.
4. **Gate 12 (Joos IRF) FAILS at all three horizons** — 11.69 / 23.81 / 39.06. §2.
5. **Gate 4 splits**: level 0.434 (best recorded) but decadal variability **2.7× too smooth**, and
   gate 4 is imbalance-immune where gate 7 is not. §2. This is the best-posed open target.
6. **Gate 5's τ_ex miss is FORCED**: the bomb lag wants τ_ex ≈ 2.3, both gradient streams sit at a
   sharp interior optimum at 1.03 and reject 2.0 by ~1490 logL. Structural. §2.
7. **The `luc_scale`-squared bug was EIGHT sites, not one.** Objective never affected; the stored
   per-stream tables were. Swept, gated, arm files repaired. §4.
8. **`diag_fit_at_mode.R` was stale five ways** and printed MISMATCH on all 14 rows while its
   rankings were quoted into memory. Fixed; its gate is now fatal with an empty allow-list. §4.
9. **The per-direction Hessian is folded into the refit driver.** No more manual second step. §5.
10. **`rep_dC`: panel item #12 does not survive measurement.** Re-centring moves the fit ≤0.03 ppm
    and only relabels the flag. The prior was NOT changed. §6.
11. **Marcus's challenge to §6's framing is live and only partly answered.** §6b — the test that
    would settle it needs data not in the repo.
12. **Still no posterior.** The sampler has never converged. Everything here is single-point.

---

## 1. WHAT WAS ASKED AND WHAT WAS DONE

Session ran: panel item #7 → the `luc_scale` sweep → the refit → the Hessian fold-in → `rep_dC`.
Commits: `88c314f`, `5d9bc0f`, `5aeaed0`, `517e823`, `d7c985e`, `277959b`.

---

## 2. DESIGN GATES AT THE VECTOR THE APP SHIPS

`calibration/diag_joos_irf.R` was hardcoded to `ccx_default_params()` and grew a mode path
(`[defaults|N|D]`, ~7 s). New `calibration/diag_design_gates_at_mode.R` (~9 s) covers gates 4, 5,
7 plus a provenance gate. Both carry `bomb_total` and `luc_scale` through a wrapper — on gate 5
that is not a refinement, it is the whole measurement.

| gate | defaults | pre-refit mode | **refitted mode** | verdict |
|---|---|---|---|---|
| 12 Joos IRF (TH 20/50/100) | 12.43 / 25.53 / 41.86 | 11.74 / 23.97 / 39.36 | **11.69 / 23.81 / 39.06** | **FAILS all three** |
| 4 airborne fraction | 0.426, sd 0.035 | 0.435, sd 0.019 | **0.434, sd 0.019** | level passes, **variability 2.7× too smooth** |
| 5 bomb NH peak / lag | 801.5 ‰ / 1.12 | 892.3 / 0.91 | **888.5 ‰ / 0.92** | **FAILS** (obs 855.3 / 1.34) |
| 7 sinks (land σ) | +2.23 | +2.04 | **+2.12** | **FAILS on land** |

**Gate 12's background is not the explanation and points the other way**: the mode's held 2010
background is 394.8 ppm vs the defaults' 387.6, and a higher background makes a pulse last
*longer* (in-model PI 33.9 vs PD 42.1). It fails in spite of a bias in its favour. `ccx_irf()` is
a paired difference so the imperfect hold cancels.

**Gate 4 is the imbalance-immune target.** AF = growth ÷ emissions; GCB's `imbalance` is the
residual *after* the sinks, so it enters neither term — unlike gate 7, which the 08-22 handoff
§3b argues may be unreachable by construction. **Target sd 0.051, model 0.019.** This is the
number 08-22 §4's pre-registration clause asked for.

**Gate 5 and τ_ex — the substantive find, and the opposite of what I set out to confirm.** I wrote
into DESIGN that the bomb lag and gate 9's gradient concur that τ_ex is too fast, inferred from
the sign of a stored log-unit, then profiled it before letting it stand. **It is false.** The lag
rises monotonically with τ_ex and needs ≈2.3 yr for the observed 1.34; both gradient streams sit
at a **sharp interior optimum at 1.03** and reject τ_ex = 2.0 by ~1490 logL on `co2_gradient`
alone. **The two interhemispheric observables disagree and the gradient outvotes the bomb lag by
three orders of magnitude**, so gate 5's lag miss is a FORCED residual — a structural statement
about one exchange time serving both a station pair and a hemispherically-integrated tracer.
Frozen 1-D profile, so magnitudes are upper bounds ([[ccx_seas_q10_ridge]]); the ordering is robust.

**WITHDRAWN:** "TH 50 and TH 100 are ON the floor." Fair at −0.13 / −0.35 %; not at
**−0.78 / −1.12 %**. Gate 12 now fails clearly, not marginally.

---

## 3. THE REFIT

Arm N only. 623.9 min, 266,961 evals, 0.140 s/eval, warm start. `refit_20260822.log`.

- **Converged, and the 08-20r pathology did not recur.** Cycle 1 hit the 20-restart cap (gain
  1.7295), polish gained **0.0359** against the **16.08** that exposed the un-located mode last
  time. Cycle 2: 0.0000 twice, stop. **The polish gain is the diagnostic — read it before
  trusting any mode.**
- **The 10.4-hour run landed where a ~20-minute smoke run did** — same log-post to four decimals,
  **max 0.0016 sd apart**. Good evidence the mode is real, and grounds to scope the next
  small-change refit at ONE warm cycle. Use `CCX_ARM_{OUTDIR,RESTARTS,CYCLES,MAXIT}` (added
  2026-08-22); `ARM_OUT()` derives from `ARM_OUTDIR`, so redirecting output redirects the
  warm-start source too and cannot clobber the shipped mode.
- **Measure displacement, never infer it from Δlogpost.** Gain 1.7; move **RMS 0.577 sd**, three
  coords over 1 sd: `rep_dC` **+1.60**, `k_w` **−1.35**, `bomb_total` **−1.21**.
- **`rep_dC` got WORSE: 5.18 → 5.57 σ.** The ice fix sharpens that blocker. Beyond 3 σ now:
  `sst_seas_amp_NH` −6.22, `rep_dC` +5.57, `sst_seas_amp_SH` −4.25, `seas_T_amp_SH` −3.95.
- `kz` **6452, still 97.1 % up its bracket** — the standing question, unmoved.

---

## 4. THE `luc_scale` SWEEP AND THE STALE DIAGNOSTICS

**Eight sites** applied `luc_scale` twice to the gross-land-sink reconstruction. **Four
near-identical-looking sites were CORRECT** — they take `eluc` from the UNSCALED base
(`diag_dic_gradient`, `diag_h_ml_roles`, `diag_ocean_candidates`, `diag_hml_band_discontinuity`).
That is the discriminator and two passes of the scan missed it. `ccx_make_logpost` never had the
bug, so **no fit was ever affected**; the stored per-stream tables were. Blast radius is exactly
`gcb_land_sink`.

`ccx_load_mode()` / `ccx_scaled_forcing()` in `R/calibrate.R` return the forcing and its `eluc`
from ONE call. **`test-luc-scale.R` gained a repo lint and a numerical twin against
`ccx_make_logpost`. Both mutation-tested — and the numerical one FAILED its first mutation**,
because at `ccx_init_unc()` `luc_scale` is exactly 1 and `bomb_total` exactly 102, so a
multiplicative bug is invisible there. Both are now perturbed off their inits. **The lint then
caught a regression I introduced myself.**

Arm files repaired by `calibration/repair_arm_streams.R`; pre-repair copies in
`output/quarantine/20260822_luc_scale_squared_streams/`. Each carries `streams`,
`streams_as_fitted`, `streams_provenance`.

**`diag_fit_at_mode.R` was stale five ways**, all silent, while its own gate printed MISMATCH on
all 14 rows and the file went on printing the rankings quoted into memory: the
`seas_drivers/sst_obs` escape hatch (the mode carries DRIVER params, not sine knobs); `rep_dC`
never applied; `sigma_d13c`'s retirement giving **n = 0** on both d13C rows; ice still `co2_NH`;
and **gate 7's land σ hardcoded 0.9** — `LIK_GCB_LAND_SD`'s pre-2026-08-14 value.
**So memory `ccx_fit_at_mode`'s "gate 7 PASSES" was wrong**; at σ = 0.5 it is land +1.9σ, FAILS.
Same hatch removed from `diag_rep_dC_gates.R` and `diag_station_representation.R`;
`diag_rep_dC_gates.R`'s GATE 1 retargeted (it was failing by 880.6 against a superseded contract).

**WITHDRAWN:** "`gamma_enso` is dropped by `intersect()`." I wrote it into a comment and a
docstring off a crude grep, then checked before acting on it across 11 files. It is in
`ccx_default_params()` and in `CCX_PARAM_NAMES`. Both corrected.

---

## 5. THE HESSIAN

`ccx_hessian_per_direction()` **promoted** to `R/calibrate.R` (not copied — copying would have
recreated the duplication §4 spent a day removing). Both the refit driver and
`recompute_hessian.R` call it. `ARM_HESS_EPS` retired to reporting-only.

Verified: driver vs reference `max|ΔH|/max|H|` **1.4e-8**; rewired `recompute_hessian.R` vs its
own prior output **bit-identical**. Confirms `ccx_hess_step_sd` by measurement — the scalar 3e-4
is **250× too small for `h_ml`, 167× `kz`, 67× `gamma_enso`**.

**A 3.0e+04 "relative difference" in the first comparison was a DENOMINATOR ARTEFACT** — worst
cell `[rep_dC, bomb_total]` where the reference is exactly 0.0. **Compare Hessians by matrix
norm, not cell-wise.**

Two silent defects fell out: the kink-proximity check computed the Hessian's `h_ml` reach from the
**scalar** step (certifying a step the Hessian never took, on the softest direction); and the
step-stability block re-ran its sweep at that same scalar at a loose 0.25 tolerance. Both now use
each direction's actual step at 0.02.

---

## 6. `rep_dC` — PANEL ITEM #12, RE-POSED

`calibration/diag_rep_dC_prior.R` (~4 min). **The prior was NOT changed.**

### 6a. What was measured

- **The centre is nearly inert.** Likelihood-only optimum **5.62 ppm, curvature sd 0.097** with
  `k_w`/`bomb_total` re-optimised — the data are ~10× tighter than the 1.0 ppm prior.
  **Re-centring anywhere in [0, 3] ppm moves the posterior ≤ 0.03 ppm** and moves `prior_z`
  5.57 → 3.59 at μ = 2. **Demoting the top-ranked flag by relabeling is
  `prior_z_grid_scale` repeated on purpose.**
- **The prior sd has no receipt for the quantity it constrains.** `LIK_CO2_REP_ERR` = 1.0 ppm is
  both the CO₂-level stream sd and this prior's sd; its receipt is **co-located INSTRUMENT
  disagreement at one site**, and the comment concedes a station-vs-box term "must exceed it.
  1.0 ppm is a plausible value."
- **Era decomposition.** `rep_dC` applies to MLO/SPO only; the ice block scores the bare box.
  Flask era (box − station): 4.67, 5.81, 5.83, 5.44, 5.58 — **constant to ~1 ppm over 66 yr,
  MLO/SPO agree to ~0.3 ppm, and the fitted 5.57 == the flask-era mean 5.47**. Ice era
  (box − obs): **−1.89, −3.86, −0.67**. Swing ≈ **9.4 ppm**.

### 6b. MARCUS'S CHALLENGE — LIVE, AND ONLY PARTLY ANSWERED

> *"ice core vs direct measurements are so different that I wouldn't be surprised at very large
> change in offsets. I'm not sure why the offset can't change sign."*

**The challenge is well founded and my sentence was an assertion, not an argument.** Part 3
compared an offset-CORRECTED residual against an offset-FREE one and called the difference a sign
flip in one quantity. It is not one quantity. Firn smoothing on a rising curve, Δage placement and
a different calibration scale are all real mechanisms for the two systems to differ.

**TEST RUN (model-independent, the records overlap):** 47 samples, 1962–1996 —
**ice − SPO = −0.31 ± 0.15 ppm** (sd 1.05), **trend −0.008 ppm/yr, p = 0.57**; ice − MLO = −1.81
(the gradient, as expected). The systems agree to a third of a ppm, with no drift, in the window
where firn smoothing should be **largest**.

**THE LIMITATION THAT MUST RIDE WITH THAT NUMBER.** The record on disk is the **Rubino et al.
(2019) Law Dome SPLINE** (DATA.md:52), not raw ice/firn samples. If that spline is constrained by
atmospheric data over its modern end — exactly this overlap — the agreement is partly **by
construction** and this is not an independent cross-validation. **Nothing in the repo settles
which.** Treat −0.31 ppm as an upper bound *conditional on the spline being independent there*.

**Secondary, and coupled to the panel's ice-covariance item:** the ice term's stated σ is ~4.04
ppm against a **measured** scatter of 1.05 ppm about the flask record. Either the σ carries a
representativeness allowance the overlap says is unnecessary, or the term is ~4× under-weighted.

### 6b-RESOLVED (2026-08-23, later the same day)

**Tests 1 and 2 were run and the challenge is settled — the offset does NOT differ; the
transition problem is real for another reason.** Full write-up:
`notes/lit_2026-08-23_1940s_co2_plateau.md`.

- **The circularity caveat above is RETRACTED.** `obs$ice` is the RAW sample file, not the spline
  — DATA.md:52 mislabelled it (now corrected). Overlap 1962–96: ice − SPO **−0.31 ± 0.15 ppm**;
  split by type **FIRN −0.40 ± 0.19 (n=20), ICE −0.24 ± 0.23 (n=27)**, differing by 0.16 ppm
  (t = −0.53, n.s.). Both independent of Scripps ⇒ genuine cross-validation. **Test 1 needed no
  download: the data were already on disk** — the second time that lesson has applied here.
- **Test 2:** pre-1958 residual, n=160, on **dCO₂/dt R² 0.209** (slope −11.7, p = 1.2e-09) versus
  **cumulative emissions R² 0.045**. Growth rate wins 4.6×, and its sign is **opposite** to what
  firn smoothing predicts. Placement error is bounded by Test 1 at ~60× too small.
- **THE LITERATURE IS THE ANSWER.** The mid-century pause is the published **1940s CO₂ plateau**
  (~310–312 ppm, ~1940–1955), present in the revised Rubino et al. (2019) record we score
  against. It needs **2–3 GtC/yr over 1942–49 AFTER firn diffusion and bubble trapping are
  accounted for**. Bastos et al. (2016) put the model–obs mismatch at **0.9–2.0 PgC/yr** and
  conclude the ocean hypothesis "cannot be confirmed by independent data". **No model reproduces
  it.**
- **Consequences:** our 4.7σ pause IS this plateau; our **12.7σ terrestrial rejection agrees with
  the published δ¹³C attribution** (oceans ≥ two-thirds) and is stronger; and it coheres with
  GCB's own imbalance peaking at +1.30/+1.62 GtC/yr in the same decade. **"Make the model fit the
  mid-century" should be DE-RANKED** — it is an open problem in the field, not a defect here.

### 6c. THREE TESTS THAT WOULD SETTLE IT — 1 and 2 DONE (see 6b-RESOLVED); 3 still open

1. **Raw Law Dome samples (DE08 / DE08-2 / DSS) instead of the spline.** Removes the circularity
   in 6b outright. This is the decisive one and it is a download, not an analysis.
2. **Regress the ice-era residual on dCO₂/dt versus on cumulative emissions.** A firn/Δage
   artefact scales with the growth rate; a model budget error scales with cumulative emissions.
   Same shape as the GCB-imbalance regression that returned r = 0.771.
3. **Give the ice term its own offset parameter and see if it is identified.** Directly
   parameterises Marcus's hypothesis. If `rep_ice` is well determined and lands several ppm from
   `rep_dC`, the eras genuinely differ; if it is unidentified or lands near zero, they do not.
   Costs an objective change and therefore a refit — now ~1 warm cycle.

---

## 6d. THE 12.7 σ IS NOW ~5 σ (validated 2026-08-23)

**`diag_d13c_midcentury.R`'s σ was computed on `n`, not `n_eff`.** Law Dome's air-age spectral
width is 4.5–7.0 yr (Trudinger et al. 2002b via Bastos §2.1), so samples closer than that measure
**overlapping air**. The 1940–1960 window's **13 samples are four groups spanning 18 yr** →
span/width 3.6 draws, clustering 2. Corrected: excursion **± 0.016 → ± 0.041 ‰**, departure
**13.1 σ → 5.1 σ**, range **~5–7 σ** across the `n_eff` estimator. **Never quote 12.7 σ again.**

**The conclusion survives** — 5 σ still rejects a terrestrial explanation, so 2026-08-22 §4's
withdrawal of the LUC time-profile programme stands. **A third error term is unquantified and now
binding:** systematic/calibration drift that is *non-linear and localised near mid-century* (a
constant offset cancels by construction; a linear drift is absorbed by the fitted trend). Nothing
in the repo bounds it.

**The general lesson, and it is the transferable one:** this is the SAME non-independence the
2026-08-22 panel flagged for the CO₂ ice term, sitting undetected in the isotope term built from
the same samples. **When a correlated-rows defect is found in one stream, audit every stream built
from those samples.** The ice covariance item on the work list should now be read as covering both.

## 7. NON-OBVIOUS STATE

- `mode_fit_pumpN.rds` is **post-refit and post-per-direction-Hessian**. Its `streams` are correct
  by construction (driver fixed) and it carries no `streams_as_fitted` — that field exists only on
  the repaired pre-refit copies.
- `pre_refit_20260822/` holds the vector every 2026-08-22b gate status was measured at. Those
  numbers are NOT reproducible from the current mode file.
- **Arm D is a different objective from arm N** (last fitted before the 08-20g
  `CCX_SST_SEAS_LAG` fix, −8244 logL away). Never table them as an arm comparison.
- `diag_fit_at_mode.R`'s allow-list is **empty on purpose**. Add a name only with a dated reason.
- `recompute_hessian.R` is now a REPORTING wrapper; the computation is in `R/calibrate.R`.
- The 08-22 handoff §6 trap list still applies in full.

---

## 8. OPENING THE NEXT SESSION

```bash
cd ~/Documents/2026/CodeProjects/CarbonCycleEmulator && claude --remote-control ccx-dev
```

> Read `notes/handoff_2026-08-23_sweep_refit_and_rep_dC.md`. The objective is unchanged since
> `d6adb58` and the arm-N refit has landed — **no refit is owed**.
>
> **The session's result is that a correct, +16.9-log-unit fix to the objective moved no
> observable.** No DESIGN gate changed verdict and three drifted worse. Combined with gate 5's
> forced τ_ex residual, the open questions are **structural, not calibration**.
>
> **Live and unresolved:** Marcus's challenge in §6b. The ice-vs-flask overlap says −0.31 ppm,
> but the record is a spline that may be atmospherically constrained there. §6c lists three tests;
> **#1 is a download and would settle it.**
>
> **Best-posed target:** gate 4's decadal airborne-fraction variability — 0.019 against 0.051,
> imbalance-immune, unmoved by the refit.
>
> **Cheapest unstarted, all still open from 08-22 §7:** the gate-7 closure check (~0.69 GtC/yr,
> ~30 min); cement carbonation (0.42 σ, free); the app's 65.6 s startup (1 h, launch blocker);
> the ice covariance `diag + s²11ᵀ` profile — **now coupled to §6b's σ finding, take them
> together**. And `q10`'s structural incapacity (γ_L ≈ −4 vs C4MIP −45.1 ± 50.6), the largest
> listed item at 3 h–3 d.
>
> **Do NOT** re-run arm D, re-centre `rep_dC`'s prior, or scope a small-change refit at 20
> restarts — a warm cycle finds the same mode.
