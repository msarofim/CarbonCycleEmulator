#!/bin/bash
# =====================================================================
# multistart.sbatch -- ONE dispersed start per array task.
#
# ⚠ SUBMISSION IS MARCUS'S CALL, AND THE AUTHENTICATION IS HIS TOO. Torch needs
# the NYU VPN, the gateway password, Duo, and a Microsoft device-code at
# login.torch; none of that is scriptable. ⭐ BUT ONCE A ControlMaster IS LIVE
# the channel is reusable, and Claude submitted the 2026-09-03 run over exactly
# that, on Marcus's explicit instruction. The constraint is AUTHENTICATION, not
# authorship -- check the machine, not this comment
# ([[runnable_is_not_undrivable]]).
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
# WALL -- RE-DERIVED 2026-09-10 FROM A PREFLIGHT MEASURED ON THE NODES, not from
# the Mac. Adopting the periodic spinup (2026-09-09x) made every evaluation ~3x
# more expensive, which invalidated the pre-adoption arithmetic that stood here.
# ⛔ The failure it would have caused is SILENT: the restart guard starts a
# restart only while `elapsed + 1.5p` still fits CCX_MS_WALL_MIN, so a `p` that
# grows past ~2/3 of the budget collapses the multi-restart design to a single
# pass -- and the task still EXITS 0. Not a timeout, and nothing announces it.
#
# MEASURED (preflight job 17316317, ids 0-5,12,20, 2026-09-10, cs608 + gr105):
#   0.5938 - 1.0796 s/eval  =>  a 6000-eval pass (CCX_MS_MAXIT) takes 59.4 - 108.0 min.
#   Port VERIFIED on all 8 tasks, rel 3.0e-10 to 5.4e-09.
#
# THE ARITHMETIC, at the WORST measured rate (p = 108.0 min), which is the one
# that has to hold:
#   * budget CCX_MS_WALL_MIN = 300 of a 360 min request (--time=06:00:00).
#   * the guard can still START a restart up to elapsed = 300 - 1.5p = 138 min,
#     so restarts are reachable rather than shut out (at WALL_MIN 180 they were
#     shut out after 18 min -- that is why 180 is no longer used).
#   * a restart begun at the limit and actually taking k x p ends at
#     300 + (k - 1.5)p; reaching the 360 cap needs k = 2.06, i.e. a TWOFOLD
#     overrun of a measured projection. The worst contention ever measured on
#     this model is 1.61x, so the cap is not reachable on any observed behaviour.
#   * passes available inside the budget: 300/108 = 2.8 at the worst rate and
#     300/59.4 = 5.0 at the best, which is what CCX_MS_RESTARTS = 3 wants.
#
# ⚠ 06:00:00 IS THE QoS CEILING, NOT A PREFERENCE -- VERIFIED ON THE MACHINE
# rather than read off this comment ([[runnable_is_not_undrivable]]): `sacctmgr
# show qos` gives cpu_short MaxWall 06:00:00, MaxTRESPU cpu=32,mem=120G. That
# TRES cap is also why the array throttle is %24 and not higher: 24 tasks x
# --mem=4G = 96G fits 120G, while %32 would request 128G and never start.
#
# MEMORY. --mem=4G against a MEASURED peak RSS of 213 MB for a full task
# (2026-09-01, /usr/bin/time -l): 19x headroom, deliberately generous because
# the g++ compile of src/ccx_core.cpp runs inside the job's own cgroup. Outputs
# are 1.4 KB per task, so disk is not a consideration at any array size.
# =====================================================================
#SBATCH --job-name=ccx_multistart
#SBATCH --account=torch_pr_1041_general
#SBATCH --partition=cpu_short
#SBATCH --time=06:00:00
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

