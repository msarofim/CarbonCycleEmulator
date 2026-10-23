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
source(ccx_path("calibration", "lib_ms_deadline.R"))   # ms_start_clock() / ms_clock_mix_note() (2026-10-05 o)

CO_DIR <- local({
  d <- Sys.getenv("CCX_MS_OUTDIR", NA_character_)
  # ⚠ MATCHES run_dispersed_multistart.R's default. Two files naming two
  # different default directories is the caption-sync bug: the collector would
  # read an empty 22-parameter directory and say "no start_*.rds".
  if (is.na(d) || !nzchar(d))
    ccx_path("calibration", "output", "multistart_20260901_enso25") else d
})
CO_FRAC <- local({
  v <- Sys.getenv("CCX_MS_CLUSTER_FRAC", NA_character_)
  if (is.na(v) || !nzchar(v)) 0.25 else as.numeric(v)
})
# ⛔ THE VERDICT'S BOUND IS **READ FROM THE STARTS**, not set here. This is only
# the value to assume when a file predates `cycle_tol` being recorded
# (2026-09-01e) -- it is the driver's MS_CYCLE_TOL at that date, and using it is
# an ASSUMPTION the report says out loud rather than a bound it knows.
CO_TOL_FALLBACK <- 0.5
CO_REF_IDS  <- c(cold = 0L, incumbent = 1L, new_basin = 2L)
# ⛔ THE BENCHMARK IS THE BEST *RE-CONVERGED KNOWN BASIN*, NOT ID 2 (2026-09-01k).
# Ids 1 and 2 are MIGRATED 21-parameter vectors: their ocean ENSO pair is
# exactly 0 because the mechanism did not exist when they were fitted, and the
# objective is measured to want it elsewhere. Ranking a dispersed 25-parameter
# result against id 2's start value -- or against the -1496.01 in its mode file
# -- compares an optimum against a migrated point [[like_for_like_forcing]].
# So the number to beat is the best FINAL value among the fixed non-cold starts,
# which is what ids 3-5 exist to produce.
CO_SEED_IDS <- c(inc_enso = 3L, new_enso = 4L, new_obs = 5L)
# THE FILE SLOTS (2026-10-23): MIRRORS run_dispersed_multistart.R's MS_FILE_IDS (test-ms-file.R checks the two agree). A
# FILLED slot is a known point (the flask refit's T8c / T8f points), so it joins the benchmark; an EMPTY one ran its id's
# dispersed draw (start_class "dispersed") and joins the draws. Which slots were filled is READ from the starts'
# `file_starts_n` below, so a slot the file did not fill is never reported as a MISSING known-basin start.
CO_FILE_IDS <- c(file1 = 6L, file2 = 7L, file3 = 8L, file4 = 9L)
CO_OUT     <- file.path(CO_DIR, "summary.csv")

fs <- sort(list.files(CO_DIR, pattern = "^start_[0-9]+\\.rds$", full.names = TRUE))
if (!length(fs)) stop("no start_*.rds under ", CO_DIR)
R <- lapply(fs, readRDS)
# how many file slots the wave's file filled; a file written before 2026-10-23 has no field and filled none
CO_FILE_N <- unique(vapply(R, function(r) if (is.null(r$file_starts_n)) 0L else as.integer(r$file_starts_n), integer(1)))
if (length(CO_FILE_N) > 1L)
  stop("the starts under ", CO_DIR, " record different numbers of file starts (", paste(CO_FILE_N, collapse = ", "),
       "). They are not one survey.")
CO_BENCH_IDS <- c(CO_REF_IDS[c("incumbent", "new_basin")], CO_SEED_IDS, CO_FILE_IDS[seq_len(CO_FILE_N)])

