# Beta copy worklist, 2026-10-12

- Date: 2026-10-12. Commit: `f0def17`.
- Compiled read-only; no copy drafted.

Every `file:line` below was found by grep in the checkout at `f0def17`. None is copied from a note. Strings are quoted as they appear in the source, EXCEPT that some `\u` escapes are shown as the character they produce (₂, —, °, ñ). To grep the source, search for the escape (e.g. `CO\u2082`). Checked 2026-10-12 (main session): every quoted line was found in the code (36 locations; 9 single-line quotes at the stated line, 8 exact and 1 differing only by an escape; all 170 block lines found). Where a string is built with `paste()` / `sprintf()`, the source expression is quoted; comment lines inside it are elided and marked.

**Status key:**
- `DRAFT`: Claude's wording, needs his.
- `EMPTY`: no text yet.
- `STALE`: his text, now factually out of date.
- `PLACEHOLDER`: a deploy setting.
- `ACTION`: not copy.

## Contents

| Group | Items |
|---|---|
| A. Blockers for lifting the Futures band hold | 5 (four pieces of copy and the one-line lift) |
| B. Pulse lab | 11 |
| C. Review cards (and the two items the brief grouped with them) | 16 |
| D. Other app copy | 5 |
| E. Deploy blockers that are not copy | 5 |
| F. Could not locate or could not resolve | 6 |

**Sources:**
- handoffs `handoff_2026-10-12b_tagged_pulse_fair_grid.md` §4 (newest), `_2026-10-12_pd100_free_climate.md` §4, `_2026-10-11_comments_fair_pd100.md` §4 and `_2026-10-10_band_shipped_hold_on_copy.md` §3;
- facts notes `ship_copy_facts_2026-10-09.md` and `card5a_caption_facts_2026-10-12.md`;
- CHANGELOG 2026-10-08 (g), (j); 10-09 (f); 10-10 (c); 10-11 (a), (c); 10-12 (b), (g)–(o);
- memory `ccx_app_beta_blockers`.

---

## A. Blockers for lifting the Futures band hold

**The rule** (handoff 10-10 §3.1; `ship_copy_facts_2026-10-09.md` top):
- A1–A4 land in ONE commit together with A5.
- `test-futures-ribbons.R` fails a lift while any of A1–A4 is open.
- Then run every test that reads `global.R` or `review.R`: `test-review-cards.R`, `test-app-review-copy.R` and the card-number tests. Then check the app in the browser.
- Card 6's id stays 6.

### A1 — The band's label, and the caption frame it sits in

**Where:**
- The label is not in a source file. It is `provenance$label` inside `data/futures_ribbons.rds` (md5 `18c1dea3494ee933311ac63bd455bd4c`).
- It is set by re-running `calibration/promote_futures_ribbons.R` with `--label=` (`:38` reads the argument; `:81–82` write `label` and `label_ruled`). The exact command is in `ship_copy_facts_2026-10-09.md` §A.
- The frame is rendered by `app/global.R:514–518` (`APP_RIBBON_NOTE`).

**Current text:**
- The label, read from the `.rds`: `MCMC posterior draws (supplied), conditional on the fourteen held values`. `label_ruled` = `FALSE`, `n_ok` = 17000, `probs` = 0.05 / 0.5 / 0.95.
- The frame (`global.R:514–518`):
  ```r
  APP_RIBBON_NOTE <- if (isTRUE(APP_RIBBONS$ok)) with(APP_RIBBONS$provenance, sprintf(
    "Shaded: the %g–%g%% range of %d model runs — a %s.",
    100 * probs[1], 100 * probs[length(probs)], n_ok, label)) else
    if (isTRUE(APP_RIBBONS$held)) NULL else       # held: silent -- card 6 (the bands card) says why there is no band
    sprintf("No uncertainty band is drawn: %s.", APP_RIBBONS$why)
  ```

**Status:**
- The label: `DRAFT`. It is the builder's provenance label and was never ruled copy (facts note §A).
- The frame: `DRAFT`. The facts note §A calls it "unruled template text".

**Must agree with** `ship_copy_facts_2026-10-09.md`, "What the band IS" and §A:
- 17 000 runs, 5–95 % shaded. The count prints as "17000", with no thousands separator (`%d`).
- 29 fitted carbon-cycle parameters are varied and 14 values are held.
- The climate response, the non-CO₂ forcing and the structure are not varied.
- The line is inside the band in 5614 of 5614 cells.
- At the default selection the band is visible only on High: about 8 px at 2150 in an 800 px viewport.

**Gate:** `tests/testthat/test-futures-ribbons.R:79`, "the HOLD: the loader draws nothing while it is set, and it is lifted only with the copy". Its helper `.fr_lift_problems()` (`:68–77`) fails while `label_ruled` is not TRUE (`:71`). The tests at `:154` and `:168` check that the re-promoted bands and method are the landing's own.

### A2 — Card 6 ("bands"): title, plain, detail, ask

**Where:** `app/R/review.R:706–730`. The comment above it (`:703–705`) still points to `notes/card6_facts_2026-10-02.md`. That note is superseded for its numbers by the 10-09 facts note (handoff 10-10 §4).

**Current text** (`review.R:706–730`, verbatim):
```r
  list(id = 6, key = "bands", class = "gap",
       title = "There are no uncertainty bands, anywhere",
       plain = paste("Every line in this app is a single best fit. There is no",
                     "posterior, so there are no ribbons, and no number here",
                     "comes with a calibrated uncertainty."),
       detail = paste("The parameters were located by dispersed multistart",
                      "optimisation, and the curvature at the optimum is",
                      "well-behaved enough to quote individual standard errors --",
                      "but a Gaussian approximation at a mode is not a posterior,",
                      "and at this model's conditioning the widest directions",
                      "would be exactly the ones that approximation handles worst.",
                      "Drawing a band from it would put a number on the chart that",
                      "reads as calibrated uncertainty and is not.",
                      "That has since been measured: a Gaussian band was built and",
                      "run through the full model, and along the direction that",
                      "trades the strength of CO₂ fertilisation against its",
                      "shape the real fit falls away far faster than the Gaussian",
                      "assumes, so the band would have been too wide. Running a real",
                      "sampler is planned for the final model, not this beta: the",
                      "compute is affordable, but no sampler has yet converged on",
                      "this posterior, and that is a research problem rather than",
                      "a queue wait."),
       ask = paste("Would you want the posterior before you trusted any of this,",
                   "or is a single best fit acceptable for a teaching tool that",
                   "says so on every tab?")),
```

**Status:** `STALE`. The text is his approved copy, and it describes an app with no band. The sentence beginning "That has since been measured" is Claude's (`review.R:701–702`: "drafted for Marcus's wording").

