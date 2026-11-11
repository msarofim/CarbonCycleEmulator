# =====================================================================
# test-landing-page.R -- the static landing page at carbotope.org (docs/, GitHub Pages; 2026-11-10).
#
# Marcus 2026-11-10 ("Go with option 1, the landing page with a button"): a plain page that crawlers and link
# previews can read without waking the app. Nothing else checks it: GitHub Pages serves whatever is committed.
#   1. Every address in it is the right one: the app's (README.md's "App:" line), the repository's and the
#      feedback post's (app/global.R's APP_REPO_URL / APP_FEEDBACK_URL).
#   2. The search and preview tags are there, absolute, and point at this site; the preview image exists at
#      the size the tags state.
#   3. A shared view (an address with a query) goes on to the app with its query; the app is woken only from
#      an event handler, never as the page loads.
#   4. Informal output: the bare name, no institution (~/.claude/CLAUDE.md, ruling R4); no draft markers.
# CCX_LANDING_DIR points the test at another copy (the mutation script,
# outputs/diagnostics/landing_page_20261110/mutate_landing_page.sh).
# =====================================================================

.lp_dir <- Sys.getenv("CCX_LANDING_DIR", file.path(.root, "docs"))
.lp_html <- function(f = "index.html") paste(readLines(file.path(.lp_dir, f), warn = FALSE, encoding = "UTF-8"), collapse = "\n")
.lp_const <- function(name) {
  l <- grep(sprintf("^%s\\s*<-", name), readLines(file.path(.root, "app", "global.R"), warn = FALSE), value = TRUE)
  sub('^[^"]*"([^"]+)".*$', "\\1", l[1])
}
.lp_meta <- function(h, key) {
  m <- regmatches(h, regexpr(sprintf('<meta (?:name|property)="%s" content="[^"]*">', key), h, perl = TRUE))
  if (length(m)) sub('.*content="([^"]*)".*', "\\1", m) else NA_character_
}
.lp_site <- "https://carbotope.org/"

test_that("1. every address on the page is the right one", {
  skip_if(!file.exists(file.path(.lp_dir, "index.html")), "landing page absent")
  h <- .lp_html()
  app <- sub(".*App: (https://\\S+).*", "\\1", grep("App: https://", readLines(file.path(.root, "README.md"), warn = FALSE), value = TRUE)[1])
  expect_match(app, "^https://.*\\.share\\.connect\\.posit\\.cloud/$")
  # every Connect Cloud address on the page is the app's (the button and both scripts)
  found <- regmatches(h, gregexpr("https://[a-z0-9.-]*connect\\.posit\\.cloud[^\"' ]*", h))[[1]]
  expect_length(found, 3L)
  expect_true(all(found == app), info = paste(unique(found), collapse = " "))
  expect_match(h, sprintf('<a class="button" id="open-app" href="%s">', app), fixed = TRUE)
  expect_match(h, sprintf('href="%s"', .lp_const("APP_REPO_URL")), fixed = TRUE)
  expect_match(h, sprintf('href="%s"', .lp_const("APP_FEEDBACK_URL")), fixed = TRUE)
  # every Substack link is the post (2026-11-11: a second one sits under the button)
  sub_links <- regmatches(h, gregexpr('href="https://[^"]*substack\\.com[^"]*"', h))[[1]]
  expect_gte(length(sub_links), 2L)
  expect_true(all(sub_links == sprintf('href="%s"', .lp_const("APP_FEEDBACK_URL"))), info = paste(unique(sub_links), collapse = " "))
  expect_match(.lp_html("404.html"), sprintf('href="%s"', app), fixed = TRUE)
})

