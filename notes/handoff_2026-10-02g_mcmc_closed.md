# Handoff 2026-10-02 (g): the MCMC check is CLOSED (Marcus: "Stop here; keep holding"). The Laplace band was ~2× too wide; the carbon-cycle band is thin; the app stays band-free. Nothing is running

> **Session start.** Launch from `FaIRtoFrEDI/`, then `change_directory` here (CLAUDE.md). ⛔ Never use a bare `cd` in a
> Bash call; use `git -C` or absolute paths.
>
> **Read first:** this file, then CHANGELOG **2026-10-02 (u), (t), (s)**. Handoff (f) is history: its stage 1 has run
> and been read.

---

## 1. What the MCMC check found (CHANGELOG s, t)

- **Stage 1** (Torch job 18969240, 4 chains, an 8 h self-stop) did NOT converge by Vehtari et al.'s reference.
  - `beta_max` has R-hat 1.21 and ESS 14, with chain means 2.20–2.48. `h_ml`, `npp_tsens`, `imb_share_ocean_rest` and
    `fert_k` come next.
  - The log-posterior IS at the Gaussian typical set: mean −1421.9, sd 4.11, against −1421.6 / 4.06.
- **The band** (4,100 stage-1 draws through `build_futures_ribbons.R --draws=`, read by the new
  `calibration/diag_mcmc_band_by_chain.R`):
  - ⭐ **The held Laplace band was about 2× too wide.** The MCMC width is 0.41× the Laplace's for CO₂ and 0.58× for GMST.
    At vvH CO₂ 2150 that is 815 / 825.5 / 837 ppm against 812 / 828 / 851.
  - The four chains agree on the band to ≤ 3.4 ppm / 0.014 °C, which is 15–30 % of its narrow width.
  - The band is not still widening (late/early width 1.01 ± 0.11). ⚠ That null only sees a ≳ 20 % change.
  - The band's cells have R-hat 1.03–1.075, below the 1.01 reference.
  - GMST ±0.016 °C (vvM 2100) would be invisible at the app's scale: only the carbon cycle varies.
- **Ruling (u):** no stage 2; `APP_RIBBONS_HOLD` stands.

## 2. State

- **Running:** nothing (Mac or Torch).
- **Commits:** `0c97ac3` (handoff f), then `01f6df9` (s), `8259108` (t) and this handoff's commit (u). All pushed.
- **Torch** `/scratch/ms17839/CarbonCycleEmulator`:
  - `outputs/mcmc_check/chain_{1..4}.rds` hold stage 1 at 56,000 / 50,500 / 60,000 / 53,500 iterations. They are
    RESUMABLE by handoff (f) §2.5's stage-2 command (NO `rm`), provided the Torch tree is not re-shipped first.
  - /scratch IS flushed; the period was not checked.
  - `outputs/mcmc_smoke/` holds the smoke.
- **Mac, untracked** (Marcus's call whether to commit, about 2 MB):
  - `outputs/mcmc_check/`: the 4 chain files (checksum-identical to Torch's), `pooled_u.rds` (md5 `f64f4611…`, whose
    md5 the committed band artifact records), and the reader's `read_20261002_drop0.log` and `diag_20261002_drop0.csv`;
  - `outputs/mcmc_smoke/`, `outputs/diagnostics/smoke/`;
  - `carbotopecomment.9.26.26.docx` (Marcus's; leave it).
- **Committed evidence:**
  - `outputs/diagnostics/futures_ribbons_mcmc_stage1_20261002.{rds,log}` and `mcmc_band_by_chain_stage1_20261002.{log,csv}`;
  - `outputs/diagnostics/mcmc_modestart_20261001/`.
- **Code added this arc:**
  - `calibration/read_mcmc_check.R`;
  - `calibration/lib_mcmc_diag.R` + `tests/testthat/test-mcmc-diag.R` (22 expectations, 7 mutants caught);
  - `calibration/diag_mcmc_band_by_chain.R`.
  - The six test files that scan `calibration/` pass (263 expectations). The full suite was last run at `571b24b`
    (5534 / 0 / 0 / 4); `R/` and `app/` are untouched since.
- **Disposable:**
  - `~/ccx_frozen/ribbons_mcmc_01f6df9`. The band run's frozen copy; its `run_stage1.out` duplicates the committed log.
  - The (e) / (f) list: `~/ccx_frozen/{suite_20261001j, ribbons_trial_20261001, ribbons_c12af28, final_508b2bf,
    final_ca14204, final_571b24b}` and `/tmp/ccx_torch_bundle.tar.gz`.
- **Branches:** unchanged from (f) §4. The git-stamp branch `claude/youthful-blackburn-fbc009` is still unmerged; its lint
  would want `ccx_git_stamp()` in this arc's new drivers.
- **Memory:**
  - new this arc: `am_early_adaptation_stalls_chain`, `torch_rcpp_in_container`, `background_task_time_limit`;
  - updated: `laplace_fails_on_fertilisation_ridge`, `memory_keyspace_follows_launch_cwd`.

## 3. Lessons worth carrying (in memory)

- A smoke that adapts earlier than production says nothing about burn-in. Bracket the typical set from both sides
  against mode − χ²_d/2.
- A Bash `run_in_background` task is killed at about 29 min. A long local job goes to the Terminal panel, watched by a
  PID-based Monitor.
- When R-hat is bad on a parameter, measure convergence in the DELIVERABLE's units before buying more compute. Here the
  band's cells (1.03–1.075) were far better than `beta_max` (1.21).

## 4. Still open for Marcus (unchanged from (e) §5, plus one)

- **Whether to commit the stage-1 chains and pooled draws** (about 2 MB, untracked).
- **B8:** the verdict (§5) and the acts (§7) of `notes/assessment_2026-10-01_hilda33d_DRAFT.md`.
- **The copy in Claude's wording, his to edit:**
  - the card 4 and 5 sentences, the land-pools line, the fertilization caveat and the pulse-box sentence;
  - card 6's added sentence (bands), which could now cite the MCMC result.
- **The review list's §C** (13 older items), including the deploy checklist (both URLs are placeholders).
- **The A9 copy items:**
  - the emissions switch's blurb;
  - the N-retention arrow;
  - the imbalance panel's framing;
  - the AOD label;
  - the verdict phrases.
