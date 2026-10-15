# =====================================================================
# diag_enso_sink_power.R -- BEFORE ASKING WHETHER THE MODEL'S ENSO RESPONSE IS
# RIGHT: DOES THE OBSERVABLE CARRY AN ENSO SIGNAL AT ALL, AND WITH WHAT POWER?
#
# WHY THIS RUNS FIRST. On 2026-09-01 I reported the model's 2023/24 ocean-sink
# response as a sign error, and Marcus retracted it: every ENSO differs in its
# land/ocean impact, and a one-parameter ENSO response can only ever capture the
# AVERAGE, modulated by intensity. The composite over all events is the right
# test -- but it is only worth running if the series being composited can show
# the effect. **A test whose null is structurally guaranteed reports "no effect"
# identically to one that looked and found nothing** ([[no_power_null]]).
#
# ⛔ THIS FILE SCORES NO MODEL. It measures the OBSERVATIONS only, so its verdict
# cannot be about CCX. If the GCB ocean sink carries no detectable ENSO signal,
# then neither our model nor Ke et al.'s +0.38 GtC/yr is testable against it and
# the question is CLOSED FOR WANT OF AN OBSERVABLE -- not answered.
#
# THE DESIGN, and every choice in it is named:
#   * POSITIVE CONTROL. The land sink's ENSO response is long established, so it
#     is regressed FIRST with the identical machinery. A method that cannot find
#     the land signal has not earned a null on the ocean one.
#   * EFFECTIVE SAMPLE SIZE, not n. Both series are autocorrelated (the
#     detrended ocean sink has lag-1 ~0.6), so the naive CI on r is far too
#     tight. Bartlett/Quenouille: n_eff = n (1 - r1 r2) / (1 + r1 r2).
#   * A LAG PROFILE, not a chosen lag. Land and ocean carbon trail ENSO by a
#     quarter to two; the profile is reported and its argmax is an OUTPUT.
#   * DETRENDING SENSITIVITY. The secular trend must come out, and the order is
#     a free choice, so degrees 1-3 are all reported rather than one picked.
#   * MINIMUM DETECTABLE EFFECT. The number that makes this a POWER test and not
#     another null: the smallest slope this series could resolve, against the
#     effect size Ke et al. imply.
#
# Usage:  Rscript calibration/diag_enso_sink_power.R    # ~5 s, no model run
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
# ⭐ THE ESTIMATOR IS SHARED with diag_enso_model_vs_obs.R -- one detrending
# convention, one lag convention, one effective sample size. See the header there.
source(ccx_path("calibration", "lib_enso_regression.R"))

# ---- named constants ------------------------------------------------
PW_INDEX   <- ER_INDEX
PW_ALT     <- ER_ALT
PW_LAGS    <- ER_LAGS
PW_DEGS    <- ER_DEGS
PW_DEG     <- ER_DEG
PW_YRS     <- c(1959, 2024)      # the GCB record
PW_ALPHA   <- ER_ALPHA
PW_POWER   <- ER_POWER
# Ke et al. 2026 (iScience 29(8):117053): +0.38 GtC/yr stronger ocean uptake in
# an event of MEI 0.71. ⚠ ORIENTATION ONLY -- their window is Jul-Jul and their
# decomposition is not this series. Used to ASK whether an effect of that ORDER
# would be visible here, which is a question about this series, not about them.
PW_KE_OCEAN <- 0.38; PW_KE_MEI <- 0.71

cat(sprintf("\n%s\nCAN THE GCB SINKS SHOW AN ENSO SIGNAL AT ALL?  (observations only; no model)\n%s\n",
            strrep("=", 78), strrep("=", 78)))

g <- as.data.frame(ccx_prepare_obs()$gcb)
g <- g[g$year >= PW_YRS[1] & g$year <= PW_YRS[2], ]
e <- as.data.frame(readRDS(ccx_path("data", "forcing_enso.rds")))

# ---- the index, aggregated to the sink's own annual resolution at each lag ----
# A lag of L months means the annual mean of the index over the 12 months ENDING
# L months before each year's end -- i.e. the sink is allowed to trail the index.
pw_index_annual <- function(col, lag_m) er_index_annual(g$year, col, lag_m)
pw_detrend <- function(x, deg) er_detrend(x, g$year, deg)
ac1 <- er_ac1

pw_cor <- er_cor    # the shared estimator; see lib_enso_regression.R

# ---- 1. THE POSITIVE CONTROL -----------------------------------------
cat(sprintf("\n%s\n1. POSITIVE CONTROL -- the LAND sink, whose ENSO response is long established.\n   If this machinery cannot find it, no null it reports on the ocean is worth having.\n%s\n",
            strrep("-", 78), strrep("-", 78)))
