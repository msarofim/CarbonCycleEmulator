# Handoff — CarbonCycleEmulator, 2026-08-27d: §7c-3 IS OPEN, and it is NOT a land box —
# the model's SH OCEAN CHANNEL ARRIVES FIVE MONTHS LATE

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`, clean.
**Nothing is running.** **Suite: 1122 pass / 0 fail** — unchanged from `9d866ca`.

**Supersedes** `notes/handoff_2026-08-27c_suite_green_partition_next.md` for its §4 (the next
step). Its §1–§3 stand and are not repeated. Pre-registration:
`notes/prereg_2026-08-27d_sh_seasonal_partition_power.md` (+ an amendment written before
measurement B). Scored: `notes/collect_2026-08-27d_sh_seasonal_partition_inversion.md`.
CHANGELOG 2026-08-27d. Commits `b8f7838`, `f0c9a25`, `61ec881`.

---

## 0. STATE IN SIX LINES

1. **§7c-3 is OPEN and its candidate CHANGED.** Not a land box. §1, §3
2. **THE HEADLINE: the model makes SPO's cycle by SUBTRACTING two antiphase pieces where
   nature ADDS two in-phase ones.** The 2 % CO2 agreement is two errors cancelling. §1
3. **The model's SH ocean component is 0.45× in size and 5.17 MONTHS out of phase.** §1
4. **Two standing readings REVERSE**: `sst_seas_amp_SH`'s −6.32 σ flag is the model penalised
   for being RIGHT, and the SH land excess is mostly IMPORTED FROM THE NH. §3
5. **A number in the record moves: the SPO partition residual is 1.93×, not ~1.5×** — an
   estimator artefact, and it is a METHODOLOGICAL CHOICE owed to Marcus. §4
6. **Two named next steps, both observational, neither requiring a refit.** §5

---

## 1. THE TABLE — the observed cycle split into land and ocean, from the observations alone

`calibration/diag_seas_signature_inversion.R` (new, ~40 s). Peak-to-peak ppm, first harmonic,
1975–2024, at the canonical mode with full forcing.

| stn | part | obs amp | model amp | ratio | obs peak mo | model peak mo | phase err |
|---|---|---|---|---|---|---|---|
| MLO | land | 7.717 | 7.235 | 0.94× | 3.39 | 3.54 | +0.15 |
| MLO | ocean | 1.091 | 0.582 | 0.53× | 8.35 | 9.50 | +1.16 |
| **SPO** | **land** | **0.683** | **1.373** | **2.01×** | 9.29 | 8.82 | −0.47 |
| **SPO** | **ocean** | **0.522** | **0.236** | **0.45×** | **8.52** | **3.35** | **−5.17** |

**Nature ADDS** at SPO: land 0.683 at month 9.29 and ocean 0.522 at 8.52, **0.77 months apart**,
58 % + 45 % ≈ 103 % of the 1.168 total.
**The model SUBTRACTS**: land 1.373 at 8.82 against ocean 0.236 at 3.35, **5.47 months apart**,
120 % − 21 % ≈ 99 % of its 1.148.

**⇒ The CO2 amplitude agrees to 2 % BECAUSE two errors cancel.** Handoff 27c §3 inferred that the
CO2 rows have no power; this measures the mechanism. [[no_power_null]].

**HOW IT WORKS, and why you can trust it.** Every seasonal channel's δ¹³C harmonic vector is
ANTIPHASE to its own CO2 harmonic vector, so each signature is a signed SCALAR and two vector
equations in two vector unknowns close exactly. That premise is **GATED, not assumed**: all 12
channel/station pairs sit within **0.43 months** of antiphase and the gate drops anything past
1.0. The signatures are **−0.04733** (land) and **−0.00461** (ocean) ‰/ppm — **10.3× apart**,
which is what conditions the inverse. Both spreads propagate into every bar.

**THREE GUARDS, all of which passed and all of which you should keep if you extend this:**
- **The method control is scored FIRST and gates the rest.** MLO, where the answer is known:
  observed land share **113.3 %** (over 100 % because NH land and ocean are themselves antiphase).
  The script *stops* if it fails.
- **Cross-validated on the MODEL side**, where the direct channel sum is also available and the
  inversion never sees it: SPO land **+2.4 %**, SPO ocean **−4.9 %**, all four phases within
  **0.55 months**. MLO land +7.9 % / ocean +25.9 %, residual = global emission seasonality
  (0.377 ppm at MLO, in neither channel set, fossil at −27.9 ‰ so it inverts as land).
- **Bars**: bootstrap over YEARS × the signature range, 2000 draws, **seeded** (an unseeded bar
  moved a share by ~0.5 pp between runs, enough to walk it across a prediction boundary).
  Angles averaged as VECTORS — a wrapped scalar median breaks at the Dec/Jan seam.

---

## 2. MEASUREMENT A — 72 % of the model's SPO cycle is made in the NORTHERN hemisphere

`calibration/diag_seas_channel_decomp.R` gained three cross-hemisphere cases (~6 s). Read at SPO:

- **NH-origin 0.821 ppm (72.0 %), peaking month 6.46.** SH-local 1.060 (93.0 %) at 10.07.
  **108° apart**, and they close to the 1.140 total as vectors within **1.6 %**.
- The analytic two-box transfer function at the mode's `tau_ex` = 1.159 yr —
  `|C_S/C_N| = (1/τ)/√(ω² + 1/τ²)` = 0.1360, lag `atan(ωτ)` = 2.74 mo — predicts **0.897 ppm**
  undamped against **0.821** measured. **The SH sinks damp the leak by 8 %, no more.**

**AND A TEST DIED BEFORE IT RAN.** `seas_T_amp_SH` — the parameter carrying the −4.64 σ prior flag
and the one the prereg's P3/P4 named — moves the SPO cycle by **0.092 ppm** against `NEP SH`'s
**1.390**. It has essentially no authority over its own observable. **The SH land respiration flag
is NOT being set by the SPO seasonal rows**, and a slice in it would have measured the
`seas_T_amp`×`q10` ridge ([[ccx_seas_q10_ridge]]), not the partition. P3/P4 were withdrawn in a
prereg amendment written before B was designed; P5–P7 replaced them.

**Scored:** P1 ✓, P2 ✓, P5 ✓ (44.7 %, predicted 40–50 %), P6 ✓ (4.35 months, predicted ≥ 3),
P7 control ✓. **P2's consequence MISSED as stated** — predicted SH-local > 100 % of the total,
measured **93.0 %** — and the miss is informative: **SH-local LAND alone is 114.7 %**, and the
three-channel aggregate is smaller than its land pair because the model's SH ocean is antiphase to
its SH land and cancels part of it. That is the same defect the inversion then measured directly.

---

## 3. ⇒ TWO STANDING READINGS REVERSE, AND §7c-3'S CANDIDATE CHANGES

**(a) `sst_seas_amp_SH`'s −6.32 σ flag is the model being PENALISED FOR BEING RIGHT.** The channel
is solubility-only: `sst_seas_amp_SH` modulates SST and nothing else, so colder austral winter
water takes CO2 UP and the channel's atmospheric contribution can only peak in austral autumn.
Month 4.16 is the *only* phase it can have. Adding amplitude to a wrong-phase channel makes the
cycle worse — so the fit suppressed it to **21 % of observed, correctly**. The flag is the prior
objecting to a refusal that the physics justifies.

⚠ **The MECHANISM that would have the observed phase — a seasonal mixed-layer / entrainment cycle
bringing DIC-rich water up in austral winter — is MY READING, not a citation.** I have no source
to hand and am not labelling it established. **The PHASE is the measurement**; the mechanism is
§5's first item.

**(b) THE SH LAND BOX IS DEAD AS POSED.** **0.821 of the model's 1.373 ppm SH land component
arrives from the NORTHERN hemisphere** — more than the **entire observed SPO land component of
0.683**. A box placed in the SH cannot fix a signal generated in the NH. The 2.01× SH land excess
is real and is the largest single component error in the table, but it is mostly *imported*.

**The three lines that pointed at "SH land" in handoff 27c §4 now read:** the prior flags are (a)
above; the driver ratios are (a) again for the ocean and imported for the land; the surviving
partition residual is the wrong-phase ocean. **Marcus's named candidates from handoff 27 — latitude
bands, stratosphere, high-latitude mixing — are untouched by this and stay live**, but note
`R/model.R:218` records that NH latitude banding was already tested and REJECTED
(`diag_npp_twobox.R`: every multi-box fit deletes its own low-latitude boxes).

---

## 4. ⚠ A DECISION OWED: the SPO partition residual is 1.93×, not ~1.5×

The two figures are the same quantity on two estimators, and **the whole gap is ONE CELL**:

| | obs mean-of-magnitudes | obs magnitude-of-mean | inflation |
|---|---|---|---|
| MLO CO2 | 3.3818 | 3.3770 | 1.00× |
| MLO δ¹³C | 0.1788 | 0.1783 | 1.00× |
| SPO CO2 | 0.5980 | 0.5850 | 1.02× |
| **SPO δ¹³C** | **0.0223** | **0.0168** | **1.33×** |

All four model series sit at 1.00×. **1.93 / 1.33 = 1.45 ≈ 1.48**, the published figure exactly.
`diag_seas_isotope_rectification.R` uses `mean(sqrt(a²+b²))`, which cannot separate a coherent
cycle from year-to-year scatter; `diag_seas_channel_decomp.R` uses `|mean vector|` and its own
comment says why. **The inflation lands in the DENOMINATOR, so the estimator that had been quoted
is the one that flatters the model.**

**Recommendation: the magnitude-of-mean-vector, and restate the standing target as 1.93×.** It is
the only noise-immune one of the two, the likelihood scores the coefficients rather than their
magnitudes, and the inflation is confined to exactly the series that would flatter us. **Not
resolved unilaterally — Marcus's call**, per the standing rule that ensemble/aggregation choices
are flagged, not silently settled. [[amp_definition_mismatch]] carries this incident.

---

## 5. NEXT, IN ORDER — both observational, neither needs a refit

1. **Get an observational Southern-Ocean seasonal air-sea CO2 flux climatology** (SOCAT-derived
   products are the obvious family) and check its phase against the **8.52 [7.82, 9.20]** the
   inversion returns. That converts §3(a)'s mechanism into a citation or kills it. Nothing on
   disk covers this — it is a download.
2. **Price the interhemispheric leak.** Two candidates, and the second is UNCHECKED and cheap:
   - `tau_ex` = 1.159 yr at the mode. Its leverage on SPO is now analytic (§2), so a profile is
     one line, not a run.
   - **The NH box's own seasonal amplitude is pinned near MLO's 6.6 ppm**, and a hemispheric
     MEAN should plausibly be larger than a subtropical station's. If it is, the leak the model
     already over-supplies gets worse. **NOAA's network measures this directly** — it is a
     number, not a model output, and nobody has looked.
3. **Only then** ask whether any structural land change is owed.

**Still open behind it, unchanged:** the d¹³C Suess overshoot re-check; whether `gcb_land_sink`
SHOULD be decisive (−7.94 and +2.31 σ, carrying `LIK_LAND_SINK_INFLATE` = 3.0 and a known GCB
closure error); `kz` railing (6332 vs a bracket top of 6528); the pump's `alpha13_signed` (b) case;
`alpha_as_*`; the Hessian condition number; **the sampler — still the project's oldest open item,
and there is STILL NO POSTERIOR.**

**And still owed from 27c:** `ccx_hold_climate()`'s incomplete-control gap is **NOT audited beyond
the one test that found it**. Nothing in this handoff uses it.

---

## 6. NON-OBVIOUS STATE ADDED TODAY

- **`diag_seas_channel_decomp.R`'s linearity check no longer indexes `CD_CASES[1:6]`** — it uses
  the named `CD_SINGLE`, so appending aggregate cases cannot silently corrupt it.
- **`diag_seas_signature_inversion.R` reduces both species over the INTERSECTION of their observed
  years**, not the CO2 record's. The δ¹³C record starts later at both stations; using the CO2 years
  gives `NA` and the first version of the script died on it.
- **`INDEX_ccx.md` was 19.1 KB, over its 18 KB HARD ceiling.** Consolidated to **17.3 KB** — the
  blockers section cut from 9.4 KB to 7.6 KB *while adding* the new finding, and a duplicate
  `ccx_gates_at_mode` entry removed. All 98 links verified to resolve. Still over the 14 KB soft
  target; a further pass is owed but it is no longer a restructure.
