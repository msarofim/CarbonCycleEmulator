# HANDOFF 2026-10-21: post 2 built for Substack; the app upgraded (phone, first visit, deep links, downloads) and live

**Supersedes** `notes/handoff_2026-10-16_post2_review.md`. Written on Marcus's request ("Write the handoff note"),
2026-10-21.

- **Start here:** CHANGELOG **2026-10-16 (i)–(n)**, **2026-10-17 (a)**, **2026-10-20 (a)–(j)**, **2026-10-21 (a)–(b)**;
  `outputs/substack_20261016/README.txt` (post 2 paste-in); `outputs/diagnostics/loadtest_20261020/README.md`;
  `app/DEPLOY.md`. Memory: `ccx_connect_cloud_deploy`, `excess_decays_slower_than_pulse`.
- **main = the commit that adds this note, pushed.** The tree is clean. No local `claude/*` branches and no worktrees.
- **Suite:** full @ `ba898e25` (after the three merges): 8,704 passed, 0 failed, 1 skipped (the standing
  `test-l2-enso-limb.R` skip), 231 warnings (as at `cd7a1c9`); log `outputs/diagnostics/suite_20261020_ba898e25.log`.
  Since then only app code changed (`a4dc202`, `a688a70`, `dfba0d3`): the 20 app-facing files, 1,203 expectations, 0 failed.

## 1. What was done

