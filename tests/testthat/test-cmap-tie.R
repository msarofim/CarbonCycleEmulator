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
# ⛔ (2026-10-11 b) UNTIL TODAY THEY DID NOT: the only separation check compared
# the two CONSTANTS with each other, and at hilda29e three rows sat in the gap with
# a green suite. "THE GAP" test below is the one that reads the canonical's rows.
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

# =====================================================================
# ⛔ THE GAP MUST STILL BE A GAP, ON THE CANONICAL'S OWN ROWS (2026-10-11 b).
# The cut rests on a SEPARATION measured over all 12 rows at three arms
# (APP_CMAP_TIE_SRC): rows whose winner flipped had top-two margins at or below
# APP_CMAP_TIE_FLIP_MAX, stable rows at or above APP_CMAP_TIE_STABLE_MIN, and
# NOTHING between. global.R says a row landing in that gap means re-derive the
# cut; nothing checked it, and at hilda29e three rows sit there (found by the
# 2026-10-11 adoption audit).
# ALL 12 ROWS, not only the three the takeaway names (Marcus 2026-10-11: "is
# there a reason not to do all 12?" -- no): the separation was measured over all
# 12, and WHICH rows are the top three moves with every refit.
# ⚠ A row in the gap is not proof that its winner flips -- the gap was defined
# by CROSS-ARM behaviour, and this reads one arm. It means the cut no longer
# classifies that row from measurement, which is the trigger to re-measure.
# =====================================================================
# the top-two margin in pp, computed exactly as app_cmap_holder_phrase() does
.cm_margins <- function(MC) apply(MC, 1, function(r) {
  v <- sort(100 * r / sum(r), decreasing = TRUE); v[[1]] - v[[2]] })
# strictly between: the endpoints ARE the measured rows (the largest flipper, the smallest stable row)
.cm_in_gap <- function(mg, lo = .env$APP_CMAP_TIE_FLIP_MAX, hi = .env$APP_CMAP_TIE_STABLE_MIN)
  mg[mg > lo & mg < hi]

test_that("THE GAP: no row of the canonical's map has a top-two margin inside the measured gap", {
  f <- file.path(.root, "data", "constraint_map.rds")
  skip_if(!file.exists(f), "constraint map not built")
  cm <- readRDS(f)
  # the rows must be the CANONICAL's, or this checks a retired arm (test-constraint-map 7 fails loudly then)
  skip_if(length(ccx_cmap_problems(cm)) > 0L, "the map is not the canonical's (test-constraint-map 7 fails)")
  mg <- .cm_margins(cm$MC)
  expect_length(mg, nrow(cm$MC))                       # every row, not the top three
  g <- .cm_in_gap(mg)
  expect(length(g) == 0L,
         sprintf(paste("%d row(s) of the %s map sit inside the gap (%.3f, %.3f) pp the tie cut rests on: %s.",
                       "Re-measure the separation (%s) and re-derive the cut from its two endpoints."),
                 length(g), cm$provenance$mode, .env$APP_CMAP_TIE_FLIP_MAX, .env$APP_CMAP_TIE_STABLE_MIN,
                 paste(sprintf("%s %.2f", names(g), g), collapse = "; "), .env$APP_CMAP_TIE_SRC))
})

test_that("MUTATION: the gap gate catches a row in the gap, and passes with none", {
  lo <- .env$APP_CMAP_TIE_FLIP_MAX; hi <- .env$APP_CMAP_TIE_STABLE_MIN
  # synthetic: a stable row (30 pp), a flipper (0.4 pp), a row in the gap (2 pp) -> exactly that one
  MC <- rbind(stable = c(a = 60, b = 30, c = 10), flipper = c(a = 50, b = 49.6, c = 0.4),
              in_gap = c(a = 50, b = 48, c = 2))
  expect_identical(names(.cm_in_gap(.cm_margins(MC))), "in_gap")
  # the endpoints are the measured rows themselves: not in the gap
  expect_length(.cm_in_gap(c(x = lo, y = hi)), 0L)
  # and on the REAL product's rows, both directions
  f <- file.path(.root, "data", "constraint_map.rds")
  skip_if(!file.exists(f), "constraint map not built")
  MC <- readRDS(f)$MC
  set_margin <- function(r, m) {             # move share from the runner-up to the top so the margin is m pp
    o <- order(r, decreasing = TRUE); s <- sum(r)
    d <- (m - 100 * (r[o[1]] - r[o[2]]) / s) * s / 200
    r[o[1]] <- r[o[1]] + d; r[o[2]] <- r[o[2]] - d; r }
  # every row pushed OUT of the gap (to hi + 1 pp) -> the gate passes
  out <- MC; for (k in names(.cm_in_gap(.cm_margins(MC)))) out[k, ] <- set_margin(MC[k, ], hi + 1)
  expect_length(.cm_in_gap(.cm_margins(out)), 0L)
  # ...and the most stable row pushed IN (to the gap's middle) -> caught, by name
  k <- names(which.max(.cm_margins(out))); inn <- out; inn[k, ] <- set_margin(out[k, ], (lo + hi) / 2)
  expect_identical(names(.cm_in_gap(.cm_margins(inn))), k)
})
