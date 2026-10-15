# =====================================================================
# build_hemi_diseq_targets.R -- the HEMISPHERIC air-sea d13C DISEQUILIBRIUM, from GLODAPv2.2023
# surface bottles (2026-09-20 t). The observation behind GATE D.
#
# WHY. The MLO-SPO d13C gradient miss is a constant -0.0668 permil offset that needs +64 GtC-permil/yr
# of NH-minus-SH isoflux ([[ccx_d13c_gradient_offset_additive]]); the ocean's meridional
# disequilibrium pattern (Quay et al. 2003 Fig. 8: tropics +1.8, poleward of ~50 deg -2) supplies most
# of it, and the model's two columns have the WRONG SIGN. Nothing in the objective or the gate set
# resolves the disequilibrium by hemisphere (gate Q is a global mean). This builds that observation
# from the data on disk, on Quay's own definition, rather than from a figure digitized by eye.
#
# DEFINITION (Quay 2003 para. 25): D = d13C of atmospheric CO2 EXPECTED at equilibrium with the
# surface water, minus the OBSERVED atmospheric d13C = d13C_DIC - eps_DIC-g(T) - d13C_atm, with
# eps from Zhang et al. (1995) as the model carries it (ALPHA_AS_ZHANG_*, ALPHA_AS_FCO3 held) and
# d13C_atm the Scripps station annual level of the bottle's hemisphere in the bottle's year (MLO
# for lat >= 0, SPO for lat < 0; the station-vs-zonal representation is ~0.03-0.07 permil, the
# atmospheric gradient itself, against a bottle spread of ~0.4).
#
# AGGREGATION. Bottles: flag 2, depth <= HD_SURF_M, year >= HD_YEAR_MIN (the station records start
# 1980), finite in-situ temperature. Cluster = (year, 5-deg lat band, 30-deg lon cell): the unit of
# independence (a cruise leg's bottles are one sample of the band). Band mean = mean of its cluster
# means. Hemisphere / region means weight the band means by the band's OCEAN AREA from the ERSSTv5
# land mask (cos(lat) x ocean fraction; an unsampled band gets no weight and is REPORTED as missing
# coverage). Two weightings are carried: AREA (the like-for-like statistic against a box model whose
# boxes ARE areas) and AREA x k (k ~ NCEP sig995 wind speed^2 climatology, Wanninkhof 1992 -- the
# weighting that turns D into an ISOFLUX; reported beside, not gated).
# REGIONS: |lat| < HD_LAT_HI = the model's mixed-layer column; |lat| >= HD_LAT_HI = its HS box, the
# same 55 deg split as build_hs_surface_targets.R.
# UNCERTAINTY: cluster bootstrap (HD_BOOT draws, seed HD_SEED, recorded in the artifact) of every
# weighted mean -- the sampling error of the mean over independent samples, band weights held.
# THE MODEL SIDE is evaluated at the same YEARS: the bottle-year histogram per region is stored so
# the gate averages the model's D over the same years the bottles sample (D drifts with the
# Suess rate, ~0.1 permil across the record).
# Output: data/obs_hemi_diseq.rds; the surface-c13 subset is cached in data-raw/downloads.
# Usage: Rscript data-raw/build_hemi_diseq_targets.R   (~2 min first time: one pass over the 895 MB master)
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
suppressPackageStartupMessages(library(ncdf4))
HD_MASTER   <- ccx_path("data-raw", "downloads", "GLODAPv2.2023_Merged_Master_File.csv")
HD_SUBSET   <- ccx_path("data-raw", "downloads", "glodap_c13_surface_subset.csv")
HD_ERSST    <- ccx_path("data-raw", "downloads", "ersst_v5_sst_mnmean.nc")
HD_NCEP     <- ccx_path("data-raw", "downloads", "ncep_r1_wspd.sig995.mon.mean.nc")
HD_OUT      <- ccx_path("data", "obs_hemi_diseq.rds")
HD_SURF_M   <- 50;  HD_FLAG_OK <- 2;  HD_YEAR_MIN <- 1980
HD_LAT_HI   <- 55                     # the HS / ML split, as build_hs_surface_targets.R
HD_BAND     <- 5;   HD_LON_CELL <- 30 # cluster geometry, degrees
HD_BOOT     <- 2000; HD_SEED <- 20260920
HD_ATM_STN  <- c(NH = "MLO", SH = "SPO")

