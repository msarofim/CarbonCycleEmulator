# Literature provenance: `NPP_GLOBAL_PI` (global preindustrial terrestrial NPP)

2026-09-29. Literature check only. **No code changed.** `R/constants.R` still has
`NPP_GLOBAL_PI = 60 GtC/yr`, `status = "provisional"`.

## What the constant is (from the code)

- `R/model.R:3849-3850`: `npp0[NH/SH] = NPP_GLOBAL_PI * npp_frac_NH / (1 - npp_frac_NH)`. This is
  the NPP₀ of DESIGN.md §3.3. NPP(t) = NPP₀·(1 + β ln(χ/χ₀)), and preindustrial steady state sets
  R_het = NPP₀ and the pool sizes.
- DESIGN.md §3.3: NPP₀ is scaled by `(1 − c)`, where c is the cleared fraction from cumulative LUC.
  So NPP_GLOBAL_PI is **total land NPP (above + below ground) at χ₀, before the model's own
  clearing**. That puts it close to a *potential-vegetation* NPP at preindustrial CO₂ and climate.
  Whether it should instead be *actual* 1750 NPP (after pre-1750 clearing, with 1750 cropland) is
  a methodological choice this note does not settle. **Flagged for Marcus.**
- Crops: the model has no separate cropland NPP, so the global number implicitly includes whatever
  replaced the natural vegetation.
- `data-raw/build_npp_hemispheric.R:46` and `R/calibrate.R:659` already record that MOD17's
  modern total sits below 60.

## Sources opened this session

"Verified" means I read the number in the source's own text, table or data this session.
"Abstract-only" means I read only the abstract. Vintage is the publication year; component data
can be older and is noted where it is.

| # | Source | Value (PgC/yr) | Status | Where | Scope | Period the number describes | Vintage |
|---|---|---|---|---|---|---|---|
| 1 | Prentice et al. 2001, IPCC TAR WG1 Ch.3 (no DOI; ISBN 0-521-01495-6; PDF `ipcc.ch/site/assets/uploads/2018/03/WGI_TAR_full_report.pdf`) | **"about 60"** | verified (full text) | §3.2.1, p.191: "Global terrestrial NPP has been estimated at about 60 PgC/yr through integration of field measurements (Table 3.2) (Atjay et al., 1979; Saugier and Roy, 2001)" | Total terrestrial NPP. Actual land cover, crops included | Contemporary (field integration). Fig 3.1 is for the 1980s | **2001, oldest in the stack** |
| 1a | same, Table 3.2, "Total" row, Atjay column (WBGU 1988 / Atjay et al. 1979) | **59.9** | verified | Table 3.2, NPP column | Biome sum. Croplands 6.8, wetlands 4.3 included | Contemporary | 2001 (data 1979) |
| 1b | same, Table 3.2, "Total" row, MRS column (Mooney, Roy & Saugier 2001 = Saugier & Roy 2001) | **62.6** | verified (via the TAR table, not the book chapter itself) | Table 3.2 | Biome sum. Croplands 4.1. No wetlands class | Contemporary | 2001 |
| 2 | Haberl et al. 2007, PNAS 104:12942, doi:10.1073/pnas.0704243104 | **NPP₀ = 65.51** (potential) | verified (full text, PMC1911196) | Table 1. NPP₀ from the LPJ DGVM (Methods) | **Potential natural vegetation**, above + below ground (aboveground alone 35.38) | Year-2000 climate and CO₂ | 2007 |
| 2a | same | **NPP_act = 59.22** (actual) | verified | Table 1. ΔNPP_LC = 6.29 (9.6 %) | Actual land cover, crops included, above + below ground | Year 2000 | 2007 |
| 3 | Ito 2011, Glob. Change Biol. 17:3161-3175, doi:10.1111/j.1365-2486.2011.02450.x | **56.2 ± 14.3 (mean ± 1 sd), median 56.4** | **abstract-only** (Crossref abstract; Wiley full text 403) | Abstract | "Total terrestrial NPP at the present time", n = 251 estimates, 1862-2011 | Present day | 2011 |
| 3a | same | preindustrial NPP_T | **NOT VERIFIED** | Abstract says it was "assessed" but gives no number. Paywalled | — | Preindustrial | 2011 |
| 4 | MOD17A3HGF C6.1 (Running & Zhao, doi:10.5067/MODIS/MOD17A3HGF.061; ICDC regrid doi:10.25592/uhhfdm.14635), processed in this repo | **52.7** (2001-2023 mean) | verified (data on disk: `data/obs_npp_hemispheric.rds$global_mean_PgC`) | built by `data-raw/build_npp_hemispheric.R` | Actual land cover, crops included. Valid MODIS pixels only (barren/ice/water excluded) | 2001-2023 | data 2001-2023, **most recent** |
| 5 | Zhao & Running 2010, Science 329:940, doi:10.1126/science.1192666 | only a trend: −0.55 PgC change 2000-2009 | abstract-only (PubMed 20724633). No global total in the abstract | Abstract | MOD17 | 2000-2009 | 2010 |
| 6 | Krausmann et al. 2013, PNAS 110:10324, doi:10.1073/pnas.1211349110 | HANPP 6.9 → 14.8 GtC/yr = 13 % → 25 % of NPP_pot, 1910 → 2005 | verified (full text, PMC3690849). **Does NOT state NPP_pot in PgC** | Abstract; Fig. 1 | NPP_pot from LPJ, varies with CO₂ (Fig. 1B caption) | 1910-2005 | 2013 |
| 6a | same, *implied* NPP_pot = HANPP / share | 6.9/0.13 ≈ 53 (1910), 14.8/0.25 ≈ 59 (2005) | **DERIVED by me, not stated.** Rounded percentages. Do not cite | — | — | — | — |
| 7 | IPCC AR5 WG1 Ch.6 (Ciais et al. 2013), Fig. 6.1 | **no land NPP.** Preindustrial (~1750) gross photosynthesis 108.9, total respiration + fire 107.2 | verified (full text) | Fig. 6.1 + caption. §6.5.2.1 says present-day land NPP is "approximately 50 to 60 PgC yr–1 (Nemani et al., 2003)" | GPP only in the figure | ~1750 (black numbers in the figure) | 2013 |
| 8 | IPCC AR6 WG1 Ch.5 (Canadell et al. 2021), Fig. 5.12 | **no land NPP.** Preindustrial gross photosynthesis 113 (+29 anthropogenic 2010-19), total respiration + fire 111.1 (+25.6) | verified (full text) | Fig. 5.12 + caption. The only NPP in the caption is **ocean** NPP (Kwiatkowski 2020) | GPP only on land | ~1750 (yellow numbers in the figure) | 2021 |

