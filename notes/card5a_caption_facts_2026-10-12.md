# Card 5a caption — the facts, for Marcus's wording (2026-10-12)

Marcus, 2026-10-12: "Write the facts note (Recommended)". **No caption prose here.** The wording is his.
Every number is at `hilda29e` (the canonical), on the PD100 protocol with the climate FREE.

## 1. What the panel draws (`app/R/plots_review.R` `rv_plot_irf`, `app/R/review.R` `rv_pulse`)

| line | source | how it is released | time axis |
|---|---|---|---|
| This model (solid) | `ccx_pd100()`, R/joos_irf.R | 100 GtC added to the atmosphere state at 2015.0, at its own isotope ratios (`ccx_pulse_state`) | t = year − 2015 |
| Joos et al. 2013 multi-model mean (solid) | Joos 2013 **Table 5** fit, `JOOS_T5` | the fit's function, not a run | as published |
| FaIR 2.2.4 (calib 1.6.0), 841-configuration mean (dashed) | `data/fair_pd100.rds`, from FaIRtoFrEDI `run_fair_pd100_for_ccx.py` `964aa12` (pushed 10-12) | 100 GtC spread uniformly over 2015 | t = timebound − 2015.5 (ruled "mid-release") |

**The shared protocol** (Joos 2013 Table 1 runs 1–3), now true of all three lines:
- the history to 2010;
- CO₂ then held by diagnosed emissions, with non-CO₂ and land-use forcing held;
- 100 GtC added in 2015;
- climate free.

⚠ Until 10-12, CarboTope's line held temperature at 2010 (0.509 / 0.361 / 0.271). That made it the only line on the card on a different protocol.

## 2. The numbers the caption could use

| | 20 yr | 100 yr | 300 yr |
|---|---|---|---|
| This model | **0.522** | **0.379** | **0.295** |
| Joos 2013 multi-model mean (Table 5 fit) | 0.596 | 0.409 | 0.322 |
| FaIR, 841-config mean | 0.483 | 0.364 | 0.291 |
| FaIR, 5th–95th percentile across configs | 0.453–0.515 | 0.307–0.413 | 0.223–0.369 |

- **Ordering, at all three horizons:** Joos > this model > FaIR mean.
  - The model–FaIR gap shrinks with time: +0.039, +0.015, +0.004.
  - The Joos–model gap shrinks too: −0.074, −0.030, −0.027.
- **Against FaIR's spread:** this model is ABOVE FaIR's 95th percentile from the release to 27.5 yr (0.522 vs 0.515 at 20 yr), and INSIDE it from 28.5 yr to 300 yr. Year-by-year comparison: scratch run 2026-10-12, `rv_pulse()` against the file's `irf_p05` / `irf_p95`.
- **Time-integrated IRF against Joos Table 4's 5–95 % range, the spread across the complex models** (yr):

| TH | this model | FaIR mean (p05–p95) | Joos best | Joos 5–95 % |
|---|---|---|---|---|
| 20 | 12.85 | **11.83** (11.41–12.28) | 14.2 | 12.2–16.3 |
| 50 | 26.85 | 24.91 (23.47–26.39) | 30.3 | 24.0–36.6 |
| 100 | 46.95 | 44.06 (40.26–47.64) | 52.4 | 39.5–65.2 |

- This model's values are from `outputs/diagnostics/joos_irf_canonical_20261012.log` §3.
- FaIR's are my integration of `data/fair_pd100.rds`: a trapezoid with IRF(0) = 1 prepended.
  - The release convention moves TH20 by about ±0.26 yr.
  - ⚠ **FaIR's mean TH20 (11.83) is BELOW Joos's 5 % floor (12.2) under any of the three axis conventions** (start-, mid- or end-of-release). This model is inside Joos's range at all three horizons.

## 3. What each line IS (for any claim the caption makes about it)

- **FaIR's IRF shape is Joos's.** Its partition fractions and lifetimes ARE Joos 2013 Table 5, so it differs from Joos only through its time-scale factor α (0.283 at the release, the config mean; CHANGELOG 10-12 b).
  - Its 5–95 % spread is FaIR's posterior on its carbon-cycle and climate parameters, not the spread of complex models.
  - That is why it is narrow early (±0.03 at 20 yr).
  - I believe fair-calibrate draws FaIR's carbon-cycle parameters from emulations of CMIP6 Earth-system models. **This is unverified**, so check the fair-calibrate documentation / Smith et al. before the caption says it.
- **Joos's curve** is a fit to the multi-model mean. The model spread is published as Table 4's integrated-IRF ranges; there is no per-year band in this repo.
- **This model's line** is the central parameter set only: no posterior band is computed for the pulse.

## 4. The present caption, checked

The caption is assembled in `rv_plot_irf`:
- *"At 20 yr: 0.522 vs 0.596. At 100 yr: 0.379 vs 0.409. At 300 yr: 0.295 vs 0.322."* TRUE, but it names neither line, and FaIR's numbers are absent.
- *"A comparison, not a test — nothing from this source scores the model."* TRUE for both sources: no objective reads a Joos or FaIR quantity (10-12 b audit). But *"this source"* is singular, and the card now carries two.
- The card's typed text (`review.R` card 5: "decays faster here than in the multi-model mean"; "inside that study's range on every term") still holds (`f1e2427`).
  - ⚠ "decays faster here than in the multi-model mean" is true against Joos. **Against FaIR it is the other way round:** this model decays SLOWER than FaIR at every horizon.
