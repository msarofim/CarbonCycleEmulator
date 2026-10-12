setwd("/Users/MarcusMarcus/Documents/2026/CodeProjects/CarbonCycleEmulator")
for (f in list.files("R", pattern="\\.R$", full.names=TRUE)) source(f)
F <- suppressWarnings(ccx_build_forcing("historical"))
for (h in HEMIS) { v <- F[[paste0("sst_anom_", h)]]; cat(h, "sst_anom range", range(v, na.rm=TRUE), " months < 0:", sum(v < 0, na.rm=TRUE), "of", length(v), "; first negative t", F$t[which(v<0)[1]], "\n") }
cat("HS SST min (2 + anom):", 2 + min(F$sst_anom_NH, F$sst_anom_SH, na.rm=TRUE), "\n")
cat("carb t_range:", carb_coefs()$t_range, "\n")
