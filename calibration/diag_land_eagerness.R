# =====================================================================
# diag_land_eagerness.R -- WHICH KNOB MAKES THE LAND SINK LESS EAGER,
#                          AND DOES IT FIX ONE END BY BREAKING THE OTHER?
#
# The land sink misses GCB 2025 by +2.04 sd at the arm-N mode (3.38 vs
# 2.36 +/- 0.5 GtC/yr, 2015-2024). Handoff 21d sec.7 floated "a land sink that
# is too eager" as the single hypothesis that would also explain gate 12's low
# point IRF and the CO2 level swing. THIS SCRIPT IS THE TEST OF THAT
# HYPOTHESIS, AND IT IS BUILT SO THE HYPOTHESIS CAN LOSE.
#
# THE TWO-ENDED PROBLEM. diag_co2_level_swing.R TEST 2 measured the model's
# growth-rate error against the ice record and it is NOT one-signed:
#
#   1870s-1920s   model grows ~0.05-0.10 ppm/yr TOO SLOW  -> sinks too STRONG
#   1930s-1960s   model grows ~0.15-0.33 ppm/yr TOO FAST  -> sinks too WEAK
#   1970s-1980s   model grows about right
#   2015-2024     land sink +2.04 sd too STRONG
#
# So "the land sink is too eager" is at best HALF the story, and any knob that
# only scales the sink up or down moves both ends the SAME WAY. That is exactly
# what this script measures: for each lever, the modern sink AND the mid-century
# growth-rate error, side by side. A lever that improves both is a fix. A lever
# that trades them is evidence the defect is STRUCTURAL -- a wrong time
# dependence, not a wrong gain -- and no amount of refitting will find it.
#
# FROZEN, AND DELIBERATELY. Every scan holds the other 20 parameters at the
# mode. Per handoff 21c sec.2c a frozen profile is NOT a posterior statement and
# must not be read as one -- `beta_max`/`fert_k` absorb ~85 % of a q10 change
# when free. But the question here is d(sink)/d(knob), the LEVER's own size and
# sign, and for that frozen is the correct and only meaningful construction.
# The compensation is measured separately in TEST C.
#
# Usage:  Rscript calibration/diag_land_eagerness.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

LE_MODE_FILE <- ccx_mode_file()
LE_YEARS     <- c(1750, 2024)
LE_SINK_WIN  <- c(2015, 2024)     # GCB 2025 decadal mean window
LE_MID_WIN   <- c(1930, 1965)     # where the growth-rate error peaks
LE_GCB_LAND  <- 2.36; LE_GCB_LAND_SD  <- LIK_GCB_LAND_SD
LE_GCB_OCEAN <- 3.22; LE_GCB_OCEAN_SD <- LIK_GCB_OCEAN_SD

md <- readRDS(LE_MODE_FILE); pm <- md$par_mode
p0 <- ccx_default_params()
for (n in intersect(names(p0), CCX_PARAM_NAMES)) p0[[n]] <- pm[[n]]
p0$pump_mode <- md$pump_mode

ice <- as.data.frame(ccx_prepare_obs()$ice)
ice_lo <- stats::loess(CO2ppm ~ year, data = ice[ice$year >= 1850, ], span = 0.25)
LE_OBS_MID <- diff(stats::predict(ice_lo, data.frame(year = LE_MID_WIN))) / diff(LE_MID_WIN)

le_score <- function(p) {
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", LE_YEARS, prod_c14 = sp$prod_c14,
                          bomb_total_kmol = pm$bomb_total, luc_scale = pm$luc_scale)
  o  <- ccx_run_fast(sp, F)$out
  yrs <- sort(unique(floor(o$t + 1e-9))); bnd <- c(yrs, max(yrs) + 1L)
  sa <- function(v) stats::approx(o$t, v, xout = bnd, rule = 2)$y
  eluc <- ccx_forcing_eluc_annual(F)
  k <- yrs >= LE_SINK_WIN[1] & yrs <= LE_SINK_WIN[2]
  e <- eluc$eluc[match(yrs[k], eluc$year)]
  sh <- tapply(o$co2_SH, floor(o$t + 1e-9), mean)
  gr <- (sh[as.character(LE_MID_WIN[2])] - sh[as.character(LE_MID_WIN[1])]) / diff(LE_MID_WIN)
  list(land  = mean(diff(sa(o$land_C))[k] + e),
       ocean = mean(diff(sa(o$ocean_C))[k]),
       mid   = as.numeric(gr) - LE_OBS_MID,
       co2   = as.numeric(sh[as.character(2024)]))
}

