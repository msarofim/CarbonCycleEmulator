# Pump δ¹³C fractionations: what the literature supports — 2026-10-12

- **Serves:** `PUMP_EPS13_ORG` (−20 ‰) and `PUMP_EPS13_CARB` (+1 ‰), rows 1–2 of
  `notes/constants_citation_needs_2026-10-12.md`. Follows up item 1 of
  `notes/constants_citation_sources_7_2026-10-12.md`.
- **Read-only.** No value, code, test or data file was changed. Nothing is committed. This is the only
  file written in the repo. One throw-away script lived in the session scratchpad (§D).
- **Access date for every URL:** 2026-10-12.
- **How pages were read.**
  - **PDFs** fetched by WebFetch were cached by the tool outside the repo. I read them with `pdftotext`
    to stdout, so their locators come from the raw text layer: Schmittner 2013, Claret 2021, Kwon 2021,
    Jahn 2015, Morée 2018, Tschumi 2011, Buitenhuis 2019, Hermoso 2016, Jiménez-López 2006 and
    Gussone 2005.
  - **Local PDFs** under `~/Documents/2026/ClaudeDocs/Papers/`: Zhang et al. 1995 and the Dentith reply.
  - **HTML pages** (Liu 2021, Buchanan 2019, Verwega 2021, McClelland 2017) came back as text extracted
    by WebFetch's helper model. Check those locators by eye before they go into the registry.
  - **Abstracts only**, from the Crossref or OpenAlex APIs: Goericke & Fry 1994, Freeman & Hayes 1992,
    Young 2013, Tagliabue & Bopp 2008, Eide 2017b, Sonnerup 1999, Broecker & Maier-Reimer 1992 and
    King & Howard 2004. WebFetch summarized these rather than quoting them.
- **Labels.** **"My arithmetic"** marks every number I computed. It is a check, not a sourced value.
  **"Secondary"** means the number was seen only as quoted by another paper.
- **Sign convention.** Everything is in the code's convention: ε = 1000·(R_product / R_source − 1).
  So organic ε is **negative** and carbonate ε is **positive**. Many papers quote εp as a positive
  "discrimination", and I converted them.

---

## 0. The model quantity (confirmed in code)

- `add_flux()` (`R/model.R:2454`) computes `f13 <- F_C * r13 * alpha13`. Here `r13` is the
  **source** box's ¹³C/C ratio; for a positive flux the source is `from`.
- Every pump leg passes `alpha13 = 1 + PUMP_EPS13_{ORG,CARB}/1000`:
  - the LS mixed layer and the tropical box, `R/model.R:3216-3233`;
  - the HS box to HD, `R/model.R:3450-3454`;
  - the C++ core, `R/cpp.R:96-97`.
- So **ε_org = 1000·(R_exported organic / R_surface DIC − 1)** and **ε_carb = 1000·(R_CaCO₃ / R_surface DIC − 1)**.
  - Both are relative to the **bulk DIC of the surface box that exports**.
  - Neither is relative to CO₂(aq), HCO₃⁻ or the deep DIC the carbon is added to.
- The legs are signed (`alpha13_signed = TRUE`). The same ε is used for the LS and HS pumps.
- `pump_carb_frac` is 0.23 (`R/model.R:1880`), pinned by the GLODAP alkalinity gradient.
- **Leverage (my arithmetic, first order).** `PUMP_GRAD_OBS` is 233 µmol/kg (`R/constants.R:277`).
  - The organic share is then about 180 µmol/kg. A −2 ‰ change in ε_org moves deep-minus-surface
    δ¹³C by about −2 × 180/2250 ≈ **−0.16 ‰**, before any refit re-balances.
  - The carbonate share is about 54 µmol/kg. A ±1 ‰ change in ε_carb moves it by about
    **±0.02 ‰**.
  - The organic constant is the one that matters.

---

## (a) Short answers

### `PUMP_EPS13_ORG`: recommended **−22 ‰, 1σ ≈ 1.5 ‰** (range −20 to −24), preindustrial and export-weighted

Four independent lines meet near −22 ‰ relative to surface DIC:

