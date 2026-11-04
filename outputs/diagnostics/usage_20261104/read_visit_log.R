# =====================================================================
# read_visit_log.R -- who used the live app: the CCX_SESSION lines (app/R/sessionlog.R) from the host's log.
#
# Marcus 2026-11-04 ("Can you check yesterday's CarboTope usage?"). Read-only. The content's runtime log is the
# current revision's `publish_log_channel` (it carries both the publish lines and the app's stderr); rsconnect
# 1.11.2 reads it the same way after a publish (`getAuthorization()` then `connectCloudLogsClient()$getLogs()`).
#
# ⛔ THE SERVICE RETURNS ONLY THE TWO ENDS OF THE CHANNEL. `limit` is at most 1500 and `traversal_direction` is
# forward or backward; no time or cursor parameter was found (2026-11-04: 13 time names ignored, 47 names sent a
# non-numeric value and none was rejected). So this reads the first 1500 lines after the publish and the last
# 1500, and reports the gap between them. About 1500 lines is 12 hours here, mostly start-up boilerplate from a
# container that restarts every ~15 minutes.
#
# Usage: Rscript read_visit_log.R <out_dir>     (keep <out_dir> outside the repository: it is public)
# Writes <out_dir>/log_entries.rds (every line read) and <out_dir>/visits.csv (one row per visit).
# =====================================================================

CONTENT_ID <- "01a14244-5cc3-1951-7b06-9e2fb07beae3"
ACCOUNT    <- "saraphreport"
SERVER     <- "connect.posit.cloud"
PAGE_MAX   <- 1500L                 # the service's ceiling (HTTP 422 above it)
LOCAL_TZ   <- "America/New_York"    # Marcus's clock, for the printed table
LOG_TAG    <- "CCX_SESSION"         # app/R/sessionlog.R's APP_SESSION_LOG_TAG

out_dir <- commandArgs(trailingOnly = TRUE)[1]
if (is.na(out_dir)) stop("Usage: Rscript read_visit_log.R <out_dir>")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

cl  <- rsconnect:::clientForAccount(rsconnect:::accountInfo(ACCOUNT, SERVER))
rev <- cl$getContent(CONTENT_ID)$current_revision
ch  <- rev$publish_log_channel
tok <- cl$getAuthorization(ch)
svc <- rsconnect:::parseHttpUrl(paste0(rsconnect:::connectCloudUrls()$logs, "/v1"))
page <- function(dir) {
  r <- rsconnect:::GET(svc, list(accessToken = tok), sprintf("/logs/%s?traversal_direction=%s&limit=%d", ch, dir, PAGE_MAX))
  data.frame(ts = vapply(r$data, function(e) e$timestamp / 1e6, 1), key = vapply(r$data, function(e) e$sort_key, 1),
             level = vapply(r$data, function(e) e$level, ""), type = vapply(r$data, function(e) e$type, ""),
             msg = vapply(r$data, function(e) e$message, ""))
}
x <- unique(rbind(page("forward"), page("backward")))
x <- x[order(x$key), ]
x$t <- as.POSIXct(x$ts, origin = "1970-01-01", tz = "UTC")
saveRDS(x, file.path(out_dir, "log_entries.rds"))

loc <- function(t) format(t, "%m-%d %H:%M", tz = LOCAL_TZ)
cat(sprintf("Revision %s (published %s). Read %d lines: %s to %s (%s).\n", rev$id, rev$publish_end_time, nrow(x),
            loc(min(x$t)), loc(max(x$t)), LOCAL_TZ))
gap <- which(diff(x$ts) > 3600)
if (length(gap)) cat("NOT READ (between the two pages, or no lines):", paste(loc(x$t[gap]), "to", loc(x$t[gap + 1])), "\n")
if (nrow(x) < 2 * PAGE_MAX) cat("The two pages overlap: the whole channel was read.\n")

s <- x[startsWith(x$msg, paste0(LOG_TAG, " ")), ]
recs <- lapply(sub(paste0("^", LOG_TAG, " "), "", s$msg), jsonlite::fromJSON)
g <- function(z, k, d = NA) if (is.null(z[[k]]) || !length(z[[k]])) d else z[[k]]
d <- do.call(rbind, lapply(recs, function(z) data.frame(
  event = z$event, id = z$id, start = z$start, client = z$client, dur_s = g(z, "dur_s"), ref = g(z, "ref"),
  n_changes = g(z, "n_changes"), changed = paste(g(z, "changed", ""), collapse = ","), tabs = paste(g(z, "tabs", ""), collapse = " > "))))
if (is.null(d)) { cat("No", LOG_TAG, "lines in what was read.\n"); quit(save = "no") }
v <- merge(d[d$event == "start", c("id", "start", "client")],
           d[d$event == "end", c("id", "dur_s", "ref", "n_changes", "changed", "tabs")], by = "id", all = TRUE)
v <- v[order(v$start), ]
v$start_local <- loc(as.POSIXct(v$start, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"))
utils::write.csv(v, file.path(out_dir, "visits.csv"), row.names = FALSE)
cat(sprintf("\nVisits: %d (%s). With at least one control changed: %d.\n", nrow(v),
            paste(names(table(v$client)), table(v$client), sep = " ", collapse = ", "), sum(v$n_changes > 0, na.rm = TRUE)))
print(v[, c("start_local", "client", "dur_s", "ref", "n_changes", "changed", "tabs")], row.names = FALSE, right = FALSE)

# the host's own activity: container starts and stops, and first page draws that no browser session followed
fo <- x$ts[grepl("Downloading google font", x$msg, fixed = TRUE)]
ss <- x$ts[startsWith(x$msg, paste0(LOG_TAG, ' {"event":"start"'))]
cat(sprintf("\nContainer loads %d, stops %d; first page draws in a fresh container %d, of which %d had no session within 2 min.\n",
            sum(grepl("Loading the previously published content", x$msg, fixed = TRUE)),
            sum(grepl("Stopping server", x$msg, fixed = TRUE)), length(fo),
            sum(!vapply(fo, function(t) any(abs(ss - t) < 120), TRUE))))
k <- x$t[grepl("signal: killed", x$msg, fixed = TRUE)]
if (length(k)) cat("Workers killed:", paste(loc(k), collapse = ", "), "\n")
