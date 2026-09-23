# =====================================================================
# diag_app_cross_tab_step.R -- DO THE APP'S OWN TABS AGREE ON THE PAST?
#
# WHAT THIS MEASURES AND WHY IT IS OWED. `diag_app_params.R`'s gate 5 found a
# 13.1 ppm step at 2024 between the Keeling tab (scenario "historical" = the GCB
# budget) and the Futures tab (an SSP, whose historical segment is the SSP/LUH2
# harmonisation) -- two inventories over the same years, both drawn as "the
# model". That was measured 2026-08-21 at a pre-`hilda29l` parameter vector and
# before the periodic-spinup fix (09-21 i), so the NUMBER is stale even though
# the mechanism is parameter-independent. `notes/plan_2026-09-22_product_beta_
# and_writeup.md` §1 makes re-measuring it at `hilda29l` build item 1: it is an
# app-internal inconsistency a reviewer WILL find by flipping tabs, and the
# beta's whole purpose is to be reviewed.
#
# THE MEASUREMENT IS OF WHAT THE APP DRAWS, NOT OF A RECONSTRUCTION OF IT. This
# sources `app/global.R` -- the app's own startup, its own spinup, its own
# fitted forcing parameters -- and then calls the same run helpers `server.R`
# calls. A re-derived pipeline would be measuring a different object, which is
# the like-for-like rule.
#
# ⚠ THERE ARE THREE HISTORIES ON THIS APP, NOT TWO. `app_stylised_emissions()`
# (the "What if" tab) takes fossil from the GCB history and land-use from the
# SSP background, so its past matches NEITHER of the other two tabs. Gate 5 did
# not look at it. All three are scored below.
#
# Nothing here is a fix: the resolution (splice the SSP series onto the GCB
# history at the handover year, or caption the discontinuity, or both) is a
# ruling, and it needs this number first.
#
# Usage:  Rscript calibration/diag_app_cross_tab_step.R
# =====================================================================

XT_DATE       <- format(Sys.Date(), "%Y%m%d")
XT_HIST_TAB   <- "The Keeling Curve"        # tab 1: scenario "historical"
XT_FUT_TAB    <- "Futures"                  # tab 5: an SSP over APP_FUTURE_YEARS
XT_WHATIF_TAB <- "What if..."               # tab 3: stylised, hybrid inventory
XT_SCEN       <- "ssp245"                   # the Futures tab's default scenario
XT_READ_YEAR  <- 2024                       # the year the app's takeaway reads
XT_END_YEAR   <- 2100                       # what the step costs at the far end
XT_OUT <- file.path("outputs", "diagnostics",
                    sprintf("app_cross_tab_step_%s.log", XT_DATE))

# The app's startup, verbatim. getwd() must be the repo root; global.R resolves
# CCX_ROOT by walking up to DESIGN.md, so it works from either.
suppressPackageStartupMessages({
  library(shiny); library(bslib); library(ggplot2)
})
xt_warn <- character(0)
withCallingHandlers(
  source(file.path("app", "global.R")),
  warning = function(w) {
    xt_warn <<- c(xt_warn, conditionMessage(w)); invokeRestart("muffleWarning")
  })

xt_con <- file(XT_OUT, open = "wt")
xt <- function(fmt, ...) {
  s <- if (length(list(...))) sprintf(fmt, ...) else fmt
  cat(s, "\n", sep = ""); cat(s, "\n", sep = "", file = xt_con)
}

xt("=====================================================================")
xt("APP CROSS-TAB STEP -- do the app's tabs agree about the past?")
xt("  run       %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S"))
# Provenance only -- the parameters come from the app's own resolution above.
# Through ccx_load_mode(), not a direct read of the mode file: the direct form
# is what test-mode-struct-lint.R ratchets against, rightly -- it is one line
# away from running a HILDA mode as a column. (The lint is a LITERAL file-level
# match, so a comment spelling out the rejected pattern trips it too. Do not.)
xt_md <- ccx_load_mode()$md
xt("  mode      %s  (struct %s, %d fitted names, promoted %s)",
   basename(ccx_mode_file()), xt_md$struct, length(xt_md$param_names),
   as.character(xt_md$promoted_on))
xt("  spinup    %s", APP_SPINUP_LABEL)
xt("  params    %s", app_params$source)
xt("  commit    %s", tryCatch(
     trimws(system2("git", c("rev-parse", "--short", "HEAD"), stdout = TRUE)),
     error = function(e) "unknown"))
xt("  read year %d; scenario %s; horizon %d", XT_READ_YEAR, XT_SCEN, XT_END_YEAR)
xt("=====================================================================")

# ---- 1. THE INVENTORIES, cumulative over the shared years ------------
xt("\n1. THE EMISSIONS INVENTORIES, cumulative GtC 1750-%d", XT_READ_YEAR)

xt_cum <- local({
  h <- APP_EMIS_HIST
  s <- APP_SSP_EMIS[APP_SSP_EMIS$scenario == XT_SCEN, ]
  yy <- intersect(h$year, s$year); yy <- yy[yy <= XT_READ_YEAR]
  hh <- h[match(yy, h$year), ]; ss <- s[match(yy, s$year), ]
  # The What-if tab's hybrid, built by the app's own helper.
  em <- app_stylised_emissions("scenario", c(min(yy), XT_READ_YEAR),
                               background = XT_SCEN)
  em <- em[em$year %in% yy, ]
  data.frame(
    inventory = c("historical (GCB)", sprintf("%s (SSP/LUH2)", XT_SCEN),
                  "stylised hybrid"),
    tab       = c(XT_HIST_TAB, XT_FUT_TAB, XT_WHATIF_TAB),
    fossil    = c(sum(hh$fossil_GtC), sum(ss$fossil_GtC), sum(em$fossil_GtC)),
    luc       = c(sum(hh$luc_GtC),    sum(ss$luc_GtC),    sum(em$luc_GtC)),
    stringsAsFactors = FALSE)
})
xt_cum$total <- xt_cum$fossil + xt_cum$luc

