# =====================================================================
# diag_npp_bands.R -- WOULD SPLITTING THE NH LAND INTO LATITUDE BANDS
#                     ACTUALLY HELP?
#
# THE PROPOSAL (Marcus 2026-08-20e): "It seems like the problem is that we are
# trying to apply a single insolation curve to some very different ecosystems.
# The atmosphere can still be at the hemispheric level, but the NPP can be a bit
# more complicated."
#
# THE STATE OF PLAY THIS ANSWERS. One insolation curve leaves **11.4 %** of the
# observed NH seasonal shape unexplained (diag_seas_rectification.R), and the
# curve the CO2 record prefers sits at 75 N -- 40.7 degrees poleward of the NH
# NPP centroid at 34.29. Both facts are consistent with an AGGREGATION failure:
# a boreal forest that shuts off in winter and a tropical forest that barely
# varies are being represented by one shape.
#
# THE TEST THAT DECIDES IT, and it needs no model runs. If the misfit is an
# aggregation artefact, then **each band on its own should be well described by
# its own insolation curve**, and the residual should collapse when the bands
# are fitted separately. If instead each band is individually badly matched,
# the premise ("productivity follows insolation") is what is wrong and splitting
# buys nothing but parameters. Those two outcomes are distinguishable HERE, at
# the cost of re-reading five years of 8-day data.
#
# THREE MODELS ARE SCORED AGAINST THE SAME OBSERVED NH AGGREGATE:
#   1BAND      one curve, phi and amplitude free           -- the incumbent, 7.4 %
#   NBAND-A1   sum over bands, each at its OWN NPP centroid latitude, amplitudes
#              FIXED AT 1 -- i.e. pure spatial aggregation with NO free
#              parameters at all. This is the honest "just do it properly"
#              version and it is the one most likely to be assumed to work.
#   NBAND-Afree same, with one free amplitude PER BAND.
# Band WEIGHTS are measured NPP shares, never fitted. A common time shift is
# free in all three (seas_lag_p would absorb it).
#
# WHY THE SH IS COMPUTED TOO, despite Marcus expecting little: "probably
# wouldn't make as much of a difference" is a prediction, and it costs one more
# loop to check it rather than assume it.
#
# Usage:  Rscript calibration/diag_npp_bands.R
# =====================================================================
suppressPackageStartupMessages(library(ncdf4))
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)

NB_DIR   <- "data-raw/downloads/mod17_gpp8d"
NB_OUT   <- "data/obs_npp_bands.rds"
NB_VAR   <- "net_photosynthesis"     # PsnNet -- closer to NPP than gpp; see DATA.md 3d
NB_R     <- 6371000
NB_NVALID_FULL <- 14400
NB_NGRID <- 720
NB_PHI   <- seq(2, 89, by = 0.5)
NB_AMP   <- seq(0.05, 4, by = 0.025)
NB_SHIFT <- seq(0, 11.75, by = 0.25)
# Ecosystem-motivated edges, not equal-area: tropics / warm temperate + the
# world's deserts / cool temperate / boreal. The boreal cut at 55 is where the
# growing season starts being light- and frost-limited rather than water-limited.
NB_EDGES <- c(0, 23.5, 40, 55, 90)

tt  <- (seq_len(NB_NGRID) - 0.5) / NB_NGRID
p2p <- function(x) max(x) - min(x)
unitmean <- function(v) v / mean(v)
INS <- vapply(NB_PHI, function(phi) unitmean(ccx_insol(phi, tt)), numeric(NB_NGRID))

window_op <- function(mid, days, ndays) {
  half <- (days / ndays) / 2
  W <- matrix(0, nrow = length(mid), ncol = NB_NGRID)
  for (i in seq_along(mid)) {
    inw <- ((tt - (mid[i] - half[i])) %% 1) <= ((2 * half[i]) %% 1)
    W[i, inw] <- 1 / sum(inw)
  }
  W
}
roll_op <- function(W, s) {
  k <- round(s / 12 * NB_NGRID) %% NB_NGRID
  if (k == 0) W else W[, c((k + 1):NB_NGRID, seq_len(k)), drop = FALSE]
}

