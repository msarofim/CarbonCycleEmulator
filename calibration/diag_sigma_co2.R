# =====================================================================
# diag_sigma_co2.R -- REVIEW ITEM 6b, the measurement before the decision.
#
# THE QUESTION. handoff 2026-08-15 sec.4.1 diagnosed `sigma_co2` as
# "unidentified and pinned at a boundary -- it will hurt MCMC mixing and
# covariance conditioning. Fix it or drop it; do not sample it", and
# handoff 2026-08-15b made that the standing blocker on the refit (item 8).
#
# That diagnosis rests on ONE observation -- sigma_co2 = 0.223 at the MAP mode
# against a prior median of 1.5, z = -2.56 -- and on the ANALYTIC fact that
# the CO2 level terms use sd = sqrt(sigma_co2^2 + LIK_CO2_REP_ERR^2) with
# LIK_CO2_REP_ERR fixed at 1.0 ppm. Write v = sigma^2 + c^2. For n Gaussian
# residuals r with pooled mean square R^2,
#
#     d/dv loglik = -n/(2v) + sum(r^2)/(2v^2) = 0   ->   v = R^2
#     so  sigma^2 = R^2 - c^2,
#
# which has NO REAL SOLUTION whenever the pooled residual RMS R falls below the
# fixed constant c. Then the likelihood is monotone decreasing in sigma and the
# posterior mode is set by the prior alone. THAT is the precise content of
# "pinned at a boundary", and it is a statement about R, not about sigma_co2.
#
# So the decision needs five things measured, not one:
#
#  1. R, THE POOLED ANNUAL LEVEL RESIDUAL, at more than one point in parameter
#     space. R < c and R > c are qualitatively different regimes and the repo
#     contains points on BOTH sides: the MAP mode has R = 0.642 (no interior
#     optimum) and test-likelihood.R's fixture has R ~ 1.13 (interior optimum,
#     which is why that test's assertions still pass). A parameter that is
#     boundary-pinned at the mode but interior 500 log-units away is not
#     "unidentified" -- it is a valve that is currently shut.
#  2. WHETHER THERE IS A BOUNDARY AT ALL. The sampler works on the UNCONSTRAINED
#     scale, where sigma_co2 is log-transformed. sigma -> 0 is u -> -Inf, and the
#     lognormal prior takes the density to zero there. A hard edge in natural
#     units can be no edge at all in the coordinates the sampler uses, and
#     "pinned at a boundary" is a claim about the sampler's geometry.
#  3. HOW MUCH THE DATA ACTUALLY TIGHTEN IT -- posterior sd against prior sd on
#     the sampling scale. This is the identifiability metric; z = -2.56 is not.
#  4. THE CONDITIONING CLAIM, which is about CORRELATION and is measurable
#     directly from the stored Laplace covariance. "Hurts covariance
#     conditioning" is falsifiable and has not been checked.
#  5. WHAT EACH OPTION COSTS, in the only currency that matters here: the
#     EFFECTIVE sd of the CO2 level stream, because that is a stream WEIGHT in
#     an objective whose 40:1 CO2-vs-partition imbalance is the whole point of
#     the review. Dropping sigma_co2 is not free housekeeping if it re-weights
#     the loudest stream.
#
# This file does NOT take the decision. It measures. The choice between free /
# fixed / dropped is a weighting choice and goes to Marcus.
#
# THE ABSENCE CONTRACT (handoff 2026-08-15b sec.3.2). ccx_loglik()'s gradient
# streams are SKIPPED unless `err` carries grad_off_co2 and grad_off_d13c, so
# every log-likelihood here supplies them. They do not enter the CO2 level sd
# and so cannot affect parts 1-3, but they must be present for any TOTAL quoted
# below to be comparable with a post-2026-08-15 number.
#
# RUNTIME ~1 min.
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

