#!/usr/bin/env Rscript
# =====================================================================
# diag_warming_switch_split.R -- the What-if WARMING switch's effect on CO2 today, split into the
# temperature paths it zeroes, on the app's own runner and estimator at whatever canonical this
# tree registers (2026-10-06).
#
# WHY. Since hilda33p the switch (R/mechanisms.R `warming_feedback`) also removes the
# stratification feedback (DESIGN §3.4a S), and its caveat now says so as "a third, smaller
# effect" (Marcus 2026-10-06: "Caveat sentence (Recommended)"). "Smaller" is a measured claim,
# and this is the measurement. test-mechanisms.R guards the ORDERING at the canonical; this
# records the numbers.
#
# THE PATHS are the parameters the switch zeroes, one knockout each, everything else at the mode:
#   soil      q10 -> 1                       (heterotrophic respiration's temperature response)
#   seawater  sst_scale -> 0, sst_obs -> 0   (solubility and chemistry through SST; ONE path,
#                                            both columns, as the switch itself zeroes both)
#   greening  npp_tsens -> 0                 (pinned at 0 in hilda33p: expected exactly 0 there)
#   mixing    mix_strat_s -> 0               (the stratification feedback; 0 is OFF bit for bit)
# The switch also zeroes the gmst INPUT; with the four zeroed the run is already blind to it
# (test-mechanisms.R), so it is not a fifth path.
#
# THE ESTIMATOR is app/server.R's output$c_takeaway: co2_global = (co2_NH + co2_SH) / 2 at the
# LAST row of the historical run ("CO2 today would be X ppm instead of Y"). The 2024 annual mean
# is printed beside it. Nothing here changes the model or the app. No RNG. Run from the repo root:
#   Rscript calibration/diag_warming_switch_split.R
# =====================================================================
t_start <- Sys.time()
ROOT <- normalizePath(getwd())
stopifnot(file.exists(file.path(ROOT, "app", "global.R")))
setwd(file.path(ROOT, "app"))
invisible(capture.output(suppressMessages(suppressWarnings(
  shiny::loadSupport(getwd(), renv = globalenv(), globalrenv = globalenv())))))
setwd(ROOT)

# ---- named constants (every label below derives from these) -----------------------------
WW_DRIVER <- "calibration/diag_warming_switch_split.R"
WW_SWITCH <- "warming_feedback"
WW_PATHS  <- list(soil     = list(q10 = 1),
                  seawater = list(sst_scale = 0, sst_obs = 0),
                  greening = list(npp_tsens = 0),
                  mixing   = list(mix_strat_s = 0))
WW_TYPED  <- "It also removes a third, smaller effect"   # the caveat's claim: mixing < soil and < seawater
WW_ANNUAL <- 2024L                                       # the annual-mean year printed beside the app's last row
stopifnot(WW_SWITCH %in% names(CCX_MECHANISMS),
          grepl(WW_TYPED, CCX_MECHANISMS[[WW_SWITCH]]$caveat, fixed = TRUE))
WW_OUT <- file.path("outputs", "diagnostics",
                    sprintf("warming_switch_split_%s_%s", format(Sys.Date(), "%Y%m%d"), CCX_MODE_CANONICAL))
commit <- ccx_git_stamp()
dirty  <- ccx_stamp_dirty(commit)   # the rds keeps `dirty`: TRUE / FALSE / NA = git could not tell
sink(paste0(WW_OUT, ".log"), split = TRUE)
cat(sprintf("%s | commit %s | canonical %s (%s) | %s\n", WW_DRIVER, commit,
            CCX_MODE_CANONICAL, basename(dirname(ccx_mode_file())), format(Sys.time(), "%Y-%m-%d %H:%M")))

