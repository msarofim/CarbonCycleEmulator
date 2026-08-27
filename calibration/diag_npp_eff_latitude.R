# =====================================================================
# diag_npp_eff_latitude.R -- WHAT IS THE NPP-WEIGHTED EFFECTIVE LATITUDE,
#                            AND IS 75 N DEFENSIBLE?
#
# THE SUSPECT. CCX_SEAS_PHI_EFF["NH"] = 75 deg is described in R/model.R as a
# "flux-weighted effective" latitude, but handoff 2026-08-20d section 6 records
# what it actually is: a knob fitted OFFLINE against MLO, under the pre-08-18
# sine respiration, i.e. against a model that no longer exists. It gives the NEP
# shape a unit-mean peak-to-peak of 2.80, which on ~28 GtC/yr of NH NPP is a
# ~78 GtC/yr seasonal swing -- and the channel budget
# (diag_seas_channel_decomp.R) found NEP and respiration each about 2x the net
# and 6.6 months antiphase, cancelling. An over-driven NEP channel is exactly
# what would force an over-large respiration channel to cancel it, and 48 K of
# seasonal land temperature is what that cancellation costs.
#
# 75 N is also, on its face, far poleward of any plausible NPP-weighted
# latitude. This script turns that impression into a number, from the MOD17
# field already on disk -- no new download.
#
# THE MEASUREMENT, and WHY IT IS NOT SIMPLY A WEIGHTED MEAN LATITUDE. The
# constant does not enter the model as a latitude. It enters as a SHAPE: the
# model asserts
#     NPP_h(t) = NPP_h * insol(phi_eff, t - lag) / mean_t insol(phi_eff, .)
# for the hemisphere as a whole. Apply that same assertion per grid cell -- the
# model's own premise, taken locally -- and the hemisphere's aggregate shape is
#     N_agg(t) = sum_i w_i * insol(phi_i, t) / mean_t insol(phi_i, .)   / sum_i w_i
# with w_i the cell's ANNUAL NPP. phi_eff is then the latitude whose own
# normalised shape best matches N_agg. Because insolation is strongly nonlinear
# in latitude (polar night rectifies the shape), that is NOT the same number as
# the NPP-weighted mean latitude, and both are reported so the difference is
# visible rather than assumed away.
#
# THE FIT IS LAG-INVARIANT. seas_lag_p is a FREE parameter (phenology), so any
# phase offset between a candidate phi and N_agg can be absorbed by it, and a
# phi chosen on phase would be measuring the wrong thing. phi_eff is therefore
# fitted jointly with a free time shift, and the shift it wants is reported
# separately as a lag consequence. Amplitude-only and phase-only matches are
# reported alongside: the whole lesson of this arc is that reading one of them
# in isolation misleads (amp_definition_mismatch).
#
# WHAT THIS DOES NOT MEASURE, stated plainly. MOD17A3HGF is an ANNUAL product.
# It gives the SPATIAL distribution of NPP, not its seasonal cycle. So this
# script cannot test the model's premise that NPP follows insolation; it takes
# that premise as given and asks only the aggregation question -- given the
# premise, which single latitude represents the hemisphere. If the premise is
# itself wrong (temperature, water and phenology all matter, and boreal NPP
# does not switch on with the light), that is a SEPARATE defect and would need
# an 8-day product (MOD17A2H GPP) to test. Do not read a phi_eff from here as
# "the observed NPP seasonality".
#
# AMPLITUDE CONVENTION: PEAK-TO-PEAK of the unit-mean shape throughout,
# max(n) - min(n), matching the 2.80 quoted for 75 N in handoff 20d section 6.
# Not semi-amplitude. This is the definition that inverted a conclusion twice
# (amp_definition_mismatch) -- it is stated once here and used everywhere below.
#
# Usage:  Rscript calibration/diag_npp_eff_latitude.R
# =====================================================================
suppressPackageStartupMessages(library(ncdf4))
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)

EL_NPP_DIR   <- "data-raw/downloads/mod17_npp"
EL_VAR       <- "npp"
EL_R_EARTH   <- 6371000
EL_NVALID_FULL <- 14400        # `numberofvalidvalues` of a FULL cell at the equator
EL_TOTAL_OK  <- c(30, 80)      # PgC/yr, the same read-the-file-right gate as
                               # data-raw/build_npp_hemispheric.R
EL_NGRID     <- 720            # points per year; matches ccx_seas_norms()'s norm grid
EL_PHI_GRID  <- seq(0.5, 89.5, by = 0.05)   # candidate effective latitudes, NH
EL_MODE_FILE <- ccx_mode_file()

# ---------------------------------------------------------------------
# 1. NPP by latitude row, from MOD17
# ---------------------------------------------------------------------
# Only latitude matters for insolation, so the field collapses to a latitude
# profile with no loss. The valid-area weighting is build_npp_hemispheric.R's,
# for the reason documented there: `npp` is the mean over VALID pixels, not the
# cell mean, and MOD17's sinusoidal pixels are equal-area so the pixel COUNT is
# proportional to valid area.
fs <- list.files(EL_NPP_DIR, pattern = "\\.nc$", recursive = TRUE, full.names = TRUE)
stopifnot(length(fs) > 10)
yrs <- as.integer(sub(".*__(\\d{4})0101__.*", "\\1", basename(fs)))
o <- order(yrs); fs <- fs[o]; yrs <- yrs[o]

