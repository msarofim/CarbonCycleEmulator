# =====================================================================
# run_repilot.R -- short pilot restarted FROM THE MODE, with a proposal scaled
# to the posterior instead of an isotropic 0.05.
#
# This is evidence-gathering, NOT a production posterior. It answers one
# question: does starting at the mode with a Hessian-scaled proposal move
# acceptance toward 0.234 and R-hat toward 1? The original pilot
# (calibration/run_pilot.R) failed on both because it started 18 correlated
# parameters ~87,000 log-units below the mode with a spherical proposal:
# worst R-hat 4.53, min ESS 4, acceptance 0.045-0.063.
#
# Same length and seed as that pilot so the comparison is like-for-like.
#
# Usage:  Rscript calibration/run_repilot.R [mode_fit_file]
# Output: calibration/output/repilot_fit.rds
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

args <- commandArgs(trailingOnly = TRUE)
REPILOT_MODE_FILE <- if (length(args)) args[1] else
  file.path("calibration", "output", "mode_fit_bombwin.rds")
REPILOT_N_ITER    <- 1500     # matched to the original pilot
REPILOT_N_CHAINS  <- 4        # matched
REPILOT_SEED      <- 2026     # matched
REPILOT_DISPERSE  <- 2.0      # start chains at mode + DISPERSE * posterior sd,
                              # so between-chain variance is meaningful for
                              # R-hat but no chain starts in the far tail
REPILOT_ADAPT_FRAC<- 0.5
REPILOT_ACC_TARGET<- 0.234
REPILOT_OUT       <- file.path("calibration", "output", "repilot_fit.rds")
PILOT_REF <- list(rhat = 4.53, ess = 4, acc = c(0.045, 0.063))

if (!file.exists(REPILOT_MODE_FILE))
  stop("No mode file at '", REPILOT_MODE_FILE, "' -- run calibration/run_modefind.R first.")
md <- readRDS(REPILOT_MODE_FILE)
cat(sprintf("mode file: %s\n", REPILOT_MODE_FILE))
cat(sprintf("mode log-post %.1f; Laplace covariance %s\n", md$logpost,
            if (isTRUE(md$pd)) "positive-definite" else "NOT PD -- falling back to diagonal"))

# Proposal covariance. adaptMCMC accepts either a variance vector or a full
# covariance matrix; the full matrix is the point of this run, because an
# isotropic proposal is exactly what a correlated ridge defeats.
if (isTRUE(md$pd)) {
  Sig <- md$cov
  sdv <- md$sd_unc
} else {
  # Not PD: use whatever curvature the diagonal gives, floored so a flat or
  # wrong-signed direction cannot produce an absurd step.
  d <- diag(md$hessian)
  sdv <- ifelse(d < 0, sqrt(1 / -d), 0.1)
  sdv <- pmin(pmax(sdv, 1e-3), 1.0)
  Sig <- diag(sdv^2)
  cat("  diagonal fallback sd range: ", sprintf("%.4g", min(sdv)), " to ",
      sprintf("%.4g", max(sdv)), "\n", sep = "")
}

lp <- ccx_make_logpost()
cat(sprintf("\nrepilot: %d iters x %d chains, seed %d, dispersion %.1f posterior sd\n",
            REPILOT_N_ITER, REPILOT_N_CHAINS, REPILOT_SEED, REPILOT_DISPERSE))
t0 <- Sys.time()
chains <- lapply(seq_len(REPILOT_N_CHAINS), function(i) {
  set.seed(REPILOT_SEED + i)
  st <- md$u_mode + REPILOT_DISPERSE * sdv * stats::rnorm(length(sdv))
  names(st) <- CCX_PARAM_NAMES
  res <- adaptMCMC::MCMC(lp, n = REPILOT_N_ITER, init = st, scale = Sig,
                         adapt = floor(REPILOT_ADAPT_FRAC * REPILOT_N_ITER),
                         acc.rate = REPILOT_ACC_TARGET, showProgressBar = FALSE)
  colnames(res$samples) <- CCX_PARAM_NAMES
  cat(sprintf("  chain %d done, acceptance %.3f\n", i, res$acceptance.rate))
  res
})
el <- as.numeric(difftime(Sys.time(), t0, units = "mins"))
fit <- list(chains = chains, param_names = CCX_PARAM_NAMES, n_iter = REPILOT_N_ITER,
            years = c(1750, 2024), seed = REPILOT_SEED, mode_file = REPILOT_MODE_FILE,
            proposal = Sig, minutes = el)
saveRDS(fit, REPILOT_OUT)

# ---- diagnostics -----------------------------------------------------
acc <- sapply(chains, function(c) c$acceptance.rate)
burn <- floor(REPILOT_N_ITER / 2)
draws <- lapply(chains, function(c) c$samples[(burn + 1):REPILOT_N_ITER, , drop = FALSE])
rhat_ess <- function(k) {
  m <- sapply(draws, function(d) d[, k]); n <- nrow(m); ch <- ncol(m)
  W <- mean(apply(m, 2, var)); B <- n * var(colMeans(m))
  vh <- ((n - 1) / n) * W + B / n
  rh <- if (W > 0) sqrt(vh / W) else NA_real_
  # ESS from the combined-chain autocorrelation, with maxlag at the series
  # length -- acf's default truncation would floor ESS artificially.
  v <- as.vector(m)
  a <- stats::acf(v, lag.max = length(v) - 1, plot = FALSE, demean = TRUE)$acf[-1]
  cut <- which(a < 0.05)[1]; if (is.na(cut)) cut <- length(a)
  ess <- length(v) / (1 + 2 * sum(a[seq_len(cut)]))
  c(rhat = rh, ess = ess)
}
di <- t(sapply(seq_along(CCX_PARAM_NAMES), rhat_ess))
rownames(di) <- CCX_PARAM_NAMES

cat(sprintf("\nelapsed %.1f min\n", el))
cat("\n=== repilot vs original pilot ===\n")
cat(sprintf("  acceptance : %.3f-%.3f   (pilot %.3f-%.3f, target %.3f)\n",
            min(acc), max(acc), PILOT_REF$acc[1], PILOT_REF$acc[2], REPILOT_ACC_TARGET))
cat(sprintf("  worst R-hat: %.3f          (pilot %.2f, gate < 1.05)\n",
            max(di[, "rhat"], na.rm = TRUE), PILOT_REF$rhat))
cat(sprintf("  min ESS    : %.0f             (pilot %d, gate >= 400)\n",
            min(di[, "ess"], na.rm = TRUE), PILOT_REF$ess))
cat("\nper-parameter (worst 8 by R-hat):\n")
print(round(di[order(-di[, "rhat"]), ][1:8, ], 3))
cat("\nNOTE: a 1500-iteration pilot cannot reach ESS 400; the question here is\n")
cat("whether acceptance and R-hat MOVED, not whether they pass the gates.\n")
