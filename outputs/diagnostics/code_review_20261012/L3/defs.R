source("/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/fa6620c3-fcfb-49a4-a787-90d23c00188e/scratchpad/review/L3/load.R")
S <- "/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/fa6620c3-fcfb-49a4-a787-90d23c00188e/scratchpad/review/L3"
d <- ccx_default_params(); d <- ccx_set_enso(d, list(gamma_enso = 0.5))
c <- readRDS(file.path(S, "rp.rds"))$p
nm <- sort(union(names(d), names(c)))
diffs <- Filter(function(n) !identical(d[[n]], c[[n]]), nm)
for (n in diffs) cat(sprintf("%-22s default=%-28s canon=%s\n", n, paste(format(d[[n]]), collapse=","), paste(format(c[[n]]), collapse=",")))
cat("pred default: hs", ccx_hs_on(d), "inert", ccx_inert_on(d), "mix", ccx_mix_on(d), "seasml", ccx_seas_ml_on(d), "lag", ccx_enso_lag_of(d), "enso_idx", ccx_enso_index_of(d), "aod", ccx_aod_mode_of(d), "\n")
cat("canon ml_nh_cycle:", format(c$ml_nh_cycle), "\n")
