# THE GATE SET, AUDITED — GATE 4 / 8 / 10 RETIRED, GATE V ADDED, GATE 12 DEMOTED
**2026-09-04 · CarbonCycleEmulator · Marcus's ruling, implemented**

**The rule applied:** *every test must compare an observed variable — including
measures of interannual variability and other second-order observations — or a physical law,
against the model.* Everything below follows from applying it to the whole set.

---

## 1. ⛔ GATE 4 RETIRED (airborne fraction)

Its quantity is a GCB observation, so it passes the rule as literally worded. It fails on
what the rule is for:

* **Its numerator is a scored stream and its denominator is a model input.** AF = model
  atmospheric growth ÷ model emissions; emissions are prescribed, growth is what
  `co2_level_MLO/SPO` scores. Measured, gate 4's one signal — the 2020s — reappears in
  `co2_level_MLO` at **mean z −0.96, max |z| 1.63**, the largest decadal excursion in that
  stream's record. Same sign, same size, already in the objective.
* **70 % of its target's variance was sampling noise** (spread 0.0483 vs a per-decade floor
  of 0.0404, analytic and MC-validated).
* **`sd()` over seven decades cannot tell a drift from a wiggle**, so it ranked the
  *uncalibrated defaults* above the adopted mode; detrended the two are identical.

The AF is still **computed and printed** (level 0.4246 vs GCB 0.4313). `dg_gate4_verdict()`
now **errors with the reason**, the way a retired mode name does.

## 2. ⭐ GATE V ADDED — interannual CO₂ growth variability

The second-order observation gate 4 was reaching for, where it *is* resolved: 66 annual
values, not 7 decadal ones.

* **Estimator, identical both sides:** `grow_y = AF(y)·emis_y + eps_y` with AF(y) a natural
  spline (`DG_V_DF` = 3); the gate is `sd(eps)`, GtC/yr.
* **Bound derived from the observation itself:** the sampling error of an sd,
  `sd/sqrt(2(n−1))` = **0.080 GtC/yr**, MC-validated to three decimals. Two-sided,
  `|z| ≤ DG_V_NSD` = 2 — too much variability is as wrong as too little.
* **Nothing in the objective asks for it:** `co2_level_*` scores levels at a deliberately
  soft 1.0 ppm.

| | sd (GtC/yr) | ratio | z |
|---|---|---|---|
| GCB 2025 | 0.911 ± 0.080 | 1.00 | — |
| defaults | 0.638 | 0.70 | **−3.42** |
| **ent26** | 0.698 | 0.77 | **−2.67 → FAIL** |

Stable across the smoothing choice (obs 0.907–0.933, arms 0.627–0.698 over df 2–5).
Mutation-tested in both directions in `test-gate-bounds.R`, including the white-noise
premise that makes `sqrt(2(n−1))` the right denominator.

### Where the model's variability comes from (`diag_gateV_variability_drivers.R`)

Knockouts at the canonical mode — temperature smoothed with an 11-yr centered mean (trend
kept), `gamma_diff = 0`, all four `gamma_enso_*` = 0:

| case | sd | z | variance lost |
|---|---|---|---|
| all drivers on | 0.698 | −2.67 | — |
| no TEMPERATURE (`gmst` + `sst_anom_*`) | 0.505 | −5.09 | **−47.8 %** |
| no VOLCANIC (AOD → diffuse light) | 0.677 | −2.93 | −6.1 % |
| no ENSO (land + ocean) | 0.405 | −6.33 | **−66.3 %** |
| none of them | 0.190 | −9.02 | −92.6 % |

⚠ Singles sum to 0.586 against the joint 0.451 — the difference is interaction, reported
rather than hidden. The driver-free residual is 7 % of the variance.
⇒ **The three named drivers would have to supply 1.76× their present combined variance for
gate V to close.** ENSO is the largest single share, and the ENSO *ocean* response is
already on record as anti-correlated with the observed (r −0.51 vs +0.535) — Fix B is the
lever this gate points at.

## 3. ☀ WOULD AN OBSERVED SOLAR CYCLE HELP? — **No**, on three independent grounds

1. **It is already in the model.** CCX is driven with the *observed* GMST record, which
   contains whatever the solar cycle did to temperature — the same argument `R/forcing.R`
   already makes for volcanic cooling. A solar→temperature term would **double-count**. The
   only non-redundant addition would be a *direct irradiance → photosynthesis* path, i.e. a
   new mechanism (the solar analog of `gamma_diff`), not a new forcing column.
2. **The observations show no significant cycle.** Best-fitting period in 9–13 yr is
   **9.4 yr** (not 11), amplitude 0.477 GtC/yr = 13.7 % of the anomaly's variance — but a
   white-noise null searched over the *same band* has median 0.316 and 95 % 0.502, so the
   observed sits at the **93rd percentile**: not significant once the band search is counted.
3. **It is too small either way.** Closing gate V needs 0.343 (GtC/yr)²; a harmonic of that
   amplitude carries 0.114, or **33 %** of it.

⚠ **Power, stated:** the 95 % null cut is 0.502 GtC/yr, so this test detects any harmonic in
the band above ~15 % of the observed variance and **cannot rule out smaller ones**. On 66
years (~6 cycles) that is the honest statement — a solar cycle big enough to matter for
gate V would have shown.

## 4. ⛔ GATES 8 AND 10 RETIRED

* **Gate 8 (δ¹³C Suess endpoints)** differenced two station-years that `d13c_level_MLO/SPO`
  already score every year of, and re-judged the result at a typed 0.10 ‰ with no derivation.
