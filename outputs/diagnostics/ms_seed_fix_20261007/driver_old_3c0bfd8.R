# =====================================================================
# run_dispersed_multistart.R -- ONE dispersed start per invocation, so N of
# them are an embarrassingly parallel array rather than a serial queue.
#
# WHY THIS FILE EXISTS. `handoff_2026-08-31e_the_basin.md` §4/§8.6:
#   * the incumbent and the 08-31e polished mode are TWO BASINS, separated by a
#     21.53-log-unit barrier on the straight u-path, so a warm-started local
#     search CANNOT cross between them;
#   * the polished basin is CONVERGED at -1496.01 and beats the incumbent by
#     +52.0 -- but that surveys ONE basin, the one the probe stumbled into;
#   * ⇒ "the DISPERSED MULTI-START remains the load-bearing experiment", and it
#     now has a proper incumbent to beat.
# `run_modefind_pump_arms.R` cannot be that experiment: it is ONE warm-started
# chain per arm, 203 min for four restarts, serial. The restructuring is the
# whole point -- it is what makes Torch win, and the standing Torch verdict says
# a straight port of the serial driver is MEASURED TO LOSE.
#
# ⛔ THIS DRIVER ADOPTS NOTHING AND WRITES NO MODE FILE ANY OTHER CODE READS.
# It writes `start_<id>.rds` into its own output directory. `CCX_MODE_CANONICAL`
# is untouched; ranking and adoption are separate steps and the adoption one is
# Marcus's.
#
# THE SIX FIXED STARTS. Ids 0-5 are not dispersed:
#   id 0  the COLD hand-set init            -- the control the refits all quote
#   id 1  the INCUMBENT -- since 2026-09-10 `hilda31p` (see MS_REF_INC below)
#   id 2  the NEW BASIN -- since 2026-09-10 `hilda31`, by path (see MS_REF_NEW)
#   id 3  the INCUMBENT + the ocean ENSO pair at the objective's own conditional
#         optimum
#   id 4  the NEW BASIN + the same
#   id 5  the NEW BASIN + the OBSERVATION-implied ENSO partition (land x1.734,
#         ocean +0.326 each), which the objective conditionally RESISTS
# ⚠ THE TARGETS COME FROM FILES THIS SCRIPT DID NOT WRITE ([[gate_reads_its_own_output]]):
# they are read out of the two mode files, not restated as literals here, and a
# port that silently changes the objective fails them. Run ids 0-5 FIRST, before
# any large array.
#
# ⛔ RE-CUT 2026-09-01k FOR THE 25-PARAMETER MODEL, AND IDS 3-5 ARE THE RE-CUT.
# Ids 1 and 2 USED to be "warm starts at points ALREADY converged on the Mac, so
# on any machine they must return -1548.01 / -1496.01 to within the optimiser's
# own noise". THAT IS NO LONGER TRUE and the sentence had to go: after the ENSO
# split both files are MIGRATED 21-parameter vectors carrying an ocean pair of
# EXACTLY 0, and 0 is not where the objective wants it. Measured on the shipped
# objective, 2026-09-01: the migrated incumbent is -1551.1222 and the migrated
# new basin -1500.0507, and moving the ocean pair to +0.10 in each hemisphere --
# nothing else touched -- is worth +1.9087 at the new basin and +0.2947 at the
# incumbent. So NEITHER is a mode of this space, and a survey that ranked a
# third basin against -1496.01 would be comparing a 25-parameter optimum against
# a 21-parameter migrated point ([[like_for_like_forcing]]).
# ⇒ THE BASELINE A SURVEY IS JUDGED AGAINST MUST BE PRODUCED BY THE SURVEY, on
# the same machine and the same objective. That is what ids 3-5 are for, and it
# is why they are worth three tasks: they carry the two known basins into the
# 25-parameter space rather than importing a number from a run that predates it.
# Ids 1 and 2 stay as the un-seeded controls -- the pair says what the seeding
# was worth.
#
# THE DISPERSION SCALE IS MEASURED, NOT INVENTED. Every prior in
# CCX_PARAM_TABLE has O(1) scale in the unconstrained coordinate by construction
# (see ccx_prior_z() in R/calibrate.R), so a Gaussian in u IS a prior-scale
# dispersion. Its sd defaults to the per-coordinate RMS distance between the TWO
# KNOWN BASINS -- computed here from their own mode files, so it moves when they
# do -- because that is the separation a survey has to resolve to be worth
# running. ⚠ IT IS STILL A METHODOLOGICAL CHOICE (project rule: flag, do not
# silently resolve). `CCX_MS_SPREAD` overrides it and the value used is printed
# and stored in every output file.
#
# ⛔ AND THE POOL IT IS AVERAGED OVER IS NOT ALL 25 COORDINATES (fixed
# 2026-09-01k). A coordinate that BOTH reference points got by MIGRATION rather
# than from a fit carries no basin separation at all: the ocean ENSO pair is
# EXACTLY 0 in both files because the mechanism did not exist when either was
# fitted, and the land pair differs by 0.0100 only because it is the retired
# scalar cut in half. Averaging four such coordinates into the RMS multiplied
# the whole dispersion by sqrt(21/25) = 0.9165 -- so the survey drew every
# coordinate 8.4 % NARROWER than the measurement says, for a bookkeeping reason.
# Measured: RMS over all 25 = 0.9592, over the 21 that at least one reference
# point FITTED = 1.0466. The pool is now the second, and the excluded names are
# printed, so the next split fixes itself instead of quietly shrinking the
# survey again ([[recorded_but_never_restored]] -- a value derived from a field
# whose meaning changed).
# ⚠ WHAT THIS DOES NOT DO IS GIVE THE FOUR ENSO COORDINATES A SCALE OF THEIR
# OWN. They are dispersed at the SHARED pooled sd, which is an assertion, not a
# measurement: their own separation is structurally zero and no second basin
# exists to measure it against. `diag_enso_objective_leverage.R` (09-01j) is the
# check that this is not silly -- at ~1.05 they land 6-9 conditional sds out,
# against 325-430 for the stiffest coordinates, so they are genuinely dispersed
# and are not what makes a dispersed start expensive.
#
# Usage
#   CCX_MS_ID=7 Rscript calibration/run_dispersed_multistart.R
#   (or let it read SLURM_ARRAY_TASK_ID)
# Knobs, all env, all printed when overridden:
#   CCX_MS_ID        start index; else SLURM_ARRAY_TASK_ID; else 0
#   CCX_MS_OUTDIR    output dir (default calibration/output/multistart_<date>)
#   CCX_MS_RESTARTS  Nelder-Mead restarts per cycle          (default 3)
#   CCX_MS_CYCLES    NM-then-BFGS cycles                     (default 6)
#   CCX_MS_MAXIT     NM iterations per restart               (default 6000)
#   CCX_MS_BUDGET_MIN  the budget in MINUTES on CCX_MS_CLOCK; stop cleanly (default 180; both runners
#                    export 300). Its pre-2026-10-05 name CCX_MS_WALL_MIN is still read.
#   CCX_MS_CLOCK     the budget's clock: wall | cpu          (default wall; the Mac runner exports cpu)
#   CCX_MS_SPREAD    dispersion sd in u-space               (default: measured)
#   CCX_MS_SEED      base seed; start k uses SEED + k        (default 2026)
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
# ---- PINS (2026-09-13). CCX_MS_PIN="name=value[,name=value]" holds fitted names at
# values and REMOVES them from the fitted set for this whole process (ccx_apply_pins);
# "" = a free arm. Applied before anything reads CCX_PARAM_NAMES. Recorded in every
# checkpoint and start file, in the outdir name, and GATED against the port targets
# (a CSV measured with other pins is another objective).
# ---- THE GATE (2026-09-30; CCX_PARAM_GATED): a structure that OPENS it (the D2 / D3
# label, "hilda_csl3v0kaidgb") fits four more names. Applied BEFORE the pins and before
# anything reads CCX_PARAM_NAMES; a holding structure (every older label) is a no-op, so
# every older array is byte-for-byte the run it was. Unset CCX_MS_STRUCT is "" here (a
# no-op) and is refused below by .ms_env_required() with the driver's own message.
MS_GATE <- ccx_apply_gate(Sys.getenv("CCX_MS_STRUCT", ""))
if (length(MS_GATE)) cat(sprintf("GATE OPEN (structure '%s'): %s enter the fitted set\n",
                                 Sys.getenv("CCX_MS_STRUCT"), paste(MS_GATE, collapse = ", ")))
MS_PINS <- ccx_parse_pins(Sys.getenv("CCX_MS_PIN", ""))
invisible(ccx_apply_pins(MS_PINS))
if (length(MS_PINS)) cat(sprintf("PINNED (removed from the fitted set, held in the base): %s -> %d free parameters\n",
                                 paste(sprintf("%s = %s", names(MS_PINS), MS_PINS), collapse = ", "), length(CCX_PARAM_NAMES)))
source(ccx_path("calibration", "lib_run_inputs.R"))
source(ccx_path("calibration", "lib_ms_deadline.R"))   # the in-restart deadline (option A, 2026-10-05)
ccx_require_run_inputs()   # BEFORE the budget's clock starts, and before any target is written

# ---- named constants ------------------------------------------------
MS_ARM        <- "N"          # the shipped arm; see run_modefind_pump_arms.R
MS_SEED_BASE  <- 2026
# ⛔⛔ THE PENALTY MUST BE WORSE THAN THE START, AND A FIXED 1e6 IS NOT (2026-09-10,
# round-6 array 17343694, ids 9/12/23). Three dispersed starts sat at -7.4e6 /
# -5.4e6 / -4.0e6, Nelder-Mead stepped into the infeasible region (the seas_ml=1
# P8 wall and non-converging periodic spinups return -Inf), the wrapper handed
# back 1e6 -- which as a log-post of -1e6 is BETTER than the start -- and the
# simplex collapsed onto that flat plateau: "gain 6428918.8", "CONVERGED" at
# exactly -1000000.0000, PORT GATE (b) satisfied, exit 0, in 2.3 minutes. A DEAD
# task that reported success. So: MS_PENALTY_FLOOR is the old constant, and the
# penalty actually used is set AFTER the start is evaluated, at 10 x |start|, so
# no feasible point in play can lose to an infeasible one. The final point is
# then GATED below: it must be FINITE under the objective itself.
MS_PENALTY_FLOOR <- 1e6       # finite stand-in for -Inf, as the serial driver
MS_PENALTY    <- MS_PENALTY_FLOOR   # re-set at the start point; see MS_PENALTY_MULT
MS_TOL        <- 1e-4         # a restart gaining less than this stops the cycle
MS_CYCLE_TOL  <- 0.5          # = ARM_CYCLE_TOL; a cycle below this is CONVERGED
MS_DRAW_TRIES <- 200          # redraws allowed before a start is declared dead
# ⛔⛔ RE-RULED 2026-09-10 FOR ROUND 6 (Marcus: "follow the recommendation"). At
# `seas_ml = 1` the P8 geometry guard makes the objective -Inf above h_ml ~ 75 m,
# and the 08-31e new-basin reference sat at 143.9 m (the 09-10 second basin at
# 164 m) -- infeasible, so ids 2/4/5 would have been born dead and the port
# target for `new_basin` could not be written ⇒ [[ccx_seas_ml_p8_wall_blocks_reference_set]].
# The references are now the two 31-parameter HILDA modes, both feasible at
# either `seas_ml` (h_ml 44.09 / 49.15 m), in-space, needing NO migration:
#   INCUMBENT = `hilda31p` (canonical, refitted under the periodic spinup)
#   NEW BASIN = `hilda31`  (the pre-adoption canonical, quarantined, by PATH)
# ⚠ They are ~9 log-units and small parameter moves apart, so the MEASURED
# dispersion between them is far smaller than the 1.0452 the 09-08e/09-10 arrays
# used; the sbatch therefore sets CCX_MS_SPREAD EXPLICITLY (to that 1.0452, its
# provenance stated there) and names it in the outdir, as the stop() below asks.
# Resolved THROUGH THE REGISTRY, not as a literal (test-mode-file.R's lint):
# a registered name that is later retired fails here by NAME, with the reason.
# ⛔⛔ RE-RULED 2026-09-12 FOR ROUND 7 (the refit under the 09-12 objective: annual-mean
# isotope pins, row-read concentrations, IntCal to 1941, no pre-run ice rows; Marcus:
# "start the refit"). INCUMBENT = `hilda31s` (the canonical, seas_ml 1, h_ml 64.8 --
# 10 m under the P8 wall); NEW BASIN = `hilda31p` (the registered seas_ml 0 control,
# h_ml 44.1, feasible at seas_ml 1 and a different basin of h_ml). Both through the
# registry. `hilda31` (quarantined, aseasonal) is no longer a reference.
# 2026-09-13: round 7 ADOPTED as `hilda31s2`; the incumbent for the NEXT array is that file.
# 2026-09-13 (d): the canonical is PINNED (`hilda30c`, ent_seas_amp_SH = 0). THE INCUMBENT
# FOLLOWS THE ARRAY'S OWN PINS: an array run under the canonical's pins takes the
# canonical; a FREE array takes the registered free PARENT (`hilda31s2`), because a
# 30-name vector is not a point of the 31-name space (its shim would migrate to 0 and be
# SEEDED at the table init -- a start, not the incumbent). Any other pin set is a new
# objective with no incumbent on disk: stop, rather than warm-start from the wrong one.
# 2026-09-14 (h): an array whose pins EXTEND the canonical's by names the pump field
# does not read (ccx_pins_extend_canonical) also takes the canonical -- the E array.
# 2026-09-17 (j): the rule lives in ONE function, ccx_ms_reference_set() (R/calibrate.R),
# read here and by make_port_targets.R; the control's arm (the inert pins, shim FREE,
# seas_ml 0) takes `hilda31p` as its incumbent and the free parent as its new basin.
# (.ms_env_required is defined further down, beside the structure block; an unset value
# stops THERE with the driver's own message -- here it is passed through as NA and
# ccx_parse_seas_ml() names it.)
.ms_ref <- ccx_ms_reference_set(MS_PINS, Sys.getenv("CCX_MS_SEAS_ML", NA_character_))
MS_REF_INC_NAME <- .ms_ref$incumbent
MS_REF_NEW_NAME <- .ms_ref$new_basin
MS_REF_INC    <- CCX_MODE_FILES[[MS_REF_INC_NAME]]
if (is.null(MS_REF_INC)) stop("MS_REF_INC: '", MS_REF_INC_NAME, "' is not in CCX_MODE_FILES -- ",
                              "re-rule the reference set (see MS_REF_INC_LABEL).")
