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
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))

# ---- named constants: every label below derives from these ----------
MS_MODE      <- CCX_MODE_CANONICAL
MS_OUT       <- ccx_path("outputs", "diagnostics",
                         "mode_streams_provenance_20260909.rds")
MS_TOL_ROW   <- 1e-6    # per-row agreement on the COMMON rows
MS_TOL_RECON <- 1e-4    # logpost - logprior vs a candidate loglik
MS_STRUCT_MIN <- 1e5    # a column-resolved hilda vector must be WORSE by at least this

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
# ⛔ RECOMPUTED HERE, not lifted from a sibling artifact. A diagnostic that reads
# another script's saved streams inherits whatever vector THAT script resolved,
# and cannot tell a stale field from a mis-resolved recomputation
# ([[derived_must_mean_computed]], [[draws_match_gate]]).
v   <- dg_vector(MS_MODE)
rec <- unlist(dg_streams(dg_run(v), v))
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
# ⚠ THE HISTORICAL DEFECT IS PRESERVED, NOT RE-DERIVED. Once
# calibration/repair_canonical_streams.R has run, the live `streams` is correct
# and there is no defect left in the file to demonstrate on. The pre-repair set
# survives as `streams_as_fitted` (and byte-identically in the quarantine), and
# THAT is what sections 3 and 4 below exercise -- a gate must be pointed at the
# quarantine copy, never at a path its own repair rewrote
# ([[gate_reads_its_own_output]]).
stale <- if (!is.null(md$streams_as_fitted)) unlist(md$streams_as_fitted) else NULL
recon <- function(s) abs(sum(s) - ll_implied) < MS_TOL_RECON
same  <- function(a, b) setequal(names(a), names(b)) &&
                        max(abs(a[names(b)] - b)) < MS_TOL_ROW
cat("\n== 3. verdict ==\n")
if (recon(rec) && same(rec, fil)) {
  cat(sprintf("  ✅ HEALTHY. The live `streams` matches a recomputation at the resolved vector\n     (%d rows, max|diff| %.2e) AND reconciles with logpost - logprior to %.2e.\n",
              length(fil), max(abs(rec[names(fil)] - fil)), abs(sum(rec) - ll_implied)))
  if (!is.null(md$streams_provenance))
    cat(sprintf("     Repaired %s (%s); pre-repair set kept as `streams_as_fitted`.\n",
                md$streams_provenance$recomputed_on, md$streams_provenance$recomputed_at))
} else if (recon(rec) && !recon(fil)) {
  cat(sprintf("  ⛔ THE `streams` FIELD IS STALE by %.4f log-units, but the stored `logpost`\n     IS today's objective (reproduced to %.2e), so NO REFIT IS OWED.\n     Repair with calibration/repair_canonical_streams.R.\n",
              sum(rec) - sum(fil), abs(sum(rec) - ll_implied)))
  cat(sprintf("     gained %s | lost %s\n", paste(only_rec, collapse = " "),
              paste(only_fil, collapse = " ")))
} else if (recon(fil) && !recon(rec)) {
  cat("  ⛔⛔ THE STORED logpost WAS BUILT FROM THE STORED STREAM SET -- the refit ran under\n     an objective this build no longer has. A REFIT IS OWED; this is not a reporting bug.\n")
} else if (same(rec, fil)) {
  # ⛔ THE CASE [[compare_gaps_not_absolute_logposts]] PREDICTS, and it arrived
  # the same day this file was written. The streams still match a recomputation
  # at the resolved vector, so the LIKELIHOOD is intact and the objective has
  # NOT moved; what moved is a PRIOR, which shifts the stored `logpost` while
  # leaving every stream where it was. Diagnosing this as "a third objective
  # vintage" would indict a correct file for a property of its producer.
  cat(sprintf("  ⚠ A PRIOR HAS MOVED SINCE THIS MODE WAS FITTED -- the objective has NOT.\n"))
  cat(sprintf("     The %d streams still match a recomputation to %.2e, so the LIKELIHOOD\n     (%.6f) is intact; it is the stored `logpost` that is stale, by exactly the\n     prior shift: %+.6f log-units.\n",
              length(fil), max(abs(rec[names(fil)] - fil)), sum(rec), ll_implied - sum(rec)))
  cat(sprintf("     stored logpost %.6f | under TODAY'S priors this vector scores %.6f\n",
              md$logpost, sum(rec) + lp_band))
  cat("     ⇒ COMPARE ON LIKELIHOOD, not on the stored logpost, until the refit re-runs.\n")
} else {
  cat(sprintf("  ⛔ NEITHER candidate reconciles (file %+.4f, recomputed %+.4f) AND the file's\n     streams do not match a recomputation. Both a prior and the objective may have\n     moved; do not price anything on this file.\n",
              sum(fil) - ll_implied, sum(rec) - ll_implied))
}
if (!is.null(stale)) {
  # ⚠ MEASURED AGAINST THE RECOMPUTED STREAMS, NOT against `ll_implied`. The
  # shortfall is a property of the STREAM SET and must not move when a prior
  # does; quoting it against the implied loglik made the historical 4.7543 read
  # as 3.9433 the moment the 09-09w priors landed.
  cat(sprintf("\n  THE DEFECT THIS FILE WAS WRITTEN FOR, from the preserved `streams_as_fitted`:\n    %d rows, sum %.6f -> SHORT BY %.4f log-units against the recomputed set.\n    carried %s (%.4f) where the objective scored %s (%.4f).\n",
              length(stale), sum(stale), sum(stale) - sum(rec),
              paste(setdiff(names(stale), names(rec)), collapse = " "),
              sum(stale[setdiff(names(stale), names(rec))]),
              paste(setdiff(names(rec), names(stale)), collapse = " "),
              sum(rec[setdiff(names(rec), names(stale))])))
}

