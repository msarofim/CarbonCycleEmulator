# How much does the app's historical run move if data-raw/downloads/nuclear14c is absent?
# (DEPLOY.md:91 says exclude data-raw/; R/forcing.R:370 reads this dir at run time.)
Sys.setenv(OPENBLAS_NUM_THREADS = 1, VECLIB_MAXIMUM_THREADS = 1)
setwd("/Users/MarcusMarcus/Documents/2026/CodeProjects/CarbonCycleEmulator/app")
t0 <- Sys.time()
source("global.R")
cat(sprintf("global.R sourced in %.0f s; mode %s\n", as.numeric(difftime(Sys.time(), t0, units="secs")), CCX_MODE_CANONICAL))
base <- APP_HIST$out
ccx_nuclear_c14_annual <- function(dir = NULL) {
  warning("No nuclear 14C files found; industrial source set to zero.")
  data.frame(year = integer(0), mol_per_yr = numeric(0)) }
F0 <- app_build_forcing("historical", APP_HIST_YEARS, prod_c14 = APP_SPIN$prod_c14)
zero <- ccx_run_fast(APP_SPIN, F0)$out
cat("\nnuclear source sum (mol): base", sum(APP_HIST$forcing$c14_nuc %||% NA), " zero", sum(F0$c14_nuc %||% NA), "\n")
yr <- floor(base$t)
num <- names(base)[sapply(base, is.numeric)]
dd <- sapply(num, function(v) max(abs(zero[[v]] - base[[v]]), na.rm = TRUE))
cat("\nmax |zero - base| by output column (nonzero only):\n"); print(signif(dd[dd > 0], 3))
for (v in grep("d14c", num, value = TRUE, ignore.case = TRUE)) {
  d <- zero[[v]] - base[[v]]
  ann <- tapply(d, yr, mean)
  cat(sprintf("%-22s annual-mean diff: 1980 %+.2f  2000 %+.2f  2010 %+.2f  %d %+.2f  (max |.| %.2f in %s)\n", v,
      ann["1980"], ann["2000"], ann["2010"], max(yr), ann[as.character(max(yr))], max(abs(ann)), names(ann)[which.max(abs(ann))]))
}
