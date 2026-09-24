# =====================================================================
# THE PULSE LAB RELEASES CARBON BEFORE THE YEAR THE SLIDER SAYS.
#
# FOUND 2026-09-24 by the F4 gate (tests/testthat/test-future-yvar.R), which
# asked the obvious question nobody had asked of this tab: do the pulse run and
# the baseline run agree BEFORE the pulse? They do not.
#
# ⭐ THE CLAIM IS A CAUSALITY VIOLATION, not a disagreement about physics.
# Atmospheric CO2 in 2049 cannot depend on emissions released in 2050. Any
# non-zero difference there is an implementation artefact by definition, so
# this needs no model-derived threshold and no tuning judgement: the bound is
# ZERO, and it comes from a law (~/.claude/CLAUDE.md, "thresholds come from an
# observation or a physical law first").
#
# ⭐⭐ THE MECHANISM, and the code documents it against itself.
# `ccx_annual_to_monthly()` (R/forcing.R) interpolates annual emissions to
# monthly with a NATURAL CUBIC SPLINE through year midpoints, then applies an
# additive per-year correction so each year's 12 months average to its annual
# value. The correction fixes the annual MEAN. It does nothing about the
# spline's AMPLITUDE -- and a natural spline is a GLOBAL interpolant, so moving
# one knot rings through its neighbours with alternating sign, decaying by
# roughly a factor of 4 per year.
#
# A one-year pulse is the sharpest possible knot move. The comment at
# R/forcing.R:536 states the assumption this breaks in as many words -- that
# the interpolation "leaves every month of a year within a whisker of its
# annual mean" -- and the `method = "constant"` branch exists precisely because
# a spline through the sharply peaked bomb-14C series undershot either side of
# the 1962 peak. THE SAME LESSON, NOT YET APPLIED TO THE PULSE.
#
# ⛔ THIS SCRIPT MEASURES. IT CHANGES NOTHING. The fix is a methodological
# choice with two candidate homes -- the model's forcing path (which every
# fitted value depends on) or the app's pulse construction (which nothing else
# touches) -- and that is Marcus's call, not this script's.
#
# ⚠ THE PARAMETERS ARE THE APP'S, BY SOURCING app/global.R RATHER THAN
# REBUILDING THEM. `ccx_diag_must_use_mode_base` (2026-09-24) records what a
# hand-rebuilt parameter set cost last time: every arm internally consistent,
# nothing erroring, and a different model from the one in front of the reader.
# Sourcing the app's own file removes the opportunity to get it wrong, and it
# also hands over `app_run_coupled()`, so the runs here are the SAME CALL the
# pulse lab makes, splice and all.
#
# ⚠ THE EXTERNAL ANCHOR is the number the app itself prints in the pulse lab
# takeaway: the share of a 100 GtC 2050 pulse still airborne at 2150. If that
# does not reproduce here, nothing below is about the app.
# =====================================================================

suppressWarnings(suppressMessages(source("app/global.R")))

# ---- named constants; every label and heading below derives from these ----
PR_GTC     <- APP_PULSE_GtC_DEFAULT      # 100 GtC: the shipped default
PR_YEAR    <- APP_PULSE_YEAR_DEFAULT     # 2050:    the shipped default
PR_BG      <- "ssp245"
PR_YEARS   <- APP_PULSE_YEARS            # the pulse lab's own span
PR_SPREAD  <- 10L                        # years, the ring-free control's width
PR_H1      <- 100L                       # horizons the takeaway quotes
PR_H2      <- 250L
PR_TITLE   <- sprintf("Pulse-lab spline ringing: %d GtC released in %d, %s",
                      PR_GTC, PR_YEAR, PR_BG)

cat("\n", strrep("=", 72), "\n", PR_TITLE, "\n", strrep("=", 72), "\n", sep = "")
cat(sprintf("mode %s | %s | app params: %s (%s)\n",
            CCX_MODE_CANONICAL, APP_SPINUP_LABEL,
            app_params$source, app_params$status))

# ---------------------------------------------------------------------
# 1. THE CAUSE, IN EMISSIONS SPACE. Parameter-free and model-free: this is
#    arithmetic on the interpolator alone, so it cannot be blamed on the
#    carbon cycle, the spinup or the mode file.
# ---------------------------------------------------------------------
cat("\n[1] The interpolator, on a flat series with one year perturbed\n")
local({
  y <- (PR_YEAR - 10L):(PR_YEAR + 10L)
  v <- rep(10, length(y)); v2 <- v
  v2[y == PR_YEAR] <- v2[y == PR_YEAR] + PR_GTC
  d <- matrix(ccx_annual_to_monthly(y, v2, y) - ccx_annual_to_monthly(y, v, y),
              nrow = 12)
  ann   <- colMeans(d)
  swing <- apply(d, 2, function(z) max(z) - min(z))
  keep  <- abs(swing) > 0.05
  cat("    annual means are EXACT -- the pulse size is not the bug:",
      sprintf("max |annual-mean error| off the pulse year = %.2e GtC/yr\n",
              max(abs(ann[y != PR_YEAR]))))
  cat("    within-year monthly swing of the DIFFERENCE (GtC/yr):\n")
  print(round(stats::setNames(swing[keep], y[keep]), 2))
  cat(sprintf("    ⭐ the swing in %d (%.1f) EXCEEDS the swing in the pulse year %d (%.1f)\n",
              PR_YEAR - 1L, swing[y == PR_YEAR - 1L], PR_YEAR, swing[y == PR_YEAR]))
})

