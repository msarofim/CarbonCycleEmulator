# CarboTope minor-issues review, 2026-11-11

Marcus: "Review the rest of carbotope for any other minor issues that should be fixed." Live app at `8be0095`
(revision `01a1cac5`) and the landing page. Three passes ran in parallel: a desktop visual sweep (1440 × 900, 57 states,
console errors logged), a phone and tablet sweep (375, 360, 768, 1024 px; Chrome emulation, not a real device or
Safari), and a text and links review of every reader-facing string (rendered with real numbers at `hilda31fl`).
Screenshots referred to below are in `outputs/diagnostics/review_20261111/`.

**Clean:** no console errors or failed loads in any state; no sideways page scroll at any size; every chart draws;
every link works (carbotope.org, the Substack post and its `#discussion` anchor, GitHub, the app, the landing-page
files); the phone tab menu works; all 19 info boxes and every unit gloss open and close on a tap. The server log since
the publish (63 sessions) has one warning: the reviewers' +5 %/yr Build-your-own run reached 45,707 ppm, beyond the
CO₂-to-forcing fit. The app shows its "Outside the fitted range" note for that case.

✔ = checked by me against the code or the image; the rest are as reported by the review passes, with their screenshots.

## A. Fixes that need no wording decision

| # | Where | Problem | Proposed fix |
|---|---|---|---|
| A1 ✔ | Under the hood, box diagram (every width, desktop too) | The bold sentence under the diagram is cut off at both edges ("Photosynthesis" loses its P, "molecule" its e). "air to warm sea" runs under the Ocean mixed layer box; "6 litterfall" is half hidden; an arrow crosses "warm". `desktop_hood__h_diagram.png` | Wrap the sentence to the image width; move the three labels clear |
| A2 ✔ | What if…? takeaway | "486 ppm instead of 425 — a difference of +60 ppm" (the values are 485.9 and 425.4); 58 of 124 switch combinations. A hyphen prints as the minus sign ("-6 ppm") | Print the difference of the rounded values; use a true minus |
| A3 ✔ | Futures, all three modes | A scenario's colour depends on which others are ticked (Low is red in the default view, green with all seven; the background in Build your own and Pulse lab is always red, so "Medium" is red there and green in Scenarios). `desktop_f_scen_default__f_plot.png`, `desktop_f_scen_all7_co2__f_plot.png`, `desktop_f_build_constant_co2__f_plot.png` | One fixed colour per scenario, used in every mode |
| A4 | Phone: Known issues card 7's tables, every Under the hood table | `overflow-wrap: anywhere` splits words and numbers ("1.9/3", "1,8/40") so one number reads as two. `mobile_p375_6_known_issues_full_p10.png`, `mobile_p375_8_under_the_hood_full_p01.png` | Let tables scroll sideways inside their own frame and keep numbers whole; prose keeps the rule |
| A5 | Phone charts | Card 3 (`rv_diseq`) facet title "emisphere average"; card 1 (`rv_repdc`) legend dots and labels cut at 360 px; Pulse lab partition: "2300" meets "2100" (375, 768), panel title clipped (360); What pins down what? heatmap row labels overlap at 360, tension-bar labels clipped. `mobile_*` | Extend the narrow-panel fitting to facet titles, annotations and category labels on these charts |
| A6 | Desktop, Known issues | Card 1's annotation sits on data points; card 2's δ¹³C Model bar runs into the panel edge. `desktop_rv_repdc_ann.png`, `desktop_rv__rv_gradient.png` | Move the annotation; pad the axis |
| A7 | Keeling chart, short windows | 2015–2024 labels the axis 2015.0, 2017.5 … `desktop_k_nh_2015__k_plot.png` | Whole-year breaks |
| A8 | Pulse lab | A 2030 release: the first year label is 2100, so the release year is unlabeled; a 10 GtC pulse reads "0.01 °C … and 0.01 °C after 250 years" (0.015 → 0.0143). `desktop_f_pulse_10_2030_vvVL__f_plot.png` | Label the release year; two significant figures for small values |
| A9 | What pins down what?, "Individual parameters" | The x title still says "Part of the model"; the tension chart and the parameter columns show code names (seas_lag_p_NH, tau_ex …) where the prose uses plain names; tension-bar labels ~8 px. `desktop_cm_parameter__cm_map.png`, `desktop_cm_component__cm_tension.png` | Title per level; plain names from `app_param_desc()`; larger labels |
| A10 | Sidebars | Unticked checkboxes and radios have a 1.2:1 border contrast (nearly invisible); the merged slider label "2015 — 2024" overruns the card; Pulse-size slider ticks "460 500" crowd; wrapped checkbox labels run under the box. `desktop_c_boxes.png`, `desktop_k_slider2015b.png`, `desktop_p_sliders.png` | Darker border; contain the label; fewer slider ticks; hanging indent |
| A11 | Futures before "Run it" / "Release the pulse" | Empty chart areas still show "Download: data (CSV) · figure (PNG)" | Hide the links until there is a chart |
| A12 | Build your own at +5 %/yr | Takeaway prints "45707 ppm" (the note beneath prints "45,806") and "4925.7 GtC a year, 467.6 times" | Thousands separators; whole numbers at that size |
| A13 | Legends | Two-entry legends wrap to two rows with room to spare (Keeling SH-only, δ¹³C, pulse chart); the seven-scenario legend reads down columns; FaIR's dashed lines have no legend key in Scenarios (a downloaded PNG loses the explanation); "Without: The ocean sink", "Without: Our emissions" | One row when it fits; row order; a FaIR key; lower-case after "Without:" |
| A14 | Landing page | The preview image carries a dark scrollbar strip from my screenshot. `mobile_p375_landing_full_p00.png` | Retake with scrollbars hidden |
| A15 | "What it is fitted to" (Under the hood) | South Pole CO₂ says 1975–2024; the level is scored from 1962 (the seasonal statistic from 1975). Other spans are typed and will go stale at the next GCB update | Read the spans from the data, as the Mauna Loa row does |
| A16 | Latent text bugs (correct today) | "with 1 further values held", "1 of the strongest opposing pairs are", "0% more" when equal, "%+.2f" can print "-0.00", the imbalance box's hard-coded "plus"/"less" around unsigned values, "in 0 of 7 decades", Scenarios with every box unticked leaves an empty takeaway and chart | Guard each case |

