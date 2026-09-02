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

GI_MODE_FILE <- ccx_mode_file()
GI_YEARS     <- c(1750, 2024)
GI_WIN       <- c(1959, 2024)
GI_Q10       <- c(1.0907, 1.5, 2.0, 2.5)
GI_ENSO      <- c(0, 0.7868, 1.5, 3.0)
GI_PPM_PER_GTC <- 1 / ccx_const("GtC_PER_PPM")

md <- readRDS(GI_MODE_FILE)
# ⛔ FIXED 2026-09-02. This read `md$par_mode` RAW and then did
#     for (n in intersect(names(p0), CCX_PARAM_NAMES)) p0[[n]] <- pm[[n]]
# `from90` is a PRE-SPLIT 21-parameter ancestor, so `pm[["gamma_enso_land_NH"]]`
# is NULL -- and ASSIGNING NULL DELETES THE ELEMENT. All four ENSO names
# vanished, `ccx_gamma_enso()` found neither the split names nor the scalar and
# returned zeros, and **every scan in this file ran with ENSO OFF**, including
# the q10 scan whose whole point is whether the explicit ENSO term absorbs q10.
# MEASURED COST: 3.68 ppm of CO2_NH over 1960-2000 against the correctly
# migrated vector. [[intersect_is_a_silent_default]]
#
# ⭐ THE ORDERING BELOW IS LOAD-BEARING AND WAS UNDOCUMENTED. `dg_vector()` in
# calibration/lib_design_gates.R uses the SAME idiom and is safe ONLY because
# the next line calls `ccx_set_enso()`, which repairs the deletion. Migrate,
# copy, THEN repair -- in that order.
pm <- ccx_migrate_par_set(md$par_mode)
p0 <- ccx_overlay_par(ccx_default_params(), pm)   # migrate, copy, repair, ASSERT
p0$pump_mode <- md$pump_mode
GI_GE <- ccx_gamma_enso(pm)
cat(sprintf("mode %s, migrated: %s\n", basename(GI_MODE_FILE),
            paste(attr(pm, "migrated"), collapse = ", ")))
cat(sprintf("ENSO at the mode: land NH %+.4f  land SH %+.4f  ocn NH %+.4f  ocn SH %+.4f\n",
            GI_GE[["land_NH"]], GI_GE[["land_SH"]], GI_GE[["ocn_NH"]], GI_GE[["ocn_SH"]]))
stopifnot(any(unlist(GI_GE) != 0))   # the deletion this file used to suffer, gated

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
# ⚠ THIS SWEEP IS A SCALAR SLICE THROUGH A FOUR-DIMENSIONAL SPACE since the
# 2026-09-01 split. `ccx_set_enso(p, list(gamma_enso = e))` fills all four
# coefficients from one scalar, so the sweep moves land and ocean, NH and SH,
# together -- which is the pre-split model's one degree of freedom and is the
# right SLICE for an absorption question, but it is not the fitted geometry.
# The mode's four are ANTIsymmetric (land -0.2457 / +1.3583), so there is no
# single scalar to mark a row with; the mode's own values are printed above
# instead of a `*` against one sweep point.
# ⚠ AND SINCE 2026-09-02 the land half is a ONE-WAY GPP MODULATION, not a
# signed soil_fast flux ([[ccx_enso_gpp_modulation]]), so these numbers are not
# comparable with any run of this file before that date -- which is the whole
# reason it is being re-run.
cat("\nQ3 -- does `gamma_enso` move gamma_IAV MORE? (the absorption test)\n")
cat(sprintf("  %-14s %12s %12s\n", "gamma_enso", "quad ppm", "quad GtC"))
ge <- list()
for (e in GI_ENSO) {
  p <- p0; p <- ccx_set_enso(p, list(gamma_enso = e)); r <- gi_run(p)
  a <- gi_gamma(r$year, r$co2, "quad"); ge[[as.character(e)]] <- a
  cat(sprintf("  %-14s %12.3f %12.2f\n", sprintf("%.4f", e), a[["ppm"]], a[["gtc"]]))
}
span_e <- ge[[as.character(GI_ENSO[length(GI_ENSO)])]][["ppm"]] - ge[[as.character(GI_ENSO[1])]][["ppm"]]

# ---- VERDICT --------------------------------------------------------
# Per-prior-sigma leverage is the honest comparison: gamma_enso has a WIDE
# N(0, 2) prior and q10 a tight one, so raw ranges flatter whichever parameter
# was given more room. What decides absorption is how far each can move within
# ITS OWN prior.
# ⚠ THESE ARE 21-PARAMETER POSTERIOR SDs read out of a pre-split mode file, used
# in a 25-parameter build. `gamma_enso`'s is the SCALAR's sd, which is the right
# scale for the scalar SLICE this file sweeps -- but it is not the sd of any of
# the four fitted coefficients, and no 25-par posterior exists to supply one
# ([[ccx_hessian_is_the_blocker]]). Named here rather than left implicit.
q_sd <- md$sd_unc[["q10"]]; e_sd <- md$sd_unc[["gamma_enso"]]
stopifnot(is.finite(q_sd), is.finite(e_sd))
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
