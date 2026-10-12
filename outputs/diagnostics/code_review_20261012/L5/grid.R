setwd("/Users/MarcusMarcus/Documents/2026/CodeProjects/CarbonCycleEmulator")
for (f in list.files("R", pattern="\\.R$", full.names=TRUE)) source(f)
lm <- ccx_load_mode(); p <- lm$p
aux <- ccx_prepare(p); g <- aux$grid
cat("h_ml", p$h_ml, " nl", g$nl, "\n"); edges <- c(0, cumsum(g$dz)); print(round(edges, 1))
cat("bottom box:", round(edges[length(edges)-1],1), "-", round(edges[length(edges)],1), " bottom-3:", round(edges[length(edges)-3],1), "-", round(edges[length(edges)],1), "\n")
sp <- ccx_periodic_spinup(p); invisible(capture.output(ccx_report_spinup(sp))) ; ccx_report_spinup(sp)
