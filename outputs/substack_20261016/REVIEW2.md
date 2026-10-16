# Second review: "CarboTope II: CarboTope vs. Bad Science"

Draft reviewed: `CarboTopeSubstack.contrarians.docx`, saved 2026-10-16 16:06 (the first review, `REVIEW.md`, read
the 14:52 save). This pass checks the revisions, the Curry and Schwartz passages, and whether Schwartz's 2025 model
belongs in the post. Sources were re-read from the raw pages saved by the first pass (Climate Etc. posts, Schwartz's
2012 referee report, the ACP 2021 discussion page, his AGU 2021 poster). Figure numbers are left for the Substack
build, as you asked.

## 1. Curry

The quotes are verbatim: 2011 "Wow." and "If Salby's analysis holds up…" (under "JC comments"); 2023 "I find this
analysis to be very interesting…" and "I think what this paper shows…" (under "JC comment"); the 2016 "JC note".

1. **"often came with favorable comments, never included critical evaluation" is accurate.** Her text in the four
   posts: 2011, a disclaimer ("not a topic on which I have any expertise"), "frustratingly preliminary", and praise
   of Salby ("an excellent lecturer", with "the reputation of a thorough and careful researcher"); 2016, "well worth listening to"; 2023 (Christofides), "very
   interesting"; 2023 (Dengler & Reid), no Curry text at all.
2. **The closing line contradicts it.** "…without ever providing any evaluation of them for her audience" conflicts
   with "favorable comments" and with the van der Werf paragraph. Favorable comments are an evaluation. "Without ever
   offering a critical evaluation" matches the record.
3. **Dengler & Reid don't fit "humans not being primarily responsible".** Their post builds on the mass balance
   (emissions minus absorption) and claims a 42-year half-life and a plateau near 475 ppm. Either widen the category
   to "or that CO₂ has a short lifetime", or the count of posts in that category is three.
4. **The van der Werf paragraph is an unfinished sentence** (it ends in a comma). "Saying" reads as if van der Werf
   said it; the words are Curry's "JC note", which continues "(but didn't expect)". The post ran on 2016-08-12, two
   days after the Salby post. "Debunking" is fair: it rebuts Salby's numbers directly (his "200% increase in fossil
   fuel emissions … is about 20% in reality").
5. Still mixed: "Curry's commentary" (2011) and "Judith's commentary" (2023).

## 2. Schwartz

1. **"a referee comment in 2012" is accurate.** He signed it "Stephen E. Schwartz (Referee)". The "Simpler
   representations…" quote is verbatim; he cites Moore & Braswell (1994) and Jacobson (2005).
2. **Fairness, optional.** The same report argues the model range was too narrow in both directions. It also cites
   Allen et al. (2009), whose box-diffusion model showed "essentially no decline in CO2 mixing ratio over the first
   hundred years" after emissions stop, and says including it would have "greatly extended upwards" the range. The
   draft quotes only the short side.
3. **The "second order" quote is verbatim and comes from the same report.** Its context gives his number: if
   emissions stopped, "something like 60% of the excess CO2 … [would] disappear within 100 years", read from the
   multi-model pulse response (0.41 at 100 years). So he assumed about 40% left.
4. **The test sentence.** "70% … in contrast to a third" is close but each half is off by a few points:

   | stop and pulse in 2030, vvM | excess left at +100 yr | pulse left at +100 yr |
   |---|---|---|
   | CarboTope | 65.5 % | 36.4 % |
   | FaIR 2.2.4 (calib 1.6.0), median (5–95 %) | 71.1 % (66.0–75.7 %) | 37.8 % (30.7–43.5 %) |

   Accurate forms: "two-thirds to 70% … against just over a third", or compare with his figure: "against the 40%
   he assumed".
5. **Figure X8's caption has two errors.**
   - The figure is one panel: dark curves are the excess left after emissions stop in 2030, orange curves a 100 GtC
     pulse released in 2030, against years after 2030. There is no left and right.
   - "66-71% of already emitted CO2" has the wrong base. The share is of the atmospheric excess above preindustrial
     (343 GtC in 2030 in CarboTope), which is 40% of the 853 GtC emitted 1750–2029. So 65% of the excess is 26% of
     what was emitted. "66–71% of the CO₂ increase above preindustrial" is accurate.
6. **The 2021 paragraph never says what the 2021 work claimed**, which is why he is in the post. His words:
   - ACP preprint abstract: adjustment time "78 to 140 years", "several-fold shorter than estimates from current
     carbon-cycle models"; cessation "would result in substantial recovery of CO2 toward its preindustrial value in
     less than a century".
   - AGU poster: "110 ± 40 years"; and "Current carbon cycle models give lifetime of excess CO2 over first 100 years
     ranging from 150 to 350 yr."

   A like-for-like test, using his stop year (2017) and his lifetime definition (−t / ln f):

   | | excess left at +100 yr | equivalent lifetime |
   |---|---|---|
   | Schwartz 2021, preprint | 28–49 % | 78–140 yr |
   | Schwartz 2021, poster | 40 % (24–51 %) | 110 ± 40 yr |
   | CarboTope, stop in 2017 | 64.0 % (64.0–66.4 % over the seven backgrounds) | 224 yr |
   | CarboTope, stop in 2030 | 65.5 % | 236 yr |
   | FaIR, stop in 2030 | 71.1 % (66.0–75.7 %) | 293 yr (240–359) |

   CarboTope and FaIR both fall inside the 150–350 yr range his poster gives for current models. Source: CHANGELOG
   2026-10-16 (k). CarboTope's runs include climate feedbacks, and their effect on this number was not separated.
   FaIR was not rerun for 2017.
