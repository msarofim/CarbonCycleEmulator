# Handoff 2026-09-30 (d): refit infrastructure BUILT (step 1). Next: Marcus's launch decisions, then Torch, then the refit

> **Session start.** Launch from `FaIRtoFrEDI/`, then `change_directory` here (CLAUDE.md). ⛔ Never use
> a bare `cd` in a Bash call; use `git -C` or absolute paths.
>
> **Read first:**
> 1. this file;
> 2. CHANGELOG **2026-09-30 (p)** (the build, the design, the verification, the smoke);
> 3. memory: `ccx_refit_infra_gate_0930.md` (indexed in `INDEX_ccx_phi.md`), then
>    `ccx_d2_d3_build_0930.md` and `ccx_rulings_0930_nonco2_imbalance_app.md`;
> 4. the previous handoff, `notes/handoff_2026-09-30c_d2d3_built.md`. Its §3 step 1 is DONE here; its
>    steps 2–5 are the plan below.

---

## 1. What this session did

All committed and pushed (`0a4daf6` .. the 09-30 (p) CHANGELOG commit).

| step | outcome |
|---|---|
| The four names in the fitted set | Through a **LABEL GATE** (`CCX_PARAM_GATED`, `ccx_apply_gate()`), NOT as table entries pinned under every older label. Same objective, and every older consumer is untouched by construction. Why: CHANGELOG (p) |
| The label | `hilda_csl3v0kaidgb` = kai + `d2d3_free = 1` + the ruled I(t) recorded (numeric code) = **objective #14**. ⚠ Name awaiting Marcus |
| Guards | `ccx_make_logpost()` two-way (built + per draw); `ccx_gate_require()` in the four mode readers; `ccx_overlay_par()` by the base's structure; dynamic absent-name tolerance (`ccx_param_absent_ok()`) |
| Verification | OFF-identity (open label + four pinned at 0 == kai, bit-exact); the screen's DNTb streams reproduced exactly; 14 gate mutations caught; `test-gated-params.R` 6 / 88 |
| Objective #14 vs registered modes | `diag_obj14_registered_bitexact.R`: 4/4 streams `identical()`, logpost diff 0 ⇒ **no restamp needed**. Mutation-tested |
| The refit path | Driver, port targets, promoter, Hessian and restamp all apply the gate before pins. Promoter GATE 5 fixed: enso/aod forcing (a pre-existing defect that would have stopped any ka-descended promotion), D3 shares, npp row |
| Loaders | `dg_vector` and `ccx_load_mode` converted to `ccx_overlay_par()`; `dg_streams` and `ccx_load_mode`'s `err` carry the shares; `dg_run` passes the structure's enso/aod |
| Run inputs | `data/forcing_ndep.rds` added to `CCX_RUN_INPUTS` |
| Smoke (worktree `~/ccx_frozen/20260930p_dgb_smoke`) | Port targets (33 free); preflight ids 0–11 LAUNCHABLE; the promoter's GATES 1–5 on a synthetic open-label start; Hessian GATE 1 |
| Suite | see §5 |

## 2. Decisions for Marcus (NOT ruled; ask with the question tool before launching)

1. **The label's name.** `hilda_csl3v0kaidgb` (d = N retention, g = greening, b = budget/D3) was the 09-30c
   handoff's suggestion. A rename touches `R/calibrate.R` (one function, one dispatch line, the label
   list and the error text), the four label ledgers and `test-gated-params.R`.
2. **How to disperse `npp_tsens` in the multistart.**
   - The driver disperses every coordinate at ONE u-space sd (1.0452 in the 09-28 arrays). For
     `npp_tsens` (`tr = "id"`, prior sd 0.029 /K) that is 36 prior sds.
   - At the DNTb vector, a 1-sd move in `npp_tsens` alone costs −4.5e5 / −8.9e5 log-units. That is about
     10× the stiffest existing coordinate (`q10`: −5.6e4 / −4.6e4) and 12× `grad_off_d13c` (7 prior sds
     at that spread).
   - `ndep_ret` costs −230 / −1890; the shares cost −1 to −5.
   - The dispersed starts still land in the 09-28c array's range (−2e5 to −1.4e7 vs −1.5e5 to −1.5e7).
   - Options: keep the uniform spread (as every array so far); disperse `npp_tsens` at its prior sd; or
     another per-coordinate cap. This is an ensemble-construction choice (CLAUDE.md: flag, don't resolve).
3. **The reference set.**
   - With the canonical's 9 pins, `ccx_ms_reference_set()` gives incumbent `hilda29l` (φ 0.5,
     `hilda_csl3`) and new basin `hilda31pe` (hilda_c, seas_ml 0).
   - Under the new label both are SEEDED starts: port targets −12,149.8 / −12,163.0, vs about −1,408 at
     the DNTb screen vector. This is what 09-28b/c did, and there 7 of 24 starts converged inside a
     5-h wall at 29 names.
   - A closer φ = 0 incumbent (the 09-28c `promoted_basin1`, unregistered) would need registering
     (`CCX_MODE_FILES`, `CCX_MODE_PINNED`, `make_bundle.sh`, the `test-mode-file` / `test-hml-floor`
     ledgers) plus a reference-set branch. There is no env override.
