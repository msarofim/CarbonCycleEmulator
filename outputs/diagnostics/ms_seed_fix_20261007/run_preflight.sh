#!/bin/bash
# run_preflight.sh <arm: obj16|obj18> <id> -- the FIXED driver's own PREFLIGHT (CCX_MS_PREFLIGHT=1) under the arm's wave
# environment: start, duplicate refusal, port gate, rate, the PREFLIGHT line. obj18 needs #18's port targets in place.
set -u
arm="$1"; id="$2"; D=outputs/diagnostics/ms_seed_fix_20261007
PIN16='ent_seas_amp_SH=0,w_eq=27,gamma_eq=1,pump_export=9.0800000000000001,w_vent=0,gamma_vent=0,w_thc=0,gamma_enso_ocn_NH=0,gamma_enso_ocn_SH=0,npp_tsens=0'
case "$arm" in
  obj16) export CCX_MS_STRUCT=hilda_csl3v0kaidgbem; export CCX_MS_PIN="$PIN16" ;;
  obj18) export CCX_MS_STRUCT=hilda_csl3v0kaidgbemwt
         export CCX_MS_PIN="$PIN16,lag_enso_land=5.8483078104595023,gamma_enso_land_NH=0.65897731179720698,gamma_enso_land_SH=0.63155946220609593,w_enso_l2=16.605064312322234" ;;
esac
export CCX_MS_SEAS_ML=1 CCX_MS_PUMP_FIELD=solved CCX_MS_SPREAD=1.0452 CCX_MS_ID="$id" CCX_MS_PREFLIGHT=1
export CCX_MS_BUDGET_MIN=300 CCX_MS_CLOCK=cpu CCX_MS_RESTARTS=3 CCX_MS_CYCLES=6 CCX_MS_MAXIT=6000
export CCX_MS_OUTDIR="${CCX_SCRATCH:?}/ms_seed_preflight_${arm}"
export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1
log="$D/preflight_${arm}_$(printf %03d "$id").log"
nice -n 10 Rscript --vanilla calibration/run_dispersed_multistart.R > "$log" 2>&1
echo "$arm $id rc $?"
