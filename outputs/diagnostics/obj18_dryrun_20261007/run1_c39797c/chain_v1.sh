#!/bin/bash
# OBJECTIVE #18's LANDING CHAIN (handoff notes/handoff_2026-10-07d_obj18_stage2_running.md s. 3.5-3.6; CHANGELOG 2026-10-07 k).
# ONE script, two modes, so the DRY RUN exercises the very chain the landing runs (#17's dry run tested its drivers, not
# its chain):
#   dryrun  a SEPARATE detached worktree at the repo's HEAD (~/ccx_frozen/20261007i_obj18_dryrun), a scratch copy of EVERY
#           start file at least 2 min old (never a file mid-write), the run tree's #18 port targets; logs in DRYRUN_logs/.
#           ⛔ A PARTIAL WAVE: its numbers preview the landing; they are not its read.
#   land    ~/ccx_frozen/20261007i_obj18_land.sh first (the run's end line, no work process, 24 exit codes; copy into the
#           repo; cmp; RUN_PROVENANCE), then the same steps IN THE REPO; logs in outputs/diagnostics/obj18_landing_<date>/.
# Steps, each stopping the chain at its first failure and naming its log:
#   collect -> basins (diag_obj18_basins.R: LP = the best stored logpost, NAT = the best likelihood + prior; RULED 10-07 k,
#   "Likelihood + prior (Recommended)") -> promote LP (promote's default; refused unless it IS the basin step's LP)
#   [+ promote NAT with --id when it differs: "Build --id, read both (Recommended)"] -> for EACH promoted mode: the
#   Hessian (--update, nice), the read (diag_obj18_refit_read.R), the one-pass check (fit_iav_module.R --check, RULED
#   0.1 sigma), the ocean-climate driver -> ONE scorecard (GATE V) with every promoted arm beside hilda29w.
# It ADOPTS nothing, COMMITS nothing, and edits no script: run it in the background and wait on its PID (memory
# never_edit_a_running_script; pgrep_wait_loop_matches_itself).
# Usage: bash ~/ccx_frozen/20261007i_obj18_chain.sh dryrun|land
set -uo pipefail
MODE="${1:-}"; [ "$MODE" = dryrun ] || [ "$MODE" = land ] || { echo "usage: $0 dryrun|land"; exit 2; }
REPO="$HOME/Documents/2026/CodeProjects/CarbonCycleEmulator"
RUNT="$HOME/ccx_frozen/20261007i_obj18"; TAG=20261007i; LAB=hilda_csl3v0kaidgbemwt
NAME="multistart_${TAG}_${LAB}_seasml1_pin_obj18_sd1.0452"
KIT=c39797c                      # the landing kit (CHANGELOG 10-07 k: promote --id, the basins, the read): the chain needs it at HEAD
STAGE1="calibration/output/iav_module_20261007_refit_20261006_obj17_basinB_start001_DRYRUN_hilda_csl3v0kaidgbemwt.rds"   # CCX_MODE_OBJ18_MODULE_FILE
INC=hilda29w                     # CCX_MODE_OBJ18_INCUMBENT: #17's basin B, the scorecard's comparison arm
DAY=$(date +%Y%m%d)
export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1
if [ "$MODE" = dryrun ]; then
  D="$HOME/ccx_frozen/20261007i_obj18_dryrun"
  if [ ! -e "$D" ]; then
    git -C "$REPO" diff --quiet -- R calibration tests || { echo "REFUSED: uncommitted changes under R/, calibration/ or tests/ (the tree would not be HEAD's code)"; exit 1; }
    C=$(git -C "$REPO" rev-parse --short HEAD)
    git -C "$REPO" worktree add --detach "$D" "$C" >/dev/null 2>&1 || { echo "worktree add failed"; exit 1; }
    for e in "$REPO"/data-raw/downloads/*; do b=$(basename "$e"); [ -e "$D/data-raw/downloads/$b" ] || ln -s "$e" "$D/data-raw/downloads/$b"; done
    echo "dry-run tree $D at $C"
  fi
  W="$D"; cd "$W" || exit 1
  WAVE="$W/calibration/output/DRYRUN_$NAME"; L="$W/DRYRUN_logs"; SFX=_DRYRUN; NICE=19; DPFX="DRYRUN_"
  export CCX_IAV_WORKERS=3       # the wave still holds 8 cores; the check's answer does not depend on the worker count
  [ ! -e "$WAVE" ] || { echo "REFUSED: $WAVE exists (a previous dry run): inspect it, or remove the tree, before re-running"; exit 1; }
  mkdir -p "$WAVE" "$L"
  N=0; for f in $(find "$RUNT/calibration/output/$NAME" -maxdepth 1 -name 'start_[0-9][0-9][0-9].rds' -mmin +2 | sort); do
    cp -p "$f" "$WAVE/"; cmp -s "$f" "$WAVE/$(basename "$f")" || { echo "the scratch copy differs from $f"; exit 1; }; N=$((N + 1)); done
  [ "$N" -gt 0 ] || { echo "no finished start at least 2 min old under the run"; exit 1; }
  echo "scratch copies of $N finished start files ($(ls "$WAVE" | tr '\n' ' '))"
  cp -p "$RUNT/calibration/torch/port_targets.csv" calibration/torch/port_targets.csv   # #18's targets (HEAD's are the canonical's)
else
  W="$REPO"; cd "$W" || exit 1
  WAVE="$W/calibration/output/$NAME"; L="$W/outputs/diagnostics/obj18_landing_$DAY"; SFX=""; NICE=10; DPFX=""
  git merge-base --is-ancestor "$KIT" HEAD || { echo "REFUSED: HEAD predates $KIT (promote --id)"; exit 1; }
  git diff --quiet -- R calibration tests || { echo "REFUSED: uncommitted changes under R/, calibration/ or tests/ (provenance would say +dirty)"; exit 1; }
  mkdir -p "$L"
fi
step() { local name="$1"; shift; echo "== $name  $(date '+%H:%M:%S')"; if "$@" > "$L/$name.log" 2>&1; then echo "   rc 0";
  else local rc=$?; echo "   FAILED (rc $rc): see $L/$name.log"; tail -15 "$L/$name.log"; exit 1; fi; }

echo "objective #18 landing chain ($MODE) at $(git -C "$W" rev-parse --short HEAD), $(date '+%Y-%m-%dT%H:%M:%S%z')"
[ "$MODE" = land ] && step land bash "$HOME/ccx_frozen/20261007i_obj18_land.sh"
step collect env CCX_MS_OUTDIR="$WAVE" Rscript calibration/collect_dispersed_multistart.R
[ "$MODE" = land ] && cp -p "$L/collect.log" "$WAVE/collect_$DAY.log"
step basins env CCX_O18_WAVE="$WAVE" CCX_O18_TAG="$SFX" Rscript calibration/diag_obj18_basins.R
# the decision file's path is READ from the step's own "saved" line: the driver dates it at ITS run time, and a chain
# that crosses midnight would otherwise look for yesterday's name
IDS="$(sed -n 's/^saved \(.*\)[.]{log,rds,ids}.*/\1/p' "$L/basins.log").ids"
LP=$(awk '$1 == "LP" {print $2}' "$IDS"); NAT=$(awk '$1 == "NAT" {print $2}' "$IDS")
[[ "$LP" =~ ^[0-9]+$ && "$NAT" =~ ^[0-9]+$ ]] || { echo "the basin step's $IDS names no LP / NAT id"; exit 1; }
echo "   the basins: LP id $LP (best stored logpost), NAT id $NAT (best likelihood + prior)"

