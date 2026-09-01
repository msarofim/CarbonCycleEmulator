#!/bin/bash
# =====================================================================
# multistart.sbatch -- ONE dispersed start per array task.
#
# ⚠ SUBMITTED BY MARCUS, NOT BY CLAUDE. Torch needs the NYU VPN, the gateway
# password, Duo, and a Microsoft device-code at login.torch; none of that is
# scriptable from here.
#
# ⛔ RUN THE PREFLIGHT BATCH FIRST AND READ IT (~2 min/task, exits 0 without
# optimising):
#     CCX_MS_PREFLIGHT=1 sbatch --array=0-5,25,45 --time=00:15:00 \
#       calibration/torch/multistart.sbatch
# Ids 0/1/2 are the cold init, the 08-30 incumbent and the 08-31e new basin;
# ids 3/4/5 are the ENSO-SEEDED carries of the two known basins into the
# 25-parameter space (see run_dispersed_multistart.R's header -- the migrated
# files are NOT modes of this space, so the survey has to produce its own
# baseline). 25 and 45 are dispersed ids from inside the production range, so
# the batch covers the draw path as well as the warm one.
# EVERY task carries a PORT GATE against logposts measured on the Mac and
# shipped in calibration/torch/port_targets.csv. If it fails, every start in the
# survey would be optimising a different objective. Do not scale past it.
#
# THEN the survey, THROTTLED -- %10 caps how many run at once:
#     sbatch --array=0-45%10 calibration/torch/multistart.sbatch
# ⚠ ROUND 2 IS **NOT** THE SAME ARRAY AGAIN. Re-submit only the fixed starts and
# the best dispersed ids from round 1's summary.csv -- resuming all 40 spends
# three times the fairshare converging tasks that are already 50+ log-units
# behind. See calibration/torch/README.md, "Two rounds, and the second is not
# the first repeated".
#
# WALL -- THE ARITHMETIC, BECAUSE A TIMEOUT COSTS FAIRSHARE AND A CLEAN EXIT
# DOES NOT. This job REQUESTS 4 h = 240 min (--time above), which is the cap the
# arithmetic below is against. ⚠ THAT IS A REQUEST, NOT THE PARTITION'S CEILING:
# cpu_short's QoS allows 6 h at cpu=32 per user [[torch_qos_is_the_real_cap]], so
# a round 2 may raise --time and re-derive this block. The task's OWN budget
# (CCX_MS_WALL_MIN) is 180, so it stops the optimiser, checkpoints and exits 0
# with ~57 min to spare -- "OUT OF TIME" is a normal exit here, NOT a SLURM kill,
# and re-submitting the same array RESUMES each task from its checkpoint.
#
#   worst case: the guard starts a restart only if elapsed + 1.5 x projection
#   still fits 180, so a restart can begin at 180 - 1.5p and, if it actually
#   takes k x p, ends at 180 + (k - 1.5)p. With p ~ 37 min (6,000 evals at the
#   ~0.37 s/eval a 2x-slower-than-Mac node implies) it takes k > 3.0 -- a
#   THREEFOLD overrun of a measured projection -- to reach the 240 min cap.
#   The worst contention ever measured on this model was 1.61x.
#
# MEMORY. --mem=4G against a MEASURED peak RSS of 213 MB for a full task
# (2026-09-01, /usr/bin/time -l): 19x headroom, deliberately generous because
# the g++ compile of src/ccx_core.cpp runs inside the job's own cgroup. Outputs
# are 1.4 KB per task, so disk is not a consideration at any array size.
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
# ⚠ THE #SBATCH DIRECTIVES ABOVE MUST BE LITERAL -- SLURM parses them before any
# shell runs, so --output cannot be a variable. The BODY is parameterised so
# this exact file can be dry-run off Torch: an untestable script is an unverified
# one, and everything below except `module load` was smoke-tested locally on
# 2026-09-01 by setting CCX_PROJ to an extracted copy of the bundle.
#
# ⛔ THE NAME IS `CCX_PROJ_DIR`, NOT `PROJ`, AND IT IS `readonly` (2026-09-01e).
# Round 1 wrote its 10 result files into ANOTHER PROJECT'S TREE because Torch's
# ~/.bashrc exports `PROJ=/scratch/ms17839/SLR-RFF-BRICK` and this script sourced
# it between setting PROJ and using it:
#     PROJ=...CarbonCycleEmulator ; cd "$PROJ" ; source ~/.bashrc ; ...$PROJ...
# The `cd` was correct ONLY because it happened to precede the source -- ⚠ AN
# ORDERING THAT WORKS IS NOT AN ORDERING THAT IS SAFE. Nothing errored; the wrong
# path was printed once per task, in a line nobody reads until they go looking
# for the outputs. Three structural fixes, because one of them is a convention
# and conventions rot: (1) A SCRIPT MAY NOT NAME A VARIABLE THE ENVIRONMENT IT
# SOURCES ALSO OWNS -- so it is renamed; (2) `readonly` makes a clobber a HARD
# ERROR rather than a silent rebind [[split_name_must_hard_error]]; (3) the write
# path is computed BEFORE the source and ASSERTED to be inside the project after
# it. `CCX_PROJ` stays the override INPUT (that is what the local dry-run sets).
CCX_PROJ_DIR="${CCX_PROJ:-/scratch/ms17839/CarbonCycleEmulator}"
readonly CCX_PROJ_DIR
cd "$CCX_PROJ_DIR"
mkdir -p logs calibration/output