MS_REF_NEW    <- CCX_MODE_FILES[[MS_REF_NEW_NAME]]
if (is.null(MS_REF_NEW)) stop("MS_REF_NEW: '", MS_REF_NEW_NAME, "' is no longer in CCX_MODE_FILES -- ",
                              "re-rule the reference set (see MS_REF_NEW_LABEL).")
# The labels read the run's own CCX_MS_SEAS_ML: until 09-17 (j) they TYPED "seas_ml 1",
# true of every array to date and false of the control refit.
# ...and until 2026-10-03 (c) this one TYPED "objective #12, periodic spinup": every start file of
# the #14 and #15 refits says #12 in its `kind`. No objective-number constant exists, so the label
# now says what is TRUE of every run -- the point is scored under THIS build's objective -- and
# derives the spinup from the objective's own (CCX_OBJECTIVE_SPINUP).
MS_REF_INC_LABEL <- sprintf("INCUMBENT = %s (%s; scored under this build's objective, %s spinup, evaluated at seas_ml %s)",
                            MS_REF_INC_NAME, .ms_ref$why, ccx_spinup_label(CCX_OBJECTIVE_SPINUP),
                            Sys.getenv("CCX_MS_SEAS_ML", "UNSET"))
MS_REF_NEW_LABEL <- sprintf("NEW BASIN = %s (%s; registered, evaluated at seas_ml %s)", MS_REF_NEW_NAME,
                            if (identical(MS_REF_NEW_NAME, CCX_MODE_SEASML0_CONTROL)) "seas_ml 0 control, periodic spinup"
                            else "the free parent, the other h_ml basin",
                            Sys.getenv("CCX_MS_SEAS_ML", "UNSET"))
# ⚠ THESE THREE NAMES ARE ALSO THE PORT-TARGET KEYS in calibration/torch/
# port_targets.csv, so this vector may not be extended with ids that have no
# target row -- the seeded ids below are deliberately NOT in it, and the port
# gate treats them the way it treats a dispersed id (it checks the new-basin
# reference point, which every task can evaluate).
MS_REF_IDS    <- c(cold = 0L, incumbent = 1L, new_basin = 2L)
# ---- THE ENSO-SEEDED STARTS (2026-09-01k) ---------------------------
# ⛔ THE SURVEY MUST PRODUCE ITS OWN BASELINE. See the header: both mode files
# are migrated 21-parameter vectors whose ocean ENSO pair is exactly 0, so
# neither is a mode of this space and neither -1548.01 nor -1496.01 is a number
# a 25-parameter result may be ranked against.
MS_SEED_IDS   <- c(inc_enso = 3L, new_enso = 4L, new_obs = 5L)
MS_DISPERSED_FROM <- 6L        # every id at or above this one is a random draw
# MEASURED, and re-measurable in four evaluations. The objective's own
# conditional optimum for the ocean pair at the 08-31e basin, with the other 23
# coordinates FROZEN: +0.05 -> +1.43, +0.10 -> +1.91, +0.15 -> +1.44,
# +0.20 -> +0.03, -0.10 -> -5.45 (2026-09-01, shipped table, matched harness;
# reproduces diag_enso_objective_leverage.R's +1.91 at +0.10).
# ⚠ A START POINT DOES NOT HAVE TO BE RIGHT -- it has to be somewhere the
# optimiser would not otherwise go. The precision of this number is irrelevant;
# its SIGN and ORDER are the point.
MS_ENSO_OCN_OPT <- 0.10
# THE OBSERVATION-IMPLIED PARTITION, which is a DIFFERENT claim from the one
# above and deliberately gets its own start. Closing GCB's measured ENSO sink
# slopes needs land x1.734 and ocean +0.326 in each hemisphere (09-01j, after
# the slope-for-coefficient correction: the coefficient->slope transfer is
# ~0.43, not 1 [[slope_gap_is_not_a_coefficient]]). Conditionally the objective
# REFUSES that -- it scores -7.72 against the unseeded basin -- but a
# conditional sign is a hypothesis about a refit, not a prediction of one
# ([[ccx_gates_priced]]: frozen slices overstated a cost by 253 log-units), and
# the compensating-error state (09-01g) is precisely other coordinates absorbing
# an ENSO change. This start asks the question a frozen slice cannot: started
# where the OBSERVATION says the partition is, does the fit stay near there?
MS_ENSO_OCN_OBS   <- 0.326
MS_ENSO_LAND_OBS  <- 1.734     # multiplier on BOTH land coefficients
# ---- budget shaping. ⚠ THESE LIVE HERE, WITH THE OTHER NAMED CONSTANTS, and
# not beside the loop that uses them: the first cut defined MS_POLISH_TARGET
# next to the wall guard and referenced it in the startup banner 20 lines
# earlier, which is an "object not found" at run time and nowhere else.
MS_MAXIT_FLOOR  <- 200    # NM evals below which a restart is not worth entering
MS_POLISH_MAXIT <- 500    # BFGS iterations; each costs ~(2n+1) = 51 evals at n = 25
MS_POLISH_FLOOR <- 10     # BFGS iterations below which a polish is not worth entering
MS_POLISH_TARGET <- 100   # BFGS iterations the last cycle is GUARANTEED room for
# ⚠ AND THE RESERVE IS CAPPED AS A FRACTION OF THE BUDGET. A reserve expressed
# only as "room for 100 BFGS iterations" is an ABSOLUTE cost -- 41.6 min at the
# rate a 2x-slower node implies -- which is 23 % of a 180 min budget but 155 %
# of a 15 min one. The first cut had no cap and, on a short budget, reserved
# more than the whole budget so NO RESTART COULD EVER RUN. Whatever the budget,
# the polish may claim at most this share of it up front; it can still grow
# beyond the reserve when NM finishes early, because the polish is sized from
# what is actually left.
MS_POLISH_RESERVE_FRAC <- 0.15
MS_TARGETS    <- "calibration/torch/port_targets.csv"
# THE PORT GATE IS TWO GATES, AND EACH BOUND MATCHES ITS OWN CLAIM
# ([[gate_bound_matches_its_claim]]):
#   (a) the START value is an EVALUATION of one fixed point, so machine A and
#       machine B must agree to floating-point, and the bound is RELATIVE and
#       tight -- tight meaning ABOVE THE OBJECTIVE'S OWN ROUNDOFF FLOOR AT THAT
#       POINT, which is measured, not assumed (2026-09-15; MS_PORT_FLOOR_* below).
#       This is what actually catches a bad port -- a different BLAS, a
#       different libm, a half-copied data file.
#   (b) the FINAL value is the result of an OPTIMISATION from that point, so the
#       only claim available is an ORDERING: it may not come back WORSE than
#       where it started. No invented threshold ([[threshold_from_obs_or_law]]).
# The old single 1.0-log-unit bound was neither: it compared an optimised value
# against the mode file's STORED logpost, 85 % of which the incumbent's known
# -0.85 objective-drift offset spent before the port was even considered.
MS_EVAL_TOL   <- 1e-8         # relative, on a pure evaluation identity -- the FLOOR of gate (a)'s bound
# ⭐ GATE (a)'S BOUND IS DERIVED FROM A MEASURED ROUNDOFF FLOOR, NOT TYPED (2026-09-15;
# Marcus ruled option A). The E array's preflight 17818291 failed gate (a) on ONE task
# of 24 -- the incumbent reference, rel 2.16e-8 -- while the cold and new-basin
# references reproduced at 1e-11 on the same nodes. Tested on BOTH machines: no
# discrete choice flipped (same substeps, same Newton iteration count with the
# identical residual history; Torch self-reproduces to 1e-14). What flipped the gate
# was the OBJECTIVE'S OWN ROUNDOFF FLOOR, which is POINT-DEPENDENT: perturbing u by
# 1e-12 relative moved the logpost by up to 3.5e-5 (Mac) / 8.7e-5 (Torch) at the
# incumbent vs 2e-6 / 6e-6 at the other two, FLAT across eps 1e-12..1e-8 (a floor, not a
# gradient), carried by the d13C level rows. A fixed 1e-8 (2.7e-5 absolute there) sat
# BELOW that floor and failed on noise. So the bound is now
#     tol_abs = max(MS_EVAL_TOL * |target|, MS_PORT_FLOOR_K * floor)
# with `floor` = max |lp(u') - lp(u)| over MS_PORT_FLOOR_N SEEDED perturbations
# u' = u * (1 +- MS_PORT_FLOOR_EPS) of one coordinate, measured HERE at the reference
# point -- and a HARD CEILING MS_PORT_TOL_CEIL relative, so a real break (a missing
# input ~ 1e-3 relative; the 09-01 ent26 false-broken-port was -Inf) still fails and a
# pathologically noisy point is REPORTED rather than waved through. Every number is
# printed. ⇒ [[port_gate_tolerance_below_roundoff_floor]]. ⛔ Raising MS_EVAL_TOL by
# hand was option (C), the loosen-to-pass anti-pattern, and was rejected.
MS_PORT_FLOOR_N    <- 12L         # perturbations; the 09-15 diagnostic used 12
MS_PORT_FLOOR_EPS  <- 1e-12       # relative, one coordinate at a time (~1e4 ulp)
MS_PORT_FLOOR_K    <- 3           # safety over the measured max |delta|
MS_PORT_TOL_CEIL   <- 1e-6        # relative ceiling on tol_abs; a real break is >= 1e-3
MS_PORT_FLOOR_SEED <- 20260915L   # the floor's own RNG stream; the driver's is saved and restored

.env_num <- function(nm, default) {
  v <- Sys.getenv(nm, NA_character_)
  if (is.na(v) || !nzchar(v)) return(default)
  n <- suppressWarnings(as.numeric(v))
  if (is.na(n)) stop(nm, " is not numeric: '", v, "'")
  cat(sprintf("OVERRIDE %s = %s (default %s)\n", nm, format(n), format(default)))
  n
}
MS_RESTARTS <- .env_num("CCX_MS_RESTARTS", 3)
MS_CYCLES   <- .env_num("CCX_MS_CYCLES",   6)
MS_MAXIT    <- .env_num("CCX_MS_MAXIT",    6000)
# ⚠ 180 IS THE DIRECT-INVOCATION DEFAULT ONLY. It once matched
# calibration/torch/multistart.sbatch; the sbatch and the Mac runner now both
# export 300 (corrected 2026-10-05 o: this comment still said "MATCHES").
# ⭐ THE BUDGET IS ON THE CLOCK CCX_MS_CLOCK NAMES (2026-10-05 o; D1 "CPU on
# Mac, wall on Torch"). Its env name is CCX_MS_BUDGET_MIN since then; the older
# CCX_MS_WALL_MIN is still read, so every earlier launch recipe runs unchanged.
# Both set and DIFFERENT is a stop, not a precedence rule.
MS_BUDGET_VAR <- local({
  b <- Sys.getenv("CCX_MS_BUDGET_MIN", ""); w <- Sys.getenv("CCX_MS_WALL_MIN", "")
  if (nzchar(b) && nzchar(w) && !identical(b, w))
    stop("CCX_MS_BUDGET_MIN = '", b, "' and its pre-2026-10-05 name CCX_MS_WALL_MIN = '", w,
         "' are both set and DIFFER. Set one.", call. = FALSE)
  if (!nzchar(b) && nzchar(w)) "CCX_MS_WALL_MIN" else "CCX_MS_BUDGET_MIN"
})
MS_BUDGET_MIN <- .env_num(MS_BUDGET_VAR, 180)
MS_CLOCK       <- ms_clock_kind()             # validated: an unknown CCX_MS_CLOCK stops
MS_CLOCK_LABEL <- ms_clock_label(MS_CLOCK)    # "wall" / "CPU": every budget label derives from it
# The units the log prints. Under the wall clock they are the pre-10-05 "min" and "s/eval", so a wall run's log
# reads exactly as it did; under the CPU clock they say so on every line.
MS_MIN_UNIT <- if (MS_CLOCK == "wall") "min" else paste0(MS_CLOCK_LABEL, "-min")
MS_SPE_UNIT <- if (MS_CLOCK == "wall") "s/eval" else paste0(MS_CLOCK_LABEL, "-s/eval")
if (nzchar(Sys.getenv("CCX_MS_CLOCK", "")))
  cat(sprintf("OVERRIDE CCX_MS_CLOCK = %s (default wall)\n", MS_CLOCK))
