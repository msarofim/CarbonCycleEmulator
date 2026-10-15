# Handoff 2026-09-30 (c): D2 and D3 are built and screened. Next arc: the refit infrastructure, then the refit

> **Session start.** Launch from `FaIRtoFrEDI/`, then `change_directory` here (CLAUDE.md). ⛔ Never use
> a bare `cd` in a Bash call; use `git -C` or absolute paths.
>
> **Read first:**
> 1. this file;
> 2. CHANGELOG **2026-09-30 (i)–(o)**;
> 3. memory:
>    - `ccx_d2_d3_build_0930.md` (what was built, the form lesson, the screen results);
>    - `ccx_rulings_0930_nonco2_imbalance_app.md` (D1–D4, plus the design sub-rulings appended today);
>    - both are indexed in `INDEX_ccx_phi.md`;
> 4. `notes/prereg_2026-09-30c_nonco2_drivers_imbalance.md`: the design, the predictions registered before
>    every run, and their scores;
> 5. `notes/lit_2026-09-30_nonco2_land_sink_drivers.md`: the receipts (spot-checked).
>
> The previous handoff is `notes/handoff_2026-09-30b_nonco2_imbalance.md`. Its steps 0–3 are DONE here.
> Its steps 4–6 are the plan below.

---

## 1. What this session did

All committed and pushed (`d2790be..3eb4fe2`, plus this handoff).

| step | outcome | CHANGELOG |
|---|---|---|
| D3 preview (fixed vector) | Today's GCB imbalance + cement (0.63 GtC/yr) is split land 56 %, E_LUC via `luc_scale` 37 %, ocean 12 %. RAW I(t) is 64 % interannual noise | (i) |
| D3 machinery | Shares on the simplex move the two GCB sink targets; absent = objective #13 bit-exact; mutations M1–M8 caught | (j) |
| D3-alone screen | P-D3-1..4 PASS: **fertilization RISES 2–5 %**, `luc_scale` → 1 | (k) |
| D2 literature pass | Subagent, spot-checked. (a) N dep supported but 7–9 % of S_LAND; (b) a POSITIVE greening term is not supported; (c) a 1750 deficit is contradicted, and regrowth is already in net E_LUC | (k) |
| Rulings | See §2 | (l), (m) |
| D2 build | N-dep forcing data (emissions proxy), cited constants, greening term, N-retention flux; all OFF by default; all mutation-tested | (l), (m) |
| A form flaw, caught by the pre-registered gate | The NPP-multiplier form's sink tracked d(ndep)/dt (0.37 kg C/kg N vs the literature's 0.6–8.7). Replaced by the ruled RETENTION FLUX | (l), (m) |
| D2 screens | Multiplier form (the record) and the ruled forms | (l), (n) |
| D3 defaults | Set to the ruling (smooth + cement) | `3eb4fe2` |

**The headline, from the screen on the ruled forms** (costs are UPPER bounds: 11 of 29 names re-fitted; futures
are quoted only from a full refit, per the R2 lesson):
- The record WANTS the N-retention sink at **4–6 kg C/kg N**, the literature's central value: +5.3 log-units
  (N alone), +7.4 (N + greening).
- It spends it on fertilization: **enh(410) −12 % / −19 %**.
- Modern NPP moves **69.6 → 67.7 / 66.8**, against the observed 56.1 ± 7.75. D4 is moving, NOT resolved.
- Greening fits **≈ 0** in every arm, and q10 FALLS. P-D2-4 fails in every arm, so the record and the
  literature agree there is no greening term.
- **N + greening + D3 is the only combination that moves the future toward Koven**: z(2100–2200) 2.27 → 1.93,
  K 872 → 799 (more saturating), SSP5-8.5 2300 +61 ppm. ⚠ The +61 mixes the fertilization shape, `luc_scale`
  (which also scales scenario land use) and the ocean. Decompose it before attributing.

## 2. Rulings (Marcus, 2026-09-30, via the question tool; the chosen option labels verbatim)

- **D3 I(t):** "Smooth + cement". An 11-yr centered mean (window shrinking at the ends) of (imbalance + cement
  carbonation); constant shares.
- **D2 (a) forcing:** "Emissions proxy". NOx-N + NH₃-N above 1750, × land fraction 0.60, × NH share 0.83.
  SSPs are ratio-harmonized to the CMIP7 history, converging by 2050.
