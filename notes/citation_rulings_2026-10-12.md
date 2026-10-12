# Citation rulings — 2026-10-12

- **Serves:** "Cite before beta", and "Citations first, one refit (Recommended)". Every value ADOPTED here goes into ONE refit together with the IntCal σ fix (CHANGELOG 10-12 u). Then MCMC, then the `v1.1` tag.
- **Sources:**
  - `notes/constants_citation_needs_2026-10-12.md` (the worklist; row numbers below are its rows);
  - `notes/constants_citation_sources_7_2026-10-12.md` (the 7 with nothing on disk);
  - two research reports still pending, marked ⏳.
- **Answers are Marcus's, verbatim, from the walkthrough.** Nothing here is implemented yet.

## A. Values that CHANGE (all go into the refit)

| row | constant | was | ruled | Marcus, verbatim | consequences |
|---|---|---|---|---|---|
| 3 | `ALK_SURFACE` | 2300 µmol/kg (uncited) | **2303.4**, GLODAPv2.2023 0–100 m volume-weighted, built as a versioned `data/` product | "Adopt 2303.4 (Recommended)" | moves with `build_carbonate_tables.R:58` and `obs_tr_box.rds$alk_tr$model_const` |
| 5 | `OCEAN_DEPTH` | 3700 m | **3682.2 m** (Charette & Smith 2010, Oceanography 23(2), Table 2; ±1.2 % 1σ) | "Adopt 3682.2 (Recommended)" | rebuild the GLODAP deep targets (`obs_glodap_deep.rds$model_layer` 2627–3700) |
| 17 | `CCX_SST_SEAS_LAG` | 1.32 mo, NH-measured, typed, applied to both hemispheres | **per hemisphere, READ from `obs_seasonal_clim.rds`**: NH 1.325, SH **1.536**. ✅ Verified 10-12: the code's SH term is −A·sin(2π(t − (3.5+L)/12)), which peaks at month 0.5 + L, and ERSSTv5's SH peak is month 2.036. ⚠ The product's stored SH `model_lag` (7.54) omits the sign flip, so read `peak_month − 0.5`, not `model_lag`. | "Per-hemisphere, read from data (Recommended)" | a second constant in BOTH cores, with a parity test |
| 20 | `FORC_NUC_NH_SHARE` | 0.95 (uncited) | **per-year NH share from the 22-country files**: 0.942 (1984) to 1.0; pooled 0.993 | "Are we already refitting? If so, do the best option scientifically. Otherwise, 0.993." (we are refitting) | becomes a forcing series in both cores; the ¹⁴C tag's 2×2 solve goes per-month. ⚠ The files have reporting gaps (SH 0 in 2010 and 2023), but the model's global total sums the same rows, so a per-year split stays consistent with it. |
| 19 | `FORC_BOMB_NH_SHARE` | 0.90 (uncited) | **FITTED**, prior U[0.77, 0.98] (⁹⁰Sr deposition to fusion yield, UNSCEAR 2000 Annex C Tables 7 / 2). Check identifiability after the refit (posterior sd, correlation with `tau_ex` and `bomb_total`); if it is not identified, fall back to a fixed proxy and say so. | asked "which is the scientifically most justified approach?", then "Fit it, prior U[0.77, 0.98] (Recommended)" | +1 fitted name. ⚠ It must differ from the nuclear share in every month the tag is used. |
| 16 | `CCX_SEAS_T_LAG` | 2.0 mo (a likelihood profile at the 08-20 arm-N mode) | **FITTED** in the refit, prior **U[0, 6] months** (logit on the box, like `kz` / `h_ml`): respiration cannot lead its temperature driver, and a lag past half a cycle aliases. NOT centred on the old 2.0, which would be circular. | "Fit it in the refit (Recommended)"; prior "Uniform [0, 6] months (Recommended)" | +1 fitted name |
| 30 | `SALINITY_REF` | 34.7 (uncited) | **computed from GLODAPv2.2023**, same layer and weighting as `ALK_SURFACE`, and adopted. ✅ Measured 10-12 with the ALK recipe (it reproduces 2303.38 exactly): **34.760** at 0–100 m, all latitudes, cos-lat cell-weighted (913 cells; +0.17 %). Over the LS domain only (\|lat\| < 57.14°) it is 35.005; the ruling says the same domain as ALK, which is all latitudes. | "Compute from GLODAP, adopt (Recommended)" | rebuild `data/carbonate_coefs.rds`; check `RHO_SEAWATER`'s S 35 against it |
| 21–22 | `P_canon` production (diagnostic only) | 2.04 atoms cm⁻² s⁻¹ | **1.88** (Kovaltsov et al. 2012, 1750–1900, verified against the PDF); note 1.75 (Roth & Joos 2013). Area 5.10066e14 m² (Moritz 2000). Avogadro and seconds-per-year READ from the registry. | "Use 1.88, note 1.75 (Recommended)" | no refit (not in the objective) |
| 11–12 | photosynthetic ε (`CCX_ALPHA_PHOTO_EPS_BIOSPHERE`, and the registry `ALPHA_PHOTO_EPS`) | live 15.6 (= Farquhar Δ 15.85); registry 18 | **16.2** in CCX's `alpha_photo = 1 − ε/1000` form, = Farquhar **Δ 16.5** (Still, Berry, Collatz & DeFries 2003, GBC 17:1006, abstract: assimilation-weighted, C4 GPP 35.3 Pg C/yr ≈ 23 %; ✅ verified 10-12 via EarthRef ERR 74609). Synthesis 16.5–16.7 ± 0.8 at Luo 2024's C4 share of 19.5 % (`notes/photo_eps_sources_2026-10-12.md`). One value, in the registry. Fix the registry errors: Lloyd & Farquhar's 14.8 is at **21 %** C4, not 25 %; the "15–18" range is in neither Still nor Suits. Document the limitation that the CO₂-fertilised net sink is C3-dominated and one ε cannot serve gross and net. The time trend (Keeling 2017) is a sensitivity case only. | asked "which is the scientifically best value?"; then "Adopt 16.2 = Still's 16.5 (Recommended)" | refit. ✅ Convention checked: Δ = ε/(1 − ε/1000), so 16.5 → 16.23. Suits 2005 (15.9 total, C3 19.2) and Ballantyne 2011's 14.8–16.5 bracket checked against the PDFs. |
| 1 | `PUMP_EPS13_ORG` | −20 ‰ (recollected) | **−22 ‰**, one constant, relative to SURFACE DIC, preindustrial, export-weighted (1σ ≈ 1.5). Anchor: Claret, Sonnerup & Quay 2021 (GBC 35:e2020GB006757, §3.2.1). Their deep-Pacific δ¹³C–PO₄ slope is −1.01 ± 0.02 ‰ per µmol/kg, so at C:P 117 remineralised OM is −20.07 ‰ vs deep DIC (✅ checked against the PDF 10-12); converted to the surface reference that is ≈ −22.0. Corroborated by export-weighted εp fits (−20.7 to −23.4), isotope models (−21.5 to −23.1) and low-latitude POC (≈ −21). Document as limitations: high-latitude export is more negative (≈ −25 to −28), and εp has risen since the 1960s. | "Focused literature search first (Recommended)", then "Adopt −22, one constant (Recommended)" | refit; first-order effect on deep-minus-surface δ¹³C ≈ −0.16 ‰ |
| 2 | `PUMP_EPS13_CARB` | +1 ‰ | **keep +1 ‰**: cite Romanek et al. 1992's calcite +1.0 vs HCO₃⁻ (via Jiménez-López 2006, secondary), with 0 to +2 as the stated range (vital effects pull it down, aragonite pushes it up). Effect ≈ ±0.02 ‰ per ‰. | "Keep +1, cite the bracket (Recommended)" | no value change |

