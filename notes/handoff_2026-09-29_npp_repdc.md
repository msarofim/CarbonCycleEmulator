# Handoff 2026-09-29 (b): ENSO / AOD switches, `rep_dC` futures, and the NPP_GLOBAL_PI arc

> Launch from `FaIRtoFrEDI/`, then `change_directory` here (CLAUDE.md). ⛔ **Never use a bare `cd` in a
> Bash call**; use `git -C` or absolute paths.
> **Read first:** this file, then CHANGELOG **2026-09-29 (e)–(k)**, then the memory via `INDEX_ccx_ref.md`
> (or the φ-arc sub-index it points to, if the 09-29 split has landed):
> - `ccx_enso_detrend_priced_0929`
> - `ccx_aod_mode_anomaly_ruled`
> - `ccx_land_2300_esm_benchmark`
> - `ccx_npp_global_pi_ruling_0929`
> - `ccx_rep_dc_lever_is_the_phi_loop`
>
> The previous handoff is `notes/handoff_2026-09-29_phi_sweep.md`.

---

## 1. What we were working on
The work started from the φ-sweep handoff's open list. The **refit base** is φ = 0 + the fert_k shape
prior (`hilda_csl3v0k`, scratch mode `calibration/output/multistart_20260928c_…/promoted_basin1/`).
From there, five threads:
- Price the ENSO detrend.
- Fix the AOD background.
- Follow up on `rep_dC`.
- Resolve `NPP_GLOBAL_PI`.
- Find an ESM benchmark for land carbon at 2300.

## 2. Decisions (Marcus) and results, in order
1. **Refit base = φ = 0 + shape prior (v0k)**, ruled.
2. **ENSO detrend: build both routes, then price them** (`enso_index`: demean default / detrend / relsst_lp).
   - Priced at v0k: −1.3 to −2.9 logpost. `q10` moves by +0.006; futures by ≤ 1.4 ppm.
   - ⇒ **The trend is not φ-like and does not hold `q10` low.** No Torch refit is queued for it. CHANGELOG (f).
3. **AOD: `aod_mode = anomaly` is RULED the improved version** — ON in the next refit label.
   - The default stays `legacy` (bit-identical), so objective #13 is untouched.
   - Gain at v0k: +0.54 unrefitted, +0.97 rebalanced. The decay time is measured (Pinatubo 1/e, 1.42 yr).
     CHANGELOG (h).
4. **ESM benchmark** (Koven et al. 2022, SSP5-8.5 to 2300): 0.89–1.28× PI land, computed. CCX gives 2.27×
   (`hilda29l`) and 1.63–1.65× (φ = 0). Both are above every verified model. CHANGELOG (g); note
   `notes/lit_2026-09-29_land_c_2300_benchmark.md`.
5. **`rep_dC` futures along CONVERGED ladders.** To 1σ:
   - `hilda29l`: +271 ppm (SSP5-8.5 2300).
   - φ = 0: +63 ppm. ⇒ **Its leverage is mostly the φ loop.**
   - ⭐ At the measured offset (0.776), φ = 0 fertilisation = `beta_max` 1.97 / `fert_k` 644, **inside the
     literature band**, for −45.0. The R2 prior ruling (09-23) still stands. CHANGELOG (h), (k).
6. **`NPP_GLOBAL_PI`: "1 and then 4".**
   - **Option 1 is applied:** the value stays 60, status provisional, with citations (TAR + brackets).
   - **Measured:** the model's 2001–23 NPP is **70** vs MOD17 52.75. The model has no pre-1750 clearing,
     so the constant IS its 1750 NPP.
   - **Option 4, ruled:** centre = mean of the verified totals = **56.06**; σ widened for n = 3 to the
     84 % one-sided UCB = **7.76**. Arms: A = v0k + AOD anomaly; B1 = A + the NPP row (NPP₀ fixed);
     B2 = + a fitted NPP₀ scale.
   - **POWER CHECK: B1 moves modern NPP by −0.01 GtC/yr.** The row is decorative at this σ, so nothing
     went to Torch.
   - **Option-1 scan** (`npp0_scan_20260929`): lowering NPP to ~55 costs ~−125, **57 % of it paid by NH
     bomb Δ¹⁴C.** The seasonal cycle barely pays (−2.6).
   - Hypothesis (untested): the unfitted land residence times set the land's bomb-¹⁴C uptake.
     CHANGELOG (i)–(k).
7. **`NPP_GLOBAL_PI` is left for a ruling** on potential vs actual. It turned out moot in model terms:
   see 6.
8. **Tests:** Marcus authorised extending the registry tripwires. `test-constants-batch.R:14` is extended
   (labels `hilda_csl3v0ka`, `hilda_csl3v0kan`). The 38-parameter count tests are to be extended only if B2
   is built.