base <- le_score(p0)
cat(sprintf("mode %s\n  land %.2f (%+.2f sd)  ocean %.2f (%+.2f sd)  mid-century growth err %+.3f ppm/yr  CO2(SH) 2024 %.1f\n",
            basename(LE_MODE_FILE), base$land, (base$land - LE_GCB_LAND) / LE_GCB_LAND_SD,
            base$ocean, (base$ocean - LE_GCB_OCEAN) / LE_GCB_OCEAN_SD, base$mid, base$co2))
cat(sprintf("  observed %d-%d growth from the ice: %.3f ppm/yr\n", LE_MID_WIN[1], LE_MID_WIN[2], LE_OBS_MID))
cat(sprintf("  TARGETS: land -> %.2f (needs %+.2f GtC/yr), mid-century error -> 0 (needs %+.3f)\n\n",
            LE_GCB_LAND, LE_GCB_LAND - base$land, -base$mid))

le_row <- function(lab, p) {
  r <- le_score(p)
  cat(sprintf("  %-22s %7.2f %+7.2f %8.2f %+9.3f %9.1f\n", lab, r$land,
              (r$land - LE_GCB_LAND) / LE_GCB_LAND_SD, r$ocean, r$mid, r$co2))
  invisible(r)
}
hdr <- function(t) {
  cat(sprintf("\n%s\n  %-22s %7s %7s %8s %9s %9s\n", t, "setting", "land",
              "(sd)", "ocean", "mid err", "CO2 2024"))
}

# ---- TEST A: the temperature sensitivity of respiration --------------
# q10 sits at 1.0907 -- essentially NO respiration feedback (q10^(1.3/10) = 1.011
# at today's warming). Literature is 1.5-2.0. It is low because the SEASONAL
# rows put it there through the exact ridge with seas_T_amp_NH (21c sec.2), and
# those rows move only 4.3 log-units across the whole q10 range -- so q10 is set
# by a seasonal AMPLITUDE prior, not by any annual carbon observation.
hdr("TEST A -- q10, the respiration feedback (the only NEGATIVE feedback on the land)")
for (q in c(1.0907, 1.25, 1.5, 2.0, 2.5)) {
  p <- p0; p$q10 <- q
  le_row(sprintf("q10 = %.4f%s", q, if (abs(q - pm$q10) < 1e-6) "  (mode)" else ""), p)
}

# ---- TEST B: the CO2 sensitivity of NPP -----------------------------
# 1 + beta_max * d/(fert_k + d), d = CO2 - preindustrial. At the mode
# beta_max 0.931 / fert_k 503.5, and d ~ 145 ppm today, so the model is on the
# NEAR-LINEAR limb: fert_k >> d means MM has gone linear and the asymptote is
# never approached over the historical record.
hdr("TEST B -- beta_max, the fertilisation gain")
for (b in c(0.9310, 0.75, 0.60, 0.45)) {
  p <- p0; p$beta_max <- b
  le_row(sprintf("beta_max = %.4f%s", b, if (abs(b - pm$beta_max) < 1e-4) "  (mode)" else ""), p)
}
hdr("TEST B2 -- fert_k, the half-saturation point (higher = weaker at today's CO2)")
for (k in c(503.5, 700, 1000, 2000)) {
  p <- p0; p$fert_k <- k
  le_row(sprintf("fert_k = %.0f%s", k, if (abs(k - pm$fert_k) < 1) "  (mode)" else ""), p)
}

# ---- TEST C: do the two ends MOVE TOGETHER OR TRADE? ----------------
# The decisive question. For each lever, the ratio of what it does to the
# mid-century error to what it does to the modern sink. Same sign = the lever
# trades one end for the other and cannot fix both.
cat("\nTEST C -- do the levers fix both ends, or trade them?\n")
cat(sprintf("  %-22s %12s %12s %8s\n", "lever", "d(land sink)", "d(mid err)", "verdict"))
levers <- list(
  list("q10 1.09 -> 2.0",      function(p) { p$q10 <- 2.0; p }),
  list("beta_max 0.93 -> 0.60", function(p) { p$beta_max <- 0.60; p }),
  list("fert_k 504 -> 1000",   function(p) { p$fert_k <- 1000; p }))
