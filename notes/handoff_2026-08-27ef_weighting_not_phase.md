# Handoff — CarbonCycleEmulator, 2026-08-27e/f: `tau_ex` IS OUT, AND THE SH OCEAN
# PROBLEM IS A **WEIGHTING** PROBLEM — my 27d diagnosis was half wrong

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`, clean.
**Nothing is running.** **Suite: 1122 pass / 0 fail** (no `R/` change today).

**Supersedes** `notes/handoff_2026-08-27d_partition_inverted_ocean_phase_is_wrong.md` for its
**§3(a)** (the mechanism reading) and **§5** (the next steps — both are now done). Its §1, §2, §4
and §6 stand: the inversion table, the 72 % NH-origin leak, the 1.93× estimator finding.

Pre-registrations `prereg_2026-08-27e_tau_ex_leak_profile.md`,
`prereg_2026-08-27f_so_pco2_phase.md` — both written before their scripts existed. Scored:
`collect_2026-08-27ef_tau_ex_exonerated_and_the_weighting_error.md`. CHANGELOG 2026-08-27e/f.
Commits `a9d850c`, `8df7c7c`, + this one.

---

## 0. STATE IN FIVE LINES

1. **Both of 27d §5's next steps are DONE.** §1, §2
2. **`tau_ex` is EXONERATED as a partition lever** — the ratio moves 4.2 % over a 5.7× range. §2
3. **⚠ 27d §3(a) IS HALF WRONG and is corrected here.** The SH-MEAN ocean pCO2 cycle IS in phase
   with SST, and the model matches it to 0.45 months. §1
4. **The real defect is WEIGHTING: the SH mean is a 76 % cancellation of two antiphase regimes,
   and the model matches the residual.** §1
5. **⇒ ONE live candidate remains: LATITUDE BANDS, on the SH OCEAN limb.** §3

---

## 1. ⚠ THE CORRECTION — phase right, weighting wrong

Against the Landschützer/Laruelle merged pCO2 climatology (NCEI 0209633, downloaded and
registered today, Marcus's choice) + ERSSTv5, area-weighted over the same bands:

| band | pCO2 amp µatm | peak mo | SST peak mo | gap |
|---|---|---|---|---|
| **SH all (0–90 S)** | **4.56** | **1.20** | 2.05 | **0.85** |
| SH subtrop 0–30 S | 16.41 | 1.43 | 2.21 | 0.78 |
| SH 30–40 S | 25.08 | 1.28 | 1.92 | 0.64 |
| **SO 40–90 S** | **19.45** | **7.50** | 1.94 | **5.56** |
| SO 60–90 S | 41.91 | 7.79 | 1.85 | 5.94 |
| NH all (0–90 N) | 2.93 | 8.14 | 7.84 | 0.30 |

**P1 FAILED. P4 FAILED. That is the result.** A solubility-only channel is the RIGHT description
of the SH hemispheric mean (0.85 months), and the model's channel at atmospheric month **4.16**
matches the observed SH-mean ΔpCO2-implied **4.54** — **0.38 months apart.** I had conflated *the
SH ocean* with *the Southern Ocean*. They are antiphase.

**THE DEFECT IS THE AGGREGATION.** Weighted by area:

| limb | amplitude | peak mo |
|---|---|---|
| subtropical (0–40 S) | 11.70 | 1.38 |
| Southern Ocean (40–90 S) | 7.18 | **7.50** |
| **vector sum** | **4.56** | 1.20 |
| scalar sum | 18.87 | — **76 % CANCELS** |

**The model matches a residual, which is matching neither regime.** And **what SPO sees is not
the area mean** — the Southern Ocean's ΔpCO2 peaks **7.41** against the inversion's atmospheric
**8.52 [7.82, 9.20]**, a **1.11-month** lag (shorter than a quarter cycle because the box loses
signal to exchange and sinks). The subtropical limb, at 1.52, cannot produce 8.52 at any lag.

**⇒ `sst_seas_amp_SH` CANNOT FIX THIS — the parameter scales a phase it cannot rotate.** 27d's
conclusion that its −6.32 σ flag is the model penalised for a correct refusal SURVIVES, on a
better-founded reason than the one I gave it.

**P2 CONFIRMED, and it converts the mechanism from my reading into a measurement**: south of
40 S, pCO2 peaks month **7.50** and sits **5.56 months** from SST — wintertime entrainment raising
pCO2 in the season solubility alone would lower it. **P3 method control PASSED** (subtropical gap
0.78 ≤ 2.5). **The NH is the second control and it passes**: NH-mean pCO2 is **0.30 months** from
NH-mean SST, so the NH genuinely is solubility-dominated at the hemispheric mean — which is why
the NH ocean component's phase error is +1.16 months against the SH's −5.17.

## 2. `tau_ex` — EXONERATED, and two process errors of mine along the way

11 log-spaced nodes over 0.7–4.0 yr, two runs per node so the leak is differenced vectorially.

- **P2 CONFIRMED and it is the result:** the SPO δ¹³C-per-ppm ratio moves **4.2 % across a 5.7×
  range** (1.83× → 1.99×, fitted 1.91×). **Transport relabels WHERE the cycle was made, not WHAT
  made it** — both parts carry the land signature. **The leak is a SIZE error, not the partition
  error.**
- **P1 CONFIRMED on its falsifier** (leak 0.422 ppm at τ = 2.371 vs a predicted 0.42–0.48)
  **MISSED on its other half**: the SH-sink damping is not constant, it falls monotonically
  **11.0 % → 5.9 %**.
- **P3's substantive half CONFIRMED** (the seasonal and gradient rows disagree in direction)
  **but MY SIGN WAS WRONG** — `co2_seasonal_SPO` wants a LONGER `tau_ex`, not shorter. I reasoned
  from amplitude alone on a row that is phase-driven: **the same scalar reading of a vector
  decomposition that `diag_seas_channel_decomp.R`'s own header already records as having been
  wrong in both directions in August.**
- **My first P3 readout was an artefact of my own grid.** Log spacing put 1.181 eight times closer
  to the fitted 1.159 than 0.992 was, so all four rows read "wants LONGER" off the SPACING.
  Replaced by a symmetric central difference in ln τ — **which is the form to reuse.**
- **Free convergence check:** slope ÷ curvature puts the optimum at **1.156** vs the stored
  **1.159** — 0.3 %. The canonical mode is converged in this coordinate.

## 3. ⇒ NEXT: latitude bands, on the SH OCEAN limb — and how to pose it

This is Marcus's own named candidate from handoff 27, arrived at from a different direction. **It
is a structural change and is his call to authorise**, not mine. What §1 gives it that it did not
have before is a target with a number and a phase: two SH ocean bands, a subtropical one that the
current SST channel already describes correctly, and a Southern-Ocean one peaking ~5.9 months
away from it.

**Before building anything:**
1. **The seasonal entrainment term does not exist in the model at all.** The SH ocean's only
   seasonal driver is `sst_seas_amp_SH`. A band split with no new mechanism gives two solubility
   channels in the same phase and buys nothing — **the band and the mechanism have to land
   together**, which is a bigger change than a reparametrisation.
2. **Note what banding has and has not been tested on.** `R/model.R:218` records that latitude
   banding was tested and REJECTED on the NH **land NPP shape** (`diag_npp_twobox.R`: every
   multi-box fit deletes its own low-latitude boxes). Different limb, different hemisphere — **no
   evidence either way for the ocean.** Do not cite it as precedent in either direction.
3. **Pre-register, and score it on the isotopes or the drivers.** The CO2 seasonal rows still have
   no power (27d §1), and a band split that reproduces the same residual would look like success
   on them.
4. **Measure the POWER first**, as 27d did — a band whose flux weighting nobody has computed may
   not move `d13c_seasonal_SPO` at all.

**Still unchecked and cheap:** **the NH box's own seasonal amplitude.** `R/likelihood.R:1028`
maps `co2_NH` → MLO directly, with only a LEVEL offset (`rep_dC`); there is **no seasonal
representation term at all**, so the model asserts MLO's cycle IS the NH hemispheric mean. If a
hemispheric mean is larger, the leak the model already over-supplies gets worse. NOAA's network
measures this; nobody has looked.

**Still open behind it, unchanged:** the d¹³C Suess overshoot re-check; whether `gcb_land_sink`
should be decisive (−7.94, +2.31 σ, `LIK_LAND_SINK_INFLATE` = 3.0, known GCB closure error);
`kz` railing (6332 vs 6528); the pump's `alpha13_signed` (b) case; `alpha_as_*`; the Hessian
condition number; **the sampler — still the oldest open item, and there is STILL NO POSTERIOR.**
**And still owed:** `ccx_hold_climate()`'s incomplete-control gap is unaudited beyond the one
test that found it. Nothing today used it.

**A decision still owed from 27d §4:** the SPO partition residual is **1.93×, not ~1.5×** — an
estimator difference, flagged not resolved.

---

## 4. NON-OBVIOUS STATE ADDED TODAY

- **New download, gitignored like every other**: `data-raw/downloads/MPI-ULB-SOM_FFN_clim.nc`
  (47.5 MB, sha256 `aad8a56a…`). Registered as block **[6c]** in `data-raw/download_data.R` **and
  appended to `MANIFEST.csv` by hand** — it was fetched with `curl`, not by a full
  `download_data.R` run, and the manifest note says so.
- **⚠ pCO2 IS NOT FLUX.** `F = k·K0·ΔpCO2`. Nothing in `diag_so_pco2_phase.R` contains the wind
  seasonality in `k` or the temperature seasonality in `K0`, both of which modulate AMPLITUDE
  strongly. **No number in it may be quoted as a flux amplitude.** The flux weighting is more
  Southern-Ocean-tilted than area weighting, which only strengthens §1.
- **A climatology carries no error bar.** Unlike the inversion's bootstrapped intervals, these
  phases have no observational uncertainty attached; **the spread ACROSS BANDS is the honest
  scale** and it is reported.
- **`diag_tau_ex_leak_profile.R` asserts its stream names against the run's own list** — the
  gradient rows are `co2_gradient` / `d13c_gradient`, not `*_grad`, and a wrong-but-existing name
  would have failed silently.
- **The memory sub-index was re-cut mid-session**: `INDEX_ccx_seas.md` now exists, split out of
  `INDEX_ccx.md` (12.6 KB / 7.4 KB, both inside budget). **The seasonal arc lives there**, and its
  LIVE STATE block carries today's correction.
