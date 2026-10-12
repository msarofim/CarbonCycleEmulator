# =====================================================================
# build_glodap_surface_alk_sal.R -- the model's SURFACE ALKALINITY and its
# REFERENCE SALINITY, measured from GLODAPv2.2023 with ONE recipe.
#
# WHY (citation rulings 2026-10-12, notes/citation_rulings_2026-10-12.md rows 3
# and 30). ALK_SURFACE (2300 umol/kg) and SALINITY_REF (34.7) were uncited
# working values. Marcus ruled both adopted from GLODAP, on the same layer and
# the same weighting:
#   row 3:  "Adopt 2303.4 (Recommended)"
#   row 30: "Compute from GLODAP, adopt (Recommended)"
# They enter the objective ONLY through the structure label
# hilda_csl3v0kaidgbemwtc (ruled 2026-10-12, "New label (a) (Recommended)");
# every registered mode keeps 2300 / 34.7.
#
# THE RECIPE is calibration/diag_alk_gradient.R's ak_bin() (the source of the
# 2303.38 the ledger quotes), restated here so a data product does not source a
# diagnostic:
#   * flag == 2 (GLODAP "acceptable") and the value > -900 (GLODAP's -9999 fill);
#   * 0 <= depth < 100 m. ⚠ `<`, the dg_bin() convention: the build scripts'
#     gd_binned() takes `<=`, and the bottles exactly at 100 m are in one and
#     not the other (~0.4 umol/kg on the ALK gradient; diag_alk_gradient.R);
#   * bin to 5 deg lat x 10 deg lon x 250 m cells, average within a cell;
#   * weight the CELLS by cos(mean cell latitude). The slab is one 250 m bin
#     deep, so this IS the volume weighting of the deep-target scripts.
#   * ALL LATITUDES. The LS-domain-only (|lat| < 57.14 deg) value is reported
#     beside it, NOT adopted: the ruling says "the same domain as ALK", and
#     ALK's 2303.4 is all-latitude.
# Each variable is binned over ITS OWN valid bottles, so the cell counts differ
# (ALK 829, salinity 913 at the 2026-10-12 measurement).
#
# GATES (stop, not warn): the ALK value must reproduce the ledger's 2303.38 and
# the salinity the 10-12 measurement's 34.760, each to the last printed digit.
# They are REPRODUCTION gates on a recipe already ruled -- if the master file or
# the recipe moves, the build stops and the ruling has to be re-read.
#
# SOURCE. GLODAPv2.2023 Merged Master File (bottle data), Lauvset et al. (2024)
# ESSD 16:2047-2072, doi:10.5194/essd-16-2047-2024; data doi:10.25921/z7hc-v261.
# Provenance row `glodap_v2_2023` in data-raw/downloads/MANIFEST.csv (the zip);
# the unzipped CSV's sha256 is stamped into the product below.
#
# RUNTIME ~1 min (one pass over the 894 MB master file).
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)

SA_MASTER   <- ccx_path("data-raw", "downloads", "GLODAPv2.2023_Merged_Master_File.csv")
SA_OUT      <- ccx_path("data", "obs_glodap_surface_alk_sal.rds")
SA_FLAG_OK  <- 2                 # GLODAP: 2 = acceptable measurement
SA_FILL_GT  <- -900              # GLODAP's fill value is -9999
SA_ZMIN     <- 0                 # m
SA_ZMAX     <- 100               # m, EXCLUSIVE (the dg_bin() convention)
SA_DLAT     <- 5                 # deg
SA_DLON     <- 10                # deg
SA_DZ       <- 250               # m
SA_LS_LAT   <- 57.14             # deg, the LS/HS boundary (obs_tr_box.rds's mask); reported only
# The reproduction gates: the ledger's value and the 10-12 measurement, at the
# precision each was quoted.
SA_GATE_ALK <- 2303.38           # umol/kg, notes/constants_citation_needs_2026-10-12.md:126
SA_GATE_SAL <- 34.760            # notes/citation_rulings_2026-10-12.md row 30
SA_GATE_TOL_ALK <- 0.005         # half a unit in the last quoted digit
SA_GATE_TOL_SAL <- 0.0005

cols <- c(lat = "G2latitude", lon = "G2longitude", depth = "G2depth",
          talk = "G2talk", talkf = "G2talkf", sal = "G2salinity", salf = "G2salinityf")
