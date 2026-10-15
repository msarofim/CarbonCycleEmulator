# =====================================================================
# diag_d13c_levers.R -- is there ANY lever that closes the d13C Suess overshoot
# without breaking CO2 or Delta14C?
#
# diag_d13c_suess.R established that the model over-depletes atmospheric d13C by
# ~0.55 permil at 2015-2024 and closed four candidates: the fossil source
# signature (fixed, worth 3 %), the three fractionation constants (0.014-0.035
# permil per permil), the reachable sink partition (needs a 72 % land share
# against GCB's 42 %, at +40 ppm of CO2), and the gross land loop `ra_ratio`
# (0.10 permil across its range, and 14C forbids the large values).
#
# This scans the two families that were left. Both change the ISOTOPIC
# DISEQUILIBRIUM -- the buffering a declining atmosphere gets from two-way
# exchange with reservoirs still carrying older, less depleted carbon -- rather
# than the fractionation or the net fluxes:
#
#   OCEAN    k_w, h_ml, kz. How much gross air-sea exchange there is, how big
#            the surface reservoir it exchanges with is, and how fast the
#            depleted signal is buried out of contact.
#   LAND LAG tau_wood, tau_soil_slow, litter_slow_frac, npp_veg_frac. NOT the
#            gross magnitude (that was ra_ratio) but the AGE of the carbon
#            coming back: a land whose return flux is too young carries too
#            little disequilibrium regardless of how large it is.
#
# One at a time from ccx_default_params(). Every row carries the CO2 bias, the
# Delta14C bias and the land-sink share alongside, because a lever that closes
# d13C by breaking those has not closed anything -- that is the whole lesson of
# the beta scan in diag_d13c_suess.R [3].
#
# THE LAND LAYOUT IS FROZEN AS STRUCTURE (Marcus, 2026-08-12, handoff 12d sec.5).
# Its rows here are diagnostic: they say whether the layout is implicated, not
# whether to calibrate it.
#
# ---------------------------------------------------------------------
# RESULT (2026-08-13): k_w IS THE LEVER, AND IT WANTS AN UNPHYSICAL VALUE.
#
#   k_w    d13C bias   CO2 bias   D14C bias   land share
#   1500     +0.548     +2.33       +2.65        46 %      <- default
#   2500     +0.259     +3.63       +4.59        46 %
#   4000     +0.075     +4.38       +1.52        45 %
#   6000     -0.034     +4.81       -1.62        45 %
#
# k_w ~4000 m/yr closes the d13C bias almost entirely for ~2 ppm of CO2, with
# Delta14C and the sink partition essentially untouched -- the first lever found
# that is not paid for somewhere else. Nothing else comes close: h_ml moves the
# bias 0.085 permil across 30-200 m, and every LAND LAG knob that helps costs
# 15-50 permil of Delta14C (tau_wood 150 -> +43.8; litter_slow_frac 0.5 -> +51.5).
#
# But 1500 m/yr IS the Wanninkhof global-mean CO2 transfer velocity (DESIGN.md
# line 102; ~16.5 cm/hr = 1450 m/yr), which is why the prior is centered there.
# 4000 is 2.7x that, +2.45 sigma. It is not available as a physical value.
#
# WHAT THAT MEANS -- and it is the same gap 14C already found. The model needs
# more air-sea gross exchange than a real piston velocity delivers because its
# ocean cannot MAINTAIN the isotopic disequilibrium. The real ocean does it by
# circulation: upwelling continually presents water last in contact with a
# pre-industrial atmosphere, so the return flux stays isotopically old. A
# pure-diffusion column has no upwelling -- it smears the Suess signal downward
# and the water at the surface has already been partly loaded, so the return flux
# is too depleted and the atmosphere over-depletes. Raising k_w fakes it by
# talking faster to a reservoir that is too equilibrated; raising kz fakes it by
# burying the signal, and costs +13 ppm and +22 permil Delta14C at kz 10000.
#
# Handoff 12d sec.2 closed the 14C budget with the residual "atmosphere short /
# ocean long => VENTILATION". This is that same missing term, seen in the other
# isotope. DESIGN.md sec.2 rejected HILDA as "too many parameters to
# communicate" and 12d sec.10 lists ocean advection among the items deliberately
# dropped -- so this is a KNOWN, CHOSEN limitation now given its price in permil,
# not a new defect.
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

# ---- labels derive from constants (project rule) --------------------
DL_YEARS     <- c(1750, 2024)
DL_BOMB_REF  <- 102
DL_BIAS_WIN  <- c(2015, 2024)    # d13C / CO2 / sink-share window
DL_D14C_WIN  <- c(2000, 2019)    # Delta14C window (Hua ends 2019)
DL_TARGET    <- 0.0              # every bias is stated against zero

