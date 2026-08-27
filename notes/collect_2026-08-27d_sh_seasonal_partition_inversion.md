# COLLECT — 2026-08-27d: THE MODEL BUILDS THE SPO SEASONAL CYCLE OUT OF THE
# WRONG TWO PIECES, AND THE OCEAN PIECE ARRIVES IN THE WRONG SEASON

Against `notes/prereg_2026-08-27d_sh_seasonal_partition_power.md` and its amendment, both
written before the corresponding measurement ran. **All six scored predictions are recorded
below, hits and misses.**

Scripts: `calibration/diag_seas_channel_decomp.R` (extended, measurement A) and
`calibration/diag_seas_signature_inversion.R` (new, measurement B). Both run at the canonical
mode with full forcing, ~6 s and ~40 s. Neither uses `ccx_hold_climate()`.

---

## THE RESULT IN ONE TABLE

The observed seasonal cycle at each station, split into a LAND and an OCEAN component by
their δ¹³C signatures — amplitude AND phase, from the observations alone — against the same
split of the model's own cycle. Peak-to-peak ppm, first harmonic, 1975–2024.

| stn | part | obs amp | model amp | ratio | obs peak mo | model peak mo | phase err |
|---|---|---|---|---|---|---|---|
| MLO | land | 7.717 | 7.235 | 0.94× | 3.39 | 3.54 | +0.15 |
| MLO | ocean | 1.091 | 0.582 | 0.53× | 8.35 | 9.50 | +1.16 |
| **SPO** | **land** | **0.683** | **1.373** | **2.01×** | 9.29 | 8.82 | −0.47 |
| **SPO** | **ocean** | **0.522** | **0.236** | **0.45×** | **8.52** | **3.35** | **−5.17** |

**Nature makes SPO's 1.17 ppm cycle by ADDING two nearly in-phase pieces** — land 0.683 peaking
month 9.29 and ocean 0.522 peaking 8.52, 0.77 months apart, 58 % + 45 % ≈ 103 %.

**The model makes its 1.15 ppm by SUBTRACTING two nearly antiphase ones** — land 1.373 at 8.82
against ocean 0.236 at 3.35, **5.47 months apart**, 120 % − 21 % ≈ 99 %.

**The CO2 amplitude agrees to 2 % because two errors cancel.** That is the mechanical statement
of handoff 27c §3's "the CO2 rows have no power", and it is now a measurement rather than an
inference: the row cannot see a partition error because the partition error is what makes it
agree.

---

## THE SIX PREDICTIONS, SCORED

**P1 — CONFIRMED.** The NH-origin part of the model's SPO cycle is **72.0 %** of it (floor ≥ 30 %,
point estimate 40–70 %). The analytic two-box transfer function at the mode's `tau_ex` = 1.159 yr
predicted **0.897 ppm** undamped; measured **0.821** — the SH sinks damp it by 8 %.

**P2 — CONFIRMED.** NH-origin peaks month **6.46**, base SPO at **8.71** — **2.25 months**, 108°
apart (floor ≥ 2). The two parts close to the total as vectors within **1.6 %**.

**P2's consequence — MISSED AS STATED, and the miss is informative.** Predicted |SH-local| >
the 1.09 ppm total; measured **1.060 ppm, 93.0 %**. But **SH-local LAND alone is 1.308 ppm,
114.7 %** — over 100 % as predicted. The three-channel SH aggregate is *smaller* than its land
pair because the model's SH ocean channel is ANTIPHASE to its SH land and cancels part of it.
That cancellation is the same defect the inversion then measured directly.

**P3 / P4 — NOT SCORED, knob withdrawn before the test.** Measurement A showed `seas_T_amp_SH`
moves the SPO cycle by **0.092 ppm** against `NEP SH`'s **1.390** — 15× apart. The parameter
carrying the −4.64 σ prior flag has essentially no authority over the observable P3/P4 were to be
scored on, so a slice in it would have measured the ridge and the priors. Amended openly in the
prereg before B was designed. **This is itself a finding:** the SH land respiration flag is not
being set by the SPO seasonal rows.

**P5 — CONFIRMED.** Observed SPO ocean share **44.7 %** (predicted 40–50 %).

**P6 — CONFIRMED, and it is the one that redirects §7c-3.** The observed SPO ocean component
peaks month **8.52, 95 % CI [7.82, 9.20]** — austral late winter/early spring. The model's SH
air-sea channel peaks month **4.16**. **4.35 months apart** (floor ≥ 3), and the interval excludes
the model's phase with room to spare.

**P7 — CONTROL PASSES.** MLO observed land share **113.3 %** (floor ≥ 80 %; over 100 % because the
NH land and ocean components are themselves antiphase and partly cancel). The inversion returns
the known answer where the answer is known, which is what licenses reading SPO.

---

## WHY THE OCEAN PHASE IS WRONG, AND WHAT IT IMPLIES

The model's only SH air-sea seasonal driver is `sst_seas_amp_SH`, which modulates **SST and
nothing else**. Colder water in austral winter is more soluble, so the channel draws CO2 DOWN in
the cold season and its atmospheric contribution peaks in austral autumn — month 4.16, which is
what it does. **A solubility-only ocean can only ever have that phase.**

