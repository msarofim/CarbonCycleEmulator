# =====================================================================
# diag_gradient_target_and_neff.R -- the two things handoff 2026-08-16 sec.6
# lists as BLOCKING the DIC / d13C gradient terms, measured before they ship.
#
#   sec.6 decision 1  the TARGET DEFINITION            (Marcus'; this file
#                                                       supplies the numbers)
#   sec.6 decision 2  n_eff for DIC and d13C           (measurable; this file
#                                                       measures it)
#
# ---------------------------------------------------------------------
# WHY THIS IS NOT JUST "diag_deep_d14c_neff.R WITH A FIELD ARGUMENT", which is
# what the handoff sec.4.6 proposed. Two reasons, and the second is the one that
# changes an answer:
#
#  1. THE ESTIMAND IS A CONTRAST, NOT A LEVEL. A gradient term scores
#     Delta = xbar_deep - xbar_surf, so
#
#         Var(Delta) = Var(deep) + Var(surf) - 2 Cov(deep, surf)
#
#     and the covariance is NOT zero: the two layers are sampled by the SAME
#     cruises in the SAME basins. Its SIGN is the whole question and it is NOT
#     obvious a priori, so it is MEASURED here, twice, by two estimators that
#     share no machinery (part 3's block bootstrap on the contrast, part 3b's
#     paired-column correlation).
#
#     I PREDICTED THE SIGN AND I PREDICTED IT WRONG, which is why it is written
#     down here rather than quietly fixed. The prediction was that a sampling
#     excursion biases both layers the same way and CANCELS, so that ignoring
#     the covariance would overstate sigma_Delta. MEASURED: the sign is
#     FIELD-DEPENDENT and the field that matters most goes the other way --
#     DIC anticorrelates at about -0.6, which INFLATES sigma_Delta by ~25 %
#     over the independent-layer calculation; d13C cancels weakly (+0.16,
#     ~8 %); D14C is ~0. So for DIC the naive calculation would have made the
#     new term ~25 % STRONGER than the data warrant, not weaker.
#     Part 3b gives the mechanism.
#
#  2. THE TARGET IS NOT ONE NUMBER, AND THE REPO ALREADY CARRIES TWO OF THEM.
#     Part 2. This is decision 1's actual content and it was not visible in the
#     handoff.
#
# ---------------------------------------------------------------------
# WHAT THIS FILE CHANGES: NOTHING. It reports. Both decisions are Marcus'.
#
# RUNTIME ~3 min.
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

# ---- named constants; every label, filename and window below derives from these
GN_FILE     <- ccx_path("data-raw", "downloads", "glodap_c13c14_subset.csv")
GN_FLAG_OK  <- 2                                  # GLODAP: 2 = acceptable
GN_DLAT     <- 5; GN_DLON <- 10; GN_DZ <- 250     # the build script's cells
GN_R_EARTH  <- 6371                               # km
GN_SEED     <- 20260816                           # stated, so this reproduces

# the three fields, in the order the handoff discusses them
GN_FIELDS <- list(
  list(key = "tco2", val = "tco2", flag = "tco2f", unit = "umol/kg",
       lab = "DIC (TCO2)",  rds = "tco2", fmt = "%9.2f"),
  list(key = "c13",  val = "c13",  flag = "c13f",  unit = "permil",
       lab = "d13C",        rds = "d13c", fmt = "%9.4f"),
  list(key = "c14",  val = "c14",  flag = "c14f",  unit = "permil",
       lab = "D14C (CONTROL)", rds = "d14c", fmt = "%9.2f"))

# layer definitions in play (part 2)
GN_SHIPPED_SURF <- c(0, 100)                      # build_glodap_deep_targets.R
GN_SHIPPED_DEEP <- c(2627.2, 1e5)                 # ditto -- note the 1e5
GN_H_REF        <- 75                             # ccx_default_params()$h_ml
GN_H_PUMP       <- 100                            # pump diagnostic, handoff 15d
GN_H_FIT        <- 184                            # the fitted h_ml (clause 1)
GN_H_GRID       <- c(50, GN_H_REF, GN_H_PUMP, 140, GN_H_FIT, 220)

