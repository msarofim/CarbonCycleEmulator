# =====================================================================
# download_data.R — acquire all raw calibration inputs
#
# Every dataset below records: URL (or local provenance), access date,
# SHA-256 checksum, and citation. The manifest is written to
# data-raw/downloads/MANIFEST.csv and is the provenance record for the
# whole calibration. Re-running this script re-downloads and re-checksums;
# a changed checksum on an unchanged upstream version is a red flag.
#
# Run:  Rscript data-raw/download_data.R
# =====================================================================

suppressWarnings(suppressMessages({
  library(tools)
}))

# Run from the repo root.
DL_DIR   <- "data-raw/downloads"
ACCESSED <- as.character(Sys.Date())

dir.create(DL_DIR, showWarnings = FALSE, recursive = TRUE)

manifest <- list()

record <- function(key, file, source, citation, notes = "") {
  stopifnot(file.exists(file))
  manifest[[key]] <<- data.frame(
    key       = key,
    file      = file,
    source    = source,
    citation  = citation,
    accessed  = ACCESSED,
    bytes     = file.info(file)$size,
    sha256    = tools::sha256sum(file)[[1]],
    notes     = notes,
    stringsAsFactors = FALSE
  )
  cat(sprintf("  [ok] %-14s %8.1f kB  %s\n", key, file.info(file)$size / 1024, basename(file)))
}

fetch <- function(key, url, dest, citation, notes = "") {
  dest <- file.path(DL_DIR, dest)
  cat(sprintf("  ... %-14s %s\n", key, url))
  res <- try(utils::download.file(url, dest, quiet = TRUE, mode = "wb"), silent = TRUE)
  if (inherits(res, "try-error") || !file.exists(dest) || file.info(dest)$size < 500) {
    stop(sprintf("FAILED to download %s from %s", key, url))
  }
  record(key, dest, url, citation, notes)
}

cat("\n=== CarbonCycleEmulator: raw data acquisition ===\n")
cat("Access date:", ACCESSED, "\n\n")

# ---------------------------------------------------------------------
# 1. Atmospheric CO2 — instrumental record
# ---------------------------------------------------------------------
cat("[1] Atmospheric CO2 (instrumental)\n")

fetch("co2_mlo",
      "https://gml.noaa.gov/webdata/ccgg/trends/co2/co2_mm_mlo.csv",
      "co2_mm_mlo.csv",
      paste("Lan X, Tans P, Thoning K / NOAA GML. Trends in globally-averaged CO2.",
            "Mauna Loa monthly mean CO2 (Keeling C.D., Scripps + NOAA GML)."),
      "NH target; monthly means 1958-03 onward; ppm dry-air mole fraction")

fetch("co2_spo",
      paste0("https://gml.noaa.gov/aftp/data/trace_gases/co2/flask/surface/txt/",
             "co2_spo_surface-flask_1_ccgg_month.txt"),
      "co2_spo_surface-flask_1_ccgg_month.txt",
      "NOAA GML Carbon Cycle Cooperative Global Air Sampling Network, South Pole (SPO) flask CO2.",
      "SH target; monthly flask means")

# ---------------------------------------------------------------------
# 2. Atmospheric CO2 + d13C — ice core / firn (pre-instrumental)
# ---------------------------------------------------------------------
cat("[2] Law Dome ice core / firn (CO2 + d13C)\n")

fetch("lawdome",
      "https://www.ncei.noaa.gov/pub/data/paleo/icecore/antarctica/law/law2018co2.txt",
      "law2018co2.txt",
      paste("Rubino M, Etheridge DM, Thornton DP, et al. (2019). Law Dome ice core 2000-year",
            "CO2, CH4, N2O and d13C-CO2. Earth Syst. Sci. Data 11:473-492.",
            "Data: doi:10.25919/5bfe29ff807fb; NOAA/WDS Paleo study 25830."),
      "Pre-1958 CO2 target; SampleID/age_ice/age_CO2/CO2ppm/CO2err, firn + ice")

