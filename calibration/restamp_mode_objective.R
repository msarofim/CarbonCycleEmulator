# =====================================================================
# restamp_mode_objective.R -- re-record a mode file's `streams` and `logpost`
# under TODAY'S objective after a PRICED objective change, keeping the history.
#
# WHY (2026-09-11 (5)). The ruling "annual mean of the concentration" changed
# how the ocean-gradient and HS-surface rows read a box (over its mass AT THE
# TIME, averaged over the epoch year -- R/likelihood.R, ccx_box_annual_conc).
# At a time-constant box that moves the rows by the box's own seasonal cycle:
# -0.0957 at hilda31p. A mode file stores its streams in the units of the
# objective that produced them, and two fixtures cross-check the harness
# against them (test-enso-demean.R's edm_crosscheck, test-mode-file.R's
# "the canonical's stored logpost is a value of today's objective"). Neither
# is re-expressible away -- their point IS the stored value -- so the file is
# re-stamped, with the old value and the reason kept inside it.
#
# ⛔ NOT A BARE WRITE. The measured move OF THE LIKELIHOOD (sum of streams)
# must equal the PRICED move given on the command line (to RS_TOL), so this
# script cannot absorb an unpriced drift: a delta that does not match the
# CHANGELOG's number is refused. The gate is on the STREAMS, not the logpost,
# because a stored logpost also carries every PRIOR move since the file was
# fitted (the quarantined hilda31 sits -0.811 behind on the 09-09w re-centring,
# which its streams never saw) -- the same reason edm_crosscheck() pins the
# streams ([[compare_gaps_not_absolute_logposts]]). The logpost move is printed
# with that decomposition. The previous streams/logpost go into
# `objective_history`, never overwritten.
#
# Usage: Rscript calibration/restamp_mode_objective.R <mode_file> <expected_delta> "<reason>"
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 3L) stop("usage: restamp_mode_objective.R <mode_file> <expected_delta> \"<reason>\"")
RS_FILE <- args[1]; RS_EXPECT <- as.numeric(args[2]); RS_REASON <- args[3]
RS_TOL  <- 1e-4                          # the priced delta is quoted to 4 dp
md <- readRDS(RS_FILE)
bp <- ccx_mode_base(md); if (!is.null(md$pump_mode)) bp$pump_mode <- md$pump_mode
# 2026-09-16 (d): a PINNED file has its pins applied first, and a file written
# under an older parameter set is brought forward by ccx_mode_start() (migrated
# + seeded, the encoding every gate 4 uses) -- the bare ccx_par_to_unc(par_mode)
# refuses both. The seeding shift and the h_ml band term ride in the logpost
# and are reported as prior drift below; the gate is on the STREAMS.
rm <- ccx_apply_pins(ccx_mode_pins(md)); on.exit(ccx_unpin_params(rm), add = TRUE)
invisible(utils::capture.output(st0 <- ccx_mode_start(md, "restamp"))); u <- st0$u
v  <- ccx_make_logpost(base_params = bp, by_stream = TRUE,
                       spinup_fn = ccx_spinup_from_label(ccx_mode_spinup(md)))(u)
# The stored logpost stays in the FILE'S OWN coordinates: today's likelihood +
# the priors on ITS names under ITS recorded band. ccx_mode_start()'s shift is
# exactly what this build adds on top (the seeded absent names' prior legs and
# the h_ml band term), so it is removed here -- otherwise every gate 4 (`v -
# shift == md$logpost`) would fail by the shift after the restamp.
lp_new <- as.numeric(v) - st0$logpost_shift; st_new <- attr(v, "streams")
lik_old <- sum(unlist(md$streams)); lik_new <- sum(unlist(st_new))
delta   <- lik_new - lik_old                      # the LIKELIHOOD move -- what is gated
d_lp    <- lp_new - md$logpost                    # the logpost move = likelihood + prior drift
cat(sprintf("%s: likelihood %.6f -> %.6f (delta %+.6f; expected %+.4f) | logpost %.6f -> %.6f (%+.6f, of which prior drift %+.6f)\n",
            RS_FILE, lik_old, lik_new, delta, RS_EXPECT, md$logpost, lp_new, d_lp, d_lp - delta))
if (abs(delta - RS_EXPECT) > RS_TOL)
  stop("the measured LIKELIHOOD move does not match the priced one (|", format(delta - RS_EXPECT), "| > ", RS_TOL,
       "). Price the change in the CHANGELOG first; this script does not absorb drift.")
# a row NEW to the objective (an added stream, #13) has no old value: name it as new rather than NA
new_rows <- setdiff(names(st_new), names(md$streams)); old_rows <- intersect(names(st_new), names(md$streams))
moved <- c(old_rows[which(abs(unlist(st_new[old_rows]) - unlist(md$streams[old_rows])) > 1e-6)], if (length(new_rows)) paste0("NEW:", new_rows))
cat("  rows that moved:", paste(sprintf("%s %+.4f", moved, unlist(st_new[moved]) - unlist(md$streams[moved])), collapse = ", "), "\n")
md$objective_history <- c(md$objective_history, list(list(
  date = format(Sys.Date()), reason = RS_REASON, logpost_before = md$logpost, logpost_after = lp_new,
  lik_before = lik_old, lik_after = lik_new, prior_drift_absorbed = d_lp - delta,
  streams_before = md$streams, commit = tryCatch(system("git rev-parse --short HEAD", intern = TRUE), error = function(e) NA_character_),
  by = "calibration/restamp_mode_objective.R")))
md$logpost <- lp_new; md$streams <- st_new
saveRDS(md, RS_FILE)
cat(sprintf("restamped %s (history entries: %d)\n", RS_FILE, length(md$objective_history)))
