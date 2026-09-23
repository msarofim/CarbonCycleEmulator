# =====================================================================
# diag_rep_dc_release_test.R -- T2 (the R2 test menu, 2026-09-22):
# "WHO is holding `rep_dC` up, and does the cost COLLAPSE when you let them go?"
#
# ⛔⛔ THESE ARE DIAGNOSTIC ARMS AND NONE OF THEM IS ADOPTABLE. Dropping an
# observational block or re-weighting one is an OBJECTIVE change (freeze record
# §4.1: a ruling, then a restamp of every mode). Nothing here is written to a
# mode file and no constant is mutated.
#
# WHAT THE TEST IS FOR. T-(u) found that forcing `rep_dC` down does NOT hurt the
# modern flask records the prior is nominally about -- `co2_level_MLO` +0.92,
# `co2_level_SPO` +0.31, `d13c_level_SPO` +8.56 all IMPROVE. The cost falls on
# `co2_icecore` (-13.45) and the bomb-14C pair (`d14c_SH` -7.55, `d14c_NH`
# -3.12). So the offset is held up by the PREINDUSTRIAL ICE ANCHOR and the BOMB
# VENTILATION CONSTRAINT. T2 releases each of those in turn and asks whether the
# cost collapses:
#   arm A -- the ice sigma at its MEASURED scatter instead of its stated one.
#            If the cost collapses here, `rep_dC` is standing in for a MIS-SET
#            ICE WEIGHT.
#   arm B -- the ice block dropped entirely. If the cost collapses here but not
#            under A, it is a PREINDUSTRIAL-ANCHOR error, not a weight.
#   arm C -- the bomb-14C pair dropped. If the cost collapses here, it is a
#            VENTILATION constraint doing the holding.
#
# ⛔⛔ THE ONE THING THIS SCRIPT MUST NOT LET A READER DO: compare a logpost
# ACROSS arms. Arms B and C score FEWER rows and arm A scores one row with a
# different sigma, so their totals are on different objectives and are not
# comparable by construction. The ONLY comparable quantity is the DELTA ALONG
# THE LADDER WITHIN an arm -- what it costs that arm to force `rep_dC` down --
# and the report prints deltas for exactly that reason.
#
# ⚠ THE ICE SIGMA IS RE-MEASURED, NOT QUOTED. The 1.05 ppm figure comes from
# notes/handoff_2026-08-23_sweep_refit_and_rep_dC.md:199-201 ("the ice term's
# stated sigma is ~4.04 ppm against a MEASURED scatter of 1.05 ppm about the
# flask record"). That is our own note, which is not a citation -- so arm A
# re-derives the scatter from the ice-vs-flask overlap here and REFUSES to run
# if the re-measured value disagrees with the recalled one by more than
# RT_SIGMA_TOL. A threshold comes from an observation, not from a memory of one.
#
# Usage:
#   Rscript calibration/diag_rep_dc_release_test.R <job|all|collect|scout>
# `scout` re-measures the ice scatter and prints the job table without running.
# =====================================================================
.root <- local({
  d <- normalizePath(getwd(), mustWork = FALSE)
  for (i in 1:8) { if (file.exists(file.path(d, "DESIGN.md"))) break; d <- dirname(d) }
  d
})
setwd(.root)
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

# ---- NAMED CONSTANTS -------------------------------------------------
RT_TAG      <- "rep_dc_release_test"
RT_DATE     <- "20260923"
RT_OUTDIR   <- Sys.getenv("RT_OUTDIR",
                 file.path("outputs", "diagnostics", sprintf("%s_%s", RT_TAG, RT_DATE)))

RT_MU_MEAS  <- 0.776     # the MEASURED station-vs-hemisphere offset (MBL zonal)
RT_MU_MASSW <- -0.215    # the MASS-WEIGHTED expectation (diag_rep_dc_mass_weighting.R)
RT_RUNGS    <- c(3.516, RT_MU_MEAS, RT_MU_MASSW)   # canonical, then both candidate targets
RT_CANON    <- 1L

