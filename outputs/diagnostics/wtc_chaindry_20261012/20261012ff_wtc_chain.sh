#!/bin/bash
# THE WTC REFIT's LANDING CHAIN (CHANGELOG 2026-10-12 ff; #18's two-mode chain, committed as
# outputs/diagnostics/obj18_dryrun_20261007/run2_3a50d21/chain_v2.sh, with the tree, tag, label, the read and the check's
# reference changed). ONE script, two modes, so the dry run exercises the very chain the landing runs:
#   dryrun  a SEPARATE detached worktree at the repo's HEAD (~/ccx_frozen/20261012ff_wtc_chaindry), a scratch copy of EVERY
#           start file at least 2 min old (never a file mid-write), the run tree's port targets; logs in DRYRUN_logs/.
#           ⛔ A PARTIAL WAVE: its numbers preview the landing; they are not its read.
#   land    ~/ccx_frozen/20261012ff_wtc_land.sh first (the run's end line, no work process, 24 exit codes; copy into the
#           repo; cmp; RUN_PROVENANCE), then the same steps IN THE REPO; logs in outputs/diagnostics/wtc_landing_<date>/.
# Steps, each stopping the chain at its first failure and naming its log:
#   collect -> basins (diag_obj18_basins.R, which reads the WTC objective since c3514fb: LP = the best stored logpost,
#   NAT = the best likelihood + prior, NEAR = the runner-up on it within the optimiser's bound; the 10-07 k rulings) ->
#   promote LP (promote's default; refused unless it IS the basin step's LP) [+ NAT with --id when it differs] [+ NEAR]
#   -> for EACH promoted mode: the Hessian (--update, nice), the WTC read (diag_wtc_refit_read.R), the one-pass module
#   check (fit_iav_module.R --check against CCX_MODE_OBJ18P2_MODULE_FILE, the file the pins came from) and its verdict at
#   the RULED 0.1 sigma (Marcus 2026-10-12: "I'm okay with 0.1 sigma unless that's a problem"),
#   the ocean-climate driver -> ONE scorecard (GATE V) with every promoted arm beside the canonical hilda29e (arm C).
# It ADOPTS nothing, COMMITS nothing, and edits no script: run it in the background and wait on its PID (memory
# never_edit_a_running_script; pgrep_wait_loop_matches_itself).
# Usage: bash ~/ccx_frozen/20261012ff_wtc_chain.sh dryrun|land
set -uo pipefail
MODE="${1:-}"; [ "$MODE" = dryrun ] || [ "$MODE" = land ] || { echo "usage: $0 dryrun|land"; exit 2; }
REPO="$HOME/Documents/2026/CodeProjects/CarbonCycleEmulator"
RUNT="$HOME/ccx_frozen/20261012ff_wtc"; TAG=20261012ff; LAB=hilda_csl3v0kaidgbemwtc
NAME="multistart_${TAG}_${LAB}_seasml1_pin_wtc_sd1.0452_prior_bomb_share_NH_seas_T_lag"
KIT=c3514fb                      # the landing kit (nuc_share in the hand-built forcings, the basins' table, the WTC read)
DAY=$(date +%Y%m%d)
export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1
if [ "$MODE" = dryrun ]; then
  D="$HOME/ccx_frozen/20261012ff_wtc_chaindry"
  if [ ! -e "$D" ]; then
    git -C "$REPO" diff --quiet -- R calibration tests || { echo "REFUSED: uncommitted changes under R/, calibration/ or tests/ (the tree would not be HEAD's code)"; exit 1; }
    C=$(git -C "$REPO" rev-parse --short HEAD)
    git -C "$REPO" worktree add --detach "$D" "$C" >/dev/null 2>&1 || { echo "worktree add failed"; exit 1; }
    for e in "$REPO"/data-raw/downloads/*; do b=$(basename "$e"); [ -e "$D/data-raw/downloads/$b" ] || ln -s "$e" "$D/data-raw/downloads/$b"; done
    echo "dry-run tree $D at $C"
  fi
  W="$D"; cd "$W" || exit 1
  WAVE="$W/calibration/output/DRYRUN_$NAME"; L="$W/DRYRUN_logs"; SFX=_DRYRUN; NICE=19; DPFX="DRYRUN_"
  export CCX_IAV_WORKERS=2       # the wave still holds 8 cores; the check's answer does not depend on the worker count
  [ ! -e "$WAVE" ] || { echo "REFUSED: $WAVE exists (a previous dry run): inspect it, or remove the tree, before re-running"; exit 1; }
  mkdir -p "$WAVE" "$L"
  N=0; for f in $(find "$RUNT/calibration/output/$NAME" -maxdepth 1 -name 'start_[0-9][0-9][0-9].rds' -mmin +2 | sort); do
    cp -p "$f" "$WAVE/"; cmp -s "$f" "$WAVE/$(basename "$f")" || { echo "the scratch copy differs from $f"; exit 1; }; N=$((N + 1)); done
  [ "$N" -gt 0 ] || { echo "no finished start at least 2 min old under the run"; exit 1; }
  echo "scratch copies of $N finished start files ($(ls "$WAVE" | tr '\n' ' '))"
  cp -p "$RUNT/calibration/torch/port_targets.csv" calibration/torch/port_targets.csv   # the WTC targets (HEAD's are the canonical's)
  cp -p "$RUNT/calibration/torch/port_targets.csv" "$WAVE/port_targets_${LAB}.csv"      # where the land script puts them
else
  W="$REPO"; cd "$W" || exit 1
  WAVE="$W/calibration/output/$NAME"; L="$W/outputs/diagnostics/wtc_landing_$DAY"; SFX=""; NICE=10; DPFX=""
  git merge-base --is-ancestor "$KIT" HEAD || { echo "REFUSED: HEAD predates $KIT (the landing kit)"; exit 1; }
  git diff --quiet -- R calibration tests || { echo "REFUSED: uncommitted changes under R/, calibration/ or tests/ (provenance would say +dirty)"; exit 1; }
  mkdir -p "$L"
fi
MODREF=$(Rscript -e 'suppressMessages(for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)); cat(ccx_path(CCX_MODE_OBJ18P2_MODULE_FILE))')
[ -f "$MODREF" ] || { echo "no module-check reference file ($MODREF)"; exit 1; }
step() { local name="$1"; shift; echo "== $name  $(date '+%H:%M:%S')"; if "$@" > "$L/$name.log" 2>&1; then echo "   rc 0";
  else local rc=$?; echo "   FAILED (rc $rc): see $L/$name.log"; tail -15 "$L/$name.log"; exit 1; fi; }

echo "WTC landing chain ($MODE) at $(git -C "$W" rev-parse --short HEAD), $(date '+%Y-%m-%dT%H:%M:%S%z')"
[ "$MODE" = land ] && step land bash "$HOME/ccx_frozen/20261012ff_wtc_land.sh"
step collect env CCX_MS_OUTDIR="$WAVE" Rscript calibration/collect_dispersed_multistart.R
[ "$MODE" = land ] && cp -p "$L/collect.log" "$WAVE/collect_$DAY.log"
step basins env CCX_O18_WAVE="$WAVE" CCX_O18_TAG="_wtc$SFX" Rscript calibration/diag_obj18_basins.R
# the decision file's path is READ from the step's own "saved" line (a chain that crosses midnight would otherwise look
# for yesterday's name)
IDS="$(sed -n 's/^saved \(.*\)[.]{log,rds,ids}.*/\1/p' "$L/basins.log").ids"
LP=$(awk '$1 == "LP" {print $2}' "$IDS"); NAT=$(awk '$1 == "NAT" {print $2}' "$IDS"); NEAR=$(awk '$1 == "NEAR" {print $2}' "$IDS")
[[ "$LP" =~ ^[0-9]+$ && "$NAT" =~ ^[0-9]+$ ]] || { echo "the basin step's $IDS names no LP / NAT id"; exit 1; }
[ -z "$NEAR" ] || [[ "$NEAR" =~ ^[0-9]+$ ]] || { echo "the basin step's $IDS names a malformed NEAR id '$NEAR'"; exit 1; }
echo "   the basins: LP id $LP (best stored logpost), NAT id $NAT (best likelihood + prior)${NEAR:+, NEAR id $NEAR (the runner-up on it, within the optimiser convergence bound)}"

