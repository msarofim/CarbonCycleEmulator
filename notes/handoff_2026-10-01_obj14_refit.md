# Handoff 2026-10-01: the objective-#14 refit has LANDED and been read. Next: Marcus's adoption decisions, then the app (D1) and the assessment

> **Session start.** Launch from `FaIRtoFrEDI/`, then `change_directory` here (CLAUDE.md). ⛔ Never use
> a bare `cd` in a Bash call; use `git -C` or absolute paths.
>
> **Read first:**
> 1. this file;
> 2. CHANGELOG **2026-10-01 (a)** (the refit read), then 09-30 (p) / (q) (the infrastructure and the launch);
> 3. memory: `ccx_obj14_refit_1001.md` and `ccx_refit_infra_gate_0930.md` (both indexed in
>    `INDEX_ccx_phi.md`; `INDEX_ccx.md`'s live state points here);
> 4. the previous handoff, `notes/handoff_2026-09-30d_refit_infra.md`.

---

## 1. Where things stand

- **The mode:** `calibration/output/refit_20261001_obj14_hilda_csl3v0kaidgb/mode_fit_pumpN.rds`.
  - Label `hilda_csl3v0kaidgb` = objective #14 (D2 + D3 fitted); 33 free names under the canonical 9 pins.
  - logpost −1405.249036, likelihood −1369.1761 on 26 rows.
  - GATES 1–5; Hessian PD, cond 1.7e6.
  - ⛔ **Promoted, NOT named, NOT registered, NOT adopted.** `CCX_MODE_CANONICAL` is still `hilda29l`.
  - Consumers must `ccx_apply_gate(ccx_mode_struct(md))` BEFORE `ccx_apply_pins(...)`.
- **The wave:** `calibration/output/multistart_20260930q_hilda_csl3v0kaidgb_…_sdby_npp_tsens=0.0291/`
  - 24/24 converged; `collect_20261001.log`; per-task logs; `RUN_PROVENANCE.txt`.
  - The second "basin" differs in `h_ml` only (the 09-28e near-degeneracy).
- **The reading:** `calibration/diag_obj14_refit_read.R` → `outputs/diagnostics/obj14_refit_read_20261001.*`.
  It covers the scorecard vs the alignment control, D4, the predictions, the futures decomposition, the
  `npp_tsens` lever and the Laplace futures spread. Numbers: CHANGELOG 10-01 (a).

## 2. Decisions for Marcus (not ruled)

1. **Name, register and adopt the mode?**
   - Registering touches `CCX_MODE_FILES`, `CCX_MODE_PINNED`, `make_bundle.sh`'s tar list and the
     `test-mode-file` / `test-hml-floor` ledgers.
   - Adopting (repointing the canonical) also moves the AIC gate's named red and every "the canonical's
     stored logpost" fixture.
   - ⚠ #14's logpost is NOT comparable with #13's stored values: compare on the COMMON rows.
2. **D4 is a NAMED TENSION** (NPP 67.7, z +1.50), as ruled 09-30 if unresolved. Its wording goes into the
   assessment.
3. **`dg_run` and N deposition.**
   - The design gates run to 2025 (`DG_YEARS`, ruled 09-12); the historical N-deposition series ends in
     2024; `ccx_ndep_forcing()` refuses partial coverage by design (pinned by `test-ndep.R` ACCESSOR).
   - So the design gates and the scorecard drivers that use `dg_run` cannot score this mode yet.
   - Proposed: hold 2025's deposition flat, as GMST and emissions already are. That changes a test-pinned
     contract, so ask.
4. **The four D2 choices flagged on 09-30 (c)**, still unanswered:
   - `ndep` NON-CLIMATE;
   - the prior's 1.0–15 interval;
   - `soil_slow` only;
   - the `npp` readout excludes the flux.

## 3. Next steps (after the rulings)

1. **D1, the app** (09-30c handoff §3 step 4):
   - repoint `app/global.R` to the mode, with its own spinup and the gate applied before its pins;
   - `app/R/params_meta.R` needs the four names, and must be told about gated names;
   - the D3 panel: `plot_land_sink_imbalance()` draws GCB_land + 0.593 · I(t) as "this calibration's
     attribution"; the wording is Marcus's;
   - the copy edits ("two-pool land", "no nutrient limitation") are Marcus's.
2. **Precompute posterior ribbons** for the app's futures (CLAUDE.md: live-run only the central set). The
   Laplace spread (±39 ppm at SSP5-8.5 2300) is linear; a sampled ribbon is the product version.
3. **A new assessment / freeze record:**
   - the refit's scorecard;
   - D4 named;
   - (c) documented as `luc_scale`'s recovery-like freedom;
   - the futures decomposition, with its caveat: the control → refit change is not "what D2/D3 did".

## 4. State

- **Nothing is running.** No worktrees besides `main`; the launch worktree was removed after a
  byte-identical check of the copy.
- **Disposable:** `~/ccx_frozen/suite_20260930p` (a frozen suite copy, not a worktree).
- `carbotopecomment.9.26.26.docx` is Marcus's. Leave it.
- `outputs/diagnostics/smoke/` stays untracked by convention.
- All committed and pushed.
