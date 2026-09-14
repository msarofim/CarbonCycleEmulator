# =====================================================================
# build_tr_box_targets.R -- the TROPICAL SURFACE BOX `tr` (2026-09-14 d/e):
# the second build of the equatorial-cell arc (prereg 09-14c, option T1,
# rulings R1-R4 of 09-14 d; the 26 C isotherm = Marcus 09-14 e, "move forward
# with recommendations"). Produces data/obs_tr_box.rds for the `hilda_tr`
# structure label: the box's OBSERVED geometry and every surface SST the label
# uses, on ONE grid and ONE temperature base.
#
# THE BOX: the ocean where the 1991-2020 annual-mean SST climatology (ERSSTv5,
# the Nino3.4 base period) is >= TR_ISO_C, inside the LS domain (|lat| <= 57.14,
# HILDA's hs_frac 0.16), MINUS the equatorial cell's band (D1's idiom: the cell
# takes its area from the surface box it sits in). Mirror boxes NH_tr / SH_tr,
# one parameter set (the cell's precedent). The RESIDUAL mixed layer = LS minus
# tr minus eq -- its SST and MLD are what `sst_NH/SH` and the h_ml products
# must become under this label (measured 09-14 d: 17.7 / 16.1 C at 26 C, the
# typed 18 / 16 within 0.3 C).
#
# PROVENANCE RULES (09-14 d): (i) areas on the SOM-FFN 1-deg grid, the grid
# that gave eq_frac (ERSST's 2-deg cells over-count coastal ocean by 3.5 %);
# SST regridded to it by nearest cell. (ii) EVERY surface SST re-based to
# 1850-1900 -- the SST anomaly forcing (data/forcing_sst.rds, HadSST4) is on
# that base, and a climatological mean used as a PI base runs the box ~0.7 C
# warm today (the first build's sst_eq 27.04 did exactly that; hilda_eq keeps
# it, documented; hilda_tr reads the re-based cell SST from THIS product).
# The isotherm MASK is defined on the raw climatology (the region that is warm
# TODAY); only the temperatures carried into the model are re-based.
# Nothing is typed: every number below is computed from the downloads in
# data-raw/downloads (MANIFEST.csv) or read from a sibling product.
# =====================================================================
suppressMessages({ library(ncdf4); source("tests/testthat/setup.R", chdir = TRUE) })
TR_ISO_C     <- 26                     # RULED 09-14 e (the recommended value of the 09-14 d measurement)
TR_CLIM      <- c(1991, 2020)          # ERSST climatology = the Nino3.4 base period (EQ_SST_BASE)
TR_PI_BASE   <- c(1850, 1900)          # the SST anomaly forcing's base (build_sst_forcing.R)
TR_SST_REG   <- c(1948, 2024)          # the Nino3.4 regression window (EQ_SST_REG)
TR_LS_LAT    <- asin(1 - CCX_STRUCT_HILDA$hs_frac) * 180 / pi   # 57.14, DERIVED (build_mld_targets.R)
EQ_LAT <- c(-5, 5); EQ_LON <- c(160, -80)                      # the cell's band (build_eq_cell_targets.R)
TR_SURF_M <- 50; TR_FLAG_OK <- 2; TR_LON_BIN <- 10               # GLODAP conventions (build_hs_surface_targets.R)
TR_STRICT_N <- 12L                                              # Holte: months required
EARTH_R <- 6371e3
FILES <- list(
  pco2 = ccx_path("data-raw", "downloads", "MPI-ULB-SOM_FFN_clim.nc"),
  mld  = ccx_path("data-raw", "downloads", "Argo_mixedlayers_monthlyclim_04142022.nc"),
  sst  = ccx_path("data-raw", "downloads", "ersst_v5_sst_mnmean.nc"),
  dic  = ccx_path("data-raw", "downloads", "glodap_dic_talk_subset.csv"),
  enso = ccx_path("data", "forcing_enso.rds"),
  sstf = ccx_path("data", "forcing_sst.rds"),
  eq   = ccx_path("data", "obs_eq_cell.rds"))