DEST_LP="$W/calibration/output/${DPFX}refit_${DAY}_wtc_${LAB}"
step promote_lp Rscript calibration/promote_multistart_mode.R --name="wtc_${LAB}" --outdir="$WAVE" --dest="$DEST_LP"
GOT=$(Rscript -e 'cat(readRDS(commandArgs(TRUE)[1])$promoted_from$id)' "$DEST_LP/mode_fit_pumpN.rds")
[ "$GOT" = "$LP" ] || { echo "promote's default picked id $GOT but the basin step's LP is $LP: STOP (a dead best? read both logs)"; exit 1; }
PROMOTED=("$DEST_LP"); ARMS="wtc=$DEST_LP/mode_fit_pumpN.rds"
RULE="Marcus 2026-10-07 k: 'Build --id, read both (Recommended)', 'Likelihood + prior (Recommended)', 'Read both within 0.5 (Recommended)'"
promote_id() {   # $1 the id, $2 why: promote --id into <the LP dest>_id<NNN>, and add it to the reads and the scorecard
  local NP; NP=$(printf %03d "$1"); local DEST="${DEST_LP}_id${NP}"
  step "promote_id$NP" Rscript calibration/promote_multistart_mode.R --name="wtc_${LAB}_id${NP}" --outdir="$WAVE" --dest="$DEST" --id="$1" --why="$2"
  PROMOTED+=("$DEST"); ARMS="$ARMS,wtcid${NP}=$DEST/mode_fit_pumpN.rds"; }
