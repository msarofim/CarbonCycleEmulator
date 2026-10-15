# Handoff — CarbonCycleEmulator, 2026-08-31b
# **THE REFIT IS STAGED AND SMOKED BUT NOT LAUNCHED — MARCUS RULED "SETTLE §8.3 FIRST".**
# **AND §8.3's NUMBER DID NOT SURVIVE CHECKING: −232 WAS MEASURED OFF-SUPPORT.**

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`, **clean at `d335152`**.
**Suite 1275 pass / 6 FAIL / 2 skip.** Nothing running. 2 commits here, 1 in `FaIRtoFrEDI`
(`e525182`, memory). Continues `handoff_2026-08-31_priced_and_option_A.md`, whose §8.1 recipe
**had a blocker in it** (§3 below).

⚠ **SESSION CWD WAS `FaIRtoFrEDI/`; ALL THE CODE WORK IS IN `CarbonCycleEmulator/`.**

---

## 0. STATE IN EIGHT LINES

1. ⛔ **The −232 land-axis price is measured OFF-SUPPORT.** `kz` = 7667 vs a bracket top of 6528. §2
2. **On support gate 7 still closes at `beta_max` 0.35 — for −285 / −298, and only barely.** §2
3. ⇒ **The real §8.3 question is "is `kz` ≤ 6528 defensible?", not "is −232 worth it?"** §2
4. **The 22-param refit is STAGED, FROZEN, SMOKED, and NOT LAUNCHED** on Marcus's ruling. §1, §4
5. ⚠ **The handoff's own warm-start recipe could not work** — fixed and mutation-tested. §3
6. ⚠ **A THIRD live-names-on-a-stored-vector site, and the first SILENT one: 1693 log-units.** §5
7. **Memory re-cut: `INDEX_ccx_ocean.md` split out; the −232 memory CORRECTED.** §6
8. ⚠ **The budget convention in `CLAUDE.md` and the one in practice DISAGREE.** §6

---

## 1. ⛔ OPEN TASKS BEFORE ANY REFIT — READ THIS FIRST

**The 08-31 lesson was "ship structural changes BEFORE the refit; this ordering cost 14 h."** It
cost 14 h once. The items below are the ones that would cost it again. Ranked by whether they
INVALIDATE a completed refit.

### 1a. BLOCKING — each of these moves the mode, so a refit run before it is wasted

| item | why it invalidates | where |
|---|---|---|
| **The `kz` bracket** | `kz` **rails**: 95.1 % / 97.5 % of bracket in the 08-30 arms, and **exactly 6528 (100 %)** at every constrained frontier point. The fitted mode is PRESSED AGAINST this bound. Move the bracket, the mode moves. | §2, [[ccx_price_measured_off_support]] |
| **The §8.3 land-axis ruling** | If `beta_max` is to be constrained toward 0.35, that is a different objective and a different mode. | §2 |
| **Seasonal `tau_ex` adoption** | `tau_ex_seas_amp` / `_phase` are `base_param`s at default 0, NOT among the 22. Adopting them is a PARAMETER-SET change — exactly what made the 08-30 refit a 21-param file in a 22-param build. | 08-31 §5 |

⚠ **These three are not independent.** All three touch how the model splits drawdown between land
and ocean. Settling them one at a time costs one refit each; settling them together costs one.

### 1b. NOT blocking the run, but blocking the USE of its output

- ⛔ **The Hessian step study is OWED.** `diag_hess_eps_21par.R` chose its step against a **KINKED**
  objective; the 08-29k C1 remap removed all 26 kinks. **The driver computes a Hessian at the end of
  every arm**, so a refit run today produces a covariance nobody may trust. Re-run the step study
  against the C1 objective **first** and the same 14 h yields a usable Hessian instead of a
  discarded one. Carried unchanged from 08-31 §9; it has now been deferred twice.
- ⚠ **`run_modefind_pump_arms.R`'s kink scan can no longer fail.** It prints `0 kink(s)` and fires
  its `!= 3` warning every run. A gate that always fires is not a gate. Left for a ruling.

### 1c. NOT blocking — resolved BY the refit, or independent

- **The 6 test failures** (`test-mode-decode.R:15,:29`; `test-mode-file.R:109` ×2, `:203`;
  `test-prior-z.R:38`). All say one true thing — the stored modes are 21-parameter files in a
  22-parameter build. **The refit is their fix**, so they are an OUTPUT of the refit, not an input.
- **`PIN_PRIOR_CREDIT` / `test-mode-file.R`'s premise.** 08-31 showed the arm gap WIDENED under
  refitting and the excess −9.52 is a likelihood differential re-optimization cannot recover, so the
  premise is **permanently** false. Needs REWRITING, not re-tolerancing, and not by a refit.
- **`b0 = 3.017`** against a derived bar of 4.0 but **2.8× the external floor (1.087 ppm)**. Its
  fixture is on `ccx_default_params()`, so **no refit will move it.** Model-quality item.
- **The `intersect()` blast radius** (§5) — 75 scripts, but **NOT the refit driver**, which is clean
  (verified §5).

### 1d. VERIFIED CLEAN — do not re-litigate

- ✅ **The refit driver is NOT affected by the `intersect()` defect.** Its only `intersect()` is at
  `:607`, inside the per-stream decomposition, and **all six parameters with no slot in
  `ccx_default_params()` are carried explicitly**: `bomb_total` / `luc_scale` at `:618-622`,
  `sigma_d14c` / `rep_dC` / `grad_off_co2` / `grad_off_d13c` at `:645-646`.
- ✅ **The warm-start path works**, end to end, on both real arm files (§3).
- ✅ **The two-arm smoke PASSED** — both exit 0, all three files written per arm (§4).

---

## 2. WOULD A TORCH REFIT GIVE US AS GOOD OR BETTER INFORMATION?

**SHORT ANSWER: STRICTLY MORE information, but NOT more of the information currently OWED — and it
costs a port plus the one property that makes this particular refit worth running.**

The two are not the same experiment:

| | **laptop — warm-start continuation** | **Torch — parallel dispersed multi-start** |
|---|---|---|
| what it does | refines the 08-30 basin under the 22-param objective | 20+ independent dispersed starts, take the best |
| answers | "what is the mode of this basin?" | "**is this basin the best one?**" |
| runtime | ~14 h, measured | ~1 h on 20 cores, **projected, never measured as a driver** |
| setup | zero — recipe verified, smoke passed | a PORTING project + Marcus's auth |
| **attributability** | ✅ **isolates the split** | ❌ **confounds split with basin change** |

### 2a. Why the laptop run is the RIGHT instrument for what is owed

Everything the refit is owed FOR is a within-basin question:

- resolve the 6 failures (needs *a* converged 22-param mode — either delivers);
- collect the **+11.33** the SH-lag split already scores (registered against **this** basin);
- re-measure `PIN_PRIOR_CREDIT` on comparable arms.

⛔ **AND ONE OF THEM ONLY THE WARM START CAN DELIVER: ATTRIBUTION.** The whole point of this refit is
to price *the split*. Warm-started, Δlogpost is the split's effect and nothing else. Dispersed
multi-start could land in a different basin, and then a +40 improvement cannot be decomposed into
"the split paid" versus "we found somewhere else". **That is not a runtime argument; the laptop run
is a better-controlled experiment for this question.**

### 2b. Why Torch's question is nonetheless the more valuable one right now

The model has never had a basin survey, and there is real evidence the objective is nasty:

- the 08-20r run **hit the restart cap while still gaining**, and its BFGS polish then gained
  **16.08** — two orders of magnitude more than any of its last restarts, i.e. the simplex collapsed
  in a direction the gradient could still exploit and **the mode was NOT located**;
- **31–35 log-unit BFGS jumps** and a non-monotone gain sequence;
- Hessian conditioned **1.11e6**, softest/stiffest sd ratio **1055×**;
- **`kz` rails, every single time.**

⇒ **Dispersed multi-start is the natural instrument for §1a's blocking question.** If 20 starts
dispersed across the space all drive `kz` to its bracket top, the rail is a property of the
objective, not of a warm start — and **that is evidence about whether `kz` ≤ 6528 is binding real
physics or just binding.** If they do not, the rail is an artifact and §8.3's price is meaningless.
**Torch's run answers the question that is BLOCKING the laptop run.**

### 2c. What is measured vs projected — do not confuse them

**MEASURED** (probe job `16075825`, 2026-08-20, `/scratch/ms17839/ccx-probe/`):
- R 4.5.1, Rcpp 1.1.0 present; `src/ccx_core.cpp` compiles in **4.1 s**, no source changes.
- ⭐ **Cross-platform parity is EXACT** — Torch and the Mac both give `logpost = -2674.035951671`,
  **all 9 printed decimals**. There is NO scientific barrier; results are directly comparable.
- ⚠ **The Mac is ~2× FASTER PER EVAL** — 0.141 s vs 0.294 s on the same 5-eval loop.

**PROJECTED, NOT MEASURED:** the "~15 h → under an hour on 20 cores". Only a 25 s probe has ever run
there; **no CCX driver has.**

⇒ **A straight PORT of the current driver is measured to LOSE**: 2× slower per eval, the driver is
inherently serial (Nelder-Mead, 20 SEQUENTIAL restarts), 2 × 28 h, and it would not fit
`cpu_short`'s **4 h** cap. **Torch only wins RESTRUCTURED.** Restructuring is a methodological
change, not an operational one, and therefore Marcus's call.

### 2d. Gotchas that already bit once (08-20), carried forward

- The R wrapper is a **Singularity container**: R **fails outright on the login node** and must run
  under SLURM.
- **Write the sbatch LOCALLY and `scp` it** — a heredoc-through-ssh mangled the `SLURM_TMPDIR` bind
  and cost a job (exit 127).
- Packages go to `R_LIBS_USER` on scratch; the overlay is `:ro`.
- **`adaptMCMC` is MISSING.** Blocks sampler work, not mode-find.
- ⚠ **Claude cannot authenticate** — VPN + gateway password + Duo + Microsoft device-code are
  Marcus's. Every Torch verdict ends in "laptop", or "here is the sbatch, you submit it".
- Fairshare was **1.000000** on 08-20 and decays with use — re-check before assuming priority.

### 2e. RECOMMENDATION

**Run BOTH, in this order, and do not collapse them into one job:**
1. **Torch dispersed multi-start FIRST** — it is the instrument for §1a's blocking `kz` question, and
   it is the cheap one *if* the port is paid. Its output is a basin map, not an adopted mode.
2. **Then the laptop warm-start continuation** for the owed, attributable within-basin numbers,
   once the bracket and the land-axis ruling are settled.

⚠ **If only one runs, run the laptop one** — it is the one that is owed, verified, and attributable.
**But do not read it as evidence that the mode is global. It cannot be.**

---

## 3. ⚠ THE HANDOFF'S OWN WARM-START RECIPE COULD NOT WORK (`203422a`)

08-31 §8.1 says to warm-start from the 08-30 arms because *"`par_mode` overlays via the legacy
branch"*. **True of the MODEL — `ccx_seas_lag_p()`'s absence contract — and FALSE of the FITTER.**
The warm start re-encodes through `ccx_par_to_unc()`, which iterates the **BUILD's** names, so a
21-parameter `par_mode` reached `.to_unc(NULL, ...)` and died inside `vapply` as

    values must be length 1, but FUN(X[[12]]) result is length 0

— an **INDEX**, three frames below the cause, naming nothing. **Probed directly on both real arm
files before launch: both failed.** It would have killed a 14 h run in its first seconds.

The 08-31 session hardened the **DECODE** side (`ccx_unc_to_par()`) and left **ENCODE** unhardened —
and encode is the side the warm start uses. Both halves now exist:

- **`ccx_par_to_unc()`** names the absent parameters and says a parameter SET is what changed.
- **`ccx_migrate_par_set()`** brings a stored list onto the build's fitted set, reading what an
  absent split MEANS **from `ccx_seas_lag_p()` itself** rather than restating the contract, so the
  two cannot drift apart. It **REFUSES** to fill from `CCX_SEAS_LAG_P_DEFAULT`: **a warm start from
  an invented coordinate is not a warm start.**
- The driver migrates at the warm-start site and **PRINTS what it filled**.

**Mutation-tested:** disable the encode guard → 3 failures; fill from the named default instead of
the legacy scalar → 5. Tests also run the two real 08-30 arm files end to end, skipping rather than
failing where the arm directory is absent.

⚠ **PROCESS NOTE.** The first mutation revert used `git checkout` on a file with UNCOMMITTED work
and discarded the edits; the mutation-2 evidence above is from an isolated redo using a file backup.
**Use a file backup, not `git checkout`, to revert a mutation on uncommitted work.**

### The 0.8 that is NOT a cost

The warm start reads **0.8 BELOW** each file's stored logpost. **That is not the migration costing
anything** — it is the split replacing one `seas_lag_p` prior term with two. Predicted from the
parameter table alone, **before looking**: from90 **−0.8533**, pin90 **−0.8115** (they differ because
the arms sit at different fitted lags, 1.7502 vs 1.7997). Predicted reads −1548.011 / −1557.487; the
driver printed **−1548.0 / −1557.5**. Two arms agreeing on a prediction that differs between them.

---

## 4. THE REFIT IS STAGED, FROZEN AND SMOKED — BUT NOT LAUNCHED

`calibration/output/refit_20260831_seas_lag_split/` holds:

- `README.md` — full provenance, including the §3 blocker and its fix.
- `run_modefind_pump_arms_FROZEN.R` — byte copy of the tracked driver at **`203422a`**
  (md5 `7d5e6122e506c01208f5d6eec8c8f042`). **The tracked driver may be edited; this copy may not.**
- `from90/mode_fit_pumpN.rds` — byte copy of the 08-30 arm, md5 `f4f28060a9ea35064ddf2bf70d118ace`
- `pin90/mode_fit_pumpN.rds` — byte copy, md5 `23bfb7457f331d213fdddc406f72f274`

**THE SMOKE PASSED** (`CCX_ARM_RESTARTS=1 CCX_ARM_CYCLES=1 CCX_ARM_MAXIT=60`, both arms parallel,
scratch outdir, ~23 min): **both exit 0**, both wrote `mode_fit_pumpN.rds` +
`mode_fit_pumpN_progress.rds` + `pump_arms_comparison.rds`, driver header confirms **22 parameters**,
and both logged `WARM START MIGRATED from a 21-parameter file: filled seas_lag_p_NH, seas_lag_p_SH`.

**TO LAUNCH** (only after §1a is settled), from the repo root:

    RD=calibration/output/refit_20260831_seas_lag_split
    export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1
    ( CCX_ARM_OUTDIR=$RD/from90 \
      Rscript $RD/run_modefind_pump_arms_FROZEN.R > $RD/from90/_run.log 2>&1 ) &
    ( CCX_ARM_OUTDIR=$RD/pin90 CCX_PIN_PARAMS='fert_k=90' \
      Rscript $RD/run_modefind_pump_arms_FROZEN.R > $RD/pin90/_run.log 2>&1 ) &
    wait

⚠ **`CCX_ARM_MAXIT` is the knob that makes a smoke cheap** — leaving it at 20000 while cutting
restarts/cycles produced a run still inside its FIRST restart at 23 min.

---

## 5. ⚠ A THIRD SITE OF THE SAME DEFECT — AND THE FIRST SILENT ONE (`d335152`)

Re-running `diag_price_the_gates.R` in the 22-parameter build **hard-stops on its own likelihood
gate**. The cause:

    for (n in intersect(names(base), names(p0))) base[[n]] <- p0[[n]]

`p0` is a 21-parameter mode, `base` a 22-parameter default. **`intersect()` does not error — it
OMITS** — so the fitted NPP lag is dropped and `base` runs at the **DEFAULT 2.25** instead of the
fitted **1.7502**. The gate reads **−3187.902 against −1494.871: 1693 log-units**, because the
seasonal CO₂ streams carry the model's highest leverage (`co2_seasonal_MLO` 4118). Routing `p0`
through `ccx_migrate_par_set()` restores it to **−1494.871 exactly**.

**Blast radius, and it splits on whether a guard exists:**
- **75 calibration scripts** use an `intersect` overlay; **20** mention `param_names` at all.
- ✅ **`app/global.R` IS guarded and degrades honestly** — `:121` skips any mode whose `param_names`
  mismatch, so it refuses all stored modes and falls back to hand-set values under a banner reading
  *"not fitted to anything… close but not calibrated."* **Working as designed. The refit resolves it.**
- ✅ **The refit driver is clean** (§1d).
- ❌ The unguarded diagnostics are not. Anything re-run since `11ff844` may have scored with the NPP
  lag at its default.

⛔ **NOT FIXED beyond the one script this needed. 75 call sites, and whether the fix belongs
per-caller or in ONE shared overlay helper, is Marcus's ruling.** ⚠ `diag_app_params.R:34` already
documents this exact idiom biting the app once before, so this is a RECURRENCE, not a first.

⇒ **THE RULE THE DAY ARGUES FOR** ([[intersect_is_a_silent_default]]): of today's THREE instances of
live-names-meet-a-stored-vector, the two caught fast were caught because something asserted a
**CONTRACT** — the objective's own gate, and a loop over `CCX_PARAM_NAMES` that refuses a `NULL`. The
one that cost real numbers is the only one that **treats absence as normal.** Make absence ASSERT.

---

## 6. MEMORY WAS RE-CUT — and the budget convention is AMBIGUOUS

- **`INDEX_ccx_ocean.md` split out** (pump / `h_ml` / `kz` / `tau_ex` / carbonate / DIC + δ¹³C
  gradients / conveyor / GLODAP). The split 08-30 predicted and that had been **deferred twice**. It
  opens with the two LIVE ocean rulings so the owed capacity diagnostic is found where it is looked
  for. Zero dangling links, zero orphans across 405 files.
- ⛔ **[[ccx_gates_priced]] CORRECTED** so nobody quotes −232 again, and
  **[[ccx_price_measured_off_support]]** written. **[[intersect_is_a_silent_default]]** written.
  **[[consider_torch_first]]** now carries the CCX verdict (§2) so it is not re-derived.
- **`FaIRtoFrEDI/CLAUDE.md` fixed** (`e525182`): its sub-index list still named **FOUR** when there
  were eight.

⚠ **THE BUDGET CONVENTION DISAGREES WITH ITSELF, AND IT CHANGES THE ANSWER.** `CLAUDE.md` says
budgets are *"measured on content excluding the fixed rules header"*; handoffs 08-30 and 08-31
compared **total `wc -c`** (*"17430 B — still 3 KB over soft"*). Measured both ways today:

| file | total | content (excl. header) | soft | over by TOTAL? | over by CONTENT? |
|---|---|---|---|---|---|
| `MEMORY.md` | 13664 | 7762 | 12288 | yes | **no** |
| `INDEX_ccx.md` | 14503 | 9351 | 14336 | marginally | **no** |
| `INDEX_ccx_seas.md` | 14706 | 11199 | 14336 | yes | **no** |
| `INDEX_slr.md` | 16622 | **15402** | 14336 | yes | **YES** |

⇒ **Under the WRITTEN rule only `INDEX_slr.md` is over. Under PRACTICE, four files are.** ⚠ **Settle
which — this is the same class of thing (a budget denominated in the wrong unit) that made the 08-17
structure regress within eight days.** The ocean split stands on its merits either way, but under the
written rule it was **not** budget-forced. ⚠ Any byte-count check must skip indented code blocks: a
naive `[[...]]` scan matches `p[[n]]` in quoted R and reports a phantom dangling link.

---

## 7. NON-OBVIOUS STATE

- **Nothing is running.** No partial jobs. Both repos clean.
- ⚠ **Everything in `handoff_2026-08-31` §9 still stands** — `ccx_hold_climate()` does not freeze
  `aod_*`; **never add an AOD → temperature term**; AOD pre-1850 is zero; `diag_landed_gap_streams.R`
  is QUARANTINED; `refit_20260828_sigma_eff` is RATIFIED "do not adopt"; the pinned-96 successor is
  undecided and is NOT a config change; `ccx_forcing_at(F, i)` takes a **ROW INDEX, not a year**.
- ⚠ **`tau_ex_seas_amp` / `tau_ex_seas_phase` remain `base_param`s at default 0**, NOT among the 22.
  Its phase is set by ITCZ migration and is **OBSERVABLE — pin it before reading the scan's argmax.**
- ⚠ **eVolv2k still LOCATED, not pulled** — needs Marcus's go-ahead. v3 (WDCC,
  `10.26050/WDCC/eVolv2k_v3`, NetCDF 21.24 MiB) **has the AOD**; v4 is VSSI only. Measure the
  **1850–1900 overlap** before any splice.
- **Suite 1275 pass / 6 FAIL / 2 skip** — the same 6 as `11ff844`, +20 new passes, no regressions.

---

## 8. COMMITS

    d335152  PRICED ON SUPPORT: the -232 used a kz 17% above its own bracket
    203422a  The warm-start path could not read a 21-parameter file, and said so with an index
    e525182  (FaIRtoFrEDI) Split the CCX ocean arc out of INDEX_ccx.md, a split owed twice over

## 9. HOW TO RUN WHAT THIS SESSION ADDED

    Rscript calibration/diag_price_the_land_axis_on_support.R   # ~12 min, the corrected axis
    Rscript -e 'library(testthat); test_file("tests/testthat/test-seas-lag-split.R")'   # 40 pass
    Rscript tests/run_tests.R                                   # ~9 min; expect 6 FAILURES, §7
