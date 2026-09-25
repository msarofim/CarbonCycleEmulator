# =====================================================================
# diag_rep_dc_product_ladder.R -- T1 (the R2 test menu, 2026-09-22):
# "what would the PRODUCTS look like if `rep_dC` were forced down?"
#
# ⛔⛔ THIS IS A PROBE AND IT CHANGES NOTHING. No objective change, no mode
# file written, no prior altered. `rep_dC` is PINNED at each rung and the other
# 28 fitted names are FULLY re-optimised; the shipped N(0, LIK_CO2_REP_ERR)
# prior term is left exactly as it is, because the question here is not "what
# prior would move the fit" (that was T-(u), the centre/width side test) but
# "does anything a reader would CARE about move when the offset moves".
#
# WHY THIS IS THE DECISION-RELEVANT TEST. `rep_dC` is one of the five named
# shims (whole-model review 09-16 d; freeze record §4.2). Its z is +3.5 and the
# 09-22 (aa) mass-weighting term makes the residue it stands for LARGER, not
# smaller (+2.67 -> +3.62 ppm NH). The open ruling R2 is whether to re-centre
# and/or tighten its prior. That ruling is a LABELLING decision if the model's
# products are flat along the ladder, and a PHYSICS decision if they are not.
# Nothing else in the menu answers that; the loglik total does not, because a
# shim is exactly the thing that buys loglik without moving a product.
#
# THE LADDER SPANS BOTH CANDIDATE TARGETS, DELIBERATELY. The menu was written
# before T3 and said "3.52 -> 0.78". T3 then moved the target: the measured
# station-vs-hemisphere offset is +0.776 ppm (RPL_MU_MEAS, MBL zonal), but the
# MASS-WEIGHTED expectation for a whole-atmosphere box is -0.215 ppm
# (RPL_MU_MASSW, diag_rep_dc_mass_weighting.R). Which of those is the right
# target IS the ruling, so the ladder covers both rather than pre-empting it.
#
# ⚠ TWO GATES BEFORE ANY NUMBER IS READ, and the second is the one that matters:
#   HARNESS  -- the rebuilt objective reproduces the stored logpost.
#   VECTOR   -- the reconstructed gate vector `v` at the canonical `u` matches
#               dg_vector(CCX_MODE_CANONICAL) parameter for parameter. Every
#               product below is computed through the shipped gate path
#               (dg_run / dg_gate*), so if this reconstruction drifts, every
#               product moves for a reason that has nothing to do with rep_dC.
#               ⭐ MUTATION-TESTED 2026-09-23, because a gate that passes is not
#               a gate that works. HARNESS fails on a +0.5 offset to the rebuilt
#               logpost. VECTOR fails on a 1-part-per-million nudge to a MODEL
#               name (`k_w`, worst delta 1.9e-3) and to a NUISANCE (`bomb_total`,
#               1.2e-4), and names the offender first in both cases.
#               ⚠ ITS ONE MEASURED BLIND SPOT: the ENSO half of the overlay is
#               INVISIBLE to it -- at the canonical, `ccx_set_enso()` is a genuine
#               no-op, because the copy that precedes it already writes the two
#               fitted land gammas and the two ocean gammas are PINNED at 0 in
#               `bp`. Measured 2026-09-23 by deleting the call, which the gate did
#               NOT catch. It stops being a no-op the moment a rung moves them,
#               and the gate still cannot see that at u0. Since 2026-09-25 the
#               call is reached through `ccx_overlay_par()`, whose own
#               deleted-nothing assertion fires at EVERY rung -- which is the
#               half a gate evaluated only at u0 can never cover.
#   NOISE    -- and then the canonical rung is re-run from RPL_N_REP PERTURBED
#               starts. The spread of each product across those replicates is
#               the OPTIMISER-NOISE FLOOR. A product that moves less than its
#               own floor has not moved. Without this the ladder cannot tell
#               physics from Nelder-Mead.
#
# Usage:
#   Rscript calibration/diag_rep_dc_product_ladder.R <job>    # one job, saves RDS
#   Rscript calibration/diag_rep_dc_product_ladder.R collect  # the report
# `job` is an integer index into RPL_JOBS() or the string "all" (serial).
# =====================================================================
.root <- local({
  d <- normalizePath(getwd(), mustWork = FALSE)
  for (i in 1:8) { if (file.exists(file.path(d, "DESIGN.md"))) break; d <- dirname(d) }
  d
})
setwd(.root)
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
source("calibration/lib_design_gates.R")
ccx_load_cpp()

