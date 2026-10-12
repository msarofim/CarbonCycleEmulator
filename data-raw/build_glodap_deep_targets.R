# =====================================================================
# build_glodap_deep_targets.R -- deep-ocean D14C, d13C and DIC from GLODAPv2,
# as observational targets: a sourced central value, and the sigma question
# it turns out NOT to settle.
#
# WHY (review item 4, handoff 13i sec.A3). Two things in this repo were blocked
# on one missing dataset:
#
#  (a) THE kz DECISION. CCX_PARAM_TABLE bounds kz to [3830, 6200] to keep the
#      model's deep D14C inside "roughly -150 to -200 permil" -- a range that
#      appears ONCE in the repo, in DATA.md sec.5, WITH NO SOURCE. Project hard
#      rule 2 forbids an uncited value in code, and Marcus' chosen option
#      (delete the bracket, add a deep-D14C LIKELIHOOD term) is a STRONGER use
#      of the number than the bound it replaces. Bare deletion was measured and
#      rejected (kz -> 10,686, deep D14C -112.7 permil), so the bracket stayed.
#  (b) THE BIOLOGICAL PUMP's deep DIC and d13C targets (13h sec.4.3). The model's
#      interior DIC gradient is EXACTLY ZERO -- 1986.3 umol/kg uniform through
#      3700 m -- and its interior d13C gradient is exactly +1.560 permil uniform.
#      Neither has ever been scored against data.
#
# One pull serves both, which is why it is done before the refit rather than after.
#
# SOURCE. GLODAPv2.2023 Merged Master File (bottle data), glodap.info,
# doi:10.25921/z7hc-v261. Lauvset SK, et al. (2024), "The annual update
# GLODAPv2.2023", Earth Syst. Sci. Data 16:2047-2072,
# doi:10.5194/essd-16-2047-2024. Provenance in data-raw/downloads/MANIFEST.csv.
#
# THE MODEL'S "DEEP" IS A SPECIFIC LAYER, NOT A MOOD. ccx_ocean_grid(75) puts
# the bottom of an 11-box column at 2627.2-3700 m (midpoint 3163.6), so the
# comparable observation is a volume-weighted mean over 2627-3700 m, and that is
# the headline row. Other thresholds are reported so the choice is visible
# rather than buried.
#
# CORRECTION 2026-08-14, made the same day: the sentence here originally added
# that `diagnostics$d14c_deep_by_hemi` -- the quantity the kz bracket was
# bisected on -- IS that layer. IT IS NOT. That diagnostic takes
# tail(aux$idx[[h]]$oc, 3), the bottom THREE interior boxes = 1313.6-3700 m,
# which runs 13-20 permil enriched across the kz bracket (kz 5000: -170.1
# against the bottom box's -186.4). Scoring this file's 2627-3700 m target
# against it would have been a ~1.6 sigma layer mismatch, and it is where the
# handoff's "runaway at 6.1 sigma" came from -- like for like it is 5.3.
# `diagnostics$d14c_bottom_box` was added to R/spinup.R for this target; the
# 3-box diagnostics are unchanged because the bracket and every earlier result
# were derived from them.
#
# THREE METHODOLOGICAL CHOICES, none of them silently resolved:
#  1. WEIGHTING. GLODAP bottles are not spatially uniform (the Atlantic is
#     heavily over-sampled relative to its volume). A raw bottle mean is
#     therefore biased. Values are binned to 5 deg lat x 10 deg lon x 250 m
#     cells, averaged within a cell, and the CELLS are weighted by
#     cos(lat) x thickness. The unweighted bottle mean is printed alongside so
#     the size of the sampling bias is visible.
#  2. BOMB CONTAMINATION. Below ~2000 m bomb 14C is largely absent, but NOT in
#     the North Atlantic, where deep water forms. Reported with and without a
#     North Atlantic mask (lat > 40 N, lon -80..20).
#  3. SIGMA -- AND THIS ONE IS NOT RESOLVED HERE. 13i sec.A3 assumed GLODAP would
#     supply "a real spatial spread for the sigma". It supplies the spread; the
#     spread is NOT the sigma. A one-box model should be scored against the
#     VOLUME-WEIGHTED MEAN, whose uncertainty is the spread divided by an
#     EFFECTIVE sample size (deep water masses are basin-coherent, so n_eff is
#     of order tens, not the 3,592 cells) and then inflated for model
#     representation error. The candidates span 15x and they decide the kz
#     question outright -- see the block at the end. Marcus'.
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)

