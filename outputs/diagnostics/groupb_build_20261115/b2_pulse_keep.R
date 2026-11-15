#!/usr/bin/env Rscript
# b2_pulse_keep.R -- B2 (group B, Marcus 11-15): his Pulse lab sentence "Between 100 and 250 years, the warming
# actually increases a little (4%), whereas the airborne carbon concentrations drop another 18%." carries two numbers
# whose SIGN and SIZE depend on the settings. This sweeps the Pulse lab's controls (every background, every release
# year, three pulse sizes) through the app's own runs and server.R's arithmetic (f_takeaway, temperature view):
#   keep_T = dT(y2) / dT(y1), keep_C = f(y2) / f(y1), y1 = release + 100, y2 = min(release + 250, last year).
# Read-only, no RNG. Usage (repo root): Rscript outputs/diagnostics/groupb_build_20261115/b2_pulse_keep.R
ROOT <- normalizePath(getwd()); stopifnot(file.exists(file.path(ROOT, "app", "global.R")))
setwd(file.path(ROOT, "app"))
invisible(capture.output(suppressMessages(suppressWarnings(
  shiny::loadSupport(getwd(), renv = globalenv(), globalrenv = globalenv())))))
setwd(ROOT)
B2_SIZES <- c(APP_PULSE_GTC_RANGE[1], APP_PULSE_GtC_DEFAULT, APP_PULSE_GTC_RANGE[2])
B2_YEARS <- seq(APP_PULSE_YEAR_RANGE[1], APP_PULSE_YEAR_RANGE[2], by = APP_PULSE_YEAR_RANGE[3])
OUT <- file.path("outputs", "diagnostics", "groupb_build_20261115", "b2_pulse_keep")
cat("LOADED\n"); flush(stdout())
grid <- expand.grid(bg = unname(APP_SCENARIOS), year = B2_YEARS, gtc = B2_SIZES, stringsAsFactors = FALSE)
res <- do.call(rbind, lapply(seq_len(nrow(grid)), function(i) {
  g <- grid[i, ]; yrs <- APP_PULSE_YEARS
  bg <- APP_SCEN_EMIS[APP_SCEN_EMIS$scenario == g$bg, ]; y <- seq(yrs[1], yrs[2])
  base_em <- data.frame(year = y, fossil_GtC = stats::approx(bg$year, bg$fossil_GtC, xout = y, rule = 2)$y,
                        luc_GtC = stats::approx(bg$year, bg$luc_GtC, xout = y, rule = 2)$y)
  pulse_em <- base_em; k <- pulse_em$year == g$year; pulse_em$fossil_GtC[k] <- pulse_em$fossil_GtC[k] + g$gtc
  cb <- app_run_coupled(APP_SPIN, g$bg, yrs, g$bg, emissions = base_em, interp_method = APP_PULSE_EMIS_METHOD)$climate
  cp <- app_run_coupled(APP_SPIN, g$bg, yrs, g$bg, emissions = pulse_em, interp_method = APP_PULSE_EMIS_METHOD)$climate
  ppm <- g$gtc / ccx_const("GtC_PER_PPM")
  f <- function(yy) (cp$co2_ppm[cp$year == yy] - cb$co2_ppm[cb$year == yy]) / ppm
  dT <- function(yy) cp$gmst[cp$year == yy] - cb$gmst[cb$year == yy]
  y1 <- g$year + 100; y2 <- min(g$year + 250, max(cb$year))
  data.frame(g, y1 = y1, y2 = y2, dT1 = dT(y1), dT2 = dT(y2), keep_T = dT(y2) / dT(y1), keep_C = f(y2) / f(y1))
}))
prov <- sprintf("b2_pulse_keep.R | commit %s | canonical %s | %s | %d settings (backgrounds x release years x sizes %s GtC)",
                ccx_git_stamp(), CCX_MODE_CANONICAL, format(Sys.time(), "%Y-%m-%d %H:%M"), nrow(res),
                paste(B2_SIZES, collapse = "/"))
saveRDS(list(provenance = prov, table = res), paste0(OUT, ".rds"))
sink(paste0(OUT, ".log")); cat(prov, "\n\n")
pc <- function(x) sprintf("%+.1f%%", 100 * (x - 1))
cat(sprintf("warming change from y1 to y2: %s to %s (median %s); negative in %d of %d settings\n",
            pc(min(res$keep_T)), pc(max(res$keep_T)), pc(stats::median(res$keep_T)), sum(res$keep_T < 1), nrow(res)))
cat(sprintf("airborne carbon change:       %s to %s (median %s); positive in %d of %d settings\n",
            pc(min(res$keep_C)), pc(max(res$keep_C)), pc(stats::median(res$keep_C)), sum(res$keep_C > 1), nrow(res)))
cat(sprintf("rounded warming change: %s\n", paste(names(table(round(100 * (res$keep_T - 1)))),
                                                  table(round(100 * (res$keep_T - 1))), sep = ":", collapse = " ")))
cat("\nby background and release year (default size):\n")
d <- res[res$gtc == APP_PULSE_GtC_DEFAULT, ]
print(stats::xtabs(round(100 * (keep_T - 1)) ~ bg + year, d))
cat("\nairborne carbon, same:\n"); print(stats::xtabs(round(100 * (keep_C - 1)) ~ bg + year, d))
cat("\nlargest |keep_T(size) - keep_T(default)| across sizes, percentage points:",
    sprintf("%.2f", max(abs(100 * (res$keep_T - stats::ave(res$keep_T, res$bg, res$year, FUN = function(v) v[2]))))), "\n")
sink(); cat(readLines(paste0(OUT, ".log")), sep = "\n")
