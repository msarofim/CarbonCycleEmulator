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

## 2. D2 design (after the literature pass, `notes/lit_2026-09-30_nonco2_land_sink_drivers.md`)

### 2a. N deposition: BUILD. ⚠ FORM RULED 2026-09-30 (m): a RETENTION FLUX, not the multiplier below
> **Superseded form.** The multiplier described in this subsection was built (`c0ae37b`) and failed this note's
> own P-D2-2 gate by construction. Its sink tracks d(ndep)/dt: 0.37–0.70 kg C/kg N at the prior centre
> (`diag_ndep_form_efficiency.R`).
>
> **The ruled form** (`65bc714`):
> - F_h = `ndep_ret` × 1e-3 × max(ndep_h, 0) GtC/yr, from the atmosphere into `soil_slow`, at `alpha_photo`.
> - `ndep_ret` is lognormal: centre **3.9 kg C/kg N** (`NDEP_RET_PRIOR_CENTRE`), log-sd **0.67**
>   (`NDEP_RET_PRIOR_LOGSD`).
> - P-D2-2 now reads: `ndep_ret` inside its prior's 2σ AND the implied sink per N inside 0.6–8.7.
>
> The multiplier's screen (`alignment_screen_d2_20260930.*`) is its record. The text below is kept as
> written before the runs.

- **Form.** NPP × (1 + γ_N · ndep_h).
  - ndep_h is anthropogenic deposition onto hemisphere h's LAND, in Tg N/yr above 1750. It is carried
    in the forcing columns `ndep_NH` and `ndep_SH`.
  - It feeds the existing pools through the existing allocation.
  - Precedents: MAGICC-CNit's exp(f1·AD), which is linear at these magnitudes, and the C4MIP ε metric
    (lit N19, N22).
  - The Janssens Rh channel stays out: whole-ecosystem C–N responses already contain it (lit §2a(i)).
- **Prior.** γ_N is lognormal, centre **1.0e-4 per Tg N/yr**, log-sd **0.9**.
  - r = 5.8 kg C of extra NPP per kg N on land: Du & de Vries 2018's 19.4 for forests × the forest
    share 0.30.
  - γ_N = r × 1e-3 / NPP₀ (C, lit §2a(ii)).
  - 2σ reaches CLM4.5's 36.
- **Gate.** The model's implied sink per unit ΔNdep must fall inside 0.6–8.7 kg C/kg N (land mean;
  lit §2a(iv)).
- **Forcing (choice §6.4).** Recommended: the emissions proxy.
  - Deposition ≈ NOx-N + NH₃-N emissions to within 1–6 % (Galloway 2004, Lamarque 2013, Tan 2018).
  - Land fraction 0.60 (0.55–0.65 across Galloway, Kanakidou and Tan). The land fraction is degenerate
    with γ_N, so its uncertainty sits inside the log-sd.
  - NH / SH split 0.83 / 0.17 (C, from Tan 2018 Table 5).
  - It is the only source that covers every scenario the model runs, to 2300.
  - Seam: the SSPs' CMIP6 history is 8.4 Tg N/yr above the CMIP7 history at 2014, so they are
    harmonised at the seam (§6.5).
- **Expected.** A sink of 0.1–0.2 GtC/yr, 7–9 % of S_LAND, falling after mid-century in every scenario.
  NPP rises only 0.3–0.5 %.

### 2b. Climate greening: the literature does NOT support a positive term (choice §6.6)
- **Form, if built.** NPP × exp(σ_T · ΔT), on annual-mean GMST relative to the spinup year. This is
  MAGICC6's per-flux exp(σΔT) and CNit's f_T.
  - The seasonal NEP rides on NPP, so its amplitude scales with the term. No separate seasonal
    temperature path.
- **Prior, if built.** σ_T ~ N(0, 0.03) per K, SIGN-FREE: MAGICC6's C4MIP fits give median 0.00 and SD
  0.029 (Meinshausen 2011, Table B4).
  - The evidence leans negative: CMIP6 γ_NPP is negative in 8 of 10 ESMs (Varney 2024, verified
    verbatim); CNit's median is −0.14 /K; GCB 2025's net climate effect is −0.8 ± 0.7.
- **Role.** Not a historical sink. The record sees σ_T − ln(q10)/10, so σ_T is what could let q10 rise.
- ⚠ A POSITIVE fitted σ_T raises post-2100 uptake, which widens the Koven gap.

### 2c. Recovery from past disturbance: the evidence says NO (choice §6.7)
- **(c-i) A 1750 deficit is contradicted.**
  - Ice-core δ¹³C shows land stable or gaining to ~1700, then releasing (Bauska 2015).
  - GCB's 1750–1850 E_LUC is a 30 ± 20 GtC source.
  - The legacy of pre-industrial clearing is emission.
