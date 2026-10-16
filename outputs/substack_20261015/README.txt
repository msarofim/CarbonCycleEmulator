CarboTope launch post: Substack paste-in
========================================

Files in this folder
  carbotope_substack.html            the whole post, one paste
  hero_pulse_atoms_vs_excess.png     hero image (top of the post)
  fig1_keeling.png                   Figure 1
  fig2_pulse_airborne.png            Figure 2
  fig3_pulse_warming.png             Figure 3
  make_figures.R, provenance.txt     how the four PNGs were made (re-render is byte-identical)

Before posting (order matters)
  a. The app is deployed on Posit Connect Cloud (account saraphreport, Basic plan). The post
     links "CarboTope" to
     https://01a14244-5cc3-1951-7b06-9e2fb07beae3.share.connect.posit.cloud/
     which is live. Republishing keeps this address; a vanity name or custom domain would
     change it, so fix the link (step 8) if one is set before posting.
  b. Make the GitHub repository public. FN1 links to
     https://github.com/msarofim/CarbonCycleEmulator which is still private, so readers
     would get a 404.
  c. After the post is live: set APP_FEEDBACK_URL to the post's address, update
     test-review-cards.R, and redeploy (app/DEPLOY.md).

Paste and redistribute (Chrome)
  1. Open carbotope_substack.html in Chrome. Select all (Cmd-A), copy, and paste into the
     body of a new Substack post.
  2. Cut the title (first line) into Substack's title field.
  3. Cut the italic subtitle into Substack's subtitle field, then delete the horizontal rule
     under it.
  4. Footnotes: there are four, FN1-FN4, in reading order. Search the body for "FN". At each
     [FN#] marker, delete the marker, insert a footnote with Substack's footnote tool, and
     paste that footnote's text from the Footnotes section at the bottom. Take them in order
     1 -> 4 so Substack's numbering matches. FN1 and FN3 each contain a hyperlink: check it
     survives the paste into the footnote, and re-add it if not.
       FN1  after "CarboTope" in the first sentence        (GitHub link)
       FN2  after "to tune this model."                    (the Claude footnote)
       FN3  after "change global concentrations"           (Warming Papers; Bregman review link)
       FN4  after "either the CarboTope or FaIR"           (temperature relies on FaIR)
  5. Delete the whole Footnotes section at the bottom: its horizontal rule, heading and the
     four FN paragraphs.
  6. Images: search for "INSERT IMAGE". For each marker, delete the line and upload the named
     PNG with Substack's image tool at that spot.
       hero_pulse_atoms_vs_excess.png  top of the body, no caption. Optionally also set it as
                                       the post's social/cover image in post settings.
       fig1_keeling.png                Keeling Curve section
       fig2_pulse_airborne.png         after "The pulse tab ..." paragraph
       fig3_pulse_warming.png          directly after Figure 2
     Each figure is followed by an italic "Figure N: ..." paragraph. Cut it into the image's
     caption field, or leave it in place as an italic line.
  7. Search for "ADD SUBSCRIBE BUTTON HERE" (after "Coming up next") and replace it with a
     Substack subscribe button.
  8. Check every link in the preview:
       CarboTope                          https://01a14244-5cc3-1951-7b06-9e2fb07beae3.share.connect.posit.cloud/  (step a)
       millennial lifetime of carbon dioxide
                                          https://climatemodels.uchicago.edu/geocarb/archer.2009.ann_rev_tail.pdf
       van Vuuren et al. 2026             https://wcrp-cmip.org/explainer-scenarios-for-cmip7/
                                          (Cloudflare blocks automated checks; open it by hand)
       FN1 "here"                         https://github.com/msarofim/CarbonCycleEmulator  (step b)
       FN3 "reviewed by Bram Bregman in 2011"
                                          https://www.tandfonline.com/doi/full/10.1080/20430779.2011.637673
  9. Check CO2 / 13C / 14C / 20th render with their sub- and superscripts. Then preview
     (web and email) and publish.

Formatting changes from the Word draft (wording otherwise unchanged)
  - "Title:" / "Subtitle:" labels dropped; "[link to ...]" placeholders turned into links.
  - Figure X1/X2/X3 renumbered Figure 1/2/3, in captions and text.
  - Section headings without trailing colons; the 1) 2) 3) list is a numbered list.
  - CO2, 13C, 14C written with sub/superscripts; The Warming Papers in italics.
  - Periods added at the end of FN1 and FN4.
