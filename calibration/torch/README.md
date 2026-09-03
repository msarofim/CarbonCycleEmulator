# Torch bundle — the DISPERSED MULTI-START

> ## ⚠ RE-CUT FOR THE 25-PARAMETER MODEL, 2026-09-01k
>
> The ENSO split (22 → 25) landed after this bundle was first staged. Regenerating
> `port_targets.csv` (09-01j) made the bundle *runnable* at 25 parameters. **This pass asks the
> different question — what the survey should now DO** — and changes three things. The driver, the
> collector and the sbatch body carry the reasoning in full; this is the summary.
>
> ### 1. ⛔ NEITHER KNOWN BASIN IS A MODE OF THIS SPACE, SO THE SURVEY MUST PRODUCE ITS OWN BASELINE
>
> Both mode files are **migrated 21-parameter vectors whose ocean ENSO pair is exactly 0** — 0 is
> what they RAN, because the mechanism did not exist when they were fitted. Measured on the shipped
> objective: the migrated incumbent is **−1551.1222**, the migrated new basin **−1500.0507**, and
> moving the ocean pair to **+0.10 in each hemisphere with nothing else touched** is worth
> **+1.9087** at the new basin (+0.2947 at the incumbent). ⇒ **−1496.01 is not a number a
> 25-parameter result may be ranked against**, and neither is id 2's start value: that comparison is
> an optimum against a migrated point.
>
> **So the fixed head of the array grew from three ids to six.** Ids 3–5 carry the two known basins
> INTO this space, on the same machine and the same objective as everything they will be compared
> with:
>
> | id | start | log-post there |
> |---|---|---|
> | 0 | the COLD hand-set init | −19204.7216 |
> | 1 | the INCUMBENT, migrated (UNSEEDED control) | −1551.1222 |
> | 2 | the NEW BASIN, migrated (UNSEEDED control) | −1500.0507 |
> | **3** | **incumbent + ocean ENSO +0.10 each** | **−1550.8275** |
> | **4** | **new basin + ocean ENSO +0.10 each** | **−1498.1420** |
> | **5** | **new basin + the OBSERVATION-implied partition** (ocean +0.326 each, land ×1.734) | **−1507.6925** |
>
> Ids 1/2 are kept UNSEEDED beside 3/4 precisely so the pair says what the seeding was worth; the
> collector prints that difference. **Id 5 is the one that is conditionally WORSE on purpose** —
> it starts where GCB's measured ENSO sink slopes say the partition is, which the objective
> conditionally resists by −7.72. A conditional sign is a hypothesis about a refit, not a
> prediction of one (the gate-pricing arc measured 253 log-units of pure frozen-slice artifact),
> and 09-01g's compensating-error reading is exactly other coordinates absorbing an ENSO change.
> One task buys the answer.
>
> ### 2. ⛔ THE DISPERSION WAS DILUTED 8.4 % BY A BOOKKEEPING ARTIFACT
>
> `MS_SPREAD` is the per-coordinate RMS separation between the two known basins. Four of the 25
> coordinates were **migrated in both files**, so their separation is a property of the migration
> contract, not of the basins: the ocean pair differs by **exactly 0** and the land pair by
> **0.0100**, which is the retired scalar cut in half. Averaging those four in multiplied the whole
> dispersion by √(21/25) = 0.9165.
>
> **RMS over all 25 = 0.9592; over the 21 that at least one reference point FITTED = 1.0466.** The
> pool is now the second, derived from `attr(, "migrated")` so the next split fixes itself, and the
> excluded names are PRINTED. ⚠ **Do not read 0.9592 as "the basins got closer"** — over the shared
> coordinates the separation is what it always was.
>
> ⚠ **This does NOT give the four ENSO coordinates a scale of their own.** They are dispersed at the
> shared pooled sd, which is an ASSERTION: their own separation is structurally zero and there is no
> second basin to measure it against. `diag_enso_objective_leverage.R` is the check that it is not
> silly — at ~1.05 they land **6–9 conditional sds** out against **325–430** for the stiffest
> coordinates, so they are genuinely dispersed and are not what makes a dispersed start expensive.
>
> ### 3. ⚠ ROUND 2 IS NOT ROUND 1 REPEATED
>
> The old advice was "re-submit the same array to continue". At 25 parameters the Nelder-Mead
> simplex has **26 vertices**, so each task converges less far in the same wall than the
> 22-dimensional design assumed, and most tasks will still check out in the −1500s. Re-submitting
> all 40 spends three times the fairshare converging starts that are already 50+ log-units behind.
> **Round 2 = the six fixed ids plus the best dispersed ids from round 1's `summary.csv`.** See
> "Two rounds, and the second is not the first repeated" below.
>
> ### What did NOT change, and why
>
> * **N = 40 dispersed starts.** Still the one choice with no measurement behind it, and still 40:
>   the space is bigger, but the four new coordinates are the SOFTEST in it, so the added volume is
>   the cheap part of the search. Buying depth in round 2 beats buying width in round 1 — width
>   cannot be narrowed later, and a wider first array costs fairshare up front.
> * **`CCX_MS_MAXIT = 6000`.** The wall, not the cycle budget, is what stops a round: 3 × 6,000
>   evals is ~111 min at the ~0.37 s/eval a 2×-slower node implies, so a 180 min task does not
>   reach even two cycles. The guard already shortens restarts to fit; raising maxit would change
>   nothing a round actually executes.
> * **The dispersion CENTRE** is still the COLD init — neither known basin, so the survey is not
>   centred on an answer.
> * **The objective and the parameter table.** `port_targets.csv` still stands at `53ef03d`,
>   `n_par = 25`, kz [4379.1, 8109.9]; **nothing here re-ran it and nothing needs to.**
>
> **Preflighted 2026-09-01 on the Mac for ids 0, 1, 2, 3, 4, 5, 25 and 45** — all eight print
> `PORT GATE (a) PASSED`, and the three seeded start values above are what they reported. Both
> directions of the new fixed-id guard are mutation-tested.
>
> ⚠ **Use a FRESH output directory**: the default moved to
> `calibration/output/multistart_20260901_enso25`, which names the parameter set rather than a date.

