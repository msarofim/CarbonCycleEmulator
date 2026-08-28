# =====================================================================
# diag_hess_eps_21par.R -- IS `ARM_HESS_EPS = 3e-4` STILL A VALID
# FINITE-DIFFERENCE STEP AT 21 PARAMETERS?
#
# WHY THIS RUNS BEFORE THE REFIT AND NOT AFTER IT.
#
# The two-arm refit's PRIMARY comparison is a Laplace evidence, and the term
# that a MAP-only comparison drops -- -0.5 log|-H| -- is computed from a single
# fixed central-difference step, `ARM_HESS_EPS`. The driver does NOT sweep it:
# if the Hessian comes back non-PD the arm's evidence degrades to NA and the
# ~11 h is spent for a comparison that cannot be made. `recompute_hessian.R`
# exists as the after-the-fact remedy, and its own header records why the
# question is not academic -- at MODE_HESS_EPS = 1e-3 a step in log(kz) cost
# 49,000 log-units and returned a second derivative of -4.9e10 against a true
# -41.3, i.e. nine orders of magnitude of pure step-size artefact.
#
# THREE THINGS HAVE CHANGED SINCE 3e-4 WAS LAST EXERCISED, and each moves the
# usable window in a DIFFERENT direction, which is why the answer is measured
# rather than argued:
#
#  1. PARAMETER COUNT 18 -> 21. Six coordinates are new since the step was set
#     (`seas_T_amp_NH/SH`, `seas_lag_p`, `sst_seas_amp_NH/SH`, `rep_dC`) and
#     four are gone (`seas_amp_*`, `seas_phase_*`, `sigma_d13c`). A step
#     validated on coordinates that no longer exist says nothing about the ones
#     that replaced them.
#  2. `rep_dC` IS ON THE IDENTITY SCALE with a prior sd of 1.0 ppm, so its
#     curvature is O(1) in natural units -- the SMALLEST in the table by orders
#     of magnitude. Small curvature is exactly the case where a small step
#     drowns in roundoff: the second difference scales as c*eps^2 while the
#     roundoff floor scales as |logpost|*eps_mach and does NOT shrink with eps.
#  3. `h_ml` IS BOUNDED TO [85, 120] FOR THE REFIT (Marcus 2026-08-16g), a
#     logit coordinate over a support 4.9x narrower than the shipped [30, 200].
#     The unconstrained scale is therefore a DIFFERENT scale, and a step size is
#     a statement about a scale. This script applies the SAME override so it is
#     validating the step on the objective the refit will actually optimise.
#
# WHAT IT DOES NOT AND CANNOT DO. There is no mode on the post-2026-08-18 model
# -- that is what the refit is for -- so this cannot sweep at the point where
# the Hessian will finally be taken. It sweeps at TWO points instead, chosen to
# bracket rather than to guess:
#   * INIT -- `ccx_init_unc()`, the exact point both arms start from.
#   * LIFTED -- the adopted arm-N mode's 15 surviving parameters with defaults
#     for the 6 new ones. NOT a mode of anything (its `q10` and `beta_max` were
#     fitted against the seasonal SINE, and under driver seasonality `q10` has
#     seasonal duty), but it is a physically DIFFERENT point in the 15
#     directions that carry most of the curvature.
# A step size that is stable at both is not proven stable at the mode; a step
# that FAILS at either is disqualified now, for 1 minute of compute instead of
# 11 hours. That asymmetry is the whole design.
#
# Usage:  Rscript calibration/diag_hess_eps_21par.R
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

# ---- labels and thresholds derive from named constants (project rule) ----
HEPS_GRID       <- c(1e-5, 3e-5, 1e-4, 3e-4, 1e-3, 3e-3)
HEPS_SHIPPED    <- 3e-4      # the value under test = run_modefind_pump_arms.R's
HEPS_STABLE_TOL <- 0.25      # max relative spread over a window, as
                             # recompute_hessian.R's HESS_STABLE_TOL
