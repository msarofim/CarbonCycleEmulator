# QUARANTINE — outputs produced while `seas_ml` LEAKED INTO THE ASEASONAL SPINUP

**Created 2026-09-09t**, by the whole-model code review Marcus commissioned on 09-09s. See
CHANGELOG 2026-09-09t and `notes/review_2026-09-09t_whole_model_code_review.md` §1.

## 1. Which bug applies
**A real bug, not a reverted choice.** One mechanism was gated on **two different objects**:

- **R** gated on `ccx_seas_ml_on(p)` (`R/model.R:853`), which requires `p$seas_drivers > 0`.
- **C++** gated on `A.seas_ml`, and that flag was `as.integer(!is.null(aux$mld_coef))`
  (`R/cpp.R:50`) — **a function of `aux` ALONE**.

`ccx_spinup()` builds `aux <- ccx_prepare(p)` from the **un-zeroed** `p` (`R/spinup.R:151`) and only
**then** sets `p0$seas_drivers <- 0` (`:227`) — and **every equilibrium solve runs through the C++
path**. So the zeroing was honoured by R and **ignored by C++**, and the "preindustrial equilibrium"
was the state that balances a spurious entrainment limb frozen at the spinup epoch.

**MEASURED at the canonical `hilda31`:** R gate `FALSE`, C++ flag `1`, and the spinup's own
supposedly-aseasonal equilibrium moved

| | `seas_ml = 0` | `seas_ml = 1` | Δ |
|---|---|---|---|
| ocean C | 37 894.163 GtC | 35 953.939 GtC | **−1 940.224** |
| max abs Δ over all 36×3 state | — | — | **489.2** |

⚠ **The atmosphere is unchanged (588.093 both)** — it is pinned to `CO2_PI_PPM`, so the whole
displacement lands in the ocean, which is why no CO₂-level diagnostic flagged it directly.

## 2. Which files
Every one of these ran the model with `seas_ml = 1` through a contaminated spinup.

| file | what it is | why quarantined |
|---|---|---|
| `p12_compensator_20260909.{rds,log}` | P12, the `ent_seas_amp_SH` likelihood profile | both arms spun up; the `seas_ml = 1` arm is contaminated |
| `p12_streams_20260909.log` | P12's per-stream split | **derived from `p12_compensator_20260909.rds`** — inherits it |
| `p1c_dpco2_20260909.{rds,log}` | P1c, SH air-sea ΔpCO₂ vs SOM-FFN | the `seas_ml = 1` amplitude (40.76 µatm) is contaminated |
| `seas_ml_probe_20260909.{rds,log}` | P1, the unrefitted ML DIC anomaly | on-minus-off, so the "on" arm is contaminated |
| `seas_ml_convergence_20260909.{rds,log}` | P9 substep convergence + P10 rectification | `arm(seas_ml)` runs both arms |

⭐ **THE READING MOST AT RISK.** P12's headline was *"the mechanism succeeds on the seasonal cycle
and PAYS −514 on the two CO₂ LEVEL rows"*, and P10 independently reported *"the seasonal ML CHANGES
ANTHROPOGENIC UPTAKE — a RESULT, not a defect."* **Both are the exact signature of a ~1 940 GtC
ocean-carbon deficit at t₀.** Two diagnostics agreed, and their agreement read as corroboration when
it was a shared cause. Neither conclusion survives into the post-fix world without being re-measured.

## 3. Canonical post-fix replacements
**NOT YET REGENERATED** — re-running them is the next session's first task. When regenerated they
take the **same basenames in `outputs/diagnostics/`**. Compare against those, never against these.

The fix is the **2026-09-09u** commit (CHANGELOG 09-09u, `notes/handoff_2026-09-09u_blocker_fixed_rerun_owed.md`): the gate is now resolved **once**, in R, by the same function the
R core uses (`p$seas_ml_on <- as.integer(ccx_seas_ml_on(p))` in `ccx_cpp_par()`), shipped through
`Par`, and read by both C++ sites; `A.seas_ml` survives only as a data-presence conjunct.
`ccx_seas_ml_marshal_check()` refuses the mirror case (`p` ON, `aux` OFF) loudly.

## 4. ⛔ What is NOT quarantined, and must not be
`seasonal_ml_geometry_20260909.{rds,log}` — **pure geometry**. It calls `ccx_ocean_grid()` and reads
`data/obs_mld.rds`; it **never spins up or runs the model**, so the P8 bound (76.1 m), the layer-1
base and the winter-ML depths in it are unaffected. Verified by inspection of
`calibration/diag_seasonal_ml_geometry.R`, which contains no `ccx_spinup`/`ccx_run` call.

⚠ **The R-core-only results are also unaffected in principle** — the leak is in the C++ path — but
every diagnostic above obtains its initial state from `ccx_spinup()`, which uses C++ regardless of
which core then integrates. So "it ran in R" is **not** an exemption here.

## 5. Why kept rather than deleted
They are the **regression test for the fix** and the only measure of the bug's size. The pre-fix
behaviour is reachable in one line — restore the pre-fix gate in `ccx_cpp_par()` by dropping the
`seas_drivers` conjunct (`p$seas_ml_on <- as.integer(!is.null(p$seas_ml) && p$seas_ml > 0)`) — which
is exactly the mutation used to confirm the new tests in `tests/testthat/test-parity.R` genuinely
fail on the old code. These files are what a re-run should be diffed against to answer "how big was
it, per stream?", which is the question the refit's target depends on.
