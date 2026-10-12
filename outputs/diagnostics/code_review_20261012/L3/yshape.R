source("/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/fa6620c3-fcfb-49a4-a787-90d23c00188e/scratchpad/review/L3/load.R")
S <- "/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/fa6620c3-fcfb-49a4-a787-90d23c00188e/scratchpad/review/L3"
x <- readRDS(file.path(S, "s2.rds")); s2 <- x$s2; Fb <- x$Fb[1:12, ]
cat("NB =", nrow(s2$y), "\n")
s3 <- s2; s3$y <- rbind(s2$y, extra1 = c(1, 1, 1), extra2 = c(1, 1, 1))   # two rows too many: no OOB read, misaligned columns
r <- tryCatch(ccx_run_fast(s3, Fb), error = function(e) e)
if (inherits(r, "error")) cat("ccx_run_fast ERROR:", conditionMessage(r), "\n") else
  cat("ccx_run_fast ran silently; co2_NH[1] =", r$out$co2_NH[1], " d13c_NH[1] =", r$out$d13c_NH[1], " (correct:", ccx_run_fast(s2, Fb)$out$d13c_NH[1], ")\n")
rr <- tryCatch(ccx_run(s3, Fb[1:2, ]), error = function(e) e)
cat("ccx_run (R):", if (inherits(rr, "error")) paste("ERROR:", conditionMessage(rr)) else paste("ran; d13c_NH[1] =", rr$out$d13c_NH[1]), "\n")
