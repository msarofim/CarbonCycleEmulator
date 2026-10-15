# Collect 2026-08-27l — **THE SH (shape, size) PAIR IS A DEGENERATE RIDGE, AND THE ARC'S
# RESIDUAL LIVES INSIDE IT**
# The GPP/PsnNet bracket is 1.4x. The ridge is 3.2x. We have been arguing about the smaller one.

**Trigger.** Handoff 27k owed two decisions. (ii) was "is the model ENTITLED to the GPP end of
`SEAS_NPP_AMP_SH`?" — flagged as Marcus's, and as gating the design of (A).

**Ruling (Marcus, 2026-08-27):** *re-derive the bracket off a NON-MODIS product.* Neither end is
trusted; MOD17 is a single point of failure for a constant now carrying the whole seasonal arc.

**This note is what was found while preparing that question, and it RE-SPECIFIES the task Marcus
set** — see sec.3. Nothing was run against the model; sec.1 is a documentation lookup and sec.2 is
an offline re-run of an existing script on data already on disk.

---

## 1. THE PROVENANCE ALREADY ORDERED THE BRACKET — GPP WAS NEVER AVAILABLE

Written **2026-08-20**, before this arc existed and before any fit wanted 0.352:

- `data-raw/build_npp_seasonal_shape.R:20-28` — `gpp` is "GROSS. Autotrophic respiration runs
  through the shoulder seasons, so GPP is **LESS rectified** than NPP and its phi_eff is biased
  EQUATORWARD, **i.e. toward the convenient answer**." `net_photosynthesis` is "PsnNet = GPP −
  leaf and fine-root maintenance respiration. Closer to NPP; still omits growth respiration and
  live-wood maintenance." **"The truth for NPP sits at or BEYOND the PsnNet end of the bracket."**
- `DATA.md:237-242` repeats it verbatim.
- `R/model.R:1115` confirms the driver is the NPP one:
  `seas <- seas_npp_amp_SH * npp * (ccx_insol(phi_eff) / nrm$n - 1)`, moved through the LEAF pool.
  It multiplies the model's own NPP, so PsnNet is its observable and GPP is the wrong quantity.

**⇒ The 1.4x is an ORDERED bracket with a DERIVED direction, not a symmetric product disagreement.**
NPP sits at or past 0.5027, AWAY from 0.352. Adopting the GPP end would have moved a measured
constant in the direction its own derivation calls "the convenient answer".

**⇒ 27j's LAND-only and JOINT arms are therefore INADMISSIBLE AS CANDIDATE CONFIGURATIONS.** They
bought the land correction with a value the provenance forbids. **What survives from 27j is the
INTERACTION (+64.99 vs a pre-registered +39.59) as evidence that the land and ocean corrections
COUPLE** — a statement about the model's structure, which does not depend on 0.352 being right.
The landed vectors are not a mode. [[one_fix_confirmed_residual_is_land]]

## 2. BUT THE BRACKET IS NOT THE UNCERTAINTY — MEASURED

`Rscript calibration/diag_seas_rectification.R` (offline, no model runs, ~4 min, frozen copy).
The script has profiled the SH pair since it was written; **the row had never been read for this
question.** Form C is `1 + A*(I(phi)/mean I - 1)` — exactly what `seas_npp_amp_*` already does —
with **A re-optimized at every phi**, which the script's own header calls "the only fair way".

**FORM C: residual (rms as a fraction of observed peak-to-peak) and the fitted amplitude**

| phi | −15.75 | −20 | −25 | **−30 (shipped)** | −40 | −50 |
|---|---|---|---|---|---|---|
| `SH_psnnet` residual | 12.9% | 12.5% | 12.2% | **12.0%** | **11.9%** | 12.2% |
| `SH_psnnet` fitted A | **0.97** | 0.77 | 0.61 | **0.50** | 0.36 | **0.30** |
| `SH_gpp` residual | 13.5% | 13.1% | 12.9% | **12.7%** | 13.2% | 17.5% |
| `SH_gpp` fitted A | 0.69 | 0.55 | 0.45 | **0.37** | 0.31 | 0.30 |

Against the NH, which is what a DETERMINED latitude looks like:

| phi | 38.35 | 45 | 50 | 55 | 65 | **75 (shipped)** | 85 |
|---|---|---|---|---|---|---|---|
| `NH_psnnet` residual | 12.7% | 12.0% | 11.4% | 10.8% | 9.3% | **7.5%** | 8.3% |

- **THE SH LATITUDE IS NOT DETERMINED.** 1.0 percentage-point spread over 34 degrees, shallow and
  ambiguous, versus the NH's **5.2-point swing with a clean interior optimum**. The script's own
  rubric: "A FLAT row means the latitude is NOT determined once amplitude is free, and the choice
  should be made on other grounds."
- **AND THE SHAPE BARELY EXPLAINS THE SH AT ALL.** Freeing the amplitude leaves **92 %** of the
  incumbent residual in `SH_psnnet` against **65 %** in `NH_psnnet`. There is a ~12 % residual FLOOR
  that no single-latitude insolation curve gets below — consistent with the stated physics that
  76 % of SH NPP is equatorward of 23.5 S and its cycle is **water-driven, not light-driven**.
