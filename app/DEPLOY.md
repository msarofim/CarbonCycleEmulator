# Deploying the app

```bash
Rscript -e 'shiny::runApp("app", launch.browser = TRUE)'
```

`.claude/launch.json` in this repo holds the same command as a named config
(`ccx-app`, port 7788) for editor/agent launchers.

⚠ **A Claude Code session launched from a SIBLING repo cannot see it.** The
harness resolves `launch.json` from the SESSION root, and the standing rule is to
launch sessions from `FaIRtoFrEDI/` (the memory keyspace follows the launch cwd).
Such a session has two options, and the second is cleaner:

1. temporarily add a `ccx-app` entry to `FaIRtoFrEDI/.claude/launch.json` — that
   file is TRACKED, so revert it afterwards (`git checkout -- .claude/launch.json`).
   `cwd` outside the project root is rejected, so the command needs an absolute
   `setwd()` in its `runtimeArgs`;
2. start it from this repo directly with the command above and point the browser
   at `http://127.0.0.1:7788`.

## ⚠ BEFORE THE PUBLIC BETA GOES OUT

The app ships as **beta `v1.0-hilda29l`**, and its seventh tab ("Known issues")
is the point of the release: it puts each remaining flaw to the reader and asks
whether it is a deal-breaker, fixable or acceptable. Three things must be true
before the link is posted.

1. **`APP_FEEDBACK_URL` must be set in `app/global.R`** to the Substack post the
   comments live under. Until it is, every card renders a visible "the comment
   link is not set in this build" warning instead of a link, and the tab's header
   says so too — deliberately, because a dead link costs exactly the feedback
   this release exists to collect. `APP_REPO_URL` is the same: it pointed at a
   GitHub repo that does not exist until 2026-09-22 and is now a placeholder.
   `tests/testthat/test-review-cards.R` asserts the placeholder machinery is
   wired; **update that test when you set the URL, do not delete it.**
2. **Re-time startup on an idle machine.** See below.
3. **Check the hosting plan's active-hours and concurrent-connection limits**
   against the expected traffic. A post that reaches a few hundred readers in
   its first hours can put more simultaneous sessions on a free tier than it
   allows, and each cold session pays the full start-up.

## Start-up cost — the number a visitor actually pays

Start-up compiles the C++ core, runs the 1750 spin-up and one historical
integration. **Measured: 73 s on an idle M4; 2.8 min under load (four Julia
jobs); 148 s in the 2026-09-22 contended check.** The "~20 s" this file used to
claim is a warm-compile-cache number and is not what a first visitor sees.
`APP_WARMUP_NOTE` in `global.R` tells the reader to allow three minutes, and the
first tab renders it; the post should say the same thing.

Everything after start-up is live: a counterfactual rerun is ~60 ms, three
coupled SSP futures ~0.5 s, a matched pulse pair over 1750–2300 ~0.65 s.
Nothing is precomputed, so no cached figure can fall out of date with the model.
**The "Known issues" tab adds four runs the app does not otherwise make** (a gate
run to 2025, an ENSO knockout, a 1000-year pulse pair, and the control mode's own
spin-up and run). They are memoised and computed on FIRST VIEW of that tab, not
at start-up — measured at about 6 s in total, contended — so a visitor who never
opens the tab never pays for it.

## Dependencies

`shiny`, `bslib`, `ggplot2`, `Rcpp`. Deliberately **not** plotly, DT or shinyWidgets —
shinyapps.io memory is the binding constraint and base ggplot covers every panel.

## What has to ship

The app reads from the repository root, so deploy the whole tree, not just `app/`:

| Path | Why |
|---|---|
| `R/` | the model |
| `src/ccx_core.cpp` | compiled at startup |
| `data/*.rds` | observations, forcings, the FaIR climate module |
| `calibration/output/refit_20260920_hilda29l_obj13_hilda_csl3/mode_fit_pumpN.rds` | **the parameter set the app runs on.** This is the canonical mode, resolved by `ccx_mode_file()` (`R/paths.R`), which is the ONE place its path is named — take the path from there rather than from this table. It moved here 2026-08-27; the old `pump_arms/mode_fit_pumpN.rds` was fitted before the seasonal-NEP isotope fix changed the objective and is quarantined. `mode_fit.rds` has never existed. Omit the file and the app falls back to uncalibrated defaults SILENTLY (the banner is the only report) |
| `DESIGN.md` | `.find_root()` locates the repo by looking for this file |
| `calibration/lib_design_gates.R` (+ `lib_seas_limbs.R`, `lib_glodap_obs.R`) | **the gate kernels the "Known issues" tab measures itself with.** Sourced lazily on first view of that tab, never at start-up. Omit them and the cards that need them render their reason in place of their number — a visible degradation, not a silent one, but the review tab is then half-useless |
| `calibration/output/refit_20260919_hilda31pe_obj13_hilda_c_seasml0/mode_fit_pumpN.rds` | the seas_ml-0 **control**, which card 6 runs beside the canonical. Resolved by `ccx_mode_file(CCX_MODE_SEASML0_CONTROL)` — take the path from there, not from this table |

`data-raw/` is **not** needed at runtime and is large. Exclude it.

## The parameter banner

`app/global.R:app_params()` resolves the parameter set in this order, and the banner
at the top of every tab reports which one it landed on:

1. `calibration/output/posterior_draws.rds` → "calibrated posterior"
2. the first of `ccx_mode_file(CCX_MODE_CANONICAL)` (today
   `calibration/output/refit_20260920_hilda29l_obj13_hilda_csl3/mode_fit_pumpN.rds`), then
   `calibration/output/mode_fit.rds`, that exists AND carries this build's
   parameter set (`ccx_mode_carries_build()`; a pinned canonical's held names
   come back through `ccx_mode_par_with_pins()`) → "posterior mode" (so a stale
   fit from an older parameter table is ignored rather than silently misaligned)
3. otherwise → "uncalibrated defaults", with the warning styling

**Two of the fitted names are FORCING parameters** (`bomb_total`,
`luc_scale`), not model parameters, and `ccx_default_params()` has no slot for
them. `app_build_forcing()` and `app_run_coupled()` in `global.R` exist to carry
them onto every forcing the app builds; call those, never `ccx_build_forcing()`
or `ccx_run_coupled()` directly. Skipping them is worth ~5.8 ppm at 2024 and
nothing would report it. See `calibration/diag_app_params.R`.

Do not remove the banner. What the model is fitted to changes what every number on
every tab means.
