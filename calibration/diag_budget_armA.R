# =====================================================================
# diag_budget_armA.R -- IS THE LAND COVERING FOR THE OCEAN AT ARM A? (2026-09-30 c)
# Marcus 2026-09-30: "several land-carbon issues ... all pushing in unphysical
# directions." One common-cause candidate is a model OCEAN sink below GCB's, which
# the land would then make up. The 09-24 identity (diag_land_sink_bias_budget.R)
# ruled that out at hilda29l (dOcean -0.05), but arm A's kz is ~2x that mode's, so
# it is re-measured here on arm A's fixed-stock tau-500 control vector: model vs
# GCB ocean sink, RESIDUAL land sink (d land_C + E_LUC, gate 7's convention) and
# E_LUC, by window. Same annual-sink estimator as gate 7 (dg_annual_sinks()).
# No RNG. USAGE: Rscript calibration/diag_budget_armA.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f); ccx_load_cpp()
source("calibration/lib_design_gates.R")
MODE <- ccx_path("calibration","output","multistart_20260928c_hilda_csl3v0k_seasml1_pin_ent_seas_amp_SH=0_w_eq=27_gamma_eq=1_pump_export=9.08_w_vent=0_gamma_vent=0_w_thc=0_gamma_enso_ocn_NH=0_gamma_enso_ocn_SH=0_sd1.0452","promoted_basin1","mode_fit_pumpN.rds")
FREE <- c("beta_max","fert_k","luc_scale","q10","seas_T_amp_NH","seas_T_amp_SH","seas_lag_p_NH","seas_lag_p_SH","npp_frac_NH","kz","rep_dC")
md <- readRDS(ccx_mode_file(MODE)); invisible(ccx_apply_pins(md$pins))
prev <- read.csv(ccx_path("outputs","diagnostics","npp0_scan_20260929.csv")); r1 <- prev[prev$scale == 1, ]
ctrl <- readRDS(ccx_path("outputs","diagnostics","tau_soil_slow_profile_fixedstock_20260929.rds"))[[2]]
bp <- ccx_mode_base(md); bp$pump_mode <- md$pump_mode
bp <- ccx_apply_structure(bp, "hilda_csl3v0ka", as.character(md$seas_ml), pump_field = md$pump_field)
for (n in names(md$pins)) bp[[n]] <- md$pins[[n]]; for (n in names(ctrl$over)) bp[[n]] <- ctrl$over[[n]]
p0 <- as.list(ccx_unc_to_par(md$u_mode)); for (n in FREE) p0[[n]] <- ctrl$par[[n]]
pu <- ccx_unc_to_par(ccx_par_to_unc(unlist(p0)[md$param_names])); p <- ccx_overlay_par(bp, pu)
sp <- ccx_spinup_from_label(ccx_mode_spinup(md))(p)
F <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = sp$prod_c14, bomb_total_kmol = pu$bomb_total,
                       luc_scale = pu$luc_scale, enso_index = ccx_enso_index_of(p), aod_mode = ccx_aod_mode_of(p))
r <- ccx_run_fast(sp, F); r$F <- F
a <- dg_annual_sinks(r); el <- ccx_forcing_eluc_annual(F)
g <- readRDS(ccx_path("data","gcb_budget.rds"))$budget
OUT <- ccx_path("outputs","diagnostics","budget_armA_20260930.log"); sink(OUT, split = TRUE)
W <- list(c(1960,1989), c(1990,2009), c(2010,2023), c(1960,2023))
cat(sprintf("arm A fixed-stock tau-500 control; kz %.0f, luc_scale %.4f, beta_max %.3f, fert_k %.1f, q10 %.3f\n", pu$kz, pu$luc_scale, pu$beta_max, pu$fert_k, pu$q10))
cat(sprintf("%-11s %7s %7s %7s | %7s %7s %7s | %7s %7s\n", "window", "ocn_M", "ocn_G", "dOcn", "lnd_M", "lnd_G", "dLnd", "luc_M", "luc_G"))
for (w in W) { k <- a$year >= w[1] & a$year <= w[2]; kg <- g$year >= w[1] & g$year <= w[2]; ke <- el$year >= w[1] & el$year <= w[2]
  cat(sprintf("%d-%d %7.3f %7.3f %+7.3f | %7.3f %7.3f %+7.3f | %7.3f %7.3f\n", w[1], w[2], mean(a$ocean[k]), mean(g$ocean_sink[kg]), mean(a$ocean[k]) - mean(g$ocean_sink[kg]),
    mean(a$land[k]), mean(g$land_sink[kg]), mean(a$land[k]) - mean(g$land_sink[kg]), mean(el$eluc[ke]), mean(g$luc[kg]))) }
cat(sprintf("provenance: calibration/diag_budget_armA.R @%s; hilda_csl3v0ka v0k basin1 + fixed-stock tau500 control; historical 1750-2024; GtC/yr; GCB = data/gcb_budget.rds; no RNG\n", system("git rev-parse --short HEAD", intern = TRUE))); sink()