# ---- 3b. WAS THE RECOMPUTATION RESOLVED UNDER THE FILE'S OWN STRUCTURE? --
# The other way a "recomputed" stream set can be wrong, and it is not visible in
# the totals: a hilda mode resolved as a COLUMN is a well-formed 25-row set at a
# catastrophically different likelihood (CHANGELOG 09-08f). `ccx_mode_base(md)`
# is the ONE resolver (R/paths.R); this contrasts it against the column to show
# the check has POWER rather than asserting the resolver was used.
cat("\n== 3b. the recomputation was resolved under the file's own structure ==\n")
p_str <- ccx_overlay_par(ccx_mode_base(md), ccx_mode_params(md))
p_col <- ccx_overlay_par(ccx_apply_structure(ccx_default_params(), ""), ccx_mode_params(md))
p_col$pump_mode <- md$pump_mode
v_col <- v; v_col$p <- p_col
rec_col <- unlist(dg_streams(dg_run(v_col), v_col))
cat(sprintf("  struct '%s' -> hs_frac %.2f | resolved likelihood %.4f\n",
            ccx_mode_struct(md), p_str$hs_frac, sum(rec)))
cat(sprintf("  the SAME vector as a COLUMN -> hs_frac %g | likelihood %.2f (%+.1f)\n",
            p_col$hs_frac, sum(rec_col), sum(rec_col) - sum(rec)))
cat(sprintf("  -> the structure is worth %.3e log-units here: %s\n",
            abs(sum(rec_col) - sum(rec)),
            if (abs(sum(rec_col) - sum(rec)) > MS_STRUCT_MIN) "the check HAS POWER" else "NO POWER"))
stopifnot(p_str$hs_frac > 0, p_col$hs_frac == 0,
          abs(sum(rec_col) - sum(rec)) > MS_STRUCT_MIN)