> ## ✅ SHIPPED, SET UP, AND PREFLIGHTED ON TORCH — 2026-09-01
>
> Bundle extracted to `/scratch/ms17839/CarbonCycleEmulator`; `setup_torch.sh` run (Rcpp 1.1.0, C++
> core compiles in ~18 s). **Preflight array `0-5,25,45` (job 16731571): 8/8 COMPLETED, exit 0:0**,
> and **every start value matches the Mac to the digit**. `PORT GATE (a)` verified at **rel
> 1.1e-13 – 2.3e-13** against a 1e-8 tolerance, at all three reference points, on the compute nodes.
> **THE PORT IS VERIFIED.** Nothing has been optimised; the production array has NOT been submitted.
>
> ⭐ **MEASURED s/eval ON THE COMPUTE NODES: 0.245–0.455, median ~0.33** — the number that could not
> be obtained from the Mac, and essentially the ~0.37 this design assumed. **`CCX_MS_MAXIT = 6000`
> stands**: a full restart projects to 24.5–45.5 min of the 180 min budget, so three restarts plus
> the polish reserve fit. ⚠ **The LOGIN node measured 0.808 s/eval** — 2.4× worse, pure contention.
> Size on a job's number, never a login node's.
>
> ⛔ **TWO TORCH TRAPS COST AN HOUR AND ARE NOW FIXED IN `setup_torch.sh`** (`multistart.sbatch` was
> never at risk — it runs a script FILE). Both are in the `nyu-torch-hpc` skill.
> 1. **The r/4.5.1 module is a Singularity wrapper whose `Rscript -e` EATS `$`** — it re-quotes argv
>    into a double-quoted `bash -c`. `bp$pump_mode <- "N"` became `bp <- "N"`, so `base_params` was
>    the string `"N"`, the closure bailed at its spinup guard, and setup printed **`log-post at the
>    cold init = -Inf`**. ⚠ **That reads exactly like a broken port and is not one.** The tells:
>    **0.024 s/eval is far too FAST** (an early-return path, not a different answer), and R warned
>    `Coercing LHS to a list` once per call. ⇒ **The cold init is now GATED at 1e-8, not printed** —
>    the −Inf was printed, read, and very nearly believed.
> 2. **The container needs a writable `/tmp` bind source.** Inside a job Torch sets `SLURM_TMPDIR`
>    and `/state/partition1` is `drwxrwxrwt`; on the login node it is root-owned 755 and every
>    `Rscript` dies with `FATAL: container creation failed`, naming nothing about R.
>
> ✅ **The partition question is ANSWERED, and `sinfo` was the wrong command**: it reports
> `cpu_short infinite` because that is the *partition* limit. The **QoS** is the cap —
> `cpu_short` = **MaxWall 6 h** (not 4 h) and **`cpu=32` per user**, so `%10` is a choice, not the
> ceiling; `cs` carries **no partition QoS** and this account's `normal` QoS has no MaxWall, so the
> long-wall phase 2 looks available there. ⚠ Not proven — no job has been submitted with `--qos`.
>
> ⚠ Two benign NOTEs in every reference log: the mode files were fitted under `kz [3942.5, 6528]`
> and the shipped table is `[4379.1, 8109.9]`. **Feasible, so they are legal starts** — the driver
> says so by design, and the port gate uses `port_targets.csv`, not their stored logposts.

