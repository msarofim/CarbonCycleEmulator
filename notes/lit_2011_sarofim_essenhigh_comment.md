# Comment on Essenhigh (2009) — M. C. Sarofim, drafted 2011, never submitted

**Transcription of `app/www/sarofim_essenhigh_comment_2011.doc`.** Author: Marcus C. Sarofim; the
file's own metadata records **Company: MIT** and **Created 2011-04-15** (the filename says
`1_10_2011`, so treat the drafting date as "early 2011" rather than either). Never submitted;
Cawley (2011) covered Essenhigh in *Energy & Fuels* the same year. Added to the repo 2026-08-25 at
the author's request, for the historical-interest link from the app.

> **THE `.doc` IS AUTHORITATIVE. This plain-text rendering IS lossy.** The original carries **27
> superscript and 33 subscript runs** — CO₂, ¹⁴C, ¹³C, ¹²C, 10¹⁸, CO₃⁻⁻, 4ᵗʰ — and `textutil`'s
> text output flattens every one of them, so they read here as "CO2", "14C", "5.135 x 1018".
> *(I asserted the opposite in an earlier revision of this header. That was a tooling artifact:
> `textutil`'s HTML contains 8 NUL bytes, so `file` calls it "data" and plain `grep` silently
> skips it — `grep -a` finds all 27. Counted correctly, the formatting was there all along.)*

## Edits made to the `.doc` — 2026-08-25, on the author's instruction

**Every change is pre-2011 information**, which was the author's condition: the latest year cited
anywhere in the document is still **2010**. Formatting is untouched — the corrected file carries the
same 27 superscript and 33 subscript runs as the original, verified by diff. The untouched original
is in git history at commit `d8945aa`.

| was | now |
|---|---|
| `O'Neill B, Measuring Time in the Greenhouse, Climatic Change 37, 491-503, 1997` | `O'Neill BC; Oppenheimer M; Gaffin SR, Measuring Time in the Greenhouse; An Editorial Essay, Climatic Change, 37, 491-505, 1997` |
| `Doman AJ; ...` | `Dolman AJ; ...` — the body spells it Dolman twice |
| `... Science, 367-371, 2004` | `... Science, **305**, 367-371, 2004` |
| `shift this note down?` | deleted |
| trailing note, *"Predated Essenhigh by 16 years…"* | **deleted as redundant** — the body already says it: *"O'Neill et al. was a response in part to the publication of Starr (1993) which made similarly confused claims based on 14C levels in the atmosphere, though 16 years earlier than Essenhigh."* The ~12 empty paragraphs that had positioned it went with it, so the document no longer ends on a blank page |

---

Comment on “Potential Dependence of Global Warming on the Residence Time (RT) in the Atmosphere of Anthropogenically Sourced Carbon Dioxide”

Essenhigh (2009) claims to demonstrate that the recent rise in CO2 concentrations was not driven by anthropogenic emissions but rather by natural factors such as the rising atmospheric temperatures.  Such a result would indeed be of deep political significance, as the paper claims.  Unfortunately, the paper’s approach is deeply flawed due to an ignorance of many decades of published literature that has conclusively demonstrated the anthropogenic origin of the majority of the recent rise of CO2 concentrations.  There are three major factors ignored by Essenhigh (2009):  the chemistry driving carbon dioxide absorption by the oceans; the paleoclimate history showing that recent changes in concentration are unprecedented in at least 800,000 years; and physical implausibility of the carbon cycle having an isotope selectivity of a factor of 3.  There are a number of other flaws in the paper, ranging from poor assumptions about the perfectly mixed nature of carbon storage in the ocean and ecosystem, to an erroneous straw man of constant exponential decay for the standard model of atmospheric carbon adjustment time, to leaving out deforestation from the historical emissions estimates used in the paper.

A useful general reference to read is O’Neill et al. (1997) which was written specifically to address the same confusion about residence times and adjustment times evinced by Essenhigh (2009).  O’Neill et al. was a response in part to the publication of Starr (1993) which made similarly confused claims based on 14C levels in the atmosphere, though 16 years earlier than Essenhigh.  Another good reference is the Frequently Asked Questions box in the IPCC 4th Assessment Report (Denman et al., 2007).  The attribution of the CO2 rise to anthropogenic emissions has been deemed unequivocal by the IPCC since the First Assessment Report:  unequivocal is not a word used lightly in science.  An example of a recent study that properly uses 14C measurements to understand the carbon cycle is Levin et al. (2010). 

