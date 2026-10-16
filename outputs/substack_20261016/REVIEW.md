# Review: "CarboTope II: CarboTope vs. Bad Science"

**Second review of the 16:06 save: `REVIEW2.md`** (Curry, Schwartz, Schwartz 2025, and the revisions).
**Third review of the 19:41 save: `REVIEW3.md`.**

Draft reviewed: `CarboTopeSubstack.contrarians.docx`, saved 2026-10-16 14:52. Figures: this folder,
made by `make_figures.R` at the canonical model (hilda31w). Numbers below come from the repo's data or
from committed diagnostics, named in each item.

## 1. Science corrections

1. **The buffer-chemistry paragraph has the mechanism wrong.** The calcium and aragonite steps are not
   how the buffer works, and the direction of the aragonite effect is reversed.
   - What happens: dissolved CO₂ reacts with carbonate ions that are already in seawater,
     CO₂ + CO₃²⁻ + H₂O → 2 HCO₃⁻. Each CO₂ molecule taken up uses up one carbonate ion.
   - No cation has to "pair up". Charge stays balanced because one doubly charged carbonate ion becomes
     two singly charged bicarbonate ions. The sodium, magnesium and calcium in seawater stay dissolved
     throughout.
   - Aragonite is not "used up" by the uptake. What falls is the dissolved carbonate ion. That lowers
     aragonite saturation (calcium is nearly constant, so saturation follows carbonate), which is the
     problem for shells and corals.
   - Dissolving aragonite or calcite works the other way: it adds carbonate back and increases the
     ocean's capacity. That is the slow seafloor process that, over many thousands of years, lowers the
     equilibrium number further.
   - Suggested replacements for the wrong sentences: "every pair of dissolved CO₂ molecules need to be
     paired up with a calcium ion" → each CO₂ taken up consumes one carbonate ion; "as aragonite gets used
     up" → as carbonate ions get used up.
   - A number you can use (CarboTope, warm surface water, `revelle_buffer_20261016`): the carbonate ion
     fell from 245 to 199 µmol/kg (−19 %) between 1750 and 2024, and the Revelle factor rose from 8.9 to 10.0.
2. **"the ocean increases in equilibrium concentration by only 1 %"**: right for a Revelle factor of 10,
   but the quantity is the surface water's dissolved inorganic carbon. CarboTope's surface boxes are at
   10.0–10.7 (warm) and 14.6 (cold) today, and the whole ocean's effective factor is 12.6, so "about 1 %
   or less" is the accurate form.
3. **Footnote on aragonite saturation "and therefore the Revelle factor"**: the two move together
   because both depend on the carbonate ion, but one does not cause the other. "The Revelle factor varies
   with location, mostly with temperature" is accurate. Typo: "more temperature surface ocean" →
   "warmer surface ocean".
4. **"This property alone changes a 1.3 % human addition … 14 % (39 ppm)"**: matches
   `revelle_buffer_20261016` (+14.2 %, +39.4 ppm). Its assumptions are worth a footnote: the atmosphere
   and the whole ocean settle (many centuries, because of the deep ocean); land, climate and alkalinity
   held fixed; no seafloor carbonate dissolution.
5. **"Reason the third" claims CarboTope "requires human emissions"**: the new `fig5_with_without_emissions.png` shows it.
   Without human emissions CarboTope gives 281 ppm in 2024 against 425 ppm with them, and δ¹³C of −6.4 ‰
   against −8.9 ‰ (Mauna Loa measured −8.72 ‰ in 2024). ⚠ The model's δ¹³C ends about 0.15 ‰ more negative
   than Mauna Loa. That is a known issue, visible in the figure, and small next to the 2.5 ‰ gap the
   figure is about.
6. **Schwartz, "70 % … in contrast to 40 %"**: the measured values (CHANGELOG 2026-10-15 c,
   `zec_vs_pulse_20261015`, Medium background) are 66 % (CarboTope) and 71 % (FaIR, median) of the excess
   left 100 years after emissions stop in 2030, against 36 % and 38 % of a pulse. "Two-thirds to 70 %
   … against about 37 %" is accurate. The gap grows with time (new `fig6_stop_vs_pulse.png`).

## 2. Numbers to fill or update

