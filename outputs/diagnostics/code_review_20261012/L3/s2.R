source("/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/fa6620c3-fcfb-49a4-a787-90d23c00188e/scratchpad/review/L3/load.R")
md <- readRDS(ccx_mode_file())
pm <- ccx_mode_par_with_pins(md)
if (length(ccx_mode_absent(md))) pm <- ccx_migrate_par_set(pm)
rp <- ccx_mode_run_params(md, pm)
p <- rp$p
saveRDS(rp, "/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/fa6620c3-fcfb-49a4-a787-90d23c00188e/scratchpad/review/L3/rp.rds")
cat("struct:", md$struct, " seas_ml:", md$seas_ml, " pump_field:", md$pump_field, " spinup:", md$spinup, "\n")
print(unlist(md$pins))
pred <- c(hs=ccx_hs_on(p), eq=ccx_eq_on(p), tr=ccx_tr_on(p), inert=ccx_inert_on(p), mix=ccx_mix_on(p),
          seas_ml=ccx_seas_ml_on(p), seas_ml_ls=ccx_seas_ml_ls_on(p), seas_ml_hs=ccx_seas_ml_hs_on(p))
print(pred)
nm <- c("pump_field","pump_grad","pump_export","pump_mode","pump_carb_frac","pump_hs_gcm2","pump_seas_amp","pump_hs_seas_amp",
 "hs_frac","h_hs","u_hs","tau_q","q_attach_from","hs_asx_frac","alk_hs","sst_hs","hs_sst_anom_frac",
 "kz","kz_deep_frac","kz_zscale","h_ml","k_w","w_up","w_out_NH","w_out_SH","q_conv","w_eq","eq_frac_NH","tr_frac_NH","w_vent","w_thc","k_l2","w_enso_l2",
 "seas_drivers","seas_ml","sst_obs","revelle_frozen","alpha_as_tdep","alpha_photo_eps","soil_inert_frac","gamma_diff","ndep_ret","npp_tsens",
 "mix_strat_s","mix_strat_q","mix_strat_tau","lag_enso_land","enso_index","aod_mode","fert_form","f_luc_perm","f_luc_wood","ent_seas_amp_SH",
 "tau_ex_seas_amp","npp_veg_frac","ra_ratio","seas_amp_NH")
for (n in nm) cat(sprintf("%-18s %s\n", n, paste(format(p[[n]]), collapse=",")))
cat("substeps auto:", ccx_substeps_for(p), "\n")
cat("enso_index:", ccx_enso_index_of(p), " aod_mode:", ccx_aod_mode_of(p), " enso_lag:", ccx_enso_lag_of(p), "\n")
