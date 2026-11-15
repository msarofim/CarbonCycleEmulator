#!/usr/bin/env Rscript
# =====================================================================
# diag_card4_whatif_residuals.R -- card 4's detail, re-measured on the measure card 4a now draws (group B B19,
# Marcus 2026-11-15: "move card 4a to the what-if measure").
#
# WHY. Card 4's detail makes four claims measured on the 10-15 estimator (diag_growth_residual_years.R: model annual-
# mean differences against GCB's Jan-to-Jan atm_growth, 1959-2024, the mismatched pairing that put the two series'
# ENSO peaks 6 months apart; sheet B19):
#   (1) "over sixty-six years";
#   (2) the year-by-year model-minus-record difference "shows no usable association with the ENSO index, with
#       volcanic aerosol, or with the decade: ... none of the three reaches significance";
#   (3) "the decade averages all sit well inside one year's scatter";
#   (4) "The single largest overshoot is 1991 ... but 1983, the year after El Chichon, misses the other way".
# This re-measures each on the What if...? tab's measure, the one card 4a draws since 11-15: app_annual_growth(APP_HIST
# $out) against app_obs_growth(APP_OBS_GROWTH) (NOAA MBL, annual means differenced), on the tab's opening window cut to
# the record, each series' anomaly about the tab's decadal smooth (app_growth_window(), app_growth_anom(); plots.R).
# The residual is model anomaly minus record anomaly (+ = the model grew faster than the record that year), as before.
# The ENSO index and the AOD are the run's own drivers (the forcing's `enso` and the hemispheric AOD mean, calendar-
# year means), as diag_growth_residual_years.R used; the observed Nino 3.4 at card 4a's lag is reported beside them.
# RNG only in the robustness bootstrap (seed stamped in the log and the .rds). Usage: Rscript calibration/diag_card4_whatif_residuals.R   (repo root; read-only; ~1 min)
# =====================================================================
ROOT <- normalizePath(getwd()); stopifnot(file.exists(file.path(ROOT, "app", "global.R")))
setwd(file.path(ROOT, "app"))
invisible(capture.output(suppressMessages(suppressWarnings(
  shiny::loadSupport(getwd(), renv = globalenv(), globalrenv = globalenv())))))
setwd(ROOT)

CW_DRIVER <- "calibration/diag_card4_whatif_residuals.R"
CW_TOP    <- 6L        # extreme years named at each end
CW_ALPHA  <- 0.05      # "reaches significance" = two-sided p below this
CW_DECADE <- 10L
CW_DEC_MIN_N <- 5L     # a decade with fewer years in the window is shown but not called a decade average
CW_ERUPT  <- c(`El Chichon` = 1982L, Pinatubo = 1991L)   # the card names the year after each eruption and the eruption year
CW_STEM <- file.path("outputs", "diagnostics", sprintf("card4_whatif_residuals_%s_%s", format(Sys.Date(), "%Y%m%d"),
                                                       CCX_MODE_CANONICAL))
commit <- ccx_git_stamp(); dirty <- ccx_stamp_dirty(commit)
mode_file <- ccx_mode_file(); md5 <- unname(tools::md5sum(mode_file))
LOG <- paste0(CW_STEM, ".log"); if (file.exists(LOG)) file.remove(LOG)
say <- function(...) { txt <- sprintf(...); cat(txt); cat(txt, file = LOG, append = TRUE) }
say("%s | commit %s%s | canonical %s (md5 %s) | %s\n", CW_DRIVER, commit, if (dirty) " (dirty)" else "",
    CCX_MODE_CANONICAL, md5, format(Sys.time(), "%Y-%m-%d %H:%M"))

# ---- the series: card 4a's (rv_growth_variability()), plus the residual and the drivers ---------------------------
v <- rv_growth_variability()
F <- app_build_forcing("historical", APP_HIST_YEARS, prod_c14 = APP_SPIN$prod_c14)
ann <- function(t, x) { a <- stats::aggregate(list(x = x), list(year = floor(t + 1e-9)), mean); stats::setNames(a$x, a$year) }
en <- ann(F$t, F$enso); ao <- ann(F$t, (F$aod_NH + F$aod_SH) / 2)
nino <- rv_enso_annual(RV_GROWTH_ENSO_LAG_MO)
d <- data.frame(year = v$years, m_a = v$model_anom, o_a = v$obs_anom)
d$res <- d$m_a - d$o_a
d$enso <- unname(en[as.character(d$year)]); d$aod <- unname(ao[as.character(d$year)])
d$nino_lag <- unname(nino[as.character(d$year)])
stopifnot(!anyNA(d$enso), !anyNA(d$aod))
say("card 4a's measure: %d-%d, n = %d (the What if...? tab's window from APP_CF_YEARS_DEFAULT %d-%d, cut to the record)\n",
    min(d$year), max(d$year), nrow(d), APP_CF_YEARS_DEFAULT[1], APP_CF_YEARS_DEFAULT[2])