**Status: PREFLIGHTED ON TORCH. The production array is NOT yet submitted.** Everything below has been
smoke-tested on the Mac; nothing has touched Torch. **Claude cannot submit** — Torch needs the NYU
VPN, the gateway password, Duo, and a Microsoft device-code at `login.torch`. The steps are Marcus's.

## Why this is on Torch at all, and why the SERIAL driver is not

The standing verdict, said out loud every time: **a straight port of
`run_modefind_pump_arms.R` is MEASURED TO LOSE.** The Mac is ~2× faster per evaluation, Nelder-Mead
is serial, and one warm-started chain took 203 min — it would not fit `cpu_short`'s 4 h and would
gain nothing if it did.

**Torch wins only RESTRUCTURED**, and this is the restructuring: `run_dispersed_multistart.R` runs
**ONE start per process**, so N starts are an array instead of a queue. That is the load-bearing
experiment `handoff_2026-08-31e_the_basin.md` §4/§8.6 names — the incumbent and the 08-31e polished
mode are **two basins separated by a 21.53-log-unit barrier**, so no warm-started local search can
survey between them, and the polished basin (−1496.01, +52.0 over the incumbent) is **one basin, the
one the probe stumbled into.** The survey asks whether a third is better. ⚠ **Those two numbers are
21-parameter numbers**; under the shipped 25-parameter objective the same two points evaluate to
**−1500.0507** and **−1551.1222**, a gap of **51.07**, and neither is a mode — which is what ids 3–5
exist to fix.

⛔ **Restructuring the experiment was a methodological change and therefore Marcus's call.** This
bundle implements it; it does not decide it. **Nothing here adopts anything** — `CCX_MODE_CANONICAL`
is untouched, and the survey writes `start_*.rds` files no other code reads.

## The five choices this bundle makes, all of them yours to change

| choice | value | where it came from |
|---|---|---|
| dispersion **sd** | **1.0466** in u-space (0.9592 before the pool was fixed; 1.0493 at 22 parameters) | **MEASURED**: the per-coordinate RMS distance between the two KNOWN basins, recomputed at every run — pooled over the 21 coordinates at least one of them FITTED, not over all 25. `CCX_MS_SPREAD` overrides. |
| dispersion **centre** | the COLD hand-set init | Neither known basin, so the survey is not centred on an answer. |
| **budget per start** | 3 restarts × 6000 maxit × 6 cycles, **180 min** wall | `cpu_short` caps at 240 min; the task's own budget stops it at 180, so **"OUT OF TIME" is a clean exit 0 with a checkpoint, never a SLURM kill**. A restart would have to overrun its measured projection by **>3×** to reach the cap; the worst contention ever measured on this model was 1.61×. |
| **N starts** | 40 (`--array=6-45`) | Arbitrary, and the only one of the four with no measurement behind it. Kept at 40 for round 1 deliberately: buy DEPTH in round 2, not width in round 1. |
| **the fixed head** | 6 ids (`0-5`), of which **3 are ENSO-seeded** | **MEASURED**, and it is the 09-01k re-cut: the migrated mode files are not modes of this space, so the baseline a survey is judged against has to be produced BY the survey. |

