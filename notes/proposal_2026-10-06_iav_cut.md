# PROPOSAL 2026-10-06 — calibrate the interannual parameters on the growth record alone (Marcus's split)

> **Status.** Previewed on Marcus's question; **nothing is built and no objective has changed.** Every number below
> comes from committed drivers run on the canonical (`hilda33p`, mode md5 `52540498…`):
> - `calibration/diag_iav_cut_preview.R` → `outputs/diagnostics/iav_cut_preview_20261006_hilda33p.{log,rds,png}`;
> - `diag_iav_kernel_preview.R` (C5), `diag_iav_station_timing.R` (C6), `diag_iav_cut_se.R` (error bars) and
>   `diag_iav_cut_scope.R` (B2 split into its ENSO and volcanic parts).
>
> These are CONDITIONAL slices: every other name stays at the canonical, apart from the blocks B2/B3 re-optimise.
> A real stage-2 refit gives the joint answer.

Marcus, verbatim: *"I still find it odd that there is a pattern in the data that ENSO causes a lagged effect on CO2 and
that we can't somehow make our ENSO parameter do a better job of reproducing that lag. What about having a 12-month
smoothed CO2 growth that is used only for calibrating the ENSO and volcanic aerosol parameters? E.g., the parameters
that only care about interannual variability and not the regular annual cycle or the long term trend which is what all
the other parameters in the model care about."*

## 1. What it is, and why it is not the row declined twice
- **The interannual module** fits the interannual names to the detrended 12-month growth.
  - The names: the land ENSO lag, the land ENSO amplitude, `gamma_diff`, and optionally `w_enso_l2`.
  - The growth: a centred 12-month difference of NOAA MBL global CO₂, 1980–2024, detrended with a natural spline,
    df 5. The difference removes the annual cycle and the spline the trend.
- **The main module** fits every other name to the existing rows, with the interannual names held.
- Statistics calls this a *modular* or *cut* calibration: a module's data inform only that module's names, so a
  suspect module cannot pull them (Liu, Bayarri & Berger 2009, *Bayesian Analysis* 4:119, doi:10.1214/09-BA404;
  Plummer 2015, *Stat. Comput.* 25:37, doi:10.1007/s11222-014-9503-z).
- **It is a different design from the two declined rows** (memory `ccx_growth_objective_declined`). The 09-26 growth
  row and the 10-04 timing row were added to the JOINT objective, where the existing rows outvote them: at its honest
  weight the timing row moved the lag only 2.61 → 2.70. Here the existing rows get no vote on these names.
  - The 09-26 objections were "over-determined" and "very loud". Both are about the joint objective, so they do not
    apply.
  - The third objection, "fights the variability shortfall", becomes the point: it is measured below.

## 2. What it does (part A; real runs at the optimum)
| | canonical | growth module (A1) |
|---|---|---|
| land ENSO lag, months | 2.61 | **5.86** (1σ 4.6–7.2; 2σ 3.1–8.8, monthly n_eff 22.5) |
| land ENSO amplitude | 1 × (0.508 / 0.487) | **× 1.38** |
| `gamma_diff` (fixed today) | 0.25 | **0.56** |
| modelled growth peak after Niño 3.4 (record +5) | +1 | +6 |
| detrended growth r: monthly / annual | 0.59 / 0.64 | **0.71 / 0.77** |
| sd ratio, model / observed: monthly / annual | 0.53 / 0.61 | 0.74 / 0.78 |
| What-if readout's annual miss, ppm/yr | 0.370 | **0.328** (−11.5 %) |
| how much worse the miss gets with ENSO zeroed | 9.6 % | **25.9 %** |

- **The annual estimator agrees.** It gives a lag of 6.2 (1σ 5.4–7.0) and the same amplitudes. On it, the canonical's
  2.6 lies outside 2σ.
- **The error bars on the two amplitudes** (`diag_iav_cut_se.R`; profile likelihood, the other amplitude re-fitted):

  | estimator | n_eff | amplitude (1σ) | `gamma_diff` (1σ) | `gamma_diff` 2σ | distance from canonical: amplitude / `gamma_diff` |
  |---|---|---|---|---|---|
  | monthly | 22.5 | ×1.38 (1.09–1.67) | 0.56 (0.34–0.78) | 0.11–1.02 | 1.3σ / 1.4σ |
  | annual | 44.8 | ×1.41 (1.22–1.59) | 0.61 (0.49–0.73) | 0.36–0.86 | 2.1σ / 2.8σ |

  - **The lag is the robust part:** the canonical's 2.6 lies outside 2σ on both estimators.
  - **The two amplitudes are only 1.3–2.8σ from the canonical**, depending on the estimator's n_eff.