The key confusion in Essenhigh (2009) is between “residence time” and “adjustment time”.  In fact, the author mentions his confusion three times.  O’Neill et al. noted that the terminology of this field can be confusing to policymakers and other non-experts, but it is unfortunate that Essenhigh (and, similarly, the reviewers and the editor) did not think to consult an actual expert in the field or the many available textbooks and the existing literature in order to clear up this confusion.  “Residence time” refers to the average time that a given carbon atom stays in the atmosphere before it moves to another reservoir such as the ocean or the ecosystem.  “Adjustment time” refers to the timescale on which atmospheric concentrations actually change.  While in many systems residence time and adjustment time are identical, it is possible for the two lifetimes to also be very different.  Policy relevant timescales are determined entirely by the adjustment time of carbon dioxide concentrations in the atmosphere, not by the residence time.
 
The difference between CO2 residence times and adjustment times was recognized at least as far back as1957, where Revelle and Suess examined 14C/12C ratios in order to determine the “average lifetime” of CO2 molecules, but also noted that the “exchange rate of isotopically labeled CO2 between atmosphere and ocean, which, in principle, could be deduced from C14 measurements, is not identical with the rate of absorption [of excess CO2 in the atmosphere]”.  Revelle and Suess attributed this difference to “the peculiar buffer mechanism of sea water.”  Rodhe and Björkström (1979) showed analytically that residence times and adjustment times can be decoupled under certain conditions, and used a simple model to show how the peculiar buffer mechanism of Revelle and Suess could lead to such a decoupling.  The buffer mechanism involves the chemistry of CO2 absorption by the oceans:  as CO2 dissolves in water it forms H2CO3.  H2CO3 in the ocean is in equilibrium with the ions HCO3- and CO3--.  By Henry’s Law, an increase of atmospheric CO2 leads to a proportional increase of H2CO3 (and/or dissolved CO2):  however, in the process, there is a reduction in the concentration of the carbonate ion (note that on the timescales of many thousands of years, more carbonate ion will eventually dissolve from ocean sediments, however, this process is not important for calculating CO2 concentrations on the century timescale).  What this means is that an increase of the partial pressure of CO2 leads to a less than proportional increase in the amount of carbon in the ocean:  the proportionality constant is known as the Revelle factor, and ranges from values of 8 to 16 in the oceans, meaning that in order to increase oceanic carbon in equilibrium by 1%, atmospheric carbon loading must increase by 8 to 16% (Sabine et al. 2004). Furthermore, Rodhe and Björkström showed that when the flux is not directly proportional to changes in partial pressure, that the “adjustment time” can be several times larger than the “equilibrium turn-over time”. Therefore, the real world is entirely different than the perfectly stirred reactor mixing structure used by Essenhigh (2009) because of this ocean chemistry.  In addition to this chemical difference, there are many other biological and physical differences between the ocean and ecosystem carbon sinks and a perfectly stirred reactor.  The ocean’s mixing timescale is on the order of thousands of years:  for this reason, carbon cycle models as long ago as the 1970s used diffusive approximations rather than perfectly stirred reactors (Oeschger et al. 1975). The ecosystem is even further from a perfectly stirred reactor:  much of the ecosystem carbon uptake number used by Essenhigh – the Gross Primary Productivity or GPP – involves carbon that enters the ecosystem in the spring and summer as leaves grow, and returns to the atmosphere in the fall and winter as leaves drop and decay.  Real carbon cycle models often divide the ecosystem into many components to reflect the fast and slow carbon pools.  

Essenhigh (2009) makes the offhand claim that the change in concentration could be due to the warming of the oceans.  It is indeed true that the solubility of CO2 decreases in water as temperature increases, and therefore a warming of the oceans should, all else equal, lead to an increase of atmospheric concentrations.  However, the magnitude of this response is on the order of 6.9 to 10.2 ppm per degree Celsius sea surface temperature rise (Denman et al. 2007).  Even Revelle and Suess (1957) considered and rejected this hypothesis based on the knowledge available 50 years ago.  In order to explain the concentration increase of more than 100 ppm since 1750, global mean sea surface temperatures would need to have increased on the order of 10 °C in the past several centuries – which they clearly have not.  Ice cores demonstrate that over at least the past 800,000 years CO2 concentrations ranged from 180 in the middle of the glacial period to at most 300 ppm during the interglacials (Jansen et al., 2007). The evidence shows that the current concentration of 386 ppm is far outside the historical range of the past million or more years, and this fact, combined with the fact that historical CO2 emissions of more than 470 gigatons in the past 160 years are more than twice the atmospheric increase of about 200 gigatons, are enough in and of themselves to be strong evidence for an anthropogenic cause of the recent CO2 increase.  

