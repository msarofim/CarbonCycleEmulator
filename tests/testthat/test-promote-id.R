# =====================================================================
# test-promote-id.R -- promote_multistart_mode.R's --id (CHANGELOG 2026-10-07 k; Marcus: "Build --id, read both
# (Recommended)"). calibration/lib_ms_promote.R pmm_choose_start() makes the choice; the driver wires it.
#   PI1 THE CHOICE (synthetic starts, no model): the default is the best converged in-time start, as GATE 3 always
#       computed it; --id picks the named start and returns the computed best beside it with the gap; it REFUSES an
#       unknown, duplicated, unconverged, out-of-time or dead id, and a non-integer.
#   PI2 THE WIRING (the driver's code): it sources the lib and calls pmm_choose_start(); --why is required with --id
#       and refused without it; the provenance records chosen_by / best_id / best_logpost / gap_to_best / why.
#   PI3 END TO END on objective #17's landed wave (committed): --id=1 promotes id 1 (basin B's incumbent start, 0.409
#       below the best) with the best (id 10) and the gap recorded, and its model fields are identical() to hilda29w's,
#       the dry run's promotion of the same start; the DEFAULT still promotes id 10, identical() in every model field
#       to the landed refit_20261007_obj17 file. Malformed calls stop before any file is written.
# ⚠ The default path's choice is UNCHANGED: a `dead` best is refused there by GATE 4's re-evaluation, as before.
# =====================================================================
source(ccx_path("calibration", "lib_ms_promote.R"))
PI_WAVE  <- ccx_path("calibration", "output", "multistart_20261006o_hilda_csl3v0kaidgbemw_seasml1_pin_obj17_sd1.0452")
PI_LANDED <- ccx_path("calibration", "output", "refit_20261007_obj17_hilda_csl3v0kaidgbemw", "mode_fit_pumpN.rds")
PI_B     <- ccx_path("calibration", "output", "refit_20261006_obj17_basinB_start001_DRYRUN", "mode_fit_pumpN.rds")
PI_B_MD5 <- "081eb16f4fe718692004fb1cf9645891"                 # hilda29w, registered 10-07 (i)
PI_MODEL_FIELDS <- c("par_mode", "u_mode", "logpost", "streams", "pins", "struct", "seas_ml", "pump_field", "trace")
pi_start <- function(id, lp, converged = TRUE, out_of_time = FALSE, dead = FALSE)
  list(id = as.integer(id), logpost = lp, converged = converged, out_of_time = out_of_time, dead = dead)
# best converged in time: id 1 (-9); id 2 is HIGHER but out of time, id 3 higher but unconverged
pi_S <- list(pi_start(0, -10), pi_start(1, -9), pi_start(2, -8, out_of_time = TRUE), pi_start(3, -7, converged = FALSE),
             pi_start(4, -9.5), pi_start(5, -9.25, dead = TRUE))

test_that("PI1: the default is the computed best; --id picks the named start with the best and the gap beside it", {
  d <- pmm_choose_start(pi_S)
  expect_identical(d$pick$id, 1L); expect_identical(d$top$id, 1L)
  expect_identical(d$chosen_by, "best_logpost"); expect_identical(d$gap, 0)
  expect_identical(vapply(d$fin, `[[`, 0L, "id"), c(0L, 1L, 4L, 5L))     # out of time / unconverged never ranked
  k <- pmm_choose_start(pi_S, 4L)
  expect_identical(k$pick$id, 4L); expect_identical(k$top$id, 1L)
  expect_identical(k$chosen_by, "id"); expect_equal(k$gap, 0.5)
  expect_identical(pmm_choose_start(pi_S, 1L)$gap, 0)                      # naming the best is allowed, gap 0
})

test_that("PI1: --id REFUSES an unknown, duplicated, unconverged, out-of-time or dead id, and a non-integer", {
  expect_error(pmm_choose_start(pi_S, 99L), "0 start files carry that id")
  expect_error(pmm_choose_start(c(pi_S, list(pi_start(4, -9.6))), 4L), "2 start files carry that id")
  expect_error(pmm_choose_start(pi_S, 2L), "out_of_time TRUE")
  expect_error(pmm_choose_start(pi_S, 3L), "converged FALSE")
  expect_error(pmm_choose_start(pi_S, 5L), "dead TRUE")
  expect_error(pmm_choose_start(pi_S, 1.5), "whole number")
  expect_error(pmm_choose_start(pi_S, -1), "whole number")
  expect_error(pmm_choose_start(list(pi_start(0, -1, converged = FALSE))), "no CONVERGED")
})