CITE <- list(
  pco2 = "Landschuetzer, Gruber & Bakker (2020) MPI-ULB-SOM_FFN_clim, monthly climatology 1985-2015 (NCEI); data-raw/downloads/MANIFEST.csv",
  mld  = "Holte, Talley, Gilson & Roemmich (2017) GRL 44:5618; Argo mixed-layer monthly climatology 2022-04-14 (mld_dt_mean)",
  sst  = "Huang et al. (2017) ERSSTv5, J. Climate 30:8179; ersst_v5_sst_mnmean.nc (NOAA PSL)",
  sstf = "HadSST.4.2.0.0 hemispheric annual anomalies re-based to 1850-1900 (data-raw/build_sst_forcing.R)",
  enso = "NOAA CPC ersst5.nino.mth.91-20 Nino3.4 anomaly (data/forcing_enso.rds)",
  glodap = "Lauvset et al. (2024) GLODAPv2.2023 (ESSD 16:2047-2072); flag-2 bottle subsets in data-raw/downloads")
OUT <- ccx_path("data", "obs_tr_box.rds")

to360 <- function(x) x %% 360
awt <- function(lat, dlat) abs(sin((lat + dlat / 2) * pi / 180) - sin((lat - dlat / 2) * pi / 180))
cell_area <- function(lon, lat) { dlat <- abs(diff(lat)[1]); dlon <- abs(diff(lon)[1])
  matrix(rep(awt(lat, dlat) * (dlon / 360) * 2 * pi * EARTH_R^2, each = length(lon)), nrow = length(lon)) }
in_lon <- function(lon, w) { l <- to360(lon); a <- to360(w[1]); b <- to360(w[2]); if (a <= b) l >= a & l <= b else l >= a | l <= b }
box_mask <- function(lon, lat, latw, lonw = NULL) { m <- matrix(FALSE, length(lon), length(lat))
  j <- which(lat > latw[1] & lat <= latw[2]); i <- if (is.null(lonw)) seq_along(lon) else which(in_lon(lon, lonw)); m[i, j] <- TRUE; m }
wmean <- function(x, w, m) { ok <- is.finite(x) & m & is.finite(w); sum(x[ok] * w[ok]) / sum(w[ok]) }
near <- function(x, grid) vapply(x, function(v) which.min(abs(grid - v)), integer(1))
HEMI <- list(NH = c(0, 90), SH = c(-90, 0))

# ---- the area grid: SOM-FFN 1 deg, ocean = all 12 months finite -----------------
cat("== grid and areas (SOM-FFN 1 deg)\n")
nc <- nc_open(FILES$pco2); plat <- ncvar_get(nc, "lat"); plon <- ncvar_get(nc, "lon"); pco2 <- ncvar_get(nc, "pco2")
patt <- ncatt_get(nc, "pco2"); nc_close(nc)
fv <- as.numeric(if (!is.null(patt[["_FillValue"]])) patt[["_FillValue"]] else patt$FillValue); stopifnot(is.finite(fv), fv < 0)
pco2[pco2 <= fv + 1] <- NA_real_
ocean <- apply(is.finite(pco2), c(1, 2), all); A_p <- cell_area(plon, plat)
hemi_A <- vapply(HEMI, function(lw) sum(A_p[ocean & box_mask(plon, plat, lw)]), 0)
eqo <- readRDS(FILES$eq)
stopifnot(abs(hemi_A[["NH"]] / 1.543e14 - 1) < 0.01, abs(hemi_A[["SH"]] / 2.064e14 - 1) < 0.01)   # the eq product's own areas
cat(sprintf("  hemispheric ocean NH %.4g / SH %.4g m2 (= the eq_frac grid); model OCEAN_AREA_* %.3g / %.3g (provisional)\n",
            hemi_A[["NH"]], hemi_A[["SH"]], ccx_const("OCEAN_AREA_NH"), ccx_const("OCEAN_AREA_SH")))

# ---- SST: ERSSTv5 climatology, regridded; the PI re-base -------------------------
cat("== SST (ERSSTv5) and the 1850-1900 re-base (HadSST4)\n")
nc <- nc_open(FILES$sst); slat <- ncvar_get(nc, "lat"); slon <- ncvar_get(nc, "lon"); stime <- ncvar_get(nc, "time")
sst <- ncvar_get(nc, "sst"); nc_close(nc)
sdate <- as.Date(stime, origin = "1800-01-01"); syear <- as.integer(format(sdate, "%Y")); smon <- as.integer(format(sdate, "%m"))
kc <- which(syear >= TR_CLIM[1] & syear <= TR_CLIM[2]); stopifnot(length(kc) == 12 * (diff(TR_CLIM) + 1))
clim_s <- apply(sst[, , kc], c(1, 2), mean)                        # [lon, lat] on the ERSST grid
pi_ <- near(plon %% 360, slon %% 360); pj <- near(plat, slat)
clim <- clim_s[pi_, pj]                                             # nearest-cell regrid to the SOM-FFN grid
A_s <- cell_area(slon, slat)
fs <- as.data.frame(readRDS(FILES$sstf))
rebase <- vapply(c("NH", "SH"), function(h) -mean(fs[[paste0("sst_anom_", h)]][fs$year >= TR_CLIM[1] & fs$year <= TR_CLIM[2]]), 0)
stopifnot(all(is.finite(rebase)), all(abs(rebase + 0.7) < 0.15))    # the 09-14 d measurement: -0.70 both
cat(sprintf("  re-base %d-%d -> %d-%d: NH %+.3f / SH %+.3f C (HadSST4 hemispheric anomaly, sign flipped)\n", TR_CLIM[1], TR_CLIM[2], TR_PI_BASE[1], TR_PI_BASE[2], rebase[["NH"]], rebase[["SH"]]))

