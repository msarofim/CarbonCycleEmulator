#!/bin/bash
# The tie cut from the posterior (Marcus 2026-10-14: "Posterior spread, 100 draws (Recommended)"). Frozen worktree at 1c26e8e.
# data-raw/downloads/* (gitignored) is SYMLINKED file by file from the main checkout, as the 10-13 MCMC worktree was: without
# it the nuclear-14C source is zero (first launch, 07:02; the tie-cut run failed GATE MAP by 0.962 log-units).
# One core, beside the band build's eight. Torch verdict, said out loud: Mac (~50 min on one core).
cd /Users/MarcusMarcus/ccx_frozen/20261014_cmap_spread || exit 1
export OPENBLAS_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 OMP_NUM_THREADS=1
caffeinate -i -s Rscript calibration/diag_cmap_posterior_spread.R --draws=outputs/mcmc_check_20261014_hilda31w_200k/pooled_u_thin2.rds \
  --chains=outputs/mcmc_check_20261014_hilda31w_200k --n=100 --cores=1
echo "rc=$?"
