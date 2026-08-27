# Handoff — CarbonCycleEmulator, 2026-08-27g: **THE NEXT STEP IS SH OCEAN BANDS**
# (authorised by Marcus, 2026-08-27) — the target, the design, and the four traps

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`, clean.
**Nothing is running.** **Suite: 1122 pass / 0 fail** — no `R/` change since `9d866ca`.

**This is a DESIGN handoff.** The diagnosis is finished and is not re-argued here; §1 states only
the numbers the design has to hit. Provenance:
`handoff_2026-08-27d_partition_inverted_ocean_phase_is_wrong.md` (the inversion, §1/§2/§4 still
stand), `handoff_2026-08-27ef_weighting_not_phase.md` (the correction that produced this step),
collects `…27d…`, `…27ef…`, preregs `…27d/e/f`. CHANGELOG 2026-08-27 / d / e-f.

**⚠ NOTHING IS BUILT YET AND NOTHING SHOULD BE UNTIL §3 IS ANSWERED.** §4 is a decision, not a
formality: the cheap version of this change and the expensive version answer different questions.

---

## 0. STATE IN SIX LINES

1. **The defect is settled**: the SH mean is a **76 % cancellation** of two antiphase ocean
   regimes and the model matches the residual. §1
2. **`sst_seas_amp_SH` cannot fix it** — the parameter scales a phase it cannot rotate. §1
3. **Everything else is ruled out**: `tau_ex` exonerated, SH land box dead, CO2 rows powerless. §2
4. **THE BAND AND THE MECHANISM MUST LAND TOGETHER.** Two solubility bands share a phase and buy
   nothing. §3
5. **There is a cheap version that is NOT a box split** and probably answers the question. §4
6. **Score it on the isotopes or the drivers, and measure POWER first.** §5

---

## 1. THE TARGET, in numbers the design has to hit

Observed, from `calibration/diag_so_pco2_phase.R` (Landschützer/Laruelle pCO2 climatology
NCEI 0209633 + ERSSTv5, ocean-area weighted, land masked):

| limb | pCO2 amp µatm | peak mo | vs SST peak |
|---|---|---|---|
| subtropical 0–40 S | 11.70 | **1.38** | in phase (0.6–0.8 mo) |
| Southern Ocean 40–90 S | 7.18 | **7.50** | **5.56 mo away** |
| **SH mean (vector)** | **4.56** | 1.20 | 0.85 mo |
| scalar sum | 18.87 | — | **76 % CANCELS** |

**What SPO sees is the Southern Ocean.** Its ΔpCO2 peaks **7.41**; the inversion put the observed
ocean-signatured atmospheric component at **8.52 [7.82, 9.20]** — a **1.11-month** lag. The
subtropical limb, at 1.52, cannot produce 8.52 at any lag.

**What the model has:** one SH ocean box, one seasonal air-sea driver (`sst_seas_amp_SH`,
modulating SST and nothing else), atmospheric contribution peaking month **3.35**, amplitude
**0.236 ppm** against an observed **0.522**. So the ocean limb is **0.45× in size and ~5.2 months
in phase error at SPO**, while being *right* for the hemispheric mean (4.16 vs an observed 4.54).

**The NH is the control and it needs no band split:** NH-mean pCO2 is **0.30 months** from NH-mean
SST. The NH really is solubility-dominated at the hemispheric mean. **Do not band the NH ocean on
this evidence.**

## 2. WHAT IS ALREADY RULED OUT — do not re-open these

- **`tau_ex`** — EXONERATED (27e). The SPO δ¹³C-per-ppm ratio moves **4.2 % across a 5.7× range**.
  Transport relabels *where* the cycle was made, not *what* made it.
- **The SH land box** — DEAD as posed (27d). **0.821 of the model's 1.373 ppm SH land arrives from
  the NH**, more than the entire observed SPO land component of 0.683.
- **`seas_T_amp_SH`** — moves the SPO cycle by **0.092 ppm** against `NEP SH`'s 1.390. Its −4.64 σ
  flag is not set by the SPO seasonal rows.
- **The CO2 seasonal rows as a test** — no power; already matched, by two errors cancelling.
- **NH land latitude banding** — tested and REJECTED (`diag_npp_twobox.R`, `R/model.R:218`: every
  multi-box fit deletes its own low-latitude boxes). **Different limb, different hemisphere —
  that is NOT precedent for the ocean, in either direction. Do not cite it as one.**

## 3. ⚠ THE DESIGN CONSTRAINT THAT DECIDES EVERYTHING

**A band split ALONE buys nothing.** The model's only seasonal air-sea driver is SST. Split the SH
ocean into two bands today and you get two *solubility* channels, both peaking in austral autumn,
differing only in amplitude — their vector sum has the same phase as the single channel it
replaced. **The 5.9-month phase separation is not a property of latitude; it is a property of a
MECHANISM the model does not contain.**

**The missing mechanism is a seasonal entrainment / mixed-layer cycle**: winter deepening entrains
DIC-rich water and raises surface pCO2 in the season solubility alone would be lowering it. That
is now **measured, not asserted** — south of 40 S, pCO2 peaks month 7.50, **5.56 months from SST**
(prereg 27f P2, confirmed; method control P3 passed at 0.78; NH control 0.30).

⇒ **The band and the mechanism must land together.** That is what makes this a structural change
rather than a reparametrisation, and it is why §4 exists.

## 4. ⇒ THE DECISION OWED BEFORE ANY CODE: two versions, and they are not equivalent

### 4a. THE CHEAP ONE — a second seasonal air-sea CHANNEL, no new state (RECOMMENDED FIRST)

Keep one SH ocean box. Give the air-sea term a **second seasonal component** with its own phase
and amplitude, representing the Southern-Ocean entrainment limb, and let the existing SST term
carry the subtropical limb. Both are already area-weightable from §1's table.

- **No new boxes, no new state, no spin-up change, no C++ port of a new column.**
- Two new parameters at most (a Southern-Ocean amplitude and its phase), and **§1 gives the phase
  from observation** — so it can be a MEASURED CONSTANT, not a fitted one, exactly as
  `CCX_SST_SEAS_LAG` = 1.32 was derived from ERSSTv5 rather than fitted.
- **It tests the hypothesis directly**: if a correctly-phased ocean channel is what SPO needs, this
  will show it, and it will do so without a single new degree of freedom in the ocean state.
- **What it CANNOT do** is give the two limbs different carbon chemistry, different Revelle
  factors, or different mean sinks — it is a seasonal-flux fix only.

### 4b. THE EXPENSIVE ONE — a genuine second SH ocean column

Two SH ocean columns (subtropical, Southern Ocean) with their own areas, mixed layers, `kz`,
outcrop and conveyor limbs. **This roughly doubles the SH ocean state and needs the C++ core
ported alongside `R/model.R`** (both cores are gated by `test-parity.R`). It buys the mean-state
questions 4a cannot touch — and it lands on `h_ml`, `kz` (which RAILS at 6332 against a bracket
top of 6528), the pump and the conveyor all at once.

**MY RECOMMENDATION: 4a first, and treat 4b as conditional on what 4a's residual looks like.**
4a is days; 4b is the largest structural change since the pump, on a model with **no posterior**
and a sampler that has never converged. If 4a closes the SPO isotope residual, 4b is unnecessary
for this problem. If 4a moves it and stalls, its residual tells you what 4b has to supply.
**Marcus's call — this is a scoping decision, not mine.**

## 5. HOW TO POSE IT, WHICHEVER VERSION

1. **PRE-REGISTER.** Every seasonal conclusion in this arc that was not pre-registered has been
   retracted by its own refit. The 27d/e/f preregs are the pattern: predictions with numeric
   falsifiers, a method control scored FIRST, and an explicit "what is NOT claimed".
2. **MEASURE THE POWER BEFORE THE FIX.** The CO2 seasonal rows are structurally incapable of
   rejecting a partition error ([[no_power_null]]). Score on **`d13c_seasonal_SPO`** and on the
   **driver ratios**. A band split that reproduces the same residual would look like success on
   the CO2 rows.
3. **THE PREDICTION TO STATE IN ADVANCE**: a correctly-phased SH ocean channel should let
   `sst_seas_amp_SH` rise toward its observed 1.746 **without** the seasonal rows objecting —
   because the objection was to the phase, not the amplitude. **If it does not, the weighting
   account in §1 is wrong and that is the finding.**
4. **CARRY THE CONFOUNDS.** `seas_T_amp`×`q10` is an EXACT ridge ([[ccx_seas_q10_ridge]], product
   held to 0.2 % over a 2.5× `q10` range) and `beta_max`/`fert_k` absorb 85 % of a frozen cost, so
   **a frozen 1-D scan will overstate every cost.** Read shape and direction, not Δlogpost.
5. **RE-RUN `diag_seas_signature_inversion.R` AFTER**, not just the objective. It is the
   diagnostic that states the result in the form the problem was posed in, and its MLO control
   is the gate that says the inversion is still readable.
6. **Whatever the objective does, the DRIVER RATIOS are the second scorecard** — SH ocean at 21 %
   of observed, SH land at 29 % of its bracket's low end. A fix that improves logL while pushing
   those further out has moved the problem, not solved it.

## 6. NON-OBVIOUS STATE — read before touching anything

- **⚠ THE pCO2 FILE'S FILL VALUE IS NOT APPLIED BY `ncdf4`** — it names the attribute `FillValue`,
  not `_FillValue`, **and stores it as a STRING**. Land came back as −999 in the first run of
  `diag_so_pco2_phase.R`. **Fixed, and gated** (finite fraction asserted 0.55–0.78). It cost only
  AMPLITUDES: −999 is constant in time, so every PHASE was right to the last decimal and no
  verdict moved. **All amplitudes now in the record are the corrected ones.**
  [[fillvalue_not_applied]].
- **pCO2 IS NOT FLUX.** `F = k·K0·ΔpCO2`. Nothing in `diag_so_pco2_phase.R` carries the wind
  seasonality in `k` or the temperature seasonality in `K0`. **No number in it is a flux
  amplitude.** For 4a this matters: the *flux* weighting is more Southern-Ocean-tilted than the
  area weighting §1 uses, so §1's SO share is if anything an UNDER-estimate.
- **A climatology carries no error bar.** These phases have no observational uncertainty attached,
  unlike the inversion's bootstrapped intervals. **The spread ACROSS BANDS is the honest scale.**
- **`R/likelihood.R:1028` maps `co2_NH` → MLO directly**, with only a LEVEL offset (`rep_dC`) and
  **no seasonal representation term at all** — so the model asserts MLO's cycle IS the NH
  hemispheric mean. **Still unchecked, still cheap, and it interacts with this work**: if a
  hemispheric mean is larger, the NH leak into SPO (already 0.821 ppm) gets worse. NOAA's network
  measures it.
- **`ccx_hold_climate()`'s incomplete-control gap is unaudited** beyond the one test that found it
  (27c §2). Nothing in 27d–g used it. **A new seasonal channel is exactly the kind of thing it
  would fail to hold** — audit it before using it as a control for this work.
- **The memory sub-index was re-cut mid-session**: the seasonal arc now lives in
  `INDEX_ccx_seas.md` (7.6 KB), split out of `INDEX_ccx.md` (12.8 KB). Both inside budget.
- **New download**, gitignored, registered as block **[6c]** in `data-raw/download_data.R` and
  appended **by hand** to `MANIFEST.csv` (fetched by curl, not a full run; the note says so):
  `MPI-ULB-SOM_FFN_clim.nc`, 47.5 MB, sha256 `aad8a56a…`.
- **New diagnostics**, all fast: `diag_seas_signature_inversion.R` (~40 s),
  `diag_tau_ex_leak_profile.R` (~25 s), `diag_so_pco2_phase.R` (~2 s), and three
  cross-hemisphere cases added to `diag_seas_channel_decomp.R` (~6 s).

## 7. STILL OPEN BEHIND THIS, UNCHANGED

The d¹³C Suess overshoot re-check; whether `gcb_land_sink` should be decisive (−7.94, +2.31 σ,
`LIK_LAND_SINK_INFLATE` = 3.0, a known GCB closure error); **`kz` railing** (6332 vs a bracket top
of 6528 — and 4b would land directly on it); the pump's `alpha13_signed` (b) case; `alpha_as_*`
(hardcoded, uncited, and **temperature-independent under a seasonal SST cycle** — 4a touches this
neighbourhood); the Hessian condition number; **the sampler — still the project's oldest open
item, and there is STILL NO POSTERIOR.**

**A DECISION STILL OWED (27d §4):** the SPO partition residual is **1.93×, not ~1.5×** — an
estimator difference, not a model change. `mean(sqrt(a²+b²))` inflates the observed SPO δ¹³C
harmonic by **1.33×** where all seven other series sit at 1.00–1.02×, and the inflation is in the
DENOMINATOR. Recommendation is the noise-immune `|mean vector|`. **Flagged, not resolved.**
