# =====================================================================
# T-hml follow-up 2 (2026-09-08g): WHICH likelihood row carries the h_ml
# feature at 49.9-51.2 m? Neither the pump shape nor the substep count does
# (diag_thml_kink_source.R). Per-stream log-likelihood along the same fine
# grid, second-differenced; the row(s) whose d2 spikes name the path.
# Usage: Rscript calibration/diag_thml_kink_rows.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))
TK_HALF <- 4; TK_STEP <- 0.25; TK_RATIO <- 3
TK_OUT <- ccx_path("outputs", "diagnostics", sprintf("thml_kink_rows_%s.rds", format(Sys.Date(), "%Y%m%d")))
v <- dg_vector(CCX_MODE_CANONICAL); h0 <- v$p$h_ml
fine <- h0 + seq(-TK_HALF, TK_HALF, by = TK_STEP)
ST <- t(vapply(fine, function(h) { va <- v; va$p$h_ml <- h; unlist(dg_streams(dg_run(va), va)) }, numeric(length(unlist(dg_streams(dg_run(v), v))))))
tot <- rowSums(ST)
d2 <- function(x) diff(x, differences = 2) / TK_STEP^2
D2 <- apply(ST, 2, d2); d2tot <- d2(tot)
mid <- fine[-c(1, length(fine))]
cat(sprintf("total likelihood (dg rows) d2 along the grid; spike = |d2| > %g x median:\n", TK_RATIO))
sp_tot <- abs(d2tot) > TK_RATIO * stats::median(abs(d2tot))
for (k in seq_along(mid)) cat(sprintf("  h_ml %6.2f  lik %+9.4f  d2 %+8.4f%s\n", mid[k], tot[k + 1] - tot[which.min(abs(fine - h0))], d2tot[k], if (sp_tot[k]) "  <-- SPIKE" else ""))
cat("\n=== per-stream: the excursion of d2 inside the feature window (49.5-51.5 m) vs its median outside ===\n")
win <- mid > 49.5 & mid < 51.5
sc <- sort(vapply(colnames(D2), function(n) { x <- D2[, n]; (max(abs(x[win])) / max(stats::median(abs(x[!win])), 1e-6)) }, numeric(1)), decreasing = TRUE)
for (n in names(sc)) cat(sprintf("  %-22s max|d2| in window %8.4f  median|d2| outside %8.4f  ratio %7.1f  (row at mode %+.2f)\n", n, max(abs(D2[win, n])), stats::median(abs(D2[!win, n])), sc[[n]], ST[which.min(abs(fine - h0)), n]))
cat("\n=== the top three rows along the grid (value minus the row's value at the mode) ===\n")
top <- names(sc)[1:3]; cat(sprintf("  %7s", "h_ml")); for (n in top) cat(sprintf(" %22s", n)); cat("\n")
for (k in seq_along(fine)) { cat(sprintf("  %7.2f", fine[k])); for (n in top) cat(sprintf(" %+22.4f", ST[k, n] - ST[which.min(abs(fine - h0)), n])); cat("\n") }
saveRDS(list(fine = fine, streams = ST, D2 = D2, score = sc, date = Sys.time()), TK_OUT)
cat(sprintf("saved %s\n⛔ Nothing adopted.\n", TK_OUT))
