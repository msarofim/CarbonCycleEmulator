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
# The pulse lab's interpolation, read from the app's own constant by the same
# route -- never retyped here, or the tab and its gate could drift apart.
PULSE_METHOD <- .f4_const("APP_PULSE_EMIS_METHOD", .f4_global)
stopifnot(is.character(PULSE_METHOD), length(PULSE_METHOD) == 1L)

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
  # ⚠ "the way the app builds it" INCLUDES ITS INTERPOLATION. The app's pulse
  # lab opts into APP_PULSE_EMIS_METHOD (2026-09-24); a test that kept the
  # DEFAULT here would be exercising a path the tab no longer uses, which is the
  # caption-sync bug class -- the test would keep passing while the tab changed.
  # Read from the app's own constant, never retyped.
  run <- function(em, method) suppressWarnings(
    ccx_run_coupled(sp, "ssp245", yrs, emissions = em, interp_method = method)$climate)
  list(base_em = base_em, pulse_em = pulse_em,
       base  = run(base_em,  PULSE_METHOD),
       pulse = run(pulse_em, PULSE_METHOD),
       base_default  = run(base_em,  CCX_EMIS_METHOD_DEFAULT),
       pulse_default = run(pulse_em, CCX_EMIS_METHOD_DEFAULT),
       # the retired default, run by NAME (2026-10-01): (c3) needs it to show the
       # flip removed a real defect rather than nothing
       base_spline   = run(base_em,  "spline"),
       pulse_spline  = run(pulse_em, "spline"),
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
# RE-PINNED 2026-10-11 (Marcus: "Re-pin both (Recommended)", on his 10-11 comment "start the line at
# zero when the pulse starts"). Was: the clipped annual means at their integer years, so the line began
# mid-air at the release year's own mean. Now: an exact 0 on 1 January of the release, then each
# annual mean at MID-YEAR (pulse_from_release(), app/R/plots.R).
test_that("plot_pulse_warming draws the two runs' GMST difference, from zero at the release", {
  d <- ggplot2::ggplot_build(
    .f4_warm(.f4$base, .f4$pulse, .f4$year, .f4$gtc))$data[[2]]  # layer 2 = line
  k <- .f4$base$year >= .f4$year
  want <- data.frame(year = c(.f4$year, .f4$base$year[k] + 0.5),
                     dT = c(0, (.f4$pulse$gmst - .f4$base$gmst)[k]))
  expect_equal(nrow(d), nrow(want))
  expect_equal(round(d$y, 10), round(want$dT, 10))
  expect_equal(round(d$x, 10), round(want$year, 10))
  # the start IS the release, at exactly zero, and the first mean sits half a year later
  expect_identical(d$y[1], 0)
  expect_equal(d$x[1:2], as.numeric(.f4$year) + c(0, 0.5))
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

# ---- (c) causality, asserted EXACTLY where exactness is owed --------
# ⭐⭐ THE ONLY DEFENSIBLE BOUND IS ZERO, and as of 2026-09-24 the app MEETS it
# where the fix can deliver it. This used to pin the defect at its measured size
# (a ratchet) because a tolerance would have been a lie; the app now opts into
# causal interpolation, so the ratchet is replaced by the real bound.
# ⚠ THREE LEVELS, BECAUSE THEY ARE OWED DIFFERENT THINGS. The interpolation is
# exact; the uncoupled run inherits that exactly; the COUPLED run additionally
# carries the outer loop's convergence, which is not acausality and must not be
# asserted away as if it were. Measured 2026-09-24: spline leaks 52.6 GtC/yr of
# pre-pulse emissions and 4.70 ppm of pre-pulse CO2; constant leaks 0.000 of both.
test_that("(c) the app's interpolation is EXACTLY causal: emissions and uncoupled CO2", {
  sp  <- ccx_spinup(ccx_default_params())
  mk  <- function(em) suppressWarnings(ccx_build_forcing(
            "ssp245", c(1750, 2300), prod_c14 = sp$prod_c14,
            emissions = em, emis_method = PULSE_METHOD))
  Fb <- mk(.f4$base_em); Fp <- mk(.f4$pulse_em)
  pre <- Fb$year < .f4$year
  expect_true(any(pre))
  # 1. the emissions the model is HANDED are bit-identical before the pulse
  expect_identical(max(abs((Fp$e_foss_NH + Fp$e_foss_SH)[pre] -
                           (Fb$e_foss_NH + Fb$e_foss_SH)[pre])), 0)
  # 2. and so is the CO2 of the run that has no outer loop to blur it
  rb <- ccx_run_fast(sp, Fb); rp <- ccx_run_fast(sp, Fp)
  k  <- floor(rb$out$t + 1e-9) < .f4$year
  expect_identical(max(abs(((rp$out$co2_NH + rp$out$co2_SH) / 2 -
                            (rb$out$co2_NH + rb$out$co2_SH) / 2)[k])), 0)
  # MUTATION GUARD: a pair that stopped responding would also be zero before the
  # pulse, so require a real signal after it.
  expect_gt(max(abs(((rp$out$co2_NH + rp$out$co2_SH) / 2 -
                     (rb$out$co2_NH + rb$out$co2_SH) / 2)[!k])), 1)
})

test_that("(c2) the COUPLED pair's pre-pulse residual VANISHES as the loop converges", {
  # ⛔⛔ THIS IS THE TEST THAT CAUGHT THE INCOMPLETE FIX, and it is the reason it
  # is written as a LIMIT rather than a tolerance. Fixing only the emissions
  # interpolation left 3.48e-3 ppm before a 2050 pulse. That looked like
  # convergence noise -- and the first attempt at this gate tried to measure a
  # noise floor and pass it. It was NOT noise: it did not move when the outer
  # loop's tolerance was tightened 100x, because a SECOND global spline (the
  # GMST feedback in R/climate.R) was ringing backwards too.
  # ⇒ The discriminating property is the LIMIT, not the size. Convergence noise
  # shrinks with `tol`; an acausal path does not. Asserting a small number would
  # have passed the broken model; asserting the limit does not.
  sp  <- ccx_spinup(ccx_default_params()); yrs <- c(1750, 2300)
  pre_resid <- function(tol) {
    b <- suppressWarnings(ccx_run_coupled(sp, "ssp245", yrs, emissions = .f4$base_em,
           interp_method = PULSE_METHOD, tol = tol))$climate
    p <- suppressWarnings(ccx_run_coupled(sp, "ssp245", yrs, emissions = .f4$pulse_em,
           interp_method = PULSE_METHOD, tol = tol))$climate
    max(abs(p$co2_ppm[b$year < .f4$year] - b$co2_ppm[b$year < .f4$year]))
  }
  loose <- pre_resid(CLIM_TOL)
  tight <- pre_resid(CLIM_TOL / 100)
  expect_lt(loose, 1e-4)        # already negligible at the shipped tolerance
  expect_identical(tight, 0)    # and EXACTLY zero once the loop is converged
  expect_lte(tight, loose)      # monotone: tightening never makes it worse
})

# ⭐ THE DEFAULT PATH IS CAUSAL TOO, SINCE 2026-10-01: THE LEDGER IS PAID.
# Until then this test asserted the opposite on purpose -- "the DEFAULT
# interpolation still rings, and the app does not use it" -- so that whoever
# flipped CCX_EMIS_METHOD_DEFAULT would be told by a failing test that the
# `emissions-interp-constant` ledger was due. Marcus ruled the flip on 2026-10-01
# (review 10-01c B6, "apply it now"), every registered mode was restamped at its
# priced move (calibration/diag_emis_constant_price.R), and this now asserts the
# paid state: the default IS the app's method, the default pair is causal to the
# coupled loop's own bound ((c2)'s), and -- the power -- the retired spline, run
# by name, still rings. Flip the default back and the first two fail.
test_that("(c3) the DEFAULT interpolation is the causal one (ledger paid 2026-10-01); the spline still rings", {
  pre <- .f4$base_default$year < .f4$year
  ppm <- .f4$gtc / ccx_const("GtC_PER_PPM")
  expect_identical(CCX_EMIS_METHOD_DEFAULT, PULSE_METHOD)
  d_def <- .f4$pulse_default$co2_ppm[pre] - .f4$base_default$co2_ppm[pre]
  expect_lt(max(abs(d_def)), 1e-4)         # (c2)'s bound at the shipped loop tolerance
  # POWER: the method the flip retired, run by name, still leaks a ringing
  # (2026-09-24: 4.70 ppm of uncoupled CO2 before a 2050 pulse)
  pre_s <- .f4$base_spline$year < .f4$year
  d_spl <- .f4$pulse_spline$co2_ppm[pre_s] - .f4$base_spline$co2_ppm[pre_s]
  expect_gt(max(abs(d_spl)) / ppm, 0.01)    # at least 1 % of one pulse-ppm before the pulse
  expect_true(any(d_spl > 0) && any(d_spl < 0))   # a RINGING, not a one-signed leak
  expect_gt(max(abs(d_spl)), 100 * max(abs(d_def)))
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
