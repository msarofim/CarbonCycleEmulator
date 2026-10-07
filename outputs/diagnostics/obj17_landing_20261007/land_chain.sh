#!/bin/bash
# THE LANDING CHAIN FOR OBJECTIVE #17's STAGE 2 (handoff notes/handoff_2026-10-07_obj17_finished.md §3). Written 2026-10-07
# after the run finished (06:34 EDT, rc 0). Each piece was DRY-RUN on start_001 the night before (CHANGELOG 10-06 p);
# this chains them on the REAL outdir, in the REPO, and stops at the first failure. Run it in the background and wait
# on its PID; do NOT edit any repo script while it runs (memory never_edit_a_running_script).
#   0 land.sh (verify, copy into the repo, cmp, RUN_PROVENANCE)   1 the id-18 statement appended (numbers READ)
#   2 collect   3 promote (expect id 10, basin A)   4 Hessian (--update, nice 10)   5 read (diag_obj17_refit_read.R)
#   6 the one-pass check (fit_iav_module.R --check)   7 the same read at BASIN B (the dry run's promoted start_001)
# Logs: outputs/diagnostics/obj17_landing_20261007/. It ADOPTS nothing and commits nothing.
set -uo pipefail
R="$HOME/Documents/2026/CodeProjects/CarbonCycleEmulator"; cd "$R" || exit 1
TAG=20261006o; LAB=hilda_csl3v0kaidgbemw
NAME="multistart_${TAG}_${LAB}_seasml1_pin_obj17_sd1.0452"; DST="$R/calibration/output/$NAME"
DEST="$R/calibration/output/refit_20261007_obj17_${LAB}"; MODE="$DEST/mode_fit_pumpN.rds"
STAGE1="calibration/output/iav_module_20261006_hilda33p.rds"
BASIN_B_MODE="$HOME/ccx_frozen/20261006o_obj17_dryrun/calibration/output/DRYRUN_refit_obj17/mode_fit_pumpN.rds"
BASIN_B_WAVE="$HOME/ccx_frozen/20261006o_obj17_dryrun/calibration/output/DRYRUN_multistart_obj17"
L="$R/outputs/diagnostics/obj17_landing_20261007"; mkdir -p "$L"
export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1
step() { local name="$1"; shift; echo "== $name  $(date '+%H:%M:%S')"; if "$@" > "$L/$name.log" 2>&1; then echo "   rc 0";
  else echo "   FAILED (rc $?): see $L/$name.log"; tail -15 "$L/$name.log"; exit 1; fi; }

echo "landing chain at $(git rev-parse --short HEAD), $(date '+%Y-%m-%dT%H:%M:%S%z')"
git merge-base --is-ancestor 0a4e89f HEAD || { echo "REFUSED: HEAD predates 0a4e89f (the overlay fix promote needs)"; exit 1; }
git diff --quiet -- R calibration tests || { echo "REFUSED: uncommitted changes under R/, calibration/ or tests/ (provenance would say +dirty)"; exit 1; }

step land bash "$HOME/ccx_frozen/20261006o_obj17_land.sh"
step id18_statement Rscript -e '
  d <- commandArgs(TRUE)[1]; s <- readRDS(file.path(d, "start_018.rds"))
  tl <- grep("^MS_EVAL_TOL", readLines("calibration/run_dispersed_multistart.R"), value = TRUE)[1]
  tol <- as.numeric(regmatches(tl, regexpr("[0-9.]+e[-+]?[0-9]+", tl)))   # no backreference: Rscript -e unescapes them
  txt <- sprintf(paste0("\nID 18 STATEMENT (appended %s by ~/ccx_frozen/20261007_obj17_land_chain.sh; every number read from start_018.rds and the driver): ",
    "id 18 (%s) exited rc 1 on the driver DEAD-TASK gate. It ran OUT OF TIME (converged %s) at logpost %.6f; re-evaluated there %.6f, a relative gap ",
    "%.3e against MS_EVAL_TOL %g. The message says \"penalty plateau\", but the re-evaluation is FINITE: the gate fired on that small mismatch. ",
    "Its log shows two non-converged 12C conveyor spinups (|resid| ~5e-9), the likely source (untested). Recorded dead = TRUE, so collect refuses it; ",
    "it is ~120 log-units below the basins and changes nothing.\n"),
    format(Sys.time(), "%Y-%m-%d %H:%M"), s$kind, s$converged, s$logpost, s$final_lp_check, abs(s$final_lp_check - s$logpost) / abs(s$logpost), tol)
  cat(txt); cat(txt, file = file.path(d, "RUN_PROVENANCE.txt"), append = TRUE)' "$DST"
step collect env CCX_MS_OUTDIR="$DST" Rscript calibration/collect_dispersed_multistart.R
cp -p "$L/collect.log" "$DST/collect_20261007.log"
step promote Rscript calibration/promote_multistart_mode.R --name=obj17_${LAB} --outdir="$DST" --dest="$DEST"
echo "   promoted: $(Rscript -e 'm <- readRDS(commandArgs(TRUE)[1]); cat(sprintf("id %s, logpost %.6f", format(m$promoted_from$id), m$logpost))' "$MODE")"
step hessian nice -n 10 Rscript calibration/recompute_hessian.R "$MODE" --update
step read Rscript calibration/diag_obj17_refit_read.R
step check Rscript calibration/fit_iav_module.R --base="$MODE" --check="$STAGE1"
step read_basinB env CCX_O17_MODE="$BASIN_B_MODE" CCX_O17_WAVE="$BASIN_B_WAVE" CCX_O17_TAG=_basinB Rscript calibration/diag_obj17_refit_read.R
echo "== LANDING CHAIN DONE $(date '+%H:%M:%S'). Logs: $L. Next: handoff §3 steps 3-6 (read, the separate drivers, CHANGELOG, Marcus)."
