#!/usr/bin/env Rscript
# =====================================================================
# diag_app_wobble_shares.R -- the What-if tab's WOBBLE SHARES, measured on the app's own
# estimator at whatever canonical this tree registers (2026-10-03).
#
# WHY. R/mechanisms.R's `enso` entry TYPES two measured claims into the copy:
#   blurb   "switch it off and about a quarter of the wobble goes with it"     (ENSO off)
#   caveat  "...about a third of the wobble remains"   (ENSO + warming + volcanic light off)
# Both were measured at hilda33d on 10-02 (CHANGELOG 10-02 w: full 0.268 ppm/yr, ENSO -28 %,
# all three -67 %) by a run that was never committed. No test re-measures them --
# test-app-review-copy pins the WORDS -- so adopting a new canonical can make them false in
# silence. This measures them, and its gate is that the registered hilda33d reproduces the
# recorded 10-02 values to their printed precision before anything else it says counts.
#
# THE ESTIMATOR is app/server.R's output$c_growth_note, replicated line for line: the sd of
# the residuals of annual growth (app_annual_growth, the app's ONE definition) about
# lm(g ~ ns(year, df = 3)), over the slider's default window intersected with the observed
# record's span (app_obs_growth(APP_OBS_GROWTH)). The switched runs are app_run_mechanisms(off).
# Nothing here changes the model or the app. No RNG. Run from the repo root:
#   Rscript calibration/diag_app_wobble_shares.R
# =====================================================================
t_start <- Sys.time()
ROOT <- normalizePath(getwd())
stopifnot(file.exists(file.path(ROOT, "app", "global.R")))
setwd(file.path(ROOT, "app"))
invisible(capture.output(suppressMessages(suppressWarnings(
  shiny::loadSupport(getwd(), renv = globalenv(), globalrenv = globalenv())))))
setwd(ROOT)

# ---- named constants (every label below derives from these) -----------------------------
WS_DRIVER  <- "calibration/diag_app_wobble_shares.R"
WS_SLIDER  <- c(1850L, APP_HIST_YEARS[2])          # = ui.R's c_years default
WS_DF      <- 3L                                   # = server.R's ns(year, df = 3)
WS_ARMS    <- list(full = character(0), enso = "enso", warming = "warming_feedback", volcanic = "volcanic",
                   all_three = c("enso", "warming_feedback", "volcanic"))
WS_TYPED   <- c(enso = "about a quarter of the wobble goes", all_three = "about a third of the wobble remains")
WS_REC     <- list(mode = "hilda33d", full = 0.268, share_enso = 0.28, share_all = 0.67)   # CHANGELOG 10-02 (w)
WS_REC_TOL <- c(full = 0.0005, share = 0.005)      # half a unit in each recorded number's last printed digit
stopifnot(all(unlist(WS_ARMS) %in% names(CCX_MECHANISMS)))
WS_OUT <- file.path("outputs", "diagnostics", sprintf("app_wobble_shares_%s_%s", format(Sys.Date(), "%Y%m%d"), CCX_MODE_CANONICAL))
commit <- tryCatch(system2("git", c("-C", ROOT, "rev-parse", "--short", "HEAD"), stdout = TRUE), error = function(e) NA_character_)
dirty  <- tryCatch(length(system2("git", c("-C", ROOT, "status", "--porcelain", "--untracked-files=no"), stdout = TRUE)) > 0,
                   error = function(e) NA)
sink(paste0(WS_OUT, ".log"), split = TRUE)
cat(sprintf("%s | commit %s%s | canonical %s (%s) | %s\n", WS_DRIVER, commit, if (isTRUE(dirty)) " (+uncommitted)" else "",
            CCX_MODE_CANONICAL, basename(dirname(ccx_mode_file())), format(Sys.time(), "%Y-%m-%d %H:%M")))

