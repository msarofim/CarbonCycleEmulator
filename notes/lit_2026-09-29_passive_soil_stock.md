# Literature: how big and how old is the passive soil pool a global box model sees?

2026-09-29. A literature pass for the `tau_soil_slow` profile (CHANGELOG 09-29 (m)/(n)). The fit
weakly prefers 1000–1500 yr, which gives a passive stock of 3000–4500 GtC at fixed
`litter_slow_frac` 0.05. It gains +5.7 log-likelihood, bought by `d14c_NH`, `d14c_intcal` and
`d13c_level_MLO`. This note changes no code or data.

**Rules followed.** I opened every number below in the source named. The access level is marked
per row: **FULL** (full text or figure opened), **ABS** (abstract only) or **SNIP** (search-engine
summary only; treat as weaker). Anything I could not open is marked [UNVERIFIED]. Vintage is the
publication year. The oldest sources are Siegenthaler & Oeschger 1987, Batjes 1996, Lassey et al.
1996 and Joos et al. 1996.

Model reference point (R/model.R defaults): vegetation 516, responsive soil 114, passive soil
1500 GtC (NPP₀ 60 × 0.05 × 500 yr); land total ≈ 2130 GtC.

---

## 1. Global soil organic carbon stocks

| Source (vintage) | Access | Depth | Number | Permafrost / peat treatment |
|---|---|---|---|---|
| IPCC AR6 WG1 Ch5 **Fig. 5.12** (Canadell et al. 2021), p. 700 | FULL (figure viewed) | not stated in caption | **PI stocks: Vegetation 450, Soils 1700, Permafrost 1200 PgC** | "Soils" = *outside* the permafrost region (Batjes 2016; Jackson et al. 2017). Permafrost region from Hugelius 2014; Strauss 2017; Mishra 2021. Vegetation = "range of seven estimates" from Erb et al. 2018 |
| IPCC AR6 WG1 Ch5 **Box 5.1** (2021) | FULL | surface + deep deposits | Northern permafrost region **1460–1600 PgC**. Of that, permafrost soils and deposits hold **1070–1360 PgC**, with 300–400 in the first metre. Permafrost-free soils within the region hold **280–340 PgC** | — |
| Global Carbon Budget 2024, Friedlingstein et al. 2025, ESSD 17:965, **Fig. 2**, doi:10.5194/essd-17-965-2025 | FULL (figure viewed) | — | **Vegetation 450, Soils 1700, Permafrost 1400 GtC** | ⚠ The caption says these stocks are "taken from Canadell et al. (2021)", i.e. AR6. But AR6 Fig. 5.12 prints permafrost **1200**, not 1400. This is probably where the "permafrost 1400" in the brief came from. GCB is not an independent stock estimate |
| Jobbágy & Jackson 2000, Ecol. Appl. 10:423–436, doi:10.1890/1051-0761(2000)010[0423:TVDOSO]2.0.CO;2 | FULL (abstract, PDF from the authors' lab) | 0–1 / 1–2 / 2–3 m | **1502 Pg (0–1 m); 491 (1–2 m) and 351 (2–3 m); 2344 Pg (0–3 m)**, "56% more than" the first metre | Built from >2700 profiles; boreal/tundra were supplemented from Canadian data. Peat and permafrost are not separated |
| Batjes 1996, Eur. J. Soil Sci. 47:151–163, doi:10.1111/j.1365-2389.1996.tb01386.x | ABS | 0–0.3 / 0–1 / 0–2 m | SOC **684–724 (0–30 cm), 1462–1548 (0–100 cm), 2376–2456 Pg (0–200 cm)** | Excludes litter and charcoal |
| Batjes 2016 (WISE30sec), Geoderma 269:61–68, doi:10.1016/j.geoderma.2016.01.034 | ABS (WUR repository) | 0–2 m | **2060 ± 215 Pg C**, of which **607 ± 87 Pg** (~30 %) is in the Northern Circumpolar Region | Circumpolar share is given, but not as frozen vs thawed |
| Jackson et al. 2017, Annu. Rev. Ecol. Evol. Syst. 48:419–445, doi:10.1146/annurev-ecolsys-112414-054234 | FULL (PDF from the authors' lab) | 0–2 / 0–3 m | Abstract: **2270 (0–2 m) and 2770 Pg (0–3 m)**, "could be as much as 700 Pg smaller". §5.1, Table 2: **2273 Pg (0–2 m)**; peatlands **543**; permafrost regions **582** (26 %); **2800 Pg to 3 m**. Deeper (>3 m) permafrost deposits add **~300–500**. A bedrock-depth correction cuts WISE30sec from **2047 → 1354 Pg (0–2 m)** and **1425 → 1277 (0–1 m)** | Permafrost region soil C is "roughly equally divided between permanently and seasonally frozen soils". About 300 Pg of permafrost-region C is in peatlands; do not count it twice |
| Scharlemann et al. 2014, Carbon Management 5:81–91, doi:10.4155/cmt.13.77 | SNIP (paywalled). The range is corroborated by Jackson 2017 §5.1 | mostly 0–1 m [UNVERIFIED] | Median of 27 studies **1460.5 Pg C**, range **504–3000** | — |
| Shi et al. 2020 (see §2) | FULL | 0–0.3 / 0.3–1 m | **840 ± 280 + 1008 ± 505 = 1848 Pg** (mean of HWSD and SoilGrids). Permafrost **322 + 443**, non-permafrost **517 + 565** | Mineral soil only |
| Hugelius et al. 2014, Biogeosciences 11:6573–6593, doi:10.5194/bg-11-6573-2014 | ABS | 0–0.3 / 0–1 / 0–3 m / >3 m | Permafrost region **217 ± 12 (0–0.3 m), 472 ± 27 (0–1 m), 1035 ± 150 (0–3 m)**. Deltas >3 m **91 ± 52**, Yedoma >3 m **181 ± 54**. Total **~1300 (1100–1500) Pg**. Of that, **~500 Pg is in non-permafrost soils, the active layer or taliks, and ~800 Pg is perennially frozen** | This is the frozen vs thawed split a box model needs |
| **Peat:** Yu et al. 2010, GRL 37, doi:10.1029/2010GL043584 | ABS | full peat depth | Northern **547 (473–621) GtC**, tropical **50 (44–55)**, southern **15 (13–18)** | Accumulated since the Last Glacial Maximum |
| **Peat:** Hugelius et al. 2020, PNAS 117:20438–20446, doi:10.1073/pnas.1916387117 | ABS | full peat depth | Northern peatlands **415 ± 150 Pg C** over 3.7 ± 0.5 M km². "Nearly half" is permafrost-affected. Current sink **0.10 ± 0.02 Pg C/yr** | More recent and lower than Yu 2010 |

SoilGrids 2.0 (Poggio et al. 2021, SOIL 7:217, doi:10.5194/soil-7-217-2021): the abstract gives no
global stock, and I did not open the full text.

**Summary of stocks.** Mineral soil to 1 m is about 1300–1850 Pg across products. To 2 m it is about
2060–2450 Pg, and to 3 m about 2340–2800 Pg. These totals include the permafrost region. The
products that separate the permafrost region give about 1700 PgC outside it (AR6). Inside it, about
800 Pg is perennially frozen and about 500 Pg is not (Hugelius 2014).

## 2. Radiocarbon constraints on soil turnover and age

| Source (vintage) | Access | Number | What it means |
|---|---|---|---|
| **Shi et al. 2020**, Nat. Geosci. 13:555–559, doi:10.1038/s41561-020-0596-z | FULL (accepted version, MPG PuRe) | 789 Δ¹⁴C profiles. **Table 1**: carbon-weighted Δ¹⁴C in year 2000 is **−97 ± 24 ‰ (0–30 cm)** and **−391 ± 56 ‰ (30–100 cm)**. Mean age is **1390 ± 310 yr** and **8280 ± 2820 yr**. For 0–1 m: **−244 ± 48 ‰, 4830 ± 1730 yr**. Main text: **24 % (450 of 1848 Pg) is younger than 1000 yr**, nearly all of it in 0–30 cm. **1005 of 1008 Pg** of subsurface C is older than 1000 yr. Non-permafrost median age: 660 yr (0–30 cm) and 3420 yr (30–100 cm) | "Mean age" is the turnover time of a one-pool steady-state model fitted to each layer's Δ¹⁴C, then carbon-weighted. The paper says the bulk is supplied by "a very slow trickle of inputs" stabilised on millennial timescales |
| **He et al. 2016**, Science 353:1419–1424, doi:10.1126/science.aad4273 (volume and pages taken from Shi 2020's reference list) | ABS | 157 profiles to 1 m. Mean soil C age **3100 ± 1800 yr** (data) against **430 ± 50 yr** (ESMs). ESMs overstate 21st-century soil sequestration by **40 ± 27 %** | I could not open the full text, so I cannot report its fitted passive-pool turnover |
| **Copard et al. 2025**, Global Change Biol. 31(9):e70482, doi:10.1111/gcb.70482 (**newest source**) | FULL (PMC12405676) | 313 ISRaD profiles. Ancient, radiocarbon-free OC ("aOC", taken as F¹⁴C = 0) makes up **0.11 ± 0.10 of SOC (0–30 cm), 0.27 ± 0.18 (30–100 cm) and 0.51 ± 0.22 (>100 cm)** (Fig. 4B, Table 3). On the Batjes 1996 / J&J 2000 stocks that is **77 of 704 Gt, 216 of 801 Gt, and 464 of 910 Gt (1–2 m)**. With aOC removed, the ¹⁴C ages are **140 ± 570 / 420 ± 1230 / 800 ± 2140 yr** by layer. The 0–1 m mean is **290 ± 990 yr**, "contrasting sharply with previously reported values of 3100 to 4830 years" | ⚠ These are conventional ¹⁴C ages (−8267 ln F), not turnover times. They are profile means and the spread is large. The aOC split rests on a two-end-member mixing assumption. It **contradicts** the Shi/He reading and has not yet been tested by others |
| Trumbore 2000, Ecol. Appl. 10:399–411, doi:10.1890/1051-0761(2000)010[0399:AOSOMA]2.0.CO;2 | SNIP | At three forest sites (boreal, temperate, tropical), the mean age of bulk detrital and O/A-horizon C is **200–1200 yr**. Tropical soil respiration is dominated by C fixed less than 1 yr earlier | Site study, shallow horizons only |
| Sierra et al. 2017, Global Change Biol. 23:1763–1773, doi:10.1111/gcb.13556 | ABS | No numbers. Argues that "age", "turnover", "transit" and "residence" time are often confused | Mean AGE ≠ box TURNOVER TIME. This matters for §5 |
| Carvalhais et al. 2014, Nature 514:213–217, doi:10.1038/nature13731 | ABS (the headline number is elided in the API abstract) | Whole-ecosystem turnover is **15 yr** near the Equator and **255 yr** north of 75°N. Models underestimate the global value by **36 %**. Global mean is [UNVERIFIED] | Stock/GPP. Not a passive-pool constraint |
| Fung et al. 1997, GBC 11:507–533, doi:10.1029/97GB01751 | ABS | ¹³C isotopic disequilibrium of biospheric respiration **~0.33 ‰ for 1988**. Higher than earlier estimates because it uses "ages rather than turnover times" | Constrains the respiration age distribution, which bears on `d13c_level_MLO`. Not a stock |

## 3. Naegler & Levin 2006: where the model's targets come from

Naegler, T. & I. Levin (2006), *Closing the global radiocarbon budget 1945–2005*, JGR 111, D12311,
doi:10.1029/2005JD006758. **FULL** (local PDF: `~/Documents/2026/ClaudeDocs/Papers/`). It is
already transcribed in `data-raw/manual/naegler_levin_2006_budget.csv` and cited in DESIGN.md §3.1
and DATA.md §10.

- **Both numbers are confirmed.** **Table 4**, scenario YANG: biosphere excess ¹⁴C is **21.7 kmol
  (Jan 1975)** and **18.9 kmol (Jan 1995)**. The other scenarios give 22.0–22.2 and 19.2.
- **2200 PgC is confirmed, but it is a MODEL SETTING, not an observation.** Paragraph [15] reads:
  "The global biospheric carbon mass is 2200 PgC". It splits into **leaves 53 PgC (τ 2.5 yr),
  twigs 137 (6.5 yr), wood 773 (43.0 yr), and "almost immobile carbon in soils" 1238 PgC (τ 610
  yr)**, with NPP 60 PgC/yr. The authors describe it as "consistent with earlier work [Goudriaan
  1992; Post 1993; Mook 2000; Olson et al. 2001]". Details are in Naegler's 2005 thesis [not
  opened].
- The authors say simulated biospheric excess ¹⁴C "depend[s] strongly on model parameters such as
  turnover times, NPP, pool sizes", and that their model biosphere may be an underestimate.
- ⇒ **The 2200 PgC / 21.7 / 18.9 target is one model's configuration and that configuration's
  output. It is not independent evidence.** DATA.md §10 already says this about the ¹⁴C rows. The
  carbon-mass row has the same status. N&L's own passive pool is **1238 PgC at 610 yr**, which is
  close to the current default of 1500 at 500 yr.

## 4. Other box-model land benchmarks

| Model (vintage) | Access | Land pools at PI | Passive / soil pool |
|---|---|---|---|
| **Siegenthaler & Oeschger 1987**, Tellus B 39:140–154, doi:10.1111/j.1600-0889.1987.tb00278.x (**oldest**) | FULL (**Fig. 2** viewed) | G (ground vegetation) 100, W (wood) 500, D (detritus) 120, H (soils) 1500 GtC; **total 2220**; NPP 60 | **H = 1500 GtC with outflow 15 GtC/yr ⇒ τ = 100 yr** |
| **Joos et al. 1996** (Bern), Tellus B 48:397–417, doi:10.3402/tellusb.v48i3.15921 | FULL (scanned PDF, OCR'd p. 412) | Four pools, "ground vegetation, wood, detritus and soil organic carbon (Emanuel et al., 1984; Siegenthaler and Oeschger, 1987)". Overturning times **2.9, 20, 2.2 and 100 yr** | Same as S&O 1987. The pool sizes are not restated on the page I read |
| **Lassey, Enting & Trudinger 1996**, Tellus B 48:487–501, doi:10.3402/tellusb.v48i4.15928 | FULL (scanned, **Fig. 4 / Table 2** viewed) | Short-lived 140 GtC, long-lived **1419 GtC**; **total 1559**; NPP 60 | Long-lived τ = **150 yr**. Its size and turnover were calibrated jointly with the cosmogenic ¹⁴C production rate. The fitted production, **1.52 atoms/cm²/s**, is "at the low end of independent estimates". The authors suggest that reservoirs "coupled to the atmosphere with exchange times up to ~10,000 years may be too small", but blame mainly the diffusive ocean |
| **Naegler & Levin 2006** (GRACE) | FULL | 53 + 137 + 773 + 1238 = **2200 PgC** | **1238 PgC, τ 610 yr** |
| **This model (default)** | — | 516 + 114 + 1500 = **2130** | **1500, τ 500 yr** |

The classic box models put 1400–1500 GtC in their slowest land pool. Their total land is
1560–2220 GtC. Two of them (S&O, Bern) turn the slow pool over in 100–150 yr. Only GRACE (610 yr)
and this model (500 yr) use a centennial–millennial passive pool.

**The pre-bomb Δ¹⁴C / IntCal question.** In this model the cosmogenic production is **solved
for** in the spinup (R/spinup.R header), so `d14c_intcal` scores the 1750→1950 Suess decline, not
the absolute level. I found no source that says the pre-bomb Suess decline needs old soil carbon.
Lassey 1996 is the closest: there, the absolute level trades against the production rate and
long-exchange reservoirs, mostly the ocean. **Not found in this pass.**

## 5. Ice-core and δ¹³C constraints on the size of the biosphere

- Ciais et al. 2012, Nat. Geosci. 5:74–79, doi:10.1038/ngeo1324 (SNIP; paywalled). Gross
  primary production at the LGM was **~40 ± 10 Pg C/yr**, half of the pre-industrial value, yet
  the land held "only 330 Pg less carbon than pre-industrial". This constrains glacial–interglacial
  CHANGE, not the absolute pre-industrial stock.
- Fung et al. 1997 (§2) constrains the respired-C age distribution through the ¹³C disequilibrium.
- **I found no ice-core or δ¹³C constraint on the ABSOLUTE pre-industrial land stock.** Two
  searches only; not exhaustive.

---

## 6. What this implies for 1500 vs 3000–4500 GtC

### Evidence (from the sources above)

- **E1. Stock.** Outside the permafrost region, soil to the depths the products cover holds
  **~1700 PgC** (AR6 Fig. 5.12). The permafrost region adds **~500 Pg of unfrozen C** and
  **~800 Pg of perennially frozen C** (Hugelius 2014). All soil to 3 m, permafrost included, holds
  **2344–2800 Pg** (J&J 2000; Jackson 2017). Deeper permafrost deposits add 300–500 Pg (Jackson
  2017).
- **E2. Radiocarbon-free fraction.** Some soil C holds no ¹⁴C at all. Copard 2025 puts it at
  **11 % / 27 % / 51 %** by layer, about 760 of 2415 Gt in 0–2 m. This carbon does not exchange
  with the atmosphere on any timescale the model spans. The method is new and a single-study
  result.
- **E3. Age.** Carbon-weighted bulk Δ¹⁴C to 1 m is **−244 ± 48 ‰** in year 2000 (Shi 2020).
  Published mean ages to 1 m range from **4830** (Shi 2020) and **3100** (He 2016) down to **290
  yr** once aOC is removed (Copard 2025). These disagree by an order of magnitude, and the
  difference is mostly the aOC treatment.
- **E4. The existing 2200 PgC target is not an observation.** It is Naegler & Levin's GRACE
  configuration (§3). Older box models used 1560–2220 GtC of land in total.

### My reading (arithmetic and judgement, not from any source)

- **R1. On stock alone, 3000–4500 GtC is outside the evidence.** With 3000–4500 GtC in the
  passive pool, total land is 3600–5100 GtC. That is at or above the **whole** soil inventory to
  3 m (2344–2800 Pg) plus vegetation (~450), and it would count the frozen ~800 Pg and the
  radiocarbon-free fraction as exchanging. The carbon that exchanges on centennial–millennial
  scales (unfrozen, ¹⁴C-bearing soil) comes out at roughly **1200–2000 Pg**: about 1700 + ~500
  unfrozen, minus a 20–30 % aOC share. The default of 1614 GtC total soil sits inside that range.
- **R2. A ¹⁴C inventory check that does not depend on the aOC treatment.** The land's natural ¹⁴C
  decay sink scales with Σ C·F¹⁴C. Radiocarbon-free carbon adds zero to that sum, so the aOC
  debate cannot move it. Shi 2020 Table 1 gives 840 × 0.903 + 1008 × 0.609 ≈ **1370 GtC**
  (modern-equivalent, 0–1 m, year 2000). Removing the frozen deep permafrost lowers that; adding
  1–2 m raises it. A rough range is ~1200–1800. The model's soil value, from a steady-state
  one-pool formula with mean life 8223 yr and pre-bomb conditions, is **1530 at τ 500, 2180 at
  750, 2790 at 1000 and 3920 at 1500**. Only τ ≈ 500–750 falls in the range. **Caveats:** the
  data are year-2000 (topsoil inflated by bomb carbon) and the model is pre-bomb; permafrost is
  split using medians; and the ranges mix sources.
- **R3. The literature separates stock from age. The profile did not.** The profile varied
  `tau_soil_slow` at fixed `litter_slow_frac`, so stock rose with τ (stock = 3 GtC/yr × τ). The
  literature supports an OLD passive pool (E3) at a MODEST stock (E1), which means a smaller
  trickle of input. A 1500-yr pool holding 1500 GtC needs about 1 GtC/yr of input
  (`litter_slow_frac` ≈ 0.017). Its passive Δ¹⁴C (~−154 ‰) would be consistent with E3 while the
  stock stays consistent with E1. (m) freed both and still went to 2.6–5.6k, so the likelihood
  may want stock itself: more ¹⁴C mass, or more q10-released carbon. Two tests could tell these
  apart:
  - **(T1)** Profile τ **at a fixed passive stock of 1500**, co-varying `litter_slow_frac`. If
    the +5.7 survives, age buys it. If it vanishes, stock buys it, and stock conflicts with E1.
  - **(T2)** Report the model's soil Σ C·F¹⁴C and bulk soil Δ¹⁴C in year 2000 at each profile
    row, against Shi's 1370 GtC and −244 ‰ (0–1 m). Also report how the solved cosmogenic
    production moves with τ. By my rough estimate land is only ~6 % of total ¹⁴C decay, so that
    last check probably has little power.
- **Verdict (reading):** the independent evidence favours **~1500 GtC** (range ~1200–2000) for an
  exchanging passive pool. It does **not** support 3000–4500 GtC. It does allow the passive pool
  to be older than 500 yr **if** its input is cut rather than its stock raised. A gain of +5.7
  log units over a 2–3× stock range is small next to the E1 inventory, which is the constraint.
  If `tau_soil_slow` or the stock is released, the prior should come from E1, per the
  constants.R citation rule.

### Oldest sources

S&O 1987, Batjes 1996, Lassey 1996, Joos 1996, Fung 1997, J&J 2000, Trumbore 2000. The stock
conclusion does not rest on any of them: AR6 2021, Jackson 2017, Batjes 2016 and Hugelius 2014
carry it. The age question rests on Shi 2020 and He 2016 against Copard 2025. Copard is the newest
and would win the recency tie-breaker. It is also a single, method-dependent study.