# ---- the masks ----------------------------------------------------------------------
LS  <- box_mask(plon, plat, c(-TR_LS_LAT, TR_LS_LAT)) & ocean
EQ  <- box_mask(plon, plat, EQ_LAT, EQ_LON) & ocean
TRa <- is.finite(clim) & (clim >= TR_ISO_C) & LS
masks <- lapply(HEMI, function(lw) { H <- box_mask(plon, plat, lw)
  list(tr = TRa & H & !EQ, eq = EQ & H, ml = LS & H & !TRa & !EQ, ls = LS & H, hs = ocean & H & !LS) })
# the eq_frac cross-check: this grid's cell area must be the eq product's (same grid, same mask)
for (h in names(HEMI)) stopifnot(abs(sum(A_p[masks[[h]]$eq]) / hemi_A[[h]] / eqo$eq_frac$value[[h]] - 1) < 1e-6)

geom <- lapply(names(HEMI), function(h) { m <- masks[[h]]; rb <- rebase[[h]]
  j <- which(apply(m$tr, 2, any)); edge <- if (h == "NH") max(plat[j]) else min(plat[j])
  list(tr_frac = sum(A_p[m$tr]) / hemi_A[[h]], ml_frac = sum(A_p[m$ml]) / hemi_A[[h]], eq_frac = sum(A_p[m$eq]) / hemi_A[[h]],
       hs_frac = sum(A_p[m$hs]) / hemi_A[[h]],
       sst_tr_clim = wmean(clim, A_p, m$tr), sst_ml_clim = wmean(clim, A_p, m$ml), sst_eq_clim = wmean(clim, A_p, m$eq),
       sst_ls_clim = wmean(clim, A_p, m$ls), sst_hs_clim = wmean(clim, A_p, m$hs),
       sst_tr_pi = wmean(clim, A_p, m$tr) + rb, sst_ml_pi = wmean(clim, A_p, m$ml) + rb, sst_eq_pi = wmean(clim, A_p, m$eq) + rb,
       lat_edge = edge, area_tr_m2 = sum(A_p[m$tr]), area_ml_m2 = sum(A_p[m$ml]), hemi_ocean_m2 = hemi_A[[h]])
}); names(geom) <- names(HEMI)
cat(sprintf("  %-3s tr_frac %.4f (to %+.0f deg) ml_frac %.4f eq_frac %.4f hs_frac %.4f | clim SST tr %.2f ml %.2f eq %.2f ls %.2f hs %.2f | PI-based tr %.2f ml %.2f eq %.2f\n",
            names(geom), sapply(geom, `[[`, "tr_frac"), sapply(geom, `[[`, "lat_edge"), sapply(geom, `[[`, "ml_frac"), sapply(geom, `[[`, "eq_frac"), sapply(geom, `[[`, "hs_frac"),
            sapply(geom, `[[`, "sst_tr_clim"), sapply(geom, `[[`, "sst_ml_clim"), sapply(geom, `[[`, "sst_eq_clim"), sapply(geom, `[[`, "sst_ls_clim"), sapply(geom, `[[`, "sst_hs_clim"),
            sapply(geom, `[[`, "sst_tr_pi"), sapply(geom, `[[`, "sst_ml_pi"), sapply(geom, `[[`, "sst_eq_pi")), sep = "")
cat(sprintf("  model today: sst_NH/SH %g / %g (typed, treated as PI), sst_hs %g, hilda_eq's sst_eq %.2f (clim, NOT re-based)\n",
            ccx_default_params()$sst_NH, ccx_default_params()$sst_SH, CCX_STRUCT_HILDA$sst_hs, eqo$sst_eq$both$annual_mean_C))
