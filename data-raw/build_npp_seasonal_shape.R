# =====================================================================
# build_npp_seasonal_shape.R -- THE OBSERVED SEASONAL SHAPE OF NH/SH
#                               TERRESTRIAL PRODUCTIVITY
#                               -> data/obs_npp_seasonal_shape.rds
#
# WHY THIS EXISTS. diag_npp_eff_latitude.R measured the NPP-weighted effective
# latitude at 38.35 N against a shipped CCX_SEAS_PHI_EFF["NH"] of 75, but it
# could only answer the AGGREGATION question -- given the model's premise that
# productivity follows normalised insolation, which single latitude represents
# the hemisphere. It could not test the PREMISE, because MOD17A3HGF is annual.
# If NH productivity is strongly RECTIFIED (a growing season that switches on
# and off), a poleward phi_eff is a legitimate emulation of rectification and
# 75 is defensible under a meaning the constant's name does not claim.
#
# This script removes the premise. MOD17A2HGF is the same algorithm and the
# same 0.5 deg ICDC regrid, 8-DAILY, so the hemispheric aggregate seasonal
# shape is OBSERVED rather than assumed, and phi_eff is fitted to THAT.
#
# TWO VARIABLES, AS A BRACKET, because neither is NPP:
#   gpp                 -- GROSS. Autotrophic respiration runs through the
#                          shoulder seasons, so GPP is LESS rectified than NPP
#                          and its phi_eff is biased EQUATORWARD, i.e. toward
#                          the convenient answer. Reported so the bias has a
#                          number rather than a hand-wave.
#   net_photosynthesis  -- MOD17's PsnNet = GPP - leaf and fine-root maintenance
#                          respiration. Closer to NPP; still omits growth
#                          respiration and live-wood maintenance.
# The truth for NPP sits at or beyond the PsnNet end of the bracket.
#
# THE COMPARISON IS WINDOW-INTEGRATED, NOT POINT-SAMPLED. Each observation is a
# composite ACCUMULATED over its window, so the model shape is integrated over
# the same window rather than evaluated at its midpoint. Point-sampling a
# curved shape at coarse steps biases the amplitude, and this project has been
# bitten by exactly that quantisation before.
#
# AND THE WINDOWS ARE NOT ALL 8 DAYS. The last composite of each year runs from
# DOY 361 to the end, so 5 days in a common year and 6 in a leap year. Treating
# it as 8 would inflate the winter end of the NH cycle -- the end that carries
# the rectification signal. Window lengths are derived from the file dates.
#
# WHAT THIS MEASURES BEYOND phi_eff. The observed shape has a real PHASE, and
# insolation does not: daily-mean insolation peaks at the solstice at every
# extratropical latitude. The offset between them IS the model's phenology lag
# `seas_lag_p`, so this product measures a fitted parameter as a by-product.
#
# FIVE YEARS spread across the record (2001, 2006, 2011, 2016, 2021) -- the
# spread across them is the reported uncertainty on the shape. See
# data-raw/download_mod17_gpp8d.R for why those years and why the zips are kept.
#
# Usage:  Rscript data-raw/build_npp_seasonal_shape.R
# =====================================================================
suppressPackageStartupMessages(library(ncdf4))
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)

SS_DIR   <- "data-raw/downloads/mod17_gpp8d"
SS_OUT   <- "data/obs_npp_seasonal_shape.rds"
SS_VARS  <- c(gpp = "gpp", psnnet = "net_photosynthesis")
SS_R_EARTH <- 6371000
SS_NVALID_FULL <- 14400          # full-cell pixel count AT THE EQUATOR
SS_NGRID <- 720                  # points/yr for the model shape; = ccx_seas_norms()
SS_PHI   <- seq(0.5, 89.5, by = 0.05)
# Annual totals are a read-the-file-right gate, NOT a science claim. MOD17 GPP
# is ~130 PgC/yr globally and PsnNet is roughly half of it.
SS_GATE  <- list(gpp = c(90, 170), psnnet = c(40, 100))

