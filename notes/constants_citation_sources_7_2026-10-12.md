# Candidate sources for the 7 constants with nothing on disk — 2026-10-12

- **Serves:** `notes/constants_citation_needs_2026-10-12.md`, rows 1, 5, 13, 14, 16, 19, 21 and 22 (the "no candidate anywhere on disk" list), plus the production rate that rides with row 22.
- **Read-only.** No value, code, test or data file was changed. Nothing is committed. This file is the only file written in the repo.
- **Code read at:** HEAD `e6de59c`, which was committed by another session while this one ran. Code line numbers were re-checked against it. Uncommitted edits by another process were present in `R/model.R`, `R/forcing.R` and others; the cited lines were re-grepped after those edits.
- **How pages were read.** Web search plus WebFetch. WebFetch cached each PDF it fetched under the session's `~/.claude/projects/.../tool-results/` folder (outside the repo, automatic). I read those PDFs with `pdftotext` to stdout, so for PDFs the locators below come from the raw text layer. For HTML pages (Liu 2021, Verwega 2021, Wikipedia, PVEducation, AmeriFlux) WebFetch returns an extraction made by a helper model. Those locators should be checked by eye before they go into the registry. Each item says which method applied.
- **Access date for every URL:** 2026-10-12.
- **"My arithmetic"** marks every number I computed. It is a check, not a proposed value.
- **Quotes:** at most one short quote per source; everything else is paraphrase.

---

## Summary

| # | Constant (code value) | Best candidate value | Source and locator | Like-for-like? | Differs from code? |
|---|---|---|---|---|---|
| 1 | `PUMP_EPS13_ORG` (−20 ‰, organic export relative to surface DIC) | **−19 ‰** (an adopted constant). Observation-based modern surface offset ≈ **−23 to −25 ‰** (my arithmetic). | Liu, Six & Ilyina 2021, BG 18:4389, §3.2.2, Eq. 14 (citing Eide et al. 2017b, **not read**). Schmittner et al. 2013, BG 10:5793, p. 5794 (−21 ‰ organic vs about +2 ‰ DIC). Verwega et al. 2021, ESSD 13:4861, §3.1 Eq. 3 (mean δ¹³C_POC −23.96 ‰). | **Partly.** Liu's −19 has the same definition and sign (organic minus DIC) but is a constant chosen for a decomposition, not a measurement. The observations are modern, surface, absolute and not export-weighted. | Yes: −1 against Liu; +3 to +5 against the observational offset. |
| 5 | `OCEAN_DEPTH` (3700 m) | **3682.2 m** (±1.2 %, 1σ) | Charette & Smith 2010, Oceanography 23(2):112–114, Table 2, p. 114 | **Yes.** Mean depth = volume / area, SRTM30_PLUS V5. | Yes: code is +0.48 % (+17.8 m), inside the source's own 1σ of ±44 m. The registry's 3690 (Eakins & Sharman, **not read**) is +0.21 % from it. |
| 13 | Obliquity (−23.44°) | **23.439279°** at J2000.0 (= 84381.406″) | IERS Conventions (2010), TN 36, Ch. 5 (version of 10 Aug 2012), §5.6.2, p. 20; mean-obliquity series Eq. 5.40, p. 22 | **Yes** for the quantity. The epoch is J2000.0. It is 23.472° in 1750 and 23.436° in 2024 (my arithmetic). | No (rounds to 23.44). |
| 14 | +10-day phase in −23.44° cos(2π(N+10)/365.25) | **10 days** (Dec solstice → Jan 1 0h UT). Observed spacing is **9.85–10.43 d** (my arithmetic). | Formula form: Wikipedia "Position of the Sun" (**secondary**, no primary cited for this form). PVEducation attributes the cos(d+10) form to Cooper 1969 (**not read**). Solstice times: USNO seasons API. | **Partly.** Wikipedia counts N = 0 at Jan 1 0h UT, as the code does. PVEducation/Cooper count d = 1 on Jan 1, a 1-day shift. Both use 365, not 365.25. | No. |
| 16 | `CCX_SEAS_T_LAG` (2.0 months after mid-July) | **Not found** | — | No observational source for a respiration-weighted soil-temperature (or respiration-driver) phase. Soil heat conduction puts the lag at the respiring depth at about 0.2 months (my arithmetic). | n/a |
| 19 | `FORC_BOMB_NH_SHARE` (0.90, NH share of bomb-¹⁴C **delivery to the troposphere**) | **No direct value.** Published proxies give **0.77–0.98** (my arithmetic). | UNSCEAR 2000 Annex C: Table 6 p. 209 (fission-debris injection, NH 0.894); Table 7 pp. 210–211 (measured ⁹⁰Sr hemispheric deposition, NH 0.768); Table 2 p. 205 (fusion yield by test site, NH 0.932–0.982 depending on how equatorial sites are split). | **None are like-for-like.** ⁹⁰Sr deposition is the closest physical analogue (stratospheric debris reaching the surface by hemisphere), but it is fission-weighted and particulate, while ¹⁴C is fusion-weighted and gaseous. | 0.90 sits inside the proxy range. ⚠ The fusion-yield proxy with Christmas Island split 50/50 gives 0.953, which collides with `FORC_NUC_NH_SHARE` = 0.95. |
| 21 | `P_canon` production (2.04 atoms cm⁻² s⁻¹) | Preindustrial (1750–1900): **1.88** (cosmic-ray model) or **1.75** (carbon-cycle budget) | Kovaltsov, Mishev & Usoskin 2012, EPSL 337–338:114 (arXiv v1 p. 5, lines 126–128). Roth & Joos 2013, Clim. Past 9:1879, p. 1894. | **Yes** for epoch and definition: global mean per cm² of Earth's surface, averaged over 1750–1900. | **Yes.** 2.04 is +8.5 % over 1.88 and +16.6 % over 1.75 (my arithmetic). It matches the Masarik & Beer values (2.02 in 1999; 2.05 at Φ = 550 MeV in 2009), seen **only secondarily**, which both newer papers call too high. |
| 22 | Earth surface area (5.1e14 m²) | **5.10066e14 m²** (my arithmetic from R₂) | Moritz 2000, "Geodetic Reference System 1980", J. Geodesy 74:128–133, §4 "Numerical Values", p. 131: R₂ = 6 371 007.1810 m | **Yes.** Area of the GRS80 ellipsoid = 4πR₂². | −0.013 % (negligible). |