nc  <- nc_open(fs[1])
lat <- ncvar_get(nc, "lat"); lon <- ncvar_get(nc, "lon"); nc_close(nc)
dlat <- abs(diff(lat)[1]); dlon <- abs(diff(lon)[1])
lat_hi <- (lat + dlat / 2) * pi / 180; lat_lo <- (lat - dlat / 2) * pi / 180
area_lat <- EL_R_EARTH^2 * (dlon * pi / 180) * (sin(lat_hi) - sin(lat_lo))
px_area  <- area_lat[which.min(abs(lat))] / EL_NVALID_FULL

cat(sprintf("MOD17 %d files %d-%d, %d x %d grid, pixel area %.0f m2\n",
            length(fs), min(yrs), max(yrs), length(lon), length(lat), px_area))

npp_lat <- matrix(0, nrow = length(lat), ncol = length(fs))   # PgC/yr per lat row
for (i in seq_along(fs)) {
  nc <- nc_open(fs[i]); v <- ncvar_get(nc, EL_VAR)
  nv <- ncvar_get(nc, "numberofvalidvalues"); nc_close(nc)
  v[!is.finite(v)] <- NA; nv[!is.finite(nv) | nv < 0] <- 0
  flux <- v * (nv * px_area) / 1e12                            # PgC/yr per cell
  npp_lat[, i] <- colSums(flux, na.rm = TRUE)                  # lon is dim 1
}
w_lat <- rowMeans(npp_lat)                                     # PgC/yr, 2001-2023 mean
tot <- sum(w_lat)
if (tot < EL_TOTAL_OK[1] || tot > EL_TOTAL_OK[2])
  stop(sprintf("global NPP %.1f PgC/yr outside the gate [%g, %g] -- file read wrong",
               tot, EL_TOTAL_OK[1], EL_TOTAL_OK[2]))
cat(sprintf("global %.2f PgC/yr, NH %.2f (share %.4f), SH %.2f  [gate PASS]\n\n",
            tot, sum(w_lat[lat >= 0]), sum(w_lat[lat >= 0]) / tot, sum(w_lat[lat < 0])))

# ---------------------------------------------------------------------
# 2. The aggregate shape, and the effective latitude that matches it
# ---------------------------------------------------------------------
tt   <- (seq_len(EL_NGRID) - 0.5) / EL_NGRID
p2p  <- function(x) max(x) - min(x)
peak_mo <- function(x) (tt[which.max(x)] * 12) %% 12          # month index, 0 = Jan 1
shape <- function(phi) { v <- ccx_insol(phi, tt); v / mean(v) }
roll  <- function(x, k) if (k == 0L) x else c(x[(k + 1):length(x)], x[seq_len(k)])

# A candidate latitude is scored on SHAPE after its best circular time shift is
# removed, because seas_lag_p can absorb any shift. Done by FFT, because brute
# force is 720 shifts x 1780 candidates x 720 points. The identity used is
#   min_k ||roll(s,k) - t||^2 = ||s||^2 + ||t||^2 - 2 max_k corr(s,t)[k]
# and the FFT correlation is GATED against the brute-force loop below rather
# than trusted -- a transform convention error here would silently return a
# plausible wrong latitude.
xcorr <- function(s, t) Re(stats::fft(Conj(stats::fft(s)) * stats::fft(t), inverse = TRUE)) / length(s)
fit_shift <- function(s, t) {
  cc <- xcorr(s, t); k <- which.max(cc) - 1L
  list(k = k, sse = sum(s^2) + sum(t^2) - 2 * cc[k + 1L],
       shift_mo = -(k / length(s)) * 12)     # months; negative k means shape is EARLY
}
{ # GATE: FFT vs brute force, on a shape that is not one of the candidates
  s <- shape(52.3); t <- shape(38.7)
  bf <- vapply(seq_len(EL_NGRID) - 1L, function(k) sum((roll(s, k) - t)^2), numeric(1))
  ff <- fit_shift(s, t)
  stopifnot(abs(min(bf) - ff$sse) < 1e-8 * sum(t^2),
            (which.min(bf) - 1L) == ff$k)
  cat(sprintf("FFT shift-fit gated against brute force: sse %.6g == %.6g, k %d == %d  [PASS]\n\n",
              min(bf), ff$sse, which.min(bf) - 1L, ff$k))
}