1. **Deep-ocean δ¹³C–PO₄ slope (data; integrated over remineralized organic matter, effectively preindustrial).**
   - Claret, Sonnerup & Quay (2021), §3.2.1, Eq. 3, Fig. 9a, pp. 11–12: the deep Pacific
     (30°S–30°N, >2000 m) slope in GLODAPv2.2020 is −1.01 ± 0.02 ‰ per µmol/kg.
     - With C:P 117 and a mean DIC of 2325 this gives remineralized organic matter at −20.07 ‰.
     - With C:P 124 ± 10 it gives −19 ‰.
   - That number is **relative to the deep DIC** the carbon is added to. The code's ε is relative to
     the **surface source**.
   - To convert, add δ¹³C_deep − δ¹³C_surface,PI = 0.12 − (1.36 + 0.66) = −1.90 ‰ (my arithmetic). The
     inputs are:
     - deep Pacific GLODAPv2.2023 mean 0.12 ‰;
     - low-latitude surface 1.36 ‰ in about 1995 (both from `glodap_c13c14_subset.csv`);
     - Suess shift 0.66 ‰ (Liu 2021 §4; Schmittner 2013 p. 5808 gives 0.67).
   - Result: **ε ≈ −22.0 ‰** at C:P 117 and −20.8 ‰ at C:P 124.
     - The C:P uncertainty dominates: 117 ± 14 gives **−24.7 to −19.8 ‰** (my arithmetic).
   - This is the most like-for-like constraint. It measures what is actually remineralized, DOC
     included, and it is immune to the suspended-versus-sinking POC question.
2. **Published εp(CO₂aq) relations, export-weighted at 278 µatm (my arithmetic, §D).**
   - The three relations come from Kwon et al. 2021 Table 1, p. 9: Goericke & Fry 1994, Popp et al.
     1989 and Freeman & Hayes 1992.
   - They are weighted by the Nowicki et al. 2022 total-export field already on disk.
   - Results: global **−22.9 / −23.4 / −20.7 ‰**; low-latitude pump region (|lat| < 57.14°)
     −22.5 / −22.7 / −20.2 ‰; HS region −26.3 / −28.3 / −24.6 ‰.
3. **Popp-type ocean models, preindustrial (model output; my arithmetic for the offsets).**
   - UVic: upper-100 m mean detritus −29.6 ‰ against DIC −6.5 ‰ in the no-air-sea-fractionation run,
     **−23.1 ‰** (Schmittner 2013 p. 5799).
   - MOM5-BLING: preindustrial 30°S–30°N δ¹³C_org −19.23 ‰ against a surface mean DIC of 2.24 ‰,
     **≈ −21.5 ‰** (Claret 2021 pp. 4, 12).
   - MPI-HAMOCC Hist_Popp: −22.5 − 1.64 = −24.1 ‰ modern. Liu 2021 App. D says the εp part of the
     change is about 1.5 ‰, which gives **≈ −22.6 ‰ preindustrial**.
4. **Observed POC (modern, not export-weighted).**
   - Goericke & Fry's 30°S–30°N mean is −20.1 ± 1.3 ‰ (secondary, via Claret p. 12). Against GLODAP
     low-latitude surface DIC of 1.36 ‰ that gives **−21.5 ‰** (my arithmetic).
   - Claret puts preindustrial organic matter about 1 ‰ heavier, but the DIC was also about 0.7 ‰
     heavier. So the preindustrial low-latitude value is about −21 ‰ (my arithmetic).
   - High latitudes are far more negative. Verwega 2021 gives 1990s Southern Ocean medians ≤ −28 ‰
     (absolute).

**Against the code's −20 ‰.**
- −20 is about 2 ‰ less negative than the center.
- It equals the **low-latitude-only** or **Freeman & Hayes** end of the range.
- The −19 (Liu 2021, citing Eide 2017b) and −20 (Morée 2018) values in the decomposition literature
  enter a Broecker & Maier-Reimer δ¹³C_bio = (ε/DIC)·C:P·ΔPO₄ formula. There ε is relative to the
  **local or mean-ocean** DIC (δ¹³C ≈ 0 to +0.7 ‰), not to the surface source (≈ +2 ‰ preindustrial).
- Read like-for-like, they correspond to about −21 to −22 ‰ in the code's definition (my arithmetic).

