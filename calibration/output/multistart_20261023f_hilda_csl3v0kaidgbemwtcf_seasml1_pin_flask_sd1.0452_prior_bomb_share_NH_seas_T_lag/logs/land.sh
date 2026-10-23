#!/bin/bash
# LAND THE FLASK REFIT (CHANGELOG 2026-10-23 f; label hilda_csl3v0kaidgbemwtcf). The WTC refit's land script
# (~/ccx_frozen/20261012ff_wtc_land.sh, committed in its wave's logs/land.sh) with the tree, tag, label, outdir, the start
# count (3), the launch script's start/end lines and the provenance text changed, and the file starts copied.
#
# What it does, in order:
#   - VERIFIES the run finished: the launch script's end line, NO work process left, and 3 exit codes.
#   - COPIES into the repo: the outdir (start + ckpt files), the task logs, the exit file, the wave log, the preflight
#     folder and summary, the port-target log, the pin string, the launch script and its log (as logs/launch.{sh,out}),
#     the port targets and the file starts.
#   - CMPs every copied file.
#   - Only then writes RUN_PROVENANCE.txt, from facts it reads.
# What it does NOT do: collect, promote, commit, or delete anything. Those stay separate, read steps.
# It REFUSES to overwrite an existing repo outdir, so a failed run leaves nothing half-written that it would reuse.
# Usage: bash ~/ccx_frozen/20261023f_flask_land.sh (the chain, ~/ccx_frozen/20261023f_flask_chain.sh land, runs it first)
set -euo pipefail
T="$HOME/ccx_frozen/20261023_flask"; TAG=20261023f; LAB=hilda_csl3v0kaidgbemwtcf; NSTART=3
R="$HOME/Documents/2026/CodeProjects/CarbonCycleEmulator"
NAME="multistart_${TAG}_${LAB}_seasml1_pin_flask_sd1.0452_prior_bomb_share_NH_seas_T_lag"   # the launch script's CCX_MS_OUTDIR
SRC="$T/calibration/output/$NAME"; DST="$R/calibration/output/$NAME"
LOUT="$HOME/ccx_frozen/20261023f_flask_launch.out"; LSH="$HOME/ccx_frozen/20261023f_flask_launch.sh"
EX="$T/logs/ccx_multistart_mac_${TAG}_exit.txt"; WAVE="$T/logs/wave_${TAG}.log"; PINF="$T/logs/pins_${TAG}.txt"
FSTARTS="$T/calibration/torch/file_starts_${LAB}.rds"

echo "== 1. FINISHED?"
END=$(grep -E "^flask refit end .* rc [0-9]+$" "$LOUT" || true)
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
cp -p "$T"/logs/ccx_multistart_mac_${TAG}_[0-9][0-9][0-9].out "$EX" "$WAVE" "$T/logs/port_targets_${TAG}.log" "$PINF" "$T/logs/preflight_${TAG}.log" "$DST/logs/"
cp -pR "$T/logs/preflight_${TAG}" "$DST/logs/"
cp -p "$LSH" "$DST/logs/launch.sh"; cp -p "$LOUT" "$DST/logs/launch.out"
cp -p "$T/calibration/torch/port_targets.csv" "$DST/port_targets_${LAB}.csv"
cp -p "$FSTARTS" "$DST/file_starts_${LAB}.rds"
cp -p "$0" "$DST/logs/land.sh"

echo "== 3. VERIFY byte-identity"
FAIL=0
d=$(diff -rq "$SRC" "$DST" -x logs -x "port_targets_${LAB}.csv" -x "file_starts_${LAB}.rds" || true); [ -z "$d" ] || { echo "$d"; FAIL=1; }
d=$(diff -rq "$T/logs/preflight_${TAG}" "$DST/logs/preflight_${TAG}" || true); [ -z "$d" ] || { echo "$d"; FAIL=1; }
NLOG=0
for f in "$T"/logs/ccx_multistart_mac_${TAG}_[0-9][0-9][0-9].out "$EX" "$WAVE" "$T/logs/port_targets_${TAG}.log" "$PINF" "$T/logs/preflight_${TAG}.log"; do
  cmp -s "$f" "$DST/logs/$(basename "$f")" || { echo "MISMATCH $f"; FAIL=1; }; NLOG=$((NLOG + 1)); done
