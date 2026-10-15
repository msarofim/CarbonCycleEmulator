# =====================================================================
# build_volcanic_aod.R -- STRATOSPHERIC AEROSOL OPTICAL DEPTH, hemispheric
#   -> data/forcing_volcanic_aod.rds
#
# SOURCE. NASA GISS `tau_reff_CMIP7-2-2-1.nc` (the CMIP7 stratospheric aerosol
# forcing dataset as distributed by GISS). CHOSEN FOR LIKE-FOR-LIKE: this
# project's FaIR work migrated to calib 1.6.0 + CMIP7 drivers on 2026-08-28, so
# the volcanic series the emulator uses should be the one FaIR is being driven
# with, not Sato-Lacis or CMIP6. [[fair_calib_160_migration]]
#
# WHAT IS IN IT. `tau` = stratospheric AOD on a 24-band latitude grid, monthly,
# 1850-01 .. 2023-12 (2088 months). Also `reff` (effective radius, micron) and
# `tau_lvl` (4 levels), neither used here.
#
# ⚠ TWO COVERAGE GAPS, BOTH DELIBERATE AND BOTH FLAGGED IN THE OUTPUT:
#   1. PRE-1850 IS ZERO. The model runs from 1750, so Laki (1783), the 1808/09
#      unidentified eruption and TAMBORA (1815) are all MISSING. Filling them
#      needs eVolv2k (Toohey & Sigl 2017); until then any pre-1850 volcanic
#      story -- including "the year without a summer" -- is NOT AVAILABLE.
#   2. 2024 IS HELD AT THE 2023-12 VALUE. The record ends 2023-12 and the model
#      runs to 2024; the period is volcanically quiet so this is a small,
#      declared extrapolation, not a gap-fill.
#
# AREA WEIGHTING is exact: bands are weighted by sin(lat_hi) - sin(lat_lo) from
# `lat_bnds`, not by cos(center). Hemispheric means use the bands each side of
# the equator; the grid is symmetric so no band straddles it (GATE 2).
#
# Run:  Rscript data-raw/build_volcanic_aod.R
# =====================================================================
suppressWarnings(suppressMessages(library(ncdf4)))

VA_SRC  <- "data-raw/downloads/tau_reff_CMIP7-2-2-1.nc"
VA_OUT  <- "data/forcing_volcanic_aod.rds"
VA_END  <- 2024                       # extend-and-hold target year
# ---- SANITY GATES, from the published literature, fixed before the run.
VA_PIN_YR   <- c(1991.5, 1992.5)      # Pinatubo peak window
VA_PIN_BAND <- c(0.08, 0.20)          # global-mean 550 nm AOD at the peak
VA_QUIET    <- 0.01                   # global AOD in a volcanically quiet year
VA_QUIET_YR <- 2005

nc  <- nc_open(VA_SRC)
tau <- ncvar_get(nc, "tau")                       # [lat, month]
lat <- ncvar_get(nc, "lat")
lb  <- ncvar_get(nc, "lat_bnds")                  # [2, lat]
tm  <- nc$dim[["month"]]$vals                     # days since 1850-01-01
nc_close(nc)

# ⚠ GATE 0 -- a NetCDF fill value that never got applied is this repo's
# [[fillvalue_not_applied]] incident. Check the finite fraction after every read.
stopifnot(all(is.finite(tau)), all(is.finite(lat)), all(is.finite(lb)))
stopifnot(min(tau) >= 0, max(tau) < 1)
cat(sprintf("GATE 0  finite %.1f %%, range [%.5f, %.5f]  ok\n",
            100 * mean(is.finite(tau)), min(tau), max(tau)))

# exact area weights: sin(upper) - sin(lower)
w <- abs(sin(lb[2, ] * pi / 180) - sin(lb[1, ] * pi / 180))
stopifnot(abs(sum(w) - 2) < 1e-9)                 # the whole sphere, in sin units
nh <- lat > 0; sh <- lat < 0
stopifnot(!any(abs(lat) < 1e-9), sum(nh) + sum(sh) == length(lat))
cat(sprintf("GATE 2  %d bands, %d NH / %d SH, no band straddles the equator  ok\n",
            length(lat), sum(nh), sum(sh)))

