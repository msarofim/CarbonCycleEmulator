#!/bin/bash
# LAND OBJECTIVE #16's REFIT: handoff notes/handoff_2026-10-05b_obj16_running.md §5 steps 1-2 (CHANGELOG 10-05 f).
# Written 2026-10-05 while the refit ran, on the k_w arm's landing (10-05 a).
#
# What it does, in order:
#   - VERIFIES the run finished: the chain's end line, NO work process left, and 24 exit codes.
#   - COPIES into the repo: the outdir (start + ckpt files), the task logs, the exit file, the wave log, the preflight
#     folder, the port-target log, the launch script and chain log (as logs/launch.{sh,out}), and the port targets.
#   - CMPs every copied file.
#   - Only then writes RUN_PROVENANCE.txt, from facts it reads (the k_w arm's one-line template).
# What it does NOT do: collect, promote, commit, or delete anything. Those stay separate, read steps.
# It REFUSES to overwrite an existing repo outdir, so a failed run leaves nothing half-written that it would reuse.
# Usage: bash ~/ccx_frozen/20261005f_obj16_land.sh
set -euo pipefail
T="$HOME/ccx_frozen/20261005f_obj16"; TAG=20261005f; LAB=hilda_csl3v0kaidgbem; NSTART=24
R="$HOME/Documents/2026/CodeProjects/CarbonCycleEmulator"
PINS="ent_seas_amp_SH=0,w_eq=27,gamma_eq=1,pump_export=9.08,w_vent=0,gamma_vent=0,w_thc=0,gamma_enso_ocn_NH=0,gamma_enso_ocn_SH=0,npp_tsens=0"
NAME="multistart_${TAG}_${LAB}_seasml1_pin_$(echo "$PINS" | tr ',' '_')_sd1.0452"    # the launch script's own construction
SRC="$T/calibration/output/$NAME"; DST="$R/calibration/output/$NAME"
LOUT="$HOME/ccx_frozen/20261005f_obj16_launch.out"; LSH="$HOME/ccx_frozen/20261005f_obj16_launch.sh"
EX="$T/logs/ccx_multistart_mac_${TAG}_exit.txt"; WAVE="$T/logs/wave_${TAG}.log"

echo "== 1. FINISHED?"
END=$(grep -E "^objective #16 end .* rc [0-9]+$" "$LOUT" || true)
[ -n "$END" ] || { echo "NOT FINISHED: no end line in $LOUT"; exit 1; }
echo "  $END"
# the WORK processes, not the launcher (memory background_job_dies_with_its_session); this script's own command
# line does not contain the pattern, pgrep never lists itself, and the [t] keeps any WRAPPER shell whose argv quotes
# this line from matching itself (memory pgrep_wait_loop_matches_itself)
NWORK=$( (pgrep -f "R.*--file=calibration/run_dispersed_multistar[t].R" || true) | wc -l | tr -d ' ')
[ "$NWORK" -eq 0 ] || { echo "WORK PROCESSES STILL RUNNING: $NWORK"; exit 1; }
NEX=$(wc -l < "$EX" | tr -d ' '); NBAD=$(awk '$2 != 0' "$EX" | wc -l | tr -d ' ')
echo "  exit file: $NEX lines, $NBAD non-zero"; [ "$NEX" -eq "$NSTART" ] || { echo "EXPECTED $NSTART exit codes"; exit 1; }
(grep -E "^all tasks finished|^non-zero exits" "$WAVE" || true) | sed 's/^/  /'
NS=$(ls "$SRC" | grep -cE '^start_[0-9]{3}[.]rds$' || true); NC=$(ls "$SRC" | grep -cE '^start_[0-9]{3}_ckpt[.]rds$' || true)
echo "  outdir: $NS start files, $NC checkpoints, $(ls "$SRC" | wc -l | tr -d ' ') entries in all"

echo "== 2. COPY into $DST"
[ ! -e "$DST" ] || { echo "REFUSED: $DST already exists (inspect it; never overwrite)"; exit 1; }
mkdir -p "$DST/logs"
cp -pR "$SRC"/. "$DST"/
cp -p "$T"/logs/ccx_multistart_mac_${TAG}_[0-9][0-9][0-9].out "$EX" "$WAVE" "$T/logs/port_targets_${TAG}.log" "$DST/logs/"
cp -pR "$T/logs/preflight_${TAG}" "$DST/logs/"
cp -p "$LSH" "$DST/logs/launch.sh"; cp -p "$LOUT" "$DST/logs/launch.out"
cp -p "$T/calibration/torch/port_targets.csv" "$DST/port_targets_${LAB}.csv"

