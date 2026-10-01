# =====================================================================
# test-git-stamp.R -- ccx_git_stamp() (R/provenance.R), MUTATION-TESTED in
# scratch git repositories: every stamp form is built from a REAL tree state,
# never asserted from the code that computes it.
#
# WHY (2026-10-01 g). The bare idiom this helper replaced returned character(0)
# outside a checkout, and its consumers then dropped the stamped line, blanked
# a figure caption, or crashed a data.frame() at the save step. The 10-01 (f)
# stamp's own first cut read "+dirty" on a CLEAN tree (an unquoted `:(exclude)`
# pathspec is a sh syntax error), and only a mutation test caught it. So every
# guard in the helper has a case here that FAILS without it -- see the
# CHANGELOG entry for the mutation table -- and the stamp is checked where it
# lands, in a written line and a written CSV ([[to_csv_drops_dataframe_attrs]]).
#
# The scratch repos live under tempdir() in a directory whose name carries a
# space and parentheses, so `-C root` is quoted or every case fails. The one
# case that corrupts an index makes git print its own complaint to stderr: the
# helper passes git's diagnosis through on purpose.
# =====================================================================

skip_if_no_git <- function() if (!nzchar(Sys.which("git"))) testthat::skip("git is not on PATH")

# Scratch-repo git, with identity, signing and hooks pinned so a user's config
# cannot fail a commit. Errors loudly: a fixture that silently failed to build
# would make every assertion below vacuous.
gs_git <- function(dir, ...) {
  out <- suppressWarnings(system2("git", shQuote(c("-C", dir, "-c", "user.name=ccx-test",
           "-c", "user.email=ccx-test@example.invalid", "-c", "commit.gpgsign=false",
           "-c", "core.hooksPath=/dev/null", ...)), stdout = TRUE, stderr = TRUE))
  if (!is.null(attr(out, "status")))
    stop("scratch git failed: git ", paste(c(...), collapse = " "), "\n", paste(out, collapse = "\n"))
  out
}

# A committed scratch repo: one file under each stamped path, one OUTSIDE them
# (notes/), and a tracked data/out.rds standing in for a driver's own output.
gs_repo <- function(env = parent.frame(), parent = tempdir()) {
  d <- tempfile("git stamp (scratch) ", tmpdir = parent)
  dir.create(d)
  withr::defer(unlink(d, recursive = TRUE), envir = env)
  for (p in c(CCX_STAMP_PATHS, "notes")) {
    dir.create(file.path(d, p)); writeLines("v1", file.path(d, p, "f.txt"))
  }
  writeLines("v1", file.path(d, "data", "out.rds"))
  gs_git(d, "init", "-q"); gs_git(d, "add", "-A"); gs_git(d, "commit", "-q", "-m", "scratch")
  list(dir = d, head = gs_git(d, "rev-parse", "--short", "HEAD"))
}

# A directory that is NOT a checkout, as a frozen bundle under ~/ccx_frozen/ is.
gs_bundle <- function(env = parent.frame(), parent = tempdir()) {
  d <- tempfile("frozen bundle ", tmpdir = parent)
  dir.create(d)
  withr::defer(unlink(d, recursive = TRUE), envir = env)
  d
}
gs_outside_any_repo <- function(d) !is.null(attr(suppressWarnings(
  system2("git", shQuote(c("-C", d, "rev-parse", "--git-dir")), stdout = TRUE, stderr = FALSE)), "status"))

gs_edit <- function(r, ...) cat("v2\n", file = file.path(r$dir, ...), append = TRUE)

test_that("a clean checkout stamps HEAD, and nothing else", {
  skip_if_no_git()
  r <- gs_repo()
  expect_match(r$head, "^[0-9a-f]{7,}$")
  expect_identical(ccx_git_stamp(root = r$dir), r$head)
})

test_that("every kind of change under the stamped paths reads +dirty", {
  skip_if_no_git()
  cases <- list(                                       # each case gets its own repo
    "tracked edit in R/"     = function(r) gs_edit(r, "R", "f.txt"),
    "staged-only edit"       = function(r) { gs_edit(r, "calibration", "f.txt"); gs_git(r$dir, "add", "-A") },
    "edit in src/"           = function(r) gs_edit(r, "src", "f.txt"),
    "edit in app/"           = function(r) gs_edit(r, "app", "f.txt"),
    "untracked file in data" = function(r) writeLines("new", file.path(r$dir, "data", "new.rds")),
    "untracked R/*.R"        = function(r) writeLines("x <- 1", file.path(r$dir, "R", "new.R")),
    "deleted tracked file"   = function(r) file.remove(file.path(r$dir, "R", "f.txt")))
  for (nm in names(cases)) {
    r <- gs_repo(); cases[[nm]](r)
    expect_identical(ccx_git_stamp(root = r$dir), paste0(r$head, CCX_STAMP_DIRTY), info = nm)
  }
})

