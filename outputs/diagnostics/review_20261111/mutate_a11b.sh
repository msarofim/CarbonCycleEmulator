#!/bin/bash
# Mutation test for A11b (2026-11-11): the Download links of the batch-A build never got an address, because A11 hides
# the Download line while its chart draws and Shiny suspends an output it sees as hidden. Each mutation breaks the fix
# in app/R/downloads.R in place and must fail block A11b; the file is restored and cmp-checked after each. Same harness
# as mutate_batch_a.sh. Stop any app running from this checkout first.
# Run: bash outputs/diagnostics/review_20261111/mutate_a11b.sh
R=/Users/MarcusMarcus/Documents/2026/CodeProjects/CarbonCycleEmulator
S=$(mktemp -d)
cat > $S/run.R <<'REOF'
f <- commandArgs(trailingOnly = TRUE)[1]
r <- as.data.frame(testthat::test_file(file.path("tests/testthat", f), reporter = "silent"))
bad <- r[r$failed > 0 | r$error, ]
cat("RESULT:", if (nrow(bad)) paste(sub(" .*", "", bad$test), collapse = ",") else "none", "\n")
REOF
run() {  # $1 label, $2 source file, $3 test file, $4 expected failing blocks, $5 perl substitution
  cp $R/$2 $S/orig; perl -0pi -e "$5" $R/$2
  if cmp -s $R/$2 $S/orig; then echo "$1: MUTATION DID NOT APPLY"; return; fi
  got=$(cd $R && Rscript $S/run.R $3 2>/dev/null | grep "^RESULT:" | sed 's/RESULT: //; s/ *$//')
  printf "%-46s %-34s expect %-10s got %s\n" "$1" "$3" "$4" "$got"
  cp $S/orig $R/$2; cmp -s $R/$2 $S/orig || echo "RESTORE FAILED $2"
}
T=test-app-review-20261111.R
L='    for (suffix in c("_csv", "_png")) shiny::outputOptions(output, paste0(id, suffix), suspendWhenHidden = FALSE)'
echo "unmutated $T: $(cd $R && Rscript $S/run.R $T 2>/dev/null | grep '^RESULT:')"
run "M13 A11b options line removed"      app/R/downloads.R $T "A11b." "s/\Q$L\E\n//"
run "M14 A11b PNG links left suspended"  app/R/downloads.R $T "A11b." 's/for \(suffix in c\("_csv", "_png"\)\) shiny::outputOptions/for (suffix in c("_csv")) shiny::outputOptions/'
run "M15 A11b suspendWhenHidden = TRUE"  app/R/downloads.R $T "A11b." 's/paste0\(id, suffix\), suspendWhenHidden = FALSE\)/paste0(id, suffix), suspendWhenHidden = TRUE)/'
run "M16 A11b options before the output" app/R/downloads.R $T "A11b." "s/\Q$L\E\n//; s/(  register <- function\(id\) \{\n)/\$1$L\n/"
rm -rf $S
