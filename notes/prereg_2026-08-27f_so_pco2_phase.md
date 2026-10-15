# PRE-REGISTRATION — is the observed SH surface-ocean pCO2 cycle IN PHASE WITH SST,
# as the model's only SH air-sea channel requires it to be?

**Written 2026-08-27, BEFORE `calibration/diag_so_pco2_phase.R` was written or run**, and before
the downloaded file was opened for anything but its variable list. Handoff 27d §5 item 1.

---

## The claim under test, stated so it can fail

The model's ONLY SH air-sea seasonal channel is `sst_seas_amp_SH`, which modulates **SST and
nothing else**. Ocean pCO2 then follows SST through solubility (~4.23 %/°C), so the model asserts:

> **SH surface-ocean pCO2 peaks WHEN SST PEAKS.**

That is a claim about the ocean, testable against an ocean product **with no flux, no
gas-transfer velocity, and no quarter-cycle conversion in the way.** It is a much cleaner test
than the one handoff 27d §5 named, and it is available because the product is a pCO2 climatology.

## The data

`data-raw/downloads/MPI-ULB-SOM_FFN_clim.nc` — Landschützer/Laruelle merged monthly pCO2
climatology, 1440×720, `muatm`, NOAA NCEI accession 0209633, registered in `download_data.R`
(Marcus's choice, 2026-08-27, on [[weight_recent_literature]]). SST from **ERSSTv5 already on
disk**, the same product `data-raw/build_seasonal_climatology.R` uses, so the SST side of this
comparison is the same SST the model's own observed-amplitude constants came from.

Both sides area-weighted over the SAME masks, first-harmonic phase by the SAME estimator
(magnitude of the mean vector — [[amp_definition_mismatch]]), reported per latitude band.

## P1 — THE CORE TEST: SH-mean ocean pCO2 is NOT in phase with SST

**PREDICT: the SH-mean (area-weighted, all SH ocean) pCO2 first-harmonic peak is ≥ 2.0 months
from the SH-mean SST peak.**
**FALSIFIER: within 1.0 month**, which would VINDICATE the solubility-only channel and mean the
inversion's 8.52 has some other explanation. That outcome would put handoff 27d §3(a) in doubt
and is the one worth being wrong about.

## P2 — the Southern Ocean is what drives it, and it peaks in austral WINTER

**PREDICT: south of 40 °S, pCO2 peaks in months 6–10 and is ≥ 4.0 months from that band's SST
peak.** Reading: wintertime deepening entrains DIC-rich water and raises pCO2 in the season when
solubility alone would be lowering it. **This is the mechanism handoff 27d flagged as MY READING
rather than a citation — P2 is what converts it or kills it.**

## P3 — THE METHOD CONTROL, scored FIRST

**PREDICT: in the SH subtropics (0–30 °S), pCO2 peaks within 2.5 months of SST.** Solubility
should dominate there, so the method must return "in phase" where in-phase is the right answer.
**If P3 fails the method is broken and P1/P2 are not read** — the same contract as
`diag_seas_signature_inversion.R`'s MLO control.

## P4 — the quantitative link back to the inversion

Flux ∝ ΔpCO2, and an atmospheric concentration anomaly lags its driving flux by a quarter cycle,
so the SH-mean ΔpCO2 phase **+3 months** is the implied peak of the ocean-signatured atmospheric
component. **PREDICT: that lands ≥ 3.0 months later than the model's SH air-sea channel at month
4.16.** **FALSIFIER: within 2.0 months of 4.16.**

⚠ **P4 IS THE WEAKEST OF THE FOUR AND IS LABELED SO IN ADVANCE.** The +3 months assumes a pure
first harmonic and NO loss from the SH box; real loss (interhemispheric exchange, sinks) makes the
true lag SHORTER than 3 months, so P4's conversion is biased toward LATER and its margin should be
read as generous. P1–P3 carry no such conversion and are where the weight sits.

---

## What is NOT claimed

- **pCO2 IS NOT FLUX.** `F = k·K0·ΔpCO2`, and neither the gas-transfer velocity's wind seasonality
  nor K0's own temperature seasonality is in any number here. Both modulate AMPLITUDE strongly;
  their effect on PHASE is second-order but not zero, and no result below should be quoted as a
  flux amplitude.
- **A climatology is not an error bar.** This product carries no per-month spread I am using, so
  the phases below have no observational uncertainty attached — unlike the inversion's, which are
  bootstrapped. Bands are reported instead, and the SPREAD ACROSS BANDS is the honest scale.
- No refit, no posterior; the model side is the already-measured 4.16 and is not recomputed.
