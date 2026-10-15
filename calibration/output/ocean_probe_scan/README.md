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

---

## RESULT — all six arms, 2026-08-24

| arm | logpost | `rep_dC` | Δσ | `luc_scale` Δσ | ridge Δσ |
|---|---|---|---|---|---|
| 0 (reference) | −1859.32 | 5.5658 | — | — | — |
| 2.5 | −1860.38 | 5.6042 | +0.16 | +0.52 | −0.14 / −0.19 |
| 9.434 | −1874.34 | 5.6447 | **+0.32** | +1.90 | −0.54 / −0.72 |
| 15 | −1895.97 | 5.6174 | +0.21 | **+2.94** | −0.84 / −1.12 |
| 9.434 **pinned** | −1868.5 | 5.6086 | +0.18 | pinned | +1.31 / +1.13 |
| 15 **pinned** | −1893.4 | 5.5252 | −0.17 | pinned | **+2.08 / +1.75** |

*(pinned logposts are NOT comparable to the free ones — the `luc_scale` prior was replaced.)*

**P1 HOLDS / P2 HOLDS / P3 FALSIFIED / P4 HOLDS / P5 HOLDS / P6 HOLDS.**

**THE RESULT: relieving the plateau decade does not relax `rep_dC`** — at any rate, free or
pinned. `|Δ| ≤ 0.32 σ` in all five live arms, and the sign is inconsistent. Against the `foss`
probe at the **same window-end CO₂ relief** and the same lever pinned: **−6.02 σ**
(5.566 → 4.102). The relief `foss` bought was payment for its **permanent level shift**, not for
explaining the plateau.

**RESIDUAL CONFOUND, stated because it is not resolved here:** `ocean` differs from `foss` in TWO
ways — temporal persistence AND isotopic signature — so this pair does not isolate which explains
the `rep_dC` difference. The mechanism argument favors persistence (`rep_dC` is a CO₂ *level*
offset; only persistence touches the level after 1960; `sigma_d14c` is a ¹⁴C error scale on other
streams) but that is an argument, not a measurement. **`ocean_deep` would discriminate directly** —
it has `foss`'s CO₂ trajectory and `ocean`'s isotopes.