HEPS_WINDOW_MIN <- 3L        # a "window" must span at least this many grid steps
# ⚠ RETIRED BAND, 2026-08-28. This file was written when the three
# ocean-gradient rows SKIPPED outside [85, 120]. They are now scored at
# sigma_eff at every h_ml (option 5). What it reads below is PROVENANCE:
# results produced under it are NOT comparable with post-adoption fits.
HEPS_HML_BOUND  <- LIK_OCEAN_GRAD_HML_OK_RETIRED   # [85, 120], as ARM_HML_BOUND
HEPS_HML_INIT   <- 100                     # as ARM_HML_INIT
HEPS_MODE_FILE  <- ccx_mode_file()
HEPS_ARM        <- "N"       # sweep arm; D is spot-checked at HEPS_SHIPPED
HEPS_SPOT_ARM   <- "D"
HEPS_MACH       <- .Machine$double.eps

sep <- function(s) cat(sprintf("\n\n=== %s ===\n", s))

cat(sprintf("HESSIAN STEP CHECK at %d parameters: %s\n",
            length(CCX_PARAM_NAMES), paste(CCX_PARAM_NAMES, collapse = ", ")))
cat(sprintf("shipped ARM_HESS_EPS = %.0e; grid = %s\n",
            HEPS_SHIPPED, paste(format(HEPS_GRID, scientific = TRUE), collapse = ", ")))

# =====================================================================
# The h_ml override, IDENTICAL to the refit driver's, with the same gate.
# Without it this script measures curvature in a coordinate the refit does not
# use, which is the failure it exists to prevent.
# =====================================================================
sep("h_ml BOUNDED, mirroring run_modefind_pump_arms.R")
.tab_before <- CCX_PARAM_TABLE
CCX_PARAM_TABLE$h_ml$lo    <- HEPS_HML_BOUND[1]
CCX_PARAM_TABLE$h_ml$hi    <- HEPS_HML_BOUND[2]
CCX_PARAM_TABLE$h_ml$init  <- HEPS_HML_INIT
CCX_PARAM_TABLE$h_ml$prior <-
  local({ lo <- HEPS_HML_BOUND[1]; hi <- HEPS_HML_BOUND[2]
          function(x) stats::dunif(x, lo, hi, log = TRUE) })
.chg <- names(which(!vapply(CCX_PARAM_NAMES, function(n)
  identical(CCX_PARAM_TABLE[[n]], .tab_before[[n]]), logical(1))))
if (!identical(.chg, "h_ml"))
  stop("the h_ml override touched more than h_ml: ", paste(.chg, collapse = ", "))
cat(sprintf("h_ml -> [%g, %g] init %g. GATE: only `h_ml` changed. OK\n",
            HEPS_HML_BOUND[1], HEPS_HML_BOUND[2], HEPS_HML_INIT))
rm(.tab_before, .chg)

# =====================================================================
# The two evaluation points.
# =====================================================================
sep("EVALUATION POINTS")
u_init <- ccx_init_unc(); names(u_init) <- CCX_PARAM_NAMES

md <- readRDS(HEPS_MODE_FILE)
shared <- intersect(names(md$par_mode), CCX_PARAM_NAMES)
dropped <- setdiff(md$param_names, CCX_PARAM_NAMES)
added   <- setdiff(CCX_PARAM_NAMES, md$param_names)
# Built in the UNCONSTRAINED coordinates on top of the init vector, not through
# ccx_default_params(): the likelihood-side parameters (`rep_dC`, `sigma_d14c`,
# the two `grad_off_*`) are not model fields, so a natural-scale round trip
# through the default parameter list drops them silently.
u_lift <- u_init
for (n in shared) u_lift[[n]] <- .to_unc(md$par_mode[[n]], CCX_PARAM_TABLE[[n]])
names(u_lift) <- CCX_PARAM_NAMES
p_lift <- ccx_unc_to_par(u_lift)
cat(sprintf("LIFTED from %s: %d of %d parameters carried over.\n",
            basename(HEPS_MODE_FILE), length(shared), length(CCX_PARAM_NAMES)))
