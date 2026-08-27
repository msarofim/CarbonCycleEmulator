# =====================================================================
# diag_so_pco2_phase.R -- IS THE OBSERVED SH SURFACE-OCEAN pCO2 CYCLE
#                         IN PHASE WITH SST, AS THE MODEL REQUIRES?
#
# THE CLAIM UNDER TEST (prereg 2026-08-27f). The model's ONLY SH air-sea
# seasonal channel is `sst_seas_amp_SH`, which modulates SST and nothing
# else. Ocean pCO2 then follows SST through solubility, so the model
# ASSERTS that SH ocean pCO2 peaks when SST peaks. That is a claim about
# the ocean and it is testable directly -- no flux, no gas-transfer
# velocity, no quarter-cycle conversion in the way.
#
# WHY THIS IS THE TEST AND NOT A FLUX COMPARISON. Handoff 27d sec.5 asked
# for a flux climatology. The product Marcus chose is a pCO2 climatology,
# which turns out to allow the SHARPER test: the model's premise is about
# pCO2's phase relative to SST, and both sides of that are measurable
# without ever forming a flux. The flux route is still run (sec.4) but it
# carries a conversion the pCO2 route does not, and it is labelled weaker.
#
# ⚠ pCO2 IS NOT FLUX. F = k * K0 * dpCO2. Nothing here contains the wind
# seasonality in k or the temperature seasonality in K0. Both modulate the
# AMPLITUDE strongly. No number below may be quoted as a flux amplitude.
#
# BOTH SIDES ARE AREA-WEIGHTED OVER THE SAME MASKS AND REDUCED BY THE SAME
# ESTIMATOR -- the magnitude of the mean harmonic vector, never the mean of
# per-month magnitudes (memory amp_definition_mismatch, second incident).
#
# Usage:  Rscript calibration/diag_so_pco2_phase.R
# =====================================================================
suppressPackageStartupMessages(library(ncdf4))
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)

SP_PCO2  <- "data-raw/downloads/MPI-ULB-SOM_FFN_clim.nc"
SP_ERSST <- "data-raw/downloads/ersst_v5_sst_mnmean.nc"
# ERSSTv5 window = LIK_SEAS_WINDOW, the same window the model's seasonal rows
# are scored over and the same one build_seasonal_climatology.R used.
SP_SST_WINDOW <- LIK_SEAS_WINDOW
# The model's SH air-sea channel's atmospheric peak month, and the inversion's
# observed ocean component, both MEASURED elsewhere and carried as constants so
# this script never recomputes them under a different convention.
SP_MODEL_AIRSEA_MO <- 4.16       # diag_seas_channel_decomp.R, SPO, "air-sea SH off"
SP_INV_OCEAN_MO    <- 8.52       # diag_seas_signature_inversion.R, obs SPO ocean
SP_INV_CI          <- c(7.82, 9.20)
SP_BANDS <- list(
  `SH all (0-90S)`   = c(-90,   0),
  `SH subtrop 0-30S` = c(-30,   0),
  `SH 30-40S`        = c(-40, -30),
  `SO 40-90S`        = c(-90, -40),
  `SO 40-60S`        = c(-60, -40),
  `SO 60-90S`        = c(-90, -60),
  `NH all (0-90N)`   = c(  0,  90))

sep <- function(s) cat(sprintf("\n\n=== %s ===\n", s))
# First harmonic of a 12-month climatology: project onto sin/cos of the month
# MIDPOINTS. Peak month is reported on the same (a, b) -> month convention as
# every other seasonal diagnostic in this repo.
harm <- function(x) {
  tt <- (seq_len(12) - 0.5) / 12
  c(a = 2 * mean(x * sin(2 * pi * tt)), b = 2 * mean(x * cos(2 * pi * tt)))
}
amp    <- function(v) 2 * sqrt(sum(v^2))
ang_mo <- function(v) 12 * ((atan2(v[["a"]], v[["b"]]) / (2 * pi)) %% 1)
dmo    <- function(a, b) { d <- (a - b) %% 12; min(d, 12 - d) }
# Area weight for a regular lat grid: proportional to the cell's sin(lat) span.
awt <- function(lat, dlat) abs(sin((lat + dlat / 2) * pi / 180) -
                               sin((lat - dlat / 2) * pi / 180))