# ---- named constants: every label and threshold below derives from these ----
SC_YEARS      <- c(1750, 2024)
SC_BOMB_REF   <- 102
SC_SIGMA_D13C <- 0.44         # the MAP mode's value, as diag_gradient_terms.R uses
SC_SIGMA_D14C <- 5
# Measured intercepts from calibration/diag_gradient_terms.R part 3, so the
# gradient streams are PRESENT and near their fitted offsets rather than at a
# zero that the same diagnostic rejected at 95 %.
SC_GRAD_OFF_DEFAULT <- c(co2 = -0.386, d13c = +0.099)
SC_GRAD_OFF_MODE    <- c(co2 = -0.549, d13c = +0.107)
# The pre-gradient mode. Its LOG-POSTERIOR is not comparable with anything
# computed after 2026-08-15 (18 parameters, two fewer streams, three input
# changes) -- but its PARAMETER VECTOR is still the best available locator of
# the posterior region, and that is the only thing it is used for here.
SC_MODE_PATH  <- ccx_path("calibration", "output", "quarantine",
                          "20260815_pre_gradient_terms", "mode_fit.rds")
SC_PRIOR_MED  <- 1.5          # CCX_PARAM_TABLE$sigma_co2, lognormal median
SC_PRIOR_SDLOG <- 0.7         #   "                      , sdlog
SC_GRID       <- exp(seq(log(0.01), log(20), length.out = 601))  # ppm
SC_OPTIONS    <- c(0, 0.223, 1.5)   # candidate FIXED values: drop / mode / prior median
SC_OUTDIR     <- ccx_path("calibration", "output", "sigma_co2")

dir.create(SC_OUTDIR, recursive = TRUE, showWarnings = FALSE)
sep <- function(s) cat(sprintf("\n\n=== %s ===\n", s))

sc_err <- function(sigma_co2, off) {
  list(sigma_co2 = sigma_co2, sigma_d13c = SC_SIGMA_D13C,
       sigma_d14c = SC_SIGMA_D14C,
       grad_off_co2 = off[["co2"]], grad_off_d13c = off[["d13c"]])
}

obs <- ccx_prepare_obs()
base_forcing <- ccx_build_forcing("historical", SC_YEARS, prod_c14 = 0,
                                  bomb_total_kmol = SC_BOMB_REF)

#' Run the model at one parameter set and return everything the parts below need
sc_run <- function(p, bomb_total, luc_scale, label) {
  sp <- ccx_spinup(p)
  F  <- base_forcing
  F$c14_cosmo <- sp$prod_c14
  F$c14_bomb  <- base_forcing$c14_bomb * (bomb_total / SC_BOMB_REF)
  for (cc in c("e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH"))
    F[[cc]] <- base_forcing[[cc]] * luc_scale
  attr(F, "luc_scale") <- luc_scale
  eluc <- ccx_forcing_eluc_annual(base_forcing)
  eluc$eluc <- eluc$eluc * luc_scale
  out <- ccx_run_fast(sp, F)$out
  list(label = label, out = out, eluc = eluc,
       deep = sp$diagnostics$d14c_bottom_box)
}

#' The pooled annual CO2 level residual over BOTH stations -- the quantity the
#' whole decision turns on. Measured, never stored.
sc_residual <- function(r) {
  ms <- ccx_model_stats(r$out, obs)
  per <- lapply(c("MLO", "SPO"), function(st) {
    o <- obs$co2_ann[[st]]; m <- ms$co2[[st]]
    k <- match(o$year, m$year); g <- !is.na(k)
    o$level[g] - m$level[k[g]]
  })
  names(per) <- c("MLO", "SPO")
  list(per = per, pooled = unlist(per))
}

# ---- the two evaluation points ---------------------------------------
pts <- list(sc_run(ccx_default_params(), SC_BOMB_REF, 1.0,
                   "ccx_default_params()"))
attr(pts[[1]], "off") <- SC_GRAD_OFF_DEFAULT

mode_ok <- file.exists(SC_MODE_PATH)
if (mode_ok) {
  md <- readRDS(SC_MODE_PATH)
  pm <- md$par_mode
  p2 <- ccx_default_params()
  for (n in intersect(names(p2), names(pm))) p2[[n]] <- pm[[n]]
  p2 <- ccx_set_enso(p2, pm)
  pts[[2]] <- sc_run(p2, pm$bomb_total, pm$luc_scale,
                     "pre-gradient MAP mode's parameters (18-par, quarantined)")
  attr(pts[[2]], "off") <- SC_GRAD_OFF_MODE
}

