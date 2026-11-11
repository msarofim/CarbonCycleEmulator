# Handoff 2026-11-11: CarboTope minor-issues batch A

Supersedes `notes/handoff_2026-10-25_alt_text_live.md` for the app's live state. Read with `CLAUDE.md`,
`~/.claude/CLAUDE.md`, and memory `ccx_connect_cloud_deploy` (host, deploy, visit log, landing page).

## 1. Where things stand

- **Live app:** `8be0095a`, Posit Connect Cloud revision `01a1cac5-1226-1c4b-6f95-22f8d91a8e4f`, published by Marcus
  2026-11-11 13:21 UTC, live-checked (CHANGELOG 2026-11-11 g). 4 GB / 2 CPU; timeouts 1200 / 1800 / idle 5.
  Not tagged (Marcus's call).
- **Landing page:** https://carbotope.org is `docs/` on GitHub Pages (`main` /docs, custom domain verified, HTTPS
  enforced, Let's Encrypt to 2027-02-09). A push to `main` that touches `docs/` is live about a minute later. The Porkbun
  forward is gone. Steps and the certificate trap in `app/DEPLOY.md` "The landing page".
- **Last commit before this note:** `37818e6a` (the review). Working tree clean apart from this note and
  `outputs/diagnostics/review_20261111/log_problems.R`.
- **Next:** Marcus said "Go ahead with A; write the handoff first". Batch A = items A1–A16 of
  `notes/review_2026-11-11_minor_issues.md`. Group B (B1–B21) waits for Marcus.

## 1b. Progress (updated 2026-11-11, later the same day)

- **Batch A done** in `2bc18f62` (CHANGELOG 2026-11-11 i): all 16 items, new `test-app-review-20261111.R`, mutation
  script `outputs/diagnostics/review_20261111/mutate_batch_a.sh` (12/12). The landing preview image is live (docs/).
- ~~In flight: full suite at `2bc18f62`~~ (died with that session; superseded, see below).
- **Later still (CHANGELOG 2026-11-11 j, k, l):** serving the `2bc18f62` bundle found a batch-A bug: A11's rule hid
  the Download line while the chart drew, Shiny suspended the links, and 18 of 54 never got an address. Fixed in
  `34252dc7` (`suspendWhenHidden = FALSE` in `app_dl_server()`; gate A11b; browser check
  `outputs/diagnostics/review_20261111/check_dl_links.py`; old bundle quarantined). The suites then failed the U.S.-spelling
  lint on batch A's "no colour for" error; Marcus chose "Fix both" (message and A3's pattern; test edit flagged), `01cdaf99`.
- **LIVE since 19:00 UTC (CHANGELOG 2026-11-11 m):** `01cdaf99`, revision `01a1cbfb`; live checks all pass. Open: the
  box diagram on the host's font (litterfall arrowhead hidden; land-use arrow on Soil's corner) and, at the tuned 565 px
  on any font, the 92 and 69 arrows touching "warm" and "respiration". Card 2's facet titles draw their digits on the
  host (the gaps were this laptop's font). Headless Chrome 49106 is stopped.
- **Box diagram fixed (CHANGELOG 2026-11-11 n, o; Marcus: "Yes, fix the box diagram"):** the host draws in DejaVu Sans
  (matched to 102 px of 152,550). Fixed-size boxes, arrows on box edges, labels at a fixed gap, image 482 px tall at
  565. Gate `test-diagram-pixels.R` (both fonts; DejaVu from matplotlib's copy in the miniforge cache, or
  `CCX_DEJAVU_DIR`). Commit `64d91397`; suite 9,741 / 0 / 1 skip / 233 warnings.
- **LIVE since 20:38 UTC (CHANGELOG 2026-11-11 p):** `64d91397`, revision `01a1cc55`; live checks all pass and the live
  diagram matches the DejaVu render. GitHub Pages: the build for `0e032cef` failed to start (GitHub side, landing page
  unaffected); check that the next push's build succeeds (`gh run list --repo msarofim/CarbonCycleEmulator`).
- **Was the deploy candidate:** `~/ccx_frozen/bundle_20261111_64d91397`, served locally, all checks pass. Marcus publishes (command
  in CHANGELOG o), then the live checks in §3 step 5, `check_dl_links.py` on the live URL, and the live diagram against
  `outputs/diagnostics/diagram_font_20261111/render_diagram.R dejavu` (diagram area only; the footnotes wrap to the
  live width).
- **Tools added:** `outputs/diagnostics/review_20261111/shoot_imgs.py` saves a chart's own PNG (page-clip screenshots
  on a phone catch the fixed navbar); `validate_palette_cdp.py` runs the dataviz skill's palette validator in headless
  Chrome (no node here).

## 2. Decisions this session (with reasons)

- **Session logging live** since 11-02 (app/R/sessionlog.R): `CCX_SESSION` start/end JSON lines. Read with
  `Rscript outputs/diagnostics/usage_20261104/read_visit_log.R <dir outside the repo>`; only the first and last 1,500
  log lines are reachable (no paging parameter exists). "headless" = our checks.
