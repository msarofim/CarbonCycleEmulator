# =====================================================================
# diag_ridge_reparam.R -- DOES FITTING IN RIDGE COORDINATES COST FEWER
#                         OBJECTIVE EVALUATIONS?  (2026-08-25g)
#
# THE MOTIVATION IS MEASURED, NOT ASSUMED. The 2026-08-25f refit spends
# ~332,000 objective evaluations per arm in CYCLE 1 ALONE, at 0.162 s each
# (6.2 evals/s, single core, read off the live logs). ~1.0 M evaluations across
# three arms in 15 h. Nelder-Mead is strictly serial, so no amount of hardware
# shortens ONE arm -- the only lever on a single arm's wall-clock is fewer
# evaluations.
#
# AND THE REASON IT NEEDS SO MANY IS ALREADY KNOWN IN THIS REPO: `beta_max` and
# `fert_k` are correlated at rho = +0.997 (memory ccx_face_fert_k_ceiling,
# ccx_hess_step_sd). A simplex in a +0.997-correlated plane has to crawl along a
# knife-edge. The GOOD COORDINATES were discovered here too and are already used
# by seed_fert_ridge_arms.R and every ridge diagnostic: the ridge-invariant
# present-day enhancement
#
#     enh(chi) = beta_max * d / (fert_k + d),      d = chi - CO2_PI
#
# holding which is exactly what the historical CO2 integral constrains.
#
# ---------------------------------------------------------------------
# THE TEST KEEPS THE OBJECTIVE BIT-IDENTICAL AND CHANGES ONLY THE SEARCH
# VARIABLES, and that distinction is the whole validity of the experiment.
#
# Reparametrising by editing CCX_PARAM_TABLE would change the PRIOR -- a
# different transform carries a different Jacobian, so `lp` would no longer be
# the same function and a "faster" result could just be an easier problem. So
# nothing here touches CCX_PARAM_TABLE, R/ or src/. Instead
#
#     lp2(v) = lp(u_of_v(v))
#
# is the SAME posterior read through a change of search coordinates. GATE 1
# asserts that identity to machine precision; if it ever fails, the comparison
# is meaningless and the file stops.
#
# SAFE TO RUN ALONGSIDE A LIVE REFIT. Rcpp::sourceCpp() compiles into a
# PER-PROCESS R tempdir (verified: /var/folders/.../RtmpXXXX/sourceCpp-...), and
# a running arm sourced R/ and compiled its core at startup, so neither this
# process nor edits on disk can reach it. This file also writes only to its own
# OUTDIR. It does use a core, which will slow a concurrent refit.
#
# Usage:  Rscript calibration/diag_ridge_reparam.R [budget_evals]
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
ccx_load_cpp()

# ---- named constants ------------------------------------------------
RR_CHI      <- 420            # ppm; the epoch enh() is held at, as in seed_fert_ridge_arms.R
RR_BUDGET   <- local({ a <- commandArgs(TRUE); if (length(a)) as.integer(a[1]) else 20000L })
RR_SEEDFILE <- "calibration/output/refit_20260825f_ref/mode_fit_pumpN_progress.rds"
RR_FALLBACK <- "calibration/output/quarantine/20260825_seas_isotope_rectification/pump_arms/mode_fit_pumpN.rds"
RR_PERTURB  <- 0.35           # sd of the common random start offset, in u-units
RR_NSTART   <- 3              # independent starts; one race is an anecdote
RR_SEED     <- 20260825L
RR_HML      <- LIK_OCEAN_GRAD_HML_OK    # the driver's band; see ccx_hml_band_provenance
OUTDIR      <- ccx_path("calibration", "output", "ridge_reparam")
dir.create(OUTDIR, recursive = TRUE, showWarnings = FALSE)

CCX_PARAM_TABLE$h_ml$lo <- RR_HML[1]; CCX_PARAM_TABLE$h_ml$hi <- RR_HML[2]
CCX_PARAM_TABLE$h_ml$prior <- local({ lo <- RR_HML[1]; hi <- RR_HML[2]
                                      function(x) stats::dunif(x, lo, hi, log = TRUE) })