for (h in c("NH", "SH")) {
  sel <- if (h == "NH") lat >= 0 else lat < 0
  w   <- w_lat[sel]; la <- lat[sel]
  w[!is.finite(w) | w < 0] <- 0
  # Per-cell unit-mean shapes, NPP-weighted. Cells with no NPP drop out of the
  # weighted mean by construction, so no land mask is needed here.
  S   <- vapply(la, shape, numeric(EL_NGRID))                  # EL_NGRID x nlat
  agg <- as.vector(S %*% w) / sum(w)
  phi_bar <- sum(w * la) / sum(w)                              # the naive answer
  gr  <- EL_PHI_GRID * (if (h == "NH") 1 else -1)              # signed candidate grid
  ff  <- lapply(gr, function(phi) fit_shift(shape(phi), agg))
  i_hat   <- which.min(vapply(ff, function(x) x$sse, numeric(1)))
  phi_hat <- gr[i_hat]
  # amplitude-only and phase-only matches, for the contrast
  a_of <- vapply(gr, function(phi) p2p(shape(phi)), numeric(1))
  phi_amp <- gr[which.min(abs(a_of - p2p(agg)))]
  m_of <- vapply(gr, function(phi) peak_mo(shape(phi)), numeric(1))
  phi_pha <- gr[which.min(abs(((m_of - peak_mo(agg) + 6) %% 12) - 6))]
  shipped <- CCX_SEAS_PHI_EFF[[h]]

  cat(sprintf("=== %s ===  NPP %.2f PgC/yr over %d latitude rows with NPP > 0\n",
              h, sum(w), sum(w > 0)))
  cat(sprintf("  %-34s %8s %10s %10s %10s\n", "", "phi", "p2p", "peak mo", "rms resid"))
  row <- function(lab, phi, note = "") {
    s <- shape(phi); f <- fit_shift(s, agg)
    cat(sprintf("  %-34s %8.2f %10.3f %10.2f %10.4f%s\n", lab, phi, p2p(s), peak_mo(s),
                sqrt(f$sse / EL_NGRID), note))
  }
  cat(sprintf("  %-34s %8s %10.3f %10.2f %10s\n", "AGGREGATE (NPP-weighted shapes)", "--",
              p2p(agg), peak_mo(agg), "--"))
  row("CCX_SEAS_PHI_EFF", shipped, "   <- SHIPPED")
  row("shape-matched (lag-invariant)", phi_hat, "   <- MEASURED")
  row("NPP-weighted MEAN latitude", phi_bar)
  row("amplitude-matched only", phi_amp)
  row("phase-matched only", phi_pha)
  cat(sprintf("  shipped / aggregate peak-to-peak = %.3f  (>1 = the model OVER-drives NEP)\n",
              p2p(shape(shipped)) / p2p(agg)))
  # PHASE CARRIES NO INFORMATION HERE, and the table above will look like a bug
  # if that is not said. Daily-mean insolation is symmetric about the solstice
  # at EVERY extratropical latitude, so every candidate peaks in the same month
  # as the aggregate and every best shift is 0 to the grid's resolution. The
  # "phase-matched only" row is therefore degenerate -- it returns the lowest
  # latitude on the grid whose peak still lands on the solstice, which is a
  # property of the tropics, not a measurement. ALL the information about
  # phi_eff is in the SHAPE, and within the shape almost all of it is in the
  # peak-to-peak. Read the rms residual column, not the peak month.
  cat(sprintf("  best time shifts: measured %+.2f mo, shipped %+.2f mo -- both 0 by the\n",
              ff[[i_hat]]$shift_mo, fit_shift(shape(shipped), agg)$shift_mo))
  cat("  symmetry just described, so seas_lag_p has NOTHING to absorb if phi moves.\n\n")
}

# ---------------------------------------------------------------------
# 3. What it would cost the NEP channel, at the adopted mode
# ---------------------------------------------------------------------
# Priced in GtC/yr of seasonal swing, which is the quantity handoff 20d section 6
# put the suspicion in. NOT a logL -- that needs the profile with the rebuild
# harness (diag_seas_obs_drivers.R's idiom), which is the next step and is not
# done here.
if (file.exists(EL_MODE_FILE)) {
  fit <- readRDS(EL_MODE_FILE); pm <- fit$par_mode
  npp0 <- ccx_const("NPP_GLOBAL_PI")
  cat(sprintf("=== SEASONAL NEP SWING AT THE ADOPTED MODE (arm %s) ===\n", CCX_MODE_CANONICAL))
  cat(sprintf("  NPP_GLOBAL_PI %.1f GtC/yr, npp_frac_NH %.4f -> NH %.1f GtC/yr\n",
              npp0, pm[["npp_frac_NH"]], npp0 * pm[["npp_frac_NH"]]))
  for (h in c("NH", "SH")) {
    npph <- npp0 * (if (h == "NH") pm[["npp_frac_NH"]] else 1 - pm[["npp_frac_NH"]])
    cat(sprintf("  %s: shipped phi %+5.1f -> %6.1f GtC/yr swing\n",
                h, CCX_SEAS_PHI_EFF[[h]], npph * p2p(shape(CCX_SEAS_PHI_EFF[[h]]))))
  }
  cat("  (Compare: the whole observed MLO cycle is ~6.75 ppm = ~14 GtC of\n")
  cat("   atmospheric carbon peak-to-trough. A swing many times that is not\n")
  cat("   impossible -- most of it is cancelled by respiration -- but it is the\n")
  cat("   cancellation that section 3 of handoff 20d indicted.)\n")
} else {
  cat(sprintf("(%s absent -- skipping the GtC pricing)\n", EL_MODE_FILE))
}