GD_FILE  <- ccx_path("data-raw", "downloads", "glodap_c13c14_subset.csv")
# THE COLUMN DEPTH IS AN ARGUMENT (2026-10-12, citation rulings row 5: OCEAN_DEPTH
# 3700 -> 3682.2 m, Charette & Smith 2010 Table 2, "Adopt 3682.2 (Recommended)").
# Two products, selected by the structure label (R/likelihood.R's
# ccx_glodap_deep_file()), never by editing this file:
#   (no argument) 3700, the legacy column -> data/obs_glodap_deep.rds, which every
#        registered mode was scored against. NOT rebuilt: the shipped file is the
#        record (a scratch `out` reproduces it; CHANGELOG 2026-10-12 ee).
#   `3682.2`  -> data/obs_glodap_deep_3682.2m.rds, the targets of label
#        hilda_csl3v0kaidgbemwtc.
# The bottom layer's TOP is ccx_ocean_grid(75)'s, rounded to 0.1 m: 2627.2 at
# 3700 (typed since 08-14 and kept typed, so the legacy product is reproduced
# byte for byte; the derivation is asserted to agree with it), 2614.7 at 3682.2.
# The optional second argument overrides the output path.
GD_DEPTH_LEGACY   <- 3700        # m, the uncited working value every registered mode ran on
GD_H_ML_GRID      <- 75          # m, the h_ml at which the target layer was defined (08-14)
gd_args           <- commandArgs(trailingOnly = TRUE)
GD_MODEL_DEPTH    <- if (length(gd_args) < 1) GD_DEPTH_LEGACY else as.numeric(gd_args[1])
stopifnot(is.finite(GD_MODEL_DEPTH), GD_MODEL_DEPTH > 3000, GD_MODEL_DEPTH < 4500)
gd_top_of <- function(D) { g <- ccx_ocean_grid(GD_H_ML_GRID, total_depth = D)
                           round(sum(g$dz[-length(g$dz)]), 1) }
stopifnot(gd_top_of(GD_DEPTH_LEGACY) == 2627.2)
GD_MODEL_DEEP_TOP <- if (GD_MODEL_DEPTH == GD_DEPTH_LEGACY) 2627.2 else gd_top_of(GD_MODEL_DEPTH)  # m
GD_OUT <- if (length(gd_args) >= 2) gd_args[2] else
  if (GD_MODEL_DEPTH == GD_DEPTH_LEGACY) ccx_path("data", "obs_glodap_deep.rds") else
  ccx_path("data", sprintf("obs_glodap_deep_%sm.rds", format(GD_MODEL_DEPTH)))
cat(sprintf("column depth %g m: the model's bottom layer is %.1f-%g m at h_ml %g -> %s\n",
            GD_MODEL_DEPTH, GD_MODEL_DEEP_TOP, GD_MODEL_DEPTH, GD_H_ML_GRID, GD_OUT))
GD_DEPTHS <- c(1500, 2000, GD_MODEL_DEEP_TOP, 3000)
GD_DLAT <- 5; GD_DLON <- 10; GD_DZ <- 250
GD_NATL <- list(lat = 40, lon = c(-80, 20))
GD_FLAG_OK <- 2                  # GLODAP: 2 = acceptable measurement

d <- utils::read.csv(GD_FILE)
cat(sprintf("\nGLODAPv2.2023: %d bottles carrying d13C or D14C, %d-%d\n",
            nrow(d), min(d$year), max(d$year)))

gd_clean <- function(val, flag) {
  v <- d[[val]]; f <- d[[flag]]
  ok <- is.finite(v) & v > -900 & is.finite(f) & f == GD_FLAG_OK
  ok
}

#' Volume-weighted mean over a depth band, binned first (choice 1 above)
gd_binned <- function(ok, val, zmin, zmax, drop_natl = FALSE) {
  k <- ok & d$depth >= zmin & d$depth <= zmax
  if (drop_natl)
    k <- k & !(d$lat > GD_NATL$lat & d$lon >= GD_NATL$lon[1] & d$lon <= GD_NATL$lon[2])
  if (sum(k) < 20) return(NULL)
  x  <- d[k, ]
  bl <- floor(x$lat / GD_DLAT); bo <- floor(x$lon / GD_DLON); bz <- floor(x$depth / GD_DZ)
  id <- paste(bl, bo, bz)
  cell   <- tapply(x[[val]], id, mean)
  celllat<- tapply(x$lat,    id, mean)
  w      <- cos(celllat * pi / 180)
  list(n_bottles = sum(k), n_cells = length(cell),
       raw   = mean(x[[val]]),
       vw    = sum(cell * w) / sum(w),
       sd_cells = stats::sd(cell),
       # spread of the volume-weighted distribution, which is the sigma a
       # one-box model should be scored with
       sd_w  = sqrt(sum(w * (cell - sum(cell * w) / sum(w))^2) / sum(w)),
       p05   = as.numeric(stats::quantile(cell, 0.05)),
       p95   = as.numeric(stats::quantile(cell, 0.95)))
}

