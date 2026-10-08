#!/bin/bash
# kept-pair end-to-end: ONE short #18-arm task (id 1, hilda29w's start) from a frozen tree at 253fbc9 with #18's port targets.
cd /Users/MarcusMarcus/ccx_frozen/kept_pair_e2e_253fbc9 || exit 1
PIN16='ent_seas_amp_SH=0,w_eq=27,gamma_eq=1,pump_export=9.0800000000000001,w_vent=0,gamma_vent=0,w_thc=0,gamma_enso_ocn_NH=0,gamma_enso_ocn_SH=0,npp_tsens=0'
export CCX_MS_STRUCT=hilda_csl3v0kaidgbemwt CCX_MS_SEAS_ML=1 CCX_MS_PUMP_FIELD=solved CCX_MS_SPREAD=1.0452
export CCX_MS_PIN="$PIN16,lag_enso_land=5.8483078104595023,gamma_enso_land_NH=0.65897731179720698,gamma_enso_land_SH=0.63155946220609593,w_enso_l2=16.605064312322234"
export CCX_MS_ID=1 CCX_MS_BUDGET_MIN=20 CCX_MS_CLOCK=cpu CCX_MS_RESTARTS=1 CCX_MS_CYCLES=1 CCX_MS_MAXIT=300
export CCX_MS_OUTDIR=/Users/MarcusMarcus/ccx_frozen/kept_pair_e2e_253fbc9/calibration/output/kept_pair_e2e
export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1
nice -n 10 Rscript --vanilla calibration/run_dispersed_multistart.R
echo "exit $?"