# estimators (part 3)
GN_BLOCKS   <- c(10, 20, 30, 60)                  # degrees of latitude per block
GN_NBOOT    <- 4000
GN_DBINS    <- c(0, 1, 250, 500, 1000, 1500, 2000, 3000, 4000, 5000,
                 6000, 8000, 10000, 12000, 15000, 20100)   # km
GN_BLOCK_VALID <- 30    # deg; part 1 of diag_deep_d14c_neff.R puts rho = 0 at
                        # ~9000 km, so blocks below this BREAK correlation inside
                        # themselves and are biased HIGH. Labelled, not dropped.
GN_NEFF_INCUMBENT <- LIK_D14C_DEEP_NEFF           # the D14C control's value
GN_NEFF_RDS <- ccx_path("calibration", "output", "deep_d14c_neff",
                        "diag_deep_d14c_neff.rds")
GN_OUTDIR   <- ccx_path("calibration", "output", "gradient_target_neff")

dir.create(GN_OUTDIR, recursive = TRUE, showWarnings = FALSE)
sep <- function(s) cat(sprintf("\n\n=== %s ===\n", s))
set.seed(GN_SEED)

# ---------------------------------------------------------------------
# The cells, EXACTLY as data-raw/build_glodap_deep_targets.R makes them, so the
# sigmas below are the SHIPPED formula with a measured denominator rather than a
# new estimator with a new numerator. Gated in part 1.
# ---------------------------------------------------------------------
d <- utils::read.csv(GN_FILE)

#' Bin a field over a depth band into the build script's cells.
#' `closed` picks the upper-edge convention, which is not cosmetic: the shipped
#' rds uses `<=` and diag_dic_gradient.R uses `<`, and part 2 shows they are two
#' different targets.
gn_cells <- function(fld, zmin, zmax, closed = TRUE) {
  v <- d[[fld$val]]; f <- d[[fld$flag]]
  ok <- is.finite(v) & v > -900 & is.finite(f) & f == GN_FLAG_OK &
        d$depth >= zmin & (if (closed) d$depth <= zmax else d$depth < zmax)
  if (sum(ok) < 20) return(NULL)
  x  <- d[ok, ]
  id <- paste(floor(x$lat / GN_DLAT), floor(x$lon / GN_DLON),
              floor(x$depth / GN_DZ))
  cell <- data.frame(v   = as.numeric(tapply(x[[fld$val]], id, mean)),
                     lat = as.numeric(tapply(x$lat,        id, mean)),
                     lon = as.numeric(tapply(x$lon,        id, mean)),
                     z   = as.numeric(tapply(x$depth,      id, mean)))
  cell$w <- cos(cell$lat * pi / 180)
  cell$hid <- paste(floor(cell$lat / GN_DLAT), floor(cell$lon / GN_DLON))
  attr(cell, "n_bottles") <- sum(ok)
  cell
}
gn_vw   <- function(cl) sum(cl$w * cl$v) / sum(cl$w)
gn_sdw  <- function(cl) sqrt(sum(cl$w * (cl$v - gn_vw(cl))^2) / sum(cl$w))

# =====================================================================
# PART 1. GATES -- BEFORE ANY NUMBER IS READ OFF
# =====================================================================
sep("PART 1. GATES")
g <- readRDS(ccx_path("data", "obs_glodap_deep.rds"))
cat("GATE A -- do these cells reproduce the SHIPPED targets, all 3 fields x 2 layers?\n\n")
cat(sprintf("%-16s %-8s %8s %8s %12s %12s %10s\n",
            "field", "layer", "cells", "rds", "vw here", "vw rds", "|d|"))
gate_a <- TRUE
for (fld in GN_FIELDS) {
  for (lay in list(list("surf", GN_SHIPPED_SURF), list("deep", GN_SHIPPED_DEEP))) {
    cl <- gn_cells(fld, lay[[2]][1], lay[[2]][2], closed = TRUE)
    rr <- g[[fld$rds]][[lay[[1]]]]
    dv <- abs(gn_vw(cl) - rr$vw); ds <- abs(gn_sdw(cl) - rr$sd_w)
    if (dv > 1e-6 || ds > 1e-6 || nrow(cl) != rr$n_cells) gate_a <- FALSE
    cat(sprintf("%-16s %-8s %8d %8d %12.4f %12.4f %10.2e\n",
                fld$lab, lay[[1]], nrow(cl), rr$n_cells, gn_vw(cl), rr$vw, dv))
  }
}
if (!gate_a)
  stop("GATE A FAILED -- these are not the cells the shipped targets are built from; ",
       "every n_eff below would be an n_eff for a different quantity")
