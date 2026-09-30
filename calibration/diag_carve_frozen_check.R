# =====================================================================
# diag_carve_frozen_check.R -- FROZEN carve-out futures (CHANGELOG 09-29 v, D).
# The re-fitted carve-out (exchanging passive x0.8053) gave +18.8 ppm ssp585 2300
# against a retention-weight estimate of ~+36. This runs the fixed-stock tau-500
# CONTROL vector with ONLY litter_slow_frac scaled (nothing re-fitted), to see
# whether the re-fit is what halves it. Measured 2026-09-29: +52.0 ppm at 2300,
# +2.10 ppm at 2024. No RNG. USAGE: Rscript calibration/diag_carve_frozen_check.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f); ccx_load_cpp()
MODE <- ccx_path("calibration","output","multistart_20260928c_hilda_csl3v0k_seasml1_pin_ent_seas_amp_SH=0_w_eq=27_gamma_eq=1_pump_export=9.08_w_vent=0_gamma_vent=0_w_thc=0_gamma_enso_ocn_NH=0_gamma_enso_ocn_SH=0_sd1.0452","promoted_basin1","mode_fit_pumpN.rds")
FREE <- c("beta_max","fert_k","luc_scale","q10","seas_T_amp_NH","seas_T_amp_SH","seas_lag_p_NH","seas_lag_p_SH","npp_frac_NH","kz","rep_dC")
md <- readRDS(ccx_mode_file(MODE)); invisible(ccx_apply_pins(md$pins))
bp <- ccx_mode_base(md); bp$pump_mode <- md$pump_mode
bp <- ccx_apply_structure(bp, "hilda_csl3v0ka", as.character(md$seas_ml), pump_field = md$pump_field)
for (n in names(md$pins)) bp[[n]] <- md$pins[[n]]
prev <- read.csv(ccx_path("outputs","diagnostics","npp0_scan_20260929.csv")); r1 <- prev[prev$scale == 1, ]
p0 <- as.list(ccx_unc_to_par(md$u_mode)); for (n in FREE) p0[[n]] <- r1[[n]]
ctrl <- readRDS(ccx_path("outputs","diagnostics","tau_soil_slow_profile_fixedstock_20260929.rds"))[[2]]; stopifnot(ctrl$value == 500)
run <- function(lsf) { pr <- p0; for (n in FREE) pr[[n]] <- ctrl$par[[n]]
  pu <- ccx_unc_to_par(ccx_par_to_unc(unlist(pr)[md$param_names])); b <- bp; b$litter_slow_frac <- lsf
  p <- ccx_overlay_par(b, pu); sp <- ccx_spinup_from_label(ccx_mode_spinup(md))(p)
  r <- suppressWarnings(ccx_run_coupled(sp, "ssp585", c(1750L, 2300L), bomb_total_kmol = pu$bomb_total, luc_scale = pu$luc_scale))$out
  co2 <- tapply((r$co2_NH + r$co2_SH)/2, floor(r$t), mean); as.numeric(co2[c("2024","2100","2300")]) }
a <- run(0.05); b <- run(0.05 * 0.8053)
cat(sprintf("frozen ctrl  2024 %.2f 2100 %.1f 2300 %.2f\nfrozen carve 2024 %.2f 2100 %.1f 2300 %.2f\nd2300 %+.1f  d2024 %+.2f\n", a[1],a[2],a[3], b[1],b[2],b[3], b[3]-a[3], b[1]-a[1]))
