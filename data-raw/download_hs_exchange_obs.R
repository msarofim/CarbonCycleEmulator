# =====================================================================
# download_hs_exchange_obs.R -- the OBSERVATIONS behind the cold box's air-sea
# exchange factor `hs_asx_frac` (2026-09-06; prereg_2026-09-07 sec.4).
#
# HILDA (Siegenthaler & Joos 1992) sets the high-latitude surface box's gas
# exchange per unit area EQUAL to the low-latitude one, on the argument that
# winter sea-ice cover cancels the stronger high-latitude winds. Our fits put
# the factor at 0.65-0.8 (bomb rows, marginal sd <= 0.10). This script fetches
# the two datasets that let the factor be ESTIMATED from observations and a
# law (Wanninkhof 2014: k = 0.251 <U^2> (Sc/660)^-1/2, times open water):
#   1. HadISST1 monthly sea-ice concentration, 1 deg, 1870-present (17 MB gz)
#   2. NCEP/NCAR Reanalysis 1 monthly-mean scalar wind speed at sigma 0.995,
#      2.5 deg, 1948-present (25 MB)
# The SST that defines the HS area (annual-mean SST < 5 degC) is ERSST v5,
# ALREADY in the manifest (`ersst_v5_monthly`); it is not re-fetched.
# Companion: data-raw/build_hs_exchange_factor.R -> data/obs_hs_exchange_factor.rds
#
# Run from the repo root:  Rscript data-raw/download_hs_exchange_obs.R
# UPSERTS into MANIFEST.csv (download_data.R owns the original entries).
# =====================================================================
HX_DIR <- "data-raw/downloads"; HX_MAN <- file.path(HX_DIR, "MANIFEST.csv")
HX_MIN_BYTES <- 5e5
HX_SETS <- list(
  hadisst_ice = list(
    url  = "https://www.metoffice.gov.uk/hadobs/hadisst/data/HadISST_ice.nc.gz",
    dest = "HadISST_ice.nc.gz", gunzip_to = "HadISST_ice.nc",
    cite = paste("Rayner N.A. et al. (2003), J. Geophys. Res. 108(D14), 4407,",
                 "doi:10.1029/2002JD002670. HadISST1 monthly sea-ice concentration, 1 deg."),
    notes = paste("for hs_asx_frac: open-water fraction over the SST<5C area.",
                  "Southern-Ocean ice before the satellite era (pre-1979) is climatological",
                  "in HadISST1 -- windows are chosen 1979 onward for the headline.")),
  ncep_wspd_sig995 = list(
    url  = "https://downloads.psl.noaa.gov/Datasets/ncep.reanalysis/Monthlies/surface/wspd.sig995.mon.mean.nc",
    dest = "ncep_r1_wspd.sig995.mon.mean.nc", gunzip_to = NULL,
    cite = paste("Kalnay E. et al. (1996), Bull. Amer. Meteor. Soc. 77, 437-471,",
                 "doi:10.1175/1520-0477(1996)077<0437:TNYRP>2.0.CO;2. NCEP/NCAR Reanalysis 1,",
                 "monthly mean scalar wind speed at sigma 0.995, 2.5 deg, from NOAA PSL."),
    notes = paste("for hs_asx_frac: the wind half of HILDA's ice-cancels-winds argument.",
                  "Monthly mean |U| at ~40 m, not 10 m and not <U^2>; only the HS/LL RATIO",
                  "is used, so the height and second-moment factors largely cancel.")))
dir.create(HX_DIR, showWarnings = FALSE, recursive = TRUE)
rows <- list()
for (key in names(HX_SETS)) {
  s <- HX_SETS[[key]]; dest <- file.path(HX_DIR, s$dest)
  cat(sprintf("  ... %-18s %s\n", key, s$url))
  res <- try(utils::download.file(s$url, dest, quiet = TRUE, mode = "wb"), silent = TRUE)
  if (inherits(res, "try-error") || !file.exists(dest) || file.info(dest)$size < HX_MIN_BYTES)
    stop(sprintf("FAILED to download %s from %s", key, s$url))
  if (!is.null(s$gunzip_to)) {
    out <- file.path(HX_DIR, s$gunzip_to)
    st <- system2("gunzip", c("-kf", shQuote(dest)))
    if (st != 0 || !file.exists(out)) stop(sprintf("gunzip FAILED for %s", key))
    cat(sprintf("      gunzipped -> %s (%.1f MB)\n", basename(out), file.info(out)$size / 1048576))
  }
  rows[[key]] <- data.frame(
    key = key, file = dest, source = s$url, citation = s$cite, accessed = format(Sys.Date()),
    bytes = file.info(dest)$size, sha256 = tools::sha256sum(dest)[[1]], notes = s$notes,
    stringsAsFactors = FALSE)
  cat(sprintf("  [ok] %-18s %8.1f MB  sha256 %s\n", key, file.info(dest)$size / 1048576,
              substr(rows[[key]]$sha256, 1, 12)))
}
man <- utils::read.csv(HX_MAN, stringsAsFactors = FALSE)
new <- do.call(rbind, rows)
man <- rbind(man[!(man$key %in% new$key), ], new)
utils::write.csv(man, HX_MAN, row.names = FALSE)
cat(sprintf("\nmanifest now %d entries (%s)\n", nrow(man), HX_MAN))
