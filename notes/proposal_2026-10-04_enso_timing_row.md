# PROPOSAL 2026-10-04 — a GROWTH-SHAPE row for the land ENSO timing (objective #16 candidate)

> **⛔ RULED 2026-10-04 (Marcus): "No row; draft card-4 text (Recommended)".** The row is NOT built. The card-4 sentence
> is drafted for his wording in `notes/draft_2026-10-04_card4_enso_timing.md`. This note stands as the record of why.

> **Status.** Drafted on Marcus's ruling "Draft a timing-row proposal" (2026-10-04; the 10-04 handoff's item 2).
> - Nothing is built and no objective is changed.
> - The numbers come from `calibration/diag_obj16_preview.R` (`outputs/diagnostics/obj16_preview_20261004.{log,rds}`) and
>   the 10-04 (e) run. Both are CONDITIONAL slices at hilda34g, with 26 names held; a refit gives the joint answer.

## 1. The problem, in numbers
- hilda34g's land ENSO lag is **2.64 ± 0.39 months** (10-03 g). The rows that set it are:
  - `gcb_land_sink` (+6.45 of the lag's +14.92), which is GCB's S_LAND, a DGVM ensemble: model-derived timing;
  - the SPO seasonal rows (+4.43), which see ENSO only where an anomaly projects onto a year's fit (10-02 dd).
- The atmosphere's own timing is in **no row**. Observed global CO₂ growth peaks **5 months** after Niño 3.4 (r 0.50,
  10-02 x); the model's peaks **1 month** after.
- At a lag of 5 months, with the 8-name land block re-optimized (10-04 e, D):
  - the existing rows lose **12.2** log-units;
  - the growth peak moves to +4 months, and the detrended correlation with the observed growth rises 0.57 → 0.67;
  - SSP5-8.5 2300 moves +7 ppm.
- Why it matters, by the 09-03 standard ("pedagogical, not an emulator"): the app teaches ENSO's effect on the growth
  rate, and "non-physical ENSO … behavior is problematic" for a teaching model. The timing miss is VISIBLE: it is a miss,
  not a cancellation.

## 2. Is this the NEW reason the 09-26 ruling asked for?
The 09-26 ruling: do not re-propose the growth row without a new reason (memory `ccx_growth_objective_declined`). Its
premise, a big 1991 residual, dissolved when the estimators were matched. What is new since then:
- **the model has a FITTED lag** (10-02 aa, adopted 10-03 h), and the observation that measures timing most directly is
  in no row;
- the rows that do set the lag include a **model product** (DGVM S_LAND), whose ENSO timing is the DGVMs', not an
  observation.

That is a reason that did not exist on 09-26. Whether it is ENOUGH is the ruling.