# D4 (Marcus 2026-10-05, "Warn only, at 2x (Recommended)"): under the CPU clock, a
# start whose WALL time passes this multiple of its budget is FLAGGED (the log and
# the start file's `wall_warned`). It is never stopped for it.
MS_WALL_WARN_X <- 2
MS_SEED     <- .env_num("CCX_MS_SEED",     MS_SEED_BASE)

# ---- WHICH START. Absence ASSERTS nothing here -- 0 is a legal, MEANINGFUL
# id (the cold control) -- but a NON-NUMERIC id must stop rather than become 0.
MS_ID <- local({
  v <- Sys.getenv("CCX_MS_ID", NA_character_)
  if (is.na(v) || !nzchar(v)) v <- Sys.getenv("SLURM_ARRAY_TASK_ID", NA_character_)
  if (is.na(v) || !nzchar(v)) {
    cat("no CCX_MS_ID and no SLURM_ARRAY_TASK_ID -- running the COLD control, id 0\n")
    return(0L)
  }
  n <- suppressWarnings(as.integer(v))
  if (is.na(n) || n < 0)
    stop("start id must be a non-negative integer; got '", v, "'")
  n
})

# ---- PER-COORDINATE DISPERSION OVERRIDES (2026-09-30 p; Marcus: "At its prior sd") ----
# The shared u-space sd (MS_SPREAD, below) is sized for coordinates whose u-scale is O(1)
# against their prior. `npp_tsens` (the D2 greening term, tr = "id", prior sd
# NPP_TSENS_PRIOR_SD = 0.029 /K) is not: at 1.0452 a dispersed start sits 36 prior sds out,
# and at the D2/D3 screen's DNTb vector a 1-sd move in it ALONE costs 4.5e5-8.9e5
# log-units, ~10x the stiffest other coordinate (q10, ~5e4; CHANGELOG 09-30 p). RULED:
# disperse it at its PRIOR sd -- in u-space, which for tr = "id" is the natural sd
# (asserted). Applied only to names this run FITS (the gate open); printed; recorded in
# every start file (`spread_by_name`) and REQUIRED in the output directory's name.
MS_SPREAD_OVERRIDE <- c(npp_tsens = ccx_const("NPP_TSENS_PRIOR_SD"))
MS_SPREAD_OVERRIDE <- MS_SPREAD_OVERRIDE[names(MS_SPREAD_OVERRIDE) %in% CCX_PARAM_NAMES]
if ("npp_tsens" %in% names(MS_SPREAD_OVERRIDE) && !identical(CCX_PARAM_TABLE$npp_tsens$tr, "id"))
  stop("MS_SPREAD_OVERRIDE gives npp_tsens its prior sd as a u-space sd, which holds only under tr = \"id\".")
MS_SPREAD_LABEL <- if (length(MS_SPREAD_OVERRIDE))
  paste0("_sdby_", paste(sprintf("%s=%s", names(MS_SPREAD_OVERRIDE), formatC(MS_SPREAD_OVERRIDE, format = "g", digits = 3)), collapse = "_")) else ""
MS_OUTDIR <- local({
  d <- Sys.getenv("CCX_MS_OUTDIR", NA_character_)
  # ⚠ THE DEFAULT NAMES THE PARAMETER SET, NOT JUST A DATE (2026-09-01k). It
  # was `multistart_20260831`, staged for a 22-parameter build; a date is not a
  # parameter set, and this project moved that set TWICE in three days. The
  # resume now refuses a checkpoint from another set, but a directory whose name
  # says which set it holds is the answer that does not rely on a guard firing.
  if (is.na(d) || !nzchar(d))
    ccx_path("calibration", "output",
             # 2026-09-16 f: the label DERIVES from the struct env var and the
             # date -- the two typed labels here covered "hilda" and "" only, so
             # a hilda_c array without CCX_MS_OUTDIR would have landed in
             # `multistart_20260901_enso25`, the 22-parameter era's name.
             paste0("multistart_", format(Sys.Date(), "%Y%m%d"), "_",
                    (function(st) if (nzchar(st)) st else "column")(Sys.getenv("CCX_MS_STRUCT", "")),
                    # 2026-09-10: seas_ml changes the OBJECTIVE at a constant 31 names, which
                    # the param_names guard cannot see; the directory must say it.
                    if (identical(Sys.getenv("CCX_MS_SEAS_ML", "0"), "1")) "_seasml1" else "",
                    # 2026-09-14 h: the pump field changes the objective too; the directory says it.
                    if (identical(Sys.getenv("CCX_MS_PUMP_FIELD", "solved"), "martin")) "_martin" else "",
                    ccx_pin_label(MS_PINS),
                    MS_SPREAD_LABEL))   # 2026-09-30 p: a per-coordinate dispersion override
  else d
})
# THE DIRECTORY MUST SAY IT (the seasml1 / _martin precedent): a dispersion that differs by
# coordinate is a different survey of the same objective. Checked BEFORE the directory exists.
if (nzchar(MS_SPREAD_LABEL) && !grepl(MS_SPREAD_LABEL, basename(MS_OUTDIR), fixed = TRUE))
  stop("the dispersion OVERRIDES ", sub("^_sdby_", "", MS_SPREAD_LABEL), " (the D2/D3 gate is open) but the output ",
       "directory '", basename(MS_OUTDIR), "' does not say so. Append '", MS_SPREAD_LABEL,
       "' to CCX_MS_OUTDIR (the driver's own default carries it).")
dir.create(MS_OUTDIR, recursive = TRUE, showWarnings = FALSE)
MS_OUT  <- file.path(MS_OUTDIR, sprintf("start_%03d.rds", MS_ID))
MS_CKPT <- file.path(MS_OUTDIR, sprintf("start_%03d_ckpt.rds", MS_ID))

# ---- the two reference points, and the dispersion scale they set -----
.mdI <- readRDS(ccx_path(MS_REF_INC)); .mdN <- readRDS(ccx_path(MS_REF_NEW))
# ⚠ WHAT A REFERENCE POINT MUST BE IS **FEASIBLE**, NOT FITTED-UNDER-THIS-TABLE
# (narrowed 2026-09-01). This used to demand that each reference file's recorded
# bands EQUAL the shipped table -- and the 09-01 `kz` re-bisection to the sourced
# GLODAP support made that false for every mode file on disk, which would have
# stopped the survey dead on a property of its warm starts rather than of the
# port. The port gate does not use these files' stored logposts at all; it uses
# `port_targets.csv`, measured under whatever table is shipped. So the
# requirement here is that the point HAS a finite objective value, and the
# requirement that actually needed a gate -- that the TARGET FILE was measured
# under the SAME table this run uses -- is enforced at PORT GATE (a) below.
# [[gate_bound_matches_its_claim]]
.ship <- lapply(CCX_PARAM_TABLE, function(s) c(s$lo, s$hi))
for (.r in list(list("incumbent", .mdI), list("new basin", .mdN))) {
  # SEED BEFORE THE FEASIBILITY CHECK (2026-09-06d): a migrated ancestor's
  # kz_deep_frac is 1 -- what it RAN -- and 1 is the box's upper bound, so the
  # unseeded vector is infeasible by construction and the seed is what makes
  # it a start point. (The P_INC/P_NEW below seed again; same numbers.)
  .pm <- ccx_seed_unencodable(ccx_migrate_par_set(ccx_mode_par_with_pins(.r[[2]])), paste(.r[[1]], "feasibility"))
  .bad <- Filter(function(n) {
    b <- .ship[[n]]
    !is.null(b) && all(is.finite(b)) && (.pm[[n]] <= b[1] || .pm[[n]] >= b[2])
  }, CCX_PARAM_NAMES)
  if (length(.bad))
    stop("reference file for ", .r[[1]], " is NOT FEASIBLE under the shipped ",
         "table (", paste(.bad, collapse = ", "), "), so it cannot be a start ",
         "point: the objective has no finite value there.")
  if (!isTRUE(all.equal(.r[[2]]$kz_bracket, .ship$kz)) ||
      !isTRUE(all.equal(.r[[2]]$hml_bound, .ship$h_ml)))
    cat(sprintf("NOTE the %s reference was FITTED under kz [%s], the shipped table is kz [%s].\n     Feasible, so it is a legal start; its own stored logpost is on a different scale.\n",
                .r[[1]], paste(.r[[2]]$kz_bracket, collapse = ", "),
                paste(.ship$kz, collapse = ", ")))
}
P_INC <- ccx_migrate_par_set(ccx_mode_par_with_pins(.mdI))   # a pinned file's held name is HELD, not absent (09-13 (d))
P_NEW <- ccx_migrate_par_set(ccx_mode_par_with_pins(.mdN))
# ---- SEED A COORDINATE THE MIGRATION COULD ONLY FILL WITH ITS OFF STATE ----
# `ent_seas_amp_SH` entered CCX_PARAM_TABLE on 2026-09-03 with `tr = "log"`.
# ccx_migrate_par_set() fills it with 0 -- WHAT THE ANCESTOR RAN, which is the
# right answer for a vector you MEASURE at -- but a log space has no 0, so a
# reference point migrated that way cannot be a START point. These are different
# statements and the code now says both: the migration records what the ancestor
# ran, and this seeds where the search begins.
# ⛔ NOT a silent repair. It fires only for a coordinate the migration itself
# reports as filled, it names the coordinate, and it prints both numbers.
P_INC <- ccx_seed_unencodable(P_INC, "incumbent start")
P_NEW <- ccx_seed_unencodable(P_NEW, "new basin start")
U_INC <- ccx_par_to_unc(P_INC)
U_NEW <- ccx_par_to_unc(P_NEW)
U_COLD <- ccx_init_unc()
# ---- THE DISPERSION POOL. A coordinate MIGRATED IN BOTH reference points has
# a separation that is an artifact of the migration contract, not a measured
# distance between basins, so it is excluded from the RMS rather than averaged
# into it. Derived from `attr(, "migrated")` -- the field the migration itself
# records -- so the next split is handled without editing this line, and the
# excluded names are PRINTED rather than assumed ([[intersect_is_a_silent_default]]:
# absence must say so).
MS_SPREAD_SKIP <- intersect(attr(P_INC, "migrated"), attr(P_NEW, "migrated"))
MS_SPREAD_POOL <- setdiff(CCX_PARAM_NAMES, MS_SPREAD_SKIP)
if (!length(MS_SPREAD_POOL))
  stop("every coordinate was migrated in BOTH reference points, so there is no ",
       "measured basin separation left to set a dispersion from. Set CCX_MS_SPREAD ",
       "explicitly and say in the output directory name what it came from.")
MS_SPREAD_MEASURED <- sqrt(mean((U_NEW - U_INC)[MS_SPREAD_POOL]^2))
MS_SPREAD_ALL      <- sqrt(mean((U_NEW - U_INC)^2))   # the diluted value, for the record
# ⚠ RENAMED from MS_SPREAD_ALL25 on 2026-09-03: the build fits 26 and a name
# carrying a stale count is the label-drift bug the project rule exists to stop.
MS_SPREAD <- .env_num("CCX_MS_SPREAD", MS_SPREAD_MEASURED)
# the shared sd, with the per-coordinate overrides (MS_SPREAD_OVERRIDE, defined above MS_OUTDIR)
MS_SPREAD_VEC <- stats::setNames(rep(MS_SPREAD, length(CCX_PARAM_NAMES)), CCX_PARAM_NAMES)
MS_SPREAD_VEC[names(MS_SPREAD_OVERRIDE)] <- MS_SPREAD_OVERRIDE

cat(sprintf("\n%s\nDISPERSED MULTI-START, id %d, arm %s, %d parameters\n",
            strrep("=", 70), MS_ID, MS_ARM, length(CCX_PARAM_NAMES)))
cat(sprintf("  host %s   R %s   seed %d + id\n", Sys.info()[["nodename"]],
            paste(R.version$major, R.version$minor, sep = "."), MS_SEED))
cat(sprintf("  budget: %d restarts x %d maxit x %d cycles, %s %g min\n",
            MS_RESTARTS, MS_MAXIT, MS_CYCLES, MS_CLOCK_LABEL, MS_BUDGET_MIN))
