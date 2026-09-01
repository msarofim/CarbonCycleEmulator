# Torch bundle — the DISPERSED MULTI-START

**Status: RUNNABLE, NOT YET RUN, and READY TO LAUNCH.** Everything below has been
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
one the probe stumbled into.** The survey asks whether a third is better.

⛔ **Restructuring the experiment was a methodological change and therefore Marcus's call.** This
bundle implements it; it does not decide it. **Nothing here adopts anything** — `CCX_MODE_CANONICAL`
is untouched, and the survey writes `start_*.rds` files no other code reads.

## The four choices this bundle makes, all of them yours to change

| choice | value | where it came from |
|---|---|---|
| dispersion **sd** | **1.0493** in u-space | **MEASURED**: the per-coordinate RMS distance between the two KNOWN basins, recomputed from their own mode files at every run. That is the separation a survey must resolve to be worth running. `CCX_MS_SPREAD` overrides. |
| dispersion **centre** | the COLD hand-set init | Neither known basin, so the survey is not centred on an answer. |
| **budget per start** | 3 restarts × 6000 maxit × 6 cycles, **180 min** wall | `cpu_short` caps at 240 min; the task's own budget stops it at 180, so **"OUT OF TIME" is a clean exit 0 with a checkpoint, never a SLURM kill**. A restart would have to overrun its measured projection by **>3×** to reach the cap; the worst contention ever measured on this model was 1.61×. |
| **N starts** | 40 (`--array=3-42`) | Arbitrary, and the only one of the four with no measurement behind it. Raise it if fairshare allows. |

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

**That is what checkpoint/resume is for.** Re-submit the same array and each task continues from its
own checkpoint (tested). Budget **2–3 rounds**, and read a round of "OUT OF TIME" as progress, not
as a fault — a genuine fault looks like a non-zero exit, a port-gate stop, or a task that gained
nothing.

⚠ **A dispersed start is a LONG climb.** At sd 1.05 a draw scores ~−3×10⁵ against the cold init's
−1.9×10⁴, so a start may spend its whole wall budget and check out unconverged. That is expected and
is why every task **checkpoints every cycle**: re-submitting the same array **resumes** each task
from its own checkpoint instead of restarting it.

## Run it

```bash
# 1. ON THE MAC -- build and ship the bundle (~2 MB, excludes data-raw/ and .git)
bash calibration/torch/make_bundle.sh          # prints the scp + untar lines

# 2. ON TORCH -- one-time setup: R lib on scratch, Rcpp, C++ compile check.
#    IT PRINTS THE MEASURED s/eval. Size the array on THAT, not on the Mac's.
bash calibration/torch/setup_torch.sh

# 3. PREFLIGHT THE WHOLE ARRAY -- ~2 s per task, no optimisation, no fairshare.
#    Proves every id draws a finite start and every task agrees on the objective.
for i in $(seq 0 42); do
  CCX_MS_PREFLIGHT=1 CCX_MS_ID=$i Rscript --vanilla \
    calibration/run_dispersed_multistart.R 2>&1 | grep -E "PREFLIGHT|Error"
done

# 4. THE GATE BATCH -- 5 tasks, and NOT ids 0-2 alone (see below)
sbatch --array=0-2,21,42 calibration/torch/multistart.sbatch
sacct -j <jobid> -X --format=JobID,State,ExitCode,Elapsed

# 5. ONLY IF THE GATE BATCH PASSES -- the survey, THROTTLED to 10 at a time
sbatch --array=3-42%10 calibration/torch/multistart.sbatch

# 6. COLLECT (either machine)
CCX_MS_OUTDIR=.../multistart_20260831 Rscript calibration/collect_dispersed_multistart.R
```

⚠ **CHECK FAIRSHARE FIRST**: `sshare -u ms17839`. Below ~0.3 and jobs queue behind other users even
on an idle cluster; submit in smaller batches and prefer off-peak.

⚠ **`%10` IS NOT DECORATION.** It caps how many array tasks run at once, which does two things worth
having: it bounds the blast radius if something is wrong to 10 tasks rather than 40, and it limits
self-contention — 40 of our own tasks on shared nodes is exactly the situation that turned a measured
0.150 s/eval into 0.241 on this model. The wall guard adapts to that, but not needing to is better.

⚠ **THE GATE BATCH IS `0-2,21,42`, NOT `0-2`.** Ids 0–2 are all *reference* starts — warm, already
at a known point — and they never execute the dispersed-draw path: the redraw loop, the long climb
from ~−3×10⁵, or the budget-shortened restart. A gate batch made only of them would certify a code
path the survey does not use. 21 and 42 are dispersed ids from inside the production range, which
also satisfies the HPC rule of a **≥5-task smoke test spread across the index range** before any
array with N > 20 (each failed task still burns fairshare).

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
the parameter table moved — would spend **40 × 3 h** optimising a different objective, and only the
collector would ever notice. With it, a broken port kills every task in about two seconds.

## The port gate — read it before scaling

Ids **1** and **2** start at points already converged on the Mac, and each is gated **twice**, with
each bound matching its own claim:

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

⚠ **The target is NOT each mode file's stored `logpost`.** The 08-30 incumbent stores −1547.1579 and
evaluates to **−1548.0112**: a −0.85 objective-drift offset that has nothing to do with any port.
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