**Why preindustrial and constant.**
- A constant must serve the spin-up, which sets the interior gradient, and 1750–2024.
- The εp relations put the 278 → 360 µatm drift at −1.0 / −1.9 / −1.3 ‰ (GF94 / Popp / FH92;
  my arithmetic, §D).
- Observations show at least that much recently:
  - Young et al. 2013: >0.015 ‰/yr in the subtropics.
  - Verwega 2021: median δ¹³C_POC down about 3 ‰ since the 1960s, about twice the Suess effect,
    outside the Southern Ocean.
- A preindustrial constant is right for the spin-up. It **cannot** represent the post-1960 εp trend.

**Methodological choices for Marcus (not resolved here).**
- (i) One constant, or separate LS and HS values?
  - The literature supports about **−22 ‰ for LS** and about **−26 ‰ for HS** (preindustrial;
    §D range −24.6 to −28.3).
  - This is a structural change.
- (ii) A preindustrial-constant versus a CO₂-dependent ε.
  - This is also structural.
  - The εp(CO₂aq) relations are weak (Goericke & Fry 1994, abstract), so a CO₂-dependent form adds
    a parameterization choice, not a measurement.
- (iii) Any change is **refit-class**: the constant is in the fitted objective (constants worklist row 1).

### `PUMP_EPS13_CARB`: recommended **keep +1 ‰, 1σ ≈ 1 ‰** (range 0 to +2), relative to DIC

1. **Inorganic equilibrium relative to HCO₃⁻ at 25 °C.**
   - Calcite +1.0 ± 0.2 ‰ (Romanek et al. 1992, secondary via Jiménez-López, Romanek & Caballero
     2006 p. 1169). The same page lists other experiments at 0.9 and 0.94 ± 0.06 ‰. Its own
     pure-calcite extrapolation is 0.82 ± 0.09 ‰ (abstract, p. 1163).
   - Aragonite +2.7 ‰ (Romanek 1992, secondary via Gussone et al. 2005 Table 4, p. 4492). The text on
     p. 4485 gives aragonite +1.7 ‰ relative to calcite.
2. **HCO₃⁻ to DIC correction is small.**
   - From Zhang et al. 1995 (ε_HCO₃–g p. 111; ε_DIC–g abstract p. 107), DIC is 0 to 0.2 ‰ lighter
     than HCO₃⁻ between 25 and 5 °C (my arithmetic).
   - So ε(calcite–DIC) ≈ +1.0 to +1.2 ‰ and ε(aragonite–DIC) ≈ +2.7 to +2.9 ‰.
   - Hermoso et al. 2016 (Eq. 3, p. 304) uses δ¹³C_inorg = δ¹³C_DIC + 1 directly, citing Romanek.
3. **Export mineralogy.**
   - Pteropod **aragonite** is 33–36 % of CaCO₃ export at 100 m and 12–26 % at 2000 m
     (Buitenhuis et al. 2019 Table 1, p. 6; text pp. 7–8; a model tuned to the observations).
   - The rest is calcite. Foraminifera are 18–26 % (p. 8); coccolithophores make up the remainder.
   - The mineral-weighted equilibrium value is about **+1.6 to +1.8 ‰** (my arithmetic).
4. **Biogenic vital effects pull that down.**
   - Heavily calcifying coccoliths (*C. pelagicus*, *C. leptoporus*) sit about 2.5 ‰ below inorganic
     calcite at preindustrial DIC, so ε ≈ −1.5 ‰ relative to DIC (my arithmetic). *E. huxleyi* sits
     above it (Hermoso 2016 §3.1.2, pp. 304–305). The interspecies range is about 3 ‰.
   - Foraminiferal δ¹³C falls with rising [CO₃²⁻] (Spero et al. 1997, abstract).
   - Southern Ocean trap foraminifera are out of equilibrium, most strongly at lower latitudes
     (King & Howard 2004, abstract). No magnitude was readable.
5. **Model practice spans 0 to +2 ‰** (§C). +1 ‰ is the midpoint.

**Verdict.**
- +1 ‰ sits at the center of a 0 to +2 ‰ bracket.
- No source gives an export-weighted biogenic value.
- Its leverage is about 0.02 ‰ per ‰, so the bracket is not worth a refit on its own.

---

## (b) Every estimate found

### Organic export relative to the code's reference (surface DIC)

