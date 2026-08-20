# =====================================================================
# build_npp_hemispheric.R -- OBSERVED NH/SH split of terrestrial NPP
#                            -> data/obs_npp_hemispheric.rds
#
# WHY THIS EXISTS. `npp_frac_NH` is the model's NH share of global NPP. It is
# FITTED, under a UNIFORM[0.4, 0.8] prior -- zero observational content -- and
# the 21-parameter mode puts it at 0.4662, i.e. 53 % of global NPP on the
# hemisphere that holds 19 % of the planet's land. The audit
# (calibration/diag_driver_audit.R block 2) flagged that; nothing on disk could
# check it. GFED is fire, OSCAR is land-use, GCB is the global sink -- none
# partitions NPP. This does.
#
# THE PRODUCT, chosen on Marcus' criterion of "well regarded but easy to
# download". MOD17 is the standard satellite NPP algorithm (Running/Zhao), and
# MOD17A3HGF C6.1 is its current gap-filled annual product. The LP DAAC
# original is 500 m sinusoidal HDF behind an Earthdata login; ICDC Hamburg
# republishes it regridded to a regular 0.5 deg grid in netCDF, CC-BY-4.0,
# NO REGISTRATION -- one 46 MB zip for 2001-2023.
#   Running SW, Zhao M (2021), MOD17A3HGF v061, NASA LP DAAC,
#     doi:10.5067/MODIS/MOD17A3HGF.061
#   ICDC regridded distribution: doi:10.25592/uhhfdm.14635 (Kern S, UHH/ICDC)
#
# WHAT THIS IS NOT. MOD17 is a SATELLITE-ERA product (2001-2023) and the model's
# `npp_frac_NH` is a PREINDUSTRIAL (1750) split. They are not the same quantity:
# two centuries of hemispherically asymmetric land clearing sit between them,
# and the model already represents that -- it scales npp0_h by (1 - cleared_h),
# which walks the realised share from 0.4662 to 0.4466 over 1750-2024. So the
# modern observation constrains the model's MODERN share, and the 1750 parameter
# only through that. The comparison must be made at the model's modern state,
# never against the raw parameter. Stated here because getting it backwards
# would look like agreement where there is none.
#
# THE AREA TRAP, found on the first run and fixed rather than tolerated. `npp`
# is the "grid cell mean" over the MODIS pixels that carry VALID data, NOT an
# average over the whole cell. Multiplying it by full 0.5 deg cell area assumes
# every cell is wholly vegetated and gave a global total of 65.1 PgC/yr, well
# above anything MOD17 publishes. The file carries its own fix:
# `numberofvalidvalues` counts contributing pixels, and because MOD17's native
# sinusoidal pixels are EQUAL-AREA, that count is proportional to valid area --
# 14400 at the equator, 7258 at 60 N (ratio 0.504 against cos 60 = 0.500). So
# valid area = nvalid * pixel area, with pixel area the equatorial cell area
# divided by 14400. That is exact and needs no land mask. Same class of error as
# the 41.9 %-of-the-globe "land" mask in build_seasonal_climatology.R: a cell is
# not the thing inside it.
#
# ALSO NOT: MOD17's global total is known to sit BELOW the ~60 GtC/yr the model
# carries as NPP_GLOBAL_PI (itself flagged `provisional`, "NEEDS a cited
# source"). This script therefore reports the SHARE, which is what the parameter
# is, and reports the total only as a gate on having read the file correctly.
#
# Usage:  Rscript data-raw/build_npp_hemispheric.R
# =====================================================================
suppressPackageStartupMessages(library(ncdf4))

