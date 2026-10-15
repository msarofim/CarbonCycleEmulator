#!/usr/bin/env Rscript
# =====================================================================
# diag_cut_laplace_is.R -- IS A GAUSSIAN AT THE CANONICAL GOOD ENOUGH TO DRAW BANDS FROM? (2026-10-08 i)
#
# Marcus 2026-10-08: "Evaluate if the posterior bands are feasible: if so, implement them." The ruled method is
# the cut posterior "Laplace + propagation" (10-06 o): stage 1's Laplace pushed into the main fit's names through
# the cross-Hessian, on top of the MAIN FIT'S OWN Laplace. The main fit's Laplace is the part that failed at
# hilda33d (10-01 l: median lp - lp_quad -25.5, ESS 8 / 1000, the fertilization ridge), and its names are
# stage 2's, so it is tested FIRST, at THIS canonical: if it fails, propagation cannot rescue it.
#
# TWO PROPOSALS, each N_DRAWS draws in u-space at the mode, every draw scored on the REAL objective (the stage-2
# logpost, module names pinned -- i.e. conditional on stage 1 at its mode):
#   laplace  N(u0, Sigma), Sigma the mode file's covariance = solve(-H). The ruled method; 10-01's test exactly.
#   secant   N(u0, V diag((r_a f sd_a)^2) V'), the same eigen-axes V, each axis's sd rescaled by r_a =
#            sqrt(0.5 / |mean drop at +-1 sd|) -- the curvature MEASURED one sd out instead of at the mode
#            (hess_eps_frac 0.1) -- inflated by SC_INFLATE so the proposal stays WIDER than the target (a
#            narrower proposal is the heavy-tailed failure; tests/testthat/test-importance.R), capped at SC_RMAX.
#            The obvious remedy, tested so the verdict on the ruled method comes with the nearest alternative.
# The verdict per proposal is R/importance.R's: ESS, and the Pareto k-hat against min(1 - 1/log10(S), 0.7)
# (Vehtari et al. 2024, JMLR 25(72)).
#
# Output: outputs/diagnostics/cut_laplace_is_<date>_<canonical>.{log,rds}. Read-only for the model.
# Usage:  Rscript calibration/diag_cut_laplace_is.R          # ~3 min on 8 cores
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

# ---- named constants (every label derives from these) -------------------------
CI_DRIVER   <- "calibration/diag_cut_laplace_is.R"
CI_N        <- 1000L          # draws per proposal (10-01 (l)'s count)
CI_SEED     <- 20261008L      # laplace draws; the secant draws use CI_SEED + 1L; set IMMEDIATELY before each rnorm
CI_CORES    <- 8L
SC_INFLATE  <- 1.25           # secant proposal: inflation over the measured 1-sd curvature scale
SC_RMAX     <- 1.5            # ... and never more than this x the Laplace sd on any axis
CI_RIDGE    <- c("beta_max", "fert_k", "ndep_ret")   # reported names: the 10-01 ridge
CI_STEM <- ccx_path("outputs", "diagnostics", sprintf("cut_laplace_is_%s_%s", format(Sys.Date(), "%Y%m%d"),
                                                     CCX_MODE_CANONICAL))
CI_COMMIT <- ccx_git_stamp()

# ---- the harness: diag_laplace_axes.R's, which reproduces the stored logpost ----
md <- readRDS(ccx_mode_file(CCX_MODE_CANONICAL))
invisible(ccx_apply_gate(ccx_mode_struct(md))); invisible(ccx_apply_pins(ccx_mode_pins(md)))
invisible(ccx_adopt_mode_band(md))
u0  <- ccx_par_to_unc(md$par_mode); Sig <- ccx_mode_fit_stats(md)$cov
bp  <- ccx_mode_base(md); if (!is.null(md$pump_mode)) bp$pump_mode <- md$pump_mode
lpf <- ccx_make_logpost(base_params = bp, spinup_fn = ccx_spinup_from_label(ccx_mode_spinup(md)))
lp0 <- as.numeric(lpf(u0))
NAMES <- names(u0); d <- length(u0)

sink(paste0(CI_STEM, ".log"), split = TRUE)
cat(sprintf("%s @%s | canonical %s (%s) | %s\n", CI_DRIVER, CI_COMMIT, CCX_MODE_CANONICAL,
            basename(dirname(ccx_mode_file())), format(Sys.time(), "%Y-%m-%d %H:%M")))
# GATES: the harness reproduces the stored mode, and Sigma is the inverse of the stored -H
g1 <- abs(lp0 - md$logpost) < 1e-3
Hn <- -md$hessian
g2 <- max(abs(Sig %*% Hn - diag(d))) < 1e-6
cat(sprintf("GATE harness: lp(u0) %.4f vs stored %.4f -> %s\nGATE Sigma = solve(-H): max|Sigma (-H) - I| %.1e -> %s\n",
            lp0, md$logpost, if (g1) "PASS" else "FAIL", max(abs(Sig %*% Hn - diag(d))), if (g2) "PASS" else "FAIL"))
if (!(g1 && g2)) stop("gates failed")
cat(sprintf("%d fitted names, %d pinned (the module's four among them: %s)\n", d, length(ccx_mode_pins(md)),
            paste(intersect(CCX_IAV_MODULE_NAMES, names(ccx_mode_pins(md))), collapse = ", ")))

score <- function(U) unlist(parallel::mclapply(seq_len(nrow(U)), function(i) {
  u <- U[i, ]; names(u) <- NAMES
  tryCatch(as.numeric(lpf(u)), error = function(e) -Inf) }, mc.cores = CI_CORES))

