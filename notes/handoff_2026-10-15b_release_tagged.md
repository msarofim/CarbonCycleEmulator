# HANDOFF 2026-10-15b: BETA v1.0 tagged; next are the Substack formatting and the deploy

> **Superseded by `notes/handoff_2026-10-15c_deploy.md`** (same evening): the app is deployed on Posit Connect Cloud, the `.doc` is removed, and post 1 is formatted with the live link.

**Supersedes** `notes/handoff_2026-10-15_prepublic_review.md`. Written on Marcus's request ("Yes, write the handoff
note"), 2026-10-15 evening.

- **Start here:** CHANGELOG **2026-10-15 (e)–(r)**, and memory `ccx_app_beta_blockers` (its top paragraph is this
  day's end state).
- **main = `6f0b6db`, pushed.** The tag **`v1.0-beta-hilda31w`** sits on `16bd431`, pushed.
- **Full suite @ `e1c9d10`: 8166 passed, 0 failed, 1 skipped** (the standing `l2-enso-limb` skip). It ran in a
  frozen worktree with the downloads linked. Log: `outputs/diagnostics/suite_20261015_e1c9d10.log`.
- The tree is clean apart from Marcus's untracked `.docx` files in the repo root (see §4).

## 1. What was done today

| | commits | outcome |
|---|---|---|
| band copy | `2514038` drafts, `8d6a7a9` lift | Marcus: "Draft all four for me to edit". His one edit deleted the Laplace sentences. Issue 6's numbers are pinned and mutation-tested in `test-futures-ribbons.R`. |
| U.S. spelling | `5250df8` app, `02d4297` comments, `dbc2819` docs | Lint `test-app-us-spelling.R` covers every app string literal. Comments and docs were converted by scratch scripts, with only comments/prose shown to change (CHANGELOG f–h). |
| dormant-bug fixes | branch `claude/inspiring-albattani-62a97b` merged at `d0e95c6` | Marcus: "Yes, merge it." This overrides the morning's "not before launch". The merged code equals the suite-tested `47cf497` (CHANGELOG j–k). |
| his comments 10.15.26b | `9c1a97f` | 13 items, incl. the Build-your-own comparison (it now draws the "Everything else follows" scenario) and Δ¹⁴C rendering (one font: a page script in `ui.R` + `app_plotmath()` for plot titles). |
| app-text review | `b3d5b5f`, `3040c0e` | Marcus: "Apply all the app text suggestions", incl. his three open items (CHANGELOG n). |
| README | `e1c9d10` | "not for citation" cut |
| Substack assets | `cd7a68b`, `68d8821` | `outputs/substack_20261015/` (`make_figures.R`, `fig1_keeling.png`, `fig2_pulse_airborne.png`, `fig3_pulse_warming.png`, `hero_pulse_atoms_vs_excess.png`, `provenance.txt`). Re-render is byte-identical. The Essenhigh 2011 PDF is in `app/www/`. |
| suite, tag | `0cbc67d`, `16bd431`, `6f0b6db` | 8166 / 0 / 1; tagged |

## 2. Decisions (Marcus, verbatim, 2026-10-15)

- "Draft all four for me to edit", then delete the bell-curve (Laplace) sentences.
- "Update spelling in the app to be U.S. spelling" → "Convert the code comments to U.S. spelling too" → "Convert
  the docs to U.S. spelling too".
- "Yes, merge it." (the dormant fixes, before launch)
- "Apply all the app text suggestions"
- "Yes, cut it from the README and run the suite."
- Figures: "nicely formatted figures as replacements for the screenshots … and also select a good hero figure".
  Also: "Fix the bad hyperlinks when we format for substack" and "Use the attached pdf for my Essenhigh rebuttal
  paper".
- **The contrarian material moved to a SECOND post** (Marcus took the suggestion).
- "Yes, tag it."

## 3. Open items, in order

1. **Substack post 1 (the launch), formatting.** Marcus's current draft is `CarboTopeSubstack.docx` (repo root,
   untracked, 1,205 words, saved 18:18). He may revise it after today's suggestions (conclusion; captions; see the
   chat summary in §5). When he says it is final:
   - format with the `substack-formatting` skill: HTML + README, `[FN#]` markers, `[INSERT IMAGE: …]` markers, the
     hero first, then fig1–3;
   - captions must match the NEW figures: CarboTope orange (not red), the tagged atoms near-black (not blue), and
     X1's faint lines are the box before the station offset;
   - fill "[link to model]" with the deployed app URL (expected `https://carbotope.shinyapps.io/carbotope/`;
     confirm after deploy) and add the repo link.
