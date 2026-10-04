# ASSESSMENT — CarbonCycleEmulator at `hilda34g`, release BETA v1.0 CarboTope (2026-10-04) — ⚠ DRAFT EVIDENCE, NOT A VERDICT

**Marcus (2026-10-04), on the 10-04 handoff's open items: "hilda34g assessment"** (item 6). This note follows
`notes/assessment_2026-10-01_hilda33d_DRAFT.md`, with the same sections. It gives the model as it stands, judged
against the 09-03 standard, with every remaining flaw named and classed.
**§5, the VERDICT, and §7, the acts, are Marcus's and are left as placeholders.**

**Sources.**
- Unless cited otherwise, every number comes from the scorecard with hilda34g as the canonical,
  `outputs/diagnostics/whole_model_scorecard_20261004_hilda34g.{log,rds}`, at `cb23e52`. Its "+dirty" stamp is two
  untracked preview files that the scorecard does not read.
- Modern NPP: `outputs/diagnostics/d4_readout_20261004.{log,csv}`.
- The objective is **#15**. Every logpost is comparable only within it, and **arms are compared on LIKELIHOOD over its
  27 rows**: hilda34g's logpost carries the lag's flat prior and logit Jacobian, which no lag-0 mode has.

---

## 0. The standard (unchanged; 09-21 §0)
A pedagogical model, not an emulator: **the product is the CHAIN**. Constraining the model with seasonal and isotopic
data should make long perturbation lifetimes emerge. A defect BLOCKS release only if it breaks a link. A benchmark
miss with the right mechanism is a research question. Joos 2013 never scores the model (gates 12 and L are
comparisons).

