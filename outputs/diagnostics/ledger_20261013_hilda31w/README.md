# The hilda31w adoption's test ledger (2026-10-13)

The full suite at `2b1c603` (the adoption commit) and the evidence used to classify every failure. CHANGELOG 2026-10-13 (g).
Nothing here edits a repo test. Model: CarbonCycleEmulator, canonical `hilda31w` (label `hilda_csl3v0kaidgbemwtc`, seas_ml 1).
No RNG is used anywhere in these files.

| file | what it is |
|---|---|
| `../suite_20261013_2b1c603.log` | the full suite, frozen worktree `~/ccx_frozen/suite_20261013_2b1c603`, BLAS pinned to 1: 7865 passed, 32 failed, 12 errored, 4 skipped, 19.3 min |
| `../suite_20261013_2b1c603_ledger.log` | `ledger_rerun.R` on the 15 failing files: every failure and error message (44 = 32 + 12), since the summary reporter printed only the first 10 |
| `suite_runner_2b1c603.sh` | the suite runner as it ran |
| `harness_patch_NOT_APPLIED.diff` | a PROPOSED patch to five test files, applied ONLY in the scratch worktree `~/ccx_frozen/ledger_20261013_2b1c603`: each hand-built forcing passes `nuc_share = ccx_nuc_share_of(p)`, and `test-stability.R` builds the canonical's own column (`ccx_grid_of(p)`; the P8 wall on `ccx_ocean_depth()`), not the legacy 3700 m one |
| `ledger_patched.R`, `ledger_patched_2b1c603.log` | those five files run with the patch: canonical-contracts (gates 1-2, R<->C++ parity) and stability pass at hilda31w; four failures surface underneath (flux-trace-exact:65, imbalance-panel x4 in one test, mechanisms:328) |
| `power_spinup_diag154.R`, `power_spinup_diag154_2b1c603.log` | read-only, at `2b1c603`: test-spinup-diagnostics:154's quantities at hilda29e and hilda31w, and the orbit's monthly global d13C against its annual mean (run twice; identical output) |