- **A2, with the ocean limb freed.**
  - On the growth alone the ocean limb runs away: `w_enso_l2` goes to 55–113 and the land amplitude to 2.4–4×. Growth
    sees only land plus ocean.
  - With `gcb_ocean_enso_slope` in the module, the limb stays at 15.1 (canonical 13.2) and the rest matches A1.
  - **So if the ocean limb joins the module, its own row must join with it.**

## 3. What it costs the main objective (part B)
- **B1, unrefitted: −80.2 in likelihood.** Step by step:
  - the lag 2.61 → 5.86: −22.6, of which the seasonal rows −12.4 and `gcb_land_sink` −9.6;
  - the amplitude ×1.38: −23.6, of which `gcb_land_sink` −24.9;
  - `gamma_diff` 0.25 → 0.56: −34.0, of which `gcb_land_sink` −12.1, the two ice cores −12.2, MLO's level −6.3 and
    SPO's δ¹³C level −3.6.
- **`gcb_land_sink` pays −46.7 in all**, in the big years:
  - 2010 −4.2;
  - 1992 −4.1 (Pinatubo, `gamma_diff`);
  - 1966 −3.9; 2016 −3.4; 2023 −3.1;
  - 1963 −2.8 (Agung); 1998 −2.4.
- **A refit of the other names recovers little:**
  - B2 re-optimises the five other land names and lands at −71.9;
  - B3 adds the six seasonal-cycle names and `tau_ex`, and lands at −72.1 (both pass the slope gate);
  - what comes back is the ice core and level rows (`co2_icecore` −5.5 → −0.8). The land sink (−48.0) and the
    seasonal rows (MLO −5.8, SPO −5.3) do not move.
