# =====================================================================
# make_record.R -- the pulse lab's ocean-by-depth split, as the app computes it (2026-10-16)
#
# Runs the Pulse lab EXACTLY as app/server.R does (APP_SPIN, app_run_coupled() with
# keep_forcing, app_pulse_depth_runs(), app_pulse_partition_table()) and writes both panels'
# shares at chosen offsets after the release, each row stamped with its provenance (every
# instant is one rerun away; a per-row stamp made that table 1.3 MB). Deterministic: no RNG
# anywhere on this path (verified by running twice and comparing bytes; see README.md).
#
# Usage, from the repo root:  Rscript outputs/diagnostics/pulse_ocean_depth_20261016/make_record.R
# =====================================================================
RECORD_BG      <- "vvM"                       # the pulse lab's default background
RECORD_YEAR    <- 2050L                       # release year (the slider's default)
RECORD_GTC     <- 100                         # pulse size, GtC (the slider's default)
RECORD_OFFSETS <- c(1, 5, 10, 20, 50, 100, 150, 200, 250)   # yr after release, read at year + 0.5
RECORD_DIR     <- file.path("outputs", "diagnostics", "pulse_ocean_depth_20261016")
RECORD_STEM    <- sprintf("pulse_ocean_depth_%s_%d_%gGtC", RECORD_BG, RECORD_YEAR, RECORD_GTC)

stopifnot(file.exists("DESIGN.md"))
root <- getwd()
suppressMessages({ library(shiny); library(ggplot2); old <- setwd("app"); source("global.R")
  for (f in sort(list.files("R", pattern = "\\.R$", full.names = TRUE))) source(f); setwd(old) })
setwd(root)

yrs <- APP_PULSE_YEARS
bg  <- APP_SCEN_EMIS[APP_SCEN_EMIS$scenario == RECORD_BG, ]
y   <- seq(yrs[1], yrs[2])
base_em <- data.frame(year = y,
                      fossil_GtC = stats::approx(bg$year, bg$fossil_GtC, xout = y, rule = 2)$y,
                      luc_GtC    = stats::approx(bg$year, bg$luc_GtC,    xout = y, rule = 2)$y)
pulse_em <- base_em
pulse_em$fossil_GtC[pulse_em$year == RECORD_YEAR] <- pulse_em$fossil_GtC[pulse_em$year == RECORD_YEAR] + RECORD_GTC
run <- function(em, ...) app_run_coupled(APP_SPIN, RECORD_BG, yrs, RECORD_BG, emissions = em,
                                         interp_method = APP_PULSE_EMIS_METHOD, keep_forcing = TRUE, ...)
runs <- list(base = run(base_em), pulse = run(pulse_em), tagged = run(pulse_em, c14_tag_base = base_em))
dr  <- app_pulse_depth_runs(APP_SPIN, runs, RECORD_YEAR)
tab <- app_pulse_partition_table(dr, RECORD_GTC)

b <- app_ocean_depth_bounds(APP_SPIN$grid)
W <- app_ocean_depth_weights(APP_SPIN)
mm <- vapply(c("base", "pulse", "tagged"), function(n) attr(dr[[n]], "mismatch")$max, numeric(1))
prov <- sprintf(paste("%s @ %s; canonical %s (%s); %s background, %g GtC released over %d (%s emissions);",
                      "groups ML+HS+oc1-%d / oc%d-%d / oc%d-%d, HD split by depth (h_hs %.1f m;",
                      "bounds %.1f / %.1f m; HD shares %.4f / %.4f / %.4f); instants mid-year;",
                      "chain vs unsplit max rel %.2g (bound %.2g); share of the pulse, %%; no RNG"),
                file.path(RECORD_DIR, "make_record.R"), ccx_git_stamp(), CCX_MODE_CANONICAL,
                basename(dirname(ccx_mode_file())), RECORD_BG, RECORD_GTC, RECORD_YEAR, APP_PULSE_EMIS_METHOD,
                OCEAN_DEPTH_LAST_LAYER[["upper"]], OCEAN_DEPTH_LAST_LAYER[["upper"]] + 1L,
                OCEAN_DEPTH_LAST_LAYER[["intermediate"]], OCEAN_DEPTH_LAST_LAYER[["intermediate"]] + 1L,
                APP_SPIN$grid$nl, APP_SPIN$aux$h_hs, b[2], b[3],
                W["NH_hd", "upper"], W["NH_hd", "intermediate"], W["NH_hd", "deep"],
                max(mm), attr(dr$pulse, "mismatch")$bound)

tab$pct <- 100 * tab$frac

pick <- do.call(rbind, lapply(RECORD_OFFSETS, function(o) {
  d <- tab[abs(tab$t - (RECORD_YEAR + OCEAN_DEPTH_INSTANT_OFFSET + o)) < 1e-6, ]
  stopifnot(nrow(d) == 2L * nlevels(tab$where))
  data.frame(offset_yr = o, t = d$t, panel = d$panel, reservoir = d$where, pct = d$pct)
}))
pick$provenance <- prov
write.csv(pick, file.path(RECORD_DIR, paste0(RECORD_STEM, "_offsets.csv")), row.names = FALSE)

# the console table the README quotes
for (pn in levels(tab$panel)) {
  cat("\n==", pn, "== (% of the pulse at release year + 0.5 + offset)\n")
  m <- sapply(RECORD_OFFSETS, function(o) { d <- pick[pick$panel == pn & pick$offset_yr == o, ]
                                           d$pct[order(d$reservoir)] })
  dimnames(m) <- list(levels(tab$where), paste0("+", RECORD_OFFSETS))
  print(round(m, 2))
}
cat("\n", prov, "\n")
