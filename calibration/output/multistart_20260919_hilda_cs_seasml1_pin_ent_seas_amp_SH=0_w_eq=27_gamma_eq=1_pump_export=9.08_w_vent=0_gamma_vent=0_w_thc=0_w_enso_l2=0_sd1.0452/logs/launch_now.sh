#!/bin/bash
# 2026-09-19 (l): RULING 1's TEST, refit form -- the canonical's arm under the hilda_cs structure
# (the seasonal ML's NH cycle FLAT, SH cycle on), objective #13, seas_ml 1, the canonical's 8 pins
# (the shim at 0 + seven inert), 30 free. Reference set: incumbent hilda30e (-1480.2586 = its point
# with the NH flat, the 09-19 k knock-out), new basin hilda31pe (-1496.32). Frozen tree = the bundle
# at FROZEN_FROM_COMMIT.txt. THE QUESTION: does a refit with the NH cycle flat recover the NH
# seasonal rows (d13c_seasonal_MLO -7.25 vs the control) -- the ML right in the SH and wrong in the NH
# (H_driver) -- or not (H_mech)? Read with diag_obj13_refit_read.R (O13_LABEL=canonical) + a hilda_cs read.
set -u
cd "$(dirname "$0")"
echo "firing $(date "+%Y-%m-%dT%H:%M:%S%z")"
export CCX_MS_STRUCT=hilda_cs CCX_MS_SEAS_ML=1
export CCX_MS_PIN=ent_seas_amp_SH=0,w_eq=27,gamma_eq=1,pump_export=9.08,w_vent=0,gamma_vent=0,w_thc=0,w_enso_l2=0
export CCX_MS_TAG=20260919
export CCX_MAC_NPAR="${CCX_MAC_NPAR:-8}"
bash calibration/mac/run_multistart_mac.sh
echo "launcher exit $? $(date "+%Y-%m-%dT%H:%M:%S%z")"
