# The four forcing guards on the pure-R core: MEASURED, not landed (2026-10-14 n)

**Ruling (Marcus, verbatim):** "Measure first (Recommended)". The question is handoff 10-14c §3.4:
`ccx_run_prepared()` (`R/cpp.R:555–558`) checks the forcing's ENSO index, AOD mode, nuclear share and
N deposition against the parameters, and `ccx_run()` (`R/forcing.R` ~1342) checks none of them.

**Nothing in main changed.** The patch ran only in a scratch worktree.

## What was run

- **Two scratch worktrees at `f451f0f`**, both with `data-raw/downloads` linked (81 / 81):
  - `~/ccx_frozen/suite_20261014_guards_base` is unpatched;
  - `~/ccx_frozen/suite_20261014_guards_on` carries `guards_patch.diff`. That is four lines at the top of
    `ccx_run()`, each value derived from `spin$params` exactly as `ccx_cpp_prepare()` derives it.
- **The full suite in each, concurrently** (`suite_20261014_guards_{base,on}.sh`, BLAS pinned to 1 thread),
  20.5 min each.
- **A power check** (`guard_power.R`, run from a worktree root; log `guard_power.log`). A fake spin and an
  UNSTAMPED forcing are passed to `ccx_run()`, once per mismatch. The guards sit before any use of the state,
  so this needs no spinup.

## Results

### 1. The patch has power

Each of the four mismatches STOPS in the patched tree with its own guard's message. The matched case (`none`)
passes the guards and only then fails on the fake spin, exactly as both cases fail in the unpatched tree.

### 2. The suite: nothing stops

| tree | passed | failed | skipped | log |
|---|---|---|---|---|
| base | 8050 | 3 | 1 | `../suite_20261014_f451f0f_guards_base.log` |
| on | 8050 | 3 | 1 | `../suite_20261014_f451f0f_guards_on.log` |

- The failures are the same three in both: app-version and card 4 ×2, all expected.
- The skip is the standing `l2-enso-limb` one.
- **This null is not structurally guaranteed.** `test-flux-trace-exact.R` runs `ccx_run()` at the canonical
  (`hilda31w`: detrend / anomaly / per_year, `ndep_ret` 6.73) on a correctly stamped forcing. So that path
  went through all four guards with non-default values, and passed.

### 3. The app: passes

- `app/global.R:473` is the app's one pure-R call, the box diagram's RK4 flux trace over the last year.
- Sourcing `app/global.R` in the patched tree builds `APP_FLUX` normally (1 row, 2024), and the guard call is
  confirmed in the deparsed `ccx_run`.
- `app_build_forcing()` stamps from `APP_PARAMS`, and base R row slicing (`F[i, ]`) keeps the stamps
  (verified in R 4.5).

### 4. The calibration drivers: 9 of 21 call sites would stop, in 7 scripts

This is a STATIC read of every `ccx_run()` call under `calibration/`, done by a subagent and spot-checked as
listed below. `mode_variants.log` gives each mode's variants:
- `hilda29l` is all defaults;
- `hilda29e` is detrend / anomaly / constant, `ndep_ret` 9.08;
- `hilda31w` is detrend / anomaly / per_year, `ndep_ret` 6.73.

| script:line | why it would stop | today |
|---|---|---|
| `diag_d13c_isoflux_budget.R:74` | canonical params, default-built forcing | runs SILENTLY on the default variants |
| `diag_f2_periodic_spinup.R:77` | the same, and its 1750–2250 forcing runs past the deposition table (stamped "none") while `ndep_ret` is 6.73 | runs SILENTLY, with deposition zero |
| `diag_kz_pump_pathways.R:48, :49` | canonical params, unstamped forcing | the two R runs finish, then its C++ cross-check at `:52` STOPS |
| `diag_p12_compensator_redundant.R:100` | canonical params, default-built forcing | runs SILENTLY |
| `diag_seas_ml_convergence.R:64, :106` | `ccx_mode_file()` default params, default-built forcing | runs SILENTLY |
| `diag_seas_ml_probe.R:72` | canonical params, default-built forcing | runs SILENTLY |
| `diag_ta0_enso_upwelling_sign.R:68` | canonical params, unstamped forcing | its C++ call at `:62` STOPS first |

- **The other 12 sites pass.** They use default or `hilda29l`-era params, or they stamp with `ccx_*_of(p)` the
  way `dg_run()` does.
- **Spot-checked by hand:** `kz` `:24–30` and `:46–53`, `ta0` `:58–69` and `seas_ml_convergence` `:55–66` (read); every
  mode's variants (run).
- **No existing output is affected.** Every output these five SILENT scripts have written is dated 09-09 to
  09-21. Their logs name `hilda29l` or the 09-08 `hilda31` refit. The four variant switches were added on
  09-29 (ENSO index `e33ed24`, AOD mode `ee6d413`), 09-30 (`ccx_ndep_check` `c0ae37b`) and 10-12 (nuclear
  share `3130c9f`), so those runs had default variants on both sides. Nothing is quarantined.
- **The fix in each script** is to pass `enso_index` / `aod_mode` / `nuc_share = ccx_*_of(sp$params)`, as
  `dg_run()` does. f2 also needs a deposition source that covers its years.

## Reading

- Adding the guards stops nothing in the suite or the app.
- It turns five diagnostics that would currently run the canonical against the wrong forcing variants, without
  a word, into loud stops.
- Whether to land them, and whether to fix the seven scripts, is Marcus's.
