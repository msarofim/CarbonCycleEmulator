# =====================================================================
# build_npp_ocean_seasonal_shape.R -- THE OBSERVATIONAL CROSS-CHECK on the
#   seasonal shape of ocean export: satellite NET PRIMARY PRODUCTION (Oregon
#   State Ocean Productivity, CbPM on MODIS, r2022, monthly, 1080 x 2160)
#   -> data/obs_npp_ocean_seasonal_shape.rds
#
# WHY. The O5 prior (data/obs_export_seasonal_shape_cmip6.rds) is a MODEL
# product. NPP from ocean colour is the observational-algorithm quantity
# nearest to export; the export/NPP ratio rises with NPP and falls with
# temperature (Laws 2011), so export is MORE seasonal than NPP -- this product
# is a LOWER BOUND on the export's seasonal amplitude, and a direct check on
# its PHASE. Same bands and estimator as the CMIP6 product (LS = |lat| < 57.14,
# HS = the rest, per hemisphere; first harmonic at month centres; the model's
# lag convention). Window 2003-2014 (MODIS full years, ending with CMIP6's).
# Files: cbpm.yyyyddd.hdf.gz, mg C m-2 d-1, HDF4, fill -9999, global 1/6 deg
# equirectangular (90N..90S, -180..180). Read with terra; area = cos(lat).
# ⚠ The site announced (2024-09-12) it has stopped updating; the archive is
# static. Downloads are cached under data-raw/downloads/cbpm/ (not committed).
# Run from the repo root:  Rscript data-raw/build_npp_ocean_seasonal_shape.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
suppressPackageStartupMessages(library(terra))
NP_BASE  <- "https://orca.science.oregonstate.edu/data/1x2/monthly/cbpm2.modis.r2022/hdf/"
NP_DIR   <- ccx_path("data-raw/downloads", "cbpm"); dir.create(NP_DIR, showWarnings = FALSE)
NP_YEARS <- 2003:2014
NP_HS_LAT <- 57.14
NP_FILL  <- -9999
NP_OUT   <- ccx_path("data", "obs_npp_ocean_seasonal_shape.rds")
NP_SERIES <- c("NH_LS", "SH_LS", "NH_HS", "SH_HS")
doy_start <- function(y, m) as.integer(format(as.Date(sprintf("%d-%02d-01", y, m)), "%j"))
# one accumulator per series per month: mean NPP-weighted total, PgC/yr
tot <- matrix(0, 12, length(NP_SERIES), dimnames = list(NULL, NP_SERIES)); cnt <- integer(12)
W <- NULL
for (y in NP_YEARS) for (m in 1:12) {
  fn <- sprintf("cbpm.%d%03d.hdf", y, doy_start(y, m)); gz <- file.path(NP_DIR, paste0(fn, ".gz")); hd <- file.path(NP_DIR, fn)
  if (!file.exists(hd)) {
    if (!file.exists(gz)) { ok <- tryCatch({ utils::download.file(paste0(NP_BASE, basename(gz)), gz, quiet = TRUE, mode = "wb"); TRUE }, error = function(e) FALSE)
      if (!ok) { cat(sprintf("  %s: download FAILED, skipped\n", fn)); next } }
    if (system2("gunzip", c("-f", shQuote(gz))) != 0) { cat(sprintf("  %s: gunzip FAILED, skipped\n", fn)); next }
  }
  r <- rast(hd); v <- values(r, mat = FALSE); v[v == NP_FILL | !is.finite(v)] <- NA
  if (is.null(W)) {   # geometry once: rows are latitude bands from 90N down, cols longitude
    nr <- nrow(r); nc <- ncol(r); lat_c <- 90 - (seq_len(nr) - 0.5) * 180 / nr
    dlat <- pi / nr; dlon <- 2 * pi / nc; R <- 6371000
    area_row <- R^2 * cos(lat_c * pi / 180) * dlat * dlon                       # m2 per cell, by row
    LAT <- matrix(lat_c, nr, nc); AREA <- matrix(area_row, nr, nc)
    W <- lapply(list(NH_LS = LAT > 0 & abs(LAT) < NP_HS_LAT, SH_LS = LAT < 0 & abs(LAT) < NP_HS_LAT,
                     NH_HS = LAT > 0 & abs(LAT) >= NP_HS_LAT, SH_HS = LAT < 0 & abs(LAT) >= NP_HS_LAT), function(mask) as.vector(t(AREA * mask)))
    cat(sprintf("grid %d x %d; LS area NH %.3g m2\n", nr, nc, sum(W$NH_LS)))
  }
  vv <- ifelse(is.na(v), 0, v)                                                   # mgC m-2 d-1; ice/no-data = 0 production
  for (s in NP_SERIES) tot[m, s] <- tot[m, s] + sum(vv * W[[s]]) * 1e-3 * 1e-15 * 365.25   # PgC/yr
  cnt[m] <- cnt[m] + 1L
  if (m == 12) cat(sprintf("  %d done\n", y))
}
clim <- sweep(tot, 1, pmax(cnt, 1L), "/")
harm <- function(cl, h) { mc <- (1:12 - 0.5) / 12; a <- 2 / 12 * sum(cl * cos(2 * pi * mc)); b <- 2 / 12 * sum(cl * sin(2 * pi * mc))
  mean <- mean(cl); peak <- (atan2(b, a) / (2 * pi) * 12) %% 12; lag <- ((peak - (if (h == "NH") 6.5 else 0.5) + 6) %% 12) - 6
  resid <- cl - mean - (a * cos(2 * pi * mc) + b * sin(2 * pi * mc))
  c(mean_PgC = mean, amp_rel = sqrt(a^2 + b^2) / mean, peak_month = peak, lag_mo = lag, rect = max(cl) / mean, frac_h1 = 1 - sum(resid^2) / sum((cl - mean)^2)) }
summ <- do.call(rbind, lapply(NP_SERIES, function(s) data.frame(series = s, t(harm(clim[, s], substr(s, 1, 2))), row.names = NULL)))
shape <- lapply(NP_SERIES, function(s) list(month = 1:12, value = clim[, s] / mean(clim[, s]))); names(shape) <- NP_SERIES
out <- list(summary = summ, clim_PgC = clim, shape = shape, years = NP_YEARS, n_months = cnt, hs_lat = NP_HS_LAT,
            product = "Oregon State Ocean Productivity, CbPM (Westberry et al. 2008) on MODIS, r2022, monthly 1080x2160, mg C m-2 d-1",
            source = NP_BASE, quantity = "NET PRIMARY PRODUCTION, not export: a LOWER bound on export seasonality (Laws 2011 e-ratio rises with NPP, falls with T); phase directly comparable",
            lag_convention = "R/model.R pump_seas_lag (NH peaks 6.5 + lag, SH 0.5 + lag)", built = format(Sys.time(), "%Y-%m-%d %H:%M"))
saveRDS(out, NP_OUT); cat(sprintf("wrote %s\n", NP_OUT)); print(summ, digits = 3)
for (s in NP_SERIES) cat(sprintf("%s shape: %s\n", s, paste(sprintf("%.2f", shape[[s]]$value), collapse = " ")))
