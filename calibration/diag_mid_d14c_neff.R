# =====================================================================
# diag_mid_d14c_neff.R -- MEASURE the intermediate slabs' effective sample
# size instead of reusing the deep slab's (prereg 2026-09-06c sec.6, I14).
#
# The two rows added on 2026-09-06 (objective change #8) carry sigma =
# sd_w / sqrt(n_eff) with n_eff = LIK_D14C_MID_NEFF = 20, REUSED from the deep
# slab where diag_deep_d14c_neff.R measured it. The conditional optimum then
# showed the rows' WEIGHT is what decides whether a fit keeps the structure,
# so the reuse is now load-bearing and must be measured.
#
# METHOD: the deep script's estimators, applied to each slab's own cells --
# same binning (5 x 10 deg x 250 m, cos-lat weights), same correlogram bins,
# same block sizes, same seed policy. The deep slab is re-run FIRST as a gate:
# its admissible set (6.4 / 11.9 / 26.0 / 110.1, median 18.9) must reproduce
# or nothing below is the same estimator. The admissible set is the deep
# script's: correlogram floored at 0, block bootstrap 60 and 30 deg, empirical
# correlogram; Kish and the 10/20 deg blocks are printed and excluded for the
# deep script's stated reasons (they break correlation inside blocks).
#
# Usage:  Rscript calibration/diag_mid_d14c_neff.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)

NM_FILE  <- ccx_path("data-raw", "downloads", "glodap_c13c14_subset.csv")
NM_DLAT <- 5; NM_DLON <- 10; NM_DZ <- 250; NM_FLAG_OK <- 2
NM_DBINS <- c(0, 500, 1000, 1500, 2000, 3000, 4000, 5000, 6000, 8000, 10000, 12000, 15000, 20100)
NM_BLOCKS <- c(10, 20, 30, 60); NM_NBOOT <- 4000; NM_R_EARTH <- 6371
NM_ADMISSIBLE_BLOCKS <- c(30, 60)
NM_DEEP_ADMISSIBLE <- c(6.4, 11.9, 26.0, 110.1)   # the deep script's recorded set, the GATE
NM_GATE_TOL <- 0.15                                # relative, per member (bootstrap noise)
NM_IN_USE <- LIK_D14C_MID_NEFF
NM_OUT <- ccx_path("outputs", "diagnostics", "mid_d14c_neff_20260906.rds")
set.seed(20260906)

tgm <- ccx_mid_d14c_target(); tgd <- ccx_deep_d14c_target()
slabs <- list(deep = c(tgd$layer[["top"]], 1e5),
              A = c(tgm$slabs$top[1], tgm$slabs$bot[1]),
              B = c(tgm$slabs$top[2], tgm$slabs$bot[2]))
d <- utils::read.csv(NM_FILE)
ok_all <- is.finite(d$c14) & d$c14 > -900 & is.finite(d$c14f) & d$c14f == NM_FLAG_OK

