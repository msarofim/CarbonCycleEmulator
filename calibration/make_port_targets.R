# =====================================================================
# make_port_targets.R -- record, ON THE REFERENCE MACHINE, what the objective
# evaluates to at three fixed points, so a PORT can be gated against it.
#
# WHY A FILE AND NOT A LITERAL. `run_dispersed_multistart.R`'s reference ids
# must be able to say "this machine reproduces the objective". The value they
# compare against has to come from somewhere the running script did not produce
# ([[gate_reads_its_own_output]]) -- a gate whose target is its own output
# passes exactly once and thereafter compares a convention against itself.
#
# WHY NOT THE MODE FILES' OWN STORED logpost. Because that is NOT the same
# quantity. The 08-30 incumbent stores -1547.1579 and evaluates to -1548.0112
# in today's build: a -0.85 objective-drift offset that has nothing to do with
# any port. Gating a port against it would spend 85 % of a 1.0-log-unit budget
# on a known, unrelated effect. What a port must reproduce is what THIS BUILD
# computes at THAT point, which is what this file records.
#
# THE THREE POINTS are the reference starts, and they are read out of the mode
# files rather than restated: the cold hand-set init, the 08-30 incumbent, and
# the 08-31e polished new-basin mode.
#
# Re-run this whenever the OBJECTIVE changes. The output carries the commit, the
# host and the timestamp so a stale target is visible rather than silent.
#
# Usage:  Rscript calibration/make_port_targets.R      # ~5 s
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

PT_ARM  <- "N"
PT_OUT  <- ccx_path("calibration", "torch", "port_targets.csv")
PT_REFS <- c(
  cold      = NA,   # the hand-set init; no file
  incumbent = "calibration/output/refit_20260831_seas_lag_split/from90/mode_fit_pumpN.rds",
  new_basin = "calibration/output/polish_20260831_probe_basin/from90/mode_fit_pumpN.rds"
)

bp <- ccx_default_params(); bp$pump_mode <- PT_ARM
lp <- ccx_make_logpost(base_params = bp)
.ship <- lapply(CCX_PARAM_TABLE, function(s) c(s$lo, s$hi))

rows <- lapply(names(PT_REFS), function(nm) {
  if (is.na(PT_REFS[[nm]])) {
    u <- ccx_init_unc(); stored <- NA_real_; src <- "ccx_init_unc()"
  } else {
    md <- readRDS(ccx_path(PT_REFS[[nm]]))
    if (!isTRUE(all.equal(md$hml_bound, .ship$h_ml)) ||
        !isTRUE(all.equal(md$kz_bracket, .ship$kz)))
      stop(nm, " was fitted under NON-SHIPPED bands; its point is not a ",
           "like-for-like target under the shipped table.")
    u <- ccx_par_to_unc(ccx_migrate_par_set(md$par_mode))
    stored <- md$logpost; src <- PT_REFS[[nm]]
  }
  v <- lp(u)
  if (!identical(lp(u), v))
    stop("the objective is not a pure function of u on this machine; a port ",
         "gate against it would be meaningless.")
  data.frame(name = nm, logpost = sprintf("%.10f", v),
             stored = if (is.na(stored)) NA_character_ else sprintf("%.10f", stored),
             offset = if (is.na(stored)) NA_character_ else sprintf("%+.10f", v - stored),
             source = src, stringsAsFactors = FALSE)
})
tg <- do.call(rbind, rows)
tg$arm       <- PT_ARM
tg$n_par     <- length(CCX_PARAM_NAMES)
tg$commit    <- tryCatch(sub("\\s.*", "", system("git rev-parse --short HEAD",
                                                 intern = TRUE)), error = function(e) NA)
tg$host      <- Sys.info()[["nodename"]]
tg$r_version <- paste(R.version$major, R.version$minor, sep = ".")
tg$measured  <- format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")

dir.create(dirname(PT_OUT), recursive = TRUE, showWarnings = FALSE)
utils::write.csv(tg, PT_OUT, row.names = FALSE)
cat(sprintf("\nPORT TARGETS written to %s\n\n", PT_OUT))
print(tg[, c("name", "logpost", "stored", "offset")], row.names = FALSE)
cat(sprintf("\n  arm %s, %d parameters, commit %s, host %s, R %s\n",
            PT_ARM, length(CCX_PARAM_NAMES), tg$commit[1], tg$host[1], tg$r_version[1]))
cat("  ⚠ `stored` is each mode FILE's own logpost and is NOT the target: the\n")
cat("    incumbent's -0.85 offset is objective drift, not a port defect.\n")
