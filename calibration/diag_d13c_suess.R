# =====================================================================
# diag_d13c_suess.R -- the model's 13C Suess decline is ~30 % too steep, and
# nothing available can close it. This is a STRUCTURAL finding, not a bug list.
#
# FOUND 2026-08-12 while pricing handoff 12d sec.0 step 1. The d13C residual is
# neither scatter nor a constant offset: obs - model grows monotonically from
# ~0 permil in 1850 to +0.58 by 2020 at MLO (+0.43 at SPO), with 0.07 permil of
# year-to-year scatter around it. The model reproduces the SHAPE of the Suess
# decline and overshoots its MAGNITUDE.
#
# Why it matters beyond d13C itself: a too-depleted atmosphere is relieved by a
# LARGER land sink (photosynthesis discriminates against 13C), so the d13C term
# pushes q10 DOWN -- it is a CONTRIBUTOR to the q10 inversion, not a cure for
# it. diag_q10_stream_direction.R measures that direction.
#
# WHAT THIS SCRIPT ESTABLISHES, in order:
#
# [1] The residual's structure in time (Law Dome pre-1980, Scripps after).
#
# [2] Sensitivity to each PROVISIONAL 13C constant, CO2 bias carried alongside
#     so a "fix" that moves the carbon budget is visible. The fossil source
#     signature is the only strong lever: -28 -> -24 permil takes MLO +0.577 ->
#     +0.048 with CO2 unmoved, where the three fractionation factors move it
#     0.014-0.035 permil per permil. That motivated the fossil-source fix below,
#     and is why the atmosphere's d13C is worth trusting as a partition signal.
#
#     THE FOSSIL-SOURCE FIX IS DONE AND IT WAS NEARLY WORTHLESS. d13c_foss was a
#     single -28 permil for 1750-2024, wrong twice over: GCB's `fossil` column is
#     fossil-fuel-AND-INDUSTRY, so ~4-5 % of it is cement (calcined limestone,
#     ~0 permil), and the fuel mix ran from all-coal (~-24) to gas-inclusive
#     (~-44 for the gas share). It is now built per year from GCB's own by-fuel
#     split (data-raw/build_calibration_data.R [5b]), running -24.0 in 1850 to
#     -28.3 in 2024 -- inside the -28 to -24 envelope Graven et al. (2020) state
#     for the global fossil-plus-cement signature.
#     It moved the 2015-2024 MLO bias 0.577 -> 0.561, i.e. 3 % of it. The reason
#     is emission weighting: the years where the old constant was most wrong
#     carry almost no emissions. The correction is right and stays; the
#     over-depletion is not the source signature.
#
# [3] Is it the SINK PARTITION? Closing the d13C bias needs a ~72 % land share
#     (beta ~0.9) against GCB's 42 %, which puts CO2 40 ppm high and the land
#     sink at 4.7 GtC/yr against GCB's 2.4. d13C and CO2 cannot both be
#     satisfied by any partition this model can reach.
#
# [4] Is it weak isotopic DISEQUILIBRIUM DAMPING? `ra_ratio`, the gross land
#     loop, moves the bias 0.10 permil across its whole plausible range while
#     leaving net carbon untouched -- and D14C (the right constraint on gross
#     exchange) goes +2.7 to -14.6 permil across the same range, forbidding the
#     large values. Not it either.
#
# WHAT IS LEFT: the model over-depletes by ~0.55 permil and none of the source
# signature, the fractionation constants, the reachable sink partition, or the
# gross land exchange accounts for it. The calibration's only remaining way to
# relieve it is to manufacture land sink -- which is what q10 -> 0.17 is doing.
# Untested candidate: the ocean-side disequilibrium, in a pure-diffusion ocean
# with no biological pump whose DIC inventory is ~16 % low.
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

# ---- PINNED TO THE LOG FERTILIZATION FORM (2026-08-14) --------------
# This diagnostic was written against NPP = NPP0(1 + beta ln(chi/chi0)) and
# every number in its header is a LOG-FORM number. On 2026-08-14 the default
# flipped to CCX_FERT_MM, under which `beta` is INERT -- so without this pin the
# file would still run, still print a beta column, and silently report the same
# MM answer for every beta. (That is not hypothetical: it happened to
# diag_fert_pulse_gates.R and to the app's fertilization switch on the day of
# the flip, and identical rows are what caught both.)
#
# The pin makes this file reproduce its recorded numbers exactly. It does NOT
# make them current: the shipped model is now the saturating form, and anything
# here that fed a live decision must be re-run under it.
local({
  .orig <- ccx_default_params
  assign("ccx_default_params", function() {
    p <- .orig(); p$fert_form <- CCX_FERT_LOG; p
  }, envir = globalenv())
})