**Must agree with** `ship_copy_facts_2026-10-09.md` §B, F1–F5. Where the current text disagrees:
- "so the band would have been too wide". F1: "Not re-measurable at `hilda29e`… The ~2× factor (CO₂ 0.41×, GMST 0.58×) is `hilda33d`'s, 10-02."
- "well-behaved enough to quote individual standard errors". F2: near 1× along fertilisation; 5.2× for `h_ml`; 1.4× for three others.
- "Running a real sampler is planned … no sampler has yet converged". F3: "A sampler HAS run." R-hat max 1.046 (`beta_max`), 8 of 30 above 1.01, min bulk ESS 105. The chains agree to ≤ 3.5 ppm CO₂ (21 % of the band's width).
- "There is no posterior, so there are no ribbons". Once the hold lifts, a band IS drawn: F4, F5, and "What the band IS".

**Gate:** `test-futures-ribbons.R:79` via `.fr_lift_problems()`. ⚠ It checks ONLY the title string, which it holds as `FR_NO_BAND_TITLE` (`:62`, `"There are no uncertainty bands, anywhere"`). Nothing gates the plain, detail or ask. `test-review-cards.R` also applies to every card:
- `:40`: the ledger is valid and rendered, so all four fields must be non-empty;
- `:60`: the `ask` must contain "?".

### A3 — The parameter panel's "not yet a posterior" clause

**Where:** `app/global.R:338–341`, inside `app_params()`. The comment at `:336–337` reads "If a band ever ships, this clause must go with it."

**Current text** (`global.R:331–341`, the expression it closes):
```r
    detail <- paste0("Maximum-a-posteriori fit of ", .n_fit,
                     " parameters to CO₂, δ¹³C, Δ¹⁴C and Global Carbon Budget",
                     " sinks",
                     if (.n_pin) paste0(", with ", .n_pin,
                                        " further values held at stated numbers") else "",
                     # [comment lines 336–337 elided]
                     ". A single best fit, not yet a posterior — no",
                     " uncertainty ranges are shown, and the fit constrains the",
                     " shape of these curves more tightly than their absolute",
                     " height.")
```

**Status:** `STALE`. It becomes false when the hold lifts.

**Must agree with** `ship_copy_facts_2026-10-09.md` §C:
- The lines are still the single best fit (MAP).
- The Futures tab shows a sampled band around them.
- Nothing else in the app has a range.

**Gate:** `test-futures-ribbons.R:79` via `.fr_lift_problems()`. It fails while `global.R` contains `FR_NO_BAND_PANEL` = `"not yet a posterior — no"` (`:63`, `:72`).

**Related string, currently unreachable:** `global.R:344–347` sets
```r
    detail <- paste("Bayesian posterior from MCMC. Ribbons show the calibrated",
                    "parameter uncertainty.")
```
It runs only if `calibration/output/posterior_draws.rds` exists. The comment at `global.R:473–475` says that path "would relabel the whole app 'calibrated posterior'". Nothing ships it. Listed only so that it is not mistaken for live copy.

### A4 — The temperature view's sentence (`APP_RIBBON_NOTE_TEMP`)

**Where:** `app/global.R:532`. The ruling and its description are at `:519–531`.

**Current text:** `APP_RIBBON_NOTE_TEMP <- NULL`

**Status:** `EMPTY`. It blocks the lift.

**Must agree with:**
- the ruling: CHANGELOG 10-10 (c), Marcus verbatim: "Omit it on temperature";
- the facts in `ship_copy_facts_2026-10-09.md` §D: 0.02–0.10 °C wide at 2100–2150, against lines 1.25–4.61 °C apart; about 3 px at the app's scale; temperature moves only through the CO₂ it is handed.
- The comment at `global.R:529–530` says what the ruling asks the sentence to convey.

**Gate:** `test-futures-ribbons.R:79` via `.fr_lift_problems()` (`:74–75`), "the temperature view's sentence is not yet worded" while it is NULL or blank. `:122` ("RULED 10-10 …") checks that the temperature view shows this sentence in place of the label.

### A5 — The lift itself (one line)

**Where:** `app/global.R:496–498`.

**Current text:**
```r
APP_RIBBONS_HOLD <- paste("held until the copy lands (ship ruled 2026-10-09): the band's label, card 6",
                          "and the parameter panel still describe an app with no band, and the",
                          "temperature view's sentence is not yet worded")
```
It is never displayed (handoff 10-10 §2).

**Status:** `ACTION`. Set it to `NULL` in the same commit as A1–A4.

**Gate:** `test-futures-ribbons.R:79`. With the hold NULL, `.fr_lift_problems()` must return empty (`:88–90`).

---

## B. Pulse lab

Every item in B1–B10 is marked as a draft in code:
- `app/R/plots.R:68–70`: "THE KEYS, PANEL TITLES AND NOTES BELOW ARE DRAFTS FOR MARCUS'S WORDING";
- `app/global.R:845`: "DRAFTS for Marcus's wording (2026-10-12)".

**The facts these sit beside** (CHANGELOG 10-12 (j), (k)):
- `vvM`, 100 GtC released in 2050.
- After 100 yr, **9.7 %** of the pulse's own atoms are still in the air, against **50.4 %** of the extra CO₂ (5.2×).
- After 20 yr: 19.8 % against 59.9 % (3.0×).
- CarboTope against FaIR's mean (5–95 %):

| after the release | CarboTope | FaIR |
|---|---|---|
| +1 yr | 0.903 | 0.884 (0.841–0.921) |
| +20 yr | 0.598 | 0.576 (0.487–0.655) |
| +100 yr | 0.503 | 0.514 (0.348–0.664) |
| +250 yr | 0.410 | 0.471 (0.239–0.666) |

- FaIR's grid covers 7 markers × release years 2030–2100, every 10 yr, at 100 GtC only.

### B1 — The legend key for the extra-CO₂ line

- **Where:** `app/R/plots.R:71` (used at `:1514`, `:1522`).
- **Current text:** `KEY_PULSE_EXTRA  <- "The extra CO₂ (with the pulse, minus without)"`
- **Status:** `DRAFT`.
- **Must agree with:** CHANGELOG 10-12 (j).
- **Gate:** `test-plot-text-fits.R:212`, "3b. legend keys fit, as a ROW and not only one at a time". Every `KEY_*` must fit a full panel's width.

### B2 — The legend key for the tagged line

- **Where:** `app/R/plots.R:72` (used at `:1519`, `:1522`).
- **Current text:** `KEY_PULSE_TAGGED <- "The pulse's own carbon atoms (tagged)"`
- **Status:** `DRAFT`.
- **Must agree with:** CHANGELOG 10-12 (j).
- **Gate:** `test-plot-text-fits.R:212` (3b).

### B3 — The title of the left partition panel

- **Where:** `app/R/plots.R:73` (used at `:1291`, `:1298`).
- **Current text:** `PANEL_PULSE_EXTRA  <- "The extra carbon"`
- **Status:** `DRAFT`.
- **Gate:** none found (grep of `tests/`).

### B4 — The title of the right partition panel

- **Where:** `app/R/plots.R:74` (used at `:1296`, `:1298`).
- **Current text:** `PANEL_PULSE_TAGGED <- "The pulse's own atoms"`
- **Status:** `DRAFT`.
- **Gate:** none found.

### B5 — The decay chart's caption when the tag is drawn

- **Where:** `app/R/plots.R:75–78` (used at `:1548`).
- **Current text:**
  ```r
  PULSE_TAG_DECAY_NOTE <- paste("The tagged atoms leave the air within years, because the air swaps",
                                "carbon with land and ocean every year. The extra CO₂ stays far",
                                "longer, because carbonate chemistry limits how much EXTRA carbon",
                                "the ocean can take up.")
  ```
- **Status:** `DRAFT`.
- **Must agree with:** CHANGELOG 10-12 (j): 19.8 % of the tagged atoms in the air at +20 yr, 9.7 % at +100 yr.
- **Gate:** none found. No caption-width test lists it.

### B6 — The partition caption's sentence for the right panel

- **Where:** `app/R/plots.R:79–80` (used at `:1308`).
- **Current text:**
  ```r
  PULSE_TAG_PARTITION_NOTE <- paste("Right: the same pulse, with its own carbon atoms tagged and",
                                    "followed wherever they go.")
  ```
- **Status:** `DRAFT`.
- **Gate:** none found.

### B7 — The "Left:" prefix on his `PULSE_PARTITION_NOTE`

- **Where:** `app/R/plots.R:1308`. His note is at `:81–84`.
- **Current text:**
  ```r
             if (!is.null(tag)) paste("Left:", PULSE_PARTITION_NOTE, PULSE_TAG_PARTITION_NOTE)
             else PULSE_PARTITION_NOTE,
  ```
  `PULSE_PARTITION_NOTE` (his, per handoff 10-12b §4) reads:
  ```r
  PULSE_PARTITION_NOTE <- paste("This is how much extra carbon each reservoir holds because of",
                                "the pulse — the difference between running with it and",
                                "without. It is not a trace of where those particular molecules",
                                "went, which is a different question with a different answer.")
  ```
- **Status:** `DRAFT` (the prefix only).
- **Gate:** `test-plot-text-fits.R:93`, "1. every caption fits the panel it is drawn in, at both widths". It measures `PULSE_PARTITION_NOTE` ALONE (`:101`). The combined "Left: … Right: …" caption that renders when the tag is drawn is not measured.

### B8 — FaIR's legend label in the pulse lab

- **Where:** `app/global.R:846` (applied at `:842`, with `pv$model` and `n_configs`).
- **Current text:** `APP_FAIR_PULSE_LAB_FMT <- "%s, %d-configuration mean (5–95 %% shaded)"`
- **Status:** `DRAFT`.
- **Must agree with:** the grid's provenance: `FaIR 2.2.4 (calib 1.6.0)`, 841 configs (`test-fair-pulse-grid.R:42–43`).
- **Gate:** `test-fair-pulse-grid.R:63`, "ON the grid FaIR is returned and labelled; …". `:66` requires the label to contain the model string, so the `%s` must stay.

### B9 — FaIR's off-grid message

- **Where:** `app/global.R:847–848` (applied at `:834` with size, first year, last year and step).
- **Current text:**
  ```r
  APP_FAIR_PULSE_OFFGRID_FMT <- paste("FaIR was run for a %g GtC pulse released in %d-%d, every %d years;",
                                      "set the pulse to one of those to compare.")
  ```
- **Status:** `DRAFT`.
- **Must agree with:** CHANGELOG 10-12 (k): 2030–2100 every 10 yr, 100 GtC.
- **Gate:** `test-fair-pulse-grid.R:63`. `:73` requires the literal `"FaIR was run for"`, so rewording that phrase fails the test.

### B10 — FaIR's on-grid note

- **Where:** `app/global.R:849–851` (rendered at `app/server.R:815`).
- **Current text:**
  ```r
  APP_FAIR_PULSE_NOTE <- paste("FaIR is shown for the same pulse on the same scenario. Before 2025 this",
                               "model follows the observed carbon budget and FaIR its own history, so the",
                               "two release the pulse into slightly different worlds.")
  ```
- **Status:** `DRAFT`.
- **Must agree with:** no note states the year. For reference:
  - the Scenarios-view note `APP_FAIR_NOTE` (`global.R:918`) says "Before 2024";
  - the splice year is computed: `APP_SPLICE_YEAR <- max(APP_EMIS_HIST$year)` (`global.R:758`).
  - ⭐ **Measured (main session, 2026-10-12): `APP_SPLICE_YEAR` evaluates to 2024**: observed budget through 2024, the scenario from 2025. So "Before 2025" here is exact, and `APP_FAIR_NOTE`'s "Before 2024" is a year early. Both years are TYPED, not derived from `APP_SPLICE_YEAR`, so a GCB update would leave both stale.
- **Gate:** `test-fair-pulse-grid.R:24–31` checks only that the constant exists.

### B11 — The section heading over both partition panels

- **Where:** `app/ui.R:487`.
- **Current text:** `h5("Where the extra carbon ends up"),`
- **Status:** `STALE`. It is his text (CHANGELOG 10-12 (j): "it is his"), and it now heads the tagged panel too. See F2 for the two notes' disagreement on its status.
- **Gate:** none found.

**Decision, not copy** (handoff 10-12b §4: "Confirm"): the FaIR box's default in the pulse lab. It is `checkboxInput("f_fair", "Compare with standard FaIR", value = FALSE)` at `app/ui.R:461`, shared with the Scenarios view.

---

## C. Review cards

The brief put the residual strip (C14) and the orphaned "The first is" (C15) in this group, so they are listed here.

### C1 — Cards 2 and 3: the ¹⁴C facts

- **Where:** no text exists. The cards are `app/R/review.R:538–555` (card 2) and `:556–575` (card 3).
- **Current text:** none on ¹⁴C.
- **Status:** `EMPTY`. It blocks nothing; the handoff calls it "where, and whether, to add" (10-11 §4).
- **Must agree with** CHANGELOG 10-11 (a), "Answered, not edited":
  - the post-1980 NH−SH Δ¹⁴C gradient matches Hua (−7.4 vs −8.1 ‰ in the 2010s), but the bomb era misses (gate 5 FAILS);
  - the air-sea Δ¹⁴C disequilibrium is neither fitted nor gated: 41 ‰ in the model vs about 52 ‰ observed (1997, 0–100 m);
  - the ocean's bomb-¹⁴C inventory overshoots: 83.8 vs 55.5 kmol in 1995. Handoff 10-11 §1 rounds these to "84 vs 56".
- **Gate:** none.

### C2 — Card 4's title and plain: "about 60%"

- **Where:** `app/R/review.R:577` (title) and `:583` (plain).
- **Current text:**
  - `title = "Year-to-year variability is about 60% of observed",`
  - `"wobble in CO₂ growth is only about 60% of the observed",`
- **Status:** `STALE`.
- **Must agree with** CHANGELOG 10-08 (g) ledger: 66 % (app estimator, 0.304 / 0.459); GATE V 0.854, PASS. "wording, Marcus".
- **Gate:** none. CHANGELOG 10-11 (c): "pinned or checked by NO test".

### C3 — Card 4's timing sentence (plain)

- **Where:** `app/R/review.R:589–591`. The comment at `:587–588` quotes `hilda33p`'s +1 month.
- **Current text:**
  ```r
                       "The timing of the CO₂ growth peak after an El Niño is too early,",
                       "peaking a month after the Pacific warmth index rather than five",
                       "months from the observed record."),
  ```
- **Status:** `STALE`.
- **Must agree with** CHANGELOG 10-08 (g) ledger: the growth peak after Niño 3.4 is model **5**, record 5. "the cut fixed the timing miss the card describes". Source: `outputs/diagnostics/card4_audit_20261008_hilda29e.log`.
- **Gate:** `tests/testthat/test-app-review-copy.R:144` (C4t, plain), in the test at `:179`, "all of Marcus's 2026-10-06 copy rulings are still applied". It REQUIRES `"peaking a month after the Pacific warmth index rather than five"` and forbids `"Its timing is a little early, too"`. The pin must change in the same commit as the copy.

### C4 — Card 4's range word: "a little below"

- **Where:**
  - the word: `app/R/review.R:304` (`RV_ENSO_L2_VS_OBS`);
  - the sentence: `:600–605`.
- **Current text:**
  - `RV_ENSO_L2_VS_OBS <- "below"`
  - the sentence:
    ```r
           detail = paste("The sensitivity is carried by a physical mechanism -- a",
                          "layer-3 upwelling anomaly driven by the Niño3.4 index,",
                          sprintf("whose fitted strength sits a little %s the range",
                                  RV_ENSO_L2_VS_OBS),
                          "observed for equatorial transport variability (the",
                          "numbers are under the second chart). It replaced a pair of",
    ```
- **Status:** `STALE`.
- **Must agree with** CHANGELOG 10-08 (g): 16.79 vs [14, 25], which is inside.
- **Gate:**
  - `tests/testthat/test-review-card-numbers.R:85`, in the test at `:79` ("card 4's 'a little <word> the range' …"). This is **one of card 4's two by-design failures.**
  - `:87` also requires the frame `"sits a little %s the range"`.
  - `test-app-review-copy.R` A4 (`:121`) requires `RV_ENSO_L2_VS_OBS` to stay present.

### C5 — Card 4's lag sentence: "2.5 months"

- **Where:** `app/R/review.R:631–633`.
- **Current text:**
  ```r
                        "\n\nFor the land uptake, the ENSO response is defined to occur",
                        "2.5 months after the index based on the vegetation model",
                        "response timing from the Global Carbon Budget.",
  ```
- **Status:** `STALE`.
- **Must agree with** CHANGELOG 10-08 (g): 5.93 ± 1.21 months (PINNED; profile 2σ 2.99–9.11); "2.84 sd" from 2.5.
- **Gate:**
  - `test-review-card-numbers.R:75`, in the test at `:63` ("card 4's lag is within ONE sd …"). This is **the other by-design failure.**
  - The typed values it checks are `RCN_CARD4_LAG <- 2.5` and `RCN_CARD4_LAG_TEXT <- "2.5 months after the index"` (`:36–37`). Their comment: "they change in the SAME commit as the copy".
  - `test-app-review-copy.R:145–146` (C4t, detail) REQUIRES `"2.5 months after the index based on the vegetation model"`.
  - CHANGELOG 10-11 (c): "Card 4's copy fix and that pin must land together."

### C6 — Card 4's Pinatubo figure

- **Where:** `app/R/review.R:619–625`.
- **Current text:**
  ```r
                        "and the interesting part is that it is not all for want of",
                        "a mechanism: the volcanic path IS here and running --",
                        "stratospheric aerosol scatters sunlight, the model's plants",
                        "use that diffuse light better, and switching the path off",
                        "moves CO₂ by about one and a half parts per million in",
                        "the years after Pinatubo. It is present and the total",
                        "wobble is still short.",
  ```
- **Status:** `STALE`.
- **Must agree with** CHANGELOG 10-08 (g): 1.01 ppm (monthly max), against 1.49 at `hilda29l`. "stale since `hilda33p`, not this adoption"; "wording, Marcus".
- **Gate:** `test-app-review-copy.R` N8 (`:79`) requires the word `"Pinatubo"` somewhere in the copy files. No numeric gate.

### C7 — Card 4's last sentence: estimator-dependent

- **Where:** `app/R/review.R:651–654`.
- **Current text:**
  ```r
                        "other way, so even that is not a rule. What the caption",
                        "above reports is the finding that survives: the model's",
                        "variability is more El Niño-driven than the real record's,",
                        "so the variance it lacks is of some other kind."),
  ```
- **Status:** `STALE`. The 10-08 (g) ledger calls it **"ESTIMATOR-DEPENDENT"**, not false.
- **Must agree with** CHANGELOG 10-08 (g): GATE V estimator, model 0.48 vs record 0.29; N7 estimator, model 0.19 vs record 0.30.
- **Gate:** none.

### C8 — Card 5a's caption: one source named, two drawn

- **Where:** `app/R/plots_review.R:273–276`.
- **Current text:**
  ```r
           caption = rv_cap(paste0(
             paste(sprintf("At %d yr: %.3f vs %.3f.", x$horizons, x$read, x$joos),
                   collapse = "  "),
             "  A comparison, not a test — nothing from this source scores the model."))) +
  ```
- **Status:** `STALE`. It is his copy (handoff 10-12 §4): "this source" is singular and the card now has two sources. Its numbers are computed live (CarboTope vs Joos) and name neither line; it prints no FaIR numbers (facts note §4).
- **Must agree with** `card5a_caption_facts_2026-10-12.md` §2:
  - this model 0.522 / 0.379 / 0.295;
  - Joos 0.596 / 0.409 / 0.322;
  - FaIR mean 0.483 / 0.364 / 0.291;
  - FaIR 5–95 %: 0.453–0.515 / 0.307–0.413 / 0.223–0.369;
  - above FaIR's p95 to 27.5 yr, inside it from 28.5 to 300 yr.
  - §1 gives the shared protocol of all three lines; §3 says what each line is. §3 flags as UNVERIFIED the claim that fair-calibrate draws its carbon-cycle parameters from CMIP6 emulations.
- **Gate:** none on the caption's words. `test-app-review-copy.R` N9 (`:80`; the copy files include `plots_review.R`) forbids the phrase `"not a gate. Nothing from this source"`.
- **Adjacent strings on the same panel** (see F4):
  - `lab_m <- "This model"; lab_j <- "Joos et al. 2013 multi-model mean"` (`plots_review.R:251`);
  - `RV_FAIR_LAB_FMT <- "%s, %d-configuration mean"` (`review.R:70`);
  - `RV_FAIR_BAND_FMT <- "%s, 5–95 %% of configurations"` (`review.R:73`).

### C9 — Card 5's title and text: "decays faster", true against Joos and the REVERSE against FaIR

- **Where:** `app/R/review.R:660–688`.
- **Current text** (verbatim; comment lines `:670–680` elided):
  ```r
         title = "A pulse of CO₂ decays faster here than in the multi-model mean",
         plain = paste("Release a pulse and this model keeps less of it in the air",
                       "at a century than the Joos et al. (2013) multi-model mean",
                       "does. The eventual split between land, ocean and air at a",
                       "thousand years is inside that study's range on every term."),
         detail = paste("This is a comparison and deliberately not a test: nothing",
                        "from that study is allowed to score this model, because a",
                        "long perturbation lifetime is supposed to emerge from the",
                        "seasonal and isotopic constraints rather than be fitted",
                        "to. Reporting the difference and not tuning it away is the",
                        # [comment lines 670–680 elided]
                        "point. Where the difference sits is visible in the two",
                        "charts: the pulse leaves the air faster here, most of all",
                        "in the first few decades, but after a thousand years the",
                        "split between land, ocean and air is close to the",
                        "multi-model mean on every term."),
         ask = paste("The app teaches how long CO₂ lasts. Is a lifetime shorter",
                     "than the multi-model mean -- with the shape inside its band --",
                     "acceptable to teach, or does it undercut the lesson?")),
  ```
- **Status:** `STALE`, per the facts note's flag. It is his approved text; every claim still holds against Joos (`f1e2427`; RE-CHECKED comment `:678–680`).
- **Must agree with** `card5a_caption_facts_2026-10-12.md` §4: "decays faster here than in the multi-model mean" is true against Joos, but "this model decays SLOWER than FaIR at every horizon" (§2: 0.522 / 0.379 / 0.295 vs FaIR 0.483 / 0.364 / 0.291). The 1000-yr split is 17.4 / 57.6 / 25.0 %, z +0.20 / −0.23 / −0.01 (CHANGELOG 10-12 (b)).
- **Gate:**
  - `test-app-review-copy.R` A5 (`:122`) REQUIRES `"split between land, ocean and air is close to the"` and forbids `"and the ocean a smaller one"`.
  - The card's class gloss (`RV_CLASS_GLOSS["comparison"]`, `review.R:51–53`, his N9 wording) is pinned by N9: `"long tail of carbon dioxide is robust"`.

### C10 — The card-5 code comments that quote `hilda33d` / `hilda29l` numbers

- **Where:** `app/R/review.R:672–677`. The 10-12 update that supersedes them is at `:678–680`.
- **Current text:**
  ```r
                        # and the ocean a smaller one" -- hilda29l's 1000-yr split
                        # (34 / 48 / 18 %). At hilda33d it is 18 / 60 / 22 against
                        # Joos's 16 / 59 / 25 (z +0.28 / +0.15 / -0.63 in true s.d. since the 10-02 +-2 s.d. fix; scorecard
                        # 2026-10-01): the ocean is now LARGER too, and every term
                        # sits within two-thirds of one s.d. (|z| <= 0.63). The difference is in
                        # the timing, largest early: IRF(20) 0.508 vs 0.596.
  ```
- **Status:** `STALE`. These are code comments and are never displayed.
- **Must agree with:**
  - `hilda29e`: IRF(20) **0.522** (facts note §2);
  - split **17.4 / 57.6 / 25.0 %**, z **+0.20 / −0.23 / −0.01** (CHANGELOG 10-12 (b); `review.R:679`).
- **Gate:** none (comments are stripped before the copy pins run).

### C11 — Card 8 ("ocean_climate"): title, plain, detail, ask

- **Where:** `app/R/review.R:773–793`. The draft marker is at `:770`.
- **Current text** (verbatim):
  ```r
    list(id = 8, key = "ocean_climate", class = "response",
         title = "The ocean loses uptake to warming about twice as strongly as ocean models do",
         plain = paste("Warmer seawater holds less CO₂, so as the sea surface warms the ocean",
                       "takes up less. In this model that loss is about twice what the ocean",
                       "models of the Global Carbon Budget show, and it appears decades earlier."),
         detail = paste("This is a comparison, not a test: those ocean models are models, not",
                        "measurements, and nothing from them scores this one. The seawater",
                        "chemistry is not the cause -- how fast CO₂ pressure rises with",
                        "temperature here matches the measured value. Our leading explanation,",
                        "tested but not settled, is that this model's ocean mixes vertically so",
                        "strongly that the surface keeps being refilled with carbon-rich water",
                        "from below, where real surface water would adjust and partly offset the",
                        "warming. Mixing less is not the fix: the same mixing is what the",
                        "radiocarbon and the ocean's carbon uptake require, and weakening it",
                        "shrinks the uptake and this effect together. The model also has no wind",
                        "effect, which in at least one ocean model is the largest part of the",
                        "climate effect. The second chart says what it is worth: how much lower",
                        "CO₂ would be in 2300 if this ocean responded like the ocean models."),
         ask = paste("Is an ocean that over-reacts to warming acceptable for teaching how",
                     "climate change weakens the carbon sinks, or should it be fixed before",
                     "the model is used to talk about the future?"))
  ```
- **Status:** `DRAFT` (CHANGELOG 10-08 (j): "The card text and the class gloss are CLAUDE'S DRAFT").
- **Must agree with** CHANGELOG 10-08 (j):
  - "about twice": 2 lies inside the 2015–24 ratio's GCB-1σ range (1.73–2.88) and inside the per-K ratio ± 1 se (1.81 ± 0.40);
  - "decades earlier": the lead is 27 years;
  - the chemistry: d ln pCO₂/dT is 0.039–0.046 /K vs Takahashi's 0.0423;
  - CO₂ lower in 2300: SSP5-8.5 −31.3, vvH −24.5, vvM −14.4 ppm.
- **Gate:**
  - `test-ocean-climate-card.R:36`, "2. the card's qualitative words follow from the product". It REQUIRES `"about twice"` in both title and plain, and `"decades earlier"` in plain.
  - `test-review-cards.R:40` and `:60` (non-empty fields; the ask contains "?").
- **Adjacent:** the two chart captions (`plots_review.R:341–347`, `:364–368`) and `RV_OCLIM_SCEN` (`plots_review.R:353`). See F4.

### C12 — Card 8's class gloss, `response`

- **Where:** `app/R/review.R:57–58`. The draft marker is at `:56`.
- **Current text:**
  ```r
    response   = paste("the process is in the model, but it reacts by the wrong amount, and",
                       "refitting the same model does not fix it."),
  ```
- **Status:** `DRAFT`.
- **Gate:** `test-review-cards.R:60` (every card's class must have a gloss).

### C13 — The constraint map's computed caption line (the El Niño module)

- **Where:** `app/global.R:678` (row text) and `:688–692` (the sentence). The draft marker is at `:677`. It renders at `app/server.R:1027`.
- **Current text:**
  ```r
  APP_CMAP_MODULE_ROW_TEXT <- c(gcb_ocean_enso_slope = "how strongly the ocean sink follows El Niño")
  ```
  ```r
    sprintf(paste(" Not on this map: the model's %s El Niño settings. They are fitted in a separate",
                  "step, to the month-to-month wobble in CO₂'s growth rate (%d–%d) and to %s, and",
                  "are held fixed while everything shown here is fitted."),
            nw, m$growth_window[1], m$growth_window[2],
            paste(APP_CMAP_MODULE_ROW_TEXT[m$rows], collapse = " and "))
  ```
- **Status:** `DRAFT`. Handoff 10-08 (b) §1 calls it "a computed caption line (Claude's draft)".
- **Must agree with:** CHANGELOG 10-08 (h) (Marcus: "Main fit only"); the module record in `data/constraint_map.rds`.
- **Gate:** `tests/testthat/test-constraint-map-panel.R:220`, "8. the map says the cut's El Nino settings are not on it …". It REQUIRES:
  - `"four El Niño settings"`;
  - the window rendered as `"%d–%d"`;
  - an error matching `"no plain-language text"` for an unknown row.

### C14 — The residual strip in the four-switch case (What-if tab)

- **Where:**
  - axis: `app/R/plots.R:966`;
  - caption: `:998–999`;
  - the numbers under the panel: `app/server.R:530–541`.
- **Current text:**
  - `LAB_GROWTH_RESID <- "Model − measured (ppm/yr)"`
  - the caption:
    ```r
             "Positive = the model grew faster than the measured record that year.",
             "Same years and same estimators as the panel above."))) +
    ```
  - the numbers:
    ```r
      txt <- sprintf(paste("Against the measured record over the same %d years:",
                           "the full model runs %+.2f ppm/yr on average (typical",
                           "miss %.2f), and its single worst year is %d at %+.2f."),
                     r$full$n, r$full$bias, r$full$rms, r$full$worst_year,
                     r$full$worst)
    ```
- **Status:** `EMPTY`. No text addresses the four-switch case. Optional (handoff 10-11 §4: "Optional: wording for the residual strip under the four-switch case").
- **Must agree with** CHANGELOG 10-11 (a):
  - with warming, ENSO, volcanic and emissions off, the model's growth is ~1e-12 ppm/yr, so "0.00 (100% less)" is arithmetically right;
  - the strip then shows model − measured = −(measured growth), which carries all of the record's own wobble.
- **Gate:** none.

### C15 — The pulse box's orphaned "The first is"

- **Where:** `app/server.R:951–954`.
- **Current text:**
  ```r
        p("Two things are worth separating here. The first is that the warming",
          "barely decays: a pulse of carbon emissions keeps warming the world for as",
          "long as this model runs, so on any human timescale the temperature",
          "resulting from a tonne of CO₂ is permanent."),
  ```
- **Status:** `STALE`. It is his text (10-11, verbatim). Its "second" went when his 10-11 paragraph replaced three old ones (handoff 10-11 §4).
- **Gate:** none on this paragraph. The next paragraph (`:965–973`) is pinned by `test-app-review-copy.R` A2 (`:115`), `"per 1000 GtC from any"`, and its numbers by `test-pulse-linearity.R`.

### C16 — Card 7's k_w line (found by the marker grep; on no handoff's open list)

- **Where:** `app/R/review.R:761–766`. The marker is at `:757`.
- **Current text:**
  ```r
                        "One fitted value is a compromise between two sources rather",
                        "than a measurement: the air-sea gas transfer speed comes out at",
                        "about 1,900 m per year, against the literature's 1,446 (Naegler",
                        "2009). The data slightly prefer the literature value; what holds",
                        "it higher is the stated prior on how much gas exchange the cold",
                        "high-latitude box gets, and the two cannot both hold."),
  ```
- **Status:** `DRAFT` (CHANGELOG 10-06 (j): "card 7's `k_w` line, DRAFTED for his review"). See F3.
- **Must agree with:** CHANGELOG 10-06 (j): 1894.7 ± 53.7 at `hilda33p`; the prior centre is 1,446. The test re-checks the fit at the current canonical.
- **Gate:** `test-review-card-numbers.R:90`, "card 7's k_w line …". It REQUIRES `"against the literature's 1,446"` and `"about 1,900 m per year"`, and the fitted k_w within one sd of 1900.

---

## D. Other app copy

### D1 — The What-if ENSO switch: "about a third"

- **Where:** `R/mechanisms.R:224–226` (repo-root `R/`, not `app/`). It sits in the `enso` mechanism's `caveat` (`:217–226`). The handoffs call it the "What-if blurb", but the string is the caveat; the blurb is `:197–201`.
- **Current text:**
  ```r
                     "In the model, even accounting for El Niño, temperature, and",
                     "aerosol light-diffusion effects, about a third of the wobble",
                     "remains, so there must be other sources of variability."),
  ```
- **Status:** `STALE`. It is his sentence (`mechanisms.R:211–212`: "the last sentence is his").
- **Must agree with** CHANGELOG 10-08 (g), `app_wobble_shares_20261008_hilda29e`: all three off leaves **29 %** (`hilda33p` 32 %). ENSO off removes 39 %, so the blurb's "about 40 %" holds.
- **Gate:** none. CHANGELOG 10-11 (c): "'about a third' [is] pinned or checked by NO test".

### D2 — The constraint map's seasonal "theory" paragraph

- **Where:** `app/server.R:1128–1135`. The marker is at `:1120`.
- **Current text:**
  ```r
          " A likely reason they disagree, given how this model is built: it makes its",
          " seasonal cycle from two channels that run in opposite directions — plants on",
          " land, which take up and release carbon with a strong ¹³C fingerprint, and the",
          " surface ocean, which gives off CO₂ as it warms in summer and carries almost no",
          " ¹³C fingerprint. The ocean channel shrinks the seasonal CO₂ swing without",
          " shrinking the δ¹³C swing in step, so the two tracers respond differently to",
          " the same seasonal settings — and with one seasonal setting per hemisphere,",
          " the fit can only split the difference."),
  ```
- **Status:** `DRAFT` (CHANGELOG 10-02 (w): "The seasonal 'theory' is MY DRAFT, for his wording."). See F3.
- **Must agree with:** CHANGELOG 10-02 (w): the mechanism measured 08-21 (`ccx_sst_seas_veto`). The code comment says that note's numbers are from an older mode, so no direction at this fit is claimed.
- **Gate:** none found.

### D3 — The scenario menu's parenthetical descriptors

- **Where:** `app/global.R:135–141`. The marker is at `:132–133`: "are drafts for Marcus's review".
- **Current text:**
  ```r
    "Very low (net zero by mid-century)"         = "vvVL",
    "Low-to-negative (cuts, then net removal)"   = "vvLN",
    "Low (net zero after mid-century)"           = "vvL",
    "Medium-to-low (net zero around 2100)"       = "vvML",
    "Medium (roughly flat to 2100)"              = "vvM",
    "High-to-low (rises, then deep cuts)"        = "vvHL",
    "High (rising to 2100)"                      = "vvH"
  ```
- **Status:** `DRAFT` (CHANGELOG 09-29 (c): "the parenthetical descriptors are drafts for Marcus"). See F3.
- **Must agree with:** per the comment at `:132–133`, each marker's NET CO₂ path (fossil + land use, 2025–2100) in `data-raw/build_vv_scenarios.R`'s product. No facts note.
- **Gate:** none found on the names. The names are display keys, used by `app_future_bands()` (`global.R:538–545`) through `names(APP_SCENARIOS)`.

### D4 — Parameter-table labels drafted on 10-01 and 10-02

- **Where:** `app/R/params_meta.R:122–129`. The markers are at `:114–115` and `:127`. `ndep_ret` at `:120` was ruled by Marcus (B4) and is not listed.
- **Current text:**
  ```r
    npp_tsens            = list(desc = "Plant growth's response to warming", unit = "per °C"),
    imb_share_land       = list(desc = "Share of the carbon budget's unexplained gap assigned to the land",
                                unit = "—"),
    imb_share_ocean_rest = list(desc = "Ocean's share of the gap the land does not take", unit = "—"),
  ```
  ```r
    lag_enso_land        = list(desc = "Delay between El Niño and the land's carbon response",
                                unit = "months"),
  ```
- **Status:** `DRAFT`. See F3.
- **Gate:** `test-app-params-table.R:39` and `:47`. Every parameter must have a non-empty description and unit; the wording is not pinned.

### D5 — The pulse box's first paragraph (marked "PLACEHOLDER FOR MARCUS")

- **Where:** `app/server.R:945–949`. The marker is at `:915–918`.
- **Current text:**
  ```r
      info_box("What this says about carbon and temperature",
        p(sprintf(paste("This %d GtC pulse warms the world by %.3f °C a century",
                        "later — %.2f °C per 1000 GtC — and by %s of its own peak",
                        "warming still at %d, %d years after release."),
                  pr$gtc, at(y100), per1000, fmt_pct(keep), yend, yend - pr$year)),
  ```
- **Status:** `DRAFT`. The marker says "THE PROSE IS A PLACEHOLDER FOR MARCUS". It predates his 10-11 edits to the box's other two paragraphs (C15 and `:965–973`). See F3.
- **Must agree with:** numbers computed live from the run.
- **Gate:** none found.

---

## E. Deploy blockers that are not copy

The source is `app/DEPLOY.md` (see F1), "BEFORE THE PUBLIC BETA GOES OUT", items 1–3 (`:34–53`), and memory `ccx_app_beta_blockers`.

### E1 — `APP_FEEDBACK_URL`

- **Where:** `app/global.R:116`.
- **Current text:** `APP_FEEDBACK_URL <- "SET-BEFORE-DEPLOY"`
- **Status:** `PLACEHOLDER`.
- **What it must be:** the Substack post the comments live under (`global.R:114–115`, Marcus 2026-09-22). DEPLOY.md item 1 (`:41–48`).
- **Guarded by:** `app_link_ok()` (`global.R:124–125`). Until it is set, the app renders:
  - `"The comment link is not set in this build. "` per card (`ui.R:91`);
  - `"This build has no comment link set. "` on the tab (`ui.R:526–527`);
  - `rv_card_url()` returns NULL (`review.R:875`).
- **Gate:**
  - `tests/testthat/test-review-cards.R:71`, "the feedback link is a placeholder until it is deliberately set". Its header reads "⚠ THIS TEST MUST BE UPDATED, NOT DELETED, WHEN THE URL IS SET".
  - `:93`, "every APP_*_URL in global.R is guarded by app_link_ok() in ui.R", which also needs ≥ 2 URL constants (`:96`).
  - `:100` (the mutation).

### E2 — `APP_REPO_URL`

- **Where:** `app/global.R:117`.
- **Current text:** `APP_REPO_URL     <- "SET-BEFORE-DEPLOY"`
- **Status:** `PLACEHOLDER`.
- **What it must be:**
  - `ui.R:689` comment: "the GitHub remote is private, so there is no public target until one is chosen".
  - Memory `ccx_app_beta_blockers`: making the repo public was declined (R3).
  - The "Source" paragraph it sits under (`ui.R:685–686`) says the repository holds the scripts and the decision log.
  - Until it is set: `"This build has no repository link set. "` (`ui.R:694`).
- **Gate:** `test-review-cards.R:93` and `:100`.

### E3 — Re-time start-up on an IDLE machine

- **Where:**
  - `app/DEPLOY.md:49` (item 2) and `:55–62`;
  - the copy that depends on the result: `APP_WARMUP_NOTE`, `app/global.R:105–107`:
    ```r
    APP_WARMUP_NOTE  <- paste("First load compiles the model and runs a 1750 spin-up:",
                              "allow up to three minutes. After that every panel is a",
                              "live model run, not a stored picture.")
    ```
- **Status:** `ACTION`.
- **Recorded so far** (DEPLOY.md `:57–59`): 73 s on an idle M4; 2.8 min under load; 148 s in the 09-22 contended check. Memory: not re-done 09-23/24 because of the load average. The 10-12b handoff §5 says the preview's first load takes "about 3 min before 'Listening'" (contended, not idle).
- **Gate:** none.

### E4 — The hosting plan's active-hours and concurrency limits

- **Where:** `app/DEPLOY.md:50–53` (item 3).
- **Status:** `ACTION`.
- **Related, already ruled** (DEPLOY.md `:22–29`, ruling R3): the URL is `carbotope.shinyapps.io/carbotope`, to be set at the FIRST deploy. Handoff 10-11 §1: that URL returned 404 (not deployed).
- **Gate:** none.

### E5 — DEPLOY.md's own text is stale against the code

- **Where:**
  - `app/DEPLOY.md:36`: "cut on mode `hilda33p` since 2026-10-06";
  - `:87` and `:99–100`: the `hilda33p` path `refit_20261005_hilda33p_obj16_hilda_csl3v0kaidgbem/mode_fit_pumpN.rds`;
  - `:67–69`: "the control mode's own spin-up and run" among the Known-issues runs.
- **What the code says now:**
  - `APP_RELEASE_MODE <- "hilda29e"` (`app/global.R:87`);
  - `CCX_MODE_CANONICAL <- "hilda29e"` with path `refit_20261008_hilda29e_obj18p2_hilda_csl3v0kaidgbemwt/…` (`R/paths.R:220`, `:238`);
  - the card that spun up a second mode was retired 2026-10-01 (`review.R:19–20`).
- **Status:** `STALE`. This is a doc, not app copy. DEPLOY.md itself says to take the path from `ccx_mode_file()`.
- **Gate:** `test-app-version.R` checks `APP_RELEASE_MODE`, not DEPLOY.md.

---

## F. Could not locate or could not resolve

**F1 — "`DEPLOY.md`" is not at the repo root.** The only copy is `app/DEPLOY.md`. Every DEPLOY.md reference above is to that file.

**F2 — The status of the section heading (B11): two sources disagree.**
- Handoff 10-12b §4 lists "the section heading 'Where the extra carbon ends up', which now sits over both panels" under "**Copy, all DRAFTS**".
- CHANGELOG 10-12 (j) says "The section heading … now sits over both panels; it is his."
- The handoff is the NEWER of the two: its CHANGELOG entry is (m), after (j). I listed B11 as his text needing review, and did not resolve which reading is meant.

**F3 — Draft and placeholder markers in code that are on NO handoff's open list (10-10, 10-11, 10-12, 10-12b):**
- D2 (10-02);
- D3 (09-29);
- D4 (10-01 / 10-02);
- D5 (09-25 / 09-26);
- C16 (10-06).

Whether Marcus has since accepted any of them is not recorded in the CHANGELOG entries I read: 09-26 (e), 09-29 (c), 10-02 (w) via 10-06 (j), and 10-11 (a). Searched: `CLAUDE'S DRAFT`, `DRAFTED`, `drafted`, `drafts for Marcus`, `PLACEHOLDER FOR MARCUS`, `for his review`. I listed them because the markers are still in the code; I did not establish that they are still open.

**F4 — Strings on panels he is rewording, with no draft marker and no recorded ruling.** Authorship and status could not be established:
- card 5a's legend labels (`plots_review.R:251`; `review.R:70`, `:73`);
- card 8's two chart captions (`plots_review.R:341–347`, `:364–368`) and `RV_OCLIM_SCEN` (`plots_review.R:353`). CHANGELOG 10-08 (j) marks the card text and gloss as drafts and is silent on the captions.

**F5 — Card 4: which sentence the handoffs call "the timing sentence".** The handoffs pair "card 4's stale timing sentence" with "its two by-design failures". The two failures are NOT the timing sentence:
- `test-review-card-numbers.R:75` is the 2.5-month LAG (C5);
- `:85` is the range word (C4).

The timing sentence (C3) is pinned only by `test-app-review-copy.R:144` (C4t), which currently PASSES. CHANGELOG 10-08 (g) and 10-11 (c) also list the title (C2), Pinatubo (C6) and the estimator-dependent last sentence (C7). All five are listed above.

**F6 — Open in handoff 10-12b §4, not copy, not itemised here:**
- the early-drawdown next step (`notes/early_drawdown_diagnosis_2026-10-12.md`);
- the tie spread resting on one pair of basins;
- FaIR's temperature response not drawn in the pulse lab;
- the nine held-era diagnostics (convert on touch).

Also not app text: the stale band strings in `calibration/lib_design_gates.R` listed in CHANGELOG 10-12 (n) under "Stale text left for Marcus". 10-12 (n) states "Neither string reaches the app or any log."

---

### Where a current string contradicts a facts-note or CHANGELOG number

| Item | Current text | Note says |
|---|---|---|
| A2 card 6 | "Running a real sampler is planned … no sampler has yet converged" | "A sampler HAS run"; R-hat max 1.046 (facts 10-09 F3) |
| A2 card 6 | "so the band would have been too wide" | ~2× is `hilda33d`'s; "Not re-measurable at `hilda29e`" (F1) |
| A3 | "no uncertainty ranges are shown" | the Futures tab will show a band (facts §C) |
| C2 | "about 60%" | 66 % (10-08 g) |
| C3 | "a month after … rather than five" | model 5, record 5 (10-08 g) |
| C4 | "a little below the range" | 16.79 vs [14, 25], inside (10-08 g) |
| C5 | "2.5 months" | 5.93 ± 1.21 (10-08 g) |
| C6 | "about one and a half parts per million" | 1.01 (10-08 g) |
| C9 | "decays faster here than in the multi-model mean" | true vs Joos; SLOWER than FaIR, 0.379 vs 0.364 at 100 yr (5a facts §4, §2) |
| C10 (comment) | "IRF(20) 0.508 vs 0.596"; "18 / 60 / 22" | 0.522; 17.4 / 57.6 / 25.0 (5a facts §2; 10-12 b) |
| D1 | "about a third" | 29 % (10-08 g) |
| B10 vs `APP_FAIR_NOTE` | "Before 2025" | `global.R:918` says "Before 2024". RESOLVED by measurement (see B10): splice year 2024, so "Before 2025" is exact and "Before 2024" is a year early |