ok14 <- gd_clean("c14", "c14f")
ok13 <- gd_clean("c13", "c13f")
okco <- gd_clean("tco2", "tco2f")
cat(sprintf("usable (flag == %d): D14C %d, d13C %d, TCO2 %d\n",
            GD_FLAG_OK, sum(ok14), sum(ok13), sum(okco)))

report <- function(lab, ok, val, unit) {
  cat(sprintf("\n=== %s (%s) ===\n", lab, unit))
  cat(sprintf("%-26s %8s %7s %9s %9s %8s %16s\n",
              "band", "bottles", "cells", "raw mean", "vol-wtd", "sd", "5-95 % of cells"))
  for (z in GD_DEPTHS) {
    r <- gd_binned(ok, val, z, 1e5)
    if (is.null(r)) next
    tag <- if (isTRUE(all.equal(z, GD_MODEL_DEEP_TOP)))
      sprintf("%.0f-%.0f m  <- MODEL LAYER", z, GD_MODEL_DEPTH) else sprintf("> %.0f m", z)
    cat(sprintf("%-26s %8d %7d %9.1f %9.1f %8.1f %7.1f to %6.1f\n",
                tag, r$n_bottles, r$n_cells, r$raw, r$vw, r$sd_w, r$p05, r$p95))
  }
  r <- gd_binned(ok, val, GD_MODEL_DEEP_TOP, 1e5, drop_natl = TRUE)
  if (!is.null(r))
    cat(sprintf("%-26s %8d %7d %9.1f %9.1f %8.1f %7.1f to %6.1f\n",
                "  same, N Atlantic cut", r$n_bottles, r$n_cells, r$raw, r$vw,
                r$sd_w, r$p05, r$p95))
  # surface, for the gradient
  s <- gd_binned(ok, val, 0, 100)
  if (!is.null(s))
    cat(sprintf("%-26s %8d %7d %9.1f %9.1f %8.1f %7.1f to %6.1f\n",
                "0-100 m (surface)", s$n_bottles, s$n_cells, s$raw, s$vw,
                s$sd_w, s$p05, s$p95))
  invisible(list(deep = gd_binned(ok, val, GD_MODEL_DEEP_TOP, 1e5),
                 deep_no_natl = gd_binned(ok, val, GD_MODEL_DEEP_TOP, 1e5, TRUE),
                 surf = s))
}

r14 <- report("DEEP D14C -- the kz target", ok14, "c14", "permil")
r13 <- report("DEEP d13C -- a pump target", ok13, "c13", "permil")
rco <- report("DEEP DIC (TCO2) -- a pump target", okco, "tco2", "umol/kg")

cat(sprintf("\n\n=== WHAT THIS SETTLES ===\n"))
cat(sprintf("[a] the kz bracket's uncited \"roughly -150 to -200 permil\" (DATA.md sec.5):\n"))
cat(sprintf("    GLODAPv2.2023, model layer %.0f-%.0f m, volume-weighted: %+.1f +/- %.1f permil\n",
            GD_MODEL_DEEP_TOP, GD_MODEL_DEPTH, r14$deep$vw, r14$deep$sd_w))
cat(sprintf("    N-Atlantic cut: %+.1f +/- %.1f. Measurement error is 2-4 permil, i.e.\n",
            r14$deep_no_natl$vw, r14$deep_no_natl$sd_w))
cat(sprintf("    the SPATIAL SPREAD is ~%.0fx the measurement error -- but it is NOT the\n",
            r14$deep$sd_w / 3))
cat("    sigma; see the sigma block below, which is the real decision.\n")
cat(sprintf("[b] the model's ZERO interior DIC gradient, against observations:\n"))
cat(sprintf("    surface (0-100 m) %.1f, deep %.1f umol/kg -> observed gradient %.1f\n",
            rco$surf$vw, rco$deep$vw, rco$deep$vw - rco$surf$vw))
