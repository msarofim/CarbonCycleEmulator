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

# UPDATED 2026-10-15, when the URL was set to the published post 1 (Marcus sent the link). The guard
# above stays; this adds what a SET link must look like. A share link copied from Substack carries the
# author's referral code and utm_* tracking, so a bare post address is required: https, a Substack
# post path, no query string, no fragment (rv_card_url() appends its own, RV_FEEDBACK_ANCHOR).
rv_feedback_url_ok <- function(u)
  grepl("^https://[a-z0-9-]+\\.substack\\.com/p/[a-z0-9-]+$", u)

rv_feedback_url <- function(global_lines)
  sub('^\\s*APP_FEEDBACK_URL\\s*<-\\s*"([^"]*)".*$', "\\1",
      grep("^\\s*APP_FEEDBACK_URL\\s*<-", global_lines, value = TRUE))

test_that("the feedback link is SET, to a bare Substack post address", {
  skip_if_no_review()
  u <- rv_feedback_url(readLines(file.path(.rv_app_dir, "global.R"), warn = FALSE))
  expect_length(u, 1L)
  expect_false(identical(u, "SET-BEFORE-DEPLOY"))
  expect_true(rv_feedback_url_ok(u), info = u)
})

# ADDED 2026-10-16: the per-card links ended in "#card-N", which no Substack post serves, so each
# "Comment on issue N" opened the top of the post. The allowed fragments are the ones MEASURED that day on a
# fresh load of post 1 (rv_card_url()'s comment in review.R): "discussion" scrolled to the comment box;
# "card-1" did not move the page. rv_card_url() is called with the shipped APP_FEEDBACK_URL from global.R.
RV_SUBSTACK_ANCHORS_MEASURED <- "discussion"
rv_comment_fragment_ok <- function(url)
  grepl("#", url, fixed = TRUE) && sub("^[^#]*#", "", url) %in% RV_SUBSTACK_ANCHORS_MEASURED

rv_card_url_with <- function(feedback_url, fn = .rv_env$rv_card_url) {
  environment(fn) <- list2env(list(
    APP_FEEDBACK_URL = feedback_url,
    app_link_ok = function(u) is.character(u) && length(u) == 1L && nzchar(u) &&
      !identical(u, "SET-BEFORE-DEPLOY")), parent = .rv_env)
  fn
}

test_that("each card's comment link lands on the post's comment box", {
  skip_if_no_review()
  u <- rv_feedback_url(readLines(file.path(.rv_app_dir, "global.R"), warn = FALSE))
  f <- rv_card_url_with(u)
  for (id in vapply(.rv_env$RV_CARDS, `[[`, numeric(1), "id")) {
    url <- f(id)
    expect_true(startsWith(url, paste0(u, "#")), info = url)
    expect_true(rv_comment_fragment_ok(url), info = url)
  }
  expect_null(rv_card_url_with("SET-BEFORE-DEPLOY")(1L))
})

test_that("MUTATION: the fragment check rejects the old #card-N link and a bare post address", {
  skip_if_no_review()
  u <- "https://thesaraphreport.substack.com/p/the-debut-of-carbotope-beta-a-new"
  old <- rv_card_url_with(u, function(id) {
    if (!app_link_ok(APP_FEEDBACK_URL)) return(NULL)
    sprintf("%s#card-%d", APP_FEEDBACK_URL, id)
  })
  expect_false(rv_comment_fragment_ok(old(1L)))
  expect_false(rv_comment_fragment_ok(u))
  expect_false(rv_comment_fragment_ok(paste0(u, "#")))
})

test_that("MUTATION: the set-link check rejects the placeholder and a tracked share link", {
  skip_if_no_review()
  expect_false(rv_feedback_url_ok("SET-BEFORE-DEPLOY"))
  expect_false(rv_feedback_url_ok(paste0(
    "https://thesaraphreport.substack.com/p/the-debut-of-carbotope-beta-a-new",
    "?r=ywmw&utm_campaign=post&utm_medium=web&showWelcomeOnShare=true")))
  expect_false(rv_feedback_url_ok("http://thesaraphreport.substack.com/p/the-debut-of-carbotope-beta-a-new"))
  expect_false(rv_feedback_url_ok("https://thesaraphreport.substack.com/"))
  expect_identical(rv_feedback_url('APP_FEEDBACK_URL <- "SET-BEFORE-DEPLOY"'), "SET-BEFORE-DEPLOY")
})