- **D2 (a) form:** "Retention flux". F_h = `ndep_ret` × 1e-3 × max(ndep_h, 0) GtC/yr, atmosphere →
  `soil_slow`, at `alpha_photo`. The prior on `ndep_ret` is lognormal, center 3.9 kg C/kg N, "2-sigma spanning
  0.6–8.7".
- **D2 (b):** "Sign-free prior". NPP × exp(`npp_tsens` · GMST), `npp_tsens` ~ N(0, 0.029) /K.
- **D2 (c):** "Don't build". `luc_scale` is the model's existing recovery-like freedom (~0.23–0.26 GtC/yr).
  Say so in the assessment.
- Also from Marcus: "yes, write the handoff note".

Standing from before: 0–1 m; the inert pool; the K prior stays 0.35; stock readouts include every pool; the app
is unfrozen (`v1.0-hilda29l` stays the record tag); **the arm-A refit waited for D2/D3, which are now built.**

## 3. The plan: the next arc, in order

### Step 1: refit infrastructure (code; no fit yet)
The four new names reach the model today ONLY as `base_params` fields: the screens set them inside the logpost
closure. A refit cannot fit them until they are in `CCX_PARAM_TABLE`.

- **Table entries** (`R/calibrate.R`), priors read from `R/constants.R`:
  - `ndep_ret`: `tr = "log"`, prior `dlnorm(x, log(NDEP_RET_PRIOR_CENTRE), NDEP_RET_PRIOR_LOGSD)`.
  - `npp_tsens`: `tr = "id"`, prior `dnorm(x, 0, NPP_TSENS_PRIOR_SD)`.
  - `imb_share_land`: `tr = "logit"`, lo 0, hi 1, prior `dbeta(x, 1, 2)`.
  - `imb_share_ocean_rest`: `tr = "logit"`, lo 0, hi 1, prior uniform (log-density 0).
  - Beta(1,2) × U(0,1) through the stick-breaking map is the FLAT simplex; `test-imb-alloc.R` asserts that
    density is constant.
  - ⚠ The table adds the logit Jacobians, which the screen's ML treatment of the shares did not. The shares'
    MAP will differ slightly from the screen's.
- **Every older label must PIN all four at 0** (off). This is required, not optional:
  - `tr = "log"` cannot encode 0 for `ndep_ret`;
  - an unpinned name with no leverage is a prior-only coordinate, which the logpost's MODEL_SLOTS check exists
    to prevent;
  - shares pinned at (0, 0) are objective #13 bit-exact (tested).
- **Registered files lack the names.** Follow the `w_eq` / `gamma_eq` precedent:
  - `CCX_PARAM_ABSENT_OK` plus `ccx_migrate_par_set()` fill what the file RAN (0 = off);
  - `ccx_mode_start()` handles the encoding seed;
  - the "stored streams reproduce" tests must stay bit-exact.
- **A structure label** chained from `hilda_csl3v0kai`. It unpins the four names and turns the D3 rows on.
  - Name suggestion: `hilda_csl3v0kaidgb` (d = N retention, g = greening, b = budget/D3). The name is
    Marcus's call.
  - Extend the label ledgers deliberately, as for `kai`: `test-struct-v0.R` PRIOR_ON, `test-tr-box.R`,
    `test-constants-batch.R`.
- **Objective #14.** The D3 rows live under the new label. Per the freeze record
  (`notes/assessment_2026-09-21_product_ready.md` §4), an objective change means a restamp of every mode. The
  older labels' streams stay bit-exact because their shares are pinned at 0; verify that, don't assume it.
- **Tests:**
  - a registered mode reproduces with the four names absent/pinned;
  - the new label's logpost equals the screen's DNTb value at the same vector (an identity gate);
  - mutation-test the pins.

### Step 2: Torch, and ASK Marcus before launching (standing rule: say the verdict out loud)
- The screens took 11–17 min for 4 arms locally. A full 33-name multistart is hours, and the 09-28 arrays
  went to Torch.
- The verdict is probably Torch. Confirm it is free (it was on 09-26), and ask first.

### Step 3: the refit, on the new label under objective #14
- Read D4 against 56.1 ± 7.75 (`data/obs_npp_modern_target.rds`). If it is unresolved, write it into the new
  assessment as a **named tension**.
