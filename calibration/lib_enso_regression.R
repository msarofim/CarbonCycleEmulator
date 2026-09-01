# =====================================================================
# lib_enso_regression.R -- the ENSO-vs-sink regression, in ONE place.
#
# Extracted 2026-09-01 when the model-side comparison needed the identical
# estimator the observation-side power test uses. Two copies of a regression is
# two chances for the detrending order, the lag convention or the effective
# sample size to drift apart while both files keep printing "slope".
#
# ⛔ SOURCE THIS, DO NOT RUN IT.
#
# THE CONVENTIONS, fixed here so every caller shares them:
#   * INDEX: Nino3.4 anomaly (the longer series; `mei` is NA before 1979 and is
#     used only as a robustness check).
#   * LAG: a lag of L months means the annual mean of the index over the 12
#     months ENDING L months before the year's end -- the sink TRAILS the index.
#   * DETRENDING: a polynomial in year, order ER_DEG, removing the secular trend
#     the sinks carry because they grow with atmospheric CO2.
#   * n_eff: Bartlett/Quenouille. Both series are autocorrelated -- the detrended
#     GCB ocean sink has lag-1 ~0.6 -- so the naive CI on r is far too tight.
# =====================================================================

ER_INDEX <- "nino34_anom"
ER_ALT   <- "mei"
ER_LAGS  <- 0:12
ER_DEGS  <- 1:3
ER_DEG   <- 2
ER_ALPHA <- 0.05
ER_POWER <- 0.80

#' The ENSO index averaged onto a set of years, at a lag in months
er_index_annual <- function(years, col = ER_INDEX, lag_m = 0) {
  e <- as.data.frame(readRDS(ccx_path("data", "forcing_enso.rds")))
  t <- e$year + (e$month - 0.5) / 12
  v <- e[[col]]; ok <- is.finite(v)
  vapply(years, function(y) {
    hi <- (y + 1) - lag_m / 12
    k <- ok & t > hi - 1 & t <= hi
    if (sum(k) < 6) NA_real_ else mean(v[k])
  }, numeric(1))
}

er_detrend <- function(x, years, deg = ER_DEG) residuals(lm(x ~ poly(years, deg)))
er_ac1 <- function(x) { x <- x[is.finite(x)]; cor(x[-1], x[-length(x)]) }

#' Correlation and slope with an EFFECTIVE sample size
er_cor <- function(x, y) {
  k <- is.finite(x) & is.finite(y); x <- x[k]; y <- y[k]; n <- length(x)
  r <- cor(x, y)
  rr <- er_ac1(x) * er_ac1(y)
  n_eff <- max(3, n * (1 - rr) / (1 + rr))
  z <- atanh(r); se <- 1 / sqrt(n_eff - 3)
  ci <- tanh(z + c(-1, 1) * qnorm(1 - ER_ALPHA / 2) * se)
  list(r = r, n = n, n_eff = n_eff, ci = ci,
       p = 2 * (1 - pnorm(abs(z) / se)),
       slope = coef(lm(y ~ x))[[2]], sd_y = sd(y), sd_x = sd(x))
}

#' The smallest |slope| this series could resolve at ER_POWER
er_min_slope <- function(cc) {
  r_min <- tanh((qnorm(1 - ER_ALPHA / 2) + qnorm(ER_POWER)) / sqrt(cc$n_eff - 3))
  r_min * cc$sd_y / cc$sd_x
}

#' Scan ER_LAGS and return the strongest, plus how many lags are significant
er_best_lag <- function(years, y, col = ER_INDEX) {
  best <- NULL; nsig <- 0L
  for (L in ER_LAGS) {
    cc <- er_cor(er_index_annual(years, col, L), y)
    if (cc$ci[1] * cc$ci[2] > 0) nsig <- nsig + 1L
    if (is.null(best) || abs(cc$r) > abs(best$r)) { best <- cc; best$lag <- L }
  }
  best$nsig <- nsig; best$nlag <- length(ER_LAGS); best
}
