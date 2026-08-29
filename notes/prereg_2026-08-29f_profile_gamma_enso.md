# PREREG 2026-08-29f — **PROFILE `gamma_enso`: TUNING JOB OR STRUCTURE JOB?**
# Written and committed BEFORE the driver. **No gate below may move.**

**State:** `main` at `e3f007b`, clean. Nothing running.

## 0. THE QUESTION

08-29e measured the model at **33 % of the observed interannual CO₂ growth-rate sd** (0.301 vs
0.900 ppm/yr) with **r = 0.571** — right timing, wrong amplitude — and ENSO currently supplying
`sqrt(0.301² − 0.173²)` = **0.246** of it. `gamma_enso` = **0.85119**, fitted.

**Is the fit being BLOCKED from more ENSO, or is the ENSO RESPONSE SHAPE wrong?** One profile
decides which, and it decides whether this is tuning or structure.

## 1. THE ARITHMETIC, REGISTERED BEFORE THE RUN

`ccx_core.cpp:396-397` adds `gamma_enso * enso * enso_share[hi]` to the soil→atmosphere flux —
**LINEAR in `gamma_enso`**, so the ENSO-driven growth-rate sd should scale linearly with it.
To reach the observed 0.900 from a 0.173 non-ENSO baseline requires an ENSO contribution of
`sqrt(0.900² − 0.173²)` = **0.883**, i.e.

    gamma_enso  =  0.85119 x 0.883 / 0.246  =  ~3.05      (3.6x the fitted value)

**REGISTERED PREDICTIONS:**
- **E1 — LINEARITY.** sd_ENSO(γ) is linear in γ to within **3 %** over the grid. If it is not, the
  response is saturating and that alone is the structure answer.
- **E2 — THE PROFILE HAS AN INTERIOR MAXIMUM near the fitted value**, i.e. |argmax γ − 0.851| < 0.4.
  **PREDICTED: yes** — `gamma_enso` is a fitted parameter and nothing has changed the objective
  since it was fitted.
- **E3 — THE PRICE OF CLOSING THE GAP.** logpost at γ = 3.05 relative to the mode.
  Bands, fixed here: **CHEAP ≤ 20 | MODERATE ≤ 100 | PROHIBITIVE > 100** (the 08-29d scale).
  **PREDICTED: PROHIBITIVE.** If it is CHEAP, the fit was simply never asked and this is a tuning
  job — a much better outcome than expected, and it must not be explained away.
- **E4 — WHO REFUSES.** The by-stream decomposition at γ = 3.05. **PREDICTED: `co2_level_MLO` and
  `co2_level_SPO` carry ≥ 50 %** — ENSO adds year-to-year structure to the very rows that are
  currently fitted to 0.53–0.58 ppm RMS, and by [[ccx_stream_leverage]] they outvote everything.
- **E5 — CONDITIONAL BUY-BACK.** Re-optimise a small carbon slice (`beta_max`, `fert_k`, `q10`) at
  each γ. Frozen costs are upper bounds and this repo has been burned reading them as prices
  (handoff 08-25b §7). No gate — this repo has no stable prior for the buy-back fraction.
- **E6 — DOES IT EVEN HELP THE FIT'S OWN TARGET?** Report r (model vs obs anomaly) along the
  profile. **A larger amplitude with unchanged r means the model is being made LOUDER, not more
  RIGHT** — and r is what the pedagogy needs.

## 2. WHAT NO OUTCOME LICENSES

- **No adoption.** `gamma_enso` stays at 0.85119.
- **It does not price volcanoes.** 08-29e showed the thermal path can supply ≤ 7 % of Pinatubo and
  the missing mechanism is diffuse-light fertilisation; nothing here tests that.
- **It cannot attribute the residual variance.** Fires, hydrology, GCB methodology and observational
  error all live in the 0.900 and none is separated here.