# ---------------------------------------------------------------------
# 1. Read: latitude x window flux, per year
# ---------------------------------------------------------------------
read_year <- function(zp) {
  tmp <- file.path(tempdir(), paste0("nb_", basename(zp)))
  unlink(tmp, recursive = TRUE); dir.create(tmp, recursive = TRUE)
  utils::unzip(zp, exdir = tmp, junkpaths = TRUE); on.exit(unlink(tmp, recursive = TRUE))
  fs <- sort(list.files(tmp, pattern = "\\.nc$", full.names = TRUE))
  dates <- as.Date(sub(".*__(\\d{8})__.*", "\\1", basename(fs)), "%Y%m%d")
  yr <- as.integer(format(dates[1], "%Y")); doy <- as.integer(format(dates, "%j"))
  ny <- as.integer(format(as.Date(sprintf("%d-12-31", yr)), "%j"))
  days <- c(diff(doy), ny - doy[length(doy)] + 1); stopifnot(sum(days) == ny)
  nc <- nc_open(fs[1]); lat <- ncvar_get(nc, "lat"); lon <- ncvar_get(nc, "lon"); nc_close(nc)
  dlat <- abs(diff(lat)[1]); dlon <- abs(diff(lon)[1])
  al <- NB_R^2 * (dlon * pi / 180) *
    abs(sin((lat + dlat / 2) * pi / 180) - sin((lat - dlat / 2) * pi / 180))
  px <- al[which.min(abs(lat))] / NB_NVALID_FULL
  M <- matrix(0, length(lat), length(fs))
  for (i in seq_along(fs)) {
    nc <- nc_open(fs[i]); x <- ncvar_get(nc, NB_VAR)
    nv <- ncvar_get(nc, "numberofvalidvalues"); nc_close(nc)
    x[!is.finite(x)] <- NA; nv[!is.finite(nv) | nv < 0] <- 0
    M[, i] <- colSums(x * (nv * px) / 1e12, na.rm = TRUE)
  }
  list(year = yr, lat = lat, doy = doy, days = days, ndays = ny, M = M)
}
zips <- sort(list.files(NB_DIR, pattern = "\\.nc\\.zip$", full.names = TRUE))
yrs  <- lapply(zips, function(z) { cat(sprintf("  reading %s\n", basename(z))); read_year(z) })
lat  <- yrs[[1]]$lat

# ---------------------------------------------------------------------
# 2. Per-band shapes, and the single-band vs multi-band comparison
# ---------------------------------------------------------------------
fit1 <- function(W, target, bank) {          # best (column, shift) for one bank
  best <- list(sse = Inf)
  for (s in NB_SHIFT) {
    M <- roll_op(W, s) %*% bank
    e <- colSums((M - target)^2); j <- which.min(e)
    if (e[j] < best$sse) best <- list(sse = e[j], j = j, s = s, fit = M[, j])
  }
  best
}
bankC <- do.call(cbind, lapply(NB_AMP, function(A) 1 + A * (INS - 1)))   # (phi, A) grid

