# HANDOFF 2026-10-12 (f) — the WTC refit is RUNNING (wave `20261012ff`); its dry run and landing are ARMED

> ⚠ **SUPERSEDED 2026-10-13 by `notes/handoff_2026-10-13_hilda31w_adoption.md`.** The wave landed. The land chain stopped at the module check's GATE 0 on the objective's noise floor, it was resumed after two rulings, and id 17 was ruled ADOPTED as `hilda31w`. Two things here turned out differently. (1) The first start finished at 22:33, not ~01:00: id 001 converged in 161 CPU-min. (2) §5's "don't merge the MANIFEST branch while the land chain runs" was more caution than needed: that merge touches only `data-raw/` and CHANGELOG, and neither is a `ccx_git_stamp()` path. It merged before both runs (10-12 gg).

**Supersedes** `notes/handoff_2026-10-12e_wtc_label_built.md` (which now points here). Written on Marcus's request
("Yes, write the handoff note"), 2026-10-12 ~21:00.

- main = `8bff440` before this note's commit, **pushed**. Repo clean under `R/`, `calibration/`, `tests/` (the armed
  chain REFUSES otherwise: keep it clean until the landing has run).
- **Start here:** CHANGELOG **2026-10-12 (ff)**; the rulings ledger `notes/citation_rulings_2026-10-12.md` §D (now with
  the 0.1 σ ruling); memory [[ccx_wtc_label_built]] and [[gated_off_state_is_not_zero]].
- **First thing to do:** read `~/ccx_frozen/20261012ff_wtc_armed.out` (§5), then the landing's logs.

## 1. What was done this session

