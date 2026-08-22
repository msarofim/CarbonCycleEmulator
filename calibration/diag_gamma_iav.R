# =====================================================================
# diag_gamma_iav.R -- WOULD AN INTERANNUAL CONSTRAINT ACTUALLY PIN q10?
#
# Handoff 21d sec.11a: the land sink misses GCB by +2.04 sd, `q10` is the only
# clean lever (1.09 -> 2.0 takes it to +0.94 sd for +4.5 ppm), and `q10` sits at
# 1.0907 because the SEASONAL rows put it there through the exact ridge with
# `seas_T_amp_NH` -- rows that move only 4.3 log-units across the whole q10
# range (21c sec.2). So q10 is set by a seasonal amplitude prior and by no
# annual carbon observation, and `beta_max`/`fert_k` absorb 85 % of any change.
#
# THE STANDARD MISSING OBSERVABLE is the INTERANNUAL sensitivity of the CO2
# growth rate to temperature -- gamma_IAV. It separates the TEMPERATURE
# sensitivity of land carbon from the CO2 sensitivity, which is exactly the
# separation nothing in this likelihood currently makes: the seasonal rows score
# a within-year amplitude, and the GCB rows score a decadal LEVEL. Neither
# scores a year-to-year COVARIANCE.
#
# ***THIS SCRIPT DOES NOT ADD ANYTHING TO THE OBJECTIVE.*** Adding a likelihood
# term changes the objective, and in this repo that means REFIT OWED and nothing
# comparable across it. So this measures, first, whether the term would bite at
# all -- and it is built so the answer can be NO:
#
#   Q1  What IS the model's gamma_IAV, and what is the observed one?
#   Q2  Does gamma_IAV move with q10? If not, the term cannot identify q10 and
#       the whole proposal is dead. THIS IS THE KILL SWITCH.
#   Q3  Does it move MORE with `gamma_enso`? The model already has an explicit
#       ENSO->soil flux with a WIDE N(0, 2) prior, fitted at 0.787. If that
#       channel dominates the IAV response, a gamma_IAV term would be absorbed
#       by `gamma_enso` and would NOT reach q10 -- the same compensation trap
#       that beta_max/fert_k set for q10 in the annual budget. A constraint that
#       a nuisance parameter can eat is not a constraint.
#
# METHODOLOGICAL CHOICES, FLAGGED RATHER THAN BURIED (per the standing rule --
# these are NOT resolved here, they are reported so the sensitivity is visible):
#
#  (a) TEMPERATURE. The literature constraint (Cox et al. 2013) uses TROPICAL
#      LAND temperature; this repo has only GLOBAL MEAN SURFACE TEMPERATURE, and
#      the model's own q10 acts on `forc$gmst`. GMST is therefore the
#      SELF-CONSISTENT choice for asking "does this model's q10 show up in its
#      IAV", and it is NOT the same quantity as the published gamma_IAV. No
#      literature value is quoted here for that reason.
#  (b) DETRENDING. The regression is of growth-rate anomaly on temperature
#      anomaly, and "anomaly" is a choice. Both a quadratic detrend and a
#      first-difference filter are run; if the two disagree the number is not
#      robust enough to score.
#  (c) WINDOW. 1959-2024, the era with a continuous flask record.
#
# Usage:  Rscript calibration/diag_gamma_iav.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

GI_MODE_FILE <- file.path("calibration", "output", "pump_arms", "mode_fit_pumpN.rds")
GI_YEARS     <- c(1750, 2024)
GI_WIN       <- c(1959, 2024)
GI_Q10       <- c(1.0907, 1.5, 2.0, 2.5)
GI_ENSO      <- c(0, 0.7868, 1.5, 3.0)
GI_PPM_PER_GTC <- 1 / ccx_const("GtC_PER_PPM")

md <- readRDS(GI_MODE_FILE); pm <- md$par_mode
p0 <- ccx_default_params()
for (n in intersect(names(p0), CCX_PARAM_NAMES)) p0[[n]] <- pm[[n]]
p0$pump_mode <- md$pump_mode

gm <- as.data.frame(readRDS(ccx_path("data", "forcing_gmst.rds")))

#' gamma_IAV: slope of detrended CO2 growth rate on detrended temperature.
#' Returned in ppm/yr/K AND GtC/yr/K; the second is the comparable unit.
gi_gamma <- function(year, co2, method = "quad") {
  d <- data.frame(year = year, co2 = co2)
  d <- d[d$year >= GI_WIN[1] & d$year <= GI_WIN[2], ]
  d$gr <- c(NA, diff(d$co2))                       # ppm/yr, calendar-year
  d$t  <- gm$gmst_anom[match(d$year, gm$year)]
  d <- d[stats::complete.cases(d), ]
  if (identical(method, "diff")) {
    # First differences of BOTH series: kills any smooth trend in either without
    # assuming a functional form, at the cost of amplifying high-frequency noise.
    x <- diff(d$t); y <- diff(d$gr)
  } else {
    # Quadratic in year removed from both: keeps more signal, assumes the trend
    # is smooth over 66 years.
    x <- stats::residuals(stats::lm(t  ~ poly(year, 2), data = d))
    y <- stats::residuals(stats::lm(gr ~ poly(year, 2), data = d))
  }
  fit <- summary(stats::lm(y ~ x))$coefficients
  c(ppm = fit["x", "Estimate"], se = fit["x", "Std. Error"],
    gtc = fit["x", "Estimate"] / GI_PPM_PER_GTC,
    se_gtc = fit["x", "Std. Error"] / GI_PPM_PER_GTC, n = length(x))
}

