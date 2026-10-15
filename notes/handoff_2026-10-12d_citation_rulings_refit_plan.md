# HANDOFF 2026-10-12 (d) — review §4–§6 done; every citation item RULED; the one refit is PLANNED, not started; `~/ccx_frozen` cleared to the Trash

> ⛔ **SUPERSEDED by `notes/handoff_2026-10-12e_wtc_label_built.md`** (2026-10-12): the routing was ruled, the label
> `hilda_csl3v0kaidgbemwtc` built, tested and priced, and the refit procedure ruled. Read that one first.

**Supersedes** `notes/handoff_2026-10-12c_code_review.md`. Everything still open from its §4 is restated in §4 below.

Written on Marcus's request ("Yes, write the handoff note"), 2026-10-12.
- **Nothing is running** except the local app preview (§5).
- main = `cd6206d` before this note's commit. The last three commits (the rulings ledger) were NOT pushed before this note; this note's commit pushes them.

**Start here.**
1. **`notes/citation_rulings_2026-10-12.md`.** THE ledger: every ruling, Marcus's verbatim answer, the consequence, and what was verified. The implementation works from this file.
2. CHANGELOG **2026-10-12 (y)–(cc)**.
3. The three research reports behind the rulings (all read-only subagent work, spot-checked):
   - `notes/constants_citation_sources_7_2026-10-12.md` (the 7 items with nothing on disk);
   - `notes/photo_eps_sources_2026-10-12.md`;
   - `notes/pump_eps13_sources_2026-10-12.md`.
4. `notes/constants_citation_needs_2026-10-12.md`, the worklist whose ROW NUMBERS the ledger uses. ⚠ Its code line numbers have drifted (e.g. `model.R:4414` is now 4515), so re-grep before editing.
5. Memory:
   - [[ccx_app_beta_blockers]] (head updated: all citations ruled);
   - [[ccx_frozen_cleared_20261012]] (new);
   - [[ccx_intcal_sigma_is_age_years]].

## 1. What was done this session

| Item | Outcome |
|---|---|
| **Review §4 code items** (Marcus: "Review §4 code items") | (y), `e6de59c`. `CCX_MODE_RETIRED` gained the five missing names, with a new gate tying every `CCX_MODE_*_QUARANTINED` path to an entry (mutation-tested). Also: the dead app fallback mode path removed, `APP_HIST_YEARS`' end read from the GCB file, the periodic spin-up reporting annual-mean δ¹³C / Δ¹⁴C (`ccx_spinup_diagnostics()` now REQUIRES `d13c_atm` / `d14c_atm`), and the `ccx_run` roxygen block unfused. |
| **Review §5 dormant bugs** ("§5 dormant-bug guards") | (z), `eb9a256`. 12 of 13 now raise an error or warning; #13 (a LUC pulse × `luc_scale`) is documented; plus the `fert_k` `$` partial match. New `tests/testthat/test-dormant-guards.R` (24 / 0); every block FAILS on the pre-fix code. A Futures sweep gave 186 renders, 0 errors. The flat-emissions warning says "held FLAT" so that `dg_run()`'s muffle catches it. |
| **Review §6 canonical tests** ("§6 canonical-path tests") | (aa), `eb9a256`. New `tests/testthat/test-canonical-contracts.R` (27 / 0): gates 1–2 and R↔C++ parity on `hilda29e`, each ≥ 12× inside existing bounds, each with a power check. |
| **Full suite at `eb9a256`** | (bb): **7469 passed, 2 failed (card 4, by design), 3 skipped**, 18.1 min. Log `outputs/diagnostics/suite_20261012_eb9a256.log`. Pushed (`f084da9`). |
| **"Delete any obsolete material"** | (cc). `~/ccx_frozen` (42 GB) went to `~/.Trash/ccx_frozen_20261012/` (stat-verified). Also moved: the two merged `.claude/worktrees`, `outputs/diagnostics/smoke/`, `outputs/mcmc_smoke/` and `tests/testthat/_problems/` → `~/.Trash/ccx_repo_cleanup_20261012/`. Three merged `claude/*` branches deleted; the 08-22 stash dropped (its fix is in HEAD). Every file in `~/ccx_frozen` was git-blob-checked: 132,690 were in git, and the 427 non-junk files that were not are in `~/ccx_frozen_records_20261012.tar.gz` (byte-verified, with a README and the stash patch). **Nothing was hard-deleted.** The Trash frees no space until Marcus empties it; the disk is 95 % full. |
| **Citation walkthrough** ("walk me through the citation list rulings") | Five rounds of questions plus two literature searches. **Every item ruled.** See the ledger. |

