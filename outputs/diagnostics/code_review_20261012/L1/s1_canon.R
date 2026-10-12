setwd("/Users/MarcusMarcus/Documents/2026/CodeProjects/CarbonCycleEmulator")
for (f in list.files("R", pattern="\\.R$", full.names=TRUE)) source(f)
md <- readRDS(ccx_mode_file())
cat("struct:", ccx_mode_struct(md), " seas_ml:", ccx_mode_seas_ml(md), " pump_field:", ccx_mode_pump_field(md), " pump_mode:", md$pump_mode, " spinup:", ccx_mode_spinup(md), "\n")
cat("pins:\n"); print(unlist(md$pins))
pm <- ccx_mode_par_with_pins(md)
base <- ccx_mode_base(md)
p <- ccx_overlay_par(base, pm)
d <- ccx_default_params()
cat("par_mode names (", length(md$par_mode), "):\n"); print(unlist(md$par_mode))
cat("\n--- predicates ---\n")
cat("hs_on", ccx_hs_on(p), " eq_on", ccx_eq_on(p), " tr_on", ccx_tr_on(p), " inert_on", ccx_inert_on(p),
    " seas_ml_on", ccx_seas_ml_on(p), " seas_ml_ls", ccx_seas_ml_ls_on(p), " seas_ml_hs", ccx_seas_ml_hs_on(p), "\n")
cat("mix_on", tryCatch(ccx_mix_on(p), error=function(e) conditionMessage(e)), "\n")
cat("enso lag", ccx_enso_lag_of(p), "\n"); print(ccx_gamma_enso(p)); print(ccx_seas_lag_p(p))
cat("hs_sst_frac", ccx_hs_sst_frac(p), "\n")
cat("\n--- differences base/final p vs default ---\n")
nm <- union(names(d), names(p))
for (n in nm) {
  a <- d[[n]]; b <- p[[n]]
  if (!identical(a, b)) cat(sprintf("%-22s default=%s  canon=%s\n", n, paste(format(a), collapse=","), paste(format(b), collapse=",")))
}
saveRDS(p, "/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/fa6620c3-fcfb-49a4-a787-90d23c00188e/scratchpad/review/L1/p_canon.rds")
