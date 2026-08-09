# Run the full test suite from the repo root:
#   Rscript tests/run_tests.R
suppressMessages(library(testthat))
res <- test_dir("tests/testthat", stop_on_failure = TRUE)
