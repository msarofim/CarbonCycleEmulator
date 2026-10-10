# HANDOFF 2026-10-10 — the `hilda29e` 200k MCMC band is SHIPPED into `data/`; the app's HOLD waits only on Marcus's copy; one lint failure awaits his ruling

**Supersedes** `notes/handoff_2026-10-09_mcmc_200k_running.md`. Its §3 items 1–4 are DONE: the landing, the report, his ruling, and the ship's code steps. Its item 5 (card 4 / card 8 / constraint-map caption / What-if blurb wording) still applies unchanged.

Written on Marcus's request ("write the handoff note"), 2026-10-10. **Nothing is running.**

**Start here.**
1. CHANGELOG **2026-10-09 (g)**, **(f)**, **(e)**, **(d)**, in that order. (g) is the newest.
2. `notes/ship_copy_facts_2026-10-09.md`: the facts for the copy the hold-lift waits on.
3. Memory: `laplace_fails_on_fertilisation_ridge` (its 10-09 e / f paragraphs) and `ccx_app_beta_blockers` (the "BANDS: SHIP RULED" section).
4. `~/.claude/CLAUDE.md` and this repo's `CLAUDE.md`.

## 1. What was done (rulings verbatim)

| Step | Outcome |
|---|---|
| The 200k landing (armed last session) | `land.sh` rc 0, done 16:59 EDT 10-09. The chains were COMPLETE at 14:20; the snapshot is md5-identical to the live files; read `--pool-thin=2`; build 159 min, 17 000 of 17 000 draws ran; per-chain and drift diagnostics ran. Committed `09a3d15`; CHANGELOG (e). |
| `calibration/diag_mcmc_band_compare.R` (new; `b9b58a1`, lint fix `dd62587`) | The 50k / 100k / 200k reads side by side, with `hilda33d` stage 1 as the precedent. It reproduces every logged number. Its PREFIX check shows the 100k → 200k extension is **bit-exact on the real chains** (all four); the check was mutation-tested. Output: `outputs/diagnostics/mcmc_band_compare_hilda29e_20261009.{log,csv}`. |
| **The 200k read** | R-hat max **1.046** (`beta_max`), 8 of 30 above 1.01, min bulk ESS 105: still short of Vehtari et al.'s reference.<br>CO₂ between-chain range: max **3.46 ppm, 21 %** of the band's width; median 1.01 ppm, 15 %. Stage 1 was 3.42 ppm, 29 %.<br>The band is NOT widening: late/early 1.01. From 100k to 200k the width went ×0.973 and no median moved more than 0.37 ppm.<br>`h_ml`'s 100k sink was an EXCURSION: block medians are 56–58 m from 100k onward, and near-floor visits recur in about 1 draw in 10.<br>Expected vs measured: ESS ×2.4 expected, ×2.5 measured; the range was expected ~1.5× smaller and came out ×1.53. |
| **"Ship the 200k band (Recommended)"; "Keep the floor (Recommended)"** | ⚠ **The hold is NOT lifted**, though my option text had listed lifting it. Lifting it alone leaves three things describing an app with no band: card 6's title ("There are no uncertainty bands, anywhere"), the parameter panel's "not yet a posterior — no uncertainty ranges are shown", and the band's label. All three are Marcus's copy. Details in CHANGELOG (f). |
| The ship's code steps (`23dc945`, `e1711dc`) | `calibration/promote_futures_ribbons.R`: the bands are copied untouched, the draws' md5 is checked, the chain seeds are recorded in the artifact, and `key_draws` is dropped (22.1 → 0.3 MB in memory). Two runs are byte-identical; it refuses the wrong draws and refuses a Laplace band.<br>→ `data/futures_ribbons.rds`, md5 `18c1dea3494ee933311ac63bd455bd4c`, `label_ruled = FALSE`.<br>`ccx_ribbons_problems()` now requires supplied draws to record the chains' seeds, RNG kind and where the seed is applied.<br>`test-futures-ribbons.R` rewritten: 23 → 52 expectations, all pass. Its `.fr_lift_problems()` fails a lift while any of the three still says there is no band; mutation: a scratch tree with only the hold lifted FAILS on all three. |
| Full suite at `e1711dc` (CHANGELOG g) | **7107 passed, 5 failed, 0 errors, 3 skipped**, 17.7 min. Card 4's two failures are by design. Of the new failures, `test-git-stamp-lint` was my compare script calling git directly: fixed, log unchanged. The other two are the mode-struct lint on `diag_mcmc_drift.R`: **REPORTED, not touched** (§3 item 2). |

## 2. Where things stand NOW

