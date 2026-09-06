# =====================================================================
# build_hs_exchange_factor.R -- the cold box's air-sea exchange factor FROM
# OBSERVATIONS AND A LAW (2026-09-06; prereg_2026-09-07 sec.4, the owed pin).
#
# The model's `hs_asx_frac` multiplies the high-latitude surface box's gas
# exchange AREA; the piston velocity `k_w` is one fitted number per unit area
# for the whole ocean. So the observational counterpart of `hs_asx_frac` is the
# ratio of the per-area transfer velocity over the cold area (annual-mean SST
# below HX_SST_CUT) to that over the warm area, with
#     k = 0.251 <U^2> (Sc/660)^-1/2 x (1 - ice)      (Wanninkhof 2014 eq. 4;
#                                                     ice: no exchange through it)
# so  factor = <(1 - sic) U^2 Sc^-1/2>_HS / <U^2 Sc^-1/2>_LL, area- and
# month-weighted. HILDA's assumption is that this is 1 (ice cancels the winds);
# the Schmidt term is NOT in HILDA's argument and is the piece a fitted `k_w`
# for the warm box cannot supply to the cold one.
#
# Inputs (MANIFEST.csv): ersst_v5_monthly (SST, the mask, 2 deg), hadisst_ice
# (sea-ice concentration, 1 deg, block-averaged to 2 deg), ncep_wspd_sig995
# (monthly-mean |U| at sigma 0.995, 2.5 deg, nearest cell). Everything is
# formed on ERSST's 2 deg grid with cos(lat) area weights.
# ⚠ |U| is a monthly MEAN at ~40 m: <U^2> over the month exceeds <U>^2 by the
# gustiness factor (1.27 for a Rayleigh distribution, Wanninkhof 2014), and
# 10 m winds are weaker than sigma-0.995 winds. Both enter HS and LL alike and
# cancel in the RATIO to first order; the residual is stated, not corrected.
# Output: data/obs_hs_exchange_factor.rds (+ the printed table).
#
# Run from the repo root:  Rscript data-raw/build_hs_exchange_factor.R
# =====================================================================
suppressPackageStartupMessages(library(ncdf4))
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)

HX_SST_CUT   <- 5                       # degC, HILDA's HS definition (annual-mean SST < 5)
HX_WIN       <- c(1981, 2010)           # headline window: satellite-era ice, WMO normal
HX_WINS      <- list(c(1981, 2010), c(1991, 2020), c(1979, 1998), c(1961, 1990))
HX_SST_HS_MODEL <- 2                    # the model's sst_hs, for the Schmidt term at the model's own T
HX_SC_REF    <- 660                     # Wanninkhof's reference Schmidt number (label only; cancels)
HX_OCEAN_FRAC_BAND <- c(0.65, 0.75)     # sanity band on the ERSST ocean-area fraction
HX_LL_OW_MIN <- 0.98                    # the warm box must be (nearly) ice-free, or the mask is wrong
HX_HILDA_HS_FRAC <- 0.16                # HILDA's value, for the comparison line only
HX_OUT <- ccx_path("data", "obs_hs_exchange_factor.rds")
DL <- ccx_path("data-raw", "downloads")
F_SST <- file.path(DL, "ersst_v5_sst_mnmean.nc")
F_ICE <- file.path(DL, "HadISST_ice.nc")
F_WND <- file.path(DL, "ncep_r1_wspd.sig995.mon.mean.nc")
SC <- vapply(c("A", "B", "C", "D", "E"), function(k) ccx_const(paste0("SC_CO2_W14_", k)), 0)
schmidt <- function(t) SC[["A"]] + SC[["B"]] * t + SC[["C"]] * t^2 + SC[["D"]] * t^3 + SC[["E"]] * t^4

