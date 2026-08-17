# `alk_sigma_rep/` — alkalinity's representation error, the input 16g could not measure

Produced by `calibration/diag_alk_sigma_rep.R` (2026-08-17). ~30 s.
Full account: CHANGELOG 2026-08-17; DESIGN.md §5.2k (the σ-inflation paragraph).

**THIS IS A DIAGNOSTIC, NOT A RESULT AND NOT A PROPOSAL.** `R/likelihood.R` is unchanged, the
band is still `LIK_OCEAN_GRAD_HML_OK = c(85, 120)`, and **σ-inflation is still unimplemented and
still Marcus's call** (handoff 2026-08-16g §2.4, open item 4). This directory only supplies the
third of the three numbers that decision needs.

## Why it exists

16g §2.4 priced σ-inflation against the shipped hard skip using measured `σ_rep(h_ml)` for the DIC
and δ¹³C gradient rows, and recorded a blocker for the third:

> "Alkalinity's `σ_rep` is UNQUANTIFIED — the GLODAP subset carries no `talk` column, so it would
> need a new download or a stated assumption."

**The stated reason is wrong, and no new download was needed.** The subset 16g's part 4 reads
(`glodap_c13c14_subset.csv`) has no `talk`, but the shipped ALK target was never built from that
file: `data-raw/build_glodap_deep_targets.R:324` reads `glodap_dic_talk_subset.csv` — 464,590
QC-passed bottles, already on disk — precisely because, in the build script's own words,
alkalinity is measured on far more bottles than the isotope cruises carry. Part 4 pointed at one
file while the target came from another; that, and nothing else, is why the row was unquantified.

## Files

- `_run.log` — full console output: three gates, the `h_ml` scan, the summary table, three scored
  predictions.
- `alk_sigma_rep.rds` — `alk` (the per-`h_ml` table: `like_for_like`, `sigma_rep`, `ratio`),
  `dic_alkpop` (DIC on the **same** population, the Q3 shape comparator), `gate_gaps`,
  `shipped_alk`, `predictions`.

## What it establishes

1. **ALK's `σ_rep` is measurable from local data**, and the recipe reproduces **both** shipped
   targets from this file's own cells to **0.00e+00** (`talk` 78.5927; `tco2_alkpop` 225.8087)
   before any `h_ml` moves — so what is measured is the shipped target's own representation error,
   not a near-miss recipe's.
2. **The alkalinity row is the best-behaved of the three**, not a hidden risk:

   | row | in band | all `h_ml` | source |
   |---|---|---|---|
   | DIC | 0.04–0.34 | 0.04–0.87 | 16g part 4 |
   | δ¹³C | 0.01–0.55 | 0.01–1.11 | 16g part 4 |
   | **ALK** | **0.02–0.07** | **0.02–0.34** | **this file** |

   At the quarantined mode's `h_ml` = 184 the ALK mismatch is **0.17 σ**; in band it never exceeds
   **0.07 σ**.
3. It **strengthens 16g §2.4's finding rather than qualifying it**: the band switches all three rows
   off together, and the row whose representation error was feared unknown turns out to carry the
   *smallest* one. Every row's mismatch is sub-1σ across `h_ml`'s whole prior support.

## Cautions

- **The comparison table's DIC/δ¹³C rows are read from
  `../hml_band_discontinuity/hml_band_discontinuity.rds`**, not transcribed. If that file is absent
  the diagnostic omits those rows rather than quoting prose.
- **`dic_alkpop` is NOT the shipped DIC row.** It is DIC measured on the alkalinity population, which
  the build script keeps separate on purpose (`tco2_alkpop`, "reported for the ratio; NOT a term").
  Its gradient differs from the shipped isotope-population DIC target. Do not quote it as the DIC row.
- **This file does not price inflation against the skip.** That needs the model's own gradient at each
  `h_ml` (16g part 4b), and 16g's 21 % figure is unchanged by anything here. This is the
  observation-side quantity only.
- **`σ_rep` at `h_ml` = 100 is not zero** (~0.37 μmol/kg at the nearest scanned point, 102). Gate G3
  asserts the model's surface box at 100 m *is* the shipped 0–100 m layer, so the residual there is
  the closed-vs-open edge convention alone — that is the floor of the curve, not a depth mismatch.
