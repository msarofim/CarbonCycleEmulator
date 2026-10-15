# =====================================================================
# diag_pedagogy.R -- the model scored against the two arguments it was built to
# refute. HEADLINE: THE MODEL PRODUCES THE SKEPTIC'S OWN "5-YEAR RESIDENCE
# TIME" NUMBER (4.3 yr) AND, IN THE SAME RUN, SHOWS 26 % OF A MASS PULSE STILL
# AIRBORNE AFTER A CENTURY.
#
# WRITTEN 2026-08-13 for notes/expertpanel_2026-08-13_structure_for_pedagogy.md,
# which treats Marcus' stated motivation -- "'5 year CO2 residence time' and
# 'CO2 concentrations correlate with temperature'" -- as a DESIGN SPEC and asks
# what structure it demands. Everything the panel note quotes is computed here.
#
# [1] TURNOVER IS NOT ADJUSTMENT, AND THE MODEL SEPARATES THEM EXACTLY. From
#     one spinup, one parameter set, two paired perturbations: a MASS pulse
#     (100 GtC at the atmosphere's own isotope ratios) and a pure 14C LABEL
#     pulse (+10 % atmospheric 14C, no mass).
#
#       yr        mass airborne     label remaining
#        1           0.893              0.811
#       10           0.604              0.292
#      100           0.262              0.058     <-- 4.5x apart
#      300           0.171              0.029
#
#     Label 1/e = 7.13 yr; mass 1/e = 40.3 yr.
#
#     THE TURNOVER TIME ITSELF IS NOW READ OFF THE FLUX TRACE (R/fluxes.R,
#     added 2026-08-13d), not off the label slope: tau_turn = M_atm / (gross
#     flux out) = 4.69 yr at 1750, rising to 5.32 by 2024 as the atmosphere
#     fills faster than the gross fluxes grow. THAT IS THE QUOTED "5-YEAR
#     RESIDENCE TIME", COMPUTED CORRECTLY -- the right answer to the wrong
#     question.
#
#     A ONE-MONTH LABEL SLOPE IS *NOT* A CLEAN ESTIMATOR OF IT, and this
#     supersedes the 4.32 yr this file reported on 2026-08-13. Seasonal NEP is a
#     real atm->leaf flux that integrates to zero annually, so it is excluded
#     from atm_out -- correctly for the annual mean, wrongly for a January
#     finite difference, which the January seasonal drawdown then biases FAST.
#     Tested, not assumed (test-fluxes.R): with seasonality off the label slope
#     gives 4.700 against the trace's 4.692, agreeing to 0.2 %; with it on the
#     same slope reads 4.32. Part 1b prints both.
#
# [2] THE OCEAN-STRUCTURE DEBATE IS NEARLY IRRELEVANT TO THIS. Conveyor C at
#     20 Sv with kz 2000 moves AF@100 from 0.262 to 0.284. Choosing a 2024
#     background instead of preindustrial moves it further, to 0.298 -- i.e.
#     A CONTROL THE APP ALREADY EXPOSES OUTWEIGHS THE WHOLE CONVEYOR QUESTION.
#     Decide the conveyor on oceanography; it is not blocking the app.
#
# [3] TEMPERATURE -> CO2 IS REAL, RIGHT-SIGNED, AND AN ORDER OF MAGNITUDE TOO
#     SMALL. +1 K held with ZERO emissions: +5.19 ppm @10 yr, +10.74 @300 yr.
#     Against the model's own 1.20 K of 1960-2023 warming that is 12.9 of the
#     102.5 ppm rise -- 13 %.
#
# [4] AND THE ISOTOPES DECIDE IT BY SIGN. Splitting the +1 K response at 300 yr:
#       solubility only (ocean outgassing)  +4.43 ppm   d13C +0.0354 permil  UP
#       respiration only (land release)     +6.24 ppm   d13C -0.0760
#       both                               +10.74 ppm   d13C -0.0410
#       observed/model 1960-2023          +102.5  ppm   d13C -1.773
#     "THE WARM OCEAN IS OUTGASSING IT" PREDICTS d13C RISING. It falls, by
#     1.77 permil. Even the land limb, which has the right sign, is 43x small.
#     NOTE the ocean's NET change under the full +1 K run is -0.04 GtC at
#     300 yr, which looks like a suspicious zero. It is a CROSSING, not an
#     identity: solubility-only gives -23.50 and respiration-only +23.50 at
#     300 yr, but -15.1 and +9.5 at 100 yr. Tested, part 4b.
#
# [5] THE MODEL REPRODUCES THE SKEPTIC'S HEADLINE STATISTIC. cor(CO2 growth
#     rate, GMST) = +0.930 over 1960-2023 while 100 % of its trend is
#     emissions-driven. Detrend both and r = 0.582 -- the genuine ENSO link,
#     which explains wobbles, not the rise. Co-trending manufactures the rest.
#
# RUNTIME ~3 s. All at ccx_default_params(), NOT the posterior mode; the mode
# has h_ml 179 m and kz 6031, both of which push toward more ocean uptake and a
# shorter adjustment time, so THESE CURVES MUST BE RECOMPUTED AT THE MODE
# BEFORE ANYTHING SHIPS.
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

