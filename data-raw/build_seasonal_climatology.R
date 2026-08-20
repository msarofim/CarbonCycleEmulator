# =====================================================================
# build_seasonal_climatology.R -- OBSERVED hemispheric SEASONAL CYCLES of
# sea-surface temperature and land air temperature -> data/obs_seasonal_clim.rds
#
# WHY THIS EXISTS (audit 2026-08-20d, calibration/diag_driver_audit.R).
# The model's four seasonal temperature knobs -- seas_T_amp_{NH,SH},
# sst_seas_amp_{NH,SH} -- were fitted against priors that were RECOLLECTIONS,
# and the fit left them at -6.03, -4.72 and +3.83 prior-sigma. Nothing in the
# repo could check them: HadSST4 and CRUTEM5 are both held as ANNUAL ANOMALY
# series, and an anomaly has its monthly climatology subtracted, so the
# seasonal cycle is removed by construction. This script supplies the missing
# half -- the ABSOLUTE monthly climatology those anomalies are anomalies FROM.
#
# THE TWO PRODUCTS, and why these two.
#
# LAND: CRU 1961-90 absolute land-surface-air-temperature climatology,
# 5 deg x 5 deg monthly (`absolute.nc`), MASKED BY CRUTEM5 STATION COVERAGE on
# the identical 72 x 36 grid. This is the DESIGNED COMPANION to the CRUTEM
# anomaly series the repo already holds -- same grid, same 1961-90 baseline --
# so adding it to a CRUTEM anomaly is the construction its authors intended.
#
# THE MASK IS NOT OPTIONAL AND THE FIRST RUN OF THIS SCRIPT PROVED IT.
# `absolute.nc` is SPATIALLY COMPLETE -- it carries an interpolated value in
# every cell, ocean included, with no missing_value ever written (range
# -70.3 to +35.7 C, zero NAs). Averaged unmasked it gives an "NH land" mean of
# 14.59 C and a half-amplitude of 6.68 K, both badly contaminated by ocean.
# The tell was that NH and SH each returned EXACTLY 1296 of 2592 cells -- half
# the globe apiece, which no land mask produces. Hence sc_gate_cells() below:
# the cell counts are ASSERTED, not printed and trusted.
# Jones PD, New M, Parker DE, Martin S, Rigor IG (1999), Surface air
# temperature and its changes over the past 150 years, Rev. Geophys. 37:173-199,
# doi:10.1029/1999RG900002.
#
# OCEAN: NOAA ERSSTv5 monthly ABSOLUTE SST, 2 deg, 1854-present. HadSST4 --
# which the repo uses for the annual anomaly -- publishes NO absolute
# companion, so a different product is unavoidable on the ocean side. ERSSTv5
# is the one to reach for on the IGCC-compatibility criterion Marcus raised:
# IGCC's GMST is a 4-dataset mean, and ERSSTv5 is the ocean component of TWO of
# the four (NOAAGlobalTemp and GISTEMP; HadCRUT5 uses HadSST4). No absolute SST
# product is a component of all four, because HadSST4 has no absolute form.
# Huang B et al. (2017), J. Climate 30:8179-8205, doi:10.1175/JCLI-D-16-0836.1.
#
# THE MASK CAVEAT, stated rather than buried: the seasonal cycle enters the
# model ADDITIVELY, on top of the HadSST4 annual anomaly (R/model.R ~line 1000).
# So an ERSST-vs-HadSST4 mask difference perturbs the seasonal AMPLITUDE only,
# not the anomaly path -- and the amplitude it is replacing is currently wrong
# by a factor of ~20. The inconsistency is real and it is negligible against
# what it fixes.
#
# THE WEIGHTING CAVEAT, and it is the load-bearing one. These are AREA-weighted
# hemispheric means. The model's parameters are not area-weighted quantities:
# `seas_T_amp_*` multiplies SOIL RESPIRATION, so its honest observational
# counterpart is respiration-weighted; `sst_seas_amp_*` modulates AIR-SEA
# EXCHANGE, so its counterpart is gas-exchange-weighted. Neither weighting is
# available here. THESE NUMBERS ARE THEREFORE PRIOR ANCHORS, NOT VALUES TO
# PRESCRIBE. The latitude-band variants below exist to bracket that gap: NH
# soil carbon and NH heterotrophic respiration are boreal-weighted, so the
# >30N and >45N rows bound the flux-weighted amplitude from above.
#
# EVERY AMPLITUDE IS REPORTED BOTH WAYS -- half-amplitude (the model's
# parameter convention) and peak-to-peak -- computed from one expression, per
# the amp_definition_mismatch rule that cost this project two handoffs.
#
# Usage:  Rscript data-raw/build_seasonal_climatology.R
# =====================================================================
suppressPackageStartupMessages(library(ncdf4))

