# =====================================================================
# diag_tr_box_bound_sensitivity.R -- 2026-09-14 (d). RULING R2's MEASUREMENT.
# The tropical surface box `tr` (prereg 09-14c, option T1) needs a bound. The
# candidates: the climatological annual-mean SST isotherm (25 / 26 / 27 C) and
# a fixed +/-20 deg. For each, per hemisphere: the box's ocean area as a fraction
# of the hemisphere (the eq_frac idiom, cell area REMOVED as D1 removes it from
# the ML), its area-weighted annual-mean SST, the RESIDUAL mixed layer's mean SST
# (0-57.14 deg minus tr minus eq -- the number sst_NH/SH must become), the full
# 0-57.14 mean (what 18 / 16 should have been), HS's mean (vs sst_hs 2), and the
# Holte MLD (dt) mean over tr and over the residual ML (the h_ml prior's and
# seas_ml's driver on the new masks). Same products as build_eq_cell_targets.R:
# ERSSTv5 (1991-2020 climatology, the Nino3.4 base) and the Argo/Holte MLD
# climatology; areas on each product's own grid. Nothing is written to data/.
# =====================================================================
suppressMessages({ library(ncdf4); source("tests/testthat/setup.R", chdir = TRUE) })
COMMIT <- ccx_git_stamp()
TR_ISO      <- c(25, 26, 27)            # candidate isotherms, degC (annual-mean climatology)
TR_LAT_FIX  <- 20                       # the fixed-latitude control
TR_CLIM     <- c(1991, 2020)            # the Nino3.4 base period (build_eq_cell_targets.R EQ_SST_BASE)
TR_LS_LAT   <- asin(1 - CCX_STRUCT_HILDA$hs_frac) * 180 / pi   # 57.14: the LS/HS split (build_mld_targets.R)
EQ_LAT <- c(-5, 5); EQ_LON <- c(160, -80)                       # the cell's mask (build_eq_cell_targets.R)
EARTH_R <- 6371e3
FILES <- list(sst = ccx_path("data-raw", "downloads", "ersst_v5_sst_mnmean.nc"),
              mld = ccx_path("data-raw", "downloads", "Argo_mixedlayers_monthlyclim_04142022.nc"))
OUT <- ccx_path("outputs", "diagnostics", sprintf("tr_box_bound_sensitivity_%s", format(Sys.Date(), "%Y%m%d")))
to360 <- function(x) x %% 360
awt <- function(lat, dlat) abs(sin((lat + dlat / 2) * pi / 180) - sin((lat - dlat / 2) * pi / 180))
cell_area <- function(lon, lat) { dlat <- abs(diff(lat)[1]); dlon <- abs(diff(lon)[1])
  matrix(rep(awt(lat, dlat) * (dlon / 360) * 2 * pi * EARTH_R^2, each = length(lon)), nrow = length(lon)) }
in_lon <- function(lon, w) { l <- to360(lon); a <- to360(w[1]); b <- to360(w[2]); if (a <= b) l >= a & l <= b else l >= a | l <= b }
box_mask <- function(lon, lat, latw, lonw = NULL) { m <- matrix(FALSE, length(lon), length(lat))
  j <- which(lat > latw[1] & lat <= latw[2]); i <- if (is.null(lonw)) seq_along(lon) else which(in_lon(lon, lonw)); m[i, j] <- TRUE; m }
wmean <- function(x, w, m) { ok <- is.finite(x) & m & is.finite(w); sum(x[ok] * w[ok]) / sum(w[ok]) }

# ---- SST climatology on the ERSST grid ------------------------------------
nc <- nc_open(FILES$sst); slat <- ncvar_get(nc, "lat"); slon <- ncvar_get(nc, "lon"); stime <- ncvar_get(nc, "time")
sst <- ncvar_get(nc, "sst"); nc_close(nc)
sdate <- as.Date(stime, origin = "1800-01-01"); syear <- as.integer(format(sdate, "%Y"))
k <- which(syear >= TR_CLIM[1] & syear <= TR_CLIM[2]); stopifnot(length(k) == 12 * diff(TR_CLIM) + 12)
clim <- apply(sst[, , k], c(1, 2), mean)                   # annual-mean climatology [lon, lat]; NA = land
ocean_s <- is.finite(clim); A_s <- cell_area(slon, slat)
hemi <- list(NH = c(0, 90), SH = c(-90, 0))
hemi_A <- vapply(hemi, function(lw) sum(A_s[ocean_s & box_mask(slon, slat, lw)]), 0)
cat(sprintf("ERSST grid %d x %d; ocean fraction %.3f; hemispheric ocean area NH %.4g / SH %.4g m2 (product: 1.543e14 / 2.064e14; model OCEAN_AREA_* %.3g / %.3g)\n",
            length(slon), length(slat), mean(ocean_s), hemi_A[["NH"]], hemi_A[["SH"]], ccx_const("OCEAN_AREA_NH"), ccx_const("OCEAN_AREA_SH")))
