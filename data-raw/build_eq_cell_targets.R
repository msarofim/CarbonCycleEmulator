# =====================================================================
# build_eq_cell_targets.R -- the OBSERVED inputs and targets for the EQUATORIAL
# UPWELLING CELL (mirror boxes `NH_eq` / `SH_eq`), scoping sec.5 of
# notes/scoping_2026-09-13_equatorial_cell.md (2026-09-13 g; Marcus's rulings:
# the CELL, mirror cells with ONE parameter set, k_eq = layer 2, area-weighted
# surface reader).
#
# ONE product, six components + the W0 prior (w0_prior, the transport SOURCE), each with its own source and its own status
# (an OBSERVATION the cell is pinned to, a TARGET row/gate, or a CHECK):
#   eq_frac  the band's OCEAN area as a fraction of EACH hemisphere's ocean area
#            (the cell's area parameter -- PINNED to this, never fitted), from the
#            SOM-FFN land mask; both hemispheres, the widened control, and the
#            whole-band GLOBAL fraction B3 quoted (4.1 %).
#   h_eq     the band's mixed-layer thickness from Holte et al. 2017 (the cell's
#            thickness -- PINNED); annual mean and max, both MLD definitions,
#            strict 12-month cells, per hemisphere; the monthly shape for the
#            record (the first build has NO seasonal cycle on the cell).
#   sst_eq   the band's annual-mean SST from ERSSTv5 over the Nino3.4 base period,
#            and its Nino3.4 REGRESSION COEFFICIENT (the cell's OWN solubility
#            term: the cold tongue WARMS in El Nino -- wrong-signed locally, so
#            the cell carries both terms and their ratio is testable).
#   alk_eq   surface total alkalinity over the band, GLODAPv2.2023, flag 2,
#            <= 50 m (the cell's alkalinity -- PINNED), cluster sigma as in
#            build_hs_surface_targets.R.
#   dic_eq   the SOURCE-WATER contrast by depth bin (median DIC minus the 0-50 m
#            median) -- the observation k_eq was chosen against (CHANGELOG 09-13 f
#            inline; promoted to a product here), with the 5-30 deg column of
#            both hemispheres (the `ml_lo` analog) beside it.
#   b1       THE RESERVOIR: band annual pCO2 minus the global ocean mean (Fix B's
#            B1, +55.5 uatm at 09-04g), per hemisphere half (the asymmetry
#            sensitivity's number), the widened-mask control, and a SIGMA FLOOR.
#            ⚠ The climatology carries NO uncertainty field, so sigma here is the
#            MASK sensitivity (|widened - base|) with the month-to-month sd of
#            the contrast beside it; a tighter or looser sigma is a RULING.
#
# MASK. 5S-5N, 160E-80W -- the Fix B judgment (diag_gateS_indep_and_fixB.R,
# prereg'd 09-04g), which is the Nino3.4 latitude band over the cold-tongue
# longitudes. ⚠ THREE GRIDS, TWO LONGITUDE CONVENTIONS: SOM-FFN and Holte run
# -180..180, ERSST runs 0..360. `lon_mask()` normalizes both the axis and the
# window to 0..360 and GATES the selected span against the asked span -- the
# naive `160 <= lon <= 280` on a -180..180 axis silently selected 20 deg of warm
# pool at one sixth of the area (09-04g). Hemisphere halves are lat > 0 / lat < 0;
# a cell centered ON the equator (ERSST's lat 0) is counted in NEITHER half and
# in the whole band.
# Usage: Rscript data-raw/build_eq_cell_targets.R   -> data/obs_eq_cell.rds
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
suppressMessages(library(ncdf4))
EQ_LAT       <- c(-5, 5)               # the Nino3.4 band; hemisphere halves split at 0
EQ_LON       <- c(160, -80)            # 160E -> 80W, WRAPS the date line (west edge, east edge)
EQ_LON_WIDE  <- c(140, -70)            # the widened control (Fix B B1b)
EQ_ML_LO_LAT <- c(5, 30)               # the `ml_lo` analog column for the DIC contrast
EQ_SURF_M    <- 50; EQ_FLAG_OK <- 2; EQ_LON_BIN <- 10   # GLODAP conventions (build_hs_surface_targets.R)
EQ_DIC_BINS  <- c(0, 50, 100, 150, 200, 300, 400, 600, 1000, 6000)
EQ_SST_BASE  <- c(1991, 2020)          # the base period of ersst5.nino.mth.91-20 (forcing_enso.rds)
EQ_SST_REG   <- c(1948, 2024)          # the regression window; forcing_enso starts 1948
EQ_STRICT_N  <- 12L                    # Holte: months required (build_mld_targets.R)
EARTH_R      <- 6.371e6
FILES <- list(
  pco2 = ccx_path("data-raw", "downloads", "MPI-ULB-SOM_FFN_clim.nc"),
  mld  = ccx_path("data-raw", "downloads", "Argo_mixedlayers_monthlyclim_04142022.nc"),
  sst  = ccx_path("data-raw", "downloads", "ersst_v5_sst_mnmean.nc"),
  dic  = ccx_path("data-raw", "downloads", "glodap_dic_talk_subset.csv"),
  talk = ccx_path("data-raw", "downloads", "glodap_talk_subset.csv"),
  enso = ccx_path("data", "forcing_enso.rds"))
