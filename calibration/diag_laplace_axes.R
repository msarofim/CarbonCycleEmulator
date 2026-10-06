# =====================================================================
# diag_laplace_axes.R -- is the stored Hessian RIGHT, or is the posterior just
# not Gaussian? (2026-10-01, after diag_ribbons_linearity.R T5: the Laplace
# draws sit a median 25.5 log-units below the quadratic, importance ESS 8/1000.)
#
# Along each PRINCIPAL AXIS of the stored covariance (the eigenvectors of Sigma,
# widest first), step +-0.5, +-1, +-2 sd and score the real objective. If the
# Hessian is right, the drop at +-0.5 / +-1 sd is the quadratic's 0.125 / 0.5
# log-units (a property of the curvature AT the mode, which is what a Hessian
# measures); a far larger drop already at 0.5-1 sd says the Hessian
# UNDERSTATES the curvature there (a numerical defect), while agreement near the
# mode that breaks only at 2 sd says the posterior is non-quadratic (a curved
# ridge) and the Hessian is fine. Output: outputs/diagnostics/laplace_axes_<date>.log.
# Usage: Rscript calibration/diag_laplace_axes.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
LA_DRIVER <- "calibration/diag_laplace_axes.R"
LA_STEPS  <- c(-2, -1, -0.5, 0.5, 1, 2)
LA_N_AXES <- 8L                       # the widest axes (they carry the ribbons' spread)
LA_LOG <- ccx_path("outputs", "diagnostics", sprintf("laplace_axes_%s.log", format(Sys.Date(), "%Y%m%d")))
LA_COMMIT <- ccx_git_stamp()
md <- readRDS(ccx_mode_file(CCX_MODE_CANONICAL))
invisible(ccx_apply_gate(ccx_mode_struct(md))); invisible(ccx_apply_pins(ccx_mode_pins(md)))
invisible(ccx_adopt_mode_band(md))
u0 <- ccx_par_to_unc(md$par_mode); Sig <- ccx_mode_fit_stats(md)$cov
bp <- ccx_mode_base(md); if (!is.null(md$pump_mode)) bp$pump_mode <- md$pump_mode
lpf <- ccx_make_logpost(base_params = bp, spinup_fn = ccx_spinup_from_label(ccx_mode_spinup(md)))
lp0 <- as.numeric(lpf(u0))
ev <- eigen(Sig, symmetric = TRUE)
sink(LA_LOG, split = TRUE)
cat(sprintf("=== %s @%s, run %s; mode %s logpost %.4f; Sigma eigenvalues (u-space var) %.3g .. %.3g ===\n",
            LA_DRIVER, LA_COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M"), CCX_MODE_CANONICAL, lp0,
            max(ev$values), min(ev$values)))
cat(sprintf("stored Hessian: hess_eps_frac %s; unstable steps: %s\n", format(md$hess_eps_frac),
            if (length(md$hess_eps_unstable)) paste(md$hess_eps_unstable, collapse = ", ") else "none"))
cat("drop = lp(u0 + s sd v) - lp0, against the quadratic's -s^2/2:\n")
jobs <- expand.grid(axis = seq_len(LA_N_AXES), s = LA_STEPS)
res <- parallel::mclapply(seq_len(nrow(jobs)), function(j) {
  a <- jobs$axis[j]; s <- jobs$s[j]
  u <- u0 + s * sqrt(ev$values[a]) * ev$vectors[, a]; names(u) <- names(u0)
  tryCatch(as.numeric(lpf(u)), error = function(e) -Inf) - lp0 }, mc.cores = 8)
jobs$drop <- unlist(res)
for (a in seq_len(LA_N_AXES)) {
  v <- ev$vectors[, a]; top <- order(-abs(v))[1:3]
  r <- jobs[jobs$axis == a, ]
  cat(sprintf("axis %d (sd %.3f; %s): %s\n", a, sqrt(ev$values[a]),
              paste(sprintf("%s %+.2f", names(u0)[top], v[top]), collapse = ", "),
              paste(sprintf("%+g sd %+.2f", r$s, r$drop), collapse = " | ")))
}
cat("(quadratic: +-0.5 sd -0.125, +-1 sd -0.5, +-2 sd -2.0)\n")
sink()