The observed component peaks five months later, in austral late winter. **A seasonal cycle in
mixed-layer depth / entrainment of DIC-rich water is the mechanism with that phase** — winter
deepening brings high-DIC water up and drives outgassing in the same season the solubility term
is taking CO2 in. The model has no such term.

⚠ **The mechanism is my reading; the PHASE is the measurement.** I have no citation to hand for
the Southern-Ocean seasonal flux decomposition and am not labelling it established. What is
measured here is that the observed ocean-signatured component peaks at 8.52 [7.82, 9.20] and the
model's solubility channel peaks at 4.16. The named test is §1 of the next-step list below.

**⇒ §7c-3's structural candidate is NOT a land box.** Two of three independent lines that pointed
at "SH land" now read differently:

- The **2.01× SH land excess is real** and is the largest single component error in the table.
  But **0.821 of the model's 1.373 ppm SH land arrives from the NORTHERN hemisphere** through
  `tau_ex` — **more than the entire observed SPO land component of 0.683.** A land box placed in
  the SH cannot fix a signal generated in the NH.
- The **SH ocean is 0.45× in size AND 5.17 months out of phase.** Adding amplitude to a channel
  with the wrong phase makes the cycle worse, which is exactly why the fit suppressed
  `sst_seas_amp_SH` to **21 % of its observed value**. **The fit was right to.** The −6.32 σ prior
  flag on that parameter is the model being penalised for correctly refusing a broken channel —
  not evidence that the SH ocean amplitude is the problem.

---

## AND A NUMBER IN THE STANDING RECORD MOVES: the SPO partition residual is 1.93×, not ~1.5×

The two figures are the same quantity on two different estimators, and the whole gap is **one
cell**:

| | obs mean-of-magnitudes | obs magnitude-of-mean | inflation |
|---|---|---|---|
| MLO CO2 | 3.3818 | 3.3770 | 1.00× |
| MLO δ¹³C | 0.1788 | 0.1783 | 1.00× |
| SPO CO2 | 0.5980 | 0.5850 | 1.02× |
| **SPO δ¹³C** | **0.0223** | **0.0168** | **1.33×** |

Every model series sits at 1.00×. The observed SPO δ¹³C harmonic is the only inflated series in
the problem, and **1.93 / 1.33 = 1.45 ≈ 1.48**, which is the published figure exactly.

`diag_seas_isotope_rectification.R` uses `mean(sqrt(a²+b²))` — the mean of per-year magnitudes,
which cannot distinguish a coherent cycle from year-to-year scatter and so inflates the noisy
observed denominator. `diag_seas_channel_decomp.R` uses `|mean vector|`, and its own comment says
why: *"averaging per-year magnitudes would inflate them by Jensen."*

**THIS IS A METHODOLOGICAL CHOICE AND IT IS FLAGGED, NOT RESOLVED.** My recommendation is the
magnitude-of-mean-vector — it is the only one of the two that is noise-immune, the likelihood
scores the coefficients rather than their magnitudes, and the inflation is confined to exactly the
series that would flatter the model. **Marcus's call.** [[amp_definition_mismatch]] is the
standing memory for this class.

---

## NEXT, IN ORDER

1. **Find an observational Southern-Ocean seasonal air-sea CO2 flux climatology** (SOCAT-derived
   products are the obvious family) and check the phase against the 8.52 [7.82, 9.20] the
   inversion returns. That converts my mechanism reading into a citation or kills it.
   **Until then the mechanism is a hypothesis and the phase gap is the result.**
2. **Price the interhemispheric leak.** The model's NH→SPO leak, 0.821 ppm, exceeds the whole
   observed SPO land component. Two candidates: `tau_ex` (1.159 yr at the mode) and the NH box's
   own amplitude, which the fit has pinned near MLO's 6.6 ppm while a hemispheric mean should
   plausibly be larger. **The second is checkable against station data and is not checked** —
   NOAA's network covers the NH latitude range and the hemispheric-mean seasonal amplitude is a
   measurable number, not a modelled one.
3. **Only then** decide whether any structural land change is owed. On this table the SH land
   excess is mostly imported, so the SH land box has lost its motivation and the two candidates
   above have gained it.

## Carried caveats

- The inversion assumes each channel's signature is a signed scalar. **GATED, not assumed:** all
  12 channel/station pairs are antiphase to within **0.43 months** and the gate drops anything
  beyond 1.0. The land and ocean signatures separate by **10.3×** (−0.04733 vs −0.00461 ‰/ppm),
  which is what conditions the inverse; both spreads are propagated into every bar.
- **Cross-validated on the model side**, where the direct channel sum is also available: SPO land
  **+2.4 %**, SPO ocean **−4.9 %**, all four phases within **0.55 months**. MLO land +7.9 % and
  MLO ocean +25.9 % — larger, and the residual is global emission seasonality (0.377 ppm at MLO,
  in neither channel set, fossil at −27.9 ‰ so it inverts as land) plus nonlinearity.
- Bars are bootstrap over YEARS crossed with the signature ranges, 2000 draws, seed 20260827.
  Angles are averaged as VECTORS; a wrapped scalar median would break at the Dec/Jan seam.
- Everything here is at the canonical mode, frozen. **No refit. No posterior.**
