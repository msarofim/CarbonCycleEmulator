# HANDOFF 2026-10-22: the δ¹³C lead is half sampling; the refit forecast; redeployed; the live pointer bug

**Supersedes** `notes/handoff_2026-10-21_draft_strings_h2_seas8.md`. Written on Marcus's request ("Then write a handoff"),
2026-10-22.

- **Start here:** CHANGELOG **2026-10-21 (v)–(z)** and **2026-10-22 (a)–(c)**; this note's §3 item 1.
  Memory: `ccx_seas8_tracer_conflict_hilda31w` (its (x), (z) and 10-22 (a) sections), `ccx_connect_cloud_deploy` (10-22 c,
  the href-rewrite trap), and their lines in `INDEX_ccx_seas.md` / `INDEX_ccx_app.md`.
- **main = the commit that adds this note, pushed.** No branches, no worktrees, no servers.
- **Live app = revision `01a16341-24ac-cda7-525c-55e82f97f7ec` from `8d1c5982`** (published 2026-10-22 10:56 UTC by
  Marcus). Everything in it is checked live except the Known-issue pointer, which is broken on the host (§3.1).

## 1. What was done

| | commits | outcome |
|---|---|---|
| items 8, 9, 10 | `9a6fc4d1` | Marcus chose the test-based drafts: 9 "after calibration it still responds by the wrong amount"; 10 the uptake / share decomposition in place of the mixing explanation; 8 first the timing draft. 10-15 card-8 pins keep their absent-halves; new `AC_CHECKS_1021C` + mutation. (v) |
| suite @ `9a6fc4d1` | `567b9eb2` | 9,180 / 0 / 1 skipped. (w) |
| T8d, the lead's sampling | `95ca2bf3`, `baa66736` | Marcus doubted that 4 days matters in a monthly model. It does in the row (45 years per year, σ = 4–10 days of phase; 4.4 d costs 22.5). But half the lead is sampling: flask CO₂'s cycle runs 2.2 d ahead of in situ in both Scripps and NOAA, and the δ¹³C row is flask while the CO₂ row is in situ. Same-flask lead 2.2 d in both networks. The lead shrinks 6.9 → 0.7 d from the 1980s to the 2020s. (x) |
| item 8 revised | `6aef5d7a` | "… the ¹³C cycle measured in air samples runs about four days ahead of the continuously measured CO₂ cycle. About half of that comes from the two sampling methods, …" (y) |
| T8c on flask CO₂ | `153ff068`, `8d1c5982` | `CCX_SEAS8_CO2SEAS=MLO_SIO_FLASK`. The δ¹³C rows' joint-fit loss falls 18.7 → 7.0 (predicted ~6); the δ¹³C-only fit reproduces the canonical bit for bit. (z) |
| T8e, the refit forecast | `ebdb89e6`, `c533da46` | Newton step on the stored Hessian, validated against T8c's block refit (forecast 12.6 vs measured 15.3), verified by evaluation. A full flask-scored refit is the block refit (+15.3) plus about 0.3. Gains are only on the two MLO seasonal rows; the app's headline numbers move ≤ ~0.1 %; the MLO CO₂ cycle 6.92 → 7.26 ppm while the app plots in situ (6.81). (10-22 a) |
| suite @ `8d1c5982` + bundle | `f621896e` | 9,181 / 0 / 1 skipped, 21.6 min. Bundle 116 files, 7.3 MB, served locally: every tab draws. (10-22 b) |
| redeploy + live checks | `b0d95096` | Revision `01a16341`. Everything passes except the see-card pointer (§3.1). (10-22 c) |

## 2. Decisions (Marcus, verbatim or his chosen option)

- Items 8, 9, 10: the recommended option each time ("Timing draft", "after calibration", "Decomposition draft"); then
  "Update the pins".
- "I'm surprised that a 4 day offset at Mauna Loa matters for a monthly model." → "Run tests 1 and 2".
- On T8d: "Measure first (Recommended)" (the T8c rerun on flask CO₂); "Revise for sampling (Recommended)" (item 8).
- "Run the suite and build the bundle. Evaluate how big an improvement we are likely to get from the refit."
- "I ran it; do the live checks. Then write a handoff."
- **Not decided:** whether to refit with the MLO CO₂ seasonal row on flask CO₂ (§3.2); whether to fix the pointer now.

## 3. Open items

1. **The Known-issue pointer is broken live (fix proposed, not made).** Connect Cloud injects `<base href="_w_<worker>/">`;
   its `__assets__/shiny-server-client.min.js` binds `jQuery("body").on("click","a",…)` and, for a link without
   `data-toggle`, writes the resolved `href` minus `/_w_<hex>/` back into `href` (`fixupUrl`, keeps `?query` and `#hash`).
   It runs on `body`, before `SEE_CARD_JS` (`app/ui.R` ~104, delegated from `document`), which reads
   `this.getAttribute('href').slice(1)`, gets a URL, finds no element and returns without `preventDefault()`.
   - **Fix:** read `this.hash.slice(1)` instead (`#issue-1` before and after the rewrite). Update the comment above it.
   - **Verify locally** (no `<base>` there): on the local app, inject the host's behaviour before clicking, e.g.
     `jQuery("body").on("click","a",function(){ if(!this.hasAttribute("data-toggle")) this.href = location.origin + "/" + location.search + this.hash; })`,
     then click the Keeling pointer. The tab must switch and the card's top be ≤ 2 px. **Mutation:** the old line must fail under the same
     injection. Consider pinning in `test-app-scan-items.R` that the handler does not read `getAttribute('href')`.
   - **Then** the 42 app-facing files, the full suite, a bundle, Marcus's publish, and `check_scan_ui.py` against `https://carbotope.org/`.
   - Other `href` reads in the app: the same handler's navbar lookup (`ui.R` ~111) reads the NAV links' `href`, which
     stayed `#tab-…` after every nav link was clicked live (the rewriter skipped them), so it can stay. The share link
     reads `data-base` and `location.search`. No other handler reads a link's `href`.
