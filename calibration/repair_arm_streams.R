# =====================================================================
# repair_arm_streams.R -- rewrite the `streams` field of mode_fit_pump{N,D}.rds.
#
# WHY. `run_modefind_pump_arms.R:452` applied `luc_scale` TWICE to the
# gross-land-sink reconstruction when it stored the per-stream decomposition
# (fixed 2026-08-22). `ccx_make_logpost()` never had the bug, so **the fits
# themselves are sound** -- `par_mode`, `logpost`, `hessian`, `cov`, `eigen` and
# every evidence number stand. What was wrong is the only per-stream table the
# project has, which is what handoffs rank work from. Arm N's `gcb_land_sink`
# read -93.71 where the truth is -95.62.
#
# WHAT THIS WRITES, AND THE HONEST CAVEAT THAT RIDES WITH IT. The recomputed
# streams are on **today's** objective, which since `d6adb58` scores the ice term
# against `co2_SH`. The stored `logpost` is on the objective in force when the
# arm was fitted. **So after this repair the file deliberately holds two
# vintages, and says so in `streams_provenance` rather than leaving a reader to
# discover it.** They reconcile when the owed refit runs; until then:
#     streams            -- this par_mode, scored under TODAY'S objective
#     streams_as_fitted   -- exactly what the refit stored (luc_scale SQUARED)
#     streams_provenance  -- dates, commit, and which fields are which vintage
# Nothing is deleted. The pre-repair files are copied to
# calibration/output/quarantine/20260822_luc_scale_squared_streams/ first, per
# the standing quarantine convention.
#
# ARM D IS REPAIRED BUT STILL NOT COMPARABLE TO ARM N. It was last fitted before
# the 2026-08-20g CCX_SST_SEAS_LAG correction (both refit_20260820.log and
# refit_20260821_cont.log read "REFIT, 1 ARM(S) [N]"), so its recomputed streams
# differ from its as-fitted ones by ~-8244 log-units, dominated by
# co2_seasonal_MLO. Repairing the luc term does not make the arms like-for-like.
#
# ⛔⛔ THIS SCRIPT IS ITSELF A STALE PRODUCER (found 2026-09-09w). Its ccx_loglik()
# call below passes NO `d14c_mid`, so it reproduces the PRE-PROFILE decomposition:
# `d14c_deep_ocean` where today's objective scores three `d14c_profile_*` rows (GNORM
# on since 2026-09-07). Re-running it would REINTRODUCE, on whatever file it touched,
# exactly the defect that `calibration/repair_canonical_streams.R` was written to undo.
# It is left unedited because both its arms are RETIRED and its own already-repaired
# guard stops it re-running. ⭐ If you ever need it again, take the producer from
# `dg_streams()` (calibration/lib_design_gates.R) -- the SAME one the adoption gate
# uses -- rather than the call below.
#
# Usage:  Rscript calibration/repair_arm_streams.R [--dry-run]
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

RS_ARMS  <- c("N", "D")
RS_DIR   <- ccx_path("calibration", "output", "pump_arms")
RS_QUAR  <- ccx_path("calibration", "output", "quarantine",
                     "20260822_luc_scale_squared_streams")
RS_DRY   <- "--dry-run" %in% commandArgs(TRUE)
RS_COMMIT <- tryCatch(system("git rev-parse --short HEAD", intern = TRUE),
                      error = function(e) NA_character_)
RS_DATE  <- as.character(Sys.Date())

if (!RS_DRY) dir.create(RS_QUAR, recursive = TRUE, showWarnings = FALSE)

for (arm in RS_ARMS) {
  f <- file.path(RS_DIR, sprintf("mode_fit_pump%s.rds", arm))
  if (!file.exists(f)) { cat("absent, skipped:", basename(f), "\n"); next }
  md <- readRDS(f)
  if (!is.null(md$streams_provenance)) {
    cat(sprintf("arm %s already repaired on %s -- skipped\n",
                arm, md$streams_provenance$recomputed_on)); next
  }

  M  <- ccx_load_mode(f)
  sp <- ccx_spinup(M$p)
  SF <- ccx_scaled_forcing(sp, years = c(1750, 2024),
                           luc_scale = M$luc_scale, bomb_total = M$bomb_total)
  o  <- ccx_run_fast(sp, SF$F)$out
  now <- ccx_loglik(o, ccx_prepare_obs(), M$err, luc = SF$eluc,
                    deep = sp$diagnostics$d14c_bottom_box,
                    ocean_grad = ccx_ocean_grad_scored(o, sp), by_stream = TRUE)

  was <- unlist(md$streams); nowv <- unlist(now)
  k <- intersect(names(was), names(nowv)); d <- nowv[k] - was[k]
  cat(sprintf("\n=== arm %s ===\n  stored sum %.1f -> recomputed %.1f (%+.1f)\n",
              arm, sum(was[k]), sum(nowv[k]), sum(d)))
  for (nm in names(sort(abs(d[abs(d) > 0.05]), decreasing = TRUE)))
    cat(sprintf("    %-20s %+12.2f\n", nm, d[[nm]]))

  if (RS_DRY) next
  file.copy(f, file.path(RS_QUAR, basename(f)), overwrite = FALSE)
  md$streams_as_fitted  <- md$streams
  md$streams            <- now
  md$streams_provenance <- list(
    recomputed_on   = RS_DATE,
    recomputed_at   = RS_COMMIT,
    reason          = paste("run_modefind_pump_arms.R:452 applied luc_scale twice to the",
                            "gross-land-sink reconstruction; fixed 2026-08-22."),
    streams_objective  = paste("CURRENT as of", RS_COMMIT, "- ice term scores co2_SH (d6adb58)."),
    logpost_objective  = paste("AS FITTED - pre-d6adb58 for both arms (ice scored co2_NH),",
                               "and for arm D also pre-2026-08-20g CCX_SST_SEAS_LAG."),
    fields_unaffected  = c("par_mode", "u_mode", "logpost", "hessian", "cov", "cor",
                           "sd_unc", "eigen", "logdet_negH"),
    delta_total     = sum(d),
    quarantine      = file.path(basename(dirname(RS_QUAR)), basename(RS_QUAR)))
  saveRDS(md, f)
  cat(sprintf("  WRITTEN. pre-repair copy -> %s\n", RS_QUAR))
}
