# =====================================================================
# collect_dispersed_multistart.R -- rank the starts, and say how many BASINS
# they found rather than how many runs finished.
#
# WHY RANKING IS NOT ENOUGH. The survey's question is not "what is the best
# logpost" -- that is one line. It is "is there a THIRD basin", and two starts
# that land 0.01 apart at the same point are ONE finding reported twice. So this
# clusters the finished starts in u-space before it ranks them, and reports the
# cluster count as the answer.
#
# ⚠ THE CLUSTER RADIUS IS A MEASURED SCALE, NOT AN INVENTED ONE. It defaults to
# a fraction of the per-coordinate RMS separation of the TWO KNOWN BASINS, which
# every output file records as `spread_measured` -- i.e. the survey's own
# resolution. Two points closer than that are not resolvable as different basins
# BY THIS SURVEY, and saying so is the honest verdict. It is still a choice; it
# is printed, and `CCX_MS_CLUSTER_FRAC` overrides it.
#
# ⛔ ADOPTS NOTHING. It writes a summary CSV and prints a table.
#
# Usage:  CCX_MS_OUTDIR=<dir> Rscript calibration/collect_dispersed_multistart.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)

CO_DIR <- local({
  d <- Sys.getenv("CCX_MS_OUTDIR", NA_character_)
  if (is.na(d) || !nzchar(d)) ccx_path("calibration", "output", "multistart_20260831") else d
})
CO_FRAC <- local({
  v <- Sys.getenv("CCX_MS_CLUSTER_FRAC", NA_character_)
  if (is.na(v) || !nzchar(v)) 0.25 else as.numeric(v)
})
CO_REF_IDS <- c(cold = 0L, incumbent = 1L, new_basin = 2L)
CO_OUT     <- file.path(CO_DIR, "summary.csv")

fs <- sort(list.files(CO_DIR, pattern = "^start_[0-9]+\\.rds$", full.names = TRUE))
if (!length(fs)) stop("no start_*.rds under ", CO_DIR)
R <- lapply(fs, readRDS)

# ---- GATE: one parameter set, one arm, one dispersion, or they are not
# comparable and a ranking across them is meaningless.
.chk <- function(field, what) {
  v <- unique(vapply(R, function(r) paste(r[[field]], collapse = "|"), character(1)))
  if (length(v) > 1)
    stop("the starts under ", CO_DIR, " disagree on ", what, ": ",
         paste(v, collapse = "  /  "), ". They are not one survey.")
  v
}
.chk("param_names", "the parameter set")
.chk("pump_mode",   "the arm")
.chk("spread",      "the dispersion sd")
cat(sprintf("\n%s\nDISPERSED MULTI-START SURVEY -- %d starts under\n  %s\n%s\n",
            strrep("=", 74), length(R), CO_DIR, strrep("=", 74)))

# ---- did every reference start pass its port gate? -------------------
for (nm in names(CO_REF_IDS)) {
  k <- which(vapply(R, function(r) identical(r$id, CO_REF_IDS[[nm]]), logical(1)))
  if (!length(k)) { cat(sprintf("  ⚠ reference start '%s' (id %d) IS MISSING -- the port is NOT verified\n",
                                nm, CO_REF_IDS[[nm]])); next }
  r <- R[[k]]
  cat(sprintf("  reference %-10s id %d  logpost %12.4f  port %s\n", nm, r$id, r$logpost,
              if (isTRUE(r$port_checked)) sprintf("VERIFIED (rel %.1e)", r$port_rel)
              else if (identical(r$id, CO_REF_IDS[["cold"]])) "n/a"
              else "*** NOT VERIFIED ***"))
}

fin  <- vapply(R, function(r) r$logpost, numeric(1))
conv <- vapply(R, function(r) isTRUE(r$converged), logical(1))
oot  <- vapply(R, function(r) isTRUE(r$out_of_time), logical(1))
ids  <- vapply(R, function(r) r$id, integer(1))
U    <- do.call(rbind, lapply(R, function(r) r$u_mode))

# ---- clustering, on the FINISHED starts only -------------------------
# An out-of-time start is a point the search had not finished moving, so
# clustering it would invent a basin at wherever the clock happened to stop.
RAD <- CO_FRAC * R[[1]]$spread_measured * sqrt(ncol(U))
# EXCLUDE a task that ran NO restart as well as one that ran out of time: its
# u is exactly where it was dropped, so clustering it would invent a basin at a
# random draw. `restarts_done` is absent from files written before 08-31f.
did_work <- vapply(R, function(r) is.null(r$restarts_done) || r$restarts_done > 0L, logical(1))
keep <- which(!oot & did_work)
if (any(!did_work))
  cat(sprintf("  ⚠ %d start(s) ran NO restart at all (the wall budget did not fit one).\n     Excluded from the basin count.\n",
              sum(!did_work)))
