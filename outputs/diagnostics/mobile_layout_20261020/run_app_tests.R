# The app-facing test files (CarboTope phone layout work, 2026-10-20), one result row per file.
# Usage (repo root): Rscript outputs/diagnostics/mobile_layout_20261020/run_app_tests.R
suppressMessages(library(testthat))
files <- sort(c(Sys.glob("tests/testthat/test-review-*.R"), Sys.glob("tests/testthat/test-app-*.R"),
                "tests/testthat/test-plot-text-fits.R", "tests/testthat/test-ui-year-bounds-lint.R"))
commit <- system("git rev-parse --short HEAD", intern = TRUE)
dirty  <- length(system("git status --porcelain -- app tests R", intern = TRUE)) > 0
cat(sprintf("commit %s%s, %s, R %s, testthat %s\n", commit, if (dirty) " (+ uncommitted app/tests/R changes)" else "",
            format(Sys.time(), "%Y-%m-%d %H:%M"), getRversion(), packageVersion("testthat")))
tot <- c(passed = 0, failed = 0, skipped = 0, warnings = 0)
t0 <- Sys.time()
for (f in files) {
  r <- as.data.frame(test_file(f, reporter = "silent", stop_on_failure = FALSE))
  n <- c(passed = sum(r$nb) - sum(r$failed) - sum(r$skipped), failed = sum(r$failed) + sum(r$error),
         skipped = sum(r$skipped), warnings = sum(r$warning))
  tot <- tot + n
  cat(sprintf("%-42s pass %4d  fail %d  skip %d  warn %d\n", basename(f), n[1], n[2], n[3], n[4]))
}
cat(sprintf("%-42s pass %4d  fail %d  skip %d  warn %d   (%d files, %.1f min)\n", "TOTAL", tot[1], tot[2], tot[3], tot[4],
            length(files), as.numeric(difftime(Sys.time(), t0, units = "mins"))))
