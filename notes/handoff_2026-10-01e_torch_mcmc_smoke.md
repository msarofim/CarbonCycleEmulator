# Handoff 2026-10-01 (e): NEXT SESSION = run the MCMC SMOKE on Torch. Cards renumbered 1–7, the superseded branch deleted; everything else as in (d)

> **Session start.** Launch from `FaIRtoFrEDI/`, then `change_directory` here (CLAUDE.md). ⛔ Never use a bare
> `cd` in a Bash call; use `git -C` or absolute paths. **Load the `nyu-torch-hpc` skill before the first Torch
> command.**
>
> **Read first:**
> 1. this file;
> 2. `notes/handoff_2026-10-01d_rulings_applied.md`. It records the state of Marcus's 12 rulings, and it still
>    holds, except that its card numbers are from before the renumbering (the bands card is now **6**, the
>    stand-ins card **7**);
> 3. CHANGELOG **2026-10-01 (n)**, then **(l)** for the MCMC design and the failed Laplace check;
> 4. memory `laplace_fails_on_fertilisation_ridge.md`: why the band is held, and why a random-walk sampler will
>    mix slowly along that ridge.

---

## 1. Where things stand

- **Canonical:** `hilda33d`, objective #14, with the emissions interpolation piecewise-CONSTANT since 10-01 (k).
  Stored logpost **−1405.411447**; likelihood −1369.3386 on 26 rows.
- **App:** release **BETA v1.0 CarboTope**.
  - The Known-issues cards run **1–7**. The AIC card was retired, then the cards were renumbered on Marcus's
    instruction (the app was never deployed).
  - **No uncertainty band**: `APP_RIBBONS_HOLD`, Marcus's "Hold the bands".
- **The MCMC check** is built, dry-run and NOT submitted:
  - driver `calibration/run_mcmc_check.R`: adaptive Metropolis on the canonical's 33-name space, Laplace-seeded,
    overdispersed starts, a port gate, checkpointed and exactly resumable;
  - job `calibration/torch/mcmc_check.sbatch`: one chain per array task, `cs` partition, 36 h.
- **Marcus's routing (10-01):** "Torch (Recommended)", then: "write a handoff, with torch to run the smoke in the
  next session".
- **Suite at `571b24b`: 5534 passed, 0 failed, 0 errors, 4 skipped**
  (`outputs/diagnostics/suite_20261001_571b24b_all.log`). A headless app build confirms cards 1–7. The previous clean run, at
  `ca14204`, was 5534 / 0 / 0 / 4.

## 2. ⭐ THE NEXT SESSION: the smoke on Torch, step by step

**0. Preconditions.** Marcus is present and authenticates:
- Cisco VPN up;
- an interactive `ssh torch` (gateway password → Duo → the Microsoft device code at login.torch).
- If his `~/.ssh/config` has `ControlMaster` / `ControlPersist` on the torch host (the skill recommends it, and I
  could not read the file), later `ssh` / `scp` calls ride that socket with no prompt. Otherwise each one prompts.
- ⛔ **Every `sbatch` needs Marcus's go.** Ask once for the smoke, and again before production.

**1. Build the bundle at the commit being shipped** (on the Mac):
```bash
bash calibration/torch/make_bundle.sh
```
```bash
git -C /Users/MarcusMarcus/Documents/2026/CodeProjects/CarbonCycleEmulator rev-parse --short HEAD
```
- `make_bundle.sh` deletes any stale `/tmp/ccx_torch_bundle.tar.gz` and gates its own membership (every
  registry-named mode file is in the tarball).
- The sha goes into `CCX_MC_COMMIT`, because a Torch extract is not a checkout and cannot stamp itself.

**2. Ship and extract.** Both commands are printed by `make_bundle.sh`; run them from the LAPTOP side.
```bash
scp /tmp/ccx_torch_bundle.tar.gz torch:/scratch/ms17839/
```
```bash
ssh torch 'mkdir -p /scratch/ms17839/CarbonCycleEmulator && tar xzf /scratch/ms17839/ccx_torch_bundle.tar.gz -C /scratch/ms17839/CarbonCycleEmulator && rm /scratch/ms17839/ccx_torch_bundle.tar.gz'
```

**3. The R library.** `/scratch/ms17839/Rlibs/4.5` has held Rcpp since 09-01 (`calibration/torch/setup_torch.sh`).
If a job dies on `library(Rcpp)`, run `setup_torch.sh` on the login node. It sets `SLURM_TMPDIR`, without which
every login-node `Rscript` dies with "container creation failed".

**4. Submit the SMOKE.** Four chains × 600 iterations into their OWN directory.
- ⛔ **Delete any old `outputs/mcmc_smoke` first.** The driver RESUMES a chain file it finds. It stops on a
  mismatched `n` / `adapt` / `thin` or parameter vector, but would silently continue a matching one.
```bash
ssh torch 'cd /scratch/ms17839/CarbonCycleEmulator && rm -rf outputs/mcmc_smoke && CCX_MC_N=600 CCX_MC_ADAPT=300 CCX_MC_OUT=outputs/mcmc_smoke CCX_MC_COMMIT=<sha> sbatch --array=1-4 --time=00:45:00 calibration/torch/mcmc_check.sbatch'
```
- `sbatch` exports the submitting environment by default, so the `CCX_MC_*` settings reach the job.
- Expected time: 600 iterations × 0.59–1.08 s/eval (Torch nodes, measured 09-10), so 6–11 min per chain plus the
  C++ compile and spin-up.

