# =====================================================================
# diag_rep_dC_shape.R -- IS THE 5.2-SIGMA REPRESENTATION OFFSET A LEVEL,
#                        OR IS IT A TREND WEARING A LEVEL'S CLOTHES?
#
# `rep_dC` has prior N(0, LIK_CO2_REP_ERR = 1.0 ppm) and the arm-N mode puts it
# at +5.18 ppm. That is +5.2 sd, the largest |z| in the fit (handoff 21c sec.5),
# and it is in the OPPOSITE SIGN from the case R/calibrate.R built the parameter
# for -- that block says absorbing the d13C common-mode bias would need
# rep_dC = -4.19 ppm. Its own stated purpose is to "resist a structural error
# wearing its clothes", and the question is whether it just lost that argument.
#
# THE TEST IS THE SHAPE OF THE RESIDUAL, NOT ITS SIZE. A genuine station-vs-box
# representation constant is (a) CONSTANT IN TIME and (b) not necessarily the
# same in both hemispheres -- MLO and SPO sit at different latitudes inside
# boxes with different land fractions. Two failure signatures:
#
#   COMMON-MODE AND FLAT   -> not representation at all. Both boxes high by the
#                             same amount is an ATMOSPHERIC MASS error: the
#                             model holds ~2.13 GtC per ppm too much carbon, and
#                             `rep_dC` is laundering a budget miss.
#   GROWING WITH TIME      -> a SINK error. The offset absorbs the mean of a
#                             drift, so the early record is fitted too low and
#                             the late record too high (or vice versa), and a
#                             single constant hides both halves.
#
# AND THE WINDOW MATTERS MORE THAN EITHER. `rep_dC` applies ONLY to the station
# streams. The ice-core term is scored WITHOUT it, so "flat" measured over
# 1958-2024 is not the same claim as "flat" measured over the whole record, and
# GATE D extends the same residual back to 1750 on Law Dome -- the ice and the
# flasks agree to 0.31 ppm over their 54 overlapping years, so they can be read
# as one continuous target.
#
# Scored on the arm-N mode with its forcing parameters applied (the FULL
# resolution of diag_app_params.R), over the MLO/SPO record the likelihood
# actually scores.
#
# Usage:  Rscript calibration/diag_rep_dC_shape.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

RS_MODE_FILE <- ccx_mode_file()
RS_YEARS     <- c(1750, 2024)
RS_BOMB_REF  <- 102
RS_DECADES   <- seq(1960, 2020, by = 10)

md <- readRDS(RS_MODE_FILE); pm <- md$par_mode
cat(sprintf("mode %s   rep_dC %+.3f ppm = %+.2f sd of its N(0, %.1f) prior\n\n",
            basename(RS_MODE_FILE), pm$rep_dC, pm$rep_dC / LIK_CO2_REP_ERR,
            LIK_CO2_REP_ERR))

p <- ccx_default_params()
for (n in intersect(names(p), CCX_PARAM_NAMES)) p[[n]] <- pm[[n]]
p$pump_mode <- md$pump_mode
sp <- ccx_spinup(p)
F  <- ccx_build_forcing("historical", RS_YEARS, prod_c14 = sp$prod_c14,
                        bomb_total_kmol = pm$bomb_total, luc_scale = pm$luc_scale)
o  <- ccx_run_fast(sp, F)$out

obs <- ccx_prepare_obs()$co2
# Annual means on BOTH sides before differencing: the monthly residual is
# dominated by the seasonal cycle, which is a different misfit with its own
# parameters and would swamp the level question this script is asking.
resid_by_year <- function(stn, col) {
  ob <- obs[obs$station == stn, ]
  oy <- tapply(ob$co2_ppm, floor(ob$decimal_date + 1e-9), mean)
  my <- tapply(o[[col]], floor(o$t + 1e-9), mean)
  yy <- intersect(names(oy), names(my))
  data.frame(year = as.integer(yy), resid = as.numeric(my[yy] - oy[yy]))
}
nh <- resid_by_year("MLO", "co2_NH")
sh <- resid_by_year("SPO", "co2_SH")

