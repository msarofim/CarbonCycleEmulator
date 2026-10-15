# =====================================================================
# build_so_pco2_seas_amp.R -- PROMOTE the Southern-Ocean (40-90 S) observed
# pCO2 seasonal amplitude from a diagnostic artifact into a data/ product, so
# `.ENT_SO_PCO2_AMP` reads it instead of carrying a typed literal.
#
# WHY A PROMOTION AND NOT A RE-DERIVATION. The number is already COMPUTED, by
# `calibration/diag_so_pco2_amplitude.R`, on GATE S's own product, masks and
# estimator -- deliberately copied from `diag_so_pco2_phase.R` so the amplitude
# and the phase cannot disagree for bookkeeping reasons. A third implementation
# of that estimator is the caption-sync bug class in disguise
# ([[two_gates_one_mechanism]]), so this file COPIES the table and GATES that it
# is the table it thinks it is. It re-derives nothing.
#
# ⭐ WHICH ROW, AND WHY (ruled by Marcus 2026-09-09w). The shipped 19.45 is the
# PER-CELL reduction: harmonics fitted cell by cell, then averaged. A well-mixed
# BOX requires the harmonic of the AREA-MEAN SERIES -- 16.26 uatm -- which is
# also what the SST leg of the same prior chain uses, so the two legs are now
# like-for-like ([[like_for_like_forcing]], [[amp_definition_mismatch]], third
# incident). ⚠ The pCO2 product omits the seasonality of gas transfer and K0;
# that caveat rides with the number and is restated at the constant.
#
# ⛔ THE 4.4x ANTIPHASE HAZARD, restated because it is what makes the BAND the
# right object: the SH hemispheric mean is 3.69 uatm against the band's 16.26 --
# a 76 % cancellation between a thermal subtropical limb peaking ~month 1.2 and
# the DIC-driven Southern Ocean peaking ~month 7.5. Never take the hemispheric
# row for this prior.
#
# Usage: Rscript data-raw/build_so_pco2_seas_amp.R -> data/obs_so_pco2_seas_amp.rds
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)

SP_SRC       <- ccx_path("outputs", "diagnostics", "so_pco2_amplitude_20260909.rds")
SP_OUT       <- ccx_path("data", "obs_so_pco2_seas_amp.rds")
SP_BAND      <- "SO 40-90S"                 # GATE S's own band label
SP_HEMI      <- "SH all (0-90S)"            # the canceling row, kept as a warning
SP_ESTIMATOR <- "magnitude of mean harmonic vector, area-weighted, month centres"
SP_PRODUCER  <- "calibration/diag_so_pco2_amplitude.R"

x <- readRDS(SP_SRC)

# ---- ⛔ GATES: this is the table this file thinks it is ---------------
if (!identical(x$estimator, SP_ESTIMATOR))
  stop("the source artifact's estimator is '", x$estimator, "', not '", SP_ESTIMATOR,
       "'. The producer changed convention; re-read ", SP_PRODUCER, " before promoting.")
if (!identical(x$gate_s_band, SP_BAND))
  stop("the source artifact's GATE S band is '", x$gate_s_band, "', not '", SP_BAND, "'.")
if (!all(c(SP_BAND, SP_HEMI) %in% x$table$band))
  stop("the source table lacks the band row(s) this file promotes.")

row  <- x$table[x$table$band == SP_BAND, ]
hemi <- x$table[x$table$band == SP_HEMI, ]
cat(sprintf("promoting %s from %s\n", SP_BAND, SP_PRODUCER))
cat(sprintf("  band  %-16s amp %6.2f uatm | peak month %5.2f | %d cells\n",
            row$band, row$amp_uatm, row$peak_mo, row$n_cells))
cat(sprintf("  hemi  %-16s amp %6.2f uatm | peak month %5.2f  <- the %.1fx ANTIPHASE cancellation\n",
            hemi$band, hemi$amp_uatm, hemi$peak_mo, row$amp_uatm / hemi$amp_uatm))
# the cancellation is the reason the band row is the right object; assert it is
# still there rather than restating it in prose only.
stopifnot(row$amp_uatm > 3 * hemi$amp_uatm)

out <- list(band_amp_uatm = row$amp_uatm, band_peak_month = row$peak_mo,
            band_label = SP_BAND, hemi_amp_uatm = hemi$amp_uatm,
            hemi_peak_month = hemi$peak_mo,
            cancellation_ratio = row$amp_uatm / hemi$amp_uatm,
            estimator = SP_ESTIMATOR, producer = SP_PRODUCER,
            product = x$product,
            source = paste("Landschutzer/Laruelle SOM-FFN climatology (NCEI 0209633),",
                           SP_BAND, "-- the same product, masks and estimator GATE S",
                           "reads for its phase."),
            caveat = paste("omits the seasonality of gas transfer (k, ~wind^2) and of K0;",
                           "this is a pCO2 amplitude, NOT a flux amplitude."),
            built = format(Sys.time(), "%Y-%m-%d %H:%M"))
saveRDS(out, SP_OUT)
cat(sprintf("saved %s\n", SP_OUT))