test_that("PI2: the driver sources the lib, needs --why with --id, and records the choice", {
  src <- paste(ccx_code_lines(readLines(ccx_path("calibration", "promote_multistart_mode.R"), warn = FALSE)), collapse = "\n")
  expect_match(src, 'source(ccx_path("calibration", "lib_ms_promote.R"))', fixed = TRUE)
  expect_match(src, "CH   <- pmm_choose_start(S, PMM_ID)", fixed = TRUE)
  expect_match(src, "best <- CH$pick", fixed = TRUE)
  expect_match(src, "--id needs --why", fixed = TRUE)
  expect_match(src, "--why is for --id only", fixed = TRUE)
  for (f in c("chosen_by = CH$chosen_by", "best_id = top$id", "best_logpost = top$logpost", "gap_to_best = CH$gap", "why = PMM_WHY"))
    expect_match(src, f, fixed = TRUE)
})

test_that("PI3: end to end on #17's wave -- --id=1 is hilda29w with the choice recorded; the default is the landed file", {
  skip_if_no_cpp()
  skip_if_not(dir.exists(PI_WAVE), "objective #17's wave is not in this checkout")
  expect_identical(unname(tools::md5sum(PI_B)), PI_B_MD5)
  rs <- file.path(R.home("bin"), "Rscript"); d <- tempfile("pi3"); dir.create(d); on.exit(unlink(d, recursive = TRUE), add = TRUE)
  # shQuote(): system2() hands its args to the shell unquoted, and the --why below carries an apostrophe and spaces
  run <- function(...) withr::with_dir(ccx_root(), suppressWarnings(system2(rs, shQuote(c("calibration/promote_multistart_mode.R",
                                                                                          sprintf("--outdir=%s", PI_WAVE), ...)),
                                                                            stdout = TRUE, stderr = TRUE)))
  # malformed: refused before anything is written
  for (a in list(c("--id=1"), c("--why=x"), c("--id=1.5", "--why=x"))) {
    out <- run(sprintf("--dest=%s", file.path(d, "bad")), a)
    expect_false(is.null(attr(out, "status")), info = paste(a, collapse = " "))
    expect_false(dir.exists(file.path(d, "bad")), info = paste(a, collapse = " "))
  }
  out_id <- run(sprintf("--dest=%s", file.path(d, "id1")), "--id=1", "--why=PI3: basin B's incumbent start")
  expect_null(attr(out_id, "status"))
  m1 <- readRDS(file.path(d, "id1", "mode_fit_pumpN.rds")); mb <- readRDS(PI_B)
  for (f in PI_MODEL_FIELDS) expect_identical(m1[[f]], mb[[f]], info = f)
  pf <- m1$promoted_from
  expect_identical(pf$id, 1L); expect_identical(pf$chosen_by, "id"); expect_identical(pf$best_id, 10L)
  expect_identical(pf$why, "PI3: basin B's incumbent start")
  expect_equal(pf$gap_to_best, pf$best_logpost - m1$logpost, tolerance = 1e-5)   # the stored logpost vs its re-evaluation
  expect_gt(pf$gap_to_best, 0.4); expect_lt(pf$gap_to_best, 0.42)                # CHANGELOG 10-07 (a): 0.409
  expect_identical(c(pf$n_converged, pf$n_starts), c(18L, 24L))                  # the WHOLE wave, not a scratch copy's 1 of 1
  out_def <- run(sprintf("--dest=%s", file.path(d, "default")))
  expect_null(attr(out_def, "status"))
  m0 <- readRDS(file.path(d, "default", "mode_fit_pumpN.rds")); ml <- readRDS(PI_LANDED)
  for (f in PI_MODEL_FIELDS) expect_identical(m0[[f]], ml[[f]], info = f)
  expect_identical(m0$promoted_from$id, 10L); expect_identical(m0$promoted_from$chosen_by, "best_logpost")
  expect_identical(m0$promoted_from$gap_to_best, 0); expect_true(is.na(m0$promoted_from$why))
})