| # | Value as published | Reference phase | Weighting | Period | Method | Citation (vintage) | Locator | Converted to code ε | Like-for-like? | Primary/secondary |
|---|---|---|---|---|---|---|---|---|---|---|
| O1 | slope −1.01 ± 0.02 ‰ per µmol/kg PO₄ → remineralized OM −20.07 ‰ (C:P 117) or −19 ‰ with C:P 124 ± 10 | deep DIC (δ¹³C_DIC,deep ≈ 0) | integrated remineralization, deep Pacific | effectively preindustrial (no Suess signal below 2000 m, same page) | GLODAPv2.2020 regression | Claret, Sonnerup & Quay 2021, GBC 35:e2020GB006757, doi:10.1029/2020GB006757 (2021) | §3.2.1, Eq. 3, Fig. 9a, pp. 11–12 | **−22.0** (C:P 117); −20.8 (C:P 124); −24.7…−19.8 (C:P 117 ± 14) (my arithmetic) | **Best available**; C:P-limited | primary (NOAA IR copy) |
| O2 | 30°S–30°N mean δ¹³C_POC −20.1 ± 1.3 ‰ | absolute | surface POC | modern (compiled 1994) | compilation | Goericke & Fry 1994 via Claret 2021 | Claret p. 12 | ≈ −21.5 modern; ≈ −21 preindustrial (my arithmetic) | partly (low latitudes, suspended) | **secondary** |
| O3 | εp–CO₂aq relation weak; cannot be calibrated easily from modern POC | CO₂(aq) | — | modern | compilation | Goericke & Fry 1994, GBC 8:85, doi:10.1029/93GB03272 (1994) | abstract (Crossref) | — | context | primary (abstract) |
| O4 | α_POC←aq = −0.00935·log₁₀[CO₂] + 0.99626 | CO₂(aq) | fit | modern | regression | Goericke & Fry 1994, as transcribed in Kwon et al. 2021, GBC 35:e2020GB006684, doi:10.1029/2020GB006684 | Kwon Table 1, p. 9 | export-weighted preindustrial −22.9 (§D) | parameterization | secondary |
| O5 | α_POC←aq = −0.017·log₁₀[CO₂] + 1.0034 | CO₂(aq) | fit | — | porphyrin/POC regression | Popp et al. 1989, as given in Schmittner 2013 Eq. 7 (p. 5796), Liu 2021 Eq. 10, Kwon 2021 Table 1 | as listed | export-weighted preindustrial −23.4 (§D) | parameterization | secondary |
| O6 | α_POC←aq = −0.01203·log₁₀[CO₂] + 1.00119 | CO₂(aq) | fit | — | GEOSECS-based compilation | Freeman & Hayes 1992, GBC 6:185, doi:10.1029/92GB00190; fit via Kwon 2021 Table 1 | abstract (Crossref) + Kwon p. 9 | export-weighted preindustrial −20.7 (§D) | parameterization | abstract primary; fit secondary |
| O7 | typical bulk marine OM about −21 ‰ against mean surface DIC near +2 ‰ | absolute vs DIC | none (round numbers) | modern | introductory statement | Schmittner et al. 2013, BG 10:5793, doi:10.5194/bg-10-5793-2013 (2013) | p. 5794 | ≈ −23 (my arithmetic) | weak | primary |
| O8 | zonal δ¹³C_POC about −20 ‰ at low latitudes, −25 to −30 ‰ at high latitudes; POC about 2 ‰ lower in the 1990s than preindustrial (model) | absolute | surface POC | 1990s | G&F data vs UVic | Schmittner 2013 | §5.2.1, p. 5806 | — | context | primary |
| O9 | mean detritus 0–100 m −29.6 ‰ vs DIC −6.5 ‰ (const-gasx run) | model DIC | volume mean, 0–100 m | preindustrial-type spin-up | UVic model, Popp εp | Schmittner 2013 | p. 5799 | **−23.1** (my arithmetic) | close (volume-weighted, not export) | primary (model) |
| O10 | preindustrial sea-surface δ¹³C_org −19.23 ‰ (30°S–30°N); surface mean δ¹³C_DIC 2.24 ‰ | absolute | low latitudes | preindustrial | MOM5-BLING, Popp εp | Claret 2021 | pp. 4, 12 | ≈ −21.5 (my arithmetic; regions differ) | partly | primary (model) |
| O11 | Hist_Popp global surface δ¹³C_POC −22.5 ‰ (1960–1991); surface DIC 1.64 ‰ (1990–2005); POC −2.2 ‰ from preindustrial to the 1990s; Suess −0.66 ‰ | absolute | surface area mean | modern; preindustrial by difference | MPI-HAMOCC | Liu, Six & Ilyina 2021, BG 18:4389, doi:10.5194/bg-18-4389-2021 (2021) | §3.1, §3.2.1, §4, App. D | −24.1 modern; **≈ −22.6** preindustrial (my arithmetic) | partly | primary (model; WebFetch extraction) |
| O12 | Δphoto = −19 ‰ (decomposition constant, citing Eide 2017b) | local/mean-ocean DIC (Eq. 14 structure) | — | — | adopted | Liu 2021 | §3.2.2, Eq. 14 | ≈ −21 (shift of −2, my arithmetic) | **no** (different reference) | secondary for Eide |
| O13 | εphoto = −20 ‰ model constant, citing Lynch-Stieglitz 1995 and Tagliabue & Bopp 2008 | model surface DIC | — | — | adopted | Morée, Schwinger & Heinze 2018, BG 15:7205, doi:10.5194/bg-15-7205-2018 | p. 7207; Eq. 3, p. 7208 | −20 as a model choice | same definition; not a measurement | primary (choice) |
| O14 | arithmetic mean δ¹³C_POC −23.96 ‰; median −22.46 ‰; 1990s medians ≥ −22 ‰ (<30°), about −24 ‰ (Arctic), ≤ −28 ‰ (Southern Ocean); non-SO density maximum −19.9 ‰ (1960s) → about −23 ‰ (2010s); decline about 3 ‰, about 2× Suess | absolute | unweighted, all depths and methods | 1964–2015 | 4732-point compilation | Verwega et al. 2021, ESSD 13:4861, doi:10.5194/essd-13-4861-2021 (2021) | §3.1 Eq. 3; §4.2; abstract; §6, Fig. 11a; §8 | about −25.4 unweighted modern (my arithmetic) | **no** (absolute, modern, unweighted) | primary (WebFetch extraction) |
| O15 | εp rose since the 1960s, >0.015 ‰/yr in the subtropics; Bermuda trap record supports it | CO₂(aq) | surface POC + trap | 1960–2010 | compilation | Young et al. 2013, GBC 27:505, doi:10.1002/gbc.20045 (2013) | abstract (Crossref) | sign of the transient | context | primary (abstract) |
| O16 | δ¹³C_POC sensitive by 10–17 ‰ to the carbon species assimilated, growth rate and CO₂aq | — | — | 1860–2000 | PISCES model | Tagliabue & Bopp 2008, GBC 22:GB1025, doi:10.1029/2007GB003037 | abstract (Crossref) | parameterization spread | context | primary (abstract) |
| O17 | trap (sinking) organic matter heavier than surface by about 4 ‰ (SAZ) / 2 ‰ (PFZ) in spring; seasonal mean 1.5 / 1.8 ‰ | absolute | sinking vs suspended | 1997–98 | SO traps | Lourey, Trull & Tilbrook 2004, DSR-I 51:281, doi:10.1016/j.dsr.2003.10.002 | abstract, **seen only in a search-engine extract** (repository page refused) | would make export less negative than surface POC | relevant, **unverified** | secondary / unverified |
| O18 | culture-model organic δ¹³C plateaus at about −23 to −24 ‰ relative to DIC at low utilization | DIC | culture | lab | coccolithophore model + culture | McClelland et al. 2017, Nat. Commun. 8:14511, doi:10.1038/ncomms14511 | Results (PMC HTML, WebFetch extraction) | −23 to −24 | lab only | primary (extraction) |

