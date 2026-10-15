# G1 — the 1959 methodology seam vs the budget error. 2026-08-25.

`calibration/diag_gcb_seam_1959.R` → `calibration/output/gcb_seam_1959/{gcb_seam_1959.rds,.log}`.
Data-only; **no refit**, as §6 specified. Reads with `handoff_2026-08-25_gcb_imbalance_programme.md`.

## VERDICT: §5's century-drift reading does NOT survive. The program shrinks.

Four of the five things §5 rested on fail their own error bar or their own decomposition.

| §5 said | G1 measures |
|---|---|
| 37.8 ppm cumulative, **56 % pre-1959** | reproduced exactly (identity closes to 1.4e-10) |
| "the century drift" | **1850–1939 nets 16.6 GtC and changes sign twice**; the 1940s+50s carry **28.1 of 44.7 GtC = 63 %** in 17 % of the years |
| implicitly, that 44.7 GtC is a number to explain | **0.43–1.5 σ** once the errors are correlated as a smoothed reconstruction's must be |
| the seam is a candidate generator | **confirmed, and localized: it is the OCEAN SINK, not growth** |
| `rep_dC` might live here | growth is **exonerated** and the agreement is **circular anyway** |

## T0 — the bar, before any attribution

The imbalance's 1 σ is now derived from `R/likelihood.R`'s own sigmas rather than a hand-set
literal: `sqrt(LUC 0.70² + OCEAN 0.40² + LAND 0.50² + 5 %·F̄)` = **0.949 GtC/yr**, and that is a
**floor** — the pre-seam sinks are diagnostic-model and DGVM means, not the products those sigmas
describe.

| ρ (error correlation length) | 1 σ on the 109-yr cumulative | 44.66 GtC is |
|---|---|---|
| 0 | 9.9 GtC | 4.51 σ |
| 0.8 | 29.1 | **1.53 σ** |
| 0.9 | 41.3 | 1.08 σ |
| 0.99 | 87.6 | 0.51 σ |
| 1 | 103.5 | 0.43 σ |