CITE <- list(
  pco2 = "Landschutzer, Laruelle, Roobaert & Regnier (2020) ESSD 12:2537-2553, doi:10.5194/essd-12-2537-2020; NCEI 0209633, doi:10.25921/qb25-f418 (MPI-ULB-SOM_FFN_clim.nc, monthly pCO2 climatology, no uncertainty field)",
  mld  = "Holte, Talley, Gilson & Roemmich (2017) GRL 44:5618-5626, doi:10.1002/2017GL073426; Argo_mixedlayers_monthlyclim_04142022.nc",
  sst  = "Huang et al. (2017) J. Climate 30:8179-8205, doi:10.1175/JCLI-D-16-0836.1; NOAA ERSSTv5 sst.mnmean.nc via NOAA PSL",
  glodap = "Lauvset et al. (2024) GLODAPv2.2023 (ESSD 16:2047-2072, doi:10.5194/essd-16-2047-2024); flag-2 bottle subsets in data-raw/downloads",
  enso = "NOAA CPC ersst5.nino.mth.91-20.ascii (Nino3.4 anomaly, 1991-2020 base) as carried in data/forcing_enso.rds")

# ---- shared geometry ------------------------------------------------
to360 <- function(x) x %% 360
# WRAP-AWARE longitude selector on EITHER axis convention, gating its own span.
lon_mask <- function(lon, w) {
  l <- to360(lon); a <- to360(w[1]); b <- to360(w[2])
  i <- if (a <= b) which(l >= a & l <= b) else which(l >= a | l <= b)
  span <- (b - a) %% 360; d <- abs(diff(sort(l))[1]); got <- length(i) * d
  if (abs(got - span) > 2 * d) stop(sprintf("lon_mask(): asked %.1f deg, selected %.1f -- the wrap is wrong", span, got))
  i
}
awt <- function(lat, dlat) abs(sin((lat + dlat / 2) * pi / 180) - sin((lat - dlat / 2) * pi / 180))
# Per-cell area matrix [lon, lat] in m2 for a regular grid.
cell_area <- function(lon, lat) {
  dlat <- abs(diff(lat)[1]); dlon <- abs(diff(lon)[1])
  matrix(rep(awt(lat, dlat) * (dlon / 360) * 2 * pi * EARTH_R^2, each = length(lon)), nrow = length(lon))
}
# Logical [lon, lat] mask for a lat window (lo, hi] and an optional lon window.
box_mask <- function(lon, lat, latw, lonw = NULL) {
  m <- matrix(FALSE, length(lon), length(lat))
  j <- which(lat > latw[1] & lat <= latw[2]); i <- if (is.null(lonw)) seq_along(lon) else lon_mask(lon, lonw)
  m[i, j] <- TRUE; m
}
HEMI_LAT <- list(NH = c(0, EQ_LAT[2]), SH = c(EQ_LAT[1], 0), both = EQ_LAT)   # (lo, hi], so lat 0 is SH on a grid that has it
wmean <- function(x, w, m) { ok <- is.finite(x) & m & is.finite(w); sum(x[ok] * w[ok]) / sum(w[ok]) }