test_that("a change OUTSIDE the stamped paths does not read dirty", {
  skip_if_no_git()
  r <- gs_repo(); gs_edit(r, "notes", "f.txt"); writeLines("new", file.path(r$dir, "notes", "new.md"))
  expect_identical(ccx_git_stamp(root = r$dir), r$head)
})

test_that("an untracked R/*.R reads dirty even where git config hides untracked files", {
  skip_if_no_git()
  r <- gs_repo(); gs_git(r$dir, "config", "status.showUntrackedFiles", "no")
  writeLines("x <- 1", file.path(r$dir, "R", "new.R"))
  expect_identical(ccx_git_stamp(root = r$dir), paste0(r$head, CCX_STAMP_DIRTY))
})

test_that("a driver's OWN output is excluded -- repo-relative or absolute -- and nothing else is", {
  skip_if_no_git()
  r <- gs_repo(); gs_edit(r, "data", "out.rds")
  expect_identical(ccx_git_stamp(root = r$dir), paste0(r$head, CCX_STAMP_DIRTY))   # the control
  expect_identical(ccx_git_stamp(exclude = file.path("data", "out.rds"), root = r$dir), r$head)
  expect_identical(ccx_git_stamp(exclude = file.path(r$dir, "data", "out.rds"), root = r$dir), r$head)
  expect_identical(ccx_git_stamp(exclude = file.path(normalizePath(r$dir), "data", "out.rds"), root = r$dir), r$head)
  # a first build: the output is new, so untracked
  r2 <- gs_repo(); writeLines("v1", file.path(r2$dir, "data", "first build.rds"))
  expect_identical(ccx_git_stamp(exclude = file.path("data", "first build.rds"), root = r2$dir), r2$head)
  # narrow: the excluded output AND another file under data/ changed
  gs_edit(r, "data", "f.txt")
  expect_identical(ccx_git_stamp(exclude = file.path("data", "out.rds"), root = r$dir),
                   paste0(r$head, CCX_STAMP_DIRTY))
  # an exclude git cannot resolve fails the status: NOT PROVEN clean, never clean
  r3 <- gs_repo()
  expect_identical(ccx_git_stamp(exclude = file.path(tempdir(), "elsewhere.rds"), root = r3$dir),
                   paste0(r3$head, CCX_STAMP_STATUS_UNKNOWN))
})

test_that("a git status that FAILS reads +dirty?, never clean and never +dirty", {
  skip_if_no_git()
  r <- gs_repo()
  writeBin(as.raw(rep(0x5a, 64)), file.path(r$dir, ".git", "index"))   # corrupt index; HEAD still reads
  expect_identical(ccx_git_stamp(root = r$dir), paste0(r$head, CCX_STAMP_STATUS_UNKNOWN))
})

test_that("a checkout with no commit yet reads '?', never an empty or a dirty stamp", {
  skip_if_no_git()
  d <- gs_bundle(); gs_git(d, "init", "-q")
  dir.create(file.path(d, "R")); writeLines("x <- 1", file.path(d, "R", "a.R"))
  expect_identical(ccx_git_stamp(root = d), CCX_STAMP_NONE)
})

test_that("not a checkout: '?' without FROZEN_FROM_COMMIT.txt, '<hash>+frozen?' with one", {
  skip_if_no_git()
  b <- gs_bundle()
  skip_if_not(gs_outside_any_repo(b), "tempdir() is inside a git repository")
  expect_identical(ccx_git_stamp(root = b), CCX_STAMP_NONE)
  ff <- file.path(b, CCX_STAMP_FROZEN_FILE)
  writeLines("d84b7aa9d4f3f392317757bcc5e7361d6a2a005c", ff)                 # a full hash
  expect_identical(ccx_git_stamp(root = b), paste0("d84b7aa", CCX_STAMP_FROZEN))
  writeLines(c("00ead9f", "+ uncommitted: CCX_MODE_FREE_PARENT_PINS branch"), ff)  # short + a hand note
  expect_identical(ccx_git_stamp(root = b), paste0("00ead9f", CCX_STAMP_FROZEN))
  writeLines("  c56c84f  ", ff)                                              # padded
  expect_identical(ccx_git_stamp(root = b), paste0("c56c84f", CCX_STAMP_FROZEN))
  for (bad in list("not a commit", "abc12", character(0))) {                # unreadable -> '?'
    writeLines(bad, ff)
    expect_identical(ccx_git_stamp(root = b), CCX_STAMP_NONE, info = paste(bad, collapse = ""))
  }
})