# ---- 4. the SILENT GATE, named and MUTATION-TESTED ---------------------
# The adoption diagnostic's provenance gate compared only intersect(names) and
# reported max|diff|. Under the defect above it returns ~1e-10 and PASSES.
# ⚠ EXERCISED ON THE PRESERVED STALE SET, not on the live field: after the
# repair the live field is correct, and a gate demonstrated only against a
# defect that no longer exists is a gate nobody can check.
cat("\n== 4. the gate that should have caught this ==\n")
gate_intersect <- function(a, b) { k <- intersect(names(a), names(b))
                                   max(abs(a[k] - b[k])) < MS_TOL_ROW }
gate_nameset   <- function(a, b) setequal(names(a), names(b)) &&
                                   max(abs(a[names(b)] - b)) < MS_TOL_ROW
if (!is.null(stale)) {
  cat(sprintf("  on the HISTORICAL defect (streams_as_fitted):  intersect-gate %s  <- SILENT | name-set gate %s\n",
              if (gate_intersect(rec, stale)) "PASS" else "FAIL",
              if (gate_nameset(rec, stale)) "PASS" else "FAIL"))
  stopifnot(gate_intersect(rec, stale), !gate_nameset(rec, stale))
}
cat(sprintf("  on the LIVE field:                            intersect-gate %s | name-set gate %s\n",
            if (gate_intersect(rec, fil)) "PASS" else "FAIL",
            if (gate_nameset(rec, fil)) "PASS" else "FAIL"))
# MUTATION TEST: the name-set gate must PASS on an honest pair and FAIL on a
# broken one, or it is not a gate ([[mutation_test_gates]]). The mutants are
# built from the RECOMPUTED set so they exist whatever state the file is in --
# a mutation test that depends on the bug still being present is not a test.
mut_drop <- rec[-1]
mut_move <- rec; mut_move[[1]] <- mut_move[[1]] + 1
mut_sub  <- rec[-1]; mut_sub[["a_retired_row"]] <- rec[[1]]   # the SUBSTITUTION case
cat(sprintf("  MUTATION  identity pair    -> %s (want PASS)\n", if (gate_nameset(rec, rec)) "PASS" else "FAIL"))
cat(sprintf("  MUTATION  a row DELETED    -> %s (want FAIL)\n", if (gate_nameset(rec, mut_drop)) "PASS" else "FAIL"))
cat(sprintf("  MUTATION  a row MOVED +1   -> %s (want FAIL)\n", if (gate_nameset(rec, mut_move)) "PASS" else "FAIL"))
cat(sprintf("  MUTATION  a row SUBSTITUTED-> name-set %s (want FAIL) | intersect %s (want PASS = the blind spot)\n",
            if (gate_nameset(rec, mut_sub)) "PASS" else "FAIL",
            if (gate_intersect(rec, mut_sub)) "PASS" else "FAIL"))
stopifnot(gate_nameset(rec, rec), !gate_nameset(rec, mut_drop),
          !gate_nameset(rec, mut_move), !gate_nameset(rec, mut_sub),
          gate_intersect(rec, mut_sub))   # the silent gate's silence, asserted
cat("  ⇒ SUBSTITUTION is the case the intersect-gate cannot see, and it is the case a\n     changed objective produces.\n")

saveRDS(list(mode = MS_MODE, file = ccx_mode_file(MS_MODE),
             logpost = md$logpost, logprior = lp_band,
             loglik_implied = ll_implied,
             streams_file = fil, streams_recomputed = rec,
             only_in_file = only_fil, only_in_recomputed = only_rec,
             streams_stale = stale,
             stale_by = if (is.null(stale)) 0 else sum(rec) - sum(stale),
             reconciles = c(file = recon(fil), recomputed = recon(rec)),
             measured_on = as.character(Sys.Date()),
             commit = tryCatch(system("git rev-parse --short HEAD", intern = TRUE),
                               error = function(e) NA_character_)), MS_OUT)
cat(sprintf("\n  saved %s\n  ⛔ Reads only: no prior moved, no constant changed, no artifact repaired.\n",
            MS_OUT))
