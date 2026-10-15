# =====================================================================
# Gate: the futures tab's "Compare with standard FaIR" overlay (Marcus 09-26).
#
# The failure modes this guards, all of which are SILENT:
#   1. ⛔ THE OVERLAY RETURNS NULL AND NO LINE IS DRAWN -- which on screen looks
#      exactly like "FaIR agrees perfectly". The column names differ between the
#      objects (`APP_FAIR$gmst_C` vs a run's `gmst`), so one wrong lookup buys
#      the most flattering possible bug.
#   2. A line drawn for a scenario FaIR was never run on (a user-built pathway),
#      which would be a different experiment wearing the same panel.
#   3. The control offered in "Build your own", where 2 is unavoidable.
#   4. The caveat disappearing: before 2024 the emulator splices the observed
#      budget and FaIR does not, so a historical gap is inputs, not skill.
# =====================================================================
.root <- local({
  d <- normalizePath(getwd(), mustWork = FALSE)
  for (i in 1:8) { if (file.exists(file.path(d, "DESIGN.md"))) break; d <- dirname(d) }
  d
})
.app <- file.path(.root, "app")
.ui  <- ccx_code_lines(readLines(file.path(.app, "ui.R"), warn = FALSE))
.srv <- ccx_code_lines(readLines(file.path(.app, "server.R"), warn = FALSE))

.env <- new.env(parent = globalenv())
for (e in parse(file.path(.app, "global.R")))
  if (is.call(e) && length(e) >= 3L && identical(as.character(e[[1]]), "<-") &&
      is.name(e[[2]]) && as.character(e[[2]]) %in%
        c("app_fair_overlay", "APP_FAIR_NOTE", "APP_FAIR_LAB")) eval(e, .env)

test_that("the overlay helper and its caption exist and are wired", {
  expect_true(is.function(.env$app_fair_overlay))
  expect_true(is.character(.env$APP_FAIR_NOTE) && nzchar(.env$APP_FAIR_NOTE))
  # rendered AND placed -- the two halves that go wrong independently
  expect_true(any(grepl('output\\$f_fair_note', .srv)))
  expect_true(any(grepl('uiOutput\\("f_fair_note"\\)', .ui)))
  expect_true(any(grepl('checkboxInput\\("f_fair"', .ui)))
  expect_true(any(grepl('fair = if \\(isTRUE\\(input\\$f_fair\\)\\)', .srv)))
})

test_that("the SERVER passes IDS, not the run names", {
  # ⛔ THE CALL SITE ITSELF. The test above proves the helper works on the right
  # argument; this proves the server hands it that argument. Without this, a
  # revert to `app_fair_overlay(names(rs), ...)` -- the original bug, which drew
  # NO line and looked like perfect agreement -- passes every other check here.
  call <- grep("app_fair_overlay\\(", .srv, value = TRUE)
  expect_gt(length(call), 0L)
  joined <- paste(call, collapse = " ")
  expect_match(joined, "APP_SCENARIOS", info = "the server must key the overlay on ids")
  expect_false(grepl("app_fair_overlay(names(", joined, fixed = TRUE),
               info = "server passes run NAMES (display labels) -- draws no line")
})

test_that("the control is WITHHELD from Build your own", {
  # FaIR was never run on a user-built pathway; the checkbox must sit inside a
  # conditionalPanel excluding that mode.
  expect_true(any(grepl("input.f_mode != 'Build your own'", .ui, fixed = TRUE)))
})

test_that("the caveat names the splice, which is why the two differ pre-2024", {
  expect_match(.env$APP_FAIR_NOTE, "splice")
  expect_match(.env$APP_FAIR_NOTE, "FaIR")
})

