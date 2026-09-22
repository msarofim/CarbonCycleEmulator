# =====================================================================
# Gate: the beta review tab's CARD LEDGER (2026-09-22).
#
# WHAT THIS GUARDS, AND WHY IT IS WORTH A GATE. The "Known issues" tab is the
# whole point of the beta: it is how the model's remaining flaws are put to the
# community, one card per flaw, each asking deal-breaker / fixable /
# acceptable. The failure mode is SILENT in exactly the way the project's
# silent-gate family is -- add a card to RV_CARDS and forget to render it in
# ui.R, or renumber a card somebody has already commented on, and the tab still
# LOOKS complete. Nothing on screen says a question is missing.
#
# The check is STATIC: it reads app/ui.R as text rather than starting the app,
# because ui.R evaluation needs global.R, which compiles the C++ core and runs a
# spin-up. A gate nobody can afford to run is a gate that gets skipped.
#
# ⚠ MUTATION-TESTED BELOW. Every assertion here is paired with a deliberately
# broken ledger that it must REJECT. A gate that has only ever passed has not
# been shown to be a gate (project rule, ~/.claude/CLAUDE.md).
# =====================================================================

.rv_app_dir  <- file.path(.root, "app")
.rv_review_R <- file.path(.rv_app_dir, "R", "review.R")
.rv_ui_R     <- file.path(.rv_app_dir, "ui.R")

# Sourced into a child of the test env: review.R defines only constants and
# functions at load time (everything touching APP_* is inside a function body),
# so it loads without the app running.
.rv_env <- new.env(parent = environment())
if (file.exists(.rv_review_R)) sys.source(.rv_review_R, envir = .rv_env)

.rv_have <- file.exists(.rv_review_R) && file.exists(.rv_ui_R) &&
  exists("RV_CARDS", envir = .rv_env, inherits = FALSE)

.rv_ui_text <- if (file.exists(.rv_ui_R))
  paste(readLines(.rv_ui_R, warn = FALSE), collapse = "\n") else ""

skip_if_no_review <- function()
  testthat::skip_if_not(.rv_have, "app/R/review.R is not present")

test_that("the shipped card ledger is valid and fully rendered by ui.R", {
  skip_if_no_review()
  v <- get("rv_validate_cards", envir = .rv_env)
  problems <- v(get("RV_CARDS", envir = .rv_env), .rv_ui_text)
  expect_equal(problems, character(0),
               info = paste(problems, collapse = " | "))
})

test_that("card ids are the stable identifiers a commenter is asked to quote", {
  skip_if_no_review()
  cards <- get("RV_CARDS", envir = .rv_env)
  ids <- vapply(cards, function(c_) c_$id, 0)
  # Consecutive from 1 is NOT required -- a retired card must be allowed to
  # leave a hole rather than renumber the cards after it. Uniqueness and
  # positive integers are what a public comment reference needs.
  expect_false(anyDuplicated(ids) > 0)
  expect_true(all(ids == as.integer(ids)))
  expect_true(all(ids > 0))
})

test_that("every card names a class the tab can gloss, and asks a question", {
  skip_if_no_review()
  cards <- get("RV_CARDS", envir = .rv_env)
  gloss <- get("RV_CLASS_GLOSS", envir = .rv_env)
  for (c_ in cards) {
    expect_true(c_$class %in% names(gloss), info = c_$title)
    # a card whose "ask" is not a question is a card that collects nothing
    expect_true(grepl("\\?", c_$ask), info = c_$title)
  }
})

test_that("the feedback link is a placeholder until it is deliberately set", {
  skip_if_no_review()
  # ⚠ THIS TEST MUST BE UPDATED, NOT DELETED, WHEN THE URL IS SET. It exists so
  # that shipping a dead comment link is impossible by accident: the beta's only
  # channel is that URL, and a broken one costs exactly the feedback the beta
  # exists to collect. global.R's app_link_ok() is the runtime half; ui.R renders
  # a visible warning when it is FALSE.
  g <- paste(readLines(file.path(.rv_app_dir, "global.R"), warn = FALSE), collapse = "\n")
  expect_true(grepl("app_link_ok", g))
  expect_true(grepl("app_link_ok\\(APP_FEEDBACK_URL\\)", .rv_ui_text))
})

# ---------------------------------------------------------------------
# MUTATION TESTS -- break what the gate guards, confirm it fails
# ---------------------------------------------------------------------
test_that("the validator REJECTS a ledger with a duplicate id", {
  skip_if_no_review()
  v <- get("rv_validate_cards", envir = .rv_env)
  cards <- get("RV_CARDS", envir = .rv_env)
  bad <- cards; bad[[2]]$id <- bad[[1]]$id
  expect_true(any(grepl("duplicate card id", v(bad, NULL))))
})

test_that("the validator REJECTS a card ui.R never renders", {
  skip_if_no_review()
  v <- get("rv_validate_cards", envir = .rv_env)
  cards <- get("RV_CARDS", envir = .rv_env)
  # the exact accident this gate exists for: a ninth card added to the ledger
  # and never given a review_card() call in the tab
  ghost <- cards[[1]]
  ghost$id <- max(vapply(cards, function(c_) c_$id, 0)) + 1
  ghost$key <- "ghost"
  bad <- c(cards, list(ghost))
  out <- v(bad, .rv_ui_text)
  expect_true(any(grepl("ui.R never renders it", out, fixed = TRUE)))
})

test_that("the validator REJECTS a ui.R that renders a card not in the ledger", {
  skip_if_no_review()
  v <- get("rv_validate_cards", envir = .rv_env)
  cards <- get("RV_CARDS", envir = .rv_env)
  out <- v(cards, paste(.rv_ui_text, "\n review_card(99, \"rv_ghost\"),"))
  expect_true(any(grepl("not in the ledger", out, fixed = TRUE)))
})

test_that("the validator REJECTS a card with an ungloss-able class or empty text", {
  skip_if_no_review()
  v <- get("rv_validate_cards", envir = .rv_env)
  cards <- get("RV_CARDS", envir = .rv_env)
  b1 <- cards; b1[[1]]$class <- "not-a-class"
  expect_true(any(grepl("has no gloss", v(b1, NULL))))
  b2 <- cards; b2[[1]]$ask <- ""
  expect_true(any(grepl("ask is empty", v(b2, NULL))))
  b3 <- cards; b3[[1]]$detail <- NULL
  expect_true(any(grepl("lacks: detail", v(b3, NULL))))
})

test_that("the validator PASSES the shipped ledger it just rejected mutations of", {
  # the paired positive: a validator that rejected everything would pass every
  # mutation test above and still be useless
  skip_if_no_review()
  v <- get("rv_validate_cards", envir = .rv_env)
  expect_equal(v(get("RV_CARDS", envir = .rv_env), .rv_ui_text), character(0))
})