# ---- labels derive from constants (project rule) --------------------
PED_Y0        <- 1750
PED_Y1        <- 2050          # 300 yr of quiet run for the decay experiments
PED_HIST      <- c(1750, 2024)
PED_CORR_WIN  <- c(1959, 2023) # annual means; growth rate needs the lead year
PED_PULSE     <- 100           # GtC, mass pulse
PED_LABEL     <- 0.10          # fraction of atmospheric 14C, label pulse
PED_DT        <- 1             # K, the held temperature anomaly
PED_HORIZONS  <- c(1, 2, 5, 10, 20, 50, 100, 200, 300)
PED_CONV      <- list(q = 20, kz = 2000, sink = 8L, desc = 0L)  # handoff 13c's cell
PED_GCB_OCEAN <- 3.22          # GtC/yr, GCB 2025 2015-2024 mean (DESIGN sec.6 gate 7)

GPP_HEMI <- ccx_const("GtC_PER_PPM") / 2

# ---------------------------------------------------------------------
# A quiet forcing: no emissions, no bomb, no nuclear, no ENSO, T at its
# preindustrial value. Paired perturbation-minus-control throughout, per the
# standing paired-pulse discipline -- the control is NOT assumed flat.
# ---------------------------------------------------------------------
ped_quiet_forcing <- function(spin) {
  F <- suppressWarnings(ccx_build_forcing("historical", c(PED_Y0, PED_Y1),
                                          prod_c14 = spin$prod_c14,
                                          bomb_total_kmol = 0))
  for (cc in c("e_foss_NH", "e_foss_SH", "e_luc_NH", "e_luc_SH", "enso",
               "c14_bomb", "c14_nuclear")) F[[cc]] <- 0
  F$gmst <- 0
  F
}

ped_atm <- function(spin) c(spin$aux$idx$NH$atm, spin$aux$idx$SH$atm)