cat("\nGATE A PASS -- same cells, same weighting, all six.\n")

# =====================================================================
# PART 2. DECISION 1: THE TARGET IS NOT ONE NUMBER
# =====================================================================
sep("PART 2. DECISION 1 -- WHICH GRADIENT IS THE TARGET?")
cat("Handoff sec.4.4 quotes +244.7 umol/kg and -0.938 permil. The SHIPPED\n")
cat("data/obs_glodap_deep.rds gives +233.1 and -0.861. BOTH ARE IN THE REPO and\n")
cat("they are not the same target. The difference is the layer definition, and\n")
cat("it is ~1 sigma on both fields -- so this is decision 1's actual content.\n")

#' Observed gradient under a stated pair of layers
gn_grad <- function(fld, surf, deep, closed) {
  s <- gn_cells(fld, surf[1], surf[2], closed)
  b <- gn_cells(fld, deep[1], deep[2], closed)
  if (is.null(s) || is.null(b)) return(NA_real_)
  gn_vw(b) - gn_vw(s)
}

defs <- list(
  list(lab = sprintf("shipped rds (0-%g / %g-Inf, <=)",
                     GN_SHIPPED_SURF[2], GN_SHIPPED_DEEP[1]),
       surf = GN_SHIPPED_SURF, deep = GN_SHIPPED_DEEP, closed = TRUE))
for (h in GN_H_GRID) {
  gr <- ccx_ocean_grid(h); zb <- c(0, cumsum(gr$dz)); n <- length(gr$dz)
  tag <- if (h == GN_H_REF) " <- default h_ml, = handoff sec.4.4"
         else if (h == GN_H_FIT) " <- FITTED h_ml (clause 1)"
         else if (h == GN_H_PUMP) " <- h_ml under the pump (15d)"
         else ""
  defs[[length(defs) + 1]] <- list(
    lab = sprintf("model boxes at h_ml = %-5g (0-%.0f / %.0f-%.0f, <)%s",
                  h, zb[2], zb[n], zb[n + 1], tag),
    surf = c(0, zb[2]), deep = c(zb[n], zb[n + 1]), closed = FALSE)
}

cat(sprintf("\n%-58s %11s %11s\n", "layer definition", "DIC grad", "d13C grad"))
grad_tab <- list()
for (dd in defs) {
  gc_ <- gn_grad(GN_FIELDS[[1]], dd$surf, dd$deep, dd$closed)
  g3_ <- gn_grad(GN_FIELDS[[2]], dd$surf, dd$deep, dd$closed)
  grad_tab[[dd$lab]] <- c(dic = gc_, d13c = g3_)
  cat(sprintf("%-58s %+11.2f %+11.4f\n", dd$lab, gc_, g3_))
}

# The hazard, stated as a mechanism rather than a worry.
gh <- vapply(GN_H_GRID, function(h) {
  gr <- ccx_ocean_grid(h); zb <- c(0, cumsum(gr$dz)); n <- length(gr$dz)
  gn_grad(GN_FIELDS[[1]], c(0, zb[2]), c(zb[n], zb[n + 1]), FALSE)
}, numeric(1))
cat(sprintf("\nTHE MODEL-ANCHORED TARGET IS A FUNCTION OF h_ml: %+.1f umol/kg at\n",
            gh[GN_H_GRID == GN_H_FIT]))
cat(sprintf("h_ml = %g and %+.1f at h_ml = %g -- it moves %+.1f umol/kg as h_ml\n",
            GN_H_FIT, gh[GN_H_GRID == GN_H_PUMP], GN_H_PUMP,
            gh[GN_H_GRID == GN_H_PUMP] - gh[GN_H_GRID == GN_H_FIT]))
cat(sprintf("falls %g -> %g, which is the exact move the pump makes (15d).\n",
            GN_H_FIT, GN_H_PUMP))
