#!/usr/bin/env Rscript
# diag_zec_vs_pulse.R -- does the PRESENT EXCESS decay like a PULSE? CarboTope's half.
#
# Marcus 2026-10-15, checking Steven Schwartz's claim that "the decrease of the present excess is not exactly
# the same as the decrease of a pulse, but ... that difference is of second order because most of the excess
# CO2 is fairly new". His question: "if anthropogenic CO2 emissions were to end in 2030, what percent of the
# anthropogenic increase would remain in 2130, compared to if we add an emission pulse in 2030, what percent of
# that pulse would remain in 2130." FaIR's half is FaIRtoFrEDI/scripts/run_fair_zec_vs_pulse_for_ccx.py, with
# the SAME arms and definitions:
#   base        the van Vuuren marker, as the pulse lab runs it (app_run_coupled, APP_PULSE_EMIS_METHOD)
#   zero        fossil_GtC and luc_GtC = 0 for every year >= ZP_ZERO_YEAR; non-CO2 forcing per the marker
#   zero_pulse  zero + ZP_PULSE_GTC of fossil carbon over ZP_PULSE_YEAR
#   base_pulse  base + the same pulse (the pulse lab's own experiment)
# METRICS (global = mean of the two hemispheric boxes; GtC per ppm from R/constants.R):
#   excess remaining  (C(T1) - C_PI) / (C(T0) - C_PI); T0 = 1 Jan ZP_ZERO_YEAR, T1 = T0 + h. C at an instant is
#                     the 12-month mean CENTERED on it (the seasonal cycle cancels); C_PI = the 1750 annual mean
#                     of the base run (the spinup's periodic state).
#   pulse remaining   annual mean of d(global CO2) over year ZP_PULSE_YEAR + h, divided by the pulse in ppm
#                     (centered h years after the release-year midpoint, as FaIR's annual mean)
# GATES: G1 a zeroing that starts after the run reproduces base bit-identically; G3 every arm equals base before
# T0 to ZP_CAUSAL_TOL_PPM (see its note); G4 the emissions tables differ from base exactly where intended; G5 the
# run without the history splice equals the app's spliced run for the base arm; G6 the zeroing and the pulse both
# reach the run in their first year. No RNG. Run from the repo root:
#   Rscript calibration/diag_zec_vs_pulse.R                          (stop in 2030)
#   CCX_ZP_ZERO_YEAR=2017 Rscript calibration/diag_zec_vs_pulse.R    (Schwartz's stop year)
t_start <- Sys.time()
ROOT <- normalizePath(getwd())
stopifnot(file.exists(file.path(ROOT, "app", "global.R")))
setwd(file.path(ROOT, "app"))
invisible(capture.output(suppressMessages(suppressWarnings(
  shiny::loadSupport(getwd(), renv = globalenv(), globalrenv = globalenv())))))
setwd(ROOT)

ZP_DRIVER     <- "calibration/diag_zec_vs_pulse.R"
# The stop year (default 2030, Marcus's question). CCX_ZP_ZERO_YEAR overrides it, and the pulse moves with it, so a
# run can match another study's stop year: 2017 is Schwartz's (ACPD 2021, acp-2021-924, "hypothetical abrupt
# cessation of emissions commencing in 2017"). The year is in the output's file name.
ZP_ZERO_YEAR  <- as.integer(Sys.getenv("CCX_ZP_ZERO_YEAR", "2030"))
stopifnot(!is.na(ZP_ZERO_YEAR), ZP_ZERO_YEAR > APP_PULSE_YEARS[1], ZP_ZERO_YEAR + 100L <= APP_PULSE_YEARS[2])
ZP_PULSE_YEAR <- ZP_ZERO_YEAR
ZP_HORIZON    <- 100L
ZP_EXTRA      <- c(20L, 50L, 200L, 270L)
ZP_PULSE_GTC  <- 100                      # the pulse lab's default and FaIR's grid size
stopifnot(isTRUE(all.equal(ZP_PULSE_GTC, APP_PULSE_GtC_DEFAULT)))
ZP_NOOP_YEAR  <- APP_PULSE_YEARS[2] + 50L
GTC_PER_PPM   <- ccx_const("GtC_PER_PPM")
# G3's TOLERANCE, from two MEASUREMENTS. The coupled carbon-climate loop stops when its max |change| < CLIM_TOL
# (1e-4 K), and arms can stop after different numbers of passes, so their pre-T0 states differ by unconverged
# amounts: 2.1e-8 ppm on vvHL (base 5 passes, zero arms 4) and 5.7e-11 on vvVL at 1e-6 K. Tightening the loop makes
# them exactly 0 once the pass counts match (the test R/climate.R's own comment prescribes), so it is convergence
# noise. The one REAL acausal path this loop has had (the spline ringing, CHANGELOG 2026-09-24) left 3.48e-3 ppm.
# 1e-6 ppm sits 50x above the measured noise and 3500x below that signal; the arms run at the app's own CLIM_TOL.
ZP_TOL        <- CLIM_TOL
ZP_CAUSAL_TOL_PPM <- 1e-6
ZP_OUT_DIR    <- file.path("outputs", "diagnostics", sprintf("zec_vs_pulse_%s", format(Sys.Date(), "%Y%m%d")))
ZP_STEM       <- sprintf("ccx_%s_zec%d_vs_pulse%d_h%d", CCX_MODE_CANONICAL, ZP_ZERO_YEAR, ZP_PULSE_GTC, ZP_HORIZON)
dir.create(ZP_OUT_DIR, showWarnings = FALSE, recursive = TRUE)
commit <- ccx_git_stamp(); dirty <- ccx_stamp_dirty(commit)
sink(file.path(ZP_OUT_DIR, paste0(ZP_STEM, ".log")), split = TRUE)
cat(sprintf("%s | commit %s%s | canonical %s (%s) | %s\n", ZP_DRIVER, commit, if (isTRUE(dirty)) " (dirty)" else "",
            CCX_MODE_CANONICAL, basename(dirname(ccx_mode_file())), format(Sys.time(), "%Y-%m-%d %H:%M")))
