source("/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/fa6620c3-fcfb-49a4-a787-90d23c00188e/scratchpad/review/L3/load.R")
S <- "/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/fa6620c3-fcfb-49a4-a787-90d23c00188e/scratchpad/review/L3"
md <- readRDS(ccx_mode_file())
rp <- readRDS(file.path(S, "rp.rds")); p <- rp$p
t0 <- proc.time()
spinf <- ccx_spinup_from_label(ccx_mode_spinup(md))
sp <- spinf(p)
cat("spinup s:", (proc.time()-t0)[3], "\n")
F <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = sp$prod_c14,
     bomb_total_kmol = rp$bomb_total, luc_scale = rp$luc_scale,
     enso_index = ccx_enso_index_of(p), aod_mode = ccx_aod_mode_of(p))
saveRDS(list(sp = sp, F = F), file.path(S, "spinF.rds"))
cat("rows:", nrow(F), " substeps:", ccx_substeps_for(p, sp$grid), "\n")
# C++ to 1955
i0 <- which(F$t >= 1955)[1]
Fa <- F[seq_len(i0 - 1L), ]; Fb <- F[i0:(i0 + 20*12 - 1L), ]
ra <- ccx_run_fast(sp, Fa)
cat("retried pre:", ra$retried, ra$substeps, "\n")
s2 <- sp; s2$y <- ra$state
s2$enso_hist <- ccx_enso_hist_after(Fa$enso, sp$enso_hist)
s2$tdeep0 <- ccx_mix_tdeep_after(Fa$gmst, Fa$t, p, sp$tdeep0)
cat("tdeep0 at 1955:", s2$tdeep0, "\n")
saveRDS(list(s2 = s2, Fb = Fb), file.path(S, "s2.rds"))
t1 <- proc.time()
rC <- ccx_run_fast(s2, Fb)
cat("C++ s:", (proc.time()-t1)[3], " retried:", rC$retried, "\n")
t1 <- proc.time()
rR <- ccx_run(s2, Fb)
cat("R s:", (proc.time()-t1)[3], "\n")
saveRDS(list(rR = rR, rC = rC), file.path(S, "par1_out.rds"))
g <- ccx_mix_g_series(Fb$gmst, Fb$t, p, s2$tdeep0); cat("mix_g range:", range(g), "\n")
cat("enso range:", range(Fb$enso), " aod max:", max(Fb$aod_NH), "\n")
# per-tracer state differences
for (tr in CCX_TRACERS) {
  d <- abs(rR$state[, tr] - rC$state[, tr])
  cat(sprintf("state %-4s max abs %.3e  rel(to max|state|) %.3e  worst box %s\n", tr, max(d), max(d)/max(abs(rR$state[, tr])),
              rownames(rR$state)[which.max(d)]))
}
cols <- setdiff(intersect(names(rR$out), names(rC$out)), "t")
res <- t(sapply(cols, function(cc) { a <- rR$out[[cc]]; b <- rC$out[[cc]]
  if (all(is.na(a)) && all(is.na(b))) return(c(NA, NA, NA))
  c(maxabs = max(abs(a - b), na.rm = TRUE), rel = max(abs(a - b), na.rm = TRUE) / max(abs(a), na.rm = TRUE), nNAmismatch = sum(is.na(a) != is.na(b))) }))
print(signif(res, 3))
cat("npp diff:", max(abs(as.matrix(rR$npp[, -1]) - as.matrix(rC$npp[, -1]))), "\n")
cat("cols only in R:", setdiff(names(rR$out), names(rC$out)), " only in C:", setdiff(names(rC$out), names(rR$out)), "\n")
