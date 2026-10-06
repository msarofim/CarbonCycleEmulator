# =====================================================================
# diag_ribbons_linearity.R -- WHY the Laplace ribbons are wider than the
# delta-method predicts (2026-10-01).
#
# THE FINDING THIS CHECKS. build_futures_ribbons.R printed, at 1000 draws,
# sampled sd / linear sd = 1.62 (vvH CO2 2150), 2.02 (vvVL CO2 2150), 1.91
# (vvM GMST 2100) -- consistent across cells, far outside the ~2 % sampling
# error of a 1000-draw sd, and with a strong RIGHT skew (vvH 2150: +1.16).
# Implausible-until-explained ([[threshold_from_obs_or_law]]'s sibling rule: a
# result 2x off its analytic estimate is a bug until shown otherwise), so:
#   T1 REPRODUCE: rebuild the draw matrix from the SEED THE ARTIFACT RECORDS and
#      re-run draw 1 -- it must equal the artifact's stored draw-1 values exactly.
#      (A seed that cannot regenerate the sample is not a record of it.)
#   T2 THE DRAWS: the sample covariance of U must be Sigma (to sampling error).
#   T3 THE DELTA METHOD ON THE SAME DRAWS: y_lin = f(u0) + (U - u0) g has
#      sd = sqrt(g' Sigma g) exactly in expectation -- if it does, the arithmetic
#      is right and the excess is the MODEL's, not the code's.
#   T4 WHERE THE EXCESS LIVES: the residual y - y_lin regressed on each name's
#      standardised displacement and its SQUARE; a convex response shows up as
#      a positive coefficient on the square of the names that carry it.
#   T5 IS THE GAUSSIAN RIGHT THERE: every draw scored on the objective; the log
#      importance weight lp - lp_quad says where the real posterior falls off
#      faster (or slower) than the Laplace assumes, and the reweighted cells say
#      how much that moves the band.
# Output: outputs/diagnostics/ribbons_linearity_<date>.log. Uses only the
# artifact's own seed; draws no new random numbers.
# Usage: Rscript calibration/diag_ribbons_linearity.R
# =====================================================================
DL_ROOT <- normalizePath(getwd()); stopifnot(file.exists(file.path(DL_ROOT, "DESIGN.md")))
suppressMessages(library(shiny))
setwd(file.path(DL_ROOT, "app"))
invisible(utils::capture.output(suppressWarnings(
  shiny::loadSupport(getwd(), renv = globalenv(), globalrenv = globalenv()))))
setwd(DL_ROOT)
DL_DRIVER <- "calibration/diag_ribbons_linearity.R"
DL_LOG <- file.path(DL_ROOT, "outputs", "diagnostics", sprintf("ribbons_linearity_%s.log", format(Sys.Date(), "%Y%m%d")))
DL_CELLS <- list(c("vvH", "co2_ppm", "2150"), c("vvVL", "co2_ppm", "2150"), c("vvM", "gmst", "2100"))
DL_GRAD_FRAC <- 0.1
DL_COMMIT <- ccx_git_stamp()

rb <- readRDS(file.path(DL_ROOT, "data", "futures_ribbons.rds")); pv <- rb$provenance
md <- readRDS(ccx_mode_file(CCX_MODE_CANONICAL))
stopifnot(identical(pv$par_mode, md$par_mode))
invisible(ccx_apply_gate(ccx_mode_struct(md))); PINS <- ccx_mode_pins(md); invisible(ccx_apply_pins(PINS))
invisible(ccx_adopt_mode_band(md))
u0 <- ccx_par_to_unc(md$par_mode); stopifnot(identical(u0, pv$u_center))
Sig <- ccx_mode_fit_stats(md)$cov; k <- length(u0)

