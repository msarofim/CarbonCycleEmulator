# =====================================================================
# diag_sh_pair_nonmodis.R -- DOES A NON-MODIS PRODUCT BREAK THE (phi, A) RIDGE,
#                            OR LAND ON IT?
#
# WHY THIS EXISTS. 2026-08-27l measured that the SH (shape, size) pair is a FLAT
# RIDGE: across phi = -15.75 to -50 the MOD17 shape residual moves 12.9 -> 11.9 %
# (one percentage point) while the fitted amplitude moves 0.97 -> 0.30 (3.2x).
# So `SEAS_NPP_AMP_SH` = 0.5027 is one point on a ridge, not a pinned measurement,
# and the 1.4x GPP/PsnNet bracket that 27i/27j/decision-(ii) argued about is
# SMALLER than the degeneracy. Marcus ruled: re-derive off a non-MODIS product,
# and MEASURE THROUGH BOTH BASES BEFORE CHOOSING ONE (2026-08-27).
#
# ⚠ THE QUESTION IS NOT "WHAT NUMBER DOES THE NEW PRODUCT GIVE". A replacement
# product fitted onto the same insolation basis lands on the same ridge and
# returns a new number without pinning anything. The question is whether the
# RIDGE IS A PROPERTY OF MOD17 OR A PROPERTY OF THE SH.
#
# ⚠⚠ THE NH IS THE POWER CHECK AND IT IS NOT OPTIONAL. A flat SH row means
# nothing unless the SAME pipeline on the SAME product reproduces the NH's sharp
# interior optimum near phi = 75. If the NH comes out flat too, the flatness is
# in this script, not in the hemisphere. [[no_power_null]] [[mutation_test_gates]]
#
# PRODUCT: CMIP6 `npp` (Lmon, historical), 1995-2014, one member per model,
# hemispheric totals weighted by areacella x sftlf. Process land models, no
# satellite in the chain, so independent of MOD17's LUE algorithm -- and the only
# candidate that IS NPP rather than a GPP proxy or a net flux.
# ⚠ THESE ARE MODELS, NOT OBSERVATIONS. Accepted by Marcus for a pedagogical
# tool; may NOT be described as an observational constraint.
#
# THE SPREAD IS ACROSS MODELS, NOT YEARS -- structural, not interannual.
#
# Usage:  Rscript calibration/diag_sh_pair_nonmodis.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)

SP_CMIP  <- ccx_path("data-raw/downloads", "cmip6_npp_seasonal_shape.csv")
SP_MOD17 <- ccx_path("data", "obs_npp_seasonal_shape.rds")
SP_NGRID <- 720
SP_SHIFTS <- seq(0, 11.75, by = 0.25)
SP_AMP    <- seq(0.05, 4, by = 0.01)
# The phi rows REPORTED. Same values as diag_seas_rectification.R so the two
# tables can be read side by side; -15.12 is the MEASURED SH NPP centroid.
SP_PHI_SH <- c(-15.12, -15.75, -20, -25, -30, -40, -50, -60)
SP_PHI_NH <- c(38.35, 45, 50, 55, 65, 75, 85)

tt <- (seq_len(SP_NGRID) - 0.5) / SP_NGRID
unitmean <- function(v) v / mean(v)
p2p <- function(x) max(x) - min(x)

# Monthly window operator: each observation is a MONTHLY MEAN, so the model shape
# must be integrated over the month, never sampled at its midpoint. Same argument
# as build_npp_seasonal_shape.R's 8-day windows; this project has been bitten by
# point-sampling quantisation before. [[analytic_pulse_mean]]
mdays <- c(31,28.25,31,30,31,30,31,31,30,31,30,31)
medge <- c(0, cumsum(mdays)) / sum(mdays)
Wmon <- matrix(0, 12, SP_NGRID)
for (i in 1:12) { inw <- tt > medge[i] & tt <= medge[i+1]; Wmon[i, inw] <- 1 / sum(inw) }
stopifnot(abs(rowSums(Wmon) - 1) < 1e-12)

best_over_shift <- function(W, bank, target) {
  best <- list(sse = Inf)
  for (s in SP_SHIFTS) {
    k <- round(s / 12 * SP_NGRID) %% SP_NGRID
    M <- (if (k == 0) W else W[, c((k+1):SP_NGRID, seq_len(k)), drop = FALSE]) %*% bank
    e <- colSums((M - target)^2); j <- which.min(e)
    if (e[j] < best$sse) best <- list(sse = e[j], j = j, shift_mo = s)
  }
  best
}

# ---- load the CMIP6 climatologies ----------------------------------
d <- read.csv(SP_CMIP, stringsAsFactors = FALSE)
sp <- strsplit(d$series, "|", fixed = TRUE)
d$hemi <- vapply(sp, `[`, "", 1); d$model <- vapply(sp, `[`, "", 2)
models <- sort(unique(d$model))
cat(sprintf("CMIP6 npp Lmon historical: %d models\n\n", length(models)))