# ⚠ `mkdir -p logs` HERE DOES NOT CREATE THE DIRECTORY --output WRITES TO.
# SLURM opens that file BEFORE this script starts, so if logs/ is absent the
# task dies with no log to say why. `setup_torch.sh` creates it; that is why
# setup is not optional even once Rcpp is installed.

# ⚠ THE DIRECTORY NAMES THE PARAMETER SET. A `u` vector is meaningless without
# it, and this project moved the set twice in three days; the driver's resume
# refuses a foreign checkpoint, but not mixing them is the cleaner answer.
# ⛔ COMPUTED **BEFORE** THE `source ~/.bashrc` BELOW -- see the CCX_PROJ_DIR note
# above. This line is the one that silently wrote round 1 into SLR-RFF-BRICK.
export CCX_MS_OUTDIR="${CCX_MS_OUTDIR:-$CCX_PROJ_DIR/calibration/output/multistart_20260901_enso25}"

# NYU's /etc/bashrc references an unbound BASHRCSOURCED; without the sandwich
# `set -u` kills the job at startup.
if [ -z "${CCX_SKIP_MODULES:-}" ]; then
  set +u; source ~/.bashrc; set -u
  module load r/4.5.1
  export R_LIBS_USER=/scratch/ms17839/Rlibs/4.5
fi

# ⛔ AND RE-`cd`, for the same reason the assert is placed here: a sourced rc may
# change the working directory as easily as it may rebind a name, and the
# `Rscript calibration/...` at the bottom is a RELATIVE path. Cheap, idempotent,
# and it stops the last thing this block's ordering was quietly relying on.
cd "$CCX_PROJ_DIR"

# ⛔ ASSERT THE WRITE PATH, AFTER the source -- a gate placed before the hazard
# it guards is not a gate. An escape exists because writing outside the project
# is a legitimate thing to want ONCE, deliberately, and never by accident.
case "$CCX_MS_OUTDIR" in
  "$CCX_PROJ_DIR"/*) : ;;
  *)
    if [ -z "${CCX_MS_OUTDIR_EXTERNAL:-}" ]; then
      echo "FATAL: CCX_MS_OUTDIR is OUTSIDE the project and CCX_MS_OUTDIR_EXTERNAL is unset." >&2
      echo "  CCX_MS_OUTDIR = $CCX_MS_OUTDIR" >&2
      echo "  CCX_PROJ_DIR  = $CCX_PROJ_DIR" >&2
      echo "  This is the 2026-09-01 PROJ clobber. Results would land in another tree" >&2
      echo "  and NOTHING would error. Set CCX_MS_OUTDIR_EXTERNAL=1 only on purpose." >&2
      exit 1
    fi
    echo "⚠ CCX_MS_OUTDIR is OUTSIDE $CCX_PROJ_DIR, allowed by CCX_MS_OUTDIR_EXTERNAL=1:" >&2
    echo "  $CCX_MS_OUTDIR" >&2
    ;;
esac
echo "CCX_PROJ_DIR  $CCX_PROJ_DIR"
echo "CCX_MS_OUTDIR $CCX_MS_OUTDIR"

# MEASURED 2026-09-01: `Rscript --vanilla` implies --no-environ, which suppresses
# .Renviron FILES but NOT an exported R_LIBS_USER -- the library still lands in
# .libPaths(). Checked rather than assumed, because if it were wrong every task
# in the array would fail to find Rcpp for the same invisible reason.

# ONE THREAD. The work is a serial Nelder-Mead; BLAS threads buy nothing here
# and cost 11 h vs 2 h17 elsewhere when they oversubscribe. [[pin_blas_threads]]
export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1

export CCX_MS_WALL_MIN="${CCX_MS_WALL_MIN:-180}"        # 3 h of the 4 h cap; see WALL above
export CCX_MS_RESTARTS="${CCX_MS_RESTARTS:-3}"
export CCX_MS_CYCLES="${CCX_MS_CYCLES:-6}"
export CCX_MS_MAXIT="${CCX_MS_MAXIT:-6000}"

echo "host $(hostname)  task ${SLURM_ARRAY_TASK_ID}  $(date -Is)"
Rscript --vanilla calibration/run_dispersed_multistart.R
echo "done $(date -Is)"