# ---- the estimator (server.R's c_growth_note) ---------------------------------------------
ob  <- app_obs_growth(APP_OBS_GROWTH)
win <- c(max(WS_SLIDER[1], min(ob$year)), min(WS_SLIDER[2], max(ob$year)))
scatter <- function(g) {
  g <- g[g$year >= win[1] & g$year <= win[2], ]
  if (nrow(g) < GROWTH_RESID_MIN_YEARS) return(NA_real_)
  stats::sd(stats::residuals(stats::lm(g ~ splines::ns(year, df = WS_DF), data = g)))
}
# GATE: the full arm through app_run_mechanisms() IS the app's own historical run (APP_HIST)
full_run <- app_run_mechanisms(WS_ARMS$full)
g_app <- app_annual_growth(APP_HIST$out); g_ws <- app_annual_growth(full_run$out)
stopifnot(identical(g_app$year, g_ws$year))
cat(sprintf("gate: the no-switch run vs APP_HIST, max |d growth| %.1e ppm/yr\n", max(abs(g_app$g - g_ws$g))))
if (max(abs(g_app$g - g_ws$g)) > 1e-10) stop("the no-switch arm is not the app's own historical run")

S <- vapply(names(WS_ARMS), function(a) {
  r <- if (a == "full") full_run else app_run_mechanisms(WS_ARMS[[a]])
  scatter(app_annual_growth(r$out)) }, 0)
s_obs <- scatter(ob)
cat(sprintf("\nwindow %d-%d (the slider's default %d-%d inside the observed record %d-%d); n = %d years\n",
            win[1], win[2], WS_SLIDER[1], WS_SLIDER[2], min(ob$year), max(ob$year), sum(ob$year >= win[1] & ob$year <= win[2])))
cat(sprintf("observed scatter %.3f ppm/yr; full model %.3f (%.0f %% of observed)\n", s_obs, S[["full"]], 100 * S[["full"]] / s_obs))
tab <- data.frame(arm = names(S), switched_off = vapply(WS_ARMS, paste, "", collapse = " + "),
                  scatter = round(S, 4), share_removed = round(1 - S / S[["full"]], 4), remaining = round(S / S[["full"]], 4))
print(tab, row.names = FALSE)
cat(sprintf("\nthe copy's typed claims: ENSO off \"%s\" -> measured %.0f %% removed; all three off \"%s\" -> measured %.0f %% remains\n",
            WS_TYPED[["enso"]], 100 * (1 - S[["enso"]] / S[["full"]]), WS_TYPED[["all_three"]], 100 * S[["all_three"]] / S[["full"]]))

# ---- the reproduction gate at the recorded mode --------------------------------------------
if (identical(CCX_MODE_CANONICAL, WS_REC$mode)) {
  d <- c(full = abs(S[["full"]] - WS_REC$full), enso = abs((1 - S[["enso"]] / S[["full"]]) - WS_REC$share_enso),
         all = abs((1 - S[["all_three"]] / S[["full"]]) - WS_REC$share_all))
  ok <- d[["full"]] <= WS_REC_TOL[["full"]] && d[["enso"]] <= WS_REC_TOL[["share"]] && d[["all"]] <= WS_REC_TOL[["share"]]
  cat(sprintf("REPRODUCTION GATE at %s vs CHANGELOG 10-02 (w): |d| full %.4f, ENSO share %.4f, all-three share %.4f -> %s\n",
              WS_REC$mode, d[["full"]], d[["enso"]], d[["all"]], if (ok) "REPRODUCES" else "DOES NOT REPRODUCE"))
  if (!ok) stop("the recorded 10-02 shares do not reproduce: the estimator or the arms differ from what produced them")
} else cat(sprintf("(no reproduction gate: the recorded values are %s's; this tree's canonical is %s)\n", WS_REC$mode, CCX_MODE_CANONICAL))
sink()
saveRDS(list(scatter = S, observed = s_obs, window = win, table = tab, typed = WS_TYPED,
             provenance = list(driver = WS_DRIVER, commit = commit, dirty = dirty, canonical = CCX_MODE_CANONICAL,
                               mode_file = ccx_mode_file(), rng = "none", date = format(Sys.time(), "%Y-%m-%d %H:%M"))),
        paste0(WS_OUT, ".rds"))
cat(sprintf("saved %s.{log,rds} | %.1f min\n", WS_OUT, as.numeric(difftime(Sys.time(), t_start, units = "mins"))))
