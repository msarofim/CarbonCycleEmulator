#!/bin/bash
# =====================================================================
# multistart.sbatch -- ONE dispersed start per array task.
#
# ⚠ SUBMITTED BY MARCUS, NOT BY CLAUDE. Torch needs the NYU VPN, the gateway
# password, Duo, and a Microsoft device-code at login.torch; none of that is
# scriptable from here.
#
# ⛔ RUN THE GATE BATCH FIRST AND READ IT:
#     sbatch --array=0-2 calibration/torch/multistart.sbatch
# Ids 0/1/2 are the cold init, the 08-30 incumbent and the 08-31e new basin.
# Ids 1 and 2 carry a PORT GATE against logposts measured on the Mac and shipped
# in calibration/torch/port_targets.csv. If either fails, every dispersed start
# in the survey would be optimising a different objective. Do not scale past it.
# This is also the skill's own "test before you scale" gate: 5 tasks, all
# exit 0, real output files, before any array with N > 20.
#
# THEN the survey:
#     sbatch --array=3-42 calibration/torch/multistart.sbatch
#
# WALL. cpu_short caps at 4 h. CCX_MS_WALL_MIN below stops the optimiser
# cleanly with 30 min to spare and CHECKPOINTS, so re-submitting the same array
# RESUMES each task from its own checkpoint rather than restarting it.
# =====================================================================
#SBATCH --job-name=ccx_multistart
#SBATCH --account=torch_pr_1041_general
#SBATCH --partition=cpu_short
#SBATCH --time=04:00:00
#SBATCH --mem=4G
#SBATCH --cpus-per-task=1
#SBATCH --output=/scratch/ms17839/CarbonCycleEmulator/logs/%x_%A_%a.out
#SBATCH --error=/scratch/ms17839/CarbonCycleEmulator/logs/%x_%A_%a.err

set -euo pipefail
PROJ=/scratch/ms17839/CarbonCycleEmulator
cd "$PROJ"
mkdir -p logs calibration/output

# NYU's /etc/bashrc references an unbound BASHRCSOURCED; without the sandwich
# `set -u` kills the job at startup.
set +u; source ~/.bashrc; set -u
module load r/4.5.1
export R_LIBS_USER=/scratch/ms17839/Rlibs/4.5

# ONE THREAD. The work is a serial Nelder-Mead; BLAS threads buy nothing here
# and cost 11 h vs 2 h17 elsewhere when they oversubscribe. [[pin_blas_threads]]
export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1

export CCX_MS_OUTDIR=$PROJ/calibration/output/multistart_20260831
export CCX_MS_WALL_MIN=210        # 3.5 h of the 4 h partition cap
export CCX_MS_RESTARTS=3
export CCX_MS_CYCLES=6
export CCX_MS_MAXIT=6000

echo "host $(hostname)  task ${SLURM_ARRAY_TASK_ID}  $(date -Is)"
Rscript --vanilla calibration/run_dispersed_multistart.R
echo "done $(date -Is)"
