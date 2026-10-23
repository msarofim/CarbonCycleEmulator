#!/bin/bash
# THE ARMED DRY RUN + LANDING OF THE FLASK REFIT (CHANGELOG 2026-10-23 f; the WTC refit's armed script,
# ~/ccx_frozen/20261012ff_wtc_armed.sh, with the tree, tag, label and scripts changed).
#   1. Once the wave's FIRST start file is at least 2 min old (a FILE condition, polled every 2 min -- never a pgrep loop,
#      which matches itself: memory pgrep_wait_loop_matches_itself), run the landing chain ONCE in dryrun mode (its own
#      detached worktree at the repo's HEAD; scratch copies of the finished starts). Skipped if the launcher is already gone.
#   2. Then wait on the wave's LAUNCHER PID and run the chain ONCE in land mode, holding the Mac awake for it (the
#      launcher's own caffeinate ends with the launcher; memory mac_sleep_eats_wall_budget).
# The land chain verifies the end line, that no work process is left and the 3 exit codes before it copies anything, and
# it refuses to overwrite an existing outdir: if the run did not finish cleanly it stops at its first step, harmlessly.
# A dry-run failure does NOT block the landing: the land stops at the same step, after the copy, and is resumed by hand.
# ⛔ It ADOPTS nothing and COMMITS nothing. Its log: ~/ccx_frozen/20261023f_flask_armed.out.
# Usage: nohup bash ~/ccx_frozen/20261023f_flask_armed.sh > ~/ccx_frozen/20261023f_flask_armed.out 2>&1 &
set -u
LAUNCHER="$(cat "$HOME/ccx_frozen/20261023f_flask_launch.pid")"
RUNT="$HOME/ccx_frozen/20261023_flask"; TAG=20261023f; LAB=hilda_csl3v0kaidgbemwtcf
OUT="$RUNT/calibration/output/multistart_${TAG}_${LAB}_seasml1_pin_flask_sd1.0452_prior_bomb_share_NH_seas_T_lag"
CHAIN="$HOME/ccx_frozen/20261023f_flask_chain.sh"
[[ "$LAUNCHER" =~ ^[0-9]+$ ]] || { echo "the launch pid file holds '$LAUNCHER', not a pid"; exit 1; }
echo "armed $(date '+%Y-%m-%dT%H:%M:%S%z'): launcher $LAUNCHER; stage 1 waits for a finished start under $OUT"
until [ -n "$(find "$OUT" -maxdepth 1 -name 'start_[0-9][0-9][0-9].rds' -mmin +2 2>/dev/null | head -1)" ]; do
  kill -0 "$LAUNCHER" 2>/dev/null || break
  sleep 120
done
if kill -0 "$LAUNCHER" 2>/dev/null; then
  echo "stage 1 $(date '+%Y-%m-%dT%H:%M:%S%z'): finished starts: $(find "$OUT" -maxdepth 1 -name 'start_[0-9][0-9][0-9].rds' -mmin +2 | wc -l | tr -d ' ')"
  caffeinate -i -s bash "$CHAIN" dryrun
  echo "stage 1: the dry-run chain ended rc $? $(date '+%Y-%m-%dT%H:%M:%S%z')"
else
  echo "stage 1 SKIPPED: the launcher was gone before any start finished $(date '+%Y-%m-%dT%H:%M:%S%z')"
fi
echo "stage 2 $(date '+%Y-%m-%dT%H:%M:%S%z'): waiting on launcher $LAUNCHER"
while kill -0 "$LAUNCHER" 2>/dev/null; do sleep 60; done
echo "launcher $LAUNCHER gone $(date '+%Y-%m-%dT%H:%M:%S%z'); its end line: $(tail -1 "$HOME/ccx_frozen/20261023f_flask_launch.out")"
caffeinate -i -s bash "$CHAIN" land
echo "armed landing: the chain ended rc $? $(date '+%Y-%m-%dT%H:%M:%S%z')"
