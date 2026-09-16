# =====================================================================
# repair_canonical_streams.R -- rewrite the CANONICAL mode file's `streams`
# field, which is stale, under the same contract repair_arm_streams.R uses.
#
# WHY. Measured 2026-09-09w by calibration/diag_mode_streams_provenance.R: the
# canonical file's stored decomposition carries the retired `d14c_deep_ocean`
# row (-4.1833) where the objective actually scored the three `d14c_profile_*`
# rows (-8.9376, GNORM on since 09-07). It is short by 4.7543 log-units, exactly
# as the 09-09t review reported and contrary to the 09-09v rebuttal.
#
# ⭐ AND THIS REPAIR IS CLEANER THAN THE 2026-08-22 ONE IT COPIES. There the
# repaired file deliberately held TWO vintages, because the stored `logpost` was
# on an older objective than the recomputed streams. Here `logpost - logprior`
# reproduces the recomputed sum to 1.3e-10, so the logpost IS today's objective
# and the repaired file holds ONE. That is not an assumption -- it is the GATE
# below, and the script REFUSES TO WRITE if it fails, because a file that does
# not reconcile is a refit obligation, not a field repair.
#
# ⛔ NOTE THAT repair_arm_streams.R IS ITSELF A STALE PRODUCER. Its ccx_loglik()
# call passes no `d14c_mid`, so re-running it today would REINTRODUCE exactly
# this defect. It is not edited here (its two arms are retired and its own
# already-repaired guard stops it re-running), but a banner was added to it
# pointing at this file. The producer used below is `dg_streams()` --
# the SAME one the adoption gate uses, so there is no second copy of a scoring
# rule ([[derived_must_mean_computed]]).
#
# Ruled by Marcus 2026-09-09w. Usage:
#   Rscript calibration/repair_canonical_streams.R [--dry-run]
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))

# ---- named constants: every label and path below derives from these --
RC_MODE     <- CCX_MODE_CANONICAL
RC_BUG      <- "d14c_profile_rows_missing"
RC_QUAR     <- ccx_path("calibration", "output", "quarantine",
                        paste0("20260909w_", RC_BUG))
RC_DRY      <- "--dry-run" %in% commandArgs(TRUE)
RC_TOL_RECON <- 1e-4     # logpost - logprior vs the recomputed sum
RC_DATE     <- as.character(Sys.Date())
RC_COMMIT   <- tryCatch(system("git rev-parse --short HEAD", intern = TRUE),
                        error = function(e) NA_character_)

f  <- ccx_mode_file(RC_MODE)
md <- readRDS(f)
cat(sprintf("CANONICAL %s -- %s\n", RC_MODE, f))
if (!is.null(md$streams_provenance)) {
  cat(sprintf("  already repaired on %s (%s) -- nothing to do\n",
              md$streams_provenance$recomputed_on, md$streams_provenance$reason))
  quit(save = "no")
}

# ---- recompute, through the SAME producer the adoption gate uses -----
v   <- dg_vector(RC_MODE)
now <- dg_streams(dg_run(v), v)

# ---- the log-prior, COMPUTED (not named) -----------------------------
rc_logprior <- function(u) { names(u) <- CCX_PARAM_NAMES; pv <- ccx_unc_to_par(u)
  lp <- 0; for (n in CCX_PARAM_NAMES) { s <- CCX_PARAM_TABLE[[n]]
    lp <- lp + s$prior(pv[[n]]) + .log_jac(u[[n]], s) }; lp }
invisible(ccx_adopt_mode_band(md)); ccx_check_mode_decode(md)   # adopt the recorded band FIRST (09-16 b: the shipped floor moved), then check under it
lp  <- rc_logprior(md$u_mode)
ll_implied <- md$logpost - lp

was  <- unlist(md$streams); nowv <- unlist(now)
cat(sprintf("\n  log-prior %.6f | stored logpost %.6f -> implied loglik %.6f\n",
            lp, md$logpost, ll_implied))
