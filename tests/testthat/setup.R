# Sourced by testthat before every test file. Loads the model source from
# the repo root so tests work regardless of the working directory.

.root <- local({
  d <- normalizePath(getwd(), mustWork = FALSE)
  for (i in 1:10) {
    if (file.exists(file.path(d, "DESIGN.md"))) break
    d <- dirname(d)
  }
  d
})

for (f in list.files(file.path(.root, "R"), pattern = "\\.R$", full.names = TRUE)) {
  source(f)
}

# Shared skip: the C++ core is optional (Rcpp may be absent, or the compile may
# fail on a machine without a toolchain). MOVED HERE 2026-08-16 from
# test-climate.R, where it was defined -- which meant it existed only for files
# testthat happened to run AFTER that one, and `test_file()` on any other file
# failed outright. setup.R is sourced before EVERY file, which is what a shared
# helper needs.
skip_if_no_cpp <- function() {
  testthat::skip_if_not_installed("Rcpp")
  ok <- tryCatch({ ccx_load_cpp(); TRUE }, error = function(e) FALSE)
  if (!ok) testthat::skip("C++ core failed to compile")
}

# Shared skip: the FaIR-derived climate module is a built data product
# (data-raw/build_climate_module.R). MOVED HERE 2026-09-12 from test-climate.R and
# test-pulse.R, where it was defined twice, identically.
skip_if_no_climate <- function() {
  if (!file.exists(ccx_path("data", CLIMATE_MODULE_FILE)))
    testthat::skip("climate module not built (data-raw/build_climate_module.R)")
}
