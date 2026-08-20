# =====================================================================
# diag_seasonal_phase_obs_vs_model.R -- IS THE MODELLED SEASONAL CYCLE
# OUT OF PHASE WITH THE OBSERVED ONE THE LIKELIHOOD SCORES?
#
# THE QUESTION, from handoff 2026-08-20 section 3a. Every seasonal DRIVER peaks
# 1-2 months later than climatology says it should (NH SST Oct, land T Sep,
# NPP Aug), and moving `sst_seas_amp_NH` from its fitted 0.089 K to the physical
# 2.0 K costs `co2_seasonal_MLO` -673 log-units while the peak-to-peak AMPLITUDE
# improves. Amplitude better, likelihood far worse => the cost is PHASE.
#
# But "the drivers are late" is not the same claim as "the OBSERVABLE is late".
# The rows score `ccx_year_harmonic()`'s sin/cos coefficients on CO2 and d13C at
# MLO and SPO, and a driver phase error can be cancelled downstream (by the
# respiration counter-cycle, by air-sea exchange, by the fitted `seas_lag_p`).
# This script measures the thing the likelihood actually sees.
#
# THE ESTIMATOR IS THE LIKELIHOOD'S OWN. `ccx_seasonal_target()` on both sides,
# the same window (LIK_SEAS_WINDOW), so nothing here depends on a definition of
# "phase" the fit does not use. a*sin(2*pi*phi) + b*cos(2*pi*phi) peaks at
# phi = atan2(a, b)/(2*pi); that is the whole conversion.
#
# THREE TESTS.
#   1. PHASE AT THE MODE, per scored stream, model minus observed, in MONTHS.
#      This is the test named at the end of section 3a and it is decisive: if the
#      model's MLO CO2 phase already matches obs, the late drivers are being
#      compensated downstream and `sst_seas_amp` is not the messenger of a
#      geometry bug. If it is late too, the geometry is the bug.
#   2. WHAT THE OCEAN TERM DOES TO PHASE. The same table at the fitted
#      amplitude, at the physical 2.0 K, and with the term off. If raising it
#      rotates MLO CO2 AWAY from the observed phase, the -673 is explained and
#      the ocean term is being zeroed because it arrives at the wrong time of
#      year, not because it is redundant.
#   3. THE CONVENTION, checked analytically against its own comment. The
#      `(3.5 + LAG)/12` offset and what peak month it implies at LAG = 0 and at
#      the shipped LAG, versus what the constants' comments claim.
#
# WHAT THIS SCRIPT CANNOT DO. It cannot certify the OBSERVED climatological
# peak months of SST and land air T -- the repo carries HadSST4 ANNUAL
# hemispheric anomalies only (data-raw/build_sst_forcing.R), no monthly
# climatology. Test 1 sidesteps that entirely by comparing against the observed
# CO2 and d13C cycles, which the repo does have at monthly resolution.
#
# Usage:  Rscript calibration/diag_seasonal_phase_obs_vs_model.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

PHASE_MODE_FILE <- ccx_path("calibration", "output", "pump_arms", "mode_fit_pumpN.rds")
PHASE_WINDOW    <- LIK_SEAS_WINDOW          # the window the likelihood scores
PHASE_YEARS     <- c(1750, 2024)
PHASE_MONTHS    <- c("Jan","Feb","Mar","Apr","May","Jun",
                     "Jul","Aug","Sep","Oct","Nov","Dec")
# `sst_seas_amp_{NH,SH}` cases: the refit's answer, the prior centre (physical),
# and off. Named here so every label below derives from this one list.
PHASE_SST_CASES <- list(
  `fitted (refit's answer)` = NULL,          # NULL = leave the mode's own value
  `physical 2.0 / 1.2 K`    = c(2.0, 1.2),
  `ocean term OFF (1e-6)`   = c(1e-6, 1e-6))
PHASE_STREAMS <- c(co2_seasonal_MLO = "co2_seas.MLO", co2_seasonal_SPO = "co2_seas.SPO",
                   d13c_seasonal_MLO = "d13_seas.MLO", d13c_seasonal_SPO = "d13_seas.SPO")

sep <- function(s) cat(sprintf("\n\n=== %s ===\n", s))

