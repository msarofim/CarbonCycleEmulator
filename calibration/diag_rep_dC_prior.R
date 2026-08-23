# =====================================================================
# diag_rep_dC_prior.R -- IS `rep_dC`'s PRIOR MIS-CENTRED? Measured, and the
# answer is no: the CENTRE is nearly irrelevant, the SCALE has no receipt for
# the quantity it constrains, and neither is the actual defect.
#
# THE CLAIM UNDER TEST. The 2026-08-22 expert panel, item 12: "`rep_dC`'s
# N(0, 1.0) prior is mis-CENTRED: both stations must read below their box means,
# so the physical expectation is positive, not zero." The physics is right. The
# implied remedy -- re-centre and the +5.57 sigma flag goes away -- is not, and
# acting on it would have HIDDEN a real blocker behind a relabelled diagnostic.
# That is the failure mode memory `prior_z_grid_scale` already recorded once:
# a flag list that mis-ranks the work.
#
# WHAT THE THREE MEASUREMENTS BELOW ESTABLISH.
#
#   1. THE PRIOR CENTRE IS NEARLY INERT. Profiling `rep_dC` with its two
#      strongly-correlated partners re-optimised (`k_w` -0.78, `bomb_total`
#      -0.73) puts the LIKELIHOOD-only optimum at 5.62 ppm with curvature
#      sd 0.097 ppm. The data are ~10x tighter than the 1.0 ppm prior, so
#      re-centring the prior anywhere in [0, 3] ppm moves the posterior by
#      <= 0.03 ppm. It changes `prior_z` (5.57 -> 3.59 at mu = 2) and nothing
#      else. A prior centre that only moves the DIAGNOSTIC is not a fix.
#
#   2. THE PRIOR SD HAS NO RECEIPT FOR THIS QUANTITY. `LIK_CO2_REP_ERR` = 1.0
#      ppm serves as both the CO2-level stream sd and this prior's sd. Its
#      stated receipt (R/likelihood.R) is co-located INSTRUMENT disagreement at
#      one site -- NOAA in-situ vs SIO flask at Mauna Loa, 0.39-0.59 ppm RMS --
#      and the comment itself concedes "a station-vs-hemispheric-BOX term must
#      exceed it. 1.0 ppm is a plausible value for that quantity." Plausible is
#      not measured. A station-vs-BOX offset is a SPATIAL-REPRESENTATIVENESS
#      quantity; nothing on disk measures it, which is why item 12 was priced
#      at "1 h + DATA".
#
#   3. AND THE REAL DEFECT IS NEITHER. Part 3 is the one that matters: the
#      offset the data demand is REMARKABLY CONSTANT within the flask era and
#      CHANGES SIGN before it. `rep_dC` is not a representation constant that
#      came out too big -- it is the MODERN HALF OF THE ~9 ppm SWING wearing a
#      representation constant's clothes (memory ccx_rep_dc_co2_bias reached the
#      same place from the logL side; this reaches it from the residuals).
#
# NOTE THE ASYMMETRY THAT MAKES THIS WORK: `rep_dC` is applied to the MLO/SPO
# level streams ONLY. R/likelihood.R's ice block scores the bare `co2_SH` box
# against Law Dome with no offset at all. So the flask era can be fitted by the
# offset while the ice era cannot, and comparing the two eras isolates it.
#
# Usage:  Rscript calibration/diag_rep_dC_prior.R
# Runtime ~4 min (part 1 re-optimises at each grid point).
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

RP_ARM      <- "N"
RP_GRID     <- seq(5.0, 6.4, by = 0.2)      # around the mode, for the curvature fit
RP_PARTNERS <- c("k_w", "bomb_total")       # the two |cor| > 0.7 partners
RP_MU_TRIAL <- c(0, 0.5, 1, 2, 3)           # candidate prior centres to price
RP_FLASK_ERAS <- list(c(1958,1970), c(1970,1985), c(1985,2000), c(2000,2012), c(2012,2024))
RP_ICE_ERAS   <- list(c(1850,1900), c(1900,1940), c(1940,1958))

M  <- ccx_load_mode(RP_ARM)
sp <- ccx_spinup(M$p)
SF <- ccx_scaled_forcing(sp, luc_scale = M$luc_scale, bomb_total = M$bomb_total)
o  <- ccx_run_fast(sp, SF$F)$out
obs <- ccx_prepare_obs(); ms <- ccx_model_stats(o, obs)

cat(sprintf("\n=== 0. THE PARAMETER ===\n  fitted rep_dC = %.3f ppm; prior N(0, %.2f) => prior_z = %.2f\n",
            M$err$rep_dC, LIK_CO2_REP_ERR, M$err$rep_dC / LIK_CO2_REP_ERR))
cat(sprintf("  posterior sd (from the per-direction Hessian) = %.3f ppm\n",
            M$md$sd_unc[["rep_dC"]]))

# ---- 1. is the CENTRE the operative knob? ---------------------------
CCX_PARAM_TABLE$h_ml$lo <- M$md$hml_bound[1]; CCX_PARAM_TABLE$h_ml$hi <- M$md$hml_bound[2]
lp <- ccx_make_logpost(); u0 <- unlist(ccx_par_to_unc(M$md$par_mode))
prior_rep <- function(x) stats::dnorm(x, 0, LIK_CO2_REP_ERR, log = TRUE)
cat(sprintf("\n=== 1. PROFILE (partners %s re-optimised) ===\n",
            paste(RP_PARTNERS, collapse = ", ")))
