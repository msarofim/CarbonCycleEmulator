# =====================================================================
# diag_gradient_terms.R -- REVIEW ITEM 5, the measurement before the decision.
#
# THE QUESTION. Review sec.2.3: DESIGN sec.6 gate 9 says the MLO-SPO gradient is
# "the main constraint on tau_ex", and THERE IS NO GRADIENT TERM IN THE
# OBJECTIVE. MLO and SPO are scored as two independent levels, which prices the
# gradient only implicitly and loosely. 66 % of tau_ex's leverage comes instead
# from the seasonal-harmonic terms -- the interhemispheric exchange time is
# being set by the shape of the Keeling sawtooth.
#
# This file does NOT add the term. It measures the five things that have to be
# known before its sigma can be chosen, because the sigma IS the decision:
#
#  1. THE OBSERVED GRADIENT, through the likelihood's own annual estimator, and
#     whether that estimator reproduces gate 9's decadal table. If it does, the
#     term is nearly free; if it does not, the term needs its own estimator.
#  2. THE OBSERVATIONAL ERROR ON THE GRADIENT, measured from the two independent
#     programs in the repo rather than assumed. This is a FLOOR on the sigma.
#  3. WHETHER THE MODEL'S MISS IS AN OFFSET OR A SCALING. A two-box model's
#     NH-box minus SH-box is NOT the same quantity as MLO minus SPO -- MLO at
#     19.5 N is not the northern hemisphere's mean. If the miss is a constant
#     offset it is mostly REPRESENTATION and scoring it tightly would force the
#     model to reproduce a quantity it does not have. If the miss SCALES with
#     the gradient it is the source split or the transport time, which is what
#     the term is for. These are different hypotheses and this part separates
#     them rather than assuming the second.
#  4. WHAT THE OBJECTIVE ALREADY IMPLIES for the gradient -- the effective sigma
#     the two independent station levels give it -- because an added term
#     DOUBLE-COUNTS that information and the size of the double count decides
#     whether the honest formulation is an added term or a rotation.
#  5. THE LEVERAGE a candidate term would carry, per prior sd, on tau_ex and on
#     the two hemispheric shares -- against the 40:1 imbalance the whole review
#     is about. A term that adds 3 log-units to a 1,565-log-unit stream is
#     decoration.
#
# RUNTIME ~3 min.
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

# ---- named constants: every label and window below derives from these ----
GT_YEARS   <- c(1750, 2024)
GT_SIGMA   <- list(sigma_co2 = 1.5, sigma_d13c = 0.44, sigma_d14c = 5)
GT_WIN     <- c(2015, 2024)      # the "recent gradient" reporting window
GT_MODE    <- ccx_path("calibration", "output", "mode_fit.rds")
# DESIGN sec.6 gate 9, decadal, seasonally adjusted, paired months
GT_GATE9   <- c(`1950` = 0.47, `1960` = 0.85, `1970` = 1.66, `1980` = 1.96,
                `1990` = 2.32, `2000` = 2.72, `2010` = 3.66, `2020` = 3.97)
GT_D13C_OBS_WIN <- -0.074        # permil, MLO-SPO, handoff 13i
GT_TAU_EX_PRIOR_SD <- 0.25       # log sd, CCX_PARAM_TABLE$tau_ex
GT_SIGMA_TRIAL <- c(0.20, 0.35, 0.50, 1.00)   # ppm, candidate gradient sigmas

sep <- function(s) cat(sprintf("\n\n=== %s ===\n", s))

# ---------------------------------------------------------------------
sep("PART 1. THE OBSERVED GRADIENT, THROUGH THE LIKELIHOOD'S OWN ESTIMATOR")
# ccx_year_harmonic() already removes the seasonal cycle and the within-year
# trend per station per year, which is exactly the adjustment gate 9 warns is
# "mandatory, not cosmetic". If the annual differences of its levels reproduce
# gate 9's decadal table, the gradient term costs no new estimator and inherits
# the property that model and observations pass through identical machinery
# (design note 1b).
# ---------------------------------------------------------------------
co2 <- as.data.frame(readRDS(ccx_path("data", "obs_co2_monthly.rds")))
d13 <- as.data.frame(readRDS(ccx_path("data", "obs_d13c_monthly.rds")))