if [ "$NAT" != "$LP" ]; then
  promote_id "$NAT" "the basin best by likelihood + prior (calibration/diag_obj18_basins.R, $IDS); the best stored logpost, id $LP, is promoted beside it ($RULE)"
fi
if [ -n "$NEAR" ] && [ "$NEAR" != "$LP" ] && [ "$NEAR" != "$NAT" ]; then
  promote_id "$NEAR" "the RUNNER-UP on likelihood + prior, within the optimiser's convergence bound of the best (calibration/diag_obj18_basins.R, $IDS); read beside the best ($RULE)"
fi
for P in "${PROMOTED[@]}"; do
  K=$(basename "$P"); M="$P/mode_fit_pumpN.rds"; ID=$(Rscript -e 'cat(sprintf("%03d", readRDS(commandArgs(TRUE)[1])$promoted_from$id))' "$M")
  echo "   promoted: $K = id $ID"
  step "hessian_id$ID" nice -n "$NICE" Rscript calibration/recompute_hessian.R "$M" --update
  step "read_id$ID" env CCX_WTC_MODE="$M" CCX_WTC_WAVE="$WAVE" CCX_WTC_TAG="${SFX}_id$ID" Rscript calibration/diag_wtc_refit_read.R
  step "check_id$ID" Rscript calibration/fit_iav_module.R --base="$M" --check="$MODREF"
  CK=$(sed -n 's/^saved \(calibration\/output\/iav_module_[^ ]*[.]rds\) and .*/\1/p' "$L/check_id$ID.log")
  step "checkz_id$ID" Rscript -e 'x <- readRDS(commandArgs(TRUE)[1])$check; if (is.null(x)) stop("no $check in ", commandArgs(TRUE)[1])
    if (!isTRUE(all.equal(x$tol, 0.1))) stop("the check ran at tol ", x$tol, ", not the RULED 0.1 sigma")
    cat(sprintf("%s moved %+.5f sigma\n", names(x$z), x$z), sep = "")
    cat(sprintf("RULED 0.1 sigma (Marcus 2026-10-12): %s\n", if (isTRUE(x$pass)) "STOP -- no second pass" else "a name moved MORE: to Marcus before any second pass"))' "$CK"
  cat "$L/checkz_id$ID.log" | sed 's/^/     /'
  step "ocean_id$ID" env CCX_OC_MODE="wtcid$ID=$M" Rscript calibration/diag_ocean_climate_gobm.R
done
step scorecard env CCX_SC_EXTRA_MODE="$ARMS" CCX_SC_TAG_SUFFIX="_wtc$SFX" Rscript calibration/diag_whole_model_scorecard.R
echo "== CHAIN DONE ($MODE) $(date '+%H:%M:%S'). Logs: $L"
