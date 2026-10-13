# HANDOFF 2026-10-13: the WTC refit LANDED and RULED; adopt it as `hilda31w` (the adoption commit is NOT yet done)

**Supersedes** `notes/handoff_2026-10-12f_wtc_refit_armed.md` (which now points here). Written on Marcus's request
("Yes, write the handoff note"), 2026-10-13 ~09:45.

- main = `21903f1` before this note's commit, **pushed**. The repo is clean except the three CarboTope `.docx` files in
  the root (Marcus's, untracked by convention; not touched).
- **Start here:**
  - CHANGELOG **2026-10-13 (b) → (e)**, then 2026-10-12 (gg) → (ii) for the night before;
  - memory [[ccx_wtc_label_built]] (its last paragraph is the current state) and [[objective_noise_floor_optimum_on_spike]];
  - `outputs/diagnostics/wtc_landing_20261013/` (the landing, its resume, the GATE 0 diagnosis).
- **First thing to do:** the adoption commit (§4 step 1).

## 1. What was done (2026-10-12 21:10 → 2026-10-13 09:45)

| step | outcome |
|---|---|
| MANIFEST branch | Merged `67d343f` after re-checking the handoff's condition: the nine sha256 = the rds provenance = disk; bytes = size. The CHANGELOG conflict was resolved as **(gg)**. The stale "NO MANIFEST rows" comment was fixed. The branch's later commits are content-duplicates of main's `4003692`/`065697f`: **nothing left to merge** (tree-identical in `data-raw/`). |
| App `nuc_share` | A static check (10-12 hh): both app forcing choke points pass it. The proof is a live app start on the adopted mode (§4). |
| Armed dry run | 22:33–22:57 on ONE start (id 001): every step rc 0 (10-12 ii; `outputs/diagnostics/wtc_chaindry_20261012/`). |
| The wave | 24/24 exit 0, ended 07:36. The armed land chain ran land → collect → basins → promote → Hessian → read, then **STOPPED at the module check's GATE 0: 1.18e-5 > 1e-5**. Committed as landed (`a9b6601`). |
| Diagnosis (10-13 b) | **The objective's NUMERICAL NOISE FLOOR, ~4–5× #17's under this label**, not a defect. `diag_objective_noise_floor.R` (env overrides added, `8a3fc26`) found: the same δ¹³C rows as #17; id 1 floors too; id 17 is on a spike (8/8 nudges down); the re-encode alone moves −9.6e-6; promote even refused id 2 at 1.018e-5. Real defects move the rows by 2.35–1.0e3 (`gate0_diagnosis/`). The same floor made **id 17's Hessian non-pd**: `h_ml` / `kz_deep_frac` had no 2 % plateau, fell back to 3e-4 in u, and read noise ≈ 110. |
| Rulings built (10-13 c, e) | `CCX_REPRO_TOL` **5e-5** (`R/calibrate.R`), read by promote GATE 4 **and GATE 5**, `recompute_hessian.R` GATE 1, and `fit_iav_module.R` GATE 0. A no-plateau Hessian direction takes its **most-stable grid step** (`fallback_how`). Test file `test-repro-tol-hess-fallback.R` (27): 7 mutations, all caught. |
| Resume (10-13 d) | Pre-fix Hessian + read quarantined (`outputs/quarantine/20261013_hess_fixed_fallback/`). Then three committed stages, so every stamp is clean: A Hessian `df4ebb6`, B read + check `292783d`, C ocean + scorecard `1f2f4e2`. Script and logs: `wtc_landing_20261013/resume/`. |
| Suite at `9200485` | **8012 passed, 2 failed (card 4, by design), 1 skipped**, 20.3 min. |

**The landing's numbers** (`outputs/diagnostics/wtc_refit_read_20261013_id017.log`):
- **id 17 = LP = NAT**: a basin of 13 starts at −1054.4959, with no NEAR. The next basins are at −3.49 and −5.03.
- **Likelihood +10.83 over REF** (seasonal +3.54, bomb ¹⁴C +3.29, ice cores +2.60, IntCal +0.92, GCB rows −1.07).
- **`bomb_share_NH` 0.8417 ± 0.032**, correlated −0.31 with `tau_ex`.
- **`seas_T_lag` 0.276 ± 0.287 months**: within 1 sd of its floor, and **r = +0.955 with `seas_lag_p_NH`**. The −3.5 / −5.0 basins hold it at ≈ 4.7–4.8 with `seas_lag_p_NH` ≈ 0.7.
- −H is positive-definite (condition 3.79e5).
- Futures (WTC − REF): SSP5-8.5 +12.26, vvH +5.68 ppm. GATE V passes (z −1.38).
- **Module check:** `w` −0.110 σ (over 0.1); module gain +0.013. Swapping its values into the MAIN objective at fixed free names costs **−0.348**, mostly in the seasonal CO₂ rows (`resume/module_pin_swap.log`).

## 2. Decisions (Marcus, verbatim, 2026-10-13)

- Reproduce gates: **"5e-5, all three (Recommended)"**; then GATE 5: **"Raise to CCX_REPRO_TOL (Recommended)"**.
- Hessian: **"Most-stable step (Recommended)"**.
- Module: **"No second pass (Recommended)"**. The −0.110 σ is recorded; the pins stay #18 pass 2's.
- **"Adopt id 17"**; the name **"hilda31w"**. "hilda31e" was offered beside it and declined. It is one letter from `hilda31pe`, this refit's new-basin start.
- **Mine, stated:**
  - The tolerance lives in ONE named constant rather than four literals.
  - The fixed 3e-4 stays for a direction with no finite interior step and for a stable NON-NEGATIVE plateau. Both are outside the ruling, and both are labelled.
  - The resume ran in committed stages, so no stamp reads `+dirty`.

## 3. Files

- **New:**
  - `tests/testthat/test-repro-tol-hess-fallback.R`;
  - `outputs/diagnostics/wtc_chaindry_20261012/`, `wtc_landing_20261013/` (incl. `resume/`, `gate0_diagnosis/`);
  - `objective_noise_floor_20261013_wtc.{log,rds}`;
  - `outputs/quarantine/20261013_hess_fixed_fallback/`;
  - `suite_20261013_9200485.log`.
- **Changed:** `R/calibrate.R` (`CCX_REPRO_TOL`, the fallback); `calibration/{promote_multistart_mode,recompute_hessian,fit_iav_module,diag_objective_noise_floor}.R`; `data-raw/build_nuc_nh_share.R` (comment); CHANGELOG.
- **The landed run:**
  - `calibration/output/multistart_20261012ff_…_prior_bomb_share_NH_seas_T_lag/` (with RUN_PROVENANCE);
  - **`calibration/output/refit_20261013_wtc_hilda_csl3v0kaidgbemwtc/`** (id 17 + Hessian);
  - `calibration/output/iav_module_20261013_refit_20261013_wtc_hilda_csl3v0kaidgbemwtc.rds` (the module check at it).

## 4. Next steps (in order)

1. **The adoption commit**, following `938c9cb` (hilda29e's):
   - `git mv` the refit dir to `refit_20261013_hilda31w_wtc_hilda_csl3v0kaidgbemwtc` (the hilda33p / hilda29e precedent).
   - `R/paths.R`:
     - `CCX_MODE_CANONICAL <- "hilda31w"`, with the rulings quoted;
     - `CCX_MODE_FILES` + `CCX_MODE_PINNED` (`hilda31w = TRUE`);
     - `CCX_MODE_CANONICAL_PINS` stays `CCX_MODE_OBJ18P2_PINS` (no second pass), with a comment saying so;
     - hilda29e stays registered as the previous canonical.
   - **`CCX_MODE_CANONICAL_MODULE_CHECK` → the 10-13 check file** (`R/paths.R:406`). It is read by `diag_card4_audit.R` and `test-review-card-numbers.R`.
   - **Remove the WTC reference-set branch** (`R/calibrate.R:2799–2821`) **and its tests together** (`test-ms-reference-set.R:360–386`; line 370 asserts the canonical is NOT of the label). Decide what happens to `CCX_MODE_WTC_*`: `diag_wtc_refit_read.R` and `diag_obj18_basins.R` read them, so keep the constants as records and drop only the live branch.
   - README canonical statement (factual: what it is, what it buys, what it costs); `make_bundle.sh` ships the dir.
   - **Then the suite.** 16 test files read the canonical; expect failures where a precomputed product is keyed to hilda29e (futures ribbons, app version, gate bounds, mode file, card numbers). **Report them; don't edit tests to pass.** Several are the post-adoption list below.
2. **Ask Marcus about the app release.** `APP_RELEASE_MODE` is `"hilda29e"` (`app/global.R:94`); at hilda29e's adoption the release was his separate question. Before any live app run, start the app on hilda31w: this is the run-time proof for 10-12 (hh)'s static `nuc_share` check.
3. **The post-adoption list** (10-12e §4 step 4):
   - re-measure `ALPHA_AS_FCO3`;
   - **MCMC 4 × 200k**: say the Torch verdict out loud first (memory `consider_torch_first`);
   - the **identifiability check**: posterior sd and correlations for `bomb_share_NH` (partners `tau_ex`, `bomb_total`; a fixed proxy as the fallback) **and now `seas_T_lag`** (partner `seas_lag_p_NH`, r +0.955 at the Laplace);
   - futures bands; app and card numbers; the suite; the `v1.1` tag.

## 5. Non-obvious state

- **Nothing is running.**
- **Worktrees in `~/ccx_frozen/`, all removable; their logs are committed:**
  - `20261012ff_wtc` (the run; landed byte-identical);
  - `_chaindry` (holds the dry run's uncommitted scratch mode file and `start_001` copy, deliberately not copied);
  - `_dryrun`;
  - `suite_20261012_{9967a63,f2af594,1e66077}` and `suite_20261013_9200485`.

  Marcus has not yet said to remove them.
- **The MANIFEST task's worktree** `.claude/worktrees/compassionate-chatelet-52df58` (branch at `6953a46`) is fully represented on main. The app made it, so it's the app's to clean up.
- **The resume scripts:** `~/ccx_frozen/20261013_wtc_resume.sh` (copied to `wtc_landing_20261013/resume/`). The armed chain and armed scripts are copied to `wtc_landing_20261013/` and `wtc_chaindry_20261012/`.
- **Noise-floor consequences that outlive this landing:**
  - Any reproduce gate on this objective needs ≥ ~5e-5.
  - A difference between stored logposts below ~1e-5 is NOT a difference: the basin's top four lie within 1e-5.
  - FD Hessian steps below ~1e-3 in u read noise here.
  - Still at 1e-5 and unruled: `diag_wtc_refit_read.R` `WR_REPRO_TOL` (its gate evaluates at the stored u: diff 0) and `diag_iav_redesign_price.R`'s own `IAV_REPRO_TOL`. The floor's SOURCE is still not identified, nor why the label made it larger.
- **The new objective's logposts are NOT comparable to #18's.** Compare on likelihood (the WTC read does).
- **Still Marcus's** (unchanged): the merged remote branch `origin/claude/recursing-hermann-a2f965`; the flux-trace default; the app never SHOWING `retried` / `converged`; the copy worklist; deploy items; card 4's two by-design failures; the CarboTope `.docx` files.
- **Memory sizes:** `INDEX_ccx.md` was 14.9 KB at 10-12f (over its 14 KB soft budget). Nothing was added to it this session; `ccx_wtc_label_built.md` grew.
