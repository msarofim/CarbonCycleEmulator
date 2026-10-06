# The RULED SLEEP STATEMENT for objective #16's landing (Marcus 2026-10-05, "Land as is, state it (Recommended)";
# CHANGELOG 10-05 m, o). Appended to the landed run's RUN_PROVENANCE.txt by 20261005f_obj16_landchain.sh.
# Every number is READ, none typed:
#   - the asleep spans from `pmset -g log` ("Entering Sleep state" to the next Wake/DarkWake), within the run's span;
#   - each task's span from its own log's first ("task <id> <time>") and last ("done <time> exit <rc>") lines;
#   - each start's status from its start file.
# Usage: Rscript 20261005f_obj16_sleep_addendum.R <outdir with start_NNN.rds> <dir with the task logs> <file to append to>
args <- commandArgs(TRUE)
stopifnot(length(args) == 3L)
OUTD <- args[1]; LOGD <- args[2]; PROV <- args[3]
TAG <- "20261005f"; NSTART <- 24L; BUDGET <- "300 WALL min"
TZ <- "America/New_York"
ISO <- "[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}[-+][0-9]{4}"
ts <- function(x) as.POSIXct(x, format = "%Y-%m-%dT%H:%M:%S%z", tz = TZ)

logs <- sort(list.files(LOGD, pattern = sprintf("^ccx_multistart_mac_%s_[0-9]{3}[.]out$", TAG), full.names = TRUE))
task <- do.call(rbind, lapply(logs, function(f) {
  ln <- readLines(f, warn = FALSE)
  s <- regmatches(ln[1], regexpr(ISO, ln[1]))
  dl <- grep("^done ", ln, value = TRUE)
  d <- if (length(dl)) regmatches(dl[length(dl)], regexpr(ISO, dl[length(dl)])) else NA_character_
  data.frame(id = as.integer(sub(".*_([0-9]{3})[.]out$", "\\1", f)),
             start = ts(s), done = if (is.na(d)) as.POSIXct(NA) else ts(d))
}))
run0 <- min(task$start); run1 <- max(task$done, na.rm = TRUE)

pm <- system2("pmset", c("-g", "log"), stdout = TRUE)
ev <- regmatches(pm, regexec("^([0-9]{4}-[0-9]{2}-[0-9]{2} [0-9:]{8} [-+][0-9]{4}) (Sleep|Wake|DarkWake) +\t(.*)$", pm))
ev <- do.call(rbind, lapply(ev[lengths(ev) == 4L], function(m) data.frame(t = m[2], kind = m[3], what = m[4])))
ev$t <- as.POSIXct(ev$t, format = "%Y-%m-%d %H:%M:%S %z", tz = TZ)
ev <- ev[ev$t >= run0 - 3600 & ev$t <= run1 + 60, ]
sl <- NULL
for (i in which(ev$kind == "Sleep" & grepl("^Entering Sleep state", ev$what))) {
  nx <- which(ev$t > ev$t[i] & ev$kind %in% c("Wake", "DarkWake"))
  b <- if (length(nx)) ev$t[min(nx)] else run1
  sl <- rbind(sl, data.frame(a = ev$t[i], b = b))
}
sl <- sl[sl$b > run0 & sl$a < run1, , drop = FALSE]
fmt <- function(x) format(x, "%H:%M:%S", tz = TZ)
over <- function(s, d) if (is.na(d) || is.null(sl) || !nrow(sl)) 0 else
  sum(pmax(0, as.numeric(pmin(d, sl$b)) - as.numeric(pmax(s, sl$a)))) / 60

fs <- file.path(OUTD, sprintf("start_%03d.rds", task$id))
task$asleep  <- mapply(over, task$start, task$done)
task$status  <- vapply(fs, function(f) {
  if (!file.exists(f)) return("NO START FILE")
  r <- readRDS(f)
  if (isTRUE(r$converged)) "converged" else if (isTRUE(r$out_of_time)) "OUT OF TIME" else "cap"
}, character(1))
task$logpost <- vapply(fs, function(f) if (file.exists(f)) readRDS(f)$logpost else NA_real_, numeric(1))

L <- c("",
  sprintf("SLEEP STATEMENT (ruled: Marcus 2026-10-05, \"Land as is, state it (Recommended)\"; CHANGELOG 10-05 m, o; appended %s by ~/ccx_frozen/20261005f_obj16_sleep_addendum.R, every number read):",
          format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  sprintf("The Mac SLEPT during this run (lid closed on battery: 'Clamshell Sleep'). The budget was %s, so asleep minutes counted against every start alive across them.", BUDGET),
  sprintf("Asleep spans from `pmset -g log` within the run (%s to %s): %s. Total %.1f min asleep.",
          format(run0, "%Y-%m-%d %H:%M:%S", tz = TZ), format(run1, "%Y-%m-%d %H:%M:%S", tz = TZ),
          if (is.null(sl) || !nrow(sl)) "none" else
            paste(sprintf("%s-%s (%.1f min)", fmt(sl$a), fmt(sl$b), as.numeric(sl$b - sl$a, units = "mins")), collapse = ", "),
          if (is.null(sl) || !nrow(sl)) 0 else sum(as.numeric(sl$b - sl$a, units = "mins"))),
  "Per start -- id: started-done (wall); asleep min within its span; status; logpost:",
  sprintf("  %03d: %s-%s; asleep %5.1f; %-11s; %s", task$id, fmt(task$start), fmt(task$done), task$asleep, task$status,
          ifelse(is.na(task$logpost), "NA", sprintf("%.4f", task$logpost))))
oot <- task$id[task$status == "OUT OF TIME"]; slept <- task$id[task$asleep > 0]
L <- c(L,
  sprintf("Summary: %d of %d CONVERGED; OUT OF TIME: [%s]; of those, alive across a sleep: [%s]; starts alive across any sleep: [%s].",
          sum(task$status == "converged"), NSTART, paste(oot, collapse = ", "),
          paste(intersect(oot, slept), collapse = ", "), paste(slept, collapse = ", ")),
  "REDUCED SURVEY POWER: an out-of-time start that slept says the MACHINE was off, not that the start was slow (memory mac_sleep_eats_wall_budget). Resuming those starts from their checkpoints stays an option (handoff 10-05d section 6.3).")
if (nrow(task) != NSTART) L <- c(L, sprintf("*** only %d task logs found, expected %d", nrow(task), NSTART))
cat(L, sep = "\n"); cat("\n")
cat(L, sep = "\n", file = PROV, append = TRUE); cat("\n", file = PROV, append = TRUE)