best <- list()
for (nm in c(land = "land_sink", ocean = "ocean_sink")) {
  lab <- names(which(c(land = "land_sink", ocean = "ocean_sink") == nm))[1]
  y <- pw_detrend(g[[nm]], PW_DEG)
  cat(sprintf("\n  %s sink (detrended deg %d; residual sd %.3f, lag-1 autocorr %.2f)\n",
              toupper(lab), PW_DEG, sd(y), ac1(y)))
  cat(sprintf("  %5s %8s %8s %19s %9s %10s\n", "lag", "r", "n_eff", "95% CI", "p", "slope"))
  bb <- NULL
  for (L in PW_LAGS) {
    cc <- pw_cor(pw_index_annual(PW_INDEX, L), y)
    if (is.null(bb) || abs(cc$r) > abs(bb$r)) { bb <- cc; bb$lag <- L }
    if (L %% 3 == 0)
      cat(sprintf("  %5d %8.3f %8.1f   [%+.3f, %+.3f] %9.4f %10.3f\n",
                  L, cc$r, cc$n_eff, cc$ci[1], cc$ci[2], cc$p, cc$slope))
  }
  cat(sprintf("  BEST |r| at lag %d months: r = %+.3f, 95%% CI [%+.3f, %+.3f], p = %.4f\n",
              bb$lag, bb$r, bb$ci[1], bb$ci[2], bb$p))
  cat(sprintf("  => %s\n", if (bb$ci[1] * bb$ci[2] > 0)
              "DETECTED: the CI excludes zero." else "NOT DETECTED: the CI includes zero."))
  # ⚠ THE BEST LAG WAS SELECTED BY SCANNING 13 OF THEM, so the CI *at that lag*
  # is optimistic -- a garden of forking paths, stated rather than hidden. It
  # does not carry the verdict here: the count below says how many of the 13
  # lags are individually significant, and a signal that survives at nearly all
  # of them is not an artifact of which one was picked.
  nsig <- sum(vapply(PW_LAGS, function(L) {
    cc <- pw_cor(pw_index_annual(PW_INDEX, L), y); cc$ci[1] * cc$ci[2] > 0 }, logical(1)))
  cat(sprintf("     robustness to that choice: %d of %d lags individually significant\n",
              nsig, length(PW_LAGS)))
  best[[lab]] <- bb
}

# ---- 2. DETRENDING SENSITIVITY ---------------------------------------
cat(sprintf("\n%s\n2. IS THAT AN ARTEFACT OF THE DETRENDING ORDER? (at each series' own best lag)\n%s\n",
            strrep("-", 78), strrep("-", 78)))
cat(sprintf("  %-8s %10s %10s %10s\n", "series", "deg 1", "deg 2", "deg 3"))
for (lab in names(best)) {
  nm <- c(land = "land_sink", ocean = "ocean_sink")[[lab]]
  rs <- vapply(PW_DEGS, function(d)
    pw_cor(pw_index_annual(PW_INDEX, best[[lab]]$lag), pw_detrend(g[[nm]], d))$r, numeric(1))
  cat(sprintf("  %-8s %10.3f %10.3f %10.3f\n", lab, rs[1], rs[2], rs[3]))
}
cat(sprintf("\n  and with the ALTERNATIVE index (%s, NA before 1979):\n", PW_ALT))
for (lab in names(best)) {
  nm <- c(land = "land_sink", ocean = "ocean_sink")[[lab]]
  cc <- pw_cor(pw_index_annual(PW_ALT, best[[lab]]$lag), pw_detrend(g[[nm]], PW_DEG))
  cat(sprintf("  %-8s r = %+.3f, n = %d, n_eff = %.1f, 95%% CI [%+.3f, %+.3f]\n",
              lab, cc$r, cc$n, cc$n_eff, cc$ci[1], cc$ci[2]))
}

# ---- 3. THE POWER CALCULATION ----------------------------------------
# ⭐ THIS IS THE POINT OF THE FILE. Not "is there a signal" but "how big would a
# signal have to be for THIS series to show it" -- the question that separates a
# null with power from a null without.
cat(sprintf("\n%s\n3. MINIMUM DETECTABLE EFFECT (alpha %.2f, power %.0f%%)\n%s\n",
            strrep("-", 78), PW_ALPHA, 100 * PW_POWER, strrep("-", 78)))
zc <- qnorm(1 - PW_ALPHA / 2) + qnorm(PW_POWER)
for (lab in names(best)) {
  nm <- c(land = "land_sink", ocean = "ocean_sink")[[lab]]
  y  <- pw_detrend(g[[nm]], PW_DEG)
  x  <- pw_index_annual(PW_INDEX, best[[lab]]$lag)
  k  <- is.finite(x) & is.finite(y)
  n_eff <- best[[lab]]$n_eff
  r_min <- tanh(zc / sqrt(n_eff - 3))                      # smallest resolvable |r|
  # slope = r * sd(y)/sd(x), so the smallest resolvable slope follows
  s_min <- r_min * sd(y[k]) / sd(x[k])
  cat(sprintf("  %-8s n_eff %5.1f => smallest resolvable |r| = %.3f, i.e. |slope| = %.3f GtC/yr per index unit\n",
              lab, n_eff, r_min, s_min))
  cat(sprintf("  %-8s observed slope %+.3f  =>  %s\n", "", best[[lab]]$slope,
              if (abs(best[[lab]]$slope) >= s_min) "ABOVE the detection floor"
              else "BELOW the detection floor -- this series cannot resolve it"))
}
cat(sprintf("\n  FOR ORIENTATION: Ke et al. 2026 report %.2f GtC/yr of extra ocean uptake in an\n  event of MEI %.2f, i.e. of order %.2f GtC/yr per index unit.\n",
            PW_KE_OCEAN, PW_KE_MEI, PW_KE_OCEAN / PW_KE_MEI))
local({
  y <- pw_detrend(g$ocean_sink, PW_DEG); x <- pw_index_annual(PW_INDEX, best$ocean$lag)
  k <- is.finite(x) & is.finite(y)
  r_min <- tanh(zc / sqrt(best$ocean$n_eff - 3))
  s_min <- r_min * sd(y[k]) / sd(x[k])
  cat(sprintf("  An effect of THAT order would be %.1fx this series' detection floor (%.3f),\n  so if it were a persistent ENSO response it would be UNMISSABLE here.\n",
              (PW_KE_OCEAN / PW_KE_MEI) / s_min, s_min))
  cat("  ⚠ It is not missing because the series is blind; the two are not the same\n    quantity (Jul-Jul window, different decomposition, event-relative baseline).\n")
})
cat(sprintf("\n%s\n", strrep("=", 78)))
