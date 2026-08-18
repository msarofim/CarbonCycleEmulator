# =====================================================================
# HEMISPHERIC T RATIOS: SST and land T per unit GMST -- measured from obs,
# and their STABILITY across warming levels (Marcus 2026-08-18).
#
# THE QUESTION THIS ANSWERS. Future scenarios need hemispheric SST (and
# possibly land T) from the scenario's GMST. Options: (a) CMIP6-derived
# ratios that scale with warming level; (b) constant ratios from recent
# observations. Whether (a) buys anything over (b) turns on whether the
# ratios DRIFT with warming -- and the observed record spans ~1.3 K of
# GMST, so it can test that directly: regress each hemispheric series on
# IGCC GMST over successive windows and watch the slope.
#
# All anomalies re-based to 1850-1900 (the IGCC GMST convention) before
# anything is compared -- HadSST4 ships 1961-90-based, CRUTEM5 likewise.
# =====================================================================
DL <- "data-raw/downloads"
BASE <- c(1850, 1900)

gm <- read.csv(file.path(DL, "igcc2024_gmst_4dataset_mean.csv"))
gm <- data.frame(year = floor(gm$time), gmst = gm$GMST)

# na.rm: CRUTEM5 SH has gaps in the sparse early record; the base-period mean
# and the regressions use the years that exist rather than dying on the gaps.
rebase <- function(d) {
  d <- d[is.finite(d$anom), ]
  d$anom <- d$anom - mean(d$anom[d$year >= BASE[1] & d$year <= BASE[2]])
  d
}
sst <- lapply(c(NH = "NHEM", SH = "SHEM"), function(h) {
  d <- read.csv(file.path(DL, sprintf("HadSST.4.2.0.0_annual_%s.csv", h)))
  rebase(data.frame(year = d$year, anom = d$anomaly))
})
land <- lapply(c(NH = "northern_hemisphere", SH = "southern_hemisphere"), function(h) {
  d <- read.csv(file.path(DL, sprintf("CRUTEM.5.1.0.0.summary_series.%s.annual.csv", h)))
  rebase(data.frame(year = d$Time, anom = d[[2]]))
})

slope <- function(d, y0, y1) {
  m <- merge(d, gm, by = "year"); m <- m[m$year >= y0 & m$year <= y1, ]
  # no intercept: both series share the 1850-1900 zero by construction, and a
  # free intercept would let a baseline artifact masquerade as a ratio change
  sum(m$anom * m$gmst) / sum(m$gmst^2)
}
windows <- list(c(1880, 1940), c(1940, 1980), c(1965, 1995), c(1995, 2024), c(1850, 2024))
cat("=== slope: hemispheric anomaly per K of IGCC GMST (no intercept, common 1850-1900 base) ===\n")
cat(sprintf("%-12s %10s %10s %10s %10s\n", "window", "SST_NH", "SST_SH", "LAND_NH", "LAND_SH"))
for (w in windows) {
  cat(sprintf("%-12s %10.3f %10.3f %10.3f %10.3f%s\n",
      paste(w, collapse = "-"),
      slope(sst$NH, w[1], w[2]),  slope(sst$SH, w[1], w[2]),
      slope(land$NH, w[1], w[2]), slope(land$SH, w[1], w[2]),
      if (w[1] == 1995) "   <- the 'last 30 yr' candidate" else ""))
}
cat("\nGMST spanned: 1880-1940 window centred ~+0.05 K; 1995-2024 centred ~+1.0 K.\n")
cat("If the slopes are stable across these rows, the ratio does not detectably\n")
cat("scale with warming over the observed range, and constant-forward is defensible\n")
cat("to the extent the future resembles an extrapolation of that stability.\n")