cat(sprintf("    the model has 1986.3 umol/kg UNIFORM, i.e. a gradient of exactly 0.\n"))
cat(sprintf("[c] the model's interior d13C gradient of +1.560 permil UNIFORM:\n"))
cat(sprintf("    surface %.3f, deep %.3f -> observed gradient %.3f permil\n",
            r13$surf$vw, r13$deep$vw, r13$deep$vw - r13$surf$vw))

# ---------------------------------------------------------------------
# THE SIGMA IS THE WHOLE DECISION, and it is NOT settled by this pull.
#
# 13i sec.A3 said GLODAPv2 "gives both a central value and a real spatial spread
# for the sigma". It gives the central value. The spread is NOT automatically
# the sigma, and treating it as one would quietly make the new term useless.
#
# The model has ONE deep box, so the observable is the VOLUME-WEIGHTED MEAN.
# Three candidate sigmas, spanning ~15x:
#   * measurement error, 2-4 permil          -- a LOWER bound; ignores everything
#   * standard error of the weighted mean    -- depends on the EFFECTIVE sample
#     size, which is NOT the 3,592 cells: deep water masses are coherent over
#     ocean-basin scales, so n_eff is of order the number of independent deep
#     water masses (NADW, AABW, NPDW, ...), i.e. tens
#   * the full spatial spread, 45.9 permil   -- an UPPER bound; it asserts that a
#     one-box model should be scored as though it were sampling one bottle
#
# WHY IT DECIDES THE kz QUESTION. Bare deletion of the bracket was measured and
# rejected because kz ran to 10,686 and the deep ocean went to -112.7 permil.
# Whether a likelihood term prevents that depends entirely on sigma:
GD_KZ_RUNAWAY_D14C <- -112.7     # 13i sec.3.4 item 4, measured on this model
cat(sprintf("\n\n=== THE SIGMA CHOICE DECIDES WHETHER THE kz TERM WORKS ===\n"))
cat(sprintf("target %.1f permil; the kz -> 10,686 runaway sits at %.1f, a gap of %.1f\n\n",
            r14$deep$vw, GD_KZ_RUNAWAY_D14C, r14$deep$vw - GD_KZ_RUNAWAY_D14C))
cat(sprintf("%-46s %9s %10s %s\n", "candidate sigma", "permil", "runaway", "verdict"))
for (cs in list(list("measurement error alone", 3),
                list("SE of the weighted mean, n_eff = 100", r14$deep$sd_w / 10),
                list("SE of the weighted mean, n_eff = 20", r14$deep$sd_w / sqrt(20)),
                list("SE of the weighted mean, n_eff = 5", r14$deep$sd_w / sqrt(5)),
                list("full spatial spread (n_eff = 1)", r14$deep$sd_w))) {
  z <- abs(r14$deep$vw - GD_KZ_RUNAWAY_D14C) / cs[[2]]
  cat(sprintf("%-46s %9.1f %8.1f sd  %s\n", cs[[1]], cs[[2]], z,
              if (z > 3) "HOLDS kz" else if (z > 2) "marginal" else "DOES NOT HOLD kz"))
}
cat("\nSo the pull does NOT by itself unblock the kz decision: it supplies a sourced\n")
cat("central value (which the uncited [-150, -200] bracket bracketed correctly --\n")
cat("its midpoint -175 is within 0.3 permil of the measurement) but the sigma is a\n")
cat("METHODOLOGICAL CHOICE about representation error, and it is Marcus'.\n")
cat("NOTE the incumbent bracket is effectively a HARD +/-25 permil box, TIGHTER than\n")
cat("anything but the most aggressive n_eff here -- deleting it for an honest term\n")
cat("would LOOSEN the constraint, not tighten it.\n")

