# =====================================================================
# diag_fert_k_prior_width.R -- WOULD A TIGHTER fert_k PRIOR BE CONSISTENT WITH
# THE SCIENCE, AND WHAT WOULD IT DO? (CHANGELOG 2026-09-30 e)
# Marcus 2026-09-30: "Tighten the K prior if that is consistent with the
# underlying science."
#
# TWO QUESTIONS, ANSWERED FROM DATA ALREADY ON DISK (no model runs):
#  (1) WHAT WIDTH DOES THE EVIDENCE SUPPORT? The prior (data/prior_fert_k.rds) is
#      lognormal, median = geometric mean of Walker 2021 and Varney 2024's K,
#      log-sd 0.35 BY RULING. Neither source states an uncertainty that can be
#      propagated to K (Walker's +/- is unlabelled; Varney gives a ratio of
#      ensemble means). The one per-member SPREAD of the shape on disk is our
#      CMIP6 1pctCO2-bgc GPP extraction (16 ESMs, notes/lit_2026-09-28_cmip6_gpp/),
#      ruled a COMPARISON for the centre -- used here only for the WIDTH.
#  (2) WHAT WOULD A GIVEN WIDTH DO? The 09-30 (d) fertilisation profile's SHAPE
#      rows (K pinned with beta_max solved to hold enh(410 ppm); 9 names
#      rebalanced) give the likelihood along K. A quadratic in ln K through the
#      control and the two shape rows, combined with the lognormal prior, gives
#      the posterior K for any width. VALIDATION: at the ruled 0.35 it must
#      return the fitted K (the control was fitted under that prior).
#  ⚠ The path holds enh(410) rather than re-optimising beta_max, so its costs
#  are UPPER bounds and the likelihood may be flatter than measured; the table
#  also reports a likelihood 1.5x wider.
# No RNG. USAGE: Rscript calibration/diag_fert_k_prior_width.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
KW_PROFILE  <- ccx_path("outputs", "diagnostics", "fert_profile_fixedstock_20260930.rds")
KW_CMIP6    <- file.path("notes", "lit_2026-09-28_cmip6_gpp", "gpp_shape_summary.csv")
KW_EXCLUDE  <- "IPSL-CM6A-LR"          # flagged a probable artefact in the 09-28 lit note (R 1.11)
KW_WIDTHS   <- c(0.37, 0.35, 0.30, 0.26, 0.20, 0.14)
KW_TARGETS  <- c(750, 625)            # the 09-28 (c) band's top and the band middle's K
KW_LIK_WIDEN <- 1.5
KW_OUT      <- ccx_path("outputs", "diagnostics", "fert_k_prior_width_20260930.log")
COMMIT      <- ccx_git_stamp()

pr <- readRDS(ccx_path("data", "prior_fert_k.rds"))
d  <- utils::read.csv(KW_CMIP6)
k_all <- d$K_implied_ppm[is.finite(d$K_implied_ppm) & d$K_implied_ppm > 0]
k_ex  <- d$K_implied_ppm[!d$model %in% KW_EXCLUDE & d$K_implied_ppm > 0]

fp  <- readRDS(KW_PROFILE)
row <- function(lab) fp[[which(vapply(fp, function(r) identical(r$value, lab), logical(1)))]]
ctl <- fp[[1]]; stopifnot(isTRUE(ctl$control))
pts <- list(ctl, row("shape_K625"), row("shape_K500"))
K   <- vapply(pts, function(r) r$pin[["fert_k"]], numeric(1))
L   <- vapply(pts, function(r) r$ll1 - ctl$ll1, numeric(1))
x   <- log(K) - log(K[1])
co  <- solve(cbind(x^2, x)[2:3, ], L[2:3]); a <- co[1]; b <- co[2]
stopifnot(a < 0)                                          # concave, or there is no optimum to report
mL <- log(K[1]) - b / (2 * a); sL <- 1 / sqrt(-2 * a); mu <- log(pr$median_ppm)
post <- function(s, sl = sL) exp((mL / sl^2 + mu / s^2) / (1 / sl^2 + 1 / s^2))
need <- function(Kt, sl = sL) 1 / sqrt((mL - log(Kt)) / (sl^2 * (log(Kt) - mu)))

sink(KW_OUT, split = TRUE)
cat(sprintf("=== PROVENANCE === calibration/diag_fert_k_prior_width.R @%s, run %s; no RNG\n", COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M")))
cat(sprintf("  prior: lognormal median %.1f ppm (Walker %.1f, Varney %.1f), log-sd %.2f (%s)\n",
            pr$median_ppm, pr$K_walker, pr$K_varney, pr$log_sd, pr$log_sd_is))
cat(sprintf("  profile: %s (shape rows hold enh(410 ppm); d_loglik rebalanced)\n\n", basename(KW_PROFILE)))
cat("(1) EVIDENCE SPREAD of K across CMIP6 ESMs (GPP, 1pctCO2-bgc, MM-implied K from R = gain4x/gain2x)\n")
cat(sprintf("  all %d: median %.0f, log-sd %.3f  |  excl %s (%d): geo-mean %.0f, log-sd %.3f, MAD log-sd %.3f\n",
            length(k_all), stats::median(k_all), stats::sd(log(k_all)), paste(KW_EXCLUDE, collapse = ","),
            length(k_ex), exp(mean(log(k_ex))), stats::sd(log(k_ex)), stats::mad(log(k_ex))))
cat(sprintf("  models with K >= the fitted %.0f: %d of %d\n\n", K[1], sum(d$K_implied_ppm >= K[1]), nrow(d)))
cat("(2) LIKELIHOOD along the shape path: points (K, d_loglik) =",
    paste(sprintf("(%.0f, %+.2f)", K, L), collapse = " "), "\n")
cat(sprintf("  quadratic in ln K: likelihood optimum K %.0f, sd(ln K) %.3f\n", exp(mL), sL))
cat(sprintf("  VALIDATION: posterior at the ruled log-sd %.2f = K %.0f vs fitted %.1f\n\n", pr$log_sd, post(pr$log_sd), K[1]))
cat(sprintf("  %8s %14s %22s\n", "log-sd", "posterior K", sprintf("(likelihood x%.1f wider)", KW_LIK_WIDEN)))
for (s in KW_WIDTHS) cat(sprintf("  %8.2f %14.0f %22.0f\n", s, post(s), post(s, KW_LIK_WIDEN * sL)))
for (Kt in KW_TARGETS) cat(sprintf("  log-sd needed for posterior K = %.0f: %.3f (likelihood x%.1f wider: %.3f)\n",
                                   Kt, need(Kt), KW_LIK_WIDEN, need(Kt, KW_LIK_WIDEN * sL)))
sink()
