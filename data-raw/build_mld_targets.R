# =====================================================================
# build_mld_targets.R -- the OBSERVED mixed-layer thickness for `h_ml` (the
# low-latitude box) and, for the record, `h_hs` (the cold box), from the Holte
# et al. (2017) Argo climatology (2026-09-08; handoff 09-08b sec.2, tests T5/T6).
#
# WHY. Every HILDA round fits `h_ml` at ~40 m and `ent26` (column) at 134 m,
# and no observation had ever been put beside either. Neither de Boyer
# Montegut et al. 2004 nor Holte et al. 2017 prints a regional annual mean, so
# it is COMPUTED here from the monthly 1-deg product:
#   per cell: the ANNUAL MEAN of the 12 monthly bin-mean MLDs, and the ANNUAL
#             MAXIMUM of the same 12 (the winter maximum). A time-constant box
#             thickness can be argued either way -- the mean is the capacity
#             the air-sea flux acts on averaged over the year, the maximum is
#             the water that is ventilated at all -- and WHICH ONE IS THE
#             OBSERVATION FOR `h_ml` IS A RULING. Both are carried.
#   per region: cos(lat) area-weighted mean over the cells, the area-weighted
#             sd across cells as the representation spread of a one-box
#             thickness, plus the weighted median.
# The HS/LS boundary is DERIVED from the model's own `hs_frac`: a cap of
# fraction f of a hemisphere lies poleward of asin(1 - f), = 57.14 deg at 0.16.
# The boundary's sensitivity (50 / 55 / 60) and 20-deg zonal bands are printed
# so the reader can see how much of the LS number is the tropics.
#
# TWO MLD DEFINITIONS, both carried: `dt` = the density THRESHOLD (0.03 kg/m3
# from 10 m, de Boyer Montegut's criterion; the headline, comparable with the
# 2004 climatology) and `da` = Holte & Talley's hybrid ALGORITHM (shallower,
# finds the base of the truly mixed layer). The monthly BIN MEAN of profile MLDs
# is used (`mld_*_mean`); `mld_*_max` is the deepest single profile in the bin
# and is NOT the winter maximum of the climatology, so it is not used.
#
# COVERAGE. 46 % of (month, cell) entries are finite; only 18,611 of 34,887
# sampled cells have all 12 months. The headline uses the STRICT (12-month)
# cells so the annual mean carries no missing-season bias; the any-month
# variant is reported beside it. ⚠ At high latitude the two differ by ~40 m:
# ice-covered cells lack winter profiles (any-month biased SHALLOW) and the
# strict subset is the ice-free, mostly N. Atlantic, cells (biased DEEP). The
# HS number is therefore a bracket, not a value -- and the algebra says HS
# thickness is not a lever anyway ([[ccx_hs_endmember_is_kw]]).
#
# SOURCE. Holte J., Talley L.D., Gilson J., Roemmich D. (2017), GRL 44,
# 5618-5626, doi:10.1002/2017GL073426; product file dated 2022-04-14,
# manifest key `holte_mld_argo_clim` (data-raw/download_mld_clim.R).
# Usage: Rscript data-raw/build_mld_targets.R   -> data/obs_mld.rds
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
suppressMessages(library(ncdf4))
MLD_NC        <- ccx_path("data-raw", "downloads", "Argo_mixedlayers_monthlyclim_04142022.nc")
MLD_HS_FRAC   <- CCX_STRUCT_HILDA$hs_frac                     # 0.16, the model's own
MLD_LAT_HS    <- asin(1 - MLD_HS_FRAC) * 180 / pi              # DERIVED: 57.14 deg
MLD_LAT_SENS  <- c(50, 55, 60)
MLD_BANDS     <- list(c(0, 20), c(20, 40), c(40, MLD_LAT_HS), c(MLD_LAT_HS, 70), c(70, 90))
MLD_DEFS      <- c(dt = "density threshold (0.03 kg m-3 from 10 m)", da = "hybrid algorithm (Holte & Talley 2009)")
MLD_STATS     <- c(mean = "annual mean of the 12 monthly bin means", max = "annual maximum of the 12 monthly bin means")
MLD_STRICT_N  <- 12L                                          # months required for the headline cells
MLD_CITE      <- "Holte et al. (2017) GRL 44:5618-5626, doi:10.1002/2017GL073426; Argo_mixedlayers_monthlyclim_04142022.nc"

