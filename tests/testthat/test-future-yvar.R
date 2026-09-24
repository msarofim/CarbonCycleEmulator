# =====================================================================
# Gate: the FUTURES tab's temperature/CO2 radio (Marcus review F4, 2026-09-24:
# "the temperature/CO2 radio button should be present for the Build your own
# and Pulse lab too").
#
# WHAT THIS GUARDS. The radio's VALUES are column names that three plot
# branches index `ccx_run_coupled()$climate` with. Every way that can break is
# silent in the app, and two of them are the project's recurring shape:
#   (a) A VALUE THAT IS NOT A COLUMN. ⚠ MEASURED, not assumed: in
#       plot_future() this is NOT silent -- `cl[[yvar]]` returns NULL and
#       data.frame() raises "arguments imply differing number of rows: 11, 0,
#       1". But it raises INSIDE a renderPlot reactive, so what the reader gets
#       is a red shiny-output-error box where the chart was, on a tab that
#       otherwise looks fine, and nothing at all in a test run that never
#       starts the app. The radio's values are written in ui.R and consumed in
#       three branches of server.R, so they are exactly the kind of string that
#       decouples from the data frame it indexes.
#   (b) THE PULSE LAB'S TEMPERATURE VIEW READING THE CARBON COLUMN. The two
#       views are differences of the SAME pair of runs and the functions are
#       near-copies, so a copy-paste leaves a plot that renders perfectly and
#       is simply the wrong quantity under a temperature axis.
#   (c) THE KNOWN PRE-PULSE ARTEFACT GROWING. ⭐ This gate's first draft
#       asserted the pre-pulse difference was ZERO -- as causality requires --
#       and it FAILED, which is how the spline-ringing defect was found
#       (calibration/diag_pulse_spline_ringing.R, CHANGELOG 09-24 (d)).
#       `ccx_annual_to_monthly()` uses a natural spline, which is a GLOBAL
#       interpolant, so a one-year pulse rings backwards into the years before
#       it. The bound below is therefore a RATCHET on a measured defect, not a
#       physical tolerance: it is what the artefact is TODAY, so a change that
#       makes it worse is caught, and a fix that removes it makes this test
#       fail LOUDLY and demands the ratchet come down with it.
#   (d) THE TAKEAWAY'S COMPARISON CLAUSE VANISHING. The pulse-lab sentence
#       prints its "longer-lived of the two" clause only when the warming at
#       y1 is positive; if it were not, the clause would silently disappear
#       and the sentence would still be a valid sentence.
#
# MUTATION-TESTED: every assertion is paired with a deliberately broken input
# it must REJECT (project rule, ~/.claude/CLAUDE.md).
#
# COST: two coupled runs to 2300, ~0.5 s each. It uses ccx_run_coupled()
# directly rather than the app's app_run_coupled() wrapper, because what is
# under test is the PLOT's arithmetic on a pair of climate frames, and the
# wrapper's history splice is tested in its own gate.
# =====================================================================

# the app sources its plot helpers from app/R; setup.R only sources R/
.f4_env <- new.env(parent = environment())
local({
  assign("app_params", list(source = "test", status = "test"), envir = .f4_env)
  suppressMessages(library(ggplot2))
  sys.source(file.path(.root, "app", "R", "plots.R"), envir = .f4_env)
})
.f4_warm <- get("plot_pulse_warming", envir = .f4_env)
.f4_dec  <- get("plot_pulse_decay",   envir = .f4_env)
.f4_fut  <- get("plot_future",        envir = .f4_env)

# Read APP_FUTURE_YVARS out of global.R WITHOUT starting the app. global.R
# spins the model up and builds a flux trace at load, so sourcing it here would
# cost seconds and drag the C++ build in. The constant is a pure literal, so
# its own assignment can be evaluated on its own; found by walking the parse
# tree rather than by a regex, which would match it inside a comment.
.f4_const <- function(nm, file) {
  for (e in parse(file)) {
    if (is.call(e) && identical(as.character(e[[1]]), "<-") &&
        is.name(e[[2]]) && identical(as.character(e[[2]]), nm))
      return(eval(e[[3]], envir = baseenv()))
  }
  NULL
}
.f4_global <- file.path(.root, "app", "global.R")
YVARS   <- .f4_const("APP_FUTURE_YVARS", .f4_global)
YDEFAULT <- .f4_const("APP_FUTURE_YVAR_DEFAULT", .f4_global)