- Score the prereg's predictions at the refit, not only at the screen.
- **Decompose the futures** (fertilization shape vs `luc_scale`'s scenario land use vs ocean) before
  attributing the Koven move.

### Step 4: D1, the app
- Re-point at the new mode; `app/global.R` must use the mode's own spinup (the 09-21 lesson).
- **The D3 panel.** `plot_land_sink_imbalance()` draws GCB_land + s_land · I(t) as "this calibration's
  attribution", replacing the EXTREME band. `IMB_BAND_NOTE` / `IMB_BAND_SHORT` and
  `test-imbalance-panel.R`'s wording change with it. **The wording is Marcus's** (app text is for
  undergrads).
- **Copy edits** (Marcus drafts or approves):
  - `app/ui.R` ~623 "a two-pool land biosphere" and ~664 "Two land pools" are wrong: there are four pools
    plus the inert one.
  - The "What it cannot do" list says "no nutrient limitation". N deposition now enters as a retention flux,
    so that sentence needs revisiting.

### Step 5: a new assessment / freeze record
- The refit's scorecard.
- D4 (NPP) resolved or named.
- (c) documented as `luc_scale`'s existing recovery-like freedom.

## 4. Still open (not ruled)

**My decisions, flagged for Marcus:**
1. `ndep` is classified **NON-CLIMATE** in `ccx_hold_climate()`'s inventory (`test-so-entrainment.R`), so a
   held-climate run keeps deposition moving with its scenario.
2. The retention prior's center is 3.9 with log-sd 0.67. Its 95 % interval is **1.0–15**, not exactly 0.6–8.7.
3. The retention flux goes into `soil_slow` only. A wood/soil split would need a cited ¹⁵N partition.
4. The model's `npp` readout EXCLUDES the retention flux (≤ 0.2 GtC/yr).

**Carried:**
- **R2** (`rep_dC` prior), menu in `notes/r2_explained_2026-09-30.md` §6.
- **`ra_ratio` ≈ 0.08** at the refit, under the AR6 GPP cap.
- **A century-scale q10 split.** Greening did not open the (v) B route (σ_T ≈ 0, q10 falls), so it is even
  less motivated now.
- The prereg P1 wording; the `app/global.R` menu descriptors; the untested `f_luc_wood` / `kz_deep_frac`
  findings.
- **Memory housekeeping:**
  - list `INDEX_ccx_phi.md` in `FaIRtoFrEDI/CLAUDE.md` (needs approval);
  - root `MEMORY.md` content is 13,097 B, over its 12 KiB soft budget and under the hard one.
  - ⚠ `INDEX_ccx_app.md` is UNDER budget (14,131 < 14,336 B). The 09-30b handoff's "just over" read
    1 KB as 1000 B.

## 5. Files

**Model code:**
- `R/likelihood.R`:
  - `LIK_IMB_*` (ruled: smooth + cement);
  - `ccx_imb_series()`, `ccx_imb_shares_check()`, `ccx_imb_shares()`;
  - the rows' targets GCB + s·I(t).
- `R/calibrate.R`: `ccx_make_logpost()` resolves the shares from `p_pr`.
- `R/model.R`:
  - `CCX_NDEP_RET_DEFAULT` and the retention flux after the GPP limbs;
  - `CCX_NPP_TSENS_DEFAULT` and the exp(`npp_tsens` · gmst) factor on NPP;
  - both in `ccx_default_params()`.
- `R/cpp.R`: forcing columns `ndep_NH` / `ndep_SH`; the parameter defaults and name list; the run-time
  `ccx_ndep_check()`.
- `R/forcing.R`:
  - `CCX_NDEP_FILE`, `ccx_ndep_forcing()`, `ccx_ndep_check()`;
  - the table columns plus the `ndep_source` attr;
  - `ccx_forcing_at()`; the `ccx_hold_climate()` note.
- `R/periodic_spinup.R`: the quiet year is stamped zero by definition.
- `R/constants.R`: `NDEP_N_PER_NO2`, `NDEP_N_PER_NH3`, `NDEP_LAND_FRAC`, `NDEP_NH_SHARE`,
  `NDEP_RET_PRIOR_CENTRE`, `NDEP_RET_PRIOR_LOGSD`, `NPP_TSENS_PRIOR_SD`, and their hoisted inputs.
- `src/ccx_core.cpp`: `N_FORCING` 19; forcing-WIDTH guards at both entry points; the retention flux; the
  exp term.

**Data:**
- `data-raw/build_ndep_forcing.R` → `data/forcing_ndep.rds` (provenance `@dc70f51`).
- Sha-checked sources: the pinned vV v1.1.1 file and RCMIP v5.1.0.
- Log: `outputs/diagnostics/build_ndep_forcing_20260930.log`.

**Tests:**
- New: `test-imb-alloc.R` (74), `test-ndep.R` (47), `test-npp-tsens.R` (23).
- Ledgers extended as designed: `test-parity.R` (flat-vector mirror), `test-forcing.R` (18:19, length 19),
  `test-so-entrainment.R` (non-climate list).
- **Last full suite:** `suite_20260930_post65bc714.log`, **only the named red** (`test-mode-file.R:323`),
  PASS 5336. The one change after it (`3eb4fe2`, the ruled D3 defaults) is read only in the shares branch;
  `test-imb-alloc.R` passes.

**Drivers** (`calibration/`):
- `diag_imb_alloc_preview.R`.
- `diag_alignment_screen.R`: D3 arms `D3s` / `D3c` / `D3sc`; D2 arms `DN` / `DT` / `DNT` / `DNTb`; env
  `AS_ONLY`, `AS_TAG_SUFFIX`, `AS_SMOKE`.
- `diag_ndep_form_efficiency.R`: ⛔ a RECORD, valid only at `74896c5`.

**Outputs** (`outputs/diagnostics/`, `*_20260930.*`):
- `imb_alloc_preview`, `alignment_screen_d3`;
- `alignment_screen_d2` (the multiplier: the retired form's record);
- `alignment_screen_d2ret` (the ruled forms);
- `ndep_form_efficiency`;
- suites `post{512d8e8, c0ae37b, d7f7538, 65bc714}`.

**Notes:** `prereg_2026-09-30c_nonco2_drivers_imbalance.md`, `lit_2026-09-30_nonco2_land_sink_drivers.md`, and
this file.

## 6. Non-obvious state and traps

- **Nothing is running.** No worktrees besides `main`.
- `outputs/diagnostics/smoke/` holds the untracked smoke outputs, by convention. The D2/D3 smokes were moved
  there.
- `carbotopecomment.9.26.26.docx` is untracked and belongs to Marcus. Leave it alone.
- **`gamma_ndep` no longer exists.** The multiplier was replaced by `ndep_ret`. Anything that sets
  `gamma_ndep` now sets a field nothing reads. That is the silent-gate shape, which is why the efficiency
  diagnostic is marked a record.
- **The N-deposition data** (`ccx_ndep_forcing()`):
  - It carries `historical` (1750–2024), `ssp119` / `126` / `245` / `370` / `585` and `vvVL` / `LN` / `L` /
    `ML` / `M` / `HL` / `H` (1750–2300).
  - Any other scenario name, or a `historical` table past 2024, gives ZEROS stamped `none…`, which
    `ccx_ndep_check()` REFUSES when `ndep_ret` ≠ 0.
  - Because the file exists, every built forcing now carries non-zero `ndep` columns. That is harmless at
    `ndep_ret` 0.
  - App runs get N deposition by scenario NAME; every scenario carries the CMIP7 history, so no GCB-style
    splice is needed.
- **The C++ refuses a forcing of the wrong width** (`N_FORCING` 19). A forcing table saved before today lacks
  the `ndep` columns and fails `ccx_cpp_forcing()`'s name check, as the AOD columns did. Rebuild it with
  `ccx_build_forcing()`.
- **The suite re-sources `R/` for every test file.** Never edit `R/`, `src/` or `tests/` while a suite runs.
  Screens are safe; they run from frozen copies.
  - `sourceCpp` builds into each R session's tempdir, so a recompile cannot disturb a running job.
- **Comparing screen arms:**
  - D3 arms compare with the control on the COMMON rows only;
  - the P-D3-* predictions were registered for D3-ALONE arms, and DNTb's "P-D3-4 FAIL" applies them to a
    combined arm;
  - screen costs are upper bounds.
- **Correction on the record.** 09-30 (c)'s sentence "most of the land excess is `luc_scale`" had the sign
  backwards (09-30 i). `luc_scale` < 1 LOWERS the land excess.
- **A process note, reported to Marcus.** The literature subagent sent his email address in one (failed)
  NCBI ID-conversion request. Nothing further is needed. Brief future subagents not to pass personal data to
  services.
- **Machine.** Load ~3–4 with idle processes from other sessions. Check `uptime`, pin BLAS threads, and run
  long jobs from frozen copies.
