setwd("/Users/MarcusMarcus/Documents/2026/CodeProjects/CarbonCycleEmulator")
for (f in list.files("R", pattern="\\.R$", full.names=TRUE)) source(f)
f <- ccx_mode_file(); cat("file:", f, "\n"); cat("md5:", tools::md5sum(f), "\n")
md <- readRDS(f)
cat("names(md):\n"); print(names(md))
for (n in setdiff(names(md), c("hessian","cov","eigen","u_mode","par_mode","sd_unc","streams","param_names","laplace"))) {
  v <- md[[n]]; cat("--", n, ": "); 
  if (is.atomic(v) && length(v) <= 20) print(v) else cat(class(v), length(v), "\n")
}
cat("param_names:", md$param_names, "\n")
cat("par_mode names:", names(md$par_mode), "\n")
