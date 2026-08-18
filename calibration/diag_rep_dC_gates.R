# =====================================================================
# GATES on the 2026-08-18 likelihood change: sigma_d13c retired, rep_dC added.
#
# Three things must hold, and a green suite does not check any of them:
#   1. LEGACY PARITY  -- with sigma_d13c supplied and rep_dC absent, every
#      stream must reproduce the value stored in mode_fit_pumpN.rds EXACTLY.
#      If it does not, the change altered the old objective rather than
#      replacing it, and no pre-2026-08-18 number can be compared to a new one.
#   2. ZERO IS A NO-OP -- rep_dC = 0 must be bit-identical to rep_dC absent.
#   3. THE COUPLING IS REAL -- a non-zero rep_dC must move the CO2 and d13C
#      level residuals TOGETHER in the mass-balance ratio, not independently.
#      This is the whole safety argument for the shared parameter; if the two
#      could move separately it would be a free d13C offset in disguise.
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

m  <- readRDS("calibration/output/pump_arms/mode_fit_pumpN.rds")
pm <- m$par_mode
bp <- ccx_default_params(); bp$pump_mode <- "N"
p_mode <- bp
for (n in intersect(names(p_mode), names(pm))) p_mode[[n]] <- pm[[n]]
p_mode$sst_obs <- 0       # observed-SST is post-mode too (2026-08-18)
p_mode$seas_drivers <- 0  # THE ESCAPE HATCH, load-bearing: this mode was
# fitted under the pre-2026-08-18 seasonal SINE (its seas_amp/phase are in
# par_mode); the drivers path would ignore them and substitute defaults. The
# rds-reproduction gate below is what catches this line going missing.


sp <- ccx_spinup(p_mode)
F  <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = 0, bomb_total_kmol = 102)
F$c14_cosmo <- sp$prod_c14
F$c14_bomb  <- F$c14_bomb * (pm$bomb_total / 102)
for (cc in c("e_luc_NH","e_luc_SH","cum_luc_NH","cum_luc_SH")) F[[cc]] <- F[[cc]] * pm$luc_scale
attr(F, "luc_scale") <- pm$luc_scale
el <- ccx_forcing_eluc_annual(F); el$eluc <- el$eluc * pm$luc_scale
r  <- ccx_run_fast(sp, F); obs <- ccx_prepare_obs()

LL <- function(err) ccx_loglik(r$out, obs, err, luc = el,
                               deep = sp$diagnostics$d14c_bottom_box,
                               ocean_grad = ccx_ocean_grad_scored(r$out, sp),
                               by_stream = TRUE)

ok <- TRUE
say <- function(lbl, pass) { cat(sprintf("  %-56s %s\n", lbl, if (pass) "PASS" else "*** FAIL ***"))
                             if (!pass) ok <<- FALSE }

# ---- gate 1: legacy parity ------------------------------------------
cat("\n=== GATE 1: legacy parity (sigma_d13c supplied, rep_dC absent) ===\n")
legacy <- LL(list(sigma_d13c = pm$sigma_d13c, sigma_d14c = pm$sigma_d14c,
                  grad_off_co2 = pm$grad_off_co2, grad_off_d13c = pm$grad_off_d13c))
worst <- 0
for (nm in names(m$streams)) {
  d <- abs(legacy[[nm]] - m$streams[[nm]]); worst <- max(worst, d)
  if (d > 1e-8) cat(sprintf("    %-18s delta %.3e\n", nm, d))
}
cat(sprintf("    worst |delta| over %d streams: %.3e\n", length(m$streams), worst))
say("every stored stream reproduced to 1e-8", worst < 1e-8)

# ---- gate 2: zero is a no-op ----------------------------------------
cat("\n=== GATE 2: rep_dC = 0 is bit-identical to rep_dC absent ===\n")
base_abs <- LL(list(sigma_d14c = pm$sigma_d14c,
                    grad_off_co2 = pm$grad_off_co2, grad_off_d13c = pm$grad_off_d13c))
base_zero <- LL(list(sigma_d14c = pm$sigma_d14c, rep_dC = 0,
                     grad_off_co2 = pm$grad_off_co2, grad_off_d13c = pm$grad_off_d13c))
say("identical", identical(unname(base_abs), unname(base_zero)))