# ---- NAMED CONSTANTS: every label, filename and column below derives from ----
RPL_TAG        <- "rep_dc_product_ladder"
RPL_DATE       <- "20260923"
# ⚠ RPL_OUTDIR is overridable ONLY so a reduced-budget SMOKE run cannot write
# into the real run's directory and be collected as if it were one of its rungs.
# A smoke job's artifact still stamps its own (smaller) budget, so the two could
# be told apart after the fact -- but not before someone read the table.
RPL_OUTDIR     <- Sys.getenv("RPL_OUTDIR",
                    file.path("outputs", "diagnostics", sprintf("%s_%s", RPL_TAG, RPL_DATE)))
RPL_LOG        <- file.path("outputs", "diagnostics", sprintf("%s_%s.log", RPL_TAG, RPL_DATE))

RPL_MU_MEAS    <- 0.776    # MEASURED station-vs-hemisphere offset, MBL zonal (diag_rep_dc_mbl_zonal.R)
RPL_MU_MASSW   <- -0.215   # MASS-WEIGHTED expectation for a whole-atmosphere box (diag_rep_dc_mass_weighting.R)
# The rungs. The top is the canonical's own fitted value; the two named targets
# are rungs, not endpoints; 0.0 is the shipped prior's centre.
RPL_RUNGS      <- c(3.516, 3.000, 2.500, 2.000, 1.500, 1.000, RPL_MU_MEAS, 0.000, RPL_MU_MASSW)
RPL_CANON_RUNG <- 1L       # index into RPL_RUNGS of the canonical rung (the replicate anchor)

RPL_N_REP      <- 3        # perturbed replicates AT the canonical rung -> the noise floor
RPL_REP_FRAC   <- 0.25     # perturbation size, in units of each name's posterior sd
RPL_SEED       <- 20260923 # ⚠ STAMPED INTO EVERY ARTIFACT, not just set here

# SIZED BY THE 09-23 RECOVERY PROBE: 2000 NM iterations on the 28 free names
# cost 364 s, and NM started AT the canonical found nothing better (+0.0000),
# which is the right answer and also an UNINFORMATIVE one -- a start already at
# the optimum cannot measure recovery. That is what the PERTURBED replicates are
# for, and why the budget is set from cost rather than from that probe's verdict.
# The budget is the thing the noise floor is most sensitive to: too small and
# every product "moves". ⚠ BFGS here is numeric-gradient on 28 names, so one
# iteration costs 29 evaluations -- its budget is small for that reason, not
# because the polish is unimportant.
RPL_NM_MAXIT   <- as.integer(Sys.getenv("RPL_NM_MAXIT", "6000"))
RPL_BFGS_MAXIT <- as.integer(Sys.getenv("RPL_BFGS_MAXIT", "100"))
RPL_GATE_TOL   <- 1e-3     # harness must reproduce the stored logpost
RPL_VEC_TOL    <- 1e-10    # the reconstructed gate vector must match dg_vector()