cat(sprintf("model box MINUS station, annual means, ppm (positive = model high)\n"))
cat(sprintf("%-8s %10s %10s %10s\n", "decade", "NH-MLO", "SH-SPO", "common"))
for (d in RS_DECADES) {
  a <- mean(nh$resid[nh$year >= d & nh$year < d + 10])
  b <- mean(sh$resid[sh$year >= d & sh$year < d + 10])
  if (is.nan(a) && is.nan(b)) next
  cat(sprintf("%-8d %+10.2f %+10.2f %+10.2f\n", d, a, b, (a + b) / 2))
}
mn <- mean(nh$resid); ms <- mean(sh$resid)
cat(sprintf("%-8s %+10.2f %+10.2f %+10.2f\n", "ALL", mn, ms, (mn + ms) / 2))

# ---- GATE A: is it common-mode? -------------------------------------
# If NH and SH carry the SAME offset, it is not station representation.
cat(sprintf("\nGATE A (common-mode?)  NH %+.2f  SH %+.2f  difference %+.2f ppm\n",
            mn, ms, mn - ms))
cat(sprintf("  fitted rep_dC %+.2f ppm; the common part is %+.2f = %.0f%% of it\n",
            pm$rep_dC, (mn + ms) / 2, 100 * ((mn + ms) / 2) / pm$rep_dC))
cat(sprintf("  as atmospheric carbon: %+.1f GtC (%.2f GtC/ppm)\n",
            (mn + ms) / 2 * ccx_const("GtC_PER_PPM"), ccx_const("GtC_PER_PPM")))

# ---- GATE B: is it flat? --------------------------------------------
# OLS slope of the common residual on year. A representation constant has none.
cm <- merge(nh, sh, by = "year", suffixes = c("_nh", "_sh"))
cm$common <- (cm$resid_nh + cm$resid_sh) / 2
fit <- stats::lm(common ~ year, data = cm)
sl  <- summary(fit)$coefficients["year", ]
cat(sprintf("\nGATE B (flat?)  common residual trend %+.4f +/- %.4f ppm/yr  (t = %.1f)\n",
            sl[["Estimate"]], sl[["Std. Error"]], sl[["t value"]]))
cat(sprintf("  over the %d-%d record that is %+.2f ppm of DRIFT, against a %+.2f ppm mean\n",
            min(cm$year), max(cm$year),
            sl[["Estimate"]] * diff(range(cm$year)), mean(cm$common)))

# ---- GATE C: what would a flat offset leave behind? ------------------
cat(sprintf("\nGATE C  residual AFTER subtracting the fitted rep_dC = %.2f ppm:\n", pm$rep_dC))
cat(sprintf("%-8s %10s %10s\n", "decade", "NH", "SH"))
for (d in RS_DECADES) {
  a <- mean(nh$resid[nh$year >= d & nh$year < d + 10]) - pm$rep_dC
  b <- mean(sh$resid[sh$year >= d & sh$year < d + 10]) - pm$rep_dC
  if (is.nan(a) && is.nan(b)) next
  cat(sprintf("%-8d %+10.2f %+10.2f\n", d, a, b))
}


# ---- GATE D: the same residual over the WHOLE record ----------------
# Law Dome is ANTARCTIC, so the like-for-like model series is the SH box. (The
# likelihood scores this term against `co2_NH` on a "globally well mixed
# pre-1900" argument that is sound for the 87 pre-1900 rows and progressively
# less so for the 52 post-1958 ones, where the model's own NH-SH gradient
# reaches 3.5 ppm. Reported both ways below rather than asserted either way.)
ice <- as.data.frame(ccx_prepare_obs()$ice)
ip  <- function(col) stats::approx(o$t, o[[col]], xout = ice$year)$y
m_sh <- ip("co2_SH"); m_nh <- ip("co2_NH")
spo  <- obs[obs$station == "SPO", ]
spo_y <- tapply(spo$co2_ppm, floor(spo$decimal_date + 1e-9), mean)

