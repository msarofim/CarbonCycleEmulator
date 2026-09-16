#!/bin/bash
# =====================================================================
# run_multistart_mac.sh -- the dispersed multistart ON THE MAC, N starts at
# once, from a FROZEN TREE. The Mac-local twin of calibration/torch/multistart.sbatch.
#
# WHY IT EXISTS (2026-09-16 g): Torch fairshare was 0.21 and the machine had to be
# kept free for higher-priority FrEDI work, so the hygiene-batch refit runs here.
# The Mac evaluates the objective at 0.17-0.19 s/eval single-threaded against
# 0.59-1.08 on a Torch node, so per task the Mac is 3-5x faster; the price is
# that only ~8-12 run at once instead of 24.
#
# ⛔ RUN IT FROM A FROZEN COPY, NEVER THE WORKING TREE. R sources are read at
# start-up and the driver checkpoints/resumes for hours; an edit under a live
# task is the never_edit_a_running_script incident. The Torch bundle IS the frozen
# copy: `bash calibration/torch/make_bundle.sh` then
#     mkdir -p ~/ccx_frozen/<tag> && tar xzf /tmp/ccx_torch_bundle.tar.gz -C ~/ccx_frozen/<tag>
# and run THIS script's copy inside that tree. Results land in the frozen tree's
# calibration/output/<outdir>; copy the outdir back into the repo before collecting.
#
# ENV -- identical names and defaults to the sbatch, so a run here is
# like-for-like with a Torch run (same WALL/RESTARTS/CYCLES/MAXIT design, same
# outdir label, same port gate):
#   CCX_MS_STRUCT (required), CCX_MS_SEAS_ML (1), CCX_MS_SPREAD (1.0452),
#   CCX_MS_PUMP_FIELD (solved), CCX_MS_PIN (''), CCX_MS_TAG (today),
#   CCX_MS_OUTDIR (derived), CCX_MS_WALL_MIN (300), CCX_MS_RESTARTS (3),
#   CCX_MS_CYCLES (6), CCX_MS_MAXIT (6000), CCX_MS_PREFLIGHT ('' | 1)
# Mac-only:
#   CCX_MAC_IDS   the id list, as a space-separated string   (default "0 1 ... 23")
#   CCX_MAC_NPAR  how many run at once                        (default 8)
#
# ⚠ THE DATE IS PINNED ONCE, HERE, in CCX_MS_TAG. The driver's own default outdir
# derives from Sys.Date() PER TASK, so a wave that crosses midnight would split
# across two directories with nothing to say so. Every task gets the one OUTDIR
# computed below.
#
# BLAS threads pinned to 1 (the sbatch does the same): N single-threaded tasks,
# never N x 10 threads fighting for 10 cores.
#
# caffeinate -i -s: the Mac must not idle-sleep or lid-sleep under a 6-15 h run.
# Keep it on AC power -- `-s` only holds off sleep while plugged in.
#
# Logs: logs/ccx_multistart_mac_<tag>_<id>.out (one per task, the same lines the
# sbatch's %x_%A_%a.out would carry). Exit codes: logs/ccx_multistart_mac_<tag>_exit.txt.
# =====================================================================
set -euo pipefail
CCX_PROJ_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
readonly CCX_PROJ_DIR
cd "$CCX_PROJ_DIR"
mkdir -p logs calibration/output

if [ -z "${CCX_MS_STRUCT:-}" ]; then
  echo "run_multistart_mac.sh: CCX_MS_STRUCT is NOT SET (hilda | hilda_eq | hilda_tr | hilda_c). State the objective's label on the command line." >&2
  exit 1
fi
export CCX_MS_STRUCT
unset CCX_MS_ID
export CCX_MS_SEAS_ML="${CCX_MS_SEAS_ML:-1}"
export CCX_MS_SPREAD="${CCX_MS_SPREAD:-1.0452}"
export CCX_MS_PUMP_FIELD="${CCX_MS_PUMP_FIELD:-solved}"
FIELD_LABEL=""; if [ "$CCX_MS_PUMP_FIELD" = "martin" ]; then FIELD_LABEL="_martin"; fi
export CCX_MS_PIN="${CCX_MS_PIN:-}"
PIN_LABEL=""; if [ -n "$CCX_MS_PIN" ]; then PIN_LABEL="_pin_$(echo "$CCX_MS_PIN" | tr ',' '_')"; fi
export CCX_MS_TAG="${CCX_MS_TAG:-$(date +%Y%m%d)}"
export CCX_MS_OUTDIR="${CCX_MS_OUTDIR:-$CCX_PROJ_DIR/calibration/output/multistart_${CCX_MS_TAG}_${CCX_MS_STRUCT}_seasml${CCX_MS_SEAS_ML}${FIELD_LABEL}${PIN_LABEL}_sd${CCX_MS_SPREAD}}"
export CCX_MS_PREFLIGHT="${CCX_MS_PREFLIGHT:-}"

