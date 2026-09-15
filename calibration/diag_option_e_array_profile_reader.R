for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f); ccx_load_cpp()
x <- readRDS(ccx_path("outputs", "diagnostics", "option_e_array_read_20260915.rds"))
source(ccx_path("calibration", "lib_design_gates.R"))
for (a in c("canonical", "e_best")) {
  v <- x$res[[a]]$v; v$spinup <- CCX_OBJECTIVE_SPINUP; v$luc_scale <- v$pm$luc_scale; v$bomb_total <- v$pm$bomb_total
  re <- dg_run(v); out <- re$out; aux <- re$sp$aux; grid <- re$sp$grid
  ep <- 1760   # an early PI-ish year of the transient (the spinup is periodic; the first decade is near-PI)
  ml <- ccx_box_annual_conc(out, aux, grid, "ml", ep)
  cat(sprintf("%s: annual-mean concentration at %d (mass-at-the-time reader), minus ML:", a, ep))
  dp <- ccx_box_annual_conc(out, aux, grid, "deep", ep); cat(sprintf("  ML %.0f  bottom-ML %+.0f (y-based earlier: canonical +254, mode +311); winter ML max %.0f m vs layer-1 base %.0f m, layer-2 base %.0f m", ml[["dic"]], dp[["dic"]] - ml[["dic"]], grid$h_ml * max(vapply(HEMIS, function(h) max(ccx_mld_shape("ls")[[h]]$f_month), numeric(1))), grid$h_ml + grid$dz[2], grid$h_ml + grid$dz[2] + grid$dz[3]))
  cat("\n")
}