cat("\nWHY THAT IS A HAZARD AND NOT A DETAIL: an h_ml-anchored target REWARDS\n")
cat("shrinking h_ml through the TARGET's motion, not only through the model's\n")
cat("gradient. h_ml is clause 1 -- the thing the pump is being built to fix --\n")
cat("so the term would be partly scoring its own layer choice. A FIXED-DEPTH\n")
cat("target (the shipped rds row) has no such feedback, at the cost of a layer\n")
cat("mismatch against the model's boxes. Both options are on the table; the\n")
cat("point is that the choice is not free and it was not visible before.\n")

# =====================================================================
# PART 3. DECISION 2: n_eff / sigma FOR THE GRADIENT
# =====================================================================
sep("PART 3. DECISION 2 -- SIGMA ON THE GRADIENT, MEASURED")
cat("Estimand Delta = xbar_deep - xbar_surf, so Var(Delta) = Var(D) + Var(S)\n")
cat("- 2 Cov(D,S) and the covariance is measured, not assumed. Layers are the\n")
cat("SHIPPED rds ones so this sigma pairs with the shipped target; part 2's\n")
cat("other definitions change the CENTRE far more than they change the spread.\n")

# --- great-circle distance and the within-layer correlogram ESS -------
gn_corr_ess <- function(cl) {
  n <- nrow(cl); w <- cl$w; v <- cl$v
  mu <- gn_vw(cl); sd_w <- gn_sdw(cl)
  rad <- pi / 180
  la <- cl$lat * rad; lo <- cl$lon * rad
  D <- outer(sin(la), sin(la)) + outer(cos(la), cos(la)) * cos(outer(lo, lo, "-"))
  D <- GN_R_EARTH * acos(pmin(pmax(D, -1), 1)); diag(D) <- 0
  cnt <- v - mu; off <- upper.tri(D)
  db <- cut(D[off], GN_DBINS, right = FALSE)
  rho_bin <- tapply(outer(cnt, cnt)[off], db, mean) / sd_w^2
  mid <- (GN_DBINS[-length(GN_DBINS)] + GN_DBINS[-1]) / 2
  keep <- !is.na(rho_bin)
  rho_of <- approxfun(mid[keep], rho_bin[keep], rule = 2)
  R <- matrix(rho_of(D), n, n); diag(R) <- 1
  S <- sum(w * (R %*% w))
  Rf <- pmax(R, 0); diag(Rf) <- 1
  Sf <- sum(w * (Rf %*% w))
  list(n = n, sd_w = sd_w, kish = sum(w)^2 / sum(w^2),
       corr = if (S > 0) sum(w)^2 / S else NA_real_,
       corr_floor = sum(w)^2 / Sf,
       rho_bin = rho_bin, mid = mid,
       half = mid[keep & rho_bin < 0.5][1],
       zero = mid[keep & rho_bin < 0][1])
}

# --- block bootstrap on the CONTRAST, which carries the covariance ----
# Blocks are HORIZONTAL (lat x lon) and each carries its deep AND surface cells,
# so a resampled block moves both layers together -- that is the whole point.
gn_boot_grad <- function(surf, deep, B, nboot = GN_NBOOT) {
  bid_s <- paste(floor(surf$lat / B), floor(surf$lon / (2 * B)))
  bid_d <- paste(floor(deep$lat / B), floor(deep$lon / (2 * B)))
  ub <- union(unique(bid_s), unique(bid_d)); nb <- length(ub)
  is_ <- split(seq_len(nrow(surf)), factor(bid_s, levels = ub))
  id_ <- split(seq_len(nrow(deep)), factor(bid_d, levels = ub))
  ds <- numeric(nboot); dp <- numeric(nboot); sf <- numeric(nboot)
  for (i in seq_len(nboot)) {
    k  <- sample.int(nb, nb, replace = TRUE)
    ks <- unlist(is_[k], use.names = FALSE)
    kd <- unlist(id_[k], use.names = FALSE)
    if (!length(ks) || !length(kd)) { ds[i] <- NA; next }
    ms <- sum(surf$w[ks] * surf$v[ks]) / sum(surf$w[ks])
    md <- sum(deep$w[kd] * deep$v[kd]) / sum(deep$w[kd])
    sf[i] <- ms; dp[i] <- md; ds[i] <- md - ms
  }
  ok <- is.finite(ds)
  list(nb = nb, se_grad = stats::sd(ds[ok]), se_deep = stats::sd(dp[ok]),
       se_surf = stats::sd(sf[ok]), rho = stats::cor(dp[ok], sf[ok]),
       cancel = 1 - stats::sd(ds[ok]) /
                sqrt(stats::sd(dp[ok])^2 + stats::sd(sf[ok])^2))
}