# =====================================================================
cat("== eq_frac: the band's ocean area as a fraction of each hemisphere's ocean area (SOM-FFN mask)\n")
nc <- nc_open(FILES$pco2); plat <- ncvar_get(nc, "lat"); plon <- ncvar_get(nc, "lon"); pco2 <- ncvar_get(nc, "pco2")
patt <- ncatt_get(nc, "pco2"); nc_close(nc)
fv <- as.numeric(if (!is.null(patt[["_FillValue"]])) patt[["_FillValue"]] else patt$FillValue)  # a CHARACTER attribute -- ncdf4 does not apply it
stopifnot(is.finite(fv), fv < 0); pco2[pco2 <= fv + 1] <- NA_real_
ocean <- apply(is.finite(pco2), c(1, 2), all)          # a cell is ocean if the climatology reports all 12 months
fin <- mean(ocean); if (fin < 0.55 || fin > 0.78) stop(sprintf("pCO2 land mask implausible: %.3f finite", fin))
A_p <- cell_area(plon, plat)
hemi_ocean <- c(NH = sum(A_p[ocean & box_mask(plon, plat, c(0, 90))]), SH = sum(A_p[ocean & box_mask(plon, plat, c(-90, 0))]))
band_ocean <- function(lonw) vapply(HEMI_LAT, function(lw) sum(A_p[ocean & box_mask(plon, plat, lw, lonw)]), 0)
A_band <- band_ocean(EQ_LON); A_wide <- band_ocean(EQ_LON_WIDE)
eq_frac <- list(
  value = c(NH = unname(A_band["NH"] / hemi_ocean["NH"]), SH = unname(A_band["SH"] / hemi_ocean["SH"])),
  wide  = c(NH = unname(A_wide["NH"] / hemi_ocean["NH"]), SH = unname(A_wide["SH"] / hemi_ocean["SH"])),
  area_m2 = A_band, area_wide_m2 = A_wide, hemi_ocean_m2 = hemi_ocean,
  global_frac = unname(A_band["both"] / sum(hemi_ocean)),                          # B3's "4.1 % of the global ocean"
  model_hemi_ocean_m2 = c(NH = ccx_const("OCEAN_AREA_NH"), SH = ccx_const("OCEAN_AREA_SH")),
  frac_of_model_area = c(NH = unname(A_band["NH"] / ccx_const("OCEAN_AREA_NH")), SH = unname(A_band["SH"] / ccx_const("OCEAN_AREA_SH"))),
  def = "band ocean area (cells finite in all 12 months of the climatology) / the SAME product's hemispheric ocean area; lat (lo, hi], lon wrap-aware",
  source = CITE$pco2)
cat(sprintf("  product hemispheric ocean area  NH %.4e  SH %.4e m2 (model constants %.2e / %.2e, both 'provisional')\n",
            hemi_ocean["NH"], hemi_ocean["SH"], eq_frac$model_hemi_ocean_m2["NH"], eq_frac$model_hemi_ocean_m2["SH"]))
cat(sprintf("  band %gE->%gE, %g-%g: NH %.4e m2 = %.4f of NH ocean; SH %.4e = %.4f of SH ocean; whole band %.2f %% of the global ocean\n",
            EQ_LON[1], EQ_LON[2], EQ_LAT[1], EQ_LAT[2], A_band["NH"], eq_frac$value["NH"], A_band["SH"], eq_frac$value["SH"], 100 * eq_frac$global_frac))
cat(sprintf("  widened control %gE->%gE: NH %.4f  SH %.4f;  against the MODEL's area constants: NH %.4f  SH %.4f\n",
            EQ_LON_WIDE[1], EQ_LON_WIDE[2], eq_frac$wide["NH"], eq_frac$wide["SH"], eq_frac$frac_of_model_area["NH"], eq_frac$frac_of_model_area["SH"]))

# =====================================================================
cat("\n== b1: the reservoir -- band annual pCO2 minus the global ocean mean (SOM-FFN)\n")
band_pco2_monthly <- function(m) vapply(1:12, function(k) wmean(pco2[, , k], A_p, m & ocean), 0)
glob_m <- band_pco2_monthly(box_mask(plon, plat, c(-90, 90)))
b1_parts <- lapply(HEMI_LAT, function(lw) band_pco2_monthly(box_mask(plon, plat, lw, EQ_LON)))
b1_wide  <- band_pco2_monthly(box_mask(plon, plat, EQ_LAT, EQ_LON_WIDE))
contrast <- vapply(b1_parts, function(x) mean(x) - mean(glob_m), 0)
b1 <- list(
  value = unname(contrast["both"]), by_hemi = contrast[c("NH", "SH")],
  global_mean = mean(glob_m), band_mean = mean(b1_parts$both),
  wide = mean(b1_wide) - mean(glob_m),
  sd_mask = abs((mean(b1_wide) - mean(glob_m)) - contrast[["both"]]),   # the mask-sensitivity floor
  sd_month = stats::sd(b1_parts$both - glob_m),                          # month-to-month spread of the contrast
  monthly = b1_parts$both - glob_m,
  sigma_status = "RULING OWED: the product has no uncertainty field; sd_mask (|widened - base|) is a FLOOR, sd_month is the seasonal spread of an annual quantity (not an error)",
  def = "area-weighted annual mean pCO2 over the band minus the same over all ocean cells; monthly means first, then the 12-month mean",
  source = CITE$pco2)
