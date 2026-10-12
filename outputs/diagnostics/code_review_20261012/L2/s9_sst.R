source("/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/fa6620c3-fcfb-49a4-a787-90d23c00188e/scratchpad/review/L2/setup.R")
z <- readRDS(file.path(SCR, "spin_F.rds")); F <- z$F; sp <- z$sp
aux <- sp$aux
cat("sst_hs param:", if (is.null(p$sst_hs)) "NULL" else p$sst_hs, " aux$sst_hs:", aux$sst_hs, "\n")
for (h in HEMIS) {
  sa <- F[[paste0("sst_anom_", h)]]
  a_s <- if (h == "NH") p$sst_seas_amp_NH else p$sst_seas_amp_SH
  sg <- if (h == "NH") 1 else -1
  sst <- aux$sst[[h]] + sa + sg * a_s * sin(2 * pi * (F$t - (3.5 + CCX_SST_SEAS_LAG) / 12))
  cat(h, "LS SST range 1750-2024:", round(range(sst), 2), " frac of months >21:", round(mean(sst > 21), 3), " <5:", round(mean(sst < 5), 3), "\n")
  sst_hs <- aux$sst_hs + ccx_hs_sst_frac(p) * sa
  cat(h, "HS SST range:", round(range(sst_hs), 2), "\n")
}
