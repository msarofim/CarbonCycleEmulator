# =====================================================================
# Gate: the "Is the model's land sink too high?" panel (handoff 09-24 e item 3).
#
# ⭐⭐ THE LOAD-BEARING TEST IS 1: `app_sinks_annual()` must equal
# `dg_annual_sinks()` EXACTLY. The app and the gate compute the same quantity,
# and until 2026-09-24 (o) they disagreed — the app diffed ANNUAL MEANS of each
# stock (the flux over [mid-year y−1, mid-year y]) where the objective and gate 7
# interpolate the stocks to CALENDAR-YEAR boundaries. That is the second half of
# the defect in [[ccx_gcb_land]]: the `eluc` half was fixed in the app on 09-22,
# the HALF-YEAR ALIGNMENT half was not. It moved the land bar to 3.06 where gate
# 7 reads 3.09, and it moved this panel's decade containment.
# ⛔ It is a SILENT disagreement: both numbers are plausible, the chart looks
# fine, and nothing in the app said which convention it was on. Hence a gate that
# compares the two implementations rather than either against a recorded number.
#
# The others are the ways a panel goes wrong without erroring:
#   2. The decade table's BINNING. A plain decade bin makes a "1950s" row out of
#      the single year 1959, whose containment verdict is noise.
#   3. THE SIGN. GCB's imbalance is POSITIVE, so the band lies ABOVE the
#      published line and a LARGER model sink moves TOWARD closure. If a data
#      update ever flipped that, every sentence on the panel would invert while
#      the chart still drew.
#   4. The "EXTREME attribution" wording, which is what stops the band being read
#      as a confidence interval.
#   5. The wiring: an output rendered but never placed, or the reverse.
#
# ⚠ Test 1 RUNS THE MODEL once. That is the cost of comparing two
# implementations rather than a stored number, and the stored-number version
# could not have caught this (both implementations produce stable numbers).
# =====================================================================

.imb_app   <- file.path(.root, "app")
.imb_ui    <- readLines(file.path(.imb_app, "ui.R"), warn = FALSE)
.imb_srv   <- readLines(file.path(.imb_app, "server.R"), warn = FALSE)
.imb_plots <- file.path(.imb_app, "R", "plots.R")

IMB_UI_OUTPUT <- "w_imbalance_ui"
IMB_RENDERED  <- c("w_imbalance_ui", "w_imbalance_plot", "w_imbalance_takeaway")
IMB_PARITY_TOL <- 0     # the two implementations must be IDENTICAL, not close
IMB_MIN_N      <- 10L   # the leading-bin rule the panel documents

# plots.R needs ggplot2 and app-level constants; load it into a child env with
# the one constant it reads at call time supplied.
.imb_env <- new.env(parent = environment())
.imb_ok <- requireNamespace("ggplot2", quietly = TRUE) &&
  tryCatch({
    assign("APP_LUC_SMOOTH_YR", 11L, envir = .imb_env)
    local({ library(ggplot2); sys.source(.imb_plots, envir = .imb_env) }); TRUE
  }, error = function(e) FALSE)

skip_if_no_plots <- function() skip_if(!.imb_ok, "app/R/plots.R did not load")

