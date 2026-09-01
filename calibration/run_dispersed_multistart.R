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
# THE THREE REFERENCE STARTS ARE THE PORT'S OWN GATE. Ids 0, 1 and 2 are not
# dispersed:
#   id 0  the COLD hand-set init            -- the control the refits all quote
#   id 1  the INCUMBENT (08-30 landed)      -- must re-find -1548.01
#   id 2  the NEW BASIN (08-31e polished)   -- must re-find -1496.01
# Ids 1 and 2 are warm starts at points ALREADY converged on the Mac, so on any
# machine they must return those numbers to within the optimiser's own noise.
# ⚠ THE TARGETS COME FROM FILES THIS SCRIPT DID NOT WRITE ([[gate_reads_its_own_output]]):
# they are read out of the two mode files, not restated as literals here, and a
# port that silently changes the objective fails them. Run ids 0-2 FIRST, before
# any large array.
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
# Usage
#   CCX_MS_ID=7 Rscript calibration/run_dispersed_multistart.R
#   (or let it read SLURM_ARRAY_TASK_ID)
# Knobs, all env, all printed when overridden:
#   CCX_MS_ID        start index; else SLURM_ARRAY_TASK_ID; else 0
#   CCX_MS_OUTDIR    output dir (default calibration/output/multistart_<date>)
#   CCX_MS_RESTARTS  Nelder-Mead restarts per cycle          (default 3)
#   CCX_MS_CYCLES    NM-then-BFGS cycles                     (default 6)
#   CCX_MS_MAXIT     NM iterations per restart               (default 6000)
#   CCX_MS_WALL_MIN  wall budget in MINUTES; stop cleanly    (default 210)
#   CCX_MS_SPREAD    dispersion sd in u-space               (default: measured)
#   CCX_MS_SEED      base seed; start k uses SEED + k        (default 2026)
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
source(ccx_path("calibration", "lib_run_inputs.R"))
ccx_require_run_inputs()   # BEFORE the wall budget, and before any target is written

# ---- named constants ------------------------------------------------
MS_ARM        <- "N"          # the shipped arm; see run_modefind_pump_arms.R
MS_SEED_BASE  <- 2026
MS_PENALTY    <- 1e6          # finite stand-in for -Inf, as the serial driver
MS_TOL        <- 1e-4         # a restart gaining less than this stops the cycle
MS_CYCLE_TOL  <- 0.5          # = ARM_CYCLE_TOL; a cycle below this is CONVERGED
MS_DRAW_TRIES <- 200          # redraws allowed before a start is declared dead
MS_REF_INC    <- "calibration/output/refit_20260831_seas_lag_split/from90/mode_fit_pumpN.rds"
MS_REF_NEW    <- "calibration/output/polish_20260831_probe_basin/from90/mode_fit_pumpN.rds"
MS_REF_IDS    <- c(cold = 0L, incumbent = 1L, new_basin = 2L)
MS_TARGETS    <- "calibration/torch/port_targets.csv"
# THE PORT GATE IS TWO GATES, AND EACH BOUND MATCHES ITS OWN CLAIM
# ([[gate_bound_matches_its_claim]]):
#   (a) the START value is an EVALUATION of one fixed point, so machine A and
#       machine B must agree to floating-point, and the bound is RELATIVE and
#       tight. This is what actually catches a bad port -- a different BLAS, a
#       different libm, a half-copied data file.
#   (b) the FINAL value is the result of an OPTIMISATION from that point, so the
#       only claim available is an ORDERING: it may not come back WORSE than
#       where it started. No invented threshold ([[threshold_from_obs_or_law]]).
# The old single 1.0-log-unit bound was neither: it compared an optimised value
# against the mode file's STORED logpost, 85 % of which the incumbent's known
# -0.85 objective-drift offset spent before the port was even considered.
MS_EVAL_TOL   <- 1e-8         # relative, on a pure evaluation identity

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
MS_WALL_MIN <- .env_num("CCX_MS_WALL_MIN", 210)
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

