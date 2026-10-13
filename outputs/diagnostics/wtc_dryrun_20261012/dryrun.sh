#!/bin/bash
# DRY RUN of the WTC landing tools that need only a mode file (CHANGELOG 2026-10-12 ff): a SYNTHETIC file (hilda29e
# relabelled under hilda_csl3v0kaidgbemwtc at 0.90 / 2.0, its logpost the wave's port target), in the detached worktree
# ~/ccx_frozen/20261012ff_wtc_dryrun at c3514fb. Each step logs; a failure is recorded and the next step still runs (the
# point is to find every break in one pass). collect / basins / promote need the wave's start files: not exercised here.
set -u
D="$HOME/ccx_frozen/20261012ff_wtc_dryrun"; cd "$D" || exit 1
export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 CCX_IAV_WORKERS=2
M="$D/calibration/output/DRYRUN_refit_wtc_synthetic/mode_fit_pumpN.rds"; W="$D/calibration/output/DRYRUN_wave"
REF=$(Rscript -e 'suppressMessages(for (f in list.files("R", pattern="[.]R$", full.names=TRUE)) source(f)); cat(ccx_path(CCX_MODE_OBJ18P2_MODULE_FILE))')
L="$D/DRYRUN_logs"; mkdir -p "$L"
step() { local name="$1"; shift; echo "== $name  $(date '+%H:%M:%S')"; if "$@" > "$L/$name.log" 2>&1; then echo "   rc 0"; else echo "   FAILED (rc $?)"; tail -8 "$L/$name.log"; fi; }
echo "WTC landing dry run at $(git -C "$D" rev-parse --short HEAD), $(date '+%Y-%m-%dT%H:%M:%S%z')"
step hessian nice -n 10 Rscript calibration/recompute_hessian.R "$M" --update
step read env CCX_WTC_MODE="$M" CCX_WTC_WAVE="$W" CCX_WTC_TAG=_DRYRUN nice -n 10 Rscript calibration/diag_wtc_refit_read.R
step check nice -n 10 Rscript calibration/fit_iav_module.R --base="$M" --check="$REF"
step ocean env CCX_OC_MODE="wtcdry=$M" nice -n 10 Rscript calibration/diag_ocean_climate_gobm.R
step scorecard env CCX_SC_EXTRA_MODE="wtcdry=$M" CCX_SC_TAG_SUFFIX=_wtc_DRYRUN nice -n 10 Rscript calibration/diag_whole_model_scorecard.R
echo "== DRY RUN DONE $(date '+%H:%M:%S'). Logs: $L"
