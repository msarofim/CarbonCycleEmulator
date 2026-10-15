# Shape of CO2 fertilization saturation: literature + CMIP6 check

Compiled 2026-09-28 by a research subagent for Marcus; arithmetic and the CMIP6 summary spot-checked by the main session (identity, R/K values, the (1.34, 580) row, and the median R, all reproduced) for the CCX Michaelis-Menten (MM) fertilization factor
`NPP/NPP0 = 1 + beta_max * d/(fert_k + d)`, `d = CO2 - 278 ppm`.

Status labels: **V** = verified in the full text (location given). **A** = abstract only.
**R** = recollection, unverified. **C** = my own computation (script and inputs listed in section 4).

---

## 1. Source table

| # | Source (year) + DOI | Quantity | CO2 range | Number ± unc. | Where | Status |
|---|---|---|---|---|---|---|
| 1 | Arora et al. 2020, *Biogeosciences* 17:4173, doi:10.5194/bg-17-4173-2020 | land beta_L = ΔC_land(BGC)/ΔCO2, cumulative land C (PgC/ppm), 1pctCO2 BGC-COU approach | 2x (yr 70) and 4x (yr 140) | CMIP6 (11 models): **1.22 ± 0.40 at 2x → 0.97 ± 0.40 at 4x** (mean ± sample SD). CMIP5 (8): 1.15 ± 0.63 → 0.93 ± 0.49 | Table A1 | V |
| 1a | same | as above, split by N cycle (my split, using Arora's list of the 6 N-cycle models: ACCESS-ESM1.5, CESM2, MIROC-ES2L, MPI-ESM1.2-LR, NorESM2-LM, UKESM1-0-LL) | 2x, 4x | N: 1.03 → 0.78. No-N: 1.44 → 1.20. Cumulative ΔC_land(4x)/ΔC_land(2x) = beta4·3/beta2: mean **2.35** (range 1.48 ACCESS to 2.98 CNRM). N 2.25, no-N 2.48 | Table A1 → C | V + C |
| 1b | same | qualitative: N-cycle models have lower beta_L. Arora notes that land and ocean sinks both weaken "relatively" as CO2 rises | — | — | Abstract; Sect. 4.2 | V |
| 2 | Varney et al. 2024, *Biogeosciences* 21:2759, doi:10.5194/bg-21-2759-2024 | beta_NPP = the NPP-driven part of the soil-C concentration feedback (≈ τs0·ΔNPP/ΔCO2, PgC/ppm), 10 CMIP6 ESMs, 1pctCO2-BGC | 2x vs 4x | **2.37 ± 1.37 at 2x → 1.44 ± 0.93 at 4x**. The authors call this "some evidence of a saturation of global NPP". Ratio of secant slopes 0.61 ⇒ ΔNPP(4x)/ΔNPP(2x) ≈ 1.82 (my arithmetic, a ratio of ensemble means) | Sect. 3.3, p. 2767 | V |
| 3 | **This note: CMIP6 1pctCO2-bgc global GPP, 16 ESMs** (Pangeo GCS zarr) | GPP(C)/GPP(C0), transient at 1 %/yr, CO2 only (radiation sees the PI value) | 284→1137 ppm | **2x: +42.9 ± 16.2 %; 4x: +76.2 ± 31.0 %; 400→564: +16.9 ± 6.2 %** (mean ± SD). **R = ΔGPP(4x)/ΔGPP(2x): median 1.81, range 1.11–2.15; 15 of 16 models below 2.0 (the log value); only UKESM1 (2.15) is above**. Elasticity dlnGPP/dlnCO2 is 0.57 over 284→400 and falls to 0.29 over 2x→4x. MM fits beat log fits (lower RMSE) in all 16 models. Fitted MM K: median ≈ 580 ppm (range 123–1172) | Sect. 4 | C |
| 3a | same, split by N cycle | same | same | N (8): 2x +34.3 ± 14.4 %, 4x +62.6 ± 29.5 %, 400→564 +13.6 ± 6.0 %, R median 1.79. No-N (8): +51.5 ± 13.5 %, +89.9 ± 27.5 %, +20.1 ± 4.7 %, R median 1.82. **N limitation lowers the amplitude, not the shape** | Sect. 4 | C |
| 4 | Kou-Giesbrecht et al. 2025, *PNAS* 122, doi:10.1073/pnas.2514628122 | GPP(2x)/GPP(1x), 39 ESMs. Uses "1pctCO2" (years 68–72 over years 8–12). It is not stated whether this is the -bgc run or the fully coupled run | 284→565 | All 1.38 (range 1.26–1.50). No-N 1.45 (1.38–1.51). With N 1.33 (1.20–1.46). A BNF observational correction lowers these by ~11 % (8 % N, 15 % no-N) | Results/Methods via PMC full text. The meaning of "range" is not explicit | V (text) |
| 5 | Wenzel, Cox, Eyring & Friedlingstein 2016, *Nature* 538:499, doi:10.1038/nature19772 | GPP increase at 2x, emergent constraint from CO2 seasonal amplitude, CMIP5 | 2x | **High-latitude 37 ± 9 %; extratropical 32 ± 9 %**. Model range is 20–60 % | Abstract (PubMed) | A |
| 6 | Haverd et al. 2020, *GCB* 26:2390, doi:10.1111/gcb.14950 | global GPP, CABLE-POP with photosynthetic coordination, constrained by leaf-to-global observations | 296→389 (1900–2010); 300→600 | Historic **+30 %** (TRENDYv6 17 ± 4 %, 1σ). **+47 ± 2 % for 300→600** at constant climate and land use (NH >30°N: 42 ± 2 %, 1 SE). **Leaf elasticity falls with CO2** over 400→800 ppm at 25 °C: 37 %→19 % (Wang 2017 algorithm), 35→17 % (CABLE without coordination), 56→34 % (full CABLE) | Results; Discussion | V (PMC) |
| 7 | Walker et al. 2021, *New Phytol.* 229:2413, doi:10.1111/nph.16866 | β = ln(y_e/y_a)/ln(CO2_e/CO2_a) (a log-log elasticity) | 280–400; 400–550 | **Theory, canopy GPP: 0.60 ± 0.3 (280–400) → 0.46 ± 0.2 (400–550)**. Light-saturated leaf 0.86 and light-limited leaf 0.31 (280–400). FACE light-saturated leaf Asat 0.73 ± 0.2 (C3 0.79). **FACE biomass production 0.56 ± 0.2 (Norby 2005, early years); 0.49 ± 0.3 (decade, Walker 2019)**. Mature forests −0.3 to +0.55. Observed GPP concurrent with iCO2 β_app ≈ 1.2, "about half" of which theory can explain | Sect. II.1, III.1–2 (OSTI accepted MS) | V |
| 8 | Chen, Riley, Prentice & Keenan 2022, *PNAS* 119:e2115627119, doi:10.1073/pnas.2115627119 | direct log response β_ln of GPP, eco-evolutionary optimality framework on FLUXNET | 2001–2014 | **β_dir,ln = 0.61** (cf. FACE light-saturated 0.79; theory 0.6). Apparent β_app,ln 1.12–1.24 | Results (PMC) | V |
| 9 | Keenan et al. 2023, *Nat. Clim. Change*, doi:10.1038/s41558-023-01867-2 | CO2-driven global GPP increase, emergent constraint + optimality + RS | 1981–2020 (≈340→412 ppm, R) | **+13.5 ± 3.5 % (s.d.), 15.9 ± 2.9 PgC/yr**. Implied elasticity ≈ 0.66 (my arithmetic, using the recollected CO2 values) | Abstract (NSF PAR) | A |
| 9x | Keenan et al. 2021, *Nature* 600:253 | 11.85 ± 1.4 % (1981–2020) | — | **RETRACTED 2022** (doi:10.1038/s41586-022-04869-w). Superseded by #9. Do not cite | PubMed | V (retraction) |
| 10 | Terrer et al. 2019, *Nat. Clim. Change* 9:684, doi:10.1038/s41558-019-0545-2 | plant biomass (not GPP/NPP), 138 eCO2 experiments + N/P/mycorrhiza upscaling | "CO2 levels expected by 2100" (level not seen) | **+12 ± 3 % above current biomass, 59 ± 13 PgC**. N limits ~65 % and P ~25 % of vegetation | Abstract (Maastricht repository page) | A. The CO2 end-point and the comparison to CMIP5 are **R** |
| 11 | Wang S. et al. 2020, *Science* 370:1295, doi:10.1126/science.abb7772 | "CFE" decline 1982–2015 from satellite/ground data | 1982–2015 | Qualitative: CFE declined, and models show a weaker decline. **Three published comments (Science 2021) dispute it** | Abstract | A |
| 12 | Meinshausen et al. 2011 (MAGICC6), *ACP* 11:1417, doi:10.5194/acp-11-1417-2011 | functional form of simple-model fertilization | — | log `1+βs ln(C/C0)` (βm=1) or Gifford rectangular hyperbola `N ∝ (C−Cb)/(1+b(C−Cb))`, **Cb = 31 ppm** (βm=2), or a linear blend. βs is defined as the NPP ratio 340→680 ppm. "Previous MAGICC versions ... used the second as default." **Emulating 10 C4MIP models: βm ≥ 1.8 (mostly hyperbolic) in 6 of 10; βs 0.17–1.05** | App. A1.1 Eqs. A15–A20; Table B4 | V |
| 13 | Hector (JGCRI), `src/simpleNbox.cpp` + `inst/input/hector_ssp245.ini`, GitHub main branch as of 2026-09-28 (latest release v3.5.5) | NPP fertilization | — | `co2fert = 1 + beta*log(CO2/C0)` (pure log). **Default beta = 0.65** ("calibrated to historical observations, see PR 789"). A commented alternative pf/non-pf value is 0.53 | source code | V (code, not paper) |
| 14 | Joos et al. 2013, *ACP* 13:2793, doi:10.5194/acp-13-2793-2013 (local PDF) | simple-model settings in the IRF MIP | — | Bern-SAR: log NPP, **β = 0.27**. DCESS: β recalibrated 0.65 → **0.37**. ACC2, Bern-SAR, DCESS, MAGICC6, TOTEM all use a "simple logarithmic dependency of NPP on CO2" | Sect. 2, model descriptions (Appendix) | V |
| 15 | Gasser et al. 2017 (OSCAR v2.2), *GMD* 10:271, doi:10.5194/gmd-10-271-2017 | functional form | — | Ffert is either log (1 parameter) or hyperbolic (β̃ plus compensation point CO2cp), calibrated on CMIP5 1pctCO2/esmFixClim/esmFdbk1. The **form itself is a Monte-Carlo structural choice** | Sect. 2.3.2, Eq. 9 | V |
| 16 | Farquhar–von Caemmerer–Berry 1980 with Bernacchi et al. 2001 25 °C constants (Kc 404.9 µmol/mol, Ko 278.4 mmol/mol, Γ* 42.75 µmol/mol) | leaf A vs Ca, assuming Ci = 0.7 Ca | 278→1112 | Rubisco-limited: effective Km(Ci) ≈ 710 ppm (≈1015 ppm in Ca). 2x +88 %, 4x +194 %, R = 2.22. RuBP-regeneration-limited: 2x +35 %, 4x +57 %, **R = 1.65** | my computation | C, with constants **R** |
| 17 | Norby 2025 / Norby 2005 / EucFACE / BIFoR (Marcus's file) | NPP, temperate forest FACE | ~+150–200 ppm | as on file. Walker #7 gives the Norby 2005 β = 0.56 ± 0.2 | — | per Marcus's file |
| 18 | Zaehle et al. 2014, *New Phytol.* doi:10.1111/nph.12697 | 11 C-N models vs Duke/ORNL FACE NPP | FACE | Most models reproduced the initial NPP enhancement. None captured both the sustained Duke and declining ORNL responses (progressive N limitation) | Abstract | A. No shape number |

Not covered with numbers: Kovenock & Swann 2018 (leaf-trait acclimation; about radiative/LAI feedbacks, not the NPP-vs-CO2 shape). Zaehle et al. 2015 J. Clim and Wieder et al. 2015 Nat. Geosci. (Semantic Scholar returned no abstract). Mankin et al. 2025 J. Clim (about BGC×RAD non-additivity, not fertilization shape). I also found no MAGICC7 or FaIR default: my recollection (**R**) is that FaIR 2.x has no explicit fertilization term and represents land+ocean uptake saturation through the state-dependent iIRF100 (r0 + ru·G_uptake + rT·T + ra·G_atm).

---

## 2. Translation into CCX terms

### 2.1 Key algebraic facts
- **Shape metric R = ΔX(4x)/ΔX(2x)**, with ΔX measured from the PI value. Linear gives 3.0 and log gives 2.0. For MM in d = CO2 − C0, R = 3(K+C0)/(K+3C0), so **K = 3C0(R−1)/(3−R)**. **Log over 1x–4x is equivalent to MM with K ≈ 3C0 ≈ 834–855 ppm.** CCX's fitted fert_k = 825–940 is therefore essentially logarithmic in shape: R = 1.99 at (1.3, 825) and 2.06 at (2.7, 940).
- **The Gifford/MAGICC rectangular hyperbola is exactly CCX's MM form** with the constraint **K = (C0 − Cb)(1 + beta_max)**. With Cb = 31 ppm: β_max 1.0 → K 494; 1.34 → 578; 2.0 → 741; 2.7 → 914. So MAGICC's hyperbola ties the two parameters that the historical record cannot separate. CCX's high-β end (2.7, 940) sits on that line.
- The elasticity ε = dlnNPP/dlnCO2 is the quantity Walker 2021 and Chen 2022 report.

### 2.2 Implied numbers (from the CCX form; C0 = 278)

| Parameterization | 400→564 | 2x | 4x | R | ε 278–400 | ε 400–564 | β_max (∞) |
|---|---|---|---|---|---|---|---|
| CCX fit, low (1.3, 825) | +14.3 % | +33 % | +65 % | 1.99 | 0.43 | 0.39 | +130 % |
| CCX fit, high (2.7, 940) | +24.4 % | +62 % | +127 % | 2.06 | 0.74 | 0.64 | +270 % |
| **CMIP6-GPP-central equivalent (1.34, 580)** | **+17.0 %** | **+43 %** | **+79 %** | **1.82** | **0.58** | **0.46** | +134 % |
| ACCESS-ESM1.5 fit (0.56, 192): N+P, strongest saturation | +9.6 % | +33 % | +45 % | 1.37 | 0.54 | 0.27 | +56 % |
| UKESM1 fit (2.09, 1172): least saturating | +17.8 % | +40 % | +87 % | 2.17 | 0.49 | 0.48 | +209 % |
| Hector log β = 0.65 | +18.1 % | +45 % | +90 % | 2.00 | — | — | ∞ |
| Bern-SAR log β = 0.27 | +8.4 % | +19 % | +37 % | 2.00 | — | — | ∞ |

The (1.34, 580) row reproduces the CMIP6 ensemble's mean 2x (+43 %), 4x (+76 %, vs +79 %), 400→564 (+16.9 %) and elasticities (0.57 → 0.29 over 2x→4x) all at once. Its ε decline, 0.58 → 0.46, **matches Walker 2021's theoretical canopy values of 0.60 → 0.46**. That the point also falls on the Cb = 31 Gifford line (K = 578) is a coincidence, not a constraint.

### 2.3 What the evidence supports
- **Shape (R):** CMIP6 GPP gives a median of 1.81 with 15 of 16 models below 2.0. Varney's ensemble NPP ratio of means gives ≈1.82. Canopy-mix physiology is between the Aj (1.65) and Ac (2.22) values; Walker's canopy elasticity decline 0.60 → 0.46 implies R below 2. **Across these sources R ≈ 1.6–2.0 with a central value ≈ 1.8, i.e. K ≈ 450–850 ppm with a central ≈ 580 ppm.** CCX's K = 825–940 sits at the linear (log-like) edge of that range. Only 3 of 16 CMIP6 models are that log-like or more linear: UKESM1 (R 2.15), CNRM (1.99) and GISS (1.98).
- **Amplitude at 400→564:** CMIP6 GPP +16.9 ± 6.2 % (N models +13.6, no-N +20.1). Walker theory ε 0.46 gives (564/400)^0.46 − 1 = +17 %. The FACE biomass production β 0.49–0.56 gives +18–21 % (my arithmetic, same power law). CCX's range of +14–25 % therefore overlaps the evidence, but **its upper half (> ~21 %) is above everything except no-N CMIP6 models**.
- **At 2x:** Haverd 2020 (a high-side, coordination-enabled model) +47 ± 2 %. CMIP6 GPP +43 ± 16 %. Kou-Giesbrecht ESMs +38 % (BNF-corrected ≈ +34 %). Wenzel constraint (extratropics/high latitudes, CMIP5) 32–37 ± 9 %. **Central ≈ +35–45 % GPP at 2x.**
- **At 4x:** only the models speak: CMIP6 GPP +76 ± 31 % (N +63 %, no-N +90 %). There is no observational constraint above ~560 ppm.
- **Historic (for the fitting period):** Keenan 2023 gives +13.5 ± 3.5 % GPP for 1981–2020. The CMIP6-central MM gives +10.8 %, CCX-low +8.3 % and CCX-high +14.5 %. So the historic GPP constraint mildly favors the higher-amplitude CCX end, while the shape evidence favors a lower K. Together they point to **something like β_max ≈ 1.3–2.0 with K ≈ 500–750** rather than the (β_max, K) ridge CCX found. Treat this as a hypothesis, since the historic number is GPP and not NPP (see caveats).

### 2.4 Assumptions and caveats in the translation
1. **GPP vs NPP.** Most numbers are GPP. CCX applies the factor to NPP. Using GPP% as NPP% assumes constant CUE. Arora 2020 (Sect. 4.3) shows CUE₁ = ΔNPP/ΔGPP varies strongly across models (CanESM5 highest, ACCESS lowest), so model NPP% can differ from GPP%. Only GFDL-ESM4 publishes `npp` in 1pctCO2-bgc on Pangeo, so I could not do the NPP version across the ensemble. Varney's β_NPP ratio (≈1.82) is the only ensemble NPP-shape number, and it agrees with the GPP R.
2. **Transient vs instantaneous.** The 1pctCO2-bgc GPP includes lagged LAI and vegetation-cover build-up (Arora notes GFDL, MPI and UKESM expand cover). Lag moves response towards later, higher CO2, which **biases R upwards (towards linear)**. The instantaneous physiological saturation is therefore probably at least as strong as R ≈ 1.8. Haverd's historic elasticity (0.96 over 296→389) against its doubling value (0.56) shows how much greening/LAI can inflate apparent early responses.
3. **Land carbon ≠ NPP shape.** Arora's cumulative-land-C ratio R = 2.35 (N 2.25, no-N 2.48) is **higher** than the flux R of ~1.8 because the pools are far from equilibrium at 1 %/yr: stock growth lags the flux. It should not be used to set fert_k. At equilibrium with fixed turnover, ΔC_land/C_land0 = ΔNPP/NPP0.
4. **Nutrients.** N limitation lowers the amplitude by roughly a third at 2x (CMIP6 GPP: 34 % vs 52 %). The shape (median R 1.79 vs 1.82) is unchanged in CMIP6. The single N+P model (ACCESS) is the strongest saturator (R 1.43). Terrer 2019's biomass +12 ± 3 % "by 2100" is a biomass stock, not a flux.
5. **Temperate FACE** (Marcus's ruling) informs limits only. Walker's FACE biomass β values are consistent with the CMIP6-central amplitude.

---

## 3. Open questions and conflicts
- **Historic vs doubling elasticity (Haverd).** An elasticity of 0.96 historically against 0.56 for 300→600 implies either very strong saturation or a historic signal inflated by non-CO2 drivers or greening. Walker 2021 (Sect. III.1) says the observed GPP β_app ≈ 1.2 is about twice the theory value of 0.6 and needs "additional positive feedbacks". Unresolved.
- **Direction of the historic GPP constraint.** Keenan 2023 (+13.5 %) and Haverd (+30 % since 1900, "nearly twice" TRENDY's 17 %) are high relative to CMIP6-central. Wang 2020 claims a declining CFE, which is disputed.
- **ESM amplitude may be too high.** Kou-Giesbrecht 2025 says overestimated BNF inflates the ESM CO2 effect by ~11 %. Terrer 2019 finds nutrient limits over ~65 % (N) and ~25 % (P) of vegetation.
- **IPSL-CM6A-LR** GPP rises +51 % by 2x and is then flat or declining to 4x (R = 1.11). This is suspicious and may be a model artifact, e.g. vegetation-cover or water stress in the bgc run. I did not investigate. The median R is robust to it: dropping IPSL moves it from 1.81 to about 1.82.
- **BCC-CSM2-MR** weights were cos(lat) only (no fx on Pangeo), and **NorESM2-LM / EC-Earth3-CC** used areacella without sftlf. Ratios are only mildly affected, but their absolute G0 values are wrong. Do not use those absolute values.
- **N-cycle labels for EC-Earth3-CC (LPJ-GUESS) and CMCC-ESM2 (CLM4.5)** are my recollection (**R**). Arora 2020 lists only its 11 models.
- **Kou-Giesbrecht's 1.38**: it is not confirmed whether this is 1pctCO2 or 1pctCO2-bgc. If it is fully coupled, warming is included.
- Not found: MAGICC7's current default βm/βs, and any CMIP7/C4MIP-7 successor to Arora 2020. My searches found none published by 2026-09.

---

## 4. Provenance of my computation (source #3)
- Data: Pangeo CMIP6 catalog `https://storage.googleapis.com/cmip6/pangeo-cmip6.csv`, downloaded 2026-09-28. Variable `gpp`, table Lmon, experiment `1pctCO2-bgc`, first member alphabetically per model. 16 models (CanESM5 and CanESM5-CanOE both counted). The zstore versions are listed in `notes/lit_2026-09-28_cmip6_gpp/gpp_1pctCO2-bgc_global_annual.csv` and `/Users/MarcusMarcus/Documents/2026/ClaudeDocs/ccx_lit_scripts/20260928_cmip6_gpp/gpp.log`.
- Global sum weighting: areacella × sftlf/100 where the fx fields exist on the same grid. Otherwise as noted above.
- CO2(t) = 284.317 × 1.01^(t+0.5) for 0-indexed annual means. G0 is a linear fit over years 0–10, extrapolated to C0. Values at 400, 564, 2x and 4x come from local linear fits over ±5 yr. Years used: 0–139.
- Fits: MM `G0(1+b·d/(K+d))` and log `G0(1+β ln(C/C0))` by scipy curve_fit.
- Scripts (Python, kept OUTSIDE this R-only repo): `/Users/MarcusMarcus/Documents/2026/ClaudeDocs/ccx_lit_scripts/20260928_cmip6_gpp/gpp_bgc.py` (extraction) and `/Users/MarcusMarcus/Documents/2026/ClaudeDocs/ccx_lit_scripts/20260928_cmip6_gpp/analyse.py` (shape). Output is `notes/lit_2026-09-28_cmip6_gpp/gpp_shape_summary.csv`. ⚠ If any of these numbers enters the MODEL (a prior, a gate), it needs an R `data-raw/` script with URL, access date and checksum first (hard rule 3). The analysis was run twice with byte-identical output (md5 6590f830…). No RNG is involved.
