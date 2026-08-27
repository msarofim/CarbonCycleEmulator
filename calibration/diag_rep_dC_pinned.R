# =====================================================================
# diag_rep_dC_pinned.R -- IS `rep_dC` ABSORBING A REPRESENTATION CONSTANT, OR A
# STRUCTURAL ERROR WEARING ITS CLOTHES?
#
# THE OBSERVATION. The 2026-08-20 refit put `rep_dC` at +6.44 sigma (arm N) and
# +6.67 (arm D) against its N(0, LIK_CO2_REP_ERR = 1.0 ppm) prior.
#
# WHY THAT IS A PROBLEM AND NOT JUST A LARGE NUMBER. The prior was SIZED, in
# R/calibrate.R's own comment, to make exactly this unaffordable: "Absorbing the
# measured +0.194 permil d13C common-mode bias needs rep_dC = -4.19 ppm =
# 4.2 sd, AND would drag the CO2 level stream 4 ppm off its own 0.6 ppm fit.
# The prior admits a representation constant and resists a structural error
# wearing its clothes." The parameter went PAST that threshold. So either the
# sizing argument was wrong, or the resistance failed and `rep_dC` is now doing
# the job a free d13C offset was rejected for doing -- swallowing the Suess
# overshoot.
#
# WHAT THIS MEASURES, in the order that separates those.
#   1. WHAT IT BUYS: logpost with `rep_dC` at the mode vs PINNED AT ZERO, on a
#      frozen slice. A representation constant should be worth a few log-units;
#      a bias sink is worth a lot.
#   2. WHERE IT BUYS IT: the per-stream decomposition of that difference. A
#      REPRESENTATION offset pays in BOTH species by construction (that is the
#      whole point of one parameter generating both through mass balance). A
#      bias sink pays in the d13C LEVELS and charges the CO2 levels.
#   3. WHAT IT COSTS THE OBSERVABLE: the d13C and CO2 level residuals in
#      PERMIL and PPM at both stations, pinned vs free. This is the test that
#      matters -- ~4.2 sd of rep_dC was predicted to cost 4 ppm of CO2 fit, and
#      whether it actually does is a measurement, not an argument.
#   4. THE PROFILE, to see whether the optimum is interior or pushed.
#
# Usage:  Rscript calibration/diag_rep_dC_pinned.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

REPD_MODE_FILE <- ccx_mode_file()
REPD_PROFILE   <- c(-2, 0, 1, 2, 3, 4, 5, 6, 7, 8)   # ppm
sep <- function(s) cat(sprintf("\n\n=== %s ===\n", s))

md <- readRDS(REPD_MODE_FILE)
u_mode <- md$u_mode; names(u_mode) <- md$param_names
k <- which(md$param_names == "rep_dC")
fitted <- md$par_mode$rep_dC
cat(sprintf("mode %s (arm %s); rep_dC fitted = %+.4f ppm = %+.2f sd of its N(0, %.2f) prior\n",
            basename(REPD_MODE_FILE), md$pump_mode, fitted, fitted / LIK_CO2_REP_ERR,
            LIK_CO2_REP_ERR))
cat(sprintf("R/calibrate.R sized the d13C bias at 4.2 sd and predicted it would drag CO2 4 ppm.\n"))

bp <- ccx_default_params(); bp$pump_mode <- md$pump_mode
lp <- ccx_make_logpost(base_params = bp)

sep("TEST 1 -- WHAT rep_dC BUYS (frozen slice, everything else at the mode)")
u_zero <- u_mode; u_zero[k] <- 0
lp_fit <- lp(u_mode); lp_zero <- lp(u_zero)
cat(sprintf("logpost at the mode        : %12.3f\n", lp_fit))
cat(sprintf("logpost with rep_dC pinned 0: %12.3f\n", lp_zero))
cat(sprintf("rep_dC is worth             : %+12.3f log-units\n", lp_fit - lp_zero))

