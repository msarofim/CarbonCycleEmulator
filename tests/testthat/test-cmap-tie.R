# =====================================================================
# Gate: the constraint map's takeaway must report a TIE as a tie.
#
# ⛔ WHY. `cm_takeaway` named one holder per row -- "mostly influenced by X" --
# for the top three rows by total. Measured at three arms, TWO of those three
# are coin flips: the winner of δ¹³C level & gradient (0.13 pp) and of Δ¹⁴C bomb
# (0.85 pp) CHANGES with the arm. The app's own defence was that the sentence is
# COMPUTED "so a refit moves the sentence rather than leaving it asserting the
# old winner" -- but computing it makes it MOVE, not makes it TRUE.
#
# ⭐ THE THRESHOLD IS MEASURED. Flipping rows sat at 0.13 / 0.85 pp and stable
# rows at 3.02 pp and above, with nothing between; the cut is the geometric mean
# of the two endpoints. These tests assert the SEPARATION still holds, not the
# constant -- if a future arm lands a row in the gap, THAT is what should fail.
# ⚠ And they exercise the CALLER, not just the helper: a gate that picks its own
# inputs tests the function it points at, not the feature
# ([[gate_tested_the_helper_not_the_caller]]).
# =====================================================================
.root <- local({
  d <- normalizePath(getwd(), mustWork = FALSE)
  for (i in 1:8) { if (file.exists(file.path(d, "DESIGN.md"))) break; d <- dirname(d) }
  d
})
.app <- file.path(.root, "app")
.srv <- ccx_code_lines(readLines(file.path(.app, "server.R"), warn = FALSE))

.env <- new.env(parent = globalenv())
.want <- c("app_cmap_holder_phrase", "APP_CMAP_TIE_PP",
           "APP_CMAP_TIE_FLIP_MAX", "APP_CMAP_TIE_STABLE_MIN", "APP_CMAP_TIE_SRC")
for (e in parse(file.path(.app, "global.R")))
  if (is.call(e) && length(e) >= 3L && identical(as.character(e[[1]]), "<-") &&
      is.name(e[[2]]) && as.character(e[[2]]) %in% .want) eval(e, .env)

test_that("the threshold sits INSIDE the measured gap, and is derived from it", {
  for (w in .want) expect_false(is.null(get0(w, envir = .env)), info = w)
  # the cut must separate what was measured to flip from what was measured stable
  expect_gt(.env$APP_CMAP_TIE_PP, .env$APP_CMAP_TIE_FLIP_MAX)
  expect_lt(.env$APP_CMAP_TIE_PP, .env$APP_CMAP_TIE_STABLE_MIN)
  # and it must BE the derivation, not a number that merely happens to fit
  expect_equal(.env$APP_CMAP_TIE_PP,
               sqrt(.env$APP_CMAP_TIE_FLIP_MAX * .env$APP_CMAP_TIE_STABLE_MIN))
  # the gap must still be a gap -- if the endpoints ever cross, the whole
  # tie/no-tie distinction has stopped being measurable and must not be faked
  expect_lt(.env$APP_CMAP_TIE_FLIP_MAX, .env$APP_CMAP_TIE_STABLE_MIN)
})

test_that("the phrase reports a tie as a tie and a winner as a winner", {
  f <- .env$app_cmap_holder_phrase
  tie   <- c(A = 21.6, B = 21.5, C = 10)      # 0.1 pp apart
  clear <- c(A = 25.4, B = 22.3, C = 10)      # 3.1 pp apart
  expect_match(f(tie),   "about equally", fixed = TRUE)
  expect_match(f(tie),   "A", fixed = TRUE); expect_match(f(tie), "B", fixed = TRUE)
  expect_match(f(clear), "mostly influenced by A", fixed = TRUE)
  expect_false(grepl("about equally", f(clear), fixed = TRUE))
  # ⭐ the RUNNER-UP's share must APPEAR in the tie case -- that is the whole
  # point of the change. ⚠ Computed from the input, not typed: the phrase
  # reports shares OF THE ROW, so c(21.6, 21.5, 10) prints 41%/40%, not 22%/21%.
  # A hardcoded expectation here would have been testing my own arithmetic.
  want <- sprintf("%.0f%%", 100 * sort(tie, decreasing = TRUE)[1:2] / sum(tie))
  for (w in want) expect_match(f(tie), w, fixed = TRUE)
})

test_that("the SERVER calls the phrase helper, not which.max", {
  # the call site: without this, a revert to the argmax passes everything above
  call <- grep("app_cmap_holder_phrase", .srv, value = TRUE)
  expect_gt(length(call), 0L)
  tk <- grep("cm_takeaway", .srv)
  expect_gt(length(tk), 0L)
  # the old formulation must not come back
  expect_false(any(grepl("mostly influenced by %s", .srv, fixed = TRUE)),
               info = "server re-typed the phrase instead of calling the helper")
})

test_that("ON THE REAL PRODUCT, the two known near-ties read as ties", {
  f <- file.path(.root, "data", "constraint_map.rds")
  skip_if(!file.exists(f), "constraint map not built")
  cm <- readRDS(f)
  environment(.env$app_cmap_holder_phrase) <- .env
  tot <- sort(rowSums(cm$MC), decreasing = TRUE)
  top <- names(tot)[1:3]
  ph  <- vapply(top, function(r) .env$app_cmap_holder_phrase(cm$MC[r, ]), character(1))
  # exactly the rows the 3-arm comparison found to flip, by MARGIN not by name,
  # so a relabelled component does not silently move the expectation
  mgn <- vapply(top, function(r) { v <- sort(cm$MC[r, ] / sum(cm$MC[r, ]) * 100,
                                             decreasing = TRUE); v[[1]] - v[[2]] }, numeric(1))
  for (i in seq_along(top)) {
    if (mgn[[i]] <= .env$APP_CMAP_TIE_PP)
      expect_match(ph[[i]], "about equally", fixed = TRUE, info = top[[i]])
    else
      expect_match(ph[[i]], "mostly influenced", fixed = TRUE, info = top[[i]])
  }
  # and, as measured: exactly TWO of the top three were ties at hilda29l (09-26); ONE at the canonical
  # hilda33d (2026-10-01 c: the map rebuilt at the D2/D3 canonical; re-pin approved by Marcus)
  expect_equal(sum(mgn <= .env$APP_CMAP_TIE_PP), 1L)
})
