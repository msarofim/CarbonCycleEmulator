# =====================================================================
# diag_mode_streams_provenance.R -- IS THE CANONICAL MODE FILE'S STORED
# `streams` DECOMPOSITION THE ONE ITS OWN `logpost` WAS BUILT FROM?
#
# WHY THIS EXISTS. The 2026-09-09t whole-model review (§10 item 6) reported the
# canonical mode file's stored stream decomposition as "4.75 log-units short of
# its own stored logpost", on a wrong stream set: `d14c_deep_ocean` present, the
# `d14c_profile_*` rows absent. The 09-09v handoff pushed back -- it measured the
# 23 stored rows at -1434.670 against a stored logpost of -1478.660 and called
# the 43.99 gap "the log-prior, as expected". ⛔ THAT GAP WAS NEVER COMPUTED.
# It was inferred from its plausible size ([[derived_must_mean_computed]]), and
# the log-prior at this mode is -39.235, not 43.99.
#
# WHAT THE ANSWER TURNS ON, AND WHY IT IS NOT COSMETIC. Two readings fit the
# same file and they have opposite consequences:
#   (a) logprior == 43.99  =>  the stored logpost was built from the STORED
#       stream set, i.e. the refit ran under an objective this build no longer
#       has. The mode is then not a mode of this space and a REFIT is owed.
#   (b) logprior == 39.23  =>  the stored logpost is TODAY'S objective and is
#       valid; only the `streams` FIELD is a stale reporting artifact, repairable
#       in place by the existing calibration/repair_arm_streams.R contract.
# The prior leg of `ccx_make_logpost()` is a pure function of `u` and
# `CCX_PARAM_TABLE`, so (a) vs (b) is settled WITHOUT running the model.
#
# ⭐ AND IT NAMES A SILENT GATE. `diag_adoption_read_hilda31.R:29` gates the
# file's streams against a recomputation -- but it `intersect()`s the name sets
# first and only `cat()`s the leftovers, so a file MISSING a row and carrying a
# retired one in its place PASSES on `max|diff|`. This script asserts on the
# NAME SET, and mutation-tests that assertion.
#
# Reads only. Adopts nothing, repairs nothing, writes one .rds under
# outputs/diagnostics/. Usage: Rscript calibration/diag_mode_streams_provenance.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)

# ---- named constants: every label below derives from these ----------
MS_MODE      <- CCX_MODE_CANONICAL
MS_RECOMP    <- ccx_path("outputs", "diagnostics",
                         "adoption_read_hilda31_20260908.rds")
MS_OUT       <- ccx_path("outputs", "diagnostics",
                         "mode_streams_provenance_20260909.rds")
MS_TOL_ROW   <- 1e-6    # per-row agreement on the COMMON rows
MS_TOL_RECON <- 1e-4    # logpost - logprior vs a candidate loglik

md <- readRDS(ccx_mode_file(MS_MODE))
cat(sprintf("MODE %s (%d par, struct '%s')\n  %s\n",
            MS_MODE, length(md$param_names), ccx_mode_struct(md),
            ccx_mode_file(MS_MODE)))

# ---- 1. the log-prior, COMPUTED --------------------------------------
# Same three lines as ccx_make_logpost()'s prior leg; it is not exported, and a
# second copy of a scoring rule is the caption-sync bug class, so this one is
# gated against the objective's own total below rather than trusted on sight.
ms_logprior <- function(u) {
  names(u) <- CCX_PARAM_NAMES
  pv <- ccx_unc_to_par(u)
  lp <- 0
  for (n in CCX_PARAM_NAMES) {
    s <- CCX_PARAM_TABLE[[n]]
    lp <- lp + s$prior(pv[[n]]) + .log_jac(u[[n]], s)
  }
  lp
}
if (!identical(md$param_names, CCX_PARAM_NAMES))
  stop("this mode file was fitted on a DIFFERENT parameter set (",
       length(md$param_names), " vs ", length(CCX_PARAM_NAMES),
       "); the question this script asks is not answerable against it.")
ccx_check_mode_decode(md)

lp_shipped <- ms_logprior(md$u_mode)
old_band <- ccx_adopt_mode_band(md)     # h_ml / kz bands as the refit ran them
lp_band <- ms_logprior(md$u_mode)
cat(sprintf("\n== 1. the log-prior, COMPUTED ==\n  shipped table %.6f | mode's own bands %.6f (recorded: %s)\n",
            lp_shipped, lp_band,
            paste(names(ccx_mode_bands(md)), collapse = ", ")))
ll_implied <- md$logpost - lp_band
cat(sprintf("  stored logpost %.6f  ->  the loglik it implies = %.6f\n",
            md$logpost, ll_implied))

# ---- 2. the two candidate stream sets ---------------------------------
fil <- unlist(md$streams)
rec <- unlist(readRDS(MS_RECOMP)$new$streams)
cat(sprintf("\n== 2. the two candidate decompositions ==\n  FILE       %2d rows, sum %.6f  (gap to implied loglik %+.6f)\n  RECOMPUTED %2d rows, sum %.6f  (gap to implied loglik %+.6f)\n",
            length(fil), sum(fil), sum(fil) - ll_implied,
            length(rec), sum(rec), sum(rec) - ll_implied))