sink(DL_LOG, split = TRUE)
cat(sprintf("=== %s @%s, run %s; artifact %s (%d draws, seed %d) ===\n", DL_DRIVER, DL_COMMIT,
            format(Sys.time(), "%Y-%m-%d %H:%M"), pv$commit, pv$n_draws, pv$seed))

# ---- T1: the recorded seed regenerates the sample --------------------------
L <- chol(Sig)
RNGkind(pv$rng_kind[1], pv$rng_kind[2], pv$rng_kind[3]); set.seed(pv$seed)
Z <- matrix(stats::rnorm(pv$n_draws * k), pv$n_draws, k)
U <- sweep(Z %*% L, 2, u0, "+"); colnames(U) <- names(u0)
run_cells <- function(u) {
  pm <- ccx_unc_to_par(u); for (n in names(PINS)) pm[[n]] <- PINS[[n]]
  rp <- ccx_mode_run_params(md, pm); sp <- app_spinup(rp$p)
  vapply(DL_CELLS, function(cl) {
    out <- suppressWarnings(app_run_coupled(sp, cl[1], APP_FUTURE_YEARS, bomb_total_kmol = rp$bomb_total,
                                            luc_scale = rp$luc_scale))$climate
    out[[cl[2]]][out$year == as.integer(cl[3])] }, numeric(1))
}
y1 <- run_cells(U[1, ])
kd <- rb$key_draws
stored1 <- vapply(DL_CELLS, function(cl) kd$value[kd$draw == 1 & kd$scenario == cl[1] & kd$var == cl[2] &
                                                   kd$year == as.integer(cl[3])], numeric(1))
cat(sprintf("T1 draw 1 re-run from the recorded seed: max |diff| vs the artifact = %.3g -> %s\n",
            max(abs(y1 - stored1)), if (identical(y1, stored1)) "IDENTICAL" else "DIFFERS"))

# ---- T2: the draws carry Sigma ---------------------------------------------
Cs <- stats::cov(U); rel <- abs(Cs - Sig) / sqrt(outer(diag(Sig), diag(Sig)))
cat(sprintf("T2 sample covariance vs Sigma: max |diff| / (sd_i sd_j) = %.3f (1000 draws: ~0.03 expected); sd ratio range %.3f-%.3f\n",
            max(rel), min(sqrt(diag(Cs) / diag(Sig))), max(sqrt(diag(Cs) / diag(Sig)))))

# ---- T3 + T4 ---------------------------------------------------------------
f0 <- run_cells(u0)
G <- do.call(rbind, parallel::mclapply(names(u0), function(n) {
  h <- DL_GRAD_FRAC * sqrt(Sig[n, n]); up <- u0; dn <- u0; up[[n]] <- up[[n]] + h; dn[[n]] <- dn[[n]] - h
  (run_cells(up) - run_cells(dn)) / (2 * h) }, mc.cores = 8)); rownames(G) <- names(u0)
D <- sweep(U, 2, u0, "-"); S <- sweep(D, 2, sqrt(diag(Sig)), "/")   # standardised displacements
for (j in seq_along(DL_CELLS)) {
  cl <- DL_CELLS[[j]]
  y <- vapply(seq_len(pv$n_draws), function(i) kd$value[kd$draw == i & kd$scenario == cl[1] & kd$var == cl[2] &
                                                         kd$year == as.integer(cl[3])], numeric(1))
  ylin <- f0[j] + as.vector(D %*% G[, j])
  sdl <- sqrt(sum(G[, j] * (Sig %*% G[, j])))
  fit <- stats::lm(y ~ ylin); res <- y - ylin
  cat(sprintf("\n%s %s %s: f(u0) %.3f | sd sampled %.3f, sd of y_lin on the SAME draws %.3f, sqrt(g'Sg) %.3f | skew %.2f\n",
              cl[1], cl[2], cl[3], f0[j], stats::sd(y), stats::sd(ylin), sdl, mean(((y - mean(y)) / stats::sd(y))^3)))
  cat(sprintf("   y on y_lin: slope %.3f, R2 %.3f; residual sd %.3f (mean %+.3f = the median shift a convex response makes)\n",
              stats::coef(fit)[2], summary(fit)$r.squared, stats::sd(res), mean(res)))
  # T4: which names carry the residual -- linear and quadratic terms, one name at a time
  att <- t(vapply(names(u0), function(n) {
    s <- S[, n]; c(lin = stats::cor(res, s), sq = stats::cor(res, s^2)) }, numeric(2)))
  o <- order(-abs(att[, "sq"]))[1:6]
  cat("   residual vs each name's displacement (corr; top 6 by the SQUARE): ",
      paste(sprintf("%s lin %+.2f sq %+.2f", rownames(att)[o], att[o, "lin"], att[o, "sq"]), collapse = "; "), "\n")
}

