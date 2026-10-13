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
  # the structure's ENSO index and AOD mode, as dg_run() builds it since 2026-10-01 (c): the canonical
  # hilda33d runs aod "anomaly" (re-pin approved by Marcus)
  F <- suppressWarnings(ccx_build_forcing("historical", DG_YEARS, prod_c14 = spin$prod_c14,
                                          luc_scale = pm$luc_scale,
                                          bomb_total_kmol = pm$bomb_total,
                                          enso_index = ccx_enso_index_of(bp), aod_mode = ccx_aod_mode_of(bp), nuc_share = ccx_nuc_share_of(bp)))
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
  # 2026-10-01 (c): at the canonical hilda33d (D2/D3 fitted): 5 decades in the band, the last decade's miss
  # 0.87 (4 and 1.04 at hilda29l). MEASURED; re-pin approved by Marcus.
  # 2026-10-03 (h): at the canonical hilda34g, still 5 decades in the band; the last decade's miss 0.87 ->
  # 0.92 (0.9235). MEASURED (Marcus 2026-10-03: "Approve all (Recommended)").
  # 2026-10-08 (e): at the canonical hilda29e (#18 pass 2, the interannual cut), still 5 decades in the band; the last
  # decade's miss 0.92 -> 1.00 (1.0029). MEASURED (Marcus 2026-10-08: "Approve all five").
  # 2026-10-13 (g): at the canonical hilda31w (the WTC label), still 5 decades in the band; the last decade's miss
  # 1.00 -> 1.05 (1.0487). MEASURED (Marcus 2026-10-13: "Approve all (Recommended)").
  expect_equal(sum(s$in_band), 5L)
  expect_equal(s$miss[nrow(s)], 1.05, tolerance = 0.02)

  # ---- the +0.32 decomposition, recomputed (added 2026-09-25) --------------
  # \u26d4 The info box used to TYPE "about 0.3 GtC" and name THREE terms. There
  # are FIVE, and the panel's own roxygen also claimed the decomposition closes
  # "to 3e-14" -- which is the GCB BUDGET IDENTITY's closure, a different
  # equation. This reproduces CHANGELOG 09-24 (i)'s 1959-2024 row instead.
  z <- .imb_env$app_imbalance_identity(r$out, gcb, r$F)
  expect_equal(z$window, c(1959L, 2024L))
  # 2026-10-01 (c): the canonical is hilda33d. d_land +0.32 -> +0.462, d_luc -0.30 -> -0.214, -d_ocn -0.05 ->
  # +0.002: D3 puts 59 % of the imbalance on the land (its sink sits higher against GCB's raw column) and the
  # ocean sink now matches GCB's to 0.002 GtC/yr. imbal / cement are GCB's own (unchanged). MEASURED; re-pin
  # approved by Marcus.
  # 2026-10-03 (h): the canonical is hilda34g. d_land +0.462 -> +0.443 (0.4429), d_luc -0.214 -> -0.208
  # (-0.2079), -d_grow +0.05 -> +0.058 (0.0583), -d_ocn +0.002 -> -0.029 (-0.0290: the ocean sink now sits
  # 0.03 GtC/yr ABOVE GCB's raw column). imbal 0.540 / cement 0.088 unchanged within tolerance. MEASURED
  # (Marcus 2026-10-03: "Approve all (Recommended)").
  # 2026-10-06 (a): the canonical is hilda33p (objective #16; the refit's stronger fertilisation and larger LUC
  # scale). d_land +0.443 -> +0.482 (0.4824), d_luc -0.208 -> -0.169 (-0.1690); imbal 0.540, cement 0.088,
  # -d_grow +0.059, -d_ocn -0.029 and the decade table (5 in band, last miss 0.930) unchanged within tolerance.
  # MEASURED (Marcus 2026-10-06: "Approve all (Recommended)").
  # 2026-10-08 (e): the canonical is hilda29e. d_land +0.482 -> +0.507 (0.5074), d_luc -0.169 -> -0.146 (-0.1458); the
  # other four unchanged within tolerance. MEASURED (Marcus 2026-10-08: "Approve all five").
  # 2026-10-13 (g): the canonical is hilda31w. d_land +0.507 -> +0.564 (0.5642), d_luc -0.146 -> -0.099 (-0.0988), -d_ocn
  # -0.029 -> -0.017 (-0.0165); imbal, cement and -d_grow unchanged within tolerance. MEASURED (Marcus 2026-10-13: "Approve
  # all (Recommended)").
  expect_equal(z$d_land, +0.564, tolerance = 0.005)
  expect_equal(z$imbal,  +0.54, tolerance = 0.005)
  expect_equal(z$cement, +0.09, tolerance = 0.005)
  expect_equal(z$d_luc,  -0.099, tolerance = 0.005)
  expect_equal(-z$d_grow, +0.058, tolerance = 0.005)
  expect_equal(-z$d_ocn,  -0.017, tolerance = 0.005)
  # \u26a0 THE CLOSURE IS ASSERTED AT ITS MEASURED SIZE, NOT AT ZERO. It is
  # -0.006 GtC/yr (the table's `num` column), ~2 % of the d_land it explains.
  # Asserting 3e-14 here would fail; asserting nothing would let the identity
  # silently stop closing. The bound is the measured value with room, and the
  # mutation below is a term DROPPED, which moves it by 0.05-0.54.
  expect_lt(abs(z$closure), 0.02)
  # MUTATION: drop the growth term -- the 3-term story the prose used to tell --
  # and the closure must leave that bound. If it did not, naming five terms
  # would be decoration.
  expect_gt(abs(z$closure + z$d_grow), 0.02)
  # ...and the same for the ocean term, which is the other one that was missing.
  # ⚠ 2026-10-01 (c): read at hilda29l BY NAME. At the canonical hilda33d the ocean term is ~0 (-0.002), so
  # dropping it cannot move the closure and the check would have no power there; at hilda29l the term is
  # material (0.05) and the mutation still tests the IDENTITY's code (approved by Marcus).
  v29 <- dg_vector("hilda29l"); r29 <- dg_run(v29)
  z29 <- .imb_env$app_imbalance_identity(r29$out, gcb, r29$F)
  expect_gt(abs(z29$d_ocn), 0.02)                    # the term is material at this file: the check has power
  expect_lt(abs(z29$closure), 0.02)
  expect_gt(abs(z29$closure + z29$d_ocn), 0.02)
})

