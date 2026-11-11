# Saved 2026-11-11 from the review session (CHANGELOG 2026-11-11 h). Usage: Rscript log_problems.R "YYYY-mm-dd HH:MM"
# Read-only: the live revision's log, filtered to lines that look like problems (warnings, errors, the fit step's own
# "left as drawn" message), with counts by message. Usage: Rscript log_problems.R [since_utc "YYYY-mm-dd HH:MM"]
since <- commandArgs(trailingOnly = TRUE)[1]
cl <- rsconnect:::clientForAccount(rsconnect:::accountInfo("saraphreport", "connect.posit.cloud"))
rev <- cl$getContent("01a14244-5cc3-1951-7b06-9e2fb07beae3")$current_revision
ch <- rev$publish_log_channel; tok <- cl$getAuthorization(ch)
svc <- rsconnect:::parseHttpUrl(paste0(rsconnect:::connectCloudUrls()$logs, "/v1"))
get <- function(dir) rsconnect:::GET(svc, list(accessToken = tok), sprintf("/logs/%s?traversal_direction=%s&limit=1500", ch, dir))$data
d <- c(get("forward"), get("backward"))
x <- unique(data.frame(t = as.POSIXct(vapply(d, function(e) e$timestamp / 1e6, 1), origin = "1970-01-01", tz = "UTC"),
                       key = vapply(d, function(e) e$sort_key, 1), msg = vapply(d, function(e) e$message, "")))
x <- x[order(x$key), ]
if (!is.na(since)) x <- x[x$t >= as.POSIXct(since, tz = "UTC"), ]
cat("revision", rev$id, "| lines", nrow(x), "|", format(min(x$t)), "to", format(max(x$t)), "UTC\n")
cat("sessions started:", sum(grepl('CCX_SESSION {"event":"start"', x$msg, fixed = TRUE)), "\n")
bad <- x[grepl("warn|error|left as drawn|cannot|failed|unable|NaN|Inf\\b", x$msg, ignore.case = TRUE) & !grepl("^CCX_SESSION", x$msg), ]
if (!nrow(bad)) cat("no problem-looking lines\n") else { cat(paste(format(bad$t, "%H:%M:%S"), substr(bad$msg, 1, 220)), sep = "\n")
  k <- sort(table(substr(gsub("[0-9a-f]{8,}|[0-9]+(\\.[0-9]+)?", "#", bad$msg), 1, 160)), decreasing = TRUE)
  print(utils::head(as.data.frame(k, stringsAsFactors = FALSE), 30), row.names = FALSE, right = FALSE)
}
