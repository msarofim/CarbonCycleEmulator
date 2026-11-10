#!/bin/bash
# Mutation test for tests/testthat/test-landing-page.R (2026-11-10). Each mutation edits a COPY of docs/ and must make
# the named block fail; the unmutated copy must pass. Run from the repository root:
#   bash outputs/diagnostics/landing_page_20261110/mutate_landing_page.sh
set -u
ROOT=$(pwd); TMP=$(mktemp -d)
run() {  # $1 label, $2 expected failing block, $3 python edit applied to index.html
  rm -rf "$TMP/docs"; cp -R "$ROOT/docs" "$TMP/docs"
  python3 -I - "$TMP/docs/index.html" "$3" <<'PY'
import sys; p, code = sys.argv[1], sys.argv[2]; s = open(p, encoding="utf-8").read()
ns = {"s": s}; exec(code, ns); open(p, "w", encoding="utf-8").write(ns["s"])
PY
  out=$(CCX_LANDING_DIR="$TMP/docs" Rscript -e 'r <- as.data.frame(testthat::test_file("tests/testthat/test-landing-page.R", reporter = "silent")); f <- r$test[r$failed > 0 | r$error]; cat("RESULT:", if (length(f)) paste(sub(" .*", "", f), collapse = ",") else "none", "\n")' 2>/dev/null | grep "^RESULT:")
  got=$(echo "$out" | sed 's/RESULT: //; s/ *$//')
  if [ "$got" = "$2" ]; then v=OK; else v=MISS; fi
  printf "%-44s expect %-6s got %-8s %s\n" "$1" "$2" "$got" "$v"
}
run "unmutated"                      "none" "pass"
run "M1 button points elsewhere"     "1."   "s = s.replace('id=\"open-app\" href=\"https://01a14244', 'id=\"open-app\" href=\"https://01a99999', 1)"
run "M2 repository link changed"     "1."   "s = s.replace('github.com/msarofim/CarbonCycleEmulator', 'github.com/msarofim/Other', 1)"
run "M3 og:image tag removed"        "2."   "import re; s = re.sub(r'<meta property=\"og:image\" content=[^>]*>\n', '', s, count=1)"
run "M4 og:image:width wrong"        "2."   "s = s.replace('og:image:width\" content=\"1200\"', 'og:image:width\" content=\"1201\"', 1)"
run "M5 shared view loses its query" "3."   "s = s.replace('location.replace(APP + location.search + location.hash)', 'location.replace(APP)', 1)"
run "M6 app woken on page load"      "3."   "s = s.replace('window.addEventListener(e, warm, { capture: true, passive: true }); });', 'window.addEventListener(e, warm, { capture: true, passive: true }); });\n    warm();', 1)"
run "M7 institution in the footer"   "4."   "s = s.replace('Made by Marcus C. Sarofim.', 'Made by Marcus C. Sarofim. Marcus C. Sarofim (NYU Marron Institute).', 1)"
rm -rf "$TMP"
