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

test_that("the control is WITHHELD from Build your own", {
  # FaIR was never run on a user-built pathway; the checkbox must sit inside a
  # conditionalPanel excluding that mode.
  expect_true(any(grepl("input.f_mode != 'Build your own'", .ui, fixed = TRUE)))
})

test_that("the caveat names the splice, which is why the two differ pre-2024", {
  expect_match(.env$APP_FAIR_NOTE, "splice")
  expect_match(.env$APP_FAIR_NOTE, "FaIR")
})

test_that("the overlay returns REAL ROWS for the SSPs, not a flattering NULL", {
  skip_if(is.null(.env$APP_FAIR <- tryCatch(
    as.data.frame(readRDS(file.path(.root, "data", "forcing_climate_ssp.rds"))),
    error = function(e) NULL)), "forcing_climate_ssp.rds not built")
  environment(.env$app_fair_overlay) <- .env
  for (v in c("gmst", "co2_ppm")) {
    ov <- .env$app_fair_overlay(c("ssp126", "ssp245", "ssp585"), v)
    expect_false(is.null(ov), info = paste("overlay NULL for", v))
    expect_gt(nrow(ov), 100L)
    expect_setequal(unique(ov$who), c("ssp126", "ssp245", "ssp585"))
    expect_true(all(is.finite(ov$y)))
  }
  # ⭐ the ORDERING is the substantive check: FaIR's own scenarios must rank
  # ssp126 < ssp245 < ssp585 at 2100. A wrong column could still return rows.
  ov <- .env$app_fair_overlay(c("ssp126", "ssp245", "ssp585"), "gmst")
  at2100 <- vapply(c("ssp126", "ssp245", "ssp585"),
                   function(s) ov$y[ov$who == s & ov$year == 2100], numeric(1))
  expect_true(all(diff(at2100) > 0), info = paste(round(at2100, 2), collapse = " "))
})

test_that("a pathway FaIR never ran contributes NOTHING", {
  skip_if(is.null(.env$APP_FAIR), "forcing_climate_ssp.rds not built")
  environment(.env$app_fair_overlay) <- .env
  expect_null(.env$app_fair_overlay("Your scenario", "gmst"))
  expect_null(.env$app_fair_overlay(character(0), "gmst"))
  # a column name that does not exist must return NULL, not silently draw nothing
  expect_null(.env$app_fair_overlay("ssp245", "not_a_column"))
})
