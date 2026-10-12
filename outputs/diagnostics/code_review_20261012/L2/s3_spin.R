source("/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/fa6620c3-fcfb-49a4-a787-90d23c00188e/scratchpad/review/L2/setup.R")
t0 <- Sys.time()
sp <- ccx_spinup_from_label(ccx_mode_spinup(md))(p)
cat("spinup secs:", as.numeric(Sys.time() - t0, units="secs"), "\n")
F <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = sp$prod_c14,
                        bomb_total_kmol = rp$bomb_total, luc_scale = rp$luc_scale,
                        enso_index = ccx_enso_index_of(rp$p), aod_mode = ccx_aod_mode_of(rp$p))
saveRDS(list(sp = sp, F = F, rp = rp), file.path(SCR, "spin_F.rds"))
cat("F cols:", paste(names(F), collapse=" "), "\n")
