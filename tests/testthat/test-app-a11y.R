# =====================================================================
# Gate: what a screen reader and a first-time visitor get (2026-10-21, the pre-redeploy scan; Marcus:
# "Mechanical fixes 1-9", "Drafts 10 and 11 as written").
#
#   1. Every chart's alt text is its name from the download registry (APP_DL_SPEC). Before, Shiny fell back to
#      ggplot2::get_alt_text(), which is "" for these plots, so a screen reader skipped all of them.
#      2026-10-25 (Marcus: "Yes, fix the alt text"): the name of the chart AS DRAWN (app_dl_spec_for). The Futures
#      chart read "Futures" in all six views (three pills x CO2 / temperature); it now names each one.
#   2. Every download link's accessible name carries its chart's name (thirty links all read "data (CSV)").
#   3. Futures -> Build your own says what to do before "Run it" is pressed; its takeaway bar was empty.
#   4. The page has a language, and every link that opens a new tab says so to a screen reader (and has
#      rel = "noopener").
# 1-3 run the real server (testServer); 4 reads the source. Each check is paired with a broken case it rejects.
# =====================================================================

.ay_app_dir <- file.path(.root, "app")
.ay_files <- file.path(.ay_app_dir, c("ui.R", "server.R", "global.R", "R/downloads.R", "R/review.R"))
skip_if_no_app <- function() {
  skip_if_not_installed("shiny"); skip_if_not_installed("ggplot2"); skip_if_not_installed("bslib")
  skip_if(!all(file.exists(.ay_files)), "app files absent")
  skip_if_no_cpp(); skip_if_no_climate()
}

# A chart's alt text is right when it is its registry name: non-empty and that chart's, not another's.
ay_alt_ok <- function(alt, chart) is.character(alt) && length(alt) == 1L && nzchar(alt) && identical(alt, chart)

test_that("1b. the Futures chart's alt text names its view, in all six (2026-10-25)", {
  skip_if_no_app()
  app <- suppressMessages(shiny::shinyAppDir(.ay_app_dir))
  shiny::testServer(app, {
    AE <- environment(renderPlotFit); A <- function(nm) get(nm, envir = AE)
    tbl <- A("APP_DL_FUTURE_CHART")
    # keyed by the real pills and y variables (a key that drifts from ui.R would draw the default view below)
    expect_setequal(names(tbl), c("Scenarios", "Build your own", "Pulse lab"))
    for (m in names(tbl)) expect_setequal(names(tbl[[m]]), unname(A("APP_FUTURE_YVARS")))
    d <- A("APP_PULSE_DEFAULTS")
    session$setInputs(tabs = "Futures", f_scen = c("vvL", "vvM", "vvH"), f_fair = FALSE,
                      s_kind = "constant", s_bg = "vvM", s_go = 1, p_bg = d$p_bg, p_gtc = d$p_gtc, p_year = d$p_year)
    seen <- character(0)
    for (m in names(tbl)) for (y in unname(A("APP_FUTURE_YVARS"))) {
      session$setInputs(f_mode = m, f_yvar = y)
      alt <- output$f_plot$alt
      expect_true(ay_alt_ok(alt, unname(tbl[[m]][[y]])), info = sprintf("%s / %s: alt %s", m, y, deparse(alt)))
      expect_true(ay_alt_ok(alt, A("app_dl_spec_for")("f_plot", m, y)$chart), info = paste(m, y))
      seen <- c(seen, alt)
    }
    expect_length(unique(seen), 6L)                        # six views, six names
    expect_false(A("app_dl_spec")("f_plot")$chart %in% seen) # the registry's bare "Futures" (the old alt) is gone
    # an unknown view keeps the registry name rather than an NA alt
    expect_identical(A("app_dl_spec_for")("f_plot", "No such pill", "co2_ppm")$chart, A("app_dl_spec")("f_plot")$chart)
    expect_identical(A("app_dl_spec_for")("f_plot", NULL, NULL)$chart, A("app_dl_spec")("f_plot")$chart)
  })
})