DL          <- "data-raw/downloads"
SC_OUT      <- "data/obs_seasonal_clim.rds"
SC_CRU_NC   <- file.path(DL, "cru_absolute_1961-90.nc")
SC_ERSST_NC <- file.path(DL, "ersst_v5_sst_mnmean.nc")
SC_CRUTEM_NC <- file.path(DL, "CRUTEM.5.1.0.0.anomalies.nc")
# Land mask = CRUTEM5 cells reporting at least this many months inside the
# mask window. It is STATION COVERAGE, not a geographic land mask: sparse over
# the Sahara, the Amazon interior and Antarctica. Stated because it biases the
# average toward inhabited land, which is closer to (not equal to) the
# vegetated land the respiration term cares about.
SC_MASK_WIN    <- c(1961, 1990)
SC_MASK_MIN_MO <- 120                # months of the 360 in the window
# CELL WEIGHT = cos(lat) x LAND FRACTION x station coverage. The land fraction
# is derived from ERSSTv5's own ocean mask (the file is already downloaded for
# the SST half): the fraction of 2 deg ERSST cell centres inside each 5 deg CRU
# cell that carry NO valid SST. Weighting by full cell area instead -- the
# obvious thing -- gives 41.9 % of the globe, because at 5 deg a cell with one
# coastal station counts as wholly land, and `absolute.nc` fills those cells
# with a maritime-damped interpolation. That biases the land amplitude LOW.
# Which way an approximation errs is worth knowing: this one is CONSERVATIVE
# for the argument it is being used in.
SC_LANDFRAC_OK <- c(0.15, 0.40)     # global land is ~29 % of the surface
# SST climatology window. Matches LIK_SEAS_WINDOW (R/likelihood.R) so the
# observed cycle is estimated over the same years the model's cycle is scored
# in. A second window is computed alongside it to expose warming drift.
SC_SST_WIN     <- c(1975, 2024)
SC_SST_WIN_ALT <- c(1961, 1990)      # CRU's land baseline, for a like-for-like pair
# Latitude bands for the land bracket. "all" is every land cell in the
# hemisphere; the others progressively weight toward the boreal soil carbon
# that dominates NH heterotrophic respiration.
SC_LAND_BANDS <- list(all = 0, `>30` = 30, `>45` = 45)
SC_MONTHS <- c("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec")
# The model's seasonal lag convention (R/model.R): a term written
# sin(2*pi*(t - (3.5 + LAG)/12)) peaks at year-fraction 0.25 + (3.5 + LAG)/12,
# so LAG = 0 already places the NH peak at mid-July. Observed peak months are
# converted into THIS unit so they can be read straight against
# CCX_SEAS_T_LAG / CCX_SST_SEAS_LAG.
SC_LAG_ZERO_OFFSET <- 3.5

