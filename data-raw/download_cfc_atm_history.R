# =====================================================================
# download_cfc_atm_history.R -- atmospheric histories of the inert ocean
# ventilation tracers (CFC-11, CFC-12, SF6, ...), hemispheric, annual mid-year.
#
# WHY (2026-10-22, Marcus: "Do the cheap tests for both methane and CFC"). The
# CFC power check (calibration/diag_cfc_power_20261022.R) runs a passive CFC-11
# tracer through the canonical's own ocean transport and asks whether an observed
# ocean CFC-11 inventory could constrain the parameters the carbon data leave
# loose. It needs the atmospheric boundary condition; this is it.
#
# SOURCE. Bullister & Warner's synthesis, the series OMIP specifies for its inert
# tracers (Orr et al. 2017, GMD 10:2169, Sect. 2.6, citing the 2015 version). This
# is the 2023 revision in the same NCEI accession (0164584, CFC_ATM_Hist_2022/).
# Hemispheric values: OMIP applies the NH series 10-90N, the SH series 10-90S and
# interpolates linearly between.
#
# Run from the repo root:  Rscript data-raw/download_cfc_atm_history.R
# UPSERTS into MANIFEST.csv (download_data.R owns the original entries).
# =====================================================================
CFC_DIR  <- "data-raw/downloads"
CFC_MAN  <- file.path(CFC_DIR, "MANIFEST.csv")
CFC_URL  <- paste0("https://www.ncei.noaa.gov/data/oceans/ncei/ocads/data/0164584/",
                   "CFC_ATM_Hist_2022/Tracer_atmospheric_histories_revised_2023_Table1.csv")
CFC_FILE <- "cfc_atm_history_bullister_2023.csv"
CFC_KEY  <- "cfc_atm_hist"
CFC_MIN_BYTES <- 5000     # a redirect or error page is smaller than the table
CFC_CITE <- paste("Bullister JL, Warner MJ. Atmospheric histories (1765-2022) for CFC-11,",
                  "CFC-12, CFC-113, CCl4, SF6 and N2O. NCEI Accession 0164584",
                  "(CFC_ATM_Hist_2022, Table 1, revised 2023). The 2015 version is the",
                  "OMIP inert-tracer forcing (Orr et al. 2017, GMD 10:2169).")
CFC_NOTES <- "hemispheric (NH/SH) annual mid-year dry-air mole fractions, ppt"

dest <- file.path(CFC_DIR, CFC_FILE)
res <- try(utils::download.file(CFC_URL, dest, quiet = TRUE, mode = "wb"), silent = TRUE)
if (inherits(res, "try-error") || !file.exists(dest) || file.info(dest)$size < CFC_MIN_BYTES)
  stop("FAILED to download ", CFC_KEY, " from ", CFC_URL)
row <- data.frame(key = CFC_KEY, file = dest, source = CFC_URL, citation = CFC_CITE,
                  accessed = as.character(Sys.Date()), bytes = file.info(dest)$size,
                  sha256 = tools::sha256sum(dest)[[1]], notes = CFC_NOTES,
                  stringsAsFactors = FALSE)
cat(sprintf("  [ok] %-14s %6.1f kB  sha256 %s\n", CFC_KEY, row$bytes / 1024, substr(row$sha256, 1, 12)))
man <- utils::read.csv(CFC_MAN, stringsAsFactors = FALSE)
man <- rbind(man[man$key != CFC_KEY, ], row[names(man)])
utils::write.csv(man, CFC_MAN, row.names = FALSE)
cat(sprintf("manifest now %d entries (%s)\n", nrow(man), CFC_MAN))