- **(c-ii) Land-use regrowth is already inside GCB's net E_LUC** (GCB 2025 §2.2.1), so `f_luc_perm`
  < 1 double counts.
  - What remains outside it (natural-disturbance recovery; US fire suppression ~0.04 PgC/yr) is small,
    and its magnitude is uncited.
- **`luc_scale` ≈ 0.86 already acts as a 0.23–0.26 GtC/yr recovery-like sink.**

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

### 4.1b D3 alone: SCORED 2026-09-30 (k). All four PASS in all three arms (smooth, const, smooth + cement)
- The rows gained +11 to +17.
- enh(410) rose +2.1 to +5.3 %; `luc_scale` 0.863 → 0.875–0.891.
- s_ocean 0.11–0.15.
- SSP5-8.5 2300 moved −11 to −14 ppm.
- CONST rails the remainder at 0.

### 4.2b What the MULTIPLIER-form screen scored (09-30 l; the retired form's record)
- **P-D2-1:** PASS in DN and DNT (enh −2.2 / −8.7 %); FAIL with D3 (DNTb +2.4 %).
- **P-D2-2:** PASS, but only because the fit pushed γ to 2–5× its centre: 0.84–2.06 kg C/kg N. At the
  centre the form gives 0.40.
- **P-D2-3:** PASS.
- **P-D2-4:** FAIL in every arm: σ_T ≈ 0 (+0.004 to −0.006 /K), and q10 does not rise.
- **P-D2-5:** PASS.

### 4.2 D2: predictions, updated with the literature magnitudes (§2), before any D2 fit
- **P-D2-1 (a).** enh(410) falls below the control's, by 3–12 %. That is the (a) sink's 7–9 % share of
  S_LAND, bracketed.
  - FAILS if it does not fall.
  - The size is a range, not a gate: the CO₂ record may reassign part of it elsewhere.
- **P-D2-2 (a).** The fitted γ_N lands inside its prior's 2σ, 0.17e-4 to 6e-4 per Tg N/yr, AND the
  implied sink per N lies inside 0.6–8.7 kg C/kg N (the §2a gate).
- **P-D2-3 (a).** Modern NPP rises by less than 1 GtC/yr. (a) does NOT resolve D4.
- **P-D2-4 (b), if built sign-free.** The fitted σ_T is positive and q10 rises. The future then moves
  TOWARD Koven only if the q10 rise outweighs the σ_T gain at high warming.
  - The direction is not predicted: that trade is exactly what the build would measure.
- **P-D2-5 (all).** The post-2100 Koven z (2100–2200) stays above +1.5 with D2 (a) alone. A small sink
  cannot close a gap of this size.

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

**D3**
1. **I(t) treatment:** RAW / SMOOTH (11-yr) / CONST.
   - Recommendation: **SMOOTH.** RAW lets the interannual noise choose the share (64 % of its
     estimate). CONST ignores the imbalance's decline from +0.93 (1960s) to +0.02 (2015–2024) and rails
     the remainder at 0 in the screen.
2. **Cement carbonation** (+0.09 mean, +0.21 recently; the model has no such sink):
   - fold it into the allocated quantity; or
   - leave it out; or
   - net it from the fossil input, which is a forcing change and needs a future path.
   - Recommendation: **fold it in**: +0.67 on the common rows in the screen, and the forcing is untouched.
3. **Constant shares** (recommended) or time-varying.

**D2**

4. **(a) N-deposition forcing:**
   - the emissions proxy (recommended; §2a);
   - the CMIP7 FZJ-CMIP-nitrogen-2-0 gridded deposition for 1850–2022, then the proxy (a download;
     4 of 7 scenarios, to 2100 only);
   - the CMIP6 NCAR-CCMI-2-0 (TRENDY's forcing; 30–45 % below the observation-based 2010s totals).
5. **The SSP seam for the proxy:** ratio-harmonise each SSP to the CMIP7 history at its last shared
   year, converging by 2050 (recommended); or splice without harmonising, which gives an 8 Tg N/yr step.
6. **(b) climate greening:**
   - build it with a sign-free prior 0 ± 0.03 /K (recommended: the ruling's freedom, the literature's
     centre);
   - a hemispheric sign-constrained form (NH ≥ 0, SH ≤ 0): a suggestion with no literature numbers;
   - drop it.
7. **(c) recovery:**
   - do not build it, and record `luc_scale` as the model's existing recovery-like freedom (recommended);
   - a small prescribed decaying sink into wood, prior centre 0 with a half-normal 0.2 GtC/yr (a
     judgement, not a receipt);
   - (c-i) as a labelled sensitivity arm only.