cat(sprintf("  global %.2f  band %.2f  => contrast %+.2f uatm (NH half %+.2f, SH half %+.2f; SH - NH %+.2f)\n",
            b1$global_mean, b1$band_mean, b1$value, b1$by_hemi["NH"], b1$by_hemi["SH"], b1$by_hemi["SH"] - b1$by_hemi["NH"]))
cat(sprintf("  widened mask %+.2f (a %+.1f %% change) => sd_mask %.2f; month-to-month sd of the contrast %.2f (range %+.1f to %+.1f)\n",
            b1$wide, 100 * (b1$wide / b1$value - 1), b1$sd_mask, b1$sd_month, min(b1$monthly), max(b1$monthly)))

# =====================================================================
cat("\n== h_eq: the band's mixed-layer thickness (Holte 2017; strict 12-month cells)\n")
nc <- nc_open(FILES$mld); mlat <- ncvar_get(nc, "lat"); mlon <- ncvar_get(nc, "lon")
mld <- list(dt = ncvar_get(nc, "mld_dt_mean"), da = ncvar_get(nc, "mld_da_mean")); nc_close(nc)   # [12, lon, lat]
nmon <- apply(is.finite(mld$dt), c(2, 3), sum); strict <- nmon == EQ_STRICT_N
A_m <- cell_area(mlon, mlat)
h_one <- function(lw, lonw) {
  m <- box_mask(mlon, mlat, lw, lonw) & strict
  per <- lapply(mld, function(a) list(mean = apply(a, c(2, 3), mean), max = apply(a, c(2, 3), max), min = apply(a, c(2, 3), min)))
  out <- list(n_cells = sum(m), n_cells_any = sum(box_mask(mlon, mlat, lw, lonw) & nmon >= 1L))
  for (d in names(mld)) for (s in c("mean", "max", "min")) out[[paste(s, d, sep = "_")]] <- wmean(per[[d]][[s]], A_m, m)
  out$monthly_dt <- vapply(1:12, function(k) wmean(mld$dt[k, , ], A_m, m), 0)
  out
}
h_eq <- lapply(HEMI_LAT, h_one, lonw = EQ_LON); h_eq$wide <- h_one(EQ_LAT, EQ_LON_WIDE)
h_eq$def <- "cos-lat (area) weighted mean over strict 12-month cells of the per-cell annual mean / max / min of the monthly bin-mean MLD; dt = 0.03 kg/m3 threshold from 10 m (headline, comparable with build_mld_targets.R's h_ml), da = Holte-Talley algorithm"
h_eq$source <- CITE$mld
for (r in c("NH", "SH", "both", "wide")) { z <- h_eq[[r]]
  cat(sprintf("  %-4s n %3d (any-month %3d) | dt mean %5.1f max %5.1f min %5.1f | da mean %5.1f max %5.1f | monthly dt %s\n", r, z$n_cells, z$n_cells_any,
              z$mean_dt, z$max_dt, z$min_dt, z$mean_da, z$max_da, paste(sprintf("%.0f", z$monthly_dt), collapse = " "))) }
ml <- readRDS(ccx_path("data", "obs_mld.rds"))
cat(sprintf("  (the LS column's h_ml observation, same product: mean_dt %.1f, max_dt %.1f; hilda30c fits h_ml 65.2)\n", ml$ls$mean_dt$value, ml$ls$max_dt$value))

