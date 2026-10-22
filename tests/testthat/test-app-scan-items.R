# =====================================================================
# Gate: the scan items Marcus approved on 2026-10-21 ("Do 1-7 and the 'own' fix. 8: ... 9: Do it. 10: End at the
# last observed year. 11: Do it.").
#
#   1. Unit glosses open on a tap and on keyboard focus (a touch screen never shows a title tooltip).
#   2. The Known-issue pointers on the teaching tabs link to a card that exists.
#   3. "Copy link to this view": one per tab, on the tab's first chart, copying the SHORT address.
#   4. The Keeling seasonal window ends at the last year Mauna Loa measured in full and the run covers.
#   5. The drivers table's Covers column is each driver file's span, and server.R types no year in it.
#   6. The growth note's "begins in" year is the product's first year.
# Copy rulings (the takeaway, units, the El Niño wording, the Pulse lab's one method line, "its peak") are in
# test-app-review-copy.R's AC_CHECKS_1021B. Each check here is paired with a broken case it rejects.
# =====================================================================

.si_app_dir <- file.path(.root, "app")
.si_files <- file.path(.si_app_dir, c("ui.R", "server.R", "global.R", "R/downloads.R", "R/links.R", "R/plots.R"))
skip_if_no_app <- function() {
  skip_if_not_installed("shiny"); skip_if_not_installed("ggplot2"); skip_if_not_installed("bslib")
  skip_if(!all(file.exists(.si_files)), "app files absent")
  skip_if_no_cpp(); skip_if_no_climate()
}

# ---- the checks, as functions, so each can be shown a broken case ----------------------------
# every <abbr> on the page is a gloss a tap or a keyboard can open, with its meaning in the span right after it
si_glosses_ok <- function(html) {
  ab <- regmatches(html, gregexpr('<abbr[^>]*>[^<]*</abbr>(<span class="gloss-meaning">)?', html))[[1]]
  n_all <- lengths(regmatches(html, gregexpr("<abbr", html)))
  length(ab) > 0L && length(ab) == n_all &&
    all(grepl('class="gloss"', ab, fixed = TRUE) & grepl('tabindex="0"', ab, fixed = TRUE) &
        grepl('</abbr><span class="gloss-meaning">', ab, fixed = TRUE))
}
# every see-card link points at an element id on the page
si_card_links_ok <- function(html) {
  hrefs <- sub('.*href="#([^"]+)".*', "\\1",
               regmatches(html, gregexpr('<a href="#[^"]+" class="ccx-see-card"', html))[[1]])
  length(hrefs) > 0L && all(vapply(hrefs, function(h) grepl(sprintf('id="%s"', h), html, fixed = TRUE), logical(1)))
}
# the seasonal window: complete Mauna Loa years only, capped at the run
si_co2 <- function(years, drop = NULL) {
  d <- expand.grid(month = 1:12, year = years)
  d <- data.frame(station = "MLO", year = d$year, month = d$month, co2_ppm = 400)
  if (!is.null(drop)) d <- d[!(d$year == drop[1] & d$month == drop[2]), ]
  d
}

test_that("1. every unit gloss has the class and tabindex; the CSS and JS open it", {
  skip_if_no_app()
  app <- suppressMessages(shiny::shinyAppDir(.si_app_dir))
  shiny::testServer(app, {
    AE <- environment(renderPlotFit)
    uienv <- new.env(parent = AE)
    ui <- source(file.path(.si_app_dir, "ui.R"), local = uienv, chdir = TRUE)$value
    req <- new.env(); req$QUERY_STRING <- ""
    html <- as.character(htmltools::renderTags(ui(req))$html)
    expect_true(si_glosses_ok(html))
    expect_gte(lengths(regmatches(html, gregexpr("<abbr", html))), 8L)
    cls <- get("GLOSS_OPEN_CLASS", uienv); mcl <- get("GLOSS_MEANING_CLASS", uienv)
    css <- get("GLOSS_CSS", uienv)
    expect_true(grepl(sprintf(".%s { display: none; }", mcl), css, fixed = TRUE))
    expect_true(grepl(sprintf(".gloss.%s + .%s", cls, mcl), css, fixed = TRUE))
    expect_true(grepl(sprintf(".gloss:focus-visible + .%s", mcl), css, fixed = TRUE))
    # the meaning shown is the title's text
    m1 <- regmatches(html, regexpr('<abbr title="[^"]*"[^>]*>[^<]*</abbr><span class="gloss-meaning">[^<]*</span>', html))
    expect_identical(sub('^<abbr title="([^"]*)".*', "\\1", m1),
                     sub('.*<span class="gloss-meaning"> \\((.*)\\)</span>$', "\\1", m1))
    expect_true(grepl(sprintf("classList.toggle('%s')", cls), get("GLOSS_JS", uienv), fixed = TRUE))
    expect_true(grepl("GLOSS_CSS", paste(readLines(file.path(.si_app_dir, "ui.R")), collapse = "\n"), fixed = TRUE))

    # 2. the see-card links, and the cards they point at
    expect_true(si_card_links_ok(html))
    expect_gte(lengths(regmatches(html, gregexpr('class="ccx-see-card"', html))), 2L)
    for (i in 1:8) expect_true(grepl(sprintf('id="%s"', get("rv_card_anchor", uienv)(i)), html, fixed = TRUE), info = i)
    expect_true(grepl("a.ccx-see-card", get("SEE_CARD_JS", uienv), fixed = TRUE))
    # 2026-10-22: the live host rewrites a clicked link's href before this handler runs, so the card id comes
    # from the link's hash and the handler must not read its href attribute.
    expect_true(grepl("getElementById(this.hash.slice(1))", get("SEE_CARD_JS", uienv), fixed = TRUE))
    expect_false(grepl("getAttribute('href').slice(1)", get("SEE_CARD_JS", uienv), fixed = TRUE))

    # 3. the share links: the seven static tabs carry one each (What pins down what? draws its chart in the server)
    expect_identical(lengths(regmatches(html, gregexpr('class="ccx-share"', html))), 7L)
    expect_true(grepl(sprintf('data-base="%s"', get("APP_SHORT_URL", AE)), html, fixed = TRUE))
  })
})

