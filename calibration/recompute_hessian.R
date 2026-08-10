# =====================================================================
# recompute_hessian.R -- redo the Hessian at an already-located mode with a
# validated step size, without repeating the 100-minute optimisation.
#
# WHY: run_modefind.R used a single MODE_HESS_EPS = 1e-3 on the unconstrained
# scale for all 18 parameters. At the bomb-window mode that is far too large:
# stepping log(kz) by 1e-3 costs 49,000 log-units and by 1e-2 leaves the
# feasible region entirely, so the central difference returned -4.9e10 and the
# Laplace covariance came out non-positive-definite. At 1e-4 the same second
# derivative is -41.3.
#
# This script sweeps candidate steps, picks the largest one for which the
# curvature is stable, and reports whether the result is a usable proposal.
#
# Usage:  Rscript calibration/recompute_hessian.R [mode_file]
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

args <- commandArgs(trailingOnly = TRUE)
HESS_MODE_FILE <- if (length(args)) args[1] else
  file.path("calibration", "output", "mode_fit_bombwin.rds")
HESS_EPS_GRID  <- c(3e-5, 1e-4, 3e-4)   # candidate unconstrained steps
HESS_STABLE_TOL<- 0.25                  # max relative spread in the diagonal
                                        # across the grid for a step to count
                                        # as stable

md <- readRDS(HESS_MODE_FILE)
u  <- md$u_mode; nm <- md$param_names
lp <- ccx_make_logpost()
lp0 <- lp(u)
cat(sprintf("mode file %s\nlog-post %.4f\n\n", HESS_MODE_FILE, lp0))

# ---- diagonal curvature at each candidate step ----------------------
diag_at <- function(eps) {
  vapply(seq_along(u), function(k) {
    e <- numeric(length(u)); e[k] <- eps
    fp <- lp(u + e); fm <- lp(u - e)
    if (!is.finite(fp) || !is.finite(fm)) return(NA_real_)
    (fp - 2 * lp0 + fm) / eps^2
  }, numeric(1))
}
D <- sapply(HESS_EPS_GRID, diag_at)
rownames(D) <- nm; colnames(D) <- format(HESS_EPS_GRID, scientific = TRUE)
cat("diagonal curvature vs step size (NA = step leaves the feasible region):\n")
print(signif(D, 4))

rel_spread <- apply(D, 1, function(r) {
  r <- r[is.finite(r)]
  if (length(r) < 2) return(Inf)
  (max(r) - min(r)) / abs(mean(r))
})
cat("\nrelative spread across steps (want < ", HESS_STABLE_TOL, "):\n", sep = "")
print(round(sort(rel_spread, decreasing = TRUE), 3))

# largest step that is finite for every parameter
ok_eps <- HESS_EPS_GRID[apply(D, 2, function(c) all(is.finite(c)))]
if (!length(ok_eps)) stop("No candidate step keeps every parameter feasible.")
EPS <- max(ok_eps)
cat(sprintf("\nusing eps = %.0e (largest step feasible for all 18 parameters)\n", EPS))

# ---- full Hessian ---------------------------------------------------
n <- length(u); H <- matrix(NA_real_, n, n)
for (a in seq_len(n)) for (b in a:n) {
  ea <- eb <- numeric(n); ea[a] <- EPS; eb[b] <- EPS
  H[a, b] <- H[b, a] <-
    (lp(u + ea + eb) - lp(u + ea - eb) - lp(u - ea + eb) + lp(u - ea - eb)) / (4 * EPS^2)
}
dimnames(H) <- list(nm, nm)
ev <- eigen(H, symmetric = TRUE)
cat("\neigenvalues (all should be < 0 at a clean interior maximum):\n")
print(signif(ev$values, 4))

pd <- all(ev$values < 0)
Sigma <- Cor <- sdv <- NULL
if (pd) {
  Sigma <- solve(-H); sdv <- sqrt(diag(Sigma)); Cor <- Sigma / outer(sdv, sdv)
  cat(sprintf("\nLaplace covariance IS positive-definite. condition number %.4g\n",
              max(ev$values) / min(ev$values)))
  cat("\nstrongest parameter correlations (|r| > 0.8):\n")
  ut <- which(upper.tri(Cor) & abs(Cor) > 0.8, arr.ind = TRUE)
  if (nrow(ut)) {
    o <- order(-abs(Cor[ut]))
    for (i in o) cat(sprintf("  %-14s %-14s r = %+.3f\n",
                             nm[ut[i, 1]], nm[ut[i, 2]], Cor[ut[i, 1], ut[i, 2]]))
  } else cat("  none\n")
  cat("\nposterior sd on the unconstrained scale:\n")
  print(round(sort(sdv), 5))
} else {
  cat("\nSTILL NOT negative-definite at eps = ", format(EPS), ".\n", sep = "")
  bad <- which(ev$values >= 0)
  for (b in bad) {
    v <- ev$vectors[, b]; o <- order(-abs(v))[1:4]
    cat(sprintf("  eigenvalue %+.4g dominated by: %s\n", ev$values[b],
                paste(sprintf("%s (%+.2f)", nm[o], v[o]), collapse = ", ")))
  }
}

md$hessian <- H; md$cov <- Sigma; md$cor <- Cor; md$sd_unc <- sdv
md$pd <- pd; md$hess_eps <- EPS; md$hess_diag_grid <- D
saveRDS(md, HESS_MODE_FILE)
cat(sprintf("\nupdated %s\n", HESS_MODE_FILE))
