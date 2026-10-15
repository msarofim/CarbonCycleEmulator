# Terrestrial photosynthetic ¹³C discrimination: which constant? (2026-10-12)

- **Serves:** `notes/constants_citation_needs_2026-10-12.md` §11–12 and `notes/citation_rulings_2026-10-12.md` row 11–12 (Marcus: "which is the scientifically best value?").
- **Read-only.** This is the only file written in the repo. No value, code, test or data file was changed, and nothing was committed. Code was read at HEAD `6a09169`.
- **How pages were read:** WebSearch plus WebFetch.
  - **PDFs:** WebFetch cached each PDF it fetched under the session's `~/.claude/projects/.../tool-results/` folder, outside the repo. I read them with the Read tool (page images) or with `pdftotext` into the session scratchpad. Their locators come from the page or text layer.
  - **HTML pages:** WebFetch returns a helper-model extraction. Those locators (marked **[HTML]**) should be checked by eye before they enter the registry.
  - **Access date** for every URL: 2026-10-12.
- **Labels:**
  - **"my arithmetic"** marks every number I computed. The script is `scratchpad/harmonise.R`, outside the repo; its formulas are given inline below.
  - **"secondary"** marks a number seen only in another paper's table or text.
  - **"not read"** marks a source that was cited to me but never opened.

---

## (a) Answer

**Recommended constant:**
- **Δ ≈ 16.5 ‰**, in Farquhar's sense (photosynthate lighter than air by Δ; R_plant = R_air / (1 + Δ/1000)).
- **1σ ≈ 0.8 ‰.** The synthesis central is 16.5–16.7 and the 95 % range is about 15.2–18.1 (my arithmetic).
- **In CCX's form** (`alpha_photo = 1 − ε/1000`) that is **`alpha_photo_eps` ≈ 16.2**. The 0.27 ‰ convention gap is well inside the uncertainty, so entering 16.5 directly is also defensible. Which convention the registry records is a choice for Marcus (§0).

**Why:**
1. CCX needs one biosphere-wide (C3 + C4), GPP-weighted value. It has one land biosphere per hemisphere and no C3/C4 split.
2. The total is Δ_tot = (1 − f₄)·Δ_C3 + f₄·Δ_C4. The published global estimates differ mostly through f₄, the C4 share of GPP, which ranges from under 10 % to 30 % across the process models (Suits 2005 Table 1; van der Velde 2014 Table 2).
3. The most recent and observation-constrained f₄ is **19.5 ± 1.9 %** (Luo et al. 2024).
4. Re-weighting every process model that publishes its C3 and C4 endmembers to that share gives **15.0–17.1 ‰, mean 16.45, median 16.67** (my arithmetic, §B4).
5. A decomposition with Δ_C3 = 19.5 ± 0.7, Δ_C4 = 5 ± 1 and f₄ = 0.195 ± 0.03 gives **16.67 ± 0.74**. A 2×10⁵-draw Monte Carlo matches it (16.67, sd 0.74). The input spreads are my judgment, set from the published ranges (my arithmetic).
6. The single best citable number is **Still et al. 2003: 16.5 ‰, assimilation-weighted, C4 = 23 % of GPP.** It is indistinguishable from the synthesis.

**How the other values compare:**

| Value | What it is | Against 16.5 ± 0.8 |
|---|---|---|
| **15.6** (live) | Midpoint of a mis-attributed bracket (§D). In CCX's convention it equals Farquhar Δ **15.85** (my arithmetic). | 0.65 below in like-for-like convention (≈0.8σ); 0.9 below at face value (≈1.1σ). Inside 1σ to 1.1σ. |
| **14.8** | Lloyd & Farquhar 1994 total. Its C3 value, 17.8, is below every later C3 estimate (19.2–20.1). Re-weighted to f₄ = 19.5 % it is still 15.0. | Low-side outlier, ≈2σ below. |
| **17** | Quay 2003's a-priori value for 1970–1990 (Bakwin 1998). | Consistent (+0.5), but its ±5 makes it uninformative. |
| **18** | The C3-dominated value that comparable box models use by convention: Keeling 2017, Graven 2020, Trudinger's box-diffusion model (α = 0.982), Francey 1995 (18.0, secondary). | ≈2σ above the biosphere-wide estimate. It is like-for-like only if C4 is ≤ ~10 % of GPP, which the observation-constrained 19.5 % excludes. |

