# =====================================================================
# test-app-session-log.R -- the per-visit log lines (app/R/sessionlog.R, 2026-11-02).
#
# Marcus 2026-11-02 ("Yes, add the session logging"): the host's meter cannot say whether anyone uses the app.
#   1. The user-agent class separates our headless checks and crawlers from people.
#   2. The referrer is reduced to a host name: no path, query or credentials reach the log.
#   3. A session's lines: start and end, paired by id; tabs in visiting order; a change is a value that differs
#      from the last one seen (a first appearance is not one, nor a tab switch, nor the referrer).
#   4. The referrer never travels in a shared link, for any tab or Futures pill.
#   5. The real server writes both lines; ui.R loads the script; the script sends only the host.
# 1-3 run sessionlog.R on its own; 4-5 run the app. Each is mutation-tested
# (outputs/diagnostics/session_log_20261102/mutate_session_log.sh).
# =====================================================================

.sl_file <- file.path(.root, "app", "R", "sessionlog.R")
.sl_env <- local({
  e <- new.env(parent = globalenv())
  assign("APP_LINK_TAB_INPUT", "tabs", envir = e)       # links.R's value; test 4 reads the real one
  ok <- tryCatch({ suppressMessages(library(shiny)); sys.source(.sl_file, envir = e); TRUE }, error = function(err) FALSE)
  if (ok) e else NULL
})
skip_if_no_sl <- function() { skip_if_not_installed("shiny"); skip_if(is.null(.sl_env), "sessionlog.R did not load") }

.sl_app_dir <- file.path(.root, "app")
skip_if_no_app_sl <- function() {
  skip_if_not_installed("shiny"); skip_if_not_installed("bslib")
  skip_if(!file.exists(file.path(.sl_app_dir, "ui.R")), "app absent")
  skip_if_no_cpp(); skip_if_no_climate()
}
# the JSON half of a log line
sl_rec <- function(line) {
  expect_true(startsWith(line, "CCX_SESSION {"))
  jsonlite::fromJSON(sub("^CCX_SESSION ", "", line), simplifyVector = TRUE)
}

test_that("1. user agents are classed: headless, bot, mobile, desktop, unknown", {
  skip_if_no_sl(); e <- .sl_env
  ua <- c(headless = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/155.0.0.0 Safari/537.36",
          bot      = "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)",
          bot      = "facebookexternalhit/1.1",
          mobile   = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1",
          mobile   = "Mozilla/5.0 (Linux; Android 15) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Mobile Safari/537.36",
          desktop  = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36",
          desktop  = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:140.0) Gecko/20100101 Firefox/140.0")
  for (i in seq_along(ua)) expect_identical(e$app_ua_class(ua[[i]]), names(ua)[i], info = ua[[i]])
  for (x in list(NULL, "", NA_character_, c("a", "b"), 3)) expect_identical(e$app_ua_class(x), "unknown")
})

test_that("2. a referrer is reduced to its host name", {
  skip_if_no_sl(); e <- .sl_env
  cases <- c("https://www.reddit.com/r/climatechange/comments/abc123/looking_for_feedback/?utm=x#c" = "reddit.com",
             "https://old.reddit.com/r/climate" = "old.reddit.com",
             "https://user:secret@example.org:8443/path?q=1" = "example.org",
             "http://saraphreport.substack.com/p/post-2" = "saraphreport.substack.com",
             "t.co" = "t.co",                                          # what the browser script sends: a host
             "android-app://com.reddit.frontpage/" = "com.reddit.frontpage")
  for (k in names(cases)) {
    got <- e$app_ref_host(k)
    expect_identical(got, cases[[k]], info = k)
    expect_false(grepl("[/?#:@]", got), info = k)                       # nothing past the host survives
  }
  for (x in list(NULL, "", NA_character_, c("a", "b"))) expect_identical(e$app_ref_host(x), "none")
})