Essenhigh’s model also yields a residence time of 12CO2, a residence time that is a factor of 3 less than the residence time of 14CO2.  Isotopic separation is a challenging problem:  12CO2 and 14CO2 are chemically identical and differ in mass by less than 5%.  Kinetic isotope fractionation due to the mass difference of 12C and 13C as CO2 enters and exits seawater is on the order of 0.2%. Biological enzymatic reactions can, in principle, yield greater isotopic separation than bulk physical processes, but the separation seen in plant carbon uptake is still only 2 to 3%.  The factor of three difference that is a result of the Essenhigh approach is the kind of result that cannot just be waved away by stating that the difference is “small” and explained by unspecified differences in “absorption or solution rates”.  Additionally, Essenhigh ignores other effects on atmospheric 14C concentrations, such as changes in 14C formation due to changes in cosmic fluxes with the sunspot cycle, or the well-known Suess effect describing the dilution of 14C in the atmosphere due to the addition of 14C-poor fossil fuel carbon:  both of these effects have been taken into account in analyzing both the pre-bomb and post-bomb 14C records in multiple publications (Stuiver et al. 1981, 1998). 

There are numerous other flaws in the paper.  Figure 2 includes only fossil fuel emissions from the Carbon Dioxide Information Analysis Center and ignores the deforestation emissions that are stored at the same website.  Deforestation was the dominant source of human carbon emissions historically, surpassed by fossil fuel emissions only in the early 20th century.  Even today, deforestation emissions are estimated to be on the order of 15% of emissions from fossil fuels.  Essenhigh also uses straw men in this figure, using only exponential decay models of CO2 to represent the “consensus” approach.  Even the Bern Cycle approximation cited in the IPCC is a sum of 3 exponentials and a constant (Forster et al. 2007), but real carbon cycle models are not based on exponential fits, and have been successfully used to describe many more attributes of the real system than does Essenhigh (2009) (such as seasonal cycles, changes in atmospheric loading of 13C in addition to 14C, stratospheric concentrations, oceanic carbon concentrations differing by region, and so on), without requiring any non-physical isotopic separation but rather basing any isotopic differences on lab-measured biological uptake rates.  Another minor error, indicative of the unfamiliarity with the literature, is that Essenhigh converts 5.135 x 1018 kg to 5.66 x 1015 megatons, not realizing that in the carbon cycle field (as in most fields), megatons and gigatons are always considered to be units based on metric tons, not short tons. 

Conclusion:
There are legitimate uncertainties regarding a number of aspects of the carbon cycle.  A good reference is Dolman et al. (2010), which discusses the state of the science after the 2007 IPCC 4th Assessment Report, or Archer et al. (2009) which reviews the literature on how current carbon dioxide emissions are likely to contribute to increases in concentration lasting hundreds or thousands of years.  It is unfortunate that a paper so inconsistent with 3 decades of basic scientific understanding could have passed peer review.  Because of the political visibility of this subject this paper has received certain notoriety, and perpetuates the basic misunderstandings addressed by O’Neill et al. a dozen years ago.  Therefore, it is worthwhile to set the record straight by publishing this comment, thereby hopefully remedying any confusion in the readers of this journal who are not experts in the carbon cycle and who therefore may have assumed that a peer-reviewed publication is indicative of continued scientific debate, whereas it is a basic, well-understood, and unequivocal fact is that the majority of the recent CO2 increase is indeed of anthropogenic origin.  


Archer D; Eby M; Brovkin V; Ridgwell A; Cao L; Mikolajewicz U; Caldeira K; Matsumoto K; Munhoven G; Montenegro A; Tokos K, Atmospheric Lifetime of Fossil Fuel Carbon Dioxide, Annu. Rev. Earth Planet. Sci. 2009. 37:117–34.  