# ---------------------------------------------------------------------
sep("PART 1. R, THE POOLED RESIDUAL -- AND WHICH SIDE OF c IT FALLS")
cat(sprintf("LIK_CO2_REP_ERR = c = %.3f ppm (fixed)\n\n", LIK_CO2_REP_ERR))
cat(sprintf("%-52s %8s %8s %8s   %s\n",
            "parameter point", "R_MLO", "R_SPO", "R_pool", "interior optimum?"))
resid <- list()
for (i in seq_along(pts)) {
  rr <- sc_residual(pts[[i]]); resid[[i]] <- rr
  R  <- sqrt(mean(rr$pooled^2))
  rms <- vapply(rr$per, function(x) sqrt(mean(x^2)), numeric(1))
  cat(sprintf("%-52s %8.3f %8.3f %8.3f   %s\n", pts[[i]]$label,
              rms[["MLO"]], rms[["SPO"]], R,
              if (R > LIK_CO2_REP_ERR)
                sprintf("YES, sigma* = %.3f", sqrt(R^2 - LIK_CO2_REP_ERR^2))
              else "NO -- likelihood monotone decreasing"))
}
cat("\nThe SAME model, at two points in its own parameter space, sits on OPPOSITE\n",
    "sides of the threshold. Whether sigma_co2 has an interior maximum is not a\n",
    "property of the parameter; it is a property of how well the run fits CO2.\n", sep = "")

sep("PART 2. HOW FAR IS THE THRESHOLD? THE BIAS THAT WOULD RE-IDENTIFY IT")
# A sustained extra level bias b adds in quadrature to the existing residual.
# Solve sqrt(R^2 + b^2) = c for b: the amount of additional CO2 level misfit
# that would give sigma_co2 an interior optimum again.
for (i in seq_along(pts)) {
  R <- sqrt(mean(resid[[i]]$pooled^2))
  b <- if (R < LIK_CO2_REP_ERR) sqrt(LIK_CO2_REP_ERR^2 - R^2) else 0
  cat(sprintf("%-52s R = %.3f  ->  needs %+.3f ppm more sustained bias\n",
              pts[[i]]$label, R, b))
}
cat("\nThat is the margin. It is not large: a few tenths of a ppm of CO2 level\n",
    "bias is well inside the excursions an MCMC chain makes in its early phase\n",
    "and inside the ~30 ppm structural misfit this repo has been chasing.\n", sep = "")

sep("PART 3. IS THERE A BOUNDARY? THE PROFILE ON BOTH SCALES")
# Profile at fixed other parameters. This is the WHOLE conditional story for
# sigma_co2: it enters the objective in exactly one place (the CO2 level sd),
# and no other parameter enters that sd, so nothing else can trade against it
# except through the residual, which is held fixed here by construction.
prof <- list()
for (i in seq_along(pts)) {
  off <- attr(pts[[i]], "off")
  ll <- vapply(SC_GRID, function(s)
    ccx_loglik(pts[[i]]$out, obs, sc_err(s, off),
               luc = pts[[i]]$eluc, deep = pts[[i]]$deep), numeric(1))
  # posterior on the UNCONSTRAINED scale: lognormal prior + log-Jacobian
  lpri <- dlnorm(SC_GRID, log(SC_PRIOR_MED), SC_PRIOR_SDLOG, log = TRUE) +
          log(SC_GRID)
  lpost <- ll + lpri
  prof[[i]] <- list(sigma = SC_GRID, ll = ll, lpost = lpost)

  s_ll   <- SC_GRID[which.max(ll)]
  s_post <- SC_GRID[which.max(lpost)]
  # normalized posterior in u = log(sigma), on the sampler's own coordinates
  u  <- log(SC_GRID)
  w  <- exp(lpost - max(lpost)); w <- w / sum(w)
  mu <- sum(w * u); sdu <- sqrt(sum(w * (u - mu)^2))
  cat(sprintf("\n%s\n", pts[[i]]$label))
  cat(sprintf("  likelihood-only optimum   sigma = %.3f  (grid edge? %s)\n",
              s_ll, if (which.max(ll) == 1L) "YES, at the LOW edge" else "no"))
  cat(sprintf("  posterior optimum         sigma = %.3f   effective sd = %.4f ppm\n",
              s_post, sqrt(s_post^2 + LIK_CO2_REP_ERR^2)))
  cat(sprintf("  posterior on log scale    mean %.3f, sd %.3f   vs prior sd %.3f  ->  tightened %.2fx\n",
              mu, sdu, SC_PRIOR_SDLOG, SC_PRIOR_SDLOG / sdu))
  cat(sprintf("  log-post drop from the optimum to sigma = 0.01: %.1f log-units\n",
              max(lpost) - lpost[1]))
  cat(sprintf("  is the posterior mode at a grid edge? %s\n",
              if (which.max(lpost) %in% c(1L, length(SC_GRID))) "YES" else
                "NO -- interior, unimodal on the sampling scale"))
}
cat("\nThe likelihood alone runs to the low edge whenever R < c (part 1). The\n",
    "POSTERIOR does not: on the log scale the prior closes it off smoothly and\n",
    "the mode is interior. There is no boundary in the coordinates the sampler\n",
    "uses -- which is what the mixing claim was about.\n", sep = "")

