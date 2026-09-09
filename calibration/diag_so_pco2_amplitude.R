# =====================================================================
# diag_so_pco2_amplitude.R -- THE OBSERVED surface-ocean pCO2 seasonal
# AMPLITUDE, by latitude band, from the SAME product and the SAME
# estimator that gave GATE S its phase.
#
# WHY. Marcus retired P1's band as a gate (2026-09-09m). Its scale leg was
# the CODE UNDER TEST and its algebra was the wrong form for a moving
# boundary (notes/options_2026-09-09l_p1_yardstick.md). The replacement
# follows GATE S's own template: GATE S is classed "OBSERVATION + LAW" and
# reads the Landschutzer/Laruelle SOM-FFN climatology (NCEI 0209633) for
# its PHASE with NO MODEL IN THE LOOP. That product carries the AMPLITUDE
# of the same first harmonic. This script extracts it.
#
# ⭐ ESTIMATOR AND MASKS ARE COPIED FROM diag_so_pco2_phase.R DELIBERATELY,
# not re-derived: the amplitude and the phase must come from ONE convention
# or they can disagree for bookkeeping reasons alone. The amplitude is the
# MAGNITUDE OF THE MEAN HARMONIC VECTOR, never the mean of per-month
# magnitudes (memory `amp_definition_mismatch`, which bit twice).
#
# ⚠⚠ TWO THINGS THIS SCRIPT DOES NOT DO, BOTH RULINGS OWED:
#  1. It does NOT pick which band the model's mixed layer corresponds to.
#     The model's SH `ml` is a LOW-LATITUDE box (hs_frac splits the high
#     latitudes into `hs`), so the mapping is a real choice -- and it is
#     exactly the choice that BIT GATE S: its SH-area-mean bracket
#     [1.54, 4.54] EXCLUDES the right answer while CONTAINING the pre-fix
#     model's 4.16, because the pre-fix model was matching the
#     76 %-cancelling area mean. Reuse GATE S's settled convention; do not
#     invent a second one here.
#  2. It does NOT compare to the model, because THE MODEL DOES NOT EXPOSE
#     MIXED-LAYER pCO2 in any run output -- `ccx_run()$out` carries ml_C
#     and ml_C13 but no pCO2, and the flux trace carries none either.
#     Wiring the comparison needs that diagnostic output added first.
#
# ⛔ pCO2 IS NOT FLUX (the caveat carried from diag_so_pco2_phase.R):
# F = k * K0 * dpCO2, and nothing here contains the wind seasonality in k
# or the temperature seasonality in K0. Both modulate a FLUX amplitude
# strongly. ⭐ The caveat does NOT bite the intended comparison, because
# that compares MODEL pCO2 against OBSERVED pCO2 with no flux formed on
# either side. It DOES bite any attempt to read these as flux amplitudes.
#
# Usage:  Rscript calibration/diag_so_pco2_amplitude.R
# =====================================================================
suppressPackageStartupMessages(library(ncdf4))
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)

TAG     <- "20260909"
OUT_RDS <- file.path("outputs", "diagnostics", paste0("so_pco2_amplitude_", TAG, ".rds"))
OUT_LOG <- sub("[.]rds$", ".log", OUT_RDS)
SP_PCO2 <- "data-raw/downloads/MPI-ULB-SOM_FFN_clim.nc"
# The band GATE S is defined on, carried as a named constant so the label and
# the mask cannot drift apart.
GATE_S_BAND <- "SO 40-90S"
SP_BANDS <- list(
  `SH all (0-90S)`   = c(-90,   0),
  `SH subtrop 0-30S` = c(-30,   0),
  `SH 30-40S`        = c(-40, -30),
  `SO 40-90S`        = c(-90, -40),
  `SO 40-60S`        = c(-60, -40),
  `SO 60-90S`        = c(-90, -60),
  `NH all (0-90N)`   = c(  0,  90))

