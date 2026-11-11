#!/bin/bash
# Mutation test for the box-diagram fix (2026-11-11, CHANGELOG 11-11 n): each mutation breaks one part of the fix in
# app/R/plots.R in place and must fail the named blocks of test-diagram-pixels.R (1 = this machine's font, 2 = DejaVu
# Sans, the host's). The file is restored and cmp-checked after each. Same harness as mutate_a11b.sh.
# Stop any app running from this checkout first.
# Run: bash outputs/diagnostics/diagram_font_20261111/mutate_diagram.sh
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
T=test-diagram-pixels.R
echo "unmutated $T: $(cd $R && Rscript $S/run.R $T 2>/dev/null | grep '^RESULT:')"
run "M1 Soil box narrower (1.03 -> 0.92)"        app/R/plots.R $T "2."    's/soil = 1\.03,/soil = 0.92,/'
run "M2 litterfall head into Soil"               app/R/plots.R $T "1.,2." 's/E\("soil", "l"\) - g,  2\.25,/E("soil", "l") + 0.1,  2.25,/'
run "M3 label gap 0.07 -> 0.01"                  app/R/plots.R $T "1.,2." 's/DIAGRAM_LABEL_GAP <- 0\.07 /DIAGRAM_LABEL_GAP <- 0.01 /'
run "M4 Vegetation back at x = 1"                app/R/plots.R $T "1.,2." 's/x = c\(1\.95, 0\.62, 2\.85, 5\.1, 5\.1\)/x = c(1.95, 1, 2.85, 5.1, 5.1)/'
run "M5 no descender allowance (respiration)"    app/R/plots.R $T "1.,2." 's/2\.35, 0\.04, -lg, lg, 0, 0\)/2.35, 0, -lg, lg, 0, 0)/'
run "M6 old height (482 -> 440 px)"              app/R/plots.R $T "1.,2." 's/DIAGRAM_ASPECT <- 482 \/ 565/DIAGRAM_ASPECT <- 440 \/ 565/'
run "M7 air-to-warm-sea head into the box"       app/R/plots.R $T "1.,2." 's/E\("ml", "l"\) - g,   E\("atm", "r"\) \+ g,/E("ml", "l") + 0.1,   E("atm", "r") + g,/'
run "M8 mixing labels on their arrows (dx 0)"    app/R/plots.R $T "1.,2." 's/dx = c\(-lg, lg\), dy = dy,/dx = c(0, 0), dy = dy,/'
rm -rf $S
