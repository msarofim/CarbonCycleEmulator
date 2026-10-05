#!/bin/bash
# The k_w = 1446 PRICE ARM (Marcus 2026-10-04: "Canonical incumbent, Mac (Recommended)"; handoff
# 2026-10-04 item 4): the canonical's label hilda_csl3v0kaidgbe, its 9 pins + k_w = 1446 (Naegler 2009,
# KW_PRIOR_CENTRE), 33 free; from the frozen worktree at 773f8f2 with nuclear14c copied in and port
# targets regenerated there; 24 starts, 8 at a time, the 10-02 (ee) recipe. CHANGELOG 10-04 (g).
set -u
T="$HOME/ccx_frozen/20261004f_kw1446"; LAB=hilda_csl3v0kaidgbe
PINS="ent_seas_amp_SH=0,w_eq=27,gamma_eq=1,pump_export=9.08,w_vent=0,gamma_vent=0,w_thc=0,gamma_enso_ocn_NH=0,gamma_enso_ocn_SH=0,k_w=1446"
cd "$T" || exit 1
unset CCX_MS_PREFLIGHT CCX_MS_ID
export CCX_MS_STRUCT="$LAB" CCX_MS_SEAS_ML=1 CCX_MS_SPREAD=1.0452 CCX_MS_PIN="$PINS" CCX_MS_TAG=20261004f CCX_MAC_NPAR=8
export CCX_MS_OUTDIR="$T/calibration/output/multistart_20261004f_${LAB}_seasml1_pin_$(echo "$PINS" | tr ',' '_')_sd1.0452_sdby_npp_tsens=0.0291"
echo "k_w price arm start $(date '+%Y-%m-%dT%H:%M:%S%z')"
bash calibration/mac/run_multistart_mac.sh > "logs/wave_20261004f.log" 2>&1
echo "k_w price arm end $(date '+%Y-%m-%dT%H:%M:%S%z') rc $?"