# arm A's sigma: RECALLED for cross-checking only; the value USED is re-measured.
RT_SIGMA_RECALLED <- 1.05
RT_SIGMA_TOL      <- 0.35   # ppm; disagreement beyond this stops the run
RT_OVERLAP_WIN    <- c(1962, 1996)   # the ice-vs-flask overlap the 08-23 note used

# the streams each release arm drops. ⚠ A CHOICE, AND A FLAGGED ONE: arm C drops
# the two ATMOSPHERIC bomb rows that T-(u) named as payers, and NOT
# `excess_c14_ocean` or the three `d14c_profile_*` rows, which constrain the
# ocean's bomb INVENTORY rather than the atmospheric decay. Dropping those too
# is a different question (the ocean's uptake rate, not the ventilation the
# atmosphere sees) and would need its own arm.
RT_DROP <- list(shipped      = character(0),
                ice_sigma    = character(0),       # arm A re-weights, drops nothing
                ice_dropped  = "co2_icecore",
                bomb_dropped = c("d14c_NH", "d14c_SH"))
RT_ARMS <- names(RT_DROP)

RT_N_REP      <- 1        # one perturbed replicate per arm, at the canonical rung
RT_REP_FRAC   <- 0.25
RT_SEED       <- 20260923
RT_NM_MAXIT   <- as.integer(Sys.getenv("RT_NM_MAXIT", "6000"))
RT_BFGS_MAXIT <- as.integer(Sys.getenv("RT_BFGS_MAXIT", "100"))
RT_GATE_TOL   <- 1e-3
# GATE DROP's probe: how hard to push the observation the dropped block reads,
# and the two thresholds that make it a POWER test rather than a null.
RT_ICE_PROBE_PPM <- 10      # ppm added to every ice sample
RT_D14C_PROBE    <- 20      # permil added to both atmospheric d14C records
RT_PROBE_MIN     <- 1.0     # the SHIPPED objective must move at least this much
RT_PROBE_BLIND   <- 1e-9    # the ARM must move less than this

# ---------------------------------------------------------------------
# ARM A's SIGMA, MEASURED HERE. The ice record and the flask record overlap;
# the scatter of (ice - flask) in that window is what an ice sample's error
# actually looks like when both instruments see the same air.
# ---------------------------------------------------------------------
rt_measure_ice_scatter <- function(obs, win = RT_OVERLAP_WIN) {
  ice <- obs$ice
  k   <- ice$year >= win[1] & ice$year <= win[2]
  if (sum(k) < 5) stop("arm A: fewer than 5 ice samples in the overlap ", win[1], "-", win[2])
  # the flask comparator is SPO -- the ice term is scored against co2_SH, so SPO
  # is the station on the same side of the model's own hemispheric split.
  fl <- obs$co2_ann$SPO
  m  <- stats::approx(fl$year, fl$level, xout = ice$year[k], rule = 1)$y
  d  <- ice$CO2ppm[k] - m
  ok <- is.finite(d)
  list(n = sum(ok), win = win, bias = mean(d[ok]), scatter = stats::sd(d[ok]),
       stated_median = stats::median(ice$sd), stated_range = range(ice$sd))
}

md      <- readRDS(ccx_mode_file(CCX_MODE_CANONICAL))
pins    <- ccx_mode_pins(md)
rmp     <- ccx_apply_pins(pins); on.exit(ccx_unpin_params(rmp), add = TRUE)
bp      <- ccx_mode_base(md); bp$pump_mode <- md$pump_mode
for (n in names(pins)) bp[[n]] <- pins[[n]]
st      <- ccx_mode_start(md, RT_TAG)
spin_fn <- ccx_spinup_from_label(ccx_mode_spinup(md))
obs     <- ccx_prepare_obs()
u0      <- st$u
IDX_REP  <- match("rep_dC", names(u0))
IDX_FREE <- setdiff(seq_along(u0), IDX_REP)

ICE <- rt_measure_ice_scatter(obs)

