suppressMessages({for (f in list.files("R", pattern="\\.R$", full.names=TRUE)) source(f)})
source(ccx_path("calibration", "lib_design_gates.R"))
v <- readRDS(Sys.getenv("VFILE")); p <- v$p
sp <- dg_spinup(v)
for (sc in c("vvH", "vvVL")) {
  r <- withCallingHandlers(ccx_run_coupled(sp, sc, c(1750, 2300), bomb_total_kmol = v$bomb_total, luc_scale = v$luc_scale),
                           warning = function(w) {cat("  WARN:", conditionMessage(w), "\n"); invokeRestart("muffleWarning")})
  cat(sc, "iter", r$iterations, "converged", r$converged, " gmst 2300", round(tail(r$climate$gmst,1),3), " co2 range", round(range(r$climate$co2_ppm),1), "\n")
  # one more pass at the returned gmst: does r$out match?
}
# tighter max_iter to see the silent path
r2 <- ccx_run_coupled(sp, "vvH", c(1750, 2300), bomb_total_kmol = v$bomb_total, luc_scale = v$luc_scale, max_iter = 2L)
cat("max_iter=2: converged", r2$converged, "(no warning above means silent)\n")
