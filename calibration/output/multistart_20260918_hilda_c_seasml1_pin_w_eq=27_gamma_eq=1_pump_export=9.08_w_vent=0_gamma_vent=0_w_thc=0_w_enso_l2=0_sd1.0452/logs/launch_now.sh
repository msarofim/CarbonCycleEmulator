#!/bin/bash
# 2026-09-18 (c), Marcus: "for 1, I'll want to do the tests" -- test (a): the FREE PARENT's refit
# under objective #12 / hilda_c (seasonal ML ON, the shim FREE; the six inert pins + w_enso_l2 = 0;
# 31 free). Frozen tree = the bundle at the commit in FROZEN_FROM_COMMIT.txt. Preflight 24/24.
set -u
cd "$(dirname "$0")"
echo "firing $(date "+%Y-%m-%dT%H:%M:%S%z")"
export CCX_MS_STRUCT=hilda_c CCX_MS_SEAS_ML=1
export CCX_MS_PIN=w_eq=27,gamma_eq=1,pump_export=9.08,w_vent=0,gamma_vent=0,w_thc=0,w_enso_l2=0
export CCX_MS_TAG=20260918
export CCX_MAC_NPAR="${CCX_MAC_NPAR:-8}"
bash calibration/mac/run_multistart_mac.sh
echo "launcher exit $? $(date "+%Y-%m-%dT%H:%M:%S%z")"
