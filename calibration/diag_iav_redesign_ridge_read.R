#!/usr/bin/env Rscript
# =====================================================================
# diag_iav_redesign_ridge_read.R -- HOW WIDE IS THE beta_max RIDGE IN THE FUTURES? (CHANGELOG 2026-10-07 e)
# Reads calibration/diag_iav_redesign_ridge.R's profiles (beta_max held, the other four land names re-optimized, under #17 as
# landed and under the redesign) and, per objective:
#   SPACE     the profile is read in NATURAL space -- likelihood + prior, the five varying names' logit/log Jacobians REMOVED
#             (the density of beta_max in its own units; memory basin_rank_by_logit_jacobian) -- and, beside it, as the
#             objective's u-space logpost (Jacobians in), which the optimizer maximizes. beta_max's logit Jacobian alone moves
#             ~0.5 over 1.6-2.45, the size of the 1-sigma drop. The followers were optimized on the u-space objective;
#   MEASURED  the profile's 1-sigma interval, where a natural spline through the profiled points crosses a logpost drop of
#             1/2 on each side (fit_iav_module.R's rng() reading). A crossing at the grid's edge is a BOUND, said so;
#   QUADRATIC a quadratic in beta_max fitted to the profile: its optimum and 1-sigma width (drop 1/2). Printed beside the
#             measured interval, never instead of it: the ridge is known to stiffen away from the mode (memory
#             laplace_fails_on_fertilisation_ridge), so a quadratic fitted near the mode can overstate the width;
#   FUTURES   SSP5-8.5 and vvH CO2 in 2300 interpolated along the profile at the interval's ends, so the 1-sigma range of
#             2300 CO2 ALONG THIS RIDGE ALONE.
# Also the index's own futures effect at a FIXED beta_max (redesign minus #17, point by point).
# ⚠ A CONDITIONAL profile: 4 of 29 names follow and the module is pinned. A width, not a posterior.
# Usage: Rscript calibration/diag_iav_redesign_ridge_read.R [ridge rds]
# OUTPUTS: outputs/diagnostics/iav_redesign_ridge_read_<date>[_<tag>].{log,rds}. ⛔ ADOPTS NOTHING. No RNG.
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
RR_DRIVER  <- "calibration/diag_iav_redesign_ridge_read.R"
RR_ARGS    <- commandArgs(trailingOnly = TRUE)
RR_IN      <- if (length(RR_ARGS)) RR_ARGS[1] else file.path("outputs", "diagnostics", "iav_redesign_ridge_20261007.rds")
RR_DROP    <- 0.5            # the 1-sigma profile drop
RR_FINE    <- 1e-4           # the crossing's resolution in beta_max
RR_FIT_TOL <- 0.025          # diag_iav_redesign_ridge.R's RF_B2_TOL: a quadratic missing a point by more is flagged
RR_FUT     <- c("ssp585", "vvH")
RD <- readRDS(RR_IN); T <- RD$table; TAG <- RD$provenance$tag %||% ""
# the five varying names' Jacobian sum per cell, from each cell's own natural values (the other 24 names are fixed)
jac5 <- function(par) sum(vapply(names(par), function(n) { s <- CCX_PARAM_GATED_ALL[[n]] %||% CCX_PARAM_TABLE[[n]]
  .log_jac(.to_unc(par[[n]], s), s) }, 0))
J <- do.call(rbind, lapply(RD$cells, function(r) data.frame(obj = if (r$index == "demean") "obj17" else "redesign", beta_max = r$bm,
                                                             j5 = jac5(r$par), lp_cell = r$logpost)))
T <- merge(T, J, by = c("obj", "beta_max")); stopifnot(nrow(T) == nrow(J), isTRUE(all.equal(T$logpost, T$lp_cell)))
T$natural <- T$logpost - T$j5
RR_OUT <- file.path("outputs", "diagnostics", sprintf("iav_redesign_ridge_read_%s%s", format(Sys.Date(), "%Y%m%d"),
                                                      if (nzchar(TAG)) paste0("_", TAG) else ""))
COMMIT <- ccx_git_stamp()
sink(paste0(RR_OUT, ".log"), split = TRUE)
cat(sprintf("%s @%s, %s | from %s (%s @%s), grid %s\n", RR_DRIVER, COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M"), RR_IN,
            RD$provenance$driver, RD$provenance$commit, paste(sprintf("%.4f", RD$grid), collapse = ", ")))