gt_levels <- function(d, st, vcol) {
  o <- d[d$station == st, ]
  h <- ccx_year_harmonic(o$decimal_date, o[[vcol]])
  h[, c("year", "level", "n")]
}
gt_grad <- function(d, a, b, vcol) {
  A <- gt_levels(d, a, vcol); B <- gt_levels(d, b, vcol)
  m <- merge(A, B, by = "year", suffixes = c("_a", "_b"))
  data.frame(year = m$year, grad = m$level_a - m$level_b,
             n = pmin(m$n_a, m$n_b))
}
g_co2  <- gt_grad(co2, "MLO", "SPO", "co2_ppm")
g_d13c <- gt_grad(d13, "MLO", "SPO", "d13c")

cat(sprintf("CO2  gradient: %d paired years, %d-%d\n",
            nrow(g_co2), min(g_co2$year), max(g_co2$year)))
cat(sprintf("d13C gradient: %d paired years, %d-%d\n\n",
            nrow(g_d13c), min(g_d13c$year), max(g_d13c$year)))

dec <- floor(g_co2$year / 10) * 10
tb  <- tapply(g_co2$grad, dec, mean); nn <- tapply(g_co2$grad, dec, length)
cat(sprintf("%8s %10s %8s %10s %10s\n", "decade", "annual-est", "n yr", "gate 9", "diff"))
for (i in seq_along(tb)) {
  gk <- GT_GATE9[names(tb)[i]]
  cat(sprintf("%8s %10.2f %8d %10s %10s\n", paste0(names(tb)[i], "s"), tb[i], nn[i],
              if (is.na(gk)) "--" else sprintf("%.2f", gk),
              if (is.na(gk)) "--" else sprintf("%+.2f", tb[i] - gk)))
}
miss <- setdiff(names(GT_GATE9), names(tb))
cat(sprintf("\ngate-9 decades the ANNUAL estimator drops entirely: %s\n",
            if (length(miss)) paste0(miss, "s", collapse = ", ") else "none"))
cat("That is the right behaviour, not a loss: gate 9's own note says the 1950s\n")
cat("entry rests on 8 paired MONTHS. ccx_year_harmonic()'s 9-month minimum\n")
cat("refuses to call that a year, so the term never sees it.\n")

# ---------------------------------------------------------------------
sep("PART 2. THE OBSERVATIONAL ERROR ON THE GRADIENT -- MEASURED, NOT ASSUMED")
# Two independent programs measure these sites. Their disagreement about the
# GRADIENT is a floor on any sigma the term can be given: no model can be asked
# to reproduce a quantity more precisely than the observations define it.
#
# READ THE MLO ROW BEFORE USING THE NUMBER. Handoff 15 sec.4.1 flagged that
# `MLO` and `MLO_NOAA` in this dataset agree far too well to be two independent
# measurements. That is re-measured here, and if it holds then the network
# comparison below is really a comparison of the two SPO records with a shared
# MLO -- still a real independent measurement, but of half the gradient, and it
# must be reported as such rather than as a two-station cross-check.
# ---------------------------------------------------------------------
gt_colocated <- function(a, b) {
  x <- co2[co2$station == a, c("decimal_date", "co2_ppm")]
  y <- co2[co2$station == b, c("decimal_date", "co2_ppm")]
  m <- merge(x, y, by = "decimal_date")
  if (!nrow(m)) return(cat(sprintf("%-14s vs %-14s  NO OVERLAPPING MONTHS\n", a, b)))
  d <- m$co2_ppm.x - m$co2_ppm.y
  cat(sprintf("%-14s vs %-14s  n=%4d  mean %+7.3f  RMS %6.3f ppm%s\n", a, b, nrow(m),
              mean(d), sqrt(mean(d^2)),
              if (sqrt(mean(d^2)) < 0.01) "   <- NOT two measurements" else ""))
}
cat("co-located records, monthly:\n")
for (pr in list(c("MLO", "MLO_NOAA"), c("MLO", "MLO_SIO_FLASK"),
                c("MLO_NOAA", "MLO_SIO_FLASK"), c("SPO", "SPO_NOAA")))
  gt_colocated(pr[1], pr[2])

gN <- gt_grad(co2, "MLO_NOAA", "SPO_NOAA", "co2_ppm")
mm <- merge(g_co2, gN, by = "year", suffixes = c("_sio", "_noaa"))
dg <- mm$grad_sio - mm$grad_noaa
cat(sprintf("\nGRADIENT, network vs network: n=%d years, mean %+0.4f, sd %0.4f, RMS %0.4f ppm\n",
            nrow(mm), mean(dg), sd(dg), sqrt(mean(dg^2))))
cat("The MEAN is a systematic scale/selection offset between the programmes and\n")
cat("the SD is their year-to-year disagreement. A gradient sigma below the RMS\n")
cat("would be asserting the observations resolve something they do not.\n")