## B. Kept, now cited (no value change)

| row | constant | ruling | Marcus, verbatim |
|---|---|---|---|
| 6 | `NPP_GLOBAL_PI` 60 | Keep. Cite TAR with its present-day caveat (his 09-29 ruling), and add Bastos et al. 2016 Table 4 (54 for 1700, an OSCAR input) and Naegler & Levin 2006 (60, a model setting) beside it. | "Keep 60, add Bastos (Recommended)" |
| 28 | `bomb_total` prior log-sd 0.10 | Keep, registered as a deliberate 3.6× inflation of N&L's log half-span (0.027): the injection shape is provisional and absorbs into the magnitude. | "Keep 0.10 as a ruled inflation (Recommended)" |
| 15 | `CCX_SEAS_PHI_EFF` | NH 75: store the MOD17 amplitude-free argmin in a data product, with a reproduction test. SH −30: register as RULED, with the 08-20r likelihood record (15.8 log-units better than −18). | "Store + test NH; rule SH (Recommended)" |
| 4, 29, 31, 23 | `ALPHA_AS_FCO3` 0.082 (Zhang 1995, 7–13 %); `FORC_FOSS_NH_SHARE` 0.9201 (EDGAR v4.3.2, read from the extract); `LIK_REP_SOURCE_D13C` −26.5 (Quay 2003 T3 midpoint, −26.55); bomb prior centre 102 (N&L midpoint 102.1; read `CCX_BOMB_REF`) | Cite as-is. | "I think I would approve all of these, unless there are any problems with that." |
| 13, 14, 24 | obliquity 23.44° (IERS 2010); +10-day phase (USNO solstice spacing; formula form after Cooper 1969, unread); `JOOS_PPM_PER` 2.123 (Joos 2013 p6) | Cite as-is. | (same) |
| 7, 18 | `NPP_FRAC_NH_ANCHOR_1750` registered as "derived"; `CCX_ENT_SEAS_PEAK_MO` read from `obs_so_pco2_seas_amp.rds` (7.496; not live) | as-is | (same) |
| 8–11, 25–27 | not live at the canonical | marked "not live", with what is on disk cited | (same) |
| borderline | priors, error-model σ's, pool structure, `gamma_diff`, `CCX_SST_RATIO_*` | registered as explicit "judgement" / "ruled" entries with their reasons; no sourcing. R13_VPDB and R14_STD citations completed; `sst_hs` sourced against the measured high-latitude SST. | "Physical constants only (Recommended)" |