test_that("6. the info box COMPUTES its numbers instead of typing them", {
  # \u26d4 [[gate_only_guards_what_it_lists]] in the small: this is the assertion
  # that keeps the fix from being undone by someone editing the prose. The box
  # sits three lines under a takeaway that computes, on a panel whose header
  # insists the containment is computed and not described.
  # \u26d4 STRIP COMMENTS FIRST, AND THE FIRST DRAFT DID NOT (2026-09-25). This
  # assertion forbids the literal "about 0.3 GtC" in server.R -- and matched the
  # COMMENT IN server.R THAT DOCUMENTS THE RETIRED LITERAL. Second time in one
  # session: the ui.R year lint hit the identical trap. A text gate must read
  # CODE; a file's own description of the defect contains the defect's text, so
  # a gate that reads raw lines reports every repair as a relapse.
  # \u26a0 Quote-aware, because a `#` inside a string is content.
  # \u26d4 SHARED since 2026-09-25: helper-code-lines.R. This was one of two
  # byte-alike copies when a third gate came to need it.
  code <- ccx_code_lines(.imb_srv)
  blk <- paste(code, collapse = "\n")
  expect_true(grepl("imbalance_id\\(\\)", blk))
  # the retired literal must not come back
  expect_false(grepl("about 0\\.3 GtC", blk))
  # and no bare "N.N GtC" literal anywhere in the imbalance info box
  box <- grep("Taking the whole gap apart", code)
  expect_length(box, 1L)
  expect_false(any(grepl("[0-9]\\.[0-9]+ GtC", code[box:(box + 12L)])))
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
