# =====================================================================
# importance.R -- diagnostics for IMPORTANCE WEIGHTS: is a proposal (a Laplace / Gaussian approximation, or
# any other) close enough to the posterior that reweighting its draws can be trusted? (2026-10-08 i)
#
# WHY HERE. The 10-01 (l) Laplace band failed exactly this test (median lp - lp_quad -25.5, ESS 8 / 1000;
# memory laplace_fails_on_fertilisation_ridge), and the test was written inline in a diagnostic. The cut
# posterior (ruled 10-06 o) needs it again, at every adoption, so it lives in one place with its own test.
#
# TWO NUMBERS, because they fail differently:
#   ESS = (sum w)^2 / sum w^2 (Kish). Small when a few draws carry the weight; says nothing about whether the
#     weights have a finite variance at all.
#   k-hat, the Pareto shape of the weights' upper tail (PSIS: Vehtari, Simpson, Gelman, Yao & Gabry 2024,
#     "Pareto smoothed importance sampling", JMLR 25(72)). Their rule: the estimate is reliable when
#     k-hat < min(1 - 1 / log10(S), 0.7) for S draws (0.667 at S = 1000). The tail fit is Zhang & Stephens'
#     (2009, Technometrics 51:316) profile-posterior estimator with the weakly informative prior toward 0.5,
#     as in the {loo} package's gpdfit(), re-implemented because {loo} is not installed here. It is
#     VALIDATED against simulated generalised-Pareto tails of known shape in tests/testthat/test-importance.R.
# =====================================================================

#' Generalised Pareto fit to exceedances (Zhang & Stephens 2009, as {loo}::gpdfit)
#' @param x positive exceedances
#' @param wip shrink k toward 0.5 by the weakly informative prior (loo's default)
#' @return list(k, sigma)
ccx_gpdfit <- function(x, wip = TRUE, min_grid_pts = 30L) {
  x <- sort.int(x); N <- length(x)
  if (N < 5L) stop("ccx_gpdfit(): need at least 5 exceedances, got ", N)
  prior <- 3
  M <- min_grid_pts + floor(sqrt(N)); jj <- seq_len(M)
  xstar <- x[floor(N / 4 + 0.5)]                                  # the first quartile
  theta <- 1 / x[N] + (1 - sqrt(M / (jj - 0.5))) / prior / xstar
  lx <- function(a, x) {                                          # the profile log-likelihood per theta
    a <- -a
    k <- vapply(a, function(ai) mean(log1p(ai * x)), numeric(1))
    log(a / k) - k - 1
  }
  l_theta <- N * lx(theta, x)
  w_theta <- exp(l_theta - (max(l_theta) + log(sum(exp(l_theta - max(l_theta))))))
  theta_hat <- sum(theta * w_theta)
  k <- mean(log1p(-theta_hat * x)); sigma <- -k / theta_hat
  if (wip) k <- (k * N + 10 * 0.5) / (N + 10)
  if (is.nan(k)) k <- Inf
  list(k = k, sigma = sigma)
}

#' Importance-weight diagnostics from LOG weights (any additive constant)
#' @param lw log importance weights, log p(theta) - log q(theta); non-finite = a failed draw (weight 0)
#' @return list(S, n_failed, ess, ess_frac, max_w, k_hat, k_ok_below, k_ok, w = normalised weights)
ccx_is_diagnostics <- function(lw) {
  S <- length(lw); ok <- is.finite(lw)
  lwo <- lw[ok] - max(lw[ok])
  w <- numeric(S); w[ok] <- exp(lwo); w <- w / sum(w)
  ess <- 1 / sum(w^2)
  # the PSIS tail: the largest M = ceil(min(0.2 S, 3 sqrt(S))) weights, as exceedances over the next one
  So <- length(lwo); M <- ceiling(min(0.2 * So, 3 * sqrt(So)))
  srt <- sort(lwo)
  cutoff <- srt[So - M]; tail <- srt[(So - M + 1):So]
  exc <- exp(tail) - exp(cutoff)
  # a tail with fewer than 5 distinct exceedances is DEGENERATE: a handful of draws carry the weight, and no
  # tail shape can be fitted -- that is the failure, so it reads as k-hat = Inf, never as an error or a pass.
  # (All-zero exceedances = equal top weights = no tail at all: -Inf, a pass.)
  k_hat <- if (all(exc <= 0)) -Inf else if (sum(exc > 0) < 5L) Inf else ccx_gpdfit(exc[exc > 0])$k
  k_lim <- min(1 - 1 / log10(S), 0.7)
  list(S = S, n_failed = sum(!ok), ess = ess, ess_frac = ess / S, max_w = max(w),
       k_hat = k_hat, k_ok_below = k_lim, k_ok = isTRUE(k_hat < k_lim), w = w)
}

#' Weighted quantiles (the weights need not sum to 1)
ccx_wquantile <- function(x, w, probs) {
  o <- order(x); x <- x[o]; w <- w[o] / sum(w)
  cw <- cumsum(w) - w / 2                         # mid-point rule
  stats::approx(cw, x, xout = probs, rule = 2, ties = "ordered")$y
}