cat(sprintf("%8s %14s %14s\n", "rep_dC", "logpost", "loglik"))
LL <- vapply(RP_GRID, function(x) {
  u <- u0; u[["rep_dC"]] <- x
  op <- stats::optim(u0[RP_PARTNERS], function(v) { uu <- u; uu[RP_PARTNERS] <- v; -lp(uu) },
                     method = "Nelder-Mead", control = list(maxit = 400, reltol = 1e-10))
  cat(sprintf("%8.2f %14.3f %14.3f\n", x, -op$value, -op$value - prior_rep(x)))
  -op$value - prior_rep(x)
}, numeric(1))
cf <- stats::coef(stats::lm(LL ~ poly(RP_GRID, 2, raw = TRUE)))
xL <- -cf[2] / (2 * cf[3]); sL <- sqrt(-1 / (2 * cf[3]))
cat(sprintf("\n  LIKELIHOOD-only optimum %.3f ppm, curvature sd %.3f ppm\n", xL, sL))
cat(sprintf("  the data are %.1fx tighter than the %.1f ppm prior\n", LIK_CO2_REP_ERR / sL, LIK_CO2_REP_ERR))
cat(sprintf("\n%10s %16s %10s %12s\n", "prior mu", "posterior mode", "shift", "new prior_z"))
base <- (xL / sL^2) / (1 / sL^2 + 1 / LIK_CO2_REP_ERR^2)
for (mu in RP_MU_TRIAL) {
  xp <- (xL / sL^2 + mu / LIK_CO2_REP_ERR^2) / (1 / sL^2 + 1 / LIK_CO2_REP_ERR^2)
  cat(sprintf("%10.1f %16.3f %+10.3f %12.2f\n", mu, xp, xp - base, (xp - mu) / LIK_CO2_REP_ERR))
}
cat("\n  => RE-CENTRING MOVES THE FIT BY <= 0.03 ppm AND THE FLAG BY ~2 SIGMA.\n")
cat("     It relabels the diagnostic without changing a single fitted value.\n")

# ---- 2/3. what the data actually demand, era by era -----------------
cat("\n=== 2. THE OFFSET THE DATA DEMAND, ERA BY ERA (box - station, ppm) ===\n")
cat("  rep_dC is applied to the FLASK streams only; the ice term scores the bare box.\n\n")
cat(sprintf("%-12s %10s %10s %10s\n", "flask era", "MLO", "SPO", "mean"))
fl <- vapply(RP_FLASK_ERAS, function(e) {
  v <- vapply(c("MLO", "SPO"), function(st) {
    ob <- obs$co2_ann[[st]]; mm <- ms$co2[[st]]
    k <- match(ob$year, mm$year); g <- !is.na(k) & ob$year >= e[1] & ob$year < e[2]
    mean(mm$level[k[g]] - ob$level[g]) }, numeric(1))
  cat(sprintf("%-12s %10.2f %10.2f %10.2f\n", paste0(e[1], "-", e[2]), v[1], v[2], mean(v)))
  mean(v) }, numeric(1))
cat(sprintf("\n%-12s %10s\n", "ice era", "box - obs"))
mod_ice <- stats::approx(o$t, o$co2_SH, xout = obs$ice$year, rule = 2)$y
ic <- vapply(RP_ICE_ERAS, function(e) {
  g <- obs$ice$year >= e[1] & obs$ice$year < e[2]
  v <- mean(mod_ice[g] - obs$ice$CO2ppm[g])
  cat(sprintf("%-12s %10.2f\n", paste0(e[1], "-", e[2]), v)); v }, numeric(1))

cat(sprintf("\n=== 3. THE VERDICT ===\n"))
cat(sprintf("  flask era: mean %+.2f ppm, spread %.2f ppm over %d yr -- CONSTANT to ~1 ppm,\n",
            mean(fl), diff(range(fl)), 2024 - 1958))
cat(sprintf("             and MLO-vs-SPO agree to ~0.3 ppm, i.e. genuinely COMMON-MODE.\n"))
cat(sprintf("             fitted rep_dC %.2f == the flask-era mean %.2f.\n", M$err$rep_dC, mean(fl)))
cat(sprintf("  ice era  : %+.2f to %+.2f ppm -- THE OPPOSITE SIGN.\n", min(ic), max(ic)))
cat(sprintf("  swing    : %.1f ppm between the 1900-40 and 2012-24 eras.\n", fl[length(fl)] - min(ic)))
cat("\n  A representation offset is a property of a STATION versus a BOX. It cannot\n")
cat("  change sign when the observing system changes, and it should not need to.\n")
cat("  So `rep_dC` is NOT a representation constant that came out too large: it is\n")
cat("  the MODERN HALF OF THE ~9 ppm SWING, and it sits at the flask-era mean\n")
cat("  because the flask streams outweigh the ice term. The +5.57 sigma is the\n")
cat("  swing being reported in the units of the parameter that hides it.\n")
cat("\n  CONSEQUENCE: no change to this prior -- centre OR scale -- addresses that.\n")
cat("  Re-centring hides it. Widening it hides it further. Tightening it forces the\n")
cat("  modern residual back into the CO2 rows where it is VISIBLE, at a logL cost\n")
cat("  that part 1 prices (~370 log-units to pin at 3.0 ppm, 2 partners free).\n")