test_that("2. search and preview tags are present, absolute, and the preview image matches them", {
  skip_if(!file.exists(file.path(.lp_dir, "index.html")), "landing page absent")
  h <- .lp_html()
  expect_match(h, "<title>[^<]{10,}</title>")
  expect_match(h, sprintf('<link rel="canonical" href="%s">', .lp_site), fixed = TRUE)
  for (k in c("description", "og:title", "og:description", "og:image:alt")) expect_gt(nchar(.lp_meta(h, k)), 5L, label = k)
  expect_identical(.lp_meta(h, "og:url"), .lp_site)
  expect_identical(.lp_meta(h, "twitter:card"), "summary_large_image")
  img <- .lp_meta(h, "og:image")
  expect_true(startsWith(img, .lp_site), info = img)
  png <- file.path(.lp_dir, sub(.lp_site, "", img, fixed = TRUE))
  expect_true(file.exists(png), info = png)
  if (file.exists(png)) {
    b <- readBin(png, "raw", 24L)
    expect_identical(b[1:8], as.raw(c(0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a)))
    wh <- c(sum(as.integer(b[17:20]) * 256^(3:0)), sum(as.integer(b[21:24]) * 256^(3:0)))
    expect_identical(wh, as.numeric(c(.lp_meta(h, "og:image:width"), .lp_meta(h, "og:image:height"))))
  }
  expect_match(.lp_html("404.html"), '<meta name="robots" content="noindex">', fixed = TRUE)
  expect_match(.lp_html("robots.txt"), "Allow: /", fixed = TRUE)
  # GitHub's own commit (2026-11-10, "Create CNAME") when the custom domain was set; without it the domain is dropped
  expect_identical(trimws(.lp_html("CNAME")), sub("^https://(.*)/$", "\\1", .lp_site))
})

test_that("3. a shared view goes on to the app; the app is woken only from an event handler", {
  skip_if(!file.exists(file.path(.lp_dir, "index.html")), "landing page absent")
  h <- .lp_html()
  head <- sub("</head>.*", "", h)
  expect_match(head, "if (location.search.length > 1) location.replace(APP + location.search + location.hash);", fixed = TRUE)
  # one fetch, inside warm(), which only the listeners call
  expect_length(gregexpr("fetch(", h, fixed = TRUE)[[1]], 1L)
  warm <- regmatches(h, regexpr("function warm\\(\\) \\{.*?\\n    \\}", h))
  expect_length(warm, 1L)
  expect_match(warm, "fetch(APP,", fixed = TRUE)
  expect_false(grepl("warm()", sub("function warm\\(\\) \\{", "", h), fixed = TRUE))   # never called directly
  expect_match(h, 'window.addEventListener(e, warm, { capture: true, passive: true })', fixed = TRUE)
})

test_that("3b. the page describes every tab the app has, by its name and in its order, one sentence each", {
  skip_if(!file.exists(file.path(.lp_dir, "index.html")), "landing page absent")
  # the app's tab list (app/R/links.R app_link_inputs(), which test-app-links holds to the UI), with its two constants
  lk <- paste(readLines(file.path(.root, "app", "R", "links.R"), warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  vec <- sub("(?s).*app_link_inputs <- function\\(\\).*?character\\(0\\)\\),\\s*c\\((.*?)\\)\\)\\s*\\n.*", "\\1", lk, perl = TRUE)
  rv <- sub('^[^"]*"([^"]+)".*$', "\\1", grep("^RV_TAB_TITLE\\s*<-", readLines(file.path(.root, "app", "R", "review.R"), warn = FALSE), value = TRUE)[1])
  tabs <- trimws(strsplit(vec, ",")[[1]])
  tabs <- ifelse(tabs == "RV_TAB_TITLE", rv, ifelse(tabs == "APP_CMAP_TAB", .lp_const("APP_CMAP_TAB"), gsub('"', "", tabs)))
  expect_length(tabs, 8L)
  h <- .lp_html()
  dt <- regmatches(h, gregexpr("<dt>[^<]*</dt>", h))[[1]]
  expect_identical(gsub("</?dt>", "", dt), tabs)
  dd <- gsub("\\s+", " ", trimws(gsub("</?dd>", "", regmatches(h, gregexpr("<dd>[^<]*</dd>", h))[[1]])))
  expect_length(dd, length(tabs))
  for (s in dd) {
    expect_length(gregexpr("[.!?](\\s|$)", s)[[1]], 1L)                   # one sentence
    expect_false(grepl("—", s), info = s)                            # no em-dash (Marcus's word list)
  }
})

test_that("4. informal output: the bare name, no institution; no draft markers", {
  skip_if(!file.exists(file.path(.lp_dir, "index.html")), "landing page absent")
  vis <- gsub("<!--.*?-->", "", .lp_html())                                  # comments are not shown
  expect_match(vis, "Made by Marcus C. Sarofim.", fixed = TRUE)
  expect_false(grepl("Marron|NYU|New York University|Johns Hopkins|EPCP", vis))
  expect_false(grepl("TODO|PLACEHOLDER|\\[DRAFT|XXX|SET-BEFORE-DEPLOY", vis))
})
