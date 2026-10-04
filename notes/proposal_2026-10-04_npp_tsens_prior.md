# PROPOSAL 2026-10-04 — revisiting the `npp_tsens` (greening) prior (objective #16 candidate) — FOR MARCUS'S RULING

> **RULED 2026-10-04 (Marcus): "Preview P3 with q10 freed (Recommended)".** The preview
> (`calibration/diag_p3_netclimate_preview.R`) is running; §5's choice between P3 and P4 waits on it. Checked first: the
> interactive-CO₂ bias in the net-climate comparison is measured small (−0.023 GtC/yr; like-for-like +0.141, z +1.34;
> `calibration/diag_net_climate_co2_feedback.R`), so §3's "wrong sign" stands.

> **THE P3 PREVIEW, READ (10-04 k; CHANGELOG 10-04 k). §5's choice is now P0/P3 vs P4.**
> - The running preview had **no power on `q10`**. Its block frees `q10` to 0.15 of its marginal sd, because the
>   seasonal rows fix A_T · ln(q10) and `seas_T_amp` was held. Its held-`q10` cells price that seasonal ridge
>   (98.7 % of their cost), not the GCB row. Its output is to be quarantined when it lands.
> - **Repaired** (`calibration/diag_p3_powered_step.R`: a Newton step from the mode, evaluated, at power 0.87–1.00).
>   **P3 with `q10` truly freed moves `q10` by < 0.04 sd (1.060 → 1.061).** `npp_tsens` goes +0.0089 → +0.0063 and
>   the net climate effect +0.12 → +0.07 GtC/yr, still the wrong sign. SSP5-8.5 2300: +3.3 ppm. The objective gains
>   +0.03.
> - **Why:** 96 % of the model's heterotrophic respiration passes through its 2-yr soil pool, which re-equilibrates
>   within years. So `q10` moves the net climate effect only −0.016 GtC/yr per sd (`npp_tsens`: +0.160). A
>   first-principles estimate from the pool split (0.61 per unit ln q10) matches the measured 0.69.
> - **So P3 ≈ P0.** The real choice is P0/P3 (no material change) vs P4 (pin at 0).

> **Status.** Drafted on Marcus's ruling "Revisit the npp_tsens prior" (2026-10-04). It re-opens the 09-30 ruling,
> which made the prior sign-free, N(0, 0.029).
> - Nothing is built and no objective is changed.
> - The numbers come from `calibration/diag_obj16_preview.R` (`outputs/diagnostics/obj16_preview_20261004.{log,rds}`,
>   section G) and the 10-04 (e) run. Both are CONDITIONAL slices at hilda34g.

## 1. Why it is re-opened (CHANGELOG 10-04 e)
- **The land ENSO lag SETS the sign** of `npp_tsens`, carrying 89–92 % of the refit's −0.0079 → +0.0089 /K flip.
  - At lag 0, the GCB land sink pulled the term negative: an ENSO-timing patch, a match by cancellation.
  - With the lag, the pre-1958 ice-core CO₂ and seasonal rows set it positive.
- **The sign is weakly held:**
  - half the flip fits only 0.33–0.42 logpost worse;
  - at either lag ν sits within ~1 sd (≈ 0.008 /K) of zero;
  - **~27 ppm of SSP5-8.5 2300** rides on the sign (1448.6 at hilda34g vs 1476.2 at the control).
- hilda34g's +0.0089 is a GREENING-with-warming term, and a positive term raises post-2100 uptake. The literature
  leans the other way (§2).

