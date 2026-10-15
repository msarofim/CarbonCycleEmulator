# =====================================================================
# THE TAKEAWAYS' ARITHMETIC (2026-10-12 pre-beta code review, notes/code_review_2026-10-12.md §2).
#
# ⛔⛔ WHY THIS FILE EXISTS. Four numbers the app printed were computed wrongly, each inside a
# renderText where no test could reach it:
#   A1 the Scenarios span read the FIRST and LAST ticked runs, not the min and max;
#   A2 `which.min(abs(t - 1958))` TIES on month-centered times and took December 1957;
#   A3 the Keeling "today" was one December of the raw box against a typed 39-month obs window;
#   A4 the land-use crossing year diffed ANNUAL MEANS, the half-year offset fixed on 09-24 (o).
# The arithmetic now lives in named functions (app/global.R, app/R/plots.R), gated here on
# SYNTHETIC inputs built so that the OLD construction gives a different answer -- each test
# carries its own power. ⚠ These assert numbers, never wording: the prose is Marcus's.
# =====================================================================
.root <- local({
  d <- normalizePath(getwd(), mustWork = FALSE)
  for (i in 1:8) { if (file.exists(file.path(d, "DESIGN.md"))) break; d <- dirname(d) }
  d
})
# parsed out of global.R, not sourced with it (sourcing loads the whole app; see test-stylised-takeaway.R)
.ta_env <- new.env(parent = globalenv())
.ta_want <- c("app_year_mask", "app_annual_mean_of", "app_scenario_span", "app_keeling_numbers")
for (e in parse(file.path(.root, "app", "global.R"))) {
  if (is.call(e) && length(e) >= 3L && identical(as.character(e[[1]]), "<-") &&
      is.name(e[[2]]) && as.character(e[[2]]) %in% .ta_want) eval(e, .ta_env)
}
.months <- function(y0, y1) seq(y0, y1 + 1 - 1e-9, by = 1 / 12) + 1 / 24   # month CENTERS, as the runs
.ta_plots_ok <- requireNamespace("ggplot2", quietly = TRUE) &&
  tryCatch({ assign("APP_LUC_SMOOTH_YR", 11L, envir = .ta_env)
             local({ library(ggplot2); sys.source(file.path(.root, "app", "R", "plots.R"), envir = .ta_env) })
             TRUE }, error = function(e) FALSE)

test_that("the four helpers were found in global.R", {
  for (f in .ta_want) expect_true(is.function(get0(f, envir = .ta_env)), info = f)
})

test_that("A2: a year is addressed by its months -- the integer-distance lookup TIES", {
  t <- .months(1957, 1958)
  # POWER: the old lookup lands in the PREVIOUS year
  expect_equal(floor(t[which.min(abs(t - 1958))]), 1957)
  m <- .ta_env$app_year_mask(t, 1958)
  expect_equal(sum(m), 12L)
  expect_true(all(floor(t[m]) == 1958))
  expect_error(.ta_env$app_year_mask(t, 1960), "no month in 1960")
  expect_equal(.ta_env$app_annual_mean_of(t, t, 1958), 1958.5)
})

test_that("A1: the Scenarios span is the min and max over EVERY ticked run", {
  ends <- c(366, 305, 367, 618, 440, 825, 700)          # menu order, NOT outcome order
  rs <- lapply(seq_along(ends), function(i)
    list(climate = data.frame(year = c(2149, 2150), co2_ppm = c(0, ends[i]), gmst = c(0, ends[i] / 200))))
  sp <- .ta_env$app_scenario_span(rs)
  expect_equal(sp$year, 2150)
  expect_equal(sp$co2, c(305, 825))
  expect_equal(sp$gmst, c(305, 825) / 200)
  # POWER: first and last would have said 366-700
  expect_false(isTRUE(all.equal(sp$co2, range(ends[c(1, length(ends))]))))
  rs[[2]]$climate$year <- c(2148, 2149)
  expect_error(.ta_env$app_scenario_span(rs), "different years")
})

test_that("A3: the Keeling numbers are the scored line's calendar-year means, against the SAME year", {
  t <- .months(1957, 2024)
  seas <- 3 * sin(2 * pi * (t %% 1))
  out <- data.frame(t = t, co2_NH = 300 + (t - 1957) + seas)
  obs <- data.frame(year = c(rep(2024, 12), rep(2025, 12)), month = rep(1:12, 2),
                    co2_ppm = c(rep(410, 12), rep(500, 12)))
  kn <- .ta_env$app_keeling_numbers(out, obs, rep_dC = 4)
  expect_equal(kn$start_year, 1958)
  expect_equal(kn$now_year, 2024)
  expect_equal(kn$start, mean(out$co2_NH[floor(t) == 1958]) - 4)
  expect_equal(kn$now,   mean(out$co2_NH[floor(t) == 2024]) - 4)
  expect_equal(kn$obs_now, 410)                          # 2025 is past the run: excluded
  # POWER: the old "today" (one raw December) and the old window (>= 2023) differ from these
  expect_gt(abs(out$co2_NH[nrow(out)] - kn$now), 3)
  expect_gt(abs(mean(obs$co2_ppm[obs$year >= 2023]) - kn$obs_now), 1)
  # an incomplete observed year is refused, not averaged
  expect_error(.ta_env$app_keeling_numbers(out, obs[-1, ], rep_dC = 4), "11 months in 2024")
  expect_equal(.ta_env$app_keeling_numbers(out, obs, rep_dC = NULL)$now, kn$now + 4)
})

test_that("A4: app_sinks_annual's land_net is CALENDAR-YEAR, not a difference of annual means", {
  skip_if(!.ta_plots_ok, "app/R/plots.R did not load")
  # land stock flat, then rising at 1 GtC/yr from 1 July 1902: a calendar year owns exactly the
  # change between its two 1 Januarys, so 1901 -> 0, 1902 -> 0.5, 1903 -> 1
  t <- .months(1900, 1905)
  out <- data.frame(t = t, ocean_C = 0, land_C = pmax(0, t - 1902.5))
  F <- suppressWarnings(ccx_build_forcing("historical", c(1900, 1905)))
  ann <- .ta_env$app_sinks_annual(out, F)
  got <- ann$land_net[match(c(1901, 1902, 1903), ann$yr)]
  expect_equal(got, c(0, 0.5, 1), tolerance = 1e-12)
  expect_equal(ann$land_sink - ann$land_net,
               ccx_forcing_eluc_annual(F)$eluc[match(ann$yr, ccx_forcing_eluc_annual(F)$year)])
  # POWER: the old construction smears it by half a year (1902 -> 0.125, 1903 -> 0.875)
  a <- stats::aggregate(list(g = out$land_C), list(year = floor(out$t)), mean)
  old <- stats::setNames(diff(a$g), a$year[-1])
  expect_equal(unname(old[c("1902", "1903")]), c(0.125, 0.875), tolerance = 1e-12)
})