# ---- [1] the bottles --------------------------------------------------
if (!file.exists(HD_SUBSET)) {
  cat("extracting surface c13 bottles from the master file (one pass)...\n")
  keep <- c(G2year = "year", G2month = "month", G2latitude = "lat", G2longitude = "lon", G2depth = "depth",
            G2temperature = "temp", G2c13 = "c13", G2c13f = "c13f")
  hdr <- strsplit(readLines(HD_MASTER, n = 1), ",")[[1]]; stopifnot(all(names(keep) %in% hdr))
  dt <- utils::read.csv(HD_MASTER, colClasses = ifelse(hdr %in% names(keep), "numeric", "NULL"))
  names(dt) <- keep[names(dt)]
  dt <- dt[is.finite(dt$c13) & dt$c13 > -900 & dt$depth <= HD_SURF_M, ]
  utils::write.csv(dt, HD_SUBSET, row.names = FALSE); cat(sprintf("written %s (%d surface c13 bottles)\n", HD_SUBSET, nrow(dt)))
}
b <- utils::read.csv(HD_SUBSET)
b <- b[b$c13f == HD_FLAG_OK & b$year >= HD_YEAR_MIN & is.finite(b$temp) & b$temp > -3, ]
b$hemi <- ifelse(b$lat >= 0, "NH", "SH")

# ---- [2] the atmosphere at the bottle's year and hemisphere --------------
d13 <- as.data.frame(readRDS(ccx_path("data", "obs_d13c_monthly.rds")))
atm <- lapply(HD_ATM_STN, function(st) { o <- d13[d13$station == st, ]; ccx_year_harmonic(o$decimal_date, o$d13c) })
b$d13c_atm <- NA_real_
for (h in HEMIS) { k <- b$hemi == h; b$d13c_atm[k] <- atm[[h]]$level[match(b$year[k], atm[[h]]$year)] }
b <- b[is.finite(b$d13c_atm), ]
# ---- [3] the disequilibrium per bottle ---------------------------------
eps_dicg <- function(T) ccx_const("ALPHA_AS_ZHANG_A") * T * ccx_const("ALPHA_AS_FCO3") + ccx_const("ALPHA_AS_ZHANG_B") * T + ccx_const("ALPHA_AS_ZHANG_C")
b$D <- b$c13 - eps_dicg(b$temp) - b$d13c_atm
b$band <- floor(b$lat / HD_BAND) * HD_BAND + HD_BAND / 2          # band center
b$cluster <- paste(b$year, b$band, floor(((b$lon + 180) %% 360) / HD_LON_CELL))
b$region <- ifelse(abs(b$band) > HD_LAT_HI, "hs", "ml")             # by BAND CENTER: the 55-deg split is a band edge, so a band is wholly one region
cat(sprintf("bottles: %d (flag %d, <= %d m, >= %d, T finite); clusters %d; years %d-%d (median %d)\n",
            nrow(b), HD_FLAG_OK, HD_SURF_M, HD_YEAR_MIN, length(unique(b$cluster)), min(b$year), max(b$year), as.integer(stats::median(b$year))))

# ---- [4] band weights: ocean area (ERSST mask) and k ~ wind^2 (NCEP) ------
nc <- nc_open(HD_ERSST); sst <- ncvar_get(nc, "sst", start = c(1, 1, 1), count = c(-1, -1, 12)); elat <- ncvar_get(nc, "lat"); nc_close(nc)
ocean <- apply(sst, c(1, 2), function(v) mean(is.finite(v)))          # ocean (ice-free-or-not) fraction per cell, 0/1
frac_by_lat <- apply(ocean, 2, mean)                                    # ocean fraction of each 2-deg latitude row
nc <- nc_open(HD_NCEP); w <- ncvar_get(nc, "wspd"); wlat <- ncvar_get(nc, "lat"); nc_close(nc)
wclim <- apply(w, c(1, 2), mean, na.rm = TRUE)                          # long-term mean wind speed per cell
u2_by_lat <- apply(wclim^2, 2, mean, na.rm = TRUE)                      # ~ k, per 2.5-deg row (over land too; a proxy)
band_w <- function(centre) {                                            # ocean area of a 5-deg band, and its k weight
  lo <- centre - HD_BAND / 2; hi <- centre + HD_BAND / 2
  ke <- elat > lo & elat <= hi; kw <- wlat > lo & wlat <= hi
  area <- mean(frac_by_lat[ke]) * (sin(hi * pi / 180) - sin(lo * pi / 180))
  c(area = area, k = mean(u2_by_lat[kw]))
}
bands <- sort(unique(b$band)); bw <- t(vapply(bands, band_w, numeric(2))); rownames(bw) <- bands
# the FULL area of each hemisphere/region (sampled or not), to report coverage
all_bands <- seq(-87.5, 87.5, by = HD_BAND); aw_all <- t(vapply(all_bands, band_w, numeric(2)))[, "area"]; names(aw_all) <- all_bands