hdr <- strsplit(readLines(SA_MASTER, n = 1), ",")[[1]]
stopifnot(all(cols %in% hdr))
cat("reading", basename(SA_MASTER), "(one pass, ~1 min) ...\n")
d <- utils::read.csv(SA_MASTER, colClasses = ifelse(hdr %in% cols, "numeric", "NULL"))
names(d) <- names(cols)[match(names(d), cols)]
master_sha256 <- system2("shasum", c("-a", "256", shQuote(SA_MASTER)), stdout = TRUE)
master_sha256 <- strsplit(master_sha256, " ")[[1]][1]

#' cos-lat cell-weighted mean of one field over the surface slab
sa_bin <- function(val, flag, lat_max = Inf) {
  ok <- is.finite(d[[val]]) & d[[val]] > SA_FILL_GT &
        is.finite(d[[flag]]) & d[[flag]] == SA_FLAG_OK &
        d$depth >= SA_ZMIN & d$depth < SA_ZMAX & abs(d$lat) < lat_max
  x    <- d[ok, ]
  id   <- paste(floor(x$lat / SA_DLAT), floor(x$lon / SA_DLON), floor(x$depth / SA_DZ))
  cell <- tapply(x[[val]], id, mean)
  w    <- cos(tapply(x$lat, id, mean) * pi / 180)
  list(vw = sum(cell * w) / sum(w), n_bottles = sum(ok), n_cells = length(cell),
       raw = mean(x[[val]]), sd_cell = stats::sd(cell))
}

alk    <- sa_bin("talk", "talkf")
sal    <- sa_bin("sal",  "salf")
alk_ls <- sa_bin("talk", "talkf", SA_LS_LAT)
sal_ls <- sa_bin("sal",  "salf",  SA_LS_LAT)

cat(sprintf("\n%-22s %10s %9s %7s %10s\n", "", "cos-lat vw", "bottles", "cells", "raw mean"))
for (r in list(list("ALK (umol/kg), all", alk), list("ALK, |lat| < 57.14", alk_ls),
               list("salinity, all", sal), list("salinity, |lat| < 57.14", sal_ls)))
  cat(sprintf("%-22s %10.4f %9d %7d %10.4f\n", r[[1]], r[[2]]$vw, r[[2]]$n_bottles,
              r[[2]]$n_cells, r[[2]]$raw))

if (abs(alk$vw - SA_GATE_ALK) > SA_GATE_TOL_ALK)
  stop(sprintf("ALK reproduction gate: %.4f vs the ruled %.2f. The recipe or the master file moved; re-read the ruling.",
               alk$vw, SA_GATE_ALK))
if (abs(sal$vw - SA_GATE_SAL) > SA_GATE_TOL_SAL)
  stop(sprintf("salinity reproduction gate: %.5f vs the ruled %.3f. The recipe or the master file moved; re-read the ruling.",
               sal$vw, SA_GATE_SAL))

out <- list(
  alk_umolkg = alk$vw, salinity = sal$vw,
  # what the structure block reads: the values AT THE PRECISION THEY WERE RULED
  # (2303.4, 34.760), so a re-run that moves the fourth decimal does not move
  # the objective without a ruling.
  alk_ruled_umolkg = 2303.4, salinity_ruled = 34.760,
  detail = list(alk = alk, sal = sal, alk_ls_only = alk_ls, sal_ls_only = sal_ls),
  recipe = list(flag_ok = SA_FLAG_OK, depth_m = c(SA_ZMIN, SA_ZMAX), depth_upper = "exclusive (<)",
                bin = c(dlat = SA_DLAT, dlon = SA_DLON, dz = SA_DZ),
                weight = "cells weighted by cos(mean cell latitude); all latitudes",
                ls_lat_reported_only = SA_LS_LAT),
  source = paste("GLODAPv2.2023 Merged Master File; Lauvset et al. (2024) ESSD 16:2047-2072,",
                 "doi:10.5194/essd-16-2047-2024; data doi:10.25921/z7hc-v261"),
  master_file = basename(SA_MASTER), master_sha256 = master_sha256,
  ruling = "notes/citation_rulings_2026-10-12.md rows 3 + 30; label hilda_csl3v0kaidgbemwtc",
  script = "data-raw/build_glodap_surface_alk_sal.R", built = format(Sys.time(), "%Y-%m-%d %H:%M %Z"))
saveRDS(out, SA_OUT)
cat(sprintf("\nwritten: %s\n  ALK %.4f umol/kg (ruled 2303.4), salinity %.5f (ruled 34.760)\n  master sha256 %s\n",
            SA_OUT, alk$vw, sal$vw, master_sha256))
