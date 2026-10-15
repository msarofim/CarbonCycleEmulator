# =====================================================================
# download_mod17_gpp8d.R -- MOD17A2HGF C6.1 8-DAY GPP + NET PHOTOSYNTHESIS
#                           -> data-raw/downloads/mod17_gpp8d/gpp8d_<year>.nc.zip
#
# WHY. diag_npp_eff_latitude.R measured the NPP-weighted effective latitude at
# 38.35 N against a shipped CCX_SEAS_PHI_EFF["NH"] of 75, but it had to bound
# its own answer: MOD17A3HGF is an ANNUAL product, so it gives the SPATIAL
# distribution of NPP and says nothing about the seasonal cycle. It therefore
# tests the AGGREGATION under the model's premise ("NPP follows normalized
# insolation") and cannot test the premise itself. If real NH productivity is
# strongly RECTIFIED -- a growing season that switches on and off, which boreal
# vegetation is -- then a poleward phi_eff is a legitimate emulation of
# rectification rather than an error, and the offline fit that produced 75 said
# as much ("at 75 N the polar night rectifies the growing season by itself").
#
# This is the product that settles it: the same MOD17 algorithm, the same
# 0.5 deg ICDC regrid, the same CC-BY-4.0 and no registration -- but 8-DAILY.
#   Running SW, Zhao M (2021) MOD17A2HGF v061, NASA LP DAAC,
#     doi:10.5067/MODIS/MOD17A2HGF.061
#   ICDC regrid: doi:10.25592/uhhfdm.14449 (Kern S, UHH/ICDC), CC-BY-4.0
#
# IT CARRIES BOTH `gpp` AND `net_photosynthesis`, and that matters. The model's
# seasonal term is on NPP, and GPP is the wrong quantity for it: autotrophic
# respiration keeps running through the shoulder seasons, so GPP is LESS
# rectified than NPP and a GPP-derived phi_eff is biased toward the equator --
# i.e. against the 75 hypothesis, which would make a GPP-only answer the
# convenient one rather than the honest one. `net_photosynthesis` is MOD17's
# PsnNet = GPP minus leaf and fine-root maintenance respiration, which is much
# closer to NPP (it still omits growth respiration and live-wood maintenance).
# BOTH are carried downstream, and the pair BRACKETS the answer.
#
# FIVE YEARS, SPREAD ACROSS THE RECORD, not a consecutive block: 2001, 2006,
# 2011, 2016, 2021. A seasonal SHAPE climatology converges fast (the annual
# product's NH share moves by sd 0.0135 over 23 years), and spreading the
# sample averages ENSO variability and makes any drift in the shape visible as
# a spread across the five rather than invisible inside one pentad. 2022 is
# absent from the archive upstream -- the depositor withheld it -- so it cannot
# be part of any sample.
#
# THE ZIPS ARE KEPT AND THE UNZIPPED FILES ARE NOT. Each year unzips to 597 MB
# (46 files) against a 70 MB zip, so five years would be 3 GB of derived data
# reconstructible in seconds. The builder unzips to a tempdir and deletes.
# THIS ALSO MEANS THE MANIFEST SHA-256 STAYS VERIFIABLE, which it is not for
# the annual product, whose zip was deleted after unzipping.
#
# Downloads are gitignored; MANIFEST.csv is the tracked provenance record.
#
# Usage:  Rscript data-raw/download_mod17_gpp8d.R
# =====================================================================
GP_DIR   <- "data-raw/downloads/mod17_gpp8d"
GP_MAN   <- "data-raw/downloads/MANIFEST.csv"
GP_YEARS <- c(2001, 2006, 2011, 2016, 2021)
GP_BASE  <- paste0("https://www.fdr.uni-hamburg.de/record/14449/files/",
                   "MODIS-C061__MOD17A2HGF__GrossPrimaryProduction__8DAY__",
                   "LPDAAC__GLOBAL__0.5degree__UHAM-ICDC__%d__fv0.01.nc.zip?download=1")