D_NOW <- RR_CHI - ccx_const("CO2_PI_PPM")
IB <- match("beta_max", CCX_PARAM_NAMES); IF <- match("fert_k", CCX_PARAM_NAMES)
SB <- CCX_PARAM_TABLE$beta_max; SF <- CCX_PARAM_TABLE$fert_k

lp <- ccx_make_logpost()

# ---- the change of search coordinates -------------------------------
# v is u everywhere except slot IB, which carries LOGIT-SCALED enh instead of
# logit-scaled beta_max. `fert_k`'s own coordinate is UNCHANGED, so the pair
# becomes (enh, fert_k): the direction the data constrain, and the direction
# they do not.
#
# enh's bounds are DERIVED from the two parents' bounds at this chi, not chosen:
# enh = beta_max * d/(fert_k + d) is increasing in beta_max and decreasing in
# fert_k, so its range over the box is [lo_b*d/(hi_f+d), hi_b*d/(lo_f+d)],
# clipped to (0, hi_b) since enh <= beta_max. Derived from the transform, not
# from a value (memory derive_gate_from_the_thing).
RR_ENH_LO <- max(SB$lo * D_NOW / (SF$hi + D_NOW), 1e-8)
RR_ENH_HI <- min(SB$hi * D_NOW / (SF$lo + D_NOW), SB$hi)
.lgt  <- function(x, lo, hi) log((x - lo) / (hi - x))
.ilgt <- function(z, lo, hi) lo + (hi - lo) / (1 + exp(-z))

u_of_v <- function(v) {
  u <- v
  fert <- .ilgt(v[[IF]], SF$lo, SF$hi)
  enh  <- .ilgt(v[[IB]], RR_ENH_LO, RR_ENH_HI)
  bmax <- enh * (fert + D_NOW) / D_NOW
  # OUT OF beta_max's BOX IS NOT AN ERROR, IT IS -Inf, exactly as the prior
  # would give. Returning NA here would make the two arms differ in their
  # FEASIBLE SET rather than in their coordinates, which is the confound this
  # whole file exists to avoid.
  if (!is.finite(bmax) || bmax <= SB$lo || bmax >= SB$hi) return(NULL)
  u[[IB]] <- .lgt(bmax, SB$lo, SB$hi)
  u
}
v_of_u <- function(u) {
  v <- u
  fert <- .ilgt(u[[IF]], SF$lo, SF$hi)
  bmax <- .ilgt(u[[IB]], SB$lo, SB$hi)
  enh  <- bmax * D_NOW / (fert + D_NOW)
  v[[IB]] <- .lgt(min(max(enh, RR_ENH_LO * (1 + 1e-12)), RR_ENH_HI * (1 - 1e-12)),
                  RR_ENH_LO, RR_ENH_HI)
  v
}
lp2 <- function(v) { u <- u_of_v(v); if (is.null(u)) return(-Inf); lp(u) }

# ---- the start point -------------------------------------------------
seedfile <- if (file.exists(ccx_path(RR_SEEDFILE))) RR_SEEDFILE else RR_FALLBACK
md <- readRDS(ccx_path(seedfile))
stopifnot(identical(md$param_names, CCX_PARAM_NAMES) || is.null(md$param_names))
U0 <- ccx_par_to_unc(md$par_mode)
cat(sprintf("=== RIDGE REPARAMETRISATION RACE ===\nstart file: %s\n", seedfile))
if (identical(seedfile, RR_FALLBACK))
  cat("*** PRELIMINARY: the post-fix reference mode has not been written yet, so this\n",
      "*** races from the PRE-FIX mode. The rho = +0.997 geometry is a property of the\n",
      "*** CO2 integral and is not expected to move with the isotope fix -- but that is\n",
      "*** an expectation, not a measurement. RE-RUN when the progress file exists.\n", sep = "")
