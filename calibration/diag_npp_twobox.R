# =====================================================================
# diag_npp_twobox.R -- THE TWO-BOX NPP DRIVER, TESTED AS ASKED
#
# THE QUESTION (Marcus 2026-08-20e): "So a single NPP box with a seasonal cycle
# based on 75 degrees outperforms a dual NPP box where 0-60 has a weak seasonal
# cycle and 60-90 has a strong one?"
#
# IT IS A FAIR CHALLENGE AND THE ANSWER IS NO -- that configuration was never
# run. What diag_npp_bands.R and diag_npp_seasonal_fraction.R tested was:
#   * FOUR boxes at 0/23.5/40/55/90, amplitudes free       -> 7.1 % (BEAT 7.4 %)
#   * TWO boxes above 23.5 with 0-23.5 DELETED             -> 7.5 %
#   * ONE box, phi and amplitude free                      -> 7.4 %
# The four-box model already **outperformed** the single curve; the claim was
# that it did so by 0.3 points for two extra parameters, which is a statement
# about SIZE, not about direction, and "buys nothing" over-compressed it.
#
# Marcus' configuration is neither of those: TWO boxes SPANNING THE WHOLE
# hemisphere -- 0-60 keeping its weak cycle rather than being deleted, 60-90
# carrying the strong one. That is the natural two-parameter member of the
# family, and it is the one with the clean physical reading: a water-driven
# low-latitude pool and a light-driven boreal pool.
#
# WEIGHTS AND CENTROIDS ARE MEASURED, never fitted. Amplitudes are tested BOTH
# fixed at 1 (a zero-parameter driver) and free (one per box). The split is
# scanned, because 60 is a proposal and not a measurement.
#
# SHAPE ONLY. This scores the observed 8-day productivity shape. Whether the CO2
# and d13C records agree is a separate question that needs a CORE CHANGE to
# answer -- both cores currently carry exactly one insolation latitude per
# hemisphere -- which is precisely the decision this diagnostic exists to inform.
#
# Usage:  Rscript calibration/diag_npp_twobox.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)

TB_CACHE <- "data/obs_npp_latwindow.rds"
TB_NGRID <- 720
TB_SHIFT <- seq(0, 11.75, by = 0.25)
TB_SPLITS <- c(40, 45, 50, 55, 60, 65, 70)
TB_ONE_REF <- c(NH = 7.4, SH = 11.5)      # one box, phi + amplitude free
TB_FOUR_REF <- c(NH = 7.1, SH = 10.5)     # four boxes at 0/23.5/40/55/90, A free

stopifnot(file.exists(ccx_path(TB_CACHE)))
cache <- readRDS(ccx_path(TB_CACHE)); lat <- cache[[1]]$lat
tt <- (seq_len(TB_NGRID) - 0.5) / TB_NGRID
p2p <- function(x) max(x) - min(x); unitmean <- function(v) v / mean(v)
window_op <- function(mid, days, ndays) {
  half <- (days / ndays) / 2
  W <- matrix(0, length(mid), TB_NGRID)
  for (i in seq_along(mid)) {
    inw <- ((tt - (mid[i] - half[i])) %% 1) <= ((2 * half[i]) %% 1)
    W[i, inw] <- 1 / sum(inw)
  }
  W
}
roll_op <- function(W, s) {
  k <- round(s / 12 * TB_NGRID) %% TB_NGRID
  if (k == 0) W else W[, c((k + 1):TB_NGRID, seq_len(k)), drop = FALSE]
}

