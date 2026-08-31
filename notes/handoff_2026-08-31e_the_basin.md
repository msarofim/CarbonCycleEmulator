# Handoff — CarbonCycleEmulator, 2026-08-31e
# **THE MISSING CONTROL WAS TWO EVALUATIONS, NOT A REFIT — AND IT SAYS**
# **THE INCUMBENT IS NOT THE MODE. TWO BASINS, 21.5 LOG-UNITS APART.**

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`, **clean at `fd6d696`**.
1 commit. Nothing running. **No files under `R/` touched** ⇒ the suite cannot have regressed and was
not re-run; it stands at 1275 / 6 FAIL / 2 skip.
Continues `handoff_2026-08-31d_probe_and_the_torch_question.md`, whose **ruling #4 is now ANSWERED**.

⚠ **SESSION CWD WAS `FaIRtoFrEDI/`; ALL THE CODE WORK IS IN `CarbonCycleEmulator/`.**

---

## 0. STATE IN FIVE LINES

1. ⭐ **The probe's mode is FEASIBLE under the shipped bracket ⇒ the control 08-31d costed as a
   refit is a matched pair of evaluations.** §1
2. ⛔ **+51.73 under the SHIPPED table ⇒ the `kz` widening contributed NOTHING.** §2
3. ⛔ **TWO BASINS: the straight `u`-path dips 21.53 BELOW the worse endpoint.** §3
4. ⇒ **Ruling #4 answered, and INDEPENDENT of rulings #1–#3. The dispersed multi-start is now the
   load-bearing run; a warm start from the incumbent cannot reach the better basin.** §4
5. **Rulings #1, #2, #3 remain OPEN and are Marcus's.** 08-31d §4 stands unchanged. §5

---

## 1. THE OBSERVATION THAT COLLAPSED THE CONTROL (`fd6d696`)

08-31d §2 recorded the +51.9 decomposition as *"ARITHMETIC, NOT MEASUREMENT"* and named the control:
*"the staged refit, split with the SHIPPED bracket — HAS NOT BEEN RUN."* It was costed as a refit.

**It is not one.** The probe's mode sits at `kz` = **6302.37, INSIDE the shipped [3942.5, 6528]**
(91.3 % of it) and `h_ml` = **134.11, inside the shipped [30, 200]**. **All 22 parameters are
strictly interior to the shipped table.** ⇒ the probe's mode is a **feasible point of the un-widened
problem**, and "is it better under the shipped bracket" is **two evaluations**, ~40 s.

⭐ **THE TRANSFERABLE MOVE: before costing a control as a refit, ask whether the candidate point is
already FEASIBLE under the incumbent's constraints.** If it is, the question is an evaluation.

`calibration/diag_probe_basin_vs_incumbent.R`. Adopts nothing. Gates **mutation-tested 2/2**.

---

## 2. THE BASELINE IS THE 08-30 FILE, AND GETTING THAT WRONG COSTS 38 LOG-UNITS

⛔ **NOT `CCX_MODE_CANONICAL`.** `refit_20260825f_from90` predates three of the four stacked objective
changes in `INDEX_ccx`, and in today's build reproduces **its own stored logpost only to −42.99**.
The **08-30 landed** file (`refit_20260831_seas_lag_split/from90`, md5 `f4f28060…`, = the probe's own
warm start, and a 21-param file migrated to 22 by the model's own `ccx_migrate_par_set()` contract)
reproduces to **−0.85**. Against the canonical the gap prices at **+89.67 — wrong by 38, all of it
objective drift**, and it would have read as a discovery.

    MATCHED, both under the SHIPPED table
      incumbent (08-30 landed)   -1548.0112
      probe     (08-31 wide)     -1496.2776
      probe - incumbent          +51.7336

⇒ ⛔ **THE WIDENING CONTRIBUTED NOTHING.** The handoff's cross-bracket **+51.9** survives at **+51.73**
once the reparameterisation is removed **by construction** rather than estimated. The probe's own
recorded-band offset — the widened-`kz` constant — measures **+1.33**, against 08-31d's predicted
"≈1.5". **It was never a bracket question.**

---

## 3. TWO BASINS, NOT AN UNFINISHED CLIMB

**No single-coordinate move from the incumbent is uphill:**

    + the probe's SPLIT NPP lags   -654.53
    + the probe's h_ml only        -330.05
    + the probe's kz only            -2.71
    the probe, all 22 together      +51.73   <- only the JOINT move gains

**Each point is a LOCAL MAXIMUM in `h_ml` conditional on the rest** — a 43-point profile across the
shipped [30, 200] puts the argmax at **35.0 m** from the incumbent and **135.0 m** from the probe,
each at its own value. Dragging `h_ml` alone to the other mode costs **−330.05** / **−368.76**.

⭐ **MODE CONNECTIVITY.** The straight line in `u`-space between them dips to **−1569.54 at t = 0.40**
— **21.53 log-units BELOW the worse endpoint**, 73.27 below the better. ⇒ **SEPARATED.** These are
two basins, not one hill the 08-30 refit failed to finish climbing.

⚠ **CHECK, surfaced not swallowed:** one straight path bounds what a **LOCAL** search starting at the
incumbent can reach. It is **NOT** a proof of topological separation — a curved route may exist.

**ADDENDUM — the incumbent is not converged either.** On its **own** side of the barrier,
t ∈ [0.025, 0.100] scores above it, best **+2.43 at t = 0.05**. Consistent with the 08-30 run hitting
its restart cap while still gaining, and with the BFGS polish's +9.07.

---

## 4. WHAT THIS SETTLES — AND WHAT IT DOES NOT

✅ **RULING #4 ("does the `h_ml` basin change what we refit AT ALL?") — ANSWERED: YES.** Any refit
warm-started from the incumbent **inherits the wrong basin and cannot cross to the better one.**

⭐ **AND IT IS INDEPENDENT OF RULINGS #1–#3.** 08-31d listed all four as blocking and warned they were
not independent. **The basin question does not wait on the `kz` bracket**: the better mode is interior
to the shipped bracket, so it exists whichever way #1 is ruled.

⇒ **08-31d §5b's recommendation is now MEASURED rather than inferred from one accident: run the
DISPERSED MULTI-START FIRST.** The laptop warm-start continuation prices a split *inside the wrong
basin* and is the follow-up, not the lead.

⚠ **It also sharpens 08-31d's caveat on the 6 test failures.** "The refit is their fix" is worse than
optimistic: a warm-started refit fixes them **into the basin we now know is not the best one.**

⚠ **The probe is still NOT converged** (restart cap; BFGS polish gained 9.07), so **−1496.28 is a
LOWER BOUND on its basin's depth.** Every number here is conservative — the gap can only widen.

---

## 5. ⛔ STILL OPEN — ALL MARCUS'S, ALL UNCHANGED FROM 08-31d §4

| # | ruling | status |
|---|---|---|
| **1** | **The `kz` bracket**: keep / re-bisect at a stated k / delete | **OPEN.** 08-31d's recommendation — **re-bisect wide** — is unchanged. §2 removes the *urgency* (the bracket is not what is costing the +51.73) but not the *defect* (wrong layer, uncited target). |
| **2** | **§8.3 — buy gate 7 by putting the deep ocean 3.4σ young?** | **OPEN.** Untouched today. |
| **3** | **Seasonal `tau_ex` adoption** (a PARAMETER-SET change) | **OPEN.** Untouched today. |
| **4** | **Does the `h_ml` basin change what we refit?** | ✅ **ANSWERED — yes.** §4 |

**TORCH VERDICT (standing rule — say it every time): RUNNABLE, NOT YET RUN, AND THE CASE IS NOW
MEASURED RATHER THAN SUSPECTED.** Everything in 08-31d §5a/§5c stands verbatim: a straight port is
**measured to lose** (Mac ~2× faster per eval, Nelder-Mead serial, would not fit `cpu_short`'s 4 h);
**Torch only wins RESTRUCTURED for parallel dispersed starts**, which is a methodological change and
therefore Marcus's call; **Claude cannot submit** (VPN + gateway + Duo + device-code); `adaptMCMC` is
still missing there.

---

## 6. NON-OBVIOUS STATE

- **Nothing running. Repo clean at `fd6d696`. No `R/` files touched**, so the suite was deliberately
  NOT re-run — it stands at **1275 / 6 / 2**.
- ⚠ **A `<<-` restoring `CCX_PARAM_TABLE` at SCRIPT TOP LEVEL fails** — top level *is* `globalenv()`,
  and `<<-` begins its search **above** it, on the package search path. Plain `<-` at that scope.
  Cost one run; the same idiom inside a function (as `R/paths.R` uses it) is correct.
- ⚠ **`ccx_migrate_par_set()` is the ONLY correct way to bring the 21-param 08-30 file to 22** — it
  reads `ccx_seas_lag_p()`, the model's own absence contract, rather than re-deciding what the
  retired scalar meant. Do not hand-fill the two lag names.
- **Memory updated:** new `ccx_two_basins_not_a_bracket.md`; `INDEX_ccx.md`'s 08-31d probe paragraph
  REPLACED with the measured version (it said "MAY NOT BE THE MODE"); root `MEMORY.md` CCX line
  extended. ⚠ **`INDEX_ccx.md` is 15.9 KB and `MEMORY.md` 15.2 KB — both over their soft budgets
  (14 / 12 KB), under the 18 KB hard ceiling. Merge when convenient.**
- ⚠ **08-31d §6's two "stale index" items were ALREADY FIXED** before this session started — both
  indexes were rewritten at 13:01 and correctly read "SHIPPED 08-31" and "SUITE 1275". Do not re-fix.
- ⚠ **Everything else in 08-31d §7 still stands** — the staged refit is still STAGED AND UNLAUNCHED
  with a FROZEN driver predating the five 08-31d fixes; `ccx_forcing_at(F, i)` takes a ROW INDEX;
  `diag_landed_gap_streams.R` is QUARANTINED; `refit_20260828_sigma_eff` is RATIFIED "do not adopt".

## 7. HOW TO RUN IT

    Rscript calibration/diag_probe_basin_vs_incumbent.R    # ~40 s, adopts nothing, gates 4/4
