# Handoff — CarbonCycleEmulator, 2026-08-31d
# **THE BRACKET IS SETTLED AND THE −232 WAS RIGHT. THE PROBE SAYS `kz` STAYS PUT —**
# **AND FOUND A MODE 51.9 BETTER ALONG AN AXIS NOBODY WAS LOOKING AT.**

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`, **clean at `7cd5a38`**.
**Suite 1275 pass / 6 FAIL / 2 skip — the SAME six, no regressions.** Nothing running.
4 commits. Continues `handoff_2026-08-31b_offsupport_and_the_overlay.md`, whose §8.3 blocker is now
discharged and whose headline number is REVERSED.

⚠ **SESSION CWD WAS `FaIRtoFrEDI/`; ALL THE CODE WORK IS IN `CarbonCycleEmulator/`.**

---

## 0. STATE IN EIGHT LINES

1. ⛔ **`kz` ≤ 6528 is a +1.22σ TRUNCATION of GLODAP, not a numerical support.** §1
2. ⛔ **The −232 was RIGHT; −285 is what truncation costs. NEVER QUOTE −285 as "corrected".** §1
3. **The probe: `kz` used NONE of 6,865 m²/yr of new headroom — but is NOT converged.** §2
4. ⚠ **The probe's +51.9 is `h_ml`'s, not `kz`'s ⇒ THE CANONICAL MODE MAY NOT BE THE MODE.** §2
5. **5 bugs fixed, one of which decoded a real number 26 % wrong.** §3
6. ⛔ **FOUR rulings are open and ALL FOUR block a refit.** §4
7. **Before Torch: the port is unpaid, the parameter set is unfrozen, Claude cannot submit.** §5
8. **Structural-change status, item by item — two are DONE and the index says otherwise.** §6

---

## 1. THE BRACKET IS SETTLED — AND IT REVERSED 08-31b's HEADLINE (`b4d1d91`)

`calibration/diag_kz_bracket_on_the_sourced_target.R` (~18 min). Adopts nothing.

⛔ **08-31b called the bracket "a numerically-chosen support, neither an observation nor a law."
HALF WRONG, and it was the half that mattered.** The bisection recipe **is** observational — both
ends are the `kz` that puts the model's deep ocean at a stated Δ¹⁴C. What is unsourced is the
**TARGET**: `[−200, −150] ‰`, which `R/calibrate.R` itself calls *"an uncited recollection"*, on the
bottom **THREE** boxes, while `d14c_deep_ocean` scores the **BOTTOM BOX** against GLODAP's
**−175.3 ± 10.3 ‰**. The question was never "observation or not" — it was **which observation, on
which layer, with what σ.**

**On the layer the likelihood actually scores** (gated against DESIGN §5.2j's published ends,
reproduced to 0.05 ‰): `kz` 3942.5 → −219.75 ‰ = **z −4.34**; `kz` 6528 → −162.78 ‰ = **z +1.22**.
⇒ **a 5.55σ box centred 1.56σ BELOW the sourced target.** On the *mode's* own map the sourced 2σ top
is **6529.1** against the shipped 6528 — the ceiling **is a 2σ cutoff**.

⚠ **The law route is closed WITH A RECEIPT, not a shrug.** DESIGN §3.4 already prices `kz` at
**7.4–12.2× Ledwell's NATRE diffusivity** ((1.7±0.2)e−5 m²/s = 536 m²/yr) **by construction** — a 1-D
effective diffusivity emulating 3-D advection. Deep Δ¹⁴C is the ONLY bound available.

**Re-bisected on GLODAP, the land axis prices gate 7 at −232.0 / −233.9, not −284.9** — and the five
non-railed rows reproduce the *published off-support* `kz` (6486.0 / 6608.1 / 6799.6 / 7121.6 /
7666.6) to a maximum of **0.1 m²/yr**. ⭐ **An unbounded `exp(u)` search and a logit on a sourced 3σ
bracket, written a day apart for opposite purposes, land on the same optimum.**

⇒ ⛔ **THE FRONTIER'S PARAMETERS WERE RIGHT AND ITS SUPPORT WAS WRONG.** 08-31b's support-gate
DEFECT is real and its gate STAYS. **What was wrong was the REMEDY: re-derive the support, do not
re-price against it.** ⇒ **A GATE INHERITS THE AUTHORITY OF THE BOUND IT ENFORCES** — ours enforced a
bound with no receipt and turned an uncited recollection into a −53-log-unit "correction" that read
as a discovery.

**§8.3 RESTATED, and this is the deliverable.** The price is a **CURVE** in the deep-Δ¹⁴C misfit
tolerated (−285 at +1.2σ, −232 at +3.4σ), and `d14c_deep_ocean` already prices that continuously.
The call is a trade between two independent observations: **will we buy gate 7 (the GCB partition)
by putting the deep ocean 3.4σ young on GLODAP?** At `beta_max` 0.35 both sinks land inside 1σ
(land **+0.78**, ocean **+0.16**), deep Δ¹⁴C goes −155.4 → −140.5 ‰, and the deep term contributes
only ≈**−5.7** of the 232 — **so it is not what is being paid.** The CO₂ streams are, at their 40:1
leverage. **The bracket was not preventing that trade; it was HIDING it.**

---

## 2. THE PROBE — `kz` STAYED PUT, AND SOMETHING ELSE DIDN'T (`89048f7`, `a323a5d`)

`calibration/output/probe_20260831_kz_wide_support/` — 220 min, 84,299 evals, arm N only.
`CCX_WIDEN_PARAMS="kz=3494.9,13265.0"`, all 22 parameters free. **The exit condition as written.**

⭐ **k = 6 WAS SET BY POWER, NOT TASTE.** The runaway the bracket exists to stop is the 17-param
unbounded mode at `kz` = **10,686** = deep Δ¹⁴C −125.6 ‰ = **z +4.84**. A support must CONTAIN it or
the null is structurally guaranteed: **k = 4 → [4045, 9345] EXCLUDES it and has NO POWER**; k = 6 →
[3495, 13265] contains it. **k = 6 is the smallest sourced bracket that can fail.**

    kz  6400.4 (95.1 % of [3942.5, 6528])  ->  6302.4 (28.7 % of [3494.9, 13265])

**DOWN 1.5 % with the ceiling raised 2.03×; third least-changed of 20 parameters. It used NONE of
6,865 m²/yr of new headroom.** ⚠ **SUGGESTIVE, NOT CONCLUSIVE — pre-registered as such, and the
driver disqualifies it in its own words:** `*** [N] LAST CYCLE HIT THE RESTART CAP -- this mode is
NOT converged` (restart 4 still gained 0.70; the BFGS polish then gained **9.07**, the 08-20r
simplex-collapse signature). **This does NOT certify the exit condition met.**

### ⛔ AND THE PROBE DID NOT ISOLATE WHAT IT WAS BUILT TO ISOLATE

    logpost  -1547.2 -> -1495.3  (+51.9)
    h_ml       35.25 ->  134.11 m  (+280 %)  <- inside its UNCHANGED band
    seas_T_amp_SH +278 %, fert_k +63 %, beta_max +20 %, kz -1.5 %

Decomposition is **ARITHMETIC, NOT MEASUREMENT**: ≈1.5 reparameterisation (predicted **+1.49** from
the parameter values *before looking*; observed +1.5), ≈11.3 the `seas_lag_p` split, leaving **≈39
that is a better `h_ml`**. **The control that separates them — the staged refit, split with the
SHIPPED bracket — HAS NOT BEEN RUN.**

⚠⚠ **THE FINDING TO ESCALATE IS NOT ABOUT `kz`: THE CANONICAL MODE MAY NOT BE THE MODE.** −1495.3
against −1547.2, driven by a parameter **whose band nobody touched**, found because this run had a
fresh restart budget where the 08-30 run had hit its cap while still gaining. That is 08-31b §2b's
basin-survey argument arriving as **evidence rather than as a worry**, and it is independent of every
bracket question. **It also means the 6 test failures' "the refit is their fix" framing is optimistic
— a refit into the WRONG BASIN fixes them and is still wrong.**

### Two 08-31c predictions confirmed, both confounded

- **`kz`'s Hessian entry stabilised** — the morning's step study found `kz` the ONE step-dependent
  coordinate at `lifted`; the probe reports **all 22 stable**. (Jacobian compression: a logit at
  95.1 % of its bracket has `dkz/du` compressed 3.6–10×.)
- **Conditioning 5.36e5 → 6.84e4**, ~8×, against [[ccx_hessian_is_the_blocker]]'s 1.11e6.
- ⚠ Both confounded by the `h_ml` move. Neither is attributable to the widening alone.

### ⭐ A THIRD RESULT NOBODY ASKED FOR: the hemispheric lag behaves as predicted

The probe is the **first all-parameters-free evidence on OPTION A**. `seas_lag_p` was a scalar at
**1.7502**; split and freed it went **NH 1.4579 / SH 2.3159** — apart, in the directions
`INDEX_ccx_seas` predicted ("the SH needs its NEP later, the NH does not") — and `seas_T_amp_SH` rose
**1.074 → 4.054** unprompted, matching the registered "at lag 2.25 the fit raises it 1.04 → 3.49".
⚠ Not converged, and confounded with `h_ml`. **But the sign and the mechanism both replicate.**

---

## 3. FIVE BUGS FIXED (`a323a5d`) — suite unchanged at 1275 / 6 / 2

1. ⛔ **`kz_bracket` was RECORDED AND NEVER RESTORED. HIGH.** The driver has written it since 08-16
   for the reason it states beside `hml_bound` — *"`par_mode` is band-independent; `u_mode`,
   `hessian` and `cov` are NOT"* — and `ccx_mode_params()` / `ccx_adopt_mode_band()` restored only
   `hml_bound`. **Invisible for a fortnight because every file's `kz_bracket` equalled the shipped
   table.** The probe wrote the first file where they differ, and on it the standard
   `ccx_unc_to_par(md$u_mode)` idiom decodes `kz` as **4685.5 against a true 6302.4 — 26 % wrong,
   silently.** Recorded bands now live ONCE in `CCX_MODE_BAND_FIELDS`; both functions restore **and
   VERIFY** every one. Verified both ways (probe file → 6302.4; canonical mode → exact no-op).
   ⚠ **A defect I introduced and caught mid-patch:** `on.exit` registered INSIDE the restore loop
   captures the loop variable — R evaluates it at EXIT — so it restores the LAST band twice and
   leaks the rest. Snapshot before the loop, restore in one `on.exit`.
2. **`diag_hess_eps_21par.R` CRASHED (exit 1 → 0).** Empty `kb` ⇒ `cumsum(c(TRUE, diff(integer(0))>1))`
   is length 1 while `kb` is length 0 ⇒ `split()` yields one EMPTY group ⇒ length 0 into a
   `numeric(1)` contract. Empty because the 08-29k C1 remap removed the kinks. **Three live sites of
   the idiom; the other two were already guarded.**
3. **`min()` of an empty vector** in the driver — *"ARM_HML_INIT = 100 is Inf m clear"* + a warning,
   every run. **Line ~795 of the same file already had the guarded form.**
4. **A gate that could no longer pass**: `!= 3` was the PRE-remap kink count. Expected count is now
   **0**, measured, named, with provenance.
5. **Two "21 coordinates" labels in a 22-parameter build**, now derived from `length()`.

**NOT touched, deliberately:** the `intersect()` overlay across 75 scripts. Per-caller vs one shared
helper is a DESIGN decision parked with Marcus, not a bug fix.

---

## 4. ⛔ FOUR OPEN RULINGS — ALL FOUR BLOCK A REFIT

| # | ruling | why it blocks | where |
|---|---|---|---|
| **1** | **The `kz` bracket**: keep / re-bisect at a stated k / delete | changes the parameter TABLE ⇒ the staged refit must be re-frozen | §1, §2 |
| **2** | **§8.3**: buy gate 7 by putting the deep ocean 3.4σ young? | a different objective ⇒ a different mode | §1 |
| **3** | **Seasonal `tau_ex` adoption** | `tau_ex_seas_amp`/`_phase` are `base_param`s at 0, NOT among the 22 — adopting is a PARAMETER-SET change, exactly what made 08-30 a 21-param file in a 22-param build | §6 |
| **4** | **NEW — does the `h_ml` basin change what we refit AT ALL?** | if the canonical mode is not the mode, every warm-started refit inherits the wrong basin | §2 |

⚠ **These are not independent.** 1–3 all touch how drawdown splits between land and ocean; 4 may
moot the warm start entirely. **Settling them one at a time costs one refit each.**

**MY RECOMMENDATION ON #1, and it has NOT changed with the probe:** **re-bisect wide.** The probe
strengthens "delete" but does not reach it — my evidence is one non-converged run, and
`R/likelihood.R` records that under the Student-t marginalisation of `n_eff` the runaway penalty
drops **4.3× (20.1 → 4.67 against a 4.50 threshold)**, concluding in terms that *"under it this term
could NEVER replace the `kz` bracket."* Representation error in that σ is still **zero**. Re-bisecting
at a stated k fixes both documented defects (wrong layer, uncited target) without betting a refit on
a σ uncertain by ~2×.

---

## 5. WHAT IS NEEDED BEFORE A TORCH REFIT

**TORCH VERDICT (standing rule — say it every time): RUNNABLE, NOT YET RUN, AND THE CASE FOR IT JUST
GOT STRONGER.**

### 5a. What is MEASURED vs PROJECTED (unchanged from 08-31b §2c — do not re-derive)

**MEASURED** (probe job `16075825`, 2026-08-20, `/scratch/ms17839/ccx-probe/`): R 4.5.1 + Rcpp
present; `ccx_core.cpp` compiles in **4.1 s**, no source changes; ⭐ **cross-platform parity EXACT —
`logpost = -2674.035951671`, all 9 printed decimals**; ⚠ **the Mac is ~2× FASTER PER EVAL** (0.141 s
vs 0.294 s). **PROJECTED, NEVER MEASURED: everything about a CCX driver running there. Only a 25 s
probe has ever run.**

⇒ **A STRAIGHT PORT IS MEASURED TO LOSE**: 2× slower/eval, Nelder-Mead is inherently serial, 20
sequential restarts, and it would not fit `cpu_short`'s **4 h** cap. **Torch only wins RESTRUCTURED**
— and restructuring is a METHODOLOGICAL change, therefore Marcus's call.

### 5b. ⭐ TODAY CHANGED THE BALANCE OF 08-31b §2e

08-31b recommended the laptop warm-start first "if only one runs", because it is the ATTRIBUTABLE
experiment. **That advice was written before we had evidence that the incumbent basin is not the best
one.** §2's `h_ml` result is exactly what a dispersed multi-start exists to find, and it was found by
accident, on one arm, with a fresh restart budget. ⇒ **The dispersed multi-start is now answering a
question we KNOW has a surprising answer, not a hypothetical one.** I would now run **Torch's basin
survey FIRST**, and treat the laptop continuation as the follow-up that prices the split once the
basin is settled.

### 5c. THE CHECKLIST — what must be true before submitting anything

| | item | status |
|---|---|---|
| ⛔ | **The 4 rulings in §4 settled** — a refit before them is wasted (the 14 h lesson, twice now) | **OPEN** |
| ⛔ | **The driver RESTRUCTURED for parallel dispersed starts** — a straight port is measured to lose | **NOT STARTED**, and it is Marcus's methodological call |
| ⛔ | **Marcus submits.** Claude CANNOT authenticate — VPN + gateway password + Duo + Microsoft device-code | **standing** |
| ✅ | **The Hessian step study re-run against the C1 objective** — 08-31b §1b's "OWED, deferred twice" | **DISCHARGED TODAY**, §5d |
| ✅ | **The warm-start path reads a 21-param file** | fixed 08-31b `203422a`, smoked |
| ✅ | **Mode files decode under the band that fitted them** | fixed today, §3 item 1 |
| ⚠ | **`adaptMCMC` is MISSING on Torch** | blocks SAMPLER work, not mode-find |
| ⚠ | **Fairshare was 1.000000 on 08-20 and decays with use** | re-check before assuming priority |
| ⚠ | **Write the sbatch LOCALLY and `scp` it** | a heredoc-through-ssh mangled `SLURM_TMPDIR` and cost a job (exit 127) |
| ⚠ | **R fails outright on the LOGIN node** (Singularity container) — must run under SLURM | standing |

### 5d. ✅ THE HESSIAN STEP STUDY IS DISCHARGED — with a CONDITIONAL answer

Re-run today against the C1 objective (81 s, not the multi-hour job the handoff's framing implied).
⚠ **It was NOT stale in the ways 08-31b implied**: it reads `CCX_PARAM_NAMES` dynamically so it
already ran at 22, and `h_ml` was unbounded there on 08-28. Only its filename and two labels said 21.

    point `init`  : eps 3e-4 inside a stable window for 22/22
    point `lifted`: 20/22 -- sst_seas_amp_NH (positive curvature, NOT a step problem)
                          -- kz  STEP-DEPENDENT  <- the real failure
    *** CHANGE ARM_HESS_EPS. Step-dependent at: kz

⇒ **The answer is conditional on where `kz` sits.** At `lifted` (`kz` at 95.1 % of the shipped
bracket) it fails; at the probe's mode (`kz` interior, 28.7 %) **all 22 coordinates are stable.**
**So a refit whose `kz` is railed produces a covariance with one untrustworthy row, and one whose
`kz` is interior does not** — which ties this item to ruling #1 rather than settling it separately.

---

## 6. STATUS OF THE POSSIBLE STRUCTURAL CHANGES

⚠ **TWO OF THESE ARE DONE AND THE MEMORY INDEX SAYS OTHERWISE — fix the index before trusting it.**

| change | status | notes |
|---|---|---|
| **`seas_lag_p` → per-hemisphere** | ✅ **SHIPPED 08-31 (`11ff844`)**, in the 22 | ⛔ **`INDEX_ccx_seas.md` still says "NOT STARTED"** — STALE. Confirmed in `R/calibrate.R:274`. §2 gives its first all-free evidence and it behaves as predicted. |
| **`kz` bracket re-derivation** | ✅ **MEASURED today**, §1 | awaiting ruling #1. Nothing adopted. |
| **Hessian step study vs C1** | ✅ **DISCHARGED today**, §5d | conditional on `kz`'s position |
| **Pre-1850 volcanic (eVolv2k)** | ⛔ **LOCATED, NOT PULLED** — needs Marcus's go-ahead | **v3** (WDCC, DOI `10.26050/WDCC/eVolv2k_v3`, NetCDF **21.24 MiB**, CC-BY-4.0) **HAS the AOD**; **v4** (PANGAEA 2024) is **VSSI only**. The two overlap **1850–1900 = 51 yr of like-for-like validation — MEASURE THAT OVERLAP BEFORE ANY SPLICE.** ⚠ `ccx_hold_climate()` does NOT freeze `aod_*`; **never add an AOD → temperature term**; AOD pre-1850 is currently zero. |
| **Seasonal `tau_ex`** (`tau_ex_seas_amp`/`_phase`) | ⚠ **MEASURED, partially supported, NOT adopted** — `base_param`s at default 0, NOT among the 22 | best cell moves the bomb lag **+0.268 yr (74 % of the gap)** but costs **38 % of the CO₂ gradient**; at QUADRATURE phase the cost falls **~5×** per unit of lag (rectification, ⟨k·ΔC⟩ ≠ ⟨k⟩⟨ΔC⟩). ⛔ **THE PHASE IS NOT FREE — it is set by ITCZ migration and is OBSERVABLE. PIN IT BEFORE READING THE SCAN'S ARGMAX.** Adopting = a PARAMETER-SET change (ruling #3). |
| **`SEAS_T_LAG` per-hemisphere** (respiration phase) | ⛔ **NOT STARTED** | `INDEX_ccx_seas` names it as "an equally valid place to open the same angle" as the NPP lag — also global, also compile-time. The natural successor to OPTION A. |
| **Gate 12a — ocean CAPACITY** (buffer / Revelle / alkalinity) | ⛔ **OWED, UNWRITTEN** | the model sits at **0.200 airborne at 300 yr, already BELOW Joos's asymptote a₀ = 0.2173** ⇒ an EQUILIBRIUM statement. **Do NOT write another rate study for it** — it closes on NEITHER uptake axis. |
| **NH box's own seasonal amplitude** | ⛔ **UNCHECKED** | named as the seasonal arc's remaining gap |
| **`h_ml` basin** | ⚠ **NEW TODAY, unresolved** | §2. May moot the warm start. |

---

## 7. NON-OBVIOUS STATE

- **Nothing is running.** Both repos clean.
- ⚠ **`CCX_WIDEN_PARAMS` is NEW** (`89048f7`) — widens a LOGIT parameter's support in-session,
  mirroring how `CCX_PIN_PARAMS` narrows one. **Widen-only, and the gate enforces the name.** A
  **no-op override is REFUSED** — it reads identically to one that worked. **Mutation-tested 9/9.**
  The staged refit is unaffected: it runs an md5-pinned FROZEN copy, not the tracked driver.
- ⚠ **The probe OVERWROTE its own warm-start input**, as `ARM_WARM` is designed to (read and write
  the same path). The pre-run byte copy survives at
  `refit_20260831_seas_lag_split/from90/mode_fit_pumpN.rds`, md5 `f4f28060a9ea35064ddf2bf70d118ace`.
  **The probe README's md5 line for that file is therefore now stale by design.**
- ⚠ **The staged refit `refit_20260831_seas_lag_split/` is STILL STAGED, SMOKED AND UNLAUNCHED** and
  its FROZEN driver (md5 `7d5e6122e506c01208f5d6eec8c8f042`) predates today's five fixes. **If it is
  launched as-is it will carry bugs 3–5** (cosmetic) but NOT bug 1 (it writes `kz_bracket`
  correctly; only readers were wrong). **Re-freeze from `7cd5a38` if the rulings change anything.**
- ⚠ **Everything in 08-31b §7 still stands** — `ccx_forcing_at(F, i)` takes a ROW INDEX not a year;
  `diag_landed_gap_streams.R` is QUARANTINED; `refit_20260828_sigma_eff` is RATIFIED "do not adopt";
  the pinned-96 successor is undecided and is NOT a config change.
- ⚠ **Memory index staleness found today:** `INDEX_ccx_seas.md` says the hemispheric lag is "NOT
  STARTED" (it shipped 08-31); `INDEX_ccx.md` says "SUITE 1255" (it is 1275). **Pre-existing dangling
  memory link:** `glacier_gap_is_rate_not_curve`, referenced twice from `magicc_colder_than_fair_2300.md`.
- **Suite 1275 pass / 6 FAIL / 2 skip** — `test-mode-decode.R:15,:29`; `test-mode-file.R:109 ×2,
  :203`; `test-prior-z.R:38`. Same six as `11ff844`. ⚠ **"The refit is their fix" is optimistic while
  §2's basin question is open.**

---

## 8. COMMITS

    7cd5a38  Log 08-31d: the probe, and the five fixes
    a323a5d  Fix five bugs found sweeping for them; the kz one had a 26% wrong number in it
    89048f7  Add CCX_WIDEN_PARAMS so the kz exit condition can be ASKED without adopting it
    b4d1d91  Settle the kz bracket: it is a +1.2 sigma truncation, and the -232 was right

## 9. HOW TO RUN WHAT THIS SESSION ADDED

    Rscript calibration/diag_kz_bracket_on_the_sourced_target.R    # ~18 min, the bracket, on support
    Rscript calibration/diag_hess_eps_21par.R                      # ~81 s, now exits 0
    Rscript tests/run_tests.R                                      # ~9 min; expect the SAME 6, §7

    # the probe, re-runnable (arm N, ~3.7 h). NOTE it overwrites its warm start.
    PD=calibration/output/probe_20260831_kz_wide_support
    export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1
    CCX_ARM_OUTDIR=$PD/from90 CCX_WIDEN_PARAMS="kz=3494.9,13265.0" \
    CCX_ARM_RESTARTS=4 CCX_ARM_CYCLES=1 CCX_ARM_MAXIT=20000 \
      Rscript $PD/run_modefind_pump_arms_FROZEN.R > $PD/from90/_run.log 2>&1
