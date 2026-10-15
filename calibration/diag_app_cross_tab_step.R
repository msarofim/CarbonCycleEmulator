# =====================================================================
# diag_app_cross_tab_step.R -- DO THE APP'S OWN TABS AGREE ON THE PAST?
#
# WHAT THIS MEASURES AND WHY IT IS OWED. `diag_app_params.R`'s gate 5 found a
# 13.1 ppm step at 2024 between the Keeling tab (scenario "historical" = the GCB
# budget) and the Futures tab (an SSP, whose historical segment is the SSP/LUH2
# harmonization) -- two inventories over the same years, both drawn as "the
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
# (the Futures tab's "Build your own" pill) takes fossil from the GCB history and
# land-use from the SSP background, so its past matches NEITHER of the other
# two. Gate 5 did not look at it. All three are scored below.
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
# ⚠ The stylized pathway is a PILL INSIDE the Futures tab ("Build your own"),
# not the "What if...?" tab, which is the MECHANISM tab and runs the historical
# scenario over 1750-2024 -- i.e. on the GCB budget, with no step.
XT_WHATIF_TAB <- "Futures > Build own"      # the stylized, hybrid inventory
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

XT_COMMIT <- ccx_git_stamp()
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
xt("  commit    %s", XT_COMMIT)
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

# ---- 2. WHAT THE TABS DRAW, BEFORE AND AFTER THE SPLICE ---------------
# Measured off the app's own run objects, not inferred from the inventories:
# the sinks are nonlinear, so the airborne-fraction arithmetic above is a scale
# check on the answer, never the answer.
#
# BEFORE = ccx_run_coupled() called directly with the app's fitted forcing
# parameters, which is what the tabs did until 09-22. AFTER = app_run_coupled(),
# which splices. Both arms differ in ONE thing.
xt("\n2. CO2 AT %d, AS EACH TAB DRAWS IT", XT_READ_YEAR)

xt_at <- function(year, y_series, t_series) {
  # Annual mean of the monthly series, the way the app's panels read it.
  k <- floor(t_series) == year
  if (!any(k)) return(NA_real_)
  mean(y_series[k])
}

xt_hist_ppm <- xt_at(XT_READ_YEAR, APP_HIST$out$co2_global, APP_HIST$out$t)

xt_unspliced <- function(scenario, emissions = NULL) {
  ccx_run_coupled(APP_SPIN, scenario, APP_FUTURE_YEARS,
                  nonco2_scenario = scenario, emissions = emissions,
                  bomb_total_kmol = APP_BOMB_TOTAL, luc_scale = APP_LUC_SCALE)
}
xt_read <- function(r, year) r$climate$co2_ppm[r$climate$year == year]

# The stylized table, exactly as server.R builds it for the Build-your-own pill.
xt_sty_em <- app_stylised_emissions("scenario", APP_FUTURE_YEARS,
                                    background = XT_SCEN)

xt_runs <- list(
  fut_before = xt_unspliced(XT_SCEN),
  fut_after  = app_run_coupled(APP_SPIN, XT_SCEN, APP_FUTURE_YEARS),
  sty_before = xt_unspliced(XT_SCEN, xt_sty_em),
  sty_after  = app_run_coupled(APP_SPIN, XT_SCEN, APP_FUTURE_YEARS,
                               nonco2_scenario = XT_SCEN, emissions = xt_sty_em))
xt_ppm <- lapply(xt_runs, xt_read, year = XT_READ_YEAR)

xt("  %-22s (%-22s)  %7.2f ppm", XT_HIST_TAB, "historical (GCB)", xt_hist_ppm)
xt("  %-22s (%-22s)  BEFORE %7.2f  step %+6.2f   AFTER %7.2f  step %+6.2f",
   XT_FUT_TAB, XT_SCEN, xt_ppm$fut_before, xt_ppm$fut_before - xt_hist_ppm,
   xt_ppm$fut_after, xt_ppm$fut_after - xt_hist_ppm)
xt("  %-22s (%-22s)  BEFORE %7.2f  step %+6.2f   AFTER %7.2f  step %+6.2f",
   XT_WHATIF_TAB, "GCB fossil + SSP LUC",
   xt_ppm$sty_before, xt_ppm$sty_before - xt_hist_ppm,
   xt_ppm$sty_after, xt_ppm$sty_after - xt_hist_ppm)

