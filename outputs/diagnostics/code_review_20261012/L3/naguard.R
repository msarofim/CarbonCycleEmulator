source("/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/fa6620c3-fcfb-49a4-a787-90d23c00188e/scratchpad/review/L3/load.R")
S <- "/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/fa6620c3-fcfb-49a4-a787-90d23c00188e/scratchpad/review/L3"
x <- readRDS(file.path(S, "s2.rds")); s2 <- x$s2; Fb <- x$Fb[1:24, ]
Fz <- Fb; Fz$e_foss_NH[24] <- NaN            # a non-finite value reaching the core in the FINAL month only
r <- ccx_run_fast(s2, Fz)
cat("anyNA(out):", anyNA(r$out[, ccx_out_na_guard_cols(r$out, s2$params)]), " anyNA(state):", anyNA(r$state),
    " anyNA(npp):", anyNA(r$npp), " retried:", r$retried, " substeps:", r$substeps, "\n")
Fz2 <- Fb; Fz2$e_foss_NH[23] <- NaN
r2 <- ccx_run_fast(s2, Fz2)
cat("NaN in month 23 -> retried:", r2$retried, " substeps:", r2$substeps, " anyNA(state):", anyNA(r2$state), "\n")
