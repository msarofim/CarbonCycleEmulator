# interim per-chain look at the hilda31fl chains (scratch, read-only on copies)
S <- commandArgs(TRUE)[1]
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
md <- readRDS(ccx_mode_file(CCX_MODE_CANONICAL))
invisible(ccx_apply_gate(ccx_mode_struct(md))); invisible(ccx_apply_pins(ccx_mode_pins(md)))
invisible(ccx_adopt_mode_band(md))
nm <- c("h_ml", "seas_T_lag", "seas_lag_p_NH", "seas_lag_p_SH", "beta_max", "fert_k", "ndep_ret", "luc_scale")
cat("mode:", paste(sprintf("%s=%.4g", nm, unlist(md$par_mode[nm])), collapse = "  "), "\n")
for (k in 1:4) {
  x <- readRDS(file.path(S, sprintf("chain_%d.rds", k)))
  P <- do.call(rbind, lapply(seq_len(nrow(x$samples)), function(i) unlist(ccx_unc_to_par(x$samples[i, ]))))
  cat(sprintf("\nchain %d, %d kept (iter %d-%d)\n", k, nrow(P), min(x$samples_iter), max(x$samples_iter)))
  # split the window in thirds to see drift
  g <- cut(seq_len(nrow(P)), 3, labels = c("1st", "2nd", "3rd"))
  for (n in nm) {
    q <- quantile(P[, n], c(.05, .5, .95))
    th <- tapply(P[, n], g, median)
    cat(sprintf("  %-14s 5/50/95 %8.4g %8.4g %8.4g | median by third %8.4g %8.4g %8.4g\n", n, q[1], q[2], q[3], th[1], th[2], th[3]))
  }
}
