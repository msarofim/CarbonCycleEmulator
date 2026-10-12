suppressMessages({for (f in list.files("R", pattern="\\.R$", full.names=TRUE)) source(f)})
v <- readRDS(Sys.getenv("VFILE")); p <- v$p
F <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = 1, enso_index = ccx_enso_index_of(p), aod_mode = ccx_aod_mode_of(p))
fr <- if (is.null(p$hs_sst_anom_frac)) 1 else p$hs_sst_anom_frac
T <- p$sst_hs + fr * F$sst_anom_SH
cat("hs_sst_anom_frac", fr, " sst_hs", p$sst_hs, " months below 2 C:", sum(T < 2), "of", length(T), " min T", min(T), " year of min:", F$year[which.min(T)], "\n")
k <- withCallingHandlers(carb_constants(min(T)), warning = function(w) { cat("WARN:", conditionMessage(w), "\n"); invokeRestart("muffleWarning") })
cat("aux sst_hs used:", ccx_prepare(p)$sst_hs, "\n")
