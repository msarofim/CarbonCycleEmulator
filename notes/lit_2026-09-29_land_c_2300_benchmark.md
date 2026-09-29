# Literature benchmark: total land carbon change to 2100 / 2300 under high forcing

Date: 2026-09-29. Purpose: a cited yardstick for CCX's two candidate calibrations, which give land
carbon at 2300 under the van Vuuren CMIP7 'H' marker of ~2.27x preindustrial (phi=0.5) vs ~1.65x
(phi=0). CCX preindustrial land total ~2130 GtC (value supplied by the caller, not re-derived here).

Status labels: **verified** = number read in the full text opened this session (PDF text extracted
with pdftotext); **abstract-only**; **computed** = arithmetic by me, shown below. PgC = GtC.

## Summary table

| # | Source (vintage) | Model(s) | Scenario | Forcing mode | CO2 2100 / 2300 (ppm) | Land C change to 2100 (PgC) | Land C change to 2300 (PgC) | Base (scope) | Multiple of PI | Status | Locator |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Koven et al. **2022**, ESD 13:885, doi:10.5194/esd-13-885-2022 | CanESM5, CESM2-WACCM, CNRM-ESM2-1, IPSL-CM6A-LR, UKESM1-0-LL (CMIP6) + UVic-ESCM 2.10 (EMIC) | SSP5-8.5 + extension | **Concentration-driven**, with LUC forcing; land use held constant after 2100 | 1135.2 / 2161.7 (from #5) | 1850–2100 (hist + 2015–2100 cumulative land sink): CanESM5 541, CESM2-W 264, CNRM 478, IPSL 205, UKESM1 122, UVic 102; mean 285 **(computed)** | 1850–2300: CanESM5 197, CESM2-W 508, CNRM 83, IPSL −112, UKESM1 43, UVic −253; mean 78 **(computed)** | Not given in Koven. Base taken from #3 (cVeg + cSoil + cLitter, 1986–2005), back-shifted by Koven's 1850–2015 sink — see arithmetic | 2100: 1.04–1.27; 2300: 0.89–1.28 **(computed)** | Period sums **verified** (Table B1); cumulative totals and multiples **computed** | Table B1 (App. B); Sect. 3.2; Fig. 1c |
| 1b | Koven et al. 2022 (same) | same six | SSP5-3.4-OS + extension | Concentration-driven | 496.6 / 398.5 (from #5) | 1850–2100: CanESM5 163, CESM2-W 121, CNRM 393, IPSL 195, UKESM1 78, UVic 53 **(computed)** | 1850–2300: 12, 60, 362, 141, 71, −48 **(computed)** | as row 1 | not computed | as row 1 | Table B1 |
| 2 | Arora et al. **2020**, Biogeosciences 17:4173, doi:10.5194/bg-17-4173-2020 | 11 CMIP6 ESMs (C4MIP); 8 CMIP5 for comparison | 1pctCO2, idealized, **no LUC** | Concentration-driven, fully coupled (COU) | 4xCO2 at yr 140 ≈ 1140 (4 × "around 285 ppm", **computed**) | Cumulative land uptake at 4xCO2: CMIP6 **635 ± 258** (mean ± sample SD); 578 ± 185 without CanESM5; CMIP5 505 ± 297 | n/a | Change from preindustrial control | n/a (no per-model base in paper) | **verified** | Sect. 4.1 (p. 4183) and 4.2 (p. 4185); Table A1: β_L = 0.97 ± 0.40 PgC/ppm at 4x, 1.22 ± 0.40 at 2x |
| 3 | Gier et al. **2024**, arXiv:2402.05671v1 (preprint; the EGUsphere discussion version is egusphere-2024-277) | CMIP5/CMIP6 ESMs | historical | c = concentration-driven, e = emission-driven | n/a | n/a | n/a | **Land stocks, 1986–2005 mean**: CanESM5c 513 veg + 1486 soil+litter; CESM2-WACCMc 574 + 1201 (**soil top 1 m only**, cSoilAbove1m); CNRM-ESM2-1c 719 + 2281; IPSL-CM6A-LRc 352 + 649; UKESM1-0-LLc 705 + 2118; obs (HWSD+NCSCD) 478 + 1561 | — | **verified** | Supplement Table S7; Sect. on carbon stocks (text lines on cSoilAbove1m) |
| 4 | Lee et al. **2025**, ESD 16:1427, doi:10.5194/esd-16-1427-2025 | CESM2-LE (CLM5), 10 members | SSP3-7.0 + extension to 2500 | **Concentration-driven** | 2300: 1482.8 (from #5); paper: peak ~1515 ppm ~2240, ~1371 at 2500 | Terrestrial stocks "856 PgC in 2000 to 2288 PgC in 2200", then 2079 by 2500. Vegetation 494 (2000) → 873 (2200) → 900 (2250) then slight decline | not stated for 2300 in text (Fig. 8 only) | Stocks, veg + soil, from 2000; PI value not given in text | not computed — see caveat | **verified** (text), numbers flagged | Sect. 4 text on Fig. 8 (p. 1437) |
| 5 | Meinshausen et al. **2020**, GMD 13:3571, doi:10.5194/gmd-13-3571-2020 | MAGICC7 (concentrations used by #1, #4) | SSP extensions | — | SSP5-8.5: 1135.2 / 2161.7 (peak 2206.4 in 2250); SSP3-7.0: 867.2 / 1482.8; SSP5-3.4-OS: 496.6 / 398.5 | — | — | — | — | **verified** | Table 5 (global means) |
| 6 | Friedlingstein et al. **2014**, J. Climate 27:511, doi:10.1175/JCLI-D-12-00579.1 (**oldest verified source in this stack**) | 11 CMIP5 ESMs | RCP8.5 to 2100 only | **Emission-driven** (esmrcp85) | 2100: 985 ± 97 (range 794–1149) | 1850–2100 cumulative land uptake: mean **91 ± 218** (8 ESMs that simulate the net land flux incl. LUC); range **−173 to +352** for those 8; −173 to +758 for all 11 | n/a | Change from preindustrial | n/a | **verified**; minus signs restored from the text ("cumulative source of 165 PgC to a cumulative sink of 758 PgC") because pdftotext dropped them in Table 3 | Table 3; Sect. 5 |
| 7 | Randerson et al. **2015**, GBC 29:744, doi:10.1002/2014GB005079 | CESM1(BGC) | RCP8.5 + extension to 2300 | Concentration-driven, with three coupling configurations | not read | not read | **Climate effect only** (difference between coupling configurations, not the total change): climate change reduced land stocks by 232 PgC by 2300; warming 9.3 K 1850–2300 | — | — | **abstract-only** (Wiley PDF blocked by a Cloudflare challenge) | Abstract |

### Arithmetic for the Koven multiples (computed)

Δ(1850→2100) = hist(1850–2015) + sink(2015–2100); Δ(1850→2300) adds sink(2100–2200) + sink(2200–2300).
All from Koven Table B1 ("land sink", PgC; positive = uptake).

PI_est = B(1986–2005, Gier Table S7) − hist(1850–2015, Koven Table B1). Multiple = (PI_est + Δ)/PI_est.

| Model | B | hist | PI_est | Δ2100 | Δ2300 | x2100 | x2300 |
|---|---|---|---|---|---|---|---|
| CanESM5 | 513+1486 = 1999 | −9 | 2008 | 541 | 197 | 1.269 | 1.098 |
| CESM2-WACCM | 574+1201 = 1775 | −41 | 1816 | 264 | 508 | 1.145 | 1.280 |
| CNRM-ESM2-1 | 719+2281 = 3000 | 136 | 2864 | 478 | 83 | 1.167 | 1.029 |
| IPSL-CM6A-LR | 352+649 = 1001 | 25 | 976 | 205 | −112 | 1.210 | 0.885 |
| UKESM1-0-LL | 705+2118 = 2823 | −1 | 2824 | 122 | 43 | 1.043 | 1.015 |
| UVic-ESCM | not in Gier | 17 | — | 102 | −253 | — | — |

Base caveats: (a) B is a 1986–2005 mean, while hist runs to 2015, so PI_est is off by the model's
~1996–2015 land sink (tens of PgC; <5 % of B for every model above). (b) CESM2-WACCM's B uses soil
carbon above 1 m only; its full-column soil pool is larger, so its multiple is overstated. (c) Gier's
values come from the concentration-driven historical run (suffix "c"), a different ensemble member
from Koven's runs. (d) Koven's "land sink" in a concentration-driven run with LUC forcing includes
land-use emissions inside the net flux (Koven Sect. 2.1); post-2100 land use is held constant.

### Sink → source (Koven 2022, Sect. 3.2, verified)

Under SSP5-8.5 every model switches from net sink to neutral or source. Timing runs from ~2100 in
UVic-ESCM to ~2220 in CESM2-WACCM. Ensemble cumulative land sink: 264 ± 172 (2015–2100),
−29 ± 264 (2100–2200), −178 ± 251 (2200–2300) PgC. CanESM5 loses 650 PgC over 2200–2300.
In Lee 2025 (CESM2, SSP3-7.0) land shifts "from a carbon sink to a carbon source after the 22nd
century", driven by soil (permafrost) loss. Friedlingstein 2014: by 2100 under emission-driven
RCP8.5, CESM1-BGC, NorESM1-ME and MIROC-ESM already simulate a cumulative land source.

### Vegetation vs soil

- Koven 2022: split shown only as zonal means (Fig. 6). No global veg/soil totals in the text or
  tables, so it is **not quantified here**.
- Lee 2025 (CESM2, SSP3-7.0): vegetation 494 → 873 PgC (2000 → 2200), peak 900 in 2250. The
  post-2200 decline in total is "largely driven by changes in soil carbon stocks".

## What the range implies for 2.27x vs 1.65x (numbers only)

- CCX increment implied: 2.27x ⇒ +1.27 × 2130 = **+2705 GtC**; 1.65x ⇒ +0.65 × 2130 = **+1385 GtC** (computed).
- Koven 2022 CMIP6 + EMIC, SSP5-8.5, CO2 2162 ppm at 2300: Δland(1850–2300) = **−253 to +508 PgC**
  (mean 78). Multiples 0.89–1.28 (5 ESMs, computed).
  - The largest ESM increment (508) is 0.37 of the 1.65x increment and 0.19 of the 2.27x increment (computed).
  - At 2100, the largest ESM increment (CanESM5, 541) is 0.39 of the 1.65x increment (computed).
- Arora 2020, idealized 1pctCO2 at ~1140 ppm with no LUC or non-CO2 forcing: 635 ± 258 PgC.
  Mean + 2 SD = 1151 PgC, i.e. 0.83 of the 1.65x increment (computed). As a multiple of CCX's own base
  (2130), the mean is 1.30x and mean + 2 SD is 1.54x (computed). This applies CCX's base to ESM
  increments, so it is not like-for-like: ESM bases range ~1000–3000 PgC (Gier Table S7).
- Friedlingstein 2014, emission-driven RCP8.5 to 2100: 91 ± 218 PgC (8 models with LUC), maximum 352.
- Linear β_L check, **not a projection** (computed): β_L(4x) 0.97 PgC/ppm × (2162 − 285) ppm = 1821
  PgC. Arora Table A1 shows β_L falling from 1.22 at 2x to 0.97 at 4x, so extrapolating to ~7.6x
  overstates it. This excludes the carbon–climate loss: γ_L = −45 ± 51 PgC/°C at 4x (CMIP6 mean ± SD).
- No ESM or EMIC value found in this session reaches 1.65x at 2300. The highest computed 2300 value
  is 1.28x (CESM2-WACCM, and that base is top-1 m soil only).

Like-for-like flags: #1 and #4 are concentration-driven, while CCX under a vV marker is presumably
emission-driven. Emission-driven ESM runs to 2300 were not found. The vV 'H' marker's CO2 at 2300
was not looked up; compare it with SSP5-8.5's 2161.7 ppm and SSP3-7.0's 1482.8 ppm before reading
the Koven/Lee rows as matched forcing. It is also unknown whether CCX's 2130 GtC base includes
permafrost and deep soil. ESM bases differ in scope: Gier's CLM5 soil is top 1 m, and CESM2 and
UVic carry some permafrost carbon (Koven Sect. 2.1.1).

## Could NOT be verified

- **Tokarska et al. 2016**, Nat. Clim. Change 6:851, doi:10.1038/nclimate3036 (RCP8.5 extension, 5 EgC): paywalled; Semantic Scholar marks the abstract as elided by the publisher. No numbers used. Koven 2022 states its sink-to-source transition is "qualitatively consistent" with Tokarska.
- **Zickfeld et al. 2013**, J. Climate 26:5782, doi:10.1175/JCLI-D-12-00584.1 (EMIC RCP extensions to 2300): AMS site returned 403 / CloudFront error, and the listed bronze-OA PDF came back empty. I read only the abstract (via DTU Orbit), which has no land-carbon numbers.
- **Randerson et al. 2015** full text (total land change, CO2 path, veg/soil split): blocked. Only the abstract's −232 PgC climate effect is used.
- **Lee et al. 2025 total-stock numbers look internally inconsistent.** The text gives total terrestrial carbon of 856 PgC in 2000 and vegetation of 494 PgC in 2000, which implies soil of only ~362 PgC. Gier Table S7 gives CESM2 top-1 m soil+litter ≈ 1000 PgC. The total then rises to 2288 PgC by 2200 while vegetation gains only 379. The 856 figure may be a typo, but I did not check Fig. 8 digitally, so no multiple is computed from Lee 2025.
- Koven 2022 global vegetation vs soil split: shown in the figure only, not in tabulated numbers.
- DGVM / LPJ-family runs to 2300 under high emissions: none found in one search round.
- Emission-driven ESM land-carbon trajectories to 2300 (e.g. ZECMIP, CMIP7 esm-scen extensions): not found or not checked. ZECMIP (MacDougall et al. 2020) was not opened.
- Per-model preindustrial land stocks: Gier's 1986–2005 values were used as a proxy (see base caveats). Arora 2020 does not tabulate model pools.
- Local ClaudeDocs/Papers had none of these papers.

---

## CORRECTION (main session, 2026-09-29): the CCX side of the comparison

The research brief named the wrong scenario. The 2.27× / 1.65× figures come from **SSP5-8.5**, not the
van Vuuren H marker (CHANGELOG 2026-09-29 (b); `outputs/diagnostics/phi0_futures_ssp_20260929.log`):

- **Base.** Total land (every CCX land pool) goes 2130 → 4830 GtC at `hilda29l` (φ 0.5). The φ = 0 basin-1
  arm reaches 1.65×.
- **Forcing.** Emission-driven, with the SSP's own land-use history. That history is **not** GCB-spliced and runs
  about 90 GtC short (handoff 09-29 §5), which biases CCX's land slightly HIGH.
- **CCX CO₂ at 2300.** **875 ppm** (`hilda29l`) and **1374 ppm** (φ = 0).
- **The matched ESM row.** Koven 2022's SSP5-8.5 rows are the like-for-like comparison. They are
  concentration-driven at **2162 ppm** in 2300, which is HIGHER CO₂ than either CCX arm. More CO₂ should mean
  more fertilisation, yet those ESMs gain **less** land: 0.89–1.28× (computed above).
- **Not fully matched.** The warming paths differ (CCX's own vs each ESM's), and CCX's land base scope
  (permafrost is not represented) differs from the ESMs'.