# =====================================================================
cat("\n== sst_eq: the band's annual-mean SST (ERSSTv5) and its Nino3.4 coefficient\n")
nc <- nc_open(FILES$sst); slat <- ncvar_get(nc, "lat"); slon <- ncvar_get(nc, "lon"); stime <- ncvar_get(nc, "time")
sst <- ncvar_get(nc, "sst"); nc_close(nc)                                   # [lon, lat, time]; missing_value already NA via ncdf4
sdate <- as.Date(stime, origin = "1800-01-01"); syear <- as.integer(format(sdate, "%Y")); smon <- as.integer(format(sdate, "%m"))
A_s <- cell_area(slon, slat)
sst_series <- function(lw, lonw) { m <- box_mask(slon, slat, lw, lonw); vapply(seq_along(stime), function(k) wmean(sst[, , k], A_s, m), 0) }
en <- as.data.frame(readRDS(FILES$enso)); en <- en[is.finite(en$nino34_anom), c("year", "month", "nino34_anom")]
sst_one <- function(lw, lonw) {
  ts <- data.frame(year = syear, month = smon, sst = sst_series(lw, lonw))
  base <- ts[ts$year >= EQ_SST_BASE[1] & ts$year <= EQ_SST_BASE[2], ]
  clim <- tapply(base$sst, base$month, mean)
  ts$anom <- ts$sst - clim[ts$month]
  mg <- merge(ts, en, by = c("year", "month")); mg <- mg[mg$year >= EQ_SST_REG[1] & mg$year <= EQ_SST_REG[2], ]
  fit_m <- stats::lm(anom ~ nino34_anom, data = mg)
  ann <- stats::aggregate(cbind(anom, nino34_anom) ~ year, data = mg, FUN = mean)
  fit_a <- stats::lm(anom ~ nino34_anom, data = ann)
  list(annual_mean_C = mean(clim), clim_monthly_C = as.numeric(clim), seas_amp_C = (max(clim) - min(clim)) / 2,
       beta_monthly = unname(coef(fit_m)[2]), se_monthly = summary(fit_m)$coefficients[2, 2], r_monthly = stats::cor(mg$anom, mg$nino34_anom), n_monthly = nrow(mg),
       beta_annual = unname(coef(fit_a)[2]), se_annual = summary(fit_a)$coefficients[2, 2], r_annual = stats::cor(ann$anom, ann$nino34_anom), n_annual = nrow(ann),
       annual = ann)
}
sst_eq <- lapply(HEMI_LAT, sst_one, lonw = EQ_LON); sst_eq$wide <- sst_one(EQ_LAT, EQ_LON_WIDE)
sst_eq$def <- sprintf("area-weighted band SST; annual mean and monthly climatology over %d-%d (the Nino3.4 base period); beta = OLS slope of the band's monthly (or annual-mean) SST anomaly on the Nino3.4 anomaly, %d-%d. ⚠ The index is ITSELF an ERSSTv5 band mean (5S-5N, 170-120W), so beta is not independent of the product; it is the cold tongue's share of the index's own swing, and it is the cell's OWN solubility term", EQ_SST_BASE[1], EQ_SST_BASE[2], EQ_SST_REG[1], EQ_SST_REG[2])
sst_eq$source <- paste(CITE$sst, "|", CITE$enso)
for (r in c("NH", "SH", "both", "wide")) { z <- sst_eq[[r]]
  cat(sprintf("  %-4s annual mean %.2f C (seasonal half-amp %.2f) | beta monthly %+.3f +/- %.3f K per index (r %+.2f, n %d) | annual %+.3f +/- %.3f (r %+.2f, n %d)\n",
              r, z$annual_mean_C, z$seas_amp_C, z$beta_monthly, z$se_monthly, z$r_monthly, z$n_monthly, z$beta_annual, z$se_annual, z$r_annual, z$n_annual)) }
cat("  (Fix B's B3 used a DECLARED NOMINAL of 27.0 C for the band's K0)\n")

