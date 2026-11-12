#!/bin/bash
# k_w = 1446 PRICE PROFILE at hilda31fl, for card 7's sentence (group B item B20; Marcus 2026-11-11: "Re-measure B19-B21
# at hilda31fl"). The 10-13 recipe unchanged (CHANGELOG 2026-10-13 q): frozen worktree at 6c6cc9fd; two starts in
# parallel, A = the canonical's mode, B = warm from the 10-05 kw1446 refit; 300 CPU-min each; resumable (re-run this).
# Torch verdict, said out loud: the Mac (two single-threaded tasks; the Mac ~2x faster per evaluation, 10-23).
W=/Users/MarcusMarcus/ccx_frozen/20261111_kw1446_profile_hilda31fl
cd "$W" || exit 1
n=$(find data-raw/downloads -maxdepth 1 -type l | wc -l); [ -e data-raw/downloads/nuclear14c ] && [ ! -e data-raw/downloads/downloads ] && [ "$n" -ge 70 ] || { echo "REFUSING: data-raw/downloads not linked per file ($n links)"; exit 3; }
export OPENBLAS_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 OMP_NUM_THREADS=1
OUT=outputs/diagnostics/price_profile_20261111_hilda31fl
: > /Users/MarcusMarcus/ccx_frozen/20261111_kw1446_profile_hilda31fl.pids
for T in A B; do
  if [ $T = A ]; then S=canonical; else S=calibration/output/refit_20261005_kw1446_hilda_csl3v0kaidgbe/mode_fit_pumpN.rds; fi
  nohup caffeinate -i -s Rscript calibration/run_price_profile.R --hold=k_w=1446 --start=$S --tag=$T --out-dir=$OUT \
    >> /Users/MarcusMarcus/ccx_frozen/20261111_kw1446_profile_hilda31fl_$T.out 2>&1 &
  echo $! >> /Users/MarcusMarcus/ccx_frozen/20261111_kw1446_profile_hilda31fl.pids
done
