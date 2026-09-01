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
| **budget per start** | 3 restarts × 6000 maxit × 6 cycles, 210 min wall | Sized to `cpu_short`'s 4 h with 30 min of margin. The guard **projects** from a measured restart duration rather than merely reading the clock — `optim()` cannot be interrupted once entered. |
| **N starts** | 40 (`--array=3-42`) | Arbitrary, and the only one of the four with no measurement behind it. Raise it if fairshare allows. |

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

# 3. THE GATE BATCH -- ids 0/1/2 = cold init, 08-30 incumbent, 08-31e new basin
sbatch --array=0-2 calibration/torch/multistart.sbatch
sacct -j <jobid> -X --format=JobID,State,ExitCode,Elapsed

# 4. ONLY IF THE GATE BATCH PASSES -- the survey
sbatch --array=3-42 calibration/torch/multistart.sbatch

# 5. COLLECT (either machine)
CCX_MS_OUTDIR=.../multistart_20260831 Rscript calibration/collect_dispersed_multistart.R
```

## The port gate — read it before scaling

Ids **1** and **2** start at points already converged on the Mac, and each is gated **twice**, with
each bound matching its own claim:

* **(a) the START point is an EVALUATION**, so two machines must agree to floating point. The bound
  is **relative, 1e-8**, against `calibration/torch/port_targets.csv` — logposts measured on the Mac
  by `calibration/make_port_targets.R`, carrying host, commit and timestamp. **This is the gate that
  catches a bad port** (a different BLAS, a half-copied data file, a stale build).
  Mutation-tested: perturbing a target by 1e-6 relative makes it fire.
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