test_that("MUTATION: the gloss and card-link checks reject a bare abbr and a link to no card", {
  ok <- paste0('<p><abbr title="x" class="gloss" tabindex="0">ppm</abbr><span class="gloss-meaning"> (x)</span>',
               ' <a href="#issue-1" class="ccx-see-card">i</a></p><div id="issue-1"></div>')
  expect_true(si_glosses_ok(ok)); expect_true(si_card_links_ok(ok))
  expect_false(si_glosses_ok(sub(' tabindex="0"', "", ok, fixed = TRUE)))          # the pre-fix gloss
  expect_false(si_glosses_ok(sub(' class="gloss"', "", ok, fixed = TRUE)))
  expect_false(si_glosses_ok(sub('<span class="gloss-meaning"> (x)</span>', "", ok, fixed = TRUE)))
  expect_false(si_glosses_ok(paste0(ok, '<abbr title="y">GtC</abbr>')))             # one bare abbr among good ones
  expect_false(si_card_links_ok(sub('id="issue-1"', 'id="issue-9"', ok, fixed = TRUE)))
  expect_false(si_card_links_ok("<p>no links</p>"))
})

test_that("3. one share link per tab, on its first chart, copying the short address plus the view", {
  skip_if_no_app()
  app <- suppressMessages(shiny::shinyAppDir(.si_app_dir))
  shiny::testServer(app, {
    AE <- environment(renderPlotFit)
    A <- function(nm) get(nm, envir = AE)
    ids <- A("APP_SHARE_IDS")
    # one per tab, in navbar order: the ids' prefixes are the tabs' (k_ Keeling ... h_ Under the hood)
    expect_identical(length(ids), length(A("app_link_inputs")()))
    expect_identical(sub("_.*", "", ids), c("k", "w", "c", "i", "f", "rv", "cm", "h"))
    for (id in ids) {
      expect_false(is.null(A("app_dl_spec")(id)), info = id)          # so the chart has a download row
      expect_true(grepl("ccx-share", as.character(A("app_dl_links")(id)), fixed = TRUE), info = id)
    }
    expect_false(grepl("ccx-share", as.character(A("app_dl_links")("k_seasonal")), fixed = TRUE))
    expect_null(A("app_share_link")("k_seasonal"))
    js <- A("APP_SHARE_JS")
    expect_true(grepl("getAttribute('data-base') + '/' + window.location.search", js, fixed = TRUE))
    expect_true(grepl(jsonlite::toJSON(A("APP_SHARE_DONE"), auto_unbox = TRUE), js, fixed = TRUE))
    # What pins down what?: its chart is drawn by the server through the same wrapped plotOutput()
    session$setInputs(tabs = A("APP_CMAP_TAB"), cm_level = "component")
    expect_true(grepl("ccx-share", output$cm_map_ui$html, fixed = TRUE))
  })
})