if (MS_CLOCK != "wall")
  cat(sprintf("  ... on the %s clock (CCX_MS_CLOCK; RECORDED in the start file): a sleep or a suspension does not spend\n      it. WALL time past %g x the budget is FLAGGED, never stopped (D4, CHANGELOG 2026-10-05 o).\n",
              MS_CLOCK_LABEL, MS_WALL_WARN_X))
cat(sprintf("  dispersion sd %.4f in u-space (measured per-coordinate RMS between\n    the two known basins = %.4f, pooled over the %d coordinates at least one of\n    them FITTED; over all %d it would be %.4f, diluted by the %d migrated in BOTH:\n    %s)\n",
            MS_SPREAD, MS_SPREAD_MEASURED, length(MS_SPREAD_POOL),
            length(CCX_PARAM_NAMES), MS_SPREAD_ALL, length(MS_SPREAD_SKIP),
            if (length(MS_SPREAD_SKIP)) paste(MS_SPREAD_SKIP, collapse = ", ") else "none"))
if (length(MS_SPREAD_OVERRIDE))
  cat(sprintf("  dispersion OVERRIDDEN per coordinate (u-space sd): %s\n",
              paste(sprintf("%s = %.4g", names(MS_SPREAD_OVERRIDE), MS_SPREAD_OVERRIDE), collapse = ", ")))
cat(sprintf("  out %s\n%s\n", MS_OUT, strrep("=", 70)))

bp <- ccx_default_params(); bp$pump_mode <- MS_ARM
# THE DECLARED STRUCTURE (2026-09-06d): one definition, shared with
# make_port_targets.R, selected by CCX_MS_STRUCT ("" = column, "hilda").
# ⛔⛔ AND THE SEASONAL MIXED LAYER (2026-09-10), selected by CCX_MS_SEAS_ML, and
# BOTH MUST BE SET EXPLICITLY -- an unset variable is an ERROR here, not a
# default. The 09-10 refit (17318015 + 17325832) ran BOTH rounds with the
# mechanism OFF because this line built a bare `ccx_default_params()` and nobody
# had to say what `seas_ml` was; the result was launched as the round-6 test and
# turned out to be a new seas_ml = 0 baseline ⇒ [[ccx_refit_ran_at_seas_ml_0]].
# `ccx_apply_structure()` itself keeps a default (0) for library callers and
# `ccx_mode_base()`; THE DRIVER refuses to guess, because a guess here costs
# 24 x 5 h of fairshare before anyone can see it was wrong. The same rule now
# binds CCX_MS_STRUCT, whose unset-means-column default is the
# [[port_targets_need_the_struct_var]] footgun in make_port_targets.R.
.ms_env_required <- function(k) {
  v <- Sys.getenv(k, NA_character_)
  if (is.na(v)) stop("run_dispersed_multistart.R: ", k, " is NOT SET. The objective's ",
                     "label must be stated explicitly (multistart.sbatch exports it); an ",
                     "unset value is how the 2026-09-10 refit ran at seas_ml = 0 unnoticed.")
  v
}
MS_STRUCT_ENV  <- .ms_env_required("CCX_MS_STRUCT")
MS_SEAS_ML_ENV <- .ms_env_required("CCX_MS_SEAS_ML")
# THE PUMP FIELD'S CONSTRUCTION (option D + E, 2026-09-14 h): the THIRD axis of
# the objective's label. NOT required in the environment -- unset = "solved" =
# every registered file's field, which is a FACT about the model (no other
# field existed before 09-14 h), not a default being trusted. The E array sets
# CCX_MS_PUMP_FIELD=martin; recorded in every start file and gated against the
# port targets exactly as seas_ml is.
MS_PUMP_FIELD_ENV <- Sys.getenv("CCX_MS_PUMP_FIELD", "solved")
bp <- ccx_apply_structure(bp, MS_STRUCT_ENV, MS_SEAS_ML_ENV, pump_field = MS_PUMP_FIELD_ENV)
for (n in names(MS_PINS)) bp[[n]] <- MS_PINS[[n]]     # the pinned value lives in the base
MS_STRUCT <- attr(bp, "struct"); MS_SEAS_ML <- attr(bp, "seas_ml"); MS_PUMP_FIELD <- attr(bp, "pump_field")
# ⛔ UNDER "martin" THE SOLVED FIELD'S `pump_grad` DOES NOT REACH THE MODEL, and
# under "solved" the loop's three names do not; a free unidentified name is a
# flat likelihood direction and a singular Hessian. Refuse by name rather than
# fit a parameter the objective cannot see (prereg 09-14h §2).
.ms_inert <- ccx_pump_field_inert(MS_PUMP_FIELD)
.ms_inert_free <- intersect(.ms_inert, CCX_PARAM_NAMES)
if (length(.ms_inert_free))
  stop("run_dispersed_multistart.R: under pump_field = \"", MS_PUMP_FIELD, "\" the name(s) ",
       paste(.ms_inert_free, collapse = ", "), " do not reach the model (",
       if (identical(MS_PUMP_FIELD, "martin")) "the prescribed field ignores pump_grad; ruling E3 subsumes option A"
       else "the loop is absent under the solved field",
       ") and must be PINNED (CCX_MS_PIN), not fitted.")
# ... and the SAME rule for the equatorial cell's two names under a structure
# WITHOUT the cell (2026-09-16 f): `w_eq` / `gamma_eq` do not reach the model
# when eq_frac = 0, so a free pair is a likelihood-flat direction held only by
# its prior -- the E array (hilda_c, 09-15) fitted them free and they sat at
# the prior's centre (27.13 Sv, 1.00) for 32 wasted dimensions of Hessian.
if (!ccx_eq_on(bp)) {
  .ms_cell_free <- intersect(c("w_eq", "gamma_eq"), CCX_PARAM_NAMES)
  if (length(.ms_cell_free))
    stop("run_dispersed_multistart.R: under struct \"", MS_STRUCT, "\" (no equatorial cell) the name(s) ",
         paste(.ms_cell_free, collapse = ", "), " do not reach the model and must be PINNED (CCX_MS_PIN), not fitted.")
}
# ... and the layer-2 Nino3.4 limb's name under a structure with k_l2 = 0 (2026-09-17 k)
if (!ccx_l2_on(bp) && "w_enso_l2" %in% CCX_PARAM_NAMES)
  stop("run_dispersed_multistart.R: under struct \"", MS_STRUCT, "\" (k_l2 = 0, no layer-2 limb) ",
       "w_enso_l2 does not reach the model and must be PINNED (CCX_MS_PIN), not fitted.")
# the banner prints the WHOLE declared block of the label, so a hilda_eq task's log
# names the cell's geometry (eq_frac, h_eq, sst_eq, sst_eq_enso, alk_eq, k_eq) and is
# distinguishable from a hilda task's on its own (review 2026-09-14)
# ... and a hilda_tr task's names the tropical box's (tr_frac, h_tr, sst_tr, sst_tr_enso,
# alk_tr) and the three SST overrides (2026-09-14f). ONE dispatch: ccx_struct_block().
.ms_struct_blk <- if (nzchar(MS_STRUCT)) ccx_struct_block(MS_STRUCT) else NULL
cat(sprintf("  structure: '%s'%s\n", MS_STRUCT,
            if (length(.ms_struct_blk)) paste0(" (", paste(sprintf("%s=%s", names(.ms_struct_blk), signif(unlist(.ms_struct_blk), 5)), collapse = ", "), ")") else " (32-box column)"))
cat(sprintf("  seasonal mixed layer: seas_ml = %d (%s; from CCX_MS_SEAS_ML, RECORDED in every start file and GATED against the port targets)\n",
            MS_SEAS_ML, if (MS_SEAS_ML == 1L) "ON -- round 6" else "OFF -- the shipped model"))
stopifnot(identical(bp$seas_ml, MS_SEAS_ML))   # the label IS the model's switch, not a note beside it
cat(sprintf("  pump field: '%s' (%s; from CCX_MS_PUMP_FIELD, RECORDED in every start file and GATED against the port targets)\n",
            MS_PUMP_FIELD, if (identical(MS_PUMP_FIELD, "martin")) "PRESCRIBED export on the Martin profile + the ventilation loop -- option D+E"
                           else "the SOLVED GLODAP-shape field -- every registered file"))
stopifnot(identical(bp$pump_field, MS_PUMP_FIELD))
lp_fun <- ccx_make_logpost(base_params = bp)
n_eval <- 0L
# ⭐ THE IN-RESTART DEADLINE (option A; Marcus 2026-10-05 on notes/proposal_2026-10-04_multistart_inrestart_wall.md;
# calibration/lib_ms_deadline.R). The wrapper checks the CURRENT step's deadline before each evaluation and
# tracks the best point the step has evaluated; ms_run_step() returns that point when the deadline passes.
# Outside a step (the rate measurement, the start, the dead-task check call lp_fun directly) there is none.
# ⭐ ONE CLOCK (2026-10-05 o): the step's deadlines are read on MS_CLOCK, and ms_now() reads the STEP'S clock, so
# the budget's origin, its elapsed minutes and every deadline below cannot be on two different clocks.
MS_STEP <- ms_step_state(MS_CLOCK)
ms_now <- function() ms_clock(MS_STEP$clock)
neg_lp <- function(u) {
  ms_check_deadline(MS_STEP)
  n_eval <<- n_eval + 1L
  v <- lp_fun(u)
  val <- if (!is.finite(v)) MS_PENALTY else -v
  ms_track_best(MS_STEP, u, val)
  val
}

