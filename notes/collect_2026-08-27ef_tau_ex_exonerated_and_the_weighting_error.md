# COLLECT — 2026-08-27e/f: `tau_ex` IS EXONERATED, AND THE SH OCEAN CHANNEL'S PHASE IS
# NOT WRONG — ITS *WEIGHTING* IS. I had the diagnosis half wrong.

Against `notes/prereg_2026-08-27e_tau_ex_leak_profile.md` and
`notes/prereg_2026-08-27f_so_pco2_phase.md`, both written before their scripts existed.
**Seven scored predictions; three FAILED and the failures are where the result is.**

Scripts: `calibration/diag_tau_ex_leak_profile.R` (new, ~25 s) and
`calibration/diag_so_pco2_phase.R` (new, ~2 s). New data:
`data-raw/downloads/MPI-ULB-SOM_FFN_clim.nc`, registered in `download_data.R`.

---

## 1. ⚠ A CORRECTION TO HANDOFF 27d §3(a), IN PLACE

Handoff 27d said the model's SH air-sea channel "arrives in the wrong season", flagging the
entrainment mechanism as my reading and the 4.16-vs-8.52 phase gap as the measurement.

**The measurement was right. My reading of it was half wrong.**

| band | pCO2 amp (µatm) | peak mo | SST peak mo | gap |
|---|---|---|---|---|
| **SH all (0–90 S)** | **4.56** | **1.20** | 2.05 | **0.85** |
| SH subtrop 0–30 S | 16.41 | 1.43 | 2.21 | 0.78 |
| SH 30–40 S | 25.08 | 1.28 | 1.92 | 0.64 |
| **SO 40–90 S** | **19.45** | **7.50** | 1.94 | **5.56** |
| SO 60–90 S | 41.91 | 7.79 | 1.85 | 5.94 |
| NH all (0–90 N) | 2.93 | 8.14 | 7.84 | 0.30 |

**The SH-MEAN ocean pCO2 cycle IS in phase with SST — 0.85 months.** A solubility-only channel
is the *right* description of the SH hemispheric mean, and the model's channel at month 4.16
matches the observed SH-mean ΔpCO2-implied phase of **4.54 — 0.38 months apart.**

**P1 FAILED and P4 FAILED, and that is the finding.** I conflated "the SH ocean" with "the
Southern Ocean". They are nearly opposite.

## 2. WHAT IS ACTUALLY WRONG: the SH mean is a 76 % CANCELLATION of two opposed regimes

| band | area wt | amp | peak mo | weighted |
|---|---|---|---|---|
| 0–30 S | 0.475 | 16.41 | 1.43 | 7.79 |
| 30–40 S | 0.156 | 25.08 | 1.28 | 3.91 |
| 40–90 S | 0.369 | 19.45 | 7.50 | 7.18 |

subtropical limb (0–40 S) **11.70 at month 1.38** against Southern Ocean **7.18 at month 7.50** —
**5.88 months apart, i.e. antiphase.** Vector sum **4.56**; scalar sum 18.87. **76 % CANCELS.**

**⇒ THE MODEL IS MATCHING A RESIDUAL.** Its single SH ocean box carries the area-mean SST cycle,
which is the small leftover of two large opposing regimes — and reproducing the leftover is not
reproducing either regime. **What SPO sees is not the area mean.** The inversion put the observed
atmospheric ocean component at **8.52 [7.82, 9.20]**; the Southern Ocean's ΔpCO2 peaks at **7.41**,
**1.11 months earlier** — the lag of an atmospheric anomaly behind its driving flux, shorter than
a quarter cycle because the SH box loses signal to exchange and sinks. The subtropical limb
(ΔpCO2 at 1.52) cannot produce 8.52 at any lag.