#' Decay curves for both perturbations, from one state and one parameter set
ped_curves <- function(p, from_2024 = FALSE) {
  spin <- ccx_spinup(p)
  Fq   <- ped_quiet_forcing(spin)
  if (from_2024) {
    Fh <- ccx_build_forcing("historical", PED_HIST, prod_c14 = spin$prod_c14)
    spin$y <- ccx_run_fast(spin, Fh)$state
  }
  ctl <- ccx_run_fast(spin, Fq)$out
  ii  <- ped_atm(spin); iN <- ii[1]; iS <- ii[2]

  # MASS pulse: added at the atmosphere's OWN isotope ratios, so it perturbs the
  # amount and not simultaneously the label. Split by the hemispheres' existing
  # share so the pulse does not also perturb the interhemispheric gradient.
  sp <- spin
  fN <- spin$y[iN, "C"] / (spin$y[iN, "C"] + spin$y[iS, "C"])
  for (k in ii) {
    add <- PED_PULSE * if (k == iN) fN else 1 - fN
    r13 <- spin$y[k, "C13"] / spin$y[k, "C"]
    r14 <- spin$y[k, "C14"] / spin$y[k, "C"]
    sp$y[k, "C"]   <- sp$y[k, "C"]   + add
    sp$y[k, "C13"] <- sp$y[k, "C13"] + add * r13
    sp$y[k, "C14"] <- sp$y[k, "C14"] + add * r14
  }
  mp <- ccx_run_fast(sp, Fq)$out
  af <- ((mp$co2_NH - ctl$co2_NH) + (mp$co2_SH - ctl$co2_SH)) * GPP_HEMI / PED_PULSE

  # LABEL pulse: 14C only, no mass. Its decay is the TURNOVER time -- and it is
  # how the turnover time is recovered at all, because ccx_run() emits no gross
  # fluxes (the panel note's recommendation R1).
  sl <- spin
  for (k in ii) sl$y[k, "C14"] <- sl$y[k, "C14"] * (1 + PED_LABEL)
  lp  <- ccx_run_fast(sl, Fq)$out
  lab <- ((lp$d14c_NH - ctl$d14c_NH) + (lp$d14c_SH - ctl$d14c_SH)) / 2
  lab <- lab / lab[1]

  list(yrs = ctl$t - ctl$t[1], af = af, lab = lab, ctl = ctl, spin = spin)
}

at <- function(cv, v, y) v[which.min(abs(cv$yrs - y))]
efold <- function(cv, v) stats::approx(v, cv$yrs, xout = exp(-1))$y

# =====================================================================
# 1. TURNOVER vs ADJUSTMENT
# =====================================================================
p0 <- ccx_default_params()
cv <- ped_curves(p0)
# The flux trace is read off the FULL HISTORICAL forcing, so both ends of the
# industrial period are visible: the turnover time is not a constant, it LENGTHENS
# as the atmosphere fills faster than the gross fluxes grow.
Fh_all <- ccx_build_forcing("historical", PED_HIST, prod_c14 = cv$spin$prod_c14)
cat(sprintf("\n[control] drift over %d yr: CO2 %+.4f ppm, d14C %+.4f permil\n",
            PED_Y1 - PED_Y0,
            tail(cv$ctl$co2_NH, 1) - cv$ctl$co2_NH[1],
            tail(cv$ctl$d14c_NH, 1) - cv$ctl$d14c_NH[1]))

cat("\n=== 1. TURNOVER vs ADJUSTMENT (one state, one parameter set) ===\n")
cat(sprintf("%6s  %14s  %16s\n", "yr", "mass airborne", "label remaining"))
for (y in PED_HORIZONS)
  cat(sprintf("%6.0f  %14.4f  %16.4f\n", y, at(cv, cv$af, y), at(cv, cv$lab, y)))
cat(sprintf("  1/e crossing: label %.2f yr, mass %.1f yr; ratio at 100 yr = %.1fx\n",
            efold(cv, cv$lab), efold(cv, cv$af),
            at(cv, cv$af, 100) / at(cv, cv$lab, 100)))

# ---- 1b. THE TURNOVER TIME, from the flux trace (the authoritative route) ----
# tau_turn = M_atm / (gross flux out of the atmosphere), computed inside the
# model by R/fluxes.R rather than inferred from a decay slope.
flx <- ccx_flux_annual(ccx_run(cv$spin, Fh_all, fluxes = TRUE)$fluxes)
cat("\n=== 1b. TURNOVER TIME FROM THE FLUX TRACE ===\n")
cat(sprintf("  1750: gross out %.1f GtC/yr -> tau_turn %.2f yr   <-- THE \"5-YEAR\" NUMBER\n",
            flx$atm_out[1], flx$tau_turn[1]))
