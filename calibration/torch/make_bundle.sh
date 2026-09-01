#!/bin/bash
# =====================================================================
# make_bundle.sh -- build the tarball to ship to Torch. Run ON THE MAC.
#
# ⛔ EXCLUDES data-raw/ (3.4 GB of provenance the model never reads at run time)
# and .git/ (56 MB). What is left is ~10 MB: one scp, one Duo prompt.
# The skill's rule is tarball-not-rsync above ~1,000 files or ~500 MB; this is
# under both, but it is still ONE transfer instead of several.
#
# DESIGN.md IS NOT OPTIONAL -- it is REPO_MARKER in R/paths.R, and without it
# ccx_root() cannot resolve a single data path.
# =====================================================================
set -euo pipefail
cd "$(dirname "$0")/../.."
OUT=/tmp/ccx_torch_bundle.tar.gz
tar czf "$OUT" \
  DESIGN.md CLAUDE.md README.md DATA.md \
  R src data tests \
  calibration/*.R calibration/torch \
  calibration/output/refit_20260831_seas_lag_split \
  calibration/output/polish_20260831_probe_basin
echo "bundle: $OUT  ($(du -h "$OUT" | cut -f1))"
echo
echo "  scp $OUT torch:/scratch/ms17839/"
echo "  ssh torch 'mkdir -p /scratch/ms17839/CarbonCycleEmulator && \\"
echo "             tar xzf /scratch/ms17839/ccx_torch_bundle.tar.gz \\"
echo "                 -C /scratch/ms17839/CarbonCycleEmulator && \\"
echo "             rm /scratch/ms17839/ccx_torch_bundle.tar.gz'"
