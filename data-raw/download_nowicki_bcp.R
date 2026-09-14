# =====================================================================
# download_nowicki_bcp.R -- the OBSERVATION-CONSTRAINED ENSEMBLE behind the
# prescribed global export `pump_export` (option D + E, 2026-09-14; ruling E4,
# Marcus 09-14: "Nowicki if it includes uncertainty bounds").
#
# Nowicki, DeVries & Siegel (2022) assimilate satellite + in-situ BGC
# observations into a 124-member ensemble of the biological pump and report an
# ENSEMBLE-MEAN global export of 10.2 PgC/yr (abstract). The paper text is
# behind a publisher bot-check (09-14; not bypassed), so the ensemble's own
# spread is taken from its DATA RELEASE, which carries the mean and the 25th /
# 75th percentile of every field (figshare description). The companion build
# script integrates the export maps to global totals; the prior's bounds are
# the ensemble's IQR, computed, not recalled.
# Companion: data-raw/build_pump_export_prior.R -> data/obs_pump_export_prior.rds
#
# Run from the repo root:  Rscript data-raw/download_nowicki_bcp.R
# UPSERTS into MANIFEST.csv (download_data.R owns the original entries).
# =====================================================================
BCP_DIR <- "data-raw/downloads"; BCP_MAN <- file.path(BCP_DIR, "MANIFEST.csv")
BCP_MIN_BYTES <- 2e8   # figshare reports 225,147,078 bytes, md5 3da27a0a... (API, 2026-09-14)
BCP_SETS <- list(
  nowicki2022_bcp = list(
    url  = "https://ndownloader.figshare.com/files/36114617",
    dest = "biopump_model_output.nc",
    cite = paste("Nowicki M., DeVries T., Siegel D.A. (2022), Global Biogeochem. Cycles 36,",
                 "e2021GB007083, doi:10.1029/2021GB007083. Quantifying the carbon export and",
                 "sequestration pathways of the ocean's biological carbon pump. Data:",
                 "figshare doi:10.6084/m9.figshare.19074521 (biopump_model_output.nc)."),
    notes = paste("for pump_export (option D+E, ruling E4): the ensemble mean and the 25th/75th",
                  "percentile maps of total carbon export (Fig. 6) and by pathway (Fig. S3),",
                  "integrated to global PgC/yr by the companion build script. 124-member",
                  "ensemble; abstract's ensemble-mean global export 10.2 PgC/yr.")))
dir.create(BCP_DIR, showWarnings = FALSE, recursive = TRUE)
options(timeout = 3600)
rows <- list()
for (key in names(BCP_SETS)) {
  s <- BCP_SETS[[key]]; dest <- file.path(BCP_DIR, s$dest)
  cat(sprintf("  ... %-20s %s\n", key, s$url))
  res <- try(utils::download.file(s$url, dest, quiet = TRUE, mode = "wb"), silent = TRUE)
  if (inherits(res, "try-error") || !file.exists(dest) || file.info(dest)$size < BCP_MIN_BYTES)
    stop(sprintf("FAILED to download %s from %s", key, s$url))
  rows[[key]] <- data.frame(
    key = key, file = dest, source = s$url, citation = s$cite, accessed = format(Sys.Date()),
    bytes = file.info(dest)$size, sha256 = tools::sha256sum(dest)[[1]], notes = s$notes,
    stringsAsFactors = FALSE)
  cat(sprintf("  [ok] %-20s %8.1f MB  sha256 %s\n", key, file.info(dest)$size / 1048576,
              substr(rows[[key]]$sha256, 1, 12)))
}
man <- utils::read.csv(BCP_MAN, stringsAsFactors = FALSE)
new <- do.call(rbind, rows)
man <- rbind(man[!(man$key %in% new$key), ], new)
utils::write.csv(man, BCP_MAN, row.names = FALSE)
cat(sprintf("\nmanifest now %d entries (%s)\n", nrow(man), BCP_MAN))
