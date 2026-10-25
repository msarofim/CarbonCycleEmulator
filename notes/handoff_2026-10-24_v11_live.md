# HANDOFF 2026-10-24: BETA v1.1 is live on hilda31fl; the MCMC arc is closed

**Supersedes** `notes/handoff_2026-10-23_products_rebuilt_mcmc_next.md`, which now points here. Written on Marcus's request
("I published it; do the live checks, then write the handoff"), 2026-10-24 ~12:45 EDT.

- **Start here:** CHANGELOG **2026-10-23 (u) to 2026-10-24 (j)**. Memory: `ccx_hilda31fl_adopted` (state through the
  release) and `ccx_cmap_tie_posterior_stability` (the tie rule's 10-24 refinement).
- **main = the commit that logs this note as CHANGELOG 2026-10-24 (j), pushed.** No branches. One extra worktree is kept
  (§5). **The canonical is `hilda31fl`; the live app is BETA v1.1 CarboTope, built from `9c7ec7de`, published by Marcus
  10-24 and live-checked (i).**
- Nothing is running.

## 1. What was done (10-23 evening to 10-24)

| | CHANGELOG | outcome |
|---|---|---|
| `RB_COV_EMIS` | 10-23 u | `hilda31fl = "constant"` (its Hessian: `recompute_hessian.R --update`, no emissions argument, after the 10-01 flip) |
| landing chain | 10-23 v, w | armed overnight in a frozen linked worktree; smoke-tested on interim copies; Phase 2 ruled |
| MCMC read | 10-24 a | 4 × 200k landed 05:24–06:00. NOT converged: max R-hat 1.113 (`seas_T_lag`; hilda31w 1.241), 12 / 32 > 1.01, min bulk ESS 27. Lag ridge visited by chains 2, 3, 1. No post-adaptation logpost trend |
| identifiability | 10-24 a | `bomb_share_NH` identified [0.775, 0.905]; `seas_T_lag` on its 0 floor (43 % in the band's lowest 5 %); `h_ml` wall 75.02 m (substep cap) again |
| band | 10-24 a, b | 17 000 / 17 000 draws, 228 min; by chain ≤ 38 % of the width (median 16 %); moves ≤ 0.09 of hilda31w's width. SHIPPED, ruled label carried |
| card 6 copy | 10-24 c | "three of the four chains", "about 4 ppm", "about two fifths"; the test's fraction parser generalized |
| tie stability | 10-24 d, e | 400 draws: δ¹³C level & gradient 20 / 400, ON the 5 % cut again. New rule: named only if the exact 95 % upper bound < 5 % (`ccx_cmap_lost_hi95`). Promoted |
| suite + bundle | 10-24 f, h | @`51948d67` 9394 / 1 (app-version); @`9c7ec7de` **9395 / 0 / 1**. Bundles served locally, every tab draws |
| release | 10-24 g | `APP_VERSION` "v1.1", `APP_RELEASE_MODE` "hilda31fl"; DEPLOY.md, README status updated |
| live checks | 10-24 i | host serves `9c7ec7d`; every tab draws; pointers OK; scan UI ALL OK at both sizes; v1.1 texts live |

## 2. Decisions (Marcus, verbatim)

- MCMC Phase 2: "Yes, hilda31w's settings (Recommended)" (pool 4, drop 0, thin ×2, 100-draw tie run).
- "Yes, copy and commit when the band lands". Band: "Ship it (Recommended)".
- Tie cut: "Re-run on 400 draws (Recommended)", then "Name only rows clear of the cut (Recommended)".
- Card 6: Use "about two fifths" and update the parser.
- Release: "Bump the version", then "BETA v1.1 CarboTope (Recommended)".
- "I published it; do the live checks, then write the handoff."

## 3. Files

- **New, committed:** `outputs/mcmc_check_20261024_hilda31fl_200k/` (chains, pooled draws, reads, identifiability, landing
  logs); `outputs/diagnostics/` `futures_ribbons_mcmc_20261024_hilda31fl_200k.{rds,_20261024.log}`,
  `mcmc_band_by_chain_hilda31fl_200k_20261024.*`, `mcmc_drift_hilda31fl_200k_20261024.*`,
  `cmap_posterior_spread_20261024_hilda31fl_n{100,400}.{log,rds}`, `promote_{futures_ribbons,cmap_stability}_20261024.log`,
  `suite_20261024_{51948d67,9c7ec7de}{.log,_perfile.csv}`, `mcmc_interim_20261023_hilda31fl_40k/`,
  `mcmc_landing_20261024_hilda31fl/` (armed script, smoke, the 400-draw launch), `live_20261024_v11/`.
- **Rebuilt in `data/`:** `futures_ribbons.rds` (md5 61bc2632…), `constraint_map_stability.rds` (ae482204…).
- **Code edited:** `calibration/build_futures_ribbons.R` (`RB_COV_EMIS`), `R/paths.R` (`ccx_cmap_lost_hi95`, counts in
  `ccx_cmap_stab_problems`), `app/global.R` (helper by counts, `APP_CMAP_TIE_SRC`, version, comments), `app/server.R`
  (takeaway passes counts), `app/R/review.R` (card 6), `calibration/promote_cmap_stability.R` (counts, n-min refusal),
  `tests/testthat/test-{futures-ribbons,cmap-tie,app-version}.R`, `app/DEPLOY.md`, `README.md`.
- **Nothing pending in the tree.**

## 4. Next (none started; all Marcus's to choose)

1. ~~**Git tag**~~ DONE 10-24 (k): `v1.1-beta-hilda31fl` (annotated) at `9c7ec7de`, pushed.
2. **Carried over, unchanged:** card 8's text (still Claude's draft since 10-13); whether the Keeling chart needs a note on
   flask's sparse 1960s; `f_plot`'s alt text is "Futures" in all three modes (seen again live); capacity before a live
   class; cold start ~8 s; the marketing list; handoff 10-21 §3.3's science follow-ups; flask CO₂'s MLO cycle is 4.8 %
   larger and 2.2 d earlier than in situ, unexplained.
3. **Sampler, if wanted:** the chains still do not converge on the seasonal-lag triplet (`seas_T_lag`, `seas_lag_p_NH/SH`,
   r +0.955). The band barely depends on it (the lag names move vvH CO₂ 2150 by ≤ 0.77 ppm per posterior sd on 22.8 ppm),
   which is why it shipped. A longer run or a reparameterisation of the triplet would be the fix.
4. **Small robustness fix:** `promote_cmap_stability.R` passes `--out` to `ccx_git_stamp(exclude=)` unguarded, so a second
   path outside the repo stamps `+dirty?`. `promote_futures_ribbons.R` has the guard (`PR_EXCL`).

## 5. Non-obvious state

- **Kept worktree:** `~/ccx_frozen/20261023_mcmc_hilda31fl` @`2ec25511`. Its real chains are in the repo (cmp-identical),
  but its `outputs/mcmc_smoke_20261023_hilda31fl/chain_{1..4}.rds` (the 10-23 smoke) are not. Remove with
  `git worktree remove --force` once those are copied or judged unneeded.
- **Bundles in `~/ccx_frozen`:** `bundle_20261024_9c7ec7de` is the published one. `bundle_20261024_51948d67` still carries
  v1.0 and must not be published.
- **The tie rule reads counts.** A stability file without `n_lost` + `provenance$n_draws` is refused. Each map rebuild
  needs `diag_cmap_posterior_spread.R --n=400 --cores=8` (~30 min) then `promote_cmap_stability.R`, run with any second
  path INSIDE the repo. At 400 draws, 11 losses are named and 12 are a tie; fewer than 72 draws are refused.
- **Card 6's typed numbers are pinned** against the band's by-chain read (`test-futures-ribbons`, "issue 6's typed
  numbers"): a rebuilt band that moves them turns that test red, and the copy is Marcus's.
- **Live-check recipe:** `"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new
  --remote-debugging-port=9333 --user-data-dir=<scratch> about:blank &`, then
  `python3 -I outputs/diagnostics/see_card_hash_20261022/check_live_pointer.py 9333 https://carbotope.org/ 1440 900 <commit7>`
  and `.../scan_items_20261021/check_scan_ui.py 9333 https://carbotope.org/ <prefix> <W> <H>`; stop Chrome by PID.
  `check_live_pointer`'s Build-your-own FAIL is by design (the plot waits for "Run it").
- **Built-in browser:** keep each in-page script under 45 s; a script that outlives the limit keeps running and clicking.
- **Memory budgets:** `INDEX_ccx.md` and `INDEX_ccx_gates.md` are both ~14.8 KB (over the 14 KB soft budget);
  `INDEX_ccx_app.md` over soft since 10-22. Root `MEMORY.md` not touched.