# ---------------------------------------------------------------------
sep("PART 3. IS THE MODEL'S MISS AN OFFSET OR A SCALING?")
# THE HYPOTHESIS THIS PART EXISTS TO SEPARATE. The model's co2_NH is a
# well-mixed NORTHERN HEMISPHERE, and MLO is one subtropical mountain station
# that sits BELOW the northern hemispheric mean because the mid-latitude source
# region is north of it. So
#     (MLO - SPO)_obs = (NH_box - SH_box)_model + b + eps
# with b a representation offset that is NOT zero and is not known in this repo
# -- nothing here resolves CO2 by latitude (obs_co2_monthly.rds carries two
# sites; only D14C is zonal). Scoring the level at a tight sigma when b is
# unmeasured would force the model to absorb b into tau_ex and the shares.
#
# The two hypotheses make DIFFERENT predictions and this regression separates
# them:
#     obs_grad ~ a + b * model_grad
#   b ~ 1, a != 0  ->  a CONSTANT OFFSET: representation. Score the SLOPE/growth
#                      of the gradient, or carry b explicitly, or widen sigma.
#   a ~ 0, b != 1  ->  a PROPORTIONAL error: the source split or the exchange
#                      time. That is what the term is for and it can be scored
#                      on the level.
# ---------------------------------------------------------------------
p_def <- ccx_default_params()
gt_run <- function(p) {
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", GT_YEARS, prod_c14 = sp$prod_c14)
  o  <- ccx_run_fast(sp, F)$out
  list(out = o, sp = sp, F = F, ms = ccx_model_stats(o, ccx_prepare_obs()))
}
gt_model_grad <- function(ms, which = c("co2", "d13")) {
  which <- match.arg(which)
  A <- ms[[which]]$MLO; B <- ms[[which]]$SPO
  m <- merge(data.frame(year = A$year, a = A$level),
             data.frame(year = B$year, b = B$level), by = "year")
  data.frame(year = m$year, grad = m$a - m$b)
}
obs <- ccx_prepare_obs()
r_def <- gt_run(p_def)

mode_ok <- file.exists(GT_MODE)
if (mode_ok) {
  md <- readRDS(GT_MODE)
  mode_ok <- identical(md$param_names, CCX_PARAM_NAMES)
  if (!mode_ok)
    cat("NOTE: mode_fit.rds is from a different parameter set and is SKIPPED,\n",
        "     not silently coerced. Re-run calibration/run_modefind.R.\n", sep = "")
}
if (mode_ok) {
  p_mode <- ccx_default_params()
  for (n in intersect(names(p_mode), CCX_PARAM_NAMES)) p_mode[[n]] <- md$par_mode[[n]]
  p_mode <- ccx_set_enso(p_mode, md$par_mode)
  r_mode <- gt_run(p_mode)
}

