#!/usr/bin/env Rscript
# =====================================================================
# calibration/diag_dirty_stamp_repro.R -- does a "+dirty"-stamped artifact reproduce from a CLEAN tree?
# (2026-10-12, CHANGELOG 2026-10-12 (a).) Compares a stored stage-1 module rds (calibration/fit_iav_module.R)
# with its re-run from a frozen `git archive` of the SAME commit, element by element, with identical():
# every element and every provenance field must match except the three that must differ (commit, date,
# base_file); check$ref is compared by basename (an absolute path to the same file). Mutation-tested: a
# 1e-12 nudge to one pin and a flipped check verdict are both reported as differing.
# Usage: Rscript calibration/diag_dirty_stamp_repro.R <stored.rds> <repro.rds>
# =====================================================================
a <- commandArgs(TRUE); s <- readRDS(a[1]); r <- readRDS(a[2])
cat("stored:", a[1], "\n  commit", s$provenance$commit, "| repro commit", r$provenance$commit, "\n")
# fields that MUST differ (when, where, which stamp) -- everything else must be identical()
PROV_EXPECTED_DIFF <- c("commit", "date", "base_file")
stopifnot(identical(names(s), names(r)))
bad <- 0L
for (n in setdiff(names(s), "provenance")) {
  x <- s[[n]]; y <- r[[n]]
  if (n == "check" && is.list(x)) { x$ref <- basename(x$ref); y$ref <- basename(y$ref) }   # an absolute path to the same file
  ok <- identical(x, y)
  if (!ok) bad <- bad + 1L
  cat(sprintf("  %-12s %s\n", n, if (ok) "identical" else paste("DIFFERS:", paste(all.equal(x, y), collapse = "; "))))
}
ps <- s$provenance; pr <- r$provenance
stopifnot(identical(names(ps), names(pr)))
for (n in setdiff(names(ps), PROV_EXPECTED_DIFF)) if (!identical(ps[[n]], pr[[n]])) {
  bad <- bad + 1L; cat(sprintf("  provenance$%s DIFFERS: %s vs %s\n", n, format(ps[[n]]), format(pr[[n]]))) }
cat(sprintf("  provenance: %d of %d fields identical (the %d that must differ: %s)\n",
            sum(vapply(setdiff(names(ps), PROV_EXPECTED_DIFF), function(n) identical(ps[[n]], pr[[n]]), logical(1))),
            length(setdiff(names(ps), PROV_EXPECTED_DIFF)), length(PROV_EXPECTED_DIFF), paste(PROV_EXPECTED_DIFF, collapse = ", ")))
cat(if (bad == 0L) "  VERDICT: the clean re-run reproduces the stored artifact exactly\n" else sprintf("  VERDICT: %d element(s) differ\n", bad))