## Partition: can we avoid the 4 h cap?

**What I know**, from the operational notes: `cpu_short` caps at **4 h** and typically has 244+ idle
nodes, so tasks start almost immediately. `cs` has 513 GB/node and no QoS *memory* limit, is **lower
priority** and less crowded. ⚠ **I do not know `cs`'s wall limit** — the notes record its memory
characteristics, not its time cap, and I have no way to check from here. One command settles it:

```bash
sinfo -o "%P %l %m %c"      # %l is each partition's time limit; %P marks the default
```

**But the cap is already cheap, and that changes the question.** Checkpoint/resume is tested: a
re-submitted array continues each task from its own checkpoint. So a 4 h cap costs about **2 min of
R startup and C++ compile per round**, plus queue time — not lost work. Against that, `cs` is
explicitly *lower priority*: with 40 tasks throttled 10 at a time, four waves queuing behind other
users can easily cost more wall-clock than the 2 min/round the cap costs. **On the numbers I have,
`cpu_short` + resume is likely to finish sooner**, and it is also the safer choice while the survey
is still unproven.

⭐ **The case where a long wall genuinely wins is the SECOND phase, not the first.** The survey has a
natural two-phase shape — screen wide, then converge the best few. Phase 1 is 40 short tasks and is
ideal for `cpu_short`. Phase 2 is a handful of long, uninterrupted climbs on the most promising
basins, and that is exactly what a long-wall, low-priority, uncrowded partition is for. If `sinfo`
shows `cs` allows a long wall, use it **for the top few after round 1**, not for the whole array.

⚠ **If you do move to a long wall, raise `CCX_MS_CYCLES` as well.** At 6 cycles × 3 restarts ×
6,000 evals the task exhausts its *cycle* budget at roughly 108,000 evals (~11 h at 0.37 s/eval), so
on a 12 h partition the cycle cap, not the wall, would stop it — and it would exit "restart budget
spent" rather than using the time you asked for.

## ⚠ EXPECT MOST TASKS TO COME BACK "OUT OF TIME" AFTER ROUND ONE — THAT IS NOT A FAILURE

Measured 2026-09-01 at production *shape* (same restarts × cycles, a budget the task actually
reaches, so the wall guard is exercised rather than short-circuited). A dispersed start climbed
**−263,312 → −2,609 in one restart (5 min) → −1,855 in two → −1,588 in three**, then the guard
shortened the last restart, skipped the polish and **exited 0 at 13.1 min of a 15 min budget** —
1.9 min unused, by design. Scaled to 180 min that is an exit around **157 min, ~83 min inside the
240 min cap**.

But arithmetic on the same numbers: 180 min at the ~0.37 s/eval a 2×-slower node implies is
**~29,000 evals**, while the 08-31e polish needed **67,311 evals to converge from an ALREADY GOOD
point**. A dispersed start begins far further out and reached only −1,588 against the basin's
−1,495.3 in this test. ⇒ **one round will land most tasks in the −1,500s and NOT converged.**

⭐ **The polish is what makes a truncated round still worth having.** In that same test the BFGS
polish, running for **14 iterations** on the budget reserved for it, gained **33.88 log-units**
(−1612.10 → −1578.22) — against −1588.10 for the identical run before the polish was reachable. A
round that ends "OUT OF TIME" still ends *polished*.

**That is what checkpoint/resume is for.** Re-submitting a task continues it from its own
checkpoint (tested). Budget **2–3 rounds**, and read a round of "OUT OF TIME" as progress, not as a
fault — a genuine fault looks like a non-zero exit, a port-gate stop, or a task that gained nothing.
⚠ **But re-submit a SUBSET, not the same array** — see the next section.