# ---------------------------------------------------------------------
# THE GRADIENT TARGETS (added 2026-08-16). Marcus took the DIC and d13C
# gradient terms into the objective; these are the three numbers each needs.
#
# LAYERS. FIXED DEPTHS -- the `surf` and `deep` bands above -- NOT the model's
# own boxes, decided by Marcus on 2026-08-16 after both options were priced in
# calibration/diag_gradient_target_and_neff.R part 2b. A model-anchored target
# is a function of h_ml and rewards a LARGE h_ml (penalty falls 81 -> 53
# log-units across h_ml 50 -> 220), pushing against the very clause the pump
# exists to fix; freezing at the h_ml = 75 grid instead overstates the miss by
# 1.61 sigma at the fitted h_ml = 184, biasing IN FAVOUR of the pump. Fixed
# depths are neutral on both counts AND are like-for-like to 0.09 sigma at
# h_ml = 100, the value the pump delivers -- which is why the likelihood carries
# a GATE on h_ml (LIK_OCEAN_GRAD_HML_OK) rather than a silent assumption.
#
# SIGMA. Var(Delta) = Var(D) + Var(S) - 2 Cov(D,S), and the covariance is NOT
# negligible and NOT the same sign for every field: DIC anticorrelates at ~-0.6
# (basins trade the two ends of the gradient -- surface DIC peaks where the deep
# water is youngest), which INFLATES sigma_Delta ~25 %; d13C cancels weakly.
# A block bootstrap on the CONTRAST carries that automatically, which is why the
# sigma is measured here rather than composed from two per-layer n_eff.
# Blocks must EXCEED the decorrelation scale (~9,000 km) to be valid, so only
# 30 and 60 degrees are reported and the CONSERVATIVE (60 deg) one is shipped.
#
# EPOCH. The observed surface is anthropogenically contaminated, and Marcus'
# resolution (2026-08-16) is to score the model's TRANSIENT gradient at the
# observations' own epoch rather than correct the surface for C_ant and Suess --
# the GLODAPv2.2023 bottle file carries no C_ant column, so correcting DIC would
# have meant a new download or a dC* build. The epoch is therefore part of the
# target and is measured here, per field AND per layer, because the two layers
# are not sampled at the same mean time.
GD_GRAD_BLOCKS <- c(30, 60)      # degrees latitude; > the ~9,000 km decorrelation scale
GD_GRAD_NBOOT  <- 4000
GD_GRAD_SEED   <- 20260816       # stated, so this build reproduces

#' cos(lat)-weighted mean sampling year of the cells in a band
gd_epoch <- function(ok, zmin, zmax) {
  k <- ok & d$depth >= zmin & d$depth <= zmax
  x <- d[k, ]
  id <- paste(floor(x$lat / GD_DLAT), floor(x$lon / GD_DLON), floor(x$depth / GD_DZ))
  yc <- tapply(x$year, id, mean)
  w  <- cos(tapply(x$lat, id, mean) * pi / 180)
  sum(yc * w) / sum(w)
}

#' Block bootstrap on the CONTRAST deep - surf. Blocks are HORIZONTAL and each
#' carries both layers' cells, so a resampled block moves them together -- that
#' is what makes the covariance ride along instead of being assumed.
gd_grad_boot <- function(ok, val) {
  cells <- function(zmin, zmax) {
    k <- ok & d$depth >= zmin & d$depth <= zmax
    x <- d[k, ]
    id <- paste(floor(x$lat / GD_DLAT), floor(x$lon / GD_DLON), floor(x$depth / GD_DZ))
    data.frame(v = as.numeric(tapply(x[[val]], id, mean)),
               lat = as.numeric(tapply(x$lat, id, mean)),
               lon = as.numeric(tapply(x$lon, id, mean)))
  }
  s <- cells(0, 100); b <- cells(GD_MODEL_DEEP_TOP, 1e5)
  s$w <- cos(s$lat * pi / 180); b$w <- cos(b$lat * pi / 180)
  set.seed(GD_GRAD_SEED)
  vapply(GD_GRAD_BLOCKS, function(B) {
    bs <- paste(floor(s$lat / B), floor(s$lon / (2 * B)))
    bd <- paste(floor(b$lat / B), floor(b$lon / (2 * B)))
    ub <- union(unique(bs), unique(bd)); nb <- length(ub)
    is_ <- split(seq_len(nrow(s)), factor(bs, levels = ub))
    id_ <- split(seq_len(nrow(b)), factor(bd, levels = ub))
    dr <- vapply(seq_len(GD_GRAD_NBOOT), function(i) {
      k  <- sample.int(nb, nb, replace = TRUE)
      ks <- unlist(is_[k], use.names = FALSE); kd <- unlist(id_[k], use.names = FALSE)
      if (!length(ks) || !length(kd)) return(NA_real_)
      sum(b$w[kd] * b$v[kd]) / sum(b$w[kd]) - sum(s$w[ks] * s$v[ks]) / sum(s$w[ks])
    }, numeric(1))
    stats::sd(dr[is.finite(dr)])
  }, numeric(1))
}

