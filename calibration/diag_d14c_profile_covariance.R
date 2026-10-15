# =====================================================================
# diag_d14c_profile_covariance.R -- THE VERTICAL CONTRAST IS THE OBSERVATION
# THE LEVEL ROWS THROW AWAY. (2026-09-06, after the profile-price frontier.)
#
# Three interior D14C levels (1500-2000, 2000-2627, 2627-bottom m) at ~13 permil
# each cannot distinguish an abyss filled from below (bottom YOUNGER than the
# layer above it -- the conduit's mid-depth minimum) from a column with a sharp
# K(z) and a deep mixed layer (monotone aging). But the three means are built
# from the SAME 5x10 deg columns at different depths, so their sampling errors
# are strongly correlated and the CONTRASTS (B - deep, A - B) are known far
# better than the levels. This measures the joint covariance of the three means
# by the block bootstrap the deep n_eff decision used, and reads each arm's
# contrast against it.
#
# Usage:  Rscript calibration/diag_d14c_profile_covariance.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)

PC_FILE  <- ccx_path("data-raw", "downloads", "glodap_c13c14_subset.csv")
PC_DLAT <- 5; PC_DLON <- 10; PC_DZ <- 250; PC_FLAG_OK <- 2
PC_BLOCKS <- c(30, 60); PC_NBOOT <- 4000
PC_OUT <- ccx_path("outputs", "diagnostics", "d14c_profile_covariance_20260906.rds")
set.seed(20260906)
tgm <- ccx_mid_d14c_target(); tgd <- ccx_deep_d14c_target()
slabs <- list(A = c(tgm$slabs$top[1], tgm$slabs$bot[1]), B = c(tgm$slabs$top[2], tgm$slabs$bot[2]),
              deep = c(tgd$layer[["top"]], 1e5))
d <- utils::read.csv(PC_FILE)
ok_all <- is.finite(d$c14) & d$c14 > -900 & is.finite(d$c14f) & d$c14f == PC_FLAG_OK
cells <- lapply(names(slabs), function(k) {
  z <- slabs[[k]]; ok <- ok_all & d$depth >= z[1] & (if (k == "deep") d$depth <= z[2] else d$depth < z[2])
  x <- d[ok, ]
  id <- paste(floor(x$lat / PC_DLAT), floor(x$lon / PC_DLON), floor(x$depth / PC_DZ))
  data.frame(slab = k, v = as.numeric(tapply(x$c14, id, mean)), lat = as.numeric(tapply(x$lat, id, mean)),
             lon = as.numeric(tapply(x$lon, id, mean)))
})
cell <- do.call(rbind, cells); cell$w <- cos(cell$lat * pi / 180)
means <- vapply(names(slabs), function(k) { c <- cell[cell$slab == k, ]; sum(c$w * c$v) / sum(c$w) }, 0)
cat(sprintf("observed levels: A %.1f  B %.1f  deep %.1f;  contrasts A-B %+.1f, B-deep %+.1f\n",
            means[["A"]], means[["B"]], means[["deep"]], means[["A"]] - means[["B"]], means[["B"]] - means[["deep"]]))
# joint block bootstrap: resample horizontal blocks, ALL depths of a block together
COV <- list()
for (Bk in PC_BLOCKS) {
  bid <- paste(floor(cell$lat / Bk), floor(cell$lon / (2 * Bk)))
  ub <- unique(bid); nb <- length(ub); idx <- split(seq_len(nrow(cell)), bid)
  m <- t(vapply(seq_len(PC_NBOOT), function(i) {
    k <- unlist(idx[sample.int(nb, nb, replace = TRUE)], use.names = FALSE); c <- cell[k, ]
    vapply(names(slabs), function(s) { cc <- c[c$slab == s, ]; sum(cc$w * cc$v) / sum(cc$w) }, 0)
  }, numeric(3)))
  COV[[as.character(Bk)]] <- stats::cov(m)
  se <- sqrt(diag(COV[[as.character(Bk)]])); R <- stats::cov2cor(COV[[as.character(Bk)]])
  cat(sprintf("\nblock %g deg (%d blocks): level se A %.2f  B %.2f  deep %.2f;  corr(A,B) %.2f  corr(B,deep) %.2f  corr(A,deep) %.2f\n",
              Bk, nb, se[1], se[2], se[3], R[1, 2], R[2, 3], R[1, 3]))
  seAB <- sqrt(COV[[as.character(Bk)]][1, 1] + COV[[as.character(Bk)]][2, 2] - 2 * COV[[as.character(Bk)]][1, 2])
  seBD <- sqrt(COV[[as.character(Bk)]][2, 2] + COV[[as.character(Bk)]][3, 3] - 2 * COV[[as.character(Bk)]][2, 3])
  cat(sprintf("  contrast se: A-B %.2f   B-deep %.2f   (the level rows' own se at n_eff 20: %.1f / %.1f / %.1f)\n",
              seAB, seBD, tgm$slabs$sd[1], tgm$slabs$sd[2], tgd$sd))
  COV[[paste0("se_", Bk)]] <- c(AB = seAB, BD = seBD)
}
# each arm's B - deep contrast, from today's logs (typed from the logs of this session; recomputable)
arms <- list("ent26 (column, kz 6356)" = c(-140.7, -156.1), "column obs-pinned kz 5267" = c(-157.1, -175.3),
             "HILDA attach, obs-pinned" = c(-169.9, -175.3), "bottom attach, obs-pinned kz 1747" = c(-187.3, -175.3),
             "K(z)+bottom conduit (09-06b)" = c(-195.8, -175.3), "frontier W10 (K(z)+deep ML, conduit off)" = c(-179.1, -197.9))
obsBD <- means[["B"]] - means[["deep"]]
cat(sprintf("\nB - deep contrast, observed %+.1f;  z at the 60-deg and 30-deg contrast se:\n", obsBD))
for (n in names(arms)) { c <- arms[[n]][1] - arms[[n]][2]
  cat(sprintf("  %-44s B %7.1f deep %7.1f  contrast %+6.1f   z %+6.2f (60) %+6.2f (30)\n", n, arms[[n]][1], arms[[n]][2], c,
              (c - obsBD) / COV$se_60[["BD"]], (c - obsBD) / COV$se_30[["BD"]])) }
cat("\n  ⚠ Arm values are the LS-column slab and bottom-box means from today's logs; the observed contrast\n")
cat("    is the same estimator on the same cells. A contrast row with THIS se is the observation that\n")
cat("    discriminates 'filled from below' from 'sharp K(z) + deep mixed layer'. Not yet in the objective.\n")
saveRDS(list(means = means, cov = COV, arms = arms), PC_OUT); cat(sprintf("  saved %s\n", PC_OUT))
