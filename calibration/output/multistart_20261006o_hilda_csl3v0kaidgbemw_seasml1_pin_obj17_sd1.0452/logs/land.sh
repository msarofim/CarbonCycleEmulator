#!/bin/bash
# LAND OBJECTIVE #17's STAGE-2 REFIT: handoff notes/handoff_2026-10-06d_obj17_running.md (CHANGELOG 2026-10-06 o).
# Written 2026-10-06 while the refit ran, on #16's landing script (its outdir's logs/land.sh).
#
# What it does, in order:
#   - VERIFIES the run finished: the chain's end line, NO work process left, and 24 exit codes.
#   - COPIES into the repo: the outdir (start + ckpt files), the task logs, the exit file, the wave log, the preflight
#     folder, the port-target log, the pin string, the launch script and chain log (as logs/launch.{sh,out}), and the
#     port targets.
#   - CMPs every copied file.
#   - Only then writes RUN_PROVENANCE.txt, from facts it reads.
# What it does NOT do: collect, promote, commit, or delete anything. Those stay separate, read steps.
# It REFUSES to overwrite an existing repo outdir, so a failed run leaves nothing half-written that it would reuse.
# Usage: bash ~/ccx_frozen/20261006o_obj17_land.sh
set -euo pipefail
T="$HOME/ccx_frozen/20261006x_obj17"; TAG=20261006o; LAB=hilda_csl3v0kaidgbemw; NSTART=24
R="$HOME/Documents/2026/CodeProjects/CarbonCycleEmulator"
NAME="multistart_${TAG}_${LAB}_seasml1_pin_obj17_sd1.0452"     # the launch script's own construction (CCX_MS_OUTDIR)
SRC="$T/calibration/output/$NAME"; DST="$R/calibration/output/$NAME"
LOUT="$HOME/ccx_frozen/20261006o_obj17_launch.out"; LSH="$HOME/ccx_frozen/20261006o_obj17_launch.sh"
EX="$T/logs/ccx_multistart_mac_${TAG}_exit.txt"; WAVE="$T/logs/wave_${TAG}.log"; PINF="$T/logs/pins_${TAG}.txt"

echo "== 1. FINISHED?"
END=$(grep -E "^objective #17 end .* rc [0-9]+$" "$LOUT" || true)
[ -n "$END" ] || { echo "NOT FINISHED: no end line in $LOUT"; exit 1; }
echo "  $END"
# the WORK processes, not the launcher; the [t] keeps a wrapper shell quoting this line from matching itself
# (memory pgrep_wait_loop_matches_itself)
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
cp -p "$T"/logs/ccx_multistart_mac_${TAG}_[0-9][0-9][0-9].out "$EX" "$WAVE" "$T/logs/port_targets_${TAG}.log" "$PINF" "$DST/logs/"
cp -pR "$T/logs/preflight_${TAG}" "$DST/logs/"
cp -p "$LSH" "$DST/logs/launch.sh"; cp -p "$LOUT" "$DST/logs/launch.out"
cp -p "$T/calibration/torch/port_targets.csv" "$DST/port_targets_${LAB}.csv"
cp -p "$0" "$DST/logs/land.sh"

echo "== 3. VERIFY byte-identity"
FAIL=0
d=$(diff -rq "$SRC" "$DST" -x logs -x "port_targets_${LAB}.csv" || true); [ -z "$d" ] || { echo "$d"; FAIL=1; }
d=$(diff -rq "$T/logs/preflight_${TAG}" "$DST/logs/preflight_${TAG}" || true); [ -z "$d" ] || { echo "$d"; FAIL=1; }
NLOG=0
for f in "$T"/logs/ccx_multistart_mac_${TAG}_[0-9][0-9][0-9].out "$EX" "$WAVE" "$T/logs/port_targets_${TAG}.log" "$PINF"; do
  cmp -s "$f" "$DST/logs/$(basename "$f")" || { echo "MISMATCH $f"; FAIL=1; }; NLOG=$((NLOG + 1)); done
cmp -s "$LSH" "$DST/logs/launch.sh" || { echo "MISMATCH launch.sh"; FAIL=1; }
cmp -s "$LOUT" "$DST/logs/launch.out" || { echo "MISMATCH launch.out"; FAIL=1; }
cmp -s "$T/calibration/torch/port_targets.csv" "$DST/port_targets_${LAB}.csv" || { echo "MISMATCH port targets"; FAIL=1; }
cmp -s "$0" "$DST/logs/land.sh" || { echo "MISMATCH land.sh"; FAIL=1; }
[ "$FAIL" -eq 0 ] || { echo "VERIFICATION FAILED: the copy is NOT byte-identical; RUN_PROVENANCE.txt NOT written"; exit 1; }
NPRE=$(ls "$T/logs/preflight_${TAG}" | wc -l | tr -d ' ')
echo "  all identical: the outdir's $(ls "$SRC" | wc -l | tr -d ' ') files, $NLOG logs (task logs, exit, wave, port targets, pins), $NPRE preflight files, launch.{sh,out}, port targets"

echo "== 4. RUN_PROVENANCE.txt"
START=$(grep -E "^objective #17 start" "$LOUT" | sed -E 's/^objective #17 start ([^ ]+) at .*/\1/')
FIN=$(echo "$END" | sed -E 's/^objective #17 end ([^ ]+) rc .*/\1/'); RC=$(echo "$END" | sed -E 's/.* rc ([0-9]+)$/\1/')
RECIPE=$(grep -E "^BUDGET" "$WAVE" | sed -E 's/ +mode .*//; s/  +/ /g')
cat > "$DST/RUN_PROVENANCE.txt" <<EOF
FROZEN_FROM_COMMIT $(git -C "$T" rev-parse --short HEAD); worktree $T (the git-ignored data-raw/downloads entries SYMLINKED to the repo's; 14/14 run-time inputs; port targets regenerated there under this pin set = port_targets_${LAB}.csv here, cmp-identical to the tree's calibration/torch/port_targets.csv; their log logs/port_targets_${TAG}.log); Mac 8-parallel (CCX_MAC_NPAR=8), ${RECIPE}; label ${LAB} (OBJECTIVE #17, the interannual cut: the low-pass gcb_land_sink row, gcb_ocean_enso_slope moved to the module), seas_ml 1, spread 1.0452, PINS = R/paths.R CCX_MODE_OBJ17_PINS: #16's ten + the module's four at stage 1's values (calibration/output/iav_module_20261006_hilda33p.rds; the launch string is logs/pins_${TAG}.txt); the reference-set branch of CHANGELOG 10-06 (o); outdir NAMED (the driver's default would carry the 14 pins, 379 bytes); launched ${START}, finished ${FIN} rc ${RC}; $((NEX - NBAD))/${NEX} exit 0 (logs/ccx_multistart_mac_${TAG}_exit.txt); ${NS} start files + ${NC} checkpoints; launch script logs/launch.sh, chain log logs/launch.out; copied into the repo $(date '+%Y-%m-%d') byte-identical (diff -rq on the outdir and the preflight folder, cmp on the ${NLOG} logs, launch.{sh,out} and the port targets) by ~/ccx_frozen/20261006o_obj17_land.sh. CHANGELOG 10-06 (o) launch; the landing is the entry that cites this file.
EOF
cat "$DST/RUN_PROVENANCE.txt"
echo "== DONE. Next: CCX_MS_OUTDIR=\"$DST\" Rscript calibration/collect_dispersed_multistart.R | tee \"$DST/collect_$(date +%Y%m%d).log\""
