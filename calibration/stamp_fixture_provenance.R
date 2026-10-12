#!/usr/bin/env Rscript
# =====================================================================
# calibration/stamp_fixture_provenance.R -- ONE-OFF (2026-10-12, CHANGELOG 2026-10-12 (a)).
# Five test fixtures in outputs/diagnostics/ were saved with NO provenance of their own (found by the
# 2026-10-11 (c) adoption audit): seas_ml_hemisphere_split_20260919, hilda28_basins_20260907,
# alignment_screen_d2ret_20260930, tau_soil_slow_profile_fixedstock_stock8053_20260929 and
# kz_bracket_hilda36_20260906. This attaches attr(x, "provenance") to each, built from its companion log
# and git history -- nothing is re-computed, and every stamp says it was made POST HOC, not by the driver.
# No file's md5 was recorded anywhere before (searched: every text file and 2488 .rds provenance blocks),
# so no receipt breaks; the old md5 is kept in the stamp as md5_before.
# ⛔ REFUSES a file that already carries a provenance attribute, so a second run changes nothing.
# Usage (repo root): Rscript calibration/stamp_fixture_provenance.R
# =====================================================================
STAMP_SRC <- paste("stamped POST HOC on 2026-10-12 by calibration/stamp_fixture_provenance.R (CHANGELOG 2026-10-12 (a)) from the",
                   "companion log and git history;",
                   "NOT written by the driver. The values are untouched: identical() to the unstamped object once this",
                   "attribute is removed. md5_before is the file's md5 before the stamp.")
RNG_NOTE  <- "none: the driver makes no RNG call (checked at HEAD and at the commit named here)"
D <- "outputs/diagnostics"
SPECS <- list(
  seas_ml_hemisphere_split_20260919 = list(
    driver = "calibration/diag_seas_ml_hemisphere_split.R", run = "2026-09-19 14:18:21 (log header)",
    commit = NA_character_,
    commit_note = paste("not recorded by the driver. The driver and this file were first committed together in f791a0d",
                        "(2026-09-19 14:19), so the run was on that commit's driver, uncommitted."),
    arms = paste("canonical hilda30e (ML on, shim pinned); fp1 = test (a) id 18 (ML on, shim free); control hilda31pe",
                 "(ML off) -- per the log header. hilda30e is QUARANTINED (CCX_MODE_HILDA30E_QUARANTINED)."),
    log = file.path(D, "seas_ml_hemisphere_split_20260919.log")),
  hilda28_basins_20260907 = list(
    driver = "calibration/diag_hilda28_basins.R", run = "2026-09-07 (the committing commit's date; the log has no time)",
    commit = NA_character_,
    commit_note = paste("not recorded by the driver. The driver and this file were first committed together in 5d6054c",
                        "(2026-09-07 08:06), so the run was on that commit's driver, uncommitted."),
    arms = paste("the HILDA refit (job 17072999, 28 parameters): the best start of each of its 10 basins (`fam`), and",
                 "ent26, the column control (CCX_MODE_COLUMN_CONTROL), scored the same way (`ent26`) -- per the log's",
                 "table and the driver's saveRDS"),
    log = file.path(D, "diag_hilda28_basins_20260907.log")),
  alignment_screen_d2ret_20260930 = list(
    driver = "calibration/diag_alignment_screen.R", run = "2026-09-30 16:21 (log header)",
    commit = "58cd91c", commit_note = "as printed in the log's PROVENANCE line; the driver did not save it into the rds",
    arms = paste("structure hilda_csl3v0kai (inert pool f 0.194684) at v0k basin 1; control = the",
                 "tau_soil_slow_profile_fixedstock_stock8053_20260929 value-500 row, rescored under the label"),
    log = file.path(D, "alignment_screen_d2ret_20260930.log")),
  tau_soil_slow_profile_fixedstock_stock8053_20260929 = list(
    driver = "calibration/diag_tau_soil_slow_profile.R", run = "2026-09-29 21:06 (log header)",
    commit = "965cc73", commit_note = "as printed in the log's PROVENANCE line; the driver did not save it into the rds",
    arms = paste("structure hilda_csl3v0ka at v0k basin 1, 11 names at the npp0_scan_20260929.csv scale-1 optimum;",
                 "FIXED STOCK; passive stock x0.8053 (1208 GtC); tau_soil_slow in {500, 1000, 2000} yr"),
    log = file.path(D, "tau_soil_slow_profile_fixedstock_stock8053_20260929.log")),
  kz_bracket_hilda36_20260906 = list(
    driver = "calibration/diag_kz_bracket_hilda36.R", run = "2026-09-06 (the committing commit's date; the log has no time)",
    commit = NA_character_,
    commit_note = paste("not recorded by the driver. The driver and this file were first committed together in ce3d20b",
                        "(2026-09-06 17:42), so the run was on that commit's driver, uncommitted."),
    arms = paste("NO fitted mode: default parameters on the declared 36-box structure (f 0.050, hs_asx 1.00, z_K 253,",
                 "attach 1), kz bracketed against the target -175.26 +/- 10.26; the run's p0 is stored in `p0`"),
    log = file.path(D, "diag_kz_bracket_hilda36_20260906.log"))
)
for (nm in names(SPECS)) {
  f <- file.path(D, paste0(nm, ".rds")); s <- SPECS[[nm]]
  stopifnot(file.exists(f), file.exists(s$log))
  bytes0 <- readBin(f, "raw", file.size(f)); md5_0 <- unname(tools::md5sum(f))
  x0 <- readRDS(f)
  if (!is.null(attr(x0, "provenance"))) stop(nm, " already carries a provenance attribute: not overwriting it")
  x <- x0
  attr(x, "provenance") <- c(list(tag = nm), s, list(rng = RNG_NOTE, md5_before = md5_0, stamp = STAMP_SRC))
  saveRDS(x, f)
  y <- readRDS(f); p <- attr(y, "provenance"); attr(y, "provenance") <- NULL
  if (!identical(y, x0) || !identical(p$md5_before, md5_0)) {
    writeBin(bytes0, f); stop(nm, ": the stamped file is NOT identical to the original once unstamped -- restored")
  }
  cat(sprintf("%-55s stamped; values identical(); md5 %s -> %s\n", nm, md5_0, unname(tools::md5sum(f))))
}
