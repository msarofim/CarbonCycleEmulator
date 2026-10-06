#!/bin/bash
# OVERNIGHT LANDING CHAIN for objective #16's refit. Marcus, 2026-10-05 ~20:50: "I'm headed to bed. Take the next
# obvious steps whenever the running tasks complete." It runs handoff notes/handoff_2026-10-05d_obj16_cpu_budget.md
# §4 steps 1-7, each dry-run tested in CHANGELOG 10-05 (j), once the run ENDS, and it does not depend on any Claude
# session (launched under nohup + caffeinate; memory background_job_dies_with_its_session).
# NOT here: step 8 (CHANGELOG, commit, push) and step 9 (adoption, which is Marcus's call).
# - It waits on the launch chain's PID with kill -0, never pgrep (memory pgrep_wait_loop_matches_itself).
# - It stops at the first failing step (set -euo pipefail): promote STOPs on its own gate failures.
# - The date is stamped ONCE, so a landing that crosses midnight writes ONE refit directory. The handoff's commands
#   call $(date) per step, which would split it.
# - BLAS is pinned to one thread (memory pin_blas_threads).
# ⛔ Never edit this file while it runs: bash reads a script as it executes it.
# ⛔ No other `run_dispersed_multistart.R` process may be alive when step 1 runs: the landing helper's work-process
#   check counts EVERY one, a smoke test's included, and refuses.
set -euo pipefail
LAUNCH_PID="${LAUNCH_PID:-27265}"   # bash ~/ccx_frozen/20261005f_obj16_launch.sh, started 09:01:19
R="${CCX_LAND_REPO:-$HOME/Documents/2026/CodeProjects/CarbonCycleEmulator}"
LAND_SH="${CCX_LAND_SH:-$HOME/ccx_frozen/20261005f_obj16_land.sh}"
ADDENDUM_R="$HOME/ccx_frozen/20261005f_obj16_sleep_addendum.R"
NAME="multistart_20261005f_hilda_csl3v0kaidgbem_seasml1_pin_ent_seas_amp_SH=0_w_eq=27_gamma_eq=1_pump_export=9.08_w_vent=0_gamma_vent=0_w_thc=0_gamma_enso_ocn_NH=0_gamma_enso_ocn_SH=0_npp_tsens=0_sd1.0452"
OUT="$R/calibration/output/$NAME"   # the landing helper's own DST
export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1
step() { echo; echo "######## $(date '+%Y-%m-%dT%H:%M:%S%z') STEP $*"; }

echo "landchain start $(date '+%Y-%m-%dT%H:%M:%S%z'); waiting on the launch chain, PID $LAUNCH_PID"
while kill -0 "$LAUNCH_PID" 2>/dev/null; do sleep 60; done
sleep 5
D=$(date +%Y%m%d)
DEST="calibration/output/refit_${D}_obj16_hilda_csl3v0kaidgbem"
echo "launch chain gone $(date '+%Y-%m-%dT%H:%M:%S%z'); date stamp $D; DEST $DEST"
cd "$R"

step "1 land: confirm, copy, verify, record"
bash "$LAND_SH"
step "1b the ruled sleep statement, appended to RUN_PROVENANCE.txt"
Rscript --vanilla "$ADDENDUM_R" "$OUT" "$OUT/logs" "$OUT/RUN_PROVENANCE.txt" \
  || echo "*** SLEEP ADDENDUM FAILED: the statement must be written by hand before the CHANGELOG entry"

step "2 collect"
CCX_MS_OUTDIR="$OUT" Rscript calibration/collect_dispersed_multistart.R 2>&1 | tee "$OUT/collect_${D}.log"

step "3 promote (GATES 1-5 must pass; it STOPs otherwise)"
[ ! -e "$DEST" ] || { echo "REFUSED: $DEST already exists"; exit 1; }
mkdir -p "$DEST"
Rscript calibration/promote_multistart_mode.R --name=obj16_hilda_csl3v0kaidgbem --outdir="$OUT" --dest="$DEST" 2>&1 \
  | tee "$DEST/promote_${D}.log"

step "4 Hessian"
nice -n 10 Rscript calibration/recompute_hessian.R "$DEST/mode_fit_pumpN.rds" --update 2>&1 | tee "$DEST/hessian_${D}.log"

step "5 read (its own log: outputs/diagnostics/)"
Rscript calibration/diag_obj16_refit_read.R 2>&1

step "6 ocean, like-for-like, under the RULED GMST rule (its own log: outputs/diagnostics/)"
CCX_OC_MODE="obj16=$DEST/mode_fit_pumpN.rds" Rscript calibration/diag_ocean_climate_gobm.R 2>&1

step "7 scorecard"
CCX_SC_EXTRA_MODE="obj16=$DEST/mode_fit_pumpN.rds" CCX_SC_TAG_SUFFIX=_obj16 \
  Rscript calibration/diag_whole_model_scorecard.R 2>&1 | tee "outputs/diagnostics/whole_model_scorecard_${D}_hilda34g_obj16.log"

echo
echo "landchain DONE $(date '+%Y-%m-%dT%H:%M:%S%z'): steps 1-7 complete. NOTHING committed; NOTHING adopted."
