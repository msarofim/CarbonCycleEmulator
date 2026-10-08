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
rm -f "$OUT"     # never ship a stale tarball
# assert every registry-named mode file exists (they are listed below by hand)
Rscript --vanilla -e 'for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
  fs <- c(unname(CCX_MODE_FILES), CCX_MODE_COLUMN_CONTROL, CCX_MODE_HILDA31_QUARANTINED, CCX_MODE_HILDA31S_QUARANTINED, CCX_MODE_HILDA30C_QUARANTINED, CCX_MODE_HILDA30H_QUARANTINED, CCX_MODE_HILDA31P_QUARANTINED, CCX_MODE_HILDA30E_QUARANTINED, CCX_MODE_HILDA30S_QUARANTINED)
  miss <- fs[!file.exists(fs)]; if (length(miss)) stop("registry names missing files: ", paste(miss, collapse = ", "))
  cat("registry files present:", length(fs), "\n")' 
# ⚠ `data-raw/downloads/nuclear14c` IS NOT OPTIONAL, and it is 428 KB of the
# 3.4 GB tree. `ccx_nuclear_c14_annual()` reads it AT RUN TIME through a default
# argument and, when it is absent, WARNS and sets the industrial 14C source to
# zero -- a different objective, ~1e-3 relative, with no error. Omitting it is
# how the 2026-09-01 port gate came to fail on a machine that was fine.
# Everything in calibration/lib_run_inputs.R's manifest must be listed here.
# ⛔ AND EVERY MODE FILE R/paths.R NAMES (CCX_MODE_FILES + the *_QUARANTINED paths): a missing
# one makes tar exit non-zero under set -e BEFORE the 'bundle:' line, and a stale tarball at
# /tmp can then be shipped (2026-09-13: the round-7 adoption moved a directory and this list
# was not updated; caught because the incumbent's file was absent on Torch). The check below
# asserts them from the registry rather than trusting this list.
# COPYFILE_DISABLE stops the `._*` AppleDouble files. It does NOT stop the com.apple.provenance
# xattrs, which bsdtar writes as LIBARCHIVE.xattr pax headers, and GNU tar on Torch prints
# "Ignoring unknown extended header keyword" ONCE PER FILE on extract. 480 such lines buried the
# extract's real output on 2026-09-14 (i), and 696 more on 2026-10-01 (p), with COPYFILE_DISABLE
# set. --no-xattrs is what stops them (measured: 17 headers -> 0 on the same members).
COPYFILE_DISABLE=1 tar --no-xattrs -czf "$OUT" \
  DESIGN.md CLAUDE.md README.md DATA.md \
  R src data tests \
  data-raw/downloads/nuclear14c \
  calibration/*.R calibration/torch calibration/mac \
  calibration/output/refit_20261008_hilda29e_obj18p2_hilda_csl3v0kaidgbemwt \
  calibration/output/refit_20261005_hilda33p_obj16_hilda_csl3v0kaidgbem \
  calibration/output/refit_20261003_hilda34g_obj15_hilda_csl3v0kaidgbe \
  calibration/output/refit_20261001_hilda33d_obj14_hilda_csl3v0kaidgb \
  calibration/output/refit_20260920_hilda29l_obj13_hilda_csl3 \
  calibration/output/refit_20260922_hilda32f_obj13_hilda_csl3_free_parent \
  calibration/output/quarantine/20260920_hilda29l_adopted \
  calibration/output/quarantine/20260920_hilda30s_adopted \
  calibration/output/refit_20260919_hilda31pe_obj13_hilda_c_seasml0 \
  calibration/output/refit_20260912_hilda31_seasml1_round7 \
  calibration/output/quarantine/20260919_hilda30e_adopted \
  calibration/output/quarantine/20260917_hilda30h_adopted/refit_20260913_hilda30_cprime_pin_ent0 \
  calibration/output/quarantine/20260910_periodic_spinup_adopted \
  calibration/output/quarantine/20260913_round7_adopted \
  calibration/output/quarantine/20260908_hilda31_adopted/refit_20260903_ent26
# ⛔ THE MEMBERSHIP GATE (2026-09-14 i): the registry check above proves the files exist ON
# THE MAC, not that they are IN the tarball -- and the column control (ent26, quarantined
# 09-08) was absent from this list for six days while that check passed. A gate that reads
# the list it is meant to guard is not a gate; this one reads the tarball.
tar tzf "$OUT" > /tmp/ccx_bundle_list.txt
Rscript --vanilla -e 'for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
  fs <- c(unname(CCX_MODE_FILES), CCX_MODE_COLUMN_CONTROL, CCX_MODE_HILDA31_QUARANTINED, CCX_MODE_HILDA31S_QUARANTINED, CCX_MODE_HILDA30C_QUARANTINED, CCX_MODE_HILDA30H_QUARANTINED, CCX_MODE_HILDA31P_QUARANTINED, CCX_MODE_HILDA30E_QUARANTINED, CCX_MODE_HILDA30S_QUARANTINED)
  inb <- readLines("/tmp/ccx_bundle_list.txt"); miss <- fs[!fs %in% inb]
  if (length(miss)) stop("registry files NOT IN THE TARBALL: ", paste(miss, collapse = ", "))
  cat("registry files in the tarball:", length(fs), "of", length(fs), "\n")'
echo "bundle: $OUT  ($(du -h "$OUT" | cut -f1))"
echo
echo "  scp $OUT torch:/scratch/ms17839/"
echo "  ssh torch 'mkdir -p /scratch/ms17839/CarbonCycleEmulator && \\"
echo "             tar xzf /scratch/ms17839/ccx_torch_bundle.tar.gz \\"
echo "                 -C /scratch/ms17839/CarbonCycleEmulator && \\"
echo "             rm /scratch/ms17839/ccx_torch_bundle.tar.gz'"