4. **Torch (standing rule: say the verdict out loud, ask first).**
   - The verdict is Torch: 33 names; the 09-28c array took ~4.3 h per start with a 5-h wall and only
     7/24 converged.
   - Check the queue first (it was free on 09-26), then ask.
   - Launch recipe (the 09-28 one, `handoff_2026-09-28_fert_shape.md` §4): `CCX_MS_STRUCT=hilda_csl3v0kaidgb`,
     `CCX_MS_SEAS_ML=1`, `CCX_MS_PIN=<the canonical 9>`, `CCX_MS_SPREAD=1.0452`, WALL 300, partition `cs`.
     Regenerate the port targets **in the frozen tree** (they write `calibration/torch/port_targets.csv`),
     then run the preflight for every id.

## 3. The plan after the decisions (the 09-30c handoff's steps 2–5)

1. **Launch** on Torch from a frozen worktree at the launch commit. Collect, promote (GATES 1–5), run
   `recompute_hessian.R --update`.
2. **Read the refit:**
   - D4 against 56.1 ± 7.75 (`data/obs_npp_modern_target.rds`); if unresolved, it is a NAMED TENSION;
   - score the prereg's predictions at the refit (`notes/prereg_2026-09-30c_nonco2_drivers_imbalance.md`);
   - **decompose the futures** (fertilisation shape vs `luc_scale`'s scenario land use vs the ocean)
     before attributing the Koven move;
   - ⚠ `dg_run` cannot yet score an `ndep_ret` ≠ 0 vector: `DG_YEARS` runs to 2025, the historical
     N-deposition series ends 2024, and `ccx_ndep_forcing()` refuses partial coverage by design. The fix
     is to hold 2025 flat, as GMST and emissions are. It changes the `test-ndep.R` ACCESSOR contract, so
     ask.
3. **D1, the app.** Repoint to the new mode (`app/global.R` must use the mode's own spinup), and apply
   the gate before reading the mode. `app/R/params_meta.R` needs the four names (and must be told about
   gated names). The D3 panel wording and the copy edits are Marcus's (09-30c §3 step 4).
4. **A new assessment / freeze record** (09-30c §3 step 5).

## 4. Still open (carried)

**My decisions, flagged for Marcus** (09-30c §4, still unanswered):
- `ndep` classified NON-CLIMATE;
- the retention prior's interval is 1.0–15;
- the flux goes into `soil_slow` only;
- the `npp` readout excludes the flux.

**Carried from before:**
- R2 (`rep_dC` prior);
- `ra_ratio` ≈ 0.08 under the AR6 GPP cap;
- the century-scale q10 split;
- the prereg P1 wording;
- the `app/global.R` menu descriptors;
- `f_luc_wood` / `kz_deep_frac`.

**Memory housekeeping:**
- list `INDEX_ccx_phi.md` in `FaIRtoFrEDI/CLAUDE.md` (needs approval);
- root `MEMORY.md` is over its soft budget.

## 5. Files and state

- **Code:**
  - `R/calibrate.R`: the gate block after `CCX_PARAM_NAMES`; `ccx_param_absent_ok()`; the migration
    contract; the label; the guard in `ccx_make_logpost()`; `ccx_gate_require()`;
  - `R/model.R` (`ccx_overlay_par()`);
  - `R/likelihood.R` (`LIK_IMB_TREATMENT_CODES`);
  - `R/paths.R` (the decode check).
- **Calibration:**
  - `run_dispersed_multistart.R`, `make_port_targets.R`, `promote_multistart_mode.R`,
    `recompute_hessian.R`, `restamp_mode_objective.R`, `lib_design_gates.R`, `lib_run_inputs.R`;
  - new: `diag_obj14_registered_bitexact.R`.
- **Tests:**
  - new: `test-gated-params.R`;
  - extended ledgers: `test-constants-batch.R`, `test-tr-box.R`, `test-struct-v0.R`, `test-soil-inert.R`,
    `test-overlay-idiom-lint.R` (N 61 → 59).
- **Outputs:**
  - `outputs/diagnostics/obj14_registered_bitexact_20260930.log`;
  - the suite log `suite_20260930_post7201852.log`.
- **Frozen trees (disposable):**
  - `~/ccx_frozen/suite_20260930p` (the suite copy);
  - `~/ccx_frozen/20260930p_dgb_smoke`, a git WORKTREE: remove it with `git worktree remove --force`. It
    holds the smoke port targets and a synthetic promoted file, neither a record.
- `carbotopecomment.9.26.26.docx` is Marcus's. Leave it.
- `outputs/diagnostics/smoke/` stays untracked by convention.
- **Nothing is running.**
