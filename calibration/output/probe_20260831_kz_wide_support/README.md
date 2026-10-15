# PROBE — does the `d14c_deep_ocean` term hold `kz` with all 22 parameters free?

**Staged 2026-08-31c. This is a PROBE, not a refit, and it adopts nothing.**

## The question, and why it needs a run

`R/calibrate.R` sets the `kz` bracket's exit condition in terms:

> *"keep the bracket, add the term at n_eff = 20. **DELETE IT ONLY AFTER A REFIT SHOWS THE TERM
> HOLDING `kz` ALONE.**"*

Two earlier answers exist and **neither is the refit the condition asks for**:

| | free parameters | verdict |
|---|---|---|
| `diag_kz_railed.R` (08-2x) | **0** — conditional profile at the mode | likelihood turns over at 6462, INSIDE |
| `diag_kz_bracket_on_the_sourced_target.R` PART 3 (08-31c) | **3** — `kz`/`fert_k`/`q10` | turns over at **6486.1, 56 %** of a 3σ box |
| **this probe** | **22 — all of them** | ← the exit condition as written |

08-31c also measured *why* the question is live: the shipped bracket is a **hard truncation of
GLODAP deep-Δ¹⁴C at +1.22σ** (defaults) / **+2.0σ** (the mode's own map), against the σ = 10.3 the
likelihood term scores that same observable with. The bracket and the term encode **one observation
twice**, and the harder encoding wins.

## The support, and why k = 6 is not a free choice

`CCX_WIDEN_PARAMS="kz=3494.9,13265.0"` — the **k = 6σ** bracket re-bisected on the sourced GLODAP
target (−175.26 ± 10.259 ‰, `ccx_deep_d14c_target()`), i.e. Δ¹⁴C ∈ [−236.8, −113.7] ‰.

⭐ **THE POWER REQUIREMENT SETS k, NOT TASTE.** The runaway this bracket was created to stop is the
17-parameter unbounded mode at **`kz` = 10,686**, which on the model that ships reads deep Δ¹⁴C
**−125.6 ‰ = z +4.84**. A support must CONTAIN that or "`kz` stayed interior" is structurally
guaranteed and the null is untestable ([[no_power_null]]):

    k = 4  ->  [4045.3,  9344.5]   EXCLUDES the runaway  ->  NO POWER, rejected
    k = 6  ->  [3494.9, 13265.0]   CONTAINS it (z +4.84) ->  ADOPTED

**k = 6 is the smallest sourced bracket with the power to fail.**

## ⚠ THE PROBE'S POWER IS ASYMMETRIC — read the two outcomes differently

- **`kz` runs away** (walks toward 13265, or past the old 6528 and keeps going) → **DECISIVE.** The
  term does not hold it, the bracket is load-bearing, and option "delete" is off the table.
- **`kz` stays interior** → **SUGGESTIVE, NOT CONCLUSIVE.** 4 restarts is not convergence, so this
  cannot certify the exit condition met — only that it was not violated within the budget. Do not
  report it as "the exit condition is satisfied".

This asymmetry is the reason a short probe is worth running before a 14 h refit at all.

## What is staged

| file | md5 | note |
|---|---|---|
| `run_modefind_pump_arms_FROZEN.R` | `5e414c7d0af572f5abec365775e4f514` | byte copy of the tracked driver at `89048f7`. **This copy may not be edited** (never edit a running script). |
| `from90/mode_fit_pumpN.rds` | `f4f28060a9ea35064ddf2bf70d118ace` | the 08-30 arm-N warm start — **byte-identical to the staged refit's copy**, so the two runs start from the same point. |

**Arm: `from90` only.** The bracket question is not arm-specific, and `pin90` would double the
contention for no extra information. `pump_mode` "N".

## Budget

    CCX_ARM_RESTARTS=4  CCX_ARM_CYCLES=1  CCX_ARM_MAXIT=20000   (~30 min projected)

**Restarts are cut; the per-restart budget is NOT.** The full refit is 20 restarts × 6 cycles ≈ 14 h,
i.e. ~7 min per restart at `MAXIT` 20000. Cutting `MAXIT` instead would leave every restart
unresolved, which is how a smoke says nothing (08-31b §4: `MAXIT` at 20000 with restarts cut left
the run inside its FIRST restart at 23 min — that is the cheap-smoke knob, and this is not a smoke).

## ⚠ Caveats carried

- **The Laplace evidence of a widened run is NOT comparable to an unwidened one** — a uniform prior
  over a wider support has a different normalizing constant. Read **parameters** and **per-stream
  logL**, never evidence. (Same caveat the pin block carries for pins.)
- **The Hessian this run reports is still subject to the owed step study.** 08-31c measured that at
  the `lifted` point `kz` is the ONE coordinate with step-dependent curvature — plausibly because a
  logit pressed against its bound has a vanishing Jacobian (3.6× compressed at the canonical mode,
  ~10× at the 08-30 arms). **If that hypothesis is right this probe should also stabilize `kz`'s
  Hessian entry**, which is a second, independent thing to read off it.
- **Nothing here changes what ships.** `CCX_WIDEN_PARAMS` mutates the table in-session only, behind
  gates that refuse a no-op, a narrowing, a non-logit parameter, and any edit that touches more than
  the named parameter.

## Launch

    PD=calibration/output/probe_20260831_kz_wide_support
    export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1
    CCX_ARM_OUTDIR=$PD/from90 \
    CCX_WIDEN_PARAMS="kz=3494.9,13265.0" \
    CCX_ARM_RESTARTS=4 CCX_ARM_CYCLES=1 CCX_ARM_MAXIT=20000 \
      Rscript $PD/run_modefind_pump_arms_FROZEN.R > $PD/from90/_run.log 2>&1

**TORCH VERDICT (standing rule, say it every time): LAPTOP.** Torch is RUNNABLE — cross-platform
parity is exact to 9 decimals (probe job `16075825`) — but measured **2× slower per eval**, the
driver is serial Nelder-Mead, and Claude cannot authenticate (VPN + Duo are Marcus's). A ~30 min
serial job is strictly worse there.
