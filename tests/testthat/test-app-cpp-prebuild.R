# =====================================================================
# Gate: the C++ core's BACKGROUND BUILD (R/cpp.R ccx_cpp_prebuild(); 2026-10-20, CHANGELOG 2026-10-20 b).
#
# app/global.R starts the compile in a separate R process and the first run that needs the core waits
# for it. What must hold:
#   1. the background build is the one loaded (no second compile), and the core it gives computes
#      EXACTLY what the in-process core computes (identity: same source, compiler and flags);
#   2-4. MUTATIONS: a build that FAILS, a build process that DIES without a result, and one that never
#      starts each fall back to the in-process compile, and the dead and never-started ones do so
#      without waiting out CCX_CPP_PREBUILD_WAIT_S.
# Each case runs in a fresh Rscript, so the core this test process loaded is never touched.
# The result compared is a default-parameter spin-up's state (~190 calls into the core) and one
# derivative; the forcing is test-parity.R's.
# =====================================================================
skip_if_no_cpp()

CPB_RSCRIPT <- file.path(R.home("bin"), "Rscript")
CPB_FAST_S  <- 10       # "without waiting out the wait": far below CCX_CPP_PREBUILD_WAIT_S (600 s)
CPB_SETUP_S <- 0.25     # test 4: room for the child's setup between `started` and the wait (measured ~0.02 s)

#' Run `setup` then ccx_load_cpp() in a fresh R process; what it loaded, how long it waited, what it computed
cpb_child <- function(setup) {
  out <- tempfile(fileext = ".rds"); scr <- tempfile(fileext = ".R")
  writeLines(c(
    sprintf("setwd(%s)", deparse(.root)),
    "for (f in list.files('R', pattern = '[.]R$', full.names = TRUE)) source(f)",
    setup,
    "t0 <- proc.time()[['elapsed']]",
    "ccx_load_cpp()",
    "load_s <- proc.time()[['elapsed']] - t0",
    "p <- ccx_default_params(); sp <- ccx_spinup(p)",
    "forc <- list(e_foss = list(NH = 8, SH = 0.4), e_luc = list(NH = 0.6, SH = 0.5),",
    "             cum_luc = list(NH = 120, SH = 80), gmst = 1.1, enso = 0.7, c14_bomb = 1200,",
    "             c14_nuclear = 40, c14_cosmo = sp$prod_c14, d13c_foss = -27.6)",
    "d <- ccx_deriv_fast(sp$y, 1980.5, p, forc, sp$grid, sp$aux)",
    # the compiled libraries in the background build's directory, and when its result was written
    "pb <- file.path(tempdir(), 'pb')",
    "so <- list.files(pb, pattern = '[.]so$', recursive = TRUE, full.names = TRUE)",
    "done_t <- if (file.exists(file.path(pb, 'done'))) file.mtime(file.path(pb, 'done')) else NA",
    sprintf("saveRDS(list(built_by = .ccx_cpp_env$built_by, wait_s = .ccx_cpp_env$prebuild_wait_s,
                     load_s = load_s, y = sp$y, d = d, so_t = file.mtime(so), done_t = done_t), %s)",
            deparse(out))), scr)
  log <- system2(CPB_RSCRIPT, scr, stdout = TRUE, stderr = TRUE)
  if (!file.exists(out)) stop("child failed:\n", paste(utils::tail(log, 20), collapse = "\n"))
  c(readRDS(out), list(log = log))
}

# the reference: this process's own (in-process) core
.p  <- ccx_default_params(); .sp <- ccx_spinup(.p)
.forc <- list(e_foss = list(NH = 8, SH = 0.4), e_luc = list(NH = 0.6, SH = 0.5),
              cum_luc = list(NH = 120, SH = 80), gmst = 1.1, enso = 0.7, c14_bomb = 1200,
              c14_nuclear = 40, c14_cosmo = .sp$prod_c14, d13c_foss = -27.6)
.d <- ccx_deriv_fast(.sp$y, 1980.5, .p, .forc, .sp$grid, .sp$aux)

test_that("1. the background build is the one loaded, and its core computes exactly what the in-process one does", {
  r <- cpb_child("ccx_cpp_prebuild(file.path(tempdir(), 'pb'))")
  expect_identical(r$built_by, "background")
  expect_false(any(grepl("compiling here", r$log)))
  # no second compile: the one library there was written by the child, before its result
  expect_length(r$so_t, 1L)
  expect_true(r$so_t <= r$done_t)
  expect_identical(r$y, .sp$y)
  expect_identical(r$d, .d)
})

test_that("2. MUTATION: a background build that FAILS falls back to the in-process compile", {
  r <- cpb_child("ccx_cpp_prebuild(file.path(tempdir(), 'pb'), src = file.path(tempdir(), 'absent.cpp'))")
  expect_identical(r$built_by, "in-process")
  expect_true(any(grepl("background build failed", r$log)))
  expect_identical(r$y, .sp$y)
})

test_that("3. MUTATION: a build process that DIES without a result falls back at once", {
  # a PID file naming a process that does not exist, and no result: what a killed child leaves
  r <- cpb_child(c("d <- file.path(tempdir(), 'pb'); dir.create(d)",
                   "writeLines('999999', file.path(d, 'pid'))",
                   ".ccx_cpp_env$prebuild <- list(dir = d, pid = file.path(d, 'pid'), done = file.path(d, 'done'),",
                   "                              log = file.path(d, 'build.log'), started = Sys.time())"))
  expect_identical(r$built_by, "in-process")
  expect_true(any(grepl("did not finish", r$log)))
  expect_lt(r$wait_s, CPB_FAST_S)
})

test_that("4. MUTATION: a build that never STARTS (no PID) falls back after the grace period, not the wait", {
  r <- cpb_child(c("CCX_CPP_PREBUILD_GRACE_S <- 1", "loadNamespace('Rcpp')",   # Rcpp loaded before the clock starts
                   "d <- file.path(tempdir(), 'pb'); dir.create(d)",
                   ".ccx_cpp_env$prebuild <- list(dir = d, pid = file.path(d, 'pid'), done = file.path(d, 'done'),",
                   "                              log = file.path(d, 'build.log'), started = Sys.time())"))
  expect_identical(r$built_by, "in-process")
  # the grace runs from `started`; the wait's own clock starts the few ms of setup later
  expect_gte(r$wait_s, 1 - CPB_SETUP_S)
  expect_lt(r$wait_s, CPB_FAST_S)
})