# ---- one harmonic estimator, used for every series in this file -----
# First annual harmonic of a 12-value monthly climatology on mid-month
# year-fractions. Returns half-amplitude, peak-to-peak, peak month, and the
# second-harmonic ratio (how far from a pure sine the real cycle is -- the
# model can only make a sine, so this is the shape error it cannot represent).
sc_harm <- function(v) {
  phi <- (seq_len(12) - 0.5) / 12
  a1 <- 2 * mean(v * sin(2 * pi * phi)); b1 <- 2 * mean(v * cos(2 * pi * phi))
  a2 <- 2 * mean(v * sin(4 * pi * phi)); b2 <- 2 * mean(v * cos(4 * pi * phi))
  r1 <- sqrt(a1^2 + b1^2); r2 <- sqrt(a2^2 + b2^2)
  pk <- (atan2(a1, b1) / (2 * pi)) %% 1
  list(mean = mean(v), half_amp = r1, p2p = 2 * r1, p2p_raw = max(v) - min(v),
       peak_frac = pk, peak_month = 12 * pk, amp2_over_amp1 = r2 / r1,
       # the model's own lag parameter that would reproduce this peak
       model_lag = ((12 * pk - 3) - SC_LAG_ZERO_OFFSET) %% 12,
       clim = v)
}
sc_show <- function(tag, h) cat(sprintf(
  "  %-22s mean %7.2f C | half-amp %6.3f K | p2p %6.3f K (raw %6.3f) | peak %s (%.2f) | model LAG %5.2f mo | amp2/amp1 %.3f\n",
  tag, h$mean, h$half_amp, h$p2p, h$p2p_raw,
  SC_MONTHS[pmin(12L, floor(h$peak_month) + 1L)], h$peak_month, h$model_lag, h$amp2_over_amp1))

# =====================================================================
cat("=== LAND: CRU 1961-90 absolute climatology, area-weighted ===\n")
nc  <- nc_open(SC_CRU_NC)
tem <- ncvar_get(nc, "tem")                 # [lon, lat, month], celsius
lat <- ncvar_get(nc, "lat"); nc_close(nc)
stopifnot(all(is.finite(tem)))              # it really is complete -- see header
w_lat <- cos(lat * pi / 180)

# ---- the land mask, from CRUTEM5 coverage on the identical grid ------
nc   <- nc_open(SC_CRUTEM_NC)
ct   <- ncvar_get(nc, "tas")
ctim <- as.POSIXlt(as.Date(ncvar_get(nc, "time"), origin = "1850-01-01"))
clat <- ncvar_get(nc, "latitude"); clon <- ncvar_get(nc, "longitude"); nc_close(nc)
# THE TWO FILES SHARE A GRID AND DISAGREE ABOUT ITS ORDER: `absolute.nc` runs
# latitude N->S (+87.5 first), CRUTEM5 runs S->N (-87.5 first). Longitude
# agrees. Aligned BY VALUE with match(), never by assuming the order -- an
# unflipped mask would have masked Antarctica with the Arctic's coverage and
# produced a perfectly plausible-looking wrong answer (nameless_matrix_order).
stopifnot(identical(dim(ct)[1:2], dim(tem)[1:2]),
          max(abs(sort(clat) - sort(lat))) < 1e-6,
          max(abs(clon - ncvar_get(nc_open(SC_CRU_NC), "lon"))) < 1e-6)
