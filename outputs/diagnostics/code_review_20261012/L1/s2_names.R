setwd("/Users/MarcusMarcus/Documents/2026/CodeProjects/CarbonCycleEmulator")
for (f in list.files("R", pattern="\\.R$", full.names=TRUE)) source(f)
d <- ccx_default_params()
cat("CCX_PARAM_NAMES (", length(CCX_PARAM_NAMES), "):\n"); print(CCX_PARAM_NAMES)
cat("\nIn table but NO default slot:\n"); print(setdiff(CCX_PARAM_NAMES, names(d)))
cat("\nGated ALL names:\n"); print(names(CCX_PARAM_GATED_ALL)); cat("gated without default slot:\n"); print(setdiff(names(CCX_PARAM_GATED_ALL), names(d)))
md <- readRDS(ccx_mode_file())
cat("\npar_mode names with no default slot:\n"); print(setdiff(names(md$par_mode), names(d)))
cat("\npar_mode names not in CCX_PARAM_NAMES:\n"); print(setdiff(names(md$par_mode), CCX_PARAM_NAMES))
# Prefix-collision audit: any default name that is a prefix of another (the $ partial matching hazard)
n <- names(d)
for (a in n) { hits <- n[startsWith(n, a) & n != a]; if (length(hits)) cat(sprintf("PREFIX: %-18s is a prefix of %s\n", a, paste(hits, collapse=", "))) }
# Also names on the canonical p
p <- readRDS("/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/fa6620c3-fcfb-49a4-a787-90d23c00188e/scratchpad/review/L1/p_canon.rds")
n2 <- names(p)
cat("\n-- canonical p prefix pairs --\n")
for (a in n2) { hits <- n2[startsWith(n2, a) & n2 != a]; if (length(hits)) cat(sprintf("PREFIX: %-18s is a prefix of %s\n", a, paste(hits, collapse=", "))) }
# Table init vs default mismatches
cat("\n-- table init vs default --\n")
for (nm in intersect(CCX_PARAM_NAMES, names(d))) {
  ii <- CCX_PARAM_TABLE[[nm]]$init
  if (!isTRUE(all.equal(ii, d[[nm]]))) cat(sprintf("%-20s init=%s default=%s  [lo,hi]=[%s,%s]\n", nm, format(ii), format(d[[nm]]), format(CCX_PARAM_TABLE[[nm]]$lo), format(CCX_PARAM_TABLE[[nm]]$hi)))
}
cat("\n-- defaults outside table bounds --\n")
for (nm in intersect(CCX_PARAM_NAMES, names(d))) {
  lo <- CCX_PARAM_TABLE[[nm]]$lo; hi <- CCX_PARAM_TABLE[[nm]]$hi
  if (!is.null(lo) && !is.null(hi) && is.numeric(d[[nm]]) && (d[[nm]] < lo || d[[nm]] > hi)) cat(sprintf("%-20s default=%s outside [%s,%s] tr=%s\n", nm, format(d[[nm]]), format(lo), format(hi), format(CCX_PARAM_TABLE[[nm]]$tr)))
}