wm <- function(k) as.numeric(crossprod(tau[k, , drop = FALSE], w[k]) / sum(w[k]))
aod_g <- wm(seq_along(lat)); aod_n <- wm(which(nh)); aod_s <- wm(which(sh))

# time axis: the file is monthly from 1850-01; build decimal year at mid-month
yr0 <- 1850
n   <- length(tm)
year  <- yr0 + (seq_len(n) - 1) %/% 12
month <- (seq_len(n) - 1) %% 12 + 1
stopifnot(n == 2088, year[1] == 1850, month[1] == 1, year[n] == 2023, month[n] == 12)

d <- data.frame(year = year, month = month,
                t = year + (month - 0.5) / 12,
                aod_global = aod_g, aod_NH = aod_n, aod_SH = aod_s)

# ---- gap 2: extend-and-hold to VA_END, DECLARED
if (VA_END > max(d$year)) {
  last <- d[nrow(d), ]
  add <- do.call(rbind, lapply((max(d$year) + 1):VA_END, function(y)
    data.frame(year = y, month = 1:12, t = y + ((1:12) - 0.5) / 12,
               aod_global = last$aod_global, aod_NH = last$aod_NH, aod_SH = last$aod_SH)))
  d <- rbind(d, add)
  cat(sprintf("     extended %d-%d by HOLDING 2023-12 (global %.5f) -- declared, not gap-filled\n",
              max(d$year) - (VA_END - max(year)) + 1, VA_END, last$aod_global))
}

# ---- SANITY GATES against the literature
pk <- d[d$t >= VA_PIN_YR[1] & d$t <= VA_PIN_YR[2], ]
pin <- max(pk$aod_global)
g1 <- pin >= VA_PIN_BAND[1] && pin <= VA_PIN_BAND[2]
cat(sprintf("GATE 1  Pinatubo peak global AOD %.4f (expect %.2f-%.2f)  %s\n",
            pin, VA_PIN_BAND[1], VA_PIN_BAND[2], if (g1) "ok" else "⚠ OUT OF BAND"))
qz <- mean(d$aod_global[d$year == VA_QUIET_YR])
g3 <- qz < VA_QUIET
cat(sprintf("GATE 3  quiet-year (%d) global AOD %.5f (expect < %.2f)  %s\n",
            VA_QUIET_YR, qz, VA_QUIET, if (g3) "ok" else "⚠ TOO HIGH"))
top <- d[order(-d$aod_global), ][1:6, ]
cat("\n  the six largest months in the record:\n")
for (i in seq_len(nrow(top)))
  cat(sprintf("    %4d-%02d  global %.4f  NH %.4f  SH %.4f\n",
              top$year[i], top$month[i], top$aod_global[i], top$aod_NH[i], top$aod_SH[i]))
cat("\n  annual-mean global AOD at the named eruptions:\n")
for (y in c(1883, 1902, 1912, 1963, 1964, 1982, 1983, 1991, 1992, 1993))
  cat(sprintf("    %4d  %.4f\n", y, mean(d$aod_global[d$year == y])))
stopifnot(g1, g3)

attr(d, "source")   <- "NASA GISS tau_reff_CMIP7-2-2-1.nc (CMIP7 stratospheric aerosol)"
attr(d, "coverage") <- "1850-01..2023-12 measured; 2024 held at 2023-12; PRE-1850 IS ZERO AND ABSENT"
attr(d, "missing")  <- "Laki 1783, 1808/09 unknown, Tambora 1815 -- need eVolv2k"
attr(d, "built")    <- as.character(Sys.Date())
saveRDS(d, VA_OUT)
cat(sprintf("\nwritten: %s  (%d rows, %d-%d)\n", VA_OUT, nrow(d), min(d$year), max(d$year)))