DEST_LP="$W/calibration/output/${DPFX}refit_${DAY}_obj18_${LAB}"
step promote_lp Rscript calibration/promote_multistart_mode.R --name="obj18_${LAB}" --outdir="$WAVE" --dest="$DEST_LP"
GOT=$(Rscript -e 'cat(readRDS(commandArgs(TRUE)[1])$promoted_from$id)' "$DEST_LP/mode_fit_pumpN.rds")
[ "$GOT" = "$LP" ] || { echo "promote's default picked id $GOT but the basin step's LP is $LP: STOP (a dead best? read both logs)"; exit 1; }
PROMOTED=("$DEST_LP"); ARMS="$INC,obj18=$DEST_LP/mode_fit_pumpN.rds"
if [ "$NAT" != "$LP" ]; then
  NP=$(printf %03d "$NAT"); DEST_NAT="${DEST_LP}_id${NP}"
  step promote_nat Rscript calibration/promote_multistart_mode.R --name="obj18_${LAB}_id${NP}" --outdir="$WAVE" --dest="$DEST_NAT" \
    --id="$NAT" --why="the basin best by likelihood + prior (calibration/diag_obj18_basins.R, $IDS); the best stored logpost, id $LP, is promoted beside it (Marcus 2026-10-07 k: 'Build --id, read both (Recommended)', 'Likelihood + prior (Recommended)')"
  PROMOTED+=("$DEST_NAT"); ARMS="$ARMS,obj18id${NP}=$DEST_NAT/mode_fit_pumpN.rds"
fi
for P in "${PROMOTED[@]}"; do
  K=$(basename "$P"); M="$P/mode_fit_pumpN.rds"; ID=$(Rscript -e 'cat(sprintf("%03d", readRDS(commandArgs(TRUE)[1])$promoted_from$id))' "$M")
  echo "   promoted: $K = id $ID"
  step "hessian_id$ID" nice -n "$NICE" Rscript calibration/recompute_hessian.R "$M" --update
  step "read_id$ID" env CCX_O18_MODE="$M" CCX_O18_WAVE="$WAVE" CCX_O18_TAG="${SFX}_id$ID" Rscript calibration/diag_obj18_refit_read.R
  step "check_id$ID" Rscript calibration/fit_iav_module.R --base="$M" --check="$STAGE1"
  step "ocean_id$ID" env CCX_OC_MODE="obj18id$ID=$M" Rscript calibration/diag_ocean_climate_gobm.R
done
step scorecard env CCX_SC_EXTRA_MODE="$ARMS" CCX_SC_TAG_SUFFIX="_obj18$SFX" Rscript calibration/diag_whole_model_scorecard.R
echo "== CHAIN DONE ($MODE) $(date '+%H:%M:%S'). Logs: $L"