cat("\nGATE D: model SH box minus ANTARCTIC CO2 (Law Dome ice, then SPO flask)\n")
cat(sprintf("  %-14s %5s %9s %9s\n", "era", "n", "model-obs", "source"))
for (w in list(c(1750, 1800), c(1800, 1850), c(1850, 1900),
               c(1900, 1940), c(1940, 1960))) {
  k <- ice$year >= w[1] & ice$year < w[2]
  if (!sum(k)) next
  cat(sprintf("  %4d-%-9d %5d %+9.2f %9s\n", w[1], w[2], sum(k),
              mean(m_sh[k] - ice$CO2ppm[k], na.rm = TRUE), "ice"))
}
for (w in list(c(1958, 1980), c(1980, 2000), c(2000, 2025))) {
  yy <- as.character(seq(w[1], w[2] - 1)); yy <- yy[yy %in% names(spo_y)]
  my <- tapply(o$co2_SH, floor(o$t + 1e-9), mean)[yy]
  cat(sprintf("  %4d-%-9d %5d %+9.2f %9s\n", w[1], w[2], length(yy),
              mean(my - spo_y[yy]), "SPO"))
}
# Are the two observational products mutually consistent where they overlap?
# If they are not, the swing below is an obs artifact and nothing more.
kv <- ice$year >= 1957 & ice$year <= 1996
dv <- data.frame(ice = ice$CO2ppm[kv], spo = spo_y[as.character(ice$year[kv])])
dv <- dv[stats::complete.cases(dv), ]
cat(sprintf("  OBS CROSS-CHECK, %d overlapping years: ice - SPO = %+.2f ppm\n",
            nrow(dv), mean(dv$ice - dv$spo)))
cat(sprintf("  (ice scored against co2_NH instead: mean resid %+.2f ppm, era spread below)\n",
            mean(m_nh - ice$CO2ppm, na.rm = TRUE)))

# ---- GATE E: what does rep_dC BUY, and what does it COST? -----------
# The prior was written to "resist a structural error wearing its clothes".
# This is the exchange rate it was up against.
eluc <- ccx_forcing_eluc_annual(F)
err  <- function(rep) list(sigma_d14c = pm$sigma_d14c, rep_dC = rep,
                           grad_off_co2 = pm$grad_off_co2,
                           grad_off_d13c = pm$grad_off_d13c)
ll   <- function(rep) ccx_loglik(o, ccx_prepare_obs(), err(rep), luc = eluc,
                                 deep = sp$diagnostics$d14c_bottom_box,
                                 ocean_grad = ccx_ocean_grad_scored(o, sp),
                                 by_stream = TRUE)
a <- ll(pm$rep_dC); b <- ll(0)
nm <- union(names(a), names(b))
gv <- function(v, n) if (is.na(v[n])) 0 else as.numeric(v[n])
cat(sprintf("\nGATE E: streams that move when rep_dC goes %.2f -> 0\n", pm$rep_dC))
for (n in nm) {
  d <- gv(a, n) - gv(b, n)
  if (abs(d) > 1e-6) cat(sprintf("  %-18s %10.2f -> %10.2f   %+10.2f\n",
                                 n, gv(a, n), gv(b, n), d))
}
pri <- stats::dnorm(pm$rep_dC, 0, LIK_CO2_REP_ERR, log = TRUE) -
       stats::dnorm(0, 0, LIK_CO2_REP_ERR, log = TRUE)
cat(sprintf("  %-18s %10s    %10s   %+10.2f\n", "LIKELIHOOD BOUGHT", "", "",
            sum(a) - sum(b)))
cat(sprintf("  %-18s %10s    %10s   %+10.2f\n", "PRIOR PAID", "", "", pri))
cat(sprintf("  exchange rate: %.0f log-units of likelihood per log-unit of prior\n",
            abs((sum(a) - sum(b)) / pri)))
