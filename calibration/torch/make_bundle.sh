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
# ⚠ `data-raw/downloads/nuclear14c` IS NOT OPTIONAL, and it is 428 KB of the
# 3.4 GB tree. `ccx_nuclear_c14_annual()` reads it AT RUN TIME through a default
# argument and, when it is absent, WARNS and sets the industrial 14C source to
# zero -- a different objective, ~1e-3 relative, with no error. Omitting it is
# how the 2026-09-01 port gate came to fail on a machine that was fine.
# Everything in calibration/lib_run_inputs.R's manifest must be listed here.
tar czf "$OUT" \
  DESIGN.md CLAUDE.md README.md DATA.md \
  R src data tests \
  data-raw/downloads/nuclear14c \
  calibration/*.R calibration/torch \
  calibration/output/refit_20260910_hilda31_periodic \
  calibration/output/quarantine/20260910_periodic_spinup_adopted
echo "bundle: $OUT  ($(du -h "$OUT" | cut -f1))"
echo
echo "  scp $OUT torch:/scratch/ms17839/"
echo "  ssh torch 'mkdir -p /scratch/ms17839/CarbonCycleEmulator && \\"
echo "             tar xzf /scratch/ms17839/ccx_torch_bundle.tar.gz \\"
echo "                 -C /scratch/ms17839/CarbonCycleEmulator && \\"
echo "             rm /scratch/ms17839/ccx_torch_bundle.tar.gz'"
