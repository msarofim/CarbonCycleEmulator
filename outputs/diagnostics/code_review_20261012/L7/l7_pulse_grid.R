# L7: how background/year move the pulse box's per-1000 figure, and the lifted ribbons vs the central line
ROOT <- "/Users/MarcusMarcus/Documents/2026/CodeProjects/CarbonCycleEmulator"
setwd(file.path(ROOT, "app"))
suppressPackageStartupMessages(source("global.R"))
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
# server.R's pulse_runs(), base and pulse arms, verbatim construction
pulse_pair <- function(bgk, year, gtc, yrs = APP_PULSE_YEARS) {
  bg <- APP_SCEN_EMIS[APP_SCEN_EMIS$scenario == bgk, ]
  y <- seq(yrs[1], yrs[2])
  base_em <- data.frame(year = y,
    fossil_GtC = stats::approx(bg$year, bg$fossil_GtC, xout = y, rule = 2)$y,
    luc_GtC    = stats::approx(bg$year, bg$luc_GtC,    xout = y, rule = 2)$y)
  pulse_em <- base_em
  pulse_em$fossil_GtC[pulse_em$year == year] <- pulse_em$fossil_GtC[pulse_em$year == year] + gtc
  b <- app_run_coupled(APP_SPIN, bgk, yrs, bgk, emissions = base_em, interp_method = APP_PULSE_EMIS_METHOD)
  p <- app_run_coupled(APP_SPIN, bgk, yrs, bgk, emissions = pulse_em, interp_method = APP_PULSE_EMIS_METHOD)
  d <- p$climate$gmst - b$climate$gmst
  at <- function(yy) d[which.min(abs(b$climate$year - yy))]
  c(per1000_100 = at(year + 100) / gtc * 1000, per1000_20 = at(year + 20) / gtc * 1000,
    per1000_200 = if (year + 200 <= yrs[2]) at(year + 200) / gtc * 1000 else NA)
}
cat("box sentence constants: about", APP_PULSE_PER1000_ABOUT, "+-", APP_PULSE_PER1000_ABOUT_TOL,
    "; spread", APP_PULSE_LIN_SPREAD, "% over", APP_PULSE_LIN_SIZES, "; src:", APP_PULSE_LIN_SRC, "\n")
res <- NULL
for (bgk in c("vvLN", "vvM", "vvH")) for (yr in c(2030, 2050, 2100)) for (g in c(10, 100, 500)) {
  v <- suppressWarnings(pulse_pair(bgk, yr, g))
  res <- rbind(res, data.frame(bg = bgk, year = yr, gtc = g, t(round(v, 3))))
}
print(res)
sp <- aggregate(per1000_100 ~ bg + year, res, function(x) 100 * diff(range(x)) / mean(x))
names(sp)[3] <- "spread_pct_10_to_500"; print(sp)

# ---- lifted ribbons vs the app's own central line
r <- readRDS(APP_RIBBONS_FILE)
for (s in APP_SCENARIOS) {
  cl <- suppressWarnings(app_run_coupled(APP_SPIN, s, APP_FUTURE_YEARS))$climate
  b <- r$bands[r$bands$scenario == s & r$bands$var == "co2_ppm", ]
  m <- match(b$year, cl$year)
  v <- cl$co2_ppm[m]
  k <- b$year >= APP_FUTURE_VIEW[1] & b$year <= APP_FUTURE_VIEW[2]
  cat(sprintf("%-5s co2: central outside [q05,q95] in %d of %d view years; max |central - q50| %.3f ppm; width@2150 %.1f ppm\n",
              s, sum((v[k] < b$q05[k]) | (v[k] > b$q95[k])), sum(k), max(abs(v[k] - b$q50[k])),
              (b$q95 - b$q05)[b$year == 2150]))
}
