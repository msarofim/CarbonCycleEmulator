# =====================================================================
# recompute_hessian.R -- redo the Hessian at an already-located mode with a
#                        VALIDATED, PER-PARAMETER step size, without repeating
#                        the optimisation.
#
# WHY IT FIRST EXISTED: run_modefind.R used a single MODE_HESS_EPS = 1e-3 on the
# unconstrained scale for all parameters. At the bomb-window mode that is far
# too large: stepping log(kz) by 1e-3 costs 49,000 log-units and by 1e-2 leaves
# the feasible region entirely, so the central difference returned -4.9e10 and
# the Laplace covariance came out non-positive-definite. At 1e-4 the same second
# derivative is -41.3.
#
# WHY IT WAS REWRITTEN (2026-08-21, handoff sec.3). The 21-parameter refit
# reported `curvature step-stability at the mode: UNSTABLE at h_ml`, which makes
# `sd_unc`, `cov`, `logdet_negH` and any Laplace evidence in
# mode_fit_pumpN.rds unusable. Three things had to change before this file could
# answer that:
#
#  1. IT READ `md$u_mode` AND DECODED IT UNDER THE DEFAULT PARAMETER TABLE. The
#     arm refit overrode h_ml's band to [85, 120] IN PROCESS
#     (ccx_hml_band_provenance), so `u_mode` decoded under the default [30, 200]
#     can give an h_ml metres away from the 87.56 the file's own par_mode says,
#     and it would then have computed a perfectly clean Hessian at the WRONG
#     POINT and said nothing. It now re-encodes from `par_mode`, which is
#     band-independent, under the band the file RECORDS in `hml_bound`, and
#     GATE 1 refuses to continue unless the log-posterior reproduces
#     `md$logpost`. (mode_fit_pumpN.rds as it stands DOES round-trip -- GATE 1
#     prints both so the reader can see that rather than assume it either way.
#     The guard is for the next file, not this one.)
#
#  2. IT WROTE ITS RESULT BACK OVER THE MODE FILE. A 15-hour refit's output is
#     not a scratch buffer. Results now go to a SEPARATE file; updating the mode
#     file in place requires --update and still only happens after the gates.
#
#  3. ONE GLOBAL eps CANNOT SERVE BOTH kz AND h_ml, which is the whole problem.
#     `kz` fails when the step is far too LARGE; `h_ml` fails because
#     ARM_HESS_EPS = 3e-4 is far too SMALL. h_ml is logit-transformed on
#     [85, 120] and the mode sits at 7.3 % of that band, so du -> dh_ml is
#     heavily compressed: 3e-4 in u reaches 7.1e-4 METRES. Curvature measured
#     over seven ten-thousandths of a metre is reading the integrator's own
#     noise. The step is now chosen PER PARAMETER, and the chosen vector is
#     written next to the Hessian -- a second-order block that cannot be
#     reproduced without an unrecorded setting is a trap (the same lesson as
#     hml_bound itself).
#
# THE STEP RULE, and WHY IT IS NOT "the largest stable step". The first version
# of this rewrite swept the grid and took the largest step whose curvature
# agreed with both neighbours. That is defensible for the DIAGONAL and it is
# WRONG for the CROSS terms: it chose eps = 1e-1 for nearly everything, which
# for `beta_max` is a move of 313 log-units -- far outside the quadratic region
# -- and the resulting Hessian had a POSITIVE eigenvalue of +86.8 in the
# (beta_max, fert_k) plane. The Michaelis-Menten fertilisation pair is a curved
# valley; a step that large reads its third and fourth derivatives, and a
# diagonal-only stability scan cannot see that happening.
#
# So the step is DERIVED from the curvature instead of picked off a grid:
#
#     eps_k = HESS_EPS_FRAC * sd_k,    sd_k = 1 / sqrt(-d2 logpost / du_k^2)
#
# a fixed fraction of each direction's own posterior width. Then the objective
# moves by HESS_EPS_FRAC^2 / 2 log-units in EVERY direction by construction --
# 0.005 at the shipped 0.1 -- which sits about 5,000x above this integrator's
# noise floor (h_ml's curvature is still noise-dominated at a 6e-7 move and
# clean by 6e-6) and leaves a truncation error of order HESS_EPS_FRAC^2 / 4,
# a quarter of a percent. The grid sweep survives, but only to ESTIMATE sd_k
# and to verify the derived step afterwards at a third and three times its
# value.
#
# WHAT THAT RULE EXPLAINS, which is the actual sec.3 finding. ARM_HESS_EPS =
# 3e-4 is 0.5-1.8x the right step for the seven STIFF directions (beta_max,
# fert_k, q10, k_w, bomb_total, luc_scale, grad_off_d13c) and 0.003-0.06x the
# right step for the soft ones. It was calibrated on the stiff subspace. h_ml
# is simply the SOFTEST direction in the model -- unconstrained sd 0.886 --
# so 3e-4 is 333x too small there and it is the one that got flagged. THE
# LOGIT-COMPRESSION STORY IS TRUE ABOUT REACH AND WRONG ABOUT CAUSE: `kz` was
# under-stepped 181x and `gamma_enso` 66x, neither of them near a bound and
# neither flagged, because their curvature happened to survive the noise at
# 3e-4. The instability report was under-reporting, not over-reporting.
#
# A stability check still runs, and a parameter that fails it is REPORTED AS
# SUCH rather than given the least-bad step.
#
# Usage:  Rscript calibration/recompute_hessian.R [mode_file] [--update]
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

