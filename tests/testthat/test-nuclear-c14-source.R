# The nuclear-industry 14C source as a tracked data/ input (2026-10-14; Marcus: "Promote to
# data/ .rds + stop() (Recommended)"; CHANGELOG 2026-10-14 h, j).
#
#   N1  the .rds's nine files are the ones MANIFEST.csv records (sha256, independent record)
#   N2  the .rds is CURRENT with those files: the build-time reader reproduces it exactly
#       (skipped where data-raw/downloads is absent, e.g. a bundle; N1 still runs there)
#   N3  the loader STOPS without the file, and converts with MOL_C14_PER_GBq exactly
#   N4  nothing in R/ reads data-raw/ at run time (the grep lib_run_inputs.R's header cites)
#
# That the MODEL is bit-identical to the pre-change reader was measured once against the
# pre-change build (CHANGELOG 2026-10-14 j) and is held continuously by the suite's
# stored-stream reproduce tests, which fail on the three 14C rows if this source moves.

NC_DIR <- ccx_path("data-raw", "downloads", "nuclear14c")

test_that("N1: the source's nine files are the ones MANIFEST.csv records", {
  r <- readRDS(ccx_path(FORC_NUC_C14_FILE))
  pv <- attr(r, "provenance")
  expect_length(pv$file_sha256, 9L)
  man <- utils::read.csv(ccx_path("data-raw", "downloads", "MANIFEST.csv"), stringsAsFactors = FALSE)
  k <- match(file.path("data-raw", "downloads", "nuclear14c", names(pv$file_sha256)), man$file)
  expect_false(anyNA(k))
  expect_identical(unname(pv$file_sha256), man$sha256[k])
  expect_identical(names(r), c("year", "GBq"))
  expect_true(all(diff(r$year) == 1L))     # one row per year, no interior gap
})

test_that("N2: the source is CURRENT with its files (the build-time reader reproduces it exactly)", {
  skip_if_not(dir.exists(NC_DIR) && length(list.files(NC_DIR, pattern = "csv$")) > 0,
              "data-raw/downloads/nuclear14c absent (a bundle or a fresh clone); N1 still checks the record")
  r <- readRDS(ccx_path(FORC_NUC_C14_FILE)); attr(r, "provenance") <- NULL
  expect_identical(r, ccx_nuclear_c14_sum_files(NC_DIR))
})

test_that("N3: the loader STOPS without the file, and converts exactly", {
  expect_error(ccx_nuclear_c14_annual(file.path(tempdir(), "no_such_nuclear_c14.rds")), "is missing")
  r <- readRDS(ccx_path(FORC_NUC_C14_FILE))
  v <- ccx_nuclear_c14_annual()
  expect_identical(v$year, r$year)
  expect_identical(v$mol_per_yr, r$GBq * ccx_const("MOL_C14_PER_GBq"))
})

test_that("N4: nothing in R/ reads data-raw/ at run time", {
  hits <- unlist(lapply(list.files(ccx_path("R"), pattern = "\\.R$", full.names = TRUE), function(f) {
    x <- readLines(f, warn = FALSE)
    x <- sub("#.*$", "", x)                                  # code only, not comments
    if (any(grepl('ccx_path\\("data-raw"', x))) basename(f)
  }))
  expect_identical(hits, NULL, info = paste(hits, collapse = ", "))
})