**⇒ §7c-3'S CANDIDATE IS A WEIGHTING/AGGREGATION ERROR, AND IT LANDS ON MARCUS'S OWN NAMED
CANDIDATE — LATITUDE BANDS WITHIN A HEMISPHERE.** One SH ocean box cannot carry two nearly
antiphase regimes at once, and no value of `sst_seas_amp_SH` can fix that: the parameter scales a
phase it cannot rotate. **This is why the fit suppressed it to 21 % of observed — the channel it
scales has the subtropical phase, which is ~antiphase to what SPO needs, so any amplitude hurts.**
[[audit_every_target]] in miniature: the band that was never separately audited is the one that
decided the conclusion.

**And it explains the NH working.** NH-mean pCO2 is 0.30 months from NH SST — the NH really is
solubility-dominated at the hemispheric mean, which is why the NH ocean component's phase error is
only +1.16 months against the SH's −5.17.

**P2 CONFIRMED, and it converts the mechanism.** South of 40 S, pCO2 peaks month **7.50**
(predicted 6–10) and is **5.56 months** from SST (predicted ≥ 4.0). Wintertime entrainment raising
pCO2 in the season solubility alone would be lowering it is no longer my reading — it is measured
in a published product. **P3 method control PASSED** (subtropical gap 0.78 ≤ 2.5).

## 3. `tau_ex` IS EXONERATED AS A PARTITION LEVER (prereg 27e)

11 log-spaced nodes over 0.7–4.0 yr, two runs per node so the NH leak is differenced vectorially
at each.

- **P1 CONFIRMED on its falsifier**: leak **0.422 ppm** at τ = 2.371 against a predicted
  0.42–0.48. **MISSED on its other half** — the SH-sink damping is not roughly constant, it falls
  monotonically **11.0 % → 5.9 %** across the grid.
- **P2 CONFIRMED, and it is the result.** The SPO δ¹³C-per-ppm ratio moves **4.2 %** across a
  **5.7× range** of `tau_ex` (1.83× → 1.99×, fitted 1.91×) against a ±10 % band. **Transport
  relabels WHERE the cycle was made, not WHAT made it** — both parts carry the land signature.
  The leak is a SIZE error, not the partition error.
- **P3's substantive half CONFIRMED** (the seasonal and gradient rows disagree in direction —
  `co2_seasonal_SPO` slope +131.9, `co2_gradient` −3.1, `d13c_seasonal_MLO` −59.0)
  **but MY PREDICTED SIGN WAS WRONG.** I said the CO2 row wants a SHORTER `tau_ex`; it wants a
  LONGER one. I reasoned from the amplitude alone and the row is phase-driven — **the same scalar
  reading of a vector decomposition that `diag_seas_channel_decomp.R`'s own header records as
  having been wrong in both directions in August.**
- **And my first readout of P3 was an artefact of my own grid.** Log spacing put 1.181 eight times
  closer to the fitted 1.159 than 0.992 was, so all four rows read "wants LONGER" off the SPACING.
  Replaced with a symmetric central difference in ln τ. [[argmax_flat_optima]].
- **Free convergence check:** slope ÷ curvature puts the optimum at `tau_ex` **1.156** against the
  stored **1.159** — **0.3 %**. The canonical mode is converged in this coordinate.

---

## Carried caveats

- **pCO2 IS NOT FLUX.** `F = k·K0·ΔpCO2`. Neither the wind seasonality in `k` nor the temperature
  seasonality in `K0` is in any number here; both modulate AMPLITUDE strongly. **No number above
  may be quoted as a flux amplitude**, and the flux weighting is more Southern-Ocean-tilted than
  the area weighting, which if anything strengthens §2.
- **A climatology is not an error bar.** This product carries no spread I am using, so these
  phases have no observational uncertainty attached — unlike the inversion's, which are
  bootstrapped. **The spread ACROSS BANDS is the honest scale** and it is reported.
- **The +3-month quarter-cycle conversion in P4 is an idealisation** and was labelled the weakest
  of the four before it ran. Real loss makes the true lag shorter, which is exactly the 1.13
  months §2 measures against the Southern Ocean.
- The `tau_ex` profile is FROZEN in the other 20 parameters and therefore overstates every cost;
  it is read for sign, shape and the ratio between rows.