# ---- GATE: one parameter set, one arm, one dispersion, or they are not
# comparable and a ranking across them is meaningless.
.chk <- function(field, what) {
  v <- unique(vapply(R, function(r) paste(r[[field]], collapse = "|"), character(1)))
  if (length(v) > 1)
    stop("the starts under ", CO_DIR, " disagree on ", what, ": ",
         paste(v, collapse = "  /  "), ". They are not one survey.")
  # invisible: at TOP LEVEL in an Rscript the value of a call is auto-printed,
  # so this gate used to dump all 22 parameter names above the report's title.
  invisible(v)
}
.chk("param_names", "the parameter set")
.chk("pump_mode",   "the arm")
.chk("spread",      "the dispersion sd")
# one file of FILE STARTS (2026-10-23): a start without one records NA, and one written before the field existed has none
local({
  v <- unique(vapply(R, function(r) if (is.null(r$file_starts_md5) || is.na(r$file_starts_md5)) "none"
                     else r$file_starts_md5, character(1)))
  if (length(v) > 1L)
    stop("the starts under ", CO_DIR, " disagree on the file starts (CCX_MS_FILE_STARTS md5 ", paste(v, collapse = "  /  "),
         "). They are not one survey.")
})
cat(sprintf("\n%s\nDISPERSED MULTI-START SURVEY -- %d starts under\n  %s\n%s\n",
            strrep("=", 74), length(R), CO_DIR, strrep("=", 74)))

# ---- did every reference start pass its port gate? -------------------
for (nm in names(CO_REF_IDS)) {
  k <- which(vapply(R, function(r) identical(r$id, CO_REF_IDS[[nm]]), logical(1)))
  # (2026-10-23) every task checks the port (a non-reference one at the new-basin point), so a missing reference start
  # leaves the port unverified only when no start that ran checked it -- a local refit runs ids 1 and 6-7 only
  if (!length(k)) { cat(sprintf("  ⚠ reference start '%s' (id %d) IS MISSING -- %s\n", nm, CO_REF_IDS[[nm]],
                                if (any(vapply(R, function(r) isTRUE(r$port_checked), logical(1))))
                                  "the starts that ran checked the port themselves (their port column below)"
                                else "the port is NOT verified")); next }
  r <- R[[k]]
  cat(sprintf("  reference %-10s id %d  logpost %12.4f  port %s\n", nm, r$id, r$logpost,
              if (isTRUE(r$port_checked)) sprintf("VERIFIED (rel %.1e)", r$port_rel)
              else if (identical(r$id, CO_REF_IDS[["cold"]])) "n/a"
              else "*** NOT VERIFIED ***"))
}
# ---- the FILE STARTS (2026-10-23): each one's value gate and port, from its own record
for (r in R[vapply(R, function(r) identical(r$start_class, "file"), logical(1))])
  cat(sprintf("  file start %-9s id %d  logpost %12.4f  port %s  value gate %s\n", r$file_start_name, r$id, r$logpost,
              if (isTRUE(r$port_checked)) sprintf("VERIFIED (rel %.1e)", r$port_rel) else "*** NOT VERIFIED ***",
              if (isTRUE(r$file_gate$checked)) sprintf("VERIFIED (|diff| %.1e)", r$file_gate$diff) else "*** NOT RUN ***"))

# ⛔ DEAD TASKS (2026-09-10): a start whose reported optimum is not a finite point
# of the objective (it ended on the penalty plateau) is REFUSED, not ranked --
# three of them in 17343694 reported "CONVERGED" at exactly -1e6. Files written
# before the field existed carry no `dead`; for those the plateau value itself
# is the tell, so both are checked.
.dead <- vapply(R, function(r) isTRUE(r$dead) || isTRUE(all.equal(r$logpost, -1e6)), logical(1))
if (any(.dead)) {
  cat(sprintf("  *** %d DEAD task(s) EXCLUDED (optimum not a finite point of the objective): ids %s -- re-run them
",
              sum(.dead), paste(vapply(R[.dead], function(r) r$id, integer(1)), collapse = ", ")))
  R <- R[!.dead]
  if (!length(R)) stop("every start in this directory is DEAD; nothing to rank. Re-run them from a driver with the derived penalty (2026-09-10).")
}
fin  <- vapply(R, function(r) r$logpost, numeric(1))
conv <- vapply(R, function(r) isTRUE(r$converged), logical(1))
oot  <- vapply(R, function(r) isTRUE(r$out_of_time), logical(1))
ids  <- vapply(R, function(r) r$id, integer(1))
U    <- do.call(rbind, lapply(R, function(r) r$u_mode))
# ⭐ THE CLOCK EACH START'S BUDGET RAN ON (2026-10-05 o; Marcus D3, "Record and warn (Recommended)"). An absent
# field is "wall": every start file written before then ran the wall clock. Out-of-time counts and minutes on two
# clocks are not like-for-like, so a mixed wave is WARNED below and every label names its clock.
clk  <- vapply(R, ms_start_clock, character(1))
CO_CLOCK <- if (length(unique(clk)) == 1L) ms_clock_label(clk[1]) else "MIXED-clock"

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
  cat(sprintf("  ⚠ %d start(s) ran NO restart at all (the %s budget did not fit one).\n     Excluded from the basin count.\n",
              sum(!did_work), CO_CLOCK))
