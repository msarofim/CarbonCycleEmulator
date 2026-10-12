suppressMessages({for (f in list.files("R", pattern="\\.R$", full.names=TRUE)) source(f)})
source(ccx_path("calibration", "lib_design_gates.R"))
v <- readRDS(Sys.getenv("VFILE")); p <- v$p
cat("spinup label:", v$spinup_label, "\n")
fn <- if (is.null(v$spinup)) ccx_spinup else v$spinup
t0 <- Sys.time(); sp <- fn(p); cat("spinup time", format(Sys.time() - t0), "\n")
F <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = sp$prod_c14, bomb_total_kmol = v$bomb_total,
                       luc_scale = v$luc_scale, enso_index = ccx_enso_index_of(p), aod_mode = ccx_aod_mode_of(p))
gpp <- ccx_const("GtC_PER_PPM") / 2
tot <- function(state, aux) sum(state[, "C"])
budget <- function(sp0, F0) {
  r <- ccx_run_fast(sp0, F0)
  dC <- sum(r$state[, "C"]) - sum(sp0$y[, "C"])
  E  <- sum(F0$e_foss_NH + F0$e_foss_SH) / 12 - sum(F0$sink_ocean[F0$sink_ocean != 0]) * 0
  c(dC = dC, foss = E, resid = dC - E, co2_2024 = mean(tail((r$out$co2_NH + r$out$co2_SH)/2, 12)))
}
cat("none:", round(budget(sp, F), 8), "\n")
for (nm in names(CCX_MECHANISMS)) {
  t0 <- Sys.time()
  ms <- tryCatch(ccx_mechanism_spinup(p, F, nm, fn), error = function(e) {cat(nm, "ERROR", conditionMessage(e), "\n"); NULL})
  if (is.null(ms)) next
  b <- budget(ms$spin, ms$m$F)
  cat(sprintf("%-17s dC %.6f foss %.6f resid %.2e co2_2024 %.2f  (%.1fs)\n", nm, b["dC"], b["foss"], b["resid"], b["co2_2024"], as.numeric(Sys.time()-t0, units="secs")))
}
