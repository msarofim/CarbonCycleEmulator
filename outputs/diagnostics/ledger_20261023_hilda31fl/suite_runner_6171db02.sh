#!/bin/bash
cd /Users/MarcusMarcus/ccx_frozen/suite_20261023_6171db02
n=$(find data-raw/downloads -maxdepth 1 -type l | wc -l); [ -e data-raw/downloads/nuclear14c ] && [ ! -e data-raw/downloads/downloads ] && [ "$n" -ge 70 ] || { echo "REFUSING: data-raw/downloads not linked per file ($n links)"; exit 3; }
export OPENBLAS_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 OMP_NUM_THREADS=1
OUT=/Users/MarcusMarcus/Documents/2026/CodeProjects/CarbonCycleEmulator/outputs/diagnostics/suite_20261023_6171db02
Rscript -e '
t0 <- Sys.time()
r <- testthat::test_dir("tests/testthat", reporter = "summary", stop_on_failure = FALSE)
d <- as.data.frame(r)
fails <- d[d$failed > 0 | d$error, c("file", "test", "failed", "error")]
pf <- aggregate(cbind(nb, failed, skipped, warning, error = as.integer(error)) ~ file, data = d, FUN = sum)
write.csv(pf, "'"$OUT"'_perfile.csv", row.names = FALSE)
cat(sprintf("\n=== SUITE @ 6171db02 (code = 6171db02; hilda31fl ADOPTED, CHANGELOG 10-23 k; linked): %d passed, %d failed, %d skipped, %d errored, %d warnings (nb %d); %.1f min ===\n",
            sum(d$nb - d$failed - d$skipped), sum(d$failed), sum(d$skipped), sum(d$error), sum(d$warning), sum(d$nb),
            as.numeric(difftime(Sys.time(), t0, units = "mins"))))
print(fails, row.names = FALSE)
skips <- d[d$skipped > 0, c("file", "test")]; cat("skipped:\n"); print(skips, row.names = FALSE)
' > "$OUT.log" 2>&1
echo "rc=$?" >> "$OUT.log"
