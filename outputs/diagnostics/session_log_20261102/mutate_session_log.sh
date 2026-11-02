#!/bin/bash
# Mutation test for the 2026-11-02 session log: each mutation must fail its named block in
# tests/testthat/test-app-session-log.R. Files are restored and cmp-checked after every mutation.
R=/Users/MarcusMarcus/Documents/2026/CodeProjects/CarbonCycleEmulator
S=$(mktemp -d)   # scratch copies of the mutated files and the runner
for f in app/R/sessionlog.R app/R/links.R app/server.R; do cp "$R/$f" "$S/$(basename $f).orig"; done
cat > $S/run.R <<'REOF'
r <- as.data.frame(testthat::test_file("tests/testthat/test-app-session-log.R", reporter = "silent",
                                       package = NULL, load_package = "none"))
bad <- r[r$failed > 0 | r$error, ]
cat("RESULT:", if (nrow(bad)) paste(sub(" .*", "", bad$test), collapse = ",") else "none", "\n")
REOF
run() {  # $1 label, $2 file, $3 perl substitution
  perl -0pi -e "$3" "$2"
  if cmp -s "$2" "$S/$(basename $2).orig"; then echo "$1: MUTATION DID NOT APPLY"; return; fi
  out=$(cd $R && Rscript $S/run.R 2>/dev/null | grep "^RESULT:")
  echo "$1: failing blocks = $out"
  cp "$S/$(basename $2).orig" "$2"; cmp -s "$2" "$S/$(basename $2).orig" || echo "RESTORE FAILED $2"
}
echo "unmutated: $(cd $R && Rscript $S/run.R 2>/dev/null | grep '^RESULT:')"
run "M1 no headless class"                 $R/app/R/sessionlog.R 's/  if \(grepl\("headless", ua, fixed = TRUE\)\) return\("headless"\)\n//'
run "M2 referrer path kept"                $R/app/R/sessionlog.R 's/  h <- sub\("\[\/\?#:\]\.\*\$", "", h\)\n//'
run "M3 first appearance counted"          $R/app/R/sessionlog.R 's/setdiff\(intersect\(names\(v\), names\(st\$prev\)\), /setdiff(names(v), /'
run "M4 referrer in the Keeling link"      $R/app/R/links.R      's/c\("k_years", "k_hemi", "k_obs"\),/c("k_years", "k_hemi", "k_obs", "ccx_referrer"),/'
run "M5 server never starts the log"       $R/app/server.R       's/  app_session_log_server\(input, session\)\n//'
run "M6 script sends the full referrer"    $R/app/R/sessionlog.R 's/h = new URL\(document\.referrer\)\.hostname/h = document.referrer/'
for f in sessionlog.R links.R; do cmp -s $R/app/R/$f $S/$f.orig || echo "NOT RESTORED $f"; done
cmp -s $R/app/server.R $S/server.R.orig || echo "NOT RESTORED server.R"
echo "all restored"
