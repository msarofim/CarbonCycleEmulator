# =====================================================================
# build_vv_scenarios.R -- the seven van Vuuren ScenarioMIP-CMIP7 marker
# scenarios as CCX inputs (Marcus 2026-09-29: "moving to van Vuuren is the right
# call ... all seven marker scenarios", on the FaIRtoFrEDI splice method).
#
# WHY. The app's scenario menu ran on RCMIP v5.1.0 CMIP6 SSPs, whose
# "MAGICC AFOLU" land-use history is 90 GtC SHORT of the GCB budget CCX is
# fitted to (1750-2014: 185.3 vs 275.6 GtC; van Vuuren's CMIP7 history 244.0).
# The app splices GCB over every scenario's past (app_splice_history(), 09-22
# ruling), so the menu's FUTURE is what this changes; van Vuuren is the current
# (CMIP7) scenario set, carries REAL published emissions to 2500 (truncated at
# the standing 2300 end year), and is the set FaIRtoFrEDI's work already uses.
#
# THE SPLICE (the FaIRtoFrEDI "zenodo" variant, the NCC publication basis): own
# history up to the seam, then the published Zenodo v1.1.1 series VERBATIM, no
# harmonization. In CCX "own history" is GCB through its last year, applied at
# run time by app_splice_history() (APP_SPLICE_YEAR = the last GCB year). So
# this file stores the Zenodo series UNMODIFIED, like ssp_emissions.rds, and the
# seam lives in exactly one place.
#
# TWO OUTPUTS, both schema-identical to their SSP counterparts:
#   data/vv_emissions.rds         scenario, year, fossil_GtC, luc_GtC   (= ssp_emissions.rds)
#   data/forcing_climate_vv.rds   scenario, year, gmst_C, ..., erf_nonco2 (= forcing_climate_ssp.rds)
# The climate MODULE (data/climate_module.rds) is NOT refitted: it stays fitted
# to the SSP runs; the vV runs only supply each marker's prescribed non-CO2 ERF.
#
# PROVENANCE
#   emissions: Zenodo 10.5281/zenodo.20713982 v1.1.1 (2026-06-16), file
#     data/fair-inputs/emissions_1750-2500.csv in chrisroadmap/cmip7-scenariomip-1.1.1.zip.
#     ⚠ NOT the DOI printed in van Vuuren et al. 2026 (GMD 19:2627), which resolves to the
#     stylized v1.0. Taken from FaIRtoFrEDI's PINNED copy (pinned 2026-09-28T14:37Z,
#     scripts/pin_inputs.py); the sha256 below is checked, so a different file is an error.
#   forcing: data-raw/downloads/fair_v160_vv/ from FaIRtoFrEDI/scripts/run_fair_vv_for_ccx.py
#     (FaIR 2.2.4, calib 1.6.0 prod, 841 configs, ensemble mean); checked against its MANIFEST.
#
# Usage: Rscript data-raw/build_vv_scenarios.R
# =====================================================================
for (f in list.files("R", pattern = "\\.R$", full.names = TRUE)) source(f)

# ---- named constants ---------------------------------------------------
VV_ZENODO_DOI  <- "10.5281/zenodo.20713982"
VV_ZENODO_VER  <- "1.1.1"
VV_ZENODO_URL  <- "https://zenodo.org/api/records/20713982/files/chrisroadmap/cmip7-scenariomip-1.1.1.zip/content"
VV_PINNED_SRC  <- "~/Documents/2026/CodeProjects/FaIRtoFrEDI/data/vanvuuren/zenodo_v111_emissions_1750-2500.csv"
VV_PINNED_SHA  <- "1ada0d6089247fe79080a2744ed711502b97bbb3fd921cf9439aca88ea2a240a"
VV_PINNED_UTC  <- "2026-09-28T14:37:18+00:00"
VV_DL_DIR      <- ccx_path("data-raw", "downloads", "vanvuuren_zenodo_v111")
VV_FAIR_DIR    <- ccx_path("data-raw", "downloads", "fair_v160_vv")
VV_END_YEAR    <- 2300          # standing end year (Marcus 2026-08-28); the source runs to 2500
GtCO2_PER_GtC  <- 3.664         # same constant as build_calibration_data.R (GCB 2025 stated)
# Marker code -> CCX scenario key, and the source's own scenario column. Declared,
# not parsed -- the same bijection FaIRtoFrEDI's drivers gate on.
VV_MARKERS <- data.frame(
  key    = c("vvVL", "vvLN", "vvL", "vvML", "vvM", "vvHL", "vvH"),
  marker = c("VL",   "LN",   "L",   "ML",   "M",   "HL",   "H"),
  stringsAsFactors = FALSE)
VV_VARS <- c(fossil = "CO2 FFI", luc = "CO2 AFOLU")

sha256 <- function(p) digest::digest(file = p, algo = "sha256")
cat("\n=== build_vv_scenarios.R ===\n")

# ---- 1. the emissions: copy the pinned file in, verify, read --------------
dir.create(VV_DL_DIR, showWarnings = FALSE, recursive = TRUE)
dst <- file.path(VV_DL_DIR, basename(VV_PINNED_SRC))
if (!file.exists(dst)) invisible(file.copy(path.expand(VV_PINNED_SRC), dst))
got <- sha256(dst)
if (!identical(got, VV_PINNED_SHA))
  stop("van Vuuren emissions sha256 ", got, " != pinned ", VV_PINNED_SHA,
       ". Re-fetch with: curl -L -o s111.zip '", VV_ZENODO_URL, "' && unzip")
