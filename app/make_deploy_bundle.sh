#!/bin/bash
# Build the shinyapps.io deploy bundle for CarboTope from a COMMIT (default HEAD).
#
#   app/make_deploy_bundle.sh <out_dir> [commit]
#
# The ship list lives HERE, once, so app/DEPLOY.md cannot drift from it (it named a mode file two
# adoptions old until 2026-10-15). The parameter file's path is never typed: it is whatever
# ccx_mode_file() returns at that commit. Only TRACKED files ship (git archive), so local artifacts
# such as app/Rplots.pdf never do. data-raw/ is excluded: nothing in the app reads it at run time
# since 2026-10-14 (nuclear 14C is data/forcing_nuclear_c14.rds).
#
# shinyapps.io runs the app found at the bundle ROOT, but the app lives in app/ and reads the repo
# root (R/, data/, src/, DESIGN.md), so the bundle gets a two-line root app.R that runs app/.
# Tested 2026-10-15 by running shiny::runApp(<out_dir>) on a bundle built this way (CHANGELOG 10-15).
set -euo pipefail
OUT=${1:?usage: app/make_deploy_bundle.sh <out_dir> [commit]}
REV=${2:-HEAD}
ROOT=$(git -C "$(dirname "$0")/.." rev-parse --show-toplevel)
[ -e "$OUT" ] && { echo "refusing: $OUT exists" >&2; exit 1; }

# the canonical mode file AT THAT COMMIT, resolved by the code itself
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
git -C "$ROOT" archive "$REV" R data DESIGN.md | tar -x -C "$TMP"     # sourcing R/ reads data/
MODE=$(cd "$TMP" && Rscript -e '
  suppressMessages(for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f))
  cat(sub(paste0(ccx_path(), "/"), "", ccx_mode_file(), fixed = TRUE))' 2>"$TMP/mode.err" | tail -1) || true
[ -n "$MODE" ] || { echo "could not resolve ccx_mode_file() at $REV:" >&2; tail -5 "$TMP/mode.err" >&2; exit 1; }

SHIP=(R src/ccx_core.cpp data DESIGN.md app
      calibration/lib_design_gates.R calibration/lib_seas_limbs.R calibration/lib_glodap_obs.R
      "$MODE")
# ⛔ NO PLACEHOLDER COPY SHIPS (2026-10-16). Slots awaiting Marcus's wording are shown on screen in
# brackets that open with this marker (app/R/plots.R PULSE_DEPTH_*); a bundle carrying one is refused.
PLACEHOLDER_MARK='[MARCUS:'
# (this script holds the marker itself, so it is excluded from its own search)
if git -C "$ROOT" grep -n -F "$PLACEHOLDER_MARK" "$REV" -- app ':!app/make_deploy_bundle.sh' \
     >"$TMP/placeholders" 2>/dev/null; then
  echo "refusing: placeholder copy at $REV (replace it first):" >&2; cat "$TMP/placeholders" >&2; exit 1
fi
mkdir -p "$OUT"
git -C "$ROOT" archive "$REV" "${SHIP[@]}" | tar -x -C "$OUT"
printf '%s\n' '# shinyapps.io runs the app at the bundle ROOT; the app lives in app/ and reads the repo root.' \
              'shiny::shinyAppDir("app")' > "$OUT/app.R"
# The bundle has no .git, so the commit is written down for ccx_git_stamp() (R/provenance.R), which
# reads this file's first line: the CSV downloads print it (app/R/downloads.R, 2026-10-20).
git -C "$ROOT" rev-parse "$REV" > "$OUT/FROZEN_FROM_COMMIT.txt"
echo "bundle: $OUT  (commit $(git -C "$ROOT" rev-parse --short "$REV"); mode file $MODE)"
echo "files: $(find "$OUT" -type f | wc -l | tr -d ' ')  size: $(du -sh "$OUT" | cut -f1)"
