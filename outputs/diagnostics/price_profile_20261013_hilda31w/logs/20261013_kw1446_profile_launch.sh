#!/bin/bash
# k_w = 1446 PRICE PROFILE at hilda31w (Marcus 2026-10-13: "Two-start profile, Mac (Recommended)"), for card 7's sentence.
# Frozen worktree at 142767b. Two starts in parallel: A = hilda31w's mode, B = warm from the 10-05 kw1446 refit (the
# shared names; the WTC names at hilda31w's). 300 CPU-min each, the wave's recipe. Resumable: re-run this script.
# Torch verdict, said out loud: Mac (2 cores beside the MCMC's 4; ruled).
W=/Users/MarcusMarcus/ccx_frozen/20261013_kw1446_profile
cd "$W" || exit 1
export OPENBLAS_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 OMP_NUM_THREADS=1
OUT=outputs/diagnostics/price_profile_20261013_hilda31w
: > /Users/MarcusMarcus/ccx_frozen/20261013_kw1446_profile.pids
for T in A B; do
  if [ $T = A ]; then S=canonical; else S=calibration/output/refit_20261005_kw1446_hilda_csl3v0kaidgbe/mode_fit_pumpN.rds; fi
  nohup caffeinate -i -s Rscript calibration/run_price_profile.R --hold=k_w=1446 --start=$S --tag=$T --out-dir=$OUT \
    >> /Users/MarcusMarcus/ccx_frozen/20261013_kw1446_profile_$T.out 2>&1 &
  echo $! >> /Users/MarcusMarcus/ccx_frozen/20261013_kw1446_profile.pids
done