eq_m <- box_mask(slon, slat, EQ_LAT, EQ_LON) & ocean_s
ls_m <- lapply(hemi, function(lw) box_mask(slon, slat, c(max(lw[1], -TR_LS_LAT), min(lw[2], TR_LS_LAT))) & ocean_s)
hs_m <- lapply(hemi, function(lw) box_mask(slon, slat, lw) & ocean_s & !box_mask(slon, slat, c(-TR_LS_LAT, TR_LS_LAT)))
# ---- MLD climatology on the Argo grid --------------------------------------
nc <- nc_open(FILES$mld); mlat <- ncvar_get(nc, "lat"); mlon <- ncvar_get(nc, "lon"); mld_dt <- ncvar_get(nc, "mld_dt_mean"); nc_close(nc)   # [12, lon, lat]
strict <- apply(is.finite(mld_dt), c(2, 3), sum) == 12L; mld_mean <- apply(mld_dt, c(2, 3), mean); A_m <- cell_area(mlon, mlat)
# the SST isotherm mask re-expressed on the MLD grid by nearest ERSST cell
near <- function(x, grid) vapply(x, function(v) which.min(abs(grid - v)), integer(1))
mi <- near(mlon %% 360, slon %% 360); mj <- near(mlat, slat)
on_mld_grid <- function(m_s) m_s[mi, mj]

cases <- c(setNames(lapply(TR_ISO, function(T) list(kind = "isotherm", T = T)), sprintf("iso%g", TR_ISO)),
           list(lat20 = list(kind = "lat", lat = TR_LAT_FIX)))
rows <- list()
cat(sprintf("\n%-8s %-3s %8s %8s %8s | %8s %8s %8s | %8s %8s\n", "bound", "hemi", "tr_frac", "tr_SST", "resid_ML", "LS_SST", "HS_SST", "eq_SST", "MLD_tr", "MLD_resid"))
for (nm in names(cases)) { cs <- cases[[nm]]
  tr_all <- if (cs$kind == "isotherm") (clim >= cs$T) & ocean_s else box_mask(slon, slat, c(-cs$lat, cs$lat)) & ocean_s
  tr_all <- tr_all & box_mask(slon, slat, c(-TR_LS_LAT, TR_LS_LAT))    # inside the LS domain by construction
  for (h in names(hemi)) {
    H <- box_mask(slon, slat, hemi[[h]])
    tr <- tr_all & H & !eq_m; eqh <- eq_m & H; res <- ls_m[[h]] & !tr_all & !eq_m
    tr_mld <- on_mld_grid(tr) & strict; res_mld <- on_mld_grid(res) & strict
    r <- data.frame(bound = nm, hemi = h,
      tr_frac = sum(A_s[tr]) / hemi_A[[h]], tr_sst = wmean(clim, A_s, tr), resid_ml_sst = wmean(clim, A_s, res),
      ls_sst = wmean(clim, A_s, ls_m[[h]]), hs_sst = wmean(clim, A_s, hs_m[[h]]), eq_sst = wmean(clim, A_s, eqh),
      eq_frac = sum(A_s[eqh]) / hemi_A[[h]], resid_frac = sum(A_s[res]) / hemi_A[[h]],
      mld_tr = wmean(mld_mean, A_m, tr_mld), mld_resid = wmean(mld_mean, A_m, res_mld),
      lat_edge = if (cs$kind == "isotherm") { j <- which(apply(tr, 2, any)); if (h == "NH") max(slat[j]) else min(slat[j]) } else cs$lat * (if (h == "NH") 1 else -1))
    rows[[length(rows) + 1]] <- r
    cat(sprintf("%-8s %-3s %8.4f %8.2f %8.2f | %8.2f %8.2f %8.2f | %8.1f %8.1f   (tr reaches %+.0f deg; eq_frac %.4f)\n", nm, h,
                r$tr_frac, r$tr_sst, r$resid_ml_sst, r$ls_sst, r$hs_sst, r$eq_sst, r$mld_tr, r$mld_resid, r$lat_edge, r$eq_frac))
  }
}
tab <- do.call(rbind, rows)
cat(sprintf("\nmodel today: sst_NH/SH 18 / 16 (typed), sst_hs 2, sst_eq 27.04 (this climatology, NOT re-based to 1850-1900 -- the SST anomaly forcing is on 1850-1900); LS Holte h_ml obs mean 59.7\n"))
cat("the isotherm sensitivity, tr_frac and tr_sst, 25 -> 27 C:\n"); for (h in c("NH", "SH")) { z <- tab[tab$hemi == h & grepl("iso", tab$bound), ]
  cat(sprintf("  %s: tr_frac %s; tr_sst %s; residual ML SST %s\n", h, paste(sprintf("%.3f", z$tr_frac), collapse = " / "), paste(sprintf("%.2f", z$tr_sst), collapse = " / "), paste(sprintf("%.2f", z$resid_ml_sst), collapse = " / "))) }
saveRDS(list(table = tab, iso = TR_ISO, lat_fix = TR_LAT_FIX, clim = TR_CLIM, ls_lat = TR_LS_LAT, hemi_area = hemi_A, files = FILES,
             commit = COMMIT, date = Sys.time()), paste0(OUT, ".rds"))
write.csv(tab, paste0(OUT, ".csv"), row.names = FALSE)
cat("saved", paste0(OUT, ".{rds,csv}"), "\n")