args <- commandArgs(trailingOnly = TRUE)
HESS_UPDATE    <- "--update" %in% args
args           <- setdiff(args, "--update")
HESS_MODE_FILE <- if (length(args)) args[1] else
  ccx_mode_file()
HESS_OUT_FILE  <- sub("\\.rds$", "_hess.rds", HESS_MODE_FILE)
# HALF-DECADE GRID, three and a half decades wide. The old grid stopped at 3e-4,
# which is where h_ml's problem STARTS -- a sweep that cannot reach the answer
# cannot report that it did not find it.
HESS_EPS_GRID  <- c(1e-5, 3e-5, 1e-4, 3e-4, 1e-3, 3e-3, 1e-2, 3e-2, 1e-1, 3e-1)
HESS_STABLE_TOL <- 0.02   # max relative disagreement with EITHER neighbour
HESS_EPS_FRAC   <- 0.10   # step as a fraction of each direction's posterior sd
HESS_FALLBACK   <- 3e-4   # used only for parameters with no stable step, and
                          # flagged loudly when it is

sep <- function(s) cat(sprintf("\n%s\n%s\n", s, strrep("-", nchar(s))))

md <- readRDS(HESS_MODE_FILE)
nm <- md$param_names
stopifnot(identical(nm, CCX_PARAM_NAMES))

# ---- the band the mode was FOUND under, from the file, not assumed -----
if (!is.null(md$hml_bound)) {
  CCX_PARAM_TABLE$h_ml$lo    <- md$hml_bound[1]
  CCX_PARAM_TABLE$h_ml$hi    <- md$hml_bound[2]
  CCX_PARAM_TABLE$h_ml$init  <- mean(md$hml_bound)
  CCX_PARAM_TABLE$h_ml$prior <-
    local({ b <- md$hml_bound; function(x) stats::dunif(x, b[1], b[2], log = TRUE) })
}
bp <- ccx_default_params()
if (!is.null(md$pump_mode)) bp$pump_mode <- md$pump_mode
lp <- ccx_make_logpost(base_params = bp)
u  <- ccx_par_to_unc(md$par_mode)     # NEVER md$u_mode -- see the header
lp0 <- lp(u)

sep("GATE 1: the stored mode reproduces at the point this Hessian is taken")
cat(sprintf("mode file  %s\n", HESS_MODE_FILE))
cat(sprintf("pump_mode  %s\n", if (is.null(md$pump_mode)) "(default)" else md$pump_mode))
cat(sprintf("h_ml band  %s\n", if (is.null(md$hml_bound)) "(table default)"
                               else sprintf("[%g, %g] (from the file)", md$hml_bound[1],
                                            md$hml_bound[2])))
cat(sprintf("log-post   %.6f   file %.6f   diff %.3e\n", lp0, md$logpost, lp0 - md$logpost))
if (!is.null(md$u_mode))
  cat(sprintf("(md$u_mode would have decoded h_ml to %.3f m; par_mode says %.3f m)\n",
              .from_unc(md$u_mode[[match("h_ml", nm)]], CCX_PARAM_TABLE$h_ml),
              md$par_mode$h_ml))
