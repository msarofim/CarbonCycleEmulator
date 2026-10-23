# =====================================================================
# make_flask_file_starts.R -- write the FILE STARTS of the flask refit (refit item 2, 2026-10-23; handoff
# notes/handoff_2026-10-23_flask_refit_item2.md §3): T8c's block point and T8f's Newton point, read out of T8f's output
# together with the values T8f scored there. The canonical, the refit's third start, is already id 1 (the incumbent of
# ccx_ms_reference_set()'s flask branch) and is not in this file.
#
# Rulings (Marcus 2026-10-22): "Local refit from T8c's point (Recommended)"; "Add it as a third (Recommended)" (T8f's
# Newton point); "Carry module, then check (Recommended)" (the canonical's pins, the interannual module's four included).
#
# ⭐ THE TARGETS ARE T8f's, NOT THIS SCRIPT'S. No model is run here. Each start's `logpost` is what T8f's override objective
# (calibration/lib_seas8_20261021.R, an independent implementation) scored at that point; test-flask-label.R shows the
# label reproduces it to 1e-8, and the driver's FILE-START GATE checks its own objective against it before any budget is
# spent ([[gate_reads_its_own_output]]).
# The label fields are the arm the run uses: CCX_MODE_FLASK_STRUCT, the canonical's seas_ml and pump field, and
# CCX_MODE_FLASK_PINS. The file is checked with the driver's own reader (ms_read_file_starts()) under that arm before it
# is written.
#
# Output: calibration/torch/file_starts_<label>.rds (TRACKED, and shipped by make_bundle.sh with calibration/torch).
# Usage:  Rscript calibration/make_flask_file_starts.R        # < 2 s
#         then CCX_MS_FILE_STARTS=calibration/torch/file_starts_hilda_csl3v0kaidgbemwtcf.rds for the run (ids 6, 7)
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
source(ccx_path("calibration", "lib_ms_file.R"))

FS_T8F    <- file.path("outputs", "diagnostics", "seas8_20261021_hilda31w", "t8f_allflask_forecast_hilda31w.rds")
FS_OUT    <- file.path("calibration", "torch", paste0("file_starts_", CCX_MODE_FLASK_STRUCT, ".rds"))
FS_SLOTS  <- 4L   # the driver's length(MS_FILE_IDS); the reader only needs an upper bound here
FS_COMMIT <- ccx_git_stamp(exclude = FS_OUT)   # the starts file is this script's product, not an input

T8F <- readRDS(ccx_path(FS_T8F))
md_file <- ccx_mode_file(CCX_MODE_FLASK_INCUMBENT)
md <- readRDS(md_file)
# T8f was computed at THIS canonical file, with every MLO CO2 row on flask (both of its overrides): the flask label's scope
if (!identical(T8F$provenance$mode, CCX_MODE_FLASK_INCUMBENT) ||
    !identical(T8F$provenance$mode_md5, unname(tools::md5sum(md_file))))
  stop("T8f was computed at ", T8F$provenance$mode, " (md5 ", T8F$provenance$mode_md5, "), not at ",
       CCX_MODE_FLASK_INCUMBENT, "'s file as it is now (", md_file, "). Its points belong to another start.")
if (!identical(c(T8F$provenance$co2seas, T8F$provenance$co2level), rep(LIK_CO2_FLASK_STATION, 2)))
  stop("T8f's overrides are ", T8F$provenance$co2seas, " / ", T8F$provenance$co2level, ", not ",
       LIK_CO2_FLASK_STATION, " on both: not the flask label's objective.")

starts <- list(
  t8c_block = list(
    u = T8F$points$uB, logpost = T8F$forecast$block$base,
    source = sprintf("T8c's block point (%s: $points$uB; logpost $forecast$block$base; T8f @%s)",
                     FS_T8F, T8F$provenance$commit)),
  t8f_newton = list(
    u = T8F$points$uN_all, logpost = sum(T8F$rows$all_at_allN),
    source = sprintf("T8f's Newton point (%s: $points$uN_all; logpost sum($rows$all_at_allN); T8f @%s)",
                     FS_T8F, T8F$provenance$commit)))
out <- list(
  starts = starts,
  struct = CCX_MODE_FLASK_STRUCT, seas_ml = ccx_mode_seas_ml(md), pump_field = ccx_mode_pump_field(md),
  pins = CCX_MODE_FLASK_PINS,
  provenance = list(
    builder = "calibration/make_flask_file_starts.R", commit = FS_COMMIT,
    built = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
    from = FS_T8F, from_md5 = unname(tools::md5sum(ccx_path(FS_T8F))),
    from_driver = T8F$provenance$driver, from_commit = T8F$provenance$commit,
    canonical = CCX_MODE_FLASK_INCUMBENT, canonical_md5 = T8F$provenance$mode_md5,
    rulings = c("Local refit from T8c's point (Recommended)", "Add it as a third (Recommended)",
                "Carry module, then check (Recommended)"),
    units = "u: the unconstrained coordinate of CCX_PARAM_TABLE; logpost: log-units",
    rng = "none"))

# the driver's own reader, under the arm the run fits (the gate, then the pins), before anything is written
tmp <- tempfile(fileext = ".rds"); saveRDS(out, tmp)
g <- ccx_apply_gate(CCX_MODE_FLASK_STRUCT); h <- ccx_apply_pins(CCX_MODE_FLASK_PINS)
chk <- tryCatch(ms_read_file_starts(tmp, FS_SLOTS,
                                    list(struct = CCX_MODE_FLASK_STRUCT, seas_ml = ccx_mode_seas_ml(md),
                                         pump_field = ccx_mode_pump_field(md), pins = CCX_MODE_FLASK_PINS),
                                    CCX_PARAM_NAMES),
                finally = { ccx_unpin_params(h); ccx_unapply_gate(g) })
saveRDS(out, ccx_path(FS_OUT))
cat(sprintf("file starts for the flask refit -> %s (md5 %s)\n", FS_OUT, unname(tools::md5sum(ccx_path(FS_OUT)))))
for (k in seq_along(chk))
  cat(sprintf("  slot file%d (the driver's MS_FILE_IDS[%d]): '%s', %d names, logpost %.6f\n    %s\n", k, k, chk[[k]]$name,
              length(chk[[k]]$u), chk[[k]]$logpost, chk[[k]]$source))
cat(sprintf("  label %s, seas_ml %d, pump field %s, pins %s; built at %s from %s (md5 %s)\n", out$struct, out$seas_ml,
            out$pump_field, ccx_pin_label(out$pins), FS_COMMIT, FS_T8F, out$provenance$from_md5))