k <- nrow(flx)
cat(sprintf("  %d: gross out %.1f GtC/yr -> tau_turn %.2f yr\n",
            flx$year[k], flx$atm_out[k], flx$tau_turn[k]))
cat(sprintf("  photosynthesis %.1f + air-to-sea %.1f GtC/yr, against fossil emissions %.1f\n",
            flx$gpp[k], flx$as_down[k], flx$foss[k]))
cat("  A ONE-MONTH LABEL SLOPE IS NOT THIS NUMBER: seasonal NEP is excluded from\n")
cat(sprintf("  atm_out (it integrates to zero annually), so a January launch reads %.2f yr.\n",
            -(1 / 12) / log(cv$lab[2] / cv$lab[1])))
cat("  test-fluxes.R pins both: seasonality off, the two routes agree to 0.2 %.\n")

# =====================================================================
# 2. HOW MUCH OF THIS DOES THE OCEAN-STRUCTURE DEBATE MOVE?
# =====================================================================
pc <- p0
pc$q_conv <- PED_CONV$q; pc$kz <- PED_CONV$kz
pc$conv_sink <- PED_CONV$sink; pc$conv_descent <- PED_CONV$desc
cases <- list("preindustrial, no conveyor"      = cv,
              "preindustrial, conveyor C"       = ped_curves(pc),
              "2024 background, no conveyor"    = ped_curves(p0, from_2024 = TRUE))
cat("\n=== 2. SENSITIVITY OF THE PEDAGOGICAL CURVES TO STRUCTURE ===\n")
cat(sprintf("%-30s %7s %7s %8s %7s | %9s\n",
            "case", "AF@20", "AF@50", "AF@100", "AF@300", "label 1/e"))
for (nm in names(cases)) {
  c1 <- cases[[nm]]
  cat(sprintf("%-30s %7.3f %7.3f %8.3f %7.3f | %9.2f\n", nm,
              at(c1, c1$af, 20), at(c1, c1$af, 50), at(c1, c1$af, 100),
              at(c1, c1$af, 300), efold(c1, c1$lab)))
}
cat("  the background (an existing app control) outweighs the conveyor question.\n")

# =====================================================================
# 3. TEMPERATURE -> CO2, and 4. ITS ISOTOPIC SIGNATURE
# =====================================================================
ped_warm <- function(q10, sst, dT = PED_DT) {
  p2 <- p0; p2$q10 <- q10; p2$sst_scale <- sst
  s2 <- ccx_spinup(p2); Fq <- ped_quiet_forcing(s2)
  c2 <- ccx_run_fast(s2, Fq)$out
  Ft <- Fq; Ft$gmst <- dT
  w  <- ccx_run_fast(s2, Ft)$out
  yrs <- c2$t - c2$t[1]
  g <- function(v, y) v[which.min(abs(yrs - y))]
  list(dco2 = function(y) g((w$co2_NH - c2$co2_NH + w$co2_SH - c2$co2_SH) / 2, y),
       dd13 = function(y) g((w$d13c_NH - c2$d13c_NH + w$d13c_SH - c2$d13c_SH) / 2, y),
       dd14 = function(y) g((w$d14c_NH - c2$d14c_NH + w$d14c_SH - c2$d14c_SH) / 2, y),
       docn = function(y) g(w$ocean_C - c2$ocean_C, y),
       dlnd = function(y) g(w$land_C  - c2$land_C,  y))
}
full <- ped_warm(p0$q10, p0$sst_scale)
cat(sprintf("\n=== 3. +%.0f K HELD, ZERO EMISSIONS ===\n", PED_DT))
cat(sprintf("%6s %10s %10s %10s %10s\n", "yr", "dCO2 ppm", "dd13C", "dD14C", "land GtC"))
for (y in c(10, 50, 100, 200, 300))
  cat(sprintf("%6.0f %10.2f %+10.3f %+10.2f %+10.1f\n", y,
              full$dco2(y), full$dd13(y), full$dd14(y), full$dlnd(y)))

