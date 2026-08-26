# The pinned `luc` arm — 2026-08-24c. **SCRATCH. NEVER THE SHIPPED MODE.**

ONE refit. Arm N, `CCX_SINK_MODE=luc`, `CCX_SINK_RATE=2.5`, `luc_scale` **PINNED at 0.898400**,
`CCX_ARM_RESTARTS=8 CCX_ARM_CYCLES=2`, h_ml bounded [85, 120] — **every setting copied from the
pinned `foss` run** (`../pump_arms_SINK25_PINLUC/refit_sink25_pinluc.log`) so the two are
like-for-like down to the restart count.

**Predictions pre-registered before launch** in
`notes/prereg_2026-08-24c_luc_arm_persistence_vs_isotopes.md`. Headline: `rep_dC` falls by
**≤ −5.0 σ** (falsifier |Δ| < 1.0 σ), because `luc` carries `foss`'s persistence (0.501 vs 0.432 of
its window-end CO₂ effect left at 2024) with `ocean`-scale isotopes (Δ¹⁴C excursion 0.170 ‰ vs
`foss`'s 9.72). That is the cell `ocean_deep` was proposed to provide, already implemented.

**SEED-COPY TRAP (08-24b §6).** This directory was seeded with a copy of the real
`mode_fit_pumpN.rds` so the warm-start path runs as production does — so **that file exists before
the run starts and is the UNPERTURBED reference.** Completion keys on `pump_arms_comparison.rds`,
never on the presence of `mode_fit_pumpN.rds`.

**PROVENANCE GATE:** the warm-start logpost must be ≈ **−2691.2**. More than ~2 off ⇒ the arm on
disk is not the arm intended.