# ---- readers: each returns array[lon, lat, month-of-window] on ITS grid -----
nc_time_ym <- function(n) {
  tu <- n$dim$time$units; tv <- n$dim$time$vals
  origin <- as.Date(sub("^.*since ", "", tu))
  d <- if (grepl("^hours", tu)) origin + tv / 24 else origin + tv
  list(y = as.integer(format(d, "%Y")), m = as.integer(format(d, "%m")))
}
read_win <- function(file, var, win) {
  n <- nc_open(file); on.exit(nc_close(n))
  ym <- nc_time_ym(n); ix <- which(ym$y >= win[1] & ym$y <= win[2])
  if (length(ix) != 12 * diff(win) + 12) stop(sprintf("%s: window %d-%d incomplete (%d months)", basename(file), win[1], win[2], length(ix)))
  a <- ncvar_get(n, var, start = c(1, 1, min(ix)), count = c(-1, -1, length(ix)))
  miss <- ncatt_get(n, var, "missing_value")$value
  if (!is.null(miss)) a[a == miss] <- NA
  a[!is.finite(a) | abs(a) > 1e20] <- NA
  list(a = a, lon = n$dim[[grep("lon", names(n$dim), value = TRUE)[1]]]$vals,
       lat = n$dim[[grep("lat", names(n$dim), value = TRUE)[1]]]$vals, month = ym$m[ix])
}
clim12 <- function(a, month) { # monthly climatology over the window
  out <- array(NA_real_, c(dim(a)[1:2], 12))
  for (m in 1:12) out[, , m] <- rowMeans(a[, , month == m, drop = FALSE], dims = 2, na.rm = TRUE)
  out
}
# HadISST 1 deg -> ERSST 2 deg by 2x2 block mean (cell edges coincide: ERSST
# cell L spans L-1..L+1, HadISST cells L-0.5 and L+0.5 lie inside it).
ice_to_2deg <- function(ice, lon2, lat2) {
  hl <- ice$lon; hb <- ice$lat
  out <- array(NA_real_, c(length(lon2), length(lat2), dim(ice$a)[3]))
  for (i in seq_along(lon2)) {
    ls <- c(lon2[i] - 0.5, lon2[i] + 0.5); ls[ls >= 180] <- ls[ls >= 180] - 360
    li <- match(ls, hl)
    for (j in seq_along(lat2)) {
      bj <- match(c(lat2[j] - 0.5, lat2[j] + 0.5), hb)
      if (any(is.na(li)) || any(is.na(bj))) next
      blk <- ice$a[li, bj, , drop = FALSE]
      out[i, j, ] <- apply(blk, 3, function(x) if (all(is.na(x))) NA_real_ else mean(x, na.rm = TRUE))
    }
  }
  out
}
# NCEP 2.5 deg -> 2 deg by nearest cell (lat descending in the file)
wind_to_2deg <- function(w, lon2, lat2) {
  li <- vapply(lon2, function(x) which.min(abs(((w$lon - x + 180) %% 360) - 180)), 1L)
  bj <- vapply(lat2, function(y) which.min(abs(w$lat - y)), 1L)
  w$a[li, bj, , drop = FALSE]
}

build_window <- function(win, verbose = TRUE) {
  sst <- read_win(F_SST, "sst", win); lon2 <- sst$lon; lat2 <- sst$lat
  ice <- read_win(F_ICE, "sic", win)
  wnd <- read_win(F_WND, "wspd", win)
  sst_c <- clim12(sst$a, sst$month)
  ice_c <- clim12(ice_to_2deg(ice, lon2, lat2), ice$month)
  wnd_c <- clim12(wind_to_2deg(wnd, lon2, lat2), wnd$month)
  sst_ann <- rowMeans(sst_c, dims = 2)
  ocean <- is.finite(sst_ann)
  # HadISST marks ice-free open ocean 0 and land NA; an ERSST ocean cell with NA
  # ice (coastline mismatch) is taken ice-free, and counted so it is visible.
  ice_na <- ocean & !is.finite(rowMeans(ice_c, dims = 2))
  ice_c[is.na(ice_c)] <- 0
  W <- outer(rep(1, length(lon2)), cos(lat2 * pi / 180)); W[!ocean] <- 0
  hs <- ocean & sst_ann < HX_SST_CUT
  hemi <- outer(rep(TRUE, length(lon2)), lat2 >= 0)          # NH cells
  ow_c <- 1 - ice_c                                          # open-water fraction, monthly
  u2_c <- wnd_c^2                                            # (monthly-mean |U|)^2
  sc_c <- schmidt(pmax(sst_c, -1.8))^-0.5                    # Sc^-1/2 at the monthly SST
  amean <- function(x, mask) { w <- W * mask; sum(w * x, na.rm = TRUE) / sum(w) }    # area mean of a 2-D field
  mmean <- function(x3, mask) mean(vapply(1:12, function(m) amean(x3[, , m], mask), 0)) # area+month mean
  one <- function(mask_hs, mask_ll, lbl) {
    kfull <- function(msk) mmean(ow_c * u2_c * sc_c, msk)
    list(lbl = lbl,
         hs_area_frac = sum(W * mask_hs) / sum(W * (mask_hs | mask_ll)),
         sst_hs_mean = amean(sst_ann, mask_hs), sst_ll_mean = amean(sst_ann, mask_ll),
         ow_hs = mmean(ow_c, mask_hs), ow_ll = mmean(ow_c, mask_ll),
         u_hs = mmean(wnd_c, mask_hs), u_ll = mmean(wnd_c, mask_ll),
         u2_ratio = mmean(u2_c, mask_hs) / mmean(u2_c, mask_ll),
         sc_ratio = mmean(sc_c, mask_hs) / mmean(sc_c, mask_ll),
         sc_ratio_model_t = schmidt(HX_SST_HS_MODEL)^-0.5 / mmean(sc_c, mask_ll),
         icewind_hs = mmean(ow_c * u2_c, mask_hs) / mmean(u2_c, mask_ll),   # HILDA's own two terms, rectified
         factor_product = mmean(ow_c, mask_hs) * (mmean(u2_c, mask_hs) / mmean(u2_c, mask_ll)) *
                          (mmean(sc_c, mask_hs) / mmean(sc_c, mask_ll)),
         factor = kfull(mask_hs) / mmean(u2_c * sc_c, mask_ll))
  }
  res <- list(global = one(hs, ocean & !hs, "global"),
              NH = one(hs & hemi, ocean & !hs & hemi, "NH"),
              SH = one(hs & !hemi, ocean & !hs & !hemi, "SH"))
  list(win = win, res = res, ocean_frac = sum(W) / sum(outer(rep(1, length(lon2)), cos(lat2 * pi / 180))),
       n_ice_na = sum(ice_na), n_hs = sum(hs))
}