# ---- the secant scales: every eigen-axis at +-1 Laplace sd ---------------------
ev <- eigen(Sig, symmetric = TRUE); sda <- sqrt(ev$values)
Lap <- ev$vectors %*% diag(sda)                                                 # column a = sd_a v_a
P <- rbind(sweep(t(Lap), 2, u0, "+"), sweep(-t(Lap), 2, u0, "+"))               # rows: u0 + 1 sd on axis a, then - 1 sd
drop <- matrix(score(P) - lp0, ncol = 2L)                                       # [a, 1] = +1 sd, [a, 2] = -1 sd
mdrop <- pmax(-rowMeans(drop), 1e-6)
r_a <- pmin(sqrt(0.5 / mdrop) * SC_INFLATE, SC_RMAX)
cat("\n=== CURVATURE ONE SD OUT, all eigen-axes (quadratic drop = 0.50) ===\n")
cat(sprintf("  axes with mean drop > 1.0 (twice the quadratic's): %d of %d\n", sum(mdrop > 1), d))
for (a in order(-mdrop)[1:6]) {
  v <- ev$vectors[, a]; top <- order(-abs(v))[1:3]
  cat(sprintf("  axis %2d (Laplace sd %.3f; %s): drop %+.2f / %+.2f -> ratio %.1fx, proposal scale %.3f\n",
              a, sda[a], paste(sprintf("%s %+.2f", NAMES[top], v[top]), collapse = ", "),
              drop[a, 1], drop[a, 2], mdrop[a] / 0.5, r_a[a]))
}

# ---- the two proposals ------------------------------------------------------------
props <- list(
  laplace = list(L = Lap, seed = CI_SEED),
  secant  = list(L = ev$vectors %*% diag(sda * r_a), seed = CI_SEED + 1L))
out <- list()
for (nm in names(props)) {
  L <- props[[nm]]$L                                 # Sigma_prop = L L'
  set.seed(props[[nm]]$seed, kind = "Mersenne-Twister")
  Z <- matrix(stats::rnorm(CI_N * d), CI_N, d)
  U <- sweep(Z %*% t(L), 2, u0, "+"); colnames(U) <- NAMES
  lp <- score(U)
  logq <- -0.5 * rowSums(Z^2)                        # log N(u; u0, LL') up to its constant
  lw <- lp - logq
  dl <- (lp - lp0) + 0.5 * rowSums((sweep(U, 2, u0) %*% Hn) * sweep(U, 2, u0))   # lp - lp_quad (10-01's)
  dg <- ccx_is_diagnostics(lw)
  proj3 <- as.numeric(sweep(U, 2, u0) %*% ev$vectors[, which.max(mdrop)])
  cat(sprintf("\n=== PROPOSAL '%s' (%d draws, seed %d) ===\n", nm, CI_N, props[[nm]]$seed))
  cat(sprintf("  lp - lp_quad: median %+.2f, 5%% %+.2f, 95%% %+.2f; failed draws %d\n",
              stats::median(dl[is.finite(dl)]), stats::quantile(dl[is.finite(dl)], 0.05),
              stats::quantile(dl[is.finite(dl)], 0.95), dg$n_failed))
  cat(sprintf("  ESS %.1f of %d (%.1f %%); largest weight %.3f; Pareto k-hat %.2f (reliable below %.3f) -> %s\n",
              dg$ess, CI_N, 100 * dg$ess_frac, dg$max_w, dg$k_hat, dg$k_ok_below,
              if (dg$k_ok) "RELIABLE" else "NOT RELIABLE"))
  cat(sprintf("  log weight vs the most-curved axis's coordinate: r %+.2f\n",
              stats::cor(lw[is.finite(lw)], abs(proj3[is.finite(lw)]))))
  for (n in CI_RIDGE) {
    x <- U[, n]
    cat(sprintf("  %-9s u-space: mode %+.3f | proposal sd %.3f | weighted mean %+.3f, sd %.3f\n", n, u0[[n]],
                stats::sd(x), sum(dg$w * x), sqrt(sum(dg$w * (x - sum(dg$w * x))^2))))
  }
  out[[nm]] <- list(U = U, lp = lp, logq = logq, lw = lw, dl = dl, diag = dg[setdiff(names(dg), "w")],
                    w = dg$w, seed = props[[nm]]$seed)
}

prov <- list(driver = CI_DRIVER, commit = CI_COMMIT, canonical = CCX_MODE_CANONICAL,
             mode_file = ccx_mode_file(), mode_md5 = unname(tools::md5sum(ccx_mode_file())),
             n_draws = CI_N, seeds = c(laplace = CI_SEED, secant = CI_SEED + 1L), rng_kind = "Mersenne-Twister",
             seed_applied = "immediately before each proposal's single rnorm() call",
             conditional_on = "stage 1 (the module's four names) at the canonical's pins",
             secant = list(inflate = SC_INFLATE, rmax = SC_RMAX, step = "+-1 Laplace sd per eigen-axis"),
             k_rule = "Vehtari et al. 2024 JMLR 25(72): k-hat < min(1 - 1/log10(S), 0.7)",
             date = format(Sys.time(), "%Y-%m-%d %H:%M"))
saveRDS(list(proposals = out, axes = list(values = ev$values, vectors = ev$vectors, drop = drop, r = r_a),
             u0 = u0, lp0 = lp0, provenance = prov), paste0(CI_STEM, ".rds"))
cat(sprintf("\nprovenance: %s @%s; %s; seeds %d / %d (Mersenne-Twister, before each rnorm); no other RNG\n",
            CI_DRIVER, CI_COMMIT, CCX_MODE_CANONICAL, CI_SEED, CI_SEED + 1L))
cat(sprintf("saved %s.{log,rds}\n", CI_STEM))
sink()