# ---- pCO2 climatology ------------------------------------------------
nc <- nc_open(SP_PCO2)
plat <- ncvar_get(nc, "lat"); plon <- ncvar_get(nc, "lon")
pco2 <- ncvar_get(nc, "pco2")                       # lon x lat x 12, muatm
patt <- ncatt_get(nc, "pco2")
nc_close(nc)
pdlat <- abs(diff(plat)[1])
# ⚠ THE FILL VALUE IS NOT APPLIED BY ncdf4 AND LAND IS NOT NA. This file names
# the attribute `FillValue`, not the CF-standard `_FillValue`, so ncdf4 hands
# back -999 over every land cell as if it were data. Read the declared value
# from the FILE rather than hardcoding it, and mask on it.
# WHAT IT COST BEFORE IT WAS CAUGHT (2026-08-27f, first run): every band mean
# was diluted by its land fraction. -999 is CONSTANT IN TIME, so it contributes
# nothing to a seasonal harmonic and every PHASE was unaffected -- but every
# AMPLITUDE was scaled down by the band's ocean fraction, and the sec.1b area
# weights came back EXACTLY equal to the hemispheric ones, which is the tell.
stopifnot(!is.null(patt$FillValue) || !is.null(patt[["_FillValue"]]))
# ...AND IT IS STORED AS A CHARACTER STRING, "-999", not a number -- so it is
# not merely un-applied, it would not survive arithmetic either. Coerce and
# gate the coercion; a silent NA here would mask NOTHING and restore the bug.
fv <- as.numeric(if (!is.null(patt[["_FillValue"]])) patt[["_FillValue"]] else patt$FillValue)
stopifnot(is.finite(fv), fv < 0)
pco2[pco2 <= fv + 1] <- NA_real_
fin <- mean(is.finite(pco2[, , 1]))
cat(sprintf("pCO2  %s: %d lon x %d lat x %d mo | FillValue %g masked -> %.1f%% ocean\n",
            basename(SP_PCO2), length(plon), length(plat), dim(pco2)[3], fv, 100 * fin))
# GATE: the ocean is ~71 % of the globe and this product drops the Arctic
# interior and the ice shelves, so anything outside this band means the mask
# did not take (1.00 = the bug above) or took far too much.
if (fin < 0.55 || fin > 0.78)
  stop(sprintf("pCO2 land mask implausible: %.3f of cells finite", fin))

# ---- SST climatology, ERSSTv5 over the scored window -----------------
nc <- nc_open(SP_ERSST)
slat <- ncvar_get(nc, "lat"); slon <- ncvar_get(nc, "lon")
stime <- ncvar_get(nc, "time")                      # days since 1800-01-01
sdate <- as.Date("1800-01-01") + stime
keep  <- which(as.integer(format(sdate, "%Y")) >= SP_SST_WINDOW[1] &
               as.integer(format(sdate, "%Y")) <= SP_SST_WINDOW[2])
sst <- ncvar_get(nc, "sst", start = c(1, 1, min(keep)),
                 count = c(-1, -1, length(keep)))
nc_close(nc)
smo <- as.integer(format(sdate[keep], "%m"))
sst_clim <- array(NA_real_, c(dim(sst)[1], dim(sst)[2], 12))
for (m in 1:12) sst_clim[, , m] <- apply(sst[, , smo == m, drop = FALSE], c(1, 2), mean)
sdlat <- abs(diff(slat)[1])
cat(sprintf("SST   %s: %d lon x %d lat, %d-%d (%d months)\n\n",
            basename(SP_ERSST), length(slon), length(slat),
            SP_SST_WINDOW[1], SP_SST_WINDOW[2], length(keep)))

# Area-weighted monthly mean of a lon x lat x 12 field over a latitude band.
band_clim <- function(fld, lat, dlat, lo, hi) {
  j <- which(lat > lo & lat <= hi)
  if (!length(j)) return(rep(NA_real_, 12))
  w <- awt(lat[j], dlat)
  vapply(1:12, function(m) {
    s <- fld[, j, m]
    ok <- is.finite(s)
    W  <- matrix(rep(w, each = nrow(s)), nrow = nrow(s))
    sum(s[ok] * W[ok]) / sum(W[ok])
  }, 0)
}

