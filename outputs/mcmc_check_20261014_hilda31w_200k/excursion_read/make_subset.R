D <- "outputs/mcmc_check_20261014_hilda31w_200k"
S <- lapply(1:4, function(k) readRDS(file.path(D, sprintf("chain_%d.rds", k))))
pick <- function(n, m) unique(round(seq(1, n, length.out = m)))
ex <- S[[4]]$samples[S[[4]]$samples_iter > 50000 & S[[4]]$samples_iter <= 115000, ]
mn <- do.call(rbind, lapply(S[1:3], `[[`, "samples"))
A <- ex[pick(nrow(ex), 200), ]; B <- mn[pick(nrow(mn), 200), ]
U <- rbind(A, B); stopifnot(nrow(U) == 400)
saveRDS(U, commandArgs(TRUE)[1])
cat("excursion pool", nrow(ex), "-> 200; main pool", nrow(mn), "-> 200\n")
