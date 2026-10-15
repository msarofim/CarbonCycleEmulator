# =====================================================================
# Gate: `diag_joos_irf.R` has NO default arm, and `canonical` is an arm name.
#
# ⛔ WHY. Until 2026-09-27 a bare run silently meant "defaults" -- the
# UNCALIBRATED table, pulse AF@100 0.445 against the shipped model's 0.307 --
# while JOOS_SRC named the truth 180 lines above the verdict. The 08-31f fix
# made an UNRECOGNIZED argument an error and left the ABSENT one silent, though
# its own comment already said "absence must ASSERT".
#
# ⚠ Text-level, on purpose: running the driver takes minutes, and what must not
# regress is the CONTRACT -- that absence stops, and that `canonical` resolves
# through CCX_MODE_CANONICAL rather than being typed as a mode name (which would
# freeze it at today's arm; it has moved 11 times in 25 days).
# =====================================================================
.root <- local({
  d <- normalizePath(getwd(), mustWork = FALSE)
  for (i in 1:8) { if (file.exists(file.path(d, "DESIGN.md"))) break; d <- dirname(d) }
  d
})
.src <- ccx_code_lines(readLines(file.path(.root, "calibration", "diag_joos_irf.R"),
                                 warn = FALSE))
.j <- paste(.src, collapse = "\n")

test_that("absence is an ERROR, not a default", {
  expect_false(grepl("JOOS_ARM_DEFAULT", .j, fixed = TRUE),
               info = "a default arm constant is back")
  # ⛔ THE WINDOW MUST BE THE BRANCH, NOT "the next few lines". The first
  # version of this test took `.src[i:(i+2)]` and asserted it contained
  # `stop(` -- which it did even with the silent default restored, because the
  # window ran on into the UNKNOWN-ARM branch and found THAT one's stop().
  # Mutation-testing caught it: the mutant scored 0 failures. Scope the text to
  # the absent-argument branch exactly, and assert BOTH what must be there and
  # what must not.
  i <- grep("!nzchar\\(a\\[1\\]\\)", .src)
  expect_length(i, 1L)
  j <- grep("a\\[1\\] %in% JOOS_ARM_NAMES", .src)
  expect_length(j, 1L)
  expect_gt(j, i)                                  # the branches are in this order
  branch <- paste(.src[i:(j - 1L)], collapse = " ")
  expect_match(branch, "stop\\(")
  expect_false(grepl("return(", branch, fixed = TRUE),
               info = "the absent-argument branch RETURNS a default instead of stopping")
})

test_that("`canonical` is an arm, and RESOLVES rather than being hardcoded", {
  expect_match(.j, 'JOOS_ARM_CANONICAL <- "canonical"')
  expect_match(.j, "JOOS_ARM_NAMES <- c\\(\"defaults\", JOOS_ARM_CANONICAL")
  # ⭐ it must resolve through the POINTER. Typing the mode name would freeze
  # the alias at today's arm, which is the whole reason it is an alias.
  expect_match(.j, "JOOS_ARM <- CCX_MODE_CANONICAL")
  expect_false(grepl('JOOS_ARM_CANONICAL <- "hilda', .j, fixed = TRUE))
  # and the output must record WHICH mode it resolved to
  expect_match(.j, "asked for")
})

test_that("the arm list offered by the error message is the real one", {
  # it must be built from CCX_MODE_FILES, not retyped -- a retyped list goes
  # stale the moment an arm is registered
  expect_match(.j, "names\\(CCX_MODE_FILES\\)")
})
