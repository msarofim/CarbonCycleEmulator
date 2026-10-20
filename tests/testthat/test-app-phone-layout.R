# =====================================================================
# Gate: the app on a phone (2026-10-20).
#
# Measured at 375 x 812 before this work (outputs/diagnostics/mobile_layout_20261020/): the first tab's
# takeaway started 837 px down and its first plot 1,208 px down, and 13 of the 25 plots drawn by default
# had text running off an edge of the image (legends cut at both sides, captions, y titles).
#   * app_fit_plot() (app/R/plots.R) refits a finished plot to a narrow panel. It is called by
#     renderPlotFit() for every plot, so a regression here is silent on screen until someone opens the app
#     on a phone. These tests build plots that DO overflow at 351 px (each asserts that first, so the fix
#     has something to fix) and require the fitted plot to fit.
#   * ui.R puts each tab's lead (takeaway + main plot) before the sidebar on a phone through main_panel().
#     A tab built with a bare mainPanel(), or a lead without its takeaway, would fall back to controls-first
#     with no error; the static checks below catch both, and are mutation-tested.
# =====================================================================

.pf_plots <- file.path(.root, "app", "R", "plots.R")
.pf_env <- local({
  e <- new.env(parent = globalenv())
  assign("app_params", list(source = "posterior mode (single best fit)",
                            status = "Not peer-reviewed teaching software"), envir = e)
  assign("APP_LUC_SMOOTH_YR", 11L, envir = e)
  assign("APP_LUC_SPLIT_NOTE", NULL, envir = e)
  ok <- tryCatch({ suppressMessages(library(ggplot2)); sys.source(.pf_plots, envir = e); TRUE },
                 error = function(err) FALSE)
  if (ok) e else NULL
})
skip_if_no_fit <- function() {
  skip_if_not_installed("ggplot2")
  skip_if(is.null(.pf_env), "app/R/plots.R did not load")
}
# Open a device of the panel's size and publish that width, as renderPlotFit() does.
pf_at <- function(e, w, h, expr) {
  f <- tempfile(fileext = ".png")
  grDevices::png(f, width = w, height = h, res = 72)
  e$app_set_panel_px(w)
  on.exit({ e$app_clear_panel_px(); grDevices::dev.off(); unlink(f) }, add = TRUE)
  force(expr)
}
pf_geo <- function(e, p) e$.fit_geometry(ggplot2::ggplot_gtable(ggplot2::ggplot_build(p)))

# The Keeling chart's six keys, two rows of three (its own guide), plus an override.aes the refit must keep.
PF_KEYS <- c("Measured, Mauna Loa", "Measured, South Pole", "Model box, north", "Model box, south",
             "Model, Northern Hemisphere", "Model, Southern Hemisphere")
pf_legend_plot <- function(e) {
  d <- data.frame(x = rep(1:10, 6), y = rep(1:10, 6) + rep(1:6, each = 10),
                  k = factor(rep(PF_KEYS, each = 10), levels = PF_KEYS))
  ggplot(d, aes(x, y, colour = k)) + geom_line() +
    guides(colour = guide_legend(nrow = 2, byrow = TRUE, override.aes = list(linewidth = 3))) +
    labs(caption = e$app_provenance_caption()) + e$theme_ccx()
}

test_that("1. an overflowing legend is refitted until it fits, its guide settings kept", {
  skip_if_no_fit(); e <- .pf_env
  pf_at(e, 351, 380, {
    p <- pf_legend_plot(e)
    expect_gt(pf_geo(e, p)$legend_over, 0.5)          # the fixture really overflows at phone width
    q <- e$app_fit_plot(p)
    expect_lte(pf_geo(e, q)$legend_over, 0.5)
    expect_equal(q$guides$guides$colour$params$override.aes$linewidth, 3)
    expect_null(q$guides$guides$colour$params$nrow)
  })
})

test_that("2. above APP_FIT_MAX_PX, and with no live width, the plot comes back untouched", {
  skip_if_no_fit(); e <- .pf_env
  p <- pf_legend_plot(e)
  # a legend that overflows even just above the threshold: left alone there, because wide layouts are not
  # touched (mutation-tested: without the threshold this refits it)
  wide <- p + guides(colour = guide_legend(nrow = 1))
  pf_at(e, e$APP_FIT_MAX_PX + 1, 380, {
    expect_gt(pf_geo(e, wide)$legend_over, 0.5)
    expect_identical(e$app_fit_plot(wide), wide)
  })
  e$app_clear_panel_px()
  expect_identical(e$app_fit_plot(p), p)
  expect_identical(e$app_fit_plot("not a plot"), "not a plot")
  # ...and a plot that already fits a narrow panel is untouched too
  q <- ggplot(data.frame(x = 1:3, y = 1:3), aes(x, y)) + geom_point() + e$theme_ccx()
  pf_at(e, 351, 380, expect_identical(e$app_fit_plot(q), q))
})