# ---- [5] the weighted means, with a cluster bootstrap ---------------------
cm <- aggregate(D ~ cluster + band + hemi + region + year, b, mean)   # cluster means
band_mean <- function(x) { bm <- tapply(x$D, x$band, mean); bm }
wmean <- function(x, weight = c("area", "k")) {
  bm <- band_mean(x); ww <- bw[as.character(names(bm)), "area"]
  if (weight == "k") ww <- ww * bw[as.character(names(bm)), "k"]
  sum(ww * bm) / sum(ww)
}
sel <- function(h, reg = NULL) { k <- cm$hemi == h; if (!is.null(reg)) k <- k & cm$region == reg; cm[k, ] }
targets <- list(); set.seed(HD_SEED)
for (h in HEMIS) for (reg in c("all", "ml", "hs")) for (weight in c("area", "k")) {
  x <- if (reg == "all") sel(h) else sel(h, reg)
  if (!nrow(x)) next
  est <- wmean(x, weight)
  cl <- unique(x$cluster)
  boot <- replicate(HD_BOOT, { xs <- x[match(sample(cl, replace = TRUE), x$cluster), ]; wmean(xs, weight) })
  sampled <- as.numeric(names(band_mean(x)))
  full_bands <- all_bands[(if (h == "NH") all_bands > 0 else all_bands < 0) & (if (reg == "all") TRUE else if (reg == "hs") abs(all_bands) >= HD_LAT_HI else abs(all_bands) < HD_LAT_HI)]
  cov <- sum(aw_all[as.character(sampled)]) / sum(aw_all[as.character(full_bands)])
  targets[[paste(h, reg, weight, sep = "_")]] <- list(
    hemi = h, region = reg, weight = weight, mean = est, se = stats::sd(boot), n_bottles = sum(b$hemi == h & (reg == "all" | b$region == reg)),
    n_clusters = length(cl), bands = sampled, area_coverage = cov,
    years = as.integer(names(table(x$year))), year_weights = as.numeric(table(x$year)) / nrow(x))
  cat(sprintf("  %s %-3s %-4s  D %+.3f +- %.3f permil  (bottles %5d, clusters %4d, bands %2d, area coverage %.2f, years %d-%d)\n",
              h, reg, weight, est, stats::sd(boot), targets[[paste(h, reg, weight, sep = "_")]]$n_bottles, length(cl), length(sampled), cov, min(x$year), max(x$year)))
}
# the global mean, area x k weighted, to compare with Quay's 0.60 (their weighting, their 1995 adjustment absent here)
glob <- lapply(c(area = "area", k = "k"), function(weight) wmean(cm, weight))
cat(sprintf("global: area-weighted %+.3f, area x k weighted %+.3f  (Quay 2003: 0.88 area, 0.60 area x k, adjusted to 1995)\n", glob$area, glob$k))
asym <- list(area = targets$NH_all_area$mean - targets$SH_all_area$mean, k = targets$NH_all_k$mean - targets$SH_all_k$mean,
             se_area = sqrt(targets$NH_all_area$se^2 + targets$SH_all_area$se^2), se_k = sqrt(targets$NH_all_k$se^2 + targets$SH_all_k$se^2))
cat(sprintf("ASYMMETRY D_NH - D_SH: area %+.3f +- %.3f; area x k %+.3f +- %.3f permil\n", asym$area, asym$se_area, asym$k, asym$se_k))
# the ocean area poleward of HD_LAT_HI as a fraction of each hemisphere's ocean (for the hs_frac question), from the same mask
hs_area_frac <- vapply(HEMIS, function(h) { fb <- all_bands[if (h == "NH") all_bands > 0 else all_bands < 0]
  sum(aw_all[as.character(fb[abs(fb) >= HD_LAT_HI])]) / sum(aw_all[as.character(fb)]) }, 0)
cat(sprintf("ocean area poleward of %d deg as a fraction of the hemisphere's ocean (ERSST mask): NH %.3f, SH %.3f\n", HD_LAT_HI, hs_area_frac[["NH"]], hs_area_frac[["SH"]]))
out <- list(targets = targets, asym = asym, global = glob, hs_area_frac = hs_area_frac, band_weights = bw,
            consts = list(surf_m = HD_SURF_M, flag = HD_FLAG_OK, year_min = HD_YEAR_MIN, lat_hi = HD_LAT_HI, band = HD_BAND, lon_cell = HD_LON_CELL,
                          boot = HD_BOOT, seed = HD_SEED, atm_stations = HD_ATM_STN, eps = "Zhang 1995 via ALPHA_AS_ZHANG_*, ALPHA_AS_FCO3 held",
                          definition = "Quay 2003 para. 25: d13C_DIC - eps_DIC-g(T) - d13C_atm(station, year)"),
            provenance = list(master = basename(HD_MASTER), ersst = basename(HD_ERSST), ncep = basename(HD_NCEP), n_bottles = nrow(b), n_clusters = length(unique(b$cluster)),
                              seed = HD_SEED, seed_applied_to = "cluster bootstrap in [5], immediately before replicate()", built = format(Sys.time(), "%Y-%m-%d %H:%M")))
saveRDS(out, HD_OUT); cat(sprintf("saved %s\n", HD_OUT))