# ---- T5: IS THE GAUSSIAN RIGHT ALONG THAT RIDGE? (importance weights) ------
# The Laplace draws assume lp(u) ~ lp0 - 0.5 (u-u0)' Sigma^-1 (u-u0). Where the
# real log-posterior falls FASTER than that (a curved ridge), the Gaussian puts
# mass the posterior does not, and the band is too wide there. Score every draw
# on the canonical's own objective; Delta = lp(u) - lp_quad(u) is the log
# importance weight of the posterior against the Gaussian. Reported: Delta's
# spread and what drives it, the weights' effective sample size, and the cells'
# IS-reweighted 5/50/95 % beside the plain ones.
# (Delta also carries the 10-01 (k) flip's -0.16 at the mode, a constant.)
bp <- ccx_mode_base(md); if (!is.null(md$pump_mode)) bp$pump_mode <- md$pump_mode
lpf <- ccx_make_logpost(base_params = bp, spinup_fn = ccx_spinup_from_label(ccx_mode_spinup(md)))
lp0 <- as.numeric(lpf(u0))
lps <- unlist(parallel::mclapply(seq_len(nrow(U)), function(i)
  tryCatch(as.numeric(lpf(U[i, ])), error = function(e) -Inf), mc.cores = 8))
Q <- solve(Sig); quad <- lp0 - 0.5 * rowSums((D %*% Q) * D)
dl <- lps - quad
cat(sprintf("\nT5 logpost at the mode %.4f (stored %.4f); %d of %d draws finite\n", lp0, md$logpost, sum(is.finite(lps)), length(lps)))
cat(sprintf("   Delta = lp - lp_quad: median %+.2f, 5-95 %% [%+.2f, %+.2f], min %+.1f; corr with beta_max displacement %+.2f, with its square %+.2f\n",
            stats::median(dl), stats::quantile(dl, 0.05), stats::quantile(dl, 0.95), min(dl),
            stats::cor(dl, S[, "beta_max"]), stats::cor(dl, S[, "beta_max"]^2)))
w <- exp(dl - max(dl)); w <- w / sum(w)
cat(sprintf("   importance weights: ESS %.0f of %d; largest single weight %.3f\n", 1 / sum(w^2), length(w), max(w)))
wq <- function(x, w, p) { o <- order(x); cw <- cumsum(w[o]); vapply(p, function(pp) x[o][which(cw >= pp)[1]], numeric(1)) }
for (cl in DL_CELLS) {
  y <- vapply(seq_len(pv$n_draws), function(i) kd$value[kd$draw == i & kd$scenario == cl[1] & kd$var == cl[2] &
                                                         kd$year == as.integer(cl[3])], numeric(1))
  cat(sprintf("   %s %s %s  plain 5/50/95 %%: %s | reweighted: %s\n", cl[1], cl[2], cl[3],
              paste(sprintf("%.2f", stats::quantile(y, c(0.05, 0.5, 0.95))), collapse = " / "),
              paste(sprintf("%.2f", wq(y, w, c(0.05, 0.5, 0.95))), collapse = " / ")))
}
sink()
