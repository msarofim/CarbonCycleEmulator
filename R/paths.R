# =====================================================================
# paths.R — resolve repo-relative paths regardless of working directory.
#
# Needed because scripts, testthat (which runs from tests/testthat/), and
# the Shiny app (which runs from app/) all have different working
# directories but must reach the same data/ files.
# =====================================================================

REPO_MARKER <- "DESIGN.md"

#' Absolute path to the repository root
#' @param start directory to search upward from
ccx_root <- function(start = getwd()) {
  d <- normalizePath(start, mustWork = FALSE)
  for (i in 1:10) {
    if (file.exists(file.path(d, REPO_MARKER))) return(d)
    parent <- dirname(d)
    if (identical(parent, d)) break
    d <- parent
  }
  stop("Could not locate the CarbonCycleEmulator root (no '", REPO_MARKER,
       "' found above '", start, "').")
}

#' Build a path relative to the repository root
#' @param ... path components, e.g. ccx_path("data", "obs_co2_monthly.rds")
ccx_path <- function(...) file.path(ccx_root(), ...)