2. **Refit decision (Marcus's).** Scoring the MLO CO₂ seasonal row on flask CO₂ would cut the CO₂/δ¹³C seasonal
   conflict 18.7 → 7.0 and move the MLO δ¹³C cycle from 0.90× to 0.95× observed, peak 4.2 → 2.4 days late. It changes
   no headline number the app shows by more than ~0.1 %. Cost: a new canonical (MCMC band, precomputes, card numbers), and the
   model's MLO cycle would sit ~7 % above the in situ record the app plots unless the plotted series changes too.
3. **Science follow-ups, not app blockers:**
   - The same-air 2.2-d lead that no seasonal-block setting makes: a seasonally varying ε, or separate photosynthesis /
     respiration signatures (R + C++ core and a refit).
   - Why flask CO₂'s MLO cycle is 2.2 d earlier and 4.8 % larger than in situ (unexplained; both networks).
   - The lead's decline across decades.
   - `sst_seas_amp_NH` held low in every joint fit while both solo fits raise it.
   - The model's MLO CO₂ amplitude trend: +0.025 /yr against +0.009 observed.
4. **Carried over:** f_plot's alt text is "Futures" in all three modes; capacity (raise memory to 2–4 GB before a live
   class); cold start ~8 s; the marketing list; post 1 stays the feedback channel; iOS Safari needs a simulator runtime
   (ask first); rebuild the precomputes at each adoption or stored-label change. `INDEX_ccx_app.md` is 16.3 KB, over its
   14 KB soft budget (hard 18 KB).

## 4. Non-obvious state

- **The publish is Marcus's**: the auto-mode classifier refuses `deployApp()`. Hand him
  `Rscript -e 'rsconnect::deployApp("<bundle dir>", appId = "01a14244-5cc3-1951-7b06-9e2fb07beae3", account = "saraphreport", server = "connect.posit.cloud", forceUpdate = TRUE)'`.
  Revision check: `rsconnect:::clientForAccount(rsconnect:::accountInfo("saraphreport","connect.posit.cloud"))$getContent("01a14244-5cc3-1951-7b06-9e2fb07beae3")$current_revision`.
- **Suite recipe:** copy `~/ccx_frozen/suite_20261022_8d1c5982.sh`, change the commit (and label) in its three places,
  `git worktree add --detach ~/ccx_frozen/suite_<date>_<commit> <commit>`, link every untracked `data-raw/downloads`
  entry per file (78 links + 3 tracked = 81), run in the background, then `git worktree remove`.
- **Bundle:** `app/make_deploy_bundle.sh ~/ccx_frozen/bundle_<date>_<commit> <commit>`; the deployed one is
  `~/ccx_frozen/bundle_20261022_8d1c5982`. To serve a bundle locally, add a temporary `.claude/launch.json` entry
  running `setwd('<bundle dir>'); shiny::runApp('.', port = 7791, …)`, then `git checkout -- .claude/launch.json`.
- **The browser pane's default size is too small for base-R plots** ("figure margins too large"): resize to
  1440 × 900 (or 375 × 812) and reload before judging a plot error.
- **`check_scan_ui.py`'s `js()` swallows page exceptions** (a throw returns None). A step that throws reads as "the click did
  nothing", so read the state, not just the verdict. Headless Chrome:
  `"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --remote-debugging-port=9333 --user-data-dir=<scratch> about:blank &`,
  then `python3 -I outputs/diagnostics/scan_items_20261021/check_scan_ui.py 9333 https://carbotope.org/ <out_prefix> 1440 900`; kill it by PID.
- **App-facing runner** (the scratchpad copy is lost): the files
  `grep -lE 'file\.path\(\.root, "app"\)|app/R/|app/global\.R|shinyAppDir|"app"' tests/testthat/test-*.R` (42), run
  as ONE `testthat::test_dir("tests/testthat", filter = "^(<stems>)$")`; count passed as `nb - failed - skipped`. Never
  loop with a variable named `f` (loading the app overwrites it). 2,478 / 0 at `6aef5d7a`.
- **seas8 overrides:** `CCX_SEAS8_EPS`, `CCX_SEAS8_CO2SEAS=MLO_SIO_FLASK`, `CCX_SEAS8_OUT`, `CCX_SEAS8_SCREEN_DIR`.
  Both overrides apply after GATE R1. ⛔ Logposts under an override are a different objective, so never compare them with the
  canonical's. A solo fit whose rows the override leaves alone must reproduce the canonical bit for bit, which is a free gate.
- **New calibration drivers call `ccx_git_stamp()`**, never `git` (`test-git-stamp-lint.R`).
- Launch scripts kept: `~/ccx_frozen/suite_20261022_8d1c5982.sh`, `~/ccx_frozen/suite_20261021_9a6fc4d1.sh`,
  `outputs/diagnostics/seas8_20261021_hilda31w/co2flask/logs/t8c_co2flask_launch.sh`.
