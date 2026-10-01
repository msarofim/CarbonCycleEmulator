#!/bin/bash
# =====================================================================
# mcmc_check.sbatch -- ONE CHAIN of the MCMC check per array task
# (Marcus 2026-10-01, review 10-01c B7: "Laplace first, MCMC as the check";
# where: "Torch (Recommended)"). The chain driver is calibration/run_mcmc_check.R.
#
# ⚠ SUBMISSION IS MARCUS'S CALL (asked before every submit), AND THE
# AUTHENTICATION IS HIS: VPN, gateway password, Duo, the device code.
#
# ⛔ SMOKE FIRST (the nyu-torch-hpc test-before-you-scale gate), into its OWN
# output dir so production never resumes a smoke checkpoint:
#     CCX_MC_N=600 CCX_MC_ADAPT=300 CCX_MC_CKPT=100 CCX_MC_OUT=outputs/mcmc_smoke \
#       sbatch --array=1-4 --time=00:45:00 calibration/torch/mcmc_check.sbatch
# ⚠ CKPT 100, not the default 500 (2026-10-01 p): the proposal is refreshed only AT a
# checkpoint inside [t0, adapt] = [adapt/3, adapt] = [100, 300], so at 500 the smoke
# never adapts at all, and it prints only two progress lines to time the rate from.
# Read, for all four: exit 0; the driver's port gate ("recomputed ... stored ...")
# passed (it STOPS on a mismatch > 1e-5, so the logpost is the Mac's objective);
# chain_<k>.rds written; the per-checkpoint s/iteration -- the RATE that sizes
# production. THEN production:
#     CCX_MC_COMMIT=<sha> sbatch --array=1-4 calibration/torch/mcmc_check.sbatch
#
# WALL. Measured on Torch nodes 2026-09-10 (multistart.sbatch, preflight job
# 17316317): 0.59-1.08 s per evaluation under the periodic spin-up. One
# iteration = one evaluation, so 1e5 iterations = 16-30 h. `cs` has no QoS
# wall cap (QoS=N/A, MaxTime=UNLIMITED; measured with scontrol, see
# multistart.sbatch), so the request is 36 h with the driver's own stop at
# CCX_MC_WALL_MIN (34 h) -- it checkpoints and exits 0. Re-submitting the SAME
# command resumes every unfinished chain exactly (its RNG state rides in the
# checkpoint); a finished chain exits at once.
#
# MEMORY: one chain holds 1e5 log-posteriors and ~3,500 x 33 samples, a few MB;
# the model's measured peak RSS is 213 MB (multistart.sbatch). 4G is headroom.
# =====================================================================
#SBATCH --job-name=ccx_mcmc
#SBATCH --account=torch_pr_1041_general
#SBATCH --partition=cs
#SBATCH --time=36:00:00
#SBATCH --mem=4G
#SBATCH --cpus-per-task=1
#SBATCH --array=1-4
#SBATCH --output=/scratch/ms17839/CarbonCycleEmulator/logs/%x_%A_%a.out
#SBATCH --error=/scratch/ms17839/CarbonCycleEmulator/logs/%x_%A_%a.err
set -euo pipefail
# ⛔ CCX_PROJ_DIR, readonly, never PROJ (Torch's ~/.bashrc exports PROJ for another project)
# CCX_PROJ points the body at an extracted bundle for a LOCAL dry run (multistart.sbatch's idiom);
# on Torch it is unset and the scratch path is used.
CCX_PROJ_DIR="${CCX_PROJ:-/scratch/ms17839/CarbonCycleEmulator}"
readonly CCX_PROJ_DIR
cd "$CCX_PROJ_DIR"
mkdir -p logs
if [ -z "${CCX_SKIP_MODULES:-}" ]; then       # CCX_SKIP_MODULES=1 only for a local dry run
  set +u; source ~/.bashrc; set -u
  module load r/4.5.1
  export R_LIBS_USER=/scratch/ms17839/Rlibs/4.5
fi
cd "$CCX_PROJ_DIR"            # a sourced rc may move the cwd; the Rscript path below is relative

CCX_MC_OUT="${CCX_MC_OUT:-outputs/mcmc_check}"
case "$CCX_MC_OUT" in /*) echo "FATAL: CCX_MC_OUT must be relative to $CCX_PROJ_DIR" >&2; exit 1 ;; esac
export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1    # serial chain [[pin_blas_threads]]

echo "host $(hostname)  chain ${SLURM_ARRAY_TASK_ID}  out ${CCX_MC_OUT}  $(date "+%Y-%m-%dT%H:%M:%S%z")"
Rscript --vanilla calibration/run_mcmc_check.R \
  --chain="${SLURM_ARRAY_TASK_ID}" \
  --n="${CCX_MC_N:-100000}" --adapt="${CCX_MC_ADAPT:-30000}" \
  --thin="${CCX_MC_THIN:-20}" --ckpt="${CCX_MC_CKPT:-500}" \
  --wall_min="${CCX_MC_WALL_MIN:-2040}" \
  --out="${CCX_MC_OUT}" --commit="${CCX_MC_COMMIT:-unrecorded}"
echo "done $(date "+%Y-%m-%dT%H:%M:%S%z")"