- ⚠ **B2 raises `beta_max` and `fert_k` by ~14 %** (2.08 → 2.36; 752 → 855). That moves SSP5-8.5 CO₂ in 2300 by
  −30 ppm (1461.5 → 1431.4) and vvH by −14. **Its owner is `gamma_diff`**, measured by `diag_iav_cut_scope.R`, which splits B2 in two:

  | arm | after B2 | `beta_max` / `fert_k` | SSP5-8.5 2300 |
  |---|---|---|---|
  | ENSO only (A1's lag and amplitude, `gamma_diff` 0.25) | −45.2 | +2.7 % / +1.4 % | −8.8 ppm |
  | volcanic only (`gamma_diff` 0.56) | −33.3 | +11 % / +13 % | −22.4 ppm |

  - The volcanic arm also leaves the two ice cores and both CO₂ level rows paying −15 after the re-optimisation.
  - **So `gamma_diff` is not an interannual-only name.** Its AOD forcing has a positive mean (an eruption only ever
    adds), so raising it shifts long-term land carbon, and the fertilisation pair and the futures move with it.
  - The ENSO names nearly are interannual-only, because the index is demeaned (Ruling A).
- **The app shows little of the land-sink cost.** Its land-sink panel smooths GCB and the model over 11 years
  (`APP_LUC_SMOOTH_YR`), so the cost shows only in the thin annual line.

## 4. Why the joint fit holds the lag at 2.6: three things that measure DIFFERENT objects
1. **GCB's land-sink row scores a DGVM product whose ENSO response is earlier and weaker than the atmosphere's**
   (C4, data only; GCB 2025's own budget, 1959–2024).
   - The land sink the atmosphere implies is fossil + LUC − growth − ocean − cement. It peaks 5 months after Niño 3.4
     (8 months in 1980–2024), with sd 0.92 GtC/yr.
   - GCB's S_LAND peaks at 3 months (4), with sd 0.56 GtC/yr.
   - The difference is GCB's own imbalance, which is anti-correlated with ENSO: r −0.32, or −0.40 in 1980–2024.
   - The row's target smooths the imbalance over 11 years (ruled 09-30), so at interannual frequencies the row scores
     S_LAND's own timing.
   - Caveat: the row scores the ensemble MEAN, whose year-to-year signal is damped by averaging the DGVMs.
2. **MLO sees ENSO about 3 months before the global mean** (C6, data only). Each observed growth record peaks at:

   | record | peak, months after Niño 3.4 |
   |---|---|
   | MLO, Scripps / NOAA | **+2 / +3** |
   | SPO, Scripps / NOAA | +5 / +5 |
   | global MBL | +5 |

   - It is the whole cross-correlation curve that shifts, not just its peak.
   - The model's NH box, which the MLO rows score, responds on the global mean's timing (+1 at the canonical, +5 at
     A1). A two-box model cannot make one station lead the global mean.
3. **The seasonal rows carry real information, but about something else** (C2).
   - Each row's lag preference splits exactly into information minus visibility (gated to 9e-14).
   - Information peaks at short lags; visibility actually favours long lags.
   - The information comes from the big years (1983, 2016, 1992, 1998, 2011 carry 45 % of what lag 5 costs, at the canonical amplitudes).
   - For MLO, point 2 explains it. **For SPO it is unexplained:** SPO's own growth peaks on the global mean's timing.
4. **A response SHAPE does not reconcile them** (C5).
   - With an exponential memory on the land term (onset L, memory τ 1–9 months), the growth's best is still τ = 0,
     L = 6, and the seasonal rows' best is still τ = 0, L = 3.
   - Memory makes both worse.
5. **Without the seasonal rows** (C1), the joint optimum hardly moves: 2.65 months, against 2.48 with them on 10-06's
   spline.
   - What changes is the profile's depth. Lag 5 costs −4.0 instead of −12.0.
   - The rows still against lag 5 are `gcb_land_sink` −2.0, the two ice cores −1.5 and `gcb_ocean_enso_slope` −0.6.
   - The land amplitude also falls as the lag lengthens (0.42 / 0.38 at lag 5).
   - **So no existing row sees the global growth timing.** The seasonal rows set how firmly the lag is held, not where.

## 5. Decisions (each is yours; each changes the answer)
1. **Build it at all?** Or keep the joint fit, and rewrite card 4 around what is now measured: the 2.6 months is a
   compromise between the global atmosphere (~6), GCB's DGVMs (~3–4) and Mauna Loa (~2–3).
   - **My recommendation: build it, for the land ENSO names at least.**
     - The lag is the robust finding: the canonical is outside 2σ on both estimators.
     - It is what the app teaches: ENSO's share of the What-if readout rises 9.6 % → 25.9 %.
     - The rows that resist it measure objects the two-box model cannot represent jointly with the global mean.
   - The price is real and mostly permanent: about −72 in likelihood after a partial refit. The scorecard's land-sink
     and seasonal rows get worse; the app's smoothed panels barely show it.
2. **The scope.** Options: the land ENSO lag and amplitude only (A0), plus `gamma_diff` (A1), or plus the ocean limb
   with its own row (A2). **Recommended: A0, the land ENSO lag and amplitude only, with `gamma_diff` held at 0.25 for now.**
   - The ENSO part is what the growth record pins, and it barely leaks into the trend names.
   - `gamma_diff` fails the split's own premise: it is not interannual-only.
     - The growth's 0.56 is only 1.4σ (monthly) to 2.8σ (annual) from 0.25.
     - Moving it drags the fertilisation pair and the 2300 futures.
     - The canonical's objective prefers 0 (+1.74).
   - It deserves its own decision. One candidate: an AOD term made zero-mean, as Ruling A made the ENSO index.
3. **The ocean limb: keep it in the main module** (recommended). A2 shows the module would leave it near 15
   (canonical 13.2), so moving it gains nothing and makes `gcb_ocean_enso_slope` a module row.
4. **The estimator.** Monthly gives the timing resolution, and the 10-02/10-04/10-06 diagnostics use it. Annual is the
   app's readout and gives tighter bars. Both give a lag of 5.9–6.2.
   - **Recommended: monthly, with annual as a check.**
5. **The land-sink row's year-by-year part.** Under the split's own logic the main names care about the trend. Scoring
   `gcb_land_sink` on its 11-yr smoothed part (the window its imbalance already uses) would stop the main module
   fighting the module over a DGVM ensemble mean's ENSO timing.
   - It is NOT priced here, and the σ of a smoothed target is itself a choice.
   - **Recommended: price it before deciding**, as a cheap preview like this one.
6. **Where stage 2 runs.** Torch, or the Mac's CPU clock (13–16 h). This is decided at launch.

## 6. Cost, if built
- **Stage 1**, minutes on the Mac. A fitter for the module's objective: superposition plus a direct polish, as in this
  preview.
- **`gamma_diff` as a fitted name**, if it joins the module:
  - a parameter-table entry and its prior;
  - the label/gate machinery (absent = bit-identical);
  - parity in both cores is already there.
- **Stage 2**: a 24-start refit of the other names with the module's names pinned (`CCX_MS_PIN` carries pins). About
  13–16 h on the Mac's CPU clock, or Torch.
- **Uncertainty**: the cut posterior, i.e. stage 1's spread propagated into stage 2, for the app's ribbons.
- **Then**: tests (absent = bit-identical, mutations), a restamp, the scorecard, and the app's copy: card 4's timing
  disclosure, the What-if numbers, and the wobble shares.
