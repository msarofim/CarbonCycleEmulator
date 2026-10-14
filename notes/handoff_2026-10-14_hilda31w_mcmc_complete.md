# HANDOFF 2026-10-14: the hilda31w MCMC chains are COMPLETE; the read is next

**Supersedes** `notes/handoff_2026-10-13b_hilda31w_mcmc_running.md` (which now points here). Written on Marcus's request
("check status and then write handoff"), 2026-10-14 ~06:10.

- main = `ec175a6` before this note's commit, **pushed**. The repo is clean except the three CarboTope `.docx` files in the root (Marcus's, untracked by convention; not touched).
- **Start here:** CHANGELOG **2026-10-13 (k) → (q)**; memory [[ccx_hilda31w_adopted]] (its last paragraphs); §4 below.
- **First thing to do:** §4 step 1. Snapshot the chains into the repo and run the read.

## 1. Status at 06:09 EDT

- **MCMC: 4 / 4 COMPLETE.** Each ran 200 000 iterations and kept 8 500 samples, over 917–998 min. Post-adaptation acceptance: 0.067 / 0.078 / 0.072 / **0.039**.
  - The chain files are still in the frozen worktree, `~/ccx_frozen/20261013_mcmc_hilda31w/outputs/mcmc_check_20261013_hilda31w/chain_{1..4}.rds`, **not yet in the repo**. Logs: `~/ccx_frozen/20261013_mcmc_hilda31w_chain{1..4}.out`.
  - ⚠ **Chain 4 made ONE long excursion, and it was transient.** Its kept-sample `h_ml` medians by quarter are 62.5 / **45.7** / 63.7 / 61.6 m; chains 1–3 sit at ~61–65 m throughout. It has 3 892 distinct kept rows against 5 853–6 232 for the others.
    - Expect it in `h_ml`'s R-hat and ESS.
    - The 10-13 19:35 flag ("sticky", moves ~1 % after 60k) described the excursion while it was happening. It is not a chain that never came back.
- **The `k_w` = 1446 profile:** done, landed and read (CHANGELOG q). Card 7's two claims hold.
- **No preview is running.** Both :7790 (hilda31w, mine) and :7788 (hilda29e) are gone.

## 2. What was done since the 10-13b handoff (2026-10-13 ~12:00 → 20:00)

| step | commits | outcome |
|---|---|---|
| (k) the three product rebuilds | `327de2d` … `526a2a6` | Constraint map, `pulse_vs_tcre` and card 8 rebuilt at hilda31w; every typed claim still holds. The stake's G3 false FAIL was diagnosed: GMST record ends 2024, SST 2025, so the arms ran 6 vs 5 coupled iterations. It is now two exact checks, mutation-tested. `test-cmap-tie` is red by ruling. |
| (l) worktree cleanup | `ae1003c` | Nine removable `~/ccx_frozen` trees removed, each checked file by file first. |
| (m) the app runs on hilda31w | `5c57add`, `10a0bdf` | Run-time `nuc_share` proof 12 / 12 (two refused mutations); every tab live, no output error. |
| (n) easy fixes | `0e273e1`, `d274d6a` | Card 1's label border (`linewidth`, ggplot2 4.0); the land-sink panel's "Removed 10 rows" (`na.rm`, PNG byte-identical); `DEPLOY.md`; "the seventh tab" → by name. |
| (o) tolerances | `5f158b3` | `MC_LP_TOL`, `WR_REPRO_TOL` and the IAV-price `IAV_REPRO_TOL` all read `CCX_REPRO_TOL`. |
| (p) prep while the chains ran | `0ad47a0` … `fd753ff` | Read + identifiability dry run; band smoke; **two blockers fixed** (`start_redraws` in the reader, `RB_COV_EMIS` in the band builder); the `h_ml` wall measured; GATE S explained; suite 8027 / 8 expected; the `k_w` profile launched. |
| (q) card 7's `k_w` claim | `eee2fc4`, `ec175a6` | Likelihood **+6.21** for 1446 (was +2.75); `hs_asx_frac`'s prior is **88 %** of the prior cost; posterior price −15.40. |

## 3. Decisions (Marcus, verbatim, 2026-10-13)

- The constraint map's two new names: **"Existing groups (Recommended)"**.
- G3: **"Both exact checks (Recommended)"**.
- The tie cut: **"Defer to the MCMC (Recommended)"**.
- Panel #7: **"Self-contained mutation (Recommended)"**.
- **"Remove the removable worktrees in ~/ccx_frozen"**.
- **"Yes, start the app on hilda31w"**.
- **"Fix anything that can be addressed easily."**
- `MC_LP_TOL` / `WR_REPRO_TOL` / IAV-price `IAV_REPRO_TOL`: **"Use CCX_REPRO_TOL (Recommended)"**, each.
- **"Do 1, 2, 4 and 3; run 5 overnight"**; the `k_w` arm: **"Two-start profile, Mac (Recommended)"**.
- **"Yes, copy the results and compute the prior ledger"**.
- **Mine, stated:**
  - `run_price_profile.R` RESTATES the wave's optimiser recipe and constants rather than calling the wave's driver. The wave's reference machinery has no slot for a warm start from another objective's mode. Said in its header.
  - `diag_mcmc_identifiability.R`'s bins (1 / 2 / 5 m; the outer 1 % / 5 % of a band) are descriptive, not thresholds.
  - `diag_pulse_vs_tcre.R`'s screen-read anchor was re-read off the live app: 1.36 → 1.35.
  - Smoke runs used Laplace draws dressed as a pooled file, in scratch only, never committed.
  - The 10-05 `k_w` read's canonical is **hilda34g** (its own provenance), not hilda33p as older notes said. Corrected in card 7's comment and the 10-13b handoff.

