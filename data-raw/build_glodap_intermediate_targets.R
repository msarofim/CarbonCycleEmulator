# =====================================================================
# build_glodap_intermediate_targets.R -- natural D14C in the INTERMEDIATE ocean
# from GLODAPv2.2023, as two observational rows for the likelihood.
#
# WHY (2026-09-06, Marcus: "the priority is to use observations and known
# physical laws to constrain the model's behavior"). The objective scored ONE
# interior D14C row, the bottom box (2627-3700 m), and 2026-09-04j measured that
# the model's worst ventilation error sits ABOVE it, at 1000-2500 m. Every
# structural arm of the September ocean arc was therefore compared to the
# intermediate GLODAP profile by a diagnostic and constrained by it in no fit.
# 2026-09-06 found that the pure column cannot flatten the deep profile at any
# kz and that the conduit arms can -- the discriminating observation was never
# in the objective. These rows put it there.
#
# THE TWO SLABS TILE THE BOMB-FREE INTERIOR WITH THE EXISTING DEEP ROW:
#     A  1500-2000 m,  B  2000-2627.2 m,  (deep row: 2627.2-3700 m)
# 1500 m is the arc's standing bomb-free floor (bomb addition <= 4.5 permil
# below it, calibration/diag_ventilation_profile.R); 2627.2 m is the deep row's
# top (data-raw/build_glodap_deep_targets.R, GD_MODEL_DEEP_TOP). Fixed DEPTH
# slabs, not model layers: the grid moves with h_ml, so the MODEL side is a
# thickness-weighted mean over whichever layers overlap the slab
# (R/likelihood.R, ccx_model_d14c_slabs()). Like for like at every h_ml.
#
# BINNING AND WEIGHTING: VERBATIM the deep build script's gd_binned() -- 5 deg
# lat x 10 deg lon x 250 m cells, cells weighted cos(lat), sd_w the weighted
# spread -- copied rather than sourced because that script runs its whole
# report on load. If the deep row's recipe ever changes, change this one in
# the same edit (the caption-sync bug class).
#
# SIGMA. The deep row uses sd_w / sqrt(n_eff) with n_eff = 20, MEASURED for the
# deep slab (calibration/diag_deep_d14c_neff.R). n_eff has NOT been measured
# for these slabs; the likelihood reuses LIK_D14C_DEEP_NEFF and says so. The
# correlation scale of intermediate water is if anything longer than the
# deep's (fewer, larger water masses), so 20 is not conservative here -- an
# owed measurement, flagged in the accessor.
#
# SOURCE. GLODAPv2.2023 Merged Master File, glodap.info, doi:10.25921/z7hc-v261;
# Lauvset et al. (2024), ESSD 16:2047, doi:10.5194/essd-16-2047-2024. Subset
# and access date in data-raw/downloads/MANIFEST.csv (pulled 2026-08-14).
#
# Usage:  Rscript data-raw/build_glodap_intermediate_targets.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)

GI_FILE  <- ccx_path("data-raw", "downloads", "glodap_c13c14_subset.csv")
# THE COLUMN DEPTH IS AN ARGUMENT (2026-10-12; OCEAN_DEPTH 3700 -> 3682.2 m under label
# hilda_csl3v0kaidgbemwtc, citation rulings row 5). Slab B ENDS WHERE THE DEEP ROW BEGINS
# (the 09-06 design: the three levels tile), so B's bottom follows the deep row's top:
# 2627.2 at 3700 (typed, kept, so the shipped product is reproduced) and ccx_ocean_grid(75)'s
# 2614.7 at 3682.2 -- build_glodap_deep_targets.R's rule, asserted equal to the deep product's
# stored layer top below. ⚠ B's STREAM NAME derives from its edges (d14c_mid_2000_2615 at
# 3682.2), so the B row is renamed under the new label.
#   (no argument) 3700 -> data/obs_glodap_intermediate.rds (NOT rebuilt; the record)
#   `3682.2`          -> data/obs_glodap_intermediate_3682.2m.rds
GI_DEPTH_LEGACY <- 3700
gi_args  <- commandArgs(trailingOnly = TRUE)
GI_DEPTH <- if (length(gi_args) < 1) GI_DEPTH_LEGACY else as.numeric(gi_args[1])
GI_DEEP_FILE <- ccx_glodap_file("obs_glodap_deep", GI_DEPTH)
GI_DEEP_TOP  <- readRDS(GI_DEEP_FILE)$model_layer[["top"]]   # m; = GD_MODEL_DEEP_TOP, the deep row's top
stopifnot(GI_DEPTH != GI_DEPTH_LEGACY || GI_DEEP_TOP == 2627.2)
GI_OUT <- if (length(gi_args) >= 2) gi_args[2] else ccx_glodap_file("obs_glodap_intermediate", GI_DEPTH)
GI_SLABS <- list(A = c(1500, 2000), B = c(2000, GI_DEEP_TOP))
GI_DLAT <- 5; GI_DLON <- 10; GI_DZ <- 250
GI_NATL <- list(lat = 40, lon = c(-80, 20))
GI_FLAG_OK <- 2