# ⚠ THE DIRECTORY NAMES THE PARAMETER SET **AND THE OBJECTIVE**. A `u` vector is
# meaningless without the set it was encoded under, and this project moved the
# set twice in three days -- but on 2026-09-02 it moved the OBJECTIVE three
# times at a CONSTANT 25 names (T-dependent air-sea 13C alphas, the one-way GPP
# ENSO term, and Ruling A's demeaning), which a set-only name cannot
# distinguish. Hence `_demean25`, not `_enso25`: the 09-01 checkpoints have 25
# matching names and would have been RESUMED into a different objective.
# The driver now refuses that too (it stamps `ref_logpost` into every checkpoint
# and re-reads it), but a directory that cannot collide is the cleaner answer
# and the guard is the backstop, not the plan.
# ⛔ COMPUTED **BEFORE** THE `source ~/.bashrc` BELOW -- see the CCX_PROJ_DIR note
# above. This line is the one that silently wrote round 1 into SLR-RFF-BRICK.
# ⭐ 2026-09-03: `_ent26`. `ent_seas_amp_SH` entered CCX_PARAM_TABLE, so this is
# a 26-NAME space and the 09-02 checkpoints in `_demean25` are 25-name files.
# The driver's checkpoint guard would REFUSE them by `param_names` -- correctly,
# and loudly -- but a directory that cannot collide is the cleaner answer and
# the guard is the backstop, not the plan.
# 2026-09-07f: the HILDA-structure refit, round 3 (30 parameters: + pump_hs_gcm2 with a literature prior;
# objective #10 + #11 HS-surface rows; corrected gradient rows). CCX_MS_STRUCT selects
# the declared structure in BOTH the driver and the port targets; the outdir
# names the parameter set and the structure, as the 09-01k rule requires.
# 2026-09-08d: round 4 (31 parameters: + u_hs FREED under the observed overturning,
# lognormal median 21.84 m/yr; h_ml's flat prior replaced by the Holte mean/max
# lognormal). Round-3 checkpoints (30 names) are refused by the guard; new outdir.
# 2026-09-08e: round 5 (31 parameters; + the OBSERVATION prior on hs_asx_frac, 0.653 x 0.15 log-sd:
# round 4 rebuilt the sink there). 24 starts (6 fixed + 18 dispersed) at %24 -- one wave.
#     sbatch --array=0-23%24 calibration/torch/multistart.sbatch
# 2026-09-10: ROUND 6 under the ADOPTED PERIODIC SPINUP. 24 starts (6 fixed + 18
# dispersed) at %24, one wave, --time and CCX_MS_WALL_MIN re-derived from the
# preflight above. Objective: MAP as usual (Marcus 09-09x -- "likelihood-only"
# meant COMPARE on likelihood, not fit without priors); 31 par, ent_seas_amp_SH KEPT.
#     sbatch --array=0-23%24 calibration/torch/multistart.sbatch
export CCX_MS_STRUCT="${CCX_MS_STRUCT:-hilda}"
# ⭐⭐ 2026-09-09x: THE OBJECTIVE'S **SPINUP** CHANGED -- the PERIODIC (limit-cycle)
# spinup was adopted (Marcus), so `ccx_make_logpost()` now seeds every transient
# from `ccx_periodic_spinup()`. ⛔⛔ THE PARAMETER SET IS UNCHANGED AT 31 NAMES,
# WHICH IS EXACTLY THE 09-02 HAZARD THIS BLOCK WAS WRITTEN ABOUT: the driver's
# checkpoint guard refuses a mismatched `param_names`, and it would NOT refuse the
# 09-08e files -- their 31 names are identical. What protects us is the
# `ref_logpost` stamp, which moved; the NEW OUTDIR is the clean answer and the
# guard is the backstop, not the plan. The name says `periodic` for that reason.
export CCX_MS_OUTDIR="${CCX_MS_OUTDIR:-$CCX_PROJ_DIR/calibration/output/multistart_20260909x_hilda31_periodic}"

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

export CCX_MS_WALL_MIN="${CCX_MS_WALL_MIN:-300}"        # 5 h of the 6 h cap; see WALL above
export CCX_MS_RESTARTS="${CCX_MS_RESTARTS:-3}"
export CCX_MS_CYCLES="${CCX_MS_CYCLES:-6}"
export CCX_MS_MAXIT="${CCX_MS_MAXIT:-6000}"

echo "host $(hostname)  task ${SLURM_ARRAY_TASK_ID}  $(date -Is)"
Rscript --vanilla calibration/run_dispersed_multistart.R
echo "done $(date -Is)"
