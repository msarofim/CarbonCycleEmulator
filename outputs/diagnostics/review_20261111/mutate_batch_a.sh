#!/bin/bash
# Mutation test for batch A of the 2026-11-11 review: each mutation breaks one fix in place and must fail the named
# block of the named test file; the file is restored and cmp-checked after each. Stop any app running from this
# checkout first. Run: bash outputs/diagnostics/review_20261111/mutate_batch_a.sh
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
for f in $T test-takeaway-arithmetic.R test-plot-text-fits.R test-stylised-takeaway.R; do echo "unmutated $f: $(cd $R && Rscript $S/run.R $f 2>/dev/null | grep '^RESULT:')"; done
run "M1 A3 colours ignored"              app/R/plots.R $T "A3." 's/g <- g \+ scale_colour_manual\(values = colours\[lev\], breaks = lev, aesthetics = c\("colour", "fill"\)\)/g <- g/'
run "M2 A7 default steps (2.5)"          app/R/plots.R $T "A7/A8." 's/b <- scales::breaks_extended\(n, Q = c\(1, 5, 2, 4, 3\)\)\(lims\)\n  b <- b\[is.finite\(b\) & abs\(b - round\(b\)\) < 1e-9\]/b <- scales::breaks_extended(n)(lims)/'
run "M3 A8 method not unwrapped"         app/R/plots.R $T "A7/A8." 's/\.fit_unwrap <- function\(fn\) if \(inherits\(fn, "ggproto_method"\) && is\.function\(environment\(fn\)\$f\)\) environment\(fn\)\$f else fn/.fit_unwrap <- function(fn) fn/'
run "M4 A8 two decimals always"          app/global.R  $T "A8." 's/if \(is\.finite\(x\) && abs\(x\) < 0\.1 && x != 0\) formatC/if (FALSE) formatC/'
run "M5 A13 FaIR key beside the rest"    app/R/plots.R $T "A13." 's/\(if \(has_fair\) theme\(legend\.box = "vertical"\)\)/NULL/'
run "M6 A13 Without: label as typed"     app/global.R  $T "A13." 's/return\(paste\("Without:", app_mech_inline\(CCX_MECHANISMS\[\[off\]\]\$label\)\)\)/return(paste("Without:", CCX_MECHANISMS[[off]]\$label))/'
run "M7 A15 month count ignored"         app/global.R  $T "A15." 's/names\(n\)\[n >= min_months\]/names(n)/'
run "M8 A11 empty-chart rule removed"    app/ui.R      $T "A4/A10/A11." 's/      \.shiny-plot-output:not\(:has\(img\)\) \+ \.ccx-dl \{ display: none; \}\n//'
run "M9 A10 slider mask removed"         app/global.R  $T "A4/A10/A11." 's/sliderInput <- function\(\.\.\.\)\n  htmltools::tagAppendAttributes\(shiny::sliderInput\(\.\.\.\), `data-force-edges` = "true", \.cssSelector = "input"\)/sliderInput <- function(...) shiny::sliderInput(...)/'
run "M10 A2 unrounded difference"        app/global.R  test-takeaway-arithmetic.R "A5:" 's/a <- round\(with_switch\); b <- round\(without_switch\); d <- b - a/a <- round(with_switch); b <- round(without_switch); d <- round(without_switch - with_switch)/'
run "M11 A1 bold measured plain"         app/R/plots.R test-plot-text-fits.R "3a2." 's/diagram_note_pt\(DIAGRAM_NOTE_SIZE_BOLD \* scale\), face = "bold"\)\)/diagram_note_pt(DIAGRAM_NOTE_SIZE_BOLD * scale)))/'
run "M12 A12 big numbers with decimals"  app/global.R  test-stylised-takeaway.R "every" 's/big <- e_end \/ e0 >= 10/big <- FALSE/'
rm -rf $S