#' The objective for one arm. Arm A rebuilds the objective on a MODIFIED obs;
#' the drop arms subtract the dropped streams from the shipped total, which is
#' exact and needs no second implementation of the likelihood.
rt_logpost_for <- function(arm) {
  if (arm == "ice_sigma") {
    o2 <- obs; o2$ice$sd <- rep(ICE$scatter, length(o2$ice$sd))
    lp2 <- ccx_make_logpost(base_params = bp, by_stream = TRUE,
                            spinup_fn = spin_fn, obs = o2)
    return(function(u) lp2(u))
  }
  lp1 <- ccx_make_logpost(base_params = bp, by_stream = TRUE, spinup_fn = spin_fn)
  drop <- RT_DROP[[arm]]
  if (!length(drop)) return(function(u) lp1(u))
  function(u) {
    v <- lp1(u); s <- attr(v, "streams")
    miss <- setdiff(drop, names(s))
    if (length(miss)) stop("arm ", arm, ": stream(s) absent: ", paste(miss, collapse = ", "))
    out <- as.numeric(v) - sum(unlist(s[drop]))
    attributes(out) <- attributes(v)[c("streams", "loglik", "logprior")]
    out
  }
}

rt_start <- function(k) {
  if (k == 0L) return(u0)
  sdv <- if (!is.null(md$cov) && all(names(u0) %in% rownames(md$cov)))
           sqrt(diag(md$cov))[names(u0)] else rep(RT_REP_FRAC, length(u0))
  set.seed(RT_SEED + 100L + k)     # ⚠ set IMMEDIATELY before the draw that uses it
  z <- stats::rnorm(length(u0))
  u <- u0 + RT_REP_FRAC * sdv * z
  u[IDX_REP] <- u0[IDX_REP]
  u
}

rt_optimise <- function(lp_arm, u_start, rung) {
  uu <- u_start; uu[IDX_REP] <- rung
  f <- function(z) { w <- uu; w[IDX_FREE] <- z; val <- -as.numeric(lp_arm(w))
                     if (!is.finite(val)) 1e10 else val }
  o1 <- stats::optim(uu[IDX_FREE], f, method = "Nelder-Mead",
                     control = list(maxit = RT_NM_MAXIT, reltol = 1e-12))
  o2 <- stats::optim(o1$par, f, method = "Nelder-Mead",
                     control = list(maxit = RT_NM_MAXIT, reltol = 1e-12))
  o3 <- stats::optim(o2$par, f, method = "BFGS",
                     control = list(maxit = RT_BFGS_MAXIT, reltol = 1e-12))
  best <- list(o1, o2, o3)[[which.min(c(o1$value, o2$value, o3$value))]]
  uu[IDX_FREE] <- best$par
  list(u = uu, value = -best$value, conv = best$convergence)
}

RT_JOBS <- function() {
  j <- NULL; id <- 0L
  for (a in RT_ARMS) {
    for (i in seq_along(RT_RUNGS)) {
      id <- id + 1L
      j <- rbind(j, data.frame(id = id, arm = a, rung = RT_RUNGS[i], rep = 0L,
                               label = sprintf("%s_rung_%.3f", a, RT_RUNGS[i]),
                               stringsAsFactors = FALSE))
    }
    for (k in seq_len(RT_N_REP)) {
      id <- id + 1L
      j <- rbind(j, data.frame(id = id, arm = a, rung = RT_RUNGS[RT_CANON], rep = k,
                               label = sprintf("%s_replicate%d", a, k),
                               stringsAsFactors = FALSE))
    }
  }
  j
}

