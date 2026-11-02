# =====================================================================
# sessionlog.R -- one log line when a visit starts and one when it ends (2026-11-02).
#
# Marcus 2026-11-02 ("Yes, add the session logging"): the host's usage meter cannot say whether anyone uses the
# app. One worker is kept warm around the clock, so billed hours track the clock, and the connections chart
# averages ~0.1 with no breakdown. These lines go to the server's standard error, which Connect Cloud keeps in
# the content's logs, as
#     CCX_SESSION {"event":"start","id":"...","start":"...","client":"desktop"}
#     CCX_SESSION {"event":"end","id":"...","start":"...","client":"desktop","dur_s":412,"ref":"reddit.com",
#                  "tabs":["The Keeling Curve","Futures"],"n_changes":9,"changed":["k_years","f_mode"]}
# so a visit can be counted, told apart from a forgotten tab (long, no changes) or one of our own headless
# checks (client "headless"), and traced to where it came from.
#
# ⛔ WHAT IS NOT LOGGED: no IP address, no full user-agent string (only its class), no referring page beyond
# its host name. The browser itself reduces the referrer to the host (APP_SESSION_JS), so the full address
# never reaches the server; app_ref_host() reduces it again on this side.
# ⛔ THE REFERRER NEVER TRAVELS IN A LINK: APP_SESSION_REF_INPUT is in no tab's list (links.R), so
# app_link_keep() excludes it from the address bar; test-app-session-log.R holds that.
# ⚠ The start line is written as the session opens, so a visit still counts if the worker dies before it ends.
# =====================================================================

APP_SESSION_LOG_TAG   <- "CCX_SESSION"
APP_SESSION_REF_INPUT <- "ccx_referrer"   # set once by APP_SESSION_JS when the page connects
APP_SESSION_MAX_NAMES <- 30L              # cap on the input names listed in an end line

APP_SESSION_JS <- sprintf("
  $(document).on('shiny:connected', function () {
    var h = '';
    try { if (document.referrer) h = new URL(document.referrer).hostname; } catch (e) {}
    Shiny.setInputValue(%s, h);
  });", jsonlite::toJSON(APP_SESSION_REF_INPUT, auto_unbox = TRUE))

#' The class of a user-agent string: "headless", "bot", "mobile", "desktop" or "unknown"
app_ua_class <- function(ua) {
  if (!is.character(ua) || length(ua) != 1L || is.na(ua) || !nzchar(ua)) return("unknown")
  ua <- tolower(ua)
  if (grepl("headless", ua, fixed = TRUE)) return("headless")
  if (grepl("bot|crawl|spider|slurp|facebookexternalhit|embedly|curl/|wget/|python-requests", ua)) return("bot")
  if (grepl("mobi|android|iphone|ipad", ua)) return("mobile")
  "desktop"
}

#' The host name of a referrer (either a full address or a bare host), "none" when there is none
app_ref_host <- function(ref) {
  if (!is.character(ref) || length(ref) != 1L || is.na(ref) || !nzchar(ref)) return("none")
  h <- sub("^[a-z][a-z0-9+.-]*://", "", tolower(ref))
  h <- sub("^[^@/]*@", "", h)          # any user:password@ part
  h <- sub("[/?#:].*$", "", h)
  h <- sub("^www\\.", "", h)
  if (nzchar(h)) h else "none"
}

#' One log line for a session's state, as "CCX_SESSION <json>"
app_session_line <- function(event, st, end = NULL) {
  rec <- list(event = event, id = st$id, start = format(st$t0, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"), client = st$client)
  if (identical(event, "end")) {
    rec$dur_s <- round(as.numeric(difftime(end, st$t0, units = "secs")))
    rec$ref <- st$ref
    rec$tabs <- I(st$tabs)
    rec$n_changes <- st$n
    rec$changed <- I(utils::head(st$changed, APP_SESSION_MAX_NAMES))
  }
  paste(APP_SESSION_LOG_TAG, jsonlite::toJSON(rec, auto_unbox = TRUE))
}

app_session_emit <- function(line) cat(line, "\n", sep = "", file = stderr())

#' The server half: a start line now, a running tally of tabs and changed inputs, an end line when it closes
#' @param now,emit replaceable for tests
app_session_log_server <- function(input, session, now = Sys.time, emit = app_session_emit) {
  st <- new.env(parent = emptyenv())
  st$id <- substr(paste(session$token, collapse = ""), 1, 8)   # random per session; pairs the two lines
  st$t0 <- now()
  st$client <- app_ua_class(tryCatch(suppressWarnings(session$request[["HTTP_USER_AGENT"]]),
                                     error = function(e) NULL))
  st$ref <- "none"; st$tabs <- character(0); st$changed <- character(0); st$n <- 0L; st$prev <- NULL
  emit(app_session_line("start", st))
  observe({
    v <- reactiveValuesToList(input)
    tab <- v[[APP_LINK_TAB_INPUT]]
    if (is.character(tab) && length(tab) == 1L && !identical(utils::tail(st$tabs, 1), tab)) st$tabs <- c(st$tabs, tab)
    if (!is.null(v[[APP_SESSION_REF_INPUT]])) st$ref <- app_ref_host(v[[APP_SESSION_REF_INPUT]])
    # a change is an input whose value differs from the last one seen; an input that first appears (the first
    # flush, or a control drawn later) is not one, and neither is a tab switch (counted in `tabs`)
    if (!is.null(st$prev)) {
      both <- setdiff(intersect(names(v), names(st$prev)), c(APP_LINK_TAB_INPUT, APP_SESSION_REF_INPUT))
      ch <- both[!vapply(both, function(k) identical(v[[k]], st$prev[[k]]), logical(1))]
      st$n <- st$n + length(ch); st$changed <- union(st$changed, ch)
    }
    st$prev <- v
  })
  session$onSessionEnded(function() emit(app_session_line("end", st, now())))
  invisible(st)
}