test_that("a bundle unpacked INSIDE another repository is not stamped with that repository's HEAD", {
  skip_if_no_git()
  outer <- gs_repo()
  b <- file.path(outer$dir, "notes", "unpacked bundle")
  dir.create(b)
  expect_identical(ccx_git_stamp(root = b), CCX_STAMP_NONE)
  dir.create(file.path(b, ".git"))                    # a stray, empty .git: git walks up to `outer`
  expect_identical(ccx_git_stamp(root = b), CCX_STAMP_NONE)
  writeLines("a15652e", file.path(b, CCX_STAMP_FROZEN_FILE))
  expect_identical(ccx_git_stamp(root = b), paste0("a15652e", CCX_STAMP_FROZEN))
})

test_that("in a checkout git wins over a FROZEN_FROM_COMMIT.txt", {
  skip_if_no_git()
  r <- gs_repo(); writeLines("a15652e", file.path(r$dir, CCX_STAMP_FROZEN_FILE))
  expect_identical(ccx_git_stamp(root = r$dir), r$head)
})

test_that("outside a checkout git is never RUN, so a bundle prints no 'fatal: not a git repository'", {
  skip_if_no_git()
  b <- gs_bundle(); skip_if_not(gs_outside_any_repo(b), "tempdir() is inside a git repository")
  outer <- gs_repo(); nested <- file.path(outer$dir, "notes", "unpacked bundle"); dir.create(nested)
  # a recording `git` first on PATH, in front of the real one
  shim <- tempfile("git shim "); dir.create(shim); withr::defer(unlink(shim, recursive = TRUE))
  log <- file.path(shim, "calls.log"); file.create(log)
  writeLines(c("#!/bin/sh", 'printf "%s\\n" "$*" >> "$GS_SHIM_LOG"', 'exec "$GS_REAL_GIT" "$@"'),
             file.path(shim, "git"))
  Sys.chmod(file.path(shim, "git"), "755")
  withr::local_envvar(GS_SHIM_LOG = log, GS_REAL_GIT = unname(Sys.which("git")),
                      PATH = paste(shim, Sys.getenv("PATH"), sep = .Platform$path.sep))
  # the shim has power: in a checkout it records the helper's calls
  expect_identical(ccx_git_stamp(root = outer$dir), outer$head)
  expect_gt(length(readLines(log)), 0L)
  for (d in c(b, nested)) {
    file.create(log)
    expect_identical(ccx_git_stamp(root = d), CCX_STAMP_NONE)
    expect_identical(readLines(log), character(0), info = d)
  }
})

test_that("ccx_stamp_dirty() reads TRUE, FALSE, or NA when the stamp cannot tell", {
  expect_identical(ccx_stamp_dirty("4b0b802"), FALSE)
  expect_identical(ccx_stamp_dirty(paste0("4b0b802", CCX_STAMP_DIRTY)), TRUE)
  expect_identical(ccx_stamp_dirty(paste0("4b0b802", CCX_STAMP_STATUS_UNKNOWN)), NA)
  expect_identical(ccx_stamp_dirty(paste0("4b0b802", CCX_STAMP_FROZEN)), NA)
  expect_identical(ccx_stamp_dirty(CCX_STAMP_NONE), NA)
})

test_that("every stamp form survives the consumer shapes that used to drop or crash on it", {
  skip_if_no_git()
  r <- gs_repo(); b <- gs_bundle()
  stamps <- c(clean = ccx_git_stamp(root = r$dir), none = ccx_git_stamp(root = b))
  gs_edit(r, "R", "f.txt"); stamps["dirty"] <- ccx_git_stamp(root = r$dir)
  writeLines("d84b7aa", file.path(b, CCX_STAMP_FROZEN_FILE)); stamps["frozen"] <- ccx_git_stamp(root = b)
  log <- tempfile(fileext = ".log"); csv <- tempfile(fileext = ".csv")
  withr::defer(unlink(c(log, csv)))
  for (nm in names(stamps)) {
    s <- stamps[[nm]]
    expect_length(s, 1L); expect_true(nzchar(s), info = nm)
    cat(sprintf("== header -- commit %s ==\n", s), file = log)               # the line that vanished
    expect_identical(readLines(log), sprintf("== header -- commit %s ==", s), info = nm)
    df <- data.frame(a = 1:3, provenance = sprintf("drv @%s; no RNG", s))   # the save that crashed
    utils::write.csv(df, csv, row.names = FALSE)
    expect_identical(utils::read.csv(csv)$provenance, rep(sprintf("drv @%s; no RNG", s), 3L), info = nm)
    expect_true(nzchar(paste(strwrap(sprintf("caption; commit %s; units", s), 118), collapse = "\n")))
  }
  expect_identical(unname(stamps[c("dirty", "frozen", "none")]),
                   c(paste0(r$head, CCX_STAMP_DIRTY), paste0("d84b7aa", CCX_STAMP_FROZEN), CCX_STAMP_NONE))
})
