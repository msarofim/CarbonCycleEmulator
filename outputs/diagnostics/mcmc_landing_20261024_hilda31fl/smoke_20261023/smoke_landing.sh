#!/bin/bash
# SMOKE of the hilda31fl landing chain's steps, on interim checkpoint copies (scratch; outputs in the frozen tree's outputs/smoke_20261023)
set -u
W=/Users/MarcusMarcus/ccx_frozen/20261024_land_hilda31fl
SNAP=outputs/smoke_20261023/snap
SM=outputs/smoke_20261023
cd "$W" || exit 1
export OPENBLAS_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 OMP_NUM_THREADS=1
t() { echo "--- $1 $(date '+%H:%M:%S')"; }
t read0; Rscript calibration/read_mcmc_check.R --dir=$SNAP --drop=0 > $SM/read0.out 2>&1 || { echo "STOP read0 rc $?"; exit 2; }
t readthin; Rscript calibration/read_mcmc_check.R --dir=$SNAP --drop=0 --pool-thin=100 > $SM/readthin.out 2>&1 || { echo "STOP readthin rc $?"; exit 3; }
t ident; Rscript calibration/diag_mcmc_identifiability.R --draws=$SNAP/pooled_u.rds --out-dir=$SNAP > $SM/ident.out 2>&1 || { echo "STOP ident rc $?"; exit 4; }
t build; Rscript calibration/build_futures_ribbons.R --draws=$SNAP/pooled_u_thin100.rds --cores=4 --out=$SM/ribbons_smoke.rds > $SM/build.out 2>&1 || { echo "STOP build rc $?"; exit 5; }
t bychain; Rscript calibration/diag_mcmc_band_by_chain.R --ribbons=$SM/ribbons_smoke.rds --draws=$SNAP/pooled_u_thin100.rds --laplace=none --tag=smoke > $SM/bychain.out 2>&1 || { echo "STOP bychain rc $?"; exit 6; }
t drift; Rscript calibration/diag_mcmc_drift.R --dir=$SNAP --pooled=$SNAP/pooled_u_thin100.rds --ribbons=$SM/ribbons_smoke.rds --tag=smoke --names=beta_max,ndep_ret,fert_k,seas_T_lag,luc_scale > $SM/drift.out 2>&1 || { echo "STOP drift rc $?"; exit 7; }
t spread; Rscript calibration/diag_cmap_posterior_spread.R --draws=$SNAP/pooled_u_thin100.rds --chains=$SNAP --n=2 --cores=1 --out-dir=$SM > $SM/spread.out 2>&1 || { echo "STOP spread rc $?"; exit 8; }
t done
