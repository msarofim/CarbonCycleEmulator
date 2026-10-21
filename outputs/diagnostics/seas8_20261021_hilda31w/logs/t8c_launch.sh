#!/bin/bash
# T8c launch (2026-10-21): 8 block fits from the frozen worktree /Users/MarcusMarcus/ccx_frozen/seas8_20261021 (commit 84295883 + the seas8 drivers copied in)
cd /Users/MarcusMarcus/ccx_frozen/seas8_20261021
export CCX_SEAS8_OUT=/Users/MarcusMarcus/Documents/2026/CodeProjects/CarbonCycleEmulator/outputs/diagnostics/seas8_20261021_hilda31w OPENBLAS_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 OMP_NUM_THREADS=1
: > /Users/MarcusMarcus/Documents/2026/CodeProjects/CarbonCycleEmulator/outputs/diagnostics/seas8_20261021_hilda31w/logs/t8c_fits.pids
for spec in "B_i mode" "B_i quad:B_i" "B_ii mode" "B_ii quad:A_iii" "B_iii mode" "B_iii quad:B_i" "B_iii quad:A_iii" "A_iii mode"; do
  set -- $spec
  tag="${1}_from_$(echo $2 | tr -d ':_')"
  nohup Rscript calibration/diag_seas8_split_fit_20261021.R --set=$1 --start=$2 --budget-min=75 > /Users/MarcusMarcus/Documents/2026/CodeProjects/CarbonCycleEmulator/outputs/diagnostics/seas8_20261021_hilda31w/logs/t8c_fit_${tag}.log 2>&1 &
  echo "$! $1 $2" >> /Users/MarcusMarcus/Documents/2026/CodeProjects/CarbonCycleEmulator/outputs/diagnostics/seas8_20261021_hilda31w/logs/t8c_fits.pids
done
