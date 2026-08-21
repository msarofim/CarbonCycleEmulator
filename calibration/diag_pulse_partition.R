# =====================================================================
# diag_pulse_partition.R -- WHERE DOES A CO2 PULSE END UP, AND WHEN?
#
# A FEASIBILITY PROTOTYPE for the app panel Marcus specified 2026-08-21: a
# perturbation curve over time on top, a reservoir-partition bar chart
# underneath, dense to 2100 and then point estimates at 2200, 2300, ... 3000.
#
# It is a diagnostic, not the panel. What it is FOR is answering the three
# questions the panel cannot be built without:
#   1. does the partition CLOSE? (the fractions must sum to 1, or the bar chart
#      is lying) -- and over 975 years the integrator's own quadrature is a real
#      candidate for not closing;
#   2. is the answer RIGHT? (checked against the Joos et al. 2013 multi-model
#      IRF, which is DESIGN sec.6 gate 12's benchmark);
#   3. is it FAST enough to run live in Shiny?
#
# THE PARTITION IS OF THE PULSE, NOT OF THE STOCK. Every number below is a
# PAIRED difference, pulse-run minus baseline-run, which is the only way to ask
# where the added carbon went: the reservoirs are all moving anyway under the
# background scenario, and a single run cannot separate the two.
#
# ***`deep_C_{NH,SH}` IS THE BOTTOM BOX, NOT THE OCEAN INTERIOR.*** R/model.R:48
# says so -- those columns exist for the DIC and d13C GRADIENT likelihood terms,
# which need one deep box as a time series, and `deep_C_NH` carries
# `y[obox$NH["deep"], "C"]`, one of TEN interior layers. Summing ml + deep as if
# it were the ocean accounts for 31 % of `ocean_C` and loses 69 % of it. The
# first version of this script did that and reported the pulse partition failing
# to close by 32 %.
#
# THE SPLIT THAT WORKS TODAY, with no model change: the interior is the
# REMAINDER, `ocean_C - (ml_C_NH + ml_C_SH)`. So
#   atmosphere    = mean(co2_NH, co2_SH) x GtC_PER_PPM
#   land          = land_C
#   surface ocean = ml_C_NH + ml_C_SH
#   deep ocean    = ocean_C - surface ocean
# and the four close on `ocean_C` and `land_C` by construction rather than by
# hoping a subset adds up.
#
# WHAT IS STILL MISSING for the panel Marcus specified: `land_C` is
# leaf + wood + soil_fast + soil_slow AGGREGATED, so a vegetation-vs-soil bar --
# the more interesting one, because the two have very different timescales --
# needs those pools exposed as output columns. The state vector has them;
# `ccx_run_fast()` does not return them. That is a column, not a mechanism.
#
# Usage:  Rscript calibration/diag_pulse_partition.R [pulse_GtC] [pulse_year]
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

PP_ARGS  <- commandArgs(TRUE)
PP_GTC   <- if (length(PP_ARGS) >= 1) as.numeric(PP_ARGS[1]) else 100
PP_YEAR  <- if (length(PP_ARGS) >= 2) as.numeric(PP_ARGS[2]) else 2030
PP_BG    <- "ssp245"          # background scenario; the pulse is added ON TOP
PP_END   <- 3000
PP_DENSE <- 2100              # annual to here, then decadal points
PP_POINTS <- seq(2200, PP_END, by = 100)
PP_GTC_PER_PPM <- ccx_const("GtC_PER_PPM")
# Joos et al. 2013 Table 5 multi-model IRF FIT, as recorded in DESIGN sec.6
# gate 12 (doi:10.5194/acp-13-2793-2013). EVALUATED, not typed: the first
# version of this file typed recalled values and got 50 yr and 100 yr wrong by
# 0.05-0.06 (0.44/0.35 against the correct 0.487/0.409), which is the same size
# as the model-vs-benchmark difference it was being used to judge.
PP_JOOS_A0  <- 0.2173
PP_JOOS_A   <- c(0.2240, 0.2824, 0.2763)
PP_JOOS_TAU <- c(394.4, 36.54, 4.304)
ccx_joos_irf <- function(t)
  PP_JOOS_A0 + sum(PP_JOOS_A * exp(-t / PP_JOOS_TAU))
