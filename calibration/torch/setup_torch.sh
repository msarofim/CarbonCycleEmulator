#!/bin/bash
# =====================================================================
# setup_torch.sh -- one-time: R library on scratch, Rcpp, and a compile check.
# Run ON TORCH, from /scratch/ms17839/CarbonCycleEmulator, after the bundle has
# been extracted. ~5 min, most of it Rcpp.
#
# THE ONLY R DEPENDENCY THE MODEL HAS IS Rcpp (grep of R/ and the driver:
# stats::, utils::, Rcpp::; adaptMCMC is used ONLY by ccx_run_mcmc(), which this
# survey does not call -- and it is NOT available on Torch, which is why the
# survey is a mode-finder and not a sampler).
# =====================================================================
set -euo pipefail
PROJ=/scratch/ms17839/CarbonCycleEmulator
cd "$PROJ"
set +u; source ~/.bashrc; set -u
module load r/4.5.1

# ⛔ THE R MODULE IS A SINGULARITY WRAPPER, AND ON THE LOGIN NODE IT HAS NO
# WRITABLE /tmp TO BIND (found 2026-09-01, first real run on Torch).
# /share/apps/r/4.5.1/bin/Rscript -> __run_base_r.bash picks its bind source as
#   SLURM_TMPDIR set   -> "${SLURM_TMPDIR}/rtmp-$$"
#   otherwise          -> "/state/partition1/${USER}/rtmp-$$"
# MEASURED, both halves: inside a SLURM job Torch DOES set SLURM_TMPDIR
# (/state/partition1/job-<id>) and /state/partition1 is drwxrwxrwt on the
# compute nodes -- so multistart.sbatch needs NOTHING and was never at risk.
# On the LOGIN node /state/partition1 is root-owned 755, the fallback mkdir
# fails, and EVERY Rscript dies with
#   "FATAL: container creation failed: ... mount source ... doesn't exist"
# which names the container, the mount and the pid, and NOTHING about R, the
# module, or the permission that actually failed. ⚠ The failing `mkdir` prints
# ABOVE singularity's own banner and is easy to read as noise.
# Setting SLURM_TMPDIR is the wrapper's OWN branch, not a workaround.
if [ -z "${SLURM_TMPDIR:-}" ]; then
  export SLURM_TMPDIR="/scratch/ms17839/tmp/ccx_setup_$$"
  mkdir -p "$SLURM_TMPDIR"
  trap 'rm -rf "${SLURM_TMPDIR}"' EXIT
  echo "login node: SLURM_TMPDIR unset, using $SLURM_TMPDIR for the R container's /tmp"
fi

export R_LIBS_USER=/scratch/ms17839/Rlibs/4.5
mkdir -p "$R_LIBS_USER" logs

Rscript --vanilla -e '
  if (!requireNamespace("Rcpp", quietly = TRUE))
    install.packages("Rcpp", repos = "https://cloud.r-project.org",
                     lib = Sys.getenv("R_LIBS_USER"))
  cat("Rcpp", as.character(packageVersion("Rcpp")), "OK\n")'

# COMPILE CHECK -- the C++ core is compiled by Rcpp::sourceCpp() at load, once
# per process. Prove it builds on this toolchain BEFORE an array of 40 tasks
# each discovers it cannot.
Rscript --vanilla -e '
  for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
  t0 <- Sys.time(); ccx_load_cpp()
  cat(sprintf("C++ core compiled in %.1f s\n",
              as.numeric(difftime(Sys.time(), t0, units = "secs"))))
  bp <- ccx_default_params(); bp$pump_mode <- "N"
  lp <- ccx_make_logpost(base_params = bp); u <- ccx_init_unc()
  t1 <- Sys.time(); for (i in 1:20) v <- lp(u)
  cat(sprintf("log-post at the cold init = %.4f\n", v))
  cat(sprintf("PER-EVAL %.4f s -- the Mac measured 0.15-0.22; size the array on THIS.\n",
              as.numeric(difftime(Sys.time(), t1, units = "secs")) / 20))'

echo
echo "NEXT: the PREFLIGHT batch -- ~2 min/task, exits 0 without optimising:"
echo "  CCX_MS_PREFLIGHT=1 sbatch --array=0-5,25,45 --time=00:15:00 \\"
echo "    calibration/torch/multistart.sbatch"
echo "  (0-5 are the fixed starts, 25 and 45 exercise the dispersed-draw path)"