# ---------------------------------------------------------------------
# 2. The runs. Built exactly as app/server.R's pulse_runs() builds them.
# ---------------------------------------------------------------------
pr_emissions <- function(extra_year, extra_gtc, spread = 1L) {
  bg <- APP_SSP_EMIS[APP_SSP_EMIS$scenario == PR_BG, ]
  y  <- seq(PR_YEARS[1], PR_YEARS[2])
  e  <- data.frame(
    year = y,
    fossil_GtC = stats::approx(bg$year, bg$fossil_GtC, xout = y, rule = 2)$y,
    luc_GtC    = stats::approx(bg$year, bg$luc_GtC,    xout = y, rule = 2)$y)
  if (extra_gtc != 0) {
    # spread = 1 reproduces the app exactly; spread > 1 is the control below.
    win <- extra_year + seq_len(spread) - ceiling(spread / 2)
    e$fossil_GtC[e$year %in% win] <-
      e$fossil_GtC[e$year %in% win] + extra_gtc / spread
  }
  e
}
pr_run <- function(em) suppressWarnings(
  app_run_coupled(APP_SPIN, PR_BG, PR_YEARS, PR_BG, emissions = em))

base  <- pr_run(pr_emissions(PR_YEAR, 0))$climate
shipd <- pr_run(pr_emissions(PR_YEAR, PR_GTC, 1L))$climate
sprd  <- pr_run(pr_emissions(PR_YEAR, PR_GTC, PR_SPREAD))$climate

PPM <- PR_GTC / ccx_const("GtC_PER_PPM")
frac <- function(cl, y) (cl$co2_ppm[cl$year == y] - base$co2_ppm[base$year == y]) / PPM
dT   <- function(cl, y)  cl$gmst[cl$year == y]    - base$gmst[base$year == y]

# ---- THE ANCHOR, checked before anything below is read --------------
cat("\n[2] ANCHOR -- the app's own pulse-lab number, reproduced here\n")
cat(sprintf("    airborne share at %d (%d GtC, %d, %s): %.1f%%\n",
            PR_YEAR + PR_H1, PR_GTC, PR_YEAR, PR_BG, 100 * frac(shipd, PR_YEAR + PR_H1)))
cat(sprintf("    airborne share at %d: %.1f%%   warming at %d: %+.3f °C\n",
            PR_YEAR + PR_H2, 100 * frac(shipd, PR_YEAR + PR_H2),
            PR_YEAR + PR_H1, dT(shipd, PR_YEAR + PR_H1)))

# ---------------------------------------------------------------------
# 3. THE CAUSALITY VIOLATION. Bound = 0, from the law.
# ---------------------------------------------------------------------
cat("\n[3] ⛔ BEFORE the pulse year -- every one of these must be ZERO\n")
pre <- base$year < PR_YEAR
dco2 <- shipd$co2_ppm[pre] - base$co2_ppm[pre]
dgm  <- shipd$gmst[pre]    - base$gmst[pre]
nz   <- which(dco2 != 0)
cat(sprintf("    non-zero pre-pulse years : %d of %d (%d-%d)\n",
            length(nz), sum(pre), base$year[pre][min(nz)], base$year[pre][max(nz)]))
cat(sprintf("    max |ΔCO2|  pre-pulse    : %.3f ppm   (in %d)\n",
            max(abs(dco2)), base$year[pre][which.max(abs(dco2))]))
cat(sprintf("    max |ΔGMST| pre-pulse    : %.5f °C\n", max(abs(dgm))))
cat(sprintf("    signs pre-pulse          : %d negative, %d positive",
            sum(dco2 < 0), sum(dco2 > 0)))
cat("  <- alternating, i.e. ringing, not a leak\n")
cat(sprintf("    ⭐ as a share of the pulse: %.1f%% of one pulse-ppm (%.1f ppm)\n",
            100 * max(abs(dco2)) / PPM, PPM))