| step | outcome |
|---|---|
| **Trash** (10-12e's ⚠) | Moot. #18's launch and land scripts were committed in each wave's `calibration/output/multistart_*/logs/`, and its chains in `outputs/diagnostics/obj18*_landing*/`. Only the `~/ccx_frozen` duplicates were lost. |
| **Driver extension `1e66077`** | (a) ⚠ **BUG: `ccx_migrate_par_set()` filled 0 for `bomb_share_NH` / `seas_T_lag`** (the generic gated-name loop) and called it "what the ancestor RAN". Every file ran 0.90 / 2.0. Neither 0 encodes, so the start was seeded at the box midpoints (0.875, 3), not at hilda29e's own model. Fixed via the absence resolvers (new `ccx_bomb_share_nh()`; `ccx_seas_t_lag()`). (b) `ccx_ms_reference_set()`'s ruled branch (`R/paths.R` `CCX_MODE_WTC_STRUCT/_PINS/_INCUMBENT`). (c) Dispersed draws take the two names FROM THEIR PRIORS (outdir suffix `_prior_bomb_share_NH_seas_T_lag`, start-file field `prior_draw`). ⚠ 10-12e's claim that `ccx_mode_start()` refuses hilda29e was WRONG: the failure was this silent fill. Mutation-tested. |
| **Launch** 19:46:02 | Frozen tree `~/ccx_frozen/20261012ff_wtc` at `1e66077` (downloads APFS-cloned, `diff -rq` identical). Port targets: incumbent **−1062.9494406**, cross-checked by hand: stored −1166.9497 + the pricing's +106.95 + the two names' prior/Jacobian −2.949 = +104.00 (measured +104.0003). Preflight 24/24 LAUNCHABLE. #18's recipe: 24 starts, 8 at once, 300 CPU-min, 3 × 6 × 6000, spread 1.0452. The 8 WORK processes were confirmed. |
| **Landing kit `c3514fb`** | A subagent screened the 8 landing tools; its main claim was verified by hand. **Five hand-built forcings lacked the label's per-year nuclear share** and would have STOPPED under it: promote GATE 5, `dg_run` / `dg_gateG` (module check, scorecard), `br_net_climate`, the ocean driver. Fixed + regression test (mutation-tested). `diag_obj18_basins.R` matches a (label, pins) table, since the WTC pins ARE #18 pass 2's. New **`calibration/diag_wtc_refit_read.R`**. |
| **Dry run on a synthetic file** `44643e8` | hilda29e relabelled at 0.90 / 2.0, in `~/ccx_frozen/20261012ff_wtc_dryrun`. Hessian, read, check, ocean and scorecard all run; the read's gates pass. The Hessian at hilda29e is NOT negative-definite under the new objective (3 positive eigenvalues: `kz_deep_frac`, `beta_max`/`fert_k`, `npp_frac_NH`), which shows where the refit will likely move. Record and README: `outputs/diagnostics/wtc_dryrun_20261012/`. |
| **Suite at `1e66077`** | **7978 passed, 2 failed (card 4, by design), 1 skipped**, 33.3 min beside the wave (`outputs/diagnostics/suite_20261012_1e66077.log`). |

## 2. Decisions

- **Marcus, verbatim: "I'm okay with 0.1 sigma unless that's a problem"**: the module check stops at **0.1 σ**. The 10-12
  option text's "> 0.01 sigma" was a slip in the question the previous session wrote; 0.1 σ is #17 / #18's rule and
  `fit_iav_module.R`'s `IAV_CHECK_TOL`. No code moved. The chain's `checkz` step refuses a check run at any other tol.
- **Mine, stated:**
  - The module check's reference is `CCX_MODE_OBJ18P2_MODULE_FILE` (its optimum IS the pins, verified), the same one
    hilda29e's own check used.
  - The prior draw is uniform on the box in parameter space, encoded through the table, asserted flat. The rnorm vector
    is drawn whole first, so no other coordinate's draw changes.
  - The WTC reference-set branch is live only while the canonical is NOT a file of the label. **Remove it at adoption**,
    as #16's and #18 p2's went.
  - The armed landing proceeds even if the dry run fails (it would stop at the same step, after the copy).

## 3. Files

- **New:** `calibration/diag_wtc_refit_read.R`; `outputs/diagnostics/wtc_dryrun_20261012/` (logs + README);
  `outputs/diagnostics/suite_20261012_1e66077.log`; this note.
- **Changed:** `R/calibrate.R` (migration WTC branch; reference-set branch), `R/model.R` (`ccx_bomb_share_nh()`),
  `R/paths.R` (`CCX_MODE_WTC_*`); `calibration/run_dispersed_multistart.R` (prior draws);
  `calibration/{promote_multistart_mode,lib_design_gates,lib_block_reopt,diag_ocean_climate_gobm}.R` (nuc_share);
  `calibration/diag_obj18_basins.R` (objective table); `tests/testthat/test-{wtc-label,ms-reference-set}.R`;
  `notes/citation_rulings_2026-10-12.md` §D; CHANGELOG (ff).
- **Outside the repo, `~/ccx_frozen/`:** `20261012ff_wtc_{launch,land,chain,armed,dryrun}.sh` (+ `.pid` / `.out`).
  ⚠ The land script copies `launch.sh` / `land.sh` into the wave's `logs/`, so those two reach the repo. Copy
  `chain.sh` and `armed.sh` into `outputs/diagnostics/wtc_landing_<date>/` by hand when committing the landing; #18
  lost its only records of these to the Trash.

## 4. Next steps (in order)

1. **Read the armed log** `~/ccx_frozen/20261012ff_wtc_armed.out`:
   - stage 1, the DRY RUN on the first finished starts: its logs are in
     `~/ccx_frozen/20261012ff_wtc_chaindry/DRYRUN_logs/`, and it exercised collect / basins / promote for the first time
     under the label;
   - stage 2, the LAND: logs in `outputs/diagnostics/wtc_landing_<date>/`.
   If a step failed, fix it, commit, and RESUME BY HAND without the land step, which refuses an existing outdir (#18
   pass 2 needed `outputs/diagnostics/obj18p2_landing_20261008/chain_resume.sh` for exactly this).
2. **Read the landing:** survey (converged / out of time / dead; 21 dispersed + cold + 2 refs); the basins' LP / NAT /
   NEAR; the WTC read per promoted mode:
   - the likelihood vs REF by row and group: IntCal is the row the label moved most (+96.79 at hilda29e, its rows now
     weigh ~6×);
   - where `bomb_share_NH` / `seas_T_lag` landed, and whether either is within 1 sd of a bound;
   - their correlation with `tau_ex` / `bomb_total` (a PREVIEW only);
   - the futures and the net climate effect.
   Then the module check's verdict at **0.1 σ**; GATE V on the scorecard.
3. **Commit the landing** (wave copy, RUN_PROVENANCE, the promoted refits, the logs, `chain.sh` + `armed.sh`); write
   CHANGELOG (gg).
4. **Marcus's rulings:** adopt or not, which basin if LP ≠ NAT, and **the mode's name (he names it)**. A second module
   pass only if the check says MORE at 0.1 σ.
5. **After adoption** (unchanged from 10-12e §4 step 4):
   - remove the WTC reference-set branch; move `CCX_MODE_CANONICAL_MODULE_CHECK`;
   - the bomb-share identifiability check (posterior sd, correlations with `tau_ex` and `bomb_total`; a fixed proxy as the
     fallback);
   - re-measure `ALPHA_AS_FCO3`; MCMC 4 × 200k; the futures bands; the app and card numbers (⚠ the app's own forcing
     builds must pass `nuc_share` too: check `app/` before the live run); the suite; the `v1.1` tag.
6. **Not on the refit's path:** the PHI_EFF NH product; the cite-as-is registry sweep and its "judgement" entries (ledger §B).

## 5. Non-obvious state

- **Running:**
  - the wave's launcher, **pid 78825** (`20261012ff_wtc_launch.pid`; its end line, in
    `~/ccx_frozen/20261012ff_wtc_launch.out`, is `WTC refit end <ts> rc N`);
  - the armed script, **pid 83390** (`20261012ff_wtc_armed.pid`).
  - Wait on PIDs (`kill -0`), never `pgrep -f` loops. Count work processes with
    `pgrep -f "R.*--file=calibration/run_dispersed_multistar[t].R"`.