# ---- labels derive from constants (project rule) --------------------
DS_YEARS      <- c(1750, 2024)
DS_BOMB_REF   <- 102
DS_BIAS_WIN   <- c(2015, 2024)     # window the [2] bias is averaged over
DS_LAWDOME_BRK <- c(1750, 1800, 1850, 1900, 1930, 1950, 1960, 1970, 1980, 1991)
DS_SCRIPPS_BRK <- seq(1975, 2025, by = 5)
DS_PHOTO_GRID <- c(14, 15, 16, 17, 18, 19, 20)   # permil, land discrimination
DS_ASUP_GRID  <- c(8, 9, 10, 11, 12)             # permil, evasion  (equilibrium)
DS_ASDN_GRID  <- c(0, 1, 2, 3)                   # permil, invasion (kinetic)
DS_FOSS_GRID  <- c(-24, -25, -26, -27, -28, -29) # permil, fossil source

obs <- ccx_prepare_obs()
base_forcing <- ccx_build_forcing("historical", DS_YEARS, prod_c14 = 0,
                                  bomb_total_kmol = DS_BOMB_REF)

# d13c_foss moved from `aux` to the FORCING TABLE on 2026-08-12, so overriding
# it here means overwriting a column -- wrapping ccx_prepare() no longer reaches
# it, and a scan written that way reports six identical rows while looking live.
ds_run <- function(p, d13c_foss = NULL) {
  s <- ccx_spinup(p)
  F <- base_forcing; F$c14_cosmo <- s$prod_c14
  if (!is.null(d13c_foss)) F$d13c_foss <- d13c_foss
  list(out = ccx_run_fast(s, F)$out, spinup = s)
}

# ---------------------------------------------------------------------
cat("[1] RESIDUAL STRUCTURE IN TIME (obs - model)\n")
r  <- ds_run(ccx_default_params())
out <- r$out
cat(sprintf("    spinup d13c_atm %.3f permil vs D13C_PI %.3f\n",
            r$spinup$diagnostics$d13c_atm, ccx_const("D13C_PI")))

f_nh <- stats::approxfun(out$t, out$d13c_NH, rule = 2)
f_sh <- stats::approxfun(out$t, out$d13c_SH, rule = 2)
f_g  <- stats::approxfun(out$t, (out$d13c_NH + out$d13c_SH) / 2, rule = 2)

sp13 <- as.data.frame(readRDS(ccx_path("data", "obs_icecore.rds"))$d13c_spline)
sp13 <- sp13[sp13$year >= DS_LAWDOME_BRK[1] &
             sp13$year <= DS_LAWDOME_BRK[length(DS_LAWDOME_BRK)], ]
sp13$mod <- f_g(sp13$year + 0.5)
cat("\n  Law Dome d13C spline (Rubino et al. 2019) vs hemispheric-mean model:\n")
for (i in seq_len(length(DS_LAWDOME_BRK) - 1)) {
  k <- sp13$year >= DS_LAWDOME_BRK[i] & sp13$year < DS_LAWDOME_BRK[i + 1]
  if (!any(k)) next
  cat(sprintf("    %4d-%4d  n=%3d  obs %7.3f  mod %7.3f  resid %+7.3f\n",
              DS_LAWDOME_BRK[i], DS_LAWDOME_BRK[i + 1] - 1, sum(k),
              mean(sp13$d13c[k]), mean(sp13$mod[k]),
              mean(sp13$d13c[k] - sp13$mod[k])))
}

cat("\n  Scripps annual levels vs model:\n")
for (st in c("MLO", "SPO")) {
  o <- obs$d13_ann[[st]]
  o$mod <- (if (st == "MLO") f_nh else f_sh)(o$year + 0.5)
  for (i in seq_len(length(DS_SCRIPPS_BRK) - 1)) {
    k <- o$year >= DS_SCRIPPS_BRK[i] & o$year < DS_SCRIPPS_BRK[i + 1]
    if (!any(k)) next
    cat(sprintf("    %s %4d-%4d n=%2d  obs %7.3f  mod %7.3f  resid %+7.3f\n",
                st, DS_SCRIPPS_BRK[i], DS_SCRIPPS_BRK[i + 1] - 1, sum(k),
                mean(o$level[k]), mean(o$mod[k]), mean(o$level[k] - o$mod[k])))
  }
}