for (L in levers) {
  r <- le_score(L[[2]](p0))
  dl <- r$land - base$land; dm <- r$mid - base$mid
  # WANTED: dl < 0 (sink down toward GCB) AND dm < 0 (model grew too fast
  # mid-century, so its growth must come DOWN too). Both negative = a real fix.
  v <- if (dl < 0 && dm < 0) "FIXES BOTH" else if (dl < 0) "TRADES" else "WRONG WAY"
  cat(sprintf("  %-22s %+12.3f %+12.3f %8s\n", L[[1]], dl, dm, v))
}

# ---- TEST D: IS IT THE SINK AT ALL, OR IS IT THE LAND-USE INPUT? ----
# TEST C says no land PARAMETER fixes both ends, because every one of them is a
# gain on a sink and a gain moves both ends the same way. Fixing both needs
# something whose sign DIFFERS between mid-century and now. An emissions input
# is exactly that, and land-use is the least certain one in the budget:
# diag_app_params.R gate 5 measured GCB 2025 and SSP/LUH2 disagreeing by 91.4
# GtC of cumulative LUC over the same years -- a 33 % disagreement about the
# very quantity whose time profile this test needs.
#
# So: rerun the historical period with the SSP/LUH2 land-use series in place of
# GCB's, fossil untouched, everything else at the mode. This is NOT a proposal
# to switch inventories -- it is a measurement of whether the mid-century defect
# lives in the sink or in the forcing.
hdr("TEST D -- the SAME model on the OTHER land-use inventory")
le_score_luc <- function(luc_src) {
  h <- as.data.frame(readRDS(ccx_path("data", "forcing_emissions_historical.rds")))
  em <- data.frame(year = h$year, fossil_GtC = h$fossil_GtC, luc_GtC = h$luc_GtC)
  if (identical(luc_src, "ssp")) {
    sspe <- as.data.frame(readRDS(ccx_path("data", "ssp_emissions.rds")))
    sspe <- sspe[sspe$scenario == "ssp245", ]
    em$luc_GtC <- stats::approx(sspe$year, sspe$luc_GtC, xout = em$year, rule = 2)$y
  }
  sp <- ccx_spinup(p0)
  F <- ccx_build_forcing("historical", LE_YEARS, prod_c14 = sp$prod_c14,
                         emissions = em, bomb_total_kmol = pm$bomb_total,
                         luc_scale = pm$luc_scale)
  o <- ccx_run_fast(sp, F)$out
  yrs <- sort(unique(floor(o$t + 1e-9))); bnd <- c(yrs, max(yrs) + 1L)
  sa <- function(v) stats::approx(o$t, v, xout = bnd, rule = 2)$y
  eluc <- ccx_forcing_eluc_annual(F)
  k <- yrs >= LE_SINK_WIN[1] & yrs <= LE_SINK_WIN[2]
  e <- eluc$eluc[match(yrs[k], eluc$year)]
  sh <- tapply(o$co2_SH, floor(o$t + 1e-9), mean)
  list(land = mean(diff(sa(o$land_C))[k] + e),
       ocean = mean(diff(sa(o$ocean_C))[k]),
       mid = as.numeric((sh[as.character(LE_MID_WIN[2])] -
                         sh[as.character(LE_MID_WIN[1])]) / diff(LE_MID_WIN)) - LE_OBS_MID,
       co2 = as.numeric(sh[as.character(2024)]))
}
for (src in c("gcb", "ssp")) {
  r <- le_score_luc(src)
  cat(sprintf("  %-22s %7.2f %+7.2f %8.2f %+9.3f %9.1f\n",
              paste0("LUC = ", toupper(src)), r$land,
              (r$land - LE_GCB_LAND) / LE_GCB_LAND_SD, r$ocean, r$mid, r$co2))
}
rg <- le_score_luc("gcb"); rs <- le_score_luc("ssp")
vd <- if (rs$land - rg$land < 0 && rs$mid - rg$mid < 0) "FIXES BOTH" else
      if (rs$land - rg$land < 0 || rs$mid - rg$mid < 0) "TRADES" else "WRONG WAY"