| Where | Draft | Value | Source |
|---|---|---|---|
| ¶ "Compared to the 40,000 GtC" | X, Y, Z | atmosphere 588 GtC; land 2,131 GtC (1,839 excluding inert soil); ocean 37,361 GtC; total 40,080 | CarboTope preindustrial state |
| same ¶ | "less than 2 %" | 1.3 % (505 / 39,788 exchanging carbon) | `revelle_buffer_20261016` |
| Reason 1 | "mostly flat for the 10,000 years of the Holocene at around 280 ppm" | Not flat: about 261 ppm at 6–10 ka, 278–280 ppm in the last 3,000 years; range about 248–285 over the Holocene. "Between about 260 and 285 ppm", or limit the claim to the last 2,000 years (Law Dome 154–1750 CE: 271–285 ppm, Figure 3). The PSU link shows only ~900–1800 AD. | Bereiter et al. 2015, GRL 42:542 (fact-check); `data/obs_icecore.rds` |
| Reason 1 | "426 ppm and rising by 2.5 ppm/year" | OK. Mauna Loa September 2026 was 426.1 (a seasonal low); the 2025 annual mean is 427.35 on NOAA's current page (427.0 in the repo's August download); growth 2.6 ppm/yr over 2015–2025 | NOAA GML (fact-check); repo record |
| Reason 2 | "about twice" | 2.0× (2015–2024) | Global Carbon Budget 2025 |
| Reason 1 | "the 800,000 ice core record" | "the 800,000-year ice core record" | typo |

## 3. Figures

| Slot in the draft | File | Notes |
|---|---|---|
| Figure 1 "[insert Pulse lab figure here]" | `fig1_pulse_ocean_depth.png` | The app's panel, Medium background, 100 GtC in 2050. Your caption matches its keys. |
| Figure 2 "[Make a chemistry diagram …]" | `fig2_buffer_chemistry.png` | Uses the corrected mechanism (item 1.1). Its text is short and factual; reword freely. |
| Figure X4 (XKCD 793) | your image | Renumber to 3. ⚠ CC BY-NC: fine on a free newsletter; check if the post sits behind a paid tier. |
| Reason 1 "[find image I can use?]" | `fig3_co2_record.png` | Law Dome and Mauna Loa, the last ~1,900 years and 1900 on. The right panel shows the ice and the air agreeing where they overlap (1958–1996), which answers "ice cores aren't accurate". |
| Reason 2 "[image showing atmospheric increase vs. human emissions?]" | `fig4_emissions_vs_increase.png` | GCB 2025, 1959–2024, the gap shaded as the land and ocean uptake. |
| NEW, Reason 3 | `fig5_with_without_emissions.png` | CarboTope with and without human emissions against CO₂ and δ¹³C records (item 1.5). |
| NEW, Schwartz | `fig6_stop_vs_pulse.png` | Excess left after emissions stop in 2030 vs a pulse, CarboTope and FaIR, 20–270 years (item 1.6). |

Optional, not made: the 800,000-year ice-core record (Bereiter et al. 2015 composite, NOAA NCEI). It
would need a download into `data-raw/` first.

## 4. Facts, quotes and links

A fact-check against the primary sources (judithcurry.com, drroyspencer.com, the papers, Crossref,
the ACP discussion pages). Most quotes are verbatim. These need changes:

1. **Curry: "no disclaimers" and "never providing any evaluation" are not accurate as written.**
   - 2011: she wrote "The Earth's carbon cycle is not a topic on which I have any expertise" and called the
     material "frustratingly preliminary". She also praised Salby.
   - 2016: two days after the Salby post she ran a rebuttal guest post by Guido van der Werf
     (judithcurry.com/2016/08/12/broad-consistency-between-patterns-of-fossil-fuel-emissions-and-atmospheric-co2/),
     with a JC note: "This is exactly the sort of thing that I hoped my post would elicit (but didn't expect)." (Verified here.)
   - Her evaluations were favourable, not absent. "Never offered a critical evaluation" fits the record better.
   - A further post, Joachim Dengler, "Temperature – a driver of the carbon cycle" (2025-07-16, no Curry text),
     does NOT fit the draft's category (corrected 2026-10-16 on Marcus's reading, checked against the post): it
     states no lifetime and accepts the anthropogenic mass balance; its topic is temperature-driven variability
     in the growth rate. Its sink model (sink = a·C + b·T + c) does carry a 5 %/yr absorption rate that it says
     matches the bomb-¹⁴C decline. That equates gross exchange with net uptake (the residence-time confusion),
     and a linear sink at 5 %/yr implies a ~20-year e-folding for a pulse, but the post never says so. Leave it
     out of the count unless the post discusses that implication.
   - Climate Etc. announced it is closing (2026-06-23). The links work today; Wayback links would last longer.
2. **Both Salby quotes are from the 2011 post.** Neither appears in the 2016 post. Her 2016 "JC reflections" call the talk well crafted and well worth listening to.
3. **Dengler & Reid do not deny that humans caused the rise.** Their paper calls emissions a key control
   knob; the claim is the 42-year half-life (verified; e-folding ≈ 61 yr). They belong under the
   simple-model problem, not under "humans not primarily responsible".
4. **Essenhigh**: single author, and his affiliation on the paper is Mechanical Engineering at Ohio State
   ("chemical engineer" in the draft). His residence times are ~5 yr (¹²C) and ~16 yr (¹⁴C), as the draft says.
