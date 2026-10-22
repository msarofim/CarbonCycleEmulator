#!/bin/bash
# T8c with the MLO CO2 seasonal row on Scripps flask CO2 (Marcus 2026-10-21: "Measure first", after T8d): 7 block fits
# from the frozen worktree /Users/MarcusMarcus/ccx_frozen/seas8flask_20261021_153ff068 (commit 153ff068), the same
# starts as the eps run, then the collect step. Waits on its own children (wait), never a pgrep loop.
cd /Users/MarcusMarcus/ccx_frozen/seas8flask_20261021_153ff068
export CCX_SEAS8_CO2SEAS=MLO_SIO_FLASK CCX_SEAS8_OUT=/Users/MarcusMarcus/Documents/2026/CodeProjects/CarbonCycleEmulator/outputs/diagnostics/seas8_20261021_hilda31w/co2flask CCX_SEAS8_SCREEN_DIR=/Users/MarcusMarcus/Documents/2026/CodeProjects/CarbonCycleEmulator/outputs/diagnostics/seas8_20261021_hilda31w OPENBLAS_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 OMP_NUM_THREADS=1
t0=$(date +%s)
for spec in "B_iii mode" "B_iii fit:/Users/MarcusMarcus/Documents/2026/CodeProjects/CarbonCycleEmulator/outputs/diagnostics/seas8_20261021_hilda31w/t8c_fit_B_i_from_mode.rds" "B_iii fit:/Users/MarcusMarcus/Documents/2026/CodeProjects/CarbonCycleEmulator/outputs/diagnostics/seas8_20261021_hilda31w/t8c_fit_B_ii_from_quadA_iii.rds" \
            "B_i mode" "B_i fit:/Users/MarcusMarcus/Documents/2026/CodeProjects/CarbonCycleEmulator/outputs/diagnostics/seas8_20261021_hilda31w/t8c_fit_B_ii_from_quadA_iii.rds" "B_ii mode" "B_ii fit:/Users/MarcusMarcus/Documents/2026/CodeProjects/CarbonCycleEmulator/outputs/diagnostics/seas8_20261021_hilda31w/t8c_fit_B_ii_from_quadA_iii.rds"; do
  set -- $spec
  tag="${1}_from_$(basename "$2" .rds | tr -d ':_')"
  Rscript calibration/diag_seas8_split_fit_20261021.R --set=$1 --start=$2 --budget-min=75 > /Users/MarcusMarcus/Documents/2026/CodeProjects/CarbonCycleEmulator/outputs/diagnostics/seas8_20261021_hilda31w/co2flask/logs/t8c_fit_${tag}.log 2>&1 &
  echo "$! $1 $2" >> /Users/MarcusMarcus/Documents/2026/CodeProjects/CarbonCycleEmulator/outputs/diagnostics/seas8_20261021_hilda31w/co2flask/logs/t8c_fits.pids
done
wait
echo "fits done after $(( $(date +%s) - t0 )) s"
Rscript calibration/diag_seas8_split_collect_20261021.R > /Users/MarcusMarcus/Documents/2026/CodeProjects/CarbonCycleEmulator/outputs/diagnostics/seas8_20261021_hilda31w/co2flask/t8c_split_hilda31w.log 2>&1
echo "collect rc=$? after $(( $(date +%s) - t0 )) s"