cat(sprintf("\n  %d of %d starts CONVERGED, %d ran out of wall time (excluded from\n  the basin count, included in the table below).\n",
            sum(conv), length(R), sum(oot)))
cat(sprintf("  cluster radius %.4f = %.2f x the measured inter-basin separation\n",
            RAD, CO_FRAC))

lab <- rep(NA_integer_, length(R))
if (length(keep)) {
  d <- as.matrix(stats::dist(U[keep, , drop = FALSE]))
  # single-linkage at RAD: the transitive closure of "within RAD"
  cl <- rep(NA_integer_, length(keep)); nc <- 0L
  for (i in seq_along(keep)) {
    if (!is.na(cl[i])) next
    nc <- nc + 1L; front <- i
    while (length(front)) {
      cl[front] <- nc
      nxt <- unique(unlist(lapply(front, function(j) which(d[j, ] <= RAD & is.na(cl)))))
      front <- nxt
    }
  }
  lab[keep] <- cl
  # order clusters by their best member, so cluster 1 IS the best basin found
  bestof <- vapply(seq_len(nc), function(k) max(fin[keep][cl == k]), numeric(1))
  ord <- order(bestof, decreasing = TRUE); remap <- match(seq_len(nc), ord)
  lab[keep] <- remap[cl]
  cat(sprintf("\n  ⇒ %d DISTINCT BASIN%s among the %d finished starts.\n",
              nc, if (nc == 1L) "" else "S", length(keep)))
}

o <- order(fin, decreasing = TRUE)
cat(sprintf("\n  %5s %6s %14s %14s %8s %7s %6s  %s\n",
            "rank", "id", "logpost", "vs best", "basin", "status", "min", "kind"))
for (i in seq_along(o)) {
  j <- o[i]; r <- R[[j]]
  cat(sprintf("  %5d %6d %14.4f %14.4f %8s %7s %6.0f  %s\n", i, r$id, fin[j],
              fin[j] - max(fin), if (is.na(lab[j])) "--" else as.character(lab[j]),
              if (oot[j]) "TIME" else if (conv[j]) "conv" else "cap",
              r$minutes, r$kind))
}

# ---- the verdict, as an ORDERING against the incumbent to beat -------
kN <- which(ids == CO_REF_IDS[["new_basin"]])
if (length(kN)) {
  bench <- fin[kN]; best <- max(fin); jb <- which.max(fin)
  cat(sprintf("\n%s\n  BEST FOUND      id %d at %.4f\n  TO BEAT         id %d (08-31e new basin) at %.4f\n  difference      %+.4f log-units\n",
              strrep("-", 74), ids[jb], best, ids[kN], bench, best - bench))
  cat(sprintf("  VERDICT: the survey %s the 08-31e basin.\n",
              if (best > bench + 1e-8) "FOUND A BETTER BASIN THAN"
              else if (best < bench - 1e-8) "did NOT reach"
              else "REPRODUCED, and did not beat,"))
  if (!is.na(lab[jb]) && !is.na(lab[kN]) && lab[jb] != lab[kN])
    cat("  ⚠ and the best start is in a DIFFERENT cluster from it -- a third basin.\n")
}
cat("  ⚠ A survey bounds what N starts at ONE dispersion found. It is not a\n")
cat("    proof that no better basin exists ([[no_power_null]]: measure the\n")
cat("    test's power before believing its null).\n")

sm <- data.frame(id = ids, logpost = fin, basin = lab, converged = conv,
                 out_of_time = oot, minutes = vapply(R, function(r) r$minutes, numeric(1)),
                 n_eval = vapply(R, function(r) r$n_eval, numeric(1)),
                 draws = vapply(R, function(r) r$draws, numeric(1)),
                 kind = vapply(R, function(r) r$kind, character(1)),
                 host = vapply(R, function(r) r$host, character(1)))
utils::write.csv(sm[order(-sm$logpost), ], CO_OUT, row.names = FALSE)
cat(sprintf("\n  summary written to %s\n⛔ NOTHING IS ADOPTED.\n%s\n", CO_OUT, strrep("=", 74)))
