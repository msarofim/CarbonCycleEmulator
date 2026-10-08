#!/bin/bash
# THE ARMED LANDING OF OBJECTIVE #18 (CHANGELOG 2026-10-07 k). Waits on the wave's LAUNCHER PID -- never a pgrep loop, which
# matches itself (memory pgrep_wait_loop_matches_itself) -- then runs the landing chain ONCE, in land mode, holding the Mac
# awake for it (the launcher's own caffeinate ends with the launcher; memory mac_sleep_eats_wall_budget).
# The chain verifies the end line, that no work process is left and the 24 exit codes before it copies anything, and it
# refuses to overwrite an existing outdir: if the run did not finish cleanly it stops at its first step, harmlessly.
# ⛔ It ADOPTS nothing and COMMITS nothing. Its log: ~/ccx_frozen/20261007i_obj18_land_armed.out; the chain's step logs:
# outputs/diagnostics/obj18_landing_<date>/ in the repo.
# Usage: nohup bash ~/ccx_frozen/20261007i_obj18_land_armed.sh > ~/ccx_frozen/20261007i_obj18_land_armed.out 2>&1 &
LAUNCHER=51496                                      # ~/ccx_frozen/20261007i_obj18_launch.pid
[ "$(cat "$HOME/ccx_frozen/20261007i_obj18_launch.pid")" = "$LAUNCHER" ] || { echo "the launch pid file does not name $LAUNCHER"; exit 1; }
echo "armed $(date '+%Y-%m-%dT%H:%M:%S%z'): waiting on launcher $LAUNCHER"
while kill -0 "$LAUNCHER" 2>/dev/null; do sleep 60; done
echo "launcher $LAUNCHER gone $(date '+%Y-%m-%dT%H:%M:%S%z'); its end line: $(tail -1 "$HOME/ccx_frozen/20261007i_obj18_launch.out")"
caffeinate -i -s bash "$HOME/ccx_frozen/20261007i_obj18_chain.sh" land
rc=$?
echo "armed landing: the chain ended rc $rc $(date '+%Y-%m-%dT%H:%M:%S%z')"