NPP_DIR  <- "data-raw/downloads/mod17_npp"
NPP_OUT  <- "data/obs_npp_hemispheric.rds"
NPP_VAR  <- "npp"                      # kg C m-2 yr-1, grid-cell mean
NPP_R_EARTH <- 6371000                 # m, mean radius; areas are exact on a sphere
# MOD17's global annual NPP is around the mid-50s PgC/yr. This gate is wide: it
# exists to catch a unit error or a missing-value leak, not to referee the
# science. A run outside it has read the file wrong.
NPP_TOTAL_OK <- c(30, 80)              # PgC/yr
NPP_NVALID_FULL <- 14400               # `numberofvalidvalues` for a full cell
                                       # AT THE EQUATOR (the variable's own
                                       # valid_max); the count falls with cos(lat)
                                       # because MOD17 pixels are equal-area
# Latitude bands, matching build_seasonal_climatology.R so the two products can
# be read side by side.
NPP_BANDS <- list(all = 0, `>30` = 30, `>45` = 45)

fs <- list.files(NPP_DIR, pattern = "\\.nc$", recursive = TRUE, full.names = TRUE)
stopifnot(length(fs) > 10)
yrs <- as.integer(sub(".*__(\\d{4})0101__.*", "\\1", basename(fs)))
o <- order(yrs); fs <- fs[o]; yrs <- yrs[o]
cat(sprintf("%d annual files, %d-%d\n\n", length(fs), min(yrs), max(yrs)))

nc  <- nc_open(fs[1])
lat <- ncvar_get(nc, "lat"); lon <- ncvar_get(nc, "lon"); nc_close(nc)
# Cell area on a sphere: R^2 * dlon * (sin(lat_hi) - sin(lat_lo)). Exact, and it
# is the reason a naive cos(lat) weight is not used here -- the grid is regular
# and coarse enough that the difference is visible in the polar rows.
dlat <- abs(diff(lat)[1]); dlon <- abs(diff(lon)[1])
lat_hi <- (lat + dlat / 2) * pi / 180; lat_lo <- (lat - dlat / 2) * pi / 180
area_lat <- NPP_R_EARTH^2 * (dlon * pi / 180) * (sin(lat_hi) - sin(lat_lo))   # m2 per cell
area <- matrix(rep(area_lat, each = length(lon)), nrow = length(lon))
# One MODIS pixel's area, derived from the grid rather than typed in: the
# equatorial cell divided by the full-cell pixel count.
i_eq <- which.min(abs(lat))
px_area <- area_lat[i_eq] / NPP_NVALID_FULL
cat(sprintf("MODIS pixel area from the grid: %.0f m2 (%.1f m square; nominal MODIS 463.3 m)\n\n",
            px_area, sqrt(px_area)))

per_year <- lapply(seq_along(fs), function(i) {
  nc <- nc_open(fs[i]); v <- ncvar_get(nc, NPP_VAR)
  nv <- ncvar_get(nc, "numberofvalidvalues"); nc_close(nc)
  v[!is.finite(v)] <- NA; nv[!is.finite(nv) | nv < 0] <- 0
  va <- nv * px_area                      # VALID area per cell, m2
  # kg C m-2 * m2 -> kg C; /1e12 -> Pg C
  flux <- v * va / 1e12
  out <- list(year = yrs[i])
  for (bn in names(NPP_BANDS)) {
    b <- NPP_BANDS[[bn]]
    nh <- lat >= b; sh <- lat <= -b
    out[[paste0("NH_", gsub("[^A-Za-z0-9]", "", bn))]] <- sum(flux[, nh], na.rm = TRUE)
    out[[paste0("SH_", gsub("[^A-Za-z0-9]", "", bn))]] <- sum(flux[, sh], na.rm = TRUE)
  }
  out$area_NH <- sum(va[, lat >= 0], na.rm = TRUE)
  out$area_SH <- sum(va[, lat <  0], na.rm = TRUE)
  out
})
d <- do.call(rbind, lapply(per_year, function(x) as.data.frame(x)))
bkey <- function(bn) gsub("[^A-Za-z0-9]", "", bn)

