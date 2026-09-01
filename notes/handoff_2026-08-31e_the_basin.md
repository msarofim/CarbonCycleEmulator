# Handoff — CarbonCycleEmulator, 2026-08-31e
# **THE MISSING CONTROL WAS TWO EVALUATIONS, NOT A REFIT — AND IT SAYS**
# **THE INCUMBENT IS NOT THE MODE. TWO BASINS, 21.5 LOG-UNITS APART.**

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`, **clean at `dee1916`**.
⭐ **UPDATED AFTER THE POLISH LANDED — see §8, appended. The basin is CONVERGED and the gap is +52.0.**
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


---

# ⭐ §8 — APPENDED: THE POLISH LANDED. CONVERGED, +52.0, AND `kz` IS NOT RAILED.

`calibration/output/polish_20260831_probe_basin/` (`398691b` staging, `dee1916` outputs).
203.4 min, 67,311 evals, arm N, **SHIPPED bracket**, warm-started from a byte copy of the probe mode.

## 8.1 CONVERGED — the caveat is retired

    [N] cycle 1 restart  4: gain 0.0046
    *** [N] cycle 1 HIT THE RESTART CAP WHILE STILL GAINING
    [N] cycle 1 polish: log-post = -1496.0 (gain 0.0251)
    [N] === cycle 1 total gain 0.2648 ===
    [N] CONVERGED: cycle gain below ARM_CYCLE_TOL (0.5)

⚠ **READ THE CYCLE LINE, NOT THE RESTART LINE.** The restart-cap string is the same one that
disqualified the probe; `ARM_CYCLE_TOL` cleared `hit_cap` and the driver declared **CONVERGED**.
⇒ **the "NOT converged" caveat that qualified this basin since 08-31d is DISCHARGED.**

⭐ **The BFGS polish added 0.0251** — against the **9.07** it gained in the probe run from an
NM-stalled point. Starting from a polished point, it found nothing. That is the measurement that
justifies §8.5's abandoned restarts after the fact.

## 8.2 THE CONVERGED GAP IS +52.0

    MATCHED under the SHIPPED table
      incumbent (08-30)     -1548.0112
      probe (unconverged)   -1496.2776
      polished (converged)  -1496.0128
      polished - incumbent   +51.9984
      polished - probe        +0.2648

⇒ **the +51.73 lower bound was right to 0.27.** The polished mode file is a **22-parameter file
recorded under the SHIPPED bands** (`hml_bound` [30, 200], `kz_bracket` [3942.5, 6528]), so it
carries **no reparameterisation constant at all** and is directly comparable with anything fitted on
this objective.

## 8.3 ⭐ THE RESULT THAT FEEDS RULING #1: `kz` MOVES *AWAY* FROM THE CEILING

| mode | `kz` | % of shipped bracket | `h_ml` |
|---|---|---|---|
| incumbent (08-30) | 6400.36 | **95.1 %** | 35.25 m |
| probe (unconverged) | 6302.37 | 91.3 % | 134.11 m |
| **polished (converged)** | **6169.22** | **86.1 %** | **143.92 m** |

⇒ ⛔ **THE RAILING THAT MOTIVATED THE WHOLE BRACKET INVESTIGATION IS A PROPERTY OF THE WRONG BASIN.**
`kz` sits **further from the ceiling the better the fit gets**, and it is comfortably interior at the
converged mode. This does **not** settle ruling #1 — the wrong-layer / uncited-target defect in the
bracket's derivation is untouched by it — but it **removes the pressure** that framed the bracket as
binding, and it is new evidence *for* #1 rather than something blocked by it.

## 8.4 PRIOR TAILS MOSTLY IMPROVE; TWO STILL FLAGGED

Flagged (|z| > 3) **3 → 2**. Big movers: **`h_ml` −1.87 → +0.44** (from the tail to central — the
shallow-`h_ml` prior-credit signature is GONE), **`seas_T_amp_SH` −4.54 → −0.63**,
`seas_T_amp_NH` 2.31 → 0.28, `kz` 1.65 → 1.09. Worse: `npp_frac_NH` 1.15 → **−2.26**,
`tau_ex` −0.50 → −1.81.
⚠ **Still flagged: `sst_seas_amp_SH` −5.63 → −4.73** (improved, still deep) and **`rep_dC`
3.06 → 3.68** (worse). Both are long-standing; neither is created by this basin.

⚠ **Hessian: conditioning 5.36e5 → 1.12e5 (~4.8×), PD. `h_ml` is STEP-UNSTABLE — but so it was at
the incumbent**, so this is NOT a regression. ⛔ **08-31d §5d's conditional answer ("`kz` interior ⇒
all 22 stable") does NOT survive**: at the converged mode `kz` IS interior (86.1 %) and `h_ml` is
unstable anyway. That reading came from the probe's NON-CONVERGED point. **The Laplace covariance
here has one untrustworthy row** — matters for any evidence/uncertainty use, not for the MAP gap.

## 8.5 ⚠ THE FIRST ATTEMPT WAS ABANDONED AT 3 h — AND WHY

A 20-restart budget was launched first and killed at 3 h (`398691b`; log preserved as
`from90/_run_ABANDONED_20restarts.log`; nothing had been written, so the requeue reproduced restarts
1–2 **bit-identically**, confirming determinism under `ARM_SEED = 2026`).

Two errors in the original ETA, both recorded so they are not repeated:
1. ⛔ **Restart length generalised from ONE datapoint.** Restart 1's 10,545 evals (early `reltol`
   convergence from a polished start) was the EXCEPTION; restarts 2–3 used 17,503 and **20,001** =
   maxit. The "halves cycle 1" claim was wrong.
2. ⛔ **CONTENTION, not a slow run** ([[eta_in_days_is_not_a_slow_run]]): **0.150 → 0.241 s/eval
   (1.61×)**, tracking four Julia processes at ~100 % CPU from ANOTHER SESSION. **Left running.**

The remaining 17 restarts priced at **≈23 h**; the gain had already collapsed geometrically to
**0.0023**. §8.1's polish gain of 0.0251 confirms they would have bought **< 0.05**.

## 8.6 WHAT THIS CHANGES FOR THE RULINGS

| # | status after the polish |
|---|---|
| **1** `kz` bracket | **STILL OPEN, STILL YOURS.** §8.3 is new evidence: `kz` is interior at 86.1 % in the better basin, so the bracket is not binding where it matters. The derivation defect (wrong layer, uncited target) is untouched. **My recommendation is unchanged: re-bisect wide.** |
| **2** §8.3 gate-7 trade | **OPEN, untouched.** ⚠ Worth re-pricing IN THE NEW BASIN before ruling — the land/ocean split moved. |
| **3** seasonal `tau_ex` | **OPEN, untouched.** ⚠ `tau_ex` moved −0.50 → −1.81 in prior-z; re-measure here first. |
| **4** the `h_ml` basin | ✅ **ANSWERED AND NOW CONVERGED.** +52.0. |

⛔ **NOTHING IS ADOPTED.** The polished mode is **not** `CCX_MODE_CANONICAL` and this run did not make
it so. **Adopting it is a call for Marcus** — and it is a bigger one than it looks: it would move the
canonical mode into a different basin, which re-prices every gate and both open trades.

⚠ **AND THE SURVEY IS STILL OWED.** This converged ONE basin — the one the probe stumbled into. It
says nothing about whether a THIRD is better. **The dispersed multi-start remains the load-bearing
experiment** (§4, §5), and now has a proper incumbent to beat: **−1496.01**.

**TORCH VERDICT (standing): RUNNABLE, NOT YET RUN.** Unchanged, and this run is evidence FOR the
restructured form — 203 min for one warm-started chain on a contended laptop is exactly the serial
cost a dispersed survey multiplies by N.
