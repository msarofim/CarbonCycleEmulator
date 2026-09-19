#!/bin/bash
# 2026-09-18 (f): THE CANONICAL's REFIT UNDER OBJECTIVE #13 (the GCB ENSO ocean-slope row, added
# 09-18 e) -- owed after every objective change. hilda_c, seasonal ML ON, the canonical's 7 pins
# (the shim at 0 + six inert) + w_enso_l2 = 0 (the limb's name, absent under hilda_c), 30 free.
# Reference set: incumbent hilda30h (-1436.6717 = its #13 restamp, offset 0), new basin hilda31p.
# Frozen tree = the bundle at the commit in FROZEN_FROM_COMMIT.txt. Fire by hand or from a chain.
set -u
cd "$(dirname "$0")"
echo "firing $(date "+%Y-%m-%dT%H:%M:%S%z")"
export CCX_MS_STRUCT=hilda_c CCX_MS_SEAS_ML=1
export CCX_MS_PIN=ent_seas_amp_SH=0,w_eq=27,gamma_eq=1,pump_export=9.08,w_vent=0,gamma_vent=0,w_thc=0,w_enso_l2=0
export CCX_MS_TAG=20260918
export CCX_MAC_NPAR="${CCX_MAC_NPAR:-8}"
bash calibration/mac/run_multistart_mac.sh
echo "launcher exit $? $(date "+%Y-%m-%dT%H:%M:%S%z")"