| | commits | outcome |
|---|---|---|
| comment links | `e20a92a` | "Comment on issue N" goes to Substack's comment box (`#discussion`); `#card-N` matched nothing. |
| Known-issues lead | `507d0a2` | "the charts take a few seconds to appear" (Marcus's choice); deployed 10-16. |
| Schwartz at his stop year | `c5f0713`, `44331dd` | Stopping emissions in 2017: CarboTope keeps 64 % of the excess after 100 yr = 224-yr equivalent lifetime (his 2021: 78–140). First 2017 run QUARANTINED: `app_run_coupled()` re-splices history ≤ 2024 over a caller's emissions; gates G5/G6 added, mutation-tested. |
| post 2 reviews | `78b06ed`, `d2c7c2c` | `REVIEW2.md` (16:06 save), `REVIEW3.md` (19:41 save). |
| post 2 Substack build | `4a61823`…`8b6fb21` | `outputs/substack_20261016/carbotope2_substack.html` + `README.txt`; Figures 1–7 (files renamed to post numbering; Fig 3 = Marcus's XKCD), Figure 7 has Schwartz's 40 % marker, hero `hero_with_without_emissions.png` (1456×762). `figures_provenance.txt`. |
| load test | `9cb7701` | Live app, 1 CPU / 1 GB: 5 simultaneous students OK (served in turn), 10 crash it (all disconnect; down ~45 min). Locally ~600 MB after the first full session, +~30 MB per active student, not released. Driver: `outputs/diagnostics/loadtest_20261020/loadtest.py`. |
| phone layout | merged `0aa504d` | Below 576 px: tab dropdown (navbar 288 → 72 px), takeaway + main plot before the controls, `app_fit_plot()` refits plot text. |
| first visit | merged `3f627ab` | Start-up runs and the Pulse lab's default from md5-gated precomputes; C++ compiles in the background. Pulse lab draws the default with no click; changing a setting grays it until "Release the pulse". |
| deep links + downloads | merged `ba898e2` | URL carries tab + settings (Shiny bookmarking; a link never presses a button); CSV + PNG under every chart, CSVs with provenance. |
| copy | `a4dc202`, `a688a70` | Gray-out note in Marcus's words; start-up note DELETED; download labels, empty-chart message, "Choose a tab" approved. While grayed, the pulse charts' downloads carry the gray-out note instead of the previous run (my choice of wording; real-server test). |
| deploys | `c75eab6`, `de6cef2` | Revision `01a15bf5` (10-20) then `01a15e0d` (10-21, from `dfba0d3`). |
| cold start | `b4bdd27` | After 45 min idle: connect 7.7 s, first plot 10.2 s (old revision same day: 18.4 / 20.9 s). One sample each. |
| Known issue 2 | `dfba0d3` | Second panel labelled "δ¹³C gradient (‰)" again: `app_plotmath_str()` read only the first label; now vectorized. Test `test-review-gradient-labels.R` with mutation. Live. |
| sessions | — | Phone, first-visit and links/downloads sessions archived; their branches and worktrees deleted (all merged). |

## 2. Decisions (Marcus, verbatim)

- Post 2: "Add Schwartz's 40% marker to Figure X8 and regenerate it." "Review again, and if it looks good build the
  substack formatted version with appropriate figure numbering and other fixes." Hero: "Yes" (Figure 6's CO₂ panel).
- "Run the load test. Because the connect cloud credits aren't restricted right now, that's not a limitation."
- On classroom use: "I don't know if multiple students using it simultaneously in a classroom is that likely."
- Pulse lab: "If we have the pre-calculated default pulse, I would automatically populate the graph rather than waiting
  for a click. And then replace it if the pulse options change." Asked what "replace" means: "Grey out, wait for the click".
- "Merge all three (Recommended)". Gray-out note: "Chart reflects previous settings. Release the pulse to update."
- "Delete the start-up note; approve the rest as drafted (though for the Pulse lab, it should only happen when changing
  pulse size/date, not before the first run because now there's a default, right?)"
- "Archive the three finished sessions"; "Delete the branches and start the Known issue 2 fix"; "Redeploy it".

## 3. Open items

1. **Post 2 is Marcus's to paste.** Before pasting, his calls (README "Check first"):
   - the carbonate sentence, reworded in the build to "Mostly it was already dissolved in seawater, where it is the
     raw material for calcium carbonate aka aragonite" (his draft said it "was probably living its life as" aragonite);
   - FN1 sits on the subtitle, which Substack's subtitle field cannot hold; FN6 sits on the Figure 2 caption (keep that
     caption as an italic line);
   - the Revelle & Suess link is the DOI (resolves to Tellus's open-access PDF); Wiley's page could not be tested.
   - 17 links block scripted checks (publisher bot walls); README lists them to click by hand.
2. **Marketing (suggested 10-20, none started):** a classroom worksheet + answer key; CLEAN (SERC) submission; a JOSE
   paper after v1.0 (Zenodo DOI first); EGU 2027 education session (deadline inferred mid-January 2027 from the last two
   years, not confirmed); Skeptical Science's residence-time pages; Archer, Joos; Carbon Brief / RealClimate / The
   Climate Brink. Short domain: carbotope.org/.com/.net unregistered on 10-20; registrar URL forwarding keeps post 1's link.
3. **Capacity:** the 10-student crash was measured BEFORE the first-visit change; not re-tested. For a live class,
   raise memory (2–4 GB) on the content page and republish. Per-session memory growth (~10 MB retained) not investigated.
4. **Cold start:** the remaining ~8 s is mostly the container (the app's own start-up is ~1 s locally). Removing it
   would need a keep-warm option, if his plan has one.
5. **Phone:** tested in Chrome emulation only (not iOS Safari); at 320 px the tab dropdown cuts long tab names.
6. **At every adoption:** rebuild `review_precompute.rds`, `app_startup_precompute.rds`, `pulse_default_precompute.rds`
   (`calibration/build_app_precompute.R`) and `ocean_climate_card.rds`; their tests fail until rebuilt (`app/DEPLOY.md`).
7. **Optional:** FaIR was not rerun at the 2017 stop (only 2030); Schwartz's 2025 model left out of post 2 (REVIEW2 §3).

## 4. Non-obvious state

- **Live:** revision `01a15e0d-6e7a-4d3c-9c9b-040a0e979833` from `dfba0d3`; 1 CPU, 1024 MB, connection 1200 s, read
  1800 s, idle 5 s; scheduler `sched_max_proc` 10, `sched_max_conns` 20, load factor 0.5, `init_timeout` 60. URL unchanged.
- **Redeploy:** `app/make_deploy_bundle.sh <dir> <commit>` (now writes `FROZEN_FROM_COMMIT.txt`, which the CSV
  downloads print), then `rsconnect::deployApp(<dir>, appId = "01a14244-5cc3-1951-7b06-9e2fb07beae3", account =
  "saraphreport", server = "connect.posit.cloud", forceUpdate = TRUE)`. Bundle 116 files, 7.3 MB.
- ⛔ **A load test of the LIVE app takes it down for real visitors.** Test small N first; stop at the first disconnect.
- ⛔ **`app_run_coupled()` re-splices GCB history over years ≤ 2024**: a zeroing or pulse before 2025 passed to it is
  silently overwritten. `calibration/diag_zec_vs_pulse.R` splices first and runs with the splice switched off.
- **Browser checks:** a tab opened in the hidden Browser pane can be 0 × 0 and every plot then errors "figure margins
  too large" (harness, not app): set a viewport first. The Futures tab's inner pill panes are also `.tab-pane.active`,
  so take a top-level pane from its navbar link's href.
- **Tests:** `shiny::testServer` returns a download output as a file path (used by `test-app-precompute.R` 12).
  `outputs/diagnostics/app_precompute_timing_20261020/coldstart.py`'s default-pulse step now times out (the default is
  already drawn); its recorded numbers predate (d).
- **Scratchpad only** (session-specific): deploy bundles and logs (a log holds a short-lived upload token; never paste
  it), the zip files sent to Marcus, headless-Chrome profiles.