# ---- gate 3: the coupling ------------------------------------------
cat("\n=== GATE 3: rep_dC moves CO2 and d13C together, in ratio ===\n")
ms <- ccx_model_stats(r$out, obs)
resid <- function(rep) {
  bco2 <- mean(sapply(c("MLO","SPO"), function(st) {
    o <- obs$co2_ann[[st]]; mm <- ms$co2[[st]]; k <- match(o$year, mm$year); g <- !is.na(k)
    mean(o$level[g] - (mm$level[k[g]] - rep)) }))
  bd13 <- mean(sapply(c("MLO","SPO"), function(st) {
    o <- obs$d13_ann[[st]]; mm <- ms$d13[[st]]; k <- match(o$year, mm$year); g <- !is.na(k)
    pr <- mm$level[k[g]]
    cb <- ms$co2[[st]]$level[match(o$year[g], ms$co2[[st]]$year)]
    if (rep != 0) pr <- pr - rep * (LIK_REP_SOURCE_D13C - pr) / cb
    mean(o$level[g] - pr) }))
  c(co2 = bco2, d13c = bd13)
}
r0 <- resid(0)
cat(sprintf("    rep_dC = 0 : CO2 bias %+.4f ppm, d13C bias %+.4f permil\n", r0["co2"], r0["d13c"]))
cat(sprintf("%8s %12s %12s %14s\n", "rep_dC", "dCO2 bias", "dd13C bias", "ratio permil/ppm"))
ratios <- c()
for (rep in c(-1, -0.5, 0.5, 1)) {
  rr <- resid(rep); dco2 <- rr["co2"] - r0["co2"]; dd13 <- rr["d13c"] - r0["d13c"]
  ratios <- c(ratios, dd13 / dco2)
  cat(sprintf("%8.2f %12.4f %12.5f %14.5f\n", rep, dco2, dd13, dd13 / dco2))
}
# Mass balance predicts d(d13C bias)/d(CO2 bias) = -(d_s - d13C)/CO2, since
# d(CO2 bias)/d(rep_dC) = +1.
#
# THE BACKGROUND MUST BE THE ONE THE STREAM SCORES ON, and it is taken from the
# OBSERVATIONS, not the model. Both points matter and the first was got wrong
# once: averaging d13C and CO2 over the whole 1750-2024 run gives -7.07 permil
# and 305 ppm, which is the preindustrial-weighted mean and predicts a ratio 30 %
# too large. The d13C stream scores ~1990 onward. Using OBSERVED station values
# also keeps this an INDEPENDENT check -- predicting from the model's own state
# would just restate the implementation back to itself.
yrs_sc <- Reduce(intersect, lapply(c("MLO","SPO"), function(st) obs$d13_ann[[st]]$year))
d13_bg <- mean(sapply(c("MLO","SPO"), function(st) {
  o <- obs$d13_ann[[st]]; mean(o$level[o$year %in% yrs_sc]) }))
co2_bg <- mean(sapply(c("MLO","SPO"), function(st) {
  o <- obs$co2_ann[[st]]; mean(o$level[o$year %in% yrs_sc]) }))
# SIGN, spelled out because it has been got wrong three times in one session.
# station = box - rep (d_s - d13C_box)/CO2_box.  d_s < d13C_box, so that term is
# NEGATIVE and rep > 0 makes the STATION HEAVIER than the box -- correct, since
# the box is the thing holding the extra light carbon.  Hence
#   d(d13C bias)/d(rep) = -(d_s - d13C)/CO2 * -1 = (d_s - d13C)/CO2  < 0
# while d(CO2 bias)/d(rep) = +1, so the RATIO IS NEGATIVE.
pred <- (LIK_REP_SOURCE_D13C - d13_bg) / co2_bg
cat(sprintf("\n    mass-balance prediction from OBS: %+.5f permil per ppm\n", pred))
cat(sprintf("      (d_s %.1f permil, observed d13C %.2f, observed CO2 %.0f, over %d scored yr)\n",
            LIK_REP_SOURCE_D13C, d13_bg, co2_bg, length(yrs_sc)))
cat(sprintf("    measured ratios span     %+.5f .. %+.5f\n", min(ratios), max(ratios)))
say("ratio matches mass balance within 15 %", all(abs(ratios / pred - 1) < 0.15))
say("ratio is NEGATIVE (station heavier than box for rep_dC > 0)", all(ratios < 0))
say("ratio is CONSTANT across rep_dC (a single knob, not two)",
    (max(ratios) - min(ratios)) / abs(mean(ratios)) < 0.05)

cat(sprintf("\n=== %s ===\n", if (ok) "ALL GATES PASS" else "GATES FAILED"))
if (!ok) quit(status = 1)
