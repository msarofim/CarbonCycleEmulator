# PRE-REGISTRATION — does a correctly-phased SOUTHERN-OCEAN ENTRAINMENT CHANNEL
# fix the SPO seasonal partition, at constant ocean state?

**Written 2026-08-27, BEFORE any line of the channel was written.** Scope authorized by Marcus
2026-08-27: **version 4a of handoff `…27g` §4** — a second seasonal air-sea channel, **no new
boxes and no new state** — with 4b (a genuine second SH ocean column) held conditional on what
4a's residual looks like. Companion decision the same day: the seasonal amplitude estimator is
**`|mean vector|`** (`CCX_SEAS_AMP_ESTIMATOR`), so the standing SPO partition target is **1.93×**.

---

## The claim under test, stated so it can fail

The model has ONE seasonal air-sea driver in each hemisphere: `sst_seas_amp_*`, which modulates
**SST and nothing else**. Ocean pCO2 then follows SST through solubility, so every air-sea channel
the model can build peaks in its hemisphere's late summer. The observed SH ocean is not one regime
but two, **5.88 months apart** (`diag_so_pco2_phase.R`, 2026-08-27f, re-run today):

| limb | pCO2 amp µatm | peak mo | vs that band's SST |
|---|---|---|---|
| subtropical 0–40 S | 11.70 | 1.38 | 0.78 mo — solubility |
| Southern Ocean 40–90 S | 7.18 | **7.50** | **5.56 mo** |
| SH mean (vector) | 4.56 | 1.20 | 0.85 mo — **76 % cancels** |
| NH mean (control) | 2.93 | 8.14 | **0.30 mo** — genuinely solubility-dominated |

> **HYPOTHESIS: what the model is missing at SPO is a SECOND SH air-sea channel, peaking in
> austral WINTER, carrying the OCEAN's isotopic signature — the surface-pCO2 signature of
> wintertime mixed-layer deepening entraining DIC-rich water.**

Represented at constant state as a **zero-mean seasonal DIC anomaly on the SH mixed layer**,
applied to the pCO2 calculation only. It moves no carbon on the annual mean, adds no state
variable, and reaches the atmosphere through the evasion limb that already exists — so it arrives
with `alpha_as_up`, i.e. **ocean-signatured**, which is the entire point.

**Its PHASE IS A MEASURED CONSTANT, NOT A FITTED ONE** — peak month **7.50**, ocean-area-weighted
40–90 S from the Landschützer/Laruelle climatology, exactly as `CCX_SST_SEAS_LAG` = 1.32 was
measured from ERSSTv5 rather than fitted. One free parameter is added: its amplitude.

## Where the model starts — MEASURED TODAY, not recalled

`diag_seas_channel_decomp.R` at the canonical mode, and `ccx_mode_file()`:

| quantity | value |
|---|---|
| SPO d13C-per-ppm residual (model/obs) | **1.93×**  (MLO control 0.97×) |
| model SPO **ocean component** (inversion) | **0.236 ppm [0.195, 0.280], month 3.35 [3.21, 3.50]**, 20.6 % of the cycle |
| observed SPO ocean component (inversion) | **0.522 ppm [0.306, 0.725], month 8.52 [7.82, 9.20]**, 44.7 % |
| ⇒ obs/model | **0.45× in size, 5.17 months in phase** |
| model SH air-sea CHANNEL at SPO (decomp) | 0.248 ppm pk-pk, peak month 4.17 |
| model SPO **land** vs obs (inversion) | 1.373 vs 0.683 = **2.01×** |
| MLO control (inversion) | obs land share **113.3 %** — P7 passes, the inversion is readable |
| `sst_seas_amp_SH` at the mode | **0.360** vs observed **1.746** = **20.6 %**, prior z **−6.32** |
| `sst_seas_amp_NH` at the mode | 0.937 vs 2.237 = 41.9 %, prior z −3.48 |
| `seas_T_amp_SH` at the mode | 1.04, prior z −4.64 |
| scored rows | `d13c_seasonal_SPO` +229.86, `co2_seasonal_SPO` +57.36, logpost −1544.615 |

---

## P0 — THE METHOD CONTROL, SCORED FIRST. If it fails, NOTHING BELOW IS READ.

1. **At zero amplitude the model must be BIT-IDENTICAL to the shipped one**, in both cores, on a
   full historical run — not "close". The channel is a strict extension or it is a refactor with
   an undisclosed side effect.
2. **R and C++ must agree with the channel ON**, at `test-parity.R`'s own tolerance. The two cores
   are gated against each other and a channel present in one only is not a channel.
3. **`seas_drivers = 0` must kill it**, like every other seasonal driver, so `ccx_spinup()`'s
   zeroing and the aseasonal control still hold. ⚠ **`ccx_hold_climate()` will NOT hold it** — it
   freezes forcing COLUMNS, and this cycle is generated from a PARAMETER and `t`, exactly as the
   seasonal SST cycle is (27c §2). That is a documented structural limit, audited below, and the
   control to use for this channel is `seas_drivers`, never `ccx_hold_climate()`.

## P1 — THE POWER MEASUREMENT, SCORED SECOND, BEFORE ANY VERDICT

The CO2 seasonal rows are already matched and **have no power to reject a partition error**
([[no_power_null]], [[seas_right_observable_wrong_drivers]]). This test must therefore be shown to
be *capable* of moving the thing it is being asked about, before its result means anything.