test_that("1. the app's land sink IS the gate's, not a second implementation", {
  skip_if_no_cpp(); skip_if_no_plots()
  source(file.path(.root, "calibration", "lib_design_gates.R"), local = TRUE)
  md   <- readRDS(ccx_mode_file())
  pins <- ccx_mode_pins(md)
  rmp  <- ccx_apply_pins(pins); on.exit(ccx_unpin_params(rmp), add = TRUE)
  bp   <- ccx_mode_base(md); bp$pump_mode <- md$pump_mode
  pm   <- ccx_mode_par_with_pins(md)
  if (length(ccx_mode_absent(md))) pm <- ccx_migrate_par_set(pm)
  bp   <- ccx_overlay_par(bp, pm)
  bp   <- ccx_set_enso(bp, pm)
  for (n in names(pins)) bp[[n]] <- pins[[n]]
  spin <- ccx_spinup_from_label(ccx_mode_spinup(md))(bp)
  F <- suppressWarnings(ccx_build_forcing("historical", DG_YEARS, prod_c14 = spin$prod_c14,
                                          luc_scale = pm$luc_scale,
                                          bomb_total_kmol = pm$bomb_total))
  r <- ccx_run_fast(spin, F); r$F <- F

  ann <- .imb_env$app_sinks_annual(r$out, r$F)
  a   <- dg_annual_sinks(r)
  i   <- match(a$year, ann$yr)
  expect_false(anyNA(i))
  expect_equal(max(abs(ann$land_sink[i]  - a$land)),  IMB_PARITY_TOL)
  expect_equal(max(abs(ann$ocean_sink[i] - a$ocean)), IMB_PARITY_TOL)

  # MUTATION: the PRE-FIX construction (differenced annual means) must FAIL this.
  # If it did not, the gate would not have caught the bug it exists for.
  yr  <- floor(r$out$t)
  old <- stats::aggregate(cbind(ocean_C, land_C) ~ yr, data = r$out, FUN = mean)
  old <- old[order(old$yr), ]
  el  <- ccx_forcing_eluc_annual(r$F)
  old$land_sink <- c(NA, diff(old$land_C)) + el$eluc[match(old$yr, el$year)]
  j <- match(a$year, old$yr)
  expect_gt(max(abs(old$land_sink[j] - a$land), na.rm = TRUE), 0.01)

  # and the decade table must reproduce the recorded containment
  gcb <- as.data.frame(readRDS(ccx_path("data", "gcb_budget.rds"))$budget)
  s <- .imb_env$app_imbalance_decades(r$out, gcb, r$F)
  expect_equal(nrow(s), 7L)
  expect_equal(sum(s$in_band), 4L)
  expect_equal(s$miss[nrow(s)], 1.04, tolerance = 0.02)
})

test_that("2. a leading partial decade is dropped and a trailing one is kept", {
  skip_if_no_plots()
  expect_equal(.imb_env$IMB_DECADE_MIN_N, IMB_MIN_N)
  src <- paste(readLines(.imb_plots, warn = FALSE), collapse = "\n")
  # the rule is applied to the FIRST row only; a rule applied to all rows would
  # silently delete the 2020s, which is the row the takeaway names
  expect_true(grepl("s$n[1] < IMB_DECADE_MIN_N", src, fixed = TRUE))
  expect_true(grepl("s[-1L, , drop = FALSE]", src, fixed = TRUE))
})

test_that("3. GCB's imbalance is POSITIVE, so the band lies above the line", {
  gcb <- as.data.frame(readRDS(ccx_path("data", "gcb_budget.rds"))$budget)
  im <- gcb$imbalance[!is.na(gcb$imbalance)]
  expect_gt(mean(im), 0)
  # the panel's whole argument is that a BIGGER sink closes the budget; if the
  # mean ever went negative every sentence on it would invert
  expect_gt(sum(im > 0) / length(im), 0.5)
})

test_that("4. the band is called an EXTREME attribution, in both places", {
  skip_if_no_plots()
  src <- paste(readLines(.imb_plots, warn = FALSE), collapse = " ")
  expect_true(grepl("EXTREME attribution", src, fixed = TRUE))
  # once for the chart caption, once for the caveat box -- two constants
  expect_true(grepl("IMB_BAND_SHORT", src, fixed = TRUE))
  expect_true(grepl("IMB_BAND_NOTE", src, fixed = TRUE))
  expect_true(any(grepl("IMB_BAND_NOTE", .imb_srv, fixed = TRUE)))
})

test_that("5. the section is placed in ui.R and rendered in server.R", {
  expect_true(any(grepl(sprintf('uiOutput("%s")', IMB_UI_OUTPUT), .imb_ui, fixed = TRUE)))
  for (id in IMB_RENDERED)
    expect_true(any(grepl(sprintf("output$%s", id), .imb_srv, fixed = TRUE)))
  body <- paste(.imb_srv, collapse = "\n")
  for (id in setdiff(IMB_RENDERED, IMB_UI_OUTPUT))
    expect_gt(length(gregexpr(id, body, fixed = TRUE)[[1]]), 1)
})
