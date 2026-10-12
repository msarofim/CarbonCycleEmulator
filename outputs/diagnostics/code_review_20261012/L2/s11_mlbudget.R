source("/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/fa6620c3-fcfb-49a4-a787-90d23c00188e/scratchpad/review/L2/setup.R")
z <- readRDS(file.path(SCR, "spin_F.rds")); sp <- z$sp
w <- readRDS(file.path(SCR, "y98.rds")); y <- w$y98; F <- w$F; pp <- w$pp
aux <- sp$aux; grid <- sp$grid
sub <- ccx_resolve_substeps("auto", pp, grid)
idx <- which(F$t >= 1998 & F$t < 2025)
iml <- c(aux$idx$NH$ml, aux$idx$SH$ml); ihs <- c(aux$idx$NH$hs, aux$idx$SH$hs)
dml <- 0; n <- 0; ml0 <- NA
for (j in seq_along(idx)) {
  i <- idx[j]; fi <- ccx_forcing_at(F, i)
  if (F$t[i] >= 2024 && is.na(ml0)) ml0 <- sum(y[iml, "C"])
  k1 <- ccx_deriv(y, F$t[i], pp, fi, grid, aux)
  if (floor(F$t[i]) == 2024) { dml <- dml + sum(k1[iml, "C"]); n <- n + 1 }
  y <- ccx_step_rk4(y, F$t[i], 1/12, pp, fi, grid, aux, sub, k1 = k1)
}
cat("2024 mean dML/dt (opening-state):", dml / n, "  actual ML change over 2024:", sum(y[iml, "C"]) - ml0, "\n")