⚠ **A dispersed start is a LONG climb.** At sd 1.05 a draw scores ~−3×10⁵ against the cold init's
−1.9×10⁴, so a start may spend its whole wall budget and check out unconverged. That is expected and
is why every task **checkpoints every cycle**: re-submitting a task **resumes** it from its own
checkpoint instead of restarting it. (Measured 2026-09-01 at the 09-01k dispersion: id 25 draws at
−168,724 and id 45 at −229,287.)

## Two rounds, and the second is not the first repeated

**Round 1** — `--array=0-45%10`. Every fixed id, every dispersed id, one 180 min budget each.

**Round 2** — **the six fixed ids plus the best dispersed ids from round 1**, read off
`summary.csv`, e.g. `--array=0-5,<the best ~8>`. Same command, same output directory; each task
resumes from its own checkpoint.

⛔ **Do NOT re-submit `0-45` a second time.** The survey's question is "is there a THIRD basin", and
after round 1 a start 50+ log-units behind the best is not a candidate for it — it is a start whose
basin has already been identified as worse. Converging it costs a full task and changes no verdict.
The fixed ids are the exception and are always re-submitted: they are the BASELINE the verdict is an
ordering against, so they are the tasks that most need to be converged.

⚠ **What this trades away, said out loud** ([[no_power_null]]): a truncated start is ranked on a
value it had not finished climbing to, so a genuinely deep basin that happened to start slowly can
be dropped in round 1. That is a real cost and it is why the cut is the best **~8**, not the best 2
— and why the collector prints the OUT-OF-TIME flag beside every rank rather than hiding it.

## Run it

```bash
# 1. ON THE MAC -- build and ship the bundle (~2 MB, excludes data-raw/ and .git)
bash calibration/torch/make_bundle.sh          # prints the scp + untar lines

# 2. ON TORCH -- one-time setup: R lib on scratch, Rcpp, C++ compile check.
#    IT PRINTS THE MEASURED s/eval. Size the array on THAT, not on the Mac's.
bash calibration/torch/setup_torch.sh

# 3. THE PREFLIGHT ARRAY -- ~2 min/task, ~10 CPU-minutes for the whole thing.
#    This is the real gate: it loads the modules, imports Rcpp, COMPILES the C++
#    core, resolves every NFS path, checks the run-time inputs, verifies the port
#    against the shipped targets, draws each start -- and MEASURES s/eval on the
#    compute nodes themselves. Then it exits 0 without optimising.
CCX_MS_PREFLIGHT=1 sbatch --array=0-5,25,45 --time=00:15:00 \
  calibration/torch/multistart.sbatch
sacct -j <jobid> -X --format=JobID,State,ExitCode,Elapsed
grep -h PREFLIGHT logs/ccx_multistart_*.out        # read the s/eval it reports

# 4. SIZE THE RUN FROM WHAT STEP 3 MEASURED (see "Sizing" below), then launch
#    the whole flight. %10 IS the staged rollout: 10 tasks run, the rest wait.
sbatch --array=0-45%10 calibration/torch/multistart.sbatch
#    ...then LOOK at the first wave before walking away:
sacct -j <jobid> -X --format=JobID,State,ExitCode,Elapsed | head -12

# 5. COLLECT (either machine). The verdict is an ordering against the best
#    RE-CONVERGED known basin (ids 1-5), never against -1496.01 -- and it is
#    bounded by the OPTIMISER's convergence tolerance (MS_CYCLE_TOL, read from
#    the start files and printed), not by the port gate's 1e-8. 1e-8 is an
#    EVALUATION-identity bound; applied to two optimiser outputs it called a
#    -0.0000 difference "did NOT reach" on 2026-09-01.
CCX_MS_OUTDIR=.../multistart_20260901_enso25 Rscript calibration/collect_dispersed_multistart.R

# 6. ROUND 2 -- the fixed ids plus the best dispersed ids, NOT the whole array.
sbatch --array=0-5,<best ids from summary.csv> calibration/torch/multistart.sbatch
```

## Subset first, or the whole flight? — neither, quite

