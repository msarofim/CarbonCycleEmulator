# The 10-05 landing-prep test tree, preserved — NOT canonical outputs

**What this is.** Every untracked file of the frozen worktree `~/ccx_frozen/20261005g_ocgobm` (detached at
`f35ca59`, plus the read script of `af7cb36`), copied here byte-identical, relative paths kept, before the tree was
removed on 2026-10-06 (Marcus: "Housekeeping (Recommended)"; CHANGELOG 10-06 f).

**Why it is kept.** Two CHANGELOG entries cite this tree as their evidence, and it was the only copy:
- 2026-10-05 (h), the like-for-like ocean diagnostic's two tests: (1) the default path bit-identical to the committed
  `ocean_climate_gobm_20261004.rds`; (2) the stratification-feedback path on a SCRATCH mode file;
- 2026-10-05 (j), the landing chain's dry run on #16's first finished start (id 1): its `DRYRUN_logs/`.

**What it is NOT.**
- `calibration/output/DRYRUN_refit_obj16/` and `DRYRUN_wave/` are a DRY-RUN promote of ONE start (id 1), not the
  landing. The landed #16 is `calibration/output/refit_20261005_hilda33p_obj16_hilda_csl3v0kaidgbem/`.
- `calibration/output/SCRATCH_obj16like_NOT_A_FIT/` is NOT A FIT: a scratch file for testing the readers.
- `outputs/diagnostics/*_DRYRUN*` and `*_obj16dry*` are the (j) dry run's previews of the read. The read of record is
  `outputs/diagnostics/obj16_refit_read_20261005.log` (CHANGELOG 10-05 p).
- `outputs/diagnostics/ocean_climate_gobm_20261005.{log,rds}` is (h)'s test (1), on hilda34g, and
  `ocean_climate_gobm_20261005_obj16like.{log,rds}` its test (2), on the SCRATCH file. They test the code; they are
  not #16's read (that is `ocean_climate_gobm_20261005_obj16.{log,rds}`, in the repo since 10-05 p).
- `calibration/diag_obj16_refit_read.R` is the read script AS IT RAN in the dry run. The live one is the repo's.
- `logs_regress_default.out`, `logs_test_mix.out`: the consoles of (h)'s tests (1) and (2).