zips <- sort(list.files(SS_DIR, pattern = "^gpp8d_\\d{4}\\.nc\\.zip$", full.names = TRUE))
stopifnot(length(zips) >= 3)
cat(sprintf("%d year-zips in %s\n\n", length(zips), SS_DIR))

# ---------------------------------------------------------------------
# 1. One year -> latitude x window flux, for each variable
# ---------------------------------------------------------------------
read_year <- function(zp) {
  tmp <- file.path(tempdir(), paste0("gpp8d_", tools::file_path_sans_ext(basename(zp))))
  unlink(tmp, recursive = TRUE); dir.create(tmp, recursive = TRUE)
  utils::unzip(zp, exdir = tmp, junkpaths = TRUE)
  on.exit(unlink(tmp, recursive = TRUE))
  fs <- sort(list.files(tmp, pattern = "\\.nc$", full.names = TRUE))
  dates <- as.Date(sub(".*__(\\d{8})__.*", "\\1", basename(fs)), "%Y%m%d")
  stopifnot(length(fs) >= 45, !anyNA(dates))
  yr <- as.integer(format(dates[1], "%Y"))
  doy <- as.integer(format(dates, "%j"))
  ny  <- as.integer(format(as.Date(sprintf("%d-12-31", yr)), "%j"))   # 365 or 366
  # Window length: 8 days, except the last composite which runs to year end.
  days <- c(diff(doy), ny - doy[length(doy)] + 1)
  stopifnot(all(days > 0), sum(days) == ny)

  nc <- nc_open(fs[1]); lat <- ncvar_get(nc, "lat"); lon <- ncvar_get(nc, "lon"); nc_close(nc)
  dlat <- abs(diff(lat)[1]); dlon <- abs(diff(lon)[1])
  area_lat <- SS_R_EARTH^2 * (dlon * pi / 180) *
    (sin((lat + dlat / 2) * pi / 180) - sin((lat - dlat / 2) * pi / 180))
  px_area <- area_lat[which.min(abs(lat))] / SS_NVALID_FULL

  out <- lapply(SS_VARS, function(v) matrix(0, nrow = length(lat), ncol = length(fs)))
  for (i in seq_along(fs)) {
    nc <- nc_open(fs[i])
    nv <- ncvar_get(nc, "numberofvalidvalues"); nv[!is.finite(nv) | nv < 0] <- 0
    va <- nv * px_area                                  # VALID area per cell, m2
    for (k in names(SS_VARS)) {
      x <- ncvar_get(nc, SS_VARS[[k]]); x[!is.finite(x)] <- NA
      # kg C m-2 accumulated over the window * m2 -> kg C; /1e12 -> Pg C
      out[[k]][, i] <- colSums(x * va / 1e12, na.rm = TRUE)
    }
    nc_close(nc)
  }
  list(year = yr, lat = lat, doy = doy, days = days, ndays = ny, flux = out)
}

yrs <- lapply(zips, function(z) { cat(sprintf("  reading %s\n", basename(z))); read_year(z) })
lat <- yrs[[1]]$lat
stopifnot(all(vapply(yrs, function(y) isTRUE(all.equal(y$lat, lat)), logical(1))))

# ---------------------------------------------------------------------
# 2. The observed hemispheric shape, per year and variable
# ---------------------------------------------------------------------
# RATE, not accumulated flux: the last window of the year is shorter, so the raw
# composites are not comparable to each other. rate_i = flux_i / days_i, and the
# annual mean rate is sum(flux)/sum(days) -- NOT mean(rate), which would weight
# the short window like a full one.
shape_of <- function(y, k, h) {
  sel <- if (h == "NH") lat >= 0 else lat < 0
  fl  <- colSums(y$flux[[k]][sel, , drop = FALSE])          # PgC per window
  list(rate = (fl / y$days) / (sum(fl) / y$ndays),          # unit annual mean
       total = sum(fl),                                     # PgC/yr in this hemisphere
       # Window MIDPOINT in fraction-of-year, the model's own time coordinate.
       mid = (y$doy - 1 + y$days / 2) / y$ndays)
}