con <- file(OUT_LOG, open = "wt")
say <- function(...) { m <- sprintf(...); cat(m, "\n"); cat(m, "\n", file = con) }

## ---- estimator: IDENTICAL to diag_so_pco2_phase.R -------------------------
harm <- function(x) {
  tt <- (seq_len(12) - 0.5) / 12
  c(a = 2 * mean(x * sin(2 * pi * tt)), b = 2 * mean(x * cos(2 * pi * tt)))
}
amp    <- function(v) 2 * sqrt(sum(v^2))
ang_mo <- function(v) 12 * ((atan2(v[["a"]], v[["b"]]) / (2 * pi)) %% 1)
awt <- function(lat, dlat) abs(sin((lat + dlat / 2) * pi / 180) -
                               sin((lat - dlat / 2) * pi / 180))

nc   <- nc_open(SP_PCO2)
plat <- ncvar_get(nc, "lat")
pco2 <- ncvar_get(nc, "pco2")                      # lon x lat x 12, muatm
nc_close(nc)
dlat <- abs(diff(plat)[1])

say("OBSERVED surface-ocean pCO2 SEASONAL AMPLITUDE (first harmonic)")
say("product : %s", SP_PCO2)
say("source  : Landschutzer, Laruelle, Roobaert & Regnier (2020), ESSD 12:2537,")
say("          NOAA NCEI Accession 0209633, doi:10.25921/qb25-f418")
say("estimator: magnitude of the MEAN harmonic vector, area-weighted, month CENTRES")
say("⭐ same product, masks and estimator as GATE S's phase -- one convention, not two")
say("")
say("  %-18s %12s %12s %10s", "band", "amp (uatm)", "peak month", "n cells")

rows <- lapply(names(SP_BANDS), function(bn) {
  br  <- SP_BANDS[[bn]]
  sel <- which(plat >= br[1] & plat < br[2])
  w   <- awt(plat[sel], dlat)
  # area-weighted mean series over the band, then ONE harmonic of it --
  # never a mean of per-cell amplitudes, which would not cancel phase.
  ser <- vapply(seq_len(12), function(m) {
    sl <- pco2[, sel, m]
    ok <- is.finite(sl)
    wm <- matrix(rep(w, each = nrow(sl)), nrow = nrow(sl))
    sum(sl[ok] * wm[ok]) / sum(wm[ok])
  }, numeric(1))
  v <- harm(ser)
  n <- sum(is.finite(pco2[, sel, 1]))
  say("  %-18s %12.2f %12.2f %10d", bn, amp(v), ang_mo(v), n)
  data.frame(band = bn, lat_lo = br[1], lat_hi = br[2],
             amp_uatm = amp(v), peak_mo = ang_mo(v), n_cells = n)
})
tab <- do.call(rbind, rows)

## ---- WHICH ESTIMATOR PRODUCED `.ENT_SO_PCO2_AMP` = 19.45? ------------------
# R/constants.R carries 19.45 as the observed 40-90 S amplitude "from the same
# product" -- against the 16.26 above, a 20 % gap on the SAME band and the SAME
# file. Two numbers for one quantity is a defect whichever is right, so this
# identifies the split rather than picking a winner by preference.
GATE_S_CONST <- 19.45
sel <- which(plat >= -90 & plat < -40); w <- awt(plat[sel], dlat)
ser <- vapply(seq_len(12), function(m) {
  sl <- pco2[, sel, m]; ok <- is.finite(sl)
  wm <- matrix(rep(w, each = nrow(sl)), nrow = nrow(sl))
  sum(sl[ok] * wm[ok]) / sum(wm[ok])
}, numeric(1))
# PER-CELL amplitudes, vectorised: project every cell onto the same two basis
# vectors at once, so this is the identical estimator applied cell-wise.
tt  <- (seq_len(12) - 0.5) / 12
cub <- matrix(pco2[, sel, ], ncol = 12)
keep <- stats::complete.cases(cub)
aa <- 2 * (cub[keep, ] %*% sin(2 * pi * tt)) / 12
bb <- 2 * (cub[keep, ] %*% cos(2 * pi * tt)) / 12
wcell <- matrix(rep(w, each = dim(pco2)[1]), ncol = 1)[keep]
A_area <- amp(harm(ser))
A_cell <- sum(2 * sqrt(aa^2 + bb^2) * wcell) / sum(wcell)
say("")
say("WHICH ESTIMATOR PRODUCED `.ENT_SO_PCO2_AMP` = %.2f ?", GATE_S_CONST)
say("  (1) harmonic of the AREA-MEAN series   %6.2f uatm   <- GATE S's phase uses this",
    A_area)
