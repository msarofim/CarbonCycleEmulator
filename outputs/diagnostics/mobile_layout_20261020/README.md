# CarboTope on a phone (2026-10-20)

Branch `claude/dazzling-nash-6c3551`. Code commits `6f732a6`, `3b20ff2`, `5659d26`, `6ffdb96`; this record was
captured at `6ffdb96` against the local app (`ccx-app`, port 7788). Not merged, not deployed.

## What changed

Below 576 px (Bootstrap 5's `sm`, where `sidebarLayout()` stacks), `app/ui.R`:

1. The eight navbar links are hidden and a `<select>` takes their place beside the brand. The script builds it
   from the links (same order, same text), clicks the matching link on a choice, and follows the open tab.
2. `main_panel(lead = ..., ...)` wraps each sidebar tab's takeaway and main plot in `.ccx-lead` and the rest
   in `.ccx-rest`. CSS `order` puts the lead first, the sidebar's controls second and the rest last.
3. Plots get a 320 px height floor; a word wider than the screen breaks; the three readouts on "Where does the
   carbon go?" stay in one row (`col-4`, 1.2rem); the box diagram keeps its tuned 565 px width and scrolls
   sideways inside its frame.

At 576 px and above none of these rules applies. No app text was reworded; one new string,
`APP_TAB_MENU_LABEL = "Choose a tab"`, is the select's accessible name for screen readers and is not displayed.

`app/R/plots.R`: `app_fit_plot()` refits a finished plot when its live width is at most 552 px (the full panel
at the 768 px floor). It measures the plot on the device `renderPlot()` has open and changes only what
overflows: more legend rows, a wrapped axis title, a wrapped title or subtitle, category labels turned on end,
fewer tick breaks. `renderPlotFit()` (`app/server.R`) sends every plot through it. The tension chart on "What
pins down what?" puts measurement names above its bars when they do not fit beside them.

## Results

First screen at 375 x 812 (px from the page top; the screen ends at 812):

| Tab | before: takeaway / first plot | after: takeaway / first plot | after: controls | page width |
|---|---|---|---|---|
| The Keeling Curve | 837 / 1208 | 258 / 629 | 1023 | 375 → 375 |
| Where does the carbon go? | 549 / 931 | 169 / 452 | 796 | 375 → 375 |
| What if…? | 981 / 1119 | 169 / 306 | 720 | 375 → 375 |
| Isotope fingerprints | 668 / 993 | 169 / 494 | 828 | 375 → 375 |
| Futures | 1080 / 1217 | 169 / 306 | 720 | 375 → 375 |
| Known issues | none / 1367 | none / 1151 | none | 537 → 375 |
| What pins down what? | 624 / 995 | 225 / 596 | 1382 | 375 → 375 |
| Under the hood | none / 762 | none / 546 | none | 401 → 375 |

Navbar 288 → 72 px. Known issues and Under the hood have no takeaway or sidebar; their sideways scroll came
from the review tables' code names and the repository URL.

**768 x 1024 and 1440 x 900:** navbar height, takeaway, first-plot and controls positions, page width and
plots drawn are identical to `9cb7701` on all 8 tabs (`layout_summary.csv`, `base_*` vs `after_*`).

**Plot text.** `ink_scan.txt` lists where the ink is in every plot image Shiny sent. Before, 13 of the 25 plots
drawn by default at 375 px had ink in their outermost 2 px, i.e. text cut at the border (legends at both
sides, captions, a y title). After: 0 of 81 (25 default plots plus the pulse lab partition and a What-if
driver chart, at all three widths). The scan does not see a y title running into a caption or labels running
into each other; those were checked by eye on the 375 px images (Keeling seasonal cycle, the review card on
the ocean's disequilibrium, the tension chart, the pulse lab's two panels).

**Desktop and tablet plots, byte for byte** (`samepath_768_1440_vs_9cb7701.txt`). Both apps were run from the
same checkout path, the old code and then the new; two app instances in different checkouts produce
different PNG bytes even with identical model output (the historical run is identical; checked), so only a
same-path comparison means anything. At 1440 px, 23 of 25 plots are identical. The two that change are the
half-width charts on "Where does the carbon go?" (516 px): the airborne-fraction y title was cut off at the
top and now wraps; the uptake-bars y title touched the caption and now wraps. At 768 px five change: the same
two, the Δ¹⁴C legend (four keys in one row, cut at both sides; now two rows), the residual strip's y title
(it ran into the caption), and the pulse-share bars on Known issue 5 (y title wraps; it was within 6 % of its
room, the safety margin the caption wrapper also uses).

## Files

- `before_375x812_*.png`, `after_375x812_*.png`: first screen of each tab. `after_768x1024_*`,
  `after_1440x900_*`: the same after the change. `*_extra_*`: the pulse lab partition (Futures → Pulse lab →
  Release the pulse, defaults) and the What-if driver chart (El Niño / La Niña switched off alone).
- `full_375/`: each tab's whole page at 375 px, after the change.
- `*_layout.jsonl`, `layout_summary.csv`: the measurements behind the table (`base_*` = `9cb7701`).
- `shoot_tabs.py`: drives headless Chrome over the DevTools protocol (stdlib only).
- `ink_scan.py`, `ink_scan.txt`: the border scan. `run_app_tests.R`: the app-facing test files, one row each;
  `app_tests_6ffdb96.log` its output.

To reproduce: start the app (`ccx-app`), start Chrome with `--headless=new --remote-debugging-port=9333
--user-data-dir=<tmp> --hide-scrollbars`, then
`python3 -I shoot_tabs.py 9333 http://127.0.0.1:7788/ <out> after 375 812 --mobile --extras --plots <dir>`.

## Tests

App-facing files at `6ffdb96` (`app_tests_6ffdb96.log`): 11 files, 482 passed, 0 failed, 0 skipped, 2 warnings.
The 2 warnings are in `test-review-0916-fixes.R` and are the same 2 at `9cb7701` (a forcing window that starts
in 1900).

New: `tests/testthat/test-app-phone-layout.R` (37 expectations). Each fitter case first asserts that its fixture
overflows at 351 px, then that the fitted plot fits; a plot that fits, and any plot above 552 px, must come
back identical. The ui.R check requires every sidebar tab to use `main_panel()` with a takeaway in its lead.
Mutation-tested: disabling the legend refit, the y-title wrap, the subtitle wrap, the label rotation, the tick
thinning, the 552 px threshold or the tension chart's rule each fails its test; so do a bare `mainPanel()` and
a takeaway left out of the lead.

## For Marcus

- The select's screen-reader label "Choose a tab" is new text (never displayed).
- The box diagram scrolls sideways on a phone rather than shrinking; its text overlapped at 351 px.
- On a phone, plots are at least 320 px tall and the readout numbers are 1.2rem.
- Two desktop charts change (above): the airborne-fraction and uptake y titles now wrap at 1440 px.

## Not covered

- Real devices: Chrome's device emulation only (touch on, DPR 1 for the record, DPR 2 in the in-app browser).
  Safari on iOS was not tested.
- Screens narrower than 375 px: at 320 px the select truncates longer tab names.
- Cost: refitting re-renders a plot up to twice at phone width. The partition chart on "Where does the carbon
  go?" builds in ~0.4 s, so that tab settles ~1 s later on a phone (2.6 s vs 1.5 s here).
- Found, not fixed (seen at 1440 px on `9cb7701` too, so not caused by this change): on Known issue 2 both
  facet strips read "CO gradient (ppm)" with no subscript. The second should be the δ¹³C gradient. My guess at
  the cause, not tested: `rv_plot_gradient()` hands `app_plotmath_str`, which reads only its first string, to
  `as_labeller()`, so the first label is recycled.
