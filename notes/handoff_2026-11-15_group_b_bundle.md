# Handoff 2026-11-15: group B is built; two answers from Marcus, then bundle and deploy

Supersedes `notes/handoff_2026-11-15_group_b_build.md` (the build plan). Read with `CLAUDE.md`, `~/.claude/CLAUDE.md`
(word-choice rules apply to every string a reader sees), CHANGELOG 2026-11-15 (c), (d), (e), and
`notes/drafts_2026-11-15_group_b.md` (the drafts and his answers). Batch A's handoff
(`notes/handoff_2026-11-11_minor_issues_batch_a.md` §3) is the bundle, deploy and live-check recipe.

## 0. UPDATE 2026-11-15 (later): T1/T2 run, caption done, checked and bundled (CHANGELOG 11-15 f, g)

Marcus: "run T1 and T2; use 11 months with 'where both peak', and continue work". Done:
- T1/T2 (`calibration/diag_card4_enso_knockouts.R`; write-up `notes/drafts_2026-11-15_group_b.md` §1c, memory
  `ccx_card4_early_side_not_sooner`): on the module's estimator the peaks coincide and the miss is uncorrelated there;
  the difference is on the early side, where card 4a's calendar-year index sits. T3, T4 not run.
- Card 4a's caption: "…to each January, where both peak, r is…", printed only when both series peak at the lag.
- Suite at `8ba6c320` 9,892 / 0 / 1 skip; mutations 18/18; bundle `~/ccx_frozen/bundle_20261115_8ba6c320` checked
  locally (`outputs/diagnostics/groupb_bundle_20261115/README.md`).

**Approved (Marcus, 2026-11-15): "Approve the second draft".** Card 4's paragraph ships as in the bundle; no rebuild.
He also asked for "an improved ENSO fit" on the refit list (`notes/next_refit_candidates.md` item 3) and for the last
12 hours of usage before publishing (CHANGELOG 11-15 h). Next, §4 step 4: he publishes
```
Rscript -e 'rsconnect::deployApp("/Users/MarcusMarcus/ccx_frozen/bundle_20261115_8ba6c320", appId = "01a14244-5cc3-1951-7b06-9e2fb07beae3", account = "saraphreport", server = "connect.posit.cloud", forceUpdate = TRUE)'
```
then the live checks (batch A §3 step 5) and push `main` (B9.9 landing page title). B13 still open.

**DONE 2026-11-15 (CHANGELOG 11-15 i):** published by Marcus (revision `01a1e15d`), live checks pass, `main` pushed, the landing
page title is live. Open: B13; refit list items 1–3 (`notes/next_refit_candidates.md`); T3/T4 not run.

## 1. Where things stand

- **Built:** every group B item except B13 (still open, nothing built). Commits `fd10dfaa` (the build), `bc7c691c`
  (browser fixes: banner edges, dashed measured seasonal curves), `685bd0dd` (the year-bounds fix, suite record), and
  this session's last commit (his answers, second card 4 draft, this note). Live app is still `64d91397`. **Nothing pushed**
  (B9.9 changes the landing page title, which goes live on carbotope.org with the next push to `main`).
- **Suite** at `fd10dfaa`: 9,877 passed, 1 failed (`test-ui-year-bounds-lint.R` 1, fixed in ui.R in `685bd0dd`; the lint was
  not edited), 1 standing skip; per-file diff in CHANGELOG (d). **Not yet re-run on the final commit.**
- **Gates:** `tests/testthat/test-app-review-20261115.R` (126) and `AC_CHECKS_1115` in `test-app-review-copy.R`; mutation
  script `outputs/diagnostics/groupb_build_20261115/mutate_group_b.py` (16/16 caught at `d155c624`; one mutant added since,
  not yet run).
- **Re-pinned tests** (his group B wording replaced the wording they pinned; listed for him in the drafts note): seven rows of
  `test-app-review-copy.R` (10-01 A2, 10-21 K takeaway + its mutant, 10-21 FaIR checkbox, 10-16 P caption, 10-16
  "residence", 10-06 H1, 10-15 "K issue 4 share"). Tell him about the last one (added after his answers).

## 2. Marcus's answers (2026-11-15, verbatim) and what was done

1. "Card 4's suggested paragraph seems too long. Also, why would the model respond to El Nino sooner than measured
   growth, if it was tuned to measured growth?" → second draft in the code (drafts note §1b), "sooner" withdrawn.
   **Awaiting his approval of the second draft**, and possibly his choice of tests (§3).
2. "Pros/cons of each?" (card 4a's caption lag) → answered in the reply; lag 11 stays built (`RV_GROWTH_ENSO_LAG_MO`,
   review.R). **Awaiting his choice.**