cat(sprintf("enh bounds derived from the parents' box: [%.4g, %.4g]; enh(start) = %.6f\n",
            RR_ENH_LO, RR_ENH_HI,
            md$par_mode$beta_max * D_NOW / (md$par_mode$fert_k + D_NOW)))

# ---- GATE 1: the objective is UNCHANGED ------------------------------
cat("\nGATE 1: lp2(v_of_u(u)) must equal lp(u) -- same function, new coordinates.\n")
set.seed(RR_SEED)
g1 <- vapply(seq_len(6), function(i) {
  u <- U0 + (if (i == 1) 0 else stats::rnorm(length(U0), 0, RR_PERTURB))
  a <- lp(u); b <- lp2(v_of_u(u))
  if (!is.finite(a) && !is.finite(b)) return(0)
  abs(a - b)
}, numeric(1))
cat(sprintf("  max |lp - lp2| over 6 points: %.3e\n", max(g1)))
stopifnot(max(g1) < 1e-8)
cat("  and the round trip u -> v -> u must be the identity:\n")
g2 <- max(abs(u_of_v(v_of_u(U0)) - U0))
cat(sprintf("  max |u - u(v(u))| = %.3e\n", g2))
stopifnot(g2 < 1e-8)
cat("GATE 1 PASS.\n")

# ---- the race --------------------------------------------------------
# SAME optimiser, SAME budget, SAME starts, SAME function. Only the coordinates
# differ. Nelder-Mead is the driver's own inner method.
race <- function(f, x0, budget)
  stats::optim(x0, function(z) -f(z), method = "Nelder-Mead",
               control = list(maxit = budget, reltol = 1e-12))

cat(sprintf("\nRACE: Nelder-Mead, budget %d evals, %d starts (start 1 = the mode itself)\n\n",
            RR_BUDGET, RR_NSTART))
cat(sprintf("%-7s %14s %14s %14s %10s\n", "start", "u-coords", "v-coords (ridge)",
            "difference", "start lp"))
set.seed(RR_SEED)
RES <- lapply(seq_len(RR_NSTART), function(i) {
  u0 <- U0 + (if (i == 1) 0 else stats::rnorm(length(U0), 0, RR_PERTURB))
  if (!is.finite(lp(u0))) return(NULL)
  ru <- race(lp,  u0,          RR_BUDGET)
  rv <- race(lp2, v_of_u(u0),  RR_BUDGET)
  cat(sprintf("%-7d %14.2f %14.2f %+14.2f %10.1f\n", i, -ru$value, -rv$value,
              -rv$value + ru$value, lp(u0)))
  list(start_lp = lp(u0), u = -ru$value, v = -rv$value,
       u_par = ccx_unc_to_par(setNames(ru$par, CCX_PARAM_NAMES)),
       v_par = ccx_unc_to_par(setNames(u_of_v(rv$par), CCX_PARAM_NAMES)))
})
RES <- Filter(Negate(is.null), RES)
d <- vapply(RES, function(r) r$v - r$u, numeric(1))
cat(sprintf("\nridge coordinates win by %+.2f log-units on average (%d/%d starts)\n",
            mean(d), sum(d > 0), length(d)))
cat("A POSITIVE number means the SAME optimiser reached a HIGHER posterior on the\n")
cat("SAME budget purely from the change of coordinates.\n")
cat(sprintf("At %.3f s/eval that budget is %.1f min per arm per parametrisation.\n",
            0.162, RR_BUDGET * 0.162 / 60))

for (r in RES) cat(sprintf("  landed fert_k: u-coords %8.2f   ridge %8.2f\n",
                           r$u_par$fert_k, r$v_par$fert_k))
saveRDS(list(res = RES, budget = RR_BUDGET, seedfile = seedfile,
             enh_bounds = c(RR_ENH_LO, RR_ENH_HI), chi = RR_CHI),
        file.path(OUTDIR, "ridge_reparam_race.rds"))
cat(sprintf("\nwritten: %s\n", file.path(OUTDIR, "ridge_reparam_race.rds")))