test_that("4-6. the seasonal window, the drivers' spans and the growth note's year are read from the data", {
  skip_if_no_app()
  app <- suppressMessages(shiny::shinyAppDir(.si_app_dir))
  shiny::testServer(app, {
    AE <- environment(renderPlotFit)
    A <- function(nm) get(nm, envir = AE)
    # 4. the window on the live record, and on records built to break it
    sw <- A("app_seas_window")
    expect_identical(as.integer(A("APP_SEAS_WINDOW")),
                     as.integer(sw(A("APP_OBS")$co2, A("APP_HIST_YEARS")[2])))
    expect_identical(as.integer(sw(si_co2(1999:2024), 2024)), c(2000L, 2024L))
    expect_identical(as.integer(sw(si_co2(1999:2026), 2024)), c(2000L, 2024L))           # capped at the run
    expect_identical(as.integer(sw(si_co2(1999:2024, drop = c(2024, 12)), 2024)), c(2000L, 2023L))  # a missing month
    sub_ <- A("plot_seasonal")(A("APP_HIST")$out, A("APP_OBS"), A("APP_SEAS_WINDOW"))$labels$subtitle
    expect_true(grepl(sprintf("%d–%d", A("APP_SEAS_WINDOW")[1], A("APP_SEAS_WINDOW")[2]), sub_, fixed = TRUE))
    expect_error(A("plot_seasonal")(A("APP_HIST")$out, A("APP_OBS")))   # no typed default window to fall back on

    # 5. each Covers entry is its file's span; the table shows them in Driver order
    root <- A("CCX_ROOT")
    span <- function(f, keep = NULL) {
      d <- as.data.frame(readRDS(file.path(root, "data", f))); if (!is.null(keep)) d <- d[keep(d), ]
      sprintf("%d–%d", min(d$year), max(d$year))
    }
    cv <- A("APP_DRIVER_COVERS")
    expect_identical(cv[["sst"]], span("forcing_sst.rds"))
    expect_identical(cv[["gmst"]], span("forcing_gmst.rds"))
    # ENSO ends at the last year with all twelve months (Marcus 2026-10-21: "end ENSO at the last full year")
    en <- as.data.frame(readRDS(file.path(root, "data", "forcing_enso.rds")))
    nmo <- tapply(!is.na(en$nino34_anom), en$year, sum)
    full <- as.integer(names(nmo)[nmo == 12])
    expect_identical(cv[["enso"]], sprintf("%d–%d", min(full), max(full)))
    fy <- A("app_full_years")("v")
    si_m <- data.frame(year = rep(2001:2003, each = 12), v = c(rep(1, 24), rep(1, 7), rep(NA, 5)))
    expect_identical(range(si_m$year[fy(si_m)]), c(2001L, 2002L))                         # a partial last year drops
    si_m1 <- si_m[-1, ]
    expect_identical(range(si_m1$year[fy(si_m1)]), c(2002L, 2002L))                      # so does a partial first year
    # MUTATION: the file's full span counts the partial last year (the record runs into 2026 today)
    if (max(en$year[!is.na(en$nino34_anom)]) > max(full))
      expect_false(identical(cv[["enso"]], span("forcing_enso.rds", function(d) !is.na(d$nino34_anom))))
    expect_identical(cv[["aod"]], span("forcing_volcanic_aod.rds"))
    expect_identical(cv[["ndep"]], span("forcing_ndep.rds", function(d) d$scenario == "historical"))
    expect_identical(cv[["emissions"]], span("forcing_emissions_historical.rds"))
    # MUTATION: N deposition with its scenarios left in runs to 2300, and the ¹⁴C row with the zero rows kept
    # starts in 1950; the table shows neither
    expect_false(identical(cv[["ndep"]], span("forcing_ndep.rds")))
    expect_false(grepl("^1950", cv[["c14"]]))
    tab <- output$h_drivers
    expect_true(all(unname(cv[c("emissions", "gmst", "sst", "enso", "aod", "c14", "ndep")]) %in%
                      regmatches(tab, gregexpr("[0-9]{4}–[0-9]{4}", tab))[[1]]))
    # no year typed in the table's Covers column
    src <- paste(readLines(file.path(.si_app_dir, "server.R"), encoding = "UTF-8"), collapse = "\n")
    blk <- regmatches(src, regexpr("(?s)output\\$h_drivers <- renderTable\\(\\{.*?\\}, striped", src, perl = TRUE))
    expect_length(blk, 1L)
    expect_false(grepl("Covers = c\\(", blk))
    expect_false(grepl("[0-9]{4}\\\\u2013", blk))

    # 6. the growth note names the product's first year
    g <- readRDS(file.path(root, "data", "mbl_global_growth.rds"))
    expect_true(grepl(sprintf("begins in %d.", min(g$level$year)), A("GROWTH_UNIT_NOTE"), fixed = TRUE))
    expect_identical(A("GROWTH_OBS_FIRST_YEAR"), as.integer(min(g$level$year)))
  })
})
