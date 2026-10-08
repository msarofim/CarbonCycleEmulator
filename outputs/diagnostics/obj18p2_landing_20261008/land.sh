#!/bin/bash
# LAND #18 PASS 2 (CHANGELOG 2026-10-08 d): #18's land.sh with the tree, tag, start count and outdir changed, and the preflight
# SUMMARY log copied too (the gap #18's land.sh left; CHANGELOG 10-08 b). VERIFIES the run finished (end line, no work
# process, 2 exit codes); COPIES outdir, task logs, exit file, wave log, preflight logs (both rounds), port-target log, pins,
# launch.{sh,out}, port targets; CMPs every file; then writes RUN_PROVENANCE.txt. Refuses an existing repo outdir.
set -euo pipefail
T="$HOME/ccx_frozen/20261008d_obj18p2"; TAG=20261008d; LAB=hilda_csl3v0kaidgbemwt; NSTART=2
R="$HOME/Documents/2026/CodeProjects/CarbonCycleEmulator"
NAME="multistart_${TAG}_${LAB}_seasml1_pin_obj18p2_sd1.0452"
SRC="$T/calibration/output/$NAME"; DST="$R/calibration/output/$NAME"
LOUT="$HOME/ccx_frozen/20261008d_obj18p2_launch.out"; LSH="$HOME/ccx_frozen/20261008d_obj18p2_launch.sh"
EX="$T/logs/ccx_multistart_mac_${TAG}_exit.txt"; WAVE="$T/logs/wave_${TAG}.log"; PINF="$T/logs/pins_${TAG}.txt"
echo "== 1. FINISHED?"
END=$(grep -E "^#18 pass 2 end .* rc [0-9]+$" "$LOUT" || true); [ -n "$END" ] || { echo "NOT FINISHED: no end line in $LOUT"; exit 1; }
echo "  $END"
NWORK=$( (pgrep -f "R.*--file=calibration/run_dispersed_multistar[t].R" || true) | wc -l | tr -d ' ')
[ "$NWORK" -eq 0 ] || { echo "WORK PROCESSES STILL RUNNING: $NWORK"; exit 1; }
NEX=$(wc -l < "$EX" | tr -d ' '); NBAD=$(awk '$2 != 0' "$EX" | wc -l | tr -d ' ')
echo "  exit file: $NEX lines, $NBAD non-zero"; [ "$NEX" -eq "$NSTART" ] || { echo "EXPECTED $NSTART exit codes"; exit 1; }
echo "== 2. COPY into $DST"
[ ! -e "$DST" ] || { echo "REFUSED: $DST already exists (inspect it; never overwrite)"; exit 1; }
mkdir -p "$DST/logs/preflight"
cp -pR "$SRC"/. "$DST"/
cp -p "$T"/logs/ccx_multistart_mac_${TAG}_[0-9][0-9][0-9].out "$EX" "$WAVE" "$T/logs/port_targets_${TAG}.log" "$PINF" "$DST/logs/"
cp -p "$T"/logs/ccx_multistart_mac_${TAG}pf_* "$T/logs/preflight_${TAG}.log" "$DST/logs/preflight/"
cp -pR "$T/logs/preflight_v1" "$DST/logs/preflight/"
cp -p "$LSH" "$DST/logs/launch.sh"; cp -p "$LOUT" "$DST/logs/launch.out"
cp -p "$T/calibration/torch/port_targets.csv" "$DST/port_targets_${LAB}.csv"; cp -p "$0" "$DST/logs/land.sh"
echo "== 3. VERIFY byte-identity"
FAIL=0
d=$(diff -rq "$SRC" "$DST" -x logs -x "port_targets_${LAB}.csv" || true); [ -z "$d" ] || { echo "$d"; FAIL=1; }
d=$(diff -rq "$T/logs/preflight_v1" "$DST/logs/preflight/preflight_v1" || true); [ -z "$d" ] || { echo "$d"; FAIL=1; }
for f in "$T"/logs/ccx_multistart_mac_${TAG}_[0-9][0-9][0-9].out "$EX" "$WAVE" "$T/logs/port_targets_${TAG}.log" "$PINF"; do
  cmp -s "$f" "$DST/logs/$(basename "$f")" || { echo "MISMATCH $f"; FAIL=1; }; done
for f in "$T"/logs/ccx_multistart_mac_${TAG}pf_* "$T/logs/preflight_${TAG}.log"; do
  cmp -s "$f" "$DST/logs/preflight/$(basename "$f")" || { echo "MISMATCH $f"; FAIL=1; }; done
cmp -s "$LSH" "$DST/logs/launch.sh" && cmp -s "$LOUT" "$DST/logs/launch.out" || { echo "MISMATCH launch.{sh,out}"; FAIL=1; }
cmp -s "$T/calibration/torch/port_targets.csv" "$DST/port_targets_${LAB}.csv" || { echo "MISMATCH port targets"; FAIL=1; }
cmp -s "$0" "$DST/logs/land.sh" || { echo "MISMATCH land.sh"; FAIL=1; }
[ "$FAIL" -eq 0 ] || { echo "VERIFICATION FAILED: RUN_PROVENANCE.txt NOT written"; exit 1; }
echo "  all identical"
echo "== 4. RUN_PROVENANCE.txt"
cat > "$DST/RUN_PROVENANCE.txt" <<PROV
FROZEN_FROM_COMMIT $(git -C "$T" rev-parse --short HEAD); worktree $T (downloads APFS-cloned or symlinked from the repo's; port targets regenerated there under this pin set)
RUN $(grep -E "^#18 pass 2 start" "$LOUT") -> $END
RECIPE $(grep -E "^BUDGET" "$WAVE" | sed -E 's/ +mode .*//; s/  +/ /g')
PINS $(cat "$PINF")
EXITS $(sort -n "$EX" | tr '\n' ' ')
RULING Marcus 2026-10-08, verbatim: "Basin 1, run the second pass, adopt if it passes" (CHANGELOG 2026-10-08 d)
LANDED $(date '+%Y-%m-%dT%H:%M:%S%z') by $0
PROV
cat "$DST/RUN_PROVENANCE.txt"
