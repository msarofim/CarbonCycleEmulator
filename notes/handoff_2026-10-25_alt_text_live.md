# HANDOFF 2026-10-25: BETA v1.1 live from 07d04b16 (the stamp guard and the Futures alt text)

**Supersedes** `notes/handoff_2026-10-24_v11_live.md`, which now points here. Written on Marcus's request ("Write the
handoff"), 2026-10-25.

- **Start here:** CHANGELOG **2026-10-24 (k) to 2026-10-25 (e)**; for the MCMC arc and the v1.1 release before that, the
  10-24 handoff and CHANGELOG 10-23 (u) to 10-24 (j).
- **main = the commit that logs this note as CHANGELOG 2026-10-25 (e), pushed.** No branches, no extra worktrees, nothing
  running. **The canonical is `hilda31fl`. The live app is BETA v1.1 CarboTope, republished by Marcus 10-25 from
  `07d04b16` and live-checked (d).** Tag `v1.1-beta-hilda31fl` marks `9c7ec7de`, the first v1.1 publish; the 10-25
  redeploy is not tagged.

## 1. Done since the 10-24 handoff

| | CHANGELOG | outcome |
|---|---|---|
| tag | 10-24 k | `v1.1-beta-hilda31fl` (annotated) at `9c7ec7de`, pushed |
| MCMC worktree | 10-24 l | smoke chains copied to `outputs/diagnostics/mcmc_launch_20261023_hilda31fl/smoke_chains/`; worktree removed |
| stamp guard | 10-25 a | `ccx_stamp_exclude()` (`R/provenance.R`): an `--out` outside the repo no longer stamps a clean tree `+dirty?`. Used by `promote_cmap_stability.R`, `promote_futures_ribbons.R`, `build_futures_ribbons.R` |
| alt text | 10-25 b | the Futures chart names its view in six alts (`APP_DL_FUTURE_CHART`, `app_dl_alt()`); its CSV title follows |
| suite + bundle | 10-25 c | @`07d04b16` 9,437 / 0 / 1; bundle served locally, every tab draws |
| live checks | 10-25 d | host serves `07d04b1`; every tab draws; pointers OK; scan UI ALL OK at both sizes; six alts live |

## 2. Decisions (Marcus, verbatim)

- "Tag v1.1-beta-hilda31fl and push the tag". "Remove the MCMC worktree after copying the smoke chains".
- "Fix the promote_cmap_stability stamp guard." "Yes, fix the alt text". "Yes, run the suite and build the bundle".
- "I published it; do the live checks".
- The six alt names are Claude's drafts, shown to Marcus in chat and not changed by him; they live in `APP_DL_FUTURE_CHART`
  (`app/R/downloads.R`).

## 3. Files

- **Code:** `R/provenance.R` (`ccx_stamp_exclude`), `calibration/promote_cmap_stability.R`, `calibration/promote_futures_ribbons.R`,
  `calibration/build_futures_ribbons.R`, `app/R/downloads.R` (`APP_DL_FUTURE_CHART`, `app_dl_spec_for`, `app_dl_alt`),
  `app/server.R` (`renderPlotFit`'s alt).
- **Tests:** `test-git-stamp.R` (+21: the helper, a control that reproduces the defect, a source check),
  `test-app-a11y.R` (+21: block 1b, all six views on the running server).
- **Records:** `outputs/diagnostics/suite_20261025_07d04b16{.log,_perfile.csv}`, `outputs/diagnostics/live_20261025_alt/`,
  `outputs/diagnostics/mcmc_launch_20261023_hilda31fl/smoke_chains/`. README's test line cites the 07d04b16 suite.
- **Bundles in `~/ccx_frozen`:** `bundle_20261025_07d04b16` (live), `bundle_20261024_9c7ec7de` (the first v1.1 publish),
  `bundle_20261024_51948d67` (still labeled v1.0: never publish).

## 4. Open (all Marcus's to choose; none started)

1. **Capacity before a live class:** raise the app's memory to 2–4 GB on Connect Cloud; cold start is ~8 s.
2. **Small windows:** at a panel smaller than a plot's margins, R refuses to draw and the live app shows Shiny's sanitized
   "An error has occurred" (k_plot, k_seasonal; seen 10-22 and 10-25 d). A phone at 375 × 812 draws fine. A friendlier
   message, or a smaller margin floor, would be a code change.
3. **Copy:** card 8's text (listed as Claude's draft since 10-13); whether the Keeling chart needs a note on flask's sparse 1960s.
4. **Tag the 10-25 redeploy** (for example `v1.1.1-…`), or leave the tag on the first v1.1 publish.
5. **The host's revision record** (memory size, timeouts) has not been read since 10-22 (`rsconnect:::clientForAccount(...)`,
   handoff 10-21 §3).
6. **Science, not app blockers:** the seasonal-lag triplet that keeps the sampler from converging (R-hat 1.11); the δ¹³C
   seasonal lead; card 8's unexplained share; flask CO₂'s MLO cycle 4.8 % larger and 2.2 d earlier than in situ; the model's
   MLO amplitude trend (+0.024 /yr against +0.009 observed).
7. **Housekeeping:** `INDEX_ccx.md` and `INDEX_ccx_gates.md` ~14.8 KB, `INDEX_ccx_app.md` also over its 14 KB soft budget;
   the marketing list.

## 5. Non-obvious state

- **Live checks: wait out the cold start.** A `check_live_pointer.py` run started right after a publish finds no plots and
  an empty CSV with no errors. Re-run a few minutes later. Recipe: headless Chrome on port 9333 (scratch profile), then
  `check_live_pointer.py 9333 https://carbotope.org/ 1440 900 <commit7>` and `check_scan_ui.py 9333 https://carbotope.org/
  <prefix> <W> <H>`; stop Chrome by PID. Build your own's FAIL there is by design.
- **The built-in browser pane at its default size** is smaller than the Keeling plots' margins: resize to 1440 × 900
  before judging a tab. Keep each in-page script under 45 s.
- **`renderPlotFit()` must stay short:** `test-app-phone-layout` 7 reads only the first 12 lines of its body and needs
  `app_fit_plot(res$value)` there. The alt logic lives in `app_dl_alt()` for that reason.
- **A `testServer` block sets every input in its first `setInputs`.** The session's first flush renders every output;
  charts drawn with NULL inputs raised a ggplot manual-scale warning (10-25 c). Which output was never named: both
  instrumented probes made the warning disappear.
- **Loading the app overwrites a global `f`:** use another loop variable (`.af_file`) in app-facing test runners.
- **A driver whose output path is an argument** passes `ccx_stamp_exclude(<out>)` to `ccx_git_stamp(exclude=)`;
  `test-git-stamp` fails a driver that takes `--out` and skips it.
- **The map's tie rule reads counts** (10-24 e): a stability file needs `n_lost` and `provenance$n_draws`; 400 draws via
  `diag_cmap_posterior_spread.R --n=400 --cores=8`, then `promote_cmap_stability.R`.
