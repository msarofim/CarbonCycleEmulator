suppressMessages({for (f in list.files("R", pattern="\\.R$", full.names=TRUE)) source(f)})
v <- readRDS(Sys.getenv("VFILE")); p <- v$p
# (1) late-start forcing: SST seam
F <- suppressWarnings(ccx_build_forcing("ssp245", c(2030, 2040), prod_c14 = 1, enso_index = ccx_enso_index_of(p), aod_mode = ccx_aod_mode_of(p)))
cat("late-start (2030-2040) sst_anom_NH first/last:", F$sst_anom_NH[1], tail(F$sst_anom_NH,1), " anyNA:", anyNA(F$sst_anom_NH), "\n")
F2 <- suppressWarnings(ccx_build_forcing("ssp245", c(2020, 2040), prod_c14 = 1, enso_index = ccx_enso_index_of(p), aod_mode = ccx_aod_mode_of(p)))
F3 <- suppressWarnings(ccx_build_forcing("ssp245", c(1750, 2040), prod_c14 = 1, enso_index = ccx_enso_index_of(p), aod_mode = ccx_aod_mode_of(p)))
k2 <- F2$year == 2035; k3 <- F3$year == 2035
cat("2035 sst_NH: start-2020 build", round(mean(F2$sst_anom_NH[k2]),4), " start-1750 build", round(mean(F3$sst_anom_NH[k3]),4), " (same gmst? ", all.equal(F2$gmst[k2], F3$gmst[k3]), ")\n")
# (3) LUC zero crossings by scenario
for (sc in ccx_climate_scenarios()) {
  e <- tryCatch(ccx_scenario_emissions(sc), error = function(e) NULL); if (is.null(e)) next
  yy <- min(e$year):2300; l <- approx(e$year, e$luc_GtC, yy, rule = 2)$y
  nx <- sum(diff(sign(l)) != 0)
  if (nx) cat(sc, ": LUC sign changes", nx, " near years", paste(yy[which(diff(sign(l)) != 0)], collapse=","), "\n")
}
