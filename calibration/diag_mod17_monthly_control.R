# =====================================================================
# diag_mod17_monthly_control.R -- THE WINDOW CONTROL FOR diag_sh_pair_nonmodis.R
#
# WHY THIS EXISTS. diag_sh_pair_nonmodis.R fits CMIP6 npp on 12 MONTHLY windows;
# diag_seas_rectification.R fits MOD17 on 46 8-DAY windows. The two SH answers
# differ (MOD17 argmin -30ish and near-flat; CMIP6 argmin -50 with a 3.25 pp
# swing), and a monthly window SMOOTHS the target more than an 8-day one -- which
# can move both the fitted amplitude and the argmin on its own.
#
# ⚠ SO THE PRODUCT DIFFERENCE AND THE WINDOW DIFFERENCE ARE CONFOUNDED, and the
# comparison is not LIKE-FOR-LIKE until one of them is held fixed.
# [[like_for_like_forcing]] -- this class of error has inverted a reading three
# times on one dataset in this project's history.
#
# WHAT THIS DOES. Aggregates the MOD17 8-day shapes to MONTHLY and pushes them
# through the IDENTICAL monthly pipeline used for CMIP6. Then:
#   MOD17-monthly ~ MOD17-8day   =>  the window is innocent, the difference is
#                                    the PRODUCT, and the CMIP6 answer stands.
#   MOD17-monthly ~ CMIP6        =>  the window did it, and the "non-MODIS
#                                    product disagrees" reading is an artefact.
#
# Usage:  Rscript calibration/diag_mod17_monthly_control.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)

MC_NGRID  <- 720
MC_SHIFTS <- seq(0, 11.75, by = 0.25)
MC_AMP    <- seq(0.05, 4, by = 0.01)
MC_PHI_SH <- c(-15.12, -15.75, -20, -25, -30, -40, -50, -60)
MC_PHI_NH <- c(38.35, 45, 50, 55, 65, 75, 85)

tt <- (seq_len(MC_NGRID) - 0.5) / MC_NGRID
unitmean <- function(v) v / mean(v)
p2p <- function(x) max(x) - min(x)

mdays <- c(31,28.25,31,30,31,30,31,31,30,31,30,31)
medge <- c(0, cumsum(mdays)) / sum(mdays)
Wmon <- matrix(0, 12, MC_NGRID)
for (i in 1:12) { inw <- tt > medge[i] & tt <= medge[i+1]; Wmon[i, inw] <- 1/sum(inw) }

best_over_shift <- function(W, bank, target) {
  best <- list(sse = Inf)
  for (s in MC_SHIFTS) {
    k <- round(s / 12 * MC_NGRID) %% MC_NGRID
    M <- (if (k == 0) W else W[, c((k+1):MC_NGRID, seq_len(k)), drop = FALSE]) %*% bank
    e <- colSums((M - target)^2); j <- which.min(e)
    if (e[j] < best$sse) best <- list(sse = e[j], j = j, shift_mo = s)
  }
  best
}

ss <- readRDS(ccx_path("data", "obs_npp_seasonal_shape.rds"))

# ---- 8-day -> monthly, AREA-CONSERVING (not nearest-midpoint) -------
# Each 8-day composite is an accumulation over its own window; a month's value is
# the DURATION-WEIGHTED mean of the composites overlapping it. Assigning each
# composite to the month containing its midpoint would drop the fraction of a
# composite that straddles a month boundary -- ~13 % of them do.
to_monthly <- function(mid, vals) {
  d    <- diff(c(mid, mid[1] + 1))
  lo   <- mid - d/2; hi <- mid + d/2
  out  <- numeric(12)
  for (i in 1:12) {
    a <- medge[i]; b <- medge[i+1]
    ov <- pmax(0, pmin(hi, b) - pmax(lo, a)) +
          pmax(0, pmin(hi + 1, b) - pmax(lo + 1, a)) +
          pmax(0, pmin(hi - 1, b) - pmax(lo - 1, a))
    out[i] <- sum(ov * vals) / sum(ov)
  }
  out
}

profile_one <- function(tgt, phis) {
  res <- amp <- numeric(length(phis))
  for (ip in seq_along(phis)) {
    v <- unitmean(ccx_insol(phis[ip], tt))
    bank <- vapply(MC_AMP, function(A) 1 + A*(v - 1), numeric(MC_NGRID))
    f <- best_over_shift(Wmon, bank, tgt)
    res[ip] <- sqrt(f$sse / 12) / p2p(tgt); amp[ip] <- MC_AMP[f$j]
  }
  list(res = res, amp = amp)
}

cat("=== MOD17, AGGREGATED TO MONTHLY, THROUGH THE CMIP6 PIPELINE ===\n")
cat("(mean over the 5 product years; compare to diag_seas_rectification.R's 8-day row)\n")
for (nm in names(ss$fits)) {
  x <- ss$fits[[nm]]
  phis <- if (x$hemisphere == "NH") MC_PHI_NH else MC_PHI_SH
  R <- A <- matrix(NA_real_, length(x$years), length(phis))
  for (iy in seq_along(x$years)) {
    tgt <- unitmean(to_monthly(x$mid, x$shape_by_year[, iy]))
    pr  <- profile_one(tgt, phis); R[iy, ] <- pr$res; A[iy, ] <- pr$amp
  }
  rm_ <- colMeans(R); am <- colMeans(A)
  cat(sprintf("\n  %-10s", nm)); cat(sprintf("%9g", phis)); cat("\n")
  cat(sprintf("  %-10s", "residual")); cat(sprintf("%8.1f%%", 100*rm_)); cat("\n")
  cat(sprintf("  %-10s", "fitted A")); cat(sprintf("%9.2f", am)); cat("\n")
  cat(sprintf("  swing %.2f pp | A range %.2f -> %.2f (%.2fx) | argmin phi = %g\n",
              100*(max(rm_)-min(rm_)), max(am), min(am), max(am)/min(am), phis[which.min(rm_)]))
}
cat("\n=== READ ===\n")
cat("  MOD17 8-day (diag_seas_rectification.R): NH argmin 75, swing 5.2 pp;\n")
cat("                                           SH argmin ~-40, swing 1.0 pp, A 0.97->0.30.\n")
cat("  CMIP6 monthly (diag_sh_pair_nonmodis.R): NH argmin 75, swing 5.22 pp;\n")
cat("                                           SH argmin -50, swing 3.25 pp, A 1.90->0.35.\n")
cat("  If MOD17-monthly SH tracks MOD17-8day, the window is innocent.\n")
