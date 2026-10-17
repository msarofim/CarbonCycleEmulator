CarboTope II (post 2): Substack paste-in
=======================================

Built 2026-10-16 from CarboTopeSubstack.contrarians.docx saved 20:17.

Files in this folder
  carbotope2_substack.html           the whole post, one paste
  fig1_pulse_ocean_depth.png         Figure 1
  fig2_buffer_chemistry.png          Figure 2
  fig3_xkcd_physicists.png           Figure 3 (your XKCD image, copied out of the Word file, 358 x 540 px)
  fig4_co2_record.png                Figure 4
  fig5_emissions_vs_increase.png     Figure 5
  fig6_with_without_emissions.png    Figure 6
  fig7_stop_vs_pulse.png             Figure 7 (now with Schwartz's 40% marker)
  make_figures.R, figures_provenance.txt
                                     how Figures 1-2 and 4-7 were made (re-render is byte-identical)
  REVIEW.md, REVIEW2.md, REVIEW3.md  the three review passes

Check first (my edits to your wording; everything else is formatting)
  a. The carbonate sentence. Your draft: "But where did that carbonate come from? It was probably
     living its life as calcium carbonate aka aragonite, [FN] the building blocks for shells and
     corals." The HTML now reads: "But where did that carbonate come from? Mostly it was already
     dissolved in seawater, where it is the raw material for calcium carbonate aka aragonite, [FN3]
     the building blocks for shells and corals." Reword or revert as you like.
  b. The Schwartz 2012 quote has its parentheses back, as in his report: "...within 100 years.
     (I recognize ... fairly new)."
  c. Revelle and Suess (1957) links to the DOI, https://doi.org/10.1111/j.2153-3490.1957.tb01849.x,
     which redirects to Tellus's open-access page (the PDF downloads without a login). Wiley's page
     showed a bot check, so its access could not be tested. Swap the Wiley link back if you prefer.

Two footnotes sit where Substack may not accept a footnote
  - FN1 is on the subtitle. Substack's subtitle field takes plain text, so the footnote cannot go
    there. Either drop FN1, or keep the subtitle plain and attach FN1 somewhere in the body.
  - FN6 is on the Figure 2 caption. Keep that caption as an italic line below the image (do not
    move it into the image's caption field), so the footnote can attach to it.

Paste and redistribute (Chrome)
  1. Open carbotope2_substack.html in Chrome. Select all (Cmd-A), copy, and paste into the body
     of a new Substack post.
  2. Cut the title (first line) into Substack's title field.
  3. Cut the italic subtitle into Substack's subtitle field (see FN1 above), then delete the
     horizontal rule under it.
  4. Footnotes: there are 17, FN1-FN17, in reading order. Search the body for "FN". At each [FN#]
     marker, delete the marker, insert a footnote with Substack's footnote tool, and paste that
     footnote's text from the Footnotes section at the bottom. Take them in order 1 -> 17 so
     Substack's numbering matches. FN1, FN4, FN6, FN7 and FN16 contain a hyperlink: check it
     survives the paste into the footnote, and re-add it if not.
       FN1   subtitle "CarboTope wins!"                      (Dinosaur vs. Bedtime link)
       FN2   after "since 1750."                             (land use left out)
       FN3   after "calcium carbonate aka aragonite,"        (Aragorn)
       FN4   after "This is why CO2 is bad for corals."      (EPA ocean acidification link)
       FN5   after "(this is called the Revelle factor)."    (aragonite saturation and Revelle)
       FN6   after the Figure 2 caption                      (chemistry diagrams link)
       FN7   after "your brains fall out."                   (Jonathan Becher link)
       FN8   after "after a CO2 molecule is added)"          (two jars of marbles)
       FN9   after "carbon cycle models and understanding."  (CarboTope vs real models)
       FN10  after "rising by 2.6 ppm/year"                  (decade average)
       FN11  after "any concentration above 300 ppm."        (EPA site still down)
       FN12  after "the cause of the rise in concentrations." (water vapor)
       FN13  after "a respected chemical engineering journal." (associate editor)
       FN14  after "something wrong in his assumptions."     (never submitted)
       FN15  after "published in 2007 and 2010/22."          (Beck)
       FN16  after "The referee who was a carbon cycle expert" (David Archer; Springer link)
       FN17  after "having domain experts review papers."    (domain experts)
  5. Delete the whole Footnotes section at the bottom: its horizontal rule, heading and the 17 FN
     paragraphs.
  6. Images: search for "INSERT IMAGE". For each marker, delete the line and upload the named PNG
     with Substack's image tool at that spot (fig1 ... fig7, in order). Each image is followed by
     an italic "Figure N: ..." line. Cut it into the image's caption field, or leave it in place as
     an italic line (Figure 2's must stay in place; see FN6).
  7. Search for "ADD SUBSCRIBE BUTTON HERE" (after the Conclusions) and replace it with a
     Substack subscribe button.
  8. Links. 30 of the 47 load from a script. These 17 block automated checks (publisher bot
     walls); open them by hand in the preview:
       Wiley/AGU   Jacobson "a CO2 lifetime of 30-95 years"; Schwartz "his 2007 paper"
       SAGE        Beck "2007"; Meijer (2007)
       ACS         "Essenhigh, 2009"; "Gavin Cawley"
       Royal Soc.  "Koutsoyiannis et al. 2022" (epigraph); "Royal Society article"
       MDPI        "MDPI article" (Christofides); "MDPI paper" (Dengler & Reid)
       ESSOAr      Schwartz "AGU poster"
       Elsevier    Humlum et al. (2013); Harde (2017); Starr (1993); Kohler et al. (2018);
                   Richardson (2013); Kern and Leuenberger (2013); Masters and Benestad (2013)
     The Spencer January 2009 address contains an ellipsis character (%E2%80%A6); it loads, but
     check it after pasting.
  9. Check CO2, H2O, H2CO3, CO3 2-, HCO3 -, H+ and delta-13C render with their sub- and
     superscripts. Then preview (web and email) and publish.

Formatting changes from the Word draft (wording otherwise unchanged, apart from a-c above)
  - "Title:" / "Subtitle:" labels dropped; "[link to ...]" placeholders turned into links on the
    words they follow; figure placeholders replaced by the image markers.
  - Figure X4-X8 renumbered Figure 3-7, in captions and text.
  - Section headings without trailing colons ("Contrarian Mistakes", "Conclusions"; "A couple of
    mainstream scientist examples" as a subheading). The two epigraphs are a block quote.
  - Chemical formulas and delta-13C with sub/superscripts; "--" as em dashes; number ranges with
    en dashes.
  - Typos: "Kohler et al (2018). criticizing" -> "Kohler et al. (2018) criticizing"; "responsae" ->
    "response"; the comma in "was that, 'cessation" removed; a comma after "Essenhigh, 2009";
    periods added at the ends of FN3, FN7 and FN15.
