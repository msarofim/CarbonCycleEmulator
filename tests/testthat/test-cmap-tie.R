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
# ⭐ THE THRESHOLD IS MEASURED. On 09-26 (hilda29l) flipping rows sat at 0.13 / 0.85 pp and stable
# rows at 3.02 pp and above, and the cut was the geometric mean of the two endpoints. The 10-11 (b)
# gap gate found three hilda29e rows inside that gap. Re-measured 10-12 against the like-for-like
# basin hilda29a6, NO row flips, so that rule lost its lower endpoint.
# ⭐ RE-EXPRESSED 2026-10-12 (Marcus, verbatim: "Scale to basin spread (Recommended)"): the cut is the
# largest change any row's margin shows between the canonical and its like-for-like basin
# ([[tolerance_scaled_to_spread]]). These tests RECOMPUTE that spread from the two maps, so a
# rebuild of either map that moves it fails here until the cut is re-carried.
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
           "APP_CMAP_TIE_ARM", "APP_CMAP_TIE_SHIFT_MAX", "APP_CMAP_TIE_SRC")
for (e in parse(file.path(.app, "global.R")))
  if (is.call(e) && length(e) >= 3L && identical(as.character(e[[1]]), "<-") &&
      is.name(e[[2]]) && as.character(e[[2]]) %in% .want) eval(e, .env)

test_that("the threshold IS the carried basin spread, and names its arm", {
  for (w in .want) expect_false(is.null(get0(w, envir = .env)), info = w)
  # it must BE the derivation, not a number that merely happens to fit
  expect_identical(.env$APP_CMAP_TIE_PP, .env$APP_CMAP_TIE_SHIFT_MAX)
  expect_gt(.env$APP_CMAP_TIE_PP, 0)
  # the source string names the arm the spread was measured against
  expect_match(.env$APP_CMAP_TIE_SRC, .env$APP_CMAP_TIE_ARM, fixed = TRUE)
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
  # hilda33d (2026-10-01 c: the map rebuilt at the D2/D3 canonical; re-pin approved by Marcus); still ONE at
  # hilda29e under the 10-12 basin-spread cut (δ¹³C level & gradient, 0.94 pp)
  expect_equal(sum(mgn <= .env$APP_CMAP_TIE_PP), 1L)
})

# =====================================================================
# ⛔ THE SPREAD, RECOMPUTED FROM THE TWO MAPS (2026-10-12; replaces 10-11 (b)'s "THE GAP").
# The cut is only a measurement while it equals what the two maps say. So these tests read the
# canonical's map and its like-for-like basin's map, and require three things:
#   (1) the basin IS like-for-like with the CURRENT canonical (same structure, same names, same rows);
#   (2) the largest |change| in any row's margin equals APP_CMAP_TIE_SHIFT_MAX (to its 3 decimals);
#   (3) no row whose margin EXCEEDS the cut changes winner at the basin. That is the premise that makes
#       the cut mean "resolved by the fit".
# ALL 12 ROWS (Marcus 2026-10-11: "is there a reason not to do all 12?" -- no).
# ⚠ A refit moves the canonical's map. Then (1) or (2) fails, and that failure is the trigger to
# re-measure, not to re-pin.
# =====================================================================
# a row's margin of the REFERENCE winner `w` over the best other component, in pp of the row
# (signed: negative when `w` has lost the row). Same shares as app_cmap_holder_phrase().
.cm_signed <- function(r, w) { s <- 100 * r / sum(r); s[[w]] - max(s[names(s) != w]) }
.cm_winner <- function(r) names(which.max(r))
.cm_shift <- function(MC0, MC1) {
  w0 <- apply(MC0, 1, .cm_winner)
  vapply(rownames(MC0), function(f) .cm_signed(MC1[f, ], w0[[f]]) - .cm_signed(MC0[f, ], w0[[f]]), numeric(1))
}
# the premise: rows above the cut that change winner (none, if the cut means anything)
.cm_flips_above <- function(MC0, MC1, cut) {
  m0 <- apply(MC0, 1, function(r) .cm_signed(r, .cm_winner(r)))
  fl <- apply(MC0, 1, .cm_winner) != apply(MC1[rownames(MC0), , drop = FALSE], 1, .cm_winner)
  rownames(MC0)[fl & m0 > cut]
}
.cm_arm_file <- function() file.path(.root, "outputs", "diagnostics",
                                     sprintf("constraint_map_%s.rds", .env$APP_CMAP_TIE_ARM))