## 1. What changed since 10-01 (`hilda33d`, objective #14)
- **Objective #15** (10-02 bb–cc, on Marcus's rulings):
  - the land ENSO lag `lag_enso_land` (W1: DESIGN's never-built `L_MEI`), fitted under the label `hilda_csl3v0kaidgbe`;
  - the Law Dome ice-core δ¹³C row (W2);
  - ice-core CO₂ cut to pre-1958 (W3);
  - the `k_w` and `tau_ex` priors cited and moved (W5);
  - gates 5, 6, 7, 11 and P7 repaired before scoring (W4).
- **The canonical is `hilda34g`**, the #15 lag arm, adopted 10-03 (h).
  - **The lag is 2.64 ± 0.39 months.** It earns its parameter: +14.92 on likelihood over the lag-0 control refit,
    ΔAIC −27.8.
  - Likelihood **−1143.2508** on 27 rows, logpost −1182.991369. 34 names are fitted and the same nine held.
- **ENSO now HELPS the app's What-if fit.** Switching it off is 11 % worse, against +0.9 % at hilda33d.
  - The model's growth now peaks 1 month after Niño 3.4 (it was −2; observed +5).
  - The What-if blurb reads "about 40 % of the wobble" (ruled).
- **The release moved:** "BETA v1.0 CarboTope" is cut on hilda34g ("Move v1.0 to hilda34g").
- **The substep controller is fixed** (10-03 j, 10-04 a; merged 10-04 d).
  - Near the P8 wall the RK4 count under-resolved the SH winter mixed layer, and the objective there was integrator
    artefact.
  - No registered mode moves (all at 4 substeps).
- **The greening sign was tested** (10-04 e). The lag SETS the sign of `npp_tsens` (§4.3).

## 2. The gates at `hilda34g`
| gate | reads | verdict | class |
|---|---|---|---|
| D | hemispheric air–sea δ¹³C disequilibrium asymmetry +0.090 vs the bottles' +0.286 ± 0.029, z −6.74 | FAIL | structural (09-21 §1, unchanged) |
| GL / H | the MLO−SPO δ¹³C gradient 1.95× observed (−0.1304 vs −0.0668), z −7.15; R_co2 0.874; contrast z +12.02 | FAIL | structural (09-21 §1) |
| V | interannual sd 0.548 vs 0.933 ± 0.084, **0.59×**, z −4.60 | FAIL | structural (a FAIL is not a blocker, Marcus); the lag fixed the TIMING, not this amplitude |
| 5 | bomb ¹⁴C: SH peak height (`sh_v`) z +10.58, NH e-folding z −7.32; both orderings ok | FAIL | repaired 10-02 (W4); fails at every registered mode, as ruled |
| the AIC gate | the canonical vs the seas_ml-0 control (`hilda31pe`) on the comparable rows | PASS in the suite at `e2f611b` | accounting. On the scorecard's shared rows (the two moved GCB rows excluded) the canonical leads by **+32.31** at 34 vs 31 free names |
| G | ocean anthropogenic-C inventory: se 18.6, z −0.024 (inventory +1.95 %) | PASS | — |
| Q | global air–sea δ¹³C disequilibrium +0.560 vs Quay 0.60 ± 0.10, n_sd 0.40 | PASS | — |
| 7 | 2010s sinks: ocean 3.14 (z −0.26), land 3.06 (z +0.86) GtC/yr | PASS | — |
| S | SPO seasonal ocean limb 0.210 ppm at month 8.50, in [7.41, 10.41] | PASS | — |
| 6 | MLO seasonal-amplitude growth 1960s → 2010s: +14.42 % vs +15.57 % (se 3.44 pp), z −0.34 | PASS | — |
| P7 | the seasonal mixed layer is not a vertical-gradient lever (0.08× its bound) | PASS | — |
| 11 | 21 series screened; no flags | — | screen |

**The free parent.** As for hilda33d, hilda34g has none. The pins' price under #15 is not measured.

## 3. The chain, link by link
1. **Seasonal cycle.** GATE S passes (0.210 ppm at month 8.50), and GATE 6 passes: the amplitude GROWTH is now
   within 0.34 se of the record. `sst_seas_amp_*` stays a named shim (§6).
2. **Isotopes.** The bomb curve, the deep Δ¹⁴C profile, the Suess decline and the ocean's ¹³C gradient (P7 PASS) hold.
   The isotopic reds are D and GL (¹³C hemispheric structure), plus gate 5's repaired bomb-shape statistics.
3. **The sinks and their variability.** GATE 7 PASSES.
   - The ENSO ocean slope is **0.86× GCB** (+0.0988 ± 0.0426 vs +0.1153 ± 0.0246). It is carried by the layer-3 limb
     at 12.93 Sv per index unit; the solubility path alone is still wrong-signed (−0.183).
   - The land ENSO term arrives 2.64 months after the index. That is set by GCB's DGVM-based land sink and the SPO
     seasonal rows; the atmosphere's growth timing would want ~5 (§4.2).
   - GATE V FAILS at 0.59×.
4. **What emerges** (a comparison, not a gate):
   - IRF(20 / 100 / 300) **0.528 / 0.374 / 0.280** against Joos 2013's 0.596 / 0.409 / 0.322. Still faster than the
     multi-model mean. The gap at 100 yr is 0.035 (hilda33d 0.049; hilda29l 0.121).
   - The 1000-yr partition is **land 15 / ocean 62 / air 23 %** against Joos's 16 ± 7 / 59 ± 6 / 25 ± 4.5 (1 s.d.),
     z **−0.08 / +0.50 / −0.54**.
   - The pulse box reads **about 1.4 °C per 1000 GtC** (ruled: "about" = within 0.1) at +20 / 50 / 100 / 200 yr:
     1.46 / 1.39 / 1.36 / 1.40 (`pulse_vs_tcre_20261003`). The spread across pulse sizes is 2.7 %.

## 4. Named tensions and open quantitative statements
1. **D4, modern NPP:** **66.31 GtC/yr, z +1.32** against 56.06 ± 7.75 (exclusive, as ruled; hilda33d 67.67, z +1.50).
   Beside it, +0.68 GtC/yr is retained via N deposition (gross: `ndep_ret` 13.94 kg C/kg N × 48.9 Tg N/yr). It stays a
   named tension.
2. **The lag vs the atmosphere's timing** (the handoff's item 2). The rows that set the lag want ~2.6 months; the
   observed growth wants ~5.
   - A lag of 5 months, with the land block re-fitted, costs 12.2 log-units and moves the growth peak to +4.
   - It raises the correlation with observed growth 0.57 → 0.67 and moves SSP5-8.5 2300 by +7 ppm (10-04 e, D).
   - **Marcus: "Draft a timing-row proposal"** (in progress, `notes/proposal_2026-10-04_enso_timing_row.md`).
