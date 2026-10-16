# HANDOFF 2026-10-15c: CarboTope is DEPLOYED (Connect Cloud); next are the repo going public, the post, and the feedback link

**Supersedes** `notes/handoff_2026-10-15b_release_tagged.md`. Written on Marcus's request ("Yes, write the
handoff and stop both servers"), 2026-10-15 late evening.

- ⭐ **Item 1 below is DONE (CHANGELOG 2026-10-15 z): the repository is PUBLIC**, with no history rewrite, the three
  review `.docx` untracked and both `claude/*` remote branches deleted.
- ⭐ **Items 2 and 3 are DONE (CHANGELOG 2026-10-15 aa):** post 1 is published, `APP_FEEDBACK_URL` points to it, and the
  app is redeployed from `7f069fa` (revision `01a1427c…`, still 1 GB).
- ⭐ **Item 4's precompute and item 6 are DONE (CHANGELOG 2026-10-15 bb):** Known issues first view 4.0 s on Connect
  Cloud (was 30.7 s); the old worktree is removed. Timeouts: connection 20 min, read 30 min (Marcus's settings),
  live after a republish of `b7928cd` as revision `01a14484…`. ⚠ Re-run `calibration/build_review_precompute.R`
  at every adoption.
- **Start here:** CHANGELOG **2026-10-15 (t)–(y)**, `app/DEPLOY.md` "Posit Connect Cloud", and memory
  `ccx_connect_cloud_deploy` + the top paragraph of `ccx_app_beta_blockers`.
- **main = the commit that adds this note, pushed.** The tag `v1.0-beta-hilda31w` is unchanged (on `16bd431`).
- **Suite:** not re-run this session. Since `e1c9d10` (8166 / 0 / 1) the changes are docs, diagnostics, one
  `app/global.R` COMMENT, and the deletion of an unreferenced `app/www/*.doc`. No code path changed.
- **Both local app servers are stopped** (:7788, :7791). Port 7790 stays Marcus's (see §5).

## 1. What was done this session

| | commits | outcome |
|---|---|---|
| post 1 review | none | Captions, pulse point 3 (FaIR line = FaIR's own climate; secondary rise depends on background) and links reviewed. Marcus revised the draft. |
| Known issues 5 vs Pulse lab | none | Issue 5 is Joos's PD100 (pulse 2015, CO₂ held at 2010): CarboTope stays above FaIR to 300 yr (0.293 vs 0.291). In the Pulse lab (2050, scenario backgrounds) it drops below FaIR after 2100 (High) to 2120 (Medium). The issue's text is right for its setup. |
| carbon-cycle uncertainty | `56ec846`, `3621749` | `outputs/diagnostics/carbon_spread_20261015/`. Pulse band (200 MCMC draws): CarboTope 3–7 points wide vs FaIR 12–66 (ratio 4–10). Scenario CO₂ in 2100: 3.5–10 ppm vs 14–99 ppm. FaIR's scenario CO₂ spread was never stored before (`run_fair_vv_for_ccx.py:162` writes the mean only). Gated, mutation-tested, byte-identical twice. |
| post 1 formatted | `8f90898`, then the URL in `4f8cd15` | `outputs/substack_20261015/carbotope_substack.html` + `README.txt`: FN1–FN4, hero + fig1–3, subscribe marker. The link is the live Connect Cloud URL. |
| `.doc` removed | `187a6da` | `app/www/sarofim_essenhigh_comment_2011.doc`; the PDF stays and is served. |
| deploy | `46c554d`, `4f8cd15` | Connect Cloud, account `saraphreport`, Basic plan, 1 CPU / 1 GB. Details in §4. |

## 2. Decisions (Marcus, verbatim, 2026-10-15 evening)

- "Run both, 200 draws for the pulse band" (the CarboTope pulse band and FaIR's scenario CO₂ spread).
- "Go ahead and format the attached for substack."
- "Delete the .doc file: the pdf is good enough."
- "Run steps 1 and 3 now." / "And step 4." (install rsconnect; build the bundle; check it locally)
- "Prepare the Connect Cloud files and try the free plan."
- Account name **`saraphreport`** (asked "Is 'saraphreport' a good name for the account?"; it was registered).
- **Upgraded to Connect Cloud Basic** ($190/yr) and set the app's memory to 1 GB. Connect Cloud is the host;
  shinyapps.io is the documented fallback.
- On "without selecting for it" (post 1): keep it. phi = 0 stands on scientific grounds, and estimating total
  sinks with models is different from calibrating to model structure or uptake rates.
- Not a ruling: the 4-GB-to-1-GB setting reached the app only on the second try, set on the CarboTope
  content's own settings page and then republished.

## 3. Open items, in order

1. **Make the GitHub repo public** (`msarofim/CarbonCycleEmulator`, still PRIVATE). His pre-public decisions
   come first:
   - the tracked review `.docx` files (9.22, 9.24, 9.25);
   - the gmail-authored merge commit `3abbb3a`;
   - the NetID in tracked logs;
   - stale remote branches `origin/claude/recursing-hermann-a2f965` and `origin/claude/inspiring-albattani-62a97b`.
   Until the repo is public, FN1's GitHub link and the app's `APP_REPO_URL` 404 for readers.
2. **Publish post 1.** Follow `outputs/substack_20261015/README.txt`. Four wording points were flagged to
   Marcus and NOT changed (his text):
   - "an emission pulse for either the CarboTope or FaIR" lacks a noun;
   - "'What if…?' that lets you…" is a fragment;
   - "the What if? tab" / "the Isotope Fingerprints tab" don't match the app's tab names ("What if…?",
     "Isotope fingerprints");
   - "The pulse tab" is the Pulse lab inside Futures.
3. **The feedback link, then redeploy.**
   - Set `APP_FEEDBACK_URL` (`app/global.R`, still `"SET-BEFORE-DEPLOY"`) to the post's URL.
   - Update `tests/testthat/test-review-cards.R` (do not delete it) and commit.
   - Rebuild with `app/make_deploy_bundle.sh <new dir>`.
   - Redeploy to the SAME content: `rsconnect::deployApp(<dir>, appId = "01a14244-5cc3-1951-7b06-9e2fb07beae3", account = "saraphreport", server = "connect.posit.cloud")`.
     A fresh bundle directory has no deployment record, so give the `appId`.
   - Check that the 1 GB setting survived (API: `current_revision.memory`).
4. **Optional, Marcus's call:**
   - precompute the Known-issues tab's three runs (the first view took 30.7 s once, 4.2 s once);
   - lower the connection timeout (3600 s; an abandoned tab may keep the app billing);
   - a vanity name or custom domain (Enhanced). Either would change the URL in the post.
5. **Post 2 (contrarians):** not touched this session. `CarboTopeSubstack.contrarians.docx` and
   `carbosubstackcomments.docx` are still unread. Known for it: the EPA indicators link is broken
   ("%5d.%5bFootnote"); fix "Kohler" → "Köhler" and "Zern" → "Kern" (handoff 10-15b §3.4).
6. **The bug-fix session's worktree** `.claude/worktrees/compassionate-chatelet-52df58` still exists (merged
   work); archive on Marcus's say-so.

## 4. The deployment (facts to re-verify, not to trust)

- **App:** `https://01a14244-5cc3-1951-7b06-9e2fb07beae3.share.connect.posit.cloud/` (public).
  - Management page: `https://connect.posit.cloud/saraphreport/content/01a14244-5cc3-1951-7b06-9e2fb07beae3`.
  - The URL is tied to the content id and survived two republishes.
- **Live revision:**
  - `01a14251-eceb-083a-217d-369a9f39177b`, built from `187a6da` (the tag minus the `.doc` and one
    DEPLOY.md line);
  - 1 CPU / 1024 MB;
  - `idle_timeout` 5, `conn_timeout` 3600 (Posit Connect defaults, seconds as I read them).
- **Plan:** Basic, $190/yr. 8 GB / 2 CPU max, 100 usage credits a month, 25 apps, private-repo deploys.
  - Credits per hour = 0.75 × CPU + 0.25 × GB, so 1.0 per hour of serving.
  - The usage period runs from account creation (2026-10-16 UTC).
  - Paid limits are not enforced until 2027 (docs.posit.co/connect-cloud/user/usage.html).
- **Measured on Connect Cloud:**
  - cold start 27.0 s to the first plot;
  - all 8 tabs and 25 plots, no errors;
  - pulse 11.8 s (the same at 4 GB and 1 GB);
  - Build your own 4.6–5.0 s;
  - provenance = posterior mode (31 fitted, 14 held);
  - the PDF is served, the `.doc` 404s;
  - sub/superscripts and plot glyphs render.
- **Why Connect Cloud:** Posit's 2026-07-21 post. shinyapps.io apps auto-migrate from early 2027, with URL
  redirects and plan prices held until 2029.
- **No repo files are needed for the deploy:** rsconnect publishes the local bundle and writes its own
  manifest (47 packages incl. `adaptMCMC` → `RcppArmadillo`, only because `R/calibrate.R` mentions it).

## 5. Non-obvious state

- **rsconnect 1.11.2 is installed** in the system R library. The account `saraphreport` is registered in
  rsconnect's user config.
  - `rsconnect::connectCloudUser()` FAILS with "`serverName` must be a single string, not `NULL`" if the
    Posit login has no Connect Cloud account yet. A token-refresh handler intercepts the refused
    account-list request. Workaround: create the account in the browser first.
- **`/tmp/carbotope_bundle`** is the deployed bundle. It carries the deployment record
  (`rsconnect/documents/app.R/connect.posit.cloud/saraphreport/carbotope.dcf`). `/tmp` is wiped on reboot;
  that is harmless, since `appId` above re-targets the content.
- The deploy log in the session scratchpad contains a short-lived upload token. It is not in the repo; never
  paste it.
- ⛔ **Port 7790 is Marcus's** (memory `ccx_app_beta_blockers`). This session used 7788 (working tree) and 7791
  (the bundle).
- **A hidden Browser pane renders at 0×0**, so every Shiny plot errors with "figure margins too large". Set a
  viewport (`resize_window` 1440×900) before judging an app from the pane.
- The carbon-spread drivers: `pulse_band.R` (R, ~15 min on 6 cores under load) and `fair_vv_co2_spread.py`
  (`~/climate-env/bin/python -I`, ~4 min). The FaIR script imports FaIRtoFrEDI's exporter READ-ONLY.
  FaIRtoFrEDI is on branch `heat-ed-morbidity` with Marcus's uncommitted edits; do not commit there without
  asking.
- `CLAUDE.md`'s tracked-Python count is 14 (the FaIR spread script added one).