gi_run <- function(p) {
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", GI_YEARS, prod_c14 = sp$prod_c14,
                          bomb_total_kmol = pm$bomb_total, luc_scale = pm$luc_scale)
  o  <- ccx_run_fast(sp, F)$out
  g  <- (o$co2_NH + o$co2_SH) / 2
  y  <- tapply(g, floor(o$t + 1e-9), mean)
  list(year = as.numeric(names(y)), co2 = as.numeric(y))
}

# ---- OBSERVED -------------------------------------------------------
# MLO + SPO annual means averaged: the closest this repo has to a global mean,
# and the same two stations the likelihood scores.
obs <- ccx_prepare_obs()$co2
oy  <- do.call(rbind, lapply(c("MLO", "SPO"), function(st) {
  d <- obs[obs$station == st, ]
  a <- tapply(d$co2_ppm, floor(d$decimal_date + 1e-9), mean)
  data.frame(year = as.numeric(names(a)), co2 = as.numeric(a), st = st)
}))
og <- stats::aggregate(co2 ~ year, oy[oy$year %in%
        intersect(oy$year[oy$st == "MLO"], oy$year[oy$st == "SPO"]), ], mean)

cat(sprintf("window %d-%d\n\n", GI_WIN[1], GI_WIN[2]))
cat(sprintf("%-28s %10s %10s %12s\n", "series", "ppm/yr/K", "+/- se", "GtC/yr/K"))
for (mth in c("quad", "diff")) {
  g <- gi_gamma(og$year, og$co2, mth)
  cat(sprintf("%-28s %10.3f %10.3f %12.2f\n",
              sprintf("OBSERVED (MLO+SPO, %s)", mth), g[["ppm"]], g[["se"]], g[["gtc"]]))
}

# ---- Q2: THE KILL SWITCH -- does gamma_IAV move with q10? ----------
cat("\nQ2 -- does gamma_IAV respond to q10? (all other parameters at the mode)\n")
cat(sprintf("  %-14s %12s %12s %12s %12s\n", "q10", "quad ppm", "quad GtC", "diff ppm", "diff GtC"))
gq <- list()
for (q in GI_Q10) {
  p <- p0; p$q10 <- q; r <- gi_run(p)
  a <- gi_gamma(r$year, r$co2, "quad"); b <- gi_gamma(r$year, r$co2, "diff")
  gq[[as.character(q)]] <- a
  cat(sprintf("  %-14s %12.3f %12.2f %12.3f %12.2f\n",
              sprintf("%.4f%s", q, if (abs(q - pm$q10) < 1e-6) "*" else ""),
              a[["ppm"]], a[["gtc"]], b[["ppm"]], b[["gtc"]]))
}
span_q <- gq[[as.character(GI_Q10[length(GI_Q10)])]][["ppm"]] - gq[[as.character(GI_Q10[1])]][["ppm"]]

# ---- Q3: the compensation trap -- does gamma_enso move it more? ----
cat("\nQ3 -- does `gamma_enso` move gamma_IAV MORE? (the absorption test)\n")
cat(sprintf("  %-14s %12s %12s\n", "gamma_enso", "quad ppm", "quad GtC"))
ge <- list()
for (e in GI_ENSO) {
  p <- p0; p$gamma_enso <- e; r <- gi_run(p)
  a <- gi_gamma(r$year, r$co2, "quad"); ge[[as.character(e)]] <- a
  cat(sprintf("  %-14s %12.3f %12.2f\n",
              sprintf("%.4f%s", e, if (abs(e - pm$gamma_enso) < 1e-3) "*" else ""),
              a[["ppm"]], a[["gtc"]]))
}
span_e <- ge[[as.character(GI_ENSO[length(GI_ENSO)])]][["ppm"]] - ge[[as.character(GI_ENSO[1])]][["ppm"]]

# ---- VERDICT --------------------------------------------------------
# Per-prior-sigma leverage is the honest comparison: gamma_enso has a WIDE
# N(0, 2) prior and q10 a tight one, so raw ranges flatter whichever parameter
# was given more room. What decides absorption is how far each can move within
# ITS OWN prior.
q_sd <- md$sd_unc[["q10"]]; e_sd <- md$sd_unc[["gamma_enso"]]
lev_q <- span_q / (max(GI_Q10) - min(GI_Q10)) * q_sd
lev_e <- span_e / (max(GI_ENSO) - min(GI_ENSO)) * e_sd
obs_se <- gi_gamma(og$year, og$co2, "quad")[["se"]]
cat(sprintf("\nVERDICT\n"))
cat(sprintf("  gamma_IAV span over q10 %.2f-%.2f            : %+.3f ppm/yr/K\n",
            min(GI_Q10), max(GI_Q10), span_q))
cat(sprintf("  gamma_IAV span over gamma_enso %.1f-%.1f       : %+.3f ppm/yr/K\n",
            min(GI_ENSO), max(GI_ENSO), span_e))
cat(sprintf("  per POSTERIOR sd: q10 (sd %.4f) %+.4f | gamma_enso (sd %.3f) %+.4f  -> ratio %.2f\n",
            q_sd, lev_q, e_sd, lev_e, abs(lev_e / lev_q)))
cat(sprintf("  observed gamma_IAV standard error            : %.3f ppm/yr/K\n", obs_se))
cat(sprintf("  q10 1.09->2.5 is %.2f observed SE of signal; gamma_enso's range is %.2f\n",
            abs(span_q) / obs_se, abs(span_e) / obs_se))
cat(sprintf("  => %s\n", if (abs(span_q) < obs_se)
     "DEAD: q10 does not move gamma_IAV by even one observational SE. Do not add the term."
   else if (abs(lev_e) > abs(lev_q))
     "ABSORBED: gamma_enso has more leverage per prior sd. The term would be eaten, not reach q10."
   else "LIVE: q10 has the leverage and gamma_enso cannot eat it. Worth proposing."))