# ---- the start point for THIS id ------------------------------------
# DETERMINISTIC PER ID, so start k is the same point whether it runs alone, in
# an array of 8 or in an array of 400, and a failed task can be requeued without
# changing what it was. That is the property `set.seed(ARM_SEED)` gives the
# serial driver, carried over to a fan-out.
# ⚠ THE OCEAN-ENSO SEED SEEDS WHAT THIS ARM FITS (2026-09-17 l). Under an arm that
# PINS the ocean pair (the E array under martin; the limb's arm), setting
# gamma_enso_ocn_* here is silently DROPPED by ccx_par_to_unc() (a pinned name is
# not encoded) -- ids 3/4 then DUPLICATE ids 1/2 while their label says "the pair
# SET to +0.100" (found at the limb arm's preflight: id 3 = id 1 to the digit; the
# E array's ids 3/4 were the same duplicates). So: with the pair FREE, seed the pair;
# with the pair PINNED and the LIMB ON, seed the limb's w_enso_l2 at an edge of
# Meinen's per-index bracket (the product, obs_eq_cell.rds; `edge` "hi" = 25 for the
# incumbent-side start, "lo" = 14 for the new-basin-side, so the two seeded starts
# bracket the init 18.7 the references sit at); with the pair pinned and NO limb,
# nothing can be seeded -- say so in the label rather than run a duplicate.
.ms_ocn_pinned <- all(c("gamma_enso_ocn_NH", "gamma_enso_ocn_SH") %in% names(MS_PINS))
.ms_limb_on    <- ccx_l2_on(bp)                       # bp = the run's own base (structure applied above)
MS_L2_SEED_SV <- ccx_eq_cell_obs()$w0_prior$interannual$per_index_sv   # c(14, 25) Sv per index, Meinen 2001
ms_seed_ocn <- function(p, x, edge = c("hi", "lo")) {
  edge <- match.arg(edge)
  if (!.ms_ocn_pinned) { p$gamma_enso_ocn_NH <- x; p$gamma_enso_ocn_SH <- x; return(p) }
  if (.ms_limb_on) { p$w_enso_l2 <- if (edge == "hi") max(MS_L2_SEED_SV) else min(MS_L2_SEED_SV); return(p) }
  p                                                    # pinned, no limb: nothing to seed
}
ms_seed_ocn_label <- function(x, edge = c("hi", "lo")) {
  edge <- match.arg(edge)
  if (!.ms_ocn_pinned) return(sprintf("the ocean ENSO pair SET to %+0.3f each (the 09-01 conditional optimum of the 08-31e basin; a perturbation here)", x))
  if (.ms_limb_on) return(sprintf("the ocean ENSO pair PINNED; the limb's w_enso_l2 SET to %g Sv per index (the %s edge of Meinen's bracket)",
                                  if (edge == "hi") max(MS_L2_SEED_SV) else min(MS_L2_SEED_SV), if (edge == "hi") "HIGH" else "LOW"))
  "the ocean ENSO pair PINNED and no limb: NOTHING seeded -- this start EQUALS the reference it is named for"
}
ms_seed_land <- function(p, m) {
  p$gamma_enso_land_NH <- p$gamma_enso_land_NH * m
  p$gamma_enso_land_SH <- p$gamma_enso_land_SH * m; p
}
ms_start <- function(id) {
  if (id == MS_REF_IDS[["cold"]])
    return(list(u = U_COLD, kind = "reference: COLD hand-set init", draws = 0L, ref = NA_real_))
  if (id == MS_REF_IDS[["incumbent"]])
    return(list(u = U_INC, kind = paste("reference:", MS_REF_INC_LABEL),
                draws = 0L, ref = .mdI$logpost))
  if (id == MS_REF_IDS[["new_basin"]])
    return(list(u = U_NEW, kind = paste("reference:", MS_REF_NEW_LABEL),
                draws = 0L, ref = .mdN$logpost))
  # ---- THE SEEDED STARTS. ⚠ SEEDED IN PARAMETER SPACE, THEN ENCODED, never by
  # adding to `u`: the ENSO entries happen to be `tr = "id"` today, so the two
  # would agree, and that is exactly the coincidence a later transform change
  # would break silently. Go through ccx_par_to_unc() and the encoding stays the
  # table's business.
  # ⚠ DISPATCHED THROUGH THE VECTOR, NOT BY `MS_SEED_IDS[["name"]]` AT EACH
  # BRANCH. Under the direct form, DELETING an entry made this function die at
  # "subscript out of bounds" three frames from the cause and never reached the
  # gap guard below (mutation-tested 2026-09-01k, which is how it was found).
  # Now: an id the vector names with no branch here stops with the reason, and
  # an id the vector no longer names falls through to the gap guard.
  .sk <- names(MS_SEED_IDS)[match(id, MS_SEED_IDS)]
  if (!is.na(.sk) && !(.sk %in% c("inc_enso", "new_enso", "new_obs")))
    stop("MS_SEED_IDS names id ", id, " as '", .sk, "' but ms_start() has no ",
         "branch that builds it. Add one beside the others.")
  if (identical(.sk, "inc_enso"))
    return(list(u = ccx_par_to_unc(ms_seed_ocn(P_INC, MS_ENSO_OCN_OPT, "hi")),
                kind = paste("seeded: INCUMBENT with", ms_seed_ocn_label(MS_ENSO_OCN_OPT, "hi")),
                draws = 0L, ref = NA_real_))
  if (identical(.sk, "new_enso"))
    return(list(u = ccx_par_to_unc(ms_seed_ocn(P_NEW, MS_ENSO_OCN_OPT, "lo")),
                kind = paste("seeded: NEW BASIN with", ms_seed_ocn_label(MS_ENSO_OCN_OPT, "lo")),
                draws = 0L, ref = NA_real_))
  if (identical(.sk, "new_obs"))
    return(list(u = ccx_par_to_unc(ms_seed_land(ms_seed_ocn(P_NEW, MS_ENSO_OCN_OBS, "hi"),
                                                MS_ENSO_LAND_OBS)),
                kind = sprintf("seeded: NEW BASIN + the OBSERVATION-implied partition (%s; land x%.3f)",
                               ms_seed_ocn_label(MS_ENSO_OCN_OBS, "hi"), MS_ENSO_LAND_OBS),
                draws = 0L, ref = NA_real_))
  # ⛔ AN ID BELOW THE DISPERSED FLOOR THAT MATCHED NOTHING ABOVE IS A GAP IN
  # THIS FUNCTION, NOT A DISPERSED START. Falling through would silently turn a
  # fixed start into a random draw and the output file would call it dispersed.
  if (id < MS_DISPERSED_FROM)
    stop("id ", id, " is below MS_DISPERSED_FROM (", MS_DISPERSED_FROM, ") but ",
         "matches no fixed start. The fixed ids are ",
         paste(sort(c(MS_REF_IDS, MS_SEED_IDS)), collapse = ", "),
         "; add the missing one here or raise the floor.")
  set.seed(MS_SEED + id)
  for (k in seq_len(MS_DRAW_TRIES)) {
    stopifnot(identical(names(U_COLD), names(MS_SPREAD_VEC)))
    u <- U_COLD + MS_SPREAD_VEC * stats::rnorm(length(U_COLD))
    names(u) <- CCX_PARAM_NAMES
    if (is.finite(lp_fun(u)))
      return(list(u = u, kind = sprintf("dispersed about the COLD init, sd %.4f%s", MS_SPREAD,
                                        if (length(MS_SPREAD_OVERRIDE)) sprintf(" (%s)", paste(sprintf("%s at %.4g", names(MS_SPREAD_OVERRIDE), MS_SPREAD_OVERRIDE), collapse = ", ")) else ""),
                  draws = k, ref = NA_real_))
  }
  # A dispersed start that cannot find a finite point is a fact about the
  # dispersion, not a task to retry silently.
  stop("start ", id, ": ", MS_DRAW_TRIES, " draws at sd ", MS_SPREAD,
       " all gave a non-finite log-posterior. The dispersion is too wide for ",
       "this parameter table; lower CCX_MS_SPREAD and say so in the output dir.")
}

# ---- PREFLIGHT: prove the whole array is launchable WITHOUT launching it ----
# ⭐ `CCX_MS_PREFLIGHT=1` runs everything up to and including the port gate and
# the start draw, prints one line, and EXITS 0 without optimising. Looping it
# over every id in the array validates the entire submission in ~2 s per task
# instead of discovering a bad one after 3 h x 40 of fairshare.
#
# It exercises the REAL code path rather than a copy of it, which is the whole
# reason it lives here and not in a separate preflight script: a preflight that
# re-implements the draw would be testing itself.
MS_PREFLIGHT <- nzchar(Sys.getenv("CCX_MS_PREFLIGHT", ""))

# ---- resume, if this task has already run part of its budget ---------
st <- ms_start(MS_ID)
u <- st$u; best <- -lp_fun(u)
# THE PENALTY, DERIVED FROM THE START (see MS_PENALTY_FLOOR): strictly worse than
# any value the search begins from, so an infeasible step can never look like a
# gain. `neg_lp` reads MS_PENALTY at call time, so this assignment reaches it.
MS_PENALTY_MULT <- 10
MS_PENALTY <- max(MS_PENALTY_FLOOR, MS_PENALTY_MULT * abs(best))
cat(sprintf("infeasible-step penalty: log-post %.4g (= max(%.0e, %d x |start|)); the start beats it by construction\n",
            -MS_PENALTY, MS_PENALTY_FLOOR, MS_PENALTY_MULT))
# ⭐ THE FIXED REFERENCE POINT'S VALUE, CAPTURED BEFORE ANY RESUME CAN MOVE IT.
# ⛔ THE BUG THIS KILLS (found 2026-09-01 by re-submitting reference id 1):
# PORT GATE (a) used to read whatever the run STARTED FROM, which after a
# checkpoint resume is the OPTIMISER'S progress, not the reference point. So
# re-submitting an array to continue it -- the workflow the README recommends,
# and the whole reason tasks checkpoint -- made a reference task abort with
# "this machine does not reproduce the objective ... STOP AND DIAGNOSE", a
# false alarm pointing at the port when nothing was wrong at all. Gate (a)'s
# claim is about a FIXED point, so it must evaluate the FIXED point, always.
MS_REF_LP <- -best
trace <- data.frame(cycle = 0L, restart = 0L, logpost = -best, evals = 0L)
cyc0 <- 1L
MS_RESUMED <- FALSE
if (file.exists(MS_CKPT)) {
  ck <- readRDS(MS_CKPT)
  if (!identical(ck$id, MS_ID))
    stop("checkpoint at ", MS_CKPT, " is for id ", ck$id, ", not ", MS_ID)
  # ⛔ AND FOR THIS PARAMETER SET. See the note at the saveRDS below. Older
  # checkpoints carry no `param_names`; those are refused too rather than
  # trusted, because "written before the field existed" and "written under a
  # different set" are indistinguishable from here and only one of them is safe.
  if (is.null(ck$param_names))
    stop("checkpoint at ", MS_CKPT, " records no parameter set, so it cannot be ",
         "shown to have been written under this build's ", length(CCX_PARAM_NAMES),
         ". Delete it and restart this id, or point CCX_MS_OUTDIR at a fresh ",
         "directory -- a `u` vector means nothing without the set it was encoded under.")
  if (!identical(ck$param_names, CCX_PARAM_NAMES))
    stop("checkpoint at ", MS_CKPT, " was written on a ", length(ck$param_names),
         "-parameter build; this build fits ", length(CCX_PARAM_NAMES),
         ". Resuming it would decode a `u` of the wrong length. Use a fresh ",
         "CCX_MS_OUTDIR for a new parameter set; do not mix them in one directory.")
  # ⛔ AND UNDER THIS OBJECTIVE. Recorded AND READ -- a stamp nobody checks is
  # the [[recorded_but_never_restored]] failure with extra steps. MS_REF_LP was
  # evaluated a few lines above, at the FIXED reference point, on today's build;
  # if the checkpoint's stamp differs the objective moved underneath it.
  # ⚠ Older checkpoints carry no stamp and are REFUSED, not trusted, for exactly
  # the reason the `param_names` guard gives: "written before the field existed"
  # and "written under a different objective" are indistinguishable from here.
  if (is.null(ck$ref_logpost))
    stop("checkpoint at ", MS_CKPT, " records no `ref_logpost`, so it cannot be ",
         "shown to have been written under THIS objective (the parameter set ",
         "alone does not pin it -- 2026-09-02 moved the objective three times ",
         "at a constant 25 names). Delete it, or point CCX_MS_OUTDIR at a fresh ",
         "directory.")
  if (!isTRUE(abs(ck$ref_logpost - MS_REF_LP) <=
              MS_EVAL_TOL * max(1, abs(MS_REF_LP))))
    stop("checkpoint at ", MS_CKPT, " was written under a DIFFERENT OBJECTIVE: ",
         "its fixed reference point scored ", sprintf("%.6f", ck$ref_logpost),
         " and on this build the same point scores ", sprintf("%.6f", MS_REF_LP),
         " (delta ", sprintf("%+.6f", MS_REF_LP - ck$ref_logpost), "). Resuming ",
         "would carry a `best` from one objective into another. Use a fresh ",
         "CCX_MS_OUTDIR for a new objective; do not mix them in one directory.")
  u <- ck$u; best <- ck$best; trace <- ck$trace; cyc0 <- ck$cycle + 1L
  MS_RESUMED <- TRUE
  cat(sprintf("RESUMED from checkpoint at cycle %d, log-post %.4f\n", ck$cycle, -best))
}
# TWO NUMBERS, SAID SEPARATELY. Printing one line for both is how the gate came
# to conflate them: on a resumed run the old line claimed the DRAW landed where
# the OPTIMISER had got to.
cat(sprintf("start point: %s (%d draw%s), log-post there = %.4f\n",
            st$kind, st$draws, if (st$draws == 1L) "" else "s", MS_REF_LP))
if (MS_RESUMED)
  cat(sprintf("  ...but this run CONTINUES from the checkpoint at %.4f, cycle %d\n",
              -best, cyc0 - 1L))

