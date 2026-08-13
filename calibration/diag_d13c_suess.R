# =====================================================================
# diag_d13c_suess.R -- the model's 13C Suess decline is too steep, and the
# fossil source d13C is the lever that owns it.
#
# FOUND 2026-08-12 while pricing handoff 12d sec.0 step 1. The d13C residual is
# not scatter and it is not a constant offset: obs - model grows monotonically
# from ~0 permil in 1850 to +0.58 by 2020 at MLO (+0.43 at SPO), with only
# 0.07 permil of year-to-year scatter around it. The model reproduces the SHAPE
# of the Suess decline and overshoots its MAGNITUDE by ~30 %.
#
# Why it matters beyond d13C itself: a too-depleted atmosphere is relieved by a
# LARGER land sink (photosynthesis discriminates against 13C), so the d13C term
# pushes q10 DOWN -- it is a contributor to the q10 inversion, not a cure for it.
# diag_q10_stream_direction.R measures that direction.
#
# [1] residual structure in time, against Law Dome (pre-1980) and Scripps.
# [2] sensitivity of the 2015-2024 bias to each PROVISIONAL 13C constant in
#     ccx_prepare(), with the CO2 bias carried alongside so a "fix" that moves
#     the carbon budget is visible.
#
# RESULT of [2]: d13c_foss owns the bias almost entirely. -28 -> -24 permil
# takes MLO from +0.577 to +0.048 and SPO from +0.425 to -0.052, while the CO2
# bias does not move at all (+2.33 ppm throughout). The three fractionation
# factors move it only 0.014-0.035 permil per permil -- an order of magnitude
# weaker. So this is a d13C-only lever, orthogonal to the carbon budget.
#
# TWO CONCRETE DEFECTS IN d13c_foss = -28, both pushing the same way:
#   (a) `fossil_GtC` is GCB's fossil-fuel-AND-INDUSTRY column, which INCLUDES
#       cement. Cement carbon comes from limestone at d13C ~ 0 permil, not from
#       fuel at -28, and it is ~4-5 % of the total.
#   (b) the value is CONSTANT over 1750-2024, but the fuel mix is not: coal
#       (~-24 permil) dominated early and gas (~-44) is a modern addition, so a
#       single modern-mix value applied to the whole industrial period
#       over-depletes cumulatively -- which is exactly the growing-residual
#       signature [1] shows.
# Neither is settled here; this diagnostic prices them. See CHANGELOG.
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

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

ds_run <- function(p) {
  s <- ccx_spinup(p)
  F <- base_forcing; F$c14_cosmo <- s$prod_c14
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

ds_bias <- function(mods = list(), label = "") {
  assign("ccx_prepare", function(p, ...) {
    a <- ds_prepare_orig(p, ...)
    for (n in names(mods)) a[[n]] <- mods[[n]]
    a
  }, envir = globalenv())
  on.exit(assign("ccx_prepare", ds_prepare_orig, envir = globalenv()))
  ms <- ccx_model_stats(ds_run(ccx_default_params())$out, obs)
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
cat("\n  -- fossil source d13c_foss --\n")
for (d in DS_FOSS_GRID)
  ds_bias(list(d13c_foss = d), sprintf("d13c_foss     = %d permil", d))
