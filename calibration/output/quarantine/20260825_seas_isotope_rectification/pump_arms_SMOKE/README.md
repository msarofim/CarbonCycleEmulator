# SMOKE TEST OUTPUT — NOT A RESULT. DO NOT QUOTE ANY NUMBER IN HERE.

Produced 2026-08-16f by a **deliberately truncated** copy of
`calibration/run_modefind_pump_arms.R`: `ARM_RESTARTS = 1`, `ARM_MAXIT = 60`,
against the real driver's 20 and 20,000. **Neither arm is converged and neither
is a mode.** The run existed to exercise the driver end-to-end before committing
~11 h to it, and it did its job — it found a blocker.

Kept rather than deleted because it **is the evidence** for that blocker (see
CHANGELOG 2026-08-16f and DESIGN §5.2j). Kept under a `_SMOKE` name, with this
file, so it cannot be mistaken for `calibration/output/pump_arms/`, which is
where the real run will write.

## What it verified about the driver (the point of the exercise)

- The `pump_mode`-differs-and-nothing-else gate fires and passes.
- Both arms run, write their own `.rds` as they finish, and the comparison block
  executes.
- **The Laplace evidence degrades to `NA` rather than being patched** when an
  arm's Hessian is not positive-definite — the N arm's was not, at a
  non-converged point. **This is a live risk for the real run**: if either arm
  comes back non-PD there is no evidence number, and `calibration/recompute_hessian.R`
  (which sweeps `ARM_HESS_EPS` and checks curvature is stable) is the remedy.
- The per-stream decomposition and the standing-questions block both populate.

## What it found — the reason the real run was NOT launched

**Both arms landed with all three ocean-gradient rows ABSENT, and both ran
`pump_grad` into the far prior tail.** `LIK_OCEAN_GRAD_HML_OK` is [85, 120]:

| arm | `h_ml` | rows | `kz` (bracket [3942.5, 6528]) | `pump_grad` | prior sd |
|---|---|---|---|---|---|
| N | 85.00 | **ABSENT** | 6434.3 (96.4 % up) | 963.6 | +5.68 |
| D | 33.52 | **ABSENT** | 4174.6 (9.0 % up) | 1431.0 | +7.25 |

Two things make this more than truncation noise:

1. **The arms diverge completely** — `h_ml` 85.00 vs 33.52, `kz` at 96.4 % vs
   9.0 % of the bracket. With the constraining rows switched off the surface is
   flat/multi-modal enough that two arms of the same objective wander to
   unrelated corners. A comparison run in that regime is noise.
2. **It is not a truncation artifact of the search alone.** Measured separately
   at otherwise-init parameters: crossing `h_ml` 84.99 → 85.00 (absent → live)
   **costs 10.07 log-units** and 119.99 → 120.01 (live → absent) **gains 9.6**,
   so the objective actively *pays* to leave the band; and `h_ml`'s own
   likelihood falls monotonically from −4105 at 70 to −4703 at 150. The N arm
   sitting at **exactly 85.00** is that edge being found from the outside.

**`pump_grad` = 963.6 and 1431.0 are what an unconstrained pump looks like.**
With the rows LIVE (`h_ml` = 100) the best `pump_grad` is **250.0, 0.28 prior
sd** — close to both the observation (233.109) and the 1-D optimum (274.5).

## Also not a finding, and flagged so it is not read as one

The per-stream table shows D gaining on `co2_seasonal_MLO` (+29.6), `d14c_NH`
(+24.8) and `d13c_level_SPO` (+10.8) — i.e. **not** "entirely the CO₂ record",
which was the pre-refit reading. That would be interesting **if either arm were
converged**. Neither is. It is recorded only as a reason to look at that table
carefully when the real run lands, not as evidence about N vs D.
