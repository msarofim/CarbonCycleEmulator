# =====================================================================
# lib_rep_dc_ladder_report.R -- the reader for diag_rep_dc_product_ladder.R.
#
# WHY IT IS A SEPARATE FILE. The ladder's jobs are launched as independent
# processes (one per rung, so a stall in one cannot take the run down and so no
# fork has to survive a C++ handle). The report therefore has to be a pass over
# what landed on disk, and it has to say plainly which jobs are MISSING rather
# than quietly averaging over the ones that are there.
#
# ⛔ THE ONE RULE THIS FILE ENFORCES: a product's movement is reported against
# TWO yardsticks and never against a hand-picked absolute --
#   (1) the REPLICATE NOISE FLOOR, the spread of that product across the
#       perturbed re-optimisations AT THE CANONICAL RUNG. A product that moves
#       less than its own floor has not moved; the ladder has no power there and
#       says so instead of reporting a number.
#   (2) its OWN OBSERVATIONAL SIGMA where one exists (RPL_OBS_SD).
# [[tolerance_scaled_to_spread]], [[no_power_null]].
# =====================================================================

#' @param dir     the job directory
#' @param jobs    the job table (RPL_JOBS())
#' @param obs_sd  named vector of each product's observational sigma; NA elsewhere
#' @param n_rep   how many perturbed replicates were requested
#' @param rungs   the ladder
#' @param canon   index into `rungs` of the canonical rung
# ⛔ TWO OF THE "PRODUCTS" ARE NOT PRODUCTS, and reporting them as flat would be
# a false negative dressed as evidence (found 2026-09-23 on the smoke run, where
# both read EXACTLY 0.0000 movement AND an exactly 0.0000 noise floor -- the
# signature of an identity, not of a quantity that was measured and did not
# move; [[suspicious uniformity]] in `~/.claude/CLAUDE.md`):
#   `co2_pi`         -- the spinup is SOLVED to CO2_PI_PPM, so this is a
#                       constraint the model satisfies, not an output it chooses.
#   `part1000_close` -- the pulse partition's own mass-closure residual.
# They are kept because a MOVE in either is a bug signal, and reported under
# CHECKS where a reader cannot mistake "constant by construction" for "the
# ladder has no effect on it".
RPL_CHECKS <- c("co2_pi", "part1000_close")
# If the replicates cannot get back to within this of the canonical logpost, the
# "noise floor" is measuring an INADEQUATE OPTIMISER BUDGET, not optimiser noise,
# and every /floor ratio below is against the wrong scale.
RPL_FLOOR_SANE <- 5.0

