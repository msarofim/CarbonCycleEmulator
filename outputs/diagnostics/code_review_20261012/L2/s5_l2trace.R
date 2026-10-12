source("/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/fa6620c3-fcfb-49a4-a787-90d23c00188e/scratchpad/review/L2/setup.R")
z <- readRDS(file.path(SCR, "spin_F.rds")); sp <- z$sp
w <- readRDS(file.path(SCR, "y98.rds")); y <- w$y98; F <- w$F; pp <- w$pp
aux <- sp$aux; grid <- sp$grid
sub <- ccx_resolve_substeps("auto", pp, grid)
idx <- which(F$t >= 1998 & F$t < 2025)
res <- data.frame(t = F$t[idx], l2_ml_to_int = NA, ml_int = NA, pump = NA, miss_ml = NA)
iml <- c(aux$idx$NH$ml, aux$idx$SH$ml)
for (j in seq_along(idx)) {
  i <- idx[j]; fi <- ccx_forcing_at(F, i)
  k1 <- ccx_deriv(y, F$t[i], pp, fi, grid, aux, record = TRUE)
  fl <- attr(k1, "fluxes"); attr(k1, "fluxes") <- NULL
  # the missing flux: boxnet vs dC at the two ML boxes (positive = dC more than recorded = net inflow from L2)
  miss <- k1[iml, "C"] - fl$boxnet[iml]
  res$miss_ml[j] <- sum(miss)
  res$l2_ml_to_int[j] <- -sum(miss)
  res$ml_int[j] <- fl$channels[["ml_int"]]; res$pump[j] <- fl$channels[["pump"]]
  y <- ccx_step_rk4(y, F$t[i], 1/12, pp, fi, grid, aux, sub, k1 = k1)
}
a <- aggregate(res[-1], by = list(year = floor(res$t)), FUN = mean)
a$arrow <- a$ml_int + a$pump
a$arrow_true <- a$arrow + a$l2_ml_to_int
print(round(a, 3))
saveRDS(a, file.path(SCR, "l2_annual.rds"))