# ---- PORT GATE (a): the FIXED REFERENCE point evaluates the same here as on
# the reference machine. Run BEFORE spending the budget, so a bad port costs
# seconds rather than a full array. The target is read from a file this script
# did not write ([[gate_reads_its_own_output]]); if it is absent, say so and
# decline to claim the port is verified -- do not silently proceed as if it were.
# ⚠ IT GATES `MS_REF_LP`, NOT `MS_START_LP`: the two differ after a resume, and
# only the first is the fixed point the claim is about.
MS_START_LP <- -best
MS_PORT <- list(checked = FALSE, target = NA_real_, rel = NA_real_)
local({
  f <- ccx_path(MS_TARGETS)
  nm <- names(MS_REF_IDS)[match(MS_ID, MS_REF_IDS)]
  # ⭐ EVERY TASK CHECKS THE PORT, NOT ONLY IDS 0-2 (2026-09-01). A dispersed
  # or SEEDED task has no target of its own -- port_targets.csv holds the three
  # reference points and nothing else, deliberately, because a target must be a
  # FIXED point and a seed is a start -- so it evaluates the NEW-BASIN reference point
  # -- one extra objective call, well under a second -- and checks that. The
  # reason is fairshare, not elegance: without it, an array submitted without
  # its gate batch (or after the table moved) would spend 40 x 3.5 h optimising
  # a different objective and only the collector would ever notice. With it, a
  # broken port kills every task in about two seconds.
  if (is.na(nm)) nm <- "new_basin"
  if (!file.exists(f)) {
    cat(sprintf("*** PORT GATE SKIPPED: no %s. Run `Rscript calibration/make_port_targets.R`\n    on the reference machine and ship it. This run is NOT port-verified.\n",
                MS_TARGETS))
    return(invisible(NULL))
  }
  # ⛔ `colClasses` ON THE PROVENANCE COLUMNS, OR read.csv EATS THE COMMIT.
  # A short hash is often all-digits-and-e -- `8297e84` parses as 8.297e+87 --
  # so the 2026-09-03 preflight logged its own provenance as a number in
  # scientific notation. The GATE is unaffected (it keys on `n_par` and the
  # brackets, and the CSV on disk is intact), but a provenance label that
  # silently becomes a different string is the label-drift class this project
  # keeps paying for. Read them as text and they cannot be reinterpreted.
  tg <- utils::read.csv(f, stringsAsFactors = FALSE,
                        colClasses = c(commit = "character", host = "character",
                                       name = "character", struct = "character"))
  r  <- tg[tg$name == nm, ]
  if (!nrow(r)) stop("port targets file has no row for reference '", nm, "'")
  if (!identical(as.integer(r$n_par[1]), length(CCX_PARAM_NAMES)))
    stop("port targets were recorded on a ", r$n_par[1], "-parameter build; ",
         "this build fits ", length(CCX_PARAM_NAMES), ". The target is stale.")
  # ⭐ THE TARGET MUST HAVE BEEN MEASURED UNDER THIS TABLE. A widened or
  # re-centred bracket shifts every logpost by a reparameterisation constant, so
  # a target from another table fails gate (a) for a reason that has nothing to
  # do with the port -- and would be read as a bad port. The 09-01 `kz`
  # re-bisection is exactly that event. Older CSVs carry no bracket columns;
  # those cannot be checked, so they are REFUSED rather than trusted.
  if (is.null(r$kz_lo) || is.na(r$kz_lo[1]))
    stop("port targets file records no parameter bracket, so it cannot be shown ",
         "to have been measured under this table. Re-run ",
         "`Rscript calibration/make_port_targets.R` on the reference machine.")
  .tt <- c(as.numeric(r$kz_lo[1]), as.numeric(r$kz_hi[1]),
           as.numeric(r$hml_lo[1]), as.numeric(r$hml_hi[1]))
  .lt <- c(.ship$kz, .ship$h_ml)
  if (!isTRUE(all.equal(.tt, .lt)))
    stop("port targets were measured under kz [", .tt[1], ", ", .tt[2], "] / h_ml [",
         .tt[3], ", ", .tt[4], "]; this build ships kz [", .lt[1], ", ", .lt[2],
         "] / h_ml [", .lt[3], ", ", .lt[4], "]. Every logpost differs by a ",
         "reparameterisation constant, so the comparison would indict the PORT ",
         "for a change in the TABLE. Re-run make_port_targets.R and re-ship the CSV.")
  # AND UNDER THIS STRUCTURE (2026-09-06d): a target measured on the column
  # against a run with HILDA's boxes on differs by hundreds of log-units for a
  # reason that has nothing to do with the port. Older CSVs carry no column;
  # those are refused like a missing bracket.
  if (is.null(r$struct) || is.na(r$struct[1]))
    stop("port targets file records no structure label; re-run make_port_targets.R.")
  if (!identical(as.character(r$struct[1]), MS_STRUCT))
    stop("port targets were measured with structure '", r$struct[1], "'; this run has '",
         MS_STRUCT, "'. Re-run make_port_targets.R under the run's CCX_MS_STRUCT.")
  # AND AT THIS `seas_ml` (2026-09-10): the switch moves the objective by ~150
  # log-units at the 09-10 mode and by -Inf wherever h_ml exceeds the P8 guard,
  # at a CONSTANT parameter set -- so `n_par` cannot see it and only this column
  # can. A CSV without it predates the capability and is refused like a missing
  # bracket: "written before the field existed" and "written at the other
  # setting" are indistinguishable from here ⇒ [[ccx_refit_ran_at_seas_ml_0]].
  if (is.null(r$seas_ml) || is.na(r$seas_ml[1]))
    stop("port targets file records no `seas_ml` column; re-run make_port_targets.R ",
         "with CCX_MS_SEAS_ML set to this run's value (", MS_SEAS_ML, ").")
  if (!identical(ccx_parse_seas_ml(r$seas_ml[1]), MS_SEAS_ML))
    stop("port targets were measured at seas_ml = ", r$seas_ml[1], "; this run has seas_ml = ",
         MS_SEAS_ML, ". Re-run make_port_targets.R under the run's CCX_MS_SEAS_ML.")
  # AND UNDER THIS PUMP FIELD (2026-09-14 h): the field moves the objective by
  # ~900 log-units at the canonical vector (the option-E probe) at a constant
  # name count; a CSV without the column predates the axis and is "solved" as
  # a FACT (ccx_mode_pump_field()'s contract), refused only if it disagrees.
  .pt_field <- if (is.null(r$pump_field) || is.na(r$pump_field[1])) "solved" else as.character(r$pump_field[1])
  if (!identical(.pt_field, MS_PUMP_FIELD))
    stop("port targets were measured under pump_field = '", .pt_field, "'; this run has '",
         MS_PUMP_FIELD, "'. Re-run make_port_targets.R under the run's CCX_MS_PUMP_FIELD.")
  # ⛔ AND UNDER THE SAME PINS (2026-09-13): a target measured on the free arm is
  # another objective's number for a pinned run, and vice versa. A CSV without the
  # column predates pins and is refused for a pinned run, accepted (as "no pins") for a free one.
  csv_pins <- if (is.null(r$pins)) "" else if (is.na(r$pins[1])) "" else as.character(r$pins[1])
  if (!identical(csv_pins, ccx_pin_label(MS_PINS)))
    stop("port targets were measured with pins '", csv_pins, "'; this run has '", ccx_pin_label(MS_PINS),
         "'. Re-run make_port_targets.R under the run's CCX_MS_PIN.")
  tgt <- as.numeric(r$logpost[1])
  if (!is.finite(tgt))
    stop("port target for '", nm, "' is ", r$logpost[1], " -- that reference point is ",
         "INFEASIBLE under this objective (at seas_ml = 1 the P8 guard makes h_ml above ",
         "~76 m -Inf). A gate against it cannot pass or fail; change the reference set.")
  # THE VALUE THIS TASK EVALUATES AT THE REFERENCE POINT. For ids 0-2 that IS
  # their own start point and is already in hand; for a dispersed id it is a
  # point this task never visits, so evaluate it -- one call, and the whole
  # justification for doing so is that it is cheap.
  here <- if (identical(MS_ID, unname(MS_REF_IDS[[nm]]))) MS_REF_LP
          else lp_fun(switch(nm, cold = U_COLD, incumbent = U_INC, new_basin = U_NEW))
  u_ref <- switch(nm, cold = U_COLD, incumbent = U_INC, new_basin = U_NEW)
  # THE MEASURED FLOOR (2026-09-15; see MS_PORT_FLOOR_* above): the objective's own
  # roundoff sensitivity AT THIS POINT, ON THIS MACHINE. Its RNG stream is private so
  # the driver's dispersion / restart streams are untouched by adding this step.
  .had_seed <- exists(".Random.seed", envir = globalenv(), inherits = FALSE)
  .saved <- if (.had_seed) get(".Random.seed", envir = globalenv()) else NULL
  set.seed(MS_PORT_FLOOR_SEED)
  .floor_d <- vapply(seq_len(MS_PORT_FLOOR_N), function(k) {
    du <- u_ref; j <- sample(length(du), 1L)
    du[j] <- du[j] * (1 + sample(c(-1, 1), 1L) * MS_PORT_FLOOR_EPS)
    lp_fun(du) - here
  }, numeric(1))
  if (.had_seed) assign(".Random.seed", .saved, envir = globalenv()) else rm(".Random.seed", envir = globalenv())
  fl <- max(abs(.floor_d))
  diff_abs <- abs(here - tgt)
  rel      <- diff_abs / max(abs(tgt), 1e-12)
  tol_abs  <- max(MS_EVAL_TOL * max(abs(tgt), 1e-12), MS_PORT_FLOOR_K * fl)
  ceil_abs <- MS_PORT_TOL_CEIL * max(abs(tgt), 1e-12)
  cat(sprintf("PORT GATE (a) at the %s reference point: here %.10f vs %s@%s %.10f,\n              |diff| %.3e (rel %.2e)%s\n",
              nm, here, r$host[1], r$commit[1], tgt, diff_abs, rel,
              if (identical(MS_ID, unname(MS_REF_IDS[[nm]]))) "" else "  [this task's own start is elsewhere]"))
  cat(sprintf("              roundoff floor here: max |delta lp| %.3e over %d perturbations of u by %.0e (median %.3e; %d non-finite)\n",
              fl, MS_PORT_FLOOR_N, MS_PORT_FLOOR_EPS, median(abs(.floor_d)), sum(!is.finite(.floor_d))))
  cat(sprintf("              bound = max(%.0e x |target| = %.3e, %g x floor = %.3e) = %.3e; ceiling %.0e x |target| = %.3e\n",
              MS_EVAL_TOL, MS_EVAL_TOL * abs(tgt), MS_PORT_FLOOR_K, MS_PORT_FLOOR_K * fl, tol_abs, MS_PORT_TOL_CEIL, ceil_abs))
  if (!is.finite(fl) || tol_abs > ceil_abs)
    stop("PORT GATE (a) CANNOT BE APPLIED: the objective's own roundoff floor at the ", nm,
         " reference point (", format(fl, digits = 3), ") puts the bound above its ceiling (",
         format(ceil_abs, digits = 3), " = ", MS_PORT_TOL_CEIL, " relative). The point is too ",
         "noisy to gate a port on; re-rule the reference set (or find out WHY it is that noisy) ",
         "before submitting the survey.")
  if (diff_abs > tol_abs)
    stop("PORT GATE (a) FAILED: this machine does not reproduce the objective ",
         "at a FIXED point to within ", format(tol_abs, digits = 3), " (= max(", MS_EVAL_TOL,
         " relative, ", MS_PORT_FLOOR_K, " x the measured roundoff floor ", format(fl, digits = 3),
         ")). Every dispersed start in this array would then be optimising something other ",
         "than the objective the reference modes were fitted on. STOP AND DIAGNOSE ",
         "before submitting the survey.")
  MS_PORT <<- list(checked = TRUE, target = tgt, rel = rel, diff = diff_abs, floor = fl, tol = tol_abs)
  cat("PORT GATE (a) PASSED.\n")
})

# ---- the budget, PROJECTED rather than merely checked -----------------
# ⛔ A BUDGET CHECK THAT ONLY LOOKS AT THE CLOCK CANNOT STOP A RESTART THAT HAS
# ALREADY STARTED. `optim()` is not interruptible from inside, so "elapsed <
# budget, go" commits the task to a WHOLE further restart -- MS_MAXIT evals,
# which at Torch's measured rate is half an hour. On a 4 h partition with a
# 3.5 h budget that overrun lands exactly on the cap and the task is killed with
# its cycle unwritten. So the guard PROJECTS: it starts a restart only if the
# time it is measured to take still fits.
#
# The first restart has no history, so its projection comes from timing the
# start evaluation -- a measurement, not a guess. MS_PROJ_SAFETY is the margin
# on it, and NM's own early `reltol` exit means the projection is an UPPER
# bound: restarts finish early far more often than they overrun.
# ⚠ 1.5, NOT 1.25, AND THE ARITHMETIC IS WRITTEN DOWN BECAUSE A TIMEOUT COSTS
# FAIRSHARE. The guard starts a restart only if `elapsed + SAFETY * projection`
# still fits `MS_BUDGET_MIN`, so the worst case is a restart that begins just
# inside the budget and then runs LONGER than projected -- which is exactly what
# node contention does ([[eta_in_days_is_not_a_slow_run]]: a 1.61x degradation
# was measured on this very model). With SAFETY = 1.5 and MS_BUDGET_MIN set 60 min
# below the SLURM wall, a restart would have to overrun its projection by more
# than 2.5x to reach the hard cap. At 1.25 with a 30 min gap, 2x was enough.
# ⚠ THAT MARGIN IS WALL-CLOCK ARITHMETIC, which is why Torch keeps the WALL clock
# (D1, 2026-10-05 o; the sbatch refuses any other). A CPU budget under a hard
# wall limit can overrun it by however much the task is starved of CPU.
MS_PROJ_SAFETY <- 1.5
MS_RATE_SAMPLES <- 5
# ⭐ THE BUDGET'S ORIGIN, on MS_CLOCK (2026-10-05 o). The wall origin beside it
# feeds only the record (`minutes_wall`) and D4's flag; no deadline reads it.
t0 <- ms_now(); t0_wall <- ms_clock("wall")
# ⛔ ONE TIMED CALL IS NOT A RATE. This measured a SINGLE evaluation and used it
# to project a 6,000-eval restart -- a 6,000x extrapolation from n = 1, on a
# shared node, where the first call is also the one most likely to be
# unrepresentative (cold caches, first touch of the forcing arrays). The MEDIAN
# of a few is still cheap (~1 s) and cannot be thrown by one outlier.
.tv <- vapply(seq_len(MS_RATE_SAMPLES), function(i) {
  .t <- ms_now(); invisible(lp_fun(u))
  ms_now() - .t
}, numeric(1))
MS_SEC_PER_EVAL <- stats::median(.tv)
cat(sprintf("measured %.4f %s (median of %d; range %.4f-%.4f) => one %d-eval restart\n  projects to %.1f %s; %s budget %g %s, of which %.1f %s is RESERVED for the\n  BFGS polish (%d iterations)\n",
            MS_SEC_PER_EVAL, MS_SPE_UNIT, MS_RATE_SAMPLES, min(.tv), max(.tv), MS_MAXIT,
            MS_SEC_PER_EVAL * MS_MAXIT / 60, MS_MIN_UNIT, MS_CLOCK_LABEL, MS_BUDGET_MIN, MS_MIN_UNIT,
            min(MS_PROJ_SAFETY * MS_POLISH_TARGET * (2 * length(CCX_PARAM_NAMES) + 1) *
                  MS_SEC_PER_EVAL / 60, MS_POLISH_RESERVE_FRAC * MS_BUDGET_MIN), MS_MIN_UNIT,
            MS_POLISH_TARGET))
