# =====================================================================
# Gate: the FUTURES tab's 1900-2150 span (Marcus review F5, APPROVED
# 2026-09-24: "I'm okay with the history->scenario splice being midframe").
#
# WHAT THIS GUARDS.
#   (a) THE RUN SPAN AND THE VIEW SPAN STAYING DIFFERENT THINGS. The model
#       must still START IN 1750. A run begun at 1900 inherits ~88 GtC of
#       land-use carbon already emitted while ccx_spinup() hands it
#       preindustrial stocks -- ccx_build_forcing() warns about exactly that
#       and the run still completes, so the failure is a start-up transient in
#       a finished-looking chart. If APP_FUTURE_VIEW were ever used as the run
#       span, or APP_FUTURE_YEARS as the view, nothing would error.
#   (b) A VIEW THAT SELECTS NOTHING. Cropping by filter means an out-of-range
#       view yields zero rows, and ggplot draws an empty panel with axes --
#       which reads as "the model is flat here", the project's recurring
#       silent-empty-panel failure. plot_future() must REFUSE it.
#   (c) THE Y SCALE TRAINING ON THE VISIBLE YEARS. The crop is a filter and
#       NOT coord_cartesian() precisely so this holds; a zoom would leave the
#       axis trained on 1750 onward. Asserted by construction, and
#       mutation-tested against the zoom it rejects.
#   (d) ⭐ THE FITTED-RANGE CAVEAT. F5 did not create the extrapolation but it
#       made it 26x worse: the stylized "+5 %/yr" pathway reaches 3,516 ppm at
#       2100 (2.1x the fitted top) and 44,172 ppm at 2150 (26.2x). Measured
#       both horizons, 2026-09-24. ccx_run_coupled() warns to the CONSOLE,
#       which is not where a reader is. The note must fire outside the range
#       and must NOT fire inside it -- a caveat that always shows is furniture.
#
# MUTATION-TESTED throughout.
# =====================================================================

.f5_env <- new.env(parent = environment())
local({
  assign("app_params", list(source = "test", status = "test"), envir = .f5_env)
  suppressMessages(library(ggplot2))
  sys.source(file.path(.root, "app", "R", "plots.R"), envir = .f5_env)
})
.f5_fut <- get("plot_future", envir = .f5_env)

# Constants and the note function are read out of global.R's PARSE TREE rather
# than by sourcing it: global.R spins the model up and builds a flux trace at
# load. The constants are literals; app_erf_range_note() takes its range and
# slack as arguments for exactly this reason, so it evaluates standalone.
.f5_top <- function(nm) {
  for (e in parse(file.path(.root, "app", "global.R"))) {
    if (is.call(e) && identical(as.character(e[[1]]), "<-") &&
        is.name(e[[2]]) && identical(as.character(e[[2]]), nm))
      return(eval(e[[3]], envir = globalenv()))
  }
  NULL
}
RUN  <- .f5_top("APP_FUTURE_YEARS")
VIEW <- .f5_top("APP_FUTURE_VIEW")
NOTE <- .f5_top("app_erf_range_note")

.f5_cl <- function(y0, y1, co2 = 400) data.frame(
  year = y0:y1, co2_ppm = rep(co2, y1 - y0 + 1), gmst = seq(0, 2, length.out = y1 - y0 + 1))

# ---- (a) the two spans are distinct, and nested the right way -------
test_that("(a) the run starts in 1750 and the view is a window inside it", {
  expect_equal(RUN[1], 1750)                 # the model's own start
  expect_true(VIEW[1] > RUN[1])              # the view crops, it does not extend
  expect_equal(VIEW[2], RUN[2])              # and it reaches the end of the run
  expect_true(VIEW[1] < VIEW[2])
  # F5's approved span, pinned: this is the ruling, so changing it should
  # require editing this line and noticing.
  expect_equal(as.numeric(VIEW), c(1900, 2150))
})