out <- list()
for (h in c("NH", "SH")) {
  sgn <- if (h == "NH") 1 else -1
  edges <- NB_EDGES * sgn
  cat(sprintf("\n=== %s ===\n", h))
  per_year <- lapply(yrs, function(y) {
    mid <- (y$doy - 1 + y$days / 2) / y$ndays
    W <- window_op(mid, y$days, y$ndays)
    bands <- lapply(seq_len(length(edges) - 1), function(k) {
      lo <- min(edges[k], edges[k + 1]); hi <- max(edges[k], edges[k + 1])
      sel <- lat >= lo & lat < hi & (if (sgn > 0) lat >= 0 else lat < 0)
      fl <- colSums(y$M[sel, , drop = FALSE])
      w  <- rowMeans(y$M[sel, , drop = FALSE]) * length(y$days)   # per-lat annual weight
      list(sel = sel, flux = fl, total = sum(fl),
           centroid = sum(w * lat[sel]) / sum(w),
           rate = (fl / y$days) / (sum(fl) / y$ndays))
    })
    tot <- sum(vapply(bands, `[[`, numeric(1), "total"))
    agg_fl <- Reduce(`+`, lapply(bands, `[[`, "flux"))
    list(W = W, bands = bands, tot = tot,
         agg = (agg_fl / y$days) / (sum(agg_fl) / y$ndays),
         wts = vapply(bands, `[[`, numeric(1), "total") / tot)
  })

  cat(sprintf("  %-14s %8s %9s %9s %9s %9s %9s\n",
              "band", "NPP %", "centroid", "own p2p", "fit phi", "fit A", "resid"))
  nb <- length(NB_EDGES) - 1
  for (k in seq_len(nb)) {
    w  <- mean(vapply(per_year, function(p) p$wts[k], numeric(1)))
    ct <- mean(vapply(per_year, function(p) p$bands[[k]]$centroid, numeric(1)))
    r  <- vapply(seq_along(per_year), function(i) {
      p <- per_year[[i]]; tg <- p$bands[[k]]$rate
      f <- fit1(p$W, tg, bankC)
      c(p2p = p2p(tg), phi = NB_PHI[((f$j - 1) %% length(NB_PHI)) + 1] * sgn,
        A = NB_AMP[(f$j - 1) %/% length(NB_PHI) + 1],
        res = sqrt(f$sse / nrow(p$W)) / p2p(tg))
    }, numeric(4))
    cat(sprintf("  %-14s %7.1f%% %9.2f %9.3f %9.2f %9.2f %8.1f%%\n",
                sprintf("%g..%g", NB_EDGES[k] * sgn, NB_EDGES[k + 1] * sgn),
                100 * w, ct, mean(r["p2p", ]), mean(r["phi", ]), mean(r["A", ]),
                100 * mean(r["res", ])))
  }

  # --- the three whole-hemisphere models ---
  score <- function(kind) vapply(seq_along(per_year), function(i) {
    p <- per_year[[i]]; tg <- p$agg
    if (kind == "1band") {
      f <- fit1(p$W, tg, bankC); return(sqrt(f$sse / nrow(p$W)) / p2p(tg))
    }
    # N-band: each band at its own NPP centroid; amplitudes fixed at 1, or fitted
    S <- vapply(seq_len(nb), function(k)
      unitmean(ccx_insol(p$bands[[k]]$centroid, tt)), numeric(NB_NGRID))
    best <- Inf
    for (s in NB_SHIFT) {
      Ws <- roll_op(p$W, s)
      B  <- Ws %*% S                                        # windows x bands
      if (kind == "Nband1") {
        m <- as.vector(B %*% p$wts); e <- sum((m - tg)^2)
      } else {
        # amplitudes free: m = sum_k w_k (1 + A_k (S_k - 1)) = 1 + sum_k w_k A_k (S_k - 1)
        # LINEAR in A, so it is a least-squares solve, not a grid search.
        X <- sweep(B - 1, 2, p$wts, `*`)
        A <- tryCatch(qr.solve(X, tg - 1), error = function(e) rep(1, nb))
        m <- as.vector(1 + X %*% A); e <- sum((m - tg)^2)
      }
      if (e < best) best <- e
    }
    sqrt(best / nrow(p$W)) / p2p(tg)
  }, numeric(1))

  s1 <- mean(score("1band")); sN1 <- mean(score("Nband1")); sNf <- mean(score("Nfree"))
  cat(sprintf("\n  WHOLE-HEMISPHERE FIT to the observed aggregate (rms resid / obs p2p):\n"))
  cat(sprintf("    1 band, phi + amplitude free            %6.1f%%   (2 params)\n", 100 * s1))
  cat(sprintf("    %d bands at NPP centroids, amplitudes = 1 %5.1f%%   (0 params)\n", nb, 100 * sN1))
  cat(sprintf("    %d bands at NPP centroids, amplitudes free %5.1f%%   (%d params)\n",
              nb, 100 * sNf, nb))
  out[[h]] <- list(one = s1, nband_fixed = sN1, nband_free = sNf, edges = NB_EDGES * sgn)
}

saveRDS(list(bands = out, edges = NB_EDGES, var = NB_VAR,
             note = paste("Does splitting the hemisphere's NPP into latitude bands remove the",
                          "single-curve residual? Built by calibration/diag_npp_bands.R from",
                          "MOD17A2HGF 8-day PsnNet.")), NB_OUT)
cat(sprintf("\nwrote %s\n", NB_OUT))
cat("\nHOW TO READ THIS. If the per-band residuals are much SMALLER than the\n")
cat("single-curve 11 %, the misfit is an AGGREGATION artefact and banding is the\n")
cat("right fix. If each band is individually just as badly matched, the premise\n")
cat("-- productivity follows insolation -- is what is wrong, and banding buys\n")
cat("parameters rather than physics.\n")
