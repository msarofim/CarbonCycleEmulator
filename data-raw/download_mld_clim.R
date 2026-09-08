# =====================================================================
# download_mld_clim.R -- the OBSERVATION behind the low-latitude mixed-layer
# thickness `h_ml` (and, for the record, the cold box's `h_hs`): the Holte et
# al. (2017) Argo mixed-layer climatology (2026-09-08; handoff 09-08b sec.2).
#
# Every HILDA round fits `h_ml` at ~40 m against `ent26`'s 134 m, and no
# observation has ever been put beside either number. Neither de Boyer
# Montegut et al. 2004 nor Holte et al. 2017 PRINTS a global or low-latitude
# annual mean, so it must be COMPUTED from the product. This fetches the
# monthly 1-deg climatology (density-threshold AND hybrid-algorithm MLDs, from
# ~1.25 M Argo profiles); the companion build script does the area-weighting.
# Companion: data-raw/build_mld_targets.R -> data/obs_mld.rds
#
# Run from the repo root:  Rscript data-raw/download_mld_clim.R
# UPSERTS into MANIFEST.csv (download_data.R owns the original entries).
# =====================================================================
MLD_DIR <- "data-raw/downloads"; MLD_MAN <- file.path(MLD_DIR, "MANIFEST.csv")
MLD_MIN_BYTES <- 1e8   # the server reports 115,355,604 bytes (curl -I, 2026-09-08)
MLD_SETS <- list(
  holte_mld_argo_clim = list(
    url  = "https://mixedlayer.ucsd.edu/data/Argo_mixedlayers_monthlyclim_04142022.nc",
    dest = "Argo_mixedlayers_monthlyclim_04142022.nc",
    cite = paste("Holte J., Talley L.D., Gilson J., Roemmich D. (2017), Geophys. Res. Lett. 44,",
                 "5618-5626, doi:10.1002/2017GL073426. An Argo mixed layer climatology and",
                 "database: monthly 1-deg climatology, product dated 2022-04-14, mixedlayer.ucsd.edu."),
    notes = paste("for h_ml (and h_hs for the record): the low-latitude (|lat| < 57, the model's",
                  "hs_frac 0.16 boundary) annual-mean and annual-maximum mixed-layer thickness,",
                  "cos(lat) area-weighted; density-threshold and hybrid-algorithm variants both",
                  "carried. Server Last-Modified 2022-04-26.")))
dir.create(MLD_DIR, showWarnings = FALSE, recursive = TRUE)
options(timeout = 1800)
rows <- list()
for (key in names(MLD_SETS)) {
  s <- MLD_SETS[[key]]; dest <- file.path(MLD_DIR, s$dest)
  cat(sprintf("  ... %-20s %s\n", key, s$url))
  res <- try(utils::download.file(s$url, dest, quiet = TRUE, mode = "wb"), silent = TRUE)
  if (inherits(res, "try-error") || !file.exists(dest) || file.info(dest)$size < MLD_MIN_BYTES)
    stop(sprintf("FAILED to download %s from %s", key, s$url))
  rows[[key]] <- data.frame(
    key = key, file = dest, source = s$url, citation = s$cite, accessed = format(Sys.Date()),
    bytes = file.info(dest)$size, sha256 = tools::sha256sum(dest)[[1]], notes = s$notes,
    stringsAsFactors = FALSE)
  cat(sprintf("  [ok] %-20s %8.1f MB  sha256 %s\n", key, file.info(dest)$size / 1048576,
              substr(rows[[key]]$sha256, 1, 12)))
}
man <- utils::read.csv(MLD_MAN, stringsAsFactors = FALSE)
new <- do.call(rbind, rows)
man <- rbind(man[!(man$key %in% new$key), ], new)
utils::write.csv(man, MLD_MAN, row.names = FALSE)
cat(sprintf("\nmanifest now %d entries (%s)\n", nrow(man), MLD_MAN))