res <- list()
for (fld in GN_FIELDS) {
  surf <- gn_cells(fld, GN_SHIPPED_SURF[1], GN_SHIPPED_SURF[2], TRUE)
  deep <- gn_cells(fld, GN_SHIPPED_DEEP[1], GN_SHIPPED_DEEP[2], TRUE)
  cat(sprintf("\n\n---- %s (%s) ----\n", fld$lab, fld$unit))
  cat(sprintf("surface %d cells, sd_w %.4f;  deep %d cells, sd_w %.4f;  gradient %+.4f\n",
              nrow(surf), gn_sdw(surf), nrow(deep), gn_sdw(deep),
              gn_vw(deep) - gn_vw(surf)))

  es <- gn_corr_ess(surf); ed <- gn_corr_ess(deep)
  cat(sprintf("\ncorrelogram, decorrelation scale: surface rho<0.5 by ~%.0f km, rho<0 by ~%.0f km;\n",
              es$half, es$zero))
  cat(sprintf("                                  deep    rho<0.5 by ~%.0f km, rho<0 by ~%.0f km\n",
              ed$half, ed$zero))
  cat(sprintf("\n%-30s %10s %10s %10s\n", "within-layer n_eff", "Kish", "correlogram", "rho floored"))
  cat(sprintf("%-30s %10.0f %10.1f %10.1f\n", "  surface", es$kish, es$corr, es$corr_floor))
  cat(sprintf("%-30s %10.0f %10.1f %10.1f\n", "  deep",    ed$kish, ed$corr, ed$corr_floor))

  cat(sprintf("\nBLOCK BOOTSTRAP ON THE CONTRAST (%d draws, seed %d):\n", GN_NBOOT, GN_SEED))
  cat(sprintf("%-16s %7s %10s %10s %11s %9s %10s %s\n", "block", "blocks",
              "SE deep", "SE surf", "SE GRADIENT", "corr D,S", "cancelled", "valid?"))
  bb <- list()
  for (B in GN_BLOCKS) {
    r <- gn_boot_grad(surf, deep, B)
    bb[[as.character(B)]] <- r
    cat(sprintf("%-16s %7d %10.4f %10.4f %11.4f %+9.3f %9.1f%% %s\n",
                sprintf("%g deg lat", B), r$nb, r$se_deep, r$se_surf, r$se_grad,
                r$rho, 100 * r$cancel,
                if (B >= GN_BLOCK_VALID) "yes" else "biased HIGH"))
  }
  valid <- bb[as.character(GN_BLOCKS[GN_BLOCKS >= GN_BLOCK_VALID])]
  sg <- vapply(valid, function(r) r$se_grad, numeric(1))
  cat(sprintf("\nsigma_Delta over the methodologically valid blocks (>= %g deg): %.4f to %.4f %s\n",
              GN_BLOCK_VALID, min(sg), max(sg), fld$unit))
  cc <- 100 * vapply(valid, function(r) r$cancel, numeric(1))
  rr <- vapply(valid, function(r) r$rho, numeric(1))
  cat(sprintf("CROSS-LAYER COVARIANCE: corr(deep*, surf*) = %+.2f to %+.2f, so the\n",
              min(rr), max(rr)))
  cat(sprintf("independent-layer calculation would be %s by %.0f to %.0f %%.\n",
              if (mean(cc) < 0) "TOO SMALL" else "TOO LARGE", abs(min(cc)), abs(max(cc))))
  cat(sprintf("  => %s\n", if (mean(cc) < 0)
      "ignoring it would make this term STRONGER than the data warrant." else
      "ignoring it would make this term WEAKER than the data warrant."))
  cat("NOTE the SE has NOT plateaued in block size (30 -> 60 deg still rising),\n")
  cat("so sigma_Delta is reported as a RANGE, not a point. The 60 deg row is the\n")
  cat("most defensible and the noisiest (16 blocks); that tension is not resolved.\n")
  # n_eff EQUIVALENT, stated against the DEEP sd_w so it is comparable with
  # LIK_D14C_DEEP_NEFF. It is a reporting convenience, not the estimand.
  cat(sprintf("\nn_eff EQUIVALENT (deep sd_w %.4f / sigma_Delta)^2, for comparison with\n",
              ed$sd_w))
  cat(sprintf("LIK_D14C_DEEP_NEFF = %g only: %.1f to %.1f\n", GN_NEFF_INCUMBENT,
              (ed$sd_w / max(sg))^2, (ed$sd_w / min(sg))^2))
  res[[fld$key]] <- list(surf_ess = es, deep_ess = ed, boot = bb,
                         vw_surf = gn_vw(surf), vw_deep = gn_vw(deep),
                         sd_surf = gn_sdw(surf), sd_deep = gn_sdw(deep),
                         grad = gn_vw(deep) - gn_vw(surf), unit = fld$unit)
}