nc <- nc_open(MLD_NC)
lat <- ncvar_get(nc, "lat"); lon <- ncvar_get(nc, "lon")
arr <- lapply(names(MLD_DEFS), function(d) ncvar_get(nc, paste0("mld_", d, "_mean")))   # [12, 360, 180]
names(arr) <- names(MLD_DEFS); nc_close(nc)
stopifnot(all(dim(arr$dt) == c(12L, length(lon), length(lat))))
nmon <- apply(is.finite(arr$dt), c(2, 3), sum)
stopifnot(all(nmon == apply(is.finite(arr$da), c(2, 3), sum)))     # the two definitions share their coverage
W  <- matrix(cos(lat * pi / 180), length(lon), length(lat), byrow = TRUE)
L  <- matrix(abs(lat), length(lon), length(lat), byrow = TRUE)
cell <- function(d, stat) { x <- apply(arr[[d]], c(2, 3), stat, na.rm = TRUE); x[nmon == 0] <- NA; x }
FIELDS <- list(); for (d in names(MLD_DEFS)) for (s in names(MLD_STATS)) FIELDS[[paste(s, d, sep = "_")]] <- cell(d, s)

wstats <- function(x, m) {
  ok <- is.finite(x) & m; w <- W[ok] / sum(W[ok]); v <- x[ok]
  mu <- sum(w * v); o <- order(v); cw <- cumsum(w[o])
  list(value = mu, sd_cell = sqrt(sum(w * (v - mu)^2)), median = v[o][which(cw >= 0.5)[1]],
       q25 = v[o][which(cw >= 0.25)[1]], q75 = v[o][which(cw >= 0.75)[1]], n_cells = sum(ok))
}
region <- function(lo, hi, strict) L >= lo & L < hi & (if (strict) nmon == MLD_STRICT_N else nmon >= 1L)
one_region <- function(lo, hi, strict) lapply(FIELDS, wstats, m = region(lo, hi, strict))