for (i in seq_len(nrow(xt_cum)))
  xt("  %-22s  %-18s  fossil %6.1f   LUC %6.1f   total %6.1f",
     xt_cum$inventory[i], xt_cum$tab[i],
     xt_cum$fossil[i], xt_cum$luc[i], xt_cum$total[i])

xt("\n  differences against the historical (GCB) inventory:")
for (i in 2:nrow(xt_cum))
  xt("    %-22s  fossil %+6.1f   LUC %+6.1f   total %+6.1f GtC = %+5.1f ppm if fully airborne",
     xt_cum$inventory[i],
     xt_cum$fossil[i] - xt_cum$fossil[1],
     xt_cum$luc[i]    - xt_cum$luc[1],
     xt_cum$total[i]  - xt_cum$total[1],
     (xt_cum$total[i] - xt_cum$total[1]) / ccx_const("GtC_PER_PPM"))

# ---- 2. WHAT THE TABS ACTUALLY DRAW ----------------------------------
# Measured off the app's own run objects, not inferred from the inventories:
# the sinks are nonlinear, so the airborne-fraction arithmetic above is a scale
# check on the answer, never the answer.
xt("\n2. CO2 AT %d, AS EACH TAB DRAWS IT", XT_READ_YEAR)

xt_at <- function(year, y_series, t_series) {
  # Annual mean of the monthly series, the way the app's panels read it.
  k <- floor(t_series) == year
  if (!any(k)) return(NA_real_)
  mean(y_series[k])
}

xt_hist_ppm <- xt_at(XT_READ_YEAR, APP_HIST$out$co2_global, APP_HIST$out$t)

xt_fut <- app_run_coupled(APP_SPIN, XT_SCEN, APP_FUTURE_YEARS)
xt_fut_ppm <- xt_fut$climate$co2_ppm[xt_fut$climate$year == XT_READ_YEAR]

xt_whatif_em <- app_stylised_emissions("scenario", APP_FUTURE_YEARS,
                                       background = XT_SCEN)
xt_whatif <- app_run_coupled(APP_SPIN, XT_SCEN, APP_FUTURE_YEARS,
                             nonco2_scenario = XT_SCEN, emissions = xt_whatif_em)
xt_whatif_ppm <- xt_whatif$climate$co2_ppm[xt_whatif$climate$year == XT_READ_YEAR]

xt("  %-18s (%-16s)  %7.2f ppm", XT_HIST_TAB, "historical (GCB)", xt_hist_ppm)
xt("  %-18s (%-16s)  %7.2f ppm   step %+6.2f ppm", XT_FUT_TAB,
   XT_SCEN, xt_fut_ppm, xt_fut_ppm - xt_hist_ppm)
xt("  %-18s (%-16s)  %7.2f ppm   step %+6.2f ppm", XT_WHATIF_TAB,
   "stylised hybrid", xt_whatif_ppm, xt_whatif_ppm - xt_hist_ppm)

xt_obs <- local({
  # The two stations the Keeling tab plots; their mean is the closest thing the
  # app draws to a global number. ⚠ NOT a global mean of the record -- two
  # stations, and the model box sits above them by `rep_dC` by construction.
  co2 <- APP_OBS$co2
  k <- co2$year == XT_READ_YEAR
  if (!any(k)) NA_real_ else
    mean(tapply(co2$co2_ppm[k], co2$station[k], mean, na.rm = TRUE), na.rm = TRUE)
})
xt("\n  MLO/SPO station mean at %d (what the Keeling tab plots against): %.2f ppm",
   XT_READ_YEAR, xt_obs)
xt("  the model box is expected ABOVE it by rep_dC = %.2f ppm, by construction",
   APP_REP_DC)

# ---- 3. WHAT THE STEP COSTS AT THE HORIZON ---------------------------
xt("\n3. THE STEP AT %d -- every future the app draws carries it", XT_END_YEAR)
xt_fut_end <- xt_fut$climate$co2_ppm[xt_fut$climate$year == XT_END_YEAR]
xt("  %s at %d: %.1f ppm, carrying the %+.2f ppm deficit it inherited at %d",
   XT_SCEN, XT_END_YEAR, xt_fut_end, xt_fut_ppm - xt_hist_ppm, XT_READ_YEAR)

xt("\n=====================================================================")
xt("READING. The step is an EMISSIONS-INVENTORY difference, not a parameter")
xt("difference: the same fitted vector and the same spinup draw both curves.")
xt("The resolution is a ruling -- splice the SSP series onto the GCB history at")
xt("the handover year, or caption the discontinuity on both tabs, or both.")
xt("=====================================================================")

# ---- 4. WARNINGS RAISED BY THE APP'S OWN STARTUP ---------------------
# Read, not suppressed: "There were 50 or more warnings" is exactly the shape a
# real defect hides in.
xt("\n4. WARNINGS FROM app/global.R STARTUP: %d, %d distinct", length(xt_warn),
   length(unique(xt_warn)))
for (w in sort(unique(xt_warn)))
  xt("  x%-4d %s", sum(xt_warn == w), substr(w, 1, 110))

close(xt_con)
cat("\nwritten: ", XT_OUT, "\n", sep = "")