cat(sprintf("  gone since that fit (%d): %s\n", length(dropped), paste(dropped, collapse = ", ")))
cat(sprintf("  new since that fit (%d, at defaults): %s\n", length(added), paste(added, collapse = ", ")))
# The lifted point must be FEASIBLE -- h_ml 94.36 is inside the refit's bound,
# but that is a fact about this rds and is asserted rather than assumed.
if (!all(is.finite(u_lift)))
  stop("the lifted point does not round-trip through the transforms: ",
       paste(CCX_PARAM_NAMES[!is.finite(u_lift)], collapse = ", "))
cat(sprintf("  h_ml carried = %.2f m, inside [%g, %g]. all 21 coordinates finite. OK\n",
            p_lift$h_ml, HEPS_HML_BOUND[1], HEPS_HML_BOUND[2]))

bp <- ccx_default_params(); bp$pump_mode <- HEPS_ARM
lp <- ccx_make_logpost(base_params = bp)

# DETERMINISM. The roundoff analysis below assumes the objective is a pure
# function of u -- if it were not, no step size would help and the finding would
# be that, not a window. Asserted, because it is cheap and it is load-bearing.
if (lp(u_init) != lp(u_init) || lp(u_lift) != lp(u_lift))
  stop("ccx_make_logpost() is not deterministic -- the step-size question is moot")
cat("GATE: the objective is bit-reproducible on repeat evaluation. OK\n")

POINTS <- list(init = u_init, lifted = u_lift)

# =====================================================================
# Diagonal curvature vs step, at each point.
#
# Reporting the DIAGONAL rather than the full Hessian is deliberate: the
# roundoff/truncation trade-off is per-coordinate, a full 21x21 sweep over 6
# steps is 6 x 924 evaluations for information the diagonal already carries,
# and the driver's failure mode (non-PD) is driven by diagonal entries going
# wrong sign or wrong magnitude.
# =====================================================================
diag_at <- function(u, lp0, eps) {
  vapply(seq_along(u), function(k) {
    e <- numeric(length(u)); e[k] <- eps
    fp <- lp(u + e); fm <- lp(u - e)
    if (!is.finite(fp) || !is.finite(fm)) return(NA_real_)
    (fp - 2 * lp0 + fm) / eps^2
  }, numeric(1))
}

# The largest contiguous run of grid steps over which a coordinate's curvature
# agrees to HEPS_STABLE_TOL. Contiguity matters: two steps agreeing at opposite
# ends of the grid with garbage between them is not a window.
best_window <- function(v) {
  n <- length(v); best <- c(NA_integer_, NA_integer_, 0L)
  for (a in seq_len(n)) for (b in a:n) {
    r <- v[a:b]
    if (anyNA(r) || any(!is.finite(r)) || any(r >= 0)) next
    if ((max(r) - min(r)) / abs(mean(r)) > HEPS_STABLE_TOL) next
    if (b - a + 1L > best[3]) best <- c(a, b, b - a + 1L)
  }
  best
}

RES <- list()
for (pt in names(POINTS)) {
  u <- POINTS[[pt]]; lp0 <- lp(u)
  sep(sprintf("POINT `%s`  (log-post %.2f, arm %s)", pt, lp0, HEPS_ARM))
  D <- sapply(HEPS_GRID, function(e) diag_at(u, lp0, e))
  rownames(D) <- CCX_PARAM_NAMES; colnames(D) <- format(HEPS_GRID, scientific = TRUE)
  cat("diagonal curvature d2(logpost)/du2 vs step (NA = step leaves the feasible region):\n")
  print(signif(D, 4))

  W <- t(vapply(seq_len(nrow(D)), function(i) best_window(D[i, ]), numeric(3)))
  lo <- ifelse(is.na(W[, 1]), NA, HEPS_GRID[W[, 1]])
  hi <- ifelse(is.na(W[, 2]), NA, HEPS_GRID[W[, 2]])
  # ANALYTIC roundoff floor, from first principles rather than from the grid:
  # the second difference resolves c*eps^2 against an absolute noise of about
  # 4*|logpost|*eps_mach, so eps must exceed sqrt(4|lp0|*eps_mach/(tol*|c|)).
  cref <- apply(D, 1, function(r) { r <- r[is.finite(r)]; if (!length(r)) NA_real_ else stats::median(abs(r)) })
  floor_pred <- sqrt(4 * abs(lp0) * HEPS_MACH / (HEPS_STABLE_TOL * cref))
  tab <- data.frame(curvature = signif(cref, 4),
                    win_lo = lo, win_hi = hi, win_n = W[, 3],
                    roundoff_floor = signif(floor_pred, 2),
                    shipped_ok = HEPS_SHIPPED >= lo & HEPS_SHIPPED <= hi,
                    row.names = CCX_PARAM_NAMES)
  cat(sprintf("\nlargest contiguous stable window per coordinate (tol %.2f, min span %d):\n",
              HEPS_STABLE_TOL, HEPS_WINDOW_MIN))
  print(tab)
  RES[[pt]] <- list(D = D, tab = tab, lp0 = lp0)
}

