# CarboTope group B: decision sheet (2026-11-11)

Items B1–B21 of `notes/review_2026-11-11_minor_issues.md` §B. Nothing in the app has changed. Each row gives the current
text or behaviour (rendered, with real numbers, from the app code that is live: `64d91397`; HEAD `3b80ad57` has the
same `app/`, `R/`, `data/` and `src/`), the problem, the options, my recommendation and a blank for your choice.
Drafts follow your word-choice rules in `~/.claude/CLAUDE.md`; rewrite freely.

- Science numbers are measured at the canonical `hilda31fl` (mode file md5 `80c487f5…`) by committed drivers; each
  section names its driver and output.
- Screenshots are in `outputs/diagnostics/groupb_20261111/shots/` (headless Chrome at 1440 × 900, a 375 × 812 phone
  and a 768 × 1024 tablet; Chrome emulation, not a real device). The capture tool and its action lists are next to them.
- Prototypes for B14 ran in a throwaway worktree; the code is `outputs/diagnostics/groupb_20261111/proto_b14_worktree.diff`.

Order: science first (the card texts depend on it), then design, then wording, then B10.

---

## Science (B19–B21)

### B19. Card 4's last sentence: "on the What-if tab's measure it is less"

**Where:** `app/R/review.R:762-766` (detail) and `:767-770` (ask). Card 4a's chart caption computes its own word live
(`app/R/plots_review.R:226-233`) and is unaffected.

**Current:** "On the first chart's measure the model's variability is more ENSO-driven than the record's; on the
What-if tab's measure it is less — so we cannot say the missing variance is not El Niño-shaped." Ask: "And if the
missing variability is not clearly El Niño, not volcanic and not a trend — what would you look for next?"

