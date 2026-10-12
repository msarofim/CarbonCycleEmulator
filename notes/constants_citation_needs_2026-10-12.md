# Constants citation worklist — 2026-10-12

- **Ruling it serves:** Marcus, "Cite before beta". This file lists what each value needs. Marcus supplies or approves the sources.
- **Compiled read-only.** No value, code, test or data file was changed. Nothing is committed.
- **Commit read:** `1b16747` (HEAD of `main`).
- **Canonical:** `hilda29e`, via `ccx_mode_file()` →
  `calibration/output/refit_20261008_hilda29e_obj18p2_hilda_csl3v0kaidgbemwt/mode_fit_pumpN.rds`.
  - Structure `hilda_csl3v0kaidgbemwt` (built on `hilda_c`), `seas_ml` 1, `pump_field` "solved", spinup "periodic".
  - 29 fitted names plus 14 pins. `ent_seas_amp_SH` is **pinned at 0**.
- **Registry:** `R/constants.R`. CLAUDE.md and DESIGN §8 say `data-raw/constants.R`; that is stale.
- **Provisional ledger:** `tests/testthat/test-constants.R:112-117`. It holds 11 names: `OCEAN_DEPTH`, `ALPHA_PHOTO_EPS`, `ALK_SURFACE`, `PUMP_EPS13_ORG`, `PUMP_EPS13_CARB`, `NPP_GLOBAL_PI`, `NPP_FRAC_NH_ANCHOR_1750`, `ALPHA_AS_FCO3`, `ALPHA_AS_DOWN_LEGACY`, `ALPHA_AS_UP_LEGACY`, `ENT_SEAS_BAND_AREA_FRAC`.

**How "live" was decided.**
- I loaded the canonical's full run list with `ccx_overlay_par(ccx_mode_base(md), md$par_mode)` and read every consumer of each constant against that list.
- A pinned name is removed from `CCX_PARAM_TABLE` by `ccx_apply_pins()` (`R/calibrate.R:1198-1225`). So its prior is **not** in the objective.
- "In objective" means a changed value moves the fitted mode. That forces a **refit**, a restamp of the stored logposts and a new MCMC band. It is the same class of decision as the review's §1 IntCal σ.

**How sources were searched.**
- All 44 PDFs under `~/Documents/2026/ClaudeDocs/Papers/` were text-extracted (`pdftotext -layout`) and grepped by keyword.
- Page numbers are **PDF pages**, with the journal page given where it is printed.
- The `.docx` files there were not searched; by filename they are SC-GHG manuscripts.
- Also searched: `data/`, `data-raw/downloads/` (and its `MANIFEST.csv`), `calibration/output/alk_gradient/`, `CHANGELOG.md` and `DESIGN.md` (grep only), and `notes/lit_*`.

**Conventions in this file.**
- Paper content is given as values with a table, row and page locator, and as paraphrase. Repository source strings are quoted verbatim.
- Quay 2003 Table 3 was rendered to an image to confirm the minus signs, because text extraction drops them.
- **"My arithmetic"** marks a number I computed. It is a check, never a proposed value.

---

## Summary

