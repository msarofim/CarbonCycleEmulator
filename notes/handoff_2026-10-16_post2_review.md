# HANDOFF 2026-10-16: CarboTope is public and live with feedback links; post 2 reviewed with figures

**SUPERSEDED by `notes/handoff_2026-10-21_app_upgrade_post2.md` (2026-10-21).**

**Supersedes** `notes/handoff_2026-10-15c_deploy.md`. Written on Marcus's request ("Write the handoff note"),
2026-10-16 afternoon.

- **Start here:** CHANGELOG **2026-10-15 (z)–(bb)** and **2026-10-16 (a)–(h)**; `outputs/substack_20261016/REVIEW.md`;
  memory `ccx_app_beta_blockers`, `ccx_connect_cloud_deploy`, `ccx_luc_is_transfer_not_addition`,
  `ccx_schwartz_3ccdm_vs_carbotope`.
- **main = the commit that adds this note, pushed.** The tree is clean; Marcus's root `.docx` files are now ignored.
- **Suite:** full @ `cd7a1c9` (the ocean-depth session): 8055 passed (testthat's `passed` column; README's 8,166 @
  `e1c9d10` counted warnings too, so the two are on different bases), 0 failed, 1 skipped. An independent per-file
  recount found +120 passes in five files and none lost. Since then: no app code change apart from one comment; the
  nine affected test files re-run at `cfb5d0c`: 412 / 0.

## 1. What was done

| | commits | outcome |
|---|---|---|
| repo public | `8f0479a`, `5697029` | Marcus took every recommended option: no history rewrite (the gmail merge commit `3abbb3a` and `/scratch/ms17839` paths are public); the three review `.docx` untracked, root `/*.docx` ignored; both `claude/*` remote branches deleted. |
| feedback link | `7f069fa`, `cbd9524` | `APP_FEEDBACK_URL` = `https://thesaraphreport.substack.com/p/the-debut-of-carbotope-beta-a-new` (referral/utm stripped). `test-review-cards.R` updated, not deleted: a set-link check + mutation test. |
| Known-issues precompute | `60cfcd1`, `b7928cd`, `2b056e7` | `data/review_precompute.rds`: 5 `rv_memo()` keys; first view on Connect Cloud 30.7 → 4.0 s. Refused unless built at the canonical's mode-file md5 (then computes live). Gate `test-review-precompute.R` (29: live parity, mutations). |
| timeouts | `43bcb2e` | Marcus set connection 20 min / read 30 min on the content page; they reached the API (1200/1800 s) only after a republish. |
| old worktree | (no commit) | `compassionate-chatelet` removed (clean, merged). Later `bold-einstein` (ocean depth) removed too. |
| ocean by depth | `db0d5c4`…`cfb5d0c` | Done by the side session "CarboTope next version: three ocean layers in Pulse lab" (`local_62823b72…`): upper / intermediate / deep in both Pulse-lab partition panels, Marcus's copy, merged and deployed. |
| post-merge check | `7af469d` | Everything works live (all tabs, no errors, links). Found: DEPLOY.md wrongly said the app links the Essenhigh PDF; it does not (it is hosted for post 2). |
| Revelle diagnostic | `e405637`, `7fd7f3f` | `calibration/diag_revelle_buffer.R`. Surface-box Revelle 8.9–12.5 (1750) → 10.0–14.6 (2024). Buffered equilibrium for the fossil addition: +14.2 % / +39 ppm. ⚠ Land use is a transfer: the system total grew by fossil only (closure 3.7e-11 GtC). |
| post 2 review + figures | `18b2776`, `f69f45a` | `outputs/substack_20261016/`: six figures + `REVIEW.md` (science, numbers, primary-source fact-check). |
| Schwartz comparison | `f43dced`, `168f660` | `calibration/diag_schwartz_3ccdm.R`: his 2025 ocean matches CarboTope at +100 yr only; effective piston velocity 17.9 → 4.9 m/yr ≈ t^−½ (structural). |

## 2. Decisions (Marcus, verbatim)

- Pre-public: "No rewrite; flip public", "Untrack + gitignore", "Delete both", "Leave it" (the NetID).
- "Precompute the known issues, shorten the connection timeout, and archive the old worktree." He then set the timeouts
  himself: "I set the connection timeout to 20 minutes and the read timeout to 30 minutes."
