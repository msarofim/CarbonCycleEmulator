#!/usr/bin/env Rscript
# groupb_numbers.R -- numbers the group B decision sheet's DRAFTS quote (2026-11-11). Read-only, through the app's own
# functions at the canonical; no RNG. Usage (repo root): Rscript outputs/diagnostics/groupb_20261111/groupb_numbers.R
ROOT <- normalizePath(getwd()); stopifnot(file.exists(file.path(ROOT, "app", "global.R")))
setwd(file.path(ROOT, "app"))
invisible(capture.output(suppressMessages(suppressWarnings(
  shiny::loadSupport(getwd(), renv = globalenv(), globalrenv = globalenv())))))
setwd(ROOT)
GN_OUT <- file.path("outputs", "diagnostics", "groupb_20261111", "groupb_numbers.log")
GN_SWITCHES <- list("enso", "volcanic", c("enso", "volcanic"), "warming_feedback", "revelle")
GN_AF_FROM <- 1850L                          # the "since" year of the draft airborne-fraction sentence
if (file.exists(GN_OUT)) file.remove(GN_OUT)
say <- function(...) { txt <- sprintf(...); cat(txt); cat(txt, file = GN_OUT, append = TRUE) }
say("groupb_numbers.R | commit %s | canonical %s | %s\n", ccx_git_stamp(), CCX_MODE_CANONICAL, format(Sys.time(), "%Y-%m-%d %H:%M"))

# ---- B4: the What-if level, unrounded, per switch (server.R c_takeaway's arithmetic) ---------------------------
a <- APP_HIST$out; y_now <- max(floor(a$t + 1e-9))
lev <- function(o) app_annual_mean_of(o$t, o$co2_global, y_now)
full <- lev(a)
say("\n== B4: global-average CO2 in %d, unrounded; the full model %.3f ppm ==\n", y_now, full)
for (sw in GN_SWITCHES) {
  r <- app_run_mechanisms(sw, APP_HIST_YEARS, "historical")
  off <- lev(r$out); pc <- app_ppm_change(full, off)
  say("  %-22s off %.3f ppm, difference %+.3f (printed: %s instead of %s, %s ppm%s)\n", paste(sw, collapse = "+"), off,
      off - full, format(pc$off), format(pc$full), pc$signed, if (pc$d == 0) "; the 'unchanged' sentence" else "")
}

# ---- B11: the airborne fraction and the budget bars ---------------------------------------------------------------
F <- app_build_forcing("historical", APP_HIST_YEARS, prod_c14 = APP_SPIN$prod_c14)
pt <- partition_table(APP_HIST$out, F)
yy <- floor(pt$t + 1e-9); nn <- table(yy); fy <- as.integer(names(nn)[nn == 12])
am <- stats::aggregate(cbind(atmosphere, emitted) ~ year, data = data.frame(year = yy, pt)[yy %in% fy, ], FUN = mean)
am$af <- am$atmosphere / am$emitted
k <- am$year >= GN_AF_FROM
say("\n== B11 airborne fraction (annual means of the two cumulative stocks) ==\n")
say("  %d: %.1f%%; since %d the lowest %.1f%% (%d), the highest %.1f%% (%d)\n", max(am$year), 100 * am$af[nrow(am)],
    GN_AF_FROM, 100 * min(am$af[k]), am$year[k][which.min(am$af[k])], 100 * max(am$af[k]), am$year[k][which.max(am$af[k])])
last <- pt[nrow(pt), ]
say("  the Where tab's own takeaway: %.0f of %.0f GtC in the air = %.0f%% (last month of the run)\n",
    last$atmosphere, last$emitted, 100 * last$atmosphere / last$emitted)
ann <- app_sinks_annual(APP_HIST$out, F); win <- c(APP_SPLICE_YEAR - 9L, APP_SPLICE_YEAR)
kk <- ann$yr >= win[1] & ann$yr <= win[2]; g <- APP_GCB[APP_GCB$year >= win[1] & APP_GCB$year <= win[2], ]
say("\n== B11 budget bars, %d-%d average (plot_gcb_bars()'s arithmetic) ==\n", win[1], win[2])
say("  ocean: model %.2f, GCB %.2f GtC/yr | land: model %.2f, GCB %.2f GtC/yr\n",
    mean(ann$ocean_sink[kk], na.rm = TRUE), mean(g$ocean_sink), mean(ann$land_sink[kk], na.rm = TRUE), mean(g$land_sink))
