for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
D <- "outputs/mcmc_check_20261014_hilda31w_200k"
S <- lapply(1:4, function(k) readRDS(file.path(D, sprintf("chain_%d.rds", k))))
specs <- c(CCX_PARAM_TABLE, CCX_PARAM_GATED_ALL)
nm <- colnames(S[[1]]$samples)
dec <- function(x, n) { s <- specs[[n]]; if (is.null(s)) return(x); .from_unc(x, s) }
show <- c("seas_T_lag","seas_lag_p_NH","seas_lag_p_SH","h_ml","beta_max","npp_frac_NH","q10","fert_k")
md <- readRDS(ccx_mode_file(CCX_MODE_CANONICAL))
for (n in show) {
  cat(sprintf("\n%s (mode %.3f)  median by quarter of kept samples [q05,q95 overall]\n", n, if (!is.null(md$par_mode[[n]])) md$par_mode[[n]][1] else NA))
  for (k in 1:4) {
    v <- dec(S[[k]]$samples[, n], n); q <- split(v, rep(1:4, each = length(v)/4))
    cat(sprintf("  chain %d: %s   [%.3f, %.3f]\n", k, paste(sprintf("%7.3f", sapply(q, median)), collapse=" "), quantile(v,.05), quantile(v,.95)))
  }
}
# correlations among the lag triplet, pooled, natural units
X <- do.call(rbind, lapply(S, function(s) sapply(c("seas_T_lag","seas_lag_p_NH","seas_lag_p_SH"), function(n) dec(s$samples[, n], n))))
cat("\npooled correlation (natural units):\n"); print(round(cor(X), 3))
cat("\nfraction of pooled seas_T_lag below 0.25 / 0.5 months:", mean(X[,1] < .25), mean(X[,1] < .5), "\n")
cat("differences NH-T, SH-T pooled quantiles:\n"); print(round(quantile(X[,2]-X[,1], c(.05,.5,.95)),3)); print(round(quantile(X[,3]-X[,1], c(.05,.5,.95)),3))