sol <- ped_warm(1, p0$sst_scale)     # solubility only
res <- ped_warm(p0$q10, 0)           # respiration only
cat("\n=== 4. THE ISOTOPIC SIGNATURE DECIDES IT, BY SIGN (300 yr) ===\n")
cat(sprintf("%-34s %10s %12s\n", "limb", "dCO2 ppm", "dd13C"))
cat(sprintf("%-34s %10.2f %+12.4f  <-- RISES\n",
            "solubility only (ocean outgassing)", sol$dco2(300), sol$dd13(300)))
cat(sprintf("%-34s %10.2f %+12.4f\n",
            "respiration only (land release)", res$dco2(300), res$dd13(300)))
cat(sprintf("%-34s %10.2f %+12.4f\n", "both", full$dco2(300), full$dd13(300)))
cat("\n  4b. the ocean's near-zero NET change is a CROSSING, not an identity:\n")
cat(sprintf("      %-24s %9s %9s\n", "ocean dC, GtC", "@100 yr", "@300 yr"))
for (nm in c("solubility only", "respiration only", "both")) {
  o <- switch(nm, "solubility only" = sol, "respiration only" = res, full)
  cat(sprintf("      %-24s %+9.2f %+9.2f\n", nm, o$docn(100), o$docn(300)))
}

# =====================================================================
# 5. THE SKEPTIC'S HEADLINE STATISTIC, REPRODUCED
# =====================================================================
spin <- cv$spin
Fh <- ccx_build_forcing("historical", PED_HIST, prod_c14 = spin$prod_c14)
h  <- ccx_run_fast(spin, Fh)$out
ann <- aggregate(cbind(co2, d13) ~ year,
                 data.frame(year = floor(h$t),
                            co2  = (h$co2_NH + h$co2_SH) / 2,
                            d13  = (h$d13c_NH + h$d13c_SH) / 2), mean)
g <- as.data.frame(readRDS(ccx_path("data", "forcing_gmst.rds")))
ann <- merge(ann, g, by = "year")
ann <- ann[ann$year >= PED_CORR_WIN[1] & ann$year <= PED_CORR_WIN[2], ]
ann$growth <- c(NA, diff(ann$co2))
z <- ann[!is.na(ann$growth), ]
detr <- function(x, y) stats::residuals(stats::lm(x ~ y + I(y^2) + I(y^3)))
cat(sprintf("\n=== 5. INTERANNUAL vs SECULAR, model historical run %d-%d ===\n",
            min(z$year), max(z$year)))
cat(sprintf("  cor( CO2 GROWTH RATE  , GMST )          r = %+.3f  <-- the quoted statistic\n",
            stats::cor(z$growth, z$gmst_anom)))
cat(sprintf("  cor( CO2 level        , GMST )          r = %+.3f\n",
            stats::cor(z$co2, z$gmst_anom)))
cat(sprintf("  cor( DETRENDED growth , detrended GMST ) r = %+.3f  <-- the real, ENSO-mediated link\n",
            stats::cor(detr(z$growth, z$year), detr(z$gmst_anom, z$year))))
dT_obs <- tail(z$gmst_anom, 1) - z$gmst_anom[1]
dC_obs <- tail(z$co2, 1) - z$co2[1]
cat(sprintf("  model CO2 %.1f -> %.1f ppm (+%.1f); GMST %.2f -> %.2f K (+%.2f)\n",
            z$co2[1], tail(z$co2, 1), dC_obs,
            z$gmst_anom[1], tail(z$gmst_anom, 1), dT_obs))
cat(sprintf("  T-driven share at %.2f ppm/K: %.1f ppm = %.0f %% of the rise\n",
            full$dco2(300) / PED_DT, full$dco2(300) / PED_DT * dT_obs,
            100 * full$dco2(300) / PED_DT * dT_obs / dC_obs))