# CONVERGED and OUT-OF-TIME are mutually exclusive as of 08-31f, and the counts
# must sum: a report saying "1 of 5 converged, 5 ran out of time" is describing
# two states of one task and is how that driver bug was caught.
cat(sprintf("\n  %d of %d starts CONVERGED, %d ran out of %s time (excluded from the\n  basin count, kept in the table), %d spent their restart budget.\n",
            sum(conv), length(R), sum(oot), CO_CLOCK, sum(!conv & !oot)))
.mix <- ms_clock_mix_note(clk, ids)
if (!is.null(.mix)) cat(sprintf("  ⚠ %s\n", .mix))
if (any(conv & oot))
  stop("a start reports BOTH converged and out-of-time: ",
       paste(ids[conv & oot], collapse = ", "),
       ". Those are exclusive states; the driver that wrote it is wrong.")
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
cat(sprintf("\n  %5s %6s %14s %14s %8s %7s %6s %5s  %s\n",
            "rank", "id", "logpost", "vs best", "basin", "status", "min", "clock", "kind"))
for (i in seq_along(o)) {
  j <- o[i]; r <- R[[j]]
  cat(sprintf("  %5d %6d %14.4f %14.4f %8s %7s %6.0f %5s  %s\n", i, r$id, fin[j],
              fin[j] - max(fin), if (is.na(lab[j])) "--" else as.character(lab[j]),
              if (oot[j]) "TIME" else if (conv[j]) "conv" else "cap",
              r$minutes, clk[j], r$kind))
}

# ---- the verdict's BOUND, READ FROM THE OPTIMIZER THAT PRODUCED THESE --
# ⛔ THIS USED TO BE A HARDCODED 1e-8, AND 1e-8 IS THE WRONG KIND OF BOUND HERE.
# 1e-8 is right for the PORT GATE, whose claim is an EVALUATION IDENTITY: one
# fixed point, two machines, agree to floating point or the port is broken. The
# verdict's claim is different -- it compares two OPTIMIZER OUTPUTS, and no
# optimizer promises its output to 1e-8. So on 2026-09-01 it printed
#   "4 dispersed starts did NOT reach the best re-converged known basin"
# for a difference of -0.0000 (about 1e-6): a FALSE VERDICT, in the one line a
# reader takes away, from a bound that did not match its claim
# [[gate_bound_matches_its_claim]] -- reproduced in the very session that cited
# that memory.
# ⇒ The bound is the driver's OWN convergence criterion, `MS_CYCLE_TOL`: a start
# is declared CONVERGED when a whole cycle gains less than this, so two finals
# closer than it are, BY THIS OPTIMIZER'S OWN STANDARD, not distinguishable.
# It is READ from the start files [[recorded_but_never_restored]], PRINTED with
# the verdict, and disagreement across files is a hard error rather than a
# quietly-picked winner.
# ⚠ AND ABSENCE MUST ASSERT, not fall through. `unique(unlist(...))` DROPS the
# NULLs, so a directory mixing pre- and post-2026-09-01e files would pick the
# recorded value and say nothing about the half that carries no opinion -- the
# silent-omission shape of [[intersect_is_a_silent_default]]. Counted explicitly.
CO_TOL <- local({
  has <- vapply(R, function(r) !is.null(r$cycle_tol), logical(1))
  v   <- unique(unlist(lapply(R[has], function(r) r$cycle_tol)))
  if (length(v) > 1L)
    stop("the starts under ", CO_DIR, " record DIFFERENT convergence tolerances (",
         paste(v, collapse = ", "), "). Their finals cannot be judged against one ",
         "bound; they are not one survey.")
  if (!any(has)) {
    cat(sprintf("\n  ⚠ NO start records `cycle_tol` (all written before 2026-09-01e).\n     The verdict below uses %.3g, ASSUMED from the driver at that date, not read.\n",
                CO_TOL_FALLBACK))
    return(CO_TOL_FALLBACK)
  }
  if (!all(has))
    cat(sprintf("\n  ⚠ %d of %d starts record no `cycle_tol` (ids %s, written before\n     2026-09-01e). The verdict uses %.3g, read from the other %d -- those older\n     runs are ASSUMED to share it. Re-run them if that matters.\n",
                sum(!has), length(R), paste(ids[!has], collapse = ", "),
                as.numeric(v), sum(has)))
  as.numeric(v)
})

