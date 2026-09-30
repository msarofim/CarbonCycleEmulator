# =====================================================================
# diag_obj14_registered_bitexact.R -- OBJECTIVE #14 AND THE REGISTERED MODES
# (2026-09-30 p; the 09-30c handoff, step 1: "the older labels' streams stay
# bit-exact because their shares are pinned at 0; verify that, don't assume it").
#
# Objective #14 (the D2/D3 label "hilda_csl3v0kaidgb", R/calibrate.R) exists only
# under a structure that OPENS the gate. The freeze record (notes/assessment_
# 2026-09-21_product_ready.md sec. 4) says an objective change means a restamp of
# every mode. A restamp re-records `streams` and `logpost` when they MOVE; this
# measures whether they do. For every registered mode it re-scores the file under
# its OWN structure, pins and spinup -- the restamp tool's own path
# (restamp_mode_objective.R: gate, pins, ccx_mode_start(), the objective by stream)
# -- and compares against the STORED streams and logpost.
#
# PASS = every stream identical() (not a tolerance) and the logpost equal to the
# stored one after ccx_mode_start()'s own shift (the gate-4 identity).
# No RNG. Usage: Rscript calibration/diag_obj14_registered_bitexact.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
OB_DRIVER <- "calibration/diag_obj14_registered_bitexact.R"
OB_DATE   <- format(Sys.Date(), "%Y%m%d")
OB_LOG    <- ccx_path("outputs", "diagnostics", sprintf("obj14_registered_bitexact_%s.log", OB_DATE))
OB_LP_TOL <- 1e-9          # the logpost identity after the shift (sums of identical terms)
COMMIT    <- tryCatch(system("git rev-parse --short HEAD", intern = TRUE), error = function(e) "?")

sink(OB_LOG, split = TRUE)
cat(sprintf("%s @%s, %s\n", OB_DRIVER, COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M")))
cat(sprintf("fitted set with the gate CLOSED: %d names; gated (held under every registered label): %s\n\n",
            length(CCX_PARAM_NAMES), paste(names(CCX_PARAM_GATED), collapse = ", ")))
res <- lapply(names(CCX_MODE_FILES), function(a) {
  md <- readRDS(ccx_mode_file(a))
  gt <- ccx_apply_gate(ccx_mode_struct(md))                  # a no-op for every registered label
  rm <- ccx_apply_pins(ccx_mode_pins(md))
  on.exit({ ccx_unpin_params(rm); ccx_unapply_gate(gt) }, add = TRUE)
  invisible(utils::capture.output(st <- ccx_mode_start(md, "obj14 check")))
  bp <- ccx_mode_base(md); if (!is.null(md$pump_mode)) bp$pump_mode <- md$pump_mode
  v  <- ccx_make_logpost(base_params = bp, by_stream = TRUE,
                         spinup_fn = ccx_spinup_from_label(ccx_mode_spinup(md)))(st$u)
  s_new <- attr(v, "streams"); s_old <- unlist(md$streams)
  same_names <- identical(names(s_new), names(s_old))
  ident <- same_names && identical(unname(s_new), unname(s_old))
  dmax  <- if (same_names) max(abs(s_new - s_old)) else NA_real_
  dlp   <- as.numeric(v) - st$logpost_shift - md$logpost
  data.frame(mode = a, struct = ccx_mode_struct(md), gate_open = length(gt) > 0,
             n_rows = length(s_new), streams_identical = ident, max_abs_d_stream = dmax,
             d_logpost_after_shift = dlp, stringsAsFactors = FALSE)
})
tab <- do.call(rbind, res)
print(tab, row.names = FALSE)
ok <- all(tab$streams_identical) && all(abs(tab$d_logpost_after_shift) < OB_LP_TOL) && !any(tab$gate_open)
cat(sprintf("\nVERDICT: %s -- %d registered modes; streams identical %d/%d; |d logpost| max %.3g (tol %g)\n",
            if (ok) "PASS (no registered file moves; nothing to restamp)" else "FAIL",
            nrow(tab), sum(tab$streams_identical), nrow(tab), max(abs(tab$d_logpost_after_shift)), OB_LP_TOL))
cat(sprintf("provenance: %s @%s; registered modes from R/paths.R CCX_MODE_FILES; each file's own spinup; no RNG\n",
            OB_DRIVER, COMMIT))
sink()
if (!ok) stop("a registered mode moved under objective #14's build")