**Run the PREFLIGHT array, then launch the whole flight throttled.** A separate 5-task
*real-compute* gate batch is the wrong shape for what is still unknown: it would run for up to
3 hours to tell you things the 2-minute preflight already established.

Everything still unverified is **"Torch differs from the Mac"** — R 4.5.1 vs 4.5.3, a different
BLAS, a different compiler, NFS paths, the module environment, the `~/.bashrc` sandwich, the account
and partition strings, `R_LIBS_USER`. **Every one of those is decided in the first two minutes of a
task**, and the preflight exercises all of them, on the compute nodes, for ~10 CPU-minutes total. It
also returns the one number that cannot be measured from the Mac: **s/eval on a real node**.

What the preflight does *not* cover is long-run behaviour — the wall guard, checkpointing, the
polish, memory over 3 h. But that is pure R control flow: machine-independent, and all of it tested
locally end to end. The residual is memory drift over hours, and **`%10` covers exactly that**: ten
tasks expose it while thirty wait, and `scancel` is one command. ⚠ **The throttle only protects you
if you actually look at wave one** — that is the step to not skip, not the extra submission.

⚠ **If the preflight reports much worse than ~0.6 s/eval**, lower `CCX_MS_MAXIT` before step 4, or
every restart will be shortened and the task will spend its budget on stunted climbs.

⚠ **CHECK FAIRSHARE FIRST**: `sshare -u ms17839`. Below ~0.3 and jobs queue behind other users even
on an idle cluster; submit in smaller batches and prefer off-peak.

⚠ **`%10` IS NOT DECORATION.** It caps how many array tasks run at once, which does two things worth
having: it bounds the blast radius if something is wrong to 10 tasks rather than 40, and it limits
self-contention — 40 of our own tasks on shared nodes is exactly the situation that turned a measured
0.150 s/eval into 0.241 on this model. The wall guard adapts to that, but not needing to is better.

⚠ **THE GATE BATCH IS `0-5,25,45`, NOT `0-5`.** Ids 0–5 are all *fixed* starts — warm, at a known
point — and they never execute the dispersed-draw path: the redraw loop, the long climb from
~−2×10⁵, or the budget-shortened restart. A gate batch made only of them would certify a code path
the survey does not use. 25 and 45 are dispersed ids from inside the production range, which also
satisfies the HPC rule of a **≥5-task smoke test spread across the index range** before any array
with N > 20 (each failed task still burns fairshare).

## What the local smoke test found — all four fixed, all four verified

The whole bundle was extracted to a clean directory and driven through **the real sbatch body** via
`SLURM_ARRAY_TASK_ID`, 2026-09-01. It found:

1. ⛔ **`data-raw/downloads/nuclear14c/` was not in the bundle** (gitignored, 428 KB of the excluded
   3.4 GB tree). `ccx_nuclear_c14_annual()` reads it at run time through a default argument and, when
   absent, **warns and sets the industrial ¹⁴C source to zero** — a different objective, ~1e-3
   relative, with no error. **The port gate caught it on the first run**, which is exactly what a
   1e-8 bound on a pure evaluation is for; no looser tolerance would have. Now shipped, and
   `calibration/lib_run_inputs.R` asserts every run-time input **by name** before the wall budget, so
   the next missing file says so instead of surfacing as "the port is broken".
