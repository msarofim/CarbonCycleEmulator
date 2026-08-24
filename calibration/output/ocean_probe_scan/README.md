# Ocean-probe rate scan — 2026-08-24. **SCRATCH. NEVER THE SHIPPED MODE.**

Four refits, arm N, `luc_scale` **FREE**, `CCX_SINK_MODE=ocean`, rates **0 / 2.5 / 9.434 / 15**
GtC/yr over 1942–49. Scoping `CCX_ARM_RESTARTS=8 CCX_ARM_CYCLES=2` — **identical to the two
2026-08-23 sink runs** (`pump_arms_SINK25*`), so the scan is like-for-like with them. Each dir was
seeded with a copy of the real `mode_fit_pumpN.rds` so the warm-start path runs exactly as
production does, and because `ARM_OUT()` derives from `ARM_OUTDIR` these runs cannot touch the
shipped file.

**Predictions are pre-registered** in `notes/prereg_2026-08-24b_ocean_probe_rate_scan.md`, written
before launch. Headline: **`rep_dC` will barely move** (< 0.5 σ at every rate), because it is a
common-mode level offset and this probe is 96.7 % gone by 2024.

**Warm-start logposts confirm four DISTINCT objectives**, and each matches the at-mode diagnostic
(`calibration/diag_sink_three_arms.R`) to the decimal:

| rate | warm-start logpost | vs rate 0 | at-mode diag predicted |
|---|---|---|---|
| 0 | −1859.3 | — | — |
| 2.5 | −1861.3 | −2.0 | −2.00 |
| 9.434 | −1887.3 | −28.0 | −27.99 |
| 15 | −1928.0 | −68.7 | −68.68 |

Run 4-way parallel with BLAS pinned to one thread each (`OMP_NUM_THREADS`,
`VECLIB_MAXIMUM_THREADS`, `OPENBLAS_NUM_THREADS` = 1); ~160 MB RSS per arm. ~6 h expected, from
the `pump_arms_SINK25` run's measured 367 min at the same scoping.