# ---- phase helpers ---------------------------------------------------
# a*sin(2 pi phi) + b*cos(2 pi phi) is maximal at phi = atan2(a, b)/(2 pi).
# phi is the fraction of the calendar year, phi = 0 at Jan 1 (ccx_year_harmonic
# builds phi as t - floor(t)), so month-of-year = 12*phi.
peak_frac  <- function(a, b) (atan2(a, b) / (2 * pi)) %% 1
frac_label <- function(phi) {
  m <- 12 * phi
  sprintf("%s %+04.1f d (month %.2f)", PHASE_MONTHS[pmin(12L, floor(m) + 1L)],
          (m - floor(m)) * 30.44 - 15.2, m)
}
# Signed difference on the circle, in months, in (-6, +6].
dmonths <- function(phi1, phi2) ((phi1 - phi2 + 0.5) %% 1 - 0.5) * 12

# Gaussian cost (negative log-likelihood, dropping the constant) of one stream.
ccx__seas_cost <- function(am, bm, ao, bo, sd_a, sd_b)
  sum((am - ao)^2) / (2 * sd_a^2) + sum((bm - bo)^2) / (2 * sd_b^2)

pick <- function(ms, key) { k <- strsplit(key, ".", fixed = TRUE)[[1]]; ms[[k[1]]][[k[2]]] }

# Vector-mean phase over the window: average a and b, THEN take the angle.
# Averaging per-year peak months would wrap wrongly across the Dec/Jan seam.
summarise_stream <- function(o, m) {
  if (is.null(o) || is.null(m)) return(NULL)
  k <- match(o$year, m$year); good <- !is.na(k)
  ao <- o$a[good]; bo <- o$b[good]; am <- m$a[k[good]]; bm <- m$b[k[good]]
  po <- peak_frac(mean(ao), mean(bo)); pm <- peak_frac(mean(am), mean(bm))
  dy <- dmonths(peak_frac(am, bm), peak_frac(ao, bo))   # per-year, then averaged
  list(n = sum(good),
       amp_obs = 2 * mean(sqrt(ao^2 + bo^2)), amp_mod = 2 * mean(sqrt(am^2 + bm^2)),
       phi_obs = po, phi_mod = pm,
       d_vec = dmonths(pm, po), d_yr = mean(dy), d_yr_sd = stats::sd(dy),
       # z-scores on the two scored coefficients, so the phase error is priced
       # in the likelihood's own units rather than only in months
       sd_a = o$sd_a, sd_b = o$sd_b,
       z_a = mean((am - ao) / o$sd_a), z_b = mean((bm - bo) / o$sd_b),
       # Decompose the scored cost into an AMPLITUDE part and a PHASE part.
       # The row's cost is sum over years of (da^2/sd_a^2 + db^2/sd_b^2)/2.
       # Amplitude-only: give the model the OBSERVED phase, keep its own radius.
       # Phase-only: give the model the OBSERVED radius, keep its own phase.
       cost = ccx__seas_cost(am, bm, ao, bo, o$sd_a, o$sd_b),
       cost_amp = local({ r <- sqrt(am^2 + bm^2); th <- atan2(ao, bo)
                          ccx__seas_cost(r * sin(th), r * cos(th), ao, bo, o$sd_a, o$sd_b) }),
       cost_pha = local({ r <- sqrt(ao^2 + bo^2); th <- atan2(am, bm)
                          ccx__seas_cost(r * sin(th), r * cos(th), ao, bo, o$sd_a, o$sd_b) }))
}

# ---- the mode --------------------------------------------------------
md <- readRDS(PHASE_MODE_FILE)
p_mode <- ccx_default_params()
for (n in intersect(names(p_mode), names(md$par_mode))) p_mode[[n]] <- md$par_mode[[n]]
cat(sprintf("mode: %s (arm %s, logpost %.2f)\n", basename(PHASE_MODE_FILE),
            md$pump_mode, md$logpost))
cat(sprintf("seas_drivers %g | seas_lag_p %.4f mo | sst_seas_amp NH %.4f SH %.4f K\n",
            p_mode$seas_drivers, p_mode$seas_lag_p,
            p_mode$sst_seas_amp_NH, p_mode$sst_seas_amp_SH))
cat(sprintf("seas_T_amp NH %.4f SH %.4f K | q10 %.4f\n",
            p_mode$seas_T_amp_NH, p_mode$seas_T_amp_SH, p_mode$q10))
cat(sprintf("scoring window %d-%d (LIK_SEAS_WINDOW)\n", PHASE_WINDOW[1], PHASE_WINDOW[2]))

obs <- ccx_prepare_obs()
run_stats <- function(p) {
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", PHASE_YEARS, prod_c14 = 0, bomb_total_kmol = 102)
  F$c14_cosmo <- sp$prod_c14
  ccx_model_stats(ccx_run_fast(sp, F)$out, obs)
}