| # | Name | Value in code | Live at hilda29e? | In fitted objective? | On-disk candidate? | Candidate differs from code? |
|---|---|---|---|---|---|---|
| 1 | `PUMP_EPS13_ORG` | −20 ‰ | yes | **yes** | none | — |
| 2 | `PUMP_EPS13_CARB` | +1 ‰ | yes | **yes** | Zhang 1995 p7 (secondary, and vs CO₂ gas); Dentith reply (a model choice, α = 1) | not like-for-like |
| 3 | `ALK_SURFACE` | 2300 µmol/kg | yes | **yes** | GLODAP 0–100 m vw 2303.4 (diag output); `obs_tr_box` 2299 (tropics); Quay 2325 (a model setting) | **yes**, +0.15 % → refit if adopted |
| 4 | `ALPHA_AS_FCO3` | 0.082 | yes | **yes** | Zhang 1995 p5: 7–13 % | no |
| 5 | `OCEAN_DEPTH` | 3700 m | yes | **yes** | none on disk | (the registry's own off-disk source gives 3690) |
| 6 | `NPP_GLOBAL_PI` | 60 GtC/yr | yes | **yes** | Bastos 2016 T4: 54 (1700, a model setting); Naegler 2006: 60 (a model setting); MOD17 52.7 (modern) | **yes** (Bastos 54) → refit if adopted |
| 7 | `NPP_FRAC_NH_ANCHOR_1750` | 0.5986 | yes (prior centre) | **yes** | `obs_npp_hemispheric.rds` 0.5942 (its input) | n/a (model-derived by design) |
| 8 | `ENT_SEAS_BAND_AREA_FRAC` | 0.369 | **no** (pin 0) | no | SOM-FFN mask via `diag_so_pco2_phase.R` | not recomputed |
| 9 | `ALPHA_AS_DOWN_LEGACY` | −2 ‰ | **no** | no | Zhang 1995 kinetic −0.81 / −0.95 | yes (already documented); no refit |
| 10 | `ALPHA_AS_UP_LEGACY` | −10 ‰ | **no** | no | Quay 2003 T3: −10.9 ± 0.3 | yes; no refit |
| 11 | `ALPHA_PHOTO_EPS` (registry) | 18 ‰ | **no** | no | Quay 2003 T3: −17 ± 5 | yes (−1) |
| 12 | `CCX_ALPHA_PHOTO_EPS_BIOSPHERE` | 15.6 ‰ | yes | **yes** | Quay 2003 T3: −17 ± 5 | centre differs by 1.4, inside its ±5 → refit if adopted |
| 13 | obliquity | −23.44° | yes | **yes** | none | — |
| 14 | declination phase offset | +10 days | yes | **yes** | none | — |
| 15 | `CCX_SEAS_PHI_EFF` | NH 75°, SH −30° | yes | **yes** | `obs_npp_seasonal_shape.rds` (other estimators); the CHANGELOG argmin record | not like-for-like |
| 16 | `CCX_SEAS_T_LAG` | 2.0 mo | yes | **yes** | none (air temperature only, the wrong quantity) | — |
| 17 | `CCX_SST_SEAS_LAG` | 1.32 mo | yes | **yes** | `obs_seasonal_clim.rds`: NH 1.325; the SH row implies 1.536 (my arithmetic) | **SH yes** → refit if a per-hemisphere lag is ruled |
| 18 | `CCX_ENT_SEAS_PEAK_MO` | 7.50 | **no** (pin 0) | no | `obs_so_pco2_seas_amp.rds` 7.496 | no |
| 19 | `FORC_BOMB_NH_SHARE` | 0.90 | yes | **yes** | none direct (Hua zonal data would need a model inversion) | — |
| 20 | `FORC_NUC_NH_SHARE` | 0.95 | yes | **yes** | `nuclear14c/*.csv` → 0.993 pooled (my aggregation) | **yes** → refit if adopted |
| 21 | `P_canon` production | 2.04 atoms cm⁻² s⁻¹ | diagnostic only | no | Naegler 2006 p5: 0.48–0.55 kmol/yr (a total) | no (0.545 kmol/yr is inside) |
| 22 | Earth area in `P_canon`, plus re-typed `.SEC_PER_YR` / `.AVOGADRO` | 5.1e14 m² | diagnostic only | no | none | — |
| 23 | `CCX_BOMB_REF` and the prior-centre literal | 102 kmol | yes; `CCX_BOMB_REF` cancels | the **prior-centre literal: yes** | Naegler 2006 p1/p8: 99.3–104.9 | no (midpoint 102.1) |
| 24 | `JOOS_PPM_PER` | 2.123 GtC/ppm | app card and diagnostics | no | Joos 2013 p6: 2.123 | no |
| 25 | `.ENT_PCO2_REF` | 370 µatm | **no** | no | `obs_tr_box` global 367.3 | yes (scope mismatch); no refit |
| 26 | `.ENT_REVELLE` | 13 | **no** | no | Quay 2003 T3: 10.5 ± 1 (global) | yes (scope mismatch); no refit |
| 27 | `.ENT_DIC_SURF` | 2150 µmol/kg | **no** | no | `obs_glodap_deep` 2040; `obs_hs_surface` 2163; Quay 2.1 mol m⁻³ | yes (scope mismatch); no refit |
| 28 | `bomb_total` prior log-sd | 0.10 | yes | **yes** | Naegler range: a log half-span of 0.027 | yes if the span is read as a σ → refit (a ruling) |
| 29 | `FORC_FOSS_NH_SHARE` | 0.9201 | yes | **yes** | `seasonality_fossil.csv` reproduces it | no |
| 30 | `SALINITY_REF` *(added)* | 34.7 | yes | **yes** | GLODAPv2.2023 master file (not computed) | not computed |
| 31 | `LIK_REP_SOURCE_D13C` *(added)* | −26.5 ‰ | yes | **yes** | Quay T3: −25 / −28.1; Bastos T4: −25 and −24…−28 | no (midpoint −26.55) |

**Counts.**
- **31 items.**
- **20 are in the fitted objective:** rows 1–7, 12–17, 19, 20, 23, 28–31.
- **1 is live in the app only** (row 24). **2 are diagnostic only** (rows 21–22). **8 are not live at hilda29e:** rows 8–11, 18 and 25–27.
- **24 have an on-disk candidate.**
- **12 have a candidate whose value differs from the code:** rows 3, 6, 9–12, 17, 20 and 25–28. **6 of those are in the objective:** rows 3, 6, 12, 17, 20 and 28.
- **No candidate anywhere on disk (7):** rows 1, 5, 13, 14, 16, 19, 22.

---

## 1. `PUMP_EPS13_ORG` = −20 ‰

1. **Where.** `R/constants.R:328-333`. Read at `R/model.R:3142, 3148, 3155` (the LS pump's organic legs) and `R/model.R:3375` (the HS pump). Passed to C++ at `R/cpp.R:96`.
2. **Live:** yes (`pump_mode` "N", solved field, `pump_hs_gcm2` fitted at 85.3). **In objective:** yes, through every δ¹³C row including `ocean_grad_d13c` and the δ¹³C level rows. A change means a refit.
3. **Controls:** the δ¹³C of organic matter exported by the biological pump, relative to the surface DIC it is fixed from.
4. **Source now:** "Photosynthetic fractionation of marine organic matter relative to the DIC it is fixed from, ~20-22 permil. WORKING VALUE, recollected, NEEDS a cited source." **Status: provisional, recollected (no source).**
5. **A citation must give:**
   - an export-weighted (or global-mean) εp, i.e. δ¹³C(POC) − δ¹³C(DIC), in ‰, with its spread, from a paper with table and page;
   - if the source states εp relative to CO₂(aq), the conversion to a DIC basis and the source of that conversion.
6. **On disk:** nothing gives a value.
   - Quay et al. 2003 (GBC 17(1):1004) only names the term: symbol αob, "fractionation during marine photosynthesis", PDF p3 (journal 4-3). Its Table 3 gives no value for it.
   - Zhang et al. 1995 (GCA 59:107, abstract, PDF p1) gives the species fractionations a CO₂(aq)→DIC conversion would need.
   - Prior discussion:
     - the `test-constants.R` ledger note (2026-08-16);
     - CHANGELOG 09-21 h (line ~9124): "no source that pins the working value";
     - `notes/assessment_2026-09-21_product_ready.md` item 3;
     - DESIGN.md:692 lists "all ¹³C fractionation constants" as [VERIFY-class].
7. **Value check:** no candidate.

## 2. `PUMP_EPS13_CARB` = +1 ‰

1. **Where.** `R/constants.R:335-342`. Read at `R/model.R:3145, 3151, 3158, 3378` and `R/cpp.R:97`.
2. **Live:** yes (`pump_carb_frac` 0.23). **In objective:** yes. A change means a refit.
3. **Controls:** the δ¹³C fractionation of biogenic CaCO₃ relative to DIC on the carbonate export limb.
4. **Source now:** "Biogenic CaCO3 relative to the DIC it precipitates from -- SMALL and POSITIVE, unlike the organic limb. Expressed as a FRACTIONATION, not the ~+2 permil absolute value quoted in calibration/diag_alk_gradient.R: the absolute figure is surface DIC (+1.29 observed) plus this. WORKING VALUE." **Status: provisional, no source.**
5. **A citation must give:** a measured ε(CaCO₃–DIC) or ε(CaCO₃–HCO₃⁻) for marine biogenic carbonate, in ‰. It should say calcite or aragonite, coccolith or foraminifera, and any temperature dependence.
6. **On disk:**
   - **Zhang, Quay & Wilbur 1995**, PDF p7 (journal 113). Citing Turner (1982) and Emrich et al. (1970), it reports a solid-CaCO₃ to CO₂-gas fractionation of about 9.0–10 ‰ at 25 °C.
     - This is secondary, inorganic, and relative to CO₂ **gas**, not DIC.
     - The same paper's seawater ε(DIC–g) fit (abstract) is about 7.9 ‰ at 25 °C. The difference, roughly +1 to +2 ‰, is my first-order arithmetic, not a measurement.
   - **`bg-2019-365-AC2-supplement.pdf`** (Dentith et al., authors' reply on the FAMOUS radiocarbon paper), PDF p3. They ran FAMOUS with no CaCO₃ fractionation (αCaCO₃ = 1.0). That is a model choice, not a measurement.
7. **Value check:** no like-for-like candidate.

## 3. `ALK_SURFACE` = 2300 µmol/kg

1. **Where.** `R/constants.R:258-262`. Read at:
   - `R/model.R:2921` (LS mixed-layer pCO₂);
   - `R/model.R:3324` (HS pCO₂; `alk_hs` is absent at the canonical, so the HS box uses this value too);
   - `R/model.R:4340`;
   - `R/spinup.R:340, 362` and `R/cpp.R:70, 72`.
   - Also typed as `var1 = 2300e-6` in `data-raw/build_carbonate_tables.R:58` (fugacity coefficient only), and stored as `data/obs_tr_box.rds$alk_tr$model_const` = 2300.
2. **Live:** yes. **In objective:** yes; it sets the 1750 surface DIC, the Revelle factor and pCO₂. A change means a refit.
3. **Controls:** the fixed surface total alkalinity in every surface box's carbonate solve.
4. **Source now:** "Surface total alkalinity, held FIXED (alkalinity is near-conserved on these timescales). NEEDS a cited global-mean surface value." **Status: provisional, none.**
5. **A citation must give:**
   - a global surface TA in µmol/kg, saying area- or volume-weighted, which layer (0–50 or 0–100 m), and which epoch;
   - the product with version, DOI and access date (GLODAPv2.2023 is already the repo's product);
   - a ruling on the domain. The code applies one value to the LS boxes (|lat| < 57.14°) and to the HS box.
6. **On disk:**
   - **`calibration/output/alk_gradient/diag_alk_gradient.rds`** `$surf$vw` = **2303.38 µmol/kg**: GLODAPv2.2023, 0–100 m, volume-weighted over 829 cells (`$raw` 2277.25), from `calibration/diag_alk_gradient.R`.
     - It is recorded in CHANGELOG 2026-08-16 (line ~24812) and DESIGN.md:918 as "2300 against GLODAP's 2303.4".
     - It is a diagnostic output, not a versioned `data/` product.
   - **`data/obs_tr_box.rds$alk_tr`**: median surface (≤ 50 m, flag 2) TA over the ≥ 26 °C tropical mask is NH 2296, SH 2306, both 2299. The source is Lauvset et al. 2024, ESSD 16:2047. It covers that mask only.
   - **CHANGELOG 09-07 (line ~12080):** the SH high-latitude surface TA is 2296 (n 5200). The all-latitude median is 2256.
   - **Quay et al. 2003**, PDF p4 (journal 4-4): their box-diffusion model starts from an alkalinity of 2325 µeq/kg. That is a model setting.
   - **Raw data:** `data-raw/downloads/GLODAPv2.2023_Merged_Master_File.csv`, `glodap_talk_subset.csv` and `glodap_dic_talk_subset.csv`.
   - **Prior power check:** GATE G (CHANGELOG ~14781) fails when `ALK_SURFACE` moves ±2 % and passes within ±1 %.
7. **Value check:** GLODAP 0–100 m gives 2303.4 against 2300 (+0.15 %). **If adopted, the value changes and a refit is needed.** Quay's 2325 is a model setting (+1.1 %).

## 4. `ALPHA_AS_FCO3` = 0.082

1. **Where.** `R/constants.R:752-759`. Placed in `aux` at `R/model.R:4448`. Used by `ccx_alpha_as()` (`R/model.R:547-554`) and its C++ twin (`src/ccx_core.cpp:225+`).
2. **Live:** yes (`alpha_as_tdep` = 1). **In objective:** yes, through every air-sea δ¹³C limb. A change means a refit.
3. **Controls:** the surface carbonate-ion fraction [CO₃²⁻]/DIC in Zhang's temperature-dependent ε(DIC–g). It is held constant rather than solved.
4. **Source now:** "Surface [CO3=]/DIC held fixed rather than solved per step. Measured at the 25-parameter mode's own surface state (NH 0.0856, SH 0.0786; mean 0.082) -- INSIDE Zhang's stated 0.05-0.20. Contributes 0.020 permil of an ~8.7 permil eps_DIC-g and 1 % of its temperature slope." **Status: provisional.** It is an approximation, measured at an older (25-parameter) mode.
5. **A citation must give one of:**
   - an observed global surface [CO₃²⁻]/DIC from a carbonate-system climatology (product, version, DOI, access date, layer); or
   - a ruling that it is model-derived. It would then be "derived", naming the script, mode and commit, and it was last measured at a mode older than hilda29e.
6. **On disk:**
   - **Zhang et al. 1995**, PDF p5 (journal 111): in average seawater, carbonate is 7–13 % of total DIC (HCO₃⁻ 87–93 %, CO₂(aq) < 1 %).
   - **Same paper, abstract (PDF p1):** the fit holds for 0.05 < fCO₃ < 0.20 and 5–25 °C.
   - **`data-raw/downloads/glodap_dic_talk_subset.csv`** (paired tco2/talk): fCO₃ is computable with the repo's carbonate constants. Not computed here.
7. **Value check:** 0.082 lies inside 7–13 %. No disagreement.

## 5. `OCEAN_DEPTH` = 3700 m

1. **Where.** `R/constants.R:250-256`. Read as the default `total_depth` of `ccx_ocean_grid()` (`R/model.R:1166`).
   - **Coupling:** `data/obs_glodap_deep.rds$model_layer` = c(2627, 3700). The deep-target layer bounds were cut from the 3700 m grid at h_ml 75.
2. **Live:** yes. **In objective:** yes, through every interior box mass. A change means a refit **and** a rebuild of the GLODAP deep targets.
3. **Controls:** the column depth, which sets every interior layer's thickness.
4. **Source now:** "Working value. Eakins & Sharman (2010, NOAA NGDC, ETOPO1): volume 1.335e9 km3 over 3.619e8 km2 = 3690 m mean depth -- 0.3 % under the working 3700. STAYS provisional at 3700 (2026-09-21 h): the column depth sets every deep-row mass, so moving it is a model change and a restamp, not a citation." **Status: partial.** The named source gives 3690, not 3700.
5. **A citation must give:** this is a **ruling**, not a lookup. Either adopt the cited 3690 (refit plus target rebuild), or keep 3700 with a stated tolerance ("equals 3690 to 0.3 %") ruled acceptable. Eakins & Sharman 2010 is not on disk.
6. **On disk:** no PDF or dataset gives a mean ocean depth. DESIGN.md:78 still says "≈ 3700 m [VERIFY]".
7. **Value check:** nothing on disk. The registry's own off-disk source gives 3690 (−0.3 %).

## 6. `NPP_GLOBAL_PI` = 60 GtC/yr

1. **Where.** `R/constants.R:353-375`. Read at `R/model.R:4333-4334` (`npp0`).
2. **Live:** yes. **In objective:** yes; it sets NPP₀, the land pool sizes, respiration and the seasonal NEP amplitude. A change means a refit.
3. **Controls:** global terrestrial NPP at 1750 CO₂, before the model's own clearing.
4. **Source now** (excerpt): "PROVISIONAL BY RULING (Marcus 2026-09-29, option 1 of four) … Value from IPCC TAR WG1 Ch.3 (Prentice et al. 2001) sec. 3.2.1: 'about 60 PgC/yr through integration of field measurements' … SCOPE CAVEAT: all PRESENT-DAY; no opened source gives a 1750 value … TAR is the OLDEST source." **Status: provisional by ruling.** It is cited, but at the wrong period.
   - DESIGN §3.3 (≈ line 112) retired the modern-NPP prior on 10-02 (D4: NPP₀ stays fixed; modern NPP is a named tension).
5. **A citation must give:** a preindustrial (≈1700–1750) total (above + below ground) land NPP in PgC/yr, with a ruling on potential versus actual vegetation (flagged in `notes/lit_2026-09-29_npp_global_pi.md`). Or a ruling that the present-day "about 60" is acceptable under the stated caveat.
6. **On disk:**
   - **Bastos et al. 2016** (BG 13:4877), Table 4, PDF p10 (journal 4886). The row "NPP0, F0B, gross terrestrial fluxes in 1700" gives **54 PgC yr⁻¹**, referenced to Running (2012).
     - It is an OSCAR model input for 1700, sourced to a modern estimate.
     - Vintage 2016, which is newer than TAR (2001).
   - **Naegler & Levin 2006** (JGR 111, D12311), PDF p5 ("5 of 14"): their GRACE model is configured with a global total NPP of 60 PgC/yr. That is a model setting.
   - **`data/obs_npp_hemispheric.rds`** `$global_mean_PgC` = 52.7 (MOD17A3HGF C6.1, 2001–2023).
   - **`data/obs_npp_modern_target.rds`** centre 56.1 (products 52.7 / 56.2 / 59.2).
   - **`notes/lit_2026-09-29_npp_global_pi.md`** has the full literature table (TAR, Haberl 2007 potential 65.51 at year-2000 CO₂, Ito 2011, AR5/AR6). None of those PDFs are on disk.
7. **Value check:** Bastos Table 4 gives **54 for 1700**, 10 % below 60, and it is the only on-disk number labelled preindustrial. It is a model input whose cited source is modern. **If adopted, the value changes and a refit is needed.** Naegler's 60 agrees, as a model setting.

## 7. `NPP_FRAC_NH_ANCHOR_1750` = 0.5986

1. **Where.** `R/constants.R:595-601`. Read at `R/calibrate.R:680-682` as the prior centre for `npp_frac_NH`, with sd `NPP_FRAC_NH_SD` = 0.04.
2. **Live:** yes; `npp_frac_NH` is fitted at 0.59415. **In objective:** yes, as the prior term. A change means a refit.
3. **Controls:** the prior centre of the 1750 NH share of NPP.
4. **Source now:** "NPP_FRAC_NH_OBS inverted through the model's own hemispheric clearing to 1750, as a fixed point. The PRIOR CENTRE for the fitted `npp_frac_NH` (Marcus 2026-08-20k), NOT the value it takes. Derived by calibration/diag_npp_frac_anchor.R at the arm-N mode." **Status: provisional (model-inverted by design).** The underlying observation (MOD17A3HGF C6.1) is cited.
5. **What it needs:** no literature citation. It needs a **ruling on status**. Either:
   - re-derive it at hilda29e (whose `luc_scale` is 0.914) and register it as "derived" with script, mode and commit; or
   - centre the prior on `NPP_FRAC_NH_OBS` directly.
6. **On disk:** `data/obs_npp_hemispheric.rds$nh_share_mean` = 0.5942 (sd 0.0135, 2001–2023), which is the input. The script is `calibration/diag_npp_frac_anchor.R`.
7. **Value check:** not applicable. It was derived at the 08-20 "arm-N" mode, not at hilda29e, and was not re-measured here.

## 8. `ENT_SEAS_BAND_AREA_FRAC` = 0.369 (`.ENT_BAND_AREA_FR`)

1. **Where.**
   - `R/constants.R:156` (`.ENT_BAND_AREA_FR`), `988-1006` (the registry entry) and `1035-1037` (`ENT_SEAS_AMP_SH_DERIV`).
   - `R/calibrate.R:71` holds `ENT_SEAS_LOGSD` typed as 0.49848 = log(1/0.369)/2, tied by `test-ent-seas-fitted.R`.
   - `R/calibrate.R:808-809` is the prior.
2. **Live: NO at hilda29e.**
   - `ent_seas_amp_SH` is pinned at 0. The channel needs a non-zero amplitude to run (`R/model.R:2909-2913`, `src/ccx_core.cpp:733-736`).
   - The pinned name's prior leaves the table, so this is evaluated only at source time.
   - It would be live in any arm that frees `ent_seas_amp_SH` (e.g. `hilda31p`).
3. **Controls:** it dilutes the 40–90°S in-band entrainment amplitude onto the SH box. It sets both the prior centre and the width.
4. **Source now:** "LIVE GEOGRAPHIC RATIO: the ocean area of the 40-90 S band as a fraction of TOTAL SH ocean area, from the 2026-08-27g entrainment pre-check's own area weighting. … ⚠ PROVISIONAL: a GEOGRAPHIC area ratio that NEEDS a cited source, exactly as OCEAN_AREA_NH/SH do." **Status: provisional.**
5. **A citation must give:** a land/ocean mask or hypsometry product (version, access date) for the 40–90°S ocean area and the SH ocean area. Or a ruling to register it as "data" computed from the product mask already on disk, stating whether unreported or ice cells count.
6. **On disk:** `data-raw/downloads/MPI-ULB-SOM_FFN_clim.nc` via `calibration/diag_so_pco2_phase.R:159-172` (`ocean_area()` over the product's reported cells) is where 0.369 came from. `ersst_v5_sst_mnmean.nc` is an alternative mask. Not recomputed here. No literature on disk.
7. **Value check:** none.

## 9–10. `ALPHA_AS_DOWN_LEGACY` = −2 ‰ and `ALPHA_AS_UP_LEGACY` = −10 ‰

1. **Where.** `R/constants.R:776-789`. Placed in `aux` at `R/model.R:4454-4455`. Used only when `alpha_as_tdep` = 0 (`R/model.R:548-549`, `src/ccx_core.cpp:225`).
2. **Live: NO** (`alpha_as_tdep` = 1). They are the path that reproduces pre-09-02 vectors.
3. **Controls:** the retired scalar air-sea ¹³C fractionations.
4. **Source now:**
   - DOWN: "The pre-2026-09-02 invasion fractionation, a literal in ccx_prepare()'s aux. Measured against Zhang et al. (1995) it is 2.4x TOO LARGE (eps_k ~ -0.84 at the model's SST). Retained ONLY as the behaviour-preserving path."
   - UP: "… Right to 3-5 % against Zhang et al. (1995) (-9.50/-9.72 at the model's SST)."
   - **Status: provisional (never sourced).**
5. **What it needs:** no citation for beta if they stay reproduction-only. Marcus to rule whether they stay on the provisional ledger. `test-constants.R` pins both the provisional set and the retired roster, so any status change needs a deliberate test edit.
6. **On disk:**
   - **Zhang et al. 1995**, PDF p4 (journal 110): kinetic fractionation −0.81 ± 0.16 ‰ at 21 °C and −0.95 ± 0.2 ‰ at 5 °C. These are already registered as `ALPHA_AS_KIN_21/_5`.
   - **Quay et al. 2003**, Table 3, PDF p16 (journal 4-16): "Fractionation during CO₂ gas efflux, ‰" αma = −10.9 ± 0.3 (1970–1990 a priori).
7. **Value check:** DOWN −2 against about −0.8 to −0.95. UP −10 against −10.9 ± 0.3. Neither is live, so no refit.

## 11–12. `ALPHA_PHOTO_EPS` = 18 (registry) and `CCX_ALPHA_PHOTO_EPS_BIOSPHERE` = 15.6 (live)

1. **Where.**
   - Registry: `R/constants.R:301-308`. Read only as the fallback at `R/model.R:4414` when `p$alpha_photo_eps` is absent.
   - **Live value:** `R/calibrate.R:2303`, `CCX_ALPHA_PHOTO_EPS_BIOSPHERE <- 15.6`, injected by `ccx_struct_hilda_c()` (`R/calibrate.R:2304-2312`).
   - The canonical's run list carries `alpha_photo_eps` = 15.6 (verified by loading it).
   - It is used as `aux$alpha_photo` on the photosynthesis limbs and the seasonal uptake limb (`R/model.R:2829-2830`).
2. **Live:**
   - **18: NO at hilda29e.** It is read only by lists that lack the field: `ccx_default_params()` and pre-`hilda_c` registered modes.
   - **15.6: YES, in objective**, through the land isotopic signature in every δ¹³C row. A change means a refit.
3. **Controls:** terrestrial photosynthetic ¹³C discrimination.
4. **Source now:**
   - **Registry:** "Lloyd & Farquhar (1994) Oecologia 99:201-215: C3 GPP-weighted 13C discrimination 17.8 permil; C4 3.6; total 14.8 at 25 % C4. Still et al. (2003) GBC 17:1006 / Suits et al. (2005) GBC 19:GB1017: 15-18 permil. IN USE: 18 (the C3-only value); the biosphere-wide 14.8-16.5 is the refit-batch revision (review 2026-09-14 g)."
   - **`R/calibrate.R:2295-2299`:** "alpha_photo_eps <- 15.6 permil, the MID-BRACKET of the biosphere-wide value (Lloyd & Farquhar 1994 total 14.8 at 25 % C4; Still 2003 / Suits 2005 15-18 -> 14.8-16.5) … A RULED CHOICE, not a measurement."
   - **Status:**
     - The registry is cited, but its "IN USE: 18" is **false at the canonical** (review §3).
     - 15.6 is partial: the **upper bound 16.5 has no named source** in either file. The registry text says the later work brackets 15–18, not 14.8–16.5.
5. **A citation must give:**
   - one number in one place, the registry, corrected to the value in use;
   - a global GPP-weighted C3+C4 discrimination in ‰, with the C4 share and the period;
   - the source of the 16.5.
   - Lloyd & Farquhar, Still, Suits and Scholze are not on disk.
6. **On disk:**
   - **Quay et al. 2003**, Table 3, PDF p16 (journal 4-16): "Fractionation during photosynthesis, ‰" αab = **−17 ± 5** (footnote d: Bakwin et al. 1998; a 1970–1990 a-priori value).
   - **Bastos et al. 2016**, Table 4, PDF p10, lists a terrestrial-biosphere "isotopic fractionation" of −7 (Ciais et al. 2014). That is a different quantity, recorded only so it is not mistaken for a candidate.
7. **Value check:** Quay's 17 differs from 18 (−1) and from 15.6 (+1.4). Both lie inside its ±5. **If 17 were adopted, a refit is needed.**

## 13–14. Obliquity −23.44° and the +10-day declination phase

1. **Where.**
   - `R/model.R:340` (`ccx_insol`) and `src/ccx_core.cpp:375-376` (`seas_insol`).
   - Used at `R/model.R:797` (norms) and `R/model.R:2816` (seasonal NPP), and at `src/ccx_core.cpp:697, 1393`.
2. **Live:** yes (`seas_drivers` = 1). **In objective:** yes, through the seasonal CO₂ and δ¹³C rows via the NPP insolation shape.
   - A change means a refit.
   - `SEAS_NPP_AMP_*` and `CCX_SEAS_PHI_EFF` would also need re-deriving, because they are fitted through this shape (`test-likelihood.R` re-fits the amplitudes at the current φ).
3. **Controls:** the solar declination in the daily-mean top-of-atmosphere insolation that shapes the seasonal NPP cycle.
4. **Source now:** the docstring reads "Daily-mean top-of-atmosphere insolation at latitude phi, flat-sun formula. S0 is omitted -- every use divides by the annual mean, so it cancels. Periodic in t with period exactly 1 (the +10 day offset rides inside the cosine)". **Status: none** for 23.44 or for +10.
5. **A citation must give:**
   - (i) the obliquity value, its epoch and its source;
   - (ii) the source of the cosine declination approximation and its +10-day (December-solstice) phase, with its stated accuracy against an ephemeris;
   - (iii) confirmation that the 365.25-day year in `tt * 365.25` is intended.
6. **On disk:** nothing. I searched "obliquit|declination|23.4x|solstice|insolation" in all 44 PDFs; CHANGELOG has uses only.
7. **Value check:** none.

## 15. `CCX_SEAS_PHI_EFF` = (NH 75°, SH −30°)

1. **Where.** `R/model.R:263`, with its C++ twin at `src/ccx_core.cpp:351`. Used at `R/model.R:797, 2816` and `src/ccx_core.cpp:697, 1393`.
2. **Live:** yes. **In objective:** yes. A change means a refit and re-deriving `SEAS_NPP_AMP_*`.
3. **Controls:** the effective latitude whose insolation **shape** drives seasonal NPP. Its size is `SEAS_NPP_AMP_*`.
4. **Source now:** `R/model.R:249-262` says it is "the latitude whose INSOLATION SHAPE best matches observed land productivity once the amplitude is free", per `calibration/diag_seas_rectification.R`. CHANGELOG 08-18 (~25700) calls it "the offline interior optimum".
   - **Status: partial.** It is fitted to MOD17 offline, has no registry entry, no data product stores the 75, and no reproduction test exists.
   - The SH −30 was "asserted outright" (CHANGELOG 08-20 audit, line ~26263).
5. **A citation must give:** a registry entry with status "data" or "derived" naming:
   - the product (MOD17A2HGF C6.1; its DOI is already in `obs_npp_seasonal_shape.rds$source`);
   - the estimator (amplitude-free SSE, window-integrated, free shift);
   - the script and its output;
   - a reproduction test, as `SEAS_NPP_AMP_*` already have.
   - For the SH, either a measurement or a ruling. CHANGELOG 08-20r (~26959) records −30 scoring −2027.7 against −18 at −2043.5, with "−18 for 15.8 log-units" offered.
6. **On disk:**
   - **`data/obs_npp_seasonal_shape.rds`** stores two **other** estimators:
     - unit-amplitude SSE φ: NH 49.3 (GPP) / 50.0 (PsnNet); SH −10.9 / −16.1;
     - amplitude-matched φ: NH 54.6 / 55.5; SH −28.2 / −32.2.
   - It does **not** store the amplitude-free argmin that gives 75.
   - **CHANGELOG ~17703:** the NH argmin is 75 in MOD17-8day, MOD17-monthly and CMIP6. For the SH, "the argmin runs to the grid edge", so there is no interior optimum on the insolation basis.
7. **Value check:** no like-for-like value on disk. The stored estimators are different quantities.

## 16. `CCX_SEAS_T_LAG` = 2.0 months

1. **Where.** `R/model.R:277`, with its twin at `src/ccx_core.cpp:359`. Used at `R/model.R:798, 2802` and `src/ccx_core.cpp:690, 1395`.
2. **Live:** yes. **In objective:** yes.
3. **Controls:** the phase of the seasonal soil-respiration temperature factor, in months after the mid-July zero-lag peak.
4. **Source now:** "MEASURED 2026-08-20, calibration/diag_seas_lag_profile.R: profiled at the arm-N mode, the seasonal rows give … A clean interior optimum at 2.0". **Status: model-derived.** It is a likelihood profile of the code under test, at an 08-20 mode.
5. **A citation must give:** an observed seasonal phase of soil temperature or heterotrophic respiration (hemispheric, respiration-weighted), with product and access date. Or a ruling that it is a calibrated structural constant: then it is either fitted, or registered "derived" naming the model, mode and vintage, as the threshold rule requires.
6. **On disk:** none. `data/obs_seasonal_clim.rds` holds land **air**-temperature peaks (NH all-land, model_lag 0.042). The code comment rules that out explicitly ("DO NOT 'correct' the 2.0 to match it").
7. **Value check:** none.

## 17. `CCX_SST_SEAS_LAG` = 1.32 months

1. **Where.** `R/model.R:295`, with its twin at `src/ccx_core.cpp:360`.
   - Used at `R/model.R:2883` for both hemispheres, with the SH sign-flipped, and at `src/ccx_core.cpp:724`.
   - The HS box has no seasonal cycle (`R/model.R:3307-3311`).
2. **Live:** yes. **In objective:** yes (`sst_seas_amp_NH/SH` are fitted at 1.632 / 1.555).
3. **Controls:** the phase of the seasonal SST perturbation on the low-latitude surface boxes.
4. **Source now:** "ERSSTv5's area-weighted NH hemispheric climatology (1975-2024, = LIK_SEAS_WINDOW) peaks at month 7.82, which in this file's (3.5 + LAG)/12 convention is LAG = 1.32." **Status: data, via a diagnostic.** The value is typed rather than read, and it was measured on the NH only but is applied to both hemispheres.
5. **A citation must give:**
   - the value read from the product, or a registry "data" entry tied by a test;
   - the ERSSTv5 citation (Huang et al. 2017, doi:10.1175/JCLI-D-16-0836.1, already in `obs_seasonal_clim.rds$ocean_source`);
   - **a ruling on whether the SH gets its own lag.**
6. **On disk:** `data/obs_seasonal_clim.rds`:
   - `$ocean$\`NH_1975-2024\`$model_lag` = **1.3249** (peak month 7.8249). It matches.
   - The SH row's peak month is 2.0357. Its stored `model_lag` of 7.5357 was computed **without** the SH sign flip.
   - Under the code's sign-flipped convention (−sin peaks half a cycle later, so peak = 0.5 + LAG), the SH lag is **1.536 months** (my arithmetic).
7. **Value check:** the NH agrees. **The SH product implies 1.54 against 1.32 in use**, so the model's SH SST peaks about 0.2 months early. The value changes only under a per-hemisphere ruling, and then a refit is needed.

## 18. `CCX_ENT_SEAS_PEAK_MO` = 7.50

1. **Where.** `R/model.R:330`, with its twin at `src/ccx_core.cpp:368`. Used at `R/model.R:2912` and `src/ccx_core.cpp:735`, and only when `ent_seas_amp_SH` ≠ 0.
2. **Live: NO at hilda29e** (`ent_seas_amp_SH` is pinned at 0).
3. **Controls:** the peak month of the Southern Ocean entrainment channel's surface-DIC anomaly.
4. **Source now:** "MEASURED … Peak month of the ocean-area-weighted 40-90 S pCO2 first harmonic." **Status: data, via a diagnostic, typed.**
5. **What it needs:** read it from the product, or register it as "data" with a test tie.
6. **On disk:** `data/obs_so_pco2_seas_amp.rds$band_peak_month` = **7.4962**. Its source is the Landschützer/Laruelle SOM-FFN climatology (NCEI 0209633), with a MANIFEST row.
7. **Value check:** it agrees to rounding.

## 19. `FORC_BOMB_NH_SHARE` = 0.90

1. **Where.** `R/forcing.R:115`. Placed in `aux` at `R/model.R:4471`. Used at `R/model.R:3761-3764`, `src/ccx_core.cpp:1202-1204` and `R/c14_tag.R:48`.
2. **Live:** yes. **In objective:** yes (the NH and SH Δ¹⁴C rows and the bomb rows). A change means a refit.
3. **Controls:** the NH fraction of bomb-¹⁴C delivered to the troposphere.
4. **Source now:** "# atmospheric weapons tests were overwhelmingly NH." **Status: none.**
   - The CHANGELOG 08-20 audit (~26261) calls it "still PROVISIONAL".
   - DESIGN.md:558-559 says "Injected into the NH (and a small SH share [VERIFY]) troposphere."
5. **A citation must give:** the hemispheric split of bomb-¹⁴C **delivery to the troposphere** over 1952–1980, with source and table.
   - The model's source is a stratosphere→troposphere delivery (`R/forcing.R:390-397`).
   - A production split by test-site latitude is not the same quantity.
6. **On disk:** no quoted share.
   - Naegler & Levin 2006 (PDF p4, p10) uses a six-band model and discusses hemispheric inventories but gives no NH share.
   - Indirect data: `data/obs_d14c_zonal.rds` and `data-raw/downloads/hua2022_zonal_d14c.rds` (Hua et al. 2022; `build_bomb_c14_source.R:198` already aggregates them to hemispheres), and `Delta14co2_input4MIPs_…nc`. A share inferred from these would depend on the model's interhemispheric exchange time.
   - Tans (1981) SCOPE 16 is not on disk.
   - **Coupling:** the ¹⁴C tag's 2×2 solve needs the bomb and nuclear NH shares to **differ** (`R/c14_tag.R:38, 48-50`).
7. **Value check:** none.

## 20. `FORC_NUC_NH_SHARE` = 0.95

1. **Where.** `R/forcing.R:113-114`. Placed in `aux` at `R/model.R:4472`. Same uses as row 19.
2. **Live:** yes. **In objective:** yes, as a small source. A change means a refit.
3. **Controls:** the NH fraction of industrial (nuclear power and reprocessing) ¹⁴C.
4. **Source now:** "# nuclear-industry 14C: the 22 reporting countries are overwhelmingly NH. PROVISIONAL." **Status: none.**
5. **A citation must give:** the GBq-weighted NH share of the industrial source the model actually uses, with the per-country hemisphere assignment; or a cited share. A time-varying share is the like-for-like quantity.
6. **On disk:** `data-raw/downloads/nuclear14c/*.csv`, the same files `ccx_nuclear_c14_annual()` sums (22 countries).
   - Only Argentina (Atucha-1, Atucha-2, Embalse) and Brazil (Angra-2) are SH.
   - Summing every row as the model does, the SH holds **0.70 %** of the GBq, so the pooled NH share is **0.993** (my aggregation, all years pooled; not a proposed value).
7. **Value check:** 0.993 pooled against 0.95. **If adopted, the value changes and a refit is needed**; the effect was not measured here. It must stay ≠ `FORC_BOMB_NH_SHARE` (row 19 coupling).

## 21–22. `P_canon`: 2.04 atoms cm⁻² s⁻¹ × 5.1e14 m², and the re-typed `.SEC_PER_YR` / `.AVOGADRO`

1. **Where.** `R/spinup.R:204-205`, duplicated at `calibration/pump_shim.R:177`.
   - It feeds `prod_canonical` and `prod_ratio` (`R/spinup.R:275-276`), the printout at `R/spinup.R:556`, and `calibration/diag_dic_gradient.R:341`.
   - Gate: `tests/testthat/test-spinup.R:56-57` requires 0.5 < `prod_ratio` < 2.0, on **default** parameters.
2. **Live:** diagnostic only. Production is **solved** by `ccx_spinup()`, and `P_canon` enters no flux. **Not in the objective.**
3. **Controls:** a reference cosmogenic ¹⁴C production rate, printed for comparison.
4. **Source now:** "# canonical cosmogenic production, for comparison ONLY". **Status: none.**
   - CHANGELOG ~21601: "Where the ~545 target came from has NOT been verified".
   - The line re-types `365.25 * 86400` and `6.02214076e23` instead of reading `.SEC_PER_YR` / `.AVOGADRO`, which the header at `R/constants.R:24-31` forbids.
   - **Those two registry privates (`R/constants.R:30-31`) carry no source string either.** Avogadro's value is exact in SI; the Julian year is a convention.
   - The Earth area also appears inside `OCEAN_AREA_NH/SH`'s source strings as "a hemisphere's 2.551e14 m2", uncited. 2 × 2.551e14 = 5.102e14 against 5.1e14 here (−0.04 %, my arithmetic).
5. **A citation must give:**
   - a global-mean natural ¹⁴C production rate in atoms cm⁻² s⁻¹, stating the period and solar modulation;
   - an Earth surface-area source;
   - and the two constants read from the registry.
6. **On disk:** Naegler & Levin 2006, PDF p5 ("5 of 14").
   - GRACE's natural production depends on the scenario: 0.48–0.55 kmol ¹⁴C/yr (2.9–3.3 × 10²⁶ atoms/yr), averaged over a solar cycle (±10 % across it), and distributed after Lingenfelter (1963).
   - `P_canon` = 545.2 mol/yr = **0.545 kmol/yr** = 3.28 × 10²⁶ atoms/yr (my arithmetic), inside that range at its top.
   - That corroborates the **total**, not the per-area 2.04 or the area.
7. **Value check:** the total agrees. Nothing on disk gives the per-area flux or the area.

## 23. `CCX_BOMB_REF` = 102 kmol, and the re-typed 102s

1. **Where.**
   - `R/constants.R:1149`.
   - Re-typed as defaults at `R/forcing.R:400, 407, 438, 603`.
   - `R/calibrate.R:870` (init) and **`R/calibrate.R:871`, where the prior centre is `log(102)`. That is a separate literal, not `CCX_BOMB_REF`.**
2. **Live:**
   - `CCX_BOMB_REF` **cancels** in the objective: the forcing is built at `CCX_BOMB_REF` and scaled by `bomb_total / CCX_BOMB_REF` (`R/calibrate.R:2061, 3025`).
   - **The prior-centre literal is in the objective.** A change means a refit.
3. **Controls:** the reference bomb total, and separately the centre of the `bomb_total` prior.
4. **Source now:**
   - `R/constants.R:1145-1148` gives none.
   - `R/calibrate.R:864-869` says "Calibrated (as DESIGN intended), with a CITABLE prior: Naegler & Levin (2006) give 99.3-104.9 kmol."
5. **A citation must give:**
   - the centre stated as N&L's range midpoint, with the citation;
   - the prior reading `CCX_BOMB_REF`, not a second literal;
   - a flag on the like-for-like question already logged: the model's source is a delivery-to-troposphere, centred on N&L's production total (CHANGELOG ~21118-21130, ~21441, 09-15 f ~9443). That is a methodological choice.
6. **On disk:** Naegler & Levin 2006, PDF p1 (abstract) and p8 ("8 of 14"). Total bomb ¹⁴C production 1945–1980 runs from 99.3 kmol (598 × 10²⁶ atoms, scenario YANGM5) to 104.9 kmol (632 × 10²⁶, RATH). The midpoint is 102.1 (my arithmetic).
7. **Value check:** it agrees.

## 24. `JOOS_PPM_PER` = 2.123 GtC/ppm

1. **Where.** `R/joos_irf.R:19`. Used at `R/joos_irf.R:110, 157` (`ccx_irf`, and `ccx_irf_pd` → `ccx_pd100`), by **`app/R/review.R:387`** (the app's PD100 card), by `test-fair-pd100.R:46` and `test-pd100-runner.R:71`, and by diagnostics.
2. **Live:** in the app's review card and in diagnostics. **Not in the objective.**
3. **Controls:** normalises the 100 GtC pulse to ppm in the Joos IRF protocol.
4. **Source now:** "# GtC per ppm, the conversion Joos states". **Status: partial** (no page).
5. **What it needs:** the page in Joos et al. 2013.
6. **On disk:** Joos et al. 2013 (ACP 13:2793), PDF p6 (journal 2798).
   - The protocol converts the 100 GtC pulse to 47.10 ppm with **2.123 GtC ppm⁻¹**, citing Enting et al. 1994.
   - The same paragraph notes a revised factor of 2.120 (Prather et al. 2012).
7. **Value check:** it agrees. The model's own ppm uses `GtC_PER_PPM` = 2.124, so the normalised IRF carries a 2.123/2.124 factor (−0.05 %). `test-pd100-runner.R:71` already accounts for it.

## 25–27. `.ENT_PCO2_REF` = 370 µatm, `.ENT_REVELLE` = 13, `.ENT_DIC_SURF` = 2150 µmol/kg

1. **Where.** `R/constants.R:130, 151, 144`. They are consumed only by `ENT_SEAS_AMP_SH_INBAND/_DERIV` (`R/constants.R:1007-1037`), which is the prior centre of `ent_seas_amp_SH` (`R/calibrate.R:808`).
2. **Live: NO at hilda29e** (pin 0; the prior is not evaluated).
3. **Controls:** the conversion of the observed Southern Ocean pCO₂ and SST cycles into a DIC entrainment amplitude.
4. **Source now:**
   - 370: "uatm, reference surface pCO2 the % is taken on"
   - 2150: "umol/kg, surface DIC. ⚠ UNCITED, and it sits ~5.6 % above the GLODAP surface value GATE G scores against (~2035)…"
   - 13: "buffer factor. ⛔ DELIBERATELY NOT read off the model's own carbonate chemistry…"
   - **Status: none** for all three.
5. **A citation must give:** surface means for pCO₂ (µatm, period), DIC (µmol/kg, layer, epoch) and the Revelle factor over the **40–90°S band**, not the global ocean, because the chain is in-band. Each needs a product or paper and an access date.
6. **On disk** (none is a 40–90°S band value):
   - **pCO₂:** `data/obs_tr_box.rds$pco2$both$global` = 367.27 (SOM-FFN 1985–2015 global surface mean).
   - **DIC:**
     - `data/obs_glodap_deep.rds$tco2$surf$vw` = 2040.0 (GLODAPv2.2023, 0–100 m, global);
     - `data/obs_hs_surface.rds$dic$target` = 2163 (the SH high-latitude box);
     - Quay et al. 2003, Table 3 (PDF p16): C_oc = 2.1 ± 0.05 mol C m⁻³. The table prints it as "DOC concentration", but p3 defines C_oc as upper-ocean DIC. That is ≈ 2049 µmol/kg at ρ 1025 (my conversion).
   - **Revelle:**
     - Quay 2003, Table 3: buffer factor ξ = 10.5 ± 1 (global a priori, 1970–1990);
     - Quay 2003, p4: their box-diffusion model's buffer factor runs from about 9 to 10.
   - **Raw data for band values:** `MPI-ULB-SOM_FFN_clim.nc` and `glodap_dic_talk_subset.csv`.
7. **Value check:** all three differ from the on-disk global values (367 vs 370, 2040 vs 2150, 10.5 vs 13), but at a mismatched scope. They are not live, so there is no refit at hilda29e.

## 28. `bomb_total` prior log-sd = 0.10

1. **Where.** `R/calibrate.R:870-871`.
2. **Live:** yes (`bomb_total` is fitted at 118.874). **In objective:** yes, as the prior term. A change means a refit.
3. **Controls:** the width of the lognormal prior on total bomb ¹⁴C.
4. **Source now:** `R/calibrate.R:864-869` says "… with a CITABLE prior: Naegler & Levin (2006) give 99.3-104.9 kmol. Treating it as free lets error in the still-provisional injection SHAPE be partly absorbed into magnitude…".
   - **The 0.10 itself has no source.**
   - DESIGN.md:686 reads "P_bomb | total bomb ¹⁴C production | N centered on Naegler & Levin [VERIFY]". DESIGN says Normal; the code uses a lognormal.
5. **A citation must give:** a published uncertainty on total bomb production (σ in kmol or %). Or a ruling that 0.10 is a deliberate inflation over the scenario span, stating the factor and the reason (the shape absorption the comment gives).
6. **On disk:** Naegler & Levin 2006, PDF p1 and p8: the four-scenario span is 99.3–104.9 kmol. That is a scenario range, not a σ.
   - Its log half-span is **0.027** (my arithmetic), so 0.10 is about 3.6× wider.
   - ±1σ at 0.10 spans 92.3–112.7 kmol.
   - The fitted 118.874 sits at **+1.53σ** under 0.10.
7. **Value check:** reading the span as ±1σ would narrow the prior about 3.6× and require a refit. The span is not a σ, so this is a **ruling, not a lookup**.

## 29. `FORC_FOSS_NH_SHARE` = 0.9201

1. **Where.** `R/forcing.R:68`. Its comment continues at `R/forcing.R:88-99`, split from the assignment by the SST block (an edit artefact). Used at `R/forcing.R:712-718, 766-767` and `R/joos_irf.R:63-64`.
2. **Live:** yes. **In objective:** yes (the MLO–SPO gradient rows).
3. **Controls:** the NH share of fossil CO₂ emissions.
4. **Source now:** "MEASURED (Marcus, 2026-08-15, review item 5) by the EDGAR v4.3.2 country aggregation in data-raw/extract_emission_seasonality.py -- Crippa et al. 2020, Sci Data 7:121. …"
   - **Status: cited.** The `MANIFEST.csv` row `edgar_v432_co2_monthly` gives doi:10.1038/s41597-020-0462-2, the URL, access date 2026-08-15 and sha256 `19a3b628…`.
5. **Residual needs (no new source needed):**
   - (a) The number is typed, not read from the extract.
   - (b) It is the 1970–2012 cumulative share applied as a constant over 1750–2024. That is a methodological choice; flagged.
   - (c) `data-raw/extract_emission_seasonality.py:178` still prints "FORC_FOSS_NH_SHARE is 0.95", which is stale text.
6. **On disk:** `data-raw/downloads/seasonality_fossil.csv` (1970–2012, 516 rows) reproduces **0.9201** (my aggregation).
7. **Value check:** it agrees.

## 30. `SALINITY_REF` = 34.7 *(added; outside R/ and src/, but on the live path)*

1. **Where.** `data-raw/build_carbonate_tables.R:25`. It is baked into `data/carbonate_coefs.rds`, whose provenance reads "S=34.7; built 2026-08-09". From there it reaches every K0/K1/K2/Kb/Kw and the boron total in `R/carbonate.R` and the C++ core.
2. **Live:** yes. **In objective:** yes, through all carbonate chemistry. A change means rebuilding the coefficients and a refit.
3. **Controls:** the salinity at which every carbonate constant is evaluated.
4. **Source now:** "# global-mean surface salinity used throughout". **Status: none.**
5. **A citation must give:** a global (or LS-box area) mean surface salinity on PSS-78, with product, version, access date and layer.
   - Consistency note: `RHO_SEAWATER` is cited at S 35 (`R/constants.R:344-350`).
6. **On disk:** `data-raw/downloads/GLODAPv2.2023_Merged_Master_File.csv` has a salinity column; not computed here. No paper on disk gives a value.
7. **Value check:** not computed.

## 31. `LIK_REP_SOURCE_D13C` = −26.5 ‰ *(added; self-declared provisional, outside the registry)*

1. **Where.** `R/likelihood.R:168` (comment at 158-167). Used at `R/likelihood.R:2560` and `R/calibrate.R:971`.
2. **Live:** yes (`rep_dC` is fitted at 4.212 ppm). **In objective:** yes. A change means a refit.
3. **Controls:** the δ¹³C of the excess carbon that the station-versus-box representation offset `rep_dC` carries.
4. **Source now:** "⚠ PROVISIONAL, UNCITED (flagged 2026-09-12, review C; CLAUDE.md rule 2). The value is the midpoint of a recollected bracket -- ~-25 permil for respired C3-biosphere carbon, ~-28 for the fossil-fuel mix -- and NEITHER endpoint has a paper + table behind it … (candidates to check, not citations: Andres et al. 2000 Tellus B for the fossil mix; a C3/C4-weighted respiration signature for the land)."
   - **Status: provisional, none.** CHANGELOG 09-12 (~9900) says it "stays, marked provisional (no receipt)".
5. **A citation must give:** the δ¹³C of respired land efflux and of the fossil mix over the scoring period (paper and table), plus a ruling on how to weight them (midpoint or flux-weighted).
6. **On disk:**
   - **Quay et al. 2003**, Table 3, PDF p16: biospheric CO₂ efflux R_b = **−25 ± 2.0 ‰**, and fossil R_f = **−28.1 ± 0.5 ‰** (1970–1990 a priori; from Heimann & Maier-Reimer 1996 unless footnoted).
   - **Bastos et al. 2016**, Table 4, PDF p10 (journal 4886): terrestrial biosphere δ¹³C −25 (Hellevang & Aagaard 2015); fossil −24 (1750) to −28 (2010) (Andres et al. 1994).
   - The repo's own fossil series, `d13c_foss` in the historical forcing (Graven et al. 2020-based), runs from −24.0 in 1850 to −28.3 in 2024 (`R/forcing.R:851`).
7. **Value check:** Quay's two endpoints give a midpoint of −26.55 (my arithmetic). It agrees.

---

## Borderline / not sure

These are not in the table above. Each is live unless noted. Marcus to rule whether "Cite before beta" covers them.

- **`gamma_diff` 0.25** (`CCX_GAMMA_DIFF_DEFAULT`, `R/model.R:907`; live, in objective). It is a ruled adoption chosen at a likelihood price and FACE-gated. No literature value is given for the fractional NPP enhancement per unit AOD.
- **Land-pool structure** (`R/model.R:1540-1548`; live, in objective): `npp_leaf_frac` 0.60, `tau_leaf` 1 yr, `tau_wood` 20 yr, `litter_slow_frac` 0.05, `tau_soil_fast` 2 yr, `tau_soil_slow` 500 yr.
  - They were chosen by `diag_land_topology.R` against N&L 2006 Table 4, which is a model-derived choice.
  - The pool sizes are checked against IPCC AR6 WG1 Fig. 5.12.
  - DESIGN.md:692 lists τ_veg and τ_soil as "Fixed [VERIFY-class]".
- **`sst_hs` 2 °C** (`R/model.R:1689`; live, in objective). It is justified as the floor of the carbonate fits. Measured high-latitude SSTs on disk: `data/obs_tr_box.rds` geom NH 1.73 / SH −0.094 °C (1991–2020).
- **`R13_VPDB` 0.0111802** (`R/constants.R:193-196`; live). It is marked "cited", but "Chang & Li, via NBS 19" has no year or journal. **`R14_STD`** (198-202) names Stuiver & Polach 1977 without a page.
- **`.SEC_PER_YR`, `.AVOGADRO`** (`R/constants.R:30-31`): no source strings. See rows 21–22.
- **`CCX_SST_RATIO_NH/SH` 0.819 / 0.762** (`R/forcing.R:85-86`). Used for futures only, in the app. They were measured by `calibration/diag_hemis_t_ratios.R` (HadSST4 against IGCC) and are not stored in a product.
- **`sst_scale` 0.8** (`R/model.R:2069`). It is a fallback used only when the forcing lacks SST-anomaly columns. As far as I read, the canonical's historical run does not reach it; I did not test that by running.
- **Prior hyperparameters on fitted names, with no source next to them:**
  - `q10` lognormal(log 2.0, 0.25) (`R/calibrate.R:203-204`; DESIGN §5.1 gives "median 2, 90 % CI ~(1.4, 2.9)", unsourced);
  - `seas_lag_p_NH/SH` N(2.25, 0.75) (741-744);
  - `pump_grad` log-sd 0.25 (646-648);
  - `sigma_d14c` lognormal(5, 0.7) (966-967);
  - `grad_off_co2` and `grad_off_d13c` N(0, 0.5 / 0.15) (1021-1024);
  - `NPP_FRAC_NH_SD` 0.04 and `SST_SEAS_LOGSD` 0.25 (`R/calibrate.R:29, 36`), both labelled "judgement";
  - the uniform boxes (`kz` [1161.6, 27808], `kz_deep_frac` [0.005, 1], `beta_max` [0, 3]).
  - There are also error-model σ's in `R/likelihood.R` (`LIK_D14C_REP_OTHER` 4 ‰, `LIK_D14C_REP_BOMB` 25 ‰, `LIK_CO2_REP_ERR` 1.0 ppm, `LIK_ICE_REP_ERR` 4 ppm, `LIK_GRAD_*_SD`, …).
  - These are modelling or error-model choices, not physical constants. Listed only so the scope can be ruled.
- **Conventions and numerics, probably out of scope:**
  - the 3.5-month zero-lag offset (`R/model.R:798, 2802, 2883`; recorded as `lag_zero_offset` in `obs_seasonal_clim.rds`);
  - the grid growth factor 1.4 (`R/model.R:1167`);
  - `FORC_GMST_PRE1850` = 0 and `FORC_ENSO_PRE1948` = 0.
- **`D13C_OTHER` −24 ‰** (`data-raw/build_calibration_data.R:359`). Non-cement process emissions go on the coal endmember. It is a choice; the script puts it under 0.4 % of the cumulative total.
- **Dormant at the canonical:** `CCX_SEAS_LAG_P_DEFAULT` 2.25 (both lags are fitted) and `FORC_LUC_NH_SHARE` 0.55 (the time-series switch is on).

## Searched and found nothing (on disk)

- **`PUMP_EPS13_ORG`.** Searched "fractionation|discriminat|epsilon|organic|photosynth|plankton|POC|soft tissue" over all 44 PDFs. Only Quay 2003's symbol αob turned up, with no value.
- **`OCEAN_DEPTH`.** Searched "mean depth|ocean depth|36xx–37xx m|3.6–3.7 km". Nothing. Eakins & Sharman 2010 is not on disk.
- **Obliquity and the +10-day phase.** Searched "obliquit|declination|23.4x|solstice|insolation". Nothing.
- **`CCX_SEAS_T_LAG`.** No soil-temperature or respiration-seasonality product is in `data/` or `data-raw/downloads/`. Only air temperature (CRU) is there.
- **`FORC_BOMB_NH_SHARE`.** Searched Naegler 2006 for "hemisphere|latitud|test site|zonal". No share. Tans 1981 (SCOPE 16) is not on disk.
- **Earth area 5.1e14 m² and the per-area 2.04 atoms cm⁻² s⁻¹.** Searched "5.1 × 10¹⁴|surface area of the earth|atoms cm|cosmogenic|Lingenfelter|Masarik". Only Naegler's totals turned up (row 21).
- **Not searched:** the `.docx` files in `ClaudeDocs/Papers/`.

## Cross-cutting couplings (a value change must move these together)

- **`OCEAN_DEPTH`** ↔ `data/obs_glodap_deep.rds$model_layer` (2627–3700).
- **`ALK_SURFACE`** ↔ `build_carbonate_tables.R:58` and `obs_tr_box.rds$alk_tr$model_const`.
- **Obliquity, the +10 days and `CCX_SEAS_PHI_EFF`** ↔ `SEAS_NPP_AMP_NH/SH`. They are one shape-and-size unit and must be re-derived together.
- **`FORC_BOMB_NH_SHARE` / `FORC_NUC_NH_SHARE`** ↔ the ¹⁴C tag's 2×2 solve; the two must differ.
- **`CCX_BOMB_REF`** ↔ the separate literal at `R/calibrate.R:871`.
- **`SALINITY_REF`** ↔ `RHO_SEAWATER`'s S 35.
- **R ↔ C++ twins:** `SEAS_PHI_EFF`, `SEAS_T_LAG`, `SST_SEAS_LAG`, `ENT_SEAS_PEAK_MO` and the obliquity must change in both cores.
- **Any change to the 20 in-objective items** moves `hilda29e`, every stored logpost and the MCMC band. Whether they go into one batched refit alongside the §1 IntCal decision is a ruling.
