#!/bin/bash
# hilda31fl MCMC band (Marcus 2026-10-23: "Mac, tonight (Recommended)"; starts: the 10-13 ruling "Redraw until finite").
# Frozen worktree at 2ec25511. Exactly resumable: re-running this script continues each chain. Do NOT add --commit.
# The hilda31w launch (outputs/diagnostics/mcmc_launch_20261013_hilda31w/) with the tree, out dir and logs renamed.
cd /Users/MarcusMarcus/ccx_frozen/20261023_mcmc_hilda31fl
export OPENBLAS_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 OMP_NUM_THREADS=1
: > /Users/MarcusMarcus/ccx_frozen/20261023_mcmc_hilda31fl.pids
for c in 1 2 3 4; do
  nohup caffeinate -i -s Rscript calibration/run_mcmc_check.R --chain=$c --n=200000 --adapt=30000 --thin=20 --ckpt=500 \
    --out=outputs/mcmc_check_20261023_hilda31fl >> /Users/MarcusMarcus/ccx_frozen/20261023_mcmc_hilda31fl_chain$c.out 2>&1 &
  echo $! >> /Users/MarcusMarcus/ccx_frozen/20261023_mcmc_hilda31fl.pids
done
