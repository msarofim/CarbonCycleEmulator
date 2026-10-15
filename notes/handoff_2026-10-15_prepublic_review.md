# HANDOFF 2026-10-15: pre-public review applied; going public this afternoon

**Supersedes** `notes/handoff_2026-10-14c_nuclear_source_promoted.md`. Written on Marcus's request ("Write handoff and
then show me the uncertainty band text for review"), 2026-10-15 ~11:10.

- **Start here:** CHANGELOG **2026-10-14 (m)–(o)** and **2026-10-15 (a)–(d)**; memory `ccx_app_beta_blockers`.
- **main = `00bddd2`, pushed.** The tree is clean apart from Marcus's untracked CarboTope `.docx` files
  (9.26, 10.2, 10.11, 10.15) and the gitignored `CLAUDE.local.md`.
- **Full suite @ `6278482`: 8095 passed, 0 failed, 1 skipped** (the standing `l2-enso-limb` skip). It is the first
  fully green suite since the hilda31w adoption.

## 1. What was done (10-14 evening → 10-15)

| | commits | outcome |
|---|---|---|
| IC8 split | `f451f0f` | the raw-file sha256 is now IC8b, which skips without the download (ruled) |
| pure-R forcing guards | `818b9cc` (measured), `bcaa1f9` (landed) | `ccx_run()` runs the four guards ccx_run_prepared() runs; 7 calibration scripts now STOP (fix on touch, ruled) |
| release cut | `556f4a4` | BETA v1.0 on `hilda31w`; `APP_REPO_URL` = the GitHub repo |
| deploy prep | `837d248` | `app/make_deploy_bundle.sh` (the ship list, tested: the bundle runs every tab); DEPLOY.md fixed (it named a mode two adoptions old) |
| 10-15 text review | `5adf02c` | his `CarboTopecomments.10.15.26.docx` applied; card → issue; issue 4 facts fixed |
| Schwartz check | `a5e7720` (+ FaIRtoFrEDI `8c685cb`, `417db44`, pushed) | CO₂ stops in 2030 → 71 % (FaIR) / 66 % (CarboTope) of the excess left in 2130, vs 37 % / 36 % of a pulse in the same world. Not second order |
| box diagram | `0d694df` | two arrows ML↔deep, litterfall label below, no overlaps, text scales with the panel width |
| pre-public review | `7caeede` docs, `0695062` model comments, `6278482` app text | four reviewers, ~110 findings applied (CHANGELOG 10-15 d) |

## 2. Decisions (Marcus, verbatim, 2026-10-15)

- "Beta v1.0 is fine, because this is the first public version."
- **Posting plan:** "1) make github public. 2) post substack with the CarboTope link. 3) Push CarboTope with the
  Substack link."
- "Remove the Marron affiliation from LICENSE and README."
- **Review rulings:**
  - "Apply all (Recommended)" for the fact fixes, with copy pins following the changed sentences;
  - "Apply all (Recommended)" for the cleanups;
  - "Facts-only README + banners (Recommended)";
  - "Trim to a public version (Recommended)" for CLAUDE.md.
- **Dormant model bugs:** NOT fixed before launch, because they change behavior. Marcus started the proposed
  session "Fix six dormant CarboTope model bugs" (`local_443fd6a2-…`), which works in its own worktree.

## 3. Open items, in order

1. **The uncertainty-band copy (Marcus's).** These four items lift `APP_RIBBONS_HOLD` in ONE commit:
   - the band's label (`calibration/promote_futures_ribbons.R --label=`, command in the facts note §A);
   - issue 6's title, plain, detail and ask (`app/R/review.R`, id 6). The title "There are no uncertainty bands,
     anywhere" is now the one visibly false title in the app;
   - the parameter panel's "not yet a posterior" clause (`app/global.R` ~364);
   - `APP_RIBBON_NOTE_TEMP`.

   Facts: `notes/ship_copy_facts_2026-10-14_hilda31w.md`.
2. **Other copy still his:**
   - issue 4's class "structural": its gloss is the separate-hemispheres one, which does not describe a variance
     shortfall;
   - issue 7's "slightly" (+6.21 log-likelihood);
   - `APP_WARMUP_NOTE`'s "three minutes" (start-up is ~7 s locally; re-time on shinyapps.io).
3. **Repo-public decisions (his):**
   - the three tracked review `.docx` (9.22, 9.24, 9.25);
   - `app/www/sarofim_essenhigh_comment_2011.doc`, which is served publicly once deployed and linked from nothing;
   - the gmail-authored GitHub merge commit `3abbb3a`;
   - the NetID in tracked logs;
   - the stale branch `origin/claude/recursing-hermann-a2f965`.
4. **Deploy:** never done. Steps:
   - `install.packages("rsconnect")`;
   - his token;
   - `app/make_deploy_bundle.sh /tmp/carbotope_bundle`;
   - `rsconnect::deployApp(..., appName = "carbotope", account = "carbotope")`.

   Then set `APP_FEEDBACK_URL` to the Substack post (update `test-review-cards.R`, do not delete it). Posting order
   (DEPLOY.md): deploy first with the placeholder, then post, then redeploy with the URL.
5. **Tag:** after his copy, a full suite run, then the tag. Ask him first.
6. **The dormant-bug session** reports back on its own; check its diff and suite before trusting it.

## 4. Non-obvious state

- **Port 7790 is Marcus's** (his own `runApp` for reviews). Use the `ccx-app` preview (7788) and stop it when done.
  The Browser pane's hidden 0×0 window makes plots report "figure margins too large"; resize to 1280 first.
- **`CLAUDE.local.md`** (gitignored) now holds the memory-store and harness notes that left CLAUDE.md and DEPLOY.md.
  Claude Code loads it automatically, but a frozen worktree does not have it.
- **No worktrees remain** in `~/ccx_frozen/` from today. The dormant-bug session has its own worktree.
- **FaIRtoFrEDI branch `heat-ed-morbidity`** carries the CarboTope FaIR drivers and is pushed. Its working tree has
  Marcus's uncommitted EGU memo `.docx` edits; they were not touched.
- **Session-scratch only:** the reviewers' scripts, the diagram renders and the bundle test dirs. Their results are
  in CHANGELOG and `outputs/diagnostics/`.