Not checked: Saugier & Roy 2001 as a primary chapter (book, not opened; its total is read only
through TAR Table 3.2), and any TRENDY/CMIP preindustrial-control NPP output.

## Which value is best supported, and is 60 inside the verified range?

Numbers only.

- **No verified source states a *preindustrial* global terrestrial NPP.** AR5 Fig 6.1 and AR6
  Fig 5.12 give 1750 fluxes as GPP only (108.9 and 113). Ito 2011 says it assessed preindustrial
  NPP, but the number was not reachable.
- Verified **present-day actual** NPP: 52.7 (MOD17, 2001-2023), 56.2 ± 14.3 (Ito 2011, abstract),
  59.22 (Haberl 2007, year 2000), 59.9 and 62.6 (TAR Table 3.2), "about 60" (TAR §3.2.1),
  "approximately 50 to 60" (AR5 §6.5.2.1, citing Nemani 2003).
- Verified **potential-vegetation** NPP (the closest scope to NPP₀ before clearing): 65.51
  (Haberl 2007, LPJ, but at **year-2000 CO₂ and climate**, not 1750).
- Span of the verified central values: **52.7 to 65.5**. **60 is inside it**, and inside Ito's
  ±1 sd band [41.9, 70.5].
- Direction (both from verified numbers, no magnitude claimed):
  (a) Moving from actual to potential vegetation *raises* NPP: 59.22 → 65.51 in Haberl, +6.29.
  (b) Moving from year-2000 CO₂ back to 1750 *lowers* NPP: Krausmann Fig 1B treats CO₂
  fertilisation as changing NPP_pot. The size of that change is not stated in the paper as a
  number, and I have not derived one. A 1750 potential NPP therefore falls **below 65.5** by an
  amount no source opened here quantifies.
- **Vintage.** The most recent verified totals are MOD17 (data to 2023; 52.7) and Ito 2011 (56.2).
  Both are below 60. The two sources nearest to 60 are TAR (2001, oldest; component data from 1979)
  and Haberl 2007. Recency as a tie-breaker leans toward the mid-50s for present-day actual NPP.
  None of these recent numbers is a preindustrial or potential estimate, though, so they do not
  bear directly on NPP₀.
- **Model consistency, recorded only.** With NPP₀ = 60 and CO₂ fertilisation making modern NPP
  higher than NPP₀, the model's modern NPP will sit above 60. That is above every verified modern
  total except TAR MRS (62.6) and Haberl NPP₀ (65.5). This matches the existing comment in
  `R/calibrate.R:659`. Whether that matters depends on the actual-vs-potential choice flagged above.

## Proposed citation comment (DRAFT, not applied)

The conditions are met: TAR §3.2.1 states "about 60 PgC/yr" directly, and Ito's ±1 sd band
contains 60. The scope mismatch has to travel with the citation:

```r
  NPP_GLOBAL_PI = list(
    value = 60, units = "GtC/yr",
    status = "cited",
    source = paste("Global terrestrial NPP, total (above + below ground). Value from IPCC TAR",
                   "WG1 Ch.3 (Prentice et al. 2001) sec. 3.2.1: 'about 60 PgC/yr through",
                   "integration of field measurements'; Table 3.2 totals 59.9 (Atjay 1979/WBGU)",
                   "and 62.6 (Mooney, Roy & Saugier 2001). Bracketed by Ito 2011 GCB 17:3161",
                   "(doi:10.1111/j.1365-2486.2011.02450.x; abstract) 56.2 +/- 14.3 (n=251,",
                   "present day) and Haberl et al. 2007 PNAS 104:12942 (doi:10.1073/pnas.",
                   "0704243104) Table 1: actual 59.22, potential 65.51 (LPJ, yr-2000 CO2/climate).",
                   "SCOPE CAVEAT: all are PRESENT-DAY estimates; no opened source gives a 1750",
                   "value (AR5 Fig 6.1 / AR6 Fig 5.12 give preindustrial GPP only, 108.9 / 113).",
                   "Used here as NPP0 before model clearing. Cited 2026-09-29, value unchanged.")),
```

Whether to set `status = "cited"` or keep `"provisional"` given the present-day/preindustrial
mismatch is Marcus's call. So is whether TAR (2001, oldest) should be the lead citation or only a
bracket.
