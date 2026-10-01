# =====================================================================
# lib_mcmc_diag.R -- convergence diagnostics for the MCMC check's chains
# (calibration/run_mcmc_check.R), read by calibration/read_mcmc_check.R.
#
# Rank-normalised split-R-hat, bulk-ESS and tail-ESS as DEFINED by Vehtari,
# Gelman, Simpson, Carpenter & Buerkner (2021), "Rank-normalization, folding, and
# localization: an improved R-hat for assessing convergence of MCMC", Bayesian
# Analysis 16(2):667-718, doi:10.1214/20-BA1221: split-R-hat on rank-normalised
# draws (Sec. 4.1, eq. 14), its folded version for the tails, the multi-chain
# autocorrelation (eq. 10) and Geyer's initial monotone sequence (Sec. 3.2).
#
# ⚠ WRITTEN FROM THE PAPER, NOT CALLED FROM A PACKAGE: `posterior`, which
# implements these, is not installed (2026-10-01; `coda` is, but its gelman.diag
# is the classic unsplit PSRF and its effectiveSize is a spectral estimate). So
# they are validated against KNOWN answers, not against another implementation
# (tests/testthat/test-mcmc-diag.R): AR(1) chains, whose ESS is N(1-phi)/(1+phi)
# exactly; planted between-chain shifts, scale differences and trends; and a
# direct (non-FFT) autocovariance.
#
# Input everywhere: an iterations x chains matrix of ONE scalar quantity.
# =====================================================================

MCD_RANK_OFFSET <- 3 / 8          # Blom's offset in the rank -> normal-score map (eq. 14)
MCD_TAIL_PROBS  <- c(0.05, 0.95)  # tail-ESS: the ESS of the 5 % and 95 % quantile indicators

# Each chain's first and second halves become two chains. With an odd length the
# middle draw is dropped, so both halves have the same length.
mcd_split <- function(x) {
  x <- as.matrix(x); n <- nrow(x); h <- n %/% 2
  cbind(x[seq_len(h), , drop = FALSE], x[(n - h + 1L):n, , drop = FALSE])
}

# Rank-normalise the POOLED draws, keeping the iterations x chains shape (eq. 14).
mcd_z <- function(x) {
  r <- rank(x, ties.method = "average")
  matrix(stats::qnorm((r - MCD_RANK_OFFSET) / (length(r) - 2 * MCD_RANK_OFFSET + 1)),
         nrow(x), ncol(x))
}

# Classic R-hat on the chains exactly as given (the callers split first).
mcd_rhat_basic <- function(x) {
  n <- nrow(x)
  W <- mean(apply(x, 2, stats::var))
  B <- n * stats::var(colMeans(x))
  sqrt(((n - 1) / n * W + B / n) / W)
}

# Rank-normalised split-R-hat: the larger of the bulk version and the FOLDED one,
# |x - median|, which sees chains that agree in location but not in scale.
mcd_rhat <- function(x) {
  x <- as.matrix(x)
  bulk <- mcd_rhat_basic(mcd_z(mcd_split(x)))
  tail <- mcd_rhat_basic(mcd_z(mcd_split(abs(x - stats::median(x)))))
  max(bulk, tail)
}

# Biased autocovariance (divisor n, as Geyer 1992 recommends), lags 0..n-1, by FFT.
# Zero-padding to >= 2n removes the circular wrap.
mcd_acov <- function(y) {
  n <- length(y); L <- 2^ceiling(log2(2 * n))
  f <- stats::fft(c(y - mean(y), numeric(L - n)))
  Re(stats::fft(Conj(f) * f, inverse = TRUE))[seq_len(n)] / (L * n)
}

# eq. 10's combined autocorrelation, cut by Geyer's initial positive sequence and
# then made MONOTONE: rho[t + 1] holds lag t, and lags >= max_t are unused except
# rho[max_t + 1], the improved estimate's tail term. rho_raw is the sequence BEFORE
# the monotone step, returned so a test can show the step had something to do.
mcd_rho_geyer <- function(x) {
  x <- as.matrix(x); n <- nrow(x); m <- ncol(x)
  ac <- matrix(vapply(seq_len(m), function(j) mcd_acov(x[, j]), numeric(n)), n, m)
  W  <- mean(ac[1, ]) * n / (n - 1)
  vp <- W * (n - 1) / n + (if (m > 1L) stats::var(colMeans(x)) else 0)
  rho_at <- function(t) 1 - (W - mean(ac[t + 1L, ])) / vp     # lag t
  rho <- numeric(n)                                            # rho[t + 1] holds lag t
  t <- 0L; rho_even <- 1; rho_odd <- rho_at(1L)
  rho[1] <- rho_even; rho[2] <- rho_odd
  while (t < n - 5L && !is.nan(rho_even + rho_odd) && rho_even + rho_odd > 0) {
    t <- t + 2L
    rho_even <- rho_at(t); rho_odd <- rho_at(t + 1L)
    if (rho_even + rho_odd >= 0) { rho[t + 1L] <- rho_even; rho[t + 2L] <- rho_odd }
  }
  max_t <- t
  if (rho_even > 0) rho[max_t + 1L] <- rho_even
  rho_raw <- rho
  t <- 0L                                                      # initial MONOTONE sequence
  while (t <= max_t - 4L) {
    t <- t + 2L
    if (rho[t + 1L] + rho[t + 2L] > rho[t - 1L] + rho[t]) {
      rho[t + 1L] <- (rho[t - 1L] + rho[t]) / 2
      rho[t + 2L] <- rho[t + 1L]
    }
  }
  list(rho = rho, rho_raw = rho_raw, max_t = max_t)
}

# Multi-chain ESS of the chains as given, from mcd_rho_geyer() with the paper's two
# guards (the improved tail term, and tau floored at 1/log10(S)).
mcd_ess_basic <- function(x) {
  x <- as.matrix(x)
  v <- stats::var(as.vector(x))
  if (nrow(x) < 4L || !is.finite(v) || v == 0) return(NA_real_)
  g <- mcd_rho_geyer(x)
  S <- length(x)
  tau <- -1 + 2 * sum(g$rho[seq_len(g$max_t)]) + g$rho[g$max_t + 1L]
  S / max(tau, 1 / log10(S))
}

# Bulk-ESS: the ESS of the rank-normalised split chains.
mcd_ess_bulk <- function(x) mcd_ess_basic(mcd_z(mcd_split(as.matrix(x))))

# Tail-ESS: the smaller ESS of the two tail-quantile indicators.
mcd_ess_tail <- function(x) {
  x <- as.matrix(x)
  min(vapply(MCD_TAIL_PROBS, function(p) {
    q <- stats::quantile(x, p, names = FALSE)
    mcd_ess_basic(mcd_split(matrix(as.numeric(x <= q), nrow(x), ncol(x))))
  }, numeric(1)))
}

# One row per quantity: the three diagnostics plus each chain's mean, for a table.
mcd_summary <- function(x, name) {
  x <- as.matrix(x)
  data.frame(name = name, rhat = mcd_rhat(x), ess_bulk = mcd_ess_bulk(x),
             ess_tail = mcd_ess_tail(x), mean = mean(x), sd = stats::sd(as.vector(x)),
             chain_means = paste(sprintf("%.4g", colMeans(x)), collapse = " "),
             stringsAsFactors = FALSE)
}