writeLines(c(sprintf("source: Zenodo %s v%s, data/fair-inputs/emissions_1750-2500.csv", VV_ZENODO_DOI, VV_ZENODO_VER),
             sprintf("url: %s", VV_ZENODO_URL),
             sprintf("copied from: %s (pinned %s)", VV_PINNED_SRC, VV_PINNED_UTC),
             sprintf("sha256: %s", got),
             sprintf("copied: %s", format(Sys.Date()))),
           file.path(VV_DL_DIR, "PROVENANCE.txt"))
cat(sprintf("[1] %s sha256 verified\n", basename(dst)))

v <- utils::read.csv(dst, check.names = FALSE, stringsAsFactors = FALSE)
if (!setequal(unique(v$scenario), VV_MARKERS$marker))
  stop("source scenarios {", paste(sort(unique(v$scenario)), collapse = ","),
       "} != the declared markers")
ycol <- grep("^[0-9]", names(v), value = TRUE)
yrs  <- floor(as.numeric(ycol))                 # FaIR mid-year stamps: 1750.5 -> 1750
keep <- yrs <= VV_END_YEAR
units <- unique(v$unit[v$variable %in% VV_VARS])
if (!identical(units, "Mt CO2/yr")) stop("unexpected CO2 units: ", paste(units, collapse = ", "))

em <- do.call(rbind, lapply(seq_len(nrow(VV_MARKERS)), function(i) {
  g <- function(var) {
    r <- v[v$scenario == VV_MARKERS$marker[i] & v$variable == var, ycol]
    if (nrow(r) != 1L) stop(VV_MARKERS$marker[i], " has ", nrow(r), " rows of ", var)
    as.numeric(r[1, keep]) / 1000 / GtCO2_PER_GtC   # Mt CO2/yr -> GtC/yr
  }
  data.frame(scenario = VV_MARKERS$key[i], year = as.integer(yrs[keep]),
             fossil_GtC = g(VV_VARS[["fossil"]]), luc_GtC = g(VV_VARS[["luc"]]))
}))
if (anyNA(em)) stop("NA in the van Vuuren CO2 emissions")
attr(em, "provenance") <- sprintf(
  "van Vuuren et al. 2026 ScenarioMIP-CMIP7 markers, Zenodo %s v%s (sha256 %s), CO2 FFI + AFOLU, %d-%d; GCB history is spliced at run time (app_splice_history)",
  VV_ZENODO_DOI, VV_ZENODO_VER, substr(got, 1, 12), min(em$year), max(em$year))
saveRDS(em, ccx_path("data", "vv_emissions.rds"))
cat(sprintf("[1] data/vv_emissions.rds: %d markers, %d-%d\n", nrow(VV_MARKERS), min(em$year), max(em$year)))

# ---- 2. the non-CO2 forcing: verify against the export's MANIFEST ---------
man <- utils::read.csv(file.path(VV_FAIR_DIR, "MANIFEST.csv"), stringsAsFactors = FALSE)
cl <- do.call(rbind, lapply(seq_len(nrow(VV_MARKERS)), function(i) {
  fn <- sprintf("fair_v160_%s.csv", VV_MARKERS$key[i])
  p  <- file.path(VV_FAIR_DIR, fn)
  row <- man[man$file == fn, ]
  if (nrow(row) != 1L) stop(fn, " is not in MANIFEST.csv exactly once")
  if (!identical(sha256(p), row$sha256)) stop(fn, " does not match its MANIFEST sha256")
  d <- utils::read.csv(p)
  d$scenario <- VV_MARKERS$key[i]
  d[d$year <= VV_END_YEAR, ]
}))
cl <- cl[, c("scenario", "year", "gmst_C", "gmst_p05", "gmst_p95",
             "co2_ppm", "erf_total", "erf_co2", "erf_nonco2")]
attr(cl, "provenance") <- unique(man$source)
saveRDS(cl, ccx_path("data", "forcing_climate_vv.rds"))
cat(sprintf("[2] data/forcing_climate_vv.rds: %d markers, %d-%d, %s\n",
            nrow(VV_MARKERS), min(cl$year), max(cl$year), unique(man$source)))

# ---- 3. the seam, REPORTED (the splice is verbatim, so the step is real) ---
h <- as.data.frame(readRDS(ccx_path("data", "forcing_emissions_historical.rds")))
hy <- max(h$year)
cat(sprintf("\n[3] the seam: GCB %d vs each marker's %d (GtC/yr; the splice is a verbatim step)\n", hy, hy + 1L))
cat(sprintf("    GCB %d: fossil %.2f  luc %.2f\n", hy, h$fossil_GtC[h$year == hy], h$luc_GtC[h$year == hy]))
for (k in VV_MARKERS$key) {
  z <- em[em$scenario == k & em$year == hy + 1L, ]
  cat(sprintf("    %-5s %d: fossil %.2f (%+.2f)  luc %.2f (%+.2f)\n", k, hy + 1L,
              z$fossil_GtC, z$fossil_GtC - h$fossil_GtC[h$year == hy],
              z$luc_GtC, z$luc_GtC - h$luc_GtC[h$year == hy]))
}