**5. Read the smoke. This is the gate; do not scale past it.**
- `ssh torch 'sacct -j <jobid> --noheader -o JobID,State,ExitCode,Elapsed -X'`: all four COMPLETED, 0:0.
- Each of `logs/ccx_mcmc_<jobid>_<k>.out` must show:
  - the **port line** `mode hilda33d logpost: recomputed -1405.411447, stored -1405.411447 (diff …)` (the driver
    STOPS if |diff| > 1e-5, so a completed chain has passed it);
  - `chain k COMPLETE: 600 iterations`;
  - the acceptance rates. The Mac's 400-iteration smoke gave 0.31 overall and 0.40 after adaptation.
- `outputs/mcmc_smoke/chain_{1..4}.rds` exist, with seeds 20261002–20261005 recorded inside.
- **The rate:** minutes per 600 iterations from each log's last progress line. It sizes production: 1e5 × s/it.
- Optionally bring the four files home, FROM THE LAPTOP SIDE (the skill: never rsync from Torch inside an ssh
  session):
  `scp 'torch:/scratch/ms17839/CarbonCycleEmulator/outputs/mcmc_smoke/chain_*.rds' outputs/mcmc_smoke/`
  ⚠ Neither `outputs/mcmc_smoke/` nor `outputs/mcmc_check/` is gitignored (checked 10-01). Leave the smoke
  untracked, as `outputs/diagnostics/smoke/` is. Whether the production chains are committed (a few MB each) or
  only their reader's outputs is a call to make when they land.

**6. PRODUCTION, only on Marcus's go after reading the smoke.**
- Check fairshare first: `ssh torch 'sshare -u ms17839'`. Below ~0.3, jobs queue behind everyone.
- Then: `rm -rf outputs/mcmc_check` (the FIRST time only), then
  `CCX_MC_COMMIT=<sha> sbatch --array=1-4 calibration/torch/mcmc_check.sbatch`.
  - The defaults are n 1e5, adapt 3e4, thin 20, wall stop 34 h of the 36 h request.
  - A chain that reaches its wall checkpoints and exits 0. **Resubmitting the SAME command resumes it exactly**,
    and a finished chain exits at once.
- Expect ~16–30 h per chain.

**7. After production (on the Mac, from a frozen copy):**
- **Write a reader:** split R-hat and bulk ESS on each parameter and on the log-posterior, then pool the
  post-adaptation samples into a u-matrix `.rds`.
- **Run the band:**
  `Rscript calibration/build_futures_ribbons.R --draws=<that rds> --out=outputs/mcmc_check/futures_ribbons_mcmc.rds`.
  It uses the same machinery as the held Laplace evidence, so the two bands differ only in where the draws came
  from.
- **Rule:** whether a band ships (lifting `APP_RIBBONS_HOLD`) is Marcus's decision.
- ⚠ Judge convergence on R-hat and ESS, not acceptance. The fertilization ridge is curved, and a random walk in
  u-space crosses it slowly.

## 3. Traps (`nyu-torch-hpc` + this project)
- `Rscript -e` EATS `$` on Torch, because the Singularity wrapper re-quotes it. Run R from FILES only; the job
  script does.
- Never run a chain on the login node: SIGKILL past ~30 min of CPU, and 2.4× slower.
- `PROJ` is exported by Torch's `~/.bashrc` for another project. The job uses `CCX_PROJ_DIR`, which is
  `readonly`.
- The logs are absolute in the `#SBATCH` lines: `/scratch/ms17839/CarbonCycleEmulator/logs/`.
- `cs` has no QoS wall. `cpu_short` would cap the job at 6 h.
- **Local dry run** of the exact job script (done 10-01 n, it passed). Build the bundle, extract it to a scratch
  directory `<dir>`, then:
  `CCX_PROJ=<dir> CCX_SKIP_MODULES=1 SLURM_ARRAY_TASK_ID=1 CCX_MC_N=60 CCX_MC_ADAPT=30 CCX_MC_OUT=outputs/mcmc_smoke bash <dir>/calibration/torch/mcmc_check.sbatch`.

## 4. State
- **Running:** nothing (the app preview was never running this session).
- **Branches:**
  - `emissions-interp-constant` is DELETED (it was `35f38dc`, superseded by 10-01 k).
  - `claude/youthful-blackburn-fbc009` (the git-stamp branch, CHANGELOG (h)) is still UNMERGED. Its lint would
    want `ccx_git_stamp()` in this session's new drivers.
  - `claude/compassionate-leavitt-a7e631` is merged; its worktree remains.
- **Disposable:** the frozen copies under `~/ccx_frozen/` named `suite_20261001j`, `ribbons_trial_20261001`,
  `ribbons_c12af28`, `final_508b2bf`, `final_ca14204` and `final_571b24b`, plus `/tmp/ccx_torch_bundle.tar.gz`
  (rebuilt in step 1 anyway).
- `carbotopecomment.9.26.26.docx` is Marcus's; leave it. `outputs/diagnostics/smoke/` stays untracked.

## 5. Still open for Marcus (unchanged from (d))
- **B8:** the verdict (§5) and the acts (§7) of `notes/assessment_2026-10-01_hilda33d_DRAFT.md`.
- **The copy in Claude's wording, his to edit:** the card 4 and 5 sentences, the land-pools line, the
  fertilization caveat, the pulse-box sentence, and the one sentence added to card 6 (bands).
- **The review list's §C** (13 older items), including the deploy checklist (both URLs are placeholders).
- **The A9 copy items:**
  - the emissions switch's blurb (it also removes N deposition);
  - the N-retention arrow in the box diagram;
  - the imbalance panel's framing;
  - the AOD label;
  - the verdict phrases.