**Unsourced after this pass:**
- **16** (no observational source found).
- **19** (no published hemispheric split of bomb-¹⁴C delivery; only proxies).

**Weakly sourced:**
- **1**: the only same-definition number is an adopted constant whose origin (Eide 2017b) I could not open.
- **14**: the exact form is sourced only to Wikipedia; the attributed primary, Cooper 1969, was not read.

---

## 1. `PUMP_EPS13_ORG` = −20 ‰

**What the code means by it.**
- `add_flux()` (`R/model.R:2447+`) multiplies the **source** box's ¹³C/¹²C ratio by `alpha13`. The pump legs call it with `alpha13 = 1 + PUMP_EPS13_ORG/1000` (`R/model.R:3210, 3216, 3223, 3443`; `R/cpp.R:96`).
- So ε = 1000·(R_export/R_surfaceDIC − 1) = −20 ‰. Exported organic carbon is 20 ‰ **lighter than the surface DIC it is drawn from**.
- Like-for-like means: organic export relative to **DIC** (not CO₂(aq)), negative sign, export-weighted, held constant from 1750.
- ε and δ_org − δ_DIC differ by a factor (1 + δ_DIC/1000). That is about 0.04 ‰ at δ_DIC = +2 ‰ (my arithmetic), which is negligible.

**Candidates.**

1. **Liu, B., Six, K. D. & Ilyina, T. (2021).** Incorporating the stable carbon isotope ¹³C in the ocean biogeochemical component of the Max Planck Institute Earth System Model. *Biogeosciences* 18, 4389–4429. doi:10.5194/bg-18-4389-2021.
   - **Locator:** §3.2.2, Eq. (14) and the sentence after it. Δphoto, "the carbon isotope fractionation during marine photosynthesis", is set to **−19 ‰**, citing Eide et al. (2017b), with R_C:P = 122 (Takahashi et al. 1985).
   - The same section says that in reality Δphoto varies in space with CO₂(aq), and that using a constant has limited quantitative impact on their comparison.
   - **URL:** https://bg.copernicus.org/articles/18/4389/2021/bg-18-4389-2021.html (WebFetch extraction of the HTML; check by eye).
   - **Definition:** Eq. 14 is a Broecker & Maier-Reimer-type decomposition: δ¹³C_DIC,bio = δ¹³C_DIC,MO + (Δphoto/DIC_MO)·R_C:P·(PO₄ − PO₄,MO). From that structure Δphoto is the offset of remineralised organic carbon from DIC, so it has the **same definition and sign as the code's ε** (my reading of the equation; the text does not name the reference pool).
   - **Check:** −19 × 122 / 2200 = −1.05 ‰ per µmol kg⁻¹ PO₄ (my arithmetic, DIC ≈ 2200 assumed), close to the classic δ¹³C–PO₄ slope.
   - **Status:** an adopted constant for a diagnostic, not a measurement. Its stated origin, **Eide, M., Olsen, A., Ninnemann, U. S. & Johannessen, T. (2017b), GBC 31:515–534, doi:10.1002/2016GB005473, was NOT read** (Wiley returned 403). Vintage 2021, citing 2017.
   - Same paper, model output (not observations): global-mean surface δ¹³C_POC −22.5 ‰ (Hist_Popp, 1960–1991 climatology; §3.1, Fig. 3a) and surface δ¹³C_DIC 1.64 ‰ (1990–2005; §3.2.1, Fig. 5a). The difference is about −24.1 ‰ (my arithmetic; the two periods differ).
   - Appendix D says model δ¹³C_POC fell by 2.2 ‰ from preindustrial to the 1990s, mostly from rising εp under higher CO₂(aq). So a **preindustrial** offset is smaller in magnitude than a modern one.

