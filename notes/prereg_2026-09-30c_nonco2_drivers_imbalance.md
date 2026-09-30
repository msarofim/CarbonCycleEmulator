# Pre-registration 2026-09-30 (c): D2, non-CO₂ land-sink drivers, and D3, the imbalance allocation

> **Status.** DRAFT. Written before any D2 code and before any D2/D3 fit.
> - The D3 machinery is built, OFF by default and mutation-tested (`512d8e8`; CHANGELOG 09-30 j).
> - The D3 fixed-vector preview is run (CHANGELOG 09-30 i).
> - The D2 literature pass is `notes/lit_2026-09-30_nonco2_land_sink_drivers.md`.
>
> Every number below carries its source. The choices in §6 are Marcus's.

## 0. The rulings this implements (Marcus, 2026-09-30, verbatim)

> *"2) definitely add non-CO2 contributors to carbon as in item 2. All 3 items seem defensible and
> relevant. 3) For the GCB budget imbalance: the calibration should have freedom to move it where it
> helps the model solve best. Then could the display panel use that calibration solution to assign it
> visually? 4) I still have hope that the NPP 70 vs. 56 might resolve with our fixes, but if it doesn't,
> then we need to keep it as a named tension."*

Standing: the arm-A refit HOLDS until D2 and D3 are built and screened.

## 1. The problem, in numbers

- The CO₂ record fixes the historical total uptake, and the ocean sits on GCB. That leaves the land
  sink fixed too (CHANGELOG 09-30 c, d).
- The model has ONE mechanism that scales with CO₂ to supply it, fertilisation.
  - The fitted β_max is 2.55 with K 868 ppm.
  - Every forward fertilisation response is 1.3–1.9σ above the literature, all on the same side.
  - Koven's post-2100 windows are missed at z +2.3 / +1.6 (09-30 g scorecard).
- Parametric alignment is exhausted (09-30 g, J1–J6 and G1–G3). Every land knob trades against the
  others under the fixed uptake.
- Two structural routes remain:
  - **D2**: supply part of the historical sink with drivers whose FUTURE differs from CO₂'s;
  - **D3**: let the target itself move where GCB's own budget does not close.

## 2. D2 design

*(the forms and priors are pending the literature pass; filled in §2a–2c)*

### 2.0 What is already on disk for an N-deposition forcing (C = computed here, 2026-09-30)
Anthropic plus open-burning N emissions: NOx as NO₂ × 14.007/46.006, plus NH₃ × 14.007/17.031, as ΔN
relative to 1750 (Tg N/yr).
- Sources:
  - van Vuuren CMIP7 v1.1.1: the pinned, sha-checked file `build_vv_scenarios.R` already reads. History
    through 2023, markers diverge from 2024.
  - RCMIP v5.1.0 `ssp585`: CMIP6 history to 2014, extended to 2500.

| series | 1900 | 1950 | 1980 | 2000 | 2014 | 2023 | 2050 | 2100 | 2200 | 2300 |
|---|---|---|---|---|---|---|---|---|---|---|
| CMIP7 history (vV) | 6.2 | 20.7 | 61.0 | 75.6 | 82.9 | 84.3 | | | | |
| RCMIP ssp585 | 6.4 | 21.3 | 63.0 | 76.5 | 91.3 | | 106.2 | 87.5 | 64.4 | 52.8 |
| vV H | | | | | | | 83.4 | 106.5 | 16.2 | 0.4 |
| vV M | | | | | | | 86.1 | 105.1 | 15.7 | 0.4 |
| vV L | | | | | | | 74.0 | 57.7 | 8.0 | 0.6 |
| vV VL | | | | | | | 33.2 | 19.0 | 1.4 | −1.4 |

- ⭐ **N deposition's FUTURE falls in every scenario**: it rises to about mid-century, then declines. It
  is the opposite of CO₂ fertilisation's monotone future, which is D2's purpose.
- ⚠ **Seam:** CMIP6 history is 8.4 Tg N/yr ABOVE CMIP7 at 2014 (91.3 vs 82.9; different CEDS vintages).
  An SSP run spliced onto the CMIP7 history needs a harmonisation choice (§6).
- ⚠ The vV post-2100 extensions ramp emissions to ~0 by 2300: a stylised tail, like their CO₂.
- Not yet applied: the fraction deposited on LAND and the NH/SH split. Both come from the literature
  pass or a deposition dataset.

### 2.0b First-principles magnitudes (C; to be checked against the literature numbers)
- **(a) N deposition.** Take NPP × (1 + x(t)) with x rising roughly linearly 1950→2020.
  - The resulting sink is ≈ (dΔNPP/dt) × τ_eff + ΔNPP × (share reaching the passive pool).
  - With τ_eff ~ 40 yr (wood-dominated) and the passive litter share 0.05, that is ≈ 31 · x(2020) GtC/yr.
  - A 0.3 GtC/yr sink needs x(2020) ≈ 1 %, i.e. ΔNPP ≈ 0.65 GtC/yr.
  - ⇒ (a) cannot move the 70-vs-56 NPP tension; it moves the fertilisation budget.
- **(b) Greening, (1 + γ_T ΔT) on NPP against q10^(ΔT/10) on respiration.**
  - Rh ≈ NPP near equilibrium, so γ_T = ln(q10)/10 cancels the INSTANTANEOUS response: 0.069 /K at
    q10 2, 0.0095 /K at the fitted 1.10.
  - The historical record sees mostly the difference γ_T − ln(q10)/10.
  - ⇒ (b) is what lets q10 rise, and at high warming an exponential respiration beats a linear NPP gain.
    (b) is therefore the lever on Koven's post-2100 windows, not on the historical sink.
  - ⚠ A linear γ_T with no saturation under SSP5-8.5's ~8 K by 2300 would ADD a future sink. The form
    must decide that (§6).