# ⚠ FINDING (09-14 e): the OCEAN poleward of 57.14 deg is 12.6 % / 13.0 % of each hemisphere's
# ocean, not hs_frac's 0.16 -- 57.14 was derived as the latitude poleward of which 16 % of a
# uniform SPHERE lies (build_mld_targets.R), and the ocean is not uniform in latitude. The
# HILDA structure's HS area is therefore ~25 % larger than the ocean inside its own mask.
# Recorded here, NOT changed (a structural constant of every registered mode; a ruling).
cat(sprintf("  ⚠ ocean poleward of %.2f deg = %.3f / %.3f of each hemisphere's ocean vs hs_frac %.2f (derived on a uniform sphere)\n",
            TR_LS_LAT, geom$NH$hs_frac, geom$SH$hs_frac, CCX_STRUCT_HILDA$hs_frac))

# ---- the tropical box's SST response to Nino3.4 (the cell's idiom, on the tr mask) ----
cat("== the box's Nino3.4 SST coefficient (for the R side to rule on; the ML uses the hemispheric anomaly only)\n")
en <- as.data.frame(readRDS(FILES$enso)); en <- en[is.finite(en$nino34_anom), c("year", "month", "nino34_anom")]
tr_s <- lapply(names(HEMI), function(h) masks[[h]]$tr[near(slon %% 360, plon %% 360), near(slat, plat)]); names(tr_s) <- names(HEMI)   # the mask back on the ERSST grid
sst_one <- function(m) {
  ts <- data.frame(year = syear, month = smon, sst = vapply(seq_along(stime), function(k) wmean(sst[, , k], A_s, m), 0))
  base <- ts[ts$year >= TR_CLIM[1] & ts$year <= TR_CLIM[2], ]; cm <- tapply(base$sst, base$month, mean); ts$anom <- ts$sst - cm[ts$month]
  mg <- merge(ts, en, by = c("year", "month")); mg <- mg[mg$year >= TR_SST_REG[1] & mg$year <= TR_SST_REG[2], ]
  fm <- stats::lm(anom ~ nino34_anom, data = mg); ann <- stats::aggregate(cbind(anom, nino34_anom) ~ year, data = mg, FUN = mean); fa <- stats::lm(anom ~ nino34_anom, data = ann)
  list(annual_mean_C = mean(cm), clim_monthly_C = as.numeric(cm), seas_amp_C = (max(cm) - min(cm)) / 2,
       beta_monthly = unname(coef(fm)[2]), se_monthly = summary(fm)$coefficients[2, 2], r_monthly = stats::cor(mg$anom, mg$nino34_anom), n_monthly = nrow(mg),
       beta_annual = unname(coef(fa)[2]), se_annual = summary(fa)$coefficients[2, 2], r_annual = stats::cor(ann$anom, ann$nino34_anom), n_annual = nrow(ann))
}
sst_tr <- lapply(tr_s, sst_one)
for (h in names(HEMI)) { z <- sst_tr[[h]]
  cat(sprintf("  %s: ERSST-grid annual mean %.2f C (seasonal half-amp %.2f) | beta monthly %+.3f +/- %.3f K per index (r %+.2f) | annual %+.3f +/- %.3f (r %+.2f)  [cell: %+.3f]\n",
              h, z$annual_mean_C, z$seas_amp_C, z$beta_monthly, z$se_monthly, z$r_monthly, z$beta_annual, z$se_annual, z$r_annual, eqo$sst_eq$both$beta_monthly)) }

# ---- MLD (Holte dt) over tr and over the RESIDUAL mixed layer --------------------------
cat("== Holte MLD over tr and the residual ML (the h_ml / seas_ml products' new masks)\n")
nc <- nc_open(FILES$mld); mlat <- ncvar_get(nc, "lat"); mlon <- ncvar_get(nc, "lon"); mld_dt <- ncvar_get(nc, "mld_dt_mean"); nc_close(nc)   # [12, lon, lat]
nmon <- apply(is.finite(mld_dt), c(2, 3), sum); strict <- nmon == TR_STRICT_N; A_m <- cell_area(mlon, mlat)
mi <- near(mlon %% 360, plon %% 360); mj <- near(mlat, plat)
h_one <- function(m_p) { m <- m_p[mi, mj] & strict
  per <- list(mean = apply(mld_dt, c(2, 3), mean), max = apply(mld_dt, c(2, 3), max), min = apply(mld_dt, c(2, 3), min))
  c(list(n_cells = sum(m)), lapply(per, function(a) wmean(a, A_m, m)), list(monthly = vapply(1:12, function(k) wmean(mld_dt[k, , ], A_m, m), 0))) }