# =====================================================================
cat("\n== alk_eq / dic_eq: GLODAPv2.2023 over the band (flag 2)\n")
d <- read.csv(FILES$dic)
# Bottle selector, the same wrap rule as lon_mask(): on the 0..360 axis 160E->80W is 160..280 and does NOT wrap.
in_lon <- function(lon, w) { l <- to360(lon); a <- to360(w[1]); b <- to360(w[2]); if (a <= b) l >= a & l <= b else l >= a | l <= b }
in_band <- function(df, lw, lonw) df$lat > lw[1] & df$lat <= lw[2] & in_lon(df$lon, lonw)
db <- d[in_band(d, EQ_LAT, EQ_LON), ]
row <- function(df, col) {                                # the HS-surface idiom: clusters = (year, 10-deg lon) cells
  x <- df[[col]]; cl <- paste(df$year, floor(to360(df$lon) / EQ_LON_BIN))
  cm <- tapply(x, cl, mean)
  list(target = stats::median(x), mean = mean(x), sd_w = stats::sd(x), n = length(x), n_eff = length(cm),
       sd_cluster = stats::sd(cm), sd = stats::sd(cm) / sqrt(length(cm)), epoch = stats::median(df$year), year_range = range(df$year))
}
alk_srf <- db[db$talkf == EQ_FLAG_OK & db$depth <= EQ_SURF_M, ]
alk_eq <- list(both = row(alk_srf, "talk"), NH = row(alk_srf[alk_srf$lat > 0, ], "talk"), SH = row(alk_srf[alk_srf$lat <= 0, ], "talk"))
tk <- read.csv(FILES$talk); tk <- tk[tk$talkf == EQ_FLAG_OK & tk$depth <= EQ_SURF_M & in_band(tk, EQ_LAT, EQ_LON), ]
alk_eq$talk_only_check <- list(median = stats::median(tk$talk), n = nrow(tk), note = "the talk-only subset (no year column, so unclustered) -- a check on the DIC-paired n")
alk_eq$model_const <- ccx_const("ALK_SURFACE") * 1e6
alk_eq$def <- sprintf("median surface (<= %g m) total alkalinity, flag %d, umol/kg; sd = sd(cluster means)/sqrt(n_clusters), sd_cluster = the representation spread (build_hs_surface_targets.R)", EQ_SURF_M, EQ_FLAG_OK)
alk_eq$source <- CITE$glodap
for (r in c("both", "NH", "SH")) { z <- alk_eq[[r]]
  cat(sprintf("  alk %-4s median %.1f (mean %.1f) umol/kg, bottle sd %.1f, n %d, clusters %d, cluster sd %.1f => sd %.2f; epoch %.0f [%d-%d]\n",
              r, z$target, z$mean, z$sd_w, z$n, z$n_eff, z$sd_cluster, z$sd, z$epoch, z$year_range[1], z$year_range[2])) }
cat(sprintf("  talk-only subset check: median %.1f, n %d | model ALK_SURFACE %.0f umol/kg (held fixed)\n", alk_eq$talk_only_check$median, alk_eq$talk_only_check$n, alk_eq$model_const))

dic_ok <- function(df) df[df$tco2f == EQ_FLAG_OK, ]
contrast_by_bin <- function(df) {
  b <- cut(df$depth, EQ_DIC_BINS, right = FALSE, include.lowest = TRUE)
  med <- tapply(df$tco2, b, stats::median); n <- tapply(df$tco2, b, length); n[is.na(n)] <- 0L
  data.frame(bin = levels(b), depth_lo = head(EQ_DIC_BINS, -1), depth_hi = tail(EQ_DIC_BINS, -1),
             median = as.numeric(med), n = as.integer(n), contrast = as.numeric(med) - med[[1]], row.names = NULL)
}
dic_band <- dic_ok(db)
ml_lo <- dic_ok(d[(d$lat > EQ_ML_LO_LAT[1] & d$lat <= EQ_ML_LO_LAT[2]) | (d$lat < -EQ_ML_LO_LAT[1] & d$lat >= -EQ_ML_LO_LAT[2]), ])
dic_eq <- list(band = contrast_by_bin(dic_band), band_NH = contrast_by_bin(dic_band[dic_band$lat > 0, ]), band_SH = contrast_by_bin(dic_band[dic_band$lat <= 0, ]),
               ml_lo_column = contrast_by_bin(ml_lo),
               surface = row(dic_band[dic_band$depth <= EQ_SURF_M, ], "tco2"),
               year_range = range(dic_band$year), n_band = nrow(dic_band),
               model_layers = "hilda30c layer 1 65-117 m (+46 over ML), layer 2 117-190 (+97), layer 3 190-292 (+135): T-A2 stage 1, CHANGELOG 09-13 f",
               def = sprintf("median DIC per depth bin minus the 0-%g m median, umol/kg, flag %d, RAW bottles %s -- the surface carries a ~50-yr anthropogenic smear (the deep does not), so the contrast is biased LOW by that smear; labelled, not corrected", EQ_SURF_M, EQ_FLAG_OK, paste(range(dic_band$year), collapse = "-")),
               source = CITE$glodap)