out <- list(
  ls = one_region(0, MLD_LAT_HS, TRUE),  ls_anymonth = one_region(0, MLD_LAT_HS, FALSE),
  hs = one_region(MLD_LAT_HS, 90, TRUE), hs_anymonth = one_region(MLD_LAT_HS, 90, FALSE),
  boundary_sens = do.call(rbind, lapply(c(MLD_LAT_SENS, MLD_LAT_HS), function(b) data.frame(
    lat_bnd = b, ls_mean_dt = wstats(FIELDS$mean_dt, region(0, b, TRUE))$value, ls_max_dt = wstats(FIELDS$max_dt, region(0, b, TRUE))$value,
    hs_mean_dt = wstats(FIELDS$mean_dt, region(b, 90, TRUE))$value, hs_max_dt = wstats(FIELDS$max_dt, region(b, 90, TRUE))$value))),
  bands = do.call(rbind, lapply(MLD_BANDS, function(b) { r <- region(b[1], b[2], TRUE); data.frame(
    lat_lo = b[1], lat_hi = b[2], mean_dt = wstats(FIELDS$mean_dt, r)$value, max_dt = wstats(FIELDS$max_dt, r)$value,
    mean_da = wstats(FIELDS$mean_da, r)$value, n_cells = sum(is.finite(FIELDS$mean_dt) & r)) })),
  # THE SEASONAL SHAPE (added 2026-09-08d, options_2026-09-08d_seasonal_h_ml.md): per hemisphere, the
  # area-weighted monthly threshold MLD over the 12-month LS cells, and the PER-CELL entrainment
  # fraction f = (h_m - h_min)/h_m averaged the same way -- the dilution-honest driver for a derived
  # entrainment mechanism. `hmin` is each cell's own annual minimum.
  seasonal = local({ hmin <- apply(arr$dt, c(2, 3), min, na.rm = TRUE); hmin[nmon < MLD_STRICT_N] <- NA
    lat_signed <- matrix(lat, length(lon), length(lat), byrow = TRUE)
    one <- function(hem) { m <- nmon == MLD_STRICT_N & (if (hem == "NH") lat_signed >= 0 & lat_signed < MLD_LAT_HS else lat_signed < 0 & lat_signed > -MLD_LAT_HS)
      h <- vapply(1:12, function(k) { x <- arr$dt[k, , ]; ok <- is.finite(x) & m; sum(x[ok] * W[ok]) / sum(W[ok]) }, 0)
      f <- vapply(1:12, function(k) { x <- (arr$dt[k, , ] - hmin) / arr$dt[k, , ]; ok <- is.finite(x) & m; sum(x[ok] * W[ok]) / sum(W[ok]) }, 0)
      list(h_m = h, f_ent = f, h_mean = mean(h), h_max = max(h), month_max = which.max(h), f_max = max(f), f_min = min(f), n_cells = sum(m & is.finite(hmin))) }
    list(NH = one("NH"), SH = one("SH"), def = "dt; f_ent = per-cell (h_m - h_min)/h_m, cos-lat mean over 12-month LS cells") }),
  coverage = list(cells_sampled = sum(nmon >= 1), cells_strict = sum(nmon == MLD_STRICT_N), finite_frac = mean(is.finite(arr$dt))),
  consts = list(hs_frac = MLD_HS_FRAC, lat_hs = MLD_LAT_HS, strict_months = MLD_STRICT_N, defs = MLD_DEFS, stats = MLD_STATS,
                weighting = "cos(lat) per 1-deg cell; sd_cell = area-weighted sd across cells (representation spread)"),
  source = MLD_CITE, built = format(Sys.time(), "%Y-%m-%d %H:%M"))

cat(sprintf("Holte 2017 Argo MLD climatology: %d sampled cells, %d with all %d months (%.0f %% of entries finite)\n",
            out$coverage$cells_sampled, out$coverage$cells_strict, MLD_STRICT_N, 100 * out$coverage$finite_frac))
cat(sprintf("HS/LS boundary DERIVED from hs_frac %.2f: |lat| = %.2f deg\n\n", MLD_HS_FRAC, MLD_LAT_HS))
cat(sprintf("  %-12s %-9s | %7s %7s %7s %7s %7s %6s\n", "region", "field", "mean", "sd_cell", "median", "q25", "q75", "n"))
for (rg in c("ls", "ls_anymonth", "hs", "hs_anymonth")) for (f in names(FIELDS)) { r <- out[[rg]][[f]]
  cat(sprintf("  %-12s %-9s | %7.1f %7.1f %7.1f %7.1f %7.1f %6d\n", rg, f, r$value, r$sd_cell, r$median, r$q25, r$q75, r$n_cells)) }
cat("\n  boundary sensitivity (strict cells, threshold MLD):\n"); print(out$boundary_sens, row.names = FALSE, digits = 4)
cat("\n  zonal bands (strict cells):\n"); print(out$bands, row.names = FALSE, digits = 4)
for (hem in c("NH", "SH")) { z <- out$seasonal[[hem]]
  cat(sprintf("\n  seasonal %s: h_m %s | mean %.1f max %.1f (month %d); f_ent %s | %.3f-%.3f\n", hem, paste(sprintf("%.0f", z$h_m), collapse = " "), z$h_mean, z$h_max, z$month_max, paste(sprintf("%.2f", z$f_ent), collapse = " "), z$f_min, z$f_max)) }
cat(sprintf("\n  MODEL: h_ml fitted 39.8 (every HILDA round) / 134 (ent26 column); h_hs 400 (round 3).\n"))
saveRDS(out, ccx_path("data", "obs_mld.rds")); cat("saved data/obs_mld.rds\n")
