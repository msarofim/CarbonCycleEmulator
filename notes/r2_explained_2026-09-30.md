# R2 explained: the `rep_dC` offset, what holds it up, and what each choice costs (φ = 0 numbers)

Marcus (09-29): *"I'd want to revisit R2 with a longer explanation."* This note is that explanation.
Nothing here changes the model or the objective. Every number comes from a file or measurement named
in the text.

## 1. What `rep_dC` is

- **Definition.** `rep_dC` is a fitted constant, in ppm. It is added to each hemisphere's model
  atmospheric CO₂ before that box is compared with the station records:
  - Mauna Loa for the NH box;
  - the South Pole for the SH box.
- **What it does not touch.** The ice-core CO₂ rows are scored against the bare box, with no offset.
- **Prior.** N(0, 1.0 ppm), where 1.0 is `LIK_CO2_REP_ERR`. That receipt is co-located instrument
  disagreement at one site, so it is not a measurement of this quantity (memory `ccx_rep_dc_prior`).
- **Fitted value.** 3.27 ppm at v0k (φ = 0; the ladder's canonical rung) and 3.52 at `hilda29l`
  (φ = 0.5).

**What it is meant to represent.** A background station does not see its hemisphere's mean air. The
measured offset against the NOAA marine-boundary-layer zonal reference (doi:10.15138/DVNP-F961) is:
- +0.74 ppm (NH mean − MLO);
- +0.81 ppm (SH mean − SPO);
- **0.776 ppm** on average (09-22 o).

So the offset's **sign and ordering are right**. Its **size is about 4× too large.**

## 2. What holds it at ~3.3 ppm

Not the station records. Forcing `rep_dC` down *improves* the MLO and SPO level rows. The offset is
held up by two other constraints (09-23 T1 / T2, at `hilda29l`):

- **The preindustrial ice-core anchor.**
  - Before the flask era, the model runs 1–4 ppm *below* the ice record.
  - In the flask era it runs ~5 ppm *above* the stations (the 08-23 era decomposition).
  - One trajectory cannot hit both, and `rep_dC` absorbs the modern half of the mismatch.
- **The bomb-¹⁴C ventilation rows** (`d14c_NH`, `d14c_SH`).

**The release test.** Priced at forcing `rep_dC` to the measured 0.776:
- removing the ice rows cuts the cost to **0.32×**;
- removing the bomb rows cuts it to **0.23×**.

The two holders are partially redundant, so their shares add to more than 100 %.

**Why this matters.** Forcing the offset down also moves gate D (the interhemispheric δ¹³C
asymmetry) and gate GL toward their observations. **The offset is absorbing real structural strain,
not mislabelled noise.**

## 3. The 09-23 ruling, for the record

**Prior unchanged; `rep_dC` stays one of the five named shims.** The fix it points to was the
interhemispheric deep exchange (IHDE), which was declined the same day as low-likelihood. So there is
no successor arc. That is the current state.

## 4. What changed since: φ = 0, and today's shelf

- **The 09-23 shelf expired.** It was a profile of the objective at `hilda29l`, so it lapsed when φ
  was set to 0.
- **Today's re-read** (`calibration/diag_rep_dc_shelf_v0k.R`) takes it from the φ = 0 ladder that
  already existed (09-29 k): 9 rungs, everything else re-optimised at each. It uses T4p's argument:
  a profile contains the answer for every prior on that parameter.
- **Checks:** GATE SHAPE passes (monotone and concave) and the REST identity is 0.

**The φ = 0 shelf** (`outputs/diagnostics/rep_dc_shelf_v0k_20260930.log`). Each cell is the fitted
`rep_dC`, with its likelihood cost against the fitted optimum:

| prior σ | centred 0 | centred on the measured 0.776 | centred −0.215 (mass-weighted) |
|---|---|---|---|
| 1.0 (shipped) | inert: stays 3.27 | inert | inert |
| 0.5 | 2.70 (−2.9) | 2.90 (−1.5) | 2.65 (−3.3) |
| 0.2 (Francey floor) | 1.22 (−27.4) | **1.74 (−16.0)** | 1.07 (−31.1) |
| hard pin at 0.776 | — | **0.776 (−39.8)** | — |

**Futures** (09-29 k, same ladder):
- `rep_dC` 3.27 → 1.0 moves SSP5-8.5 2300 CO₂ by **+63 ppm** and vvH by **+26 ppm**.
- At `hilda29l` the same move was **+271 ppm**. Most of that was the φ vegetation loop amplifying a
  fertilisation change. Setting φ = 0 removed that amplifier.

## 5. The new finding: R2 works through the fertilisation SHAPE, and the two are separable

Along the φ = 0 ladder, the present-day fertilisation enhancement (NPP gain at 410 ppm) stays at
**0.337–0.340 on every rung**, while the saturation constant K falls:

| `rep_dC` | 3.27 | 2.0 | 1.0 | 0.776 | 0.0 |
|---|---|---|---|---|---|
| K (ppm) | 865 | 763 | 666 | 644 | 570 |
| β_max | 2.55 | 2.27 | 2.03 | 1.97 | 1.78 |

So lowering `rep_dC` is, on the land side, a pure *shape* move. The historical amplitude is untouched,
and the curve saturates sooner. That shape change is what moves the future.

Today's fertilisation profile (CHANGELOG 09-30 d) moved K to 625 by itself, with `rep_dC` left free.
That cost only **−5.6**. So:

- **The −40 at the measured offset is almost all `rep_dC`'s own cost** (the ice anchor and the bomb
  rows), not the cost of the shape.
- **The shape can be decided on its own evidence.** That was item 1 (the K prior is already
  consistent with the science) and item 6 (the alignment screen).
- ⚠ **Hypothesis, not yet tested:** with K held fixed, `rep_dC`'s remaining leverage on the future is
  small. The test is `rep_dC` pinned at 0.776 with K pinned at its control value; one run.

## 6. The decision menu

| option | `rep_dC` | record cost | what it changes |
|---|---|---|---|
| (a) as ruled 09-23: N(0, 1) | 3.27 | 0 | nothing; stays a named shim |
| (b) re-centre on 0.776, σ 1.0 | 3.27 | 0 | nothing (inert) |
| (c) re-centre on 0.776, σ 0.2 | 1.74 | −16.0 | offset 2.2× the measured one instead of 4×; K ≈ 735 (from the ladder); a partial fertilisation-shape move |
| (d) hard pin at 0.776 | 0.776 | −39.8 | offset = measurement; K 644; SSP5-8.5 2300 about +60 ppm |
| (e) fix the structure (IHDE) | — | — | declined 09-23 |

**My reading, for you to rule on.** Because the future consequence of R2 runs through K, and K can be
set on its own evidence, R2 is once again mostly a question of how honestly the offset is labelled.
If you want the offset to look like the representation term it is named for, (c) is the defensible
version:
- σ 0.2 is Francey et al. 2019's floor for such a term;
- it is centred on the measured value;
- it costs −16.

(a) remains defensible as a named shim. Neither option fixes anything structural. The strain the
offset absorbs (the ice anchor against the modern level, and gate D's NH surface deficit) stays where
it is. Any change to the prior is an objective change, so it would also need a restamp at the next
refit.