# SAY IT OUT LOUD IF ONE RESTART CANNOT FIT THE BUDGET AT ALL -- that is a
# sizing error, and the task should announce it rather than quietly shorten
# every restart for hours.
if (MS_PROJ_SAFETY * MS_SEC_PER_EVAL * MS_MAXIT / 60 > MS_BUDGET_MIN)
  cat(sprintf("*** WARNING: a full %d-eval restart does NOT fit %g %s at this rate.\n    Every restart will be SHORTENED. Lower CCX_MS_MAXIT or raise %s.\n",
              MS_MAXIT, MS_BUDGET_MIN, MS_MIN_UNIT, MS_BUDGET_VAR))

# ⭐ THE PREFLIGHT EXITS **HERE**, NOT BEFORE THE RATE MEASUREMENT (moved
# 2026-09-01). Measuring s/eval costs 5 evaluations -- about two seconds -- and
# it is the ONE number that cannot be obtained from the reference machine: how
# fast this model runs on THIS node. Exiting above meant a preflight array on
# the cluster verified the environment and then threw away the measurement that
# sizes CCX_MS_MAXIT for every task after it. A preflight now does both.
if (MS_PREFLIGHT) {
  cat(sprintf("PREFLIGHT id %03d on %s: start %s, log-post %.4f, %d draw%s, port %s,\n             %.4f %s => a %d-eval restart takes %.1f %s of a %g %s budget. LAUNCHABLE.\n",
              MS_ID, Sys.info()[["nodename"]],
              if (MS_ID >= MS_DISPERSED_FROM) "dispersed"
              else if (MS_ID %in% MS_SEED_IDS) "SEEDED" else "REFERENCE", MS_START_LP,
              st$draws, if (st$draws == 1L) "" else "s",
              if (isTRUE(MS_PORT$checked)) sprintf("VERIFIED rel %.1e (floor %.1e, bound %.1e)", MS_PORT$rel, MS_PORT$floor, MS_PORT$tol)
              else "NOT VERIFIED",
              MS_SEC_PER_EVAL, MS_SPE_UNIT, MS_MAXIT, MS_SEC_PER_EVAL * MS_MAXIT / 60, MS_MIN_UNIT,
              MS_BUDGET_MIN, MS_MIN_UNIT))
  if (length(MS_SPREAD_OVERRIDE))
    cat(sprintf("             start at the overridden coordinates: %s\n",
                paste(sprintf("%s = %+.5f", names(MS_SPREAD_OVERRIDE), unlist(ccx_unc_to_par(st$u)[names(MS_SPREAD_OVERRIDE)])), collapse = ", ")))
  if (!isTRUE(MS_PORT$checked))
    stop("PREFLIGHT id ", MS_ID, ": the port is NOT verified, so this task would ",
         "spend its whole budget on an unchecked objective. Fix that before submitting.")
  if (!is.finite(MS_START_LP))
    stop("PREFLIGHT id ", MS_ID, ": the start point has a non-finite log-posterior.")
  quit(save = "no", status = 0)
}
elapsed_min      <- function() (ms_now() - t0) / 60                    # on MS_CLOCK: what the budget counts
elapsed_wall_min <- function() (ms_clock("wall") - t0_wall) / 60       # the record and D4's flag only
# D4 (Marcus 2026-10-05, "Warn only, at 2x (Recommended)"): FLAG a start whose wall time has passed
# MS_WALL_WARN_X x its budget -- it slept, or it is starved of CPU -- once, in the log and in the start file.
# It never stops the start. Under the wall clock the budget itself ends a start long before 2x.
wall_warned <- FALSE
flag_wall <- function() {
  if (MS_CLOCK == "wall" || wall_warned) return(invisible(NULL))
  w <- elapsed_wall_min()
  if (w > MS_WALL_WARN_X * MS_BUDGET_MIN) {
    wall_warned <<- TRUE
    cat(sprintf("*** [%03d] WALL time %.0f min has passed %g x the %g %s budget (%.1f %s spent): the machine\n      slept, or the task is starved of CPU. FLAGGED, not stopped (D4, CHANGELOG 2026-10-05 o).\n",
                MS_ID, w, MS_WALL_WARN_X, MS_BUDGET_MIN, MS_MIN_UNIT, elapsed_min(), MS_MIN_UNIT))
  }
  invisible(NULL)
}
restart_min <- numeric(0)
# ⇒ THE BUDGET SIZES THE RESTART; IT DOES NOT MERELY VETO IT. A task whose
# remaining budget cannot fit a FULL-maxit restart used to do nothing at all and
# check out with 0 evals, which spends the whole allocation to learn nothing.
# It now runs a SHORTER restart scaled to what is left. Returns 0 when even the
# floor does not fit, which is the only case where doing nothing is right.
# ⭐ THE POLISH GETS A RESERVED SLICE, NOT THE LEFTOVERS. Sizing it to whatever
# NM happens to leave makes its size an accident of how the last restart landed
# -- and at some budget geometries that is ZERO. The polish is measured to be
# worth 9.07 log-units from an NM-stalled point (08-31e §8.1), which is worth far
# more than the few thousand extra NM evals the reserve costs, so NM stops early
# enough to leave room for MS_POLISH_TARGET iterations.
polish_reserve_min <- function()
  min(MS_PROJ_SAFETY * MS_POLISH_TARGET * (2 * length(u) + 1) * MS_SEC_PER_EVAL / 60,
      MS_POLISH_RESERVE_FRAC * MS_BUDGET_MIN)

maxit_for_budget <- function() {
  left <- MS_BUDGET_MIN - elapsed_min() - polish_reserve_min()
  per  <- if (length(restart_min)) max(restart_min) / MS_MAXIT else MS_SEC_PER_EVAL / 60
  n    <- floor(left / (MS_PROJ_SAFETY * per))
  if (n < MS_MAXIT_FLOOR) 0L else as.integer(min(n, MS_MAXIT))
}
converged <- FALSE; out_of_time <- FALSE
deadline_stops <- 0L   # steps ended by the in-restart deadline (RECORDED in the start file)

restarts_done <- 0L
for (cyc in seq(cyc0, MS_CYCLES)) {
  cyc_start <- best
  cyc_restarts <- 0L
  for (i in seq_len(MS_RESTARTS)) {
    mx <- maxit_for_budget()
    if (mx == 0L) { out_of_time <- TRUE; break }
    if (mx < MS_MAXIT)
      cat(sprintf("[%03d] cycle %d restart %2d: SHORTENED to maxit %d by the %s budget\n",
                  MS_ID, cyc, i, mx, MS_CLOCK_LABEL))
    .r0 <- ms_now(); .n0 <- n_eval
    # the restart's deadline leaves the polish its reserved slice, as maxit_for_budget() does
    fit <- ms_run_step(MS_STEP, u, best, neg_lp, "Nelder-Mead", list(maxit = mx, reltol = 1e-12),
                       deadline = t0 + 60 * (MS_BUDGET_MIN - polish_reserve_min()))
    # NORMALISED to a FULL restart, because a shortened one is not comparable and
    # feeding it back raw would make the projection shrink every cycle -- by the
    # evaluations it ACTUALLY made (option A, proposal §3), not the planned maxit.
    restart_min <- c(restart_min, ms_restart_minutes((ms_now() - .r0) / 60, MS_MAXIT, n_eval - .n0))
    cyc_restarts <- cyc_restarts + 1L; restarts_done <- restarts_done + 1L
    if (isTRUE(fit$deadline)) {
      deadline_stops <- deadline_stops + 1L
      cat(sprintf("[%03d] cycle %d restart %2d: STOPPED AT THE DEADLINE after %d evals; the best EVALUATED point is kept\n",
                  MS_ID, cyc, i, n_eval - .n0))
    }
    gain <- best - fit$value; u <- fit$par; best <- fit$value
    cat(sprintf("[%03d] cycle %d restart %2d: log-post = %12.4f (gain %10.4f) evals %d  %.1f %s\n",
                MS_ID, cyc, i, -best, gain, n_eval, elapsed_min(), MS_MIN_UNIT))
    flag_wall()
    trace <- rbind(trace, data.frame(cycle = cyc, restart = i, logpost = -best, evals = n_eval))
    if (isTRUE(fit$deadline)) break     # no further restart fits; the polish keeps its reserved slice
    if (i > 1 && gain < MS_TOL) break
  }
  # ⛔ THE POLISH IS SHORTENED TO FIT, NOT VETOED -- AND WITHOUT THIS IT NEVER RAN
  # ON TORCH AT ALL (found 2026-09-01, working out what a longer wall would buy).
  # A 500-iteration BFGS costs ~500 x (2n+1) = 25,500 evals at n = 25 (22,500 at
  # the n = 22 this was first measured at), which is 157 min at the ~0.37 s/eval
  # a 2x-slower node implies -- so the admission test
  # `elapsed + 1.5 x 157 <= 180` is FALSE at elapsed = 0, forever. On the Mac's
  # 0.199 s/eval it projects to 73 min and runs, which is exactly why every local
  # smoke test looked fine and every Torch task would have skipped it.
  # ⚠ THAT WOULD NOT HAVE BEEN A SLOWDOWN, IT WOULD HAVE BEEN A WRONG ANSWER:
  # 08-31e §8.1 measured the polish gaining 9.07 from an NM-stalled point, so a
  # survey that never polishes under-reports the depth of every basin it finds
  # and can rank two basins the wrong way round.
  # Same idiom as maxit_for_budget(): size the step to the budget, and skip only
  # when even the floor does not fit.
  # ⚠ AT THE OBSERVED RATE since option A (proposal §3): this used the START point's measured rate, so a task
  # whose restarts had slowed near the h_ml wall sized its polish as if they had not.
  mx_pol <- ms_polish_maxit(MS_BUDGET_MIN - elapsed_min(), length(u), MS_SEC_PER_EVAL, restart_min, MS_MAXIT,
                            MS_PROJ_SAFETY, MS_POLISH_FLOOR, MS_POLISH_MAXIT)
  if (!out_of_time && mx_pol > 0L) {
    if (mx_pol < MS_POLISH_MAXIT)
      cat(sprintf("[%03d] cycle %d polish: SHORTENED to maxit %d by the %s budget\n",
                  MS_ID, cyc, mx_pol, MS_CLOCK_LABEL))
    .n0 <- n_eval
    # the deadline returns the best EVALUATED point; any OTHER error still discards the polish, as before
    pc <- tryCatch(ms_run_step(MS_STEP, u, best, neg_lp, "BFGS", list(maxit = mx_pol, reltol = 1e-14),
                               deadline = t0 + 60 * MS_BUDGET_MIN),
                   error = function(e) NULL)
    if (!is.null(pc) && isTRUE(pc$deadline)) {
      deadline_stops <- deadline_stops + 1L; out_of_time <- TRUE
      cat(sprintf("[%03d] cycle %d polish: STOPPED AT THE DEADLINE after %d evals; the best EVALUATED point is kept\n",
                  MS_ID, cyc, n_eval - .n0))
    }
    if (!is.null(pc) && pc$value < best) {
      cat(sprintf("[%03d] cycle %d polish: log-post = %.4f (gain %.4f)\n",
                  MS_ID, cyc, -pc$value, best - pc$value))
      u <- pc$par; best <- pc$value
    }
  } else if (!out_of_time) {
    cat(sprintf("[%03d] cycle %d polish SKIPPED: not even %d BFGS iterations fit the\n      remaining budget. This is the END of the round, not a defect.\n",
                MS_ID, cyc, MS_POLISH_FLOOR))
    out_of_time <- TRUE
  }
# ⛔ A CYCLE WHOSE POLISH WAS SKIPPED IS NOT A COMPLETED CYCLE, so its gain is
# not the quantity ARM_CYCLE_TOL was set against -- the BFGS half is exactly the
# half that gained 9.07 in the probe run from an NM-stalled point. Declaring
# CONVERGED on the NM-only gain would report the two states at once, which is
# what the first end-to-end run did: "CONVERGED" and "ran out of wall time" on
# the same task. `out_of_time` therefore vetoes convergence outright.
  cyc_gain <- cyc_start - best
  cat(sprintf("[%03d] === cycle %d total gain %.4f (log-post %.4f, %d evals, %.1f %s) ===\n",
              MS_ID, cyc, cyc_gain, -best, n_eval, elapsed_min(), MS_MIN_UNIT))
  flag_wall()
  # CHECKPOINT EVERY CYCLE. A wall-clock kill must leave the best-so-far on disk
  # and a requeue must be able to continue it -- that is what makes a 4 h
  # partition usable for a job whose length is not known in advance.
  # ⭐ `param_names` IS RECORDED SO THE RESUME CAN REFUSE A STALE CHECKPOINT
  # (2026-09-01j). A checkpoint is a `u` vector, and a `u` vector is only
  # meaningful under the parameter set it was written for -- this project moved
  # that set TWICE in three days (seas_lag_p 21->22 on 08-31, ENSO 22->25 on
  # 09-01). Resuming a 22-parameter checkpoint into a 25-parameter build dies
  # inside ccx_make_logpost() as "names attribute [25] must be the same length
  # as the vector [22]", three frames below the cause and naming none of it.
  # Recorded AND READ, at the resume below [[recorded_but_never_restored]].
  # ⭐ AND `ref_logpost` IS RECORDED FOR THE SAME REASON, ONE LEVEL UP
  # (2026-09-02). `param_names` proves the checkpoint was written under this
  # PARAMETER SET; it says nothing about the OBJECTIVE, and on 2026-09-02 the
  # objective moved three times while the set stayed at 25 -- T-dependent
  # air-sea 13C alphas, the one-way GPP ENSO term, and Ruling A's demeaning,
  # the last worth +56.4785 on its own. A 09-01 checkpoint has 25 names that
  # match exactly, so the guard above would have WAVED IT THROUGH and the task
  # would have resumed a pre-adoption `best` into a post-adoption objective.
  # The stamp is the FIXED reference point's own value, not a commit hash: it
  # is derived from the objective itself rather than from a proxy that a
  # comment-only commit would move [[threshold_from_obs_or_law]].
  saveRDS(list(id = MS_ID, u = u, best = best, cycle = cyc, trace = trace,
               n_eval = n_eval, seed = MS_SEED + MS_ID,
               param_names = CCX_PARAM_NAMES, ref_logpost = MS_REF_LP, pins = MS_PINS), MS_CKPT)
  # ⛔ A CYCLE THAT RAN NO RESTART IS NOT A CONVERGED CYCLE. It gained 0.0000
  # because nothing was tried, and `0 < MS_CYCLE_TOL` is true for exactly that
  # reason -- so the budget guard firing before the first restart used to print
  # "WALL BUDGET REACHED -- NOT converged" and then "CONVERGED" three lines
  # later, on a task with 0 evals. A null that is structurally guaranteed reports
  # the same string as one that looked and found nothing ([[no_power_null]]).
  if (!out_of_time && cyc_restarts > 0L && cyc_gain < MS_CYCLE_TOL) {
    converged <- TRUE; break
  }
  if (out_of_time) break
}
if (out_of_time)
  cat(sprintf("*** [%03d] %s BUDGET %g %s REACHED -- checkpointed, NOT converged.\n",
              MS_ID, toupper(MS_CLOCK_LABEL), MS_BUDGET_MIN, MS_MIN_UNIT))