3. "About two thirds." → card 4's plain; gated as the nearest simple fraction to card 4a's ratio (0.672).
4. "Drop volcanic." → card 4's ask: "And if the missing variability is not El Niño or a trend, what would you look for next?"
5. "Approve." → the B14 note as built.

## 3. Open: his question on "sooner", the hypotheses and the tests (not run)

The premise needs one correction: the main calibration does not score year-to-year growth (the interannual cut). The four
ENSO settings (two land sensitivities, the land lag 5.93 months, the ocean upwelling limb) were fitted in a separate step to
the centred 12-month growth sampled monthly, and to the ocean sink's ENSO slope (`app_cmap_module_note()`, global.R), and
are held. The measured facts on card 4a's measure (`card4_whatif_residuals_20261115_hilda31fl.log`,
`card4_enso_estimators_20261111_hilda31fl.log`): both series' r with the index peak at 11 months with equal ENSO-related
variance (0.24 vs 0.26 of the record's); at shorter lags the model's r is higher (lag 0 +0.29 vs −0.15, lag 3 +0.59 vs
+0.19), which is why the miss correlates with the same calendar year's index (r +0.48) and not with the 11-month one (−0.03).

Hypotheses: (H1) structure: four parameters place the peak but not the lag shape (an ocean limb acting without delay
would do it; the record's negative lag-0 r fits a real ocean taking up more CO₂ in the El Niño year itself);
(H2) estimator: timing fitted on centred monthly growth may look different on calendar-year annual-mean differences (the
6-month precedent, memory `ccx_card4_less_was_estimator_mismatch`); (H3) a few large events carry it.

Tests, each minutes: (T1) knockouts: the ocean limb off, then the land ENSO response off; which removes the model's
positive lag-0 r and the miss's association; (T2) the same lag profile on the module's own estimator
(`data-raw/build_mbl_global_growth_monthly.R`); (T3) the miss's correlation at every lag 0–18 (a pure amplitude difference
would peak at 11, a timing difference near 0); (T4) leave-one-event-out (1982–83, 1997–98, 2015–16). Recommended: T1 and
T2. Run only on his word.

Lag pros and cons, as given to him: **11 months** (both peak there; both r positive, +0.73 vs +0.51; matches the land lag
and the variance split; but harder to explain, mostly the previous year's ENSO, a chosen lag needs "where both peak" in the
caption, and card 4b uses calendar-year means). **Calendar year** (simplest, no choice to justify, matches card 4b; but the
record's r is −0.15, which reads as "measured growth does not follow ENSO", and the comparison then mostly measures the
timing difference in §3). Recommendation: 11 months, with "where both peak" added to the caption.

## 4. Then (batch A §3, unchanged)

1. Apply his answers; re-run the two gate files, `mutate_group_b.py` (clean tree, no app running), then the full suite in a
   frozen worktree (`~/ccx_frozen/suite_20261115_fd10dfaa.sh` is the template; link the 79 untracked `data-raw/downloads`
   entries per file; compare per-file counts with `outputs/diagnostics/suite_20261115_fd10dfaa_perfile.csv`).
2. `bash app/make_deploy_bundle.sh ~/ccx_frozen/bundle_<date>_<commit> <commit>`; `diff -rq` against the last bundle.
3. Serve it (temporary `.claude/launch.json` entry, reverted after); every tab at 1440 × 900 and 375 × 812;
   `outputs/diagnostics/review_20261111/check_dl_links.py`; for phone scroll and gray-outs use headless Chrome with
   `outputs/diagnostics/groupb_20261111/cdp_shoot.py` and `outputs/diagnostics/groupb_build_20261115/phone_check.json`.
4. Marcus publishes (the command in batch A §3 step 4); then the live checks (§3 step 5) and push `main` (the landing page
   title, B9.9).

## 5. Traps (this session)

- **Functions in global.R cannot see app/R/ under `shinyAppDir()`.** The B7 helpers had to live in params_meta.R.
- **`test-takeaway-arithmetic.R` extracts named functions from global.R**; a new global constant inside one breaks it
  (hence `app_ppm_small()` beside `app_ppm_change()`).
- **`test-app-precompute.R` 12 deletes the line holding `withheld =`**: keep that argument on one line (`dl_withheld()`).
- **`test-ui-year-bounds-lint.R` wants each "Years shown" default written `c(<start>, APP_HIST_YEARS[2])`** in ui.R.
- **The hidden in-app browser pane runs no CSS transitions and ignores programmatic scrolling** (memory
  `hidden_browser_pane_freezes_transitions_and_scroll`); **ragg on this Mac drops plotmath glyphs under ~8 px**, the host
  draws them (memory `ragg_drops_small_plotmath_glyphs`).
- **`mutate_group_b.py` restores files with `git checkout`**: an edit made to app/ while it runs is lost.
- The Write tool turns `–` in a test file into the character; match the file's bytes when editing it.