2. **Schmittner, A., Gruber, N., Mix, A. C., Key, R. M., Tagliabue, A. & Westberry, T. K. (2013).** Biology and air–sea gas exchange controls on the distribution of carbon isotope ratios (δ¹³C) in the ocean. *Biogeosciences* 10, 5793–5816. doi:10.5194/bg-10-5793-2013.
   - **Locators (pdftotext of the Copernicus PDF):**
     - p. 5794, Introduction: typical bulk marine organic matter is about −21 ‰ against a mean surface δ¹³C_DIC near +2 ‰. That is an offset of about **−23 ‰** (my arithmetic). It is an introductory statement with no table.
     - p. 5796, §2.2, Eq. (7): their εp parameterisation (Popp et al. 1989, relative to CO₂(aq)).
     - p. 5799, text after Eqs. 15–16: they fix δ¹³C_org = −21 ‰ (absolute) for their decomposition.
     - p. 5806, §5.2.1: the observed δ¹³C_POC meridional pattern (Goericke & Fry 1994 compilation) runs from about −20 ‰ at low latitudes to −25 to −30 ‰ at high latitudes.
   - **URL:** https://bg.copernicus.org/articles/10/5793/2013/bg-10-5793-2013.pdf
   - **Like-for-like:** the −21 vs +2 statement gives the right definition (organic minus DIC), but it is a round-number statement for the modern ocean, not export-weighted.

3. **Verwega, M.-T., Somes, C. J., Schartau, M., Tuerena, R. E., Lorrain, A., Oschlies, A. & Slawig, T. (2021).** Description of a global marine particulate organic carbon-13 isotope data set. *Earth Syst. Sci. Data* 13, 4861–4880. doi:10.5194/essd-13-4861-2021.
   - **Locators (WebFetch extraction of the HTML; check by eye):**
     - 4732 δ¹³C_POC points from the 1960s on (abstract);
     - arithmetic mean of the collection **−23.96 ‰** (§3.1, Eq. 3);
     - median −22.46 ‰ (§4.2);
     - 1990s Atlantic-section medians ≥ −22 ‰ below 30° latitude, about −24 ‰ in the Arctic and ≤ −28 ‰ in the Southern Ocean (abstract);
     - median δ¹³C_POC fell by more than 3 ‰ since the 1960s in all basins except the Southern Ocean (abstract).
   - **URL:** https://essd.copernicus.org/articles/13/4861/2021/essd-13-4861-2021.html
   - **Like-for-like: no.** These are absolute δ¹³C (not relative to DIC), modern (Suess-affected), mostly surface, and not export-weighted.
   - Subtracting a modern surface δ¹³C_DIC of about +1.5 ‰ from the −23.96 ‰ mean gives about −25.5 ‰ (my arithmetic, unweighted). This is an observation-based bound, not a value to adopt.

**Verdict.**
- No export-weighted, preindustrial, DIC-referenced measurement was found.
- The code's −20 ‰ lies between the adopted −19 ‰ constant (Liu 2021 via Eide 2017b) and the modern observational offset of about −23 to −25 ‰ (my arithmetic).
- The preindustrial offset would be smaller in magnitude than the modern one (Liu 2021 App. D).
- **Next step:** open Eide et al. 2017b to see where −19 comes from. It may in turn cite Broecker & Maier-Reimer 1992 or a C:P-scaled δ¹³C–PO₄ slope.

## 5. `OCEAN_DEPTH` = 3700 m

**What the code means by it.**
- It is the column depth of the 1-D box-diffusion interior (`ccx_ocean_grid(total_depth=)`), laid under an ocean area that sums to 3.619e14 m² (`OCEAN_AREA_NH/SH`).
- So the like-for-like quantity is **global ocean volume divided by ocean area**.

**Candidate.**
- **Charette, M. A. & Smith, W. H. F. (2010).** The volume of Earth's ocean. *Oceanography* 23(2), 112–114. doi:10.5670/oceanog.2010.51 (DOI from the publisher listing seen in search; it is not printed on the PDF).
- **Locators (pdftotext of the TOS PDF):**
  - **Table 2, p. 114** (Supporting Material): mean depth **3682.22 m**, area **361.841 × 10⁶ km²**, volume **1.33238 × 10⁹ km³**. Their 1σ uncertainties are 1.2 % (depth), 0.14 % (area) and 1.2 % (volume).
  - In the same table, the measured ("pinged") cells average 3504 m and the satellite-estimated cells 3700 m.
  - **p. 113**, text and Table 1: built from SRTM30_PLUS V5 (16 Sep 2008), 30-arc-second grid. Every cell below zero counts as ocean; no land-below-sea-level mask was applied; Antarctic ice-shelf cavities were not treated.
  - Table 1 also lists earlier estimates: Shiklomanov & Sokolov 1983, 3703 m; Baumgartner & Reichel 1975, 3733 m; Menard & Smith 1966, 3729 m.
