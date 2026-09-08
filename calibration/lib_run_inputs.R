# =====================================================================
# lib_run_inputs.R -- the RUN-TIME INPUTS the objective needs, in one list,
# asserted BEFORE anything spends a wall budget on them.
#
# ⛔ THE BUG THIS EXISTS TO KILL (found 2026-09-01, by the Torch port gate, on
# the FIRST end-to-end run of the bundle). `ccx_nuclear_c14_annual()` reads
# `data-raw/downloads/nuclear14c/*.csv` through a DEFAULT ARGUMENT, and when the
# directory is absent it **warns and returns an empty frame** -- the industrial
# 14C source silently becomes ZERO. The Torch bundle excludes `data-raw/` (3.4 GB
# of provenance), so every array task would have run a DIFFERENT OBJECTIVE,
# wrong by ~1e-3 relative in log-posterior: far too small to look wrong, far too
# large to be the same problem.
#
# The port gate DID catch it -- that is what a 1e-8 relative bound on a pure
# evaluation is for, and no looser tolerance would have. But it reported "this
# machine does not reproduce the objective", which points at the PORT when the
# cause is a FILE THAT WAS NOT SHIPPED. A gate that fires for the right reason
# and names the wrong one still costs a diagnosis. So: assert the inputs first,
# by name, and let the port gate go back to guarding the port.
#
# ⚠ THE LIST IS THE POINT ([[recorded_but_never_restored]], [[default_off_hides_the_bug]]).
# `nuclear14c` is TODAY the only run-time read from `data-raw/` in `R/` -- checked,
# not assumed (`grep -rn 'ccx_path("data-raw"' R/`). Add an entry here THE SAME
# DAY a second one appears, and `make_bundle.sh` ships everything named here.
#
# ⛔ SOURCE THIS, DO NOT RUN IT.
# =====================================================================

# Each entry: the path, WHY the objective needs it, and the SYMPTOM of absence --
# because the symptom is what a reader will actually have in front of them.
CCX_RUN_INPUTS <- list(
  list(path    = file.path("data-raw", "downloads", "nuclear14c"),
       kind    = "dir",
       pattern = "csv$",
       why     = "the industrial (reactor) 14C source, summed over 7 country files",
       symptom = paste("ccx_nuclear_c14_annual() warns 'No nuclear 14C files found;",
                       "industrial source set to zero' and the objective shifts by",
                       "~1e-3 relative -- silently, and only in the 14C streams")),
  # 2026-09-07f: the two products round 3's objective and prior read. The
  # surface product is tryCatch'ed to NULL by ccx_hs_surface_target(), so its
  # absence would DROP two rows silently -- a different objective, no error.
  list(path    = file.path("data", "obs_hs_surface.rds"),
       kind    = "file", pattern = NULL,
       why     = "objective #11: the HS-surface DIC and d13C targets (GLODAPv2.2023)",
       symptom = "hs_surf_dic / hs_surf_d13c are ABSENT from by_stream and the total is a different objective"),
  list(path    = file.path("data", "obs_hs_export_prior.rds"),
       kind    = "file", pattern = NULL,
       why     = "the lognormal literature prior on pump_hs_gcm2 (Liniger 2025, Arteaga 2019)",
       symptom = "readRDS() errors inside the prior at the first log-posterior evaluation"),
  # 2026-09-08d: the two OBSERVATION priors round 4 reads (u_hs freed; h_ml's
  # flat density replaced). Same failure mode as the export prior above.
  list(path    = file.path("data", "obs_u_hs_prior.rds"),
       kind    = "file", pattern = NULL,
       why     = "the lognormal observation prior on u_hs (NADW + AABW formation, Talley 2013 / Lumpkin & Speer 2007)",
       symptom = "readRDS() errors inside the prior at the first log-posterior evaluation"),
  list(path    = file.path("data", "obs_h_ml_prior.rds"),
       kind    = "file", pattern = NULL,
       why     = "the lognormal observation prior on h_ml (Holte 2017 Argo MLD: annual mean 59.7 / max 118 m as the 16/84 % points)",
       symptom = "readRDS() errors inside the prior at the first log-posterior evaluation")
)

#' Stop unless every run-time input is present, naming the one that is not
#'
#' @param inputs the manifest; overridable only for testing this function
#' @return invisibly TRUE
ccx_require_run_inputs <- function(inputs = CCX_RUN_INPUTS) {
  missing <- character(0)
  for (it in inputs) {
    p <- ccx_path(it$path)
    ok <- if (identical(it$kind, "dir"))
            dir.exists(p) && length(list.files(p, pattern = it$pattern)) > 0
          else file.exists(p)
    if (!ok)
      missing <- c(missing, sprintf("  %s\n      needed for: %s\n      symptom if missing: %s",
                                    it$path, it$why, it$symptom))
  }
  if (length(missing))
    stop("RUN-TIME INPUT MISSING -- the objective would be silently DIFFERENT ",
         "here:\n", paste(missing, collapse = "\n"),
         "\n\n  These are excluded from git (`.gitignore: data-raw/downloads/*`) but ",
         "ARE shipped by\n  calibration/torch/make_bundle.sh. If you are on a remote ",
         "machine, re-build and\n  re-send the bundle; do not proceed, and do not ",
         "read a port-gate failure as a\n  port problem until this passes.")
  cat(sprintf("run-time inputs present: %d/%d. OK\n", length(inputs), length(inputs)))
  invisible(TRUE)
}