**⚠ Methodological choice, flagged and not resolved (§E).** The GPP-weighted mean is the right value for CCX's gross GPP limb and its equilibrium pool δ. The net CO₂-fertilized sink and the NH seasonal NEP are probably C3-dominated, though. Budget box models may use 18 for exactly that reason, and the Graven/Lavergne box model gives C4 zero fertilization. One constant cannot be right for both.

**⚠ Time dependence (§C).** The evidence on drift over 1750–2024 conflicts:
- **For an increase:** atmospheric δ¹³C budgets infer +0.014 ± 0.007 ‰ ppm⁻¹ (Keeling 2017). Over CO₂ 277 → 422 ppm that is **+2.0 ± 1.0 ‰** (my arithmetic).
- **For little change:** tree rings show small 20th-century changes (Keller 2017), and JULES plus a tree-ring network show no significant global trend over 1979–2016 (Lavergne 2022).
- **The other way:** land-use C4 expansion lowers Δ by up to about 0.5 ‰.

A constant anchored on the 1983–2008 process-model era is defensible. A CO₂-linear sensitivity run is the standard alternative.

---

## 0. The model quantity

**Code locators** (HEAD `6a09169`; the citation-needs note's line numbers have drifted):
- **Registry value:** `R/constants.R:310–319` (`ALPHA_PHOTO_EPS` = 18; comment block 285–309).
- **Live value:** `R/calibrate.R:2320` (`CCX_ALPHA_PHOTO_EPS_BIOSPHERE <- 15.6`; rationale in the docstring at 2312–2316). It is injected by `ccx_struct_hilda_c()` at 2321–2333.
- **Conversion:** `R/model.R:4515` builds `alpha_photo = 1 − eps/1000` in `ccx_prepare()`. The citation-needs note's `model.R:4414` is stale.
- **Applied at:**
  - `R/model.R:2819–2823`: the two GPP limbs, atmosphere → leaf and atmosphere → wood, carrying `npp + ra + enso_gpp` share.
  - `R/model.R:2833`: N-deposition retention into slow soil.
  - `R/model.R:2917–2918`: the seasonal uptake half only. The release half has α = 1. The note's `2829–2830` is stale; those lines are now the N-deposition block.
  - The C++ core takes the same scalar (`R/cpp.R:59`).

**Convention:**
- `add_flux()` (`R/model.R:2454–2488`) sets `f13 = F_C · r13(source) · alpha13`. So R_veg = R_atm·(1 − ε/1000): **positive ε means photosynthate is lighter by ≈ ε ‰.**
- Farquhar's Δ is defined by R_air/R_plant = 1 + Δ/1000. Suits et al. 2005 use it (Eq. 1–2, p. 5), as do van der Velde et al. 2014 (Eq. 2, p. 6556).
- Hence **ε_CCX = Δ/(1 + Δ/1000)**, giving these pairs (my arithmetic):

| Farquhar Δ | CCX ε |
|---|---|
| 14.8 | 14.58 |
| 15.85 | 15.6 |
| 16.5 | 16.23 |
| 17.0 | 16.72 |
| 18.0 | 17.68 |
| 18.33 | 18 |

- Trudinger's box-diffusion "0.982" is already in CCX's α form. For the budget models' "18" the convention is not stated in what I read.

**Weighting:**
- ε is applied to **GPP** (`npp + ra`). Autotrophic respiration returns at the pool's ratio, so at equilibrium the net NPP flux carries the same ε. GPP-weighted and NPP-weighted values coincide in CCX.
- In the literature they differ slightly. Scholze's figure is NPP-weighted (via Keeling 2017); Still, Suits and van der Velde are assimilation-weighted.

**Hemispheres:** the same scalar applies to NH and SH. **No C3/C4 split**, so the value must be a C3 + C4 composite.

---

## (b) Every estimate found

### B1. Global, flux-weighted, C3 + C4 totals (process models)

| Value Δ (‰) | C4 share of GPP | Weighting | Period | Method | Citation (vintage, DOI) | Locator | Like-for-like? | Primary / secondary |
|---|---|---|---|---|---|---|---|---|
| **14.8** (C3 17.8, range 12.9–19.6 by biome; C4 3.6) | **21 %** | GPP | climatology (monthly) | Gridded climate, stomatal optimization | Lloyd & Farquhar 1994, Oecologia 99:201–215, doi:10.1007/BF00627732 | Abstract **[HTML, Springer]**. Also Suits 2005 ¶10 p. 5 and Table 1 p. 6; van der Velde 2014 Table 2 p. 6559. | **Yes** in definition. C3 is low by later standards; the authors call it slightly below the commonly used 18–20. | Primary (abstract) + 2 secondary |
| **15.7** (C3 20.0, C4 4.4) | **27 %** | net assimilation | GCM-coupled SiB2 run | SiB2 + GCM | Fung et al. 1997, GBC 11(4):507–533, doi:10.1029/97GB01751 | Abstract gives a range of **12–16** for "the global flux-weighted mean" **[HTML, Carnegie page]**. The 15.7 is from Suits Table 1 p. 6 and van der Velde Table 2. | Yes; f₄ high | Range primary; 15.7 secondary |
| **18.1** with agricultural mask; **18.6** natural vegetation | **15 %** | ecosystem Δ_e | 0.5° climatology | BIOME4 | Kaplan, Prentice & Buchmann 2002, GBC 16(4), doi:10.1029/2001GB001403 | Abstract **[HTML, Lund LUP]**. The 15 % and C3 20.0 ± 1.0 are from Suits Table 1 p. 6 and ¶12 p. 8. | Yes; f₄ low (Kaplan pers. comm. in Suits ¶12) | Primary (values) + secondary (f₄) |
| **16.5** (published as −16.5) | **23 %** (35.3 of 150 PgC yr⁻¹) | assimilation | 1980s–1990s | SiB2 + C3/C4 map (remote sensing, crop maps) | Still, Berry, Collatz & DeFries 2003, GBC 17(1), 1006, doi:10.1029/2001GB001807 | Abstract **[HTML, EarthRef ERR 74609]**. Article number from Suits' reference list (txt l.1515). Values corroborated by Ovwemuvwose 2026 §1, §3.4. | **Yes** | Primary (abstract) |
| **17.7** leaf-level, interannual variability ≈0.3; **17.9 → 17.0** across land-use schemes | **< 10 %** (van der Velde Table 2) | leaf-level | 1950–1998 | LPJ | Scholze dissertation, Univ. Hamburg (c. 2003) | Abstract, p. ii–iii (pdftotext). Units glyph lost in the text layer. | Partly: leaf-level, very low f₄ | Primary (thesis abstract) |
| **17.7** | < 10 % | — | — | LPJ | Scholze, Kaplan, Knorr & Heimann 2003, GRL 30(2):1097, doi:10.1029/2002GL015631 | van der Velde Table 2 p. 6559. Full text not read (Wiley 403, MPG 403, EPFL 403). | Partly | Secondary |
| **11.9 (or 17.9?) to 17.0** | variable (C4 crops and pastures) | leaf | 1901–1998 | LPJ with land use | Scholze, Ciais & Heimann 2008, GBC 22(1), GB1009, doi:10.1029/2006GB002899 | Abstract **[HTML, Lund]**. ⚠ It reads 11.9, while the thesis abstract gives 17.9 with identical disequilibrium numbers (37.9 / 23.9). One of them is probably a typo. | Partly | Primary (abstract) |
| **15.9** (C3 19.2, C4 4.4) | **24 %** (Table 1); **25 %** (¶13) | net assimilation (¶14; Fig. 4 caption) | **1983–1993** | SiB2.5 + CFRAX, ECMWF-driven | Suits et al. 2005, GBC 19, GB1017, doi:10.1029/2003GB002141 | Abstract p. 1; ¶13 p. 8; Table 1 p. 6; Conclusion ¶25 p. 13 (page images) | **Yes**. ⚠ Internal 24 vs 25 % inconsistency. | Primary |
| **15.2 ± 0.04** (C3 19 ± 0.15, "19–20"; C4 4.4) | **≈30 %** | assimilation (Eq. 7) | **1997–2008** | SiBCASA | van der Velde et al. 2014, BG 11:6553–6571, doi:10.5194/bg-11-6553-2014 | Abstract p. 6553; §3.1 p. 6558; Table 2 p. 6559. The conclusions add that the global value depends strongly on the C4 share prescribed (pdftotext l.1197). | Yes; f₄ high | Primary |
| **16.9–19.5** (fixed endmembers C3 **20.7**, C4 **6.3**) | **12–27 %** across 11 CMIP6 models | GPP (Eq. 1) | 2014 | CMIP6 GPP split × leaf-database endmembers (Cornwell 2018, 3987 species). The authors state it neglects environmental and physiological effects. | Ovwemuvwose, Prentice & Graven 2026, BG 23:5593–5605, doi:10.5194/bg-23-5593-2026 | §2.3 Eq. 1; §3.4 / Fig. 6a; Abstract **[HTML]** | Partly: leaf-tissue endmembers (see B2) and model C4 shares that Luo 2024 shows run low | Primary |

### B2. C3-only and endmember values (inputs, not totals)

| Value (‰) | What | Citation | Locator | Note |
|---|---|---|---|---|
| C3 forests **20.9 ± 1.5** (photorespiration + mesophyll), 22.9 (photorespiration only), 23.8 (simple) | JULES, GPP-weighted, C3 woody only | Lavergne et al. 2022, GCB 28(2):524–541, doi:10.1111/gcb.15924 | §3.2, §4.4 **[HTML, PMC9298043]** | About +0.8 above the leaf network and up to +1.6 above tree rings (§4.4) |
| Leaf Δ **20.1 ± 2.3** (n = 1558) | observed leaf network | same | §3.1.1 **[HTML]** | Species and site mean, not GPP-weighted |
| C3 **20.7**, C4 **6.3** | histogram peaks of the Cornwell et al. 2018 leaf database, split at 12.5 ‰ | Ovwemuvwose 2026 | §2.3 **[HTML]** | Cornwell 2018 itself not read |
| C3 "about 18", C4 "about 4" (typical offsets from air) | review text | Graven, Keeling & Rogelj 2020, GBC 34, e2019GB006170, doi:10.1029/2019GB006170 | §4, "On land" **[HTML, PMC7757245]** | Textbook offsets, not a model parameter |
| Direction only: heterotrophic tissues are ¹³C-enriched relative to leaves in C3 plants | review | Cernusak et al. 2009, Funct. Plant Biol. 36:199–213, doi:10.1071/FP08216 | abstract (search snippet only) | So leaf-tissue Δ likely **overstates** the flux-weighted photosynthate Δ. Magnitude not retrieved. |

### B3. C4 share of global GPP (the swing variable)

| f₄ | Period | Citation | Locator |
|---|---|---|---|
| **19.5 ± 1.9 %** (1 SE, bootstrap). **19.7 → 19.0 %** from 2001–05 to 2015–19. DGVM ensemble **14 ± 13 %**. Earlier estimates 18–23 %. | 2001–2019 | Luo et al. 2024, Nat. Commun. 15:1219, doi:10.1038/s41467-024-45606-3 | Abstract; Discussion ¶1; Results; Fig. 4d **[HTML, PMC10858286]** |
| 23 % | 1980s–90s | Still 2003 | abstract |
| 21 % | climatology | Lloyd & Farquhar 1994 | abstract |
| 20 ± 3 % (their synthesis); CMIP6 range 12–27 % | 2014 | Ovwemuvwose 2026 | §3.3 **[HTML]** |
| 18.5 % including crops (16.2 % natural) | 2001–2016 | Lavergne et al. 2026, Commun. Earth Environ., doi:10.1038/s43247-025-03102-6 | Results **[HTML, PMC12851932]** |
| 27 / 15 / 24 or 25 / ≈30 / < 10 % | various | Fung / Kaplan / Suits / van der Velde / Scholze | Suits Table 1; van der Velde Table 2 |

### B4. Harmonization to f₄ = 19.5 % (my arithmetic)

Δ_tot = (1 − 0.195)·Δ_C3 + 0.195·Δ_C4, using each paper's own endmembers:

| Study | Endmembers C3 / C4 | Published total (own f₄) | Mix at own f₄ (check) | **At f₄ = 19.5 %** |
|---|---|---|---|---|
| Lloyd & Farquhar 1994 | 17.8 / 3.6 | 14.8 (21 %) | 14.82 | **15.03** |
| Fung 1997 | 20.0 / 4.4 | 15.7 (27 %) | 15.79 | **16.96** |
| Kaplan 2002 | 20.0 / 3.5 (their "3 to 4") | 18.1 (15 %) | 17.53 | **16.78** |
| Still 2003 | implied C3 20.11 if C4 = 4.4 | 16.5 (23 %) | by construction | **17.05** |
| Suits 2005 | 19.2 / 4.4 | 15.9 (24 %) | 15.65 | **16.31** |
| van der Velde 2014 | 19.5 / 4.4 | 15.2 (30 %) | 14.97 | **16.56** |

- **Mean 16.45, median 16.67, sd 0.74, range 15.03–17.05.**
- The simple mix reproduces the published totals only to within −0.1 to +0.6 ‰, because each paper weights per grid cell. Adding each paper's residual back gives a mean of 16.61.
- **With leaf endmembers** (20.7 / 6.3) instead: 17.89 at 19.5 %, 17.39 at 23 %. Leaf-tissue Δ is likely an upper bound (Cernusak 2009 direction).
- **Registry check:** at the registry's "25 % C4" the Lloyd & Farquhar endmembers give **14.25, not 14.8**. The abstract's 21 % reproduces 14.82.

### B5. Values used by comparable global budget / box models

| Value | Model | Citation | Locator | Primary / secondary |
|---|---|---|---|---|
| **18 ‰, constant** in the standard run. Variants: linear in CO₂; or constant 1765–1955, then linear in time. | 3-box land + 1-D diffusive ocean | Keeling et al. 2017, PNAS 114(39):10361–10366, doi:10.1073/pnas.1619240114 | Results ¶1 and SI Table S1 (SI not read) **[HTML, PMC5625891]** | Primary (main text) |
| **18 ‰ constant** ("standard mode"). The original 3-box configuration overpredicts the δ¹³CO₂ decline at constant Δ. | Graven et al. 2020 simple carbon-cycle model | as described by Lavergne et al. 2026 | Methods ("Simple carbon cycle model"); Results, Fig. 6 **[HTML]** | Secondary for Graven 2020. Graven's own SI Text S1/S2 failed to load. |
| C3 **18** / C4 **6**, constant (test); C4 box with zero CO₂ fertilization | Graven 2020 box model, re-partitioned | Lavergne et al. 2026 | Results / Fig. 6; Methods **[HTML]** | Primary |
| α(atm→biosphere) = **0.982**, i.e. ε = 18 in CCX's form; biosphere fractionation variation "assumed to be negligible" | Enting–Lassey box-diffusion model | Trudinger 2001 PhD thesis, Ch. 4 (CSIRO e-print `trudinger_2001a4.pdf`) | Table 4.1, p. 126; §4.2, p. 122 (pdftotext) | Primary |
| **18.0** | double deconvolution | Francey et al. 1995 | van der Velde Table 2 p. 6559 | Secondary (not read) |
| **18.7** | Bern double deconvolution | Joos & Bruno 1998, GBC 12:277–295, doi:10.1029/98GB00746 | van der Velde Table 2 p. 6559 | Secondary. Bern repository blocked (Anubis). |
| **−17 ± 5** a priori (1970–1990), from Bakwin 1998 | budget inversion | Quay et al. 2003, GBC 17(1):1004 | Table 3, PDF p. 16 (on disk, per the citation-needs note) | Primary (on disk) |
| Latitude- and time-varying, computed from SiB runs | 2-D inversion | Ciais et al. 1995, JGR 100(D3):5051–5070 | Abstract (search snippet) | No number obtained |

### B6. Atmosphere-derived (regional, not global)

- **Lai et al. 2004** (GBC 18, doi:10.1029/2003GB002148): δ¹³C of NEE is −27.1 ± 2.7 to −28.3 ± 2.5 ‰ at C3 forests and −22.6 ± 4.0 ‰ at a prairie. Abstract **[HTML, EarthRef ERR 80953]**. These are site signatures, not Δ.
- **Miller et al. 2003**, as plotted in Suits 2005 Fig. 8 (p. 12): NH 20–60°N growing-season flux δ¹³C mostly between about −23 and −26 ‰. Against the canopy air δ of −7.9 ‰ that Suits holds fixed, that implies Δ ≈ 15–18 ‰. My reading of a figure, approximate.
- **Randerson et al. 2002:** northern biomes 19.0–19.6 ‰. Secondary (search snippet); not read.
- **Bakwin et al. 1998** (GBC 12:555, doi:10.1029/98GB02265): not read. It is the source of Quay's 17 ± 5.

---

## (c) Time dependence over 1750–2024

**C3 physiology, evidence for an increase:**
- **Keeling et al. 2017** infer **+0.014 ± 0.007 ‰ ppm⁻¹**, mostly explained by photorespiration and mesophyll effects (abstract). Over 1975–2005 that is +0.66 ± 0.34 ‰, given once as 0.65 ± 0.33 (Results).
  - Discussion, Eq. 1 decomposition: photorespiration 0.0041 ± 0.0014, mesophyll 0.006 ± 0.003, residual 0.004 ± 0.008 ‰ ppm⁻¹ **[HTML]**.
- **Ovwemuvwose 2026** (§1) and **Graven 2020** (§6) restate the +0.7 ‰ over 1975–2005.
- **Ovwemuvwose 2026** also cites Peters et al. 2018 for +0.4 ‰ in the NH over 2000–2011 (secondary).
- **Lavergne et al. 2026** (model): total land Δ **+0.017 ± 0.001 ‰ yr⁻¹ = 0.010 ‰ ppm⁻¹** over 1982–2016. With their map, 0.007 ‰ ppm⁻¹ over 2001–2016 (Results **[HTML]**).

**Against a large increase:**
- **Keller et al. 2017** (BG 14:2641, doi:10.5194/bg-14-2641-2017). From 76 tree-ring records: small average 20th-century changes in Δ and cᵢ/cₐ, and iWUE up about 27 % since 1900. LPX-Bern matches; CLM4.5 roughly doubles the iWUE change (abstract **[HTML]**). Full-text numbers not obtained (PDF over 10 MB).
- **Lavergne et al. 2022:** JULES global Δ "stayed nearly constant" over 1979–2016, and the pooled tree-ring trend is not significant, p = 0.097 (Abstract; §3.1.2 **[HTML]**).
- **Scholze et al. 2003**, via Ballantyne 2011 (BGD p. 4617, l. 22–24): a modeled ≈0.4 ‰ **decrease** in discrimination, mainly from increased water stress. Secondary.

**Composition (C3/C4):**
- **Kaplan 2002:** the agricultural mask lowers Δ_e by **0.5 ‰** (18.6 → 18.1), mostly from C4 crops on naturally C3 land (abstract).
- **Keeling 2017:** Scholze's estimate that C3/C4 shifts lowered NPP-weighted Δ by ∼0.5 ‰ since preindustrial is "likely an upper bound"; adding it moves the inferred sensitivity only from 0.014 to 0.013 (Discussion **[HTML]**).
- **Ovwemuvwose 2026:** C3/C4 GPP shifts change Δ by **−0.35 to +0.11 ‰** over 1975–2005. Over 1850–2014 most CMIP6 models decrease, CESM2 is flat and two models rise (Abstract; §3.4).
- **Luo 2024:** f₄ fell from 19.7 to 19.0 % (2001–05 to 2015–19), which raises Δ by about **+0.10 ‰** (my arithmetic, ×14.5).
- **Lavergne 2026:** C4 biomass share fell from 15.8 to 12.2 % over 1982–2016. The CO₂ effect on natural C4 grasses outweighs crop expansion.

**Magnitudes for CCX** (my arithmetic). CO₂ values come from the repo: 1750 = 277.01 ppm (`data/obs_icecore.rds` co2_spline); 2024 ≈ 422.3 ppm (mean of MLO_NOAA 424.60 and SPO_NOAA 420.09, `data/obs_co2_monthly.rds`).

| Assumption | Δ change |
|---|---|
| Keeling slope, 1750 → 2024 (+145 ppm) | **+2.03 ± 1.02 ‰** |
| Keeling slope, process-model era (≈1995, ≈360 ppm) back to 1750 | **−1.16 ± 0.58 ‰** |
| Keeling slope, ≈1995 forward to 2024 | **+0.88 ± 0.44 ‰** |
| Tree rings / JULES | ≈0 |
| Land-use C4 | 0 to −0.5 ‰ preindustrial → present |

**Which constant best represents the period:**
- Every global process estimate sits in **1983–2008** (Suits, Still, van der Velde).
- If Keeling's trend is real, a constant 16.5 anchored there overstates the 1750 value by about 1.2 ‰ and understates 2024 by about 0.9 ‰. If the tree-ring and JULES evidence is right, the constant holds.
- Two physical arguments push in opposite directions over 1750–2024 (physiology up, land-use C4 down), and their sizes are disputed. A **constant anchored on the modern era** is therefore defensible.

**Is a time-varying form standard?**
- **No.** In comparable box models the standard is a **constant 18** (Keeling 2017 standard run; Graven 2020 "standard mode"; Trudinger, which assumes the variation negligible).
- The **CO₂-linear form** is the main published alternative (Keeling 2017; Lavergne 2026 "CO₂-driven"). Graven 2020 uses a CO₂-dependent form after Schubert & Jahren 2015 for projections only (§8); its coefficients are in SI Text S2, not read.
- Process models (LPJ, SiBCASA, JULES) compute Δ prognostically.
- Both budget studies found that a **constant** Δ makes the modeled δ¹³C decline steeper than observed (Keeling 2017 Results; Lavergne 2026: a 0.30 ‰ gap over 2012–2016 at constant Δ, 0.16 with varying Δ, 0.08 with varying Δ and f₄). This bears on the trend, not on the level of the constant.

---

## (d) Where the "16.5" comes from

1. **Still et al. 2003, abstract** (EarthRef ERR 74609 rendering, where the unit glyph shows as "?"): the assimilation-weighted terrestrial discrimination is −16.5 ‰. Ovwemuvwose 2026 §3.4 quotes the same 16.5 ‰. This is the only primary source of the number. It is a C3 + C4, GPP-weighted global value at 23 % C4.
2. **The bracket "14.8–16.5" is printed in Ballantyne et al. 2011** (BG 8:3093–3106, doi:10.5194/bg-8-3093-2011, p. 3093, Introduction, right column; also BGD 8:4603, p. 4604 l. 22–26):
   - It gives a global flux-weighted fractionation "between −14.8 ‰ and −16.5 ‰ (Fung et al., 1997; Suits et al., 2005)".
   - ⚠ **The citation does not match the numbers.** Fung gives 15.7 (abstract range 12–16) and Suits gives 15.9.
   - The endpoints are exactly **Lloyd & Farquhar 1994 (14.8)** and **Still 2003 (16.5)**.
   - This is the most likely origin of CCX's "14.8–16.5" bracket, whether copied directly or by pairing Lloyd & Farquhar with Still.
3. **The registry's "Still 2003 / Suits 2005: 15–18 permil" is also unsourced.** Neither paper gives that range. Suits' Table 1 spans 14.8–18.6 across four studies.
4. **Registry error:** "total 14.8 at **25 %** C4" should read **21 %** (Lloyd & Farquhar abstract; Suits ¶10 and Table 1; van der Velde Table 2). See B4.

---

## (e) Structural caveats (methodological choices, flagged for Marcus)

1. **GPP-weighted versus sink-weighted.** In CCX the net land sink and the land-use emissions carry the same ε as gross GPP.
   - Fung 1997's abstract says land/ocean partitioning needs, among other things, "the fractions of C3 and C4 vegetation involved in the biospheric uptake".
   - Scholze 2008's abstract: the C4 land-use experiment shifts about 1 PgC yr⁻¹ from inferred land sources to ocean fluxes in a double deconvolution.
   - The Graven/Lavergne box model gives C4 zero CO₂ fertilization (Lavergne 2026 Methods).
   - If the fertilized sink is C3-dominated, its effective Δ is nearer the C3 value of about 19–20 than the GPP-weighted 16.5. That may be why budget models keep 18.
   - One constant cannot serve both the gross exchange and the net sink. Options: (i) GPP-weighted 16.5, the literal answer to the question asked; (ii) an effective about 18 as in the budget models; (iii) a structural C3/C4 split. **Not resolved here.**
2. **Hemispheres.** No hemispheric C3 + C4 value was found in any text read; they exist only as maps or zonal plots (Suits Fig. 4 and 8; van der Velde Fig. 2a). CCX applies one scalar to both hemispheres. The NH seasonal δ¹³C rows see a mostly C3 extratropical source. Miller 2003's NH flux signatures (Suits Fig. 8) imply roughly 15–18 ‰, a figure reading only.
3. **Interannual variability** is 0.3 ‰ (Scholze thesis) or ±0.04 ‰ detrended (van der Velde). Both are negligible for a constant.

---

## (f) What I searched

**Read (primary):**
- Suits 2005 (full PDF)
- van der Velde 2014 (full PDF)
- Ballantyne 2011 BG and BGD (full PDFs)
- Trudinger 2001 thesis Ch. 4 (PDF)
- Scholze thesis abstract (PDF)
- Lloyd & Farquhar 1994 (Springer abstract)
- Still 2003 (EarthRef abstract)
- Fung 1997 (Carnegie abstract)
- Kaplan 2002 (Lund abstract)
- Scholze 2008 (Lund abstract)
- Lai 2004 (EarthRef abstract)
- Keeling 2017 (PMC full text, SI not read)
- Graven 2020 (PMC full text, SI not loaded)
- Lavergne 2022 (PMC)
- Lavergne 2026 (PMC)
- Luo 2024 (PMC)
- Ovwemuvwose 2026 (BG HTML)
- Keller 2017 (BG abstract page)

**Searched, number not obtained:**
- Scholze 2003 GRL (403 at Wiley, MPG and EPFL)
- Joos & Bruno 1998 (Bern repository blocked)
- Rubino 2013 (Keele 403)
- Francey 1995; Bakwin 1998; Ciais 1995 full text; Randerson 2002
- Schubert & Jahren 2012 / 2015 coefficients
- Lavergne 2019 (GCB review) and 2020 (New Phytol.)
- Keller 2017 full-text numbers (PDF over 10 MB)
- Keeling 2017 SI Table S1 (PNAS 403)
- Graven 2017 GMD (CMIP6 isotope compilation; not opened, no discrimination parameter expected)
- Cornwell 2018 (endmembers seen only via Ovwemuvwose)

**Query themes:**
- Each candidate paper by title
- "assimilation-weighted terrestrial discrimination"
- "global flux-weighted" discrimination
- C4 share of GPP
- secular increase in discrimination
- box-model 13C fractionation 18 permil
- tree-ring Δ trends
- CMIP6 C3/C4 discrimination
- 2024–2026 updates

**Vintages:** 1994, 1997, 2002, 2003, 2003/2008, 2005, 2011, 2014, 2017 (×2), 2020, 2022, 2024, 2026 (×2). The two 2026 papers and Luo 2024 are the newest. They move the C4 share (19.5 %) and the endmember route upward (16.9–19.5, leaf-based). They do not overturn the process-model central of about 16.5.
