#!/bin/bash
# OBJECTIVE #18's STAGE-2 REFIT (Marcus 2026-10-07: "Full redesign (Recommended)"; the label "hilda_csl3v0kaidgbemwt
# (Recommended)"; stage 1's base "Basin B (Recommended)"; the incumbent "Register B, seed from it (Recommended)").
# The redesigned cut: #17 (the low-pass land row; the slope row in the module) + the DETRENDED ENSO index + gcb_ocean_sink
# on its low-pass part. #16's ten pins + the module's four at STAGE 1's values under #18 at #17's basin B
# (calibration/fit_iav_module.R @5d34d41 --struct -> CCX_MODE_OBJ18_MODULE_FILE; R/paths.R CCX_MODE_OBJ18_PINS), so 29
# free names. INCUMBENT hilda29w (#17's basin B, registered 10-07 i) seeded at the pins; new basin the seas_ml-0 control.
# From the frozen worktree at c81f285, the git-ignored downloads APFS-cloned (14/14 inputs), port targets regenerated
# there under this pin set (logs/port_targets_20261007i.log; incumbent -1173.0992111 = the pricing's B1s). Preflight 24/24
# LAUNCHABLE, every port VERIFIED (incumbent rel 2.1e-14), 0.351 CPU-s/eval at id 1 (logs/preflight_20261007i/).
# 24 starts, 8 at a time, #17's recipe on the CPU clock: BUDGET 300 CPU-min, 3 restarts x 6 cycles x 6000 maxit, spread
# 1.0452. The outdir is NAMED (the driver's default carries the 14 pins, over macOS's 255-byte limit). Torch verdict,
# said out loud: Mac, overnight, as ruled. Launched under nohup; the Mac launcher holds caffeinate -i -s itself.
# CHANGELOG 2026-10-07 (i).
set -u
T="$HOME/ccx_frozen/20261007i_obj18"; LAB=hilda_csl3v0kaidgbemwt
PINS="$(cat "$T/logs/pins_20261007i.txt")"
cd "$T" || exit 1
unset CCX_MS_PREFLIGHT CCX_MS_ID
export CCX_MS_STRUCT="$LAB" CCX_MS_SEAS_ML=1 CCX_MS_SPREAD=1.0452 CCX_MS_PIN="$PINS" CCX_MS_TAG=20261007i CCX_MAC_NPAR=8
export CCX_MS_BUDGET_MIN=300 CCX_MS_CLOCK=cpu CCX_MS_RESTARTS=3 CCX_MS_CYCLES=6 CCX_MS_MAXIT=6000
export CCX_MS_OUTDIR="$T/calibration/output/multistart_20261007i_${LAB}_seasml1_pin_obj18_sd1.0452"
echo "objective #18 start $(date '+%Y-%m-%dT%H:%M:%S%z') at $(git -C "$T" rev-parse --short HEAD)"
bash calibration/mac/run_multistart_mac.sh > "logs/wave_20261007i.log" 2>&1
rc=$?
echo "objective #18 end $(date '+%Y-%m-%dT%H:%M:%S%z') rc $rc"