p2p <- function(x) max(x) - min(x)
cat("\n=== ANNUAL TOTALS (the read-the-file gate) AND OBSERVED SHAPE ===\n")
for (k in names(SS_VARS)) {
  tot <- vapply(yrs, function(y) sum(y$flux[[k]]), numeric(1))
  if (mean(tot) < SS_GATE[[k]][1] || mean(tot) > SS_GATE[[k]][2])
    stop(sprintf("%s global %.1f PgC/yr outside gate [%g, %g] -- read wrong",
                 k, mean(tot), SS_GATE[[k]][1], SS_GATE[[k]][2]))
  cat(sprintf("  %-7s global %.1f PgC/yr (%s)  [gate PASS]\n", k, mean(tot),
              paste(sprintf("%d:%.1f", vapply(yrs, `[[`, numeric(1), "year"), tot),
                    collapse = " ")))
}

# ---------------------------------------------------------------------
# 3. Fit the effective latitude to the OBSERVED shape
# ---------------------------------------------------------------------
# The model shape is INTEGRATED over each observation window on a 720-point
# grid, not sampled at the midpoint -- see the header. The fit is done with a
# free circular time shift, because seas_lag_p is free and would absorb one;
# the shift it wants is reported, and IS the phenology lag.
tt <- (seq_len(SS_NGRID) - 0.5) / SS_NGRID
# All candidate shapes, unit annual mean, as columns: 720 x length(SS_PHI).
# Built once -- the fit is then three matrix multiplies rather than a triple
# loop, which is the difference between seconds and an hour.
SS_INS <- vapply(SS_PHI, function(phi) {
  v <- ccx_insol(phi, tt); v / mean(v)
}, numeric(SS_NGRID))
SS_SHIFT_MO <- seq(0, 11.75, by = 0.25)        # phenology lag candidates, months
# Report a lag in (-6, 6]: a "9.9 month" phenology lag is a 2.1 month LEAD, and
# printing the wrapped form invites exactly the misreading this arc keeps making.
wrap_mo <- function(m) ((m + 6) %% 12) - 6

#' Window-averaging operator: W %*% v averages the 720-point shape over each
#' composite window. This is the "integrate, do not point-sample" rule made
#' explicit, and it carries the 5-6 day final window of the year correctly.
window_op <- function(mid, days, ndays) {
  half <- (days / ndays) / 2
  W <- matrix(0, nrow = length(mid), ncol = SS_NGRID)
  for (i in seq_along(mid)) {
    inw <- ((tt - (mid[i] - half[i])) %% 1) <= ((2 * half[i]) %% 1)
    W[i, inw] <- 1 / sum(inw)
  }
  W
}

fit_phi <- function(target, mid, days, ndays) {
  W <- window_op(mid, days, ndays)
  best <- list(sse = Inf)
  for (s in SS_SHIFT_MO) {
    # A time shift of the shape is a circular ROLL of the grid, so it is applied
    # to the operator's COLUMNS once rather than to every candidate shape.
    # DIRECTION: the model shape is insol(phi, t - s), i.e. v shifted LATER, and
    # (W v_shifted)[j] = sum_m W[j, m + k] v[m] -- so the columns advance, they
    # do not retreat. Getting this backwards flips the sign of the reported
    # phenology lag while leaving phi_eff untouched, which is exactly the kind
    # of error that survives a plausibility check. Gated below.
    k <- round(s / 12 * SS_NGRID) %% SS_NGRID
    M <- (if (k == 0) W else W[, c((k + 1):SS_NGRID, seq_len(k)), drop = FALSE]) %*% SS_INS
    e <- colSums((M - target)^2)
    j <- which.min(e)
    if (e[j] < best$sse)
      best <- list(sse = e[j], phi = SS_PHI[j], shift_mo = s, m = M[, j])
  }
  best
}