rt_gates <- function() {
  lp1 <- ccx_make_logpost(base_params = bp, by_stream = TRUE, spinup_fn = spin_fn)
  got <- as.numeric(lp1(u0)) - st$logpost_shift
  pass <- abs(got - md$logpost) < RT_GATE_TOL
  cat(sprintf("=== GATE HARNESS === rebuilt %.4f vs stored %.4f -> %s\n",
              got, md$logpost, if (pass) "PASS" else "*** FAIL ***"))
  if (!pass) stop("harness does not reproduce the stored logpost")

  cat(sprintf("\n=== ARM A's SIGMA, RE-MEASURED (not quoted) ===\n"))
  cat(sprintf("  ice vs SPO flask, %d-%d: n = %d, bias %+.3f ppm, SCATTER %.3f ppm\n",
              ICE$win[1], ICE$win[2], ICE$n, ICE$bias, ICE$scatter))
  cat(sprintf("  the objective's STATED ice sigma: median %.3f ppm, range %.3f-%.3f\n",
              ICE$stated_median, ICE$stated_range[1], ICE$stated_range[2]))
  cat(sprintf("  recalled (handoff 08-23) %.3f vs re-measured %.3f -> %s\n",
              RT_SIGMA_RECALLED, ICE$scatter,
              if (abs(ICE$scatter - RT_SIGMA_RECALLED) <= RT_SIGMA_TOL) "AGREE"
              else "*** DISAGREE ***"))
  if (abs(ICE$scatter - RT_SIGMA_RECALLED) > RT_SIGMA_TOL)
    stop("the re-measured ice scatter disagrees with the recalled 1.05 ppm by more than ",
         RT_SIGMA_TOL, " ppm; arm A's sigma is not what the note says it is -- ",
         "settle the measurement before running the arm")
  cat(sprintf("  => arm A scores the ice block at a FLAT %.3f ppm (all %d samples)\n",
              ICE$scatter, length(obs$ice$sd)))

  # ---- GATE DROP: a POWER test, not an identity ----------------------
  # ⛔ THE OBVIOUS GATE HERE IS CIRCULAR AND WAS WRITTEN AND THROWN AWAY
  # (2026-09-23). Checking that the arm equals "the shipped total minus the
  # dropped streams" compares the arm against the very arithmetic that BUILT
  # it -- it passes at 0.000e+00 and can never fail. [[gate_reads_its_own_output]].
  #
  # What actually has to hold is that the dropped block no longer INFLUENCES the
  # arm. So: perturb the OBSERVATION that only that block reads, rebuild the
  # objective on the perturbed observation, and require BOTH halves --
  #   the SHIPPED objective MOVES  (otherwise the probe is too small to test
  #                                 anything and a null would be meaningless),
  #   the ARM does NOT move        (which is the property being claimed).
  # A gate that only checked the second half would pass on a probe with no
  # power at all. [[no_power_null]].
  cat("\n=== GATE DROP (a power test: the dropped block no longer influences the arm) ===\n")
  base <- lp1(u0); s0 <- attr(base, "streams")
  rt_probe <- function(mutate, stream) {
    o2  <- mutate(obs)
    lpm <- ccx_make_logpost(base_params = bp, by_stream = TRUE, spinup_fn = spin_fn, obs = o2)
    vm  <- lpm(u0); sm <- attr(vm, "streams")
    c(shipped = abs(as.numeric(vm) - as.numeric(base)),
      arm     = abs((as.numeric(vm) - sum(unlist(sm[stream]))) -
                    (as.numeric(base) - sum(unlist(s0[stream])))))
  }
  probes <- list(
    ice_dropped = list(stream = RT_DROP$ice_dropped,
                       what = sprintf("ice CO2 +%.0f ppm", RT_ICE_PROBE_PPM),
                       mut = function(o) { o$ice$CO2ppm <- o$ice$CO2ppm + RT_ICE_PROBE_PPM; o }),
    bomb_dropped = list(stream = RT_DROP$bomb_dropped,
                        what = sprintf("d14C NH+SH %+.0f permil", RT_D14C_PROBE),
                        mut = function(o) {
                          for (nm in c("d14_nh", "d14_sh")) o[[nm]]$d14c <- o[[nm]]$d14c + RT_D14C_PROBE
                          for (nm in c("d14_nh_ann", "d14_sh_ann")) o[[nm]]$value <- o[[nm]]$value + RT_D14C_PROBE
                          o }))
  for (a in names(probes)) {
    p <- probes[[a]]; r <- rt_probe(p$mut, p$stream)
    ok_power <- r[["shipped"]] > RT_PROBE_MIN
    ok_blind <- r[["arm"]] < RT_PROBE_BLIND
    cat(sprintf("  %-14s probe %-26s shipped moves %10.3f (>%.1f? %s) | arm moves %.3e (<%.0e? %s)\n",
                a, p$what, r[["shipped"]], RT_PROBE_MIN, if (ok_power) "yes" else "NO",
                r[["arm"]], RT_PROBE_BLIND, if (ok_blind) "yes" else "NO"))
    if (!ok_power) stop("GATE DROP: the ", a, " probe does not move the SHIPPED objective, ",
                        "so it has no power to show the arm is blind to it")
    if (!ok_blind) stop("GATE DROP: arm ", a, " still responds to the block it claims to drop")
  }
  # and the no-drop arm must be bit-identical to the shipped objective
  d_sh <- abs(as.numeric(rt_logpost_for("shipped")(u0)) - as.numeric(base))
  cat(sprintf("  %-14s %-32s |delta| %.3e -> %s\n", "shipped", "(must be the shipped objective)",
              d_sh, if (d_sh == 0) "PASS" else "*** FAIL ***"))
  if (d_sh != 0) stop("the 'shipped' arm is not the shipped objective")
  invisible(TRUE)
}