**ρ = 0 is the wrong row.** Pre-1959 `atm_growth` and `ocean_sink` are smooth *by construction*
(GCB's own header), so their errors are the correlated case. [[curvature_needs_an_error_bar]]
firing for the fourth time on this project.

## T1 — the seam is real, and it is the OCEAN SINK

Smoothness fingerprint (sd of second differences, post/pre): `atm_growth` **27.9×**,
`ocean_sink` **42.4×**, every other term ≤ 4.4×. That is GCB's header statement, measured.

But the **variance** seam and the **level** seam are different objects, and only one term has both:

| term | step at 1958.5 (w=10) | bootstrap σ | z | w=8 → 20 |
|---|---|---|---|---|
| `ocean_sink` | **+0.232** | 0.073 | **+3.18** | +2.05 → **+5.30**, monotone |
| `atm_growth` | +0.239 | 0.443 | +0.54 | +0.23 → +1.53, **not resolved** |
| `imbalance` | −0.290 | 0.368 | −0.79 | −0.01 → −2.23 |
| `luc` | −0.129 | 0.114 | −1.13 | −2.4 at w≥15 (trend change, not a step) |

**The Newey-West bar was ANTI-CONSERVATIVE by 1.0–4.9× and is not what any z above uses.** With
w = 8–20 residuals and a lag truncation of 1–2, NW is badly downward-biased. The bar used is a
**matched block bootstrap**: each side's own residuals about a local quadratic over a ±30-yr pool,
block-resampled through the *same* estimator, which preserves the seam's own heteroscedasticity
(residual sd about a local quadratic: `ocean_sink` pre **0.0093** vs post **0.1015**).

*A first attempt at the MC was wrong and is recorded here rather than deleted:* it resampled
residuals about a **global** linear fit, so for `atm_growth` the "noise" was really the global
line's curvature misspecification, and it declared the analytic bar anti-conservative by 8×. A null
distribution has to be built around a trend model the data could plausibly have come from.

## T2/T3 — pricing the ocean step: an upper bound, and a non-identification

Held constant over 109 yr the step is **+25.3 GtC = 57 %** of the pre-seam cumulative — an
**upper bound**, since a diagnostic model at a lower CO₂ level *should* have a smaller sink.

The backcast that would replace it does **not identify**: `ocean_sink ~ (CO₂ − 276.88)` fitted on
1959–1980 gives a pre-seam gap of **+6.8 GtC (15 %)**, fitted on 1959–2024 it gives **+51.8 GtC
(116 %)** — **7.6× apart**, because the relation is curved (the buffer factor rises with CO₂) and
the pre-seam era is outside the fitted range. **No window is chosen.** The seam's cumulative share
is bounded, not measured.

## T4 — the growth term is exonerated, and the test is circular anyway

Cumulating GCB's `atm_growth` forward from an 1850 ice anchor and comparing to the **172 raw Law
Dome samples the likelihood actually scores**: mean **−1.00 ppm**, RMS 2.03, and in units of the
ice term's own σ, **RMS z = 0.46**. In the 1940–58 plateau window itself, mean −1.91 ppm, RMS
z = 0.53, against a mean ice σ of 4.35 ppm.

**T4b, the one identified growth number in the file.** The level residual *is* the running integral
of the growth error, so its drift across the era needs no extrapolation and no bandwidth choice
([[smoother_wider_than_feature]] is the reason to prefer the level to a differentiated spline).
Drift 1850–79 → 1929–58 = **−1.19 ± 1.04 ppm = 1.14 σ**, with n_eff from the 4.5–7.0 yr air-age
spectral width ([[ccx_d13c_neff]]) rather than the raw sample count. That is **2.5 GtC = 6 %** of
the pre-seam cumulative.

**AND IT IS CIRCULAR.** GCB's pre-1959 growth is Joos & Spahni 2008, itself a reconstruction of
this same Law Dome/firn record. Agreement is **by construction**, not confirmation. The correct
reading is the strong one: GCB's pre-seam growth and our ice term are **one object**, so a model
already fitted to our ice term is already fitted to GCB's growth, and the imbalance can only ever
have been a statement about **emissions and sinks**. §5's item 1 — "most of it is being taken up by
the model's sinks responding to a CO₂ level that is itself partly the imbalance's doing" — has the
causality backwards: the CO₂ level is an *input* to the imbalance, not an output of it.

## T5 — it is not a century drift; it is the 1940s–50s

| decade | GtC | running | % of 44.7 |
|---|---|---|---|
| 1850s–1930s | +16.56 | 16.56 | **37 %** (sign changes twice: −2.34 in the 1880s, −1.25 in the 1890s) |
| **1940s** | **+13.04** | 29.59 | 66 % |
| **1950s** | **+15.07** | 44.66 | 100 % |

**63 % of the pre-seam cumulative is the 1940–58 window** — i.e. the published CO₂ plateau the
08-23/08-24 arc spent six refits on and **de-ranked**, plus the decade immediately before the
methodology change whose ocean sink T1 resolves as stepped. The successor program would have
re-inherited the arc that was just closed.

## What survives, and what should be done with it

- **Nothing here is a home for `rep_dC`.** Growth is exonerated (6 %, 1.14 σ) and circular; the
  cumulative is ≤1.5 σ; the residue is the de-ranked plateau plus a seam in a product we do not
  score before 1959 (the objective scores `gcb_land_sink`/`gcb_ocean_sink` from 1959 on).
- **G2 (price the transfer) and G3 (isotopic attribution) are now premature** — both were scoped to
  explain a 37.8 ppm century drift that does not survive T0 and T5. Do not run them as written.
- **G4 (a refit) is unjustified by this line.**
- **What is worth keeping** is narrow: GCB's pre-1959 `ocean_sink` carries a resolved
  **+0.23 to +0.28 GtC/yr** discontinuity at its own methodology seam. That is a caveat to put on
  any future use of the pre-1959 budget, not a program.