sep("PART 4. THE CONDITIONING CLAIM, MEASURED")
if (mode_ok) {
  r <- md$cor["sigma_co2", ]
  r <- r[names(r) != "sigma_co2"]
  cat("posterior correlation of sigma_co2 with every other parameter,\n")
  cat("from the stored Laplace covariance at the pre-gradient mode:\n\n")
  print(round(sort(r), 3))
  cat(sprintf("\n  max |r| = %.3f (%s)\n", max(abs(r)), names(which.max(abs(r)))))
  cat(sprintf("  for comparison, the worst pair in the same matrix: |r| = %.3f\n",
              max(abs(md$cor[upper.tri(md$cor)]))))
  cat("\nposterior sd on the unconstrained scale, ALL parameters, worst first:\n")
  print(round(sort(md$sd_unc, decreasing = TRUE), 3))
  cat(sprintf("\n  sigma_co2 ranks %d of %d by posterior width.\n",
              which(names(sort(md$sd_unc, decreasing = TRUE)) == "sigma_co2"),
              length(md$sd_unc)))
} else {
  cat("mode_fit absent from the quarantine path -- conditioning claim UNTESTED.\n")
}

sep("PART 5. WHAT EACH OPTION COSTS THE OBJECTIVE")
# The currency is the EFFECTIVE sd, because that is the CO2 level stream's
# weight. Everything else follows from it: the implied gradient sd (which
# LIK_GRAD_* says to re-measure if sigma_co2 moves) and the stream imbalance.
cat(sprintf("%-26s %12s %14s %16s\n", "option", "sigma_co2", "effective sd",
            "weight vs free"))
ref_eff <- sqrt(SC_OPTIONS[2]^2 + LIK_CO2_REP_ERR^2)
for (s in SC_OPTIONS) {
  eff <- sqrt(s^2 + LIK_CO2_REP_ERR^2)
  lab <- switch(as.character(s), "0" = "DROP (fix at 0)",
                "0.223" = "FIX at the MAP value", "FIX at the prior median")
  cat(sprintf("%-26s %12.3f %14.4f %15.2fx\n", lab, s, eff, (ref_eff / eff)^2))
}
cat("\nand the same three, scored -- CO2 level streams and the total:\n\n")
for (i in seq_along(pts)) {
  off <- attr(pts[[i]], "off")
  cat(sprintf("%s\n", pts[[i]]$label))
  cat(sprintf("  %-26s %12s %12s %12s\n", "option",
              "co2_lvl_MLO", "co2_lvl_SPO", "TOTAL ll"))
  for (s in SC_OPTIONS) {
    ps <- ccx_loglik(pts[[i]]$out, obs, sc_err(s, off), luc = pts[[i]]$eluc,
                     deep = pts[[i]]$deep, by_stream = TRUE)
    lab <- switch(as.character(s), "0" = "DROP (fix at 0)",
                  "0.223" = "FIX at the MAP value", "FIX at the prior median")
    cat(sprintf("  %-26s %12.1f %12.1f %12.1f\n", lab,
                ps[["co2_level_MLO"]], ps[["co2_level_SPO"]], sum(ps)))
  }
  cat("\n")
}

sep("PART 6. THE KNOCK-ON LIK_GRAD_* ASKS FOR")
# R/likelihood.R: "Re-measure if sigma_co2 or LIK_CO2_REP_ERR move." The two
# station levels price their difference implicitly at sd*sqrt(2); the added
# gradient term must still outweigh that by enough for the double count to stay
# second-order, which is what justified ADDING a term rather than ROTATING the
# (MLO, SPO) pair.
cat(sprintf("%-26s %14s %18s %14s\n", "option", "effective sd",
            "implied grad sd", "variance ratio"))