Denman, K.L., et al. (2007) Couplings Between Changes in the Climate System and Biogeochemistry. In: Climate Change 2007: The Physical Science Basis. Contribution of Working Group I to the Fourth Assessment Report of the Intergovernmental Panel on Climate Change [Solomon, S., D. Qin, M. Manning, Z. Chen, M. Marquis, K.B. Averyt, M. Tignor and H.L. Miller (eds.)]. Cambridge University Press, Cambridge, United Kingdom and New York, NY, USA.

Dolman AJ; van der Werf GR; Ganssen G; Erisman, JW; Strengers B, A Carbon Cycle Science Update Since IPCC AR-4, A Journal of the Human Environment 39(5-6):402-412, 2010.  

Forster, P. et al. (2007) Changes in Atmospheric Constituents and in Radiative Forcing. In: Climate Change 2007. The Physical Science Basis. Contribution of Working Group I to the Fourth Assessment Report of the Intergovernmental Panel on Climate Change [Solomon, S., D. Qin, M. Manning, Z. Chen, M. Marquis, K.B. Averyt, M. Tignor and H.L. Miller (eds.)]. Cambridge University Press, Cambridge, United Kingdom and New York, NY, USA.

Jansen, E., J. Overpeck, K.R. Briffa, J.C. Duplessy, F. Joos, V. Masson-Delmotte, D. Olago, B. Otto-Bliesner, W.R. Peltier, S. Rahmstorf, R. Ramesh, D. Raynaud, D. Rind, O. Solomina, R. Villalba and D. Zhang (2007) Palaeoclimate. In: Climate Change 2007: The Physical Science Basis. Contribution of Working Group I to the Fourth Assessment Report of the Intergovernmental Panel on Climate Change [Solomon, S., D. Qin, M. Manning, Z. Chen, M. Marquis, K.B. Averyt, M. Tignor and H.L. Miller (eds.)]. Cambridge University Press, Cambridge, United Kingdom and New York, NY, USA.

Levin, I; Naegler, T; Kromer, B; Diehl, M; Francey, RJ; Gomez-Pelaez, AJ; Steele, LP. Wagenbach, D; Weller, R; Worthy, DE.  Observations and modeling of the global distribution and long-term trend of atmospheric 14CO2, Tellus, 2010.   

Oeschger, H; Siegenthaler, U; Schotterer, U; Gugelman, A, A Box Diffusion Model to Study the Carbon Dioxide Exchange in Nature, Tellus 27, 168-192, 1975.  

O’Neill BC; Oppenheimer M; Gaffin SR, Measuring Time in the Greenhouse; An Editorial Essay, Climatic Change, 37, 491-505, 1997

Rodhe H; Björkström A; Some consequences of non-proportionality between fluxes and reservoir contents in natural systems, Tellus, 31, 269-278 (1979).

Revelle R; Suess HE, Carbon Dioxide Exchange Between Atmosphere and Ocean and the Question of an Increase of Atmospheric CO2 during the Past Decades, Tellus IX, 1957.

Sabine CL; Feely RA; Gruber N; Key RM; Lee K; Bullister JL; Wanninkhof R; Wong CS; Wallace DWR; Tilbrook B; Millero FJ; Peng TH; Kozyr A; Ono T; Rios AF, The Oceanic Sink for Anthropogenic CO2, Science, 305, 367-371, 2004.

Starr, C, Atmospheric CO2 residence time and the carbon cycle, Energy, 18, 1297-1310, 1993.  

Stuiver, M; Quay, PD, Atmospheric 14C changes resulting from fossil fuel CO2 release and cosmic ray flux variability, Earth and Planetary Science Letters, 53, 349-362, 1981.  

Stuiver, M; Braziunas, TF, Anthropogenic and solar components of hemispheric 14C, Geophysical Research Letters, 25 (3), 329-332, 1998.

---

# Why this document is in the repo

1. **Its reference list is the best one we have** on the residence-vs-adjustment distinction, and it
   supersedes the 2026-08-25 web sweep where the two differ — see
    Part 4.
2. **It moves the timeline back sixteen years.** Starr (1993) is the first published instance;
   O'Neill et al. (1997) was written to end the confusion; Revelle & Suess had the distinction in
   **1957** and Rodhe & Björkström proved the decoupling analytically in **1979**.
3. **It anticipates DESIGN gate 12b by fourteen years** — *"Even the Bern Cycle approximation cited
   in the IPCC is a sum of 3 exponentials and a constant"* is exactly the premise the gate tests.