PP_HORIZONS <- c(20, 50, 100, 300, 500, 1000)

sep <- function(s) cat(sprintf("\n%s\n%s\n", s, strrep("-", nchar(s))))

# ---------------------------------------------------------------------
# The paired runs
# ---------------------------------------------------------------------
sp <- ccx_spinup(ccx_default_params())
raw <- as.data.frame(readRDS(ccx_path("data", "ssp_emissions.rds")))
raw <- raw[raw$scenario == PP_BG, c("year", "fossil_GtC", "luc_GtC")]
# ***THE SSP TABLE IS DECADAL PAST 2020.*** It must be put on an ANNUAL grid
# BEFORE the pulse is added, or "add 100 GtC to the year 2030 row" adds 100
# GtC/yr to a decadal knot and ccx_annual_to_monthly() then ramps through it for
# twenty years -- delivering about TEN TIMES the pulse, smeared. The first
# version of this script did exactly that and reported 242 ppm of atmospheric
# perturbation from a 100 GtC pulse, which is 5x what 100 GtC can produce even
# if NONE of it is taken up. app/server.R already does this interpolation and is
# not affected; a diagnostic reading the table directly is.
yy  <- seq(1750, PP_END)
em  <- data.frame(
  year       = yy,
  fossil_GtC = stats::approx(raw$year, raw$fossil_GtC, xout = yy, rule = 2)$y,
  luc_GtC    = stats::approx(raw$year, raw$luc_GtC,    xout = yy, rule = 2)$y)
# The table stops at 2500 and every SSP is at ZERO there, so rule = 2's flat
# hold to 3000 extends zero. Asserted rather than assumed.
stopifnot(max(raw$year) >= 2500,
          raw$fossil_GtC[raw$year == max(raw$year)] == 0,
          raw$luc_GtC[raw$year == max(raw$year)] == 0,
          em$fossil_GtC[em$year == PP_END] == 0)
em_pulse <- em
# Released over a single year, so the pulse size IS the number asked for.
em_pulse$fossil_GtC[em_pulse$year == PP_YEAR] <-
  em_pulse$fossil_GtC[em_pulse$year == PP_YEAR] + PP_GTC
# GATE: the two emission series differ by EXACTLY the pulse, in exactly one year.
.d <- em_pulse$fossil_GtC - em$fossil_GtC
stopifnot(sum(.d != 0) == 1L, abs(sum(.d) - PP_GTC) < 1e-9,
          identical(em_pulse$luc_GtC, em$luc_GtC))

t0 <- Sys.time()
run <- function(e) suppressWarnings(
  ccx_run_coupled(sp, PP_BG, c(1750, PP_END), emissions = e))
base <- run(em); pulse <- run(em_pulse)
PP_SECS <- as.numeric(Sys.time() - t0, units = "secs")

# ---------------------------------------------------------------------
# The partition, as a paired difference
# ---------------------------------------------------------------------
part <- function(o) {
  atm <- (o$out$co2_NH + o$out$co2_SH) / 2 * PP_GTC_PER_PPM
  ml  <- o$out$ml_C_NH + o$out$ml_C_SH
  data.frame(t = o$out$t, atmosphere = atm, land = o$out$land_C,
             surface_ocean = ml,
             # the INTERIOR as a remainder -- see the header on deep_C_*
             deep_ocean = o$out$ocean_C - ml)
}
b <- part(base); p <- part(pulse)
stopifnot(identical(b$t, p$t))
RES <- c("atmosphere", "land", "surface_ocean", "deep_ocean")
D <- as.data.frame(lapply(RES, function(k) p[[k]] - b[[k]]))
names(D) <- RES
D$t <- b$t
D$total <- rowSums(D[RES])

at <- function(yr) which.min(abs(D$t - (yr + 0.5)))

# ---------------------------------------------------------------------
# 1. DOES IT CLOSE?
# ---------------------------------------------------------------------
sep("1. CONSERVATION -- do the four reservoirs account for the whole pulse?")
cat(sprintf("pulse %.0f GtC released in %d on a %s background; run to %d\n",
            PP_GTC, PP_YEAR, PP_BG, PP_END))