cat(sprintf("\n=== hs_asx_frac from observations: SST < %g C area; Sc from %s ===\n", HX_SST_CUT, "SC_CO2_W14_A..E"))
runs <- lapply(HX_WINS, build_window)
names(runs) <- vapply(HX_WINS, function(w) sprintf("%d-%d", w[1], w[2]), "")
head_key <- sprintf("%d-%d", HX_WIN[1], HX_WIN[2]); H <- runs[[head_key]]
# sanity gates on the MASK, not on the answer
if (H$ocean_frac < HX_OCEAN_FRAC_BAND[1] || H$ocean_frac > HX_OCEAN_FRAC_BAND[2])
  stop(sprintf("ERSST ocean-area fraction %.3f outside [%.2f, %.2f]: mask wrong", H$ocean_frac, HX_OCEAN_FRAC_BAND[1], HX_OCEAN_FRAC_BAND[2]))
if (H$res$global$ow_ll < HX_LL_OW_MIN)
  stop(sprintf("warm box open-water fraction %.3f < %.2f: the SST cut is not separating the ice", H$res$global$ow_ll, HX_LL_OW_MIN))
cat(sprintf("  ocean area fraction %.3f (ERSST mask); HS cells %d; ocean cells with no HadISST ice value %d (taken ice-free)\n",
            H$ocean_frac, H$n_hs, H$n_ice_na))
cat(sprintf("\n  headline window %s (each factor is HS relative to the warm box):\n", head_key))
cat(sprintf("  %-7s %7s %7s %7s %6s %6s %6s %6s %7s %7s %8s %8s %8s\n", "box", "areaHS", "sstHS", "sstLL", "owHS", "owLL", "U_HS", "U_LL", "U2rat", "Scrat", "ice*wind", "product", "FACTOR"))
for (k in names(H$res)) { r <- H$res[[k]]
  cat(sprintf("  %-7s %7.3f %7.2f %7.2f %6.3f %6.3f %6.2f %6.2f %7.3f %7.3f %8.3f %8.3f %8.3f\n", r$lbl, r$hs_area_frac, r$sst_hs_mean, r$sst_ll_mean,
              r$ow_hs, r$ow_ll, r$u_hs, r$u_ll, r$u2_ratio, r$sc_ratio, r$icewind_hs, r$factor_product, r$factor)) }
cat(sprintf("  (HILDA: hs_frac %.2f in EACH hemisphere; the model applies one hs_frac to both. Sc term at the model's sst_hs = %g C: %.3f)\n",
            HX_HILDA_HS_FRAC, HX_SST_HS_MODEL, H$res$global$sc_ratio_model_t))
cat("\n  window sensitivity (global): areaHS  owHS  ice*wind  FACTOR\n")
for (k in names(runs)) { r <- runs[[k]]$res$global
  cat(sprintf("  %-10s %6.3f %6.3f %8.3f %8.3f%s\n", k, r$hs_area_frac, r$ow_hs, r$icewind_hs, r$factor,
              if (runs[[k]]$win[1] < 1979) "   (pre-satellite ice: climatological in HadISST1)" else "")) }
cat("\n  reading: ice*wind is HILDA's argument (ice cancels winds) measured; FACTOR adds the Schmidt\n")
cat("  term a single fitted k_w cannot carry. Compare to the fitted hs_asx_frac 0.65-0.8 (09-06c).\n")
out <- list(sst_cut = HX_SST_CUT, window = HX_WIN, windows = runs, headline = H$res,
            factor = H$res$global$factor, icewind = H$res$global$icewind_hs, hs_area_frac = H$res$global$hs_area_frac,
            schmidt = "SC_CO2_W14_A..E (Wanninkhof 2014 Table 1), k ~ Sc^-1/2",
            law = "Wanninkhof (2014) eq. 4: k660 = 0.251 <U^2> (Sc/660)^-1/2; open water only",
            sources = c("ersst_v5_monthly", "hadisst_ice", "ncep_wspd_sig995"), built = format(Sys.Date()),
            caveats = c("monthly-mean |U| at sigma 0.995, squared; gustiness and height cancel in the ratio to first order",
                        "NCEP nearest-cell to 2 deg; HadISST 2x2 block mean; ERSST ocean cells lacking an ice value taken ice-free",
                        "no exchange through ice (linear in open-water fraction); HILDA's convention"))
saveRDS(out, HX_OUT); cat(sprintf("\nwrote %s\n", HX_OUT))