## 3. D3 design: the imbalance allocation (candidate objective #14)

### 3.1 Form (built, `512d8e8`, OFF)
- Targets:
  - `gcb_land_sink`: GCB_land + s_land · I(t);
  - `gcb_ocean_sink`: GCB_ocean + s_ocean · I(t).
- Both rows keep objective #13's σ (0.5 / 0.4 GtC/yr).
- **Shares on the simplex:** s_land, s_ocean ≥ 0 and s_land + s_ocean ≤ 1.
- **The remainder 1 − s_land − s_ocean is "not a sink error".** The model's growth is pinned by the
  CO₂ record, so that remainder can only be carried by `luc_scale`.
  - ⇒ There is **no separate emissions share**: it would be collinear with `luc_scale`.
  - At the alignment control, `luc_scale` 0.863 already carries 37 % of imbalance + cement (09-30 i).
- **Prior: flat on the simplex (Dirichlet(1,1,1)),** which is what "freedom to move it" means.
  - It is built by stick-breaking: `imb_share_land` ~ Beta(1, 2) and `imb_share_ocean_rest` ~ U(0, 1),
    with s_ocean = (1 − s_land) · rest.
  - The map's Jacobian (1 − s_land) cancels Beta(1,2)'s density, so the prior is constant on the
    simplex (tested).
- **Absent shares mean objective #13, bit for bit.** Shares (0, 0) are the same (tested).
- The ENSO ocean-slope row (#13) is untouched; D3 moves only the two LEVEL rows.

### 3.2 What the preview says (fixed vector, no fit; 09-30 i)

| I(t) | s_land | s_ocean | level share of Σ I² | Δll rows at fixed params |
|---|---|---|---|---|
| RAW | 0.26 ± 0.07 | 0.08 ± 0.06 | 0.36 | +8.3 |
| SMOOTH 11-yr | 0.47 ± 0.10 | 0.17 ± 0.08 | 0.79 | +12.9 |
| CONST | 0.65 ± 0.11 | 0.14 ± 0.09 | 1.00 | +17.6 |

(± = σ/√Σ I², the rows' own curvature at fixed parameters.)

### 3.3 The display (D3's question: yes)
- `plot_land_sink_imbalance()` draws GCB_land + s_land · I(t) as **"this calibration's attribution"**,
  replacing today's EXTREME band (all of I to land). One sentence gives the three shares: land, ocean,
  and the remainder carried by the model's land-use emissions.
- `IMB_BAND_NOTE`, `IMB_BAND_SHORT` and `test-imbalance-panel.R`'s wording assertions change with it.
- The wording must say the attribution is the MODEL's, fitted: not GCB's, and not an uncertainty range.
- Draws only after a refit under #14: the shares are a property of a mode, not of the data.

## 4. Pre-registered predictions (written before any D2/D3 fit)

### 4.1 D3 alone
- **P-D3-1.** The rows gain ≥ +8 (the fixed-vector floor) under any treatment.
- **P-D3-2.** ⚠ **D3 alone does NOT lower fertilisation.**
  - Today `gcb_land_sink` pulls the land sink DOWN: in the 09-30 (d) profile it IMPROVED by
    +12.6 / +15.6 as fertilisation was cut.
  - A free s_land releases that pull. β_max, or the enh(410) amplitude, stays within ±5 % of the
    control or RISES, and `luc_scale` moves toward 1.
  - FAILS if the enhancement at 410 ppm falls by more than 5 %.
- **P-D3-3.** s_ocean > 0.05 at the optimum. FAILS if the ocean share rails at 0.
- **P-D3-4.** The SSP5-8.5 2300 CO₂ moves by less than ±20 ppm. D3 is about the target, not the land's
  future.

### 4.2 D2 (per driver; filled with the literature numbers in §2)
- **P-D2-1.** The fertilisation amplitude falls: enh(410 ppm) below the control's 0.339.
- **P-D2-2.** The post-2100 land sink falls toward Koven: z for 2100–2200 below +2.27.
- **P-D2-3.** q10 can rise: the fitted q10 above 1.11.
- **P-D2-4.** Modern NPP: (a) and (b) RAISE it; (c) does not. D4's hope rests on (c) and on P-D2-1.

## 5. The screen (step 4), before the refit
- `diag_alignment_screen.R` gains the D2 labels and the D3 shares, as extra coordinates (like NPP₀ and
  `ra_ratio` in 09-30 g).
- Arms:
  - D3 alone under the ruled treatment;
  - each D2 driver alone;
  - all three D2 drivers together;
  - all three plus D3.
- The scorecard is the acceptance view: pools, NPP, GPP, sinks vs GCB, soil Δ¹⁴C vs Shi, fertilisation
  responses, q10, and the Koven windows.
- ⚠ Structural choices are priced only at a FULL refit (the R2 lesson, 09-30 g).

## 6. Choices for Marcus

*(D3 choices below. The D2 choices are appended after the literature pass.)*

1. **I(t) treatment:** RAW / SMOOTH (11-yr) / CONST.
   - Recommendation: **SMOOTH.** RAW lets the interannual noise choose the share (64 % of its
     estimate). CONST ignores the imbalance's decline from +0.93 (1960s) to +0.02 (2015–2024).
2. **Cement carbonation** (+0.09 mean, +0.21 recently; the model has no such sink):
   - fold it into the allocated quantity (I = imbalance + cement); or
   - leave it out; or
   - net it from the fossil input, which is a forcing change and also needs a future path.
   - Recommendation: **fold it in**. It is carbon the model must place like the imbalance, and it
     keeps the forcing untouched.
3. **Constant shares** (recommended) or time-varying (by epoch).
