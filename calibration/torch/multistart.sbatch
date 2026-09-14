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
# ⚠ 06:00:00 WAS THE QoS CEILING UNDER `cpu_short` (MaxWall 06:00:00, MaxTRESPU
# cpu=32,mem=120G, verified with `sacctmgr show qos` rather than read off a
# comment). ⛔ ON `cs` IT IS NOT A CEILING AT ALL -- that partition has QoS=N/A
# and MaxTime=UNLIMITED, so the account's `normal` QoS applies with no wall cap.
# The 6 h request is KEPT DELIBERATELY: the arithmetic above is derived against
# it, and a longer wall would need the restart/polish budget re-derived, not just
# the number raised. Likewise `%24` is now the DESIGN's start count rather than
# the 120G memory cap that forced it under cpu_short.
#
# MEMORY. --mem=4G against a MEASURED peak RSS of 213 MB for a full task
# (2026-09-01, /usr/bin/time -l): 19x headroom, deliberately generous because
# the g++ compile of src/ccx_core.cpp runs inside the job's own cgroup. Outputs
# are 1.4 KB per task, so disk is not a consideration at any array size.
# =====================================================================
#SBATCH --job-name=ccx_multistart
#SBATCH --account=torch_pr_1041_general
#SBATCH --partition=cs
#SBATCH --time=06:00:00
#SBATCH --mem=4G
#SBATCH --cpus-per-task=1
# ⛔⛔ PARTITION `cs`, NOT `cpu_short`, AND THIS IS A MEASUREMENT (2026-09-10).
# `cpu_short` spans 186 CPU nodes (`cs*`, AvailableFeatures=(null)) and 74 GPU
# NODES (`gl*` cuda,l40s and `gr*` cuda,rtx6000). SLURM placed 20 of 24 tasks on
# gr105 and THIS SERIAL, SINGLE-THREADED JOB GOT 13-18 % OF A CORE THERE, against
# ~50 % on the CPU node cs608 -- measured as dCPU over a 471 s window at 9-17 min
# in, so steady state and not startup. Neither node was oversubscribed by SLURM
# (cs608 128/128 alloc, load 101; gr105 98/128, load 78), so it is NOT core
# contention; cgroup CPU share reserved for GPU jobs is the likely mechanism,
# which is INFERRED and NOT verified. Array 17316364 was cancelled and
# resubmitted here ⇒ [[eta_in_days_is_not_a_slow_run]] ("read the meter at ~5 min
# and requeue rather than wait").
#
# ⛔ WHY THE PARTITION AND NOT `--exclude`: THE CLUSTER REFUSES `--exclude`.
#     sbatch: error: ** Please do note --exclude=... Please report back to hpc@nyu.edu
# A site job_submit plugin rejects it outright, so the submission FAILS rather
# than degrades. SLURM also has no negative `--constraint`, and the CPU nodes
# advertise NO feature to select positively on -- so choosing a GPU-free
# PARTITION is the only mechanism left. `cs` is exactly the 186 CPU nodes.
#
# ⚠⚠ WHAT CHANGING PARTITION COSTS, checked rather than assumed:
#   * `cs` has QoS=N/A, so the account's `normal` QoS applies -- NO MaxWall and
#     NO MaxTRESPU. `cpu_short`'s QoS caps (MaxWall 06:00:00, cpu=32, mem=120G)
#     DO NOT BIND HERE. ⇒ the `--time=06:00:00` below is now our own choice, not
#     a ceiling, and the `%24` throttle is now a DESIGN choice (24 starts), not
#     the 120G memory cap that forced it under cpu_short.
#   * PriorityTier 1000 against cpu_short's 10000, so `cs` may queue longer.
#     PreemptMode=OFF, so these jobs are still NOT preemptible.
#   * TRES=cpu=23552 over 184 nodes; 6,819 CPUs were idle at resubmission.
#
# ⚠ THE GPU PLACEMENT WAS NEVER A CORRECTNESS ISSUE, and that was checked: the
# PORT GATE passed on all 24 tasks INCLUDING the 20 on gr105, rel 3.92e-10
# against a 1e-8 tolerance. Same arch, same compiled core -- only throughput.
# ⚠ NOR A PREEMPTION ISSUE: cpu_short is PreemptMode=OFF at PriorityTier=10000.
#
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
# ⛔ NO DEFAULT SINCE 2026-09-14: the structure label is the FIRST axis of the objective
# and every array since round 5 has needed it stated. A default of `hilda` would have
# let the eq-cell wave run 33 names against a model with no cell -- the port gate
# refuses that in ~3 s, but a gate is the backstop, not the plan (the driver's rule).
if [ -z "${CCX_MS_STRUCT:-}" ]; then
  echo "multistart.sbatch: CCX_MS_STRUCT is NOT SET (hilda | hilda_eq | hilda_tr). State the objective's label on the command line." >&2
  exit 1
