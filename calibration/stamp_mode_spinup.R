# =====================================================================
# stamp_mode_spinup.R -- record the SPINUP VINTAGE into a mode file that was
# promoted before the field existed (2026-09-10), and ONLY after proving it.
#
# `hilda31p` (refit_20260910_hilda31_periodic) was promoted on 09-10 with its
# `streams` computed under CCX_OBJECTIVE_SPINUP = the periodic spinup (GATE 5
# reconciled them to -1.2e-09), but promote_multistart_mode.R did not yet write
# a `spinup` label. A consumer scoring the file like-for-like has to know that
# ⇒ ccx_mode_spinup(). This stamps the label -- and it is NOT a bare write: the
# candidate label is PROVED first, by requiring that the file's stored logpost
# reproduces under that spinup to the project's reproduction tolerance and
# does NOT under the other. A stamp that could be applied to a file it is
# false of would be a provenance field worth nothing.
#
# Usage:  Rscript calibration/stamp_mode_spinup.R <mode_file> <periodic|aseasonal>
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) stop("usage: stamp_mode_spinup.R <mode_file> <periodic|aseasonal>")
SMS_FILE  <- args[1]; SMS_LABEL <- args[2]
SMS_TOL   <- 1e-5                       # = recompute_hessian.R GATE 1 / promote GATE 4
md <- readRDS(SMS_FILE)
if (!is.null(md$spinup)) stop(SMS_FILE, " already records spinup = '", md$spinup, "'.")
bp <- ccx_mode_base(md); if (!is.null(md$pump_mode)) bp$pump_mode <- md$pump_mode
u  <- ccx_par_to_unc(md$par_mode)
v  <- vapply(c("periodic", "aseasonal"), function(l)
  ccx_make_logpost(base_params = bp, spinup_fn = ccx_spinup_from_label(l))(u), numeric(1))
cat(sprintf("stored %.6f | periodic %.6f (diff %.2e) | aseasonal %.6f (diff %.2e)\n",
            md$logpost, v[["periodic"]], v[["periodic"]] - md$logpost,
            v[["aseasonal"]], v[["aseasonal"]] - md$logpost))
ok <- abs(v - md$logpost) <= SMS_TOL
if (!ok[[SMS_LABEL]]) stop("the stored logpost does NOT reproduce under '", SMS_LABEL, "'; refusing to stamp.")
if (sum(ok) != 1L) stop("the stored logpost reproduces under BOTH spinups -- the label has no power here; refusing.")
md$spinup <- SMS_LABEL
md$spinup_stamped_by <- "calibration/stamp_mode_spinup.R"
md$spinup_stamped_on <- format(Sys.Date())
saveRDS(md, SMS_FILE)
cat(sprintf("stamped spinup = '%s' into %s\n", SMS_LABEL, SMS_FILE))