2. **Deploy (never done).**
   - Steps:
     - `install.packages("rsconnect")`;
     - Marcus's shinyapps.io token;
     - `app/make_deploy_bundle.sh /tmp/carbotope_bundle`;
     - `rsconnect::deployApp(..., appName = "carbotope", account = "carbotope")`.
   - Posting order (DEPLOY.md): deploy with the placeholder → post → set `APP_FEEDBACK_URL` to the post (update
     `test-review-cards.R`; do not delete it) → redeploy. Marcus's own order was "1) make github public. 2) post
     substack with the CarboTope link. 3) Push CarboTope with the Substack link."
   - On the first deploy, check:
     - the start-up time: `APP_WARMUP_NOTE` says "allow up to a minute", which is NOT measured on shinyapps.io;
       re-time it;
     - that the super/subscript page script works;
     - the plot fonts on Linux (caption prose still uses Unicode ₂);
     - that `sarofim_essenhigh_comment_2011.pdf` is served.
3. **Repo-public decisions (Marcus's).**
   - The tracked review `.docx` (9.22, 9.24, 9.25).
   - `app/www/sarofim_essenhigh_comment_2011.doc`, now beside the PDF: keep or remove?
   - The gmail-authored merge commit `3abbb3a`.
   - The NetID in tracked logs.
   - Stale remote branches: `origin/claude/recursing-hermann-a2f965` and `origin/claude/inspiring-albattani-62a97b`
     (merged; pushed by the bug-fix session).
4. **Substack post 2 (contrarians).** His new draft is `CarboTopeSubstack.contrarians.docx` (untracked; not read
   this session). Also untracked and not read: `carbosubstackcomments.docx`.
   - Verified for it: every rebuttal link resolves to the intended paper. Crossref checked Köhler 2018, Kern &
     Leuenberger 2013, Richardson 2013, Masters & Benestad 2013, Meijer 2007, Beck 2007, Humlum 2013, Harde 2017,
     Jacobson 2005 and Schwartz 2007. The publisher 403s are bot-blocks, not dead links.
   - The one truly broken link is the EPA indicators URL, which carried "%5d.%5bFootnote".
   - Text typos: "Kohler" → "Köhler", "Zern" → "Kern".
5. **The bug-fix session** (`local_443fd6a2-…`, "Fix six dormant CarboTope model bugs") is idle. Its work is merged.
   Its worktree `.claude/worktrees/compassionate-chatelet-52df58` remains (detached at `e67a3b3`) and can be
   archived on Marcus's say-so.

## 4. Non-obvious state

- ⛔ **Port 7790 is Marcus's.** Never serve the app there, not even "for him": on 10-15 that blocked his own
  `runApp`. Use the `ccx-app` preview (7788) and stop it after. Memory `ccx_app_beta_blockers`.
- ⛔ **Frozen suite worktrees: link `data-raw/downloads/*` PER FILE.** `ln -s <dir>` into the existing directory
  nests the link and silently runs UNLINKED (6 skips instead of 1). The launch scripts in `~/ccx_frozen/` now
  refuse unless the links are per file. Memory `ccx_worktree_needs_downloads_linked`.
- **Numbers ready for the post** (pulse-lab default: 100 GtC, 2050, Medium):
  - extra CO₂ vs the pulse's carbon atoms still in the air: 53 % vs 13 % (2100), 50 % vs 10 % (2150), 41 % vs 6 %
    (2300);
  - temperature peak 18 yr after release (FaIR 17);
  - Build your own on Medium: "hold at today's level" → 592 ppm (2100), 701 (2150), no peak; "fall to zero by
    2060" → peak 451 ppm in 2048, then 426 (2100) and 411 (2150).
  - Schwartz test (CHANGELOG 10-15 c): 66–71 % of the excess remains a century after emissions stop, vs 36–37 % of
    a pulse.
- **Figure palette** (dataviz validator): the Keeling red/blue pair passes. The pulse figures' near-black atoms line
  fails only the lightness/chroma checks (it reads as ink); separation passes with margin. Swapping it to the app's
  blue was rejected: ΔE 1.6 against FaIR's purple under deuteranopia.
- **The U.S.-spelling conversions** of comments and docs used scratch scripts; only the app-string lint is
  permanent. Kept British on purpose:
  - the printed labels "JUDGEMENT"/"UNLABELLED" (the prior screen and `data/obs_hs_asx_prior.rds`) and the docs
    that quote them;
  - "Met Office Hadley Centre";
  - the mechanism key `fertilisation`;
  - ggplot's `colour`;
  - quotes, slugs and file names;
  - the 2011 transcription;
  - CHANGELOG (f), (g), (h), which list the British forms.
- `notes/band_copy_drafts_2026-10-15.md` records the band copy as drafted (pre-edit).
