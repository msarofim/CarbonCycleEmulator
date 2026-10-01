# Handoff 2026-10-01 (b): `hilda33d` is ADOPTED and the suite is clean. Next: Marcus's open calls (D2 choice 4, the app's version label, the AIC gate's row set), then D1 copy and the assessment

> **Session start.** Launch from `FaIRtoFrEDI/`, then `change_directory` here (CLAUDE.md). ⛔ Never use
> a bare `cd` in a Bash call; use `git -C` or absolute paths.
>
> **Read first:**
> 1. this file;
> 2. CHANGELOG **2026-10-01 (c)** (the request, the assessment, the adoption, 2025 N deposition, the D2
>    rulings) and **(d)** (the suite: what was fixed in code, what was re-pinned, what is flagged);
> 3. memory: `ccx_hilda33d_adopted.md` (new), then `ccx_obj14_refit_1001.md` and
>    `ccx_refit_infra_gate_0930.md`. They are indexed in `INDEX_ccx_phi.md`, and `INDEX_ccx.md`'s LIVE
>    STATE names hilda33d;
> 4. the previous handoff, `notes/handoff_2026-10-01_obj14_refit.md` (pre-adoption; its §2 decisions 1, 3
>    and 4 are now settled).

---

## 1. Where things stand

- **The canonical is `hilda33d`** (`CCX_MODE_CANONICAL`, `R/paths.R`).
  - Objective #14 under label `hilda_csl3v0kaidgb`: D2 (N retention, greening) and D3 (the GCB-imbalance
    shares) are FITTED. 33 names, the same 9 pins.
  - File: `calibration/output/refit_20261001_hilda33d_obj14_hilda_csl3v0kaidgb/mode_fit_pumpN.rds`
    (renamed at adoption; CHANGELOG 10-01 (a) quotes the old path).
  - Registering `hilda33d` puts it in `CCX_MODE_FILES` / `CCX_MODE_PINNED`. hilda29l stays registered: it
    is the v1.0 product's mode (tag `v1.0-hilda29l`).
- **The gate rides with the pins.** `ccx_mode_pins()` carries the file's open structure, so
  `ccx_apply_pins(ccx_mode_pins(md))` opens the gate first. Code that builds pins any other way must still
  call `ccx_apply_gate()` before them.
- ⚠ **Comparing with a #13 mode:** use the 24 SHARED rows only. D3 moves the two GCB sink rows' targets.
  - hilda33d −1308.60;
  - hilda29l −1319.32 (ΔAIC −13.4);
  - hilda32f −1314.81;
  - hilda31pe −1313.28 (ΔAIC −5.35).
- **2025 N deposition** is the seven-vV-marker mean (50.886 Tg N/yr). `dg_run` and the design gates score
  the canonical.
- **Suite CLEAN at `f9bffdf`:** 5453 passed, 0 failed, 0 errors, 5 skipped
  (`outputs/diagnostics/suite_20261001_postf9bffdf.log`).
- **The app** (preview checked at `def9cea`): it loads on hilda33d with no console errors. The live
  takeaway reads 426 ppm today vs about 424 measured. "Under the hood" lists the four new parameters with
  their fitted values.

## 2. Decisions for Marcus (NOT ruled)

1. **D2 choice 4: the NPP readout** ("Pros/cons?").
   - The readout EXCLUDES the retention flux; the status quo stands until he rules.
   - ⛔ The question quoted the NET sink (0.33 GtC/yr). The readout would add the GROSS flux, 0.498 GtC/yr
     over 2001–2023.
   - Exclude: 67.67, z +1.50. Include: 68.17, z +1.56.
   - My recommendation: keep it excluded and quote the flux beside D4.
2. **The app's version label.**
   - `APP_VERSION <- "v1.0-hilda29l"` (`app/global.R:77`) is a literal. The banner therefore reads "BETA
     v1.0-hilda29l", and `APP_STAGE_NOTE` says "the model is frozen at this version", while the app runs
     hilda33d.
   - Options:
     - (a) a new release name, Marcus's wording;
     - (b) derive the mode suffix from `CCX_MODE_CANONICAL` (labels from named constants);
     - (c) hold the app on hilda29l until the D1 copy is done.
   - The "Known issues" cards were also written about v1.0-hilda29l.
3. **`test-mode-file`'s AIC gate** (named red #2) now PASSES on its 26 common rows, two of which are #14's
   MOVED GCB rows (+18.54, ΔAIC −33.1).
   - On the 24 like-for-like rows it also passes (+4.68, ΔAIC −5.35).
   - Open: should the row set drop moved rows when the arms' objectives differ? Its comment block still
     calls it a standing red.
4. **The drafted app labels** for the four gated names (`app/R/params_meta.R`), and their constraint-map
   components (`ndep_ret` / `npp_tsens` → "Land uptake"; the shares → "Input scalings & reporting").
   App text is his.

## 3. Next steps (after the rulings)

1. **D1, the app copy** (Marcus's text): the D3 panel wording, "two-pool land", "no nutrient limitation",
   and the version label (above).
2. **Precomputed posterior ribbons** for the app's futures. The ±39 ppm Laplace spread is linear; a sampled
   ribbon is the product version.
3. **A new assessment / freeze record:** the scorecard, D4 named, the futures decomposition with its
   caveat.
4. **Provenance:** `diag_whole_model_scorecard.R` and `diag_constraint_map.R` stamp no commit in their
   outputs. A small fix; flagged as a separate task.

## 4. State

- **Nothing is running** except the app preview server (`ccx-app`, port 7788), which can be stopped.
- No worktrees besides `main`.
- **Disposable** (frozen suite copies, not worktrees): `~/ccx_frozen/suite_20260930p`, `suite_20261001c`,
  `suite_20261001d`, `suite_20261001e`. Their logs are copied into `outputs/diagnostics/`.
- ⚠ The root `MEMORY.md` content is ~13.1 KB, over its 12 KB soft budget. That was pre-existing; this
  session's edit was size-neutral.
- `carbotopecomment.9.26.26.docx` is Marcus's. Leave it.
- `outputs/diagnostics/smoke/` stays untracked by convention.
