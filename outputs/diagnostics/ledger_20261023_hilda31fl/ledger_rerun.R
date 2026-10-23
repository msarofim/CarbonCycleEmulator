options(testthat.summary.max_reports = 1000)
fs <- c("app-a11y","app-downloads","app-precompute","app-scan-items","app-version","constraint-map","flask-label",
        "flux-trace-exact","futures-ribbons","gate-bounds","mechanisms","mode-file","ms-reference-set",
        "ocean-climate-card","pulse-linearity","review-precompute")
r <- testthat::test_dir("tests/testthat", filter = paste0("^(", paste(fs, collapse = "|"), ")$"),
                        reporter = testthat::SummaryReporter$new(max_reports = 1000), stop_on_failure = FALSE)
d <- as.data.frame(r)
cat(sprintf("\n=== RERUN of the 16 failing files @ 6171db02: %d failed, %d errored ===\n", sum(d$failed), sum(d$error)))
