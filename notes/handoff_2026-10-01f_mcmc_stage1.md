# Handoff 2026-10-01 (f): MCMC STAGE 1 is RUNNING on Torch (job 18969240, done ~22:35–22:45 10-01). NEXT SESSION = read it with `calibration/read_mcmc_check.R`; stage 2 and the band are Marcus's calls

> **Session start.** Launch from `FaIRtoFrEDI/`, then `change_directory` here (CLAUDE.md). ⛔ Never use a bare `cd` in a
> Bash call; use `git -C` or absolute paths. **Load the `nyu-torch-hpc` skill before the first Torch command.**
>
> **Read first:**
> 1. this file;
> 2. CHANGELOG **2026-10-01 (q)**, then **(p)**. (r) is this handoff;
> 3. memory:
>    - `laplace_fails_on_fertilisation_ridge.md`: why the MCMC check exists, and its state;
>    - `am_early_adaptation_stalls_chain.md` (new): why the smoke's numbers are not a burn-in measurement;
>    - `torch_rcpp_in_container.md` (new);
> 4. for the history of the check only: `notes/handoff_2026-10-01e_torch_mcmc_smoke.md` (the smoke plan, now done).

---

## 1. Where things stand

- **Canonical:** `hilda33d`, objective #14, emissions interpolation piecewise-CONSTANT. Stored logpost **−1405.411447**.
  Unchanged this session.
- **App:** BETA v1.0 CarboTope, Known-issues cards 1–7. **No uncertainty band**: `APP_RIBBONS_HOLD` holds it. Lifting
  it is Marcus's ruling, after the MCMC check.
- **The MCMC check:**
  - **The smoke PASSED** (job 18966349, 4 × 600 iterations). All four tasks COMPLETED 0:0, and the port gate matched to −2.04e−8.
    Seeds 20261002–05 are recorded, MaxRSS is 530–556 MB, and the rate is 0.47–0.54 s/iteration.
  - **Marcus asked to save Torch time** and to rule out runs that would need cancelling (CHANGELOG q, verbatim). Then
    he ruled **"Staged, 4 chains (Recommended)"**.
  - **STAGE 1 = job 18969240**, RUNNING since 14:35 10-01 on cs648 / cs662 / cs664 / cs667.
    - It runs production settings (n 1e5, adapt 3e4, thin 20, ckpt 500) with an **8 h self-stop**:
      `CCX_MC_WALL_MIN=480` under `--time=08:30:00`.
    - Each chain checkpoints and **exits 0** at the first checkpoint after 480 min, around **22:35–22:45**. Its log
      then ends with `wall 480 min reached: checkpointed at <iter>, resume with the same command`.
    - **Expected stop points** (rates at 42 min): chains 1 and 3 ~58.5k (0.49 s/it), chain 4 ~54k (0.54), **chain 2
      ~49k (0.585)**.
  - **Health at 42 min:**
    - lp −1416.7 to −1421.7, inside the Gaussian typical set (mode − χ²₃₃/2: median −1421.6, 95 % [−1430.8, −1414.9]);
    - acceptance 0.14–0.20 overall, and ~0.21 for chain 3 after the first adaptation at 1000;
    - stderr empty; MaxRSS 530–549 MB.
- **Code on Torch = `c631e50`** (the bundle; all 668 files md5-verified against the Mac). `main` is at this handoff's
  commit, pushed. Since `c631e50`, only Mac-side files changed: `make_bundle.sh`, the reader, its library and tests,
  and a comment in the job script.
- **Suite:** not re-run in full this session. `R/` and `app/` are untouched, and the six test files that scan
  `calibration/` pass (263 expectations, CHANGELOG q). The last full run was `571b24b`: 5534 / 0 / 0 / 4.

## 2. ⭐ THE NEXT SESSION, step by step

**0. Preconditions.** Run `ssh -O check torch`; "Master running" means no authentication is needed. Otherwise Marcus
re-authenticates (VPN, then an interactive `ssh torch`: gateway password → Duo → the device code).

**1. Did stage 1 end cleanly?**
```bash
ssh torch 'sacct -j 18969240 --noheader -o JobID,State,ExitCode,Elapsed,MaxRSS -X'
```
```bash
ssh torch 'for k in 1 2 3 4; do tail -3 /scratch/ms17839/CarbonCycleEmulator/logs/ccx_mcmc_18969240_$k.out; done; wc -l /scratch/ms17839/CarbonCycleEmulator/logs/ccx_mcmc_18969240_*.err'
```
- Expect COMPLETED 0:0 four times, each log ending at the wall message.
- **TIMEOUT** (killed at 8.5 h before the driver's own stop): the chain file holds the last checkpoint (≤ 500
  iterations lost). It is still readable and still resumable.
- **FAILED / NODE_FAIL** (`JobRequeue=0`, so a dead node fails the job): read the `.err`. A resubmit of the stage-2
  command resumes exactly. Ask Marcus first.