**Measured** (`calibration/diag_card4_enso_estimators.R` → `outputs/diagnostics/card4_enso_estimators_20261111_hilda31fl.{log,rds}`;
model = the app's own historical run; index = observed Niño 3.4; 90 % interval from a paired moving-block bootstrap,
seed 20261111, two runs identical; Williams' t for two correlations sharing the index):

| estimator | years | lag 0 | lag 3 | lag 6 | lag 9 | r peaks at (model / record) |
|---|---|---|---|---|---|---|
| card 4a's chart (GATE V; GCB) | 1959–2024 | +0.48 vs +0.29, **clear** | +0.75 vs +0.49, clear | +0.79 vs +0.52, clear | +0.74 vs +0.50, clear | 5 / 5 months |
| the What-if tab as drawn (NOAA MBL, annual means differenced) | 1980–2024 | +0.29 vs −0.15, **clear** | +0.58 vs +0.19, clear | +0.67 vs +0.37, clear | +0.71 vs +0.47, clear | 11 / 11 months |
| the 10-15 reading (model annual means vs GCB Jan-to-Jan) | 1959–2024 | +0.18 vs +0.29, not clear (p 0.38) | +0.49 vs +0.48 | +0.59 vs +0.50 | +0.64 vs +0.48, clear | **11 / 5 months** |

(model r vs record r; "clear" = the 90 % interval of the difference excludes zero.)

- The 11-11 review's six numbers reproduce exactly on the second row, the series the What-if tab draws.
- The 10-15 "less" came from the third row. That reading pairs the model's annual-mean differences (centred near
  1 January) with GCB's January-to-January series (centred near 1 July). The model's correlation peaks 6 months later
  than the record's on that row for that reason alone. The app has avoided this pairing since 2026-09-26
  (`app_obs_growth()`'s header).
- On both like-for-like rows the model and the record peak at the same lag, and the model's r is higher at every lag.
- Where the missing variance sits (at the shared peak lag, as fractions of the record's variance):

| | model: ENSO-related | model: the rest | record: ENSO-related | record: the rest |
|---|---|---|---|---|
| card 4a's estimator (lag 5) | 0.47 | 0.28 | 0.27 | 0.73 |
| What-if estimator (lag 11) | 0.24 | 0.21 | 0.26 | 0.74 |

  The model's shortfall is in the part that does not follow the index (0.45 and 0.53 of the record's variance). Its
  ENSO-related part is equal to or larger than the record's. This is a linear split on one lagged annual index; an ENSO
  response that index cannot represent would count as "the rest".

**Options**
- (a) Draft: "On both charts' measures the model's growth follows the ENSO index more closely than the measured
  growth does. The variance the model lacks is in the part that does not follow ENSO." Ask: "And if the missing
  variability is not El Niño, volcanic or a trend, what would you look for next?"
- (b) Shorter: delete the sentence and keep the ask as is.
- (c) Leave as is (the sentence's second clause is not supported at this canonical).

**Recommendation:** (a). It restores the 09-22 finding (N7) on the estimator the app now uses. A test could hold it:
`test-review-card-numbers.R` would recompute r on both like-for-like estimators and fail if either reverses. Today
nothing checks this sentence.

**Decision:** ______

### B20. Card 3's "about 15%" and card 7's "The data prefer the literature value"

**Where:** card 3 `app/R/review.R:656-667`; card 7 `app/R/review.R:886-892`.

**Current, card 3:** "There is a related quantitative tension: the ocean bottles and the atmospheric δ¹³C decline
disagree by about 15% on how fast the air and sea exchange isotopes — the surface bottles want it slower, the
atmospheric δ¹³C decline holds it where it is — so a fix that satisfies one moves away from the other."

**Current, card 7:** "One fitted value is a compromise between two sources rather than a measurement: the air–sea gas
transfer speed comes out at about 1,840 m per year, against the literature's 1,446 (Naegler 2009). The data prefer the
literature value; what holds it higher is the stated prior on how much gas exchange the cold high-latitude box gets,
and the two cannot both hold."

**Card 3, measured** (`calibration/diag_card3_kw_diseq_scan.R` → `outputs/diagnostics/card3_kw_diseq_scan_20261111_hilda31fl.{log,rds}`;
`k_w` scaled ×0.70–1.30, everything else at the mode; gate D's disequilibria against the GLODAP bottles):

| disequilibrium (‰) | model at ×1 | bottles | `k_w` factor that meets the bottles |
|---|---|---|---|
| northern mixed layer | +1.061 | +1.278 ± 0.023 | ×0.78 (slower) |
| southern mixed layer | +0.936 | +1.055 ± 0.021 | ×0.87 (slower) |
| northern hemisphere average (card 3's chart) | +0.929 | +1.007 ± 0.022 | ×0.90 (slower) |
| southern hemisphere average (card 3's chart) | +0.836 | +0.721 ± 0.019 | ×1.19 (**faster**) |
| northern / southern cold high-latitude box | +0.035 / +0.160 | −0.481 / −1.062 | none in ×0.70–1.30 |
| north-minus-south asymmetry | +0.093 | +0.286 ± 0.029 | none (0.084–0.100 across the scan) |

- The two mixed-layer levels still want slower exchange, by 13–22 % (`hilda29l`'s 15 % was "both at ×0.85").
- The hemisphere averages, which card 3's chart draws, now pull opposite ways: the north wants slower, the south
  faster. The cold boxes miss by 0.5–1.2 ‰ at any exchange speed in the scan.
- With nothing else re-fitted, ×0.85 costs 618 log-likelihood: atmospheric Δ¹⁴C 391, atmospheric δ¹³C level 198,
  CO₂ 16. So the atmospheric Δ¹⁴C rows resist a slower exchange about twice as hard as the δ¹³C decline does.
  Re-fitted (the profile below), the picture changes.

**Card 7, measured:** PENDING. The `k_w` = 1446 price profile (the 10-13 recipe: two starts, the 30 other names
re-fitted) is running at `hilda31fl`; at `hilda31w` it gave the data's preference for 1,446 as +6.21 log-likelihood
(atmospheric Δ¹⁴C +7.09, δ¹³C −2.68) and `hs_asx_frac`'s prior as 88 % of what holds `k_w` higher.

**Options for card 3** (to settle once card 7's number is in)
- (a) Re-word to the current numbers: "There is a related tension: the surface-ocean bottles want the air–sea isotope
  exchange 13–22% slower in the warm surface layer than the atmospheric records allow, while the cold high-latitude
  water misses the bottles at any exchange speed."
- (b) Cut the sentence. Card 7 already carries the gas-exchange-speed story, and card 3's version now depends on which
  boxes are averaged.
- (c) Leave as is.

**Recommendation:** (b), unless the profile shows the atmospheric δ¹³C rows holding `k_w` once everything else is
re-fitted. At `hilda31w` they did not (−2.68 against +7.09 for Δ¹⁴C), which would put card 3's "the atmospheric δ¹³C
decline holds it where it is" in conflict with card 7's "the data prefer the literature value".

**Decision (card 3):** ______  **Decision (card 7):** ______

### B21. Card 7 vs What pins down what? on the seasonal SST amplitude

**Where:** card 7 `app/R/review.R:869-873`; the map paragraph `app/server.R:1272-1276` (its three names are computed).

**Current, card 7:** "The stand-ins that matter most for what this app claims are the station offset (issue 1), the
δ¹³C gradient offset (issue 2 is scored net of it), and a seasonal sea-surface-temperature amplitude fitted well under
the observed one."

**Current, What pins down what?:** "Some parameters have little influence on the model, and are not well constrained by
observations, such as “Southern sea-surface seasonal temperature swing”, “Northern sea-surface seasonal temperature
swing”, and “Share of bomb-test 14C released in the Northern Hemisphere”."

**Measured** (`calibration/diag_card7_sst_amp.R` → `outputs/diagnostics/card7_sst_amp_20261111_hilda31fl.{log,rds}`):
- Fitted half-amplitudes: north 1.50 K against ERSSTv5's 2.24 K (67 %); south 1.60 K against 1.75 K (91 %).
- On the map the two SST swings are the two least influential of the 25 model parameters (total leverage 1.11 and
  1.34; the next is 1.73, the largest 8.01).
- Moving both to the measured values, nothing else re-fitted: −12.9 log-likelihood (CO₂ seasonal rows −12.1). The
  seasonal cycle the Keeling tab draws changes by −3.6 % in the north (7.19 → 6.93 ppm peak to trough; Mauna Loa
  6.75) and −6.8 % in the south.
- Setting both to zero instead: −290 log-likelihood, and the southern cycle grows by 64 %.

So the SST cycle matters to the seasonal cycle, but the gap between the fitted and the measured amplitude moves what
the app shows by a few percent. The two texts measure different things and both are true. Card 7's "matter most" is
the claim the numbers do not support, and "fitted well under the observed one" holds for the north only.

**Options**
- (a) Take it off card 7's "matter most" list: "The stand-ins that matter most for what this app claims are the station
  offset (issue 1) and the δ¹³C gradient offset (issue 2 is scored net of it)." The table below still lists both SST
  swings.
- (b) Keep it with the measured size: "... and the northern seasonal sea-surface-temperature swing, fitted at about two
  thirds of the measured one, which changes the seasonal cycle on the Keeling tab by about 4%."
- (c) Leave as is.

**Recommendation:** (a). Neither offset's "matter most" was re-measured here; that half of the sentence is carried
as written.

**Decision:** ______

---

## Design (B12–B18)

### B12. Controls the Keeling and Where texts ignore

**Where:** `app/server.R:87` (Keeling takeaway), `:143` and the three readouts (Where), `app/R/plots.R:840`
(`plot_seasonal()`).

**Current:** with Years 2000–2024 and "Southern only" set, the Keeling takeaway still reads "At Mauna Loa, the model
produces 315 ppm in 1958, rising to 423 ppm in 2024; the measured value is about 425 ppm. …", and the seasonal chart
still draws Mauna Loa (`shots/b12_keeling_2000_2024_SH_viewport.png`, `shots/b12_b13_keeling_seasonal_SH.png`). With
Years 1900–1960 on the Where tab the readouts still give 317 / 234 / 224 GtC, which are 1750–2024 totals
(`shots/b12_where_1900_1960_viewport.png`). The seasonal chart's window is fixed at 2000–2024
(`APP_SEAS_WINDOW`).

**Options**
- (a) Make all three follow the controls: the takeaway names the chosen station and years; the readouts give the
  window's carbon; the seasonal chart draws the South Pole for "Southern only" and both stations for "Both".
- (b) Keep the takeaway and readouts fixed and say so in their labels (for example "Since 1750, to 2024" above the
  readouts); make only the seasonal chart follow the hemisphere and the measurements checkbox.
- (c) Leave as is.

**Recommendation:** (b). The readouts are cumulative stocks, so "the carbon of 1900–1960" would be a different
quantity (emitted in the window, and where it went) and needs its own wording. The South Pole cycle is small and
reversed in phase, which is worth a student seeing.

**Decision:** ______

### B13. The seasonal chart's "Measured" curve is a fitted wave

**Where:** `app/R/plots.R:840-865`.

**Current:** both curves are the mean one-harmonic fit (sine + cosine per year, averaged over 2000–2024); the
measured one is labelled "Measured, Mauna Loa" (`shots/b12_b13_keeling_seasonal_SH.png`). It is what the
calibration scores.

**Options**
- (a) Relabel: "Measured, Mauna Loa (one annual wave fitted to each year)" and a caption sentence: "Both curves are
  the average of a single annual wave fitted to each year, 2000–2024, the form the calibration scores."
- (b) Draw the measured monthly means (detrended the same way) as twelve points over the model's curve, which shows the
  real shape including what one wave leaves out.
- (c) Leave as is.

**Recommendation:** (a) now; (b) is the better chart but needs a model curve on the same footing (monthly means too)
to stay like-for-like.

**Decision:** ______

### B14. Airborne fraction before about 1900

**Where:** `app/R/plots.R:934-950` (`plot_airborne_fraction()`), on the Where tab.

**Current:** the monthly ratio of the two cumulative stocks, from the first month with more than 1 GtC emitted. The
airborne carbon's seasonal swing (about 5 GtC within each year) over a small denominator draws a solid band: the
ratio swings 484 points within 1754, 64 in 1780, 13 in 1850, 5 in 1900 and 0.7 in 2024. At 1750–1900 the axis runs
−100 % to 300 % (`shots/b14_now_af_1750_1900.png`; default view `shots/b14_now_af_1750_2024.png`). The dashed 50 %
line is drawn but nearly invisible (grey75, 0.3 wide). Measured by `outputs/diagnostics/groupb_20261111/proto_b14.R`
(log in `proto/`).

**Options** (prototypes in the real app, `shots/b14_proto{A,B,C}_af_*.png`)
- (A) Annual means, starting where the monthly swing stays below 5 points (1908; 10 points would be 1864, 2 points
  1966). A window ending before 1908 shows a note instead of a chart (`b14_protoA_af_1750_1900.png`).
- (B) Monthly ratio from 1959, GCB's first year. Still shows a ±1-point seasonal sawtooth (`b14_protoB_af_1750_2024.png`).
- (C) Annual means from the start. Averaging removes the band entirely: the annual-mean ratio changes by at most
  1.1 points from one year to the next from 1755 on, and by under 0.5 points from 1959. It falls from 62 % in 1755 to
  36 % by 1850: the air holds more of an emission that is still young (`b14_protoC_af_1750_2024.png`,
  `_1750_1900.png`, `_1850_2024.png`).

**Recommendation:** (C), with the 50 % line darkened. It needs no threshold, and every window draws a chart. If you
would rather not show the 18th-century decline, (A) at a threshold you choose.

**Decision:** ______ (threshold, if A: ______)

### B15. The residual strip's years

**Where:** `app/R/plots.R:1510-1512` (caption); `app/server.R:595-605` (comment).

**Current:** the strip runs 1980–2024 (the measured record) under a growth chart that runs 1850–2024 at the default
window. Its caption ends "Same years and same estimators as the panel above."
(`shots/b15_growth_and_resid_viewport.png`). The code comment above it says the strip "SHARES THE GROWTH CHART'S x
LIMITS"; it shares the window's measured years, not the x limits.

**Options**
- (a) Caption from the window: "Positive = the model grew faster than the measured record that year. The years with
  measurements (1980–2024), on the same estimators as the panel above."
- (b) Also give the strip the growth chart's x limits, so a year sits under the same year. At the default window that
  squeezes the 45 measured years into the right quarter of the strip.

**Recommendation:** (a), and correct the code comment.

**Decision:** ______

### B16. Phone: "Run it" sits below the chart it fills

**Where:** `app/ui.R:666` (`s_go`), `:677` (`p_go`); the phone layout puts the lead (takeaway and chart) before the
controls below 576 px.

**Current (375 × 812):** in Build your own the takeaway is at y 202, the chart 249–649, the button at y 956. After
"Run it" the screen shows the button and the bottom of the chart; the new takeaway is 508 px above the top of the
screen (`shots/b16_phone_build_before_run_viewport.png`, `shots/b16_phone_build_after_run_viewport.png`).

**Options**
- (a) On narrow screens, scroll to the takeaway once the new chart has drawn (`shots/b16_proto_scroll_to_takeaway_viewport.png`
  is that end state).
- (b) Put the Futures controls above the chart on phones (the other tabs keep lead-first).
- (c) A small "Run it" bar fixed to the bottom of the screen in those two modes.

**Recommendation:** (a). It keeps one phone layout for every tab; the scroll fires only on the button's click, below
576 px.

**Decision:** ______

### B17. Portrait tablet (768 px): a 168 px sidebar

**Where:** `sidebarPanel(width = 3)` on each tab (`app/ui.R:372`, `:422`, `:512`, `:587`, `:642`, `:827`), i.e.
`col-sm-3` from 576 px up.

**Current:** from 576 px up the sidebar keeps a quarter of the row: 168 px wide at 768, slider 134 px, so the
two handles of "Years shown" touch and the labels merge ("1958 — 2024"), the scenario dropdown wraps to three lines
over its arrow, and "Build your own" wraps one word per line (`shots/b17_tablet768_keeling_top_viewport.png`,
`shots/b17_tablet768_pulse_top_viewport.png`).

**Options**
- (a) Below 992 px, give the sidebar the full width, under the lead, as on phones; keep the wide navbar.
- (b) Widen the sidebar to 5/12 between 768 and 991 px.
- (c) Leave as is (portrait tablets are a small share of readers).

**Recommendation:** (a). It reuses the phone arrangement, which the phone-layout tests already cover.

**Decision:** ______

### B18. Cosmetic layout

| # | Current | Proposed | Decision |
|---|---|---|---|
| 1 | The yellow banner is inset from the content on both sides (desktop: banner ≈ 26–1414 px, content 12–1428; `shots/b12_keeling_2000_2024_SH_viewport.png`; phone `shots/b18_phone_keeling_top_viewport.png`) | Same left and right edges as the content | ___ |
| 2 | Phone: the three Where readouts sit at different heights (air at y 399, land and ocean at 420; "Taken up by land" wraps to two lines) (`shots/b18_phone_where_readouts_viewport.png`) | Labels on one line ("In the air", "In land", "In the ocean") or the numbers aligned to a common baseline | ___ |
| 3 | Phone: "view" of "Copy link to this view" wraps onto its own line (two line boxes, 34 px tall) | Keep the link on one line (`white-space: nowrap`), moving it to its own line when it does not fit | ___ |
| 4 | Tap targets: Download links 15 px tall, slider handles 22 × 22 px | 32 px minimum height on touch screens (padding, no visual change on desktop) | ___ |
| 5 | New: at 768 px the Pulse lab legend prints "The extra CO" with the subscript ₂ missing (`shots/b17_tablet768_pulse_top_viewport.png`) | Find which fitting step drops it (phone-layout refit or the legend key) | ___ |

**Recommendation:** all five; 5 is a defect, the others are polish.

---

## Wording (B1–B9, B11)

Drafts only. The current text is quoted as rendered.

### B1. What pins down what? takeaway (your 10-02 sentence)

**Where:** `app/server.R:1156-1159`.
**Current:** "The metrics most sensitive to changes in this model are δ13C level & gradient — led by …; CO2 level — led
by …; Δ14C in the air (bomb) — mostly influenced by …. A metric low on the chart is one this model could change a
good deal without results changing substantially."
**Problem:** the second sentence reads as the reverse of what is meant, and "metric" is the tab's "measurement".
**Draft:** "The measurements most sensitive to changes in this model are … . A measurement low on the chart changes
little even when the model's parameters change a good deal."
**Decision:** ______

### B2. Pulse lab, temperature view: "keeps 104%"

**Where:** `app/server.R:916-921`.
**Current:** "Release 100 GtC in 2050 and the world is 0.14 °C warmer a century later, and 0.14 °C warmer after 250
years. Over that stretch the warming keeps 104% of its century-later value and the airborne carbon keeps 82%, so the
warming is the longer-lived of the two."
**Draft:** "… By then the warming is at 104% of its century-later value and the airborne carbon at 82%, so the warming
is the longer-lived of the two."
**Decision:** ______

### B3. What if…? with nothing ticked

**Where:** `app/server.R:456-459`.
**Current:** "Nothing is switched off, so the charts show the full model against the measurements. Tick one or more
boxes to remove a mechanism; tick several to remove them together."
**Problem:** the first chart (CO₂ level) has no measurements; only the growth chart does.
**Draft:** "Nothing is switched off, so the charts show the full model, and the growth-rate chart compares it with the
measurements. Tick one or more boxes to remove a mechanism; tick several to remove them together."
**Decision:** ______

### B4. What if…? takeaway for year-to-year switches (changed since the review)

**Where:** `app/server.R:692-732`.
**Current:** the review saw "…is unchanged to the nearest ppm — these are year-to-year mechanisms, and they move the
wobble rather than the level" (plural for one switch). Since batch A's A2 ("print the difference of the rounded
values") that sentence is no longer reached by El Niño or volcanic aerosols. They now print:
"With El Niño / La Niña switched off, global-average CO2 in 2024 would be 426 ppm instead of 425 — a difference of
+1 ppm." The unrounded change is +0.16 ppm (volcanic +0.22, both +0.38): the full model sits at 425.43, next to a
rounding boundary. `outputs/diagnostics/groupb_20261111/groupb_numbers.log`.
**Problem:** a 0.16 ppm change printed as 1 ppm; the explanatory sentence is unreachable; the grammar issue remains
for when it is reached.
**Options**
- (a) When the unrounded change is under 1 ppm, print it to one decimal and explain: "With El Niño / La Niña switched
  off, global-average CO₂ in 2024 changes by +0.2 ppm. This switch acts year to year: it moves the wobble rather than
  the level, and the growth-rate chart below is where it shows up." (Plural form for several switches.) Larger changes
  keep A2's sentence.
- (b) Keep A2's rule and fix only the grammar.
**Recommendation:** (a). It keeps A2's property (the printed difference equals the printed numbers) wherever levels are
printed.
**Decision:** ______

### B5. Forest regrowth: −1.22 beside "1.22 GtC absorbed/year"

**Where:** readouts `app/server.R:317-336`; takeaway `:367-404`.
**Current:** readouts "Deforestation, gross 2.51 / Forest regrowth −1.22 / Net, the land-use input the model is given
1.29 / GtC per year, 2015–2024 average"; takeaway "…in the last decade it has compensated for 49% (1.22 GtC
absorbed/year versus 2.51 GtC emitted/year)."
**Draft:** keep the readouts' signs (they make 2.51 − 1.22 = 1.29 visible) and extend the unit line: "GtC per year,
2015–2024 average; negative values are taken out of the air."
**Decision:** ______

### B6. Pulse lab: "Runs the model twice"

**Where:** `app/ui.R:681-682`. `app_pulse_runs()` (`app/global.R:714-747`) makes three runs: without the pulse, with
it, and with its carbon tagged.
**Current:** "Runs the model twice, with and without the pulse, from identical starting conditions, and takes the
difference. The difference is what the extra carbon does."
**Draft:** "Runs the model with and without the pulse, from identical starting conditions, and takes the difference:
that is what the extra carbon does. A third run tags the pulse's carbon atoms to follow where they go."
**Decision:** ______

### B7. Under the hood, "Parameters"

**Where:** `app/ui.R:906-913`.
**Current:** "These are the numbers the calibration fits, and the few it holds at a stated value. Everything else —
ocean area, the mass of the atmosphere, carbonate chemistry constants — is fixed from measurements and cited in the
repository. The El Niño settings are fitted in a separate step and then held. A value held at 0 is a mechanism that is
in the code but switched off."
**Facts (the table, 45 rows):** 31 fitted, 14 held. Of the 14: four are fitted in the separate step (the El Niño land
response, north and south, its delay, and the El Niño upwelling limb); seven are held at 0 (ventilation loop and its
ENSO modulation, overturning, southern seasonal entrainment, the two ENSO ocean sensitivities, plant growth's
response to warming); three are held at other values (equatorial upwelling cell 27 Sv, its ENSO modulation 1,
biological pump 9.08 GtC/yr). Eight of the 14 have "ENSO" in their names; four of those eight are the ones fitted in
the separate step, and the other four are held at 0 or 1.
**Draft:** "These are the numbers the calibration fits (31) and the ones it holds at a stated value (14). Everything
else, such as ocean area, the mass of the atmosphere and carbonate chemistry constants, is fixed from measurements and
cited in the repository. Four held values, the El Niño land response and its delay and the El Niño upwelling limb, are
fitted in a separate step to the year-to-year record. A value held at 0 is a mechanism that is in the code but switched
off. The equatorial upwelling cell, its El Niño modulation and the biological pump are held at fixed values." (The
counts would be computed from the table.)
**Decision:** ______

### B8. Pulse partition takeaway: "in this box", "residence lifetime" (your 10-16 text)

**Where:** `app/R/plots.R:167-174` (`PULSE_DEPTH_TAKEAWAY`).
**Current:** "…The left panel shows how much excess carbon stays in each reservoir (the rate of decline in the
atmosphere in this box informs the “perturbation lifetime”). The right panel shows where the individual carbon atoms
from the pulse end up (the rate of decline in the atmosphere in this box informs the “residence lifetime”). …"
**Problem:** "box" means a reservoir elsewhere in the app; "residence lifetime" mixes two terms.
**Draft:** "box" → "panel" (twice); "residence lifetime" → "residence time".
**Decision:** ______

### B9. Small items

| # | Where | Current | Draft | Decision |
|---|---|---|---|---|
| 1 | Keeling takeaway, `app/server.R:117` | "with a couple exceptions" | "with a couple of exceptions" | ___ |
| 2 | Card 4, `app/R/review.R:764` | "the What-if tab's measure" | "the What if…? tab's measure" (moot if B19 (a) is taken) | ___ |
| 3 | Card 7's table, `app/R/review.R:110`, `:113` | "the same, southern hemisphere" | "the same, Southern Hemisphere" (as the chart legends) | ___ |
| 4 | Futures, `app/server.R:1040`, `:1065` | "1.36 °C per 1000 GtC", "about 1.4 °C per 1000 GtC" | "1,000 GtC" (the app's form elsewhere, e.g. "about 1,840 m") | ___ |
| 5 | Under the hood drivers table, `app/server.R:1426` | "IGCC" | "Indicators of Global Climate Change (IGCC)" | ___ |
| 6 | Card 8 caption, `app/R/plots_review.R` (`rv_plot_oclim`) | "-0.43 GtC/yr here (-0.38 to -0.49 across the ten ocean-model setups), -0.20 ± 0.05" | low to high and true minus signs: "−0.43 GtC/yr here (−0.49 to −0.38 across …), −0.20 ± 0.05" (`shots/b9_card8_oclim.png`) | ___ |
| 7 | Pulse partition caption, `app/R/plots.R:1826`, `:186` | "Left: This is how much extra carbon each reservoir holds because of the pulse. Right: the same pulse, with its carbon atoms tagged." | "Left: how much extra carbon each reservoir holds because of the pulse. Right: the same pulse, with its carbon atoms tagged." | ___ |
| 8 | FaIR checkbox (Scenarios), `app/global.R:1245` | "Compare with FaIR, a widely used climate emulator." | drop the final period (the Pulse lab label has none) | ___ |
| 9 | Landing page `docs/index.html:25-31` (title, my wording) vs `:102` (your lead) | "a carbon-cycle model built for students" vs "a new simple carbon cycle model" | title and descriptions follow your lead: "carbon cycle model" | ___ |
| 10 | "air-sea" vs "air–sea" | not found in the rendered text at `64d91397` (only "air–sea"); chart images not searched | none | ___ |

### B11. Panels with a heading and no takeaway

| Panel | Where | Draft (numbers computed live, as the other takeaways) | Decision |
|---|---|---|---|
| Airborne fraction | `app/ui.R:469` | "About 41% of all the carbon emitted since 1750 is still in the air. Since 1850 that share has stayed between 32% and 41%." (annual means; 2024 40.9 %, lowest 32.1 % in 1863) | ___ |
| Does the model agree with the measured budget? | `app/ui.R:470-471` | "Over 2015–2024 the model's ocean takes up 3.12 GtC a year and the Global Carbon Budget's 3.22; the model's land takes up 3.03 and the budget's 2.36." | ___ |
| Δ¹⁴C: the bomb spike and how fast it drained away | `app/ui.R:628` | No new text: move the tab takeaway's second sentence ("Δ14C tells a different story: …") under this heading, so each chart has its own | ___ |

Numbers: `outputs/diagnostics/groupb_20261111/groupb_numbers.log`. The airborne-fraction range depends on B14's
choice (it uses annual means, option C's series).

---

## B10. Unit glosses (ready to apply; same mechanism and wording as the existing notes)

| Tab | Missing | Change |
|---|---|---|
| Isotope fingerprints | The takeaway prints "2.34‰"; the ‰ gloss is inside the collapsed "What the two isotopes tell you" box (`app/ui.R:615`) | A visible one-line note in the sidebar: "Isotope ratios are given in ‰." with `gloss("‰", "per mil: parts per thousand")` (a `unit_note_permil()` beside `unit_note_ppm()`) |
| Futures, Build your own | The takeaway prints "10.5 GtC a year"; only the Pulse lab pill has `unit_note_gtc()` (`app/ui.R:683`) | `unit_note_gtc()` in the Build your own pill |
| What if…? | The driver chart for "Our emissions" is in GtC; the sidebar has only the ppm note (`app/ui.R:527`) | `unit_note_gtc()` under `unit_note_ppm()` |
| Under the hood | The parameter table shows ppm and ‰; only the GtC note is there (`app/ui.R:902`) | `unit_note_ppm()` and `unit_note_permil()` beside it |

**Decision:** ______ (apply all / some / none)

---

## Provenance

- Science drivers committed at `68ea6221`; outputs at `3b80ad57` (logs stamp `68ea6221`, clean).
- Capture tool `outputs/diagnostics/groupb_20261111/cdp_shoot.py` and its action lists; B14 prototype script and
  worktree diff in the same folder; `groupb_numbers.R` for B4 and B11.
- Card 7's `k_w` profile: frozen worktree `~/ccx_frozen/20261111_kw1446_profile_hilda31fl` at `6c6cc9fd`, launch script
  `~/ccx_frozen/20261111_kw1446_profile_hilda31fl_launch.sh`, both starts passed the canonical's reproduction gate
  (diff 0).
