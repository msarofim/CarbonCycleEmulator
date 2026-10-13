files <- c("app-params-table","app-version","canonical-contracts","constraint-map","flux-trace-exact","futures-ribbons",
           "gate-bounds","imbalance-panel","mechanisms","ms-reference-set","ocean-climate-card","pulse-linearity",
           "review-card-numbers","spinup-diagnostics","stability")
for (f in files) {
  r <- testthat::test_file(file.path("tests/testthat", paste0("test-", f, ".R")), reporter = "silent", stop_on_failure = FALSE)
  for (t in r) for (res in t$results) {
    if (inherits(res, c("expectation_failure", "expectation_error"))) {
      cat(sprintf("\n### %s | %s | %s\n", f, class(res)[1], t$test))
      sr <- res$srcref; if (!is.null(sr)) cat("  at line", sr[1], "\n")
      cat("  ", substr(gsub("\n", "\n   ", conditionMessage(res)), 1, 900), "\n")
    }
  }
}