- **URL:** https://tos.org/oceanography/assets/docs/23-2_charette.pdf
- **Like-for-like:** yes, it is volume over area. Their area (3.61841e14 m²) is within 0.02 % of the code's 3.619e14 (my arithmetic).
- **Value check (my arithmetic):**
  - 3700 is **+0.48 %** (+17.8 m) above 3682.2. That is inside the source's own 1σ (±44 m).
  - The registry's off-disk 3690 m (Eakins & Sharman 2010) is +0.21 % above it.

**Not read or not usable.**
- **Eakins & Sharman 2010** (NOAA NGDC, "Volumes of the World's Oceans from ETOPO1"): the old NGDC URL now redirects to the ETOPO product page, and the Wayback Machine is not reachable from this tool. **Not read.**
- **Weatherall et al. 2015**, *Earth and Space Science* 2:331–345, doi:10.1002/2015EA000107 (GEBCO_2014): a search snippet of the abstract gives a grid "mean depth" of 3897 m and a median of 3441 m. The AWI repository blocked the fetch, so I did not see how it was averaged. It is far deeper than any volume/area estimate and is probably a different statistic. **Do not use** until the method is seen.
- **Costello, Cheung & De Hauwere 2010** (ES&T 44:8821; correction 2015): I found only a conference poster (total sea surface area 353 million km², volume ~1.3 billion km³) with no mean depth. Not used.

**Verdict.** This is a ruling, not a lookup, as the worklist says.
- Adopting 3682 m would mean a refit **plus** rebuilding the GLODAP deep-target layer bounds (`obs_glodap_deep.rds$model_layer`).
- Alternatively, 3700 can be kept as "Charette & Smith 2010 Table 2, 3682 ± 44 m (1σ); 3700 is +0.5 %, inside 1σ". This is the most recent and most fully documented volume/area estimate I could read. Vintage 2010; Eakins & Sharman is the same vintage.

## 13. Obliquity −23.44°

**What the code means by it.** It is the amplitude of the solar declination in `ccx_insol()` (`R/model.R:346-351`) and `seas_insol()` (`src/ccx_core.cpp:373-376`): dec = −23.44° · cos(2π(tt·365.25 + 10)/365.25). The quantity is the obliquity of the ecliptic, in degrees.

**Candidate.**
- **IERS Conventions (2010).** G. Petit & B. Luzum (eds.), IERS Technical Note No. 36, Verlag des Bundesamts für Kartographie und Geodäsie, Frankfurt am Main. Chapter 5, "Transformation between the ITRS and the GCRS" (chapter version of 10 August 2012).
- **Locators (pdftotext of the chapter PDF):**
  - **§5.6.2, p. 20:** the IAU 2006 mean obliquity at J2000.0 is ε₀ = **84381.406″** (the IAU 2000 value was 84381.448″).
  - **Eq. (5.40), p. 22:** ε_A = ε₀ − 46.836769″ t − 0.0001831″ t² + 0.00200340″ t³ − …, with t in Julian centuries (TT) from J2000.0.
- **URL:** https://iers-conventions.obspm.fr/content/chapter5/icc5.pdf
- **Conversion (my arithmetic):** 84381.406″ = **23.439279°**. Using the linear term of Eq. 5.40 only, the value is 23.4718° in 1750 and 23.4362° in 2024.
- **Like-for-like:** yes, at epoch J2000.0. 23.44 is that value to two decimals. The model applies one fixed value across 1750–2024, where the true value drifts by 0.036°. I did not measure the effect.
- **Secondary only:** Jenkins, A. (2013), *Eur. J. Phys.* 34:633, doi:10.1088/0143-0807/34/3/633, uses ε = 23.44° (arXiv:1208.1043, Eq. 3, arXiv p. 4) without deriving it.

## 14. The +10-day declination phase