**2. Bring the chain files home, from the LAPTOP side.**
```bash
mkdir -p /Users/MarcusMarcus/Documents/2026/CodeProjects/CarbonCycleEmulator/outputs/mcmc_check
```
```bash
scp 'torch:/scratch/ms17839/CarbonCycleEmulator/outputs/mcmc_check/chain_*.rds' /Users/MarcusMarcus/Documents/2026/CodeProjects/CarbonCycleEmulator/outputs/mcmc_check/
```
- ⛔ **Leave Torch's `outputs/mcmc_check/` in place.** Stage 2 resumes from those files.
- `outputs/mcmc_check/` is not gitignored. Leave it untracked until Marcus says whether chains or only the reader's
  outputs are committed (a few MB per chain).

**3. Run the reader** (repo root; read-only, a few seconds):
```bash
Rscript --vanilla calibration/read_mcmc_check.R --dir=outputs/mcmc_check
```
It writes three files into `outputs/mcmc_check/`: `read_<date>_drop0.log`, `diag_<date>_drop0.csv`, and `pooled_u.rds`
(the pooled draws, with their window, chain md5s and seeds in an attribute).

**4. What to read, and put in front of Marcus.** The reader REPORTS; Marcus RULES.
- **The lp blocks (5000 iterations).**
  - Burn-in was done by ~1000 (the early check).
  - After 30k, look for DRIFT across blocks, which would mean non-stationarity.
  - Look for a chain sitting at a different LEVEL from the others: a stuck chain on the ridge, the failure this
    check exists to find.