cat(sprintf("  model d13C %.3f -> %.3f permil (%+.3f); the T-driven signal is %.0fx smaller\n",
            z$d13[1], tail(z$d13, 1), tail(z$d13, 1) - z$d13[1],
            abs((tail(z$d13, 1) - z$d13[1]) / full$dd13(300))))

# =====================================================================
# 6. THE OCEAN IS A NET SINK -- the direct refutation
# =====================================================================
n  <- nrow(h); k1 <- which.min(abs(h$t - 2015))
cat("\n=== 6. BUDGET CLOSURE AND THE OCEAN'S SIGN ===\n")
d_atm <- ((h$co2_NH[n] + h$co2_SH[n]) - (h$co2_NH[1] + h$co2_SH[1])) / 2 *
         ccx_const("GtC_PER_PPM")
d_ocn <- h$ocean_C[n] - h$ocean_C[1]
d_lnd <- h$land_C[n]  - h$land_C[1]
cum_f <- sum(Fh$e_foss_NH + Fh$e_foss_SH) / 12
cat(sprintf("  1750-2024 cumulative: atm %+.1f  ocean %+.1f  land %+.1f  = %.1f GtC\n",
            d_atm, d_ocn, d_lnd, d_atm + d_ocn + d_lnd))
cat(sprintf("  cumulative FOSSIL emissions %.1f GtC -> closes to %.2f %%\n",
            cum_f, 100 * abs(d_atm + d_ocn + d_lnd - cum_f) / cum_f))
cat("  (LUC is a veg->atm TRANSFER, not an external source, so it correctly\n")
cat("   does not appear in the total -- see memory project_ccx_luc_c14_leak.)\n")
cat(sprintf("  ocean uptake 2015-2024: %+.2f GtC/yr against GCB's %.2f (%.0f %% low)\n",
            (h$ocean_C[n] - h$ocean_C[k1]) / (h$t[n] - h$t[k1]), PED_GCB_OCEAN,
            100 * (1 - ((h$ocean_C[n] - h$ocean_C[k1]) / (h$t[n] - h$t[k1])) / PED_GCB_OCEAN)))
cat("  A RESERVOIR GAINING CARBON IS NOT THE ONE SUPPLYING THE ATMOSPHERE.\n")

# =====================================================================
# 7. THE UNDECLARED PRE-1850 LUC BACK-FILL (panel note recommendation R3)
# =====================================================================
raw <- as.data.frame(readRDS(ccx_path("data", "forcing_emissions_historical.rds")))
raw <- raw[raw$year <= PED_HIST[2], ]
na_yrs <- range(raw$year[is.na(raw$luc_GtC)])
cum_luc_forcing <- sum(Fh$e_luc_NH + Fh$e_luc_SH) / 12
cum_luc_source  <- sum(raw$luc_GtC, na.rm = TRUE)
cat("\n=== 7. PRE-1850 LUC IS EXTRAPOLATED, SILENTLY ===\n")
cat(sprintf("  GCB LUC is NA for %d-%d (%d yr). ccx_annual_to_monthly()'s rule=2\n",
            na_yrs[1], na_yrs[2], na_yrs[2] - na_yrs[1] + 1))
cat(sprintf("  holds the %d value flat backwards, inventing %.1f GtC.\n",
            na_yrs[2] + 1, cum_luc_forcing - cum_luc_source))
cat(sprintf("  forcing carries %.1f GtC of LUC against %.1f in the source: %.0f %% is extrapolation.\n",
            cum_luc_forcing, cum_luc_source,
            100 * (cum_luc_forcing - cum_luc_source) / cum_luc_forcing))
cat("  NOT a conservation error, and a nonzero pre-1850 flux is defensible --\n")
cat("  the objection is that nobody CHOSE it. GMST's identical flat-hold warns\n")
cat("  on every build (forcing.R); d13c_foss's carries a justifying comment.\n")
cat("  FLAGGED AS A METHODOLOGICAL CHOICE FOR MARCUS, not resolved here.\n")
