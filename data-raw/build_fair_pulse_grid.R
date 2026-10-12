# =====================================================================
# build_fair_pulse_grid.R -- FaIR 2.2.4 (calib 1.6.0) on the pulse lab's OWN pulse
#
# RULED (Marcus 2026-10-12, "Keep card 5; FaIR on same pulse (Recommended)"): card 5 stays in the
# Review tab; the pulse lab gets FaIR's mean and 5-95 % band for the SAME scenario pulse,
# precomputed over a grid (scenarios x release years at 100 GtC) and shown only when the
# user's settings match a grid point.
#
# SOURCE: data-raw/downloads/fair_v160_vv_pulse/, written by
#   FaIRtoFrEDI/scripts/run_fair_vv_pulse_grid_for_ccx.py
# which IMPORTS the app's own FaIR scenario exporter (run_fair_vv_for_ccx.py) and differs from it
# only by the pulse; its gate G2 proves every baseline arm IS the app's FaIR scenario line.
#
# THIS SCRIPT REFUSES:
#   * a CSV whose sha256 is not the one its provenance records;
#   * a driver that had uncommitted changes at run time ("+dirty");
#   * a pulse that is not FPG_PULSE_GTC, a release that is not spread over the release year, a
#     metric that is not FaIR's own airborne accounting, or fewer configs than FPG_N;
#   * a gate file that does not hold G1 and a G2 and a G3+G5 row for every arm.
# The APP checks the grid against its own constants at load (app/global.R APP_FAIR_PULSE_LOAD).
#
# OUTPUT: data/fair_pulse_grid.rds -- scenario, release_year, year, af_mean, af_median, af_p05,
#   af_p95, d_co2_ppm_mean, d_gmst_mean; attributes `provenance` (named list), `gates`
#   (data.frame) and `source_sha256`.
#
# Usage: Rscript data-raw/build_fair_pulse_grid.R
# =====================================================================
for (f in list.files("R", pattern = "\\.R$", full.names = TRUE)) source(f)

FPG_DIR    <- ccx_path("data-raw", "downloads", "fair_v160_vv_pulse")
FPG_STEM   <- "fair_v160_vv_pulse100"
FPG_LABEL  <- "FaIR 2.2.4 (calib 1.6.0)"
FPG_N      <- 841L
FPG_PULSE_GTC <- 100
FPG_OUT    <- ccx_path("data", "fair_pulse_grid.rds")
FPG_REPORT_H <- c(1, 20, 100)        # yr after the release, printed only

sha256 <- function(p) digest::digest(file = p, algo = "sha256")
cat("\n=== build_fair_pulse_grid.R ===\n")

csv  <- file.path(FPG_DIR, paste0(FPG_STEM, ".csv"))
pv   <- utils::read.csv(file.path(FPG_DIR, paste0(FPG_STEM, "_provenance.csv")), stringsAsFactors = FALSE)
gt   <- utils::read.csv(file.path(FPG_DIR, paste0(FPG_STEM, "_gates.csv")), stringsAsFactors = FALSE)
stopifnot(nrow(pv) == 1L)
prov <- as.list(pv[1, ])

if (!identical(sha256(csv), prov$sha256)) stop(basename(csv), " does not match the sha256 its provenance records")
if (grepl("dirty", prov$commit, fixed = TRUE)) stop("the driver had uncommitted changes at run time (", prov$commit, ")")
if (!identical(prov$model, FPG_LABEL)) stop("model is '", prov$model, "', not '", FPG_LABEL, "'")
if (!identical(as.integer(prov$n_configs), FPG_N)) stop("n_configs is ", prov$n_configs)
if (!isTRUE(all.equal(as.numeric(prov$pulse_gtc), FPG_PULSE_GTC, tolerance = 0))) stop("pulse is ", prov$pulse_gtc, " GtC")
if (!grepl("uniform over the release year", prov$release, fixed = TRUE)) stop("release is '", prov$release, "'")
if (!grepl("airborne_emissions", prov$metric, fixed = TRUE)) stop("metric is '", prov$metric, "'")

d <- utils::read.csv(csv, stringsAsFactors = FALSE)
need <- c("scenario", "release_year", "year", "af_mean", "af_median", "af_p05", "af_p95",
          "d_co2_ppm_mean", "d_gmst_mean")
miss <- setdiff(need, names(d)); if (length(miss)) stop("missing columns: ", paste(miss, collapse = ", "))
d <- d[, need]
arms <- unique(d[, c("scenario", "release_year")])
markers <- strsplit(prov$markers, ";", fixed = TRUE)[[1]]
years   <- as.integer(strsplit(prov$release_years, ";", fixed = TRUE)[[1]])
if (nrow(arms) != length(markers) * length(years)) stop("the grid is not markers x release years")
# the gates: G1 once, a G2 per marker, a G3+G5 per arm
if (!any(gt$gate == "G1")) stop("no G1 (zero-pulse) row in the gates file")
if (!setequal(gt$marker[gt$gate == "G2"], markers)) stop("a marker lacks its G2 row")
if (sum(grepl("^G3\\+G5 ", gt$gate)) != nrow(arms)) stop("an arm lacks its G3+G5 row")
for (i in seq_len(nrow(arms))) {
  a <- d[d$scenario == arms$scenario[i] & d$release_year == arms$release_year[i], ]
  if (any(diff(a$year) != 1) || a$year[1] != arms$release_year[i]) stop("arm ", i, ": years not 1-yr from the release")
  if (any(a$af_p05 > a$af_mean + 1e-12 | a$af_mean > a$af_p95 + 1e-12)) stop("arm ", i, ": mean outside its band")
}
if (any(!is.finite(as.matrix(d[, -1])))) stop("non-finite values")

attr(d, "provenance") <- prov
attr(d, "gates") <- gt
attr(d, "source_sha256") <- sha256(csv)
saveRDS(d, FPG_OUT)
cat(sprintf("[1] %s: %d rows, %d arms (%s x %s); %s, %s configs, commit %s\n",
            basename(FPG_OUT), nrow(d), nrow(arms), paste(markers, collapse = "/"),
            paste(range(years), collapse = "-"), prov$model, prov$n_configs, prov$commit))
for (h in FPG_REPORT_H) {
  r <- d[d$year == d$release_year + h, ]
  cat(sprintf("    AF mean +%3d yr: %.3f-%.3f across the grid\n", h, min(r$af_mean), max(r$af_mean)))
}
over <- gt$note[grepl("^G3\\+G5 ", gt$gate)]
cat("    configs with AF > 1 at some later timebound, per arm (FaIR's r_A saturation; KEPT):\n")
cat(paste0("      ", gt$marker[grepl("^G3\\+G5 ", gt$gate)], " ", sub("^G3\\+G5 ", "", gt$gate[grepl("^G3\\+G5 ", gt$gate)]),
           ": ", sub(";.*", "", sub("configs with AF > 1 at some later timebound: ", "", over)), collapse = "\n"), "\n")