# GATE: recover a KNOWN (phi, lag) from a synthetic target. A shift applied in
# the wrong direction, or an off-by-one in the roll, returns a plausible number
# and no error -- so the operator is tested against a case whose answer is known
# before it is used on data whose answer is not.
{
  g <- yrs[[1]]
  mid <- (g$doy - 1 + g$days / 2) / g$ndays
  PHI_T <- 52.30; LAG_T <- 2.25
  tgt <- as.vector(window_op(mid, g$days, g$ndays) %*%
                   (function(v) v / mean(v))(ccx_insol(PHI_T, tt - LAG_T / 12)))
  chk <- fit_phi(tgt, mid, g$days, g$ndays)
  stopifnot(abs(chk$phi - PHI_T) < 0.5, abs(chk$shift_mo - LAG_T) < 0.3)
  cat(sprintf("\nfit_phi gated on a synthetic target: phi %.2f (true %.2f), lag %.2f mo (true %.2f)  [PASS]\n",
              chk$phi, PHI_T, chk$shift_mo, LAG_T))
}

res <- list()
for (h in c("NH", "SH")) for (k in names(SS_VARS)) {
  per <- lapply(yrs, shape_of, k = k, h = h)
  # Fit each YEAR separately: the spread across years is the uncertainty, and a
  # fit to the 5-year mean shape would hide it.
  # Each year gets its OWN window operator: 2016 is a leap year, so its windows
  # and its final short composite are not 2001's.
  f <- Map(function(pp, y) fit_phi(pp$rate, pp$mid, y$days, y$ndays), per, yrs)
  phis <- vapply(f, `[[`, numeric(1), "phi") * (if (h == "NH") 1 else -1)
  shs  <- vapply(f, `[[`, numeric(1), "shift_mo")
  amps <- vapply(per, function(pp) p2p(pp$rate), numeric(1))
  pk   <- vapply(per, function(pp) (pp$mid[which.max(pp$rate)] * 12) %% 12, numeric(1))
  # AMPLITUDE-MATCHED phi, alongside the SSE fit. The observed shape is
  # RECTIFIED and an insolation shape is not, so no phi reproduces it and the
  # SSE fit COMPROMISES -- it lands on a phi whose amplitude is short of the
  # observation. Reporting only one of the two would repeat this arc's standing
  # error in either direction (amp_definition_mismatch).
  a_of  <- vapply(SS_PHI, function(phi) p2p(ccx_insol(phi, tt) / mean(ccx_insol(phi, tt))),
                  numeric(1))
  phi_a <- vapply(amps, function(A) SS_PHI[which.min(abs(a_of - A))], numeric(1)) *
           (if (h == "NH") 1 else -1)
  # How much of the cycle NO insolation shape can explain: rms of the best fit's
  # residual as a fraction of the observed peak-to-peak.
  frac <- vapply(seq_along(f), function(i)
    sqrt(f[[i]]$sse / length(per[[i]]$rate)) / amps[i], numeric(1))
  res[[paste(h, k, sep = "_")]] <- list(
    phi_amp = phi_a, phi_amp_mean = mean(phi_a),
    resid_frac = frac, resid_frac_mean = mean(frac),
    shape_by_year = vapply(per, function(pp) pp$rate, numeric(length(per[[1]]$rate))),
    hemisphere = h, var = k, years = vapply(yrs, `[[`, numeric(1), "year"),
    phi = phis, phi_mean = mean(phis), phi_sd = stats::sd(phis),
    shift_mo = wrap_mo(shs), shift_mean = mean(wrap_mo(shs)),
    p2p = amps, p2p_mean = mean(amps), peak_mo = pk,
    total_PgC = vapply(per, `[[`, numeric(1), "total"),
    shape_mean = rowMeans(vapply(per, function(pp) pp$rate, numeric(length(per[[1]]$rate)))),
    mid = per[[1]]$mid)
}