5. **Jacobson**: doi:10.1029/2005JD005888 is a 2005 *correction* to his 2002 JGR black-carbon paper. The
   30–95 yr figure is in it (revised from 50–200 yr).
6. **Humlum et al. 2013** is about the phase relation (CO₂ lags sea-surface temperature by 11–12 months):
   move it to the ENSO confusion.
7. **Segalstad**: the linked PDF is a later (~1998) chapter that cites "Segalstad (1996)" as a separate work. Change the year or the link.
8. **Schwartz**
   - The 2012 quotes are both from his review of Joos et al. (ACPD 2012); attribute the "second order" sentence to that review.
   - The ESSOAr item looks like his AGU 2021 poster rather than a second submitted paper.
   - "Neither was published" is true of those two items. His later Biogeosciences papers (2024, bg-21-5045;
     2025, bg-22-2979) make NO short-lifetime claim (corrected 2026-10-16 on Marcus's reading, checked): 2024
     argues the models' ocean and land uptake rates are anticorrelated, so their spread understates the
     uncertainty; 2025 is a three-compartment ocean model fitted to heat uptake that matches the GCB ocean sink.
     How that model compares with CarboTope: `outputs/diagnostics/schwartz_3ccdm_20261016_hilda31w.log`
     (CHANGELOG 2026-10-16 g).
   - RC1 on the ACP paper was David Archer (signed), who recommended against publication: "highly critical" holds.
   - RC2 disclaimed ocean carbon-cycle expertise only, so "isn't a carbon cycle expert" overstates it.
   - His own 2021 abstract says carbon-cycle models leave 0.55–0.85 of the excess 100 years after emissions
     stop, which supports your test.
   - The Appendix F quote is verbatim.
   - Climate sensitivity: 1.1 ± 0.5 K (2007) and 1.9 ± 1.0 K (2008) verified. AR4 2–4.5 °C and AR6 2.5–4 °C
     are likely *ranges*, not best estimates (AR6's best estimate is 3 °C).
9. **ATTP's 2023 post** is a short dismissal ("clearly nonsense"); it does not mention ENSO. "Rebuttal" oversells it a little.
10. **Beck**: the 2022 paper is marked submitted 2010, accepted 2022, "Post mortem memorial edition"; Beck
    died in 2010. That answers the footnote. The journal's chief editor is Hermann Harde, with Humlum and
    Koutsoyiannis as co-editors, which may interest you.
11. **Aragonite**: named for Molina de Aragón, which is in Guadalajara (Castilla–La Mancha), not Aragon;
    Werner mistook its location. The link to the Kingdom of Aragon is only through the town's name.
12. **Revelle & Suess 1957**: the phrase "peculiar buffer mechanism of sea water" is verbatim. The paper is now
    open access (tellusjournal.org/articles/10.3402/tellusa.v9i1.9075); link that or the DOI instead of the
    Wiley epdf. It also estimated an atmospheric CO₂ molecule lifetime of about 10 years.
13. **Verified as written**: the DOE report's five authors (Christy, Curry, Koonin, McKitrick, Spencer); the
    2023 Curry quotes (verbatim, under "JC comment"); the Koutsoyiannis papers and the proverb; all five
    Spencer posts and the "strenuous and vehement" sentence; Starr 1993 (Energy 18:1297); Harde 2017;
    Cawley 2011; the six rebuttals (Keeling's JSTOR page could not be read, but his comment is in the same
    E&E issue as Meijer's); the 800,000-year maximum (298.6 ppm, so "no concentration above 300 ppm" holds).
14. **Links**: all reachable links resolve. The EPA 2025 link is malformed. Several publisher links
    (ACS, ScienceDirect, SAGE, AGU, MDPI, Royal Society) block scripts but are correct; doi.org links are
    safer for the ACS ones. The January 2009 Spencer URL contains a literal "…": check it after pasting
    into Substack. Placeholders still open: [link to CarboTope], [link to github pdf], X/Y/Z GtC, Figure X4.

## 5. Small fixes

- "CarboTope is a better model that any" → "than".
- "Essenhigh et al., 2009" → "Essenhigh (2009)"; "a chemical engineer" → his department was mechanical engineering (section 4.4).
- "Kohler et al." → "Köhler et al.".
- "Judith's commentary" and "Curry's commentary" both appear; pick one.
- The malformed EPA link: the URL is glued to "].[Footnote".
- Humlum et al. (2013): move from the residence-time list to the ENSO confusion (section 4.6).
- "[link to github pdf]": the 2011 comment is at
  https://github.com/msarofim/CarbonCycleEmulator/blob/main/app/www/sarofim_essenhigh_comment_2011.pdf
  (and also served at the app's address, /sarofim_essenhigh_comment_2011.pdf).