for (h in c("NH", "SH")) {
  sgn <- if (h == "NH") 1 else -1
  yrs <- lapply(cache, function(y) {
    inh <- if (sgn > 0) lat >= 0 else lat < 0
    fl <- colSums(y$M[inh, , drop = FALSE])
    list(W = window_op((y$doy - 1 + y$days / 2) / y$ndays, y$days, y$ndays),
         fl_lat = rowSums(y$M) * inh,
         agg = (fl / y$days) / (sum(fl) / y$ndays))
  })
  cat(sprintf("\n=== %s ===  two boxes spanning the WHOLE hemisphere\n", h))
  cat(sprintf("  %-7s | %6s %7s %6s %7s | %9s | %9s %6s %6s\n",
              "split", "w_lo", "phi_lo", "w_hi", "phi_hi",
              "A = 1", "A free", "A_lo", "A_hi"))
  for (L in TB_SPLITS) {
    r <- vapply(yrs, function(y) {
      segs <- list(c(0, L), c(L, 91))
      P <- lapply(segs, function(ab) {
        sel <- if (sgn > 0) lat >= ab[1] & lat < ab[2] else lat <= -ab[1] & lat > -ab[2]
        w <- y$fl_lat[sel]
        if (sum(w) <= 0) return(c(w = 0, phi = NA_real_))
        c(w = sum(w) / sum(y$fl_lat), phi = sum(w * lat[sel]) / sum(w))
      })
      ww <- vapply(P, `[[`, numeric(1), "w"); ph <- vapply(P, `[[`, numeric(1), "phi")
      if (anyNA(ph)) return(rep(NA_real_, 8))
      S <- vapply(ph, function(z) unitmean(ccx_insol(z, tt)) - 1, numeric(TB_NGRID))
      b1 <- Inf; bF <- Inf; bA <- c(NA, NA)
      for (s in TB_SHIFT) {
        B <- roll_op(y$W, s) %*% S
        e1 <- sum((1 + as.vector(B %*% ww) - y$agg)^2)
        X <- sweep(B, 2, ww, `*`)
        # NON-NEGATIVE least squares, solved exactly for two columns. An
        # unconstrained solve returns A_lo ~ -8, i.e. the low-latitude box run
        # BACKWARDS as a shape-corrector -- which fits, and which no
        # productivity box can do. With two columns NNLS is: solve; if a
        # coefficient is negative, clamp it to zero and re-solve the other.
        A <- tryCatch(qr.solve(X, y$agg - 1), error = function(e) rep(NA_real_, 2))
        if (!anyNA(A) && any(A < 0)) {
          cand <- lapply(1:2, function(j) {
            a <- c(0, 0); a[j] <- sum(X[, j] * (y$agg - 1)) / sum(X[, j]^2)
            if (a[j] < 0) a[j] <- 0
            a
          })
          A <- cand[[which.min(vapply(cand, function(a)
            sum((1 + as.vector(X %*% a) - y$agg)^2), numeric(1)))]]
        }
        eF <- if (anyNA(A)) NA_real_ else sum((1 + as.vector(X %*% A) - y$agg)^2)
        if (is.finite(e1) && e1 < b1) b1 <- e1
        if (is.finite(eF) && eF < bF) { bF <- eF; bA <- A }
      }
      amp <- p2p(y$agg); n <- nrow(y$W)
      c(ww[1], ph[1], ww[2], ph[2], sqrt(b1 / n) / amp, sqrt(bF / n) / amp, bA[1], bA[2])
    }, numeric(8))
    if (all(is.na(r[2, ]))) {
      cat(sprintf("  %-7.0f | the high box is EMPTY at this split -- not a two-box model\n", L * sgn))
      next
    }
    m <- rowMeans(r, na.rm = TRUE)
    cat(sprintf("  %-7.0f | %6.3f %7.2f %6.3f %7.2f | %8.1f%% | %8.1f%% %6.2f %6.2f\n",
                L * sgn, m[1], m[2], m[3], m[4], 100 * m[5], 100 * m[6], m[7], m[8]))
  }
  cat(sprintf("  BENCHMARKS: one box (phi + A free) %.1f%% | four boxes (A free) %.1f%%\n",
              TB_ONE_REF[[h]], TB_FOUR_REF[[h]]))
}
# ---------------------------------------------------------------------
# RE-CHECK THE FOUR-BOX NUMBER, which was reported UNCONSTRAINED
# ---------------------------------------------------------------------
# diag_npp_bands.R's headline "four boxes, amplitudes free = 7.1 %" came from an
# unconstrained qr.solve. The two-box scan above has just shown that
# unconstrained solves in this family reach for NEGATIVE amplitudes -- a
# productivity box run backwards through the year, which fits and cannot exist.
# So the four-box number is re-derived here under NON-NEGATIVITY, exactly, by
# enumerating all 2^4 active sets. If it moves, the earlier number was an
# artifact of the constraint being absent and must be withdrawn.
nnls_exact <- function(X, y) {
  p <- ncol(X); best <- NULL; bE <- Inf
  for (m in 0:(2^p - 1)) {
    keep <- which(bitwAnd(m, 2^(seq_len(p) - 1)) > 0)
    a <- rep(0, p)
    if (length(keep)) {
      sol <- tryCatch(qr.solve(X[, keep, drop = FALSE], y), error = function(e) NULL)
      if (is.null(sol) || anyNA(sol) || any(sol < 0)) next
      a[keep] <- sol
    }
    e <- sum((X %*% a - y)^2)
    if (is.finite(e) && e < bE) { bE <- e; best <- a }
  }
  list(a = best, sse = bE)
}
TB_EDGES4 <- c(0, 23.5, 40, 55, 90)
cat("\n=== FOUR BOXES, unconstrained vs non-negative ===\n")
for (h in c("NH", "SH")) {
  sgn <- if (h == "NH") 1 else -1
  r <- vapply(cache, function(y) {
    inh <- if (sgn > 0) lat >= 0 else lat < 0
    fl <- colSums(y$M[inh, , drop = FALSE]); fl_lat <- rowSums(y$M) * inh
    W <- window_op((y$doy - 1 + y$days / 2) / y$ndays, y$days, y$ndays)
    agg <- (fl / y$days) / (sum(fl) / y$ndays)
    P <- lapply(seq_len(length(TB_EDGES4) - 1), function(k) {
      ab <- TB_EDGES4[c(k, k + 1)]; if (k == length(TB_EDGES4) - 1) ab[2] <- 91
      sel <- if (sgn > 0) lat >= ab[1] & lat < ab[2] else lat <= -ab[1] & lat > -ab[2]
      w <- fl_lat[sel]
      if (sum(w) <= 0) return(c(w = 0, phi = mean(ab) * sgn))
      c(w = sum(w) / sum(fl_lat), phi = sum(w * lat[sel]) / sum(w))
    })
    ww <- vapply(P, `[[`, numeric(1), "w"); ph <- vapply(P, `[[`, numeric(1), "phi")
    S <- vapply(ph, function(z) unitmean(ccx_insol(z, tt)) - 1, numeric(TB_NGRID))
    bU <- Inf; bN <- Inf; aN <- rep(NA_real_, 4)
    for (s in TB_SHIFT) {
      X <- sweep(roll_op(W, s) %*% S, 2, ww, `*`)
      au <- tryCatch(qr.solve(X, agg - 1), error = function(e) NULL)
      if (!is.null(au) && !anyNA(au)) {
        e <- sum((1 + X %*% au - agg)^2); if (is.finite(e) && e < bU) bU <- e
      }
      nn <- nnls_exact(X, agg - 1)
      if (is.finite(nn$sse) && nn$sse < bN) { bN <- nn$sse; aN <- nn$a }
    }
    c(sqrt(bU / nrow(W)) / p2p(agg), sqrt(bN / nrow(W)) / p2p(agg), aN)
  }, numeric(6))
  cat(sprintf("  %s: UNCONSTRAINED %.1f%%   NON-NEGATIVE %.1f%%   A = %s\n", h,
              100 * mean(r[1, ]), 100 * mean(r[2, ]),
              paste(sprintf("%.2f", rowMeans(r[3:6, , drop = FALSE])), collapse = " ")))
}
cat("  A non-negative solution that sets boxes to ZERO has DELETED them -- the\n")
cat("  multi-box model is then the cutoff model wearing more parameters.\n")

cat("\n  A_lo and A_hi are the fitted amplitude factors of the low- and high-latitude\n")
cat("  boxes, RELATIVE TO EACH BOX'S OWN insolation curve. A_hi near 1 means the\n")
cat("  boreal box really does follow its own light cycle; A_lo far from 1 means the\n")
cat("  low-latitude box does not, and is being used as a shape-filler.\n")