gd_gradient <- function(ok, val, r) {
  se <- gd_grad_boot(ok, val)
  names(se) <- paste0("blk", GD_GRAD_BLOCKS)
  list(target = r$deep$vw - r$surf$vw,
       # CONSERVATIVE of the valid blocks. A gradient term that is too tight is
       # the failure mode that hijacks a posterior; too loose merely wastes data.
       sd = max(se), sd_by_block = se,
       epoch_surf = gd_epoch(ok, 0, 100),
       epoch_deep = gd_epoch(ok, GD_MODEL_DEEP_TOP, 1e5),
       layer_surf = c(0, 100), layer_deep = c(GD_MODEL_DEEP_TOP, 1e5),
       nboot = GD_GRAD_NBOOT, blocks = GD_GRAD_BLOCKS, seed = GD_GRAD_SEED)
}

grad <- list(tco2 = gd_gradient(okco, "tco2", rco),
             d13c = gd_gradient(ok13, "c13",  r13),
             d14c = gd_gradient(ok14, "c14",  r14))   # D14C: reported, NOT a term
cat("\n\n=== GRADIENT TARGETS (fixed depths; Marcus 2026-08-16) ===\n")
cat(sprintf("%-8s %12s %10s %12s %12s %12s\n", "field", "target", "sd (60deg)",
            "sd (30deg)", "epoch surf", "epoch deep"))
for (nm in names(grad)) {
  gg <- grad[[nm]]
  cat(sprintf("%-8s %12.4f %10.4f %12.4f %12.1f %12.1f%s\n", nm, gg$target, gg$sd,
              gg$sd_by_block[["blk30"]], gg$epoch_surf, gg$epoch_deep,
              if (nm == "d14c") "   <- reported only, no term" else ""))
}

# ---------------------------------------------------------------------
# THE ALKALINITY GRADIENT (added 2026-08-16b). Marcus: make it a fourth
# likelihood term. `G2talk` was never extracted before because nothing used it;
# calibration/diag_alk_gradient.R showed it sizes the carbonate limb directly.
#
# IT COMES FROM A DIFFERENT BOTTLE POPULATION AND THAT IS NOT FREE. The subset
# above is "bottles carrying d13C or D14C" -- a small, isotope-cruise-biased
# sample. Alkalinity is measured on far more bottles. Using the bigger sample
# gives a better sigma; mixing the two populations to form the RATIO
# (ALK gradient / DIC gradient = the carbonate share) compares two different
# samples of the ocean. So BOTH are measured here and the DIC gradient is
# recomputed on the ALK population, which is what makes the ratio commensurable.
# Nothing above this line is touched: `grad` is already built, and gd_grad_boot()
# re-seeds on every call, so the pre-existing targets are bit-identical.
GD_MASTER      <- ccx_path("data-raw", "downloads",
                           "GLODAPv2.2023_Merged_Master_File.csv")
GD_TALK_SUBSET <- ccx_path("data-raw", "downloads", "glodap_dic_talk_subset.csv")

if (!file.exists(GD_TALK_SUBSET)) {
  cat("\nextracting G2talk + G2tco2 from the master file (one pass, ~1 min)...\n")
  keep <- c(G2year = "year", G2latitude = "lat", G2longitude = "lon",
            G2depth = "depth", G2tco2 = "tco2", G2tco2f = "tco2f",
            G2talk = "talk", G2talkf = "talkf")
  hdr  <- strsplit(readLines(GD_MASTER, n = 1), ",")[[1]]
  stopifnot(all(names(keep) %in% hdr))
  dt <- utils::read.csv(GD_MASTER,
                        colClasses = ifelse(hdr %in% names(keep), "numeric", "NULL"))
  names(dt) <- keep[names(dt)]
  dt <- dt[is.finite(dt$talk) & dt$talk > -900 & dt$talkf == GD_FLAG_OK, ]
  utils::write.csv(dt, GD_TALK_SUBSET, row.names = FALSE)
  cat(sprintf("written: %s (%d bottles with usable talk)\n", GD_TALK_SUBSET, nrow(dt)))
}
dt <- utils::read.csv(GD_TALK_SUBSET)

# The gradient machinery above closes over `d`; point it at the ALK population
# for these two calls and put it back. Explicit and reversed immediately, rather
# than a second copy of gd_grad_boot()/gd_epoch() that could drift from the first.
d_isotope <- d
d <- dt
ok_talk <- is.finite(d$talk) & d$talk > -900 & is.finite(d$talkf) & d$talkf == GD_FLAG_OK
ok_dict <- is.finite(d$tco2) & d$tco2 > -900 & is.finite(d$tco2f) & d$tco2f == GD_FLAG_OK
r_talk <- list(surf = gd_binned(ok_talk, "talk", 0, 100),
               deep = gd_binned(ok_talk, "talk", GD_MODEL_DEEP_TOP, 1e5))
