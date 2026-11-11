#!/usr/bin/env Rscript
# proto_b14.R -- group B item B14 (2026-11-11): where the airborne-fraction curve starts to mean something.
# MEASURES the monthly ratio's within-year swing against the year, then RENDERS the current panel and two
# alternatives at the live panel size (half width, 260 px tall) with the app's own theme. Changes no app code: the
# alternatives are local re-statements of plot_airborne_fraction() (app/R/plots.R) with one change each.
# Usage (repo root): Rscript outputs/diagnostics/groupb_20261111/proto_b14.R      # no RNG
ROOT <- normalizePath(getwd()); stopifnot(file.exists(file.path(ROOT, "app", "global.R")))
setwd(file.path(ROOT, "app"))
invisible(capture.output(suppressMessages(suppressWarnings(
  shiny::loadSupport(getwd(), renv = globalenv(), globalrenv = globalenv())))))
setwd(ROOT)

# ---- named constants ------------------------------------------------------------
PB_OUT     <- file.path("outputs", "diagnostics", "groupb_20261111", "proto")
PB_SWING   <- c(0.10, 0.05, 0.02)        # within-year swing of the monthly ratio, as a fraction (10, 5, 2 points)
PB_W_PX    <- 520L; PB_H_PX <- 260L      # the live w_af image at 1440 px (half-width column), 260 px tall (ui.R)
PB_RES     <- 96                          # renderPlot's resolution
PB_GCB_START <- min(APP_GCB$year)         # where GCB's annual budget begins
dir.create(PB_OUT, showWarnings = FALSE, recursive = TRUE)
LOG <- file.path(PB_OUT, "proto_b14.log"); if (file.exists(LOG)) file.remove(LOG)
say <- function(...) { txt <- sprintf(...); cat(txt); cat(txt, file = LOG, append = TRUE) }
say("proto_b14.R | commit %s | canonical %s | %s\n", ccx_git_stamp(), CCX_MODE_CANONICAL, format(Sys.time(), "%Y-%m-%d %H:%M"))

F <- app_build_forcing("historical", APP_HIST_YEARS, prod_c14 = APP_SPIN$prod_c14)
pt <- partition_table(APP_HIST$out, F)
pt$af <- pt$atmosphere / pt$emitted
pt$year <- floor(pt$t + 1e-9)
yr <- stats::aggregate(cbind(af = af, emitted = emitted, atm = atmosphere) ~ year, data = pt[pt$emitted > 1, ],
                       FUN = function(x) c(mean = mean(x), lo = min(x), hi = max(x)))
sw <- data.frame(year = yr$year, swing = yr$af[, "hi"] - yr$af[, "lo"], af_mean = yr$af[, "mean"],
                 emitted = yr$emitted[, "mean"], atm_range = yr$atm[, "hi"] - yr$atm[, "lo"])
say("\n=== the monthly ratio (cumulative airborne / cumulative emitted) per year, from the first month emitted > 1 GtC ===\n")
for (y in c(sw$year[1], 1760, 1780, 1800, 1825, 1850, 1875, 1900, 1925, 1950, 1959, 2000, max(sw$year)))
  with(sw[sw$year == y, ], say("  %d: cumulative emitted %6.1f GtC; airborne carbon's within-year range %.2f GtC; ratio's swing %5.1f points (mean %.0f%%)\n",
                                year, emitted, atm_range, 100 * swing, 100 * af_mean))
first_below <- vapply(PB_SWING, function(s) { bad <- sw$year[sw$swing >= s]; if (length(bad)) max(bad) + 1 else sw$year[1] }, 0)
for (i in seq_along(PB_SWING)) say("  the swing stays below %2.0f points from %d on (cumulative emitted then %.0f GtC)\n",
                                   100 * PB_SWING[i], first_below[i], sw$emitted[sw$year == first_below[i]])
say("  GCB's annual budget begins %d\n", PB_GCB_START)