# ---------------------------------------------------------------------
# ccx_prepare() builds the 13C constants from literals, so they are overridden
# by wrapping it. That also covers ccx_spinup(), which calls ccx_prepare().
cat(sprintf("\n[2] SENSITIVITY OF THE %d-%d BIAS TO EACH PROVISIONAL 13C CONSTANT\n",
            DS_BIAS_WIN[1], DS_BIAS_WIN[2]))
ds_prepare_orig <- ccx_prepare

ds_bias <- function(mods = list(), label = "", d13c_foss = NULL) {
  assign("ccx_prepare", function(p, ...) {
    a <- ds_prepare_orig(p, ...)
    for (n in names(mods)) a[[n]] <- mods[[n]]
    a
  }, envir = globalenv())
  on.exit(assign("ccx_prepare", ds_prepare_orig, envir = globalenv()))
  ms <- ccx_model_stats(ds_run(ccx_default_params(), d13c_foss)$out, obs)
  win <- function(o, m, col) {
    k <- match(o$year, m$year)
    g <- !is.na(k) & o$year >= DS_BIAS_WIN[1] & o$year <= DS_BIAS_WIN[2]
    mean(o[[col]][g] - m$level[k[g]])
  }
  cat(sprintf("    %-40s  d13C MLO %+6.3f  SPO %+6.3f   CO2 %+6.2f ppm\n", label,
              win(obs$d13_ann$MLO, ms$d13$MLO, "level"),
              win(obs$d13_ann$SPO, ms$d13$SPO, "level"),
              win(obs$co2_ann$MLO, ms$co2$MLO, "level")))
}

cat("    (target is 0.000; CO2 bias carried so a d13C 'fix' that moves carbon shows)\n\n")
ds_bias(list(), "BASELINE, as shipped")
cat("\n  -- land discrimination alpha_photo --\n")
for (e in DS_PHOTO_GRID)
  ds_bias(list(alpha_photo = 1 - e / 1000), sprintf("alpha_photo   = -%d permil", e))
cat("\n  -- air-sea evasion alpha_as_up (equilibrium) --\n")
for (e in DS_ASUP_GRID)
  ds_bias(list(alpha_as_up = 1 - e / 1000), sprintf("alpha_as_up   = -%d permil", e))
cat("\n  -- air-sea invasion alpha_as_down (kinetic) --\n")
for (e in DS_ASDN_GRID)
  ds_bias(list(alpha_as_down = 1 - e / 1000), sprintf("alpha_as_down = -%d permil", e))
cat("\n  -- fossil source d13c_foss, held CONSTANT at each value --\n")
cat("     (the shipped model no longer has a constant here; the series it does\n")
cat("      use lands at the 'as shipped' row above)\n")
for (d in DS_FOSS_GRID)
  ds_bias(label = sprintf("d13c_foss     = %d permil", d), d13c_foss = d)