- **R-hat and ESS, worst-first.** The window is one common span, (30k, the shortest chain's last kept iteration],
  about (30k, 49k] and ~960 kept samples per chain, because chain 2 is slow.
  - Vehtari et al.'s reference thresholds are printed as theirs: R-hat < 1.01, bulk- and tail-ESS > 100 per chain.
  - Expect the ridge names (`beta_max`, `fert_k`, `ndep_ret`) to be the slowest.
- **The posterior against the Laplace** (`sd_over_laplace`, `shift_in_laplace_sd`, u-space). This is the comparison
  the check exists for. 10-01 (l) found the Gaussian too wide along the ridge.
- ⚠ Judge on R-hat and ESS, never on acceptance ([[acceptance_rate_certifies_nothing]]).
- **Marcus's decision**, with numbers in hand:
  - (a) stage 1 suffices, so run the band;
  - (b) **stage 2**;
  - (c) re-read with `--drop=<iterations>` if the blocks show a later burn-in.

**5. STAGE 2, only on Marcus's go.**
```bash
ssh torch 'cd /scratch/ms17839/CarbonCycleEmulator && CCX_MC_COMMIT=c631e50 CCX_MC_WALL_MIN=570 sbatch --array=1-4 --time=10:00:00 calibration/torch/mcmc_check.sbatch'
```
- ⛔ **NO `rm -rf outputs/mcmc_check`.** That would destroy stage 1.
- The same n / adapt / thin / ckpt / t0 apply, and the resume check enforces them (mutation-tested). Each chain
  continues EXACTLY.
- **Remaining time to 1e5:** chains 1 and 3 ~5.7 h, chain 4 ~6.9 h, chain 2 ~8.3 h.
  - The 10 h request with a 9.5 h self-stop covers all four.
  - The default (drop both overrides, 36 h) also works. It only schedules less easily, and fairshare was 0.237.
  - A chain that is still short simply resumes again on the same command.
- Then repeat steps 1–4. A finished chain exits at once if resubmitted.

**6. The band, only if Marcus accepts convergence. Run it from a FROZEN copy** (never run a script an interpreter
might be editing).
- `git archive` of the commit into `~/ccx_frozen/ribbons_mcmc_<sha>/`.
- ⚠ **Copy in the two git-ignored inputs, which the archive omits:** `data-raw/downloads/nuclear14c` and
  `data-raw/downloads/glodap_c13c14_subset.csv`. Without `nuclear14c` the industrial ¹⁴C source silently becomes zero
  (make_bundle.sh's warning).
- ⚠ `build_futures_ribbons.R` sets `RB_ROOT <- getwd()`. So `--draws` and `--out` resolve **inside the frozen
  copy**, and the cwd must be its root.
  - Copy `outputs/mcmc_check/pooled_u.rds` into `<frozen>/outputs/mcmc_check/` first.
  - Then:
    `Rscript calibration/build_futures_ribbons.R --draws=outputs/mcmc_check/pooled_u.rds --out=outputs/mcmc_check/futures_ribbons_mcmc.rds --commit=<sha>`.
  - Copy the artifact and its log (`<frozen>/outputs/diagnostics/futures_ribbons_mcmc_<date>.log`) back into the repo.
- **Cost:** the Laplace run took 8.4 min per 1000 draws on 8 cores. Stage 1's ~3.8k pooled draws take ~32 min; the
  full 14k take ~2 h.
- ⚠ **A methodological choice to flag, not decide:** all pooled draws, or an even thin? The band's Monte Carlo error
  follows the ESS, not the draw count.
- It uses the same machinery as the held Laplace evidence, so the two bands differ only in where the draws came from.
  Lifting `APP_RIBBONS_HOLD` is Marcus's ruling.

## 3. Traps
- **Don't re-ship the bundle between the stages** unless the change is outside the model and the driver. The resume
  check guards the settings and the port gate guards the objective at the mode, but a driver change would make
  stage 2 a different program from stage 1.
- `outputs/mcmc_smoke/` holds the smoke chains plus the reader's test outputs. They are untracked, and their lp is
  **not** a burn-in measurement: the smoke adapted from ~25 moves and stalled ([[am_early_adaptation_stalls_chain]]).
- **The mode-struct RATCHET** (`test-mode-struct-lint.R`): a new driver that does `readRDS(ccx_mode_file(...))` must go
  through `ccx_mode_base()`, or it fails. Editing the ratchet's list is not the fix.
- `Rscript -e` eats `$` on Torch: run R from FILES. Never run a chain on the login node.
- Rcpp comes from the R container; `/scratch/ms17839/Rlibs/4.5` is empty and never mattered
  ([[torch_rcpp_in_container]]).
- `make_bundle.sh` now passes `--no-xattrs` (`c4fd484`). The 696 "Ignoring unknown extended header" lines of the 10-01
  extract will not recur.
- The reader refuses to write draws if the canonical's mode, structure, pins or name moved since the chains ran.
  `build_futures_ribbons.R` decodes against the CURRENT canonical.

## 4. State
- **Running:** Torch job **18969240** (stage 1), until ~22:35–22:45 10-01. Nothing on the Mac.
- **Torch tree** `/scratch/ms17839/CarbonCycleEmulator`:
  - `c631e50`'s bundle extracted over the 09-15 tree (no stale file in `R/`, `src/`, `data/`);
  - `outputs/mcmc_smoke/` (the smoke) and `outputs/mcmc_check/` (stage 1, LIVE);
  - logs `logs/ccx_mcmc_18966349_*` (smoke) and `logs/ccx_mcmc_18969240_*` (stage 1).
- **Commits this session** (all pushed):
  - `c631e50`: the driver's resume check on t0 / ckpt, the supplied-commit label, host and R recorded, the smoke's
    ckpt note;
  - `c4fd484`: `make_bundle.sh --no-xattrs`;
  - `1d59837`: the reader, `lib_mcmc_diag.R` and its 22-expectation test, the smoke record, the mode-start evidence;
  - this handoff.
- **Branches:** `main`, plus three others.
  - `claude/youthful-blackburn-fbc009` (the git-stamp branch, CHANGELOG h) is still UNMERGED (pushed; worktree
    present). Its lint would want `ccx_git_stamp()` in the new drivers, including `read_mcmc_check.R`.
  - `claude/compassionate-leavitt-a7e631` is merged; its worktree remains.
  - `isotopic-audit-20260909` and `luc-veg-debit` are local and untouched this session.
- **Disposable:** the frozen copies `~/ccx_frozen/{suite_20261001j, ribbons_trial_20261001, ribbons_c12af28,
  final_508b2bf, final_ca14204, final_571b24b}`, and `/tmp/ccx_torch_bundle.tar.gz`.
- **Untracked:** `carbotopecomment.9.26.26.docx` (Marcus's; leave it), `outputs/diagnostics/smoke/`, `outputs/mcmc_smoke/`.
- **Memory:**
  - new: `am_early_adaptation_stalls_chain` (in `INDEX_diag_conv`) and `torch_rcpp_in_container` (in `INDEX_infra`);
  - updated: `laplace_fails_on_fertilisation_ridge` (its state) and `memory_keyspace_follows_launch_cwd`;
  - Sizes: `INDEX_ccx_app` 14,297 B and `INDEX_ccx` 14,148 B, both just under the 14,336 B soft budget. Don't grow
    either without splitting.
- **An observation, no action taken:** this session was LAUNCHED in this repo, and its context still carried the
  shared root `MEMORY.md` through the 09-25 symlink. The launch convention is unchanged; changing it is Marcus's
  call (`memory_keyspace_follows_launch_cwd.md`).

## 5. Still open for Marcus
- **The MCMC readout** (step 4), then stage 2 and the band (steps 5–6).
- **B8:** the verdict (§5) and the acts (§7) of `notes/assessment_2026-10-01_hilda33d_DRAFT.md`.
- **The copy in Claude's wording, his to edit:** the card 4 and 5 sentences, the land-pools line, the fertilisation
  caveat, the pulse-box sentence, and card 6's one added sentence (bands).
- **The review list's §C** (13 older items), including the deploy checklist (both URLs are placeholders).
- **The A9 copy items:** the emissions switch's blurb (it also removes N deposition), the N-retention arrow in the box
  diagram, the imbalance panel's framing, the AOD label, and the verdict phrases.
