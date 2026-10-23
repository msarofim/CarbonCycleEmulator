#!/bin/bash
# preflight one tree: $1 tree, $2 tag, $3 ids, $4 file-starts ('' = none)
T="$1"; TAG="$2"; IDS="$3"; FS="$4"; LAB=hilda_csl3v0kaidgbemwtcf
S=/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/82a62d40-e53e-421b-ac3e-524a6770cf67/scratchpad
cd "$T" || exit 1
export CCX_MS_STRUCT=$LAB CCX_MS_SEAS_ML=1 CCX_MS_SPREAD=1.0452 CCX_MS_PIN="$(cat $S/pins_flask.txt)" CCX_MS_TAG=$TAG
export CCX_MS_BUDGET_MIN=300 CCX_MS_CLOCK=cpu CCX_MS_RESTARTS=3 CCX_MS_CYCLES=6 CCX_MS_MAXIT=6000 CCX_MS_PREFLIGHT=1
export CCX_MAC_IDS="$IDS" CCX_MAC_NPAR=4
export CCX_MS_OUTDIR="$T/calibration/output/multistart_${TAG}_${LAB}_seasml1_pin_flask_sd1.0452_prior_bomb_share_NH_seas_T_lag"
if [ -n "$FS" ]; then export CCX_MS_FILE_STARTS="$FS"; else unset CCX_MS_FILE_STARTS; fi
bash calibration/mac/run_multistart_mac.sh > "logs/preflight_${TAG}.log" 2>&1
echo "$TAG rc $?"; sort -n "logs/ccx_multistart_mac_${TAG}_exit.txt" | tr '\n' ' '; echo
