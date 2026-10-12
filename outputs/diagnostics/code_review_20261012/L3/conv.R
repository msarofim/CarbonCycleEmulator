source("/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/fa6620c3-fcfb-49a4-a787-90d23c00188e/scratchpad/review/L3/load.R")
S <- "/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/fa6620c3-fcfb-49a4-a787-90d23c00188e/scratchpad/review/L3"
md <- readRDS(ccx_mode_file()); rp <- readRDS(file.path(S, "rp.rds")); p <- rp$p
spinf <- ccx_spinup_from_label(ccx_mode_spinup(md))
.orig <- ccx_substeps_for
res <- list()
for (N in c(4L, 8L, 16L)) {
  ccx_substeps_for <- function(p, grid = ccx_ocean_grid(p$h_ml), dt = 1/12) N
  sp <- spinf(p)
  F <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = sp$prod_c14, bomb_total_kmol = rp$bomb_total,
                         luc_scale = rp$luc_scale, enso_index = ccx_enso_index_of(p), aod_mode = ccx_aod_mode_of(p))
  r <- ccx_run_fast(sp, F)
  stopifnot(r$substeps == N, !r$retried)
  res[[as.character(N)]] <- r$out
}
ccx_substeps_for <- .orig
for (cc in c("co2_NH", "co2_SH", "d13c_NH", "d14c_NH", "ocean_C", "land_C", "ml_C_SH", "ml_pco2_SH")) {
  d48 <- max(abs(res[["4"]][[cc]] - res[["8"]][[cc]])); d816 <- max(abs(res[["8"]][[cc]] - res[["16"]][[cc]]))
  cat(sprintf("%-11s max|4-8| %.3e   max|8-16| %.3e   ratio %.1f\n", cc, d48, d816, d48 / d816))
}
cat("CO2_NH last row 4/8/16:", sapply(res, function(o) o$co2_NH[nrow(o)]), "\n")
