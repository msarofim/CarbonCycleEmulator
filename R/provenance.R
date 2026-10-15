# =====================================================================
# provenance.R -- THE ONE GIT STAMP. Every driver that records which code
# produced its output calls ccx_git_stamp(); nothing else in the repo runs git
# for a stamp (tests/testthat/test-git-stamp-lint.R fails if anything does).
#
# THE DEFECT THIS REPLACES (2026-10-01 f/h). 69 drivers stamped their commit
# with some form of
#
#     tryCatch(system("git rev-parse --short HEAD", intern = TRUE), error = ...)
#
# Outside a git checkout -- e.g. a frozen copy of the repo run from elsewhere -- git exits
# 128 and system() / system2() only WARN, so the handler never fires and the
# value is character(0). Measured 2026-10-01 on every consumer shape the drivers
# used: a cat(sprintf()) line VANISHES; a say()/xt() line prints blank; an rds
# field stores chr(0); a figure caption built by one sprintf() is EMPTY; and
# data.frame(..., provenance = sprintf(...)) / df$provenance <- ... ERROR, so 13
# drivers would have lost their CSV -- most also their rds -- at the save step,
# after the whole computation. The hand-rolled dirty checks,
# length(system("git status ...")) > 0, read FALSE -- CLEAN -- whenever git
# could not answer. There were five path sets and four fallback values, and
# diag_pulse_vs_tcre.R re-wrote the idiom hours after it was measured: hence
# one helper, its own mutation test (test-git-stamp.R), and a lint.
#
# THE STAMP, always ONE non-empty string:
#   <hash>          HEAD, and nothing under `paths` differs from it
#   <hash>+dirty    a tracked edit (staged or not) or an UNTRACKED file under
#                   `paths`, other than `exclude`. Every R/*.R is sourced by
#                   every driver, committed or not.
#   <hash>+dirty?   git gave no status, so the tree is NOT PROVEN clean. Kept
#                   distinct from +dirty so a broken check cannot pass for a
#                   dirty tree, or for a clean one.
#   <hash>+frozen?  not a checkout, but the bundle's FROZEN_FROM_COMMIT.txt names
#                   the commit it was frozen from on its first line (read since
#                   Marcus's 2026-10-01 ruling). "?" because a bundle's own edits
#                   cannot be checked -- some bundles admit them on a second line.
#   ?               no commit could be read at all.
# Ignored inputs (data-raw/downloads/) are invisible to git status either way.
#
# ⚠ Args are shQuote()d: system2() hands them to sh UNQUOTED, and the
# `:(exclude)` pathspec is a sh syntax error without it -- the first cut of the
# 10-01 (f) stamp read "+dirty" on a CLEAN tree that way.
# ⚠ `-C root`, and root must BE the checkout's top level: `root/.git` exists (a
# directory in a checkout, a file in a worktree) AND git agrees it is the top
# level. A bundle unpacked inside some other repository would otherwise be
# stamped with THAT repo's HEAD. Without `root/.git` git is not run at all, so a
# bundle prints no "fatal: not a git repository" on every start.
# ⚠ `--untracked-files=normal` is explicit: a `status.showUntrackedFiles = no`
# in any git config would otherwise hide an untracked R/*.R and read clean.
# ⚠ A driver that WRITES under `paths` passes its own output as `exclude`: it
# is the product, never an input, and a second run before the first is
# committed would otherwise stamp ITSELF dirty ([[gate_reads_its_own_output]]).
# =====================================================================

CCX_STAMP_PATHS          <- c("R", "src", "calibration", "app", "data")
CCX_STAMP_DIRTY          <- "+dirty"
CCX_STAMP_STATUS_UNKNOWN <- "+dirty?"
CCX_STAMP_FROZEN         <- "+frozen?"
CCX_STAMP_NONE           <- "?"
CCX_STAMP_FROZEN_FILE    <- "FROZEN_FROM_COMMIT.txt"

#' The git stamp of the code a driver is running
#' @param paths   repo-relative paths whose state counts toward "+dirty"
#' @param exclude the driver's own outputs under `paths`, repo-relative or
#'                absolute under `root` (e.g. the ccx_path() it saves to): git
#'                resolves an absolute pathspec inside the work tree itself, and
#'                one it cannot resolve fails the status -- "+dirty?", never clean
#' @param root    the repository root
#' @return one non-empty string; see the header for its forms
ccx_git_stamp <- function(paths = CCX_STAMP_PATHS, exclude = character(0),
                          root = ccx_root()) {
  git <- function(...) suppressWarnings(tryCatch(
    system2("git", shQuote(c("-C", root, ...)), stdout = TRUE),
    error = function(e) structure(character(0), status = NA_integer_)))
  ok  <- function(x) is.null(attr(x, "status")) && length(x) == 1L && nzchar(x)
  top <- if (file.exists(file.path(root, ".git"))) git("rev-parse", "--show-toplevel")
  if (!is.null(top) && ok(top) && identical(normalizePath(top, mustWork = FALSE),
                                            normalizePath(root, mustWork = FALSE))) {
    h <- git("rev-parse", "--short", "HEAD")
    if (ok(h)) {
      d <- git("status", "--porcelain", "--untracked-files=normal", "--", paths,
               if (length(exclude)) paste0(":(exclude)", exclude))
      return(paste0(h, if (!is.null(attr(d, "status"))) CCX_STAMP_STATUS_UNKNOWN
                       else if (length(d)) CCX_STAMP_DIRTY else ""))
    }
  }
  ff <- file.path(root, CCX_STAMP_FROZEN_FILE)
  l1 <- if (file.exists(ff)) trimws(readLines(ff, n = 1L, warn = FALSE)) else character(0)
  if (length(l1) == 1L && grepl("^[0-9a-f]{7,40}$", l1))
    return(paste0(substr(l1, 1L, 7L), CCX_STAMP_FROZEN))
  CCX_STAMP_NONE
}

#' Whether a stamp says the tree was dirty: TRUE, FALSE, or NA when it cannot tell
#' @param stamp a ccx_git_stamp() value
ccx_stamp_dirty <- function(stamp) {
  if (endsWith(stamp, CCX_STAMP_DIRTY)) TRUE
  else if (grepl("?", stamp, fixed = TRUE)) NA
  else FALSE
}
