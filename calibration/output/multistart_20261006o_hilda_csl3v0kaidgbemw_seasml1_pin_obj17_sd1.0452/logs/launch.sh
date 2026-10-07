#!/bin/bash
# OBJECTIVE #17's STAGE-2 REFIT (Marcus 2026-10-06: "Build: land + ocean module (Recommended)"; "Mac, overnight
# (Recommended)"). The interannual cut's label hilda_csl3v0kaidgbemw (Marcus: "hilda_csl3v0kaidgbemw (Recommended)"):
# gcb_land_sink scored on its low-pass part, gcb_ocean_enso_slope moved to the module. #16's ten pins + the module's
# four at STAGE 1's values (calibration/fit_iav_module.R @edc0cd0 -> calibration/output/iav_module_20261006_hilda33p.rds;
# R/paths.R CCX_MODE_OBJ17_PINS), so 29 free names. From the frozen worktree at 20a89f8, the git-ignored downloads
# symlinked (14/14 inputs), port targets regenerated there under this pin set (logs/port_targets_20261006o.log).
# Preflight 24/24 LAUNCHABLE, every port VERIFIED, 0.347 CPU-s/eval at id 1 (logs/preflight_20261006o/).
# 24 starts, 8 at a time, the 10-05 recipe on the CPU clock: BUDGET 300 CPU-min, 3 restarts x 6 cycles x 6000 maxit,
# spread 1.0452. The outdir is NAMED: the driver's default carries the 14 pins (379 bytes, over macOS's 255-byte
# limit). Launched under nohup; the Mac launcher holds caffeinate -i -s itself. CHANGELOG 2026-10-06 (o).
set -u
T="$HOME/ccx_frozen/20261006x_obj17"; LAB=hilda_csl3v0kaidgbemw
PINS="ent_seas_amp_SH=0,w_eq=27,gamma_eq=1,pump_export=9.0800000000000001,w_vent=0,gamma_vent=0,w_thc=0,gamma_enso_ocn_NH=0,gamma_enso_ocn_SH=0,npp_tsens=0,lag_enso_land=5.8432437811315161,gamma_enso_land_NH=0.66071085740286073,gamma_enso_land_SH=0.63322088075695704,w_enso_l2=14.726151317112601"
cd "$T" || exit 1
unset CCX_MS_PREFLIGHT CCX_MS_ID
export CCX_MS_STRUCT="$LAB" CCX_MS_SEAS_ML=1 CCX_MS_SPREAD=1.0452 CCX_MS_PIN="$PINS" CCX_MS_TAG=20261006o CCX_MAC_NPAR=8
export CCX_MS_BUDGET_MIN=300 CCX_MS_CLOCK=cpu CCX_MS_RESTARTS=3 CCX_MS_CYCLES=6 CCX_MS_MAXIT=6000
export CCX_MS_OUTDIR="$T/calibration/output/multistart_20261006o_${LAB}_seasml1_pin_obj17_sd1.0452"
echo "objective #17 start $(date '+%Y-%m-%dT%H:%M:%S%z') at $(git -C "$T" rev-parse --short HEAD)"
bash calibration/mac/run_multistart_mac.sh > "logs/wave_20261006o.log" 2>&1
rc=$?
echo "objective #17 end $(date '+%Y-%m-%dT%H:%M:%S%z') rc $rc"