# EVERY link constant, not just the comment link (2026-10-06, Marcus: "Go ahead and fix the repo link").
# The repo link rendered UNGUARDED, a live <a> to "SET-BEFORE-DEPLOY", while global.R's comment said ui.R
# guards its links: the test above named one URL, so the other was never checked. This one is generated
# from global.R's own definitions, so a third URL cannot go unchecked either.
rv_unguarded_urls <- function(global_lines, ui_text) {
  urls <- unique(sub("^\\s*(APP_[A-Z_]*URL)\\s*<-.*", "\\1",
                     grep("^\\s*APP_[A-Z_]*URL\\s*<-", global_lines, value = TRUE)))
  urls[!vapply(urls, function(u) grepl(sprintf("app_link_ok(%s)", u), ui_text, fixed = TRUE), logical(1))]
}

test_that("every APP_*_URL in global.R is guarded by app_link_ok() in ui.R", {
  skip_if_no_review()
  g <- readLines(file.path(.rv_app_dir, "global.R"), warn = FALSE)
  expect_gte(length(grep("^\\s*APP_[A-Z_]*URL\\s*<-", g)), 2L)   # the feedback AND the repo link
  expect_identical(rv_unguarded_urls(g, .rv_ui_text), character(0))
})

test_that("MUTATION: the URL-guard check fires on the 10-06 defect (the repo link unguarded)", {
  skip_if_no_review()
  g <- readLines(file.path(.rv_app_dir, "global.R"), warn = FALSE)
  mutated <- gsub("app_link_ok(APP_REPO_URL)", "TRUE", .rv_ui_text, fixed = TRUE)
  expect_identical(rv_unguarded_urls(g, mutated), "APP_REPO_URL")
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

test_that("the validator REJECTS a ledger that reuses a RETIRED id", {
  skip_if_no_review()
  v <- get("rv_validate_cards", envir = .rv_env)
  cards <- get("RV_CARDS", envir = .rv_env)
  ids <- vapply(cards, function(c_) c_$id, 0)
  retired <- get("RV_RETIRED_IDS", envir = .rv_env)
  # 2026-10-01: the AIC card (the old card 6) was retired and its hole CLOSED by renumbering
  # (Marcus: "renumber the cards"; the app has never been deployed). So the shipped ledger
  # retires nothing and runs 1..n -- and whatever it retires later, it must not reuse.
  expect_false(any(ids %in% retired))
  # POWER, on an injected retirement (the shipped set is empty): the same validator, its
  # RV_RETIRED_IDS bound to a retired id, refuses a ledger that reuses it -- so after
  # deployment "card N" cannot come to mean a different question -- and passes one that
  # leaves the hole.
  v_ret <- v; environment(v_ret) <- list2env(list(RV_RETIRED_IDS = max(ids) + 1L), parent = .rv_env)
  bad <- cards; bad[[length(bad)]]$id <- max(ids) + 1L
  expect_true(any(grepl("retired card id", v_ret(bad, NULL), fixed = TRUE)))
  expect_equal(v_ret(cards, NULL), character(0))
})

test_that("the tab's lead counts the ledger, not a typed word", {
  skip_if_no_review()
  cards <- get("RV_CARDS", envir = .rv_env)
  words <- get("RV_COUNT_WORDS", envir = .rv_env)
  lead <- get("RV_TAB_LEAD", envir = .rv_env)
  expect_true(startsWith(lead, paste(words[length(cards)], "things")),
              info = sprintf("%d cards; lead begins '%s'", length(cards), substr(lead, 1, 20)))
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

# =====================================================================
# Gate: server.R's LAST TOP-LEVEL EXPRESSION IS THE SERVER FUNCTION.
#
# THE BUG THIS EXISTS FOR (2026-09-22, found by opening the app in a browser).
# Shiny's two-file style takes `source("server.R")$value` as the server. A
# utility defined at the BOTTOM of server.R therefore BECOMES the server:
# `%||% <- function(a, b)` did, and every session died with
#     Error in server(...) : unused arguments (input = ..., output = ...)
# before one output rendered. The UI still built and every plot was simply
# BLANK -- indistinguishable from a slow panel or an empty dataset.
#
# ⚠ AND THE CHECK THAT MISSED IT. An ad-hoc smoke test asserted
# `is.function(source("server.R")$value)`, which was TRUE -- of the wrong
# function. is.function() is not the property; the ARITY is. That is the
# "a gate that passes is not a gate that works" failure, so this one asserts
# the formals by name and is mutation-tested below.
# =====================================================================

.rv_server_R <- file.path(.rv_app_dir, "server.R")

# The server function's required signature, by name and order.
RV_SERVER_FORMALS <- c("input", "output", "session")

#' The formals of the last top-level expression of an app file.
#' @return character() if it is not a function at all
rv_last_value_formals <- function(path) {
  v <- source(path, local = new.env())$value
  if (!is.function(v)) return(character())
  names(formals(v))
}

test_that("server.R's last top-level value is the (input, output, session) server", {
  skip_if_not(file.exists(.rv_server_R), "app/server.R is not present")
  expect_equal(rv_last_value_formals(.rv_server_R), RV_SERVER_FORMALS)
})

test_that("the arity check REJECTS a helper left at the bottom of server.R", {
  skip_if_not(file.exists(.rv_server_R), "app/server.R is not present")
  # reproduce the exact 2026-09-22 bug in a copy: append the helper that used
  # to live there, and confirm this gate fails rather than passing on
  # is.function() the way the smoke test did
  tmp <- tempfile(fileext = ".R")
  on.exit(unlink(tmp), add = TRUE)
  writeLines(c(readLines(.rv_server_R, warn = FALSE),
               "`%||%` <- function(a, b) if (is.null(a)) b else a"), tmp)
  got <- rv_last_value_formals(tmp)
  expect_false(identical(got, RV_SERVER_FORMALS))
  expect_equal(got, c("a", "b"))          # the bug's own signature
  expect_true(is.function(source(tmp, local = new.env())$value))  # why is.function() missed it
})

# =====================================================================
# THE STAND-IN LIST (card 7 since the 2026-10-01 renumbering; card 8 at review N12, Marcus 2026-09-22)
#
# The card used to name the SHIMS in prose while the table under it listed the
# PINS, and presented the two as one list -- Marcus asked how they related and
# the honest answer was that they are different things. They are now two
# labeled tables with the overlap computed. RV_SHIMS is the one part that
# CANNOT be derived (whether a fitted name is a stand-in is a judgment, taken
# from the 2026-09-16 whole-model review), so it is the part that can go stale
# the way the parameter label table did -- hence a gate, mutation-tested.
# =====================================================================
test_that("every stand-in names a parameter this build still carries", {
  skip_if_no_review()
  v <- get("rv_validate_shims", envir = .rv_env)
  problems <- v(get("RV_SHIMS", envir = .rv_env), CCX_PARAM_NAMES)
  expect_equal(problems, character(0), info = paste(problems, collapse = " | "))
})

test_that("the stand-in list and the pin list are allowed to overlap, and do", {
  skip_if_no_review()
  shims <- names(get("RV_SHIMS", envir = .rv_env))
  pins  <- names(CCX_MODE_CANONICAL_PINS)
  # Not an assertion about WHICH names overlap -- that moves with the canonical
  # and asserting it here would be a second claim about the mode file. What the
  # card needs is that the two lists are genuinely different sets, so that
  # presenting them as one was a real error and not pedantry.
  expect_false(setequal(shims, pins))
  expect_true(length(setdiff(shims, pins)) > 0)
  expect_true(length(setdiff(pins, shims)) > 0)
})

test_that("the stand-in gate rejects a name that has left the parameter set", {
  skip_if_no_review()
  v <- get("rv_validate_shims", envir = .rv_env)
  broken <- get("RV_SHIMS", envir = .rv_env)
  broken[["a_name_that_left"]] <- "a stand-in for a parameter that is gone"
  problems <- v(broken, CCX_PARAM_NAMES)
  expect_true(any(grepl("a_name_that_left", problems)))
})

test_that("the stand-in gate rejects an unnamed or empty entry", {
  skip_if_no_review()
  v <- get("rv_validate_shims", envir = .rv_env)
  b1 <- get("RV_SHIMS", envir = .rv_env); b1[["rep_dC"]] <- ""
  expect_true(any(grepl("rep_dC", v(b1, CCX_PARAM_NAMES))))
  b2 <- get("RV_SHIMS", envir = .rv_env); names(b2)[1] <- ""
  expect_true(length(v(b2, CCX_PARAM_NAMES)) > 0)
  expect_true(length(v(list(), CCX_PARAM_NAMES)) > 0)
})