cat(sprintf("  %-22s %+12.3f %+12.3f %8s\n", "GCB -> SSP/LUH2 LUC",
            rs$land - rg$land, rs$mid - rg$mid, vd))
cat("\n  (the gross land sink is reconstructed with the MODEL'S OWN E_LUC, so the two\n")
cat("   rows are not scored against the same GCB residual-sink definition -- read the\n")
cat("   MID-CENTURY column, which is a pure CO2-vs-ice comparison and is definition-free.\n")
cat("   And note CO2 2024 falls to 409.2: the SSP series is not a drop-in replacement,\n")
cat("   it is a measurement of how much of the mid-century defect the LUC TIME PROFILE\n")
cat("   can carry.)\n")

# ---- TEST E: IS IT A GAIN PROBLEM, OR A PARTITION PROBLEM? ----------
# TEST C killed "the land sink is too eager" as a single-knob fix, and
# diag_gamma_iav.R then killed the constraint that would have pinned q10. Read
# the mode's three misses TOGETHER rather than one at a time:
#
#   land sink   +2.04 sd  TOO STRONG
#   ocean sink  -0.62 sd  TOO WEAK
#   CO2 level   ~+5 ppm   TOO HIGH (laundered by rep_dC, diag_rep_dC_shape.R)
#
# TOTAL uptake is roughly right and the PARTITION is wrong. That reframes the
# whole thing: a knob that scales land uptake down raises CO2 (TEST B: +20 to
# +25 ppm), because the carbon the land stops taking goes into the air. But a
# knob that moves uptake FROM the land TO the ocean fixes all three at once --
# ocean up, CO2 down, and land down TWICE (directly, and again because lower CO2
# means less fertilization).
#
# WANTED, and registered before the numbers: d(land) < 0 AND d(ocean) > 0 AND
# d(CO2) < 0. A lever that does all three is a partition lever and is what the
# mode actually needs. If none does, the defect is not in the ocean parameters.
hdr("TEST E -- the OCEAN levers, scored on the PARTITION not on one sink")
le_ocean <- function(lab, mod) {
  p <- mod(p0); r <- le_score(p)
  cat(sprintf("  %-22s %7.2f %+7.2f %8.2f %+9.3f %9.1f\n", lab, r$land,
              (r$land - LE_GCB_LAND) / LE_GCB_LAND_SD, r$ocean, r$mid, r$co2))
  invisible(r)
}
le_ocean("mode", function(p) p)
for (v in c(95, 105, 120)) le_ocean(sprintf("h_ml = %d", v), function(p) { p$h_ml <- v; p })
for (v in c(8000, 12000, 20000)) le_ocean(sprintf("kz = %d", v), function(p) { p$kz <- v; p })
for (v in c(3000, 4000)) le_ocean(sprintf("k_w = %d", v), function(p) { p$k_w <- v; p })
for (v in c(400, 550)) le_ocean(sprintf("pump_grad = %d", v), function(p) { p$pump_grad <- v; p })

cat("\nTEST E VERDICT -- which levers move the PARTITION the right way?\n")
cat(sprintf("  %-22s %10s %10s %10s %10s\n", "lever", "d(land)", "d(ocean)", "d(CO2)", "verdict"))
ocean_levers <- list(
  list("h_ml 87.6 -> 120",   function(p) { p$h_ml <- 120; p }),
  list("kz 6461 -> 20000",   function(p) { p$kz <- 20000; p }),
  list("k_w 2024 -> 4000",   function(p) { p$k_w <- 4000; p }),
  list("pump_grad 298 -> 550", function(p) { p$pump_grad <- 550; p }),
  list("q10 1.09 -> 2.0",    function(p) { p$q10 <- 2.0; p }))
for (L in ocean_levers) {
  r <- le_score(L[[2]](p0))
  dl <- r$land - base$land; do_ <- r$ocean - base$ocean; dc <- r$co2 - base$co2
  v <- if (dl < 0 && do_ > 0 && dc < 0) "PARTITION" else
       if (dl < 0 && do_ > 0) "part(CO2 up)" else "no"
  cat(sprintf("  %-22s %+10.3f %+10.3f %+10.2f %10s\n", L[[1]], dl, do_, dc, v))
}