cat(sprintf("  DIC band: %d bottles %d-%d; surface median %.1f (n %d)\n", dic_eq$n_band, dic_eq$year_range[1], dic_eq$year_range[2], dic_eq$surface$target, dic_eq$surface$n))
cat(sprintf("  %-12s %8s %6s | %8s %6s | %8s %6s | %8s %6s\n", "bin m", "band", "n", "NH half", "n", "SH half", "n", "5-30 col", "n"))
for (i in seq_len(nrow(dic_eq$band))) cat(sprintf("  %-12s %+8.1f %6d | %+8.1f %6d | %+8.1f %6d | %+8.1f %6d\n", dic_eq$band$bin[i],
  dic_eq$band$contrast[i], dic_eq$band$n[i], dic_eq$band_NH$contrast[i], dic_eq$band_NH$n[i], dic_eq$band_SH$contrast[i], dic_eq$band_SH$n[i], dic_eq$ml_lo_column$contrast[i], dic_eq$ml_lo_column$n[i]))

# =====================================================================
out <- list(eq_frac = eq_frac, b1 = b1, h_eq = h_eq, sst_eq = sst_eq, alk_eq = alk_eq, dic_eq = dic_eq,
            consts = list(lat = EQ_LAT, lon = EQ_LON, lon_wide = EQ_LON_WIDE, ml_lo_lat = EQ_ML_LO_LAT, surf_m = EQ_SURF_M, flag = EQ_FLAG_OK,
                          lon_bin = EQ_LON_BIN, dic_bins = EQ_DIC_BINS, sst_base = EQ_SST_BASE, sst_reg = EQ_SST_REG, strict_months = EQ_STRICT_N,
                          hemi_split = "lat > 0 is NH, lat <= 0 is SH (a cell centred on the equator counts as SH; ERSST has one such row)"),
            scope = "notes/scoping_2026-09-13_equatorial_cell.md sec.5; rulings 2026-09-13 g: cell, mirror cells one parameter set, k_eq = 2, area-weighted surface reader, w_eq fitted with the Meinen prior, B1 sigma = sd_mask, h_eq = mean; prereg notes/prereg_2026-09-13g_equatorial_cell_build.md",
            # THE TRANSPORT SOURCE (09-13 g): the prior on the cell's mean upwelling W0 = `w_eq`, carried HERE so
            # calibrate.R reads it through a loader and never types the number (the ccx_u_hs_prior idiom).
            w0_prior = list(mean_sv = 27, sd_sv = 3, range_sv = c(24, 30),
                            def = "mean vertical transport across 50 m, 5S-5N: 24 +/- 3 Sv over 155-95W (1993-96) and ~30 Sv over 165E-95W (= ~60 Sv Ekman divergence half cancelled by geostrophic convergence); mean w 0.24e-5 m/s = 76 m/yr. Prior centre = the midpoint of the two boxes, sd = the stated +/- 3",
                            interannual = list(p2p_sv = 50, def = "peak-to-peak cross-isotherm transport change between the 1997-98 El Nino and 1998-99 La Nina, 8S-8N (Meinen & McPhaden 2001, as quoted by Meinen et al. 2001)",
                                               nino34_p2p_monthly = 3.49, nino34_p2p_annual = 2.00, per_index_sv = c(14, 25),
                                               note = "on forcing_enso.rds's index: Jan 1998 +1.75 to Jan 1999 -1.74 monthly; 1997 +0.84 to 1999 -1.16 on annual means. Like-for-like caveats both ways (monthly p2p over-states an annual slope; the 8-deg box adds Sv)"),
                            historical = "Quay et al. 1983 (bomb-14C budget) 26 +/- 7 Sv; Johnson et al. 2001 57 +/- 16 Sv (includes 1997-99); Kessler 2006 Prog. Oceanogr. 69:181-217 review: 30-50 Sv east-central Pacific",
                            source = "Meinen C.S., McPhaden M.J., Johnson G.C. (2001) Vertical velocities and transports in the equatorial Pacific during 1993-99. J. Phys. Oceanogr. 31:3230-3248 (text extracted from the PMEL scan)"),
            built = format(Sys.time(), "%Y-%m-%d %H:%M"))
saveRDS(out, ccx_path("data", "obs_eq_cell.rds")); cat("\nsaved data/obs_eq_cell.rds\n")