- **⛔ Don't edit the chain while it runs.** `~/ccx_frozen/20261012ff_wtc_chain.sh` is run by the armed script twice:
  ~01:00 (dry run) and ~mid-morning (land). Bash reads scripts incrementally.
- **The land chain runs FROM THE REPO** (its R code at HEAD). No edits under `R/` or `calibration/` until it finishes.
- **Expected timing:** first starts finish ~5 h after launch (~01:00); the wave ends mid-morning (#18 took 13.5 h wall
  for the same recipe).
- **Worktrees** (all removable with `git worktree remove` once their logs are committed):
  - `~/ccx_frozen/20261012ff_wtc` (the run: keep until landed);
  - `_dryrun` (synthetic tools dry run; logs committed);
  - `_chaindry` (created ~01:00 by the armed dry run);
  - `suite_20261012_{9967a63,f2af594,1e66077}` (logs committed).
- **The MANIFEST task** (separate session, worktree `.claude/worktrees/compassionate-chatelet-52df58`, branch
  `claude/compassionate-chatelet-52df58`) has ONE unmerged commit, `d1a09fe` ("MANIFEST rows for the nine
  nuclear-industry 14C files ... access date unknown, recorded as file mtime"). It touches
  `data-raw/downloads/MANIFEST.csv`, `data-raw/download_data.R` and possibly `CHANGELOG.md`. Before merging, check that
  its sha256 values equal `attr(readRDS("data/forcing_nuc_nh_share.rds"), "provenance")$file_sha256`. **Don't merge
  while the land chain runs** (an untracked/changed input stamps `+dirty`: memory `stamp_dirty_from_untracked_input`).
- **The new objective's logposts are NOT comparable to #18's**; compare the new mode against REF (hilda29e under the
  label at 0.90 / 2.0) on likelihood, which the WTC read does.
- **Still Marcus's** (unchanged): the merged remote branch `origin/claude/recursing-hermann-a2f965`; the flux-trace
  default; the app never SHOWING `retried` / `converged`; the copy worklist; deploy items; card 4's two by-design
  failures; the untracked `CarboTopecomments.10.11.26.docx` / `carbotopecomment.9.26.26.docx` /
  `carbotopecomments.10.2.26.docx` in the repo root (tracked by convention when he sends them; not touched).
- **Memory sizes:** `INDEX_ccx.md` 14.9 KB (over its 14 KB soft budget, under 18 KB hard); `INDEX_conv_build.md` 13.6 KB.