fetch("lawdome_d13c",
      "https://www.ncei.noaa.gov/pub/data/paleo/icecore/antarctica/law/law2018d13c-co2.txt",
      "law2018d13c-co2.txt",
      "Rubino M, et al. (2019), as above — d13C-CO2 table.",
      "Pre-1990 d13C target (NOAA/INSTAAR flask record starts 1990)")

fetch("lawdome_spline",
      "https://www.ncei.noaa.gov/pub/data/paleo/icecore/antarctica/law/law2018splines.txt",
      "law2018splines.txt",
      "Rubino M, et al. (2019), as above — spline-smoothed composite records.",
      "Smooth annual composite; candidate pre-1958 CO2/d13C target in place of raw samples")

# ---------------------------------------------------------------------
# 3. d13C — modern flask network
# ---------------------------------------------------------------------
cat("[3] d13C-CO2 (modern flask, NOAA/INSTAAR)\n")

for (stn in c("mlo", "spo")) {
  fetch(paste0("d13c_", stn),
        sprintf(paste0("https://gml.noaa.gov/aftp/data/trace_gases/co2c13/flask/surface/",
                       "co2c13_%s_surface-flask_1_sil_month.txt"), stn),
        sprintf("co2c13_%s_surface-flask_1_sil_month.txt", stn),
        paste("NOAA GML / INSTAAR Stable Isotope Lab, Cooperative Global Air Sampling Network,",
              toupper(stn), "d13C-CO2 monthly flask means."),
        "Suess-effect target; record starts ~1990")
}

# ---------------------------------------------------------------------
# 4. Global Carbon Budget — sink partition constraint
# ---------------------------------------------------------------------
cat("[4] Global Carbon Budget 2025\n")

fetch("gcb_global",
      paste0("https://openclimatedata.github.io/global-carbon-budget/data/",
             "global-carbon-budget-2025-global-carbon-budget.csv"),
      "gcb2025_global_budget.csv",
      paste("Friedlingstein P, et al. (2026). Global Carbon Budget 2025.",
            "Earth Syst. Sci. Data 18:3211. Data doi:10.18160/GCP-2025",
            "(tidy CSV mirror of Global_Carbon_Budget_2025_v1.0.xlsx via openclimatedata)."),
      "1959-2024, GtC/yr: fossil, LUC, atm growth, ocean sink, land sink, cement carbonation, imbalance")

fetch("gcb_hist",
      paste0("https://openclimatedata.github.io/global-carbon-budget/data/",
             "global-carbon-budget-2025-historical-budget.csv"),
      "gcb2025_historical_budget.csv",
      "Friedlingstein P, et al. (2026), GCB 2025 historical budget sheet (as above).",
      "1750-2024 GtC/yr; source of prescribed fossil + LUC emissions forcing")

# The by-fuel split is what makes the fossil source d13C time-varying. The
# budget sheets above give only the TOTAL fossil column, which is fossil fuel
# AND INDUSTRY -- cement included. Cement carbon is limestone at d13C ~ 0 permil
# and coal, oil and gas are ~ -24, -26.5 and -44, so a single constant applied
# to the total is wrong twice over (see data-raw/build_calibration_data.R [3b]).
fetch("gcb_fossil_by_fuel",
      paste0("https://openclimatedata.github.io/global-carbon-budget/data/",
             "global-carbon-budget-2025-fossil-emissions.csv"),
      "gcb2025_fossil_emissions_by_fuel.csv",
      paste("Friedlingstein P, et al. (2026), GCB 2025 'Fossil Emissions by Category'",
            "sheet (as above)."),
      "1850-2024 GtC/yr by fuel: Coal, Oil, Gas, Cement.emission, Flaring, Other")

# ---------------------------------------------------------------------
# 5. ENSO index
# ---------------------------------------------------------------------
cat("[5] ENSO indices\n")
# DESIGN.md specified MEIv2 spliced to extended MEI (MEI.ext). NOAA PSL has
# RETIRED the MEI.ext distribution (404 as of this access date), so both a
# modern MEI and a long Nino 3.4 record are pulled; the choice of which
# drives the model is a flagged methodological decision (see CHANGELOG).

fetch("meiv2",
      "https://psl.noaa.gov/enso/mei/data/meiv2.data",
      "meiv2.data",
      "Zhang T, et al. / NOAA PSL. Multivariate ENSO Index Version 2 (MEI.v2).",
      "1979-present, bimonthly")

