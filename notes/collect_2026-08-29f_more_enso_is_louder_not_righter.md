# COLLECT 2026-08-29f — **MORE ENSO MAKES THE MODEL LOUDER, NOT RIGHTER**
# The fit WAS asked and refuses at −62.6 (MODERATE, not prohibitive) — and scaling ENSO to match
# the observed variance leaves the correlation **unchanged at r ≈ 0.56**.

**Prereg:** `notes/prereg_2026-08-29f_profile_gamma_enso.md`. **Driver:**
`calibration/diag_gamma_enso_profile.R`. **Output:** `outputs/diagnostics/gamma_enso_profile.{rds,log}`.

---

## 1. THE PROFILE

| γ | Δlogpost | sd | r | 1998 | 1992 (Pinatubo) |
|---|---|---|---|---|---|
| 0 (ENSO off) | −9.40 | 0.1725 | 0.442 | 0.188 | −0.183 |
| 0.40 | −2.64 | 0.2230 | 0.543 | 0.302 | −0.077 |
| **0.85119 (the mode)** | **0** | **0.3006** | **0.571** | 0.430 | +0.043 |
| 1.50 | −5.46 | 0.4271 | 0.572 | 0.615 | +0.215 |
| 2.00 | −17.11 | 0.5296 | 0.567 | 0.757 | +0.347 |
| 3.05 (closes the sd gap) | −62.63 | 0.7504 | 0.557 | 1.056 | +0.626 |
| 4.00 | −128.37 | 0.9531 | 0.550 | 1.327 | +0.877 |

Observed sd **0.8996**; the model's non-ENSO baseline is **0.1725**.

- **E2 PASS** — the frozen argmax is **exactly** the fitted 0.85119. **The fit was asked and answered.**
- **E3 → MODERATE, −62.63 frozen / −61.26 conditional (2 % buy-back).** ⚠ **I predicted PROHIBITIVE
  and was wrong.** The refusal is real but not overwhelming.
- **E6 — THE ONE THAT MATTERS.** r goes **0.571 → 0.557** while sd goes 0.301 → 0.750. **Turning ENSO
  up adds variance of the right SHAPE but no additional right DETAIL. It makes the model louder, not
  righter.** ⇒ **the missing variance is NOT ENSO amplitude.**
- **E4 FAIL, and the identity of the refuser is the interesting part:** the two `co2_level` rows carry
  only 38 %. **The single largest objector is `gcb_land_sink` at −21.72 (35 %)**, then
  `co2_seasonal_SPO` −14.71, then `co2_level_MLO`/`SPO` −11.92/−11.88.

## 2. ⚠ TWO OF MY GATES PRINTED VERDICTS THAT THE NUMBERS DO NOT SUPPORT

**(a) E1 "FAIL — the response SATURATES" is an ESTIMATOR ARTEFACT, not a model property.** I defined
`sd_ENSO = sqrt(sd² − sd_off²)`, which assumes the ENSO and non-ENSO components are ORTHOGONAL. They
are not — El Niño warms, and the GMST-driven response is correlated with it — so quadrature
subtraction is invalid and the ratio drifts 43.8 %. **On an estimator that is actually linear-valid,
the 1998 anomaly minus its γ = 0 value, the response is linear to 0.25 %:**

    γ         0.40    0.8512    1.50    2.00    3.05    4.00
    Δ1998/γ  0.2850   0.2843  0.2847  0.2845  0.2846  0.2848

**The flux is linear in γ exactly as `ccx_core.cpp:396` says. E1's verdict line is wrong.**

**(b) The driver's closing line, "TUNING JOB: the fit was simply never asked for it", contradicts its
own E2.** E2 shows the frozen argmax sits *exactly* at the fitted value — the fit **was** asked, and
refused. The correct reading is **"the fit refuses, at a MODERATE price"**, which is neither of the
two branches I pre-registered. Both misfires are the same failure I made on T1 this morning: a
verdict string asserting a mechanism the measurement does not establish.

## 3. WHY THE FIT SHRINKS ENSO — AND A NUMBER WORTH CONSIDERING

**This is interpretation, flagged as such, not a gate.** For a predictor of correlation `r`, the
squared-error-optimal scaling gives a fitted series with sd = `r × sd_obs`, **not** sd = `sd_obs` —
classic regression attenuation. Here that is `0.571 × 0.900` = **0.514**, against the model's 0.301
and the variance-matching 0.750. **Matching the observed variance and minimising squared error are
different objectives, and the fit is correctly doing the second.**

⇒ **γ ≈ 1.5 costs only −5.46 and takes sd 0.301 → 0.427**; γ = 2.0 costs −17.11 for sd 0.530. For a
teaching tool that has to LOOK right, the region γ ∈ [1.5, 2.0] is close to the attenuation-optimal
0.514 at a small price. **That is a calibration/pedagogy trade-off and Marcus's call, not a fit
result.** Nothing is adopted; γ stays 0.85119.

## 4. WHAT THIS SETTLES FOR THE PLAN

- **ENSO is not where the missing variability is.** r ≈ 0.57 at every amplitude means the ENSO
  channel explains ~33 % of the observed anomaly variance in TIMING and cannot explain more by
  getting louder.
- ⇒ **the remaining 2/3 must come from mechanisms that are ABSENT**, and the one we now have data
  for is **volcanic diffuse-light fertilisation** (08-29e: the thermal path supplies ≤ 7 % of
  Pinatubo, measured ~0 %).
- **`gcb_land_sink` being the largest ENSO objector is a NEW link to gate 7** (land sink +2.30 σ).
  Two independent arcs now touch that row. Untested.
