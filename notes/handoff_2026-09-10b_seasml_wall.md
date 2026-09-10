# Handoff — 2026-09-10b. **STEPS 1–3 OF `handoff_2026-09-10_adopt_then_round6.md` ARE DONE (Hessian → repoint → `seas_ml` capability). ⛔⛔ STEP 4, THE ROUND-6 REFIT, IS BLOCKED ON ONE RULING: AT `seas_ml = 1` THE OBJECTIVE IS −Inf ABOVE h_ml ≈ 75 m AND THE REFERENCE SET CROSSES THAT WALL.**

> Read first: **CHANGELOG 2026-09-10 (6)**. Memory: [[ccx_hilda31p_adopted]],
> [[ccx_seas_ml_p8_wall_blocks_reference_set]], [[ccx_refit_ran_at_seas_ml_0]].

## 1. STATE OF THE TREE
`CarbonCycleEmulator/main`, clean, no remote. Commits this session: `fa0e7cf` (Hessian),
`db7c355` (`seas_ml` capability), `ca33bef` (repoint + spinup vintage + demean test rebuild).
- ✅ **`CCX_MODE_CANONICAL = "hilda31p"`** → `calibration/output/refit_20260910_hilda31_periodic/mode_fit_pumpN.rds`
  (31 par, hilda, `seas_ml` 0, `spinup` "periodic", −1480.540424, full Hessian block, PD, `h_ml` unstable).
- ✅ **`hilda31` QUARANTINED** → `calibration/output/quarantine/20260910_periodic_spinup_adopted/` (README there);
  errors by name; by path `CCX_MODE_HILDA31_QUARANTINED`.
- ✅ **Suite 12,990 / 2 failed / 1 error / 4 skipped** = the pre-existing set (alpha-as GATE Q; seas-lag-split migration).
- ✅ `port_targets.csv` regenerated at **`seas_ml = 0`** (logposts byte-identical to 09-09x's) and now carries a `seas_ml` column.
- ⚠ `tests/testthat/test-mode-file.R:187` still asserts "largest STORED logpost" against its own comment (:175–179). Passes with one registered arm only. **Ruling owed; not repaired.**
- ⚠ Root `MEMORY.md` is **19,218 B, OVER its 18,432 hard ceiling**. Restructure owed (Marcus's call what stays).

## 2. THE CAPABILITY, AS BUILT (so the next run cannot repeat 09-10's silent default)
- `ccx_apply_structure(p, struct, seas_ml)` — sets `p$seas_ml` AND `attr(, "seas_ml")`; default `CCX_MS_SEAS_ML` ("0"); 0/1 only, errors by name.
- `ccx_mode_seas_ml(md)` / `ccx_mode_spinup(md)` / `ccx_mode_base(md)` — a mode file's own setting (absent = 0 / aseasonal = facts about old files).
- **`run_dispersed_multistart.R` and `make_port_targets.R` STOP if `CCX_MS_STRUCT` or `CCX_MS_SEAS_ML` is unset.** Start files record `seas_ml`; the promoter records `seas_ml` + `spinup`; the port gate refuses a CSV at the other `seas_ml`, a CSV without the column, or a non-finite target.
- `multistart.sbatch` / `setup_torch.sh` export `CCX_MS_SEAS_ML` (default **1**); outdir `multistart_20260910_hilda31p_periodic_seasml${CCX_MS_SEAS_ML}`.
- `calibration/stamp_mode_spinup.R` — stamps `spinup` into a pre-field file ONLY after proving reproduction under exactly one spinup.

## 3. ⛔ THE BLOCKER — measured, not inferred (`scratchpad/feas_seasml1.R`, reproducible from the table in CHANGELOG (6))
`ccx_seas_ml_guard()` (P8) → −Inf above h_ml ≈ 75 m (finite at 74, −6.4e8 at 75, −Inf from 76) inside the [30, 200] band.
- `MS_REF_NEW` / `PT_REFS$new_basin` (08-31e, **143.9 m**) = −Inf ⇒ `make_port_targets.R` at `seas_ml = 1` REFUSES (correct).
- **The 09-10 second basin (164 m) does not exist under the round-6 objective** ⇒ it cannot be the replacement reference.
- Fixed starts 2/4/5 would be born at −Inf; the cold init (75.0 m) sits ON the wall; dispersed draws survive by re-draw but the effective h_ml prior is truncated at the wall.
- `MS_SPREAD` is measured from `MS_REF_INC`–`MS_REF_NEW` separation, so the reference choice sets the survey's scale.
**Options (none taken):** (a) `MS_REF_INC := hilda31p`, `MS_REF_NEW := hilda31` (both feasible, in-space, no migration; ~9 log-units apart, parameters close ⇒ `CCX_MS_SPREAD` explicit and named in the outdir — e.g. carry round 5/6's measured 1.0452); (b) keep the 08-30 incumbent, pick another feasible second point; (c) widen P8 (a MODEL change). ⚠ Also `hilda31p` unrefitted at `seas_ml = 1` = −1634.68 (−154): NOT evidence against the mechanism ([[like_for_like_forcing]]).

## 4. WHAT TO DO ONCE RULED (in this order)
1. Edit `MS_REF_INC` / `MS_REF_NEW` in `run_dispersed_multistart.R` and `PT_REFS` in `make_port_targets.R` to the ruled set (they must agree — the port-target KEYS are the driver's reference ids); consider moving the cold init's `h_ml` init off 75 m (that is a `CCX_PARAM_TABLE` change — say so).
2. `CCX_MS_STRUCT=hilda CCX_MS_SEAS_ML=1 Rscript calibration/make_port_targets.R` — check the `struct` AND `seas_ml` columns.
3. Local preflight on ids 0–5 and two dispersed ids: `CCX_MS_STRUCT=hilda CCX_MS_SEAS_ML=1 CCX_MS_OUTDIR=<scratch> CCX_MS_PREFLIGHT=1 CCX_MS_ID=<id> Rscript --vanilla calibration/run_dispersed_multistart.R` — every one must print `PORT GATE (a) PASSED` and a FINITE start.
4. Ship the bundle; Torch preflight (`CCX_MS_PREFLIGHT=1 sbatch --array=0-5,12,20 --time=00:15:00`), **re-derive the wall from the measured s/eval** (seas_ml = 1 is ~1.4× on the Mac, ~3× was the 09-09x estimate — measure, don't carry); then `sbatch --array=0-23%24 calibration/torch/multistart.sbatch` on **`cs`**. Round 2 = fixed ids + round 1's best dispersed, same outdir.
5. Promote with `promote_multistart_mode.R` (it now records `seas_ml` = 1 and `spinup`); `recompute_hessian.R --update`; then the P2 / P12 reads (`sst_seas_amp_NH` z, `ent_seas_amp_SH` vs 6.5525).

## 5. WHAT I WOULD NOT DO
- Do not run `make_port_targets.R` or the driver with either label variable unset — they now refuse, and that refusal is the fix.
- Do not swap `test-mode-file.R:187`'s expectation, and do not register a second arm until it is ruled.
- Do not read the −154 at `seas_ml = 1` as a verdict on round 6.
- Do not submit to `cpu_short`; do not carry the 300-min wall without re-measuring s/eval at `seas_ml = 1`.