gt_offset_vs_scaling <- function(mg, og, lab, unit) {
  m <- merge(mg, og, by = "year", suffixes = c("_mod", "_obs"))
  fit_full <- stats::lm(grad_obs ~ grad_mod, data = m)
  fit_prop <- stats::lm(grad_obs ~ 0 + grad_mod, data = m)   # a forced to 0
  ci <- stats::confint(fit_full)
  cat(sprintf("\n%s (%s), %d paired years %d-%d\n", lab, unit, nrow(m),
              min(m$year), max(m$year)))
  cat(sprintf("  mean model %+.3f   mean obs %+.3f   mean miss %+.3f\n",
              mean(m$grad_mod), mean(m$grad_obs),
              mean(m$grad_mod) - mean(m$grad_obs)))
  cat(sprintf("  obs ~ a + b*model :  a = %+.3f [%+.3f, %+.3f]   b = %+.3f [%+.3f, %+.3f]   R2 %.3f\n",
              coef(fit_full)[1], ci[1, 1], ci[1, 2],
              coef(fit_full)[2], ci[2, 1], ci[2, 2], summary(fit_full)$r.squared))
  cat(sprintf("  obs ~ b*model     :  b = %+.3f,  residual RMS %.3f\n",
              coef(fit_prop)[1], sqrt(mean(residuals(fit_prop)^2))))
  a_zero <- ci[1, 1] <= 0 && ci[1, 2] >= 0
  b_one  <- ci[2, 1] <= 1 && ci[2, 2] >= 1
  cat(sprintf("  VERDICT: a=0 %s at 95%%, b=1 %s at 95%%  ->  %s\n",
              if (a_zero) "ADMISSIBLE" else "REJECTED",
              if (b_one)  "ADMISSIBLE" else "REJECTED",
              if (!a_zero && b_one) "CONSTANT OFFSET (representation-like)"
              else if (a_zero && !b_one) "PROPORTIONAL (split/transport-like)"
              else if (!a_zero && !b_one) "BOTH -- offset AND scaling"
              else "neither distinguishable"))
  invisible(m)
}
cat("at DEFAULT parameters:")
gt_offset_vs_scaling(gt_model_grad(r_def$ms, "co2"),  g_co2,  "CO2 gradient",  "ppm")
gt_offset_vs_scaling(gt_model_grad(r_def$ms, "d13"),  g_d13c, "d13C gradient", "permil")
if (mode_ok) {
  # THE MODE IS PRE-5b AND THIS IS A CONFOUND, NOT A RESULT. mode_fit.rds was
  # produced on 2026-08-15 under the CONSTANT land-use share; running its
  # parameters through the time-varying forcing gives a hybrid that is neither
  # the fitted model nor a refitted one. Both are reported so the reader can see
  # which part of the mode's gradient behavior is its parameters and which is
  # the input change it was never fitted against.
  cat("\nat the MAP MODE, on the 5b (time-varying-share) forcing")
  cat("  -- NOTE: the mode was FITTED under the constant share; see below\n")
  gt_offset_vs_scaling(gt_model_grad(r_mode$ms, "co2"), g_co2,  "CO2 gradient",  "ppm")
  gt_offset_vs_scaling(gt_model_grad(r_mode$ms, "d13"), g_d13c, "d13C gradient", "permil")

  old_w <- FORC_USE_LUC_NH_SHARE_TS
  assign("FORC_USE_LUC_NH_SHARE_TS", FALSE, envir = globalenv())
  r_mode0 <- gt_run(p_mode)
  assign("FORC_USE_LUC_NH_SHARE_TS", old_w, envir = globalenv())
  cat("\nat the MAP MODE, on the forcing it was ACTUALLY FITTED TO (constant share):")
  gt_offset_vs_scaling(gt_model_grad(r_mode0$ms, "co2"), g_co2,  "CO2 gradient",  "ppm")
  gt_offset_vs_scaling(gt_model_grad(r_mode0$ms, "d13"), g_d13c, "d13C gradient", "permil")
}

# ---------------------------------------------------------------------
sep("PART 4. WHAT THE OBJECTIVE ALREADY IMPLIES FOR THE GRADIENT")
# The two station levels are scored INDEPENDENTLY at sd = sqrt(sigma_co2^2 +
# LIK_CO2_REP_ERR^2) each, so the difference already carries an implied sigma of
# sqrt(2) times that. Any ADDED gradient term double-counts exactly that
# information. The size of the double count is the whole argument for adding a
# term (weak implied sigma -> the new term dominates and the double count is
# second-order) versus rotating the pair to (mean, difference) (comparable
# sigmas -> the double count is first-order and a rotation is the honest move).
# ---------------------------------------------------------------------
cat(sprintf("%-28s %10s %12s %14s\n", "sigma_co2 basis", "station sd", "implied grad sd",
            "model miss / sd"))
miss_def <- mean(gt_model_grad(r_def$ms, "co2")$grad[
  gt_model_grad(r_def$ms, "co2")$year >= GT_WIN[1]]) -
  mean(g_co2$grad[g_co2$year >= GT_WIN[1]])
for (bs in list(c("prior-ish 1.5", 1.5),
                c("MAP mode 0.223", if (mode_ok) md$par_mode$sigma_co2 else 0.223))) {
  s  <- sqrt(as.numeric(bs[2])^2 + LIK_CO2_REP_ERR^2)
  cat(sprintf("%-28s %10.3f %12.3f %14.2f\n", bs[1], s, sqrt(2) * s,
              abs(miss_def) / (sqrt(2) * s)))
}
cat(sprintf("\nmodel-minus-obs gradient over %d-%d at defaults: %+0.3f ppm\n",
            GT_WIN[1], GT_WIN[2], miss_def))
cat("A miss smaller than its own implied error bar is why nothing has ever\n")
cat("objected to it -- review sec.2.3's point, now with the post-5b number.\n")

