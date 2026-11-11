# =====================================================================
# test-app-review-20261111.R -- batch A of the 2026-11-11 minor-issues review (notes/review_2026-11-11_minor_issues.md).
#
# Marcus 2026-11-11: "Go ahead with A". Gates for the items no other file holds (A1 is in test-plot-text-fits 3a2,
# A2 in test-takeaway-arithmetic A5, A12 in test-stylised-takeaway):
#   A3  one colour per scenario, whatever else is drawn          A7/A8  whole-year breaks; the release year labelled
#   A8  small temperatures to two significant figures            A13 FaIR keyed; "Without:" mid-line; legends read across
#   A15 the South Pole span read from the data                   A16 the module note's count words
#   A4/A10/A11  the CSS rules and the slider attribute are where they must be
#   A11b  every Download link is registered never to suspend (found serving the batch-A bundle; CHANGELOG 11-11 j)
# Functions are parsed out of app/global.R (sourcing it loads the whole app) and app/R/plots.R is sourced alone.
# Mutation-tested: outputs/diagnostics/review_20261111/mutate_batch_a.sh.
# =====================================================================

.rv_root <- .root
.rv_env <- local({
  e <- new.env(parent = globalenv())
  assign("app_params", list(source = "x", status = "single best fit"), envir = e)
  assign("APP_LUC_SMOOTH_YR", 11L, envir = e); assign("APP_LUC_SPLIT_NOTE", NULL, envir = e)
  ok <- tryCatch({ suppressMessages(library(ggplot2)); sys.source(file.path(.rv_root, "app", "R", "plots.R"), envir = e); TRUE },
                 error = function(err) FALSE)
  want <- c("APP_SCENARIOS", "APP_SCENARIO_COLOURS", "APP_YOUR_SCENARIO", "APP_YOUR_SCENARIO_COLOUR",
            "app_scenario_colours", "app_degC_small", "app_spo_first_scored_year", "sliderInput",
            "MECH_LABEL_KEEP_CASE", "app_mech_inline", "app_mech_key", "app_cmap_module_note", "APP_SCEN_PROMPT")
  for (x in parse(file.path(.rv_root, "app", "global.R"), keep.source = FALSE))
    if (is.call(x) && identical(as.character(x[[1]]), "<-") && is.name(x[[2]]) && as.character(x[[2]]) %in% want)
      eval(x, e)
  if (ok) e else NULL
})
skip_if_no_rv <- function() { skip_if_not_installed("ggplot2"); skip_if(is.null(.rv_env), "plots.R did not load") }
rv_runs <- function(ids, e) stats::setNames(lapply(ids, function(i)
  list(climate = data.frame(year = 1900:2150, co2_ppm = 300 + seq_along(1900:2150) * match(i, e$APP_SCENARIOS),
                            gmst = 1))), names(e$APP_SCENARIOS)[match(ids, e$APP_SCENARIOS)])
rv_line_colours <- function(p) {   # label -> colour of the drawn lines
  b <- ggplot2::ggplot_build(p); d <- b$data[[length(b$data)]]
  lv <- levels(b$plot$data$who); stats::setNames(d$colour[match(seq_along(lv), d$group)], lv)
}

test_that("A3. a scenario keeps its colour whatever else is ticked; your pathway has its own", {
  skip_if_no_rv(); e <- .rv_env
  cols <- e$app_scenario_colours()
  low <- names(e$APP_SCENARIOS)[e$APP_SCENARIOS == "vvL"]
  three <- rv_line_colours(e$plot_future(rv_runs(c("vvL", "vvM", "vvH"), e), "co2_ppm", "CO2", colours = cols))
  seven <- rv_line_colours(e$plot_future(rv_runs(unname(e$APP_SCENARIOS), e), "co2_ppm", "CO2", colours = cols))
  one   <- rv_line_colours(e$plot_future(rv_runs("vvL", e), "co2_ppm", "CO2", colours = cols))
  expect_identical(unname(three[low]), unname(e$APP_SCENARIO_COLOURS[["vvL"]]))
  expect_identical(unname(seven[low]), unname(three[low]))
  expect_identical(unname(one[low]), unname(three[low]))
  # POWER: by position (the old hue scale) Low changes colour between the two selections
  h3 <- rv_line_colours(e$plot_future(rv_runs(c("vvL", "vvM", "vvH"), e), "co2_ppm", "CO2"))
  h7 <- rv_line_colours(e$plot_future(rv_runs(unname(e$APP_SCENARIOS), e), "co2_ppm", "CO2"))
  expect_false(identical(unname(h3[low]), unname(h7[low])))
  # Build your own: the background keeps its scenario colour, the pathway is the ink
  byo <- c(rv_runs("vvM", e), stats::setNames(rv_runs("vvH", e), e$APP_YOUR_SCENARIO))
  bc <- rv_line_colours(e$plot_future(byo, "co2_ppm", "CO2", colours = cols))
  expect_identical(unname(bc[e$APP_YOUR_SCENARIO]), e$APP_YOUR_SCENARIO_COLOUR)
  expect_identical(unname(bc[names(e$APP_SCENARIOS)[e$APP_SCENARIOS == "vvM"]]), unname(e$APP_SCENARIO_COLOURS[["vvM"]]))
  # every scenario has a distinct colour, and a run without one is refused rather than dropped
  expect_setequal(names(e$APP_SCENARIO_COLOURS), unname(e$APP_SCENARIOS))
  expect_length(unique(cols), length(cols))
  expect_error(e$plot_future(c(rv_runs("vvL", e), list(Other = rv_runs("vvM", e)[[1]])), "co2_ppm", "CO2", colours = cols),
               "no colour")
})