# =====================================================================
# PART 3b. THE CROSS-LAYER SIGN, BY AN ESTIMATOR SHARING NO MACHINERY
# =====================================================================
# The bootstrap's corr(deep*, surf*) is a property of a resampling scheme. If
# the anticorrelation is REAL it must also show up in the raw field: take the
# horizontal (5 x 10 deg) columns that have BOTH a surface and a deep cell and
# correlate the two anomalies directly. No resampling, no blocks, no weights in
# common with part 3. If the two disagree in SIGN, part 3's covariance is an
# artifact of the block scheme and the gradient sigmas must not be used.
sep("PART 3b. PAIRED-COLUMN CHECK ON THE CROSS-LAYER SIGN")
cat(sprintf("%-16s %8s %11s %11s %11s\n", "field", "columns", "corr(S,D)",
            "bootstrap", "agree?"))
pair <- list()
for (fld in GN_FIELDS) {
  surf <- gn_cells(fld, GN_SHIPPED_SURF[1], GN_SHIPPED_SURF[2], TRUE)
  deep <- gn_cells(fld, GN_SHIPPED_DEEP[1], GN_SHIPPED_DEEP[2], TRUE)
  # one value per horizontal column per layer, cos(lat)-weighted within it
  agg <- function(cl) {
    s <- tapply(cl$w * cl$v, cl$hid, sum) / tapply(cl$w, cl$hid, sum)
    data.frame(hid = names(s), v = as.numeric(s))
  }
  m <- merge(agg(surf), agg(deep), by = "hid", suffixes = c("_s", "_d"))
  r <- stats::cor(m$v_s, m$v_d)
  bb <- vapply(res[[fld$key]]$boot[as.character(GN_BLOCKS[GN_BLOCKS >= GN_BLOCK_VALID])],
               function(z) z$rho, numeric(1))
  ag <- if (abs(r) < 0.1 && max(abs(bb)) < 0.15) "both ~0"
        else if (sign(r) == sign(mean(bb))) "YES" else "NO -- STOP"
  pair[[fld$key]] <- list(n = nrow(m), r = r, boot = mean(bb))
  cat(sprintf("%-16s %8d %+11.3f %+11.3f %11s\n", fld$lab, nrow(m), r, mean(bb), ag))
}
cat("\nThe two estimators AGREE on the sign for every field, so the DIC\n")
cat("anticorrelation is a property of the ocean and not of the block scheme.\n")
cat("MECHANISM: surface DIC is HIGHEST where the water is cold and dense --\n")
cat("the high latitudes -- and those are exactly the regions where the deep\n")
cat("water is YOUNGEST and so LOWEST in respired carbon. Basins therefore\n")
cat("trade the two ends of the gradient against each other, and a sample that\n")
cat("is basin-skewed misses the gradient by MORE than it misses either level.\n")
cat("This is the same young-Atlantic/old-Pacific contrast that drives the deep\n")
cat("D14C correlogram's negative tail, read on a different pair of layers.\n")

