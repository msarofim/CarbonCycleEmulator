# =====================================================================
# run_modefind.R -- locate the posterior mode before sampling.
#
# The pilot MCMC (calibration/run_pilot.R) started 18 correlated parameters at
# hand-set defaults ~87,000 log-units below the mode and was still climbing at
# the last iteration: worst R-hat 4.53, min ESS 4, acceptance 0.045-0.063.
# That is transient burn-in, not sampling. Handoff 2026-08-10 sec.4 fix 1.
#
# This script does NOT sample. It (a) finds the mode by derivative-free
# restarts, (b) takes a numerical Hessian there, and (c) reports the curvature
# so the proposal for the next pilot can be scaled to the posterior instead of
# an isotropic 0.05.
#
# Output: calibration/output/mode_fit.rds
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

# ---- labels derive from constants (project rule) --------------------
MODE_SEED        <- 2026
MODE_MAXIT       <- 20000   # Nelder-Mead default 500 is far too small for 18 par
MODE_RESTARTS    <- 12      # consecutive restarts; stops early on convergence
MODE_TOL         <- 1e-4    # stop when a restart gains less than this in log-post
MODE_PENALTY     <- 1e6     # finite stand-in for -Inf so optim can navigate
MODE_HESS_EPS    <- 1e-3    # step on the unconstrained scale for the Hessian
MODE_OUT         <- file.path("calibration", "output", "mode_fit.rds")
PILOT_BEST_LP    <- -6469   # best log-posterior seen in the pilot, for reference

set.seed(MODE_SEED)
dir.create(dirname(MODE_OUT), showWarnings = FALSE, recursive = TRUE)

lp_fun <- ccx_make_logpost()

# optim minimises, and cannot navigate out of -Inf; map non-finite to a large
# finite penalty so a bad proposal is steeply discouraged but still has a slope
# back toward feasible space.
n_eval <- 0L
neg_lp <- function(u) {
  n_eval <<- n_eval + 1L
  v <- lp_fun(u)
  if (!is.finite(v)) return(MODE_PENALTY)
  -v
}

u0 <- ccx_init_unc()
lp0 <- lp_fun(u0)
cat(sprintf("start: log-post at hand-set init = %.1f\n", lp0))
cat(sprintf("       pilot best (for reference) = %.1f\n", PILOT_BEST_LP))

t0 <- Sys.time()

# ---- (a) Nelder-Mead restarts ---------------------------------------
# Restarting NM from its own answer is the standard remedy for its tendency to
# stall on a collapsed simplex in high dimension.
u <- u0
best <- -lp0
trace <- data.frame(restart = 0L, logpost = lp0, evals = 0L)
for (i in seq_len(MODE_RESTARTS)) {
  fit <- optim(u, neg_lp, method = "Nelder-Mead",
               control = list(maxit = MODE_MAXIT, reltol = 1e-12))
  gain <- best - fit$value
  u <- fit$par; best <- fit$value
  cat(sprintf("restart %2d: log-post = %12.1f  (gain %10.4f)  evals %d\n",
              i, -best, gain, n_eval))
  trace <- rbind(trace, data.frame(restart = i, logpost = -best, evals = n_eval))
  if (i > 1 && gain < MODE_TOL) { cat("converged: gain below MODE_TOL\n"); break }
}

# ---- (b) BFGS polish ------------------------------------------------
# The model is deterministic, so numerical gradients are well behaved once we
# are near the mode. This tightens the location before the Hessian is taken.
pol <- tryCatch(
  optim(u, neg_lp, method = "BFGS",
        control = list(maxit = 500, reltol = 1e-14)),
  error = function(e) { cat("BFGS polish failed:", conditionMessage(e), "\n"); NULL })
if (!is.null(pol) && pol$value < best) {
  cat(sprintf("BFGS polish: log-post = %.1f (gain %.4f)\n", -pol$value, best - pol$value))
  u <- pol$par; best <- pol$value
} else {
  cat("BFGS polish: no improvement, keeping Nelder-Mead mode\n")
}
names(u) <- CCX_PARAM_NAMES
lp_mode <- -best

# ---- (c) numerical Hessian at the mode ------------------------------
# Central differences on the unconstrained scale. -H^-1 is the Laplace
# covariance; its correlation matrix is the direct test of the suspected
# k_w / h_ml / kz ridge (handoff sec.4 fix 3).
cat("hessian: central differences, ", length(u), " parameters\n", sep = "")
hess_num <- function(f, x, eps) {
  n <- length(x); H <- matrix(NA_real_, n, n)
  f0 <- f(x)
  for (a in seq_len(n)) for (b in a:n) {
    ea <- eb <- numeric(n); ea[a] <- eps; eb[b] <- eps
    H[a, b] <- H[b, a] <-
      (f(x + ea + eb) - f(x + ea - eb) - f(x - ea + eb) + f(x - ea - eb)) / (4 * eps^2)
  }
  H
}
H <- hess_num(function(z) lp_fun(z), u, MODE_HESS_EPS)
dimnames(H) <- list(CCX_PARAM_NAMES, CCX_PARAM_NAMES)

Sigma <- tryCatch(solve(-H), error = function(e) NULL)
ok_pd <- !is.null(Sigma) && all(is.finite(Sigma)) && all(diag(Sigma) > 0)
if (ok_pd) {
  sdv <- sqrt(diag(Sigma))
  Cor <- Sigma / outer(sdv, sdv)
  ev  <- eigen(Sigma, symmetric = TRUE)
  cat(sprintf("Laplace covariance: PD, condition number %.3g\n",
              max(ev$values) / min(ev$values)))
} else {
  Cor <- NULL; ev <- NULL; sdv <- NULL
  cat("Laplace covariance: NOT positive-definite at this point -- ",
      "mode is not a clean interior optimum (see saved Hessian)\n", sep = "")
}

el <- as.numeric(difftime(Sys.time(), t0, units = "mins"))
cat(sprintf("\nmode log-post = %.1f  (gain over init %.1f, over pilot best %.1f)\n",
            lp_mode, lp_mode - lp0, lp_mode - PILOT_BEST_LP))
cat(sprintf("elapsed %.1f min, %d posterior evaluations (%.3f s/eval)\n",
            el, n_eval, el * 60 / n_eval))

cat("\nmode, natural scale:\n")
print(round(unlist(ccx_unc_to_par(u)), 4))

out <- list(u_mode = u, par_mode = ccx_unc_to_par(u), logpost = lp_mode,
            logpost_init = lp0, hessian = H, cov = Sigma, cor = Cor,
            sd_unc = sdv, eigen = ev, pd = ok_pd, trace = trace,
            n_eval = n_eval, minutes = el, seed = MODE_SEED,
            param_names = CCX_PARAM_NAMES)
saveRDS(out, MODE_OUT)
cat("\nwrote ", MODE_OUT, "\n", sep = "")