# ---- TEST 1 ----------------------------------------------------------
sep("TEST 1 -- PHASE AT THE MODE: MODEL MINUS OBSERVED, IN MONTHS")
cat("Positive = the model's cycle peaks LATER in the year than the observed one.\n")
cat("d_vec uses window-mean (a,b); d_yr averages the per-year phase difference.\n\n")
ms0 <- run_stats(p_mode)
rows <- lapply(names(PHASE_STREAMS), function(s)
  summarise_stream(obs[[strsplit(PHASE_STREAMS[[s]], ".", fixed = TRUE)[[1]][1]]][[
                     strsplit(PHASE_STREAMS[[s]], ".", fixed = TRUE)[[1]][2]]],
                   pick(ms0, PHASE_STREAMS[[s]])))
names(rows) <- names(PHASE_STREAMS)
for (s in names(rows)) {
  r <- rows[[s]]; if (is.null(r)) { cat(sprintf("%-18s ABSENT\n", s)); next }
  cat(sprintf("%-18s obs peak %-26s model peak %-26s\n", s,
              frac_label(r$phi_obs), frac_label(r$phi_mod)))
  cat(sprintf("%-18s d_vec %+5.2f mo | d_yr %+5.2f +- %.2f mo | amp obs %.4f model %.4f | z_a %+6.2f z_b %+6.2f (n=%d)\n\n",
              "", r$d_vec, r$d_yr, r$d_yr_sd, r$amp_obs, r$amp_mod, r$z_a, r$z_b, r$n))
}
cat("COST DECOMPOSITION -- the row's own Gaussian cost, split into the part a\n")
cat("pure amplitude error would cost and the part a pure phase error would cost.\n")
cat("(They do not sum to the total: the two errors interact.)\n\n")
cat(sprintf("%-18s %10s %10s %10s   %s\n", "stream", "cost", "amp-only", "phase-only", "verdict"))
for (s in names(rows)) {
  r <- rows[[s]]; if (is.null(r)) next
  cat(sprintf("%-18s %10.1f %10.1f %10.1f   %s\n", s, r$cost, r$cost_amp, r$cost_pha,
              if (r$cost_amp > r$cost_pha) "AMPLITUDE dominates" else "PHASE dominates"))
}

# ---- TEST 2 ----------------------------------------------------------
sep("TEST 2 -- WHAT THE OCEAN SEASONAL TERM DOES TO PHASE")
cat("If raising sst_seas_amp rotates MLO CO2 AWAY from the observed phase while\n")
cat("its amplitude improves, the -673 log-units are a PHASE cost.\n\n")
tab <- lapply(names(PHASE_SST_CASES), function(k) {
  v <- PHASE_SST_CASES[[k]]
  p <- p_mode
  if (!is.null(v)) { p$sst_seas_amp_NH <- v[1]; p$sst_seas_amp_SH <- v[2] }
  ms <- run_stats(p)
  vapply(names(PHASE_STREAMS), function(s) {
    r <- summarise_stream(obs[[strsplit(PHASE_STREAMS[[s]], ".", fixed = TRUE)[[1]][1]]][[
                            strsplit(PHASE_STREAMS[[s]], ".", fixed = TRUE)[[1]][2]]],
                          pick(ms, PHASE_STREAMS[[s]]))
    if (is.null(r)) c(d_mo = NA, amp = NA) else c(d_mo = r$d_vec, amp = r$amp_mod)
  }, numeric(2))
})
names(tab) <- names(PHASE_SST_CASES)
cat("phase difference model - obs, MONTHS:\n")
print(round(t(vapply(tab, function(x) x["d_mo", ], numeric(length(PHASE_STREAMS)))), 3))
cat("\nmodelled peak-to-peak amplitude (obs targets in the row below):\n")
print(round(t(vapply(tab, function(x) x["amp", ], numeric(length(PHASE_STREAMS)))), 4))
cat("obs:", sprintf("%s %.4f  ", names(rows), vapply(rows, function(r)
  if (is.null(r)) NA_real_ else r$amp_obs, numeric(1))), "\n")

