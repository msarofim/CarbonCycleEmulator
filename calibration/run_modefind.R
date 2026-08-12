# =====================================================================
# run_modefind.R -- locate the posterior mode before sampling.
#
# The pilot MCMC (calibration/run_pilot.R) started the correlated parameters at
# hand-set defaults ~87,000 log-units below the mode and was still climbing at
# the last iteration: worst R-hat 4.53, min ESS 4, acceptance 0.045-0.063.
# That is transient burn-in, not sampling. Handoff 2026-08-10 sec.4 fix 1.
#
# 2026-08-11: this now runs against the REBUILT posterior -- 17 parameters, not
# 18 (rho retired), annual values with independent errors plus an explicit
# seasonal statistic, and an integrator whose substep count is chosen from the
# diffusion stability criterion rather than fixed at 4. Every earlier mode is
# quarantined under calibration/output/quarantine/ and is NOT comparable: the
# likelihood it maximised is a different function.
#
# The single mode-finding driver. calibration/run_modefind_bombwin.R was a
# near-duplicate differing only in its output filename and was folded in here.
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
MODE_RESTARTS    <- 20      # consecutive restarts; stops early on convergence.
                            # RAISED 12 -> 20 on 2026-08-12: the 17-parameter run
                            # hit the cap of 12 while STILL GAINING 1.3-1.8 log-
                            # units per restart, and the BFGS polish then gained a
                            # further 9.7 -- i.e. Nelder-Mead was stalling on a
                            # collapsed simplex, not sitting at the optimum, and
                            # the cap silently truncated a live climb. Costs
                            # nothing when MODE_TOL is reached first.
MODE_TOL         <- 1e-4    # stop when a restart gains less than this in log-post
MODE_PENALTY     <- 1e6     # finite stand-in for -Inf so optim can navigate
MODE_HESS_EPS    <- 3e-4    # step on the unconstrained scale for the Hessian.
                            # 1e-3 WAS TOO LARGE and produced a non-PD Hessian:
                            # at the bomb-window mode, stepping log(kz) by 1e-3
                            # costs 49,000 log-units and 1e-2 leaves the feasible
                            # region, so the central difference returned -4.9e10
                            # where the true second derivative is -41.3. Always
                            # confirm with calibration/recompute_hessian.R, which
                            # sweeps the step and checks curvature is stable
                            # before trusting the covariance.
MODE_OUT         <- file.path("calibration", "output", "mode_fit.rds")
# Physical plausibility markers, printed next to the mode. These are NOT
# constraints -- the prior already carries that -- they exist because the
# 2026-08-10 mode was accepted for a day before anyone noticed q10 = 0.28 means
# respiration FALLS with warming. Anything flagged here needs an explanation.
MODE_FLAG_SIGMA  <- 3.0     # prior-sd distance at which a parameter is flagged

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
cat(sprintf("       %d parameters: %s\n", length(CCX_PARAM_NAMES),
            paste(CCX_PARAM_NAMES, collapse = ", ")))

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

# ---- (b2) physical-plausibility screen ------------------------------
# Report how far each parameter sits in its own prior's tail, and report the
# substep count the integrator needed, so a mode pressed against the stability
# criterion is visible rather than inferred later from a failed pilot.
pm <- ccx_unc_to_par(u)
prior_z <- function(n) {
  s <- CCX_PARAM_TABLE[[n]]; x <- pm[[n]]
  # numerical quantile position of x under the prior, expressed in normal sds
  g <- s$prior
  lo <- x / 1e3; hi <- x * 1e3
  if (s$tr == "logit") { lo <- s$lo + 1e-9; hi <- s$hi - 1e-9 }
  xs <- seq(lo, hi, length.out = 4001)
  d <- exp(vapply(xs, function(z) g(z), numeric(1)))
  d[!is.finite(d)] <- 0
  if (sum(d) <= 0) return(NA_real_)
  cdf <- cumsum(d) / sum(d)
  qnorm(min(max(approx(xs, cdf, xout = x, rule = 2)$y, 1e-12), 1 - 1e-12))
}
zs <- vapply(CCX_PARAM_NAMES, function(n) tryCatch(prior_z(n), error = function(e) NA_real_),
             numeric(1))
flag <- which(abs(zs) > MODE_FLAG_SIGMA)
cat("\nprior-tail position of the mode (normal sds; |z| > ", MODE_FLAG_SIGMA,
    " flagged):\n", sep = "")
print(round(zs, 2))
if (length(flag)) {
  cat("*** FLAGGED, needs an explanation before this mode is used: ",
      paste(CCX_PARAM_NAMES[flag], collapse = ", "), "\n")
} else {
  cat("no parameter beyond ", MODE_FLAG_SIGMA, " prior sds\n", sep = "")
}
p_mode <- ccx_default_params()
for (n in intersect(names(p_mode), CCX_PARAM_NAMES)) p_mode[[n]] <- pm[[n]]
cat(sprintf("integrator substeps needed at the mode: %d (floor %d) -- kz = %.0f\n",
            ccx_substeps_for(p_mode), CCX_SUBSTEPS_MIN, pm$kz))

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
              max(abs(ev$values)) / min(abs(ev$values))))
} else {
  Cor <- NULL; ev <- NULL; sdv <- NULL
  cat("Laplace covariance: NOT positive-definite at this point -- ",
      "mode is not a clean interior optimum (see saved Hessian)\n", sep = "")
}

el <- as.numeric(difftime(Sys.time(), t0, units = "mins"))
cat(sprintf("\nmode log-post = %.1f  (gain over init %.1f)\n",
            lp_mode, lp_mode - lp0))
cat(sprintf("elapsed %.1f min, %d posterior evaluations (%.3f s/eval)\n",
            el, n_eval, el * 60 / n_eval))

cat("\nmode, natural scale:\n")
print(round(unlist(ccx_unc_to_par(u)), 4))

out <- list(u_mode = u, par_mode = ccx_unc_to_par(u), logpost = lp_mode,
            logpost_init = lp0, hessian = H, cov = Sigma, cor = Cor,
            sd_unc = sdv, eigen = ev, pd = ok_pd, trace = trace,
            n_eval = n_eval, minutes = el, seed = MODE_SEED,
            param_names = CCX_PARAM_NAMES, prior_z = zs,
            substeps = ccx_substeps_for(p_mode))
saveRDS(out, MODE_OUT)
cat("\nwrote ", MODE_OUT, "\n", sep = "")
