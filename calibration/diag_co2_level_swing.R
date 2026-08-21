# =====================================================================
# diag_co2_level_swing.R -- IS THE 9 ppm SWING THE MODEL, OR IS IT THE ICE?
#
# diag_rep_dC_shape.R GATE D reported the model running -4.12 ppm against
# Antarctic CO2 over 1900-1940 and +5.08 over 2000-2025, and read that as a
# structural misfit with its crossover in the 1940s. Marcus 2026-08-21 raised
# the obvious competing hypothesis, and it is a good one: ICE AND AIR ARE NOT
# THE SAME MEASUREMENT. Firn air is enclosed over years, so an ice sample is a
# SMOOTHED atmosphere with a gas age offset from its ice age; different cores
# have different accumulation rates and therefore different smoothing widths and
# different offsets; and the mid-century is exactly where several CO2 products
# are known to be awkward.
#
# GATE D's own cross-check does NOT settle this. It showed ice and SPO flask
# agreeing to 0.31 ppm over 54 overlapping years -- but the overlap starts in
# 1957 and THE CROSSOVER IS AT ~1945-1955, inside the window where ice is the
# only product. So the cross-check tested the wrong decade.
#
# FOUR TESTS THAT SEPARATE THE HYPOTHESES. Each one is diagnostic on its own:
#
#  1. BY CORE. The Law Dome record is five cores with two DIFFERENT gas-age
#     offsets (DE08/DE08-2 at 31 yr, DSS/DSS0506 at 60 yr) and different
#     accumulation rates. A real atmospheric misfit is the same in every core
#     that covers the same years. A product artefact is not. This is the
#     strongest test available without new data, and 98 of the 109 samples in
#     1900-1970 are DE08/DE08-2, so the crossover is largely WITHIN ONE CORE.
#
#  2. GROWTH RATE, NOT LEVEL. A level residual that swings is the integral of a
#     growth-rate residual that changes sign. If the OBSERVATIONS show a
#     mid-century pause in dCO2/dt that the model does not reproduce, the
#     crossover is that feature and nothing else -- and "is the pause real
#     atmosphere or a firn artefact" becomes the whole question. This is the
#     test that says WHERE to look rather than how big it is.
#
#  3. FIRN SMOOTHING, AS A SCAN. Convolving the model with an air-age
#     distribution before comparing is the right like-for-like. Rather than
#     assert a width per core -- which needs a citation this repo does not
#     carry -- scan Gaussian widths 0/5/10/20/30 yr and report how much of the
#     swing each one removes. If no plausible width removes it, smoothing is
#     not the explanation, and that conclusion needs no citation.
#
#  4. GAS-AGE SENSITIVITY. Shift the ice time axis +/- 10 yr and re-measure. If
#     a decade of age error can produce the swing, the swing is not evidence.
#
# Usage:  Rscript calibration/diag_co2_level_swing.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

SW_MODE_FILE <- file.path("calibration", "output", "pump_arms", "mode_fit_pumpN.rds")
SW_YEARS     <- c(1750, 2024)
SW_SMOOTH    <- c(0, 5, 10, 20, 30)     # Gaussian sd of the air-age kernel, yr
SW_AGESHIFT  <- c(-10, -5, 0, 5, 10)    # gas-age perturbation, yr
SW_EARLY     <- c(1900, 1940)           # the two windows the swing runs between
SW_LATE      <- c(1958, 1997)           # ice only, so both ends are ONE product

md <- readRDS(SW_MODE_FILE); pm <- md$par_mode
p <- ccx_default_params()
for (n in intersect(names(p), CCX_PARAM_NAMES)) p[[n]] <- pm[[n]]
p$pump_mode <- md$pump_mode
sp <- ccx_spinup(p)
F  <- ccx_build_forcing("historical", SW_YEARS, prod_c14 = sp$prod_c14,
                        bomb_total_kmol = pm$bomb_total, luc_scale = pm$luc_scale)
o  <- ccx_run_fast(sp, F)$out
# Law Dome is ANTARCTIC: the like-for-like model series is the SH box.
mod_y <- tapply(o$co2_SH, floor(o$t + 1e-9), mean)
mod_t <- as.numeric(names(mod_y))

ice <- as.data.frame(ccx_prepare_obs()$ice)
ice$core <- sub("[ ].*$", "", ice$SampleID)
at <- function(yr, v = mod_y, tt = mod_t) stats::approx(tt, v, xout = yr)$y

cat(sprintf("mode %s   n_ice %d over %d-%d\n\n", basename(SW_MODE_FILE),
            nrow(ice), min(ice$year), max(ice$year)))

# ---- TEST 1: BY CORE ------------------------------------------------
cat("TEST 1 -- residual (model SH box - ice) BY CORE, ppm\n")
cat(sprintf("  %-9s %6s %6s", "window", "n", "all"))
cores <- sort(unique(ice$core))
for (cc in cores) cat(sprintf(" %8s", cc))
cat("\n")
wins <- list(c(1750, 1850), c(1850, 1900), c(1900, 1940),
             c(1940, 1958), c(1958, 1997))
