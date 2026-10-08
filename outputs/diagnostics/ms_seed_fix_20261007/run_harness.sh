#!/bin/bash
# run_harness.sh <arm: obj16|obj18> <which: old|new> <id> -- one harness call under the arm's wave environment.
set -u
arm="$1"; which="$2"; id="$3"
D=outputs/diagnostics/ms_seed_fix_20261007
PIN16='ent_seas_amp_SH=0,w_eq=27,gamma_eq=1,pump_export=9.0800000000000001,w_vent=0,gamma_vent=0,w_thc=0,gamma_enso_ocn_NH=0,gamma_enso_ocn_SH=0,npp_tsens=0'
case "$arm" in
  obj16) export CCX_MS_STRUCT=hilda_csl3v0kaidgbem; export CCX_MS_PIN="$PIN16" ;;
  obj18) export CCX_MS_STRUCT=hilda_csl3v0kaidgbemwt
         export CCX_MS_PIN="$PIN16,lag_enso_land=5.8483078104595023,gamma_enso_land_NH=0.65897731179720698,gamma_enso_land_SH=0.63155946220609593,w_enso_l2=16.605064312322234" ;;
esac
case "$which" in old) drv=$D/driver_old_3c0bfd8.R ;; new) drv=calibration/run_dispersed_multistart.R ;; esac
export CCX_MS_SEAS_ML=1 CCX_MS_PUMP_FIELD=solved CCX_MS_SPREAD=1.0452 CCX_MS_ID="$id"
export CCX_MS_BUDGET_MIN=300 CCX_MS_CLOCK=cpu CCX_MS_RESTARTS=3 CCX_MS_CYCLES=6 CCX_MS_MAXIT=6000
export CCX_MS_OUTDIR="${CCX_SCRATCH:?}/ms_seed_harness_${arm}_${which}"
export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1
nice -n 10 Rscript --vanilla $D/start_harness.R "$drv" "$D/start_${arm}_${which}_$(printf %03d "$id").rds" > "$D/start_${arm}_${which}_$(printf %03d "$id").log" 2>&1
echo "$arm $which $id rc $?"
