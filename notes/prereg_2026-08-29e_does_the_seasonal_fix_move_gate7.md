# PREREG 2026-08-29e — **DOES THE SEASONAL FIX MOVE GATE 7?**
# Marcus's "cheap test first". Written and committed BEFORE the driver. **No gate may move.**

**State:** `main` at `855bfa5`, clean. Nothing running.

## 0. THE HYPOTHESIS, AND WHY IT LOOKED PROMISING

Gate 7 says the land sink is **3.56 vs GCB 2.410 ± 0.50 = +2.30 σ**, i.e. ~1.15 GtC/yr too much
uptake. The seasonal arm says SH soil respiration wants to be **3.4× larger** (`seas_T_amp_SH`
1.0391 → 3.4945 when the geometry allows it, 08-29d). More respiration ⇒ less net uptake. **If one
change fixes both, two defects collapse into one.**

## 1. ⚠ THE DIRECT PATH IS A STRUCTURALLY GUARANTEED NULL — READ THE CODE BEFORE THE RESULT

`src/ccx_core.cpp:379-381` multiplies soil respiration by

    pow(q10, ±seas_T_amp[hi] * sin(2π(t − (3.5+SEAS_T_LAG)/12)) / 10) / seas_r_norm[hi]

and `seas_r_norm[h]` (lines 653–659) is the **720-point ANNUAL MEAN OF EXACTLY THAT SAME FACTOR**.
**The division removes the Jensen rectification exactly, at every amplitude.** The code says so in
its own comment: *"unit-annual-mean"*.

⇒ **`seas_T_amp_SH` CANNOT change annual-mean soil respiration, so it cannot move the land sink or
gate 7 through the direct path — at ANY value.** Analytically the removed factor is
`I₀(A·ln q10 / 10)`, which over 1.0391 → 3.4945 would have been only **1.000044 → 1.000495, i.e.
+0.045 %** — on ~20 GtC/yr of SH heterotrophic respiration, **~0.009 GtC/yr against a 1.15 GtC/yr
gap, ~130× too small even if it were NOT normalised out.**

**A null here would therefore mean NOTHING** ([[no_power_null]]). So the run does two things:

- **T1 — MUTATION TEST of that structural claim.** Sweep `seas_T_amp_SH` ALONE over
  {1.0391, 3.4945, 7.1012, 13.95} with everything else frozen. **PREDICTED: the 2015–2023 land and
  ocean sinks move by < 0.001 GtC/yr — numerically zero.** If they move materially, **my reading of
  the code is wrong** and that is the finding.
- **T2 — THE REAL QUESTION.** Evaluate gate 7 at the STORED seasonal-fix vectors from
  `outputs/diagnostics/price_the_lag.rds` (shipped-gross arms at lag 1.7677 / 2.00 / 2.25 / 2.50,
  where the WHOLE slice was re-optimised). This asks whether the seasonal-fix CONFIGURATION moves
  gate 7 through any path, not whether `seas_T_amp_SH` does.

## 2. GATES

- **T0 — CONTROL.** At the mode, land **3.56** and ocean **2.97** GtC/yr on 2015–2023, within 0.01.
  Same `dg_sinks()` window and estimator as `diag_design_gates_at_mode.R`, copied not reinvented.
- **T1 — the structural null, mutation-tested.** |Δ land| < 0.001 GtC/yr across the whole sweep.
  **PREDICTED: PASS (i.e. exactly null).**
- **T2 — the statistic.** Land sink at each stored arm vs 3.56, against GCB 2.410 ± 0.50.
  **"MOVES" = |Δ land| ≥ 0.25 GtC/yr (half a σ) at lag 2.25.**
  **PREDICTED: it does NOT move — |Δ| < 0.25** — because the only slice members with an annual-mean
  carbon path are `q10` (PINNED in those arms) and `seas_T_amp_NH` (same normalisation), so nothing
  in that configuration has a route to the annual budget.
- **T3 — IF T2 moves, ATTRIBUTE IT.** Report which parameter carries it by re-evaluating the arm
  with each slice member reverted to the mode one at a time. No gate; it is a decomposition.

## 3. WHAT NO OUTCOME LICENSES

Nothing is adopted. This cannot rehabilitate `seas_T_amp_SH`, price the lag (done, 08-29d), or
revisit gate 7's target. **If T1 and T2 both come back null, the honest conclusion is that the
seasonal and land-sink defects are INDEPENDENT and gate 7 needs its own arm** — not that the
seasonal fix was tested and failed.