- **Landing page, option 1** (Marcus): static page with an "Open CarboTope" button; a query string forwards to the
  app; the app is woken on the visitor's first interaction. Search engines are kept off the app itself by Connect
  Cloud's default robots.txt; the landing page is indexable. Tab descriptions (11-11 b) and the Substack sentence
  (Marcus's words, 11-11 c2) are live.
- **Y titles fitted at every width** (11-11 d): `app_fit_plot()` runs its y-title step above `APP_FIT_MAX_PX` when
  `.fit_y_title_maybe_tall()` flags the plot; plotmath titles keep their source (`attr "ccx_src"`) and wrap as stacked
  lines (`app_plotmath_lines()`). Everything else on wide charts is untouched. Gate: `test-app-phone-layout.R` 3c/3d.
- **Navbar name links to carbotope.org**, same tab (11-11 e). `windowTitle = APP_TITLE`.
- **Two test edits, flagged to Marcus** (his rule: don't edit a failing test to pass): phone-layout block 3's "plotmath
  left alone" became "plotmath wraps, same words, fits"; a11y block 4 now reads `navbarPage()`'s `lang` off the parse
  tree instead of matching the title line's text.

## 3. Batch A: the plan and the recipe

Items (details and screenshots in the review note): A1 box diagram clipping; A2 What-if takeaway rounding and minus
sign; A3 one fixed colour per scenario across Futures modes; A4 phone tables split numbers (`overflow-wrap: anywhere`
below 576 px in ui.R; removing it alone brings back sideways scroll, so tables need their own scroll frame); A5 phone
chart clipping (rv_diseq facet title, rv_repdc legend/labels, f_partition ticks/title, cm_map row labels,
cm_tension labels); A6 rv_repdc annotation over points, rv_gradient bar at the panel edge; A7 whole-year breaks;
A8 Pulse lab release-year label and small-value digits; A9 parameter-level map (title, plain names via
`app_param_desc()`, label size); A10 sidebar contrast, slider label overrun, pulse-size ticks, checkbox hanging
indent; A11 hide Download links under empty charts; A12 thousands separators in Build your own; A13 legends (one row
when it fits, row order, FaIR key, lower case after "Without:"); A14 retake the landing screenshot with scrollbars
hidden; A15 "What it is fitted to" spans from the data; A16 latent text bugs.

**Per change:** a test that fails first, then the fix, then a mutation (the repo's habit: every gate is
mutation-tested). Check visually with `outputs/diagnostics/axis_title_20261111/shoot_plots.py` (headless Chrome on a
debugging port; usage in its docstring) against the local app (`preview_start` name `ccx-app`, port 7788).

**Deploy recipe** (as in CHANGELOG 2026-11-11 f):
1. Commit; full suite in a frozen worktree: `git worktree add --detach ~/ccx_frozen/suite_<date>_<commit> <commit>`,
   link the 79 untracked `data-raw/downloads` entries per file (82 total), copy and edit
   `~/ccx_frozen/suite_20261111_8be0095a.sh`, run it in the background (~23 min), compare per-file counts with
   `outputs/diagnostics/suite_20261111_8be0095a_perfile.csv` (9,652 / 0 / 1 skip / 233 warnings), remove the worktree.
2. `bash app/make_deploy_bundle.sh ~/ccx_frozen/bundle_<date>_<commit> <commit>`; `diff -rq` against
   `~/ccx_frozen/bundle_20261111_8be0095a` (exclude `rsconnect`).
3. Serve the bundle locally through a temporary `.claude/launch.json` entry (revert with `git checkout --
   .claude/launch.json`); run `check_live_pointer.py` (its one FAIL is Build your own before "Run it", by design).
4. Marcus publishes (the auto-mode classifier refuses `deployApp()`): give him
   `Rscript -e 'rsconnect::deployApp("<bundle>", appId = "01a14244-5cc3-1951-7b06-9e2fb07beae3", account = "saraphreport", server = "connect.posit.cloud", forceUpdate = TRUE)'`.
5. Live checks: revision via `rsconnect:::clientForAccount(...)$getContent(id)$current_revision` (save without the
   upload URL); `time_tab_draws.py` (waits until drawn; use it over the fixed-wait checker on a slow network);
   `check_live_pointer.py`; `check_scan_ui.py` at 1440 × 900 and 375 × 812; `log_problems.R "<publish time>"`.

## 4. Non-obvious state and traps

- **Precomputes:** `data/*precompute*.rds` are md5-gated on the mode file and store some label strings (card 5's FaIR
  band label). A copy edit to a stored label needs a rebuild; `test-review-precompute.R` catches it.
- **CSS inside `sprintf()`** in ui.R (the phone `@media` block) needs `%%`; a rule pasted near it can land inside the
  phone-only block (11-11 e). Check the computed style in the browser.
- **Connect Cloud rewrites `<a>` hrefs** without `data-toggle` on click (memory `ccx_connect_cloud_deploy`); absolute
  external links are unaffected.
- **Visit log:** a visitor who arrives while the app sleeps passes Connect Cloud's wake page and is logged with
  `ref` = the app's own host.
- **Never edit a file an R process is running from**: stop `ccx-app` before an in-place mutation script.
- Headless Chrome: start one per job on its own port and kill it by PID; never a `pgrep` wait loop.
