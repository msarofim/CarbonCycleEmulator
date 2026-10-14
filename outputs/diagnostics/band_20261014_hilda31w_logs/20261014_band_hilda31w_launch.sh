#!/bin/bash
# hilda31w MCMC BAND (Marcus 2026-10-14, verbatim: "Pool all 4, build, test by chain (Recommended)"; "0 (Recommended)";
# data-raw/downloads/* (gitignored) is SYMLINKED file by file from the main checkout, as the 10-13 MCMC worktree was: without
# it the nuclear-14C source is zero (first launch, 07:02; the tie-cut run failed GATE MAP by 0.962 log-units).
# "Thin x2 within chain (Recommended)"). Frozen worktree at aac38b6; nothing here may be edited while it runs.
# Torch verdict, said out loud: Mac (the CCX R env + compiled core are verified here; 10 free cores; ~4.7 h on 8).
#   1. build_futures_ribbons.R --draws=pooled_u_thin2.rds (17 000 draws, 8 cores)
#   2. diag_mcmc_band_by_chain.R --laplace=none (no Gaussian band is buildable at hilda31w: P8 censors ~1 in 5)
#   3. diag_mcmc_drift.R --names = the five worst R-hats at this read
# It REPORTS; whether the band ships (promote_futures_ribbons.R) is Marcus's.
set -u
W=/Users/MarcusMarcus/ccx_frozen/20261014_band_hilda31w
SNAP=outputs/mcmc_check_20261014_hilda31w_200k
POOLED=$SNAP/pooled_u_thin2.rds
RIB=outputs/diagnostics/futures_ribbons_mcmc_20261014_hilda31w_200k.rds
TAG=hilda31w_200k
NAMES=seas_T_lag,seas_lag_p_NH,seas_lag_p_SH,beta_max,h_ml
cd "$W" || exit 1
export OPENBLAS_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 OMP_NUM_THREADS=1
echo "=== band launch $(date '+%Y-%m-%d %H:%M:%S') @$(git -C "$W" rev-parse --short HEAD); pooled md5 $(md5 -q $POOLED) ==="
echo "--- build $(date '+%H:%M:%S')"
caffeinate -i -s Rscript calibration/build_futures_ribbons.R --draws=$POOLED --cores=8 --out=$RIB || { echo "STOP: build rc $?"; exit 5; }
echo "--- by chain $(date '+%H:%M:%S')"
caffeinate -i -s Rscript calibration/diag_mcmc_band_by_chain.R --ribbons=$RIB --draws=$POOLED --laplace=none --tag=$TAG || { echo "STOP: by-chain rc $?"; exit 6; }
echo "--- drift $(date '+%H:%M:%S')"
caffeinate -i -s Rscript calibration/diag_mcmc_drift.R --dir=$SNAP --pooled=$POOLED --ribbons=$RIB --tag=$TAG --names=$NAMES || { echo "STOP: drift rc $?"; exit 7; }
echo "=== band done $(date '+%Y-%m-%d %H:%M:%S') ==="
