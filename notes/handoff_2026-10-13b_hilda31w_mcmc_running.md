# HANDOFF 2026-10-13b: hilda31w ADOPTED, its test ledger APPLIED; the MCMC band is RUNNING; the product rebuilds are next

**Supersedes** `notes/handoff_2026-10-13_hilda31w_adoption.md` (which now points here). Written on Marcus's request
("Yes, write the handoff note"), 2026-10-13 ~12:00.

- main = `7ceb638` before this note's commit, **pushed**. Repo clean except the three CarboTope `.docx` files in the
  root (Marcus's, untracked by convention; not touched).
- **Start here:** CHANGELOG **2026-10-13 (f) → (j)**; memory [[ccx_hilda31w_adopted]] (current state, last paragraph);
  `outputs/diagnostics/ledger_20261013_hilda31w/` and `outputs/diagnostics/mcmc_launch_20261013_hilda31w/` (READMEs).
- **First thing to do:** confirm the 4 MCMC chains are alive (§5), then the product rebuilds (§4 step 1).
- ⭐ **UPDATE 10-13 ~12:50: §4 step 1 is DONE** — CHANGELOG **2026-10-13 (k)** (`327de2d`..`526a2a6`, pushed). Three rulings
  were taken on the way (map grouping, the stake's G3 split, panel #7). `test-cmap-tie` is RED **by ruling**: the tie cut's
  re-measurement is deferred to the MCMC read (no near basin in the WTC wave). Chains at ~12k/200k after 65 min, so
  ~18–19 h in all (≈ 05:30–06:30 EDT 10-14). **Next is §4 step 2**, and it now carries the tie-cut method question.
- ⭐ **UPDATE 10-13 ~13:40: §4 step 4's "start the app on hilda31w" is DONE** — CHANGELOG (m): 12 / 12 headless, every tab
  live, no output error. A fresh app is on **:7790** (`ccx-app-7790`); :7788 still holds hilda29e.

## 1. What was done (2026-10-13 ~10:00 → 12:00)

| step | commit | outcome |
|---|---|---|
| (f) Adoption | `2b1c603` | Refit dir renamed `refit_20261013_hilda31w_wtc_hilda_csl3v0kaidgbemwtc` (md5 unchanged). `R/paths.R`: canonical `hilda31w` (registered, PINNED); pins stay `CCX_MODE_OBJ18P2_PINS`; `CCX_MODE_CANONICAL_MODULE_CHECK` → the 10-13 check file (pre-rename name kept, as at 10-08; its base_md5 matches). The WTC reference-set branch removed with its test (15); `CCX_MODE_WTC_*` kept as records. README statement; `make_bundle.sh` ships the dir. |
| (g) Suite + ledger | `220ba63` | Suite at `2b1c603`: **7865 / 32 failed / 12 errors / 4 skips**, 19.3 min. 44 entries classified, no test edited. All 12 errors were TEST-built inputs not label-aware (forcing without `nuc_share`; the legacy 3700 m grid vs 3682.2). With an 11-line patch in a scratch tree, gates 1–2 and R↔C++ parity PASS at hilda31w. One real app gap: no `APP_PARAM_META` rows for the two new names. |
| (h) Ledger applied | `e6a27a9` | All as ruled. Every edited file passes; only card 4's two by-design failures remain. `mechanisms:328` re-measured by a new driver `calibration/diag_mechanism_sweep.R` (`50867d7`): old construction 8 crash / 40 warn / 16 clean of 64; the app's 127/127 clean. |
| (i) fCO3 | `2aacfe1`, `f6088ac` | New driver `calibration/diag_fco3_at_mode.R` (`8e53a05`): hilda31w **0.0926** (2024) / 0.1190 (1750); hilda29e 0.0922 / 0.1186; worth ~0.0025 ‰. KEPT at 0.082, recorded in its source text. |
| (j) MCMC | `e83e228`, `7ceb638` | First smoke could not start chains 1–2: the 2× starts crossed the P8 wall. Fixed as ruled (redraw until finite). Smoke 4 × 300 passes. **Production launched 11:42 EDT.** |

## 2. Decisions (Marcus, verbatim, 2026-10-13)

- Ledger: **"Approve all (Recommended)"**. Parameter labels: **"Use the drafts (Recommended)"** — `bomb_share_NH` "Share of
  bomb-test ¹⁴C released in the Northern Hemisphere" (—), `seas_T_lag` "Delay between the seasonal temperature swing and
  soil respiration" (months). App release: **"Hold until rebuilt (Recommended)"**. Card 7: **"about 1,850"**.
- MCMC: **"Launch on the Mac (Recommended)"**; starts: **"Redraw until finite (Recommended)"**. fCO3: **"Keep 0.082,
  record it (Recommended)"**. Products: **"Rebuild all three (Recommended)"**.
- **Mine, stated:**
  - test (15) was removed with the branch, as the previous handoff scoped it: it is the spec of deleted code.
  - The README's 2300 number is against hilda29e ITSELF: +11.56 ppm (1486.85 vs 1475.29). The read's +12.26 is against REF (hilda29e under the new label).
  - The legacy fCO3 recipe was dropped as an artefact (SH 0.616 at seas_ml 1); not reported.
  - The fCO3 epoch question (present day vs 1750) is recorded as Marcus's, not resolved.

## 3. Files

- **New drivers:** `calibration/diag_mechanism_sweep.R`, `calibration/diag_fco3_at_mode.R`.
- **Changed:** `R/paths.R`, `R/calibrate.R` (branch removed), `R/constants.R` (fCO3 text only),
  `calibration/run_mcmc_check.R` (the start rule), `calibration/torch/make_bundle.sh`, `app/R/params_meta.R`,
  `app/R/review.R` (card 7), README, CHANGELOG; 11 test files (ledger).
- **Records:** `outputs/diagnostics/suite_20261013_2b1c603{,_ledger}.log`, `ledger_20261013_hilda31w/`,
  `mechanism_sweep_20261013_hilda31w.{log,rds}`, `fco3_at_mode_20261013.{log,rds}`, `mcmc_launch_20261013_hilda31w/`.

## 4. Next steps (in order)

1. **The three product rebuilds** (ruled). Each from a CLEAN commit (the stamp covers R, src, calibration, app, data),
   BLAS pinned, then report what moved and any card copy whose typed claim stops holding.
   - **Constraint map:** `Rscript calibration/diag_constraint_map.R`. "Main fit only" (10-08 ruling). Move `CM_DATE`
     (`"20261008e"`, line 69) to the new tag; check the hilda29e-specific comments (lines ~182–215) still describe the
     families. `test-constraint-map` 6/7 and the `cmap-tie` skip should clear.
   - **pulse_vs_tcre:** `Rscript calibration/diag_pulse_vs_tcre.R` (reads the canonical; dated output). Clears
     `test-pulse-linearity` and its two skips. The app's `APP_PULSE_LIN_*` copy is checked by that test.
   - **Card 8 (ocean-climate card), a CHAIN** — `build_ocean_climate_card.R` only COLLECTS three products, md5-gated
     to the canonical, and its inputs list (lines 24–28) must move:
     - OC: **already exists** — `outputs/diagnostics/ocean_climate_gobm_20261013_wtcid017.rds` (resume stage C).
     - TS: `CCX_H2_SERIES=<the OC file> Rscript calibration/diag_h2_time_shape.R`.
     - FS: `diag_h2_futures_stake.R` needs hilda31w entries in `HF_OC_RDS` (line 52) and `HF_REC_BY_MODE` (line 69).
       The G1 reference comes from an INDEPENDENT path: `Rscript calibration/diag_app_ssp585_ref.R` (~1.5 min) at
       hilda31w; expect ≈ 1486.85 (the read's br_futures value).
     - Then the builder. ⚠ Card 8's headline "about twice as strongly as ocean models do" (2.16× at hilda29e) must be
       re-checked against the rebuilt numbers; the card text is Claude's draft awaiting Marcus's wording.
2. **The MCMC read**, once the chains finish (~15–23 h from 11:42, i.e. ~03:00–11:00 EDT 10-14):
   - `Rscript calibration/read_mcmc_check.R --dir=<snapshot>` at a common window, as at hilda29e (snapshot the chain files into the repo first).
   - ⚠ h_ml is bounded ABOVE by the P8 wall (75.48 m) ~6 m from the mode, as well as by the 42.5 m floor: read the near-wall share, not just R-hat.
   - **Identifiability:** posterior sd and correlations for `bomb_share_NH` (partners `tau_ex`, `bomb_total`; a fixed proxy as the fallback) and `seas_T_lag` (partner `seas_lag_p_NH`, r +0.955 at the Laplace; near its 0 floor).
3. **The band:** `build_futures_ribbons.R --draws=<pooled_u>` (hilda29e: 14 000 draws ≈ 2.5 h on 8 cores), then
   `diag_mcmc_band_by_chain.R`; `test-futures-ribbons` names the shipped mode (`.fr_ship_md`).
4. **App and card numbers; the release** (Marcus: v1.0 vs v1.1, `APP_RELEASE_MODE`; until then app-version is a known
   red). **Before any live app run, start the app on hilda31w** — the run-time proof of 10-12 (hh)'s static `nuc_share`
   check. Then the full suite and the `v1.1` tag.

## 5. Non-obvious state

- **RUNNING: the MCMC**, frozen worktree `~/ccx_frozen/20261013_mcmc_hilda31w` at `e83e228`.
  - PIDs in `~/ccx_frozen/20261013_mcmc_hilda31w.pids` (9189–9192). Check them with `kill -0`, NEVER `pgrep -f`.
  - Logs: `~/ccx_frozen/20261013_mcmc_hilda31w_chain{1..4}.out`.
  - Chain files: `outputs/mcmc_check_20261013_hilda31w/chain_{1..4}.rds` IN THE WORKTREE.
  - Exactly resumable: re-run `~/ccx_frozen/20261013_mcmc_hilda31w_launch.sh`. Do NOT add `--commit`.
  - Starts: chains 1–2 after 2 redraws, 3–4 after 0 (recorded as `start_redraws`).
- **Also running, not mine:** a Shiny preview on :7788 from `app/`, started 10-12 14:02. It holds hilda29e in memory.
- **Worktrees in `~/ccx_frozen/`:** ⭐ **UPDATE 10-13 ~13:05: the nine removable trees below are REMOVED** (Marcus asked;
  CHANGELOG 10-13 (l) lists what was checked). Only `20261013_mcmc_hilda31w` remains.
  - In use: `20261013_mcmc_hilda31w`.
  - Removable, made this session: `suite_20261013_2b1c603`; `ledger_20261013_2b1c603` (the scratch tree, with the harness patch applied).
  - Older, from the previous handoff: `20261012ff_wtc`, `_chaindry`, `_dryrun`, `suite_20261012_{9967a63,f2af594,1e66077}`, `suite_20261013_9200485`.
  - **Marcus has not said to remove any.**
- **Flagged, not changed:**
  - Card 7's sentence after the number ("The data slightly prefer the literature value…") was measured at hilda33p (10-05 a). It is not re-measured at hilda31w.
  - `MC_LP_TOL` (1e-5) is not under `CCX_REPRO_TOL`. It passed with diff 0, since the gate evaluates at the stored u. Also still unruled at 1e-5: `WR_REPRO_TOL` and `IAV_REPRO_TOL`.
  - GATE S's blind phase moved 4.10 → 4.38. The per-hemisphere ERSSTv5 SST lag is a candidate cause, inferred and not tested.
- **The new objective's logposts are NOT comparable to #18's.** Compare on likelihood.
- **Still Marcus's** (unchanged):
  - the merged remote branch `origin/claude/recursing-hermann-a2f965`;
  - the flux-trace default;
  - the app never SHOWING `retried` / `converged`;
  - the copy worklist and deploy items;
  - card 4's two by-design failures;
  - the CarboTope `.docx` files.
  - New: `app/DEPLOY.md:36` still names hilda33p as the release's cut mode (stale since 10-08).
- **Memory:** the root `MEMORY.md` routes the canonical to [[ccx_hilda31w_adopted]], and its content is ~12.1 KB (soft 12 KB). `INDEX_ccx.md` is 14.8 KB (soft 14), net −116 B this session.