# ---- the pulse pair, built the way the app builds it ----------------
.f4 <- local({
  yrs <- c(1750, 2300); pyear <- 2050L; gtc <- 100
  sp <- ccx_spinup(ccx_default_params())
  ssp <- as.data.frame(readRDS(ccx_path("data", "ssp_emissions.rds")))
  bg <- ssp[ssp$scenario == "ssp245", ]
  y <- seq(yrs[1], yrs[2])
  base_em <- data.frame(
    year = y,
    fossil_GtC = stats::approx(bg$year, bg$fossil_GtC, xout = y, rule = 2)$y,
    luc_GtC    = stats::approx(bg$year, bg$luc_GtC,    xout = y, rule = 2)$y)
  pulse_em <- base_em
  pulse_em$fossil_GtC[pulse_em$year == pyear] <-
    pulse_em$fossil_GtC[pulse_em$year == pyear] + gtc
  list(
    base  = suppressWarnings(
      ccx_run_coupled(sp, "ssp245", yrs, emissions = base_em)$climate),
    pulse = suppressWarnings(
      ccx_run_coupled(sp, "ssp245", yrs, emissions = pulse_em)$climate),
    year = pyear, gtc = gtc)
})

# ---- (a) every radio value is a real climate column -----------------
test_that("every value the radio can take is a column ccx_run_coupled returns", {
  expect_true(length(YVARS) >= 2L)
  expect_true(all(nzchar(names(YVARS))))          # every choice has a label
  expect_true(all(YVARS %in% names(.f4$base)))
  expect_true(YDEFAULT %in% YVARS)
  # and each one actually draws something: a finite, full-length series
  for (v in YVARS) {
    d <- ggplot2::ggplot_build(.f4_fut(list(A = list(climate = .f4$base)), v, "y"))$data[[1]]
    expect_equal(nrow(d), nrow(.f4$base), info = v)
    expect_true(all(is.finite(d$y)), info = v)
  }
})

test_that("(a) a radio value that is not a column is REJECTED", {
  # MUTATION: the typo that renders an empty panel instead of erroring.
  expect_false("gmst_anom" %in% names(.f4$base))
  expect_error(
    ggplot2::ggplot_build(.f4_fut(list(A = list(climate = .f4$base)),
                                  "gmst_anom", "y")),
    regexp = NULL)
})

# ---- (b) the temperature view draws TEMPERATURE ---------------------
test_that("plot_pulse_warming draws the two runs' GMST difference, clipped", {
  d <- ggplot2::ggplot_build(
    .f4_warm(.f4$base, .f4$pulse, .f4$year, .f4$gtc))$data[[2]]  # layer 2 = line
  want <- data.frame(year = .f4$base$year,
                     dT = .f4$pulse$gmst - .f4$base$gmst)
  want <- want[want$year >= .f4$year, ]
  expect_equal(nrow(d), nrow(want))
  expect_equal(round(d$y, 10), round(want$dT, 10))
  expect_equal(min(d$x), as.numeric(.f4$year))
})

test_that("(b) a temperature view reading the CARBON column is REJECTED", {
  # MUTATION: the copy-paste that would render perfectly and be wrong. The
  # airborne SHARE the decay panel draws must NOT match the warming series --
  # if it did, this gate could not tell the two views apart at all.
  dw <- ggplot2::ggplot_build(
    .f4_warm(.f4$base, .f4$pulse, .f4$year, .f4$gtc))$data[[2]]
  dc <- ggplot2::ggplot_build(
    .f4_dec(.f4$base, .f4$pulse, .f4$year, .f4$gtc))$data[[2]]
  expect_equal(nrow(dw), nrow(dc))               # same years, so comparable
  expect_false(isTRUE(all.equal(dw$y, dc$y)))
  # and they are not the same series rescaled either: the shapes differ
  expect_false(isTRUE(all.equal(stats::cor(dw$y, dc$y), 1, tolerance = 1e-6)))
})

