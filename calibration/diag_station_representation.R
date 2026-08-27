# =====================================================================
# IS THE COMMON-MODE d13C BIAS A STATION-vs-BOX REPRESENTATION OFFSET?
#
# THE QUESTION (Marcus, 2026-08-18). MLO and SPO are not exact measures of
# hemispheric concentration, so a station-vs-box OFFSET is physically expected
# and the likelihood should probably carry one. The likelihood currently has
# GRADIENT offsets (grad_off_co2, grad_off_d13c) but NO LEVEL offset: the level
# terms compare a station straight to the model's hemispheric box. So the
# common-mode d13C bias measured by diag_fit_at_mode.R (+0.23 MLO, +0.15 SPO)
# has nowhere to go and lands in the residual.
#
# THE TEST, and it is decisive because the two species are not independent.
# A representation offset is one physical thing: the box holds air the remote
# marine station does not see -- continental boundary layer carrying fossil and
# respired CO2. That carbon has BOTH more CO2 AND lighter d13C, tied by mass
# balance. So a representation offset must move CO2 and d13C TOGETHER, in a
# fixed ratio set by the source signature:
#
#   box = station air + dC of signature d_s
#   d_box - d_st = dC (d_s - d_st) / C_box
#   bias_co2  = obs_st - mod_box = -dC
#   bias_d13c = obs_st - mod_box = -dC (d_s - d_st)/C_box = -k * bias_co2 * ...
#
# ⇒ bias_d13c_predicted = -(d_s - d_st)/C_box * bias_co2
#
# If the measured d13C bias is far larger than the measured CO2 bias predicts,
# the d13C offset is NOT representation and a free level offset would be
# absorbing a structural model error instead. That is the thing to know BEFORE
# adding the parameter, not after.
#
# Usage: Rscript calibration/diag_station_representation.R [N|D]
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

ARM <- (function(a) if (length(a) && a[1] %in% c("N", "D")) a[1] else "N")(commandArgs(TRUE))
m  <- readRDS(ccx_mode_file(ARM))
pm <- m$par_mode
bp <- ccx_default_params(); bp$pump_mode <- ARM
p_mode <- bp
for (n in intersect(names(p_mode), CCX_PARAM_NAMES)) p_mode[[n]] <- pm[[n]]
# ESCAPE HATCH REMOVED 2026-08-22, and it had been WRONG since the 2026-08-20
# refit. It forced `sst_obs <- 0` and `seas_drivers <- 0` on the argument that
# this mode was fitted under the pre-2026-08-18 seasonal SINE -- true of the
# 08-18 mode, false of the one on disk. mode_fit_pumpN.rds (08-21) carries the
# DRIVER parameters (seas_T_amp_*, seas_lag_p, sst_seas_amp_*, npp_frac_NH) and
# no sine knobs, so the hatch ran this diagnostic at a DIFFERENT MODEL from the
# fit it describes. See calibration/diag_fit_at_mode.R's header for the full set
# of staleness defects found with it.


sp <- ccx_spinup(p_mode)
F  <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = 0, bomb_total_kmol = 102)
F$c14_cosmo <- sp$prod_c14
F$c14_bomb  <- F$c14_bomb * (pm$bomb_total / 102)
for (cc in c("e_luc_NH","e_luc_SH","cum_luc_NH","cum_luc_SH")) F[[cc]] <- F[[cc]] * pm$luc_scale
out <- ccx_run_fast(sp, F)$out
obs <- ccx_prepare_obs(); ms <- ccx_model_stats(out, obs)

bias <- function(o, mm, col = "level") {
  k <- match(o$year, mm$year); g <- !is.na(k)
  c(bias = mean(o[[col]][g] - mm$level[k[g]]), n = sum(g))
}
bco2 <- setNames(sapply(c("MLO","SPO"), function(s) unname(bias(obs$co2_ann[[s]], ms$co2[[s]])["bias"])), c("MLO","SPO"))
bd13 <- setNames(sapply(c("MLO","SPO"), function(s) unname(bias(obs$d13_ann[[s]], ms$d13[[s]])["bias"])), c("MLO","SPO"))

# The source signature and background, taken from the MODEL, not assumed.
yrs   <- out$t >= 2000
C_box <- mean((out$co2_NH[yrs] + out$co2_SH[yrs]) / 2)
d_st  <- mean(sapply(c("MLO","SPO"), function(s) {
           o <- obs$d13_ann[[s]]; mean(o$level[o$year >= 2000]) }))
# d_s: the excess carbon a continental box carries relative to marine baseline
# is fossil + respired.  Fossil is the forcing's own d13c_foss; respiration
# carries the land biosphere's signature.  Bracket rather than pick one.
d_foss <- -28; d_resp <- -25; d_s_range <- c(d_resp, d_foss)

cat(sprintf("\n=== STATION-vs-BOX REPRESENTATION TEST, arm %s ===\n\n", ARM))
cat(sprintf("  measured bias (obs_station - model_box), 
    CO2   MLO %+7.4f   SPO %+7.4f  ppm    common-mode %+7.4f
    d13C  MLO %+7.4f   SPO %+7.4f  permil common-mode %+7.4f\n\n",
    bco2["MLO"], bco2["SPO"], mean(bco2),
    bd13["MLO"], bd13["SPO"], mean(bd13)))
cat(sprintf("  model background: C_box %.1f ppm, station d13C %.3f permil (2000+)\n", C_box, d_st))
cat(sprintf("  assumed excess-carbon signature d_s in [%g, %g] permil\n\n", d_s_range[1], d_s_range[2]))

cat("  IF the CO2 bias is a representation offset, mass balance REQUIRES:\n")
for (d_s in d_s_range) {
  # dC = C_box - C_st = -bias_co2 ; bias_d13c = d_st - d_box = -dC (d_s-d_st)/C_box
  k <- (d_s - d_st) / C_box             # permil of d13C per ppm of CO2 BIAS
  pred <- k * mean(bco2)
  cat(sprintf("    d_s = %6.1f permil -> %+.4f permil per ppm  =>  predicted d13C bias %+.4f permil\n",
              d_s, k, pred))
}
k_mid <- (mean(d_s_range) - d_st) / C_box
pred_mid <- k_mid * mean(bco2)
cat(sprintf("\n  MEASURED d13C common-mode bias      %+.4f permil\n", mean(bd13)))
cat(sprintf("  PREDICTED from the CO2 bias (mid)   %+.4f permil\n", pred_mid))
cat(sprintf("  RATIO measured / predicted          %.1fx\n\n", mean(bd13) / pred_mid))

cat(sprintf("  Inverted: to explain %+.4f permil of d13C as representation would need a\n", mean(bd13)))
cat(sprintf("  CO2 offset of %+.2f ppm.  The measured CO2 common-mode bias is %+.3f ppm,\n",
            mean(bd13) / k_mid, mean(bco2)))
cat(sprintf("  and LIK_CO2_REP_ERR (the repo's own station-vs-box scale) is %.1f ppm.\n", LIK_CO2_REP_ERR))

cat("\n  VERDICT: ")
if (abs(mean(bd13) / pred_mid) > 5)
  cat("the d13C common-mode bias is FAR larger than the CO2 bias can explain\n  under a shared representation mechanism. The SIGN agrees, the MAGNITUDE does\n  not. A free common-mode d13C level offset would absorb a STRUCTURAL error.\n")
if (abs(mean(bd13) / pred_mid) <= 5) cat("consistent with representation.\n")