test_that("3. a plain y title taller than its panel wraps; a plotmath one is left alone", {
  skip_if_no_fit(); e <- .pf_env
  ttl <- "Share of all emissions still in the air"
  mk <- function(y) ggplot(data.frame(x = 1:3, y = 1:3), aes(x, y)) + geom_line() +
    labs(y = y, caption = e$app_provenance_caption("Dashed line at 50% for reference.")) + e$theme_ccx()
  pf_at(e, 351, 260, {
    p <- mk(ttl)
    room <- pf_geo(e, p)$y_room
    expect_gt(e$.fit_text_px(ttl, e$CCX_BASE_SIZE), room)    # the fixture really overflows
    q <- e$app_fit_plot(p)
    lab <- ggplot2::ggplot_build(q)$plot$labels$y
    expect_true(grepl("\n", lab, fixed = TRUE))
    expect_identical(gsub("\n", " ", lab, fixed = TRUE), ttl)  # moved, not reworded
    expect_lte(e$.fit_text_px(lab, e$CCX_BASE_SIZE), pf_geo(e, q)$y_room)
    pm <- mk(e$app_plotmath("CO₂ above the annual mean (ppm)"))
    expect_identical(ggplot2::ggplot_build(e$app_fit_plot(pm))$plot$labels$y,
                     ggplot2::ggplot_build(pm)$plot$labels$y)
  })
})

test_that("3b. a subtitle no wrapper handled is wrapped to the plot; one app_subtitle() wrapped is left alone", {
  skip_if_no_fit(); e <- .pf_env
  # a What-if driver chart's subtitle: a mechanism's label, drawn as is (plot_driver()); this one reached the
  # right edge of the 351 px panel on 2026-10-20
  sub <- "El Ni\u00f1o / La Ni\u00f1a: the Ni\u00f1o 3.4 sea-surface temperature anomaly"
  mk <- function(s) ggplot(data.frame(x = 1:3, y = 1:3), aes(x, y)) + geom_line() + labs(subtitle = s) +
    e$theme_ccx()
  pf_at(e, 351, 300, {
    expect_gt(e$.fit_text_px(sub, e$SUBTITLE_PT), e$app_text_px("full"))   # the fixture really overflows
    got <- ggplot2::ggplot_build(e$app_fit_plot(mk(sub)))$plot$labels$subtitle
    expect_identical(gsub("\n", " ", got, fixed = TRUE), sub)
    expect_lte(e$.fit_text_px(got, e$SUBTITLE_PT), e$app_text_px("full"))
    pre <- e$app_subtitle(paste(sub, sub))                                   # already wrapped to this width
    expect_identical(ggplot2::ggplot_build(e$app_fit_plot(mk(pre)))$plot$labels$subtitle, pre)
  })
})

test_that("4. colliding category labels are turned on end, and only when they collide", {
  skip_if_no_fit(); e <- .pf_env
  cats <- c("North,\nmixed layer", "North,\ncold box", "South,\nmixed layer", "South,\ncold box",
            "North", "South", "North\nminus south")
  p <- ggplot(data.frame(c = factor(cats, levels = cats), v = 1:7), aes(c, v)) + geom_col() + e$theme_ccx()
  angle <- function(q) ggplot2::calc_element("axis.text.x.bottom", q$theme)$angle
  pf_at(e, 313, 320, expect_equal(angle(e$app_fit_plot(p)), 90))
  pf_at(e, e$APP_FIT_MAX_PX, 320, expect_equal(angle(e$app_fit_plot(p)), 0))   # 552 px: room enough
})

test_that("4b. crowded year ticks get fewer breaks, across a facet edge too; an uncrowded axis is untouched", {
  skip_if_no_fit(); e <- .pf_env
  # the pulse lab's two panels, 2050-2300: at 351 px "2300" and "2050" met across the gap
  two <- ggplot(data.frame(x = rep(c(2050, 2300), 2), y = 1:4, g = rep(c("left", "right"), each = 2)),
                aes(x, y)) + geom_line() + facet_wrap(~g, nrow = 1) + e$theme_ccx()
  collide <- function(q) { b <- ggplot2::ggplot_build(q); e$.fit_x_ticks_collide(q, b, ggplot2::ggplot_gtable(b)) }
  pf_at(e, 351, 320, {
    expect_gte(collide(two), 3L)                      # the fixture really collides
    expect_identical(collide(e$app_fit_plot(two)), 0L)
  })
  # a single panel of years is not crowded at phone width, and is left exactly as it was
  one <- ggplot(data.frame(x = c(1850, 2024), y = 1:2), aes(x, y)) + geom_line() + e$theme_ccx()
  pf_at(e, 351, 320, expect_identical(e$app_fit_plot(one), one))
})