rt_run_job <- function(k) {
  J <- RT_JOBS(); j <- J[J$id == k, ]; stopifnot(nrow(j) == 1)
  cat(sprintf("\n=== JOB %d: %s (arm %s, rep_dC %.3f, start %s) ===\n",
              j$id, j$label, j$arm, j$rung,
              if (j$rep == 0) "canonical" else sprintf("perturbed %d", j$rep)))
  lp_arm <- rt_logpost_for(j$arm)
  t0 <- Sys.time()
  o  <- rt_optimise(lp_arm, rt_start(j$rep), j$rung)
  va <- lp_arm(o$u)
  el <- as.numeric(difftime(Sys.time(), t0, units = "mins"))
  out <- list(job = j, u = o$u, arm_logpost = o$value,
              arm_loglik = as.numeric(attr(va, "loglik")),
              streams = unlist(attr(va, "streams")), conv = o$conv, minutes = el,
              provenance = list(
                driver = "calibration/diag_rep_dc_release_test.R",
                mode = CCX_MODE_CANONICAL, objective = "#13 MODIFIED, diagnostic only",
                arm = j$arm, dropped = RT_DROP[[j$arm]],
                ice_sigma_used = if (j$arm == "ice_sigma") ICE$scatter else NA_real_,
                ice_scatter_measured = ICE$scatter, ice_overlap = ICE$win, ice_n = ICE$n,
                ice_sigma_source = "re-measured here; cross-checked against handoff 2026-08-23 (1.05 ppm)",
                spinup = ccx_mode_spinup(md), seed = RT_SEED,
                seed_applied = "rt_start(), immediately before rnorm()",
                nm_maxit = RT_NM_MAXIT, rungs = RT_RUNGS,
                units = "rep_dC ppm; logpost/loglik log-units",
                comparability = "logpost is comparable WITHIN an arm only; arms score different row sets",
                commit = tryCatch(system("git rev-parse --short HEAD", intern = TRUE),
                                  error = function(e) NA_character_),
                built = as.character(Sys.time())))
  dir.create(RT_OUTDIR, showWarnings = FALSE, recursive = TRUE)
  saveRDS(out, file.path(RT_OUTDIR, sprintf("job%02d_%s.rds", j$id, j$label)))
  cat(sprintf("  arm logpost %.4f  loglik %.4f  conv %d  %.1f min\n",
              o$value, out$arm_loglik, o$conv, el))
  invisible(out)
}

args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0 || args[1] == "help") {
  cat("usage: Rscript calibration/diag_rep_dc_release_test.R <job-id|all|collect|scout>\n")
  print(RT_JOBS())
} else if (args[1] == "scout") {
  rt_gates(); print(RT_JOBS())
} else if (args[1] == "collect") {
  source("calibration/lib_rep_dc_release_report.R")
  rt_report(RT_OUTDIR, RT_JOBS(), RT_RUNGS, RT_CANON, RT_DROP)
} else if (args[1] == "all") {
  rt_gates(); for (k in RT_JOBS()$id) rt_run_job(k)
} else {
  rt_gates(); rt_run_job(as.integer(args[1]))
}
