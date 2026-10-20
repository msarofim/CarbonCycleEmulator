# Time each top-level expression of app/global.R in a FRESH process, from a deploy bundle.
#   Rscript time_stages.R <bundle_dir> <out_csv> <label>
# Evaluates global.R expression by expression in globalenv (as shiny does), then ui.R and server.R.
a <- commandArgs(TRUE); bundle <- a[1]; out_csv <- a[2]; label <- a[3]
T0 <- proc.time()[["elapsed"]]
setwd(file.path(bundle, "app"))
ex <- parse("global.R", keep.source = TRUE)
sr <- attr(ex, "srcref")
rows <- list()
for (i in seq_along(ex)) {
  t0 <- proc.time()[["elapsed"]]
  eval(ex[[i]], envir = globalenv())
  dt <- proc.time()[["elapsed"]] - t0
  first <- as.character(sr[[i]])[1]
  rows[[length(rows) + 1]] <- data.frame(stage = substr(first, 1, 70), line = sr[[i]][1], s = dt)
}
for (f in c(sort(list.files("R", pattern = "[.][Rr]$", full.names = TRUE)), "ui.R", "server.R")) {
  t0 <- proc.time()[["elapsed"]]
  sys.source(f, envir = if (startsWith(f, "R/")) globalenv() else new.env(parent = globalenv()))
  rows[[length(rows) + 1]] <- data.frame(stage = paste("source", f), line = NA, s = proc.time()[["elapsed"]] - t0)
}
d <- do.call(rbind, rows)
d$label <- label
d$total_since_R_start <- proc.time()[["elapsed"]]
write.csv(d, out_csv, row.names = FALSE)
big <- d[d$s >= 0.05, ]
cat(sprintf("%-72s %5s %7.2f\n", big$stage, big$line, big$s), sep = "")
cat(sprintf("sum of stages %.2f s; R process elapsed at end %.2f s\n", sum(d$s), proc.time()[["elapsed"]]))
