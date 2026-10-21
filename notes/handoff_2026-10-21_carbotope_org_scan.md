# HANDOFF 2026-10-21 (2): post 2 checked live; carbotope.org; the pre-redeploy scan and Marcus's wording (not yet deployed)

**SUPERSEDED by `notes/handoff_2026-10-21_scan_items_built.md`** (later 2026-10-21): §3 item 2's scan items are built.

**Update, later 2026-10-21:** §3 item 1 is done. Suite at `6cf56879`: 9,086 passed, 0 failed, 1 skipped; Marcus
published the bundle (the session's permission check refused `deployApp()`); revision `01a15f80` from `6cf56879`;
every live check passes. CHANGELOG 2026-10-21 (k), (l). §3 items 2–5 are still open.

**Supersedes** `notes/handoff_2026-10-21_app_upgrade_post2.md`. Written on Marcus's request ("Write the handoff note"),
2026-10-21, while the final full suite was still running.

- **Start here:** CHANGELOG **2026-10-21 (d)–(j)**; `app/DEPLOY.md` ("The short address"); this note's §3 item 1.
  Memory: `carbotope_substack_posts` (new), `ccx_connect_cloud_deploy` (custom-domain facts, carbotope.org).
- **main = the commit that adds this note, pushed.** The code under test is `7bca6a32`; this note's commit adds only
  `notes/` and `CHANGELOG.md`. No branches, no worktrees.
- **Live app = revision `01a15e0d` from `dfba0d3` (unchanged this session).** Everything in §1 rows 3–7 is committed
  and NOT deployed.

## 1. What was done

| | commits | outcome |
|---|---|---|
| post 2 live | `b4002d1` | `…/p/carbotope-ii-carbotope-vs-bad-science` (dated Oct 17). Same 48 links as the build, 7 figures in order, 18 footnotes (Marcus added one); the hero is the social image only. A Ken Towe comment (aragonite vs calcite; Weddell CFCs) analysed in chat; Marcus: "not worth replying to". |
| carbotope.org | `d7d1b7b`, `88a8bc0` | Marcus registered it at Porkbun (to 2028-10-21). 302 forward to the posit.cloud URL, apex + www (+ wildcard), http + https (Let's Encrypt, apex + `*.`), path and query passed through: `carbotope.org/?<settings>` opens that view; a mistyped path gets the app's 404. Opens top-level, not framed. |
| yellow-box link | `2f755f7` | "Substack" in the Known-issues box links to post 1's comment box (`rv_feedback_how_ui()`). The first draft rendered "on Substack ." (tagList newlines); the test caught it. |
| banner short link | `a136438` | Banner on every tab ends "Short link: CarboTope.org" (Marcus's place and words; `APP_SHORT_URL` built from the label). |
| pre-redeploy scan | `1c2f104` | CHANGELOG (h): alt text on every chart, `lang="en"`, accessible names for download and new-tab links, unit notes (ppm/GtC) on four more tabs, "Still in the air", "Cumulative carbon", dashes, derived years, slider ticks off, phone menu (fits at 360 px; own row below 360), the diag script's `nuc_share` fix. |
| Marcus's wording | `1c2f104` | CHANGELOG (i): Keeling takeaway (SST added; "with a couple exceptions, it is designed around parameters that represent physical processes"; ENSO spelled out), FaIR checkbox "Compare with FaIR, a widely used climate emulator.", Build-your-own prompt, Pulse-lab prompt "Release the pulse to see results at these settings.", chart caption "CarboTope.org (beta), single best fit. …", "the “Without” line", "Drawing the chart". |
| precompute | `7bca6a3` | `data/review_precompute.rds` rebuilt: card 5's stored FaIR legend text changed ("5–95%"); no number moved. |

Tests added: `test-app-short-link.R`, `test-app-a11y.R` (real server: alt text, link names, both prompts), the
yellow-box tests in `test-review-cards.R`, `AC_CHECKS_1021` in `test-app-review-copy.R` (K2 superseded in part by
"3a", noted in the file). App-facing files after the six: all pass (review-copy 102, short-link 8, a11y 105,
plot-text-fits 111, phone-layout 37, review-cards 86, links 32, review-precompute 29).

## 2. Decisions (Marcus, verbatim)

- Domain: asked whether to buy thesaraphreport.org instead; recommended carbotope.org alone unless the Substack moves
  there. "What is the annual cost and the best way to get carbotope.org?" (Porkbun: $7.98 first year, $11.84 renewal,
  their pricing API). He set it up, then turned on include-path and wildcard himself.
- "can we make it clear somewhere on the app that 'CarboTope.org' will now take you there?" → end of the banner,
  "Short link: CarboTope.org".
- On the scan: "Mechanical fixes 1–9", "Drafts 10 and 11 as written", "Slider ticks off (20)", "Phone menu on its own
  row below 360 px (21)", "Use 'Still in the air'. The suggested language generally looks good. 'But it is not an
  abstract regression: with a couple exceptions, it is designed around parameters that represent physical
  processes.' Add sea surface temperature to the list. [...] Change 'Compare with standard FaIR' to 'Compare with
  FaIR, a widely used climate emulator.'"
- On the six: "1b, 2a, 3a, 4a, 5: 'Release the pulse to see results at these settings.' And I implemented 6b." (6b =
  the link-preview description, set by him in Connect Cloud → content Settings → Info → Description.)
- **"Redeploy once the tests pass"** — standing for the deploy in §3 item 1.

## 3. Open items

1. **REDEPLOY, approved, waiting on the suite.** The full suite on `7bca6a32` was running in the background when this
   was written (the session's scratchpad log `suite_20261021b.log`; the scratchpad is per-session, so a new session
   reruns it). Its stamp will name this note's commit, not `7bca6a32`: the run started at `7bca6a32` and the note's
   commit changes no file the tests read. The previous run (`@88a8bc00` + (h)'s edits: 9,060 passed, 2 failed,
   2 errored) found only the three breaks CHANGELOG (i) fixes. **If it passes:** copy the log to
   `outputs/diagnostics/suite_20261021_<commit>.log`, then `app/make_deploy_bundle.sh <dir> 7bca6a32` and
   `rsconnect::deployApp(<dir>, appId = "01a14244-5cc3-1951-7b06-9e2fb07beae3", account = "saraphreport",
   server = "connect.posit.cloud", forceUpdate = TRUE)`. **If anything fails: stop and report; do not deploy.**
   After the publish: every tab at 1440 × 900 (alt text present, no output errors), the banner's short link, a
   Pulse-lab link at 200 GtC (the prompt), carbotope.org → the new revision, and the link preview
   (`curl -A facebookexternalhit/1.1 -L https://carbotope.org/` → `og:description` should be Marcus's 6b text, not
   "Interactive data applications and reports"; Connect Cloud regenerates `og:image` from the first tab, which now
   shows the short link).
2. **Scan items not acted on** (review agent's list, CHANGELOG (h) last bullet): Under the hood has no takeaway;
   "see issue N" pointers could link to the tab; tooltips do not show on phones; nothing says the address bar is a
   shareable link. Reported by the agent and not individually verified by me: the Pulse lab says "runs the model
   twice" twice; "ppm per year" vs "ppm/yr" on two stacked What-if charts; the El Niño fit described two ways (What
   pins vs card 4); typed values `GROWTH_UNIT_NOTE` ("begins in 1979", correct today) and the seasonal window
   2000–2024; strings still marked as drafts in comments (scenario labels, `APP_CMAP_MODULE_ROW_TEXT`,
   `APP_FAIR_PULSE_LAB_FMT`, the seasonal-theory paragraph, pulse keys, the `response` gloss, card 8's clause); stale
   code comments (server.R:4-6, :977 "PLACEHOLDER", global.R:121-122 "404s"); the drivers table's other coverage
   years (each product's own range: a decision).
3. **From the previous handoff, still open:** the marketing list; capacity (the 10-student crash predates the
   first-visit change; raise memory to 2–4 GB before a live class); cold start (~8 s, container); the post 1 → post 2
   feedback channel stays post 1 (not asked).
4. **Phone on real iOS Safari: not possible here yet.** Xcode is installed but has no iOS simulator runtime, and
   `xcode-select` points to the Command Line Tools (changing it needs Marcus's password). Running `simctl` with
   `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` worked and triggered Xcode's first-launch component
   install. An iOS runtime is a multi-GB download: ask first.
5. **At every adoption, and now also when a label inside a stored value changes,** rebuild the precomputes
   (`calibration/build_review_precompute.R`; `build_app_precompute.R`; `ocean_climate_card.rds`):
   `test-review-precompute.R` compares stored with live and caught card 5's legend text.

## 4. Non-obvious state

- **carbotope.org at Porkbun:** destination saved WITHOUT a trailing slash; Temporary (302); include path ON;
  wildcard ON. Forward changes took ~10 min to reach Porkbun's three forwarders (207.207.210.23/.50/.36); the
  certificate ~20 min after the delegation. Whether Marcus turned on auto-renew is not known.
- **Connect Cloud custom domains need the Enhanced plan** ($59/mo vs Basic $19/mo); the forward is the free route.
- **The copy audit (`test-app-review-copy.R`) reads source with WHOLE-LINE comments stripped**: a trailing comment
  quoting old wording trips an absent-check, and a phrase built by `sprintf()` or split across `paste()` lines is
  not "present". Pinned phrases (e.g. A6's "a land biosphere of four") must stay literal.
- **Loading the app overwrites a global `f`** (global.R's `for (f in ...)`): an ad hoc `for (f in files)` test loop
  prints the wrong names after the first file. Use another variable name.
- **Hidden Browser pane:** a JS call with long awaits times out at 45 s; check one tab per call. Zoom regions are in
  the last screenshot's coordinate frame.
- **Shiny `tagList()` puts a newline on each side of a tag**: an inline link before punctuation needs
  `.noWS = "outside"` (both `gloss()` and the yellow-box link do).
- **Scratchpad only:** the suite logs, `apply_six.py`, the Towe depth-split script, the patched copy of the card-4
  diagnostic, the post 2 link list.