neff_of <- function(zmin, zmax, lbl, closed_top = FALSE) {
  ok <- ok_all & d$depth >= zmin & (if (closed_top) d$depth <= zmax else d$depth < zmax)
  x  <- d[ok, ]
  id <- paste(floor(x$lat / NM_DLAT), floor(x$lon / NM_DLON), floor(x$depth / NM_DZ))
  cell <- data.frame(v = as.numeric(tapply(x$c14, id, mean)), lat = as.numeric(tapply(x$lat, id, mean)),
                     lon = as.numeric(tapply(x$lon, id, mean)))
  cell$w <- cos(cell$lat * pi / 180)
  n <- nrow(cell); w <- cell$w; v <- cell$v
  mu <- sum(w * v) / sum(w); sd_w <- sqrt(sum(w * (v - mu)^2) / sum(w))
  rad <- pi / 180; la <- cell$lat * rad; lo <- cell$lon * rad
  D <- outer(sin(la), sin(la)) + outer(cos(la), cos(la)) * cos(outer(lo, lo, "-"))
  D <- NM_R_EARTH * acos(pmin(pmax(D, -1), 1)); diag(D) <- 0
  cnt <- v - mu; CV <- outer(cnt, cnt); off <- upper.tri(D)
  db <- cut(D[off], NM_DBINS, right = FALSE)
  rho_bin <- tapply(CV[off], db, mean) / sd_w^2
  mid <- (NM_DBINS[-length(NM_DBINS)] + NM_DBINS[-1]) / 2
  okb <- !is.na(rho_bin)
  rho_of <- approxfun(mid[okb], rho_bin[okb], rule = 2, yleft = rho_bin[okb][1])
  R <- matrix(rho_of(D), n, n); diag(R) <- 1
  S <- sum(w * (R %*% w)); n_corr <- if (S > 0) sum(w)^2 / S else NA_real_
  Rf <- pmax(R, 0); diag(Rf) <- 1; n_floor <- sum(w)^2 / sum(w * (Rf %*% w))
  n_kish <- sum(w)^2 / sum(w^2)
  half <- mid[which(okb & rho_bin < 0.5)[1]]; neg <- mid[which(okb & rho_bin < 0)[1]]
  boot <- vapply(NM_BLOCKS, function(B) {
    bid <- paste(floor(cell$lat / B), floor(cell$lon / (2 * B)))
    idxs <- split(seq_len(n), bid); nb <- length(idxs)
    m <- vapply(seq_len(NM_NBOOT), function(i) {
      k <- unlist(idxs[sample.int(nb, nb, replace = TRUE)], use.names = FALSE)
      sum(w[k] * v[k]) / sum(w[k]) }, numeric(1))
    (sd_w / stats::sd(m))^2 }, 0)
  names(boot) <- NM_BLOCKS
  adm <- c(floor = n_floor, bb60 = boot[["60"]], bb30 = boot[["30"]], empirical = n_corr)
  cat(sprintf("\n--- %s: %.0f-%s m -- %d bottles, %d cells, vw mean %.1f, sd_w %.1f ---\n", lbl, zmin,
              if (zmax > 1e4) "bottom" else sprintf("%.0f", zmax), nrow(x), n, mu, sd_w))
  cat(sprintf("  correlogram: rho < 0.5 by ~%.0f km, negative by ~%s km\n", half, if (is.na(neg)) "never" else sprintf("%.0f", neg)))
  cat(sprintf("  Kish %.0f | correlogram empirical %s | floored %.1f | block bootstrap 10/20/30/60 deg: %s\n",
              n_kish, if (is.na(n_corr)) "UNUSABLE (S <= 0)" else sprintf("%.1f", n_corr), n_floor,
              paste(sprintf("%.1f", boot), collapse = " / ")))
  cat(sprintf("  ADMISSIBLE {floor, bb60, bb30, empirical} = {%s}; median %.1f, geomean %.1f  ->  sigma at median %.2f (in use: n_eff %d, sigma %.2f)\n",
              paste(sprintf("%.1f", adm), collapse = ", "), stats::median(adm, na.rm = TRUE),
              exp(mean(log(adm), na.rm = TRUE)), sd_w / sqrt(stats::median(adm, na.rm = TRUE)), NM_IN_USE, sd_w / sqrt(NM_IN_USE)))
  list(lbl = lbl, n = n, mu = mu, sd_w = sd_w, kish = n_kish, empirical = n_corr, floor = n_floor,
       boot = boot, adm = adm, median = stats::median(adm, na.rm = TRUE), geomean = exp(mean(log(adm), na.rm = TRUE)))
}

cat("=== n_eff FOR THE INTERMEDIATE SLABS, by the deep slab's own estimators ===\n")
res <- list()
res$deep <- neff_of(slabs$deep[1], slabs$deep[2], "DEEP (the gate)", closed_top = TRUE)
gate <- abs(res$deep$adm / NM_DEEP_ADMISSIBLE - 1)
cat(sprintf("  GATE vs the recorded deep set %s: max relative departure %.3f  %s\n",
            paste(NM_DEEP_ADMISSIBLE, collapse = "/"), max(gate, na.rm = TRUE),
            if (max(gate, na.rm = TRUE) <= NM_GATE_TOL) "PASS -- same estimator" else "FAIL -- NOT the same estimator; do not read the slabs"))
if (max(gate, na.rm = TRUE) > NM_GATE_TOL) stop("gate failed")
res$A <- neff_of(slabs$A[1], slabs$A[2], "SLAB A")
res$B <- neff_of(slabs$B[1], slabs$B[2], "SLAB B")
cat("\n=== VERDICT ===\n")
for (k in c("A", "B")) {
  r <- res[[k]]
  cat(sprintf("  slab %s: admissible median %.1f (geomean %.1f) vs in-use %d -> ratio %.2f  %s\n", k, r$median, r$geomean,
              NM_IN_USE, r$median / NM_IN_USE,
              if (r$median / NM_IN_USE > 2 || r$median / NM_IN_USE < 0.5) "DIFFERS by > 2x (I14)" else "within 2x of 20"))
}
i14 <- any(vapply(c("A", "B"), function(k) { q <- res[[k]]$median / NM_IN_USE; q > 2 || q < 0.5 }, TRUE))
cat(sprintf("  I14  a slab's measured n_eff differs from 20 by > 2x : %s\n", if (i14) "PASS" else "FAIL"))
cat("  ⚠ As for the deep slab, the admissible set is a BRACKET (floor vs empirical differ ~15x) and the\n")
cat("    median is a convention; the residual ambiguity is about whether basin contrast is sampled\n")
cat("    structure or exchangeable water masses. Marcus's call, as it was on 2026-08-14/16.\n")
saveRDS(res, NM_OUT); cat(sprintf("  saved %s\n", NM_OUT))