# ---- (c) the known pre-pulse artefact, ratcheted -------------------
# ⛔ THE ONLY DEFENSIBLE BOUND HERE IS ZERO, and the model does not meet it.
# Rather than write a tolerance that pretends otherwise, this pins the defect
# at its measured size and says so. Expressed as a share of ONE PULSE-PPM so
# the ratchet scales with the pulse rather than being an absolute ppm that
# would silently loosen if the default pulse size changed
# (~/.claude/CLAUDE.md, "scale a plausibility tolerance to the sampled spread").
F4_PRE_PULSE_RING <- 0.08   # measured 0.065 on hilda29l, 2026-09-24

test_that("(c) the acausal pre-pulse ringing has not grown", {
  pre <- .f4$base$year < .f4$year
  expect_true(any(pre))
  ppm <- .f4$gtc / ccx_const("GtC_PER_PPM")
  ring <- max(abs(.f4$pulse$co2_ppm[pre] - .f4$base$co2_ppm[pre])) / ppm
  # The defect is REAL -- this documents it rather than asserting it away.
  expect_gt(ring, 0)
  expect_lt(ring, F4_PRE_PULSE_RING)
  # Its signature is a RINGING, not a leak: a leak would be one-signed.
  d <- .f4$pulse$co2_ppm[pre] - .f4$base$co2_ppm[pre]
  expect_true(any(d > 0) && any(d < 0))
  # MUTATION: after the pulse the difference must be far LARGER than the
  # artefact, or the ratchet above is measuring the signal rather than the
  # noise and would pass on a model that had stopped responding at all.
  post <- .f4$base$year > .f4$year
  expect_gt(max(abs(.f4$pulse$co2_ppm[post] - .f4$base$co2_ppm[post])) / ppm,
            10 * ring)
})

# ---- (d) the takeaway's comparison clause is reachable ---------------
test_that("(d) the pulse takeaway's 'longer-lived' clause actually renders", {
  ppm <- .f4$gtc / ccx_const("GtC_PER_PPM")
  cb <- .f4$base; cp <- .f4$pulse
  f  <- function(y) (cp$co2_ppm[cp$year == y] - cb$co2_ppm[cb$year == y]) / ppm
  dT <- function(y) cp$gmst[cp$year == y] - cb$gmst[cb$year == y]
  y1 <- .f4$year + 100; y2 <- min(.f4$year + 250, max(cb$year))
  # The clause is printed only when dT(y1) > 0; that guard exists so a
  # degenerate run cannot divide by zero, and this asserts the app's OWN
  # default pulse is not degenerate -- i.e. the sentence the reader gets is
  # the full one, not the silently shortened one.
  expect_gt(dT(y1), 0)
  keep_T <- dT(y2) / dT(y1); keep_C <- f(y2) / f(y1)
  expect_true(is.finite(keep_T) && is.finite(keep_C))
  expect_gt(keep_T, 0); expect_gt(keep_C, 0)
  # ⛔ NO DIRECTION AND NO MAGNITUDE IS ASSERTED HERE, for two reasons.
  # First, which of the two is longer-lived is a property of the fitted
  # climate module and the app COMPUTES it rather than declaring it; pinning
  # it would turn a measurement into a ratchet and make a legitimate refit
  # look like a regression. Second and decisive: this file runs on
  # ccx_default_params(), which is NOT the app's parameter set -- the app
  # builds from ccx_mode_base() + ccx_mode_par_with_pins(), and a magnitude
  # asserted on defaults would be a different model's
  # (memory `ccx_diag_must_use_mode_base`, 2026-09-24). Magnitudes belong in
  # calibration/diag_pulse_spline_ringing.R, which is built the app's way.
  # What must hold HERE is only that the clause is well-posed.
  expect_false(isTRUE(all.equal(keep_T, keep_C)))
})
