# =====================================================================
# diag_sh_land_latitude.R -- WHERE IS THE SOUTHERN HEMISPHERE'S LAND,
#                            AND WHERE IS ITS BIOMASS?
#
# THE QUESTION (Marcus 2026-08-20e): the SH effective latitude is NOT determined
# by either the observed seasonal shape (diag_seas_rectification.R: the residual
# is flat from -16 to -40 once amplitude is free) or by the calibration
# (diag_phi_eff_profile.R: -15.75 and -40 are within 12 log-units of each other).
# When the data do not choose, the choice should be made on physical grounds --
# and Marcus' prior is the WEIGHTED LATITUDE OF THE NON-ANTARCTIC LAND MASS,
# "because that's where the biomass is".
#
# That is a testable statement with more than one reading, so all of them are
# computed rather than one being picked:
#   1. LAND AREA          -- every square meter of ice-free land, deserts
#                            included. The literal reading of "land mass".
#   2. VEGETATED AREA     -- MOD17's valid pixels: land that MODIS sees
#                            vegetation on. Sahara/Atacama/Namib drop out.
#   3. NPP                -- MOD17's flux. Where the carbon actually moves,
#                            which is what the model's NEP term represents.
# They are not the same number, and the gaps between them ARE the answer to
# "which weighting did you mean".
#
# ANTARCTICA IS EXCLUDED FROM (1) EXPLICITLY. It is 8.8 % of the globe's land
# area, it is at 90 S where the insolation shape is extreme, and it carries no
# vegetation -- including it would drag the area-weighted latitude poleward for
# a continent that contributes nothing to the seasonal carbon cycle. It drops
# out of (2) and (3) by itself, which is a useful check on the exclusion.
#
# The land fraction is ERSSTv5's ocean mask inverted, exactly as
# data-raw/build_seasonal_climatology.R builds it -- same product, same idiom,
# so the two are comparable.
#
# Usage:  Rscript calibration/diag_sh_land_latitude.R
# =====================================================================
suppressPackageStartupMessages(library(ncdf4))
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)

SL_ERSST <- "data-raw/downloads/ersst_v5_sst_mnmean.nc"
SL_NPP   <- "data-raw/downloads/mod17_npp"
SL_ANTARCTIC <- -60      # deg; the exclusion cut for the land-AREA weighting
SL_NVALID_FULL <- 14400
SL_R <- 6371000
SL_NGRID <- 720

tt <- (seq_len(SL_NGRID) - 0.5) / SL_NGRID
p2p_of <- function(phi) { v <- ccx_insol(phi, tt); max(v) - min(v) } # v is unit-mean below
pp <- function(phi) { v <- ccx_insol(phi, tt); v <- v / mean(v); max(v) - min(v) }

# ---- 1. LAND AREA, from ERSSTv5's ocean mask -------------------------
nc <- nc_open(SL_ERSST)
elat <- ncvar_get(nc, "lat"); elon <- ncvar_get(nc, "lon")
sst  <- ncvar_get(nc, "sst", start = c(1, 1, 1), count = c(-1, -1, 12))
nc_close(nc)
# A cell is OCEAN if ERSST reports SST there in any of the first 12 months.
is_ocean <- apply(is.finite(sst), c(1, 2), any)
dlat <- abs(diff(elat)[1]); dlon <- abs(diff(elon)[1])
alat <- SL_R^2 * (dlon * pi / 180) *
  abs(sin((elat + dlat / 2) * pi / 180) - sin((elat - dlat / 2) * pi / 180))
area <- matrix(rep(alat, each = length(elon)), nrow = length(elon))
land <- area * !is_ocean
cat(sprintf("ERSSTv5 grid %d x %d, land = %.1f %% of the globe (incl. Antarctica)\n",
            length(elon), length(elat), 100 * sum(land) / sum(area)))

wmean_lat <- function(w, lat, sel) {
  wl <- colSums(w)[sel]; la <- lat[sel]
  sum(wl * la) / sum(wl)
}
sh_all <- elat < 0
sh_noa <- elat < 0 & elat > SL_ANTARCTIC
nh_all <- elat >= 0
cat(sprintf("  Antarctica (south of %g) is %.1f %% of all land area\n", SL_ANTARCTIC,
            100 * sum(land[, elat <= SL_ANTARCTIC]) / sum(land)))

# ---- 2 & 3. VEGETATED AREA and NPP, from MOD17 -----------------------
fs <- list.files(SL_NPP, pattern = "\\.nc$", recursive = TRUE, full.names = TRUE)
nc <- nc_open(fs[1]); mlat <- ncvar_get(nc, "lat"); mlon <- ncvar_get(nc, "lon"); nc_close(nc)
mdlat <- abs(diff(mlat)[1]); mdlon <- abs(diff(mlon)[1])
malat <- SL_R^2 * (mdlon * pi / 180) *
  abs(sin((mlat + mdlat / 2) * pi / 180) - sin((mlat - mdlat / 2) * pi / 180))
px <- malat[which.min(abs(mlat))] / SL_NVALID_FULL
veg <- matrix(0, length(mlon), length(mlat)); npp <- veg
for (f in fs) {
  nc <- nc_open(f)
  v <- ncvar_get(nc, "npp"); nv <- ncvar_get(nc, "numberofvalidvalues"); nc_close(nc)
  v[!is.finite(v)] <- 0; nv[!is.finite(nv) | nv < 0] <- 0
  veg <- veg + nv * px / length(fs)
  npp <- npp + v * nv * px / length(fs)
}

# ---- report ----------------------------------------------------------
cat("\n=== WEIGHTED MEAN LATITUDE, three readings of \"where the land is\" ===\n")
cat(sprintf("  %-38s %10s %10s %12s\n", "weighting", "SH", "NH", "SH p2p"))
row <- function(lab, sh, nh) cat(sprintf("  %-38s %10.2f %10.2f %12.3f\n", lab, sh, nh, pp(sh)))
row("1. land AREA, Antarctica EXCLUDED", wmean_lat(land, elat, sh_noa), wmean_lat(land, elat, nh_all))
row("   land AREA, Antarctica included", wmean_lat(land, elat, sh_all), wmean_lat(land, elat, nh_all))
row("2. VEGETATED area (MOD17 valid px)", wmean_lat(veg, mlat, mlat < 0), wmean_lat(veg, mlat, mlat >= 0))
row("3. NPP (MOD17 flux)", wmean_lat(npp, mlat, mlat < 0), wmean_lat(npp, mlat, mlat >= 0))
cat(sprintf("\n  For comparison -- SHIPPED %.1f (p2p %.3f); shape-matched to the observed\n",
            CCX_SEAS_PHI_EFF[["SH"]], pp(CCX_SEAS_PHI_EFF[["SH"]])))
cat(sprintf("  8-day cycle -16.14 (p2p %.3f); amplitude-matched -32.15 (p2p %.3f).\n",
            pp(-16.14), pp(-32.15)))
cat("  Observed SH p2p (MOD17 psnnet) is 0.845.\n")
cat("\n  NOTE the direction of the gaps: deserts sit in the subtropics, so dropping\n")
cat("  them (1 -> 2) moves the latitude AWAY from the subtropics, and weighting by\n")
cat("  productivity rather than area (2 -> 3) moves it further still. \"Where the\n")
cat("  biomass is\" and \"where the land is\" are therefore NOT the same latitude,\n")
cat("  and the model's NEP term represents the former.\n")