## B. Your call: wording, design or science

**Wording (all approved text; suggestions only)**
- B1 ✔ What pins down what? takeaway (your 10-02 text): "A metric low on the chart is one this model could change a good deal without results changing substantially" reads as the reverse of what is meant; it also says "metric" where the tab says "measurement". Suggestion: "A measurement low on the chart is one that changes little even when the model's parameters change a good deal."
- B2 ✔ Pulse lab temperature takeaway: "the warming keeps 104% of its century-later value" ("keeps" above 100%). Suggestion: "is at 104% of".
- B3 What if…? with nothing ticked: "the charts show the full model against the measurements", but the CO₂-level chart has no measurements.
- B4 What if…? with only El Niño or only volcanic aerosols ticked: "these are year-to-year mechanisms, and they move the wobble" (plural for one switch).
- B5 "Forest regrowth" readout shows −1.22 next to a takeaway saying "1.22 GtC absorbed/year".
- B6 Pulse lab note "Runs the model twice": three runs since the tagged-pulse panel (10-12).
- B7 Under the hood "Parameters": "the few it holds" covers 14 of 45 rows; "the El Niño settings" match rows named "ENSO …"; held rows that are neither (the biological pump) are not covered.
- B8 The pulse partition takeaway says "in this box" (twice) for "in this panel", where "box" elsewhere means a reservoir; "residence lifetime" vs the usual "residence time".
- B9 Trivial: "a couple exceptions" (Keeling takeaway); "What-if tab" vs "What if…?" (card 4); "southern hemisphere" lower case (Known issues 1); "air-sea" vs "air–sea"; "1000 GtC" without a separator; "IGCC" not spelled out; card 8 prints its range high-to-low; "Left: This is…" / "Right: the same…"; the FaIR checkbox ends in a period; landing page "carbon-cycle model" (title, mine) vs "carbon cycle model" (your lead).

**Unit glosses and takeaways (project rule 7)**
- B10 ‰ in the Isotopes takeaway has no visible gloss; GtC in Build your own and What if…? (driver chart) has none in those modes; Under the hood's table shows ppm and ‰ with only the GtC note.
- B11 Panels with a heading but no one-sentence takeaway: Airborne fraction, "Does the model agree with the measured budget?", the Δ¹⁴C chart.

**Design**
- B12 The Keeling takeaway always describes Mauna Loa 1958–2024, and the Where readouts always give 2024 totals, whatever the year or hemisphere controls say. The seasonal chart always shows Mauna Loa and ignores the hemisphere and measurement controls.
- B13 ✔ The seasonal chart's "Measured, Mauna Loa" curve is a one-harmonic fit to the measurements, labelled "Measured".
- B14 Airborne fraction for early windows: at 1750–1900 the axis runs −100 % to 300 %; before ~1900 the default view draws a solid band (monthly ratio of tiny numbers). Needs a choice of where the ratio starts to mean something. `desktop_w_1750_1900__w_af.png`, `desktop_w_default__w_af.png`
- B15 The residual strip under the growth chart runs 1979–2024 while the chart above runs 1850–2024; its caption says "Same years … as the panel above".
- B16 Phone: in Build your own and Pulse lab the button sits ~1000 px below the chart it fills; after "Run it" the reader sees the bottom of the chart with the new takeaway above the screen. `mobile_p375_after_run_it_viewport.png`
- B17 Portrait tablet (768 px): the sidebar is ~167 px wide, so slider handles sit 5 px apart, dropdown arrows overlap their text, and labels wrap one word per line. `mobile_t768_1_the_keeling_curve_top.png`
- B18 Cosmetic layout: the yellow banner is narrower than the content under it; the three Where readouts sit at different heights on a phone; "view" of "Copy link to this view" wraps alone; tap targets under 32 px (download links 15 px, slider handles 22 px).

**Science claims to re-measure at `hilda31fl`**
- B19 Card 4: "on the What-if tab's measure it is less [ENSO-driven]". Re-measured on that estimator, the model correlates more strongly with Niño 3.4 than the record at every lag tried (r +0.29/+0.58/+0.67 vs −0.15/+0.19/+0.37 at 0/3/6 months). If that holds, the sentence's conclusion loses its support.
- B20 Card 3's "about 15%" was measured at `hilda29l`; card 7's "The data prefer the literature value" at `hilda31w`. Neither re-checked since. (Re-checked and still true: card 1 "several times", card 2 "about 12% low", card 3 "about a third", card 4 "about one ppm after Pinatubo" and "70–90%", card 5's ordering, card 6's counts, card 7's "about 1,840", the What-if ENSO blurb.)
- B21 Card 7 lists the seasonal SST amplitude among the stand-ins "that matter most for what this app claims"; What pins down what? names the two SST seasonal swings as the parameters with the least influence.