* **Gate 10 (natural deep-ocean Δ¹⁴C)** took its target *and* its sigma from
  `ccx_deep_d14c_target()` — the likelihood's own accessor. Its header said so in as many
  words. A gate tied to the stream it checks cannot fail independently of the optimizer.
  The observation is not lost: `d14c_deep_ocean` scores it and `test-likelihood.R` bounds
  `kz` through it.

⚠ What is lost is stated in the retirement block: both were the only places certain
diagnostic quantities were *printed* beside their targets. If they are wanted back, bring
back the print, not the verdict.

🐛 **And the summary block of `diag_design_gates_unscored.R` could not run at all** — `cn`
was the typed literal `"from90"`, quarantined on 09-04, so every lookup indexed a NULL.
Now `CCX_MODE_CANONICAL`. Gate 6 reads **PASS** at ent26 (growth +19.4 % vs observed +15.6 %).

## 5. ⚠ GATE 12 / 12a / 12b → A POST-MODEL COMPARISON, NOT A TEST

Joos et al. 2013 is another *model*, and **no observation constrains a CO₂ perturbation
lifetime** — the bomb-¹⁴C record measures tracer transport, and the two are ~2.8× apart at
100 yr. The long tail should be **emergent**; a tail that appears because the model was held
to Joos's number is not evidence. So: still computed, still printed against Joos's ranges
with *inside / BELOW / ABOVE*, **nothing scored, gated, or chased in a refit**.

⛔ **CONSEQUENCE: P5 IS NO LONGER "FALSIFIED".** IRF(100) = 0.276 against Joos's band is now
a **reported difference** — a statement about where the model's emergent lifetime sits.
Every record saying "P5 FALSIFIED" predates this ruling.

The strict assertion in `test-pulse.R` — |model − Joos|/Joos < 0.40 at 20/50/100 yr, a typed
band against another model, evaluated at `ccx_default_params()` rather than the fitted mode —
is **gone**. What that test still asserts is only what is ours: the protocol's own
precondition, and that the IRF stays in (0, 1) and decays. The Joos numbers are reported.
`test-joos-irf.R` keeps every assertion, because none of them is about *our* model: the
single-exponential locus is parameter-free algebra and the rest are properties of the
reference and the estimator.

---

## 6. What the set now looks like

| gate | quantity | source | independent of the objective? |
|---|---|---|---|
| **V** | interannual CO₂ growth variability | GCB, second-order | **yes — nothing scores it** |
| **Q** | air-sea δ¹³C disequilibrium | Quay 2003 | **yes** |
| **G** | ocean surface DIC | GLODAP | **yes** |
| 5 | bomb ¹⁴C peak / lag / e-fold | Hua 2022 | different functional of a scored stream |
| 6 | MLO seasonal amplitude *growth* | Scripps | different functional |
| 7 | land/ocean sinks | GCB (obs + model) | no — documented restatement |
| S | SPO ocean limb phase | obs **inverted through the model** | **self-declared circular, provisional** |
| 11 | uniformity screen | — | a screen, not a claim |
| 12/12a/12b | pulse IRF | **another model** | **comparison, not a gate** |
| ~~4~~ ~~8~~ ~~10~~ | — | — | **RETIRED 2026-09-04** |

## 7. ⇒ Still open, in order

1. **Gate S is circular** — its target is an SPO observation inverted through the model's own
   signatures, and all six constants are `status = "provisional"`. The independent check its
   own source names is the **MPI SOM-FFN surface-ocean pCO₂ climatology, already downloaded**
   (`data-raw/downloads/MPI-ULB-SOM_FFN_clim.nc`) and used only to bracket `sst_seas_amp`.
   The same product is the Fix B pre-test still owed.
2. **Observations on disk with no test:** `obs_d14c_station_validation` (160 station Δ¹⁴C
   points, built explicitly as a held-out validation set, used by nothing);
   `obs_oceanic_suess$eide_profile` (33-point ocean δ¹³C Suess depth profile); the MOD17
   **global** NPP level (52.7 PgC/yr — only the NH *share* is used).
3. **Not in the repo at all:** the ocean **anthropogenic carbon inventory** (GLODAP/Sabine
   Cant). The ocean bomb-¹⁴C inventory is scored, but ¹⁴C measures ventilation, not buffer
   capacity — and gate 12a's standing verdict is an ocean-*capacity* defect.
4. **Atmospheric O₂/APO** — the independent observational split of land vs ocean sink. Needs
   an O₂:C stoichiometry layer: a modeling job, not a test.

## Files

* `calibration/lib_design_gates.R` — gate 4 retired (`DG_G4_RETIRED`, erroring verdict);
  gate V kernel, obs, verdict; `DG_LEDGER` rows rewritten.
* `calibration/diag_gateV_variability_drivers.R` + `calibration/output/gateV_variability_drivers/`
* `calibration/diag_design_gates_unscored.R` — gates 8/10 retired; `cn` repaired.
* `calibration/diag_design_gates_at_mode.R`, `diag_gates_in_the_new_basin.R`,
  `diag_gates_at_refit_20260903.R` — gate 4 printed, gate V scored.
* `R/joos_irf.R`, `calibration/diag_joos_irf.R`, `tests/testthat/test-joos-irf.R`,
  `tests/testthat/test-pulse.R` — gate 12 demoted to a comparison.
* `tests/testthat/test-gate-bounds.R` — gate 4's mutation test replaced by gate V's.
