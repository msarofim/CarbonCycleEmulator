# prior_screen_20260901 — the prior screen at the 25-parameter mode

Produced by `calibration/diag_prior_screen_enso25.R` on 2026-09-01.
**ADOPTS NOTHING.** `CCX_MODE_CANONICAL` untouched; every mode read by path.

`prior_screen_enso25.log` is the full run. Inputs are the round-1 survey files
(`calibration/output/multistart_20260901_enso25/`, rsynced from
`/scratch/ms17839/` on 2026-09-01) and three ancestors already on disk.

The screen is priced on the RATIO as well as the z, because `SST_SEAS_LOGSD`
and `NPP_FRAC_NH_SD` are widths the code itself labels as JUDGEMENTS — a z
against a chosen width is partly a statement about the choice. Provenance is
derived from each prior closure, not hand-maintained.
