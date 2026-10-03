#!/bin/bash
# resume_017.sh -- is the lag arm's start 017 (OUT OF TIME at -1319.64, still gaining) a STUCK start or a
# second basin? Continue it from its OWN checkpoint with the SAME driver, code (the frozen lag tree at
# 3fc5dca) and settings, with a fresh wall budget, into a NEW directory -- the arm's own outdir is never
# touched. nice'd so it yields to the control arm's 8 tasks. Run only after the lag arm's chain has ended.
set -euo pipefail
T="$HOME/ccx_frozen/20261002ee_obj15_lag"
TAIL="_seasml1_pin_ent_seas_amp_SH=0_w_eq=27_gamma_eq=1_pump_export=9.08_w_vent=0_gamma_vent=0_w_thc=0_gamma_enso_ocn_NH=0_gamma_enso_ocn_SH=0_sd1.0452_sdby_npp_tsens=0.0291"
ORIG="$T/calibration/output/multistart_20261002ee_hilda_csl3v0kaidgbe${TAIL}"
RD="$T/calibration/output/resume017_20261003_hilda_csl3v0kaidgbe${TAIL}"
grep -q "arm hilda_csl3v0kaidgbe end" "$HOME/ccx_frozen/20261002ee_obj15_launch.out" || { echo "the lag arm has not ended"; exit 1; }
[ ! -e "$RD" ] || { echo "REFUSING: $RD exists"; exit 1; }
mkdir -p "$RD"
cp -p "$ORIG/start_017_ckpt.rds" "$RD/"
cmp "$ORIG/start_017_ckpt.rds" "$RD/start_017_ckpt.rds"
cd "$T"
export CCX_MS_STRUCT=hilda_csl3v0kaidgbe CCX_MS_SEAS_ML=1 CCX_MS_SPREAD=1.0452 CCX_MS_TAG=20261003r017 CCX_MAC_NPAR=1 CCX_MAC_IDS=17
export CCX_MS_PIN="ent_seas_amp_SH=0,w_eq=27,gamma_eq=1,pump_export=9.08,w_vent=0,gamma_vent=0,w_thc=0,gamma_enso_ocn_NH=0,gamma_enso_ocn_SH=0"
export CCX_MS_OUTDIR="$RD" CCX_MS_WALL_MIN=300
unset CCX_MS_PREFLIGHT CCX_MS_ID
echo "resume 017 start $(date '+%Y-%m-%dT%H:%M:%S%z')"
nice -n 10 bash calibration/mac/run_multistart_mac.sh > logs/wave_20261003r017.log 2>&1
echo "resume 017 end $(date '+%Y-%m-%dT%H:%M:%S%z') rc $?"