tot <- d$NH_all + d$SH_all
if (mean(tot) < NPP_TOTAL_OK[1] || mean(tot) > NPP_TOTAL_OK[2])
  stop(sprintf("mean global NPP %.1f PgC/yr is outside the sanity gate [%g, %g] -- ",
               mean(tot), NPP_TOTAL_OK[1], NPP_TOTAL_OK[2]),
       "the file has been read wrong (units, fill value, or area).")

cat("=== GLOBAL TOTAL AND NH SHARE, per year ===\n")
cat(sprintf("  %-6s %10s %10s %10s %10s\n", "year", "NH PgC/yr", "SH PgC/yr", "global", "NH share"))
for (i in seq_len(nrow(d)))
  cat(sprintf("  %-6d %10.2f %10.2f %10.2f %10.4f\n",
              d$year[i], d$NH_all[i], d$SH_all[i], tot[i], d$NH_all[i] / tot[i]))
sh_all <- d$NH_all / tot
cat(sprintf("\n  MEAN over %d-%d: global %.2f PgC/yr | NH share %.4f (sd %.4f, range %.4f-%.4f)\n",
            min(yrs), max(yrs), mean(tot), mean(sh_all), stats::sd(sh_all),
            min(sh_all), max(sh_all)))
cat("  The sd is the answer to 'does this need to be time-varying?' over the\n")
cat("  satellite era. It says nothing about 1750-2000, where hemispherically\n")
cat("  asymmetric clearing is the whole story and the model already has a\n")
cat("  mechanism for it.\n")

cat("\n=== LATITUDE BANDS (share of global NPP in each hemisphere's band) ===\n")
for (bn in names(NPP_BANDS))
  cat(sprintf("  lat %-4s  NH %6.2f PgC/yr (%.4f of global)   SH %6.2f (%.4f)\n", bn,
              mean(d[[paste0("NH_", bkey(bn))]]), mean(d[[paste0("NH_", bkey(bn))]]) / mean(tot),
              mean(d[[paste0("SH_", bkey(bn))]]), mean(d[[paste0("SH_", bkey(bn))]]) / mean(tot)))

cat("\n=== PRODUCTIVITY PER UNIT VEGETATED AREA ===\n")
aN <- mean(d$area_NH); aS <- mean(d$area_SH)
cat(sprintf("  NH %.3fe14 m2 of VALID MODIS pixels, %.2f PgC/yr -> %.4f kgC/m2/yr\n",
            aN / 1e14, mean(d$NH_all), mean(d$NH_all) * 1e12 / aN))
cat(sprintf("  SH %.3fe14 m2 of VALID MODIS pixels, %.2f PgC/yr -> %.4f kgC/m2/yr\n",
            aS / 1e14, mean(d$SH_all), mean(d$SH_all) * 1e12 / aS))
cat(sprintf("  SH is %.2fx as productive per m2 as NH (the model's mode says 2.34x)\n",
            (mean(d$SH_all) / aS) / (mean(d$NH_all) / aN)))

out <- list(by_year = d, nh_share = sh_all,
            nh_share_mean = mean(sh_all), nh_share_sd = stats::sd(sh_all),
            global_mean_PgC = mean(tot), years = yrs, bands = NPP_BANDS,
            source = paste("MOD17A3HGF C6.1 (Running & Zhao, doi:10.5067/MODIS/MOD17A3HGF.061);",
                           "0.5 deg netCDF regrid by UHH/ICDC, doi:10.25592/uhhfdm.14635, CC-BY-4.0"),
            note = paste("SATELLITE ERA (2001-2023). npp_frac_NH is a PREINDUSTRIAL split;",
                         "compare against the model's MODERN realised share, which its own",
                         "hemispheric clearing produces, NOT against the raw parameter.",
                         "Built by data-raw/build_npp_hemispheric.R."))
saveRDS(out, NPP_OUT)
cat(sprintf("\nwrote %s\n", NPP_OUT))