test_that("1-3. charts carry their names, download links name their chart, Build your own asks for the press", {
  skip_if_no_app()
  app <- suppressMessages(shiny::shinyAppDir(.ay_app_dir))
  shiny::testServer(app, {
    AE <- environment(renderPlotFit)
    A <- function(nm) get(nm, envir = AE)
    mech_drv <- names(Filter(function(m) !is.null(m$driver), A("CCX_MECHANISMS")))
    session$setInputs(tabs = "The Keeling Curve", k_years = c(1958, 2024), k_hemi = "both", k_obs = TRUE,
                      w_years = c(1850, 2024), c_mech = mech_drv, c_years = c(1850, 2024),
                      i_years = c(1940, 2024), i_hemi = "both", f_mode = "Scenarios",
                      f_scen = c("vvL", "vvM", "vvH"), f_yvar = "co2_ppm", f_fair = FALSE, cm_level = "component")
    ids <- ls(dl_plots)
    expect_gt(length(ids), 20L)
    n_checked <- 0L
    for (id in ids) {
      sp <- A("app_dl_spec")(id)
      if (is.null(sp)) next
      out <- tryCatch(output[[id]], error = function(e) NULL)
      if (is.null(out)) next   # a chart this view does not draw
      now <- A("app_dl_spec_for")(id, input$f_mode, input$f_yvar)
      expect_true(ay_alt_ok(out$alt, now$chart), info = sprintf("%s: alt %s", id, deparse(out$alt)))
      n_checked <- n_checked + 1L
      html <- as.character(A("app_dl_links")(id))
      want <- function(lab) sprintf('aria-label="%s"', htmltools::htmlEscape(paste0(sp$chart, ": ", lab), attribute = TRUE))
      expect_true(grepl(want(A("APP_DL_LABEL_CSV")), html, fixed = TRUE), info = id)
      expect_true(grepl(want(A("APP_DL_LABEL_PNG")), html, fixed = TRUE), info = id)
    }
    expect_gt(n_checked, 15L)
    # Build your own: the prompt until the button is pressed, then the run's own sentence.
    session$setInputs(f_mode = "Build your own", s_kind = "constant", s_bg = "vvM", s_go = 0)
    expect_identical(output$f_takeaway, A("APP_BUILD_PROMPT"))
    expect_true(grepl("“Run it”", A("APP_BUILD_PROMPT"), fixed = TRUE))
    session$setInputs(s_go = 1)
    expect_true(startsWith(output$f_takeaway, "Your pathway reaches"))
    # Pulse lab (Marcus 2026-10-21, "5"): at settings with no result, the prompt; at the defaults, the stored run.
    d <- A("APP_PULSE_DEFAULTS")
    session$setInputs(f_mode = "Pulse lab", p_bg = d$p_bg, p_gtc = d$p_gtc + 100, p_year = d$p_year)
    expect_identical(output$f_takeaway, A("APP_PULSE_PROMPT"))
    expect_identical(A("APP_PULSE_PROMPT"), "Release the pulse to see results at these settings.")
    session$setInputs(p_gtc = d$p_gtc)
    expect_true(startsWith(output$f_takeaway, sprintf("Release %d GtC in %d", as.integer(d$p_gtc), as.integer(d$p_year))))
  })
})

test_that("MUTATION: the alt check rejects an empty alt, a missing one, and another chart's name", {
  expect_true(ay_alt_ok("CO₂ at Mauna Loa and the South Pole", "CO₂ at Mauna Loa and the South Pole"))
  expect_false(ay_alt_ok("", "CO₂ at Mauna Loa and the South Pole"))           # Shiny's fallback before the fix
  expect_false(ay_alt_ok(NULL, "CO₂ at Mauna Loa and the South Pole"))
  expect_false(ay_alt_ok("Airborne fraction", "CO₂ at Mauna Loa and the South Pole"))
})

# ---- 4. static: lang, and every new-tab link ---------------------------------------------------------------
# Each tags$a(...) call that sets target = "_blank", as source text, must also set rel = "noopener" and an
# aria-label that ends with APP_NEW_TAB_NOTE.
ay_new_tab_problems <- function(src_text) {
  calls <- regmatches(src_text, gregexpr("tags\\$a\\((?:[^()]|\\((?:[^()]|\\([^()]*\\))*\\))*\\)", src_text, perl = TRUE))[[1]]
  calls <- calls[grepl('target = "_blank"', calls, fixed = TRUE)]
  bad <- calls[!(grepl('rel = "noopener"', calls, fixed = TRUE) &
                 grepl("`aria-label` =", calls, fixed = TRUE) & grepl("APP_NEW_TAB_NOTE", calls, fixed = TRUE))]
  list(n = length(calls), bad = bad)
}
ay_src <- function() paste(unlist(lapply(file.path(.ay_app_dir, c("ui.R", "R/review.R")), readLines, warn = FALSE)),
                           collapse = "\n")

test_that("4. the page has a language, and every new-tab link says so and sets rel = noopener", {
  skip_if(!all(file.exists(.ay_files)), "app files absent")
  ui <- paste(readLines(file.path(.ay_app_dir, "ui.R"), warn = FALSE), collapse = "\n")
  expect_true(grepl('navbarPage(', ui, fixed = TRUE) && grepl('title = APP_TITLE,\\s*\\n\\s*lang = "en"', ui))
  r <- ay_new_tab_problems(ay_src())
  expect_gte(r$n, 4L)   # the card links, the repository, the short link, the Substack word
  expect_identical(r$bad, character(0))
})

test_that("MUTATION: the new-tab check catches a link without rel and one without the note", {
  skip_if(!all(file.exists(.ay_files)), "app files absent")
  src <- ay_src()
  no_rel <- sub('rel = "noopener",', "", src, fixed = TRUE)
  expect_length(ay_new_tab_problems(no_rel)$bad, 1L)
  no_note <- sub("`aria-label` = paste0(APP_REPO_URL, APP_NEW_TAB_NOTE), ", "", src, fixed = TRUE)
  expect_false(identical(no_note, src))
  expect_length(ay_new_tab_problems(no_note)$bad, 1L)
})
