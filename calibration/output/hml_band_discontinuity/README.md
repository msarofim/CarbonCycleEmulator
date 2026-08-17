# `hml_band_discontinuity/` — the `h_ml` cliff, decomposed

Produced by `calibration/diag_hml_band_discontinuity.R` (2026-08-16g). ~4 min.
Full account: DESIGN.md §5.2k; CHANGELOG 2026-08-16g.

**THIS IS A DIAGNOSTIC, NOT A RESULT AND NOT A PROPOSAL.** `R/likelihood.R` is unchanged.
Handoff 16f §5.5's four options remain Marcus's decision; this directory exists so the
decision is made on the decomposition rather than on the total.

## Files

- `_run.log` — the full console output, including all four gates and the five scored predictions.
- `hml_band_discontinuity.rds` — `straddle` (the per-stream split at each band edge), `scan`
  (30 `h_ml` points), `variants` (shipped / rows-deleted / rows-always-live / 3 tapers),
  `sigma_rep` (DIC and δ¹³C representation error vs `h_ml`), `zs`, `predictions`, `constants`.

## What it establishes

1. The cliff is **exactly** "the three `ocean_grad_*` rows appeared", to 1e-12. `h_ml` = 85 is not
   a worse fit than 84.99; it is **scored on more data**.
2. A **taper removes the barrier and not the incentive** — argmax stays at 32 m under every ramp
   width, and under the hard skip, and with the rows deleted.
3. **The rows are not why `h_ml` leaves the band**: a 236 log-unit pull against a 10.0 log-unit
   cliff, and deleting the rows moves the argmax 32 → 32 m.
4. `σ_rep(h)` is **measured** and never exceeds ~1σ anywhere in `h_ml`'s prior support.

## Cautions

- Every number is at **init parameters with only `h_ml` varied**. The 236 log-units is an
  **UPPER BOUND** on the cost of bounding `h_ml` — `beta_max`, `kz` and `k_w` can reallocate some
  of it in a refit. Same caveat class as DESIGN §5.2g's pump margin.
- **Alkalinity's `σ_rep` is UNQUANTIFIED** — the GLODAP subset has no `talk` column.
- `h_ml` = 30 cannot be evaluated: it is the prior's bound, where `qlogis(0)` = −Inf. The argmax
  at 32 m means `h_ml` runs **into its bound**, not that 32 is an interior optimum.
- **P4 and P5 FAILED as predicted-vs-measured** and are recorded as failures. Neither bar was
  loosened; both failures point the same way (inflation is a stronger remedy, and the band is
  more disproportionate, than predicted).
