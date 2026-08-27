# =====================================================================
# diag_app_params.R -- WHAT DOES THE APP ACTUALLY SHIP, AND WHAT WOULD IT SHIP?
#
# `app/global.R` resolves its parameter vector from
# `calibration/output/mode_fit.rds`. THAT FILE DOES NOT EXIST. The adopted mode
# is `calibration/output/pump_arms/mode_fit_pumpN.rds`, so the app has been
# falling through to `ccx_default_params()` and drawing every panel with
# uncalibrated starting values while its own banner says so in small type.
#
# This measures the difference before the fix is written, because the fix is
# NOT a one-line path change. Six of the 21 fitted parameters are not model
# parameters at all:
#
#   bomb_total, luc_scale        -- FORCING parameters. `ccx_make_logpost()`
#                                   applies them by rescaling the bomb-14C
#                                   column and the four LUC columns. The app
#                                   builds its own forcing and would silently
#                                   drop both.
#   sigma_d14c, rep_dC,          -- LIKELIHOOD parameters. They score the
#   grad_off_co2, grad_off_d13c     model against observations; they do not
#                                   move a trajectory. The app has no
#                                   likelihood, so dropping them cannot change
#                                   a curve.
#
# ***BUT `rep_dC` IS NOT INERT FOR THE APP, BECAUSE THE APP DRAWS THE SAME
# COMPARISON THE LIKELIHOOD SCORES.*** R/likelihood.R:1098 predicts the station
# as `model_box_CO2 - rep_dC`; the fitted value is 5.18 ppm. `plot_keeling()`
# plots the model's NH and SH BOXES against the MLO and SPO STATIONS with no
# offset at all. So the calibrated model is EXPECTED to sit ~5 ppm above Mauna
# Loa on that panel, by construction, and the app has no way to say so. Scored
# below as STATION alongside the raw BOX, because which one is "the model
# reproduces the record" is a presentation decision for Marcus, not a bug.
#
# `global.R`'s existing loop is `intersect(names(p), names(pm))`, which drops
# all six WITHOUT WARNING -- and two of them change the curve the app draws.
# So there are three candidate resolutions, not two, and this scores all three:
#
#   DEFAULTS  what ships today
#   PAR-ONLY  the path fix alone: par_mode into p, forcing left at luc_scale 1
#   FULL      par_mode into p AND bomb_total/luc_scale into the forcing
#
# The scoring quantities are the ones a visitor to the app can check: the CO2
# level the Keeling tab claims the model reproduces from emissions alone, and
# the two sink strengths tab 2 is named after, against GCB 2025.
#
# Usage:  Rscript calibration/diag_app_params.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

AP_MODE_FILE <- ccx_mode_file()
AP_YEARS     <- c(1750, 2024)          # = APP_HIST_YEARS in app/global.R
AP_OBS_YEAR  <- 2024                   # the year the app's takeaway line reads
AP_SINK_WIN  <- c(2015, 2024)          # GCB decadal-mean window, GCB 2025 Table 6
AP_BOMB_REF  <- 102                    # = BOMB_REF in ccx_make_logpost()
# GCB 2025 2015-2024 means and stated 1 sigma, as carried by R/likelihood.R
# (LIK_GCB_OCEAN_SD / LIK_GCB_LAND_SD) and R/model.R:481.
AP_GCB_LAND  <- 2.36; AP_GCB_LAND_SD  <- LIK_GCB_LAND_SD
AP_GCB_OCEAN <- 3.22; AP_GCB_OCEAN_SD <- LIK_GCB_OCEAN_SD

md <- readRDS(AP_MODE_FILE)
pm <- md$par_mode
cat(sprintf("mode file : %s\n  pump_mode %s   logpost %.2f   %d params\n",
            basename(AP_MODE_FILE), md$pump_mode, md$logpost, length(md$param_names)))

# ---- GATE 1: the 21-name guard in app_params() ----------------------
# It was written to reject a stale 18-parameter fit. If it rejects the arm file
# the path fix is inert and the app keeps shipping defaults with no error.
cat(sprintf("GATE 1: identical(md$param_names, CCX_PARAM_NAMES) = %s\n",
            identical(md$param_names, CCX_PARAM_NAMES)))

# ---- GATE 2: which fitted parameters does `p` not have a slot for? ---
p0   <- ccx_default_params()
in_p <- intersect(names(p0), CCX_PARAM_NAMES)
not_p <- setdiff(CCX_PARAM_NAMES, names(p0))
cat(sprintf("GATE 2: %d of %d fitted parameters are model parameters; %d are not:\n  %s\n",
            length(in_p), length(CCX_PARAM_NAMES), length(not_p),
            paste(not_p, collapse = ", ")))