if (abs(lp0 - md$logpost) > 1e-5)
  stop("the mode does not reproduce -- a Hessian here would be at the wrong point")

# ---- how far each unconstrained step reaches in NATURAL units ----------
# This is the diagnostic that made sec.3's hypothesis: the same eps means
# wildly different physical distances across a logit-transformed parameter's
# band, and h_ml's mode sits near the bottom of a narrow one.
reach <- vapply(nm, function(n) {
  s <- CCX_PARAM_TABLE[[n]]; uu <- u[[match(n, nm)]]
  (.from_unc(uu + 1e-6, s) - .from_unc(uu - 1e-6, s)) / 2e-6
}, numeric(1))

# ---- diagonal curvature at each candidate step ------------------------
# THE COMPUTATION NOW LIVES IN R/calibrate.R (promoted 2026-08-23), and this
# script became one of TWO callers rather than the only home of the correct
# version. That is the point: the refit driver used to take a scalar step and
# this script existed to fix its output afterwards, so the right implementation
# was one someone had to remember to run. Both now call the same function; what
# is left here is the REPORTING, which is what this file is actually for.
HD   <- ccx_hessian_per_direction(lp, u, verbose = FALSE)
D    <- HD$curvature_by_step
SDV  <- HD$sd_diag
EPSV <- HD$eps
V    <- HD$verify
unstable <- HD$no_plateau        # no stable plateau; fell back
vspread  <- apply(V, 1, function(r)
  if (anyNA(r) || r[2] == 0) Inf else max(abs(r - r[2])) / abs(r[2]))
failed   <- HD$unstable          # chosen step not verified at eps/3 and 3 eps
cat("NA = the step leaves the feasible region\n")
print(signif(D, 4))

sep("CHOSEN STEP, PER PARAMETER")
cat(sprintf("eps = %.2f x the direction's own posterior sd; verified at eps/3 and 3 eps\n",
            HESS_EPS_FRAC))
cat(sprintf("d(logpost) over the step is %.4f in EVERY direction by construction\n",
            HESS_EPS_FRAC^2 / 2))
cat(sprintf("%-16s %10s %10s %11s %11s %9s %s\n", "parameter", "sd (unc)", "eps (u)",
            "reach (nat)", "curvature", "eps/3-3eps", "vs refit 3e-4"))
for (k in seq_along(nm)) {
  st <- if (nm[k] %in% failed) " *** UNSTABLE" else ""
  cat(sprintf("%-16s %10.5f %10.3e %11.4g %11.5g %8.2f%% %8.3fx%s\n",
              nm[k], SDV[k], EPSV[k], EPSV[k] * reach[k], V[k, "mid"],
              100 * min(vspread[k], 999), md$hess_eps / EPSV[k], st))
}
if (length(failed))
  cat(sprintf("\n*** %d parameter(s) UNSTABLE at the derived step: %s\n",
              length(failed), paste(failed, collapse = ", ")))
if (length(unstable))
  cat(sprintf("*** %d parameter(s) had no plateau at all, using the fallback: %s\n",
              length(unstable), paste(unstable, collapse = ", ")))
cat("\nthe refit's single 3e-4, as a multiple of the right step: soft directions\n")
cat("are UNDER-stepped (ratio << 1), stiff ones are about right (ratio ~ 1)\n")

# h_ml's step must not reach a kink -- the piecewise-C1 direction (ccx_hml_kink)
if ("h_ml" %in% nm && !is.null(md$hml_kinks)) {
  ih <- match("h_ml", nm)
  gap <- min(abs(md$hml_kinks - md$par_mode$h_ml))
  cat(sprintf("\nh_ml: step reaches %.4g m; nearest kink is %.4g m away (%s)\n",
              EPSV[ih] * reach[ih], gap,
              if (EPSV[ih] * reach[ih] < gap) "CLEAR" else "*** THE STEP CROSSES A KINK"))
  cat(sprintf("      the refit's %.0e reached %.4g m -- %.0fx smaller\n",
              md$hess_eps, md$hess_eps * reach[ih], EPSV[ih] / md$hess_eps))
}