md    <- readRDS(ccx_mode_file(CCX_MODE_CANONICAL))
pins  <- ccx_mode_pins(md)
rmp   <- ccx_apply_pins(pins); on.exit(ccx_unpin_params(rmp), add = TRUE)
bp    <- ccx_mode_base(md); bp$pump_mode <- md$pump_mode
for (n in names(pins)) bp[[n]] <- pins[[n]]
st    <- ccx_mode_start(md, RPL_TAG)
spin_fn <- ccx_spinup_from_label(ccx_mode_spinup(md))
lp    <- ccx_make_logpost(base_params = bp, by_stream = TRUE, spinup_fn = spin_fn)
obs   <- ccx_prepare_obs()
u0    <- st$u
stopifnot(identical(CCX_PARAM_TABLE$rep_dC$tr, "id"))   # u IS ppm for this name
IDX_REP <- match("rep_dC", names(u0))
IDX_FREE <- setdiff(seq_along(u0), IDX_REP)

# ---------------------------------------------------------------------
# The reconstruction: u -> the gate vector `v` that dg_run()/dg_gate*() want.
# This mirrors ccx_make_logpost()'s own body (R/calibrate.R:2385) rather than
# re-deriving it, and gate VECTOR below proves the mirror closes.
# ⚠ THE MIRROR IS THROUGH `ccx_overlay_par()`, NOT THE OBJECTIVE'S LITERAL LOOP
# (converted 2026-09-25, RULING B's convert-on-touch). The helper is that loop
# plus `ccx_set_enso()` plus an assertion that the overlay DELETED NOTHING, so
# the two coincide exactly whenever the fitted set carries every name -- which
# `ccx_unc_to_par()` guarantees by construction, since it builds one value per
# CCX_PARAM_NAMES. Gate VECTOR measures that coincidence at u0 (0.000e+00 over
# 106 names) rather than leaving it argued.
# ⚠ TWO PARAMETER LISTS ([[ccx_two_param_lists]]): `p` is the MODEL list and
# carries none of the six nuisances; `pv` is the FITTED list and carries them.
# ---------------------------------------------------------------------
.v_template <- dg_vector(CCX_MODE_CANONICAL)
rpl_vector_at <- function(u) {
  pv <- ccx_unc_to_par(u)
  p  <- bp
  p  <- ccx_overlay_par(p, pv)
  v  <- .v_template
  v$p            <- p
  v$bomb_total   <- pv$bomb_total
  v$luc_scale    <- pv$luc_scale
  v$sigma_d14c   <- pv$sigma_d14c
  v$rep_dC       <- pv$rep_dC
  v$grad_off_co2 <- pv$grad_off_co2
  v$grad_off_d13c<- pv$grad_off_d13c
  v$spinup       <- spin_fn
  v
}

# ---------------------------------------------------------------------
# THE PRODUCTS. Every one is read through the SHIPPED path -- dg_run(),
# dg_gate*(), dg_gateL_partition(), the scorecard's own irf_of block -- so a
# number here is the number the model reports, not a re-implementation of it.
# Each carries the yardstick it should be judged against: its OWN observational
# sigma where one exists, and the replicate noise floor always.
# ---------------------------------------------------------------------
RPL_D_OBS  <- dg_gateD_obs()
RPL_H_OBS  <- dg_gateH_obs(obs)
RPL_G7_TGT <- dg_gcb_target(DG_SINK_WIN)

rpl_irf <- function(v) {
  spin   <- dg_spinup(v)
  F_hist <- ccx_build_forcing("historical", c(1750, JOOS_REF_YEAR), prod_c14 = spin$prod_c14,
                              bomb_total_kmol = v$bomb_total, luc_scale = v$luc_scale)
  sp_ref <- spin; sp_ref$y <- ccx_run_fast(spin, F_hist)$state
  F_fwd  <- suppressWarnings(ccx_build_forcing(
              "historical", c(JOOS_REF_YEAR, JOOS_REF_YEAR + 300 + DG_L_EXTRA_YR),
              prod_c14 = spin$prod_c14, bomb_total_kmol = 0, luc_scale = v$luc_scale))
  for (cc in c("e_foss_NH", "e_foss_SH", "e_luc_NH", "e_luc_SH",
               "enso", "c14_bomb", "c14_nuclear")) F_fwd[[cc]] <- 0
  F_fwd$gmst <- F_fwd$gmst[1]
  F_hold <- ccx_hold_forcing(sp_ref, F_fwd, verbose = FALSE)
  o  <- ccx_irf(sp_ref, F_hold); o$t <- o$t - (JOOS_PULSE_YR - JOOS_REF_YEAR)
  k  <- o$t >= 0; at <- function(y) o$irf[k][which.min(abs(o$t[k] - y))]
  c(irf20 = at(20), irf100 = at(100), irf300 = at(300))
}

