# =====================================================================
# links.R -- deep links: the address bar carries the current view (2026-10-20).
#
# An instructor or a post can point at one view -- a tab, a Futures pill, and the
# settings on it -- by copying the page's address. Shiny's URL bookmarking
# encodes the inputs into the query string; the observer below re-encodes them
# on every change and writes the result into the address bar, so the address is
# always the link to what is on screen. Opening it restores the same inputs, and
# with them the tab.
#
# ⭐ ONLY THE OPEN TAB'S SETTINGS TRAVEL. Every other input is excluded from the
# link at encode time (app_link_keep()), so a link to the Keeling curve carries
# three settings rather than all twenty-odd; anything not in the link opens at
# its default. The per-tab lists are APP_LINK_INPUTS, and
# tests/testthat/test-app-links.R fails if an input in ui.R is in no list and
# not in APP_LINK_NOT_CARRIED, or if a list names a tab ui.R does not have.
#
# ⚠ ui.R IS A FUNCTION OF THE REQUEST since 2026-10-20 (`function(request)
# navbarPage(...)`): Shiny restores an input by building the UI with the link's
# value as the control's starting value, which it can only do per request.
# =====================================================================

enableBookmarking(store = "url")

APP_LINK_TAB_INPUT <- "tabs"   # navbarPage(id = ...) in ui.R
APP_LINK_PILL_INPUT <- "f_mode"   # the Futures tab's pills

#' The settings each tab's link carries, by tab title. A FUNCTION, because two
#' titles are constants from files Shiny sources after this one (review.R).
app_link_inputs <- function() stats::setNames(list(
  c("k_years", "k_hemi", "k_obs"),
  "w_years",
  c("c_mech", "c_years"),
  c("i_years", "i_hemi"),
  c(APP_LINK_PILL_INPUT, "f_yvar", "f_fair"),
  character(0),
  "cm_level",
  character(0)),
  c("The Keeling Curve", "Where does the carbon go?", "What if…?", "Isotope fingerprints",
    "Futures", RV_TAB_TITLE, APP_CMAP_TAB, "Under the hood"))

# ...and on the Futures tab, the open pill's own settings on top
APP_LINK_PILL_INPUTS <- list(
  "Scenarios"      = "f_scen",
  "Build your own" = c("s_kind", "s_zero_year", "s_rate", "s_bg"),
  "Pulse lab"      = c("p_bg", "p_gtc", "p_year"))

# Inputs a link never carries, and why. A button's click count is not a setting.
# ⭐ RULED (Marcus 2026-10-20): a link restores the tab and the settings, and NEVER presses a
# button. On the Pulse lab, the precomputed default pulse is shown automatically and a change
# of settings greys it until "Release the pulse" -- that display is the first-visit work's
# (server.R's pulse path), so a link at the default settings shows the precomputed result and
# a link at other settings waits for the press. Nothing here touches that path.
APP_LINK_NOT_CARRIED <- c(
  s_go = "the \u201cRun it\u201d button: a link never presses it (Marcus 2026-10-20)",
  p_go = "the \u201cRelease the pulse\u201d button: a link never presses it (Marcus 2026-10-20)")

#' The inputs a link to this view carries
#' @param v the current inputs, as a list (tab and pill read from it)
app_link_keep <- function(v) {
  tab <- v[[APP_LINK_TAB_INPUT]]
  keep <- c(APP_LINK_TAB_INPUT, if (!is.null(tab)) app_link_inputs()[[tab]])
  if (identical(tab, "Futures") && !is.null(v[[APP_LINK_PILL_INPUT]]))
    keep <- c(keep, APP_LINK_PILL_INPUTS[[v[[APP_LINK_PILL_INPUT]]]])
  unique(keep)
}

#' The server half: keep the address bar on the current view, and finish a restore
#' @return list(url = function() the current link, or NULL before the first one)
app_links_server <- function(input, session) {
  state <- new.env(parent = emptyenv())
  state$url <- NULL
  observe({
    v <- reactiveValuesToList(input)
    session$setBookmarkExclude(setdiff(names(v), app_link_keep(v)))
    session$doBookmark()
  })
  onBookmarked(function(url) {
    state$url <- url
    updateQueryString(url, mode = "replace")
  })
  onRestored(function(st) {
    v <- st$input
    # the FaIR box's label follows the pill (server.R), but that observer ignores the FIRST
    # pill value -- which, on a restored link, is not the default one
    if (!is.null(v[[APP_LINK_PILL_INPUT]]))
      updateCheckboxInput(session, "f_fair", label = app_fair_check_label(v[[APP_LINK_PILL_INPUT]]))
  })
  list(url = function() state$url)
}

# ---- "Copy link to this view" (Marcus 2026-10-21: "9: Do it") -----------------------
# The address bar already IS the link to the view (above), but nothing on the page said so. One link per tab,
# beside the download links of the tab's first chart (app_dl_links(), downloads.R), copies the view's link.
# ⭐ IT COPIES THE SHORT ADDRESS: APP_SHORT_URL plus the query string. The forward passes the query through
# (app/DEPLOY.md, "The short address"), so the link opens the same view, and moving the app means editing the
# forward rather than breaking every copied link.
APP_SHARE_LABEL  <- "Copy link to this view"
APP_SHARE_DONE   <- "Link copied"
APP_SHARE_PROMPT <- "Copy this link:"     # where the browser refuses the clipboard
APP_SHARE_DONE_MS <- 2000
# the first chart of each tab, in navbar order (test-app-scan-items.R ties each to its tab)
APP_SHARE_IDS <- c("k_plot", "w_partition", "c_plot", "i_d13c", "f_plot", "rv_repdc", "cm_map", "h_diagram")

#' The link, or NULL for a chart that is not its tab's first
app_share_link <- function(id) {
  if (!id %in% APP_SHARE_IDS) return(NULL)
  tagList(" · ", tags$a(href = "#", class = "ccx-share", role = "button", `data-base` = APP_SHORT_URL,
                             APP_SHARE_LABEL, .noWS = "outside"))
}
APP_SHARE_JS <- sprintf("
  $(document).on('click', 'a.ccx-share', function (e) {
    e.preventDefault();
    var a = this, url = a.getAttribute('data-base') + '/' + window.location.search;
    var done = function () {
      a.textContent = %s;
      setTimeout(function () { a.textContent = %s; }, %d);
    };
    if (navigator.clipboard && window.isSecureContext)
      navigator.clipboard.writeText(url).then(done, function () { window.prompt(%s, url); });
    else window.prompt(%s, url);
  });",
  jsonlite::toJSON(APP_SHARE_DONE, auto_unbox = TRUE), jsonlite::toJSON(APP_SHARE_LABEL, auto_unbox = TRUE),
  APP_SHARE_DONE_MS, jsonlite::toJSON(APP_SHARE_PROMPT, auto_unbox = TRUE),
  jsonlite::toJSON(APP_SHARE_PROMPT, auto_unbox = TRUE))
