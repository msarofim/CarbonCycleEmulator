# HANDOFF 2026-10-06b — Marcus's 10-06 rulings APPLIED; H2 TESTED and PRICED; the suite is clean and nothing is running.

**Supersedes** `notes/handoff_2026-10-06_hilda33p_adopted.md` (which now points here).
- Written on Marcus's request, verbatim: "write a handoff for the next session."
- `main` is at this note's commit, pushed. Everything below is in `main`.

**Start here.**
1. Read `CHANGELOG.md` 2026-10-06 (j), then (c)–(i) (newest at the top). (k) is this handoff.
2. Then these memory files (shared store):
   - `ccx_h2_tested_and_priced` (new): H2's test and its futures stake;
   - `ccx_enso_response_too_early` (10-06 addendum): the seasonal rows hold the ENSO lag short;
   - `ccx_growth_objective_declined`: why the fit has no growth-rate term (asked twice, declined twice);
   - `frozen_tree_cited_as_only_copy` (new): check a tree isn't cited evidence before removing it;
   - `r_system_warns_not_errors`: `ccx_git_stamp()` is MERGED into `main`;
   - `ccx_hilda33p_adopted`: the canonical, and the wording items now applied.

## 1. State
- **The canonical is `hilda33p`** (objective #16), unchanged today. "BETA v1.0 CarboTope" runs on it.
- **The full suite at `15dbda6`: 6427 passed, 0 failed, 3 skipped (the standing three), 0 errors.**
  - Log: `outputs/diagnostics/suite_20261006_15dbda6.log`.
  - The commits after it change no code: the suite log, CHANGELOG, this note.
- **The app** was verified on `main` after the last app change:
  - card 4 carries Marcus's two sentences; card 7 the drafted `k_w` line;
  - the parameter table has the "Set" column (33 fitted, 10 held);
  - the Source section shows "This build has no repository link set" instead of a broken link;
  - no console errors.
  - The `ccx-app` preview is LEFT RUNNING on localhost:7788, from the repo.
- **Branches:** only `main`, locally and on `origin` (four merged branches deleted, 10-06 i). The two
  `.claude/worktrees/` folders are detached checkouts in the desktop app's reuse pool; leave them.
- **`~/ccx_frozen/`** (13 GB): every 10-05/06 tree is removed. Left, on no list: the September trees, `final_*`,
  `ribbons_*`, `suite_202609*`/`suite_20261001*`, and the `20261002ee_obj15_launch.*`,
  `20261005_suite_777877b_rerun_launch.*`, `20261005_suite_aa76fb5_launch.*` files. Removing them needs Marcus's OK.
- **Nothing is running** except the app preview.

## 2. Rulings today (Marcus, verbatim)
- On the 10-06 handoff's open items:
  - "Caveat sentence (Recommended)"; "Mark held rows (Recommended)"; "Fix eval-rate line (Recommended)";
  - "Assessment → hilda33p (Recommended)", "Housekeeping (Recommended)", "Merge git-stamp branch".
  - Not chosen: the 180-min default (stays), renaming `CCX_MS_BUDGET_MIN` (stays), the resume of #16's 8 starts.
- "Delete any obsolete branches."
- `carbotopecomments.10.2.26.docx` (his file, edited 10-06; untracked in the repo root):
  - "Card 4: re-measure the 'about three months'."
  - "Do we have a theory about why our fit for ENSO timing is so much sooner than the best estimate in the literature?"
  - card 4's plain and detail "Change to" texts (applied verbatim, in the app's CO₂ / El Niño style);
  - "Go ahead and fix the repo link, regenerate the port targets, change the pgrep advice, and correct the DESIGN.md
    factual error. Close the finished items. Add a line about k_w to the known issues tab. Keep rep_dC as a named
    standin. Find a citation for f_luc_wood = 0. Save the ra_ratio and sigma-audit items for the next model change."
  - "Do the H2 diagnostic and test."
  - His three "old comments" in that file were already applied on 10-02.
