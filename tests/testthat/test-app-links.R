# =====================================================================
# test-app-links.R -- deep links (app/R/links.R, 2026-10-20).
#
# What a link carries is a per-tab list (APP_LINK_INPUTS, APP_LINK_PILL_INPUTS). The
# failure this file exists to catch is SILENT: an input added to ui.R and to no list
# simply never travels in a link, and a renamed tab leaves its list keyed on a title
# that no longer exists -- both still produce a working link, to the wrong view. So
# every input id in ui.R must be in a list or in APP_LINK_NOT_CARRIED, every list key
# must be a tab ui.R draws, and each lint is mutation-tested.
# The restore itself is checked by building ui.R's UI function under a restore
# context made from a query string (shiny internals: skipped if they move). The
# round trip in a real browser, tab by tab, is outputs/diagnostics/deeplinks_20261020/.
# =====================================================================

.lk_app_dir <- file.path(.root, "app")
.lk_ui <- file.path(.lk_app_dir, "ui.R")

skip_if_no_app_lk <- function() {
  skip_if_not_installed("shiny"); skip_if_not_installed("bslib")
  skip_if(!file.exists(.lk_ui), "app/ui.R absent")
  skip_if_no_cpp(); skip_if_no_climate()
}

# every call in a file, as calls
.lk_calls <- function(file) {
  out <- list()
  walk <- function(e, parent = NULL) {
    if (is.call(e)) {
      out[[length(out) + 1L]] <<- e
      for (a in as.list(e)[-1]) if (!missing(a)) walk(a)
    }
  }
  for (e in parse(file, keep.source = FALSE, encoding = "UTF-8")) walk(e)
  out
}
.lk_fn <- function(e) if (is.name(e[[1]])) as.character(e[[1]]) else ""
LK_INPUT_FNS <- c("sliderInput", "radioButtons", "checkboxInput", "checkboxGroupInput", "selectInput",
                  "selectizeInput", "numericInput", "textInput", "textAreaInput", "dateInput",
                  "dateRangeInput", "actionButton", "actionLink", "fileInput", "passwordInput")

#' Every input id ui.R creates: the controls' first argument, and the nav containers' `id`
lk_ui_input_ids <- function(file = .lk_ui) {
  ids <- character()
  for (e in .lk_calls(file)) {
    f <- .lk_fn(e)
    if (f %in% LK_INPUT_FNS && length(e) >= 2L) {
      a <- if (!is.null(e$inputId)) e$inputId else e[[2]]
      if (is.character(a)) ids <- c(ids, a)
    }
    if (f %in% c("tabsetPanel", "navbarPage", "navset_pill", "navset_tab") && is.character(e$id)) ids <- c(ids, e$id)
  }
  unique(ids)
}

#' The titles of the tabPanel()s directly inside a container call
lk_child_tabs <- function(call, env) {
  kids <- Filter(function(a) is.call(a) && identical(.lk_fn(a), "tabPanel"), as.list(call)[-1])
  vapply(kids, function(k) as.character(eval(k[[2]], env)), "")
}
lk_container <- function(file, fn, id) {
  for (e in .lk_calls(file)) if (identical(.lk_fn(e), fn) && identical(e$id, id)) return(e)
  NULL
}

#' The lint: problems with the link lists against ui.R's inputs and tabs
lk_lint <- function(ui_ids, tab_titles, pill_titles, inputs, pill_inputs, not_carried, tab_id, pill_id) {
  carried <- c(tab_id, unlist(inputs), unlist(pill_inputs))
  c(if (length(x <- setdiff(ui_ids, c(carried, names(not_carried)))))
      sprintf("in ui.R but in no link list and not in APP_LINK_NOT_CARRIED: %s", paste(x, collapse = ", ")),
    if (length(x <- setdiff(c(carried, names(not_carried)), ui_ids)))
      sprintf("in a link list but not an input in ui.R: %s", paste(x, collapse = ", ")),
    if (length(x <- intersect(carried, names(not_carried))))
      sprintf("both carried and not carried: %s", paste(x, collapse = ", ")),
    if (!setequal(names(inputs), tab_titles))
      sprintf("link lists keyed %s; ui.R's tabs are %s", paste(sort(names(inputs)), collapse = " | "),
              paste(sort(tab_titles), collapse = " | ")),
    if (!setequal(names(pill_inputs), pill_titles))
      sprintf("pill lists keyed %s; ui.R's pills are %s", paste(sort(names(pill_inputs)), collapse = " | "),
              paste(sort(pill_titles), collapse = " | ")))
}