names(u) <- CCX_PARAM_NAMES
pm <- ccx_unc_to_par(u)
# THE STAMP READS THE STRUCTURE THE FIT READ (2026-09-17). The objective
# evaluates every prior at `bp` + the draw (u_hs's Sv-to-m/yr centre converts at
# the LIVE hs_frac, 2026-09-16 d); this stamp passed no list, so ccx_prior_z()
# fell back to the built 0.16 and every hilda_c start file recorded u_hs at
# z +0.16 where the objective had scored it at -0.75. The fit was right (the
# logpost closes to loglik + logprior at the live list to 1e-4); the LABEL was
# wrong. Same base + this draw's values, exactly as ccx_make_logpost() does.
p_stamp <- bp; for (n in names(pm)) p_stamp[[n]] <- pm[[n]]
zs <- vapply(CCX_PARAM_NAMES,
             function(n) tryCatch(ccx_prior_z(n, pm[[n]], p = p_stamp), error = function(e) NA_real_),
             numeric(1))
# DEAD-TASK CHECK (2026-09-10): the point this task reports must be a point OF
# THE OBJECTIVE -- finite under lp_fun itself, and equal to what the optimiser
# says. A best on the penalty plateau is not a result; before this check it was
# written as converged = TRUE and exited 0 (ids 9/12/23 of 17343694). RECORDED
# in the file (so the collector can refuse it) AND fatal below (so SLURM says FAILED).
.final_lp <- lp_fun(u)
dead <- !is.finite(.final_lp) || abs(.final_lp - (-best)) > MS_EVAL_TOL * max(1, abs(best))
if (dead) converged <- FALSE

res <- list(id = MS_ID, kind = st$kind, u_mode = u, par_mode = pm, logpost = -best,
            logpost_start = trace$logpost[1], converged = converged, dead = dead,
            final_lp_check = .final_lp,
            out_of_time = out_of_time, cycles = if (exists("cyc")) cyc else 0L,
            restarts_done = restarts_done, deadline_stops = deadline_stops,
            trace = trace, n_eval = n_eval, minutes = elapsed_min(),
            sec_per_eval = MS_SEC_PER_EVAL, restart_min = restart_min,
            # RECORDED (2026-10-05 o): the clock `minutes`, `sec_per_eval` and `restart_min` are on, the budget
            # they ran against, the WALL minutes beside them, and D4's flag. An absent `clock` reads as "wall"
            # (ms_start_clock()): every file written before then ran the wall clock.
            clock = MS_CLOCK, budget_min = MS_BUDGET_MIN, minutes_wall = elapsed_wall_min(),
            wall_warned = wall_warned,
            prior_z = zs, param_names = CCX_PARAM_NAMES, pump_mode = MS_ARM,
            # RECORDED (2026-09-08f) so a promoted mode carries the structure it
            # was fitted under; consumed by promote_multistart_mode.R / ccx_mode_base().
            struct = MS_STRUCT,
            # RECORDED (2026-09-10) for the same reason and the same consumers:
            # a promoted mode must carry the seasonal-mixed-layer setting it was
            # fitted at, or ccx_mode_base() scores it on the other objective.
            seas_ml = MS_SEAS_ML,
            # RECORDED (2026-09-14 h): the pump field's construction this start was
            # fitted under; ccx_mode_pump_field() reads an absent field as "solved".
            pump_field = MS_PUMP_FIELD,
            # RECORDED (2026-09-13): the pins this start was fitted under (NULL = free).
            # promote_multistart_mode.R applies them before GATE 1; ccx_mode_base() carries them.
            pins = MS_PINS,
            # RECORDED **AND** READ by collect_dispersed_multistart.R's VERDICT.
            # ⛔ THE BOUND ON "did this start reach that one" IS THIS OPTIMISER'S
            # OWN CONVERGENCE TOLERANCE, and the only file that knows it is the
            # one that ran it. Before 2026-09-01e the collector hardcoded 1e-8 --
            # the right bound for the EVALUATION identity of the port gate and
            # the wrong one for comparing two optimiser OUTPUTS -- and printed
            # "4 dispersed starts did NOT reach the best re-converged known
            # basin" for a difference of -0.0000 [[gate_bound_matches_its_claim]].
            restart_tol = MS_TOL, cycle_tol = MS_CYCLE_TOL,
            seed = MS_SEED + MS_ID, spread = MS_SPREAD,
            spread_by_name = MS_SPREAD_OVERRIDE,   # the per-coordinate overrides (2026-09-30 p); empty = none
            spread_measured = MS_SPREAD_MEASURED, draws = st$draws,
            # RECORDED **AND** READ by collect_dispersed_multistart.R: which
            # kind of start this was, and what the dispersion was pooled over.
            # A `start_*.rds` whose `kind` string is the only record of whether
            # it was seeded cannot be grouped by a collector without parsing
            # prose [[recorded_but_never_restored]].
            start_class = if (MS_ID >= MS_DISPERSED_FROM) "dispersed"
                          else if (MS_ID %in% MS_SEED_IDS) "seeded" else "reference",
            spread_pool = MS_SPREAD_POOL, spread_skipped = MS_SPREAD_SKIP,
            spread_all = MS_SPREAD_ALL,
            enso_seed = c(ocn_opt = MS_ENSO_OCN_OPT, ocn_obs = MS_ENSO_OCN_OBS,
                          land_obs_mult = MS_ENSO_LAND_OBS),
            port_checked = MS_PORT$checked, port_target = MS_PORT$target,
            port_rel = MS_PORT$rel, port_diff = MS_PORT$diff,
            port_floor = MS_PORT$floor, port_tol = MS_PORT$tol,   # the MEASURED floor + derived bound (2026-09-15)
            ref_logpost = MS_REF_LP, resumed = MS_RESUMED,
            # RECORDED **AND** RESTORED: these are the fields ccx_mode_bands()
            # reads. [[recorded_but_never_restored]] -- a band written by a
            # producer and consumed by no reader decoded 26 % wrong for a
            # fortnight. Written here because a downstream reader needs them.
            hml_bound = .ship$h_ml, kz_bracket = .ship$kz,
            table_kz = .ship$kz, table_hml = .ship$h_ml,
            host = Sys.info()[["nodename"]],
            r_version = paste(R.version$major, R.version$minor, sep = "."))
saveRDS(res, MS_OUT)

cat(sprintf("\n[%03d] FINAL log-post %.4f  (%s, %d restart%s, %d evals, %.1f %s%s)\n",
            MS_ID, -best,
            if (converged) "CONVERGED"
            else if (restarts_done == 0L) sprintf("*** NO RESTART RAN -- the %s budget did not fit ONE", MS_CLOCK_LABEL)
            else if (out_of_time) "OUT OF TIME" else "restart budget spent",
            restarts_done, if (restarts_done == 1L) "" else "s", n_eval, elapsed_min(), MS_MIN_UNIT,
            if (MS_CLOCK == "wall") ""
            else sprintf("; %.1f wall-min%s", elapsed_wall_min(), if (wall_warned) ", FLAGGED (D4)" else "")))
# The RESTARTS' own rate, not the clock over the whole task: the start evaluation,
# the compile and the checkpoint writes are not per-eval costs, and a task with
# NO restart has no rate at all rather than a large one.
# ⚠ FIXED 2026-10-06 (Marcus: "Fix eval-rate line (Recommended)"): this printed
# 60 x sum(restart_min) / n_eval, NORMALISED minutes over ALL evals (the polish's
# too), wrong both ways -- 0.0333 for a true 0.2935, 32.8 for a true 1.149 (CHANGELOG
# 10-06 d). ms_eval_rate_sec() is the slowest restart's rate, the one the polish
# and maxit_for_budget() size on.
# ⚠ BRACES: at TOP LEVEL R parses `if (...) expr` as complete and then meets a
# bare `else` as a new statement -- "unexpected 'else'". Inside a function or a
# braced block the same code is fine, which is why this reads as correct.
.rate <- ms_eval_rate_sec(restart_min, MS_MAXIT)
if (!is.null(.rate)) {
  cat(sprintf("[%03d] eval rate %.4f %s, the slowest of %d restart%s (fastest %.4f) -- SIZE THE ARRAY ON THIS\n",
              MS_ID, .rate[["slowest"]], MS_SPE_UNIT, length(restart_min),
              if (length(restart_min) == 1L) "" else "s", .rate[["fastest"]]))
} else {
  cat(sprintf("[%03d] eval rate: NOT MEASURED (no restart ran). The start evaluation alone\n      timed %.4f %s; raise %s or lower CCX_MS_MAXIT.\n",
              MS_ID, MS_SEC_PER_EVAL, MS_SPE_UNIT, MS_BUDGET_VAR))
}

# ---- DEAD-TASK GATE: fatal, AFTER the file is written (see `dead` above).
if (dead)
  stop("DEAD TASK id ", MS_ID, ": the reported optimum ", sprintf("%.4f", -best),
       " is not a finite point of the objective (lp_fun there = ", .final_lp,
       "). The search ended on the infeasible-step penalty plateau; this is a ",
       "failure, not a convergence. Its start file has been written for the ",
       "post-mortem but must NOT be collected as a basin.")
# ---- PORT GATE (b): an ORDERING, which is the only claim available about an
# OPTIMISED value. A maximiser that returns less than it was handed is broken,
# and that is true of every start, not only the reference ones -- so this one
# runs unconditionally.
if (-best < MS_START_LP - MS_EVAL_TOL * abs(MS_START_LP))
  stop("PORT GATE (b) FAILED for id ", MS_ID, ": the optimiser returned ",
       sprintf("%.6f", -best), ", BELOW the ", sprintf("%.6f", MS_START_LP),
       " it started from. That is not a convergence question; the search is ",
       "broken on this machine.")
cat(sprintf("[%03d] PORT GATE (b) ordering: final %.4f >= start %.4f. OK\n",
            MS_ID, -best, MS_START_LP))
if (!is.na(st$ref))
  cat(sprintf("[%03d] for reference: the mode FILE stores %.4f; the difference from\n      this run's start value is objective drift, not a port defect.\n",
              MS_ID, st$ref))
cat(sprintf("%s\n", strrep("=", 70)))
