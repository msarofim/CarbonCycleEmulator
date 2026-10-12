setwd("/Users/MarcusMarcus/Documents/2026/CodeProjects/CarbonCycleEmulator")
for (f in list.files("R", pattern="\\.R$", full.names=TRUE)) source(f)
lm <- ccx_load_mode(); p <- lm$p
fns <- ls(pattern = "^ccx_.*_on$", envir = globalenv())
for (fn in fns) { f <- get(fn); a <- names(formals(f))
  v <- tryCatch(if (length(a) >= 1 && a[1] %in% c("p","params")) f(p) else "skip(args)", error = function(e) paste("ERR", conditionMessage(e)))
  cat(sprintf("%-28s %s   [%s]\n", fn, paste(format(v), collapse=","), paste(a, collapse=",")))
}
cat("gates open:", ccx_gates_open(ccx_mode_struct(lm$md)), "\n")
sw <- c("seas_ml","seas_drivers","pump_mode","pump_field","hs_frac","k_l2","w0_l2","enso_index","aod_mode","d2d3_free","enso_lag_free","iav_cut","mix_strat_s","mix_strat_q","mix_strat_tau","imb_treatment","imb_with_cement","soil_inert_frac","phi","veg_cap","fert_k_prior","alpha_photo_eps","gcb_land_lowpass_df","gcb_ocean_lowpass_df","gcb_enso_slope_row","ml_nh_cycle","tr_frac_NH","eq_frac_NH","w_eq","w_thc","ra_ratio","npp_tsens","ndep_ret","lag_enso_land")
for (n in sw) cat(sprintf("  %-22s %s\n", n, if (is.null(p[[n]])) "<NULL>" else paste(format(p[[n]]), collapse=",")))
