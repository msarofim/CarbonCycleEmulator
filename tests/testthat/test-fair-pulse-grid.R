# =====================================================================
# FaIR ON THE PULSE LAB'S OWN PULSE -- data/fair_pulse_grid.rds and the app's use of it (2026-10-12)
#
# RULED (Marcus 2026-10-12, "Keep card 5; FaIR on same pulse (Recommended)"): FaIR's mean and 5-95 %
# band for the SAME scenario pulse, precomputed over scenarios x release years at one size, shown
# ONLY when the user's pulse is a grid point.
#
# WHAT IS GUARDED:
#   * the product is what its importer refused everything else for (provenance, gates);
#   * the grid covers EVERY background the pulse lab offers x EVERY release year its slider offers, at
#     a size the slider offers -- read from the app's own constants, never retyped here;
#   * on the grid FaIR is drawn; off it nothing is drawn and the reason is given (never the nearest);
#   * the drawn FaIR series starts from zero at the release, as the model's lines do.
# =====================================================================
.root <- local({
  d <- normalizePath(getwd(), mustWork = FALSE)
  for (i in 1:8) { if (file.exists(file.path(d, "DESIGN.md"))) break; d <- dirname(d) }
  d
})
.fpg_file <- file.path(.root, "data", "fair_pulse_grid.rds")
skip_if(!file.exists(.fpg_file), "data/fair_pulse_grid.rds not built (data-raw/build_fair_pulse_grid.R)")

# global.R's own constants and its own loader + matcher, evaluated WITHOUT starting the app
.env <- new.env(parent = globalenv())
.want <- c("APP_SCENARIOS", "APP_PULSE_GtC_DEFAULT", "APP_PULSE_GTC_RANGE", "APP_PULSE_YEAR_RANGE",
           "APP_FAIR_PULSE_FILE", "APP_FAIR_PULSE_LOAD", "APP_FAIR_PULSE", "app_fair_pulse_why",
           "app_fair_pulse", "APP_FAIR_PULSE_LAB_FMT", "APP_FAIR_PULSE_OFFGRID_FMT", "APP_FAIR_PULSE_NOTE")
for (e in parse(file.path(.root, "app", "global.R")))
  if (is.call(e) && length(e) >= 3L && identical(as.character(e[[1]]), "<-") &&
      is.name(e[[2]]) && as.character(e[[2]]) %in% .want) eval(e, .env)
for (w in .want) stopifnot(exists(w, envir = .env, inherits = FALSE))
.d  <- get("APP_FAIR_PULSE", envir = .env)
.pv <- attr(.d, "provenance"); .gt <- attr(.d, "gates")
.yr_slider <- with(list(r = get("APP_PULSE_YEAR_RANGE", envir = .env)), seq(r[1], r[2], r[3]))

test_that("the app LOADS the grid (no refusal reason)", {
  expect_null(get("APP_FAIR_PULSE_LOAD", envir = .env)$why)
  expect_false(is.null(.d))
})

test_that("the product carries its provenance and gates, as the importer required", {
  expect_identical(.pv$model, "FaIR 2.2.4 (calib 1.6.0)")
  expect_identical(as.integer(.pv$n_configs), 841L)
  expect_false(grepl("dirty", .pv$commit, fixed = TRUE))
  expect_match(.pv$metric, "airborne_emissions", fixed = TRUE)
  expect_match(.pv$release, "uniform over the release year", fixed = TRUE)
  expect_true(any(.gt$gate == "G1"))
  g2 <- .gt[.gt$gate == "G2", ]
  expect_setequal(g2$marker, sub("^vv", "", unique(.d$scenario)))
  expect_true(all(g2$value <= g2$tol))           # every baseline arm IS the app's FaIR scenario line
})

test_that("the grid COVERS every background x every release year the pulse lab offers, at a size it offers", {
  arms <- unique(.d[, c("scenario", "release_year")])
  expect_setequal(unique(arms$scenario), unname(get("APP_SCENARIOS", envir = .env)))
  for (sc in unique(arms$scenario)) expect_setequal(arms$release_year[arms$scenario == sc], .yr_slider)
  r <- get("APP_PULSE_GTC_RANGE", envir = .env)
  expect_true(as.numeric(.pv$pulse_gtc) %in% seq(r[1], r[2], r[3]))
  # and the slider's DEFAULT pulse is a grid point, so the comparison appears without moving it
  expect_equal(as.numeric(.pv$pulse_gtc), get("APP_PULSE_GtC_DEFAULT", envir = .env))
})

test_that("ON the grid FaIR is returned and labelled; OFF it nothing is, and the reason is given", {
  on <- .env$app_fair_pulse("vvM", 2050, as.numeric(.pv$pulse_gtc))
  expect_gt(nrow(on), 0L); expect_true(all(on$scenario == "vvM" & on$release_year == 2050))
  expect_match(attr(on, "label"), .pv$model, fixed = TRUE)
  expect_null(.env$app_fair_pulse_why("vvM", 2050, as.numeric(.pv$pulse_gtc)))
  # MUTATIONS: another size, a year the grid lacks, a background it lacks -> no line, a reason
  for (a in list(list("vvM", 2050, as.numeric(.pv$pulse_gtc) + 10), list("vvM", 2045, as.numeric(.pv$pulse_gtc)),
                 list("ssp245", 2050, as.numeric(.pv$pulse_gtc)))) {
    expect_null(do.call(.env$app_fair_pulse, a))
    expect_match(do.call(.env$app_fair_pulse_why, a), "FaIR was only run for", fixed = TRUE)   # Marcus 2026-10-15
  }
})

test_that("the DRAWN FaIR series starts from zero at the release, like the model's lines", {
  pe <- new.env(parent = environment())
  assign("app_params", list(source = "test", status = "test"), envir = pe)
  suppressMessages(library(ggplot2))
  sys.source(file.path(.root, "app", "R", "plots.R"), envir = pe)
  fair <- .env$app_fair_pulse("vvM", 2050, as.numeric(.pv$pulse_gtc))
  yrs <- 2040:2150
  cl <- data.frame(year = yrs, co2_ppm = 400)
  cp <- cl; cp$co2_ppm[cp$year >= 2050] <- 400 + 20
  g <- pe$plot_pulse_decay(cl, cp, 2050, as.numeric(.pv$pulse_gtc), fair = fair)
  b <- ggplot2::ggplot_build(g)
  geoms <- vapply(g$layers, function(l) class(l$geom)[1], "")
  expect_true("GeomRibbon" %in% geoms)
  fd <- g$data[g$data$who == attr(fair, "label"), ]
  expect_equal(fd$year[1], 2050); expect_equal(fd$frac[1], 0)
  expect_equal(fd$year[2], 2050.5); expect_equal(fd$frac[2], fair$af_mean[fair$year == 2050])
})
