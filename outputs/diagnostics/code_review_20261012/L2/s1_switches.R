source("/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/fa6620c3-fcfb-49a4-a787-90d23c00188e/scratchpad/review/L2/setup.R")
cat("mode file:", ccx_mode_file(CCX_MODE_CANONICAL), "\n")
cat("struct:", ccx_mode_struct(md), " seas_ml:", ccx_mode_seas_ml(md), " spinup:", ccx_mode_spinup(md), " pump:", md$pump_mode, "\n")
preds <- ls(pattern="^ccx_.*_on$")
for (f in preds) { r <- tryCatch(get(f)(p), error=function(e) paste("ERR", conditionMessage(e))); cat(sprintf("%-28s %s\n", f, paste(format(r), collapse=" "))) }
d <- ccx_default_params()
cat("\n--- params differing from defaults ---\n")
for (n in union(names(p), names(d))) {
  a <- p[[n]]; b <- d[[n]]
  if (!identical(a, b)) cat(sprintf("%-24s canon=%s  default=%s\n", n, paste(format(a, digits=6), collapse=","), paste(format(b, digits=6), collapse=",")))
}
saveRDS(p, file.path(SCR, "p_canon.rds"))
