for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
D <- "outputs/mcmc_check_20261014_hilda31w_200k"
specs <- c(CCX_PARAM_TABLE, CCX_PARAM_GATED_ALL)
dec <- function(x, n) .from_unc(x, specs[[n]])
for (k in 1:4) {
  s <- readRDS(file.path(D, sprintf("chain_%d.rds", k)))
  T <- dec(s$samples[, "seas_T_lag"], "seas_T_lag"); H <- dec(s$samples[, "h_ml"], "h_ml")
  it <- s$samples_iter
  blk <- cut(it, seq(30000, 200000, by = 10000))
  cat(sprintf("\nchain %d: 10k-iteration blocks  [frac T_lag>1 | median T_lag | median h_ml | median lp]\n", k))
  a <- tapply(T > 1, blk, mean); b <- tapply(T, blk, median); h <- tapply(H, blk, median); l <- tapply(s$samples_lp, blk, median)
  print(round(data.frame(fracT_gt1 = a, T_lag = b, h_ml = h, lp = l), 2))
  cat(sprintf("  fraction of kept samples with T_lag > 1: %.3f; > 2: %.3f; lp median when T>1: %.2f, when T<0.5: %.2f\n",
      mean(T > 1), mean(T > 2), median(s$samples_lp[T > 1]), median(s$samples_lp[T < .5])))
}
