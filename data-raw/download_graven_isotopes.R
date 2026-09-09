# =====================================================================
# download_graven_isotopes.R -- the INDEPENDENT atmospheric carbon-isotope
# record (2026-09-09; the isotopic-data audit of handoff 09-08j sec.3.4).
#
# WHY THIS EXISTS. For the bomb window (1950-1980) the repo has exactly ONE
# atmospheric D14C product -- Hua et al. 2022, in data/obs_d14c_zonal.rds --
# and that same record ALSO supplies the sub-annual shape of the bomb source
# function (data-raw/build_bomb_c14_source.R). So the window's only isotopic
# concentration constraint is both an INPUT and a TARGET, and there is no
# second product to arbitrate. There is also NO d13C observation of any kind
# in that window: the flask record (data/obs_d13c_monthly.rds) starts 1977.2
# and data/obs_icecore.rds has ZERO samples in 1950-1980.
#
# ⚠ VINTAGE -- READ THIS BEFORE CITING. DATA.md sec.9 refers to "Graven et al.
# 2017, GMD 10:4405 ... input4MIPs doi:10.22033/ESGF/input4MIPs.1601 and .1602"
# and says the product is "retained as a d13C cross-check". It was NEVER
# ACQUIRED -- no file existed on disk before this script. What ESGF now serves
# under these variables is the SUCCESSOR: CMIP7 / C4MIP / ImperialCollege-3-0,
# version v20250502, spanning 1700-2023. That is a DIFFERENT DATASET from the
# CMIP6 v1.2.0 (1850-2015) the 2017 paper describes -- more recent and longer,
# but do NOT label it "Graven et al. 2017". Label it as below.
#
# ⚠ AND IT IS NOT FULLY INDEPENDENT OF HUA. Graven's compilation is built from
# the same underlying station and tree-ring measurements; it is an independent
# COMPILATION AND GRIDDING, not an independent observing system. It can test
# zonal aggregation, baseline convention and version drift. It CANNOT provide a
# statistically independent second sample of the bomb transient. Said here
# rather than discovered later. [[threshold_from_obs_or_law]]
#
# The two files are TINY (48.7 kB / 31.3 kB) and are verified against the
# publisher's own SHA256, which is external to this repo and to the model.
#
# Run from the repo root:  Rscript data-raw/download_graven_isotopes.R
# UPSERTS into MANIFEST.csv (download_data.R owns the original entries).
# =====================================================================
GRV_DIR <- "data-raw/downloads"; GRV_MAN <- file.path(GRV_DIR, "MANIFEST.csv")
GRV_BASE <- paste0("https://esgf1.dkrz.de/thredds/fileServer/input4mips/input4MIPs/",
                   "CMIP7/C4MIP/ImperialCollege/ImperialCollege-3-0/atmos/yr/")
GRV_CITE <- paste("Graven H. et al. (2017), Geosci. Model Dev. 10:4405-4417,",
                  "doi:10.5194/gmd-10-4405-2017, 'Compiled records of carbon isotopes in",
                  "atmospheric CO2 for historical simulations in CMIP6'. FILE VINTAGE:",
                  "input4MIPs CMIP7/C4MIP ImperialCollege-3-0 v20250502 (1700-2023) --",
                  "the SUCCESSOR to the CMIP6 v1.2.0 (1850-2015) described in the paper.")
GRV_SETS <- list(
  graven_d14c_zonal = list(
    sub  = "Delta14co2/gz/v20250502/",
    dest = "Delta14co2_input4MIPs_atmosphericState_C4MIP_ImperialCollege-3-0_gz_1700-2023.nc",
    sha  = "5541d1e063cefc55c7b2519d319d3d8d0d80ae2b1f278107db484d2fe7691b71",
    bytes = 48712,
    notes = paste("ZONAL (gz) annual Delta14C, 1700-2023. The independent cross-check on",
                  "Hua et al. 2022 for the bomb window; an independent COMPILATION, not an",
                  "independent observing system. 3 zones vs Hua's 5 -- aggregate BOTH to the",
                  "model's hemispheres with ccx_zone_weights() before any comparison.")),
  graven_d13c_global = list(
    sub  = "delta13co2/gm/v20250502/",
    dest = "delta13co2_input4MIPs_atmosphericState_C4MIP_ImperialCollege-3-0_gm_1700-2023.nc",
    sha  = "29f9d01da0f82b5e10b95e750ac2d1afb95d213b603b9306fabf6d5b98ff45be",
    bytes = 31313,
    notes = paste("GLOBAL MEAN (gm) annual delta13C, 1700-2023. The ONLY d13C record covering",
                  "1950-1980: the flask record starts 1977.2 and the ice cores have no samples",
                  "there. Global mean only -- it cannot test the hemispheric d13C gradient.")))

dir.create(GRV_DIR, showWarnings = FALSE, recursive = TRUE)
options(timeout = 1800)
cat("\n=== Graven atmospheric carbon isotopes (input4MIPs) ===\n")
rows <- list()
for (key in names(GRV_SETS)) {
  s <- GRV_SETS[[key]]; url <- paste0(GRV_BASE, s$sub, s$dest); dest <- file.path(GRV_DIR, s$dest)
  cat(sprintf("  ... %-20s %s\n", key, s$dest))
  res <- try(utils::download.file(url, dest, quiet = TRUE, mode = "wb"), silent = TRUE)
  if (inherits(res, "try-error") || !file.exists(dest))
    stop(sprintf("FAILED to download %s from %s", key, url))
  got <- tools::sha256sum(dest)[[1]]
  # The gate is the PUBLISHER's checksum, external to this repo and to the
  # model. A size check alone would pass on a truncated or an error-page body.
  if (!identical(got, s$sha))
    stop(sprintf("CHECKSUM MISMATCH for %s\n  expected %s\n  got      %s", key, s$sha, got))
  if (file.info(dest)$size != s$bytes)
    stop(sprintf("SIZE MISMATCH for %s: expected %d, got %d", key, s$bytes, file.info(dest)$size))
  rows[[key]] <- data.frame(
    key = key, file = dest, source = url, citation = GRV_CITE, accessed = format(Sys.Date()),
    bytes = file.info(dest)$size, sha256 = got, notes = s$notes, stringsAsFactors = FALSE)
  cat(sprintf("  [ok] %-20s %8.1f kB  sha256 %s VERIFIED against ESGF\n",
              key, file.info(dest)$size / 1024, substr(got, 1, 12)))
}
man <- utils::read.csv(GRV_MAN, stringsAsFactors = FALSE)
new <- do.call(rbind, rows)
man <- rbind(man[!(man$key %in% new$key), ], new)
utils::write.csv(man, GRV_MAN, row.names = FALSE)
cat(sprintf("\nmanifest now %d entries (%s)\n", nrow(man), GRV_MAN))
cat("⚠ Vintage is ImperialCollege-3-0 v20250502 (1700-2023), NOT the CMIP6 v1.2.0 of the paper.\n")