h_tr <- lapply(names(HEMI), function(h) h_one(masks[[h]]$tr)); names(h_tr) <- names(HEMI)
h_ml <- lapply(names(HEMI), function(h) h_one(masks[[h]]$ml)); names(h_ml) <- names(HEMI)
h_tr$both <- h_one(masks$NH$tr | masks$SH$tr); h_ml$both <- h_one(masks$NH$ml | masks$SH$ml)
mlo <- readRDS(ccx_path("data", "obs_mld.rds"))
for (h in c("NH", "SH", "both")) cat(sprintf("  %-4s tr: n %4d mean %5.1f max %5.1f min %5.1f | residual ML: n %4d mean %5.1f max %5.1f min %5.1f   (today's LS: mean %.1f max %.1f)\n",
  h, h_tr[[h]]$n_cells, h_tr[[h]]$mean, h_tr[[h]]$max, h_tr[[h]]$min, h_ml[[h]]$n_cells, h_ml[[h]]$mean, h_ml[[h]]$max, h_ml[[h]]$min, mlo$ls$mean_dt$value, mlo$ls$max_dt$value))

# ---- pCO2: the box minus the global surface (a CHECK target, the B1 construction) -------
cat("== pCO2 climatology: tr minus the global surface (SOM-FFN), the B1 construction -- a CHECK, not a row\n")
pco2_ann <- apply(pco2, c(1, 2), mean)
glob <- wmean(pco2_ann, A_p, ocean)
pco2_tr <- lapply(names(HEMI), function(h) list(mean = wmean(pco2_ann, A_p, masks[[h]]$tr), minus_global = wmean(pco2_ann, A_p, masks[[h]]$tr) - glob,
                                                 ml_minus_global = wmean(pco2_ann, A_p, masks[[h]]$ml) - glob)); names(pco2_tr) <- names(HEMI)
pco2_tr$both <- list(mean = wmean(pco2_ann, A_p, TRa & !EQ), minus_global = wmean(pco2_ann, A_p, TRa & !EQ) - glob, global = glob,
                     eq_minus_global = wmean(pco2_ann, A_p, EQ) - glob)
cat(sprintf("  global surface %.1f uatm; tr NH %+.1f / SH %+.1f / both %+.1f; residual ML NH %+.1f / SH %+.1f; the cell %+.1f (B1 %+.1f in the eq product)\n",
            glob, pco2_tr$NH$minus_global, pco2_tr$SH$minus_global, pco2_tr$both$minus_global, pco2_tr$NH$ml_minus_global, pco2_tr$SH$ml_minus_global, pco2_tr$both$eq_minus_global, eqo$b1$value))

# ---- GLODAP: alkalinity and surface DIC in the box --------------------------------------
cat("== GLODAPv2.2023 over the box (flag 2, <= 50 m)\n")
d <- read.csv(FILES$dic)
in_mask <- function(df, m_p) { i <- near(to360(df$lon), plon %% 360); j <- near(df$lat, plat); m_p[cbind(i, j)] }
row <- function(df, col) { x <- df[[col]]; cl <- paste(df$year, floor(to360(df$lon) / TR_LON_BIN)); cm <- tapply(x, cl, mean)
  list(target = stats::median(x), mean = mean(x), sd_w = stats::sd(x), n = length(x), n_eff = length(cm),
       sd_cluster = stats::sd(cm), sd = stats::sd(cm) / sqrt(length(cm)), epoch = stats::median(df$year), year_range = range(df$year)) }
srf <- d[d$depth <= TR_SURF_M, ]
alk_tr <- list(); dic_tr <- list()
for (h in c("NH", "SH", "both")) { m <- if (h == "both") TRa & !EQ else masks[[h]]$tr
  a <- srf[srf$talkf == TR_FLAG_OK & in_mask(srf, m), ]; c2 <- srf[srf$tco2f == TR_FLAG_OK & in_mask(srf, m), ]
  alk_tr[[h]] <- row(a, "talk"); dic_tr[[h]] <- row(c2, "tco2")
  cat(sprintf("  %-4s alk median %.1f (n %d, clusters %d, sd %.2f) | DIC median %.1f (n %d, sd %.2f)\n", h, alk_tr[[h]]$target, alk_tr[[h]]$n, alk_tr[[h]]$n_eff, alk_tr[[h]]$sd, dic_tr[[h]]$target, dic_tr[[h]]$n, dic_tr[[h]]$sd)) }