# ---------------------------------------------------------------------
# [3] IS IT THE SINK PARTITION? The land sink discriminates (-18 permil), the
# ocean sink barely does, so a partition that is too ocean-heavy gives the right
# total CO2 and a too-depleted atmosphere. This is precisely what d13C exists to
# detect, so it is the first suspect once the source signature is ruled out.
#
# RESULT: closing the d13C bias needs a ~72 % land share (beta ~0.9), against
# GCB's 42 % -- and it puts CO2 40 ppm high and the land sink at 4.7 GtC/yr
# against GCB's 2.4. d13C and CO2 CANNOT both be satisfied by any partition this
# model can reach. That is the structural misfit, located.
cat("\n[3] d13C BIAS vs LAND-SINK SHARE (scanning beta at the default q10)\n")
DS_BETA_GRID <- c(0.2, 0.38, 0.6, 0.9, 1.2)
gcb <- as.data.frame(obs$gcb)
# UNITS, fixed 2026-08-13. This returned mean(diff(land_C)) and compared it to
# GCB's `land_sink`. Those are different quantities: diff(land_C) is the NET
# land flux (sink MINUS E_LUC) and GCB's column is the residual sink alone. They
# were nearly the same while land-use carbon was being regrown and stopped being
# so at 404d66d -- the same trap diag_d13c_partition_refit.R records. The gross
# sink, which is what GCB's column means, is diff(land_C) + E_LUC.
DS_ELUC <- local({
  em <- as.data.frame(readRDS(ccx_path("data", "forcing_emissions_historical.rds")))
  mean(em$luc_GtC[em$year >= DS_BIAS_WIN[1] & em$year <= DS_BIAS_WIN[2]])
})
ds_partition <- function(out) {
  yr  <- floor(out$t + 1e-9)
  ann <- stats::aggregate(cbind(ocean_C, land_C) ~ yr, data = out, FUN = mean)
  ann <- ann[order(ann$yr), ]
  k   <- ann$yr[-1] >= DS_BIAS_WIN[1]
  c(land = mean(diff(ann$land_C)[k]) + DS_ELUC,
    ocean = mean(diff(ann$ocean_C)[k]))
}
g <- gcb$year >= DS_BIAS_WIN[1] & gcb$year <= DS_BIAS_WIN[2]
cat(sprintf("    GCB %d-%d observed: land %.2f  ocean %.2f  (land share %.0f %%)\n",
            DS_BIAS_WIN[1], DS_BIAS_WIN[2], mean(gcb$land_sink[g]),
            mean(gcb$ocean_sink[g]),
            100 * mean(gcb$land_sink[g]) /
              (mean(gcb$land_sink[g]) + mean(gcb$ocean_sink[g]))))
for (b in DS_BETA_GRID) {
  p <- ccx_default_params(); p$beta <- b
  out <- ds_run(p)$out
  ms  <- ccx_model_stats(out, obs)
  s   <- ds_partition(out)
  win <- function(o, m, col) {
    k <- match(o$year, m$year)
    gg <- !is.na(k) & o$year >= DS_BIAS_WIN[1] & o$year <= DS_BIAS_WIN[2]
    mean(o[[col]][gg] - m$level[k[gg]])
  }
  cat(sprintf("    beta %.2f  gross land %.2f ocean %.2f (share %2.0f %%)  d13C %+.3f  CO2 %+6.2f ppm\n",
              b, s[["land"]], s[["ocean"]],
              100 * s[["land"]] / (s[["land"]] + s[["ocean"]]),
              win(obs$d13_ann$MLO, ms$d13$MLO, "level"),
              win(obs$co2_ann$MLO, ms$co2$MLO, "level")))
}

# ---------------------------------------------------------------------
# [4] IS IT WEAK ISOTOPIC DISEQUILIBRIUM DAMPING? A declining atmospheric d13C
# is buffered by gross two-way exchange with reservoirs still carrying older,
# less depleted carbon. `ra_ratio` sets the gross land loop (Ra routed through
# the vegetation pool) and ships at 0 -- GPP = NPP ~60 GtC/yr against a real
# ~120 -- while leaving the NET carbon flux untouched. If the overshoot were
# weak damping, this is the lever that closes it for free.
#
# RESULT: it does not. Across its whole plausible range it moves the bias
# 0.10 permil, and it is not free -- D14C goes +2.7 to -14.6 permil, so 14C
# (the right constraint on gross exchange) forbids the large values anyway.
cat("\n[4] d13C BIAS vs THE GROSS LAND LOOP (ra_ratio; NET carbon flux unchanged)\n")
DS_RA_GRID <- c(0, 0.25, 0.5, 1.0, 1.5, 2.0)
for (r in DS_RA_GRID) {
  p <- ccx_default_params(); p$ra_ratio <- r
  out <- ds_run(p)$out
  ms  <- ccx_model_stats(out, obs)
  win <- function(o, m, col) {
    k <- match(o$year, m$year)
    gg <- !is.na(k) & o$year >= DS_BIAS_WIN[1] & o$year <= DS_BIAS_WIN[2]
    mean(o[[col]][gg] - m$level[k[gg]])
  }
  o14 <- obs$d14_nh_ann; k14 <- match(o14$year, ms$d14$NH$year)
  g14 <- !is.na(k14) & o14$year >= 2000
  cat(sprintf("    ra_ratio %.2f  d13C %+.3f  CO2 %+.2f ppm  D14C(NH, 2000+) %+7.2f permil\n",
              r, win(obs$d13_ann$MLO, ms$d13$MLO, "level"),
              win(obs$co2_ann$MLO, ms$co2$MLO, "level"),
              mean(o14$value[g14] - ms$d14$NH$mean[k14[g14]])))
}
