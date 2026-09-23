# =====================================================================
# lib_rep_dc_release_report.R -- the reader for diag_rep_dc_release_test.R (T2).
#
# ⛔⛔ THE RULE THIS FILE EXISTS TO ENFORCE. Arms B and C score FEWER rows than
# the shipped objective and arm A scores one row at a different sigma, so an
# arm's logpost is on its OWN objective. Comparing two arms' logposts is
# meaningless and the table therefore does not print a cross-arm total. The only
# comparable quantity is the COST WITHIN AN ARM -- what that arm pays to force
# `rep_dC` from the canonical down to a target -- and the question T2 asks is
# whether that cost COLLAPSES relative to the shipped arm's.
#
# [[like_for_like_forcing]]: the arms differ only in the likelihood; every one
# starts from the same canonical `u`, pins `rep_dC` at the same rungs, and frees
# the same 28 names.
# =====================================================================

rt_report <- function(dir, jobs, rungs, canon, drop) {
  fs <- list.files(dir, pattern = "^job[0-9]+_.*\\.rds$", full.names = TRUE)
  if (!length(fs)) stop("no job files in ", dir)
  J <- lapply(fs, readRDS)
  J <- J[order(vapply(J, function(x) x$job$id, integer(1)))]
  ids <- vapply(J, function(x) x$job$id, integer(1))

  missing <- setdiff(jobs$id, ids)
  cat(sprintf("=== %d of %d jobs present%s ===\n", length(ids), nrow(jobs),
              if (length(missing)) sprintf("; MISSING %s", paste(missing, collapse = ", ")) else ""))
  if (length(missing)) cat("⚠ INCOMPLETE -- a missing rung makes its arm's cost unreadable.\n")

  p1 <- J[[1]]$provenance
  cat(sprintf("\nmode %s | %s | spinup %s | commit %s\n",
              p1$mode, p1$objective, p1$spinup, p1$commit))
  cat(sprintf("arm A sigma: RE-MEASURED %.3f ppm from %d ice samples in %d-%d (%s)\n",
              p1$ice_scatter_measured, p1$ice_n, p1$ice_overlap[1], p1$ice_overlap[2],
              p1$ice_sigma_source))
  cat(sprintf("seed %d applied at %s\n", p1$seed, p1$seed_applied))
  cat(sprintf("⛔ %s\n", p1$comparability))

  arms <- unique(vapply(J, function(x) x$job$arm, character(1)))

  # ---- the noise floor, per arm, from its own replicate --------------
  cat("\n=== NOISE FLOOR, per arm (|replicate - canonical| in log-units) ===\n")
  floor_v <- setNames(rep(NA_real_, length(arms)), arms)
  for (a in arms) {
    can <- Filter(function(x) x$job$arm == a && x$job$rep == 0 &&
                    abs(x$job$rung - rungs[canon]) < 1e-9, J)
    rep <- Filter(function(x) x$job$arm == a && x$job$rep > 0, J)
    if (length(can) && length(rep)) {
      floor_v[[a]] <- max(abs(vapply(rep, function(x) x$arm_logpost, numeric(1)) -
                              can[[1]]$arm_logpost))
      cat(sprintf("  %-14s %8.3f\n", a, floor_v[[a]]))
    } else cat(sprintf("  %-14s %8s (canonical or replicate missing)\n", a, "--"))
  }

  # ---- THE COST, within each arm ------------------------------------
  cat(sprintf("\n=== THE COST OF FORCING rep_dC DOWN, within each arm ===\n"))
  cat(sprintf("  %-14s %10s %14s %14s %12s %10s\n",
              "arm", "rep_dC", "arm logpost", "cost vs canon", "vs shipped", "/floor"))
  cost <- list()
  for (a in arms) {
    base <- Filter(function(x) x$job$arm == a && x$job$rep == 0 &&
                     abs(x$job$rung - rungs[canon]) < 1e-9, J)
    if (!length(base)) { cat(sprintf("  %-14s canonical rung MISSING\n", a)); next }
    b <- base[[1]]$arm_logpost
    for (rg in rungs) {
      it <- Filter(function(x) x$job$arm == a && x$job$rep == 0 &&
                     abs(x$job$rung - rg) < 1e-9, J)
      if (!length(it)) next
      d <- it[[1]]$arm_logpost - b
      cost[[paste(a, rg)]] <- d
      sh <- cost[[paste("shipped", rg)]]
      rel <- if (!is.null(sh) && is.finite(sh) && abs(sh) > 1e-9) d / sh else NA_real_
      fl <- floor_v[[a]]
      cat(sprintf("  %-14s %10.3f %14.3f %14.3f %12s %10s\n", a, rg,
                  it[[1]]$arm_logpost, d,
                  if (is.finite(rel)) sprintf("%.2fx", rel) else "--",
                  if (is.finite(fl) && fl > 0) sprintf("%.1f", abs(d) / fl) else "--"))
    }
  }

  # ---- the verdict ---------------------------------------------------
  cat("\n=== DOES THE COST COLLAPSE? ===\n")
  cat("  'vs shipped' < ~0.5 on an arm => that arm's released block was carrying\n")
  cat("  the offset, and rep_dC is standing in for it. ~1.0 => the block is not\n")
  cat("  what is holding the offset up, and releasing it buys nothing.\n")
  cat("  '/floor' < 1 => that arm has NO POWER on the question -- its own\n")
  cat("  optimiser spread is as large as the cost it is being asked to resolve.\n")
  for (rg in rungs[-canon]) {
    sh <- cost[[paste("shipped", rg)]]
    if (is.null(sh)) next
    cat(sprintf("\n  at rep_dC = %+.3f (shipped arm pays %.2f):\n", rg, sh))
    for (a in setdiff(arms, "shipped")) {
      d <- cost[[paste(a, rg)]]
      if (is.null(d)) next
      cat(sprintf("    %-14s pays %8.2f  (%.2fx the shipped cost) -> %s\n", a, d, d / sh,
                  if (abs(d / sh) < 0.5) "COLLAPSES" else "does NOT collapse"))
    }
  }
  cat("\n⛔ NOTHING HERE IS ADOPTED. Every arm is a MODIFIED objective and adopting\n")
  cat("   one is a ruling plus a restamp of every mode (freeze record §4.1).\n")
  invisible(list(cost = cost, floor = floor_v, missing = missing))
}