7. **"AGU abstract"**: the ESSOAr item is his AGU Fall Meeting 2021 poster (GC25C-0665); "poster" is more precise.
   "The ACP paper was not published" matches the page ("the revision was not accepted"). RC1 is David Archer (signed).
   The RC2 quote is verbatim, and its two sentences are consecutive in the original. RC2 also wrote that the study
   "could be publishable on scientific views".
8. **"Schwartz preemptively attacks his critics"**: the Appendix F sentence rebuts arguments. It does not question
   critics' motives the way Spencer's 2009 line does ("how politicized the science … has become"). "Preemptively
   rebuts" is accurate; your next sentence already gives him that credit.
9. The climate-sensitivity sentence is now accurate: 1.9 ± 1.0 °C (2008) sits below both likely ranges.

## 3. Schwartz's 2025 model: include it?

**Recommendation: not as a discussion in this post. A one-sentence footnote is optional.**

- It makes no lifetime claim (your reading, confirmed against the paper on 10-16). Placed in a list of short-lifetime
  arguments, it would read as one.
- What the comparison shows is indirect. Driven by CarboTope's atmosphere, his ocean takes up the same share of a
  pulse at +100 yr (26.6 % in both), about half as much at +20 yr (11.2 vs 20.0 %) and more at +250 yr (44.9 vs
  33.1 %) (CHANGELOG 2026-10-16 g). One well-mixed deep box behind a fixed exchange velocity produces that time
  shape. The consequence for a lifetime (likely a lower multi-century tail if the model were run forward) was not
  computed.
- A case for the footnote: his recent peer-reviewed papers (Biogeosciences 2024 and 2025) make no short-lifetime
  claim, and the 2025 paper fits its ocean to the Global Carbon Budget 2023 ocean sink (our re-implementation gives
  2.75 PgC/yr in 2022 against his published 2.84 ± 0.6; GCB 2025 now gives 3.12). Saying so pre-empts a "his newer work is fine" reply and fits your "to give
  Schwartz credit" sentence.
- A better home: a post on why fitting the historical record does not fix a model's long tail. The exchange velocity
  that makes his ocean match CarboTope falls from 17.9 m/yr at +20 yr to 4.9 m/yr at +250 yr, close to t^−½, the
  signature of a diffusive interior.

## 4. Other revisions

1. **Buffer chemistry: the reaction is now right; the source of the carbonate is not.** "Where did that carbonate
   come from? It was probably living its life as calcium carbonate aka aragonite", "every dissolved CO2 molecule
   needs an aragonite molecule to partner with" and "as aragonite gets used up" still describe solid aragonite being
   consumed. The carbonate ion the reaction uses is already dissolved in seawater, and the uptake does not dissolve
   solid aragonite. Dissolving aragonite would add carbonate ions and raise the uptake. The coral link runs through
   saturation: corals and shellfish build aragonite from the same dissolved carbonate ion, so fewer carbonate ions
   means lower aragonite saturation. Figure 2 shows this mechanism, so the text and the figure currently disagree.
   Smallest fix: "an aragonite molecule" → "a carbonate ion"; "as aragonite gets used up" → "as carbonate ions get
   used up". Also "two bicarbonate (HCO3-) molecules" → "ions".
2. **Holocene range.** "for the 10,000 years of the Holocene at between 271 and 285 ppm": 271–285 ppm is the Law
   Dome range for 154–1750 CE (repo data: 270.7–284.5 ppm), about 1,600 years. The repo has no ice-core CO₂ before
   154 CE, so the 10,000-year claim is unchecked here; the first pass's fact-check put the early Holocene near 260 ppm
   (Bereiter et al. 2015, not downloaded). Options: limit the claim to the period Figure X5 shows, or download the
   Bereiter composite to check it (it needs your OK).
3. **Figure X7 caption.** "The δ¹³C pattern is a 'fingerprint' of fossil fuel combustion": the run without human
   emissions removes fossil fuels, cement and land clearing together, and δ¹³C falls for both fossil and
   land-clearing carbon (both come from photosynthesis and are low in ¹³C). "of carbon from fossil fuels and cleared land" is
   accurate.
4. **Figure 1 and its lead-in.** The text says "surface, intermediate, and deep"; the app and the caption say "upper"
   (to ~300 m). Pick one.
5. Small: "Köhler et al 2018. criticizing" → "Köhler et al. (2018) criticizing"; "who knew Essenhigh as fellow
   combustion experts" → "as a fellow combustion expert".
6. **Checked and fine:** Segalstad (1998); 427 ppm and 2.6 ppm/yr; Figure X6's 2.0×; the reservoir numbers (CarboTope:
   588, 2,131 and 37,361 GtC, total 40,080) and 1.3 %; the Essenhigh affiliation and the GitHub link. The Starr link
   was not opened.
7. **Still open from the first review:** "by only 1%" is the surface water's dissolved inorganic carbon, so "about 1%
   or less" (1.2); the footnote's "and therefore the Revelle factor" (1.3), and "more temperate" → "warmer"; the
   Jacobson DOI is a 2005 correction to his 2002 paper (4.5); the open-access Revelle & Suess link (4.12); the
   malformed EPA 2025 link; the XKCD licence if the post is paywalled; Wayback links for Climate Etc.