OUT <- list()
for (sp_name in c("natural", "logpost")) for (o in c("obj17", "redesign")) {
  X <- T[T$obj == o, ]; X <- X[order(X$beta_max), ]; X$d <- X[[sp_name]] - max(X[[sp_name]])
  fine <- seq(min(X$beta_max), max(X$beta_max), by = RR_FINE); sp <- stats::splinefun(X$beta_max, X$d, method = "natural")(fine)
  k <- fine[sp >= -RR_DROP]; lo <- min(k); hi <- max(k); b_hat <- fine[which.max(sp)]
  edge <- c(lo = lo <= min(fine) + RR_FINE, hi = hi >= max(fine) - RR_FINE)
  fut_at <- function(b) vapply(RR_FUT, function(s) stats::approx(X$beta_max, X[[s]], xout = b)$y, 0)
  F_lo <- fut_at(lo); F_hi <- fut_at(hi); F_hat <- fut_at(b_hat)
  q <- stats::lm(d ~ beta_max + I(beta_max^2), data = X); cf <- stats::coef(q); res <- max(abs(stats::residuals(q)))
  q_opt <- if (cf[[3]] < 0) -cf[[2]] / (2 * cf[[3]]) else NA_real_; q_sd <- if (cf[[3]] < 0) sqrt(RR_DROP / -cf[[3]]) else NA_real_
  sl <- vapply(RR_FUT, function(s) stats::coef(stats::lm(X[[s]] ~ X$beta_max))[[2]], 0)
  cat(sprintf("\n%s, %s (%d points, beta_max %.3f-%.3f)\n", o, if (sp_name == "natural") "NATURAL space (likelihood + prior, no Jacobians)"
              else "u-space logpost (the objective; Jacobians in)", nrow(X), min(X$beta_max), max(X$beta_max)))
  cat(sprintf("  MEASURED: optimum beta_max %.4f; 1-sigma interval %.4f%s to %.4f%s\n", b_hat, lo, if (edge[["lo"]]) " (grid edge: a BOUND)" else "",
              hi, if (edge[["hi"]]) " (grid edge: a BOUND)" else ""))
  cat(sprintf("    2300 CO2 over that interval: %s\n", paste(sprintf("%s %.1f to %.1f ppm (%+.1f / %+.1f about the optimum's %.1f)", RR_FUT,
              pmin(F_lo, F_hi), pmax(F_lo, F_hi), pmin(F_lo, F_hi) - F_hat, pmax(F_lo, F_hi) - F_hat, F_hat), collapse = "; ")))
  cat(sprintf("  QUADRATIC (max |residual| %.4f%s): optimum %.4f, 1-sigma +/- %.4f; 2300 CO2 %s per unit beta_max -> +/- %s\n", res,
              if (res > RR_FIT_TOL) sprintf(" > %.3f: NOT QUADRATIC over this range, read the measured interval", RR_FIT_TOL) else "",
              q_opt, q_sd, paste(sprintf("%s %+.1f ppm", RR_FUT, sl), collapse = ", "), paste(sprintf("%s %.1f ppm", RR_FUT, abs(sl) * q_sd), collapse = ", ")))
  OUT[[paste(o, sp_name, sep = "_")]] <- list(measured = c(opt = b_hat, lo = lo, hi = hi), edge = edge, fut_hat = F_hat, fut_lo = F_lo, fut_hi = F_hi,
                   quad = list(coef = cf, max_resid = res, opt = q_opt, sd = q_sd), slope = sl)
}
A <- T[T$obj == "obj17", ]; B <- T[T$obj == "redesign", ]; A <- A[order(A$beta_max), ]; B <- B[order(B$beta_max), ]
stopifnot(isTRUE(all.equal(A$beta_max, B$beta_max)))
D <- data.frame(beta_max = A$beta_max, ssp585 = B$ssp585 - A$ssp585, vvH = B$vvH - A$vvH)
cat("\nTHE INDEX's OWN FUTURES EFFECT at a FIXED beta_max (redesign minus #17, the four re-optimised under each), ppm in 2300:\n")
print(round(D, 3), row.names = FALSE)
cat(sprintf("  range: SSP5-8.5 %+.2f to %+.2f, vvH %+.2f to %+.2f\n", min(D$ssp585), max(D$ssp585), min(D$vvH), max(D$vvH)))
saveRDS(list(fits = OUT, index_effect = D, table = T, provenance = list(driver = RR_DRIVER, commit = COMMIT, input = RR_IN, input_commit = RD$provenance$commit,
             drop = RR_DROP, fine = RR_FINE, fit_tol = RR_FIT_TOL, date = format(Sys.time(), "%Y-%m-%d %H:%M"), rng = "none",
             units = "beta_max as the table; CO2 ppm")), paste0(RR_OUT, ".rds"))
cat(sprintf("\nsaved %s.{log,rds}\n⛔ ADOPTS NOTHING.\n", RR_OUT))
sink()