pp_of <- function(phi) p2p(ccx_insol(phi, tt) / mean(ccx_insol(phi, tt)))
cat("\n=== EFFECTIVE LATITUDE FITTED TO THE OBSERVED SHAPE ===\n")
cat(sprintf("  %-12s %9s %7s %9s %9s %9s %8s %9s\n", "hemi/var", "phi(SSE)", "sd(yr)",
            "phi(amp)", "obs p2p", "fit p2p", "lag mo", "unexpl"))
for (nm in names(res)) {
  x <- res[[nm]]
  cat(sprintf("  %-12s %9.2f %7.2f %9.2f %9.3f %9.3f %8.2f %8.1f%%\n", nm,
              x$phi_mean, x$phi_sd, x$phi_amp_mean, x$p2p_mean, pp_of(x$phi_mean),
              x$shift_mean, 100 * x$resid_frac_mean))
}
cat("  phi(SSE) = best SHAPE match; phi(amp) = the phi whose peak-to-peak equals\n")
cat("  the observation. They differ because the observed cycle is RECTIFIED and an\n")
cat("  insolation shape is not -- 'unexpl' is the rms residual of the best fit as a\n")
cat("  fraction of the observed peak-to-peak, i.e. what NO single latitude can do.\n")
cat("  lag = observed peak minus insolation peak, wrapped to (-6, 6]; POSITIVE is\n")
cat("  productivity lagging light, which is what seas_lag_p represents.\n")
cat(sprintf("\n  SHIPPED CCX_SEAS_PHI_EFF: NH %.1f (unit-mean p2p %.3f), SH %.1f (%.3f)\n",
            CCX_SEAS_PHI_EFF[["NH"]],
            p2p(ccx_insol(CCX_SEAS_PHI_EFF[["NH"]], tt) / mean(ccx_insol(CCX_SEAS_PHI_EFF[["NH"]], tt))),
            CCX_SEAS_PHI_EFF[["SH"]],
            p2p(ccx_insol(CCX_SEAS_PHI_EFF[["SH"]], tt) / mean(ccx_insol(CCX_SEAS_PHI_EFF[["SH"]], tt)))))
cat(sprintf("  ANNUAL-PRODUCT answer (diag_npp_eff_latitude.R): NH 38.35 (p2p %.3f), SH -15.75 (%.3f)\n",
            pp_of(38.35), pp_of(-15.75)))
cat("  Fitted seas_lag_p at the arm-N mode: 2.17 months -- compare the lag column.\n")

saveRDS(list(fits = res, years = vapply(yrs, `[[`, numeric(1), "year"),
             vars = SS_VARS, phi_grid = range(SS_PHI),
             source = paste("MOD17A2HGF C6.1 8-daily (Running & Zhao,",
                            "doi:10.5067/MODIS/MOD17A2HGF.061); 0.5 deg netCDF regrid",
                            "by UHH/ICDC, doi:10.25592/uhhfdm.14449, CC-BY-4.0"),
             note = paste("gpp and psnnet BRACKET NPP: GPP is less rectified than NPP",
                          "(autotrophic respiration runs in the shoulder seasons) so its",
                          "phi_eff is biased equatorward; PsnNet omits growth and live-wood",
                          "respiration so it is closer but still not NPP. Model shape is",
                          "WINDOW-INTEGRATED to match the composites, and the last window",
                          "of each year is 5-6 days, not 8.",
                          "Built by data-raw/build_npp_seasonal_shape.R.")),
        SS_OUT)
cat(sprintf("\nwrote %s\n", SS_OUT))