rpl_products <- function(u) {
  v  <- rpl_vector_at(u)
  r  <- dg_run(v)
  lv <- lp(u)
  gd <- dg_gateD_verdict(dg_gateD(r, v, RPL_D_OBS), RPL_D_OBS)
  gh <- dg_gateH(v, obs, RPL_H_OBS, r = r)
  gl <- dg_gateGL_verdict(gh, RPL_H_OBS)
  g7 <- dg_gate7(r); g7v <- dg_gate7_verdict(g7, RPL_G7_TGT)
  g4 <- dg_gate4(r, v)
  pt <- dg_gateL_partition(v)
  ir <- rpl_irf(v)
  list(
    scalar = c(
      logpost        = as.numeric(lv) - st$logpost_shift,
      loglik         = as.numeric(attr(lv, "loglik")),
      rep_dC         = unname(ccx_unc_to_par(u)$rep_dC),
      # --- the products the ruling is about ---
      irf20          = unname(ir[["irf20"]]),
      irf100         = unname(ir[["irf100"]]),
      irf300         = unname(ir[["irf300"]]),
      part1000_land  = unname(pt$share[["land"]]),
      part1000_ocean = unname(pt$share[["ocean"]]),
      part1000_air   = unname(pt$share[["air"]]),
      part1000_close = pt$closure,
      af_all         = g4$all,
      gateD_asym     = gd$asym,
      gateD_z        = gd$z,
      grad_d13c      = gh$d13c,
      grad_co2       = gh$co2,
      gateGL_z       = gl$z,
      co2_pi         = r$sp$diagnostics$co2_ppm,
      sink_land      = g7$land,
      sink_ocean     = g7$ocean,
      sink_land_z    = g7v$z_land,
      sink_ocean_z   = g7v$z_ocean
    ),
    streams = unlist(attr(lv, "streams")),
    af_dec  = g4$dec,
    u       = u
  )
}

# ---- the yardsticks: each product's OWN observational sigma, where one exists
# ⚠ Where a product has NO observational sigma the entry is NA and the report
# falls back to the replicate noise floor alone. [[tolerance_scaled_to_spread]]
RPL_OBS_SD <- c(
  part1000_land  = DG_L_JOOS$land[["sd"]],
  part1000_ocean = DG_L_JOOS$ocean[["sd"]],
  part1000_air   = DG_L_JOOS$air[["sd"]],
  gateD_asym     = RPL_D_OBS$asym_se,
  grad_d13c      = RPL_H_OBS$d13c$se,
  grad_co2       = RPL_H_OBS$co2$se
)

# ---------------------------------------------------------------------
# THE JOB LIST. Job 1 is the canonical rung from the canonical start; jobs
# 2..(1+RPL_N_REP) are the canonical rung from PERTURBED starts (the noise
# floor); the rest are the ladder.
# ---------------------------------------------------------------------
RPL_JOBS <- function() {
  j <- data.frame(id = 1L, label = "canonical", rung = RPL_RUNGS[RPL_CANON_RUNG],
                  rep = 0L, stringsAsFactors = FALSE)
  for (i in seq_len(RPL_N_REP))
    j <- rbind(j, data.frame(id = 1L + i, label = sprintf("replicate%d", i),
                             rung = RPL_RUNGS[RPL_CANON_RUNG], rep = i))
  for (i in setdiff(seq_along(RPL_RUNGS), RPL_CANON_RUNG))
    j <- rbind(j, data.frame(id = nrow(j) + 1L, label = sprintf("rung_%.3f", RPL_RUNGS[i]),
                             rung = RPL_RUNGS[i], rep = 0L))
  j
}

