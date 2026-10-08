#!/bin/bash
# OBJECTIVE #18, PASS 2 (Marcus 2026-10-08, verbatim: "Basin 1, run the second pass, adopt if it passes"). #18's label
# (hilda_csl3v0kaidgbemwt), #16's ten pins + the module at the ONE-PASS CHECK's values at basin 1 (R/paths.R
# CCX_MODE_OBJ18P2_PINS, bit for bit CCX_MODE_OBJ18P2_MODULE_FILE). WARM REFITS from BOTH landed basins: id 1 = hilda29a0
# (basin 1), id 2 = hilda29a6 (basin 2), each seeded at the new pins. From the frozen worktree at 3ab4793, port targets
# regenerated there under this pin set (logs/port_targets_20261008d.log: incumbent -1166.9498, new basin -1167.9842);
# preflight 2/2 LAUNCHABLE, ports VERIFIED (logs/preflight_20261008d*). #18's recipe on the CPU clock: BUDGET 300 CPU-min,
# 3 restarts x 6 cycles x 6000 maxit, spread 1.0452 (unused: no dispersed id). Torch verdict, said out loud: Mac -- two
# warm tasks, ~0.22 CPU-s/eval, an idle laptop. CHANGELOG 2026-10-08 (d).
set -u
T="$HOME/ccx_frozen/20261008d_obj18p2"; LAB=hilda_csl3v0kaidgbemwt; TAG=20261008d
cd "$T" || exit 1
unset CCX_MS_PREFLIGHT CCX_MS_ID
export CCX_MS_STRUCT="$LAB" CCX_MS_SEAS_ML=1 CCX_MS_SPREAD=1.0452 CCX_MS_PIN="$(cat "$T/logs/pins_$TAG.txt")" CCX_MS_TAG=$TAG
export CCX_MAC_NPAR=2 CCX_MAC_IDS="1 2"
export CCX_MS_BUDGET_MIN=300 CCX_MS_CLOCK=cpu CCX_MS_RESTARTS=3 CCX_MS_CYCLES=6 CCX_MS_MAXIT=6000
export CCX_MS_OUTDIR="$T/calibration/output/multistart_${TAG}_${LAB}_seasml1_pin_obj18p2_sd1.0452"
echo "#18 pass 2 start $(date '+%Y-%m-%dT%H:%M:%S%z') at $(git -C "$T" rev-parse --short HEAD)"
bash calibration/mac/run_multistart_mac.sh > "logs/wave_$TAG.log" 2>&1
rc=$?
echo "#18 pass 2 end $(date '+%Y-%m-%dT%H:%M:%S%z') rc $rc"
