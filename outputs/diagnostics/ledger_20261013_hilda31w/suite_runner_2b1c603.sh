#!/bin/bash
cd /Users/MarcusMarcus/ccx_frozen/suite_20261013_2b1c603
export OPENBLAS_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 OMP_NUM_THREADS=1
Rscript -e '
t0 <- Sys.time()
r <- testthat::test_dir("tests/testthat", reporter = "summary", stop_on_failure = FALSE)
d <- as.data.frame(r)
fails <- d[d$failed > 0 | d$error, c("file", "test", "failed", "error")]
cat(sprintf("\n=== SUITE @ 2b1c603: %d passed, %d failed, %d skipped, %d errored files/tests; %.1f min ===\n",
            sum(d$nb - d$failed - d$skipped), sum(d$failed), sum(d$skipped), sum(d$error),
            as.numeric(difftime(Sys.time(), t0, units = "mins"))))
print(fails, row.names = FALSE)
' > /Users/MarcusMarcus/Documents/2026/CodeProjects/CarbonCycleEmulator/outputs/diagnostics/suite_20261013_2b1c603.log 2>&1
echo "rc=$?" >> /Users/MarcusMarcus/Documents/2026/CodeProjects/CarbonCycleEmulator/outputs/diagnostics/suite_20261013_2b1c603.log