# ---- the runner: app_run_mechanisms() line for line, with ONE path knocked out ------------
run_knockout <- function(set) {
  F0 <- suppressWarnings(app_build_forcing("historical", APP_HIST_YEARS, prod_c14 = 0))
  p <- APP_PARAMS; for (n in names(set)) { stopifnot(!is.null(p[[n]])); p[[n]] <- set[[n]] }
  sp <- app_spinup(p); F0$c14_cosmo <- sp$prod_c14
  o <- ccx_run_fast(sp, F0)$out
  o$co2_global <- (o$co2_NH + o$co2_SH) / 2
  o
}
today  <- function(o) o$co2_global[nrow(o)]
annual <- function(o) mean(o$co2_global[floor(o$t) == WW_ANNUAL])

# GATES: the no-knockout arm IS the app's historical run, and the switch arm is the app's own
full <- run_knockout(list())
g1 <- abs(today(full) - APP_HIST$out$co2_global[nrow(APP_HIST$out)])
cat(sprintf("gate 1: the no-knockout run vs APP_HIST, |d CO2 today| %.1e ppm\n", g1))
if (g1 > 1e-10) stop("the no-knockout arm is not the app's own historical run")
sw <- app_run_mechanisms(WW_SWITCH)$out
cat(sprintf("the app's sentence: \"CO2 today would be %.0f ppm instead of %.0f\" (%.3f vs %.3f)\n",
            today(sw), today(full), today(sw), today(full)))
for (n in names(WW_PATHS))
  cat(sprintf("  path %-8s : %s (at the mode: %s)\n", n,
              paste(sprintf("%s -> %g", names(WW_PATHS[[n]]), unlist(WW_PATHS[[n]])), collapse = ", "),
              paste(sprintf("%s = %.6g", names(WW_PATHS[[n]]), unlist(APP_PARAMS[names(WW_PATHS[[n]])])), collapse = ", ")))

arms <- lapply(WW_PATHS, run_knockout)
d_today  <- vapply(arms, function(o) today(full) - today(o), 0)
d_annual <- vapply(arms, function(o) annual(full) - annual(o), 0)
tot_today <- today(full) - today(sw); tot_annual <- annual(full) - annual(sw)
tab <- data.frame(path = c(names(WW_PATHS), "SUM of the singles", "the switch (all at once)"),
                  d_co2_today_ppm = round(c(d_today, sum(d_today), tot_today), 4),
                  share_of_switch = round(c(d_today, sum(d_today), tot_today) / tot_today, 4),
                  d_co2_annual_ppm = round(c(d_annual, sum(d_annual), tot_annual), 4))
names(tab)[4] <- sprintf("d_co2_%d_mean_ppm", WW_ANNUAL)
cat("\nCO2 removed by each knockout (full minus knocked out; + = the path raises CO2):\n")
print(tab, row.names = FALSE)
ord <- d_today[["mixing"]] > 0 && d_today[["mixing"]] < d_today[["soil"]] && d_today[["mixing"]] < d_today[["seawater"]]
cat(sprintf("\nthe caveat's claim \"%s\": mixing %.3f ppm vs soil %.3f and seawater %.3f -> %s\n",
            WW_TYPED, d_today[["mixing"]], d_today[["soil"]], d_today[["seawater"]], if (ord) "HOLDS" else "DOES NOT HOLD"))
sink()
saveRDS(list(d_today = d_today, d_annual = d_annual, switch_today = tot_today, switch_annual = tot_annual,
             full_today = today(full), switch_run_today = today(sw), table = tab, claim_holds = ord,
             provenance = list(driver = WW_DRIVER, commit = commit, dirty = dirty, canonical = CCX_MODE_CANONICAL,
                               mode_file = ccx_mode_file(), estimator = "co2_global at the last row (server.R c_takeaway)",
                               rng = "none", date = format(Sys.time(), "%Y-%m-%d %H:%M"))),
        paste0(WW_OUT, ".rds"))
cat(sprintf("saved %s.{log,rds} | %.1f min\n", WW_OUT, as.numeric(difftime(Sys.time(), t_start, units = "mins"))))
