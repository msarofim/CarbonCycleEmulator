#!/bin/bash
# The tie stability on 400 draws (Marcus 2026-10-24: "Re-run on 400 draws (Recommended)"): CO2 level and d13C level &
# gradient lost their winner in exactly 5 of 100 draws, on APP_CMAP_TIE_LOST_MAX (CHANGELOG 2026-10-24 a).
# Frozen worktree at 283e3f3b, data-raw/downloads linked per file (79 + 3 tracked). Torch verdict, said out loud: Mac (~20 min on 8).
cd /Users/MarcusMarcus/ccx_frozen/20261024_cmap400_hilda31fl || exit 1
n=$(find data-raw/downloads -maxdepth 1 -type l | wc -l); [ -e data-raw/downloads/nuclear14c ] && [ "$n" -ge 79 ] || { echo "REFUSING: data-raw/downloads not linked per file ($n links)"; exit 3; }
export OPENBLAS_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 OMP_NUM_THREADS=1
echo "=== launch $(date '+%Y-%m-%d %H:%M:%S') @$(git rev-parse --short HEAD) ==="
caffeinate -i -s Rscript calibration/diag_cmap_posterior_spread.R --draws=outputs/mcmc_check_20261024_hilda31fl_200k/pooled_u_thin2.rds \
  --chains=outputs/mcmc_check_20261024_hilda31fl_200k --n=400 --cores=8
echo "rc=$? $(date '+%H:%M:%S')"