cat(sprintf("CO2 emissions zero from %d; pulse %g GtC over %d; horizon %d yr; GtC/ppm %.4f; coupled tol %.0e K\n",
            ZP_ZERO_YEAR, ZP_PULSE_GTC, ZP_PULSE_YEAR, ZP_HORIZON, GTC_PER_PPM, ZP_TOL))

yrs <- APP_PULSE_YEARS
# THE SPLICE COMES FIRST (fixed 2026-10-16 k). app_run_coupled() replaces every year up to APP_SPLICE_YEAR with the
# observed GCB record, so a zeroing or a pulse applied BEFORE it is silently overwritten for years <= that year. A
# 2017 stop ran with emissions to 2024 and an erased pulse (quarantined: outputs/quarantine/20261016_zec2017_history_splice/).
# Each table is now spliced here, then modified, and run by run() with the splice switched off, so the table a gate
# checks is the table the model runs. For a stop after APP_SPLICE_YEAR the two orders give the same table (G5).
emis_raw <- function(bg) {
  e <- APP_SCEN_EMIS[APP_SCEN_EMIS$scenario == bg, ]; y <- seq(yrs[1], yrs[2])
  data.frame(year = y,                                       # the pulse lab's own table (server.R pulse_runs)
             fossil_GtC = stats::approx(e$year, e$fossil_GtC, xout = y, rule = 2)$y,
             luc_GtC    = stats::approx(e$year, e$luc_GtC,    xout = y, rule = 2)$y)
}
emis_for <- function(bg, zero_year = NULL, pulse = 0) {
  d <- app_splice_history(emis_raw(bg), bg); rownames(d) <- NULL
  if (!is.null(zero_year)) d[d$year >= zero_year, c("fossil_GtC", "luc_GtC")] <- 0
  d$fossil_GtC[d$year == ZP_PULSE_YEAR] <- d$fossil_GtC[d$year == ZP_PULSE_YEAR] + pulse
  d
}
# app_run_coupled() with its defaults (bomb total, LUC scale) kept in one place and only the splice removed
run_presliced <- app_run_coupled
environment(run_presliced) <- list2env(list(app_splice_history = function(em, scenario) em), parent = globalenv())
run <- function(bg, em) run_presliced(APP_SPIN, bg, yrs, bg, emissions = em, interp_method = APP_PULSE_EMIS_METHOD,
                                      tol = ZP_TOL)$out
glob <- function(o) (o$co2_NH + o$co2_SH) / 2
centred <- function(o, T) mean(glob(o)[o$t >= T - 0.5 & o$t < T + 0.5])     # 12 months centered on T
annual  <- function(o, Y) mean(glob(o)[o$t >= Y & o$t < Y + 1])