MS_OUTDIR <- local({
  d <- Sys.getenv("CCX_MS_OUTDIR", NA_character_)
  if (is.na(d) || !nzchar(d))
    ccx_path("calibration", "output", "multistart_20260831")
  else d
})
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
  .pm <- ccx_migrate_par_set(.r[[2]]$par_mode)
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
U_INC <- ccx_par_to_unc(ccx_migrate_par_set(.mdI$par_mode))
U_NEW <- ccx_par_to_unc(ccx_migrate_par_set(.mdN$par_mode))
U_COLD <- ccx_init_unc()
MS_SPREAD_MEASURED <- sqrt(mean((U_NEW - U_INC)^2))
MS_SPREAD <- .env_num("CCX_MS_SPREAD", MS_SPREAD_MEASURED)

cat(sprintf("\n%s\nDISPERSED MULTI-START, id %d, arm %s, %d parameters\n",
            strrep("=", 70), MS_ID, MS_ARM, length(CCX_PARAM_NAMES)))
cat(sprintf("  host %s   R %s   seed %d + id\n", Sys.info()[["nodename"]],
            paste(R.version$major, R.version$minor, sep = "."), MS_SEED))
cat(sprintf("  budget: %d restarts x %d maxit x %d cycles, wall %g min\n",
            MS_RESTARTS, MS_MAXIT, MS_CYCLES, MS_WALL_MIN))
cat(sprintf("  dispersion sd %.4f in u-space (measured per-coordinate RMS between\n    the two known basins = %.4f)\n",
            MS_SPREAD, MS_SPREAD_MEASURED))
cat(sprintf("  out %s\n%s\n", MS_OUT, strrep("=", 70)))

bp <- ccx_default_params(); bp$pump_mode <- MS_ARM
lp_fun <- ccx_make_logpost(base_params = bp)
n_eval <- 0L
neg_lp <- function(u) {
  n_eval <<- n_eval + 1L
  v <- lp_fun(u)
  if (!is.finite(v)) return(MS_PENALTY)
  -v
}