say("  (2) AREA-MEAN of PER-CELL amplitudes   %6.2f uatm   <- PHASE-BLIND", A_cell)
say("  the constant is closest to (%d).", if (abs(A_cell - GATE_S_CONST) <
    abs(A_area - GATE_S_CONST)) 2L else 1L)
say("⛔ ⇒ THE PROJECT'S AMPLITUDE CONSTANT AND ITS PHASE CONSTANT COME FROM TWO")
say("   DIFFERENT CONVENTIONS ON THE SAME PRODUCT AND BAND -- [[amp_definition_mismatch]].")
say("⭐ AND THE PHYSICS PICKS ONE: `ent_seas_amp_SH` perturbs a SINGLE WELL-MIXED BOX,")
say("   whose concentration is the AREA MEAN. For a box, the area mean of the anomaly IS")
say("   the anomaly of the area mean, so (1) is correct and (2) overstates it: (2) averages")
say("   |amplitude| and so discards the phase cancellation a box cannot avoid.")
say("⚠ BUT DO NOT CORRECT ONE LEG OF A TWO-LEG SUM ALONE. The prior centre adds a")
say("   SOLUBILITY term (46.95 uatm, from .ENT_SO_SST_AMP = 3.0 K) to this one, and that")
say("   term's own convention -- per-cell or area-mean -- IS NOT STATED in constants.R.")
say("   If it is also per-cell, the two biases partially CANCEL in the sum. Establish the")
say("   SST leg's convention before changing either.")
say("⇒ IMPACT IS SMALL EITHER WAY: swapping 19.45 -> 16.26 moves the in-band value")
say("   29.68 -> 28.25 and the prior centre 10.95 -> 10.43, a 4.8 %% change, because the")
say("   SOLUBILITY term dominates the sum. A real defect, a modest number.")

say("")
say("⚠ RULINGS OWED BEFORE THIS BECOMES A GATE:")
say("  1. WHICH BAND maps to the model's SH mixed layer? The model's `ml` is the")
say("     LOW-LATITUDE surface box (hs_frac splits the high latitudes into `hs`),")
say("     so this is a real choice -- and it is the choice that BIT GATE S, whose")
say("     SH-area-mean bracket EXCLUDED the right answer while CONTAINING the")
say("     pre-fix model. Reuse GATE S's settled convention; do not invent a second.")
say("  2. THE MODEL SIDE DOES NOT EXIST YET: ccx_run()$out carries ml_C and ml_C13")
say("     but NO mixed-layer pCO2, and neither does the flux trace. That output")
say("     must be added before any comparison can be made.")
say("⛔ pCO2 IS NOT FLUX. These are pCO2 amplitudes and may not be quoted as flux")
say("   amplitudes: F = k*K0*dpCO2 and neither the wind seasonality in k nor the")
say("   temperature seasonality in K0 is present here.")

dir.create(dirname(OUT_RDS), showWarnings = FALSE, recursive = TRUE)
saveRDS(list(product = SP_PCO2, gate_s_band = GATE_S_BAND, table = tab,
             estimator = "magnitude of mean harmonic vector, area-weighted, month centres",
             built = Sys.time()), OUT_RDS)
say("")
say("wrote %s", OUT_RDS)
close(con)
