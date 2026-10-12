# =====================================================================
# build_glodap_profile_covariance.R -- the JOINT sampling covariance of the
# three interior GLODAPv2 D14C levels (2026-09-06; OBJECTIVE CHANGE #9,
# prereg_2026-09-07 sec.2). Promotes calibration/diag_d14c_profile_covariance.R
# to a build product so the likelihood can read it.
#
# WHY. The 1500-2000 m, 2000-2627 m and bottom-box means are built from the
# SAME 5x10-deg columns at different depths, so their sampling errors are
# correlated 0.97-0.99 and the vertical CONTRASTS are known 3-4x better than
# the levels (se(B - deep) 3.5-4.0 permil vs 13.5 on a level). Three
# independent rows discard that; one multivariate-normal row keeps it.
#
# RECIPE. The same cells as the deep and intermediate rows (5x10x250 m bins,
# cos-lat weights, flag 2, depth >= top and < bot; the deep slab is >= top).
# Joint block bootstrap: horizontal blocks of GP_BLOCKS degrees latitude by
# twice that in longitude, ALL depths of a block resampled together, GP_NBOOT
# draws, fixed seed. Both block sizes are stored; the likelihood picks one
# (LIK_D14C_PROFILE_BLOCK). GATE: the point means must reproduce the stored
# row targets to GP_TOL, or the file is not written -- the MVN row must score
# the SAME three numbers the independent rows score.
#
# Run from the repo root:  Rscript data-raw/build_glodap_profile_covariance.R [depth] [out]
#
# THE COLUMN DEPTH IS AN ARGUMENT (2026-10-12; OCEAN_DEPTH 3700 -> 3682.2 m under label
# hilda_csl3v0kaidgbemwtc). The product EMBEDS the three row targets, so it is built once per
# column depth from that depth's deep and intermediate products (R/likelihood.R's
# ccx_glodap_file()): no argument = 3700 -> data/obs_glodap_profile_cov.rds (NOT rebuilt; the
# record), `3682.2` -> data/obs_glodap_profile_cov_3682.2m.rds, stamped `column_depth`.
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)

GP_FILE  <- ccx_path("data-raw", "downloads", "glodap_c13c14_subset.csv")
GP_DLAT <- 5; GP_DLON <- 10; GP_DZ <- 250; GP_FLAG_OK <- 2
GP_BLOCKS <- c(30, 60); GP_NBOOT <- 4000; GP_SEED <- 20260906
GP_TOL <- 1e-3                                # permil; the point means vs the stored targets
GP_DEPTH_LEGACY <- 3700
gp_args  <- commandArgs(trailingOnly = TRUE)
GP_DEPTH <- if (length(gp_args) < 1) GP_DEPTH_LEGACY else as.numeric(gp_args[1])
GP_OUT   <- if (length(gp_args) >= 2) gp_args[2] else ccx_glodap_file("obs_glodap_profile_cov", GP_DEPTH)

tgm <- ccx_mid_d14c_target(depth = GP_DEPTH); tgd <- ccx_deep_d14c_target(depth = GP_DEPTH)
if (is.null(tgm) || is.null(tgd)) stop("the intermediate and deep build products must exist first")
if (tgm$masked || tgd$masked) stop("the rows are N-Atlantic-MASKED; this recipe is unmasked -- align first")
slabs <- list(A = c(tgm$slabs$top[1], tgm$slabs$bot[1]), B = c(tgm$slabs$top[2], tgm$slabs$bot[2]),
              deep = c(tgd$layer[["top"]], 1e5))