DL_GRIDS <- list(
  k_w              = c(500, 1000, 1500, 2500, 4000, 6000),
  h_ml             = c(30, 50, 75, 120, 178, 200),
  kz               = c(1000, 3830, 5000, 6200, 10000),
  tau_wood         = c(10, 20, 40, 80, 150),
  tau_soil_slow    = c(100, 250, 500, 1000, 2000),
  litter_slow_frac = c(0.01, 0.05, 0.15, 0.30, 0.50),
  npp_veg_frac     = c(0, 0.25, 0.5, 0.75, 1.0)
)
DL_FAMILY <- c(k_w = "OCEAN", h_ml = "OCEAN", kz = "OCEAN",
               tau_wood = "LAND LAG", tau_soil_slow = "LAND LAG",
               litter_slow_frac = "LAND LAG", npp_veg_frac = "LAND LAG")

obs <- ccx_prepare_obs()
gcb <- as.data.frame(obs$gcb)
base_forcing <- ccx_build_forcing("historical", DL_YEARS, prod_c14 = 0,
                                  bomb_total_kmol = DL_BOMB_REF)

dl_metrics <- function(p) {
  s <- ccx_spinup(p)
  F <- base_forcing; F$c14_cosmo <- s$prod_c14
  out <- ccx_run_fast(s, F)$out
  if (anyNA(out$co2_NH)) return(NULL)
  ms <- ccx_model_stats(out, obs)
  lev <- function(o, m, col) {
    k <- match(o$year, m$year)
    g <- !is.na(k) & o$year >= DL_BIAS_WIN[1] & o$year <= DL_BIAS_WIN[2]
    mean(o[[col]][g] - m$level[k[g]])
  }
  o14 <- obs$d14_nh_ann; k14 <- match(o14$year, ms$d14$NH$year)
  g14 <- !is.na(k14) & o14$year >= DL_D14C_WIN[1] & o14$year <= DL_D14C_WIN[2]
  yr  <- floor(out$t + 1e-9)
  ann <- stats::aggregate(cbind(ocean_C, land_C) ~ yr, data = out, FUN = mean)
  ann <- ann[order(ann$yr), ]
  kk  <- ann$yr[-1] >= DL_BIAS_WIN[1]
  ld  <- mean(diff(ann$land_C)[kk]); oc <- mean(diff(ann$ocean_C)[kk])
  c(d13c = lev(obs$d13_ann$MLO, ms$d13$MLO, "level"),
    co2  = lev(obs$co2_ann$MLO, ms$co2$MLO, "level"),
    d14c = mean(o14$value[g14] - ms$d14$NH$mean[k14[g14]]),
    land = ld, ocean = oc, land_share = 100 * ld / (ld + oc))
}

g <- gcb$year >= DL_BIAS_WIN[1] & gcb$year <= DL_BIAS_WIN[2]
GCB_SHARE <- 100 * mean(gcb$land_sink[g]) /
  (mean(gcb$land_sink[g]) + mean(gcb$ocean_sink[g]))
cat(sprintf("biases are obs - model, %d-%d (D14C %d-%d); target %.1f\n",
            DL_BIAS_WIN[1], DL_BIAS_WIN[2], DL_D14C_WIN[1], DL_D14C_WIN[2],
            DL_TARGET))
cat(sprintf("GCB %d-%d land share %.0f %% (land %.2f, ocean %.2f GtC/yr)\n\n",
            DL_BIAS_WIN[1], DL_BIAS_WIN[2], GCB_SHARE,
            mean(gcb$land_sink[g]), mean(gcb$ocean_sink[g])))

p0 <- ccx_default_params()
m0 <- dl_metrics(p0)
cat(sprintf("%-9s %8s | %8s %9s %10s | %6s %6s %7s\n",
            "parameter", "value", "d13C", "CO2 ppm", "D14C pm",
            "land", "ocean", "share%"))
cat(strrep("-", 78), "\n")
cat(sprintf("%-9s %8s | %+8.3f %+9.2f %+10.2f | %6.2f %6.2f %6.0f%%   <- DEFAULTS\n",
            "", "", m0[["d13c"]], m0[["co2"]], m0[["d14c"]],
            m0[["land"]], m0[["ocean"]], m0[["land_share"]]))

for (nm in names(DL_GRIDS)) {
  cat(sprintf("\n-- %s: %s --\n", nm, DL_FAMILY[[nm]]))
  for (v in DL_GRIDS[[nm]]) {
    p <- p0; p[[nm]] <- v
    m <- dl_metrics(p)
    if (is.null(m)) { cat(sprintf("%-9s %8g | run failed (NA)\n", nm, v)); next }
    cat(sprintf("%-9s %8g | %+8.3f %+9.2f %+10.2f | %6.2f %6.2f %6.0f%%%s\n",
                nm, v, m[["d13c"]], m[["co2"]], m[["d14c"]],
                m[["land"]], m[["ocean"]], m[["land_share"]],
                if (isTRUE(all.equal(v, p0[[nm]]))) "   <- default" else ""))
  }
}