# ---- the verdict, as an ORDERING against the incumbent to beat -------
# ⚠ AN UNSEEDABLE SEEDED SLOT IS NOT A KNOWN-BASIN START (2026-10-07 m; lib_ms_seed.R): when the arm fits none of a
# seed's targets, the driver runs that id as a DISPERSED DRAW and records start_class "dispersed". It joins the
# survey's draws below, never the benchmark, and it is not MISSING either. Older files carry the id's class.
co_drawn <- vapply(R, function(r) identical(r$start_class, "dispersed"), logical(1))
co_unseedable <- ids[ids %in% CO_SEED_IDS & co_drawn]
# a FILLED file slot that reports a draw is a driver defect, not a fallback: CO_BENCH_IDS holds only the filled slots
if (any(ids %in% CO_FILE_IDS[seq_len(CO_FILE_N)] & co_drawn))
  stop("file slot(s) ", paste(ids[ids %in% CO_FILE_IDS[seq_len(CO_FILE_N)] & co_drawn], collapse = ", "),
       " ran a dispersed draw although the wave's file filled them (file_starts_n = ", CO_FILE_N, ").")
kB <- which(ids %in% CO_BENCH_IDS & !co_drawn)
if (length(co_unseedable))
  cat(sprintf("\n  ⚠ seeded slot%s %s %s UNSEEDABLE under this arm (its seed moves no fitted name) and ran %s:\n    counted with the survey's draws, not in the benchmark.\n",
              if (length(co_unseedable) == 1L) "" else "s", paste(sort(co_unseedable), collapse = ", "),
              if (length(co_unseedable) == 1L) "was" else "were",
              if (length(co_unseedable) == 1L) "a dispersed draw" else "dispersed draws"))