# ---------------------------------------------------------------------
sep("PART 5. LEVERAGE PER PRIOR SD -- IS THE TERM WORTH ADDING AT ALL?")
# The unit is log-units per one prior sd of the parameter, the same unit
# diag_stream_leverage.R uses, so these numbers sit directly beside the 40:1
# imbalance (CO2 streams 1,565; ice core 118; gcb_ocean_sink 36; gcb_land_sink
# 7.3). Reported for a range of candidate sigmas because THE SIGMA IS THE
# DECISION and its effect is quadratic.
#
# The shares are NOT parameters and have no prior sd, so they are stepped by
# their own documented uncertainty instead: fossil 0.95 -> the EDGAR-measured
# 0.9201, and land-use across its lo/hi bracket.
# ---------------------------------------------------------------------
gt_grad_recent <- function(ms, which = "co2") {
  g <- gt_model_grad(ms, which)
  mean(g$grad[g$year >= GT_WIN[1] & g$year <= GT_WIN[2]])
}
obs_recent <- mean(g_co2$grad[g_co2$year >= GT_WIN[1] & g_co2$year <= GT_WIN[2]])

# The candidate term, as it would be written: annual paired residuals, one sigma.
gt_term <- function(ms, sigma) {
  m <- merge(gt_model_grad(ms, "co2"), g_co2, by = "year",
             suffixes = c("_mod", "_obs"))
  sum(stats::dnorm(m$grad_obs, m$grad_mod, sigma, log = TRUE))
}

gt_variant <- function(lab, p = p_def, foss = NULL, luc_which = NULL) {
  old_f <- FORC_FOSS_NH_SHARE; old_w <- FORC_USE_LUC_NH_SHARE_TS
  on.exit({ assign("FORC_FOSS_NH_SHARE", old_f, envir = globalenv())
            assign("FORC_USE_LUC_NH_SHARE_TS", old_w, envir = globalenv()) })
  if (!is.null(foss)) assign("FORC_FOSS_NH_SHARE", foss, envir = globalenv())
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", GT_YEARS, prod_c14 = sp$prod_c14)
  if (!is.null(luc_which)) {
    yrs <- sort(unique(F$year))
    sh  <- rep(ccx_luc_nh_share(yrs, luc_which), each = 12)
    tot <- F$e_luc_NH + F$e_luc_SH
    F$e_luc_NH <- tot * sh; F$e_luc_SH <- tot * (1 - sh)
    ct <- F$cum_luc_NH + F$cum_luc_SH
    F$cum_luc_NH <- ct * sh; F$cum_luc_SH <- ct * (1 - sh)
  }
  o  <- ccx_run_fast(sp, F)$out
  ms <- ccx_model_stats(o, obs)
  list(lab = lab, ms = ms, grad = gt_grad_recent(ms),
       parts = ccx_loglik(o, obs, GT_SIGMA, luc = ccx_forcing_eluc_annual(F),
                          by_stream = TRUE))
}
base <- gt_variant("baseline (defaults, 5b on)")
p_lo <- p_def; p_lo$tau_ex <- p_def$tau_ex * exp(-GT_TAU_EX_PRIOR_SD)
p_hi <- p_def; p_hi$tau_ex <- p_def$tau_ex * exp(+GT_TAU_EX_PRIOR_SD)
vars <- list(
  gt_variant(sprintf("tau_ex -1 prior sd (%.3f)", p_lo$tau_ex), p = p_lo),
  gt_variant(sprintf("tau_ex +1 prior sd (%.3f)", p_hi$tau_ex), p = p_hi),
  gt_variant("fossil NH share 0.9201 (EDGAR)", foss = 0.9201),
  gt_variant("LUC NH share -> lo bracket",  luc_which = "share_lo"),
  gt_variant("LUC NH share -> hi bracket",  luc_which = "share_hi")
)
cat(sprintf("observed %d-%d gradient %.3f ppm; baseline model %.3f (miss %+.3f)\n\n",
            GT_WIN[1], GT_WIN[2], obs_recent, base$grad, base$grad - obs_recent))
cat(sprintf("%-34s %9s %10s %s\n", "", "grad ppm", "d existing",
            paste(sprintf("%9s", sprintf("s=%.2f", GT_SIGMA_TRIAL)), collapse = "")))
for (v in vars) {
  dterm <- vapply(GT_SIGMA_TRIAL,
                  function(s) gt_term(v$ms, s) - gt_term(base$ms, s), numeric(1))
  cat(sprintf("%-34s %9.3f %10.1f %s\n", v$lab, v$grad,
              sum(v$parts) - sum(base$parts),
              paste(sprintf("%+9.1f", dterm), collapse = "")))
}
cat("\n'd existing' is what the CURRENT objective sees. The sigma columns are what\n")
cat("the gradient term WOULD add. Where the two have opposite signs, the term is\n")
cat("supplying information the objective does not have -- which is the case for\n")
cat("adding it. Where they agree, it is re-weighting information already there.\n")
