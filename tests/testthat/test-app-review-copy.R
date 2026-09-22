# =====================================================================
# Gate: the APP COPY fixed in Marcus's 2026-09-22 review STAYS fixed.
#
# WHAT THIS GUARDS. The 45-comment review produced 27 copy items whose whole
# content is a string: a sentence on a card that was FALSE (the app denied the
# volcanic mechanism it runs), a claim that was stale (`No ocean circulation`),
# a dated code comment that had leaked into user-facing copy. None of them is
# reachable by any other test -- the app renders, the suite passes, and the
# page says the wrong thing.
#
# WHY IT IS A GATE AND NOT A CHECKLIST. The 09-22 (o) session lost three
# already-applied edits to a Python batch that asserted part-way through and
# wrote NOTHING; they were reported "ok" and discarded. The only thing that
# caught it was an audit pass of exactly this shape, and that audit lived in a
# scratchpad and did not survive the session -- so this file exists to stop the
# next copy edit from silently reverting one of these, and to stop the audit
# itself from being scratchpad-only a second time.
#
# ⚠ R COMMENT LINES ARE STRIPPED BEFORE MATCHING. Six of the 27 items are
# documented in the source by a comment that QUOTES the old wording ("...the
# `No ocean circulation` claim is cut..."). Matching raw source reads every one
# of those as a miss -- the audit's own false-failure mode, measured: 6 of 27.
# Only WHOLE-LINE comments are stripped, because deciding whether a `#` inside
# a line opens a comment or sits in a string needs a parser. If a TRAILING
# comment ever trips a check here, move that comment onto its own line; do not
# weaken the strip.
#
# ⚠ MUTATION-TESTED BELOW. Every mechanism in this file -- the absent check,
# the present check, the comment strip -- is paired with input it must REJECT
# or must NOT reject. A gate that has only ever passed has not been shown to be
# a gate (project rule, ~/.claude/CLAUDE.md).
# =====================================================================

# The copy surface: every file the review's items were applied to. Read as one
# blob on purpose -- an item that moves between ui.R and review.R is still fixed,
# and this gate should not fail on a refactor that changes nothing on screen.
AC_COPY_FILES <- c(
  "app/ui.R", "app/server.R", "app/global.R",
  "app/R/review.R", "app/R/params_meta.R", "app/R/plots.R",
  "app/R/plots_review.R", "R/mechanisms.R"
)

# Drop whole-line R comments (including roxygen `#'`). See the header.
ac_strip_comments <- function(lines) lines[!grepl("^\\s*#", lines)]

ac_copy_source <- function(root, files = AC_COPY_FILES) {
  paths <- file.path(root, files)
  paste(unlist(lapply(paths[file.exists(paths)], function(p)
    ac_strip_comments(readLines(p, warn = FALSE)))), collapse = "\n")
}

# (label, must be ABSENT, must be PRESENT); NA for "not checked on this side".
AC_CHECKS <- list(
  c("K1 no 'Given only emissions'",      "Given only emissions", NA),
  c("K1 no 'Nothing here was tuned'",    "Nothing here was tuned", NA),
  c("K2 driver list in takeaway",        NA, "an ENSO index and volcanic aerosol"),
  c("K4 see_card text",                  NA, "The solid one shows the"),
  c("W4 airborne fraction reworded",     "the single most useful summary", "not a clean score for the sinks"),
  c("C4 dated clause gone",              "since 2026-09-01", NA),
  c("C4 ENSO blurb",                     NA, "out of the surface ocean, year by year"),
  c("C5 'exactly one reason' gone",      "for exactly one", "driven by sunlight and temperature"),
  c("F1 FaIR text",                      "So the honest reading is", "Future scenario temperatures are a result"),
  c("F3 confound sentence gone",         "confound it", NA),
  c("N1 acknowledgement wording",        NA, "any potential"),
  c("N2 lead sentence cut",              "not quoted", NA),
  c("N4 mechanism not carrier",          "What carrier would you expect", "What mechanism might help"),
  c("N8 volcanic mechanism",             "for which there is no mechanism", "Pinatubo"),
  c("N9 comparison gloss",               "not a gate. Nothing from this source", "long tail of carbon dioxide is robust"),
  c("N10 physical mechanism",            "When a named mechanism loses", "When a physical mechanism loses"),
  c("N11 'most that naming buys' gone",  "most that naming buys", NA),
  c("N12 two lists",                     NA, "rv_standins"),
  c("N12 shim gate",                     NA, "rv_validate_shims"),
  c("U1 gated param table",              "desc = c(", "app_param_table(CCX_PARAM_NAMES"),
  c("U2 drivers table",                  NA, "h_drivers"),
  c("U2 IGCC no longer a target",        NA, "What drives the model"),
  c("U3/R4 affiliation dropped",         "NYU Marron Institute\"", "APP_AUTHOR       <- \"Marcus C. Sarofim\""),
  c("U4 isotope sentence",               "which is what lets the isotope tab work", "All exchanges include all three carbon"),
  c("U5 'No ocean circulation' gone",    "No ocean circulation", "meet only in the atmosphere"),
  c("U6 goal first",                     NA, "able to duplicate observed hemispheric, seasonal"),
  c("O2 banner shortened",               NA, "provenance_detail"),
  # C2 (09-22 r): the chart measured the claim next to it and falsified it --
  # ENSO off removes 23 % of the scatter, not the wobble. See
  # [[ccx_wobble_is_mostly_emissions]].
  c("C2 wobble claim corrected",         "switch it off and the wobbles go", "about a quarter of the wobble")
)