# ---- GATE 3: pump_mode is STRUCTURAL and is not in par_mode ----------
# ccx_default_params() must already be the adopted arm, or the app would run
# arm-N parameters through arm-D structure.
cat(sprintf("GATE 3: default pump_mode '%s' vs mode file '%s' -> %s\n",
            p0$pump_mode, md$pump_mode,
            if (identical(p0$pump_mode, md$pump_mode)) "MATCH" else "MISMATCH, must be set"))

# ---------------------------------------------------------------------
# The three resolutions
# ---------------------------------------------------------------------
ap_params <- function(kind) {
  p <- ccx_default_params()
  if (identical(kind, "DEFAULTS")) {
    p$gamma_enso <- CCX_PARAM_TABLE$gamma_enso$init   # what global.R does today
    return(p)
  }
  for (n in in_p) p[[n]] <- pm[[n]]
  p$pump_mode <- md$pump_mode
  p
}

ap_run <- function(kind) {
  p  <- ap_params(kind)
  sp <- ccx_spinup(p)
  full <- identical(kind, "FULL")
  F <- ccx_build_forcing("historical", AP_YEARS, prod_c14 = sp$prod_c14,
                         bomb_total_kmol = if (full) pm$bomb_total else AP_BOMB_REF,
                         luc_scale       = if (full) pm$luc_scale  else 1)
  r <- ccx_run_fast(sp, F)
  r$out$co2_global <- (r$out$co2_NH + r$out$co2_SH) / 2
  list(p = p, sp = sp, F = F, out = r$out)
}

# Calendar-year sink fluxes, the SAME construction the likelihood scores
# (stock interpolated to year boundaries and differenced, gross land = model
# land uptake + the model's OWN E_LUC), so these numbers are comparable to the
# gcb_land_sink / gcb_ocean_sink terms rather than merely similar to them.
ap_sinks <- function(o, F) {
  yrs <- sort(unique(floor(o$t + 1e-9))); bnd <- c(yrs, max(yrs) + 1L)
  stock_at <- function(v) stats::approx(o$t, v, xout = bnd, rule = 2)$y
  eluc <- ccx_forcing_eluc_annual(F)
  k <- yrs >= AP_SINK_WIN[1] & yrs <= AP_SINK_WIN[2]
  e <- eluc$eluc[match(yrs[k], eluc$year)]
  list(ocean = mean(diff(stock_at(o$ocean_C))[k]),
       land  = mean(diff(stock_at(o$land_C))[k] + e))
}

AP_OBS <- ccx_prepare_obs()
# Compared as ANNUAL MEANS of the last complete year, not last-month values:
# the seasonal cycle is ~6 ppm peak-to-peak at MLO, so a point-in-time
# comparison is dominated by phase and would move with the month the run ends.
ap_annual <- function(t, v, yr) mean(v[floor(t + 1e-9) == yr])
ap_obs_stn <- function(stn, yr) {
  o <- AP_OBS$co2[AP_OBS$co2$station == stn, ]
  mean(o$co2_ppm[floor(o$decimal_date + 1e-9) == yr])
}
AP_MLO <- ap_obs_stn("MLO", AP_OBS_YEAR)
AP_SPO <- ap_obs_stn("SPO", AP_OBS_YEAR)

cat(sprintf("\nobserved %d annual means: MLO %.1f ppm   SPO %.1f ppm\n",
            AP_OBS_YEAR, AP_MLO, AP_SPO))
cat(sprintf("GCB 2025 %d-%d: land %.2f +/- %.2f   ocean %.2f +/- %.2f GtC/yr\n",
            AP_SINK_WIN[1], AP_SINK_WIN[2], AP_GCB_LAND, AP_GCB_LAND_SD,
            AP_GCB_OCEAN, AP_GCB_OCEAN_SD))
cat(sprintf("station prediction = model box - rep_dC, rep_dC = %.2f ppm (0 for DEFAULTS)\n\n",
            pm$rep_dC))

cat(sprintf("%-9s %8s %8s %8s %8s %7s %7s %7s %7s\n", "resolution",
            "NHbox", "NH-MLO", "NHstn", "stn-MLO", "land", "(sig)", "ocean", "(sig)"))
res <- list()
for (kind in c("DEFAULTS", "PAR-ONLY", "FULL")) {
  r <- ap_run(kind); o <- r$out
  nh <- ap_annual(o$t, o$co2_NH, AP_OBS_YEAR)
  sh <- ap_annual(o$t, o$co2_SH, AP_OBS_YEAR)
  rep <- if (identical(kind, "DEFAULTS")) 0 else pm$rep_dC
  s <- ap_sinks(o, r$F)
  res[[kind]] <- list(nh = nh, sh = sh, stn = nh - rep, land = s$land,
                      ocean = s$ocean, run = r)
  cat(sprintf("%-9s %8.1f %+8.1f %8.1f %+8.1f %7.2f %+7.2f %7.2f %+7.2f\n", kind,
              nh, nh - AP_MLO, nh - rep, nh - rep - AP_MLO,
              s$land,  (s$land  - AP_GCB_LAND)  / AP_GCB_LAND_SD,
              s$ocean, (s$ocean - AP_GCB_OCEAN) / AP_GCB_OCEAN_SD))
}