## 2. The literature (`notes/lit_2026-09-30_nonco2_land_sink_drivers.md`, with its status codes)
| # | source | quantity | number | comparable to `npp_tsens`? |
|---|---|---|---|---|
| G9 | Meinshausen 2011 (MAGICC6) Table B4, Eq. A21 | σ_NPP in NPP × exp(σ ΔT), global-mean T, fitted to 10 C4MIP models | mean **−0.006**, sd 0.029, median 0.00, range −0.06…+0.04 K⁻¹ | **yes: the same functional form** (the current prior's width is this sd) |
| G5 | Varney 2024 BG 21:2759 §3.3 | CMIP6 γ_NPP (1pctCO2-rad, 10 ESMs) | −29.4 ± 40.1 Pg C/K (2×); **8 of 10 negative** | different units (land C attributable to NPP, per K). My conversion with τ₀ = C/NPP ≈ 33 yr and NPP₀ = 60: **−0.015 ± 0.020 K⁻¹**, NOT a published number |
| G12 | CNit (Table A2) | s in exp(s · ΔT_land) | median −0.14 per K of LAND T | different structure; not used |
| G3 | GCB 2025 ESSD 18:3211 §3.7.2 | net climate effect on S_LAND, 2015–24 (TRENDY S2 − S1) | **−0.8 ± 0.7 GtC/yr** | NPP **and** respiration together: a joint constraint on `npp_tsens` and `q10` |
| G14 / G11 | Mahecha 2010; Hector v3.5.5 | ecosystem Q10; Hector's history fit | 1.4 ± 0.1; q10_rh 1.2 with NO NPP-T term | `q10` at hilda34g is **1.06** (prior z −2.54, strained) |

The lit note's own bottom line (items 6–7): the sign is unresolved; σ_T and q10 are not jointly identifiable from the
historical sink; pin one through the seasonal cycle or IAV, or fit to the GCB net climate effect.

## 3. What the model says now (the preview, section G)
At hilda34g's lag, with `npp_tsens` HELD and the other 7 land-block names re-optimised (all four converged):

| `npp_tsens` (/K) | Δ likelihood | `beta_max` | SSP5-8.5 2300 (ppm) | vvH 2300 | net climate effect on S_LAND, 2015–24 (GtC/yr) |
|---|---|---|---|---|---|
| −0.012 | −2.20 | 2.33 | 1483.8 | 1025.7 | −0.25 |
| −0.006 (the C4MIP mean) | −0.99 | 2.19 | 1472.3 | 1018.3 | −0.15 |
| **0** | **−0.26** | 2.05 | **1462.2** | 1011.5 | −0.04 |
| **+0.0089 (hilda34g)** | 0 | 1.83 | **1448.6** | 1002.2 | **+0.12** |

- **The profile is quadratic** (max residual 0.003 log-units). Without `npp_tsens`'s own prior its optimum is
  **+0.0095 /K, sd 0.0085**. So **zero is 1.1 sd away, and the record cannot fix the sign.**
- **The ridge in one line:** each −0.006 /K of greening is taken up by ~+0.15 in `beta_max` and moves SSP5-8.5 2300 by
  ~+9 to +12 ppm.
- **The net climate effect has the wrong sign at the canonical.** The model's land GAINS 0.12 GtC/yr from 1901–2024
  climate change. GCB 2025's TRENDY estimate is a LOSS of 0.8 ± 0.7 (z +1.31).
  - Even at −0.012 it is −0.25 (z +0.79).
  - The model's `q10` is 1.06 (prior z −2.54; flux towers 1.4, Hector 1.2). That is the other half of this response,
    and it is held here.
- ⚠ CO₂ is interactive in the model and prescribed in TRENDY, so the held-climate run's lower CO₂ feeds back a little.
  The definition is otherwise TRENDY's (climate held at its 1901–20 mean).

## 4. The options, each priced (the preview's analytic modes on the measured profile)
| option | `npp_tsens` mode (/K) | SSP5-8.5 2300 (ppm) | net climate effect (GtC/yr) |
|---|---|---|---|
| P0 sign-free N(0, 0.029) (status quo; reproduces hilda34g) | +0.0087 | 1449 | +0.12 |
| P1 C4MIP mean N(−0.006, 0.029) | +0.0083 | 1450 | +0.11 |
| P2 CMIP6-informed N(−0.015, 0.020) (my conversion) | +0.0058 | 1453 | +0.06 |
| P3 GCB net-climate row (+ P0), `q10` HELD | +0.0066 | 1452 | +0.08 |
| P4 pin at 0 | 0 | 1462 | −0.04 |
- **P0, keep the sign-free N(0, 0.029)** (the 09-30 ruling): the status quo.
- **P1, re-centre on the C4MIP mean, N(−0.006, 0.029):** the literature's own numbers in the model's own functional form.
- **P2, a CMIP6-informed prior, N(−0.015, 0.020):** my conversion of Varney's γ_NPP. Shown for scale; I would not
  recommend a prior built on my own unit conversion.
- **P3, a GCB net-climate-effect ROW** (−0.8 ± 0.7 GtC/yr, 2015–24, TRENDY definition) in the objective, not a prior.
  - It is the identification route the literature note names, and it constrains `npp_tsens` and `q10` TOGETHER.
  - It is an objective change, and the model's value would be computed on TRENDY's definition (climate held at
    1901–20).
- **P4, pin `npp_tsens` at 0** (a ruled pin, like the nine): a term whose sign the record cannot fix is not fitted.

**What it says.**
- **No literature-centred prior moves the sign.** The record's profile (sd 0.0085) is 3.4× narrower than the
  literature's own spread (0.029), so a prior at that width shifts the mode by 0.0005 (P1) to 0.003 (P2), and the
  futures by ≤ 4 ppm.
- A prior that DID decide the sign would have to be several times tighter than the C4MIP spread. The literature does
  not support that (lit note item 6: "the sign is unresolved").
- The GCB row, with `q10` held, pulls only a little (σ 0.7 is wide). Its real target is the JOINT response:
  `npp_tsens` with `q10`, whose strained 1.06 makes the model's land climate-benefiting.

## 5. Recommendation, and what needs ruling
**My recommendation: not P1 or P2.** At the literature's own width they change nothing but every stored logpost.
**Choose between:**
- **P3 with `q10` freed.** It is the identification route the literature note names, and it confronts the wrong-signed
  net climate effect and the strained `q10` together. It needs one more preview first (the land block + `q10`, with the
  row computed inside the objective; ~3× the evaluation cost).
- **P4, the pin at 0.** The simplest honest statement for a teaching model: a term whose sign the record cannot fix is
  not fitted. It costs 0.26 on the likelihood and adds 13.5 ppm to SSP5-8.5 2300.

My lean is P3, previewed first, because it also addresses `q10`.

**UPDATE 10-04 (k), after the preview:** the lean above rested on P3 "also addressing `q10`". It does not.
- With power, the GCB row moves `q10` by 0.04 sd. The seasonal ridge and `seas_T_amp`'s observation prior hold it,
  and the soil structure gives it almost no leverage on the net climate effect.
- P3's whole effect is ~30 % of the way from P0 to P4 on `npp_tsens` (+0.0063 vs +0.0089 / 0), +3.3 ppm.
- **Revised recommendation: decide between P0 and P4 on what the app should SAY:**
  - **P0 (status quo)** keeps a weakly-identified positive greening term (≈ 1 sd from zero) and a net climate effect
    of the wrong sign, disclosed.
  - **P4** fits no term the record cannot sign, at −0.26 likelihood and +13.5 ppm at SSP5-8.5 2300. The net climate
    effect is still ≈ 0 (−0.04), not GCB's −0.8: P4 removes the wrong sign but does not create the right one.
  - P3 is defensible only as documentation (the GCB comparison inside the objective). It moves the futures 3 ppm,
    and every stored logpost would move by its term.
- **The structural point, for the record (not a proposal):** neither option can reach GCB's −0.8 GtC/yr.
  - The model routes 4 % of litter to its slow soil pool, so it has almost no soil carbon that keeps responding to
    warming on decades.
  - That would be a soil-structure question (a decadal pool), larger than objective #16.

**What needs ruling:**
1. Which option (P0–P4), or a combination (e.g. P1 with P3).
2. If it is an objective change (P3, or any prior change, which moves every stored logpost by the prior term): package
   it with the timing-row decision as one objective #16 and one refit (`notes/proposal_2026-10-04_enso_timing_row.md` §6.4).
3. Whether `q10`'s strained value (z −2.54) enters the same decision, since P3 constrains it jointly.
