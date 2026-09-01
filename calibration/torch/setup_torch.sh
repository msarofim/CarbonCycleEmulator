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
echo "NEXT: sbatch --array=0-2 calibration/torch/multistart.sbatch   # the gate batch"