test_that("A7/A8. year axes break on whole years; the Pulse lab labels its release year, also when thinned", {
  skip_if_no_rv(); e <- .rv_env
  b <- e$app_year_breaks()(c(2014.6, 2024.4))
  expect_true(all(b == round(b))); expect_gte(length(b), 3L)
  expect_true(any(scales::breaks_extended()(c(2014.6, 2024.4)) %% 1 != 0))   # POWER: the default gives 2017.5
  r <- e$app_year_breaks(release = 2030)(c(2017.5, 2312.5))
  expect_true(2030 %in% r)
  expect_false(any(abs(r[r != 2030] - 2030) <= e$APP_YEAR_BREAK_GAP * 295))   # no regular break crowding it
  # the class survives ggplot's method wrapping, so the narrow-panel thinning keeps the release year
  d <- data.frame(year = rep(2050:2300, 2), v = 1, panel = rep(c("a", "b"), each = 251))
  p <- ggplot(d, aes(year, v)) + geom_line() + facet_wrap(~panel, nrow = 1) +
    scale_x_continuous(breaks = e$app_year_breaks(release = 2050)) + e$theme_ccx()
  expect_true(inherits(e$.fit_unwrap(p$scales$get_scales("x")$breaks), "ccx_year_breaks"))
  f <- tempfile(fileext = ".png"); grDevices::png(f, width = 336, height = 380, res = 72); e$app_set_panel_px(336)
  on.exit({ e$app_clear_panel_px(); grDevices::dev.off(); unlink(f) }, add = TRUE)
  q <- e$app_fit_plot(p)
  br <- ggplot2::ggplot_build(q)$layout$panel_params[[1]]$x$breaks
  expect_true(2050 %in% br); expect_true(all(br[!is.na(br)] == round(br[!is.na(br)])))
})

test_that("A8. a small temperature keeps two significant figures; larger ones two decimals", {
  skip_if_no_rv(); f <- .rv_env$app_degC_small
  expect_identical(c(f(0.0151), f(0.0143), f(0.14), f(0.672), f(0)), c("0.015", "0.014", "0.14", "0.67", "0.00"))
  expect_identical(sprintf("%.2f", 0.0151), "0.02")   # POWER: what it printed
})

test_that("A13. FaIR's dashes have a key on their own row; legends read across; 'Without:' takes the mid-line form", {
  skip_if_no_rv(); e <- .rv_env
  runs <- rv_runs(unname(e$APP_SCENARIOS), e)
  fair <- data.frame(year = 1900:2150, y = 300, who = names(runs)[1])
  p <- e$plot_future(runs, "co2_ppm", "CO2", fair = fair, colours = e$app_scenario_colours())
  lt <- ggplot2::ggplot_build(p)$plot$scales$get_scales("linetype")   # trained on the data
  expect_false(is.null(lt))
  expect_identical(as.character(lt$get_breaks()), c(e$KEY_FUTURE_MODEL, e$KEY_FUTURE_FAIR))
  expect_identical(p$theme$legend.box, "vertical")
  expect_true(isTRUE(p$guides$guides$colour$params$theme$legend.byrow))   # ggplot2 4.0 keeps byrow in the guide's theme
  expect_null(e$plot_future(runs, "co2_ppm", "CO2", colours = e$app_scenario_colours())$scales$get_scales("linetype"))
  # Keeling / d13C: no forced second row for a two-key legend
  src <- readLines(file.path(.rv_root, "app", "R", "plots.R"), warn = FALSE)
  expect_length(grep("guide_legend\\(nrow = 2, byrow = TRUE\\)", src), 0L)
  # "Without: the ocean sink", but "Without: CO₂ fertilization" and "Without: El Niño / La Niña"
  mech <- list(ocean_sink = list(label = "The ocean sink"), fertilisation = list(label = "CO₂ fertilization"),
               enso = list(label = "El Niño / La Niña"))
  assign("CCX_MECHANISMS", mech, envir = e)
  expect_identical(e$app_mech_key("ocean_sink"), "Without: the ocean sink")
  expect_identical(e$app_mech_key("fertilisation"), "Without: CO₂ fertilization")
  expect_identical(e$app_mech_key("enso"), "Without: El Niño / La Niña")
})

