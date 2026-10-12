setwd("/Users/MarcusMarcus/Documents/2026/CodeProjects/CarbonCycleEmulator")
for (f in list.files("R", pattern="\\.R$", full.names=TRUE)) source(f)
sc <- readRDS(ccx_path("data", "obs_seasonal_clim.rds"))
wk <- sprintf("%%s_%d-%d", sc$sst_window[1], sc$sst_window[2])
for (h in HEMIS) { o <- sc$ocean[[sprintf(wk, h)]]; cat(h, "peak_month", o$peak_month, " model_lag", o$model_lag, " half_amp", o$half_amp, "\n") }
cat("CCX_SST_SEAS_LAG", CCX_SST_SEAS_LAG, "; LIK_SEAS_WINDOW", if (exists("LIK_SEAS_WINDOW")) LIK_SEAS_WINDOW else NA, "; sst_window", sc$sst_window, "\n")
# SH: the model applies sigma=-1 flip to the same lag; what lag would the SH obs want?
o <- sc$ocean[[sprintf(wk, "SH")]]; cat("SH obs lag in flipped convention (peak - 6 months):", ((o$peak_month - 6 - 3) - 3.5) %% 12, "\n")