cat(sprintf("\nSH box vs SPO:  DEFAULTS %+.1f   PAR-ONLY %+.1f   FULL %+.1f ppm (box, no offset)\n",
            res$DEFAULTS$sh - AP_SPO, res$`PAR-ONLY`$sh - AP_SPO, res$FULL$sh - AP_SPO))

cat(sprintf("\nPAR-ONLY -> FULL, the cost of dropping the two forcing parameters:\n"))
cat(sprintf("  luc_scale  %.4f   bomb_total %.2f kmol (ref %.0f)\n",
            pm$luc_scale, pm$bomb_total, AP_BOMB_REF))
cat(sprintf("  NH box @%d %+.2f ppm\n  land sink %+.3f GtC/yr\n  ocean sink %+.3f GtC/yr\n",
            AP_OBS_YEAR, res$FULL$nh - res$`PAR-ONLY`$nh,
            res$FULL$land - res$`PAR-ONLY`$land,
            res$FULL$ocean - res$`PAR-ONLY`$ocean))

# ---- GATE 4: 14C, which is the only place bomb_total shows -----------
d14 <- vapply(res, function(x) max(x$run$out$d14c_NH), numeric(1))
cat(sprintf("\nGATE 4: peak Delta14C(NH)  DEFAULTS %.0f  PAR-ONLY %.0f  FULL %.0f permil\n",
            d14[["DEFAULTS"]], d14[["PAR-ONLY"]], d14[["FULL"]]))

# ---- GATE 5: DO THE APP'S OWN TABS AGREE WITH EACH OTHER? ------------
# Tab 1 (Keeling) runs scenario "historical" -> data/forcing_emissions_historical.rds,
# the GCB 2025 budget. Tab 5 (Futures) runs ccx_run_coupled() on an SSP ->
# data/ssp_emissions.rds, whose historical segment is the SSP/LUH2 harmonisation.
# They are DIFFERENT INVENTORIES over the same years, and the app draws both as
# "the model". This is independent of every parameter above -- it is an
# emissions-data question -- but it lands on the same CO2 axis a visitor reads,
# so it belongs in the same report.
ap_emis_gap <- local({
  h <- as.data.frame(readRDS(file.path("data", "forcing_emissions_historical.rds")))
  s <- as.data.frame(readRDS(file.path("data", "ssp_emissions.rds")))
  s <- s[s$scenario == "ssp245", ]
  yy <- intersect(h$year, s$year); yy <- yy[yy <= AP_OBS_YEAR]
  hh <- h[match(yy, h$year), ]; ss <- s[match(yy, s$year), ]
  list(yy = yy,
       foss = sum(ss$fossil_GtC) - sum(hh$fossil_GtC),
       luc  = sum(ss$luc_GtC)    - sum(hh$luc_GtC),
       h_luc = sum(hh$luc_GtC), s_luc = sum(ss$luc_GtC))
})
cat(sprintf("\nGATE 5: the two emissions inventories the app draws, %d-%d cumulative\n",
            min(ap_emis_gap$yy), max(ap_emis_gap$yy)))
cat(sprintf("  ssp245 minus historical:  fossil %+.1f GtC   LUC %+.1f GtC (%.1f vs %.1f)\n",
            ap_emis_gap$foss, ap_emis_gap$luc, ap_emis_gap$s_luc, ap_emis_gap$h_luc))
cat(sprintf("  total %+.1f GtC = %+.1f ppm if fully airborne\n",
            ap_emis_gap$foss + ap_emis_gap$luc,
            (ap_emis_gap$foss + ap_emis_gap$luc) / ccx_const("GtC_PER_PPM")))

# Measured rather than inferred: run the coupled path the futures tab runs and
# read the same year off both.
ap_full <- res$FULL$run
ap_cpl <- ccx_run_coupled(ap_full$sp, "ssp245", c(1750, 2100),
                          bomb_total_kmol = pm$bomb_total, luc_scale = pm$luc_scale)
ap_h <- ap_annual(ap_full$out$t, (ap_full$out$co2_NH + ap_full$out$co2_SH) / 2, AP_OBS_YEAR)
ap_f <- ap_cpl$climate$co2_ppm[ap_cpl$climate$year == AP_OBS_YEAR]
cat(sprintf("  MEASURED at %d: tab 1 (historical) %.1f ppm   tab 5 (ssp245) %.1f ppm   gap %+.1f ppm\n",
            AP_OBS_YEAR, ap_h, ap_f, ap_f - ap_h))
cat(sprintf("  ssp245 @2100 therefore carries the same deficit: %.1f ppm\n",
            ap_cpl$climate$co2_ppm[nrow(ap_cpl$climate)]))