test_that("5. a plot that fails to build is returned as it was, with a message", {
  skip_if_no_fit(); e <- .pf_env
  bad <- ggplot(data.frame(x = 1), aes(x, no_such_column)) + geom_point()
  pf_at(e, 351, 300, {
    expect_message(r <- e$app_fit_plot(bad), "app_fit_plot: left as drawn")
    expect_identical(r, bad)
  })
})

test_that("6. the tension chart puts its names above the bars only when they do not fit beside them", {
  skip_if_no_fit(); e <- .pf_env
  d <- data.frame(par = rep(c("seas_lag_p_NH", "seas_T_lag", "tau_ex"), 2),
                  fam = c("CO₂ seasonal cycle", "δ¹³C seasonal cycle", "CO₂ north–south gradient",
                          "δ¹³C seasonal cycle", "CO₂ seasonal cycle", "δ¹³C level & gradient"),
                  v = c(2.2, 1.9, 0.9, -2.2, -1.9, -0.9))
  pf_at(e, 351, 320, expect_true(e$cmap_tension_names_above(d)))
  pf_at(e, 744, 320, expect_false(e$cmap_tension_names_above(d)))
  e$app_clear_panel_px()
  expect_false(e$cmap_tension_names_above(d))     # no live width: the desktop layout
  # ...and the chart itself follows the rule: thinner bars, names above, on the phone only
  tn <- list(par = d$par[1:3], up = d$fam[1:3], down = d$fam[4:6], up_pull = d$v[1:3], down_pull = d$v[4:6])
  local({
    assign("APP_CMAP_NOTE", "A stand-in note.", envir = e)
    bar_w <- function() with(ggplot2::ggplot_build(e$plot_constraint_tension(tn))$data[[1]], max(ymax - ymin))
    pf_at(e, 351, 320, expect_equal(bar_w(), 0.45))
    pf_at(e, 744, 320, expect_equal(bar_w(), 0.62))
  })
})

test_that("7. renderPlotFit() sends every visible plot through app_fit_plot()", {
  src <- readLines(file.path(.root, "app", "server.R"), warn = FALSE)
  body <- src[grep("renderPlotFit <- function", src):length(src)][1:12]
  expect_length(grep("app_fit_plot(res$value)", body, fixed = TRUE), 1L)
})

# ---- ui.R: every sidebar tab leads with its takeaway on a phone ----------------
# Returns the problems found in ui.R's parsed code: a bare mainPanel() outside main_panel()'s own definition,
# or a main_panel() whose `lead` has no takeaway().
pf_ui_problems <- function(exprs) {
  out <- character(0)
  calls_in <- function(x, fn) {
    if (!is.call(x)) return(list())
    here <- if (identical(x[[1]], as.name(fn))) list(x) else list()
    c(here, unlist(lapply(as.list(x)[-1], calls_in, fn = fn), recursive = FALSE))
  }
  for (ex in exprs) {
    is_def <- is.call(ex) && identical(ex[[1]], as.name("<-")) && identical(ex[[2]], as.name("main_panel"))
    if (!is_def && length(calls_in(ex, "mainPanel")))
      out <- c(out, "a bare mainPanel() outside main_panel()")
    for (mp in calls_in(ex, "main_panel")) {
      lead <- match.call(function(lead, ...) NULL, mp)$lead     # named or first positional, as R binds it
      if (is.null(lead) || !length(calls_in(lead, "takeaway")))
        out <- c(out, "a main_panel() whose lead has no takeaway()")
    }
  }
  out
}

test_that("8. every sidebar tab is built with main_panel(), its lead carrying the takeaway", {
  ui <- parse(file.path(.root, "app", "ui.R"), keep.source = FALSE)
  expect_identical(pf_ui_problems(ui), character(0))
  n_mp <- sum(vapply(as.list(ui), function(x) length(grep("main_panel(", deparse(x), fixed = TRUE)), 0L))
  expect_gte(n_mp, 6L)   # the six sidebar tabs (plus main_panel's own definition)
  # MUTATIONS: the checker must catch each defect it is for
  expect_match(pf_ui_problems(parse(text = "sidebarLayout(sidebarPanel(), mainPanel(width = 9, p('x')))")),
               "bare mainPanel", all = FALSE)
  expect_match(pf_ui_problems(parse(text = "main_panel(lead = tagList(plotOutput('k')), p('x'))")),
               "no takeaway", all = FALSE)
  expect_match(pf_ui_problems(parse(text = "main_panel(lead = h5('x'), takeaway(textOutput('t')))")),
               "no takeaway", all = FALSE)   # the takeaway left in the rest, after the controls
  expect_identical(pf_ui_problems(parse(text = "main_panel(tagList(takeaway(textOutput('t'))), p('x'))")),
                   character(0))             # a positional lead is still the lead
})
