# Handoff 2026-11-11: CarboTope minor-issues review, group B

Supersedes `notes/handoff_2026-11-11_minor_issues_batch_a.md` for the app's live state. Read with `CLAUDE.md`,
`~/.claude/CLAUDE.md`, the review note `notes/review_2026-11-11_minor_issues.md` (group B is its §B, items B1–B21),
and memory `INDEX_ccx_app_build.md` (host, deploy, the two 11-11 traps below).

## 1. Where things stand

- **Live app:** `64d91397`, Posit Connect Cloud revision `01a1cc55-987f-30a5-3bf4-deed63dfa8c0`, published by Marcus
  2026-11-11 20:38 UTC from `~/ccx_frozen/bundle_20261111_64d91397`; live checks all pass (CHANGELOG 2026-11-11 p).
  4 GB / 2 CPU; timeouts 1200 / 1800 / idle 5. Not tagged.
- **Landing page:** https://carbotope.org (`docs/` on GitHub Pages). The Pages build for `0e032cef` failed to start on
  GitHub's side (no workflow file in the repo; "legacy" build from `main /docs`); the next one, `d212842d`, built and
  the site returns 200. If a Pages notification arrives, `gh run list --repo msarofim/CarbonCycleEmulator`.
- **Last commit:** `d212842d` (live checks). Working tree clean apart from this note. Suite baseline at `64d91397`:
  9,741 passed / 0 failed / 1 standing skip (`l2-enso-limb`) / 233 warnings, 25.5 min
  (`outputs/diagnostics/suite_20261111_64d91397{.log,_perfile.csv}`).

## 2. What Marcus decided for group B (2026-11-11, answers to three questions)

1. **Run it in a fresh session from this note** (this one).
2. **Wording (B1–B9 and B11's missing takeaways): draft only, change nothing.** Write every proposed sentence into a
   decision sheet next to the current text; the app's text stays as it is until Marcus approves or rewrites each one.
   B1 and B2 have suggestions in the review note; B3–B9 and B11 need drafts. His word-choice rules in `~/.claude/CLAUDE.md`
   ("Word choice: what I cut from Claude's drafts") apply to every draft.
3. **Design (B12–B18) and science (B19–B21): decision sheet first.** Re-measure B19–B21 at `hilda31fl`, prototype where
   it helps a choice (screenshots), then one sheet with a recommendation per item. Nothing in these items ships until
   Marcus chooses.
- **Not covered by the three answers: B10** (unit glosses where the takeaway or table lacks one). It reuses the existing
  gloss mechanism and text (project rule 7), but it is still a visible change: put it in the sheet as "ready to apply"
  and wait.

So the deliverable of the next session is **a decision sheet**, not app changes. Suggested form: one row per item with
the current text or behaviour (quoted, with where it is in the code), the problem, the options, Claude's recommendation
and a blank for Marcus's choice; screenshots for design items; measured numbers with the script that produced them for
B19–B21. A Markdown file under `notes/` works; an artifact is an option if he wants to fill it in a browser (ask).

## 3. Plan for each part

- **B19–B21 (science):** B19 says the model correlates more strongly with Niño 3.4 than the record at every lag tried
  (r +0.29/+0.58/+0.67 vs −0.15/+0.19/+0.37 at 0/3/6 months), which would undercut card 4's "on the What-if tab's measure
  it is less ENSO-driven". Re-measure on the What-if tab's own estimator first (read how that tab computes it), at
  `hilda31fl` via `ccx_mode_file()`; record the seed and inputs in the output (CLAUDE.md "A seed must be recorded in the
  artifact"). B20: card 3's "about 15 %" (measured at `hilda29l`) and card 7's "The data prefer the literature value"
  (`hilda31w`). B21: card 7 vs What pins down what? on the seasonal SST amplitude. Read `INDEX_ccx_app.md` and the
  Known-issues sources before measuring; these claims have history.
- **B12–B18 (design):** B12 and B13 are about what a control or a label promises; B14 needs a choice of where the
  airborne fraction starts to mean something (`desktop_w_1750_1900__w_af.png`); B15 the residual strip's years; B16–B18
  phone and tablet layout. Prototype B14 and B16 if it helps; screenshot with
  `outputs/diagnostics/review_20261111/shoot_imgs.py` or `axis_title_20261111/shoot_plots.py`.
- **B1–B9, B11 (wording):** quote the rendered text with real numbers (run the app), then the draft.

## 4. Decisions earlier this session (with reasons; CHANGELOG 2026-11-11 j–p)

- **Download links (j):** batch A's A11 CSS hid each Download line until its chart drew; Shiny suspended the hidden
  links and 18 of 54 never got an address. Fixed with `suspendWhenHidden = FALSE` in `app_dl_server()`; A11's CSS and
  test unchanged. Browser gate `check_dl_links.py`. Memory `shiny_hidden_download_link_suspended`.
- **Spelling (k):** batch A's `stop()` message said "no colour for"; its own A3 test matched that text. Marcus chose
  "Fix both"; the A3 pattern is now "no color" (test edit, flagged).
- **Box diagram (n):** the host draws in DejaVu Sans (+22 % in bold). Fixed-size boxes, arrows on box edges, labels at a
  fixed gap, two label tiers, image 440 → 482 px tall at 565. Pixel gate `test-diagram-pixels.R` checks both fonts.
  Memory `ccx_app_host_font_dejavu`.

## 5. Non-obvious state and traps

- **The diagram's boxes are now FIXED SIZE** (`DIAGRAM_BOX_HW`, `DIAGRAM_BOX_HH` in app/R/plots.R). A longer box name, a
  different `hs_frac` percentage or `n_layers` must still fit; `test-diagram-pixels.R` checks that in both fonts.
- **DejaVu for tests** comes from matplotlib's copy in `~/miniforge3/pkgs/...` (or `CCX_DEJAVU_DIR`); block 2 of the
  pixel test skips, with the reason, where none is found.
- **`test-plot-text-fits` 3a reads only the first 140 lines of `plot_box_diagram()`**; the bold footnote's
  `app_text_px("diagram")` is at line 135 (5 lines of headroom). Move comments above the function rather than editing
  the test.
- **`APP_PANEL_PX["diagram"] = 424` is stale** (no longer a drawn width; narrowest is ~552). It is the footnote wrap's
  fallback and 3a/3a2 measure at it; harmless but untrue. Not changed (would move gates).
- **Deploy recipe** as in the batch-A handoff §3. Tools added this session: `review_20261111/check_dl_links.py`,
  `diagram_font_20261111/{render_diagram.R, iterate.R, render_live_scale.R, diagram_widths.py, compare.py, pngtools.py}`
  (zlib-only PNG crop and compare; no PIL or R `png` here).
- **`~/ccx_frozen/`:** `bundle_20261111_64d91397` is live; `bundle_20261111_{01cdaf99,34252dc7}` superseded;
  `quarantine_20261111_dl_links_suspended/bundle_20261111_2bc18f62` quarantined (README in
  `outputs/quarantine/20261111_dl_links_suspended/`). No frozen worktree left.
- Never edit a file an R process is running from; start one headless Chrome per job and kill it by PID; revert any
  temporary `.claude/launch.json` entry (`git checkout -- .claude/launch.json`).
