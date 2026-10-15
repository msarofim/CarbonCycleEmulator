# Quarantine — 2026-08-12b: free `tau_soil_fast`, unbounded `kz`

## What is wrong with these outputs

This is the **17-parameter** mode fit produced against the four-pool land with
`tau_soil_fast` **calibrated** and `kz` **unbounded** (lognormal prior, `init` 4000). Both
choices were superseded the same day, by decision (Marcus 2026-08-12), after this mode
demonstrated the problem.

**1. The mode undid the bomb-¹⁴C partition fix.** `tau_soil_fast` went to **11.16 yr at
+3.61 σ** — past `MODE_FLAG_SIGMA = 3.0`, so `run_modefind.R`'s own plausibility screen
flagged it and printed *"needs an explanation before this mode is used."* The explanation
is disqualifying:

| biosphere ¹⁴C vs N&L | 1975 | 1995 |
|---|---|---|
| two-pool land (the original defect) | +51 % | +58 % |
| four-pool land, defaults | −0.3 % | +9.6 % |
| **four-pool land, THIS mode** | **+50 %** | **+64 %** |

`diag_land_topology.R` [4] had already measured this bound ("at 10 yr the 1975 inventory
is +56 %"). The cause is structural: N&L's biosphere row has **no observational estimate**,
so there is no ¹⁴C-partition term in the likelihood and nothing stops the fit from leaving
the partition the four-pool land was built to close.

**2. `kz` ran away to 10,686** (+1.85 σ), putting the deep ocean at **−129.9 ‰** against an
observed −150 to −200. The fit wants high `kz` for the bomb window and low `kz` for the deep
age; with one diffusivity and no bound, the bomb window won.

**3. It did not converge.** It stopped on the `MODE_RESTARTS = 12` cap while still gaining
1.3–1.8 log-units per restart, and the BFGS polish then gained a further **9.74** — more than
the last five restarts combined. `logpost = -2293.5` is an **upper bound on the mode, not the
mode**, and must not be quoted as one.

## Files here

| file | what it is |
|---|---|
| `mode_fit.rds` | the 17-parameter mode, `logpost -2293.5`, Hessian PD (condition 2.2e5) |
| `modefind.log` | full run log, 178.2 min, 182,833 evals, 0.058 s/eval |

## Canonical replacement

`calibration/output/mode_fit.rds`, refit after the two decisions:

- **`tau_soil_fast` FROZEN** at its structural 2 yr — removed from `CCX_PARAM_TABLE`, so it
  is no longer calibrated. It keeps its value from `ccx_default_params()`. The land turnover
  times are teaching content, not nuisance parameters.
- **`kz` BOUNDED** to [3900, 6300] (logit + uniform), the range that puts the deep ocean
  inside the observed −150 to −200 ‰. Measured, not assumed: the kz→deep-Δ¹⁴C relation is
  essentially univariate (`h_ml` moves it <1.5 ‰ across 39.7–100 m).

## Do not quote

`logpost -2293.5` from this directory, for two independent reasons: it was maximized over a
**different parameter set** (17 vs the post-decision count), and it was **not converged**.
Comparing it to any later mode is meaningless in both directions.