## 4. Next steps (in order)

1. **Snapshot and read the chains.**
   - Copy them into the repo, e.g. `outputs/mcmc_check_20261014_hilda31w_200k/` (the hilda29e precedent is `outputs/mcmc_check_20261009_hilda29e_200k/`), and verify with `cmp`.
   - Then `Rscript calibration/read_mcmc_check.R --dir=<snapshot>`, with `--drop=0` first. It prints the 5 000-iteration log-posterior blocks for the burn-in call.
   - **Marcus's calls:** convergence; `--drop`; chain 4; and `--pool-thin` (the hilda29e precedent is "Thin x2 within chain", i.e. `--pool-thin=2`).
2. **The identifiability check:** `Rscript calibration/diag_mcmc_identifiability.R --draws=<snapshot>/pooled_u*.rds`.
   - It covers `bomb_share_NH` vs `tau_ex` / `bomb_total`; `seas_T_lag` vs `seas_lag_p_NH` (Laplace r +0.955; mass near its 0 floor); and `h_ml` against the wall, measured at the mode.
   - It was dry-run on the partial chains: the pipeline works, and those numbers carry no weight.
3. **The tie-cut method**, deferred to this read: does the cut become each row's margin spread over posterior draws? About 22 s per constraint map, so ~100 draws ≈ 40 min on one core. Marcus's call.
4. **The band.**
   - `Rscript calibration/build_futures_ribbons.R --draws=<REPO-RELATIVE pooled_u> --cores=8 --out=<not data/>`. Smoke-tested; `--draws` and `--out` resolve against the repo root. At hilda29e, 14 000 draws took ≈ 2.5 h on 8 cores.
   - Torch verdict to say out loud: the Mac has all 10 cores free now.
   - Then `diag_mcmc_band_by_chain.R`, and `promote_futures_ribbons.R` to ship. `test-futures-ribbons` names the shipped mode (`.fr_ship_md`). The app's `APP_RIBBONS_HOLD` still holds the band until its copy lands.
5. **Card wording (Marcus):** card 7's "slightly" against +6.21; card 8's draft.
6. **The release:** v1.0 vs v1.1 (`APP_RELEASE_MODE`; app-version is a known red until then), the full suite, the `v1.1` tag.

## 5. Non-obvious state

- **Frozen worktrees in `~/ccx_frozen/`:**
  - `20261013_mcmc_hilda31w`: done. Keep it until the chains are snapshotted and the read is committed.
  - `20261013_kw1446_profile`: done, results copied byte-identical. Removable on Marcus's word.
  - `suite_20261013_5f158b3`: removable.
  - Marcus has not said to remove these three.
- **The `h_ml` wall at the mode is 75.02 m, and it is the SUBSTEP CAP** (`CCX_SUBSTEPS_MAX` 256 at `kz` 13790), not P8. P8 alone is at 75.14 m on the label's 3682.2 m grid.
  - ⚠ The "75.48 m" in CHANGELOG (j), in `run_mcmc_check.R`'s comment (line ~69) and in the 10-13 launch README is ~0.4 m high. Those records were not edited.
- **A Gaussian (Laplace) band is NOT buildable at hilda31w.** P8 censors about one draw in five, and the builder refuses above 1 %. MCMC draws cannot cross the wall.
- **The pure-R core runs none of the four forcing guards** (ENSO index, AOD, `nuc_share`, N deposition); all four sit on the C++ path. This is a design question for Marcus. The app feeds the R core a stamped build, which was checked.
- **Expected reds:** app-version (release); `test-cmap-tie` (deferred); `test-futures-ribbons` (until the band ships); card 4 ×2 (by design).
  - The suite at `5f158b3` read 8027 / 8 / 1 skip / 0 errors. Commits after it (new drivers, two fixes, comments) were not re-suited.
- **Tested, not open:** GATE S's blind phase 4.10 → 4.38 is 80 % the ERSSTv5 SH SST lag (`55b810f`). The pulse headline 1.35026 rounds to "about 1.4" by 0.0003.
- `.claude/launch.json` carries a second config, `ccx-app-7790`.
- **Still Marcus's (unchanged):**
  - the merged remote branch `origin/claude/recursing-hermann-a2f965`;
  - the flux-trace default;
  - the app never SHOWING `retried` / `converged`;
  - the copy worklist and deploy items;
  - card 4's two by-design failures;
  - the CarboTope `.docx` files;
  - the app's own `.claude/worktrees/compassionate-chatelet-52df58`.
- **Memory:** [[ccx_hilda31w_adopted]] carries the state through (q). New this session: [[exact_gate_span_past_gmst_record]] (indexed in `INDEX_diag_bound.md`). `INDEX_ccx.md` is unchanged at 14.8 KB (soft 14).
