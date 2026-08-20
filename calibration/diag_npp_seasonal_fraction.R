# =====================================================================
# diag_npp_seasonal_fraction.R -- WHAT IF ONLY THE EXTRATROPICAL NPP IS
#                                 SEASONAL AT ALL?
#
# THE PROPOSAL (Marcus 2026-08-20e): "what about not including the low-latitudes
# in the annual cycle at all, and just using the higher latitudes that are truly
# insolation driven? And maybe fewer than 4 bands?"
#
# WHY THIS IS NOT THE BANDING PROPOSAL, AND WHY IT COULD BE MUCH BETTER.
# diag_npp_bands.R showed that splitting the hemisphere into four bands, each
# with its own insolation curve, buys 0.3 points for two extra parameters -- and
# that its zero-parameter version is TWICE AS BAD as one curve. But it also
# showed WHY: the two boreal bands want phi poleward of their centroids with
# A ~ 1 (rectification, clean), while the two low-latitude bands are not
# light-shaped at all (the subtropical band wanted phi = 5 with the amplitude
# pegged at its ceiling). Banding kept the bad bands and gave them curves.
# **This proposal DELETES them from the seasonal term instead.**
#
# THE MODEL, and note that it can have NO free parameters:
#     n(t) = 1 + w(L) * A * ( I(phi(L), t) / mean I - 1 )
# where L is a latitude cutoff and BOTH
#     w(L)   = the share of hemispheric NPP poleward of L, and
#     phi(L) = the NPP-weighted centroid of that share
# are MEASURED from MOD17. Equatorward of L, NPP is treated as ASEASONAL --
# which is not a fudge but a statement: that carbon's cycle is water-driven, and
# a light-driven model should not pretend to represent it.
#
# With A = 1 this is a ZERO-PARAMETER seasonal driver: no fitted amplitude, no
# fitted latitude, both read off the satellite field. That is the outcome worth
# hunting -- it would replace two tuned constants with two measurements.
#
# THE ANNUAL BUDGET IS UNTOUCHED at every L: the term is a unit-mean modulation,
# so treating the tropics as aseasonal redistributes nothing and removes no
# carbon. Only the WITHIN-YEAR distribution changes.
#
# "FEWER THAN 4 BANDS" is tested too: a 2-band variant splits the seasonal part
# at 55 N (the cool-temperate / boreal divide), still with measured weights and
# centroids, to see whether the surviving structure is worth one more term.
#
# Usage:  Rscript calibration/diag_npp_seasonal_fraction.R
# =====================================================================
suppressPackageStartupMessages(library(ncdf4))
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)

SF_DIR   <- "data-raw/downloads/mod17_gpp8d"
SF_CACHE <- "data/obs_npp_latwindow.rds"   # lat x window x year, so this scan is instant next time
SF_VAR   <- "net_photosynthesis"
SF_R     <- 6371000
SF_NVALID_FULL <- 14400
SF_NGRID <- 720
SF_SHIFT <- seq(0, 11.75, by = 0.25)
SF_AMP   <- seq(0.05, 3, by = 0.01)
SF_CUTS  <- c(0, 10, 20, 23.5, 30, 35, 40, 45, 50, 55, 60)
SF_SPLIT <- 55                              # the 2-band divide, applied above the cutoff

tt  <- (seq_len(SF_NGRID) - 0.5) / SF_NGRID
p2p <- function(x) max(x) - min(x)
unitmean <- function(v) v / mean(v)

# ---- read once, cache ------------------------------------------------
if (file.exists(ccx_path(SF_CACHE))) {
  cache <- readRDS(ccx_path(SF_CACHE)); cat(sprintf("cache: %s\n", SF_CACHE))
} else {
  read_year <- function(zp) {
    tmp <- file.path(tempdir(), paste0("sf_", basename(zp)))
    unlink(tmp, recursive = TRUE); dir.create(tmp, recursive = TRUE)
    utils::unzip(zp, exdir = tmp, junkpaths = TRUE); on.exit(unlink(tmp, recursive = TRUE))
    fs <- sort(list.files(tmp, pattern = "\\.nc$", full.names = TRUE))
    dates <- as.Date(sub(".*__(\\d{8})__.*", "\\1", basename(fs)), "%Y%m%d")
    yr <- as.integer(format(dates[1], "%Y")); doy <- as.integer(format(dates, "%j"))
    ny <- as.integer(format(as.Date(sprintf("%d-12-31", yr)), "%j"))
    days <- c(diff(doy), ny - doy[length(doy)] + 1); stopifnot(sum(days) == ny)
    nc <- nc_open(fs[1]); lat <- ncvar_get(nc, "lat"); lon <- ncvar_get(nc, "lon"); nc_close(nc)
    dlat <- abs(diff(lat)[1]); dlon <- abs(diff(lon)[1])
    al <- SF_R^2 * (dlon * pi / 180) *
      abs(sin((lat + dlat / 2) * pi / 180) - sin((lat - dlat / 2) * pi / 180))
    px <- al[which.min(abs(lat))] / SF_NVALID_FULL
    M <- matrix(0, length(lat), length(fs))
    for (i in seq_along(fs)) {
      nc <- nc_open(fs[i]); x <- ncvar_get(nc, SF_VAR)
      nv <- ncvar_get(nc, "numberofvalidvalues"); nc_close(nc)
      x[!is.finite(x)] <- NA; nv[!is.finite(nv) | nv < 0] <- 0
      M[, i] <- colSums(x * (nv * px) / 1e12, na.rm = TRUE)
    }
    list(year = yr, lat = lat, doy = doy, days = days, ndays = ny, M = M)
  }
  zips <- sort(list.files(SF_DIR, pattern = "\\.nc\\.zip$", full.names = TRUE))
  cache <- lapply(zips, function(z) { cat(sprintf("  reading %s\n", basename(z))); read_year(z) })
  saveRDS(cache, ccx_path(SF_CACHE))
  cat(sprintf("wrote cache %s\n", SF_CACHE))
}
lat <- cache[[1]]$lat

