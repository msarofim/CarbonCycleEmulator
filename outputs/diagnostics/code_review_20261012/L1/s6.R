setwd("/Users/MarcusMarcus/Documents/2026/CodeProjects/CarbonCycleEmulator")
for (f in list.files("R", pattern="\\.R$", full.names=TRUE)) source(f)
d <- ccx_default_params()
src <- unlist(lapply(c(list.files("R", full.names=TRUE), "src/ccx_core.cpp"), readLines))
# drop lines inside ccx_default_params (approx: lines of model.R 1426-2273) by excluding exact "name =" declaration lines
for (n in names(d)) {
  pat <- paste0("(\\$", n, "\\b|\\[\\[\"", n, "\"\\]\\]|\"", n, "\"|P\\.", n, "\\b)")
  hits <- grep(pat, src, perl=TRUE)
  if (length(hits) == 0) cat("NO READER:", n, "\n")
}