- "Yes, remove the worktree" (bold-einstein).
- "Save the Revelle analysis as a diagnostic."
- Post 2: "Review the next substack post (attached), and make suggestions for improvements, as well as making the
  appropriate figures (and suggesting new figures if appropriate)."
- His corrections of the fact-check: Dengler's 2025 post "didn't actually propose a short lifetime"; Schwartz 2024/2025
  make no short-lifetime claims. Both confirmed against the sources; REVIEW.md corrected.
- His paragraph on CarboTope's lineage ("didn't inherit code ... inspiration from Oeschger, HILDA, and Joos ...
  combines a monthly timestep, separate hemispheres, and isotope tracking") is accurate as revised.

## 3. Open items

1. **Post 2 is Marcus's to revise.** `REVIEW.md` lists everything. The ones that matter most:
   - the buffer-chemistry paragraph's mechanism (carbonate ion, not calcium or solid aragonite);
   - the Curry characterizations (her 2011 disclaimer, the 2016 van der Werf rebuttal; both Salby quotes are from 2011);
   - Dengler & Reid accept the human cause; Essenhigh is a single author in mechanical engineering; Humlum belongs with the ENSO confusion;
   - the Holocene range (~260–285 ppm); the Schwartz numbers (66–71 % vs ~37 %).
   Then, when he asks, format it for Substack (skill `substack-formatting`) with a README, as post 1.
2. **Figures for post 2** are drafts in `outputs/substack_20261016/` (fig1–4 for his slots, fig5–6 suggested). Renumber
   once he settles the order (the XKCD image is his Figure 3).
3. ✅ **DONE 2026-10-16 (j)**, Marcus's wording, deployed (revision `01a1467e…`). Was: **App copy (Marcus's):** the Known-issues lead still says the first opening "run[s] the model again, which takes a few
   seconds". It no longer does.
4. **Optional:**
   - ✅ DONE 2026-10-16 (i)/(j), deployed: the links now end in `#discussion` (the comment box). Was: the "Comment on issue N" links end in `#card-N`, which Substack ignores;
   - an 800,000-year ice-core figure (Bereiter et al. 2015) needs a download into `data-raw/`; ask first;
   - a vanity URL (it would change the address in post 1).
5. **At every adoption:** re-run `calibration/build_review_precompute.R` (as for `data/ocean_climate_card.rds`).
   `test-review-precompute.R` fails until it is.

## 4. Non-obvious state

- **Live:**
  - revision `01a144cc-69f2-e5ee-99c0-e34d25125f3c`, from `7f2204b`, deployed by the ocean-depth session;
  - 1 CPU, 1024 MB, connection 1200 s, read 1800 s, idle 5 s;
  - app URL unchanged: `https://01a14244-5cc3-1951-7b06-9e2fb07beae3.share.connect.posit.cloud/`.
- **Redeploy:** `app/make_deploy_bundle.sh <dir> <commit>`, then `rsconnect::deployApp(<dir>, appId = "01a14244-5cc3-1951-7b06-9e2fb07beae3",
  account = "saraphreport", server = "connect.posit.cloud", forceUpdate = TRUE)` (in `app/DEPLOY.md`). Settings survive
  redeploys; a settings change needs a republish to take effect. The Browser pane is not signed in to Posit, and Claude
  cannot sign in.
- **Usage credits:** Marcus can see them on the content's Usage page and under Account Usage. There is no API call for them.
- **Local branches** `claude/bold-einstein-47f001`, `claude/compassionate-chatelet-52df58` and
  `claude/inspiring-albattani-62a97b` remain. All are merged or superseded; delete on his say-so.
- **CarboTope run rows** are START-of-month states. A closure or uptake calculation must use the state at Jan 1 of the
  next year, which `APP_HIST` lacks for 2024; use `dg_run()`.
- **A WebFetch'd page is summarized by a small model:** check any quote that will be published against the source. The
  fact-check subagent's characterizations were wrong twice (Dengler 2025, Schwartz 2024/25).
- **The Write tool** stores `\uXXXX` escapes in R strings as literal Unicode, so later string-match edits must use the
  actual characters.
- **Scratchpad only** (session-specific, not needed): deploy bundles and logs (a log holds a short-lived upload token;
  never paste it), the tagged-atom tail analysis behind the 10-15 answer on the post's 'long tail' sentence (not committed; re-run
  before a post quotes its numbers), probe scripts.
- **The Ladrillo session** (`local_90b19e5b…`) was running `run_ic_arms.sh L27` on 9 Python workers earlier; check
  `uptime` before long jobs.