3. **The greening sign is weakly held** (10-04 e).
   - At lag 0, the GCB land sink pulled `npp_tsens` negative: an ENSO-timing patch. The lag removed that pull, and
     the ice-core CO₂ and seasonal rows set the term positive (+0.0089 /K).
   - Half the flip fits only 0.3–0.4 log-units worse, and ~27 ppm of SSP5-8.5 2300 rides on the sign.
   - The literature leans negative (`R/constants.R` `NPP_TSENS_PRIOR_SD`).
   - **Marcus: "Revisit the npp_tsens prior"** (in progress).
4. **`k_w` sits at ~1900 m/yr against Naegler's 1446.** It is a balance between the hemispheres' box rows (memory
   `ccx_kw_hemispheric_balance`). **The price arm is running** (10-04 g): a 24-start refit with `k_w` held at 1446,
   read on likelihood.
5. **Uncertainty.** The app shows no bands. The held Laplace evidence is pinned to hilda33d, where it was built, and
   the app refuses it at hilda34g. MCMC stage 1 (at hilda33d) found the Laplace band ~2× too wide; that arc is closed
   (10-02 u).
6. **Strained priors (|z| > 2):** `q10` −2.54, `kz_deep_frac` −2.75, `pump_hs_gcm2` +2.13, **`rep_dC` +4.17**. The last is
   the named shim the ice-CO₂ cut freed to take up the station offset (10-03 g).

## 5. VERDICT — [Marcus]
> *Placeholder.* The 10-01 question was whether this is a product-ready version despite the remaining flaws. The
> evidence above is what changed under it.

## 6. What "final" would NOT mean — the items carried OUT (re-checked 10-04)
1. **The σ audit's three objective items** are unchanged and unruled:
   - `gcb_ocean_sink`'s 0.4 GtC/yr uninflated σ;
   - the `excess_c14_ocean` target set;
   - `CCX_ICE_DISCREPANCY`.
2. **The stand-ins:** the 09-16 review's five, over seven names (card 7). At hilda34g three are HELD at 0
   (`ent_seas_amp_SH` and the ocean ENSO pair), as at hilda33d.
3. **Eleven constants are still `provisional`** (11 of the 74 entries of `CCX_CONSTANTS`, 6 of them retired; `ccx_check_constants()`), the same eleven as 10-01:
   `OCEAN_DEPTH`, `ALK_SURFACE`, `ALPHA_PHOTO_EPS`, `PUMP_EPS13_ORG/CARB`, `NPP_GLOBAL_PI`, `NPP_FRAC_NH_ANCHOR_1750`,
   `ALPHA_AS_FCO3`, `ALPHA_AS_DOWN/UP_LEGACY`, `ENT_SEAS_BAND_AREA_FRAC`.
4. **The 10-01c review §C items** are still unruled, as listed in the 10-01 draft §6.4.
5. **New since 10-01:**
   - the timing row and the greening prior (§4.2–4.3; both are objective changes, so a refit);
   - extending the substep fix's held-K rule to `ccx_tr_box_eigbound()` (no registered mode would move; an objective
     change for tr-box structures).

## 7. What the freeze would BE (the acts) — [Marcus]
- **The model:** canonical `hilda34g`
  (`calibration/output/refit_20261003_hilda34g_obj15_hilda_csl3v0kaidgbe/mode_fit_pumpN.rds`, via `ccx_mode_file()`).
  - 34 fitted names and nine held.
  - Likelihood −1143.2508 on 27 rows, logpost −1182.991369.
  - Hessian PD (cond 1.6e6). `h_ml` is on its known ridge.
- **The objective:** #15.
- **The suite:**
  - at `e2f611b` (the adoption's ledger): **6030 passed, 0 failed, 3 skipped, 0 errors**;
  - at `a7eab97` (the substep fix, whose code `main` carries since `11dda49`): **6039 / 0 / 3 / 0**.
- **A version tag?** [Marcus.] `v1.0-hilda29l` marks the 09-22 freeze. The app's release name, BETA v1.0
  CarboTope, now runs on hilda34g.
- **The product:**
  - the app runs the canonical live, with no bands (held);
  - the Known-issues tab shows cards 1–7;
  - README and DEPLOY.md name the release.

## 8. What would re-open it
- the `k_w` price (running);
- objective #16, if Marcus rules the timing row and/or a new greening prior (each needs a refit);
- a ruling on §6.1;
- an interhemispheric deep exchange (declined 09-23).
