# Handoff — CarbonCycleEmulator, 2026-08-31f
# **THE GATES ARE RE-PRICED IN THE NEW BASIN — AND THE HARNESS THAT**
# **MEASURES THEM HAD NOT RUN SINCE 08-31.**
# **THE DISPERSED MULTI-START IS BUNDLED, GATED AND READY TO LAUNCH.**

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`, clean at `4538475`.
2 commits. **Nothing running on Torch. Nothing adopted.** `CCX_MODE_CANONICAL` is untouched.
**No `R/` file was touched**, so the suite stands where 08-31e left it — **1275 / 6 FAIL / 2 skip** —
and was deliberately not re-run.
Continues `handoff_2026-08-31e_the_basin.md`, whose **§8.6 "re-price in the new basin" is now DONE**.

⚠ **SESSION CWD WAS `FaIRtoFrEDI/`; ALL THE CODE WORK IS IN `CarbonCycleEmulator/`.**

---

## 0. STATE IN FIVE LINES

1. ⛔ **`diag_design_gates_at_mode.R` HAD NOT RUN SINCE 08-31** — its 21-name guard aborted it. Fixed,
   and gate 12's file was worse: an unknown arm silently ran the DEFAULTS. §1
2. ⭐ **THE +52.0 IS LIKELIHOOD-DRIVEN: loglik +37.82 / prior +14.18** ⇒ this basin PASSES the test
   the 08-28 option-5 refit failed. §2
3. **Gate 7 land +2.37 → +1.87 σ (still FAILS); gate 4 better but SMOOTHER; ⛔ gate 5 AND gate 12a
   get WORSE.** A 52-log-unit basin move buys NOTHING on the pulse response. §2
4. ⭐ **The dispersed multi-start is restructured, bundled and PORT-GATED** — `calibration/torch/`.
   RUNNABLE, READY, NOT YET RUN. **Marcus submits.** §3
5. **Rulings #1, #2, #3 remain OPEN and are Marcus's.** #2 and #3 are now re-priced. §4

---

## 1. THE GATES HARNESS WAS BROKEN, AND A BROKEN GATE IS SILENT

`diag_design_gates_at_mode.R` carried `stopifnot(identical(md$param_names, CCX_PARAM_NAMES))`. The
08-31 `seas_lag_p` split made every stored mode a 21-parameter file in a 22-parameter build, so the
script **aborted before its first gate** — the same one true thing the 6 failing tests say, in a file
nobody was running. `diag_joos_irf.R` was worse: an unrecognized arm argument (a typo, or a perfectly
legal mode PATH) **silently ran the uncalibrated defaults** and reported gate 12 as if that were the
question.

⭐ **THE TRANSFERABLE MOVE: after a structural change, RUN the guards — do not reason about them.**
A gate that cannot run and a gate that passes produce the same thing in a session that does not run
them: nothing. [[broken_gate_reports_nothing]], [[no_power_null]].

Both now MIGRATE a fitted ancestor through `ccx_migrate_par_set()` — the model's own absence
contract, which ERRORS rather than hand-filling — and **print that they did**. The Joos arm assert is
**mutation-tested** (`nonsense_arm` stops). Gates 4/5/7 moved into `calibration/lib_design_gates.R`
so the new re-pricing file measures the same gate rather than a second copy of it.

## 2. THE RE-PRICING (`calibration/diag_gates_in_the_new_basin.R`, ~10 s, adopts nothing)

Matched under the SHIPPED table. Incumbent = 08-30 landed (migrated 21→22), new basin = 08-31e
polished. ⛔ Baseline is **not** `CCX_MODE_CANONICAL` — it would misprice by 38.

| gate | incumbent | new basin | |
|---|---|---|---|
| **4** airborne fraction (GCB 0.431) | 0.418 (err 0.013) | **0.428 (err 0.003)** | ✅ |
| **4** decadal sd (obs 0.051) | 0.028 | **0.024** | ⚠ SMOOTHER — the spread half is WORSE |
| **5** NH→SH bomb lag (obs 1.34 yr) | 0.97 (−0.37) | **0.86 (−0.48)** | ⛔ |
| **7** land σ | +2.37 | **+1.87** | ✅ by 0.50 σ, STILL FAILS |
| **7** ocean σ | −0.82 | **−0.45** | ✅ passes |
| **12a** integrated IRF TH-20 vs Joos floor | −0.09 % | **−3.33 %** | ⛔ WORSE, still BELOW |
| **12b** tail ratio (band 0.593–0.979) | 0.7063 | 0.7077 | — passes both |
| prior-z flags \|z\|>3 | 3 | **2** | ✅ |

⭐ **THE SPLIT: loglik +37.82, prior +14.18.** That is the [[hml_shallow_is_prior_credit]] test, and
this basin PASSES it where the 08-28 option-5 refit failed it (+4.060 = prior +7.397 / loglik
**−1.199**). **The prior term is not zero** — do not call the gain purely likelihood-driven.

- **Payers FOR:** `d13c_level_SPO` +8.04, `co2_seasonal_SPO` +7.59, `gcb_land_sink` +7.03,
  `co2_seasonal_MLO` +6.70, `d14c_NH` +5.47. **AGAINST: `co2_gradient` −9.70.**
- **Parameters:** `fert_k` 189 → **320**, `beta_max` 0.555 → **0.680**, `h_ml` 35.25 → **143.9**,
  `tau_ex` 1.147 → **0.828**. ⚠ `npp_frac_NH` prior-z +1.15 → **−2.26** is the one that got worse.
- ⛔ **GATE 12a DOES NOT CLOSE IN EITHER BASIN AND MOVES THE WRONG WAY.** A 52-log-unit move to a
  different basin buys nothing on the pulse response — the strongest evidence yet that 12a is an
  ocean-CAPACITY defect, not a rate or a fitting one.

## 3. THE TORCH BUNDLE — RUNNABLE, READY, NOT YET RUN

**TORCH VERDICT (standing rule, said out loud): RUNNABLE, NOT YET RUN, AND NOW STAGED.** A straight
port of the serial driver is still MEASURED TO LOSE. **Torch wins only RESTRUCTURED**, and
`calibration/run_dispersed_multistart.R` is the restructuring: ONE start per process, so N starts are
a SLURM array instead of a queue. ⚠ **Claude cannot submit** (VPN + gateway + Duo + device-code).

**Read `calibration/torch/README.md` — it is the checklist.** In short:

    bash calibration/torch/make_bundle.sh          # on the Mac; ~2 MB, prints the scp lines
    bash calibration/torch/setup_torch.sh          # on Torch; Rcpp + a compile check + s/eval
    sbatch --array=0-2  calibration/torch/multistart.sbatch    # THE GATE BATCH -- read it
    sbatch --array=3-42 calibration/torch/multistart.sbatch    # only if the gate batch passes
    CCX_MS_OUTDIR=... Rscript calibration/collect_dispersed_multistart.R

- ⭐ **The dispersion sd is MEASURED: 1.0493**, the per-coordinate RMS distance between the TWO KNOWN
  BASINS, recomputed from their own mode files each run. ⚠ **Still a methodological choice — yours.**
  So is **N = 40**, the one of the four settings with no measurement behind it.
- ⭐ **The port gates itself, and each bound matches its own claim.** (a) the START point is an
  EVALUATION ⇒ **1e-8 relative** against `calibration/torch/port_targets.csv` (measured on the Mac,
  carrying host + commit); (b) the FINAL value is an OPTIMIZATION ⇒ an **ORDERING**, no threshold.
  Mutation-tested. ⚠ The target is **not** each file's stored `logpost`: the incumbent's −0.85 is
  objective drift and would have eaten most of a 1.0-log-unit budget before the port was considered.
- **The wall guard PROJECTS and SHORTENS.** `optim()` cannot be interrupted once entered, so a
  clock-only check commits a task to a whole further restart and lands past the 4 h cap.
- ⛔ **FOUR bugs the smoke found, all of them REPORTING bugs.** A task whose budget could not fit ONE
  restart reported **CONVERGED** and printed an eval rate over **zero evals**; a task whose BFGS
  polish was skipped for budget reported **`CONVERGED` and `OUT OF TIME` at once** (the polish is the
  half that gained 9.07 in the probe run, so a cycle without it is not a completed cycle —
  `out_of_time` now VETOES convergence, and the collector ERRORS on both flags, mutation-tested
  against the pre-fix files); and the collector's own consistency gate printed all 22 parameter names
  above the report title, because at top level in an `Rscript` the value of a call is auto-printed.
- **End-to-end, 5 starts on a contended laptop:** port gates passed on all three references (rel
  6e-16 to 2e-14), id 2 re-found **−1496.0128 exactly**, id 1 gained **+15.31 in 802 evals** — a
  fresh confirmation the incumbent is not converged — and a dispersed draw climbed −450,536 → −2,196
  in the same budget. ⚠ Run on SHORT budgets, so no start reached a real basin; what is verified is
  the PIPELINE and the GATES, not a survey result.
- ⚠ **A dispersed start is a LONG climb** — at sd 1.05 a draw scores ~−3×10⁵ against the cold init's
  −1.9×10⁴. Every task checkpoints every cycle, so **re-submitting the same array RESUMES**.

## 4. ⛔ STILL OPEN — ALL MARCUS'S

| # | ruling | status |
|---|---|---|
| **1** | the `kz` bracket: keep / re-bisect / delete | **OPEN.** Unchanged. Recommendation still **re-bisect wide**. |
| **2** | buy gate 7 by putting the deep ocean young? | **OPEN, RE-PRICED.** Gate 7's land axis improved **0.50 σ on its own** and `d14c_deep_ocean` barely moved (−4.89 → −4.53) ⇒ **the trade buys less AND is needed less.** |
| **3** | seasonal `tau_ex` adoption | **OPEN, RE-PRICED.** `tau_ex` fell to 0.828, gate 5's gap GREW, and the mechanism's best cell now covers **56 %** of it against 72 %. ⚠ The +0.268 yr numerator was measured in the OLD basin and has NOT been re-measured. |
| **4** | the `h_ml` basin | ✅ answered 08-31e. |
| **5** | ⭐ **NEW — adopt the polished mode?** | **OPEN.** §2 is the evidence: likelihood-driven, gates 4/7 better, gates 5/12a worse. Adoption moves the canonical mode into a different basin and re-prices everything again. |
| **6** | ⭐ **NEW — launch the survey (N, spread, budget)?** | **OPEN.** §3. The bundle is ready; the four settings are stated and yours to change. |

## 5. MEMORY

- **New:** `ccx_gates_repriced_new_basin.md`, `broken_gate_reports_nothing.md`.
- **Trimmed** (all figures are CONTENT, i.e. excluding each file's fixed rules header, which is how
  the budget is defined):
  - `MEMORY.md` **15223 → 13575 B total = 10054 B of content**, ✅ **inside** its 12 KB soft budget.
    The READ FIRST block was carrying findings rather than pointers; it is back to pointers, and the
    four gate-hygiene memories merged into ONE "silent-gate family" entry.
  - `INDEX_ccx.md` **16068 → 14190 B of content**, ✅ **inside** its 14 KB soft budget, while GAINING
    the re-pricing entry. The seasonal-`tau_ex` finding moved to `INDEX_ccx_ocean.md` (7503 B) where
    the routing rule puts it.
  - `INDEX_cmp.md` **13871 B of content — already inside**; it only looked over on total bytes.
- ⚠ **ONE FILE STILL OVER, DELIBERATELY: `INDEX_ccx_seas.md`, 15359 B of content vs 14 KB.** It is an
  ACTIVE arc of one-line pointers with nothing duplicated to merge, so cutting it would delete live
  findings rather than compress them. **The real fix is to move its CLOSED sub-arcs to
  `INDEX_ccx_arch.md` (7821 B, plenty of room) — and deciding which threads of an active arc are
  closed is yours, not mine.** Far under the 18 KB hard ceiling either way.

## 6. NON-OBVIOUS STATE

- ⚠ **`dg_vector()` returns TWO parameter lists and they are not interchangeable** — `$p` is the
  MODEL's list (for `ccx_spinup()`), `$pm` the FITTED 22 (for `ccx_par_to_unc()` and the objective).
  Handing `$p` to the objective raises "lacks parameters this build fits". [[ccx_two_param_lists]],
  hit again this session.
- ⚠ **A top-level `if (...) expr` / newline / `else` does not parse in R** — "unexpected 'else'".
  Inside a function the same code is fine, which is why it reads as correct. Brace it.
- ⚠ **Setting a logit parameter exactly AT its bound still round-trips** (`.from_unc(Inf)` returns
  the bound), so it is a USELESS mutation for a round-trip gate. Go **outside** the bound.
- **Everything else from 08-31e §6 stands**: the staged refit is still STAGED AND UNLAUNCHED with a
  FROZEN driver; `ccx_forcing_at(F, i)` takes a ROW INDEX; `diag_landed_gap_streams.R` is
  QUARANTINED; `refit_20260828_sigma_eff` is RATIFIED "do not adopt".

## 7. HOW TO RUN WHAT THIS SESSION ADDED

    Rscript calibration/diag_gates_in_the_new_basin.R                 # ~10 s, gates 4/5/7 + rulings
    Rscript calibration/diag_design_gates_at_mode.R                   # ~6 s, repaired
    Rscript calibration/diag_joos_irf.R <path-to-mode-file|arm>       # ~9 s, gate 12
    Rscript calibration/make_port_targets.R                           # ~5 s, re-run if the objective moves
    CCX_MS_ID=2 Rscript calibration/run_dispersed_multistart.R        # one start, locally

---

# ⭐ §8 — APPENDED 2026-09-01: RULING #1 CLOSED, AND THE FAILING-TEST LABEL WAS WRONG TWICE

Clean at `330d177`. **Suite 1282 / 6 FAIL / 2 skip** — same count as 08-31e, DIFFERENT composition.

## 8.1 THE `kz` BRACKET IS RE-BISECTED WIDE AND SHIPPED

`CCX_PARAM_TABLE$kz`: **[3942.5, 6528] → [4379.1, 8109.9]**, `init` 6244.5. Same recipe, same
default parameters, run against GLODAP's sourced **−175.26 ± 10.259‰ on the bottom box** at
**k = 3σ**. ⚠ **The floor RISES too — a RE-CENTERING, not only a widening.** Every mode file stays
strictly interior. ⭐ On this support the anchor turns over **INTERIOR at 6486 = 56 % of the box**:
the bracket was not what held `kz`.

⚠ **Re-measured before shipping** (`diag_kz_bracket_hml_sensitivity.R`): the "`h_ml` moves it under
1.5‰" justification was measured over **39.7–100 m**, which no longer contains the better basin's
**143.9 m**. It reproduces inside its own window (0.99‰); across [35, 195] the Δ¹⁴C at fixed `kz`
moves **6.25‰ = 10.2 % of the 3σ box**. Sufficient at k = 3, **not obviously at k = 1**.

## 8.2 WHAT MOVED, AND WHAT DID NOT

- **Every stored logpost moved** with the logit Jacobian: incumbent −1548.011 → **−1546.345**, new
  basin −1496.013 → **−1495.276**. ⇒ **the basin gap is +52.00 → +51.07, and ALL of it is PRIOR**
  (loglik gap unchanged at +37.82; prior share +14.18 → **+13.25**).
- ✅ **Gates 4/5/7, both re-priced rulings and every prior-z are BIT-IDENTICAL** (diffed). A support
  change must not touch a model-vs-obs measurement, and it did not.
- **`port_targets.csv` re-measured and now records its bracket**; the driver REFUSES a target from a
  different table. ⛔ **Three of my own band gates would have refused every mode file on disk** —
  each demanded bands EQUAL the shipped table, wider than any of them claims. Narrowed.

## 8.3 ⛔ ONE PREVIOUSLY PASSING TEST FAILS AND IS LEFT FAILING — YOURS

`test-likelihood.R:578`, `expect_lte(CCX_PARAM_TABLE$kz$hi, 7000)`: **8109.9 > 7000**. A deliberate
loose guard rail whose own comment says it exists so the band cannot be *"widened into uselessness
one re-bisection at a time"*. Its runaway guard (`hi < 10686`) still passes and the new bracket is
sourced where the old was not — but **how loose that rail should be is policy, not a code fix.**
Suggested: raise to a number that still excludes the 10,686 runaway and say in the comment that the
band now tracks a SOURCED k = 3σ box.

## 8.4 THE FAILING-TEST LABEL WAS WRONG TWICE

08-31e said all 6 "say ONE true thing — the stored modes are 21-parameter files".

- ✅ **FIXED — `test-prior-z.R`** was ERRORING on `no such parameter: seas_lag_p`. Unrelated to mode
  files; no refit would have fixed it. Now checks **both** limbs, which actually tests
  `R/calibrate.R`'s claim that the split kept the original prior on each.
- ⛔ **AND ADOPTION WOULD NOT FIX TWO MORE — IT WOULD INVERT THEM.** `test-mode-decode.R`'s two
  failures encode the CURRENT canonical's **retired [85,120] band** as their premise. Point
  `CCX_MODE_CANONICAL` at the polished mode and both premises dissolve: the band-blind idiom becomes
  CORRECT and `ccx_check_mode_decode()` stops erroring, so both fail the other way. **They need a
  file that genuinely carries an overridden band** — the 08-31 probe is one, on disk.
- ⇒ **HONEST TALLY: 3 fixed by adoption, 2 INVERTED by it, 1 unrelated (fixed), + the new §8.3 rail.**

## 8.5 ORDERING, RECOMMENDED

1. ✅ **`kz` bracket** — done, and it had to be first: the bracket IS the survey's coordinate system.
2. **Torch gate batch** `--array=0-2`, then the survey `--array=3-42`. ⚠ **Re-ship
   `port_targets.csv`** — it was re-measured under the new table and the driver now refuses a stale one.
3. **Adopt after the survey.** Adoption is decoupled from it (the survey reads modes by PATH;
   `CCX_MODE_CANONICAL` appears in those files only in a comment), so adopting first buys nothing and
   risks doing it twice. ⚠ And plan §8.4's two inverted tests INTO the adoption — they will fail the
   moment the canonical moves.

---

# ⭐ §9 — APPENDED 2026-09-01: TORCH IS READY TO SUBMIT. CLAUDE CANNOT SUBMIT IT.

Clean at `bfbfdd0`. Bundle built from that commit at `/tmp/ccx_torch_bundle.tar.gz` (2.0 MB, 236
files). **Nothing has run on Torch.** `ssh -o BatchMode=yes torch` returns **exit 255** — the
connection needs the NYU VPN, the gateway password, Duo and a Microsoft device-code, none of which
is non-interactive. **Every command below is Marcus's to run.**

## 9.1 THE SEQUENCE

    # on the Mac
    bash calibration/torch/make_bundle.sh          # prints the scp + untar lines
    scp /tmp/ccx_torch_bundle.tar.gz torch:/scratch/ms17839/
    ssh torch 'mkdir -p /scratch/ms17839/CarbonCycleEmulator && \
               tar xzf /scratch/ms17839/ccx_torch_bundle.tar.gz \
                   -C /scratch/ms17839/CarbonCycleEmulator && \
               rm /scratch/ms17839/ccx_torch_bundle.tar.gz'

    # on Torch
    cd /scratch/ms17839/CarbonCycleEmulator
    sshare -u ms17839                              # fairshare; below ~0.3 means queuing
    sinfo -o "%P %l %m %c"                         # ⚠ THE OPEN QUESTION: what is cs's wall cap?
    bash calibration/torch/setup_torch.sh          # Rcpp + a compile check + s/eval

    CCX_MS_PREFLIGHT=1 sbatch --array=0-2,21,42 --time=00:15:00 \
      calibration/torch/multistart.sbatch          # ~10 CPU-min, verifies EVERYTHING environmental
    grep -h PREFLIGHT logs/ccx_multistart_*.out    # and reports s/eval per node

    # size CCX_MS_MAXIT if that rate is much worse than ~0.6 s/eval, then:
    sbatch --array=0-42%10 calibration/torch/multistart.sbatch
    sacct -j <jobid> -X --format=JobID,State,ExitCode,Elapsed | head -12   # LOOK at wave one

    CCX_MS_OUTDIR=calibration/output/multistart_20260831 \
      Rscript calibration/collect_dispersed_multistart.R

## 9.2 WHAT IS VERIFIED, AND WHAT IS NOT

**Verified locally, end to end, through the real sbatch body via `SLURM_ARRAY_TASK_ID`:** the bundle
is self-sufficient; all 43 ids preflight LAUNCHABLE with every dispersed draw feasible first try;
4 concurrent C++ compiles race-free; checkpoint resume; peak RSS **213 MB** vs the 4 G request;
a production-shape task exits **13.1 min of a 15 min budget**, guard-stopped not clock-stopped;
`--vanilla` keeps an exported `R_LIBS_USER`; the port gate fires on a 1e-6 perturbation and passes
on a resumed reference task.

⛔ **NOT verified, and unverifiable from here: that Torch behaves like the Mac.** R 4.5.1 vs 4.5.3,
BLAS, compiler, NFS, modules, the account/partition strings. **That is exactly what the preflight
array is for, and it is why it runs before anything expensive.**

## 9.3 ⚠ READ THESE BEFORE JUDGING THE FIRST RESULTS

- **"OUT OF TIME" after round one is EXPECTED, not a failure.** 180 min gives ~29,000 evals against
  the 67,311 the 08-31e polish needed from a far better start. Re-submit the same array to resume.
  **Budget 2–3 rounds.** A real fault is a non-zero exit, a port-gate stop, or a task that gained
  nothing.
- **The polish is what makes a truncated round worth having** — 14 iterations gained **33.88**
  log-units in the local test. It could never have run before 09-01; see the CHANGELOG.
- **`%10` is the staged rollout.** It only protects if wave one is actually read.

## 9.4 STILL OPEN, UNCHANGED

`test-likelihood.R:578` (`kz$hi <= 7000`) fails and is deliberately left failing (§8.3). Adoption of
the polished mode waits for the survey (§8.4 — and two `test-mode-decode.R` failures will INVERT on
adoption). ⚠ **Suite 1282 / 6 FAIL / 2 skip**, composition per §8.4.