test_that("1. every input in ui.R travels in a link or is listed as not carried; every list names a real tab (mutation-tested)", {
  skip_if_no_app_lk()
  app <- suppressMessages(shiny::shinyAppDir(.lk_app_dir))
  shiny::testServer(app, {
    AE <- environment(renderPlotFit); A <- function(nm) get(nm, envir = AE)
    nav <- lk_container(.lk_ui, "navbarPage", A("APP_LINK_TAB_INPUT"))
    pills <- lk_container(.lk_ui, "tabsetPanel", A("APP_LINK_PILL_INPUT"))
    expect_false(is.null(nav)); expect_false(is.null(pills))
    tabs <- lk_child_tabs(nav, AE); pill_t <- lk_child_tabs(pills, AE)
    expect_gte(length(tabs), 8L)
    ids <- lk_ui_input_ids()
    expect_gte(length(ids), 20L)
    args <- list(ui_ids = ids, tab_titles = tabs, pill_titles = pill_t, inputs = A("app_link_inputs")(),
                 pill_inputs = A("APP_LINK_PILL_INPUTS"), not_carried = A("APP_LINK_NOT_CARRIED"),
                 tab_id = A("APP_LINK_TAB_INPUT"), pill_id = A("APP_LINK_PILL_INPUT"))
    expect_identical(do.call(lk_lint, args), NULL)
    # MUTATIONS: each must be reported
    m <- args; m$ui_ids <- c(ids, "new_slider");                          expect_length(do.call(lk_lint, m), 1L)
    m <- args; m$inputs[["The Keeling Curve"]] <- "k_years";              expect_length(do.call(lk_lint, m), 1L)
    m <- args; names(m$inputs)[1] <- "The Keeling curve";                 expect_length(do.call(lk_lint, m), 1L)
    m <- args; m$tab_titles <- c(tabs, "A new tab");                      expect_length(do.call(lk_lint, m), 1L)
    m <- args; m$pill_inputs[["Pulse lab"]] <- c("p_bg", "p_gtc");        expect_length(do.call(lk_lint, m), 1L)
    m <- args; m$not_carried <- c(m$not_carried, k_obs = "x");             expect_length(do.call(lk_lint, m), 1L)
    m <- args; m$ui_ids <- setdiff(ids, "s_go");                          expect_length(do.call(lk_lint, m), 1L)
  })
})

