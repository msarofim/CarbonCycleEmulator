rb <- readRDS(commandArgs(TRUE)[1])
K <- rb$key_draws; K$grp <- ifelse(K$draw <= 200, "excursion", "main")
cat(sprintf("draws ok %d of %d\n", rb$provenance$n_ok, rb$provenance$n_draws))
q <- function(x) quantile(x, c(.05, .5, .95), names = FALSE)
cells <- unique(K[, c("scenario", "var", "year")])
out <- do.call(rbind, lapply(seq_len(nrow(cells)), function(i) {
  c0 <- cells[i, ]; s <- K[K$scenario == c0$scenario & K$var == c0$var & K$year == c0$year, ]
  e <- q(s$value[s$grp == "excursion"]); m <- q(s$value[s$grp == "main"])
  data.frame(c0, main_q05 = m[1], main_q50 = m[2], main_q95 = m[3], main_w = m[3] - m[1],
             ex_q50 = e[2], ex_w = e[3] - e[1], dmed = e[2] - m[2], dmed_over_w = (e[2] - m[2]) / (m[3] - m[1]))
}))
out <- out[order(-abs(out$dmed_over_w)), ]
print(head(out, 14), row.names = FALSE, digits = 4)
cat("\n|median shift| / main 5-95 width, by var:\n"); print(tapply(abs(out$dmed_over_w), out$var, function(x) round(c(median = median(x), max = max(x)), 3)))