alk_tr$model_const <- ccx_const("ALK_SURFACE") * 1e6; alk_tr$def <- "median surface (<= 50 m) total alkalinity, flag 2, umol/kg, bottles inside the tr mask; sd = sd(cluster means)/sqrt(n_clusters)"
cat(sprintf("  (the cell: alk %.1f, surface DIC %.1f; model ALK_SURFACE %.0f)\n", eqo$alk_eq$both$target, eqo$dic_eq$surface$target, alk_tr$model_const))

# ---- write ----------------------------------------------------------------------------
obs <- list(
  iso_C = TR_ISO_C, clim = TR_CLIM, pi_base = TR_PI_BASE, rebase_C = rebase, ls_lat = TR_LS_LAT,
  geom = geom,
  tr_frac = list(value = c(NH = geom$NH$tr_frac, SH = geom$SH$tr_frac), def = sprintf("ocean area where the %d-%d annual-mean ERSSTv5 SST >= %g C, inside |lat| <= %.2f, MINUS the equatorial cell's band, as a fraction of the hemisphere's ocean area on the SOM-FFN 1-deg grid (the eq_frac grid)", TR_CLIM[1], TR_CLIM[2], TR_ISO_C, TR_LS_LAT)),
  ml_frac = list(value = c(NH = geom$NH$ml_frac, SH = geom$SH$ml_frac), def = "the RESIDUAL mixed layer: LS minus tr minus eq, same grid"),
  sst = list(tr = c(NH = geom$NH$sst_tr_pi, SH = geom$SH$sst_tr_pi), ml = c(NH = geom$NH$sst_ml_pi, SH = geom$SH$sst_ml_pi), eq = c(NH = geom$NH$sst_eq_pi, SH = geom$SH$sst_eq_pi),
             clim = list(tr = c(NH = geom$NH$sst_tr_clim, SH = geom$SH$sst_tr_clim), ml = c(NH = geom$NH$sst_ml_clim, SH = geom$SH$sst_ml_clim), eq = c(NH = geom$NH$sst_eq_clim, SH = geom$SH$sst_eq_clim),
                         ls = c(NH = geom$NH$sst_ls_clim, SH = geom$SH$sst_ls_clim), hs = c(NH = geom$NH$sst_hs_clim, SH = geom$SH$sst_hs_clim)),
             def = sprintf("area-weighted annual-mean SST over each mask, %d-%d climatology, RE-BASED to %d-%d by the HadSST4 hemispheric anomaly (rebase_C); `clim` = un-re-based. The model's carbonate routine sees sst + forcing anomaly (on the same base)", TR_CLIM[1], TR_CLIM[2], TR_PI_BASE[1], TR_PI_BASE[2]),
             source = paste(CITE$sst, "|", CITE$sstf)),
  sst_enso = c(sst_tr, list(def = "the box's OLS SST-anomaly slope on the Nino3.4 anomaly, the cell's idiom (build_eq_cell_targets.R); recorded for the R side to RULE on -- the ML uses the hemispheric anomaly only", source = paste(CITE$sst, "|", CITE$enso))),
  h_tr = c(h_tr, list(def = "Holte dt MLD over the tr mask: area-weighted mean over strict 12-month cells of the per-cell annual mean / max / min, and the monthly means", source = CITE$mld)),
  h_ml_resid = c(h_ml, list(def = "the SAME over the RESIDUAL mixed layer (LS minus tr minus eq): what obs_mld$ls and the h_ml prior become under hilda_tr", source = CITE$mld, today_ls = c(mean_dt = mlo$ls$mean_dt$value, max_dt = mlo$ls$max_dt$value))),
  pco2 = c(pco2_tr, list(def = "SOM-FFN annual-mean pCO2 over the mask minus the global surface mean -- the B1 construction, a CHECK target (no likelihood row is ruled for it)", source = CITE$pco2)),
  alk_tr = alk_tr, dic_tr = c(dic_tr, list(def = "median surface DIC in the box (PT6's check), umol/kg", source = CITE$glodap)),
  files = FILES, cite = CITE, built = list(script = "data-raw/build_tr_box_targets.R", date = Sys.time(),
                                           commit = tryCatch(system("git rev-parse --short HEAD", intern = TRUE), error = function(e) NA)))
saveRDS(obs, OUT)
cat("\nwrote", OUT, "\n")