#' The perturbed start for replicate `k`. ⚠ THE SEED IS SET IMMEDIATELY BEFORE
#' THE DRAW that consumes the RNG stream, and the value travels in the artifact.
rpl_start <- function(k) {
  if (k == 0L) return(u0)
  sdv <- if (!is.null(md$cov) && all(names(u0) %in% rownames(md$cov)))
           sqrt(diag(md$cov))[names(u0)] else rep(RPL_REP_FRAC, length(u0))
  set.seed(RPL_SEED + k)
  z <- stats::rnorm(length(u0))
  u <- u0 + RPL_REP_FRAC * sdv * z
  u[IDX_REP] <- u0[IDX_REP]          # the rung is PINNED; never perturbed
  u
}

rpl_optimise <- function(u_start, rung) {
  uu <- u_start; uu[IDX_REP] <- rung
  f <- function(z) { w <- uu; w[IDX_FREE] <- z; val <- -as.numeric(lp(w))
                     if (!is.finite(val)) 1e10 else val }
  o1 <- stats::optim(uu[IDX_FREE], f, method = "Nelder-Mead",
                     control = list(maxit = RPL_NM_MAXIT, reltol = 1e-12))
  o2 <- stats::optim(o1$par, f, method = "Nelder-Mead",
                     control = list(maxit = RPL_NM_MAXIT, reltol = 1e-12))
  o3 <- stats::optim(o2$par, f, method = "BFGS",
                     control = list(maxit = RPL_BFGS_MAXIT, reltol = 1e-12))
  best <- list(o1, o2, o3)[[which.min(c(o1$value, o2$value, o3$value))]]
  uu[IDX_FREE] <- best$par
  list(u = uu, value = -best$value, conv = best$convergence)
}

# ---------------------------------------------------------------------
args <- commandArgs(trailingOnly = TRUE)
dir.create(RPL_OUTDIR, showWarnings = FALSE, recursive = TRUE)

rpl_gates <- function() {
  vg <- lp(u0)
  got <- as.numeric(vg) - st$logpost_shift
  pass_h <- abs(got - md$logpost) < RPL_GATE_TOL
  cat(sprintf("=== GATE HARNESS === rebuilt %.4f (shift %+.4f) vs stored %.4f -> %s\n",
              got, st$logpost_shift, md$logpost, if (pass_h) "PASS" else "*** FAIL ***"))
  if (!pass_h) stop("harness does not reproduce the stored logpost")

  # GATE VECTOR: the reconstruction must match the shipped dg_vector(), name by
  # name, or every product below moves for a reason unrelated to rep_dC.
  vr <- rpl_vector_at(u0); vt <- .v_template
  nm <- intersect(names(vt$p), names(vr$p))
  nm <- nm[vapply(nm, function(n) is.numeric(vt$p[[n]]) && length(vt$p[[n]]) == length(vr$p[[n]]),
                  logical(1))]
  d  <- vapply(nm, function(n) max(abs(vr$p[[n]] - vt$p[[n]])), numeric(1))
  for (n in c("bomb_total", "luc_scale", "sigma_d14c", "rep_dC", "grad_off_co2", "grad_off_d13c"))
    d[[n]] <- abs(vr[[n]] - vt[[n]])
  worst <- max(d, na.rm = TRUE)
  pass_v <- worst < RPL_VEC_TOL
  cat(sprintf("=== GATE VECTOR === worst |delta| over %d names: %.3e (tol %.1e) -> %s\n",
              length(d), worst, RPL_VEC_TOL, if (pass_v) "PASS" else "*** FAIL ***"))
  if (!pass_v) {
    print(utils::head(sort(d, decreasing = TRUE), 8))
    stop("the reconstructed gate vector does not match dg_vector(); products would be uninterpretable")
  }
  invisible(TRUE)
}

