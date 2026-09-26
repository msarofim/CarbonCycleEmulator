# =====================================================================
# ONE quote-aware comment stripper, shared by every text gate.
#
# ⛔⛔ WHY THIS FILE EXISTS. A raw-line text gate reports EVERY REPAIR AS A
# RELAPSE, because a file's own description of a defect contains the defect's
# text ([[text_gate_matches_its_own_comment]], 09-25 i -- it happened twice in
# one session, on the ui.R year lint and the server.R "about 0.3 GtC" gate).
# The fix is to match CODE ONLY. The tempting alternative -- narrowing the
# pattern until it goes quiet -- narrows it past the case it exists to catch.
#
# ⚠ It must be QUOTE-AWARE: a `#` inside a string is content, not a comment,
# and ui.R carries hex colours. A naive `sub("#.*", "", ln)` deletes them.
#
# ⚠ AND IT MUST LIVE IN ONE PLACE. By 2026-09-25 there were two byte-alike
# copies (test-ui-year-bounds-lint.R, test-imbalance-panel.R) and a third was
# about to be written for test-constraint-map-panel.R. Three copies of one rule
# is three chances for one of them to be fixed alone.
#
# Known limitation, stated rather than discovered: it does not track escaped
# quotes (`\"`) or single-quoted strings. Neither appears in the app's R files,
# and test 0 below fails if that stops being true.
# =====================================================================

#' Strip R comments from source lines, leaving the code
#' @param ln character vector of source lines
#' @return the same length, comments removed (a comment-only line becomes "")
ccx_code_lines <- function(ln) {
  out <- character(length(ln))
  for (i in seq_along(ln)) {
    chars <- strsplit(ln[i], "", fixed = TRUE)[[1]]
    q <- 0L; cut <- length(chars) + 1L
    for (j in seq_along(chars)) {
      if (chars[j] == '"') q <- q + 1L
      else if (chars[j] == "#" && q %% 2L == 0L) { cut <- j; break }
    }
    out[i] <- if (cut == 1L) "" else paste(chars[seq_len(cut - 1L)], collapse = "")
  }
  out
}

test_that("0. the shared comment stripper keeps code and drops comments", {
  expect_identical(ccx_code_lines("x <- 1  # a comment"), "x <- 1  ")
  expect_identical(ccx_code_lines("# whole line"), "")
  # ⚠ THE CASE THAT BREAKS A NAIVE sub("#.*", "") -- a hex colour in ui.R
  expect_identical(ccx_code_lines('col <- "#C4315F"'), 'col <- "#C4315F"')
  expect_identical(ccx_code_lines('col <- "#C4315F"  # the fg'), 'col <- "#C4315F"  ')
  # a `#` inside a string that is itself followed by a real comment
  expect_identical(ccx_code_lines('p("a # b") # c'), 'p("a # b") ')
  expect_identical(ccx_code_lines(c("a", "# b")), c("a", ""))

  # THE LIMITATION, ASSERTED rather than trusted: no escaped or single-quoted
  # strings in the files this helper is pointed at, or the quote count is wrong.
  #
  # ⛔⛔ THE ROOT IS RESOLVED HERE, NOT BORROWED FROM A TEST FILE (fixed
  # 2026-09-26). This block used to read `.root`, which every TEST FILE defines
  # but no HELPER does -- and testthat sources helpers BEFORE test files. So
  # this `test_that` raised "object '.root' not found" during
  # `source_test_helpers()`, which testthat turns into a FAILURE INSIDE
  # source_dir() and then ABORTS THE WHOLE RUN. ⚠ The suite did not report a
  # failing test; it reported nothing at all, for every test in the repo,
  # because it never reached one. `Rscript tests/run_tests.R` had been dead
  # since a6ddf96 (the commit that added this helper) -- the pre-helper baseline
  # was pass 4773 / fail 1 / error 0. ⇒ [[broken_gate_reports_nothing]], and its
  # sharper form: a BROKEN HARNESS is indistinguishable from a broken test in
  # the output, and costs the whole suite rather than one gate.
  # ⭐ A helper must be self-contained: it cannot depend on a name that only
  # exists once test files start running.
  .helper_root <- local({
    d <- normalizePath(getwd(), mustWork = FALSE)
    for (i in 1:8) { if (file.exists(file.path(d, "DESIGN.md"))) break; d <- dirname(d) }
    d
  })
  expect_true(file.exists(file.path(.helper_root, "DESIGN.md")),
              info = "the helper could not locate the repo root from getwd()")
  for (f in c("ui.R", "server.R", "global.R")) {
    src <- readLines(file.path(.helper_root, "app", f), warn = FALSE)
    expect_false(any(grepl('\\\\"', src)),
                 info = paste(f, "carries an escaped quote; ccx_code_lines() cannot parse it"))
  }
})