ct <- ct[, match(lat, clat), , drop = FALSE]
stopifnot(max(abs(clat[match(lat, clat)] - lat)) < 1e-6)
kmask <- which(ctim$year + 1900 >= SC_MASK_WIN[1] & ctim$year + 1900 <= SC_MASK_WIN[2])
nobs  <- apply(is.finite(ct[, , kmask, drop = FALSE]), c(1, 2), sum)
mask  <- nobs >= SC_MASK_MIN_MO
# AREA fraction, not cell count: a 5 deg cell at 80 N is a sixth of one at the
# equator, and the unmasked run's giveaway was a COUNT that looked plausible.
# ---- land fraction per 5 deg cell, from ERSSTv5's ocean mask ---------
nc  <- nc_open(SC_ERSST_NC)
e1  <- ncvar_get(nc, "sst", start = c(1, 1, 1), count = c(-1, -1, 1))
elat <- ncvar_get(nc, "lat"); elon <- ncvar_get(nc, "lon"); nc_close(nc)
elon <- ((elon + 180) %% 360) - 180                    # 0..358 -> -180..180
is_ocean <- is.finite(e1) & e1 > -100 & e1 < 100
lon <- ncvar_get(nc_open(SC_CRU_NC), "lon")
# Bin each ERSST centre into its CRU cell (both grids are regular 5 deg / 2 deg
# with cell CENTRES stored, hence the half-width offsets).
ix <- findInterval(elon, sort(lon) - 2.5); iy <- findInterval(elat, sort(lat) - 2.5)
n_tot <- n_oc <- matrix(0, nrow(tem), ncol(tem))
lat_s <- sort(lat)
for (a in seq_along(elon)) for (b in seq_along(elat)) {
  if (ix[a] < 1 || ix[a] > nrow(tem) || iy[b] < 1 || iy[b] > ncol(tem)) next
  jy <- which(abs(lat - lat_s[iy[b]]) < 1e-6)         # back to CRU's N->S order
  n_tot[ix[a], jy] <- n_tot[ix[a], jy] + 1
  if (is_ocean[a, b]) n_oc[ix[a], jy] <- n_oc[ix[a], jy] + 1
}
# Cells with no ERSST coverage at all (the two polar rows) are treated as land;
# they are Arctic/Antarctic and carry cos(lat) ~ 0.04 of weight either way.
land_frac <- ifelse(n_tot > 0, 1 - n_oc / n_tot, 1)
wgrid <- matrix(rep(w_lat, each = nrow(tem)), nrow = nrow(tem)) * land_frac
sc_gate_cells <- function() {
  fr <- sum(wgrid[mask]) / sum(matrix(rep(w_lat, each = nrow(tem)), nrow = nrow(tem)))
  cat(sprintf("  land mask: %d of %d cells with CRUTEM5 >= %d months in %d-%d\n",
              sum(mask), length(mask), SC_MASK_MIN_MO, SC_MASK_WIN[1], SC_MASK_WIN[2]))
  cat(sprintf("  ERSST-derived land fraction, whole globe: %.1f %% | after the station mask: %.1f %%\n",
              100 * sum(wgrid) / sum(matrix(rep(w_lat, each = nrow(tem)), nrow = nrow(tem))),
              100 * fr))
  if (fr < SC_LANDFRAC_OK[1] || fr > SC_LANDFRAC_OK[2])
    stop(sprintf("land mask covers %.1f %% of global area, outside the plausible [%.0f, %.0f] %% -- ",
                 100 * fr, 100 * SC_LANDFRAC_OK[1], 100 * SC_LANDFRAC_OK[2]),
         "the mask is wrong; do NOT average through it.")
  fr
}
land_area_frac <- sc_gate_cells()
land <- list()
for (hh in c("NH", "SH")) for (bn in names(SC_LAND_BANDS)) {
  b  <- SC_LAND_BANDS[[bn]]
  sel <- if (hh == "NH") which(lat >= b) else which(lat <= -b)
  v <- vapply(seq_len(12), function(m) {
    x <- tem[, sel, m]; w <- wgrid[, sel] * mask[, sel]
    stats::weighted.mean(x[w > 0], w[w > 0])
  }, 0)
  key <- paste0(hh, "_", bn)
  land[[key]] <- sc_harm(v)
  sc_show(sprintf("land %s lat %s", hh, bn), land[[key]])
}
cat(sprintf("\n  masked land cells: NH %d, SH %d (of %d total grid cells)\n",
            sum(mask[, lat >= 0]), sum(mask[, lat < 0]), length(mask)))