echo "== 3. VERIFY byte-identity"
FAIL=0
d=$(diff -rq "$SRC" "$DST" -x logs -x "port_targets_${LAB}.csv" || true); [ -z "$d" ] || { echo "$d"; FAIL=1; }
d=$(diff -rq "$T/logs/preflight_${TAG}" "$DST/logs/preflight_${TAG}" || true); [ -z "$d" ] || { echo "$d"; FAIL=1; }
NLOG=0
for f in "$T"/logs/ccx_multistart_mac_${TAG}_[0-9][0-9][0-9].out "$EX" "$WAVE" "$T/logs/port_targets_${TAG}.log"; do
  cmp -s "$f" "$DST/logs/$(basename "$f")" || { echo "MISMATCH $f"; FAIL=1; }; NLOG=$((NLOG + 1)); done
cmp -s "$LSH" "$DST/logs/launch.sh" || { echo "MISMATCH launch.sh"; FAIL=1; }
cmp -s "$LOUT" "$DST/logs/launch.out" || { echo "MISMATCH launch.out"; FAIL=1; }
cmp -s "$T/calibration/torch/port_targets.csv" "$DST/port_targets_${LAB}.csv" || { echo "MISMATCH port targets"; FAIL=1; }
[ "$FAIL" -eq 0 ] || { echo "VERIFICATION FAILED: the copy is NOT byte-identical; RUN_PROVENANCE.txt NOT written"; exit 1; }
NPRE=$(ls "$T/logs/preflight_${TAG}" | wc -l | tr -d ' ')
echo "  all identical: the outdir's $(ls "$SRC" | wc -l | tr -d ' ') files, $NLOG logs (task logs, exit, wave, port targets), $NPRE preflight files, launch.{sh,out}, port targets"

echo "== 4. RUN_PROVENANCE.txt"
N14=$(diff -rq "$T/data-raw/downloads/nuclear14c" "$R/data-raw/downloads/nuclear14c" >/dev/null 2>&1 && echo "diff -rq clean" || echo "diff -rq NOT clean")
START=$(grep -E "^objective #16 start" "$LOUT" | sed -E 's/^objective #16 start ([^ ]+) at .*/\1/')
FIN=$(echo "$END" | sed -E 's/^objective #16 end ([^ ]+) rc .*/\1/'); RC=$(echo "$END" | sed -E 's/.* rc ([0-9]+)$/\1/')
RECIPE=$(grep -E "^WALL_MIN" "$WAVE" | sed -E 's/ +mode .*//; s/  +/ /g')
cat > "$DST/RUN_PROVENANCE.txt" <<EOF
FROZEN_FROM_COMMIT $(git -C "$T" rev-parse --short HEAD); worktree $T (data-raw nuclear14c copied in, $N14 against the repo's; port targets regenerated there under this pin set = port_targets_${LAB}.csv here, cmp-identical to the tree's calibration/torch/port_targets.csv; their log logs/port_targets_${TAG}.log); Mac 8-parallel (CCX_MAC_NPAR=8), ${RECIPE}; label ${LAB}, seas_ml 1, spread 1.0452, PINS ${PINS} (npp_tsens PINNED at 0: OBJECTIVE #16, P4, Marcus 2026-10-05 "p4"; the reference-set branch of CHANGELOG 10-05 e); launched ${START}, finished ${FIN} rc ${RC}; $((NEX - NBAD))/${NEX} exit 0 (logs/ccx_multistart_mac_${TAG}_exit.txt); ${NS} start files + ${NC} checkpoints; launch script logs/launch.sh, chain log logs/launch.out; copied into the repo $(date '+%Y-%m-%d') byte-identical (diff -rq on the outdir and the preflight folder, cmp on the ${NLOG} logs, launch.{sh,out} and the port targets) by ~/ccx_frozen/20261005f_obj16_land.sh. CHANGELOG 10-05 (e)/(f) launch; the landing is the entry that cites this file.
EOF
cat "$DST/RUN_PROVENANCE.txt"
echo "== DONE. Next (handoff §5 step 3): CCX_MS_OUTDIR=\"$DST\" Rscript calibration/collect_dispersed_multistart.R | tee \"$DST/collect_$(date +%Y%m%d).log\""
