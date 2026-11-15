# Handoff 2026-11-15: build group B (CarboTope minor issues, batch B)

**SUPERSEDED 2026-11-15** by `notes/handoff_2026-11-15_group_b_bundle.md`: group B is built and checked; two answers
from Marcus remain, then the bundle.

Marcus asked for this note ("Yes, write the handoff note", 11-15) so a fresh session builds his group B decisions.
Read with `CLAUDE.md`, `~/.claude/CLAUDE.md` (word-choice rules apply to every string a reader sees), memory
`INDEX_ccx_app.md` and `INDEX_ccx_app_build.md`, and the two notes this one continues:
`notes/handoff_2026-11-11_group_b_sheet.md` (the sheet session) and `notes/handoff_2026-11-11_minor_issues_batch_a.md`
(§3 is the build/suite/bundle/deploy recipe batch A used; follow it again).

## 1. Where things stand

- **The decisions:** `notes/decision_sheet_2026-11-11_group_b.md` (its top section "Marcus's decisions" and "Decided
  11-15" are the summary; each item's section has the current text, the code location and the options) and
  `outputs/diagnostics/groupb_20261111/decisions_20261115.json` (all 37 entries with his notes, verbatim). The
  fill-in page (https://claude.ai/artifact/MTiQHcqrUMichcsaNx8vMC) holds the same; the JSON is the copy to work from.
- **App code** is still the live `64d91397` (`git diff 64d91397 HEAD -- app R data src` empty at `557ce422`).
  Suite baseline at `64d91397`: 9,741 passed, 0 failed, 1 standing skip (`outputs/diagnostics/suite_20261111_64d91397.log`).
- **Last commit before this note:** see `git log`; the tree was clean.

## 2. What to build (one commit per item or small group; CHANGELOG entry per working unit)

Quote Marcus's text exactly where he wrote it; where his sentence carries a number, compute the number from the run
(the labels-from-constants rule) and keep his words around it.

**Science**
- **B19 → move card 4a to the What-if measure.** Card 4a (`app/R/plots_review.R` ~205–233, data from
  `rv_variability()`) now draws GATE V: GCB's Jan-to-Jan growth against the model's calendar-boundary stock
  difference (`dg_af_annual_model()`), 1959–2024, AF-regression anomalies. Move it to the What-if tab's estimator:
  `app_annual_growth(APP_HIST$out)` against `app_obs_growth(APP_OBS_GROWTH)` (NOAA MBL, annual means differenced),
  1980–2024, anomalies about `ns(year, df = 3)` (server.R `cf_window()` and `c_growth_note` define the window and the
  spline; reuse them, do not copy them). `calibration/diag_card4_enso_estimators.R`'s `WHATIF` row is exactly this
  series; use it as the reference the new chart must reproduce (r and sd ratio). GATE V itself stays as it is in the
  calibration code; only the card changes.
  - What changes with it: the caption's sd ratio goes from 0.864 to 0.672 (11-11 log); n = 45. The caption's r's are
    at lag 0 today (+0.48 vs +0.29, matching the GATEV lag-0 row); on the new estimator lag 0 gives +0.29 vs −0.15 and
    both peak at 11 months (+0.73 vs +0.51). Which lag the caption quotes is a choice to put to Marcus with the card 4
    drafts; the comparative word is "more closely than" at every lag.
  - **Card 4's text must be re-measured on the new measure, then drafted for Marcus** (wording is draft-only for
    him; ask before shipping): "over sixty-six years" (n = 45 now); "none of the three reaches significance"
    (re-run `calibration/diag_growth_residual_years.R`, or its equivalent, on the What-if series); "The single
    largest overshoot is 1991 … 1983 … misses the other way" (⚠ 09-26 measured 1991 at +0.43 on the matched
    estimator, an ordinary year, against +1.02 on the mismatched pairing: the sentence may be an estimator
    artefact); the last sentence ("On the first chart's measure … it is less") becomes B19 option (a) adapted to
    ONE measure, e.g. "The model's growth follows the ENSO index more closely than the measured growth does. The
    variance the model lacks is in the part that does not follow ENSO." Ask: option (a)'s.
  - `tests/testthat/test-review-card-numbers.R`: add the check option (a) promised: recompute r for model and record
    on the card's estimator and fail if the model's is not the larger.
- **B19, RONI:** done (sheet, "Decided 11-15"). No app change.
- **B20 card 3:** (b) cut the sentence (`app/R/review.R` ~656–667).
- **B20 card 7:** replace the detail text (`app/R/review.R` ~886–892) with the wording in the sheet's "Decided 11-15"
  (his, corrected). Keep the existing numbers' sources (1,840 from the table, 1,446 Naegler 2009) and their comments.
- **B21:** (a) take the SST amplitude off card 7's "matter most" list (sheet B21).
- **B20, the prior:** not an app change; it is item 1 of `notes/next_refit_candidates.md`.

