#!/bin/bash
# usage: mutate.sh <file> <perl-substitution> <label>
f="$1"; sub="$2"; lab="$3"; S=$(dirname "$0")
cp -p "$f" "$S/backup"
perl -0pi -e "$sub" "$f"
if cmp -s "$f" "$S/backup"; then echo "$lab: MUTATION DID NOT APPLY"; exit 1; fi
out=$(OPENBLAS_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 Rscript -e 'r <- testthat::test_dir("tests/testthat", filter = "ms-file", reporter = "silent", stop_on_failure = FALSE); d <- as.data.frame(r); cat(sum(d$failed), sum(d$error), paste(unique(d$test[d$failed > 0 | d$error]), collapse=" | "))' 2>&1 | tail -1)
cp -p "$S/backup" "$f"; cmp -s "$f" "$S/backup" || { echo "RESTORE FAILED $f"; exit 2; }
echo "$lab: failed/errored = $out"