fetch("nino34",
      "https://psl.noaa.gov/data/correlation/nina34.data",
      "nina34.data",
      "NOAA PSL Nino 3.4 SST index (5N-5S, 170W-120W), from NOAA ERSST.",
      "1948-present, monthly; candidate long ENSO index covering the full dense-CO2 era")

# ---------------------------------------------------------------------
# 6. Atmospheric Delta14C — Hua et al. 2022 zonal compilation (via SoilR)
# ---------------------------------------------------------------------
cat("[6] Delta14C zonal compilation (Hua et al. 2022)\n")

if (!requireNamespace("SoilR", quietly = TRUE)) {
  stop("Package 'SoilR' required for the Hua et al. (2022) Delta14C compilation.\n",
       "  install.packages('SoilR')")
}
hua_file <- file.path(DL_DIR, "hua2022_zonal_d14c.rds")
hua <- SoilR::Hua2021          # object name retains the 2021 preprint naming
saveRDS(hua, hua_file)
record("d14c_hua", hua_file,
       sprintf("R package SoilR %s, dataset Hua2021 (= Supplementary Material 2 of the paper)",
               as.character(utils::packageVersion("SoilR"))),
       paste("Hua Q, Turnbull JC, Santos GM, et al. (2022). Atmospheric radiocarbon for the",
             "period 1950-2019. Radiocarbon 64(4):723-745. doi:10.1017/RDC.2021.95"),
       paste("5 zones (NHZone1/2/3, SHZone1-2, SHZone3), monthly mean+sd Delta14C and F14C,",
             "1941-2019. NH box target = NHZone1/2/3; SH box target = SHZone1-2 + SHZone3."))

# ---------------------------------------------------------------------
# 6b. Nuclear-industry gaseous 14C emissions (Zenodo, CC-BY-4.0)
# ---------------------------------------------------------------------
# NOT the bomb source -- this is routine reactor + reprocessing release. It was
# originally slated for the v2 backlog as "small", but a magnitude check
# (CHANGELOG 2026-08-10) showed it reaches ~11 % of the modern observed D14C
# tendency, so it is a v1 term. Units are GBq of 14C.
cat("[6b] Nuclear-industry 14C emissions (Laemmel et al., Zenodo 15034663)\n")

NUC_DIR <- file.path(DL_DIR, "nuclear14c")
dir.create(NUC_DIR, showWarnings = FALSE, recursive = TRUE)
nuc_files <- c(
  "NFRP_14C_annual_emissions_1950_2023.csv",
  "Other_countries_NPP_14C_annual_emissions_1983_2023.csv",
  "USA_NPP_14C_annual_emissions_2010_2023.csv",
  "Canada_NPP_14C_annual_emissions_1985_2023.csv",
  "Germany_NPP_14C_annual_emissions_1976_2023.csv",
  "France_NPP_14C_annual_emissions_2005_2023.csv",
  "China_NPP_14C_annual_emissions_2013_2023.csv",
  "South_Korea_NPP_14C_annual_emissions_1998_2023.csv",
  "Switzerland_NPP_14C_annual_emissions_1990_2023.csv"
)
for (nf in nuc_files) {
  dest <- file.path("nuclear14c", nf)
  fetch(paste0("nuc_", sub("_14C.*", "", nf)),
        sprintf("https://zenodo.org/records/15034663/files/%s?download=1", nf),
        dest,
        paste("Laemmel T, Knaack T, Heckel A, Wenger A, Szidat S (2025).",
              "Compilation of nuclear industry's gaseous radiocarbon emissions",
              "from 1950 to 2023. Zenodo, doi:10.5281/zenodo.15034663. CC-BY-4.0."),
        "GBq 14C; semicolon-delimited; NPP = power plants, NFRP = fuel reprocessing")
}