**PREDICT: within its admissible amplitude range the new channel can deliver ≥ 0.70 ppm pk-pk of
ocean-signatured seasonal CO2 at SPO.**

**The threshold is an OBSERVATION, not a tolerance chosen to pass.** The model's SPO ocean
component is 0.248 ppm at month 4.17; the observed one is 0.522 ppm at month 8.52 — **4.35 months
apart, i.e. within 1.7 months of antiphase**. Closing a near-antiphase gap requires the vector
difference, ≈ 0.248 + 0.522 = **0.77 ppm**, and 0.70 is that with the phase imperfection allowed
for. **FALSIFIER: it cannot reach 0.70 ppm at any admissible amplitude ⇒ the instrument is too
weak to answer the question and no null from it is reportable.**

A quantitative pre-check that the required amplitude is physical, done in advance:
the Southern Ocean's own solubility cycle (SST amp 3.0 K × ~4.23 %/K × ~370 µatm ≈ 47 µatm,
peaking month 1.94) must be *overcome* to leave the observed 19.45 µatm at month 7.50, so the
entrainment term is ≈ 66 µatm ⇒ ΔDIC ≈ (66/370)·2150/13 ≈ **30 µmol/kg** in the band, and
**≈ 11 µmol/kg** as a mean over the SH box after the 0.369 ocean-area weight. **If the fitted
amplitude lands far outside ~5–30 µmol/kg, the channel is being used as a fudge factor and should
be reported as one.**

## P2 — THE HANDOFF'S OWN PREDICTION: the objection was to the PHASE, not the AMPLITUDE

With the channel on and the seasonal parameters re-optimized, **`sst_seas_amp_SH` should RISE from
0.360 toward its observed 1.746, without the seasonal rows objecting.**

**PREDICT: `sst_seas_amp_SH` ≥ 0.60 and its prior z better than −5.0** (from −6.32), with
`co2_seasonal_SPO` + `d13c_seasonal_SPO` **not worse than their present sum, 287.2**.

**FALSIFIER: `sst_seas_amp_SH` does not rise (< 0.42, i.e. under a 15 % move), or it rises only by
paying the seasonal rows.** *That outcome is a real finding and is to be reported as one*: it
would mean the weighting account — that the SH mean is a 76 % cancellation the model matches as a
residual — is wrong.

## P3 — the SPO ocean channel's PHASE moves toward the inversion

**PREDICT: the model's SPO ocean component moves from month 3.35 to ≥ 6.0** — at least halfway to
the inversion's 8.52 (the midpoint is 5.94) — read from `diag_seas_signature_inversion.R`, with
`diag_seas_channel_decomp.R`'s SH air-sea channel (4.17 today) as the cross-check.
**FALSIFIER: it stays within 1.0 month of 3.35** — the channel would then be adding amplitude in
the season the model already had, which is a reparametrization of `sst_seas_amp_SH`, not a fix.

## P4 — THE STANDING TARGET: the partition residual falls

**PREDICT: the SPO d13C-per-ppm residual falls from 1.93× to ≤ 1.70×**, on the adopted
`|mean vector|` estimator, **while the MLO control stays within 0.90–1.10×** (it is 0.97× now).
**FALSIFIER: ≥ 1.85×, or MLO leaves that band** — the second half matters as much as the first: a
change that fixes SPO by breaking MLO has moved the problem, which is the failure mode §6 of the
handoff names.

## P5 — the SECOND SCORECARD: the driver ratios must not be paid off

`sst_seas_amp_SH` 20.6 % of observed, `sst_seas_amp_NH` 41.9 %, `seas_T_amp_SH` at 29 % of its
bracket's low end, `seas_T_amp_NH` at 131 % of the high end. **PREDICT: none of the four moves
FURTHER from its observed value than it is today.** A refit that improves logL while pushing the
drivers further out has moved the problem, not solved it — and would be reported that way.

---

## What is NOT claimed

- **This is 4a, not a band split.** One SH ocean box, one mixed layer, one Revelle factor, one
  mean sink. It **cannot** answer the mean-state questions — `h_ml`, the railing `kz` (6332 against
  a bracket top of 6528), the pump, or the conveyor — and a good result here is **not** evidence
  that a second ocean column is unnecessary for those.
- **The phase is asserted from a CLIMATOLOGY, which carries no error bar.** The honest scale is
  the spread across bands (40–60 S peaks 7.10, 60–90 S peaks 7.79), not a confidence interval.
- **pCO2 is not flux.** Neither the wind seasonality in `k` nor the temperature seasonality in
  `K0` is in the 7.50. Both bear on AMPLITUDE, so P1's 30 µmol/kg pre-check is an order-of-
  magnitude statement, not a calibration.
- **No posterior, and no claim about one.** There is still no converged sampler; every number here
  is at the single canonical mode, and a 1-D re-optimization is not a refit of the model.
- **Frozen scans OVERSTATE cost.** `seas_T_amp`×`q10` is an exact ridge (product held to 0.2 % over
  a 2.5× `q10` range, [[ccx_seas_q10_ridge]]) and `beta_max`/`fert_k` absorb 85 % of a frozen cost.
  **Read shape and direction, not Δlogpost**, from anything scanned at frozen neighbors.
- **Not claimed: that entrainment is the only candidate mechanism.** Seasonal wind-driven
  gas-transfer and sea-ice cover both modulate the same limb in the same season. This tests whether
  a correctly-phased ocean channel closes the residual — **not which physical process supplies it.**
