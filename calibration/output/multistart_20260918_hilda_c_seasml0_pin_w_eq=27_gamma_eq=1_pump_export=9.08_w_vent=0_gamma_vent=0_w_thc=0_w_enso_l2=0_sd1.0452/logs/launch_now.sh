#!/bin/bash
# 2026-09-18 (f): THE seas_ml-0 CONTROL's REFIT UNDER OBJECTIVE #13 (the GCB ENSO ocean-slope row,
# 09-18 e) -- the third arm of the like-for-like #13 set (canonical / control / free parent).
# hilda_c, seasonal ML OFF, the six inert pins + w_enso_l2 = 0 (the limb's name, absent under
# hilda_c), the shim FREE: 31 free -- the 09-17 j arm plus the inert limb pin.
# Reference set: incumbent hilda31p (-1795.4028), new basin hilda31s2 (-2093.2005); with the row
# off both reproduce the 09-17 j targets to the digit. Frozen tree = the bundle at
# FROZEN_FROM_COMMIT.txt. Fire by hand or from a chain.
set -u
cd "$(dirname "$0")"
echo "firing $(date "+%Y-%m-%dT%H:%M:%S%z")"
export CCX_MS_STRUCT=hilda_c CCX_MS_SEAS_ML=0
export CCX_MS_PIN=w_eq=27,gamma_eq=1,pump_export=9.08,w_vent=0,gamma_vent=0,w_thc=0,w_enso_l2=0
export CCX_MS_TAG=20260918
export CCX_MAC_NPAR="${CCX_MAC_NPAR:-8}"
bash calibration/mac/run_multistart_mac.sh
echo "launcher exit $? $(date "+%Y-%m-%dT%H:%M:%S%z")"