window_op <- function(mid, days, ndays) {
  half <- (days / ndays) / 2
  W <- matrix(0, nrow = length(mid), ncol = SF_NGRID)
  for (i in seq_along(mid)) {
    inw <- ((tt - (mid[i] - half[i])) %% 1) <= ((2 * half[i]) %% 1)
    W[i, inw] <- 1 / sum(inw)
  }
  W
}
roll_op <- function(W, s) {
  k <- round(s / 12 * SF_NGRID) %% SF_NGRID
  if (k == 0) W else W[, c((k + 1):SF_NGRID, seq_len(k)), drop = FALSE]
}

for (h in c("NH", "SH")) {
  sgn <- if (h == "NH") 1 else -1
  cat(sprintf("\n=== %s ===\n", h))
  yrs <- lapply(cache, function(y) {
    mid <- (y$doy - 1 + y$days / 2) / y$ndays
    inh <- if (sgn > 0) lat >= 0 else lat < 0
    fl_lat <- rowSums(y$M) * inh                 # annual NPP per lat row, this hemisphere
    agg_fl <- colSums(y$M[inh, , drop = FALSE])
    list(W = window_op(mid, y$days, y$ndays), fl_lat = fl_lat, lat = lat,
         agg = (agg_fl / y$days) / (sum(agg_fl) / y$ndays), days = y$days, ndays = y$ndays)
  })
  # w(L) and phi(L), MEASURED, per year
  wphi <- function(y, L) {
    sel <- if (sgn > 0) lat >= L else lat <= -L
    w <- y$fl_lat[sel]
    # THE CUTOFF CAN EMPTY THE HEMISPHERE. The SH holds 0.0 % of its NPP south
    # of 55, so at L = 60 the centroid is 0/0 -- and an NaN phi propagates
    # silently through ccx_insol() into the residual and kills the run at
    # `if (e1 < best1)`, several frames from the cause. That is the FINDING
    # (there is no southern boreal band), so it is returned as one.
    if (sum(w) <= 0) return(c(w = 0, phi = NA_real_))
    c(w = sum(w) / sum(y$fl_lat), phi = sum(w * lat[sel]) / sum(w))
  }
  cat(sprintf("  %-8s %8s %8s | %-22s | %-24s\n", "cutoff", "w(L)", "phi(L)",
              "A = 1 (ZERO params)", "A free (1 param)"))
  cat(sprintf("  %-8s %8s %8s | %9s %11s | %9s %8s %5s\n", "", "", "",
              "resid", "eff amp", "resid", "A", "wA"))
  for (L in SF_CUTS) {
    r <- vapply(yrs, function(y) {
      p <- wphi(y, L)
      if (!is.finite(p[["phi"]]))
        return(c(w = 0, phi = NA_real_, r1 = NA_real_, rF = NA_real_, A = NA_real_))
      S <- unitmean(ccx_insol(p[["phi"]] * sgn, tt))
      best1 <- Inf; bestF <- Inf; bestA <- NA
      for (s in SF_SHIFT) {
        Ws <- roll_op(y$W, s); B <- as.vector(Ws %*% (S - 1))
        e1 <- sum((1 + p[["w"]] * B - y$agg)^2)
        if (e1 < best1) best1 <- e1
        # A free: linear least squares on a single column, CLAMPED NON-NEGATIVE.
        # An unconstrained solve will happily return A < 0 -- an INVERTED
        # seasonal cycle, which fits better than a badly-shaped upright one and
        # is physically meaningless. Reporting that residual as if it were a fit
        # would be the worst kind of pass. Clamped to 0, a would-be-negative
        # case degenerates to the flat model and its residual says so.
        A <- max(0, sum(B * p[["w"]] * (y$agg - 1)) / sum((B * p[["w"]])^2))
        eF <- sum((1 + p[["w"]] * A * B - y$agg)^2)
        if (eF < bestF) { bestF <- eF; bestA <- A }
      }
      n <- nrow(y$W); amp <- p2p(y$agg)
      c(w = p[["w"]], phi = p[["phi"]] * sgn,
        r1 = sqrt(best1 / n) / amp, rF = sqrt(bestF / n) / amp, A = bestA)
    }, numeric(5))
    if (all(is.na(r["phi", ]))) {
      cat(sprintf("  %-8.1f %8.3f %8s | %26s | %s\n", L * sgn, 0, "--",
                  "NO NPP POLEWARD OF THIS CUT", "-- (that IS the answer)"))
      next
    }
    cat(sprintf("  %-8.1f %8.3f %8.2f | %8.1f%% %11.3f | %8.1f%% %8.2f %5.2f\n",
                L * sgn, mean(r["w", ]), mean(r["phi", ]),
                100 * mean(r["r1", ]), mean(r["w", ]),
                100 * mean(r["rF", ]), mean(r["A", ]), mean(r["w", ] * r["A", ])))
  }
  # 2-band variant: split the SEASONAL part at SF_SPLIT, both weights + centroids measured
  L2 <- 23.5
  r2 <- vapply(yrs, function(y) {
    segs <- list(c(L2, SF_SPLIT), c(SF_SPLIT, 91))
    P <- lapply(segs, function(ab) {
      sel <- if (sgn > 0) lat >= ab[1] & lat < ab[2] else lat <= -ab[1] & lat > -ab[2]
      w <- y$fl_lat[sel]
      # A band can be EMPTY -- the SH has 0.0 % of its NPP south of 55 -- and
      # sum(w * lat)/sum(w) is then 0/0. That is not an edge case to tolerate:
      # it is the finding (there is no southern boreal band), so it returns a
      # zero-weight band at a harmless latitude rather than an NaN that
      # propagates into `if (e1 < best1)` and kills the run.
      if (sum(w) <= 0) return(c(w = 0, phi = mean(ab) * sgn))
      c(w = sum(w) / sum(y$fl_lat), phi = sum(w * lat[sel]) / sum(w))
    })
    S <- vapply(P, function(p) unitmean(ccx_insol(p[["phi"]], tt)) - 1, numeric(SF_NGRID))
    ww <- vapply(P, `[[`, numeric(1), "w")
    best1 <- Inf; bestF <- Inf; skipped <- 0L
    for (s in SF_SHIFT) {
      B <- roll_op(y$W, s) %*% S
      X <- sweep(B, 2, ww, `*`)
      # A near-empty band gives X a near-zero column, and qr.solve then returns
      # a coefficient of order 1e3-1e6 WITHOUT erroring -- so tryCatch is not
      # enough and the arithmetic downstream can go non-finite. Candidates that
      # do are SKIPPED and COUNTED, never silently dropped: a two-band fit that
      # quietly evaluated three shifts out of 48 would look like a fit.
      A <- tryCatch(qr.solve(X, y$agg - 1), error = function(e) rep(NA_real_, ncol(X)))
      e1 <- sum((1 + as.vector(B %*% ww) - y$agg)^2)
      eF <- if (anyNA(A)) NA_real_ else sum((1 + as.vector(X %*% A) - y$agg)^2)
      if (!is.finite(e1) || !is.finite(eF)) { skipped <- skipped + 1L; next }
      if (e1 < best1) best1 <- e1
      if (eF < bestF) bestF <- eF
    }
    if (skipped > 0L)
      cat(sprintf("    [%d of %d shifts skipped as non-finite -- the second band carries %.3f %% of NPP]\n",
                  skipped, length(SF_SHIFT), 100 * ww[2]))
    if (!is.finite(best1) || !is.finite(bestF)) return(c(r1 = NA_real_, rF = NA_real_))
    c(r1 = sqrt(best1 / nrow(y$W)) / p2p(y$agg), rF = sqrt(bestF / nrow(y$W)) / p2p(y$agg))
  }, numeric(2))
  cat(sprintf("\n  2 bands above %g (split at %g), measured w and phi:  A=1 %.1f%%   A free %.1f%%\n",
              L2 * sgn, SF_SPLIT * sgn,
              100 * mean(r2["r1", ], na.rm = TRUE), 100 * mean(r2["rF", ], na.rm = TRUE)))
  if (anyNA(r2))
    cat(sprintf("    (%d of %d years had no admissible 2-band fit)\n",
                sum(is.na(r2["rF", ])), ncol(r2)))
}
cat("\n  BENCHMARKS on the same target: one curve with phi AND amplitude free =\n")
cat("  7.4 % (NH) / 11.5 % (SH); four bands at their centroids with A = 1 = 14.6 % / 12.9 %.\n")
cat("  'eff amp' is w(L) itself -- the amplitude factor this model IMPLIES for a\n")
cat("  single equivalent curve, to be read against the fitted 0.49 (phi 75) and\n")
cat("  0.96 (phi 50).\n")
cat("\n  A = 0 in the 'A free' column means the unconstrained least-squares solve\n")
cat("  wanted a NEGATIVE amplitude -- an inverted seasonal cycle -- and was\n")
cat("  clamped. Those rows have no admissible fit; their residual is the flat\n")
cat("  model's, and it is reported rather than hidden.\n")
