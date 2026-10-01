# =====================================================================
# Gate: the app's RELEASE NAME and the mode it was cut on (2026-10-01).
#
# ⛔ WHY. The banner read "v1.0-hilda29l" for a day after the hilda33d adoption
# had repointed the app at a different parameter set: `APP_VERSION` was a
# literal, the app follows `CCX_MODE_CANONICAL`, and nothing tied the two
# together, so the label drifted SILENTLY (review 10-01c B2).
#
# Marcus ruled the new name, "BETA v1.0 CarboTope", which no longer carries a
# mode at all. So the mode the release was cut on is recorded on its own,
# `APP_RELEASE_MODE`, and this gate requires it to be the mode the app LOADS.
# Adopting a new canonical therefore turns this red until someone decides
# whether the release name moves too -- the decision that was skipped last time.
#
# The constants are PARSED out of global.R, not sourced: sourcing it compiles
# the C++ core and runs a spin-up (see test-pulse-linearity.R).
# ⚠ MUTATION-TESTED below: a stale release mode, and an app that stops
# resolving its parameters through CCX_MODE_CANONICAL, are both rejected.
# =====================================================================

.av_global <- file.path(.root, "app", "global.R")
.av_want <- c("APP_TITLE", "APP_VERSION", "APP_STAGE", "APP_RELEASE_NAME", "APP_RELEASE_MODE")
.av_env <- new.env(parent = baseenv())
if (file.exists(.av_global))
  for (e in parse(.av_global))
    if (is.call(e) && length(e) >= 3L && identical(as.character(e[[1]]), "<-") &&
        is.name(e[[2]]) && as.character(e[[2]]) %in% .av_want) eval(e, .av_env)
.av_text <- if (file.exists(.av_global))
  paste(readLines(.av_global, warn = FALSE), collapse = "\n") else ""

# the release mode must name the mode the app loads, and the app must load
# through CCX_MODE_CANONICAL for that comparison to mean anything
av_problems <- function(release_mode, app_text, canonical = CCX_MODE_CANONICAL) {
  bad <- character(0)
  if (!identical(release_mode, canonical))
    bad <- c(bad, sprintf("APP_RELEASE_MODE is '%s' but the app loads '%s'",
                          release_mode, canonical))
  if (!grepl("ccx_mode_file(CCX_MODE_CANONICAL)", app_text, fixed = TRUE))
    bad <- c(bad, "app_params() no longer resolves its mode through CCX_MODE_CANONICAL")
  bad
}

test_that("the release name is Marcus's ruled one, built from the named constants", {
  skip_if_not(file.exists(.av_global), "app/global.R is not present")
  for (w in .av_want) expect_true(exists(w, envir = .av_env, inherits = FALSE), info = w)
  # the ruled wording (Marcus 2026-10-01, review 10-01c B2), verbatim
  expect_identical(.av_env$APP_RELEASE_NAME, "BETA v1.0 CarboTope")
  # and no mode suffix is left in the version string to drift
  expect_false(grepl("hilda", .av_env$APP_VERSION, fixed = TRUE))
})

test_that("the release was cut on the mode the app actually loads", {
  skip_if_not(file.exists(.av_global), "app/global.R is not present")
  p <- av_problems(.av_env$APP_RELEASE_MODE, .av_text)
  expect_equal(p, character(0), info = paste(p, collapse = " | "))
})

test_that("MUTATION: a release mode left behind by an adoption is rejected", {
  # the exact 10-01 drift: the app moved to hilda33d, the label stayed on hilda29l
  p <- av_problems("hilda29l", .av_text, canonical = "hilda33d")
  expect_true(any(grepl("APP_RELEASE_MODE is 'hilda29l'", p, fixed = TRUE)))
})

test_that("MUTATION: an app that stops loading through CCX_MODE_CANONICAL is rejected", {
  txt <- gsub("ccx_mode_file(CCX_MODE_CANONICAL)", "ccx_mode_file(\"hilda29l\")",
              .av_text, fixed = TRUE)
  p <- av_problems(CCX_MODE_CANONICAL, txt)
  expect_true(any(grepl("no longer resolves", p, fixed = TRUE)))
})
