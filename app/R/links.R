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

# Inputs a link never carries, and why. A button's click count is not a setting:
# whether opening a link presses it is APP_LINK_AUTORUN's question.
APP_LINK_NOT_CARRIED <- c(
  s_go = "the “Run it” button (see APP_LINK_AUTORUN)",
  p_go = "the “Release the pulse” button (see APP_LINK_AUTORUN)")

# ⚠⚠ MARCUS'S CALL, NOT DECIDED HERE (flagged 2026-10-20, CHANGELOG 2026-10-20 b). Opening a
# link to a pill whose chart needs a button press: restore the settings and WAIT for the
# press (FALSE), or press it on arrival (TRUE)? The pulse lab's press is about 17 s on the
# Connect Cloud host (16.7 s, load test 2026-10-20) and its CPU is shared by every visitor,
# so a post linking 30 readers straight into it queues 30 pulses; "Build your own" is two
# short runs. Set as drafted: build-your-own presses, the pulse lab waits.
APP_LINK_AUTORUN <- c(build = TRUE, pulse = FALSE)
APP_LINK_BUTTON  <- c(build = "s_go", pulse = "p_go")
APP_LINK_PILL_OF <- c(build = "Build your own", pulse = "Pulse lab")
APP_LINK_PRESS_MSG <- "ccx-link-press"   # the custom message app_link_head() handles

#' The inputs a link to this view carries
#' @param v the current inputs, as a list (tab and pill read from it)
app_link_keep <- function(v) {
  tab <- v[[APP_LINK_TAB_INPUT]]
  keep <- c(APP_LINK_TAB_INPUT, if (!is.null(tab)) app_link_inputs()[[tab]])
  if (identical(tab, "Futures") && !is.null(v[[APP_LINK_PILL_INPUT]]))
    keep <- c(keep, APP_LINK_PILL_INPUTS[[v[[APP_LINK_PILL_INPUT]]]])
  unique(keep)
}

#' The buttons opening this view should press (APP_LINK_AUTORUN), as input ids
app_link_presses <- function(v, autorun = APP_LINK_AUTORUN) {
  if (!identical(v[[APP_LINK_TAB_INPUT]], "Futures")) return(character(0))
  k <- names(autorun)[autorun & APP_LINK_PILL_OF[names(autorun)] %in% v[[APP_LINK_PILL_INPUT]]]
  unname(APP_LINK_BUTTON[k])
}

#' The page script: presses a button when the server asks (a restored link, APP_LINK_AUTORUN).
#' A real click, so the button's own count advances and the user's next press still registers.
app_link_head <- function() tags$script(HTML(sprintf("
  (function () {
    function reg() {
      Shiny.addCustomMessageHandler('%s', function (id) {
        var b = document.getElementById(id); if (b) b.click();
      });
    }
    if (window.Shiny && Shiny.addCustomMessageHandler) reg();
    else document.addEventListener('DOMContentLoaded', reg);
  })();", APP_LINK_PRESS_MSG)))

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
    for (b in app_link_presses(v)) session$sendCustomMessage(APP_LINK_PRESS_MSG, b)
  })
  list(url = function() state$url)
}