## 2. Decisions (all Marcus's, verbatim, in the ledger)

**Values the refit changes:**
- `ALK_SURFACE` 2300 → **2303.4** (GLODAPv2.2023, 0–100 m, cos-lat cell-weighted; built as a `data/` product).
- `OCEAN_DEPTH` 3700 → **3682.2 m** (Charette & Smith 2010 Table 2), plus a rebuild of the GLODAP deep targets.
- `SALINITY_REF` 34.7 → **34.760**. Measured this session with the ALK recipe, which reproduces 2303.38 exactly: `calibration/lib_glodap_obs.R`'s `PUMP_DLAT` 5 / `PUMP_DLON` 10 / `PUMP_DZ` 250, flag 2, `depth < 100`, cos-lat weights, 913 cells; the LS-only value is 35.005. Rebuild `data/carbonate_coefs.rds` and check `RHO_SEAWATER`'s S 35.
- `CCX_SST_SEAS_LAG` 1.32 for both hemispheres → **per hemisphere: NH 1.325, SH 1.536**, READ from `data/obs_seasonal_clim.rds`, in both cores.
  - ⚠ The product's SH `model_lag` (7.54) omits the sign flip. Read SH as `peak_month − 0.5` (verified: the SH term −A·sin(2π(t − (3.5+L)/12)) peaks at 0.5 + L).
- `FORC_NUC_NH_SHARE` 0.95 → **a per-year NH share** from the 22-country files: SH = Argentina + Brazil only; 0.942 (1984) to 1.0; pooled 0.993; no data 1950–51.
  - Marcus: "Are we already refitting? If so, do the best option scientifically." Per-year was chosen because the model's GLOBAL total already sums the same per-year rows. The files have reporting gaps (SH 0 in 2010 and 2023), and the split must stay consistent with that total.
- Photosynthetic ε: live 15.6 → **16.2** in CCX's `1 − ε/1000` form, = Still et al. 2003's Δ 16.5 ‰ (verified via the EarthRef abstract).
  - Also fix the registry errors: Lloyd & Farquhar's 14.8 is at 21 % C4, not 25 %; the "15–18" range is not in Still or Suits.
  - Document the C3-net-sink limitation.
- `PUMP_EPS13_ORG` −20 → **−22 ‰**, one constant, surface-DIC reference. Anchor: Claret, Sonnerup & Quay 2021's deep δ¹³C–PO₄ slope −1.01, giving −20.07 vs deep DIC (checked against the PDF).
- **FITTED (+2 names → 31 fitted):**
  - the bomb ¹⁴C NH delivery share, prior **U[0.77, 0.98]**, then an identifiability check (posterior sd and correlation with `tau_ex` / `bomb_total`), with a fixed proxy as the fallback;
  - `CCX_SEAS_T_LAG`, prior **U[0, 6] months** (logit on the box), NOT centered on the old 2.0.
- **IntCal σ:** use the published Δ¹⁴C σ (column 5) of `data-raw/downloads/intcal20/intcal20.14c` (sha256 `974a6664…168e`). Add the `download_data.R` / `MANIFEST.csv` entry and rebuild `data/obs_d14c_intcal20.rds`. ⚠ `rintcal` is NOT installed; read the file.
- **Diagnostic only, no refit:** `P_canon` 2.04 → **1.88** (Kovaltsov 2012, verified; note 1.75 Roth & Joos 2013); area 5.10066e14 m² (Moritz 2000); Avogadro and seconds-per-year READ from the registry.