# ⛔⛔ THE CALLER'S CONTRACT, NOT THE HELPER'S. This file's first version tested
# `app_fair_overlay(c("ssp126", ...))` -- ids -- and passed, while the app was
# passing `names(runs)`, the DISPLAY labels, matching nothing and drawing no
# line. The gate was written FOR the flattering-NULL failure and still missed
# it, because it chose its own inputs instead of the ones the app supplies.
# ⭐ A GATE MUST BE FED WHAT THE CALLER FEEDS. These tests now go through
# APP_SCENARIOS, the same object the server slices. (Renamed from APP_SSPS and
# moved to the van Vuuren ids 2026-09-29, when the menu did; assertions unchanged.)
test_that("the overlay works on WHAT THE SERVER ACTUALLY PASSES", {
  skip_if(is.null(.env$APP_FAIR <- tryCatch(
    as.data.frame(readRDS(file.path(.root, "data", "forcing_climate_vv.rds"))),
    error = function(e) NULL)), "forcing_climate_vv.rds not built")
  # APP_SCENARIOS, read out of global.R rather than retyped here
  for (e in parse(file.path(.app, "global.R")))
    if (is.call(e) && length(e) >= 3L && identical(as.character(e[[1]]), "<-") &&
        is.name(e[[2]]) && identical(as.character(e[[2]]), "APP_SCENARIOS")) eval(e, .env)
  expect_true(is.character(.env$APP_SCENARIOS) && !is.null(names(.env$APP_SCENARIOS)))
  environment(.env$app_fair_overlay) <- .env
  sel <- c("vvL", "vvM", "vvH")
  slice <- .env$APP_SCENARIOS[.env$APP_SCENARIOS %in% sel]        # exactly the server's expression
  ov <- .env$app_fair_overlay(slice, "gmst")
  expect_false(is.null(ov), info = "overlay NULL on the server's own argument")
  expect_gt(nrow(ov), 100L)
  # ⭐ THE WHO COLUMN MUST BE THE RUN NAMES, or ggplot gives the dashed line its
  # own color and the pairing the chart depends on is lost.
  expect_setequal(unique(ov$who), names(slice))
  # and the run names really are the display labels, which is the thing that
  # differed from the ids
  expect_false(any(unique(ov$who) %in% sel),
               info = "who looks like an id; the server names runs by LABEL")
})

test_that("the overlay returns REAL ROWS for the menu scenarios, not a flattering NULL", {
  skip_if(is.null(.env$APP_FAIR <- tryCatch(
    as.data.frame(readRDS(file.path(.root, "data", "forcing_climate_vv.rds"))),
    error = function(e) NULL)), "forcing_climate_vv.rds not built")
  environment(.env$app_fair_overlay) <- .env
  for (v in c("gmst", "co2_ppm")) {
    ov <- .env$app_fair_overlay(c("vvL", "vvM", "vvH"), v)  # unnamed: ids as labels
    expect_false(is.null(ov), info = paste("overlay NULL for", v))
    expect_gt(nrow(ov), 100L)
    expect_setequal(unique(ov$who), c("vvL", "vvM", "vvH"))
    expect_true(all(is.finite(ov$y)))
  }
  # ⭐ the ORDERING is the substantive check: FaIR's own scenarios must rank
  # vvL < vvM < vvH at 2100. A wrong column could still return rows.
  ov <- .env$app_fair_overlay(c("vvL", "vvM", "vvH"), "gmst")
  at2100 <- vapply(c("vvL", "vvM", "vvH"),
                   function(s) ov$y[ov$who == s & ov$year == 2100], numeric(1))
  expect_true(all(diff(at2100) > 0), info = paste(round(at2100, 2), collapse = " "))
})

test_that("a pathway FaIR never ran contributes NOTHING", {
  skip_if(is.null(.env$APP_FAIR), "forcing_climate_vv.rds not built")
  environment(.env$app_fair_overlay) <- .env
  expect_null(.env$app_fair_overlay("Your scenario", "gmst"))
  expect_null(.env$app_fair_overlay(character(0), "gmst"))
  # a column name that does not exist must return NULL, not silently draw nothing
  expect_null(.env$app_fair_overlay("vvM", "not_a_column"))
})