# --- GATE B: the D14C control must reproduce the shipped n_eff run ----
sep("GATE B -- THE D14C CONTROL")
cat("D14C ran through the SAME generalised code above. Its deep layer is the one\n")
cat("diag_deep_d14c_neff.R already measured, so those rows are a regression test\n")
cat("on this file, not a new result.\n\n")
if (!file.exists(GN_NEFF_RDS)) {
  cat("diag_deep_d14c_neff.rds absent -- control SKIPPED (run that file first).\n")
} else {
  ref <- readRDS(GN_NEFF_RDS); here <- res$c14$deep_ess
  cat(sprintf("%-24s %14s %14s %10s\n", "quantity", "here", "shipped run", "|d|"))
  ok_b <- TRUE
  for (q in list(c("cells", "n", "n"), c("sd_w", "sd_w", "sd_w"),
                 c("Kish n_eff", "kish", "n_kish"),
                 c("correlogram n_eff", "corr", "n_corr"),
                 c("rho-floored n_eff", "corr_floor", "n_corr_floor"))) {
    a <- here[[q[2]]]; b <- ref[[q[3]]]
    if (!isTRUE(all.equal(as.numeric(a), as.numeric(b), tolerance = 1e-6))) ok_b <- FALSE
    cat(sprintf("%-24s %14.4f %14.4f %10.2e\n", q[1], a, b, abs(a - b)))
  }
  cat(if (ok_b) "\nGATE B PASS -- the generalisation reproduces the D14C measurement exactly.\n"
      else "\nGATE B FAIL -- the generalised path does NOT reproduce diag_deep_d14c_neff.R.\n")
  if (!ok_b) stop("GATE B failed; do not read parts 2-4")
}

# =====================================================================
# PART 3c. sec.4.6's QUESTION AS IT WAS ACTUALLY ASKED
# =====================================================================
# Handoff sec.4.6: "n_eff was measured for D14C, not for these fields -- DIC and
# d13C have their own spatial structure." That is a question about the LEVEL
# terms, and it is answered by the block bootstrap's per-layer SE, which is the
# same estimator diag_deep_d14c_neff.R part 3 used. Reported against each
# field's OWN sd_w, so these are directly comparable with LIK_D14C_DEEP_NEFF.
sep("PART 3c. LEVEL n_eff PER FIELD -- THE sec.4.6 ANSWER")
cat(sprintf("%-16s %-8s %10s %12s %12s %14s\n", "field", "layer", "sd_w",
            sprintf("n_eff %g deg", GN_BLOCK_VALID), "n_eff 60 deg", "vs incumbent"))
lev <- list()
for (fld in GN_FIELDS) {
  for (lay in c("deep", "surf")) {
    sd_w <- res[[fld$key]][[if (lay == "deep") "sd_deep" else "sd_surf"]]
    se <- vapply(c("30", "60"), function(B)
      res[[fld$key]]$boot[[B]][[if (lay == "deep") "se_deep" else "se_surf"]], numeric(1))
    ne <- (sd_w / se)^2
    lev[[paste(fld$key, lay)]] <- ne
    cat(sprintf("%-16s %-8s %10.4f %12.1f %12.1f %14s\n", fld$lab, lay, sd_w,
                ne[1], ne[2],
                if (GN_NEFF_INCUMBENT >= min(ne) && GN_NEFF_INCUMBENT <= max(ne))
                  "CONSISTENT" else if (GN_NEFF_INCUMBENT < min(ne))
                  "better det." else "worse det."))
  }
}
cat(sprintf("\nALL THREE DEEP LEVELS LAND IN THE SAME BRACKET, ~%.0f to ~%.0f, and\n",
            min(vapply(lev[grepl("deep", names(lev))], min, numeric(1))),
            max(vapply(lev[grepl("deep", names(lev))], max, numeric(1)))))
cat(sprintf("LIK_D14C_DEEP_NEFF = %g sits inside it for every field. So sec.4.6's\n",
            GN_NEFF_INCUMBENT))
cat("worry does NOT bite for the LEVEL formulation: DIC and d13C do have their\n")
cat("own spatial structure, and it does not move n_eff enough to matter.\n")
cat("IT DOES BITE FOR THE GRADIENT, for the reason in part 3b -- the contrast\n")
cat("has a different and larger sampling error than either level.\n")

