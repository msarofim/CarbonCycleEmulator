# =====================================================================
# aaa_root.R -- THE ROOT RESOLVER, AND IT MUST BE SOURCED FIRST.
#
# WHY THIS FILE EXISTS SEPARATELY FROM paths.R (2026-09-09w). Every driver in
# this repo bootstraps with
#
#     for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
#
# which is ALPHABETICAL. `constants.R` therefore runs BEFORE `paths.R`, so any
# constant that needs to read a data/ product at source time could not call
# `ccx_path()` -- it did not exist yet. Two such constants arrived on 09-09w
# (`.ENT_SO_SST_AMP`, `.ENT_SO_PCO2_AMP`, both promoted from typed literals to
# data/ products), and the first attempt worked around it with a relative-path
# fallback. ⛔ THAT FALLBACK WAS WRONG, and paths.R's own header says why:
# testthat runs from `tests/testthat/` and the Shiny app from `app/`, so a
# relative "data/..." resolves to nothing there. The whole suite failed to load.
#
# ⇒ The resolver is hoisted here rather than the dependency being worked around.
# `aaa_root.R` sorts before every other file in R/, so `ccx_root()` and
# `ccx_path()` are available to all of them -- including `calibrate.R` and
# `constants.R`, which precede `paths.R`. Nothing else belongs in this file:
# adding to it re-creates the ordering question it exists to close.
#
# ⚠ The name is load-bearing. Do not rename it to anything that sorts later.
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