**Kept and cited (no value change):**
- `NPP_GLOBAL_PI` 60, with Bastos 2016 added;
- the `bomb_total` prior sd 0.10, as a ruled 3.6× inflation;
- `PUMP_EPS13_CARB` +1 (bracket 0 to +2);
- `CCX_SEAS_PHI_EFF`: NH 75 stored in a product with a reproduction test; SH −30 RULED with its 08-20r record;
- the cite-as-is sweep: FCO3, FOSS share, rep δ¹³C, the bomb prior center reading `CCX_BOMB_REF`, obliquity, the +10 days, `JOOS_PPM_PER`, the NPP NH anchor, the ENT peak month;
- the not-live rows, marked "not live".
- **Scope:** physical constants only. Priors, error σ's and the pool structure become explicit "judgement" / "ruled" entries; R13_VPDB / R14_STD citations completed; `sst_hs` sourced.
- Caveats stated with the approvals: the FOSS share is EDGAR's 1970–2012 value held constant from 1750; FCO3 was measured at an ancestral mode; rep δ¹³C is a midpoint, not a flux weighting.

**Mine, stated:**
- the photo ε and pump recommendations;
- reading SH's lag from `peak_month`;
- the per-year nuclear split with gaps kept;
- the Trash-not-delete approach, plus the records tarball.

## 3. Files

- **New this session:**
  - `tests/testthat/test-dormant-guards.R`, `tests/testthat/test-canonical-contracts.R`;
  - `notes/citation_rulings_2026-10-12.md`, `notes/constants_citation_sources_7_2026-10-12.md`, `notes/photo_eps_sources_2026-10-12.md`, `notes/pump_eps13_sources_2026-10-12.md`;
  - `outputs/diagnostics/suite_20261012_eb9a256.log`.
- **Code changed:**
  - `R/paths.R`, `R/spinup.R`, `R/periodic_spinup.R`, `R/forcing.R`, `R/climate.R`, `R/cpp.R`, `R/importance.R`, `R/likelihood.R`, `R/model.R`, `R/calibrate.R` (the kz prior);
  - `src/ccx_core.cpp` (state row guards);
  - `app/global.R`;
  - tests: mode-file, spinup-diagnostics, importance, likelihood, climate, ui-year-bounds-lint.
- **Outside the repo:** `~/ccx_frozen_records_20261012.tar.gz`; `~/.Trash/ccx_frozen_20261012/`; `~/.Trash/ccx_repo_cleanup_20261012/`.
- **Pending (the implementation):** see §4.

## 4. Next steps (in order), and what is still Marcus's

**⛔ FIRST DECISION, before any code: how the changed constants reach the objective.** `ALK_SURFACE`, `OCEAN_DEPTH`, the salinity (via `carbonate_coefs.rds`), `PUMP_EPS13_ORG`, the photo ε and the IntCal file are all GLOBAL reads today. Changing them in place moves EVERY registered mode's stored logpost, and `test-mode-file` reproduces those. There are two precedents:
- **(a) structure-block routing.** The `hilda_c` idiom: `alpha_photo_eps` is a block field, absent = the old value, so "every registered file stays bit-exact". A NEW label carries all the new values and the two new fitted names. Versioned data files (deep targets, carbonate coefficients, IntCal) are selected by the label. **Marcus names the label** (he always has).
- **(b) global change plus restamp.** Like the 09-16 e hygiene batch and objective #12: restamp the registered modes under the new objective, and quarantine what it supersedes.

Ask Marcus, with that pro/con. My lean is (a): the old canonical stays reproducible for the like-for-like comparison.