# ---------------------------------------------------------------------
sep("1. PHASE OF pCO2 AGAINST PHASE OF SST, BY LATITUDE BAND")
cat("  Peak month of the FIRST HARMONIC, both sides area-weighted over the same\n")
cat("  band and reduced by the same estimator. 'gap' wraps at 6 months.\n\n")
cat(sprintf("  %-18s %9s %8s | %9s %8s | %7s\n", "band",
            "pCO2 amp", "peak mo", "SST amp", "peak mo", "gap mo"))
R <- list()
for (nm in names(SP_BANDS)) {
  b  <- SP_BANDS[[nm]]
  hp <- harm(band_clim(pco2,     plat, pdlat, b[1], b[2]))
  hs <- harm(band_clim(sst_clim, slat, sdlat, b[1], b[2]))
  g  <- dmo(ang_mo(hp), ang_mo(hs))
  R[[nm]] <- list(p = hp, s = hs, gap = g)
  cat(sprintf("  %-18s %8.2f%s %8.2f | %8.3fK %8.2f | %7.2f\n", nm,
              amp(hp), "u", ang_mo(hp), amp(hs), ang_mo(hs), g))
}

# ---------------------------------------------------------------------
sep("1b. THE SH MEAN IS A NEAR-CANCELLATION OF TWO OPPOSED REGIMES")
cat("  This is what sec.1's SH-all row hides. The subtropical and Southern-Ocean\n")
cat("  bands are ~180 deg apart, so the hemispheric mean is a small RESIDUAL of\n")
cat("  two large opposing signals -- and a model that matches the residual has\n")
cat("  not matched either regime.\n\n")
CB <- list(`0-30S` = c(-30, 0), `30-40S` = c(-40, -30), `40-90S` = c(-90, -40))
# OCEAN area, not hemispheric area. The bands differ in land fraction (0-30S
# carries South America, southern Africa and Australia; 40-60S is almost all
# water), so weighting by sin(lat) span would overweight the subtropics and
# UNDERSTATE the cancellation. Ocean area = the area of the cells the pCO2
# product actually reports, which is the same mask everything else here uses.
ocean_area <- function(lo, hi) {
  j <- which(plat > lo & plat <= hi)
  w <- awt(plat[j], pdlat)
  ok <- is.finite(pco2[, j, 1])
  sum(matrix(rep(w, each = dim(pco2)[1]), nrow = dim(pco2)[1])[ok])
}
A_SH <- ocean_area(-90, 0)
tot <- c(a = 0, b = 0); parts <- list()
cat(sprintf("  %-10s %8s %8s %10s %9s %12s\n", "band", "hemis wt", "ocean wt",
            "pCO2 amp", "peak mo", "wtd vector"))
for (nm in names(CB)) {
  b <- CB[[nm]]
  wh <- abs(sin(b[2] * pi / 180) - sin(b[1] * pi / 180))  # fraction of a hemisphere
  w  <- ocean_area(b[1], b[2]) / A_SH                     # fraction of SH OCEAN
  h <- harm(band_clim(pco2, plat, pdlat, b[1], b[2]))
  parts[[nm]] <- w * h; tot <- tot + w * h
  cat(sprintf("  %-10s %8.3f %8.3f %10.2f %9.2f %12.2f\n", nm, wh, w, amp(h),
              ang_mo(h), amp(w * h)))
}
names(tot) <- c("a", "b")
inphase <- parts[["0-30S"]] + parts[["30-40S"]]; names(inphase) <- c("a", "b")
opposed <- parts[["40-90S"]]; names(opposed) <- c("a", "b")
cat(sprintf("\n  subtropical limb (0-40S)  %6.2f at mo %.2f\n", amp(inphase), ang_mo(inphase)))
cat(sprintf("  Southern Ocean  (40-90S)  %6.2f at mo %.2f   -- %.2f mo apart\n",
            amp(opposed), ang_mo(opposed), dmo(ang_mo(inphase), ang_mo(opposed))))
cat(sprintf("  VECTOR SUM                %6.2f at mo %.2f\n", amp(tot), ang_mo(tot)))
cat(sprintf("  scalar sum would be       %6.2f  ->  %.0f%% CANCELS\n",
            amp(inphase) + amp(opposed),
            100 * (1 - amp(tot) / (amp(inphase) + amp(opposed)))))