only_rec <- setdiff(names(rec), names(fil))
only_fil <- setdiff(names(fil), names(rec))
cat(sprintf("  in RECOMPUTED only: %s (%.4f)\n  in FILE only      : %s (%.4f)\n",
            paste(only_rec, collapse = " "), sum(rec[only_rec]),
            paste(only_fil, collapse = " "), sum(fil[only_fil])))
common <- intersect(names(rec), names(fil))
worst  <- max(abs(rec[common] - fil[common]))
cat(sprintf("  the %d COMMON rows agree to %.2e -- the model and the other %d terms are identical\n",
            length(common), worst, length(common)))
stopifnot(worst < MS_TOL_ROW)

# ---- 3. THE VERDICT ----------------------------------------------------
recon_file <- abs(sum(fil) - ll_implied) < MS_TOL_RECON
recon_rec  <- abs(sum(rec) - ll_implied) < MS_TOL_RECON
cat("\n== 3. verdict ==\n")
if (recon_rec && !recon_file) {
  cat(sprintf("  ✅ THE STORED logpost IS TODAY'S OBJECTIVE. logpost - logprior reproduces the\n     RECOMPUTED sum to %.2e. The mode is a mode of this space; NO REFIT IS OWED.\n",
              abs(sum(rec) - ll_implied)))
  cat(sprintf("  ⛔ THE STORED `streams` FIELD IS STALE by %.4f log-units: it carries the retired\n     `%s` row where the objective scored %s.\n     Repairable in place by calibration/repair_arm_streams.R's contract\n     (streams / streams_as_fitted / streams_provenance). ONE vintage, not two --\n     unlike the 2026-08-22 repair, the logpost here needs no caveat.\n",
              sum(rec) - sum(fil), paste(only_fil, collapse = " "),
              paste(only_rec, collapse = " ")))
} else if (recon_file && !recon_rec) {
  cat("  ⛔ THE STORED logpost WAS BUILT FROM THE STORED STREAM SET -- the refit ran under\n     an objective this build no longer has. A REFIT IS OWED; this is not a reporting bug.\n")
} else {
  cat(sprintf("  ⚠ NEITHER candidate reconciles (file %+.4f, recomputed %+.4f). A third\n     objective vintage is in play; do not price anything on this file.\n",
              sum(fil) - ll_implied, sum(rec) - ll_implied))
}

# ---- 4. the SILENT GATE, named and MUTATION-TESTED ---------------------
# The adoption diagnostic's provenance gate compares only intersect(names) and
# reports max|diff|. Under exactly the defect above it returns 1.4e-10 and PASSES.
cat("\n== 4. the gate that should have caught this ==\n")
gate_intersect <- function(a, b) { k <- intersect(names(a), names(b))
                                   max(abs(a[k] - b[k])) < MS_TOL_ROW }
gate_nameset   <- function(a, b) setequal(names(a), names(b)) &&
                                   max(abs(a[names(b)] - b)) < MS_TOL_ROW
cat(sprintf("  intersect-gate on the LIVE defect : %s  <- SILENT\n",
            if (gate_intersect(rec, fil)) "PASS" else "FAIL"))
cat(sprintf("  name-set  gate on the LIVE defect : %s\n",
            if (gate_nameset(rec, fil)) "PASS" else "FAIL"))
# MUTATION TEST: the name-set gate must PASS on an honest pair and FAIL on a
# broken one, or it is not a gate ([[mutation_test_gates]]).
mut_drop <- rec[setdiff(names(rec), only_rec[1])]
mut_move <- rec; mut_move[[1]] <- mut_move[[1]] + 1
cat(sprintf("  MUTATION  identity pair  -> %s (want PASS)\n",
            if (gate_nameset(rec, rec)) "PASS" else "FAIL"))
cat(sprintf("  MUTATION  a row DELETED  -> %s (want FAIL)\n",
            if (gate_nameset(rec, mut_drop)) "PASS" else "FAIL"))
cat(sprintf("  MUTATION  a row MOVED +1 -> %s (want FAIL)\n",
            if (gate_nameset(rec, mut_move)) "PASS" else "FAIL"))
stopifnot(gate_nameset(rec, rec), !gate_nameset(rec, mut_drop),
          !gate_nameset(rec, mut_move), !gate_nameset(rec, fil),
          gate_intersect(rec, fil))   # the silent gate's silence, asserted

saveRDS(list(mode = MS_MODE, file = ccx_mode_file(MS_MODE),
             logpost = md$logpost, logprior = lp_band,
             loglik_implied = ll_implied,
             streams_file = fil, streams_recomputed = rec,
             only_in_file = only_fil, only_in_recomputed = only_rec,
             stale_by = sum(rec) - sum(fil),
             reconciles = c(file = recon_file, recomputed = recon_rec),
             measured_on = as.character(Sys.Date()),
             commit = tryCatch(system("git rev-parse --short HEAD", intern = TRUE),
                               error = function(e) NA_character_)), MS_OUT)
cat(sprintf("\n  saved %s\n  ⛔ Reads only: no prior moved, no constant changed, no artifact repaired.\n",
            MS_OUT))