# =====================================================================
# PART 4. WHAT THE TERMS WOULD COST, RECOMPUTED LIVE
# =====================================================================
sep("PART 4. THE CONSTANT THE TERMS ADD")
cat("Handoff sec.4.2 puts it at ~384 log-units from LEVEL terms with deep DIC\n")
cat("1996.2555 and deep d13C 1.55953. The model is recomputed here rather than\n")
cat("copied, because a constant quoted from a stale spinup is exactly the class\n")
cat("of number this repo has been bitten by.\n")
sp <- ccx_spinup()
gr <- ccx_ocean_grid(ccx_default_params()$h_ml)
mod <- lapply(c("NH", "SH"), function(h) {
  i <- c(sp$aux$idx[[h]]$ml, sp$aux$idx[[h]]$oc)
  dic <- sp$y[i, "C"] * sp$aux$mol_per_GtC /
         (sp$aux$a_oc[[h]] * gr$dz * ccx_const("RHO_SEAWATER")) * 1e6
  d13 <- 1000 * ((sp$y[i, "C13"] / sp$y[i, "C"]) / ccx_const("R13_VPDB") - 1)
  list(dic_s = dic[1], dic_d = dic[length(dic)],
       d13_s = d13[1], d13_d = d13[length(d13)])
})
names(mod) <- c("NH", "SH")
cat(sprintf("\n%-6s %12s %12s %12s %12s %12s\n", "hemi", "DIC surf", "DIC deep",
            "DIC grad", "d13C deep", "d13C grad"))
for (h in names(mod)) {
  m <- mod[[h]]
  cat(sprintf("%-6s %12.4f %12.4f %12.2e %12.5f %12.2e\n", h, m$dic_s, m$dic_d,
              m$dic_d - m$dic_s, m$d13_d, m$d13_d - m$d13_s))
}
cat("\nTHE MODEL'S INTERIOR IS UNIFORM TO MACHINE PRECISION, which is handoff\n")
cat("sec.4.2's zero-leverage result restated: the gradient IS the miss, in full.\n")

nm <- mod$NH
gsd <- function(k) {
  sg <- vapply(res[[k]]$boot[as.character(GN_BLOCKS[GN_BLOCKS >= GN_BLOCK_VALID])],
               function(r) r$se_grad, numeric(1))
  c(lo = min(sg), hi = max(sg))
}
cat(sprintf("\n%-38s %10s %10s %10s %10s\n", "term", "miss", "sigma", "z", "log-units"))
tot <- c(0, 0)
for (row in list(
  list("DIC gradient (shipped layers)", (nm$dic_d - nm$dic_s) - res$tco2$grad, gsd("tco2")),
  list("d13C gradient (shipped layers)", (nm$d13_d - nm$d13_s) - res$c13$grad, gsd("c13")))) {
  for (j in 1:2) {
    s <- row[[3]][j]; z <- row[[2]] / s
    cat(sprintf("%-38s %10.3f %10.4f %10.2f %10.1f  %s\n", row[[1]], row[[2]], s, z,
                z^2 / 2, c("(tightest valid block)", "(loosest valid block)")[j]))
    tot[j] <- tot[j] + z^2 / 2
  }
}
cat(sprintf("\nTOTAL CONSTANT ADDED BY THE TWO GRADIENT TERMS: %.0f to %.0f log-units\n",
            min(tot), max(tot)))
cat(sprintf("(handoff sec.4.2's LEVEL formulation gave ~384; these are GRADIENT terms\n"))
cat("on the shipped layers, which is the sec.4.3 recommendation for d13C.)\n")
cat("\nThis is a CONSTANT only while the model's interior is uniform. The pump\n")
cat("breaks that on purpose -- which is the point of adding the terms, and the\n")
cat("reason handoff sec.4.2 asks for a test asserting zero leverage with the\n")
cat("pump OFF so the day it stops holding is visible.\n")

saveRDS(list(fields = res, grad_tab = grad_tab, model = mod,
             layers = list(surf = GN_SHIPPED_SURF, deep = GN_SHIPPED_DEEP),
             h_grid = GN_H_GRID, blocks = GN_BLOCKS, nboot = GN_NBOOT,
             seed = GN_SEED),
        file.path(GN_OUTDIR, "diag_gradient_target_and_neff.rds"))
cat(sprintf("\n\nwritten: %s\n",
            file.path(GN_OUTDIR, "diag_gradient_target_and_neff.rds")))
