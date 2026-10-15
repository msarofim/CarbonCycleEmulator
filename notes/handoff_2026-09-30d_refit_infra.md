# Handoff 2026-09-30 (d): refit infrastructure BUILT (step 1); the objective-#14 refit is RUNNING on the Mac

> **Session start.** Launch from `FaIRtoFrEDI/`, then `change_directory` here (CLAUDE.md). ⛔ Never use
> a bare `cd` in a Bash call; use `git -C` or absolute paths.
>
> **Read first:**
> 1. this file;
> 2. CHANGELOG **2026-09-30 (p)** (the build, the design, the verification, the smoke) and **(q)** (the launch rulings and the running wave);
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

## 2. Launch rulings (Marcus, 2026-09-30, via the question tool) and THE RUNNING WAVE

- Label: "Keep hilda_csl3v0kaidgb (Recommended)".
- `npp_tsens` dispersion: "At its prior sd (Recommended)". Built as `MS_SPREAD_OVERRIDE` (`99f1161`); the
  outdir must carry `_sdby_npp_tsens=0.0291`.
- Reference set: "Registered set, as 09-28b/c (Recommended)". Incumbent `hilda29l`, new basin `hilda31pe`,
  both seeded; no code change.
- Where: **"Mac, 8 parallel"**. My verdict was Torch; Marcus chose the Mac.

**⏳ THE WAVE IS RUNNING** (launched 2026-09-30 17:42 EDT, CHANGELOG 09-30 q):
- **Tree:** `~/ccx_frozen/20260930q_dgb_refit`, a git WORKTREE at `99f1161`. ⛔ Do not touch it while the
  wave runs.
- **Launcher:** `calibration/mac/run_multistart_mac.sh` inside that tree; 24 ids, 8 at a time; WALL 300,
  3 × 6 × 6000.
- **Outdir (in the frozen tree):**
  `calibration/output/multistart_20260930q_hilda_csl3v0kaidgb_seasml1_pin_ent_seas_amp_SH=0_w_eq=27_gamma_eq=1_pump_export=9.08_w_vent=0_gamma_vent=0_w_thc=0_gamma_enso_ocn_NH=0_gamma_enso_ocn_SH=0_sd1.0452_sdby_npp_tsens=0.0291`.
- **Progress:**
  - wave log `logs/wave_20260930q.log`; per-task logs `logs/ccx_multistart_mac_20260930q_<id>.out`;
  - exit codes `logs/ccx_multistart_mac_20260930q_exit.txt`;
  - check the tasks with `ps aux | grep '[r]un_dispersed_multistart'`: WAIT ON THE WORK PROCESS, never a
    `pgrep -f` loop.
- **Expected:** ≈ 15 h (3 rounds × ≤ 5 h), done around 09:00 on 2026-10-01. The Mac must stay on AC power:
  `caffeinate -s` holds off sleep only while plugged in.
- ⚠ **M4, 4 performance + 6 efficiency cores.** About half the tasks run on efficiency cores (slower per
  evaluation), so compare per-task eval counts before reading "not converged" as a basin fact.
- The machine checks at launch, and the rates about 5 min in, are in CHANGELOG 09-30 (q).

## 3. The plan (the 09-30c handoff's steps 2–5)

1. **When the wave lands:**
   - copy the outdir from the frozen tree into the repo's `calibration/output/`;
   - `Rscript calibration/collect_dispersed_multistart.R --outdir=<it>`;
   - `promote_multistart_mode.R --outdir=<it> --dest=calibration/output/refit_2026MMDD_<name>_obj14_hilda_csl3v0kaidgb`;
   - `recompute_hessian.R <mode> --update`.
   ⚠ The name of the promoted mode, and whether to register it, is Marcus's call.
2. **Read the refit:**
   - D4 against 56.1 ± 7.75 (`data/obs_npp_modern_target.rds`); if unresolved, it is a NAMED TENSION;
   - score the prereg's predictions at the refit (`notes/prereg_2026-09-30c_nonco2_drivers_imbalance.md`);
   - **decompose the futures** (fertilization shape vs `luc_scale`'s scenario land use vs the ocean)
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
- **Frozen trees:**
  - ⛔ `~/ccx_frozen/20260930q_dgb_refit` is the RUNNING WAVE's worktree. Keep it until its outdir is
    copied back.
  - Disposable: `~/ccx_frozen/suite_20260930p` (the suite copy, not a worktree). The smoke worktree
    `20260930p_dgb_smoke` was removed at the end of the session (scratch only: the smoke port targets,
    the synthetic promoted file).
- `carbotopecomment.9.26.26.docx` is Marcus's. Leave it.
- `outputs/diagnostics/smoke/` stays untracked by convention.
- **RUNNING:** the 24-start wave (§2). Nothing else.