# ---- the start point for THIS id ------------------------------------
# DETERMINISTIC PER ID, so start k is the same point whether it runs alone, in
# an array of 8 or in an array of 400, and a failed task can be requeued without
# changing what it was. That is the property `set.seed(ARM_SEED)` gives the
# serial driver, carried over to a fan-out.
ms_start <- function(id) {
  if (id == MS_REF_IDS[["cold"]])
    return(list(u = U_COLD, kind = "reference: COLD hand-set init", draws = 0L, ref = NA_real_))
  if (id == MS_REF_IDS[["incumbent"]])
    return(list(u = U_INC, kind = "reference: INCUMBENT (08-30 landed)",
                draws = 0L, ref = .mdI$logpost))
  if (id == MS_REF_IDS[["new_basin"]])
    return(list(u = U_NEW, kind = "reference: NEW BASIN (08-31e polished)",
                draws = 0L, ref = .mdN$logpost))
  set.seed(MS_SEED + id)
  for (k in seq_len(MS_DRAW_TRIES)) {
    u <- U_COLD + MS_SPREAD * stats::rnorm(length(U_COLD))
    names(u) <- CCX_PARAM_NAMES
    if (is.finite(lp_fun(u)))
      return(list(u = u, kind = sprintf("dispersed about the COLD init, sd %.4f", MS_SPREAD),
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
  # task has no target of its own, so it evaluates the NEW-BASIN reference point
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
  tg <- utils::read.csv(f, stringsAsFactors = FALSE)
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
  tgt <- as.numeric(r$logpost[1])
  # THE VALUE THIS TASK EVALUATES AT THE REFERENCE POINT. For ids 0-2 that IS
  # their own start point and is already in hand; for a dispersed id it is a
  # point this task never visits, so evaluate it -- one call, and the whole
  # justification for doing so is that it is cheap.
  here <- if (identical(MS_ID, unname(MS_REF_IDS[[nm]]))) MS_REF_LP
          else lp_fun(switch(nm, cold = U_COLD, incumbent = U_INC, new_basin = U_NEW))
  rel <- abs(here - tgt) / max(abs(tgt), 1e-12)
  cat(sprintf("PORT GATE (a) at the %s reference point: here %.10f vs %s@%s %.10f,\n              rel %.2e (tol %.0e)%s\n",
              nm, here, r$host[1], r$commit[1], tgt, rel, MS_EVAL_TOL,
              if (identical(MS_ID, unname(MS_REF_IDS[[nm]]))) "" else "  [this task's own start is elsewhere]"))
  if (rel > MS_EVAL_TOL)
    stop("PORT GATE (a) FAILED: this machine does not reproduce the objective ",
         "at a FIXED point to ", MS_EVAL_TOL, " relative. Every dispersed start ",
         "in this array would then be optimising something other than the ",
         "objective the reference modes were fitted on. STOP AND DIAGNOSE ",
         "before submitting the survey.")
  MS_PORT <<- list(checked = TRUE, target = tgt, rel = rel)
  cat("PORT GATE (a) PASSED.\n")
})

# ---- the wall budget, PROJECTED rather than merely checked ------------
if (MS_PREFLIGHT) {
  cat(sprintf("PREFLIGHT id %03d: start %s, log-post %.4f, %d draw%s, port %s. LAUNCHABLE.\n",
              MS_ID, if (st$draws == 0L) "REFERENCE" else "dispersed", MS_START_LP,
              st$draws, if (st$draws == 1L) "" else "s",
              if (isTRUE(MS_PORT$checked)) sprintf("VERIFIED rel %.1e", MS_PORT$rel)
              else "NOT VERIFIED"))
  if (!isTRUE(MS_PORT$checked))
    stop("PREFLIGHT id ", MS_ID, ": the port is NOT verified, so this task would ",
         "spend its whole budget on an unchecked objective. Fix that before submitting.")
  if (!is.finite(MS_START_LP))
    stop("PREFLIGHT id ", MS_ID, ": the start point has a non-finite log-posterior.")
  quit(save = "no", status = 0)
}

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
# still fits `MS_WALL_MIN`, so the worst case is a restart that begins just
# inside the budget and then runs LONGER than projected -- which is exactly what
# node contention does ([[eta_in_days_is_not_a_slow_run]]: a 1.61x degradation
# was measured on this very model). With SAFETY = 1.5 and MS_WALL_MIN set 60 min
# below the SLURM wall, a restart would have to overrun its projection by more
# than 2.5x to reach the hard cap. At 1.25 with a 30 min gap, 2x was enough.
MS_PROJ_SAFETY <- 1.5
MS_RATE_SAMPLES <- 5
t0 <- Sys.time()
# ⛔ ONE TIMED CALL IS NOT A RATE. This measured a SINGLE evaluation and used it
# to project a 6,000-eval restart -- a 6,000x extrapolation from n = 1, on a
# shared node, where the first call is also the one most likely to be
# unrepresentative (cold caches, first touch of the forcing arrays). The MEDIAN
# of a few is still cheap (~1 s) and cannot be thrown by one outlier.
.tv <- vapply(seq_len(MS_RATE_SAMPLES), function(i) {
  .t <- Sys.time(); invisible(lp_fun(u))
  as.numeric(difftime(Sys.time(), .t, units = "secs"))
}, numeric(1))
MS_SEC_PER_EVAL <- stats::median(.tv)
cat(sprintf("measured %.4f s/eval (median of %d; range %.4f-%.4f) => one %d-eval restart\n  projects to %.1f min, and the wall budget is %g min\n",
            MS_SEC_PER_EVAL, MS_RATE_SAMPLES, min(.tv), max(.tv), MS_MAXIT,
            MS_SEC_PER_EVAL * MS_MAXIT / 60, MS_WALL_MIN))
# SAY IT OUT LOUD IF ONE RESTART CANNOT FIT THE BUDGET AT ALL -- that is a
# sizing error, and the task should announce it rather than quietly shorten
# every restart for hours.
if (MS_PROJ_SAFETY * MS_SEC_PER_EVAL * MS_MAXIT / 60 > MS_WALL_MIN)
  cat(sprintf("*** WARNING: a full %d-eval restart does NOT fit %g min at this rate.\n    Every restart will be SHORTENED. Lower CCX_MS_MAXIT or raise CCX_MS_WALL_MIN.\n",
              MS_MAXIT, MS_WALL_MIN))
elapsed_min <- function() as.numeric(difftime(Sys.time(), t0, units = "mins"))
restart_min <- numeric(0)
MS_MAXIT_FLOOR <- 200     # evals below which a restart is not worth entering
# ⇒ THE BUDGET SIZES THE RESTART; IT DOES NOT MERELY VETO IT. A task whose
# remaining budget cannot fit a FULL-maxit restart used to do nothing at all and
# check out with 0 evals, which spends the whole allocation to learn nothing.
# It now runs a SHORTER restart scaled to what is left. Returns 0 when even the
# floor does not fit, which is the only case where doing nothing is right.
maxit_for_budget <- function() {
  left <- MS_WALL_MIN - elapsed_min()
  per  <- if (length(restart_min)) max(restart_min) / MS_MAXIT else MS_SEC_PER_EVAL / 60
  n    <- floor(left / (MS_PROJ_SAFETY * per))
  if (n < MS_MAXIT_FLOOR) 0L else as.integer(min(n, MS_MAXIT))
}
converged <- FALSE; out_of_time <- FALSE

restarts_done <- 0L
for (cyc in seq(cyc0, MS_CYCLES)) {
  cyc_start <- best
  cyc_restarts <- 0L
  for (i in seq_len(MS_RESTARTS)) {
    mx <- maxit_for_budget()
    if (mx == 0L) { out_of_time <- TRUE; break }
    if (mx < MS_MAXIT)
      cat(sprintf("[%03d] cycle %d restart %2d: SHORTENED to maxit %d by the wall budget\n",
                  MS_ID, cyc, i, mx))
    .r0 <- Sys.time()
    fit <- optim(u, neg_lp, method = "Nelder-Mead",
                 control = list(maxit = mx, reltol = 1e-12))
    # NORMALISED to a FULL restart, because a shortened one is not comparable and
    # feeding it back raw would make the projection shrink every cycle.
    restart_min <- c(restart_min,
                     as.numeric(difftime(Sys.time(), .r0, units = "mins")) * MS_MAXIT / mx)
    cyc_restarts <- cyc_restarts + 1L; restarts_done <- restarts_done + 1L
    gain <- best - fit$value; u <- fit$par; best <- fit$value
    cat(sprintf("[%03d] cycle %d restart %2d: log-post = %12.4f (gain %10.4f) evals %d  %.1f min\n",
                MS_ID, cyc, i, -best, gain, n_eval, elapsed_min()))
    trace <- rbind(trace, data.frame(cycle = cyc, restart = i, logpost = -best, evals = n_eval))
    if (i > 1 && gain < MS_TOL) break
  }
  # The BFGS polish is capped at 500 iterations but each costs a GRADIENT, i.e.
  # ~2n evals, so it is projected on the same rule rather than assumed cheap.
  if (!out_of_time && elapsed_min() + MS_PROJ_SAFETY * 500 * 2 *
        length(u) * MS_SEC_PER_EVAL / 60 <= MS_WALL_MIN) {
    pc <- tryCatch(optim(u, neg_lp, method = "BFGS",
                         control = list(maxit = 500, reltol = 1e-14)),
                   error = function(e) NULL)
    if (!is.null(pc) && pc$value < best) {
      cat(sprintf("[%03d] cycle %d polish: log-post = %.4f (gain %.4f)\n",
                  MS_ID, cyc, -pc$value, best - pc$value))
      u <- pc$par; best <- pc$value
    }
  } else if (!out_of_time) {
    cat(sprintf("[%03d] cycle %d polish SKIPPED: it does not fit the remaining budget\n",
                MS_ID, cyc))
    out_of_time <- TRUE
  }
# ⛔ A CYCLE WHOSE POLISH WAS SKIPPED IS NOT A COMPLETED CYCLE, so its gain is
# not the quantity ARM_CYCLE_TOL was set against -- the BFGS half is exactly the
# half that gained 9.07 in the probe run from an NM-stalled point. Declaring
# CONVERGED on the NM-only gain would report the two states at once, which is
# what the first end-to-end run did: "CONVERGED" and "ran out of wall time" on
# the same task. `out_of_time` therefore vetoes convergence outright.
  cyc_gain <- cyc_start - best
  cat(sprintf("[%03d] === cycle %d total gain %.4f (log-post %.4f, %d evals, %.1f min) ===\n",
              MS_ID, cyc, cyc_gain, -best, n_eval, elapsed_min()))
  # CHECKPOINT EVERY CYCLE. A wall-clock kill must leave the best-so-far on disk
  # and a requeue must be able to continue it -- that is what makes a 4 h
  # partition usable for a job whose length is not known in advance.
  saveRDS(list(id = MS_ID, u = u, best = best, cycle = cyc, trace = trace,
               n_eval = n_eval, seed = MS_SEED + MS_ID), MS_CKPT)
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
  cat(sprintf("*** [%03d] WALL BUDGET %g min REACHED -- checkpointed, NOT converged.\n",
              MS_ID, MS_WALL_MIN))

names(u) <- CCX_PARAM_NAMES
pm <- ccx_unc_to_par(u)
zs <- vapply(CCX_PARAM_NAMES,
             function(n) tryCatch(ccx_prior_z(n, pm[[n]]), error = function(e) NA_real_),
             numeric(1))

res <- list(id = MS_ID, kind = st$kind, u_mode = u, par_mode = pm, logpost = -best,
            logpost_start = trace$logpost[1], converged = converged,
            out_of_time = out_of_time, cycles = if (exists("cyc")) cyc else 0L,
            restarts_done = restarts_done,
            trace = trace, n_eval = n_eval, minutes = elapsed_min(),
            sec_per_eval = MS_SEC_PER_EVAL, restart_min = restart_min,
            prior_z = zs, param_names = CCX_PARAM_NAMES, pump_mode = MS_ARM,
            seed = MS_SEED + MS_ID, spread = MS_SPREAD,
            spread_measured = MS_SPREAD_MEASURED, draws = st$draws,
            port_checked = MS_PORT$checked, port_target = MS_PORT$target,
            port_rel = MS_PORT$rel, ref_logpost = MS_REF_LP, resumed = MS_RESUMED,
            # RECORDED **AND** RESTORED: these are the fields ccx_mode_bands()
            # reads. [[recorded_but_never_restored]] -- a band written by a
            # producer and consumed by no reader decoded 26 % wrong for a
            # fortnight. Written here because a downstream reader needs them.
            hml_bound = .ship$h_ml, kz_bracket = .ship$kz,
            table_kz = .ship$kz, table_hml = .ship$h_ml,
            host = Sys.info()[["nodename"]],
            r_version = paste(R.version$major, R.version$minor, sep = "."))
saveRDS(res, MS_OUT)

cat(sprintf("\n[%03d] FINAL log-post %.4f  (%s, %d restart%s, %d evals, %.1f min)\n",
            MS_ID, -best,
            if (converged) "CONVERGED"
            else if (restarts_done == 0L) "*** NO RESTART RAN -- the wall budget did not fit ONE"
            else if (out_of_time) "OUT OF TIME" else "restart budget spent",
            restarts_done, if (restarts_done == 1L) "" else "s", n_eval, elapsed_min()))
# The optimiser's own evals, not the wall clock over them: the start evaluation,
# the compile and the checkpoint writes are not per-eval costs, and a task with
# NO evals has no rate at all rather than a large one.
# ⚠ BRACES: at TOP LEVEL R parses `if (...) expr` as complete and then meets a
# bare `else` as a new statement -- "unexpected 'else'". Inside a function or a
# braced block the same code is fine, which is why this reads as correct.
if (n_eval > 0L && sum(restart_min) > 0) {
  cat(sprintf("[%03d] eval rate %.4f s/eval in the optimiser -- SIZE THE ARRAY ON THIS\n",
              MS_ID, 60 * sum(restart_min) / n_eval))
} else {
  cat(sprintf("[%03d] eval rate: NOT MEASURED (no restart ran). The start evaluation alone\n      timed %.4f s/eval; raise CCX_MS_WALL_MIN or lower CCX_MS_MAXIT.\n",
              MS_ID, MS_SEC_PER_EVAL))
}

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
