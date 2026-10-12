source("/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/fa6620c3-fcfb-49a4-a787-90d23c00188e/scratchpad/review/L3/load.R")
S <- "/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/fa6620c3-fcfb-49a4-a787-90d23c00188e/scratchpad/review/L3"
o <- readRDS(file.path(S, "par1_out.rds")); rC <- o$rC; rR <- o$rR
cat("deep_C_NH range C++:", range(rC$out$deep_C_NH), " R:", range(rR$out$deep_C_NH), "\n")
cat("deep_C_NH first/last diff:", diff(range(rC$out$deep_C_NH)), "\n")
x <- readRDS(file.path(S, "s2.rds")); s2 <- x$s2; Fb <- x$Fb
invisible(withCallingHandlers(ccx_run(s2, Fb[1:30, ]), warning = function(w) { cat("WARN:", conditionMessage(w), "\n"); invokeRestart("muffleWarning") }))