rpl_report <- function(dir, jobs, obs_sd, n_rep, rungs, canon) {
  fs <- list.files(dir, pattern = "^job[0-9]+_.*\\.rds$", full.names = TRUE)
  if (!length(fs)) stop("no job files in ", dir)
  J <- lapply(fs, readRDS)
  ids <- vapply(J, function(x) x$job$id, integer(1))
  J <- J[order(ids)]; ids <- sort(ids)

  missing <- setdiff(jobs$id, ids)
  cat(sprintf("=== %d of %d jobs present%s ===\n", length(ids), nrow(jobs),
              if (length(missing)) sprintf("; MISSING %s", paste(missing, collapse = ", ")) else ""))
  if (length(missing))
    cat("⚠ the table below is INCOMPLETE -- do not read a ladder trend off it.\n")

  pv <- vapply(J, function(x) x$products$scalar, numeric(length(J[[1]]$products$scalar)))
  colnames(pv) <- vapply(J, function(x) x$job$label, character(1))
  prods <- rownames(pv)

  # ---- provenance, printed once, from the artifacts themselves ------
  p1 <- J[[1]]$provenance
  cat(sprintf("\nmode %s | objective %s | spinup %s | commit %s\n",
              p1$mode, p1$objective, p1$spinup, p1$commit))
  cat(sprintf("seed %d applied at %s | replicate perturbation %.2f x posterior sd\n",
              p1$seed, p1$seed_applied, p1$rep_frac))
  cat(sprintf("units: %s\n", p1$units))

  # ---- the NOISE FLOOR, from the replicates at the canonical rung ---
  rep_cols <- which(vapply(J, function(x) x$job$rep, integer(1)) > 0L)
  can_col  <- which(vapply(J, function(x) x$job$label, character(1)) == "canonical")
  if (!length(rep_cols)) {
    cat("\n⛔ NO REPLICATES PRESENT -- there is no noise floor, so no product movement\n")
    cat("   below can be distinguished from Nelder-Mead. Run jobs 2..%d first.\n")
    floor_v <- setNames(rep(NA_real_, length(prods)), prods)
  } else {
    anchor <- pv[, can_col, drop = TRUE]
    floor_v <- apply(abs(pv[, rep_cols, drop = FALSE] - anchor), 1, max)
    cat(sprintf("\n=== NOISE FLOOR (max |replicate - canonical| over %d perturbed re-optimisations) ===\n",
                length(rep_cols)))
    cat(sprintf("  %-16s %14s %14s\n", "product", "canonical", "floor"))
    for (n in prods)
      cat(sprintf("  %-16s %14.4f %14.4f\n", n, anchor[[n]], floor_v[[n]]))
    cat(sprintf("\n  logpost spread across replicates: %.4f log-units\n", floor_v[["logpost"]]))
    if (!is.finite(floor_v[["logpost"]]) || floor_v[["logpost"]] > RPL_FLOOR_SANE) {
      cat(sprintf("\n⛔⛔ THE BUDGET IS INADEQUATE AND THE FLOOR IS NOT A NOISE FLOOR.\n"))
      cat(sprintf("   The replicates land %.2f log-units from the canonical (sane < %.1f), so they\n",
                  floor_v[["logpost"]], RPL_FLOOR_SANE))
      cat("   did not re-find the optimum. Every /floor ratio below is measured against\n")
      cat("   UNDER-CONVERGENCE, not optimiser noise, and a product that clears it has not\n")
      cat("   been shown to move. Re-run the replicates at a larger RPL_NM_MAXIT before\n")
      cat("   reading any verdict from this table.\n")
    }
  }

  # ---- the ladder ---------------------------------------------------
  lad <- which(vapply(J, function(x) x$job$rep, integer(1)) == 0L)
  lad <- lad[order(vapply(J[lad], function(x) -x$job$rung, numeric(1)))]
  cat("\n=== THE LADDER (rep_dC pinned; the other 28 fully re-optimised) ===\n")
  hdr <- c("rep_dC", "logpost", "loglik", "irf100", "part1000_land", "part1000_ocean",
           "part1000_air", "af_all", "gateD_asym", "grad_d13c", "co2_pi",
           "sink_land", "sink_ocean")
  cat(sprintf("  %8s", hdr)); cat("\n")
  for (i in lad) {
    v <- pv[, i]
    cat(sprintf("  %8.3f", v[hdr])); cat("\n")
  }

  # ---- the verdict, product by product ------------------------------
  top <- lad[1]; bot <- lad[length(lad)]
  cat(sprintf("\n=== MOVEMENT from rep_dC %.3f to %.3f, against BOTH yardsticks ===\n",
              pv["rep_dC", top], pv["rep_dC", bot]))
  cat(sprintf("  %-16s %12s %12s %10s %10s %12s\n",
              "product", "top", "bottom", "delta", "/floor", "/obs sigma"))
  verdict <- list()
  for (n in setdiff(prods, c("rep_dC", "logpost", "loglik", RPL_CHECKS))) {
    d  <- pv[n, bot] - pv[n, top]
    fl <- floor_v[[n]]
    os <- if (n %in% names(obs_sd)) obs_sd[[n]] else NA_real_
    rf <- if (is.finite(fl) && fl > 0) abs(d) / fl else NA_real_
    ro <- if (is.finite(os) && os > 0) abs(d) / os else NA_real_
    verdict[[n]] <- c(delta = d, per_floor = rf, per_obs = ro)
    cat(sprintf("  %-16s %12.4f %12.4f %+10.4f %10s %12s\n", n,
                pv[n, top], pv[n, bot], d,
                if (is.finite(rf)) sprintf("%.1f", rf) else "--",
                if (is.finite(ro)) sprintf("%.2f", ro) else "--"))
  }
  cat("\n  /floor  = |delta| in units of the optimiser-noise floor. < 1 => THE LADDER\n")
  cat("            HAS NO POWER on that product; it has not been shown to move.\n")
  cat("  /obs sigma = |delta| in units of that product's own observational sigma,\n")
  cat("            where one exists. This is the 'would a reader notice' scale.\n")

  # ---- the CHECKS, reported apart so they cannot be read as products -
  cat("\n=== CHECKS (constant by construction -- a MOVE here is a bug, not a result) ===\n")
  for (n in intersect(RPL_CHECKS, prods))
    cat(sprintf("  %-16s %12.4f -> %12.4f  delta %+.3e  %s\n", n, pv[n, top], pv[n, bot],
                pv[n, bot] - pv[n, top],
                if (abs(pv[n, bot] - pv[n, top]) < 1e-6) "as expected" else "*** INVESTIGATE ***"))

  moved <- names(which(vapply(verdict, function(x) isTRUE(x[["per_floor"]] > 1), logical(1))))
  cat(sprintf("\n=== %d product(s) move by more than the noise floor: %s ===\n",
              length(moved), if (length(moved)) paste(moved, collapse = ", ") else "NONE"))
  cat("⛔ NOTHING HERE IS ADOPTED. Changing this prior is an OBJECTIVE change:\n")
  cat("   freeze record §4.1 -- a ruling, then a restamp of every mode.\n")
  invisible(list(products = pv, floor = floor_v, verdict = verdict, missing = missing))
}
