# DRAFT 2026-10-04 — Known-issues card 4: the ENSO TIMING miss — FOR MARCUS'S WORDING

**Ruling (Marcus, 2026-10-04): "No row; draft card-4 text (Recommended)".** No timing row and no objective change.
This note gives the facts and a candidate sentence. **The card's text in `app/R/review.R` is untouched until you word
it.** The precedent is 10-02 (v), where card 6's facts were drafted for your wording.

## The facts (each with its source)
1. **The model's CO₂ growth peaks about 1 month after the Niño 3.4 index; the measured record peaks about 5 months
   after.** The estimator is the centered 12-month difference of monthly global CO₂, spline-detrended, 1980–2024 (NOAA MBL).
   - Model at hilda34g: +1 (CHANGELOG 10-03 b; re-measured 10-04 i). Observed: +5, r 0.50 (10-02 x).
2. **The land's El Niño response is FITTED to arrive 2.64 ± 0.39 months after the index** (`lag_enso_land`, DESIGN's
   `L_MEI`, objective #15; adopted 10-03 h). The ocean's response is not lagged.
3. **What sets that lag** (10-02 dd, 10-03 g):
   - the Global Carbon Budget's land sink, which is the mean of an ensemble of vegetation models (DGVMs), so its
     El Niño timing is the models', not an observation;
   - the seasonal-cycle rows.
   The measured growth rate itself is in no row (declined 09-26).
4. **Weighting the measured growth rate by the year-to-year information it actually carries would move the lag only
   to about 3 months** (2.75–2.90; 10-04 i). Reaching 5 would mean trusting it 5–10× beyond that.
5. The miss is a TIMING miss, separate from the card's AMPLITUDE miss ("about 60 % of the observed wobble"). Fitting
   the lag moved the model's growth peak from 2 months BEFORE the index (hilda33d) to 1 month after it (observed: 5
   after), closing 3 of the 7 months, and did nothing for the amplitude.

## Candidate wording (yours to change)
**For `plain`, after its second sentence** (one sentence, undergraduate register):
> "Its timing is a little early, too: after an El Niño, the model's CO₂ growth peaks about a month after the Pacific
> warms, while the measured record peaks about five months after."

**For `detail`** (the advanced collapsible), one paragraph:
> "The land's response to El Niño is fitted to arrive about two and a half months after the index. What sets that is
> the Global Carbon Budget's land sink — itself an average of vegetation models — together with the seasonal cycle.
> The measured growth rate is not part of the fit, and giving it the weight its year-to-year information supports
> would move the land's response only to about three months."

## Once worded
- The sentence goes into card 4 (`app/R/review.R`, key "variance").
- `test-app-review-copy` gets a pin for the ruled words, as for "about 40 %".
- The numbers in the copy should be the rounded ones above, with these drivers as their re-measure sources at the
  next adoption:
  - the timing: `diag_obj15_refit_read.R` §6 / `diag_obj16_preview.R`;
  - the lag: the canonical's mode file.
