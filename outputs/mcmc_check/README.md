# MCMC check, stage 1 (CHANGELOG 2026-10-01 q – 2026-10-02 u)

These are the chains of the MCMC check on the held Laplace band, as stage 1 left them. Marcus ruled 10-02 (u), "Stop
here; keep holding", so no stage 2 was run and the app stays band-free.

- **`chain_{1..4}.rds`.** Written by `calibration/run_mcmc_check.R` at `c631e50` on Torch (job 18969240, `cs`), stopped by
  its own 8 h wall.
  - Settings: n 1e5, adapt 3e4, thin 20, ckpt 500, seeds 20261002–05. Each file's `$provenance` records the seed, where
    it is applied, the host, the commit and the settings.
  - **PARTIAL:** 56,000 / 50,500 / 60,000 / 53,500 iterations.
  - The identical files remain on Torch at `/scratch/ms17839/CarbonCycleEmulator/outputs/mcmc_check/`, where the
    stage-2 command (handoff 2026-10-01f §2.5) would resume them exactly.
- **`pooled_u.rds`.** The draws `calibration/read_mcmc_check.R` pooled over the common window (30000, 50500]: 4 × 1,025, in u-space,
  chain by chain. Its md5 `f64f461164b19c8b5616846e42794db5` is the one the band artifact
  `outputs/diagnostics/futures_ribbons_mcmc_stage1_20261002.rds` records.
- **`read_20261002_drop0.log`, `diag_20261002_drop0.csv`.** The reader's report: R-hat, ESS, the lp blocks, and the
  posterior against the Laplace.

**The finding** (10-02 s, t):
- The chains are unconverged on `beta_max` (R-hat 1.21, ESS 14).
- Measured in ppm, the band is ~half the held Laplace band's width (CO₂ 0.41×, GMST 0.58×).
- The four chains agree on it to ≤ 3.4 ppm / 0.014 °C (`calibration/diag_mcmc_band_by_chain.R`).