# ---------------------------------------------------------------------
sep("2. THE SCORED PREDICTIONS (prereg 2026-08-27f)")
p3 <- R[["SH subtrop 0-30S"]]$gap
cat(sprintf("  P3 CONTROL -- subtropical SH pCO2 within 2.5 mo of SST: %.2f  ->  %s\n",
            p3, if (p3 <= 2.5) "PASS, P1/P2 are read" else "FAIL, STOP"))
if (p3 > 2.5) { cat("\n  P1/P2/P4 ARE NOT READ. The control failed.\n"); sep("DONE"); quit(save = "no") }
p1 <- R[["SH all (0-90S)"]]$gap
cat(sprintf("  P1 -- SH-mean pCO2 >= 2.0 mo from SST: %.2f  ->  %s\n", p1,
            if (p1 >= 2.0) "CONFIRMED" else "FAILED -- the solubility-only channel is VINDICATED"))
so <- R[["SO 40-90S"]]
cat(sprintf("  P2 -- south of 40S: pCO2 peaks mo %.2f (predicted 6-10) and is %.2f mo\n",
            ang_mo(so$p), so$gap))
cat(sprintf("        from SST (predicted >= 4.0)  ->  %s\n",
            if (ang_mo(so$p) >= 6 && ang_mo(so$p) <= 10 && so$gap >= 4.0) "CONFIRMED"
            else "MISSED -- read both halves above"))

# ---------------------------------------------------------------------
sep("3. dpCO2, AND THE LINK BACK TO THE INVERSION (prereg P4 -- the WEAK one)")
cat("  dpCO2 = ocean pCO2 - atmospheric pCO2. The atmospheric side is the\n")
cat("  OBSERVED SPO seasonal harmonic, so the subtraction is like-for-like with\n")
cat("  the inversion. Its cycle is ~1 ppm against the ocean's tens, so this is a\n")
cat("  small correction -- it is done anyway because it is free and its size is\n")
cat("  then a measurement rather than an assumption.\n\n")
obs <- ccx_prepare_obs()
oa  <- obs$co2_seas$SPO
yr  <- oa$year
atm <- c(a = mean(oa$a), b = mean(oa$b))
cat(sprintf("  atmospheric SPO harmonic: amp %.3f ppm, peak mo %.2f (%d years)\n\n",
            amp(atm), ang_mo(atm), length(yr)))
cat(sprintf("  %-18s %10s %8s | %10s %8s | %10s\n", "band",
            "dpCO2 amp", "peak mo", "flux peak", "+3 mo", "vs inv 8.52"))
for (nm in names(SP_BANDS)) {
  d <- R[[nm]]$p - atm[c("a", "b")]
  names(d) <- c("a", "b")
  fm <- ang_mo(d); am <- (fm + 3) %% 12
  cat(sprintf("  %-18s %10.2f %8.2f | %10.2f %8.2f | %+10.2f\n", nm,
              amp(d), fm, fm, am, ((am - SP_INV_OCEAN_MO + 6) %% 12) - 6))
}
dsh <- R[["SH all (0-90S)"]]$p - atm[c("a", "b")]; names(dsh) <- c("a", "b")
am  <- (ang_mo(dsh) + 3) %% 12
gapm <- dmo(am, SP_MODEL_AIRSEA_MO)
cat(sprintf("\n  P4 -- SH-mean implied atmospheric ocean component at mo %.2f;\n", am))
cat(sprintf("        model's SH air-sea channel %.2f: %.2f mo apart, predicted >= 3.0  ->  %s\n",
            SP_MODEL_AIRSEA_MO, gapm, if (gapm >= 3.0) "CONFIRMED" else "FAILED"))
cat(sprintf("        (the inversion put it at %.2f [%.2f, %.2f]; this route lands %+.2f mo from that)\n",
            SP_INV_OCEAN_MO, SP_INV_CI[1], SP_INV_CI[2],
            ((am - SP_INV_OCEAN_MO + 6) %% 12) - 6))
cat("\n  ⚠ THE +3 IS A QUARTER-CYCLE IDEALISATION. Real loss from the SH box makes\n")
cat("  the true lag SHORTER than 3 months, so this row is biased LATE and its\n")
cat("  margin is generous. P1-P3 carry no such conversion.\n")

sep("DONE")