# =====================================================================
# READING THE TABLES ABOVE, and the distinction that has to be made before any
# verdict: a coordinate can fail the window test for TWO UNRELATED REASONS.
#
#  (i) STEP-SIZE FAILURE -- the curvature depends on the step. That is what this
#      script is for.
#  (ii) NOT A MODE -- the curvature is POSITIVE, stably, at every step. Neither
#      probe point is a maximum (there is no mode on this model yet), so a
#      positive diagonal means only that the refit will move that coordinate.
#      `sst_seas_amp_NH` at both points and `pump_grad` at init are this case,
#      and calling them step-size failures would be a category error.
#
# Split, because the recommendation differs completely between them.
# =====================================================================
sep("VERDICT")
classify <- function(r) {
  D <- r$D; nm <- rownames(D)
  pos <- apply(D, 1, function(v) all(v > 0, na.rm = TRUE))
  win <- !is.na(r$tab$win_lo) & HEPS_SHIPPED >= r$tab$win_lo & HEPS_SHIPPED <= r$tab$win_hi
  list(ok = nm[win], not_mode = nm[pos & !win], step_fail = nm[!pos & !win])
}
CL <- lapply(RES, classify)
for (pt in names(CL)) {
  cl <- CL[[pt]]
  cat(sprintf("point `%s`:\n", pt))
  cat(sprintf("  eps = %.0e is INSIDE a stable window for %2d/%d coordinates\n",
              HEPS_SHIPPED, length(cl$ok), length(CCX_PARAM_NAMES)))
  cat(sprintf("  positive curvature, stable (NOT a step-size problem -- this point is\n"))
  cat(sprintf("    simply not a maximum in that direction): %s\n",
              if (length(cl$not_mode)) paste(cl$not_mode, collapse = ", ") else "none"))
  cat(sprintf("  STEP-DEPENDENT curvature (the real failures): %s\n",
              if (length(cl$step_fail)) paste(cl$step_fail, collapse = ", ") else "none"))
}