cmp -s "$LSH" "$DST/logs/launch.sh" || { echo "MISMATCH launch.sh"; FAIL=1; }
cmp -s "$LOUT" "$DST/logs/launch.out" || { echo "MISMATCH launch.out"; FAIL=1; }
cmp -s "$T/calibration/torch/port_targets.csv" "$DST/port_targets_${LAB}.csv" || { echo "MISMATCH port targets"; FAIL=1; }
cmp -s "$FSTARTS" "$DST/file_starts_${LAB}.rds" || { echo "MISMATCH file starts"; FAIL=1; }
cmp -s "$0" "$DST/logs/land.sh" || { echo "MISMATCH land.sh"; FAIL=1; }
[ "$FAIL" -eq 0 ] || { echo "VERIFICATION FAILED: the copy is NOT byte-identical; RUN_PROVENANCE.txt NOT written"; exit 1; }
NPRE=$(ls "$T/logs/preflight_${TAG}" | wc -l | tr -d ' ')
echo "  all identical: the outdir's $(ls "$SRC" | wc -l | tr -d ' ') files, $NLOG logs (task logs, exit, wave, port targets, pins, preflight summary), $NPRE preflight files, launch.{sh,out}, port targets, file starts"

echo "== 4. RUN_PROVENANCE.txt"
START=$(grep -E "^flask refit start" "$LOUT" | sed -E 's/^flask refit start ([^ ]+) at .*/\1/')
FIN=$(echo "$END" | sed -E 's/^flask refit end ([^ ]+) rc .*/\1/'); RC=$(echo "$END" | sed -E 's/.* rc ([0-9]+)$/\1/')
RECIPE=$(grep -E "^BUDGET" "$WAVE" | sed -E 's/ +mode .*//; s/  +/ /g')
cat > "$DST/RUN_PROVENANCE.txt" <<EOF
FROZEN_FROM_COMMIT $(git -C "$T" rev-parse --short HEAD); worktree $T (the git-ignored data-raw/downloads entries APFS-CLONED from the repo's, diff -rq identical; port targets = port_targets_${LAB}.csv here, cmp-identical to the tree's calibration/torch/port_targets.csv, committed at 7bd37b94 after make_port_targets.R ran in the repo at 6d00fcd8 (log logs/port_targets_${TAG}.log); the incumbent hilda31w evaluates to -1067.5979272958 under the flask label = its stored -1054.4959 in situ - 13.102 (the label alone; test-flask-label.R)); Mac 3-parallel (CCX_MAC_NPAR=3), ${RECIPE}; label ${LAB} (THE FLASK REFIT: every Mauna Loa CO2 row on Scripps flask, CHANGELOG 2026-10-22 g; Marcus 2026-10-22 "Local refit from T8c's point (Recommended)", "Add it as a third (Recommended)", "Carry module, then check (Recommended)"), seas_ml 1, PINS = R/paths.R CCX_MODE_FLASK_PINS = CCX_MODE_OBJ18P2_PINS (the canonical's: #16's ten + the interannual module's four; the launch string is logs/pins_${TAG}.txt), 31 free names; THREE FIXED STARTS: id 1 = hilda31w under the flask label (the incumbent of ccx_ms_reference_set()'s flask branch, a START), id 6 = T8c's block point (-1052.232908), id 7 = T8f's Newton point (-1050.185317), the last two FILE starts from file_starts_${LAB}.rds (here; built by calibration/make_flask_file_starts.R at 475b30e3), each gated on T8f's value by the driver's FILE-START GATE; no dispersed start; preflight 3/3 LAUNCHABLE (logs/preflight_${TAG}/); outdir NAMED; launched ${START}, finished ${FIN} rc ${RC}; $((NEX - NBAD))/${NEX} exit 0 (logs/ccx_multistart_mac_${TAG}_exit.txt); ${NS} start files + ${NC} checkpoints; launch script logs/launch.sh, its log logs/launch.out; copied into the repo $(date '+%Y-%m-%d') byte-identical (diff -rq on the outdir and the preflight folder, cmp on the ${NLOG} logs, launch.{sh,out}, the port targets and the file starts) by ~/ccx_frozen/20261023f_flask_land.sh. CHANGELOG 2026-10-23 (f) launch; the landing is the entry that cites this file.
EOF
cat "$DST/RUN_PROVENANCE.txt"
echo "== DONE. Next: CCX_MS_OUTDIR=\"$DST\" Rscript calibration/collect_dispersed_multistart.R | tee \"$DST/collect_$(date +%Y%m%d).log\""