rpl_run_job <- function(k) {
  J <- RPL_JOBS(); j <- J[J$id == k, ]
  stopifnot(nrow(j) == 1)
  cat(sprintf("\n=== JOB %d: %s (rep_dC pinned at %.3f, start = %s) ===\n",
              j$id, j$label, j$rung, if (j$rep == 0) "canonical" else sprintf("perturbed %d", j$rep)))
  t0 <- Sys.time()
  o  <- rpl_optimise(rpl_start(j$rep), j$rung)
  pr <- rpl_products(o$u)
  el <- as.numeric(difftime(Sys.time(), t0, units = "mins"))
  out <- list(job = j, u = o$u, opt_logpost = o$value, conv = o$conv,
              products = pr, minutes = el,
              provenance = list(
                driver = "calibration/diag_rep_dc_product_ladder.R",
                mode = CCX_MODE_CANONICAL, mode_file = ccx_mode_file(CCX_MODE_CANONICAL),
                spinup = ccx_mode_spinup(md), objective = "#13",
                seed = RPL_SEED, seed_applied = "rpl_start(), immediately before rnorm()",
                rep_frac = RPL_REP_FRAC, nm_maxit = RPL_NM_MAXIT,
                rungs = RPL_RUNGS, mu_meas = RPL_MU_MEAS, mu_massw = RPL_MU_MASSW,
                units = "rep_dC ppm; partition %; sinks GtC/yr; gradients ppm and permil",
                commit = tryCatch(system("git rev-parse --short HEAD", intern = TRUE),
                                  error = function(e) NA_character_),
                # ⚠ A COMMIT ALONE IS NOT PROVENANCE IF THE TREE WAS DIRTY, and
                # on the 09-23 run it WAS: the driver carried uncommitted edits
                # (the RPL_OUTDIR override and the budget constant) through the
                # whole wave, so its artifacts name a commit that does not fully
                # describe the code that produced them. Recorded from here on.
                tree_dirty = tryCatch(length(system("git status --porcelain -- calibration R",
                                                    intern = TRUE)) > 0,
                                      error = function(e) NA),
                built = as.character(Sys.time())))
  saveRDS(out, file.path(RPL_OUTDIR, sprintf("job%02d_%s.rds", j$id, j$label)))
  cat(sprintf("  logpost %.4f  conv %d  %.1f min -> %s\n", o$value, o$conv, el,
              file.path(RPL_OUTDIR, sprintf("job%02d_%s.rds", j$id, j$label))))
  invisible(out)
}

if (length(args) == 0 || args[1] == "help") {
  cat("usage: Rscript calibration/diag_rep_dc_product_ladder.R <job-id|all|collect>\n")
  print(RPL_JOBS())
} else if (args[1] == "gates") {
  rpl_gates()
  cat("\n=== PRODUCTS AT THE CANONICAL u (no re-optimisation) ===\n")
  pr <- rpl_products(u0)
  for (n in names(pr$scalar)) cat(sprintf("  %-16s %14.4f\n", n, pr$scalar[[n]]))
} else if (args[1] == "collect") {
  source("calibration/lib_rep_dc_ladder_report.R")
  rpl_report(RPL_OUTDIR, RPL_JOBS(), RPL_OBS_SD, RPL_N_REP, RPL_RUNGS, RPL_CANON_RUNG)
} else if (args[1] == "all") {
  rpl_gates(); for (k in RPL_JOBS()$id) rpl_run_job(k)
} else {
  rpl_gates(); rpl_run_job(as.integer(args[1]))
}