if (!length(kB)) {
  cat(sprintf("\n%s\n  ⚠ NO VERDICT: not one of the known-basin starts (ids %s) is present, so\n    there is nothing in THIS parameter space to rank a dispersed result against.\n    Run them before reading the table above as a survey result.\n",
              strrep("-", 74), paste(sort(CO_BENCH_IDS), collapse = ", ")))
} else {
  kN <- kB[which.max(fin[kB])]
  bench <- fin[kN]; best <- max(fin); jb <- which.max(fin)
  cat(sprintf("\n%s\n  BEST FOUND      id %d at %.4f\n  TO BEAT         id %d (%s) at %.4f\n  difference      %+.4f log-units\n",
              strrep("-", 74), ids[jb], best, ids[kN], R[[kN]]$kind, bench, best - bench))
  co_missing <- setdiff(CO_BENCH_IDS, ids)
  if (length(co_missing))
    cat(sprintf("  ⚠ the benchmark is the best of only %d of the %d known-basin starts;\n    ids %s are MISSING and one of them could be higher.\n",
                length(kB), length(CO_BENCH_IDS) - length(co_unseedable),
                paste(sort(co_missing), collapse = ", ")))
  # ⭐ ONLY A DISPERSED START CAN ANSWER THE SURVEY'S QUESTION. A fixed start
  # that comes back on top says the known basins are still the best known
  # basins -- which is worth printing, but it is NOT "the survey found
  # something". Reporting one "BEST FOUND" for both conflates them, and with the
  # fixed starts now seeded (ids 3-5) the top of the table is quite likely to be
  # one of them [[no_power_null]]: the two states must not print the same line.
  kD <- which(vapply(R, function(r) identical(r$start_class, "dispersed") ||
                       (is.null(r$start_class) && !(r$id %in% c(CO_REF_IDS, CO_SEED_IDS))),
                     logical(1)))
  if (!length(kD)) {
    cat("  ⚠ NO DISPERSED START finished, so the survey has not been run yet --\n    the table above is the known basins re-converged, and nothing more.\n")
  } else {
    jd <- kD[which.max(fin[kD])]
    cat(sprintf("  BEST DISPERSED  id %d at %.4f (%+.4f vs the benchmark), of %d finished\n",
                ids[jd], fin[jd], fin[jd] - bench, length(kD)))
    cat(sprintf("  VERDICT: %d dispersed start%s %s the best re-converged known\n           basin, at the optimiser's own convergence bound of %.3g log-units.\n",
                length(kD), if (length(kD) == 1L) "" else "s",
                if (fin[jd] > bench + CO_TOL) "FOUND A BETTER BASIN THAN"
                else if (fin[jd] < bench - CO_TOL) "did NOT reach"
                else "REPRODUCED, and did not beat,", CO_TOL))
  }
  if (!is.na(lab[jb]) && !is.na(lab[kN]) && lab[jb] != lab[kN])
    cat("  ⚠ and the best start is in a DIFFERENT cluster from it -- a third basin.\n")
  # ⭐ WHAT THE SEEDING WAS WORTH, which is only readable because ids 1/2 were
  # kept as UNSEEDED controls beside ids 3/4.
  for (p in list(c("incumbent", "inc_enso"), c("new_basin", "new_enso"))) {
    ku <- which(ids == CO_REF_IDS[[p[1]]]); ks <- which(ids == CO_SEED_IDS[[p[2]]])
    if (length(ks) && co_drawn[ks])
      cat(sprintf("  ENSO seeding at the %-9s: UNSEEDABLE under this arm (id %d ran a dispersed draw)\n",
                  p[1], ids[ks]))
    else if (length(ku) && length(ks))
      cat(sprintf("  ENSO seeding at the %-9s: %+.4f log-units (%.4f seeded vs %.4f not)\n",
                  p[1], fin[ks] - fin[ku], fin[ks], fin[ku]))
  }
}
cat("  ⚠ A survey bounds what N starts at ONE dispersion found. It is not a\n")
cat("    proof that no better basin exists ([[no_power_null]]: measure the\n")
cat("    test's power before believing its null).\n")

sm <- data.frame(id = ids, logpost = fin, basin = lab, converged = conv,
                 out_of_time = oot, minutes = vapply(R, function(r) r$minutes, numeric(1)),
                 # the clock `minutes` is on, and the WALL minutes beside it (a pre-10-05 wall file: the same number)
                 clock = clk,
                 minutes_wall = vapply(R, function(r) if (!is.null(r$minutes_wall)) r$minutes_wall
                                       else if (ms_start_clock(r) == "wall") r$minutes else NA_real_, numeric(1)),
                 n_eval = vapply(R, function(r) r$n_eval, numeric(1)),
                 draws = vapply(R, function(r) r$draws, numeric(1)),
                 kind = vapply(R, function(r) r$kind, character(1)),
                 start_class = vapply(R, function(r)
                   if (is.null(r$start_class)) NA_character_ else r$start_class, character(1)),
                 host = vapply(R, function(r) r$host, character(1)))
utils::write.csv(sm[order(-sm$logpost), ], CO_OUT, row.names = FALSE)
cat(sprintf("\n  summary written to %s\n⛔ NOTHING IS ADOPTED.\n%s\n", CO_OUT, strrep("=", 74)))
