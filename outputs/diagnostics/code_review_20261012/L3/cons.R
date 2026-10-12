source("/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/fa6620c3-fcfb-49a4-a787-90d23c00188e/scratchpad/review/L3/load.R")
S <- "/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/fa6620c3-fcfb-49a4-a787-90d23c00188e/scratchpad/review/L3"
x <- readRDS(file.path(S, "spinF.rds")); sp <- x$sp; F <- x$F; p <- sp$params
F0 <- F; F0$e_foss_NH[] <- 0; F0$e_foss_SH[] <- 0          # the only external carbon source; LUC, ndep, sink_ocean are internal transfers
r <- ccx_run_fast(sp, F0)
for (tr in c("C", "C13")) cat(sprintf("C++ 1750-2024, no fossil: %s rel drift %.2e (abs %.2e)\n", tr,
    (sum(r$state[, tr]) - sum(sp$y[, tr])) / sum(sp$y[, tr]), sum(r$state[, tr]) - sum(sp$y[, tr])))
cat("max sink_ocean in F:", max(abs(F$sink_ocean)), " ndep max:", max(F$ndep_NH), " retried:", r$retried, "\n")
# inert box constant?
ii <- grep("soil_inert", rownames(r$state)); cat("inert C drift:", max(abs(r$state[ii, ] - sp$y[ii, ])), "\n")