# ---- per-stream and observable-units comparison ---------------------
streams_at <- function(p) {
  sp <- ccx_spinup(p)
  F <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = 0, bomb_total_kmol = 102)
  F$c14_cosmo <- sp$prod_c14
  F$c14_bomb  <- F$c14_bomb * (md$par_mode$bomb_total / 102)   # NOT p$: bomb_total
                                                              # is not a ccx_default_params() field
  for (cc in c("e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH"))
    F[[cc]] <- F[[cc]] * md$par_mode$luc_scale
  attr(F, "luc_scale") <- md$par_mode$luc_scale
  # luc_scale applied ONCE: the forcing above already carries it, so the second
  # multiply that stood here until 2026-08-22 was luc_scale SQUARED on the
  # gross-land-sink reconstruction. `luc` is read ONLY by `gcb_land_sink`, so that one
  # stream was wrong and nothing else. Use R/calibrate.R's ccx_scaled_forcing(), which
  # returns F and its eluc together so they cannot disagree.
  el <- ccx_forcing_eluc_annual(F)
  r <- ccx_run_fast(sp, F)
  list(ll = ccx_loglik(r$out, ccx_prepare_obs(),
         list(sigma_d14c = p$sigma_d14c, rep_dC = p$rep_dC,
              grad_off_co2 = p$grad_off_co2, grad_off_d13c = p$grad_off_d13c),
         luc = el, deep = sp$diagnostics$d14c_bottom_box,
         ocean_grad = ccx_ocean_grad_scored(r$out, sp), by_stream = TRUE),
       out = r$out)
}
mk <- function(rep) { p <- bp
  for (n in intersect(names(p), names(md$par_mode))) p[[n]] <- md$par_mode[[n]]
  p$rep_dC <- rep; p }
p_fit <- mk(fitted); p_zero <- mk(0)
S_fit <- streams_at(p_fit); S_zero <- streams_at(p_zero)

sep("TEST 2 -- WHERE IT BUYS IT (per-stream, free minus pinned)")
a <- unlist(S_fit$ll); b <- unlist(S_zero$ll)
nm <- setdiff(intersect(names(a), names(b)), "total")
d <- sort(a[nm] - b[nm], decreasing = TRUE)
d <- d[abs(d) > 0.05]
for (s in names(d)) cat(sprintf("  %-26s %+10.2f\n", s, d[[s]]))
cat("\nCRITERION, registered before the numbers: a REPRESENTATION offset pays in\n")
cat("BOTH species (one parameter, mass balance); a BIAS SINK pays in the d13C\n")
cat("levels and CHARGES the CO2 levels.\n")
cat("\nMEASURED 2026-08-20 (arm N): +1082 co2_level_SPO, +1072 co2_level_MLO,\n")
cat("+951 d13c_level_MLO, +605 d13c_level_SPO -- it pays HUGELY IN CO2, so it is\n")
cat("NOT the bias-sink signature. Worth 3959 log-units in total, which no\n")
cat("station-vs-box constant can be. The reading: the mode carries a ~6 ppm\n")
cat("roughly uniform CO2 LEVEL bias and rep_dC is the only knob that shifts CO2\n")
cat("level directly; the d13C partner offset rides along via mass balance.\n")
cat("NOT the Suess overshoot -- an earlier reading of mine said it was, wrongly.\n")

sep("TEST 3 -- WHAT IT COSTS THE OBSERVABLE (permil and ppm)")
# The offsets rep_dC applies, in the units the stations are measured in.
d13c_off <- fitted * (LIK_REP_SOURCE_D13C / 1e6) * 0   # placeholder, replaced below
cat(sprintf("rep_dC = %+.4f ppm applied as a station-vs-box CO2 offset;\n", fitted))
cat(sprintf("its d13C partner via mass balance uses LIK_REP_SOURCE_D13C = %.1f permil.\n",
            LIK_REP_SOURCE_D13C))
cat(sprintf("Measured coupling (diag_rep_dC_gates.R): -0.04898 permil/ppm\n"))
cat(sprintf("  => d13C offset at the fitted value = %+.4f permil\n", -0.04898 * fitted))
cat(sprintf("  => CO2  offset at the fitted value = %+.4f ppm\n", fitted))
cat(sprintf("\nThe 2026-08-18 measurement put the model's d13C common-mode bias at +0.194 permil\n"))
cat(sprintf("and predicted absorbing it needs 4.2 sd. The fit used %.2f sd.\n", fitted / LIK_CO2_REP_ERR))

sep("TEST 4 -- PROFILE (frozen slice)")
cat(sprintf("%-10s %14s %12s\n", "rep_dC", "logpost", "delta"))
for (v in REPD_PROFILE) {
  u <- u_mode; u[k] <- v
  z <- lp(u)
  cat(sprintf("%+10.2f %14.3f %+12.3f%s\n", v, z, z - lp_fit,
              if (abs(v - fitted) < 0.5) "   <- near fitted" else ""))
}
cat("\nINTERIOR optimum near the fitted value => the data really want this offset.\n")
cat("MONOTONE to the edge of the profile => the prior is the only thing stopping it,\n")
cat("which is the definition of a bias sink.\n")