fi
export CCX_MS_STRUCT
# a CCX_MS_ID exported in the submitting shell would reach every task through sbatch's
# environment export and collapse the whole array onto ONE id and one checkpoint (the
# driver reads CCX_MS_ID before SLURM_ARRAY_TASK_ID). Never inherit it here.
unset CCX_MS_ID
# ⛔⛔ 2026-09-10: THE SEASONAL MIXED LAYER IS THE SECOND LABEL AXIS, AND IT IS
# THE ONE THIS FILE FORGOT. Jobs 17318015 + 17325832 were launched as the
# ROUND-6 refit and ran BOTH rounds at seas_ml = 0, because `seas_ml` is a base
# parameter (not a fitted name), the driver built a bare ccx_default_params(),
# and nothing here said otherwise. The result is the new seas_ml = 0 baseline,
# `hilda31p`; the round-6 refit is the one THIS setting runs. The driver now
# REFUSES to start with the variable unset, records it in every start file, and
# the port gate refuses a port_targets.csv measured at the other value -- so
# the CSV must be regenerated with CCX_MS_SEAS_ML=1 before this can pass.
# ⚠ AT seas_ml = 1 THE OBJECTIVE IS -Inf WHEREVER h_ml EXCEEDS ~76 m (the P8
# geometry guard): the 08-31e new-basin reference (143.9 m) and the 09-10
# second basin (164 m) are both INFEASIBLE there, so the reference set in the
# driver / make_port_targets.R has to be re-ruled before a seas_ml = 1 array.
export CCX_MS_SEAS_ML="${CCX_MS_SEAS_ML:-1}"
# ⭐ THE DISPERSION IS SET EXPLICITLY FOR ROUND 6 (2026-09-10, ruled). The driver
# measures its default sd from the u-space separation of its two reference
# modes, and those are now `hilda31p` and `hilda31` -- the same basin's
# before/after, a few tenths apart -- so the measured value would survey almost
# nothing. 1.0452 is the sd the 09-08e and 09-10 arrays ran at (measured then
# between the 08-30 incumbent and the 08-31e basin over the fitted pool), i.e.
# the dispersion that found the current canonical. The outdir names it.
export CCX_MS_SPREAD="${CCX_MS_SPREAD:-1.0452}"
# ⭐⭐ 2026-09-09x: THE OBJECTIVE'S **SPINUP** CHANGED -- the PERIODIC (limit-cycle)
# spinup was adopted (Marcus), so `ccx_make_logpost()` now seeds every transient
# from `ccx_periodic_spinup()`. ⛔⛔ THE PARAMETER SET IS UNCHANGED AT 31 NAMES,
# WHICH IS EXACTLY THE 09-02 HAZARD THIS BLOCK WAS WRITTEN ABOUT: the driver's
# checkpoint guard refuses a mismatched `param_names`, and it would NOT refuse the
# 09-08e files -- their 31 names are identical. What protects us is the
# `ref_logpost` stamp, which moved; the NEW OUTDIR is the clean answer and the
# guard is the backstop, not the plan. The name says `periodic` for that reason.
# 2026-09-10: `_seasml${CCX_MS_SEAS_ML}` -- seas_ml moves the objective at a CONSTANT
# 31 names, so the directory must say it; the seas_ml = 0 rounds live in
# multistart_20260909x_hilda31_periodic (no suffix -- it predates the axis).
# 2026-09-11 (5): ROUND 6b -- the SAME arm re-fitted under the corrected
# concentration observables (annual mean over the box's mass at the time,
# [[seasonal_box_observable_artefact]]). Same 31 names, same seas_ml = 1, same
# spread; the OBJECTIVE moved (+20.7 on the incumbent target at seas_ml = 1),
# so the 09-10 round-6 checkpoints are another objective's and the directory
# says so. port_targets.csv regenerated at seas_ml = 1 on the Mac, commit c0bf185.
#     sbatch --array=0-23%24 calibration/torch/multistart.sbatch
# 2026-09-12: ROUND 7 -- the REFIT UNDER THE 09-12 OBJECTIVE (rulings (c)+(d): annual-mean
# isotope pins in the periodic spinup, concentrations read on the model's own rows, the IntCal
# window ending at 1941, no pre-run ice rows; +43.2 on the incumbent's stored logpost across
# the two restamps). Same 31 names, same seas_ml = 1, same spread; references RE-RULED to
# hilda31s (incumbent) / hilda31p (new basin), both registered; port_targets.csv regenerated
# at seas_ml = 1 on the Mac. The R core is 1.5x faster than round 6b (marshal-once, bit-identical),
# so the wall arithmetic above is now conservative.
#     CCX_MS_PREFLIGHT=1 sbatch --array=0-5,25,45 --time=00:15:00 calibration/torch/multistart.sbatch
#     sbatch --array=0-23%24 calibration/torch/multistart.sbatch
# 2026-09-13: ROUND 7 ADOPTED as hilda31s2. THE THIRD LABEL AXIS: CCX_MS_PIN holds fitted
# names at values and removes them from the fitted set ("" = free arm; the driver,
# make_port_targets.R and the port gate all read it, and the outdir carries it).
#   C' -- the pCO2-side entrainment SHIM pinned to 0 against hilda31s2 (assessment
#   2026-09-12 option C'; P12's original promise): does the real seasonal mixed layer
#   carry the SH ocean limb's DIC side on its own? 30 free parameters; references
#   hilda31s2 / hilda31p (both evaluated with the shim at 0); port_targets.csv
#   regenerated on the Mac with CCX_MS_PIN=ent_seas_amp_SH=0.
#     CCX_MS_PIN=ent_seas_amp_SH=0 CCX_MS_PREFLIGHT=1 sbatch --array=0-5,25,45 --time=00:15:00 calibration/torch/multistart.sbatch
#     CCX_MS_PIN=ent_seas_amp_SH=0 sbatch --array=0-23%24 calibration/torch/multistart.sbatch
# 2026-09-13 (i): THE EQUATORIAL CELL'S ARRAY (Fix B proper; prereg
#   notes/prereg_2026-09-13g_equatorial_cell_build.md, built 09-13h). The structure label
#   is `hilda_eq` -- HILDA's block PLUS the cell's observed geometry read from
#   data/obs_eq_cell.rds (the bundle ships data/) -- and the table gained the cell's two
#   fitted names w_eq / gamma_eq in the launch commit (31 -> 33; 32 free under the C'
#   pin, which is KEPT: ent_seas_amp_SH = 0). Both reference files are 31-name vectors:
#   the driver migrates the pair to 0 (what they RAN) and SEEDS it at init (27 Sv, 1 per
#   index = the probe's PE1 point); dispersed starts draw the pair like every other
#   coordinate. References hilda30c (incumbent, under the pin) / hilda31p (new basin).
#   port_targets.csv regenerated on the Mac under this label (incumbent -1548.95 at the
#   seeded point: -122.7 vs its stored logpost, of which ~-86 is the eq_b1 row at z +13
#   -- the array's tension, PE8). Mac preflight ids 0/1/2/6: port VERIFIED rel <= 2.4e-14,
#   0.195 s/eval (the cell costs nothing measurable over C'), so the 300/360 arithmetic
#   above stands -- RE-READ IT from the Torch preflight before the wave, as always.
#   ⛔ CCX_MS_STRUCT MUST BE GIVEN (no default since 09-14: the sbatch exits 1 without it).
#   The preflight covers the PRODUCTION ids 0-23 (review 09-14: 25/45 exercised the draw
#   path but never the 18 dispersed ids that actually run; a per-id draw failure would
#   have surfaced only in the wave). 24 x ~3 min at --time=00:15:00.
#     CCX_MS_STRUCT=hilda_eq CCX_MS_PIN=ent_seas_amp_SH=0 CCX_MS_PREFLIGHT=1 sbatch --array=0-23 --time=00:15:00 calibration/torch/multistart.sbatch
#     CCX_MS_STRUCT=hilda_eq CCX_MS_PIN=ent_seas_amp_SH=0 sbatch --array=0-23%24 calibration/torch/multistart.sbatch
# 2026-09-14 (f): THE TROPICAL BOX'S ARRAY (the cell's second build; prereg
#   notes/prereg_2026-09-14f_tr_box_build.md). Label `hilda_tr` = hilda_eq's block PLUS the
#   box's geometry read from data/obs_tr_box.rds (in the bundle) and the three SST overrides
#   (residual ML 17.18/15.35, cell re-based 26.33). NO new fitted name (33 stays 33; q_tr is
#   structural 0, R4). ⚠ Rulings R5 (sst_tr_enso on/0) and R6 (kz_tr_frac) are OWED before
#   this array is launched; port_targets.csv must be regenerated under `hilda_tr` first.
#     CCX_MS_STRUCT=hilda_tr CCX_MS_SEAS_ML=1 CCX_MS_PIN=ent_seas_amp_SH=0 CCX_MS_PREFLIGHT=1 sbatch --array=0-23 --time=00:15:00 calibration/torch/multistart.sbatch
export CCX_MS_PIN="${CCX_MS_PIN:-}"
PIN_LABEL=""; if [ -n "$CCX_MS_PIN" ]; then PIN_LABEL="_pin_$(echo "$CCX_MS_PIN" | tr ',' '_')"; fi
# THE OUTDIR CARRIES EVERY LABEL AXIS (struct, seas_ml, pins, spread) since 2026-09-13 (i);
# the C' directory predates the struct axis in the name (multistart_20260913_cprime_seasml1_pin_..._sd1.0452).
export CCX_MS_OUTDIR="${CCX_MS_OUTDIR:-$CCX_PROJ_DIR/calibration/output/multistart_20260913_eqcell_${CCX_MS_STRUCT}_seasml${CCX_MS_SEAS_ML}${PIN_LABEL}_sd${CCX_MS_SPREAD}}"

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
echo "CCX_MS_STRUCT $CCX_MS_STRUCT   CCX_MS_SEAS_ML $CCX_MS_SEAS_ML   CCX_MS_SPREAD $CCX_MS_SPREAD   CCX_MS_PIN '${CCX_MS_PIN}'"

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