rows <- list()
for (bg in unname(APP_SCENARIOS)) {
  em_b <- emis_for(bg); em_z <- emis_for(bg, ZP_ZERO_YEAR)
  em_zp <- emis_for(bg, ZP_ZERO_YEAR, ZP_PULSE_GTC); em_bp <- emis_for(bg, pulse = ZP_PULSE_GTC)
  # G4: the tables differ from base exactly where intended
  late <- em_b$year >= ZP_ZERO_YEAR
  stopifnot(all(em_z$fossil_GtC[late] == 0), all(em_z$luc_GtC[late] == 0),
            identical(em_z[!late, ], em_b[!late, ]),
            isTRUE(all.equal(em_zp$fossil_GtC - em_z$fossil_GtC, ZP_PULSE_GTC * (em_b$year == ZP_PULSE_YEAR))),
            identical(em_zp$luc_GtC, em_z$luc_GtC),
            isTRUE(all.equal(em_bp$fossil_GtC - em_b$fossil_GtC, ZP_PULSE_GTC * (em_b$year == ZP_PULSE_YEAR))))
  b <- run(bg, em_b); z <- run(bg, em_z); zp <- run(bg, em_zp); bp <- run(bg, em_bp)
  # G1: a zeroing that starts after the run is the base, bit for bit
  stopifnot(identical(run(bg, emis_for(bg, ZP_NOOP_YEAR))$co2_NH, b$co2_NH))
  # G5: switching the splice off changes nothing else -- the base arm equals the app's own spliced run, bit for bit
  stopifnot(identical(app_run_coupled(APP_SPIN, bg, yrs, bg, emissions = emis_raw(bg), interp_method = APP_PULSE_EMIS_METHOD,
                                      tol = ZP_TOL)$out$co2_NH, b$co2_NH))
  # G6: each modification reaches the run -- the zero arm leaves base within its first year, and the pulse arm
  # leaves the zero arm (an ORDERING, no threshold; it fails on the 10-16 splice bug, where both were overwritten)
  yr0 <- b$t >= ZP_ZERO_YEAR & b$t < ZP_ZERO_YEAR + 1
  if (!(max(abs(z$co2_NH[yr0] - b$co2_NH[yr0])) > 0 && max(zp$co2_NH[yr0] - z$co2_NH[yr0]) > 0))
    stop(sprintf("G6 FAIL: %s, the zeroing or the pulse in %d did not reach the run", bg, ZP_ZERO_YEAR))
  # G3: causality -- every arm equals base before T0 (the pulse and the zeroing both start on 1 Jan T0)
  pre <- b$t < ZP_ZERO_YEAR
  g3 <- max(vapply(list(z, zp, bp), function(a) max(abs(c(a$co2_NH[pre] - b$co2_NH[pre], a$co2_SH[pre] - b$co2_SH[pre]))), 0))
  if (!(g3 <= ZP_CAUSAL_TOL_PPM)) stop(sprintf("G3 FAIL: %s arms differ from base before %d by %.2e ppm (> %.0e)", bg, ZP_ZERO_YEAR, g3, ZP_CAUSAL_TOL_PPM))
  c_pi <- annual(b, yrs[1])
  x0 <- centred(z, ZP_ZERO_YEAR) - c_pi
  for (h in c(ZP_HORIZON, ZP_EXTRA)) {
    if (ZP_PULSE_YEAR + h > yrs[2]) next
    x1 <- centred(z, ZP_ZERO_YEAR + h) - c_pi
    pz <- (annual(zp, ZP_PULSE_YEAR + h) - annual(z, ZP_PULSE_YEAR + h)) * GTC_PER_PPM / ZP_PULSE_GTC
    pb <- (annual(bp, ZP_PULSE_YEAR + h) - annual(b, ZP_PULSE_YEAR + h)) * GTC_PER_PPM / ZP_PULSE_GTC
    rows[[length(rows) + 1]] <- data.frame(scenario = bg, horizon_yr = h, c_pi_ppm = c_pi, g3_pre_t0_max_dco2_ppm = g3,
      excess_t0_ppm = x0, excess_t1_ppm = x1, excess_remaining = x1 / x0,
      pulse_remaining_zero_bg = pz, pulse_remaining_scenario_bg = pb, ratio_excess_to_pulse_zero_bg = (x1 / x0) / pz)
  }
  r <- rows[[length(rows) - length(ZP_EXTRA)]]
  cat(sprintf("  %-5s excess %.1f ppm at %d -> %.1f %% left at +%d; pulse %.1f %% (zero bg), %.1f %% (scenario bg)\n",
              bg, r$excess_t0_ppm, ZP_ZERO_YEAR, 100 * r$excess_remaining, ZP_HORIZON,
              100 * r$pulse_remaining_zero_bg, 100 * r$pulse_remaining_scenario_bg))
}
out <- do.call(rbind, rows)
out$provenance <- sprintf("%s @ %s%s; canonical %s (%s); APP_PULSE_EMIS_METHOD %s; GtC/ppm %.4f; coupled tol %.0e K; no RNG; %s",
                          ZP_DRIVER, commit, if (isTRUE(dirty)) " (dirty)" else "", CCX_MODE_CANONICAL,
                          basename(dirname(ccx_mode_file())), APP_PULSE_EMIS_METHOD, GTC_PER_PPM, ZP_TOL, format(Sys.Date()))
utils::write.csv(out, file.path(ZP_OUT_DIR, paste0(ZP_STEM, ".csv")), row.names = FALSE)
cat(sprintf("gates G1 G3 G4 G5 G6 passed; wrote %s.csv | %.1f min\n", file.path(ZP_OUT_DIR, ZP_STEM),
            as.numeric(difftime(Sys.time(), t_start, units = "mins"))))
sink()