# GATE. The bound is DERIVED from the defect it repairs, not picked: a splice
# that leaves more than a tenth of the step it was built to close has not closed
# it. An absolute ppm gate here would be a number chosen by whoever wrote it.
xt_gate <- local({
  before <- max(abs(c(xt_ppm$fut_before, xt_ppm$sty_before) - xt_hist_ppm))
  after  <- max(abs(c(xt_ppm$fut_after,  xt_ppm$sty_after)  - xt_hist_ppm))
  list(before = before, after = after, ok = after < before / 10)
})
xt("\n  GATE: worst step %.2f ppm before, %.2f after (%.1f%% of it left). %s",
   xt_gate$before, xt_gate$after, 100 * xt_gate$after / xt_gate$before,
   if (xt_gate$ok) "PASS" else "FAIL -- the splice did not close the step")

xt_obs <- local({
  # The two stations the Keeling tab plots; their mean is the closest thing the
  # app draws to a global number. \u26a0 NOT a global mean of the record -- two
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

# ---- 3. WHAT THE SPLICE MOVES AT THE HORIZON -------------------------
xt("\n3. AT %d -- what the splice moves, and what it does not", XT_END_YEAR)
xt_end <- lapply(xt_runs, xt_read, year = XT_END_YEAR)
xt("  %s: BEFORE %.1f ppm   AFTER %.1f ppm   %+.1f ppm", XT_SCEN,
   xt_end$fut_before, xt_end$fut_after, xt_end$fut_after - xt_end$fut_before)
xt("  %s: BEFORE %.1f ppm   AFTER %.1f ppm   %+.1f ppm", XT_WHATIF_TAB,
   xt_end$sty_before, xt_end$sty_after, xt_end$sty_after - xt_end$sty_before)
xt("  \u26a0 EVERY SHIPPED FUTURES NUMBER MOVES BY THIS. A figure or a card")
xt("    quoting a %d concentration from before 09-22 (y) is on the old basis.",
   XT_END_YEAR)

# ---- 3b. THE JOIN ----------------------------------------------------
# The scenarios were written before the handover year and several of them no
# longer start where the record ends. The splice does NOT hide that; it ramps
# to the scenario's next reported node, and the size of what it ramps across is
# the honest thing to print.
xt("\n3b. THE JOIN at %d -- how far each scenario starts from the record", APP_SPLICE_YEAR)
xt("  observed %d: fossil %.2f   LUC %.2f GtC/yr", APP_SPLICE_YEAR,
   APP_EMIS_HIST$fossil_GtC[APP_EMIS_HIST$year == APP_SPLICE_YEAR],
   APP_EMIS_HIST$luc_GtC[APP_EMIS_HIST$year == APP_SPLICE_YEAR])
for (sc in unique(APP_SSP_EMIS$scenario)) {
  ss <- APP_SSP_EMIS[APP_SSP_EMIS$scenario == sc, ]
  nxt <- min(ss$year[ss$year > APP_SPLICE_YEAR])
  xt("  %-8s next reported year %d: fossil %+.2f   LUC %+.2f GtC/yr vs the record",
     sc, nxt,
     ss$fossil_GtC[ss$year == nxt] -
       APP_EMIS_HIST$fossil_GtC[APP_EMIS_HIST$year == APP_SPLICE_YEAR],
     ss$luc_GtC[ss$year == nxt] -
       APP_EMIS_HIST$luc_GtC[APP_EMIS_HIST$year == APP_SPLICE_YEAR])
}

# ---- 4. WARNINGS RAISED BY THE APP'S OWN STARTUP ---------------------
# Read, not suppressed: "There were 50 or more warnings" is exactly the shape a
# real defect hides in.
xt("\n4. WARNINGS FROM app/global.R STARTUP: %d, %d distinct", length(xt_warn),
   length(unique(xt_warn)))
for (w in sort(unique(xt_warn)))
  xt("  x%-4d %s", sum(xt_warn == w), substr(w, 1, 110))

xt("\n=====================================================================")
xt("READING. The step was an EMISSIONS-INVENTORY difference, not a parameter")
xt("difference: the same fitted vector and the same spinup drew both curves.")
xt("Marcus's ruling 09-22: SPLICE + CAPTION. The observed budget is now the")
xt("past on every tab (app_splice_history), and APP_SPLICE_NOTE says so on the")
xt("Futures tab. The join is a ramp to the scenario's next reported node, and")
xt("3b prints how far that node is from the record -- which the splice does")
xt("not hide and cannot fix: several SSPs no longer start where the world is.")
xt("=====================================================================")

close(xt_con)
cat("\nwritten: ", XT_OUT, "\n", sep = "")