say("  anomaly sd: model %.3f, record %.3f ppm/yr (ratio %.3f); residual mean %+.3f, sd %.3f ppm/yr\n",
    v$sd_model, v$sd_obs, v$ratio, mean(d$res), stats::sd(d$res))
say("  ENSO r (Nino 3.4, twelve months to %s; lag %d): model %+.3f, record %+.3f, n %d\n",
    rv_lag_month(RV_GROWTH_ENSO_LAG_MO), RV_GROWTH_ENSO_LAG_MO, v$enso$r_model, v$enso$r_obs, v$enso$n)

# ---- claim (2): is the residual associated with ENSO, volcanic aerosol, or the decade? ---------------------------
say("\n=== claim 2: the residual's association (two-sided p; 'significant' = p < %.2f) ===\n", CW_ALPHA)
cors <- do.call(rbind, lapply(list(
  c("ENSO index (the run's driver, calendar year)", "enso"),
  c(sprintf("observed Nino 3.4, card 4a's lag (%d mo)", RV_GROWTH_ENSO_LAG_MO), "nino_lag"),
  c("volcanic AOD (the run's driver)", "aod"),
  c("year (a trend; the decade)", "year")), function(z) {
  ct <- stats::cor.test(d$res, d[[z[2]]])
  data.frame(what = z[1], r = unname(ct$estimate), p = ct$p.value, n = nrow(d))
}))
for (i in seq_len(nrow(cors))) with(cors[i, ], say("  %-46s r %+.3f  p %.3f  n %d  %s\n", what, r, p, n,
                                                   if (p < CW_ALPHA) "<- SIGNIFICANT" else ""))
r_crit <- stats::qt(1 - CW_ALPHA / 2, nrow(d) - 2) / sqrt(nrow(d) - 2 + stats::qt(1 - CW_ALPHA / 2, nrow(d) - 2)^2)
say("  |r| needed for p < %.2f at n = %d: %.3f\n", CW_ALPHA, nrow(d), r_crit)
three <- cors[c(1, 3, 4), ]
say("  -> the card's three (ENSO driver, AOD, year): %s\n",
    if (all(three$p >= CW_ALPHA)) "NONE reaches significance (claim 2 holds)" else "AT LEAST ONE reaches significance (claim 2 FAILS)")

# ---- claim (3): decade averages against one year's scatter -------------------------------------------------------
say("\n=== claim 3: decade averages of the residual against one year's scatter (residual sd %.3f) ===\n", stats::sd(d$res))
d$decade <- (d$year %/% CW_DECADE) * CW_DECADE
dec <- do.call(rbind, lapply(split(d, d$decade), function(x)
  data.frame(decade = x$decade[1], n = nrow(x), mean = mean(x$res), se = stats::sd(d$res) / sqrt(nrow(x)))))
for (i in seq_len(nrow(dec))) with(dec[i, ], say("  %ds  n %2d  mean %+.3f  (%.2f of one year's sd)%s\n", decade, n, mean,
                                                 abs(mean) / stats::sd(d$res), if (n < CW_DEC_MIN_N) "  [partial decade]" else ""))
full_dec <- dec[dec$n >= CW_DEC_MIN_N, ]
say("  -> largest |decade mean| (decades with >= %d years): %.2f of one year's sd\n", CW_DEC_MIN_N,
    max(abs(full_dec$mean)) / stats::sd(d$res))

# ---- claim (4): the largest overshoot and the eruption years ----------------------------------------------------
say("\n=== claim 4: the %d largest overshoots and undershoots (+ = the model grew faster) ===\n", CW_TOP)
o <- d[order(-d$res), ]; u <- d[order(d$res), ]
say("  overshoots:  %s\n", paste(sprintf("%d %+.3f", o$year[1:CW_TOP], o$res[1:CW_TOP]), collapse = ", "))
say("  undershoots: %s\n", paste(sprintf("%d %+.3f", u$year[1:CW_TOP], u$res[1:CW_TOP]), collapse = ", "))
d$rank_over <- rank(-d$res); d$z <- (d$res - mean(d$res)) / stats::sd(d$res)
for (nm in names(CW_ERUPT)) for (y in CW_ERUPT[[nm]] + 0:1) {
  k <- d$year == y
  if (any(k)) say("  %d (%s%s): residual %+.3f, z %+.2f, overshoot rank %d of %d\n", y, nm,
                  if (y == CW_ERUPT[[nm]]) ", eruption year" else ", the year after", d$res[k], d$z[k], d$rank_over[k], nrow(d))
}
say("  -> the single largest overshoot is %d (%+.3f); 1991 is %s\n", o$year[1], o$res[1],
    if (o$year[1] == 1991L) "the largest (claim 4's first half holds)" else "NOT the largest (claim 4's first half FAILS)")

