#!/bin/bash
# RESUME THE WTC LANDING CHAIN BY HAND (CHANGELOG 2026-10-13 b/c/d). The armed land chain (~/ccx_frozen/20261012ff_wtc_chain.sh
# land, 2026-10-13 07:36 at 065697f) stopped at the module check's GATE 0 (1.18e-5 > the then-ruled 1e-5) -- the objective's
# noise floor. After the two rulings (9200485: CCX_REPRO_TOL 5e-5; the most-stable Hessian step), this re-runs from the
# HESSIAN (its pre-fix output is quarantined, outputs/quarantine/20261013_hess_fixed_fallback/) in THREE STAGES, each
# committed by hand before the next so every stage reads committed inputs (memory stamp_dirty_from_untracked_input):
#   A  hessian (--update)                      B  read, check, checkz (the RULED 0.1 sigma)       C  ocean, scorecard
# The steps are the chain's, verbatim, for the one promoted mode (LP = NAT = id 17; no NEAR within 0.5). The land step is
# NOT re-run (it refuses an existing outdir). ADOPTS nothing, COMMITS nothing. Logs: outputs/diagnostics/wtc_landing_20261013/resume/
# Usage: bash ~/ccx_frozen/20261013_wtc_resume.sh A|B|C
set -uo pipefail
STAGE="${1:-}"; [[ "$STAGE" =~ ^[ABC]$ ]] || { echo "usage: $0 A|B|C"; exit 2; }
REPO="$HOME/Documents/2026/CodeProjects/CarbonCycleEmulator"; cd "$REPO" || exit 1
LAB=hilda_csl3v0kaidgbemwtc; WAVE="$REPO/calibration/output/multistart_20261012ff_${LAB}_seasml1_pin_wtc_sd1.0452_prior_bomb_share_NH_seas_T_lag"
P="$REPO/calibration/output/refit_20261013_wtc_${LAB}"; M="$P/mode_fit_pumpN.rds"; L="$REPO/outputs/diagnostics/wtc_landing_20261013/resume"
RULED=9200485; export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1
git merge-base --is-ancestor "$RULED" HEAD || { echo "REFUSED: HEAD predates $RULED (the rulings)"; exit 1; }
git diff --quiet -- R calibration tests || { echo "REFUSED: uncommitted changes under R/, calibration/ or tests/"; exit 1; }
[ -z "$(git status --porcelain --untracked-files=normal -- R src calibration app data)" ] || { echo "REFUSED: untracked or changed files under a stamp path (commit the previous stage first)"; git status --short -- R src calibration app data; exit 1; }
mkdir -p "$L"
ID=$(Rscript -e 'cat(sprintf("%03d", readRDS(commandArgs(TRUE)[1])$promoted_from$id))' "$M"); [ "$ID" = 017 ] || { echo "the promoted file is id $ID, not 017"; exit 1; }
step() { local name="$1"; shift; echo "== $name  $(date '+%H:%M:%S')"; if "$@" > "$L/$name.log" 2>&1; then echo "   rc 0";
  else local rc=$?; echo "   FAILED (rc $rc): see $L/$name.log"; tail -15 "$L/$name.log"; exit 1; fi; }
echo "WTC landing RESUME stage $STAGE at $(git rev-parse --short HEAD), $(date '+%Y-%m-%dT%H:%M:%S%z')"
case "$STAGE" in
A) step "hessian_id$ID" nice -n 10 Rscript calibration/recompute_hessian.R "$M" --update ;;
B) step "read_id$ID" env CCX_WTC_MODE="$M" CCX_WTC_WAVE="$WAVE" CCX_WTC_TAG="_id$ID" Rscript calibration/diag_wtc_refit_read.R
   MODREF=$(Rscript -e 'suppressMessages(for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)); cat(ccx_path(CCX_MODE_OBJ18P2_MODULE_FILE))')
   [ -f "$MODREF" ] || { echo "no module-check reference file ($MODREF)"; exit 1; }
   step "check_id$ID" Rscript calibration/fit_iav_module.R --base="$M" --check="$MODREF"
   CK=$(sed -n 's/^saved \(calibration\/output\/iav_module_[^ ]*[.]rds\) and .*/\1/p' "$L/check_id$ID.log")
   step "checkz_id$ID" Rscript -e 'x <- readRDS(commandArgs(TRUE)[1])$check; if (is.null(x)) stop("no $check in ", commandArgs(TRUE)[1])
     if (!isTRUE(all.equal(x$tol, 0.1))) stop("the check ran at tol ", x$tol, ", not the RULED 0.1 sigma")
     cat(sprintf("%s moved %+.5f sigma\n", names(x$z), x$z), sep = "")
     cat(sprintf("RULED 0.1 sigma (Marcus 2026-10-12): %s\n", if (isTRUE(x$pass)) "STOP -- no second pass" else "a name moved MORE: to Marcus before any second pass"))' "$CK"
   sed 's/^/     /' "$L/checkz_id$ID.log" ;;
C) step "ocean_id$ID" env CCX_OC_MODE="wtcid$ID=$M" Rscript calibration/diag_ocean_climate_gobm.R
   step scorecard env CCX_SC_EXTRA_MODE="wtc=$M" CCX_SC_TAG_SUFFIX="_wtc" Rscript calibration/diag_whole_model_scorecard.R ;;
esac
echo "== STAGE $STAGE DONE $(date '+%H:%M:%S'). Logs: $L"