test_that("THE SPREAD: the cut equals the largest margin change between the canonical and its basin", {
  f <- file.path(.root, "data", "constraint_map.rds")
  skip_if(!file.exists(f), "constraint map not built")
  cm <- readRDS(f)
  skip_if(length(ccx_cmap_problems(cm)) > 0L, "the map is not the canonical's (test-constraint-map 7 fails)")
  fa <- .cm_arm_file()
  # the measurement must be present wherever the canonical's map is: a missing arm map is a FAIL, not a skip
  expect_true(file.exists(fa), info = fa)
  if (!file.exists(fa)) return(invisible())
  am <- readRDS(fa)
  # (1) like-for-like with the CURRENT canonical
  expect_identical(am$provenance$mode, .env$APP_CMAP_TIE_ARM)
  expect_identical(am$provenance$struct, cm$provenance$struct)
  expect_setequal(colnames(am$M), colnames(cm$M))
  expect_setequal(rownames(am$MC), rownames(cm$MC))
  # (2) the carried number is the measurement
  sh <- .cm_shift(cm$MC, am$MC[rownames(cm$MC), , drop = FALSE])
  expect_length(sh, nrow(cm$MC))                       # every row, not the top three
  expect(abs(max(abs(sh)) - .env$APP_CMAP_TIE_SHIFT_MAX) < 5e-4,
         sprintf("the basin spread is %.4f pp (row %s) but APP_CMAP_TIE_SHIFT_MAX carries %.3f (%s). Re-measure (%s) and carry it.",
                 max(abs(sh)), names(which.max(abs(sh))), .env$APP_CMAP_TIE_SHIFT_MAX,
                 cm$provenance$mode, .env$APP_CMAP_TIE_SRC))
  # (3) the premise
  fa_rows <- .cm_flips_above(cm$MC, am$MC, .env$APP_CMAP_TIE_PP)
  expect(length(fa_rows) == 0L,
         sprintf("row(s) above the %.3f pp cut change winner at %s: %s. The cut no longer means 'resolved by the fit'.",
                 .env$APP_CMAP_TIE_PP, .env$APP_CMAP_TIE_ARM, paste(fa_rows, collapse = "; ")))
})

test_that("MUTATION: the spread gate catches a moved margin and a flip above the cut, and passes the real maps", {
  f <- file.path(.root, "data", "constraint_map.rds"); fa <- .cm_arm_file()
  skip_if(!file.exists(f) || !file.exists(fa), "maps not built")
  MC0 <- readRDS(f)$MC; MC1 <- readRDS(fa)$MC[rownames(MC0), , drop = FALSE]
  cut <- .env$APP_CMAP_TIE_PP
  # the real pair: the spread reproduces the carried number, and no row above the cut flips
  expect_lt(abs(max(abs(.cm_shift(MC0, MC1))) - .env$APP_CMAP_TIE_SHIFT_MAX), 5e-4)
  expect_length(.cm_flips_above(MC0, MC1, cut), 0L)
  # synthetic: a 3 pp move of one row's margin is seen as a spread of 3 pp, by name
  A <- rbind(r1 = c(a = 60, b = 30, c = 10), r2 = c(a = 50, b = 45, c = 5))
  B <- A; B["r2", ] <- c(a = 51.5, b = 43.5, c = 5)   # r2's margin 5 -> 8 pp
  sh <- .cm_shift(A, B)
  expect_equal(unname(sh[["r2"]]), 3); expect_equal(unname(sh[["r1"]]), 0)
  # a sign flip is SIGNED: r2 lost by 1 pp is a shift of -6, not -4 (the unsigned margins 5 and 1)
  B2 <- A; B2["r2", ] <- c(a = 47, b = 48, c = 5)
  expect_equal(unname(.cm_shift(A, B2)[["r2"]]), -6)
  # a flip ABOVE the cut is caught by name; the same flip below the cut is not
  expect_identical(.cm_flips_above(A, B2, cut = 2), "r2")
  expect_length(.cm_flips_above(A, B2, cut = 6), 0L)
  # on the REAL maps: doctor the basin so its most stable row flips -> caught, by name
  k <- names(which.max(apply(MC0, 1, function(r) .cm_signed(r, .cm_winner(r)))))
  bad <- MC1; o <- order(bad[k, ], decreasing = TRUE); bad[k, rev(o[1:2])] <- bad[k, o[1:2]]
  expect_identical(.cm_flips_above(MC0, bad, cut), k)
  expect_gt(max(abs(.cm_shift(MC0, bad))), .env$APP_CMAP_TIE_SHIFT_MAX + 1)
})