# ---- robustness of claim 2's two associations -------------------------------------------------------------------
# AOD is two eruptions and near-zero elsewhere, so a Pearson p on it can rest on a handful of years. Three checks: the
# rank correlation, the correlation without the eruption years and the two after each, and a 90 % interval from a
# moving-block bootstrap over years (seed CW_SEED set immediately before each resampling, stamped below).
CW_SEED <- 20261115L; CW_B <- 5000L; CW_BLOCK <- 3L; CW_CI <- c(0.05, 0.95)
CW_DROP <- unlist(lapply(CW_ERUPT, function(y) y + 0:2))
blk <- function(n, L) { s <- sample.int(n - L + 1L, ceiling(n / L), replace = TRUE)
  as.vector(unlist(lapply(s, function(a) a:(a + L - 1L))))[seq_len(n)] }
say("\n=== robustness of the residual's associations (block bootstrap %d yr, B %d, seed %d; drop = %s) ===\n",
    CW_BLOCK, CW_B, CW_SEED, paste(CW_DROP, collapse = ","))
rob <- do.call(rbind, lapply(c(enso = "enso", aod = "aod"), function(col) {
  sp <- stats::cor.test(d$res, d[[col]], method = "spearman", exact = FALSE)
  k <- !d$year %in% CW_DROP; dr <- stats::cor.test(d$res[k], d[[col]][k])
  set.seed(CW_SEED)                       # immediately before the call that consumes the stream
  bs <- replicate(CW_B, { i <- blk(nrow(d), CW_BLOCK); stats::cor(d$res[i], d[[col]][i]) })
  ci <- stats::quantile(bs, CW_CI, names = FALSE)
  data.frame(driver = col, spearman = unname(sp$estimate), spearman_p = sp$p.value, r_drop = unname(dr$estimate),
             p_drop = dr$p.value, n_drop = sum(k), ci_lo = ci[1], ci_hi = ci[2])
}))
for (i in seq_len(nrow(rob))) with(rob[i, ], say(paste0("  %-5s Spearman %+.3f (p %.3f) | without the eruption years %+.3f (p %.3f, n %d)",
  " | 90%% interval [%+.3f, %+.3f] %s\n"), driver, spearman, spearman_p, r_drop, p_drop, n_drop, ci_lo, ci_hi,
  if (ci_lo > 0 && p_drop < CW_ALPHA) "<- ROBUST" else "<- rests on the eruption years"))
say("  lag-1 autocorrelation of the residual: %+.3f\n", stats::acf(d$res, plot = FALSE)$acf[2])
top5 <- o$year[1:5]
say("  the five largest overshoots: %s; of them in 1991-1993: %d\n", paste(top5, collapse = ", "), sum(top5 %in% 1991:1993))

saveRDS(list(series = d, correlations = cors, decades = dec, r_crit = r_crit, robustness = rob,
             seed = sprintf("set.seed(%d) immediately before each bootstrap (%d replicates, block %d yr)", CW_SEED, CW_B, CW_BLOCK),
             provenance = list(driver = CW_DRIVER, commit = commit, dirty = dirty, canonical = CCX_MODE_CANONICAL,
                               mode_md5 = md5, measure = "rv_growth_variability() (app/R/review.R): app_annual_growth vs app_obs_growth, app_growth_window(APP_CF_YEARS_DEFAULT), app_growth_anom()",
                               drivers = "app_build_forcing('historical') $enso and (aod_NH + aod_SH)/2, calendar-year means; observed Nino 3.4 via rv_enso_annual()",
                               rng = sprintf("bootstrap only: seed %d, B %d, block %d", CW_SEED, CW_B, CW_BLOCK), date = format(Sys.time(), "%Y-%m-%d %H:%M"))),
        paste0(CW_STEM, ".rds"))
say("\nsaved %s.{log,rds}\n", CW_STEM)