**What the code means by it.**
- Model time is decimal years, with month centres at year + (m − 0.5)/12 (`R/forcing.R:339, 620`). So `tt·365.25` is **days since Jan 1, 0h**.
- The cosine reaches its minimum (December solstice) at tt·365.25 = −10, which is **Dec 22, 0h**.
- The code uses a 365.25-day period in both places, so the shape is exactly periodic in model years (the worklist's question iii).

**Formula sources.**

1. **Wikipedia, "Position of the Sun"**, section on declination. https://en.wikipedia.org/wiki/Position_of_the_Sun (WebFetch extraction).
   - **Formula:** δ = −23.44° · cos[(360°/365)·(N + 10)]. N counts days from **N = 0 at midnight UT as Jan 1 begins**; the 10 is the approximate number of days from the December solstice to Jan 1.
   - **Stated error:** up to about 2°. A version with an eccentricity term is good to < 0.2°.
   - The 23.44° is cited to the USNO "Selected Astronomical Constants, 2015" (pp. K6–K7). **No primary source is attached to the cos(N+10) form itself.**
   - **Status: secondary**, not citable as a primary.
2. **Honsberg, C. & Bowden, S., PVEducation / PVCDROM, "Declination Angle".** https://www.pveducation.org/pvcdrom/properties-of-sunlight/declination-angle (WebFetch extraction).
   - **Formula:** δ = −23.45° · cos[(360/365)(d + 10)], with **d = 1 on Jan 1**. It also gives the equinox-referenced form 23.45° sin[(360/365)(d + 284)].
   - It attributes the formula to **Cooper, P. I. (1969), "The absorption of radiation in solar stills", *Solar Energy* 12:333–346**, and says the error against an accurate algorithm is up to about 1°.
   - **Cooper 1969 was not read** (Elsevier).
   - **Status: secondary.**
   - **Identity (my arithmetic):** −cos(2π(N+10)/365) = sin(2π(N+283.75)/365). With d = N + 1, Cooper's (284 + d) form sits 1.25 days later in phase than the cos(N+10) form. The two published day-count conventions (N from 0 vs d from 1) differ by one day.

**Check against observed solstice times.**
- Source: USNO Astronomical Applications API (https://aa.usno.navy.mil/api/seasons?year=1850, …?year=2000, …?year=2023).
- December solstice: 1850 Dec 22 03:37 UT; 2000 Dec 21 13:37 UT; 2023 Dec 22 03:27 UT.
- Time to the following Jan 1, 0h UT: **9.85 d, 10.43 d and 9.86 d** (my arithmetic).
- So the 10-day offset is right to within ±0.5 day over the model's span.

**Verdict.**
- The value 10 is supported by observation (USNO).
- The formula's form has only secondary sources. The code's day-count origin (Jan 1, 0h) matches Wikipedia's N and is one day off PVEducation/Cooper's d.
- A primary source for the cos(N+10) form, with a stated accuracy, was **not found**. Cooper 1969 (sine form) is the commonly attributed primary and should be opened before it is cited.

## 16. `CCX_SEAS_T_LAG` = 2.0 months — NOT FOUND

**What the code means by it.**
- It is the phase of the seasonal temperature factor on **soil respiration**: q10^(a_t·sin(2π(t − (3.5 + LAG)/12))/10) (`R/model.R:806, 2861`). The comment at `R/model.R:271-285` explains it.
- With LAG = 0 the NH factor peaks in mid-July. With 2.0 it peaks in mid-September.
- The like-for-like observation would be the seasonal phase of the temperature that drives heterotrophic respiration (respiration-weighted soil temperature, hemispheric), or of heterotrophic respiration itself.

**What I found (none of it like-for-like).**
- **Zhang, Q., Phillips, R. P., Manzoni, S., Scott, R. L., Oishi, A. C., Finzi, A., Daly, E., Vargas, R. & Novick, K. A. (2018).** Changes in photosynthesis and soil moisture drive the seasonal soil respiration–temperature hysteresis relationship. *Agric. For. Meteorol.* 259:184–195. doi:10.1016/j.agrformet.2018.05.005.
  - Read at the abstract level only, via the AmeriFlux publication page https://ameriflux.lbl.gov/?p=7692.
  - Seasonal hysteresis between soil respiration and soil temperature appeared in 9 of 15 site-years. Most of the lag traced to **photosynthesis timing** (recent assimilate supply) and soil moisture, **not to a soil-temperature lag**. GPP–soil-temperature lags were common across 129 FLUXNET sites.
  - No lag lengths are given in what I saw.
  - **Relevance:** it suggests a 2-month "temperature" lag in the model is absorbing substrate and moisture effects.
- **Soil heat conduction (context, not a citation of the value).**
  - The annual temperature wave lags by z/D radians, where the damping depth is D = (2K/ω)^½.
  - Source for the relation: *Physical Processes in Ecosystems* (online textbook, bookdown.org/huckley), §13.5, Eqs. 13.12–13.14. Its worked example uses K = 8.4e-7 m² s⁻¹ (§13.5.2). That example is for the diurnal cycle and is a textbook illustration, not a measurement.
  - With that K and the annual ω (my arithmetic):
    - D ≈ 2.9 m;
    - the lag at 0.3 m is about **0.2 months** and at 0.1 m about 2 days;
    - a **2-month lag needs about 3 m of depth**, well below where heterotrophic respiration happens.
- **Melo Aguilar et al., EGU21-10351 poster** (Spain, 39 SoTOS stations, soil temperature at 5–100 cm). It shows a linear phase-vs-depth regression. It is regional and the numbers can only be read off a plot, so they are not quoted.
- **Air temperature:** the repo already holds the NH land air-temperature phase (`obs_seasonal_clim.rds`, model_lag 0.042). That is the wrong quantity, as the code comment says.

**Verdict: not found.**
- Physical soil-temperature lags at respiring depths are days to weeks, not 2 months (my arithmetic above).
- The 2.0 is an **effective, model-calibrated phase**. An observational "soil temperature lag" citation would **not** support it.
- This is the "derived / calibrated structural constant" branch of the worklist (name the model, mode and vintage per the threshold rule), or a free parameter. Which one is a ruling for Marcus.

## 19. `FORC_BOMB_NH_SHARE` = 0.90 — NO DIRECT VALUE

**What the code means by it.**
- It is the NH fraction of the **stratosphere→troposphere delivery** of bomb ¹⁴C. The forcing is Tans (1981) SCOPE 16's stratospheric decrease (`R/forcing.R:383-405`, `data-raw/build_bomb_c14_source.R`).
- Tans 1981 (pdftotext of https://scope.dge.carnegiescience.edu/SCOPE_16/SCOPE_16_1.4.5_Tans_131-157.pdf) gives a **global** stratospheric inventory only. I found no hemispheric split in it.

**Published proxies: UNSCEAR 2000, Annex C.**
- **Citation:** *Sources and Effects of Ionizing Radiation*, UNSCEAR 2000 Report to the General Assembly, Vol. I, Annex C, "Exposures to the public from man-made sources of radiation", United Nations, New York.
- **Copy read:** pdftotext of the NRC hearing-exhibit copy (ENT000362), https://www.nrc.gov/docs/ML1233/ML12338A672.pdf. Page numbers below are the report's own (Annex C pp. 157–).

1. **Table 6, p. 209**, "Estimated annual injections of nuclear debris into atmospheric regions" (fission energy, Mt).
   - Totals: **North 144, South 16.9, Global 161**. NH share **0.894** (my arithmetic).
   - Footnote a: debris from equatorial sites (Christmas Island, and the high-altitude Johnston Island tests) is split equally between hemispheres.
   - **Not like-for-like:** this is fission debris and it is injection, not delivery.
2. **Table 7, pp. 210–211**, ⁹⁰Sr hemispheric deposition, totals row.
   - Measured: NH 470 PBq, SH 142 PBq → NH share **0.768**.
   - Previously derived: 460 / 144 → 0.762.
   - Calculated: 499 / 111 → 0.818. (All shares are my arithmetic.)
   - ¶32 (p. 166) says the model attributes about 90 % of deposited ⁹⁰Sr to stratospheric debris.
   - **Closest physical analogue** of stratosphere→troposphere delivery by hemisphere, because tropospheric residence is short compared with interhemispheric mixing. But it is fission-weighted and particulate; bomb ¹⁴C is fusion-weighted CO₂.
3. **Table 2, p. 205**, yields by test site.
   - Fission, fusion and total yield are given per site.
   - Southern-hemisphere sites are Fangataufa, Mururoa, Monte Bello, Emu, Maralinga, Malden Island and "Atlantic" (Argus). Everything else is northern.
   - Christmas Island (1.9°N) and Johnston Island (16.7°N) lie north of the equator, but Table 6 footnote a splits their debris equally.
   - **Fusion-yield** NH share (my arithmetic; total fusion 250.55 Mt; SH sites 4.55 Mt):
     - **0.982** with sites assigned by latitude;
     - **0.953** with Christmas Island (14.5 Mt fusion) split 50/50;
     - **0.932** with Johnston Island also split.
     UNSCEAR ties ¹⁴C release to fusion energy (Table 9, footnote f: 251 Mt).
   - **Total-yield** NH share (my arithmetic): **0.974** by latitude, **0.940** with Christmas Island split.
   - **Not like-for-like:** this is production by injection site, not delivery to the troposphere.
4. **¶59, p. 171** (record only, so it is not mistaken for a candidate): the UNSCEAR ¹⁴C dose model adjusts hemispheric values to an **initial 4:1 NH:SH ratio**, held to 1970 and relaxed to 1:1 by 2000. That is a concentration/dose assumption, not a delivery share.

**Not read.** These sources should hold a ¹⁴C-specific hemispheric stratospheric inventory or delivery split:
- **Hesshaimer & Levin 2000**, JGR 105(D9):11641–11658, doi:10.1029/1999JD901134. The Heidelberg repository blocked the fetch; Wiley returned 403.
- **Enting 1982** (CSIRO Tech. Paper 6) and **Telegadas 1971**: not found online.
- **Naegler & Levin 2006** is on disk; the worklist found no share in it.

**Verdict: unsourced.**
- The proxy range is **0.77 (⁹⁰Sr deposition) to 0.98 (fusion yield by site)**, and 0.90 sits inside it.
- ⚠ **Coupling flag:** the fusion-yield proxy with Christmas Island split equally (0.953) equals `FORC_NUC_NH_SHARE` = 0.95 to two decimals.
  - The ¹⁴C tag's 2×2 solve stops when |bomb − nuclear| < `CCX_TAG_MIN_SHARE_GAP` = 1e-6 (`R/c14_tag.R:37, 50-51`).
  - So 0.953 itself would not trip the stop, but a value rounded to 0.95 would. A gap of 0.003 would also leave the solve close to singular; I did not measure how badly it would be conditioned.
  - The worklist's nuclear candidate (0.993) would cross above most of the bomb proxies.
- **Next step:** open Hesshaimer & Levin 2000 for hemispheric stratospheric ¹⁴C inventories.

## 21. `P_canon` natural ¹⁴C production = 2.04 atoms cm⁻² s⁻¹

**What the code means by it.**
- It is a reference global-mean cosmogenic production rate, converted to mol/yr with the Earth area, for **comparison only** with the production that `ccx_spinup()` solves for **1750** (`R/spinup.R:220-221` at HEAD `e6de59c`; the worklist's 204-205 predates that commit).
- So the like-for-like epoch is **preindustrial** (pre-bomb, ideally 1750–1900), as a global average per cm² of Earth's surface.

| Value (atoms cm⁻² s⁻¹) | Definition / epoch | Method | Source and locator | Read how |
|---|---|---|---|---|
| **1.88** | mean over **1750–1900** | cosmic-ray production model (CRAC) with reconstructed solar modulation and paleomagnetic field | Kovaltsov, G. A., Mishev, A. & Usoskin, I. G. (2012), "A new model of cosmogenic production of radiocarbon ¹⁴C in the atmosphere", *Earth Planet. Sci. Lett.* 337–338:114–120 (DOI 10.1016/j.epsl.2012.05.036, not verified this session). arXiv:1206.6974v1: abstract p. 1; **p. 5, lines 126–130**; also conclusions p. 7. Notes it may be about 2 % lower because of the cutoff approach. | pdftotext of arXiv preprint v1 (not the typeset EPSL version) |
| **1.64** | mean over **1951–2010**, ranging 1.1 (1990 solar max) to 2.2 (2010 solar min) | same | same, **p. 5, lines 121–125** | same |
| 1.6–1.8 | "carbon-cycle reservoir inventory" estimates | inventory | same, p. 2, lines 26–30 (review of earlier work) | same |
| 1.9–2.5 | earlier production models | review | same, p. 2 and p. 5 | same |
| **1.75** | **1750–1900** | carbon-cycle (Bern3D-LPJ) budget | Roth, R. & Joos, F. (2013), "A reconstruction of radiocarbon production and total solar irradiance from the Holocene ¹⁴C and CO₂ records: implications of data and model uncertainties", *Clim. Past* 9:1879–1909, doi:10.5194/cp-9-1879-2013. **p. 1894.** | pdftotext of Copernicus PDF |
| 1.7 / ~1.71 | "modern" (abstract) / present-day dipole and Φ = 550 MeV | same | same, abstract p. 1879; p. 1894; p. 1898 | same |
| 1.77 | Holocene mean | same | same, p. 1898 | same |
| 1.6 / 2.07 / 1.2 | modern dipole moment (7.8e22 A m²) at φ = 650 / 300 / 1200 MV (cycle mean / solar min / solar max) | CRAC yield functions | Poluianov, S., Kovaltsov, G. A., Mishev, A. L. & Usoskin, I. G. (2016), "Production of cosmogenic isotopes ⁷Be, ¹⁰Be, ¹⁴C, ²²Na, and ³⁶Cl in the atmosphere: Altitudinal profiles of yield functions", *JGR Atmos.* 121:8125–8136, doi:10.1002/2016JD025034. arXiv:1606.05899v1 **Table 1 (arXiv p. 33)**. The caption prints M as 7.8·10²³; the text on p. 12 says 7.8·10²². | pdftotext of arXiv preprint v1 |
| (2.2 ± 0.6)e26 atoms/yr ≈ **1.37 ± 0.37** (my arithmetic) | measured, 2002–2005 | stratospheric ¹⁴C sampling (Kanu et al. 2016) | **secondary**, quoted in Poluianov 2016, arXiv p. 13 | — |
| 2.4 ± 0.2 | Holocene average | review of calculations plus inventory | Damon, P. E. & Sternberg, R. E. (1989), "Global production and decay of radiocarbon", *Radiocarbon* 31(3):697–703, doi:10.1017/S0033822200012297. **Abstract, p. 697.** The same page gives six calculations averaging 2.47 ± 0.19 (1965 solar min) and 2.02 ± 0.13 (1969 solar max); p. 698 gives about 2.2 for recent solar cycles. | pdftotext of the OCR text layer (Table 1 OCR is garbled) |
| 2.02 | global average | Masarik & Beer (1999), JGR 104(D10):12099 | **secondary only:** Hajdas, I. (2008), *E&G Quaternary Science Journal* 57(1–2):2–24, **p. 4** | pdftotext |
| 2.05 ± 0.2 | Φ = 550 MeV | Masarik & Beer (2009), JGR 114, D11103, doi:10.1029/2008JD010557 | **secondary only:** Roth & Joos 2013, **p. 1894 and p. 1898**. The AGU page returned 403. | pdftotext of Roth & Joos |

**Verdict.**
- The like-for-like candidates for a 1750 comparison are **1.88 (Kovaltsov 2012)** and **1.75 (Roth & Joos 2013)**, both averaged over 1750–1900. They come from independent methods.
- The code's 2.04 is **+8.5 %** and **+16.6 %** above them (my arithmetic). In totals (my arithmetic, code's area): 2.04 → 545 mol/yr, 1.88 → 502 mol/yr, 1.75 → 468 mol/yr.
- All three lie inside the Naegler & Levin 2006 GRACE range already on disk, 0.48–0.55 kmol/yr.
- 2.04 sits next to the Masarik & Beer values (2.02 in 1999; 2.05 at Φ = 550 MeV in 2009), which I saw only secondarily. Both Kovaltsov 2012 (arXiv p. 6, lines 141–146: lower than MB09 by 25–30 %, attributed to the cosmic-ray spectrum) and Roth & Joos 2013 call those values too high.
- It is diagnostic only. The `prod_ratio` gate (0.5–2.0) would not change.
- Vintage: Kovaltsov 2012 and Roth & Joos 2013 are newer than Masarik & Beer 1999/2009. Poluianov 2016 is the newest but gives modern-dipole values, not a 1750–1900 mean.

## 22. Earth surface area 5.1e14 m²

**What the code means by it.** The area that turns a per-cm² production rate into a global total (`R/spinup.R:221` at `e6de59c`). Kovaltsov 2012 defines production per cm² of Earth's surface (arXiv p. 4, lines 77–78), so the area should be the Earth's surface area.

**Candidate.**
- **Moritz, H. (2000).** Geodetic Reference System 1980. *Journal of Geodesy* 74(1):128–133 (the Geodesist's Handbook reprint). The copy read is paginated 128–133 and carries the corrigendum note; DOI not verified this session.
- **Locator:** §4 "Numerical Values", "Derived Geometric Constants", **p. 131**: R₂ (radius of the sphere with the same surface) = **6 371 007.1810 m**.
- **URL:** https://ciencias.ulisboa.pt/sites/default/files/fcul/dep/dqb/doc/GRS80_Moritz.pdf (pdftotext).
- **Area (my arithmetic):** 4πR₂² = **5.10066 × 10¹⁴ m²**. The code's 5.1e14 is **−0.013 %** below it.
- **Like-for-like:** yes. It is the surface area of the GRS80 reference ellipsoid.
- **Secondary consistency:** Roth & Joos 2013, p. 1887, set the atmospheric area in their model to 5.10 × 10¹⁴ m² (1 atom cm⁻² s⁻¹ = 267.0 mol/yr; a model setting). The `OCEAN_AREA_NH/SH` strings' "hemisphere 2.551e14" doubles to 5.102e14, which is +0.03 % from R₂ (my arithmetic).

**Out of scope here:** `.SEC_PER_YR` (Julian year) and `.AVOGADRO` (exact in the 2019 SI). I did not search for them.

---

## Appendix: what I searched

**Item 1 (organic fractionation).**
- Web searches:
  - box-model constant −20 ‰ organic vs DIC;
  - Broecker & Maier-Reimer 1992;
  - "20 ‰ lighter" phrasing;
  - Goericke & Fry 1994;
  - Rau et al. 1997;
  - Hofmann et al. 2000;
  - Verwega 2021;
  - Maier-Reimer 1993 (HAMOCC3, said to use a "uniform" factor; value not found);
  - Eide 2017b.
- Read: Schmittner 2013 PDF; Liu 2021 HTML; Verwega 2021 HTML.
- Blocked or not read: Eide 2017b (Wiley 403), Goericke & Fry 1994 (abstract only), Hofmann 2000 (AWI connection refused), Maier-Reimer 1993.

**Item 5 (ocean depth).**
- Searches: Charette & Smith 2010; Eakins & Sharman 2010 / ETOPO1 ocean volumes; GEBCO / ETOPO 2022 mean depth; Costello et al. 2010.
- Read: Charette & Smith PDF.
- Not reachable: the NOAA NGDC page (redirects to the ETOPO product page); the Wayback Machine (tool cannot fetch); AWI (Weatherall 2015, bot-blocked); the R `ocedata` docs (no numbers).

**Items 13–14 (obliquity and declination).**
- Read:
  - Wikipedia "Position of the Sun";
  - PVEducation "Declination Angle";
  - Jenkins 2013 (arXiv);
  - IERS Conventions 2010 Ch. 5;
  - USNO seasons API for 1850, 2000 and 2023.
- Not read: Cooper 1969 (Elsevier); Spencer 1971.

**Item 16 (soil-respiration temperature lag).**
- Searches:
  - soil temperature annual phase lag vs depth;
  - NH station phase lags;
  - soil respiration seasonal hysteresis (COSORE, FLUXNET).
- Read: the AmeriFlux page for Zhang et al. 2018; *Physical Processes in Ecosystems* §13.5; the SoTOS EGU21 poster.
- No hemispheric, respiration-weighted soil-temperature or heterotrophic-respiration phase product or paper was found.

**Item 19 (bomb ¹⁴C hemispheric share).**
- Searches: UNSCEAR 2000 Annex C yields by hemisphere; Hesshaimer & Levin 2000.
- Read: UNSCEAR 2000 Annex C (NRC exhibit copy); Tans 1981 SCOPE 16 (no hemispheric split).
- Blocked: Hesshaimer & Levin 2000 (Heidelberg repository bot-blocked).
- Not found online: Enting 1982 and Telegadas 1971.

**Items 21–22 (production rate and Earth area).**
- Read:
  - Kovaltsov 2012 (arXiv);
  - Poluianov 2016 (arXiv);
  - Roth & Joos 2013 (Copernicus PDF);
  - Damon & Sternberg 1989 (Cambridge PDF, OCR);
  - Hajdas 2008 (secondary for Masarik & Beer 1999);
  - Moritz 2000 GRS80 (ULisboa copy).
- Blocked: Masarik & Beer 2009 (AGU 403). Masarik & Beer 1999 was not found open.