test_that("A15. the South Pole span starts at the first year with enough months, as the likelihood scores it", {
  skip_if_no_rv(); e <- .rv_env
  mk <- function(y, n) data.frame(station = "SPO", decimal_date = y + (seq_len(n) - 0.5) / 12, co2_ppm = 320)
  obs <- rbind(mk(1957, 3), mk(1958, 8), mk(1962, 9), mk(1963, 12), mk(1975, 12))
  expect_identical(e$app_spo_first_scored_year(obs, min_months = 9L), 1962L)
  expect_identical(e$app_spo_first_scored_year(obs, min_months = 3L), 1957L)
})

test_that("A16. one El Niño setting reads as one; an empty scenario selection asks for a tick", {
  skip_if_no_rv(); e <- .rv_env
  assign("APP_CMAP_MODULE_ROW_TEXT", c(gr = "the growth rate's year-to-year wobble"), envir = e)
  src <- deparse(e$app_cmap_module_note)
  expect_true(any(grepl('"It is"', src, fixed = TRUE)) && any(grepl('"setting"', src, fixed = TRUE)))
  expect_true(nzchar(e$APP_SCEN_PROMPT))
  sv <- readLines(file.path(.rv_root, "app", "server.R"), warn = FALSE)
  expect_length(grep("if (!length(input$f_scen)) return(APP_SCEN_PROMPT)", sv, fixed = TRUE), 1L)
})

test_that("A4/A10/A11. the phone table rule, the checkbox contrast, the empty-chart rule and the slider attribute", {
  skip_if_no_rv(); e <- .rv_env
  ui <- paste(readLines(file.path(.rv_root, "app", "ui.R"), warn = FALSE), collapse = "\n")
  phone <- sub("(?s).*?@media \\(max-width: %1\\$\\.2fpx\\) \\{(.*?)\\n  \\}.*", "\\1", ui, perl = TRUE)
  expect_match(phone, ".tab-content table { display: block; max-width: 100%%; overflow-x: auto; overflow-wrap: normal;",
               fixed = TRUE)
  expect_match(ui, ".shiny-plot-output:not(:has(img)) + .ccx-dl { display: none; }", fixed = TRUE)
  expect_match(ui, ".checkbox input[type=checkbox]:not(:checked), .radio input[type=radio]:not(:checked) { border-color: #6c757d; }",
               fixed = TRUE)
  skip_if_not_installed("shiny")
  html <- as.character(e$sliderInput("x", "X", 0, 10, 5))
  expect_match(html, 'data-force-edges="true"', fixed = TRUE)
  expect_false(grepl('data-force-edges', as.character(shiny::sliderInput("x", "X", 0, 10, 5)), fixed = TRUE))   # POWER
})

# 2026-11-11, found serving the batch-A bundle (check_live_pointer.py: the CSV line came back empty). Shiny suspends an
# output it sees as hidden, and a suspended download link gets no address. A11's rule above hides the Download line
# until its chart has an image, so on every tab Shiny checked the links while they were hidden and never looked again:
# each link stayed disabled. app_dl_server() now marks every download output never to suspend. testServer() cannot see
# output options (its mock session does not record them), so app_dl_server() runs here against a stand-in for Shiny's
# output object that records both calls and, as Shiny does, refuses options on an output not yet defined.
test_that("A11b. every Download link is registered never to suspend, so a line hidden while its chart draws still works", {
  skip_if_not_installed("shiny")
  e <- new.env(parent = globalenv())
  for (x in parse(file.path(.rv_root, "app", "R", "downloads.R"), keep.source = FALSE))
    if (is.call(x) && identical(as.character(x[[1]]), "<-") && is.name(x[[2]]) && as.character(x[[2]]) == "app_dl_server")
      eval(x, e)
  expect_true(is.function(e$app_dl_server))
  assign("app_dl_spec", function(id) list(chart = id), envir = e)
  rec <- new.env(); rec$defined <- character(); rec$opts <- list()
  impl <- list(
    defineOutput = function(name, value, label) rec$defined <- c(rec$defined, name),
    outputOptions = function(name, ...) {
      if (!name %in% rec$defined) stop(name, " is not in list of output objects")
      rec$opts[[name]] <- utils::modifyList(rec$opts[[name]] %||% list(), list(...))
    })
  out <- structure(list(impl = impl, ns = function(x) x), class = "shinyoutput")
  plots <- new.env(); for (id in c("k_plot", "w_af", "f_partition")) assign(id, function() NULL, envir = plots)
  e$app_dl_server(out, session = NULL, plots = plots)
  want <- as.vector(outer(ls(plots), c("_csv", "_png"), paste0))
  expect_setequal(rec$defined, want)
  for (nm in want) expect_identical(rec$opts[[nm]]$suspendWhenHidden, FALSE, info = nm)
})