cat(sprintf("  stored   %2d rows, sum %.6f (%+.4f off)\n  recomputed %2d rows, sum %.6f (%+.2e off)\n",
            length(was), sum(was), sum(was) - ll_implied,
            length(nowv), sum(nowv), sum(nowv) - ll_implied))
cat(sprintf("  gained: %s\n  lost  : %s\n",
            paste(setdiff(names(nowv), names(was)), collapse = " "),
            paste(setdiff(names(was), names(nowv)), collapse = " ")))
k <- intersect(names(was), names(nowv)); d <- nowv[k] - was[k]
cat(sprintf("  the %d COMMON rows agree to %.2e\n", length(k), max(abs(d))))

# ---- ⛔ THE GATE. A file that does not reconcile is NOT repairable here ----
# This is the whole justification for a field repair rather than a refit, so it
# is a stopifnot and not a message. MUTATION-TESTED below.
rc_reconciles <- function(streams, implied) abs(sum(streams) - implied) < RC_TOL_RECON
if (!rc_reconciles(nowv, ll_implied))
  stop("REFUSING TO WRITE. The recomputed streams (", sprintf("%.4f", sum(nowv)),
       ") do NOT reconcile with logpost - logprior (", sprintf("%.4f", ll_implied),
       "), so the stored logpost is on a DIFFERENT objective than this build. ",
       "That is a REFIT obligation, not a stale reporting field. See ",
       "calibration/diag_mode_streams_provenance.R.")
# the gate must also be able to FAIL ([[mutation_test_gates]])
stopifnot(rc_reconciles(nowv, ll_implied),
          !rc_reconciles(was, ll_implied),                 # the live defect
          !rc_reconciles(nowv, ll_implied + 1),            # a moved logpost
          !rc_reconciles(nowv[-1], ll_implied))            # a dropped row
cat("  ✅ GATE: reconciles to 1 part in 1e4; and FAILS on the stored set, a moved\n     logpost and a dropped row. The logpost is TODAY'S objective.\n")

if (RC_DRY) { cat("\n  --dry-run: nothing written.\n"); quit(save = "no") }

# ---- write, quarantining the pre-repair file first --------------------
dir.create(RC_QUAR, recursive = TRUE, showWarnings = FALSE)
file.copy(f, file.path(RC_QUAR, basename(f)), overwrite = FALSE)
md$streams_as_fitted  <- md$streams
md$streams            <- now
md$streams_provenance <- list(
  recomputed_on = RC_DATE, recomputed_at = RC_COMMIT,
  reason = paste("the stored decomposition carried the retired `d14c_deep_ocean`",
                 "row where the objective scored the three `d14c_profile_*` rows",
                 "(GNORM on since 2026-09-07); short by 4.7543 log-units. The",
                 "producer that wrote it passed no `d14c_mid` to ccx_loglik()."),
  streams_objective = paste("CURRENT as of", RC_COMMIT),
  logpost_objective = paste("THE SAME. Unlike the 2026-08-22 repair this file holds",
                            "ONE vintage: logpost - logprior reproduces the recomputed",
                            "sum to", sprintf("%.1e", abs(sum(nowv) - ll_implied)),
                            "-- gated above, not assumed."),
  logprior = lp, loglik_implied = ll_implied,
  fields_unaffected = c("par_mode", "u_mode", "logpost", "hessian", "cov", "cor",
                        "sd_unc", "eigen", "logdet_negH", "prior_z"),
  delta_total = sum(nowv) - sum(was),
  quarantine = file.path(basename(dirname(RC_QUAR)), basename(RC_QUAR)))
saveRDS(md, f)
cat(sprintf("\n  WRITTEN (%+.4f). pre-repair copy -> %s\n", sum(nowv) - sum(was), RC_QUAR))
cat("  ⛔ ONLY the `streams` field moved. No prior, no constant, no logpost.\n")