# ---------------------------------------------------------------------
# 6b. Oceanic 13C Suess effect — the CROSS-CHECK on ocean 13C uptake
# ---------------------------------------------------------------------
# Added 2026-08-13. The model's atmospheric d13C is a likelihood target; the
# OCEAN's own d13C decline never was, so ocean-side 13C uptake has been running
# unscored. This is the observational field that scores it. See DATA.md sec.2
# and calibration/diag_oceanic_suess.R.
#
# 17 MB, 1x1 degree x 33 WOA standard depth levels, NetCDF classic. Reduced to
# an area-weighted depth profile by build_calibration_data.R [8]; only the
# profile is committed.
cat("[6b] Eide et al. 2017 oceanic 13C Suess effect climatology\n")

fetch("eide_c13_suess",
      paste0("https://store.pangaea.de/Publications/EideM-etal_2017/",
             "C13_Climatology_13CSuessEffect.nc"),
      "eide2017_c13_suess_effect.nc",
      paste("Eide M, Olsen A, Ninnemann US, Eldevik T (2017). A global estimate of the",
            "full oceanic 13C Suess effect since the preindustrial.",
            "Global Biogeochem. Cycles 31:492-514, doi:10.1002/2016GB005472.",
            "Dataset: doi:10.1594/PANGAEA.871993, CC-BY-3.0."),
      paste("Full 13C Suess effect, preindustrial -> GLODAPv1.1 era (1990s).",
            "CAVEAT: above 200 m the field is the 200 m back-calculation plus a",
            "SPATIALLY CONSTANT depth offset (verified, sd exactly 0), so its",
            "horizontal pattern above 200 m carries no independent information --",
            "use the global mean, not the hemispheric contrast."))

# ---------------------------------------------------------------------
# 7. Local provenance — files reused from sibling projects (not downloaded)
# ---------------------------------------------------------------------
cat("[7] Local inputs copied from sibling repos\n")

local_inputs <- list(
  list(key   = "gmst_igcc",
       from  = paste0("~/Documents/2026/CodeProjects/SLR-RFF-BRICK/data/observations/",
                      "igcc2024_gmst_4dataset_mean.csv"),
       to    = "igcc2024_gmst_4dataset_mean.csv",
       cite  = paste("Forster PM, et al. Indicators of Global Climate Change (IGCC) 2024;",
                     "4-dataset GMST mean, anomalies relative to 1850-1900."),
       notes = "Drives Q10 respiration and the SST solubility factor (standing obs convention)"),
  list(key   = "ssp_rcmip",
       from  = "~/Documents/2026/CodeProjects/FaIRtoFrEDI/data/rcp/rcmip-emissions-annual-means-v5-1-0.csv",
       to    = "rcmip-emissions-annual-means-v5-1-0.csv",
       cite  = paste("Nicholls Z, et al. RCMIP protocol emissions v5.1.0",
                     "(Emissions|CO2|MAGICC Fossil and Industrial + MAGICC AFOLU, Mt CO2/yr)."),
       notes = "Future SSP scenarios for the app: ssp119/126/245/370/585, World region, to 2500")
)

for (li in local_inputs) {
  src <- path.expand(li$from)
  dst <- file.path(DL_DIR, li$to)
  if (!file.exists(src)) {
    warning(sprintf("Local input missing, skipped: %s (%s)", li$key, src))
    next
  }
  file.copy(src, dst, overwrite = TRUE)
  record(li$key, dst, paste("local:", li$from), li$cite, li$notes)
}

# ---------------------------------------------------------------------
# Manifest
# ---------------------------------------------------------------------
man <- do.call(rbind, manifest)
write.csv(man, file.path(DL_DIR, "MANIFEST.csv"), row.names = FALSE)

cat(sprintf("\n=== %d datasets acquired; manifest -> %s ===\n",
            nrow(man), file.path(DL_DIR, "MANIFEST.csv")))
cat("\nNOTE: the Scripps South Pole records are NOT downloadable (scrippsco2.ucsd.edu\n")
cat("      is 404 site-wide). They were supplied by hand and are TRACKED IN GIT under\n")
cat("      data-raw/manual/ -- see the README there. Do not delete that directory.\n")

cat("\nStill OUTSTANDING (see CHANGELOG):\n")
cat("  - bomb 14C production history (atmospheric nuclear test yields)\n")
cat("  - optional: ocean bomb-14C inventory integral constraint\n")