r_dict <- list(surf = gd_binned(ok_dict, "tco2", 0, 100),
               deep = gd_binned(ok_dict, "tco2", GD_MODEL_DEEP_TOP, 1e5))
grad_talk    <- gd_gradient(ok_talk, "talk", r_talk)
grad_dic_alk <- gd_gradient(ok_dict, "tco2", r_dict)
d <- d_isotope

cat("\n\n=== ALKALINITY GRADIENT (fourth term; Marcus 2026-08-16b) ===\n")
cat(sprintf("%-30s %12s %10s %12s %10s\n", "quantity", "target", "sd (60deg)",
            "sd (30deg)", "cells d/s"))
cat(sprintf("%-30s %12.4f %10.4f %12.4f %6d/%-4d\n", "ALK gradient (ALK population)",
            grad_talk$target, grad_talk$sd, grad_talk$sd_by_block[["blk30"]],
            r_talk$deep$n_cells, r_talk$surf$n_cells))
cat(sprintf("%-30s %12.4f %10.4f %12.4f %6d/%-4d\n", "DIC gradient (ALK population)",
            grad_dic_alk$target, grad_dic_alk$sd, grad_dic_alk$sd_by_block[["blk30"]],
            r_dict$deep$n_cells, r_dict$surf$n_cells))
cat(sprintf("%-30s %12.4f %10.4f %12.4f %6d/%-4d\n", "DIC gradient (SHIPPED, isotope pop)",
            grad$tco2$target, grad$tco2$sd, grad$tco2$sd_by_block[["blk30"]],
            rco$deep$n_cells, rco$surf$n_cells))
cat(sprintf("\nPOPULATION CHECK: the DIC gradient moves %+.2f umol/kg (%.2f sigma of the\n",
            grad_dic_alk$target - grad$tco2$target,
            (grad_dic_alk$target - grad$tco2$target) / grad$tco2$sd))
cat("shipped sigma) between the isotope population and the ALK population. The\n")
cat("SHIPPED DIC target is NOT changed -- it is the one the objective already\n")
cat("carries -- but the carbonate share must be formed from the commensurable\n")
cat("pair, and calibration/diag_alk_gradient.R part 2 mixed the two populations.\n")
# ALK bookkeeping: d(ALK) = 2 C_carb - (N:C) C_org, C_carb + C_org = D.
GD_ALK_PER_CARB <- 2.0
GD_NC_RATIO     <- 16 / 117       # Anderson-Sarmiento-type N:C, a WORKING value
share <- function(dA, D) (dA + GD_NC_RATIO * D) / ((GD_ALK_PER_CARB + GD_NC_RATIO) * D)
cat(sprintf("\ncarbonate share, MIXED populations (as first reported): %.0f %%\n",
            100 * share(grad_talk$target, grad$tco2$target)))
cat(sprintf("carbonate share, COMMENSURABLE (both on the ALK pop):   %.0f %%\n",
            100 * share(grad_talk$target, grad_dic_alk$target)))

grad$talk <- grad_talk
grad$tco2_alkpop <- grad_dic_alk    # reported for the ratio; NOT a term