**Design**
- **B12 (b):** the seasonal chart follows the hemisphere control; the takeaway and readouts stay fixed and say so.
- **B13: OPEN.** Marcus asked what (b) takes; the answer and measurements are under B13 in the sheet
  (`b13_monthly_shape.R`). Build nothing until he decides.
- **B14 (C)** annual means from the start, 50 % line darkened, **plus** his addition: a note shown whenever the window
  includes years before 1900, saying the airborne fraction is poorly defined before the 20th century because human
  emissions were small. Draft the note's sentence close to his words and show it to him with the batch.
- **B15 (a):** the residual strip's caption from the window, and correct `server.R`'s comment above `output$c_resid`.
- **B16 (a):** phone: scroll to the takeaway once the new chart has drawn.
- **B17 (a):** below 992 px the sidebar takes the full width under the lead, as on phones.
- **B18:** all five cosmetic rows (sheet B18; #5 is the Pulse lab legend losing the ₂ at 768 px).
- **B22 (c), new** (sheet B22): on Futures → Build your own,
  1. the Pulse lab's stale rule (`app_pulse_stale()`, `APP_PULSE_RESULT_IDS`, the `ccx_pulse_stale` handler in
     `ui.R`, Marcus 10-20): once any Build-your-own input differs from the inputs of the run on screen, grey
     `f_plot`, `f_takeaway`, `f_notes` (derive the set the way test-app-precompute.R 11 derives the pulse set) and
     show under the button "Chart reflects previous settings. Press Run it to update." built from
     `APP_BUILD_RUN_LABEL` (his 10-20 Pulse wording, with the Build button's name);
  2. a "Calculating…" label beside the chart from the press until the new chart draws, on Build your own and the
     Pulse lab, with the chart greyed at once (Shiny's default fade starts only after ~1 s).
  Measured before the change: the run takes 1.3 s; the old chart stays at full opacity for 1.0 s. Re-measure after
  with the same in-page JS (events `shiny:recalculating` / `shiny:value` on `f_plot`, opacity sampled every 100 ms).

**Wording** (his choices; the drafts are in the sheet's B1–B9/B11 sections and the page)
- Drafts as written: **B1, B3, B5, B7, B8**. **B9:** all ten rows. **B11:** all three takeaways.
- **B2:** his sentence: "Between 100 and 250 years, the warming actually increases a little (4%), whereas the
  airborne carbon concentrations drop another 18%." The 4 % and 18 % (and 100/250) come from the run (the draft's
  104 %/82 %); if a setting can make the warming fall, the verb must follow the sign. Leave his words otherwise.
- **B4 (a):** his sentence, "With El Niño / La Niña switched off, global-average CO₂ in 2024 changes by +0.2 ppm. This
  switch mostly impacts year-to-year variability rather than growth over time: see the growth-rate chart below."
  (drop the stray closing quote in the JSON). It must also serve the volcanic switch (+0.217 → +0.2) and both off
  (+0.378 → +0.4): the switch's name and the number vary, the rest is his. Under 1 ppm one decimal (option a).
- **B6:** his edit of the draft: "Runs the model with and without the pulse, from identical starting conditions, and
  takes the difference to estimate the impact of the extra carbon. A third run tags the pulse's carbon atoms to follow
  where they go."
- **B10:** all four unit glosses (sheet B10).

## 3. Then

Full suite in the background (~25 min; never edit a file an R process is reading), compare with the 9,741 baseline,
report any previously passing test that fails and stop (do not edit a test to pass without asking). Bundle under
`~/ccx_frozen/bundle_<date>_<commit>`, serve it locally, check every tab at 1440 × 900 and 375 × 812 and every
Download link (`outputs/diagnostics/review_20261111/check_dl_links.py`), then hand Marcus the publish step and do the
live checks after (batch A §3; the 11-11 (m)/(p) records). Send Marcus the drafts that need his approval (card 4,
the B14 note) before the bundle, in one message.

## 4. Traps (from the last three sessions)

- `Shiny.setInputValue` changes the server's input but not the widget: drive state by bookmark URL
  (`?_inputs_&tabs=…`) for any screenshot that shows controls (memory `shiny_setinputvalue_screenshot_mismatch`).
- Download outputs must stay registered never to suspend (11-11 j); a CSS rule that hides a Download line suspends it.
- The U.S.-spelling lint covers `stop()` messages (11-11 k).
- `test-plot-text-fits` 3a reads only the first 140 lines of `plot_box_diagram()`.
- Temporary `.claude/launch.json` entries: revert (`git checkout -- .claude/launch.json`). One headless Chrome per
  job, killed by PID. Wait on PIDs, never a `pgrep -f` loop.
- A committed diagnostic re-run with a new option can overwrite its committed outputs; date-stamped stems avoid it,
  but check `git status` before committing.
- A family/partition gate checks coverage, not membership (memory `partition_gate_blind_to_membership`, 11-11).