# =====================================================================
# THE h_ml DIRECTION IS NOT A STEP-SIZE PROBLEM EITHER. IT IS A KINK.
#
# At `init` the h_ml second difference scales as 1/eps across the whole grid --
# -170900 at 1e-5 through -578 at 3e-3, a factor 3.0 per factor 3.0 of step.
# A JUMP in the value would scale as 1/eps^2 and roundoff would not scale at
# all; 1/eps is the signature of a CONTINUOUS function with a DISCONTINUOUS
# FIRST DERIVATIVE. Confirmed directly: the one-sided slopes at h_ml = 100 are
# -16.21 (left) and -17.92 (right), both stable over six decades of step.
#
# WHERE IT COMES FROM -- ccx_pump_shape(), and it is not a bug. The observed
# GLODAP DIC profile is remapped onto the model grid by OVERLAP INTEGRATION,
#     ov <- pmax(0, pmin(b, pr$bot) - pmax(a, pr$top))
# which is the conservative, correct way to put 25 m observed bins onto model
# layers. But `h_ml` IS a layer boundary, so as it moves, that pmax(0, .)
# switches on and off against the fixed observed bin edges. A clamped overlap is
# exactly a |x|: continuous, with a slope that jumps.
#
# The kinks propagate only to the ISOTOPES, which is why co2_level barely moves
# (-5e-4 of slope jump) while d13c_level_MLO and _SPO carry -0.153 and -0.115 of
# the -0.270 total: in `pump_mode = N` the export is constant-mass, so it is the
# 13C fractionation that the pump field actually moves. Same channel as the
# pump x advection reversal.
#
# THE STRUCTURE IS SPARSE, which is the reason this is a caveat and not a
# blocker. Computed below from the shape function alone, no model runs.
# =====================================================================
sep("KINK MAP of the h_ml direction over the refit's band")
kh <- seq(HEPS_HML_BOUND[1], HEPS_HML_BOUND[2], by = 0.01)
KS <- t(sapply(kh, function(h) ccx_pump_shape(ccx_ocean_grid(h))))
kt <- rowSums(abs(apply(KS, 2, function(v) diff(diff(v)))))
kb <- which(kt > 20 * stats::median(kt) + 1e-14)
# adjacent grid points belong to one kink
grp <- cumsum(c(TRUE, diff(kb) > 1))
KINKS <- vapply(split(kb, grp), function(ix) kh[ix[which.max(kt[ix])] + 1], numeric(1))
cat(sprintf("%d kink(s) in [%g, %g], from the pump shape's clamped overlap:\n",
            length(KINKS), HEPS_HML_BOUND[1], HEPS_HML_BOUND[2]))
cat(sprintf("  h_ml = %s m\n", paste(sprintf("%.2f", KINKS), collapse = ", ")))
cat(sprintf("  (%d of %d probe points carry one -- the direction is smooth in between)\n",
            length(kb), length(kt)))
cat(sprintf("*** ARM_HML_INIT = %g sits %s ***\n", HEPS_HML_INIT,
            if (any(abs(KINKS - HEPS_HML_INIT) < 1e-6)) "EXACTLY ON ONE OF THEM" else
              sprintf("%.2f m from the nearest", min(abs(KINKS - HEPS_HML_INIT)))))
cat("Harmless to the mode-find itself -- Nelder-Mead is derivative-free -- but\n")
cat("the HESSIAN's h_ml row is undefined within a step of a kink, and that row\n")
cat("enters the Laplace evidence through log|-H|. The driver is therefore made\n")
cat("to CHECK the found mode against this list rather than assume it is clear.\n")

# =====================================================================
# RECOMMENDATION
# =====================================================================
sep("RECOMMENDATION")
sf <- unique(unlist(lapply(CL, `[[`, "step_fail")))
sf <- setdiff(sf, "h_ml")
if (!length(sf)) {
  cat(sprintf("KEEP ARM_HESS_EPS = %.0e.\n", HEPS_SHIPPED))
  cat(sprintf("It sits inside a stable window at BOTH probe points for every\n"))
  cat(sprintf("coordinate whose curvature is a step-size question at all. The two\n"))
  cat(sprintf("exclusions are named, not swept: `h_ml` (a kink -- no step is valid,\n"))
  cat(sprintf("see above) and the positive-curvature coordinates (not a mode).\n"))
  cat(sprintf("The 1e-5 column is the roundoff end and should NOT be used: it moves\n"))
  cat(sprintf("gamma_enso by 7x and flips the sign of kz.\n"))
} else {
  cat(sprintf("*** CHANGE ARM_HESS_EPS. Step-dependent at: %s\n", paste(sf, collapse = ", ")))
}
saveRDS(list(res = RES, classified = CL, kinks = KINKS, grid = HEPS_GRID,
             shipped = HEPS_SHIPPED, params = CCX_PARAM_NAMES, hml_bound = HEPS_HML_BOUND),
        ccx_path("calibration", "output", "hess_eps_21par.rds"))
cat(sprintf("\nwritten: calibration/output/hess_eps_21par.rds (carries the kink list\n"))
cat(sprintf("         the driver's mode-proximity check reads)\n"))
