source("/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/fa6620c3-fcfb-49a4-a787-90d23c00188e/scratchpad/review/L2/setup.R")
z <- readRDS(file.path(SCR, "spin_F.rds")); sp <- z$sp
w <- readRDS(file.path(SCR, "y98.rds")); y <- w$y98; F <- w$F; pp <- w$pp
aux <- sp$aux; grid <- sp$grid
sub <- ccx_resolve_substeps("auto", pp, grid)
idx <- which(F$t >= 1998 & F$t < 2025)
acc <- NULL
for (j in seq_along(idx)) {
  i <- idx[j]; fi <- ccx_forcing_at(F, i)
  k1 <- ccx_deriv(y, F$t[i], pp, fi, grid, aux, record = TRUE)
  fl <- attr(k1, "fluxes"); attr(k1, "fluxes") <- NULL
  if (floor(F$t[i]) == 2024) {
    v <- c(ccx_flux_derive(fl$channels, y, aux), ccx_flux_hs_derive(fl$edges, fl$pump_edges, aux))
    acc <- if (is.null(acc)) v else acc + v
  }
  y <- ccx_step_rk4(y, F$t[i], 1/12, pp, fi, grid, aux, sub, k1 = k1)
}
acc <- acc / 12
print(round(acc[c("as_down","as_up","ml_int","pump","hs_as_down","hs_as_up","hs_pump","hs_hd_net","hd_int_net","ocean_net")], 3))
cat("warm arrow (app) ml_int+pump:", round(acc[["ml_int"]] + acc[["pump"]], 3), "  minus hs_hd_net:", round(acc[["ml_int"]] + acc[["pump"]] - acc[["hs_hd_net"]], 3), "\n")
cat("warm air-sea net (app):", round((acc[["as_down"]]-acc[["hs_as_down"]]) - (acc[["as_up"]]-acc[["hs_as_up"]]), 3), "\n")