GP_MIN_BYTES <- 50e6      # a real year is ~70 MB; anything smaller is an error
                          # page or a truncated transfer, not data
GP_CITE <- paste("Running SW, Zhao M (2021) MOD17A2HGF v061, NASA LP DAAC,",
                 "doi:10.5067/MODIS/MOD17A2HGF.061; 8-daily 0.5 deg netCDF regrid",
                 "by Kern S, UHH/ICDC, doi:10.25592/uhhfdm.14449, CC-BY-4.0.")
GP_NOTES <- paste("Sub-annual counterpart of mod17a3hgf_npp, to test whether NH",
                  "productivity is RECTIFIED (which would justify a poleward",
                  "CCX_SEAS_PHI_EFF) rather than insolation-shaped. Years 2001,",
                  "2006, 2011, 2016, 2021; 2022 absent upstream. Carries BOTH gpp",
                  "and net_photosynthesis (PsnNet, closer to NPP) -- use the pair",
                  "as a bracket. `numberofvalidvalues` weighting as for the annual",
                  "product: a cell is not the thing inside it. Zips KEPT (597 MB",
                  "unzipped per year); builders unzip to a tempdir.")

dir.create(GP_DIR, recursive = TRUE, showWarnings = FALSE)
rows <- list()
for (y in GP_YEARS) {
  dest <- file.path(GP_DIR, sprintf("gpp8d_%d.nc.zip", y))
  url  <- sprintf(GP_BASE, y)
  if (file.exists(dest) && file.info(dest)$size >= GP_MIN_BYTES) {
    cat(sprintf("  [have] %d  %.1f MB\n", y, file.info(dest)$size / 1048576))
  } else {
    cat(sprintf("  ...    %d\n", y))
    # The record URL 302s to a PRE-SIGNED S3 link that expires in 60 s, so the
    # redirect must be followed immediately and in the same call.
    r <- try(utils::download.file(url, dest, quiet = TRUE, mode = "wb"), silent = TRUE)
    if (inherits(r, "try-error") || !file.exists(dest) || file.info(dest)$size < GP_MIN_BYTES)
      stop(sprintf("FAILED or truncated: %d (%s)", y,
                   if (file.exists(dest)) sprintf("%.1f MB", file.info(dest)$size / 1048576)
                   else "no file"))
    cat(sprintf("  [ok]   %d  %.1f MB\n", y, file.info(dest)$size / 1048576))
  }
  # INTEGRITY, not just size: a 70 MB truncated zip passes a size gate and dies
  # 40 files into the build. `unzip -t` is the cheapest end-to-end check.
  tst <- suppressWarnings(system2("unzip", c("-tq", shQuote(dest)), stdout = TRUE, stderr = TRUE))
  if (!is.null(attr(tst, "status")) && attr(tst, "status") != 0)
    stop(sprintf("zip integrity check FAILED for %d:\n%s", y, paste(tst, collapse = "\n")))
  rows[[as.character(y)]] <- data.frame(
    key = sprintf("mod17a2hgf_gpp8d_%d", y), file = dest, source = url,
    citation = GP_CITE, accessed = format(Sys.Date()),
    bytes = file.info(dest)$size, sha256 = tools::sha256sum(dest)[[1]],
    notes = GP_NOTES, stringsAsFactors = FALSE)
}

# UPSERT into the manifest rather than rewriting it: download_data.R owns the
# original 14 entries and regenerates the whole file from its own list, but the
# 08-20 acquisitions were appended, so a rewrite here would drop them.
man <- utils::read.csv(GP_MAN, stringsAsFactors = FALSE)
new <- do.call(rbind, rows)
man <- rbind(man[!(man$key %in% new$key), ], new)
utils::write.csv(man, GP_MAN, row.names = FALSE)
cat(sprintf("\n%d years in %s; manifest now %d entries\n",
            length(GP_YEARS), GP_DIR, nrow(man)))