**Caveats stated with the approvals (no action ruled):**
- `FORC_FOSS_NH_SHARE` is EDGAR's 1970–2012 share, held constant over 1750–2024. Pre-1970 emissions were probably more NH-concentrated, but no pre-1970 hemispheric source is on disk.
- `ALPHA_AS_FCO3` was measured at an ancestral 25-parameter mode (worth 0.020 ‰); re-measure it at the new mode.
- `LIK_REP_SOURCE_D13C` is a midpoint, not a flux weighting.

## C. Not citation items, but in the same refit
- IntCal σ: use the published Δ¹⁴C σ (column 5) from the downloaded `intcal20.14c`. Add a `download_data.R` / `MANIFEST.csv` entry, rebuild `data/obs_d14c_intcal20.rds`, and stop depending on `rintcal`.

## D. Open before implementation
- ✅ **RULED 2026-10-12 (session e): how the values reach the objective.** A NEW structure label carries every changed value and the two new fitted names; an absent field = the old value, so `hilda29e` and every registered mode stay bit-exact (the `hilda_c` / objective-#18 idiom). Versioned data files (carbonate coefficients, deep targets, IntCal) are selected by the label. Marcus, verbatim: "New label (a) (Recommended)"; the name **`hilda_csl3v0kaidgbemwtc`** ("…wtc (c = cited)").
- Where the refit runs (Torch or the Mac), stated out loud per the standing rule.
