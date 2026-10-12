suppressMessages({for (f in list.files("R", pattern="\\.R$", full.names=TRUE)) source(f)})
v <- readRDS(Sys.getenv("VFILE")); p <- v$p
w <- character()
F <- withCallingHandlers(ccx_build_forcing("historical", c(1750, 2060), prod_c14 = 1, enso_index = ccx_enso_index_of(p), aod_mode = ccx_aod_mode_of(p)),
  warning = function(x) { w <<- c(w, conditionMessage(x)); invokeRestart("muffleWarning") })
cat("warnings:\n"); cat(paste0(" - ", substr(w, 1, 110)), sep = "\n")
cat("fossil 2024 / 2040 / 2060 annual:", sapply(c(2024, 2040, 2060), function(y) round(mean(F$e_foss_NH[F$year==y] + F$e_foss_SH[F$year==y]),3)), "\n")
nuc <- ccx_nuclear_c14_annual(); cat("nuclear 14C years:", range(nuc$year), " last-year mol/yr:", tail(nuc$mol_per_yr,1), " F c14_nuclear 2030:", mean(F$c14_nuclear[F$year==2030]), "\n")
cat("ndep source:", attr(F, "ndep_source"), "\n")
