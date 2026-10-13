#!/bin/bash
# hilda31w MCMC band (Marcus 2026-10-13: "Launch on the Mac (Recommended)"; starts "Redraw until finite (Recommended)").
# Frozen worktree at e83e228. Exactly resumable: re-running this script continues each chain. Do NOT add --commit.
cd /Users/MarcusMarcus/ccx_frozen/20261013_mcmc_hilda31w
export OPENBLAS_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 OMP_NUM_THREADS=1
: > /Users/MarcusMarcus/ccx_frozen/20261013_mcmc_hilda31w.pids
for c in 1 2 3 4; do
  nohup caffeinate -i -s Rscript calibration/run_mcmc_check.R --chain=$c --n=200000 --adapt=30000 --thin=20 --ckpt=500 \
    --out=outputs/mcmc_check_20261013_hilda31w >> /Users/MarcusMarcus/ccx_frozen/20261013_mcmc_hilda31w_chain$c.out 2>&1 &
  echo $! >> /Users/MarcusMarcus/ccx_frozen/20261013_mcmc_hilda31w.pids
done