# ---------------------------------------------------------------------
# THE OBSERVED DIC PROFILE, ON FIXED DEPTH BINS (added 2026-08-16c, task 9).
# The pump's export field is SOLVED as the source that holds this profile as a
# steady state of the model's own diffusion operator (calibration/pump_shim.R's
# dg_export_field). The shim re-bins raw bottles into the MODEL's layers on every
# call, which is fine for a 15-minute diagnostic and impossible inside a
# likelihood evaluation. So the profile is built ONCE here, on GRID-INDEPENDENT
# fixed depth bins, and R/model.R integrates it onto whatever layers a parameter
# draw asks for.
#
# WHY FIXED BINS AND NOT THE MODEL'S LAYERS: the model's layers are a function of
# h_ml, which is FITTED. A build product that depended on a fitted parameter
# would be the same hazard the gradient TARGET has (see the h_ml note above) --
# except here it would also be uncacheable.
#
# NORMALISED TO ITS OWN SURFACE, so it carries SHAPE only; the magnitude comes
# from `pump_grad` at runtime. That keeps the one number a refit might touch out
# of the build product entirely.
GD_PROF_DZ <- 250                          # m, the binning already used above
gd_profile <- function(ok, val) {
  # 100 m is kept as a bin EDGE so the target's 0-100 m surface band is an exact
  # union of bins and the mixed layer never straddles one. The last bin is
  # CLOSED AT THE MODEL'S FLOOR (3500-3700 m), because a profile that stopped at
  # 3500 would leave the bottom box's top 200 m undefined -- and the bottom box
  # is exactly the layer the gradient target scores.
  #
  # THE TOP 500 m IS BINNED AT 50 m AND THAT IS NOT COSMETIC. The TOTAL export
  # the pump needs is the diffusive flux across the TOPMOST interface alone (the
  # sum telescopes), so it is set entirely by the gradient between the mixed
  # layer and the FIRST interior box -- which is ~66 m thick at h_ml = 100. At
  # 250 m bins that box and the one below it both read the SAME 100-250 m mean,
  # which overstates the near-surface gradient and inflated the required export
  # by 28 % against calibration/pump_shim.R's direct binning
  # (calibration/diag_pump_port_parity.R). The delivered GRADIENT was unaffected,
  # which is exactly why this was worth catching: the row the likelihood scores
  # looked perfect while the pump's physical plausibility check did not.
  zb <- sort(unique(c(seq(0, 300, by = 25), seq(300, 500, by = 50), 100,
                      seq(500, GD_MODEL_DEPTH, by = GD_PROF_DZ), GD_MODEL_DEPTH)))
  do.call(rbind, lapply(seq_len(length(zb) - 1), function(k) {
    r <- gd_binned(ok, val, zb[k], zb[k + 1])
    data.frame(top = zb[k], bot = zb[k + 1],
               n_cells = if (is.null(r)) 0L else r$n_cells,
               vw = if (is.null(r)) NA_real_ else r$vw)
  }))
}
prof <- gd_profile(okco, "tco2")
# The deepest bins can be thin on cells; carry the last finite value down rather
# than emit NA into a field the model will integrate. Reported, not silent.
if (anyNA(prof$vw)) {
  cat(sprintf("\nNOTE: %d of %d profile bins have no usable cells; filled from above.\n",
              sum(is.na(prof$vw)), nrow(prof)))
  for (i in seq_len(nrow(prof))) if (is.na(prof$vw[i]) && i > 1) prof$vw[i] <- prof$vw[i - 1]
}
prof$shape <- (prof$vw - prof$vw[1]) / (prof$vw[nrow(prof)] - prof$vw[1])
cat("\n\n=== OBSERVED DIC PROFILE (pump export shape; task 9) ===\n")
cat(sprintf("%-14s %8s %10s %8s\n", "bin m", "cells", "DIC", "shape"))
for (i in seq_len(nrow(prof)))
  cat(sprintf("%-14s %8d %10.1f %8.4f\n",
              sprintf("%.0f-%.0f", prof$top[i], prof$bot[i]),
              prof$n_cells[i], prof$vw[i], prof$shape[i]))
cat(sprintf("\nsurface-to-bottom span: %+.2f umol/kg (the gradient target is %+.2f on the\n",
            prof$vw[nrow(prof)] - prof$vw[1], grad$tco2$target))
cat(sprintf("SAME surface band but a >%.1f m deep band, so the two differ by the deep\n", GD_MODEL_DEEP_TOP))
cat("band's extra thickness. The profile carries SHAPE ONLY -- it is normalised --\n")
cat("so that difference cannot leak into the pump's magnitude.\n")

out <- list(
  gradient = grad,
  dic_profile = prof,        # pump export shape (task 9); SHAPE only, normalised
  sigma_candidates = c(meas = 3, se_neff100 = r14$deep$sd_w / 10,
                       se_neff20 = r14$deep$sd_w / sqrt(20),
                       se_neff5 = r14$deep$sd_w / sqrt(5),
                       spread = r14$deep$sd_w),
  kz_runaway_d14c = GD_KZ_RUNAWAY_D14C,
  source = paste("GLODAPv2.2023 Merged Master File, glodap.info, doi:10.25921/z7hc-v261;",
                 "Lauvset et al. 2024, ESSD 16:2047, doi:10.5194/essd-16-2047-2024"),
  accessed = "2026-08-14",
  model_layer = c(top = GD_MODEL_DEEP_TOP, bottom = GD_MODEL_DEPTH),
  binning = c(dlat = GD_DLAT, dlon = GD_DLON, dz = GD_DZ),
  d14c = r14, d13c = r13, tco2 = rco)
saveRDS(out, GD_OUT)
cat(sprintf("\nsaved %s\n", GD_OUT))
