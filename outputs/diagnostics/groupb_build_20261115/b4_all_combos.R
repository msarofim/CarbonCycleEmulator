#!/usr/bin/env Rscript
# b4_all_combos.R -- B4 (group B, Marcus 11-15): which What-if switch combinations move global-average CO2 in the
# last full year by less than B4_SMALL_PPM, unrounded? Option (a) prints those to one decimal; the year-to-year
# explanation in his sentence is true only for the interannual switches. Every combination of the app's switches is
# run through the app's own app_run_mechanisms() at the canonical. Read-only, no RNG.
# Usage (repo root): Rscript outputs/diagnostics/groupb_build_20261115/b4_all_combos.R
ROOT <- normalizePath(getwd()); stopifnot(file.exists(file.path(ROOT, "app", "global.R")))
setwd(file.path(ROOT, "app"))
invisible(capture.output(suppressMessages(suppressWarnings(
  shiny::loadSupport(getwd(), renv = globalenv(), globalrenv = globalenv())))))
setwd(ROOT)
B4_SMALL_PPM <- 1                                    # option (a)'s threshold: "under 1 ppm, one decimal"
OUT <- file.path("outputs", "diagnostics", "groupb_build_20261115", "b4_all_combos")
cat("LOADED\n"); flush(stdout())
sw <- names(CCX_MECHANISMS)
combos <- unlist(lapply(seq_along(sw), function(k) combn(sw, k, simplify = FALSE)), recursive = FALSE)
a <- APP_HIST$out; y_now <- max(floor(a$t + 1e-9))
lev <- function(o) app_annual_mean_of(o$t, o$co2_global, y_now)
full <- lev(a)
res <- do.call(rbind, lapply(combos, function(cmb) {
  t0 <- Sys.time()
  r <- app_run_mechanisms(cmb, APP_HIST_YEARS, "historical")
  v <- lev(r$out)
  data.frame(switches = paste(cmb, collapse = "+"), n = length(cmb), level = v, diff = v - full,
             secs = as.numeric(difftime(Sys.time(), t0, units = "secs")))
}))
res$small <- abs(res$diff) < B4_SMALL_PPM
res <- res[order(abs(res$diff)), ]
prov <- sprintf("b4_all_combos.R | commit %s | canonical %s | %s | %d combinations of %d switches | year %d | full %.3f ppm",
                ccx_git_stamp(), CCX_MODE_CANONICAL, format(Sys.time(), "%Y-%m-%d %H:%M"), length(combos),
                length(sw), y_now, full)
saveRDS(list(provenance = prov, threshold = B4_SMALL_PPM, table = res), paste0(OUT, ".rds"))
sink(paste0(OUT, ".log")); cat(prov, "\n\n")
cat(sprintf("Combinations with |difference| < %g ppm: %d\n", B4_SMALL_PPM, sum(res$small)))
print(res[res$small, c("switches", "level", "diff")], row.names = FALSE, digits = 6)
cat("\nThe ten smallest that are NOT under the threshold:\n")
print(utils::head(res[!res$small, c("switches", "level", "diff")], 10), row.names = FALSE, digits = 6)
cat(sprintf("\nmean run time %.2f s\n", mean(res$secs))); sink()
cat(readLines(paste0(OUT, ".log")), sep = "\n")