### Carbonate relative to DIC (or HCO₃⁻)

| # | Value | Reference phase | Material | T | Method | Citation (vintage) | Locator | → ε relative to DIC | Like-for-like? | Primary/secondary |
|---|---|---|---|---|---|---|---|---|---|---|
| C1 | +1.0 ± 0.2 ‰ (Romanek 1992); 0.9 (Rubinson & Clayton 1969); 0.94 ± 0.06 (Jiménez-López 2001) | HCO₃⁻(aq) | inorganic calcite | 25 °C | lab | quoted by Jiménez-López, Romanek & Caballero 2006, GCA 70:1163, doi:10.1016/j.gca.2005.11.005 (2006) | p. 1169 | +1.0 to +1.2 (my arithmetic, C3) | inorganic only | **secondary** for Romanek |
| C2 | +0.82 ± 0.09 ‰ (pure-calcite extrapolation); +0.024 ± 0.011 ‰ per mol% MgCO₃ | HCO₃⁻(aq) | synthetic Mg-calcite | 25 °C | lab | Jiménez-López et al. 2006 | abstract, p. 1163 | about +0.9 to +1.0 | inorganic only | primary |
| C3 | calcite +1.0 ‰, aragonite +2.7 ‰ (Romanek 1992); aragonite +1.7 ‰ relative to calcite | HCO₃⁻ | inorganic | 25 °C | lab | Gussone et al. 2005, GCA 69:4485, doi:10.1016/j.gca.2005.06.003 | Table 4, p. 4492; text p. 4485 | aragonite +2.7 to +2.9 (my arithmetic) | inorganic only | **secondary** |
| C4 | CaCO₃–CO₂(g) about 9.0–10 ‰ at 25 °C (Turner 1982; Emrich 1970); ε_HCO₃–g = −0.1141·T + 10.78 ‰; ε_DIC–g = 0.014·T·fCO₃ − 0.105·T + 10.53 ‰ | CO₂ gas | inorganic | 5–25 °C | lab | Zhang, Quay & Wilbur 1995, GCA 59:107 (local PDF) | p. 113; p. 111; abstract p. 107 | DIC − HCO₃⁻ = 0 to −0.2 ‰ (my arithmetic) | conversion | primary (CaCO₃ figure secondary) |
| C5 | interspecies range about 3 ‰ at preindustrial DIC; *C. pelagicus* and *C. leptoporus* vital effect −2.5 ‰ vs inorganic (δ¹³C_DIC + 1); *E. huxleyi* positive | DIC (+1 inorganic reference) | coccolith calcite | culture | lab | Hermoso et al. 2016, BG 13:301, doi:10.5194/bg-13-301-2016 (2016) | Eq. 3, p. 304; §3.1.2, pp. 304–305 | about −1.5 for heavy calcifiers (my arithmetic) | biogenic, culture | primary |
| C6 | coccolith range "+3 to −2 ‰" across species | (not stated on page) | coccoliths | culture | lab | Ziveri et al. 2003 via Jahn et al. 2015 | Jahn p. 2424 | +3 to −2 | biogenic | **secondary** |
| C7 | heavy vs light coccolith calcite set by the PIC:POC ratio | abiogenic calcite | coccoliths | — | model + culture | McClelland et al. 2017 | abstract; Results | sign only | biogenic | primary |
| C8 | foraminiferal δ¹³C decreases with rising [CO₃²⁻] | — | *O. universa*, *G. bulloides* | culture | lab | Spero et al. 1997, Nature 390:497, doi:10.1038/37333 | abstract (RePEc) | direction only | biogenic | primary (abstract) |
| C9 | trap foraminifera out of equilibrium with DIC, largest at lower latitudes | DIC | *G. bulloides*, *G. inflata*, *N. pachyderma* | in situ | SO traps | King & Howard 2004, GBC 18:GB2007, doi:10.1029/2003GB002162 | abstract (Crossref) | direction only | biogenic, in situ | primary (abstract) |
| C10 | export at 100 m: pteropods 33–36 %, foraminifera 18–26 %; pteropods 12–26 % at 2000 m | — | export mix | — | model tuned to observations | Buitenhuis et al. 2019, GBC 33, doi:10.1029/2018GB006110 | Table 1, p. 6; pp. 7–8 | mineral weight for C1/C3 | weighting | primary |