- **⇒ ALONG THAT FLAT RIDGE THE SIZE MOVES 0.97 -> 0.30, A FACTOR OF 3.2**, at an observational
  cost of one percentage point.

## 3. ⇒ WHAT THIS DOES TO THE ARC, AND TO THE TASK

**THE ARC'S RESIDUAL IS INSIDE THE RIDGE.**

    GPP/PsnNet bracket           1.4x   <- what 27i, 27j and decision (ii) argued about
    SH land residual (27j)       1.33x  <- what the arc is trying to close
    (phi, A) ridge degeneracy    3.2x   <- what is actually unpinned

`0.5027` was never a pinned measurement. **It is one point on a flat ridge, selected by a phi_eff
of −30 that the data cannot distinguish from −15.75 or −40.** `R/constants.R:225` has always said
"the pair is a (shape, size) unit, not two independent numbers" — this measures the price of the
half that was never fitted.

**AND THE RIDGE CONTAINS BOTH ANSWERS AT EQUAL OBSERVATIONAL COST**, which is why the arc is stuck:

- The **measured** SH NPP-weighted mean latitude is **−15.12** (`R/model.R:209`,
  `diag_npp_eff_latitude.R`, MOD17A3HGF). Anchoring the shape on the measured centroid gives
  **A = 0.97, nearly 2x the shipped value** — i.e. SH land almost DOUBLE, the opposite of what the
  arc needs, at a residual of 12.9 % against 12.0 %.
- Going poleward to −40/−50 gives **A = 0.36/0.30**, past even the GPP end and in the direction the
  fit wants, at a residual of 11.9-12.2 %.

**⇒ A ONE-POINT SPREAD IN A SHAPE RESIDUAL IS BEING ASKED TO CHOOSE A FACTOR OF THREE IN A DRIVER
THAT SETS THE WHOLE SH SEASONAL PARTITION.** [[tolerance_scaled_to_spread]]

**⇒ RE-SPECIFICATION OF MARCUS'S TASK.** He asked for the BRACKET re-derived off a non-MODIS
product. Taken literally that swaps GPP/PsnNet for another productivity climatology and fits it
onto **the same insolation basis** — which lands on **the same flat ridge** and returns a new number
without pinning anything. **A replacement product is necessary and not sufficient.** To be worth
the download it must either (a) come with a shape that BREAKS the ridge, or (b) be paired with a
decision to stop parameterizing the SH shape by a latitude at all. See the options put to Marcus in
sec.5.

## 4. INDEPENDENCE IS A SPECTRUM — audit before downloading anything

"Non-MODIS" is not a binary and three obvious candidates fail it:

| candidate | independent of MOD17? | is it NPP? | verdict |
|---|---|---|---|
| **FLUXCOM RS / RS+METEO** | **NO** — MODIS reflectance is its predictor | GPP/NEE | fails independence |
| **GOSIF, CSIF** | **NO** — MODIS-derived SIF | GPP proxy | fails independence |
| **CAMS / CarbonTracker inversions** | yes | NEE | **CIRCULAR** — constrained by the very MLO/SPO CO2 the model is scored on |
| **TROPOMI SIF** (S5P, 2018-) | **YES** — different instrument, different physics (fluorescence, not LUE-from-reflectance) | GPP proxy | live |
| **GOME-2 SIF** (MetOp, 2007-) | **YES** | GPP proxy | live, longer record, coarser |
| **TRENDY / GCB DGVM ensemble, S3** | **YES** — process models, no satellite | **NPP DIRECTLY** | live; resolves the bracket rather than replacing it; access by request to Sitch, and it is MODELS not observation |
| **FLUXNET2015 / OneFlux towers** | **YES** — eddy covariance | GPP/NEE | most observational, **worst SH coverage** — the quantity wanted is a hemispheric aggregate |

⚠ **The inversion row is the trap**: it looks like the most direct measurement of the land seasonal
flux and it is the one product that cannot be used, because it is fitted to our own targets.

⚠ **TRENDY is the only candidate that IS NPP.** Every other option reproduces the "neither is NPP"
problem in a new instrument. That is an argument for it and against calling it observational.

## 5. OPEN — PUT TO MARCUS

1. **Which product** (sec.4), given that none is both observational, NPP, and SH-representative.
2. **Whether to keep the insolation-latitude basis in the SH at all**, given the 12 % floor and the
   3.2x degeneracy. The alternative is an EMPIRICAL SH shape taken from the product as data.
3. Whether the **measured centroid −15.12** should anchor the shape — it is the one externally
   determined latitude available, and it pushes SH land the WRONG way for the arc (A = 0.97).

## 6. STATE

- `R/likelihood.R:175`'s "66 % of `tau_ex`'s leverage is seasonal" **HAS NOW BEEN QUALIFIED**
  (commit `6e26248`) with 27h's measurement that it is the LOWER jaw only. Handoff 27k sec.5's
  live item is CLOSED. Comment only; suite **1157 pass / 0 fail**, unchanged.
- `outputs/diagnostics/` unchanged — `diag_seas_rectification.R` writes no RDS, it prints.
- Nothing else in `R/` or `src/` touched.
