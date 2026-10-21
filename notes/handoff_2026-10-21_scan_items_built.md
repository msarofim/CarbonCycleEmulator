# HANDOFF 2026-10-21 (3): redeployed (scan + wording); the scan items built and tested (not yet deployed)

**Supersedes** `notes/handoff_2026-10-21_carbotope_org_scan.md`. Written on Marcus's request ("Write the handoff
note"), 2026-10-21.

- **Start here:** CHANGELOG **2026-10-21 (k)–(n)**; this note's §3 item 1.
  Memory: `ccx_connect_cloud_deploy` (the deploy classifier, revision `01a15f80`), `broken_harness_hides_the_whole_suite`
  (a second instance today).
- **main = the commit that adds this note, pushed.** The app code is `42899ee8`; this note's commit adds only
  `notes/`, `CHANGELOG.md` and `outputs/diagnostics/scan_items_20261021/`. No branches, no worktrees, no servers
  running (the local `ccx-app` preview and headless Chrome are stopped).
- **Live app = revision `01a15f80-d82a-9d53-9961-205ebb3e47e5` from `6cf56879`** (published 17:27 UTC by Marcus).
  Everything in §1 row 3 is committed and NOT deployed.

## 1. What was done

| | commits | outcome |
|---|---|---|
| full suite @ `6cf56879` | `86d3a40e` | 9,086 passed, 0 failed, 1 skipped (standing `l2-enso-limb`), 231 warnings, 26.3 min; frozen worktree `~/ccx_frozen/suite_20261021_6cf56879` (launch script kept there, worktree removed). Log + per-file CSV in `outputs/diagnostics/suite_20261021_6cf56879*`. README's test line cites it. |
| redeploy | `86989cf8` | **`deployApp()` was REFUSED by Claude Code's auto-mode classifier ("Production Deploy")**, even under Marcus's "Redeploy once the tests pass". Bundle built at `6cf56879` (116 files, 7.3 MB); Marcus ran the one-line publish. Live checks all pass (CHANGELOG l): 8 tabs, 25 plots with alt text, no errors; banner short link; a 200 GtC Pulse-lab link through carbotope.org shows the prompt, then draws in 12.0 s; `og:description` = his 6b text, `og:image` regenerated. |
| scan items | `42899ee8` | CHANGELOG (m). Glosses open on tap/focus (sibling `span.gloss-meaning`); the Keeling and Isotopes pointers link to `#issue-N` and switch tabs; "Copy link to this view" on each tab's first chart copies `https://carbotope.org/` + query; Under the hood takeaway (`APP_HOOD_TAKEAWAY`); `APP_SEAS_WINDOW` (2000 to the last full MLO year, capped at the run: 2000–2024 today); drivers table Covers from each file (`APP_DRIVER_COVERS`: SST 1850–2025, ENSO 1948–2026, N dep 1750–2025 change); growth note's 1979 read from data; "ppm per year"; What pins down what? "year-to-year wobble"; one Pulse-lab method line; "of its peak warming"; three stale comments. |

Tests: new `test-app-scan-items.R` (74, with mutations); `AC_CHECKS_1021B` in `test-app-review-copy.R` (+9). The
42 app-facing files: 2,466 expectations, 0 failed. **The full suite was NOT rerun after `42899ee8`.**
Browser: local app at 1440 × 900, every tab draws with alt text and no errors, one share link each; headless check
`outputs/diagnostics/scan_items_20261021/check_scan_ui.py` prints ALL OK (share link copies the short address,
pointer lands on card 1 at the viewport top, phone tap opens the meaning inline, no sideways scroll).

## 2. Decisions (Marcus, verbatim)

- "Redeploy once the tests pass" (previous batch; used for `6cf56879`). After the refusal: "I ran it; do the live
  checks".
- On the scan list: "Do 1–7 and the "own" fix. 8: "CarboTope is a set of carbon pools in each hemisphere, joined
  with flows; the tables below lists the parameters included, the inputs, and the observations that are used to fit
  and drive the model." 9: Do it. 10: End at the last observed year. 11: Do it."
- **Not asked yet:** whether to redeploy `42899ee8`. His earlier approval was for the previous batch; ask.

