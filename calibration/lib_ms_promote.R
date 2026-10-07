# =====================================================================
# lib_ms_promote.R -- WHICH START promote_multistart_mode.R promotes (2026-10-07 k; Marcus: "Build --id, read both
# (Recommended)"). Sourced by the driver and by tests/testthat/test-promote-id.R.
#
# DEFAULT (no --id): the best CONVERGED, in-time start by the STORED logpost, COMPUTED from the directory, never typed
# (GATE 3 as it always was: [[derived_must_mean_computed]]).
# --id=<n>: the NAMED start, which must be converged, in time and live (not `dead`). The computed best is still
# returned beside it, so the mode file records what was NOT promoted and by how much.
# WHY AN ID AT ALL: the stored logpost is the density of the UNCONSTRAINED vector, likelihood + prior + the
# log-Jacobian of each transform. At objective #17 its best basin (A) led by 0.409 only through h_ml's logit
# Jacobian, and basin B was better on LIKELIHOOD by 0.761; Marcus chose B (CHANGELOG 2026-10-07 a/b;
# [[basin_rank_by_logit_jacobian]]). "Best stored logpost" cannot promote that choice.
# =====================================================================

#' @param S  the start files' lists (readRDS of every start_NNN.rds in the directory)
#' @param id NA for the computed best, or the id to promote
#' @return list(pick = the start to promote, top = the computed best, fin = the converged in-time starts,
#'   lp = their stored logposts, chosen_by = "best_logpost" | "id", gap = top's logpost minus pick's, >= 0)
pmm_choose_start <- function(S, id = NA_integer_) {
  fin <- Filter(function(s) isTRUE(s$converged) && !isTRUE(s$out_of_time), S)
  if (!length(fin)) stop("no CONVERGED, in-time start in this directory")
  lp  <- vapply(fin, function(s) s$logpost, numeric(1))
  top <- fin[[which.max(lp)]]
  if (length(id) != 1L) stop("pmm_choose_start(): `id` must be one value (NA for the computed best)")
  if (is.na(id)) return(list(pick = top, top = top, fin = fin, lp = lp, chosen_by = "best_logpost", gap = 0))
  if (!is.numeric(id) || id < 0 || id != round(id)) stop("--id must be a whole number >= 0, not '", id, "'")
  ids <- vapply(S, function(s) as.integer(s$id), integer(1))
  k <- which(ids == id)
  if (length(k) != 1L) stop(sprintf("--id=%d: %d start files carry that id; exactly one is required", as.integer(id), length(k)))
  s <- S[[k]]
  if (!isTRUE(s$converged) || isTRUE(s$out_of_time) || isTRUE(s$dead))
    stop(sprintf(paste0("--id=%d is not a CONVERGED, in-time, live start (converged %s, out_of_time %s, dead %s): ",
                        "promoting it would name a point the optimiser had not finished"),
                 as.integer(id), isTRUE(s$converged), isTRUE(s$out_of_time), isTRUE(s$dead)))
  list(pick = s, top = top, fin = fin, lp = lp, chosen_by = "id", gap = top$logpost - s$logpost)
}
