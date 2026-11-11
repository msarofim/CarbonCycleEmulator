#!/bin/bash
# Mutation test for the 2026-11-11 y-title fit (app/R/plots.R): each mutation must fail the named blocks of
# tests/testthat/test-app-phone-layout.R. plots.R is restored and cmp-checked after every mutation.
# Stop any app running from this checkout first (it would read the mutated file).
R=/Users/MarcusMarcus/Documents/2026/CodeProjects/CarbonCycleEmulator
S=$(mktemp -d)
cp $R/app/R/plots.R $S/plots.R.orig
cat > $S/run.R <<'REOF'
r <- as.data.frame(testthat::test_file("tests/testthat/test-app-phone-layout.R", reporter = "silent"))
bad <- r[r$failed > 0 | r$error, ]
cat("RESULT:", if (nrow(bad)) paste(sub(" .*", "", bad$test), collapse = ",") else "none", "\n")
REOF
run() {  # $1 label, $2 expected, $3 perl substitution on plots.R
  perl -0pi -e "$3" $R/app/R/plots.R
  if cmp -s $R/app/R/plots.R $S/plots.R.orig; then echo "$1: MUTATION DID NOT APPLY"; return; fi
  out=$(cd $R && Rscript $S/run.R 2>/dev/null | grep "^RESULT:" | sed 's/RESULT: //; s/ *$//')
  printf "%-48s expect %-12s got %s\n" "$1" "$2" "$out"
  cp $S/plots.R.orig $R/app/R/plots.R; cmp -s $R/app/R/plots.R $S/plots.R.orig || echo "RESTORE FAILED"
}
echo "unmutated: $(cd $R && Rscript $S/run.R 2>/dev/null | grep '^RESULT:')"
run "M1 wide panels returned at once (pre-fix gate)" "3c,3d" 's/if \(is\.null\(px\) \|\| !inherits\(p, "ggplot"\)\) return\(p\)/if (is.null(px) || px > APP_FIT_MAX_PX || !inherits(p, "ggplot")) return(p)/'
run "M2 plotmath titles not wrapped (pre-fix)"     "3,3c,3d"   's/src <- if \(is\.character\(lab\)\) lab else attr\(lab, "ccx_src"\)/src <- if (is.character(lab)) lab else NULL/'
run "M3 cheap check far too lax (0.95)"           "3c,3d"     's/APP_FIT_Y_CHECK_FRAC <- 0\.4/APP_FIT_Y_CHECK_FRAC <- 0.95/'
run "M4 wide path also refits legends"            "3c"        's/if \(narrow && geo\$legend_over > 0\.5\)/if (geo\$legend_over > 0.5)/'
run "M5 stacked lines without displaystyle"       "3"         's/sprintf\("atop\(displaystyle\(%s\), %s\)"/sprintf("atop(%s, %s)"/'
cmp $R/app/R/plots.R $S/plots.R.orig && echo "plots.R restored"