test_that("2. a link carries the open tab's settings and its pill's, and nothing else; it presses no button", {
  skip_if_no_app_lk()
  app <- suppressMessages(shiny::shinyAppDir(.lk_app_dir))
  shiny::testServer(app, {
    AE <- environment(renderPlotFit); A <- function(nm) get(nm, envir = AE)
    keep <- A("app_link_keep")
    expect_setequal(keep(list(tabs = "The Keeling Curve", f_mode = "Pulse lab")),
                    c("tabs", "k_years", "k_hemi", "k_obs"))
    expect_setequal(keep(list(tabs = "Futures", f_mode = "Pulse lab")),
                    c("tabs", "f_mode", "f_yvar", "f_fair", "p_bg", "p_gtc", "p_year"))
    expect_setequal(keep(list(tabs = "Futures", f_mode = "Scenarios")),
                    c("tabs", "f_mode", "f_yvar", "f_fair", "f_scen"))
    expect_setequal(keep(list(tabs = "Futures", f_mode = "Build your own")),
                    c("tabs", "f_mode", "f_yvar", "f_fair", "s_kind", "s_zero_year", "s_rate", "s_bg"))
    expect_setequal(keep(list(tabs = A("RV_TAB_TITLE"))), "tabs")
    expect_setequal(keep(list()), "tabs")
    # the buttons are never carried: a click count is not a setting, and a link never presses one
    # (Marcus 2026-10-20). Every button ui.R draws is in APP_LINK_NOT_CARRIED.
    expect_false(any(names(A("APP_LINK_NOT_CARRIED")) %in% unlist(A("app_link_inputs")())))
    btn <- unlist(lapply(.lk_calls(.lk_ui), function(e)
      if (.lk_fn(e) %in% c("actionButton", "actionLink") && is.character(e[[2]])) e[[2]]))
    expect_setequal(names(A("APP_LINK_NOT_CARRIED")), btn)
    # ...and no code path presses one: the server half sends no message and the page has no handler
    lk_src <- paste(readLines(file.path(.lk_app_dir, "R", "links.R"), warn = FALSE), collapse = "\n")
    expect_false(grepl("sendCustomMessage|\\.click\\(", lk_src))
  })
})

test_that("3. ui.R is a function of the request, and a query string restores the tab, the pill and the settings", {
  skip_if_no_app_lk()
  skip_if(!exists("RestoreContext", envir = asNamespace("shiny")) ||
            !exists("withRestoreContext", envir = asNamespace("shiny")), "shiny's restore internals moved")
  app <- suppressMessages(shiny::shinyAppDir(.lk_app_dir))
  shiny::testServer(app, {
    AE <- environment(renderPlotFit)
    env <- AE; while (!exists("app_link_keep", envir = env, inherits = FALSE)) env <- parent.env(env)
    ue <- new.env(parent = env)
    for (x in parse(.lk_ui, encoding = "UTF-8")) ui_fn <- eval(x, ue)
    expect_true(is.function(ui_fn))
    expect_identical(names(formals(ui_fn)), "request")
    html <- function(q) {
      rc <- get("RestoreContext", asNamespace("shiny"))$new(q)
      as.character(htmltools::renderTags(get("withRestoreContext", asNamespace("shiny"))(rc, ui_fn(NULL)))$html)
    }
    enc <- function(v) utils::URLencode(v, reserved = TRUE)
    active_pane <- function(h) regmatches(h, gregexpr('class="tab-pane[^"]*active[^"]*"[^>]*data-value="[^"]*"', h))[[1]]
    slider_from <- function(h, id) sub('.*data-from="([^"]*)".*', "\\1",
                                       regmatches(h, regexpr(sprintf('<input[^>]*id="%s"[^>]*>', id), h)))
    h0 <- html("")
    expect_true(any(grepl('data-value="The Keeling Curve"', active_pane(h0))))
    expect_identical(slider_from(h0, "p_gtc"), as.character(get("APP_PULSE_GtC_DEFAULT", envir = env)))
    q <- paste0("?_inputs_&tabs=", enc('"Futures"'), "&f_mode=", enc('"Pulse lab"'), "&p_gtc=200&p_year=2080")
    h1 <- html(q)
    expect_true(any(grepl('data-value="Futures"', active_pane(h1))))
    expect_true(any(grepl('data-value="Pulse lab"', active_pane(h1))))
    expect_identical(slider_from(h1, "p_gtc"), "200")
    expect_identical(slider_from(h1, "p_year"), "2080")
    # an emptied checkbox group stays empty (null), rather than falling back to its default tick
    h2 <- html(paste0("?_inputs_&tabs=", enc('"What if…?"'), "&c_mech=null"))
    expect_true(any(grepl('data-value="What if…?"', active_pane(h2), fixed = TRUE)))
    expect_false(grepl('<input type="checkbox" name="c_mech" value="[^"]*" checked', h2))
    expect_true(grepl('<input type="checkbox" name="c_mech" value="[^"]*" checked', h0))
  })
})