get_shape <- function(h, m) {
  x <- d[d$hemi == h & d$model == m, ]
  x <- x[order(x$month), "value"]
  if (length(x) != 12 || any(!is.finite(x)) || mean(x) <= 0) return(NULL)
  unitmean(x)                      # NPP is strictly positive: unit-mean is DEFINED
}

# ---- FORM C: residual and fitted A at each phi, per model ----------
profile_hemi <- function(h, phis) {
  res <- matrix(NA_real_, length(models), length(phis),
                dimnames = list(models, as.character(phis)))
  amp <- res
  for (im in seq_along(models)) {
    tgt <- get_shape(h, models[im]); if (is.null(tgt)) next
    for (ip in seq_along(phis)) {
      v <- unitmean(ccx_insol(phis[ip], tt))
      bank <- vapply(SP_AMP, function(A) 1 + A * (v - 1), numeric(SP_NGRID))
      f <- best_over_shift(Wmon, bank, tgt)
      res[im, ip] <- sqrt(f$sse / 12) / p2p(tgt)
      amp[im, ip] <- SP_AMP[f$j]
    }
  }
  list(res = res, amp = amp)
}

report <- function(lab, pr, phis) {
  cat(sprintf("\n=== %s : Form C, A re-optimised at every phi ===\n", lab))
  cat(sprintf("  %-14s", "phi")); for (p in phis) cat(sprintf("%9g", p)); cat("\n")
  md <- apply(pr$res, 2, median, na.rm = TRUE)
  cat(sprintf("  %-14s", "residual med")); for (v in md) cat(sprintf("%8.1f%%", 100*v)); cat("\n")
  cat(sprintf("  %-14s", "  IQR lo")); for (v in apply(pr$res,2,quantile,0.25,na.rm=TRUE)) cat(sprintf("%8.1f%%", 100*v)); cat("\n")
  cat(sprintf("  %-14s", "  IQR hi")); for (v in apply(pr$res,2,quantile,0.75,na.rm=TRUE)) cat(sprintf("%8.1f%%", 100*v)); cat("\n")
  ma <- apply(pr$amp, 2, median, na.rm = TRUE)
  cat(sprintf("  %-14s", "fitted A med")); for (v in ma) cat(sprintf("%9.2f", v)); cat("\n")
  cat(sprintf("  %-14s", "  A IQR lo")); for (v in apply(pr$amp,2,quantile,0.25,na.rm=TRUE)) cat(sprintf("%9.2f", v)); cat("\n")
  cat(sprintf("  %-14s", "  A IQR hi")); for (v in apply(pr$amp,2,quantile,0.75,na.rm=TRUE)) cat(sprintf("%9.2f", v)); cat("\n")
  sw <- 100*(max(md) - min(md))
  cat(sprintf("\n  SWING in the median residual across the row: %.2f percentage points\n", sw))
  cat(sprintf("  RANGE of the median fitted A across the row : %.2f -> %.2f  (%.2fx)\n",
              max(ma), min(ma), max(ma)/min(ma)))
  cat(sprintf("  argmin phi = %g (median residual %.1f%%)\n", phis[which.min(md)], 100*min(md)))
  invisible(list(swing = sw, ratio = max(ma)/min(ma), argmin = phis[which.min(md)]))
}

cat("################ NH -- THE POWER CHECK ################\n")
cat("A flat SH row is only evidence if THIS row is sharp. MOD17 gives the NH a\n")
cat("5.2-point swing to a clean interior optimum at 75. If CMIP6 NH is flat too,\n")
cat("the flatness is in this pipeline, not in the hemisphere.\n")
nh <- report("NH (CMIP6 npp)", profile_hemi("NH", SP_PHI_NH), SP_PHI_NH)

cat("\n\n################ SH -- THE QUESTION ################\n")
sh <- report("SH (CMIP6 npp)", profile_hemi("SH", SP_PHI_SH), SP_PHI_SH)

cat("\n\n=== VERDICT ===\n")
cat(sprintf("  NH swing %.2f pp (ratio %.2fx) | SH swing %.2f pp (ratio %.2fx)\n",
            nh$swing, nh$ratio, sh$swing, sh$ratio))
cat("  MOD17 for comparison: NH swing 5.2 pp, SH swing 1.0 pp with A 0.97 -> 0.30 (3.2x).\n")
cat("  If the SH row is flat HERE TOO, the ridge is a property of the SOUTHERN\n")
cat("  HEMISPHERE (a water-driven cycle has no insolation latitude), not of MOD17,\n")
cat("  and no replacement product can pin the size on this basis.\n")

saveRDS(list(models = models, nh = nh, sh = sh, phi_nh = SP_PHI_NH, phi_sh = SP_PHI_SH),
        ccx_path("outputs/diagnostics", "sh_pair_nonmodis.rds"))