streams <- c(tgm$slabs$stream, "d14c_deep_ocean")
targets <- c(tgm$slabs$target, tgd$target)
d <- utils::read.csv(GP_FILE)
ok_all <- is.finite(d$c14) & d$c14 > -900 & is.finite(d$c14f) & d$c14f == GP_FLAG_OK
cells <- lapply(names(slabs), function(k) {
  z <- slabs[[k]]; ok <- ok_all & d$depth >= z[1] & (if (k == "deep") d$depth <= z[2] else d$depth < z[2])
  x <- d[ok, ]
  id <- paste(floor(x$lat / GP_DLAT), floor(x$lon / GP_DLON), floor(x$depth / GP_DZ))
  data.frame(slab = k, v = as.numeric(tapply(x$c14, id, mean)), lat = as.numeric(tapply(x$lat, id, mean)),
             lon = as.numeric(tapply(x$lon, id, mean)))
})
cell <- do.call(rbind, cells); cell$w <- cos(cell$lat * pi / 180)
wmean <- function(c) sum(c$w * c$v) / sum(c$w)
means <- vapply(names(slabs), function(k) wmean(cell[cell$slab == k, ]), 0)
cat(sprintf("point means A %.4f  B %.4f  deep %.4f\nstored     A %.4f  B %.4f  deep %.4f\n",
            means[1], means[2], means[3], targets[1], targets[2], targets[3]))
if (any(abs(means - targets) > GP_TOL))
  stop(sprintf("the recipe does not reproduce the row targets (max |diff| %.4f > %g) -- not written", max(abs(means - targets)), GP_TOL))
set.seed(GP_SEED)
COV <- list(); SE <- list()
for (Bk in GP_BLOCKS) {
  bid <- paste(floor(cell$lat / Bk), floor(cell$lon / (2 * Bk)))
  ub <- unique(bid); nb <- length(ub); idx <- split(seq_len(nrow(cell)), bid)
  m <- t(vapply(seq_len(GP_NBOOT), function(i) {
    k <- unlist(idx[sample.int(nb, nb, replace = TRUE)], use.names = FALSE); c <- cell[k, ]
    vapply(names(slabs), function(s) wmean(c[c$slab == s, ]), 0)
  }, numeric(3)))
  S <- stats::cov(m); dimnames(S) <- list(names(slabs), names(slabs))
  COV[[as.character(Bk)]] <- S
  se <- sqrt(diag(S)); R <- stats::cov2cor(S)
  SE[[as.character(Bk)]] <- c(A = se[[1]], B = se[[2]], deep = se[[3]],
                              AB = sqrt(S[1, 1] + S[2, 2] - 2 * S[1, 2]), BD = sqrt(S[2, 2] + S[3, 3] - 2 * S[2, 3]))
  cat(sprintf("block %g deg (%d blocks): level se %.2f / %.2f / %.2f (rows' own: %.2f / %.2f / %.2f); corr %.3f %.3f %.3f; contrast se A-B %.2f  B-deep %.2f\n",
              Bk, nb, se[1], se[2], se[3], tgm$slabs$sd[1], tgm$slabs$sd[2], tgd$sd, R[1, 2], R[2, 3], R[1, 3],
              SE[[as.character(Bk)]][["AB"]], SE[[as.character(Bk)]][["BD"]]))
}
out <- list(means = means, targets = targets, streams = streams, slab_names = tgm$slabs$name,
            cov = COV, se = SE, blocks = GP_BLOCKS, nboot = GP_NBOOT, seed = GP_SEED,
            slabs = slabs, binning = c(dlat = GP_DLAT, dlon = GP_DLON, dz = GP_DZ),
            contrast_obs = c(AB = means[[1]] - means[[2]], BD = means[[2]] - means[[3]]),
            source = tgm$source, built = format(Sys.Date()),
            note = paste("Objective change #9 (PENDING RULING 2026-09-06). Level variances here are the",
                         "bootstrap's, not sd_w/sqrt(n_eff); the two agree to ~20% at 60 deg."))
if (GP_DEPTH != GP_DEPTH_LEGACY) out$column_depth <- GP_DEPTH   # absent = 3700 (the shipped record)
saveRDS(out, GP_OUT); cat(sprintf("wrote %s\n", GP_OUT))