- Then: "why don't we have a term for that?" (the growth-rate timing; answered in chat from
  `ccx_growth_objective_declined`, no change made) and this handoff.

## 3. What today produced (CHANGELOG letter → result)
| | what | where |
|---|---|---|
| (c) | warming caveat names the mixing slowdown ("a third, smaller effect": 0.15 of 5.70 ppm); parameter table "Set" column | `R/mechanisms.R`, `app/R/params_meta.R`; `diag_warming_switch_split.R` |
| (d) | the multistart's end-of-run eval rate = the slowest restart's own rate (was wrong both ways: 0.033 for 0.29, 32.8 for 1.15) | `calibration/lib_ms_deadline.R` `ms_eval_rate_sec()` |
| (e) | git-stamp branch merged; the 26 post-10-01 drivers converted to `ccx_git_stamp()` | `R/provenance.R` |
| (f) | housekeeping: 8 trees + 27 files removed; two trees' only-copy evidence moved into the repo first | `outputs/diagnostics/obj16_landing_dryrun_20261005_ocgobm_tree/`, `cpuclock_smoke_20261005/start_files/` |
| (g) | the assessment re-based on hilda33p (§5 verdict, §7 acts: Marcus's placeholders) | `notes/assessment_2026-10-06_hilda33p_DRAFT.md` |
| (i) | obsolete branches deleted | — |
| (j) | the docx rulings; card 4 re-measured; the ENSO-timing answer; H2 test + stake; Q2; `f_luc_wood` cited | below |

**(j)'s numbers:**
- **Card 4:** a timing row at its measured weight puts the lag at 2.70 / 2.90 months (from the fitted 2.606):
  "about three months" holds (`diag_timing_row_reread.R`).
- **Why the timing is early:** moving the lag to 5 months costs −11.99; the seasonal-cycle rows pay 63 % (MLO −3.59,
  SPO −2.41), GCB's land sink −1.37. GCB's land sink is the largest pull OFF short lags (+2.78 of +5.62).
- **H2 test** (`diag_h2_time_shape.R`, against GCB Fig. S10 digitised by `data-raw/build_gcb2025_s10_ocean_climate.R`,
  gated on GCB's stated −0.20): CCX −0.48 ± 0.07 vs GCB −0.29 ± 0.05 GtC/yr per K (1.63×); the gap grows from ~0;
  emergence 1973 vs 1999.
- **H2 stake** (`diag_h2_futures_stake.R`; SST anomaly × 0.613 = GCB-sized): CO₂ in 2300 SSP5-8.5 −23.6 ppm (17–30 over
  GCB ±1σ), vvH −18.5, vvM −11.0, five lower markers < 3.5; 3–8 ppm at 2100.
- **Q2:** freezing Revelle buffering at 1750 removes 13 % of the year-to-year scatter (ENSO 36 %, warming 24 %).
- **`f_luc_wood` = 0:** cited at `CCX_F_LUC_WOOD_DEFAULT` (Dorheim et al. 2024 Hector §2.2.2; GCB 2025 Suppl. S.2.2);
  neither supports the debit's composition (72 % soil).

## 4. Open items (each is Marcus's to prioritise)
1. **The `k_w` line on card 7 is MY DRAFT** ("One fitted value is a compromise …"): his wording to approve or change.
2. **H2's next step.** The signature and the stake are measured. The options on record:
   - a refit at lower `kz` (`kz` is held by the sink and bomb rows; ~13–16 h on the Mac's CPU clock, or Torch);
   - a structural surface-DIC damping (needs a proposal);
   - or disclose it (no Known-issues card covers the ocean's climate effect yet).
3. **ENSO timing** (his question; the answer is in CHANGELOG 10-06 j). Untested, and cheap: re-profile the lag WITHOUT
   the seasonal rows, to tell real phase information from the two-box model absorbing its seasonal errors. Structural
   options: per-hemisphere lags; a land term with soil-moisture memory or driven by tropical land temperature.
   - ⚠ A growth-rate ROW was asked for on 09-26 and declined, and a timing-only row was ruled out 10-04 ("No row").
     Do not re-propose either without a NEW reason (`ccx_growth_objective_declined`).
4. **The assessment:** §5 verdict and §7 acts, including a version tag (`v1.0-hilda29l` no longer identifies what
   "BETA v1.0" runs; suggested `v1.0-hilda33p`).
5. **Before going public** (the app has never been deployed):
   - `APP_FEEDBACK_URL` (the Substack post) and `APP_REPO_URL` (the GitHub repo is PRIVATE: no public target yet);
   - re-time start-up on an idle machine (73 s recorded; ~90–150 s seen today under load) and check the plan limits;
   - claim the account name;
   - his review of the draft scenario descriptors (`app/global.R`) and the sink→source caveat (his 09-29 "might
     have to be a major caveat"; on no card).
6. **The LUC chart caption** (`app/R/plots.R` `NOTE_LUC_SPLIT`) still carries the longer "asserted … does not measure
   it" phrasing; only the "Where this number comes from" text took his 10-02 wording.
7. **The next model change** bundles: `ra_ratio` (+3.2 log-units), the σ-audit trio (`gcb_ocean_sink`'s uninflated σ,
   the `excess_c14_ocean` target set, `CCX_ICE_DISCREPANCY`), and whatever H2 / ENSO structure is chosen.
8. **Older `~/ccx_frozen/` items** listed in §1 (his OK to remove).
9. **Recorded, not fixed:** one transient "figure margins too large" on the Futures chart with FaIR ticked at 1024 px,
   seen once during a scripted burst of mode switches; never reproduced (2 live retries, 12 offline renders).

## 5. Non-obvious state
- **Stamps:** every driver uses `ccx_git_stamp()` (the lint fails on any other git call). A driver that writes under
  `R src calibration app data` passes its own output as `exclude`.
- **Port targets** (`calibration/torch/port_targets.csv`) are now hilda33p's (`a16583d`). Regenerate with
  `make_port_targets.R` (env `CCX_MS_STRUCT`, `CCX_MS_SEAS_ML`, `CCX_MS_PIN`) whenever the objective or pins change;
  the driver and `setup_torch.sh` STOP on stale ones.
- **`test-review-card-numbers.R`** ties numbers typed into Known-issues prose to the fit: card 4's "2.5 months"
  within one posterior sd of the lag (2.606 ± 0.407); card 7's "about 1,900" within one sd of `k_w` (1894.7 ± 53.7)
  and "1,446" = `KW_PRIOR_CENTRE`. A refit that moves them further FAILS it by design: update the copy with
  Marcus, not the test.
- **`test-mode-struct-lint`:** a test file that reads `readRDS(ccx_mode_file())` must also call `ccx_mode_base()`.
- **Coupled runs take their parameters from the SPINUP** (`spin$params`), not the vector: a changed vector needs its
  own `dg_spinup()`.
- **The S10 digitizer never downloads:** it needs `data-raw/downloads/gcb2025_supplement.pdf` (md5 `93a7e289…`, the
  file `diag_ocean_climate_gobm.R` pins); `download_data.R` has the entry, and MANIFEST.csv the row.
- **The app preview does not reload `global.R`:** restart it after edits; it takes ~90–150 s to serve.
- **Suites:** run with `options(testthat.progress.max_fails = Inf)`, from a frozen detached worktree with
  `data-raw/downloads/*` symlinked in (setup.R refuses without the run-time inputs).
- **`rm` with variables:** guard every path (`"${F:?}/${f:?}"`); the harness refuses an unguarded one.
- **Untracked, not this session's work:** `carbotopecomment.9.26.26.docx`, `carbotopecomments.10.2.26.docx`
  (Marcus's rulings files), `outputs/diagnostics/smoke/`, `outputs/mcmc_smoke/`.
