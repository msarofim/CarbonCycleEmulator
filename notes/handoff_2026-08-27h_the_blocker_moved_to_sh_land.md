# Handoff — CarbonCycleEmulator, 2026-08-27h: **4a IS BUILT, AND THE BLOCKER MOVED TO SH LAND**
# The channel works; the fit used it as a counterweight; the next slice is the decision owed

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`, **clean**.
**Nothing is running.** **Suite: 1157 pass / 0 fail** (was 1122; +35 from `test-so-entrainment.R`).
Nine commits, `173074c..bafd266`. Prereg `notes/prereg_2026-08-27g_so_entrainment_channel.md`,
scored in `notes/collect_2026-08-27g_entrainment_channel_is_a_counterweight.md`, CHANGELOG
2026-08-27g.

**⚠ A DECISION IS OWED BEFORE THE NEXT RUN (§4), and it is NOT the 4a/4b question any more.**

---

## 0. STATE IN SEVEN LINES

1. **Marcus took both 27g decisions**: scope **4a**, estimator **`|mean vector|`** (target 1.93×). §1
2. **4a is BUILT, in both cores, gated, and OFF by default.** §2
3. **P1 PASSED — the mechanism is available.** The ocean limb rotates ~6 months into place. §3
4. **P3 FAILED — the fit used it as a COUNTERWEIGHT instead**, and that is the result. §3
5. **The blocker is now SH LAND (2.05× obs, 60 % of it imported from the NH), not the ocean.** §4
6. **My own slice froze `tau_ex`, the only lever on that import** — so §4 is a real fork. §4
7. **4b is NOT what this residual points at.** Not a case against it; a case for ordering. §4

---

## 1. THE TWO DECISIONS ALREADY TAKEN (Marcus, 2026-08-27) — do not re-open

- **27g §4 SCOPE → 4a.** A second seasonal air-sea CHANNEL: one SH ocean box, no new state, no
  C++ column port. **4b (a genuine second SH ocean column) held CONDITIONAL on 4a's residual.**
  That residual is now in hand and is §4 below.
- **27g §7 ESTIMATOR → `|mean vector|`.** `CCX_SEAS_AMP_ESTIMATOR` in `R/likelihood.R`, with
  `ccx_harmonic_amp()` / `ccx_harmonic_peak_month()`. **The standing SPO partition target is
  1.93×.** This moved NO objective and NO gate — the likelihood scores the per-year sin/cos
  coefficients and never forms an amplitude, so it is reporting only.
  `diag_seas_isotope_rectification.R` now prints BOTH estimators and the per-series inflation.

## 2. WHAT IS BUILT

`ent_seas_amp_SH` — amplitude, µmol/kg, of a **zero-mean seasonal DIC anomaly on the SH mixed
layer**, peaking at `CCX_ENT_SEAS_PEAK_MO = 7.50`.

- **THE PHASE IS MEASURED, NOT FITTED** — ocean-area-weighted 40–90 S pCO2 first harmonic, same
  standing as `CCX_SST_SEAS_LAG` = 1.32. Band spread is the honest bar: 40–60 S peaks 7.10,
  60–90 S peaks 7.79. **No hemispheric sign flip** — it was measured IN the SH and is absolute.
- **It perturbs only the DIC entering the pCO2 calculation.** No state, no box, no vertical
  transport — this is 4a. It reaches the atmosphere through the existing evasion limb, which
  already carries `alpha_as_up`, so **what it adds is OCEAN-SIGNATURED**. That is the whole point.
- **SH ONLY**, and the asymmetry is measured: NH-mean pCO2 is **0.30 months** from NH-mean SST.
- **Default 0, and ABSENT = 0**, so every stored mode still runs the model it was fitted to.
- **NOT in `CCX_PARAM_TABLE`** — adding it would change the calibrated vector's length and
  invalidate the stored mode and its Hessian. It enters a fit as a bounded free scalar with **no
  prior**, which is why the refit script refuses to call its Δlogpost a model comparison.
- Twin in `src/ccx_core.cpp` (`ENT_SEAS_PEAK_MO`, `P.ent_seas_amp_SH`), gated by `test-parity.R`.

## 3. THE SCORECARD — two PASS, one PARTIAL, one INCONCLUSIVE, one FAILED

**No threshold was moved after the fact.** P2 missed on a gate set at exact equality with no
tolerance; P4 landed between its own two gates. Both are reported as they scored.

| | prediction | result | verdict |
|---|---|---|---|
| **P0** | method control | bit-identical at zero in BOTH cores; R/C++ parity ON; `seas_drivers` kills it; `ccx_total()` conservation | **PASS** (35 assertions) |
| **P1** | ≥ 0.70 ppm at SPO | **0.860 ppm at 10 µmol/kg**; ocean limb **0.247 @ 3.68 → 0.614 @ 9.91** | **PASS** |
| **P2** | amp ≥ 0.60, z > −5.0, SPO pair ≥ 287.2 | **0.741**, z **−3.43** ✓✓, SPO pair **286.1** ✗ | **PARTIAL** |
| **P3** | SPO ocean peak 3.35 → ≥ 6.0 | **3.45** (moved +0.10 mo) | **FAILED** |
| **P4** | residual 1.93× → ≤ 1.70×, MLO 0.90–1.10 | **1.77×**, MLO **0.97×** | **INCONCLUSIVE** |
| **P5** | no driver further from observed | all four moved TOWARD observed | **PASS** |
| **P7** | MLO control (inversion readable) | **113.9 %** | **PASS** |

### The one-line result

**The channel does exactly what it was built to do, and the fit declined to use it that way.**
Given the freedom, the optimiser spent the new limb on *permission to double the wrong-phase
solubility limb* rather than on replacing it.

| | mode | incumbent (control) | challenger |
|---|---|---|---|
| `sst_seas_amp_SH` | 0.360 | **0.371** | **0.741** |
| prior z | −6.32 | −6.20 | **−3.43** |
| % of observed 1.746 | 20.6 % | 21.2 % | 42.5 % |
| SPO ocean component | 0.236 ppm @ 3.35 | — | **0.124 ppm @ 3.45** |
| vs observed 0.522 @ 8.52 | 0.45× | — | **0.23×** |

**THE INCUMBENT CONTROL IS THE LOAD-BEARING PART.** Re-optimising the identical slice WITHOUT the
channel moves the amplitude 0.360 → 0.371. **The doubling is the channel's doing**, which is
exactly what the matched design (`match_incumbents_optim`) existed to separate.

**But the two limbs are near-antiphase and largely cancel, so the NET ocean component got WORSE.**
**The model reproduced the observed 76 % cancellation internally, with its own two limbs.**

**THE GAIN IS ALL PRIOR, MEASURED NOT INFERRED: +16.78 prior against −5.17 likelihood, net
+11.62.** The likelihood cost is thin and spread — `co2_seasonal_MLO` −1.59, `co2_seasonal_SPO`
−1.47, `d13c_seasonal_MLO` −1.45 — and nothing collapses.

The fitted amplitude is **4.16 µmol/kg, BELOW the 5–30 physical pre-check band**, and the script
flags it. P1 says ~8–9 is what closes the gap. **The fit chose about half.**

## 4. ⇒ THE DECISION OWED, AND IT IS A DIFFERENT ONE FROM 27g's

### Why the fit chose half — and it is not in the ocean

- **SH land at SPO is 2.05× observed** (1.364 against 0.665), and **0.821 ppm of the model's 1.364
  arrives FROM THE NH** — more than the entire observed SPO land component of 0.665.
- Total SPO CO2 **already overshoots** at the challenger: **−2.5 % → +5.8 %**.
- So a bigger *net* ocean limb is unaffordable **at any phase**, and the only profitable use of a
  new channel is as a counterweight that buys prior credit.

### ⚠ AND MY OWN SLICE HELD NO LEVER ON THE LAND — a limit of the TEST, not only the model

The P2 slice was `sst_seas_amp_{NH,SH}`, `seas_T_amp_{NH,SH}`, `seas_lag_p`, `q10` (`q10` only
because of the exact ridge). But:

- **`seas_npp_amp_SH` is a MEASURED CONSTANT and is not fittable at all** — and it is the dominant
  SH-local channel at SPO, **1.390 ppm** against `resp SH`'s 0.092.
- **`tau_ex` IS fittable, carries the 0.821 ppm NH import, and I FROZE IT.**

**So P3's failure may be an artefact of the slice rather than of the physics.** That is a
hypothesis for a NEW pre-registered test — **NOT a licence to re-run 27g's P2 with `tau_ex` added
and relabel the result.**

**This does not contradict 27e.** That exonerated `tau_ex` as a **PARTITION** lever (the SPO
δ¹³C-per-ppm ratio moves 4.2 % over a 5.7× range) *and said in the same breath that the leak is a
**SIZE** error*. **Size is exactly what is binding here.** The two findings do not conflict; the
second is the one that applies. Do not cite the exoneration to skip this test.

### THE FORK

- **(a) THE WIDER SLICE — RECOMMENDED.** Pre-register and run the seasonal block **plus `tau_ex`**,
  both arms, same matched design. Direct test of "the slice, not the physics, scored P3 FAILED".
  Cost: one script edit (`RF_BLOCK`) and ~2 optimiser runs. **`diag_so_entrainment_refit.R` is
  already parameterised by `RF_BLOCK`, so this is a constant, not a rewrite.**
- **(b) 4b, the second SH ocean column.** **This residual does NOT point at it.** A second ocean
  column would not shrink an SH land component that is 2× too big with 60 % imported. Not a case
  *against* 4b — a case for doing (a) first and deciding 4b on a residual that has had the land
  lever available.
- **(c) Neither — take the NH-representation question first** (§6, cheap, and it feeds directly
  into the binding quantity).

**Marcus's call.** My recommendation is **(a), then re-decide 4b.**

## 5. HOW TO RUN WHAT EXISTS

    Rscript calibration/diag_so_entrainment_power.R          # P1, ~3 min, 21 model runs
    Rscript calibration/diag_so_entrainment_refit.R          # P2, ~40 min, two optimiser arms
    CCX_ENT_AMP=10 Rscript calibration/diag_seas_signature_inversion.R
    CCX_PAR_RDS=<overrides.rds> Rscript calibration/diag_seas_channel_decomp.R

`CCX_PAR_RDS` names an `.rds` holding a named list of parameter overrides, applied on top of the
mode. **Use it rather than `CCX_ENT_AMP` alone whenever you are scoring a REFIT**: the mode's
drivers with one parameter changed is a model no fit ever landed on. The challenger's overrides
are reconstructible from `outputs/diagnostics/so_entrainment_refit.rds` (`par_ch` + `ent_hat`);
newer runs also save `u_ch` / `u_inc` / `u_mode` in full.

## 6. NON-OBVIOUS STATE — READ BEFORE TOUCHING ANYTHING

- **⚠ `ccx_make_logpost()` DOES NOT REPRODUCE THE CANONICAL MODE'S STORED `logpost`** at the mode's
  own `u_mode`: **−1547.9370 against a stored −1544.6148, offset −3.3223.** **Verified IDENTICAL at
  `fbf4b4c`** (by `git checkout fbf4b4c -- R src` in the working tree), so it is **PRE-EXISTING and
  not caused by this work**. Entirely in the LIKELIHOOD — prior + Jacobian reproduce to the last
  decimal. **Its signature is an INTERHEMISPHERIC REDISTRIBUTION**: `d14c_NH` −2.78 / `d14c_SH`
  +2.44, `d13c_level_MLO` −2.65 / `d13c_level_SPO` +1.97, `co2_level_MLO` −2.58.
  **RULED OUT:** `FORC_USE_LUC_NH_SHARE_TS` and `FORC_USE_EMIS_SEASONALITY` (all four combinations
  run; shipped TRUE/TRUE is both the BEST and the one that is off), `substeps` (4 both ways), the
  refit's `h_ml` [85, 120] bound (`h_ml` = 85.729 is inside both, and the prior reproduces anyway).
  **NOT diagnosed further. Flagged, not resolved.** A MATCHED comparison is unaffected; **never
  quote an absolute logpost from a live harness against the mode file.**
  [[ccx_mode_logpost_offset]]
- **`ccx_hold_climate()` CANNOT hold the entrainment channel**, and this is now audited and gated.
  It freezes forcing COLUMNS; the channel is generated from a PARAMETER and `t`, exactly as the
  seasonal SST cycle is (the 27c gap). **The control is `seas_drivers`, never `ccx_hold_climate()`.**
  `ccx_hold_climate()` IS complete over the four climate columns, and `test-so-entrainment.R`
  carries an **inventory gate** that fails if a new forcing column appears without that decision
  being made. **27g §6's audit is DISCHARGED.**
- **`ent_seas_amp_SH` is absent from every stored mode file** and always will be while it stays out
  of `CCX_PARAM_TABLE`. Anything reading a mode gets 0 unless it is told otherwise.
- **NEVER EDIT A SCRIPT WHILE `Rscript` IS READING IT.** R parses INCREMENTALLY, so a mid-run edit
  shifts byte offsets under the live process and it resumes mid-token; the error names a line that
  is fine on disk. **Run long jobs from a frozen copy** (`cp script.R /tmp/frozen.R`). This cost a
  40-minute run today. Also **parse-check every touched file before launching**
  (`Rscript -e 'invisible(parse("f.R"))'`) — a top-level `x <- if (a) "A" else if (b) "B"` is a
  real R syntax error that incremental parsing hides behind any earlier `stop()`.
  [[never_edit_a_running_script]]
- **FIVE BUGS FOUND AND FIXED EN ROUTE, ALL IN DIAGNOSTICS, NONE IN THE MODEL.** Two were in the
  OLDER scripts and only bite once the SH ocean has two limbs: **`air-sea SH off` was
  `sst_seas_amp_SH = 0` alone** in BOTH `diag_seas_signature_inversion.R` and
  `diag_seas_channel_decomp.R`, leaving the entrainment limb running — and in the inversion **that
  case is where the ocean signature `s_O` is measured**, so it was substantive. Both now switch off
  both limbs, identically to before at amplitude 0. If you add a THIRD ocean limb, these cases are
  the first thing to update.
- **Four Julia processes were at 100 % CPU for 2h25 today** on this Mac (load 6.4/10), not from
  this work. Everything here was pinned to one BLAS thread. **Check `uptime` and whose job is
  running before launching.** [[eta_in_days_is_not_a_slow_run]]

## 7. STILL OPEN BEHIND THIS

- **`R/likelihood.R:1028` maps `co2_NH` → MLO with only a LEVEL offset and NO seasonal
  representation term** — the model asserts MLO's cycle IS the NH hemispheric mean. **Still
  unchecked, still cheap, and it now bears DIRECTLY on the binding quantity**: if a hemispheric
  mean is larger, the NH leak into SPO (0.821 ppm) gets worse. NOAA's network measures it.
  **This is the strongest cheap item on the list.**
- The δ¹³C Suess overshoot re-check; whether `gcb_land_sink` should be decisive (−7.94, +2.31 σ,
  `LIK_LAND_SINK_INFLATE` = 3.0, a known GCB closure error); **`kz` railing** (6332 against a
  bracket top of 6528 — and 4b would land directly on it); the pump's `alpha13_signed` (b) case;
  `alpha_as_*` (hardcoded, uncited, **temperature-independent under a seasonal SST cycle** — and
  4a is now in that neighbourhood); the Hessian condition number; **the sampler — still the
  project's oldest open item, and there is STILL NO POSTERIOR.**
