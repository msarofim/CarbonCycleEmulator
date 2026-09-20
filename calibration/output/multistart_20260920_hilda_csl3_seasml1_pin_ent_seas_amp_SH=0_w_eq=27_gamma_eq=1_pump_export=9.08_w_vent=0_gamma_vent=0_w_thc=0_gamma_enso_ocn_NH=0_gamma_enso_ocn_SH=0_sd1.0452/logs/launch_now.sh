#!/bin/bash
# 2026-09-20 (p): RULING 3 (Marcus: "yes for all 3") -- THE LAYER-3 Nino3.4 LIMB ON THE SHIPPED STRUCTURE:
# hilda_csl3 = hilda_cs (the seasonal ML's NH cycle flat) + the limb returning from layer 3; objective #13;
# seas_ml 1; the limb's 9 pins (the canonical's shim at 0 + six inert + the ocean ENSO shim pair at 0 --
# the limb REPLACES the shim), w_enso_l2 fitted (29 free). Prereg notes/prereg_2026-09-17k_l2_enso_limb_refit.md
# s4 rules stand: PA1 = w_enso_l2 inside Meinen's [14, 25] Sv/index; now against a shim that already fits
# the slope (0.94x at hilda30s), so the limb's case is PHYSICALITY + GATE V, not fit.
# Reference set: incumbent hilda30s (-1436.2727: its point, the pair zeroed, the limb seeded at 18.7),
# new basin hilda31pe (-1501.69). Frozen tree = the bundle at FROZEN_FROM_COMMIT.txt.
set -u
cd "$(dirname "$0")"
echo "firing $(date "+%Y-%m-%dT%H:%M:%S%z")"
export CCX_MS_STRUCT=hilda_csl3 CCX_MS_SEAS_ML=1
export CCX_MS_PIN=ent_seas_amp_SH=0,w_eq=27,gamma_eq=1,pump_export=9.08,w_vent=0,gamma_vent=0,w_thc=0,gamma_enso_ocn_NH=0,gamma_enso_ocn_SH=0
export CCX_MS_TAG=20260920
export CCX_MAC_NPAR="${CCX_MAC_NPAR:-8}"
bash calibration/mac/run_multistart_mac.sh
echo "launcher exit $? $(date "+%Y-%m-%dT%H:%M:%S%z")"
