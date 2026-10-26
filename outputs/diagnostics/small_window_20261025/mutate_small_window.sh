#!/bin/bash
# Mutation test for the 2026-10-25 small-window fixes: each mutation must fail its named block in
# tests/testthat/test-app-phone-layout.R. Files are restored and cmp-checked after every mutation.
R=/Users/MarcusMarcus/Documents/2026/CodeProjects/CarbonCycleEmulator
S=$(mktemp -d)   # scratch copies of the two mutated files and the runner
cp $R/app/R/plots.R $S/plots.R.orig; cp $R/app/server.R $S/server.R.orig
cat > $S/run_phone_layout.R <<'REOF'
r <- as.data.frame(testthat::test_file("tests/testthat/test-app-phone-layout.R", reporter = "silent",
                                       package = NULL, load_package = "none"))
bad <- r[r$failed > 0 | r$error, ]
cat("RESULT:", if (nrow(bad)) paste(sub(" .*", "", bad$test), collapse = ",") else "none", "\n")
REOF
run() {  # $1 label, $2 file, $3 perl substitution
  perl -0pi -e "$3" "$2"
  if cmp -s "$2" "$S/$(basename $2).orig"; then echo "$1: MUTATION DID NOT APPLY"; return; fi
  out=$(cd $R && Rscript $S/run_phone_layout.R 2>/dev/null | grep "^RESULT:")
  echo "$1: failing blocks = $out"
  cp "$S/$(basename $2).orig" "$2"; cmp -s "$2" "$S/$(basename $2).orig" || echo "RESTORE FAILED $2"
}
echo "unmutated: $(cd $R && Rscript $S/run_phone_layout.R 2>/dev/null | grep '^RESULT:')"
run "M1 handler returns p (pre-fix)"  $R/app/R/plots.R 's/(left as drawn \(", conditionMessage\(e\), "\)"\)\n    )p0/$1p/'
run "M2 no fixed-label branch"         $R/app/R/plots.R 's/if \(!is\.null\(sc\$labels\) && !inherits\(sc\$labels, "waiver"\) && !is\.function\(sc\$labels\)\) \{/if (FALSE) {/'
run "M3 app_plot_dim without req"      $R/app/R/plots.R 's/shiny::req\(is\.numeric\(v\) && length\(v\) == 1L && is\.finite\(v\) && v > 0\)/invisible(NULL)/'
run "M4 renderPlotFit without width"   $R/app/server.R  's/width = app_plot_dim\(session, id, "width"\), //'
cmp $R/app/R/plots.R $S/plots.R.orig && cmp $R/app/server.R $S/server.R.orig && echo "all restored"
