# =====================================================================
# Gate: the banner names the short address (2026-10-21).
#
# https://carbotope.org forwards to the app (app/DEPLOY.md, "The short address"). Post 1 and the first days of
# sharing used the long Connect Cloud address, so the banner on every tab ends "Short link: CarboTope.org"
# (Marcus chose the place and the words). What can go wrong silently: the banner stops showing it, or the
# address shown and the address linked come apart. The banner function is taken from ui.R and run on the
# SHIPPED constants from global.R (only their assignments are evaluated: global.R itself compiles the model).
# Whether the forward itself works is a network fact, checked live at deploy, not here.
# =====================================================================

.sl_app <- file.path(.root, "app")
.sl_assignments <- function(file, names) {
  out <- list()
  for (e in parse(file, keep.source = FALSE))
    if (is.call(e) && identical(e[[1]], as.name("<-")) && is.name(e[[2]]) && as.character(e[[2]]) %in% names)
      out[[as.character(e[[2]])]] <- e
  out
}
.sl_consts <- c("APP_SHORT_LINK_LEAD", "APP_SHORT_LINK_LABEL", "APP_SHORT_URL", "app_link_ok")

# The banner as ui.R defines it, in an env holding the shipped constants and stand-ins for what it reads from
# the running app (the fit status, the release name, the review tab's title). `edit` rewrites the constants'
# source first, for the mutations.
sl_banner_html <- function(edit = identity) {
  env <- new.env(parent = globalenv())
  assign("app_params", list(has_posterior = TRUE, status = "single best fit"), envir = env)
  assign("APP_RELEASE_NAME", "BETA v1.0 CarboTope", envir = env)
  assign("RV_TAB_TITLE", "Known issues", envir = env)
  for (e in .sl_assignments(file.path(.sl_app, "global.R"), .sl_consts)) eval(edit(e), env)
  eval(.sl_assignments(file.path(.sl_app, "ui.R"), "provenance_banner")[[1]], env)
  as.character(env$provenance_banner())
}
sl_check <- function(html) {
  a <- regmatches(html, gregexpr("<a [^>]*>[^<]*</a>", html))[[1]]
  a <- a[grepl("carbotope", a, ignore.case = TRUE)]
  text <- gsub("\\s+", " ", gsub("<[^>]+>", "", html))
  c(one_link     = length(a) == 1L,
    href_matches = length(a) == 1L &&
                     identical(sub('.*href="([^"]*)".*', "\\1", a), paste0("https://", tolower(gsub("<[^>]+>", "", a)))),
    new_tab      = length(a) == 1L && grepl('target="_blank"', a, fixed = TRUE),
    ends_with    = grepl("Short link: CarboTope\\.org\\s*$", text))
}

test_that("the banner ends with the short address, linked to itself, in a new tab", {
  skip_if_not_installed("shiny")
  library(shiny)
  r <- sl_check(sl_banner_html())
  expect_true(all(r), info = paste(names(r)[!r], collapse = ", "))
})

test_that("MUTATION: the check rejects a missing link, a label that differs from the link, and a same-tab link", {
  skip_if_not_installed("shiny")
  library(shiny)
  swap <- function(name, value) function(e) {
    if (identical(as.character(e[[2]]), name)) e[[3]] <- value
    e
  }
  # The URL guarded off: the banner loses the sentence.
  expect_false(sl_check(sl_banner_html(swap("APP_SHORT_URL", "SET-BEFORE-DEPLOY")))[["one_link"]])
  # A hand-typed URL that no longer matches the label shown.
  expect_false(sl_check(sl_banner_html(swap("APP_SHORT_URL", "https://carbotope.com")))[["href_matches"]])
  # A different lead: the shipped words are Marcus's.
  expect_false(sl_check(sl_banner_html(swap("APP_SHORT_LINK_LEAD", "Also at")))[["ends_with"]])
  # A same-tab link (ui.R edited in memory).
  html <- sub(' target="_blank"', "", sl_banner_html(), fixed = TRUE)
  expect_false(sl_check(html)[["new_tab"]])
})
