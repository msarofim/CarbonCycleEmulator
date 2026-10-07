#!/usr/bin/env Rscript
# =====================================================================
# diag_iav_redesign_ridge_read.R -- HOW WIDE IS THE beta_max RIDGE IN THE FUTURES? (CHANGELOG 2026-10-07 e)
# Reads calibration/diag_iav_redesign_ridge.R's profiles (beta_max held, the other four land names re-optimised, under #17 as
# landed and under the redesign) and, per objective: a quadratic in beta_max fitted to the profile's logpost (the
# profile-likelihood curvature, priors included), its optimum and 1-sigma width (logpost drop 1/2); a line fitted to
# SSP5-8.5 and vvH CO2 in 2300 along the same profile; and so the 1-sigma width of 2300 CO2 ALONG THIS RIDGE ALONE.
# Also the index's own futures effect at a FIXED beta_max (redesign minus #17, point by point).
# ⚠ A CONDITIONAL profile: 4 of 29 names follow, the module is pinned, and the grid is six points. A width, not a posterior.
# GATE: each quadratic must fit its six points to within RR_FIT_TOL (the B2 re-fit's own convergence bound, 0.025),
# or the quadratic reading is refused.
# Usage: Rscript calibration/diag_iav_redesign_ridge_read.R [ridge rds]
# OUTPUTS: outputs/diagnostics/iav_redesign_ridge_read_<date>.log. ⛔ ADOPTS NOTHING. No RNG.
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
RR_DRIVER  <- "calibration/diag_iav_redesign_ridge_read.R"
RR_ARGS    <- commandArgs(trailingOnly = TRUE)
RR_IN      <- if (length(RR_ARGS)) RR_ARGS[1] else file.path("outputs", "diagnostics", "iav_redesign_ridge_20261007.rds")
RR_DROP    <- 0.5            # the 1-sigma profile drop
RR_FIT_TOL <- 0.025          # diag_iav_redesign_ridge.R's RF_B2_TOL: 1/2 x 0.1^2 x 5 names
RR_FUT     <- c("ssp585", "vvH")
RR_OUT <- file.path("outputs", "diagnostics", sprintf("iav_redesign_ridge_read_%s", format(Sys.Date(), "%Y%m%d")))
COMMIT <- ccx_git_stamp()
sink(paste0(RR_OUT, ".log"), split = TRUE)
RD <- readRDS(RR_IN); T <- RD$table
cat(sprintf("%s @%s, %s | from %s (%s @%s)\n", RR_DRIVER, COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M"), RR_IN, RD$provenance$driver,
            RD$provenance$commit))
OUT <- list()
for (o in c("obj17", "redesign")) {
  X <- T[T$obj == o, ]; X <- X[order(X$beta_max), ]
  q <- stats::lm(logpost ~ beta_max + I(beta_max^2), data = X); cf <- stats::coef(q)
  res <- max(abs(stats::residuals(q)))
  if (cf[[3]] >= 0) stop(o, ": the profile is not concave in beta_max")
  b_opt <- -cf[[2]] / (2 * cf[[3]]); sd_b <- sqrt(RR_DROP / -cf[[3]])
  sl <- vapply(RR_FUT, function(s) stats::coef(stats::lm(X[[s]] ~ X$beta_max))[[2]], 0)
  cat(sprintf("\n%s: quadratic profile (max |residual| %.4f, tol %.3f): optimum beta_max %.4f, 1-sigma +/- %.4f (%.1f %% of it)\n", o, res,
              RR_FIT_TOL, b_opt, sd_b, 100 * sd_b / b_opt))
  cat(sprintf("  2300 CO2 along the ridge: %s ppm per unit beta_max -> 1-sigma width ALONG THIS RIDGE %s\n",
              paste(sprintf("%s %+.1f", RR_FUT, sl), collapse = ", "), paste(sprintf("%s +/- %.1f ppm", RR_FUT, abs(sl) * sd_b), collapse = ", ")))
  if (res > RR_FIT_TOL) stop(o, ": the quadratic misses the profile by more than the re-fit's own bound; read the points, not the fit")
  OUT[[o]] <- list(coef = cf, max_resid = res, opt = b_opt, sd = sd_b, slope = sl, width = abs(sl) * sd_b)
}
A <- T[T$obj == "obj17", ]; B <- T[T$obj == "redesign", ]; A <- A[order(A$beta_max), ]; B <- B[order(B$beta_max), ]
stopifnot(isTRUE(all.equal(A$beta_max, B$beta_max)))
D <- data.frame(beta_max = A$beta_max, ssp585 = B$ssp585 - A$ssp585, vvH = B$vvH - A$vvH)
cat("\nTHE INDEX's OWN FUTURES EFFECT at a FIXED beta_max (redesign minus #17, the four re-optimised under each), ppm in 2300:\n")
print(round(D, 3), row.names = FALSE)
cat(sprintf("  range: SSP5-8.5 %+.2f to %+.2f, vvH %+.2f to %+.2f\n", min(D$ssp585), max(D$ssp585), min(D$vvH), max(D$vvH)))
saveRDS(list(fits = OUT, index_effect = D, provenance = list(driver = RR_DRIVER, commit = COMMIT, input = RR_IN, drop = RR_DROP,
             fit_tol = RR_FIT_TOL, date = format(Sys.time(), "%Y-%m-%d %H:%M"), rng = "none",
             units = "beta_max as the table; CO2 ppm")), paste0(RR_OUT, ".rds"))
cat(sprintf("\nsaved %s.{log,rds}\n⛔ ADOPTS NOTHING.\n", RR_OUT))
sink()