ac_audit <- function(src, checks = AC_CHECKS) {
  problems <- character(0)
  for (ck in checks) {
    label <- ck[[1]]; absent <- ck[[2]]; present <- ck[[3]]
    if (!is.na(absent) && grepl(absent, src, fixed = TRUE))
      problems <- c(problems, paste0(label, ": still contains '", absent, "'"))
    if (!is.na(present) && !grepl(present, src, fixed = TRUE))
      problems <- c(problems, paste0(label, ": missing '", present, "'"))
  }
  problems
}

.ac_src <- ac_copy_source(.root)

test_that("every copy file the review touched is present", {
  missing <- AC_COPY_FILES[!file.exists(file.path(.root, AC_COPY_FILES))]
  expect_equal(missing, character(0),
               info = paste("copy surface moved or lost:", paste(missing, collapse = ", ")))
})

test_that("all 28 of Marcus's 2026-09-22 copy items are still applied", {
  problems <- ac_audit(.ac_src)
  expect_equal(problems, character(0), info = paste(problems, collapse = " | "))
})

test_that("every check actually checks something", {
  for (ck in AC_CHECKS)
    expect_true(!is.na(ck[[2]]) || !is.na(ck[[3]]),
                info = paste("check specifies neither side:", ck[[1]]))
})

# ---------------------------------------------------------------------
# MUTATION TESTS -- each shows the gate REJECTS what it claims to reject.
# ---------------------------------------------------------------------

test_that("MUTATION: an absent-check fires when the old wording returns to CODE", {
  # Not a comment: the reverted sentence as it would appear back in a tags$p().
  mutated <- paste(.ac_src, '  p("No ocean circulation -- diffusion only.")', sep = "\n")
  problems <- ac_audit(mutated)
  expect_true(any(grepl("U5", problems, fixed = TRUE)),
              info = paste("gate missed a reverted line:", paste(problems, collapse = " | ")))
})

test_that("MUTATION: a present-check fires when the replacement wording is deleted", {
  mutated <- gsub("meet only in the atmosphere", "meet somewhere", .ac_src, fixed = TRUE)
  problems <- ac_audit(mutated)
  expect_true(any(grepl("U5", problems, fixed = TRUE)),
              info = paste("gate missed a deleted replacement:", paste(problems, collapse = " | ")))
})

test_that("MUTATION: the comment strip is what keeps the six documented items green", {
  # The measured false-failure mode: matching RAW source (comments included)
  # reports misses for the six items whose fix is documented by a comment that
  # quotes the old wording. If this ever drops to zero, the comments went away
  # and the strip is no longer load-bearing -- not that the gate got better.
  raw <- paste(unlist(lapply(
    file.path(.root, AC_COPY_FILES)[file.exists(file.path(.root, AC_COPY_FILES))],
    function(p) readLines(p, warn = FALSE))), collapse = "\n")
  expect_true(length(ac_audit(raw)) > length(ac_audit(.ac_src)),
              info = "stripping comments changed nothing; the strip is untested here")
})

test_that("MUTATION: the strip removes whole-line comments and nothing else", {
  lines <- c("  # No ocean circulation", "#' No ocean circulation",
             'p("No ocean circulation")', "x <- 1  # No ocean circulation")
  kept <- ac_strip_comments(lines)
  expect_equal(length(kept), 2L)
  expect_true(any(grepl("p(\"", kept, fixed = TRUE)))
  expect_true(any(grepl("x <- 1", kept, fixed = TRUE)))
})
