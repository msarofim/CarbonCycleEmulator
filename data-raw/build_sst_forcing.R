# =====================================================================
# HadSST4 hemispheric annual SST anomalies -> data/forcing_sst.rds
# (2026-08-18, Marcus: HadSST4 for the historical record.)
#
# Re-based from HadSST4's native 1961-90 convention to 1850-1900, the same
# convention as the IGCC GMST forcing -- comparing or splicing anomalies on
# different baselines manufactures offsets (standing rule: multi-year
# baseline, same window for every series).
# =====================================================================
DL <- "data-raw/downloads"; BASE <- c(1850, 1900)
out <- Reduce(function(a, b) merge(a, b, by = "year"),
  lapply(c(NH = "NHEM", SH = "SHEM"), function(h) {
    d <- read.csv(file.path(DL, sprintf("HadSST.4.2.0.0_annual_%s.csv", h)))
    a <- d$anomaly - mean(d$anomaly[d$year >= BASE[1] & d$year <= BASE[2]])
    setNames(data.frame(d$year, a), c("year", paste0("sst_anom_", if (h == "NHEM") "NH" else "SH")))
  }))
stopifnot(nrow(out) > 170, all(is.finite(out$sst_anom_NH)))
saveRDS(out, "data/forcing_sst.rds")
cat(sprintf("forcing_sst.rds: %d-%d, 1850-1900 means re-zeroed (NH %.4f, SH %.4f by construction)\n",
    min(out$year), max(out$year),
    mean(out$sst_anom_NH[out$year <= 1900]), mean(out$sst_anom_SH[out$year <= 1900])))