# =====================================================================
cat("\n=== OCEAN: ERSSTv5 absolute SST, area-weighted hemispheric means ===\n")
nc   <- nc_open(SC_ERSST_NC)
tim  <- ncvar_get(nc, "time"); lat2 <- ncvar_get(nc, "lat")
yrmo <- as.POSIXlt(as.Date(tim, origin = "1800-01-01"))
yr   <- yrmo$year + 1900; mo <- yrmo$mon + 1
w2   <- cos(lat2 * pi / 180)
ocean <- list()
for (win in list(SC_SST_WIN, SC_SST_WIN_ALT)) {
  k <- which(yr >= win[1] & yr <= win[2])
  sst <- ncvar_get(nc, "sst", start = c(1, 1, min(k)), count = c(-1, -1, length(k)))
  sst[sst < -100 | sst > 100] <- NA
  for (hh in c("NH", "SH")) {
    sel <- if (hh == "NH") which(lat2 >= 0) else which(lat2 < 0)
    v <- vapply(seq_len(12), function(m) {
      kk <- which(mo[k] == m)
      x <- sst[, sel, kk, drop = FALSE]
      w <- array(rep(w_latrep <- rep(w2[sel], each = dim(sst)[1]), length(kk)), dim = dim(x))
      ok <- is.finite(x); stats::weighted.mean(x[ok], w[ok])
    }, 0)
    key <- sprintf("%s_%d-%d", hh, win[1], win[2])
    ocean[[key]] <- sc_harm(v)
    sc_show(sprintf("sst %s %d-%d", hh, win[1], win[2]), ocean[[key]])
  }
}
nc_close(nc)

# =====================================================================
cat("\n=== ARE THE HEMISPHERES EXACTLY ANTIPHASE? (the model assumes they are) ===\n")
cat("R/model.R applies sgn = -1 in the SH, i.e. the SH cycle is the NH sine\n")
cat("flipped: an assumption of EXACTLY 6 months' separation. Measured:\n")
dm <- function(a, b) ((a - b + 0.5) %% 1 - 0.5) * 12
cat(sprintf("  land (all cells)      NH peak %.2f, SH peak %.2f -> separation %+.2f mo (model: 6.00)\n",
            land$NH_all$peak_month, land$SH_all$peak_month,
            abs(dm(land$NH_all$peak_frac, land$SH_all$peak_frac))))
k1 <- sprintf("NH_%d-%d", SC_SST_WIN[1], SC_SST_WIN[2]); k2 <- sub("^NH", "SH", k1)
cat(sprintf("  sst  (%d-%d)        NH peak %.2f, SH peak %.2f -> separation %+.2f mo (model: 6.00)\n",
            SC_SST_WIN[1], SC_SST_WIN[2], ocean[[k1]]$peak_month, ocean[[k2]]$peak_month,
            abs(dm(ocean[[k1]]$peak_frac, ocean[[k2]]$peak_frac))))

out <- list(land = land, ocean = ocean, months = SC_MONTHS,
            land_source = "CRU 1961-90 absolute climatology (Jones et al. 1999, doi:10.1029/1999RG900002)",
            ocean_source = "NOAA ERSSTv5 (Huang et al. 2017, doi:10.1175/JCLI-D-16-0836.1)",
            sst_window = SC_SST_WIN, sst_window_alt = SC_SST_WIN_ALT,
            land_bands = SC_LAND_BANDS, lag_zero_offset = SC_LAG_ZERO_OFFSET,
            land_mask = list(source = "CRUTEM.5.1.0.0 gridded coverage",
                             window = SC_MASK_WIN, min_months = SC_MASK_MIN_MO,
                             area_frac = land_area_frac),
            note = paste("AREA-weighted. The model's seas_T_amp_* is respiration-weighted and",
                         "sst_seas_amp_* is gas-exchange-weighted; these are PRIOR ANCHORS,",
                         "not values to prescribe. Built by data-raw/build_seasonal_climatology.R."))
saveRDS(out, SC_OUT)
cat(sprintf("\nwrote %s\n", SC_OUT))