---

## (c) Model parameterizations found

| Model (paper) | Organic | Carbonate | Locator |
|---|---|---|---|
| UVic (Schmittner et al. 2013) | Popp εp(CO₂aq) × α_aq←DIC (Eqs. 6–7); constant-α sensitivity runs at 0.980 / 0.975 / 0.970 (ε −20 / −25 / −30 ‰ vs DIC) | **0** (Turner 1982: "small") | pp. 5796, 5798 (Table 1) |
| MOM5-BLING13C (Claret et al. 2021) | as Schmittner (Popp) | **+1 ‰** (Bonneau et al. 1980), not applied on dissolution | p. 4; App. A3, Eq. A4, p. 20 |
| MPI-HAMOCC (Liu et al. 2021) | Popp (Eq. 10) and Laws (Eqs. 11–12); Popp fits observations better (r 0.84 vs 0.71) | **0** (Turner 1982; Zeebe & Wolf-Gladrow 2001; following Lynch-Stieglitz 1995, Schmittner 2013, Tjiputra 2020) | §2.2, §2.2.2, §6 |
| CESM1 (Jahn et al. 2015, GMD 8:2419, doi:10.5194/gmd-8-2419-2015) | Rau 1989 (δCp = −0.8·CO₂* − 12.6, bounded −18 to −32), Laws 1995, Keller & Morel 1999 (Eqs. 21–26) | **+2 ‰** (Ziveri 2003); notes others use 1 ‰ (Sonnerup 1999; Tagliabue & Bopp 2008) or 0 (Marchal 1998; Schmittner 2013) | pp. 2423–2424 |
| CSIRO Mk3L-COAL (Buchanan et al. 2019, GMD 12:1491, doi:10.5194/gmd-12-1491-2019) | constant **21 ‰ relative to DIC** (ε −21 ‰; uncited); optional Laws-type (Eq. 6), floor 15 ‰ | **+2 ‰** (Ortiz et al. 1996) | §3.1, Eqs. 6–8 (WebFetch extraction) |
| HAMOCC2s (Morée et al. 2018) | constant **−20 ‰** (Lynch-Stieglitz 1995; Tagliabue & Bopp 2008) | **0**, "likely minor (∼1 ‰)" | p. 7207 |
| OCIM (Kwon et al. 2021) | Goericke & Fry fit (standard); Popp or Freeman & Hayes in the Monte Carlo | not stated in the text read | Table 1, p. 9 |
| Bern3D (Tschumi et al. 2011, Clim. Past 7:771, doi:10.5194/cp-7-771-2011) | Freeman & Hayes 1992 | Mook 1988 (value not given) | p. 774 |
| FAMOUS (Dentith et al.; authors' reply) | — | **0** (α_CaCO₃ = 1.0) | `bg-2019-365-AC2-supplement.pdf`, PDF p. 3 |
| iLOVECLIM (Bouttes et al. 2015, GMD 8:1563, doi:10.5194/gmd-8-1563-2015) | defers to Brovkin et al. 2007 (not read) | — | §2.2.3 |

**Pattern.**
- Organic: modern isotope-enabled models use a CO₂(aq)-dependent Popp-type εp; constants are used only
  for simple models or decompositions.
- Carbonate: models split 0 / +1 / +2 ‰, and none cites an export-weighted biogenic measurement.

---

## (d) The export-weighted computation (my arithmetic)

- **Script:** session scratchpad `eps_export_weighted.R`, not in the repo. It is read-only use of
  `data/carbonate_coefs.rds` and `data-raw/downloads/biopump_model_output.nc`.
- **Formula:** ε_POC←DIC = 1000·(α_POC←aq · α_aq←g / α_DIC←g − 1). This is Schmittner 2013 Eq. 6.
  - α_aq←g and α_DIC←g come from the Zhang 1995 abstract, with fCO₃ = 0.10.
  - α_POC←aq comes from the three fits in Kwon 2021 Table 1.
- **CO₂(aq)** = K0(T)·pCO₂.
  - K0 is the repo's seacarb fit (Weiss 1974, S = 34.7). It is clamped at 2 °C because its fitted
    range is 2–35 °C; 8.8 % of the export weight lies below 2 °C.
  - Surface water is assumed to be in equilibrium with the atmosphere.
- **Weights:** Nowicki et al. 2022 `tot_ex` × `Area`. The total is 10.25 PgC/yr, which checks against
  the abstract's 10.2.
- **Temperature:** the file's surface `Temp`.
- **Regions:** "LS" is |lat| < 57.14°, the model's HS boundary from `build_pump_export_prior.R`.
  - HS carries 11.4 % of export.
  - The export-weighted SST is 17.4 °C globally, 19.5 °C in LS and 1.4 °C in HS.

| pCO₂ | fit | global (export-weighted) | LS | HS | <30° | global (area-weighted) |
|---|---|---|---|---|---|---|
| 278 | Goericke & Fry 1994 | −22.92 | −22.48 | −26.30 | −21.27 | −22.79 |
| 278 | Popp 1989 | −23.36 | −22.73 | −28.25 | −20.97 | −23.17 |
| 278 | Freeman & Hayes 1992 | −20.67 | −20.16 | −24.58 | −18.76 | −20.52 |
| 360 | GF94 / Popp / FH92 | −23.96 / −25.25 / −22.00 | −23.52 / −24.62 / −21.50 | −27.33 / −30.14 / −25.91 | — | — |
| 410 | GF94 / Popp / FH92 | −24.48 / −26.20 / −22.68 | −24.04 / −25.57 / −22.17 | −27.86 / −31.09 / −26.59 | — | — |

**Weighting by gravitational export only** (`grav_ex`) moves every number by ≤ 0.3 ‰.

**Caveats.**
- The fits were made to **modern, suspended, surface** POC, not to sinking flux.
- They carry only the CO₂ dependence. Goericke & Fry's own abstract calls that dependence weak, and
  the growth-rate terms (Laws 1995; Popp 1998) are left out.
- The equilibrium-pCO₂ assumption understates CO₂(aq) in upwelling regions.
- The modern columns (−24.0 to −25.3 at 360 µatm) agree with Liu's Hist_Popp −24.1 and with the
  observation-based offsets in O14.

---

## (e) What I searched, and what I could not open

**Searched (web; Crossref, OpenAlex and Semantic Scholar APIs).**
- Organic: Eide 2017a/b; Goericke & Fry 1994; Rau 1989/1992; Freeman & Hayes 1992; Popp 1998;
  Laws 1995; Hofmann 2000; Tagliabue & Bopp 2008; Schmittner 2013; Lynch-Stieglitz 1995; Young 2013;
  Verwega 2021; Liu 2021; Buchanan 2019; Claret 2021; Kwon 2021; Morée 2018; Lourey 2004;
  sediment-trap δ¹³C compilations.
- Carbonate: Romanek 1992; Emrich 1970; Ziveri 2003; Spero 1997; Bemis 2000; King & Howard 2004;
  Hermoso 2016; McClelland 2017; Buitenhuis 2019.
- Model papers: Jahn 2015; Bouttes 2015; Tschumi 2011.

**Not opened (paywall, 403 or bot wall). Every number attributed to these is secondary or absent.**
- Eide et al. 2017b: only the abstract was read, and it gives **no** −19 ‰. The origin of Liu's −19
  is still unknown.
- Goericke & Fry 1994: abstract only.
- Rau et al. 1989.
- Laws et al. 1995 and Popp et al. 1998: no abstract available.
- Hofmann et al. 2000.
- Romanek et al. 1992 and Emrich et al. 1970: values seen only as quoted.
- Ziveri et al. 2003: the AWI server refused the connection.
- Lourey et al. 2004: the repository returned 403. **O17 is unverified.**
- King & Howard 2004 full text (figshare returned 403).
- Bemis et al. 2000, Bonneau et al. 1980 and Ortiz et al. 1996.
- Lynch-Stieglitz et al. 1995: the Bern repository bot wall; the OSTI abstract has no numbers.

**Not found.**
- No **export-weighted, data-based** organic ε relative to surface DIC.
- No **export-weighted biogenic** CaCO₃ ε.
- Both recommended values are therefore syntheses, and the derivations above are the citation trail.

**Follow-ups worth doing.**
- Read the full Goericke & Fry 1994 table.
- Read Lourey 2004 to quantify the sinking-minus-suspended offset beyond the Southern Ocean.
- The Verwega PANGAEA set (doi:10.1594/PANGAEA.929931) could be reduced to trap-only medians.
- Repeat O1 with an AOU-based (C:O₂) slope. This removes the C:P degeneracy, and Eide 2017b reports
  that δ¹³C–AOU is the tighter relation.