for (w in wins) {
  k <- ice$year >= w[1] & ice$year < w[2]
  if (!sum(k)) next
  r <- at(ice$year[k]) - ice$CO2ppm[k]
  cat(sprintf("  %4d-%-4d %6d %+6.2f", w[1], w[2], sum(k), mean(r, na.rm = TRUE)))
  for (cc in cores) {
    kk <- ice$core[k] == cc
    cat(if (sum(kk) >= 3) sprintf(" %+8.2f", mean(r[kk], na.rm = TRUE))
        else sprintf(" %8s", if (sum(kk)) paste0("(", sum(kk), ")") else "-"))
  }
  cat("\n")
}
# The decisive cell: do the two gas-age families agree where they OVERLAP?
ov <- ice$year >= 1900 & ice$year < 1962
fam <- ifelse(ice$core %in% c("DE08", "DE08-2"), "dage31", "dage60")
rr  <- at(ice$year) - ice$CO2ppm
cat(sprintf("\n  1900-1962 by gas-age family:  dage31 (n=%d) %+.2f   dage60 (n=%d) %+.2f   diff %+.2f ppm\n",
            sum(ov & fam == "dage31"), mean(rr[ov & fam == "dage31"], na.rm = TRUE),
            sum(ov & fam == "dage60"), mean(rr[ov & fam == "dage60"], na.rm = TRUE),
            mean(rr[ov & fam == "dage31"], na.rm = TRUE) -
              mean(rr[ov & fam == "dage60"], na.rm = TRUE)))
cat(sprintf("  swing WITHIN DE08 alone (%d-%d vs %d-%d): %+.2f -> %+.2f ppm\n",
            SW_EARLY[1], SW_EARLY[2], SW_LATE[1], SW_LATE[2],
            mean(rr[ice$core == "DE08" & ice$year >= SW_EARLY[1] & ice$year < SW_EARLY[2]], na.rm = TRUE),
            mean(rr[ice$core == "DE08" & ice$year >= SW_LATE[1] & ice$year < SW_LATE[2]], na.rm = TRUE)))

# ---- TEST 2: GROWTH RATE -------------------------------------------
# Decadal growth from a LOESS through the ice, so single-sample scatter does not
# masquerade as a growth-rate feature, against the model's own decadal growth.
cat("\nTEST 2 -- decadal growth rate dCO2/dt, ppm/yr\n")
lo <- stats::loess(CO2ppm ~ year, data = ice[ice$year >= 1850, ], span = 0.25)
gy <- seq(1860, 1990, by = 5)
gi <- stats::predict(lo, data.frame(year = gy))
cat(sprintf("  %-11s %8s %8s %8s\n", "decade", "ice", "model", "model-ice"))
for (d in seq(1870, 1980, by = 10)) {
  i0 <- which.min(abs(gy - (d - 5))); i1 <- which.min(abs(gy - (d + 5)))
  if (is.na(gi[i0]) || is.na(gi[i1])) next
  gr_o <- (gi[i1] - gi[i0]) / (gy[i1] - gy[i0])
  gr_m <- (at(d + 5) - at(d - 5)) / 10
  cat(sprintf("  %4ds       %8.3f %8.3f %+8.3f\n", d, gr_o, gr_m, gr_m - gr_o))
}

# ---- TEST 3: FIRN SMOOTHING, SCANNED -------------------------------
# The model is convolved, NOT the observations: an ice sample already IS a
# smoothed atmosphere, so the like-for-like operation is to smooth the model
# down to it. A Gaussian is a stand-in for the true (skewed) age distribution;
# the point of the scan is the SIZE of the effect, not its exact shape.
cat("\nTEST 3 -- model smoothed by a Gaussian air-age kernel before comparing\n")
cat(sprintf("  %-8s %10s %10s %10s\n", "sd (yr)", "1900-1940", "1958-1997", "swing"))
for (s in SW_SMOOTH) {
  if (s == 0) { sm <- mod_y } else {
    w <- stats::dnorm(seq(-4 * s, 4 * s), 0, s); w <- w / sum(w)
    sm <- stats::filter(mod_y, w, sides = 2)
    sm[is.na(sm)] <- mod_y[is.na(sm)]
  }
  e <- mean(at(ice$year[ice$year >= SW_EARLY[1] & ice$year < SW_EARLY[2]], sm) -
              ice$CO2ppm[ice$year >= SW_EARLY[1] & ice$year < SW_EARLY[2]], na.rm = TRUE)
  l <- mean(at(ice$year[ice$year >= SW_LATE[1] & ice$year < SW_LATE[2]], sm) -
              ice$CO2ppm[ice$year >= SW_LATE[1] & ice$year < SW_LATE[2]], na.rm = TRUE)
  cat(sprintf("  %-8d %+10.2f %+10.2f %10.2f\n", s, e, l, l - e))
}

# ---- TEST 4: GAS-AGE SENSITIVITY -----------------------------------
cat("\nTEST 4 -- ice time axis shifted (positive = ice air is YOUNGER than stated)\n")
cat(sprintf("  %-8s %10s %10s %10s\n", "shift", "1900-1940", "1958-1997", "swing"))
for (sh in SW_AGESHIFT) {
  ke <- ice$year >= SW_EARLY[1] & ice$year < SW_EARLY[2]
  kl <- ice$year >= SW_LATE[1]  & ice$year < SW_LATE[2]
  e <- mean(at(ice$year[ke] + sh) - ice$CO2ppm[ke], na.rm = TRUE)
  l <- mean(at(ice$year[kl] + sh) - ice$CO2ppm[kl], na.rm = TRUE)
  cat(sprintf("  %+-8d %+10.2f %+10.2f %10.2f\n", sh, e, l, l - e))
}
