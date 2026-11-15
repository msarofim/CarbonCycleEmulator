# Group B: the drafts that need Marcus's approval before the bundle (2026-11-15)

**UPDATE 2026-11-15, his answers:** (1) "too long", and why would a model tuned to the growth record respond sooner?
The "sooner" reading is withdrawn; second draft below (§1b) states measured facts only; hypotheses and tests in the
handoff (`notes/handoff_2026-11-15_group_b_bundle.md` §3). (2) asked for pros and cons (handoff §3); lag 11 stays built
until he chooses. (3) "About two thirds": applied. (4) "Drop volcanic": applied. (5) B14 note approved.

## 1b. Card 4's last paragraph, second draft (in the code now; awaiting approval)

"We looked for a pattern in the misses. The model tends to grow faster than the record in El Niño years and slower in
La Niña years, and three of the five largest overshoots are 1991–1993, after Pinatubo. The misses show no trend. The
model's growth follows the ENSO index more closely than the measured growth does, and the variance it lacks is in the
part that does not follow ENSO."

(El Niño / La Niña years = the top / bottom quartile of the run's ENSO index: mean miss +0.30 ppm/yr, 10 of 12 positive /
−0.17, 9 of 12 negative. 1991–1993 fall in the El Niño quartile; without 1982–84 and 1991–93 the association is r +0.40,
p 0.012.)

---

Built at `fd10dfaa` + `bc7c691c` (CHANGELOG 2026-11-15 c, d). Everything below is in the code as drafted, so the suite
and the local app run with it; change any of it and the copy pins move with it.

## 1. Card 4's last paragraph (B19), re-measured on card 4a's new measure

Re-measured by `calibration/diag_card4_whatif_residuals.R` (output `outputs/diagnostics/card4_whatif_residuals_20261115_hilda31fl.log`;
the What if…? tab's measure, 1980–2024, n = 45). Two claims of the current text fail on this measure:

- The year-by-year miss (model anomaly minus record anomaly) **is** associated with the run's ENSO index of the same
  calendar year: r +0.48, p 0.001. It holds on ranks (+0.44), without the eruption years (+0.40) and in a block
  bootstrap (90 % interval +0.28 to +0.68).
- It is also associated with volcanic aerosol (r +0.41, p 0.005), but only through the eruption years: +0.06 without
  1982–84 and 1991–93; the bootstrap interval includes zero.
- The largest overshoot is 1992 (+0.62 ppm/yr), and 1991–1993 are three of the five largest (1991 is fifth, +0.48).
  1983, the year after El Chichón, misses the other way (−0.23).
- Still true: no trend (r 0.00), and every decade's average is under half of one year's scatter (largest 0.41).

**Current (live):** "We looked for a pattern in the misses and did not find one. Year by year, the difference between
the model's growth and the measured growth shows no usable association with the ENSO index, with volcanic aerosol, or
with the decade: over sixty-six years none of the three reaches significance, and the decade averages all sit well
inside one year's scatter. The single largest overshoot is 1991 — the model does not draw down as much carbon after
Pinatubo as the record does — but 1983, the year after El Chichón (the other big eruption), misses the other way, so even
that is not a rule. On the first chart's measure the model's variability is more ENSO-driven than the record's; on the
What-if tab's measure it is less — so we cannot say the missing variance is not El Niño-shaped."

**Draft (in the code now):** "We looked for a pattern in the misses. Over forty-five years, the year-by-year difference
between the model's growth and the measured growth is related to the ENSO index of the same calendar year, which suggests
the model responds to El Niño sooner than the measured growth does. It shows no trend, and the decade averages all sit
well inside one year's scatter. Three of the five largest overshoots are 1991–1993: the model does not draw down as much
carbon after Pinatubo as the record does. The model's growth follows the ENSO index more closely than the measured growth
does. The variance the model lacks is in the part that does not follow ENSO."

The last two sentences are your option (a). "Sooner" is an interpretation: the model's r with the index is already
+0.29 to +0.59 at 0–3 months' lead, where the record's is −0.15 to +0.19; both peak at 11 months.

## 2. Card 4a's caption: which ENSO lag it quotes

Built with the twelve months to each January (11 months' lead), where both series peak: r +0.73 (model) and +0.51
(record). The alternative is the calendar year (lag 0): +0.29 and −0.15. "More closely than" holds at every lag 0–18
(a test now checks all nineteen).

Caption as built: "Standard deviation: model 0.31 ppm per year, measured 0.46 (0.67×). The years (1980–2024) and the
detrending of the What if…? tab's growth chart. Against the ENSO index averaged over the twelve months to each January,
r is +0.73 for the model and +0.51 for the measurements (n = 45): the model's growth follows the ENSO index more closely
than the measured growth does."

## 3. Card 4's plain sentence

"…the total year-to-year wobble in CO₂ growth is only about 70–90% of the observed one, depending on the period and the
method." The chart under it now shows 67% (0.672); GATE V's measure gives 86%. Keep, or change to the chart's figure
(for example "about two thirds of the observed one")?

## 4. Card 4's ask (option a, as you chose it)

"And if the missing variability is not El Niño, volcanic or a trend, what would you look for next?" The re-measurement
finds misses after Pinatubo (item 1). Keep it, or drop "volcanic"?

## 5. The airborne-fraction note (B14, your addition)

Shown under the airborne-fraction chart whenever "Years shown" starts before 1900 (the default 1850–2024 shows it):
"The airborne fraction is poorly defined before the 20th century because human emissions were small."

## For information (built, no decision needed unless you object)

- **B2:** your sentence prints as written at the default settings. The warming's change between 100 and 250 years runs
  −6.4 % to +6.1 % across the Pulse lab's 168 settings (it falls in 120 of them; it rises at the default, +4 %) and the airborne
  carbon's −44 % to +6 %, so each clause follows the sign: for example "Between 100 and 200 years, the warming decreases
  a little (4%), whereas the airborne carbon concentrations rise 6%." "actually" stays only with "increases".
- **B4:** your sentence for El Niño (+0.2 ppm), volcanic (+0.2) and both ("These switches mostly impact…", +0.4). These
  are the only combinations of the 127 under 1 ppm; the next is −5.4 ppm.
- **Tests re-pinned to your group B wording** (your rule on test edits): six rows of `test-app-review-copy.R`
  (10-01 A2 "1,000 GtC"; 10-21 "a couple of exceptions" and its mutant, the FaIR checkbox without the period; 10-16 the
  partition caption and "residence time"; 10-06 "the ones it holds"). No other existing test was edited.
- **B18 #5** (the Pulse lab legend's missing ₂): no change. ragg on the laptop drops plotmath glyphs under about 8 screen
  pixels; the live app (DejaVu Sans on the host) draws the ₂ at the same size.
- **Corrected:** the sheet said the annual-mean airborne fraction changes by at most 1.1 points a year from 1755; the
  prototype's log says under 2 (largest 1.6, in 1863), under 0.5 from 1959.
- **B13** stays open.