test_that("(a) a view used as a run span would be REJECTED", {
  # MUTATION: the confusion this gate exists to catch. ccx_build_forcing()
  # warns when a window starts after the emissions record does; that warning
  # is the tell, and it must still be there to be caught.
  expect_warning(ccx_build_forcing("historical", c(VIEW[1], 2024), prod_c14 = 0))
  expect_silent(suppressMessages(
    invisible(ccx_build_forcing("historical", c(RUN[1], 2024), prod_c14 = 0))))
})

# ---- (b)/(c) the crop ----------------------------------------------
test_that("(b) plot_future crops to the view and keeps every year in it", {
  runs <- list(A = list(climate = .f5_cl(RUN[1], RUN[2])))
  d <- ggplot2::ggplot_build(.f5_fut(runs, "gmst", "y", view = VIEW))$data[[1]]
  expect_equal(range(d$x), as.numeric(VIEW))
  expect_equal(nrow(d), VIEW[2] - VIEW[1] + 1)
  # uncropped, it must draw the whole run -- or the crop above proves nothing
  d0 <- ggplot2::ggplot_build(.f5_fut(runs, "gmst", "y"))$data[[1]]
  expect_equal(range(d0$x), as.numeric(RUN))
})

test_that("(b) a view that selects no years is REFUSED, not drawn empty", {
  runs <- list(A = list(climate = .f5_cl(RUN[1], RUN[2])))
  expect_error(.f5_fut(runs, "gmst", "y", view = c(2400, 2500)), "selects no model years")
})

test_that("(c) the y scale trains on the VISIBLE years only", {
  # A run whose pre-view years are wildly out of range. Under a filter the y
  # axis must ignore them; under coord_cartesian() it would not. This is the
  # mutation test for the choice recorded on APP_FUTURE_VIEW.
  cl <- .f5_cl(RUN[1], RUN[2])
  cl$gmst[cl$year < VIEW[1]] <- 999
  runs <- list(A = list(climate = cl))
  b <- ggplot2::ggplot_build(.f5_fut(runs, "gmst", "y", view = VIEW))
  expect_lt(max(b$layout$panel_params[[1]]$y.range), 100)
})

# ---- (d) the fitted-range caveat -----------------------------------
test_that("(d) the caveat is silent inside the fitted range", {
  rng <- c(278, 1687)
  expect_null(NOTE(list(.f5_cl(2000, 2150, co2 = 900)), rng = rng, slack = 5))
  # and exactly at the top of the range, still silent
  expect_null(NOTE(list(.f5_cl(2000, 2150, co2 = 1687)), rng = rng, slack = 5))
})

test_that("(d) the caveat fires outside it, and reports MEASURED numbers", {
  rng <- c(278, 1687)
  n <- NOTE(list(.f5_cl(2000, 2150, co2 = 44172)), rng = rng, slack = 5)
  expect_true(is.character(n) && nzchar(n))
  expect_true(grepl("44,172", n, fixed = TRUE))   # the run's own peak
  expect_true(grepl("1,687", n, fixed = TRUE))    # the fitted top
  expect_true(grepl("26 times", n, fixed = TRUE)) # the ratio, computed
  # MUTATION: move the fitted range and the sentence must move with it. A
  # hard-coded number would survive this.
  n2 <- NOTE(list(.f5_cl(2000, 2150, co2 = 44172)), rng = c(278, 2000), slack = 5)
  expect_false(grepl("1,687", n2, fixed = TRUE))
  expect_true(grepl("2,000", n2, fixed = TRUE))
})

test_that("(d) the MAXIMUM over all drawn runs is what decides", {
  rng <- c(278, 1687)
  # one in-range run beside one out-of-range run must still fire: the reader
  # is looking at both lines, and the caveat is about the chart.
  expect_false(is.null(NOTE(list(.f5_cl(2000, 2150, co2 = 500),
                                 .f5_cl(2000, 2150, co2 = 44172)),
                            rng = rng, slack = 5)))
})