## 3. Files (CCX `main`, all pushed; last commit `c6bf27e` + this handoff)
- **Switches:**
  - `R/forcing.R` (`CCX_ENSO_INDEX_CODES`, `ccx_enso_index_check`; `CCX_AOD_MODE_CODES`,
    `ccx_aod_forcing`, `ccx_aod_efold_yr`, `ccx_aod_mode_check`);
  - checks in `ccx_run_prepared` (R/cpp.R);
  - ps_year stamps `"none"` (R/periodic_spinup.R).
  - Data: `data-raw/build_enso_relsst.R` → `data/forcing_enso_relsst.rds`.
- **NPP:**
  - The NPP record is in both cores (`src/ccx_core.cpp` slots 8–9 → `$npp`; `R/model.R` record;
    `R/forcing.R` `ccx_run`). Tested in `tests/testthat/test-npp-record.R`.
  - `data-raw/build_npp_modern_target.R` → `data/obs_npp_modern_target.rds`.
  - `ccx_loglik(npp =)` → row `npp_modern`.
  - Labels `hilda_csl3v0ka` / `hilda_csl3v0kan` (R/calibrate.R).
- **Drivers:**
  - `calibration/diag_enso_index_price.R`, `diag_aod_mode_price.R`,
    `diag_rep_dc_ladder_futures.R` (env `RLF_DIR`/`RLF_MODE`/`RLF_TAG`);
  - `diag_rep_dc_product_ladder.R` (env `RPL_MODE`/`RPL_MODE_TAG`/`RPL_DATE`/`RPL_N_REP`);
  - `diag_model_npp_modern.R`, `diag_npp_row_power.R`, `diag_npp0_scan.R`;
  - `diag_audit_flags_screen.R` (merged from the subagent branch).
- **Tests:** `test-enso-index.R`, `test-aod-mode.R`, `test-npp-record.R`.
- **Notes:** `lit_2026-09-29_land_c_2300_benchmark.md`, `lit_2026-09-29_npp_global_pi.md`.
- **Outputs:** `outputs/diagnostics/*_20260929.*`, including `rep_dc_product_ladder_v0k_20260929/`
  (archived with job logs).

## 4. Open questions / next steps (all Marcus's)
1. **NPP next step.** Scan NPP₀ again with the land residence times free (`tau_leaf`, `tau_wood`,
   `litter_slow_frac`, `tau_soil_*`), and see whether the bomb-¹⁴C cost collapses. Or accept 70 vs ~56 as a
   named tension.
   - Build B2 only if a residence structure makes a lower NPP cheap.
2. **`rep_dC` at φ = 0.** Does "the measured offset puts fertilisation in the literature band" change the
   view of `rep_dC` for the φ = 0 lineage? (R2 was ruled on `hilda29l`, and its shelf "expires if the
   structure changes".)
3. **The next Torch refit** would be arm A (`hilda_csl3v0ka`) as the new baseline. Its launch, and whether to
   adopt φ = 0 (recompute_hessian, registration, app repoint), are still open from the previous handoff.
   - The ENSO index for it: demean unless Marcus picks otherwise (the pricing says it barely matters).
4. **Carried over:** the prereg P1 wording; the menu descriptors in `app/global.R`; the untested
   `f_luc_wood` and `kz_deep_frac` findings (the data prefer the `kz_deep_frac` floor; the Jacobian holds it).

## 5. Non-obvious state and traps
- **Nothing is running.** The frozen worktree `~/ccx_frozen/20260929_repdc_v0k` (`4471751`) is still there.
  Its only untracked content is the ladder outputs (archived) and the data symlinks, so it can be
  force-removed. The subagent worktree `.claude/worktrees/agent-a3e4f3a2c943c47a8` is merged and can go too.
- ⚠ **A git worktree lacks the gitignored `data-raw/downloads/*`.** Symlink them in, or the nuclear ¹⁴C
  source silently zeroes (logpost −1425.557 vs −1425.362).
- **Suite at `39d2056`:** only the named red (`test-mode-file.R:323`) after the lint fix and the label
  extension. The last full run predates `081bcbb`, but that file's own test passes.
- **Two identity numbers** for re-running anything:
  - v0k basin-1 stored logpost is **−1424.746523**; arm A at the same vector is −1424.207126.
  - v0k SSP5-8.5 2300 is **1388.3 ppm**, land 1.63×; `hilda29l` is 875.0 ppm, 2.27×.
- The `npp0_scan` uses an in-process `CCX_CONSTANTS` override. It is reset after the run; never leave it set
  in a session that then scores anything.
- The `npp_modern` row is scored ONLY under `npp_row == 1` (label `hilda_csl3v0kan`). Compare B1 with A on
  likelihood minus that row.
- **Memory:** `INDEX_ccx_ref.md` was over its 14 KB soft budget and is being split by a subagent. Check
  `INDEX_conv` / `MEMORY.md` for where the φ-arc lines went.
- `carbotopecomment.9.26.26.docx` is untracked and belongs to Marcus. Leave it alone.