test_that("3. a session writes a start and an end line; changes, tabs and the referrer are tallied", {
  skip_if_no_sl(); e <- .sl_env
  lines <- character(0)
  clk <- new.env(); clk$t <- as.POSIXct("2026-11-02 13:00:00", tz = "UTC")
  srv <- function(input, output, session)
    e$app_session_log_server(input, session, now = function() clk$t, emit = function(l) lines <<- c(lines, l))
  shiny::testServer(srv, {
    session$setInputs(tabs = "The Keeling Curve", k_years = c(1958, 2024), k_hemi = "both")   # the first flush
    session$setInputs(ccx_referrer = "reddit.com")                     # arrives after connect: not a change
    session$setInputs(k_hemi = "NH")
    session$setInputs(tabs = "Futures", f_mode = "Scenarios")          # a tab switch, and a control drawn later
    session$setInputs(k_hemi = "SH", k_years = c(1958, 2024))          # k_years re-sent unchanged: not a change
    session$setInputs(tabs = "The Keeling Curve")
    clk$t <- clk$t + 412
    session$close()
  })
  expect_length(lines, 2L)
  s <- sl_rec(lines[1]); x <- sl_rec(lines[2])
  expect_identical(c(s$event, x$event), c("start", "end"))
  expect_identical(s$id, x$id); expect_true(nzchar(s$id))
  expect_identical(x$start, "2026-11-02T13:00:00Z")
  expect_identical(x$dur_s, 412L)
  expect_identical(x$ref, "reddit.com")
  expect_identical(x$tabs, c("The Keeling Curve", "Futures", "The Keeling Curve"))
  expect_identical(x$n_changes, 2L)
  expect_identical(x$changed, "k_hemi")
  expect_identical(x$client, "unknown")                                # the mock session has no user agent
  expect_null(s$ref); expect_null(s$tabs)                              # the start line carries no tally
})

test_that("4. the referrer never travels in a shared link, for any tab or Futures pill", {
  skip_if_no_app_sl()
  app <- suppressMessages(shiny::shinyAppDir(.sl_app_dir))
  shiny::testServer(app, {
    AE <- environment(renderPlotFit); A <- function(nm) get(nm, envir = AE)
    ref <- A("APP_SESSION_REF_INPUT")
    tabs <- names(A("app_link_inputs")())
    expect_gt(length(tabs), 5L)
    for (tb in tabs) expect_false(ref %in% A("app_link_keep")(stats::setNames(list(tb, "reddit.com"), c("tabs", ref))),
                                  info = tb)
    for (pill in names(A("APP_LINK_PILL_INPUTS")))
      expect_false(ref %in% A("app_link_keep")(stats::setNames(list("Futures", pill, "reddit.com"), c("tabs", "f_mode", ref))),
                   info = pill)
  })
})

test_that("5. the real server writes both lines; ui.R loads the script; the script sends only the host", {
  skip_if_no_app_sl()
  app <- suppressMessages(shiny::shinyAppDir(.sl_app_dir))
  err <- utils::capture.output(type = "message", {
    shiny::testServer(app, {
      AE <- environment(renderPlotFit); A <- function(nm) get(nm, envir = AE)
      mech_drv <- names(Filter(function(m) !is.null(m$driver), A("CCX_MECHANISMS")))
      # every input in the first call, as test-app-a11y does: charts drawn with NULL inputs warn
      session$setInputs(tabs = "The Keeling Curve", k_years = c(1958, 2024), k_hemi = "both", k_obs = TRUE,
                        w_years = c(1850, 2024), c_mech = mech_drv, c_years = c(1850, 2024),
                        i_years = c(1940, 2024), i_hemi = "both", f_mode = "Scenarios",
                        f_scen = c("vvL", "vvM", "vvH"), f_yvar = "co2_ppm", f_fair = FALSE, cm_level = "component")
      session$setInputs(k_hemi = "NH")
      session$close()
    })
  })
  got <- grep("^CCX_SESSION ", err, value = TRUE)
  expect_length(got, 2L)
  if (length(got) == 2L) {
    x <- sl_rec(got[2])
    expect_identical(x$event, "end"); expect_identical(x$n_changes, 1L); expect_identical(x$changed, "k_hemi")
  }
  ui <- readLines(file.path(.sl_app_dir, "ui.R"), warn = FALSE)
  expect_length(grep("tags$script(HTML(APP_SESSION_JS))", ui, fixed = TRUE), 1L)
  skip_if_no_sl()
  expect_true(grepl("new URL(document.referrer).hostname", .sl_env$APP_SESSION_JS, fixed = TRUE))
  expect_false(grepl("setInputValue\\([^)]*document\\.referrer", .sl_env$APP_SESSION_JS))
})