# ---- full Hessian with the per-parameter step -------------------------
# Mixed steps are fine in a central cross-difference: the a-direction is
# differenced with eps_a and the b-direction with eps_b, and the denominator
# carries both.
sep("FULL HESSIAN")
# Computed by ccx_hessian_per_direction() above, with MIXED steps: the
# a-direction is differenced with eps_a and the b with eps_b, and the
# denominator carries both.
H <- HD$H
cat(sprintf("21x21 with per-direction steps, eps = %.2f x each posterior sd\n",
            HD$eps_frac))
ev <- eigen(H, symmetric = TRUE)
cat("\neigenvalues (all < 0 at a clean interior maximum):\n")
print(signif(ev$values, 4))

pd <- all(ev$values < 0)
Sigma <- Cor <- sdv <- NULL
if (pd) {
  Sigma <- solve(-H); sdv <- sqrt(diag(Sigma)); Cor <- Sigma / outer(sdv, sdv)
  cat(sprintf("\n-H IS positive-definite. condition number %.4g\n",
              max(ev$values) / min(ev$values)))
  cat(sprintf("log|-H| = %.4f\n", sum(log(-ev$values))))
  cat("\nstrongest parameter correlations (|r| > 0.8):\n")
  ut <- which(upper.tri(Cor) & abs(Cor) > 0.8, arr.ind = TRUE)
  if (nrow(ut)) {
    o <- order(-abs(Cor[ut]))
    for (i in o) cat(sprintf("  %-16s %-16s r = %+.3f\n",
                             nm[ut[i, 1]], nm[ut[i, 2]], Cor[ut[i, 1], ut[i, 2]]))
  } else cat("  none\n")
  cat("\nposterior sd, unconstrained scale (and what it reaches in natural units):\n")
  for (k in order(sdv))
    cat(sprintf("  %-16s %9.5f   +/- %-12.5g around %.5g\n",
                nm[k], sdv[k], sdv[k] * reach[k], md$par_mode[[nm[k]]]))
} else {
  cat(sprintf("\nSTILL NOT negative-definite. %d non-negative eigenvalue(s):\n",
              sum(ev$values >= 0)))
  for (b in which(ev$values >= 0)) {
    v <- ev$vectors[, b]; o <- order(-abs(v))[1:4]
    cat(sprintf("  eigenvalue %+.4g dominated by: %s\n", ev$values[b],
                paste(sprintf("%s (%+.2f)", nm[o], v[o]), collapse = ", ")))
  }
}

out <- list(mode_file = HESS_MODE_FILE, logpost = lp0,
            par_mode = md$par_mode, u_mode = u,
            hml_bound = md$hml_bound, pump_mode = md$pump_mode,
            hessian = H, cov = Sigma, cor = Cor, sd_unc = sdv, pd = pd,
            logdet_negH = if (pd) sum(log(-ev$values)) else NA_real_,
            eigen = ev, hess_eps = EPSV, hess_eps_unstable = failed,
            hess_eps_no_plateau = unstable, hess_eps_frac = HESS_EPS_FRAC,
            sd_diag = SDV, hess_eps_verify = V,
            hess_eps_grid = HESS_EPS_GRID, hess_diag_by_step = D,
            unc_reach = reach, stable_tol = HESS_STABLE_TOL)
saveRDS(out, HESS_OUT_FILE)
cat(sprintf("\nwrote %s\n", HESS_OUT_FILE))

if (HESS_UPDATE) {
  # Only ever after the gates, and only the second-order block. par_mode,
  # logpost, streams and the optimisation trace are the refit's, not ours.
  md$hessian <- H; md$cov <- Sigma; md$cor <- Cor; md$sd_unc <- sdv
  md$pd <- pd; md$eigen <- ev; md$hess_eps <- EPSV
  md$hess_eps_unstable <- failed; md$hess_diag_by_step <- D
  md$hess_eps_frac <- HESS_EPS_FRAC
  md$logdet_negH <- if (pd) sum(log(-ev$values)) else NA_real_
  md$hess_recomputed <- TRUE
  saveRDS(md, HESS_MODE_FILE)
  cat(sprintf("updated the second-order block of %s (--update)\n", HESS_MODE_FILE))
} else {
  cat("mode file NOT modified; pass --update to write the second-order block back\n")
}