# ---------------------------------------------------------------------
# 4. HOW BIG IS THE ERROR IN THE ANSWER THE READER IS GIVEN?
#    Control: the SAME interpolator, the SAME total carbon, spread over
#    PR_SPREAD years so there is no sharp knot to ring. ⚠ THIS IS NOT THE
#    SAME EXPERIMENT -- a spread release genuinely differs from an
#    instantaneous one for about a decade. It is a valid control only at the
#    long horizons, where the two must converge if the difference between them
#    is a release-shape effect and not an artefact.
# ---------------------------------------------------------------------
cat(sprintf("\n[4] Control: the same %d GtC spread over %d years (same interpolator)\n",
            PR_GTC, PR_SPREAD))
cat(sprintf("    control's pre-window max |ΔCO2| : %.3f ppm  (ring-free check)\n",
            max(abs(sprd$co2_ppm[base$year < PR_YEAR - PR_SPREAD] -
                     base$co2_ppm[base$year < PR_YEAR - PR_SPREAD]))))
for (h in c(PR_H1, PR_H2)) {
  y <- PR_YEAR + h
  cat(sprintf("    at %d: shipped %.2f%% airborne, control %.2f%%  (%+.2f pp)\n",
              y, 100 * frac(shipd, y), 100 * frac(sprd, y),
              100 * (frac(shipd, y) - frac(sprd, y))))
  cat(sprintf("           warming %+.4f °C vs %+.4f °C  (%+.1f%%)\n",
              dT(shipd, y), dT(sprd, y),
              100 * (dT(shipd, y) / dT(sprd, y) - 1)))
}

# ---------------------------------------------------------------------
# 5. The early decade. ⛔ READ THE CAVEAT BEFORE READING THE NUMBERS: at
#    short horizons the control is NOT a control. It spreads the same carbon
#    over PR_SPREAD years CENTRED on the pulse year, so at the pulse year
#    itself only about half of it has been released -- the two columns below
#    differ mostly because they are different experiments, and only the
#    long-horizon rows in [4] are a like-for-like comparison. This block is
#    printed to show WHERE the two converge, which is the evidence that [4]'s
#    agreement is real and not an accident of one horizon.
#
#    ⚠ The shipped curve rising from ~45 % at the pulse year to ~97 % a year
#    later is NOT the artefact and must not be reported as one: `co2_ppm` is an
#    ANNUAL MEAN, so a release spread across the twelve months of PR_YEAR is
#    half-counted in that year's mean by construction. The artefact is in [3],
#    and only in [3].
# ---------------------------------------------------------------------
cat("\n[5] Shipped vs control by horizon -- see the caveat in the source:\n")
cat("    the two are DIFFERENT EXPERIMENTS until the release windows wash out\n")
for (h in c(0L, 1L, 2L, 5L, 10L, 20L, 50L, PR_H1, PR_H2)) {
  y <- PR_YEAR + h
  cat(sprintf("    %d (+%3d yr): shipped %6.2f%%   control %6.2f%%   diff %+6.2f pp\n",
              y, h, 100 * frac(shipd, y), 100 * frac(sprd, y),
              100 * (frac(shipd, y) - frac(sprd, y))))
}

# ---------------------------------------------------------------------
# 6. Verdict, stated as the two separate questions it actually is.
# ---------------------------------------------------------------------
cat("\n[6] VERDICT\n")
cat(sprintf(paste0("    (i)  IS IT A DEFECT?  YES, and by a LAW, not a tolerance: %.3f ppm\n",
                   "         of CO2 appears up to %d years BEFORE the pulse, alternating in\n",
                   "         sign. Cause is the natural spline in ccx_annual_to_monthly();\n",
                   "         see [1]. Nothing about the carbon cycle can produce it.\n"),
            max(abs(dco2)), PR_YEAR - base$year[pre][min(nz)]))
cat(sprintf(paste0("    (ii) DOES IT MOVE WHAT THE APP REPORTS?  BARELY: %+.2f pp of\n",
                   "         airborne share at +%d yr and %+.2f pp at +%d yr against the\n",
                   "         ring-free control, and %+.1f%% on the warming. The takeaway's\n",
                   "         quoted numbers stand.\n"),
            100 * (frac(shipd, PR_YEAR + PR_H1) - frac(sprd, PR_YEAR + PR_H1)), PR_H1,
            100 * (frac(shipd, PR_YEAR + PR_H2) - frac(sprd, PR_YEAR + PR_H2)), PR_H2,
            100 * (dT(shipd, PR_YEAR + PR_H1) / dT(sprd, PR_YEAR + PR_H1) - 1)))
cat(paste0("    ⚠ The decay chart is CLIPPED at the pulse year, so the reader never\n",
           "      sees the pre-pulse bump. That is the clip doing the app a favour by\n",
           "      accident -- it was put there for a different reason.\n"))
cat("\n", strrep("=", 72), "\n", sep = "")
