#!/bin/bash
# OBJECTIVE #16's REFIT (Marcus 2026-10-05: "p4"; "Mac, today (Recommended)"; "Neither: launch as ruled
# (Recommended)"). The stratification feedback's label hilda_csl3v0kaidgbem (KEPT, 10-05 a), the canonical's 9 pins
# + npp_tsens = 0 (P4), so 33 free names; k_w free (hs_asx_frac's width kept). From the frozen worktree at aa76fb5
# (the #16 reference-set rule, CHANGELOG 10-05 e), with nuclear14c copied in (diff -rq clean; 14/14 inputs) and port
# targets regenerated there under this pin set. 24 starts, 8 at a time, the 10-04 (g) recipe: WALL 300 min,
# 3 restarts x 6 cycles x 6000 maxit, spread 1.0452 (no _sdby_ suffix: npp_tsens is pinned, so its dispersion
# override drops out). Option A's in-restart deadline is in the driver (92b5756). CHANGELOG 10-05 (f).
set -u
T="$HOME/ccx_frozen/20261005f_obj16"; LAB=hilda_csl3v0kaidgbem
PINS="ent_seas_amp_SH=0,w_eq=27,gamma_eq=1,pump_export=9.08,w_vent=0,gamma_vent=0,w_thc=0,gamma_enso_ocn_NH=0,gamma_enso_ocn_SH=0,npp_tsens=0"
cd "$T" || exit 1
unset CCX_MS_PREFLIGHT CCX_MS_ID
export CCX_MS_STRUCT="$LAB" CCX_MS_SEAS_ML=1 CCX_MS_SPREAD=1.0452 CCX_MS_PIN="$PINS" CCX_MS_TAG=20261005f CCX_MAC_NPAR=8
export CCX_MS_OUTDIR="$T/calibration/output/multistart_20261005f_${LAB}_seasml1_pin_$(echo "$PINS" | tr ',' '_')_sd1.0452"
echo "objective #16 start $(date '+%Y-%m-%dT%H:%M:%S%z') at $(git -C "$T" rev-parse --short HEAD)"
bash calibration/mac/run_multistart_mac.sh > "logs/wave_20261005f.log" 2>&1
rc=$?
echo "objective #16 end $(date '+%Y-%m-%dT%H:%M:%S%z') rc $rc"