## 3. The three 09-26 objections, and how the design answers each
1. **"Near-redundant; it over-determines an open system"** (growth = emissions − sinks, and GCB's budget does not close).
   - The row scores the SHAPE of the detrended growth, with its amplitude profiled out.
   - So it carries no level and no budget identity. The two GCB sink rows and the imbalance allocation are untouched.
2. **"Very loud"** (the CO₂ stream already outvotes the partition 40:1).
   - The row's weight is the MEASURED effective sample size of the detrended series (§4), not the 540 monthly points.
   - The preview (§5) prices each weight before anything is built.
3. **"It fights a known shortfall"** (the interannual AMPLITUDE, GATE V 0.59×).
   - The amplitude is a free slope inside the row, so the fit cannot buy the row by inflating the wobble.
   - GATE V stays a separate, visible FAIL.

## 4. The statistic
- **Definition:** regress the observed detrended growth on the model's, with a free slope and a free variance. The
  row is that regression's profile log-likelihood, **−(n_eff / 2) · log(1 − r₊²)**:
  - r = the correlation of the two detrended series, and r₊ = max(r, 0), so a wrong-signed model earns nothing;
  - the growth is the centered 12-month difference of the monthly global CO₂, 1980–2024, detrended by a natural spline,
    df 5. That is the 10-02 x / refit-read §6 estimator, which the What-if diagnosis already uses.
- **The observation:** NOAA's MBL global reference (manifest key `mbl_zonal_gl`, already downloaded).
  - A MONTHLY processed product is needed. `data/mbl_global_growth.rds` is annual (the app's 09-26 estimator); a monthly
    one would come from `data-raw/build_mbl_global_growth.R`, per the data-provenance rule.
- **n_eff** (Bretherton et al. 1999, J. Climate 12:1990, eq. 31; n (1 − r1x·r1y) / (1 + r1x·r1y)), measured at hilda34g:
  - **monthly 22.7 of 540 points** (lag-1 autocorrelation 0.990 model, 0.929 observed);
  - annual 44.8 of 45.
- **The annual alternative:** the app's own estimator, differences of annual means against `data/mbl_global_growth.rds`.
  - It is like-for-like with the What-if readout and has twice the n_eff.
  - It blurs the sub-annual timing that the lag is about.
- **Alternatives rejected:**
  - the lag of the peak cross-correlation (a discrete argmax, not smooth for the optimizer);
  - the full growth row (all three objections, as declined).
  - The cross-spectral phase in the ENSO band is a smooth, timing-only option. It needs more machinery and has no
    precedent here; it can be built if the shape row is ruled out.

## 5. What the row would do (the preview; conditional, land block re-optimized WITHOUT the row)
**The lag profile** at hilda34g's base, the 8-name land block re-optimized at each lag. L = 0 / 2.644 / 5 come from the
10-04 (e) run, where two starts agreed; the rest are this run's.

| lag (months) | 0 | 1 | 2 | **2.644** | 3 | 4 | 5 | 6 | 8 |
|---|---|---|---|---|---|---|---|---|---|
| Δ likelihood of the existing rows | −14.60 | −5.87 | −0.77 | **0** | −0.59 | −5.09 | −12.23 | −19.86 | −30.79 |
| model growth peak after Niño 3.4 (observed +5) | −2 | −1 | +1 | +1 | +2 | +3 | +4 | +6 | +8 |
| r, detrended growth vs observed: monthly | 0.425 | 0.475 | 0.534 | 0.573 | 0.594 | 0.644 | **0.671** | 0.671 | 0.615 |
| r: annual (the app's estimator) | 0.536 | 0.565 | 0.601 | 0.628 | 0.644 | 0.687 | 0.718 | **0.723** | 0.671 |
| `npp_tsens` (/K) | −0.0066 | +0.0011 | +0.0068 | +0.0089 | +0.0094 | +0.0087 | +0.0056 | +0.0015 | −0.0065 |
| SSP5-8.5 2300 (ppm) | 1476 | 1462 | 1452 | 1449 | 1448 | 1450 | 1456 | 1463 | 1479 |

- The slope gate failed at L = 1, 6 and 8 (single starts; the gate is curvature-blind off the base, memory
  `whitened_slope_gate_blind_off_base`). Read those three as points on a smooth profile, not certified optima.

**Where the row would put the lag** (the lag maximizing the existing rows + the row, on a spline through the profile):

| estimator | weight | lag | existing rows lose | row gains | SSP5-8.5 2300 |
|---|---|---|---|---|---|
| monthly | **1 × n_eff = 22.7** | **2.75** | 0.10 | 0.12 | 1448 |
| monthly | 2 × = 45.4 | 2.95 | 0.46 | 0.71 | 1448 |
| monthly | 5 × = 113.5 | 3.75 | 3.64 | 6.40 | 1449 |
| monthly | 10 × = 226.9 | 4.55 | 8.82 | 20.25 | 1453 |
| annual | **1 × n_eff = 44.8** | **2.90** | 0.35 | 0.54 | 1448 |
| annual | 2 × = 89.6 | 3.55 | 2.62 | 4.04 | 1448 |
| annual | 5 × = 224.1 | 4.85 | 11.07 | 23.83 | 1455 |
| annual | 10 × = 448.1 | 5.25 | 14.19 | 52.36 | 1457 |

**What it says.**
- **At its measured weight, the row moves the lag by only 0.1–0.26 months** (to 2.75 monthly, 2.90 annual).
  - That costs the existing rows 0.10–0.35, and the futures do not move.
  - The existing rows' preference for ~2.6 months (−12.2 at 5) outweighs the growth shape's independent information.
- **The observed 5 months needs ~5× the annual n_eff, or more than 10× the monthly one.** That is objection 2 in
  another form: it treats the growth record as several times more informative than its autocorrelation allows.
- The futures are insensitive to the lag between 2.6 and 4 months (1448–1450 ppm).

## 6. Recommendation, and what needs ruling
**My recommendation: do not build the row; record the timing miss as a named tension, with a sentence in Known-issues
card 4 for your wording.**
- At an honest weight the row buys ~0.2 months and nothing else, for the full cost of an objective change and a refit.
- At a weight that reaches the observation, it is the loud row the 09-26 ruling declined.
- The deeper question is why the rows that set the lag prefer ~2.6 months. GCB's S_LAND is a DGVM product, and the
  DGVMs' own ENSO timing is not an observation. That is a research question, not an objective change.

If you would rather build it anyway:
1. **Build it at all?** Or record the timing miss as a named tension, with a sentence in Known-issues card 4 for your
   wording. That changes no objective.
2. **The estimator:** monthly (timing resolution, n_eff ~23) or annual (the app's, n_eff ~45).
3. **The weight:** the measured n_eff, or a stated multiple of it. A multiple needs its own reason, because it is
   objection 2 in another form.
4. **Packaging:** together with the greening-prior decision (`notes/proposal_2026-10-04_npp_tsens_prior.md`) as ONE
   objective #16 and one refit. Priced first on every registered mode, then restamped, as at #14 and #15 (D1).

## 7. Cost, if built
- The monthly product (a data-raw step).
- The row in `R/likelihood.R`, with tests: absent = bit-identical, mutation tests, and a row-reproduction gate.
- Pricing and restamping every registered mode; the test ledger.
- A 24-start refit, about 11 h on the Mac or ~7 h on Torch with you submitting.
- Adoption: the scorecard, the constraint map, the app's re-measured copy.
