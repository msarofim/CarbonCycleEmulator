# =====================================================================
# test-git-stamp-lint.R -- nothing outside R/provenance.R runs git for a stamp.
#
# THE DEFECT THIS GUARDS (2026-10-01 f/h; R/provenance.R's header has the
# measurements). 69 drivers carried a hand-rolled `system("git rev-parse ...")`
# stamp that VANISHED, blanked, or CRASHED the save outside a checkout. They
# were converted to ccx_git_stamp() in one pass, so there is no baseline to
# shrink: the allowed count is zero. The idiom had already regrown once --
# diag_pulse_vs_tcre.R re-wrote it hours after it was measured -- so this lint
# fails on ANY system()/system2() git call in a live source, wherever written.
#
# CODE ONLY, through ccx_code_lines() (helper-code-lines.R): a driver whose
# comment describes the old idiom is not a relapse
# ([[text_gate_matches_its_own_comment]]). Each file is scanned as ONE string,
# so a call split across lines still matches.
#
# SCOPE: the top level of R/, calibration/, app/, app/R/ and data-raw/, as the
# 2026-10-01 audit's grep. NOT scanned: calibration/archive/ (archived drivers,
# three of which still carry the old idiom; they are not run) and tests/ (the
# helper's own test builds scratch repos with git).
# EXEMPT: R/provenance.R, the helper.
# ALLOWED: calibration/run_post_refit_adoption.R's one `git mv` -- a state
# change, not a stamp; its exit status is checked and its args are shQuote()d.
# =====================================================================

GL_DIRS    <- c("R", "calibration", "app", file.path("app", "R"), "data-raw")
GL_EXEMPT  <- file.path("R", "provenance.R")
GL_ALLOWED <- c("calibration/run_post_refit_adoption.R" = 1L)
GL_PATTERN <- "\\bsystem2?\\s*\\([^)]*[\"']git\\b"

gl_count <- function(lines) {
  code <- paste(ccx_code_lines(lines), collapse = "\n")
  sum(gregexpr(GL_PATTERN, code, perl = TRUE)[[1]] > 0L)
}

gl_scan <- function(root = ccx_root()) {
  fs  <- unlist(lapply(GL_DIRS, function(d)
    list.files(file.path(root, d), pattern = "\\.R$", full.names = TRUE)))
  rel <- setdiff(substring(fs, nchar(root) + 2L), GL_EXEMPT)
  n   <- vapply(rel, function(f) gl_count(readLines(file.path(root, f), warn = FALSE)), 0L)
  n[n > 0L]
}

test_that("no live source runs git except through ccx_git_stamp() and the allowed git mv", {
  hits <- gl_scan()
  extra <- hits[!names(hits) %in% names(GL_ALLOWED)]
  expect_identical(names(extra), character(0),
                   info = paste("convert to ccx_git_stamp() (R/provenance.R):",
                                paste(sprintf("%s (%d)", names(extra), extra), collapse = ", ")))
})

test_that("the allow-list and the exemption never go stale", {
  hits <- gl_scan()
  for (f in names(GL_ALLOWED))
    expect_identical(unname(hits[f]), GL_ALLOWED[[f]], info = paste(f, "-- trim GL_ALLOWED if the call is gone"))
  expect_gt(gl_count(readLines(ccx_path(GL_EXEMPT), warn = FALSE)), 0L)   # the helper IS where git runs
})

test_that("the lint fires on every shape of the old idiom and not on a comment (power check)", {
  fire <- c(
    'COMMIT <- tryCatch(system("git rev-parse --short HEAD", intern = TRUE), error = function(e) "?")',
    'say("  commit  %s", tryCatch(trimws(system2("git", c("rev-parse", "--short", "HEAD"),',
    '                                     stdout = TRUE)), error = function(e) "unknown"))',
    'x <- system2(',
    '  "git", c("status", "--porcelain"), stdout = TRUE)',
    'h <- system(paste0("git -C ", d, " rev-parse HEAD"), intern = TRUE)',
    "d <- system('git status --porcelain', intern = TRUE)")
  quiet <- c(
    '# COMMIT <- tryCatch(system("git rev-parse --short HEAD", intern = TRUE), error = function(e) "?")',
    'COMMIT <- ccx_git_stamp()   # was system("git rev-parse --short HEAD")',
    'cat("see git log for the history\\n")',
    'system("ls -la")',
    'mysystem("git")')
  expect_identical(gl_count(fire), 5L)
  expect_identical(gl_count(quiet), 0L)
  expect_identical(gl_count(c(quiet, fire)), 5L)
})
