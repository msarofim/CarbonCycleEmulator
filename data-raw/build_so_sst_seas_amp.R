# =====================================================================
# build_so_sst_seas_amp.R -- the SOUTHERN-OCEAN BAND (40-90 S) seasonal SST
# half-amplitude, COMPUTED from ERSSTv5 rather than typed.
#
# WHY THIS EXISTS. `.ENT_SO_SST_AMP` (R/constants.R) was a typed 3.0 labeled
# "K, seasonal SST half-amplitude of the 40-90 S BAND (ERSSTv5)", with a comment
# asserting the band "swings harder than the hemisphere containing it". The
# 2026-09-09t whole-model review flagged it and 09-09v CONFIRMED the flag by
# recomputation: **3.0 is the PEAK-TO-PEAK, labeled a half-amplitude** -- a true
# factor of 2 -- and the band actually swings LESS than the hemisphere
# (1.4995 < 1.7464), so the comment was falsified like-for-like too. It reads
# true only by comparing a p2p against a half-amp ⇒ [[amp_definition_mismatch]],
# [[like_for_like_forcing]].
#
# ⭐ SO THE NUMBER IS COMPUTED HERE AND READ FROM THE PRODUCT, not re-typed at a
# corrected value -- which would be the same defect at a better number
# ([[derived_must_mean_computed]]). Same idiom as build_h_ml_prior.R.
#
# ⛔ GATE 1 IS THE POINT: this file recomputes SST_SEAS_AMP_SH_OBS = 1.74644, the
# constant the repo ALREADY ships, from the same product, mask convention,
# window and estimator. If the band row is to be trusted, the row beside it that
# is already registered must come back. A band amplitude that did not reproduce
# its own hemisphere would be measuring the estimator, not the ocean.
# The estimator, window and weighting are lifted from
# data-raw/build_seasonal_climatology.R -- NOT reimplemented -- for the same
# reason ([[two_gates_one_mechanism]]).
#
# Usage: Rscript data-raw/build_so_sst_seas_amp.R  -> data/obs_so_sst_seas_amp.rds
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
suppressPackageStartupMessages(library(ncdf4))

# ---- named constants: every label and check below derives from these -
SO_NC       <- ccx_path("data-raw", "downloads", "ersst_v5_sst_mnmean.nc")
SO_WIN      <- c(1975, 2024)          # = LIK_SEAS_WINDOW, as build_seasonal_climatology.R
SO_BAND     <- c(-90, -40)            # the entrainment band, GATE S's own convention
SO_OUT      <- ccx_path("data", "obs_so_sst_seas_amp.rds")
SO_GATE_REF <- ccx_const("SST_SEAS_AMP_SH_OBS")   # 1.74644 K, already shipped
SO_GATE_TOL <- 5e-5                   # 5 s.f. on a 5-s.f. registered constant
# OPTION B (2026-09-11, prereg ruling 3): the HS box (`ml_hi`) gets an SST seasonal amplitude PINNED
# to the observation, per hemisphere, over the box's OWN cap -- poleward of the boundary DERIVED from
# hs_frac (57.14 deg at 0.16, as data-raw/build_mld_targets.R), with the LS cap (0-57) beside it for
# the reader and the 40-deg convention for comparison with GATE S. The rows above are NOT touched.
SO_LAT_HS   <- asin(1 - CCX_STRUCT_HILDA$hs_frac) * 180 / pi   # DERIVED: 57.14 deg
SO_LAT_40   <- 40

# the harmonic estimator, verbatim in substance from build_seasonal_climatology.R
so_harm <- function(v) {
  phi <- (seq_len(12) - 0.5) / 12
  a1 <- 2 * mean(v * sin(2 * pi * phi)); b1 <- 2 * mean(v * cos(2 * pi * phi))
  r1 <- sqrt(a1^2 + b1^2); pk <- (atan2(a1, b1) / (2 * pi)) %% 1
  list(mean = mean(v), half_amp = r1, p2p = 2 * r1, peak_month = 12 * pk, clim = v)
}

nc   <- nc_open(SO_NC)
tim  <- ncvar_get(nc, "time"); lat <- ncvar_get(nc, "lat")
yrmo <- as.POSIXlt(as.Date(tim, origin = "1800-01-01"))
yr   <- yrmo$year + 1900; mo <- yrmo$mon + 1
k    <- which(yr >= SO_WIN[1] & yr <= SO_WIN[2])
sst  <- ncvar_get(nc, "sst", start = c(1, 1, min(k)), count = c(-1, -1, length(k)))
sst[sst < -100 | sst > 100] <- NA
nc_close(nc)
w2 <- cos(lat * pi / 180)

so_clim <- function(sel) vapply(seq_len(12), function(m) {
  kk <- which(mo[k] == m)
  x  <- sst[, sel, kk, drop = FALSE]
  w  <- array(rep(rep(w2[sel], each = dim(sst)[1]), length(kk)), dim = dim(x))
  ok <- is.finite(x); stats::weighted.mean(x[ok], w[ok])
}, 0)