# ---- TEST 3 ----------------------------------------------------------
sep("TEST 3 -- THE (3.5 + LAG)/12 CONVENTION, AGAINST ITS OWN COMMENTS")
cat("sin(2*pi*(t - (3.5 + LAG)/12)) peaks at t = 0.25 + (3.5 + LAG)/12.\n\n")
for (lag in list(c("CCX_SEAS_T_LAG", CCX_SEAS_T_LAG, "seasonal land T peak after Jun"),
                 c("CCX_SST_SEAS_LAG", CCX_SST_SEAS_LAG, "NH SST peaks Aug-Sep"))) {
  L <- as.numeric(lag[2])
  for (l in c(0, L)) cat(sprintf("  %-17s = %4.1f -> NH peak %s%s\n", lag[1], l,
      frac_label((0.25 + (3.5 + l) / 12) %% 1),
      if (l == 0) "   (zero-lag baseline the 3.5 already bakes in)"
      else sprintf("   <- shipped; comment says \"%s\"", lag[3])))
  cat("\n")
}
cat("Insolation peak at the effective latitudes, measured on a 720-point grid:\n")
gr <- (seq_len(720) - 0.5) / 720
for (h in HEMIS) {
  iv <- vapply(gr, function(x) ccx_insol(CCX_SEAS_PHI_EFF[[h]], x), numeric(1))
  cat(sprintf("  [%s] phi_eff %+5.1f deg, unlagged insolation peaks %s\n",
              h, CCX_SEAS_PHI_EFF[[h]], frac_label(gr[which.max(iv)])))
}
cat(sprintf("\n  seas_lag_p at the mode = %.4f months (the FITTED phenology lag on insolation)\n",
            p_mode$seas_lag_p))
cat("\nDone.\n")

# ---- TEST 4 ----------------------------------------------------------
# THE CORRECTED REFERENCE. `diag_sst_seas_zeroing.R` compared a PEAK-TO-PEAK
# model amplitude (2*mean(sqrt(a^2+b^2))) against "obs 3.02 ppm / 0.55 ppm",
# which are the SEMI-amplitudes (mean(sqrt(a^2+b^2)) = 3.38 / 0.60). The
# peak-to-peak observed values are 6.76 / 1.20 ppm, and the raw NOAA monthly
# climatology (co2_ppm - co2_deseas, 1990-2014) independently gives a 6.61 ppm
# MLO peak-to-trough. So the model does not OVERSHOOT the MLO seasonal cycle --
# it UNDERSHOOTS it, and every statement in the 08-18/08-20 arc that rests on
# the overshoot has the sign backwards.
#
# THE TEST THAT FOLLOWS FROM THAT. If the model is amplitude-starved at MLO,
# `seas_T_amp_NH` = 48 K with `q10` = 1.26 is the fit buying respiration swing
# it cannot get physically, and the question is whether ANY physical pair
# reaches the observed amplitude. Ladder over (q10, seas_T_amp_NH), everything
# else frozen at the mode; the realised swing is what only the PRODUCT sets.
sep("TEST 4 -- CAN A PHYSICAL (q10, seas_T_amp_NH) REACH THE OBSERVED AMPLITUDE?")
PHASE_Q10_LADDER <- list(
  `mode (q10 1.26, A 48.07 K)`   = c(NA, NA),          # NA = keep the mode's own
  `q10 2.23, A 48.07 K`          = c(2.2275, 48.0717),
  `q10 2.23, A 15 K (physical)`  = c(2.2275, 15),
  `q10 2.23, A 10 K (physical)`  = c(2.2275, 10),
  `q10 1.26, A 15 K`             = c(1.2613, 15),
  `q10 2.23, A 100 K`            = c(2.2275, 100))
cat(sprintf("observed MLO peak-to-peak %.3f ppm (window %d-%d); SPO %.3f ppm\n\n",
            rows$co2_seasonal_MLO$amp_obs, PHASE_WINDOW[1], PHASE_WINDOW[2],
            rows$co2_seasonal_SPO$amp_obs))
cat(sprintf("%-30s %8s %8s %10s %10s\n", "case", "swing", "MLO p2p", "phase mo", "cost"))
for (k in names(PHASE_Q10_LADDER)) {
  v <- PHASE_Q10_LADDER[[k]]; p <- p_mode
  if (!is.na(v[1])) { p$q10 <- v[1]; p$seas_T_amp_NH <- v[2] }
  # realised peak-to-trough respiration factor, the only thing the product sets
  mo <- (seq_len(12) - 0.5) / 12
  rf <- p$q10^(p$seas_T_amp_NH * sin(2 * pi * (mo - (3.5 + CCX_SEAS_T_LAG) / 12)) / 10)
  r  <- summarise_stream(obs$co2_seas$MLO, run_stats(p)$co2_seas$MLO)
  cat(sprintf("%-30s %8.2f %8.3f %+10.2f %10.1f\n", k, max(rf) / min(rf),
              r$amp_mod, r$d_vec, r$cost))
}
cat("\nDone (test 4).\n")