2. ⛔ **A resumed reference task failed the port gate spuriously.** Gate (a) read whatever the run
   *started from*, which after a checkpoint resume is the optimiser's progress, not the reference
   point — so re-submitting an array to continue it (this README's own advice) aborted with a false
   "this machine does not reproduce the objective". Gate (a) now always evaluates the **fixed**
   point; gate (b)'s ordering still uses the resumed one. Re-mutation-tested: it still fires on a
   genuinely perturbed target.
3. **The sbatch body hardcoded `/scratch/ms17839/...`**, so it could never be run anywhere else. The
   body is parameterised (`CCX_PROJ`, `CCX_SKIP_MODULES`); the `#SBATCH` directives stay literal
   because SLURM parses them before any shell runs.
4. ⚠ **`mkdir -p logs` inside the script does not create the directory `--output` writes to** —
   SLURM opens that file first. `setup_torch.sh` creates it, which is why setup is not optional.

**Also verified, not assumed:** `Rscript --vanilla` implies `--no-environ` but **keeps an exported
`R_LIBS_USER`** (measured — if it did not, every task would fail to find Rcpp for the same invisible
reason); **4 tasks compiling the C++ core simultaneously** all exit 0 with distinct outputs and no
cache race; **checkpoint resume** picks up at the right cycle. Local eval rate **0.186 s/eval** —
⚠ **size the array on the number `setup_torch.sh` prints on Torch, not on this one.**

## Resource sizing — measured, not assumed

| | measured | requested | margin |
|---|---|---|---|
| **peak RSS**, full task | **213 MB** (`/usr/bin/time -l`, 2026-09-01) | `--mem=4G` | **19×** — deliberately generous, the `g++` compile of `src/ccx_core.cpp` runs inside the job's own cgroup |
| **wall**, per task | budget 180 min, exits 0 | `--time=04:00:00` | **~57 min**; needs a **>3× overrun** of a measured projection to time out |
| **output** | 1.4 KB/task + 645 B checkpoint | — | ~80 KB for the whole 40-task array |
| **eval rate** | 0.199 s/eval on the Mac (median of 5, range 0.182–0.246) | — | ⚠ **re-read it from `setup_torch.sh` on Torch and re-size if it is worse than ~0.6 s/eval** |

⚠ **The rate is measured as a MEDIAN OF 5, not one call** — a single timed evaluation spread 35 %
across samples on an idle laptop, and it was being extrapolated 6,000× to project a restart.

⭐ **EVERY TASK VERIFIES THE PORT, not only ids 0–2.** A dispersed task evaluates the new-basin
reference point once (well under a second) and checks it against `port_targets.csv`. This is a
fairshare protection, not elegance: without it, an array submitted without its gate batch — or after
the parameter table moved — would spend **46 × 3 h** optimising a different objective, and only the
collector would ever notice. With it, a broken port kills every task in about two seconds.

## The port gate — read it before scaling

Ids **1** and **2** start at points converged on the Mac **under the 21-parameter objective**, so
they are the two the port targets were measured at — not points this build's optimiser must
reproduce. Each is gated **twice**, with each bound matching its own claim:

* **(a) the FIXED REFERENCE point is an EVALUATION**, so two machines must agree to floating point.
  The bound is **relative, 1e-8**, against `calibration/torch/port_targets.csv` — logposts measured
  on the Mac by `calibration/make_port_targets.R`, carrying host, commit, **and the parameter
  bracket they were measured under**. **This is the gate that catches a bad port** (a different
  BLAS, a half-copied data file, a stale build) — and it did, on the first run.
  Mutation-tested: perturbing a target by 1e-6 relative makes it fire.
  ⚠ **Re-run `make_port_targets.R` and re-ship the CSV whenever the parameter table moves.** The
  09-01 `kz` re-bisection shifted every logpost; the driver now REFUSES a target measured under a
  different bracket rather than reading the shift as a port fault.
* **(b) the FINAL value is an OPTIMISATION**, so the only available claim is an **ordering** — it may
  not come back worse than it started. That one runs on *every* task, not just the references.

⚠ **The target is NOT each mode file's stored `logpost`.** The 08-30 incumbent stores −1547.1579
and evaluates, under the shipped 25-parameter table, to **−1551.1222** — an offset of **−3.9643**,
of which **−4.7768** is the analytic ENSO prior-split constant and the remainder is the band and
objective drift that was already there. None of it has anything to do with any port.
Gating a port on it would spend most of the budget before the port was even considered.

⚠ **Re-run `make_port_targets.R` whenever the objective changes**, and re-ship the CSV. A target file
recorded on a different parameter count is refused; one recorded on a different objective is not
detectable, which is why the file carries its commit.

## What is NOT here

* **`adaptMCMC` is not on Torch**, so no sampler. This survey is a mode-finder. (The only R
  dependency the model has is **Rcpp**.)
* **No Hessian.** The serial driver computes one; the survey does not, because a Laplace covariance
  is not what a basin count needs and the polished mode's own Hessian already has one untrustworthy
  row (`h_ml` is step-unstable — 08-31e §8.4).
* **`data-raw/` (3.4 GB)** is excluded from the bundle. `DESIGN.md` is **not** optional — it is
  `REPO_MARKER` in `R/paths.R`, and without it `ccx_root()` resolves nothing.

---

## ROUND 2 OF THE 26-PARAMETER SURVEY (planned 2026-09-03, job `16837149`)

**WHY THERE IS A ROUND 2, AND WHY IT IS NOT ROUND 1 REPEATED.** Round 1 ran ids 0–39; **ids 40–45
were CANCELLED deliberately** (Marcus, on the marginal-value question below). Of the 30 tasks
complete at that point, **24 were dispersed draws and 23 hit the same basin**, so six more draws
**at the same dispersion** would have tested exactly what the first 24 tested. That is this
project's own standing caution: *"the bound is 4 dispersed starts at ONE dispersion, not a proof"*
([[no_power_null]]). **The count was never the limitation; the single dispersion is.**

⛔ **RUN THESE ONLY AFTER THE ARRAY HAS FULLY DRAINED.** Two separate reasons, and both have bitten:
1. `Rscript` parses the file **as it goes**, so editing a driver under a live task resumes it
   mid-token and blames a line that is fine on disk ([[never_edit_a_running_script]]). The pending
   `colClasses` provenance fix ships in this window, not before.
2. A pending task reads the driver from `/scratch` **at start time**, so re-shipping mid-array
   silently splits one array across two builds.

### (a) SETTLE id 12 — the one genuine open question in round 1
It finished at **−1508.7786**, 61.9 log-units above the basin, and is labelled `CONVERGED` — but its
last two restarts read `SHORTENED to maxit 2591 / 1348 by the wall budget` with `gain 0.0000`. So
"converged" here means *the cycle-gain test passed on restarts the wall had already truncated*, which
is a weaker claim than the label makes. ⚠ It reached only **cycle 2 of 6**.
A resume continues from its checkpoint with room to finish, and the two outcomes are diagnostic:
**stays at −1508.78 on full-length restarts ⇒ a real local optimum; drops to −1446.76 ⇒ it was budget.**

    sbatch --array=12 --time=05:30:00 \
      --export=ALL,CCX_MS_WALL_MIN=300 calibration/torch/multistart.sbatch

⚠ 5 h 30 is inside `cpu_short`'s **6 h** QoS wall, read off the machine (`sacctmgr`), not recalled
([[torch_qos_is_the_real_cap]]). Same `CCX_MS_OUTDIR` — the resume needs its own checkpoint.

### (b) PROBE A SECOND DISPERSION, which is the axis with actual power
Fresh outdir, because a different dispersion is a different experiment and the driver's own rule is
to **say in the directory name what the dispersion came from**.

    sbatch --array=6-10 --export=ALL,CCX_MS_SPREAD=0.5233,\
    CCX_MS_OUTDIR=/scratch/ms17839/CarbonCycleEmulator/calibration/output/multistart_20260903_ent26_sd0p5 \
      calibration/torch/multistart.sbatch

### ⛔ TWO THINGS DELIBERATELY **NOT** DONE, AND WHY
- **No 2× dispersion.** At the measured sd 1.0466 the draws already start at −144,561 (id 12) and
  −333,427 (id 25). Doubling it puts starts in numerically absurd regions where the budget is spent
  climbing back rather than exploring — **cost without power**.
- ⭐ **The more informative change is the dispersion CENTRE, not its scale, and it is not an env
  var.** Every draw is dispersed about the **COLD init**, so the survey tests "can the optimiser
  climb from anywhere". Dispersing about the **found optimum** would instead test "is there
  structure NEAR the answer" — which is the `h_ml`-ridge question and the one a posterior would care
  about ([[ccx_hessian_is_the_blocker]]). That needs a small code change to the start-point block
  and should be its own, reviewed piece of work, not smuggled into a resubmission.