case "$CCX_MS_OUTDIR" in
  "$CCX_PROJ_DIR"/*) : ;;
  *) echo "FATAL: CCX_MS_OUTDIR is OUTSIDE the frozen tree: $CCX_MS_OUTDIR (the 2026-09-01 PROJ clobber)." >&2; exit 1 ;;
esac

export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1
export CCX_MS_WALL_MIN="${CCX_MS_WALL_MIN:-300}"
export CCX_MS_RESTARTS="${CCX_MS_RESTARTS:-3}"
export CCX_MS_CYCLES="${CCX_MS_CYCLES:-6}"
export CCX_MS_MAXIT="${CCX_MS_MAXIT:-6000}"

IDS="${CCX_MAC_IDS:-$(seq -s ' ' 0 23)}"
NPAR="${CCX_MAC_NPAR:-8}"
MODE_LABEL="wave"; if [ -n "$CCX_MS_PREFLIGHT" ]; then MODE_LABEL="PREFLIGHT"; fi
LOGSTEM="logs/ccx_multistart_mac_${CCX_MS_TAG}"
EXITS="${LOGSTEM}_exit.txt"; : > "$EXITS"

echo "CCX_PROJ_DIR  $CCX_PROJ_DIR"
echo "CCX_MS_OUTDIR $CCX_MS_OUTDIR"
echo "CCX_MS_STRUCT $CCX_MS_STRUCT   CCX_MS_SEAS_ML $CCX_MS_SEAS_ML   CCX_MS_PUMP_FIELD $CCX_MS_PUMP_FIELD   CCX_MS_SPREAD $CCX_MS_SPREAD   CCX_MS_PIN '${CCX_MS_PIN}'"
echo "WALL_MIN $CCX_MS_WALL_MIN  RESTARTS $CCX_MS_RESTARTS  CYCLES $CCX_MS_CYCLES  MAXIT $CCX_MS_MAXIT   mode $MODE_LABEL   ids [$IDS]   $NPAR at once"
echo "host $(hostname)  started $(date "+%Y-%m-%dT%H:%M:%S%z")  uptime: $(uptime)"
echo "already running at launch (>20% CPU), so a slow eval rate is read as CONTENTION first:"
ps -Ao pcpu,etime,command -r | awk 'NR>1 && $1 > 20 {print "   " substr($0,1,160)}' | head -12

# one task per id; xargs -P is the array's %N. The exit code of every task is
# recorded by name -- xargs's own exit says only "something failed".
run_one() {
  id="$1"
  log="${LOGSTEM}_$(printf '%03d' "$id").out"
  # a SUBSHELL, not a brace group: `exit` in a brace group leaves run_one before
  # the exit code is recorded (the 09-16 preflight ran 24/24 and recorded 0/24).
  ( echo "task $id  $(date "+%Y-%m-%dT%H:%M:%S%z")"; CCX_MS_ID="$id" Rscript --vanilla calibration/run_dispersed_multistart.R; rc=$?; echo "done $(date "+%Y-%m-%dT%H:%M:%S%z") exit $rc"; exit $rc ) > "$log" 2>&1
  rc=$?
  echo "$id $rc" >> "$EXITS"
  return 0
}
export -f run_one
export LOGSTEM EXITS

# shellcheck disable=SC2086
printf '%s\n' $IDS | caffeinate -i -s xargs -P "$NPAR" -I{} bash -c 'run_one {}'

echo "all tasks finished $(date "+%Y-%m-%dT%H:%M:%S%z")"
echo "exit codes (id rc):"; sort -n "$EXITS"
nfail=$(awk '$2 != 0' "$EXITS" | wc -l | tr -d ' ')
echo "non-zero exits: $nfail"