for (s in SC_OPTIONS) {
  eff <- sqrt(s^2 + LIK_CO2_REP_ERR^2)
  gsd <- eff * sqrt(2)
  lab <- switch(as.character(s), "0" = "DROP (fix at 0)",
                "0.223" = "FIX at the MAP value", "FIX at the prior median")
  cat(sprintf("%-26s %14.4f %18.3f %13.1fx\n", lab, eff, gsd,
              (gsd / LIK_GRAD_CO2_SD)^2))
}
cat(sprintf("\nLIK_GRAD_CO2_SD = %.3f ppm. The added term outweighs the implicit one\n",
            LIK_GRAD_CO2_SD))
cat("by the ratio above; handoff 2026-08-15b sec.3.1 recorded ~17x as the basis for\n")
cat("adding rather than rotating. Anything still well above ~1 leaves that intact.\n")

sep("PART 7. THE ONE ARGUMENT THAT SURVIVES: THE STREAM SETS ITS OWN VOLUME")
# Parts 1-6 dismantle the stated case (no boundary on the sampling scale, no
# correlation, three parameters far wider). But the measurement turns up a
# DIFFERENT objection, which none of the handoffs made, and it is the real one.
#
# sigma_co2 is a free error scale on the stream that already outvotes the
# partition terms 40:1. A free error scale is a self-weighting stream: the
# better the model fits CO2, the smaller sigma goes, and the LOUDER the CO2
# stream becomes. That is positive feedback on the dominant constraint, and it
# operates in the direction that makes the imbalance the whole review is about
# WORSE, not better.
if (length(pts) >= 2) {
  eff <- vapply(seq_along(pts), function(i) {
    s <- prof[[i]]$sigma[which.max(prof[[i]]$lpost)]
    sqrt(s^2 + LIK_CO2_REP_ERR^2)
  }, numeric(1))
  R <- vapply(resid, function(r) sqrt(mean(r$pooled^2)), numeric(1))
  cat(sprintf("%-52s %10s %14s\n", "parameter point", "R_pool", "effective sd"))
  for (i in seq_along(pts))
    cat(sprintf("%-52s %10.3f %14.4f\n", pts[[i]]$label, R[i], eff[i]))
  cat(sprintf("\nAs the fit improved (R %.3f -> %.3f), the CO2 level stream got\n",
              R[1], R[length(R)]))
  cat(sprintf("%.2fx LOUDER in variance terms (effective sd %.4f -> %.4f).\n",
              (eff[1] / eff[length(eff)])^2, eff[1], eff[length(eff)]))
  cat("Nothing in the objective asked for that; it is what a free sigma does.\n")
  cat("Fixing sigma_co2 removes the feedback. It does NOT re-weight the stream\n")
  cat(sprintf("much at the current fit (part 5: %.2fx), but it stops the weight\n",
              (sqrt(SC_OPTIONS[2]^2 + LIK_CO2_REP_ERR^2) / LIK_CO2_REP_ERR)^2))
  cat("moving with the residual on future refits.\n")
  cat("\nTHE COST OF FIXING IT, stated plainly: the free sigma is also the only\n")
  cat("adaptive valve on the CO2 level stream. Part 2 measured the margin at the\n")
  cat(sprintf("mode as %.3f ppm -- MCMC excursions will cross it -- and where they do,\n",
              sqrt(max(0, LIK_CO2_REP_ERR^2 - min(R)^2))))
  cat("a fixed sigma prices a bad CO2 fit at full volume with no give.\n")
}

saveRDS(list(points = lapply(pts, function(p) p$label),
             residual_rms = lapply(resid, function(r)
               c(pooled = sqrt(mean(r$pooled^2)),
                 vapply(r$per, function(x) sqrt(mean(x^2)), numeric(1)))),
             profile = prof, rep_err = LIK_CO2_REP_ERR,
             options = SC_OPTIONS),
        file.path(SC_OUTDIR, "diag_sigma_co2.rds"))
cat(sprintf("\n\nwritten: %s\n", file.path(SC_OUTDIR, "diag_sigma_co2.rds")))