**Then:**
1. **Data products**, each with a `data-raw/` script, a `MANIFEST.csv` row and a versioned `.rds`:
   - the GLODAP surface ALK and salinity product;
   - the carbonate coefficients at S 34.760;
   - the deep targets at 3682.2 m;
   - IntCal column 5;
   - the per-year nuclear NH share;
   - the SST lags read per hemisphere;
   - the PHI_EFF NH argmin (store it, and add a reproduction test).
2. **Code, in BOTH cores, with parity tests:**
   - the per-hemisphere SST lag;
   - the nuclear share as a per-month forcing input. The ¹⁴C tag's 2×2 solve (`R/c14_tag.R`) must go per-month, and `CCX_TAG_MIN_SHARE_GAP` must hold in every month the tag is used. The fitted bomb share (up to 0.98) can approach the nuclear per-year share (down to 0.942).
   - the bomb share and the respiration lag as fitted parameters, with the ruled priors. ⚠ A new parameter name must NOT prefix an existing one (grep the table; R's `$` partial-matches);
   - photo ε 16.2 and pump org −22;
   - `P_canon`;
   - the registry citations and "judgement" entries.
3. **Suite.** The canonical-pinned tests will fail BY DESIGN once the objective moves, and move with the adoption, as at past adoptions. Report them; don't weaken them.
4. **Refit.** Multistart from `hilda29e` plus dispersed starts, the landing gates, Hessian, then **Marcus's adoption ruling**.
   - **Say the Torch verdict out loud** ([[consider_torch_first]]): the Mac is ~2× faster per evaluation and ran every recent refit and MCMC. Torch wins only as a 24-wide parallel multistart, which Marcus must submit (I can't authenticate). Check `uptime` first.
5. **After adoption:**
   - the bomb-share identifiability check;
   - MCMC (4 × 200k, as 10-09);
   - the futures bands;
   - the app and card numbers;
   - the suite;
   - **the `v1.1` tag** (name it after the new mode).

**Also still Marcus's:**
- whether to delete the merged remote branch `origin/claude/recursing-hermann-a2f965` (asked; no answer);
- emptying the Trash (42 GB + 5.7 GB);
- the flux-trace default;
- the app never SHOWS `retried` / `converged` (copy);
- the whole copy worklist (`notes/beta_copy_worklist_2026-10-12.md`), plus card 6's title and the pulse box's "about 1.4 °C";
- deploy: `SET-BEFORE-DEPLOY` ×2, start-up re-timed on an IDLE machine, hosting limits;
- unchanged from 10-12c: the early-drawdown question, the tie spread, card 4's two by-design failures, the cards 2/3 ¹⁴C facts, the residual strip, card 8, the constraint-map caption, the What-if "about a third", the held-era diagnostics.

## 5. Non-obvious state

- **App preview:** `127.0.0.1:7788` (launch config `ccx-app`, pid 44779), started on `d36cda1`-era code. Since then `global.R` changed only in the derived history year (same value) and the removed fallback path, so it shows the same numbers. Restart it before any visual check.
- **The research subagents' fetched PDFs** are cached under this session's `~/.claude/projects/…/00c84ac3-…/tool-results/`. That is session-scoped; a fresh session will not find them. The locators in the three reports are what persists. Locators marked **[HTML]** were read through a helper model's extraction and need an eye check before they go into the registry.
- **`CarboTopeSubstack.docx`** in the repo root is Marcus's live Substack draft, edited 10-12 14:37. It is gitignored (`.gitignore:35`). Never touch it. The three comment `.docx` files are untracked and also his.
- **New frozen copies for long jobs still go under `~/ccx_frozen/`** (the convention stands). The directory is currently gone; recreate it.
- **The R core warns 480× per 20 years at the canonical** with "Temperature outside fitted range [2.0, 35.0] degC": the HS box sits at 1.6–3.3 °C, below the carbonate-constant fit. It's harmless (both cores extrapolate alike), but any driver running the R core will flood its log.
- **Memory sizes:** `INDEX_ccx_app` 15.3 KB (over its 14 KB soft budget, under the 18 KB hard one); `INDEX_infra` 9.2 KB.