d <- utils::read.csv(GI_FILE)
cat(sprintf("\nGLODAPv2.2023 subset: %d bottles, %d-%d\n", nrow(d), min(d$year), max(d$year)))
ok14 <- is.finite(d$c14) & d$c14 > -900 & is.finite(d$c14f) & d$c14f == GI_FLAG_OK

# VERBATIM from build_glodap_deep_targets.R::gd_binned (see header)
gi_binned <- function(ok, val, zmin, zmax, drop_natl = FALSE) {
  k <- ok & d$depth >= zmin & d$depth < zmax
  if (drop_natl)
    k <- k & !(d$lat > GI_NATL$lat & d$lon >= GI_NATL$lon[1] & d$lon <= GI_NATL$lon[2])
  if (sum(k) < 20) return(NULL)
  x  <- d[k, ]
  bl <- floor(x$lat / GI_DLAT); bo <- floor(x$lon / GI_DLON); bz <- floor(x$depth / GI_DZ)
  id <- paste(bl, bo, bz)
  cell   <- tapply(x[[val]], id, mean)
  celllat<- tapply(x$lat,    id, mean)
  w      <- cos(celllat * pi / 180)
  list(n_bottles = sum(k), n_cells = length(cell),
       raw   = mean(x[[val]]),
       vw    = sum(cell * w) / sum(w),
       sd_cells = stats::sd(cell),
       sd_w  = sqrt(sum(w * (cell - sum(cell * w) / sum(w))^2) / sum(w)),
       p05   = as.numeric(stats::quantile(cell, 0.05)),
       p95   = as.numeric(stats::quantile(cell, 0.95)))
}

cat(sprintf("\n%-16s %8s %6s %9s %9s %7s %8s   %s\n", "slab", "bottles", "cells",
            "raw mean", "vol-wtd", "sd_w", "se(20)", "N Atlantic cut: vol-wtd"))
slabs <- lapply(names(GI_SLABS), function(nm) {
  z <- GI_SLABS[[nm]]
  r <- gi_binned(ok14, "c14", z[1], z[2])
  rn <- gi_binned(ok14, "c14", z[1], z[2], drop_natl = TRUE)
  cat(sprintf("%-16s %8d %6d %9.1f %9.1f %7.1f %8.2f   %.1f\n",
              sprintf("%s %.0f-%.0f m", nm, z[1], z[2]), r$n_bottles, r$n_cells,
              r$raw, r$vw, r$sd_w, r$sd_w / sqrt(20), rn$vw))
  list(name = nm, top = z[1], bot = z[2], all = r, no_natl = rn)
})
names(slabs) <- names(GI_SLABS)

# GATE: the slabs must be consistent with the deep row's recipe. Re-derive the
# deep row here with the SAME function and require it to reproduce the stored
# target; if the recipe has drifted, this file must not be written.
deep_here <- gi_binned(ok14, "c14", GI_DEEP_TOP, 1e5)
stored <- readRDS(GI_DEEP_FILE)$d14c$deep
cat(sprintf("\nrecipe check: deep row re-derived %.3f vs stored %.3f\n", deep_here$vw, stored$vw))
# The deep script uses depth <= zmax; this one uses depth < zmax so the slabs
# tile without double-counting a bottle exactly on a boundary. On the deep row
# (zmax = 1e5) that changes nothing.
if (abs(deep_here$vw - stored$vw) > 1e-6)
  stop("the intermediate recipe does not reproduce the deep row -- do not write")

out <- list(
  slabs = slabs,
  deep_top = GI_DEEP_TOP,
  source = paste("GLODAPv2.2023 Merged Master File, glodap.info, doi:10.25921/z7hc-v261;",
                 "Lauvset et al. 2024, ESSD 16:2047, doi:10.5194/essd-16-2047-2024"),
  accessed = "2026-08-14",          # the subset's pull date, MANIFEST.csv
  built = if (GI_DEPTH == GI_DEPTH_LEGACY) "2026-09-06" else format(Sys.Date()),
  binning = c(dlat = GI_DLAT, dlon = GI_DLON, dz = GI_DZ),
  neff_note = paste("n_eff NOT measured for these slabs; the likelihood reuses",
                    "LIK_D14C_DEEP_NEFF (20, measured for 2627-3700 m). Owed."))
# the column depth, stamped on every non-legacy product (absent = 3700, the shipped file, which is
# reproduced byte for byte -- so it cannot carry the field)
if (GI_DEPTH != GI_DEPTH_LEGACY) out$column_depth <- GI_DEPTH
saveRDS(out, GI_OUT)
cat(sprintf("\nwrote %s\n", GI_OUT))