## 3. Open items

1. **Full suite, then (on Marcus's yes) the redeploy of `42899ee8`.** Suite: copy
   `~/ccx_frozen/suite_20261021_6cf56879.sh` to a new name, change the commit in its three places, `git worktree add
   --detach`, link `data-raw/downloads` per file (the guard refuses otherwise), run in the background, wait on the
   notification. Bundle: `app/make_deploy_bundle.sh <dir> <commit>`. **Then hand Marcus the command** (the classifier
   refuses it): `Rscript -e 'rsconnect::deployApp("<dir>", appId = "01a14244-5cc3-1951-7b06-9e2fb07beae3", account =
   "saraphreport", server = "connect.posit.cloud", forceUpdate = TRUE)'`. Live checks after: revision via
   `rsconnect:::clientForAccount(rsconnect:::accountInfo("saraphreport","connect.posit.cloud"))$getContent(<id>)$current_revision`;
   every tab at 1440 × 900; `check_scan_ui.py` against `https://carbotope.org/` (needs headless Chrome; see its
   docstring); the Under the hood takeaway and the drivers years.
2. **Two small questions for Marcus** (raised in chat, not answered): "the tables below lists" was set as "list"; ENSO's
   Covers shows 1948–2026 because the monthly record runs partway into 2026 (alternative: the last full year).
3. **Strings still marked as drafts in code comments** (8; offered as one approve/edit pass, not started): scenario
   labels' parentheses (`global.R` `APP_SCENARIOS`), the What pins down what? module note (`APP_CMAP_MODULE_ROW_TEXT`
   + `app_cmap_module_note()`), `APP_FAIR_PULSE_LAB_FMT`, the seasonal-theory paragraph (`server.R` ~1224), the pulse
   keys (`plots.R` `KEY_PULSE_*`), the `response` gloss (`review.R` ~62), card 8's "has not adjusted to the warming"
   clause (`review.R` ~899), the CSV chart names (`downloads.R` ~146, approved in bulk 10-20 but still marked).
   Some may already be approved by his 10-15 "apply all"; check before asking.
4. **Noted, not changed:** f_plot's alt text is "Futures" in all three Futures modes (alt = registry name by design,
   pinned by `test-app-a11y.R`).
5. **From earlier handoffs, still open:** capacity (the 10-student crash; raise memory to 2–4 GB before a live
   class); cold start ~8 s; the marketing list; post 1 stays the feedback channel; iOS Safari needs an iOS simulator
   runtime (multi-GB, ask first); rebuild the precomputes at each adoption or when a stored label changes.

## 4. Non-obvious state

- **The deploy is Marcus's to run** while the classifier refuses `deployApp()`: build, hand over the command, then
  check live. Recorded in memory `ccx_connect_cloud_deploy`.
- **`helper-code-lines.R` refuses an escaped quote (`\"`) anywhere in `app/ui.R`**, and a helper failure aborts EVERY
  test file at load (the log looks like one failure). Write JS selectors in ui.R without double quotes (the see-card
  script iterates the navbar links instead of an attribute selector).
- **The desktop Browser pane does not scroll programmatically** (`window.scrollTo(0, 500)` leaves 0) and is hidden,
  so a JS call over 45 s times out; check scrolling headless (`check_scan_ui.py`). A tap must be scrolled into the
  viewport in a SEPARATE step before `Input.synthesizeTapGesture`, or it lands out of bounds.
- **`Copy link` copies the short address**, so it depends on the Porkbun forward (302, include path ON). If the
  forward changes, the copied links follow it.
- **`plot_seasonal()` has no default window** now; the server passes `APP_SEAS_WINDOW`.
- **Loading the app overwrites a global `f`** (global.R's `for (f in ...)`); ad hoc scripts here used `ff`.
- Scratchpad only (lost with the session): the app-facing runner (`run_appfacing.R`, a list of 43 files that read the
  app), the tap-debug script, screenshots. The runner is easy to rebuild: every test file that greps for
  `file.path(.root, "app")`, `app/R/`, `app/global.R`, `shinyAppDir` or `"app"`.
