for (f in list.files("R", pattern="\\.R$", full.names=TRUE)) source(f)
ccx_load_cpp()
md <- readRDS(ccx_mode_file())
invisible(ccx_apply_gate(ccx_mode_struct(md)))
PINS <- ccx_mode_pins(md); invisible(ccx_apply_pins(PINS))
ccx_require_param_set(md, "review")
invisible(ccx_adopt_mode_band(md))
ccx_check_mode_decode(md)
u0  <- ccx_par_to_unc(md$par_mode)
cat("fitted names (", length(CCX_PARAM_NAMES), "):\n"); 
tab <- do.call(rbind, lapply(CCX_PARAM_NAMES, function(n) { s <- CCX_PARAM_TABLE[[n]]
  data.frame(name=n, tr=s$tr, lo=if(is.null(s$lo)) NA else s$lo, hi=if(is.null(s$hi)) NA else s$hi,
             init=if(is.null(s$init)) NA else s$init, mode=md$par_mode[[n]], u=u0[[n]],
             prior_at_mode=.ccx_prior_eval(s, md$par_mode[[n]], NULL), stringsAsFactors=FALSE)}))
print(tab, digits=5)
bp  <- ccx_mode_base(md); if (!is.null(md$pump_mode)) bp$pump_mode <- md$pump_mode
cat("\nstructure switches in base params:\n")
sw <- c("hs_frac","seas_ml","pump_mode","iav_cut","npp_row","fert_k_prior","imb_treatment","imb_with_cement","enso_index","aod_mode","gcb_land_lowpass_df","gcb_ocean_lowpass_df","gcb_enso_slope_row","enso_lag_free","d2d3_free","ndep_ret","w_eq","w_vent","w_thc","inert","mix_strat_s","tr_on","eq_on","alpha_photo_eps")
for (n in sw) cat(sprintf("  %-22s %s\n", n, paste(format(bp[[n]]), collapse=",")))
cat("hs_on", ccx_hs_on(bp), " eq_on", ccx_eq_on(bp), " tr_on", ccx_tr_on(bp), " inert_on", ccx_inert_on(bp), " mix_on", ccx_mix_on(bp), "\n")
cat("gates open:", paste(ccx_gates_open(bp), collapse=","), "\n")
t0 <- Sys.time()
lpf <- ccx_make_logpost(base_params = bp, spinup_fn = ccx_spinup_from_label(ccx_mode_spinup(md)), by_stream=TRUE)
v <- lpf(u0)
cat(sprintf("\nrecomputed %.6f stored %.6f diff %.3e ; loglik %.4f logprior %.4f ; %.1f s\n", as.numeric(v), md$logpost, as.numeric(v)-md$logpost, attr(v,"loglik"), attr(v,"logprior"), as.numeric(difftime(Sys.time(),t0,units="secs"))))
st <- attr(v, "streams"); print(round(st, 4))
if (!is.null(md$streams)) { cat("\nstored streams vs recomputed:\n"); s0 <- md$streams; 
  nm <- union(names(s0), names(st)); print(data.frame(stored=s0[nm], now=st[nm], diff=st[nm]-s0[nm], row.names=nm), digits=8) }
saveRDS(list(u0=u0, st=st, v=v, tab=tab), "/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/fa6620c3-fcfb-49a4-a787-90d23c00188e/scratchpad/review/L6/s2_out.rds")