h_SH   <- so_harm(so_clim(which(lat <  0)))
h_band <- so_harm(so_clim(which(lat >= SO_BAND[1] & lat <= SO_BAND[2])))
h_NH   <- so_harm(so_clim(which(lat >= 0)))

cat(sprintf("ERSSTv5 %d-%d, cos(lat)-weighted, first annual harmonic:\n", SO_WIN[1], SO_WIN[2]))
for (r in list(c("NH hemisphere", "NH"), c("SH hemisphere", "SH"),
               c(sprintf("BAND %g-%g S", -SO_BAND[2], -SO_BAND[1]), "band"))) {
  h <- get(paste0("h_", r[2]))
  cat(sprintf("  %-18s half-amp %7.4f K | p2p %7.4f K | peak month %5.2f\n",
              r[1], h$half_amp, h$p2p, h$peak_month))
}

# ---- ⛔ GATE 1: reproduce the constant the repo already ships ---------
gate_z <- abs(h_SH$half_amp - SO_GATE_REF)
cat(sprintf("\n  GATE 1  SH half-amp %.5f vs registered SST_SEAS_AMP_SH_OBS %.5f -> |d| %.2e : %s\n",
            h_SH$half_amp, SO_GATE_REF, gate_z, if (gate_z < SO_GATE_TOL) "PASS" else "FAIL"))
if (gate_z >= SO_GATE_TOL)
  stop("GATE 1 FAILED: this file does not reproduce the hemispheric constant the repo ",
       "already ships from the same product, so its BAND row is measuring the estimator, ",
       "not the ocean. Do not adopt the band number until this closes.")
# the gate must be able to fail ([[mutation_test_gates]])
stopifnot(gate_z < SO_GATE_TOL,
          abs(h_SH$p2p - SO_GATE_REF) >= SO_GATE_TOL,      # a p2p must NOT pass
          abs(h_band$half_amp - SO_GATE_REF) >= SO_GATE_TOL) # nor the band
cat("          and FAILS on the p2p and on the band row -- it is not a tautology.\n")

# ---- what this retires -------------------------------------------------
cat(sprintf("\n  the shipped .ENT_SO_SST_AMP = 3.0 is the BAND P2P (%.4f), not its half-amp (%.4f)\n",
            h_band$p2p, h_band$half_amp))
cat(sprintf("  and 'the band swings harder than the hemisphere' is FALSE like-for-like: %.4f < %.4f\n",
            h_band$half_amp, h_SH$half_amp))

# ---- OPTION B: the per-hemisphere caps ---------------------------------
so_cap <- function(hem, lo, hi) {
  sel <- if (hem == "NH") which(lat >= lo & lat < hi) else which(lat <= -lo & lat > -hi)
  h <- so_harm(so_clim(sel)); h$lat <- c(lo, hi); h$n_lat <- length(sel); h
}
caps <- list(hs_NH = so_cap("NH", SO_LAT_HS, 90), hs_SH = so_cap("SH", SO_LAT_HS, 90),
             ls_NH = so_cap("NH", 0, SO_LAT_HS), ls_SH = so_cap("SH", 0, SO_LAT_HS),
             pole40_NH = so_cap("NH", SO_LAT_40, 90), pole40_SH = so_cap("SH", SO_LAT_40, 90))
cat(sprintf("
  OPTION B caps (HS/LS boundary derived from hs_frac %.2f = %.2f deg):
", CCX_STRUCT_HILDA$hs_frac, SO_LAT_HS))
for (n in names(caps)) { h <- caps[[n]]
  cat(sprintf("  %-10s [%5.2f, %2g) | mean SST %6.2f C | half-amp %6.4f K | p2p %6.4f | peak month %5.2f
",
              n, h$lat[1], h$lat[2], h$mean, h$half_amp, h$p2p, h$peak_month)) }
# the caps must tile the hemisphere: an area-weighted recombination is a sanity check, not a gate
cat(sprintf("  (model sst_hs is %g C; the LS caps are what the fitted sst_seas_amp_NH/SH stand beside)
", CCX_STRUCT_HILDA$sst_hs))

out <- list(caps = lapply(caps, function(h) h[c("mean", "half_amp", "p2p", "peak_month", "lat", "clim")]),
            lat_hs = SO_LAT_HS,
            band_half_amp_K = h_band$half_amp, band_p2p_K = h_band$p2p,
            band_peak_month = h_band$peak_month, band_lat = SO_BAND,
            sh_half_amp_K = h_SH$half_amp, nh_half_amp_K = h_NH$half_amp,
            gate_ref = SO_GATE_REF, gate_abs_diff = gate_z, window = SO_WIN,
            estimator = "first annual harmonic of the cos(lat)-weighted monthly climatology, month centres",
            source = paste("NOAA ERSSTv5 (Huang et al. 2017, doi:10.1175/JCLI-D-16-0836.1),",
                           sprintf("%g-%g S band, %d-%d.", -SO_BAND[2], -SO_BAND[1], SO_WIN[1], SO_WIN[2])),
            built = format(Sys.time(), "%Y-%m-%d %H:%M"))
saveRDS(out, SO_OUT)
cat(sprintf("\nsaved %s\n", SO_OUT))