# ---- the panels -------------------------------------------------------------------
base_af <- function(d, cap) ggplot(d, aes(t, af)) +
  geom_hline(yintercept = 0.5, colour = "grey75", linewidth = 0.3, linetype = "22") +
  geom_line(colour = PAL[["model"]], linewidth = 0.8) +
  scale_y_continuous(labels = function(x) paste0(round(100 * x), "%")) +
  labs(x = LAB_YEAR, y = "Share of all emissions still in the air", caption = app_provenance_caption(cap, panel = "half")) +
  scale_x_continuous(breaks = app_year_breaks()) + theme_ccx()
save_panel <- function(p, name) {
  f <- file.path(PB_OUT, paste0(name, ".png"))
  ragg::agg_png(f, width = PB_W_PX, height = PB_H_PX, res = PB_RES); print(p); grDevices::dev.off(); say("  wrote %s\n", f)
}
say("\n=== panels (%d x %d px, res %d) ===\n", PB_W_PX, PB_H_PX, PB_RES)
# (0) as drawn today, default window and 1750-1900
for (w in list(c(1750, 2024), c(1750, 1900)))
  save_panel(plot_airborne_fraction(pt, w), sprintf("b14_now_%d_%d", w[1], w[2]))
# (A) annual means of both stocks (removes the seasonal cycle from the numerator), from the 5-point year
ann <- stats::aggregate(cbind(atmosphere, emitted) ~ year, data = pt, FUN = mean)
ann <- ann[ann$year >= first_below[2], ]; ann$t <- ann$year + 0.5; ann$af <- ann$atmosphere / ann$emitted
for (w in list(c(1750, 2024), c(1750, 1900)))
  save_panel(base_af(ann[ann$t >= w[1] & ann$t <= w[2], ],
                     sprintf("Annual means, from %d (before then too little has been emitted for the ratio to settle). Dashed line at 50%%.", first_below[2])),
             sprintf("b14_A_annual_from%d_%d_%d", first_below[2], w[1], w[2]))
# (B) the monthly ratio as today, but starting at GCB's first year
gcb <- pt[pt$t >= PB_GCB_START & pt$emitted > 1, ]
save_panel(base_af(gcb[gcb$t <= 2025, ], sprintf("From %d, the first year of the Global Carbon Budget. Dashed line at 50%%.", PB_GCB_START)),
           sprintf("b14_B_monthly_from%d", PB_GCB_START))
saveRDS(list(swing = sw, first_below = stats::setNames(first_below, PB_SWING), gcb_start = PB_GCB_START,
             provenance = list(script = "outputs/diagnostics/groupb_20261111/proto_b14.R", commit = ccx_git_stamp(),
                               canonical = CCX_MODE_CANONICAL, rng = "none", date = format(Sys.time()))),
        file.path(PB_OUT, "proto_b14.rds"))

# ---- the ANNUAL-MEAN ratio's own noise: does averaging let the curve start earlier? ----------------------------
# With the seasonal cycle averaged out, what is left early is year-to-year variability over a small denominator.
# Measured as the absolute change of the annual-mean ratio from one year to the next.
yy <- floor(pt$t + 1e-9); nn <- table(yy); full <- as.integer(names(nn)[nn == 12])
am <- stats::aggregate(cbind(atmosphere, emitted) ~ year, data = data.frame(year = yy, pt)[yy %in% full, ], FUN = mean)
am <- am[am$emitted > 1, ]; am$af <- am$atmosphere / am$emitted; am$jump <- c(NA, abs(diff(am$af)))
say("\n=== the annual-mean ratio and its year-to-year change ===\n")
for (y in c(am$year[2], 1760, 1780, 1800, 1825, 1850, 1875, 1900, 1950, 2000))
  with(am[am$year == y, ], say("  %d: annual-mean ratio %5.1f%%, change from the year before %4.1f points\n", year, 100 * af, 100 * jump))
first_jump <- vapply(c(0.02, 0.01, 0.005), function(s) { bad <- am$year[!is.na(am$jump) & am$jump >= s]; if (length(bad)) max(bad) + 1 else am$year[1] }, 0)
for (i in seq_along(first_jump)) say("  year-to-year change stays below %.1f points from %d on\n", 100 * c(0.02, 0.01, 0.005)[i], first_jump[i])
