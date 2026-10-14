# HANDOFF 2026-10-14b: the hilda31w MCMC is read, the band SHIPPED, and the tie rule is now posterior stability

> ⚠ **SUPERSEDED 2026-10-14 by `notes/handoff_2026-10-14c_nuclear_source_promoted.md`.** Its §3 items 1, 4 (the nuclear warn) and the `~/ccx_frozen` list are done or changed there.

**Supersedes** `notes/handoff_2026-10-14_hilda31w_mcmc_complete.md` (which now points here). Written on Marcus's request
("Yes, write the handoff (Recommended)"), 2026-10-14 ~11:00.

- **Start here:** CHANGELOG **2026-10-14 (a) → (f)**; memory [[ccx_hilda31w_adopted]] (its last paragraph),
  [[ccx_cmap_tie_posterior_stability]], [[ccx_worktree_needs_downloads_linked]].
- main = `4acb215` + this note's commit, **pushed**.
  - The tree is clean apart from the three CarboTope `.docx` files in the root (Marcus's, untracked by convention).
- **Running at writing:** the full suite at `4acb215` in `~/ccx_frozen/suite_20261014_4acb215` (PID in
  `suite_20261014_4acb215.pid`). Its log is `outputs/diagnostics/suite_20261014_4acb215.log` in the MAIN checkout.
  - Expected reds: app-version (release) and card 4 ×2 (by design).
  - `test-cmap-tie` and `test-futures-ribbons` are now GREEN.
  - Anything else is new, so read it.

## 1. What was done today

| step | commits | outcome |
|---|---|---|
| (a) snapshot + read | `87d47e3` | Chains `cmp`-identical in `outputs/mcmc_check_20261014_hilda31w_200k/`. **NOT converged: the seasonal-lag ridge** (R-hat `seas_T_lag` 1.24, `seas_lag_p_NH` 1.20, `_SH` 1.15; ESS 13–19) from chain 4's 50–115k excursion (`seas_T_lag` to 2.5 months, `h_ml` 45 m as its shadow). Excursion draws move the band ≤ 0.28 of its width (`excursion_read/`). Identifiability: `bomb_share_NH` identified; `seas_T_lag` on its 0 floor; `h_ml` cut above by the substep cap (75.02 m, 2.7 % within 1 m). |
| (b) rulings + launches | `aac38b6`, `1c26e8e`, `17beded` | `pooled_u_thin2.rds` (17 000). `diag_mcmc_drift.R --names=`. New `diag_cmap_posterior_spread.R` (4 gates). The **unlinked-worktree incident**: nuclear ¹⁴C zero, caught by GATE MAP (0.962), relaunched linked. |
| (c) tie cut read | `78d3029` | Ruled statistic **93.3 pp** (all rows ties): unusable. **No margin cut separates stable from unstable rows.** Step-scaling test: no integrator jump; the cells are first-order slopes. |
| (d) tie rule shipped | `988465e`, `a69d606` | **Posterior winner stability** (tie if the winner loses in > 5 % of draws). `promote_cmap_stability.R` → `data/constraint_map_stability.rds`; `ccx_cmap_stab_problems()`; `test-cmap-tie` 47 / 0, mutation-tested. |
| (e) band landed | `753abc9` | 17 000 / 17 000. Chains ≤ 4.76 ppm (21 %; median 11 %), cell R-hat ≤ 1.036, not widening. vvH CO₂ 2150 814.9 / 825.8 / 837.9. |
| (f) band shipped | `4acb215` | `data/futures_ribbons.rds` md5 66c81912…; `test-futures-ribbons` 65 / 0. The HOLD stays. |

## 2. Decisions (Marcus, verbatim, 2026-10-14)

- Convergence: **"Pool all 4, build, test by chain (Recommended)"**.
- `--drop`: **"0 (Recommended)"**.
- `--pool-thin`: **"Thin ×2 within chain (Recommended)"**.
- The tie cut: **"Posterior spread, 100 draws (Recommended)"**. Then, after it read 93 pp: **"Posterior winner stability (Recommended)"**.
- Refused half-steps: **"Finite half only (Recommended)"**.
- The band: **"Ship the hilda31w band (Recommended)"**.
- Handoff: **"Yes, write the handoff (Recommended)"**.
- **Mine, stated:**
  - The stability shares ship as a SEPARATE `data/` file, gated to the map, rather than inside `constraint_map.rds`. The map rebuilds in 22 s; the shares need a 45-min posterior run.
  - The 5 % is the app's own 5–95 % convention.
  - A rebuilt map drops the takeaway (logged) until the stability is re-run.
  - `test-futures-ribbons.R`'s ship record (`.fr_ship_md`, source file) was re-pointed to the ruling. It was the expected red "until the band ships".
  - The hilda29e band was superseded, not bugged, so it was not quarantined.

## 3. Open items, in order

1. **Read the suite** (above). Compare with 8027 / 8 at `5f158b3`.
2. **Copy, all Marcus's:**
   - ⚠ **"influenced about equally by X (a%) and Y (b%)"** now also covers ties with UNEQUAL mode shares. It currently reads "CO₂ level — influenced about equally by Land uptake (34%) and Mixed layer & vertical mixing (22%)". The rule does not depend on the wording.
   - **The band's four copy items**, after which `APP_RIBBONS_HOLD <- NULL` in the SAME commit: the label (`promote_futures_ribbons.R --label=`, then `label_ruled` TRUE); card 6's title and text (`app/R/review.R`); the parameter panel's "not yet a posterior" clause; the temperature sentence (`APP_RIBBON_NOTE_TEMP`).
   - Card 7's "slightly" against +6.21; card 8's draft.
3. **The release:** v1.0 vs v1.1 (`APP_RELEASE_MODE`; app-version red until then), the full suite, the `v1.1` tag.
4. **Design questions still open (Marcus):**
   - The `h_ml` posterior is truncated above by a NUMERICAL limit (`CCX_SUBSTEPS_MAX` 256, 75.02 m at the mode), not by data.
   - The pure-R core runs none of the four forcing guards.
   - `ccx_nuclear_c14_annual()` only WARNS on a missing directory. A stop() under a flag would end the worktree trap structurally.
5. **If the map is ever rebuilt:** re-run `diag_cmap_posterior_spread.R --n=100` (~45 min on one core, in a LINKED worktree), then `promote_cmap_stability.R`. Otherwise the takeaway disappears.

## 4. Non-obvious state

- **`~/ccx_frozen/` (all from today unless noted; none removed; Marcus's word needed):**
  - `20261013_mcmc_hilda31w` (10-13): chains snapshotted and read. Removable.
  - `20261013_kw1446_profile`, `suite_20261013_5f158b3` (10-13): removable (handoff 10-14).
  - `20261014_band_hilda31w`: outputs landed byte-identical. Removable.
  - `20261014_cmap_spread`: outputs landed byte-identical. Removable.
  - `suite_20261014_4acb215`: RUNNING; removable after the log is read.
  - All of today's worktrees have `data-raw/downloads/*` symlinked in. The links are gitignored.
- **Preview :7790** (`ccx-app-7790`, started this session on hilda31w) may still be running. The takeaway was checked there.
- The excursion test's scratch scripts are committed in `outputs/mcmc_check_20261014_hilda31w_200k/excursion_read/` (README there).
- The failed unlinked tie-cut run's log is kept: `outputs/diagnostics/cmap_posterior_spread_20261014_hilda31w_n100_FAILED_no_nuclear.log`.
- **Still Marcus's (unchanged from 10-14):** the merged remote branch `origin/claude/recursing-hermann-a2f965`; the flux-trace default; the app never SHOWING `retried` / `converged`; the copy worklist and deploy items; card 4's two by-design failures; the CarboTope `.docx` files; the app's own `.claude/worktrees/compassionate-chatelet-52df58`.