cat(sprintf("%6s %12s %12s %10s\n", "year", "sum (GtC)", "pulse (GtC)", "leak"))
for (yr in c(PP_YEAR + 1, 2050, 2100, 2200, 2500, PP_END)) {
  i <- at(yr)
  cat(sprintf("%6d %12.4f %12.4f %9.3f%%\n",
              yr, D$total[i], PP_GTC, 100 * (D$total[i] - PP_GTC) / PP_GTC))
}
cat("\nA drifting `leak` is the integrator's quadrature, not physics -- the\n")
cat("system is closed once emissions stop. It is the number that decides\n")
cat("whether the bar chart can be drawn as fractions of the pulse.\n")

# ---------------------------------------------------------------------
# 2. IS IT RIGHT?
# ---------------------------------------------------------------------
sep("2. AGAINST THE JOOS ET AL. 2013 MULTI-MODEL IRF (DESIGN sec.6 gate 12)")
cat(sprintf("%8s %14s %14s %10s\n", "yr after", "this model", "Joos T5 fit", "diff"))
for (h in PP_HORIZONS) {
  i <- at(PP_YEAR + h)
  f <- D$atmosphere[i] / PP_GTC
  j <- ccx_joos_irf(h)
  cat(sprintf("%8.0f %14.3f %14.3f %+10.3f\n", h, f, j, f - j))
}
cat("\n*** THIS IS NOT GATE 12 AND MUST NOT BE READ AS IT. *** Joos's PD100\n")
cat("protocol puts 100 GtC onto a background HELD at 389 ppm; this run puts it\n")
cat(sprintf("onto %s at %d, which is neither held nor at 389. DESIGN sec.6 gate 12\n",
            PP_BG, PP_YEAR))
cat("prices the protocol difference at 2 yr of integrated IRF for held-vs-decaying\n")
cat("and 7 yr for PI-vs-PD -- larger than most of the differences above. The gate\n")
cat("itself is calibration/diag_joos_irf.R and it runs the right protocol.\n")
cat("\nWhat this table IS good for is the SHAPE: the model sheds carbon from the\n")
cat("atmosphere FASTER than Joos beyond ~300 yr, and section 3 shows where it\n")
cat("goes -- which is the thing gate 12 does not score, because an airborne\n")
cat("fraction says nothing about WHICH sink took the rest.\n")

# ---------------------------------------------------------------------
# 3. THE PANEL'S OWN NUMBERS
# ---------------------------------------------------------------------
sep("3. THE PARTITION, AS THE BAR CHART WOULD SHOW IT (fraction of pulse)")
cat(sprintf("%6s %11s %11s %14s %12s %10s\n", "year", "atmosphere", "land",
            "surface ocean", "deep ocean", "ppm left"))
for (yr in c(PP_YEAR + 1, 2040, 2050, 2075, PP_DENSE, PP_POINTS)) {
  i <- at(yr)
  cat(sprintf("%6d %11.3f %11.3f %14.3f %12.3f %10.3f\n", yr,
              D$atmosphere[i] / PP_GTC, D$land[i] / PP_GTC,
              D$surface_ocean[i] / PP_GTC, D$deep_ocean[i] / PP_GTC,
              D$atmosphere[i] / PP_GTC_PER_PPM))
}

sep("4. FEASIBILITY")
cat(sprintf("two coupled runs, 1750-%d: %.2f s total\n", PP_END, PP_SECS))
cat(sprintf("dense annual points to %d, then %s\n", PP_DENSE,
            paste(PP_POINTS, collapse = ", ")))
cat("\nWHAT THE PANEL STILL NEEDS FROM THE MODEL:\n")
cat("  * `land_C` is leaf + wood + soil_fast + soil_slow AGGREGATED. A\n")
cat("    vegetation-vs-soil bar needs those four exposed as output columns.\n")
cat("    The state vector has them; ccx_run_fast() does not return them.\n")
cat("  * do NOT reach for `deep_C_{NH,SH}` for this -- it is the BOTTOM BOX,\n")
cat("    one interior layer of ten, and exists for the gradient terms.\n")
