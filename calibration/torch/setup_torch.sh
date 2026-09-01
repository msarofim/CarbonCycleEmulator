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

# ⛔ EVERY R SNIPPET BELOW GOES THROUGH A FILE, NEVER `Rscript -e`
# (found the hard way 2026-09-01, on the first real run on Torch).
# /share/apps/r/4.5.1/bin/Rscript is a wrapper that re-quotes its argv --
#     for i in "$@"; do args="${args} \"${i//\"/\\\"}\""; done
#     singularity exec ... /bin/bash -c "... ${cmd} ${args}"
# -- and that inner string is DOUBLE-quoted, so it escapes backslashes and
# double quotes but NOT `$`. Every `$` in an -e argument is expanded by the
# inner bash before R ever sees it.
#
# MEASURED, both halves:
#   via -e    `y <- x; y$pump_mode <- "N"; class(y)` -> "character"
#   from file  the same three statements            -> "list"
# In this script's own compile check that turned `bp$pump_mode <- "N"` into
# `bp <- "N"`, so ccx_make_logpost() got base_params = "N", the closure bailed
# at its spinup guard, and setup reported
#     log-post at the cold init = -Inf      PER-EVAL 0.0240 s
# ⚠ WHICH READS EXACTLY LIKE A BROKEN PORT AND IS NOT ONE. The port is fine:
# from a file this machine returns -19204.7216 at the cold init, bit-matching
# the Mac. The tells that it was the harness and not the model: 0.024 s/eval is
# far too FAST for a real evaluation (it is the early-return path), and R warned
# "Coercing LHS to a list" once per call -- the `$<-` onto an atomic.
# ⇒ `multistart.sbatch` WAS NEVER AT RISK: it runs a script FILE.
R_TMP_SCRIPT="${SLURM_TMPDIR}/ccx_setup_check.R"

cat > "$R_TMP_SCRIPT" <<'RSCRIPT'
if (!requireNamespace("Rcpp", quietly = TRUE))
  install.packages("Rcpp", repos = "https://cloud.r-project.org",
                   lib = Sys.getenv("R_LIBS_USER"))
cat("Rcpp", as.character(packageVersion("Rcpp")), "OK\n")
RSCRIPT
Rscript --vanilla "$R_TMP_SCRIPT"

# COMPILE CHECK -- the C++ core is compiled by Rcpp::sourceCpp() at load, once
# per process. Prove it builds on this toolchain BEFORE an array of 46 tasks
# each discovers it cannot.
# ⭐ AND GATE THE COLD-INIT VALUE, rather than printing it for a human to eyeball.
# The -Inf above was printed, read, and very nearly believed; a number this
# script KNOWS is a hard comparison, not a report [[gate_bound_matches_its_claim]].
# The bound is RELATIVE and tight because this is an EVALUATION of one fixed
# point: two machines must agree to floating point or the port is broken.
cat > "$R_TMP_SCRIPT" <<'RSCRIPT'
COLD_REF <- -19204.7215567491   # calibration/torch/port_targets.csv, row "cold"
COLD_TOL <- 1e-8                # relative; = MS_EVAL_TOL in the driver
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
t0 <- Sys.time(); ccx_load_cpp()
cat(sprintf("C++ core compiled in %.1f s\n",
            as.numeric(difftime(Sys.time(), t0, units = "secs"))))
bp <- ccx_default_params(); bp$pump_mode <- "N"
stopifnot(is.list(bp), length(bp) > 1)   # the -e mangling, caught at the source
lp <- ccx_make_logpost(base_params = bp); u <- ccx_init_unc()
t1 <- Sys.time(); for (i in 1:20) v <- lp(u)
per <- as.numeric(difftime(Sys.time(), t1, units = "secs")) / 20
rel <- abs(v - COLD_REF) / abs(COLD_REF)
cat(sprintf("log-post at the cold init = %.4f  (Mac %.4f, rel %.2e)\n",
            v, COLD_REF, rel))
if (!is.finite(v) || rel > COLD_TOL)
  stop("SETUP GATE FAILED: this machine does not reproduce the cold init to ",
       COLD_TOL, " relative. Every task in the survey would optimise a ",
       "different objective. STOP AND DIAGNOSE -- and check the harness before ",
       "the model: a `$` eaten by `Rscript -e` produces exactly this symptom.")
cat("SETUP GATE PASSED -- the port reproduces the reference machine.\n")
cat(sprintf("PER-EVAL %.4f s -- the Mac measured 0.15-0.22; SIZE THE ARRAY ON THIS.\n", per))
RSCRIPT
Rscript --vanilla "$R_TMP_SCRIPT"

echo
echo "NEXT: the PREFLIGHT batch -- ~2 min/task, exits 0 without optimising:"
echo "  CCX_MS_PREFLIGHT=1 sbatch --array=0-5,25,45 --time=00:15:00 \\"
echo "    calibration/torch/multistart.sbatch"
echo "  (0-5 are the fixed starts, 25 and 45 exercise the dispersed-draw path)"