- **Nothing is running.** The chains, the landing, both waiters and the suite have all exited. The suite's frozen worktree has been removed.
- **`data/futures_ribbons.rds` holds the shipped band; `APP_RIBBONS_HOLD` is still set**, so the app draws nothing and says nothing about the band. The hold's internal string and comment (`app/global.R` ~L483–491) record the 10-09 ruling and what the hold waits on. Neither is ever displayed.
- **The `h_ml` floor is KEPT** (09-16 b; `CCX_HML_FLOOR_M`).
- Everything is committed and pushed through `dd62587`; this note's commit is on top of it.

## 3. NEXT

1. **Marcus's copy, then lift the hold, in ONE commit:**
   - **A. the band's label.** It renders as "Shaded: the 5–95% range of 17000 model runs — a `<label>`." Set it by re-running the promotion with `--label="…"`; the bands are asserted unchanged:
     ```
     Rscript calibration/promote_futures_ribbons.R --from=outputs/diagnostics/futures_ribbons_mcmc_20261009_hilda29e_200k.rds --draws=outputs/mcmc_check_20261009_hilda29e_200k/pooled_u_thin2.rds --label="<his wording>"
     ```
     That sets `label_ruled = TRUE`.
   - **B. card 6** (`app/R/review.R`, id 6, key "bands"): its title, plain, detail and ask.
   - **C. the parameter-panel clause** (`app/global.R`, `app_params()`, the "not yet a posterior" sentence).
   - **D. how to present the 0.02–0.10 °C temperature band.**
   - Then set `APP_RIBBONS_HOLD <- NULL`.
   - Run `test-futures-ribbons.R`; test 1's `.fr_lift_problems()` must be empty. Also run every test that reads `global.R` or `review.R` (`test-review-cards.R`, `test-app-review-copy.R`, the card-number tests) and check the app in the browser (`preview_start`). ⚠ Card 6's ID stays 6: ids are stable public references.
   - Facts for all four: `notes/ship_copy_facts_2026-10-09.md`.
2. **Marcus rules on the mode-struct lint** (`test-mode-struct-lint.R:71, :78`; `calibration/diag_mcmc_drift.R`, from `d2bd671`):
   - **(a) convert the driver**, my recommendation: resolve the mode the way `build_futures_ribbons.R` does (gate, pins, `ccx_check_mode_decode`, `ccx_mode_base`), then show that its 100k and 200k logs reproduce;
   - **(b) add it to `MS_BASELINE`**, which is a test edit.
   - The driver never runs the model, so the struct bug the lint guards does not bite. Per `~/.claude/CLAUDE.md`, neither was touched without his ruling.
3. **Still waiting on Marcus's wording (unchanged from the 10-08b/10-09 handoffs):**
   - card 4: `card4_audit_20261008_hilda29e.log`; its two tests fail by design until the copy changes;
   - card 8's draft text;
   - the constraint map's caption line;
   - the What-if blurb ("about a third" is now 29 %).
4. **Deploy** (shinyapps.io) is separate and Marcus's: the `SET-BEFORE-DEPLOY` URLs and the rest of `ccx_app_beta_blockers`.

## 4. Non-obvious state

- **Two places carry provenance:**
  - the shipped artifact's `provenance$promoted` (source path + md5, `key_draws` dropped);
  - its `provenance$draws_provenance` (chain seeds 20261002–05, RNG kind, seed placement, chain md5s, window (30000, 200000], thin 20, pool-thin 2).
  - The builder's own `seed` is NA, deliberately: it applied none.
- **`build_futures_ribbons.R` still refuses `--draws` output in `data/`.** The promotion script is the only path; the refusal message names it.
- **Committed evidence:**
  - the chain snapshots `outputs/mcmc_check_20261008j_hilda29e_{snap50k,final}/` and `outputs/mcmc_check_20261009_hilda29e_200k/`;
  - the full 200k band with `key_draws`, `outputs/diagnostics/futures_ribbons_mcmc_20261009_hilda29e_200k.rds` (the promotion's source);
  - the landing's `.out` files in `outputs/diagnostics/mcmc_200k_landing_20261009/`.
- **Kept, not mine to remove:**
  - `~/ccx_frozen/20261008j_mcmc`, the chains' frozen worktree at `00b1c09`. Needed only to extend the chains again; removing it is Marcus's call. Its chain files equal the 200k snapshot by md5;
  - `.claude/worktrees/friendly-einstein-26825b`, a spun-off task's worktree.
- **Untracked, not this session's:** the two `carbotope*.docx`, `outputs/diagnostics/smoke/`, `outputs/mcmc_smoke/`. Leave them.
- **`notes/card6_facts_2026-10-02.md` is superseded for its numbers** (it was `hilda33d` stage 1). It now points to the 10-09 facts note.
- **Memory:** `laplace_fails_on_fertilisation_ridge.md` is now ~11 KB. `INDEX_ccx_app.md` (14.8 KB) and `INDEX_diag.md` are still over the 14 KB soft budget, as before.
- `DESIGN.md` still carries the old −0.36 / 1.8× ocean climate effect (Marcus's spec; flagged, not edited).
